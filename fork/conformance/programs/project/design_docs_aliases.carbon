// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Code organization: Namespaces
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
//   7
//   304
//   20
//   6
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P01 code block of docs/design/aliases.md, section
// "Aliases in the 0.1 toolchain", byte for byte
// (fork/designdocs/check_samples.py, rulebook R27). Expected output derived by
// hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on this fork's
// toolchain and on the upstream nightly. A PASS shows that the documented
// sample runs as documented; the design-docs bullet itself is arbitrated by
// document review.

import Core library "io";

namespace Geometry;
fn Geometry.Scale() -> i32 { return 10; }

interface Printable {
  fn Print(self);
}

class Point {
  var x: i32;
  var y: i32;
  // A member alias: `p.horizontal` names the field `p.x`.
  alias horizontal = x;
  fn Sum(self) -> i32 { return self.x + self.y; }
  alias Total = Sum;
  // An alias can surface an interface member under a class-member name.
  impl as Printable {
    fn Print(self) { Core.Print(self.x * 100 + self.y); }
  }
  alias PrintToScreen = Printable.Print;
}

// File-scope aliases of a type, a namespace, a function, a constant value,
// and a specific of a generic class.
alias Coord = Point;
alias Geo = Geometry;
alias Scale = Geometry.Scale;
alias Limit = 4;

class Box(T: type) {
  var item: T;
}
alias IntBox = Box(i32);

var calls: i32 = 0;

fn Run() -> i32 {
  // A local alias of a file-scope variable names the same storage.
  alias count = calls;
  count += 1;
  let p: Coord = {.x = 3, .y = Limit};
  Core.Print(p.horizontal);
  Core.Print(p.Total());
  p.PrintToScreen();
  Core.Print(Geo.Scale() + Scale());
  let b: IntBox = {.item = 5};
  Core.Print(b.item + calls);
  return 0;
}
