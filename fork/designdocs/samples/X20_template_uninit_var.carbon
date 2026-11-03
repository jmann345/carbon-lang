// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   5
// QUOTE: `F(5 as i32)` returns 5
// Pins the resolution, by TP-1, of the page's limit on a `var` of a template
// parameter's type without an initializer: impl lookup for `T` is delayed
// until `F` is instantiated, as proposal 2200 specifies, and the program
// prints 5. Before TP-1 the definition was rejected with ``cannot convert type
// `T` into type implementing `Core.DefaultOrUnformed` `` (fork work item
// W-127).

import Core library "io";

fn F[template T: type](x: T) -> T {
  var y: T;
  y = x;
  return y;
}

fn Run() -> i32 {
  Core.Print(F(5 as i32));
  return 0;
}
