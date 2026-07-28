// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_arm_conversion.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_arm_conversion.carbon

// Deliberately-failing conversions inside a `match` arm, pinning the
// locations of diagnostics produced by the engine-emitted test and by arm
// bodies (re-platform plan R-1).

// --- fail_case_pattern_conversion.carbon
library "[[@TEST_NAME]]";

// The case literal does not fit the scrutinee's type; the conversion inside
// the arm's engine-emitted `==` test must diagnose at the case, not at some
// generated location.
fn F(x: i32) -> i32 {
  match (x) {
    case 5000000000 => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_arm_body_conversion.carbon
library "[[@TEST_NAME]]";

// A failing conversion in an arm's body diagnoses at the body statement.
fn G(x: i32) -> i32 {
  match (x) {
    case 5 => {
      let y: i32 = ();
      return y;
    }
    default => { return 0; }
  }
  return -1;
}
