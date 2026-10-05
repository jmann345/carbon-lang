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
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// A struct literal converts to a union only when it designates exactly one
// field (docs/design/unions.md, "Initialization and assignment").

// --- fail_two_fields.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn F() -> i32 {
  // CHECK:STDERR: fail_two_fields.carbon:[[@LINE+4]]:23: error: initializer for union `IntOrBytes` must designate exactly one field; found 2 [UnionInitNotSingleField]
  // CHECK:STDERR:   var u: IntOrBytes = {.word = 1, .bytes = (0, 0, 0, 0)};
  // CHECK:STDERR:                       ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var u: IntOrBytes = {.word = 1, .bytes = (0, 0, 0, 0)};
  return u.word;
}

// --- fail_zero_fields.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn F() -> i32 {
  // CHECK:STDERR: fail_zero_fields.carbon:[[@LINE+4]]:23: error: initializer for union `IntOrBytes` must designate exactly one field; found 0 [UnionInitNotSingleField]
  // CHECK:STDERR:   var u: IntOrBytes = {};
  // CHECK:STDERR:                       ^~
  // CHECK:STDERR:
  var u: IntOrBytes = {};
  return u.word;
}

// --- fail_unknown_field.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn F() -> i32 {
  // CHECK:STDERR: fail_unknown_field.carbon:[[@LINE+4]]:23: error: union `IntOrBytes` has no field named `nope` [UnionInitUnknownField]
  // CHECK:STDERR:   var u: IntOrBytes = {.nope = 1};
  // CHECK:STDERR:                       ^~~~~~~~~~~
  // CHECK:STDERR:
  var u: IntOrBytes = {.nope = 1};
  return u.word;
}

// --- fail_element_conversion.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn F() -> i32 {
  // CHECK:STDERR: fail_element_conversion.carbon:[[@LINE+7]]:23: error: cannot implicitly convert expression of type `str` to `i32` [ConversionFailure]
  // CHECK:STDERR:   var u: IntOrBytes = {.word = "text"};
  // CHECK:STDERR:                       ^~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_element_conversion.carbon:[[@LINE+4]]:23: note: type `str` does not implement interface `Core.ImplicitAs(i32)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   var u: IntOrBytes = {.word = "text"};
  // CHECK:STDERR:                       ^~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var u: IntOrBytes = {.word = "text"};
  return u.word;
}

// --- fail_scalar_init.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
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
