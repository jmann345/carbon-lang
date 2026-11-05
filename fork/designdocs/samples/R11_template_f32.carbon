// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Functions with template parameters", quote
// EXPECT-ERROR: unable to monomorphize specific `Convert(i32, f32)`
// QUOTE: unable to monomorphize specific `Convert(i32, f32)`

fn Convert[template T: type](source: T, template U: type) -> U {
  var converted: U = source;
  return converted;
}

fn Foo(i: i32) -> f32 {
  return Convert(i, f32);
}
