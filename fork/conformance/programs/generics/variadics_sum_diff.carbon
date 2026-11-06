// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
//
// Differential pair: variadics_sum_diff.diff.cpp computes the same values
// with C++17 variadic templates and comma folds, which evaluate their
// operands left to right as Carbon's statement expansion executes its body
// once per element in order (docs/design/variadics.md, "Expressions and
// statements"), so C++ is the oracle for every printed line (no
// EXPECT-STDOUT). Horner evaluates a polynomial whose coefficients are the
// pack, which is order-sensitive; SumOfSquares forwards an expansion whose
// body is an expression of the element, `... each n * each n`, to Sum; the
// empty pack runs no iteration on either side.

import Core library "io";

fn Horner(x: i64, ... each c: i64) -> i64 {
  var total: i64 = 0;
  ... total = total * x + each c;
  return total;
}

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total += each n;
  return total;
}

fn SumOfSquares(... each n: i64) -> i64 {
  return Sum(... each n * each n);
}

fn Run() -> i32 {
  Core.Print(Horner(10, 1, 2, 3) as i32);
  Core.Print(Horner(2, 1, 0, 1, 1) as i32);
  Core.Print(Horner(7) as i32);
  Core.Print(SumOfSquares(1, 2, 3, 4) as i32);
  Core.Print(SumOfSquares() as i32);
  return 0;
}
