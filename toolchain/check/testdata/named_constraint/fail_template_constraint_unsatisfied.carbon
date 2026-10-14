// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon

// Unsatisfied `template constraint` requirements (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-5, D-SC-9): the conversion error carries notes
// naming the first unsatisfied requirement, in declaration order.

// --- fail_missing.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class Lacking {
  // CHECK:STDERR: fail_missing.carbon:[[@LINE+4]]:12: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Other(self) -> i32 { return 0; }
  // CHECK:STDERR:            ^~~~
  // CHECK:STDERR:
  fn Other(self) -> i32 { return 0; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(l: Lacking) -> i32 {
  // CHECK:STDERR: fail_missing.carbon:[[@LINE+13]]:10: error: cannot convert type `Lacking` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(l);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_missing.carbon:[[@LINE+10]]:10: note: type `Lacking` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
  // CHECK:STDERR:   return CallGet(l);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_missing.carbon:[[@LINE-20]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_missing.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(l);
}

// --- fail_wrong_return.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  // CHECK:STDERR: fail_wrong_return.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> bool { return true; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(self) -> bool { return true; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  // CHECK:STDERR: fail_wrong_return.carbon:[[@LINE+13]]:10: error: cannot convert type `C` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_wrong_return.carbon:[[@LINE-9]]:3: note: member `Get` of type `C` does not match the signature required by template constraint `HasGet` [StructuralMemberMismatch]
  // CHECK:STDERR:   fn Get(self) -> bool { return true; }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_wrong_return.carbon:[[@LINE-20]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_wrong_return.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(c);
}

// --- fail_wrong_self.carbon
library "[[@TEST_NAME]]";

// A value `self` requirement is not satisfied by a `ref self` method.
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  // CHECK:STDERR: fail_wrong_self.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(ref self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~~~~~
  // CHECK:STDERR:
  fn Get(ref self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  // CHECK:STDERR: fail_wrong_self.carbon:[[@LINE+13]]:10: error: cannot convert type `C` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_wrong_self.carbon:[[@LINE-9]]:3: note: member `Get` of type `C` does not match the signature required by template constraint `HasGet` [StructuralMemberMismatch]
  // CHECK:STDERR:   fn Get(ref self) -> i32 { return 1; }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_wrong_self.carbon:[[@LINE-20]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_wrong_self.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(c);
}

// --- fail_wrong_arity.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  // CHECK:STDERR: fail_wrong_arity.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self, n: i32) -> i32 { return n; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(self, n: i32) -> i32 { return n; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  // CHECK:STDERR: fail_wrong_arity.carbon:[[@LINE+13]]:10: error: cannot convert type `C` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_wrong_arity.carbon:[[@LINE-9]]:3: note: member `Get` of type `C` does not match the signature required by template constraint `HasGet` [StructuralMemberMismatch]
  // CHECK:STDERR:   fn Get(self, n: i32) -> i32 { return n; }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_wrong_arity.carbon:[[@LINE-20]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_wrong_arity.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(c);
}

// --- fail_external_impl.carbon
library "[[@TEST_NAME]]";

// p002200: an external `impl C as A` does not satisfy; lookup in `C` itself
// finds nothing.
interface A {
  fn F(self);
}

template constraint HasF {
  fn F(self);
}

class C {}

impl C as A {
  // CHECK:STDERR: fail_external_impl.carbon:[[@LINE+4]]:8: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn F(self) {}
  // CHECK:STDERR:        ^~~~
  // CHECK:STDERR:
  fn F(self) {}
}

fn CallF[template T: HasF](x: T) { x.F(); }

