// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_choice_expr_case.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_choice_expr_case.carbon

// An expression case pattern on a choice scrutinee that names no
// alternative of the scrutinee's choice type (here an integer literal)
// stays behind its own gate, narrowed from the combined W4 slice-gate
// string at W8c (W-008 plan §3.3): the design compares it with `==`, which
// in-slice choices do not implement (plan §1.3). Pinned to the arm's
// `case` token, the choice-scrutinee backstop in `DoMatchCaseExprPattern`
// (pattern_match.cpp).

choice Two {
  A,
  B
}

fn F(c: Two) -> i32 {
  match (c) {
    // CHECK:STDERR: fail_todo_choice_expr_case.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case expression pattern on a choice scrutinee that is not an alternative` [SemanticsTodo]
    // CHECK:STDERR:     case 5 => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case 5 => { return 1; }
    default => { return 0; }
  }
  return -1;
}
