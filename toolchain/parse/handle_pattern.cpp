// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/parse/context.h"
#include "toolchain/parse/handle.h"

namespace Carbon::Parse {

auto HandlePattern(Context& context) -> void {
  auto state = context.PopState();
  switch (context.PositionKind()) {
    case Lex::TokenKind::OpenParen:
      context.PushStateForPattern(
          StateKind::PatternListAsTuple, state.in_var_pattern,
          state.in_unused_pattern, state.in_field_shorthand_pattern,
          state.binding_context, state.ambient_precedence);
      break;
    case Lex::TokenKind::OpenCurlyBrace:
      context.PushStateForPattern(
          StateKind::PatternListAsStruct, state.in_var_pattern,
          state.in_unused_pattern, state.in_field_shorthand_pattern,
          state.binding_context, state.ambient_precedence);
      break;
    case Lex::TokenKind::Var:
      context.PushStateForPattern(
          StateKind::VariablePattern, state.in_var_pattern,
          state.in_unused_pattern, state.in_field_shorthand_pattern,
          state.binding_context, state.ambient_precedence);
      break;
    case Lex::TokenKind::Unused:
      context.PushStateForPattern(
          StateKind::UnusedPattern, state.in_var_pattern,
          state.in_unused_pattern, state.in_field_shorthand_pattern,
          state.binding_context, state.ambient_precedence);
      break;
    case Lex::TokenKind::Template:
    case Lex::TokenKind::Generic:
    case Lex::TokenKind::Runtime:
    case Lex::TokenKind::Ref:
    // `self` is always a binding, even when its type is omitted (and so is not
    // followed by a `:`).
    case Lex::TokenKind::SelfValueIdentifier:
      context.PushStateForPattern(
          StateKind::BindingPattern, state.in_var_pattern,
          state.in_unused_pattern, state.in_field_shorthand_pattern,
          state.binding_context, state.ambient_precedence);
      break;
    default:
      if (context.PositionKind().is_word() &&
          context.PositionKind(Lookahead::NextToken)
              .is_binding_pattern_operator()) {
        context.PushStateForPattern(
            StateKind::BindingPattern, state.in_var_pattern,
            state.in_unused_pattern, state.in_field_shorthand_pattern,
            state.binding_context, state.ambient_precedence);
        break;
      }
      context.PushStateForPattern(
          StateKind::ExprPattern, state.in_var_pattern, state.in_unused_pattern,
          state.in_field_shorthand_pattern, state.binding_context,
          state.ambient_precedence);
      context.PushStateForExpr(state.ambient_precedence);
      break;
  }
}

auto PushRootPattern(Context& context, bool in_var_pattern) -> void {
  // A root `var` directly before `.Name`: the `VariablePattern` wraps the
  // alternative pattern. `HandleVariablePattern` would route the `.` to an
  // ordinary (expression) pattern, so the `var` is consumed here and the
  // `FinishVariablePattern` state it would leave behind is pushed at the
  // `var` token, which emits the wrapper node. A `var` nested in a `var`
  // keeps the ordinary route, which diagnoses `NestedVar`.
  if (!in_var_pattern && context.PositionIs(Lex::TokenKind::Var) &&
      context.PositionIs(Lex::TokenKind::Period, Lookahead::NextToken)) {
    auto var_token = context.Consume();
    context.PushState(StateKind::FinishVariablePattern, var_token);
    in_var_pattern = true;
  }
  // `.Name`, optionally followed by a parenthesized payload pattern list, is
  // a choice alternative pattern. Only the leading-dot spelling at the root
  // of the pattern is an alternative pattern (root-position-only parse
  // gating, the S2c recorded deviation (1) in decision-log's S2c landing
  // note); any other leading token parses as an ordinary pattern.
  if (context.PositionIs(Lex::TokenKind::Period) &&
      context.PositionKind(Lookahead::NextToken) ==
          Lex::TokenKind::Identifier) {
    context.PushStateForPattern(
        StateKind::MatchCaseAlternativePattern, in_var_pattern,
        /*in_unused_pattern=*/false,
        /*in_field_shorthand_pattern=*/false, BindingContext::ExplicitParam,
        PrecedenceGroup::ForTopLevelPattern());
  } else {
    context.PushStateForPattern(StateKind::Pattern, in_var_pattern,
                                /*in_unused_pattern=*/false,
                                /*in_field_shorthand_pattern=*/false,
                                BindingContext::ExplicitParam,
                                PrecedenceGroup::ForTopLevelPattern());
  }
}

auto HandleExprPattern(Context& context) -> void {
  auto state = context.PopState();

  // If we parsed an expression followed by a binding operator, we most likely
  // have a malformed attempt to introduce a binding pattern that we interpreted
  // as an expression pattern, so diagnose that here rather than diagnosing a
  // missing `;` at an outer level.
  if (context.PositionKind().is_binding_pattern_operator()) {
    if (!state.has_error) {
      CARBON_DIAGNOSTIC(ExpectedBindingName, Error,
                        "unexpected expression before {0} in binding pattern",
                        Lex::TokenKind);
      // TODO: Underline the parsed expression.
      context.emitter().Emit(*context.position(), ExpectedBindingName,
                             context.PositionKind());
      state.has_error = true;
    }
    context.Consume();
    // It'd be nice to skip the type expression here too, but we can't determine
    // the end of it.
  }

  if (state.has_error) {
    context.ReturnErrorOnState();
  }
}

}  // namespace Carbon::Parse
