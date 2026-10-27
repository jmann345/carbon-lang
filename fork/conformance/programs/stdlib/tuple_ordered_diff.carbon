// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
//
// Differential pair: tuple_ordered_diff.diff.cpp compares the same values
// with std::tuple's operator<, operator<=, operator> and operator>=, which
// compare lexicographically using only the elements' `<`, as Carbon's tuple
// ordering does (docs/design/expressions/comparison_operators.md, "Default
// implementations for basic types"), so C++ is the oracle for every printed
// line (no EXPECT-STDOUT). The prelude's variadic impl makes a tuple
// `OrderedWith` itself when every element type is `Ordered`: tuples decided
// by their second element, equal tuples, the empty tuple, a tuple of a tuple
// and an i64 decided by the inner tuple's first element, and a 1-tuple of a
// NaN: neither element is less than the other, so the tuples are
// equivalent and `<=` and `>=` hold, although the element's own `<=` does
// not (the design leaves orderings that are not total open, "There is no
// expectation that an `Ordered` implementation be a total order").

import Core library "io";

fn Show(b: bool) {
  if (b) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
}

fn Run() -> i32 {
  let a: (i32, i32, i32) = (1, 2, 3);
  let b: (i32, i32, i32) = (1, 3, 0);
  Show(a < b);
  Show(a <= b);
  Show(a > b);
  Show(a >= b);
  let c: (i32, i32, i32) = (1, 2, 3);
  Show(a < c);
  Show(a > c);
  Show(a <= c);
  Show(a >= c);
  let e1: () = ();
  let e2: () = ();
  Show(e1 < e2);
  Show(e1 <= e2);
  let n: ((i32, i32), i64) = ((2, 1), 0);
  let m: ((i32, i32), i64) = ((1, 9), 5);
  Show(n > m);
  Show(n < m);
  let z: f64 = 0.0;
  let nan: f64 = z / z;
  let t: (f64,) = (nan,);
  Show(t < t);
  Show(t <= t);
  Show(t >= t);
  Show(nan <= nan);
  return 0;
}
