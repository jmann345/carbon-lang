// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_core_optional.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_core_optional.carbon

// Fork (DR-1 D-DR-15, W-322): `Core.Optional(T)` is not matched until it
// implements `Core.Match` as docs/design/sum_types.md designs it for classes
// (W-320, which waits on W-324). D-SV-7's `StdOptional` view, a second
// spelling of that route, is retired (R32 (d)).

// --- fail_todo_match.carbon

library "[[@TEST_NAME]]";

fn F(o: Core.Optional(i32)) -> i32 {
  // CHECK:STDERR: fail_todo_match.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (o) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (o) {
    case .Some(value: i32) => {
      return value;
    }
    default => {
      return -1;
    }
  }
  return -2;
}

// --- fail_todo_if_let.carbon

library "[[@TEST_NAME]]";

fn G(p: Core.Optional(i32*)) -> i32 {
  // CHECK:STDERR: fail_todo_if_let.carbon:[[@LINE+4]]:28: error: semantics TODO: `refutable pattern binding on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   if (let .Some(q: i32*) = p) {
  // CHECK:STDERR:                            ^
  // CHECK:STDERR:
  if (let .Some(q: i32*) = p) {
    return *q;
  }
  return 0;
}
