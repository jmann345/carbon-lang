// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/metaprogramming.md, "Compile-time evaluation in the 0.1 toolchain", block
// EXPECT-ERROR: semantics TODO: `local generic `let` bindings are currently unsupported`

fn F() -> i32 {
  let template N: i32 = 3;
  return N;
}
