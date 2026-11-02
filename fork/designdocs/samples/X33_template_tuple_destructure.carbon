// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   9
// QUOTE: `Sum(t)` on `(4, 5)` returns 9
// Pins the resolution, by TP-1, of the destructuring half of the page's limit
// on tuple values whose type is a template argument: the program prints
// 4 + 5. Before TP-1 the compiler stopped while it lowered `Sum((i32, i32))`,
// at toolchain/lower/aggregate.cpp:67 (fork work item W-014). The other half,
// `Id` returning values that differ from run to run, is pinned by the
// toolchain's lower/testdata/template/initialize.carbon and by the conformance
// program templates_return_aggregates_diff.

import Core library "io";

fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}

fn Run() -> i32 {
  let t: (i32, i32) = (4, 5);
  Core.Print(Sum(t));
  return 0;
}
