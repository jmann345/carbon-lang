// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_case_never_matches_single_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_case_never_matches_single_alternative.carbon

// Usefulness diagnostics on single-alternative choices (W-066): the
// empty-discriminant path (W-068 — the discriminant is the empty tuple, so
// no discriminant test exists), where alternative keying could diverge.
// Keys come from the resolved alternative's index metadata, not from any
// discriminant value, so duplicate and subsumed arms diagnose the same
// way as on multi-alternative choices.

// --- fail_duplicate_bare_single.carbon
library "[[@TEST_NAME]]";

choice One {
  Only
}

// A duplicate bare alternative on a single-alternative choice.
fn F(v: One) -> i32 {
  match (v) {
    case .Only => { return 1; }
    // CHECK:STDERR: fail_duplicate_bare_single.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case .Only => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_duplicate_bare_single.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case .Only => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case .Only => { return 2; }
  }
  return -1;
}

// --- fail_payload_subsumption_single.carbon
library "[[@TEST_NAME]]";

choice Boxed {
  Value(n: i32)
}

// Payload subsumption on a single-alternative choice.
fn F(v: Boxed) -> i32 {
  match (v) {
    case .Value(n: i32) => { return n; }
    // CHECK:STDERR: fail_payload_subsumption_single.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case .Value(5) => { return 5; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_payload_subsumption_single.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case .Value(n: i32) => { return n; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case .Value(5) => { return 5; }
  }
  return -1;
}
