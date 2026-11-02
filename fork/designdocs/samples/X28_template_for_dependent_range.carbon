// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   6
// QUOTE: `Sum(a)` on an `array(i32, 3)` holding `(1, 2, 3)` returns 6
// Pins the resolution, by TP-1, of the page's limit on a `for` loop whose
// range depends on a template parameter: the definition compiles, and the
// call `Sum(a)` iterates the array and prints 1 + 2 + 3. Before TP-1 the
// compiler stopped while it checked the loop's header in the definition, with
// or without a call (fork work item W-014).

import Core library "io";

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Run() -> i32 {
  let a: array(i32, 3) = (1, 2, 3);
  Core.Print(Sum(a));
  return 0;
}
