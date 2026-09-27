// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/fail_modifiers_and_redecl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/fail_modifiers_and_redecl.carbon

// Member and modifier restrictions reuse the class diagnostics
// (docs/design/unions.md, "Union members"): a union is implicitly final.

// --- fail_abstract.carbon
library "[[@TEST_NAME]]";

abstract union A {
  var a: i32;
}

// --- fail_base.carbon
library "[[@TEST_NAME]]";

base union B {
  var a: i32;
}

// --- fail_virtual_method.carbon
library "[[@TEST_NAME]]";

union V {
  var a: i32;
  virtual fn F(self) {}
}

// --- fail_class_then_union.carbon
library "[[@TEST_NAME]]";

class C;

union C {
  var a: i32;
}

// --- fail_redefinition.carbon
library "[[@TEST_NAME]]";

union D {
  var a: i32;
}

union D {
  var a: i32;
}
