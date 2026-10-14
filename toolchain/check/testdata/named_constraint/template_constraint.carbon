// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint.carbon

// --- decl.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// A `template constraint` declares structural member requirements: a method
// requirement and an associated-function requirement (fork decision F-010 /
// SC-1, D-SC-1, D-SC-2). `Self` is a checked-phase binding here, as in a
// `constraint` (D-SC-10 as amended at fill round 7).
template constraint HasGet {
  fn Get(self) -> i32;
  fn Make() -> Self;
}

// --- forward.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// A forward declaration and its definition agree on `template` (D-SC-16).
template constraint F;

template constraint F {
  fn G(ref self);
}

// --- compose.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// Nominal requirements still compose with structural ones.
template constraint Both {
  fn Get(self) -> i32;
  require impls Core.Destroy;
}

// --- generic.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// A generic template constraint: the with-self generic is over `(T, Self)`.
template constraint Has(T: type) {
  fn Get(self) -> T;
}

// --- fail_self_dependent_name.carbon
library "[[@TEST_NAME]]";

// A name of the body that depends on `Self`, named with no self type, is
// symbolic, as a `constraint`'s is, and is checked where it is used (D-SC-10 as
// amended at fill round 7, round 6's review 1 finding BLOCKER-1: with a
// template-phase `Self` each of these was a template-dependent action that
// non-template code never performs, so check passed and lowering aborted).
template constraint HasN {
  fn N() -> i32;
  alias A = Self;
  class Inner {
    var k: i32;
  }
}

fn AliasOfSelf() {
  // CHECK:STDERR: fail_self_dependent_name.carbon:[[@LINE+7]]:27: error: cannot implicitly convert expression of type `Core.IntLiteral` to `Self*` [ConversionFailure]
  // CHECK:STDERR:   let unused y: HasN.A* = 1;
  // CHECK:STDERR:                           ^
  // CHECK:STDERR: fail_self_dependent_name.carbon:[[@LINE+4]]:27: note: type `Core.IntLiteral` does not implement interface `Core.ImplicitAs(Self*)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let unused y: HasN.A* = 1;
  // CHECK:STDERR:                           ^
  // CHECK:STDERR:
  let unused y: HasN.A* = 1;
}

fn NestedClassAs() {
  // CHECK:STDERR: fail_self_dependent_name.carbon:[[@LINE+14]]:24: error: cannot convert expression of type `Core.IntLiteral` to `Inner` with `as` [ConversionFailure]
  // CHECK:STDERR:   let unused x: bool = 1 as HasN.Inner;
  // CHECK:STDERR:                        ^~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_self_dependent_name.carbon:[[@LINE+11]]:24: note: type `Core.IntLiteral` does not implement interface `Core.As(Inner)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let unused x: bool = 1 as HasN.Inner;
  // CHECK:STDERR:                        ^~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_self_dependent_name.carbon:[[@LINE+7]]:24: error: cannot implicitly convert expression of type `Inner` to `bool` [ConversionFailure]
  // CHECK:STDERR:   let unused x: bool = 1 as HasN.Inner;
  // CHECK:STDERR:                        ^~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_self_dependent_name.carbon:[[@LINE+4]]:24: note: type `Inner` does not implement interface `Core.ImplicitAs(bool)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let unused x: bool = 1 as HasN.Inner;
  // CHECK:STDERR:                        ^~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let unused x: bool = 1 as HasN.Inner;
}

fn NestedClassPointer() {
  // CHECK:STDERR: fail_self_dependent_name.carbon:[[@LINE+7]]:31: error: cannot implicitly convert expression of type `Core.IntLiteral` to `Inner*` [ConversionFailure]
  // CHECK:STDERR:   let unused y: HasN.Inner* = 1;
  // CHECK:STDERR:                               ^
  // CHECK:STDERR: fail_self_dependent_name.carbon:[[@LINE+4]]:31: note: type `Core.IntLiteral` does not implement interface `Core.ImplicitAs(Inner*)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   let unused y: HasN.Inner* = 1;
  // CHECK:STDERR:                               ^
  // CHECK:STDERR:
  let unused y: HasN.Inner* = 1;
}

// --- nested_class.carbon
library "[[@TEST_NAME]]";

// A class declared in a template constraint is not a requirement, and its
// member is called as a `constraint`'s nested class's member is (D-SC-10 as
// amended at fill round 7). Lowering the call aborts at sem_ir/mangler.cpp:185,
// as it does for a `constraint` on trunk 0bdce60a5.
template constraint Outer {
  class Inner {
    fn N() -> i32 { return 1; }
  }
}

fn F() -> i32 { return Outer.Inner.N(); }

// --- fail_todo_self_member_in_signature.carbon
library "[[@TEST_NAME]]";

// A requirement's signature is checked at the definition as an interface
// member's is (D-SC-10 as amended at fill rounds 7 and 8), so a member access
// into the constraint's own `Self`, of a requirement or of an alias, is
// upstream's "member access into facet of incomplete type", as `Self.U2` is in
// an interface being defined (trunk 0bdce60a5,
// impl/use_assoc_entity.carbon `fail_todo_self_period_associated_type`).
// Through fill round 6 the template-phase `Self` deferred the access, and `C`
// below satisfied `HasNM`; the template phase is SC-B2's (W-028), and the shape
// is filed as W-169 (round 7's review 2 finding MAJOR-1). `C`'s use fails with
// no diagnostic of its own, the requirement's error having been reported at
// its declaration (D-SC-9 as amended at fill round 9). The unqualified alias,
// `-> A`, is accepted (`Get2`).
template constraint HasNM {
  fn N() -> i32;
  // CHECK:STDERR: fail_todo_self_member_in_signature.carbon:[[@LINE+7]]:18: error: member access into facet of incomplete type `HasNM` [IncompleteTypeInMemberAccessOfFacet]
  // CHECK:STDERR:   fn M(p: typeof(Self.N)*) -> i32;
  // CHECK:STDERR:                  ^~~~
  // CHECK:STDERR: fail_todo_self_member_in_signature.carbon:[[@LINE-5]]:1: note: constraint is currently being defined [NamedConstraintIncompleteWithinDefinition]
  // CHECK:STDERR: template constraint HasNM {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn M(p: typeof(Self.N)*) -> i32;
}

