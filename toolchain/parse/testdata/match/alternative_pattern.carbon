// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/alternative_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/alternative_pattern.carbon

// Choice alternative patterns at the root of a `case`: bare `.Name`, a
// single-subpattern payload list, a multi-subpattern payload list (with and
// without a trailing comma), and empty parentheses for a zero-payload
// function-like alternative. A leading-dot pattern is only an alternative
// pattern at the case root; `.Err` inside parentheses stays an ordinary
// (expression) pattern.
fn F(x: i32) -> i32 {
  match (x) {
    case .Err => { return 0; }
    case .Ok(value: i32) => { return 1; }
    case .Pair(a: i32, b: i32) => { return 2; }
    case .Single(a: i32,) => { return 3; }
    case .On() => { return 4; }
    case (.Err) => { return 5; }
    default => { return 6; }
  }
  return -1;
}
