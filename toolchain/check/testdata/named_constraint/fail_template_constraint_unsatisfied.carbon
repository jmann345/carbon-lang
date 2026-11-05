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

// --- fail_static_for_method.carbon
library "[[@TEST_NAME]]";

// A requirement with `self` is not satisfied by a member without one, even when
// the member's first parameter has the self type: the requirement promises a
// call as `x.Get()`, which such a member does not serve (D-SC-5(d) as amended
// at fill round 12). The converse is satisfied
// (`template_constraint_satisfy`'s `method_for_assoc_fn`).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(unused c: C) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  // CHECK:STDERR: fail_static_for_method.carbon:[[@LINE+13]]:10: error: cannot convert type `C` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(c);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_static_for_method.carbon:[[@LINE-9]]:3: note: member `Get` of type `C` does not match the signature required by template constraint `HasGet` [StructuralMemberMismatch]
  // CHECK:STDERR:   fn Get(unused c: C) -> i32 { return 1; }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_static_for_method.carbon:[[@LINE-16]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_static_for_method.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
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

// --- fail_incomplete_and_interface.carbon
library "[[@TEST_NAME]]";

// After the incomplete-type error the facet type's interfaces are still looked
// up (D-SC-9 as amended at fill round 10): `Inc`, which does not implement `I`,
// is also reported for it, as trunk 0bdce60a5 reports an incomplete class
// against `I` alone, and `Impl`, which does, is not.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {}

class Inc;

class Impl;
impl Impl as I {}

// CHECK:STDERR: fail_incomplete_and_interface.carbon:[[@LINE+4]]:6: warning: binding `T` unused [UnusedBinding]
// CHECK:STDERR: fn F(template T: HasGet & I) {}
// CHECK:STDERR:      ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F(template T: HasGet & I) {}

fn Test() {
  // CHECK:STDERR: fail_incomplete_and_interface.carbon:[[@LINE+17]]:3: error: incomplete type `Inc` cannot satisfy template constraint `HasGet` [StructuralRequirementIncompleteType]
  // CHECK:STDERR:   F(Inc);
  // CHECK:STDERR:   ^~~~~~
  // CHECK:STDERR: fail_incomplete_and_interface.carbon:[[@LINE-15]]:1: note: class was forward declared here [ClassForwardDeclaredHere]
  // CHECK:STDERR: class Inc;
  // CHECK:STDERR: ^~~~~~~~~~
  // CHECK:STDERR: fail_incomplete_and_interface.carbon:[[@LINE-9]]:6: note: initializing generic parameter `T` declared here [InitializingGenericParam]
  // CHECK:STDERR: fn F(template T: HasGet & I) {}
  // CHECK:STDERR:      ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_incomplete_and_interface.carbon:[[@LINE+7]]:3: error: cannot convert type `Inc` into type implementing `I & HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   F(Inc);
  // CHECK:STDERR:   ^~~~~~
  // CHECK:STDERR: fail_incomplete_and_interface.carbon:[[@LINE-16]]:6: note: initializing generic parameter `T` declared here [InitializingGenericParam]
  // CHECK:STDERR: fn F(template T: HasGet & I) {}
  // CHECK:STDERR:      ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  F(Inc);
  // CHECK:STDERR: fail_incomplete_and_interface.carbon:[[@LINE+10]]:3: error: incomplete type `Impl` cannot satisfy template constraint `HasGet` [StructuralRequirementIncompleteType]
  // CHECK:STDERR:   F(Impl);
  // CHECK:STDERR:   ^~~~~~~
  // CHECK:STDERR: fail_incomplete_and_interface.carbon:[[@LINE-31]]:1: note: class was forward declared here [ClassForwardDeclaredHere]
  // CHECK:STDERR: class Impl;
  // CHECK:STDERR: ^~~~~~~~~~~
  // CHECK:STDERR: fail_incomplete_and_interface.carbon:[[@LINE-27]]:6: note: initializing generic parameter `T` declared here [InitializingGenericParam]
  // CHECK:STDERR: fn F(template T: HasGet & I) {}
  // CHECK:STDERR:      ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  F(Impl);
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
// member that differs from it only where the error is (here the parameter or
// the return type with the error) is skipped with no further diagnostic, as
// building the thunk for an impl member reports nothing for such a difference
// from an interface member with the error on trunk 0bdce60a5, so a direct use
// fails silently and an overload probe rejects the member, as for a type that
// does not satisfy the constraint (D-SC-9 as amended at fill rounds 9 to 11;
// round 8's review 1 finding MINOR-3 and review 2 finding MINOR-1). A type with
// no member of the requirement's name is still reported, as a type that does
// not implement such an interface is;
// `fail_requirement_signature_error_other_member` and
// `fail_requirement_signature_error_other_constraint` show that every other
// requirement is still checked, and `fail_requirement_signature_error_genuine`
// that every other difference from this one is.
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

// --- fail_requirement_signature_error_genuine.carbon
library "[[@TEST_NAME]]";

// A requirement with an error does not hide a difference from the member that
// the error does not cause. The member is compared as for a requirement with no
// error, with only an erroneous type or default value counted as equal to the
// type or default value in its place in the member, and a parameter declared
// with a form that has an error to the parameter in its place, binding form
// included (D-SC-9 as amended at fill rounds 12 to 14). So a different number
// of parameters, a parameter that differs where neither side has an error, a
// member without the `self` the requirement has, a different return type where
// neither is an error, a member that is not a function, a parameter type that
// differs beside an erroneous default value, a binding form that differs at a
// parameter with an error (`ParamRef`, `DefaultRef`, `DefaultVar`), and a
// default value or a return type that only one side has (`DefaultAbsent`,
// `ReturnAbsent`, and `FormDefault` beside a parameter declared with a form
// that has an error) are each reported, as without the error. Building the
// thunk for an impl member reports each against an interface member with the
// error on trunk 0bdce60a5 except `OtherParamConvertible`, whose `i64` the
// thunk converts to, and `DefaultType`, `ParamRef`, `DefaultRef`, `DefaultVar`,
// `DefaultAbsent`, `ReturnAbsent` and `FormDefault`, whose interface analogs
// the thunk does not compare beside the erroneous part. A member that matches
// only through an error (`ReturnOnly`, `ParamOnly`, `DefaultOnly`,
// `DefaultBothErrors`, `MethodForStatic`, and `FormOnly`, whose `y: i32` the
// erroneous form's parameter counts as equal to, binding form included) is
// skipped, as is `ReturnForm`, whose return by value matches the requirement's
// `ref` return, since the form of the return is not compared (D-SC-5(d) as
// amended at fill round 14), where trunk's thunk reports its interface analog
// ("cannot bind durable reference to non-reference value"). A requirement with
// an expression pattern parameter, which this split held through fill round 14
// (`ExprParam`), is refused since fill round 15 (W-238) (round 10's review 1
// finding MAJOR-1 and review 2 finding MAJOR-1; round 11's review 1 findings
// MAJOR-1 and MAJOR-2 and review 2 findings MAJOR-1 and MINOR-1; round 12's
// review 1 findings MAJOR-1 and MINOR-1 and review 2 finding MAJOR-1; round
// 13's review 1 findings MAJOR-1 and MINOR-3; round 14's review 1 findings
// MAJOR-1 and MINOR-2 and review 2 findings MINOR-1 and MINOR-3).
template constraint HasReturnError {
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+4]]:25: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self, x: i32) -> Undefined;
  // CHECK:STDERR:                         ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self, x: i32) -> Undefined;
}

