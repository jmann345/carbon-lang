// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/for/bindings.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/for/bindings.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

class EmptyRange(T: Core.Copy & Core.Destroy) {
  impl as Core.Iterate where .CursorType = {} and .ElementType = T {
    fn NewCursor(unused self) -> {} {
      return {};
    }
    fn Next(unused self, _: {}*) -> Core.Optional(T) {
      return Core.Optional(T).None();
    }
  }
}

fn F(m: i32, n: i32*);

fn For() {
  var r: EmptyRange((i32, i32)) = {};

  for ((m: i32, var n: i32) in r) {
    F(m, &n);
  }
}

