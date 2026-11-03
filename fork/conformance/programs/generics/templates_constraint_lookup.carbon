// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   25
//   6
//
// Proposal 2200 ("Name lookup", p002200:433-441, :476-503): a member of a
// value whose type is a constrained template parameter is looked up in the
// argument type and in the constraint (TP-1; DD-1 fixture R09). Square
// provides Area only through `impl as HasArea`, so the
// constraint finds it: 5 x 5 = 25. Rect's `extend impl` makes the type and
// the constraint find the same function: 2 x 3 = 6.

import Core library "io";

interface HasArea {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  impl as HasArea {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

class Rect {
  var w: i32;
  var h: i32;
  extend impl as HasArea {
    fn Area(self) -> i32 { return self.w * self.h; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Run() -> i32 {
  let q: Square = {.side = 5};
  Core.Print(Report(q));
  let r: Rect = {.w = 2, .h = 3};
  Core.Print(Report(r));
  return 0;
}
