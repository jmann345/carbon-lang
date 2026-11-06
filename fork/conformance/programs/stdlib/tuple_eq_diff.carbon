// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
//
// Differential pair: tuple_eq_diff.diff.cpp compares the same values with
// std::tuple's operator== and operator!=, which compare element by element
// with the elements' ==, in order, stopping at the first element that
// differs, as Carbon's tuple equality does (docs/design/tuples.md,
// "Operations performed field-wise"; docs/design/expressions/
// comparison_operators.md, "Default implementations for basic types"), and
// define != as the negation of ==; Carbon's tuple != compares field-wise with
// the elements' !=, which for every element type here is the negation of ==
// (Counted keeps EqWith's default NotEqual), so the two run the same element
// comparisons and C++ is the oracle for every printed line (no
// EXPECT-STDOUT). The prelude's variadic impl makes a tuple
// `EqWith` itself when every element type is `Eq`: elements of three types, a
// tuple that differs in its middle element, the empty tuple, a tuple of
// tuples (the impl used again for the inner tuple), a 5-tuple, and tuples of
// Counted, whose Equal prints 10 plus its field, so the comparisons each
// element runs, and where they stop, are printed too.

import Core library "io";

class Counted {
  var v: i32;
}

impl Counted as Core.EqWith(Counted) {
  fn Equal(self, other: Counted) -> bool {
    Core.Print(10 + self.v);
    return self.v == other.v;
  }
}

fn Show(b: bool) {
  if (b) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
}

fn Run() -> i32 {
  let a: (i32, i64, bool) = (1, 2, true);
  let b: (i32, i64, bool) = (1, 2, true);
  let c: (i32, i64, bool) = (1, 3, true);
  Show(a == b);
  Show(a == c);
  Show(a != c);
  let e1: () = ();
  let e2: () = ();
  Show(e1 == e2);
  let n: ((i32, i32), i32) = ((1, 2), 3);
  let m: ((i32, i32), i32) = ((1, 4), 3);
  Show(n == m);
  let n2: ((i32, i32), i32) = ((1, 2), 3);
  Show(n != n2);
  let w: (i32, i32, i32, i32, i32) = (1, 2, 3, 4, 5);
  let w2: (i32, i32, i32, i32, i32) = (1, 2, 3, 4, 5);
  Show(w == w2);
  let c1: Counted = {.v = 1};
  let c2: Counted = {.v = 2};
  let c3: Counted = {.v = 3};
  let c5: Counted = {.v = 5};
  let p: (Counted, Counted, Counted) = (c1, c2, c3);
  let q: (Counted, Counted, Counted) = (c1, c5, c3);
  Show(p == q);
  Show(p != q);
  Show(p == p);
  return 0;
}
