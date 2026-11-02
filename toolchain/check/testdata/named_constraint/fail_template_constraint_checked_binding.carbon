// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon

// A `template constraint` can only constrain a `template` binding (fork
// decision F-010 / SC-1, fork/structural/plan.md D-SC-8(i)); a checked-generic
// argument that a call passes to a `template` binding is checked in each
// specific of its caller (W-139, as upstream decided leads issue 2153);
// elsewhere a checked-generic self never satisfies one (D-SC-6).

// --- fail_generic_binding.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

// CHECK:STDERR: fail_generic_binding.carbon:[[@LINE+8]]:16: error: template constraint `HasGet` can only constrain a `template` binding [TemplateConstraintOnNonTemplateBinding]
// CHECK:STDERR: fn Bad(generic T: HasGet) {}
// CHECK:STDERR:                ^~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_generic_binding.carbon:[[@LINE+4]]:16: warning: binding `T` unused [UnusedBinding]
// CHECK:STDERR: fn Bad(generic T: HasGet) {}
// CHECK:STDERR:                ^~~~~~~~~
// CHECK:STDERR:
fn Bad(generic T: HasGet) {}

// --- fail_implicit_binding.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

// CHECK:STDERR: fail_implicit_binding.carbon:[[@LINE+8]]:8: error: template constraint `HasGet` can only constrain a `template` binding [TemplateConstraintOnNonTemplateBinding]
// CHECK:STDERR: fn Bad[T: HasGet](x: T) {}
// CHECK:STDERR:        ^~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_implicit_binding.carbon:[[@LINE+4]]:19: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: fn Bad[T: HasGet](x: T) {}
// CHECK:STDERR:                   ^~~~
// CHECK:STDERR:
fn Bad[T: HasGet](x: T) {}

// --- fail_implicit_binding_compound_use.carbon
library "[[@TEST_NAME]]";

// After the binding is diagnosed it has an error type (D-SC-8(i); fill round 2,
// review findings MAJOR-2 / F1), so the use of `x` in `CallGet(x)` adds no
// second diagnostic (review fold B7).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

// CHECK:STDERR: fail_implicit_binding_compound_use.carbon:[[@LINE+4]]:8: error: template constraint `HasGet` can only constrain a `template` binding [TemplateConstraintOnNonTemplateBinding]
// CHECK:STDERR: fn Bad[T: HasGet & I](x: T) -> i32 { return CallGet(x); }
// CHECK:STDERR:        ^~~~~~~~~~~~~
// CHECK:STDERR:
fn Bad[T: HasGet & I](x: T) -> i32 { return CallGet(x); }

// --- symbolic_arg.carbon
library "[[@TEST_NAME]]";

// W-139 (leads issue 2153): a checked-generic argument passed to a `template`
// binding constrained by a template constraint is checked in each specific of
// `Caller`, here `Caller(C)`, so the definition checks.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  return CallGet(x);
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(c: C) -> i32 { return Caller(c); }

// --- fail_symbolic_arg_unsatisfied.carbon
library "[[@TEST_NAME]]";

// W-139: the call is checked in `Caller(D)`, where `D` has no member `Get`.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  return CallGet(x);
}

class D {
  var v: i32;
}

// CHECK:STDERR: fail_symbolic_arg_unsatisfied.carbon:[[@LINE+13]]:30: error: unable to monomorphize specific `Caller(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Use(d: D) -> i32 { return Caller(d); }
// CHECK:STDERR:                              ^~~~~~
// CHECK:STDERR: fail_symbolic_arg_unsatisfied.carbon:[[@LINE-10]]:10: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR:   return CallGet(x);
// CHECK:STDERR:          ^~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_unsatisfied.carbon:[[@LINE-13]]:10: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR:   return CallGet(x);
// CHECK:STDERR:          ^~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_unsatisfied.carbon:[[@LINE-22]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(d: D) -> i32 { return Caller(d); }

// --- fail_symbolic_arg_mismatch.carbon
library "[[@TEST_NAME]]";

// W-139: the call is checked in `Caller(E)`, where `E.Get` returns `bool`.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  return CallGet(x);
}

class E {
  var v: i32;
  fn Get(unused self) -> bool { return true; }
}

