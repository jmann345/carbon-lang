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

// Named with no self, the requirement is a value of its own type, with no
// `Self` for a type to replace (D-SC-20 as amended at fill round 5).
template constraint HasCount {
  fn Count() -> i32;
}

template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

// CHECK:STDERR: fail_direct_call.carbon:[[@LINE+7]]:24: error: requirement `Count` of template constraint `HasCount` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn K() -> i32 { return HasCount.Count(); }
// CHECK:STDERR:                        ^~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_direct_call.carbon:[[@LINE-14]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Count() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn K() -> i32 { return HasCount.Count(); }

// CHECK:STDERR: fail_direct_call.carbon:[[@LINE+7]]:22: error: requirement `Make` of template constraint `HasMake` can only be used through a type that satisfies it [StructuralRequirementUsed]
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
// (member_access.cpp:878-883, `GetAssociatedValueImpl`), mirrored by the fork's
// TODO at member_access.cpp:1014-1023; ledger W-033 (runtime facet values).
template constraint HasMake {
  fn Make() -> Self;
}

class C {
  fn Make() -> C { return {}; }
}

fn ViaLet() -> C {
  let F: HasMake = C;
  // CHECK:STDERR: fail_todo_runtime_facet.carbon:[[@LINE+7]]:10: error: requirement `Make` of template constraint `HasMake` can only be used through a type that satisfies it [StructuralRequirementUsed]
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
// thunk (D-SC-5(c); fill round 3, review findings BLOCKER-1 and MAJOR-1: the
// thunk took the constraint's scope, passed check, crashed in the mangler and
// read as a requirement at its uses). The uses through `I` add nothing; a
// structural use of `D` finds the rejected member as an error, not a function,
// and reports it as not matching `HasF`, a follow-on of the impl's error (fill
// round 4, review finding MINOR-1). `(C as HasGet).Get` names `C`'s own member
// and is accepted (lower/testdata/template/template_constraint.carbon,
// `impl_member_alias`). `E` is upstream's twin, an alias of another interface's
// member: the same error, with no requirement note.
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

interface I2 {
  fn Get(self) -> i32;
}

interface OnlyF {
  fn F(self) -> i32;
}

class E {
  extend impl as I2 {
    fn Get(unused self) -> i32 { return 6; }
  }
}

impl E as OnlyF {
  // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE+7]]:9: error: associated function F implemented by non-function [ImplFunctionWithNonFunction]
  // CHECK:STDERR:   alias F = I2.Get;
  // CHECK:STDERR:         ^
  // CHECK:STDERR: fail_impl_member_alias.carbon:[[@LINE-13]]:3: note: associated function F declared here [AssociatedFunctionHere]
  // CHECK:STDERR:   fn F(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  alias F = I2.Get;
}

// --- fail_requirement_as_value.carbon
library "[[@TEST_NAME]]";

// A requirement named with no type that satisfies it is never a runtime value
// (D-SC-20 as amended at fill round 4, review finding BLOCKER-1: passed to a
// function, it checked clean and aborted lowering at its `.Self`-symbolic
// type). Since fill round 5 its type is the concrete
// `StructuralRequirementType`, and `Convert` rejects any value whose type is,
// or holds as a tuple, struct or array element or under `const` (since fill
// round 7), a requirement's type: an expression statement, an argument, and an
// element of a tuple or struct literal. A value that deduction built has no
// location of its own, so the error is at the conversion (round 5, review 1
// finding MINOR-1); an overload candidate rejects it silently, so only the
// overload set's error is reported (review 2 finding MINOR-2).
template constraint HasN {
  fn N() -> i32;
}

template constraint HasGet {
  fn Get(self) -> i32;
}

template constraint Has(X: type) {
  fn N() -> X;
}

interface J {}

fn Take[T: type](unused f: T) -> i32 { return 1; }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+7]]:18: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Statement() { HasN.N; }
// CHECK:STDERR:                  ^~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-18]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn Statement() { HasN.N; }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+10]]:31: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Arg() -> i32 { return Take(HasN.N); }
// CHECK:STDERR:                               ^~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-27]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-17]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn Arg() -> i32 { return Take(HasN.N); }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+10]]:34: error: requirement `Get` of template constraint `HasGet` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Method() -> i32 { return Take(HasGet.Get); }
// CHECK:STDERR:                                  ^~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-35]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-29]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn Method() -> i32 { return Take(HasGet.Get); }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+10]]:45: error: requirement `N` of template constraint `Has` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn GenericConstraint() -> i32 { return Take(Has(i32).N); }
// CHECK:STDERR:                                             ^~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-43]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> X;
// CHECK:STDERR:   ^~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-41]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn GenericConstraint() -> i32 { return Take(Has(i32).N); }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+10]]:37: error: requirement `Get` of template constraint `HasGet` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn FacetType() -> i32 { return Take((HasGet & J).Get); }
// CHECK:STDERR:                                     ^~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-59]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-53]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn FacetType() -> i32 { return Take((HasGet & J).Get); }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+10]]:41: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn TupleElement() -> i32 { return Take((HasN.N, 1)); }
// CHECK:STDERR:                                         ^~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-75]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-65]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn TupleElement() -> i32 { return Take((HasN.N, 1)); }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+10]]:45: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn StructField() -> i32 { return Take({.f = HasN.N}); }
// CHECK:STDERR:                                             ^~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-87]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-77]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn StructField() -> i32 { return Take({.f = HasN.N}); }

