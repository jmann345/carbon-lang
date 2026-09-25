// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/bool_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/bool_scrutinee.carbon

// The W-076 exhaustive bool dispatch shape (design's `IsTrue` example,
// docs/design/pattern_matching.md): each arm's condition lowers through
// the pre-existing builtin `bool.eq` lane (an `icmp eq i1`, which trivial
// optimization folds to the scrutinee itself), and the arm bodies
// converge on the resumption block — dynamically dead after the last
// arm's else edge when the arms are exhaustive.

fn IsTrue(b: bool) -> i32 {
  match (b) {
    case false => { return 0; }
    case true => { return 1; }
  }
  return -1;
}
