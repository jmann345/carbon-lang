// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/parse/context.h"
#include "toolchain/parse/handle.h"

namespace Carbon::Parse {

auto HandleOnlyParenExpr(Context& context) -> void {
  auto state = context.PopState();

  // Advance past the open paren.
  auto open_paren = context.ConsumeChecked(Lex::TokenKind::OpenParen);
  context.AddLeafNode(NodeKind::ParenExprStart, open_paren);

  state.token = open_paren;
  context.PushState(state, StateKind::OnlyParenExprFinish);
  context.PushState(StateKind::Expr);
}

static auto FinishParenExpr(Context& context, const Context::State& state)
    -> void {
  context.AddNode(NodeKind::ParenExpr, context.Consume(), state.has_error);
}

auto HandleOnlyParenExprFinish(Context& context) -> void {
  auto state = context.PopState();

  if (!context.PositionIs(Lex::TokenKind::CloseParen)) {
    if (!state.has_error) {
      CARBON_DIAGNOSTIC(UnexpectedTokenInCompoundMemberAccess, Error,
                        "expected `)`");
      context.emitter().Emit(*context.position(),
                             UnexpectedTokenInCompoundMemberAccess);
      state.has_error = true;
    }

    // Recover from the invalid token.
    context.SkipTo(context.tokens().GetMatchedClosingToken(state.token));
  }

  FinishParenExpr(context, state);
}

auto HandleParenExpr(Context& context) -> void {
  auto state = context.PopState();

  // Advance past the open paren. The placeholder will be replaced at the end
  // based on whether we determine this is a tuple or parenthesized expression.
  context.AddLeafNode(NodeKind::Placeholder,
                      context.ConsumeChecked(Lex::TokenKind::OpenParen));

  if (context.PositionIs(Lex::TokenKind::CloseParen)) {
    context.PushState(state, StateKind::TupleLiteralFinish);
  } else if (context.PositionIs(Lex::TokenKind::PeriodPeriodPeriod)) {
    // A `...` element makes the parentheses a tuple literal even without a
    // comma: "if the nearest enclosing delimiters around a `...` are
    // parentheses, they will be interpreted as forming a tuple rather than as
    // grouping" (docs/design/variadics.md, "Pack expansions").
    context.PushState(state, StateKind::TupleLiteralFinish);
    context.PushState(StateKind::TupleLiteralElementFinish);
    context.PushState(StateKind::TupleLiteralElement);
  } else {
    context.PushState(state, StateKind::ParenExprFinish);
    context.PushState(StateKind::ExprAfterOpenParenFinish);
    context.PushState(StateKind::Expr);
  }
}

auto HandleExprAfterOpenParenFinish(Context& context) -> void {
  auto state = context.PopState();

  auto list_token_kind = context.ConsumeListToken(
      NodeKind::TupleLiteralComma, Lex::TokenKind::CloseParen, state.has_error);
  if (list_token_kind == Context::ListTokenKind::Close) {
    return;
  }

  // We found a comma, so switch parent state to tuple handling.
  auto finish_state = context.PopState();
  CARBON_CHECK(finish_state.kind == StateKind::ParenExprFinish,
               "Unexpected parent state, found: {0}", finish_state.kind);
  context.PushState(finish_state, StateKind::TupleLiteralFinish);

  // If the comma is not immediately followed by a close paren, push handlers
  // for the next tuple element.
  if (list_token_kind != Context::ListTokenKind::CommaClose) {
    context.PushState(StateKind::TupleLiteralElementFinish);
    context.PushState(StateKind::TupleLiteralElement);
  }
}

auto HandleTupleLiteralElementFinish(Context& context) -> void {
  auto state = context.PopState();

  if (state.has_error) {
    context.ReturnErrorOnState();
  }

  if (context.ConsumeListToken(NodeKind::TupleLiteralComma,
                               Lex::TokenKind::CloseParen, state.has_error) ==
      Context::ListTokenKind::Comma) {
    context.PushState(StateKind::TupleLiteralElementFinish);
    context.PushState(StateKind::TupleLiteralElement);
  }
}

auto HandleTupleLiteralElement(Context& context) -> void {
  context.PopState();

  // A tuple literal or call argument list element may be a pack expansion,
  // `... expression`, with the same precedence as `,`
  // (docs/design/variadics.md, "Pack expansions").
  if (context.PositionIs(Lex::TokenKind::PeriodPeriodPeriod)) {
    context.PushState(StateKind::PackExpansionExprFinish);
    context.AddLeafNode(NodeKind::PackExpansionStart, context.Consume());
  }
  context.PushState(StateKind::Expr);
}

auto HandlePackExpansionExprFinish(Context& context) -> void {
  auto state = context.PopState();

  context.AddNode(NodeKind::PackExpansionExpr, state.token, state.has_error);
  if (state.has_error) {
    context.ReturnErrorOnState();
  }
}

auto HandleParenExprFinish(Context& context) -> void {
  auto state = context.PopState();
  context.ReplacePlaceholderNode(state.subtree_start, NodeKind::ParenExprStart,
                                 state.token);
  FinishParenExpr(context, state);
}

auto HandleTupleLiteralFinish(Context& context) -> void {
  auto state = context.PopState();

  context.ReplacePlaceholderNode(state.subtree_start,
                                 NodeKind::TupleLiteralStart, state.token);
  context.AddNode(NodeKind::TupleLiteral, context.Consume(), state.has_error);
}

auto HandleCallExpr(Context& context) -> void {
  auto state = context.PopState();
  context.PushState(state, StateKind::CallExprFinish);

  context.AddNode(NodeKind::CallExprStart, context.Consume(), state.has_error);
  if (!context.PositionIs(Lex::TokenKind::CloseParen)) {
    context.PushState(StateKind::TupleLiteralElementFinish);
    context.PushState(StateKind::TupleLiteralElement);
  }
}

auto HandleCallExprFinish(Context& context) -> void {
  auto state = context.PopState();

  context.AddNode(NodeKind::CallExpr, context.Consume(), state.has_error);
}

}  // namespace Carbon::Parse
