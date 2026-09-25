// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_form_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_form_binding.carbon

// A form binding in a `case` pattern stays behind its own gate (string
// narrowed from the combined W4 slice-gate string at W8c, W-008 plan
// §3.3): form bindings are upstream-TODO in ALL local contexts (`support
// local form bindings`, let/form.carbon), so this is not match residue
// (plan §0 R5). Pinned to the arm's `case` token, the `Kind::MatchCaseArm`
// gate in handle_binding_pattern.cpp.

fn F(x: i32) {
  match (x) {
    // CHECK:STDERR: fail_todo_form_binding.carbon:[[@LINE+4]]:5: error: semantics TODO: `form binding in match `case` pattern` [SemanticsTodo]
    // CHECK:STDERR:     case n:? form(var i32) => { return; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case n:? form(var i32) => { return; }
    default => { return; }
  }
}