fn TemplateParam[template U: type](unused template f: U) -> i32 { return 1; }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+10]]:41: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn TemplateValueParam() -> i32 { return TemplateParam(HasN.N); }
// CHECK:STDERR:                                         ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-101]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-8]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn TemplateParam[template U: type](unused template f: U) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn TemplateValueParam() -> i32 { return TemplateParam(HasN.N); }

fn GenericParam[U: type](unused generic f: U) -> i32 { return 1; }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+10]]:40: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn GenericValueParam() -> i32 { return GenericParam(HasN.N); }
// CHECK:STDERR:                                        ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-115]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-8]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn GenericParam[U: type](unused generic f: U) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn GenericValueParam() -> i32 { return GenericParam(HasN.N); }

overload fn P(unused x: i32) -> i32 { return 1; }
overload fn P[T: type](unused f: T) -> i32 { return 2; }

// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+10]]:31: error: no member of overload set `P` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Overload() -> i32 { return P(HasN.N); }
// CHECK:STDERR:                               ^~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-6]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn P(unused x: i32) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-8]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn P[T: type](unused f: T) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Overload() -> i32 { return P(HasN.N); }

// A tuple index of a refused tuple is not diagnosed again (round 6's review 2
// finding MINOR-3: it added "type `<error>` does not support tuple indexing").
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE+7]]:34: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn TupleIndex() -> i32 { return (HasN.N, 1).1; }
// CHECK:STDERR:                                  ^~~~~~
// CHECK:STDERR: fail_requirement_as_value.carbon:[[@LINE-144]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn TupleIndex() -> i32 { return (HasN.N, 1).1; }

// --- fail_requirement_through_checked_binding_as_value.carbon
library "[[@TEST_NAME]]";

// Found through a checked binding's facet type, by `extend require`, a
// requirement is not a value either, by itself or bound to an object (fill
// round 4: the bound method checked clean and aborted lowering of the
// specific).
template constraint HasN {
  fn N() -> i32;
}

template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  extend require impls HasN;
}

interface K {
  extend require impls HasGet;
}

fn Take[T: type](unused f: T) -> i32 { return 1; }

// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE+10]]:50: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Assoc[T: I](unused x: T) -> i32 { return Take(T.N); }
// CHECK:STDERR:                                                  ^~~
// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE-20]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE-8]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn Assoc[T: I](unused x: T) -> i32 { return Take(T.N); }

// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE+10]]:43: error: requirement `Get` of template constraint `HasGet` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Bound[T: K](x: T) -> i32 { return Take(x.Get); }
// CHECK:STDERR:                                           ^~~~~
// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE-28]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE-20]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn Bound[T: K](x: T) -> i32 { return Take(x.Get); }

// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE+10]]:51: error: requirement `Get` of template constraint `HasGet` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn BoundInTuple[T: K](x: T) -> i32 { return Take((x.Get, 1)); }
// CHECK:STDERR:                                                   ^~~~~
// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE-40]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE-32]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn BoundInTuple[T: K](x: T) -> i32 { return Take((x.Get, 1)); }

// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE+10]]:57: error: requirement `Get` of template constraint `HasGet` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn BoundInStruct[T: K](x: T) -> i32 { return Take({.a = x.Get}); }
// CHECK:STDERR:                                                         ^~~~~
// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE-52]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_checked_binding_as_value.carbon:[[@LINE-44]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn BoundInStruct[T: K](x: T) -> i32 { return Take({.a = x.Get}); }

// --- fail_requirement_through_template_instantiation.carbon
library "[[@TEST_NAME]]";

// A template's member access on its type parameter is replayed at
// instantiation; with a facet type as the argument, `T.N` names the requirement
// with no self type, as `HasN.N` does, and has the same concrete type. Each
// value use is then rejected where the template converts it (D-SC-20 as
// amended at fill round 5, review 1 findings BLOCKER-1 and MAJOR-2: a tuple or
// struct holding it checked clean and aborted lowering, and a discarded one was
// accepted). The same templates instantiated with a class are
// lower/testdata/template/template_constraint.carbon,
// `requirement_through_template_instantiation`.
template constraint HasN {
  fn N() -> i32;
}

template constraint HasGet {
  fn Get(self) -> i32;
}

interface J {}

fn Take[T: type](unused f: T) -> i32 { return 1; }

fn Tuple(template T: type) -> i32 { return Take((T.N, 1)); }
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+11]]:31: error: unable to monomorphize specific `Tuple(HasN)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseTuple() -> i32 { return Tuple(HasN); }
// CHECK:STDERR:                               ^~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-16]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-10]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn UseTuple() -> i32 { return Tuple(HasN); }

fn Struct(template T: type) -> i32 { return Take({.f = T.N}); }
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+11]]:32: error: unable to monomorphize specific `Struct(HasN)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseStruct() -> i32 { return Struct(HasN); }
// CHECK:STDERR:                                ^~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-30]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-24]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn UseStruct() -> i32 { return Struct(HasN); }

fn Nested(template T: type) -> i32 {
  return Take({.a = 1, .b = ((T.N, 1), 2)});
}
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+11]]:32: error: unable to monomorphize specific `Nested(HasN)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseNested() -> i32 { return Nested(HasN); }
// CHECK:STDERR:                                ^~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-46]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-40]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn UseNested() -> i32 { return Nested(HasN); }

fn IfTuple(template T: type) -> i32 {
  return Take(if true then (T.N, 1) else (T.N, 2));
}
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+20]]:33: error: unable to monomorphize specific `IfTuple(HasN)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseIfTuple() -> i32 { return IfTuple(HasN); }
// CHECK:STDERR:                                 ^~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-5]]:28: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR:   return Take(if true then (T.N, 1) else (T.N, 2));
// CHECK:STDERR:                            ^~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-64]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+10]]:33: error: unable to monomorphize specific `IfTuple(HasN)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseIfTuple() -> i32 { return IfTuple(HasN); }
// CHECK:STDERR:                                 ^~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-15]]:42: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR:   return Take(if true then (T.N, 1) else (T.N, 2));
// CHECK:STDERR:                                          ^~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-74]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn UseIfTuple() -> i32 { return IfTuple(HasN); }

