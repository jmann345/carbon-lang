// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/fail_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/fail_buf.carbon
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

// Fork (SL-1, fork/slices/plan.md §4.A): the pinned 0.1 limits of
// `Core.Buf(T)` (D-SL-6).

// --- fail_copy.carbon

library "[[@TEST_NAME]]";

// `Buf` has no `Copy` impl, so a copy is a compile error, never a double
// free. Predicted `CopyOfUncopyableType` "cannot copy value of type
// `Core.Buf(i32)`" with the `MissingImplInMemberAccessInContext` note "type
// `Core.Buf(i32)` does not implement interface `Core.Copy`".
fn C(b: Core.Buf(i32)) {
  // CHECK:STDERR: fail_copy.carbon:[[@LINE+11]]:26: error: cannot copy value of type `Core.Buf(i32 as Core.Copy & Core.Destroy)` [CopyOfUncopyableType]
  // CHECK:STDERR:   var c: Core.Buf(i32) = b;
  // CHECK:STDERR:                          ^
  // CHECK:STDERR: fail_copy.carbon:[[@LINE+8]]:26: note: type `Core.Buf(i32 as Core.Copy & Core.Destroy)` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   var c: Core.Buf(i32) = b;
  // CHECK:STDERR:                          ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_copy.carbon:[[@LINE+4]]:7: warning: binding `c` unused [UnusedBinding]
  // CHECK:STDERR:   var c: Core.Buf(i32) = b;
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var c: Core.Buf(i32) = b;
}

// --- fail_unformed.carbon

library "[[@TEST_NAME]]";

// `Buf` is not `UnformedInit`: `Destroy` runs unconditionally on `var`
// storage, so an unformed `Buf` would free a garbage pointer. Predicted
// `ConversionFailureTypeToFacet` "cannot convert type `Core.Buf(i32)` into
// type implementing `Core.DefaultOrUnformed`".
fn U() {
  // CHECK:STDERR: fail_unformed.carbon:[[@LINE+8]]:3: error: cannot convert type `Core.Buf(i32 as Core.Copy & Core.Destroy)` into type implementing `Core.DefaultOrUnformed` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   var b: Core.Buf(i32);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_unformed.carbon:[[@LINE+4]]:7: warning: binding `b` unused [UnusedBinding]
  // CHECK:STDERR:   var b: Core.Buf(i32);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var b: Core.Buf(i32);
}
