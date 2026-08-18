// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_guarded_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_guarded_default.carbon

// A guarded `default` never discharges the `default` requirement (W-067):
// exhaustiveness assumes every guard can evaluate to false
// (docs/design/pattern_matching.md, "Refutability, overlap, usefulness,
// and exhaustiveness"), so a `match` whose only `default` is guarded gets
// the same diagnosis as one with no `default` at all — the integer
// scrutinee's TODO gate, or the choice scrutinee's real nonexhaustive
// error (S2e machinery, reused unchanged).

// --- fail_integer_no_covering_arm.carbon
library "[[@TEST_NAME]]";

// An integer `match` requires an unguarded `default` (SF-7, W4's rule);
// a trailing guarded `default` leaves the guard-failure edge with no
// covering arm to fall through to.
fn F(x: i32) {
  // CHECK:STDERR: fail_integer_no_covering_arm.carbon:[[@LINE+4]]:3: error: semantics TODO: `match statement without `default` arm` [SemanticsTodo]
  // CHECK:STDERR:   match (x) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (x) {
    case 0 => { return; }
    default if (x < 0) => { return; }
  }
}

// --- fail_choice_uncovered.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// The guarded `default` covers nothing, so `.On` is uncovered and the
// choice `match` is diagnosed nonexhaustive, naming it.
fn Classify(f: Flag, x: i32) -> i32 {
  // CHECK:STDERR: fail_choice_uncovered.carbon:[[@LINE+4]]:3: error: `match` on choice `Flag` has no `default` arm and does not cover alternative `.On` [MatchNonexhaustive]
  // CHECK:STDERR:   match (f) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (f) {
    case .Off => { return 0; }
    default if (x > 0) => { return 2; }
  }
  return -1;
}

// --- fail_non_bool_guard.carbon
library "[[@TEST_NAME]]";

// A `default` guard converts to `bool` exactly like a `case` guard
// (fail_guard_non_bool.carbon); a failed conversion is diagnosed at the
// guard expression.
fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_non_bool_guard.carbon:[[@LINE+7]]:17: error: cannot implicitly convert expression of type `i32` to `bool` [ConversionFailure]
    // CHECK:STDERR:     default if (x + 1) => { return 1; }
    // CHECK:STDERR:                 ^~~~~
    // CHECK:STDERR: fail_non_bool_guard.carbon:[[@LINE+4]]:17: note: type `i32` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
    // CHECK:STDERR:     default if (x + 1) => { return 1; }
    // CHECK:STDERR:                 ^~~~~
    // CHECK:STDERR:
    default if (x + 1) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
