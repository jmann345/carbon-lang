// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_incomplete_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_incomplete_scrutinee.carbon

class C;

fn F(p: C*) {
  // CHECK:STDERR: fail_incomplete_scrutinee.carbon:[[@LINE+7]]:10: error: matching on value of incomplete type `C` [IncompleteTypeInMatchScrutinee]
  // CHECK:STDERR:   match (*p) {
  // CHECK:STDERR:          ^~
  // CHECK:STDERR: fail_incomplete_scrutinee.carbon:[[@LINE-6]]:1: note: class was forward declared here [ClassForwardDeclaredHere]
  // CHECK:STDERR: class C;
  // CHECK:STDERR: ^~~~~~~~
  // CHECK:STDERR:
  match (*p) {
    default => { return; }
  }
}