// CHECK:STDERR: fail_symbolic_arg_mismatch.carbon:[[@LINE+13]]:30: error: unable to monomorphize specific `Caller(E)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Use(e: E) -> i32 { return Caller(e); }
// CHECK:STDERR:                              ^~~~~~
// CHECK:STDERR: fail_symbolic_arg_mismatch.carbon:[[@LINE-11]]:10: note: cannot convert type `E` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR:   return CallGet(x);
// CHECK:STDERR:          ^~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_mismatch.carbon:[[@LINE-9]]:3: note: member `Get` of type `E` does not match the signature required by template constraint `HasGet` [StructuralMemberMismatch]
// CHECK:STDERR:   fn Get(unused self) -> bool { return true; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_mismatch.carbon:[[@LINE-23]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(e: E) -> i32 { return Caller(e); }

// --- fail_symbolic_arg_result_misused.carbon
library "[[@TEST_NAME]]";

// W-139: the call has `CallGet`'s declared return type, `i32`, in the checked
// generic, so a misuse of the result is diagnosed at `Caller`'s definition,
// as it is when the constraint is an interface.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  // CHECK:STDERR: fail_symbolic_arg_result_misused.carbon:[[@LINE+7]]:24: error: cannot implicitly convert expression of type `i32` to `bool` [ConversionFailure]
  // CHECK:STDERR:   let unused b: bool = CallGet(x);
  // CHECK:STDERR:                        ^~~~~~~~~~
  // CHECK:STDERR: fail_symbolic_arg_result_misused.carbon:[[@LINE+4]]:24: note: type `i32` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let unused b: bool = CallGet(x);
  // CHECK:STDERR:                        ^~~~~~~~~~
  // CHECK:STDERR:
  let unused b: bool = CallGet(x);
  return 0;
}

// --- fail_symbolic_arg_result_member.carbon
library "[[@TEST_NAME]]";

// W-139: a member access on the call's `i32` result is checked at `Caller`'s
// definition.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  // CHECK:STDERR: fail_symbolic_arg_result_member.carbon:[[@LINE+4]]:10: error: member name `foo` not found in `i32` [MemberNameNotFoundInSpecificScope]
  // CHECK:STDERR:   return CallGet(x).foo;
  // CHECK:STDERR:          ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(x).foo;
}

// --- fail_concrete_arg_beside_symbolic.carbon
library "[[@TEST_NAME]]";

// W-139: only a checked-symbolic argument for the `template` binding is checked
// per specific; the concrete `D` bound to `T` is checked at `H`'s definition.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn G[template T: HasGet, V: type](x: T, unused y: V) -> i32 { return x.Get(); }

class D {
  var v: i32;
}

// CHECK:STDERR: fail_concrete_arg_beside_symbolic.carbon:[[@LINE+13]]:43: error: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn H[U: type](d: D, u: U) -> i32 { return G(d, u); }
// CHECK:STDERR:                                           ^~~~~~~
// CHECK:STDERR: fail_concrete_arg_beside_symbolic.carbon:[[@LINE+10]]:43: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR: fn H[U: type](d: D, u: U) -> i32 { return G(d, u); }
// CHECK:STDERR:                                           ^~~~~~~
// CHECK:STDERR: fail_concrete_arg_beside_symbolic.carbon:[[@LINE-15]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_concrete_arg_beside_symbolic.carbon:[[@LINE-15]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn G[template T: HasGet, V: type](x: T, unused y: V) -> i32 { return x.Get(); }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn H[U: type](d: D, u: U) -> i32 { return G(d, u); }

// --- fail_symbolic_conversion.carbon
library "[[@TEST_NAME]]";

// D-SC-6 stays outside a call's template binding: a conversion of a
// checked-symbolic type to a template constraint is rejected.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn Caller[U: type](unused x: U) {
  // CHECK:STDERR: fail_symbolic_conversion.carbon:[[@LINE+7]]:26: error: cannot convert type `U` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   let unused T: HasGet = U;
  // CHECK:STDERR:                          ^
  // CHECK:STDERR: fail_symbolic_conversion.carbon:[[@LINE+4]]:26: note: template constraint `HasGet` can only be satisfied by a concrete type; `U` is a checked generic binding [StructuralRequirementNeedsConcreteType]
  // CHECK:STDERR:   let unused T: HasGet = U;
  // CHECK:STDERR:                          ^
  // CHECK:STDERR:
  let unused T: HasGet = U;
}

