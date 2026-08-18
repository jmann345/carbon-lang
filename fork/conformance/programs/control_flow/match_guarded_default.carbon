// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   20
//   30
//   40
//
// Guards on `default` clauses (W-067), per docs/design/pattern_matching.md
// ("Guards"): "this facility is also available for `default` clauses, so
// that `default` remains equivalent to `case _: auto`" (p2188:552-553).
// switch has no equivalent: a conditional catch-all between literal arms.
// A guard-true `default` takes its arm (`Classify(-7)` -> 20 without
// touching `case 1`); a guard-false `default` falls through to the arms
// AFTER it — reachable precisely because the guard can fail — here to
// `case 1` (`Classify(1)` -> 30) and to the final unguarded `default`
// (`Classify(42)` -> 40). First-match-wins: `Classify(0)` -> 10 never
// evaluates the guard chain. A guarded `default` does not satisfy the
// mandatory-`default` rule, so the final arm stays unguarded. Guard inputs
// are runtime-computed via RuntimeSeed (x + 20) so no constant folding can
// decide the guard.

import Core library "io";

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Classify(n: i32) -> i32 {
  match (n) {
    case 0 => { return 10; }
    default if (n < 0) => { return 20; }
    case 1 => { return 30; }
    default => { return 40; }
  }
  return -1;
}

fn Run() -> i32 {
  Core.Print(Classify(RuntimeSeed(-20)));
  Core.Print(Classify(RuntimeSeed(-27)));
  Core.Print(Classify(RuntimeSeed(-19)));
  Core.Print(Classify(RuntimeSeed(22)));
  return 0;
}
