// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/generic_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/generic_pack.carbon

// --- declaration.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... each x: each T);

// --- call.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... unused each x: each T) {}

fn G() {
  F(1 as i64, true, 2 as i32);
}
