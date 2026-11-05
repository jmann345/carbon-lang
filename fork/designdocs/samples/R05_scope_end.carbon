// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/blocks_and_statements.md, "Statements in the 0.1 toolchain", block
// EXPECT-ERROR: name `inner` not found

fn F(b: bool) -> i32 {
  if (b) {
    var inner: i32 = 1;
    inner += 1;
  }
  return inner;
}
