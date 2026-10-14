// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   2
//   8
//
// Proposal 2200 ("Use of dependent value is dependent"): tuple element access
// and indexing on a template-dependent operand are checked when the template
// is instantiated, as a tuple access and an array index (TP-1; DD-1 fixtures
// X16, X19, X24). Element 1 of (4, 5) is 5; element 1 of (1, 2, 3) is 2;
// element 0 of the class member (8, 9) is 8. The same code with the types
// written out prints the same three lines.

import Core library "io";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn At1[template T: type](a: T) -> i32 {
  return a[1];
}

class Holder(template T: type) {
  var item: T;
  fn First(self) -> i32 { return self.item[0]; }
}

fn Run() -> i32 {
  let t: (i32, i32) = (4, 5);
  Core.Print(Second(t));
  let a: array(i32, 3) = (1, 2, 3);
  Core.Print(At1(a));
  let h: Holder(array(i32, 2)) = {.item = (8, 9)};
  Core.Print(h.First());
  return 0;
}
