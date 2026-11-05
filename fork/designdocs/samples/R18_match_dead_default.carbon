// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/pattern_matching.md, "`match` in the 0.1 toolchain", block
// EXPECT-ERROR: `default` arm never matches; every value of the scrutinee is matched by prior arms

fn F(b: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    case false => { return 0; }
    default => { return 2; }
  }
  return 3;
}
