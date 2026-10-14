// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_require.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_require.carbon

// `require impls` and `template constraint`s (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-8(iii), D-SC-19): nominal and structural
// requirements compose, a concrete `impl` of an interface requiring a template
// constraint is checked at the `require` entry point, and a TEMPLATE blanket
// impl is deferred there.

// --- require_in_template.carbon
library "[[@TEST_NAME]]";

template constraint Both {
  fn Get(self) -> i32;
  require impls Core.Destroy;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
}

fn CallGet[template T: Both](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 { return CallGet(c); }

// --- require_in_interface_concrete.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
}

impl C as I {}

// --- require_in_interface_template_blanket.carbon
library "[[@TEST_NAME]]";

// The template-phase self is deferred at the `require` entry point (D-SC-19),
// and the specific `Lacking as I` resolves through the blanket impl with no
// re-check: this split PINS the SC-1 gap named in D-SC-19 and §1.G.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

impl forall [template T: type] T as I {}

class Lacking {}

fn Use[U: I](unused x: U) {}

fn Test(l: Lacking) { Use(l); }

// --- fail_require_in_interface_concrete_lacking.carbon
library "[[@TEST_NAME]]";

// The negative of `require_in_interface_concrete`: `D` lacks `Get`, so the
// `require` entry point rejects the impl (D-SC-8(iii), kept by fill round 1's
// fix 4; fill round 2, review finding F3).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

class D {}

// CHECK:STDERR: fail_require_in_interface_concrete_lacking.carbon:[[@LINE+4]]:1: error: interface `I` being implemented requires that `D` implements `HasGet` [InterfaceRequireImplsNotImplemented]
// CHECK:STDERR: impl D as I {}
// CHECK:STDERR: ^~~~~~~~~~~~~
// CHECK:STDERR:
impl D as I {}

// --- require_in_constraint.carbon
library "[[@TEST_NAME]]";

// A plain constraint's `require impls` of a template constraint carries the
// structural requirement to a `template` binding of the plain constraint
// (fill round 1, fix 4; fill round 2, review findings F3 / MINOR-4).
template constraint HasGet {
  fn Get(self) -> i32;
}

constraint P {
  require impls HasGet;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
}

fn CallGet[template T: P](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 { return CallGet(c); }

// --- fail_require_in_constraint_unsatisfied.carbon
library "[[@TEST_NAME]]";

// The negative of `require_in_constraint`: `Lacking` converts to `P` only if it
// satisfies `HasGet`, so the call fails with `ConversionFailureTypeToFacet`,
// the `StructuralMemberMissing` note naming `HasGet`,
// `StructuralRequirementHere` and `DeductionGenericHere` (fill round 2, review
// findings F3 / MINOR-4; comment added at fill round 3, review finding F9).
template constraint HasGet {
  fn Get(self) -> i32;
}

constraint P {
  require impls HasGet;
}

class Lacking {}

fn CallGet[template T: P](x: T) -> i32 { return x.Get(); }

fn Test(l: Lacking) -> i32 {
  // CHECK:STDERR: fail_require_in_constraint_unsatisfied.carbon:[[@LINE+13]]:10: error: cannot convert type `Lacking` into type implementing `P` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(l);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_require_in_constraint_unsatisfied.carbon:[[@LINE+10]]:10: note: type `Lacking` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
  // CHECK:STDERR:   return CallGet(l);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_require_in_constraint_unsatisfied.carbon:[[@LINE-18]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_require_in_constraint_unsatisfied.carbon:[[@LINE-12]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: P](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(l);
}

// --- extend_require.carbon
library "[[@TEST_NAME]]";

// `extend require impls HasGet` makes the requirement a member name of the
// extending constraint or interface, and a compound access through it binds
// the type's own `Get` (D-SC-4; fill round 2, review findings F3 / MINOR-4).
template constraint HasGet {
  fn Get(self) -> i32;
}

constraint P {
  extend require impls HasGet;
}

interface I {
  extend require impls HasGet;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
}

impl C as I {}

fn ViaP[template T: P](x: T) -> i32 { return x.(P.Get)(); }

fn ViaI[template T: I](x: T) -> i32 { return x.Get() + x.(I.Get)(); }

fn Test(c: C) -> i32 { return ViaP(c) + ViaI(c) + c.(P.Get)() + c.(I.Get)(); }

// --- require_in_interface_in_class_impl.carbon
library "[[@TEST_NAME]]";

// An impl defined inside the class it implements the interface for: the class
// is incomplete there, so the structural `require` is checked when the class
// completes (D-SC-8(iii), amended at fill round 2, review finding MAJOR-3). The
// interface `J` that the same `require` names is checked at the impl, as a
// nominal `require` is, so `extend impl as J` comes first (amended at fill
// round 3, review findings MINOR-2 / F1; the other order is
// `fail_require_mixed_in_class_impl_order`).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface J {
  fn Three(self) -> i32;
}

