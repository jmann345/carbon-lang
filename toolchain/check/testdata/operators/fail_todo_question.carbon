// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/fail_todo_question.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/fail_todo_question.carbon

// Pins the B1a gate string `postfix `?` operator` (fork/b1/plan.md §2.3/§6):
// the postfix `?` expression parses, and its check handler gates the whole
// surface — expression, statement, argument, and type positions identically —
// until B1b lands `Core.Try` and the desugar.

// --- fail_todo_expr_position.carbon
library "[[@TEST_NAME]]";

fn Expression(x: i32) -> i32 {
  // CHECK:STDERR: fail_todo_expr_position.carbon:[[@LINE+4]]:10: error: semantics TODO: `postfix `?` operator` [SemanticsTodo]
  // CHECK:STDERR:   return x? + 1;
  // CHECK:STDERR:          ^~
  // CHECK:STDERR:
  return x? + 1;
}

// --- fail_todo_statement_position.carbon
library "[[@TEST_NAME]]";

fn Statement(x: i32) {
  // CHECK:STDERR: fail_todo_statement_position.carbon:[[@LINE+4]]:3: error: semantics TODO: `postfix `?` operator` [SemanticsTodo]
  // CHECK:STDERR:   x?;
  // CHECK:STDERR:   ^~
  // CHECK:STDERR:
  x?;
}

// --- fail_todo_argument_position.carbon
library "[[@TEST_NAME]]";

fn Callee(n: i32);

fn Argument(x: i32) {
  // CHECK:STDERR: fail_todo_argument_position.carbon:[[@LINE+4]]:10: error: semantics TODO: `postfix `?` operator` [SemanticsTodo]
  // CHECK:STDERR:   Callee(x?);
  // CHECK:STDERR:          ^~
  // CHECK:STDERR:
  Callee(x?);
}

// --- fail_todo_type_position.carbon
library "[[@TEST_NAME]]";

// Type-position `?` parses as an ordinary postfix expression (fork/b1/plan.md
// §2.3, approval-gate item 7) and is gated by the same string; B1b replaces
// this with the ordinary missing-impl rejection in check.
fn TypePosition() {
  // CHECK:STDERR: fail_todo_type_position.carbon:[[@LINE+4]]:10: error: semantics TODO: `postfix `?` operator` [SemanticsTodo]
  // CHECK:STDERR:   var p: i32?;
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  var p: i32?;
}
