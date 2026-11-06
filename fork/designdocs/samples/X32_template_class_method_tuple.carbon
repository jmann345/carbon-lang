// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   6
// QUOTE: `h.Both()` returns `(3, 3)`
// Pins the resolution, by TP-1, of the class form of the page's limit on
// returning a value of a type built from a template parameter: the program
// prints 3 + 3. Before TP-1 the file checked and the compiler stopped while it
// lowered `Both(i32)`, on the fork toolchain and the nightly (fork work item
// W-014).

import Core library "io";

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Run() -> i32 {
  let h: H(i32) = {.a = 3};
  let t: (i32, i32) = h.Both();
  Core.Print(t.0 + t.1);
  return 0;
}
