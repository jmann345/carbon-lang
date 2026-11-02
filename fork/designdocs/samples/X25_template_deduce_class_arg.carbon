// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Functions with template parameters", quote
// EXPECT-ERROR: cannot deduce value for generic parameter `T`
// QUOTE: cannot deduce value for generic parameter `T`
// Pins the fork note after the overview's `Convert` example: a deduced
// template parameter is not deduced from a class's arguments, so
// `GetTemplate(h)` is rejected, while `GetChecked(h)`, the same declaration
// with a checked parameter, deduces `T` as `i32` (fork work item W-193). The
// plan's section 4.3 records the `Holder(T)*` and `Vec(N)` forms.

class Holder(T: type) {
  var item: T;
}

fn GetChecked[T: Core.Copy](h: Holder(T)) -> T {
  return h.item;
}

fn GetTemplate[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Use(h: Holder(i32)) -> i32 {
  return GetChecked(h) + GetTemplate(h);
}
