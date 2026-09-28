// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/pointer_offset.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/pointer_offset.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): `pointer.offset` lowers to
// `getelementptr inbounds <elem>, ptr %p, i64 %n`.

fn Offset[T: type](p: T*, n: i64) -> T* = "pointer.offset";

fn F(p: i32*, n: i64) -> i32* {
  return Offset(p, n);
}
