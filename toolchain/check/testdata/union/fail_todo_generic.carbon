// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/fail_todo_generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/fail_todo_generic.carbon

// Generic unions, and unions nested in a generic scope, are TODO-gated in 0.1
// (docs/design/unions.md, "Declaring a union"; fork/unions/plan.md D-UN-3).

// --- fail_todo_generic_union.carbon
library "[[@TEST_NAME]]";

union Slot(T: type) {
  var value: T;
  var next_free: Slot(T)*;
}

// --- fail_todo_nested_in_generic.carbon
library "[[@TEST_NAME]]";

class Box(T: type) {
  union U {
    var a: i32;
  }
}
