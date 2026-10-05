// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set.carbon

// Every exported member of a Carbon `overload fn` set is its own C++
// declaration behind its own pair of symbols (fork decision F-009;
// fork/overload/plan.md OV-3, D-OV-5, D-OV-9): the member itself
// (`_CF:overload<N>.Main`) and its per-member Carbon thunk
// (`_CF__carbon_thunk__overload<N>.Main`, the asm label of the C++
// declaration the inline C++ `F` calls). The C++ side resolves under C++
// rules and the Carbon side by declaration-order first-match, so a golden
// can show the two sides calling different members of one set.

// --- overload_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(unused x: i64) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

inline Cpp '''
inline int CallBool() { return Carbon::F(true); }
inline int CallWithLong() { return Carbon::F(7L); }
''';

fn Use() -> i32 { return F(7) + F(true) + Cpp.CallBool() + Cpp.CallWithLong(); }

// --- divergence.carbon

library "[[@TEST_NAME]]";

import Cpp;

// Carbon's `Pick(n)` calls member 0 (`i32` widens to `i64`); C++'s
// `Carbon::Pick(v)` calls member 1 (`int` is an exact match).
overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

inline Cpp '''
inline int FromCpp(int v) { return Carbon::Pick(v); }
''';

fn Use(n: i32) -> i32 { return Pick(n) + Cpp.FromCpp(n); }
