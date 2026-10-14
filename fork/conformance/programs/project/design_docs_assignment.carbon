// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: User-defined types (classes)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   11
//   15
//   1
//   4
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P03 code block of docs/design/assignment.md,
// section "Tuples, structs, choice types, and data classes", byte for byte
// (fork/designdocs/check_samples.py, rulebook R27). Expected output derived by
// hand in fork/designdocs/plan.md section 4 (R16(d)). Fork-only: the upstream
// nightly rejects it (the plan's section 4). A PASS shows that the documented
// sample runs as documented; the design-docs bullet itself is arbitrated by
// document review.

import Core library "io";

choice Light {
  Red,
  Green
}

class Point {
  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  // Tuples and structs assign element by element, from a literal or from
  // another object of the same type.
  var t: (i32, i32) = (1, 2);
  t = (3, 4);
  var s: {.a: i32, .b: i32} = {.a = 1, .b = 2};
  let other: {.a: i32, .b: i32} = {.a = 5, .b = 6};
  s = other;
  // A class assigns from a struct literal naming every field.
  var p: Point = {.x = 0, .y = 0};
  p = {.x = 7, .y = 8};
  // A choice value assigns as a whole.
  var light: Light = Light.Red;
  light = Light.Green;
  Core.Print(t.0 + t.1);
  Core.Print(s.a + s.b);
  Core.Print(p.x + p.y);
  match (light) {
    case .Red => { Core.Print(0); }
    case .Green => { Core.Print(1); }
  }
  // To exchange elements, copy the old value first.
  var old: (i32, i32) = t;
  t = (old.1, old.0);
  Core.Print(t.0);
  return 0;
}
