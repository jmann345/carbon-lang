// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_alternative_non_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_alternative_non_choice.carbon

// A leading-dot alternative pattern at the case root against a NON-choice
// scrutinee keeps the combined W4 slice-gate string, at the
// `AlternativePattern` non-choice gate in handle_match.cpp. W-008 plan §0
// recorded that gate as an unreachable-by-design backstop; it is in fact
// reachable from an in-slice integer scrutinee (this pin, added at W8c),
// and the combined string honestly describes the shape — a case pattern
// that is neither an integer-constant expression nor any other in-slice
// kind.

fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_todo_alternative_non_choice.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case .Foo => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case .Foo => { return 1; }
    default => { return 0; }
  }
  return -1;
}
