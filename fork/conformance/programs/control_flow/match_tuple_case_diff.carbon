// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
//
// Differential pair — tuple case patterns (W-008 W8a): the design's
// flagship mixed shape (docs/design/pattern_matching.md, "Examples":
// `case (42, (x: f32, y: f32))`) on integer tuples, vs the honest nested
// `if` equivalent in match_tuple_case_diff.diff.cpp (C++ has no tuple
// `switch`). The runner requires byte-identical exit code and stdout, so
// the C++ semantics — first matching shape wins, elementwise equality,
// destructured element reads — are the oracle; no hand-authored
// EXPECT-STDOUT. Runtime inputs go through RuntimeSeed(x) = x + 20 so the
// matches are real runtime dispatches, not constant folds.

import Core library "io";

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// C++ mirror: nested ifs over a struct of {a, {b, c}}.
fn Classify(p: (i32, (i32, i32))) -> i32 {
  match (p) {
    case (42, (x: i32, y: i32)) => { return x + y; }
    case (n: i32, (1, 2)) => { return n; }
    default => { return 0; }
  }
  // Unreachable: every arm returns. A checker/lowering bug that let the
  // match fall through would print -1 and diverge from the C++ oracle.
  return -1;
}

fn Run() -> i32 {
  // First arm: leading 42, bindings sum the nested pair.
  Core.Print(Classify((RuntimeSeed(22), (3, 4))));
  // Second arm: nested pair (1, 2) matched by value, leading element bound.
  Core.Print(Classify((RuntimeSeed(-15), (1, 2))));
  // First-match-wins: (42, (1, 2)) matches the FIRST arm, not the second.
  Core.Print(Classify((RuntimeSeed(22), (1, 2))));
  // Default: neither shape.
  Core.Print(Classify((RuntimeSeed(-11), (3, 4))));
  return 0;
}
