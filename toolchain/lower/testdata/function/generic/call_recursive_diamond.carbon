// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// EXTRA-ARGS: --include-carbon-core
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/generic/call_recursive_diamond.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/generic/call_recursive_diamond.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

import Core library "io";
fn A[T: Core.Copy](x: T, count: i32) -> T;
fn B[T: Core.Copy](x: T, count: i32) -> T;
fn C[T: Core.Copy](x: T, count: i32) -> T;
fn D[T: Core.Copy](x: T, count: i32) -> T;

// Builds on `call_recursive_mutual.carbon`. The two specifics for each of:
// A, B, C, D with a pointer type could be deduplicated.
fn A[T: Core.Copy](x: T, count: i32) -> T {
  if (count > 4) {
    return x;
  }
  if (count % 2 == 0) {
    return B(x, count);
  } else {
    return C(x, count);
  }
}

// B and C are not equivalent in the diamond: different generics and different function bodies.
fn B[T: Core.Copy](x: T, count: i32) -> T {
  Core.Print(1);
  return D(x, count);
}

fn C[T: Core.Copy](x: T, count: i32) -> T {
  Core.Print(2);
  return D(x, count);
}

fn D[T: Core.Copy](x: T, count: i32) -> T {
  return A(x, count + 1);
}

fn M() {
  var n: i32 = 0;
  var m: f64 = 1.0;
  var ptr_i32 : i32* = &n;
  var ptr_f64 : f64* = &m;

  A(n, 0);
  A(m, 0);
  A(ptr_i32, 0);
  A(ptr_f64, 0);
}

