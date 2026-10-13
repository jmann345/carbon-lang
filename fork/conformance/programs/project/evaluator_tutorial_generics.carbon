// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   18
//   20
//   19
//
// Transcribed from docs/guides/tutorial.md, section "Interfaces and generics": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on the upstream nightly and this fork's toolchain.

import Core library "io";

interface Shape {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  extend impl as Shape {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

class Rectangle {
  var width: i32;
  var height: i32;
  extend impl as Shape {
    fn Area(self) -> i32 { return self.width * self.height; }
  }
}

fn DoubleArea[T: Shape](s: T) -> i32 {
  return 2 * s.Area();
}

class Pair(T: type) {
  var first: T;
  var second: T;
}

fn Run() -> i32 {
  let sq: Square = {.side = 3};
  let rect: Rectangle = {.width = 2, .height = 5};
  Core.Print(DoubleArea(sq));
  Core.Print(DoubleArea(rect));

  let p: Pair(i32) = {.first = sq.Area(), .second = rect.Area()};
  Core.Print(p.first + p.second);
  return 0;
}
