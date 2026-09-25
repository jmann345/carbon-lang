// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/no_default_irrefutable.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/no_default_irrefutable.carbon

// Integer- and tuple-scrutinee exhaustiveness through an unguarded
// irrefutable arm (W-078b, the lifted R8 conservative gate; SF-7): these
// matches need no `default` arm and stay SILENT. The SemIR pins the
// convergence shape: the irrefutable arm's condition is a constant
// `true`, and the last arm's empty else block's edge branches straight to
// the resumption block — dynamically dead, the same shape an empty
// `default` arm produces (the former fail_todo_no_default.carbon
// fail_irrefutable_binding_arm pin, turned positive).

// --- binding_only.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(x: i32) -> i32 {
  match (x) {
    case n: i32 => { return n; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- constants_then_binding.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn G(x: i32) -> i32 {
  match (x) {
    case 0 => { return 100; }
    case 1 => { return 101; }
    case n: i32 => { return n; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- tuple_all_binding.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn H(p: (i32, i32)) -> i32 {
  match (p) {
    case (a: i32, b: i32) => { return a + b; }
  }
  return -1;
}
//@dump-sem-ir-end
