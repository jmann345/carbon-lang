// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/buf.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): `Core.Buf(T)` (D-SL-6).

// --- make_get_set.carbon

library "[[@TEST_NAME]]";

// Predicted: `Make`/`Set`/`IndexWith.At`/`Get` calls and, at the end of `F`,
// the `Destroy` witness call on `b` from the user impl inside the generic
// class (`@Buf.as.Destroy.impl`) — the arbiter of risk R-12.
//@dump-sem-ir-begin
fn F(n: i64) -> i32 {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(n, 7);
  b.Set(0, 9);
  return b[0] + b.Get(1);
}
//@dump-sem-ir-end

// --- as_slice.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn S(b: Core.Buf(i32)) -> Core.Slice(i32) {
  return b.AsSlice();
}
//@dump-sem-ir-end
