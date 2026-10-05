// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/fail_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/fail_init.carbon

// A struct literal converts to a union only when it designates exactly one
// field (docs/design/unions.md, "Initialization and assignment").

// --- fail_two_fields.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: fail_two_fields.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: fail_two_fields.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn F() -> i32 {
  var u: IntOrBytes = {.word = 1, .bytes = (0, 0, 0, 0)};
  return u.word;
}

// --- fail_zero_fields.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: fail_zero_fields.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: fail_zero_fields.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn F() -> i32 {
  var u: IntOrBytes = {};
  return u.word;
}

// --- fail_unknown_field.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: fail_unknown_field.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: fail_unknown_field.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn F() -> i32 {
  var u: IntOrBytes = {.nope = 1};
  return u.word;
}

// --- fail_element_conversion.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: fail_element_conversion.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: fail_element_conversion.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn F() -> i32 {
  var u: IntOrBytes = {.word = "text"};
  return u.word;
}

// --- fail_scalar_init.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: fail_scalar_init.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: fail_scalar_init.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn F() -> i32 {
  // CHECK:STDERR: fail_scalar_init.carbon:[[@LINE+7]]:3: error: cannot implicitly convert expression of type `Core.IntLiteral` to `IntOrBytes` [ConversionFailure]
  // CHECK:STDERR:   var u: IntOrBytes = 5;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_scalar_init.carbon:[[@LINE+4]]:3: note: type `Core.IntLiteral` does not implement interface `Core.ImplicitAs(IntOrBytes)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   var u: IntOrBytes = 5;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var u: IntOrBytes = 5;
  return u.word;
}
