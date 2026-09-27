// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/refutable_binding.h"

#include <optional>

#include "llvm/ADT/SmallVector.h"
#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/member_access.h"
#include "toolchain/check/pattern.h"
#include "toolchain/check/pattern_match.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/diagnostics/format_providers.h"
#include "toolchain/lex/token_kind.h"
#include "toolchain/parse/node_kind.h"
#include "toolchain/sem_ir/expr_info.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

auto BeginRefutableBinding(Context& context, Parse::NodeId introducer_node_id)
    -> void {
  // Begin an implicit `let` declaration context for the pattern, mirroring
  // the `for` loop's driving sequence (handle_loop_statement.cpp):
  // binding-pattern checking reads the innermost introducer state before
  // dispatching on the full-pattern kind, and in statement position the
  // introducer stack is otherwise empty. Both spellings push `Let`: the
  // `var` spelling's pattern is a `VariablePattern` node, which is what
  // makes it `var`.
  context.decl_introducer_state_stack().Push<Lex::TokenKind::Let>();
  context.pattern_block_stack().Push();
  context.full_pattern_stack().PushMatchCaseArm();
  BeginExprRegionForPattern(context);

  // Record the refutable context: the scrutinee's type, unknown until the
  // form's initializer is checked (`match` fills it right away), and the
  // introducer node, which the engine's slice-gate diagnostics are pinned
  // to.
  context.match_case_stack().push_back(
      {.scrutinee_type_id = SemIR::TypeId::None,
       .introducer_node_id = introducer_node_id});
}

auto EndRefutablePatternRegion(Context& context) -> void {
  // A root expression such as `2 + 3` is an initializing expression: its
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
}

auto EndRefutableBindingPattern(Context& context) -> void {
  EndRefutablePatternRegion(context);
  // The bindings must not be used within the initializer: tombstone them
  // until the form's close handler ends the initializer.
  context.full_pattern_stack().StartPatternInitializer();
}

