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
// behavior, pinned here. The `default` arm stays exempt (plan §1.5).
fn F(x: i32) -> i32 {
  match (x) {
    case b: bool => { if (b) { return 1; } return 2; }
    case 5 => { return 3; }
    default => { return 0; }
  }
  return -1;
}
