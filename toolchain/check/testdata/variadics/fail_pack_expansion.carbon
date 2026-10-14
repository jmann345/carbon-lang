// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_pack_expansion.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_pack_expansion.carbon

// --- fail_nested.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  ... ... Consume(each n);
}

// --- fail_without_each_name.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  ... Consume(1);
}

// --- fail_two_pack_patterns.carbon
library "[[@TEST_NAME]]";

fn F(... each a: i64, ... each b: i64);

// --- fail_variadic_virtual.carbon
library "[[@TEST_NAME]]";

base class B {
  virtual fn F[self: Self](... each n: i64);
}
