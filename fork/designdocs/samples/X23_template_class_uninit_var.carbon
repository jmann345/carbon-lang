// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Types with template parameters", quote
// EXPECT-ERROR: cannot convert type `T` into type implementing `Core.DefaultOrUnformed`
// QUOTE: cannot convert type `T` into type implementing `Core.DefaultOrUnformed`
// Pins the fork note after the overview's `Stack` example: a method of a class
// with a template parameter that declares `var y: T;` without an initializer
// is rejected where the class is defined, not on instantiation (fork work item
// W-127, held PR 51). X20 pins the same limit in a function.

class Stack(template T: type) {
  var top: T;
  fn Peek(self) -> T {
    var y: T;
    y = self.top;
    return y;
  }
}

fn Use(s: Stack(i32)) -> i32 {
  return s.Peek();
}
