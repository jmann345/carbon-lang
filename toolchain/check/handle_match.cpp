// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <optional>

#include "common/raw_string_ostream.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringExtras.h"
#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/member_access.h"
#include "toolchain/check/pattern.h"
#include "toolchain/check/pattern_match.h"
#include "toolchain/check/type.h"
#include "toolchain/diagnostics/format_providers.h"
#include "toolchain/lex/token_kind.h"
#include "toolchain/sem_ir/expr_info.h"
#include "toolchain/sem_ir/type.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// A `match` statement is checked in two layers:
//
// Pattern layer: each `case` pattern is checked into pattern SemIR inside a
// per-arm full-pattern context (`MatchCaseIntroducer` through `MatchCase`),
// mirroring the `for` loop's driving sequence in handle_loop_statement.cpp,
// and the finished pattern block is attached to a `NameBindingDecl` in the
// arm's test block — the same SemIR home `let` and `var` give their patterns.
// The arm's refutable test is emitted by `MatchCasePatternMatch`
// (pattern_match.cpp), which returns a boolean condition inst.
//
// CFG layer (owned here): first-match-wins dispatch as an
// `if`/`else if`/`else` chain — each arm's condition conditionally branches
// to the arm's body block, falling through to the next test otherwise, with
// the `default` body as the final `else` block and all arm bodies converging
// on a single resumption block.
//
// Two scrutinee shapes are supported so far: integer scrutinees with
// constant integer expression `case` patterns, and choice scrutinees with
// leading-dot alternative patterns — payload-free (`case .Err`), whose
// discriminant is compared against the scrutinee's `.discriminant` field,
// and payload-destructuring (`case .Ok(value: i32)`), which additionally
// extract the alternative's payload tuple from the scrutinee's payload
// region in the bind pass and initialize the payload bindings from its
// elements. Against either shape, a bare `name: type` binding pattern is
// also supported: it is irrefutable, so the test pass contributes no real
// condition (the arm's condition is a constant `true`), and a bind pass in
// the arm's body block initializes the binding from the scrutinee through
// `LocalPatternMatch`, so the binding exists only where the arm has matched.
// Everything outside that subset produces a "semantics TODO" diagnostic.
//
// A `case` arm may carry a guard (`case P if (E) => ...`): the guard
// expression is checked in the arm's scope (its pattern's bindings are in
// scope, per the design's guard rule) and converted to `bool` inside its
// own expression region, which is spliced into the arm's body block after
// the bind pass. The arm then branches on the guard: on success into the arm's
// body, on failure to the same else block the pattern test falls through
// to, after destroying any objects the arm created — so a failed guard
// falls through to the next arm (or `default`), preserving
// first-match-wins.
//
// Exhaustiveness (SF-7): a choice scrutinee's alternatives are a closed set,
// so a `match` whose unguarded arms cover every alternative — one arm per
// discriminant, or an irrefutable binding arm covering everything — needs no
// `default` arm; a non-exhaustive choice `match` without `default` is an
// error naming the uncovered alternatives. Guarded arms never count toward
// coverage, because exhaustiveness assumes every guard can fail. Integer
// scrutinees keep requiring `default`: integer expression patterns are never
// exhaustive per docs/design/pattern_matching.md.
//
// TODO: Support other pattern kinds (`var`/`ref` case bindings, tuple
// patterns, non-binding payload subpatterns), guards on `default` arms
// (docs/design/pattern_matching.md allows them; the parser does not yet),
// other scrutinee types (including choices with fewer than two
// alternatives, which have no integer discriminant to dispatch on), and
// integer exhaustiveness via an irrefutable arm or full enumeration.
// Diagnose cases that can never match, per docs/design/pattern_matching.md.

// Returns the scrutinee value, which is on the `MatchHandler` entry after an
// earlier case arm, or otherwise on the `MatchStatementStart` entry.
static auto PeekScrutinee(Context& context) -> SemIR::InstId {
  if (context.node_stack().PeekIs(Parse::NodeKind::MatchHandler)) {
    return context.node_stack().Peek<Parse::NodeKind::MatchHandler>();
  }
  return context.node_stack().Peek<Parse::NodeKind::MatchStatementStart>();
}

