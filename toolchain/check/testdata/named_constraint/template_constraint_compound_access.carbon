// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_compound_access.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_compound_access.carbon

// Compound member access through a `template constraint` requirement
// (`x.(HasGet.Get)`) binds the base type's OWN member after the structural
// check; there is no witness table (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-4, §1.B.3).

// --- compound.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  // CHECK:STDERR: compound.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(self) -> i32 { return 1; }
}

fn F[template T: HasGet](x: T) -> i32 { return x.(HasGet.Get)(); }

fn Test(c: C) -> i32 { return F(c); }

// --- fail_compound_unsatisfied.carbon
library "[[@TEST_NAME]]";

// The binding itself is unconstrained, so the compound access is what checks
// the base type against `HasGet`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class D {
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE+4]]:12: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Other(self) -> i32 { return 0; }
  // CHECK:STDERR:            ^~~~
  // CHECK:STDERR:
  fn Other(self) -> i32 { return 0; }
}

fn F[template T: type](x: T) -> i32 { return x.(HasGet.Get)(); }

fn Test(d: D) -> i32 {
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE+13]]:10: error: unable to monomorphize specific `F(D)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return F(d);
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE-6]]:46: note: cannot convert type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]
  // CHECK:STDERR: fn F[template T: type](x: T) -> i32 { return x.(HasGet.Get)(); }
  // CHECK:STDERR:                                              ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE-9]]:46: note: type `D` has no member named `Get` required by template constraint `HasGet` [StructuralMemberMissing]
  // CHECK:STDERR: fn F[template T: type](x: T) -> i32 { return x.(HasGet.Get)(); }
  // CHECK:STDERR:                                              ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_compound_unsatisfied.carbon:[[@LINE-23]]:3: note: requirement declared here [StructuralRequirementHere]
  // CHECK:STDERR:   fn Get(self) -> i32;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return F(d);
}
