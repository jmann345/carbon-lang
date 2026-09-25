// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_ref_binding_value_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_ref_binding_value_scrutinee.carbon

// A `ref` case binding against a value scrutinee — here a by-value
// parameter — is a real error, not a TODO: the scrutinee must itself be a
// durable reference (docs/design/pattern_matching.md, "Name binding
// patterns"), and the standard conversion machinery owns the diagnostic,
// located at the scrutinee expression the bind pass converts.

fn F(x: i32) -> i32 {
  // CHECK:STDERR: fail_ref_binding_value_scrutinee.carbon:[[@LINE+4]]:10: error: cannot bind durable reference to non-reference value of type `i32` [ConversionFailureNonRefToRef]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  match (x) {
    case ref a: i32 => { return a; }
    // CHECK:STDERR: fail_ref_binding_value_scrutinee.carbon:[[@LINE+7]]:5: error: `default` arm never matches; every value of the scrutinee is matched by prior arms [MatchDefaultNeverMatches]
    // CHECK:STDERR:     default => { return 0; }
    // CHECK:STDERR:     ^~~~~~~
    // CHECK:STDERR: fail_ref_binding_value_scrutinee.carbon:[[@LINE-4]]:5: note: every value is matched by this prior arm [MatchDefaultNeverMatchesPriorArm]
    // CHECK:STDERR:     case ref a: i32 => { return a; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    default => { return 0; }
  }
  return -1;
}
