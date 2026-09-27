// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/refutable_binding.h"

namespace Carbon::Check {

auto HandleParseNode(Context& context, Parse::IfConditionStartId node_id)
    -> bool {
  // Pushed so that a pattern condition's introducer can recognize an `if`
  // (and push the bindings' scope); the expression path of `IfCondition`
  // pops it.
  context.node_stack().Push(node_id);
  return true;
}

// `if (let P = e)` / `while (let P = e)` and their `var` spellings
// (W-012, fork/design-sprint/if-let.md Option A): the condition is a
// refutable pattern binding, checked on the `match` case-arm machinery
// (refutable_binding.h). The pattern is checked BEFORE its initializer, so
// the refutable context starts here with an unknown scrutinee type.
auto HandleParseNode(Context& context,
                     Parse::PatternConditionIntroducerId node_id) -> bool {
  if (context.node_stack()
          .PopAndDiscardSoloNodeIdIf<Parse::NodeKind::IfConditionStart>()) {
    // if-let: the bindings' scope, popped before the else arm (at
    // `IfStatementElse`, or at `IfStatement` without an `else`), so the
    // bindings are visible in the then-block only — mirroring case-arm
    // scoping. The `IfConditionStart` solo node is consumed here; this
    // introducer node takes its place on the stack, beneath `IfCondition`'s
    // entry, where the scope-popping handlers find it.
    context.scope_stack().PushForSameRegion(
        ScopeStack::CleanupScopeKind::Owned);
  } else {
    // while-let: the loop scope pushed at `WhileConditionStart` covers the
    // header and the body, and `WhileConditionStart` carries the loop header
    // id, so it is left for `WhileCondition`.
    CARBON_CHECK(
        context.node_stack().PeekIs(Parse::NodeKind::WhileConditionStart));
  }
  BeginRefutableBinding(context, node_id);
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context,
                     Parse::PatternConditionInitializerId node_id) -> bool {
  // The pattern is complete; its root stays on the node stack beneath this
  // solo node. The pattern's region is now closed, so the initializer checks
  // at region depth 1 (`?` is legal there), with the bindings tombstoned.
  EndRefutableBindingPattern(context);
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::IfConditionId node_id) -> bool {
  auto [cond_node_id, cond_value_id] = context.node_stack().PopExprWithNodeId();

  if (context.node_stack().PeekIs(
          Parse::NodeKind::PatternConditionInitializer)) {
    // A pattern condition. Order is load-bearing: chain check, scrutinee
    // gate, end of the initializer, test, branches, bind
    // (`CheckPatternConditionInitializer` runs through the test).
    auto result = CheckPatternConditionInitializer(context, node_id,
                                                   cond_node_id, cond_value_id);
    if (!result) {
      // A diagnostic that aborts checking was emitted.
      return false;
    }

    // Create the then block and the else block, and branch on the pattern's
    // condition, exactly as for a boolean condition.
    auto then_block_id =
        AddDominatedBlockAndBranchIf(context, node_id, result->test.cond_id);
    auto else_block_id = AddDominatedBlockAndBranch(context, node_id);

    // Start emitting the `then` block, and bind the pattern there: the
    // bindings are initialized only where the pattern matched.
    context.inst_block_stack().Pop();
    context.inst_block_stack().Push(then_block_id);
    context.region_stack().AddToRegion(then_block_id, node_id);
    EmitRefutableBindingBind(context, node_id, result->pattern_id,
                             result->scrutinee_id, result->test);
    context.full_pattern_stack().PopFullPattern();
    context.match_case_stack().pop_back();

    // The same entry as the expression path, so `IfStatementElse` and
    // `IfStatement` see one protocol; it sits above the
    // `PatternConditionIntroducer` solo node.
    context.node_stack().Push(node_id, else_block_id);
    return true;
  }

  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::IfConditionStart>();

  // Convert the condition to `bool`.
  cond_value_id = ConvertToBoolValue(context, node_id, cond_value_id);

  // Destroy any temporaries created in the condition.
  AddAndDiscardTemporaryCleanups(context);

  // Create the then block and the else block, and branch to the right one. If
  // there is no `else`, the then block will terminate with a branch to the
  // else block, which will be reused as the resumption block.
  auto then_block_id =
      AddDominatedBlockAndBranchIf(context, node_id, cond_value_id);
  auto else_block_id = AddDominatedBlockAndBranch(context, node_id);

  // Start emitting the `then` block.
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(then_block_id);
  context.region_stack().AddToRegion(then_block_id, node_id);

  context.node_stack().Push(node_id, else_block_id);
  return true;
}

// Pops the if-let bindings' scope when the `IfCondition` entry just popped
// belonged to a pattern condition (its `PatternConditionIntroducer` solo
// node is then on top of the node stack). Runs in the then block, before
// the else block is started or the branch out of the then block is added,
// so the bindings' cleanups land where the bindings are live.
static auto PopPatternConditionScope(Context& context) -> void {
  if (context.node_stack()
          .PopAndDiscardSoloNodeIdIf<
              Parse::NodeKind::PatternConditionIntroducer>()) {
    AddAndDiscardScopeCleanups(context);
    context.scope_stack().Pop(/*check_unused=*/true);
  }
}

auto HandleParseNode(Context& context, Parse::IfStatementElseId node_id)
    -> bool {
  auto else_block_id = context.node_stack().Pop<Parse::NodeKind::IfCondition>();
  PopPatternConditionScope(context);

  // Switch to emitting the `else` block.
  context.inst_block_stack().Push(else_block_id);
  context.region_stack().AddToRegion(else_block_id, node_id);

  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::IfStatementId node_id) -> bool {
  switch (auto kind = context.node_stack().PeekNodeKind()) {
    case Parse::NodeKind::IfCondition: {
      // Branch from then block to else block, and start emitting the else
      // block.
      auto else_block_id =
          context.node_stack().Pop<Parse::NodeKind::IfCondition>();
      PopPatternConditionScope(context);
      AddInst<SemIR::Branch>(context, node_id, {.target_id = else_block_id});
      context.inst_block_stack().Pop();
      context.inst_block_stack().Push(else_block_id);
      context.region_stack().AddToRegion(else_block_id, node_id);
      break;
    }

    case Parse::NodeKind::IfStatementElse: {
      // Branch from the then and else blocks to a new resumption block. A
      // pattern condition's scope was popped at `IfStatementElse`, and its
      // introducer node went with it.
      context.node_stack()
          .PopAndDiscardSoloNodeId<Parse::NodeKind::IfStatementElse>();
      AddConvergenceBlockAndPush(context, node_id, /*num_blocks=*/2);
      break;
    }

    default: {
      CARBON_FATAL("Unexpected parse node at start of `if`: {0}", kind);
    }
  }

  return true;
}

}  // namespace Carbon::Check
