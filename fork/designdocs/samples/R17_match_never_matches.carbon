// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/pattern_matching.md, "`match` in the 0.1 toolchain", block
// EXPECT-ERROR: `case` pattern never matches; every value it can match is matched by a prior arm

fn F(n: i32) -> i32 {
  match (n) {
    case x: i32 => { return x; }
    case 0 => { return 0; }
  }
  return 1;
}
