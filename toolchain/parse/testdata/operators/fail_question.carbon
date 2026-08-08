// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/operators/fail_question.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/operators/fail_question.carbon

// `?` with nothing to its left never reaches the postfix loop: primary
// expression parsing still diagnoses "expected expression" (fork/b1/plan.md
// §2.3).
fn BareQuestion() {
  // CHECK:STDERR: fail_question.carbon:[[@LINE+4]]:3: error: expected expression [ExpectedExpr]
  // CHECK:STDERR:   ?;
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  ?;
}

// A `?` as the right operand of an infix operator likewise has no complete
// suffix expression to its left.
fn NoOperandAfterInfix(n: i32) {
  // CHECK:STDERR: fail_question.carbon:[[@LINE+8]]:7: error: expected expression [ExpectedExpr]
  // CHECK:STDERR:   n + ?;
  // CHECK:STDERR:       ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_question.carbon:[[@LINE+4]]:7: error: expected `;` after expression statement [ExpectedExprSemi]
  // CHECK:STDERR:   n + ?;
  // CHECK:STDERR:       ^
  // CHECK:STDERR:
  n + ?;
}

// The C-2 pin (fork/b1/plan.md §2.3): `i32*?` is a hard parse error. After
// the postfix `*` binds through `ExprLoop` at `TypePostfix` precedence,
// control never re-enters the expression postfix loop, and `?` is not in the
// trailing-operator table.
fn StarThenQuestion() {
  // CHECK:STDERR: fail_question.carbon:[[@LINE+4]]:7: error: expected `;` after expression statement [ExpectedExprSemi]
  // CHECK:STDERR:   i32*?;
  // CHECK:STDERR:       ^
  // CHECK:STDERR:
  i32*?;
}

// CHECK:STDOUT: - filename: fail_question.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'BareQuestion'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │ ╭─InvalidParse '?' has_error
// CHECK:STDOUT:   │ ├─ExprStatement ';' has_error
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'NoOperandAfterInfix'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   │ │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │   │ │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │   │ │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │   │ ├─LetBindingPattern ':'
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IdentifierNameExpr 'n'
// CHECK:STDOUT:   │ │   ├─InvalidParse '?' has_error
// CHECK:STDOUT:   │ │ ╭─InfixOperatorPlus '+' has_error
// CHECK:STDOUT:   │ ├─ExprStatement ';' has_error
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   │   ╭─FunctionIntroducer 'fn'
// CHECK:STDOUT:   │   ├─IdentifierNameMaybeBeforeSignature 'StarThenQuestion'
// CHECK:STDOUT:   │   │ ╭─ExplicitParamListStart '('
// CHECK:STDOUT:   │   ├─ExplicitParamList ')'
// CHECK:STDOUT:   │ ╭─FunctionDefinitionStart '{'
// CHECK:STDOUT:   │ │   ╭─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │ ╭─PostfixOperatorStar '*'
// CHECK:STDOUT:   │ ├─ExprStatement ';' has_error
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