auto HandleParseNode(Context& /*context*/,
                     Parse::MatchConditionStartId /*node_id*/) -> bool {
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchConditionId node_id)
    -> bool {
  auto scrutinee_id = context.node_stack().PopExpr();

  // Convert the scrutinee to a value or reference expression so that we can
  // use it multiple times, once per `case`.
  scrutinee_id = ConvertToValueOrRefExpr(context, scrutinee_id);

  // Two scrutinee shapes are supported so far.
  //
  // Integer scrutinees: `Core.IntLiteral`, a builtin integer type, or a class
  // type directly adapting a builtin integer type, as `Int(N)` and `UInt(N)`
  // do. Other class types whose object representation is an integer type,
  // such as `Core.Char` or user-defined adapter classes, are excluded: they
  // have their own operator semantics.
  //
  // Choice scrutinees with an integer discriminant: dispatch compares the
  // alternative's index against the `.discriminant` field. The temporary
  // cleanup handling below stays trivially correct for both shapes as a type
  // property, not a syntactic one: integer values have no `destroy`
  // functions, and an in-slice choice's payloads are restricted to trivially
  // copyable and destructible types when the choice's representation is
  // completed (see handle_choice.cpp), so its destruction is a no-op.
  auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();
  bool is_int_scrutinee = false;
  if (context.types().TryGetIntTypeInfo(scrutinee_type_id)) {
    auto unqualified_type_id =
        context.types().GetUnqualifiedType(scrutinee_type_id);
    if (context.types().Is<SemIR::ClassType>(unqualified_type_id)) {
      is_int_scrutinee =
          context.types()
              .TryGetAsIfValid<SemIR::IntType>(
                  context.types().GetAdaptedType(unqualified_type_id))
              .has_value();
    } else {
      is_int_scrutinee = true;
    }
  }
  if (!is_int_scrutinee &&
      !GetChoiceDiscriminantType(context, scrutinee_type_id)) {
    return context.TODO(node_id, "match on unsupported scrutinee type");
  }

  // Destroy any temporaries created in the scrutinee expression.
  AddAndDiscardTemporaryCleanups(context);

  context.node_stack().Push(node_id, scrutinee_id);
  return true;
}

auto HandleParseNode(Context& /*context*/, Parse::MatchIntroducerId /*node_id*/)
    -> bool {
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchStatementStartId node_id)
    -> bool {
  // Keep the scrutinee value on the node stack for the case arms to find.
  auto scrutinee_id =
      context.node_stack().Pop<Parse::NodeKind::MatchCondition>();
  context.node_stack().Push(node_id, scrutinee_id);
  // Start tracking what this statement's arms cover; `MatchStatement` reads
  // the accumulated coverage for exhaustiveness.
  context.match_statement_stack().push_back({});
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchCaseIntroducerId node_id)
    -> bool {
  // Push the arm's scope. It must cover the pattern's bindings, the guard,
  // and the arm's body (bindings are in scope in the guard, p2188), so it is
  // pushed here rather than at `MatchHandlerStart`, which must not push a
  // second scope for this arm; `MatchHandler` pops it.
  context.scope_stack().PushForSameRegion(ScopeStack::CleanupScopeKind::Owned);

  // Begin an implicit `let` declaration context for the case pattern,
  // mirroring the `for` loop's driving sequence (handle_loop_statement.cpp):
  // binding-pattern checking reads the innermost introducer state before
  // dispatching on the full-pattern kind, and in statement position the
  // introducer stack is otherwise empty.
  context.decl_introducer_state_stack().Push<Lex::TokenKind::Let>();
  context.pattern_block_stack().Push();
  context.full_pattern_stack().PushMatchCaseArm();
  BeginExprRegionForPattern(context);

  // Record the case-arm context: the scrutinee's type for pattern checking,
  // and this introducer node, which the preserved slice-gate diagnostics are
  // pinned to.
  context.match_case_stack().push_back(
      {.scrutinee_type_id =
           context.insts().Get(PeekScrutinee(context)).type_id(),
       .introducer_node_id = node_id});

  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::AlternativePatternStartId node_id)
    -> bool {
  context.node_stack().Push(node_id);
  return true;
}

