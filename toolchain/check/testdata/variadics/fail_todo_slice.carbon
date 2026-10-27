// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_slice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_slice.carbon

// --- fail_todo_tuple_pattern.carbon
library "[[@TEST_NAME]]";

fn F() {
  // CHECK:STDERR: fail_todo_tuple_pattern.carbon:[[@LINE+4]]:8: error: semantics TODO: `pack expansion pattern with deduced arity outside a parameter list` [SemanticsTodo]
  // CHECK:STDERR:   let (... each x: i64) = ();
  // CHECK:STDERR:        ^~~
  // CHECK:STDERR:
  let (... each x: i64) = ();
}

// --- fail_todo_statement_kind.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64) {
  // CHECK:STDERR: fail_todo_statement_kind.carbon:[[@LINE+4]]:3: error: semantics TODO: `pack expansion of a statement other than an expression or if statement` [SemanticsTodo]
  // CHECK:STDERR:   ... var x: i64 = each n;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ... var x: i64 = each n;
}

// --- fail_todo_control_flow.carbon
library "[[@TEST_NAME]]";

fn Consume(x: bool);

fn F(... each b: bool) {
  // CHECK:STDERR: fail_todo_control_flow.carbon:[[@LINE+4]]:3: error: semantics TODO: `control flow in a pack expansion` [SemanticsTodo]
  // CHECK:STDERR:   ... Consume(each b and true);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ... Consume(each b and true);
}

// --- fail_todo_tuple_literal.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64) {
  // CHECK:STDERR: fail_todo_tuple_literal.carbon:[[@LINE+4]]:30: error: semantics TODO: `tuple pack segment matched with other segments` [SemanticsTodo]
  // CHECK:STDERR:   let unused t: (i64, i64) = (... each n);
  // CHECK:STDERR:                              ^~~~~~~~~~~~
  // CHECK:STDERR:
  let unused t: (i64, i64) = (... each n);
}

// --- fail_todo_merged_segments.carbon
library "[[@TEST_NAME]]";

fn ForEach(... each n: i64);

fn F(... each n: i64) {
  // CHECK:STDERR: fail_todo_merged_segments.carbon:[[@LINE+4]]:3: error: semantics TODO: `pack expansion argument merged with other arguments for the same pack` [SemanticsTodo]
  // CHECK:STDERR:   ForEach(0, ... each n);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ForEach(0, ... each n);
}

// --- fail_todo_ref_pack.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_ref_pack.carbon:[[@LINE+4]]:19: error: semantics TODO: `each-name binding that is ref, var or template` [SemanticsTodo]
// CHECK:STDERR: fn F(... ref each n: i64);
// CHECK:STDERR:                   ^
// CHECK:STDERR:
fn F(... ref each n: i64);

// --- fail_todo_two_each_names.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_two_each_names.carbon:[[@LINE+4]]:29: error: semantics TODO: `pack expansion pattern declaring more than one each-name` [SemanticsTodo]
// CHECK:STDERR: fn F(... (each a: i64, each b: i64));
// CHECK:STDERR:                             ^
// CHECK:STDERR:
fn F(... (each a: i64, each b: i64));

// --- fail_todo_tuple_operand.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_tuple_operand.carbon:[[@LINE+4]]:6: error: semantics TODO: `pack expansion pattern whose operand is not an each-name binding` [SemanticsTodo]
// CHECK:STDERR: fn F(... (each a: i64,));
// CHECK:STDERR:      ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F(... (each a: i64,));

// --- fail_todo_overload_member.carbon
library "[[@TEST_NAME]]";

overload fn G(unused b: bool) {}
// CHECK:STDERR: fail_todo_overload_member.carbon:[[@LINE+4]]:15: error: semantics TODO: `variadic member of an overload set` [SemanticsTodo]
// CHECK:STDERR: overload fn G(... unused each n: i64) {}
// CHECK:STDERR:               ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn G(... unused each n: i64) {}

fn F() {
  // CHECK:STDERR: fail_todo_overload_member.carbon:[[@LINE+4]]:3: error: semantics TODO: `variadic member of an overload set` [SemanticsTodo]
  // CHECK:STDERR:   G(1, 2);
  // CHECK:STDERR:   ^~~~~~~
  // CHECK:STDERR:
  G(1, 2);
}

