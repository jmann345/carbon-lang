// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <optional>

#include "toolchain/check/call.h"
#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/core_identifier.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/impl_lookup.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/member_access.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/operator.h"
#include "toolchain/check/pattern_match.h"
#include "toolchain/check/return.h"
#include "toolchain/diagnostics/emitter.h"
#include "toolchain/parse/typed_nodes.h"
#include "toolchain/sem_ir/class.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// The check desugar of the postfix `?` operator (fork/b1/plan.md §2.4;
// docs/design/error_handling.md, "Semantics and desugaring"), built entirely
// from existing machinery — no new inst kinds, no lowering changes. For
// `expr?` in a function returning `R`:
//
//   1. Pre-flight (`CheckQuestionPreflight`): every enclosing-context
//      requirement is diagnosed before the first inst is emitted.
//   2. `expr` is evaluated exactly once.
//   3. `expr.(Core.Try.Branch)()` produces a `Core.ControlFlow(C, B)`
//      carrier value, materialized as the dispatch scrutinee.
//   4. The carrier's discriminant is tested against `Break` (discriminant 1,
//      fixed by the prelude's alternative order), branching to a break block
//      with the continue block as the fall-through.
//   5. Break block: the `Break` payload is extracted (reference projection,
//      no copy), passed to `R.(Core.Try.FromBreak)` — the argument
//      conversion to `R`'s break type is the D3/F-006c `ImplicitAs` error
//      conversion, applied by the ordinary call machinery — and the call
//      result is returned with the whole-function cleanup discharge every
//      `return` performs.
//   6. Continue block: the `Continue` payload, converted to a value, is the
//      value of `expr?`; expression checking resumes in the continue block
//      (the short-circuit `and`/`or` block-switch precedent). The break path
//      diverges, so no convergence argument is needed.

namespace {
// The types needed to extract one carrier alternative's single payload
// element, resolved (pure queries, no emission) before any CFG exists so a
// malformed carrier bails before the desugar commits to branching.
struct CarrierPayload {
  // The alternative's name-to-index metadata.
  SemIR::ChoiceAlternative alternative;
  // The carrier's payload region (field 1 of its object representation).
  SemIR::TypeId payload_region_type_id;
  // The alternative's payload tuple within the region.
  SemIR::TypeId payload_tuple_type_id;
  // The tuple's single element type: `C` for `Continue`, `B` for `Break`.
  SemIR::TypeId element_type_id;
};

// What the pre-flight hands to the desugar on success.
struct QuestionPreflight {
  // The enclosing function's declared return type; `None` when the
  // pre-flight diagnosed (or found an already-diagnosed error).
  SemIR::TypeId return_type_id;
  // The `Core.Try` interface declaration, resolved once by the pre-flight —
  // a constant (`LookupNameInCore` resolves through constant values, adding
  // nothing to the scratch block), so the break path reuses it rather than
  // deriving the interface a second time.
  SemIR::InstId try_interface_id = SemIR::InstId::None;
};
}  // namespace

// Resolves the extraction types for the carrier alternative named `name_id`.
// Returns nullopt if the carrier is not a complete choice with a
// single-element payload tuple for that alternative — reachable under error
// recovery (for example, an all-payloads-rejected carrier specific resolves
// its representation to `ErrorInst`), so the caller bails to `ErrorInst`
// rather than asserting.
static auto ResolveCarrierPayload(Context& context,
                                  SemIR::TypeId carrier_type_id,
                                  SemIR::NameId name_id)
    -> std::optional<CarrierPayload> {
  auto alternative = LookupChoiceAlternative(context, carrier_type_id, name_id);
  if (!alternative || alternative->payload_field_index < 0) {
    return std::nullopt;
  }
  auto payload_info = GetChoicePayloadInfo(context, carrier_type_id,
                                           alternative->payload_field_index);
  if (!payload_info) {
    return std::nullopt;
  }
  auto tuple_type = context.types().TryGetAs<SemIR::TupleType>(
      payload_info->payload_tuple_type_id);
  if (!tuple_type) {
    return std::nullopt;
  }
  auto element_type_inst_ids =
      context.inst_blocks().Get(tuple_type->type_elements_id);
  if (element_type_inst_ids.size() != 1) {
    return std::nullopt;
  }
  return CarrierPayload{
      .alternative = *alternative,
      .payload_region_type_id = payload_info->payload_region_type_id,
      .payload_tuple_type_id = payload_info->payload_tuple_type_id,
      .element_type_id =
          *context.types().GetBlockAsTypeIds(element_type_inst_ids).begin()};
}

