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

fn G() -> i32 { return F({.x = 8} as NoCopy).value.x; }

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
  var unused t: Template(i32) = {};
  return Checked(i32).F();
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
  return F(s).a;
}

// --- fail_todo_template_template_carbon_generic.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

class List(T: type) {
  var head: T;
}

fn G() {
  var unused a: Cpp.Apply(List, i32);
}

// --- fail_todo_deduce_through_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

fn Get[T: type](b: Cpp.Box(T)) -> T {
  return b.value;
}

fn G() -> i32 { return Get(Cpp.MakeBox(50 as i32)); }

// --- fail_todo_impl_forall_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

interface Size {
  fn Get(self) -> i32;
}

// `T` cannot be deduced through `Box<T>`, so the impl's parameter is
// not used in a way that identifies it.
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
  return Direct(s) + Compound(s) + Simple(s);
}
