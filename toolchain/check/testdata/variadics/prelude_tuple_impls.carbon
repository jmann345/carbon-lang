// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/prelude_tuple_impls.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/prelude_tuple_impls.carbon

// --- copy.carbon
library "[[@TEST_NAME]]";

fn Dup[T: Core.Copy](x: T) -> T { return x.(Core.Copy.Op)(); }

fn Call() -> (i32, i32, i32, i32) {
  //@dump-sem-ir-begin
  return Dup((1 as i32, 2 as i32, 3 as i32, 4 as i32));
  //@dump-sem-ir-end
}

// --- eq.carbon
library "[[@TEST_NAME]]";

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  //@dump-sem-ir-begin
  return a == b;
  //@dump-sem-ir-end
}

// --- ordered.carbon
library "[[@TEST_NAME]]";

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  //@dump-sem-ir-begin
  return a < b;
  //@dump-sem-ir-end
}
