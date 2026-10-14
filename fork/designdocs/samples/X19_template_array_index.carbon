// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: unable to monomorphize specific `Second(array(i32, 3))`
// QUOTE: cannot access member of interface `Core.IndexWith(Core.IntLiteral)` in type `array(i32, 3)` that does not implement that interface
// Pins the page's limit on indexing a value whose type is a template argument
// of array type: `a[1]` fails when `Second` is instantiated for
// `array(i32, 3)` (fork work item W-192), although the same function with
// `a: array(i32, 3)` runs. The quote is the note under the error.

fn Second[template T: type](a: T) -> i32 {
  return a[1];
}

fn Use() -> i32 {
  let a: array(i32, 3) = (1, 2, 3);
  return Second(a);
}
