// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/match/guarded_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/match/guarded_default.carbon

// A `default` clause accepts a guard, mirroring the `case` guard production
// (docs/design/pattern_matching.md, "Guards": "this facility is also
// available for `default` clauses"; p2188:552-553). A guarded `default` can
// fail its guard, so — unlike an unguarded `default` — `case` arms and
// another `default` may follow it.

fn f(x: i32) -> i32 {
  match (x) {
    case 0 => { return 0; }
    default if (x < 0) => { return 1; }
    case 1 => { return 2; }
    default if (x > 10) => { return 3; }
    default => { return 4; }
  }
  return -1;
}

// A guarded `default` may also be the last arm.
fn g(x: i32) -> i32 {
  match (x) {
    case 0 => { return 0; }
    default if (x < 0) => { return 1; }
  }
  return -1;
}
