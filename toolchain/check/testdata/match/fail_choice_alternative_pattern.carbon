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

// --- fail_bare_payload_alternative.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Success(value: i32),
  Failure
}

// Parentheses are present in an alternative pattern exactly when the
// alternative declares a parameter list (p2188), so bare `.Success` is an error.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_bare_payload_alternative.carbon:[[@LINE+4]]:10: error: alternative `Success` is declared with a parameter list, so its pattern requires parentheses [MatchAlternativeMissingParens]
    // CHECK:STDERR:     case .Success => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~
    // CHECK:STDERR:
    case .Success => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_parens_on_constant_alternative.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Success(value: i32),
  Failure
}

// The other direction of the parens-iff-parameter-list rule: `Failure` declares
// no parameter list, so `.Failure()` is an error.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_parens_on_constant_alternative.carbon:[[@LINE+4]]:10: error: alternative `Failure` is declared without a parameter list, so its pattern cannot have parentheses [MatchAlternativeUnexpectedParens]
    // CHECK:STDERR:     case .Failure() => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~~~
    // CHECK:STDERR:
    case .Failure() => { return 1; }
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
    // CHECK:STDERR: fail_wrong_arity.carbon:[[@LINE+8]]:10: error: alternative pattern has 1 subpattern, but alternative `Pair` is declared with 2 parameters [MatchAlternativeArgCountMismatch]
    // CHECK:STDERR:     case .Pair(a: i32) => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_wrong_arity.carbon:[[@LINE+4]]:16: warning: binding `a` unused [UnusedBinding]
    // CHECK:STDERR:     case .Pair(a: i32) => { return 1; }
    // CHECK:STDERR:                ^~~~~~
    // CHECK:STDERR:
    case .Pair(a: i32) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_unknown_alternative.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Success(value: i32),
  Failure
}

// An unknown alternative name gets the standard member-access diagnostic,
// with or without a payload list.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_unknown_alternative.carbon:[[@LINE+8]]:10: error: member name `Nope` not found in `IntResult` [MemberNameNotFoundInInstScope]
    // CHECK:STDERR:     case .Nope(x: i32) => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_unknown_alternative.carbon:[[@LINE+4]]:16: warning: binding `x` unused [UnusedBinding]
    // CHECK:STDERR:     case .Nope(x: i32) => { return 1; }
    // CHECK:STDERR:                ^~~~~~
    // CHECK:STDERR:
    case .Nope(x: i32) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_nested_designator_subpattern.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Success(value: i32),
  Failure
}

// A leading-dot designator inside a payload list is not an alternative
// pattern (nested alternative patterns cannot arise in-slice: payload types
// are scalars); it checks as an ordinary designator expression, which needs
// `.Self` in scope. The errored element poisons the arm's condition, and
// checking continues.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_nested_designator_subpattern.carbon:[[@LINE+9]]:19: error: name `.Self` not found [NameNotFound]
    // CHECK:STDERR:     case .Success(.Failure) => { return 1; }
    // CHECK:STDERR:                   ^~~~~~~~
    // CHECK:STDERR: fail_nested_designator_subpattern.carbon: note: designator may only be used when `.Self` is in scope [NoPeriodSelfForDesignator]
    // CHECK:STDERR:
    // CHECK:STDERR: fail_nested_designator_subpattern.carbon:[[@LINE+4]]:5: error: name `Core.EqWith` implicitly referenced here, but not found [CoreNameNotFound]
    // CHECK:STDERR:     case .Success(.Failure) => { return 1; }
    // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR:
    case .Success(.Failure) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_qualified_pattern.carbon
library "[[@TEST_NAME]]";

choice IntResult {
  Success(value: i32),
  Failure
}

// Only the leading-dot alternative pattern spelling is in slice 1
// (decision-log W5 SF-4); the qualified form is a recorded work item.
fn F(r: IntResult) -> i32 {
  match (r) {
    // CHECK:STDERR: fail_todo_qualified_pattern.carbon:[[@LINE+4]]:5: error: semantics TODO: `qualified alternative pattern in match case` [SemanticsTodo]
    // CHECK:STDERR:     case IntResult.Failure => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case IntResult.Failure => { return 1; }
    default => { return 0; }
  }
  return -1;
}
