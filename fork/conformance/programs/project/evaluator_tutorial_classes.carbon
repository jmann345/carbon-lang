// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
//   7
//   8
//
// Transcribed from docs/guides/tutorial.md, section "Classes": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on the upstream nightly and this fork's toolchain.

import Core library "io";

class Point {
  fn Origin() -> Point {
    return {.x = 0, .y = 0};
  }

  fn Translate(ref self, dx: i32, dy: i32) {
    self.x += dx;
    self.y += dy;
  }

  fn Sum(self) -> i32 {
    return self.x + self.y;
  }

  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  var p: Point = Point.Origin();
  p.Translate(3, 4);
  Core.Print(p.x);
  Core.Print(p.Sum());
  p.Translate(-1, 2);
  Core.Print(p.Sum());
  return 0;
}