// Checks a choice alternative pattern (`.Name` or `.Name(<subpatterns>)`) at
// the root of a `match` `case` pattern. The name resolves against the
// case-arm scrutinee's choice type through the choice's name-to-index
// metadata (`SemIR::ChoiceAlternative`), and the resolved alternative is
// recorded in the case-arm context for `MatchCase`'s classification and the
// refutable engine's discriminant test.
//
// A bare `.Name` names a payload-free alternative constant: the designator
// is resolved in the choice's scope and wrapped in an `ExprPattern`, the
// same pattern shape a designator expression pattern produced before this
// form had its own parse node. A parenthesized `.Name(...)` destructures the
// alternative's payload: the subpatterns (bare `name: type` bindings in this
// slice) become a `TuplePattern` that the bind pass matches against the
// alternative's payload tuple, extracted from the scrutinee's payload
// region.
auto HandleParseNode(Context& context, Parse::AlternativePatternId node_id)
    -> bool {
  // Pop the optional parenthesized payload pattern list. A single
  // parenthesized subpattern arrives as a `ParenPattern` (the subpattern
  // itself), more than one (or a trailing comma, or none) as a
  // `TuplePattern`.
  bool has_parens = false;
  bool payload_is_tuple = false;
  SemIR::InstId payload_id = SemIR::InstId::None;
  if (context.node_stack().PeekIs(Parse::NodeKind::ParenPattern)) {
    has_parens = true;
    payload_id = context.node_stack().Pop<Parse::NodeKind::ParenPattern>();
  } else if (context.node_stack().PeekIs(Parse::NodeKind::TuplePattern)) {
    has_parens = true;
    payload_is_tuple = true;
    payload_id = context.node_stack().Pop<Parse::NodeKind::TuplePattern>();
  }
  auto name_id = context.node_stack().PopName();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::AlternativePatternStart>();

  auto& case_context = context.match_case_stack().back();
  auto scrutinee_type_id = case_context.scrutinee_type_id;

  // Only a choice scrutinee resolves leading-dot case patterns in its scope;
  // on any other scrutinee such a pattern keeps the W4 slice-gate TODO,
  // pinned to the introducer node.
  if (!GetChoiceDiscriminantType(context, scrutinee_type_id)) {
    return context.TODO(case_context.introducer_node_id,
                        "match `case` pattern other than an integer "
                        "literal, or a case guard");
  }

  auto push_error = [&] {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  };

  auto alternative =
      LookupChoiceAlternative(context, scrutinee_type_id, name_id);
  if (!alternative || !alternative->has_parameters) {
    // A constant alternative — or an unknown name, which gets the standard
    // member-access diagnostic. Resolve the designator in the scrutinee's
    // choice scope; the name reference lands in the pattern's pending
    // expression region.
    auto scrutinee_type_inst_id = context.types().GetTypeInstId(
        context.types().GetUnqualifiedType(scrutinee_type_id));
    if (alternative && has_parens) {
      CARBON_DIAGNOSTIC(MatchAlternativeUnexpectedParens, Error,
                        "alternative `{0}` is declared without a parameter "
                        "list, so its pattern cannot have parentheses",
                        SemIR::NameId);
      context.emitter().Emit(node_id, MatchAlternativeUnexpectedParens,
                             name_id);
      return push_error();
    }
    auto member_id =
        PerformMemberAccess(context, node_id, scrutinee_type_inst_id, name_id);
    // Record the resolution so that the refutable engine can recognize a
    // pattern whose root is this designator. Re-fetch the case-arm context:
    // if the member access ever checks code that opens a nested match, the
    // stack may have reallocated, invalidating `case_context`.
    auto& resolved_case_context = context.match_case_stack().back();
    resolved_case_context.designator_root_id = member_id;
    if (alternative) {
      resolved_case_context.alternative =
          Context::MatchCaseContext::Alternative{.index = alternative->index};
    }
    if (has_parens) {
      // Unknown alternative name with parentheses: the member access above
      // diagnosed it. Consume the pending region the name reference was
      // emitted into; the pattern is an error and the region is unused.
      ConsumeExprRegionForPattern(context, member_id);
      return push_error();
    }
    // Wrap the resolved designator in an `ExprPattern`, consuming the
    // pending expression region it was emitted into.
    auto region_id = ConsumeExprRegionForPattern(context, member_id);
    auto pattern_type_id =
        GetPatternType(context, context.insts().Get(member_id).type_id());
    auto pattern_id = AddInst<SemIR::ExprPattern>(
        context, node_id,
        {.type_id = pattern_type_id, .expr_region_id = region_id});
    context.node_stack().Push(node_id, pattern_id);
    return true;
  }

  // A payload alternative: parentheses are required, per the
  // parens-iff-parameter-list rule.
  if (!has_parens) {
    CARBON_DIAGNOSTIC(MatchAlternativeMissingParens, Error,
                      "alternative `{0}` is declared with a parameter list, "
                      "so its pattern requires parentheses",
                      SemIR::NameId);
    context.emitter().Emit(node_id, MatchAlternativeMissingParens, name_id);
    return push_error();
  }
  if (payload_id == SemIR::ErrorInst::InstId) {
    return push_error();
  }

  // Collect the payload subpatterns.
  llvm::SmallVector<SemIR::InstId> subpattern_ids;
  if (payload_is_tuple) {
    auto tuple_pattern = context.insts().GetAs<SemIR::TuplePattern>(payload_id);
    llvm::append_range(subpattern_ids,
                       context.inst_blocks().Get(tuple_pattern.elements_id));
  } else {
    subpattern_ids.push_back(payload_id);
  }

  // The pattern must reproduce the alternative's parameter list, one
  // subpattern per declared parameter.
  int param_count = 0;
  if (alternative->payload_field_index >= 0) {
    auto payload_info = GetChoicePayloadInfo(context, scrutinee_type_id,
                                             alternative->payload_field_index);
    CARBON_CHECK(payload_info, "Payload alternative without payload field");
    param_count = context.inst_blocks()
                      .Get(context.types()
                               .GetAs<SemIR::TupleType>(
                                   payload_info->payload_tuple_type_id)
                               .type_elements_id)
                      .size();
  }
  if (static_cast<int>(subpattern_ids.size()) != param_count) {
    CARBON_DIAGNOSTIC(MatchAlternativeArgCountMismatch, Error,
                      "alternative pattern has {0} subpattern{0:s}, but "
                      "alternative `{1}` is declared with {2} parameter{2:s}",
                      Diagnostics::IntAsSelect, SemIR::NameId,
                      Diagnostics::IntAsSelect);
    context.emitter().Emit(node_id, MatchAlternativeArgCountMismatch,
                           static_cast<int>(subpattern_ids.size()), name_id,
                           param_count);
    return push_error();
  }

  // In this slice, each payload subpattern must be a bare `name: type`
  // binding (decision-log W5 SF-5); `var`/`ref`/compile-time bindings were
  // already gated at the binding. Expression subpatterns and nested
  // destructuring stay TODO.
  for (auto subpattern_id : subpattern_ids) {
    if (subpattern_id == SemIR::ErrorInst::InstId) {
      return push_error();
    }
    if (!context.insts().Is<SemIR::ValueBindingPattern>(subpattern_id)) {
      return context.TODO(
          SemIR::LocId(subpattern_id),
          "non-binding subpattern in match `case` alternative pattern");
    }
  }

  // The pattern root is a `TuplePattern` over the payload subpatterns; the
  // bind pass matches it against the alternative's extracted payload tuple.
  // A single parenthesized subpattern is wrapped in one here so the payload
  // always destructures through the tuple machinery.
  SemIR::InstId root_id = payload_id;
  if (!payload_is_tuple) {
    llvm::SmallVector<SemIR::InstId> type_inst_ids;
    type_inst_ids.reserve(subpattern_ids.size());
    for (auto subpattern_id : subpattern_ids) {
      type_inst_ids.push_back(
          context.types().GetTypeInstId(SemIR::ExtractScrutineeType(
              context.sem_ir(), context.insts().Get(subpattern_id).type_id())));
    }
    auto type_id =
        GetPatternType(context, GetTupleType(context, type_inst_ids));
    // The `TuplePattern` is synthesized rather than checked from a
    // `TuplePattern` parse node, so `SemIR::TuplePattern`'s typed node id
    // doesn't fit; attach the subpattern inst's location instead, the way
    // `RebuildPatternInst` (thunk.cpp) gives a synthesized inst an existing
    // inst's location. The location resolves into the alternative pattern's
    // source for diagnostics.
    root_id = AddInst(
        context,
        SemIR::LocIdAndInst::RuntimeVerified(
            context.sem_ir(), SemIR::LocId(payload_id),
            SemIR::TuplePattern{
                .type_id = type_id,
                .elements_id = context.inst_blocks().Add(subpattern_ids)}));
  }

  case_context.alternative = Context::MatchCaseContext::Alternative{
      .index = alternative->index,
      .payload_field_index = alternative->payload_field_index,
      .payload_pattern_id = root_id};
  context.node_stack().Push(node_id, root_id);
  return true;
}