template constraint HasParamError {
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+4]]:17: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self, x: Undefined, y: i32) -> i32;
  // CHECK:STDERR:                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self, x: Undefined, y: i32) -> i32;
}

template constraint HasDefaultError {
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+4]]:31: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self, x: i32, y: i32 = Undefined) -> i32;
  // CHECK:STDERR:                               ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self, x: i32, y: i32 = Undefined) -> i32;
}

template constraint HasStaticParamError {
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+4]]:20: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(w: Self, x: Undefined) -> i32;
  // CHECK:STDERR:                    ^~~~~~~~~
  // CHECK:STDERR:
  fn F(w: Self, x: Undefined) -> i32;
}

template constraint HasFormError {
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+4]]:35: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self, x: i32, y:? form(ref Undefined)) -> i32;
  // CHECK:STDERR:                                   ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self, x: i32, y:? form(ref Undefined)) -> i32;
}

template constraint HasReturnForm {
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+4]]:17: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self, x: Undefined) -> ref i32;
  // CHECK:STDERR:                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self, x: Undefined) -> ref i32;
}

class Arity {
  fn F(unused self) -> i32 { return 1; }
}

class ParamType {
  fn F(unused self, unused x: bool) -> i32 { return 1; }
}

class NoSelf {
  fn F(unused x: i32, unused y: i32) -> i32 { return 1; }
}

class Field {
  var F: i32;
}

class ReturnOnly {
  fn F(unused self, unused x: i32) -> i32 { return 1; }
}

class ReturnAbsent {
  fn F(unused self, unused x: i32) {}
}

class ParamArity {
  fn F(unused self, unused x: i32) -> i32 { return 1; }
}

class OtherParam {
  fn F(unused self, unused x: i32, unused y: bool) -> i32 { return 1; }
}

class ParamReturn {
  fn F(unused self, unused x: i32, unused y: i32) -> bool { return true; }
}

class ParamOnly {
  fn F(unused self, unused x: i32, unused y: i32) -> i32 { return 1; }
}

class ParamRef {
  fn F(unused self, unused ref x: i32, unused y: i32) -> i32 { return 1; }
}

class OtherParamConvertible {
  fn F(unused self, unused x: i32, unused y: i64) -> i32 { return 1; }
}

class DefaultParamType {
  fn F(unused self, unused x: bool, unused y: i32 = 1) -> i32 { return 1; }
}

class DefaultType {
  fn F(unused self, unused x: i32, unused y: bool = true) -> i32 { return 1; }
}

class DefaultOnly {
  fn F(unused self, unused x: i32, unused y: i32 = 1) -> i32 { return 1; }
}

class DefaultAbsent {
  fn F(unused self, unused x: i32, unused y: i32) -> i32 { return 1; }
}

class DefaultRef {
  fn F(unused self, unused x: i32, unused ref y: i32 = 1) -> i32 { return 1; }
}

class DefaultVar {
  fn F(unused self, unused x: i32, unused var y: i32 = 1) -> i32 { return 1; }
}

class DefaultBothErrors {
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+4]]:52: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i32 = Undefined) -> i32 {
  // CHECK:STDERR:                                                    ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, unused y: i32 = Undefined) -> i32 {
    return 1;
  }
}

class MethodForStatic {
  fn F(unused self, unused x: i32) -> i32 { return 1; }
}

class FormOnly {
  fn F(unused self, unused x: i32, unused y: i32) -> i32 { return 1; }
}

class FormDefault {
  fn F(unused self, unused x: i32, unused y: i32 = 1) -> i32 { return 1; }
}

class ReturnForm {
  fn F(unused self, unused x: i32) -> i32 { return 1; }
}

fn CallR[template T: HasReturnError](unused x: T) -> i32 { return 0; }

fn CallP[template T: HasParamError](unused x: T) -> i32 { return 0; }

fn CallD[template T: HasDefaultError](unused x: T) -> i32 { return 0; }

fn CallS[template T: HasStaticParamError](unused x: T) -> i32 { return 0; }

fn CallF[template T: HasFormError](unused x: T) -> i32 { return 0; }

