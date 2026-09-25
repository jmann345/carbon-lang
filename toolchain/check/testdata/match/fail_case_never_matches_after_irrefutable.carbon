// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_case_never_matches_after_irrefutable.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_case_never_matches_after_irrefutable.carbon

// Usefulness diagnostics for `case` arms after an unguarded irrefutable arm
// (W-066): a binding root, an irrefutable `var` root, or an all-binding
// tuple root covers every scrutinee value, so any later `case` arm can
// never match — the check-layer sibling of parse's arms-after-`default`
// error. Integer-scrutinee fns keep a trailing `default` (the W-008
// residue R8 gate; `default` is usefulness-exempt, W-066 plan §1.5); the
// choice-scrutinee fn is exhaustive through its irrefutable arm.

// --- fail_after_binding.carbon
library "[[@TEST_NAME]]";

fn F(x: i32) -> i32 {
  match (x) {
    case n: i32 => { return n; }
    // CHECK:STDERR: fail_after_binding.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case 5 => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_after_binding.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case n: i32 => { return n; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case 5 => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_after_var_binding.carbon
library "[[@TEST_NAME]]";

// A `var` wrapper over a binding is an irrefutable (wildcard) root too.
fn F(x: i32) -> i32 {
  match (x) {
    case var a: i32 => { return a; }
    // CHECK:STDERR: fail_after_var_binding.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case 1 => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_after_var_binding.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case var a: i32 => { return a; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case 1 => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_choice_after_binding.carbon
library "[[@TEST_NAME]]";

choice Signal {
  Stop,
  Wait
}

// On a choice scrutinee, an irrefutable binding arm consumes every value,
// so a later alternative arm is dead; the single covering prior arm gets
// the note (contrast the union-coverage note in
// fail_case_never_matches_full_coverage.carbon).
fn F(s: Signal) -> Signal {
  match (s) {
    case c: Signal => { return c; }
    // CHECK:STDERR: fail_choice_after_binding.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case .Stop => { return s; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_choice_after_binding.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case c: Signal => { return c; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case .Stop => { return s; }
  }
  return s;
}

// --- fail_after_all_binding_tuple.carbon
library "[[@TEST_NAME]]";

// An all-binding tuple root is irrefutable given its checked arity/type.
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (a: i32, b: i32) => { return a + b; }
    // CHECK:STDERR: fail_after_all_binding_tuple.carbon:[[@LINE+7]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case (1, 2) => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_after_all_binding_tuple.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case (a: i32, b: i32) => { return a + b; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, 2) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_dead_arm_bindings_warn.carbon
library "[[@TEST_NAME]]";

// A dead arm WITH bindings: checking continues through diagnosed-dead arms
// (diagnose-and-proceed), so the dead arm's pattern still checks and its
// unused binding `a` still gets the ordinary `UnusedBinding` warning —
// `MatchHandler` pops the arm's scope with unused checking like any other
// arm (W-066 plan §4).
fn F(x: i32) -> i32 {
  match (x) {
    case n: i32 => { return n; }
    // CHECK:STDERR: fail_dead_arm_bindings_warn.carbon:[[@LINE+11]]:5: error: `case` pattern never matches; every value it can match is matched by a prior arm [MatchCaseNeverMatches]
    // CHECK:STDERR:     case var a: i32 => { return 0; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR: fail_dead_arm_bindings_warn.carbon:[[@LINE-4]]:5: note: pattern is fully covered by this prior arm [MatchCaseNeverMatchesPriorArm]
    // CHECK:STDERR:     case n: i32 => { return n; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_dead_arm_bindings_warn.carbon:[[@LINE+4]]:14: warning: binding `a` unused [UnusedBinding]
    // CHECK:STDERR:     case var a: i32 => { return 0; }
    // CHECK:STDERR:              ^~~~~~
    // CHECK:STDERR:
    case var a: i32 => { return 0; }
    default => { return 1; }
  }
  return -1;
}
