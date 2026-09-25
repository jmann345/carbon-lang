// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_PATTERN_MATCH_H_
#define CARBON_TOOLCHAIN_CHECK_PATTERN_MATCH_H_

#include <optional>

#include "toolchain/check/context.h"
#include "toolchain/sem_ir/class.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Check {

// TODO: Find a better place for this overview, once it has stabilized.
//
// The signature pattern of a function call is matched partially by the caller
// and partially by the callee. `ParamPattern` insts mark the boundary
// between the two: pattern insts that are descendants of a `ParamPattern`
// are matched by the callee, and pattern insts that have a `ParamPattern`
// as a descendant are matched by the caller.

// Return type for CalleePatternMatch.
struct CalleePatternMatchResults {
  SemIR::InstBlockId call_param_patterns_id;
  SemIR::InstBlockId call_params_id;

  SemIR::Function::CallParamIndexRanges param_ranges;
};

// Emits the pattern-match IR for the declaration of a parameterized entity with
// the given implicit and explicit parameter patterns, and the given return
// pattern (any of which may be `None` if not applicable). This IR performs the
// callee side of pattern matching, starting at the `ParamPattern` insts, and
// matching them against the corresponding `Call` parameters (see
// entity_with_params_base.h for the definition of that term).
// Returns the IDs of inst blocks consisting of references to the `Call`
// parameter patterns and `Call` parameters of the function, as well as
// the implicit, explicit, and return index ranges of those blocks.
//
// In some circumstances this can add new pattern insts, so the pattern
// block containing the parameter patterns should still be on top of
// `context.pattern_block_stack()`.
auto CalleePatternMatch(Context& context,
                        SemIR::InstBlockId implicit_param_patterns_id,
                        SemIR::InstBlockId param_patterns_id,
                        SemIR::InstId return_pattern_id)
    -> CalleePatternMatchResults;

// Return type for ThunkPatternMatch.
struct ThunkPatternMatchResults {
  // The syntactic argument list. If there is a self parameter, the first
  // element will be the corresponding argument.
  llvm::SmallVector<SemIR::InstId> syntactic_args;

  // The trailing elements of `outer_call_args` that were not used in
  // `syntactic_args`. These presumably represent the output arguments for the
  // return.
  llvm::ArrayRef<SemIR::InstId> ignored_call_args;
};

// Given the syntactic parameters and `Call` arguments for the outer part of a
// thunked function call, computes the corresponding syntactic argument list,
// suitable for passing to the inner part of the thunked function call.
auto ThunkPatternMatch(Context& context,
                       llvm::ArrayRef<SemIR::InstId> param_pattern_ids,
                       llvm::ArrayRef<SemIR::InstId> outer_call_args)
    -> ThunkPatternMatchResults;

// Emits the pattern-match IR for matching the given arguments with the given
// parameter patterns, and returns an inst block of the arguments that should
// be passed to the `Call` inst. `is_desugared` indicates that this call
// was produced by desugaring, not written as a function call in user code, so
// arguments to `ref` parameters aren't required to have `ref` tags.
auto CallerPatternMatch(Context& context, SemIR::SpecificId specific_id,
                        SemIR::InstId self_pattern_id,
                        SemIR::InstBlockId param_patterns_id,
                        SemIR::InstId return_pattern_id,
                        SemIR::InstId self_arg_id,
                        llvm::ArrayRef<SemIR::InstId> arg_refs,
                        SemIR::InstId return_arg_id, bool is_desugared)
    -> SemIR::InstBlockId;

// Emits the pattern-match IR for a local pattern matching operation with the
// given pattern and scrutinee.
auto LocalPatternMatch(Context& context, SemIR::InstId pattern_id,
                       SemIR::InstId scrutinee_id) -> void;

