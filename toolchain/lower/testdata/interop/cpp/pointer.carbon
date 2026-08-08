// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/pointer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/pointer.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// ============================================================================
// Non-null pointers
// ============================================================================

// --- nonnull.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class C {};

auto TakePtr(C* _Nonnull) -> void;
auto ReturnPtr() -> C* _Nonnull;

auto TakePtrWithThunk(C* _Nonnull, int = 0) -> void;
auto ReturnPtrWithThunk(int = 0) -> C* _Nonnull;
''';

fn PassPtr(p: Cpp.C*) {
  Cpp.TakePtr(p);
}

fn ReturnPtr() -> Cpp.C* {
  return Cpp.ReturnPtr();
}

fn PassPtrWithThunk(p: Cpp.C*) {
  Cpp.TakePtrWithThunk(p);
}

fn ReturnPtrWithThunk() -> Cpp.C* {
  return Cpp.ReturnPtrWithThunk();
}

// ============================================================================
// Nullable pointers
// ============================================================================

// --- nullable.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class C {};

auto TakePtr(C*) -> void;
auto ReturnPtr() -> C*;

auto TakePtrWithThunk(C*, int = 0) -> void;
auto ReturnPtrWithThunk(int = 0) -> C*;
''';

fn PassPtr(_: Core.Optional(Cpp.C*)) {
  // TODO: Add support for passing an optional here.
  // Cpp.TakePtr(p);
}

fn PassNonnullPtr(p: Cpp.C*) {
  // TODO: The `value_of_initializer` optimization doesn't get used here, so we
  // unnecessarily round-trip this value through memory.
  Cpp.TakePtr(p);
}

fn ReturnPtr() -> Core.Optional(Cpp.C*) {
  return Cpp.ReturnPtr();
}

fn PassPtrWithThunk(_: Core.Optional(Cpp.C*)) {
  // TODO: Add support for passing an optional here.
  // Cpp.TakePtrWithThunk(p);
}

fn PassNonnullPtrWithThunk(p: Cpp.C*) {
  Cpp.TakePtrWithThunk(p);
}

fn ReturnPtrWithThunk() -> Core.Optional(Cpp.C*) {
  return Cpp.ReturnPtrWithThunk();
}

// --- add_const.carbon

import Cpp inline '''
class C {};
C *make();
void take(const C*);
''';

fn Convert() {
  Cpp.take(Cpp.make());
}

