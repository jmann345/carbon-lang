// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/call.h"

#include <optional>
#include <utility>

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "toolchain/base/kind_switch.h"
#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/cpp/call.h"
#include "toolchain/check/cpp/thunk.h"
#include "toolchain/check/deduce.h"
#include "toolchain/check/eval.h"
#include "toolchain/check/facet_type.h"
#include "toolchain/check/function.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/import_ref.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/thunk.h"
#include "toolchain/check/type.h"
#include "toolchain/diagnostics/format_providers.h"
#include "toolchain/sem_ir/builtin_function_kind.h"
#include "toolchain/sem_ir/entity_with_params_base.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/overload_set.h"
#include "toolchain/sem_ir/pattern.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

namespace {
// Entity kinds, for diagnostics. Converted to an int for a select.
enum class EntityKind : uint8_t {
  Function = 0,
  GenericClass = 1,
  GenericInterface = 2,
  GenericNamedConstraint = 3,
};
}  // namespace

// Resolves the callee expression in a call to a specific callee, or diagnoses
// if no specific callee can be identified. This verifies the arity of the
// callee and determines any compile-time arguments, but doesn't check that the
// runtime arguments are convertible to the parameter types.
//
// `self_id` and `arg_ids` are the self argument and explicit arguments in the
// call.
//
// Returns a `SpecificId` for the specific callee, `SpecificId::None` if the
// callee is not generic, or `nullopt` if an error has been diagnosed.
static auto ResolveCalleeInCall(Context& context, SemIR::LocId loc_id,
                                const SemIR::EntityWithParamsBase& entity,
                                EntityKind entity_kind_for_diagnostic,
                                SemIR::SpecificId enclosing_specific_id,
                                SemIR::InstId self_id,
                                llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> std::optional<SemIR::SpecificId> {
  // Check that the arity matches the explicit arguments.
  auto param_patterns =
      context.inst_blocks().GetOrEmpty(entity.param_patterns_id);
  size_t expected_args_size =
      param_patterns.size() - (self_id.has_value() ? 1 : 0);
  if (arg_ids.size() != expected_args_size) {
    CARBON_DIAGNOSTIC(CallArgCountMismatch, Error,
                      "{0} argument{0:s} passed to "
                      "{1:=0:function|=1:generic class|=2:generic "
                      "interface|=3:generic constraint}"
                      " expecting {2} argument{2:s}",
                      Diagnostics::IntAsSelect, Diagnostics::IntAsSelect,
                      Diagnostics::IntAsSelect);
    CARBON_DIAGNOSTIC(InCallToEntity, Note,
                      "calling {0:=0:function|=1:generic class|=2:generic "
                      "interface|=3:generic constraint}"
                      " declared here",
                      Diagnostics::IntAsSelect);
    context.emitter()
        .Build(loc_id, CallArgCountMismatch, arg_ids.size(),
               static_cast<int>(entity_kind_for_diagnostic), expected_args_size)
        .Note(entity.latest_decl_id(), InCallToEntity,
              static_cast<int>(entity_kind_for_diagnostic))
        .Emit();
    return std::nullopt;
  }

  // Perform argument deduction.
  auto specific_id = SemIR::SpecificId::None;
  if (entity.generic_id.has_value()) {
    specific_id = DeduceGenericCallArguments(
        context, loc_id, entity.generic_id, enclosing_specific_id,
        entity.implicit_param_patterns_id, entity.param_patterns_id, self_id,
        arg_ids);
    if (!specific_id.has_value()) {
      return std::nullopt;
    }
  }
  return specific_id;
}

// Performs a call where the callee is the name of a generic class, such as
// `Vector(i32)`.
static auto PerformCallToGenericClass(Context& context, SemIR::LocId loc_id,
                                      SemIR::ClassId class_id,
                                      SemIR::SpecificId enclosing_specific_id,
                                      llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> SemIR::InstId {
  const auto& generic_class = context.classes().Get(class_id);
  auto callee_specific_id =
      ResolveCalleeInCall(context, loc_id, generic_class,
                          EntityKind::GenericClass, enclosing_specific_id,
                          /*self_id=*/SemIR::InstId::None, arg_ids);
  if (!callee_specific_id) {
    return SemIR::ErrorInst::InstId;
  }
  return GetOrAddInst<SemIR::ClassType>(context, loc_id,
                                        {.type_id = SemIR::TypeType::TypeId,
                                         .class_id = class_id,
                                         .specific_id = *callee_specific_id});
}

static auto EntityFromInterfaceOrNamedConstraint(
    Context& context, SemIR::InterfaceId interface_id)
    -> const SemIR::EntityWithParamsBase& {
  return context.interfaces().Get(interface_id);
}

static auto EntityFromInterfaceOrNamedConstraint(
    Context& context, SemIR::NamedConstraintId named_constraint_id)
    -> const SemIR::EntityWithParamsBase& {
  return context.named_constraints().Get(named_constraint_id);
}

// Performs a call where the callee is the name of a generic interface or named
// constraint, such as `AddWith(i32)`.
template <typename IdT>
  requires SameAsOneOf<IdT, SemIR::InterfaceId, SemIR::NamedConstraintId>
static auto PerformCallToGenericInterfaceOrNamedConstaint(
    Context& context, SemIR::LocId loc_id, IdT id,
    SemIR::SpecificId enclosing_specific_id,
    llvm::ArrayRef<SemIR::InstId> arg_ids) -> SemIR::InstId {
  const auto& entity = EntityFromInterfaceOrNamedConstraint(context, id);

  auto entity_kind_for_diagnostic = EntityKind::GenericInterface;
  if constexpr (std::same_as<IdT, SemIR::NamedConstraintId>) {
    entity_kind_for_diagnostic = EntityKind::GenericNamedConstraint;
  }
  auto callee_specific_id =
      ResolveCalleeInCall(context, loc_id, entity, entity_kind_for_diagnostic,
                          enclosing_specific_id,
                          /*self_id=*/SemIR::InstId::None, arg_ids);
  if (!callee_specific_id) {
    return SemIR::ErrorInst::InstId;
  }
  std::optional<SemIR::FacetType> facet_type;
  if constexpr (std::same_as<IdT, SemIR::InterfaceId>) {
    facet_type = FacetTypeFromInterface(context, id, *callee_specific_id);
  } else {
    facet_type = FacetTypeFromNamedConstraint(context, id, *callee_specific_id);
  }
  return GetOrAddInst(context, loc_id, *facet_type);
}

// Builds an appropriate specific function for the callee, also handling
// instance binding.
static auto BuildCalleeSpecificFunction(
    Context& context, SemIR::LocId loc_id, SemIR::InstId callee_id,
    SemIR::InstId callee_function_self_type_id,
    SemIR::SpecificId callee_specific_id) -> SemIR::InstId {
  auto generic_callee_id = callee_id;

  // Strip off a bound_method so that we can form a constant specific callee.
  auto bound_method = context.insts().TryGetAs<SemIR::BoundMethod>(callee_id);
  if (bound_method) {
    generic_callee_id = bound_method->function_decl_id;
  }

  // Form a specific callee.
  if (callee_function_self_type_id.has_value()) {
    // This is an associated function in an interface; the callee is the
    // specific function in the impl that corresponds to the specific function
    // we deduced.
    callee_id =
        GetOrAddInst(context, SemIR::LocId(generic_callee_id),
                     SemIR::SpecificImplFunction{
                         .type_id = GetSingletonType(
                             context, SemIR::SpecificFunctionType::TypeInstId),
                         .callee_id = generic_callee_id,
                         .specific_id = callee_specific_id});
  } else {
    // This is a regular generic function. The callee is the specific function
    // we deduced.
    callee_id =
        GetOrAddInst(context, SemIR::LocId(generic_callee_id),
                     SemIR::SpecificFunction{
                         .type_id = GetSingletonType(
                             context, SemIR::SpecificFunctionType::TypeInstId),
                         .callee_id = generic_callee_id,
                         .specific_id = callee_specific_id});
  }

  // Add the `self` argument back if there was one.
  if (bound_method) {
    callee_id =
        GetOrAddInst<SemIR::BoundMethod>(context, loc_id,
                                         {.type_id = bound_method->type_id,
                                          .object_id = bound_method->object_id,
                                          .function_decl_id = callee_id});
  }

  return callee_id;
}

auto PerformCallToFunction(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId callee_id,
                           const SemIR::CalleeFunction& callee_function,
                           llvm::ArrayRef<SemIR::InstId> arg_ids,
                           bool is_desugared) -> SemIR::InstId {
  // If the callee is a generic function, determine the generic argument values
  // for the call.
  auto callee_specific_id = ResolveCalleeInCall(
      context, loc_id, context.functions().Get(callee_function.function_id),
      EntityKind::Function, callee_function.enclosing_specific_id,
      callee_function.self_id, arg_ids);
  if (!callee_specific_id) {
    return SemIR::ErrorInst::InstId;
  }

  if (callee_specific_id->has_value()) {
    callee_id = BuildCalleeSpecificFunction(context, loc_id, callee_id,
                                            callee_function.self_type_id,
                                            *callee_specific_id);
  }

  auto& callee = context.functions().Get(callee_function.function_id);
  auto return_type_id =
      callee.GetDeclaredReturnType(context.sem_ir(), *callee_specific_id);
  if (!return_type_id.has_value()) {
    return_type_id = GetTupleType(context, {});
  }

  auto return_arg_id = SemIR::InstId::None;
  if (callee.return_pattern_id.has_value()) {
    Diagnostics::AnnotationScope annotate_diagnostics(
        &context.emitter(), [&](auto& builder) {
          CARBON_DIAGNOSTIC(IncompleteReturnTypeHere, Note,
                            "return type declared here");
          builder.Note(callee.return_pattern_id, IncompleteReturnTypeHere);
        });
    auto arg_type_id = CheckFunctionReturnPatternType(
        context, loc_id, callee.return_pattern_id, *callee_specific_id);
    if (arg_type_id == SemIR::ErrorInst::TypeId) {
      return_type_id = SemIR::ErrorInst::TypeId;
    } else if (SemIR::InitRepr::ForType(context.sem_ir(), arg_type_id)
                   .MightBeInPlace()) {
      // Tentatively use storage for a temporary as the return argument.
      // This will be replaced if necessary when we perform initialization.
      return_arg_id = AddInst<SemIR::TemporaryStorage>(
          context, loc_id, {.type_id = arg_type_id});
    }
  }
  // Convert the arguments to match the parameters.
  auto converted_args_id =
      ConvertCallArgs(context, callee_function.self_id, arg_ids, return_arg_id,
                      callee, *callee_specific_id, is_desugared);
  switch (callee.special_function_kind) {
    case SemIR::Function::SpecialFunctionKind::Thunk: {
      // If we're about to form a direct call to a thunk, inline it.
      const auto& thunk_info = context.sem_ir().thunks().Get(callee.thunk_id());
      LoadImportRef(context, thunk_info.callee_id);

      // Name the thunk target within the enclosing scope of the thunk.
      auto thunk_ref_id =
          BuildNameRef(context, loc_id, callee.name_id, thunk_info.callee_id,
                       callee_function.enclosing_specific_id);

      auto param_pattern_ids =
          context.inst_blocks().Get(context.functions()
                                        .Get(callee_function.function_id)
                                        .param_patterns_id);

      // This recurses back into `PerformCall`. However, we never form a thunk
      // to a thunk, so we only recurse once.
      return PerformThunkCall(context, loc_id, callee_function.function_id,
                              param_pattern_ids,
                              context.inst_blocks().Get(converted_args_id),
                              thunk_ref_id, thunk_info.override_self_type_id);
    }

    case SemIR::Function::SpecialFunctionKind::HasCppThunk: {
      return PerformCppThunkCall(context, loc_id, callee_function.function_id,
                                 context.inst_blocks().Get(converted_args_id),
                                 callee.cpp_thunk_decl_id());
    }

    case SemIR::Function::SpecialFunctionKind::None:
    case SemIR::Function::SpecialFunctionKind::Builtin:
    case SemIR::Function::SpecialFunctionKind::CoreWitness:
    case SemIR::Function::SpecialFunctionKind::CppThunk: {
      return GetOrAddInst<SemIR::Call>(context, loc_id,
                                       {.type_id = return_type_id,
                                        .callee_id = callee_id,
                                        .args_id = converted_args_id});
    }
  }
}

namespace {
// Why a candidate member of an `overload fn` set was rejected, for the
// `OverloadCandidateRejected` note. Converted to an int for a select.
enum class OverloadRejectReason : uint8_t {
  Arity = 0,
  Conversion = 1,
  Deduction = 2,
  ReceiverOnNonMethod = 3,
};

// The outcome of probing one candidate member.
struct OverloadProbeResult {
  // Why the candidate was rejected; `nullopt` if it was accepted.
  std::optional<OverloadRejectReason> reject_reason;
  // Whether a 0.1 gate was diagnosed, in which case the whole call is an
  // error and no further candidate is tried.
  bool gated = false;
};
}  // namespace

// Returns the range of explicit argument counts a member accepts, keyed on
// whether the call binds a receiver, exactly as `ResolveCalleeInCall` computes
// the expected count. Carbon has no default arguments, so the range is exact;
// it is a range so that variadic members (W-013) can widen it.
static auto GetExplicitArityRange(Context& context,
                                  const SemIR::Function& function,
                                  SemIR::InstId self_id)
    -> std::pair<size_t, size_t> {
  auto param_patterns =
      context.inst_blocks().GetOrEmpty(function.param_patterns_id);
  size_t expected_args_size =
      param_patterns.size() - (self_id.has_value() ? 1 : 0);
  return {expected_args_size, expected_args_size};
}

// Returns the leaf parameter pattern of a parameter pattern, looking through
// binding and `var` wrappers, or `None` if there is none.
static auto GetLeafParamPattern(Context& context, SemIR::InstId pattern_id)
    -> SemIR::InstId {
  while (true) {
    auto inst = context.insts().Get(pattern_id);
    if (inst.Is<SemIR::AnyLeafParamPattern>()) {
      return pattern_id;
    }
    if (auto binding = inst.TryAs<SemIR::WrapperBindingPattern>()) {
      pattern_id = binding->subpattern_id;
    } else if (auto var_pattern = inst.TryAs<SemIR::AnyVarPattern>()) {
      pattern_id = var_pattern->subpattern_id;
    } else {
      return SemIR::InstId::None;
    }
  }
}

// D-OV-4 step 2(e)'s literal pre-test: returns false when `arg_id` is an
// integer literal constant that does not fit `param_type_id`. Constant
// evaluation of `int.convert_checked` diagnoses an out-of-range literal
// unconditionally and still produces a value, so a bare non-diagnosing
// conversion would both accept the member and diagnose; the pre-test rejects
// the member silently instead, through the same range checks the builtin uses.
static auto IntLiteralArgFitsParam(Context& context, SemIR::InstId arg_id,
                                   SemIR::TypeId param_type_id) -> bool {
  auto const_inst_id = context.constant_values().GetConstantInstId(arg_id);
  if (!const_inst_id.has_value()) {
    return true;
  }
  auto int_value = context.insts().TryGetAs<SemIR::IntValue>(const_inst_id);
  if (!int_value ||
      !context.types().Is<SemIR::IntLiteralType>(int_value->type_id)) {
    return true;
  }
  auto param_int_info = context.types().TryGetIntTypeInfo(param_type_id);
  if (!param_int_info) {
    return true;
  }
  const auto& value = context.ints().Get(int_value->int_id);
  uint64_t width =
      param_int_info->bit_width.has_value()
          ? context.ints().Get(param_int_info->bit_width).getZExtValue()
          : value.getBitWidth();
  return IntFitsInIntType(value, param_int_info->is_signed, width);
}

// Probes whether every argument of a call converts to the corresponding
// parameter of `function`, without diagnosing and without leaving any
// instruction, cleanup, or generic-region state behind (D-OV-4 step 2(e)).
// `arg_ids` is `self` (if bound) followed by the explicit arguments, zipped
// against all of the function's parameter patterns as `CallerPatternMatch`
// does. A bound receiver is never converted here: its presence was checked by
// the caller, and binding it is the commit's job.
static auto ProbeOverloadCandidate(Context& context, SemIR::LocId loc_id,
                                   const SemIR::Function& function,
                                   SemIR::SpecificId enclosing_specific_id,
                                   SemIR::InstId self_id,
                                   llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> OverloadProbeResult {
  auto param_pattern_ids =
      context.inst_blocks().GetOrEmpty(function.param_patterns_id);
  CARBON_CHECK(param_pattern_ids.size() == arg_ids.size());

  // Snapshot the enclosing block and the cleanup stack, then open a scratch
  // block and a fresh generic region so that conversions the probe performs
  // are discarded rather than added to the enclosing block or generic.
  auto enclosing_size =
      context.inst_block_stack().PeekCurrentBlockContents().size();
  auto cleanup_depth = context.scope_stack().cleanup_scope_depth();
  context.inst_block_stack().Push();
  context.generic_region_stack().Push({.generic_id = SemIR::GenericId::None});

  OverloadProbeResult result;
  for (auto [index, arg_id, param_pattern_id] :
       llvm::enumerate(arg_ids, param_pattern_ids)) {
    if (index == 0 && self_id.has_value()) {
      // The bound receiver.
      continue;
    }
    auto param_type_id = GetScrutineeTypeInSpecific(context, param_pattern_id,
                                                    enclosing_specific_id);
    if (param_pattern_id == function.self_param_id) {
      // An explicit receiver for a method member reached without a bound
      // receiver, such as `C.M(c, 1)`: argument 0 is matched against the
      // `self` pattern. A by-value `self` is a value conversion; a `ref self`
      // or `addr self` receiver is D-OV-6 gate (xii).
      auto leaf_id = GetLeafParamPattern(context, param_pattern_id);
      if (!leaf_id.has_value() ||
          !context.insts().Is<SemIR::ValueParamPattern>(leaf_id)) {
        context.TODO(loc_id,
                     "explicit receiver for a `ref self`/`addr self` "
                     "overload member");
        result.reject_reason = OverloadRejectReason::Conversion;
        result.gated = true;
        break;
      }
    } else if (!IntLiteralArgFitsParam(context, arg_id, param_type_id)) {
      result.reject_reason = OverloadRejectReason::Conversion;
      break;
    }
    if (TryConvertToValueOfType(context, SemIR::LocId(arg_id), arg_id,
                                param_type_id) == SemIR::ErrorInst::InstId) {
      result.reject_reason = OverloadRejectReason::Conversion;
      break;
    }
  }

  // Unwind on every exit path: the scratch block, the generic region, and any
  // cleanups a materialized temporary registered during the probe (which
  // `PopAndDiscard` does not touch and the statement's cleanup emission would
  // otherwise `Destroy` in the enclosing block).
  context.generic_region_stack().Pop();
  context.inst_block_stack().PopAndDiscard();
  context.scope_stack().DiscardCleanupsSince(cleanup_depth);
  CARBON_CHECK(context.inst_block_stack().PeekCurrentBlockContents().size() ==
                       enclosing_size &&
                   context.scope_stack().cleanup_scope_depth() == cleanup_depth,
               "Overload resolution probe leaked into the enclosing block");
  return result;
}

// Performs a call where the callee is a Carbon `overload fn` set: resolves the
// call to the first member, in declaration order, that accepts the arguments
// (F-009, D-OV-4), then performs the ordinary call to that member.
static auto PerformCallToOverloadSet(Context& context, SemIR::LocId loc_id,
                                     const SemIR::CalleeOverloadSet& overload,
                                     llvm::ArrayRef<SemIR::InstId> arg_ids,
                                     bool is_desugared) -> SemIR::InstId {
  // Erroneous arguments were diagnosed where they arose; the ordinary call
  // path stays silent on them too.
  if (llvm::is_contained(arg_ids, SemIR::ErrorInst::InstId)) {
    return SemIR::ErrorInst::InstId;
  }

  // D-OV-6 gate (xi): resolution over template-dependent arguments happens
  // after substitution, which is not supported yet.
  for (auto arg_id : arg_ids) {
    auto type_dependence = context.constant_values().GetDependence(
        context.types().GetConstantId(context.insts().Get(arg_id).type_id()));
    auto value_dependence = context.constant_values().GetDependence(
        context.constant_values().Get(arg_id));
    if (type_dependence == SemIR::ConstantDependence::Template ||
        value_dependence == SemIR::ConstantDependence::Template) {
      context.TODO(loc_id,
                   "overload resolution with template-dependent arguments");
      return SemIR::ErrorInst::InstId;
    }
  }

  // Copy what the loop needs out of the store: the commit path below may add
  // instructions and entities.
  const auto& overload_set =
      context.overload_sets().Get(overload.overload_set_id);
  auto name_id = overload_set.name_id;
  auto member_decl_ids = overload_set.member_decl_ids;
  auto self_id = overload.self_id;
  llvm::ArrayRef<SemIR::InstId> self_refs = {};
  if (self_id.has_value()) {
    self_refs = self_id;
  }
  auto all_arg_ids =
      llvm::to_vector<8>(llvm::concat<const SemIR::InstId>(self_refs, arg_ids));

  llvm::SmallVector<OverloadRejectReason, 4> reject_reasons;
  for (auto member_decl_id : member_decl_ids) {
    auto function_id =
        context.insts().GetAs<SemIR::FunctionDecl>(member_decl_id).function_id;
    const auto& function = context.functions().Get(function_id);

    // (a) A bound receiver needs a member with a `self` pattern. The reverse
    // combination — a method member reached without a bound receiver — is a
    // legal call shape (`C.M(c, 1)`), matched by the probe.
    if (self_id.has_value() && !function.self_param_id.has_value()) {
      reject_reasons.push_back(OverloadRejectReason::ReceiverOnNonMethod);
      continue;
    }

    // (b) Arity, keyed on the call's receiver as the ordinary call path is.
    auto [min_args, max_args] =
        GetExplicitArityRange(context, function, self_id);
    if (arg_ids.size() < min_args || arg_ids.size() > max_args) {
      reject_reasons.push_back(OverloadRejectReason::Arity);
      continue;
    }

    // (e) The conversion probe. (Generic members are gated in 0.1, so there is
    // no deduction step here; OV-2 adds it inside the same discard scope.)
    auto probe = ProbeOverloadCandidate(context, loc_id, function,
                                        overload.enclosing_specific_id, self_id,
                                        all_arg_ids);
    if (probe.gated) {
      return SemIR::ErrorInst::InstId;
    }
    if (probe.reject_reason) {
      reject_reasons.push_back(*probe.reject_reason);
      continue;
    }

    // Commit: name the member afresh and run the ordinary call path on it,
    // reusing nothing the probe produced.
    auto callee_id = BuildNameRef(context, loc_id, name_id, member_decl_id,
                                  overload.enclosing_specific_id);
    if (self_id.has_value()) {
      callee_id = GetOrAddInst<SemIR::BoundMethod>(
          context, loc_id,
          {.type_id =
               GetSingletonType(context, SemIR::BoundMethodType::TypeInstId),
           .object_id = self_id,
           .function_decl_id = callee_id});
    }
    return PerformCallToFunction(
        context, loc_id, callee_id,
        GetCalleeAsFunction(context.sem_ir(), callee_id), arg_ids,
        is_desugared);
  }

  CARBON_DIAGNOSTIC(OverloadNoMatch, Error,
                    "no member of overload set `{0}` accepts this call",
                    SemIR::NameId);
  CARBON_DIAGNOSTIC(OverloadCandidateRejected, Note,
                    "candidate {0:=0:takes a different number of arguments"
                    "|=1:has a parameter its argument cannot implicitly "
                    "convert to"
                    "|=2:has generic parameters that could not be deduced"
                    "|=3:is not an instance method but the call provides a "
                    "receiver}",
                    Diagnostics::IntAsSelect);
  auto builder = context.emitter().Build(loc_id, OverloadNoMatch, name_id);
  for (auto [member_decl_id, reason] :
       llvm::zip_equal(member_decl_ids, reject_reasons)) {
    builder.Note(SemIR::LocId(member_decl_id), OverloadCandidateRejected,
                 static_cast<int>(reason));
  }
  builder.Emit();
  return SemIR::ErrorInst::InstId;
}

// Performs a call where the callee is a generic type. If it's not a generic
// type, produces a diagnostic.
static auto PerformCallToNonFunction(Context& context, SemIR::LocId loc_id,
                                     SemIR::InstId callee_id,
                                     llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> SemIR::InstId {
  auto type_inst =
      context.types().GetAsInst(context.insts().Get(callee_id).type_id());
  CARBON_KIND_SWITCH(type_inst) {
    case CARBON_KIND(SemIR::CppTemplateNameType template_name): {
      return PerformCallToCppTemplateName(context, loc_id,
                                          template_name.decl_id, arg_ids);
    }
    case CARBON_KIND(SemIR::GenericClassType generic_class): {
      return PerformCallToGenericClass(context, loc_id, generic_class.class_id,
                                       generic_class.enclosing_specific_id,
                                       arg_ids);
    }
    case CARBON_KIND(SemIR::GenericInterfaceType generic_interface): {
      return PerformCallToGenericInterfaceOrNamedConstaint(
          context, loc_id, generic_interface.interface_id,
          generic_interface.enclosing_specific_id, arg_ids);
    }
    case CARBON_KIND(SemIR::GenericNamedConstraintType generic_constraint): {
      return PerformCallToGenericInterfaceOrNamedConstaint(
          context, loc_id, generic_constraint.named_constraint_id,
          generic_constraint.enclosing_specific_id, arg_ids);
    }
    default: {
      CARBON_DIAGNOSTIC(CallToNonCallable, Error,
                        "value of type {0} is not callable", TypeOfInstId);
      context.emitter().Emit(loc_id, CallToNonCallable, callee_id);
      return SemIR::ErrorInst::InstId;
    }
  }
}

auto PerformCall(Context& context, SemIR::LocId loc_id, SemIR::InstId callee_id,
                 llvm::ArrayRef<SemIR::InstId> arg_ids, bool is_desugared)
    -> SemIR::InstId {
  // Try treating the callee as a function first.
  auto callee = GetCallee(context.sem_ir(), callee_id);
  CARBON_KIND_SWITCH(callee) {
    case CARBON_KIND(SemIR::CalleeError _): {
      return SemIR::ErrorInst::InstId;
    }
    case CARBON_KIND(SemIR::CalleeFunction fn): {
      return PerformCallToFunction(context, loc_id, callee_id, fn, arg_ids,
                                   is_desugared);
    }
    case CARBON_KIND(SemIR::CalleeNonFunction _): {
      return PerformCallToNonFunction(context, loc_id, callee_id, arg_ids);
    }

    case CARBON_KIND(SemIR::CalleeCppOverloadSet overload): {
      return PerformCallToCppFunction(context, loc_id,
                                      overload.cpp_overload_set_id,
                                      overload.self_id, arg_ids, is_desugared);
    }
    case CARBON_KIND(SemIR::CalleeOverloadSet overload): {
      return PerformCallToOverloadSet(context, loc_id, overload, arg_ids,
                                      is_desugared);
    }
  }
}

}  // namespace Carbon::Check
