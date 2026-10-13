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
// golden in tree used `impl forall [template` before this one). `G` is the
// ladder's "changed constraint" step as p002200 spells it,
// `fn G[template T:! NewF](x: T) { x.(NewF.DoF)(); }`
// (proposals/p002200-template-generics.md:617-634), with this toolchain's `:`
// binding (R3), and `Test` is its "still works" call `G(y)`. The interface
// member is called qualified because the impl is not `extend`, so `DoF` is not
// a member name of the class; `TestQualified` makes that call outside a
// template.

// --- ladder.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

interface NewF {
  fn DoF(self) -> i32;
}

class C {
  // CHECK:STDERR: ladder.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(unused self) -> i32 { return 1; }
}

impl forall [template T: HasGet] T as NewF {
  fn DoF(self) -> i32 { return self.Get(); }
}

fn G[template T: NewF](x: T) { x.(NewF.DoF)(); }

fn Test(c: C) { G(c); }

fn TestQualified(c: C) -> i32 { return c.(NewF.DoF)(); }

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

fn G[template T: NewF](x: T) { x.(NewF.DoF)(); }

fn Test(d: D) { G(d); }

fn TestQualified(d: D) -> i32 {
  // CHECK:STDERR: fail_ladder_unsatisfied.carbon:[[@LINE+4]]:10: error: cannot access member of interface `NewF` in type `D` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   return d.(NewF.DoF)();
  // CHECK:STDERR:          ^~~~~~~~~~~~
  // CHECK:STDERR:
  return d.(NewF.DoF)();
}
