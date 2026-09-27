// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/var_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/var_alternative.carbon

// A root `var` before a choice alternative pattern in a `case`: the
// `VariablePattern` at the `var` token wraps the `AlternativePattern` root
// (the payload bindings are `var` bindings). Before the root-`var` peek this
// shape misparsed as a `VariablePattern` over an expression pattern.

fn F(opt: Opt) -> i32 {
  match (opt) {
    case var .Some(n: i32) => { n = n + 1; return n; }
    case var .None => { return 0; }
  }
  return -1;
}

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
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─MatchIntroducer 'match'
// CHECK:STDOUT:   │ │   │ ╭─MatchConditionStart '('
// CHECK:STDOUT:   │ │   │ ├─IdentifierNameExpr 'opt'
// CHECK:STDOUT:   │ │   ├─MatchCondition ')'
// CHECK:STDOUT:   │ │ ╭─MatchStatementStart '{'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │   ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │     │   ├─IdentifierNameNotBeforeSignature 'Some'
// CHECK:STDOUT:   │ │ │     │   │ ╭─TuplePatternStart '('
// CHECK:STDOUT:   │ │ │     │   │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │ │     │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │     │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ │     │   │ ├─VarBindingPattern ':'
// CHECK:STDOUT:   │ │ │     │   ├─ParenPattern ')'
// CHECK:STDOUT:   │ │ │     │ ╭─AlternativePattern '.'
// CHECK:STDOUT:   │ │ │     ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │   ╭─IdentifierNameExpr 'n'
// CHECK:STDOUT:   │ │ │ │   │ ╭─IdentifierNameExpr 'n'
// CHECK:STDOUT:   │ │ │ │   │ ├─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ │   ├─InfixOperatorPlus '+'
// CHECK:STDOUT:   │ │ │ │ ╭─InfixOperatorEqual '='
// CHECK:STDOUT:   │ │ │ ├─ExprStatement ';'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IdentifierNameExpr 'n'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─MatchHandler '}'
// CHECK:STDOUT:   │ │ │     ╭─MatchCaseIntroducer 'case'
// CHECK:STDOUT:   │ │ │     │   ╭─AlternativePatternStart '.'
// CHECK:STDOUT:   │ │ │     │   ├─IdentifierNameNotBeforeSignature 'None'
// CHECK:STDOUT:   │ │ │     │ ╭─AlternativePattern '.'
// CHECK:STDOUT:   │ │ │     ├─VariablePattern 'var'
// CHECK:STDOUT:   │ │ │   ╭─MatchCase '=>'
// CHECK:STDOUT:   │ │ │ ╭─MatchHandlerStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
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
