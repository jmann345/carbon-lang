// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   5
// QUOTE: `Second(t)` on `(4, 5)` returns 5
// Pins the resolution, by TP-1, of the page's limit on tuple element access
// with a template-dependent operand: `p.1` is checked when `Second(t)` is
// instantiated for `(i32, i32)`, and the program prints 5. Before TP-1 the
// definition was rejected with ``type `T` does not support tuple indexing;
// only tuples can be indexed that way`` (fork work item W-014).

import Core library "io";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn Run() -> i32 {
  let t: (i32, i32) = (4, 5);
  Core.Print(Second(t));
  return 0;
}
