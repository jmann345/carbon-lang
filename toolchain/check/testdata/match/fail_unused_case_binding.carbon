// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_unused_case_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_unused_case_binding.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// The `unused` pattern modifier behaves under the case arm's implicit `let`
// introducer the same way it does in a `let` declaration: using a binding
// marked `unused` is an error (re-platform plan §3.2(a) modifier behavior).

fn F(x: i32) -> i32 {
  match (x) {
    // CHECK:STDERR: fail_unused_case_binding.carbon:[[@LINE+7]]:17: error: variable `a` marked `unused` but used [UnusedButUsed]
    // CHECK:STDERR:     case unused a: i32 => { return a; }
    // CHECK:STDERR:                 ^~~~~~
    // CHECK:STDERR: fail_unused_case_binding.carbon:[[@LINE+4]]:36: note: usage here [UnusedButUsedHere]
    // CHECK:STDERR:     case unused a: i32 => { return a; }
    // CHECK:STDERR:                                    ^
    // CHECK:STDERR:
    case unused a: i32 => { return a; }
    default => { return 0; }
  }
  return -1;
}
