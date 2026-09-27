// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/fail_todo_export.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/fail_todo_export.carbon

// UN-1 placeholder (deleted at UN-2, fork/unions/plan.md D-UN-7): exporting a
// union to C++ diagnoses a TODO instead of crashing in `GetStructTypeFields`.

// --- fail_todo_use_type.carbon
library "[[@TEST_NAME]]";
import Cpp;

union U {
  var a: i32;
  fn F(self) {}
}

inline Cpp '''
Carbon::U u;
''';

// --- fail_todo_call_method.carbon
library "[[@TEST_NAME]]";
import Cpp;

union U {
  var a: i32;
  fn F(self) {}
}

inline Cpp '''
void G() {
  Carbon::U u;
  u.F();
}
''';
