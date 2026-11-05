// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/assignment.md, "Tuples, structs, choice types, and data classes", quote
// EXPECT-STDOUT:
//   2
//   2
//   2
//   2
// QUOTE: assigns element by element from the literal and leaves `(2, 2)`
// Pins the 0.1 toolchain's current result for a tuple and a struct swap written
// as a literal, `(2, 2)`, which differs from the answer the leads gave on issue
// 686 (a temporary from the right-hand side, then the destination destroyed and
// the temporary moved in, which gives `(2, 1)`). The expected lines restate the
// page's measured sentence, not a design rule: this fixture keeps the page
// honest about current behavior and changes, with the page, when the toolchain
// defect W-188 is fixed.

import Core library "io";

fn Run() -> i32 {
  var t: (i32, i32) = (1, 2);
  t = (t.1, t.0);
  Core.Print(t.0);
  Core.Print(t.1);
  var s: {.a: i32, .b: i32} = {.a = 1, .b = 2};
  s = {.a = s.b, .b = s.a};
  Core.Print(s.a);
  Core.Print(s.b);
  return 0;
}