// --- symbolic_class_arg.carbon
library "[[@TEST_NAME]]";

// W-139: a checked-generic argument for a generic class's `template` parameter
// is checked in each specific of `Make`, here `Make(C)`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Make[U: type](unused x: U) -> i32 {
  var h: Holder(U) = {.n = 3};
  return h.n;
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(c: C) -> i32 { return Make(c); }

// --- fail_symbolic_class_arg_unsatisfied.carbon
library "[[@TEST_NAME]]";

// W-139: `Holder(U)` is checked in `Make(D)`, where `D` has no member `Get`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Make[U: type](unused x: U) -> i32 {
  var h: Holder(U) = {.n = 3};
  return h.n;
}

class D {
  var v: i32;
}

// CHECK:STDERR: fail_symbolic_class_arg_unsatisfied.carbon:[[@LINE+13]]:30: error: unable to monomorphize specific `Make(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Use(d: D) -> i32 { return Make(d); }
// CHECK:STDERR:                              ^~~~
// CHECK:STDERR: fail_symbolic_class_arg_unsatisfied.carbon:[[@LINE-11]]:10: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR:   var h: Holder(U) = {.n = 3};
// CHECK:STDERR:          ^~~~~~~~~
// CHECK:STDERR: fail_symbolic_class_arg_unsatisfied.carbon:[[@LINE-14]]:10: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR:   var h: Holder(U) = {.n = 3};
// CHECK:STDERR:          ^~~~~~~~~
// CHECK:STDERR: fail_symbolic_class_arg_unsatisfied.carbon:[[@LINE-25]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(d: D) -> i32 { return Make(d); }

// --- symbolic_interface_arg.carbon
library "[[@TEST_NAME]]";

// W-139: a checked-generic argument for a generic interface's `template`
// parameter, `J(U)`, is `U` converted to `HasGet` at `Use`'s definition, and
// the blanket impl is found for it there; `J(C)` is checked in `Use(C)`.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface J(template T: HasGet) {
  fn F() -> i32;
}

impl forall [V: type] i32 as J(V) {
  fn F() -> i32 { return 5; }
}

fn Use[U: type](unused x: U) -> i32 {
  return i32.(J(U).F)();
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn UseC(c: C) -> i32 { return Use(c); }

// --- fail_symbolic_interface_arg_no_impl.carbon
library "[[@TEST_NAME]]";

// W-139: `i32` implements `J(C)` only, so `J(U)` has no impl at `Use`'s
// definition, as for an interface constraint.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface J(template T: HasGet) {
  fn F() -> i32;
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

impl i32 as J(C) {
  fn F() -> i32 { return 5; }
}

fn Use[U: type](unused x: U) -> i32 {
  // CHECK:STDERR: fail_symbolic_interface_arg_no_impl.carbon:[[@LINE+4]]:10: error: cannot convert type `i32` into type implementing `J(U as HasGet)` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return i32.(J(U).F)();
  // CHECK:STDERR:          ^~~~~~~~~~~~
  // CHECK:STDERR:
  return i32.(J(U).F)();
}

// --- fail_symbolic_arg_return_type.carbon
library "[[@TEST_NAME]]";

// W-139: `Id`'s declared return type `T` is `U` in `Caller`, so a misuse of
// the result is diagnosed at `Caller`'s definition.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn Id[template T: HasGet](x: T) -> T { return x; }

// CHECK:STDERR: fail_symbolic_arg_return_type.carbon:[[@LINE+7]]:36: error: cannot implicitly convert expression of type `U` to `bool` [ConversionFailure]
// CHECK:STDERR: fn Caller[U: type](x: U) -> bool { return Id(x); }
// CHECK:STDERR:                                    ^~~~~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_return_type.carbon:[[@LINE+4]]:36: note: type `U` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
// CHECK:STDERR: fn Caller[U: type](x: U) -> bool { return Id(x); }
// CHECK:STDERR:                                    ^~~~~~~~~~~~~
// CHECK:STDERR:
fn Caller[U: type](x: U) -> bool { return Id(x); }

// --- fail_symbolic_arg_return_type_member.carbon
library "[[@TEST_NAME]]";

// W-139: a member access on `Id(x)`, of type `U`, is checked at `Caller`'s
// definition.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn Id[template T: HasGet](x: T) -> T { return x; }

// CHECK:STDERR: fail_symbolic_arg_return_type_member.carbon:[[@LINE+8]]:42: error: type `U` does not support qualified expressions [QualifiedExprUnsupported]
// CHECK:STDERR: fn Caller[U: type](x: U) -> i32 { return Id(x).Missing(); }
// CHECK:STDERR:                                          ^~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_symbolic_arg_return_type_member.carbon:[[@LINE+4]]:42: error: cannot access member of interface `Core.Destroy` in type `U` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR: fn Caller[U: type](x: U) -> i32 { return Id(x).Missing(); }
// CHECK:STDERR:                                          ^~~~~
// CHECK:STDERR:
fn Caller[U: type](x: U) -> i32 { return Id(x).Missing(); }

// --- fail_symbolic_class_member_result.carbon
library "[[@TEST_NAME]]";

// W-139: `Holder(U).Make()` returns `U` in `Make`, so binding it to `bool` is
// diagnosed at `Make`'s definition.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
  fn Make() -> T;
}

