// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
//   70
//   12
//   7
//   42
//   8
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P04 code block of docs/design/templates.md, section
// "Templates in the 0.1 toolchain", byte for byte
// (fork/designdocs/check_samples.py, rulebook R27). Expected output derived by
// hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on this fork's
// toolchain and on the upstream nightly. A PASS shows that the documented
// sample runs as documented; the design-docs bullet itself is arbitrated by
// document review.

import Core library "io";

class Point {
  var x: i32;
  var y: i32;
}

class Size {
  var x: i32;
  var y: i32;
  var depth: i32;
}

class Meters {
  var n: i32;
  impl as Core.ImplicitAs(i32) {
    fn Convert(self) -> i32 { return self.n; }
  }
}

// `p.x` and `p.y` are looked up in the type `T` that each call supplies,
// when the call is instantiated, not when `Sum` is defined.
fn Sum[template T: type](p: T) -> i32 {
  return p.x + p.y;
}

// The conversion and the operator are resolved per instantiation.
fn ToInt[template T: type](x: T) -> i32 {
  let n: i32 = x;
  return n + n;
}

// A deduced template parameter and an explicit one, as in the overview.
fn Convert[template T: type](source: T, template U: type) -> U {
  var converted: U = source;
  return converted;
}

// A template parameter of non-type type.
fn Scale(template N: i32, x: i32) -> i32 {
  return N * x;
}

// A class with a template parameter; its members are checked for each
// argument.
class Holder(template T: type) {
  var item: T;
  fn Get(self) -> T { return self.item; }
}

fn Run() -> i32 {
  let a: Point = {.x = 1, .y = 2};
  let b: Size = {.x = 30, .y = 40, .depth = 0};
  Core.Print(Sum(a));
  Core.Print(Sum(b));
  let m: Meters = {.n = 6};
  Core.Print(ToInt(m));
  let wide: i64 = Convert(7 as i32, i64);
  Core.Print(wide as i32);
  Core.Print(Scale(3, 14));
  let h: Holder(i32) = {.item = 8};
  Core.Print(h.Get());
  return 0;
}
