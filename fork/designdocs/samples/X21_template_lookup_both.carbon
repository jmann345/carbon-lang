// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: unable to monomorphize specific `G(C as A)`
// QUOTE: member name `F` names different entities in type `C` and in its constraint `A`
// Pins the resolution, by TP-1, of the page's limit on a name that a template
// parameter's type and its constraint give different meanings: `x.F()` finds
// the class's own `F` in `C` and the `impl`'s `F` in `A`, so `G(c)` is
// rejected when `G` is instantiated, as proposal 2200's "Name lookup" section
// (p002200:476-503) requires; the quote is the note under the error. Before
// TP-1 the program printed 21, calling the type's member (fork work item
// W-183). `x.(A.F)()` alone still calls the `impl`'s `F`.

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
