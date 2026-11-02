// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: Lowering function Both(i32)
// QUOTE: stops the compiler while it lowers a call of the method
// Pins the class form of the page's limit on returning a value of a type
// built from a template parameter: the file checks, and the compiler stops
// while it lowers `Both(i32)`, on the fork toolchain and the nightly (fork
// work item W-014). Without the call of `Both`, the file compiles; with
// `class H(T: Core.Copy)`, a program that prints `Use()` prints 6.

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Use() -> i32 {
  let h: H(i32) = {.a = 3};
  let t: (i32, i32) = h.Both();
  return t.0 + t.1;
}
