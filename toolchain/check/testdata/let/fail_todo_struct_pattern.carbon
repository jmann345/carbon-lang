// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/let/fail_todo_struct_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/let/fail_todo_struct_pattern.carbon

// The W-077 slice boundary: struct patterns check in `match` `case`
// position ONLY. Every other context — `let`, `var`, parameter lists, and
// a `let` inside a match ARM BODY (whose innermost full-pattern is a
// `NameBindingDecl`, the arm's own pattern having been popped before the
// body checks) — keeps the upstream `struct pattern start` TODO, which
// aborts checking at the pattern's opening brace. These are the first
// check-side pins of that surviving TODO, closing the recorded golden gap
// in the direction the slice leaves it; the let/var/param lane is filed as
// follow-up work.

// --- fail_todo_let.carbon
library "[[@TEST_NAME]]";

fn F() {
  // CHECK:STDERR: fail_todo_let.carbon:[[@LINE+4]]:7: error: semantics TODO: `struct pattern start` [SemanticsTodo]
  // CHECK:STDERR:   let {x: i32} = {.x = 1};
  // CHECK:STDERR:       ^
  // CHECK:STDERR:
  let {x: i32} = {.x = 1};
}

// --- fail_todo_var.carbon
library "[[@TEST_NAME]]";

fn F() {
  // CHECK:STDERR: fail_todo_var.carbon:[[@LINE+4]]:7: error: semantics TODO: `struct pattern start` [SemanticsTodo]
  // CHECK:STDERR:   var {.x = y: i32} = {.x = 1};
  // CHECK:STDERR:       ^
  // CHECK:STDERR:
  var {.x = y: i32} = {.x = 1};
}

// --- fail_todo_param.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_param.carbon:[[@LINE+4]]:6: error: semantics TODO: `struct pattern start` [SemanticsTodo]
// CHECK:STDERR: fn F({x: i32});
// CHECK:STDERR:      ^
// CHECK:STDERR:
fn F({x: i32});

// --- fail_todo_let_in_match_arm_body.carbon
library "[[@TEST_NAME]]";

// The regression trap for any future gate re-siting: inside the arm's
// BODY the gate must still fire — the body's innermost full-pattern is
// the `let`'s `NameBindingDecl`, not the arm's `MatchCaseArm`.
fn F(x: i32) -> i32 {
  match (x) {
    case n: i32 => {
      // CHECK:STDERR: fail_todo_let_in_match_arm_body.carbon:[[@LINE+4]]:11: error: semantics TODO: `struct pattern start` [SemanticsTodo]
      // CHECK:STDERR:       let {y: i32} = {.y = n};
      // CHECK:STDERR:           ^
      // CHECK:STDERR:
      let {y: i32} = {.y = n};
      return y;
    }
  }
  return -1;
}
