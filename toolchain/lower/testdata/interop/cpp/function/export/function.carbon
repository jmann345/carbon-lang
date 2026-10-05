// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/function.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/function.carbon
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

// --- other.carbon
package Other;
fn NoArgs() {}
fn BoolArg(a: bool) {
  a;
}
fn IntArg(a: i32) {
  a;
}
fn FloatArg(a: f32) {
  a;
}
fn IntReturn() -> i32 {
  return 123;
}
// --- function.carbon

library "[[@TEST_NAME]]";

import Other;
import Cpp inline '''
int G() {
  Carbon::Other::NoArgs();
  Carbon::Other::BoolArg(true);
  Carbon::Other::IntArg(123);
  Carbon::Other::FloatArg(1.5);
  return Carbon::Other::IntReturn();
}
''';

// --- single_file.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn F() {}

inline Cpp '''
inline void G1() {
  Carbon::F();
}

// Call an inline function indirectly to ensure declarations are getting
// properly registered with the CodeGen consumer.
inline void G2() {
  G1();
}
''';

fn H() { Cpp.G2(); }

