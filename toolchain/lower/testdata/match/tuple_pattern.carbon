// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/tuple_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/tuple_pattern.carbon

// Tuple case patterns must lower to elementwise compares folded into one
// arm condition (the `and`-shape block_arg chain), with the arm's bindings
// re-extracted in the arm's body block. Both the design's nested mixed
// shape on a by-value parameter and a mixed pattern on a `var` (non-literal)
// scrutinee are covered.

fn Nested(p: (i32, (i32, i32))) -> i32 {
  match (p) {
    case (42, (x: i32, y: i32)) => { return x + y; }
    case (n: i32, (1, 2)) => { return n; }
    default => { return -1; }
  }
  return -2;
}

fn VarScrutinee() -> i32 {
  var t: (i32, i32) = (1, 2);
  match (t) {
    case (1, b: i32) => { return b; }
    default => { return -1; }
  }
  return -2;
}
