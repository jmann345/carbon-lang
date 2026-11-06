// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   12
//   123
//   4321
//
// A pack between two fixed parameters, the shape of the design's
// MiddleVariadic (docs/design/variadics.md, "Additional examples"): the
// first argument matches `first`, the last matches `last`, and the run
// between them is the pack (docs/design/variadics.md, "Pattern matching").
// The body appends one decimal digit per element in order, so the output
// pins the split and the iteration order: Digits(1, 2) has an empty pack,
// 1 then 12; Digits(1, 2, 3) has the pack (2), 1, 12, then 123;
// Digits(4, 3, 2, 1) has the pack (3, 2), 4, 43, 432, then 4321.

import Core library "io";

fn Digits(first: i64, ... each mid: i64, last: i64) -> i64 {
  var total: i64 = first;
  ... total = total * 10 + each mid;
  return total * 10 + last;
}

fn Run() -> i32 {
  Core.Print(Digits(1, 2) as i32);
  Core.Print(Digits(1, 2, 3) as i32);
  Core.Print(Digits(4, 3, 2, 1) as i32);
  return 0;
}
