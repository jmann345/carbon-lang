// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_payload_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_payload_pattern.carbon

// A payload alternative pattern destructures the alternative's payload: the
// arm's test compares the scrutinee's discriminant, and the bind pass
// extracts the payload tuple from the payload region (offset-0 overlap per
// F-007k) and initializes the payload binding in the arm's scope, where the
// bound value is usable in the arm's body. Mixed arms: a payload
// alternative, a payload-free alternative, and `default` (still required
// until exhaustiveness lands, S2e).
//@dump-sem-ir-begin
choice IntResult {
  Ok(value: i32),
  Err
}

fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(value: i32) => { return value; }
    case .Err => { return -1; }
    default => { return -2; }
  }
  return -3;
}
//@dump-sem-ir-end
