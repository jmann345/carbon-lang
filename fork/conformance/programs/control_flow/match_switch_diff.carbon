// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
//
// Differential pair — the W4 slice-1 differential lock: match over an
// integer scrutinee with literal cases + `default` vs a literal C++
// `switch` in match_switch_diff.diff.cpp. The runner requires
// byte-identical exit code and stdout, so C++ switch semantics (first
// matching case, default otherwise, no fallthrough here because every arm
// returns) are the oracle — no hand-authored EXPECT-STDOUT. Carbon match
// shapes verbatim from control_flow/match_switch.carbon
// (`case <int-literal> => { ... }`, `default => { ... }`; parse shape per
// toolchain/parse/testdata/match/match.carbon, semantics per
// docs/design/pattern_matching.md).
//
// NOTE: on toolchains without match semantics — e.g. upstream nightlies
// through 0.0.0-0.nightly.2026.07.19, where all check/handle_match.cpp
// handlers are context.TODO stubs — this program COMPILE-FAILs. That is the
// expected differential signal there; the fork toolchain (W4 slice 1
// landed) is the arbiter of record for this bullet.

import Core library "io";

// C++ mirror: switch (score) { case 90: ... default: ... }
fn Grade(score: i32) -> i32 {
  match (score) {
    case 90 => { return 4; }
    case 80 => { return 3; }
    case 70 => { return 2; }
    case 60 => { return 1; }
    default => { return 0; }
  }
  // Unreachable: every arm returns. A checker/lowering bug that let the
  // match fall through would print -1 and diverge from the C++ switch.
  return -1;
}

fn Run() -> i32 {
  // Every case taken, then default (large, boundary-adjacent, negative).
  Core.Print(Grade(90));
  Core.Print(Grade(80));
  Core.Print(Grade(70));
  Core.Print(Grade(60));
  Core.Print(Grade(100));
  Core.Print(Grade(61));
  Core.Print(Grade(-90));
  return 0;
}
