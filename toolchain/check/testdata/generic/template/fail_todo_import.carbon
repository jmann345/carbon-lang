// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/fail_todo_import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/fail_todo_import.carbon

// --- lib.carbon
library "[[@TEST_NAME]]";

fn Twice[template T: type](x: T) -> T {
  return x;
}

class Box(template T: type) {
  var v: T;
  fn Get(self) -> T { return self.v; }
}

fn Plain(x: ()) -> () {
  return x;
}

// --- fail_todo_import_function.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_function.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use() -> () {
  return Twice(());
}

// --- fail_todo_import_class.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_todo_import_class.carbon:[[@LINE+4]]:1: error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` [SemanticsTodo]
// CHECK:STDERR: import library "lib";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "lib";

fn Use(b: Box(())) -> () {
  return b.Get();
}

// --- import_unused.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> () {
  return Plain(());
}
