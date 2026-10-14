// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/pattern_matching.md, "`match` in the 0.1 toolchain", block
// EXPECT-ERROR: missing `return` at end of function with declared return type

fn IsTrue(b: bool) -> bool {
  match (b) {
    case false => { return false; }
    case true => { return true; }
  }
}
