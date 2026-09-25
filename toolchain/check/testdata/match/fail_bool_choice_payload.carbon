// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_bool_choice_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_bool_choice_payload.carbon

// Usefulness on bool choice-payload subpatterns (W-076 plan §1.7, §4 F8):
// a bool constant payload keys as `BoolConst` under the `Alternative` key
// node through the generic leaf hook, so duplicate `.Tag(true)` arms and
// an irrefutable payload binding subsuming a later constant both
// diagnose, exactly as integer payloads do.

// --- fail_duplicate_payload_true.carbon
library "[[@TEST_NAME]]";

choice Wrap {
  Tag(b: bool),
  None
}

// The second `.Tag(true)` can never match; single-prior note.
fn F(w: Wrap) -> i32 {
  match (w) {
    case .Tag(true) => { return 1; }
    case .Tag(true) => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_payload_binding_subsumes.carbon
library "[[@TEST_NAME]]";

choice Wrap {
  Tag(b: bool),
  None
}

// The irrefutable payload binding keys `Wildcard` in the payload slot,
// subsuming the later `BoolConst`: `.Tag(true)` is dead.
fn G(w: Wrap) -> i32 {
  match (w) {
    case .Tag(v: bool) => { if (v) { return 1; } return 0; }
    case .Tag(true) => { return 2; }
    default => { return 3; }
  }
  return -1;
}
