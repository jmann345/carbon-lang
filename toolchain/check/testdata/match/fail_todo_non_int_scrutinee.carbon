// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/bool.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_non_int_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_non_int_scrutinee.carbon

// A still-gated scrutinee type — neither an integer shape, `bool`, a
// matchable choice, nor a tuple of those — keeps the scrutinee-gate TODO,
// pinned here under its accurate name alongside
// fail_todo_adapter_scrutinee.carbon. The bool probe this file held
// before W-076 compiles clean now and moved to the bool_scrutinee*
// positives (bool_scrutinee_default_only.carbon is the exact old shape).

class C {}

fn F(c: C) {
  match (c) {
    default => { return; }
  }
}