template constraint HasA {
  alias A = i32;
  // CHECK:STDERR: fail_todo_self_member_in_signature.carbon:[[@LINE+7]]:19: error: member access into facet of incomplete type `HasA` [IncompleteTypeInMemberAccessOfFacet]
  // CHECK:STDERR:   fn Get(self) -> Self.A;
  // CHECK:STDERR:                   ^~~~
  // CHECK:STDERR: fail_todo_self_member_in_signature.carbon:[[@LINE-5]]:1: note: constraint is currently being defined [NamedConstraintIncompleteWithinDefinition]
  // CHECK:STDERR: template constraint HasA {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn Get(self) -> Self.A;
  fn Get2(self) -> A;
}

class C {
  fn N() -> i32 { return 1; }
  fn M(unused p: typeof(N)*) -> i32 { return 2; }
}

fn CallN[template T: HasNM](unused x: T) -> i32 { return T.N(); }

fn Test(c: C) -> i32 { return CallN(c); }

// --- fail_todo_self_facet_in_signature.carbon
library "[[@TEST_NAME]]";

// A requirement's signature in which `Self` must satisfy a facet type that the
// constraint does not itself require is rejected at the definition, as an
// interface member's is (D-SC-10 as amended at fill round 8, round 7's review 1
// finding MAJOR-1): `Box(Self)` for `class Box(T: J)`, `Self.(J.Elem)`,
// `Core.Slice(Self)` and `Core.Optional(Self)`. Definition-time checking would
// defer each to the satisfying type, and through fill round 6 `C` and `S` below
// satisfied them; they come back with SC-B2's template phase (W-169). Their
// uses fail with no diagnostic of their own, the requirement's error having
// been reported at its declaration (D-SC-9 as amended at fill round 9).
// Requiring the facet type that `Self` must satisfy is the workaround
// (`self_facet_in_signature_required`).
interface J {
  fn K(self) -> i32;
}

class Box(T: J) {
  var k: i32;
}

template constraint HasWrap {
  // CHECK:STDERR: fail_todo_self_facet_in_signature.carbon:[[@LINE+7]]:20: error: cannot convert type `Self` that implements `HasWrap` into type implementing `J` [ConversionFailureFacetToFacet]
  // CHECK:STDERR:   fn Wrap(self) -> Box(Self);
  // CHECK:STDERR:                    ^~~~~~~~~
  // CHECK:STDERR: fail_todo_self_facet_in_signature.carbon:[[@LINE-8]]:11: note: initializing generic parameter `T` declared here [InitializingGenericParam]
  // CHECK:STDERR: class Box(T: J) {
  // CHECK:STDERR:           ^~~~
  // CHECK:STDERR:
  fn Wrap(self) -> Box(Self);
}

interface HasElem {
  let Elem: type;
}

template constraint HasGet {
  // CHECK:STDERR: fail_todo_self_facet_in_signature.carbon:[[@LINE+4]]:19: error: cannot convert type `Self` that implements `HasGet` into type implementing `HasElem` [ConversionFailureFacetToFacet]
  // CHECK:STDERR:   fn Get(self) -> Self.(HasElem.Elem);
  // CHECK:STDERR:                   ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn Get(self) -> Self.(HasElem.Elem);
}

template constraint HasAll {
  fn All(self) -> Core.Slice(Self);
}

template constraint HasNext {
  fn Next(self) -> Core.Optional(Self);
}

class C {
  var v: i32;
  impl as J {
    fn K(self) -> i32 { return self.v; }
  }
  fn Wrap(self) -> Box(C) { return {.k = self.v}; }
  fn Get(self) -> i32 { return self.v; }
}

impl C as HasElem where .Elem = i32 {}

