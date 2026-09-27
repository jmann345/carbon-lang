// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <optional>
#include <utility>

#include "common/raw_string_ostream.h"
#include "llvm/ADT/ArrayRef.h"
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
#include "toolchain/check/refutable_binding.h"
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
// (pattern_match.cpp), which returns a boolean condition inst. The context
// setup, the scrutinee gate, the test pass and the bind pass are the shared
// refutable-binding driver (refutable_binding.h), which the pattern
// conditions `if (let P = e)` / `while (let P = e)` and the `let`-`else`
// declaration (W-012) drive too: everything the match engine admits, they
// admit, and everything it gates, they gate. Only the usefulness and
// exhaustiveness work below is `match`-specific.
//
// CFG layer (owned here): first-match-wins dispatch as an
// `if`/`else if`/`else` chain — each arm's condition conditionally branches
// to the arm's body block, falling through to the next test otherwise, with
// the `default` body as the final `else` block and all arm bodies converging
// on a single resumption block.
//
// Five scrutinee shapes are supported so far: integer scrutinees with
// constant integer expression `case` patterns; bool scrutinees with
// constant `true`/`false` expression `case` patterns — the design treats
// `bool` like a choice type whose alternatives are `false` and `true`
// (docs/design/pattern_matching.md), so the two values are a closed domain
// for exhaustiveness and usefulness while dispatch stays on the expression
// pattern's `==` lane; choice scrutinees with
// leading-dot alternative patterns — payload-free (`case .Err`), whose
// discriminant is compared against the scrutinee's `.discriminant` field,
// and payload-destructuring (`case .Ok(value: i32)`, `case .Ok(42)`), whose
// payload subpatterns mix bindings, constant integer expressions, and
// nested tuples of those: expression subpatterns contribute payload-value
// conditions in a block dominated by the discriminant test, and binding
// subpatterns initialize in the bind pass from the alternative's payload
// tuple, extracted from the scrutinee's payload region; tuple
// scrutinees (tuples of the above, recursively) with tuple `case` patterns
// over the same element kinds, tested elementwise against the scrutinee's
// own tuple type and folded into one condition; and struct scrutinees
// (structs of the above, recursively, and mixed with tuples) with struct
// `case` patterns — designated fields (`case {.a = 1, .b = b: i32}`),
// shorthand fields (`b: i32` means `.b = b: i32`), reordered and
// field-subset patterns with a trailing `_` discard — whose field
// subpatterns resolve name-keyed against the scrutinee's own struct type
// and test in pattern order against each field's same-named scrutinee
// element (W-077). Against any shape, a bare
// `name: type` binding pattern is also supported: it is irrefutable, so the
// test pass contributes no real condition (the arm's condition is a
// constant `true`), and a bind pass in the arm's body block initializes the
// binding from the scrutinee through `LocalPatternMatch`, so the binding
// exists only where the arm has matched. `var` and `ref` case bindings
// check the same way — `case ref a: i32` binds the scrutinee itself, which
// must be a durable reference, and `case var a: i32` (including the
// composed `case var (a: i32, b: i32)` and element form
// `case (var n: i32, 1)`) initializes per-arm storage the bind pass emits
// on demand, so `var` bindings are not aliased across arms
// (docs/design/pattern_matching.md, "Pattern match control flow").
// Everything outside that subset produces a "semantics TODO" diagnostic.
//
// A `case` arm may carry a guard (`case P if (E) => ...`): the guard
// expression is checked in the arm's scope (its pattern's bindings are in
// scope, per the design's guard rule). The arm's test and bind passes run
// BEFORE the guard expression, at `MatchCaseGuardIntroducer`, and the
// guard is then checked directly into the arm's body block and converted
// to `bool` there — no captured expression region — so every binding the
// guard names is already filled. (A binding's `WrapperBinding` is created
// empty at pattern-check time and only the bind pass fills it, and SemIR's
// expression-category query ASSUMES a value category for an unfilled
// binding — expr_info.cpp's own TODO — which is wrong for `ref`-backed
// bindings: a guard checked before the bind pass built comparisons on the
// scrutinee reference without a value load.) The body block executes only
// when the pattern matched, so the guard still runs iff the arm matched.
// `MatchCaseGuard` then branches on the guard: on success into the arm's
// body, on failure to the same else block the pattern test falls through
// to, after destroying any objects the arm created — so a failed guard
// falls through to the next arm (or `default`), preserving
// first-match-wins.
//
// A `default` arm may carry a guard too (`default if (E) => ...`): `default`
// is equivalent to `case _: auto`, and "this facility is also available for
// `default` clauses" (docs/design/pattern_matching.md, "Guards"). A guarded
// `default` (`MatchGuardedDefault`) is checked as a guarded irrefutable arm
// with no pattern and no bindings: a constant-true test, then the spliced
// guard branching into the arm's body or on to the else block, so a failed
// guard falls through to a following arm or `default` — unlike an unguarded
// `default`, arms after it are reachable, and parse keeps the loop open.
// Because its guard can fail, a guarded `default` never discharges the
// `default` requirement and records nothing toward exhaustiveness.
//
// Exhaustiveness (SF-7): a choice scrutinee's alternatives are a closed set,
// so a `match` whose unguarded arms cover every alternative — one arm per
// discriminant, or an irrefutable binding arm covering everything — needs no
// `default` arm; a non-exhaustive choice `match` without `default` is an
// error naming the uncovered alternatives. Guarded arms never count toward
// coverage, because exhaustiveness assumes every guard can fail. A bool
// scrutinee's domain is the closed pair `false`/`true` — the design treats
// `bool` like a choice type (docs/design/pattern_matching.md) — so covering
// both values with unguarded constant arms needs no `default`, and a
// missing value diagnoses `MatchNonexhaustiveBool`. An integer, tuple, or
// struct scrutinee's value domain is open — integer expression patterns
// are never exhaustive per docs/design/pattern_matching.md, and the
// aggregate root records no per-value coverage (root-only, the W-076
// record) — so an unguarded irrefutable arm is the one way such a `match`
// is exhaustive without a `default` arm (W-078b); otherwise the missing
// coverage diagnoses `MatchNonexhaustiveNoIrrefutableArm`, naming no
// missing values because an open domain cannot enumerate theirs.
//
// Usefulness (W-066): a `case` arm whose pattern can never match — every
// value it could match is matched by prior arms — is an error at the arm,
// with a note at the covering prior arm, or, when a union of prior arms
// fully covers a wildcard-rooted arm on a scrutinee with a finite root
// domain — a choice's alternatives, or bool's `false`/`true` pair — one
// statement-level note naming the scrutinee type. Comparison is
// by evaluated constant value, never source form. A prior arm's guard is
// assumed to evaluate to false, so guarded prior arms block nothing, while
// a guarded arm whose own pattern is fully covered is still dead
// (docs/design/pattern_matching.md, "Refutability, overlap, usefulness, and
// exhaustiveness"). A `default` arm — guarded or not — is likewise an
// error when a prior unguarded irrefutable arm covers every value (any
// scrutinee lane, W-078b) or when the unguarded prior arms cover a choice
// or bool scrutinee's whole closed domain (W-078a;
// `DiagnoseDeadDefault`).
//
// Choices with fewer than two alternatives have no integer discriminant —
// their discriminant field is the empty tuple (handle_choice.cpp) — so
// there is nothing to test at dispatch: a single-alternative choice's
// alternative arm is always taken (a constant-true condition, the same
// shape as an irrefutable binding arm, with the payload extraction still
// real), and an empty choice — whose values cannot even be constructed —
// is vacuously exhaustive, so no arm is needed for coverage (parse still
// requires at least one arm; see `MatchStatementStart` in
// parse/handle_match.cpp).
//
// TODO: Support other pattern kinds and other scrutinee types.
//
// Deliberately NOT a TODO: enumeration-based exhaustiveness for integer
// (or integer-tuple) scrutinees is design-rejected, not future work —
// each expression pattern is treated as matching a single value from an
// infinite set, so a set of expression patterns is never exhaustive,
// demonstrated on a fully enumerated `u8` annotated "Not considered
// exhaustive." (docs/design/pattern_matching.md; rejected alternative,
// proposal p2188).

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

  // The scrutinee gate shared with the pattern-condition and `let`-`else`
  // forms (refutable_binding.h): value-or-ref conversion, the completeness
  // requirement, the shape gate, and temporary cleanup. `None` after a
  // diagnostic that aborts checking the `match`.
  scrutinee_id = CheckRefutableScrutinee(context, node_id, scrutinee_id,
                                         "match on unsupported scrutinee type");
  if (!scrutinee_id.has_value()) {
    return false;
  }

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

  // Begin the refutable pattern context (the implicit `let` declaration
  // context, the pattern block, the `MatchCaseArm` full-pattern frame, the
  // expression region, and the case-arm context pinned to this introducer
  // node). The scrutinee is already checked here — `match` is the one form
  // whose scrutinee precedes its patterns — so its type is recorded for
  // pattern checking right away, and a root alternative pattern resolves at
  // pattern time rather than at the test.
  BeginRefutableBinding(context, node_id);
  context.match_case_stack().back().scrutinee_type_id =
      context.insts().Get(PeekScrutinee(context)).type_id();

  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::AlternativePatternStartId node_id)
    -> bool {
  context.node_stack().Push(node_id);
  return true;
}