fn Test(c: C) {
  // CHECK:STDERR: fail_external_impl.carbon:[[@LINE+13]]:3: error: cannot convert type `C` into type implementing `HasF` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   CallF(c);
  // CHECK:STDERR:   ^~~~~~~~
  // CHECK:STDERR: fail_external_impl.carbon:[[@LINE+10]]:3: note: type `C` has no member named `F` required by template constraint `HasF` [StructuralMemberMissing]
  // CHECK:STDERR:   CallF(c);
  // CHECK:STDERR:   ^~~~~~~~
  // CHECK:STDERR: fail_external_impl.carbon:[[@LINE-22]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn F(self);
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR: fail_external_impl.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallF[template T: HasF](x: T) { x.F(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  CallF(c);
}

// --- fail_private.carbon
library "[[@TEST_NAME]]";

// A private member does not satisfy from outside the class (review fold A1).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  // CHECK:STDERR: fail_private.carbon:[[@LINE+4]]:18: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   private fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:                  ^~~~
  // CHECK:STDERR:
  private fn Get(self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  // CHECK:STDERR: fail_private.carbon:[[@LINE+13]]:10: error: cannot convert type `C` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_private.carbon:[[@LINE+10]]:10: note: member `Get` of type `C` is private here and cannot satisfy template constraint `HasGet` [StructuralMemberInaccessible]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_private.carbon:[[@LINE-20]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_private.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(c);
}

// --- fail_overload_set.carbon
library "[[@TEST_NAME]]";

// An `overload fn` set is not a single function (review fold A10).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  // CHECK:STDERR: fail_overload_set.carbon:[[@LINE+4]]:19: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   overload fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:                   ^~~~
  // CHECK:STDERR:
  overload fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR: fail_overload_set.carbon:[[@LINE+4]]:19: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   overload fn Get(self, n: i32) -> i32 { return n; }
  // CHECK:STDERR:                   ^~~~
  // CHECK:STDERR:
  overload fn Get(self, n: i32) -> i32 { return n; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  // CHECK:STDERR: fail_overload_set.carbon:[[@LINE+13]]:10: error: cannot convert type `C` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_overload_set.carbon:[[@LINE+10]]:10: note: member `Get` of type `C` does not match the signature required by template constraint `HasGet` [StructuralMemberMismatch]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_overload_set.carbon:[[@LINE-25]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_overload_set.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(c);
}

// --- fail_incomplete.carbon
library "[[@TEST_NAME]]";

// An incomplete type cannot satisfy a requirement (D-SC-5(a), review fold B6):
// the TYPE is the facet argument.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Inc;

// CHECK:STDERR: fail_incomplete.carbon:[[@LINE+4]]:6: warning: binding `T` unused [UnusedBinding]
// CHECK:STDERR: fn F(template T: HasGet) {}
// CHECK:STDERR:      ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F(template T: HasGet) {}

fn Test() {
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE+10]]:3: error: incomplete type `Inc` cannot satisfy template constraint `HasGet` [StructuralRequirementIncompleteType]
  // CHECK:STDERR:   F(Inc);
  // CHECK:STDERR:   ^~~~~~
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE-12]]:1: note: class was forward declared here [ClassForwardDeclaredHere]
  // CHECK:STDERR: class Inc;
  // CHECK:STDERR: ^~~~~~~~~~
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE-9]]:6: note: initializing generic parameter `T` declared here [InitializingGenericParam]
  // CHECK:STDERR: fn F(template T: HasGet) {}
  // CHECK:STDERR:      ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  F(Inc);
}

// --- fail_incomplete_class_param.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class Inc;

class Box(template T: HasGet) {}

fn Test() {
  // CHECK:STDERR: fail_incomplete_class_param.carbon:[[@LINE+14]]:10: error: incomplete type `Inc` cannot satisfy template constraint `HasGet` [StructuralRequirementIncompleteType]
  // CHECK:STDERR:   var b: Box(Inc) = {};
  // CHECK:STDERR:          ^~~~~~~~
  // CHECK:STDERR: fail_incomplete_class_param.carbon:[[@LINE-8]]:1: note: class was forward declared here [ClassForwardDeclaredHere]
  // CHECK:STDERR: class Inc;
  // CHECK:STDERR: ^~~~~~~~~~
  // CHECK:STDERR: fail_incomplete_class_param.carbon:[[@LINE-9]]:11: note: initializing generic parameter `T` declared here [InitializingGenericParam]
  // CHECK:STDERR: class Box(template T: HasGet) {}
  // CHECK:STDERR:           ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_incomplete_class_param.carbon:[[@LINE+4]]:7: warning: binding `b` unused [UnusedBinding]
  // CHECK:STDERR:   var b: Box(Inc) = {};
  // CHECK:STDERR:       ^~~~~~~~~~~
  // CHECK:STDERR:
  var b: Box(Inc) = {};
}

// --- fail_private_base.carbon
library "[[@TEST_NAME]]";

