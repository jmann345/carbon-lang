// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   11
//   12
//   0
//   11
//   12
//   13
//   1
//   21
//   22
//   1
//   1
//   10
//
// The prelude's tuple impls are found through a generic function's
// requirement, where the tuple is a specific's type argument. Counted's
// `Equal` prints 10 plus its field and its `NotEqual` prints 20 plus its
// field; the tuple impl's `Equal` calls each element's `Equal` once, in
// order, stopping at the first element that differs, and its `NotEqual`
// calls each element's `NotEqual`, stopping at the first that is true
// (tuples compare field-wise with `==` and `!=`, docs/design/tuples.md,
// "Operations performed field-wise"): Same(a, b) compares the first two
// elements, printing 11 and 12, and is false (0); Same(a, a) compares all
// three, printing 11, 12 and 13, and is true (1); Differ(a, b) prints 21
// (the first elements are not not-equal) and 22, and is true (1). Less through
// `Core.Ordered` is true for (1, 2) < (1, 3) (1), and Copies through
// `Core.Copy` copies a 4-tuple whose last element is 10.

import Core library "io";

class Counted {
  var v: i32;
}

impl Counted as Core.EqWith(Counted) {
  fn Equal(self, other: Counted) -> bool {
    Core.Print(10 + self.v);
    return self.v == other.v;
  }
  fn NotEqual(self, other: Counted) -> bool {
    Core.Print(20 + self.v);
    return self.v != other.v;
  }
}

fn Show(b: bool) {
  if (b) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
}

fn Same[T: Core.Eq](x: T, y: T) -> bool {
  return x == y;
}

fn Differ[T: Core.Eq](x: T, y: T) -> bool {
  return x != y;
}

fn Less[T: Core.Ordered](x: T, y: T) -> bool {
  return x < y;
}

fn Copies[T: Core.Copy](x: T) -> T {
  return x.(Core.Copy.Op)();
}

fn Run() -> i32 {
  let c1: Counted = {.v = 1};
  let c2: Counted = {.v = 2};
  let c3: Counted = {.v = 3};
  let c5: Counted = {.v = 5};
  let a: (Counted, Counted, Counted) = (c1, c2, c3);
  let b: (Counted, Counted, Counted) = (c1, c5, c3);
  Show(Same(a, b));
  Show(Same(a, a));
  Show(Differ(a, b));
  Show(Less((1 as i32, 2 as i32), (1 as i32, 3 as i32)));
  Core.Print(Copies((7 as i32, 8 as i32, 9 as i32, 10 as i32)).3);
  return 0;
}