fn Make[U: type](unused x: U) -> i32 {
  // CHECK:STDERR: fail_symbolic_class_member_result.carbon:[[@LINE+7]]:24: error: cannot implicitly convert expression of type `U` to `bool` [ConversionFailure]
  // CHECK:STDERR:   let unused b: bool = Holder(U).Make();
  // CHECK:STDERR:                        ^~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_symbolic_class_member_result.carbon:[[@LINE+4]]:24: note: type `U` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let unused b: bool = Holder(U).Make();
  // CHECK:STDERR:                        ^~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let unused b: bool = Holder(U).Make();
  return 0;
}

// --- symbolic_class_param.carbon
library "[[@TEST_NAME]]";

// W-139: `Holder(U)` is the same type at every mention, so `U` is deduced from
// a `Holder(C)` argument.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Take[U: type](h: Holder(U)) -> i32 { return h.n; }

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(h: Holder(C)) -> i32 { return Take(h); }

// --- symbolic_class_param_redecl.carbon
library "[[@TEST_NAME]]";

// W-139: a declaration and its definition name the same `Holder(U)`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Take[U: type](h: Holder(U)) -> i32;

fn Take[U: type](h: Holder(U)) -> i32 { return h.n; }

// --- symbolic_class_impl.carbon
library "[[@TEST_NAME]]";

// W-139: `Holder(U)` in an impl's self type uses `U`, and the impl is found
// for `Holder(C)`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

interface Z {
  fn F(self) -> i32;
}

