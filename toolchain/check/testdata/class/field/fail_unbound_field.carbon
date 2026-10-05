// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/class/field/fail_unbound_field.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/class/field/fail_unbound_field.carbon
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

class Class {
  var field: i32;
  fn F() -> i32 {
    // CHECK:STDERR: fail_unbound_field.carbon:[[@LINE+4]]:12: error: expression cannot be used as a value [UseOfNonExprAsValue]
    // CHECK:STDERR:     return field;
    // CHECK:STDERR:            ^~~~~
    // CHECK:STDERR:
    return field;
  }

  fn IsZero() -> bool {
    // CHECK:STDERR: fail_unbound_field.carbon:[[@LINE+4]]:12: error: cannot access member of interface `Core.EqWith(Core.IntLiteral)` in type `<unbound element of class Class>` that does not implement that interface [MissingImplInMemberAccess]
    // CHECK:STDERR:     return field == 0;
    // CHECK:STDERR:            ^~~~~~~~~~
    // CHECK:STDERR:
    return field == 0;
  }
}

fn G() -> i32 {
  // CHECK:STDERR: fail_unbound_field.carbon:[[@LINE+4]]:10: error: expression cannot be used as a value [UseOfNonExprAsValue]
  // CHECK:STDERR:   return Class.field;
  // CHECK:STDERR:          ^~~~~~~~~~~
  // CHECK:STDERR:
  return Class.field;
}
