// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Functions with template parameters", quote
// EXPECT-ERROR: cannot deduce value for generic parameter `T`
// QUOTE: `GetTemplate(h)` is rejected again with ``cannot deduce value for generic parameter `T` ``
// Pins the withdrawal, by TP-2, of the deduction that TP-1 implemented (the
// fork notes after the overview's `Convert` example): since every call whose
// argument depends on a template parameter is deferred, `Holder(T)` in the
// parameter's type is a deferred call, so `GetTemplate(h)` is rejected at its
// call with the message above (the first error), while `GetChecked(h)`, whose
// parameter is checked, still deduces `T` as `i32` (fork work items W-193,
// resolved by TP-1, and W-396, filed by TP-2). Before TP-2 this fixture ran
// and printed 42. The `Holder(T)*` and `Vec(N)` forms are pinned by the
// toolchain's generic/template/deduce_class_args.carbon (`fail_todo_` splits).

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
