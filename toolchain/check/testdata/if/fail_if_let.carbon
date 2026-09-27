// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/if/fail_if_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/if/fail_if_let.carbon

// Pattern-condition negatives (W-012): scoping (the bindings are visible in
// the then-block only), the irrefutable-pattern warning, the reserved
// `and`/`or` chain, the tombstoned initializer, late alternative resolution
// with the `match` diagnostics, `?` in a binding's type, and the engine's
// slice gates reached through the shared context (each an abort, so one row
// per split file).

// --- fail_binding_in_else.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

// CHECK:STDERR: fail_binding_in_else.carbon:[[@LINE+4]]:8: warning: binding `n` unused [UnusedBinding]
// CHECK:STDERR: fn Use(n: i32) {}
// CHECK:STDERR:        ^~~~~~
// CHECK:STDERR:
fn Use(n: i32) {}

fn F(o: OptInt) {
  if (let .Some(n: i32) = o) {
    Use(n);
  } else {
    // CHECK:STDERR: fail_binding_in_else.carbon:[[@LINE+4]]:9: error: name `n` not found [NameNotFound]
    // CHECK:STDERR:     Use(n);
    // CHECK:STDERR:         ^
    // CHECK:STDERR:
    Use(n);
  }
}

// --- fail_binding_after.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

// CHECK:STDERR: fail_binding_after.carbon:[[@LINE+4]]:8: warning: binding `n` unused [UnusedBinding]
// CHECK:STDERR: fn Use(n: i32) {}
// CHECK:STDERR:        ^~~~~~
// CHECK:STDERR:
fn Use(n: i32) {}

fn F(o: OptInt) {
  if (let .Some(n: i32) = o) {
    Use(n);
  }
  // CHECK:STDERR: fail_binding_after.carbon:[[@LINE+4]]:7: error: name `n` not found [NameNotFound]
  // CHECK:STDERR:   Use(n);
  // CHECK:STDERR:       ^
  // CHECK:STDERR:
  Use(n);
}

// --- fail_binding_in_else_if_condition.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

// CHECK:STDERR: fail_binding_in_else_if_condition.carbon:[[@LINE+4]]:8: warning: binding `n` unused [UnusedBinding]
// CHECK:STDERR: fn Use(n: i32) {}
// CHECK:STDERR:        ^~~~~~
// CHECK:STDERR:
fn Use(n: i32) {}

fn F(o: OptInt) {
  if (let .Some(n: i32) = o) {
    Use(n);
  // CHECK:STDERR: fail_binding_in_else_if_condition.carbon:[[@LINE+4]]:14: error: name `n` not found [NameNotFound]
  // CHECK:STDERR:   } else if (n > 0) {
  // CHECK:STDERR:              ^
  // CHECK:STDERR:
  } else if (n > 0) {
  }
}

// --- irrefutable_binding.carbon
library "[[@TEST_NAME]]";

// A binding root cannot fail: a warning, not an error.
// CHECK:STDERR: irrefutable_binding.carbon:[[@LINE+4]]:8: warning: binding `n` unused [UnusedBinding]
// CHECK:STDERR: fn Use(n: i32) {}
// CHECK:STDERR:        ^~~~~~
// CHECK:STDERR:
fn Use(n: i32) {}

fn F(x: i32) {
  // CHECK:STDERR: irrefutable_binding.carbon:[[@LINE+4]]:7: warning: pattern always matches, so this binding cannot fail [IrrefutablePatternAlwaysMatches]
  // CHECK:STDERR:   if (let n: i32 = x) {
  // CHECK:STDERR:       ^~~
  // CHECK:STDERR:
  if (let n: i32 = x) {
    Use(n);
  }
}

// --- irrefutable_single_alternative.carbon
library "[[@TEST_NAME]]";

// A single-alternative choice's alternative with an all-binding payload
// cannot fail either (the test is a constant `true`).
choice Only {
  Just(x: i32)
}

// CHECK:STDERR: irrefutable_single_alternative.carbon:[[@LINE+4]]:8: warning: binding `n` unused [UnusedBinding]
// CHECK:STDERR: fn Use(n: i32) {}
// CHECK:STDERR:        ^~~~~~
// CHECK:STDERR:
fn Use(n: i32) {}

fn F(o: Only) {
  // CHECK:STDERR: irrefutable_single_alternative.carbon:[[@LINE+4]]:7: warning: pattern always matches, so this binding cannot fail [IrrefutablePatternAlwaysMatches]
  // CHECK:STDERR:   if (let .Just(n: i32) = o) {
  // CHECK:STDERR:       ^~~
  // CHECK:STDERR:
  if (let .Just(n: i32) = o) {
    Use(n);
  }
}

