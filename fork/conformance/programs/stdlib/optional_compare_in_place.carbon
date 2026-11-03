// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   1
//   1
//   1
//   0
//   0
//   0
//   1
//   1
//   0
//   0
//
// Comparing `Core.Optional(T)` values compares the held values in place: no
// `Copy` and no `Destroy` of `T` per operand (W-352), as
// docs/design/expressions/comparison_operators.md asks of `EqWith` and
// `OrderedWith` ("should have no observable side-effects"). `Counted` counts
// its copies and destructions. Expected, from F-015's rules
// (docs/design/optional.md, "Comparison"): with `a` holding 1, `b` holding 2
// and `n` empty, `a == b` 0, `a != b` 1, `a < b` 1, `a <= b` 1, `a > b` 0,
// `a >= b` 0, `n == a` 0 (empty and non-empty are not equal), `n < a` 1 (an
// empty value orders first) and `a == a` 1; then the copies and destructions
// the nine comparisons made, 0 and 0.

import Core library "io";

class Counted {
  var v: i32;
  var copies: i32*;
  var destroys: i32*;
  impl as Core.Copy {
    fn Op(self) -> Self {
      ++*self.copies;
      return {.v = self.v, .copies = self.copies, .destroys = self.destroys};
    }
  }
  impl as Core.Destroy {
    fn Op(ref self) {
      ++*self.destroys;
    }
  }
}

impl Counted as Core.EqWith(Counted) {
  fn Equal(self, other: Counted) -> bool { return self.v == other.v; }
  fn NotEqual(self, other: Counted) -> bool { return self.v != other.v; }
}

impl Counted as Core.OrderedWith(Counted) {
  fn Less(self, other: Counted) -> bool { return self.v < other.v; }
  fn LessOrEquivalent(self, other: Counted) -> bool {
    return self.v <= other.v;
  }
  fn Greater(self, other: Counted) -> bool { return self.v > other.v; }
  fn GreaterOrEquivalent(self, other: Counted) -> bool {
    return self.v >= other.v;
  }
}

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  var copies: i32 = 0;
  var destroys: i32 = 0;
  var t1: Counted = {.v = 1, .copies = &copies, .destroys = &destroys};
  var t2: Counted = {.v = 2, .copies = &copies, .destroys = &destroys};
  var a: Core.Optional(Counted) = Core.Optional(Counted).Some(t1);
  var b: Core.Optional(Counted) = Core.Optional(Counted).Some(t2);
  var n: Core.Optional(Counted) = Core.Optional(Counted).None();
  let c0: i32 = copies;
  let d0: i32 = destroys;
  Core.Print(B(a == b));
  Core.Print(B(a != b));
  Core.Print(B(a < b));
  Core.Print(B(a <= b));
  Core.Print(B(a > b));
  Core.Print(B(a >= b));
  Core.Print(B(n == a));
  Core.Print(B(n < a));
  Core.Print(B(a == a));
  Core.Print(copies - c0);
  Core.Print(destroys - d0);
  return 0;
}
