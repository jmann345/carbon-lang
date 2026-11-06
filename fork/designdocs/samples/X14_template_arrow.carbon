// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   4
// QUOTE: `Next(link)` returns 4
// Pins the resolution, by TP-1, of the page's limit on `->` with a
// template-dependent operand: `x.p->n` is checked when `Next(link)` is
// instantiated, and the program prints `node.n`, 4. Before TP-1 the
// definition was rejected with ``cannot apply `->` operator to non-pointer
// type `<dependent type>` `` (fork work item W-014).

import Core library "io";

class Node {
  var n: i32;
}

class Link {
  var p: Node*;
}

fn Next[template T: type](x: T) -> i32 {
  return x.p->n;
}

fn Run() -> i32 {
  var node: Node = {.n = 4};
  let link: Link = {.p = &node};
  Core.Print(Next(link));
  return 0;
}
