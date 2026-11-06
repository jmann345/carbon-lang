// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   8
//   25
//
// Proposal 2200 (p002200:735-737: calling a function needs only its type)
// and proposal 2875 (each function has its own type): a value whose type is a
// template parameter is called, with the function its type names (TP-1; DD-1
// fixture X17). Apply(Twice, 4) is 2 x 4 = 8; Apply(Square, 5) is 5 x 5 = 25.

import Core library "io";

fn Apply[template G: type](h: G, x: i32) -> i32 {
  return h(x);
}

fn Twice(x: i32) -> i32 {
  return 2 * x;
}

fn Square(x: i32) -> i32 {
  return x * x;
}

fn Run() -> i32 {
  Core.Print(Apply(Twice, 4));
  Core.Print(Apply(Square, 5));
  return 0;
}
