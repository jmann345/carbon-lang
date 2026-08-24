// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/pattern_match.h"

#include <functional>
#include <optional>
#include <utility>
#include <variant>
#include <vector>

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "toolchain/base/kind_switch.h"
#include "toolchain/check/action.h"
#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/core_identifier.h"
#include "toolchain/check/eval.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/operator.h"
#include "toolchain/check/pattern.h"
#include "toolchain/check/type.h"
#include "toolchain/diagnostics/format_providers.h"
#include "toolchain/sem_ir/expr_info.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst_kind.h"
#include "toolchain/sem_ir/pattern.h"

namespace Carbon::Check {

namespace {

// State for caller-side pattern matching.
struct CallerState {
  // The in-progress contents of the `Call` arguments block.
  llvm::SmallVector<SemIR::InstId> call_args;
};

// Manages the allocation of call parameter indices.
class IndexSource {
 public:
  // Creates an IndexSource that will allocate indices starting from
  // `next_index`.
  explicit IndexSource(SemIR::CallParamIndex next_index)
      : next_index_(next_index) {}

  // Returns the index that will be allocated next.
  auto Peek() const -> SemIR::CallParamIndex { return next_index_; }

  // Allocates and returns the next index.
  auto Allocate() -> SemIR::CallParamIndex {
    auto result = next_index_;
    ++next_index_.index;
    return result;
  }

 private:
  SemIR::CallParamIndex next_index_;
};

// State for callee-side pattern matching.
struct CalleeState {
  // Pushes an inst onto the list of `Call` parameter patterns whose constant
  // value is the substituted constant value of `pattern_id` in `specific_id`.
  auto PushCallParamPattern(Context& context, SemIR::LocId loc_id,
                            SemIR::InstId pattern_id,
                            SemIR::SpecificId specific_id) -> void {
    call_param_patterns.push_back(
        WrapInstForSpecific(context, loc_id, pattern_id, specific_id).inst_id);
  }

  IndexSource index;

  // The in-progress contents of the `Call` parameters block.
  llvm::SmallVector<SemIR::InstId> call_params;

  // The in-progress contents of the `Call` parameter patterns block.
  llvm::SmallVector<SemIR::InstId> call_param_patterns;
};

// State for local pattern matching.
struct LocalState {
  // True when this walk is the bind pass of a `match` `case` arm with
  // expression subpatterns (`MatchCaseBindPatternMatch`): subtrees without
  // bindings prune — the test pass owns expression-pattern regions, and
  // splicing a region twice is not supported (see `InsertHere`) — and the
  // tuple pre-work walks the scrutinee's own tuple type instead of
  // converting to the pattern's (see `DoMatchCaseTuplePreWork`). `let` and
  // `var` behavior is unchanged when this is false.
  bool in_match_case_bind = false;
};

// State for thunk pattern matching.
struct ThunkState {
  // The not-yet-processed `Call` arguments for the outer call.
  llvm::ArrayRef<SemIR::InstId> outer_call_args;
};

// State for `match` `case` pattern matching: the refutable test pass, which
// emits the arm's boolean condition into the current (test) block. It prunes
// at irrefutable subtrees: bindings are irrefutable and belong to the bind
// pass, which owns their `bind_name_map` entries. Each refutable leaf
// appends its condition to the flat results array the caller pushed; the
// caller folds them into the arm's single condition. See
// `MatchCasePatternMatch`.
struct MatchCaseState {
  // The `MatchCase` parse node, used as the location of the emitted
  // comparison insts.
  Parse::NodeId case_node_id;
};

using State = std::variant<CallerState*, CalleeState*, LocalState*, ThunkState*,
                           MatchCaseState*>;

// The worklist and state machine for a pattern-matching operation.
//
// Conceptually, pattern matching is a recursive traversal of the pattern inst
// tree: we match a pattern inst to a scrutinee inst by converting the scrutinee
// as needed, matching any subpatterns against corresponding parts of the
// scrutinee, and assembling the results of those sub-matches to form the result
// of the whole match.
//
// This recursive traversal is implemented as a stack of work items, each
// associated with a particular pattern inst. There are two types of work items,
// PreWork and PostWork, which correspond to the work that is done before and
// after visiting an inst's subpatterns, and are handled by DoPreWork and
// DoPostWork overloads, respectively. Note that when there are no subpatterns,
// DoPreWork may push a PostWork onto the stack, or may do the post-work (if
// any) locally.
//
// DoPostWork is primarily responsible for computing the pattern's result and
// adding it to result_stack_. However, the result of matching a pattern is
// often not needed, so to avoid emitting unnecessary SemIR, it should only do
// that if need_subpattern_results() is true.
//
// The traversal behavior depends on the kind of matching being performed. In
// particular, many parts of a function signature pattern are irrelevant to the
// caller, or to the callee, in which case no work will be done in that part of
// the traversal. If an entire subpattern is known to be irrelevant in the
// current matching context, it will not be traversed at all.
class MatchContext {
 public:
  struct PreWork : Printable<PreWork> {
    // `None` when processing the callee side.
    SemIR::InstId scrutinee_id;

    auto Print(llvm::raw_ostream& out) const -> void {
      out << "{PreWork, scrutinee_id: " << scrutinee_id << "}";
    }
  };

  struct PostWork : Printable<PostWork> {
    auto Print(llvm::raw_ostream& out) const -> void { out << "{PostWork}"; }
  };

  struct WorkItem : Printable<WorkItem> {
    SemIR::InstId pattern_id;

    std::variant<PreWork, PostWork> work;

    // If true, disables diagnostics that would otherwise require scrutinee_id
    // to be tagged with `ref`. Only affects caller pattern matching.
    bool allow_unmarked_ref = false;

    auto Print(llvm::raw_ostream& out) const -> void {
      out << "{pattern_id: " << pattern_id << ", work: ";
      std::visit([&](const auto& work) { out << work; }, work);
      out << ", allow_unmarked_ref: " << allow_unmarked_ref << "}";
    }
  };

  // Constructs a MatchContext that uses the substituted constant values of
  // patterns in the given specific.
  explicit MatchContext(Context& context,
                        SemIR::SpecificId specific_id = SemIR::SpecificId::None)
      : specific_id_stack_({specific_id}), context_(context) {}

  // Performs pattern matching for the given work item.
  auto Match(State state, WorkItem entry) -> void;

  // Performs pattern matching for the given work item, and returns the result.
  auto MatchWithResult(State state, WorkItem entry) -> SemIR::InstId;

  // Performs pattern matching for the given work item, and returns the flat
  // list of collected results — the `match` `case` test pass collects one
  // condition per refutable leaf, in element order, for the caller to fold.
  auto MatchWithConditions(State state, WorkItem entry)
      -> llvm::SmallVector<SemIR::InstId>;

 private:
  // Whether the result of the work item at the top of the stack is needed.
  auto need_subpattern_results() const -> bool {
    return !results_stack_.empty();
  }

  // Adds `entry` to the front of the worklist.
  auto AddWork(WorkItem entry) -> void { stack_.push_back(entry); }

  // Sets `entry.work` to `PostWork` and adds it to the front of the worklist.
  auto AddAsPostWork(WorkItem entry) -> void {
    entry.work = PostWork{};
    AddWork(entry);
  }

  // Dispatches `entry` to the appropriate DoWork method based on the kinds of
  // `entry.pattern_id` and `entry.work`.
  auto Dispatch(State state, WorkItem entry) -> void;

