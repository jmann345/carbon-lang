// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_va2.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_va2.carbon

// --- fail_todo_two_implicit_packs.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_two_implicit_packs.carbon:[[@LINE+4]]:24: error: semantics TODO: `more than one pack expansion pattern in an implicit parameter list` [SemanticsTodo]
// CHECK:STDERR: fn F[... each T: type, ... each U: type](... each x: each T);
// CHECK:STDERR:                        ^~~
// CHECK:STDERR:
fn F[... each T: type, ... each U: type](... each x: each T);

// --- fail_todo_computed_element_type.carbon
library "[[@TEST_NAME]]";

class Box(T: type) {}

// CHECK:STDERR: fail_todo_computed_element_type.carbon:[[@LINE+4]]:36: error: semantics TODO: `pack expansion pattern whose binding type is computed from an each-name` [SemanticsTodo]
// CHECK:STDERR: fn F[... each T: type](... each b: Box(each T));
// CHECK:STDERR:                                    ^~~~~~~~~~~
// CHECK:STDERR:
fn F[... each T: type](... each b: Box(each T));

// --- fail_todo_template_each.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_template_each.carbon:[[@LINE+4]]:24: error: semantics TODO: `each-name binding that is ref, var or template` [SemanticsTodo]
// CHECK:STDERR: fn F[... template each T: type](... each x: each T);
// CHECK:STDERR:                        ^
// CHECK:STDERR:
fn F[... template each T: type](... each x: each T);

// --- fail_todo_class_pack.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_class_pack.carbon:[[@LINE+4]]:20: error: semantics TODO: `each-name binding of a class, interface or explicit compile-time parameter` [SemanticsTodo]
// CHECK:STDERR: class Tup(... each T: type) {}
// CHECK:STDERR:                    ^
// CHECK:STDERR:
class Tup(... each T: type) {}

// --- fail_todo_interface_pack.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_interface_pack.carbon:[[@LINE+4]]:22: error: semantics TODO: `each-name binding of a class, interface or explicit compile-time parameter` [SemanticsTodo]
// CHECK:STDERR: interface I(... each T: type) {}
// CHECK:STDERR:                      ^
// CHECK:STDERR:
interface I(... each T: type) {}

// --- fail_todo_explicit_generic_pack.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_explicit_generic_pack.carbon:[[@LINE+4]]:27: error: semantics TODO: `each-name binding of a class, interface or explicit compile-time parameter` [SemanticsTodo]
// CHECK:STDERR: fn Count(... generic each T: type) -> i64;
// CHECK:STDERR:                           ^
// CHECK:STDERR:
fn Count(... generic each T: type) -> i64;

// --- fail_todo_each_auto.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_each_auto.carbon:[[@LINE+4]]:18: error: semantics TODO: `HandleAutoTypeLiteral` [SemanticsTodo]
// CHECK:STDERR: fn F(... each x: auto);
// CHECK:STDERR:                  ^~~~
// CHECK:STDERR:
fn F(... each x: auto);

// --- fail_todo_two_arities.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_two_arities.carbon:[[@LINE+4]]:33: error: semantics TODO: `more than one pack arity in a generic` [SemanticsTodo]
// CHECK:STDERR: fn F[... each T: type](... each n: i64);
// CHECK:STDERR:                                 ^
// CHECK:STDERR:
fn F[... each T: type](... each n: i64);

// --- fail_todo_forward_hetero_to_homo.carbon
library "[[@TEST_NAME]]";

fn H(... each y: i64);

fn F[... each T: Core.ImplicitAs(i64)](... each x: each T) {
  // CHECK:STDERR: fail_todo_forward_hetero_to_homo.carbon:[[@LINE+4]]:3: error: semantics TODO: `forwarding a pack of different types to a pack of one type, or the reverse` [SemanticsTodo]
  // CHECK:STDERR:   H(... each x);
  // CHECK:STDERR:   ^~~~~~~~~~~~~
  // CHECK:STDERR:
  H(... each x);
}

// --- fail_todo_type_pack_call_args.carbon
library "[[@TEST_NAME]]";

fn G(... each t: type);

fn F[... each T: type](... unused each x: each T) {
  // CHECK:STDERR: fail_todo_type_pack_call_args.carbon:[[@LINE+4]]:5: error: semantics TODO: `pack expansion of a compile-time pack in a call's argument list` [SemanticsTodo]
  // CHECK:STDERR:   G(... each T);
  // CHECK:STDERR:     ^~~
  // CHECK:STDERR:
  G(... each T);
}

// --- fail_todo_expansion_without_each_name.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_expansion_without_each_name.carbon:[[@LINE+4]]:9: error: semantics TODO: `pack expansion without an each-name in a binding's type` [SemanticsTodo]
// CHECK:STDERR: fn F(t: (... i64));
// CHECK:STDERR:         ^
// CHECK:STDERR:
fn F(t: (... i64));

// --- fail_todo_overload_hetero_member.carbon
library "[[@TEST_NAME]]";

overload fn G(unused b: bool) {}
// CHECK:STDERR: fail_todo_overload_hetero_member.carbon:[[@LINE+4]]:33: error: semantics TODO: `variadic member of an overload set` [SemanticsTodo]
// CHECK:STDERR: overload fn G[... each T: type](... unused each x: each T) {}
// CHECK:STDERR:                                 ^~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn G[... each T: type](... unused each x: each T) {}

