// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Operator overloading
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   1
//
// User-defined operators via impls of Core operator interfaces: `+` through
// Core.AddWith (impl shape verbatim from toolchain/check/testdata/operators/
// overloaded/add.carbon) and `==` through Core.EqWith plus the adapted-class
// Copy impl, both verbatim from examples/advent2024/day15_common.carbon
// (class Square) and examples/advent2024/io_utils.carbon (class CharOrEOF).

import Core library "io";

class Meters {
  adapt i32;

  impl as Core.Copy {
    fn Op(self) -> Self {
      return (self as i32).(Core.Copy.Op)() as Self;
    }
  }
  impl as Core.EqWith(Meters) {
    fn Equal(self, other: Self) -> bool {
      return (self as i32) == (other as i32);
    }
    fn NotEqual(self, other: Self) -> bool {
      return (self as i32) != (other as i32);
    }
  }
}

impl Meters as Core.AddWith(Meters) where .Result = Meters {
  fn Op(self, other: Meters) -> Meters {
    return ((self as i32) + (other as i32)) as Meters;
  }
}

fn Run() -> i32 {
  let a: Meters = (30 as i32) as Meters;
  let b: Meters = (12 as i32) as Meters;
  let c: Meters = a + b;
  Core.Print(c as i32);
  if (c == ((42 as i32) as Meters)) {
    Core.Print(1);
    return 0;
  }
  return 1;
}
