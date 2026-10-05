// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/result_expected.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/result_expected.carbon
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

// An exported `Core.Result(i32, i32)`-returning function, lowered
// (docs/design/error_handling.md, "Exporting fallible Carbon functions";
// fork/eh/plan.md §1.B.5-1.B.6, §4.B): the C++-side thunk `Carbon::F`
// declares `return_storage` of the skeleton type `Carbon::expected<int, int>`,
// passes it by reference to the Carbon thunk — whose `ref` return parameter
// writes the Carbon `Result` object into it — and returns it by value. The
// skeleton mirrors the choice layout (a discriminant byte, then the payload
// union at the payload alignment), so no conversion runs at the boundary.

// --- result_expected.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn F(n: i32) -> Core.Result(i32, i32) {
  if (n < 0) { return Core.Result(i32, i32).Err(n); }
  return Core.Result(i32, i32).Ok(n);
}

inline Cpp '''
namespace Carbon {
template <typename T, typename E>
struct expected {
  unsigned char disc;
  union {
    T ok;
    E err;
  };
};
}  // namespace Carbon

inline int Use(int n) {
  Carbon::expected<int, int> r = Carbon::F(n);
  return r.disc == 0 ? r.ok : r.err;
}
''';

fn G(n: i32) -> i32 { return Cpp.Use(n); }