// --- fail_chain_reserved.carbon
library "[[@TEST_NAME]]";

fn F(x: bool, y: bool) {
  // CHECK:STDERR: fail_chain_reserved.carbon:[[@LINE+4]]:18: error: `and`/`or` at the top level of a pattern condition's initializer is reserved for pattern chaining; parenthesize the expression [PatternConditionChainReserved]
  // CHECK:STDERR:   if (let true = x and y) {
  // CHECK:STDERR:                  ^~~~~~~
  // CHECK:STDERR:
  if (let true = x and y) {
  }
}

// --- fail_binding_in_initializer.carbon
library "[[@TEST_NAME]]";

// The bindings are tombstoned while the initializer is checked; the errored
// initializer then fails the scrutinee gate.
// CHECK:STDERR: fail_binding_in_initializer.carbon:[[@LINE+4]]:8: warning: binding `n` unused [UnusedBinding]
// CHECK:STDERR: fn Use(n: i32) {}
// CHECK:STDERR:        ^~~~~~
// CHECK:STDERR:
fn Use(n: i32) {}

fn F() {
  // CHECK:STDERR: fail_binding_in_initializer.carbon:[[@LINE+8]]:20: error: `n` used before initialization [UsedBeforeInitialization]
  // CHECK:STDERR:   if (let n: i32 = n) {
  // CHECK:STDERR:                    ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_binding_in_initializer.carbon:[[@LINE+4]]:20: error: semantics TODO: `refutable pattern binding on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   if (let n: i32 = n) {
  // CHECK:STDERR:                    ^
  // CHECK:STDERR:
  if (let n: i32 = n) {
    Use(n);
  }
}

// --- fail_unknown_alternative.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  // CHECK:STDERR: fail_unknown_alternative.carbon:[[@LINE+4]]:11: error: member name `Nope` not found in `OptInt` [MemberNameNotFoundInInstScope]
  // CHECK:STDERR:   if (let .Nope = opt) {
  // CHECK:STDERR:           ^~~~~
  // CHECK:STDERR:
  if (let .Nope = opt) {
  }
}

// --- fail_missing_parens.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  // CHECK:STDERR: fail_missing_parens.carbon:[[@LINE+4]]:11: error: alternative `Some` is declared with a parameter list, so its pattern requires parentheses [MatchAlternativeMissingParens]
  // CHECK:STDERR:   if (let .Some = opt) {
  // CHECK:STDERR:           ^~~~~
  // CHECK:STDERR:
  if (let .Some = opt) {
  }
}

// --- fail_unexpected_parens.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  // CHECK:STDERR: fail_unexpected_parens.carbon:[[@LINE+4]]:11: error: alternative `None` is declared without a parameter list, so its pattern cannot have parentheses [MatchAlternativeUnexpectedParens]
  // CHECK:STDERR:   if (let .None(1) = opt) {
  // CHECK:STDERR:           ^~~~~~~~
  // CHECK:STDERR:
  if (let .None(1) = opt) {
  }
}

// --- fail_arg_count.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  // CHECK:STDERR: fail_arg_count.carbon:[[@LINE+4]]:11: error: alternative pattern has 2 subpatterns, but alternative `Some` is declared with 1 parameter [MatchAlternativeArgCountMismatch]
  // CHECK:STDERR:   if (let .Some(1, 2) = opt) {
  // CHECK:STDERR:           ^~~~~~~~~~~
  // CHECK:STDERR:
  if (let .Some(1, 2) = opt) {
  }
}

// --- unused_binding.carbon
library "[[@TEST_NAME]]";

// An unused if-let binding warns at the if-let scope's pop, like any local.
choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  // CHECK:STDERR: unused_binding.carbon:[[@LINE+4]]:17: warning: binding `n` unused [UnusedBinding]
  // CHECK:STDERR:   if (let .Some(n: i32) = opt) {
  // CHECK:STDERR:                 ^~~~~~
  // CHECK:STDERR:
  if (let .Some(n: i32) = opt) {
  }
}

// --- fail_question_in_pattern_type.carbon
library "[[@TEST_NAME]]";

// `?` inside the pattern (a binding's type expression) is at region depth
// greater than 1 and stays banned.
choice OptInt {
  Some(x: i32),
  None
}

fn F() -> i32 { return 0; }

fn G(opt: OptInt) -> i32 {
  // CHECK:STDERR: fail_question_in_pattern_type.carbon:[[@LINE+4]]:20: error: `?` cannot be used inside a pattern, a `case` guard, or a binding's type expression [QuestionInPatternContext]
  // CHECK:STDERR:   if (let .Some(n: F()?) = opt) {
  // CHECK:STDERR:                    ^~~~
  // CHECK:STDERR:
  if (let .Some(n: F()?) = opt) {
    return n;
  }
  return 0;
}

