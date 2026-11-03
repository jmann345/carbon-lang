// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/pattern_matching.md, "`match` in the 0.1 toolchain", block
// EXPECT-ERROR: `match` on `i32` has no `default` arm and no `case` arm that matches every value

fn F(n: i32) -> i32 {
  match (n) {
    case 0 => { return 0; }
    case 1 => { return 1; }
  }
  return 2;
}
