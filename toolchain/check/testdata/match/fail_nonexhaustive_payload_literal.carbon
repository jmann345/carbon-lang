// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_nonexhaustive_payload_literal.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_nonexhaustive_payload_literal.carbon

// The coverage pin for refutable payload arms (W-008 plan §4 R-4): a
// `.Some(42)` arm compares the payload's value, can fail, and records
// NOTHING toward covered alternatives — so this `match` does not cover
// `.Some`, and a constant-choice-valued expression pattern is never
// exhaustive (docs/design/pattern_matching.md, "Refutability, overlap,
// usefulness, and exhaustiveness").

choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  // CHECK:STDERR: fail_nonexhaustive_payload_literal.carbon:[[@LINE+4]]:3: error: `match` on choice `OptInt` has no `default` arm and does not cover alternative `.Some` [MatchNonexhaustive]
  // CHECK:STDERR:   match (o) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (o) {
    case .Some(42) => { return 1; }
    case .None => { return 0; }
  }
  return -1;
}
