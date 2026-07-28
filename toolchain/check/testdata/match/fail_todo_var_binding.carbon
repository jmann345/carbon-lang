// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_var_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_var_binding.carbon

// `var`-mode case bindings are a recorded later slice (re-platform plan
// §3.2(c)); the TODO is pinned to the binding itself.

fn F(x: i32) {
  match (x) {
    // CHECK:STDERR: fail_todo_var_binding.carbon:[[@LINE+4]]:14: error: semantics TODO: ``var` or `ref` binding in match `case` pattern` [SemanticsTodo]
    // CHECK:STDERR:     case var a: i32 => { return; }
    // CHECK:STDERR:              ^~~~~~
    // CHECK:STDERR:
    case var a: i32 => { return; }
    default => { return; }
  }
}
