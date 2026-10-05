// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//   2
//   1
//
// Exporting a Carbon `overload fn` set to C++, the AGREEING direction (fork
// decision F-009; fork/overload/plan.md OV-3 §5.C.1;
// docs/design/functions_overloading.md "Exporting Carbon overload sets to
// C++"): every member of the set is visible to C++ code in an `inline Cpp`
// block as an ordinary C++ overload of `Carbon::Describe`, and C++ callers
// resolve the set under C++'s own best-viable-match rules while Carbon
// callers use declaration-order first-match. Per F-009, every
// exported-overload conformance program asserts BOTH directions' resolution;
// this program is the case where the two rules agree, its sibling
// cpp_export_overload_set_divergence.carbon the case where they do not.
// Shapes from toolchain/check/testdata/interop/cpp/function/export/
// overload_set.carbon and fork/conformance/programs/interop/
// cpp_export_function.carbon. No `.diff.cpp` oracle, deliberately: the C++
// side here IS the oracle for its own two lines.
//
// EXPECT values, hand-derived (the Carbon lines from the first-match rule and
// the prelude's implicit conversions, core/prelude/types/int.carbon; the C++
// lines from [over.match.best] exact-match ranking):
//   1  Carbon `Describe(RuntimeSeed(-13))`: an `i32` argument, member 0
//      converts exactly and is the first member.
//   2  Carbon `Describe(true)`: `bool` has no implicit conversion to `i32`,
//      so member 0 is rejected and member 1 matches.
//   2  C++ `Carbon::Describe(b)` with `b: bool`: `Describe(bool)` is an exact
//      match and `bool -> int` is an integral promotion, so C++ selects the
//      `bool` member — the same member Carbon selects for a `bool`.
//   1  C++ `Carbon::Describe(n)` with `n: int`: `Describe(int)` (`i32` maps
//      to `int`) is an exact match and `int -> bool` is a boolean conversion,
//      so C++ selects the `i32` member — the same member Carbon selects.
// Runtime inputs go through `RuntimeSeed` so nothing constant-folds.

import Core library "io";
import Cpp;

overload fn Describe(unused n: i32) -> i32 { return 1; }
overload fn Describe(unused b: bool) -> i32 { return 2; }

inline Cpp '''
inline int FromCpp(bool b) { return Carbon::Describe(b); }
inline int FromCppInt(int n) { return Carbon::Describe(n); }
''';

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(Describe(RuntimeSeed(-13)));
  Core.Print(Describe(true));
  Core.Print(Cpp.FromCpp(true));
  Core.Print(Cpp.FromCppInt(RuntimeSeed(-13)));
  return 0;
}