// Finishes the arm's case pattern, begun by `MatchCaseIntroducer`: a
// leftover expression on the node stack becomes an `ExprPattern`, and the
// checked pattern root is popped and recorded in the case-arm context.
// Called from `MatchCaseGuardIntroducer` when the arm has a guard —
// expression regions nest LIFO on a region stack, so the guard's region
// could nest inside the pattern's pending one; closing the pattern's first
// keeps them siblings (a simplicity choice) — and otherwise from `MatchCase`.
//
// A `case` expression such as `2 + 3` is an initializing expression: its
// prelude operator call returns through a return slot. Convert it to a
// value now, while the pattern's expression region is still open, so the
// conversion insts land inside the region and the region's result is a
// value. Splicing an initializing result would make the `splice_block` at
// the use site itself an initializing expression, which SemIR does not
// support: an initializer must carry a storage argument (see
// `FindStorageArgForInitializer`). Type expressions uphold the same
// invariant by converting with `ExprAsType` before their region closes
// (handle_binding_pattern.cpp). Value-category expressions, including
// plain literals, are left exactly as they are.
static auto FinishCasePattern(Context& context) -> void {
  {
    auto [expr_node_id, maybe_expr_id] =
        context.node_stack().PopWithNodeIdIf<Parse::NodeCategory::Expr>();
    if (maybe_expr_id) {
      if (SemIR::IsInitializerCategory(
              SemIR::GetExprCategory(context.sem_ir(), *maybe_expr_id))) {
        *maybe_expr_id = ConvertToValueExpr(context, *maybe_expr_id);
      }
      context.node_stack().Push(expr_node_id, *maybe_expr_id);
    }
  }
  EndExprRegionForPattern(context, context.node_stack());
  context.match_case_stack().back().pattern_id =
      context.node_stack().PopPattern();
}

