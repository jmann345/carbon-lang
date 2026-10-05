// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_case_never_matches_full_coverage.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_case_never_matches_full_coverage.carbon

// Usefulness diagnostics through full alternative coverage (W-066 plan
// §2.3 step 3b): a wildcard-rooted arm on a choice scrutinee is the one
// in-slice position with a FINITE value domain, so a UNION of prior
// alternative arms can make it dead with no single prior subsuming it. No
// single covering arm exists, so the note is one statement-level note
// naming the scrutinee's choice type
// (`MatchCaseNeverMatchesFullCoverage`). The negative pin — partial
// coverage stays silent — is in usefulness_no_false_positive.carbon.

// --- fail_binding_after_full_coverage.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// Two-alternative full coverage, then a binding-rooted arm.
fn F(f: Flag) -> Flag {
  match (f) {
    case .Off => { return f; }
    case .On => { return f; }
    // CHECK:STDERR: fail_binding_after_full_coverage.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case c: Flag => { return c; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_binding_after_full_coverage.carbon:[[@LINE-6]]:10: note: all alternatives of `Flag` are matched by prior arms [MatchCaseNeverMatchesFullCoverage]
    // CHECK:STDERR:   match (f) {
    // CHECK:STDERR:          ^
    // CHECK:STDERR:
    case c: Flag => { return c; }
  }
  return f;
}

// --- fail_single_alternative_union.carbon
library "[[@TEST_NAME]]";

choice One {
  Only
}

// The degenerate single-alternative union: the one bare alternative covers
// the whole (discriminant-free, W-068) choice.
fn F(v: One) -> One {
  match (v) {
    case .Only => { return v; }
    // CHECK:STDERR: fail_single_alternative_union.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case x: One => { return x; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_single_alternative_union.carbon:[[@LINE-5]]:10: note: all alternatives of `One` are matched by prior arms [MatchCaseNeverMatchesFullCoverage]
    // CHECK:STDERR:   match (v) {
    // CHECK:STDERR:          ^
    // CHECK:STDERR:
    case x: One => { return x; }
  }
  return v;
}

// --- fail_irrefutable_payload_union.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// Irrefutable-payload coverage completes the union: `.Ok(v: i32)` covers
// `.Ok` (a wholly-irrefutable payload counts, exactly as for
// exhaustiveness), `.Err` covers the rest, and the binding arm is dead.
fn F(r: IntResult) -> i32 {
  match (r) {
    case .Ok(v: i32) => { return v; }
    case .Err => { return 0; }
    // CHECK:STDERR: fail_irrefutable_payload_union.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case unused u: IntResult => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_irrefutable_payload_union.carbon:[[@LINE-6]]:10: note: all alternatives of `IntResult` are matched by prior arms [MatchCaseNeverMatchesFullCoverage]
    // CHECK:STDERR:   match (r) {
    // CHECK:STDERR:          ^
    // CHECK:STDERR:
    case unused u: IntResult => { return 1; }
  }
  return -1;
}

// --- fail_guarded_after_full_coverage.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// A guarded later arm after full coverage is equally dead: its guard only
// runs when its pattern matched, and no value reaches its test (W-066
// plan §1.3).
fn F(f: Flag, g: bool) -> Flag {
  match (f) {
    case .Off => { return f; }
    case .On => { return f; }
    // CHECK:STDERR: fail_guarded_after_full_coverage.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case c: Flag if (g) => { return c; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_guarded_after_full_coverage.carbon:[[@LINE-6]]:10: note: all alternatives of `Flag` are matched by prior arms [MatchCaseNeverMatchesFullCoverage]
    // CHECK:STDERR:   match (f) {
    // CHECK:STDERR:          ^
    // CHECK:STDERR:
    case c: Flag if (g) => { return c; }
  }
  return f;
}
