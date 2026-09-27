// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_case_never_matches_tuple.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_case_never_matches_tuple.carbon

// Usefulness diagnostics for tuple `case` patterns (W-066): duplicate
// constant vectors, and constants subsumed elementwise by a prior arm's
// bindings — at each element the prior is a wildcard (irrefutable subtree)
// or an equal constant. Non-literal tuple scrutinees throughout (the W8a
// lesson: the literal shortcut hides bugs). The trailing `default` arms
// are live: no arm here is irrefutable, so nothing covers the domain
// without them (W-078b).

// --- fail_duplicate_vector.carbon
library "[[@TEST_NAME]]";

// A duplicate constant vector.
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (1, 2) => { return 1; }
    // CHECK:STDERR: fail_duplicate_vector.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case (1, 2) => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_duplicate_vector.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case (1, 2) => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, 2) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_subsumed_by_mixed.carbon
library "[[@TEST_NAME]]";

// Subsumption by a prior mixed arm: `(1, b: i32)` matches every `(1, _)`,
// so `(1, 2)` can never match.
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (1, b: i32) => { return b; }
    // CHECK:STDERR: fail_subsumed_by_mixed.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case (1, 2) => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_subsumed_by_mixed.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case (1, b: i32) => { return b; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, 2) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_nested_duplicate.carbon
library "[[@TEST_NAME]]";

// A nested-tuple duplicate: the comparison recurses elementwise.
fn F(p: (i32, (i32, i32))) -> i32 {
  match (p) {
    case (1, (2, 3)) => { return 1; }
    // CHECK:STDERR: fail_nested_duplicate.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case (1, (2, 3)) => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_nested_duplicate.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case (1, (2, 3)) => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, (2, 3)) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_wildcard_other_element.carbon
library "[[@TEST_NAME]]";

// Subsumption with the wildcard on the other element: `(a: i32, 2)`
// matches every `(_, 2)`, so `(1, 2)` can never match.
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (a: i32, 2) => { return a; }
    // CHECK:STDERR: fail_wildcard_other_element.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case (1, 2) => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_wildcard_other_element.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case (a: i32, 2) => { return a; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, 2) => { return 2; }
    default => { return 0; }
  }
  return -1;
}
