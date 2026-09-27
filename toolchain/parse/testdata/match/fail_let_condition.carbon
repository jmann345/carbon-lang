// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/fail_let_condition.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/fail_let_condition.carbon

// `match (let ...)` is not a pattern condition (W-012): the `let`/`var` peek
// in `HandleParenCondition` applies to `if` and `while` only, so `match`
// takes the expression path and `let` is an expected-expression error, as
// before W-012.
fn F(x: i32) -> i32 {
  match (let n: i32 = x) {
    default => { return 0; }
  }
  return 1;
}
