// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   14
//
// A Carbon-native `overload fn` set declared in another library's API file,
// defined in that library's implementation file, and called through an
// import (fork decision F-009; docs/design/functions_overloading.md;
// fork/overload/plan.md OV-2 §5.B.2). The set is imported whole, with its
// member list in declaration order, so a call here resolves by the same
// first-match rule as a same-file call, and each member's symbol carries its
// set-relative index (`:overload<N>`) in every unit, which is what links the
// calls here to the definitions in geometry.impl.carbon.
//
// EXPECT values, hand-derived from the members' bodies and the prelude's
// implicit conversions (an `i32` argument widens to `i64`, an `i64` argument
// never narrows to `i32`):
//   7   `Dist(i32, i32)`: member 0 converts exactly, |3 - 10| = 7.
//   14  `Dist(i64, i64)`: member 0 is rejected (no `i64 -> i32` conversion),
//       member 1 matches and returns 2 * |3 - 10| = 14.
// Runtime inputs go through `RuntimeSeed` so nothing constant-folds:
// RuntimeSeed(-17) = 3 and RuntimeSeed(-10) = 10.

import Core library "io";
import library "geometry";

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(Dist(RuntimeSeed(-17), RuntimeSeed(-10)));
  Core.Print(Dist(RuntimeSeed(-17) as i64, RuntimeSeed(-10) as i64));
  return 0;
}
