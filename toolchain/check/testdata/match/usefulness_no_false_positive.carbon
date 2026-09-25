// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/usefulness_no_false_positive.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/usefulness_no_false_positive.carbon

// Negative pins for the usefulness check (W-066) and the dead-`default`
// check (W-078a): every arm here is useful and must stay SILENT (the
// fail_ subfiles carry only their error arms' OWN diagnostics). Guarded
// prior arms never enter the context set (a prior arm's guard is assumed
// to evaluate to false, docs/design/pattern_matching.md), constants only
// collide on equal evaluated values, a general pattern after a specific
// one is useful (the subsumption asymmetry), the accumulator is
// per-statement, partial alternative coverage never completes the
// full-coverage union, and the `default` lane adds its own negatives:
// guarded priors never cover, a prior error arm suppresses the check,
// and the integer lane stays exempt (R8).

// --- guarded_prior.carbon
library "[[@TEST_NAME]]";

// A guarded prior arm blocks nothing: its guard is assumed false, so the
// later unguarded duplicate is useful (contrast the guarded-LATER shape in
// fail_case_never_matches_int.carbon).
fn F(x: i32, g: bool) -> i32 {
  match (x) {
    case 5 if (g) => { return 1; }
    case 5 => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- both_guarded_twins.carbon
library "[[@TEST_NAME]]";

// Both-guarded twins: the prior's guard is assumed false and the later's
// true, so the later twin is useful.
fn F(x: i32, g: bool, h: bool) -> i32 {
  match (x) {
    case 5 if (g) => { return 1; }
    case 5 if (h) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- both_guarded_alternative_twins.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// The alternative-rooted both-guarded twins, silent for the same reason.
fn F(r: IntResult, g: bool, h: bool) -> i32 {
  match (r) {
    case .Ok(42) if (g) => { return 1; }
    case .Ok(42) if (h) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- guarded_irrefutable_prior.carbon
library "[[@TEST_NAME]]";

// A guarded arm never enters the context, however wide its pattern: the
// irrefutable binding root does not make later arms dead while guarded.
fn F(x: i32) -> i32 {
  match (x) {
    case n: i32 if (n > 0) => { return n; }
    case 5 => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- nested_match.carbon
library "[[@TEST_NAME]]";

// Nested-match independence: the usefulness context is per-statement, so
// the inner `case 5` does not collide with the outer one.
fn F(x: i32, y: i32) -> i32 {
  match (x) {
    case 5 => {
      match (y) {
        case 5 => { return 1; }
        default => { return 2; }
      }
      return 3;
    }
    default => { return 0; }
  }
  return -1;
}

// --- partial_coverage_then_binding.carbon
library "[[@TEST_NAME]]";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// Partial alternative coverage then a binding arm: one alternative of
// three is covered, so the full-coverage union never completes and the
// binding arm is useful (`.Go` and `.Wait` values reach it).
fn F(s: Signal) -> Signal {
  match (s) {
    case .Stop => { return s; }
    case other: Signal => { return other; }
  }
  return s;
}

// --- guarded_default_mid_list.carbon
library "[[@TEST_NAME]]";

// A guarded `default` mid-list is a guarded arm in the context sense: it
// blocks nothing, so the `case 1` after it — repeating no prior constant —
// is useful (guarded_default.carbon's landed shape, restated as
// usefulness evidence).
fn F(x: i32) -> i32 {
  match (x) {
    case 0 => { return 0; }
    default if (x < 0) => { return 1; }
    case 1 => { return 2; }
    default => { return 3; }
  }
  return -1;
}

// --- different_constants.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

choice TwoPayloads {
  A(x: i32),
  B(y: i32)
}

// Distinct evaluated values never collide.
fn Tuples(p: (i32, i32)) -> i32 {
  match (p) {
    case (1, 2) => { return 1; }
    case (1, 3) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// Distinct payload constants under the same alternative.
fn Payloads(r: IntResult) -> i32 {
  match (r) {
    case .Ok(1) => { return 1; }
    case .Ok(2) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// Different alternatives with equal payload constants are disjoint: the
// discriminant differs, so the equal payload value does not collide.
fn Alternatives(t: TwoPayloads) -> i32 {
  match (t) {
    case .A(42) => { return 1; }
    case .B(42) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- specific_then_general.carbon
library "[[@TEST_NAME]]";

choice Boxed {
  Only(x: i32)
}

// The subsumption asymmetry: a wildcard is never itself subsumed by a
// constant, so a general pattern after a specific one is useful.
fn Tuples(p: (i32, i32)) -> i32 {
  match (p) {
    case (1, 2) => { return 1; }
    case (1, b: i32) => { return b; }
    default => { return 0; }
  }
  return -1;
}

fn Payloads(v: Boxed) -> i32 {
  match (v) {
    case .Only(7) => { return 1; }
    case .Only(x: i32) => { return x; }
  }
  return -1;
}

// --- dead_default_exempt.carbon
library "[[@TEST_NAME]]";

// A `default` arm made dead by an unguarded irrefutable prior arm is
// diagnosed on choice and bool scrutinees (W-078a;
// fail_dead_default.carbon) but stays deliberately exempt on the INTEGER
// lane: the conservative integer-exhaustiveness gate (W-008 residue R8,
// `MatchStatement`'s "match statement without `default` arm" TODO) still
// REQUIRES the `default` on every integer-scrutinee `match`, so
// diagnosing it would make `IntSide` below unwritable. The integer half
// of W-078 lands with-or-after the R8 lift; this commented negative
// golden is its record, since a `fail_todo_` file cannot pin the ABSENCE
// of a diagnostic.
fn IntSide(x: i32) -> i32 {
  match (x) {
    case n: i32 => { return n; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_prior_error_arm.carbon
library "[[@TEST_NAME]]";

// A prior ERROR arm records no key (its coverage is unknowable), so the
// later `case 5` is NOT diagnosed — only the error arm's own conversion
// error appears. Unlike exhaustiveness, the prior error does not suppress
// later usefulness checks; there is simply nothing sound to compare
// against (W-066 plan §1.8).
fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_prior_error_arm.carbon:[[@LINE+7]]:10: error: integer value 5000000000 too large for type `i32` [IntTooLargeForType]
    // CHECK:STDERR:     case 5000000000 => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~~~
    // CHECK:STDERR: {{.*}}/prelude/types/int.carbon:124:12: note: initializing function parameter [InCallToFunctionParam]
    // CHECK:STDERR:   fn Equal(self: Int(N), other: Int(N)) -> bool = "int.eq";
    // CHECK:STDERR:            ^~~~~~~~~~~~
    // CHECK:STDERR:
    case 5000000000 => { return 1; }
    case 5 => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- guarded_priors_default.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// Every alternative is covered only by GUARDED arms, which record
// nothing (a prior arm's guard is assumed to evaluate to false), so the
// `default` is reachable and the dead-`default` check (W-078a) stays
// silent — and it is the arm that keeps the match exhaustive.
fn F(f: Flag, g: bool, h: bool) -> i32 {
  match (f) {
    case .Off if (g) => { return 0; }
    case .On if (h) => { return 1; }
    default => { return 2; }
  }
  return -1;
}

// --- fail_error_arm_prior_default.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// Full alternative coverage plus a prior ERROR arm (`.Err()` — parens on
// a constant alternative, a non-aborting pattern error): the blanket
// `has_error_arm` suppression keeps the dead `default` SILENT, as
// `DiagnoseNonexhaustiveMatch` does; only the error arm's own diagnostic
// appears (W-078a plan §1.4).
fn F(r: IntResult) -> i32 {
  match (r) {
    case .Ok(v: i32) => { return v; }
    case .Err => { return 0; }
    case .Err() => { return 1; }
    default => { return 2; }
  }
  return -1;
}

// --- fail_error_arm_wildcard_prior_default.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// The W-078a plan §1.4 ASYMMETRY, pinned: an error arm plus a
// `Wildcard`-root irrefutable prior plus `default` stays silent on the
// `default` — the blanket `has_error_arm` suppression is a deliberate
// conservative divergence from the case-arm usefulness rule, which does
// not suppress on prior error arms and would diagnose a `case` arm in
// the `default`'s position against the recorded irrefutable prior. Only
// the error arm's own diagnostic appears.
fn F(r: IntResult) -> i32 {
  match (r) {
    case .Err() => { return 1; }
    case unused c: IntResult => { return 0; }
    default => { return 2; }
  }
  return -1;
}
