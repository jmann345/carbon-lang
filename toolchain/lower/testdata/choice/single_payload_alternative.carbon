// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/single_payload_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/single_payload_alternative.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// The single-alternative composed constructor shape (review F-A1): with one
// alternative there are no discriminant bits, so the object representation
// is a zero-bit `()` discriminant plus the payload region, and the
// constructor's only visible store is the payload tuple at byte offset 0.

choice OneShot {
  Only(x: i32)
}

fn Make(n: i32) -> OneShot {
  return OneShot.Only(n);
}

fn Use(n: i32) {
  // Scope exit of a local exercises the destroy path for the payload region.
  // CHECK:STDERR: single_payload_alternative.carbon:[[@LINE+4]]:7: warning: binding `v` unused [UnusedBinding]
  // CHECK:STDERR:   var v: OneShot = Make(n);
  // CHECK:STDERR:       ^~~~~~~~~~
  // CHECK:STDERR:
  var v: OneShot = Make(n);
}

