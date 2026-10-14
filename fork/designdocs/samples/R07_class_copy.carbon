// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/assignment.md, "Tuples, structs, choice types, and data classes", block
// EXPECT-ERROR: cannot copy value of type `Point`

class Point {
  var x: i32;
  var y: i32;
}

fn Reset(ref p: Point, q: Point) {
  p = q;
}
