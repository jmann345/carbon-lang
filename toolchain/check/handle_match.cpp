// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/core_identifier.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/operator.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// A `match` statement with an integer scrutinee, integer-literal `case`
// patterns, and a `default` arm is checked as an `if`/`else if`/`else` chain:
// each `case <literal>` becomes a `<literal> == scrutinee` test with a
// conditional branch to the arm's body block, falling through to the next test
// otherwise, with the `default` body as the final `else` block and all arm
// bodies converging on a single resumption block. Everything outside that
// subset produces a "semantics TODO" diagnostic.
//
// TODO: Support other pattern kinds, guards, non-integer scrutinees, and
// exhaustiveness checking without a `default` arm. Diagnose cases that can
// never match, per docs/design/pattern_matching.md.

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

  // Only integer scrutinees are supported so far: `Core.IntLiteral`, a
  // builtin integer type, or a class type directly adapting a builtin integer
  // type, as `Int(N)` and `UInt(N)` do. Other class types whose object
  // representation is an integer type, such as `Core.Char` or user-defined
  // adapter classes, are excluded: they have their own operator semantics,
  // and admitting class-typed scrutinees here would also invalidate the
  // temporary cleanup handling below, which is trivially correct only
  // because integer values have no `destroy` functions.
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
  if (!is_int_scrutinee) {
    return context.TODO(node_id, "match on non-integer scrutinee");
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
  // Only a `case` whose pattern is a single integer literal with no guard is
  // supported so far. The parse tree is stored in postorder and the introducer
  // is a leaf node, so the pattern's first node is at the next node index; a
  // one-node pattern additionally requires the bracketing `MatchCase` node to
  // immediately follow it. Diagnosing here, before the pattern's nodes are
  // traversed, keeps unsupported pattern nodes from reaching their handlers
  // outside of a pattern-matching context.
  auto pattern_kind =
      context.parse_tree().node_kind(Parse::NodeId(node_id.index + 1));
  auto after_pattern_kind =
      context.parse_tree().node_kind(Parse::NodeId(node_id.index + 2));
  if (pattern_kind != Parse::NodeKind::IntLiteral ||
      after_pattern_kind != Parse::NodeKind::MatchCase) {
    return context.TODO(
        node_id,
        "match `case` pattern other than an integer literal, or a case guard");
  }
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context,
                     Parse::MatchCaseGuardIntroducerId node_id) -> bool {
  return context.TODO(node_id, "HandleMatchCaseGuardIntroducer");
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardStartId node_id)
    -> bool {
  return context.TODO(node_id, "HandleMatchCaseGuardStart");
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardId node_id)
    -> bool {
  return context.TODO(node_id, "HandleMatchCaseGuard");
}

auto HandleParseNode(Context& context, Parse::MatchCaseId node_id) -> bool {
  auto literal_id = context.node_stack().PopExpr();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchCaseIntroducer>();
  auto scrutinee_id = PeekScrutinee(context);

  // Build `literal == scrutinee` — docs/design/pattern_matching.md mandates
  // that operand order for expression patterns: "The scrutinee is compared
  // with the expression using the `==` operator: _expression_ `==`
  // _scrutinee_" — the same way as the infix `==` operator: the `EqWith`
  // interface takes a single argument that is the type of the RHS operand.
  auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();
  SemIR::InstId args[] = {context.types().GetTypeInstId(scrutinee_type_id)};
  auto eq_id = BuildBinaryOperator(context, node_id,
                                   {.interface_name = CoreIdentifier::EqWith,
                                    .interface_args_ref = args,
                                    .op_name = CoreIdentifier::Equal},
                                   literal_id, scrutinee_id);
  auto cond_value_id = ConvertToBoolValue(context, node_id, eq_id);

  // Create the arm's body block and the block for the next test (or the
  // `default` body), and branch to the right one.
  auto then_block_id =
      AddDominatedBlockAndBranchIf(context, node_id, cond_value_id);
  auto else_block_id = AddDominatedBlockAndBranch(context, node_id);

  // Start emitting the arm's body block.
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(then_block_id);
  context.region_stack().AddToRegion(then_block_id, node_id);

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
  context.node_stack().Push(node_id);
  context.scope_stack().PushForSameRegion(ScopeStack::CleanupScopeKind::Owned);
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
    // is an error per docs/design/pattern_matching.md, and integer-literal
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
