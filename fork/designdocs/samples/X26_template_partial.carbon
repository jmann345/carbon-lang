// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: `partial` applied to final type `T`
// QUOTE: `partial` applied to final type `T`
// Pins the page's limit on `partial T*` for a template parameter `T`: it is
// rejected as for a checked parameter, which the toolchain's own split
// fail_todo_partial_template_dependent.carbon in
// toolchain/check/testdata/class/partial/qualifier.carbon pins with the
// comment that it should be accepted for a template parameter.

base class Base {
  var n: i32;
}

fn G[template T: type](p: partial T*);

fn Use(b: partial Base*) {
  G(b);
}
