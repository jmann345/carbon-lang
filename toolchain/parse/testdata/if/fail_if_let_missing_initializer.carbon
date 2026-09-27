// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/if/fail_if_let_missing_initializer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/if/fail_if_let_missing_initializer.carbon

// A pattern condition without its `=` initializer: diagnosed at the `)`, with
// recovery to the closing paren so the `if` statement still closes.

fn F(x: i32) {
  if (let n: i32) {}
}
