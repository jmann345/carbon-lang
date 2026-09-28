// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/failstop.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/failstop.carbon

// Fork (SL-1, fork/slices/plan.md §4.A, risk R-1): `fail_stop` lowers to a
// load of the `str` value, `call i64 @write(i32 2, ptr, i64)`, then
// `call void @abort()` with `abort` declared `noreturn`; no terminator follows
// the call, so the ordinary `ret void` of `F` ends the block. A positive lower
// golden, so the file is named without the `fail_` prefix.

fn Stop(message: str) = "fail_stop";

fn F() {
  Stop("boom\n");
}
