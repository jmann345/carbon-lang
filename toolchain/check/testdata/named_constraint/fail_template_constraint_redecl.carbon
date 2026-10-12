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
// F-010 / SC-1, D-SC-16).

// --- fail_decl_then_template_def.carbon
library "[[@TEST_NAME]]";

constraint X;

template constraint X {}

// --- fail_template_decl_then_def.carbon
library "[[@TEST_NAME]]";

template constraint X;

constraint X {}
