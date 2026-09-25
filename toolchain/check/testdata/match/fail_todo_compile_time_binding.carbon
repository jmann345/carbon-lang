// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_compile_time_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_compile_time_binding.carbon

// Pins the dedicated TODO string for compile-time case bindings, narrowed
// from the combined W4 slice-gate string at W8c (W-008 plan §3.3). A
// checked/template binding against a runtime match scrutinee is
// design-open (plan §1.4): nothing licenses it, and nothing forbids it, so
// the gate stays a TODO rather than a rejection.

// --- fail_todo_compile_time_binding.carbon
library "[[@TEST_NAME]]";

// A compile-time case binding reaches the `Kind::MatchCaseArm` gate in
// handle_binding_pattern.cpp's `CompileTimeBindingPattern` handler, which
// fires the dedicated TODO before the introducer-dependent local
// generic-`let` TODO could misfire for the case arm's implicit `let`.
fn G(x: i32) {
  match (x) {
    // CHECK:STDERR: fail_todo_compile_time_binding.carbon:[[@LINE+4]]:5: error: semantics TODO: `compile-time binding in match `case` pattern` [SemanticsTodo]
    // CHECK:STDERR:     case template n: i32 => { return; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case template n: i32 => { return; }
    default => { return; }
  }
}