impl forall [U: type] Holder(U) as Z {
  fn F(self) -> i32 { return self.n; }
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(h: Holder(C)) -> i32 { return h.(Z.F)(); }

// --- symbolic_class_forwarded.carbon
library "[[@TEST_NAME]]";

// W-139: `Outer` passes its `Holder(U)` to `Inner`, which deduces its own `U`
// from it at `Outer`'s definition.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Inner[U: type](h: Holder(U)) -> i32 { return h.n; }

fn Outer[U: type](unused x: U) -> i32 {
  let h: Holder(U) = {.n = 6};
  return Inner(h);
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(c: C) -> i32 { return Outer(c); }

// --- symbolic_arg_overload.carbon
library "[[@TEST_NAME]]";

// W-139 with an `overload fn` set: the set is resolved at `Caller`'s
// definition by declaration-order first match, and the first member accepts a
// checked-symbolic `U` as the single function would, its structural
// requirement waiting for `U` (OV-4's probe defers it too); so `Caller(C)`
// calls the first member, as `Pick(c)` does.
template constraint HasGet {
  fn Get(self) -> i32;
}

overload fn Pick[template T: HasGet](x: T) -> i32 { return x.Get(); }
overload fn Pick[template T: type](unused x: T) -> i32 { return 7; }

fn Caller[U: type](x: U) -> i32 { return Pick(x); }

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(c: C) -> i32 { return Caller(c) + Pick(c); }

// --- symbolic_arg_overload_template_first.carbon
library "[[@TEST_NAME]]";

// W-139 with an `overload fn` set: the template member accepts a
// checked-symbolic `U` at `Caller`'s definition, before the `i32` member.
template constraint HasGet {
  fn Get(self) -> i32;
}

overload fn F[template T: HasGet](x: T) -> i32 { return x.Get(); }
overload fn F(unused x: i32) -> i32 { return 2; }

fn Caller[U: type](x: U) -> i32 { return F(x); }

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(c: C) -> i32 { return Caller(c); }

// --- fail_todo_symbolic_arg_overload_unsatisfied.carbon
library "[[@TEST_NAME]]";

// W-139 with an `overload fn` set: `Caller` chose the first member at its
// definition, so `Caller(D)` checks `HasGet` against `D`, which has no `Get`.
// TODO: under issue 2153's monomorphization `Caller(D)` would go on to the
// second member, as `Pick(d)` does, and return 7 (W-375).
template constraint HasGet {
  fn Get(self) -> i32;
}

overload fn Pick[template T: HasGet](x: T) -> i32 { return x.Get(); }
overload fn Pick[template T: type](unused x: T) -> i32 { return 7; }

fn Caller[U: type](x: U) -> i32 { return Pick(x); }

class D {
  var v: i32;
}

// CHECK:STDERR: fail_todo_symbolic_arg_overload_unsatisfied.carbon:[[@LINE+13]]:30: error: unable to monomorphize specific `Caller(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Use(d: D) -> i32 { return Caller(d); }
// CHECK:STDERR:                              ^~~~~~
// CHECK:STDERR: fail_todo_symbolic_arg_overload_unsatisfied.carbon:[[@LINE-9]]:42: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn Caller[U: type](x: U) -> i32 { return Pick(x); }
// CHECK:STDERR:                                          ^~~~~~~
// CHECK:STDERR: fail_todo_symbolic_arg_overload_unsatisfied.carbon:[[@LINE-12]]:42: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR: fn Caller[U: type](x: U) -> i32 { return Pick(x); }
// CHECK:STDERR:                                          ^~~~~~~
// CHECK:STDERR: fail_todo_symbolic_arg_overload_unsatisfied.carbon:[[@LINE-21]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(d: D) -> i32 { return Caller(d); }

// --- symbolic_arg_through_template.carbon
library "[[@TEST_NAME]]";

// W-139 through a template: `Twice(U)`'s body passes `U` to `CallGet`, a
// deduction performed while `Twice(U)` is resolved; the requirement waits for
// the specific of `Twice` for each concrete argument, which performs that
// deduction again.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
fn Twice[template T: type](x: T) -> i32 { return CallGet(x) * 2; }
fn Caller[U: type](x: U) -> i32 { return Twice(x); }

// --- symbolic_arg_through_template_use.carbon
library "[[@TEST_NAME]]";

// W-139 through a template, instantiated: `Caller(C)` resolves `Twice(C)`,
// whose call `CallGet(C)` checks `HasGet` against `C`.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
fn Twice[template T: type](x: T) -> i32 { return CallGet(x) * 2; }
fn Caller[U: type](x: U) -> i32 { return Twice(x); }

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(c: C) -> i32 { return Caller(c); }

// --- fail_symbolic_arg_through_template_unsatisfied.carbon
library "[[@TEST_NAME]]";

// W-139 through a template: `Caller(D)` resolves `Twice(D)`, whose call
// `CallGet(D)` finds no `Get` in `D`.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
fn Twice[template T: type](x: T) -> i32 { return CallGet(x) * 2; }
// CHECK:STDERR: fail_symbolic_arg_through_template_unsatisfied.carbon:[[@LINE+16]]:42: error: unable to monomorphize specific `Twice(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Caller[U: type](x: U) -> i32 { return Twice(x); }
// CHECK:STDERR:                                          ^~~~~
// CHECK:STDERR: fail_symbolic_arg_through_template_unsatisfied.carbon:[[@LINE-4]]:50: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn Twice[template T: type](x: T) -> i32 { return CallGet(x) * 2; }
// CHECK:STDERR:                                                  ^~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_through_template_unsatisfied.carbon:[[@LINE-7]]:50: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR: fn Twice[template T: type](x: T) -> i32 { return CallGet(x) * 2; }
// CHECK:STDERR:                                                  ^~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_through_template_unsatisfied.carbon:[[@LINE-14]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_through_template_unsatisfied.carbon:[[@LINE-14]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Caller[U: type](x: U) -> i32 { return Twice(x); }

class D {
  var v: i32;
}

fn Use(d: D) -> i32 { return Caller(d); }

// --- symbolic_arg_return_type_used.carbon
library "[[@TEST_NAME]]";

// W-139: `Id(x)` has `Id`'s declared return type `T`, substituted with `U as
// HasGet`, so the call has type `U` and `Caller` returns it as a `U`.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn Id[template T: HasGet](x: T) -> T { return x; }

fn Caller[U: type](x: U) -> U { return Id(x); }

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

fn Use(c: C) -> i32 { return Caller(c).Get(); }

// --- symbolic_arg_impl_thunk.carbon
library "[[@TEST_NAME]]";

// W-139 through an impl's thunk: `W`'s `F` has a `template` binding where
// `I.F` has a checked `U`, so the thunk passes `U` to `F`'s `template T`, and
// its structural requirement is checked in each specific of the thunk, here
// for `C`.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  fn F[U: type](x: U) -> i32;
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

class W {}

impl W as I {
  fn F[template T: HasGet](x: T) -> i32 { return x.Get(); }
}

fn Use(c: C) -> i32 { return W.(I.F)(c); }

// --- fail_symbolic_arg_impl_thunk_unsatisfied.carbon
library "[[@TEST_NAME]]";

// W-139 through an impl's thunk: the thunk's specific for `D` checks `HasGet`
// against `D`, which has no `Get`.
// TODO: the specific of `F` for `D` is reported after it (W-376).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  fn F[U: type](x: U) -> i32;
}

class D {
  var v: i32;
}

class W {}

impl W as I {
  fn F[template T: HasGet](x: T) -> i32 { return x.Get(); }
}

// CHECK:STDERR: fail_symbolic_arg_impl_thunk_unsatisfied.carbon:[[@LINE+26]]:30: error: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn Use(d: D) -> i32 { return W.(I.F)(d); }
// CHECK:STDERR:                              ^~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_impl_thunk_unsatisfied.carbon:[[@LINE+23]]:30: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR: fn Use(d: D) -> i32 { return W.(I.F)(d); }
// CHECK:STDERR:                              ^~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_impl_thunk_unsatisfied.carbon:[[@LINE-23]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_impl_thunk_unsatisfied.carbon:[[@LINE-12]]:3: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR:   fn F[template T: HasGet](x: T) -> i32 { return x.Get(); }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_symbolic_arg_impl_thunk_unsatisfied.carbon:[[@LINE+13]]:30: error: unable to monomorphize specific `F(D)` [ResolvingSpecificHere]
// CHECK:STDERR: fn Use(d: D) -> i32 { return W.(I.F)(d); }
// CHECK:STDERR:                              ^~~~~~~
// CHECK:STDERR: fail_symbolic_arg_impl_thunk_unsatisfied.carbon:[[@LINE-19]]:3: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
// CHECK:STDERR:   fn F[template T: HasGet](x: T) -> i32 { return x.Get(); }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_impl_thunk_unsatisfied.carbon:[[@LINE-22]]:3: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
// CHECK:STDERR:   fn F[template T: HasGet](x: T) -> i32 { return x.Get(); }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_symbolic_arg_impl_thunk_unsatisfied.carbon:[[@LINE-39]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(d: D) -> i32 { return W.(I.F)(d); }

// --- require_in_interface_symbolic.carbon
library "[[@TEST_NAME]]";

// W-139: `G`'s `T: I` is checked-symbolic, and the call that passes `x` to a
// `template` binding is checked in each specific of `G`, here `G(C)`, so the
// definition checks. A structural requirement is still not forwarded through
// an interface's `require` to a member lookup in the checked binding itself,
// `x.Get()` in `G` (W-140; mirrors upstream's interface/require.carbon
// `fail_todo_implicit_self_impls`).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn G[T: I](x: T) -> i32 {
  return CallGet(x);
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
  impl as I {}
}

