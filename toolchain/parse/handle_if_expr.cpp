// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/lex/token_kind.h"
#include "toolchain/parse/context.h"
#include "toolchain/parse/handle.h"

namespace Carbon::Parse {

auto HandleIfExprFinishCondition(Context& context) -> void {
  auto state = context.PopState();

  context.AddNode(NodeKind::IfExprIf, state.token, state.has_error);

  if (context.PositionIs(Lex::TokenKind::Then)) {
    context.PushState(StateKind::IfExprFinishThen);
    context.ConsumeChecked(Lex::TokenKind::Then);
    context.PushStateForExpr(*PrecedenceGroup::ForLeading(Lex::TokenKind::If));
  } else {
    // TODO: Include the location of the `if` token.
    CARBON_DIAGNOSTIC(ExpectedThenAfterIf, Error,
                      "expected `then` after `if` condition");
    if (!state.has_error) {
      context.emitter().Emit(*context.position(), ExpectedThenAfterIf);
    }
    // Add invalid nodes to substitute for `IfExprThen` and the final `Expr`.
    context.AddInvalidParse(*context.position());
    context.AddInvalidParse(*context.position());
    context.ReturnErrorOnState();
  }
}

auto HandleIfExprFinishThen(Context& context) -> void {
  auto state = context.PopState();

  context.AddNode(NodeKind::IfExprThen, state.token, state.has_error);

  // The `let`-`else` ambiguity: when this `if` expression is the whole
  // initializer of a `let`/`var` declaration and its `else` is followed by
  // a code block, the `else` belongs to a `let`-`else` declaration, and the
  // design requires the `if` expression to be parenthesized
  // (fork/design-sprint/if-let.md, the initializer restriction). Diagnose
  // that, leave the `else` unconsumed for the declaration, and return the
  // expression with an error, so the user gets one diagnostic and a sane
  // tree instead of a struct-literal error. A `{` followed by `.` or `}`
  // is a struct literal (`{.a = 1}`, `{}`), so `... else {.a = 1};` keeps
  // parsing as an if-expression; a code block cannot begin with `.`, and
  // an empty else block is an error in check anyway.
  if (context.PositionIs(Lex::TokenKind::Else) &&
      context.PositionIs(Lex::TokenKind::OpenCurlyBrace,
                         Lookahead::NextToken)) {
    auto after_brace = context.PositionKind(static_cast<Lookahead>(2));
    const auto& states = context.state_stack();
    bool is_let_initializer =
        states.size() >= 2 && states.back().kind == StateKind::IfExprFinish &&
        (states[states.size() - 2].kind == StateKind::LetFinishAsRegular ||
         states[states.size() - 2].kind == StateKind::VarFinish);
    if (is_let_initializer && after_brace != Lex::TokenKind::Period &&
        after_brace != Lex::TokenKind::CloseCurlyBrace) {
      DiagnoseLetElseUnparenthesizedIfExpr(context);
      // Add an invalid node to substitute for the final `Expr`.
      context.AddInvalidParse(*context.position());
      context.ReturnErrorOnState();
      return;
    }
  }

  if (context.PositionIs(Lex::TokenKind::Else)) {
    context.PushState(StateKind::IfExprFinishElse);
    context.ConsumeChecked(Lex::TokenKind::Else);
    context.PushStateForExpr(*PrecedenceGroup::ForLeading(Lex::TokenKind::If));
  } else {
    // TODO: Include the location of the `if` token.
    CARBON_DIAGNOSTIC(ExpectedElseAfterIf, Error,
                      "expected `else` after `if ... then ...`");
    if (!state.has_error) {
      context.emitter().Emit(*context.position(), ExpectedElseAfterIf);
    }
    // Add an invalid node to substitute for the final `Expr`.
    context.AddInvalidParse(*context.position());
    context.ReturnErrorOnState();
  }
}

auto HandleIfExprFinishElse(Context& context) -> void {
  auto else_state = context.PopState();

  // Propagate the location of `else`.
  auto if_state = context.PopState();
  if_state.token = else_state.token;
  if_state.has_error |= else_state.has_error;
  context.PushState(if_state);
}

auto HandleIfExprFinish(Context& context) -> void {
  auto state = context.PopState();

  context.AddNode(NodeKind::IfExprElse, state.token, state.has_error);
}

}  // namespace Carbon::Parse