// Checks a choice alternative pattern (`.Name` or `.Name(<subpatterns>)`) at
// the root of a refutable pattern: a `match` `case` pattern, a pattern
// condition, or a `let`-`else` declaration. The name resolves against the
// scrutinee's choice type through the choice's name-to-index metadata
// (`SemIR::ChoiceAlternative`), and the resolved alternative is recorded in
// the case context for the driver's classification and the refutable
// engine's discriminant test.
//
// In a `match` the scrutinee is known at pattern time, so the name resolves
// here (`ResolvePendingAlternative`): a bare `.Name` names a payload-free
// alternative constant — the designator is resolved in the choice's scope
// and wrapped in an `ExprPattern`, the same pattern shape a designator
// expression pattern produced before this form had its own parse node —
// and a parenthesized `.Name(...)` destructures the alternative's payload:
// the subpatterns — bindings, constant-integer expressions, and nested
// tuples of those — become a `TuplePattern` matched against the
// alternative's payload tuple, extracted from the scrutinee's payload
// region: expression subpatterns compare in the test pass under the arm's
// discriminant test, and bindings initialize in the bind pass.
//
// In a pattern condition or `let`-`else` the initializer follows the
// pattern, so the scrutinee's type is `None` here (fork/w012/plan.md §1.6):
// only the scrutinee-independent half runs — the payload root is
// synthesized (an EMPTY `TuplePattern` for the bare spelling, so the root is
// always a tuple pattern and the alternative-payload lane tests the
// discriminant alone), its irrefutability is folded, and the name, parens
// and root are recorded as `pending_alternative`, which the test pass
// resolves once the scrutinee is checked. The designator lane is not
// available there (it needs a pattern-time member access), and is not
// needed: the empty root is the bare spelling's payload root.
auto HandleParseNode(Context& context, Parse::AlternativePatternId node_id)
    -> bool {
  // A root `.Name` parses in a plain `let`/`var` too (the parser cannot know
  // whether an `else` follows). Outside a refutable pattern context it stays
  // behind a TODO, the disposition a refutable expression pattern root such
  // as `let 5 = x;` has today (fork/w012/plan.md §1.13).
  if (context.full_pattern_stack().CurrentKind() !=
      FullPatternStack::Kind::MatchCaseArm) {
    return context.TODO(node_id,
                        "alternative pattern outside a refutable pattern "
                        "context");
  }

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

  auto scrutinee_type_id = context.match_case_stack().back().scrutinee_type_id;
  bool is_deferred = !scrutinee_type_id.has_value();

  auto push_error = [&] {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  };

  // Resolve the name now when the scrutinee is known (`match`).
  ResolvedAlternative resolved;
  if (!is_deferred) {
    // The subpattern count only matters for the arity rule of a payload
    // alternative, which is checked below once the subpatterns are in hand;
    // resolve the name, the choice gate and the parens rules first, as
    // before.
    int subpattern_count = 0;
    if (payload_id == SemIR::ErrorInst::InstId) {
      // An errored payload has no sound subpattern count: the arity rule is
      // skipped for it (the errored payload bails below, as before).
      subpattern_count = -1;
    } else if (has_parens) {
      if (payload_is_tuple) {
        subpattern_count = context.inst_blocks()
                               .Get(context.insts()
                                        .GetAs<SemIR::TuplePattern>(payload_id)
                                        .elements_id)
                               .size();
      } else {
        subpattern_count = 1;
      }
    }
    resolved = ResolvePendingAlternative(context, node_id, scrutinee_type_id,
                                         name_id, has_parens, subpattern_count);
    if (resolved.aborted) {
      return false;
    }
    if (!resolved.lookup || !resolved.lookup->has_parameters) {
      // A constant alternative — or an unknown name, which gets the standard
      // member-access diagnostic. Resolve the designator in the scrutinee's
      // choice scope; the name reference lands in the pattern's pending
      // expression region.
      auto scrutinee_type_inst_id = context.types().GetTypeInstId(
          context.types().GetUnqualifiedType(scrutinee_type_id));
      if (resolved.lookup && !resolved.alternative) {
        // `MatchAlternativeUnexpectedParens` was diagnosed.
        return push_error();
      }
      auto member_id = PerformMemberAccess(context, node_id,
                                           scrutinee_type_inst_id, name_id);
      // Record the resolution so that the refutable engine can recognize a
      // pattern whose root is this designator. Re-fetch the case-arm
      // context: if the member access ever checks code that opens a nested
      // match, the stack may have reallocated.
      auto& resolved_case_context = context.match_case_stack().back();
      resolved_case_context.designator_root_id = member_id;
      if (resolved.alternative) {
        resolved_case_context.alternative = *resolved.alternative;
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
    if (!resolved.alternative) {
      // `MatchAlternativeMissingParens` or `MatchAlternativeArgCountMismatch`
      // was diagnosed.
      return push_error();
    }
  }
  if (payload_id == SemIR::ErrorInst::InstId) {
    return push_error();
  }

  // Collect the payload subpatterns (none for the bare spelling).
  llvm::SmallVector<SemIR::InstId> subpattern_ids;
  if (payload_is_tuple) {
    auto tuple_pattern = context.insts().GetAs<SemIR::TuplePattern>(payload_id);
    llvm::append_range(subpattern_ids,
                       context.inst_blocks().Get(tuple_pattern.elements_id));
  } else if (has_parens) {
    subpattern_ids.push_back(payload_id);
  }

  // Payload subpatterns are bindings — value, `ref`, and `var`-mode alike —
  // constant-integer expressions, and nested tuples of those (compile-time
  // bindings were already gated at the binding; out-of-slice expression
  // shapes diagnose in the refutable engine). Classify the tree's
  // refutability while the
  // subpatterns are in hand: an unguarded arm covers its alternative for
  // exhaustiveness only when the tree is wholly irrefutable — a `.Some(42)`
  // arm compares values, can fail, and records nothing
  // (docs/design/pattern_matching.md, "Refutability, overlap, usefulness,
  // and exhaustiveness").
  bool payload_is_irrefutable = true;
  for (auto subpattern_id : subpattern_ids) {
    if (subpattern_id == SemIR::ErrorInst::InstId) {
      return push_error();
    }
    payload_is_irrefutable &=
        IsIrrefutableMatchCasePattern(context, subpattern_id);
  }

  // The pattern root is a `TuplePattern` over the payload subpatterns; the
  // bind pass matches it against the alternative's extracted payload tuple.
  // A single parenthesized subpattern is wrapped in one here so the payload
  // always destructures through the tuple machinery, and so is the deferred
  // bare spelling's empty payload.
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
    SemIR::TuplePattern tuple_pattern = {
        .type_id = type_id,
        .elements_id = context.inst_blocks().Add(subpattern_ids)};
    if (has_parens) {
      // The `TuplePattern` is synthesized rather than checked from a
      // `TuplePattern` parse node, so `SemIR::TuplePattern`'s typed node id
      // doesn't fit; attach the subpattern inst's location instead, the way
      // `RebuildPatternInst` (thunk.cpp) gives a synthesized inst an
      // existing inst's location. The location resolves into the
      // alternative pattern's source for diagnostics.
      root_id = AddInst(context, SemIR::LocIdAndInst::RuntimeVerified(
                                     context.sem_ir(), SemIR::LocId(payload_id),
                                     tuple_pattern));
    } else {
      // The deferred bare spelling's empty root has no payload inst to
      // borrow a location from and no subpattern a diagnostic could point
      // at; it carries no location.
      root_id = AddInst(context, SemIR::LocIdAndInst::NoLoc(tuple_pattern));
    }
  }

  if (is_deferred) {
    context.match_case_stack().back().pending_alternative =
        Context::MatchCaseContext::PendingAlternative{
            .name_id = name_id,
            .node_id = node_id,
            .has_parens = has_parens,
            .root_id = root_id,
            .payload_is_irrefutable = payload_is_irrefutable};
  } else {
    auto alternative = *resolved.alternative;
    alternative.payload_pattern_id = root_id;
    alternative.payload_is_irrefutable = payload_is_irrefutable;
    context.match_case_stack().back().alternative = alternative;
  }
  context.node_stack().Push(node_id, root_id);
  return true;
}

// Finishes the arm's case pattern, begun by `MatchCaseIntroducer`: a
// leftover expression on the node stack becomes an `ExprPattern`, and the
// checked pattern root is popped and recorded in the case-arm context.
// Called from `MatchCaseGuardIntroducer` when the arm has a guard — the
// arm's test and bind passes run there, before the guard expression, and
// they need the finished pattern — and otherwise from `MatchCase`.
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
  EndRefutablePatternRegion(context);
  context.match_case_stack().back().pattern_id =
      context.node_stack().PopPattern();
}

