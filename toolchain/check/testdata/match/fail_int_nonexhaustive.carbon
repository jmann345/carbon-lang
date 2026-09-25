// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_int_nonexhaustive.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_int_nonexhaustive.carbon

// The R8-lift residual lane (W-078b): an integer- or tuple-scrutinee
// `match` with no `default` arm and no unguarded irrefutable arm is
// nonexhaustive outright — expression patterns are never exhaustive, and
// enumeration-based exhaustiveness is design-rejected
// (docs/design/pattern_matching.md) — diagnosed
// `MatchNonexhaustiveNoIrrefutableArm`, naming the scrutinee type and no
// missing values (an integer cannot enumerate its missing values). The
// discharged shapes are in no_default_irrefutable.carbon.

// --- fail_literal_arms.carbon
library "[[@TEST_NAME]]";

// Integer-literal patterns are never exhaustive, so a `match` with no
// `default` arm and no irrefutable arm is an error (this shape pinned the
// former conservative-gate TODO in fail_todo_no_default.carbon).
fn F(x: i32) {
  // CHECK:STDERR: fail_literal_arms.carbon:[[@LINE+4]]:3: error: `match` on `i32` has no `default` arm and no `case` arm that matches every value [MatchNonexhaustiveNoIrrefutableArm]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (x) {
    case 0 => { return; }
  }
}

// --- fail_guarded_irrefutable_only.carbon
library "[[@TEST_NAME]]";

// A guarded irrefutable arm discharges nothing: exhaustiveness assumes
// every guard can evaluate to false (docs/design/pattern_matching.md).
fn F(x: i32, g: bool) -> i32 {
  // CHECK:STDERR: fail_guarded_irrefutable_only.carbon:[[@LINE+4]]:3: error: `match` on `i32` has no `default` arm and no `case` arm that matches every value [MatchNonexhaustiveNoIrrefutableArm]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (x) {
    case n: i32 if (g) => { return n; }
  }
  return -1;
}

// --- fail_tuple_constant_arms.carbon
library "[[@TEST_NAME]]";

// The tuple lane shares the diagnostic, naming the tuple type.
fn F(p: (i32, i32)) -> i32 {
  // CHECK:STDERR: fail_tuple_constant_arms.carbon:[[@LINE+4]]:3: error: `match` on `(i32, i32)` has no `default` arm and no `case` arm that matches every value [MatchNonexhaustiveNoIrrefutableArm]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (p) {
    case (1, 2) => { return 1; }
  }
  return -1;
}

// --- fail_error_arm_suppresses.carbon
library "[[@TEST_NAME]]";

// An arm whose pattern errored makes coverage unknowable, so only the
// arm's own error appears — no stacked nonexhaustive diagnostic.
fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_error_arm_suppresses.carbon:[[@LINE+11]]:10: error: integer value 5000000000 too large for type `i32` [IntTooLargeForType]
    // CHECK:STDERR:     case 5000000000 => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~~~
    // CHECK:STDERR: {{.*}}/prelude/types/int.carbon:124:12: note: initializing function parameter [InCallToFunctionParam]
    // CHECK:STDERR:   fn Equal(self: Int(N), other: Int(N)) -> bool = "int.eq";
    // CHECK:STDERR:            ^~~~~~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_error_arm_suppresses.carbon:[[@LINE-8]]:3: error: `match` on `i32` has no `default` arm and no `case` arm that matches every value [MatchNonexhaustiveNoIrrefutableArm]
    // CHECK:STDERR:   match (x) {
    // CHECK:STDERR:   ^~~~~~~~~~~
    // CHECK:STDERR:
    case 5000000000 => { return 1; }
  }
  return -1;
}

// --- fail_bind_error_arm_no_default.carbon
library "[[@TEST_NAME]]";

// The bind-pass-error carve-out (W-066 plan §1.8): `case b: bool` on an
// i32 scrutinee reaches the coverage recording with a non-error pattern
// and sets `has_irrefutable_arm`, so only the conversion error appears —
// a documented false negative for the nonexhaustive check.
fn F(x: i32) -> i32 {
  // CHECK:STDERR: fail_bind_error_arm_no_default.carbon:[[@LINE+7]]:10: error: cannot implicitly convert expression of type `i32` to `bool` [ConversionFailure]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_bind_error_arm_no_default.carbon:[[@LINE+4]]:10: note: type `i32` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  match (x) {
    case b: bool => { if (b) { return 1; } return 2; }
  }
  return -1;
}

// --- fail_bool_pair_enumeration.carbon
library "[[@TEST_NAME]]";

// The enumeration boundary (W-076 root-only residue): all four
// `(bool, bool)` constants cover the domain value-by-value, but tuple
// ROOTS have no union coverage, so the `match` is still diagnosed — and
// the wording stays literally true: no SINGLE arm matches every value.
fn F(p: (bool, bool)) -> i32 {
  // CHECK:STDERR: fail_bool_pair_enumeration.carbon:[[@LINE+4]]:3: error: `match` on `(bool, bool)` has no `default` arm and no `case` arm that matches every value [MatchNonexhaustiveNoIrrefutableArm]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (p) {
    case (false, false) => { return 0; }
    case (false, true) => { return 1; }
    case (true, false) => { return 2; }
    case (true, true) => { return 3; }
  }
  return -1;
}
