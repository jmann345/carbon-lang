// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   21
//   42
//   3
//
// Proposal 2200 (p002200:186-191: template parameters are deduced as checked
// ones are): a deduced template parameter is deduced through a class's
// arguments (TP-1; DD-1 fixture X25 and fork work item W-193). Get(h) is the
// item, 21; GetThrough(&h) reads the item through the pointer, and the program
// doubles it, 42; Size(v) is the deduced N of Vec(3), 3.

import Core library "io";

class Holder(T: type) {
  var item: T;
}

class Vec(template N: i32) {
  var tag: i32;
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

fn Run() -> i32 {
  var h: Holder(i32) = {.item = 21};
  Core.Print(Get(h));
  Core.Print(GetThrough(&h) * 2);
  let v: Vec(3) = {.tag = 0};
  Core.Print(Size(v));
  return 0;
}
