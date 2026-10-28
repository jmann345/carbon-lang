// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon

// An exported `overload fn` set with a defaulted member (fork/overload/ov4-plan.md
// OV-4, D-OV4-10). Each member is its own C++ declaration (OV-3), and this
// trunk exports no default argument for a Carbon default value: upstream
// exports them from 9799a2326 on, which arrives with UA-3. So a C++ caller
// supplies every argument of a defaulted member, and C++ resolves a call that
// omits one among the other members under C++ rules, where Carbon's call with
// the same arguments selects the defaulted member (rulebook R30: both sides
// asserted; the lower twin pins the C++ side's callee).

// --- supplied.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

inline Cpp '''
inline int CallTwo() { return Carbon::F(1, 5); }
''';

//@dump-sem-ir-begin
fn Use() -> i32 { return F(1) + Cpp.CallTwo(); }
//@dump-sem-ir-end

// --- divergence_omitted.carbon

library "[[@TEST_NAME]]";

import Cpp;

// Carbon's `F(1)` selects member 0 and fills `y` with 2. C++'s
// `Carbon::F(1)` sees `F(int, int)` with no default argument, which is not
// viable for one argument, and selects `F(bool)` through the integral to
// boolean conversion.
overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

inline Cpp '''
inline int CallOne() { return Carbon::F(1); }
''';

//@dump-sem-ir-begin
fn Use() -> i32 { return F(1) + Cpp.CallOne(); }
//@dump-sem-ir-end

// --- fail_cpp_omitted.carbon

library "[[@TEST_NAME]]";

import Cpp;

// No other member is viable for one argument in C++, so Clang rejects the
// call that Carbon accepts.
overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool, unused c: bool) -> i32 { return -1; }

fn Use() -> i32 { return F(1); }

inline Cpp '''
inline int CallOne() { return Carbon::F(1); }
''';
