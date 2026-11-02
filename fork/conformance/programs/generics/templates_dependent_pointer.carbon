// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   7
//   8
//
// Proposal 2200 ("Use of dependent value is dependent"): `*`, `->` and `&`
// on a template-dependent operand are checked when the template is
// instantiated (TP-1, fork/templates/plan.md; DD-1 fixtures X13, X14, X15).
// Deref(&n) reads n = 4; Next(link) reads link.p->n = node.n = 7; Bump(ref
// node) adds 1 to node.n through &node.n and returns 8. The same functions
// with the types written out print the same three lines.

import Core library "io";

class Node {
  var n: i32;
}

class Link {
  var p: Node*;
}

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Next[template T: type](x: T) -> i32 {
  return x.p->n;
}

fn Bump[template T: type](ref x: T) -> i32 {
  let q: i32* = &x.n;
  *q += 1;
  return x.n;
}

fn Run() -> i32 {
  var n: i32 = 4;
  Core.Print(Deref(&n));
  var node: Node = {.n = 7};
  let link: Link = {.p = &node};
  Core.Print(Next(link));
  Core.Print(Bump(ref node));
  return 0;
}
