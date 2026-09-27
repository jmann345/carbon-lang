// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/let/fail_let_else_if_expr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/let/fail_let_else_if_expr.carbon

// An unparenthesized `if` expression initializer of a `let`-`else` is an
// error (fork/design-sprint/if-let.md, the initializer restriction). Both
// shapes get exactly one diagnostic: the `else {` shape is caught inside the
// `if` expression, which leaves the `else` for the declaration; the
// `else 2 else {` shape is caught at the declaration's `else`.

// --- fail_else_block.carbon

fn F(c: bool) -> i32 {
  let x: i32 = if c then 1 else { return 0; }
  return x;
}

// --- fail_else_operand.carbon

fn F(c: bool) -> i32 {
  let x: i32 = if c then 1 else 2 else { return 0; }
  return x;
}
