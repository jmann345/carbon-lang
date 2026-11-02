// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: unable to monomorphize specific `Id({.x: i32, .y: i32})`
// QUOTE: cannot access member of interface `Core.Copy` in type `{.x: i32, .y: i32}` that does not implement that interface
// Pins the page's limit on copying a value whose type is a template argument
// of struct type: `return p;` fails when `Id` is instantiated for
// `{.x: i32, .y: i32}` (fork work item W-192), although the same function
// with `p: {.x: i32, .y: i32}` runs. The quote is the note under the error.

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Use() -> i32 {
  let s: {.x: i32, .y: i32} = {.x = 4, .y = 5};
  return Id(s).y;
}
