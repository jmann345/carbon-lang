// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint.carbon

// --- decl.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// A `template constraint` declares structural member requirements: a method
// requirement and an associated-function requirement (fork decision F-010 /
// SC-1, D-SC-1, D-SC-2). `Self` is a template-phase binding here (D-SC-10).
template constraint HasGet {
  fn Get(self) -> i32;
  fn Make() -> Self;
}

// --- forward.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// A forward declaration and its definition agree on `template` (D-SC-16).
template constraint F;

template constraint F {
  fn G(ref self);
}

// --- compose.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// Nominal requirements still compose with structural ones.
template constraint Both {
  fn Get(self) -> i32;
  require impls Core.Destroy;
}

// --- generic.carbon
library "[[@TEST_NAME]]";
//@include-in-dumps

// A generic template constraint: the with-self generic is over `(T, Self)`.
template constraint Has(T: type) {
  fn Get(self) -> T;
}
