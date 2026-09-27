// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/let_else_missing_initializer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/let_else_missing_initializer.carbon

// `let P else {...}` with no `= e` parses (W-012): `LetElseDecl::init` is
// optional, so the tree verifies; check diagnoses the missing initializer
// (`ExpectedInitializerAfterLet`, check/testdata/let/fail_let_else.carbon).
choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  let .Some(n: i32) else { return 0; }
  return n;
}
