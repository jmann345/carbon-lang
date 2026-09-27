// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_error_payload_no_cascade.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_error_payload_no_cascade.carbon

// An errored payload element suppresses the exhaustiveness cascade (W-008
// W8a review fix F2): the arm's condition surfaces as `ErrorInst`, so
// `MatchCase` records the error arm and coverage is unknowable — the
// element's own NameNotFound is the ONLY diagnostic, with no spurious
// MatchNonexhaustive naming `.Some` on top. Contrast
// fail_nonexhaustive_payload_literal.carbon, where the `.Some(42)` arm
// checks cleanly and the nonexhaustive diagnostic is real.

choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  match (o) {
    // CHECK:STDERR: fail_error_payload_no_cascade.carbon:[[@LINE+4]]:16: error: name `undeclared` not found [NameNotFound]
    // CHECK:STDERR:     case .Some(undeclared) => { return 1; }
    // CHECK:STDERR:                ^~~~~~~~~~
    // CHECK:STDERR:
    case .Some(undeclared) => { return 1; }
    case .None => { return 0; }
  }
  return -1;
}
