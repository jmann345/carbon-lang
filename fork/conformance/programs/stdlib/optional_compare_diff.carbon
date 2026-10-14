// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
//
// Differential pair: optional_compare_diff.diff.cpp is the equivalent C++17
// program over `std::optional<int>`, whose comparison operators compare
// engagement first and then the held values, an empty optional ordering
// before every engaged one ([optional.relops]); the runner requires
// byte-identical exit code and stdout, so C++ is the oracle for every line (no
// EXPECT-STDOUT here, the arith_widths_diff precedent). Carbon side: `==` and
// `!=` are `Optional(T) as EqWith(Optional(T))`, and `<`, `<=`, `>` and `>=`
// are `Optional(T) as OrderedWith(Optional(T))`, both in
// core/prelude/types/optional.carbon (fork design F-015,
// docs/design/optional.md). `Row` prints all six operators for one pair of
// operands, and `Run` covers every case of each operator: both empty, only the
// left empty, only the right empty, and two values that are less, equal and
// greater. `Make` builds every operand at run time, so no comparison folds.
// Core.Print lowers to printf("%d\n", x), mirrored by the C++ side.

import Core library "io";

fn B(b: bool) -> i32 { return if b then 1 else 0; }

// `Some(n)` for `n >= 0`, empty for a negative `n`.
fn Make(n: i32) -> Core.Optional(i32) {
  if (n < 0) {
    return Core.Optional(i32).None();
  }
  return Core.Optional(i32).Some(n);
}

// The six comparisons of `a` with `b`, in the order ==, !=, <, <=, >, >=.
fn Row(a: Core.Optional(i32), b: Core.Optional(i32)) {
  Core.Print(B(a == b));
  Core.Print(B(a != b));
  Core.Print(B(a < b));
  Core.Print(B(a <= b));
  Core.Print(B(a > b));
  Core.Print(B(a >= b));
}

fn Run() -> i32 {
  // Both empty.
  Row(Make(-1), Make(-2));
  // Only the left empty: an empty value orders before every value, 0 included.
  Row(Make(-1), Make(0));
  // Only the right empty.
  Row(Make(0), Make(-1));
  // Two values: less, equal, greater.
  Row(Make(0), Make(1));
  Row(Make(1), Make(1));
  Row(Make(1), Make(0));
  return 0;
}
