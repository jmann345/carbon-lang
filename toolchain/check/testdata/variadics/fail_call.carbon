// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_call.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_call.carbon

// --- fail_too_few_args.carbon
library "[[@TEST_NAME]]";

fn Middle(first: i64, ... each mid: i64, last: i64);

fn F() {
  Middle(1);
}

// --- fail_expansion_for_singular_param.carbon
library "[[@TEST_NAME]]";

fn Head(first: i64, ... each rest: i64);

fn F(... each n: i64) {
  Head(... each n);
}

// --- fail_expansion_without_pack_param.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  Consume(... each n);
}

// --- fail_element_conversion.carbon
library "[[@TEST_NAME]]";

class C {}

fn ForEach(... each n: i64);

fn F() {
  ForEach(1, {} as C);
}
