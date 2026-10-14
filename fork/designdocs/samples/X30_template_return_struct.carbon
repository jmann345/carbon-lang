// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: ResolveSpecificDefinition
// QUOTE: the same function returning `{.a: T, .b: T}`
// Pins the struct form of the page's limit on returning a value of a type
// built from a template parameter, on the fork toolchain and the nightly (fork
// work item W-014). With `[T: Core.Copy]`, a program that prints `Use()`
// prints 10; a function returning `{.a: T}` runs.

fn Mk[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = x};
}

fn Use() -> i32 {
  let s: {.a: i32, .b: i32} = Mk(5 as i32);
  return s.a + s.b;
}
