// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_bool_case_never_matches.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_bool_case_never_matches.carbon

// Usefulness on bool scrutinees (W-076 plan §2.4): bool constant arms key
// as `BoolConst`, so a duplicate value dies by single-prior subsumption
// with a note at the covering arm, and the `true`+`false` union kills a
// later wildcard-rooted arm with the statement-level
// `MatchCaseNeverMatchesFullCoverage` note — bool's two values are the
// whole domain, exactly as a choice's alternative union (the design
// treats `bool` like a choice type, docs/design/pattern_matching.md).

// --- fail_duplicate_true.carbon
library "[[@TEST_NAME]]";

// The second `case true` can never match; single-prior note.
fn F(b: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    // CHECK:STDERR: fail_duplicate_true.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case true => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_duplicate_true.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case true => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case true => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_union_kills_binding.carbon
library "[[@TEST_NAME]]";

// `case true` + `case false` cover the whole domain, so the
// binding-rooted arm is dead with no single prior subsuming it: one
// statement-level note ("all alternatives of `bool`"). The two constant
// arms also make the match exhaustive, so no `default` is required.
fn G(b: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    case false => { return 0; }
    // CHECK:STDERR: fail_union_kills_binding.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case b2: bool => { if (b2) { return 3; } return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_union_kills_binding.carbon:[[@LINE-6]]:10: note: all alternatives of `bool` are matched by prior arms [MatchCaseNeverMatchesFullCoverage]
    // CHECK:STDERR:   match (b) {
    // CHECK:STDERR:          ^
    // CHECK:STDERR:
    case b2: bool => { if (b2) { return 3; } return 2; }
  }
  return -1;
}

// --- fail_union_then_duplicate.carbon
library "[[@TEST_NAME]]";

// A duplicated constant after full coverage still takes the single-prior
// note, pointing at the FIRST covering arm — first-covering-arm
// determinism, not the union note.
fn H(b: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    case false => { return 0; }
    // CHECK:STDERR: fail_union_then_duplicate.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case true => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_union_then_duplicate.carbon:[[@LINE-5]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case true => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case true => { return 2; }
  }
  return -1;
}

// --- fail_tuple_duplicate.carbon
library "[[@TEST_NAME]]";

// A duplicate tuple pattern with a bool element dies through the
// `Tuple`+`BoolConst` key composition.
fn T(t: (bool, i32)) -> i32 {
  match (t) {
    case (true, 1) => { return 1; }
    // CHECK:STDERR: fail_tuple_duplicate.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case (true, 1) => { return 2; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_tuple_duplicate.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case (true, 1) => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (true, 1) => { return 2; }
    default => { return 0; }
  }
  return -1;
}