auto HandleParseNode(Context& context,
                     Parse::MatchCaseGuardIntroducerId node_id) -> bool {
  // The arm has a guard, so the case pattern's nodes are all checked:
  // finish the pattern and open a fresh expression region to capture the
  // guard expression. The guard is checked in the arm's scope — the
  // pattern's bindings are in scope in the guard
  // (docs/design/pattern_matching.md, "Guards") — but its insts must not be
  // emitted here in the test block, where the pattern has not yet matched
  // and the bindings are uninitialized; `MatchCase` splices the captured
  // region into the arm's body block after the bind pass.
  FinishCasePattern(context);
  BeginExprRegionForPattern(context);
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardStartId node_id)
    -> bool {
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardId node_id)
    -> bool {
  // Convert the guard's condition to a bool value while its expression
  // region is still open, so the conversion insts land inside the region
  // and the region's result is a value (the same invariant
  // `FinishCasePattern` maintains for case expressions). A conversion
  // failure is diagnosed at the guard expression.
  auto [expr_node_id, cond_id] = context.node_stack().PopExprWithNodeId();
  cond_id = ConvertToBoolValue(context, expr_node_id, cond_id);
  auto region_id = ConsumeExprRegionForPattern(context, cond_id);
  EndEmptyExprRegionForPattern(context);
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchCaseGuardStart>();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchCaseGuardIntroducer>();

  auto& case_context = context.match_case_stack().back();
  case_context.guard_region_id = region_id;
  case_context.guard_node_id = node_id;
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchCaseId node_id) -> bool {
  // Finish the pattern context begun by `MatchCaseIntroducer`, unless the
  // arm's guard already did (`MatchCaseGuardIntroducer`).
  if (!context.match_case_stack().back().pattern_id.has_value()) {
    FinishCasePattern(context);
  }
  auto pattern_id = context.match_case_stack().back().pattern_id;
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchCaseIntroducer>();
  context.decl_introducer_state_stack().Pop<Lex::TokenKind::Let>();

  // Attach the arm's finished pattern block to a `NameBindingDecl` in the
  // arm's test block, the same SemIR home `let` and `var` give their
  // patterns.
  auto pattern_block_id = context.pattern_block_stack().Pop();
  AddInst<SemIR::NameBindingDecl>(context, node_id,
                                  {.pattern_block_id = pattern_block_id});

  auto introducer_node_id =
      context.match_case_stack().back().introducer_node_id;
  // Copy: the case-arm context is popped below, before the bind pass and
  // guard emission read the resolved alternative and the guard's region.
  auto alternative = context.match_case_stack().back().alternative;
  auto guard_region_id = context.match_case_stack().back().guard_region_id;
  auto guard_node_id = context.match_case_stack().back().guard_node_id;
  auto scrutinee_id = PeekScrutinee(context);

  // Classify by the checked pattern inst: a parenthesized alternative
  // pattern's root (recorded in the case-arm context) tests the scrutinee's
  // discriminant, and its payload subpatterns bind below; other expression
  // patterns (including error recovery) are matched by the refutable engine,
  // which returns the arm's condition; a binding-pattern root is
  // irrefutable, so its test pass contributes no condition and the arm's
  // condition is a constant `true` (the refutable engine prunes at
  // binding-pattern roots, whose `bind_name_map` entries belong to the bind
  // pass below); every other pattern root stays behind the W4 slice-gate
  // TODO. The TODO is pinned to the introducer node so the preserved
  // diagnostics keep their location.
  SemIR::InstId cond_value_id = SemIR::InstId::None;
  bool is_binding_arm =
      context.insts().Is<SemIR::ValueBindingPattern>(pattern_id);
  bool is_alternative_payload_arm =
      alternative && alternative->payload_pattern_id.has_value() &&
      alternative->payload_pattern_id == pattern_id;
  if (is_alternative_payload_arm) {
    cond_value_id =
        MatchCaseAlternativePatternMatch(context, scrutinee_id, node_id);
  } else if (pattern_id == SemIR::ErrorInst::InstId ||
             context.insts().Is<SemIR::ExprPattern>(pattern_id)) {
    cond_value_id =
        MatchCasePatternMatch(context, pattern_id, scrutinee_id, node_id);
    if (!cond_value_id.has_value()) {
      // The engine diagnosed an unsupported case-pattern shape with a TODO,
      // which aborts checking.
      return false;
    }
  } else if (is_binding_arm) {
    cond_value_id = MakeBoolLiteral(context, node_id, SemIR::BoolValue::True);
  } else {
    return context.TODO(
        introducer_node_id,
        "match `case` pattern other than an integer literal, or a case guard");
  }

  // Record what this arm contributes to the enclosing statement's
  // exhaustiveness (SF-7). A guarded arm contributes nothing, whatever its
  // pattern: exhaustiveness assumes every guard can evaluate to false
  // (docs/design/pattern_matching.md, "Refutability, overlap, usefulness,
  // and exhaustiveness"). An unguarded irrefutable arm covers every
  // scrutinee value; an unguarded alternative-pattern arm covers its
  // alternative. An arm whose pattern contained an error contributes
  // unknowable coverage and suppresses the exhaustiveness diagnostic.
  {
    auto& match_context = context.match_statement_stack().back();
    if (pattern_id == SemIR::ErrorInst::InstId ||
        cond_value_id == SemIR::ErrorInst::InstId) {
      match_context.has_error_arm = true;
    } else if (guard_region_id.has_value()) {
      // Guarded arms never count toward coverage.
    } else if (is_binding_arm) {
      match_context.has_irrefutable_arm = true;
    } else if (alternative) {
      match_context.covered_alternatives.push_back(alternative->index);
    }
  }

  context.full_pattern_stack().PopFullPattern();
  context.match_case_stack().pop_back();

  // Create the arm's body block and the block for the next test (or the
  // `default` body), and branch to the right one.
  auto then_block_id =
      AddDominatedBlockAndBranchIf(context, node_id, cond_value_id);
  auto else_block_id = AddDominatedBlockAndBranch(context, node_id);

  // Start emitting the arm's body block.
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(then_block_id);
  context.region_stack().AddToRegion(then_block_id, node_id);

  // Bind pass: initialize the pattern's bindings from the scrutinee in the
  // arm's body block, where they are reachable only when the arm has
  // matched. This runs the irrefutable `LocalState` machinery, the same way
  // `let` initializes its bindings.
  //
  // For either arm shape, objects created initializing the bindings live
  // until the end of the arm's scope, the same way `let` and `for` bindings
  // defer theirs: the conversion to a binding's declared type can
  // materialize a temporary, which must not be destroyed by the next
  // statement's temporary-cleanup discharge while the binding is live.
  // `MatchHandler`'s scope cleanups discharge it at arm exit instead.
  if (is_binding_arm) {
    LocalPatternMatch(context, pattern_id, scrutinee_id);
    context.scope_stack().DeferCleanups();
  } else if (is_alternative_payload_arm &&
             alternative->payload_field_index >= 0) {
    // Extract this alternative's payload tuple from the scrutinee's payload
    // region — field 1 of the choice's object representation, with every
    // alternative's payload tuple overlapping at offset zero (the F-007k
    // storage contract) — and initialize the payload bindings from its
    // elements through the tuple-pattern machinery.
    auto payload_info = GetChoicePayloadInfo(
        context, context.insts().Get(scrutinee_id).type_id(),
        alternative->payload_field_index);
    CARBON_CHECK(payload_info, "Payload arm without payload field");
    auto payload_ref_id = AddInst<SemIR::ClassElementAccess>(
        context, node_id,
        {.type_id = payload_info->payload_region_type_id,
         .base_id = scrutinee_id,
         .index = SemIR::ElementIndex(1)});
    auto field_ref_id = AddInst<SemIR::ClassElementAccess>(
        context, node_id,
        {.type_id = payload_info->payload_tuple_type_id,
         .base_id = payload_ref_id,
         .index = SemIR::ElementIndex(alternative->payload_field_index)});
    LocalPatternMatch(context, pattern_id, field_ref_id);
    context.scope_stack().DeferCleanups();
  }

  // Guard: splice the captured condition region here, after the bind pass,
  // so the guard evaluates with the arm's bindings initialized, and branch
  // on it — into the arm's body on success, and on failure to the same else
  // block the pattern test falls through to, so a failed guard tries the
  // next arm (or `default`). Objects created by the bind pass and the guard
  // itself are live on both edges: the success edge destroys them with the
  // arm scope's cleanups at arm exit (`MatchHandler`), and the failure edge
  // — which leaves the arm's scope — must destroy them itself, before
  // branching. `DeferCleanups` keeps the body's statement-level
  // temporary-cleanup discharge from destroying them early, the same way
  // the bind pass defers its conversion temporaries.
  if (guard_region_id.has_value()) {
    auto guard_cond_id = SpliceMatchCaseGuard(context, guard_region_id);
    context.scope_stack().DeferCleanups();
    auto body_block_id =
        AddDominatedBlockAndBranchIf(context, node_id, guard_cond_id);
    AddBranchWithCleanups(
        context, SemIR::LocId(guard_node_id), else_block_id,
        context.scope_stack().enclosing_cleanup_scope_depth());
    context.inst_block_stack().Pop();
    context.inst_block_stack().Push(body_block_id);
    context.region_stack().AddToRegion(body_block_id, node_id);
  }

  context.node_stack().Push(node_id, else_block_id);
  return true;
}

