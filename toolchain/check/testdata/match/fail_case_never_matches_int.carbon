// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_case_never_matches_int.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_case_never_matches_int.carbon

// Usefulness diagnostics for integer `case` patterns (W-066): a `case` arm
// whose pattern duplicates a prior arm's evaluated constant value can never
// match — first-match-wins dispatch consumed the value — and is an error at
// the arm, with a note at the covering prior arm. Comparison is by
// evaluated constant value, never source form. Every fn keeps a trailing
// `default` arm: the conservative integer-exhaustiveness gate (W-008
// residue R8) requires one, and `default` arms are exempt from the
// usefulness check (W-066 plan §1.5, W-078).

// --- fail_duplicate_literal.carbon
library "[[@TEST_NAME]]";

// An exact duplicate literal.
fn F(x: i32) -> i32 {
  match (x) {
    case 5 => { return 1; }
    // CHECK:STDERR: fail_duplicate_literal.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case 5 => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_duplicate_literal.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case 5 => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case 5 => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_constant_expr_duplicate.carbon
library "[[@TEST_NAME]]";

// A source-form-invisible duplicate: `2 + 3` evaluates to the same
// mathematical value as `5`, so the arms key equal.
fn F(x: i32) -> i32 {
  match (x) {
    case 5 => { return 1; }
    // CHECK:STDERR: fail_constant_expr_duplicate.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case 2 + 3 => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_constant_expr_duplicate.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case 5 => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case 2 + 3 => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_negative_duplicate.carbon
library "[[@TEST_NAME]]";

// A negative-value duplicate through distinct spellings.
fn F(x: i32) -> i32 {
  match (x) {
    case -1 => { return 1; }
    // CHECK:STDERR: fail_negative_duplicate.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case -(1) => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_negative_duplicate.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case -1 => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case -(1) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_guarded_later_duplicate.carbon
library "[[@TEST_NAME]]";

// A guarded LATER duplicate is dead regardless of its guard: control only
// reaches its test with values the prior unguarded arm already consumed
// (W-066 plan §1.3). Contrast the guarded-PRIOR shape, which stays silent
// (usefulness_no_false_positive.carbon).
fn F(x: i32, g: bool) -> i32 {
  match (x) {
    case 5 => { return 1; }
    // CHECK:STDERR: fail_guarded_later_duplicate.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case 5 if (g) => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_guarded_later_duplicate.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case 5 => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case 5 if (g) => { return 2; }
    default => { return 0; }
  }
  return -1;
}
