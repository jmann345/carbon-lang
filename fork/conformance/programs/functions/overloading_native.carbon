// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//   1
//   3
//   7
//
// Carbon-native `overload fn` closed sets (fork decision F-009;
// docs/design/functions_overloading.md): every member carries the marker,
// and a call selects the FIRST member in declaration order whose parameters
// accept the arguments through implicit conversions — no best-match ranking.
// Un-SKIPped by OV-1 (fork/overload/plan.md §5.A): the stub's
// `Describe(n: i32)` / `Describe(b: bool)` strawman is kept as the first pair
// with the accepted `overload` marker; the guard body is replaced.
//
// EXPECT values, hand-derived from the first-match rule and the prelude's
// implicit conversions (core/prelude/types/int.carbon: `Int(From) as
// ImplicitAs(Int(To))` only when `From` fits in `To`; no `bool` conversion):
//   1  `Describe(i32)`: member 0 converts exactly.
//   2  `Describe(true)`: `bool` has no implicit conversion to `i32`, so
//      member 0 is rejected and member 1 matches.
//   1  `Pick(n: i32)`: `i32` widens implicitly to `i64`, so the FIRST member
//      wins even though the second is an exact match — a best-match resolver
//      would print 2. This line is the F-009 rule observed natively.
//   3  `Sum(3)`: arity 1.
//   7  `Sum(3, 4)`: arity 2.
// Runtime inputs go through `RuntimeSeed` so nothing constant-folds.

import Core library "io";

overload fn Describe(unused n: i32) -> i32 { return 1; }
overload fn Describe(unused b: bool) -> i32 { return 2; }

// Declaration order decides: `i32` widens implicitly to `i64`
// (core/prelude/types/int.carbon), so the first member wins for an `i32`
// argument even though the second is an exact match.
overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

overload fn Sum(a: i32) -> i32 { return a; }
overload fn Sum(a: i32, b: i32) -> i32 { return a + b; }

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(Describe(RuntimeSeed(-13)));
  Core.Print(Describe(true));
  var n: i32 = RuntimeSeed(-19);
  Core.Print(Pick(n));
  Core.Print(Sum(RuntimeSeed(-17)));
  Core.Print(Sum(RuntimeSeed(-17), RuntimeSeed(-16)));
  return 0;
}
