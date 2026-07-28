// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_choice_alternative_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_choice_alternative_pattern.carbon

// --- fail_todo_expr_subpattern.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// An expression subpattern inside a payload list (a refutable payload
// compare) is a later slice; only bare `name: type` binding subpatterns are
// in-slice (decision-log W5 SF-5).
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_todo_expr_subpattern.carbon:[[@LINE+4]]:14: error: semantics TODO: `non-binding subpattern in match `case` alternative pattern` [SemanticsTodo]
    // CHECK:STDERR:     case .Ok(42) => { return 1; }
    // CHECK:STDERR:              ^~
    // CHECK:STDERR:
    case .Ok(42) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_bare_payload_alternative.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// Parentheses are present in an alternative pattern exactly when the
// alternative declares a parameter list (p2188), so bare `.Ok` is an error.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_bare_payload_alternative.carbon:[[@LINE+4]]:10: error: alternative `Ok` is declared with a parameter list, so its pattern requires parentheses [MatchAlternativeMissingParens]
    // CHECK:STDERR:     case .Ok => { return 1; }
    // CHECK:STDERR:          ^
    // CHECK:STDERR:
    case .Ok => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_parens_on_constant_alternative.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// The other direction of the parens-iff-parameter-list rule: `Err` declares
// no parameter list, so `.Err()` is an error.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_parens_on_constant_alternative.carbon:[[@LINE+4]]:10: error: alternative `Err` is declared without a parameter list, so its pattern cannot have parentheses [MatchAlternativeUnexpectedParens]
    // CHECK:STDERR:     case .Err() => { return 1; }
    // CHECK:STDERR:          ^
    // CHECK:STDERR:
    case .Err() => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_wrong_arity.carbon
library "[[@TEST_NAME]]";

choice Shape {
  Pair(a: i32, b: i32),
  Dot
}

// The pattern must reproduce the alternative's parameter list, one
// subpattern per declared parameter.
fn F(s: Shape) -> i32 {
  match (s) {
    // CHECK:STDERR: fail_wrong_arity.carbon:[[@LINE+4]]:10: error: alternative pattern has 1 subpattern, but alternative `Pair` is declared with 2 parameters [MatchAlternativeArgCountMismatch]
    // CHECK:STDERR:     case .Pair(a: i32) => { return 1; }
    // CHECK:STDERR:          ^
    // CHECK:STDERR:
    case .Pair(a: i32) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_unknown_alternative.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// An unknown alternative name gets the standard member-access diagnostic,
// with or without a payload list.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_unknown_alternative.carbon:[[@LINE+4]]:10: error: member name `Nope` not found in `IntResult` [MemberNameNotFoundInInstScope]
    // CHECK:STDERR:     case .Nope(x: i32) => { return 1; }
    // CHECK:STDERR:          ^
    // CHECK:STDERR:
    case .Nope(x: i32) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_nested_designator_subpattern.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Ok(value: i32),
  Err
}

// A leading-dot designator inside a payload list is not an alternative
// pattern (nested alternative patterns cannot arise in-slice: payload types
// are scalars); it checks as an ordinary designator expression, which needs
// `.Self` in scope.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_nested_designator_subpattern.carbon:[[@LINE+5]]:14: error: name `.Self` not found [NameNotFound]
    // CHECK:STDERR:     case .Ok(.Err) => { return 1; }
    // CHECK:STDERR:              ^~~~
    // CHECK:STDERR: note: designator may only be used when `.Self` is in scope [NoPeriodSelfForDesignator]
    // CHECK:STDERR:
    case .Ok(.Err) => { return 1; }
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
