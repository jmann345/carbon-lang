// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: unrecognized declaration introducer
// QUOTE: unrecognized declaration introducer
// Pins the page's limit on `template constraint` declarations, which proposals
// 818 and 2200 specify: the parser does not recognize the introducer (the
// toolchain's own split fail_todo_template_constraint.carbon in
// toolchain/parse/testdata/generics/named_constraint/). The fork's held
// template-constraint branch (SC-1) parses and checks this file; at state L
// this fixture is removed with the limit (plan section 2.4).

template constraint HasF {
  fn F(self);
}
