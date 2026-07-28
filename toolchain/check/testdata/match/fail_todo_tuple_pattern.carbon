// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_tuple_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_tuple_pattern.carbon

// Pins the combined W4 slice-gate TODO string, which since S2b has no other
// testdata home: a non-binding, non-expression pattern root (a tuple
// pattern) and a compile-time case binding both stay behind it, pinned to
// the arm's `case` token.

// --- fail_todo_tuple_case.carbon
library "[[@TEST_NAME]]";

// A tuple pattern in a `case` checks to a `TuplePattern` root, which stays
// behind the W4 slice gate at handle_match.cpp's non-binding-root fallback
// (destructuring is a later slice, S2c).
fn F(x: i32) {
  match (x) {
    // CHECK:STDERR: fail_todo_tuple_case.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case (1, 2) => { return; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, 2) => { return; }
    default => { return; }
  }
}

// --- fail_todo_compile_time_binding.carbon
library "[[@TEST_NAME]]";

// A compile-time case binding reaches the `Kind::MatchCaseArm` gate in
// handle_binding_pattern.cpp's `CompileTimeBindingPattern` handler, which
// fires the W4 slice-gate TODO before the introducer-dependent local
// generic-`let` TODO could misfire for the case arm's implicit `let`.
fn G(x: i32) {
  match (x) {
    // CHECK:STDERR: fail_todo_compile_time_binding.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case template n: i32 => { return; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case template n: i32 => { return; }
    default => { return; }
  }
}