fn LetTuple(template T: type) -> i32 {
  let unused t: (typeof(T.N), i32) = (T.N, 1);
  return 0;
}
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+10]]:34: error: unable to monomorphize specific `LetTuple(HasN)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseLetTuple() -> i32 { return LetTuple(HasN); }
// CHECK:STDERR:                                  ^~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-6]]:38: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR:   let unused t: (typeof(T.N), i32) = (T.N, 1);
// CHECK:STDERR:                                      ^~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-90]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn UseLetTuple() -> i32 { return LetTuple(HasN); }

fn MethodTuple(template T: type) -> i32 { return Take((T.Get, 1)); }
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+11]]:37: error: unable to monomorphize specific `MethodTuple(J & HasGet)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseMethodTuple() -> i32 { return MethodTuple(HasGet & J); }
// CHECK:STDERR:                                     ^~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon: note: requirement `Get` of template constraint `HasGet` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-97]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-95]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn UseMethodTuple() -> i32 { return MethodTuple(HasGet & J); }

fn Discard(template T: type) -> i32 {
  T.N;
  return 0;
}
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+10]]:33: error: unable to monomorphize specific `Discard(HasN)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseDiscard() -> i32 { return Discard(HasN); }
// CHECK:STDERR:                                 ^~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-6]]:3: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR:   T.N;
// CHECK:STDERR:   ^~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-120]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn UseDiscard() -> i32 { return Discard(HasN); }

fn DiscardTuple(template T: type) -> i32 {
  (T.N, 1);
  return 0;
}
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+10]]:38: error: unable to monomorphize specific `DiscardTuple(HasN)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseDiscardTuple() -> i32 { return DiscardTuple(HasN); }
// CHECK:STDERR:                                      ^~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-6]]:3: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR:   (T.N, 1);
// CHECK:STDERR:   ^~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-136]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn UseDiscardTuple() -> i32 { return DiscardTuple(HasN); }

fn DiscardStruct(template T: type) -> i32 {
  {.a = T.N};
  return 0;
}
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+10]]:39: error: unable to monomorphize specific `DiscardStruct(HasN)` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseDiscardStruct() -> i32 { return DiscardStruct(HasN); }
// CHECK:STDERR:                                       ^~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-6]]:3: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR:   {.a = T.N};
// CHECK:STDERR:   ^~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-152]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn UseDiscardStruct() -> i32 { return DiscardStruct(HasN); }

class Box(template FT: type) {
  fn F() -> i32 { return Take((FT.N, 1)); }
}
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE+11]]:29: error: unable to monomorphize specific `F()` [ResolvingSpecificHere]
// CHECK:STDERR: fn UseBox() -> i32 { return Box(HasN).F(); }
// CHECK:STDERR:                             ^~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-165]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_through_template_instantiation.carbon:[[@LINE-159]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn UseBox() -> i32 { return Box(HasN).F(); }

// --- fail_requirement_typeof_value.carbon
library "[[@TEST_NAME]]";

// `typeof` of a requirement named with no self type is its concrete type
// (D-SC-20 as amended at fill round 5, review 1 finding BLOCKER-2 and review 2
// finding BLOCKER-1: the type was `.Self`-symbolic, and a parameter of it
// aborted lowering). The type has no values: a parameter, a field read and a
// return of it are value uses, rejected as above. Uses of the type itself are
// template_constraint_compound_access.carbon, `requirement_typeof`.
template constraint HasN {
  fn N() -> i32;
}

fn Take[T: type](unused f: T) -> i32 { return 1; }

// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+7]]:17: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Param(unused f: typeof(HasN.N)) {}
// CHECK:STDERR:                 ^~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-8]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn Param(unused f: typeof(HasN.N)) {}

class W {
  var f: typeof(HasN.N);
}

// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+7]]:37: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Field(w: W) -> i32 { return Take(w.f); }
// CHECK:STDERR:                                     ^~~
// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-21]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn Field(w: W) -> i32 { return Take(w.f); }

// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+7]]:40: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Return() -> typeof(HasN.N) { return HasN.N; }
// CHECK:STDERR:                                        ^~~~~~
// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-30]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn Return() -> typeof(HasN.N) { return HasN.N; }

impl W as Core.UnformedInit {}

fn Ref(unused ref f: typeof(HasN.N)) {}

