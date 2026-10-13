// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   1
//   1
//   0
//   1
//
// Comparison in checked-generic code: `Count` and `Before` compare
// `Core.Optional(T)` values through the conditional impls
// `Optional(T) as EqWith(Optional(T))` and
// `Optional(T) as OrderedWith(Optional(T))`, both in
// core/prelude/types/optional.carbon (fork design F-015,
// docs/design/optional.md), which apply when `T` is `Core.Eq` or
// `Core.Ordered`. `T` is `i32`, a user class `Point` with its own
// `EqWith`, and `Core.Optional(i32)` itself, so the nested comparison runs the
// impl twice. The bounds also name `Core.Copy & Core.Destroy` because
// `Core.Optional(T)` needs a storage impl for `T`, which only those provide in
// user code (W-176). Expected, from F-015's rules: two of three `i32` values
// equal `Some(7)`; one `Point` equals `Some(p)` (`q` differs in `y`, an empty
// value differs from every value); `Some(None)` equals only itself, not
// `None` and not `Some(Some(7))`; `Some(7)` does not order before `None`; and
// `None` orders before `Some(None)`.

import Core library "io";

class Point {
  var x: i32;
  var y: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x, .y = self.y}; }
  }
}

impl Point as Core.EqWith(Point) {
  fn Equal(self, other: Point) -> bool {
    return self.x == other.x and self.y == other.y;
  }
  fn NotEqual(self, other: Point) -> bool {
    return self.x != other.x or self.y != other.y;
  }
}

// How many of `a`, `b` and `c` equal `want`.
fn Count[T: Core.Eq & Core.Copy & Core.Destroy](
    want: Core.Optional(T), a: Core.Optional(T), b: Core.Optional(T),
    c: Core.Optional(T)) -> i32 {
  var n: i32 = 0;
  if (a == want) {
    ++n;
  }
  if (b == want) {
    ++n;
  }
  if (c == want) {
    ++n;
  }
  return n;
}

// Whether `a` orders before `b`.
fn Before[T: Core.Ordered & Core.Copy & Core.Destroy](
    a: Core.Optional(T), b: Core.Optional(T)) -> bool {
  return a < b;
}

fn Run() -> i32 {
  let none: Core.Optional(i32) = Core.Optional(i32).None();
  let seven: Core.Optional(i32) = Core.Optional(i32).Some(7);
  Core.Print(Count(seven, seven, none, seven));

  let p: Point = {.x = 1, .y = 2};
  let q: Point = {.x = 1, .y = 3};
  let some_p: Core.Optional(Point) = Core.Optional(Point).Some(p);
  let some_q: Core.Optional(Point) = Core.Optional(Point).Some(q);
  let no_point: Core.Optional(Point) = Core.Optional(Point).None();
  Core.Print(Count(some_p, some_q, no_point, some_p));

  let some_none: Core.Optional(Core.Optional(i32)) =
      Core.Optional(Core.Optional(i32)).Some(none);
  let some_seven: Core.Optional(Core.Optional(i32)) =
      Core.Optional(Core.Optional(i32)).Some(seven);
  let outer_none: Core.Optional(Core.Optional(i32)) =
      Core.Optional(Core.Optional(i32)).None();
  Core.Print(Count(some_none, some_none, outer_none, some_seven));

  Core.Print(if Before(seven, none) then 1 else 0);
  Core.Print(if Before(outer_none, some_none) then 1 else 0);
  return 0;
}
