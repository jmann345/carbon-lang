// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/fail_todo_import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/fail_todo_import.carbon

// --- lib.carbon
library "[[@TEST_NAME]]";

fn Twice[template T: type](x: T) -> T {
  return x;
}

class Box(template T: type) {
  var v: T;
  fn Get(self) -> T { return self.v; }
}

fn Plain(x: ()) -> () {
  return x;
}

class Holder {
  alias Item = ();
  var item: ();
}

fn Elem[template T: type](x: T) -> T.Item {
  return x.item;
}

class Pick(template T: type, unused U: T.Item) {}

class FieldBox(template T: type) {
  var item: T.Item;
}

class MethodBox(template T: type) {
  var t: T;
  fn Get(self) -> T.Item { return self.t.item; }
}

interface PickI(template T: type, unused U: T.Item) {}

constraint PickC(template T: type, unused U: T.Item) {}

interface WithMethod(template T: type) {
  fn F() -> T.Item;
}

class Outer(template T: type) {
  class Inner(unused U: type) {
    var x: T.Item;
  }
}

class OuterMethod(template T: type) {
  class Inner(unused U: type) {
    fn F() -> T.Item;
  }
}

fn Constrained[V: WithMethod(Holder)](unused v: V) {}

fn TakesWithMethod(unused x: WithMethod(Holder)) {}

interface Marker {}

impl forall [V: WithMethod(Holder)] V as Marker {}

fn NeedsMarker[T: Marker](unused t: T) {}

class K {
  impl as WithMethod(Holder) {
    fn F() -> () { return (); }
  }
}

fn NamesFieldBox[T: type](unused p: FieldBox(T)*) {}

fn BodyNamesFieldBox[T: type](unused t: T) {
  FieldBox(T);
}

// --- fail_todo_import_function.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() -> () {
  return Twice(());
}

// --- fail_todo_import_class.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_class.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(b: Box(())) -> () {
  return b.Get();
}

// --- import_unused.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> () {
  return Plain(());
}

// --- fail_todo_import_function_declaration.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_declaration.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(h: Holder) -> () {
  return Elem(h);
}

// --- fail_todo_import_class_declaration.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_class_declaration.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(unused p: Pick(Holder, ())) {}

// --- fail_todo_import_class_field_type.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_class_field_type.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(unused b: FieldBox(Holder)) {}

// --- fail_todo_import_class_method_declaration.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_class_method_declaration.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(b: MethodBox(Holder)) -> () {
  return b.Get();
}

// --- fail_todo_import_interface_declaration.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_interface_declaration.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(unused x: PickI(Holder, ())) {}

// --- fail_todo_import_constraint_declaration.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_constraint_declaration.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use[V: PickC(Holder, ())](unused v: V) {}

// --- fail_todo_import_interface_member_declaration.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_interface_member_declaration.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(unused x: WithMethod(Holder)) {}

// --- fail_todo_import_nested_class_field_type.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(unused o: Outer(Holder)*) {}

// --- fail_todo_import_nested_class_method_declaration.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(unused o: OuterMethod(Holder)*) {}

// --- fail_todo_import_function_constrained_by_template_interface.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(k: K) {
  Constrained(k);
}

// --- fail_todo_import_function_parameter_of_template_interface_type.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  TakesWithMethod;
}

// --- fail_todo_import_impl_constrained_by_template_interface.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(k: K) {
  NeedsMarker(k);
}

// --- fail_todo_import_function_declaration_names_class_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  NamesFieldBox;
}

// --- fail_todo_import_function_definition_names_class_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(h: Holder) {
  BodyNamesFieldBox(h);
}
