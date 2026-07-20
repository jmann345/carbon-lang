// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: interfaces powering language syntax (operators, conversions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   1
//   0
//   0
//   3
//   7
//   9
//
// Core operator interfaces powering syntax on user types: `<`/`<=`/`>`/`>=`
// via an impl of Core.OrderedWith (core/prelude/operators/comparison.carbon;
// impl shape verbatim from examples/advent2024/io_utils.carbon CharOrEOF and
// toolchain/check/testdata/operators/overloaded/ordered.carbon), `[]` via an
// impl of Core.IndexWith (core/prelude/operators/index.carbon; shape from
// toolchain/check/testdata/operators/overloaded/index_with_prelude.carbon —
// the subscript expression's type selects the impl, hence i32 indexes), and
// `var` copy-initialization via an adapted-class Core.Copy impl (shape from
// io_utils.carbon) — `var m: Meters = low` fails to compile without it
// ("does not implement interface `Core.Copy`").

import Core library "io";

class Meters {
  adapt i32;

  impl as Core.Copy {
    fn Op(self) -> Self {
      return (self as i32).(Core.Copy.Op)() as Self;
    }
  }
}

impl Meters as Core.OrderedWith(Meters) {
  fn Less(self, other: Self) -> bool {
    return (self as i32) < (other as i32);
  }
  fn LessOrEquivalent(self, other: Self) -> bool {
    return (self as i32) <= (other as i32);
  }
  fn Greater(self, other: Self) -> bool {
    return (self as i32) > (other as i32);
  }
  fn GreaterOrEquivalent(self, other: Self) -> bool {
    return (self as i32) >= (other as i32);
  }
}

class Triple {
  fn Make() -> Triple {
    return {.data = (5, 7, 9)};
  }

  var data: array(i32, 3);
}

impl Triple as Core.IndexWith(i32) where .ElementType = i32 {
  fn At(self, subscript: i32) -> i32 {
    return self.data[subscript];
  }
}

fn PrintBool(b: bool) {
  if (b) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
}

fn Run() -> i32 {
  let low: Meters = (3 as i32) as Meters;
  let high: Meters = (9 as i32) as Meters;
  PrintBool(low < high);
  PrintBool(low <= high);
  PrintBool(low > high);
  PrintBool(low >= high);

  // `var` copy-initialization dispatches through the Core.Copy impl above;
  // without that impl this line is a compile error.
  var m: Meters = low;
  Core.Print(m as i32);

  var t: Triple = Triple.Make();
  let one: i32 = 1;
  let two: i32 = 2;
  Core.Print(t[one]);
  Core.Print(t[two]);
  return 0;
}