// Emits the refutable test IR for matching a `match` `case` pattern against
// the given scrutinee into the current block, and returns a boolean condition
// inst that is true when the arm matches. This is only the test pass of case
// matching: it prunes at irrefutable subtrees (binding initialization is the
// bind pass's job, via `LocalPatternMatch` or `MatchCaseBindPatternMatch`),
// and the dispatch CFG (branches and convergence) stays with the caller. The
// case-arm state pushed by `MatchCaseIntroducer` must be on
// `Context::match_case_stack()`.
//
// A tuple-pattern root walks the SCRUTINEE's tuple type elementwise — the
// pattern's own tuple type carries expression-element types such as
// `Core.IntLiteral` and is never converted to — emitting each refutable
// element's condition eagerly into the current block and folding the
// collected conditions into one bool (observationally equivalent to the
// design's short-circuit order because in-slice element reads are total and
// case expressions are constants; W-008 plan §2.1(a)). An errored element
// makes the whole condition `ErrorInst`.
//
// `case_node_id` is the `MatchCase` parse node, used as the location of the
// emitted comparison insts. Returns `None` after diagnosing an unsupported
// case-pattern shape with a "semantics TODO" diagnostic, which aborts
// checking.
auto MatchCasePatternMatch(Context& context, SemIR::InstId pattern_id,
                           SemIR::InstId scrutinee_id,
                           Parse::NodeId case_node_id) -> SemIR::InstId;

// Emits the bind-pass IR for a `match` `case` arm whose pattern tree mixes
// bindings with expression subpatterns: the irrefutable `LocalPatternMatch`
// walk, except that subtrees without bindings prune — the test pass owns
// expression-pattern regions (each is spliced exactly once, by the test),
// and only bindings have work left in the arm's body block. Wholly-binding
// trees take plain `LocalPatternMatch` instead, byte-for-byte.
auto MatchCaseBindPatternMatch(Context& context, SemIR::InstId pattern_id,
                               SemIR::InstId scrutinee_id) -> void;

// Returns whether a `match` `case` (sub)pattern tree is wholly irrefutable:
// binding patterns match any value, and a tuple of irrefutable elements is
// irrefutable given its arity/type, which the checker enforces statically.
// Expression subpatterns compare values, so any of them makes the tree
// refutable. This is the classification exhaustiveness recording consumes
// (`MatchCase` in handle_match.cpp), and the one W-066's usefulness work
// builds on.
auto IsIrrefutableMatchCasePattern(Context& context, SemIR::InstId pattern_id)
    -> bool;

// Returns whether a `match` `case` (sub)pattern tree contains any binding
// pattern — only then does the arm have bind-pass work in its body block.
auto MatchCasePatternHasBindings(Context& context, SemIR::InstId pattern_id)
    -> bool;

// Emits the extraction of one alternative's payload tuple from a choice
// scrutinee: field 1 of the choice's object representation (the payload
// region, with every alternative's payload tuple overlapping at offset zero
// per the F-007k storage contract), then the alternative's payload tuple
// field within it. Returns the field reference. The caller is responsible
// for emitting this only where the alternative is known active — under the
// arm's discriminant test (see `MatchCaseAlternativePatternMatch`) or in
// the arm's body block.
auto EmitChoicePayloadFieldAccess(Context& context, SemIR::LocId loc_id,
                                  SemIR::InstId scrutinee_id,
                                  int32_t payload_field_index) -> SemIR::InstId;

// If `type_id` is a complete choice type — including a specific of a generic
// choice — whose discriminant is an integer field, returns the discriminant's
// type; returns nullopt otherwise, including for choices with fewer than two
// alternatives, whose discriminant is the empty tuple (no discriminant test
// exists for them; see `IsMatchableChoiceType`). The object
// representation is read through `class_type->specific_id`, so a specific's
// repr arrives substituted; the `MatchCondition` scrutinee gate forces the
// specific's definition resolution (`RequireCompleteType`) before this runs
// (see handle_match.cpp). Uses the `Class::is_choice` entity flag, never the
// representation's spelling.
auto GetChoiceDiscriminantType(Context& context, SemIR::TypeId type_id)
    -> std::optional<SemIR::TypeId>;

// Returns whether `type_id` is a complete choice type `match` can dispatch
// on: its object representation upholds the F-007k `.discriminant` contract
// and the discriminant field is either an integer (two or more alternatives;
// `GetChoiceDiscriminantType` returns its type) or the empty tuple (fewer
// than two alternatives — a single-alternative choice's one arm is always
// taken with no discriminant test, and an empty choice is vacuously
// exhaustive; W-068). The same completion/specific-resolution caveats as
// `GetChoiceDiscriminantType` apply.
auto IsMatchableChoiceType(Context& context, SemIR::TypeId type_id) -> bool;

