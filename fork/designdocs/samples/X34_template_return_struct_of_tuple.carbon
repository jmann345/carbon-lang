// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: ResolveSpecificDefinition
// QUOTE: `fn F[template T: type](x: T) -> {.a: (i32, i32)}` with the body `return {.a = x};`
// Pins the page's limit, measured after TP-1, on returning a struct whose one
// field is a tuple, initialized from a value: the compiler stops while it
// resolves the definition of `F((i32, i32))`. The same function without a
// template parameter, with `x: (i32, i32)`, stops the compiler too, where it
// is defined (fork work item W-256).

fn F[template T: type](x: T) -> {.a: (i32, i32)} {
  return {.a = x};
}

fn Use() -> i32 {
  let t: (i32, i32) = (1, 2);
  let s: {.a: (i32, i32)} = F(t);
  return s.a.1;
}
