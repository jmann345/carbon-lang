// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_binding_scope.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_binding_scope.carbon

// Case-arm bindings are scoped to their own arm: they are not visible in
// sibling arms nor after the `match` statement (re-platform plan S2b name
// scope discipline).

// --- fail_sibling_arm.carbon
library "[[@TEST_NAME]]";

fn F(x: i32) -> i32 {
  match (x) {
    case a: i32 => { return a; }
    // CHECK:STDERR: fail_sibling_arm.carbon:[[@LINE+4]]:25: error: name `a` not found [NameNotFound]
    // CHECK:STDERR:     default => { return a; }
    // CHECK:STDERR:                         ^
    // CHECK:STDERR:
    default => { return a; }
  }
  return -1;
}

// --- fail_after_match.carbon
library "[[@TEST_NAME]]";

fn G(x: i32) -> i32 {
  match (x) {
    case b: i32 => { return b; }
    default => { return 0; }
  }
  // CHECK:STDERR: fail_after_match.carbon:[[@LINE+4]]:10: error: name `b` not found [NameNotFound]
  // CHECK:STDERR:   return b;
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  return b;
}
