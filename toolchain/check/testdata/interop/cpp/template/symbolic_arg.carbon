// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/template/symbolic_arg.carbon

// C++ templates used with symbolic Carbon arguments in checked generics and
// templates: each specialization and each C++ call is formed for each
// specific. The full prelude is used so that an uninitialized `var` of a
// specialization resolves the real `Core.DefaultOrUnformed` impls.

// --- box.h

template<typename T> struct Box {
  T value;
  T Get() const { return value; }
};
template<typename T> struct Pair { T first; T second; };
template<typename T> Box<T> MakeBox(T v) { Box<T> b; b.value = v; return b; }
template<typename T> T Twice(T x) { return x + x; }
template<typename T> int SizeOfFn() { return sizeof(T); }
template<typename T> int Plain = sizeof(T) + 1;
template<template<typename> class F, typename T> struct Apply { F<T> f; };
inline int TakeInt(int x) { return x + 100; }
template<typename T> struct Static { static int Count() { return sizeof(T); } };

// --- uninitialized_var.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

//@dump-sem-ir-begin
fn F[T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value;
}
//@dump-sem-ir-end

fn G() -> i32 { return F(7 as i32); }

// --- nested_and_generic_class_args.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class List(T: type) {
  var head: T;
}

fn Nested[T: type](v: T) -> T {
  var p: Cpp.Pair(Cpp.Box(T));
  p.first.value = v;
  return p.first.value;
}

fn OfGenericClass[T: type](v: T) -> T {
  var b: Cpp.Box(List(T));
  b.value = {.head = v};
  return b.value.head;
}

fn TemplateTemplate[T: type](unused v: T) {
  var unused a: Cpp.Apply(Cpp.Box, T);
}

fn G() -> i32 {
  TemplateTemplate(1 as i32);
  return Nested(14 as i32) + OfGenericClass(15 as i32);
}

// --- function_template_call.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

//@dump-sem-ir-begin
fn F[T: type](v: T) -> T {
  return Cpp.Twice(v);
}
//@dump-sem-ir-end

fn G() -> i32 { return F(21 as i32); }

// --- explicit_type_argument.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn Explicit[T: type](v: T) -> T {
  return Cpp.Twice(T, v);
}

fn SizeOfType[T: type](unused v: T) -> i32 {
  return Cpp.SizeOfFn(T) + Cpp.Plain(T);
}

fn G() -> i32 { return Explicit(21 as i32) + SizeOfType(1 as i64); }

// --- template_called_from_checked_generic.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn Store[template T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value;
}

fn Double[template T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn Caller[U: type](u: U) -> U {
  return Store(u);
}

fn DoubleCaller[U: type](u: U) -> U {
  return Double(u);
}

fn G() -> i32 { return Caller(31 as i32) + DoubleCaller(15 as i32); }

// --- generic_class_field.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class Holder(T: type) {
  var b: Cpp.Box(T);
}

fn Get[T: type](h: Holder(T)) -> T {
  return h.b.value;
}

fn Make[T: type](v: T) -> T {
  var h: Holder(T) = {.b = Cpp.MakeBox(v)};
  return h.b.value;
}

fn G() -> i32 {
  var h: Holder(i32) = {.b = Cpp.MakeBox(60 as i32)};
  return Get(h) + Make(54 as i32);
}

// --- alias_of_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// A class-scope alias of a specialization of the class's parameter, used in a
// member's signature, as a field's type and as a `var`'s type, in a checked
// generic class and in a class template; and an alias in a function's body.
class Checked(T: type) {
  alias B = Cpp.Box(T);
  var b: B;
  fn Get(b: B) -> T { return b.value; }
  fn Make(v: T) -> B {
    var b: B;
    b.value = v;
    return b;
  }
}

class Template(template T: type) {
  alias B = Cpp.Box(T);
  fn Make(v: T) -> T {
    var b: B;
    b.value = v;
    return b.value;
  }
}

fn InFunction[T: type](v: T) -> T {
  alias B = Cpp.Box(T);
  var b: B;
  b.value = v;
  return b.value;
}

fn G() -> i32 {
  var c: Checked(i32) = {.b = Cpp.MakeBox(1 as i32)};
  return c.b.value + Checked(i32).Get(Checked(i32).Make(2)) +
         Template(i32).Make(3) + InFunction(4 as i32);
}