auto HandleParseNode(Context& /*context*/,
                     Parse::MatchDefaultIntroducerId /*node_id*/) -> bool {
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchDefaultId node_id) -> bool {
  // The current block is the last case arm's else block, or the enclosing
  // block if there are no case arms; either way it is where the `default`
  // arm's body should be emitted, so there is nothing to do other than note
  // the presence of the `default` arm for `MatchStatement`. Parse guarantees
  // the `default` arm is last.
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchHandlerStartId node_id)
    -> bool {
  // A `case` arm's scope was pushed by `MatchCaseIntroducer`, so that pattern
  // bindings cover the guard and the body; do not push a second one. A
  // `default` arm has no pattern context, so its scope starts here. Either
  // way, `MatchHandler` pops the one arm scope.
  if (context.node_stack().PeekIs(Parse::NodeKind::MatchDefault)) {
    context.scope_stack().PushForSameRegion(
        ScopeStack::CleanupScopeKind::Owned);
  }
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchHandlerId node_id) -> bool {
  AddAndDiscardScopeCleanups(context);
  context.scope_stack().Pop(/*check_unused=*/true);
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchHandlerStart>();

  if (context.node_stack().PeekIs(Parse::NodeKind::MatchDefault)) {
    // This is the `default` arm's body: leave its block on the instruction
    // block stack for `MatchStatement` to converge, and leave the
    // `MatchDefault` entry on the node stack.
    return true;
  }

  // This is a case arm's body: leave its finished block on the instruction
  // block stack for `MatchStatement` to converge, and start emitting the else
  // block, which holds the next arm's test or the `default` body.
  auto else_block_id = context.node_stack().Pop<Parse::NodeKind::MatchCase>();
  context.inst_block_stack().Push(else_block_id);
  context.region_stack().AddToRegion(else_block_id, node_id);

  // Keep the scrutinee exposed for the next case arm.
  context.node_stack().Push(node_id, PeekScrutinee(context));
  return true;
}

