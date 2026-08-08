// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/generic/call_different_specific.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/generic/call_different_specific.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Builds on call_basic.carbon and call_impl_function.carbon.
// Test that when equivalence is found for the specific fingerprint, we don't
// conclude "equivalent" for all the call graph.

// The two calls to F have the same function type, but the corresponding
// definitions should not be coalesced. The function bodies of the two
// specifics of F look mostly identical: same type for the parameters,
// calling the same A and different specifics of B, with the same function
// type. The difference is discovered in the call graph inside the two B
// specifics, where the pointer values are different, and the calls to the
// two D specifics are to functions with different function types.

fn A[U: Core.Copy](x: U) -> U {
  return x;
}

fn D[U: Core.Copy](x: U) -> U {
  return x;
}

fn B[U: Core.Copy & Core.Destroy](x: U*) {
  D(*x);
}

fn F[T: Core.Copy & Core.Destroy](x: T*) {
  A(i32);
  B(x);
}

fn M(ptr_i32: i32*, ptr_f64: f64*) {
  F(ptr_i32);
  F(ptr_f64);
}

