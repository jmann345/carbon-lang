// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/invalid_members.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/invalid_members.carbon

// --- fail_invalid_fn.carbon
library "[[@TEST_NAME]]";

constraint E {
  // A fn in a non-template constraint is an error: only a `template
  // constraint` carries structural member requirements (fork decision F-010 /
  // SC-1, D-SC-18).
  // CHECK:STDERR: fail_invalid_fn.carbon:[[@LINE+4]]:3: error: function declaration in a non-`template` `constraint`; use `template constraint` to declare a structural requirement [FunctionInNonTemplateConstraint]
  // CHECK:STDERR:   fn DeclaredFunction();
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn DeclaredFunction();
  // CHECK:STDERR: fail_invalid_fn.carbon:[[@LINE+4]]:3: error: function declaration in a non-`template` `constraint`; use `template constraint` to declare a structural requirement [FunctionInNonTemplateConstraint]
  // CHECK:STDERR:   fn DeclaredMethod(self, b: Self);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn DeclaredMethod(self, b: Self);
}

constraint F {
  // Likewise for a defined fn.
  // CHECK:STDERR: fail_invalid_fn.carbon:[[@LINE+4]]:3: error: function declaration in a non-`template` `constraint`; use `template constraint` to declare a structural requirement [FunctionInNonTemplateConstraint]
  // CHECK:STDERR:   fn DefinedFunction() {}
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn DefinedFunction() {}
  // CHECK:STDERR: fail_invalid_fn.carbon:[[@LINE+4]]:3: error: function declaration in a non-`template` `constraint`; use `template constraint` to declare a structural requirement [FunctionInNonTemplateConstraint]
  // CHECK:STDERR:   fn DefinedMethod(unused self, unused b: Self) {}
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  fn DefinedMethod(unused self, unused b: Self) {}
}

// --- todo_fail_invalid_var.carbon
library "[[@TEST_NAME]]";

constraint E {
  // TODO: Any var in a constraint is an error.
  var c: () = ();
}

// --- fail_todo_invalid_var_template.carbon
library "[[@TEST_NAME]]";

template constraint E {
  // TODO: Any var in a constraint is an error.
  // CHECK:STDERR: fail_todo_invalid_var_template.carbon:[[@LINE+4]]:3: error: semantics TODO: `field requirement in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   var c: () = ();
  // CHECK:STDERR:   ^~~
  // CHECK:STDERR:
  var c: () = ();
}

// --- todo_fail_invalid_let.carbon
library "[[@TEST_NAME]]";

constraint E {
  // TODO: Any let in a constraint is an error.
  var c: () = ();
}

// --- fail_todo_invalid_let_template.carbon
library "[[@TEST_NAME]]";

template constraint E {
  // TODO: Any let in a constraint is an error.
  // CHECK:STDERR: fail_todo_invalid_let_template.carbon:[[@LINE+4]]:3: error: semantics TODO: `field requirement in `template constraint`` [SemanticsTodo]
  // CHECK:STDERR:   var c: () = ();
  // CHECK:STDERR:   ^~~
  // CHECK:STDERR:
  var c: () = ();
}
