// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/blocks_and_statements.md, "Statements in the 0.1 toolchain", block
// EXPECT-ERROR: missing `return` at end of function with declared return type

fn F(b: bool) -> i32 {
  if (b) {
    return 1;
  }
}
