// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_todo_template_constraint_members.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_todo_template_constraint_members.carbon

// The member-requirement forms SC-1 defers (fork decision F-010 / SC-1,
// D-SC-2): a function definition (a default), a requirement with its own
// compile-time parameters (F-010l), and an associated constant.

// --- fail_todo_definition.carbon
library "[[@TEST_NAME]]";

template constraint HasDefault {
  // CHECK:STDERR: fail_todo_definition.carbon:[[@LINE+8]]:3: error: semantics TODO: `function definition in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   fn G(self) -> i32 { return 1; }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_definition.carbon:[[@LINE+4]]:8: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn G(self) -> i32 { return 1; }
  // CHECK:STDERR:        ^~~~
  // CHECK:STDERR:
  fn G(self) -> i32 { return 1; }
}

// --- fail_todo_parameterized.carbon
library "[[@TEST_NAME]]";

template constraint HasH {
  // CHECK:STDERR: fail_todo_parameterized.carbon:[[@LINE+4]]:3: error: semantics TODO: `parameterized requirement in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   fn H[U: type](self, u: U);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn H[U: type](self, u: U);
}

// --- fail_todo_assoc_const.carbon
library "[[@TEST_NAME]]";

template constraint HasX {
  // CHECK:STDERR: fail_todo_assoc_const.carbon:[[@LINE+8]]:3: error: semantics TODO: `associated constant requirement in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   let X: type;
  // CHECK:STDERR:   ^~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_todo_assoc_const.carbon:[[@LINE+4]]:14: error: expected `=`; `let` declaration must have an initializer [ExpectedInitializerAfterLet]
  // CHECK:STDERR:   let X: type;
  // CHECK:STDERR:              ^
  // CHECK:STDERR:
  let X: type;
}
