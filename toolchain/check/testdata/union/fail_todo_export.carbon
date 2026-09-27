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
  // CHECK:STDERR: fail_todo_use_type.carbon:[[@LINE+8]]:8: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn F(self) {}
  // CHECK:STDERR:        ^~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_use_type.carbon:[[@LINE-6]]:1: error: semantics TODO: `union export` [SemanticsTodo]
  // CHECK:STDERR: union U {
  // CHECK:STDERR: ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self) {}
}

inline Cpp '''
// CHECK:STDERR: fail_todo_use_type.carbon:[[@LINE+8]]:1: error: semantics TODO: `interop with unsupported type` [SemanticsTodo]
// CHECK:STDERR: Carbon::U u;
// CHECK:STDERR: ^
// CHECK:STDERR:
// CHECK:STDERR: fail_todo_use_type.carbon:[[@LINE+4]]:9: error: no type named 'U' in namespace 'Carbon' [CppInteropParseError]
// CHECK:STDERR:    33 | Carbon::U u;
// CHECK:STDERR:       | ~~~~~~~~^
// CHECK:STDERR:
Carbon::U u;
''';

// --- fail_todo_call_method.carbon
library "[[@TEST_NAME]]";
import Cpp;

union U {
  var a: i32;
  // CHECK:STDERR: fail_todo_call_method.carbon:[[@LINE+8]]:8: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn F(self) {}
  // CHECK:STDERR:        ^~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_call_method.carbon:[[@LINE-6]]:1: error: semantics TODO: `union export` [SemanticsTodo]
  // CHECK:STDERR: union U {
  // CHECK:STDERR: ^~~~~~~~~
  // CHECK:STDERR:
  fn F(self) {}
}

inline Cpp '''
void G() {
  // CHECK:STDERR: fail_todo_call_method.carbon:[[@LINE+8]]:11: error: semantics TODO: `interop with unsupported type` [SemanticsTodo]
  // CHECK:STDERR:   Carbon::U u;
  // CHECK:STDERR:           ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_call_method.carbon:[[@LINE+4]]:11: error: no type named 'U' in namespace 'Carbon' [CppInteropParseError]
  // CHECK:STDERR:    34 |   Carbon::U u;
  // CHECK:STDERR:       |   ~~~~~~~~^
  // CHECK:STDERR:
  Carbon::U u;
  u.F();
}
''';
