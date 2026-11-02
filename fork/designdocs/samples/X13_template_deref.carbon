// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: cannot dereference operand of non-pointer type `T`
// QUOTE: cannot dereference operand of non-pointer type `T`
// Pins the page's limit on prefix `*` with a template-dependent operand: it is
// checked where the function is defined and rejected, although the only call
// passes an `i32*` (fork work item W-014; the toolchain's own split
// fail_todo_unimplemented_operator.carbon in
// toolchain/check/testdata/generic/template/unimplemented.carbon pins `*x.n`).
// Proposal 2200's "Use of dependent value is dependent" section makes the
// expression dependent, checked when the call is instantiated.

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Use() -> i32 {
  var n: i32 = 4;
  return Deref(&n);
}
