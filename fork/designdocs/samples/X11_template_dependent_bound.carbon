// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: cannot initialize array with dependent bound from a list of initializers
// QUOTE: cannot initialize array with dependent bound from a list of initializers
// Pins the page's limit on an array whose bound is a template parameter: it
// cannot be initialized from a list of values (the toolchain's own split
// fail_todo_init_template_dependent_bound.carbon in
// toolchain/check/testdata/array/init_dependent_bound.carbon). The upstream
// nightly accepts this file, as the page says (the plan's probe PR-AA, section
// 4.3, runs it).

fn F(template N: i32) -> i32 {
  var a: array(i32, N) = (1, 2, 3);
  return 0;
}

fn Use() -> i32 {
  return F(3);
}
