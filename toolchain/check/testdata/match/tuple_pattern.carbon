// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/tuple_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/tuple_pattern.carbon

// Tuple case patterns over tuple scrutinees (W-008 W8a): elements are
// constant-integer expressions, bindings, and nested tuples of those. The
// test pass compares refutable elements against the scrutinee's own tuple
// type and folds the conditions into one bool; bindings initialize in the
// bind pass, in the arm's body block.

// --- literal_scrutinee.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F() -> i32 {
  match ((1, 2)) {
    case (1, 2) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- all_expr.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (1, 2) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- all_binding.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (a: i32, b: i32) => { return a + b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- mixed.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (1, b: i32) => { return b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- expr_element_conversion.carbon
library "[[@TEST_NAME]]";

// An initializing expression element (`2 + 3` returns through a return
// slot): the refutable engine converts the spliced result to a value at
// splice time (W-008 plan §2.1(b) amendment F5).
//@dump-sem-ir-begin
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case (2 + 3, b: i32) => { return b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- nested_tuple.carbon
library "[[@TEST_NAME]]";

// The design's flagship mixed shape (docs/design/pattern_matching.md,
// `case (42, (x: f32, y: f32))`), on integer tuples.
//@dump-sem-ir-begin
fn F(p: (i32, (i32, i32))) -> i32 {
  match (p) {
    case (42, (x: i32, y: i32)) => { return x + y; }
    case (n: i32, (1, 2)) => { return n; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- var_scrutinee.carbon
library "[[@TEST_NAME]]";

// A NON-literal tuple scrutinee (a `var` local): both passes must walk the
// scrutinee's own tuple type — converting to the pattern's tuple type would
// reject this design-valid shape (W-008 plan §2.1(d)).
//@dump-sem-ir-begin
fn F() -> i32 {
  var t: (i32, i32) = (1, 2);
  match (t) {
    case (1, b: i32) => { return b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- fail_arity_literal_scrutinee.carbon
library "[[@TEST_NAME]]";

// The scrutinee is converted to a value at `MatchCondition`, so even a
// tuple-literal scrutinee reaches the engine as a tuple value and arity
// mismatches diagnose against the scrutinee's tuple type.
fn F() -> i32 {
  match ((1, 2)) {
    // CHECK:STDERR: fail_arity_literal_scrutinee.carbon:[[@LINE+4]]:10: error: tuple pattern expects 3 elements, but match scrutinee has 2 [MatchCaseTuplePatternWrongArity]
    // CHECK:STDERR:     case (1, 2, 3) => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~~
    // CHECK:STDERR:
    case (1, 2, 3) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_arity_var_scrutinee.carbon
library "[[@TEST_NAME]]";

fn F() -> i32 {
  var t: (i32, i32) = (1, 2);
  match (t) {
    // CHECK:STDERR: fail_arity_var_scrutinee.carbon:[[@LINE+4]]:10: error: tuple pattern expects 1 element, but match scrutinee has 2 [MatchCaseTuplePatternWrongArity]
    // CHECK:STDERR:     case (1,) => { return 1; }
    // CHECK:STDERR:          ^~~~
    // CHECK:STDERR:
    case (1,) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_non_tuple_scrutinee.carbon
library "[[@TEST_NAME]]";

// A tuple pattern against a non-tuple scrutinee stays behind the W4
// slice-gate fallback in `MatchCase` — the shape that still reaches it
// after W8a's classification.
fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_todo_non_tuple_scrutinee.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case (1, 2) => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, 2) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_nested_non_tuple.carbon
library "[[@TEST_NAME]]";

// A nested tuple pattern against a non-tuple element hits the same gate,
// from inside the engine's scrutinee-typed walk.
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    // CHECK:STDERR: fail_todo_nested_non_tuple.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case (1, (2, 3)) => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case (1, (2, 3)) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