// Returns the index just past the usefulness-key subtree rooted at `index`
// in `key`'s preorder node list: a node with `arity` child slots is
// followed by that many subtrees. Iterative (misc-no-recursion); keys are
// well-formed by construction (`BuildMatchCaseUsefulnessKey`), so the walk
// always terminates within the key.
static auto SkipUsefulnessKeySubtree(
    llvm::ArrayRef<Context::MatchStatementContext::UsefulnessKeyNode> key,
    int index) -> int {
  for (int remaining = 1; remaining > 0; ++index) {
    remaining += key[index].arity - 1;
  }
  return index;
}

// Returns whether the pattern `prior` describes subsumes the pattern `arm`
// describes — whether every value `arm` can match, `prior` matches too. At
// each slot: the prior is `Wildcard`; or both are `IntConst` with equal
// canonical value; or both are `BoolConst` with equal value; or both are
// `Alternative` with equal discriminant index,
// the payload slots then comparing elementwise (a payload-free alternative
// has zero slots and subsumes itself); or both are `Tuple`, comparing
// elementwise; or both are `Struct`, comparing fieldwise — struct keys are
// normalized to the scrutinee's full field set in the scrutinee's
// canonical field order (`BuildMatchCaseUsefulnessKey`), so the slot-wise
// walk is sound over field-subset and reordered patterns. Nothing else
// subsumes — in particular a `Wildcard` is never itself subsumed by a
// constant, so a prior `case (1, 2)` leaves a later `case (1, b: i32)`
// useful, and a prior `{.a = 1, .b = 2}` leaves a later `{.a = 1, _}`
// useful. Two keys for the same scrutinee are structurally compatible, so
// a kind or arity mismatch is treated as not-subsumed (defensive, should
// be unreachable). Lockstep iterative walk over the preorder node lists
// (misc-no-recursion).
static auto UsefulnessKeySubsumes(
    llvm::ArrayRef<Context::MatchStatementContext::UsefulnessKeyNode> prior,
    llvm::ArrayRef<Context::MatchStatementContext::UsefulnessKeyNode> arm)
    -> bool {
  using Kind = Context::MatchStatementContext::UsefulnessKeyNode::Kind;
  int prior_index = 0;
  int arm_index = 0;
  while (prior_index < static_cast<int>(prior.size()) &&
         arm_index < static_cast<int>(arm.size())) {
    const auto& prior_node = prior[prior_index];
    const auto& arm_node = arm[arm_index];
    switch (prior_node.kind) {
      case Kind::Wildcard:
        // The prior covers the arm's whole subtree at this slot.
        ++prior_index;
        arm_index = SkipUsefulnessKeySubtree(arm, arm_index);
        continue;
      case Kind::IntConst:
        if (arm_node.kind != Kind::IntConst ||
            prior_node.int_id != arm_node.int_id) {
          return false;
        }
        break;
      case Kind::BoolConst:
        if (arm_node.kind != Kind::BoolConst ||
            prior_node.index != arm_node.index) {
          return false;
        }
        break;
      case Kind::Alternative:
        if (arm_node.kind != Kind::Alternative ||
            prior_node.index != arm_node.index ||
            prior_node.arity != arm_node.arity) {
          return false;
        }
        break;
      case Kind::Tuple:
        if (arm_node.kind != Kind::Tuple ||
            prior_node.arity != arm_node.arity) {
          return false;
        }
        break;
      case Kind::Struct:
        if (arm_node.kind != Kind::Struct ||
            prior_node.arity != arm_node.arity) {
          return false;
        }
        break;
    }
    ++prior_index;
    ++arm_index;
  }
  // Structurally compatible keys end together; leftover nodes on either
  // side mean the shapes diverged mid-walk (defensive, as above).
  return prior_index == static_cast<int>(prior.size()) &&
         arm_index == static_cast<int>(arm.size());
}