// A field reached through a `var` is a reference: bound to a `ref` parameter it
// reads no value and is accepted (D-SC-20 as amended at fill round 6, both
// reviews' finding MAJOR-1); read as a value it is refused, and so is a
// requirement name, `ref`-tagged or not. Uses of such an object are lower
// `requirement_typeof_object`.
fn ReadField() {
  var w: W;
  Ref(ref w.f);
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+7]]:34: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR:   let unused v: typeof(HasN.N) = w.f;
  // CHECK:STDERR:                                  ^~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-51]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn N() -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  let unused v: typeof(HasN.N) = w.f;
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+10]]:7: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR:   Ref(ref HasN.N);
  // CHECK:STDERR:       ^~~~~~~~~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-59]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn N() -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-24]]:15: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: fn Ref(unused ref f: typeof(HasN.N)) {}
  // CHECK:STDERR:               ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  Ref(ref HasN.N);
}

// The type under `const`, or as an array's element, is held as a tuple's or a
// struct's element is: a value of it is refused, a pointer to it is not
// (D-SC-20 as amended at fill round 7, round 6's review 1 finding MAJOR-1).
class V {
  var f: typeof(HasN.N);
  var a: array(typeof(HasN.N), 2);
}

impl V as Core.UnformedInit {}

// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+7]]:22: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn ConstParam(unused v: const typeof(HasN.N)) {}
// CHECK:STDERR:                      ^~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-82]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn ConstParam(unused v: const typeof(HasN.N)) {}

fn ConstPointer() -> i32 {
  var v: V;
  let p: const typeof(HasN.N)* = &v.f;
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+10]]:15: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR:   return Take(*p);
  // CHECK:STDERR:               ^~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-94]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn N() -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-94]]:25: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
  // CHECK:STDERR:                         ^~~~
  // CHECK:STDERR:
  return Take(*p);
}

fn ArrayLet() {
  var v: V;
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+7]]:44: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR:   let unused a: array(typeof(HasN.N), 2) = v.a;
  // CHECK:STDERR:                                            ^~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-109]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn N() -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  let unused a: array(typeof(HasN.N), 2) = v.a;
}

fn ArrayArg() -> i32 {
  var v: V;
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+10]]:15: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR:   return Take(v.a);
  // CHECK:STDERR:               ^~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-121]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn N() -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-121]]:25: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
  // CHECK:STDERR:                         ^~~~
  // CHECK:STDERR:
  return Take(v.a);
}

// A class value is accepted: it is not converted field by field. A field
// accessed through it is read as a value (member_access.cpp acquires the value
// of a class value's field), so a field that is or holds a requirement's type,
// a tuple or struct field read only for its other element included, is reached
// through a reference to the object, as in `GetRef` (D-SC-20 as amended at fill
// round 7, round 6's review 2 finding MAJOR-1).
class E {
  var t: (typeof(HasN.N), i32);
  var s: {.f: typeof(HasN.N), .x: i32};
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+7]]:32: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR:   fn Get(self) -> i32 { return self.t.1; }
  // CHECK:STDERR:                                ^~~~~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-143]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn N() -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn Get(self) -> i32 { return self.t.1; }
  fn GetRef(ref self) -> i32 { return self.t.1 + self.s.x; }
}

// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+7]]:38: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn StructField(e: E) -> i32 { return e.s.x; }
// CHECK:STDERR:                                      ^~~
// CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-154]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn N() -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn StructField(e: E) -> i32 { return e.s.x; }

// A `var` parameter's storage is a reference, so its declaration is accepted;
// a call initializes it from a value, which is refused (round 6's review 2
// finding MINOR-1).
fn VarParam(var x: typeof(HasN.N)) { Ref(ref x); }

fn CallVarParam() {
  var w: W;
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+10]]:12: error: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR:   VarParam(w.f);
  // CHECK:STDERR:            ^~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-170]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn N() -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-10]]:13: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: fn VarParam(var x: typeof(HasN.N)) { Ref(ref x); }
  // CHECK:STDERR:             ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  VarParam(w.f);
}

