// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//   3
//   9
//   1239
//   1
//   9
//   19
//
// A pack expansion argument is evaluated where it is written: "`...` in a
// tuple literal behaves like a series of comma-separated tuple elements"
// (docs/design/variadics.md, "Pack expansion expressions and statements"),
// and a call's arguments are evaluated in written order
// (docs/design/pattern_matching.md, "Evaluation order"). Echo prints its
// argument and returns it, so Plain(2, 3), which calls
// Digits(Echo(1), ... Echo(each x), Echo(9)), behaves like
// Digits(Echo(1), Echo(2), Echo(3), Echo(9)): it prints 1, 2, 3 and 9 in that
// order, then Digits appends one decimal digit per argument, 1239. Plain()
// has an empty pack: it prints 1 and 9, then 19.

import Core library "io";

fn Echo(x: i64) -> i64 {
  Core.Print(x as i32);
  return x;
}

fn Digits(first: i64, ... each mid: i64, last: i64) -> i64 {
  var total: i64 = first;
  ... total = total * 10 + each mid;
  return total * 10 + last;
}

fn Plain(... each x: i64) -> i64 {
  return Digits(Echo(1), ... Echo(each x), Echo(9));
}

fn Run() -> i32 {
  Core.Print(Plain(2, 3) as i32);
  Core.Print(Plain() as i32);
  return 0;
}
