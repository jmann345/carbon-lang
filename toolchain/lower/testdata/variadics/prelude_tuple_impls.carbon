// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/prelude_tuple_impls.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/prelude_tuple_impls.carbon

// --- copy_op.carbon
library "[[@TEST_NAME]]";

fn Call(t: (i32, i32, i32, i32)) -> (i32, i32, i32, i32) {
  return t.(Core.Copy.Op)();
}

// --- eq.carbon
library "[[@TEST_NAME]]";

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  return a == b;
}
