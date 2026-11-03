// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   30
//   12
//   1
//   1
//   2
//   1
//   101
//   105
//   101
//   200
//   12
//   72
//   -1
//
// `overload fn` members with default parameter values (fork/overload/ov4-plan.md
// OV-4, W-341): a member accepts a call that omits trailing defaulted
// arguments exactly as the ordinary call of the same function does, and a call
// two members accept selects the FIRST in declaration order (D-OV-4).
//
// EXPECT values, hand-derived from the first-match rule, upstream's positional
// default values (the omitted argument takes the parameter's default) and the
// prelude's implicit conversions (no `bool` to `i32` conversion); `Seed(x)` is
// `x + 20`:
//   30   `Scale(Seed(-17))`: 3 with `factor` defaulted to 10.
//   12   `Scale(Seed(-17), Seed(-16))`: 3 * 4.
//   1    `Pick(Seed(-15))`: both members accept one argument; member 0 (which
//        needs its default) is first, so a resolver ranking exact matches
//        first would print 2.
//   1    `Pick(Seed(-15), 6)`: only member 0 takes two.
//   2    `Order(Seed(-15))`: the exact member is first in `Order`.
//   1    `Order(Seed(-15), 6)`: only member 1 takes two.
//   101  `c.Plus()`: `start` 100 plus the default 1.
//   105  `c.Plus(5)`.
//   101  `Counter.Plus(c)`: the receiver is argument 0, `n` defaulted.
//   200  `c.Plus(true)`: member 0 rejects `bool`; member 1 doubles `start`.
//   12   `Count()`: both defaults, 1 * 10 + 2.
//   72   `Count(Seed(-13))`: 7 * 10 + 2.
//   -1   `Count(true)`: member 0 rejects `bool`; member 1.

import Core library "io";

overload fn Scale(x: i32, factor: i32 = 10) -> i32 { return x * factor; }
overload fn Scale(unused b: bool) -> i32 { return 0; }

overload fn Pick(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

overload fn Order(unused x: i32) -> i32 { return 2; }
overload fn Order(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }

class Counter {
  var start: i32;
  overload fn Plus(self, n: i32 = 1) -> i32 { return self.start + n; }
  overload fn Plus(self, b: bool) -> i32 {
    if (b) { return self.start * 2; }
    return 0;
  }
}

overload fn Count(a: i32 = 1, b: i32 = 2) -> i32 { return a * 10 + b; }
overload fn Count(unused flag: bool) -> i32 { return -1; }

fn Seed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(Scale(Seed(-17)));
  Core.Print(Scale(Seed(-17), Seed(-16)));
  Core.Print(Pick(Seed(-15)));
  Core.Print(Pick(Seed(-15), 6));
  Core.Print(Order(Seed(-15)));
  Core.Print(Order(Seed(-15), 6));
  let c: Counter = {.start = Seed(80)};
  Core.Print(c.Plus());
  Core.Print(c.Plus(5));
  Core.Print(Counter.Plus(c));
  Core.Print(c.Plus(true));
  Core.Print(Count());
  Core.Print(Count(Seed(-13)));
  Core.Print(Count(true));
  return 0;
}
