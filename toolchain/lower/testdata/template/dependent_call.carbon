// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/dependent_call.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/dependent_call.carbon

// --- call_function_typed_value.carbon
library "[[@TEST_NAME]]";

fn Apply[template G: type](h: G, x: i32) -> i32 {
  return h(x);
}

fn Twice(x: i32) -> i32 {
  return 2 * x;
}

fn Use() -> i32 {
  return Apply(Twice, 4);
}
