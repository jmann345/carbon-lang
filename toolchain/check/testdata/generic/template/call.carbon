// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/call.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/call.carbon

// --- dependent_call_nonconst_arg.carbon
library "[[@TEST_NAME]]";

class X {}
class Y {}
fn F[template G: type](H: G, x: X) {
  H(x);
}
fn TakeX(unused x: X) {}

fn GoodCall(x: X) { F(TakeX, x); }

// --- dependent_call_two_callees.carbon
library "[[@TEST_NAME]]";

class X {}
fn F[template G: type](H: G, x: X) {
  H(x);
}
fn TakeX(unused x: X) {}
fn AlsoTakeX(unused x: X) {}

fn GoodCalls(x: X) {
  F(TakeX, x);
  F(AlsoTakeX, x);
}