// Emits the extraction of `payload`'s element from `carrier_id` (a value or
// reference expression of a `Core.ControlFlow` specific) into the current
// block, and returns it as a value expression. The `ClassElementAccess`
// chain is reference projection — the bind-pass shape from
// handle_match.cpp's payload arms — so no choice value is copied; the final
// value conversion copies the scalar element only.
static auto EmitCarrierPayloadExtraction(Context& context,
                                         Parse::NodeId node_id,
                                         SemIR::InstId carrier_id,
                                         const CarrierPayload& payload)
    -> SemIR::InstId {
  auto payload_ref_id = AddInst<SemIR::ClassElementAccess>(
      context, node_id,
      {.type_id = payload.payload_region_type_id,
       .base_id = carrier_id,
       .index = SemIR::ElementIndex(1)});
  auto tuple_ref_id = AddInst<SemIR::ClassElementAccess>(
      context, node_id,
      {.type_id = payload.payload_tuple_type_id,
       .base_id = payload_ref_id,
       .index = SemIR::ElementIndex(payload.alternative.payload_field_index)});
  auto element_ref_id =
      AddInst<SemIR::TupleAccess>(context, node_id,
                                  {.type_id = payload.element_type_id,
                                   .tuple_id = tuple_ref_id,
                                   .index = SemIR::ElementIndex(0)});
  return ConvertToValueExpr(context, element_ref_id);
}