// A private method of a base class is prohibited through the derived class's
// extended scope regardless of the access context (name_lookup.cpp's
// parent-access rule), so it is reported as inaccessible, not missing
// (commit-2 review, `found_but_prohibited`).
template constraint HasGet {
  fn Get(self) -> i32;
}

base class B {
  // CHECK:STDERR: fail_private_base.carbon:[[@LINE+4]]:18: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   private fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:                  ^~~~
  // CHECK:STDERR:
  private fn Get(self) -> i32 { return 1; }
}

class C {
  extend base: B;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  // CHECK:STDERR: fail_private_base.carbon:[[@LINE+13]]:10: error: cannot convert type `C` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_private_base.carbon:[[@LINE+10]]:10: note: member `Get` of type `C` is private here and cannot satisfy template constraint `HasGet` [StructuralMemberInaccessible]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_private_base.carbon:[[@LINE-24]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_private_base.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(c);
}

// --- fail_alias_cycle.carbon
library "[[@TEST_NAME]]";

// A requirement whose only witness in the type is an `alias` of an interface
// member, where that interface is implemented only by a blanket impl over the
// same template constraint: `D.F` needs `D as A`, which needs `D: HasF`,
// which needs `D.F`. This is an acyclic-rule violation and impl lookup
// diagnoses it unconditionally (impl_lookup.cpp, "Cycles are diagnosed even
// if they are found when diagnostics are otherwise being suppressed");
// the structural check then reads the member as unsatisfied. Pinned by the
// commit-2 review (the shape with D's own `impl as A` never probes the
// blanket impl: candidates are tried most-specific first).
interface A {
  fn F(self);
}

template constraint HasF {
  fn F(self);
}

class D {
  alias F = A.F;
}

impl forall [template T: HasF] T as A {
  // CHECK:STDERR: fail_alias_cycle.carbon:[[@LINE+4]]:8: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn F(self) {}
  // CHECK:STDERR:        ^~~~
  // CHECK:STDERR:
  fn F(self) {}
}

fn Test(d: D) {
  // CHECK:STDERR: fail_alias_cycle.carbon:[[@LINE+11]]:3: error: cycle found in search for impl of `A` for type `D` [ImplLookupCycle]
  // CHECK:STDERR:   d.F();
  // CHECK:STDERR:   ^~~
  // CHECK:STDERR: fail_alias_cycle.carbon:[[@LINE-12]]:1: note: determining if this impl clause matches [ImplLookupCycleNote]
  // CHECK:STDERR: impl forall [template T: HasF] T as A {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_alias_cycle.carbon:[[@LINE+4]]:3: error: cannot access member of interface `A` in type `D` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   d.F();
  // CHECK:STDERR:   ^~~
  // CHECK:STDERR:
  d.F();
}

// --- fail_generic_self_wrong_return.carbon
library "[[@TEST_NAME]]";

// The generic-class sibling of `fail_wrong_return`: the member's return type
// is read in its own specific, formed from the arguments of its enclosing
// specific `Box(bool)`, so `Box(bool).Get` returns `bool`, which does not match
// the required `i32` (commit-2 review, MAJOR finding).
template constraint HasGet {
  fn Get(self) -> i32;
}

