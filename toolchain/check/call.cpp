// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/call.h"

#include <optional>
#include <utility>

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "toolchain/base/kind_switch.h"
#include "toolchain/check/action.h"
#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/cpp/call.h"
#include "toolchain/check/cpp/import.h"
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
#include "toolchain/check/type_completion.h"
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
// if no specific callee can be identified. This determines any compile-time
// arguments, but doesn't check that the runtime arguments are convertible to
// the parameter types. It also verifies that the number of arguments is within
// the range [callee_arity - arity_lower_bound_margin, callee_arity]. This
// allows arity matching when the callee has default arguments for some
// subpatterns. In all other cases supply the default value `0` for exact arity
// checking.
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
                                llvm::ArrayRef<SemIR::InstId> arg_ids,
                                int32_t arity_lower_bound_margin = 0)
    -> std::optional<SemIR::SpecificId> {
  // Check that the arity exactly matches or is the upper bound of the explicit
  // arguments.
  auto param_patterns =
      context.inst_blocks().GetOrEmpty(entity.param_patterns_id);
  size_t expected_args_size =
      param_patterns.size() - (self_id.has_value() ? 1 : 0);
  CARBON_CHECK(static_cast<size_t>(arity_lower_bound_margin) <=
               expected_args_size);
  size_t size_lower_bound =
      expected_args_size - static_cast<size_t>(arity_lower_bound_margin);
  if (arg_ids.size() < size_lower_bound ||
      arg_ids.size() > expected_args_size) {
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
  auto bound_method = SemIR::TryGetCalleeAsBoundMethod(
      context.sem_ir(), callee_id, SemIR::SpecificId::None);
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

// Fork (SL-1, fork/slices/plan.md §1.A.1 row 3, R-1): requires the pointee
// type that a builtin call's lowering must size to be complete at the call.
// `pointer.offset` strides by the pointee of its first parameter and
// `heap.allocate` multiplies the count by the pointee of its result's inner
// pointer; lowering represents an incomplete type as an opaque LLVM struct with
// no size (`FileContext::GetTypeAndDIType`), which nothing downstream can
// recover from. Nothing else at such a call completes the pointee: a pointer
// type is complete without its pointee, so `fn A(n: i64) -> MaybeUnformed(i32*)
// { return Alloc(i32, n); }` otherwise never completes `i32`. For a symbolic
// pointee this records a `RequireCompleteType` in the enclosing generic, so the
// requirement is enforced on each specific, in the specific's file.
static auto RequireBuiltinCallPointeeComplete(
    Context& context, SemIR::LocId loc_id, const SemIR::Function& callee,
    SemIR::TypeId return_type_id, SemIR::InstBlockId args_id) -> void {
  auto pointer_type_id = SemIR::TypeId::None;
  llvm::StringLiteral builtin_name = "";
  switch (callee.builtin_function_kind()) {
    case SemIR::BuiltinFunctionKind::PointerOffset: {
      auto arg_ids = context.inst_blocks().GetOrEmpty(args_id);
      if (arg_ids.empty()) {
        return;
      }
      pointer_type_id = context.insts().Get(arg_ids[0]).type_id();
      builtin_name = "pointer.offset";
      break;
    }
    case SemIR::BuiltinFunctionKind::HeapAllocate: {
      // The result is `MaybeUnformed(T*)`; in the prelude an adapter class
      // (`Core.MaybeUnformed`), so unwrap adapters first. The return type was
      // just completed by `CheckFunctionReturnPatternType`, so the adapted
      // type is resolved in the callee's specific.
      auto maybe_unformed = context.types().TryGetAs<SemIR::MaybeUnformedType>(
          context.types().GetTransitiveAdaptedType(return_type_id));
      if (!maybe_unformed) {
        return;
      }
      pointer_type_id =
          context.types().GetTypeIdForTypeInstId(maybe_unformed->inner_id);
      builtin_name = "heap.allocate";
      break;
    }
    default:
      return;
  }
  auto pointer_type =
      context.types().TryGetAs<SemIR::PointerType>(pointer_type_id);
  if (!pointer_type) {
    // An earlier error, or a signature the builtin's validation rejected.
    return;
  }
  auto pointee_type_id =
      context.types().GetTypeIdForTypeInstId(pointer_type->pointee_id);
  RequireCompleteType(context, pointee_type_id, loc_id, [&](auto& builder) {
    CARBON_DIAGNOSTIC(
        IncompleteTypeInBuiltinCall, Context,
        "pointee type {0} is incomplete in call to builtin function {1}",
        SemIR::TypeId, std::string);
    builder.Context(loc_id, IncompleteTypeInBuiltinCall, pointee_type_id,
                    builtin_name.str());
  });
}

auto PerformCallToFunction(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId callee_id,
                           const SemIR::CalleeFunction& callee_function,
                           llvm::ArrayRef<SemIR::InstId> arg_ids,
                           bool is_desugared) -> SemIR::InstId {
  // If the callee is a generic function, determine the generic argument values
  // for the call. Also check the arity of the function against the arguments,
  // with allowance for default argument values.
  const auto& function = context.functions().Get(callee_function.function_id);
  auto callee_specific_id = ResolveCalleeInCall(
      context, loc_id, function, EntityKind::Function,
      callee_function.enclosing_specific_id, callee_function.self_id, arg_ids,
      function.default_value_arity);
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
  if (callee.special_function_kind ==
      SemIR::Function::SpecialFunctionKind::Builtin) {
    RequireBuiltinCallPointeeComplete(context, loc_id, callee, return_type_id,
                                      converted_args_id);
  }
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
    case SemIR::Function::SpecialFunctionKind::Generated:
    case SemIR::Function::SpecialFunctionKind::CppThunk:
    case SemIR::Function::SpecialFunctionKind::CppFunctionPointerThunk: {
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
// binding and `var` wrappers (and, for an imported member, the import refs
// that carry its patterns), or `None` if there is none.
static auto GetLeafParamPattern(Context& context, SemIR::InstId pattern_id)
    -> SemIR::InstId {
  while (true) {
    if (auto const_inst_id =
            context.constant_values().GetConstantInstId(pattern_id);
        const_inst_id.has_value()) {
      pattern_id = const_inst_id;
    }
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

// The body of `ProbeOverloadCandidate`, run inside its scratch scope: deduces
// a generic member's arguments (D-OV-4 step 2(d)), then converts each explicit
// argument to its parameter type in the resulting specific (step 2(e)).
static auto ProbeOverloadCandidateInScratchScope(
    Context& context, SemIR::LocId loc_id, const SemIR::Function& function,
    SemIR::SpecificId enclosing_specific_id, SemIR::InstId self_id,
    llvm::ArrayRef<SemIR::InstId> arg_ids) -> OverloadProbeResult {
  auto param_pattern_ids =
      context.inst_blocks().GetOrEmpty(function.param_patterns_id);
  CARBON_CHECK(param_pattern_ids.size() == arg_ids.size());

  OverloadProbeResult result;

  // (d) A generic member (or a member of a generic class, which carries the
  // class's bindings): non-diagnosing deduction, whose `Converted`
  // instructions the scratch scope discards. The commit re-deduces the same
  // arguments diagnosing; `MakeSpecific` deduplicates the specific.
  auto specific_id = enclosing_specific_id;
  if (function.generic_id.has_value()) {
    specific_id = DeduceGenericCallArguments(
        context, loc_id, function.generic_id, enclosing_specific_id,
        function.implicit_param_patterns_id, function.param_patterns_id,
        self_id, arg_ids.drop_front(self_id.has_value() ? 1 : 0),
        /*diagnose=*/false);
    if (!specific_id.has_value()) {
      result.reject_reason = OverloadRejectReason::Deduction;
      return result;
    }
  }

  for (auto [index, arg_id, param_pattern_id] :
       llvm::enumerate(arg_ids, param_pattern_ids)) {
    if (index == 0 && self_id.has_value()) {
      // The bound receiver.
      continue;
    }
    auto param_type_id =
        GetScrutineeTypeInSpecific(context, param_pattern_id, specific_id);
    if (index == 0 && function.self_param_id.has_value()) {
      // An explicit receiver for a method member reached without a bound
      // receiver, such as `C.M(c, 1)`: argument 0 is matched against the
      // `self` pattern, which is positionally first as `CallerPatternMatch`
      // assumes (an imported member's `self_param_id` is a distinct import
      // ref from the entry in its parameter block, so position, not identity,
      // identifies it). A by-value `self` is a value conversion; a `ref self`
      // or `addr self` receiver is D-OV-6 gate (xii).
      auto leaf_id = GetLeafParamPattern(context, param_pattern_id);
      if (!leaf_id.has_value() ||
          !context.insts().Is<SemIR::ValueParamPattern>(leaf_id)) {
        context.TODO(loc_id,
                     "explicit receiver for a `ref self`/`addr self` "
                     "overload member");
        result.reject_reason = OverloadRejectReason::Conversion;
        result.gated = true;
        return result;
      }
    } else if (!IntLiteralArgFitsParam(context, arg_id, param_type_id)) {
      result.reject_reason = OverloadRejectReason::Conversion;
      return result;
    }
    if (TryConvertToValueOfType(context, SemIR::LocId(arg_id), arg_id,
                                param_type_id) == SemIR::ErrorInst::InstId) {
      result.reject_reason = OverloadRejectReason::Conversion;
      return result;
    }
  }
  return result;
}

// Probes whether a call's arguments select `function` — deducing a generic
// member's arguments and converting every argument to the corresponding
// parameter — without diagnosing and without leaving any instruction, cleanup,
// or generic-region state behind (D-OV-4 steps 2(d) and 2(e)). `arg_ids` is
// `self` (if bound) followed by the explicit arguments, zipped against all of
// the function's parameter patterns as `CallerPatternMatch` does. A bound
// receiver is never converted here: its presence was checked by the caller,
// and binding it is the commit's job.
static auto ProbeOverloadCandidate(Context& context, SemIR::LocId loc_id,
                                   const SemIR::Function& function,
                                   SemIR::SpecificId enclosing_specific_id,
                                   SemIR::InstId self_id,
                                   llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> OverloadProbeResult {
  // Snapshot the enclosing block and the cleanup stack, then open a scratch
  // block and a fresh generic region so that conversions the probe performs
  // are discarded rather than added to the enclosing block or generic.
  auto enclosing_size =
      context.inst_block_stack().PeekCurrentBlockContents().size();
  auto cleanup_depth = context.scope_stack().cleanup_scope_depth();
  context.inst_block_stack().Push();
  context.generic_region_stack().Push({.generic_id = SemIR::GenericId::None});

  auto result = ProbeOverloadCandidateInScratchScope(
      context, loc_id, function, enclosing_specific_id, self_id, arg_ids);

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

    // (d) Deduction for a generic member and (e) the conversion probe, both
    // inside one discard scope.
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
                    "|=3:is not an instance method, but the call provides a "
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

// Determines whether a C++ template call can be performed immediately
// (i.e. whether it is non-template-dependent).
static auto IsCppTemplateCallPerformable(Context& context,
                                         SemIR::InstId callee_id,
                                         llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> bool {
  CARBON_CHECK(OperandDependence(context, callee_id) <
               SemIR::ConstantDependence::Template);

  for (auto arg_id : arg_ids) {
    if (context.constant_values().Get(arg_id).is_symbolic()) {
      return false;
    }
  }
  return true;
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
      if (IsCppTemplateCallPerformable(context, callee_id, arg_ids)) {
        return PerformCallToCppTemplateName(context, loc_id,
                                            template_name.decl_id, arg_ids);
      }

      llvm::SmallVector<SemIR::InstId> inst_ids;
      inst_ids.push_back(callee_id);
      // Wrap symbolic template args in a `TemplateInst` so that all symbolic
      // arguments are treated as templates.
      for (auto arg_id : arg_ids) {
        if (context.constant_values().Get(arg_id).is_symbolic()) {
          auto arg = context.insts().Get(arg_id);
          inst_ids.push_back(
              AddInst(context, SemIR::LocId(arg_id),
                      SemIR::TemplateInst{.type_id = arg.type_id(),
                                          .inst_id = arg_id}));
        } else {
          inst_ids.push_back(arg_id);
        }
      }

      auto inst_block_id = context.inst_blocks().Add(inst_ids);
      return AddDependentActionSplice(
          context, loc_id,
          SemIR::CallAction{.type_id = SemIR::InstType::TypeId,
                            .inst_block_id = inst_block_id,
                            // Unused for non-function calls.
                            .is_desugared = SemIR::BoolValue::From(false)},
          SemIR::TypeInstId::None);
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

static auto PerformCallToCppFunctionPointer(
    Context& context, SemIR::LocId loc_id, SemIR::InstId function_ptr_id,
    SemIR::CalleeCppFunctionPointer fn_ptr,
    llvm::ArrayRef<SemIR::InstId> arg_ids) -> SemIR::InstId {
  auto pointer_info =
      ImportFunctionPointerInvoke(context, loc_id, fn_ptr.function_type_id);
  SemIR::CalleeFunction callee_function = {
      .function_id = pointer_info.function_id,
      .enclosing_specific_id = SemIR::SpecificId::None,
      .resolved_specific_id = SemIR::SpecificId::None,
      .self_type_id = SemIR::InstId::None,
      .self_id = function_ptr_id};

  return PerformCallToFunction(context, loc_id, pointer_info.decl_id,
                               callee_function, arg_ids, /*is_desugared=*/true);
}

// Determines whether a call can be performed immediately (i.e. whether it is
// non-template-dependent).
static auto IsCallPerformable(Context& context, SemIR::InstId callee_id,
                              llvm::ArrayRef<SemIR::InstId> arg_ids) -> bool {
  if (OperandDependence(context, callee_id) ==
      SemIR::ConstantDependence::Template) {
    return false;
  }
  for (auto arg_id : arg_ids) {
    if (OperandDependence(context, arg_id) ==
        SemIR::ConstantDependence::Template) {
      return false;
    }
  }
  return true;
}

// Common logic for `PerformCall` and `PerformAction`.
static auto PerformCallHelper(Context& context, SemIR::LocId loc_id,
                              SemIR::InstId callee_id,
                              llvm::ArrayRef<SemIR::InstId> arg_ids,
                              bool is_desugared) {
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
    case CARBON_KIND(SemIR::CalleeCppFunctionPointer fn_ptr): {
      return PerformCallToCppFunctionPointer(context, loc_id, callee_id, fn_ptr,
                                             arg_ids);
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

auto PerformCall(Context& context, SemIR::LocId loc_id, SemIR::InstId callee_id,
                 llvm::ArrayRef<SemIR::InstId> arg_ids, bool is_desugared)
    -> SemIR::InstId {
  if (IsCallPerformable(context, callee_id, arg_ids)) {
    return PerformCallHelper(context, loc_id, callee_id, arg_ids, is_desugared);
  }

  // Pack the callee and args into an inst block. This is an optimization to
  // avoid needing a Bundle in the `CallAction`.
  llvm::SmallVector<SemIR::InstId> inst_ids;
  inst_ids.reserve(1 + arg_ids.size());
  inst_ids.push_back(callee_id);
  inst_ids.append(arg_ids.begin(), arg_ids.end());
  auto inst_block_id = context.inst_blocks().Add(inst_ids);

  return HandleAction<SemIR::CallAction>(
      context, loc_id, SemIR::TypeInstId::None,
      {.type_id = SemIR::InstType::TypeId,
       .inst_block_id = inst_block_id,
       .is_desugared = SemIR::BoolValue::From(is_desugared)});
}

auto PerformAction(Context& context, SemIR::LocId loc_id,
                   SemIR::CallAction action) -> SemIR::InstId {
  auto inst_ids = context.inst_blocks().Get(action.inst_block_id);
  auto callee_id = inst_ids[0];
  auto arg_ids = inst_ids.slice(1);
  return PerformCallHelper(context, loc_id, callee_id, arg_ids,
                           action.is_desugared.ToBool());
}

}  // namespace Carbon::Check
