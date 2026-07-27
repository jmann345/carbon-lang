// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_choice_payload_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_choice_payload_pattern.carbon

// --- fail_todo_payload_pattern_args.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// `.Ok(...)` destructures the alternative's payload: slice 2.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_todo_payload_pattern_args.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case pattern destructuring a choice payload` [SemanticsTodo]
    // CHECK:STDERR:     case .Ok(42) => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case .Ok(42) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_payload_pattern_bare.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// Bare `.Ok` names the payload alternative's constructor function; matching
// it is also payload destructuring (slice 2).
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_todo_payload_pattern_bare.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case pattern destructuring a choice payload` [SemanticsTodo]
    // CHECK:STDERR:     case .Ok => { return 1; }
    // CHECK:STDERR:     ^~~~~~~~~~~
    // CHECK:STDERR:
    case .Ok => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_qualified_pattern.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// Only the leading-dot alternative pattern spelling is in slice 1
// (decision-log W5 SF-4); the qualified form is a recorded work item.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_todo_qualified_pattern.carbon:[[@LINE+4]]:5: error: semantics TODO: `qualified alternative pattern in match case` [SemanticsTodo]
    // CHECK:STDERR:     case IntResult.Err => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case IntResult.Err => { return 1; }
    default => { return 0; }
  }
  return -1;
}
