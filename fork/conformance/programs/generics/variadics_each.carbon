// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   6
//   0
//
// A definition-checked variadic Sum whose parameter list binds a pack
// (`... each n: i64`) and whose body statement-expands it
// (`... total += each n;`): the design's own SumInts example
// (docs/design/variadics.md, "Additional examples"), renamed. Called with
// three arguments and with zero, so both the n-ary and the empty expansion
// execute: 1 + 2 + 3 = 6, and the empty sum is the initial 0. The body is
// the write-tests-first stub's, uncommented; the only change is `as i32` on
// each printed sum, because Core.Print takes an i32 (core/io.carbon:12) and
// i64 does not implicitly convert to i32.

import Core library "io";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total += each n;
  return total;
}

fn Run() -> i32 {
  Core.Print(Sum(1, 2, 3) as i32);
  Core.Print(Sum() as i32);
  return 0;
}
