// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/variadics/pack_expansion_expr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/variadics/pack_expansion_expr.carbon

// --- call_args.carbon

fn F() {
  G(... each x);
  G(1, ... each x, 2);
}

// --- tuple_literal.carbon

fn F() {
  let t: auto = (... each x);
  let u: auto = (1, ... each x);
  let v: auto = (... each x, ... each y,);
}

// --- expand.carbon

fn F() {
  G(...expand t);
}

// --- fail_missing_operand.carbon

fn F() {
  G(...);
}

// --- fail_todo_and_or.carbon

fn F() {
  let b: bool = ...and G(each x);
  let c: bool = ...or G(each x);
}
