// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   4
// QUOTE: `Read(ref c)` returns 4
// Pins the resolution, by TP-1, of the page's limit on `&` with a
// template-dependent operand: `&x.n` on a `ref` parameter of template type is
// checked when `Read(ref c)` is instantiated, where `x.n` is a reference
// expression, and the program prints 4. Before TP-1 the definition was
// rejected with "cannot take the address of non-reference expression" (fork
// work item W-014).

import Core library "io";

class Counter {
  var n: i32;
}

fn Read[template T: type](ref x: T) -> i32 {
  let p: i32* = &x.n;
  return *p;
}

fn Run() -> i32 {
  var c: Counter = {.n = 4};
  Core.Print(Read(ref c));
  return 0;
}
