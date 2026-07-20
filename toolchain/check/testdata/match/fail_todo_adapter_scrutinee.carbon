// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_todo_adapter_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_todo_adapter_scrutinee.carbon

// A class type adapting an integer type has an integer object representation,
// but is not one of the integer types themselves; matching on it is not yet
// supported, even though `TryGetIntTypeInfo` succeeds for it.
class Wrapped {
  adapt i32;
}

fn F(w: Wrapped) {
  // CHECK:STDERR: fail_todo_adapter_scrutinee.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on non-integer scrutinee` [SemanticsTodo]
  // CHECK:STDERR:   match (w) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (w) {
    default => { return; }
  }
}
