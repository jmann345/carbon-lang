// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   5
// QUOTE: `Id(s).y` returns 5
// Pins the resolution, by TP-1, of the page's limit on copying a value whose
// type is a template argument of struct type: `return p;` copies the struct
// field by field when `Id` is instantiated for `{.x: i32, .y: i32}`, and the
// program prints the copy's `.y`, 5. Before TP-1 the instantiation failed
// with the note ``cannot access member of interface `Core.Copy` in type
// `{.x: i32, .y: i32}` that does not implement that interface`` (fork work
// item W-192).

import Core library "io";

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Run() -> i32 {
  let s: {.x: i32, .y: i32} = {.x = 4, .y = 5};
  Core.Print(Id(s).y);
  return 0;
}