fn CallRF[template T: HasReturnForm](unused x: T) -> i32 { return 0; }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:40: error: cannot convert type `Arity` into type implementing `HasReturnError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestArity(a: Arity) -> i32 { return CallR(a); }
// CHECK:STDERR:                                        ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-112]]:3: note: member `F` of type `Arity` does not match the signature required by template constraint `HasReturnError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-159]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32) -> Undefined;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-21]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallR[template T: HasReturnError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestArity(a: Arity) -> i32 { return CallR(a); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:48: error: cannot convert type `ParamType` into type implementing `HasReturnError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamType(p: ParamType) -> i32 { return CallR(p); }
// CHECK:STDERR:                                                ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-123]]:3: note: member `F` of type `ParamType` does not match the signature required by template constraint `HasReturnError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: bool) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-174]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32) -> Undefined;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-36]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallR[template T: HasReturnError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamType(p: ParamType) -> i32 { return CallR(p); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:42: error: cannot convert type `NoSelf` into type implementing `HasReturnError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestNoSelf(n: NoSelf) -> i32 { return CallR(n); }
// CHECK:STDERR:                                          ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-134]]:3: note: member `F` of type `NoSelf` does not match the signature required by template constraint `HasReturnError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused x: i32, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-189]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32) -> Undefined;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-51]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallR[template T: HasReturnError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestNoSelf(n: NoSelf) -> i32 { return CallR(n); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:40: error: cannot convert type `Field` into type implementing `HasReturnError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestField(f: Field) -> i32 { return CallR(f); }
// CHECK:STDERR:                                        ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+10]]:40: note: member `F` of type `Field` does not match the signature required by template constraint `HasReturnError` [StructuralMemberMismatch]
// CHECK:STDERR: fn TestField(f: Field) -> i32 { return CallR(f); }
// CHECK:STDERR:                                        ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-204]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32) -> Undefined;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-66]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallR[template T: HasReturnError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestField(f: Field) -> i32 { return CallR(f); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:50: error: cannot convert type `ParamArity` into type implementing `HasParamError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamArity(p: ParamArity) -> i32 { return CallP(p); }
// CHECK:STDERR:                                                  ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-148]]:3: note: member `F` of type `ParamArity` does not match the signature required by template constraint `HasParamError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-211]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: Undefined, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-79]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallP[template T: HasParamError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamArity(p: ParamArity) -> i32 { return CallP(p); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:50: error: cannot convert type `OtherParam` into type implementing `HasParamError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestOtherParam(o: OtherParam) -> i32 { return CallP(o); }
// CHECK:STDERR:                                                  ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-159]]:3: note: member `F` of type `OtherParam` does not match the signature required by template constraint `HasParamError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: bool) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-226]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: Undefined, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-94]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallP[template T: HasParamError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestOtherParam(o: OtherParam) -> i32 { return CallP(o); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:52: error: cannot convert type `ParamReturn` into type implementing `HasParamError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamReturn(p: ParamReturn) -> i32 { return CallP(p); }
// CHECK:STDERR:                                                    ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-170]]:3: note: member `F` of type `ParamReturn` does not match the signature required by template constraint `HasParamError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i32) -> bool { return true; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-241]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: Undefined, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-109]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallP[template T: HasParamError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamReturn(p: ParamReturn) -> i32 { return CallP(p); }

fn TestOnly(r: ReturnOnly, p: ParamOnly) -> i32 { return CallR(r) + CallP(p); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:54: error: cannot convert type `ReturnAbsent` into type implementing `HasReturnError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestReturnAbsent(r: ReturnAbsent) -> i32 { return CallR(r); }
// CHECK:STDERR:                                                      ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-199]]:3: note: member `F` of type `ReturnAbsent` does not match the signature required by template constraint `HasReturnError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32) {}
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-266]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32) -> Undefined;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-128]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallR[template T: HasReturnError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestReturnAbsent(r: ReturnAbsent) -> i32 { return CallR(r); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:46: error: cannot convert type `ParamRef` into type implementing `HasParamError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamRef(p: ParamRef) -> i32 { return CallP(p); }
// CHECK:STDERR:                                              ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-194]]:3: note: member `F` of type `ParamRef` does not match the signature required by template constraint `HasParamError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused ref x: i32, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-273]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: Undefined, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-141]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallP[template T: HasParamError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamRef(p: ParamRef) -> i32 { return CallP(p); }

fn TestOtherParamConvertible(o: OtherParamConvertible) -> i32 {
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:10: error: cannot convert type `OtherParamConvertible` into type implementing `HasParamError` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallP(o);
  // CHECK:STDERR:          ^~~~~~~~
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-206]]:3: note: member `F` of type `OtherParamConvertible` does not match the signature required by template constraint `HasParamError` [StructuralMemberMismatch]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i64) -> i32 { return 1; }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-289]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn F(self, x: Undefined, y: i32) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-157]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallP[template T: HasParamError](unused x: T) -> i32 { return 0; }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallP(o);
}

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:62: error: cannot convert type `DefaultParamType` into type implementing `HasDefaultError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultParamType(d: DefaultParamType) -> i32 { return CallD(d); }
// CHECK:STDERR:                                                              ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-218]]:3: note: member `F` of type `DefaultParamType` does not match the signature required by template constraint `HasDefaultError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: bool, unused y: i32 = 1) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-297]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32 = Undefined) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-171]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallD[template T: HasDefaultError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultParamType(d: DefaultParamType) -> i32 { return CallD(d); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:52: error: cannot convert type `DefaultType` into type implementing `HasDefaultError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultType(d: DefaultType) -> i32 { return CallD(d); }
// CHECK:STDERR:                                                    ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-229]]:3: note: member `F` of type `DefaultType` does not match the signature required by template constraint `HasDefaultError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: bool = true) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-312]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32 = Undefined) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-186]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallD[template T: HasDefaultError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultType(d: DefaultType) -> i32 { return CallD(d); }

fn TestDefaultOnly(d: DefaultOnly, b: DefaultBothErrors) -> i32 {
  return CallD(d) + CallD(b);
}

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:56: error: cannot convert type `DefaultAbsent` into type implementing `HasDefaultError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultAbsent(a: DefaultAbsent) -> i32 { return CallD(a); }
// CHECK:STDERR:                                                        ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-240]]:3: note: member `F` of type `DefaultAbsent` does not match the signature required by template constraint `HasDefaultError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-331]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32 = Undefined) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-205]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallD[template T: HasDefaultError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultAbsent(a: DefaultAbsent) -> i32 { return CallD(a); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:50: error: cannot convert type `DefaultRef` into type implementing `HasDefaultError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultRef(d: DefaultRef) -> i32 { return CallD(d); }
// CHECK:STDERR:                                                  ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-251]]:3: note: member `F` of type `DefaultRef` does not match the signature required by template constraint `HasDefaultError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused ref y: i32 = 1) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-346]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32 = Undefined) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-220]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallD[template T: HasDefaultError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultRef(d: DefaultRef) -> i32 { return CallD(d); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:50: error: cannot convert type `DefaultVar` into type implementing `HasDefaultError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultVar(d: DefaultVar) -> i32 { return CallD(d); }
// CHECK:STDERR:                                                  ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-262]]:3: note: member `F` of type `DefaultVar` does not match the signature required by template constraint `HasDefaultError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused var y: i32 = 1) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-361]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32 = Undefined) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-235]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallD[template T: HasDefaultError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultVar(d: DefaultVar) -> i32 { return CallD(d); }

fn TestMethodForStatic(m: MethodForStatic) -> i32 { return CallS(m); }

fn TestFormOnly(f: FormOnly) -> i32 { return CallF(f); }

// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE+13]]:52: error: cannot convert type `FormDefault` into type implementing `HasFormError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestFormDefault(f: FormDefault) -> i32 { return CallF(f); }
// CHECK:STDERR:                                                    ^~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-259]]:3: note: member `F` of type `FormDefault` does not match the signature required by template constraint `HasFormError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i32 = 1) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-364]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y:? form(ref Undefined)) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_signature_error_genuine.carbon:[[@LINE-250]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallF[template T: HasFormError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestFormDefault(f: FormDefault) -> i32 { return CallF(f); }

fn TestReturnForm(r: ReturnForm) -> i32 { return CallRF(r); }

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

// A member whose own declaration has an error is reported there alone when it
// differs from the requirement only where the error is: the requirement is
// skipped with no further diagnostic, as trunk 0bdce60a5 reports an impl
// member's error alone when the error is the only difference from the
// interface member, and every other requirement is still checked (D-SC-9 as
// amended at fill rounds 10 and 11, round 9's review 1 finding MINOR-2 and
// review 2 finding MINOR-1). `fail_member_signature_error_genuine` shows that
// every other difference is reported.
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

// --- fail_member_signature_error_genuine.carbon
library "[[@TEST_NAME]]";

// A member whose own declaration has an error does not hide a difference from
// the requirement that the error does not cause, compared as in
// `fail_requirement_signature_error_genuine` (D-SC-9 as amended at fill rounds
// 12 to 14): a different number of parameters, a parameter that differs where
// neither side has an error, a different `self` form, a different return type
// where neither is an error, a member without the `self` the requirement has, a
// `var` parameter where the requirement's is not, compile-time parameters of
// the member's own, a parameter type that differs beside an erroneous default
// value, a binding form that differs at the parameter with the error
// (`ParamErrorRef`, `DefaultErrorRef`), a default value or a return type that
// only the member has (`DefaultError`, `ReturnErrorAbsent`), a default value
// that only the requirement has beside the member's parameter declared with a
// form that has an error (`FormErrorNoDefault`), a `self` declared with a form
// that has an error, which declares no `self`, so that the member is one
// without the `self` the requirement has (`SelfFormError`: D-SC-5(d)'s `self`
// check runs before the comparison), and a binding against the member's
// parameter that is an expression pattern with an error (`ExprParam`, compared
// by its pattern's kind). Each is reported after the member's error, as without
// the error. Building the thunk for such an impl member reports each on trunk
// 0bdce60a5 except `ParamErrorVar`, `ParamErrorGeneric`, `ParamErrorRef` and
// `ReturnErrorAbsent`, which the thunk adapts or does not compare beside the
// error, `DefaultError`, as the thunk accepts a default value of an impl
// member's own, and `FormErrorNoDefault`, whose interface analog aborts the
// thunk (W-236); round 9 reported the first three. A member that matches only
// through its errors (`ErrorsOnly`, `DefaultOnly`, and `FormErrorOnly`, whose
// erroneous form's parameter counts as equal to `y: i32`, binding form
// included) is skipped, and `DefaultOnly`'s interface analog aborts trunk's
// thunk (W-236) (round 10's review 1 finding MAJOR-1 and review 2 finding
// MAJOR-1; round 11's review 1 findings MAJOR-1 and MAJOR-2; round 12's
// review 1 findings MAJOR-1 and MINOR-1 and review 2 finding MAJOR-1; round
// 13's review 1 finding MAJOR-1; round 14's review 1 findings MAJOR-1 and
// MINOR-1 and review 2 finding MINOR-2).
template constraint HasF {
  fn F(self, x: i32, y: i32) -> i32;
}

template constraint HasDefault {
  fn F(self, x: i32, y: i32 = 1) -> i32;
}

template constraint HasNoReturn {
  fn F(self, x: i32, y: i32);
}

class ReturnErrorArity {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:39: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32) -> Undefined { return 1; }
  // CHECK:STDERR:                                       ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32) -> Undefined { return 1; }
}

