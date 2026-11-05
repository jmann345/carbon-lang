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
// golden in tree used `impl forall [template` before this one). The sketch is
// proposals/p002200-template-generics.md:601-637: the blanket impl :612-619,
// the "changed constraint" `fn G[template T:! NewF](x: T) { x.(NewF.DoF)(); }`
// :621-628, and the "still works" call `G(y)` :636, which `Test` makes. The
// interface member is called qualified because the impl is not `extend`, so
// `DoF` is not a member name of the class; `TestQualified` makes that call
// outside a template. Deltas from the sketch (R27; fill round 3, review finding
// F4): `external impl` is spelled `impl`, the non-extending default since
// p002760 retired `external`; `:!` is `:` and `[me: Self]` is `(self)`, this
// toolchain's spellings (R3); `HasF`/`F` are `HasGet`/`Get`, this file
// family's constraint; `DoF` returns `self.Get()` as an `i32`, where the
// sketch's `me.F()` returns nothing, so that `TestQualified` has a value; and
// `var y: C = {}; G(y);` at file scope becomes `fn Test(c: C) { G(c); }`, as
// a call is not a declaration and cannot stand at file scope. The sketch's
// commented alternative `alias DoF = T.F;` is not ported: an impl member
// aliasing a template-dependent name is upstream's
// `ImplFunctionWithNonFunction` for any template binding (trunk 0bdce60a5),
// and aliasing the requirement is rejected
// (fail_template_constraint_requirement_call.carbon, `fail_ladder_alias`).

// --- ladder.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

interface NewF {
  fn DoF(self) -> i32;
}

class C {
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

// CHECK:STDERR: fail_ladder_unsatisfied.carbon:[[@LINE+7]]:17: error: cannot convert type `D` into type implementing `NewF` [ConversionFailureTypeToFacet]
// CHECK:STDERR: fn Test(d: D) { G(d); }
// CHECK:STDERR:                 ^~~~
// CHECK:STDERR: fail_ladder_unsatisfied.carbon:[[@LINE-5]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn G[template T: NewF](x: T) { x.(NewF.DoF)(); }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Test(d: D) { G(d); }

fn TestQualified(d: D) -> i32 {
  // CHECK:STDERR: fail_ladder_unsatisfied.carbon:[[@LINE+4]]:10: error: cannot access member of interface `NewF` in type `D` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   return d.(NewF.DoF)();
  // CHECK:STDERR:          ^~~~~~~~~~~~
  // CHECK:STDERR:
  return d.(NewF.DoF)();
}
