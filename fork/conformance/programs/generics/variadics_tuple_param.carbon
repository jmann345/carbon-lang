// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   112
//   4
//   71
//   0
//
// A tuple type of one pack segment, `(... each T)`, is a parameter's type and
// a return type (docs/design/variadics.md, "Tuples, packs, segments, and
// shapes"), the tuple-typed parameter and return that the design's Apply and
// TupleConcat signatures use; those signatures themselves also need a
// variadic `Core.Call`, a second implicit-list pack, a tuple of two segments
// and `...expand`. SumTuple deduces its pack of types from its argument's
// tuple type and binds the elements with `let (... each x: each T) = t;`
// ("Pack expansion patterns"): (100, 10, 2) of types (i32, i64, i16) sums to
// 112. MakeTuple returns `(... each x)`, the tuple of its arguments ("`...` in
// a tuple literal behaves like a series of comma-separated tuple elements"):
// SumTuple(MakeTuple(1 as i32, 3 as i64)) is 4, and MakeTuple(70 as i32,
// true, 1 as i32) is an (i32, bool, i32) whose elements 0 and 2 sum to 71. The
// empty tuple has an empty pack: SumTuple(()) is 0.

import Core library "io";

fn SumTuple[... each T: Core.ImplicitAs(i64)](t: (... each T)) -> i64 {
  let (... each x: each T) = t;
  var total: i64 = 0;
  ... total += each x as i64;
  return total;
}

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}

fn Run() -> i32 {
  let t: (i32, i64, i16) = (100, 10, 2);
  Core.Print(SumTuple(t) as i32);
  Core.Print(SumTuple(MakeTuple(1 as i32, 3 as i64)) as i32);
  let u: (i32, bool, i32) = MakeTuple(70 as i32, true, 1 as i32);
  Core.Print(u.0 + u.2);
  Core.Print(SumTuple(()) as i32);
  return 0;
}