class ReturnErrorParamType {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:55: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: bool) -> Undefined { return 1; }
  // CHECK:STDERR:                                                       ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, unused y: bool) -> Undefined { return 1; }
}

class ReturnErrorRefSelf {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:58: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused ref self, unused x: i32, unused y: i32) -> Undefined { return 1; }
  // CHECK:STDERR:                                                          ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused ref self, unused x: i32, unused y: i32) -> Undefined { return 1; }
}

class ParamErrorArity {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:31: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: Undefined) -> i32 { return 1; }
  // CHECK:STDERR:                               ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: Undefined) -> i32 { return 1; }
}

class ParamErrorOtherParam {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:31: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: Undefined, unused y: bool) -> i32 { return 1; }
  // CHECK:STDERR:                               ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: Undefined, unused y: bool) -> i32 { return 1; }
}

class ParamErrorReturn {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:31: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: Undefined, unused y: i32) -> bool { return true; }
  // CHECK:STDERR:                               ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: Undefined, unused y: i32) -> bool { return true; }
}

class ParamErrorNoSelf {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:33: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused w: i32, unused x: Undefined, unused y: i32) -> i32 { return 1; }
  // CHECK:STDERR:                                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused w: i32, unused x: Undefined, unused y: i32) -> i32 { return 1; }
}

class ErrorsOnly {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+8]]:31: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: Undefined, unused y: i32) -> Undefined {
  // CHECK:STDERR:                               ^~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:60: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: Undefined, unused y: i32) -> Undefined {
  // CHECK:STDERR:                                                            ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: Undefined, unused y: i32) -> Undefined {
    return 1;
  }
}