// --- fail_todo_unsupported_scrutinee.carbon
library "[[@TEST_NAME]]";

class C {}

fn F(c: C) {
  // CHECK:STDERR: fail_todo_unsupported_scrutinee.carbon:[[@LINE+4]]:18: error: semantics TODO: `refutable pattern binding on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   if (let n: C = c) {
  // CHECK:STDERR:                  ^
  // CHECK:STDERR:
  if (let n: C = c) {
  }
}

// --- fail_todo_binding_free_var.carbon
library "[[@TEST_NAME]]";

fn F(x: i32) {
  // CHECK:STDERR: fail_todo_binding_free_var.carbon:[[@LINE+4]]:7: error: semantics TODO: `binding-free `var` in match `case` pattern` [SemanticsTodo]
  // CHECK:STDERR:   if (var 5 = x) {
  // CHECK:STDERR:       ^~~
  // CHECK:STDERR:
  if (var 5 = x) {
  }
}

// --- fail_todo_var_bare_alternative.carbon
library "[[@TEST_NAME]]";

// `var` on a binding-free pattern has no storage to name: the empty
// synthetic payload root of a bare `.None` hits the binding-free-`var` gate
// at pattern time (fork/w012/plan.md §1.1).
choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  // CHECK:STDERR: fail_todo_var_bare_alternative.carbon:[[@LINE+4]]:7: error: semantics TODO: `binding-free `var` in match `case` pattern` [SemanticsTodo]
  // CHECK:STDERR:   if (var .None = opt) {
  // CHECK:STDERR:       ^~~
  // CHECK:STDERR:
  if (var .None = opt) {
  }
}

// --- fail_todo_var_refutable_tuple.carbon
library "[[@TEST_NAME]]";

// A `var` root over a refutable subtree stays behind the engine's slice
// gate, in a pattern condition as in a `case`.
fn F(pair: (i32, i32)) {
  // CHECK:STDERR: fail_todo_var_refutable_tuple.carbon:[[@LINE+4]]:7: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
  // CHECK:STDERR:   if (var (0, n: i32) = pair) {
  // CHECK:STDERR:       ^~~
  // CHECK:STDERR:
  if (var (0, n: i32) = pair) {
  }
}

// --- fail_todo_form_binding.carbon
library "[[@TEST_NAME]]";

fn F(x: i32) {
  // CHECK:STDERR: fail_todo_form_binding.carbon:[[@LINE+4]]:7: error: semantics TODO: `form binding in match `case` pattern` [SemanticsTodo]
  // CHECK:STDERR:   if (let n:? form(var i32) = x) {
  // CHECK:STDERR:       ^~~
  // CHECK:STDERR:
  if (let n:? form(var i32) = x) {
  }
}

// --- fail_todo_compile_time_binding.carbon
library "[[@TEST_NAME]]";

fn F(x: i32) {
  // CHECK:STDERR: fail_todo_compile_time_binding.carbon:[[@LINE+4]]:7: error: semantics TODO: `compile-time binding in match `case` pattern` [SemanticsTodo]
  // CHECK:STDERR:   if (let template n: i32 = x) {
  // CHECK:STDERR:       ^~~
  // CHECK:STDERR:
  if (let template n: i32 = x) {
  }
}

// --- fail_todo_qualified_alternative.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  // CHECK:STDERR: fail_todo_qualified_alternative.carbon:[[@LINE+4]]:7: error: semantics TODO: `qualified alternative pattern in match case` [SemanticsTodo]
  // CHECK:STDERR:   if (let OptInt.None = opt) {
  // CHECK:STDERR:       ^~~
  // CHECK:STDERR:
  if (let OptInt.None = opt) {
  }
}

// --- fail_incomplete_scrutinee.carbon
library "[[@TEST_NAME]]";

class C;

fn F(p: C*) {
  // CHECK:STDERR: fail_incomplete_scrutinee.carbon:[[@LINE+7]]:27: error: matching on value of incomplete type `C` [IncompleteTypeInMatchScrutinee]
  // CHECK:STDERR:   if (let .Some(n: i32) = *p) {
  // CHECK:STDERR:                           ^~
  // CHECK:STDERR: fail_incomplete_scrutinee.carbon:[[@LINE-6]]:1: note: class was forward declared here [ClassForwardDeclaredHere]
  // CHECK:STDERR: class C;
  // CHECK:STDERR: ^~~~~~~~
  // CHECK:STDERR:
  if (let .Some(n: i32) = *p) {
  }
}
