// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
//
// Proposal 2200: returning, copying and destructuring values whose types are
// built from template parameters, checked and lowered for each instantiation
// (TP-1, fork/templates/plan.md; DD-1 fixtures X29 to X33 and probe PR-AK,
// which printed values that changed from run to run). Differential pair:
// templates_return_aggregates_diff.diff.cpp computes the expected lines with
// the same templates in C++17 (no EXPECT-STDOUT). Dup(4) sums 4 + 4 = 8;
// Mk(5) sums 5 + 5 = 10; Two(4) sums 4 + 4 = 8; H(i32).Both with a = 3 sums
// 3 + 3 = 6; Sum((4, 5)) is 9; Id((4, 5)) prints 4 then 5; Id of
// {.x = 6, .y = 7} has .y = 7; G(3) returns ((3, 3), 1), which sums to 7.

import Core library "io";

fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Mk[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = x};
}

fn Two[template T: type](x: T) -> array(T, 2) {
  return (x, x);
}

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((T, T), i32) {
  return (Pair(x), 1);
}

fn Run() -> i32 {
  let t: (i32, i32) = Dup(4 as i32);
  Core.Print(t.0 + t.1);
  let s: {.a: i32, .b: i32} = Mk(5 as i32);
  Core.Print(s.a + s.b);
  let a: array(i32, 2) = Two(4 as i32);
  Core.Print(a[0] + a[1]);
  let h: H(i32) = {.a = 3};
  let u: (i32, i32) = h.Both();
  Core.Print(u.0 + u.1);
  let p: (i32, i32) = (4, 5);
  Core.Print(Sum(p));
  let r: (i32, i32) = Id(p);
  Core.Print(r.0);
  Core.Print(r.1);
  let q: {.x: i32, .y: i32} = {.x = 6, .y = 7};
  Core.Print(Id(q).y);
  let n: ((i32, i32), i32) = G(3 as i32);
  Core.Print(n.0.0 + n.0.1 + n.1);
  return 0;
}
