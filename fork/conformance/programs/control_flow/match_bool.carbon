// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   20
//   100
//   20
//   10
//
// Lands together with W-076 (bool match scrutinees — fork/w076/plan.md)
// and is expected to PASS; the scoreboard, not this comment, carries the
// before/after history (fork/process.md standing rule 2).
//
// A Carbon-side "good switch" win C/C++ `switch` cannot express cleanly:
// dispatch on a runtime `bool` with `case true`/`case false` and NO
// `default` — the design treats `bool` like a choice type whose
// alternatives are `false` and `true` (docs/design/pattern_matching.md),
// so covering both values is exhaustive (the design's own `IsTrue`
// worked example). The guarded variant shows a failed guard falling
// through to the next arm while the unguarded `true`/`false` pair still
// discharges the `default` requirement (guards never count toward
// coverage).

import Core library "io";

// C++ has no `switch (b)` over bool worth writing; the honest equivalent
// is `if (b) ... else ...`. Carbon's match is exhaustive without a
// default arm.
fn Classify(b: bool) -> i32 {
  match (b) {
    case false => { return 10; }
    case true => { return 20; }
  }
  // Unreachable belt: every value is covered above. If a checker or
  // lowering bug let the match fall through, this makes the program fail
  // loudly (exit 1 below).
  return -1;
}

// A guarded arm variant: `case true if (big)` runs only when the guard
// holds; a failed guard falls through to the unguarded `case true`. The
// unguarded `true`/`false` arms alone make the match exhaustive.
fn ClassifyGuarded(b: bool, big: bool) -> i32 {
  match (b) {
    case true if (big) => { return 100; }
    case true => { return 20; }
    case false => { return 10; }
  }
  return -1;
}

fn Run() -> i32 {
  // Both values taken through the exhaustive match.
  Core.Print(Classify(false));
  Core.Print(Classify(true));
  // Guard taken; guard failed (falls through to the unguarded arm);
  // guarded arm's pattern not matched at all.
  Core.Print(ClassifyGuarded(true, true));
  Core.Print(ClassifyGuarded(true, false));
  Core.Print(ClassifyGuarded(false, true));
  if (Classify(true) != 20) { return 1; }
  if (ClassifyGuarded(false, false) != 10) { return 1; }
  return 0;
}