class S {
  impl as Core.Copy {
    fn Op(unused self) -> Self { return {}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
  fn All(self) -> Core.Slice(Self);
  fn Next(self) -> Core.Optional(Self);
}

fn CallWrap[template T: HasWrap](x: T) -> i32 { return x.Wrap().k; }

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn CallAll[template T: HasAll](unused x: T) -> i32 { return 1; }

fn CallNext[template T: HasNext](unused x: T) -> i32 { return 2; }

fn Test(c: C, s: S) -> i32 {
  return CallWrap(c) + CallWrap(c) + CallGet(c) + CallAll(s) + CallNext(s);
}

// --- self_facet_in_signature_required.carbon
library "[[@TEST_NAME]]";

// The workaround for `fail_todo_self_facet_in_signature`: a constraint that
// requires, with `require impls`, the facet type that `Self` must satisfy can
// name it in a signature (fill round 8, round 7's review 1 finding MAJOR-1).
// `Core.Slice(Self)` and `Core.Optional(Self)` need `Core.Copy &
// Core.Destroy`, `Core.Optional` through its blanket `OptionalStorage` impl
// (core/prelude/types/optional.carbon:148), so requiring that restores both
// (fill round 9). An interface on trunk 0bdce60a5 rejects the same signatures
// even with the `require`. A required template constraint does not help, since
// a checked-symbolic self never satisfies one (D-SC-6). A member of an overload
// set constrained by `HasWrap` is probed without diagnostics, so `D`, which
// does not implement `J`, selects the next member (D-SC-12); on fb12f63cb, with
// the template-phase `Self`, `P(d)` was a hard "unable to monomorphize" error
// even with the `require` (fill round 9, round 8's review 1 finding MINOR-2).
interface J {
  fn K(self) -> i32;
}

class Box(T: J) {
  var k: i32;
}

template constraint HasWrap {
  require impls J;
  fn Wrap(self) -> Box(Self);
  fn V(self) -> i32;
}

interface HasElem {
  let Elem: type;
}

template constraint HasGet {
  require impls HasElem;
  fn Get(self) -> Self.(HasElem.Elem);
}

template constraint HasAll {
  require impls Core.Copy & Core.Destroy;
  fn All(self) -> Core.Slice(Self);
}

template constraint HasNext {
  require impls Core.Copy & Core.Destroy;
  fn Next(self) -> Core.Optional(Self);
}

class C {
  var v: i32;
  impl as J {
    fn K(self) -> i32 { return self.v; }
  }
  fn Wrap(self) -> Box(C) { return {.k = self.v}; }
  fn V(self) -> i32 { return self.v; }
  fn Get(self) -> i32 { return self.v; }
}

impl C as HasElem where .Elem = i32 {}

fn CallWrap[template T: HasWrap](x: T) -> i32 { return x.Wrap().k + x.V(); }

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 { return CallWrap(c) + CallGet(c); }

class S {
  impl as Core.Copy {
    fn Op(unused self) -> Self { return {}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
  fn All(self) -> Core.Slice(Self);
  fn Next(self) -> Core.Optional(Self);
}

fn CallAll[template T: HasAll](unused x: T) -> i32 { return 1; }

fn CallNext[template T: HasNext](unused x: T) -> i32 { return 2; }

fn TestSlice(s: S) -> i32 { return CallAll(s) + CallNext(s); }

class D {
  var v: i32;
  fn Wrap(self) -> i32 { return self.v; }
  fn V(self) -> i32 { return self.v; }
}

overload fn P[template T: HasWrap](unused x: T) -> i32 { return 10; }
overload fn P[T: type](unused x: T) -> i32 { return 20; }

fn TestProbe(c: C, d: D) -> i32 { return P(c) + P(d); }

// --- fail_todo_unqualified_requirement_in_signature.carbon
library "[[@TEST_NAME]]";

// A requirement's signature that names another requirement unqualified
// (`typeof(N)`) is accepted at the definition, but it names the requirement's
// own function for the satisfying type, which no member's type is, so a class
// whose members mirror the requirements does not satisfy the constraint (fill
// round 8, round 7's finding MINOR-1 of both reviews; W-169). An interface on
// trunk 0bdce60a5 cannot be implemented with the same signature either.
template constraint HasNM {
  fn N() -> i32;
  fn M(p: typeof(N)*) -> i32;
}

class C {
  fn N() -> i32 { return 1; }
  fn M(unused p: typeof(N)*) -> i32 { return 2; }
}

fn CallN[template T: HasNM](unused x: T) -> i32 { return T.N(); }

// CHECK:STDERR: fail_todo_unqualified_requirement_in_signature.carbon:[[@LINE+13]]:31: error: cannot convert type `C` into type implementing `HasNM` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn Test(c: C) -> i32 { return CallN(c); }
// CHECK:STDERR:                               ^~~~~~~~
// CHECK:STDERR: fail_todo_unqualified_requirement_in_signature.carbon:[[@LINE-8]]:3: note: member `M` of type `C` does not match the signature required by template constraint `HasNM` [StructuralMemberMismatch]
// CHECK:STDERR:   fn M(unused p: typeof(N)*) -> i32 { return 2; }
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_todo_unqualified_requirement_in_signature.carbon:[[@LINE-16]]:3: note: requirement declared here [StructuralRequirementHere]
// CHECK:STDERR:   fn M(p: typeof(N)*) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_todo_unqualified_requirement_in_signature.carbon:[[@LINE-11]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn CallN[template T: HasNM](unused x: T) -> i32 { return T.N(); }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Test(c: C) -> i32 { return CallN(c); }

// CHECK:STDOUT: --- decl.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasGet.type: type = facet_type <@HasGet> [concrete]
// CHECK:STDOUT:   %Self: %HasGet.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Self.as_type: type = facet_access_type %Self [symbolic]
// CHECK:STDOUT:   %pattern_type.9c6: type = pattern_type %Self.as_type [symbolic]
// CHECK:STDOUT:   %self.param_patt: %pattern_type.9c6 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt: %pattern_type.9c6 = wrapper_binding_pattern self, %self.param_patt [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %HasGet.WithSelf.Get.type: type = fn_type @HasGet.WithSelf.Get, @HasGet.WithSelf(%Self) [symbolic]
// CHECK:STDOUT:   %HasGet.WithSelf.Get: %HasGet.WithSelf.Get.type = struct_value () [symbolic]
// CHECK:STDOUT:   %.9e4: Core.Form = init_form %Self.as_type [symbolic]
// CHECK:STDOUT:   %return.param_patt.d28: %pattern_type.9c6 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.c85: %pattern_type.9c6 = return_slot_pattern %return.param_patt.d28, %Self.as_type [symbolic]
// CHECK:STDOUT:   %HasGet.WithSelf.Make.type: type = fn_type @HasGet.WithSelf.Make, @HasGet.WithSelf(%Self) [symbolic]
// CHECK:STDOUT:   %HasGet.WithSelf.Make: %HasGet.WithSelf.Make.type = struct_value () [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .HasGet = %HasGet.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %HasGet.decl: type = constraint_decl @HasGet [concrete = constants.%HasGet.type] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: constraint @HasGet {
// CHECK:STDOUT:   %Self: %HasGet.type = symbolic_binding Self, 0 [symbolic = constants.%Self]
// CHECK:STDOUT:   %HasGet.WithSelf.decl = constraint_with_self_decl @HasGet [concrete]
// CHECK:STDOUT:
// CHECK:STDOUT: !with Self:
// CHECK:STDOUT:   %HasGet.WithSelf.Get.decl: @HasGet.WithSelf.%HasGet.WithSelf.Get.type (%HasGet.WithSelf.Get.type) = fn_decl @HasGet.WithSelf.Get [symbolic = @HasGet.WithSelf.%HasGet.WithSelf.Get (constants.%HasGet.WithSelf.Get)] {
// CHECK:STDOUT:     %self.param_patt.loc9_10.1: @HasGet.WithSelf.Get.%pattern_type (%pattern_type.9c6) = value_param_pattern [symbolic = %self.param_patt.loc9_10.2 (constants.%self.param_patt)]
// CHECK:STDOUT:     %self.patt.loc9_10.1: @HasGet.WithSelf.Get.%pattern_type (%pattern_type.9c6) = wrapper_binding_pattern self, %self.param_patt.loc9_10.1 [symbolic = %self.patt.loc9_10.2 (constants.%self.patt)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9_19: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %self.param: @HasGet.WithSelf.Get.%Self.as_type.loc9_10.1 (%Self.as_type) = value_param call_param0
// CHECK:STDOUT:     %.loc9_10.1: type = splice_block %.loc9_10.2 [symbolic = %Self.as_type.loc9_10.1 (constants.%Self.as_type)] {
// CHECK:STDOUT:       %Self.ref: %HasGet.type = name_ref Self, @HasGet.%Self [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:       %Self.as_type.loc9_10.2: type = facet_access_type %Self.ref [symbolic = %Self.as_type.loc9_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:       %.loc9_10.2: type = converted %Self.ref, %Self.as_type.loc9_10.2 [symbolic = %Self.as_type.loc9_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %self: @HasGet.WithSelf.Get.%Self.as_type.loc9_10.1 (%Self.as_type) = wrapper_binding self, %self.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %HasGet.WithSelf.Make.decl: @HasGet.WithSelf.%HasGet.WithSelf.Make.type (%HasGet.WithSelf.Make.type) = fn_decl @HasGet.WithSelf.Make [symbolic = @HasGet.WithSelf.%HasGet.WithSelf.Make (constants.%HasGet.WithSelf.Make)] {
// CHECK:STDOUT:     %return.param_patt.loc10_16.1: @HasGet.WithSelf.Make.%pattern_type (%pattern_type.9c6) = out_param_pattern [symbolic = %return.param_patt.loc10_16.2 (constants.%return.param_patt.d28)]
// CHECK:STDOUT:     %return.patt.loc10_13.1: @HasGet.WithSelf.Make.%pattern_type (%pattern_type.9c6) = return_slot_pattern %return.param_patt.loc10_16.1, %.loc10_16.2 [symbolic = %return.patt.loc10_13.2 (constants.%return.patt.c85)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Self.ref: %HasGet.type = name_ref Self, @HasGet.%Self [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:     %Self.as_type.loc10_16.2: type = facet_access_type %Self.ref [symbolic = %Self.as_type.loc10_16.1 (constants.%Self.as_type)]
// CHECK:STDOUT:     %.loc10_16.2: type = converted %Self.ref, %Self.as_type.loc10_16.2 [symbolic = %Self.as_type.loc10_16.1 (constants.%Self.as_type)]
// CHECK:STDOUT:     %.loc10_16.3: Core.Form = init_form %.loc10_16.2 [symbolic = %.loc10_16.1 (constants.%.9e4)]
// CHECK:STDOUT:     %return.param: ref @HasGet.WithSelf.Make.%Self.as_type.loc10_16.1 (%Self.as_type) = out_param call_param0
// CHECK:STDOUT:     %return: ref @HasGet.WithSelf.Make.%Self.as_type.loc10_16.1 (%Self.as_type) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = %Self
// CHECK:STDOUT:   .Get = @HasGet.WithSelf.%HasGet.WithSelf.Get.decl
// CHECK:STDOUT:   .Make = @HasGet.WithSelf.%HasGet.WithSelf.Make.decl
// CHECK:STDOUT:
// CHECK:STDOUT: !requires:
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @HasGet.WithSelf.Get(@HasGet.%Self: %HasGet.type) {
// CHECK:STDOUT:   %Self: %HasGet.type = symbolic_binding Self, 0 [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:   %Self.as_type.loc9_10.1: type = facet_access_type %Self [symbolic = %Self.as_type.loc9_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type.loc9_10.1 [symbolic = %pattern_type (constants.%pattern_type.9c6)]
// CHECK:STDOUT:   %self.param_patt.loc9_10.2: @HasGet.WithSelf.Get.%pattern_type (%pattern_type.9c6) = value_param_pattern [symbolic = %self.param_patt.loc9_10.2 (constants.%self.param_patt)]
// CHECK:STDOUT:   %self.patt.loc9_10.2: @HasGet.WithSelf.Get.%pattern_type (%pattern_type.9c6) = wrapper_binding_pattern self, %self.param_patt.loc9_10.2 [symbolic = %self.patt.loc9_10.2 (constants.%self.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @HasGet.WithSelf.Get.%Self.as_type.loc9_10.1 (%Self.as_type)) -> out %return.param: %i32;
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @HasGet.WithSelf.Make(@HasGet.%Self: %HasGet.type) {
// CHECK:STDOUT:   %Self: %HasGet.type = symbolic_binding Self, 0 [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:   %Self.as_type.loc10_16.1: type = facet_access_type %Self [symbolic = %Self.as_type.loc10_16.1 (constants.%Self.as_type)]
// CHECK:STDOUT:   %.loc10_16.1: Core.Form = init_form %Self.as_type.loc10_16.1 [symbolic = %.loc10_16.1 (constants.%.9e4)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type.loc10_16.1 [symbolic = %pattern_type (constants.%pattern_type.9c6)]
// CHECK:STDOUT:   %return.param_patt.loc10_16.2: @HasGet.WithSelf.Make.%pattern_type (%pattern_type.9c6) = out_param_pattern [symbolic = %return.param_patt.loc10_16.2 (constants.%return.param_patt.d28)]
// CHECK:STDOUT:   %return.patt.loc10_13.2: @HasGet.WithSelf.Make.%pattern_type (%pattern_type.9c6) = return_slot_pattern %return.param_patt.loc10_16.2, %Self.as_type.loc10_16.1 [symbolic = %return.patt.loc10_13.2 (constants.%return.patt.c85)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn() -> out %return.param: @HasGet.WithSelf.Make.%Self.as_type.loc10_16.1 (%Self.as_type);
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @HasGet.WithSelf(constants.%Self) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @HasGet.WithSelf.Get(constants.%Self) {
// CHECK:STDOUT:   %Self => constants.%Self
// CHECK:STDOUT:   %Self.as_type.loc9_10.1 => constants.%Self.as_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.9c6
// CHECK:STDOUT:   %self.param_patt.loc9_10.2 => constants.%self.param_patt
// CHECK:STDOUT:   %self.patt.loc9_10.2 => constants.%self.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @HasGet.WithSelf.Make(constants.%Self) {
// CHECK:STDOUT:   %Self => constants.%Self
// CHECK:STDOUT:   %Self.as_type.loc10_16.1 => constants.%Self.as_type
// CHECK:STDOUT:   %.loc10_16.1 => constants.%.9e4
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.9c6
// CHECK:STDOUT:   %return.param_patt.loc10_16.2 => constants.%return.param_patt.d28
// CHECK:STDOUT:   %return.patt.loc10_13.2 => constants.%return.patt.c85
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- forward.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %F.type: type = facet_type <@F> [concrete]
// CHECK:STDOUT:   %Self: %F.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Self.as_type: type = facet_access_type %Self [symbolic]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type [symbolic]
// CHECK:STDOUT:   %self.param_patt: %pattern_type = ref_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt: %pattern_type = wrapper_binding_pattern self, %self.param_patt [symbolic]
// CHECK:STDOUT:   %F.WithSelf.G.type: type = fn_type @F.WithSelf.G, @F.WithSelf(%Self) [symbolic]
// CHECK:STDOUT:   %F.WithSelf.G: %F.WithSelf.G.type = struct_value () [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .F = %F.decl.loc5
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %F.decl.loc5: type = constraint_decl @F [concrete = constants.%F.type] {} {}
// CHECK:STDOUT:   %F.decl.loc7: type = constraint_decl @F [concrete = constants.%F.type] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: constraint @F {
// CHECK:STDOUT:   %Self: %F.type = symbolic_binding Self, 0 [symbolic = constants.%Self]
// CHECK:STDOUT:   %F.WithSelf.decl = constraint_with_self_decl @F [concrete]
// CHECK:STDOUT:
// CHECK:STDOUT: !with Self:
// CHECK:STDOUT:   %F.WithSelf.G.decl: @F.WithSelf.%F.WithSelf.G.type (%F.WithSelf.G.type) = fn_decl @F.WithSelf.G [symbolic = @F.WithSelf.%F.WithSelf.G (constants.%F.WithSelf.G)] {
// CHECK:STDOUT:     %self.param_patt.loc8_12.1: @F.WithSelf.G.%pattern_type (%pattern_type) = ref_param_pattern [symbolic = %self.param_patt.loc8_12.2 (constants.%self.param_patt)]
// CHECK:STDOUT:     %self.patt.loc8_12.1: @F.WithSelf.G.%pattern_type (%pattern_type) = wrapper_binding_pattern self, %self.param_patt.loc8_12.1 [symbolic = %self.patt.loc8_12.2 (constants.%self.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref @F.WithSelf.G.%Self.as_type.loc8_12.1 (%Self.as_type) = ref_param call_param0
// CHECK:STDOUT:     %.loc8_12.1: type = splice_block %.loc8_12.2 [symbolic = %Self.as_type.loc8_12.1 (constants.%Self.as_type)] {
// CHECK:STDOUT:       %Self.ref: %F.type = name_ref Self, @F.%Self [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:       %Self.as_type.loc8_12.2: type = facet_access_type %Self.ref [symbolic = %Self.as_type.loc8_12.1 (constants.%Self.as_type)]
// CHECK:STDOUT:       %.loc8_12.2: type = converted %Self.ref, %Self.as_type.loc8_12.2 [symbolic = %Self.as_type.loc8_12.1 (constants.%Self.as_type)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %self: ref @F.WithSelf.G.%Self.as_type.loc8_12.1 (%Self.as_type) = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = %Self
// CHECK:STDOUT:   .G = @F.WithSelf.%F.WithSelf.G.decl
// CHECK:STDOUT:
// CHECK:STDOUT: !requires:
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F.WithSelf.G(@F.%Self: %F.type) {
// CHECK:STDOUT:   %Self: %F.type = symbolic_binding Self, 0 [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:   %Self.as_type.loc8_12.1: type = facet_access_type %Self [symbolic = %Self.as_type.loc8_12.1 (constants.%Self.as_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type.loc8_12.1 [symbolic = %pattern_type (constants.%pattern_type)]
// CHECK:STDOUT:   %self.param_patt.loc8_12.2: @F.WithSelf.G.%pattern_type (%pattern_type) = ref_param_pattern [symbolic = %self.param_patt.loc8_12.2 (constants.%self.param_patt)]
// CHECK:STDOUT:   %self.patt.loc8_12.2: @F.WithSelf.G.%pattern_type (%pattern_type) = wrapper_binding_pattern self, %self.param_patt.loc8_12.2 [symbolic = %self.patt.loc8_12.2 (constants.%self.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: ref @F.WithSelf.G.%Self.as_type.loc8_12.1 (%Self.as_type));
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F.WithSelf(constants.%Self) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F.WithSelf.G(constants.%Self) {
// CHECK:STDOUT:   %Self => constants.%Self
// CHECK:STDOUT:   %Self.as_type.loc8_12.1 => constants.%Self.as_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type
// CHECK:STDOUT:   %self.param_patt.loc8_12.2 => constants.%self.param_patt
// CHECK:STDOUT:   %self.patt.loc8_12.2 => constants.%self.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- compose.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Both.type: type = facet_type <@Both> [concrete]
// CHECK:STDOUT:   %Self.d87: %Both.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Self.as_type.138: type = facet_access_type %Self.d87 [symbolic]
// CHECK:STDOUT:   %pattern_type.9c6: type = pattern_type %Self.as_type.138 [symbolic]
// CHECK:STDOUT:   %self.param_patt.491: %pattern_type.9c6 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt.118: %pattern_type.9c6 = wrapper_binding_pattern self, %self.param_patt.491 [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete]
// CHECK:STDOUT:   %Both.WithSelf.Get.type: type = fn_type @Both.WithSelf.Get, @Both.WithSelf(%Self.d87) [symbolic]
// CHECK:STDOUT:   %Both.WithSelf.Get: %Both.WithSelf.Get.type = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .Both = %Both.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %Both.decl: type = constraint_decl @Both [concrete = constants.%Both.type] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: constraint @Both {
// CHECK:STDOUT:   %Self: %Both.type = symbolic_binding Self, 0 [symbolic = constants.%Self.d87]
// CHECK:STDOUT:   %Both.WithSelf.decl = constraint_with_self_decl @Both [concrete]
// CHECK:STDOUT:
// CHECK:STDOUT: !with Self:
// CHECK:STDOUT:   %Both.WithSelf.Get.decl: @Both.WithSelf.%Both.WithSelf.Get.type (%Both.WithSelf.Get.type) = fn_decl @Both.WithSelf.Get [symbolic = @Both.WithSelf.%Both.WithSelf.Get (constants.%Both.WithSelf.Get)] {
// CHECK:STDOUT:     %self.param_patt.loc6_10.1: @Both.WithSelf.Get.%pattern_type (%pattern_type.9c6) = value_param_pattern [symbolic = %self.param_patt.loc6_10.2 (constants.%self.param_patt.491)]
// CHECK:STDOUT:     %self.patt.loc6_10.1: @Both.WithSelf.Get.%pattern_type (%pattern_type.9c6) = wrapper_binding_pattern self, %self.param_patt.loc6_10.1 [symbolic = %self.patt.loc6_10.2 (constants.%self.patt.118)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_19: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %self.param: @Both.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type.138) = value_param call_param0
// CHECK:STDOUT:     %.loc6_10.1: type = splice_block %.loc6_10.2 [symbolic = %Self.as_type.loc6_10.1 (constants.%Self.as_type.138)] {
// CHECK:STDOUT:       %Self.ref: %Both.type = name_ref Self, @Both.%Self [symbolic = %Self (constants.%Self.d87)]
// CHECK:STDOUT:       %Self.as_type.loc6_10.2: type = facet_access_type %Self.ref [symbolic = %Self.as_type.loc6_10.1 (constants.%Self.as_type.138)]
// CHECK:STDOUT:       %.loc6_10.2: type = converted %Self.ref, %Self.as_type.loc6_10.2 [symbolic = %Self.as_type.loc6_10.1 (constants.%Self.as_type.138)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %self: @Both.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type.138) = wrapper_binding self, %self.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Both.WithSelf.Self.as_type.impls.Destroy.type.require.decl = require_decl @Both.WithSelf.Self.as_type.impls.Destroy.type.require [concrete] {
// CHECK:STDOUT:     require %Self.as_type.loc7_11.1 impls %Destroy.ref
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Self.as_type.loc7_11.1: type = facet_access_type @Both.%Self [symbolic = %Self.as_type.loc7_11.2 (constants.%Self.as_type.138)]
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   }
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = %Self
// CHECK:STDOUT:   .Get = @Both.WithSelf.%Both.WithSelf.Get.decl
// CHECK:STDOUT:
// CHECK:STDOUT: !requires:
// CHECK:STDOUT:   @Both.WithSelf.Self.as_type.impls.Destroy.type.require {
// CHECK:STDOUT:     require @Both.WithSelf.Self.as_type.impls.Destroy.type.require.%Self.as_type.loc7_11.1 impls @Both.WithSelf.Self.as_type.impls.Destroy.type.require.%Destroy.ref
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic require @Both.WithSelf.Self.as_type.impls.Destroy.type.require(@Both.%Self: %Both.type) {
// CHECK:STDOUT:   %Self: %Both.type = symbolic_binding Self, 0 [symbolic = %Self (constants.%Self.d87)]
// CHECK:STDOUT:   %Self.as_type.loc7_11.2: type = facet_access_type %Self [symbolic = %Self.as_type.loc7_11.2 (constants.%Self.as_type.138)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Both.WithSelf.Get(@Both.%Self: %Both.type) {
// CHECK:STDOUT:   %Self: %Both.type = symbolic_binding Self, 0 [symbolic = %Self (constants.%Self.d87)]
// CHECK:STDOUT:   %Self.as_type.loc6_10.1: type = facet_access_type %Self [symbolic = %Self.as_type.loc6_10.1 (constants.%Self.as_type.138)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Self.as_type.loc6_10.1 [symbolic = %pattern_type (constants.%pattern_type.9c6)]
// CHECK:STDOUT:   %self.param_patt.loc6_10.2: @Both.WithSelf.Get.%pattern_type (%pattern_type.9c6) = value_param_pattern [symbolic = %self.param_patt.loc6_10.2 (constants.%self.param_patt.491)]
// CHECK:STDOUT:   %self.patt.loc6_10.2: @Both.WithSelf.Get.%pattern_type (%pattern_type.9c6) = wrapper_binding_pattern self, %self.param_patt.loc6_10.2 [symbolic = %self.patt.loc6_10.2 (constants.%self.patt.118)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @Both.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type.138)) -> out %return.param: %i32;
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Both.WithSelf(constants.%Self.d87) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Both.WithSelf.Get(constants.%Self.d87) {
// CHECK:STDOUT:   %Self => constants.%Self.d87
// CHECK:STDOUT:   %Self.as_type.loc6_10.1 => constants.%Self.as_type.138
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.9c6
// CHECK:STDOUT:   %self.param_patt.loc6_10.2 => constants.%self.param_patt.491
// CHECK:STDOUT:   %self.patt.loc6_10.2 => constants.%self.patt.118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Both.WithSelf.Self.as_type.impls.Destroy.type.require(constants.%Self.d87) {
// CHECK:STDOUT:   %Self => constants.%Self.d87
// CHECK:STDOUT:   %Self.as_type.loc7_11.2 => constants.%Self.as_type.138
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Has.type.9ba: type = generic_named_constaint_type @Has [concrete]
// CHECK:STDOUT:   %empty_struct: %Has.type.9ba = struct_value () [concrete]
// CHECK:STDOUT:   %Has.type.d68: type = facet_type <@Has, @Has(%T)> [symbolic]
// CHECK:STDOUT:   %Self: %Has.type.d68 = symbolic_binding Self, 1 [symbolic]
// CHECK:STDOUT:   %Self.as_type: type = facet_access_type %Self [symbolic]
// CHECK:STDOUT:   %pattern_type.a15: type = pattern_type %Self.as_type [symbolic]
// CHECK:STDOUT:   %self.param_patt: %pattern_type.a15 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt: %pattern_type.a15 = wrapper_binding_pattern self, %self.param_patt [symbolic]
// CHECK:STDOUT:   %.184: Core.Form = init_form %T [symbolic]
// CHECK:STDOUT:   %pattern_type.51d: type = pattern_type %T [symbolic]
// CHECK:STDOUT:   %return.param_patt: %pattern_type.51d = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt: %pattern_type.51d = return_slot_pattern %return.param_patt, %T [symbolic]
// CHECK:STDOUT:   %Has.WithSelf.Get.type: type = fn_type @Has.WithSelf.Get, @Has.WithSelf(%T, %Self) [symbolic]
// CHECK:STDOUT:   %Has.WithSelf.Get: %Has.WithSelf.Get.type = struct_value () [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .Has = %Has.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %Has.decl: %Has.type.9ba = constraint_decl @Has [concrete = constants.%empty_struct] {
// CHECK:STDOUT:     %T.patt.loc5_26.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_26.2 (constants.%T.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5_28.1: type = splice_block %.loc5_28.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc5_28.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc5_26.2: type = symbolic_binding T, 0 [symbolic = %T.loc5_26.1 (constants.%T)]
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic constraint @Has(%T.loc5_26.2: type) {
// CHECK:STDOUT:   %T.patt.loc5_26.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_26.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc5_26.1: type = symbolic_binding T, 0 [symbolic = %T.loc5_26.1 (constants.%T)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %Has.type: type = facet_type <@Has, @Has(%T.loc5_26.1)> [symbolic = %Has.type (constants.%Has.type.d68)]
// CHECK:STDOUT:   %Self.loc5_34.2: @Has.%Has.type (%Has.type.d68) = symbolic_binding Self, 1 [symbolic = %Self.loc5_34.2 (constants.%Self)]
// CHECK:STDOUT:
// CHECK:STDOUT:   constraint {
// CHECK:STDOUT:     %Self.loc5_34.1: @Has.%Has.type (%Has.type.d68) = symbolic_binding Self, 1 [symbolic = %Self.loc5_34.2 (constants.%Self)]
// CHECK:STDOUT:     %Has.WithSelf.decl = constraint_with_self_decl @Has [concrete]
// CHECK:STDOUT:
// CHECK:STDOUT:   !with Self:
// CHECK:STDOUT:     %Has.WithSelf.Get.decl: @Has.WithSelf.%Has.WithSelf.Get.type (%Has.WithSelf.Get.type) = fn_decl @Has.WithSelf.Get [symbolic = @Has.WithSelf.%Has.WithSelf.Get (constants.%Has.WithSelf.Get)] {
// CHECK:STDOUT:       %self.param_patt.loc6_10.1: @Has.WithSelf.Get.%pattern_type.loc6_10 (%pattern_type.a15) = value_param_pattern [symbolic = %self.param_patt.loc6_10.2 (constants.%self.param_patt)]
// CHECK:STDOUT:       %self.patt.loc6_10.1: @Has.WithSelf.Get.%pattern_type.loc6_10 (%pattern_type.a15) = wrapper_binding_pattern self, %self.param_patt.loc6_10.1 [symbolic = %self.patt.loc6_10.2 (constants.%self.patt)]
// CHECK:STDOUT:       %return.param_patt.loc6_19.1: @Has.WithSelf.Get.%pattern_type.loc6_19 (%pattern_type.51d) = out_param_pattern [symbolic = %return.param_patt.loc6_19.2 (constants.%return.param_patt)]
// CHECK:STDOUT:       %return.patt.loc6_16.1: @Has.WithSelf.Get.%pattern_type.loc6_19 (%pattern_type.51d) = return_slot_pattern %return.param_patt.loc6_19.1, %T.ref [symbolic = %return.patt.loc6_16.2 (constants.%return.patt)]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %T.ref: type = name_ref T, @Has.%T.loc5_26.2 [symbolic = %T (constants.%T)]
// CHECK:STDOUT:       %.loc6_19.2: Core.Form = init_form %T.ref [symbolic = %.loc6_19.1 (constants.%.184)]
// CHECK:STDOUT:       %self.param: @Has.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type) = value_param call_param0
// CHECK:STDOUT:       %.loc6_10.1: type = splice_block %.loc6_10.3 [symbolic = %Self.as_type.loc6_10.1 (constants.%Self.as_type)] {
// CHECK:STDOUT:         %.loc6_10.2: @Has.WithSelf.Get.%Has.type (%Has.type.d68) = specific_constant @Has.%Self.loc5_34.1, @Has(constants.%T) [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:         %Self.ref: @Has.WithSelf.Get.%Has.type (%Has.type.d68) = name_ref Self, %.loc6_10.2 [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:         %Self.as_type.loc6_10.2: type = facet_access_type %Self.ref [symbolic = %Self.as_type.loc6_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:         %.loc6_10.3: type = converted %Self.ref, %Self.as_type.loc6_10.2 [symbolic = %Self.as_type.loc6_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %self: @Has.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %return.param: ref @Has.WithSelf.Get.%T (%T) = out_param call_param1
// CHECK:STDOUT:       %return: ref @Has.WithSelf.Get.%T (%T) = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = %Self.loc5_34.1
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Get = @Has.WithSelf.%Has.WithSelf.Get.decl
// CHECK:STDOUT:
// CHECK:STDOUT:   !requires:
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Has.WithSelf.Get(@Has.%T.loc5_26.2: type, @Has.%Self.loc5_34.1: @Has.%Has.type (%Has.type.d68)) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T)]
// CHECK:STDOUT:   %Has.type: type = facet_type <@Has, @Has(%T)> [symbolic = %Has.type (constants.%Has.type.d68)]
// CHECK:STDOUT:   %Self: @Has.WithSelf.Get.%Has.type (%Has.type.d68) = symbolic_binding Self, 1 [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:   %Self.as_type.loc6_10.1: type = facet_access_type %Self [symbolic = %Self.as_type.loc6_10.1 (constants.%Self.as_type)]
// CHECK:STDOUT:   %pattern_type.loc6_10: type = pattern_type %Self.as_type.loc6_10.1 [symbolic = %pattern_type.loc6_10 (constants.%pattern_type.a15)]
// CHECK:STDOUT:   %self.param_patt.loc6_10.2: @Has.WithSelf.Get.%pattern_type.loc6_10 (%pattern_type.a15) = value_param_pattern [symbolic = %self.param_patt.loc6_10.2 (constants.%self.param_patt)]
// CHECK:STDOUT:   %self.patt.loc6_10.2: @Has.WithSelf.Get.%pattern_type.loc6_10 (%pattern_type.a15) = wrapper_binding_pattern self, %self.param_patt.loc6_10.2 [symbolic = %self.patt.loc6_10.2 (constants.%self.patt)]
// CHECK:STDOUT:   %.loc6_19.1: Core.Form = init_form %T [symbolic = %.loc6_19.1 (constants.%.184)]
// CHECK:STDOUT:   %pattern_type.loc6_19: type = pattern_type %T [symbolic = %pattern_type.loc6_19 (constants.%pattern_type.51d)]
// CHECK:STDOUT:   %return.param_patt.loc6_19.2: @Has.WithSelf.Get.%pattern_type.loc6_19 (%pattern_type.51d) = out_param_pattern [symbolic = %return.param_patt.loc6_19.2 (constants.%return.param_patt)]
// CHECK:STDOUT:   %return.patt.loc6_16.2: @Has.WithSelf.Get.%pattern_type.loc6_19 (%pattern_type.51d) = return_slot_pattern %return.param_patt.loc6_19.2, %T [symbolic = %return.patt.loc6_16.2 (constants.%return.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @Has.WithSelf.Get.%Self.as_type.loc6_10.1 (%Self.as_type)) -> out %return.param: @Has.WithSelf.Get.%T (%T);
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Has(constants.%T) {
// CHECK:STDOUT:   %T.patt.loc5_26.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc5_26.1 => constants.%T
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Has.WithSelf(constants.%T, constants.%Self) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Has.WithSelf.Get(constants.%T, constants.%Self) {
// CHECK:STDOUT:   %T => constants.%T
// CHECK:STDOUT:   %Has.type => constants.%Has.type.d68
// CHECK:STDOUT:   %Self => constants.%Self
// CHECK:STDOUT:   %Self.as_type.loc6_10.1 => constants.%Self.as_type
// CHECK:STDOUT:   %pattern_type.loc6_10 => constants.%pattern_type.a15
// CHECK:STDOUT:   %self.param_patt.loc6_10.2 => constants.%self.param_patt
// CHECK:STDOUT:   %self.patt.loc6_10.2 => constants.%self.patt
// CHECK:STDOUT:   %.loc6_19.1 => constants.%.184
// CHECK:STDOUT:   %pattern_type.loc6_19 => constants.%pattern_type.51d
// CHECK:STDOUT:   %return.param_patt.loc6_19.2 => constants.%return.param_patt
// CHECK:STDOUT:   %return.patt.loc6_16.2 => constants.%return.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
