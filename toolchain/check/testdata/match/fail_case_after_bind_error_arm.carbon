// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_case_after_bind_error_arm.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_case_after_bind_error_arm.carbon

// The bind-pass-error carve-out (W-066 plan §1.8): `case b: bool` on an
// i32 scrutinee errors only in the BIND pass — it reaches the usefulness
// recording with a non-error pattern and a constant-true condition, and IS
// recorded as covering, matching the landed `has_irrefutable_arm`
// behavior (the test pass classified the arm irrefutable before the bind
// pass rejected it). The later `case 5` therefore STACKS a usefulness
// error on top of the arm's conversion error — intended and documented
// behavior, pinned here — and the `default` stacks a dead-`default`
// error the same way (W-078b; the covering prior is the bind-error arm).
fn F(x: i32) -> i32 {
  // CHECK:STDERR: fail_case_after_bind_error_arm.carbon:[[@LINE+7]]:10: error: cannot implicitly convert expression of type `i32` to `bool` [ConversionFailure]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_case_after_bind_error_arm.carbon:[[@LINE+4]]:10: note: type `i32` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  match (x) {
    case b: bool => { if (b) { return 1; } return 2; }
    // CHECK:STDERR: fail_case_after_bind_error_arm.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case 5 => { return 3; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_case_after_bind_error_arm.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case b: bool => { if (b) { return 1; } return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case 5 => { return 3; }
    // CHECK:STDERR: fail_case_after_bind_error_arm.carbon:[[@LINE+7]]:5: error: `default` arm never matches; every value of the scrutinee is matched by prior arms [MatchDefaultNeverMatches]
    // CHECK:STDERR:     default => { return 0; }
    // CHECK:STDERR:     ^~~~~~~
    // CHECK:STDERR: fail_case_after_bind_error_arm.carbon:[[@LINE-12]]:5: note: every value is matched by this prior arm [MatchDefaultNeverMatchesPriorArm]
    // CHECK:STDERR:     case b: bool => { if (b) { return 1; } return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    default => { return 0; }
  }
  return -1;
}
