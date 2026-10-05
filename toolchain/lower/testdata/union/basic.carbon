// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/union/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/union/basic.carbon

// Lowering of native unions needs no union-specific code: the
// `custom_layout_type` representation lowers to `[N x i8]`, every field
// access is a byte-offset GEP at offset 0, the designated initializer is a
// plain store, and the synthesized copy witness is a memcpy of all `size(U)`
// bytes (docs/design/unions.md, "Layout"; fork/unions/plan.md §4.A).

// --- unformed_local.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: unformed_local.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: unformed_local.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn UnformedLocal() -> i32 {
  var u: IntOrBytes;
  u.word = 5;
  return u.word;
}

// --- designated_init.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: designated_init.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: designated_init.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn DesignatedInit() -> i32 {
  var v: IntOrBytes = {.word = 5};
  var b: IntOrBytes = {.bytes = (1, 2, 3, 4)};
  return v.word + (b.bytes[3] as i32);
}

// --- copy.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: copy.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: copy.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn Copy(v: IntOrBytes) -> i32 {
  var w: IntOrBytes = v;
  w = v;
  return w.word;
}

// --- user_copy_impl_shadowed.carbon
library "[[@TEST_NAME]]";

union Shadowed {
  // CHECK:STDERR: user_copy_impl_shadowed.carbon:[[@LINE+4]]:7: error: union field `a` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var a: i32;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var a: i32;
  impl as Core.Copy {
    // CHECK:STDERR: user_copy_impl_shadowed.carbon:[[@LINE+4]]:11: warning: binding `self` unused [UnusedBinding]
    // CHECK:STDERR:     fn Op(self) -> Self { return {.a = 0}; }
    // CHECK:STDERR:           ^~~~
    // CHECK:STDERR:
    fn Op(self) -> Self { return {.a = 0}; }
  }
}

fn CopyShadowed(x: Shadowed) -> i32 {
  var y: Shadowed = x;
  return y.a;
}

// --- optional_pointer_field.carbon
library "[[@TEST_NAME]]";

union OptPtr {
  // CHECK:STDERR: optional_pointer_field.carbon:[[@LINE+4]]:7: error: union field `o` has type `Core.Optional(i32* as Core.OptionalStorage)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var o: Core.Optional(i32*);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var o: Core.Optional(i32*);
  // CHECK:STDERR: optional_pointer_field.carbon:[[@LINE+4]]:7: error: union field `n` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var n: i64;
  // CHECK:STDERR:       ^~~~~~
  // CHECK:STDERR:
  var n: i64;
}

fn CopyOptPtr(p: OptPtr) -> i64 {
  var q: OptPtr = p;
  return q.n;
}

// --- method.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: method.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: method.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);

  fn LowHalf(self) -> i32 { return self.bytes[0] as i32; }
  fn Set(ref self, x: i32) { self.word = x; }
}

fn UseMethods(u: IntOrBytes) -> i32 {
  var v: IntOrBytes = u;
  v.Set(3);
  return v.LowHalf();
}

// --- by_pointer.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: by_pointer.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: by_pointer.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

fn Read(u: IntOrBytes) -> i32 { return u.word; }

fn Write(p: IntOrBytes*) { p->word = 1; }

// --- file_scope_union.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  // CHECK:STDERR: file_scope_union.carbon:[[@LINE+4]]:7: error: union field `word` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var word: i32;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var word: i32;
  // CHECK:STDERR: file_scope_union.carbon:[[@LINE+4]]:7: error: union field `bytes` has type `array(i8, 4)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var bytes: array(i8, 4);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var bytes: array(i8, 4);
}

var g: IntOrBytes = {.word = 5};

