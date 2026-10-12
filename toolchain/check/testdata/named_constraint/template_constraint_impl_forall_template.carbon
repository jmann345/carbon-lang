// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_impl_forall_template.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_impl_forall_template.carbon

// p002200's migration-ladder step: a blanket impl over a `template constraint`
// (fork decision F-010 / SC-1, fork/structural/plan.md D-SC-19, R-11: no
// golden in tree used `impl forall [template` before this one).

// --- ladder.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

interface NewF {
  fn DoF(self) -> i32;
}

class C {
  fn Get(self) -> i32 { return 1; }
}

impl forall [template T: HasGet] T as NewF {
  fn DoF(self) -> i32 { return self.Get(); }
}

fn Test(c: C) -> i32 { return c.DoF(); }

// --- fail_ladder_unsatisfied.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

interface NewF {
  fn DoF(self) -> i32;
}

class D {}

impl forall [template T: HasGet] T as NewF {
  fn DoF(self) -> i32 { return self.Get(); }
}

fn Test(d: D) -> i32 {
  return d.DoF();
}
