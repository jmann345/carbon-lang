// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Types with template parameters", quote
// EXPECT-STDOUT:
//   6
// QUOTE: `Peek` on a `Stack(i32)` whose `top` is 6 returns 6
// Pins the resolution, by TP-1, of the fork note after the overview's `Stack`
// example: a method of a class with a template parameter that declares
// `var y: T;` without an initializer is checked when `Peek` is instantiated,
// and the program prints `top`, 6. Before TP-1 the class was rejected where it
// is defined (fork work item W-127). X20 pins the same form in a function.

import Core library "io";

class Stack(template T: type) {
  var top: T;
  fn Peek(self) -> T {
    var y: T;
    y = self.top;
    return y;
  }
}

fn Run() -> i32 {
  let s: Stack(i32) = {.top = 6};
  Core.Print(s.Peek());
  return 0;
}
