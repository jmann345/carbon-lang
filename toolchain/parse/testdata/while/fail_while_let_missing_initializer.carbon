// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/while/fail_while_let_missing_initializer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/while/fail_while_let_missing_initializer.carbon

// A `while` pattern condition without its `=` initializer.

fn F(x: i32) {
  // CHECK:STDERR: fail_while_let_missing_initializer.carbon:[[@LINE+4]]:20: error: expected `=` after the pattern in a pattern condition [ExpectedPatternConditionInitializer]
  // CHECK:STDERR:   while (let n: i32) {}
  // CHECK:STDERR:                    ^
  // CHECK:STDERR:
  while (let n: i32) {}
}

// CHECK:STDOUT: - filename: fail_while_let_missing_initializer.carbon
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
// CHECK:STDOUT:   │ │   ╭─WhileConditionStart '('
// CHECK:STDOUT:   │ │   ├─PatternConditionIntroducer 'let'
// CHECK:STDOUT:   │ │   │ ╭─IdentifierNameNotBeforeSignature 'n'
// CHECK:STDOUT:   │ │   │ ├─BindingPatternTypeStart ':'
// CHECK:STDOUT:   │ │   │ ├─IntTypeLiteral 'i32'
// CHECK:STDOUT:   │ │   ├─LetBindingPattern ':'
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer ')' has_error
// CHECK:STDOUT:   │ │   ├─InvalidParse ')' has_error
// CHECK:STDOUT:   │ │ ╭─WhileCondition ')' has_error
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─WhileStatement 'while'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
