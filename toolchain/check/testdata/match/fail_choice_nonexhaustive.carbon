// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_choice_nonexhaustive.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_choice_nonexhaustive.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// A choice `match` without a `default` arm whose unguarded arms do not
// cover every alternative is an error naming the uncovered alternatives
// (docs/design/pattern_matching.md, "Refutability, overlap, usefulness,
// and exhaustiveness"; SF-7; re-platform plan S2e).

// --- fail_missing_one.carbon
library "[[@TEST_NAME]]";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// `.Wait` has no arm.
fn Classify(s: Signal) -> i32 {
  // CHECK:STDERR: fail_missing_one.carbon:[[@LINE+4]]:3: error: `match` on choice `Signal` has no `default` arm and does not cover alternative `.Wait` [MatchNonexhaustive]
  // CHECK:STDERR:   match (s) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (s) {
    case .Go(speed: i32) => { return speed; }
    case .Stop => { return 0; }
  }
  return -1;
}

// --- fail_missing_many.carbon
library "[[@TEST_NAME]]";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// `.Go` and `.Wait` have no arms; both are named, in declaration order.
fn Classify(s: Signal) -> i32 {
  // CHECK:STDERR: fail_missing_many.carbon:[[@LINE+4]]:3: error: `match` on choice `Signal` has no `default` arm and does not cover alternatives `.Go`, `.Wait` [MatchNonexhaustive]
  // CHECK:STDERR:   match (s) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (s) {
    case .Stop => { return 0; }
  }
  return -1;
}

// --- fail_guarded_cover.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// The only arm covering `.Off` is guarded, and a guard can fail at runtime,
// so it never counts toward coverage (the S2d guarded-arm rule): the match
// is not exhaustive even though every alternative has an arm.
fn Classify(f: Flag) -> i32 {
  // CHECK:STDERR: fail_guarded_cover.carbon:[[@LINE+4]]:3: error: `match` on choice `Flag` has no `default` arm and does not cover alternative `.Off` [MatchNonexhaustive]
  // CHECK:STDERR:   match (f) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (f) {
    case .Off if (true) => { return 0; }
    case .On => { return 1; }
  }
  return -1;
}

// --- fail_guarded_binding.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// A binding arm is irrefutable, but a guard makes the whole arm refutable
// (the S2d guarded-arm-never-irrefutable rule), so a guarded binding arm
// covers nothing: both alternatives are named as uncovered.
fn Classify(f: Flag) -> i32 {
  match (f) {
    // CHECK:STDERR: fail_guarded_binding.carbon:[[@LINE+8]]:10: warning: binding `whole` unused [UnusedBinding]
    // CHECK:STDERR:     case whole: Flag if (true) => { return 0; }
    // CHECK:STDERR:          ^~~~~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_guarded_binding.carbon:[[@LINE-5]]:3: error: `match` on choice `Flag` has no `default` arm and does not cover alternatives `.Off`, `.On` [MatchNonexhaustive]
    // CHECK:STDERR:   match (f) {
    // CHECK:STDERR:   ^~~~~~~~~~~
    // CHECK:STDERR:
    case whole: Flag if (true) => { return 0; }
  }
  return -1;
}

// --- fail_all_alternatives_rejected.carbon
library "[[@TEST_NAME]]";

// Every alternative is rejected with a diagnostic (unknown payload type), so
// the choice completes with an integer discriminant — the declared
// alternative count still sizes it — but an EMPTY name-to-index table. The
// match's only arm is guarded, so it records no coverage (and a guarded
// binding arm is never irrefutable): the exhaustiveness analysis runs
// against the empty table and must bail as unknowable coverage — no crash,
// and no nonexhaustive error piled on the declaration's own diagnostics.
choice C {
  // CHECK:STDERR: fail_all_alternatives_rejected.carbon:[[@LINE+4]]:8: error: name `NoSuchType` not found [NameNotFound]
  // CHECK:STDERR:   A(x: NoSuchType),
  // CHECK:STDERR:        ^~~~~~~~~~
  // CHECK:STDERR:
  A(x: NoSuchType),
  // CHECK:STDERR: fail_all_alternatives_rejected.carbon:[[@LINE+4]]:8: error: name `NoSuchType` not found [NameNotFound]
  // CHECK:STDERR:   B(y: NoSuchType)
  // CHECK:STDERR:        ^~~~~~~~~~
  // CHECK:STDERR:
  B(y: NoSuchType)
}

fn F(v: C) -> i32 {
  match (v) {
    // CHECK:STDERR: fail_all_alternatives_rejected.carbon:[[@LINE+4]]:10: warning: binding `w` unused [UnusedBinding]
    // CHECK:STDERR:     case w: C if (true) => { return 0; }
    // CHECK:STDERR:          ^~~~
    // CHECK:STDERR:
    case w: C if (true) => { return 0; }
  }
  return -1;
}

// --- signal.carbon
library "signal";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// --- fail_imported_nonexhaustive.carbon
library "[[@TEST_NAME]]";

import library "signal";

// The alternative table arrives through import (the S2c
// `SemIR::ChoiceAlternative` metadata on the class): coverage is computed
// against the imported table, and the uncovered alternatives are named the
// same as for a same-file choice.
fn Classify(s: Signal) -> i32 {
  // CHECK:STDERR: fail_imported_nonexhaustive.carbon:[[@LINE+4]]:3: error: `match` on choice `Signal` has no `default` arm and does not cover alternatives `.Go`, `.Wait` [MatchNonexhaustive]
  // CHECK:STDERR:   match (s) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (s) {
    case .Stop => { return 0; }
  }
  return -1;
}
