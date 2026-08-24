// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_tuple_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_tuple_scrutinee.carbon

// Pins the scrutinee-gate half of tuple `match` support (W-008 plan §2.2):
// a tuple scrutinee is rejected at the `MatchCondition` scrutinee gate in
// handle_match.cpp before any case pattern is reached. The tuple-pattern
// half is pinned separately (fail_todo_tuple_pattern.carbon), whose i32
// scrutinee passes this gate and stops at the case-pattern fallback instead.

// --- fail_literal_scrutinee.carbon
library "[[@TEST_NAME]]";

// A tuple-literal scrutinee: converted to a value at `MatchCondition`, then
// rejected by the scrutinee gate.
fn F() {
  // CHECK:STDERR: fail_literal_scrutinee.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match ((1, 2)) {
  // CHECK:STDERR:         ^~~~~~~~
  // CHECK:STDERR:
  match ((1, 2)) {
    default => { return; }
  }
}

// --- fail_var_scrutinee.carbon
library "[[@TEST_NAME]]";

// A non-literal tuple scrutinee (a `var` local) hits the same gate.
fn G() {
  var t: (i32, i32) = (1, 2);
  // CHECK:STDERR: fail_var_scrutinee.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (t) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (t) {
    default => { return; }
  }
}
