// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   2
// QUOTE: `T.F()` for a type parameter calls the constraint's `F`
// Pins the page's limit, measured after TP-1, on member lookup through a
// template type parameter rather than a value: `T.F()` calls the `impl`'s
// `F` (2), although `C` has its own `F` (1) and proposal 2200 looks a name up
// in both and requires the same entity (fork work item W-262). `x.F()` on a
// value of type `T` is rejected in the same case (X21).

import Core library "io";

interface A {
  fn F() -> i32;
}

class C {
  fn F() -> i32 { return 1; }
  impl as A {
    fn F() -> i32 { return 2; }
  }
}

fn G[template T: A](unused x: T) -> i32 {
  return T.F();
}

fn Run() -> i32 {
  let c: C = {};
  Core.Print(G(c));
  return 0;
}