class ParamErrorVar {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:31: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: Undefined, unused var y: i32) -> i32 { return 1; }
  // CHECK:STDERR:                               ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: Undefined, unused var y: i32) -> i32 { return 1; }
}

class ParamErrorGeneric {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:47: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F[unused U: type](unused self, unused x: Undefined, unused y: i32) -> i32 {
  // CHECK:STDERR:                                               ^~~~~~~~~
  // CHECK:STDERR:
  fn F[unused U: type](unused self, unused x: Undefined, unused y: i32) -> i32 {
    return 1;
  }
}

class DefaultErrorType {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:53: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: bool = Undefined) -> i32 {
  // CHECK:STDERR:                                                     ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, unused y: bool = Undefined) -> i32 {
    return 1;
  }
}

class DefaultError {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:52: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i32 = Undefined) -> i32 {
  // CHECK:STDERR:                                                    ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, unused y: i32 = Undefined) -> i32 {
    return 1;
  }
}

class DefaultOnly {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:52: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i32 = Undefined) -> i32 {
  // CHECK:STDERR:                                                    ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, unused y: i32 = Undefined) -> i32 {
    return 1;
  }
}

class ParamErrorRef {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:35: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused ref x: Undefined, unused y: i32) -> i32 { return 1; }
  // CHECK:STDERR:                                   ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused ref x: Undefined, unused y: i32) -> i32 { return 1; }
}

class DefaultErrorRef {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:56: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, unused ref y: i32 = Undefined) -> i32 {
  // CHECK:STDERR:                                                        ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, unused ref y: i32 = Undefined) -> i32 {
    return 1;
  }
}

class ReturnErrorAbsent {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:54: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i32) -> Undefined { return 1; }
  // CHECK:STDERR:                                                      ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, unused y: i32) -> Undefined { return 1; }
}

class FormErrorOnly {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:49: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, y:? form(ref Undefined)) -> i32 {
  // CHECK:STDERR:                                                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, y:? form(ref Undefined)) -> i32 {
    return 1;
  }
}

class FormErrorNoDefault {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:49: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, y:? form(ref Undefined)) -> i32 {
  // CHECK:STDERR:                                                 ^~~~~~~~~
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, y:? form(ref Undefined)) -> i32 {
    return 1;
  }
}

class SelfFormError {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:24: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self:? form(ref Undefined), unused x: i32, unused y: i32) -> i32 {
  // CHECK:STDERR:                        ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self:? form(ref Undefined), unused x: i32, unused y: i32) -> i32 {
    return 1;
  }
}

class ExprParam {
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+8]]:36: error: name `z` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, z) -> i32 { return 1; }
  // CHECK:STDERR:                                    ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+4]]:36: error: semantics TODO: `expression pattern` [SemanticsTodo]
  // CHECK:STDERR:   fn F(unused self, unused x: i32, z) -> i32 { return 1; }
  // CHECK:STDERR:                                    ^
  // CHECK:STDERR:
  fn F(unused self, unused x: i32, z) -> i32 { return 1; }
}

fn Call[template T: HasF](unused x: T) -> i32 { return 0; }

fn CallD[template T: HasDefault](unused x: T) -> i32 { return 0; }

