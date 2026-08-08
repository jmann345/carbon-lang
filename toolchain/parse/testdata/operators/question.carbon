// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/operators/question.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/operators/question.carbon

// Postfix `?` parses in the expression postfix loop (fork/b1/plan.md §2.3):
// highest (suffix) precedence, chaining left-to-right with `.`, `->`, calls,
// and indexing, and repeatable.

fn Chain(n: i32) {
  Open(n)?.Read()?.x;
}

fn MemberAfterQuestion(x: i32) {
  x?.y;
}

fn ArrowThenQuestion(x: i32) {
  x->y?;
}

fn Repeat(x: i32) {
  x??;
}

fn IndexAfterQuestion(a: i32, i: i32) {
  a?[i];
}

fn PrefixBindsOutside(x: i32) {
  -x?;
  not x?;
}

fn InfixOperands(x: i32, y: i32) {
  x? + y?;
}

fn AsOperand(x: i32) {
  x? as T;
}

// C-1 (fork/b1/plan.md §2.3): whitespace before a postfix-loop `?` is
// accepted silently — the loop's suffix components, unlike the `ExprLoop`
// operator table, perform no fixity/whitespace check.
fn WhitespaceBeforeQuestion(x: i32) {
  x ?;
}

// The `->?` and `:?` form tokens are unaffected by postfix `?`: max munch
// already lexed each as a single token, and they still parse as form
// declaration syntax, never as `->`/`:` followed by a postfix `?`.
fn FormReturn() ->? Form;
fn FormParam(x:? Form);

// CHECK:STDOUT: - filename: question.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'Chain'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │                 ╭─IdentifierNameExpr 'Open'
// CHECK:STDOUT:   │ │               ╭─CallExprStart '('
// CHECK:STDOUT:   │ │               ├─IdentifierNameExpr 'n'
// CHECK:STDOUT:   │ │             ╭─CallExpr ')'
// CHECK:STDOUT:   │ │           ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │           ├─IdentifierNameNotBeforeSignature 'Read'
// CHECK:STDOUT:   │ │         ╭─MemberAccessExpr '.'
// CHECK:STDOUT:   │ │       ╭─CallExprStart '('
// CHECK:STDOUT:   │ │     ╭─CallExpr ')'
// CHECK:STDOUT:   │ │   ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │   ├─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ ╭─MemberAccessExpr '.'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'MemberAfterQuestion'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │   ├─IdentifierNameNotBeforeSignature 'y'
// CHECK:STDOUT:   │ │ ╭─MemberAccessExpr '.'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'ArrowThenQuestion'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │     ├─IdentifierNameNotBeforeSignature 'y'
// CHECK:STDOUT:   │ │   ╭─PointerMemberAccessExpr '->'
// CHECK:STDOUT:   │ │ ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'Repeat'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │ ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'IndexAfterQuestion'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'a'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   │ ├─PatternListComma ','
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'i'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │       ╭─IdentifierNameExpr 'a'
// CHECK:STDOUT:   │ │     ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │   ╭─IndexExprStart '['
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'i'
// CHECK:STDOUT:   │ │ ╭─IndexExpr ']'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'PrefixBindsOutside'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │ ╭─PrefixOperatorMinus '-'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │ ╭─PrefixOperatorNot 'not'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'InfixOperands'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   │ ├─PatternListComma ','
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'y'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │   │ ╭─IdentifierNameExpr 'y'
// CHECK:STDOUT:   │ │   ├─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │ ╭─InfixOperatorPlus '+'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'AsOperand'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │     ╭─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │   ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ │   ├─IdentifierNameExpr 'T'
// CHECK:STDOUT:   │ │ ╭─InfixOperatorAs 'as'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'WhitespaceBeforeQuestion'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ │ ╭─PostfixOperatorQuestion '?'
// CHECK:STDOUT:   │ ├─ExprStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │ ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │ ├─IdentifierNameMaybeBeforeSignature 'FormReturn'
// CHECK:STDOUT:   │ │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │ ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ │ ╭─IdentifierNameExpr 'Form'
// CHECK:STDOUT:   │ ├─ReturnForm '->?'
// CHECK:STDOUT:   ├─FunctionDecl ';'
// CHECK:STDOUT:   │ ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │ ├─IdentifierNameMaybeBeforeSignature 'FormParam'
// CHECK:STDOUT:   │ │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':?'
// CHECK:STDOUT:   │ │ │ ├─IdentifierNameExpr 'Form'
// CHECK:STDOUT:   │ │ ├─FormBindingPattern ':?'
// CHECK:STDOUT:   │ ├─ExplicitParamList ')'
// CHECK:STDOUT:   ├─FunctionDecl ';'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
