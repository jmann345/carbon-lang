// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_dependent.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_dependent.carbon

// A template-dependent argument reaches the conversion chokepoint by replay at
// instantiation, with a concrete type (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-3), or at the definition, where its structural
// requirements are deferred and the conversion is performed again in each
// specific (D-SC-19 as amended for W-139).

// --- dependent_caller.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Outer[template U: type](x: U) -> i32 { return CallGet(x); }

fn Test(c: C) -> i32 { return Outer(c); }

// --- fail_dependent_caller_unsatisfied.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class D {
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE+4]]:12: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Other(self) -> i32 { return 0; }
  // CHECK:STDERR:            ^~~~
  // CHECK:STDERR:
  fn Other(self) -> i32 { return 0; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Outer[template U: type](x: U) -> i32 { return CallGet(x); }

fn Test(d: D) -> i32 {
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE+16]]:10: error: unable to monomorphize specific `Outer(D)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Outer(d);
  // CHECK:STDERR:          ^~~~~
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE-6]]:50: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR: fn Outer[template U: type](x: U) -> i32 { return CallGet(x); }
  // CHECK:STDERR:                                                  ^~~~~~~~~~
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE-9]]:50: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
  // CHECK:STDERR: fn Outer[template U: type](x: U) -> i32 { return CallGet(x); }
  // CHECK:STDERR:                                                  ^~~~~~~~~~
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE-25]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE-17]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Outer(d);
}

// --- dependent_class_arg.carbon
library "[[@TEST_NAME]]";

// D-SC-19 as amended for W-139: `Holder(T)` converts the template-dependent
// `T` to `HasGet` in `Wrap`'s definition, and each specific of `Wrap` performs
// that conversion again, here `Wrap(C)`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Wrap[template T: type](unused x: T) -> i32 {
  var h: Holder(T) = {.n = 5};
  return h.n;
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(c: C) -> i32 { return Wrap(c); }

// --- fail_dependent_class_arg_unsatisfied.carbon
library "[[@TEST_NAME]]";

// D-SC-19 as amended for W-139: `Wrap(D)` performs `Holder(T)`'s conversion
// with `D`, which has no `Get`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Wrap[template T: type](unused x: T) -> i32 {
  var h: Holder(T) = {.n = 5};
  return h.n;
}

class D {
  var v: i32;
}

// CHECK:STDERR: fail_dependent_class_arg_unsatisfied.carbon:[[@LINE+16]]:30: error: unable to monomorphize specific `Wrap(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Use(d: D) -> i32 { return Wrap(d); }
// CHECK:STDERR:                              ^~~~
// CHECK:STDERR: fail_dependent_class_arg_unsatisfied.carbon:[[@LINE-11]]:10: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR:   var h: Holder(T) = {.n = 5};
// CHECK:STDERR:          ^~~~~~~~~
// CHECK:STDERR: fail_dependent_class_arg_unsatisfied.carbon:[[@LINE-14]]:10: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR:   var h: Holder(T) = {.n = 5};
// CHECK:STDERR:          ^~~~~~~~~
// CHECK:STDERR: fail_dependent_class_arg_unsatisfied.carbon:[[@LINE-25]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_dependent_class_arg_unsatisfied.carbon:[[@LINE-25]]:14: note: initializing generic parameter `T` declared here [InitializingGenericParam]
// CHECK:STDERR: class Holder(template T: HasGet) {
// CHECK:STDERR:              ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(d: D) -> i32 { return Wrap(d); }

// --- fail_dependent_class_return_unsatisfied.carbon
library "[[@TEST_NAME]]";

// D-SC-19 as amended for W-139: the conversion is in `Wrap`'s declaration, its
// return type, and `Wrap(D)`'s declaration performs it with `D`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Wrap[template T: type](unused x: T) -> Holder(T) { return {.n = 5}; }

class D {
  var v: i32;
}

// CHECK:STDERR: fail_dependent_class_return_unsatisfied.carbon:[[@LINE+16]]:30: error: unable to monomorphize specific `Wrap(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Use(d: D) -> i32 { return Wrap(d).n; }
// CHECK:STDERR:                              ^~~~~~~
// CHECK:STDERR: fail_dependent_class_return_unsatisfied.carbon:[[@LINE-9]]:43: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn Wrap[template T: type](unused x: T) -> Holder(T) { return {.n = 5}; }
// CHECK:STDERR:                                           ^~~~~~~~~
// CHECK:STDERR: fail_dependent_class_return_unsatisfied.carbon:[[@LINE-12]]:43: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR: fn Wrap[template T: type](unused x: T) -> Holder(T) { return {.n = 5}; }
// CHECK:STDERR:                                           ^~~~~~~~~
// CHECK:STDERR: fail_dependent_class_return_unsatisfied.carbon:[[@LINE-22]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_dependent_class_return_unsatisfied.carbon:[[@LINE-22]]:14: note: initializing generic parameter `T` declared here [InitializingGenericParam]
// CHECK:STDERR: class Holder(template T: HasGet) {
// CHECK:STDERR:              ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(d: D) -> i32 { return Wrap(d).n; }

// --- fail_dependent_class_arg_checked_caller.carbon
library "[[@TEST_NAME]]";

// D-SC-19 and W-139 together: `Caller(D)` resolves `Wrap(D)`, which performs
// `Holder(T)`'s conversion with `D`; `Wrap(U)` defers it.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Wrap[template T: type](unused x: T) -> i32 {
  var h: Holder(T) = {.n = 5};
  return h.n;
}