fn Call() {
  // CHECK:STDERR: fail_todo_overload_hetero_member.carbon:[[@LINE+4]]:3: error: semantics TODO: `variadic member of an overload set` [SemanticsTodo]
  // CHECK:STDERR:   G(1 as i64, true);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  G(1 as i64, true);
}

// --- traits.h

template<typename T> struct Traits {
  static constexpr int size = sizeof(T);
};

// --- fail_todo_cpp_template_on_hetero_element.carbon
library "[[@TEST_NAME]]";

import Cpp library "traits.h";

fn Consume(x: i32);

fn F[... each T: type](... unused each x: each T) {
  // CHECK:STDERR: fail_todo_cpp_template_on_hetero_element.carbon:[[@LINE+4]]:15: error: semantics TODO: `C++ or template-dependent action on an element of a pack of different types` [SemanticsTodo]
  // CHECK:STDERR:   ... Consume(Cpp.Traits(each T).size);
  // CHECK:STDERR:               ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ... Consume(Cpp.Traits(each T).size);
}

// --- fail_todo_cpp_template_on_tuple_of_pack.carbon
library "[[@TEST_NAME]]";

import Cpp library "traits.h";

fn F[... each T: type](... unused each x: each T) -> i32 {
  return Cpp.Traits((... each T)).size;
}

fn Call() {
  // CHECK:STDERR: fail_todo_cpp_template_on_tuple_of_pack.carbon:[[@LINE+5]]:3: error: unable to monomorphize specific `F(⟬i32, i64, bool⟭)` [ResolvingSpecificHere]
  // CHECK:STDERR:   F(1 as i32, 2 as i64, true);
  // CHECK:STDERR:   ^
  // CHECK:STDERR: fail_todo_cpp_template_on_tuple_of_pack.carbon: note: semantics TODO: `unsupported type used as template argument` [SemanticsTodo]
  // CHECK:STDERR:
  F(1 as i32, 2 as i64, true);
}

// --- fail_todo_template_action_on_hetero_element.carbon
library "[[@TEST_NAME]]";

fn F[template U: type, ... each T: type](u: U, ... each x: each T) {
  // CHECK:STDERR: fail_todo_template_action_on_hetero_element.carbon:[[@LINE+4]]:7: error: semantics TODO: `C++ or template-dependent action on an element of a pack of different types` [SemanticsTodo]
  // CHECK:STDERR:   ... u.Get(each x);
  // CHECK:STDERR:       ^~~~~~~~~~~~~
  // CHECK:STDERR:
  ... u.Get(each x);
}

// --- fail_todo_initializing_element.carbon
library "[[@TEST_NAME]]";

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  // CHECK:STDERR: fail_todo_initializing_element.carbon:[[@LINE+4]]:11: error: semantics TODO: `pack expansion of initializing expressions in a tuple literal` [SemanticsTodo]
  // CHECK:STDERR:   return (... each x.(Core.Copy.Op)());
  // CHECK:STDERR:           ^~~
  // CHECK:STDERR:
  return (... each x.(Core.Copy.Op)());
}

// --- fail_todo_var_pattern.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](t: (... each T)) {
  // CHECK:STDERR: fail_todo_var_pattern.carbon:[[@LINE+4]]:8: error: semantics TODO: `pack expansion pattern in a pattern other than a parameter list or let` [SemanticsTodo]
  // CHECK:STDERR:   var (... each x: each T) = t;
  // CHECK:STDERR:        ^~~
  // CHECK:STDERR:
  var (... each x: each T) = t;
}

// --- fail_todo_enclosing_arity.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 0; }
  // CHECK:STDERR: fail_todo_enclosing_arity.carbon:[[@LINE+4]]:28: error: semantics TODO: `more than one pack arity in a generic` [SemanticsTodo]
  // CHECK:STDERR:   fn Extra(... unused each n: i64) -> i64 { return 0; }
  // CHECK:STDERR:                            ^
  // CHECK:STDERR:
  fn Extra(... unused each n: i64) -> i64 { return 0; }
}

// --- fail_todo_template_action_on_tuple_of_pack.carbon
library "[[@TEST_NAME]]";

fn F[template U: type, ... each T: type](u: U, ... each x: each T) {
  // CHECK:STDERR: fail_todo_template_action_on_tuple_of_pack.carbon:[[@LINE+4]]:3: error: semantics TODO: `C++ or template-dependent action on a tuple literal with a pack segment` [SemanticsTodo]
  // CHECK:STDERR:   u.Get((... each x));
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  u.Get((... each x));
}

// --- fail_todo_if_with_declaration.carbon
library "[[@TEST_NAME]]";

fn F(... each b: bool) {
  // CHECK:STDERR: fail_todo_if_with_declaration.carbon:[[@LINE+4]]:3: error: semantics TODO: `pack expansion of a statement other than an expression or if statement` [SemanticsTodo]
  // CHECK:STDERR:   ... if (each b) {
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ... if (each b) {
    let unused y: i64 = 0;
  }
}

// --- fail_todo_while.carbon
library "[[@TEST_NAME]]";

fn F(... each b: bool) {
  // CHECK:STDERR: fail_todo_while.carbon:[[@LINE+4]]:3: error: semantics TODO: `pack expansion of a statement other than an expression or if statement` [SemanticsTodo]
  // CHECK:STDERR:   ... while (each b) {}
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ... while (each b) {}
}
