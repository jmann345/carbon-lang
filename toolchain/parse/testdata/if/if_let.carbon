// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/if/if_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/if/if_let.carbon

// Pattern conditions (W-012, fork/design-sprint/if-let.md Option A): `if (`
// followed by `let` or `var` makes the condition a refutable pattern binding.
// The prefix lives directly under `IfCondition`: a `PatternConditionIntroducer`
// leaf, the pattern (a `VariablePattern` wrapper for the `var` spelling), a
// `PatternConditionInitializer` leaf at the `=`, then the initializer
// expression where the boolean condition would be.

// --- let_binding.carbon

fn F(x: i32) {
  if (let n: i32 = x) {}
}

// --- var_binding.carbon

fn F(x: i32) {
  if (var n: i32 = x) {}
}

// --- alternative_bare.carbon

fn F(opt: Opt) {
  if (let .None = opt) {}
}

// --- alternative_payload.carbon

fn F(opt: Opt) {
  if (let .Some(n: i32) = opt) {}
}

// --- var_alternative.carbon

fn F(opt: Opt) {
  if (var .Some(n: i32) = opt) {}
}

// --- tuple.carbon

fn F(pair: (i32, i32)) {
  if (let (0, n: i32) = pair) {}
}

// --- else_if_chain.carbon

fn F(pair: (i32, i32)) {
  if (let (0, n: i32) = pair) {
  } else if (let (n: i32, 0) = pair) {
  } else {
  }
}

// --- nested_in_match_arm.carbon

fn F(opt: Opt, x: i32) {
  match (x) {
    case 0 => {
      if (let .Some(n: i32) = opt) {}
    }
    default => {}
  }
}

// --- parenthesized_and.carbon

fn F(x: bool, y: bool) {
  if (let b: bool = (x and y)) {}
}

// CHECK:STDOUT: - filename: let_binding.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │   │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─IfStatement 'if'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: var_binding.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'var'
// CHECK:STDOUT:   │ │   │   ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │   ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │   ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   │ ╭─VarBindingPattern ':'
// CHECK:STDOUT:   │ │   ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─IfStatement 'if'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: alternative_bare.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'opt'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'Opt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │   │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │   │ ├─IdentifierNameNotBeforeSignature 'None'
// CHECK:STDOUT:   │ │   ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─IfStatement 'if'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: alternative_payload.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'opt'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'Opt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │   │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │   │ ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │   │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │   │ │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │   │ ├─ParenPattern ')'
// CHECK:STDOUT:   │ │   ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─IfStatement 'if'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: var_alternative.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'opt'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'Opt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'var'
// CHECK:STDOUT:   │ │   │   ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │   │   ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │   │   │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │   │   │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   │   │ ├─VarBindingPattern ':'
// CHECK:STDOUT:   │ │   │   ├─ParenPattern ')'
// CHECK:STDOUT:   │ │   │ ╭─AlternativePattern '.'
// CHECK:STDOUT:   │ │   ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─IfStatement 'if'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: tuple.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'pair'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ │ ╭─TupleLiteralStart '('
// CHECK:STDOUT:   │   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ │ │ ├─TupleLiteralComma ','
// CHECK:STDOUT:   │   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ │ ├─TupleLiteral ')'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │   │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │   │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │   │ ├─PatternListComma ','
// CHECK:STDOUT:   │ │   │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │   ├─TuplePattern ')'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'pair'
// CHECK:STDOUT:   │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─IfStatement 'if'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: else_if_chain.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'pair'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ │ ╭─TupleLiteralStart '('
// CHECK:STDOUT:   │   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ │ │ ├─TupleLiteralComma ','
// CHECK:STDOUT:   │   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ │ ├─TupleLiteral ')'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │   │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │   │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │   │ ├─PatternListComma ','
// CHECK:STDOUT:   │ │   │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │   ├─TuplePattern ')'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'pair'
// CHECK:STDOUT:   │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ │ ├─IfStatementElse 'else'
// CHECK:STDOUT:   │ │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │ │   │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │   │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │ │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │   │ ├─PatternListComma ','
// CHECK:STDOUT:   │ │ │   │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │   ├─TuplePattern ')'
// CHECK:STDOUT:   │ │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │ │   ├─IdentifierNameExpr 'pair'
// CHECK:STDOUT:   │ │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ │ │ ├─IfStatementElse 'else'
// CHECK:STDOUT:   │ │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ │ ├─IfStatement 'if'
// CHECK:STDOUT:   │ ├─IfStatement 'if'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: nested_in_match_arm.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'opt'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IdentifierNameExpr 'Opt'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   │ ├─PatternListComma ','
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─MatchIntroducer 'match'
// CHECK:STDOUT:   │ │   │ ╭─MatchConditionStart '('
// CHECK:STDOUT:   │ │   │ ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   ├─MatchCondition ')'
// CHECK:STDOUT:   │ │ ╭─MatchStatementStart '{'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │ │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │ │ │   │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │ │   │ ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │ │ │   │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │ │   │ │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │ │ │   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ │   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │ │   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │ │   │ ├─ParenPattern ')'
// CHECK:STDOUT:   │ │ │ │   ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │ │ │   ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │ │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ │ │ ├─IfStatement 'if'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ │ │     ╭─MatchDefaultIntroducer 'default'
// CHECK:STDOUT:   │ │ │   ╭─MatchDefault '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ ├─MatchStatement '}'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: parenthesized_and.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─BoolTypeLiteral 'bool'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   │ ├─PatternListComma ','
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'y'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─BoolTypeLiteral 'bool'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IfConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │   │ ╭─IdentifierNameNotBeforeSignature 'b'
// CHECK:STDOUT:   │ │   │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │ ├─BoolTypeLiteral 'bool'
// CHECK:STDOUT:   │ │   ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer '='
// CHECK:STDOUT:   │ │   │ ╭─ParenExprStart '('
// CHECK:STDOUT:   │ │   │ │   ╭─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   │ │ ╭─ShortCircuitOperandAnd 'and'
// CHECK:STDOUT:   │ │   │ │ ├─IdentifierNameExpr 'y'
// CHECK:STDOUT:   │ │   │ ├─ShortCircuitOperatorAnd 'and'
// CHECK:STDOUT:   │ │   ├─ParenExpr ')'
// CHECK:STDOUT:   │ │ ╭─IfCondition ')'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─IfStatement 'if'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
