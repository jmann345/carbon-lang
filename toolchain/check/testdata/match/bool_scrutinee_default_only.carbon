// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/bool.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/bool_scrutinee_default_only.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/bool_scrutinee_default_only.carbon

// A `default`-only bool match emits no comparison, so it has no `EqWith`
// dependency and checks on the minimal bool prelude: this pins the W-076
// scrutinee-gate admission by itself (plan §2.2, §4 P1(e)). Exactly the
// shape fail_todo_non_int_scrutinee.carbon pinned as a TODO before the
// gate admitted `bool`; that file now pins a still-gated scrutinee
// (an empty class) instead.

//@dump-sem-ir-begin
fn F(b: bool) {
  match (b) {
    default => { return; }
  }
}
//@dump-sem-ir-end
