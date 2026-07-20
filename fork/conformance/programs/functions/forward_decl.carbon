// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: separate declaration and definition
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   55
//   42
//
// A file-scope function declared before it is defined (also exercising
// recursion), and a method declared inside a class and defined out of line.
// Shapes verbatim from toolchain/check/testdata/function/definition/
// forward_decl.carbon (`fn Foo(); ... fn Foo() {}`), examples/advent2024/
// io_utils.carbon (`fn CharOrEOF.EOF() -> Self;` declared in class, defined
// out of line), and toolchain/check/testdata/class/inheritance/
// base_method.carbon (`fn Base.F(ref self)` out-of-line definition).

import Core library "io";

fn Fib(n: i32) -> i32;

class Widget {
  fn Weight(self) -> i32;
  var size: i32;
}

fn Widget.Weight(self) -> i32 {
  return self.size * 3;
}

fn Fib(n: i32) -> i32 {
  if (n < 2) { return n; }
  return Fib(n - 1) + Fib(n - 2);
}

fn Run() -> i32 {
  Core.Print(Fib(10));
  var w: Widget = {.size = 14};
  Core.Print(w.Weight());
  return 0;
}
