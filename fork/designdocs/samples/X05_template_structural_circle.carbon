// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: cannot convert type `Circle` into type implementing `HasArea`
// QUOTE: cannot convert type `Circle` into type implementing `HasArea`
// Pins the page's sentence on interface constraints: a class `Circle` with a
// matching `Area` method and no `impl` does not satisfy `HasArea`, as the
// accepted design specifies, so the call is rejected.

interface HasArea {
  fn Area(self) -> i32;
}

class Circle {
  var radius: i32;
  fn Area(self) -> i32 { return 3 * self.radius * self.radius; }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Use(c: Circle) -> i32 {
  return Report(c);
}
