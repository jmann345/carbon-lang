// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   12
//   0
//   -1
//   1
//   45
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P06 code block of docs/design/pattern_matching.md,
// section "`match` in the 0.1 toolchain", byte for byte
// (fork/designdocs/check_samples.py, rulebook R27). Expected output derived by
// hand in fork/designdocs/plan.md section 4 (R16(d)). Fork-only: the upstream
// nightly rejects it (the plan's section 4). A PASS shows that the documented
// sample runs as documented; the design-docs bullet itself is arbitrated by
// document review.

import Core library "io";

choice Shape {
  Circle(radius: i32),
  Rect(width: i32, height: i32),
  Empty
}

fn Area(s: Shape) -> i32 {
  // The arms cover every alternative, so no `default` is needed.
  match (s) {
    case .Circle(r: i32) => { return 3 * r * r; }
    case .Rect(w: i32, h: i32) => { return w * h; }
    case .Empty => { return 0; }
  }
  // Still required in 0.1; see the note on exhaustive `match` below.
  return -1;
}

fn Classify(n: i32) -> i32 {
  // Constant cases, a guarded binding, and the `default` an `i32` needs.
  match (n) {
    case 0 => { return 0; }
    case x: i32 if (x < 0) => { return -1; }
    default => { return 1; }
  }
}

fn Quadrant(p: (i32, i32)) -> i32 {
  match (p) {
    case (0, 0) => { return 0; }
    case (x: i32, y: i32) if (x > 0 and y > 0) => { return 1; }
    default => { return 2; }
  }
}

fn Width(r: {.w: i32, .h: i32}) -> i32 {
  // Struct patterns name fields; `_` discards the rest.
  match (r) {
    case {.w = 0, _} => { return -1; }
    case {.w = w: i32, .h = h: i32} => { return w * 10 + h; }
  }
  return -2;
}

fn Run() -> i32 {
  Core.Print(Area(Shape.Rect(3, 4)));
  Core.Print(Area(Shape.Empty));
  Core.Print(Classify(-5));
  Core.Print(Quadrant((2, 3)));
  Core.Print(Width({.w = 4, .h = 5}));
  return 0;
}
