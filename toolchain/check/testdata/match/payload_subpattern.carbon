// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/payload_subpattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/payload_subpattern.carbon

// Non-binding payload subpatterns in alternative patterns (W-008 W8a): the
// payload's expression subpatterns compare the payload's values in a block
// strictly dominated by the arm's discriminant test — the payload region of
// a non-active alternative is uninitialized storage — and the discriminant
// and payload conditions merge into the arm's single bool. A refutable
// payload arm records nothing toward exhaustiveness.

// --- literal.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

//@dump-sem-ir-begin
fn F(r: IntResult) -> i32 {
  match (r) {
    case .Ok(42) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- mixed.carbon
library "[[@TEST_NAME]]";

choice Shape {
  Pair(a: i32, b: i32),
  Dot
}

//@dump-sem-ir-begin
fn F(s: Shape) -> i32 {
  match (s) {
    case .Pair(1, b: i32) => { return b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- multi_element.carbon
library "[[@TEST_NAME]]";

choice Shape {
  Pair(a: i32, b: i32),
  Dot
}

// Exhaustive without `default`: the refutable `.Pair(1, 2)` arm records
// nothing, and the all-binding `.Pair(a: i32, b: i32)` arm covers `.Pair`.
//@dump-sem-ir-begin
fn F(s: Shape) -> i32 {
  match (s) {
    case .Pair(1, 2) => { return 1; }
    case .Pair(a: i32, b: i32) => { return a + b; }
    case .Dot => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- guarded.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// The guard splices after the bind pass, in the arm's body block, and a
// failed guard falls through to the next arm.
//@dump-sem-ir-begin
fn F(r: IntResult, b: bool) -> i32 {
  match (r) {
    case .Ok(42) if (b) => { return 1; }
    case .Ok(value: i32) => { return value; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- single_alternative.carbon
library "[[@TEST_NAME]]";

choice Boxed {
  Only(x: i32)
}

// A single-alternative choice has no discriminant to test (W-068), so the
// payload conditions are the arm's whole condition; the all-binding arm
// keeps the match exhaustive without `default`.
//@dump-sem-ir-begin
fn F(v: Boxed) -> i32 {
  match (v) {
    case .Only(7) => { return 1; }
    case .Only(x: i32) => { return x; }
  }
  return -1;
}
//@dump-sem-ir-end
