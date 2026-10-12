// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_impl_as.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_impl_as.carbon

// `impl C as HasGet` is an error: a `template constraint` names no interface
// to implement (fork decision F-010 / SC-1, fork/structural/plan.md
// D-SC-8(ii), sub-fork F-010m pinned).

// --- fail_impl_as.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(self) -> i32 { return 1; }
}

impl C as HasGet {}

// --- todo_fail_impl_as_interface_and_template.carbon
library "[[@TEST_NAME]]";

// SC-1 GAP, pinned (commit-2 review): an impl whose `as` facet type combines an
// interface with a template constraint is accepted with NO structural check of
// the impl's self. `CheckRequireDeclsSatisfied` (impl.cpp) walks the identified
// facet type's `required_impls()` only, so the structural requirement never
// reaches `LookupImplWitness`. Not unsound — a later `T: I & HasGet`
// conversion of `C` runs the check — but undiagnosed here; residue
// "structural requirements on an impl's `as` facet type"
// (fork/structural/plan.md, landed notes for commit 2).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {}

class C {}

impl C as I & HasGet {}
