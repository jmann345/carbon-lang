// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/pattern_matching.md, "`match` in the 0.1 toolchain", block
// EXPECT-ERROR: expected `(` after `if`

fn F(x: (i32, i32)) -> i32 {
  match (x) {
    case (m: i32, n: i32) if m + n < 5 => { return m - n; }
    default => { return 0; }
  }
}
