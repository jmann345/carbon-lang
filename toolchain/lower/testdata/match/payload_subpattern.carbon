// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/payload_subpattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/payload_subpattern.carbon

// The W-008 plan §4 R-2 anti-regression pin: the payload load for a
// payload-literal arm (`case .Ok(42)`) must sit in a block reached only
// when the discriminant compare succeeds — the payload region of a
// non-active alternative is uninitialized storage, and a hoisted load
// would feed poison to a branch.

choice IntResult {
  Ok(value: i32),
  Err
}

fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(42) => { return 1; }
    case .Ok(value: i32) => { return value; }
    case .Err => { return -1; }
  }
  return -2;
}
