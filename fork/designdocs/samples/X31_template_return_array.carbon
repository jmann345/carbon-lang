// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: ResolveSpecificDefinition
// QUOTE: the upstream nightly runs the `array(T, 2)` form
// Pins the array form of the page's limit on returning a value of a type built
// from a template parameter (fork work item W-014). The fork toolchain stops;
// the upstream nightly compiles it, and a program that prints `Use()` prints 8
// there, so this fixture is one of the predicted nightly differences. With
// `[T: Core.Copy]`, such a program prints 8 on the fork toolchain too.

fn Two[template T: type](x: T) -> array(T, 2) {
  return (x, x);
}

fn Use() -> i32 {
  let a: array(i32, 2) = Two(4 as i32);
  return a[0] + a[1];
}
