// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Functions with template parameters", quote
// EXPECT-STDOUT:
//   42
// QUOTE: `GetTemplate(h)` deduces `T` as `i32` from `Holder(T)`
// Pins the resolution, by TP-1, of the fork note after the overview's
// `Convert` example: a deduced template parameter is deduced from a class's
// arguments, so `GetTemplate(h)` and `GetChecked(h)` both deduce `T` as `i32`
// and the program prints 21 + 21. Before TP-1 `GetTemplate(h)` was rejected
// with ``cannot deduce value for generic parameter `T` `` (fork work item
// W-193). The `Holder(T)*` and `Vec(N)` forms are pinned by the toolchain's
// generic/template/deduce_class_args.carbon.

import Core library "io";

class Holder(T: type) {
  var item: T;
}

fn GetChecked[T: Core.Copy](h: Holder(T)) -> T {
  return h.item;
}

fn GetTemplate[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Run() -> i32 {
  let h: Holder(i32) = {.item = 21};
  Core.Print(GetChecked(h) + GetTemplate(h));
  return 0;
}
