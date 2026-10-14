// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: cannot apply `->` operator to non-pointer type `<dependent type>`
// QUOTE: cannot apply `->` operator to non-pointer type `<dependent type>`
// Pins the page's limit on `->` with a template-dependent operand: `x.p` has a
// type known only at instantiation, and `x.p->n` is rejected where the
// function is defined (fork work item W-014).

class Node {
  var n: i32;
}

class Link {
  var p: Node*;
}

fn Next[template T: type](x: T) -> i32 {
  return x.p->n;
}

fn Use() -> i32 {
  var node: Node = {.n = 4};
  let link: Link = {.p = &node};
  return Next(link);
}
