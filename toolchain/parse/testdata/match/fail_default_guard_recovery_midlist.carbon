// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/fail_default_guard_recovery_midlist.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/fail_default_guard_recovery_midlist.carbon

// A malformed guarded `default` in the MIDDLE of the arm list: recovery
// skips past the broken arm and the loop continues, so the arms after it
// (a guarded `case` and a trailing unguarded `default`) still parse.

fn f() -> i32 {
  match (true) {
    // CHECK:STDERR: fail_default_guard_recovery_midlist.carbon:[[@LINE+4]]:16: error: expected `(` after `if` [ExpectedMatchCaseGuardOpenParen]
    // CHECK:STDERR:     default if true => { return 1; }
    // CHECK:STDERR:                ^~~~
    // CHECK:STDERR:
    default if true => { return 1; }
    case x: bool if (x) => { return 2; }
    default => { return 3; }
  }
  return 0;
}
