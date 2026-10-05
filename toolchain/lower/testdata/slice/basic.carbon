// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/slice/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/slice/basic.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): the D-SL-4 arbiter at the IR level.
// Predicted in the `Get` specific: `icmp slt i64 %i, 0`, `icmp sge i64 %i,
// %size`, an `or i1`, `br i1`, the `write` + `abort` calls in the fail block,
// and `getelementptr inbounds i32` + `load i32` on the success path; in `F`
// the `FromArray` specific stores the array address and `i64 4` into the
// slice's `{ptr, i64}` storage.

fn F() -> i32 {
  var a: array(i32, 4) = (1, 2, 3, 4);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  return s[1];
}

fn G(s: Core.Slice(i32), i: i64) -> i32 {
  return s[i];
}
