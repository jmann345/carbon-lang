// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/metaprogramming.md, "Compile-time evaluation in the 0.1 toolchain", block
// EXPECT-ERROR: non-constant call to compile-time-only function

musteval fn Twice(n: i32) -> i32 { return n * 2; }

fn F(x: i32) -> i32 {
  return Twice(x);
}
