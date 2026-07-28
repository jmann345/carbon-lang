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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/negative_literal_case.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/negative_literal_case.carbon

// A negative literal is not a single integer-literal token, but its value is a
// concrete constant integer, so it is admitted as a `case` pattern (plan
// RF-4): classification is by the checked expression's constant value, never
// by its syntax.
//@dump-sem-ir-begin
fn F(x: i32) {
  match (x) {
    case -1 => { return; }
    default => { return; }
  }
}
//@dump-sem-ir-end
