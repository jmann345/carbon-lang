// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/cpp.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/cpp.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// --- std_initializer_list_make.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
template<typename T>
struct InitializerListPointerPointer {
  T* begin;
  T* end;
};

template<typename T>
struct InitializerListPointerSize {
  T* begin;
  decltype(sizeof(T)) size;
};
''';

fn MakePointerPointer(a: array(i32, 4)) -> Cpp.InitializerListPointerPointer(i32) = "cpp.std.initializer_list.make";
fn MakePointerSize(a: array(i32, 4)) -> Cpp.InitializerListPointerSize(i32) = "cpp.std.initializer_list.make";

fn TakePointerPointer(a: Cpp.InitializerListPointerPointer(i32));
fn TakePointerSize(a: Cpp.InitializerListPointerSize(i32));

fn Test() {
  TakePointerPointer(MakePointerPointer((1, 2, 3, 4)));
  TakePointerSize(MakePointerSize((1, 2, 3, 4)));
}

