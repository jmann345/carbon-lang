// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/assignment.md, "Tuples, structs, choice types, and data classes", quote
// EXPECT-STDOUT:
//   2
//   1
// QUOTE: `let u: (i32, i32) = (t.1, t.0); t = u;`

import Core library "io";

fn Run() -> i32 {
  var t: (i32, i32) = (1, 2);
  let u: (i32, i32) = (t.1, t.0);
  t = u;
  Core.Print(t.0);
  Core.Print(t.1);
  return 0;
}
