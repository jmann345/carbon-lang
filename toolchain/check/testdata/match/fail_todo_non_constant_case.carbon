// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_non_constant_case.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_non_constant_case.carbon

// --- fail_todo_runtime_var_case.carbon
library "[[@TEST_NAME]]";

// A `case` expression reading a runtime `var` has no constant value, so it
// stays behind the TODO after constant integer expression patterns (plan
// RF-4).
fn F(x: i32) {
  var y: i32 = 1;
  match (x) {
    // CHECK:STDERR: fail_todo_runtime_var_case.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case expression pattern that is not a constant integer` [SemanticsTodo]
    // CHECK:STDERR:     case y => { return; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case y => { return; }
    default => { return; }
  }
}

// --- fail_todo_let_binding_case.carbon
library "[[@TEST_NAME]]";

// A plain `let` binding binds a value-category result and is not a constant
// (see `WrapperBinding` in eval_inst.cpp), so naming one in a `case` is not
// yet a constant integer expression pattern. This pins today's behavior; it
// flips if `let` bindings gain constant values.
fn G(x: i32) {
  let k: i32 = 5;
  match (x) {
    // CHECK:STDERR: fail_todo_let_binding_case.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case expression pattern that is not a constant integer` [SemanticsTodo]
    // CHECK:STDERR:     case k => { return; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case k => { return; }
    default => { return; }
  }
}