// Diagnoses the enclosing-context requirements of `?` before any inst is
// emitted (fork/b1/plan.md §2.4 step 1): a function scope, straight-line
// body position (no captured expression region), a declared
// initializing-form return type, no `returned var` in scope, and a return
// type implementing `Core.Try`. Returns the declared return type (plus the
// resolved `Core.Try` interface) on success, and a `None` return type after
// diagnosing — or, for already-diagnosed error recovery, silently.
static auto CheckQuestionPreflight(Context& context,
                                   Parse::PostfixOperatorQuestionId node_id)
    -> QuestionPreflight {
  // D4: `?` targets the innermost enclosing function's declared return type.
  // File scope and global initializers have no function scope.
  if (!context.scope_stack().IsInFunctionScope()) {
    CARBON_DIAGNOSTIC(QuestionOutsideFunction, Error,
                      "`?` can only be used inside a function body");
    context.emitter().Emit(node_id, QuestionOutsideFunction);
    return {.return_type_id = SemIR::TypeId::None};
  }

  // The region-position policy (fork/b1/plan.md §2.4): the desugar emits a
  // `ReturnExpr` terminator plus multi-block CFG, which captured expression
  // regions — `case` guards, `case` expression patterns, and binding type
  // expressions — do not support (their splice consumers assume
  // branch-terminated, single-exit regions). The function body is region
  // depth 1 and every captured region nests above it, so a depth greater
  // than 1 is diagnosed and rejected up front. Ordinary statement, argument,
  // and initializer positions run at depth 1 and are unaffected.
  if (context.region_stack().depth() > 1) {
    CARBON_DIAGNOSTIC(QuestionInPatternContext, Error,
                      "`?` cannot be used inside a pattern, a `case` guard, "
                      "or a binding's type expression");
    context.emitter().Emit(node_id, QuestionInPatternContext);
    return {.return_type_id = SemIR::TypeId::None};
  }

  const auto& function = GetCurrentFunctionForReturn(context);
  auto return_type_id = function.GetDeclaredReturnType(context.sem_ir());
  // D4: no auto-return functions — `?` needs a declared return type to
  // rebuild through `FromBreak`.
  if (!return_type_id.has_value()) {
    CARBON_DIAGNOSTIC(QuestionNoDeclaredReturnType, Error,
                      "`?` requires the enclosing function to have a declared "
                      "return type that implements `Core.Try`");
    auto diag = context.emitter().Build(node_id, QuestionNoDeclaredReturnType);
    NoteNoReturnTypeProvided(diag, function);
    diag.Emit();
    return {.return_type_id = SemIR::TypeId::None};
  }
  if (return_type_id == SemIR::ErrorInst::TypeId) {
    // Already diagnosed at the declaration.
    return {.return_type_id = SemIR::TypeId::None};
  }

  // The break path returns through `BuildReturnWithExpr`'s `InitForm` path
  // (`InitializeExisting(..., for_return=true)`); `ref`-form and
  // symbolic-form returns are rejected up front rather than surfacing a
  // conversion failure deep in the return machinery.
  auto return_form_id = function.GetDeclaredReturnForm(context.sem_ir());
  if (return_form_id == SemIR::ErrorInst::InstId) {
    // Already diagnosed at the declaration.
    return {.return_type_id = SemIR::TypeId::None};
  }
  if (!return_form_id.has_value() ||
      !context.insts().Is<SemIR::InitForm>(return_form_id)) {
    // The two non-`InitForm` shapes are `RefForm` (`-> ref T`, or a concrete
    // `->?` form expression evaluating to a `ref` form) and
    // `SymbolicBinding` (a symbolic form, `->? Fm`); the message names both.
    CARBON_DIAGNOSTIC(QuestionNonInitReturnForm, Error,
                      "`?` cannot be used in a function whose return uses a "
                      "`ref` form or a symbolic form");
    auto diag = context.emitter().Build(node_id, QuestionNonInitReturnForm);
    if (function.return_form_inst_id.has_value()) {
      NoteReturnForm(diag, function);
    }
    diag.Emit();
    return {.return_type_id = SemIR::TypeId::None};
  }

  // A `returned var` in scope commandeers returning: `return <expr>;` is
  // unavailable while one is in flight (return.cpp's
  // ReturnExprWithReturnedVar), and the break path returns through exactly
  // that initializing-expression form. Rejected here so `?` never reaches
  // `BuildReturnWithExpr` mid-desugar with CFG already emitted.
  if (auto returned_var_id = context.scope_stack().GetReturnedVar();
      returned_var_id.has_value()) {
    CARBON_DIAGNOSTIC(QuestionInReturnedVarScope, Error,
                      "`?` cannot be used in the scope of a `returned var`; "
                      "`?` returns through an initializing expression");
    auto diag = context.emitter().Build(node_id, QuestionInReturnedVarScope);
    NoteReturnedVar(diag, returned_var_id);
    diag.Emit();
    return {.return_type_id = SemIR::TypeId::None};
  }

  // The return-type `Try` witness pre-flight (fork/b1/plan.md §2.4, the A-1
  // correction): `FromBreak` has no `self`, so the break path's compound
  // access takes the non-instance branch, which never consults the
  // missing-impl diagnostic hook — without this check a non-`Try` return
  // type would surface as a note-less facet-conversion failure at the
  // `FromBreak` access. The lookup runs in a discarded scratch block: only
  // the yes/no answer is used here (the break path re-derives the witness
  // through its own compound access), and constants persist independently,
  // so the pre-flight emits nothing.
  auto implicit_loc_id =
      context.insts().GetLocIdForDesugaring(SemIR::LocId(node_id));
  context.inst_block_stack().Push();
  // The lookup can synthesize symbolic instructions (`Converted`,
  // `FacetAccessType`, ...) that are dropped with the scratch block; push a
  // fresh generic region so they are not also registered in an enclosing
  // generic's eval region — otherwise `?` in a generic body would leave the
  // eval region referring to instructions in no body block (the
  // DeduceImplArguments precedent, deduce.cpp: "We also need to avoid adding
  // those dropped instructions to any enclosing generic").
  context.generic_region_stack().Push({.generic_id = SemIR::GenericId::None});
  auto try_interface_id =
      LookupNameInCore(context, implicit_loc_id, CoreIdentifier::Try);
  auto try_facet_type = ExprAsType(context, implicit_loc_id, try_interface_id,
                                   /*diagnose=*/false);
  bool errored = try_facet_type.type_id == SemIR::ErrorInst::TypeId;
  bool implements_try = false;
  if (!errored) {
    auto lookup_result = LookupImplWitness(
        context, SemIR::LocId(node_id),
        context.types().GetConstantId(return_type_id),
        try_facet_type.type_id.AsConstantId(), /*diagnose=*/false);
    errored = lookup_result.has_error_value();
    implements_try = !errored && lookup_result.has_value();
  }
  context.generic_region_stack().Pop();
  context.inst_block_stack().PopAndDiscard();
  if (errored) {
    // Already diagnosed.
    return {.return_type_id = SemIR::TypeId::None};
  }
  if (!implements_try) {
    // The lookup may have grown the function store; re-fetch rather than
    // holding `function` across it.
    const auto& current_function = GetCurrentFunctionForReturn(context);
    CARBON_DIAGNOSTIC(QuestionReturnTypeNotTry, Error,
                      "return type {0} of the enclosing function does not "
                      "implement `Core.Try`",
                      InstIdAsType);
    auto diag = context.emitter().Build(node_id, QuestionReturnTypeNotTry,
                                        current_function.return_type_inst_id);
    NoteReturnType(diag, current_function);
    diag.Emit();
    return {.return_type_id = SemIR::TypeId::None};
  }
  return {.return_type_id = return_type_id,
          .try_interface_id = try_interface_id};
}

