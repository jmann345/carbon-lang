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
//   40
//
// Lands together with W4 slice 1 (match statement: integer scrutinee,
// integer-literal cases, `default` — fork/trial-w4/plan.md) and is expected
// to PASS; the scoreboard, not this comment, carries the before/after
// history (fork/process.md standing rule 2).
//
// The honest C/C++ `switch` equivalent — literal cases plus `default`, which
// is all C `switch` can express (no guards/bindings; that coverage lives in
// match_guard_binding.carbon). Three integer cases probed so every case is
// taken (0/1/2 — default NOT taken) and the default is taken (42, and -7 to
// show default also catches negatives). `case <literal>` parses as an
// expression pattern: toolchain/parse/handle_pattern.cpp:43-55 (default
// branch pushes StateKind::ExprPattern, no wrapper node), with AnyPatternId
// accepting Expr-category nodes (toolchain/parse/node_ids.h:109-110);
// `default => { ... }` shape per toolchain/parse/testdata/match/match.carbon.
// Semantics per docs/design/pattern_matching.md: an expression pattern
// matches by equality, and the match executes the first `case` that
// matches, else the `default` block.

import Core library "io";

// switch (n) { case 0: return 10; case 1: return 20; case 2: return 30;
//              default: return 40; }
fn Classify(n: i32) -> i32 {
  match (n) {
    case 0 => { return 10; }
    case 1 => { return 20; }
    case 2 => { return 30; }
    default => { return 40; }
  }
  // Unreachable belt: every arm returns. If a checker/lowering bug let the
  // match fall through, this makes the program fail loudly (exit 1 below).
  return -1;
}

fn Run() -> i32 {
  // Each case taken; default not taken.
  Core.Print(Classify(0));
  Core.Print(Classify(1));
  Core.Print(Classify(2));
  // Default taken.
  Core.Print(Classify(42));
  Core.Print(Classify(-7));
  if (Classify(2) != 30) { return 1; }
  return 0;
}
