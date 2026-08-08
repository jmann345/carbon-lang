// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   20
//   30
//
// Preserves the guard/binding coverage that match_switch.carbon carried
// before it was narrowed to slice-1 arms (literal cases + `default` only):
// a binding pattern with an `if` guard, shape verbatim from
// toolchain/parse/testdata/match/match.carbon:16 (`case a: i32 if (a != x)
// => { ... }`). Semantics per
// docs/design/pattern_matching.md: first matching case wins, the bound
// `a` is in scope in the guard ("Guards": `case` _pattern_ [`if`
// _expression_]? `=>` _block_), and a failed guard falls through to the
// next arm — here `default`. Un-SKIPped at S2d (match re-platform,
// fork/match-replatform/plan.md §3.4), which gave guards real semantics:
// the guard evaluates after the arm's bindings are initialized, and
// branches into the arm's body or on to the next arm's test.

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
