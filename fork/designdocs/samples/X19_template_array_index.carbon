// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   2
// QUOTE: `Second(a)` on `(1, 2, 3)` returns 2
// Pins the resolution, by TP-1, of the page's limit on indexing a value whose
// type is a template argument of array type: `a[1]` is indexed as an array
// when `Second` is instantiated for `array(i32, 3)`, and the program prints 2.
// Before TP-1 the instantiation failed with the note ``cannot access member
// of interface `Core.IndexWith(Core.IntLiteral)` in type `array(i32, 3)` that
// does not implement that interface`` (fork work item W-192).

import Core library "io";

fn Second[template T: type](a: T) -> i32 {
  return a[1];
}

fn Run() -> i32 {
  let a: array(i32, 3) = (1, 2, 3);
  Core.Print(Second(a));
  return 0;
}
