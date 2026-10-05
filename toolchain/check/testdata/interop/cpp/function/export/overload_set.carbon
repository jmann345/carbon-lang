// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set.carbon

// Exporting a Carbon `overload fn` set to C++ (fork decision F-009;
// fork/overload/plan.md OV-3, §1.C, §4.C). C++ name lookup of the set's name
// receives every exportable member as its own declaration, so C++ sees an
// ordinary C++ overload set and resolves calls to it under C++'s rules —
// best viable match — while Carbon call sites resolve the same set by
// declaration-order first-match. The divergence is documented, not prevented
// (docs/design/functions_overloading.md, "Documented divergence"): C++ may
// select a different member than Carbon would, or reject as ambiguous a call
// Carbon accepts; it can never call a member with the wrong ABI, because each
// member is its own C++ declaration with its own symbol. The dumped ranges
// pin the Carbon side's selections; the lower twin pins the C++ side's.

// --- overload_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(unused x: i64) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// `true` is an exact match for `F(bool)`, and `7L` for `F(long)` — `i64` maps
// to `long`. A plain `7` is NOT passed here: under C++ rules `int -> long`
// and `int -> bool` are both Conversion rank, so `Carbon::F(7)` is ambiguous
// (`fail_cpp_ambiguous` below), where Carbon's first-match selects `F(i64)`.
inline Cpp '''
inline int CallBool() { return Carbon::F(true); }
inline int CallWithLong() { return Carbon::F(7L); }
''';

//@dump-sem-ir-begin
fn Use() -> i32 { return F(7) + F(true) + Cpp.CallBool() + Cpp.CallWithLong(); }
//@dump-sem-ir-end

// --- divergence.carbon

library "[[@TEST_NAME]]";

import Cpp;

// The two sides select DIFFERENT members for the same argument type: Carbon
// takes the first member (`i32` widens to `i64`, an implicit conversion), C++
// takes `Pick(int)` (an exact match outranks the `int -> long` conversion).
overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

inline Cpp '''
inline int FromCpp(int v) { return Carbon::Pick(v); }
''';

//@dump-sem-ir-begin
fn Use(n: i32) -> i32 { return Pick(n) + Cpp.FromCpp(n); }
//@dump-sem-ir-end

// --- method_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

// Members in class scope export as C++ member-function overloads of the
// exported class; `ref self` members are lvalue-ref-qualified.
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

//@dump-sem-ir-begin
fn Use() -> i32 { return Cpp.Drive(); }
//@dump-sem-ir-end

// --- fail_cpp_ambiguous.carbon

library "[[@TEST_NAME]]";

import Cpp;

// The "whether" half of the divergence: Carbon's first-match accepts `F(7)`
// (the literal converts to `i64`), while under C++ rules `int -> long` and
// `int -> bool` are both Conversion rank ([over.ics.rank]/4.1 demotes only
// pointer and member-pointer conversions to `bool`), so Clang rejects
// `Carbon::F(7)` as ambiguous.
overload fn F(unused x: i64) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return F(7); }

inline Cpp '''
inline int CallWithPlainInt() { return Carbon::F(7); }
''';

// --- fail_todo_partial_export.carbon

library "[[@TEST_NAME]]";

import Cpp;

// A member whose signature has no C++ mapping (a tuple-typed parameter) is
// omitted from the exported set after the per-function export path emits its
// semantics TODO; the other member stays callable from C++ (sub-fork F-009i,
// fork/overload/plan.md §1.C.1).
overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused p: (i32, i32)) -> i32 { return 2; }

inline Cpp '''
inline int CallInt() { return Carbon::F(7); }
''';

fn Use() -> i32 { return Cpp.CallInt(); }