// Diagnoses a choice-scrutinee `match` statement with no `default` arm whose
// arms do not cover every alternative, naming the uncovered alternatives. No
// diagnostic when the arms are exhaustive: an unguarded irrefutable arm
// covers everything, and otherwise every alternative's discriminant must be
// covered by an unguarded alternative-pattern arm (see the coverage
// recording in `MatchCase`). An arm whose pattern contained an error also
// suppresses the diagnostic — coverage is unknowable, and the arm carries
// its own diagnostic already.
static auto DiagnoseNonexhaustiveMatch(
    Context& context, Parse::NodeId node_id, SemIR::TypeId scrutinee_type_id,
    const Context::MatchStatementContext& match_context) -> void {
  if (match_context.has_irrefutable_arm || match_context.has_error_arm) {
    return;
  }

  auto unqualified_type_id =
      context.types().GetUnqualifiedType(scrutinee_type_id);
  auto class_type =
      context.types().GetAs<SemIR::ClassType>(unqualified_type_id);
  const auto& class_info = context.classes().Get(class_type.class_id);
  // A valid choice with two or more alternatives always has a non-empty
  // name-to-index table, so an empty table here triggers only under error
  // recovery: a choice whose alternatives were ALL rejected with a
  // diagnostic gets no table entries (`handle_choice.cpp` skips the push for
  // each rejected alternative), yet the declared alternative count still
  // sizes a real integer discriminant, so the class completes and the
  // scrutinee passes its gate. Coverage is then unknowable — bail without
  // diagnosing, mirroring the `has_error_arm` suppression; the declaration
  // already carries its own diagnostics. A PARTIALLY-errored choice keeps
  // entries for its surviving alternatives, so coverage is computed over
  // those only — deliberate error-recovery behavior, consistent with how
  // references to rejected alternatives resolve.
  if (class_info.choice_alternatives.empty()) {
    return;
  }

  llvm::SmallVector<SemIR::NameId> missing;
  for (const auto& alternative : class_info.choice_alternatives) {
    if (!llvm::is_contained(match_context.covered_alternatives,
                            alternative.index)) {
      missing.push_back(alternative.name_id);
    }
  }
  if (missing.empty()) {
    return;
  }

  RawStringOstream missing_stream;
  llvm::ListSeparator sep;
  for (auto name_id : missing) {
    missing_stream << sep << "`." << context.names().GetFormatted(name_id)
                   << "`";
  }
  CARBON_DIAGNOSTIC(MatchNonexhaustive, Error,
                    "`match` on choice {0} has no `default` arm and does not "
                    "cover alternative{1:s} {2}",
                    SemIR::TypeId, Diagnostics::IntAsSelect, std::string);
  context.emitter().Emit(node_id, MatchNonexhaustive, unqualified_type_id,
                         static_cast<int>(missing.size()),
                         missing_stream.TakeStr());
}