// Returns whether the unguarded arms recorded so far cover the scrutinee's
// whole closed value domain. Only the finite root domains answer true:
// `unqualified_scrutinee_type_id` must be plain `bool` — whose domain is
// the `false`/`true` pair, recorded as 0/1 in `covered_alternatives`
// (docs/design/pattern_matching.md: `bool` is treated like a choice type
// whose alternatives are `false` and `true`) — or a matchable choice type,
// whose every alternative index must be covered. The bool branch is
// decided before and without the `GetAs<SemIR::ClassType>` read, which
// would CHECK-fail on the bool singleton (W-076 plan §2.4). An empty
// alternative table answers false, and the no-coverage answer is right for
// both ways it arises: on an EMPTY choice there is nothing that covers,
// and an all-rejected-alternatives error-recovery table makes coverage
// unknowable — the same two-way answer `DiagnoseNonexhaustiveMatch`
// records. The one coverage predicate shared by the step-3b full-coverage
// usefulness rule (`EmitCaseArmTestAndBind`) and the dead-`default` check
// (`DiagnoseDeadDefault`, W-078a), so the two rules cannot diverge;
// `DiagnoseNonexhaustiveMatch` keeps its own per-value loops because it
// must NAME the missing values.
static auto UnguardedArmsCoverWholeDomain(
    Context& context, SemIR::TypeId unqualified_scrutinee_type_id,
    const Context::MatchStatementContext& match_context) -> bool {
  if (context.types().Is<SemIR::BoolType>(unqualified_scrutinee_type_id)) {
    return llvm::is_contained(match_context.covered_alternatives, 0) &&
           llvm::is_contained(match_context.covered_alternatives, 1);
  }
  const auto& class_info = context.classes().Get(
      context.types()
          .GetAs<SemIR::ClassType>(unqualified_scrutinee_type_id)
          .class_id);
  return !class_info.choice_alternatives.empty() &&
         llvm::all_of(
             class_info.choice_alternatives, [&](const auto& choice_alt) {
               return llvm::is_contained(match_context.covered_alternatives,
                                         choice_alt.index);
             });
}

// Emits a case arm's test and bind passes, once the arm's pattern is
// finished (`FinishCasePattern`): the shared driver's test pass
// (`EmitRefutableBindingTest`: the pattern block's `NameBindingDecl` home in
// the arm's test block, the classification of the checked pattern root, and
// the arm's condition), the `match`-only usefulness check and coverage
// recording, the then/else dispatch blocks, and the driver's bind pass in
// the arm's then (body) block, which is left pushed as the current block.
// Returns the arm's else block — the next test's home, which a guard's
// failure edge also targets — or `nullopt` after a "semantics TODO"
// diagnostic aborted checking.
//
// Called from `MatchCase` for an unguarded arm, with the `MatchCase` node,
// and from `MatchCaseGuardIntroducer` for a guarded arm (`is_guarded`),
// with the introducer node: a guarded arm runs both passes BEFORE its
// guard expression, so the guard checks directly into the body block with
// every binding filled. For a guarded arm the case-arm context is left on
// `match_case_stack` — it carries the arm's else block to `MatchCaseGuard`
// and `MatchCase` — and nothing beyond an error arm is recorded toward
// coverage: exhaustiveness assumes every guard can fail.
static auto EmitCaseArmTestAndBind(Context& context, Parse::NodeId node_id,
                                   bool is_guarded)
    -> std::optional<SemIR::InstBlockId> {
  auto pattern_id = context.match_case_stack().back().pattern_id;
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchCaseIntroducer>();
  context.decl_introducer_state_stack().Pop<Lex::TokenKind::Let>();

  auto introducer_node_id =
      context.match_case_stack().back().introducer_node_id;
  auto scrutinee_id = PeekScrutinee(context);

  // Test pass. An irrefutable `case` arm is the exhaustive arm, not a
  // warning. The resolved alternative is copied into `test`: an unguarded
  // arm's case-arm context is popped below, before the bind pass reads it.
  auto test = EmitRefutableBindingTest(
      context, node_id, pattern_id, scrutinee_id, /*warn_irrefutable=*/false);
  if (!test) {
    // A "semantics TODO" was diagnosed, which aborts checking.
    return std::nullopt;
  }
  const auto& alternative = test->alternative;

  // Usefulness check (W-066): diagnose a `case` arm whose pattern is not
  // useful in the context of the prior arms — every value it could match
  // is matched by a prior arm — as an error at this arm with a note at
  // the covering prior arm ("A pattern is not useful in the context of
  // prior patterns", docs/design/pattern_matching.md, "Refutability,
  // overlap, usefulness, and exhaustiveness"). Guarded and unguarded arms
  // are checked alike — an arm whose pattern is fully covered is dead
  // regardless of its guard, because control only reaches its test with
  // values prior arms already consumed — but only UNGUARDED arms are
  // recorded as context: a prior arm's guard is assumed to evaluate to
  // false, the same rule the exhaustiveness recording below applies. An
  // arm whose pattern or condition errored has unknowable coverage and is
  // neither checked nor recorded, but — unlike exhaustiveness — a prior
  // error arm does not suppress later arms' checks, which compare only
  // against soundly recorded priors; an arm whose error surfaces only in
  // the BIND pass (`case b: bool` on an i32 scrutinee) reaches this point
  // with a non-error pattern and IS recorded as covering, matching
  // `has_irrefutable_arm` below (W-066 plan §1.8). The check emits no
  // insts, and a diagnosed arm still emits its normal SemIR
  // (diagnose-and-proceed, like `MatchNonexhaustive`), so later arms are
  // still checked. It runs BEFORE this arm's own coverage recording below,
  // so the full-coverage step compares against prior arms only. `default`
  // arms never reach this site; their own deadness check is
  // `DiagnoseDeadDefault` (W-078a), which shares this site's
  // `UnguardedArmsCoverWholeDomain` coverage predicate.
  if (pattern_id != SemIR::ErrorInst::InstId &&
      test->cond_id != SemIR::ErrorInst::InstId) {
    // A `var`-wrapped alternative root keys through the alternative's
    // payload root, not the `VarPattern`: the key builder's defensive
    // check returns nullopt when the root is not the payload root, which
    // left `case var .Some(n: i32)` silently unchecked and unrecorded
    // (fork/w012/plan.md §1.1, re-review M1).
    auto key_pattern_id = test->is_var_alternative_arm
                              ? alternative->payload_pattern_id
                              : pattern_id;
    if (auto key = BuildMatchCaseUsefulnessKey(
            context, key_pattern_id, alternative,
            context.insts().Get(scrutinee_id).type_id())) {
      auto& match_context = context.match_statement_stack().back();
      CARBON_DIAGNOSTIC(MatchCaseNeverMatches, Error,
                        "`case` pattern never matches; every value it can "
                        "match is matched by a prior arm");
      bool diagnosed = false;
      // The first covering arm wins the note (arm order; deterministic).
      for (const auto& prior_arm : match_context.useful_arms) {
        if (UsefulnessKeySubsumes(prior_arm.key, *key)) {
          CARBON_DIAGNOSTIC(MatchCaseNeverMatchesPriorArm, Note,
                            "pattern is fully covered by this prior arm");
          context.emitter()
              .Build(introducer_node_id, MatchCaseNeverMatches)
              .Note(prior_arm.introducer_node_id, MatchCaseNeverMatchesPriorArm)
              .Emit();
          diagnosed = true;
          break;
        }
      }
      auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();
      auto unqualified_type_id =
          context.types().GetUnqualifiedType(scrutinee_type_id);
      bool is_bool_scrutinee =
          context.types().Is<SemIR::BoolType>(unqualified_type_id);
      if (!diagnosed &&
          key->front().kind == Context::MatchStatementContext::
                                   UsefulnessKeyNode::Kind::Wildcard &&
          (is_bool_scrutinee ||
           IsMatchableChoiceType(context, scrutinee_type_id))) {
        // A wildcard ROOT over a choice or bool scrutinee is the in-slice
        // position whose value domain is finite, so a UNION of prior
        // constant arms can cover it with no single prior subsuming it.
        // The coverage semantics are `DiagnoseNonexhaustiveMatch`'s: a
        // payload alternative counts only when covered with a wholly
        // irrefutable payload (the recording below), and a prior
        // irrefutable arm already diagnoses through the subsumption loop
        // above. An empty or all-rejected alternative table stays silent
        // (`UnguardedArmsCoverWholeDomain`'s two-way no-coverage answer).
        if (UnguardedArmsCoverWholeDomain(context, unqualified_type_id,
                                          match_context)) {
          // No single covering arm exists, so the note is one
          // statement-level note naming the scrutinee's type, stable under
          // prior-arm reshuffles. For a bool scrutinee the same note reads
          // "all alternatives of `bool`", licensed by the design's
          // bool-as-choice rule.
          CARBON_DIAGNOSTIC(MatchCaseNeverMatchesFullCoverage, Note,
                            "all alternatives of {0} are matched by prior "
                            "arms",
                            SemIR::TypeId);
          context.emitter()
              .Build(introducer_node_id, MatchCaseNeverMatches)
              .Note(scrutinee_id, MatchCaseNeverMatchesFullCoverage,
                    unqualified_type_id)
              .Emit();
          diagnosed = true;
        }
      }
      if (!is_guarded && !diagnosed) {
        // A diagnosed-dead arm is not recorded: a subsumed key adds no
        // coverage, and skipping it keeps later arms' notes pointing at
        // the FIRST covering arm.
        match_context.useful_arms.push_back(
            {.key = std::move(*key), .introducer_node_id = introducer_node_id});
      }
    }
  }

  // Record what this arm contributes to the enclosing statement's
  // exhaustiveness (SF-7). A guarded arm contributes nothing, whatever its
  // pattern: exhaustiveness assumes every guard can evaluate to false
  // (docs/design/pattern_matching.md, "Refutability, overlap, usefulness,
  // and exhaustiveness"). An unguarded irrefutable arm — a binding root, an
  // irrefutable `var` root, an all-binding tuple root, or an all-binding
  // struct root (full-set or subset+`_`), each irrefutable given the
  // arity/type or field set the checker enforced statically —
  // covers every scrutinee value and discharges exhaustiveness on EVERY
  // scrutinee lane: it is the one way an integer-, tuple-, or
  // struct-scrutinee
  // `match` is exhaustive without a `default` arm (W-078b); an
  // unguarded alternative-pattern arm covers its alternative only when its
  // payload tree is wholly irrefutable — a refutable payload such as
  // `.Some(42)` records nothing (pattern_matching.md:589-594); an unguarded
  // constant arm on a bool scrutinee covers its value, recorded as 0/1
  // (`SemIR::BoolValue`), the way an alternative's discriminant records —
  // `bool` is treated like a choice type whose alternatives are `false` and
  // `true` (docs/design/pattern_matching.md). An arm whose
  // pattern contained an error contributes unknowable coverage and
  // suppresses the exhaustiveness diagnostic.
  {
    auto& match_context = context.match_statement_stack().back();
    if (pattern_id == SemIR::ErrorInst::InstId ||
        test->cond_id == SemIR::ErrorInst::InstId) {
      match_context.has_error_arm = true;
    } else if (is_guarded) {
      // Guarded arms never count toward coverage.
    } else if (test->is_binding_arm || test->is_irrefutable_var_arm ||
               test->is_irrefutable_tuple_arm ||
               test->is_irrefutable_struct_arm) {
      match_context.has_irrefutable_arm = true;
    } else if (alternative && alternative->payload_is_irrefutable) {
      match_context.covered_alternatives.push_back(alternative->index);
    } else if (context.types().Is<SemIR::BoolType>(
                   context.types().GetUnqualifiedType(
                       context.insts().Get(scrutinee_id).type_id()))) {
      // The constant is read exactly where the usefulness key builder
      // reads it (`TryGetCaseBoolConstant`); a statement has one scrutinee
      // type, so the 0/1 indices cannot collide with choice discriminants
      // in `covered_alternatives`.
      if (auto bool_value = TryGetCaseBoolConstant(context, pattern_id)) {
        match_context.covered_alternatives.push_back(bool_value->ToBool() ? 1
                                                                          : 0);
      }
    }
  }

  context.full_pattern_stack().PopFullPattern();
  if (!is_guarded) {
    // A guarded arm's context stays on the stack, carrying the arm's else
    // block; nothing below reads it either way — the bind pass locates its
    // diagnostics at the offending subpattern (pattern_match.cpp).
    context.match_case_stack().pop_back();
  }

  // Create the arm's body block and the block for the next test (or the
  // `default` body), and branch to the right one.
  auto then_block_id =
      AddDominatedBlockAndBranchIf(context, node_id, test->cond_id);
  auto else_block_id = AddDominatedBlockAndBranch(context, node_id);

  // Start emitting the arm's body block.
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(then_block_id);
  context.region_stack().AddToRegion(then_block_id, node_id);

  // Bind pass: initialize the pattern's bindings from the scrutinee in the
  // arm's body block, where they are reachable only when the arm has
  // matched; `MatchHandler`'s scope cleanups discharge the bindings' objects
  // at arm exit.
  EmitRefutableBindingBind(context, node_id, pattern_id, scrutinee_id, *test);

  return else_block_id;
}

