// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/cpp/sum_type.h"

#include <iterator>

#include "clang/AST/DeclCXX.h"
#include "clang/AST/DeclTemplate.h"
#include "clang/Sema/Sema.h"
#include "toolchain/check/call.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/core_identifier.h"
#include "toolchain/check/cpp/custom_type_mapping.h"
#include "toolchain/check/cpp/import.h"
#include "toolchain/check/cpp/overload_resolution.h"
#include "toolchain/check/cpp/type_mapping.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/member_access.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/operator.h"
#include "toolchain/check/pattern_match.h"
#include "toolchain/check/type.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/diagnostics/format_providers.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// The largest `std::variant` with a Carbon sum type: `Core.CppCompat` declares
// `StdVariant1` to `StdVariant8` (core/prelude/types/cpp/sum.carbon).
static constexpr int MaxVariantAlternatives = 8;

// Returns the C++ class declaration behind `type_id`, or null.
static auto GetCppClassDecl(Context& context, SemIR::TypeId type_id)
    -> const clang::CXXRecordDecl* {
  auto class_type = context.types().TryGetAs<SemIR::ClassType>(type_id);
  if (!class_type) {
    return nullptr;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (!class_info.scope_id.has_value()) {
    return nullptr;
  }
  auto decl_id =
      context.name_scopes().Get(class_info.scope_id).clang_decl_context_id();
  if (!decl_id.has_value()) {
    return nullptr;
  }
  return dyn_cast<clang::CXXRecordDecl>(
      context.clang_decls().Get(decl_id).decl());
}

// Returns the Carbon payload type of one C++ alternative, or `None` when it is
// not admitted: `std::monostate` is `()`, and any other type must map to a
// type the choice payload rule admits (`IsInSliceChoicePayloadType`, SF-6).
static auto MapAlternative(Context& context, SemIR::LocId loc_id,
                           clang::QualType type) -> SemIR::TypeId {
  if (IsStdMonostate(type)) {
    return GetTupleType(context, {});
  }
  auto type_expr = ImportCppType(context, loc_id, type);
  if (!type_expr.inst_id.has_value() ||
      type_expr.type_id == SemIR::ErrorInst::TypeId) {
    return SemIR::TypeId::None;
  }
  if (!TryToCompleteType(context, type_expr.type_id, loc_id) ||
      !IsInSliceChoicePayloadType(context, type_expr.type_id)) {
    return SemIR::TypeId::None;
  }
  return type_expr.type_id;
}

// The `Core.CppCompat` names, with static storage: the identifier table keeps
// a reference to the spelling it is given.
static auto GetCarbonSumTypeName(bool is_optional, int num_alternatives)
    -> llvm::StringLiteral {
  static constexpr llvm::StringLiteral VariantNames[] = {
      "StdVariant1", "StdVariant2", "StdVariant3", "StdVariant4",
      "StdVariant5", "StdVariant6", "StdVariant7", "StdVariant8"};
  static_assert(std::size(VariantNames) == MaxVariantAlternatives);
  return is_optional ? llvm::StringLiteral("StdOptional")
                     : VariantNames[num_alternatives - 1];
}

// Forms `Core.CppCompat.<name>(args...)`, or returns `ErrorInst::TypeId` after
// the failure was diagnosed where it happened.
static auto FormCarbonSumType(Context& context, SemIR::LocId loc_id,
                              llvm::StringLiteral name,
                              llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> SemIR::TypeId {
  auto cpp_compat_id =
      LookupNameInCore(context, loc_id, CoreIdentifier::CppCompat);
  if (cpp_compat_id == SemIR::ErrorInst::InstId) {
    return SemIR::ErrorInst::TypeId;
  }
  auto generic_id = PerformMemberAccess(context, loc_id, cpp_compat_id,
                                        AddIdentifierName(context, name));
  return ExprAsType(context, loc_id,
                    PerformCall(context, loc_id, generic_id, arg_ids))
      .type_id;
}

auto GetCppSumType(Context& context, SemIR::LocId loc_id, SemIR::TypeId type_id)
    -> CppSumType {
  type_id = context.types().GetUnqualifiedType(type_id);
  const auto* record_decl = GetCppClassDecl(context, type_id);
  if (!record_decl) {
    return {};
  }
  auto mapping = GetCppSumTypeMapping(record_decl);
  if (mapping.kind == CppSumTypeMapping::None) {
    return {};
  }
  CppSumType result = {
      .status = CppSumType::NotMapped,
      .cpp_type_id = type_id,
      .is_optional = mapping.kind == CppSumTypeMapping::Optional};
  int num_alternatives = mapping.alternative_types.size();
  if (num_alternatives < 1 || num_alternatives > MaxVariantAlternatives) {
    result.reason = CppSumType::TooManyAlternatives;
    result.num_alternatives = num_alternatives;
    return result;
  }
  // The C++ class must itself be trivially copyable and destructible: the
  // reverse conversion builds a C++ object that no destructor call ends, and
  // the scrutinee's C++ temporary is destroyed by a call that must do nothing.
  if (!record_decl->isTriviallyCopyable() ||
      !record_decl->hasTrivialDestructor()) {
    result.reason = CppSumType::NotTriviallyCopyable;
    return result;
  }
  llvm::SmallVector<SemIR::InstId> arg_ids;
  for (auto [index, alternative] : llvm::enumerate(mapping.alternative_types)) {
    // A qualified or reference alternative has no by-value payload (SV-1
    // D-SV-3): `std::variant<const int, double>`, `std::variant<int&>`. Two
    // C++ classes would otherwise share one sum type, and the reverse
    // conversion could reach only one of them.
    if (alternative.hasQualifiers() || alternative->isReferenceType()) {
      result.reason = CppSumType::QualifiedAlternative;
      result.bad_alternative = index;
      result.bad_alternative_type = alternative;
      return result;
    }
    auto alternative_type_id = MapAlternative(context, loc_id, alternative);
    if (!alternative_type_id.has_value()) {
      result.reason = CppSumType::AlternativeNotAdmitted;
      result.bad_alternative = index;
      result.bad_alternative_type = alternative;
      return result;
    }
    arg_ids.push_back(context.types().GetTypeInstId(alternative_type_id));
  }
  auto carbon_type_id = FormCarbonSumType(
      context, loc_id,
      GetCarbonSumTypeName(result.is_optional, num_alternatives), arg_ids);
  if (carbon_type_id == SemIR::ErrorInst::TypeId) {
    result.reason = CppSumType::AlreadyDiagnosed;
    return result;
  }
  if (!TryToCompleteType(context, carbon_type_id, loc_id) ||
      (!GetChoiceDiscriminantType(context, carbon_type_id) &&
       num_alternatives > 1)) {
    // Not reached for an admitted specialization; diagnosed with no note
    // (`NoReason`) rather than silently.
    return result;
  }
  result.status = CppSumType::Mapped;
  result.carbon_type_id = carbon_type_id;
  return result;
}

// The C++ spelling of a type in a diagnostic, without the tag keyword
// (`std::optional<int>`, not `class std::optional<int>`).
static auto GetCppTypeSpelling(Context& context, clang::QualType type)
    -> std::string {
  clang::PrintingPolicy policy(context.ast_context().getLangOpts());
  policy.SuppressTagKeyword = true;
  return type.getAsString(policy);
}

// The C++ spelling of the class behind `type_id`, as import.cpp's diagnostics
// print C++ types: the Carbon name of an imported specialization
// (`Cpp.std._C.optional`) carries no template arguments.
static auto GetCppTypeSpelling(Context& context, SemIR::TypeId type_id)
    -> std::string {
  const auto* record_decl = GetCppClassDecl(context, type_id);
  CARBON_CHECK(record_decl, "not a C++ class");
  return GetCppTypeSpelling(
      context,
      clang::QualType(context.ast_context().getCanonicalTagType(record_decl)));
}

auto DiagnoseCppSumTypeNotMapped(Context& context, SemIR::LocId loc_id,
                                 const CppSumType& sum_type) -> void {
  if (sum_type.reason == CppSumType::AlreadyDiagnosed) {
    return;
  }
  CARBON_DIAGNOSTIC(CppSumTypeNotMapped, Error,
                    "C++ type `{0}` has no Carbon sum type", std::string);
  CARBON_DIAGNOSTIC(CppSumTypeTooManyAlternatives, Note,
                    "`std::variant` with {0} alternatives; at most {1} have a "
                    "Carbon sum type",
                    int, int);
  CARBON_DIAGNOSTIC(CppSumTypeNotTriviallyCopyable, Note,
                    "`{0}` is not trivially copyable and trivially "
                    "destructible",
                    std::string);
  CARBON_DIAGNOSTIC(CppSumTypeQualifiedAlternative, Note,
                    "alternative {0} has qualified or reference type `{1}`",
                    int, std::string);
  CARBON_DIAGNOSTIC(CppSumTypeAlternativeNotAdmitted, Note,
                    "alternative {0} has type `{1}`, which is not a choice "
                    "payload type in 0.1",
                    int, std::string);
  auto spelling = GetCppTypeSpelling(context, sum_type.cpp_type_id);
  auto builder = context.emitter().Build(loc_id, CppSumTypeNotMapped, spelling);
  switch (sum_type.reason) {
    case CppSumType::TooManyAlternatives:
      builder.Note(loc_id, CppSumTypeTooManyAlternatives,
                   sum_type.num_alternatives, MaxVariantAlternatives);
      break;
    case CppSumType::NotTriviallyCopyable:
      builder.Note(loc_id, CppSumTypeNotTriviallyCopyable, spelling);
      break;
    case CppSumType::QualifiedAlternative:
      builder.Note(loc_id, CppSumTypeQualifiedAlternative,
                   sum_type.bad_alternative,
                   GetCppTypeSpelling(context, sum_type.bad_alternative_type));
      break;
    case CppSumType::AlternativeNotAdmitted:
      builder.Note(loc_id, CppSumTypeAlternativeNotAdmitted,
                   sum_type.bad_alternative,
                   GetCppTypeSpelling(context, sum_type.bad_alternative_type));
      break;
    case CppSumType::NoReason:
    case CppSumType::AlreadyDiagnosed:
      break;
  }
  builder.Emit();
}

// Returns whether a branching conversion can be built at `loc_id`, and emits a
// TODO when it cannot. It cannot outside a function body -- a file-scope
// initializer (W-036's limit, which every branching expression shares) or a
// conversion that a template defers to its instantiation, which is performed
// outside any function body -- nor where the conversion has no source
// expression to attribute its blocks to. These are limits of the toolchain, not
// of the types, so a non-diagnosing caller does not test them: an `overload fn`
// probe accepts the pair, and the committed call emits the TODO, so which
// member a call selects does not depend on where the call is.
static auto CanBuildBranches(Context& context, SemIR::LocId loc_id) -> bool {
  if (!context.scope_stack().IsInFunctionScope()) {
    context.TODO(loc_id,
                 "conversion of a C++ `std::optional` or `std::variant` "
                 "outside a function body (at file scope, or deferred to a "
                 "template's instantiation)");
    return false;
  }
  if (context.insts().GetCanonicalLocId(loc_id).kind() !=
      SemIR::LocId::Kind::NodeId) {
    context.TODO(loc_id,
                 "conversion of a C++ `std::optional` or `std::variant` "
                 "with no source expression");
    return false;
  }
  return true;
}

// Returns the parse node that the blocks of a branching conversion are
// attributed to, or emits a TODO and returns `None` where a conversion cannot
// branch (`CanBuildBranches`).
static auto GetNodeIdForBranches(Context& context, SemIR::LocId loc_id)
    -> Parse::NodeId {
  if (!CanBuildBranches(context, loc_id)) {
    return Parse::NodeId::None;
  }
  return context.insts().GetCanonicalLocId(loc_id).node_id();
}

// Calls `callee_id`, a C++ overload set, with the explicit integer template
// argument `index` -- `std::get<I>(v)`, `v.emplace<I>(x)` -- which a Carbon
// call cannot spell (cpp/call.cpp `IsTemplateArg`).
static auto CallCppWithIndexTemplateArg(Context& context, SemIR::LocId loc_id,
                                        Parse::NodeId node_id,
                                        SemIR::InstId callee_id, int index,
                                        llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> SemIR::InstId {
  auto callee = SemIR::GetCallee(context.sem_ir(), callee_id);
  const auto* overload = std::get_if<SemIR::CalleeCppOverloadSet>(&callee);
  if (!overload) {
    return SemIR::ErrorInst::InstId;
  }
  SemIR::InstId template_arg_ids[] = {
      MakeIntLiteral(context, node_id, context.ints().Add(index))};
  auto fn_id = PerformCppOverloadResolution(
      context, loc_id,
      context.cpp_overload_sets().Get(overload->cpp_overload_set_id),
      template_arg_ids, overload->self_id, arg_ids);
  auto fn_callee = SemIR::GetCallee(context.sem_ir(), fn_id);
  auto* fn = std::get_if<SemIR::CalleeFunction>(&fn_callee);
  if (!fn) {
    return SemIR::ErrorInst::InstId;
  }
  if (overload->self_id.has_value()) {
    fn->self_id = overload->self_id;
  }
  return PerformCallToFunction(context, loc_id, fn_id, *fn, arg_ids,
                               /*is_desugared=*/true);
}

// Calls the C++ member function `name` of `object_id`.
static auto CallCppMethod(Context& context, SemIR::LocId loc_id,
                          SemIR::InstId object_id, llvm::StringRef name,
                          llvm::ArrayRef<SemIR::InstId> arg_ids = {})
    -> SemIR::InstId {
  auto method_id = PerformMemberAccess(context, loc_id, object_id,
                                       AddIdentifierName(context, name));
  return PerformCall(context, loc_id, method_id, arg_ids,
                     /*is_desugared=*/true);
}

// The value `()`: the payload of a `std::monostate` alternative.
static auto MakeEmptyTupleValue(Context& context, SemIR::LocId loc_id)
    -> SemIR::InstId {
  return GetOrAddInst<SemIR::TupleValue>(
      context, loc_id,
      {.type_id = GetTupleType(context, {}),
       .elements_id = SemIR::InstBlockId::Empty});
}

// One shared storage initialized in one of several blocks: the catching
// thunk's shape (cpp/thunk.cpp `PerformCppCatchingThunkCall`).
class BranchedInit {
 public:
  BranchedInit(Context& context, SemIR::LocId loc_id, SemIR::TypeId type_id)
      : context_(context),
        loc_id_(loc_id),
        storage_id_(AddInst<SemIR::TemporaryStorage>(context, loc_id,
                                                     {.type_id = type_id})) {}

  auto Initialize(SemIR::InstId init_id) -> void {
    if (init_id == SemIR::ErrorInst::InstId) {
      ok_ = false;
      return;
    }
    init_id = InitializeExisting(context_, loc_id_, storage_id_, init_id);
    if (init_id == SemIR::ErrorInst::InstId) {
      ok_ = false;
      return;
    }
    AddInst<SemIR::Assign>(context_, loc_id_,
                           {.lhs_id = storage_id_, .rhs_id = init_id});
  }

  auto storage_id() const -> SemIR::InstId { return storage_id_; }
  auto ok() const -> bool { return ok_; }

 private:
  Context& context_;
  SemIR::LocId loc_id_;
  SemIR::InstId storage_id_;
  bool ok_ = true;
};

// The result of a conversion that a non-diagnosing caller only tests
// (`ConversionTarget::diagnose` is false: the `overload fn` probe, call.cpp
// `ProbeOverloadCandidate`, including the element conversions of an aggregate
// argument; deduction's speculative conversions): a value of the target type
// built from no C++ call and no block, so the probe's scratch block holds all
// of it. It is not a constant, as the conversion it stands for is not, so
// deduction, which keeps a constant result, rejects both alike.
static auto MakeTestedConversion(Context& context, SemIR::LocId loc_id,
                                 SemIR::TypeId type_id) -> SemIR::InstId {
  return ConvertToValueExpr(
      context,
      AddInst<SemIR::TemporaryStorage>(context, loc_id, {.type_id = type_id}));
}

// Emits `n` arms selected by `select(i)` for i < n - 1 (the last arm is the
// fall-through), calling `arm(i)` in each, and converges.
//
// Each arm owns the cleanups registered while it is built, as an `if`
// expression's arms do (`BeginConditionalExprOperand`): a C++ temporary made in
// one arm -- the `Core.Optional(T*)` that `value()` returns for a pointer
// payload -- is destroyed at the end of that arm, where its evaluation
// dominates the destroy. An arm initializes the shared storage and produces no
// value, so no value can refer into those temporaries.
template <typename SelectFn, typename ArmFn>
static auto EmitArms(Context& context, Parse::NodeId node_id, int n,
                     SelectFn select, ArmFn arm) -> void {
  CARBON_CHECK(node_id.has_value(), "branching conversion without a node");
  auto emit_arm = [&](int i) {
    BeginConditionalExprOperand(context);
    arm(i);
    if (context.scope_stack().IsInFunctionScope()) {
      AddAndDiscardTemporaryCleanups(context);
      context.scope_stack().Pop();
    }
  };
  for (int i = 0; i < n; ++i) {
    if (i + 1 < n) {
      auto cond_id = select(i);
      auto then_block_id =
          AddDominatedBlockAndBranchIf(context, node_id, cond_id);
      auto else_block_id = AddDominatedBlockAndBranch(context, node_id);
      context.inst_block_stack().Pop();
      context.inst_block_stack().Push(then_block_id);
      context.region_stack().AddToRegion(then_block_id, node_id);
      emit_arm(i);
      context.inst_block_stack().Push(else_block_id);
      context.region_stack().AddToRegion(else_block_id, node_id);
    } else {
      emit_arm(i);
    }
  }
  if (n > 1) {
    AddConvergenceBlockAndPush(context, node_id, n);
  }
}

// The alternatives of the `choice` `type_id`, in discriminant order.
static auto GetAlternativesInOrder(Context& context, SemIR::TypeId type_id)
    -> llvm::SmallVector<SemIR::ChoiceAlternative> {
  const auto& class_info = context.classes().Get(
      context.types().GetAs<SemIR::ClassType>(type_id).class_id);
  llvm::SmallVector<SemIR::ChoiceAlternative> alternatives(
      class_info.choice_alternatives.begin(),
      class_info.choice_alternatives.end());
  llvm::sort(alternatives,
             [](const auto& a, const auto& b) { return a.index < b.index; });
  return alternatives;
}

auto ConvertCppSumToCarbon(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId {
  CARBON_CHECK(sum_type.status == CppSumType::Mapped);
  auto node_id = GetNodeIdForBranches(context, loc_id);
  if (!node_id.has_value()) {
    return SemIR::ErrorInst::InstId;
  }
  // A value, not a reference: the accessors are then called on a `const`
  // object, so overload resolution picks their `const&` forms and nothing is
  // moved from.
  value_id = ConvertToValueExpr(context, value_id);
  auto carbon_type_inst_id =
      context.types().GetTypeInstId(sum_type.carbon_type_id);
  auto alternatives = GetAlternativesInOrder(context, sum_type.carbon_type_id);
  auto make_alternative = [&](const SemIR::ChoiceAlternative& alternative,
                              SemIR::InstId payload_id) -> SemIR::InstId {
    auto alternative_id = PerformMemberAccess(
        context, loc_id, carbon_type_inst_id, alternative.name_id);
    if (!alternative.has_parameters) {
      return alternative_id;
    }
    return PerformCall(context, loc_id, alternative_id, {payload_id},
                       /*is_desugared=*/true);
  };
  const auto* record_decl = GetCppClassDecl(context, sum_type.cpp_type_id);
  auto mapping = GetCppSumTypeMapping(record_decl);

  BranchedInit result(context, loc_id, sum_type.carbon_type_id);
  if (sum_type.is_optional) {
    // `Some` is alternative 0 and `None` alternative 1: test `has_value()`.
    // A `std::optional<std::monostate>`'s `Some` carries `()`.
    bool is_monostate = IsStdMonostate(mapping.alternative_types[0]);
    auto has_value_id = ConvertToBoolValue(
        context, loc_id, CallCppMethod(context, loc_id, value_id, "has_value"));
    EmitArms(
        context, node_id, 2, [&](int) { return has_value_id; },
        [&](int i) {
          auto payload_id = SemIR::InstId::None;
          if (i == 0) {
            payload_id = is_monostate ? MakeEmptyTupleValue(context, loc_id)
                                      : CallCppMethod(context, loc_id, value_id,
                                                      "value");
          }
          result.Initialize(make_alternative(alternatives[i], payload_id));
        });
  } else {
    int n = alternatives.size();
    auto index_id = n > 1 ? CallCppMethod(context, loc_id, value_id, "index")
                          : SemIR::InstId::None;
    auto std_scope_id =
        context.classes()
            .Get(context.types()
                     .GetAs<SemIR::ClassType>(sum_type.cpp_type_id)
                     .class_id)
            .parent_scope_id;
    auto std_inst_id = context.name_scopes().Get(std_scope_id).inst_id();
    EmitArms(
        context, node_id, n,
        [&](int i) {
          auto index_type_id = context.insts().Get(index_id).type_id();
          auto i_id = ConvertToValueOfType(
              context, loc_id,
              MakeIntLiteral(context, node_id, context.ints().Add(i)),
              index_type_id);
          SemIR::InstId eq_args[] = {
              context.types().GetTypeInstId(index_type_id)};
          auto eq_id =
              BuildBinaryOperator(context, loc_id,
                                  {.interface_name = CoreIdentifier::EqWith,
                                   .interface_args_ref = eq_args,
                                   .op_name = CoreIdentifier::Equal},
                                  index_id, i_id);
          return ConvertToBoolValue(context, loc_id, eq_id);
        },
        [&](int i) {
          auto payload_id = SemIR::InstId::None;
          if (IsStdMonostate(mapping.alternative_types[i])) {
            payload_id = MakeEmptyTupleValue(context, loc_id);
          } else {
            auto get_id =
                PerformMemberAccess(context, loc_id, std_inst_id,
                                    AddIdentifierName(context, "get"));
            payload_id = CallCppWithIndexTemplateArg(context, loc_id, node_id,
                                                     get_id, i, {value_id});
          }
          result.Initialize(make_alternative(alternatives[i], payload_id));
        });
  }
  if (!result.ok()) {
    return SemIR::ErrorInst::InstId;
  }
  return ConvertToValueExpr(context, result.storage_id());
}

auto ConvertCarbonSumToCpp(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId {
  CARBON_CHECK(sum_type.status == CppSumType::Mapped);
  auto node_id = GetNodeIdForBranches(context, loc_id);
  if (!node_id.has_value()) {
    return SemIR::ErrorInst::InstId;
  }
  value_id = ConvertToValueExpr(context, value_id);
  auto cpp_type_inst_id = context.types().GetTypeInstId(sum_type.cpp_type_id);
  const auto& cpp_class = context.classes().Get(
      context.types().GetAs<SemIR::ClassType>(sum_type.cpp_type_id).class_id);
  auto alternatives = GetAlternativesInOrder(context, sum_type.carbon_type_id);
  int n = alternatives.size();

  // Default-construct the C++ object -- an empty `std::optional`, or a
  // `std::variant` holding a value-initialized first alternative -- then
  // `emplace` the active alternative's payload.
  BranchedInit result(context, loc_id, sum_type.cpp_type_id);
  auto ctor_id =
      PerformMemberAccess(context, loc_id, cpp_type_inst_id, cpp_class.name_id);
  result.Initialize(PerformCall(context, loc_id, ctor_id, {}, true));
  auto disc_type_id =
      GetChoiceDiscriminantType(context, sum_type.carbon_type_id);
  // The payload of `alternative`, or `None` for a `()` payload, which
  // `emplace` takes as no argument.
  auto payload_of =
      [&](const SemIR::ChoiceAlternative& alternative) -> SemIR::InstId {
    auto tuple_id = EmitChoicePayloadFieldAccess(
        context, loc_id, value_id, alternative.payload_field_index);
    auto tuple_type_id = context.insts().Get(tuple_id).type_id();
    auto element_type_id = context.types().GetTypeIdForTypeInstId(
        context.inst_blocks().Get(context.types()
                                      .GetAs<SemIR::TupleType>(tuple_type_id)
                                      .type_elements_id)[0]);
    if (element_type_id == GetTupleType(context, {})) {
      return SemIR::InstId::None;
    }
    return ConvertToValueExpr(context, AddInst<SemIR::TupleAccess>(
                                           context, loc_id,
                                           {.type_id = element_type_id,
                                            .tuple_id = tuple_id,
                                            .index = SemIR::ElementIndex(0)}));
  };
  bool ok = result.ok();
  EmitArms(
      context, node_id, n,
      [&](int i) {
        return EmitChoiceDiscriminantTest(context, node_id, value_id,
                                          *disc_type_id, alternatives[i].index);
      },
      [&](int i) {
        const auto& alternative = alternatives[i];
        if (!alternative.has_parameters) {
          // `None`: the default-constructed `std::optional` is empty.
          return;
        }
        llvm::SmallVector<SemIR::InstId, 1> args;
        if (auto payload_id = payload_of(alternative); payload_id.has_value()) {
          args.push_back(payload_id);
        }
        if (sum_type.is_optional) {
          ok &= CallCppMethod(context, loc_id, result.storage_id(), "emplace",
                              args) != SemIR::ErrorInst::InstId;
          return;
        }
        auto emplace_id =
            PerformMemberAccess(context, loc_id, result.storage_id(),
                                AddIdentifierName(context, "emplace"));
        ok &= CallCppWithIndexTemplateArg(context, loc_id, node_id, emplace_id,
                                          i, args) != SemIR::ErrorInst::InstId;
      });
  if (!ok) {
    return SemIR::ErrorInst::InstId;
  }
  return ConvertToValueExpr(context, result.storage_id());
}

// Returns 1 for `Core.CppCompat.StdOptional`, 2 for a `StdVariant<N>`, and 0
// for any other type.
static auto ClassifyCarbonSumType(Context& context, SemIR::TypeId type_id)
    -> int {
  auto class_type = context.types().TryGetAs<SemIR::ClassType>(
      context.types().GetUnqualifiedType(type_id));
  if (!class_type || !class_type->specific_id.has_value()) {
    return 0;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (!class_info.is_choice || !class_info.parent_scope_id.has_value() ||
      !context.name_scopes().IsInCorePackageRoot(class_info.parent_scope_id)) {
    return 0;
  }
  auto parent_name = context.names().GetAsStringIfIdentifier(
      context.name_scopes().Get(class_info.parent_scope_id).name_id());
  auto name = context.names().GetAsStringIfIdentifier(class_info.name_id);
  if (parent_name != "CppCompat" || !name) {
    return 0;
  }
  if (*name == "StdOptional") {
    return 1;
  }
  return name->starts_with("StdVariant") ? 2 : 0;
}

// Returns whether `type_id` is a `Core.Optional(T)` specific, and sets
// `payload_type_id` to `T` (from the argument `T as OptionalStorage`) when the
// argument is concrete. Adds no instruction.
static auto GetCoreOptionalPayload(Context& context, SemIR::TypeId type_id,
                                   SemIR::TypeId& payload_type_id) -> bool {
  payload_type_id = SemIR::TypeId::None;
  auto class_type = context.types().TryGetAs<SemIR::ClassType>(
      context.types().GetUnqualifiedType(type_id));
  if (!class_type || !class_type->specific_id.has_value()) {
    return false;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (class_info.is_choice ||
      !context.name_scopes().IsCorePackage(class_info.parent_scope_id) ||
      context.names().GetAsStringIfIdentifier(class_info.name_id) !=
          "Optional") {
    return false;
  }
  auto args = context.inst_blocks().GetOrEmpty(
      context.specifics().Get(class_type->specific_id).args_id);
  if (args.size() != 1) {
    return false;
  }
  auto arg_const_id = context.constant_values().Get(args[0]);
  if (context.constant_values().GetDependence(arg_const_id) !=
      SemIR::ConstantDependence::None) {
    return true;
  }
  auto arg_inst_id = context.constant_values().GetInstId(arg_const_id);
  if (auto facet = context.insts().TryGetAs<SemIR::FacetValue>(arg_inst_id)) {
    arg_const_id = context.constant_values().Get(facet->type_inst_id);
  }
  payload_type_id = context.types().TryGetTypeIdForTypeConstantId(arg_const_id);
  return true;
}

// Classifies a `Core.Optional` specific without forming its view.
static auto ClassifyCoreOptional(Context& context, SemIR::LocId loc_id,
                                 SemIR::TypeId type_id) -> CoreOptionalView {
  auto payload_type_id = SemIR::TypeId::None;
  if (!GetCoreOptionalPayload(context, type_id, payload_type_id)) {
    return {};
  }
  CoreOptionalView view = {.payload_type_id = payload_type_id};
  if (!payload_type_id.has_value()) {
    view.status = CoreOptionalView::SymbolicPayload;
  } else if (!TryToCompleteType(context, payload_type_id, loc_id) ||
             !IsInSliceChoicePayloadType(context, payload_type_id)) {
    view.status = CoreOptionalView::PayloadNotAdmitted;
  } else {
    view.status = CoreOptionalView::Matchable;
  }
  return view;
}

auto GetCoreOptionalView(Context& context, SemIR::LocId loc_id,
                         SemIR::TypeId type_id) -> CoreOptionalView {
  auto view = ClassifyCoreOptional(context, loc_id, type_id);
  if (view.status != CoreOptionalView::Matchable) {
    return view;
  }
  // The payload is admitted, so forming `StdOptional(T)` cannot fail SF-6's
  // per-specific check.
  view.view_type_id = FormCarbonSumType(
      context, loc_id, GetCarbonSumTypeName(/*is_optional=*/true, 1),
      {context.types().GetTypeInstId(view.payload_type_id)});
  if (view.view_type_id == SemIR::ErrorInst::TypeId) {
    view.status = CoreOptionalView::PayloadNotAdmitted;
  }
  return view;
}

auto DiagnoseCoreOptionalNotMatchable(Context& context, SemIR::LocId loc_id,
                                      SemIR::TypeId type_id,
                                      const CoreOptionalView& view) -> void {
  CARBON_DIAGNOSTIC(CoreOptionalNotMatchable, Error,
                    "cannot match {0} in 0.1: its payload type {1:is "
                    "symbolic|is not a choice payload type}",
                    SemIR::TypeId, Diagnostics::BoolAsSelect);
  context.emitter().Emit(loc_id, CoreOptionalNotMatchable, type_id,
                         view.status == CoreOptionalView::SymbolicPayload);
}

static auto IsTemplateDependent(Context& context, SemIR::TypeId type_id)
    -> bool {
  return context.constant_values().GetDependence(context.types().GetConstantId(
             type_id)) == SemIR::ConstantDependence::Template;
}

// Diagnoses a C++ sum value converted to a type it does not convert to.
static auto DiagnoseCppSumTypeMismatch(Context& context, SemIR::LocId loc_id,
                                       const CppSumType& sum_type,
                                       SemIR::TypeId target_type_id) -> void {
  CARBON_DIAGNOSTIC(CppSumTypeMismatch, Error,
                    "C++ type `{0}` converts only to its own Carbon sum type "
                    "{1}{2: or to the `Core.Optional` of its payload|}, not to "
                    "{3}",
                    std::string, SemIR::TypeId, Diagnostics::BoolAsSelect,
                    SemIR::TypeId);
  context.emitter().Emit(loc_id, CppSumTypeMismatch,
                         GetCppTypeSpelling(context, sum_type.cpp_type_id),
                         sum_type.carbon_type_id, sum_type.is_optional,
                         target_type_id);
}

// Diagnoses a Carbon sum value converted to a C++ class that is not the one
// whose sum type it is: another specialization (`std::optional<long>`), or a
// class with a converting constructor, which C++ would otherwise reach through
// `std::optional`'s own converting constructors.
static auto DiagnoseCppSumTypeReverseMismatch(Context& context,
                                              SemIR::LocId loc_id,
                                              SemIR::TypeId value_type_id,
                                              SemIR::TypeId target_type_id)
    -> void {
  CARBON_DIAGNOSTIC(CppSumTypeReverseMismatch, Error,
                    "{0} converts to C++ only as the `std::optional` or "
                    "`std::variant` whose Carbon sum type it is, not to `{1}`",
                    SemIR::TypeId, std::string);
  context.emitter().Emit(loc_id, CppSumTypeReverseMismatch, value_type_id,
                         GetCppTypeSpelling(context, target_type_id));
}

// Converts a value of a C++ class or Carbon type to the C++ class target
// `target_type_id`, given the Carbon sum type `sum_type_id` the value converts
// to first (itself, or the view of a `Core.Optional`).
static auto ConvertToCppSumClass(Context& context, SemIR::LocId loc_id,
                                 SemIR::InstId value_id,
                                 SemIR::TypeId value_type_id,
                                 SemIR::TypeId sum_type_id,
                                 SemIR::TypeId target_type_id, bool diagnose)
    -> SemIR::InstId {
  auto sum_type = GetCppSumType(context, loc_id, target_type_id);
  if (sum_type.status != CppSumType::Mapped ||
      sum_type.carbon_type_id != sum_type_id) {
    if (diagnose) {
      DiagnoseCppSumTypeReverseMismatch(context, loc_id, value_type_id,
                                        target_type_id);
    }
    return SemIR::ErrorInst::InstId;
  }
  if (!diagnose) {
    return MakeTestedConversion(context, loc_id, target_type_id);
  }
  if (!CanBuildBranches(context, loc_id)) {
    return SemIR::ErrorInst::InstId;
  }
  if (value_type_id != sum_type_id) {
    // A `Core.Optional(T)`: through the prelude's bridge to its view first.
    value_id = ConvertToValueOfType(context, loc_id, value_id, sum_type_id);
    if (value_id == SemIR::ErrorInst::InstId) {
      return value_id;
    }
  }
  return ConvertCarbonSumToCpp(context, loc_id, value_id, sum_type);
}

auto TryConvertCppSumType(Context& context, SemIR::LocId loc_id,
                          SemIR::InstId value_id, SemIR::TypeId target_type_id,
                          bool diagnose) -> SemIR::InstId {
  auto value_type_id = context.types().GetUnqualifiedType(
      context.insts().Get(value_id).type_id());
  target_type_id = context.types().GetUnqualifiedType(target_type_id);
  // A template-dependent side is converted when the template is instantiated
  // (the deferred conversion), with both types known.
  if (IsTemplateDependent(context, value_type_id) ||
      IsTemplateDependent(context, target_type_id)) {
    return SemIR::InstId::None;
  }

  // C++ to Carbon: to the sum type itself, or for `std::optional<T>` to
  // `Core.Optional(T')` through it.
  if (GetCppClassDecl(context, value_type_id)) {
    bool target_is_sum_type =
        ClassifyCarbonSumType(context, target_type_id) != 0;
    auto target_optional =
        target_is_sum_type
            ? CoreOptionalView()
            : ClassifyCoreOptional(context, loc_id, target_type_id);
    // A `Core.Optional` whose payload is not matchable -- in particular one
    // whose payload is the C++ class itself -- is left to `Core.Optional`'s
    // own conversions.
    if (!target_is_sum_type &&
        target_optional.status != CoreOptionalView::Matchable) {
      return SemIR::InstId::None;
    }
    auto sum_type = GetCppSumType(context, loc_id, value_type_id);
    if (sum_type.status == CppSumType::NotSumType) {
      return SemIR::InstId::None;
    }
    if (sum_type.status == CppSumType::NotMapped) {
      if (diagnose) {
        DiagnoseCppSumTypeNotMapped(context, loc_id, sum_type);
      }
      return SemIR::ErrorInst::InstId;
    }
    bool to_core_optional = false;
    if (!target_is_sum_type && sum_type.is_optional) {
      auto view = GetCoreOptionalView(context, loc_id, target_type_id);
      to_core_optional = view.view_type_id == sum_type.carbon_type_id;
    }
    if (sum_type.carbon_type_id != target_type_id && !to_core_optional) {
      if (diagnose) {
        DiagnoseCppSumTypeMismatch(context, loc_id, sum_type, target_type_id);
      }
      return SemIR::ErrorInst::InstId;
    }
    if (!diagnose) {
      return MakeTestedConversion(context, loc_id, target_type_id);
    }
    if (!CanBuildBranches(context, loc_id)) {
      return SemIR::ErrorInst::InstId;
    }
    auto sum_id = ConvertCppSumToCarbon(context, loc_id, value_id, sum_type);
    if (!to_core_optional || sum_id == SemIR::ErrorInst::InstId) {
      return sum_id;
    }
    // Through the prelude's bridge,
    // `StdOptional(T) as ImplicitAs(Optional(T))`.
    return ConvertToValueOfType(context, loc_id, sum_id, target_type_id);
  }

  // Carbon to C++: a sum type, or a `Core.Optional(T')` whose payload is
  // matchable and not a pointer (a `Core.Optional(T*)` keeps the nullable
  // pointer mapping), converts only to the C++ class whose sum type it is.
  if (!GetCppClassDecl(context, target_type_id)) {
    return SemIR::InstId::None;
  }
  if (ClassifyCarbonSumType(context, value_type_id) != 0) {
    return ConvertToCppSumClass(context, loc_id, value_id, value_type_id,
                                value_type_id, target_type_id, diagnose);
  }
  auto value_optional = ClassifyCoreOptional(context, loc_id, value_type_id);
  if (value_optional.status == CoreOptionalView::Matchable &&
      !context.types().Is<SemIR::PointerType>(value_optional.payload_type_id)) {
    auto view = GetCoreOptionalView(context, loc_id, value_type_id);
    return ConvertToCppSumClass(context, loc_id, value_id, value_type_id,
                                view.view_type_id, target_type_id, diagnose);
  }
  return SemIR::InstId::None;
}

auto MapCarbonSumTypeToCpp(Context& context, SemIR::LocId loc_id,
                           SemIR::TypeId carbon_type_id) -> clang::QualType {
  carbon_type_id = context.types().GetUnqualifiedType(carbon_type_id);
  int kind = ClassifyCarbonSumType(context, carbon_type_id);
  llvm::SmallVector<SemIR::TypeId> arg_type_ids;
  if (kind != 0) {
    auto class_type = context.types().GetAs<SemIR::ClassType>(carbon_type_id);
    for (auto arg_id : context.inst_blocks().GetOrEmpty(
             context.specifics().Get(class_type.specific_id).args_id)) {
      if (auto facet = context.insts().TryGetAs<SemIR::FacetValue>(arg_id)) {
        arg_id = facet->type_inst_id;
      }
      arg_type_ids.push_back(context.types().GetTypeIdForTypeConstantId(
          context.constant_values().Get(arg_id)));
    }
  } else {
    // A `Core.Optional(T)` whose payload is matchable and not a pointer is
    // offered as `std::optional<T'>`; a `Core.Optional(T*)` keeps the nullable
    // pointer mapping of `MapToCppType`.
    auto view = ClassifyCoreOptional(context, loc_id, carbon_type_id);
    if (view.status != CoreOptionalView::Matchable ||
        context.types().Is<SemIR::PointerType>(view.payload_type_id)) {
      return clang::QualType();
    }
    kind = 1;
    arg_type_ids.push_back(view.payload_type_id);
  }
  auto* template_decl = LookupCppClassTemplate(
      context, {"std", kind == 1 ? "optional" : "variant"});
  if (!template_decl) {
    return clang::QualType();
  }
  clang::ASTContext& ast_context = context.ast_context();
  clang::TemplateArgumentListInfo arg_list;
  for (auto arg_type_id : arg_type_ids) {
    if (!arg_type_id.has_value() || arg_type_id == SemIR::ErrorInst::TypeId) {
      return clang::QualType();
    }
    // `()` is the payload of a `std::monostate` alternative.
    auto cpp_arg_type = arg_type_id == GetTupleType(context, {})
                            ? LookupCppType(context, {"std", "monostate"})
                            : MapToCppType(context, arg_type_id);
    if (cpp_arg_type.isNull()) {
      return clang::QualType();
    }
    arg_list.addArgument(clang::TemplateArgumentLoc(
        clang::TemplateArgument(cpp_arg_type),
        ast_context.getTrivialTypeSourceInfo(cpp_arg_type)));
  }
  clang::TemplateName template_name(template_decl);
  return context.clang_sema().CheckTemplateIdType(
      clang::ElaboratedTypeKeyword::None, template_name,
      /*TemplateLoc=*/clang::SourceLocation(), arg_list,
      /*Scope=*/nullptr, /*ForNestedNameSpecifier=*/false);
}

}  // namespace Carbon::Check
