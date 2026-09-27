// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/fail_let_else_if_expr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/fail_let_else_if_expr.carbon

// An unparenthesized `if` expression initializer of a `let`-`else` is an
// error (fork/design-sprint/if-let.md, the initializer restriction). Both
// shapes get exactly one diagnostic: the `else {` shape is caught inside the
// `if` expression, which leaves the `else` for the declaration; the
// `else 2 else {` shape is caught at the declaration's `else`.

// --- fail_else_block.carbon

fn F(c: bool) -> i32 {
  // CHECK:STDERR: fail_else_block.carbon:[[@LINE+4]]:28: error: `if` expression initializer of a `let`-`else` declaration must be parenthesized [LetElseUnparenthesizedIfExpr]
  // CHECK:STDERR:   let x: i32 = if c then 1 else { return 0; }
  // CHECK:STDERR:                            ^~~~
  // CHECK:STDERR:
  let x: i32 = if c then 1 else { return 0; }
  return x;
}

// --- fail_else_operand.carbon

fn F(c: bool) -> i32 {
  // CHECK:STDERR: fail_else_operand.carbon:[[@LINE+4]]:35: error: `if` expression initializer of a `let`-`else` declaration must be parenthesized [LetElseUnparenthesizedIfExpr]
  // CHECK:STDERR:   let x: i32 = if c then 1 else 2 else { return 0; }
  // CHECK:STDERR:                                   ^~~~
  // CHECK:STDERR:
  let x: i32 = if c then 1 else 2 else { return 0; }
  return x;
}

// CHECK:STDOUT: - filename: fail_else_block.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'c'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─BoolTypeLiteral 'bool'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameExpr 'c'
// CHECK:STDOUT:   │ │ │ ╭─IfExprIf 'if'
// CHECK:STDOUT:   │ │ │ │ ╭─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ ├─IfExprThen 'then'
// CHECK:STDOUT:   │ │ │ ├─InvalidParse 'else' has_error
// CHECK:STDOUT:   │ │ ├─IfExprElse 'if' has_error
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'let'
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
// CHECK:STDOUT: - filename: fail_else_operand.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'c'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─BoolTypeLiteral 'bool'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │   │ ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   ├─ReturnType '->'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─LetElseIntroducer 'let'
// CHECK:STDOUT:   │ │ │ ╭─IdentifierNameNotBeforeSignature 'x'
// CHECK:STDOUT:   │ │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │ ├─LetInitializer '='
// CHECK:STDOUT:   │ │ │   ╭─IdentifierNameExpr 'c'
// CHECK:STDOUT:   │ │ │ ╭─IfExprIf 'if'
// CHECK:STDOUT:   │ │ │ │ ╭─IntLiteral '1'
// CHECK:STDOUT:   │ │ │ ├─IfExprThen 'then'
// CHECK:STDOUT:   │ │ │ ├─IntLiteral '2'
// CHECK:STDOUT:   │ │ ├─IfExprElse 'else'
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'let' has_error
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
