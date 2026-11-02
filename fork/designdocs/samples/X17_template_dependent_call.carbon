// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   8
// QUOTE: `Apply(Twice, 4)` calls `Twice` and returns 8
// Pins the resolution, by TP-1, of the page's limit on calling a value whose
// type is a template parameter: `h(x)` calls the function that `G`, the type
// of `Twice`, names (proposal 2875 gives each function its own type), and the
// program prints 2 x 4. Before TP-1 the call failed when `Apply(Twice, 4)`
// was instantiated, with the note ``value of type `<type of Twice>` is not
// callable`` (fork work item W-014).

import Core library "io";

fn Apply[template G: type](h: G, x: i32) -> i32 {
  return h(x);
}

fn Twice(x: i32) -> i32 {
  return 2 * x;
}

fn Run() -> i32 {
  Core.Print(Apply(Twice, 4));
  return 0;
}
