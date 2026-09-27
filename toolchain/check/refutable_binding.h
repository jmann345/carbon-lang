// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_REFUTABLE_BINDING_H_
#define CARBON_TOOLCHAIN_CHECK_REFUTABLE_BINDING_H_

#include <optional>

#include "llvm/ADT/StringRef.h"
#include "toolchain/check/context.h"
#include "toolchain/parse/node_ids.h"
#include "toolchain/sem_ir/class.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Check {

// The shared driver of the refutable pattern contexts: a `match` `case` arm,
// a pattern condition (`if (let P = e)`, `while (let P = e)`), and a
// `let`-`else` declaration (fork/w012/plan.md §2.2). Every context checks
// its pattern under `FullPatternStack::Kind::MatchCaseArm` with a
// `Context::MatchCaseContext` pushed, runs the refutable test pass against
// the scrutinee (`EmitRefutableBindingTest`), owns its own control flow, and
// runs the bind pass in its success block (`EmitRefutableBindingBind`). The
// `match`-only usefulness and exhaustiveness work stays in handle_match.cpp.
//
// The pattern-before-scrutinee order of the new forms (the parse tree visits
// `let P` before `= e`) is what `MatchCaseContext::pending_alternative`
// exists for: a root `.Name` is recorded at pattern time and resolved
// against the scrutinee's choice type at the start of the test pass
// (`ResolvePendingAlternative`), which `match` calls at pattern time instead.

// The driver contract between the two passes: the test pass's result, read
// by the bind pass.
using RefutableBindingTest = Context::MatchCaseContext::RefutableBindingTest;

// The scrutinee-shape TODO of the pattern-condition and `let`-`else` forms
// (`CheckRefutableScrutinee`'s `todo_string`; `match` passes its own).
inline constexpr llvm::StringLiteral RefutableBindingScrutineeTodo =
    "refutable pattern binding on unsupported scrutinee type";

// Starts a refutable pattern context: pushes the `let` introducer state, a
// pattern block, a `MatchCaseArm` full-pattern frame, an expression region,
// and a `MatchCaseContext` whose scrutinee type is `None` (the scrutinee is
// checked after the pattern; alternatives resolve at test time) and whose
// TODO location is `introducer_node_id`. `match` fills the scrutinee type
// itself right after this.
auto BeginRefutableBinding(Context& context, Parse::NodeId introducer_node_id)
    -> void;

// Closes the expression region of a refutable context's pattern, first
// converting a leftover initializing-category root expression to a value
// (the root `ExprPattern` invariant; see the comment in
// handle_match.cpp's `FinishCasePattern`). The pattern root is LEFT on the
// node stack. Shared by `EndRefutableBindingPattern` and `match`'s
// `FinishCasePattern`, which adds the pop into its case context.
auto EndRefutablePatternRegion(Context& context) -> void;

// Ends the pattern of a pattern condition or `let`-`else` and starts its
// initializer: `EndRefutablePatternRegion`, then
// `StartPatternInitializer` (the bindings are tombstoned while the
// initializer is checked). The pattern root is LEFT on the node stack — the
// form's close handler pops it exactly once and passes it to
// `EmitRefutableBindingTest`.
auto EndRefutableBindingPattern(Context& context) -> void;

// Returns whether `type_id` is a scrutinee shape the refutable engine can
// dispatch on: an integer shape, plain `bool`, a matchable choice, or a
// tuple or struct whose element/field types are recursively in-slice
// matchable (tuple and struct scrutinees dispatch elementwise/fieldwise, so
// each element or field must itself be dispatchable, and a tuple or struct
// of trivially destructible member types is trivially destructible — the
// temporary-cleanup argument at the gate extends memberwise). Adapter
// classes over struct types stay behind the scrutinee TODO, matching the
// int/bool strictness. Iterative worklist (misc-no-recursion); nothing the
// walk visits can form a cycle.
auto IsSupportedScrutineeType(Context& context, SemIR::TypeId type_id) -> bool;

// The scrutinee gate shared by `match` and the new forms: converts the
// scrutinee to a value or reference expression (it is used once per test),
// requires its type complete (with the `IncompleteTypeInMatchScrutinee`
// context note), gates the shape (`todo_string` names the form for the
// TODO), and destroys the scrutinee expression's temporaries. Returns the
// converted scrutinee, or `None` after a diagnostic that aborts checking.
auto CheckRefutableScrutinee(Context& context, Parse::NodeId node_id,
                             SemIR::InstId scrutinee_id,
                             llvm::StringLiteral todo_string) -> SemIR::InstId;

