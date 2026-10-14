// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_each_name.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_each_name.carbon

// --- fail_each_name_not_pack.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(x: i64) {
  ... Consume(each x);
}

// --- fail_each_name_outside_expansion.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  Consume(each n);
}

// --- fail_each_binding_outside_expansion.carbon
library "[[@TEST_NAME]]";

fn F(each n: i64) {}

// --- fail_binding_without_each.carbon
library "[[@TEST_NAME]]";

fn F(... n: i64) {}

// --- fail_unused_without_definition.carbon
library "[[@TEST_NAME]]";

fn F(... unused each n: i64);
