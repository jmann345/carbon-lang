// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: Lowering function Sum((i32, i32))
// QUOTE: stops the compiler while it lowers the instantiation
// Pins the destructuring half of the page's limit on tuple values whose type
// is a template argument (probe PR-AK's h03): the compiler stops while it
// lowers `Sum((i32, i32))`, at toolchain/lower/aggregate.cpp:67, on the fork
// toolchain and the nightly (fork work item W-014). The other half, values
// that differ from run to run, cannot be pinned by a fixture.

fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}

fn Use() -> i32 {
  let t: (i32, i32) = (4, 5);
  return Sum(t);
}
