// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/fail_let_else_trailing_semi.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/fail_let_else_trailing_semi.carbon

// A `let`-`else` declaration ends at its block's `}`, with no `;`
// (fork/design-sprint/if-let.md, open question 1 resolved as the paper
// assumes); a stray `;` is an empty expression statement, diagnosed as
// today.

fn F(y: i32) -> i32 {
  // CHECK:STDERR: fail_let_else_trailing_semi.carbon:[[@LINE+4]]:36: error: expected expression [ExpectedExpr]
  // CHECK:STDERR:   let x: i32 = y else { return 0; };
  // CHECK:STDERR:                                    ^
  // CHECK:STDERR:
  let x: i32 = y else { return 0; };
  return x;
}

// CHECK:STDOUT: - filename: fail_let_else_trailing_semi.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'F'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'y'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
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
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'y'
// CHECK:STDOUT:   │ │ ├─LetElse 'else'
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ │ │ ├─IntLiteral '0'
// CHECK:STDOUT:   │ │ │ ├─ReturnStatement ';'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─LetElseDecl 'let'
// CHECK:STDOUT:   │ │ ╭─InvalidParse ';' has_error
// CHECK:STDOUT:   │ ├─ExprStatement ';' has_error
// CHECK:STDOUT:   │ │ ╭─ReturnStatementStart 'return'
// CHECK:STDOUT:   │ │ ├─IdentifierNameExpr 'x'
// CHECK:STDOUT:   │ ├─ReturnStatement ';'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
