// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_guard_non_bool.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_guard_non_bool.carbon
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

// A guard is a boolean condition: a guard expression that does not
// implicitly convert to `bool` is a real conversion error at the guard
// expression (no longer a "semantics TODO" — re-platform plan S2d).

fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_guard_non_bool.carbon:[[@LINE+7]]:16: error: cannot implicitly convert expression of type `i32` to `bool` [ConversionFailure]
    // CHECK:STDERR:     case 0 if (x + 1) => { return 1; }
    // CHECK:STDERR:                ^~~~~
    // CHECK:STDERR: fail_guard_non_bool.carbon:[[@LINE+4]]:16: note: type `i32` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
    // CHECK:STDERR:     case 0 if (x + 1) => { return 1; }
    // CHECK:STDERR:                ^~~~~
    // CHECK:STDERR:
    case 0 if (x + 1) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
