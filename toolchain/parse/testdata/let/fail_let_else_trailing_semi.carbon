// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/fail_let_else_trailing_semi.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/fail_let_else_trailing_semi.carbon

// A `let`-`else` declaration ends at its block's `}`, with no `;`
// (fork/design-sprint/if-let.md, open question 1 resolved as the paper
// assumes); a stray `;` is an empty expression statement, diagnosed as
// today.

fn F(y: i32) -> i32 {
  let x: i32 = y else { return 0; };
  return x;
}
