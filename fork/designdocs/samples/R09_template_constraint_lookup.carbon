// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", block
// EXPECT-STDOUT:
//   25
// QUOTE: This prints `25`: `s.Area()` finds `Area` in the constraint `HasArea`

import Core library "io";

interface HasArea {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  impl as HasArea {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Run() -> i32 {
  let q: Square = {.side = 5};
  Core.Print(Report(q));
  return 0;
}
