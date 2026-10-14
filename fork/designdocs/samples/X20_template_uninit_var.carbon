// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: cannot convert type `T` into type implementing `Core.DefaultOrUnformed`
// QUOTE: cannot convert type `T` into type implementing `Core.DefaultOrUnformed`
// Pins the page's limit on a `var` of a template parameter's type without an
// initializer: it is rejected where the function is defined (fork work item
// W-127, held PR 51), where proposal 2200 delays impl lookup until the
// template argument is known. `var y: i32;` in the same position compiles.

fn F[template T: type](x: T) -> T {
  var y: T;
  y = x;
  return y;
}

fn Use() -> i32 {
  return F(5 as i32);
}
