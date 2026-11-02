// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   10
// QUOTE: `Mk(5 as i32)` returns `{.a = 5, .b = 5}`
// Pins the resolution, by TP-1, of the struct form of the page's limit on
// returning a value of a type built from a template parameter: the program
// prints 5 + 5. Before TP-1 the compiler stopped, on the fork toolchain and
// the nightly (fork work item W-014).

import Core library "io";

fn Mk[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = x};
}

fn Run() -> i32 {
  let s: {.a: i32, .b: i32} = Mk(5 as i32);
  Core.Print(s.a + s.b);
  return 0;
}
