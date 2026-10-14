// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
//   2
//   2
//
// A pack whose element type is a deduced parameter: in
// `Count[T: type](... each x: T)` the body is checked once, with `each x` of
// type `T` (docs/design/variadics.md, "Iterative typechecking of pack
// expansions"), and each call deduces `T` and the arity. One returns 1 for
// any value, so Count returns the pack's arity: Count(true, false, true) is
// 3; Forward(7 as i64, 8 as i64) passes its pack on with `... each x`, 2; and
// Count(l, m) deduces `T` as Loud, whose Copy prints 100 plus its field, and
// prints only 2, because binding a pack copies nothing.

import Core library "io";

class Loud {
  var a: i32;
}

impl Loud as Core.Copy {
  fn Op(self) -> Self {
    Core.Print(100 + self.a);
    return {.a = self.a};
  }
}

fn One[T: type](unused x: T) -> i32 {
  return 1;
}

fn Count[T: type](... each x: T) -> i32 {
  var n: i32 = 0;
  ... n += One(each x);
  return n;
}

fn Forward[T: type](... each x: T) -> i32 {
  return Count(... each x);
}

fn Run() -> i32 {
  Core.Print(Count(true, false, true));
  Core.Print(Forward(7 as i64, 8 as i64));
  let l: Loud = {.a = 3};
  let m: Loud = {.a = 4};
  Core.Print(Count(l, m));
  return 0;
}
