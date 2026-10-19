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

interface HasItem {
  let Item: type;
}

impl Holder as HasItem where .Item = () {}

fn TakesItem[template T: HasItem](unused x: T, unused p: T.Item*) {}

fn CallsTakesItem[T: HasItem](t: T, p: T.Item*) {
  TakesItem(t, p);
}

fn NamesItem[template T: HasItem](unused x: T) {
  T.Item;
}

fn CallsNamesItem[T: HasItem](t: T) {
  NamesItem(t);
}

interface ItemDoer(P: type) {
  fn Do(self, p: P);
}

impl forall [T: HasItem] T as ItemDoer(T.Item*) {
  fn Do(self, p: T.Item*) {
    TakesItem(self, p);
  }
}

class FieldBoxField(T: type) {
  var t: T;
  var p: FieldBox(Holder)*;
}

class Pair(unused A: type, unused B: type) {}

fn TakesPair[T: type](unused p: Pair(T, FieldBox(Holder))*) {}

fn TakesTuple[T: type](unused p: (T, FieldBox(Holder)*)*) {}

interface WithArg(unused U: type) {}

fn ConstrainedByWithArg[T: WithArg(FieldBox(Holder))](unused t: T) {}

class MarkerArg(unused A: type, unused B: Marker) {}

fn TakesMarkerArg[T: type](unused p: MarkerArg(T, K)*) {}

fn TakesStruct[T: type](unused p: {.a: T, .b: FieldBox(Holder)*}*) {}

fn ConstrainedByRewrite[T: HasItem where .Item = FieldBox(Holder)*](unused t: T) {}

interface RequiresFieldBox(U: type) {
  require impls WithArg((U, FieldBox(Holder)*));
}

constraint RequiresFieldBoxC(U: type) {
  require impls WithArg((U, FieldBox(Holder)*));
}

fn ConstrainedByRequires[T: RequiresFieldBox(())](unused t: T) {}

fn ConstrainedByRequiresC[T: RequiresFieldBoxC(())](unused t: T) {}

interface RequiresFieldBoxConcretely {
  require impls WithArg(FieldBox(Holder)*);
}

fn ConstrainedByConcreteRequire[T: RequiresFieldBoxConcretely](unused t: T) {}

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

// CHECK:STDERR: fail_todo_import_nested_class_field_type.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(unused o: Outer(Holder)*) {}

// --- fail_todo_import_nested_class_method_declaration.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_nested_class_method_declaration.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(unused o: OuterMethod(Holder)*) {}

// --- fail_todo_import_function_constrained_by_template_interface.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_constrained_by_template_interface.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(k: K) {
  Constrained(k);
}

// --- fail_todo_import_function_parameter_of_template_interface_type.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_parameter_of_template_interface_type.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  TakesWithMethod;
}

// --- fail_todo_import_impl_constrained_by_template_interface.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_impl_constrained_by_template_interface.carbon:[[@LINE+8]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_todo_import_impl_constrained_by_template_interface.carbon:[[@LINE+5]]:1: in import [InImport]
// CHECK:STDERR: lib.carbon:64:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn NeedsMarker[T: Marker](unused t: T) {}
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(k: K) {
  // CHECK:STDERR: fail_todo_import_impl_constrained_by_template_interface.carbon:[[@LINE+8]]:3: error: cannot convert type `K` into type implementing `Marker` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   NeedsMarker(k);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_todo_import_impl_constrained_by_template_interface.carbon:[[@LINE-6]]:1: in import [InImport]
  // CHECK:STDERR: lib.carbon:64:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn NeedsMarker[T: Marker](unused t: T) {}
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  NeedsMarker(k);
}

// --- fail_todo_import_function_declaration_names_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_declaration_names_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  NamesFieldBox;
}

// --- fail_todo_import_function_definition_names_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_definition_names_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(h: Holder) {
  BodyNamesFieldBox(h);
}

// --- fail_todo_import_function_definition_calls_function_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_definition_calls_function_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(h: Holder, p: ()*) {
  CallsTakesItem(h, p);
}

// --- fail_todo_import_function_definition_calls_function_template_definition.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_definition_calls_function_template_definition.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(h: Holder) {
  CallsNamesItem(h);
}

// --- fail_todo_import_impl_method_calls_function_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_impl_method_calls_function_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(h: Holder, p: ()*) {
  h.(ItemDoer(()*).Do)(p);
}

// --- fail_todo_import_class_field_names_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_class_field_names_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(unused f: FieldBoxField(())*) {}

// --- fail_todo_import_function_declaration_names_class_template_in_class_argument.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_declaration_names_class_template_in_class_argument.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  TakesPair;
}

// --- fail_todo_import_function_declaration_names_class_template_in_tuple.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_declaration_names_class_template_in_tuple.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  TakesTuple;
}

// --- fail_todo_import_function_constrained_by_interface_of_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_constrained_by_interface_of_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  ConstrainedByWithArg;
}

// --- fail_todo_import_function_declaration_names_impl_of_template_interface.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_declaration_names_impl_of_template_interface.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  TakesMarkerArg;
}

// --- fail_todo_import_function_declaration_names_class_template_in_struct.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_declaration_names_class_template_in_struct.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  TakesStruct;
}

// --- fail_todo_import_function_constrained_by_rewrite_to_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_constrained_by_rewrite_to_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  ConstrainedByRewrite;
}

// --- fail_todo_import_two_uses_name_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_two_uses_name_class_template.carbon:[[@LINE+8]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_todo_import_two_uses_name_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(p: ((), FieldBox(Holder)*)*) {
  TakesTuple(p);
}

// --- fail_todo_import_interface_requires_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_interface_requires_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  RequiresFieldBox;
}

// --- fail_todo_import_constraint_requires_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_constraint_requires_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  RequiresFieldBoxC;
}

// --- fail_todo_import_function_constrained_by_interface_requiring_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_constrained_by_interface_requiring_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  ConstrainedByRequires;
}

// --- fail_todo_import_function_constrained_by_constraint_requiring_class_template.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function_constrained_by_constraint_requiring_class_template.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() {
  ConstrainedByRequiresC;
}

// --- fail_todo_import_two_uses_name_interface_requiring_class_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use[T: RequiresFieldBoxConcretely](t: T) {
  ConstrainedByConcreteRequire(t);
}
