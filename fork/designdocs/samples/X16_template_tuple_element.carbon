// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: type `T` does not support tuple indexing; only tuples can be indexed that way
// QUOTE: type `T` does not support tuple indexing; only tuples can be indexed that way
// Pins the page's limit on tuple element access with a template-dependent
// operand: `p.1` is checked where the function is defined and rejected,
// although the only call passes a tuple (fork work item W-014). The same
// function with `p: (i32, i32)` compiles.

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn Use() -> i32 {
  let t: (i32, i32) = (4, 5);
  return Second(t);
}
