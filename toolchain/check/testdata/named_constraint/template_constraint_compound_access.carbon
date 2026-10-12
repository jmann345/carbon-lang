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
  fn Other(self) -> i32 { return 0; }
}

fn F[template T: type](x: T) -> i32 { return x.(HasGet.Get)(); }

fn Test(d: D) -> i32 {
  return F(d);
}
