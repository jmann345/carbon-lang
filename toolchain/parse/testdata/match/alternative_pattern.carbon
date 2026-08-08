// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/alternative_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/alternative_pattern.carbon

// Choice alternative patterns at the root of a `case`: bare `.Name`, a
// single-subpattern payload list, a multi-subpattern payload list (with and
// without a trailing comma), and empty parentheses for a zero-payload
// function-like alternative. A leading-dot pattern is only an alternative
// pattern at the case root; `.Err` inside parentheses stays an ordinary
// (expression) pattern.
fn F(x: i32) -> i32 {
  match (x) {
    case .Err => { return 0; }
    case .Ok(value: i32) => { return 1; }
    case .Pair(a: i32, b: i32) => { return 2; }
    case .Single(a: i32,) => { return 3; }
    case .On() => { return 4; }
    case (.Err) => { return 5; }
    default => { return 6; }
  }
  return -1;
}

// CHECK:STDOUT: - filename: alternative_pattern.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─MatchIntroducer 'match'
// CHECK:STDOUT:   │ │   │ ╭─MatchConditionStart '('
// CHECK:STDOUT:   │ │   │ ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   ├─MatchCondition ')'
// CHECK:STDOUT:   │ │ ╭─MatchStatementStart '{'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │     │ ├─IdentifierNameNotBeforeSignature 'Err'
// CHECK:STDOUT:   │ │ │     ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │     │ ├─IdentifierNameNotBeforeSignature 'Ok'
// CHECK:STDOUT:   │ │ │     │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │     │ │ │ ╭─IdentifierNameNotBeforeSignature 'value'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │     │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │     │ ├─ParenPattern ')'
// CHECK:STDOUT:   │ │ │     ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │     │ ├─IdentifierNameNotBeforeSignature 'Pair'
// CHECK:STDOUT:   │ │ │     │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │     │ │ │ ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │     │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │     │ │ ├─PatternListComma ','
// CHECK:STDOUT:   │ │ │     │ │ │ ╭─IdentifierNameNotBeforeSignature 'b'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │     │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │     │ ├─TuplePattern ')'
// CHECK:STDOUT:   │ │ │     ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '2'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │     │ ├─IdentifierNameNotBeforeSignature 'Single'
// CHECK:STDOUT:   │ │ │     │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │     │ │ │ ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │     │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │     │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ │     │ │ ├─PatternListComma ','
// CHECK:STDOUT:   │ │ │     │ ├─TuplePattern ')'
// CHECK:STDOUT:   │ │ │     ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '3'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │ ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │     │ ├─IdentifierNameNotBeforeSignature 'On'
// CHECK:STDOUT:   │ │ │     │ │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │     │ ├─TuplePattern ')'
// CHECK:STDOUT:   │ │ │     ├─AlternativePattern '.'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '4'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │     │ │ ╭─IdentifierNameNotBeforeSignature 'Err'
// CHECK:STDOUT:   │ │ │     │ ├─DesignatorExpr '.'
// CHECK:STDOUT:   │ │ │     ├─ParenPattern ')'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '5'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ │ │     ╭─MatchDefaultIntroducer 'default'
// CHECK:STDOUT:   │ │ │   ╭─MatchDefault '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '6'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ ├─MatchStatement '}'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ ╭─IntLiteral '1'
// CHECK:STDOUT:   │ │ ├─PrefixOperatorMinus '-'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