auto HandleParseNode(Context& context,
                     Parse::MatchCaseGuardIntroducerId node_id) -> bool {
  if (context.node_stack().PeekIs(Parse::NodeKind::MatchDefaultIntroducer)) {
    // A guard on a `default` arm (`default if (E) => ...`): there is no
    // case pattern to finish. Push the arm's scope — a case arm's scope is
    // pushed at `MatchCaseIntroducer` so the pattern's bindings cover the
    // guard, but a `default` arm has no pattern, so its scope starts at
    // the guard and `MatchHandlerStart` must not push a second one — and a
    // case-arm context with no pattern, into which `MatchCaseGuard`
    // records the guard's region; `MatchGuardedDefault` pops both. The
    // scrutinee's type is not recorded: only case patterns resolve
    // against it.
    context.scope_stack().PushForSameRegion(
        ScopeStack::CleanupScopeKind::Owned);
    context.match_case_stack().push_back(
        {.scrutinee_type_id = SemIR::TypeId::None,
         .introducer_node_id = node_id});
    // A guarded `default` keeps the capture-and-splice lane: open a fresh
    // expression region for the guard, which `MatchGuardedDefault` splices
    // into the arm's body block. A `default` arm has no bindings, so the
    // early capture has no use-before-fill hazard (contrast the case-arm
    // lane below).
    BeginExprRegionForPattern(context);
  } else {
    // The arm has a guard, so the case pattern's nodes are all checked:
    // finish the pattern, then run the arm's test and bind passes NOW,
    // before the guard expression. The guard is checked in the arm's scope
    // — the pattern's bindings are in scope in the guard
    // (docs/design/pattern_matching.md, "Guards") — and it must see them
    // FILLED: a binding's `WrapperBinding` is created empty at
    // pattern-check time and only the bind pass fills it, and SemIR's
    // expression-category query assumes a value category for an unfilled
    // binding (expr_info.cpp's own TODO) — wrong for `ref`-backed
    // bindings, whose fill is a durable reference. Running both passes
    // here leaves the arm's body block pushed, so the guard expression
    // checks directly into it, dominated by the pattern test — the guard
    // still evaluates only when the arm matched. `MatchCaseGuard` branches
    // on it; the else block rides in the arm's context until `MatchCase`
    // hands it to the handler chain.
    FinishCasePattern(context);
    auto else_block_id =
        EmitCaseArmTestAndBind(context, node_id, /*is_guarded=*/true);
    if (!else_block_id) {
      // A "semantics TODO" was diagnosed, which aborts checking.
      return false;
    }
    context.match_case_stack().back().else_block_id = *else_block_id;
  }
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardStartId node_id)
    -> bool {
  context.node_stack().Push(node_id);
  return true;
}

