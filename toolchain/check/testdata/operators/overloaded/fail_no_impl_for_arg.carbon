// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/overloaded/fail_no_impl_for_arg.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/overloaded/fail_no_impl_for_arg.carbon
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

package User;

class C {};
class D {};

impl C as Core.AddWith(C) where .Result = C {
  fn Op(unused self: C, unused other: C) -> C { return {}; }
}
impl C as Core.AddAssignWith(C) {
  fn Op(unused ref self: C, unused other: C) {}
}

fn Test(a: C, b: D, z: bool) -> C {
  if (z) {
    return a + a;
  } else {
    // CHECK:STDERR: fail_no_impl_for_arg.carbon:[[@LINE+4]]:12: error: cannot access member of interface `Core.AddWith(D)` in type `C` that does not implement that interface [MissingImplInMemberAccess]
    // CHECK:STDERR:     return a + b;
    // CHECK:STDERR:            ^~~~~
    // CHECK:STDERR:
    return a + b;
  }
}

fn TestAssign(b: D) {
  var a: C = {};

  a += a;

  // CHECK:STDERR: fail_no_impl_for_arg.carbon:[[@LINE+4]]:3: error: cannot access member of interface `Core.AddAssignWith(D)` in type `C` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   a += b;
  // CHECK:STDERR:   ^~~~~~
  // CHECK:STDERR:
  a += b;
}
