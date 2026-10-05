// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_vector_view.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_vector_view.carbon
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

// Fork (SL-2, fork/slices/plan.md §4.B `fail_no_size`; D-SL-9): a class
// without a `size()` member gets no `CppContiguousRange` witness, so the
// blanket `ImplicitAs(Slice(...))` impl does not apply. Predicted
// `ConversionFailure` "cannot implicitly convert expression of type
// `Cpp.NoSize` to `Core.Slice(i32)`" with the
// `MissingImplInMemberAccessInContext` note.

// --- no_size.h

class NoSize {
 public:
  int* data();
};

// --- fail_no_size.carbon

library "[[@TEST_NAME]]";

import Cpp library "no_size.h";

fn View(v: Cpp.NoSize) -> Core.Slice(i32) {
  // CHECK:STDERR: fail_no_size.carbon:[[@LINE+7]]:3: error: cannot implicitly convert expression of type `Cpp.NoSize` to `Core.Slice(i32 as Core.Destroy & Core.Copy)` [ConversionFailure]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR: fail_no_size.carbon:[[@LINE+4]]:3: note: type `Cpp.NoSize` does not implement interface `Core.ImplicitAs(Core.Slice(i32 as Core.Destroy & Core.Copy))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
  return v;
}
