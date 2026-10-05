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
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

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