fn Use(c: C) -> i32 { return G(c); }

// --- fail_require_in_interface_blanket.carbon
library "[[@TEST_NAME]]";

// A CHECKED blanket impl of an interface that requires a template constraint is
// rejected at the `require` entry point (D-SC-8(iii)); no structural note is
// attached there (D-SC-9, review fold A5(ii)).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

// CHECK:STDERR: fail_require_in_interface_blanket.carbon:[[@LINE+4]]:1: error: interface `I` being implemented requires that `T` implements `HasGet` [InterfaceRequireImplsNotImplemented]
// CHECK:STDERR: impl forall [T: type] T as I {}
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
impl forall [T: type] T as I {}

// --- fail_implicit_binding_direct_use.carbon
library "[[@TEST_NAME]]";

// The direct-use sibling of `fail_implicit_binding_compound_use`: a member
// access on the error-typed binding adds no second diagnostic either (fill
// round 2, review finding F1).
template constraint HasGet {
  fn Get(self) -> i32;
}

// CHECK:STDERR: fail_implicit_binding_direct_use.carbon:[[@LINE+4]]:8: error: template constraint `HasGet` can only constrain a `template` binding [TemplateConstraintOnNonTemplateBinding]
// CHECK:STDERR: fn Bad[T: HasGet](x: T) -> i32 { return x.Get(); }
// CHECK:STDERR:        ^~~~~~~~~
// CHECK:STDERR:
fn Bad[T: HasGet](x: T) -> i32 { return x.Get(); }

