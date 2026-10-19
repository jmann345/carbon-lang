// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   21
//   42
//   3
//   16
//   8
//
// Proposal 2200 (p002200:186-191: template parameters are deduced as checked
// ones are): a deduced template parameter is deduced through a class's
// arguments (TP-1; DD-1 fixture X25). Get(h) is the item, 21; GetThrough(&h)
// reads the item through the pointer, and the program
// doubles it, 42; Size(v) is the deduced N of Vec(3), 3. A class template's
// array field whose bound is the template parameter is initialized from a
// list on instantiation (TP-1): SumArr(3, 10) adds the first and third
// elements of `(10, 2, 3)` and N, 10 + 3 + 3, 16; MakeArr(3) returns such a
// class value, whose second element and N sum to 5 + 3, 8.

import Core library "io";

class Holder(T: type) {
  var item: T;
}

class Vec(template N: i32) {
  var tag: i32;
}

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn GetThrough[template T: type](h: Holder(T)*) -> T {
  return h->item;
}

fn Size[template N: i32](unused v: Vec(N)) -> i32 {
  return N;
}

fn SumArr(template N: i32, x: i32) -> i32 {
  var c: Arr(N) = {.a = (x, 2, 3), .n = N};
  return c.a[0] + c.a[2] + c.n;
}

fn MakeArr(template N: i32) -> Arr(N) {
  return {.a = (4, 5, 6), .n = N};
}

fn Run() -> i32 {
  var h: Holder(i32) = {.item = 21};
  Core.Print(Get(h));
  Core.Print(GetThrough(&h) * 2);
  let v: Vec(3) = {.tag = 0};
  Core.Print(Size(v));
  Core.Print(SumArr(3, 10));
  let m: Arr(3) = MakeArr(3);
  Core.Print(m.a[1] + m.n);
  return 0;
}
