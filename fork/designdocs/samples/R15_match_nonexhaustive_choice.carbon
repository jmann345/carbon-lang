// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/pattern_matching.md, "`match` in the 0.1 toolchain", block
// EXPECT-ERROR: `match` on choice `Signal` has no `default` arm and does not cover alternative `.Wait`

choice Signal { Stop, Go, Wait }

fn F(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    case .Go => { return 1; }
  }
  return 2;
}
