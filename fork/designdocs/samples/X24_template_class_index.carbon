// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Types with template parameters", quote
// EXPECT-ERROR: unable to monomorphize specific `First(array(i32, 2))`
// QUOTE: cannot access member of interface `Core.IndexWith(Core.IntLiteral)` in type `array(i32, 2)` that does not implement that interface
// Pins the fork note after the overview's `Stack` example: in a class with a
// template parameter, `self.item[0]` fails when `First` is instantiated for
// an array argument (fork work item W-192), where a member of type
// `array(i32, 2)` written out can be indexed. X19 pins the same limit in a
// function. The quote is the note under the error.

class Holder(template T: type) {
  var item: T;
  fn First(self) -> i32 { return self.item[0]; }
}

fn Use(h: Holder(array(i32, 2))) -> i32 {
  return h.First();
}