// Branches on a guard condition: into a new dominated body block on
// success, and to `else_block_id` on failure, destroying the arm's objects
// on the failure edge (which leaves the arm's scope). Destroy insts cannot
// sit inside a block's `BranchIf` + `Branch` terminator sequence, so when
// the arm owns cleanups — on-demand `var` case-binding storage (W-008 plan
// §2.4) is the first such object — the failure edge gets its own block; a
// cleanup-free failure edge keeps the landed two-terminator shape
// byte-for-byte. Pops the current block and leaves the body block pushed.
static auto BranchOnGuard(Context& context, Parse::NodeId node_id,
                          SemIR::LocId guard_loc_id, SemIR::InstId cond_id,
                          SemIR::InstBlockId else_block_id) -> void {
  auto body_block_id = AddDominatedBlockAndBranchIf(context, node_id, cond_id);
  auto depth = context.scope_stack().enclosing_cleanup_scope_depth();
  if (!context.scope_stack().GetCleanupsSince(depth).empty()) {
    auto fail_block_id = AddDominatedBlockAndBranch(context, node_id);
    context.inst_block_stack().Pop();
    context.inst_block_stack().Push(fail_block_id);
    context.region_stack().AddToRegion(fail_block_id, node_id);
  }
  AddBranchWithCleanups(context, guard_loc_id, else_block_id, depth);
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(body_block_id);
  context.region_stack().AddToRegion(body_block_id, node_id);
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardId node_id)
    -> bool {
  // Convert the guard's condition to a bool value. On the guarded `default`
  // lane the guard's expression region is still open, so the conversion
  // insts land inside the region and the region's result is a value (the
  // same invariant `FinishCasePattern` maintains for case expressions); on
  // the case-arm lane the conversion lands inline in the arm's body block,
  // with the guard itself. A conversion failure is diagnosed at the guard
  // expression either way.
  auto [expr_node_id, cond_id] = context.node_stack().PopExprWithNodeId();
  cond_id = ConvertToBoolValue(context, expr_node_id, cond_id);

  auto else_block_id = context.match_case_stack().back().else_block_id;
  if (else_block_id.has_value()) {
    // A guarded case arm: the test and bind passes ran at
    // `MatchCaseGuardIntroducer`, and the guard expression was checked
    // directly into the arm's body block, after the bind pass, so it
    // evaluated with the arm's bindings filled. Branch on it — into the
    // arm's body on success, and on failure to the same else block the
    // pattern test falls through to, so a failed guard tries the next arm
    // (or `default`). Objects created by the bind pass and the guard
    // itself are live on both edges: the success edge destroys them with
    // the arm scope's cleanups at arm exit (`MatchHandler`), and the
    // failure edge — which leaves the arm's scope — must destroy them
    // itself, before branching (`BranchOnGuard`). `DeferCleanups` keeps
    // the body's statement-level temporary-cleanup discharge from
    // destroying the guard's own temporaries early, the same way the bind
    // pass defers its conversion temporaries.
    context.scope_stack().DeferCleanups();
    BranchOnGuard(context, node_id, SemIR::LocId(node_id), cond_id,
                  else_block_id);
  } else {
    // A guarded `default` arm: record the captured condition region, which
    // `MatchGuardedDefault` splices into the arm's body block.
    auto region_id = ConsumeExprRegionForPattern(context, cond_id);
    EndEmptyExprRegionForPattern(context);
    auto& case_context = context.match_case_stack().back();
    case_context.guard_region_id = region_id;
    case_context.guard_node_id = node_id;
  }

  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchCaseGuardStart>();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchCaseGuardIntroducer>();
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchCaseId node_id) -> bool {
  // A guarded arm's test pass, bind pass, and guard branch already ran, at
  // `MatchCaseGuardIntroducer` and `MatchCaseGuard`, and its body block is
  // the current block; the work here is done. Pop the arm's context and
  // expose its else block for the handler chain.
  if (auto guarded_else_block_id =
          context.match_case_stack().back().else_block_id;
      guarded_else_block_id.has_value()) {
    context.match_case_stack().pop_back();
    context.node_stack().Push(node_id, guarded_else_block_id);
    return true;
  }

  // An unguarded arm: finish the pattern context begun by
  // `MatchCaseIntroducer`, then run the arm's test and bind passes.
  FinishCasePattern(context);
  auto else_block_id =
      EmitCaseArmTestAndBind(context, node_id, /*is_guarded=*/false);
  if (!else_block_id) {
    // A "semantics TODO" was diagnosed, which aborts checking.
    return false;
  }
  context.node_stack().Push(node_id, *else_block_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchDefaultIntroducerId node_id)
    -> bool {
  // Pushed so that `MatchCaseGuardIntroducer` can recognize a `default`
  // guard (a case guard's introducer follows the arm's pattern instead);
  // popped by `MatchDefault` or `MatchGuardedDefault`.
  context.node_stack().Push(node_id);
  return true;
}

// Diagnoses a `default` arm that can never match because the unguarded
// prior arms already cover every scrutinee value (W-078a, W-078b): "in a
// `match` statement, this happens if a pattern or
// `default` cannot match because all cases it could cover are handled by
// prior cases or a prior `default`" (docs/design/pattern_matching.md,
// "Refutability, overlap, usefulness, and exhaustiveness"; the design
// annotates a dead `default` "Error: unreachable."). Called from
// `MatchDefault` and `MatchGuardedDefault` with the arm's introducer node,
// after the `MatchDefaultIntroducer` entry is popped, so `PeekScrutinee`
// sees the prior `MatchHandler` / `MatchStatementStart` protocol. Guarded
// `default` arms are checked alike: deadness is arm reachability — the arm
// under test's own guard is assumed true, while guards on prior arms are
// assumed false, so guarded priors never cover (they are neither in
// `useful_arms` nor in `covered_alternatives`) — the same two-sided
// worst-case guard rule the case-arm usefulness check applies. Stage 1 —
// a single `Wildcard`-root prior subsumes `default` — runs on every
// scrutinee lane (W-078b); stage 2 — a UNION of unguarded priors
// covering the whole domain — is gated on the choice and bool lanes,
// the only closed root domains (see the union-stage comment below).
// Invariant tying this check to `DiagnoseNonexhaustiveMatch` on the
// integer/tuple/struct lane: `has_irrefutable_arm` is true iff
// `useful_arms` holds a `Wildcard`-root entry. Forward: every arm that
// sets the flag — binding, irrefutable `var`, all-binding tuple, and
// all-binding struct roots alike —
// keys as the single node `{Wildcard}` (pattern_match.cpp,
// `BuildMatchCaseUsefulnessKey`, whose irrefutability first-check runs
// before any `Struct` node is considered), and the FIRST such arm cannot
// itself be diagnosed dead on this lane — no union coverage exists for an
// open domain, so only a prior `Wildcard` arm could kill it — so it is
// recorded. Backward: only irrefutable roots key `Wildcard`. The one
// shared carve-out: a bind-pass-error arm (`case b: bool` on an `i32`
// scrutinee) sets the flag AND is recorded as covering (W-066 §1.8), so
// the two rules agree there too. A future pattern kind that is
// irrefutable but keys non-`Wildcard` would split the two rules — keep
// them aligned. Emits no insts, and the arm still emits its
// normal SemIR (diagnose-and-proceed, like `MatchCaseNeverMatches`).
static auto DiagnoseDeadDefault(Context& context,
                                Parse::NodeId introducer_node_id) -> void {
  auto scrutinee_id = PeekScrutinee(context);
  auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();
  auto unqualified_type_id =
      context.types().GetUnqualifiedType(scrutinee_type_id);

  const auto& match_context = context.match_statement_stack().back();
  // Suppress on any prior error arm, as `DiagnoseNonexhaustiveMatch` does.
  // This is a deliberate conservative DIVERGENCE from the case-arm
  // usefulness rule, which does not suppress on prior error arms (it
  // compares only against soundly recorded priors): the blanket
  // suppression here is a known deterministic false negative — an error
  // arm plus a `Wildcard`-root prior plus `default` stays silent where the
  // analogous `case` arm in the `default`'s position would be diagnosed
  // (W-078a plan §1.4; the asymmetry is pinned in
  // usefulness_no_false_positive.carbon).
  if (match_context.has_error_arm) {
    return;
  }

  CARBON_DIAGNOSTIC(MatchDefaultNeverMatches, Error,
                    "`default` arm never matches; every value of the "
                    "scrutinee is matched by prior arms");

  // Single-prior stage: only a `Wildcard`-root prior subsumes `default`,
  // which is equivalent to `case _: auto`
  // (docs/design/pattern_matching.md), keyed as the synthetic
  // `{Wildcard}`. The first covering arm wins the note (arm order;
  // deterministic, matching the case-arm check).
  Context::MatchStatementContext::UsefulnessKeyNode default_key_node = {
      .kind =
          Context::MatchStatementContext::UsefulnessKeyNode::Kind::Wildcard};
  for (const auto& prior_arm : match_context.useful_arms) {
    if (UsefulnessKeySubsumes(prior_arm.key, default_key_node)) {
      CARBON_DIAGNOSTIC(MatchDefaultNeverMatchesPriorArm, Note,
                        "every value is matched by this prior arm");
      context.emitter()
          .Build(introducer_node_id, MatchDefaultNeverMatches)
          .Note(prior_arm.introducer_node_id, MatchDefaultNeverMatchesPriorArm)
          .Emit();
      return;
    }
  }

  // Union stage: no single covering prior, but the unguarded arms cover
  // the whole domain together, so the note is one statement-level note
  // naming the scrutinee's unqualified type — for a bool scrutinee it
  // reads "all alternatives of `bool`", licensed by the design's
  // bool-as-choice rule (the landed W-076 wording). The stage exists only
  // for the closed root domains — choice and bool — so the lane test
  // gates it HERE, not at function entry: that placement is what keeps
  // `MatchDefaultNeverMatchesFullCoverage` structurally unreachable on an
  // integer, tuple, or struct scrutinee, whose open domain no union of
  // constant arms can cover — a struct-of-bools' root is OPEN under the
  // landed root-only record exactly as `(bool, bool)`'s is (W-076;
  // W-078b §1.2/R-6: root-only, residue not defect) — and on whose type
  // the `GetAs<SemIR::ClassType>` read
  // inside `UnguardedArmsCoverWholeDomain` would CHECK-fail.
  // `IsMatchableChoiceType` unqualifies internally, so passing the
  // qualified id is not an asymmetry with the `BoolType` test.
  if (context.types().Is<SemIR::BoolType>(unqualified_type_id) ||
      IsMatchableChoiceType(context, scrutinee_type_id)) {
    if (UnguardedArmsCoverWholeDomain(context, unqualified_type_id,
                                      match_context)) {
      CARBON_DIAGNOSTIC(MatchDefaultNeverMatchesFullCoverage, Note,
                        "all alternatives of {0} are matched by prior "
                        "arms",
                        SemIR::TypeId);
      context.emitter()
          .Build(introducer_node_id, MatchDefaultNeverMatches)
          .Note(scrutinee_id, MatchDefaultNeverMatchesFullCoverage,
                unqualified_type_id)
          .Emit();
    }
  }
}

auto HandleParseNode(Context& context, Parse::MatchDefaultId node_id) -> bool {
  auto introducer_node_id =
      context.node_stack()
          .PopForSoloNodeId<Parse::NodeKind::MatchDefaultIntroducer>();
  // The current block is the last case arm's else block, or the enclosing
  // block if there are no case arms; either way it is where the `default`
  // arm's body should be emitted, so there is nothing to do other than note
  // the presence of the `default` arm for `MatchStatement` — beyond
  // diagnosing the arm if the prior arms make it dead, with the error
  // located at the `default` keyword's introducer node. Parse guarantees
  // the unguarded `default` arm is last, so the priors-only check sees
  // every other arm.
  DiagnoseDeadDefault(context, introducer_node_id);
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchGuardedDefaultId node_id)
    -> bool {
  auto introducer_node_id =
      context.node_stack()
          .PopForSoloNodeId<Parse::NodeKind::MatchDefaultIntroducer>();
  // A guarded `default` is checked for deadness like the unguarded one —
  // its own guard is assumed true, so full prior coverage makes even the
  // guarded arm unreachable — and mid-list timing is sound: the check
  // compares against prior arms only, which is the definition of
  // usefulness (`DiagnoseDeadDefault`; W-078a plan §1.2). The check emits
  // nothing, so its ordering within this handler is free.
  DiagnoseDeadDefault(context, introducer_node_id);
  // Copy: the case-arm context pushed by `MatchCaseGuardIntroducer` holds
  // only the guard `MatchCaseGuard` recorded; there is no pattern and no
  // bindings.
  auto guard_region_id = context.match_case_stack().back().guard_region_id;
  auto guard_node_id = context.match_case_stack().back().guard_node_id;
  context.match_case_stack().pop_back();

  // The arm records nothing toward the enclosing statement's exhaustiveness:
  // `default` is equivalent to `case _: auto` and guarded arms never count
  // toward coverage, so a guarded `default` does not discharge the
  // `default` requirement (docs/design/pattern_matching.md, "Refutability,
  // overlap, usefulness, and exhaustiveness"), and as a guarded arm it
  // also blocks nothing for later arms' usefulness.

  // The guard is the arm's only test: `default` matches every value, so the
  // arm's condition is a constant `true` — the dispatch shape of a guarded
  // irrefutable binding arm (`EmitCaseArmTestAndBind`), minus the
  // `NameBindingDecl` and the bind pass.
  auto cond_value_id =
      MakeBoolLiteral(context, node_id, SemIR::BoolValue::True);
  auto then_block_id =
      AddDominatedBlockAndBranchIf(context, node_id, cond_value_id);
  auto else_block_id = AddDominatedBlockAndBranch(context, node_id);
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(then_block_id);
  context.region_stack().AddToRegion(then_block_id, node_id);

  // Splice the guard's captured condition region and branch on it — into
  // the arm's body on success, and on failure to the else block, which
  // holds the next arm's test (or the `default` body, or the statement's
  // convergence). The failure edge leaves the arm's scope, so it discharges
  // the scope's cleanups itself, exactly like a failed case guard.
  auto guard_cond_id = SpliceMatchCaseGuard(context, guard_region_id);
  context.scope_stack().DeferCleanups();
  BranchOnGuard(context, node_id, SemIR::LocId(guard_node_id), guard_cond_id,
                else_block_id);

  context.node_stack().Push(node_id, else_block_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchHandlerStartId node_id)
    -> bool {
  // A `case` arm's scope was pushed by `MatchCaseIntroducer`, so that pattern
  // bindings cover the guard and the body, and a guarded `default` arm's by
  // `MatchCaseGuardIntroducer`, covering the guard and the body; do not push
  // a second one. An unguarded `default` arm has neither, so its scope
  // starts here. Either way, `MatchHandler` pops the one arm scope.
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
    // This is the unguarded `default` arm's body: leave its block on the
    // instruction block stack for `MatchStatement` to converge, and leave
    // the `MatchDefault` entry on the node stack.
    return true;
  }

  // This is the body of a case arm or a guarded `default` arm: leave its
  // finished block on the instruction block stack for `MatchStatement` to
  // converge, and start emitting the else block, which holds the next arm's
  // test or the `default` body.
  auto else_block_id =
      context.node_stack().PeekIs(Parse::NodeKind::MatchGuardedDefault)
          ? context.node_stack().Pop<Parse::NodeKind::MatchGuardedDefault>()
          : context.node_stack().Pop<Parse::NodeKind::MatchCase>();
  context.inst_block_stack().Push(else_block_id);
  context.region_stack().AddToRegion(else_block_id, node_id);

  // Keep the scrutinee exposed for the next case arm.
  context.node_stack().Push(node_id, PeekScrutinee(context));
  return true;
}

// Diagnoses a `match` statement with no `default` arm whose arms are not
// exhaustive. No diagnostic when they are: an unguarded irrefutable arm
// covers everything, on every scrutinee lane; otherwise only a choice or
// bool scrutinee's closed value domain — a choice's alternatives, or
// bool's `false`/`true` pair — can be covered, every alternative's
// discriminant (or bool value, recorded as 0/1) by an unguarded arm (see
// the coverage recording in `MatchCase`), and the diagnostic names the
// uncovered alternatives or values. An integer, tuple, or struct
// scrutinee's domain is open — expression patterns are never exhaustive,
// enumeration-based exhaustiveness is design-rejected
// (docs/design/pattern_matching.md), and the aggregate root records no
// per-value coverage (root-only, W-076) — so without an irrefutable arm
// the `match` is nonexhaustive outright, diagnosed
// `MatchNonexhaustiveNoIrrefutableArm` naming no missing values (an open
// domain cannot enumerate its missing values, though for a struct the
// diagnostic still names the scrutinee type, rendered with its field
// list). An arm whose pattern
// contained an error suppresses the diagnostic — coverage is unknowable,
// and the arm carries its own diagnostic already.
static auto DiagnoseNonexhaustiveMatch(
    Context& context, Parse::NodeId node_id, SemIR::TypeId scrutinee_type_id,
    const Context::MatchStatementContext& match_context) -> void {
  if (match_context.has_irrefutable_arm || match_context.has_error_arm) {
    return;
  }

  auto unqualified_type_id =
      context.types().GetUnqualifiedType(scrutinee_type_id);

  // An integer, tuple, or struct scrutinee (W-078b; struct joins the same
  // open-domain lane, W-077): no closed domain, no
  // irrefutable arm (the early return above), so nonexhaustive outright,
  // naming no missing values. This branch also keeps the
  // `GetAs<SemIR::ClassType>` below reachable only for choice types,
  // which would CHECK-fail on an integer type. `IsMatchableChoiceType`
  // unqualifies internally, so passing the qualified id is not an
  // asymmetry with the `BoolType` test.
  if (!context.types().Is<SemIR::BoolType>(unqualified_type_id) &&
      !IsMatchableChoiceType(context, scrutinee_type_id)) {
    CARBON_DIAGNOSTIC(MatchNonexhaustiveNoIrrefutableArm, Error,
                      "`match` on {0} has no `default` arm and no `case` "
                      "arm that matches every value",
                      SemIR::TypeId);
    context.emitter().Emit(node_id, MatchNonexhaustiveNoIrrefutableArm,
                           unqualified_type_id);
    return;
  }

  if (context.types().Is<SemIR::BoolType>(unqualified_type_id)) {
    // A bool scrutinee. This branch must precede the
    // `GetAs<SemIR::ClassType>` below, which would CHECK-fail on the bool
    // singleton (W-076 plan §2.3, R-1). Bool values are not named
    // alternatives, so the missing values get their own diagnostic, spelled
    // `false`/`true` in domain order — mirroring the alternative-table
    // order the choice branch reports in.
    bool missing_false =
        !llvm::is_contained(match_context.covered_alternatives, 0);
    bool missing_true =
        !llvm::is_contained(match_context.covered_alternatives, 1);
    if (!missing_false && !missing_true) {
      return;
    }
    RawStringOstream missing_stream;
    llvm::ListSeparator sep;
    if (missing_false) {
      missing_stream << sep << "`false`";
    }
    if (missing_true) {
      missing_stream << sep << "`true`";
    }
    CARBON_DIAGNOSTIC(MatchNonexhaustiveBool, Error,
                      "`match` on `bool` has no `default` arm and does not "
                      "cover value{0:s} {1}",
                      Diagnostics::IntAsSelect, std::string);
    context.emitter().Emit(
        node_id, MatchNonexhaustiveBool,
        static_cast<int>(missing_false) + static_cast<int>(missing_true),
        missing_stream.TakeStr());
    return;
  }

  auto class_type =
      context.types().GetAs<SemIR::ClassType>(unqualified_type_id);
  const auto& class_info = context.classes().Get(class_type.class_id);
  // An empty name-to-index table means there is nothing to cover, and the
  // no-diagnostic answer below is right for both ways it arises. An EMPTY
  // choice (W-068) has a legitimately empty table: the match is vacuously
  // exhaustive — the loop below would find nothing missing anyway. Under
  // error recovery, a choice whose alternatives were ALL rejected with a
  // diagnostic gets no table entries (`handle_choice.cpp` skips the push for
  // each rejected alternative), yet the declared alternative count still
  // sizes a real integer discriminant, so the class completes and the
  // scrutinee passes its gate; coverage is then unknowable — bail without
  // diagnosing, mirroring the `has_error_arm` suppression, since the
  // declaration already carries its own diagnostics. A PARTIALLY-errored
  // choice keeps entries for its surviving alternatives, so coverage is
  // computed over those only — deliberate error-recovery behavior,
  // consistent with how references to rejected alternatives resolve.
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
  // Only an unguarded `default` arm satisfies the `default` requirement: a
  // guarded `default`'s guard can fail, so `MatchHandler` left it on the
  // node stack as an ordinary arm entry, counted below.
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
    // is an error per docs/design/pattern_matching.md. Exhaustiveness is an
    // unguarded irrefutable arm (any scrutinee lane, W-078b) or full
    // coverage of a closed value domain — a choice's alternatives, or
    // bool's `false`/`true` pair (choice and bool lanes only: an integer,
    // tuple, or struct scrutinee has no closed domain, and
    // enumeration-based
    // exhaustiveness is design-rejected, docs/design/pattern_matching.md).
    // Otherwise diagnose (`DiagnoseNonexhaustiveMatch`). Either way the
    // statement converges below: the last arm's else edge — dynamically
    // dead when the arms are exhaustive — branches to the resumption
    // block, the same shape an empty `default` arm produces.
    DiagnoseNonexhaustiveMatch(context, node_id,
                               context.insts().Get(scrutinee_id).type_id(),
                               match_context);
  }

  // The instruction block stack holds one body block per arm (`case` arms
  // and guarded `default` arms alike), plus one more block on top: the
  // unguarded `default` arm's body block, or — without one — the last arm's
  // empty else block, whose edge from the last arm's test branches straight
  // to the resumption block. Branch from all of them to a new resumption
  // block. With no other arms, the unguarded `default` body was emitted
  // directly into the enclosing block, and there is nothing to converge.
  int num_blocks = num_case_arms + 1;
  if (num_blocks >= 2) {
    AddConvergenceBlockAndPush(context, node_id, num_blocks);
  }
  return true;
}

}  // namespace Carbon::Check
