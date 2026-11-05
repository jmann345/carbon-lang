// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   8
// QUOTE: `Dup(4 as i32)` returns `(4, 4)`
// Pins the resolution, by TP-1, of the page's limit on returning a value of a
// type built from a template parameter, in its tuple form: the program prints
// 4 + 4. Before TP-1 the compiler stopped while it resolved the definition of
// `Dup(i32)`, on the fork toolchain and the nightly (fork work item W-014).

import Core library "io";

fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Run() -> i32 {
  let t: (i32, i32) = Dup(4 as i32);
  Core.Print(t.0 + t.1);
  return 0;
}
