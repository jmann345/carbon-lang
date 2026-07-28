// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <optional>

#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/pattern.h"
#include "toolchain/check/pattern_match.h"
#include "toolchain/lex/token_kind.h"
#include "toolchain/sem_ir/expr_info.h"
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
// leading-dot payload-free alternative patterns (`case .Err`), whose
// discriminant is compared against the scrutinee's `.discriminant` field.
// Against either shape, a bare `name: type` binding pattern is also
// supported: it is irrefutable, so the test pass contributes no real
// condition (the arm's condition is a constant `true`), and a bind pass in
// the arm's body block initializes the binding from the scrutinee through
// `LocalPatternMatch`, so the binding exists only where the arm has matched.
// Everything outside that subset produces a "semantics TODO" diagnostic.
//
// TODO: Support other pattern kinds (`var`/`ref` case bindings, tuple
// patterns), guards, other scrutinee types, payload destructuring in
// alternative patterns, and exhaustiveness checking without a `default` arm.
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

auto HandleParseNode(Context& context,
                     Parse::MatchCaseGuardIntroducerId node_id) -> bool {
  // Guards are a later slice (S2d). The TODO aborts checking, so the open
  // pattern context needs no unwinding.
  return context.TODO(node_id, "match case guard");
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardStartId node_id)
    -> bool {
  return context.TODO(node_id, "match case guard");
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardId node_id)
    -> bool {
  return context.TODO(node_id, "match case guard");
}

auto HandleParseNode(Context& context, Parse::MatchCaseId node_id) -> bool {
  // Finish the pattern context begun by `MatchCaseIntroducer`: a leftover
  // expression on the node stack becomes an `ExprPattern`, and the checked
  // pattern root is popped.
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
  auto pattern_id = context.node_stack().PopPattern();
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
  auto scrutinee_id = PeekScrutinee(context);

  // Classify by the checked pattern inst: expression patterns (including
  // error recovery) are matched by the refutable engine, which returns the
  // arm's condition; a binding-pattern root is irrefutable, so its test pass
  // contributes no condition and the arm's condition is a constant `true`
  // (the refutable engine prunes at binding-pattern roots, whose
  // `bind_name_map` entries belong to the bind pass below); every other
  // pattern root stays behind the W4 slice-gate TODO until payload
  // destructuring (S2c) lands. The TODO is pinned to the introducer node so
  // the preserved diagnostics keep their location.
  SemIR::InstId cond_value_id = SemIR::InstId::None;
  bool is_binding_arm =
      context.insts().Is<SemIR::ValueBindingPattern>(pattern_id);
  if (pattern_id == SemIR::ErrorInst::InstId ||
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
  if (is_binding_arm) {
    LocalPatternMatch(context, pattern_id, scrutinee_id);

    // Objects created initializing the binding live until the end of the
    // arm's scope, the same way `let` and `for` bindings defer theirs: the
    // conversion to the binding's declared type can materialize a temporary,
    // which must not be destroyed by the next statement's temporary-cleanup
    // discharge while the binding is live. `MatchHandler`'s scope cleanups
    // discharge it at arm exit instead.
    context.scope_stack().DeferCleanups();
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
  context.node_stack().Pop<Parse::NodeKind::MatchStatementStart>();

  if (!has_default) {
    // A `match` whose patterns are not exhaustive and that has no `default`
    // is an error per docs/design/pattern_matching.md, and integer expression
    // patterns are never exhaustive. Exhaustiveness checking for other
    // pattern kinds is future work.
    return context.TODO(node_id, "match statement without `default` arm");
  }

  // The instruction block stack holds one body block per case arm, plus the
  // `default` arm's body block on top; branch from all of them to a new
  // resumption block. With no case arms, the `default` body was emitted
  // directly into the enclosing block, and there is nothing to converge.
  int num_blocks = num_case_arms + 1;
  if (num_blocks >= 2) {
    AddConvergenceBlockAndPush(context, node_id, num_blocks);
  }
  return true;
}

}  // namespace Carbon::Check