class Box(T: type) {
  fn Get(self) -> T;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(b: Box(bool)) -> i32 {
  // CHECK:STDERR: fail_generic_self_wrong_return.carbon:[[@LINE+13]]:10: error: cannot convert type `Box(bool)` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(b);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_generic_self_wrong_return.carbon:[[@LINE-9]]:3: note: member `Get` of type `Box(bool)` does not match the signature required by template constraint `HasGet` [StructuralMemberMismatch]
  // CHECK:STDERR:   fn Get(self) -> T;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_generic_self_wrong_return.carbon:[[@LINE-16]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_generic_self_wrong_return.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(b);
}

// --- fail_own_params.carbon
library "[[@TEST_NAME]]";

// A member with compile-time parameters of its own never matches a requirement,
// which has none (D-SC-2; fill round 2, review finding MINOR-4). The member
// differs from the requirement in nothing else, and a call deduces its `U` from
// the requirement's `i32` (fill rounds 3 and 4, review findings F3 and MINOR-3:
// an undeducible `U` would not match under any deduction), so this split moves
// when W-136 deduces own parameters.
template constraint HasGet {
  fn Get(self, n: i32) -> i32;
}

class Box(T: type) {
  fn Get[U: type](unused self, unused n: U) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(1); }

fn Test(b: Box(i32)) -> i32 {
  // CHECK:STDERR: fail_own_params.carbon:[[@LINE+13]]:10: error: cannot convert type `Box(i32)` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(b);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_own_params.carbon:[[@LINE-9]]:3: note: member `Get` of type `Box(i32)` does not match the signature required by template constraint `HasGet` [StructuralMemberMismatch]
  // CHECK:STDERR:   fn Get[U: type](unused self, unused n: U) -> i32 { return 1; }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_own_params.carbon:[[@LINE-16]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self, n: i32) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_own_params.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(1); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(b);
}

// --- fail_alias_requirement.carbon
library "[[@TEST_NAME]]";

// The requirement itself is not a member of the type: a class whose only `Get`
// is an `alias` of the requirement does not satisfy the constraint (D-SC-5(c);
// fill round 2, review finding F2).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  alias Get = HasGet.Get;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  // CHECK:STDERR: fail_alias_requirement.carbon:[[@LINE+13]]:10: error: cannot convert type `C` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_alias_requirement.carbon:[[@LINE+10]]:10: note: name `Get` in type `C` refers to a requirement of template constraint `HasGet`, not to a member of the type [StructuralMemberIsRequirement]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_alias_requirement.carbon:[[@LINE-16]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_alias_requirement.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(c);
}

// --- fail_facet_type_self.carbon
library "[[@TEST_NAME]]";

// A facet type is not a type with members: lookup into `HasCount` finds the
// requirement `Count` itself, which does not satisfy the constraint (D-SC-5(c);
// fill round 2, review finding MINOR-1).
template constraint HasCount {
  fn Count() -> i32;
}

fn F(template T: HasCount) -> i32 { return T.Count(); }

fn Test() -> i32 {
  // CHECK:STDERR: fail_facet_type_self.carbon:[[@LINE+13]]:10: error: cannot convert type `HasCount` into type implementing `HasCount` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return F(HasCount);
  // CHECK:STDERR:          ^~~~~~~~~~~
  // CHECK:STDERR: fail_facet_type_self.carbon:[[@LINE+10]]:10: note: name `Count` in type `HasCount` refers to a requirement of template constraint `HasCount`, not to a member of the type [StructuralMemberIsRequirement]
  // CHECK:STDERR:   return F(HasCount);
  // CHECK:STDERR:          ^~~~~~~~~~~
  // CHECK:STDERR: fail_facet_type_self.carbon:[[@LINE-12]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Count() -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_facet_type_self.carbon:[[@LINE-12]]:6: note: initializing generic parameter `T` declared here [InitializingGenericParam]
  // CHECK:STDERR: fn F(template T: HasCount) -> i32 { return T.Count(); }
  // CHECK:STDERR:      ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return F(HasCount);
}

// --- fail_requirement_signature_error.carbon
library "[[@TEST_NAME]]";

// A requirement whose declaration has an error is reported there alone: a
// member that does not match it is skipped with no further diagnostic, as an
// interface member's error leaves that member of the interface's impls
// undiagnosed on trunk 0bdce60a5, so a direct use fails silently and an
// overload probe rejects the member, as for a type that does not satisfy the
// constraint (D-SC-9 as amended at fill rounds 9 and 10; round 8's review 1
// finding MINOR-3 and review 2 finding MINOR-1). A type with no member of the
// requirement's name is still reported, as a type that does not implement such
// an interface is; `fail_requirement_signature_error_other_member` and
// `fail_requirement_signature_error_other_constraint` show that every other
// requirement is still checked.
template constraint H {
  // CHECK:STDERR: fail_requirement_signature_error.carbon:[[@LINE+4]]:11: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(x: Undefined) -> i32;
  // CHECK:STDERR:           ^~~~~~~~~
  // CHECK:STDERR:
  fn F(x: Undefined) -> i32;
}

template constraint HasF {
  // CHECK:STDERR: fail_requirement_signature_error.carbon:[[@LINE+4]]:17: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self) -> Undefined;
  // CHECK:STDERR:                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self) -> Undefined;
  fn G(self) -> i32;
}

class C {
  fn F(unused x: i32) -> i32 { return 1; }
}

class D {
  fn F(unused self) -> i32 { return 1; }
  fn G(unused self) -> i32 { return 2; }
}

class E {}

