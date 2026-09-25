// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_binding_free_var.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_binding_free_var.carbon

// A binding-free `var` case pattern stays behind the W4 slice gate (W-008
// plan §2.4): there is nothing to bind, so the on-demand storage design has
// no lane for it. Pinned to the arm's `case` token, the combined-string
// site in handle_let_and_var.cpp.

fn F(x: i32) {
  match (x) {
    // CHECK:STDERR: fail_todo_binding_free_var.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case var 5 => { return; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case var 5 => { return; }
    default => { return; }
  }
}
