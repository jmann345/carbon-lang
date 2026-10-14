// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/lower/function_context.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Lower {

// TODO: Lower pack expansions (fork VA-1).

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackElement /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackElement");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackExpansionExpr /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackExpansionExpr");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackExpansionStatement /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackExpansionStatement");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackIndex /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackIndex");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackLiteral /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackLiteral");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackValue /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackValue");
}

}  // namespace Carbon::Lower
