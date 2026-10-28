// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon

// The C++ side of an exported set with a defaulted member
// (fork/overload/ov4-plan.md D-OV4-10): Carbon's `F(1)` calls member 0
// (`_CF:overload<0>.Main`) with the default `2`, and C++'s `Carbon::F(1)`
// calls member 1 through its thunk, because this trunk exports no default
// argument (upstream 9799a2326 arrives with UA-3).

// --- divergence_omitted.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

inline Cpp '''
inline int CallOne() { return Carbon::F(1); }
''';

fn Use() -> i32 { return F(1) + Cpp.CallOne(); }