// If `type_id` is a choice type with an alternative named `name_id`, returns
// that alternative's name-to-index metadata; returns nullopt otherwise. The
// entry is returned by value: the class store may grow while the caller
// still holds it.
auto LookupChoiceAlternative(Context& context, SemIR::TypeId type_id,
                             SemIR::NameId name_id)
    -> std::optional<SemIR::ChoiceAlternative>;

// The types involved in extracting one alternative's payload from a choice
// value: the payload region (the `CustomLayoutType` field of the object
// representation, where every alternative's payload tuple overlaps at offset
// zero per the F-007k storage contract) and the alternative's own payload
// tuple field within it.
struct ChoicePayloadInfo {
  SemIR::TypeId payload_region_type_id;
  SemIR::TypeId payload_tuple_type_id;
};

// Returns the payload extraction types for the alternative whose payload
// tuple is at `payload_field_index` of `type_id`'s payload region, or
// nullopt if `type_id` is not a complete choice type with such a payload
// field. Verifies the payload field's name (`.payload`) rather than
// trusting its position alone; the `.discriminant` half of the
// representation is verified by `GetChoiceDiscriminantType`.
auto GetChoicePayloadInfo(Context& context, SemIR::TypeId type_id,
                          int32_t payload_field_index)
    -> std::optional<ChoicePayloadInfo>;

// Emits the comparison of `scrutinee_id`'s discriminant field against the
// discriminant value `alternative_index`, and returns the boolean condition.
// The discriminant is read as field 0 of the choice's
// `StructType{.discriminant, ...}` representation via `ClassElementAccess`
// (the F-007k storage contract), and compared with `EqWith` on the
// discriminant's integer type `disc_type_id` (`GetChoiceDiscriminantType`'s
// result for the scrutinee's type). Shared between `match` `case`
// alternative patterns and the postfix `?` desugar (handle_question.cpp).
auto EmitChoiceDiscriminantTest(Context& context, Parse::NodeId case_node_id,
                                SemIR::InstId scrutinee_id,
                                SemIR::TypeId disc_type_id,
                                int32_t alternative_index) -> SemIR::InstId;

// Emits the refutable test for the arm of a parenthesized alternative
// pattern (`case .Name(...)`): a comparison of the scrutinee's discriminant
// field against the resolved alternative's discriminant value, taken from
// the case-arm context's `alternative` (which must be set). Returns the
// boolean condition inst. An all-binding payload contributes no test of its
// own; binding initialization is the bind pass's job against the extracted
// payload tuple.
//
// A payload with expression subpatterns (`case .Some(42)`) additionally
// tests the payload's values — strictly under the discriminant test, in a
// payload block this function switches to explicitly BEFORE invoking the
// refutable engine on the payload tree: the payload region of a non-active
// alternative is uninitialized storage, so every payload read and compare
// must be dominated by the discriminant test (W-008 plan §4 R-2; the block
// dominance is correctness, not style). The discriminant and payload
// conditions merge into one bool through the failure edge's `false`
// block_arg. An errored payload condition still closes that merge (the CFG
// stays well-formed) but the return value is `ErrorInst::InstId`, so the
// caller records the error arm. Returns `None` after a "semantics TODO"
// diagnostic on an unsupported payload shape, which aborts checking.
auto MatchCaseAlternativePatternMatch(Context& context,
                                      SemIR::InstId scrutinee_id,
                                      Parse::NodeId case_node_id)
    -> SemIR::InstId;

// Splices a `match` `case` guard's captured condition region into the
// current code block, and returns the region's result (the guard condition
// as a bool value). `MatchCase` (handle_match.cpp) calls this in the arm's
// body block after the bind pass, so the guard evaluates with the arm's
// bindings initialized. The region may contain control flow (for example a
// short-circuiting `and`), in which case the current block ends with a
// branch into the region's blocks and emission resumes in the region's
// successor block; single-block regions splice in place.
auto SpliceMatchCaseGuard(Context& context, SemIR::ExprRegionId region_id)
    -> SemIR::InstId;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_PATTERN_MATCH_H_
