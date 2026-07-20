// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Operator overloading
// EXPECT-EXIT: 0
//
// Differential pair: operator_overloading_diff.diff.cpp is the equivalent
// C++17 program using member operator+/operator*; the runner requires
// byte-identical exit code and stdout, so C++ operator overloading is the
// oracle for the computed values — no hand-authored EXPECT-STDOUT.
// User-defined `+` via Core.AddWith (impl shape verbatim from
// toolchain/check/testdata/operators/overloaded/add.carbon) and
// heterogeneous `*` by i32 via Core.MulWith (interface in
// core/prelude/operators/arithmetic.carbon, impl shape per
// toolchain/check/testdata/operators/overloaded/mul.carbon), on an
// adapt-i32 class per types/operator_overloading.carbon.

import Core library "io";

class Cents {
  adapt i32;
}

impl Cents as Core.AddWith(Cents) where .Result = Cents {
  fn Op(self, other: Cents) -> Cents {
    return ((self as i32) + (other as i32)) as Cents;
  }
}

impl Cents as Core.MulWith(i32) where .Result = Cents {
  fn Op(self, other: i32) -> Cents {
    return ((self as i32) * other) as Cents;
  }
}

fn Run() -> i32 {
  let price: Cents = (150 as i32) as Cents;
  let tip: Cents = (27 as i32) as Cents;
  let total: Cents = price + tip;
  Core.Print(total as i32);
  // The literal is bound to i32 first: `*` routes through MulWith(i32),
  // not MulWith(Core.IntLiteral).
  let factor: i32 = 3;
  let tripled: Cents = total * factor;
  Core.Print(tripled as i32);
  return 0;
}
