// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// TODO: Extend the "int" min_prelude to support basic integer operations, so we
// can use it here.
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/constant_expr_case.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/constant_expr_case.carbon

// Constant integer expression patterns (plan RF-4): a `case` expression is
// admitted whenever its value is a concrete constant integer, so constant
// arithmetic works the same way as a plain literal. Each comparison still
// evaluates the expression `==` the scrutinee, in that operand order.
//@dump-sem-ir-begin
fn F(x: i32) -> i32 {
  match (x) {
    case 2 + 3 => { return 1; }
    case -(4 * 4) => { return 2; }
    default => { return 0; }
  }
}
//@dump-sem-ir-end
