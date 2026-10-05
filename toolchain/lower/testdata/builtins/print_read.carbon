// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// EXTRA-ARGS: --include-carbon-core
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/print_read.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/print_read.carbon
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

import Core library "io";

fn PrintChar(c: i8) -> i32 = "print.char";
fn ReadChar() -> i32 = "read.char";

fn Main() {
  Core.Print(1);

  let EOF: i32 = -1;
  while (ReadChar() != EOF) {
    // "Hi"
    if (PrintChar(0x48) != EOF) {
      PrintChar(0x69);
    }
  }
}

