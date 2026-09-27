// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_PARSE_HANDLE_H_
#define CARBON_TOOLCHAIN_PARSE_HANDLE_H_

#include "toolchain/parse/context.h"

namespace Carbon::Parse {

// Declare handlers for each parse state.
#define CARBON_PARSE_STATE(Name) auto Handle##Name(Context& context) -> void;
#include "toolchain/parse/state.def"

// Pushes the state for the root pattern of a `let`/`var` declaration, a
// pattern condition, or a `match` `case`: a root `.Name` (optionally with a
// payload list) is a choice alternative pattern, a root `var` before `.Name`
// wraps one in a `VariablePattern`, and anything else is an ordinary pattern.
// `in_var_pattern` is true when the pattern is already inside a `var`.
auto PushRootPattern(Context& context, bool in_var_pattern) -> void;

// Starts a `let`-`else` declaration at its `else`, given the finishing state
// of the `let` or `var` declaration and its introducer node kind: re-kinds
// the introducer to `LetElseIntroducer`, adds the `LetElse` leaf, and queues
// the else block and `LetElseFinish`. The position must be at the `else`.
auto StartLetElse(Context& context, Context::State state,
                  NodeKind introducer_kind) -> void;

// Diagnoses an unparenthesized `if` expression as the initializer of a
// `let`-`else` declaration, at the current position (the `else`). Shared by
// the two places that detect the shape (`StartLetElse` and
// `HandleIfExprFinishThen`) so each line gets exactly one diagnostic.
auto DiagnoseLetElseUnparenthesizedIfExpr(Context& context) -> void;

}  // namespace Carbon::Parse

#endif  // CARBON_TOOLCHAIN_PARSE_HANDLE_H_
