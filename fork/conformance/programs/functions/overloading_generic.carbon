// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//   2
//
// Generic members of a Carbon-native `overload fn` set (fork decision F-009;
// docs/design/functions_overloading.md; fork/overload/plan.md OV-2 §5.B.1). A
// generic member is probed by non-diagnosing deduction in declaration order
// like any other member, and the first member that accepts the call wins.
//
// EXPECT values, hand-derived from the first-match rule and the prelude's
// implicit conversions (core/prelude/types/int.carbon: `Int(From) as
// ImplicitAs(Int(To))` only when `From` fits in `To`; no `bool` conversion):
//   1  `Kind(i32)`: member 0 (`x: i32`) converts exactly, so the generic
//      member is never probed.
//   2  `Kind(true)`: `bool` has no implicit conversion to `i32`, so member 0
//      is rejected and member 1 deduces `T = bool`.
//   2  `Kind(i64)`: there is no narrowing `i64 -> i32` implicit conversion
//      (`IntFitsIn` rejects it), so member 0 is rejected and member 1 deduces
//      `T = i64`.
// Runtime inputs go through `RuntimeSeed` so nothing constant-folds.

import Core library "io";

overload fn Kind(unused x: i32) -> i32 { return 1; }
overload fn Kind[T: type](unused x: T) -> i32 { return 2; }

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(Kind(RuntimeSeed(-19)));
  Core.Print(Kind(true));
  Core.Print(Kind(RuntimeSeed(-19) as i64));
  return 0;
}
