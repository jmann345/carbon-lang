// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   123
//   246
//   0
//   8
//   456
//
// A variadic function forwards its pack to another with a pack expansion
// argument, `... each d` or `... each d + each d`: "`...` in a tuple
// literal behaves like a series of comma-separated tuple elements"
// (docs/design/variadics.md, "Pack expansion expressions and statements"),
// so Forward(1, 2, 3) calls Digits(1, 2, 3) and Doubled(1, 2, 3) calls
// Digits(2, 4, 6). Digits appends one decimal digit per element in order:
// 123, then 246; Forward() forwards an empty pack, 0; Doubled(4) is
// Digits(8), 8. The callee's arity is deduced from the expansion's at each
// caller specific. Narrowed(4, 5, 6) passes `... ToI32(each d)`, a pack of
// i32 values 4, 5 and 6, which the call converts element by element to
// Digits' i64 ("`...T` is convertible to `...U` if [...] the scalar
// components of `T` are each convertible to all scalar components of `U`",
// docs/design/variadics.md, "Equivalence, equality, and convertibility"):
// Digits(4, 5, 6), 456. No other parameter or argument has the type of
// that pack of i32, so only the expansion requires it to be complete.

import Core library "io";

fn Digits(... each d: i64) -> i64 {
  var total: i64 = 0;
  ... total = total * 10 + each d;
  return total;
}

fn Forward(... each d: i64) -> i64 {
  return Digits(... each d);
}

fn Doubled(... each d: i64) -> i64 {
  return Digits(... each d + each d);
}

fn ToI32(x: i64) -> i32 {
  return x as i32;
}

fn Narrowed(... each d: i64) -> i64 {
  return Digits(... ToI32(each d));
}

fn Run() -> i32 {
  Core.Print(Forward(1, 2, 3) as i32);
  Core.Print(Doubled(1, 2, 3) as i32);
  Core.Print(Forward() as i32);
  Core.Print(Doubled(4) as i32);
  Core.Print(Narrowed(4, 5, 6) as i32);
  return 0;
}
