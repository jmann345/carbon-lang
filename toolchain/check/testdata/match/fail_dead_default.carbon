// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_dead_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_dead_default.carbon

// Dead `default` arms on choice and bool scrutinees (W-078a): a `default`
// whose unguarded prior arms already cover the scrutinee's whole closed
// value domain can never match — "in a `match` statement, this happens if
// a pattern or `default` cannot match because all cases it could cover
// are handled by prior cases [...] or a prior `default`"
// (docs/design/pattern_matching.md,
// "Refutability, overlap, usefulness, and exhaustiveness"; the design
// annotates the shape "Error: unreachable."). The error is at the
// `default` keyword, with a note at the single covering prior arm
// (`MatchDefaultNeverMatchesPriorArm`) or — when only the UNION of prior
// arms covers — one statement-level note naming the scrutinee's type
// (`MatchDefaultNeverMatchesFullCoverage`). Guarded `default` arms are
// checked alike: the arm under test's own guard is assumed true. The
// negative pins — guarded priors never cover, prior error arms suppress,
// the integer lane stays exempt (R8) — are in
// usefulness_no_false_positive.carbon.

// --- fail_choice_full_coverage.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// Every alternative is covered by an unguarded arm, so the `default` can
// never be taken (exhaustive_choice.carbon's former with_default shape).
fn Classify(f: Flag) -> i32 {
  match (f) {
    case .Off => { return 0; }
    case .On => { return 1; }
    default => { return -1; }
  }
  return -2;
}

// --- fail_choice_after_irrefutable.carbon
library "[[@TEST_NAME]]";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// An unguarded irrefutable prior arm covers every value, so the single
// covering arm wins the note.
fn F(s: Signal) -> Signal {
  match (s) {
    case c: Signal => { return c; }
    default => { return s; }
  }
  return s;
}

// --- fail_bool_full_coverage.carbon
library "[[@TEST_NAME]]";

// Both bool values covered: the note reads "all alternatives of `bool`",
// the design's bool-as-choice rule.
fn F(b: bool) -> i32 {
  match (b) {
    case false => { return 0; }
    case true => { return 1; }
    default => { return -1; }
  }
  return -2;
}

// --- fail_bool_after_irrefutable.carbon
library "[[@TEST_NAME]]";

// The irrefutable-prior lane on a bool scrutinee.
fn F(b: bool) -> i32 {
  match (b) {
    case b2: bool => { if (b2) { return 1; } return 0; }
    default => { return -1; }
  }
  return -2;
}

// --- fail_trailing_guarded_default.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// A choice fully covered by unguarded case arms with a TRAILING guarded
// `default`: the arm is dead — its own guard is assumed true, and no
// value reaches its test — and diagnose-and-proceed still emits full
// SemIR, so this subfile keeps the guarded `default`'s CFG pin when no
// arm follows it: the guard-failure edge branches to the match
// statement's top empty else block, converging with the other arms
// (moved from guarded_default.carbon's trailing_guarded_default subfile).
fn Classify(f: Flag, x: i32) -> i32 {
  match (f) {
    case .Off => { return 0; }
    case .On => { return 1; }
    default if (x > 0) => { return 2; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- fail_guarded_default_after_irrefutable.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// A guarded `default` after an irrefutable prior arm is equally dead: the
// guard only runs when control reaches the arm, and no value does.
fn F(f: Flag, g: bool) -> Flag {
  match (f) {
    case c: Flag => { return c; }
    default if (g) => { return f; }
  }
  return f;
}

// --- fail_bool_guarded_default.carbon
library "[[@TEST_NAME]]";

// The dead guarded `default` on a bool scrutinee, through the value
// union.
fn F(b: bool, g: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    case false => { return 0; }
    default if (g) => { return -1; }
  }
  return -2;
}

// --- fail_bind_error_arm_prior.carbon
library "[[@TEST_NAME]]";

// The bind-pass-error carve-out (W-066 plan §1.8): `case n: i32` on a
// bool scrutinee errors only in the BIND pass — it reaches the coverage
// recording with a non-error pattern and IS recorded as covering (a
// `Wildcard` key), and `has_error_arm` stays false — so the `default`
// after it IS diagnosed, STACKING on the arm's conversion error: the
// same documented behavior as fail_case_after_bind_error_arm.carbon.
fn F(b: bool) -> i32 {
  match (b) {
    case n: i32 => { return n; }
    default => { return 0; }
  }
  return -1;
}
