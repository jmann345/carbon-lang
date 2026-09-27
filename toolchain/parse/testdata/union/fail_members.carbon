// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/union/fail_members.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/union/fail_members.carbon

// Each excluded member sits on its own indented line so that recovery
// (`SkipPastLikelyEnd`) consumes only that member and the union's `}` still
// closes the tree.

// --- fail_nested_class.carbon

union U {
  var a: i32;
  class C {}
}

// --- fail_nested_choice.carbon

union U {
  var a: i32;
  choice C { X }
}

// --- fail_nested_union.carbon

union U {
  var a: i32;
  union Inner { var b: i32; }
}

// --- fail_adapt.carbon

union U {
  var a: i32;
  adapt i32;
}

// --- fail_base.carbon

base class B {}

union U {
  var a: i32;
  extend base: B;
}

// --- fail_interface.carbon

union U {
  var a: i32;
  interface I {}
}
