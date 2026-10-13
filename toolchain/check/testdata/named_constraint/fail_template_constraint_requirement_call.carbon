// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon

// A requirement `fn` of a `template constraint` has no body and is never itself
// called: a call through a type that satisfies the constraint targets the
// type's own member (fork decision F-010 / SC-1, fork/structural/plan.md D-SC-4;
// fill round 2, review findings MINOR-2 / F4).

// --- fail_direct_call.carbon
library "[[@TEST_NAME]]";

// Named with no self, the requirement's `Self` is the constraint's `.Self`
// (D-SC-20), which no type replaces.
template constraint HasCount {
  fn Count() -> i32;
}

template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

// CHECK:STDERR: fail_direct_call.carbon:[[@LINE+7]]:24: error: requirement `Count` of template constraint `HasCount` can only be called through a type that satisfies it [StructuralRequirementCalled]
// CHECK:STDERR: fn K() -> i32 { return HasCount.Count(); }
// CHECK:STDERR:                        ^~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_direct_call.carbon:[[@LINE-14]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Count() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn K() -> i32 { return HasCount.Count(); }

// CHECK:STDERR: fail_direct_call.carbon:[[@LINE+7]]:22: error: requirement `Make` of template constraint `HasMake` can only be called through a type that satisfies it [StructuralRequirementCalled]
// CHECK:STDERR: fn M() -> C { return HasMake.Make(); }
// CHECK:STDERR:                      ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_direct_call.carbon:[[@LINE-19]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Make() -> Self;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn M() -> C { return HasMake.Make(); }

// --- fail_todo_runtime_facet.carbon
library "[[@TEST_NAME]]";

// A runtime facet value is not a type: member access looks into its facet type
// with no self, as for `HasMake.Make`, and a compound access through it is
// upstream's open "associated value lookup on runtime facet value" case
// (member_access.cpp:853-858, `GetAssociatedValueImpl`), mirrored by the fork's
// TODO at member_access.cpp:987-996; ledger W-033 (runtime facet values).
template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

fn ViaLet() -> C {
  let F: HasMake = C;
  // CHECK:STDERR: fail_todo_runtime_facet.carbon:[[@LINE+7]]:10: error: requirement `Make` of template constraint `HasMake` can only be called through a type that satisfies it [StructuralRequirementCalled]
  // CHECK:STDERR:   return F.Make();
  // CHECK:STDERR:          ^~~~~~~~
  // CHECK:STDERR: fail_todo_runtime_facet.carbon:[[@LINE-12]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Make() -> Self;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return F.Make();
}

fn ViaLetCompound() -> C {
  let F: HasMake = C;
  // CHECK:STDERR: fail_todo_runtime_facet.carbon:[[@LINE+4]]:10: error: semantics TODO: `compound member access to a `template constraint` requirement through a runtime facet value` [SemanticsTodo]
  // CHECK:STDERR:   return F.(HasMake.Make)();
  // CHECK:STDERR:          ^~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return F.(HasMake.Make)();
}

// --- fail_impl_member_alias.carbon
library "[[@TEST_NAME]]";

// A requirement `fn` is a declaration of its constraint, not a function, so it
// implements no associated function, as `alias F = I2.Get` of an interface
// `I2` does not: `ImplFunctionWithNonFunction` with the requirement's note, for
// a method, an associated function, and an `extend impl` in a class, and no
// thunk (D-SC-5(b); fill round 3, review findings BLOCKER-1 and MAJOR-1: the
// thunk took the constraint's scope, passed check, crashed in the mangler and
// read as a requirement at its uses). The uses through `I` add nothing; a
// structural use of `D` finds the rejected member as an error, not a function,
// and reports it as not matching `HasF`. `(C as HasGet).Get` names `C`'s own
// member and is accepted (lower/testdata/template/template_constraint.carbon,
// `impl_member_alias`).
template constraint HasGet {
  fn Get(self) -> i32;
}

template constraint HasMake {
  fn Make() -> Self;
}

