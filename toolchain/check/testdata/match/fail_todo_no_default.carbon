// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// TODO: Extend the "int" min_prelude to support basic integer operations, so we
// can use it here.
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_no_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_no_default.carbon

// Integer matches keep W4's rule at S2e (SF-7: exhaustiveness discharges
// the `default` requirement for choice scrutinees only): an integer `match`
// without a `default` arm stays behind the TODO. The choice shape's real
// diagnostic is pinned by fail_choice_nonexhaustive.carbon.

// --- fail_literal_arms.carbon
library "[[@TEST_NAME]]";

// Integer-literal patterns are never exhaustive, so a `match` without a
// `default` arm is invalid; enumeration-based exhaustiveness is not
// implemented.
fn F(x: i32) {
  // CHECK:STDERR: fail_literal_arms.carbon:[[@LINE+4]]:3: error: semantics TODO: `match statement without `default` arm` [SemanticsTodo]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (x) {
    case 0 => { return; }
  }
}

// --- fail_irrefutable_binding_arm.carbon
library "[[@TEST_NAME]]";

// An irrefutable binding arm covers every value, but integer matches keep
// requiring `default` verbatim (SF-7); the irrefutable-arm discharge
// applies to choice scrutinees only in this slice.
fn F(x: i32) {
  // CHECK:STDERR: fail_irrefutable_binding_arm.carbon:[[@LINE+4]]:3: error: semantics TODO: `match statement without `default` arm` [SemanticsTodo]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (x) {
    case n: i32 => { return; }
  }
}
