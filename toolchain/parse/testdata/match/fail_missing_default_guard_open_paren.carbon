// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/fail_missing_default_guard_open_paren.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/fail_missing_default_guard_open_paren.carbon

fn f() -> i32 {
  match (true) {
    // CHECK:STDERR: fail_missing_default_guard_open_paren.carbon:[[@LINE+8]]:16: error: expected `(` after `if` [ExpectedMatchCaseGuardOpenParen]
    // CHECK:STDERR:     default if false) => { return 1; }
    // CHECK:STDERR:                ^~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_missing_default_guard_open_paren.carbon:[[@LINE+4]]:21: error: closing symbol without a corresponding opening symbol [UnmatchedClosing]
    // CHECK:STDERR:     default if false) => { return 1; }
    // CHECK:STDERR:                     ^
    // CHECK:STDERR:
    default if false) => { return 1; }
  }
  return 0;
}