// --- fail_todo_overload_pack_arg.carbon
library "[[@TEST_NAME]]";

overload fn G(unused x: i64) {}
overload fn G(unused b: bool) {}

fn F(... each n: i64) {
  // CHECK:STDERR: fail_todo_overload_pack_arg.carbon:[[@LINE+4]]:3: error: semantics TODO: `pack expansion argument in a call to an overload set` [SemanticsTodo]
  // CHECK:STDERR:   G(... each n);
  // CHECK:STDERR:   ^~~~~~~~~~~~~
  // CHECK:STDERR:
  G(... each n);
}

// --- fail_todo_template_dependent_call.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](t: T, ... each n: i64) {
  // CHECK:STDERR: fail_todo_template_dependent_call.carbon:[[@LINE+4]]:7: error: semantics TODO: `pack expansion argument in a template-dependent call` [SemanticsTodo]
  // CHECK:STDERR:   t.G(... each n);
  // CHECK:STDERR:       ^~~~~~~~~~
  // CHECK:STDERR:
  t.G(... each n);
}

// --- fail_todo_pack_name_without_each.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  // CHECK:STDERR: fail_todo_pack_name_without_each.carbon:[[@LINE+4]]:11: error: semantics TODO: `use of a pack's name without `each`` [SemanticsTodo]
  // CHECK:STDERR:   Consume(n);
  // CHECK:STDERR:           ^
  // CHECK:STDERR:
  Consume(n);
}

// --- fail_todo_default_after_pack.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_default_after_pack.carbon:[[@LINE+4]]:23: error: semantics TODO: `default value in a parameter list with a pack expansion pattern` [SemanticsTodo]
// CHECK:STDERR: fn F(... each n: i64, last: i64 = 7);
// CHECK:STDERR:                       ^~~~~~~~~~~~~
// CHECK:STDERR:
fn F(... each n: i64, last: i64 = 7);

// --- fail_todo_default_before_pack.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_default_before_pack.carbon:[[@LINE+4]]:22: error: semantics TODO: `default value in a parameter list with a pack expansion pattern` [SemanticsTodo]
// CHECK:STDERR: fn F(first: i64 = 7, ... each n: i64);
// CHECK:STDERR:                      ^~~
// CHECK:STDERR:
fn F(first: i64 = 7, ... each n: i64);

// --- fail_todo_default_on_pack.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_default_on_pack.carbon:[[@LINE+4]]:6: error: semantics TODO: `default value in a parameter list with a pack expansion pattern` [SemanticsTodo]
// CHECK:STDERR: fn F(... each n: i64 = 1);
// CHECK:STDERR:      ^~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F(... each n: i64 = 1);

// --- fail_todo_interface_function.carbon
library "[[@TEST_NAME]]";

interface I {
  // CHECK:STDERR: fail_todo_interface_function.carbon:[[@LINE+4]]:8: error: semantics TODO: `pack expansion pattern in an interface function` [SemanticsTodo]
  // CHECK:STDERR:   fn F(... each n: i64);
  // CHECK:STDERR:        ^~~
  // CHECK:STDERR:
  fn F(... each n: i64);
}

// --- fail_todo_conversion_cleanup.carbon
library "[[@TEST_NAME]]";

class C {
  impl as Core.Destroy {
    fn Op(ref self);
  }
}

class D {}

impl D as Core.ImplicitAs(C) {
  fn Convert(self) -> C;
}

fn ForEach(... unused each c: C) {}

fn F(... each d: D) {
  // CHECK:STDERR: fail_todo_conversion_cleanup.carbon:[[@LINE+7]]:11: error: semantics TODO: `pack element conversion that needs a cleanup` [SemanticsTodo]
  // CHECK:STDERR:   ForEach(... each d);
  // CHECK:STDERR:           ^~~~~~~~~~
  // CHECK:STDERR: fail_todo_conversion_cleanup.carbon:[[@LINE-6]]:12: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: fn ForEach(... unused each c: C) {}
  // CHECK:STDERR:            ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ForEach(... each d);
}
