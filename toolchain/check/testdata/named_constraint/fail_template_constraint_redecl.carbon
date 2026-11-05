// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_redecl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_redecl.carbon

// Redeclarations of a named constraint must agree on `template` (fork decision
// F-010 / SC-1, D-SC-16). After the mismatch is diagnosed, the constraint is
// recovered as a `template constraint` in either direction, so a `fn` member
// of the definition is a requirement and no `FunctionInNonTemplateConstraint`
// cascades from the mismatch (the `_member` splits pin that recovery).

// --- fail_decl_then_template_def.carbon
library "[[@TEST_NAME]]";

constraint X;

// CHECK:STDERR: fail_decl_then_template_def.carbon:[[@LINE+7]]:1: error: redeclarations of `constraint X` must match use of `template` [NamedConstraintRedeclTemplateMismatch]
// CHECK:STDERR: template constraint X {}
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_decl_then_template_def.carbon:[[@LINE-5]]:1: note: previously declared here [RedeclPrevDecl]
// CHECK:STDERR: constraint X;
// CHECK:STDERR: ^~~~~~~~~~~~~
// CHECK:STDERR:
template constraint X {}

// --- fail_template_decl_then_def.carbon
library "[[@TEST_NAME]]";

template constraint X;

// CHECK:STDERR: fail_template_decl_then_def.carbon:[[@LINE+7]]:1: error: redeclarations of `constraint X` must match use of `template` [NamedConstraintRedeclTemplateMismatch]
// CHECK:STDERR: constraint X {}
// CHECK:STDERR: ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_template_decl_then_def.carbon:[[@LINE-5]]:1: note: previously declared here [RedeclPrevDecl]
// CHECK:STDERR: template constraint X;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
constraint X {}

// --- fail_decl_then_template_def_member.carbon
library "[[@TEST_NAME]]";

constraint X;

// CHECK:STDERR: fail_decl_then_template_def_member.carbon:[[@LINE+7]]:1: error: redeclarations of `constraint X` must match use of `template` [NamedConstraintRedeclTemplateMismatch]
// CHECK:STDERR: template constraint X {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_decl_then_template_def_member.carbon:[[@LINE-5]]:1: note: previously declared here [RedeclPrevDecl]
// CHECK:STDERR: constraint X;
// CHECK:STDERR: ^~~~~~~~~~~~~
// CHECK:STDERR:
template constraint X {
  fn G(self);
}

// --- fail_template_decl_then_def_member.carbon
library "[[@TEST_NAME]]";

template constraint X;

// CHECK:STDERR: fail_template_decl_then_def_member.carbon:[[@LINE+7]]:1: error: redeclarations of `constraint X` must match use of `template` [NamedConstraintRedeclTemplateMismatch]
// CHECK:STDERR: constraint X {
// CHECK:STDERR: ^~~~~~~~~~~~~~
// CHECK:STDERR: fail_template_decl_then_def_member.carbon:[[@LINE-5]]:1: note: previously declared here [RedeclPrevDecl]
// CHECK:STDERR: template constraint X;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
constraint X {
  fn G(self);
}
