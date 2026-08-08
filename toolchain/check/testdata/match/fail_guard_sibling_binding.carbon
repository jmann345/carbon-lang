// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_guard_sibling_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_guard_sibling_binding.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// A guard sees its OWN arm's bindings, not a sibling arm's: each arm's
// scope pops at the arm's `MatchHandler`, before the next arm's pattern
// and guard are checked (re-platform plan S2d + S2b name scope
// discipline). The first arm's guard use of `a` is fine; the second
// arm's guard referencing `a` is a NameNotFound. Error recovery
// continues past the bad guard (the error operand flows silently,
// operator.cpp / convert.cpp), so the second arm's own binding `b`,
// used nowhere, still gets its unused-binding warning at scope pop.

fn F(x: i32) -> i32 {
  match (x) {
    case a: i32 if (a < 0) => { return 1; }
    // CHECK:STDERR: fail_guard_sibling_binding.carbon:[[@LINE+8]]:21: error: name `a` not found [NameNotFound]
    // CHECK:STDERR:     case b: i32 if (a > 0) => { return 2; }
    // CHECK:STDERR:                     ^
    // CHECK:STDERR:
    // CHECK:STDERR: fail_guard_sibling_binding.carbon:[[@LINE+4]]:10: warning: binding `b` unused [UnusedBinding]
    // CHECK:STDERR:     case b: i32 if (a > 0) => { return 2; }
    // CHECK:STDERR:          ^~~~~~
    // CHECK:STDERR:
    case b: i32 if (a > 0) => { return 2; }
    default => { return 0; }
  }
  return -1;
}