auto IsSupportedScrutineeType(Context& context, SemIR::TypeId type_id) -> bool {
  llvm::SmallVector<SemIR::TypeId> worklist = {type_id};
  while (!worklist.empty()) {
    auto current_type_id = worklist.pop_back_val();
    bool is_int_scrutinee = false;
    if (context.types().TryGetIntTypeInfo(current_type_id)) {
      auto unqualified_type_id =
          context.types().GetUnqualifiedType(current_type_id);
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
    // A bool scrutinee is exactly the unqualified `SemIR::BoolType`
    // singleton (`const bool` rides along, matching the int gate's
    // qualifier handling above). Strict by design: a class adapting `bool`
    // stays behind the scrutinee TODO, as int adapters beyond
    // `Int(N)`/`UInt(N)` do, and no scrutinee-position conversion to bool
    // is performed — `match` dispatches on the scrutinee's own type.
    bool is_bool_scrutinee = context.types().Is<SemIR::BoolType>(
        context.types().GetUnqualifiedType(current_type_id));
    if (is_int_scrutinee || is_bool_scrutinee ||
        IsMatchableChoiceType(context, current_type_id)) {
      continue;
    }
    auto unqualified_type_id =
        context.types().GetUnqualifiedType(current_type_id);
    if (auto tuple_type = context.types().TryGetAsIfValid<SemIR::TupleType>(
            unqualified_type_id)) {
      for (auto element_type_id : context.types().GetBlockAsTypeIds(
               context.inst_blocks().Get(tuple_type->type_elements_id))) {
        worklist.push_back(element_type_id);
      }
      continue;
    }
    if (auto struct_type = context.types().TryGetAsIfValid<SemIR::StructType>(
            unqualified_type_id)) {
      for (const auto& field :
           context.struct_type_fields().Get(struct_type->fields_id)) {
        worklist.push_back(
            context.types().GetTypeIdForTypeInstId(field.type_inst_id));
      }
      continue;
    }
    return false;
  }
  return true;
}

auto CheckRefutableScrutinee(Context& context, Parse::NodeId node_id,
                             SemIR::InstId scrutinee_id,
                             llvm::StringLiteral todo_string) -> SemIR::InstId {
  // Convert the scrutinee to a value or reference expression so that we can
  // use it multiple times, once per test.
  scrutinee_id = ConvertToValueOrRefExpr(context, scrutinee_id);

  // Five scrutinee shapes are supported so far.
  //
  // Integer scrutinees: `Core.IntLiteral`, a builtin integer type, or a class
  // type directly adapting a builtin integer type, as `Int(N)` and `UInt(N)`
  // do. Other class types whose object representation is an integer type,
  // such as `Core.Char` or user-defined adapter classes, are excluded: they
  // have their own operator semantics.
  //
  // Bool scrutinees: plain `bool` only — the design treats `bool` like a
  // choice type whose alternatives are `false` and `true`
  // (docs/design/pattern_matching.md), so its two values are a closed
  // domain for exhaustiveness. Classes adapting `bool` are excluded the
  // same way int adapters beyond `Int(N)`/`UInt(N)` are.
  //
  // Choice scrutinees: with two or more alternatives, dispatch compares the
  // alternative's index against the integer `.discriminant` field; with
  // fewer than two, the discriminant is the empty tuple and there is nothing
  // to test (W-068) — a single-alternative arm is always taken, and an empty
  // choice is vacuously exhaustive.
  //
  // Tuple and struct scrutinees: tuples and structs of the above,
  // recursively and mixed — dispatch is elementwise/fieldwise
  // (`IsSupportedScrutineeType`). The temporary
  // cleanup handling below stays trivially correct for every shape as a type
  // property, not a syntactic one: integer and bool values have no `destroy`
  // functions, an in-slice choice's payloads are restricted to trivially
  // copyable and destructible types when the choice's representation is
  // completed (see handle_choice.cpp), so its destruction is a no-op, and a
  // tuple or struct of such members destroys trivially too.
  auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();

  // Force the scrutinee's type complete before the shape checks below read
  // its object representation. For a specific of a generic choice this
  // resolves the specific's definition (the completer's `ClassType` case runs
  // `ResolveSpecificDefinition`), so the repr — and with it the payload
  // restriction above — is established by the match itself no matter which
  // path produced the scrutinee value; a pointer dereference or an import,
  // for example, completes nothing on the way in. A symbolic scrutinee type
  // defers the requirement to monomorphization (a `require_complete_type`
  // witness), and an already-complete concrete type is a no-op, keeping the
  // pre-existing scrutinee shapes on byte-identical paths.
  if (!RequireCompleteType(
          context, scrutinee_type_id, SemIR::LocId(node_id),
          [&](auto& builder) {
            CARBON_DIAGNOSTIC(IncompleteTypeInMatchScrutinee, Context,
                              "matching on value of incomplete type {0}",
                              TypeOfInstId);
            builder.Context(scrutinee_id, IncompleteTypeInMatchScrutinee,
                            scrutinee_id);
          })) {
    // The incomplete-type error was diagnosed above; abort checking the
    // form, the same way the scrutinee-shape TODO below does.
    return SemIR::InstId::None;
  }

  if (!IsSupportedScrutineeType(context, scrutinee_type_id)) {
    context.TODO(node_id, todo_string.str());
    return SemIR::InstId::None;
  }

  // Destroy any temporaries created in the scrutinee expression.
  AddAndDiscardTemporaryCleanups(context);

  return scrutinee_id;
}

auto ResolvePendingAlternative(Context& context, Parse::NodeId node_id,
                               SemIR::TypeId scrutinee_type_id,
                               SemIR::NameId name_id, bool has_parens,
                               int subpattern_count) -> ResolvedAlternative {
  ResolvedAlternative result;

  // Only a choice scrutinee resolves leading-dot case patterns in its scope;
  // on any other scrutinee such a pattern keeps the W4 slice-gate TODO,
  // pinned to the introducer node.
  if (!IsMatchableChoiceType(context, scrutinee_type_id)) {
    context.TODO(context.match_case_stack().back().introducer_node_id,
                 "match `case` pattern other than an integer "
                 "literal, or a case guard");
    result.aborted = true;
    return result;
  }

  result.lookup = LookupChoiceAlternative(context, scrutinee_type_id, name_id);
  if (!result.lookup) {
    // An unknown name: the caller emits the standard member-access
    // diagnostic.
    return result;
  }
  if (!result.lookup->has_parameters) {
    // A constant alternative.
    if (has_parens) {
      CARBON_DIAGNOSTIC(MatchAlternativeUnexpectedParens, Error,
                        "alternative `{0}` is declared without a parameter "
                        "list, so its pattern cannot have parentheses",
                        SemIR::NameId);
      context.emitter().Emit(node_id, MatchAlternativeUnexpectedParens,
                             name_id);
      return result;
    }
    result.alternative =
        Context::MatchCaseContext::Alternative{.index = result.lookup->index};
    return result;
  }

  // A payload alternative: parentheses are required, per the
  // parens-iff-parameter-list rule.
  if (!has_parens) {
    CARBON_DIAGNOSTIC(MatchAlternativeMissingParens, Error,
                      "alternative `{0}` is declared with a parameter list, "
                      "so its pattern requires parentheses",
                      SemIR::NameId);
    context.emitter().Emit(node_id, MatchAlternativeMissingParens, name_id);
    return result;
  }

  // The pattern must reproduce the alternative's parameter list, one
  // subpattern per declared parameter.
  int param_count = 0;
  if (result.lookup->payload_field_index >= 0) {
    auto payload_info = GetChoicePayloadInfo(
        context, scrutinee_type_id, result.lookup->payload_field_index);
    CARBON_CHECK(payload_info, "Payload alternative without payload field");
    param_count = context.inst_blocks()
                      .Get(context.types()
                               .GetAs<SemIR::TupleType>(
                                   payload_info->payload_tuple_type_id)
                               .type_elements_id)
                      .size();
  }
  if (subpattern_count >= 0 && subpattern_count != param_count) {
    CARBON_DIAGNOSTIC(MatchAlternativeArgCountMismatch, Error,
                      "alternative pattern has {0} subpattern{0:s}, but "
                      "alternative `{1}` is declared with {2} parameter{2:s}",
                      Diagnostics::IntAsSelect, SemIR::NameId,
                      Diagnostics::IntAsSelect);
    context.emitter().Emit(node_id, MatchAlternativeArgCountMismatch,
                           subpattern_count, name_id, param_count);
    return result;
  }

  result.alternative = Context::MatchCaseContext::Alternative{
      .index = result.lookup->index,
      .payload_field_index = result.lookup->payload_field_index};
  return result;
}

// Resolves the case context's pending alternative (a root `.Name` checked
// before its scrutinee) against the scrutinee's type, filling the context's
// `alternative` on success. Returns false when resolution diagnosed an
// error (the form's condition is then `ErrorInst`), and sets `aborted`
// after a TODO.
static auto ResolveDeferredAlternative(Context& context,
                                       SemIR::InstId scrutinee_id,
                                       bool* aborted) -> bool {
  auto pending = *context.match_case_stack().back().pending_alternative;
  context.match_case_stack().back().pending_alternative.reset();
  auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();
  // The root is always the synthesized payload `TuplePattern` (empty for the
  // bare `.Name` spelling), so the subpattern count is its element count.
  int subpattern_count =
      context.inst_blocks()
          .Get(context.insts()
                   .GetAs<SemIR::TuplePattern>(pending.root_id)
                   .elements_id)
          .size();
  auto resolved = ResolvePendingAlternative(
      context, pending.node_id, scrutinee_type_id, pending.name_id,
      pending.has_parens, subpattern_count);
  if (resolved.aborted) {
    *aborted = true;
    return false;
  }
  if (!resolved.lookup) {
    // An unknown alternative name: the standard member-access diagnostic,
    // emitted into the current block — no pattern region is open here, and
    // the result is unused.
    auto scrutinee_type_inst_id = context.types().GetTypeInstId(
        context.types().GetUnqualifiedType(scrutinee_type_id));
    PerformMemberAccess(context, pending.node_id, scrutinee_type_inst_id,
                        pending.name_id);
    return false;
  }
  if (!resolved.alternative) {
    return false;
  }
  // For the bare spelling too: the empty synthetic root is the payload
  // root, so the alternative-payload lane tests the discriminant alone and
  // the bind pass finds no bindings.
  resolved.alternative->payload_pattern_id = pending.root_id;
  resolved.alternative->payload_is_irrefutable = pending.payload_is_irrefutable;
  context.match_case_stack().back().alternative = *resolved.alternative;
  return true;
}

auto EmitRefutableBindingTest(Context& context, Parse::NodeId node_id,
                              SemIR::InstId pattern_id,
                              SemIR::InstId scrutinee_id, bool warn_irrefutable)
    -> std::optional<RefutableBindingTest> {
  auto introducer_node_id =
      context.match_case_stack().back().introducer_node_id;

  // Deferred alternative resolution: a pattern condition's or `let`-`else`'s
  // root `.Name` is resolved now that the scrutinee is known. `match`
  // resolved at pattern time and records nothing here.
  bool resolution_failed = false;
  if (context.match_case_stack().back().pending_alternative) {
    bool aborted = false;
    resolution_failed =
        !ResolveDeferredAlternative(context, scrutinee_id, &aborted);
    if (aborted) {
      return std::nullopt;
    }
  }

  // Attach the finished pattern block to a `NameBindingDecl` in the test
  // block, the same SemIR home `let` and `var` give their patterns.
  auto pattern_block_id = context.pattern_block_stack().Pop();
  AddInst<SemIR::NameBindingDecl>(context, node_id,
                                  {.pattern_block_id = pattern_block_id});

  // Copy: `match` pops the case context before its bind pass reads the
  // resolved alternative.
  auto alternative = context.match_case_stack().back().alternative;

  RefutableBindingTest test = {.cond_id = SemIR::InstId::None,
                               .alternative = alternative};
  if (resolution_failed) {
    // The root alternative pattern did not resolve (diagnosed above): the
    // condition is an error, no lane is classified, and the bind pass has
    // nothing sound to bind.
    test.cond_id = SemIR::ErrorInst::InstId;
    return test;
  }

  // Classify by the checked pattern inst: a parenthesized alternative
  // pattern's root (recorded in the case context) tests the scrutinee's
  // discriminant plus any payload-value conditions, and its payload
  // bindings bind below; a `var` root wrapping that payload root (the
  // var-alternative lane, decision R29a) is tested through the alternative
  // the same way and bound through the payload field ref with on-demand
  // storage — it is classified BEFORE `is_irrefutable_var_arm`, which
  // excludes it, or an all-binding `var .Some(n: i32)` would fold to a
  // constant `true` and never test the discriminant; other expression
  // patterns (including error recovery) and tuple- or struct-pattern roots
  // against a matching-shaped scrutinee are matched by the refutable
  // engine, which returns the arm's condition — a struct root runs the
  // engine whether refutable or not, so its field-set shape checks (unknown
  // fields, unmentioned fields without `_`) run at the root even for
  // all-binding patterns; a binding-pattern root — a value or `ref` binding
  // — is irrefutable, so its test pass contributes no condition and the
  // arm's condition is a constant `true` (the refutable engine prunes at
  // binding patterns, whose `bind_name_map` entries belong to the bind pass
  // below); a `var` root wrapping a wholly irrefutable subtree also runs the
  // refutable engine — its bindings all prune, so a shape-valid arm's
  // condition folds to the same constant `true`, while the engine's
  // scrutinee-typed tuple walk supplies the shape checks a bare tuple root
  // gets: a non-tuple scrutinee stays behind the W4 slice gate and an arity
  // mismatch diagnoses `MatchCaseTuplePatternWrongArity` (W8b fix round 1);
  // every other pattern root — a tuple or struct pattern against a
  // scrutinee of the other shape, and a `var` root wrapping a refutable
  // subtree or any struct pattern, included — stays behind the W4
  // slice-gate TODO. The TODO is pinned to the introducer node so the
  // preserved diagnostics keep their location.
  auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();
  test.is_binding_arm =
      context.insts().Is<SemIR::ValueBindingPattern>(pattern_id) ||
      context.insts().Is<SemIR::RefBindingPattern>(pattern_id);
  test.is_var_alternative_arm =
      context.insts().Is<SemIR::VarPattern>(pattern_id) && alternative &&
      alternative->payload_pattern_id.has_value() &&
      alternative->payload_pattern_id ==
          context.insts().GetAs<SemIR::VarPattern>(pattern_id).subpattern_id;
  test.is_irrefutable_var_arm =
      context.insts().Is<SemIR::VarPattern>(pattern_id) &&
      !test.is_var_alternative_arm &&
      IsIrrefutableMatchCasePattern(context, pattern_id);
  test.is_alternative_payload_arm =
      alternative && alternative->payload_pattern_id.has_value() &&
      alternative->payload_pattern_id == pattern_id;
  test.is_tuple_arm =
      context.insts().Is<SemIR::TuplePattern>(pattern_id) &&
      context.types().Is<SemIR::TupleType>(
          context.types().GetUnqualifiedType(scrutinee_type_id));
  test.is_irrefutable_tuple_arm =
      test.is_tuple_arm && IsIrrefutableMatchCasePattern(context, pattern_id);
  test.is_struct_arm =
      context.insts().Is<SemIR::StructPattern>(pattern_id) &&
      context.types().Is<SemIR::StructType>(
          context.types().GetUnqualifiedType(scrutinee_type_id));
  test.is_irrefutable_struct_arm =
      test.is_struct_arm && IsIrrefutableMatchCasePattern(context, pattern_id);
  if (test.is_alternative_payload_arm || test.is_var_alternative_arm) {
    test.cond_id =
        MatchCaseAlternativePatternMatch(context, scrutinee_id, node_id);
    if (!test.cond_id.has_value()) {
      // The engine diagnosed an unsupported payload shape with a TODO,
      // which aborts checking.
      return std::nullopt;
    }
  } else if (pattern_id == SemIR::ErrorInst::InstId ||
             context.insts().Is<SemIR::ExprPattern>(pattern_id) ||
             test.is_tuple_arm || test.is_struct_arm ||
             test.is_irrefutable_var_arm) {
    test.cond_id =
        MatchCasePatternMatch(context, pattern_id, scrutinee_id, node_id);
    if (!test.cond_id.has_value()) {
      // The engine diagnosed an unsupported case-pattern shape with a TODO,
      // which aborts checking.
      return std::nullopt;
    }
  } else if (test.is_binding_arm) {
    test.cond_id = MakeBoolLiteral(context, node_id, SemIR::BoolValue::True);
  } else {
    context.TODO(
        introducer_node_id,
        "match `case` pattern other than an integer literal, or a case guard");
    return std::nullopt;
  }

  // The warn predicate (fork/w012/plan.md §1.10), for a sound pattern only:
  // an alternative root cannot fail exactly when its choice has a single
  // alternative (no discriminant to test) and its payload is irrefutable —
  // the constant-`true` test above — and any other root cannot fail when
  // the engine classifies it irrefutable. Kept separate from the flags
  // `match` feeds into `has_irrefutable_arm`.
  if (pattern_id != SemIR::ErrorInst::InstId &&
      test.cond_id != SemIR::ErrorInst::InstId) {
    if (test.is_alternative_payload_arm || test.is_var_alternative_arm) {
      test.is_irrefutable =
          !GetChoiceDiscriminantType(context, scrutinee_type_id).has_value() &&
          alternative->payload_is_irrefutable;
    } else {
      test.is_irrefutable = IsIrrefutableMatchCasePattern(context, pattern_id);
    }
  }
  if (warn_irrefutable && test.is_irrefutable) {
    CARBON_DIAGNOSTIC(IrrefutablePatternAlwaysMatches, Warning,
                      "pattern always matches, so this binding cannot fail");
    context.emitter().Emit(introducer_node_id, IrrefutablePatternAlwaysMatches);
  }

  return test;
}

auto EmitRefutableBindingBind(Context& context, Parse::NodeId node_id,
                              SemIR::InstId pattern_id,
                              SemIR::InstId scrutinee_id,
                              const RefutableBindingTest& test) -> void {
  // Initialize the pattern's bindings from the scrutinee in the success
  // block, where they are reachable only when the pattern has matched. This
  // runs the irrefutable `LocalState` machinery, the same way `let`
  // initializes its bindings.
  //
  // For every shape, objects created initializing the bindings live until
  // the end of the owning scope, the same way `let` and `for` bindings
  // defer theirs: the conversion to a binding's declared type can
  // materialize a temporary, which must not be destroyed by the next
  // statement's temporary-cleanup discharge while the binding is live. The
  // owning scope's cleanups discharge it at scope exit instead.
  const auto& alternative = test.alternative;
  bool has_sound_cond = test.cond_id != SemIR::ErrorInst::InstId;
  if (test.is_binding_arm) {
    LocalPatternMatch(context, pattern_id, scrutinee_id);
    context.scope_stack().DeferCleanups();
  } else if (test.is_irrefutable_var_arm && has_sound_cond) {
    // A `var` root's storage is emitted by the bind pass on demand, here in
    // the success block, so each arm gets its own object — `var` case
    // bindings are not aliased across arms
    // (docs/design/pattern_matching.md, "Pattern match control flow") —
    // initialized from the scrutinee where the arm has matched and
    // destroyed with the owning scope's cleanups. The match-bind walk is
    // required, not plain `LocalPatternMatch`: the frame-indexed storage
    // lookup the `let`/`var` path uses is unusable in a refutable context
    // (W-008 plan §2.4). An arm whose test errored (for example a
    // tuple-arity mismatch under the `var`) has nothing sound to bind.
    MatchCaseBindPatternMatch(context, pattern_id, scrutinee_id);
    context.scope_stack().DeferCleanups();
  } else if (test.is_alternative_payload_arm && has_sound_cond &&
             alternative->payload_field_index >= 0 &&
             MatchCasePatternHasBindings(context, pattern_id)) {
    // Extract this alternative's payload tuple from the scrutinee's payload
    // region — field 1 of the choice's object representation, with every
    // alternative's payload tuple overlapping at offset zero (the F-007k
    // storage contract) — and initialize the payload bindings from its
    // elements through the tuple-pattern machinery. This re-extraction of a
    // trivially copyable payload in the success block is dominated by the
    // discriminant test, so the read is safe. A binding-free payload
    // (`case .Ok(42)`) has no bind-pass work, so nothing is extracted. An
    // arm whose test errored (for example an errored payload element) has
    // nothing sound to bind.
    auto field_ref_id = EmitChoicePayloadFieldAccess(
        context, SemIR::LocId(node_id), scrutinee_id,
        alternative->payload_field_index);
    // All-binding, `var`-free, struct-free payload trees keep the landed
    // `LocalPatternMatch` path; trees with expression subpatterns need the
    // match-bind pruning, trees with `var` patterns need its on-demand
    // storage (the frame-indexed lookup is unusable here; W-008 plan §2.4),
    // and trees with struct subpatterns need the match-bind walk too: a
    // struct subpattern in payload position makes the payload irrefutable,
    // and running it under plain `LocalState` would both attempt the
    // impossible conversion to the pattern's subset type and hit the
    // struct pre-work's non-match fatal (W-077 plan §1.8). Rerouted, the
    // bind pass reaches the struct walk's non-struct-element W4 TODO.
    if (alternative->payload_is_irrefutable &&
        !MatchCasePatternHasVarPattern(context, pattern_id) &&
        !MatchCasePatternHasStructPattern(context, pattern_id)) {
      LocalPatternMatch(context, pattern_id, field_ref_id);
    } else {
      MatchCaseBindPatternMatch(context, pattern_id, field_ref_id);
    }
    context.scope_stack().DeferCleanups();
  } else if (test.is_var_alternative_arm && has_sound_cond &&
             alternative->payload_field_index >= 0 &&
             MatchCasePatternHasBindings(context, pattern_id)) {
    // The var-alternative lane (decision R29a): the payload tuple is
    // extracted exactly as above, and the match-bind walk meets the
    // `VarPattern` root first, emitting one on-demand storage of the
    // payload tuple's type, initialized from the field ref and destructured
    // elementwise into the payload's bindings — the `case var (a: i32,
    // b: i32)` shape over a payload. The payload of a binding-free
    // `var .None` never reaches here: the `VariablePattern` handler gates
    // it at pattern time.
    auto field_ref_id = EmitChoicePayloadFieldAccess(
        context, SemIR::LocId(node_id), scrutinee_id,
        alternative->payload_field_index);
    MatchCaseBindPatternMatch(context, pattern_id, field_ref_id);
    context.scope_stack().DeferCleanups();
  } else if (test.is_tuple_arm && has_sound_cond &&
             MatchCasePatternHasBindings(context, pattern_id)) {
    // A tuple arm's bindings initialize elementwise from the scrutinee. An
    // arm whose test errored (for example a tuple-arity mismatch) has
    // nothing sound to bind. A tree with `var` elements takes the
    // match-bind walk for its on-demand storage even when wholly
    // irrefutable (W-008 plan §2.4), and a tree with a struct SUBPATTERN
    // takes it too: the `LocalPatternMatch` path converts the scrutinee to
    // the PATTERN's tuple type, and a field-subset struct element makes
    // that conversion structurally impossible (W-077 plan §1.4).
    if (test.is_irrefutable_tuple_arm &&
        !MatchCasePatternHasVarPattern(context, pattern_id) &&
        !MatchCasePatternHasStructPattern(context, pattern_id)) {
      LocalPatternMatch(context, pattern_id, scrutinee_id);
    } else {
      MatchCaseBindPatternMatch(context, pattern_id, scrutinee_id);
    }
    context.scope_stack().DeferCleanups();
  } else if (test.is_struct_arm && has_sound_cond &&
             MatchCasePatternHasBindings(context, pattern_id)) {
    // A struct arm's bindings initialize fieldwise from the scrutinee,
    // ALWAYS through the match-bind walk, never plain `LocalPatternMatch`:
    // that path converts the scrutinee to the PATTERN's own struct type,
    // and a field-subset pattern's type drops scrutinee fields, so
    // `ConvertStructToStructOrClass` would diagnose the
    // design-contradicting unexpected-field error instead of implementing
    // the discard rule (W-077 plan §1.4). An arm whose test errored (for
    // example a missing-fields shape error) has nothing sound to bind.
    MatchCaseBindPatternMatch(context, pattern_id, scrutinee_id);
    context.scope_stack().DeferCleanups();
  }
}

auto CheckPatternConditionInitializer(Context& context, Parse::NodeId node_id,
                                      Parse::NodeId init_node_id,
                                      SemIR::InstId init_id)
    -> std::optional<PatternConditionResult> {
  // `and`/`or` at the top level of the initializer is reserved for pattern
  // chaining (fork/design-sprint/if-let.md, "Not in 0.1"): the grammar keeps
  // `)` right after the initializer so let-chains can be added later. No
  // precedence group excludes only `and`/`or`, so the parse node kind is
  // inspected; the parenthesized `(e and c)` is a `ParenExpr` root and
  // passes. Diagnose and continue with the value.
  auto init_node_kind = context.parse_tree().node_kind(init_node_id);
  if (init_node_kind == Parse::NodeKind::ShortCircuitOperatorAnd ||
      init_node_kind == Parse::NodeKind::ShortCircuitOperatorOr) {
    CARBON_DIAGNOSTIC(PatternConditionChainReserved, Error,
                      "`and`/`or` at the top level of a pattern condition's "
                      "initializer is reserved for pattern chaining; "
                      "parenthesize the expression");
    context.emitter().Emit(init_node_id, PatternConditionChainReserved);
  }

  // The scrutinee diagnostics point at the initializer expression.
  auto scrutinee_id = CheckRefutableScrutinee(context, init_node_id, init_id,
                                              RefutableBindingScrutineeTodo);
  if (!scrutinee_id.has_value()) {
    return std::nullopt;
  }

  // The initializer is complete: lift the tombstones BEFORE the bind pass,
  // whose own name resolution would otherwise hit them. Then pop the
  // initializer's solo node and the pattern root, exactly once — the root
  // `EndRefutableBindingPattern` left on the node stack. The
  // `PatternConditionIntroducer` solo node stays for the caller.
  context.full_pattern_stack().EndPatternInitializer();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::PatternConditionInitializer>();
  auto pattern_id = context.node_stack().PopPattern();

  auto test = EmitRefutableBindingTest(context, node_id, pattern_id,
                                       scrutinee_id, /*warn_irrefutable=*/true);
  if (!test) {
    return std::nullopt;
  }
  // Nothing in the bind pass reads the introducer state: the on-demand
  // storage passes `is_returned_var=false`.
  context.decl_introducer_state_stack().Pop<Lex::TokenKind::Let>();

  return PatternConditionResult{
      .pattern_id = pattern_id, .scrutinee_id = scrutinee_id, .test = *test};
}

}  // namespace Carbon::Check
