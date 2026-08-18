// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/empty_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/empty_choice.carbon

// An empty choice is admitted as a `match` scrutinee (W-068): its
// discriminant field is the empty tuple, like a single-alternative choice's,
// and its alternative set is empty, so every match over it is vacuously
// exhaustive — zero alternatives need zero covering arms. Its values cannot
// be constructed (the choice's scope has no alternatives; see
// handle_choice.cpp on the empty discriminant field), so a scrutinee can
// only reach a match through an uninhabited-typed binding and the arms are
// dynamically dead. Parse still requires at least one arm
// (`MatchStatementStart`, parse/handle_match.cpp), so the zero-arm spelling
// `match (n) {}` remains a parse error; the design docs define
// exhaustiveness over pattern sets but give no zero-arm grammar
// (docs/design/pattern_matching.md, "Refutability, overlap, usefulness, and
// exhaustiveness").

// --- default_only.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Never {}

// A `default`-only match: the arm is dynamically dead — `Never` has no
// constructors — but checks like any other `default`.
fn F(n: Never) -> i32 {
  match (n) {
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- guarded_default_vacuous.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Never {}

// The vacuous-exhaustiveness pin: a guarded `default` never counts toward
// coverage and never discharges the `default` requirement, yet this match
// compiles without an unguarded `default` — the empty alternative set leaves
// nothing uncovered. The same shape over a non-empty choice is diagnosed
// (fail_choice_nonexhaustive.carbon).
fn F(n: Never, c: bool) -> i32 {
  match (n) {
    default if (c) => { return 0; }
  }
  return 1;
}
//@dump-sem-ir-end
