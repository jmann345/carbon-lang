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
// self never satisfies one (D-SC-6, the conservative answer to leads issue
// 2153).

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

// --- fail_symbolic_arg.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  // CHECK:STDERR: fail_symbolic_arg.carbon:[[@LINE+10]]:10: error: cannot convert type `U` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   return CallGet(x);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_symbolic_arg.carbon:[[@LINE+7]]:10: note: template constraint `HasGet` can only be satisfied by a concrete type; `U` is a checked generic binding [StructuralRequirementNeedsConcreteType]
  // CHECK:STDERR:   return CallGet(x);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_symbolic_arg.carbon:[[@LINE-9]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(x);
}

// --- fail_require_in_interface_symbolic.carbon
library "[[@TEST_NAME]]";

// Structural requirements are not forwarded through an interface's `require`
// for a checked binding (D-SC-6, review fold B7; mirrors upstream's
// interface/require.carbon `fail_todo_implicit_self_impls`).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn G[T: I](x: T) -> i32 {
  // CHECK:STDERR: fail_require_in_interface_symbolic.carbon:[[@LINE+10]]:10: error: cannot convert type `T` that implements `I` into type implementing `HasGet` [ConversionFailureFacetToFacet]
  // CHECK:STDERR:   return CallGet(x);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_require_in_interface_symbolic.carbon:[[@LINE+7]]:10: note: template constraint `HasGet` can only be satisfied by a concrete type; `T` is a checked generic binding [StructuralRequirementNeedsConcreteType]
  // CHECK:STDERR:   return CallGet(x);
  // CHECK:STDERR:          ^~~~~~~~~~
  // CHECK:STDERR: fail_require_in_interface_symbolic.carbon:[[@LINE-9]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return CallGet(x);
}

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

// The `extend` sibling of `fail_require_in_interface_symbolic`: `x.Get()` finds
// the requirement through `I`'s `extend require` with `Self := T`, a checked
// generic binding that cannot satisfy the constraint (D-SC-6), and a
// requirement is never itself called (D-SC-4; fill round 2, review finding
// MINOR-2).
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