overload fn P[template T: H](unused x: T) -> i32 { return 10; }
overload fn P[T: type](unused x: T) -> i32 { return 20; }

fn G1[template T: H](unused x: T) -> i32 { return 0; }

fn G2[template T: HasF](x: T) -> i32 { return x.G(); }

fn Test(c: C, d: D) -> i32 { return P(c) + G1(c) + G1(c) + G2(d) + G2(d); }

// CHECK:STDERR: fail_requirement_signature_error.carbon:[[@LINE+13]]:38: error: cannot convert type `E` into type implementing `H` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestMissing(e: E) -> i32 { return G1(e); }
// CHECK:STDERR:                                      ^~~~~
// CHECK:STDERR: fail_requirement_signature_error.carbon:[[@LINE+10]]:38: note: type `E` has no member named `F` required by template constraint `H` [StructuralMemberMissing]
// CHECK:STDERR: fn TestMissing(e: E) -> i32 { return G1(e); }
// CHECK:STDERR:                                      ^~~~~
// CHECK:STDERR: fail_requirement_signature_error.carbon:[[@LINE-38]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(x: Undefined) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error.carbon:[[@LINE-15]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn G1[template T: H](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestMissing(e: E) -> i32 { return G1(e); }

// --- fail_requirement_signature_error_other_member.carbon
library "[[@TEST_NAME]]";

// Only the requirement with the error is skipped: every other requirement of
// the constraint is still checked and reported, before or after it in
// declaration order, as trunk 0bdce60a5 reports a missing or mismatched member
// of an impl of an interface whose other member has an error (D-SC-9 as
// amended at fill round 10, round 9's review 1 finding MAJOR-1 and review 2
// finding MAJOR-1).
template constraint HasFG {
  // CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE+4]]:17: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self) -> Undefined;
  // CHECK:STDERR:                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self) -> Undefined;
  fn G(self) -> i32;
}

template constraint HasGF {
  fn G(self) -> i32;
  // CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE+4]]:17: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self) -> Undefined;
  // CHECK:STDERR:                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self) -> Undefined;
}

class Lacking {
  fn F(unused self) -> i32 { return 1; }
}

class WrongG {
  fn F(unused self) -> i32 { return 1; }
  fn G(unused self) -> bool { return true; }
}

fn CallFG[template T: HasFG](unused x: T) -> i32 { return 0; }

fn CallGF[template T: HasGF](unused x: T) -> i32 { return 0; }

// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE+13]]:44: error: cannot convert type `Lacking` into type implementing `HasFG` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestLacking(l: Lacking) -> i32 { return CallFG(l); }
// CHECK:STDERR:                                            ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE+10]]:44: note: type `Lacking` has no member named `G` required by template constraint `HasFG` [StructuralMemberMissing]
// CHECK:STDERR: fn TestLacking(l: Lacking) -> i32 { return CallFG(l); }
// CHECK:STDERR:                                            ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE-31]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn G(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE-13]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallFG[template T: HasFG](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestLacking(l: Lacking) -> i32 { return CallFG(l); }

// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE+13]]:46: error: cannot convert type `Lacking` into type implementing `HasGF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestLackingGF(l: Lacking) -> i32 { return CallGF(l); }
// CHECK:STDERR:                                              ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE+10]]:46: note: type `Lacking` has no member named `G` required by template constraint `HasGF` [StructuralMemberMissing]
// CHECK:STDERR: fn TestLackingGF(l: Lacking) -> i32 { return CallGF(l); }
// CHECK:STDERR:                                              ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE-42]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn G(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE-26]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallGF[template T: HasGF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestLackingGF(l: Lacking) -> i32 { return CallGF(l); }

// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE+13]]:42: error: cannot convert type `WrongG` into type implementing `HasFG` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestWrongG(w: WrongG) -> i32 { return CallFG(w); }
// CHECK:STDERR:                                          ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE-40]]:3: note: member `G` of type `WrongG` does not match the signature required by template constraint `HasFG` [StructuralMemberMismatch]
// CHECK:STDERR:   fn G(unused self) -> bool { return true; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE-61]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn G(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_member.carbon:[[@LINE-43]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallFG[template T: HasFG](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestWrongG(w: WrongG) -> i32 { return CallFG(w); }

// --- fail_requirement_signature_error_other_constraint.carbon
library "[[@TEST_NAME]]";