  // Do the pre-work for `entry`. `entry.work` must be a `PreWork` containing
  // `scrutinee_id`, and the pattern argument must be the value of
  // `entry.pattern_id` in `context`.
  auto DoPreWork(State state, SemIR::AnyBindingPattern binding_pattern,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::AnyParamPattern param_pattern,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::AnyReturnPattern return_pattern,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::ExprPattern expr_pattern,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::FieldDecl field_decl,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::ReturnSlotPattern return_slot_pattern,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::VarPattern var_pattern,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::TuplePattern tuple_pattern,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::SpliceInst splice,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::SpecificConstant specific_constant,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;
  auto DoPreWork(State state, SemIR::ImportRefLoaded import_ref,
                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;

  // Do the post-work for `entry`. `entry.work` must be a `PostWork`, and
  // the pattern argument must be the value of `entry.pattern_id` in `context_`.
  auto DoPostWork(State state, SemIR::AnyBindingPattern binding_pattern,
                  WorkItem entry) -> void;
  auto DoPostWork(State state, SemIR::VarPattern var_pattern, WorkItem entry)
      -> void;
  auto DoPostWork(State state, SemIR::AnyParamPattern param_pattern,
                  WorkItem entry) -> void;
  auto DoPostWork(State state, SemIR::ExprPattern expr_pattern, WorkItem entry)
      -> void;
  auto DoPostWork(State state, SemIR::ReturnSlotPattern return_slot_pattern,
                  WorkItem entry) -> void;
  auto DoPostWork(State state, SemIR::TuplePattern tuple_pattern,
                  WorkItem entry) -> void;
  auto DoPostWork(State state, SemIR::SpecificConstant specific_constant,
                  WorkItem entry) -> void;
  auto DoPostWork(State state, SemIR::ImportRefLoaded import_ref,
                  WorkItem entry) -> void;

  // Performs the core logic of matching a variable pattern whose scrutinee
  // type is `scrutinee_type_id`, but returns the scrutinee that its subpattern
  // should be matched with, rather than pushing it onto the worklist. This is
  // factored out so it can be reused by `VarParamPattern`, which needs to do
  // the pre-work of both a `VarPattern` and a `RefParamPattern`.
  auto DoVarPreWorkImpl(State state, SemIR::TypeId scrutinee_type_id,
                        SemIR::InstId scrutinee_id, WorkItem entry) const
      -> SemIR::InstId;

  // Performs the core logic of matching `entry.scrutinee_id` against the
  // constant value of `entry.pattern_id`, rather than against the pattern inst
  // itself. Factored out so that it can be reused across all inst kinds that
  // can indirectly represent patterns, like `ImportRefLoaded` and
  // `SpecificConstant`.
  auto DoIndirectPreWorkImpl(State state, WorkItem entry) -> void;

  // The tuple pre-work for both passes of a `match` `case` arm. Unlike the
  // shared tuple pre-work, this walks the SCRUTINEE's own tuple type: the
  // pattern's tuple type carries expression-element types such as
  // `Core.IntLiteral` (pattern.cpp), so a design-valid `case (1, b: i32)`
  // has no conversion from a real `(i32, i32)` scrutinee — the whole-tuple
  // conversion is skipped, the arity is checked against the scrutinee's
  // `TupleType`, element accesses take the scrutinee's element types, and
  // per-leaf typing is left to the leaves (the `==` at expression leaves,
  // the per-binding conversion in the bind pass). Subtrees the pass prunes —
  // irrefutable ones in the test pass, binding-free ones in the bind pass —
  // get no element access at all.
  auto DoMatchCaseTuplePreWork(SemIR::TuplePattern tuple_pattern,
                               SemIR::InstId scrutinee_id, WorkItem entry,
                               bool is_test_pass) -> void;

  // Emits the refutable test for an expression pattern in a `match` `case`
  // and returns the boolean condition inst, or `None` after diagnosing an
  // unsupported case-pattern shape with a "semantics TODO" diagnostic (which
  // aborts checking).
  auto DoMatchCaseExprPattern(const MatchCaseState& match_case_state,
                              SemIR::ExprPattern expr_pattern,
                              SemIR::InstId scrutinee_id) -> SemIR::InstId;

  // Asserts that there is a single inst in the top array in `results_stack_`,
  // pops that array, and returns the inst.
  auto PopResult() -> SemIR::InstId {
    CARBON_CHECK(results_stack_.PeekArray().size() == 1);
    auto value_id = results_stack_.PeekArray()[0];
    results_stack_.PopArray();
    return value_id;
  }

  // The stack of work to be processed.
  llvm::SmallVector<WorkItem> stack_;

  // The stack of in-progress match results. Each array in the stack represents
  // a single result, which may have multiple sub-results.
  ArrayStack<SemIR::InstId> results_stack_;

  // The top of this stack represents the specific that should currently be
  // substituted into pattern insts before matching them (if any). This is
  // never empty, because the constructor pushes an initial specific that
  // should never be popped.
  llvm::SmallVector<SemIR::SpecificId> specific_id_stack_;

  Context& context_;
};

}  // namespace

auto MatchContext::Match(State state, WorkItem entry) -> void {
  Diagnostics::AnnotationScope annotate_diagnostics(
      &context_.emitter(), [&](auto& builder) {
        if (std::holds_alternative<CallerState*>(state)) {
          CARBON_DIAGNOSTIC(InCallToFunctionParam, Note,
                            "initializing function parameter");
          builder.Note(entry.pattern_id, InCallToFunctionParam);
        }
      });
  CARBON_CHECK(stack_.empty());
  stack_.push_back(entry);
  while (!stack_.empty()) {
    Dispatch(state, stack_.pop_back_val());
  }
}

auto MatchContext::MatchWithResult(State state, WorkItem entry)
    -> SemIR::InstId {
  results_stack_.PushArray();
  Match(state, entry);
  return PopResult();
}

auto MatchContext::MatchWithConditions(State state, WorkItem entry)
    -> llvm::SmallVector<SemIR::InstId> {
  results_stack_.PushArray();
  Match(state, entry);
  llvm::SmallVector<SemIR::InstId> conditions(
      results_stack_.PeekArray().begin(), results_stack_.PeekArray().end());
  results_stack_.PopArray();
  return conditions;
}

// Inserts the given region into the current code block. If the region
// consists of a single block, this will be implemented as a `splice_block`
// inst. Otherwise, this will end the current block with a branch to the entry
// block of the region, and add future insts to a new block which is the
// immediate successor of the region's exit block. As a result, this cannot be
// called more than once for the same region.
static auto InsertHere(Context& context, SemIR::ExprRegionId region_id)
    -> SemIR::InstId {
  auto region = context.sem_ir().expr_regions().Get(region_id);
  auto exit_block = context.inst_blocks().Get(region.block_ids.back());
  if (region.block_ids.size() == 1) {
    // TODO: Is it possible to avoid leaving an "orphan" block in the IR in the
    // first two cases?
    if (exit_block.empty()) {
      return region.result_id;
    }
    if (exit_block.size() == 1) {
      context.inst_block_stack().AddInstId(exit_block.front());
      return region.result_id;
    }
    return AddInst<SemIR::SpliceBlock>(
        context, SemIR::LocId(region.result_id),
        {.type_id = context.insts().Get(region.result_id).type_id(),
         .block_id = region.block_ids.front(),
         .result_id = region.result_id});
  }
  if (context.region_stack().empty()) {
    context.TODO(region.result_id,
                 "Control flow expressions are currently only supported inside "
                 "functions.");
    return SemIR::ErrorInst::InstId;
  }
  AddInst(context, SemIR::LocIdAndInst::NoLoc<SemIR::Branch>(
                       {.target_id = region.block_ids.front()}));
  context.inst_block_stack().Pop();
  // TODO: this will cumulatively cost O(MN) running time for M blocks
  // at the Nth level of the stack. Figure out how to do better.
  context.region_stack().AddToRegion(region.block_ids);
  auto resume_with_block_id =
      context.insts().GetAs<SemIR::Branch>(exit_block.back()).target_id;
  CARBON_CHECK(context.inst_blocks().GetOrEmpty(resume_with_block_id).empty());
  context.inst_block_stack().Push(resume_with_block_id);
  context.region_stack().AddToRegion(resume_with_block_id,
                                     SemIR::LocId(region.result_id));
  return region.result_id;
}

// The shared representation walk behind the choice-scrutinee queries below:
// if `type_id` is a complete choice class type — entity truth via
// `Class::is_choice` — whose object representation upholds the F-007k
// storage contract (a `StructType` whose field 0 is `.discriminant`),
// returns the discriminant field's type, whatever that type is; returns
// nullopt otherwise, including for the error-recovery repr of a choice all
// of whose payloads were rejected (its object repr is the error type, not a
// `StructType`).
static auto GetChoiceDiscriminantFieldType(Context& context,
                                           SemIR::TypeId type_id)
    -> std::optional<SemIR::TypeId> {
  auto unqualified_type_id = context.types().GetUnqualifiedType(type_id);
  auto class_type =
      context.types().TryGetAsIfValid<SemIR::ClassType>(unqualified_type_id);
  if (!class_type) {
    return std::nullopt;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (!class_info.is_choice || !class_info.is_complete()) {
    return std::nullopt;
  }
  auto object_repr_id =
      class_info.GetObjectRepr(context.sem_ir(), class_type->specific_id);
  auto struct_type =
      context.types().TryGetAsIfValid<SemIR::StructType>(object_repr_id);
  if (!struct_type) {
    return std::nullopt;
  }
  auto fields = context.struct_type_fields().Get(struct_type->fields_id);
  if (fields.empty() ||
      fields.front().name_id != SemIR::NameId::ChoiceDiscriminant) {
    return std::nullopt;
  }
  return context.types().GetTypeIdForTypeInstId(fields.front().type_inst_id);
}

auto GetChoiceDiscriminantType(Context& context, SemIR::TypeId type_id)
    -> std::optional<SemIR::TypeId> {
  auto disc_type_id = GetChoiceDiscriminantFieldType(context, type_id);
  if (!disc_type_id || !context.types().TryGetIntTypeInfo(*disc_type_id)) {
    return std::nullopt;
  }
  return disc_type_id;
}

auto IsMatchableChoiceType(Context& context, SemIR::TypeId type_id) -> bool {
  auto disc_type_id = GetChoiceDiscriminantFieldType(context, type_id);
  if (!disc_type_id) {
    return false;
  }
  // Two or more alternatives dispatch on an integer discriminant; fewer than
  // two have the empty-tuple discriminant field (handle_choice.cpp) —
  // nothing to test at dispatch, but a matchable scrutinee (W-068). Any
  // other field type is not a shape `handle_choice.cpp` produces; fail safe.
  return context.types().TryGetIntTypeInfo(*disc_type_id).has_value() ||
         *disc_type_id == GetTupleType(context, {});
}

auto LookupChoiceAlternative(Context& context, SemIR::TypeId type_id,
                             SemIR::NameId name_id)
    -> std::optional<SemIR::ChoiceAlternative> {
  auto unqualified_type_id = context.types().GetUnqualifiedType(type_id);
  auto class_type =
      context.types().TryGetAsIfValid<SemIR::ClassType>(unqualified_type_id);
  if (!class_type) {
    return std::nullopt;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  for (const auto& alternative : class_info.choice_alternatives) {
    if (alternative.name_id == name_id) {
      return alternative;
    }
  }
  return std::nullopt;
}

auto GetChoicePayloadInfo(Context& context, SemIR::TypeId type_id,
                          int32_t payload_field_index)
    -> std::optional<ChoicePayloadInfo> {
  auto unqualified_type_id = context.types().GetUnqualifiedType(type_id);
  auto class_type =
      context.types().TryGetAsIfValid<SemIR::ClassType>(unqualified_type_id);
  if (!class_type) {
    return std::nullopt;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (!class_info.is_choice || !class_info.is_complete()) {
    return std::nullopt;
  }
  auto object_repr_id =
      class_info.GetObjectRepr(context.sem_ir(), class_type->specific_id);
  auto struct_type =
      context.types().TryGetAsIfValid<SemIR::StructType>(object_repr_id);
  if (!struct_type) {
    return std::nullopt;
  }
  auto fields = context.struct_type_fields().Get(struct_type->fields_id);
  if (fields.size() < 2 || fields[1].name_id != SemIR::NameId::ChoicePayload) {
    return std::nullopt;
  }
  auto payload_region_type_id =
      context.types().GetTypeIdForTypeInstId(fields[1].type_inst_id);
  auto custom_layout = context.types().TryGetAsIfValid<SemIR::CustomLayoutType>(
      payload_region_type_id);
  if (!custom_layout) {
    return std::nullopt;
  }
  auto payload_fields =
      context.struct_type_fields().Get(custom_layout->fields_id);
  if (payload_field_index < 0 ||
      payload_field_index >= static_cast<int32_t>(payload_fields.size())) {
    return std::nullopt;
  }
  return ChoicePayloadInfo{
      .payload_region_type_id = payload_region_type_id,
      .payload_tuple_type_id = context.types().GetTypeIdForTypeInstId(
          payload_fields[payload_field_index].type_inst_id)};
}

auto EmitChoiceDiscriminantTest(Context& context, Parse::NodeId case_node_id,
                                SemIR::InstId scrutinee_id,
                                SemIR::TypeId disc_type_id,
                                int32_t alternative_index) -> SemIR::InstId {
  auto index_value_id = ConvertToValueOfType(
      context, case_node_id,
      MakeIntLiteral(context, case_node_id,
                     context.ints().Add(alternative_index)),
      disc_type_id);

  auto disc_access_id =
      AddInst<SemIR::ClassElementAccess>(context, case_node_id,
                                         {.type_id = disc_type_id,
                                          .base_id = scrutinee_id,
                                          .index = SemIR::ElementIndex(0)});
  SemIR::InstId args[] = {context.types().GetTypeInstId(disc_type_id)};
  auto eq_id = BuildBinaryOperator(context, case_node_id,
                                   {.interface_name = CoreIdentifier::EqWith,
                                    .interface_args_ref = args,
                                    .op_name = CoreIdentifier::Equal},
                                   index_value_id, disc_access_id);
  return ConvertToBoolValue(context, case_node_id, eq_id);
}

auto MatchCaseAlternativePatternMatch(Context& context,
                                      SemIR::InstId scrutinee_id,
                                      Parse::NodeId case_node_id)
    -> SemIR::InstId {
  CARBON_CHECK(context.match_case_stack().back().alternative,
               "Alternative pattern arm without resolved alternative");
  // Copy: the payload walk below checks pattern code, which could grow the
  // case-arm stack and invalidate a reference.
  auto alternative = *context.match_case_stack().back().alternative;
  auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();
  auto disc_type_id = GetChoiceDiscriminantType(context, scrutinee_type_id);

  // An all-binding payload contributes no test of its own; a payload with
  // expression subpatterns must additionally compare the payload's values.
  bool payload_is_refutable = alternative.payload_pattern_id.has_value() &&
                              !alternative.payload_is_irrefutable;

  if (!disc_type_id) {
    // A single-alternative choice: its discriminant is the empty tuple
    // (handle_choice.cpp), so there is nothing to test (W-068) and any
    // payload conditions are the arm's whole condition — the one
    // alternative is always active, so its payload region reads are total
    // without a dominating discriminant test. The binding extraction in
    // `MatchCase`'s bind pass stays real. The scrutinee gate admits only
    // choice shapes here.
    CARBON_CHECK(IsMatchableChoiceType(context, scrutinee_type_id),
                 "Alternative pattern with non-choice scrutinee");
    if (!payload_is_refutable) {
      return MakeBoolLiteral(context, SemIR::LocId(case_node_id),
                             SemIR::BoolValue::True);
    }
    auto field_ref_id = EmitChoicePayloadFieldAccess(
        context, SemIR::LocId(case_node_id), scrutinee_id,
        alternative.payload_field_index);
    return MatchCasePatternMatch(context, alternative.payload_pattern_id,
                                 field_ref_id, case_node_id);
  }

  auto disc_cond_id = EmitChoiceDiscriminantTest(
      context, case_node_id, scrutinee_id, *disc_type_id, alternative.index);
  if (!payload_is_refutable) {
    return disc_cond_id;
  }

  // The payload's conditions are emitted in a payload block switched to
  // explicitly BEFORE the engine runs on the payload tree, so every
  // payload-region read and compare is strictly dominated by the
  // discriminant test: the payload region of a non-active alternative is
  // uninitialized storage, and a hoisted load would feed poison to a branch
  // (W-008 plan §4 R-2 — the dominance is correctness, not style). The
  // discriminant's failure edge carries `false` to the merge block, so the
  // arm's condition stays a single bool.
  CARBON_CHECK(alternative.payload_field_index >= 0,
               "Refutable payload without payload field");
  auto false_id = MakeBoolLiteral(context, SemIR::LocId(case_node_id),
                                  SemIR::BoolValue::False);
  auto payload_block_id =
      AddDominatedBlockAndBranchIf(context, case_node_id, disc_cond_id);
  auto end_block_id =
      AddDominatedBlockAndBranchWithArg(context, case_node_id, false_id);
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(end_block_id);
  context.inst_block_stack().Push(payload_block_id);
  context.region_stack().AddToRegion(payload_block_id, case_node_id);

  auto field_ref_id = EmitChoicePayloadFieldAccess(
      context, SemIR::LocId(case_node_id), scrutinee_id,
      alternative.payload_field_index);
  auto payload_cond_id = MatchCasePatternMatch(
      context, alternative.payload_pattern_id, field_ref_id, case_node_id);
  if (!payload_cond_id.has_value()) {
    // An unsupported payload shape was diagnosed with a TODO; checking
    // aborts, so the half-built block structure is abandoned with it.
    return SemIR::InstId::None;
  }
  AddInst<SemIR::BranchWithArg>(
      context, case_node_id,
      {.target_id = end_block_id, .arg_id = payload_cond_id});
  context.inst_block_stack().Pop();
  context.region_stack().AddToRegion(end_block_id, case_node_id);
  auto result_id = AddInst<SemIR::BlockArg>(
      context, case_node_id,
      {.type_id = context.insts().Get(false_id).type_id(),
       .block_id = end_block_id});
  SetBlockArgResultBeforeConstantUse(context, result_id, disc_cond_id,
                                     payload_cond_id, false_id);
  return result_id;
}

auto SpliceMatchCaseGuard(Context& context, SemIR::ExprRegionId region_id)
    -> SemIR::InstId {
  return InsertHere(context, region_id);
}

auto IsIrrefutableMatchCasePattern(Context& context, SemIR::InstId pattern_id)
    -> bool {
  // Iterative worklist (misc-no-recursion). Binding patterns are the
  // irrefutable leaves; tuples recurse; anything else — expression leaves
  // in particular, and error recovery — is refutable.
  llvm::SmallVector<SemIR::InstId> worklist = {pattern_id};
  while (!worklist.empty()) {
    auto inst_id = worklist.pop_back_val();
    if (auto tuple_pattern =
            context.insts().TryGetAs<SemIR::TuplePattern>(inst_id)) {
      llvm::append_range(worklist,
                         context.inst_blocks().Get(tuple_pattern->elements_id));
      continue;
    }
    if (!context.insts().Is<SemIR::ValueBindingPattern>(inst_id)) {
      return false;
    }
  }
  return true;
}

auto MatchCasePatternHasBindings(Context& context, SemIR::InstId pattern_id)
    -> bool {
  llvm::SmallVector<SemIR::InstId> worklist = {pattern_id};
  while (!worklist.empty()) {
    auto inst_id = worklist.pop_back_val();
    if (auto tuple_pattern =
            context.insts().TryGetAs<SemIR::TuplePattern>(inst_id)) {
      llvm::append_range(worklist,
                         context.inst_blocks().Get(tuple_pattern->elements_id));
      continue;
    }
    if (context.insts().Is<SemIR::ValueBindingPattern>(inst_id)) {
      return true;
    }
  }
  return false;
}

auto EmitChoicePayloadFieldAccess(Context& context, SemIR::LocId loc_id,
                                  SemIR::InstId scrutinee_id,
                                  int32_t payload_field_index)
    -> SemIR::InstId {
  auto payload_info =
      GetChoicePayloadInfo(context, context.insts().Get(scrutinee_id).type_id(),
                           payload_field_index);
  CARBON_CHECK(payload_info, "Payload arm without payload field");
  auto payload_ref_id = AddInst<SemIR::ClassElementAccess>(
      context, loc_id,
      {.type_id = payload_info->payload_region_type_id,
       .base_id = scrutinee_id,
       .index = SemIR::ElementIndex(1)});
  return AddInst<SemIR::ClassElementAccess>(
      context, loc_id,
      {.type_id = payload_info->payload_tuple_type_id,
       .base_id = payload_ref_id,
       .index = SemIR::ElementIndex(payload_field_index)});
}

// Folds the per-leaf conditions the test pass collected into the arm's
// single boolean condition. A `None` condition (an unsupported-shape TODO
// was diagnosed) aborts the arm, and an errored condition poisons the whole
// fold, so `MatchCase` still records the error arm. Multiple conditions
// fold as a flat `and` over already-computed bools — the short-circuit
// `BranchIf`/`block_arg` shape of the `and` operator
// (handle_operator.cpp), built after every condition was emitted eagerly
// into the entry block. This is observationally equivalent to the design's
// left-to-right short-circuit because in-slice element reads are total and
// in-slice case expressions are constants (W-008 plan §2.1(a); recorded
// approximation, re-examined when either premise falls).
static auto FoldMatchCaseConditions(Context& context, Parse::NodeId node_id,
                                    llvm::ArrayRef<SemIR::InstId> cond_ids)
    -> SemIR::InstId {
  bool has_error = false;
  for (auto cond_id : cond_ids) {
    if (!cond_id.has_value()) {
      return SemIR::InstId::None;
    }
    has_error |= cond_id == SemIR::ErrorInst::InstId;
  }
  if (has_error) {
    return SemIR::ErrorInst::InstId;
  }
  if (cond_ids.empty()) {
    // A wholly-irrefutable tree: every subtree pruned, so the arm always
    // matches — the same constant-true condition a binding arm contributes.
    return MakeBoolLiteral(context, SemIR::LocId(node_id),
                           SemIR::BoolValue::True);
  }
  auto result_id = cond_ids.front();
  for (auto cond_id : cond_ids.drop_front()) {
    auto bool_type_id = context.insts().Get(result_id).type_id();
    auto short_circuit_result_id = AddInst<SemIR::BoolLiteral>(
        context, node_id,
        {.type_id = bool_type_id, .value = SemIR::BoolValue::False});
    auto rhs_block_id =
        AddDominatedBlockAndBranchIf(context, node_id, result_id);
    auto end_block_id = AddDominatedBlockAndBranchWithArg(
        context, node_id, short_circuit_result_id);
    context.inst_block_stack().Pop();
    context.inst_block_stack().Push(end_block_id);
    context.inst_block_stack().Push(rhs_block_id);
    context.region_stack().AddToRegion(rhs_block_id, node_id);
    // The next condition is already computed in the entry block, so the
    // rhs block only forwards it.
    AddInst<SemIR::BranchWithArg>(
        context, node_id, {.target_id = end_block_id, .arg_id = cond_id});
    context.inst_block_stack().Pop();
    context.region_stack().AddToRegion(end_block_id, node_id);
    auto folded_id = AddInst<SemIR::BlockArg>(
        context, node_id, {.type_id = bool_type_id, .block_id = end_block_id});
    SetBlockArgResultBeforeConstantUse(context, folded_id, result_id, cond_id,
                                       short_circuit_result_id);
    result_id = folded_id;
  }
  return result_id;
}

// Returns the kind of conversion to perform on the scrutinee when matching the
// given pattern. Note that this returns `NoOp` for `var` patterns, because
// their conversion needs special handling, prior to any general-purpose
// conversion that would use this function.
static auto ConversionKindFor(SemIR::Inst pattern, MatchContext::WorkItem entry)
    -> ConversionTarget::Kind {
  CARBON_KIND_SWITCH(pattern) {
    case SemIR::VarParamPattern::Kind:
    case SemIR::VarPattern::Kind:
      // See function comment.
    case SemIR::OutParamPattern::Kind:
      // OutParamPattern conversion is handled by the enclosing
      // ReturnSlotPattern.
    case SemIR::WrapperBindingPattern::Kind:
      // WrapperBindingPattern conversion is handled by its subpattern.
      return ConversionTarget::NoOp;
    case SemIR::RefBindingPattern::Kind:
      return ConversionTarget::DurableRef;
    case SemIR::RefParamPattern::Kind:
      return entry.allow_unmarked_ref ? ConversionTarget::UnmarkedRefParam
                                      : ConversionTarget::RefParam;
    case SemIR::SymbolicBindingPattern::Kind:
    case SemIR::ValueBindingPattern::Kind:
    case SemIR::ValueParamPattern::Kind:
      return ConversionTarget::Value;
    default:
      CARBON_FATAL("Unexpected pattern kind in {0}", pattern);
  }
}

auto MatchContext::DoPreWork(State state,
                             SemIR::AnyBindingPattern binding_pattern,
                             SemIR::InstId scrutinee_id, WorkItem entry)
    -> void {
  if (std::holds_alternative<MatchCaseState*>(state)) {
    // The refutable test pass prunes at binding patterns: bindings are
    // irrefutable and contribute no condition, and descending into them here
    // would consume their `bind_name_map` entries, which the bind pass still
    // needs.
    return;
  }
  bool scheduled_post_work = false;
  if (!std::holds_alternative<CallerState*>(state)) {
    results_stack_.PushArray();
    AddAsPostWork(entry);
    scheduled_post_work = true;
  } else {
    CARBON_CHECK(!need_subpattern_results());
  }
  if (binding_pattern.kind == SemIR::WrapperBindingPattern::Kind) {
    AddWork({.pattern_id = binding_pattern.subpattern_id,
             .work = PreWork{.scrutinee_id = scrutinee_id},
             .allow_unmarked_ref = entry.allow_unmarked_ref});
  } else if (scheduled_post_work) {
    // PostWork expects a result to bind the name to. If we scheduled PostWork,
    // but didn't schedule PreWork for a subpattern, the name should be bound to
    // the scrutinee.
    results_stack_.AppendToTop(scrutinee_id);
  }
}

auto MatchContext::DoPostWork(State state,
                              SemIR::AnyBindingPattern binding_pattern,
                              WorkItem entry) -> void {
  CARBON_CHECK(!std::holds_alternative<CallerState*>(state));
  if (std::holds_alternative<ThunkState*>(state)) {
    // Pass through the result from the subpattern.
    return;
  }

  auto scrutinee_type_id = GetScrutineeTypeInSpecific(
      context_, entry.pattern_id, specific_id_stack_.back());
  auto value_id = PopResult();
  if (value_id.has_value()) {
    value_id = Convert(context_, SemIR::LocId(value_id), value_id,
                       {.kind = ConversionKindFor(binding_pattern, entry),
                        .type_id = scrutinee_type_id});
  } else {
    CARBON_CHECK(binding_pattern.kind == SemIR::SymbolicBindingPattern::Kind);
  }

  if (need_subpattern_results()) {
    results_stack_.AppendToTop(value_id);
  }

  if (specific_id_stack_.size() > 1) {
    // If anything has been pushed onto the specific stack, that means
    // that `binding_pattern` is a constant inst. The bindings for constant
    // insts are not precomputed (see the documentation for bind_name_map), so
    // we have to emit a new one here.
    context_.inst_block_stack().AddInstId(
        AddBindingForPattern(context_, SemIR::LocId(entry.pattern_id),
                             binding_pattern, scrutinee_type_id, value_id));
    return;
  }

  // We're logically consuming this map entry, so we invalidate it in order
  // to avoid accidentally consuming it twice.
  auto [bind_name_id, type_expr_region_id] =
      std::exchange(context_.bind_name_map().Lookup(entry.pattern_id).value(),
                    {.bind_name_id = SemIR::InstId::None,
                     .type_expr_region_id = SemIR::ExprRegionId::None});
  if (type_expr_region_id.has_value()) {
    InsertHere(context_, type_expr_region_id);
  }
  CARBON_CHECK(bind_name_id.has_value(), "bind_name_map entry used twice");

  auto bind_name = context_.insts().GetAs<SemIR::AnyBinding>(bind_name_id);
  CARBON_CHECK(!bind_name.value_id.has_value());
  bind_name.value_id = value_id;
  ReplaceInstBeforeConstantUse(context_, bind_name_id, bind_name);
  context_.inst_block_stack().AddInstId(bind_name_id);
}

// Returns the inst kind to use for the parameter corresponding to the given
// parameter pattern.
static auto ParamKindFor(SemIR::Inst param_pattern) -> SemIR::InstKind {
  CARBON_KIND_SWITCH(param_pattern) {
    case SemIR::OutParamPattern::Kind:
      return SemIR::OutParam::Kind;
    case SemIR::RefParamPattern::Kind:
    case SemIR::VarParamPattern::Kind:
      return SemIR::RefParam::Kind;
    case SemIR::ValueParamPattern::Kind:
      return SemIR::ValueParam::Kind;
    default:
      CARBON_FATAL("Unexpected param pattern kind: {0}", param_pattern);
  }
}

auto MatchContext::DoPreWork(State state, SemIR::AnyParamPattern param_pattern,
                             SemIR::InstId scrutinee_id, WorkItem entry)
    -> void {
  AddAsPostWork(entry);
  auto scrutinee_type_id = GetScrutineeTypeInSpecific(
      context_, entry.pattern_id, specific_id_stack_.back());

  // If `param_pattern` is a `VarParamPattern`, match it as a `VarPattern` here,
  // and then as a `RefParamPattern` below.
  if (param_pattern.kind == SemIR::VarParamPattern::Kind) {
    scrutinee_id =
        DoVarPreWorkImpl(state, scrutinee_type_id, scrutinee_id, entry);
    entry.allow_unmarked_ref = true;
  }

  CARBON_KIND_SWITCH(state) {
    case CARBON_KIND(CallerState* caller_state): {
      CARBON_CHECK(scrutinee_id.has_value());
      if (scrutinee_id == SemIR::ErrorInst::InstId) {
        caller_state->call_args.push_back(SemIR::ErrorInst::InstId);
      } else {
        caller_state->call_args.push_back(
            Convert(context_, SemIR::LocId(scrutinee_id), scrutinee_id,
                    {.kind = ConversionKindFor(param_pattern, entry),
                     .type_id = scrutinee_type_id}));
      }
      // Do not traverse farther or schedule PostWork, because the caller side
      // of the pattern ends here.
      break;
    }
    case CARBON_KIND(CalleeState* callee_state): {
      SemIR::Inst param =
          SemIR::AnyParam{.kind = ParamKindFor(param_pattern),
                          .type_id = scrutinee_type_id,
                          .index = callee_state->index.Allocate(),
                          .pretty_name_id = SemIR::GetPrettyNameFromPatternId(
                              context_.sem_ir(), entry.pattern_id)};
      auto loc_id = SemIR::LocId(entry.pattern_id);
      auto param_id = SemIR::InstId::None;
      // TODO: find a way to avoid this boilerplate.
      switch (param.kind()) {
        case SemIR::OutParam::Kind:
          param_id = AddInst(context_, loc_id, param.As<SemIR::OutParam>());
          break;
        case SemIR::RefParam::Kind:
          param_id = AddInst(context_, loc_id, param.As<SemIR::RefParam>());
          break;
        case SemIR::ValueParam::Kind:
          param_id = AddInst(context_, loc_id, param.As<SemIR::ValueParam>());
          break;
        default:
          CARBON_FATAL("Unexpected parameter kind");
      }
      if (auto var_param_pattern =
              context_.insts().TryGetAs<SemIR::VarParamPattern>(
                  entry.pattern_id)) {
        AddWork({.pattern_id = var_param_pattern->subpattern_id,
                 .work = PreWork{.scrutinee_id = param_id},
                 .allow_unmarked_ref = entry.allow_unmarked_ref});
      } else {
        if (need_subpattern_results()) {
          results_stack_.AppendToTop(param_id);
        }
      }

      callee_state->PushCallParamPattern(context_, loc_id, entry.pattern_id,
                                         specific_id_stack_.back());
      callee_state->call_params.push_back(param_id);
      break;
    }
    case CARBON_KIND(ThunkState* thunk_state): {
      auto param_id = thunk_state->outer_call_args.consume_front();
      if (auto var_param_pattern =
              context_.insts().TryGetAs<SemIR::VarParamPattern>(
                  entry.pattern_id)) {
        AddWork({.pattern_id = var_param_pattern->subpattern_id,
                 .work = PreWork{.scrutinee_id = param_id},
                 .allow_unmarked_ref = entry.allow_unmarked_ref});
      } else {
        results_stack_.AppendToTop(param_id);
      }
      break;
    }
    case CARBON_KIND(LocalState* _): {
      CARBON_FATAL("Found ValueParamPattern during local pattern match");
    }
    case CARBON_KIND(MatchCaseState* _): {
      CARBON_FATAL("Found ValueParamPattern during match case pattern match");
    }
  }
}

auto MatchContext::DoPostWork(State /*state*/,
                              SemIR::AnyParamPattern /*param_pattern*/,
                              WorkItem /*entry*/) -> void {
  // No-op: the subpattern's result is this pattern's result. Note that if
  // there were any post-work corresponding to DoVarPreWorkImpl, that work
  // would have to be done here.
}

auto MatchContext::DoPreWork(State state, SemIR::ExprPattern expr_pattern,
                             SemIR::InstId scrutinee_id, WorkItem entry)
    -> void {
  if (auto** match_case_state = std::get_if<MatchCaseState*>(&state)) {
    results_stack_.AppendToTop(
        DoMatchCaseExprPattern(**match_case_state, expr_pattern, scrutinee_id));
    return;
  }
  if (auto** local_state = std::get_if<LocalState*>(&state);
      local_state && (*local_state)->in_match_case_bind) {
    // The bind pass of a `match` `case` arm prunes at expression leaves:
    // the test pass owns their regions (each region splices exactly once)
    // and already emitted their conditions.
    return;
  }
  context_.TODO(entry.pattern_id, "expression pattern");
}

auto MatchContext::DoMatchCaseExprPattern(
    const MatchCaseState& match_case_state, SemIR::ExprPattern expr_pattern,
    SemIR::InstId scrutinee_id) -> SemIR::InstId {
  const auto& case_context = context_.match_case_stack().back();
  auto introducer_node_id = case_context.introducer_node_id;
  auto case_node_id = match_case_state.case_node_id;
  auto result_id = context_.sem_ir()
                       .expr_regions()
                       .Get(expr_pattern.expr_region_id)
                       .result_id;
  auto scrutinee_type_id = context_.insts().Get(scrutinee_id).type_id();

  if (IsMatchableChoiceType(context_, scrutinee_type_id)) {
    // A choice scrutinee.
    auto result_type_id = context_.insts().Get(result_id).type_id();
    if (result_type_id == SemIR::ErrorInst::TypeId) {
      // The pattern failed to check; a diagnostic was already produced.
      InsertHere(context_, expr_pattern.expr_region_id);
      return SemIR::ErrorInst::InstId;
    }
    if (result_id == case_context.designator_root_id) {
      // The whole pattern is a leading-dot designator naming a payload-free
      // alternative constant of the scrutinee's choice type, resolved against
      // the scrutinee's choice scope (see `AlternativePattern` in
      // handle_match.cpp); compare its discriminant against the scrutinee's
      // discriminant field. The discriminant value comes from the choice's
      // name-to-index metadata, resolved into the case-arm context at
      // pattern-check time.
      CARBON_CHECK(context_.types().GetUnqualifiedType(result_type_id) ==
                       context_.types().GetUnqualifiedType(scrutinee_type_id),
                   "Alternative constant type differs from scrutinee type");
      if (!case_context.alternative) {
        // An alternative without name-to-index metadata, such as in a
        // generic context, is out of slice; see decision-log W5-S1. The
        // scrutinee gate rejects those shapes already, so this is
        // defense-in-depth: diagnose rather than crash. Named for the
        // pattern, not the scrutinee: the scrutinee passed its gate, and it
        // is this case pattern's alternative that has no usable shape.
        context_.TODO(
            case_node_id,
            "match case pattern on unsupported choice alternative shape");
        return SemIR::InstId::None;
      }
      InsertHere(context_, expr_pattern.expr_region_id);
      auto disc_type_id =
          GetChoiceDiscriminantType(context_, scrutinee_type_id);
      if (!disc_type_id) {
        // A single-alternative choice has the empty-tuple discriminant —
        // nothing to test, so the arm is always taken (W-068), the same
        // constant-true condition an irrefutable binding arm contributes.
        return MakeBoolLiteral(context_, SemIR::LocId(case_node_id),
                               SemIR::BoolValue::True);
      }
      return EmitChoiceDiscriminantTest(context_, case_node_id, scrutinee_id,
                                        *disc_type_id,
                                        case_context.alternative->index);
    }
    if (context_.types().Is<SemIR::FunctionType>(result_type_id) ||
        context_.types().GetUnqualifiedType(result_type_id) ==
            context_.types().GetUnqualifiedType(scrutinee_type_id)) {
      // For example `case IntResult.Err`: only the leading-dot spelling is
      // in-slice (SF-4); the qualified form is a recorded work item.
      context_.TODO(introducer_node_id,
                    "qualified alternative pattern in match case");
      return SemIR::InstId::None;
    }
    context_.TODO(
        introducer_node_id,
        "match `case` pattern other than an integer literal, or a case guard");
    return SemIR::InstId::None;
  }

  // An integer scrutinee — the whole case pattern, or one element of a
  // tuple case pattern or alternative payload against the element's
  // scrutinee.
  if (context_.insts().Get(result_id).type_id() == SemIR::ErrorInst::TypeId) {
    // The pattern expression failed to check; a diagnostic was already
    // produced (for example a payload designator without `.Self`).
    InsertHere(context_, expr_pattern.expr_region_id);
    return SemIR::ErrorInst::InstId;
  }

  // Any case expression whose constant value is a
  // concrete `IntValue` is admitted (plan RF-4), whatever its declared type:
  // classification is by the checked expression's constant representation,
  // never its syntax, so `case -1` and `case 2 + 3` work the same way as
  // `case 5`, and a constant of an int-adapter class type is admitted too —
  // if its type is not `EqWith`-compatible with the scrutinee, the comparison
  // below produces a real missing-impl operator diagnostic. Everything else —
  // non-constant expressions, symbolic constants, and constants not
  // represented as `IntValue` — stays behind the SemanticsTodo. Note that
  // `let` bindings bind value-category results and so are not constants (see
  // `WrapperBinding` in eval_inst.cpp); a case naming one stays behind it
  // too.
  auto pattern_const_id = context_.constant_values().Get(result_id);
  if (!pattern_const_id.is_concrete() ||
      !context_.insts().Is<SemIR::IntValue>(
          context_.constant_values().GetInstId(pattern_const_id))) {
    context_.TODO(introducer_node_id,
                  "match case expression pattern that is not a constant "
                  "integer");
    return SemIR::InstId::None;
  }

  // Splice the pattern's expression into the test block, then build the arm's
  // condition — docs/design/pattern_matching.md mandates the operand order
  // for expression patterns: "The scrutinee is compared with the expression
  // using the `==` operator: _expression_ `==` _scrutinee_" — the same way as
  // the infix `==` operator: the `EqWith` interface takes a single argument
  // that is the type of the RHS operand.
  auto expr_id = InsertHere(context_, expr_pattern.expr_region_id);
  // A tuple element's expression region closes through
  // `EndExprRegionForPattern` (pattern.cpp), which performs no category
  // conversion, so an initializing element such as `2 + 3` splices an
  // initializing result here; convert it to a value so the comparison
  // consumes one. Root case expressions were already converted inside their
  // region by `FinishCasePattern` (handle_match.cpp), making this a no-op
  // for them.
  if (SemIR::IsInitializerCategory(
          SemIR::GetExprCategory(context_.sem_ir(), expr_id))) {
    expr_id = ConvertToValueExpr(context_, expr_id);
  }
  SemIR::InstId args[] = {context_.types().GetTypeInstId(scrutinee_type_id)};
  auto eq_id = BuildBinaryOperator(context_, case_node_id,
                                   {.interface_name = CoreIdentifier::EqWith,
                                    .interface_args_ref = args,
                                    .op_name = CoreIdentifier::Equal},
                                   expr_id, scrutinee_id);
  return ConvertToBoolValue(context_, case_node_id, eq_id);
}

auto MatchContext::DoPostWork(State /*state*/,
                              SemIR::ExprPattern /*expr_pattern*/,
                              WorkItem /*entry*/) -> void {}

auto MatchContext::DoPreWork(State /*state*/, SemIR::FieldDecl field_decl,
                             SemIR::InstId scrutinee_id, WorkItem /*entry*/)
    -> void {
  if (!scrutinee_id.has_value()) {
    return;
  }

  // Get the field initializer.
  auto unbound_element_type = context_.insts().GetAs<SemIR::UnboundElementType>(
      context_.types().GetTypeInstId(field_decl.type_id));
  auto element_type = context_.types().GetTypeIdForTypeInstId(
      unbound_element_type.element_type_inst_id);
  auto converted_id = ConvertToValueOfType(context_, SemIR::LocId(scrutinee_id),
                                           scrutinee_id, element_type,
                                           /*diagnose=*/true);
  if (converted_id == SemIR::ErrorInst::InstId) {
    return;
  }

  // Store the field's initializer.
  context_.fields().Get(field_decl.field_id).initializer_id = converted_id;
}

auto MatchContext::DoPreWork(State state,
                             SemIR::ReturnSlotPattern return_slot_pattern,
                             SemIR::InstId scrutinee_id, WorkItem entry)
    -> void {
  if (std::holds_alternative<CalleeState*>(state)) {
    CARBON_CHECK(!scrutinee_id.has_value());
    results_stack_.PushArray();
    AddAsPostWork(entry);
  }
  AddWork({.pattern_id = return_slot_pattern.subpattern_id,
           .work = PreWork{.scrutinee_id = scrutinee_id},
           .allow_unmarked_ref = entry.allow_unmarked_ref});
}

auto MatchContext::DoPostWork(State state,
                              SemIR::ReturnSlotPattern /*return_slot_pattern*/,
                              WorkItem entry) -> void {
  CARBON_CHECK(std::holds_alternative<CalleeState*>(state));
  auto type_id = GetScrutineeTypeInSpecific(context_, entry.pattern_id,
                                            specific_id_stack_.back());
  auto return_slot_id = AddInst<SemIR::ReturnSlot>(
      context_, SemIR::LocId(entry.pattern_id),
      {.type_id = type_id,
       .type_inst_id = context_.types().GetTypeInstId(type_id),
       .storage_id = PopResult()});
  bool already_in_lookup =
      context_.scope_stack()
          .LookupOrAddName(SemIR::NameId::ReturnSlot, return_slot_id)
          .has_value();
  CARBON_CHECK(!already_in_lookup);
  if (need_subpattern_results()) {
    results_stack_.AppendToTop(return_slot_id);
  }
}

auto MatchContext::DoPreWork(State state, SemIR::VarPattern var_pattern,
                             SemIR::InstId scrutinee_id, WorkItem entry)
    -> void {
  auto scrutinee_type_id = GetScrutineeTypeInSpecific(
      context_, entry.pattern_id, specific_id_stack_.back());
  auto new_scrutinee_id =
      DoVarPreWorkImpl(state, scrutinee_type_id, scrutinee_id, entry);
  if (need_subpattern_results()) {
    AddAsPostWork(entry);
  }
  AddWork({.pattern_id = var_pattern.subpattern_id,
           .work = PreWork{.scrutinee_id = new_scrutinee_id},
           .allow_unmarked_ref = true});
}

auto MatchContext::DoVarPreWorkImpl(State state,
                                    SemIR::TypeId scrutinee_type_id,
                                    SemIR::InstId scrutinee_id,
                                    WorkItem entry) const -> SemIR::InstId {
  CARBON_KIND_SWITCH(state) {
    case CARBON_KIND(CalleeState* _): {
      // We're emitting pattern-match IR for the callee, but we're still on
      // the caller side of the pattern, so we traverse without emitting any
      // insts.
      return scrutinee_id;
    }
    case CARBON_KIND(ThunkState* _): {
      return scrutinee_id;
    }
    case CARBON_KIND(LocalState* _): {
      // TODO: Find a more efficient way to put these insts in the global_init
      // block (or drop the distinction between the global_init block and the
      // file scope?)
      if (UseGlobalInit(context_)) {
        context_.global_init().Resume();
      }

      // In a `var`/`let` declaration, the `VarStorage` inst is created before
      // we start pattern matching.
      auto storage_id =
          context_.full_pattern_stack().GetLocalVarStorage(entry.pattern_id);
      if (scrutinee_id.has_value()) {
        auto init_id =
            InitializeExisting(context_, SemIR::LocId(entry.pattern_id),
                               storage_id, scrutinee_id, /*for_return=*/false);
        // TODO: It's a bit weird to use an `Assign` instruction to model
        // initialization. Consider adding a different instruction for this
        // purpose.
        AddInst<SemIR::Assign>(context_, SemIR::LocId(entry.pattern_id),
                               {.lhs_id = storage_id, .rhs_id = init_id});
      }

      if (UseGlobalInit(context_)) {
        context_.global_init().Suspend();
      }
      return storage_id;
    }
    case CARBON_KIND(CallerState* _): {
      // TODO: This variable's lifetime should end at the end of the call or the
      // full-expression. We don't use a temporary here, because temporaries are
      // treated as being immutable.
      PendingBlock storage_block(&context_);
      auto storage_id = storage_block.AddInstWithCleanup<SemIR::VarStorage>(
          SemIR::LocId(entry.pattern_id),
          {.type_id = scrutinee_type_id, .pattern_id = entry.pattern_id});
      auto init_result = Initialize(
          context_, SemIR::LocId(entry.pattern_id),
          // Disable broken lint that suggests a "fix" that doesn't compile.
          // NOLINTNEXTLINE(performance-move-const-arg)
          std::move(storage_id), std::move(storage_block), scrutinee_id);
      // TODO: Consider instead creating something like a `Temporary`
      // instruction that returns a reference so that constant evaluation can
      // obtain the value of the var parameter.
      AddInst<SemIR::Assign>(
          context_, SemIR::LocId(entry.pattern_id),
          {.lhs_id = init_result.storage_id, .rhs_id = init_result.init_id});
      return init_result.storage_id;
    }
    case CARBON_KIND(MatchCaseState* _): {
      // The test pass never descends past a binding-pattern root (the bind
      // pass runs as a `LocalState` match in the arm's body block instead),
      // and `var` patterns in `case` arms are gated behind a TODO at check
      // time.
      CARBON_FATAL("Found VarPattern during match case pattern match");
    }
  }
}

auto MatchContext::DoPostWork(State /*state*/,
                              SemIR::VarPattern /*var_pattern*/,
                              WorkItem /*entry*/) -> void {
  // No-op: the subpattern's result is this pattern's result.
}

auto MatchContext::DoPreWork(State state, SemIR::TuplePattern tuple_pattern,
                             SemIR::InstId scrutinee_id, WorkItem entry)
    -> void {
  if (std::holds_alternative<MatchCaseState*>(state)) {
    DoMatchCaseTuplePreWork(tuple_pattern, scrutinee_id, entry,
                            /*is_test_pass=*/true);
    return;
  }
  if (auto** local_state = std::get_if<LocalState*>(&state);
      local_state && (*local_state)->in_match_case_bind) {
    DoMatchCaseTuplePreWork(tuple_pattern, scrutinee_id, entry,
                            /*is_test_pass=*/false);
    return;
  }
  if (tuple_pattern.type_id == SemIR::ErrorInst::TypeId) {
    return;
  }
  auto subpattern_ids = context_.inst_blocks().Get(tuple_pattern.elements_id);
  if (need_subpattern_results()) {
    results_stack_.PushArray();
    AddAsPostWork(entry);
  }
  auto add_all_subscrutinees =
      [&](llvm::ArrayRef<SemIR::InstId> subscrutinee_ids) {
        for (auto [subpattern_id, subscrutinee_id] :
             llvm::reverse(llvm::zip_equal(subpattern_ids, subscrutinee_ids))) {
          AddWork({.pattern_id = subpattern_id,
                   .work = PreWork{.scrutinee_id = subscrutinee_id},
                   .allow_unmarked_ref = entry.allow_unmarked_ref});
        }
      };
  if (!scrutinee_id.has_value()) {
    CARBON_CHECK(std::holds_alternative<CalleeState*>(state) ||
                 std::holds_alternative<ThunkState*>(state));
    // If we don't have a scrutinee yet, we're still on the caller side of the
    // pattern, so the subpatterns don't have a scrutinee either.
    for (auto subpattern_id : llvm::reverse(subpattern_ids)) {
      AddWork({.pattern_id = subpattern_id,
               .work = PreWork{.scrutinee_id = SemIR::InstId::None},
               .allow_unmarked_ref = entry.allow_unmarked_ref});
    }
    return;
  }
  auto scrutinee = context_.insts().GetWithLocId(scrutinee_id);
  if (auto scrutinee_literal = scrutinee.inst.TryAs<SemIR::TupleLiteral>()) {
    auto subscrutinee_ids =
        context_.inst_blocks().Get(scrutinee_literal->elements_id);
    if (subscrutinee_ids.size() != subpattern_ids.size()) {
      CARBON_DIAGNOSTIC(TuplePatternSizeDoesntMatchLiteral, Error,
                        "tuple pattern expects {0} element{0:s}, but tuple "
                        "literal has {1}",
                        Diagnostics::IntAsSelect, Diagnostics::IntAsSelect);
      context_.emitter().Emit(entry.pattern_id,
                              TuplePatternSizeDoesntMatchLiteral,
                              subpattern_ids.size(), subscrutinee_ids.size());
      return;
    }
    add_all_subscrutinees(subscrutinee_ids);
    return;
  }

  auto tuple_type_id = GetScrutineeTypeInSpecific(context_, entry.pattern_id,
                                                  specific_id_stack_.back());
  auto converted_scrutinee_id = ConvertToValueOrRefOfType(
      context_, SemIR::LocId(entry.pattern_id), scrutinee_id, tuple_type_id);
  if (auto scrutinee_value = context_.insts().TryGetAs<SemIR::TupleValue>(
          converted_scrutinee_id)) {
    add_all_subscrutinees(
        context_.inst_blocks().Get(scrutinee_value->elements_id));
    return;
  }

  auto tuple_type = context_.types().GetAs<SemIR::TupleType>(tuple_type_id);
  auto element_type_inst_ids =
      context_.inst_blocks().Get(tuple_type.type_elements_id);
  llvm::SmallVector<SemIR::InstId> subscrutinee_ids;
  subscrutinee_ids.reserve(element_type_inst_ids.size());
  for (auto [i, element_type_id] : llvm::enumerate(
           context_.types().GetBlockAsTypeIds(element_type_inst_ids))) {
    subscrutinee_ids.push_back(
        AddInst<SemIR::TupleAccess>(context_, scrutinee.loc_id,
                                    {.type_id = element_type_id,
                                     .tuple_id = converted_scrutinee_id,
                                     .index = SemIR::ElementIndex(i)}));
  }
  add_all_subscrutinees(subscrutinee_ids);
}

auto MatchContext::DoMatchCaseTuplePreWork(SemIR::TuplePattern tuple_pattern,
                                           SemIR::InstId scrutinee_id,
                                           WorkItem entry, bool is_test_pass)
    -> void {
  auto append_test_result = [&](SemIR::InstId result_id) {
    if (is_test_pass) {
      results_stack_.AppendToTop(result_id);
    }
  };
  if (tuple_pattern.type_id == SemIR::ErrorInst::TypeId) {
    append_test_result(SemIR::ErrorInst::InstId);
    return;
  }
  auto subpattern_ids = context_.inst_blocks().Get(tuple_pattern.elements_id);
  auto scrutinee = context_.insts().GetWithLocId(scrutinee_id);
  auto scrutinee_type_id =
      context_.types().GetUnqualifiedType(scrutinee.inst.type_id());
  if (scrutinee_type_id == SemIR::ErrorInst::TypeId) {
    append_test_result(SemIR::ErrorInst::InstId);
    return;
  }
  auto tuple_type =
      context_.types().TryGetAsIfValid<SemIR::TupleType>(scrutinee_type_id);
  if (!tuple_type) {
    // A nested tuple pattern against a non-tuple element (the root shape is
    // classified before the engine runs; see `MatchCase`). A real
    // pattern-type error in the design; in-slice it stays behind the W4
    // slice gate, like the same shape at the root. The bind pass cannot get
    // here: its arm's test aborted or errored first.
    if (is_test_pass) {
      context_.TODO(
          context_.match_case_stack().back().introducer_node_id,
          "match `case` pattern other than an integer literal, or a case "
          "guard");
      results_stack_.AppendToTop(SemIR::InstId::None);
    }
    return;
  }
  auto element_type_inst_ids =
      context_.inst_blocks().Get(tuple_type->type_elements_id);
  if (subpattern_ids.size() != element_type_inst_ids.size()) {
    if (is_test_pass) {
      CARBON_DIAGNOSTIC(MatchCaseTuplePatternWrongArity, Error,
                        "tuple pattern expects {0} element{0:s}, but match "
                        "scrutinee has {1}",
                        Diagnostics::IntAsSelect, Diagnostics::IntAsSelect);
      context_.emitter().Emit(entry.pattern_id, MatchCaseTuplePatternWrongArity,
                              subpattern_ids.size(),
                              element_type_inst_ids.size());
      results_stack_.AppendToTop(SemIR::ErrorInst::InstId);
    }
    return;
  }
  // Emit the element accesses eagerly, each with the SCRUTINEE's element
  // type; the pruned subtrees — irrefutable ones in the test pass, which
  // contribute no condition, and binding-free ones in the bind pass, whose
  // regions the test pass already spliced — get none.
  llvm::SmallVector<std::pair<SemIR::InstId, SemIR::InstId>> element_work;
  for (auto [i, subpattern_id] : llvm::enumerate(subpattern_ids)) {
    bool pruned = is_test_pass
                      ? IsIrrefutableMatchCasePattern(context_, subpattern_id)
                      : !MatchCasePatternHasBindings(context_, subpattern_id);
    if (pruned) {
      continue;
    }
    auto element_type_id =
        context_.types().GetTypeIdForTypeInstId(element_type_inst_ids[i]);
    auto subscrutinee_id =
        AddInst<SemIR::TupleAccess>(context_, scrutinee.loc_id,
                                    {.type_id = element_type_id,
                                     .tuple_id = scrutinee_id,
                                     .index = SemIR::ElementIndex(i)});
    element_work.push_back({subpattern_id, subscrutinee_id});
  }
  // Add the work in reverse so the elements process left to right.
  for (auto [subpattern_id, subscrutinee_id] : llvm::reverse(element_work)) {
    AddWork({.pattern_id = subpattern_id,
             .work = PreWork{.scrutinee_id = subscrutinee_id},
             .allow_unmarked_ref = entry.allow_unmarked_ref});
  }
}

auto MatchContext::DoPostWork(State /*state*/,
                              SemIR::TuplePattern /*tuple_pattern*/,
                              WorkItem entry) -> void {
  auto elements_id = context_.inst_blocks().Add(results_stack_.PeekArray());
  results_stack_.PopArray();
  auto tuple_value_id = AddInst<SemIR::TupleValue>(
      context_, SemIR::LocId(entry.pattern_id),
      {.type_id = GetScrutineeTypeInSpecific(context_, entry.pattern_id,
                                             specific_id_stack_.back()),
       .elements_id = elements_id});
  results_stack_.AppendToTop(tuple_value_id);
}

auto MatchContext::DoPreWork(State state, SemIR::SpliceInst /*splice*/,
                             SemIR::InstId scrutinee_id, WorkItem entry)
    -> void {
  auto specific_pattern_const_id = SemIR::GetConstantValueInSpecific(
      context_.sem_ir(), specific_id_stack_.back(), entry.pattern_id);
  auto specific_pattern_id =
      context_.constant_values().GetInstId(specific_pattern_const_id);
  CARBON_KIND_SWITCH(state) {
    case CARBON_KIND(CallerState* caller_state): {
      // TODO: find a way to defer adding the bundle until we know we're
      // adding the action.
      auto args_id = context_.bundles()
                         .AddCanonical<SemIR::CallerPatternMatchAction::Args>(
                             {.pattern_id = specific_pattern_id,
                              .arg_id = scrutinee_id,
                              .callee_specific_id = specific_id_stack_.back()});
      caller_state->call_args.push_back(
          HandleAction<SemIR::CallerPatternMatchAction>(
              context_, SemIR::LocId(entry.pattern_id),
              context_.types().GetTypeInstId(GetScrutineeTypeInSpecific(
                  context_, entry.pattern_id, specific_id_stack_.back())),
              {.type_id = SemIR::InstType::TypeId, .args_id = args_id}));
      break;
    }
    case CARBON_KIND(ThunkState* _): {
      CARBON_FATAL("TODO: support thunk matching of pattern splices");
    }
    case CARBON_KIND(LocalState* _): {
      CARBON_FATAL("TODO: support local matching of pattern splices");
    }
    case CARBON_KIND(MatchCaseState* _): {
      CARBON_FATAL("TODO: support match case matching of pattern splices");
    }
    case CARBON_KIND(CalleeState* callee_state): {
      CARBON_CHECK(!scrutinee_id.has_value());
      auto result_id = HandleAction<SemIR::CalleePatternMatchAction>(
          context_, SemIR::LocId(entry.pattern_id),
          context_.types().GetTypeInstId(GetScrutineeTypeInSpecific(
              context_, entry.pattern_id, specific_id_stack_.back())),
          {.type_id = SemIR::InstType::TypeId,
           .args_id =
               context_.bundles()
                   .AddCanonical<SemIR::CalleePatternMatchAction::Args>(
                       {.pattern_id = specific_pattern_id,
                        .parent_index = callee_state->index.Allocate()})});
      callee_state->PushCallParamPattern(
          context_, SemIR::LocId(entry.pattern_id), entry.pattern_id,
          specific_id_stack_.back());
      callee_state->call_params.push_back(result_id);
      results_stack_.AppendToTop(result_id);
    }
  }
}

auto MatchContext::DoPreWork(State state,
                             SemIR::AnyReturnPattern return_pattern,
                             SemIR::InstId /*scrutinee_id*/, WorkItem entry)
    -> void {
  CARBON_CHECK(std::holds_alternative<CalleeState*>(state));
  if (need_subpattern_results()) {
    auto type_id = GetScrutineeTypeInSpecific(context_, entry.pattern_id,
                                              specific_id_stack_.back());
    SemIR::InstKind result_kind =
        return_pattern.kind == SemIR::RefReturnPattern::Kind
            ? SemIR::RefReturn::Kind
            : SemIR::ValueReturn::Kind;
    results_stack_.AppendToTop(AddInst(
        context_,
        SemIR::LocIdAndInst::RuntimeVerified(
            context_.sem_ir(), SemIR::LocId(entry.pattern_id),
            SemIR::AnyReturnPattern{.kind = result_kind, .type_id = type_id})));
  }
}

auto MatchContext::DoIndirectPreWorkImpl(State state, WorkItem entry) -> void {
  CARBON_CHECK(!std::holds_alternative<CalleeState*>(state));
  AddAsPostWork(entry);
  auto constant_id = SemIR::GetConstantValueInSpecific(
      context_.sem_ir(), specific_id_stack_.back(), entry.pattern_id);
  entry.pattern_id = context_.constant_values().GetInstId(constant_id);
  // Now that we've substituted the current specific into the underlying
  // pattern, we shouldn't try to redundantly reapply that specific while
  // matching it.
  specific_id_stack_.push_back(SemIR::SpecificId::None);
  AddWork(entry);
}

auto MatchContext::DoPreWork(State state,
                             SemIR::SpecificConstant specific_constant,
                             SemIR::InstId /*scrutinee_id*/, WorkItem entry)
    -> void {
  if (std::holds_alternative<CalleeState*>(state)) {
    // In callee pattern matching, we need to produce call parameter patterns
    // with the SpecificConstant's specific substituted into them, so we need
    // to defer substitution until that point. Instead, we treat that specific
    // as the current specific while traversing the underlying inst.
    AddAsPostWork(entry);
    entry.pattern_id = specific_constant.inst_id;
    specific_id_stack_.push_back(specific_constant.specific_id);
    AddWork(entry);
  } else {
    DoIndirectPreWorkImpl(state, entry);
  }
}

auto MatchContext::DoPostWork(State /*state*/,
                              SemIR::SpecificConstant /*specific_constant*/,
                              WorkItem /*entry*/) -> void {
  specific_id_stack_.pop_back();
}

auto MatchContext::DoPreWork(State state, SemIR::ImportRefLoaded /*import_ref*/,
                             SemIR::InstId /*scrutinee_id*/, WorkItem entry)
    -> void {
  DoIndirectPreWorkImpl(state, entry);
}

auto MatchContext::DoPostWork(State /*state*/,
                              SemIR::ImportRefLoaded /*import_ref*/,
                              WorkItem /*entry*/) -> void {
  specific_id_stack_.pop_back();
}

auto MatchContext::Dispatch(State state, WorkItem entry) -> void {
  if (entry.pattern_id == SemIR::ErrorInst::InstId) {
    if (need_subpattern_results()) {
      results_stack_.AppendToTop(SemIR::ErrorInst::InstId);
    }
    return;
  }
  auto pattern = context_.insts().Get(entry.pattern_id);
  CARBON_KIND_SWITCH(entry.work) {
    case CARBON_KIND(PreWork work): {
      // TODO: Require that `work.scrutinee_id` is valid if and only if insts
      // should be emitted, once we start emitting `Param` insts in the
      // `ParamPattern` case.
      CARBON_KIND_SWITCH(pattern) {
        case CARBON_KIND_ANY(SemIR::AnyBindingPattern, any_binding_pattern): {
          DoPreWork(state, any_binding_pattern, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND_ANY(SemIR::AnyParamPattern, any_param_pattern): {
          DoPreWork(state, any_param_pattern, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND_ANY(SemIR::AnyReturnPattern, return_pattern): {
          DoPreWork(state, return_pattern, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND(SemIR::ExprPattern expr_pattern): {
          DoPreWork(state, expr_pattern, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND(SemIR::FieldDecl field_decl): {
          DoPreWork(state, field_decl, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND(SemIR::ReturnSlotPattern return_slot_pattern): {
          DoPreWork(state, return_slot_pattern, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND(SemIR::VarPattern var_pattern): {
          DoPreWork(state, var_pattern, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND(SemIR::TuplePattern tuple_pattern): {
          DoPreWork(state, tuple_pattern, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND(SemIR::SpliceInst splice_inst): {
          DoPreWork(state, splice_inst, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND(SemIR::SpecificConstant specific_constant): {
          DoPreWork(state, specific_constant, work.scrutinee_id, entry);
          break;
        }
        case CARBON_KIND(SemIR::ImportRefLoaded import_ref): {
          DoPreWork(state, import_ref, work.scrutinee_id, entry);
          break;
        }
        default: {
          CARBON_FATAL("Inst kind not handled: {0}", pattern.kind());
        }
      }
      break;
    }
    case CARBON_KIND(PostWork _): {
      CARBON_KIND_SWITCH(pattern) {
        case CARBON_KIND_ANY(SemIR::AnyBindingPattern, any_binding_pattern): {
          DoPostWork(state, any_binding_pattern, entry);
          break;
        }
        case CARBON_KIND_ANY(SemIR::AnyParamPattern, any_param_pattern): {
          DoPostWork(state, any_param_pattern, entry);
          break;
        }
        case CARBON_KIND(SemIR::ExprPattern expr_pattern): {
          DoPostWork(state, expr_pattern, entry);
          break;
        }
        case CARBON_KIND(SemIR::ReturnSlotPattern return_slot_pattern): {
          DoPostWork(state, return_slot_pattern, entry);
          break;
        }
        case CARBON_KIND(SemIR::VarPattern var_pattern): {
          DoPostWork(state, var_pattern, entry);
          break;
        }
        case CARBON_KIND(SemIR::TuplePattern tuple_pattern): {
          DoPostWork(state, tuple_pattern, entry);
          break;
        }
        case CARBON_KIND(SemIR::SpecificConstant specific_constant): {
          DoPostWork(state, specific_constant, entry);
          break;
        }
        case CARBON_KIND(SemIR::ImportRefLoaded import_ref): {
          DoPostWork(state, import_ref, entry);
          break;
        }
        default: {
          CARBON_FATAL("Inst kind not handled: {0}", pattern.kind());
        }
      }
      break;
    }
  }
}

auto CalleePatternMatch(Context& context,
                        SemIR::InstBlockId implicit_param_patterns_id,
                        SemIR::InstBlockId param_patterns_id,
                        SemIR::InstId return_pattern_id)
    -> CalleePatternMatchResults {
  if (!return_pattern_id.has_value() && !param_patterns_id.has_value() &&
      !implicit_param_patterns_id.has_value()) {
    return {.call_param_patterns_id = SemIR::InstBlockId::None,
            .call_params_id = SemIR::InstBlockId::None,
            .param_ranges = SemIR::Function::CallParamIndexRanges::Empty};
  }

  CalleeState state = {.index = IndexSource(SemIR::CallParamIndex(0))};
  MatchContext match(context);

  // We add work to the stack in reverse so that the results will be produced
  // in the original order.
  if (implicit_param_patterns_id.has_value()) {
    for (SemIR::InstId inst_id :
         context.inst_blocks().Get(implicit_param_patterns_id)) {
      match.Match(
          &state,
          {.pattern_id = inst_id,
           .work = MatchContext::PreWork{.scrutinee_id = SemIR::InstId::None}});
    }
  }
  auto implicit_end = SemIR::CallParamIndex(state.call_params.size());

  if (param_patterns_id.has_value()) {
    for (SemIR::InstId inst_id : context.inst_blocks().Get(param_patterns_id)) {
      match.Match(
          &state,
          {.pattern_id = inst_id,
           .work = MatchContext::PreWork{.scrutinee_id = SemIR::InstId::None}});
    }
  }
  auto explicit_end = SemIR::CallParamIndex(state.call_params.size());

  if (return_pattern_id.has_value()) {
    match.Match(
        &state,
        {.pattern_id = return_pattern_id,
         .work = MatchContext::PreWork{.scrutinee_id = SemIR::InstId::None}});
  }
  auto return_end = SemIR::CallParamIndex(state.call_params.size());
  CARBON_CHECK(state.call_params.size() == state.call_param_patterns.size());

  return {.call_param_patterns_id =
              context.inst_blocks().Add(state.call_param_patterns),
          .call_params_id = context.inst_blocks().Add(state.call_params),
          .param_ranges = {implicit_end, explicit_end, return_end}};
}

auto ThunkPatternMatch(Context& context,
                       llvm::ArrayRef<SemIR::InstId> param_pattern_ids,
                       llvm::ArrayRef<SemIR::InstId> outer_call_args)
    -> ThunkPatternMatchResults {
  ThunkState state = {.outer_call_args = outer_call_args};
  MatchContext match(context);

  llvm::SmallVector<SemIR::InstId> inner_args;
  inner_args.reserve(outer_call_args.size());

  for (SemIR::InstId inst_id : param_pattern_ids) {
    inner_args.push_back(match.MatchWithResult(
        &state,
        {.pattern_id = inst_id,
         .work = MatchContext::PreWork{.scrutinee_id = SemIR::InstId::None},
         .allow_unmarked_ref = true}));
  }

  return {.syntactic_args = std::move(inner_args),
          .ignored_call_args = state.outer_call_args};
}

auto PerformAction(Context& context, SemIR::LocId /*loc_id*/,
                   SemIR::CallerPatternMatchAction action) -> SemIR::InstId {
  auto args = context.bundles().Get(action.args_id);
  CallerState state;
  MatchContext match(context, args.callee_specific_id);

  match.Match(&state,
              {.pattern_id = args.pattern_id,
               .work = MatchContext::PreWork{.scrutinee_id = args.arg_id},
               .allow_unmarked_ref = false});

  CARBON_CHECK(state.call_args.size() == 1,
               "TODO: add support for composite forms");
  return state.call_args[0];
}

auto PerformAction(Context& context, SemIR::LocId /*loc_id*/,
                   SemIR::CalleePatternMatchAction action) -> SemIR::InstId {
  auto args = context.bundles().Get(action.args_id);
  CalleeState state = {.index = IndexSource(args.parent_index)};
  MatchContext match(context);

  auto result_id = match.MatchWithResult(
      &state,
      {.pattern_id = args.pattern_id,
       .work = MatchContext::PreWork{.scrutinee_id = SemIR::InstId::None},
       .allow_unmarked_ref = true});
  CARBON_CHECK(state.index.Peek().index <= args.parent_index.index + 1,
               "TODO: add support for composite forms");
  return result_id;
}

auto CallerPatternMatch(Context& context, SemIR::SpecificId specific_id,
                        SemIR::InstId self_pattern_id,
                        SemIR::InstBlockId param_patterns_id,
                        SemIR::InstId return_pattern_id,
                        SemIR::InstId self_arg_id,
                        llvm::ArrayRef<SemIR::InstId> arg_refs,
                        SemIR::InstId return_arg_id, bool is_desugared)
    -> SemIR::InstBlockId {
  CallerState state;
  MatchContext match(context, specific_id);

  // When we have a separate `self_arg_id`, we concatenate that onto the front
  // of the arg_refs to match against the first parameter.
  llvm::ArrayRef<SemIR::InstId> self_arg_refs = {};
  if (self_arg_id.has_value()) {
    self_arg_refs = self_arg_id;
    CARBON_CHECK(self_pattern_id.has_value());
  }

  for (const auto& [arg_id, param_pattern_id] : llvm::zip_equal(
           llvm::concat<const SemIR::InstId>(self_arg_refs, arg_refs),
           context.inst_blocks().GetOrEmpty(param_patterns_id))) {
    match.Match(&state,
                {.pattern_id = param_pattern_id,
                 .work = MatchContext::PreWork{.scrutinee_id = arg_id},
                 .allow_unmarked_ref = arg_id == self_arg_id || is_desugared});
  }

  // Track the return storage, if present.
  if (return_pattern_id.has_value()) {
    // TODO: Do the match even if return_arg_id is None, so that subsequent
    // args are at the right index in the arg block.
    if (return_arg_id.has_value()) {
      match.Match(&state, {.pattern_id = return_pattern_id,
                           .work = MatchContext::PreWork{.scrutinee_id =
                                                             return_arg_id}});
    }
  } else {
    CARBON_CHECK(!return_arg_id.has_value(), "No pattern to match return arg");
  }

  return context.inst_blocks().Add(state.call_args);
}

auto LocalPatternMatch(Context& context, SemIR::InstId pattern_id,
                       SemIR::InstId scrutinee_id) -> void {
  LocalState state;
  MatchContext match(context);
  match.Match(&state,
              {.pattern_id = pattern_id,
               .work = MatchContext::PreWork{.scrutinee_id = scrutinee_id}});
}

auto MatchCasePatternMatch(Context& context, SemIR::InstId pattern_id,
                           SemIR::InstId scrutinee_id,
                           Parse::NodeId case_node_id) -> SemIR::InstId {
  MatchCaseState state = {.case_node_id = case_node_id};
  MatchContext match(context);
  auto cond_ids = match.MatchWithConditions(
      &state, {.pattern_id = pattern_id,
               .work = MatchContext::PreWork{.scrutinee_id = scrutinee_id}});
  return FoldMatchCaseConditions(context, case_node_id, cond_ids);
}

auto MatchCaseBindPatternMatch(Context& context, SemIR::InstId pattern_id,
                               SemIR::InstId scrutinee_id) -> void {
  LocalState state = {.in_match_case_bind = true};
  MatchContext match(context);
  match.Match(&state,
              {.pattern_id = pattern_id,
               .work = MatchContext::PreWork{.scrutinee_id = scrutinee_id}});
}

}  // namespace Carbon::Check
