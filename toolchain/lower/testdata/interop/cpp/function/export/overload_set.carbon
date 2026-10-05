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
// (`_CF__carbon_thunk:overload<N>.Main` — the thunk carries the member's
// index, so the mangler keys it as it keys the member — the asm label of the
// C++ declaration the inline C++ `F` calls). The C++ side resolves under C++
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

// --- method_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

// Members in class scope: each `ref self` member is its own lvalue-ref-
// qualified C++ member function of the exported `Acc`, behind its own
// `_CAdd:overload<N>.Acc.Main` and `_CAdd__carbon_thunk:overload<N>.Acc.Main`
// pair; `a.Add(1)` and `a.Add(true)` call different members.
class Acc {
  var total: i32;
  fn Make() -> Acc { return {.total = 0}; }
  overload fn Add(ref self, x: i32) { self.total = self.total + x; }
  overload fn Add(ref self, flag: bool) {
    if (flag) { self.total = self.total + 100; }
  }
  fn Get(self) -> i32 { return self.total; }
}

inline Cpp '''
inline int Drive() {
  auto a = Carbon::Acc::Make();
  a.Add(1);
  a.Add(true);
  return a.Get();
}
''';

fn Use() -> i32 { return Cpp.Drive(); }
