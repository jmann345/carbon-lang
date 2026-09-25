// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   22
//   10
//   20
//   42
//
// Integer `match` exhaustiveness through an unguarded irrefutable arm
// (W-078b, the lifted W-008/R8 conservative gate): no `default` arm is
// needed when an unguarded binding arm matches every value — the design's
// exhaustiveness rule, "a `match` statement is exhaustive if the pattern
// `_: auto` would not be useful as the pattern of a new case added at the
// end" (docs/design/pattern_matching.md, "Refutability, overlap,
// usefulness, and exhaustiveness"). The C equivalent is a `switch` whose
// only label is `default:` — the catch-all arm is spelled as a binding
// instead. Runtime inputs go through RuntimeSeed(x) = x + 20 so the arms
// run against real runtime values, not constant folds. Expected values
// derived by hand: IdentityPlus(1+20) = 21+1 = 22 (the binding arm is
// taken); Classify(-20+20=0) = 10 and Classify(-19+20=1) = 20 (constant
// arms still win first); Classify(22+20=42) = 42 (the trailing binding
// arm catches everything else and returns its bound value).

import Core library "io";

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// switch (x) { default: return x + 1; } — the single irrefutable arm is
// always taken, and the match needs no `default`.
fn IdentityPlus(x: i32) -> i32 {
  match (x) {
    case n: i32 => { return n + 1; }
  }
  // Unreachable belt: the arm always returns. If a checker/lowering bug
  // let the match fall through, this makes the program fail loudly.
  return -1;
}

// switch (n) { case 0: return 10; case 1: return 20; default: return n; }
// — constants first, then the catch-all binding arm.
fn Classify(n: i32) -> i32 {
  match (n) {
    case 0 => { return 10; }
    case 1 => { return 20; }
    case m: i32 => { return m; }
  }
  return -1;
}

fn Run() -> i32 {
  // The lone binding arm is taken on a runtime value.
  Core.Print(IdentityPlus(RuntimeSeed(1)));
  // Constant arms still dispatch first-match-wins.
  Core.Print(Classify(RuntimeSeed(-20)));
  Core.Print(Classify(RuntimeSeed(-19)));
  // The trailing binding arm catches a value no constant covers.
  Core.Print(Classify(RuntimeSeed(22)));
  // Exit-code belt.
  if (Classify(RuntimeSeed(22)) != 42) { return 1; }
  return 0;
}
