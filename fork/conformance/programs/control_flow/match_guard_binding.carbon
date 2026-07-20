// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   20
//   30
// SKIP: out of W4 slice 1 — binding patterns and case guards have no semantics: this file's `case a: i32 if (a < 0)` arm is rejected at its `case` token with "error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard`" (the `MatchCaseIntroducer` slice gate in toolchain/check/handle_match.cpp; fork/trial-w4/plan.md H5). Un-SKIP when guards + binding patterns land (post-slice-1 W4 work). Sketch compile-verified per R6: passes `carbon compile --phase=parse` (exit 0) on the arbiter tree (nightly 2026.07.19).
//
// Preserves the guard/binding coverage that match_switch.carbon carried
// before it was narrowed to slice-1 arms (literal cases + `default` only):
// a binding pattern with an `if` guard, shape verbatim from
// toolchain/parse/testdata/match/match.carbon:16 (`case a: i32 if (a != x)
// => { ... }`). Semantics per
// docs/design/pattern_matching.md: first matching case wins, and the bound
// `a` is in scope in the guard ("Guards": `case` _pattern_ [`if`
// _expression_]? `=>` _block_). EXPECT directives already encode those
// designed semantics so this becomes a real execution test the moment the
// SKIP line is removed.

import Core library "io";

// switch has no equivalent: a guarded binding arm between literal arms.
fn Classify(n: i32) -> i32 {
  match (n) {
    case 0 => { return 10; }
    case a: i32 if (a < 0) => { return 20; }
    default => { return 30; }
  }
  return -1;
}

fn Run() -> i32 {
  Core.Print(Classify(0));
  Core.Print(Classify(-7));
  Core.Print(Classify(42));
  return 0;
}