fn CallN[template T: HasNoReturn](unused x: T) -> i32 { return 0; }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:62: error: cannot convert type `ReturnErrorArity` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestReturnErrorArity(a: ReturnErrorArity) -> i32 { return Call(a); }
// CHECK:STDERR:                                                              ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-190]]:3: note: member `F` of type `ReturnErrorArity` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32) -> Undefined { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-209]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-15]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestReturnErrorArity(a: ReturnErrorArity) -> i32 { return Call(a); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:70: error: cannot convert type `ReturnErrorParamType` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestReturnErrorParamType(b: ReturnErrorParamType) -> i32 { return Call(b); }
// CHECK:STDERR:                                                                      ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-197]]:3: note: member `F` of type `ReturnErrorParamType` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: bool) -> Undefined { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-224]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-30]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestReturnErrorParamType(b: ReturnErrorParamType) -> i32 { return Call(b); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:66: error: cannot convert type `ReturnErrorRefSelf` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestReturnErrorRefSelf(c: ReturnErrorRefSelf) -> i32 { return Call(c); }
// CHECK:STDERR:                                                                  ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-204]]:3: note: member `F` of type `ReturnErrorRefSelf` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused ref self, unused x: i32, unused y: i32) -> Undefined { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-239]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-45]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestReturnErrorRefSelf(c: ReturnErrorRefSelf) -> i32 { return Call(c); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:60: error: cannot convert type `ParamErrorArity` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamErrorArity(d: ParamErrorArity) -> i32 { return Call(d); }
// CHECK:STDERR:                                                            ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-211]]:3: note: member `F` of type `ParamErrorArity` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: Undefined) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-254]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-60]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamErrorArity(d: ParamErrorArity) -> i32 { return Call(d); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:70: error: cannot convert type `ParamErrorOtherParam` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamErrorOtherParam(e: ParamErrorOtherParam) -> i32 { return Call(e); }
// CHECK:STDERR:                                                                      ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-218]]:3: note: member `F` of type `ParamErrorOtherParam` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: Undefined, unused y: bool) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-269]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-75]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamErrorOtherParam(e: ParamErrorOtherParam) -> i32 { return Call(e); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:62: error: cannot convert type `ParamErrorReturn` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamErrorReturn(f: ParamErrorReturn) -> i32 { return Call(f); }
// CHECK:STDERR:                                                              ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-225]]:3: note: member `F` of type `ParamErrorReturn` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: Undefined, unused y: i32) -> bool { return true; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-284]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-90]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamErrorReturn(f: ParamErrorReturn) -> i32 { return Call(f); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:62: error: cannot convert type `ParamErrorNoSelf` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamErrorNoSelf(g: ParamErrorNoSelf) -> i32 { return Call(g); }
// CHECK:STDERR:                                                              ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-232]]:3: note: member `F` of type `ParamErrorNoSelf` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused w: i32, unused x: Undefined, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-299]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-105]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamErrorNoSelf(g: ParamErrorNoSelf) -> i32 { return Call(g); }

fn TestErrorsOnly(h: ErrorsOnly) -> i32 { return Call(h); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:56: error: cannot convert type `ParamErrorVar` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamErrorVar(i: ParamErrorVar) -> i32 { return Call(i); }
// CHECK:STDERR:                                                        ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-227]]:3: note: member `F` of type `ParamErrorVar` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: Undefined, unused var y: i32) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-316]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-122]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamErrorVar(i: ParamErrorVar) -> i32 { return Call(i); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:64: error: cannot convert type `ParamErrorGeneric` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamErrorGeneric(j: ParamErrorGeneric) -> i32 { return Call(j); }
// CHECK:STDERR:                                                                ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-234]]:3: note: member `F` of type `ParamErrorGeneric` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F[unused U: type](unused self, unused x: Undefined, unused y: i32) -> i32 {
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-331]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-137]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamErrorGeneric(j: ParamErrorGeneric) -> i32 { return Call(j); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:62: error: cannot convert type `DefaultErrorType` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultErrorType(k: DefaultErrorType) -> i32 { return Call(k); }
// CHECK:STDERR:                                                              ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-239]]:3: note: member `F` of type `DefaultErrorType` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: bool = Undefined) -> i32 {
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-346]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-152]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultErrorType(k: DefaultErrorType) -> i32 { return Call(k); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:54: error: cannot convert type `DefaultError` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultError(l: DefaultError) -> i32 { return Call(l); }
// CHECK:STDERR:                                                      ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-244]]:3: note: member `F` of type `DefaultError` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i32 = Undefined) -> i32 {
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-361]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-167]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultError(l: DefaultError) -> i32 { return Call(l); }

fn TestDefaultOnly(m: DefaultOnly) -> i32 { return CallD(m); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:56: error: cannot convert type `ParamErrorRef` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestParamErrorRef(n: ParamErrorRef) -> i32 { return Call(n); }
// CHECK:STDERR:                                                        ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-241]]:3: note: member `F` of type `ParamErrorRef` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused ref x: Undefined, unused y: i32) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-378]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-184]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestParamErrorRef(n: ParamErrorRef) -> i32 { return Call(n); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:60: error: cannot convert type `DefaultErrorRef` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultErrorRef(o: DefaultErrorRef) -> i32 { return Call(o); }
// CHECK:STDERR:                                                            ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-248]]:3: note: member `F` of type `DefaultErrorRef` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused ref y: i32 = Undefined) -> i32 {
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-393]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-199]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultErrorRef(o: DefaultErrorRef) -> i32 { return Call(o); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:64: error: cannot convert type `ReturnErrorAbsent` into type implementing `HasNoReturn` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestReturnErrorAbsent(p: ReturnErrorAbsent) -> i32 { return CallN(p); }
// CHECK:STDERR:                                                                ^~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-253]]:3: note: member `F` of type `ReturnErrorAbsent` does not match the signature required by template constraint `HasNoReturn` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, unused y: i32) -> Undefined { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-400]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32);
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-210]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallN[template T: HasNoReturn](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestReturnErrorAbsent(p: ReturnErrorAbsent) -> i32 { return CallN(p); }

fn TestFormErrorOnly(q: FormErrorOnly) -> i32 { return Call(q); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:66: error: cannot convert type `FormErrorNoDefault` into type implementing `HasDefault` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestFormErrorNoDefault(r: FormErrorNoDefault) -> i32 { return CallD(r); }
// CHECK:STDERR:                                                                  ^~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-252]]:3: note: member `F` of type `FormErrorNoDefault` does not match the signature required by template constraint `HasDefault` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, y:? form(ref Undefined)) -> i32 {
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-421]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32 = 1) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-229]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallD[template T: HasDefault](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestFormErrorNoDefault(r: FormErrorNoDefault) -> i32 { return CallD(r); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:56: error: cannot convert type `SelfFormError` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestSelfFormError(s: SelfFormError) -> i32 { return Call(s); }
// CHECK:STDERR:                                                        ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-257]]:3: note: member `F` of type `SelfFormError` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(self:? form(ref Undefined), unused x: i32, unused y: i32) -> i32 {
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-440]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-246]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestSelfFormError(s: SelfFormError) -> i32 { return Call(s); }

// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE+13]]:48: error: cannot convert type `ExprParam` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestExprParam(t: ExprParam) -> i32 { return Call(t); }
// CHECK:STDERR:                                                ^~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-258]]:3: note: member `F` of type `ExprParam` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, unused x: i32, z) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-455]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, x: i32, y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_genuine.carbon:[[@LINE-261]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Call[template T: HasF](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestExprParam(t: ExprParam) -> i32 { return Call(t); }

// --- fail_member_signature_error_import_lib.carbon
library "[[@TEST_NAME]]";

// Members whose parameter wraps an expression pattern, for
// `fail_member_signature_error_import`: one with an error under `var` and
// under a default value, and one in a tuple pattern under a default value with
// an error.
class VarExpr {
  // CHECK:STDERR: fail_member_signature_error_import_lib.carbon:[[@LINE+8]]:25: error: name `z` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, var z) -> i32 { return 1; }
  // CHECK:STDERR:                         ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_member_signature_error_import_lib.carbon:[[@LINE+4]]:25: error: semantics TODO: `expression pattern` [SemanticsTodo]
  // CHECK:STDERR:   fn F(unused self, var z) -> i32 { return 1; }
  // CHECK:STDERR:                         ^
  // CHECK:STDERR:
  fn F(unused self, var z) -> i32 { return 1; }
}

class DefaultExpr {
  // CHECK:STDERR: fail_member_signature_error_import_lib.carbon:[[@LINE+8]]:22: error: name `z` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, (z) = 1) -> i32 { return 1; }
  // CHECK:STDERR:                      ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_member_signature_error_import_lib.carbon:[[@LINE+4]]:22: error: semantics TODO: `expression pattern` [SemanticsTodo]
  // CHECK:STDERR:   fn F(unused self, (z) = 1) -> i32 { return 1; }
  // CHECK:STDERR:                      ^
  // CHECK:STDERR:
  fn F(unused self, (z) = 1) -> i32 { return 1; }
}

class DefaultTupleExpr {
  // CHECK:STDERR: fail_member_signature_error_import_lib.carbon:[[@LINE+8]]:42: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(unused self, (1, unused w: i32) = Undefined) -> i32 { return 1; }
  // CHECK:STDERR:                                          ^~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_member_signature_error_import_lib.carbon:[[@LINE+4]]:22: error: semantics TODO: `expression pattern` [SemanticsTodo]
  // CHECK:STDERR:   fn F(unused self, (1, unused w: i32) = Undefined) -> i32 { return 1; }
  // CHECK:STDERR:                      ^
  // CHECK:STDERR:
  fn F(unused self, (1, unused w: i32) = Undefined) -> i32 { return 1; }
}

// --- fail_member_signature_error_import.carbon
library "[[@TEST_NAME]]";

import library "member_signature_error_import_lib";

// An imported member whose parameter wraps an expression pattern with an error
// is compared as the same member declared locally is, the expression pattern
// by its kind alone and without importing it, as upstream cannot import one
// (D-SC-9 as amended at fill round 16, round 15's review 2 finding MAJOR-1;
// W-238). No requirement has an expression pattern, so `VarExpr` is reported
// against `var y: i32` and skipped against a parameter declared with a form
// that has an error, and `DefaultExpr` is reported against `y: i32 = 1` and
// against that parameter without a default value, and skipped against it with
// one. A tuple pattern that holds one is not imported either (fill round 17,
// finding MAJOR-1 of both of round 16's reviews; W-234), so `DefaultTupleExpr`
// is reported against `y: i32 = 1` and skipped against that parameter with a
// default value. Each use aborted at import_ref.cpp:5172 before the round that
// added it; trunk 0bdce60a5 calls such an imported member, and uses an
// imported impl whose member has one, without aborting.
template constraint HasVar {
  fn F(self, var y: i32) -> i32;
}

template constraint HasDefault {
  fn F(self, y: i32 = 1) -> i32;
}

template constraint HasFormError {
  // CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE+4]]:27: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self, y:? form(ref Undefined)) -> i32;
  // CHECK:STDERR:                           ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self, y:? form(ref Undefined)) -> i32;
}

template constraint HasFormErrorDefault {
  // CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE+4]]:27: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn F(self, y:? form(ref Undefined) = 1) -> i32;
  // CHECK:STDERR:                           ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self, y:? form(ref Undefined) = 1) -> i32;
}

fn CallVar[template T: HasVar](unused x: T) -> i32 { return 0; }

fn CallDefault[template T: HasDefault](unused x: T) -> i32 { return 0; }

fn CallFormError[template T: HasFormError](unused x: T) -> i32 { return 0; }

fn CallFormErrorDefault[template T: HasFormErrorDefault](unused x: T) -> i32 {
  return 0;
}

// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE+14]]:40: error: cannot convert type `VarExpr` into type implementing `HasVar` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestVar(v: VarExpr) -> i32 { return CallVar(v); }
// CHECK:STDERR:                                        ^~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-53]]:1: in import [InImport]
// CHECK:STDERR: fail_member_signature_error_import_lib.carbon:16:3: note: member `F` of type `VarExpr` does not match the signature required by template constraint `HasVar` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, var z) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-40]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, var y: i32) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-20]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallVar[template T: HasVar](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestVar(v: VarExpr) -> i32 { return CallVar(v); }

fn TestVarFormError(v: VarExpr) -> i32 { return CallFormError(v); }

// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE+14]]:48: error: cannot convert type `DefaultExpr` into type implementing `HasDefault` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefault(d: DefaultExpr) -> i32 { return CallDefault(d); }
// CHECK:STDERR:                                                ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-71]]:1: in import [InImport]
// CHECK:STDERR: fail_member_signature_error_import_lib.carbon:28:3: note: member `F` of type `DefaultExpr` does not match the signature required by template constraint `HasDefault` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, (z) = 1) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-54]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, y: i32 = 1) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-36]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallDefault[template T: HasDefault](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefault(d: DefaultExpr) -> i32 { return CallDefault(d); }

// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE+14]]:57: error: cannot convert type `DefaultExpr` into type implementing `HasFormError` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultFormError(d: DefaultExpr) -> i32 { return CallFormError(d); }
// CHECK:STDERR:                                                         ^~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-87]]:1: in import [InImport]
// CHECK:STDERR: fail_member_signature_error_import_lib.carbon:28:3: note: member `F` of type `DefaultExpr` does not match the signature required by template constraint `HasFormError` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, (z) = 1) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-62]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, y:? form(ref Undefined)) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-50]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallFormError[template T: HasFormError](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultFormError(d: DefaultExpr) -> i32 { return CallFormError(d); }

fn TestDefaultFormErrorDefault(d: DefaultExpr) -> i32 {
  return CallFormErrorDefault(d);
}

// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE+14]]:58: error: cannot convert type `DefaultTupleExpr` into type implementing `HasDefault` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn TestDefaultTuple(d: DefaultTupleExpr) -> i32 { return CallDefault(d); }
// CHECK:STDERR:                                                          ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-107]]:1: in import [InImport]
// CHECK:STDERR: fail_member_signature_error_import_lib.carbon:40:3: note: member `F` of type `DefaultTupleExpr` does not match the signature required by template constraint `HasDefault` [StructuralMemberMismatch]
// CHECK:STDERR:   fn F(unused self, (1, unused w: i32) = Undefined) -> i32 { return 1; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-90]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self, y: i32 = 1) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_member_signature_error_import.carbon:[[@LINE-72]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallDefault[template T: HasDefault](unused x: T) -> i32 { return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestDefaultTuple(d: DefaultTupleExpr) -> i32 { return CallDefault(d); }

fn TestDefaultTupleFormErrorDefault(d: DefaultTupleExpr) -> i32 {
  return CallFormErrorDefault(d);
}

// --- fail_todo_requirement_signature_error_overload.carbon
library "[[@TEST_NAME]]";

// TODO: W-233. An overload probe rejects a member whose constraint has a
// requirement with an error, or whose argument's type has a member with an
// error, as for a type that does not satisfy it, so when no other member
// accepts the call `OverloadNoMatch` follows the requirement's or the member's
// error, as it follows a member's own error in its parameter or its binding's
// facet type on trunk 0bdce60a5 (fill rounds 10 and 11, round 9's review 1
// finding MINOR-1 and round 10's review 2 finding MINOR-3).
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

template constraint HasG {
  fn G(self) -> i32;
}

class D {
  // CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE+4]]:24: error: name `Undefined` not found [NameNotFound]
  // CHECK:STDERR:   fn G(unused self) -> Undefined { return 1; }
  // CHECK:STDERR:                        ^~~~~~~~~
  // CHECK:STDERR:
  fn G(unused self) -> Undefined { return 1; }
}

overload fn Q[template T: HasG](unused x: T) -> i32 { return 10; }
overload fn Q(unused x: i32) -> i32 { return 20; }

// CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE+10]]:31: error: no member of overload set `P` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Test(c: C) -> i32 { return P(c); }
// CHECK:STDERR:                               ^~~~
// CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE-21]]:1: note: candidate has generic parameters that could not be deduced [OverloadCandidateRejected]
// CHECK:STDERR: overload fn P[template T: H](unused x: T) -> i32 { return 10; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE-23]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn P(unused x: i32) -> i32 { return 20; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Test(c: C) -> i32 { return P(c); }

// CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE+10]]:37: error: no member of overload set `Q` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn TestMember(d: D) -> i32 { return Q(d); }
// CHECK:STDERR:                                     ^~~~
// CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE-18]]:1: note: candidate has generic parameters that could not be deduced [OverloadCandidateRejected]
// CHECK:STDERR: overload fn Q[template T: HasG](unused x: T) -> i32 { return 10; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_todo_requirement_signature_error_overload.carbon:[[@LINE-20]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn Q(unused x: i32) -> i32 { return 20; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TestMember(d: D) -> i32 { return Q(d); }

// --- fail_todo_requirement_signature_error_blanket.carbon
library "[[@TEST_NAME]]";

// TODO: W-233. Impl selection does not apply a blanket impl whose deduction
// meets a requirement with an error, so a use of the interface reports that the
// type does not implement it after the requirement's error, as trunk 0bdce60a5
// does for a blanket impl whose own constraint has an error (fill round 10,
// round 9's review 2 finding MINOR-1). The facet type's interfaces are still
// looked up after the error, so an impl-lookup cycle through them is reported
// too (`J`), as trunk reports it for the analog whose `HasF` is an interface
// with the error (fill round 11, round 10's review 2 finding MINOR-2).
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

interface J {
  fn L(self) -> i32;
}

impl forall [template T: HasF & J] T as J {
  fn L(unused self) -> i32 { return 4; }
}

// CHECK:STDERR: fail_todo_requirement_signature_error_blanket.carbon:[[@LINE+11]]:36: error: cycle found in search for impl of `J & HasF` for type `D` [ImplLookupCycle]
// CHECK:STDERR: fn TestCycle(d: D) -> i32 { return d.(J.L)(); }
// CHECK:STDERR:                                    ^~~~~~~
// CHECK:STDERR: fail_todo_requirement_signature_error_blanket.carbon:[[@LINE-7]]:1: note: determining if this impl clause matches [ImplLookupCycleNote]
// CHECK:STDERR: impl forall [template T: HasF & J] T as J {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_todo_requirement_signature_error_blanket.carbon:[[@LINE+4]]:36: error: cannot access member of interface `J` in type `D` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR: fn TestCycle(d: D) -> i32 { return d.(J.L)(); }
// CHECK:STDERR:                                    ^~~~~~~
// CHECK:STDERR:
fn TestCycle(d: D) -> i32 { return d.(J.L)(); }