auto HandleParseNode(Context& context, Parse::MatchStatementId node_id)
    -> bool {
  bool has_default =
      context.node_stack()
          .PopAndDiscardSoloNodeIdIf<Parse::NodeKind::MatchDefault>();
  int num_case_arms = 0;
  while (context.node_stack().PeekIs(Parse::NodeKind::MatchHandler)) {
    context.node_stack().Pop<Parse::NodeKind::MatchHandler>();
    ++num_case_arms;
  }
  auto scrutinee_id =
      context.node_stack().Pop<Parse::NodeKind::MatchStatementStart>();
  auto match_context = context.match_statement_stack().pop_back_val();

  if (!has_default) {
    // A `match` whose patterns are not exhaustive and that has no `default`
    // is an error per docs/design/pattern_matching.md.
    auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();
    if (!GetChoiceDiscriminantType(context, scrutinee_type_id)) {
      // An integer scrutinee. Integer expression patterns are never
      // exhaustive — each is treated as matching a single value from an
      // infinite set (docs/design/pattern_matching.md) — so W4's rule stays:
      // an integer `match` requires a `default` arm (SF-7). Exhaustiveness
      // via an irrefutable arm or full enumeration of a small integer type
      // is future work.
      return context.TODO(node_id, "match statement without `default` arm");
    }
    // A choice scrutinee: the alternatives are a closed set, so full
    // coverage discharges the `default` requirement (SF-7); otherwise
    // diagnose, naming the uncovered alternatives. Either way the statement
    // converges below: the last arm's else edge — dynamically dead when the
    // arms are exhaustive — branches to the resumption block, the same shape
    // an empty `default` arm produces.
    DiagnoseNonexhaustiveMatch(context, node_id, scrutinee_type_id,
                               match_context);
  }

  // The instruction block stack holds one body block per case arm, plus one
  // more block on top: the `default` arm's body block, or — without a
  // `default` — the last arm's empty else block, whose edge from the last
  // arm's test branches straight to the resumption block. Branch from all of
  // them to a new resumption block. With no case arms, the `default` body
  // was emitted directly into the enclosing block, and there is nothing to
  // converge.
  int num_blocks = num_case_arms + 1;
  if (num_blocks >= 2) {
    AddConvergenceBlockAndPush(context, node_id, num_blocks);
  }
  return true;
}

}  // namespace Carbon::Check
