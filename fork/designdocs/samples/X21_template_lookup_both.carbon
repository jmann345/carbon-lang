// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   21
// QUOTE: proposal 2200 rejects the call when `G` is instantiated, but the toolchain calls the type's member
// Pins the 0.1 toolchain's current result where a template parameter's type
// and its constraint both provide `F` with different meanings: `x.(A.F)()`
// calls the `impl`'s `F` (2) and `x.F()` calls the class's own `F` (1), so
// the program prints 2 x 10 + 1. This restates the page's measured sentence,
// not a design rule: proposal 2200's "Name lookup" section (p002200:476-503)
// makes `x.F()` a monomorphization error here, so this fixture changes, with
// the page, when fork work item W-183 is fixed.

import Core library "io";

interface A {
  fn F(self) -> i32;
}

class C {
  var v: i32;
  fn F(self) -> i32 { return 1; }
  impl as A {
    fn F(self) -> i32 { return 2; }
  }
}

fn G[template T: A](x: T) -> i32 {
  return x.(A.F)() * 10 + x.F();
}

fn Run() -> i32 {
  let c: C = {.v = 9};
  Core.Print(G(c));
  return 0;
}
