// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/slice/buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/slice/buf.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): `Core.Buf(T)` over `malloc`/`free`.
// Predicted: `call ptr @malloc`, `icmp eq ptr ..., null` (`PointerIsNull`),
// the fill loop (`store i32 %fill`), and `call void @free(ptr ...)` inside the
// destroy specific called at `F`'s exit (risk R-12).

fn F(n: i64) -> i32 {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(n, 7);
  b.Set(0, 9);
  return b[0] + b.Get(1);
}