// A requirement with an error does not hide another template constraint or an
// interface of the same facet type that the type does not satisfy, as trunk
// 0bdce60a5 reports a type that does not implement the other interface of `HasF
// & HasG` when a member of `HasF` has an error (D-SC-9 as amended at fill round
// 10, round 9's review 1 finding MAJOR-1 and review 2 finding MAJOR-1).
template constraint HasF {
  // CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE+4]]:17: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self) -> Undefined;
  // CHECK:STDERR:                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self) -> Undefined;
}

template constraint HasG {
  fn G(self) -> i32;
}

interface I {
  fn K(self) -> i32;
}

class D {
  fn F(unused self) -> i32 { return 1; }
}

fn CallFG[template T: HasF & HasG](unused x: T) -> i32 { return 0; }

fn CallGF[template T: HasG & HasF](unused x: T) -> i32 { return 0; }

fn CallFI[template T: HasF & I](unused x: T) -> i32 { return 0; }

// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE+13]]:33: error: cannot convert type `D` into type implementing `HasF & HasG` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestFG(d: D) -> i32 { return CallFG(d); }
// CHECK:STDERR:                                 ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE+10]]:33: note: type `D` has no member named `G` required by template constraint `HasG` [StructuralMemberMissing]
// CHECK:STDERR: fn TestFG(d: D) -> i32 { return CallFG(d); }
// CHECK:STDERR:                                 ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE-23]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn G(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE-15]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallFG[template T: HasF & HasG](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestFG(d: D) -> i32 { return CallFG(d); }

// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE+13]]:33: error: cannot convert type `D` into type implementing `HasF & HasG` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestGF(d: D) -> i32 { return CallGF(d); }
// CHECK:STDERR:                                 ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE+10]]:33: note: type `D` has no member named `G` required by template constraint `HasG` [StructuralMemberMissing]
// CHECK:STDERR: fn TestGF(d: D) -> i32 { return CallGF(d); }
// CHECK:STDERR:                                 ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE-38]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn G(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE-28]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallGF[template T: HasG & HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestGF(d: D) -> i32 { return CallGF(d); }

// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE+7]]:33: error: cannot convert type `D` into type implementing `I & HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestFI(d: D) -> i32 { return CallFI(d); }
// CHECK:STDERR:                                 ^~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_other_constraint.carbon:[[@LINE-35]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallFI[template T: HasF & I](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestFI(d: D) -> i32 { return CallFI(d); }

// --- fail_requirement_signature_error_require.carbon
library "[[@TEST_NAME]]";

// The `require` check at a class's end (D-SC-8(iii)) skips only the requirement
// with the error too, as trunk 0bdce60a5 reports a type that does not implement
// the interface an interface requires when another member of it has an error
// (D-SC-9 as amended at fill round 10, round 9's review 1 finding MAJOR-1).
template constraint HasFG {
  // CHECK:STDERR: fail_requirement_signature_error_require.carbon:[[@LINE+4]]:17: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self) -> Undefined;
  // CHECK:STDERR:                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self) -> Undefined;
  fn G(self) -> i32;
}

interface I {
  require impls HasFG;
}

class Lacking {
  fn F(unused self) -> i32 { return 1; }
  // CHECK:STDERR: fail_requirement_signature_error_require.carbon:[[@LINE+4]]:3: error: interface `I` being implemented requires that `Lacking` implements `HasFG` [InterfaceRequireImplsNotImplemented]
  // CHECK:STDERR:   impl as I {}
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  impl as I {}
}

class Complete {
  fn F(unused self) -> i32 { return 1; }
  fn G(unused self) -> i32 { return 2; }
  impl as I {}
}

// --- fail_member_signature_error.carbon
library "[[@TEST_NAME]]";

// A member whose own declaration has an error is reported there alone: the
// requirement it cannot be compared with is skipped with no further diagnostic,
// as trunk 0bdce60a5 reports an impl member's error alone, and every other
// requirement is still checked (D-SC-9 as amended at fill round 10, round 9's
// review 1 finding MINOR-2 and review 2 finding MINOR-1).
template constraint HasFG {
  fn F(self, x: i32) -> i32;
  fn G(self) -> i32;
}

class ReturnError {
  // CHECK:STDERR: fail_member_signature_error.carbon:[[@LINE+4]]:39: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32) -> Undefined { return 0; }
  // CHECK:STDERR:                                       ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32) -> Undefined { return 0; }
  fn G(unused self) -> i32 { return 2; }
}

