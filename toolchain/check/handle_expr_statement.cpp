// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/handle.h"
#include "toolchain/sem_ir/inst.h"

namespace Carbon::Check {

auto HandleParseNode(Context& context, Parse::ExprStatementId /*node_id*/)
    -> bool {
  DiscardExpr(context, context.node_stack().PopExpr());
  // Fork (VA-1, D-VA-6): the expression statement of a statement pack
  // expansion is the expansion's body, which lowering runs once per element.
  // The cleanups of its temporaries would be added to that body here, before
  // the expansion ends, so a temporary that needs destroying is diagnosed now.
  if (const auto& stack = context.pack_expansion_stack();
      !stack.empty() &&
      stack.back().kind == Context::PackExpansionScope::Kind::Statement &&
      context.scope_stack().cleanup_scope_depth() !=
          stack.back().cleanup_depth) {
    return context.TODO(SemIR::LocId(stack.back().start_node_id),
                        "pack expansion element that needs a cleanup");
  }
  AddAndDiscardTemporaryCleanups(context);
  return true;
}

}  // namespace Carbon::Check
