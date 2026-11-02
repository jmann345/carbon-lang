// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Types with template parameters", quote
// EXPECT-STDOUT:
//   8
// QUOTE: `First` on a `Holder(array(i32, 2))` holding `(8, 9)` returns 8
// Pins the resolution, by TP-1, of the fork note after the overview's `Stack`
// example: in a class with a template parameter, `self.item[0]` is indexed as
// an array when `First` is instantiated for `array(i32, 2)`, and the program
// prints 8. Before TP-1 the instantiation failed with the note ``cannot access
// member of interface `Core.IndexWith(Core.IntLiteral)` in type
// `array(i32, 2)` that does not implement that interface`` (fork work item
// W-192). X19 pins the same form in a function.

import Core library "io";

class Holder(template T: type) {
  var item: T;
  fn First(self) -> i32 { return self.item[0]; }
}

fn Run() -> i32 {
  let h: Holder(array(i32, 2)) = {.item = (8, 9)};
  Core.Print(h.First());
  return 0;
}