// The outcome of resolving a root alternative pattern's name against the
// scrutinee's choice type (`ResolvePendingAlternative`).
struct ResolvedAlternative {
  // The choice's metadata for the name, whatever the alternative's shape;
  // nullopt when the name is not an alternative of the choice (the caller
  // emits the standard member-access diagnostic for it).
  std::optional<SemIR::ChoiceAlternative> lookup;
  // The resolved alternative when the name resolves and the pattern passes
  // the parens-iff-parameters and arity rules: a constant alternative
  // records its index only, a payload alternative its index and payload
  // field index. `payload_pattern_id` and `payload_is_irrefutable` are the
  // caller's to fill (it holds the payload root). nullopt with `lookup` set
  // means a diagnosed error.
  std::optional<Context::MatchCaseContext::Alternative> alternative;
  // Whether a "semantics TODO" was diagnosed, which aborts checking.
  bool aborted = false;
};

// Resolves a root alternative pattern named `name_id` (with `has_parens`
// payload parentheses holding `subpattern_count` subpatterns; a negative
// count means the payload errored and the arity rule is skipped) against
// `scrutinee_type_id`, for `match` at pattern time and for the new forms
// at test time alike — one body for the diagnostics: the choice gate (a
// TODO pinned to the case context's introducer node), the
// `LookupChoiceAlternative`, `MatchAlternativeUnexpectedParens`,
// `MatchAlternativeMissingParens`, and `MatchAlternativeArgCountMismatch`
// at `node_id`.
auto ResolvePendingAlternative(Context& context, Parse::NodeId node_id,
                               SemIR::TypeId scrutinee_type_id,
                               SemIR::NameId name_id, bool has_parens,
                               int subpattern_count) -> ResolvedAlternative;

// Test pass. `pattern_id` is the finished root; resolves a pending
// alternative against the scrutinee's type, attaches the pattern block to a
// `NameBindingDecl` in the current block, classifies the root exactly as the
// `match` case arm does, and emits the arm's condition. Emits
// `IrrefutablePatternAlwaysMatches` (a warning at the introducer) when
// `warn_irrefutable` and the pattern cannot fail. Returns `nullopt` after an
// aborting TODO. Pops NOTHING: the full-pattern frame and the case context
// stay pushed; the CALLER pops them (`match` before its branches, the new
// forms after the bind pass).
auto EmitRefutableBindingTest(Context& context, Parse::NodeId node_id,
                              SemIR::InstId pattern_id,
                              SemIR::InstId scrutinee_id, bool warn_irrefutable)
    -> std::optional<RefutableBindingTest>;

// Bind pass, in the current (success) block: the lane selection keyed on
// `test`'s flags — `LocalPatternMatch` for all-binding `var`-free trees,
// `MatchCaseBindPatternMatch` otherwise, payload extraction for
// `test.alternative`, the var-alternative lane for a `var`-wrapped
// alternative root — each lane gated on `test.cond_id != ErrorInst`, then
// `DeferCleanups` so the bindings' objects live to the end of the owning
// scope. Pops NOTHING (the caller owns the frame and context pops).
auto EmitRefutableBindingBind(Context& context, Parse::NodeId node_id,
                              SemIR::InstId pattern_id,
                              SemIR::InstId scrutinee_id,
                              const RefutableBindingTest& test) -> void;

// The result of checking a pattern condition's initializer, for the
// `IfCondition`/`WhileCondition` pattern paths.
struct PatternConditionResult {
  SemIR::InstId pattern_id;
  SemIR::InstId scrutinee_id;
  RefutableBindingTest test;
};

// Checks a pattern condition once its initializer expression has been
// popped (`init_node_id`, `init_id`) and the `PatternConditionInitializer`
// solo node is on top of the node stack: the `and`/`or` chain reservation,
// the scrutinee gate, the end of the initializer (the tombstones lift), the
// pattern root pop, the test pass (warning on an irrefutable pattern), and
// the `let` introducer state pop. Leaves the `PatternConditionIntroducer`
// solo node on the node stack for the caller. Returns `nullopt` after a
// diagnostic that aborts checking.
auto CheckPatternConditionInitializer(Context& context, Parse::NodeId node_id,
                                      Parse::NodeId init_node_id,
                                      SemIR::InstId init_id)
    -> std::optional<PatternConditionResult>;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_REFUTABLE_BINDING_H_
