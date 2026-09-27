// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/while/while_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/while/while_let.carbon

// Pattern conditions in `while` (W-012): the same prefix as `if`, under
// `WhileCondition`.

// --- let_binding.carbon

fn F(x: i32) {
  while (let n: i32 = x) {}
}

// --- var_binding.carbon

fn F(x: i32) {
  while (var n: i32 = x) {}
}

// --- alternative_payload.carbon

fn F(opt: Opt) {
  while (let .Some(n: i32) = opt) {}
}
