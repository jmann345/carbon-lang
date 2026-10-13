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
  // CHECK:STDERR: require_in_template.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: require_in_interface_concrete.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
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

// CHECK:STDERR: require_in_interface_template_blanket.carbon:[[@LINE+4]]:14: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: fn Use[U: I](x: U) {}
// CHECK:STDERR:              ^~~~
// CHECK:STDERR:
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

template constraint HasGet {
  fn Get(self) -> i32;
}

constraint P {
  require impls HasGet;
}

class Lacking {}

fn CallGet[template T: P](x: T) -> i32 { return x.Get(); }

fn Test(l: Lacking) -> i32 {
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
// completes (D-SC-8(iii), amended at fill round 2, review finding MAJOR-3). A
// nominal `require` of the same interface is checked at the impl, as before.
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
  impl as I {}
}

// --- fail_extend_impl_extend_require_self.carbon
library "[[@TEST_NAME]]";

// A class whose only `Get` is the requirement, reached through its `extend
// impl` of an interface that does `extend require impls HasGet`, does not
// satisfy `HasGet` (D-SC-5(b): the requirement is not a member of the type),
// and calling that requirement is an error of its own (D-SC-4; fill round 2,
// review finding MINOR-1).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  extend require impls HasGet;
}

class C {
  extend impl as I {}
}

fn Test(c: C) -> i32 {
  return c.Get();
}
