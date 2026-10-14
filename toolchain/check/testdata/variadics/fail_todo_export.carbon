// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_export.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_export.carbon

// --- fail_todo_export_variadic.carbon
library "[[@TEST_NAME]]";
import Cpp;

fn Consume(unused x: i32) {}

// CHECK:STDERR: fail_todo_export_variadic.carbon:[[@LINE+4]]:1: error: semantics TODO: `exporting a variadic function to C++` [SemanticsTodo]
// CHECK:STDERR: fn Sum(... each n: i32) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Sum(... each n: i32) {
  ... Consume(each n);
}

inline Cpp '''
void CallSum() {
  // CHECK:STDERR: fail_todo_export_variadic.carbon:[[@LINE+4]]:11: error: no member named 'Sum' in namespace 'Carbon' [CppInteropParseError]
  // CHECK:STDERR:    20 |   Carbon::Sum(1, 2);
  // CHECK:STDERR:       |           ^~~
  // CHECK:STDERR:
  Carbon::Sum(1, 2);
}
''';