// A template's call argument typed by its parameter is replayed at
// instantiation and refused (round 6's review 1 finding MINOR-1); a `let` typed
// by the parameter records no action and is accepted (lower
// `requirement_typeof_object`, `LetValue`).
fn TemplateDeref[template U: type](p: U*) -> i32 { return Take(*p); }

fn UseTemplateDeref() -> i32 {
  var w: W;
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE+13]]:10: error: unable to monomorphize specific `TemplateDeref(<type of HasN.N>)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return TemplateDeref(&w.f);
  // CHECK:STDERR:          ^~~~~~~~~~~~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-7]]:64: note: requirement `N` of template constraint `HasN` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR: fn TemplateDeref[template U: type](p: U*) -> i32 { return Take(*p); }
  // CHECK:STDERR:                                                                ^~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-194]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn N() -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_requirement_typeof_value.carbon:[[@LINE-194]]:25: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
  // CHECK:STDERR:                         ^~~~
  // CHECK:STDERR:
  return TemplateDeref(&w.f);
}

// --- fail_nested_requirement_as_value.carbon
library "[[@TEST_NAME]]";

// A template constraint declared in a template constraint has the outer
// constraint's checked-phase `Self` among its arguments, so its requirement
// named with no self type is a value of a type symbolic in that `Self`, refused
// as `HasN.N` is (D-SC-10 as amended at fill round 7, round 6's review 1
// finding BLOCKER-1: with a template-phase `Self` each use was
// template-dependent, checked clean and aborted lowering or ran).
template constraint Outer {
  template constraint Inner {
    fn N() -> i32;
  }
}

fn Take[T: type](unused f: T) -> i32 { return 1; }

fn Init() {
  // CHECK:STDERR: fail_nested_requirement_as_value.carbon:[[@LINE+7]]:23: error: requirement `N` of template constraint `Inner` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR:   let unused x: i32 = Outer.Inner.N;
  // CHECK:STDERR:                       ^~~~~~~~~~~~~
  // CHECK:STDERR: fail_nested_requirement_as_value.carbon:[[@LINE-10]]:5: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:     fn N() -> i32;
  // CHECK:STDERR:     ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  let unused x: i32 = Outer.Inner.N;
}

// CHECK:STDERR: fail_nested_requirement_as_value.carbon:[[@LINE+7]]:18: error: requirement `N` of template constraint `Inner` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Statement() { Outer.Inner.N; }
// CHECK:STDERR:                  ^~~~~~~~~~~~~
// CHECK:STDERR: fail_nested_requirement_as_value.carbon:[[@LINE-20]]:5: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:     fn N() -> i32;
// CHECK:STDERR:     ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn Statement() { Outer.Inner.N; }

// CHECK:STDERR: fail_nested_requirement_as_value.carbon:[[@LINE+7]]:27: error: requirement `N` of template constraint `Inner` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Call() -> i32 { return Outer.Inner.N(); }
// CHECK:STDERR:                           ^~~~~~~~~~~~~~~
// CHECK:STDERR: fail_nested_requirement_as_value.carbon:[[@LINE-29]]:5: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:     fn N() -> i32;
// CHECK:STDERR:     ^~~~~~~~~~~~~~
// CHECK:STDERR:
fn Call() -> i32 { return Outer.Inner.N(); }

// CHECK:STDERR: fail_nested_requirement_as_value.carbon:[[@LINE+10]]:31: error: requirement `N` of template constraint `Inner` can only be used through a type that satisfies it [StructuralRequirementUsed]
// CHECK:STDERR: fn Arg() -> i32 { return Take(Outer.Inner.N); }
// CHECK:STDERR:                               ^~~~~~~~~~~~~
// CHECK:STDERR: fail_nested_requirement_as_value.carbon:[[@LINE-38]]:5: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:     fn N() -> i32;
// CHECK:STDERR:     ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_nested_requirement_as_value.carbon:[[@LINE-37]]:25: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn Take[T: type](unused f: T) -> i32 { return 1; }
// CHECK:STDERR:                         ^~~~
// CHECK:STDERR:
fn Arg() -> i32 { return Take(Outer.Inner.N); }

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
