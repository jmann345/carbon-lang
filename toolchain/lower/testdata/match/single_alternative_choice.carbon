// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/single_alternative_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/single_alternative_choice.carbon

// The W-068 dispatch shape at lowering: a single-alternative choice has no
// integer discriminant, so — unlike choice_payload.carbon's
// compare-and-branch chain — the arm's condition is a constant true (no
// discriminant load, no icmp), while the payload access stays real: the
// arm's body reads the payload tuple element through the payload region
// field of the `{(), payload}` representation, exactly as in the
// multi-alternative lowering.

choice OneShot {
  Only(x: i32)
}

fn Get(o: OneShot) -> i32 {
  match (o) {
    case .Only(v: i32) => { return v; }
  }
  return -1;
}
