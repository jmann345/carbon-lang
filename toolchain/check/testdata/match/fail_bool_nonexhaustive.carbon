// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_bool_nonexhaustive.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_bool_nonexhaustive.carbon

// A bool `match` without a `default` arm whose unguarded arms do not
// cover both values is a real nonexhaustive error naming the missing
// value(s) in domain order (`MatchNonexhaustiveBool`; W-076 plan §2.3 —
// the design treats `bool` like a choice type whose alternatives are
// `false` and `true`, docs/design/pattern_matching.md), not a TODO.

// --- fail_missing_false.carbon
library "[[@TEST_NAME]]";

// Only `true` is covered.
fn F(b: bool) -> i32 {
  // CHECK:STDERR: fail_missing_false.carbon:[[@LINE+4]]:3: error: `match` on `bool` has no `default` arm and does not cover value `false` [MatchNonexhaustiveBool]
  // CHECK:STDERR:   match (b) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (b) {
    case true => { return 1; }
  }
  return 0;
}

// --- fail_missing_true.carbon
library "[[@TEST_NAME]]";

// Only `false` is covered.
fn G(b: bool) -> i32 {
  // CHECK:STDERR: fail_missing_true.carbon:[[@LINE+4]]:3: error: `match` on `bool` has no `default` arm and does not cover value `true` [MatchNonexhaustiveBool]
  // CHECK:STDERR:   match (b) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (b) {
    case false => { return 0; }
  }
  return 1;
}

// --- fail_guarded_arm_only.carbon
library "[[@TEST_NAME]]";

// A guarded arm never counts toward coverage — exhaustiveness assumes
// every guard can fail — so both values are missing.
fn H(b: bool, c: bool) -> i32 {
  // CHECK:STDERR: fail_guarded_arm_only.carbon:[[@LINE+4]]:3: error: `match` on `bool` has no `default` arm and does not cover values `false`, `true` [MatchNonexhaustiveBool]
  // CHECK:STDERR:   match (b) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (b) {
    case true if (c) => { return 1; }
  }
  return 0;
}

// --- fail_guarded_default_only.carbon
library "[[@TEST_NAME]]";

// A guarded `default` never discharges the `default` requirement and
// records nothing toward exhaustiveness, so both values are missing.
fn I(b: bool, c: bool) -> i32 {
  // CHECK:STDERR: fail_guarded_default_only.carbon:[[@LINE+4]]:3: error: `match` on `bool` has no `default` arm and does not cover values `false`, `true` [MatchNonexhaustiveBool]
  // CHECK:STDERR:   match (b) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (b) {
    default if (c) => { return 1; }
  }
  return 0;
}
