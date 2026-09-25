// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/bool_tuple_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/bool_tuple_scrutinee.carbon

// Tuple elements of bool (W-076 plan §1.5): the tuple walk gates by
// pattern kind and shape, not element type, so once the scrutinee gate
// admits `bool` elementwise and the constant admission accepts
// `BoolLiteral`, bool tuple elements compare through the same generic
// leaf lane as the whole-pattern case (`bool as EqWith(bool)`).

// --- mixed_tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(t: (bool, i32)) -> i32 {
  match (t) {
    case (true, 1) => { return 1; }
    case (false, n: i32) => { return n; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- bool_pair_keeps_default.carbon
library "[[@TEST_NAME]]";

// Tuple exhaustiveness itself stays `default`-requiring: only the bool
// ROOT rule extends (W-076 plan §4 P5), so a `(bool, bool)` match whose
// constant arms enumerate all four value pairs still keeps its `default`
// arm. The boundary is pinned here explicitly.
//@dump-sem-ir-begin
fn G(t: (bool, bool)) -> i32 {
  match (t) {
    case (false, false) => { return 0; }
    case (false, true) => { return 1; }
    case (true, false) => { return 2; }
    case (true, true) => { return 3; }
    default => { return 4; }
  }
  return -1;
}
//@dump-sem-ir-end
