// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//
// The DOCUMENTED DIVERGENCE of exported overload sets (fork decision F-009;
// fork/overload/plan.md OV-3 §5.C.2; docs/design/functions_overloading.md
// "Documented divergence: two resolution rules"): a Carbon `overload fn` set
// resolves by declaration-order first-match at Carbon call sites and under
// C++'s best-viable-match rules at C++ call sites, so the same argument type
// can select different members on the two sides of the boundary. The
// divergence is accepted and documented rather than prevented; it is bounded
// to WHICH member runs (or whether the call compiles) and can never produce a
// wrong-ABI call, because each member is its own C++ declaration with its own
// symbol. Per F-009, every exported-overload conformance program asserts BOTH
// directions' resolution — this program is where the two rules disagree, its
// sibling cpp_export_overload_set.carbon where they agree. No `.diff.cpp`
// oracle, deliberately: a divergence test cannot use an equality oracle.
//
// EXPECT values, hand-derived:
//   1  Carbon `Pick(n)` with `n: i32`: `i32` widens implicitly to `i64`
//      (core/prelude/types/int.carbon `Int(From) as ImplicitAs(Int(To))`),
//      so the FIRST member matches and is selected — first-match, no ranking,
//      even though the second member is an exact match.
//   2  C++ `Carbon::Pick(v)` with `v: int`: `Pick(int)` (`i32` maps to `int`)
//      is an exact match and `int -> long` (`i64` maps to `long`) is an
//      integral conversion, so [over.match.best] selects the SECOND member.
// Runtime inputs go through `RuntimeSeed` so nothing constant-folds.

import Core library "io";
import Cpp;

overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

inline Cpp '''
inline int FromCpp(int v) { return Carbon::Pick(v); }
''';

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  var n: i32 = RuntimeSeed(-19);
  Core.Print(Pick(n));
  Core.Print(Cpp.FromCpp(n));
  return 0;
}