class ParamError {
  // CHECK:STDERR: fail_member_signature_error.carbon:[[@LINE+4]]:31: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: Undefined) -> i32 { return 1; }
  // CHECK:STDERR:                               ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: Undefined) -> i32 { return 1; }
  fn G(unused self) -> i32 { return 2; }
}

class LackingG {
  // CHECK:STDERR: fail_member_signature_error.carbon:[[@LINE+4]]:31: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: Undefined) -> i32 { return 1; }
  // CHECK:STDERR:                               ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: Undefined) -> i32 { return 1; }
}

fn Call[template T: HasFG](unused x: T) -> i32 { return 0; }

fn Test(r: ReturnError, p: ParamError) -> i32 { return Call(r) + Call(p); }

// CHECK:STDERR: fail_member_signature_error.carbon:[[@LINE+13]]:45: error: cannot convert type `LackingG` into type implementing `HasFG` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestLacking(l: LackingG) -> i32 { return Call(l); }
// CHECK:STDERR:                                             ^~~~~~~
// CHECK:STDERR: fail_member_signature_error.carbon:[[@LINE+10]]:45: note: type `LackingG` has no member named `G` required by template constraint `HasFG` [StructuralMemberMissing]
// CHECK:STDERR: fn TestLacking(l: LackingG) -> i32 { return Call(l); }
// CHECK:STDERR:                                             ^~~~~~~
// CHECK:STDERR: fail_member_signature_error.carbon:[[@LINE-39]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn G(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error.carbon:[[@LINE-13]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasFG](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestLacking(l: LackingG) -> i32 { return Call(l); }

// --- fail_todo_requirement_signature_error_overload.carbon
library "[[@TEST_NAME]]";

// TODO: W-233. An overload probe rejects a member whose constraint has a
// requirement with an error, as for a type that does not satisfy it, so when no
// other member accepts the call `OverloadNoMatch` follows the requirement's
// error, as it follows a member's own error in its parameter or its binding's
// facet type on trunk 0bdce60a5 (fill round 10, round 9's review 1 finding
// MINOR-1).
template constraint H {
  // CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE+4]]:11: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(x: Undefined) -> i32;
  // CHECK:STDERR:           ^~~~~~~~~
  // CHECK:STDERR:
  fn F(x: Undefined) -> i32;
}

class C {
  fn F(unused x: i32) -> i32 { return 1; }
}

overload fn P[template T: H](unused x: T) -> i32 { return 10; }
overload fn P(unused x: i32) -> i32 { return 20; }

// CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE+10]]:31: error: no member of overload set `P` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Test(c: C) -> i32 { return P(c); }
// CHECK:STDERR:                               ^~~~
// CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE-6]]:1: note: candidate has generic parameters that could not be deduced [OverloadCandidateRejected]
// CHECK:STDERR: overload fn P[template T: H](unused x: T) -> i32 { return 10; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE-8]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn P(unused x: i32) -> i32 { return 20; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Test(c: C) -> i32 { return P(c); }

// --- fail_todo_requirement_signature_error_blanket.carbon
library "[[@TEST_NAME]]";

// TODO: W-233. Impl selection does not apply a blanket impl whose deduction
// meets a requirement with an error, so a use of the interface reports that the
// type does not implement it after the requirement's error, as trunk 0bdce60a5
// does for a blanket impl whose own constraint has an error (fill round 10,
// round 9's review 2 finding MINOR-1).
template constraint HasF {
  // CHECK:STDERR: fail_todo_requirement_signature_error_blanket.carbon:[[@LINE+4]]:17: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self) -> Undefined;
  // CHECK:STDERR:                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self) -> Undefined;
}

interface I {
  fn K(self) -> i32;
}

impl forall [template T: HasF] T as I {
  fn K(unused self) -> i32 { return 3; }
}

class D {
  fn F(unused self) -> i32 { return 1; }
}

// CHECK:STDERR: fail_todo_requirement_signature_error_blanket.carbon:[[@LINE+4]]:31: error: cannot access member of interface `I` in type `D` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR: fn Test(d: D) -> i32 { return d.(I.K)(); }
// CHECK:STDERR:                               ^~~~~~~
// CHECK:STDERR:
fn Test(d: D) -> i32 { return d.(I.K)(); }
