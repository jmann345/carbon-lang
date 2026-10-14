// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: unable to monomorphize specific `Apply(<type of Twice>)`
// QUOTE: value of type `<type of Twice>` is not callable
// Pins the page's limit on calling a value whose type is a template parameter:
// `h(x)` fails when `Apply(Twice, 4)` is instantiated (fork work item W-014;
// the toolchain's own split fail_todo_dependent_call_nonconst_arg.carbon in
// toolchain/check/testdata/generic/template/call.carbon). The quote is the
// note under the error.

fn Apply[template G: type](h: G, x: i32) -> i32 {
  return h(x);
}

fn Twice(x: i32) -> i32 {
  return 2 * x;
}

fn Use() -> i32 {
  return Apply(Twice, 4);
}