// --- fail_implicit_binding_assoc_fn_use.carbon
library "[[@TEST_NAME]]";

// The associated-function sibling, through a template callee (fill round 2,
// review finding MAJOR-2: this shape used to add a second, location-less
// diagnostic inside `Use`).
template constraint HasMake {
  fn Make() -> Self;
  fn Get(self) -> i32;
}

interface I {}

fn Use[template T: HasMake](unused x: T) -> i32 { return T.Make().Get(); }

// CHECK:STDERR: fail_implicit_binding_assoc_fn_use.carbon:[[@LINE+4]]:8: error: template constraint `HasMake` can only constrain a `template` binding [TemplateConstraintOnNonTemplateBinding]
// CHECK:STDERR: fn Bad[T: HasMake & I](x: T) -> i32 { return Use(x); }
// CHECK:STDERR:        ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn Bad[T: HasMake & I](x: T) -> i32 { return Use(x); }

// --- fail_wrap_checked_binding.carbon
library "[[@TEST_NAME]]";

// D-SC-8(i) through a plain constraint's `require impls` of a template
// constraint, which fill round 1's fix 4 keeps (fill round 2, review finding
// MINOR-4).
template constraint HasGet {
  fn Get(self) -> i32;
}

constraint Wrap {
  require impls HasGet;
}

// CHECK:STDERR: fail_wrap_checked_binding.carbon:[[@LINE+4]]:8: error: template constraint `HasGet` can only constrain a `template` binding [TemplateConstraintOnNonTemplateBinding]
// CHECK:STDERR: fn Bad[T: Wrap](unused x: T) {}
// CHECK:STDERR:        ^~~~~~~
// CHECK:STDERR:
fn Bad[T: Wrap](unused x: T) {}

// --- fail_extend_require_in_interface_symbolic.carbon
library "[[@TEST_NAME]]";

// The `extend` sibling of `require_in_interface_symbolic`, whose call now
// checks per specific (W-139): `x.Get()` finds the requirement through `I`'s
// `extend require` with `Self := T`, a checked generic binding that cannot
// satisfy the constraint (D-SC-6), and a requirement is never itself called
// (D-SC-4; fill round 2, review finding MINOR-2).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  extend require impls HasGet;
}

// CHECK:STDERR: fail_extend_require_in_interface_symbolic.carbon:[[@LINE+7]]:34: error: requirement `Get` of template constraint `HasGet` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn G[T: I](x: T) -> i32 { return x.Get(); }
// CHECK:STDERR:                                  ^~~~~~~
// CHECK:STDERR: fail_extend_require_in_interface_symbolic.carbon:[[@LINE-10]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn G[T: I](x: T) -> i32 { return x.Get(); }

// --- fail_symbolic_arg_impl_deduction.carbon
library "[[@TEST_NAME]]";

// W-139 defers only the structural requirements of the call's own `template`
// binding: an impl that its conversion selects is still deduced with D-SC-6,
// so `U` does not implement `I` through a blanket impl whose `template` binding
// has a structural requirement, and the call is rejected at the definition, as
// it is for a `template T: I` (FO-1 implementation review fold, R1-M1).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  fn F() -> i32;
}

impl forall [template V: HasGet] V as I {
  fn F() -> i32 { return 4; }
}

fn CallF[template T: HasGet & I](unused x: T) -> i32 { return T.(I.F)(); }

fn Caller[U: type](x: U) -> i32 { return CallF(x); }
