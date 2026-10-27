// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   7
//   3
//   12
//   33
//
// An empty pack of types has arity 0 and runs no iteration
// (docs/design/variadics.md, "Execution Semantics"): Count() is 0, printed
// before the 7 printed between the calls, and Count(true, 1 as i64, false)
// counts three elements of two types. Around's fixed parameters take the
// first and the last argument and its pack the run between them ("Pattern
// matching"): Around(1, 2) has an empty pack, so (1 + 0) * 10 + 2 is 12;
// Around(1, true, 2 as i64, 3) has the pack (true, 2 as i64), forwarded to
// Count, so (1 + 2) * 10 + 3 is 33.

import Core library "io";

fn One[V: type](unused v: V) -> i32 {
  return 1;
}

fn Count[... each T: type](... each x: each T) -> i32 {
  var n: i32 = 0;
  ... n += One(each x);
  return n;
}

fn Around[... each T: type](first: i32, ... each x: each T, last: i32) -> i32 {
  return (first + Count(... each x)) * 10 + last;
}

fn Run() -> i32 {
  Core.Print(Count());
  Core.Print(7);
  Core.Print(Count(true, 1 as i64, false));
  Core.Print(Around(1, 2));
  Core.Print(Around(1, true, 2 as i64, 3));
  return 0;
}
