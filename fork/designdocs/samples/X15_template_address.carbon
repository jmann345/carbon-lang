// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: cannot take the address of non-reference expression
// QUOTE: cannot take the address of non-reference expression
// Pins the page's limit on `&` with a template-dependent operand: `x.n` on a
// `ref` parameter of template type is not known to be a reference expression
// where the function is defined, so `&x.n` is rejected there (fork work item
// W-014). The same function with `ref x: Counter` compiles.

class Counter {
  var n: i32;
}

fn Read[template T: type](ref x: T) -> i32 {
  let p: i32* = &x.n;
  return *p;
}

fn Use() -> i32 {
  var c: Counter = {.n = 4};
  return Read(ref c);
}
