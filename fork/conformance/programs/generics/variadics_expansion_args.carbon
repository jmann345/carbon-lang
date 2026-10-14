// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   19
//   1239
//   15559
//
// A pack expansion argument between two fixed arguments: the call's
// argument list is a tuple literal of three segments, `first`,
// `... each x * 5` and `9`, and the callee's pattern `(first: i64,
// ... each mid: i64, last: i64)` matches the outer segments to the fixed
// parameters and the expansion to the pack (docs/design/variadics.md,
// "Typechecking pattern matches"). Digits appends one decimal digit per
// argument in order.
// Scaled(1) calls Digits(1, 9) for an empty pack: 19. Plain(1, 2, 3) calls
// Digits(1, 2, 3, 9): 1239. Scaled(1, 1, 1, 1) calls Digits(1, 5, 5, 5,
// 9): the leading 1 is `first`, each of the three remaining elements
// becomes 5: 15559.

import Core library "io";

fn Digits(first: i64, ... each mid: i64, last: i64) -> i64 {
  var total: i64 = first;
  ... total = total * 10 + each mid;
  return total * 10 + last;
}

fn Plain(first: i64, ... each x: i64) -> i64 {
  return Digits(first, ... each x, 9);
}

fn Scaled(first: i64, ... each x: i64) -> i64 {
  return Digits(first, ... each x * 5, 9);
}

fn Run() -> i32 {
  Core.Print(Scaled(1) as i32);
  Core.Print(Plain(1, 2, 3) as i32);
  Core.Print(Scaled(1, 1, 1, 1) as i32);
  return 0;
}
