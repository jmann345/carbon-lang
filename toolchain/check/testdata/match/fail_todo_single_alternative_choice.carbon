// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_single_alternative_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_single_alternative_choice.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Choices with fewer than two alternatives have an empty-tuple discriminant
// — nothing to dispatch on — and stay behind the scrutinee gate (decision
// log W5-S1; re-recorded at S2e: admitting them is scrutinee-gate work the
// exhaustiveness slice does not sanction, tracked as a work item).

// --- fail_single_alternative.carbon
library "[[@TEST_NAME]]";

choice Always {
  TheOnlyOption
}

// A single-alternative match is trivially exhaustive, but there is no
// integer discriminant to compare, so the scrutinee is not matchable yet.
fn F(a: Always) {
  // CHECK:STDERR: fail_single_alternative.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (a) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (a) {
    case .TheOnlyOption => { return; }
  }
}

// --- fail_empty_choice.carbon
library "[[@TEST_NAME]]";

choice Never {}

// A zero-alternative match would be vacuously exhaustive with zero arms,
// but the scrutinee gate keeps empty choices unmatchable too.
fn F(n: Never) {
  // CHECK:STDERR: fail_empty_choice.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (n) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (n) {
    default => { return; }
  }
}