interface I {
  require impls HasGet & J;
  fn Twice(self) -> i32;
}

interface K {
  extend require impls HasGet;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
  extend impl as J {
    fn Three(unused self) -> i32 { return 3; }
  }
  impl as I {
    fn Twice(self) -> i32 { return self.Get() * 2; }
  }
  extend impl as K {}
}

fn Test(c: C) -> i32 { return c.(I.Twice)() + c.(K.Get)(); }

// --- fail_require_in_interface_in_class_impl_lacking.carbon
library "[[@TEST_NAME]]";

// The negative: `Lacking` has no `Get` when it completes.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

class Lacking {
  // CHECK:STDERR: fail_require_in_interface_in_class_impl_lacking.carbon:[[@LINE+4]]:3: error: interface `I` being implemented requires that `Lacking` implements `HasGet` [InterfaceRequireImplsNotImplemented]
  // CHECK:STDERR:   impl as I {}
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  impl as I {}
}

// --- require_in_interface_in_union_impl.carbon
library "[[@TEST_NAME]]";

// A union is a class (D-SC-12): an impl inside a union body is checked when the
// union's definition ends, as an in-class impl is at its class's end
// (D-SC-8(iii), amended at fill round 4, review findings MAJOR-1 of both
// reviews: the union's end never checked it, and the program ran).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
  fn F(self) -> i32;
}

