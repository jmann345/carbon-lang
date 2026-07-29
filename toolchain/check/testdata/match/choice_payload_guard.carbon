// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_payload_guard.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_payload_guard.carbon

// A guard on a payload-destructuring alternative arm (re-platform plan
// S2d): the arm's test compares the discriminant, the bind pass extracts
// the payload and initializes the payload binding, and only then does the
// guard evaluate — with the payload binding in scope
// (docs/design/pattern_matching.md, "Guards"). A failed guard falls
// through to the next arm: the same alternative is matched twice — once
// guarded, once unguarded — so `.Ok` values split on the guard while
// `.Err` and `default` stay reachable.
//@dump-sem-ir-begin
choice IntResult {
  Ok(value: i32),
  Err
}

fn Consume(r: IntResult) -> i32 {
  match (r) {
    case .Ok(v: i32) if (v > 0) => { return v; }
    case .Ok(w: i32) => { return w - 1; }
    case .Err => { return -10; }
    default => { return -2; }
  }
  return -3;
}
//@dump-sem-ir-end
