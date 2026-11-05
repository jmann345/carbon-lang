// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   4
// QUOTE: `Deref(&n)` returns 4
// Pins the resolution, by TP-1 (fork/templates/plan.md), of the page's limit
// on prefix `*` with a template-dependent operand: `*p` is checked when
// `Deref(&n)` is instantiated for an `i32*`, and the program prints 4. Before
// TP-1 the definition was rejected with ``cannot dereference operand of
// non-pointer type `T` `` (fork work item W-014). Proposal 2200's "Use of
// dependent value is dependent" section makes the expression dependent.

import Core library "io";

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Run() -> i32 {
  var n: i32 = 4;
  Core.Print(Deref(&n));
  return 0;
}
