// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/if/fail_if_let_missing_initializer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/if/fail_if_let_missing_initializer.carbon

// A pattern condition without its `=` initializer: diagnosed at the `)`, with
// recovery to the closing paren so the `if` statement still closes.

fn F(x: i32) {
  // CHECK:STDERR: fail_if_let_missing_initializer.carbon:[[@LINE+4]]:17: error: expected `=` after the pattern in a pattern condition [ExpectedPatternConditionInitializer]
  // CHECK:STDERR:   if (let n: i32) {}
  // CHECK:STDERR:                 ^
  // CHECK:STDERR:
  if (let n: i32) {}
}

// CHECK:STDOUT: - filename: fail_if_let_missing_initializer.carbon
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
// CHECK:STDOUT:   │ │   ├─PatternConditionInitializer ')' has_error
// CHECK:STDOUT:   │ │   ├─InvalidParse ')' has_error
// CHECK:STDOUT:   │ │ ╭─IfCondition ')' has_error
// CHECK:STDOUT:   │ │ │ ╭─CodeBlockStart '{'
// CHECK:STDOUT:   │ │ ├─CodeBlock '}'
// CHECK:STDOUT:   │ ├─IfStatement 'if'
// CHECK:STDOUT:   ├─FunctionDefinition '}'
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
