// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
//
// Differential pair — the S2d guard lock (match re-platform,
// fork/match-replatform/plan.md §3.4): a match whose arms discriminate
// through guards vs the literal C++ `if`/`else if` chain in
// match_guard_diff.diff.cpp. The runner requires byte-identical exit code
// and stdout, so C++ chain semantics are the oracle — no hand-authored
// EXPECT-STDOUT. Guard semantics per docs/design/pattern_matching.md
// ("Guards"): the pattern's bindings are in scope in the guard, and a
// `case` with a failed guard does not match — evaluation falls through to
// the next arm, then `default`. The compound guard (`and`) additionally
// locks short-circuit evaluation inside a guard.
//
// NOTE: on toolchains without guard semantics — upstream nightlies, and
// fork toolchains before S2d — this program COMPILE-FAILs ("semantics
// TODO: `match case guard`"). That is the expected differential signal
// there; the fork toolchain with S2d landed is the arbiter of record.

import Core library "io";

// C++ mirror: if (n == 0) ... else if (n < 0) ... else if (n > 99 &&
// n < 1000) ... else ...
fn Bucket(n: i32) -> i32 {
  match (n) {
    case 0 => { return 100; }
    case a: i32 if (a < 0) => { return 0 - a; }
    case b: i32 if (b > 99 and b < 1000) => { return b - 100; }
    default => { return 7; }
  }
  return -1;
}

fn Run() -> i32 {
  // The literal arm; both guarded arms; a value failing every guard; the
  // boundary just past the compound guard's upper bound.
  Core.Print(Bucket(0));
  Core.Print(Bucket(-5));
  Core.Print(Bucket(500));
  Core.Print(Bucket(50));
  Core.Print(Bucket(1000));
  return 0;
}
