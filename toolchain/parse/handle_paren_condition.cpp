// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <optional>

#include "toolchain/parse/context.h"
#include "toolchain/parse/handle.h"

namespace Carbon::Parse {

// Handles ParenConditionAs(If|While|Match).
static auto HandleParenCondition(Context& context, NodeKind start_kind,
                                 StateKind finish_state_kind) -> void {
  auto state = context.PopState();

  std::optional<Lex::TokenIndex> open_paren =
      context.ConsumeAndAddOpenParen(state.token, start_kind);
  if (open_paren) {
    state.token = *open_paren;
  }
  context.PushState(state, finish_state_kind);

  if (!open_paren && context.PositionIs(Lex::TokenKind::OpenCurlyBrace)) {
    // For an open curly, assume the condition was completely omitted.
    // Expression parsing would treat the { as a struct, but instead assume it's
    // a code block and just emit an invalid parse.
    context.AddInvalidParse(*context.position());
  } else if (start_kind != NodeKind::MatchConditionStart &&
             (context.PositionIs(Lex::TokenKind::Let) ||
              context.PositionIs(Lex::TokenKind::Var))) {
    // A pattern condition: `(let P = e)` / `(var P = e)`, for `if` and
    // `while` only — `match (let ...)` has no meaning and its `MatchCondition`
    // node carries no pattern prefix, so `match` falls through to the
    // expression path and diagnoses `let` as an expected expression. `let`
    // and `var` never begin an expression (`var` occurs only after `form(`),
    // so a single-token peek is unambiguous (fork/design-sprint/if-let.md,
    // "Implementation realities").
    auto introducer = context.Consume();
    context.AddLeafNode(NodeKind::PatternConditionIntroducer, introducer);
    context.PushState(StateKind::PatternConditionAfterPattern, introducer);
    PushRootPattern(context, /*in_var_pattern=*/context.tokens().GetKind(
                                 introducer) == Lex::TokenKind::Var);
  } else {
    context.PushState(StateKind::Expr);
  }
}

auto HandlePatternConditionAfterPattern(Context& context) -> void {
  auto state = context.PopState();
  if (context.tokens().GetKind(state.token) == Lex::TokenKind::Var) {
    // Mirror `var` declarations: the whole pattern is a `var` pattern.
    context.AddNode(NodeKind::VariablePattern, state.token, state.has_error);
  }
  if (state.has_error) {
    if (auto next = context.FindNextOf(
            {Lex::TokenKind::Equal, Lex::TokenKind::CloseParen})) {
      context.SkipTo(*next);
    }
  }
  if (auto equals = context.ConsumeIf(Lex::TokenKind::Equal)) {
    context.AddLeafNode(NodeKind::PatternConditionInitializer, *equals);
    context.PushState(StateKind::Expr);
  } else {
    CARBON_DIAGNOSTIC(ExpectedPatternConditionInitializer, Error,
                      "expected `=` after the pattern in a pattern condition");
    context.emitter().Emit(*context.position(),
                           ExpectedPatternConditionInitializer);
    context.AddLeafNode(NodeKind::PatternConditionInitializer,
                        *context.position(), /*has_error=*/true);
    context.AddInvalidParse(*context.position());
    context.ReturnErrorOnState();
  }
}

auto HandleParenConditionAsIf(Context& context) -> void {
  HandleParenCondition(context, NodeKind::IfConditionStart,
                       StateKind::ParenConditionFinishAsIf);
}

auto HandleParenConditionAsWhile(Context& context) -> void {
  HandleParenCondition(context, NodeKind::WhileConditionStart,
                       StateKind::ParenConditionFinishAsWhile);
}

auto HandleParenConditionAsMatch(Context& context) -> void {
  HandleParenCondition(context, NodeKind::MatchConditionStart,
                       StateKind::ParenConditionFinishAsMatch);
}

auto HandleParenConditionFinishAsIf(Context& context) -> void {
  auto state = context.PopState();

  context.ConsumeAndAddCloseSymbol(state, NodeKind::IfCondition);
}

auto HandleParenConditionFinishAsWhile(Context& context) -> void {
  auto state = context.PopState();

  context.ConsumeAndAddCloseSymbol(state, NodeKind::WhileCondition);
}

auto HandleParenConditionFinishAsMatch(Context& context) -> void {
  auto state = context.PopState();

  context.ConsumeAndAddCloseSymbol(state, NodeKind::MatchCondition);
}

}  // namespace Carbon::Parse
