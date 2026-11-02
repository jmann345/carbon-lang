// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: ResolveSpecificDefinition
// QUOTE: stops the compiler when a call is instantiated
// Pins the page's limit on returning a value of a type built from a template
// parameter: the compiler stops while it resolves the definition of
// `Dup(i32)`, on the fork toolchain and the nightly (fork work item W-014).
// Without the call, the file compiles; with `[T: Core.Copy]` in place of
// `[template T: type]`, a program that prints `Use()` prints 8.

fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Use() -> i32 {
  let t: (i32, i32) = Dup(4 as i32);
  return t.0 + t.1;
}
