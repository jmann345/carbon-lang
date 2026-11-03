// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   7
//
// A pack of a struct whose layout has tail padding (W-368): each element is
// read at its array stride. Expected: `F` sums the `.a` fields, 1 + 2 + 4 = 7,
// for constants and for values built at run time.

import Core library "io";

fn F(... each x: {.a: i32, .b: bool}) -> i32 {
  var n: i32 = 0;
  ... n = n + each x.a;
  return n;
}

fn Make(a: i32) -> {.a: i32, .b: bool} { return {.a = a, .b = true}; }

fn Run() -> i32 {
  Core.Print(F({.a = 1, .b = true}, {.a = 2, .b = false},
               {.a = 4, .b = true}));
  Core.Print(F(Make(1), Make(2), Make(4)));
  return 0;
}
