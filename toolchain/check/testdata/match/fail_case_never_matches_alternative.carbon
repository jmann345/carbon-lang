// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_case_never_matches_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_case_never_matches_alternative.carbon

// Usefulness diagnostics for choice-alternative `case` patterns (W-066):
// duplicate bare alternatives, duplicate payload constants, and payload
// constants subsumed by a prior arm's payload bindings — alternative roots
// compare by discriminant index, then payload slots elementwise.

// --- fail_duplicate_bare.carbon
library "[[@TEST_NAME]]";

choice Signal {
  Stop,
  Wait
}

// A duplicate bare alternative.
fn F(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 1; }
    case .Stop => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_duplicate_payload_constant.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// A duplicate payload constant.
fn F(r: IntResult) -> i32 {
  match (r) {
    case .Ok(42) => { return 1; }
    case .Ok(42) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_payload_subsumption.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// Payload subsumption: `.Ok(v: i32)` matches every `.Ok` value, so
// `.Ok(42)` can never match. The unguarded `.Ok` and `.Err` arms cover the
// choice, so no `default` is required.
fn F(r: IntResult) -> i32 {
  match (r) {
    case .Ok(v: i32) => { return v; }
    case .Ok(42) => { return 1; }
    case .Err => { return 0; }
  }
  return -1;
}

// --- fail_mixed_payload_subsumption.carbon
library "[[@TEST_NAME]]";

choice Shape {
  Pair(a: i32, b: i32),
  Dot
}

// Mixed payload subsumption: at each payload slot the prior is a wildcard
// or an equal constant.
fn F(s: Shape) -> i32 {
  match (s) {
    case .Pair(1, b: i32) => { return b; }
    case .Pair(1, 2) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_ordering_pin.carbon
library "[[@TEST_NAME]]";

choice Letter {
  A,
  B,
  C
}

// Same-statement ordering pin: the dead-arm error fires at the duplicate
// `.A` arm, and THEN the statement-level `MatchNonexhaustive` names `.B`
// and `.C` — the dead duplicate contributes no coverage beyond what the
// first `.A` arm already recorded (W-066 plan OQ-2: dead arms are not
// recorded as usefulness context either).
fn F(l: Letter) -> i32 {
  match (l) {
    case .A => { return 1; }
    case .A => { return 2; }
  }
  return -1;
}
