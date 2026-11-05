// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_todo_template_constraint_members.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_todo_template_constraint_members.carbon

// The member-requirement forms SC-1 defers (fork decision F-010 / SC-1,
// D-SC-2): a function definition (a default), a requirement with its own
// compile-time parameters (F-010l), an associated constant, since fill round
// 10 a requirement with a tuple pattern parameter and, since fill round 15, one
// with an expression pattern parameter.

// --- fail_todo_definition.carbon
library "[[@TEST_NAME]]";

// TODO: W-137. A function definition in a template constraint, a default for
// the requirement (D-SC-2).
template constraint HasDefault {
  // CHECK:STDERR: fail_todo_definition.carbon:[[@LINE+8]]:3: error: semantics TODO: `function definition in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   fn G(self) -> i32 { return 1; }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_definition.carbon:[[@LINE+4]]:8: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn G(self) -> i32 { return 1; }
  // CHECK:STDERR:        ^~~~
  // CHECK:STDERR:
  fn G(self) -> i32 { return 1; }
}

// --- fail_todo_parameterized.carbon
library "[[@TEST_NAME]]";

// TODO: W-136. A requirement with compile-time parameters of its own (D-SC-2,
// F-010l).
template constraint HasH {
  // CHECK:STDERR: fail_todo_parameterized.carbon:[[@LINE+4]]:3: error: semantics TODO: `parameterized requirement in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   fn H[U: type](self, u: U);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn H[U: type](self, u: U);
}

// --- fail_todo_assoc_const.carbon
library "[[@TEST_NAME]]";

// TODO: W-135. An associated-constant requirement (D-SC-2).
template constraint HasX {
  // CHECK:STDERR: fail_todo_assoc_const.carbon:[[@LINE+8]]:3: error: semantics TODO: `associated constant requirement in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   let X: type;
  // CHECK:STDERR:   ^~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_assoc_const.carbon:[[@LINE+4]]:14: error: expected `=`; `let` declaration must have an initializer [ExpectedInitializerAfterLet]
  // CHECK:STDERR:   let X: type;
  // CHECK:STDERR:              ^
  // CHECK:STDERR:
  let X: type;
}

// --- fail_todo_tuple_pattern_param.carbon
library "[[@TEST_NAME]]";

// TODO: W-234. A requirement with a tuple pattern parameter, directly, under
// `var` or under a default value (`G`), is refused and not collected, since the
// signature comparison does not support one: on trunk 0bdce60a5 it fails
// fatally on a `TuplePattern` for an impl of an interface with such a member
// and for a redeclaration (D-SC-2 as amended at fill rounds 10 and 11, round
// 9's review 2 finding MINOR-2 and round 10's review 1 finding MINOR-1). A use
// of a type with such members reports nothing further.
template constraint HasF {
  // CHECK:STDERR: fail_todo_tuple_pattern_param.carbon:[[@LINE+4]]:3: error: semantics TODO: `tuple pattern parameter in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   fn F(self, (a: i32, b: i32));
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn F(self, (a: i32, b: i32));
  // CHECK:STDERR: fail_todo_tuple_pattern_param.carbon:[[@LINE+4]]:3: error: semantics TODO: `tuple pattern parameter in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   fn G(self, (a: i32, b: i32) = (1, 2));
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn G(self, (a: i32, b: i32) = (1, 2));
}

class D {
  fn F(unused self, (unused a: i32, unused b: i32)) {}
  fn G(unused self, (unused a: i32, unused b: i32) = (1, 2)) {}
}

fn Call[template T: HasF](unused x: T) -> i32 { return 0; }

fn Test(d: D) -> i32 { return Call(d); }

// --- fail_todo_expr_pattern_param.carbon
library "[[@TEST_NAME]]";

// TODO: W-238. A requirement with an expression pattern parameter, directly or
// under `var` (`G`), is refused and not collected, as one with a tuple pattern
// parameter is (D-SC-2 as amended at fill round 15, round 14's review 1 finding
// MAJOR-1 and review 2 finding MINOR-1): such a parameter is itself a TODO, and
// the signature comparison fails fatally on two `ExprPattern`s, as trunk
// 0bdce60a5's does for a redeclaration and for an impl of an interface with
// such a member. `H`'s `y` is an expression pattern with an error, which fill
// round 14 compared by its kind alone (`ExprParam`, then in
// fail_template_constraint_unsatisfied.carbon). A use of a type with matching
// members reports nothing further.
template constraint HasF {
  // CHECK:STDERR: fail_todo_expr_pattern_param.carbon:[[@LINE+4]]:22: error: semantics TODO: `expression pattern` [SemanticsTodo]
  // CHECK:STDERR:   fn F(self, x: i32, 1) -> i32;
  // CHECK:STDERR:                      ^
  // CHECK:STDERR:
  fn F(self, x: i32, 1) -> i32;
  // CHECK:STDERR: fail_todo_expr_pattern_param.carbon:[[@LINE+4]]:26: error: semantics TODO: `expression pattern` [SemanticsTodo]
  // CHECK:STDERR:   fn G(self, x: i32, var 1) -> i32;
  // CHECK:STDERR:                          ^
  // CHECK:STDERR:
  fn G(self, x: i32, var 1) -> i32;
  // CHECK:STDERR: fail_todo_expr_pattern_param.carbon:[[@LINE+20]]:22: error: name `y` not found [NameNotFound]
  // CHECK:STDERR:   fn H(self, x: i32, y) -> i32;
  // CHECK:STDERR:                      ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_expr_pattern_param.carbon:[[@LINE+16]]:22: error: semantics TODO: `expression pattern` [SemanticsTodo]
  // CHECK:STDERR:   fn H(self, x: i32, y) -> i32;
  // CHECK:STDERR:                      ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_expr_pattern_param.carbon:[[@LINE-14]]:3: error: semantics TODO: `expression pattern parameter in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   fn F(self, x: i32, 1) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_expr_pattern_param.carbon:[[@LINE-13]]:3: error: semantics TODO: `expression pattern parameter in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   fn G(self, x: i32, var 1) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_expr_pattern_param.carbon:[[@LINE+4]]:3: error: semantics TODO: `expression pattern parameter in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   fn H(self, x: i32, y) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn H(self, x: i32, y) -> i32;
}

class D {
  // CHECK:STDERR: fail_todo_expr_pattern_param.carbon:[[@LINE+4]]:36: error: semantics TODO: `expression pattern` [SemanticsTodo]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, 1) -> i32 { return 1; }
  // CHECK:STDERR:                                    ^
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, 1) -> i32 { return 1; }
  // CHECK:STDERR: fail_todo_expr_pattern_param.carbon:[[@LINE+4]]:40: error: semantics TODO: `expression pattern` [SemanticsTodo]
  // CHECK:STDERR:   fn G(unused self, unused x: i32, var 1) -> i32 { return 1; }
  // CHECK:STDERR:                                        ^
  // CHECK:STDERR:
  fn G(unused self, unused x: i32, var 1) -> i32 { return 1; }
  fn H(unused self, unused x: i32, unused y: i32) -> i32 { return 1; }
}

fn Call[template T: HasF](unused x: T) -> i32 { return 0; }

fn Test(d: D) -> i32 { return Call(d); }
