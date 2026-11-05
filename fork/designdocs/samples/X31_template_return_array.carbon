// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   8
// QUOTE: `Two(4 as i32)` returns an array holding 4 and 4
// Pins the resolution, by TP-1, of the array form of the page's limit on
// returning a value of a type built from a template parameter: the program
// prints 4 + 4, as the upstream nightly already did. Before TP-1 the fork
// toolchain stopped (fork work item W-014).

import Core library "io";

fn Two[template T: type](x: T) -> array(T, 2) {
  return (x, x);
}

fn Run() -> i32 {
  let a: array(i32, 2) = Two(4 as i32);
  Core.Print(a[0] + a[1]);
  return 0;
}
