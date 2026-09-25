// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_non_constant_bool_case.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_non_constant_bool_case.carbon

// The W-076 widening admits exactly concrete `BoolLiteral` constants:
// non-constant bool expressions stay behind the (reworded) constant
// admission TODO, mirroring fail_todo_non_constant_case.carbon's integer
// shapes.

// --- fail_todo_runtime_var_bool_case.carbon
library "[[@TEST_NAME]]";

// A `case` expression reading a runtime `var` has no constant value.
fn F(b: bool) {
  var c: bool = true;
  match (b) {
    case c => { return; }
    default => { return; }
  }
}

// --- fail_todo_let_binding_bool_case.carbon
library "[[@TEST_NAME]]";

// A plain `let` binding binds a value-category result and is not a
// constant (see `WrapperBinding` in eval_inst.cpp), so naming one in a
// `case` stays behind the TODO. This pins today's behavior; it flips if
// `let` bindings gain constant values.
fn G(b: bool) {
  let k: bool = true;
  match (b) {
    case k => { return; }
    default => { return; }
  }
}
