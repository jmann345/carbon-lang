// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/fail_todo_generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/fail_todo_generic.carbon
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

// Generic unions, and unions nested in a generic scope, are TODO-gated in 0.1
// (docs/design/unions.md, "Declaring a union"; fork/unions/plan.md D-UN-3).

// --- fail_todo_generic_union.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_generic_union.carbon:[[@LINE+4]]:1: error: semantics TODO: `generic union` [SemanticsTodo]
// CHECK:STDERR: union Slot(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
union Slot(T: type) {
  var value: T;
  var next_free: Slot(T)*;
}

// --- fail_todo_nested_in_generic.carbon
library "[[@TEST_NAME]]";

class Box(T: type) {
  // CHECK:STDERR: fail_todo_nested_in_generic.carbon:[[@LINE+4]]:3: error: semantics TODO: `generic union` [SemanticsTodo]
  // CHECK:STDERR:   union U {
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
  union U {
    var a: i32;
  }
}
