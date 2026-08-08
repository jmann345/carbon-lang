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
    // CHECK:STDERR: fail_case_pattern_conversion.carbon:[[@LINE+7]]:10: error: integer value 5000000000 too large for type `i32` [IntTooLargeForType]
    // CHECK:STDERR:     case 5000000000 => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~~~
    // CHECK:STDERR: {{.*}}/prelude/types/int.carbon:124:12: note: initializing function parameter [InCallToFunctionParam]
    // CHECK:STDERR:   fn Equal(self: Int(N), other: Int(N)) -> bool = "int.eq";
    // CHECK:STDERR:            ^~~~~~~~~~~~
    // CHECK:STDERR:
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
      // CHECK:STDERR: fail_arm_body_conversion.carbon:[[@LINE+7]]:20: error: cannot implicitly convert expression of type `()` to `i32` [ConversionFailure]
      // CHECK:STDERR:       let y: i32 = ();
      // CHECK:STDERR:                    ^~
      // CHECK:STDERR: fail_arm_body_conversion.carbon:[[@LINE+4]]:20: note: type `()` does not implement interface `Core.ImplicitAs(i32)` [MissingImplInMemberAccessInContext]
      // CHECK:STDERR:       let y: i32 = ();
      // CHECK:STDERR:                    ^~
      // CHECK:STDERR:
      let y: i32 = ();
      return y;
    }
    default => { return 0; }
  }
  return -1;
}

// --- fail_case_binding_conversion.carbon
library "[[@TEST_NAME]]";

// A case binding whose type the scrutinee cannot convert to diagnoses at the
// bind-pass conversion in the arm's body block; the conversion's location is
// the scrutinee it converts (re-platform plan R-1).
fn H(x: i32) -> i32 {
  // CHECK:STDERR: fail_case_binding_conversion.carbon:[[@LINE+7]]:10: error: cannot implicitly convert expression of type `i32` to `bool` [ConversionFailure]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_case_binding_conversion.carbon:[[@LINE+4]]:10: note: type `i32` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  match (x) {
    case b: bool => { if (b) { return 1; } return 2; }
    default => { return 0; }
  }
  return -1;
}
