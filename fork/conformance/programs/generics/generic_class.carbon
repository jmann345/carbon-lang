// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: generic functions and types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   1
//
// A generic class parameterized by a type, created through a generic factory
// function with a deduced type parameter, then used at a concrete type.
// Shapes verbatim from toolchain/lower/testdata/class/generic.carbon
// (create_generic: `class A(T: type) { var x: T; var y: T; }` and
// `fn Make[T: Core.Copy](x: T, y: T) -> A(T) { return {.x = x, .y = y}; }`),
// plus a class value parameter as in toolchain/lower/testdata/class/
// base.carbon (`fn Access(d: Derived) -> ...`).

import Core library "io";

class Pair(T: type) {
  var first: T;
  var second: T;
}

fn MakePair[T: Core.Copy](x: T, y: T) -> Pair(T) {
  return {.first = x, .second = y};
}

fn SumPair(p: Pair(i32)) -> i32 {
  return p.first + p.second;
}

fn Run() -> i32 {
  let a: i32 = 40;
  let b: i32 = 2;
  var p: Pair(i32) = MakePair(a, b);
  Core.Print(SumPair(p));

  var q: Pair(bool) = MakePair(true, false);
  if (q.first) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
  return 0;
}