// CHECK:STDERR: fail_dependent_class_arg_checked_caller.carbon:[[@LINE+16]]:42: error: unable to monomorphize specific `Wrap(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Caller[U: type](x: U) -> i32 { return Wrap(x); }
// CHECK:STDERR:                                          ^~~~
// CHECK:STDERR: fail_dependent_class_arg_checked_caller.carbon:[[@LINE-7]]:10: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR:   var h: Holder(T) = {.n = 5};
// CHECK:STDERR:          ^~~~~~~~~
// CHECK:STDERR: fail_dependent_class_arg_checked_caller.carbon:[[@LINE-10]]:10: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR:   var h: Holder(T) = {.n = 5};
// CHECK:STDERR:          ^~~~~~~~~
// CHECK:STDERR: fail_dependent_class_arg_checked_caller.carbon:[[@LINE-21]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_dependent_class_arg_checked_caller.carbon:[[@LINE-21]]:14: note: initializing generic parameter `T` declared here [InitializingGenericParam]
// CHECK:STDERR: class Holder(template T: HasGet) {
// CHECK:STDERR:              ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Caller[U: type](x: U) -> i32 { return Wrap(x); }

class D {
  var v: i32;
}

fn Use(d: D) -> i32 { return Caller(d); }

// --- fail_dependent_conversion_unsatisfied.carbon
library "[[@TEST_NAME]]";

// D-SC-19 as amended for W-139: a conversion of the template-dependent `T` to
// `HasGet` outside a call is also performed again in `F(D)`.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn F[template T: type](unused x: T) -> i32 {
  let unused y: HasGet = T;
  return 1;
}

class D {
  var v: i32;
}

// CHECK:STDERR: fail_dependent_conversion_unsatisfied.carbon:[[@LINE+13]]:30: error: unable to monomorphize specific `F(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Use(d: D) -> i32 { return F(d); }
// CHECK:STDERR:                              ^
// CHECK:STDERR: fail_dependent_conversion_unsatisfied.carbon:[[@LINE-11]]:26: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR:   let unused y: HasGet = T;
// CHECK:STDERR:                          ^
// CHECK:STDERR: fail_dependent_conversion_unsatisfied.carbon:[[@LINE-14]]:26: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR:   let unused y: HasGet = T;
// CHECK:STDERR:                          ^
// CHECK:STDERR: fail_dependent_conversion_unsatisfied.carbon:[[@LINE-21]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(d: D) -> i32 { return F(d); }

// --- fail_dependent_interface_arg_unsatisfied.carbon
library "[[@TEST_NAME]]";

// D-SC-19 as amended for W-139: `J(T)` converts the template-dependent `T` to
// `HasGet` in `W`'s definition, and `W(D)` performs that conversion again.
// TODO: with TP-1's eager `J(T)`, the impl's `J(V)` is reported too (W-376).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface J(template T: HasGet) {
  fn F() -> i32;
}

impl forall [V: type] i32 as J(V) {
  fn F() -> i32 { return 5; }
}

fn W[template T: type](unused x: T) -> i32 { return i32.(J(T).F)(); }

class D {
  var v: i32;
}

// CHECK:STDERR: fail_dependent_interface_arg_unsatisfied.carbon:[[@LINE+16]]:30: error: unable to monomorphize specific `W(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Use(d: D) -> i32 { return W(d); }
// CHECK:STDERR:                              ^
// CHECK:STDERR: fail_dependent_interface_arg_unsatisfied.carbon:[[@LINE-9]]:58: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn W[template T: type](unused x: T) -> i32 { return i32.(J(T).F)(); }
// CHECK:STDERR:                                                          ^~~~
// CHECK:STDERR: fail_dependent_interface_arg_unsatisfied.carbon:[[@LINE-12]]:58: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR: fn W[template T: type](unused x: T) -> i32 { return i32.(J(T).F)(); }
// CHECK:STDERR:                                                          ^~~~
// CHECK:STDERR: fail_dependent_interface_arg_unsatisfied.carbon:[[@LINE-26]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_dependent_interface_arg_unsatisfied.carbon:[[@LINE-26]]:13: note: initializing generic parameter `T` declared here [InitializingGenericParam]
// CHECK:STDERR: interface J(template T: HasGet) {
// CHECK:STDERR:             ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(d: D) -> i32 { return W(d); }