interface I {
  fn F(self) -> i32;
  fn Mk() -> Self;
}

class C {
  fn Get(unused self) -> i32 { return 4; }
  fn Make() -> C { return {}; }
}

impl C as I {
  // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE+10]]:9: error: associated function F implemented by non-function [ImplFunctionWithNonFunction]
  // CHECK:STDERR:   alias F = HasGet.Get;
  // CHECK:STDERR:         ^
  // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE-13]]:3: note: associated function F declared here [AssociatedFunctionHere]
  // CHECK:STDERR:   fn F(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE-24]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  alias F = HasGet.Get;
  // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE+10]]:9: error: associated function Mk implemented by non-function [ImplFunctionWithNonFunction]
  // CHECK:STDERR:   alias Mk = HasMake.Make;
  // CHECK:STDERR:         ^~
  // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE-23]]:3: note: associated function Mk declared here [AssociatedFunctionHere]
  // CHECK:STDERR:   fn Mk() -> Self;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE-31]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Make() -> Self;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  alias Mk = HasMake.Make;
}

class D {
  fn Get(unused self) -> i32 { return 5; }
  extend impl as I {
    // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE+10]]:11: error: associated function F implemented by non-function [ImplFunctionWithNonFunction]
    // CHECK:STDERR:     alias F = HasGet.Get;
    // CHECK:STDERR:           ^
    // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE-40]]:3: note: associated function F declared here [AssociatedFunctionHere]
    // CHECK:STDERR:   fn F(self) -> i32;
    // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
    // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE-51]]:3: note: requirement declared here [StructuralRequirementHere]
    // CHECK:STDERR:   fn Get(self) -> i32;
    // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR:
    alias F = HasGet.Get;
    fn Mk() -> D { return {}; }
  }
}

fn Use(c: C, d: D) -> i32 {
  return c.(I.F)() + d.F();
}

template constraint HasF {
  fn F(self) -> i32;
}

fn ViaHasF[template T: HasF](x: T) -> i32 { return x.F(); }

// CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE+13]]:42: error: cannot convert type `D` into type implementing `HasF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn UseStructurally(d: D) -> i32 { return ViaHasF(d); }
// CHECK:STDERR:                                          ^~~~~~~~~~
// CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE+10]]:42: note: member `F` of type `D` does not match the signature required by template constraint `HasF` [StructuralMemberMismatch]
// CHECK:STDERR: fn UseStructurally(d: D) -> i32 { return ViaHasF(d); }
// CHECK:STDERR:                                          ^~~~~~~~~~
// CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE-11]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn F(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE-11]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn ViaHasF[template T: HasF](x: T) -> i32 { return x.F(); }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn UseStructurally(d: D) -> i32 { return ViaHasF(d); }

// --- fail_ladder_alias.carbon
library "[[@TEST_NAME]]";

// p002200's migration-ladder blanket impl (p002200:612-619) with its member
// spelled as an alias of the requirement: rejected at the impl as above, with
// no diagnostic at the uses (fill round 3, review finding BLOCKER-1).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface NewF {
  fn DoF(self) -> i32;
}

impl forall [template T: HasGet] T as NewF {
  // CHECK:STDERR: fail_ladder_alias.carbon:[[@LINE+10]]:9: error: associated function DoF implemented by non-function [ImplFunctionWithNonFunction]
  // CHECK:STDERR:   alias DoF = HasGet.Get;
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR: fail_ladder_alias.carbon:[[@LINE-7]]:3: note: associated function DoF declared here [AssociatedFunctionHere]
  // CHECK:STDERR:   fn DoF(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_ladder_alias.carbon:[[@LINE-14]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  alias DoF = HasGet.Get;
}

class C {
  fn Get(unused self) -> i32 { return 6; }
}

fn G[T: NewF](x: T) -> i32 { return x.(NewF.DoF)(); }

fn Test(c: C) -> i32 {
  return G(c) + c.(NewF.DoF)();
}
