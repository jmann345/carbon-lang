// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu --clang-arg=-std=c++20
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/operators/fork_all_operands_conversion.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/operators/fork_all_operands_conversion.carbon

// Fork (ST-1, fork/string/plan.md §4): operators.carbon's "All operands
// conversion" split pins, with two `str` operands, the TODO that a C++
// `operator+` is not found through conversions of operands that are not C++
// classes. Since ST-1, `str + str` is Carbon concatenation, so that split now
// fails later, on its result; this split keeps the TODO pinned with `bool`,
// which has no `AddWith` impl (core/prelude/types/bool.carbon).

// --- plus_with_bool_conversion.h

class BoolConvertibleC {
 public:
  BoolConvertibleC(bool b);
};
auto operator+(BoolConvertibleC lhs, BoolConvertibleC rhs) -> BoolConvertibleC;

// --- fail_todo_import_plus_with_bool_conversion.carbon

library "[[@TEST_NAME]]";

import Cpp library "plus_with_bool_conversion.h";

fn F() {
  let b1: bool = true;
  let b2: bool = false;
  // CHECK:STDERR: fail_todo_import_plus_with_bool_conversion.carbon:[[@LINE+4]]:40: error: cannot access member of interface `Core.AddWith(bool)` in type `bool` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   let unused c: Cpp.BoolConvertibleC = b1 + b2;
  // CHECK:STDERR:                                        ^~~~~~~
  // CHECK:STDERR:
  let unused c: Cpp.BoolConvertibleC = b1 + b2;
}
