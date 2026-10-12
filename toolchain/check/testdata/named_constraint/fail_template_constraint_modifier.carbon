// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_modifier.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_modifier.carbon

// The `template` modifier is accepted only on `constraint` (fork decision
// F-010 / SC-1, D-SC-1). Every other declaration rejects it through its
// existing modifier limit.

// --- fail_on_fn.carbon
library "[[@TEST_NAME]]";

template fn F();

// --- fail_on_class.carbon
library "[[@TEST_NAME]]";

template class C {}

// --- fail_on_interface.carbon
library "[[@TEST_NAME]]";

template interface I {}

// --- fail_twice.carbon
library "[[@TEST_NAME]]";

template template constraint X {}

// --- fail_with_abstract.carbon
library "[[@TEST_NAME]]";

// `template` and `abstract` are both in the "at most one of" declaration
// modifier group, so the second is rejected before any declaration-specific
// limit runs.
template abstract constraint X {}