auto HandleParseNode(Context& context, Parse::PostfixOperatorQuestionId node_id)
    -> bool {
  auto operand_id = context.node_stack().PopExpr();
  if (operand_id == SemIR::ErrorInst::InstId) {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // Step 1: everything is diagnosed before the first inst exists.
  auto preflight = CheckQuestionPreflight(context, node_id);
  auto return_type_id = preflight.return_type_id;
  if (!return_type_id.has_value()) {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // Step 2: evaluate the operand exactly once, as a value or reference.
  // Symbolic operand types are NOT gated (the W-071 discharge,
  // fork/b2/plan.md §2.2-2.3): a symbolic CHOICE carrier specific is
  // destroyable through `CanDestroyClass`'s choice clause
  // (custom_witness.cpp), so the carrier temporary's standard cleanup
  // discharge — the same one a `var` or a match scrutinee temporary of this
  // type gets — resolves. An operand that is itself a temporary of a bare
  // symbolic-binding type diagnoses the ordinary missing-`Core.Destroy`
  // error, exactly like any other symbolic non-choice temporary — no `?`
  // carve-out in either direction (the §2.3 uniformity policy, pinned by
  // fail_question_generic.carbon's fail_symbolic_temporary_uniformity subfile).
  operand_id = ConvertToValueOrRefExpr(context, operand_id);

  // Step 3: `operand.(Core.Try.Branch)()`. `Branch` has `self`, so the
  // compound access takes the instance branch, where the missing-impl hook
  // is live. The interface signature guarantees the call's type is a
  // `Core.ControlFlow(C, B)` specific with the impl's associated constants
  // substituted; the desugar reads `C` and `B` off that type below, never
  // off the witness directly.
  auto branch_call_id = BuildUnaryOperator(
      context, node_id,
      {.interface_name = CoreIdentifier::Try,
       .op_name = CoreIdentifier::Branch},
      operand_id, /*diagnose=*/true, [&](auto& builder) {
        CARBON_DIAGNOSTIC(QuestionOperandNotTry, Context,
                          "operand of `?` does not implement `Core.Try`");
        builder.Context(node_id, QuestionOperandNotTry);
      });
  if (branch_call_id == SemIR::ErrorInst::InstId) {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }
  auto carrier_id = ConvertToValueOrRefExpr(context, branch_call_id);
  auto carrier_type_id = context.insts().Get(carrier_id).type_id();

  // Resolve everything the dispatch and both payload extractions need before
  // emitting any CFG. The Branch call itself completed the carrier specific
  // (materializing its result requires the representation), so a nullopt
  // here is error recovery — an already-diagnosed malformed carrier — and
  // bails to `ErrorInst` without asserting.
  auto disc_type_id = GetChoiceDiscriminantType(context, carrier_type_id);
  auto continue_payload = ResolveCarrierPayload(
      context, carrier_type_id,
      SemIR::NameId::ForIdentifier(context.identifiers().Add("Continue")));
  auto break_payload = ResolveCarrierPayload(
      context, carrier_type_id,
      SemIR::NameId::ForIdentifier(context.identifiers().Add("Break")));
  if (!disc_type_id || !continue_payload || !break_payload) {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // Step 4: test the discriminant against `Break` (discriminant 1, fixed by
  // the prelude's Continue-then-Break declaration order) and branch. The
  // break block is the taken edge; the continue block is the fall-through.
  auto cond_id =
      EmitChoiceDiscriminantTest(context, node_id, carrier_id, *disc_type_id,
                                 break_payload->alternative.index);
  auto break_block_id = AddDominatedBlockAndBranchIf(context, node_id, cond_id);
  auto continue_block_id = AddDominatedBlockAndBranch(context, node_id);

  // Step 5, the break block: extract the break payload, rebuild the return
  // type through `R.(Core.Try.FromBreak)`, and return early. The compound
  // access on the return type takes the non-instance branch under the
  // pre-flight's witness guarantee; the defensive `ErrorInst` bail is
  // retained, and `BuildReturnWithExpr` still terminates the block on that
  // path. The argument conversion in `PerformCall` is the `ImplicitAs`
  // error conversion (D3); `BuildReturnWithExpr` forwards the initializing
  // call result into the return slot and discharges every enclosing cleanup
  // (`AddReturnInstWithCleanups`) — the continue path discharges the same
  // set at statement end, and the paths are exclusive.
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(break_block_id);
  context.region_stack().AddToRegion(break_block_id, node_id);
  {
    auto break_value_id = EmitCarrierPayloadExtraction(
        context, node_id, carrier_id, *break_payload);
    auto implicit_loc_id =
        context.insts().GetLocIdForDesugaring(SemIR::LocId(node_id));
    // `Core.Try` was already resolved (to a constant) by the pre-flight;
    // reuse it rather than deriving the interface a second time.
    auto from_break_decl_id = PerformMemberAccess(
        context, implicit_loc_id, preflight.try_interface_id,
        context.core_identifiers().AddNameId(CoreIdentifier::FromBreak));
    auto bound_from_break_id = PerformCompoundMemberAccess(
        context, SemIR::LocId(node_id),
        context.types().GetTypeInstId(return_type_id), from_break_decl_id);
    auto return_value_id = SemIR::ErrorInst::InstId;
    if (bound_from_break_id != SemIR::ErrorInst::InstId) {
      return_value_id =
          PerformCall(context, SemIR::LocId(node_id), bound_from_break_id,
                      {break_value_id}, /*is_desugared=*/true);
    }
    BuildReturnWithExpr(context, SemIR::LocId(node_id), return_value_id);
  }

  // Step 6, the continue block: the extracted continue payload is the value
  // of `expr?`, and checking of the enclosing expression resumes here.
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(continue_block_id);
  context.region_stack().AddToRegion(continue_block_id, node_id);
  auto value_id = EmitCarrierPayloadExtraction(context, node_id, carrier_id,
                                               *continue_payload);
  context.node_stack().Push(node_id, value_id);
  return true;
}

}  // namespace Carbon::Check
