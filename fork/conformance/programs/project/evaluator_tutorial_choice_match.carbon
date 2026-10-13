// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   12
//   15
//   0
//   100
//   200
//   300
//
// Transcribed from docs/guides/tutorial.md, section "Choice types and match": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on this fork's toolchain only (the upstream nightly rejects it).

import Core library "io";

choice Figure {
  Circle(radius: i32),
  Rectangle(width: i32, height: i32),
  Empty
}

// Approximates pi as 3 to stay in integer arithmetic.
fn Area(f: Figure) -> i32 {
  var area: i32 = 0;
  match (f) {
    case .Circle(r: i32) => { area = 3 * r * r; }
    case .Rectangle(w: i32, h: i32) => { area = w * h; }
    case .Empty => { area = 0; }
  }
  return area;
}

fn Describe(n: i32) -> i32 {
  var code: i32 = 0;
  match (n) {
    case 0 => { code = 100; }
    case x: i32 if (x < 0) => { code = 200; }
    default => { code = 300; }
  }
  return code;
}

fn Run() -> i32 {
  Core.Print(Area(Figure.Circle(2)));
  Core.Print(Area(Figure.Rectangle(3, 5)));
  Core.Print(Area(Figure.Empty));
  Core.Print(Describe(0));
  Core.Print(Describe(-4));
  Core.Print(Describe(9));
  return 0;
}
