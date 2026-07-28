// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/fail_alternative_pattern_unclosed.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/fail_alternative_pattern_unclosed.carbon

// Error recovery inside an alternative pattern's payload list rides the
// shared pattern-list machinery; the alternative pattern wrapper node still
// closes with an error.
fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_alternative_pattern_unclosed.carbon:[[@LINE+4]]:24: error: expected `,` or `)` [UnexpectedTokenAfterListElement]
    // CHECK:STDERR:     case .Ok(value: i32 => { return 1; }
    // CHECK:STDERR:                        ^~
    // CHECK:STDERR:
    case .Ok(value: i32 => { return 1; }
    default => { return 0; }
  }
  return -1;
}
