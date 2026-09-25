// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/bool_choice_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/bool_choice_payload.carbon

// Bool constants as choice-alternative payload subpatterns (W-076 plan
// §1.7): the constant admission in `DoMatchCaseExprPattern` is the single
// shared leaf lane for every expression-pattern position, and `bool` is
// an in-slice choice payload type (`IsInSliceChoicePayloadType`), so
// `case .Tag(true)` goes live with the W-076 widening through the same
// generic lane as tuple elements — no payload-specific code. Coverage is
// unaffected: a `.Tag(true)` payload is refutable, so the arm records
// nothing toward exhaustiveness — the `.Some(42)` rule — and only
// `.None` records, so the match keeps its `default` arm.

//@dump-sem-ir-begin
choice Wrap {
  Tag(b: bool),
  None
}

fn F(w: Wrap) -> i32 {
  match (w) {
    case .Tag(true) => { return 1; }
    case .Tag(false) => { return 0; }
    case .None => { return 2; }
    default => { return 3; }
  }
  return -1;
}
//@dump-sem-ir-end
