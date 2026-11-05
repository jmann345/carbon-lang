// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", block
// EXPECT-ERROR: unable to monomorphize specific `GetX(Empty)`

class Empty {}

fn GetX[template T: type](p: T) -> i32 {
  return p.x;
}

fn Use(e: Empty) -> i32 {
  return GetX(e);
}