// --- alias_of_constant_through_specific.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
template<typename T> struct Traits { static constexpr int size = sizeof(T); };
''';

// An alias of a template-dependent C++ constant, named through a concrete
// specific from a function that is not generic, in a checked generic class and
// in a class template: the use's category is the category of the alias's value
// in that specific, a constant.
class Checked(T: type) {
  alias Size = Cpp.Traits(T).size;
}

class Template(template T: type) {
  alias Size = Cpp.Traits(T).size;
}

fn Take(n: i32) -> i32 { return n; }

//@dump-sem-ir-begin
fn G() -> i32 {
  let a: i32 = Checked(f64).Size;
  return Take(Template(i16).Size) + a;
}
//@dump-sem-ir-end

// --- member_missing_uncalled.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// Never instantiated, so never diagnosed, as a template's body is not.
fn F[T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.nope;
}

// --- copy_into_specialization_uncalled.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// Storing a `T` in the specialization copies it, which needs `T` to be
// copyable; that is checked on instantiation, as the store is, so a body that
// is never instantiated is not diagnosed.
fn F[T: type](v: T) -> Cpp.Box(T) {
  var b: Cpp.Box(T);
  b.value = v;
  return b;
}

// --- fail_member_missing_on_instantiation.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn F[T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.nope;
}

// CHECK:STDERR: fail_member_missing_on_instantiation.carbon:[[@LINE+7]]:24: error: unable to monomorphize specific `F(i32)` [ResolvingSpecificHere]
// CHECK:STDERR: fn G() -> i32 { return F(1 as i32); }
// CHECK:STDERR:                        ^
// CHECK:STDERR: fail_member_missing_on_instantiation.carbon:[[@LINE-6]]:10: note: member name `nope` not found in `Cpp.Box` [MemberNameNotFoundInInstScope]
// CHECK:STDERR:   return b.nope;
// CHECK:STDERR:          ^~~~~~
// CHECK:STDERR:
fn G() -> i32 { return F(1 as i32); }

// --- fail_copy_into_specialization_on_instantiation.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class NoCopy {
  var x: i32;
}

fn F[T: type](v: T) -> Cpp.Box(T) {
  var b: Cpp.Box(T);
  b.value = v;
  return b;
}

// CHECK:STDERR: fail_copy_into_specialization_on_instantiation.carbon:[[@LINE+10]]:24: error: unable to monomorphize specific `F(NoCopy)` [ResolvingSpecificHere]
// CHECK:STDERR: fn G() -> i32 { return F({.x = 8} as NoCopy).value.x; }
// CHECK:STDERR:                        ^
// CHECK:STDERR: fail_copy_into_specialization_on_instantiation.carbon:[[@LINE-7]]:13: note: cannot copy value of type `NoCopy` [CopyOfUncopyableType]
// CHECK:STDERR:   b.value = v;
// CHECK:STDERR:             ^
// CHECK:STDERR: fail_copy_into_specialization_on_instantiation.carbon:[[@LINE-10]]:13: note: type `NoCopy` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
// CHECK:STDERR:   b.value = v;
// CHECK:STDERR:             ^
// CHECK:STDERR:
fn G() -> i32 { return F({.x = 8} as NoCopy).value.x; }

// --- fail_cpp_error_on_instantiation.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_cpp_error_on_instantiation.carbon:[[@LINE+9]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./box.h:8:46: error: invalid operands to binary expression ('Carbon::Point' and 'Carbon::Point') [CppInteropParseError]
// CHECK:STDERR:     8 | template<typename T> T Twice(T x) { return x + x; }
// CHECK:STDERR:       |                                            ~ ^ ~
// CHECK:STDERR: fail_cpp_error_on_instantiation.carbon:[[@LINE+5]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./box.h:8:24: note: in instantiation of function template specialization 'Twice<Carbon::Point>' requested here [CppInteropParseNote]
// CHECK:STDERR:     8 | template<typename T> T Twice(T x) { return x + x; }
// CHECK:STDERR:       |                        ^
// CHECK:STDERR:
import Cpp library "box.h";

class Point {
  var x: i32;
}

fn F[T: type](v: T) -> T {
  return Cpp.Twice(v);
}

fn G() -> i32 { return F({.x = 1} as Point).x; }

// --- fail_copy_symbolic_value_in_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// The checked generic's own rules still apply where it is defined: `T` has no
// `Core.Copy` or `Core.Destroy`, whatever initializes the `var`.
fn F[T: type](v: T) -> T {
  var r: T = Cpp.Twice(v);
  // CHECK:STDERR: fail_copy_symbolic_value_in_definition.carbon:[[@LINE+11]]:10: error: cannot copy value of type `T` [CopyOfUncopyableType]
  // CHECK:STDERR:   return r;
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_copy_symbolic_value_in_definition.carbon:[[@LINE+8]]:10: note: type `T` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return r;
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_copy_symbolic_value_in_definition.carbon:[[@LINE-8]]:3: error: cannot access member of interface `Core.Destroy` in type `T` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   var r: T = Cpp.Twice(v);
  // CHECK:STDERR:   ^~~~~~~~
  // CHECK:STDERR:
  return r;
}

// --- fail_symbolic_value_cpp_call_in_definition.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// A symbolic value of a concrete type maps to C++ where the generic is
// defined, so the call is resolved there and its error reported there, as on
// a function that is never instantiated.
fn F(generic N: i32) -> i32 {
  // CHECK:STDERR: fail_symbolic_value_cpp_call_in_definition.carbon:[[@LINE+8]]:26: error: no matching function for call to 'TakeInt' [CppInteropParseError]
  // CHECK:STDERR:    18 |   return Cpp.TakeInt(N, N);
  // CHECK:STDERR:       |                          ^
  // CHECK:STDERR: fail_symbolic_value_cpp_call_in_definition.carbon:[[@LINE-9]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./box.h:12:12: note: candidate function not viable: requires single argument 'x', but 2 arguments were provided [CppInteropParseNote]
  // CHECK:STDERR:    12 | inline int TakeInt(int x) { return x + 100; }
  // CHECK:STDERR:       |            ^       ~~~~~
  // CHECK:STDERR:
  return Cpp.TakeInt(N, N);
}

// --- cpp_result_contagion_uncalled.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn G(n: i32) -> i32 { return n; }

// The result of a C++ call deferred to each specific has no type where `F`
// is defined, so the Carbon operations on it are checked on instantiation
// too; this one is never instantiated and not diagnosed.
fn F[T: type](x: T) -> i32 {
  let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));
  return if b then 1 else 0;
}

// --- fail_cpp_result_contagion_on_instantiation.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn G(n: i32) -> i32 { return n; }

fn F[T: type](x: T) -> i32 {
  let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));
  return if b then 1 else 0;
}

// CHECK:STDERR: fail_cpp_result_contagion_on_instantiation.carbon:[[@LINE+10]]:24: error: unable to monomorphize specific `F(i32)` [ResolvingSpecificHere]
// CHECK:STDERR: fn H() -> i32 { return F(1 as i32); }
// CHECK:STDERR:                        ^
// CHECK:STDERR: fail_cpp_result_contagion_on_instantiation.carbon:[[@LINE-7]]:17: note: cannot implicitly convert expression of type `i32` to `bool` [ConversionFailure]
// CHECK:STDERR:   let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));
// CHECK:STDERR:                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_cpp_result_contagion_on_instantiation.carbon:[[@LINE-10]]:17: note: type `i32` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
// CHECK:STDERR:   let b: bool = G(Cpp.TakeInt(Cpp.Twice(x)));
// CHECK:STDERR:                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn H() -> i32 { return F(1 as i32); }

// --- fail_alias_of_template_call_on_instantiation.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// An alias's template-dependent value is checked for each specific, as an
// alias's value is where it is known: a call to a C++ function that is not
// `constexpr` is a runtime value, so the alias is diagnosed on instantiation,
// in a checked generic class and in a class template, used or not.
class Checked(T: type) {
  alias N = Cpp.Static(T).Count();
  fn F() -> i32 { return N; }
}

class Template(template T: type) {
  alias N = Cpp.Static(T).Count();
}

fn G() -> i32 {
  // CHECK:STDERR: fail_alias_of_template_call_on_instantiation.carbon:[[@LINE+7]]:17: error: binding pattern has incomplete type `Template(i32)` in name binding declaration [IncompleteTypeInBindingDecl]
  // CHECK:STDERR:   var unused t: Template(i32) = {};
  // CHECK:STDERR:                 ^~~~~~~~~~~~~
  // CHECK:STDERR: fail_alias_of_template_call_on_instantiation.carbon:[[@LINE-7]]:13: note: alias refers to a runtime value [AliasRequiresConstantValue]
  // CHECK:STDERR:   alias N = Cpp.Static(T).Count();
  // CHECK:STDERR:             ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var unused t: Template(i32) = {};
  // CHECK:STDERR: fail_alias_of_template_call_on_instantiation.carbon:[[@LINE+14]]:10: error: member access into incomplete class `Checked(i32)` [QualifiedExprInIncompleteClassScope]
  // CHECK:STDERR:   return Checked(i32).F();
  // CHECK:STDERR:          ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_alias_of_template_call_on_instantiation.carbon:[[@LINE-20]]:13: note: alias refers to a runtime value [AliasRequiresConstantValue]
  // CHECK:STDERR:   alias N = Cpp.Static(T).Count();
  // CHECK:STDERR:             ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_alias_of_template_call_on_instantiation.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `F()` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Checked(i32).F();
  // CHECK:STDERR:          ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_alias_of_template_call_on_instantiation.carbon:[[@LINE-26]]:26: note: alias refers to a runtime value [AliasRequiresConstantValue]
  // CHECK:STDERR:   fn F() -> i32 { return N; }
  // CHECK:STDERR:                          ^
  // CHECK:STDERR:
  return Checked(i32).F();
}

// --- fail_todo_form_dependent_arg.carbon

library "[[@TEST_NAME]]";

import Core library "prelude/types/form";
import Cpp library "box.h";

fn F(generic Fm: Core.Form, x:? Fm) -> i32 {
  // CHECK:STDERR: fail_todo_form_dependent_arg.carbon:[[@LINE+4]]:22: error: semantics TODO: `Support passing form-dependent args to C++ functions.` [SemanticsTodo]
  // CHECK:STDERR:   return Cpp.TakeInt(x);
  // CHECK:STDERR:                      ^
  // CHECK:STDERR:
  return Cpp.TakeInt(x);
}

// --- fail_todo_struct_arg.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn F[T: type](v: T) -> T {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value;
}

fn G() -> i32 {
  let s: {.a: i32} = {.a = 46};
  // CHECK:STDERR: fail_todo_struct_arg.carbon:[[@LINE+5]]:10: error: unable to monomorphize specific `F({.a: i32})` [ResolvingSpecificHere]
  // CHECK:STDERR:   return F(s).a;
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_todo_struct_arg.carbon: note: semantics TODO: `unsupported type used as template argument` [SemanticsTodo]
  // CHECK:STDERR:
  return F(s).a;
}

// --- fail_todo_template_template_carbon_generic.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class List(T: type) {
  var head: T;
}

fn G() {
  // CHECK:STDERR: fail_todo_template_template_carbon_generic.carbon:[[@LINE+4]]:27: error: template argument for template template parameter must be a class template or type alias template [CppInteropParseError]
  // CHECK:STDERR:    15 |   var unused a: Cpp.Apply(List, i32);
  // CHECK:STDERR:       |                           ^
  // CHECK:STDERR:
  var unused a: Cpp.Apply(List, i32);
}

// --- fail_todo_deduce_through_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn Get[T: type](b: Cpp.Box(T)) -> T {
  return b.value;
}

// CHECK:STDERR: fail_todo_deduce_through_specialization.carbon:[[@LINE+7]]:24: error: cannot deduce value for generic parameter `T` [DeductionIncomplete]
// CHECK:STDERR: fn G() -> i32 { return Get(Cpp.MakeBox(50 as i32)); }
// CHECK:STDERR:                        ^~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_todo_deduce_through_specialization.carbon:[[@LINE-7]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Get[T: type](b: Cpp.Box(T)) -> T {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn G() -> i32 { return Get(Cpp.MakeBox(50 as i32)); }

// --- fail_todo_impl_forall_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

interface Size {
  fn Get(self) -> i32;
}

// `T` cannot be deduced through `Box<T>`, so the impl's parameter is
// not used in a way that identifies it.
// CHECK:STDERR: fail_todo_impl_forall_specialization.carbon:[[@LINE+4]]:13: error: `impl` with unused generic binding [ImplUnusedBinding]
// CHECK:STDERR: impl forall [T: type] Cpp.Box(T) as Size {
// CHECK:STDERR:             ^~~~~~~~~
// CHECK:STDERR:
impl forall [T: type] Cpp.Box(T) as Size {
  fn Get(self) -> i32 { return self.value * 0 + 5; }
}

// --- fail_todo_choice_payload_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

choice Holder(T: type) {
  Full(b: Cpp.Box(T)),
  Empty
}

fn F[T: type](unused v: T) -> i32 {
  let unused h: Holder(T) = Holder(T).Empty;
  return 2;
}

// CHECK:STDERR: fail_todo_choice_payload_specialization.carbon:[[@LINE+17]]:24: error: unable to monomorphize specific `F(i32)` [ResolvingSpecificHere]
// CHECK:STDERR: fn G() -> i32 { return F(1 as i32); }
// CHECK:STDERR:                        ^
// CHECK:STDERR: fail_todo_choice_payload_specialization.carbon:[[@LINE-7]]:17: note: `Holder(T)` evaluates to incomplete type `Holder(i32)` [IncompleteTypeInMonomorphization]
// CHECK:STDERR:   let unused h: Holder(T) = Holder(T).Empty;
// CHECK:STDERR:                 ^~~~~~~~~
// CHECK:STDERR: fail_todo_choice_payload_specialization.carbon:[[@LINE-16]]:1: note: choice alternative payload type `Cpp.Box` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
// CHECK:STDERR: choice Holder(T: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_todo_choice_payload_specialization.carbon:[[@LINE+7]]:24: error: unable to monomorphize specific `F(i32)` [ResolvingSpecificHere]
// CHECK:STDERR: fn G() -> i32 { return F(1 as i32); }
// CHECK:STDERR:                        ^
// CHECK:STDERR: fail_todo_choice_payload_specialization.carbon:[[@LINE-17]]:29: note: choice alternative payload type `Cpp.Box` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
// CHECK:STDERR:   let unused h: Holder(T) = Holder(T).Empty;
// CHECK:STDERR:                             ^~~~~~~~~~~~~~~
// CHECK:STDERR:
fn G() -> i32 { return F(1 as i32); }

// --- fail_todo_member_through_constraint.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

interface Show {
  fn Get(self) -> i32;
}

class S {
  var v: i32;
  impl as Show {
    fn Get(self) -> i32 { return self.v; }
  }
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

fn Direct[T: Show](v: T) -> i32 {
  return v.Get();
}

fn Compound[T: Show](v: T) -> i32 {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value.(Show.Get)();
}

fn Simple[T: Show](v: T) -> i32 {
  var b: Cpp.Box(T);
  b.value = v;
  return b.value.Get();
}

fn G() -> i32 {
  let s: S = {.v = 49};
  // CHECK:STDERR: fail_todo_member_through_constraint.carbon:[[@LINE+7]]:36: error: unable to monomorphize specific `Simple(S as Show)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Direct(s) + Compound(s) + Simple(s);
  // CHECK:STDERR:                                    ^~~~~~
  // CHECK:STDERR: fail_todo_member_through_constraint.carbon:[[@LINE-8]]:10: note: member name `Get` not found in `S` [MemberNameNotFoundInInstScope]
  // CHECK:STDERR:   return b.value.Get();
  // CHECK:STDERR:          ^~~~~~~~~~~
  // CHECK:STDERR:
  return Direct(s) + Compound(s) + Simple(s);
}

// CHECK:STDOUT: --- uninitialized_var.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %v.param_patt.4a6: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %v.patt.0d3: %pattern_type.51d1c4.1 = wrapper_binding_pattern v, %v.param_patt.4a6 [symbolic]
// CHECK:STDOUT:   %.184347.1: Core.Form = init_form %T.67d [symbolic]
// CHECK:STDOUT:   %return.param_patt.41d2d9.1: %pattern_type.51d1c4.1 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.b39: %pattern_type.51d1c4.1 = return_slot_pattern %return.param_patt.41d2d9.1, %T.67d [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %Box.type: type = cpp_type_template_type Box [concrete]
// CHECK:STDOUT:   %Box.template: %Box.type = struct_value () [concrete]
// CHECK:STDOUT:   %.a92: type = template_inst %T.67d [template]
// CHECK:STDOUT:   %.218: type = type_of_inst @F.%.loc8_19.5 [template]
// CHECK:STDOUT:   %.55c: %.218 = splice_inst @F.%.loc8_19.5 [template]
// CHECK:STDOUT:   %.537: type = splice_inst @F.%.loc8_19.8 [template]
// CHECK:STDOUT:   %require_complete.cb0: <witness> = require_complete_type %.537 [template]
// CHECK:STDOUT:   %pattern_type.fcb: type = pattern_type %.537 [template]
// CHECK:STDOUT:   %b.patt.ef6: %pattern_type.fcb = ref_binding_pattern b [template]
// CHECK:STDOUT:   %b.var_patt.20b: %pattern_type.fcb = var_pattern %b.patt.ef6 [template]
// CHECK:STDOUT:   %DefaultOrUnformed.type: type = facet_type <@DefaultOrUnformed> [concrete]
// CHECK:STDOUT:   %Self.935: %DefaultOrUnformed.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %DefaultOrUnformed.WithSelf.Op.type.8f1: type = fn_type @DefaultOrUnformed.WithSelf.Op, @DefaultOrUnformed.WithSelf(%Self.935) [symbolic]
// CHECK:STDOUT:   %DefaultOrUnformed.WithSelf.Op.ad7: %DefaultOrUnformed.WithSelf.Op.type.8f1 = struct_value () [symbolic]
// CHECK:STDOUT:   %DefaultOrUnformed.lookup_impl_witness: <witness> = lookup_impl_witness %.537, @DefaultOrUnformed [template]
// CHECK:STDOUT:   %DefaultOrUnformed.facet.67e: %DefaultOrUnformed.type = facet_value %.537, (%DefaultOrUnformed.lookup_impl_witness) [template]
// CHECK:STDOUT:   %.77d: type = type_of_inst @F.%.loc8_20.6 [template]
// CHECK:STDOUT:   %.984: %.77d = splice_inst @F.%.loc8_20.6 [template]
// CHECK:STDOUT:   %.b48: type = type_of_inst @F.%.loc8_20.9 [template]
// CHECK:STDOUT:   %.e18: %.b48 = splice_inst @F.%.loc8_20.9 [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.5d6: %.537 = splice_inst @F.%tuple.elem0.loc8 [template]
// CHECK:STDOUT:   %.b276ea.1: type = type_of_inst @F.%.loc9_4.4 [template]
// CHECK:STDOUT:   %.06fc86.1: %.b276ea.1 = splice_inst @F.%.loc9_4.4 [template]
// CHECK:STDOUT:   %require_complete.e52: <witness> = require_complete_type %.b276ea.1 [template]
// CHECK:STDOUT:   %.756: %.b276ea.1 = splice_inst @F.%tuple.elem0.loc9 [template]
// CHECK:STDOUT:   %.560: %.b276ea.1 = splice_inst @F.%.loc9_4.7 [template]
// CHECK:STDOUT:   %.b276ea.2: type = type_of_inst @F.%.loc10_11.3 [template]
// CHECK:STDOUT:   %.06fc86.2: %.b276ea.2 = splice_inst @F.%.loc10_11.3 [template]
// CHECK:STDOUT:   %.38e: %T.67d = splice_inst @F.%tuple.elem0.loc10 [template]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Self.0e7: %Destroy.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.4e5: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Self.0e7) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.4a0: %Destroy.WithSelf.SelfDestruct.type.4e5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.assoc_type: type = assoc_entity_type @Destroy [concrete]
// CHECK:STDOUT:   %assoc2: %Destroy.assoc_type = assoc_entity element2, imports.%Core.import_ref.71d [concrete]
// CHECK:STDOUT:   %.8cb: type = type_of_inst @F.%.loc8_3.8 [template]
// CHECK:STDOUT:   %.c23: %.8cb = splice_inst @F.%.loc8_3.8 [template]
// CHECK:STDOUT:   %.57c: type = type_of_inst @F.%.loc8_3.11 [template]
// CHECK:STDOUT:   %.e63: %.57c = splice_inst @F.%.loc8_3.11 [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %v.param_patt.733: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %v.patt.808: %pattern_type.6b6 = wrapper_binding_pattern v, %v.param_patt.733 [concrete]
// CHECK:STDOUT:   %Box: type = class_type @Box [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.3e8: type = splice_block imports.%Box.decl [concrete = %Box] {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.0a5: type = splice_block %Box [concrete = %Box] {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Box.elem: type = unbound_element_type %Box, %i32 [concrete]
// CHECK:STDOUT:   %.ceb: type = custom_layout_type {size=4, align=4, .value@0: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.900: <witness> = complete_type_witness %.ceb [concrete]
// CHECK:STDOUT:   %pattern_type.070: type = pattern_type %Box [concrete]
// CHECK:STDOUT:   %b.patt.257: %pattern_type.070 = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt.12d: %pattern_type.070 = var_pattern %b.patt.257 [concrete]
// CHECK:STDOUT:   %Default.type: type = facet_type <@Default> [concrete]
// CHECK:STDOUT:   %T.b09: %Default.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.type.0c9: type = fn_type @T.as_type.as.DefaultOrUnformed.impl.Op.1, @T.as_type.as.DefaultOrUnformed.impl.9f9(%T.b09) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.cfe: %T.as_type.as.DefaultOrUnformed.impl.Op.type.0c9 = struct_value () [symbolic]
// CHECK:STDOUT:   %Box.Op.type: type = fn_type @Box.Op [concrete]
// CHECK:STDOUT:   %Box.Op: %Box.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.9b4: <witness> = custom_witness (%Box.Op), @Default [concrete]
// CHECK:STDOUT:   %Default.facet.215: %Default.type = facet_value %Box, (%custom_witness.9b4) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness.23f: <witness> = impl_witness imports.%DefaultOrUnformed.impl_witness_table.162, @T.as_type.as.DefaultOrUnformed.impl.9f9(%Default.facet.215) [concrete]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.type.915: type = fn_type @T.as_type.as.DefaultOrUnformed.impl.Op.1, @T.as_type.as.DefaultOrUnformed.impl.9f9(%Default.facet.215) [concrete]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.b24: %T.as_type.as.DefaultOrUnformed.impl.Op.type.915 = struct_value () [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.facet.2f2: %DefaultOrUnformed.type = facet_value %Box, (%DefaultOrUnformed.impl_witness.23f) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.WithSelf.Op.type.0e3: type = fn_type @DefaultOrUnformed.WithSelf.Op, @DefaultOrUnformed.WithSelf(%DefaultOrUnformed.facet.2f2) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.assoc_type: type = assoc_entity_type @DefaultOrUnformed [concrete]
// CHECK:STDOUT:   %assoc0.b81: %DefaultOrUnformed.assoc_type = assoc_entity element0, imports.%Core.import_ref.d14 [concrete]
// CHECK:STDOUT:   %.31b: type = fn_type_with_self_type %DefaultOrUnformed.WithSelf.Op.type.0e3, %DefaultOrUnformed.facet.2f2 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.f08: %.31b = splice_block %impl.elem0.0c1 [concrete = %T.as_type.as.DefaultOrUnformed.impl.Op.b24] {
// CHECK:STDOUT:       %as_type: type = facet_access_type %DefaultOrUnformed.facet.2f2 [concrete = %Box]
// CHECK:STDOUT:       %.6ea: type = converted %DefaultOrUnformed.facet.2f2, %as_type [concrete = %Box]
// CHECK:STDOUT:       %Op.ref: %DefaultOrUnformed.assoc_type = name_ref Op, imports.%Core.import_ref.6dc [concrete = %assoc0.b81]
// CHECK:STDOUT:       %impl.elem0.0c1: %.31b = impl_witness_access %DefaultOrUnformed.impl_witness.23f, element0 [concrete = %T.as_type.as.DefaultOrUnformed.impl.Op.b24]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.4: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.3c0b: init %Box = splice_block %T.as_type.as.DefaultOrUnformed.impl.Op.call {
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %.9ccea1.2: ref %Box = specific_inst @F.%b.var, @F(%i32)
// CHECK:STDOUT:       %T.as_type.as.DefaultOrUnformed.impl.Op.call: init %Box to %.9ccea1.2 = call %T.as_type.as.DefaultOrUnformed.impl.Op.specific_fn.94639c.2()
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.5: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.65b: init %Box = splice_block %.3c0b {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.1: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.5) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.6: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.e3d860.1: ref %i32 = splice_block %.a9f560.2 {
// CHECK:STDOUT:       %.d6e087.2: ref %Box = specific_inst @F.%b.ref.loc9, @F(%i32)
// CHECK:STDOUT:       %value.ref.4ac059.2: %Box.elem = name_ref value, @Box.%field_decl [concrete = @Box.%field_decl]
// CHECK:STDOUT:       %.a9f560.2: ref %i32 = class_element_access %.d6e087.2, element0
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.7: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.0fa: init %i32 = splice_block %Int.as.Copy.impl.Op.call.882 {
// CHECK:STDOUT:       %.aa3: %i32 = specific_inst @F.%v.ref, @F(%i32)
// CHECK:STDOUT:       %impl.elem0.88228e.2: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.c89: <bound method> = bound_method %.aa3, %impl.elem0.88228e.2
// CHECK:STDOUT:       %specific_fn.96a233.2: <specific function> = specific_function %impl.elem0.88228e.2, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.dab: <bound method> = bound_method %.aa3, %specific_fn.96a233.2
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call.882: init %i32 = call %bound_method.dab(%.aa3)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.2: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.7) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.8: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.906: ref %i32 = splice_block %.e3d860.1 {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.9: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.e3d860.2: ref %i32 = splice_block %.a9f560.1 {
// CHECK:STDOUT:       %.d6e087.1: ref %Box = specific_inst @F.%b.ref.loc10, @F(%i32)
// CHECK:STDOUT:       %value.ref.4ac059.1: %Box.elem = name_ref value, @Box.%field_decl [concrete = @Box.%field_decl]
// CHECK:STDOUT:       %.a9f560.1: ref %i32 = class_element_access %.d6e087.1, element0
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.10: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.f0a: init %i32 = splice_block %Int.as.Copy.impl.Op.call.c7f {
// CHECK:STDOUT:       %.222: %i32 = acquire_value %.e3d860.2
// CHECK:STDOUT:       %impl.elem0.88228e.1: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.3a9: <bound method> = bound_method %.222, %impl.elem0.88228e.1
// CHECK:STDOUT:       %specific_fn.96a233.1: <specific function> = specific_function %impl.elem0.88228e.1, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.f69: <bound method> = bound_method %.222, %specific_fn.96a233.1
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call.c7f: init %i32 = call %bound_method.f69(%.222)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.3: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.10) [concrete]
// CHECK:STDOUT:   %self.param_patt.709: %pattern_type.070 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.cfe: %pattern_type.070 = wrapper_binding_pattern self, %self.param_patt.709 [concrete]
// CHECK:STDOUT:   %Box.cpp_destructor.type: type = fn_type @Box.cpp_destructor [concrete]
// CHECK:STDOUT:   %Box.cpp_destructor: %Box.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.842: <witness> = custom_witness (%Destroy.WithSelf.Op.403, %Box.cpp_destructor, %Destroy.WithSelf.SelfDestruct.db3), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.8cf: %Destroy.type = facet_value %Box, (%custom_witness.842) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.f20: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.8cf) [concrete]
// CHECK:STDOUT:   %.03e: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.f20, %Destroy.facet.8cf [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.11: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.1f4: <bound method> = splice_block %bound_method.dc4 {
// CHECK:STDOUT:       %.9ccea1.1: ref %Box = specific_inst @F.%b.var, @F(%i32)
// CHECK:STDOUT:       %impl.elem2: %.03e = impl_witness_access %custom_witness.842, element2 [concrete = %Destroy.WithSelf.SelfDestruct.db3]
// CHECK:STDOUT:       %bound_method.dc4: <bound method> = bound_method %.9ccea1.1, %impl.elem2
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.call: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %.1f4(%.9ccea1.1)
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Box = %Box.template
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Box.template: %Box.type = struct_value () [concrete = constants.%Box.template]
// CHECK:STDOUT:   %Core.import_ref.6dc: %DefaultOrUnformed.assoc_type = import_ref Core//prelude/default, loc{{\d+_\d+}}, loaded [concrete = constants.%assoc0.b81]
// CHECK:STDOUT:   %Core.import_ref.71d: @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct.type (%Destroy.WithSelf.SelfDestruct.type.4e5) = import_ref Core//prelude/destroy, loc{{\d+_\d+}}, loaded [symbolic = @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct (constants.%Destroy.WithSelf.SelfDestruct.4a0)]
// CHECK:STDOUT:   %Box.decl: type = class_decl @Box [concrete = constants.%Box] {} {}
// CHECK:STDOUT:   %Core.import_ref.c2f: @T.as_type.as.DefaultOrUnformed.impl.9f9.%T.as_type.as.DefaultOrUnformed.impl.Op.type (%T.as_type.as.DefaultOrUnformed.impl.Op.type.0c9) = import_ref Core//prelude/default, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.DefaultOrUnformed.impl.9f9.%T.as_type.as.DefaultOrUnformed.impl.Op (constants.%T.as_type.as.DefaultOrUnformed.impl.Op.cfe)]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness_table.162 = impl_witness_table (%Core.import_ref.c2f), @T.as_type.as.DefaultOrUnformed.impl.9f9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.d14: @DefaultOrUnformed.WithSelf.%DefaultOrUnformed.WithSelf.Op.type (%DefaultOrUnformed.WithSelf.Op.type.8f1) = import_ref Core//prelude/default, loc{{\d+_\d+}}, loaded [symbolic = @DefaultOrUnformed.WithSelf.%DefaultOrUnformed.WithSelf.Op (constants.%DefaultOrUnformed.WithSelf.Op.ad7)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Box.cpp_destructor.decl: %Box.cpp_destructor.type = fn_decl @Box.cpp_destructor [concrete = constants.%Box.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc8 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.070 = ref_param_pattern [concrete = constants.%self.param_patt.709]
// CHECK:STDOUT:     %self.patt: %pattern_type.070 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.cfe]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Box = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Box = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %T.patt.loc7_7.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc7_7.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:     %v.param_patt.loc7_16.1: @F.%pattern_type.loc7 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %v.param_patt.loc7_16.2 (constants.%v.param_patt.4a6)]
// CHECK:STDOUT:     %v.patt.loc7_16.1: @F.%pattern_type.loc7 (%pattern_type.51d1c4.1) = wrapper_binding_pattern v, %v.param_patt.loc7_16.1 [symbolic = %v.patt.loc7_16.2 (constants.%v.patt.0d3)]
// CHECK:STDOUT:     %return.param_patt.loc7_24.1: @F.%pattern_type.loc7 (%pattern_type.51d1c4.1) = out_param_pattern [symbolic = %return.param_patt.loc7_24.2 (constants.%return.param_patt.41d2d9.1)]
// CHECK:STDOUT:     %return.patt.loc7_21.1: @F.%pattern_type.loc7 (%pattern_type.51d1c4.1) = return_slot_pattern %return.param_patt.loc7_24.1, %T.ref.loc7_24 [symbolic = %return.patt.loc7_21.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc7_24: type = name_ref T, %T.loc7_7.2 [symbolic = %T.loc7_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %.loc7_24.2: Core.Form = init_form %T.ref.loc7_24 [symbolic = %.loc7_24.1 (constants.%.184347.1)]
// CHECK:STDOUT:     %.loc7_9.1: type = splice_block %.loc7_9.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc7_9.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc7_7.2: type = symbolic_binding T, 0 [symbolic = %T.loc7_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v.param: @F.%T.loc7_7.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc7_18: type = name_ref T, %T.loc7_7.2 [symbolic = %T.loc7_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v: @F.%T.loc7_7.1 (%T.67d) = wrapper_binding v, %v.param
// CHECK:STDOUT:     %return.param: ref @F.%T.loc7_7.1 (%T.67d) = out_param call_param1
// CHECK:STDOUT:     %return: ref @F.%T.loc7_7.1 (%T.67d) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%T.loc7_7.2: type) {
// CHECK:STDOUT:   %T.patt.loc7_7.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc7_7.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:   %T.loc7_7.1: type = symbolic_binding T, 0 [symbolic = %T.loc7_7.1 (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc7: type = pattern_type %T.loc7_7.1 [symbolic = %pattern_type.loc7 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %v.param_patt.loc7_16.2: @F.%pattern_type.loc7 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %v.param_patt.loc7_16.2 (constants.%v.param_patt.4a6)]
// CHECK:STDOUT:   %v.patt.loc7_16.2: @F.%pattern_type.loc7 (%pattern_type.51d1c4.1) = wrapper_binding_pattern v, %v.param_patt.loc7_16.2 [symbolic = %v.patt.loc7_16.2 (constants.%v.patt.0d3)]
// CHECK:STDOUT:   %.loc7_24.1: Core.Form = init_form %T.loc7_7.1 [symbolic = %.loc7_24.1 (constants.%.184347.1)]
// CHECK:STDOUT:   %return.param_patt.loc7_24.2: @F.%pattern_type.loc7 (%pattern_type.51d1c4.1) = out_param_pattern [symbolic = %return.param_patt.loc7_24.2 (constants.%return.param_patt.41d2d9.1)]
// CHECK:STDOUT:   %return.patt.loc7_21.2: @F.%pattern_type.loc7 (%pattern_type.51d1c4.1) = return_slot_pattern %return.param_patt.loc7_24.2, %T.loc7_7.1 [symbolic = %return.patt.loc7_21.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc7: <witness> = require_complete_type %T.loc7_7.1 [symbolic = %require_complete.loc7 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %.loc8_18.2: type = template_inst %T.loc7_7.1 [template = %.loc8_18.2 (constants.%.a92)]
// CHECK:STDOUT:   %.loc8_19.5: <instruction> = call_action (%Box.ref, %.loc8_18.1), false [template]
// CHECK:STDOUT:   %.loc8_19.6: type = type_of_inst %.loc8_19.5 [template = %.loc8_19.6 (constants.%.218)]
// CHECK:STDOUT:   %.loc8_19.7: @F.%.loc8_19.6 (%.218) = splice_inst %.loc8_19.5 [template = %.loc8_19.7 (constants.%.55c)]
// CHECK:STDOUT:   %.loc8_19.8: <instruction> = convert_to_value_action %.loc8_19.3, type [template]
// CHECK:STDOUT:   %.loc8_19.9: type = splice_inst %.loc8_19.8 [template = %.loc8_19.9 (constants.%.537)]
// CHECK:STDOUT:   %require_complete.loc8: <witness> = require_complete_type %.loc8_19.9 [template = %require_complete.loc8 (constants.%require_complete.cb0)]
// CHECK:STDOUT:   %pattern_type.loc8: type = pattern_type %.loc8_19.9 [template = %pattern_type.loc8 (constants.%pattern_type.fcb)]
// CHECK:STDOUT:   %b.patt.loc8_8.2: @F.%pattern_type.loc8 (%pattern_type.fcb) = ref_binding_pattern b [template = %b.patt.loc8_8.2 (constants.%b.patt.ef6)]
// CHECK:STDOUT:   %b.var_patt.loc8_3.2: @F.%pattern_type.loc8 (%pattern_type.fcb) = var_pattern %b.patt.loc8_8.2 [template = %b.var_patt.loc8_3.2 (constants.%b.var_patt.20b)]
// CHECK:STDOUT:   %DefaultOrUnformed.lookup_impl_witness: <witness> = lookup_impl_witness %.loc8_19.9, @DefaultOrUnformed [template = %DefaultOrUnformed.lookup_impl_witness (constants.%DefaultOrUnformed.lookup_impl_witness)]
// CHECK:STDOUT:   %DefaultOrUnformed.facet.loc8_20.2: %DefaultOrUnformed.type = facet_value %.loc8_19.9, (%DefaultOrUnformed.lookup_impl_witness) [template = %DefaultOrUnformed.facet.loc8_20.2 (constants.%DefaultOrUnformed.facet.67e)]
// CHECK:STDOUT:   %.loc8_20.6: <instruction> = access_member_action %.loc8_20.1, Op [template]
// CHECK:STDOUT:   %.loc8_20.7: type = type_of_inst %.loc8_20.6 [template = %.loc8_20.7 (constants.%.77d)]
// CHECK:STDOUT:   %.loc8_20.8: @F.%.loc8_20.7 (%.77d) = splice_inst %.loc8_20.6 [template = %.loc8_20.8 (constants.%.984)]
// CHECK:STDOUT:   %.loc8_20.9: <instruction> = call_action (%.loc8_20.3), false [template]
// CHECK:STDOUT:   %.loc8_20.10: type = type_of_inst %.loc8_20.9 [template = %.loc8_20.10 (constants.%.b48)]
// CHECK:STDOUT:   %.loc8_20.11: @F.%.loc8_20.10 (%.b48) = splice_inst %.loc8_20.9 [template = %.loc8_20.11 (constants.%.e18)]
// CHECK:STDOUT:   %.loc8_3.6: %tuple.type.f7a = initialize_action %.loc8_20.5, %.loc8_19.9, %b.var, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc8: <instruction> = tuple_access %.loc8_3.6, element0 [template]
// CHECK:STDOUT:   %.loc8_3.7: @F.%.loc8_19.9 (%.537) = splice_inst %tuple.elem0.loc8 [template = %.loc8_3.7 (constants.%.5d6)]
// CHECK:STDOUT:   %.loc9_4.4: <instruction> = access_member_action %b.ref.loc9, value [template]
// CHECK:STDOUT:   %.loc9_4.5: type = type_of_inst %.loc9_4.4 [template = %.loc9_4.5 (constants.%.b276ea.1)]
// CHECK:STDOUT:   %.loc9_4.6: @F.%.loc9_4.5 (%.b276ea.1) = splice_inst %.loc9_4.4 [template = %.loc9_4.6 (constants.%.06fc86.1)]
// CHECK:STDOUT:   %require_complete.loc9: <witness> = require_complete_type %.loc9_4.5 [template = %require_complete.loc9 (constants.%require_complete.e52)]
// CHECK:STDOUT:   %.loc9_11.2: %tuple.type.f7a = initialize_action %v.ref, %.loc9_4.5, %.loc9_4.2, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc9: <instruction> = tuple_access %.loc9_11.2, element0 [template]
// CHECK:STDOUT:   %.loc9_11.3: @F.%.loc9_4.5 (%.b276ea.1) = splice_inst %tuple.elem0.loc9 [template = %.loc9_11.3 (constants.%.756)]
// CHECK:STDOUT:   %.loc9_4.7: <instruction> = convert_to_category_action %.loc9_4.2, element9 [template]
// CHECK:STDOUT:   %.loc9_4.8: @F.%.loc9_4.5 (%.b276ea.1) = splice_inst %.loc9_4.7 [template = %.loc9_4.8 (constants.%.560)]
// CHECK:STDOUT:   %.loc10_11.3: <instruction> = access_member_action %b.ref.loc10, value [template]
// CHECK:STDOUT:   %.loc10_11.4: type = type_of_inst %.loc10_11.3 [template = %.loc10_11.4 (constants.%.b276ea.2)]
// CHECK:STDOUT:   %.loc10_11.5: @F.%.loc10_11.4 (%.b276ea.2) = splice_inst %.loc10_11.3 [template = %.loc10_11.5 (constants.%.06fc86.2)]
// CHECK:STDOUT:   %.loc10_17.2: %tuple.type.f7a = initialize_action %.loc10_11.2, %T.loc7_7.1, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc10: <instruction> = tuple_access %.loc10_17.2, element0 [template]
// CHECK:STDOUT:   %.loc10_17.3: @F.%T.loc7_7.1 (%T.67d) = splice_inst %tuple.elem0.loc10 [template = %.loc10_17.3 (constants.%.38e)]
// CHECK:STDOUT:   %.loc8_3.8: <instruction> = compound_member_access_action %b.var, constants.%assoc2 [template]
// CHECK:STDOUT:   %.loc8_3.9: type = type_of_inst %.loc8_3.8 [template = %.loc8_3.9 (constants.%.8cb)]
// CHECK:STDOUT:   %.loc8_3.10: @F.%.loc8_3.9 (%.8cb) = splice_inst %.loc8_3.8 [template = %.loc8_3.10 (constants.%.c23)]
// CHECK:STDOUT:   %.loc8_3.11: <instruction> = call_action (%.loc8_3.3), true [template]
// CHECK:STDOUT:   %.loc8_3.12: type = type_of_inst %.loc8_3.11 [template = %.loc8_3.12 (constants.%.57c)]
// CHECK:STDOUT:   %.loc8_3.13: @F.%.loc8_3.12 (%.57c) = splice_inst %.loc8_3.11 [template = %.loc8_3.13 (constants.%.e63)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%v.param: @F.%T.loc7_7.1 (%T.67d)) -> out %return.param: @F.%T.loc7_7.1 (%T.67d) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %b.var: ref @F.%.loc8_19.9 (%.537) = var_storage %b.var_patt.loc8_3.1
// CHECK:STDOUT:     %DefaultOrUnformed.facet.loc8_20.1: %DefaultOrUnformed.type = facet_value constants.%.537, (constants.%DefaultOrUnformed.lookup_impl_witness) [template = %DefaultOrUnformed.facet.loc8_20.2 (constants.%DefaultOrUnformed.facet.67e)]
// CHECK:STDOUT:     %.loc8_20.1: %DefaultOrUnformed.type = converted constants.%.537, %DefaultOrUnformed.facet.loc8_20.1 [template = %DefaultOrUnformed.facet.loc8_20.2 (constants.%DefaultOrUnformed.facet.67e)]
// CHECK:STDOUT:     %.loc8_20.2: type = type_of_inst %.loc8_20.6 [template = %.loc8_20.7 (constants.%.77d)]
// CHECK:STDOUT:     %.loc8_20.3: @F.%.loc8_20.7 (%.77d) = splice_inst %.loc8_20.6 [template = %.loc8_20.8 (constants.%.984)]
// CHECK:STDOUT:     %.loc8_20.4: type = type_of_inst %.loc8_20.9 [template = %.loc8_20.10 (constants.%.b48)]
// CHECK:STDOUT:     %.loc8_20.5: @F.%.loc8_20.10 (%.b48) = splice_inst %.loc8_20.9 [template = %.loc8_20.11 (constants.%.e18)]
// CHECK:STDOUT:     %.loc8_3.1: @F.%.loc8_19.9 (%.537) = splice_inst %tuple.elem0.loc8 [template = %.loc8_3.7 (constants.%.5d6)]
// CHECK:STDOUT:     assign %b.var, %.loc8_3.1
// CHECK:STDOUT:     %.loc8_19.1: type = splice_block %.loc8_19.4 [template = %.loc8_19.9 (constants.%.537)] {
// CHECK:STDOUT:       %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %Box.ref: %Box.type = name_ref Box, imports.%Box.template [concrete = constants.%Box.template]
// CHECK:STDOUT:       %T.ref.loc8: type = name_ref T, %T.loc7_7.2 [symbolic = %T.loc7_7.1 (constants.%T.67d)]
// CHECK:STDOUT:       %.loc8_18.1: type = template_inst %T.ref.loc8 [template = %.loc8_18.2 (constants.%.a92)]
// CHECK:STDOUT:       %.loc8_19.2: type = type_of_inst %.loc8_19.5 [template = %.loc8_19.6 (constants.%.218)]
// CHECK:STDOUT:       %.loc8_19.3: @F.%.loc8_19.6 (%.218) = splice_inst %.loc8_19.5 [template = %.loc8_19.7 (constants.%.55c)]
// CHECK:STDOUT:       %.loc8_19.4: type = splice_inst %.loc8_19.8 [template = %.loc8_19.9 (constants.%.537)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: ref @F.%.loc8_19.9 (%.537) = wrapper_binding b, %b.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %b.patt.loc8_8.1: @F.%pattern_type.loc8 (%pattern_type.fcb) = ref_binding_pattern b [template = %b.patt.loc8_8.2 (constants.%b.patt.ef6)]
// CHECK:STDOUT:       %b.var_patt.loc8_3.1: @F.%pattern_type.loc8 (%pattern_type.fcb) = var_pattern %b.patt.loc8_8.1 [template = %b.var_patt.loc8_3.2 (constants.%b.var_patt.20b)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b.ref.loc9: ref @F.%.loc8_19.9 (%.537) = name_ref b, %b
// CHECK:STDOUT:     %.loc9_4.1: type = type_of_inst %.loc9_4.4 [template = %.loc9_4.5 (constants.%.b276ea.1)]
// CHECK:STDOUT:     %.loc9_4.2: @F.%.loc9_4.5 (%.b276ea.1) = splice_inst %.loc9_4.4 [template = %.loc9_4.6 (constants.%.06fc86.1)]
// CHECK:STDOUT:     %v.ref: @F.%T.loc7_7.1 (%T.67d) = name_ref v, %v
// CHECK:STDOUT:     %.loc9_11.1: @F.%.loc9_4.5 (%.b276ea.1) = splice_inst %tuple.elem0.loc9 [template = %.loc9_11.3 (constants.%.756)]
// CHECK:STDOUT:     assign %.loc9_4.2, %.loc9_11.1
// CHECK:STDOUT:     %.loc9_4.3: @F.%.loc9_4.5 (%.b276ea.1) = splice_inst %.loc9_4.7 [template = %.loc9_4.8 (constants.%.560)]
// CHECK:STDOUT:     %b.ref.loc10: ref @F.%.loc8_19.9 (%.537) = name_ref b, %b
// CHECK:STDOUT:     %.loc10_11.1: type = type_of_inst %.loc10_11.3 [template = %.loc10_11.4 (constants.%.b276ea.2)]
// CHECK:STDOUT:     %.loc10_11.2: @F.%.loc10_11.4 (%.b276ea.2) = splice_inst %.loc10_11.3 [template = %.loc10_11.5 (constants.%.06fc86.2)]
// CHECK:STDOUT:     %.loc10_17.1: @F.%T.loc7_7.1 (%T.67d) = splice_inst %tuple.elem0.loc10 [template = %.loc10_17.3 (constants.%.38e)]
// CHECK:STDOUT:     %.loc8_3.2: type = type_of_inst %.loc8_3.8 [template = %.loc8_3.9 (constants.%.8cb)]
// CHECK:STDOUT:     %.loc8_3.3: @F.%.loc8_3.9 (%.8cb) = splice_inst %.loc8_3.8 [template = %.loc8_3.10 (constants.%.c23)]
// CHECK:STDOUT:     %.loc8_3.4: type = type_of_inst %.loc8_3.11 [template = %.loc8_3.12 (constants.%.57c)]
// CHECK:STDOUT:     %.loc8_3.5: @F.%.loc8_3.12 (%.57c) = splice_inst %.loc8_3.11 [template = %.loc8_3.13 (constants.%.e63)]
// CHECK:STDOUT:     return %.loc10_17.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8(%self.param: ref %Box) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8(%self.param: ref %Box) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Box.cpp_destructor.call: init %empty_tuple.type = call imports.%Box.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc7_7.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc7_7.1 => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc7 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %v.param_patt.loc7_16.2 => constants.%v.param_patt.4a6
// CHECK:STDOUT:   %v.patt.loc7_16.2 => constants.%v.patt.0d3
// CHECK:STDOUT:   %.loc7_24.1 => constants.%.184347.1
// CHECK:STDOUT:   %return.param_patt.loc7_24.2 => constants.%return.param_patt.41d2d9.1
// CHECK:STDOUT:   %return.patt.loc7_21.2 => constants.%return.patt.b39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc7_7.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc7_7.1 => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc7 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %v.param_patt.loc7_16.2 => constants.%v.param_patt.733
// CHECK:STDOUT:   %v.patt.loc7_16.2 => constants.%v.patt.808
// CHECK:STDOUT:   %.loc7_24.1 => constants.%.795
// CHECK:STDOUT:   %return.param_patt.loc7_24.2 => constants.%return.param_patt.a9a
// CHECK:STDOUT:   %return.patt.loc7_21.2 => constants.%return.patt.e1b
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc7 => constants.%complete_type.f8a
// CHECK:STDOUT:   %.loc8_18.2 => constants.%i32
// CHECK:STDOUT:   %.loc8_19.5 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc8_19.6 => type
// CHECK:STDOUT:   %.loc8_19.7 => constants.%Box
// CHECK:STDOUT:   %.loc8_19.8 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc8_19.9 => constants.%Box
// CHECK:STDOUT:   %require_complete.loc8 => constants.%complete_type.900
// CHECK:STDOUT:   %pattern_type.loc8 => constants.%pattern_type.070
// CHECK:STDOUT:   %b.patt.loc8_8.2 => constants.%b.patt.257
// CHECK:STDOUT:   %b.var_patt.loc8_3.2 => constants.%b.var_patt.12d
// CHECK:STDOUT:   %DefaultOrUnformed.lookup_impl_witness => constants.%DefaultOrUnformed.impl_witness.23f
// CHECK:STDOUT:   %DefaultOrUnformed.facet.loc8_20.2 => constants.%DefaultOrUnformed.facet.2f2
// CHECK:STDOUT:   %.loc8_20.6 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc8_20.7 => constants.%.31b
// CHECK:STDOUT:   %.loc8_20.8 => constants.%T.as_type.as.DefaultOrUnformed.impl.Op.b24
// CHECK:STDOUT:   %.loc8_20.9 => constants.%inst.splice_block.426619.4
// CHECK:STDOUT:   %.loc8_20.10 => constants.%Box
// CHECK:STDOUT:   %.loc8_20.11 => <not constant>
// CHECK:STDOUT:   %.loc8_3.6 => constants.%tuple.24243e.1
// CHECK:STDOUT:   %tuple.elem0.loc8 => constants.%inst.splice_block.426619.5
// CHECK:STDOUT:   %.loc8_3.7 => <not constant>
// CHECK:STDOUT:   %.loc9_4.4 => constants.%inst.splice_block.426619.6
// CHECK:STDOUT:   %.loc9_4.5 => constants.%i32
// CHECK:STDOUT:   %.loc9_4.6 => <not constant>
// CHECK:STDOUT:   %require_complete.loc9 => constants.%complete_type.f8a
// CHECK:STDOUT:   %.loc9_11.2 => constants.%tuple.24243e.2
// CHECK:STDOUT:   %tuple.elem0.loc9 => constants.%inst.splice_block.426619.7
// CHECK:STDOUT:   %.loc9_11.3 => <not constant>
// CHECK:STDOUT:   %.loc9_4.7 => constants.%inst.splice_block.426619.8
// CHECK:STDOUT:   %.loc9_4.8 => <not constant>
// CHECK:STDOUT:   %.loc10_11.3 => constants.%inst.splice_block.426619.9
// CHECK:STDOUT:   %.loc10_11.4 => constants.%i32
// CHECK:STDOUT:   %.loc10_11.5 => <not constant>
// CHECK:STDOUT:   %.loc10_17.2 => constants.%tuple.24243e.3
// CHECK:STDOUT:   %tuple.elem0.loc10 => constants.%inst.splice_block.426619.10
// CHECK:STDOUT:   %.loc10_17.3 => <not constant>
// CHECK:STDOUT:   %.loc8_3.8 => constants.%inst.splice_block.426619.11
// CHECK:STDOUT:   %.loc8_3.9 => <bound method>
// CHECK:STDOUT:   %.loc8_3.10 => <not constant>
// CHECK:STDOUT:   %.loc8_3.11 => constants.%inst.call
// CHECK:STDOUT:   %.loc8_3.12 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc8_3.13 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- function_template_call.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %v.param_patt.4a6: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %v.patt.0d3: %pattern_type.51d1c4.1 = wrapper_binding_pattern v, %v.param_patt.4a6 [symbolic]
// CHECK:STDOUT:   %.184347.1: Core.Form = init_form %T.67d [symbolic]
// CHECK:STDOUT:   %return.param_patt.41d2d9.1: %pattern_type.51d1c4.1 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.b39: %pattern_type.51d1c4.1 = return_slot_pattern %return.param_patt.41d2d9.1, %T.67d [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %Twice.cpp_overload_set.type: type = cpp_overload_set_type @Twice.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Twice.cpp_overload_set.value: %Twice.cpp_overload_set.type = cpp_overload_set_value @Twice.cpp_overload_set [concrete]
// CHECK:STDOUT:   %.e16: type = type_of_inst @F.%.loc8_21.3 [template]
// CHECK:STDOUT:   %.275: %.e16 = splice_inst @F.%.loc8_21.3 [template]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.38e: %T.67d = splice_inst @F.%tuple.elem0 [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %v.param_patt.733: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %v.patt.808: %pattern_type.6b6 = wrapper_binding_pattern v, %v.param_patt.733 [concrete]
// CHECK:STDOUT:   %Twice__carbon_thunk.type: type = fn_type @Twice__carbon_thunk [concrete]
// CHECK:STDOUT:   %Twice__carbon_thunk: %Twice__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.73d: init %i32 = splice_block %Twice__carbon_thunk.call {
// CHECK:STDOUT:       %.aa3: %i32 = specific_inst @F.%v.ref, @F(%i32)
// CHECK:STDOUT:       %Twice__carbon_thunk.call: init %i32 = call imports.%Twice__carbon_thunk.decl(%.aa3)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.284: init %i32 = splice_block %.73d {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple: %tuple.type = tuple_value (%inst.splice_block.426619.2) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Twice = %Twice.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Twice.cpp_overload_set.value: %Twice.cpp_overload_set.type = cpp_overload_set_value @Twice.cpp_overload_set [concrete = constants.%Twice.cpp_overload_set.value]
// CHECK:STDOUT:   %Twice__carbon_thunk.decl: %Twice__carbon_thunk.type = fn_decl @Twice__carbon_thunk [concrete = constants.%Twice__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %T.patt.loc7_7.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc7_7.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:     %v.param_patt.loc7_16.1: @F.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %v.param_patt.loc7_16.2 (constants.%v.param_patt.4a6)]
// CHECK:STDOUT:     %v.patt.loc7_16.1: @F.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern v, %v.param_patt.loc7_16.1 [symbolic = %v.patt.loc7_16.2 (constants.%v.patt.0d3)]
// CHECK:STDOUT:     %return.param_patt.loc7_24.1: @F.%pattern_type (%pattern_type.51d1c4.1) = out_param_pattern [symbolic = %return.param_patt.loc7_24.2 (constants.%return.param_patt.41d2d9.1)]
// CHECK:STDOUT:     %return.patt.loc7_21.1: @F.%pattern_type (%pattern_type.51d1c4.1) = return_slot_pattern %return.param_patt.loc7_24.1, %T.ref.loc7_24 [symbolic = %return.patt.loc7_21.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc7_24: type = name_ref T, %T.loc7_7.2 [symbolic = %T.loc7_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %.loc7_24.2: Core.Form = init_form %T.ref.loc7_24 [symbolic = %.loc7_24.1 (constants.%.184347.1)]
// CHECK:STDOUT:     %.loc7_9.1: type = splice_block %.loc7_9.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc7_9.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc7_7.2: type = symbolic_binding T, 0 [symbolic = %T.loc7_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v.param: @F.%T.loc7_7.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc7_18: type = name_ref T, %T.loc7_7.2 [symbolic = %T.loc7_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v: @F.%T.loc7_7.1 (%T.67d) = wrapper_binding v, %v.param
// CHECK:STDOUT:     %return.param: ref @F.%T.loc7_7.1 (%T.67d) = out_param call_param1
// CHECK:STDOUT:     %return: ref @F.%T.loc7_7.1 (%T.67d) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%T.loc7_7.2: type) {
// CHECK:STDOUT:   %T.patt.loc7_7.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc7_7.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:   %T.loc7_7.1: type = symbolic_binding T, 0 [symbolic = %T.loc7_7.1 (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc7_7.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %v.param_patt.loc7_16.2: @F.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %v.param_patt.loc7_16.2 (constants.%v.param_patt.4a6)]
// CHECK:STDOUT:   %v.patt.loc7_16.2: @F.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern v, %v.param_patt.loc7_16.2 [symbolic = %v.patt.loc7_16.2 (constants.%v.patt.0d3)]
// CHECK:STDOUT:   %.loc7_24.1: Core.Form = init_form %T.loc7_7.1 [symbolic = %.loc7_24.1 (constants.%.184347.1)]
// CHECK:STDOUT:   %return.param_patt.loc7_24.2: @F.%pattern_type (%pattern_type.51d1c4.1) = out_param_pattern [symbolic = %return.param_patt.loc7_24.2 (constants.%return.param_patt.41d2d9.1)]
// CHECK:STDOUT:   %return.patt.loc7_21.2: @F.%pattern_type (%pattern_type.51d1c4.1) = return_slot_pattern %return.param_patt.loc7_24.2, %T.loc7_7.1 [symbolic = %return.patt.loc7_21.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc7_7.1 [symbolic = %require_complete (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %.loc8_21.3: <instruction> = call_action (%Twice.ref, %v.ref), false [template]
// CHECK:STDOUT:   %.loc8_21.4: type = type_of_inst %.loc8_21.3 [template = %.loc8_21.4 (constants.%.e16)]
// CHECK:STDOUT:   %.loc8_21.5: @F.%.loc8_21.4 (%.e16) = splice_inst %.loc8_21.3 [template = %.loc8_21.5 (constants.%.275)]
// CHECK:STDOUT:   %.loc8_22.2: %tuple.type = initialize_action %.loc8_21.2, %T.loc7_7.1, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc8_22.2, element0 [template]
// CHECK:STDOUT:   %.loc8_22.3: @F.%T.loc7_7.1 (%T.67d) = splice_inst %tuple.elem0 [template = %.loc8_22.3 (constants.%.38e)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%v.param: @F.%T.loc7_7.1 (%T.67d)) -> out %return.param: @F.%T.loc7_7.1 (%T.67d) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Twice.ref: %Twice.cpp_overload_set.type = name_ref Twice, imports.%Twice.cpp_overload_set.value [concrete = constants.%Twice.cpp_overload_set.value]
// CHECK:STDOUT:     %v.ref: @F.%T.loc7_7.1 (%T.67d) = name_ref v, %v
// CHECK:STDOUT:     %.loc8_21.1: type = type_of_inst %.loc8_21.3 [template = %.loc8_21.4 (constants.%.e16)]
// CHECK:STDOUT:     %.loc8_21.2: @F.%.loc8_21.4 (%.e16) = splice_inst %.loc8_21.3 [template = %.loc8_21.5 (constants.%.275)]
// CHECK:STDOUT:     %.loc8_22.1: @F.%T.loc7_7.1 (%T.67d) = splice_inst %tuple.elem0 [template = %.loc8_22.3 (constants.%.38e)]
// CHECK:STDOUT:     return %.loc8_22.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc7_7.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc7_7.1 => constants.%T.67d
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %v.param_patt.loc7_16.2 => constants.%v.param_patt.4a6
// CHECK:STDOUT:   %v.patt.loc7_16.2 => constants.%v.patt.0d3
// CHECK:STDOUT:   %.loc7_24.1 => constants.%.184347.1
// CHECK:STDOUT:   %return.param_patt.loc7_24.2 => constants.%return.param_patt.41d2d9.1
// CHECK:STDOUT:   %return.patt.loc7_21.2 => constants.%return.patt.b39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc7_7.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc7_7.1 => constants.%i32
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %v.param_patt.loc7_16.2 => constants.%v.param_patt.733
// CHECK:STDOUT:   %v.patt.loc7_16.2 => constants.%v.patt.808
// CHECK:STDOUT:   %.loc7_24.1 => constants.%.795
// CHECK:STDOUT:   %return.param_patt.loc7_24.2 => constants.%return.param_patt.a9a
// CHECK:STDOUT:   %return.patt.loc7_21.2 => constants.%return.patt.e1b
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.f8a
// CHECK:STDOUT:   %.loc8_21.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc8_21.4 => constants.%i32
// CHECK:STDOUT:   %.loc8_21.5 => <not constant>
// CHECK:STDOUT:   %.loc8_22.2 => constants.%tuple
// CHECK:STDOUT:   %tuple.elem0 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc8_22.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- alias_of_constant_through_specific.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Checked.type: type = generic_class_type @Checked [concrete]
// CHECK:STDOUT:   %Checked.generic: %Checked.type = struct_value () [concrete]
// CHECK:STDOUT:   %Template.type: type = generic_class_type @Template [concrete]
// CHECK:STDOUT:   %Template.generic: %Template.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_32.be027e.1: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32.f58524.1: type = class_type @Int, @Int(%int_32.be027e.1) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32.f58524.1 [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32.f58524.1 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32.f58524.1 [concrete]
// CHECK:STDOUT:   %Take.type: type = fn_type @Take [concrete]
// CHECK:STDOUT:   %Take: %Take.type = struct_value () [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %f64: type = class_type @Float, @Float(%int_64) [concrete]
// CHECK:STDOUT:   %Checked.c30: type = class_type @Checked, @Checked(%f64) [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32.f58524.1 [concrete]
// CHECK:STDOUT:   %pattern_type.ed1: type = pattern_type %const.6a8 [concrete]
// CHECK:STDOUT:   %size.patt.ad75ef.1: %pattern_type.ed1 = ref_binding_pattern size [concrete]
// CHECK:STDOUT:   %size.var_patt.8a2fe5.1: %pattern_type.ed1 = var_pattern %size.patt.ad75ef.1 [concrete]
// CHECK:STDOUT:   %size.var.644297.1: ref %i32.f58524.1 = var_storage imports.%size.var_patt.8a2fe5.1 [concrete]
// CHECK:STDOUT:   %int_8: %i32.f58524.1 = int_value 8 [concrete]
// CHECK:STDOUT:   %int_16: Core.IntLiteral = int_value 16 [concrete]
// CHECK:STDOUT:   %i16: type = class_type @Int, @Int(%int_16) [concrete]
// CHECK:STDOUT:   %Template.697: type = class_type @Template, @Template(%i16) [concrete]
// CHECK:STDOUT:   %size.patt.ad75ef.2: %pattern_type.ed1 = ref_binding_pattern size [concrete]
// CHECK:STDOUT:   %size.var_patt.8a2fe5.2: %pattern_type.ed1 = var_pattern %size.patt.ad75ef.2 [concrete]
// CHECK:STDOUT:   %size.var.644297.2: ref %i32.f58524.1 = var_storage imports.%size.var_patt.8a2fe5.2 [concrete]
// CHECK:STDOUT:   %int_2: %i32.f58524.1 = int_value 2 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32.f58524.1)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32.be027e.1) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32.be027e.1) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32.f58524.1, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32.f58524.1, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32.be027e.1) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %size.patt.ad75ef.1: %pattern_type.ed1 = ref_binding_pattern size [concrete = constants.%size.patt.ad75ef.1]
// CHECK:STDOUT:   %size.var_patt.8a2fe5.1: %pattern_type.ed1 = var_pattern %size.patt.ad75ef.1 [concrete = constants.%size.var_patt.8a2fe5.1]
// CHECK:STDOUT:   %size.var.3b6528.1: ref %const.6a8 = var_storage %size.var_patt.8a2fe5.1 [concrete]
// CHECK:STDOUT:   %size.patt.ad75ef.2: %pattern_type.ed1 = ref_binding_pattern size [concrete = constants.%size.patt.ad75ef.2]
// CHECK:STDOUT:   %size.var_patt.8a2fe5.2: %pattern_type.ed1 = var_pattern %size.patt.ad75ef.2 [concrete = constants.%size.var_patt.8a2fe5.2]
// CHECK:STDOUT:   %size.var.3b6528.2: ref %const.6a8 = var_storage %size.var_patt.8a2fe5.2 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc23 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc23: type = type_literal constants.%i32.f58524.1 [concrete = constants.%i32.f58524.1]
// CHECK:STDOUT:     %.loc23: Core.Form = init_form %i32.loc23 [concrete = constants.%.795]
// CHECK:STDOUT:     %return.param: ref %i32.f58524.1 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32.f58524.1 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() -> out %return.param: %i32.f58524.1 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Checked.ref: %Checked.type = name_ref Checked, file.%Checked.decl [concrete = constants.%Checked.generic]
// CHECK:STDOUT:   %f64: type = type_literal constants.%f64 [concrete = constants.%f64]
// CHECK:STDOUT:   %Checked: type = class_type @Checked, @Checked(constants.%f64) [concrete = constants.%Checked.c30]
// CHECK:STDOUT:   %.loc24_28.1: ref %const.6a8 = specific_constant @Checked.%Size.loc13_9.1, @Checked(constants.%f64) [concrete = imports.%size.var.3b6528.1]
// CHECK:STDOUT:   %Size.ref.loc24: ref %const.6a8 = name_ref Size, %.loc24_28.1 [concrete = imports.%size.var.3b6528.1]
// CHECK:STDOUT:   %.loc24_28.2: ref %i32.f58524.1 = as_compatible %Size.ref.loc24 [concrete = constants.%size.var.644297.1]
// CHECK:STDOUT:   %.loc24_28.3: ref %i32.f58524.1 = converted %Size.ref.loc24, %.loc24_28.2 [concrete = constants.%size.var.644297.1]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %.loc24_28.4: %i32.f58524.1 = acquire_value %.loc24_28.3 [concrete = constants.%int_8]
// CHECK:STDOUT:   %i32.loc24: type = type_literal constants.%i32.f58524.1 [concrete = constants.%i32.f58524.1]
// CHECK:STDOUT:   %a: %i32.f58524.1 = wrapper_binding a, %.loc24_28.4
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Take.ref: %Take.type = name_ref Take, file.%Take.decl [concrete = constants.%Take]
// CHECK:STDOUT:   %Template.ref: %Template.type = name_ref Template, file.%Template.decl [concrete = constants.%Template.generic]
// CHECK:STDOUT:   %i16: type = type_literal constants.%i16 [concrete = constants.%i16]
// CHECK:STDOUT:   %Template: type = class_type @Template, @Template(constants.%i16) [concrete = constants.%Template.697]
// CHECK:STDOUT:   %.loc25_28.1: ref %const.6a8 = specific_constant @Template.%Size.loc17_9.1, @Template(constants.%i16) [concrete = imports.%size.var.3b6528.2]
// CHECK:STDOUT:   %Size.ref.loc25: ref %const.6a8 = name_ref Size, %.loc25_28.1 [concrete = imports.%size.var.3b6528.2]
// CHECK:STDOUT:   %.loc25_28.2: ref %i32.f58524.1 = as_compatible %Size.ref.loc25 [concrete = constants.%size.var.644297.2]
// CHECK:STDOUT:   %.loc25_28.3: ref %i32.f58524.1 = converted %Size.ref.loc25, %.loc25_28.2 [concrete = constants.%size.var.644297.2]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %.loc25_28.4: %i32.f58524.1 = acquire_value %.loc25_28.3 [concrete = constants.%int_2]
// CHECK:STDOUT:   %Take.call: init %i32.f58524.1 = call %Take.ref(%.loc25_28.4)
// CHECK:STDOUT:   %a.ref: %i32.f58524.1 = name_ref a, %a
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc25_35.1: <bound method> = bound_method %Take.call, %impl.elem1
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32.be027e.1) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc25_35.2: <bound method> = bound_method %Take.call, %specific_fn
// CHECK:STDOUT:   %.loc25_33.1: %i32.f58524.1 = value_of_initializer %Take.call
// CHECK:STDOUT:   %.loc25_33.2: %i32.f58524.1 = converted %Take.call, %.loc25_33.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32.f58524.1 = call %bound_method.loc25_35.2(%.loc25_33.2, %a.ref)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
