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

// D-SC-6's cascade guard (review fold B7): after the binding is diagnosed, the
// use of `x` converts to `HasGet` without a second diagnostic because `T`'s own
// facet type already lists the requirement.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

// CHECK:STDERR: fail_implicit_binding_compound_use.carbon:[[@LINE+11]]:8: error: template constraint `HasGet` can only constrain a `template` binding [TemplateConstraintOnNonTemplateBinding]
// CHECK:STDERR: fn Bad[T: HasGet & I](x: T) -> i32 { return CallGet(x); }
// CHECK:STDERR:        ^~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_implicit_binding_compound_use.carbon:[[@LINE-6]]:54: error: use of undefined generic function [MissingGenericFunctionDefinition]
// CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
// CHECK:STDERR:                                                      ^~~~~
// CHECK:STDERR: fail_implicit_binding_compound_use.carbon:[[@LINE-14]]:3: note: generic function declared here [MissingGenericFunctionDefinitionHere]
// CHECK:STDERR:   fn Get(self) -> i32;
// CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
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
