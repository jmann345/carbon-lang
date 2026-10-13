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
