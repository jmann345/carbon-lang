// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_dependent.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_dependent.carbon

// A template-dependent argument reaches the conversion chokepoint only by
// replay at instantiation, with a concrete type (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-3).

// --- dependent_caller.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  // CHECK:STDERR: dependent_caller.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(unused self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Outer[template U: type](x: U) -> i32 { return CallGet(x); }

fn Test(c: C) -> i32 { return Outer(c); }

// --- fail_dependent_caller_unsatisfied.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class D {
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE+4]]:12: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Other(self) -> i32 { return 0; }
  // CHECK:STDERR:            ^~~~
  // CHECK:STDERR:
  fn Other(self) -> i32 { return 0; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Outer[template U: type](x: U) -> i32 { return CallGet(x); }

fn Test(d: D) -> i32 {
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE+16]]:10: error: unable to monomorphize specific `Outer(D)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Outer(d);
  // CHECK:STDERR:          ^~~~~
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE-6]]:50: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR: fn Outer[template U: type](x: U) -> i32 { return CallGet(x); }
  // CHECK:STDERR:                                                  ^~~~~~~~~~
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE-9]]:50: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
  // CHECK:STDERR: fn Outer[template U: type](x: U) -> i32 { return CallGet(x); }
  // CHECK:STDERR:                                                  ^~~~~~~~~~
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE-25]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_dependent_caller_unsatisfied.carbon:[[@LINE-17]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Outer(d);
}
