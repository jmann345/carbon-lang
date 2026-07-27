// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/fail_todo_nontrivial_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/fail_todo_nontrivial_payload.carbon

// --- fail_todo_class_payload.carbon
library "[[@TEST_NAME]]";

class Boxy {
  var x: i32;
}

// The slice-1 payload restriction (decision-log W5 SF-6) admits only scalar
// payload types; class-typed payloads are rejected with a clean diagnostic.
choice C {
  // CHECK:STDERR: fail_todo_class_payload.carbon:[[@LINE+4]]:7: error: semantics TODO: `choice alternative payload that is not trivially copyable and destructible` [SemanticsTodo]
  // CHECK:STDERR:   Hold(b: Boxy),
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  Hold(b: Boxy),
  Nothing
}

// The rejected alternative must not vanish from the scope: a later reference
// resolves to an error binding, so no confusing member-not-found diagnostic
// is produced here.
fn F(b: Boxy) -> C {
  return C.Hold(b);
}

// --- fail_todo_struct_payload.carbon
library "[[@TEST_NAME]]";

// Struct-typed payloads are also out of slice 1, even when their fields are
// scalars.
choice D {
  // CHECK:STDERR: fail_todo_struct_payload.carbon:[[@LINE+4]]:7: error: semantics TODO: `choice alternative payload that is not trivially copyable and destructible` [SemanticsTodo]
  // CHECK:STDERR:   Pair(p: {.a: i32, .b: i32}),
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  Pair(p: {.a: i32, .b: i32}),
  Nothing
}
