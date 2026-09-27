// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --cpp-exceptions=none
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/fail_catching_none_mode.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/fail_catching_none_mode.carbon

// --- fail_none_mode.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
''';

// In `--cpp-exceptions=none` no callee is fence-required, so no catching
// thunk is ever selected: `?` sees a plain `i32` operand (fail_catching.carbon
// holds the other arms; this one needs its own file-wide `EXTRA-ARGS`).
fn F() -> Core.Result(i32, Cpp.Exception) {
  // CHECK:STDERR: fail_none_mode.carbon:[[@LINE+7]]:45: error: operand of `?` does not implement `Core.Try` [QuestionOperandNotTry]
  // CHECK:STDERR:   return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
  // CHECK:STDERR:                                             ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_none_mode.carbon:[[@LINE+4]]:45: note: type `i32` does not implement interface `Core.Try` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
  // CHECK:STDERR:                                             ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
}