union U {
  var a: i32;
  var b: i32;
  impl as I {
    fn F(self) -> i32 { return self.Get(); }
  }
  fn Get(unused self) -> i32 { return 5; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(u: U) -> i32 { return u.(I.F)() + CallGet(u); }

// --- fail_require_in_interface_in_union_impl_lacking.carbon
library "[[@TEST_NAME]]";

// The negative: neither union has a `Get` when its definition ends. For
// `HasGet & J`, `J` is checked at the impl and `HasGet` at the union's end.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface J {}

interface I {
  require impls HasGet;
}

interface I2 {
  require impls HasGet & J;
}

union Lacking {
  var a: i32;
  // CHECK:STDERR: fail_require_in_interface_in_union_impl_lacking.carbon:[[@LINE+4]]:3: error: interface `I` being implemented requires that `Lacking` implements `HasGet` [InterfaceRequireImplsNotImplemented]
  // CHECK:STDERR:   impl as I {}
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  impl as I {}
}

union LackingMixed {
  var a: i32;
  impl as J {}
  // CHECK:STDERR: fail_require_in_interface_in_union_impl_lacking.carbon:[[@LINE+4]]:3: error: interface `I2` being implemented requires that `LackingMixed` implements `J & HasGet` [InterfaceRequireImplsNotImplemented]
  // CHECK:STDERR:   impl as I2 {}
  // CHECK:STDERR:   ^~~~~~~~~~~~
  // CHECK:STDERR:
  impl as I2 {}
}

// --- fail_require_mixed_in_class_impl_order.carbon
library "[[@TEST_NAME]]";

// The interfaces of a `require` that also names a template constraint are
// checked at the impl, as a nominal `require` is: `impl as J` after `impl as
// I1` is rejected for `HasGet & J` exactly as for `J` alone, and only the
// structural part waits for the class end (D-SC-8(iii), amended at fill round
// 3, review findings MINOR-2 / F1). Expected:
// `InterfaceRequireImplsNotImplemented` at `impl as I1` and at `impl as I2`.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface J {}

interface I1 {
  require impls HasGet & J;
}

interface I2 {
  require impls J;
}

class C {
  fn Get(unused self) -> i32 { return 1; }
  // CHECK:STDERR: fail_require_mixed_in_class_impl_order.carbon:[[@LINE+4]]:3: error: interface `I1` being implemented requires that `C` implements `J & HasGet` [InterfaceRequireImplsNotImplemented]
  // CHECK:STDERR:   impl as I1 {}
  // CHECK:STDERR:   ^~~~~~~~~~~~
  // CHECK:STDERR:
  impl as I1 {}
  // CHECK:STDERR: fail_require_mixed_in_class_impl_order.carbon:[[@LINE+4]]:3: error: interface `I2` being implemented requires that `C` implements `J` [InterfaceRequireImplsNotImplemented]
  // CHECK:STDERR:   impl as I2 {}
  // CHECK:STDERR:   ^~~~~~~~~~~~
  // CHECK:STDERR:
  impl as I2 {}
  impl as J {}
}

// --- require_self_class_being_defined.carbon
library "[[@TEST_NAME]]";

// A structural `require` whose self is a class still being defined waits for
// that class's end, wherever the impl is: an impl in a nested class whose self
// is the enclosing class (its `Get` declared after or before the nested
// class), and an impl of another type whose interface requires the class being
// defined, where the interface `J(D)` the same `require` names is checked at
// the impl and so is implemented first (D-SC-8(iii), amended at fill round 3,
// review findings MINOR-1 and MINOR-2 / F1; `Self` appears in `J(Self)`, as
// upstream requires of a `require` with another self).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

interface J(X: type) {}

interface IU(U: type) {
  require U impls HasGet & J(Self);
}

class Outer {
  class Inner {
    impl Outer as I {}
  }
  fn Get(unused self) -> i32 { return 1; }
}

class Outer2 {
  fn Get(unused self) -> i32 { return 2; }
  class Inner {
    impl Outer2 as I {}
  }
}

class D {}

class F {
  impl as J(D) {}
  impl D as IU(F) {}
  fn Get(unused self) -> i32 { return 3; }
}

// --- fail_require_self_class_being_defined_lacking.carbon
library "[[@TEST_NAME]]";

// The negative: `Lacking` has no `Get` when it completes, so the impl in its
// nested class is rejected then. Expected:
// `InterfaceRequireImplsNotImplemented` at the impl, once.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

class Lacking {
  class Inner {
    // CHECK:STDERR: fail_require_self_class_being_defined_lacking.carbon:[[@LINE+4]]:5: error: interface `I` being implemented requires that `Lacking` implements `HasGet` [InterfaceRequireImplsNotImplemented]
    // CHECK:STDERR:     impl Lacking as I {}
    // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR:
    impl Lacking as I {}
  }
}

// --- require_self_argument.carbon
library "[[@TEST_NAME]]";

// A `require` whose facet type takes `Self` as an argument, an interface's or a
// template constraint's, composes as in any named constraint (the design page,
// "Composing with named-constraint requirements"). Through fill round 6 the
// template-phase `Self` made the facet type a splice and the `require` was
// "constrained by a non-facet type"; the checked-phase `Self` of fill round 7
// accepts it (D-SC-10 as amended at fill round 8, round 7's review 2 finding
// MAJOR-2). A template phase brought back for SC-B2 keeps this split and
// `fail_require_self_argument_unsatisfied` as they are.
interface Conv(T: type) {
  fn Do(self) -> T;
}

template constraint Has(X: type) {
  fn Get(self) -> X;
}

template constraint ConvSelf {
  require Self impls Conv(Self);
  fn V(self) -> i32;
}

template constraint HasSelf {
  require impls Has(Self);
  fn V(self) -> i32;
}

class C {
  var v: i32;
  fn Get(self) -> C { return {.v = self.v + 1}; }
  fn V(self) -> i32 { return self.v; }
}

impl C as Conv(C) {
  fn Do(self) -> C { return {.v = self.v + 2}; }
}

fn CallDo[template T: ConvSelf](x: T) -> i32 { return x.(Conv(T).Do)().V(); }

fn CallGet[template T: HasSelf](x: T) -> i32 { return x.Get().V(); }

fn Test(c: C) -> i32 { return CallDo(c) + CallGet(c); }

// --- fail_require_self_argument_unsatisfied.carbon
library "[[@TEST_NAME]]";

// The negative of `require_self_argument`: `D` does not implement `Conv(D)`,
// and its `Get` returns `i32`, not `D` (fill round 8, round 7's review 2
// finding MAJOR-2).
interface Conv(T: type) {
  fn Do(self) -> T;
}

template constraint Has(X: type) {
  fn Get(self) -> X;
}

template constraint ConvSelf {
  require Self impls Conv(Self);
  fn V(self) -> i32;
}

template constraint HasSelf {
  require impls Has(Self);
  fn V(self) -> i32;
}

class D {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
  fn V(self) -> i32 { return self.v; }
}

fn CallConv[template T: ConvSelf](x: T) -> i32 { return x.V(); }

fn CallHas[template T: HasSelf](x: T) -> i32 { return x.V(); }

fn TestConv(d: D) -> i32 { return CallConv(d); }

fn TestHas(d: D) -> i32 { return CallHas(d); }

// --- fail_todo_require_in_interface_in_generic_class_impl.carbon
library "[[@TEST_NAME]]";

// An impl inside a generic class has the checked-symbolic self `Box(T)`, which
// never satisfies a structural requirement (D-SC-6;
// structural_conformance.cpp:510), so the `require` fails at the class end
// although every `Box(X)` has `Get`; likewise in a class nested in one. Known
// limitation (W-139). A `template` class parameter makes the self
// template-phase, deferring the check (D-SC-19). Expected:
// `InterfaceRequireImplsNotImplemented` for `Box(T)` and `Inner`, not `Box2`.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

class Box(T: type) {
  fn Get(unused self) -> i32 { return 1; }
  // CHECK:STDERR: fail_todo_require_in_interface_in_generic_class_impl.carbon:[[@LINE+4]]:3: error: interface `I` being implemented requires that `Box(T)` implements `HasGet` [InterfaceRequireImplsNotImplemented]
  // CHECK:STDERR:   impl as I {}
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  impl as I {}
}

class Outer(T: type) {
  class Inner {
    fn Get(unused self) -> i32 { return 1; }
    // CHECK:STDERR: fail_todo_require_in_interface_in_generic_class_impl.carbon:[[@LINE+4]]:5: error: interface `I` being implemented requires that `Inner` implements `HasGet` [InterfaceRequireImplsNotImplemented]
    // CHECK:STDERR:     impl as I {}
    // CHECK:STDERR:     ^~~~~~~~~~~
    // CHECK:STDERR:
    impl as I {}
  }
}

class Box2(template T: type) {
  fn Get(unused self) -> i32 { return 1; }
  impl as I {}
}

// --- fail_extend_impl_extend_require_self.carbon
library "[[@TEST_NAME]]";

// A class whose only `Get` is the requirement, reached through its `extend
// impl` of an interface that does `extend require impls HasGet`, does not
// satisfy `HasGet` (D-SC-5(c): the requirement is not a member of the type),
// and calling that requirement is an error of its own (D-SC-4; fill round 2,
// review finding MINOR-1).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  extend require impls HasGet;
}

class C {
  // CHECK:STDERR: fail_extend_impl_extend_require_self.carbon:[[@LINE+4]]:3: error: interface `I` being implemented requires that `C` implements `HasGet` [InterfaceRequireImplsNotImplemented]
  // CHECK:STDERR:   extend impl as I {}
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  extend impl as I {}
}

fn Test(c: C) -> i32 {
  // CHECK:STDERR: fail_extend_impl_extend_require_self.carbon:[[@LINE+7]]:10: error: requirement `Get` of template constraint `HasGet` can only be used through a type that satisfies it [StructuralRequirementUsed]
  // CHECK:STDERR:   return c.Get();
  // CHECK:STDERR:          ^~~~~~~
  // CHECK:STDERR: fail_extend_impl_extend_require_self.carbon:[[@LINE-19]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return c.Get();
}
