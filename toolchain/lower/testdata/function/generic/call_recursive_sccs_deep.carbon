// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// EXTRA-ARGS: --include-carbon-core
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/generic/call_recursive_sccs_deep.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/generic/call_recursive_sccs_deep.carbon
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
fn B[T: Core.Copy](x: T, count: i32);
fn C[T: Core.Copy](x: T, count: i32);
fn D[T: Core.Copy](x: T, count: i32) -> T;
fn E[T: Core.Copy](x: T, count: i32) -> T;
fn F[T: Core.Copy](x: T, count: i32) -> T;

// Builds on `call_recursive_mutual.carbon` and `call_recursive_diamond.carbon`
// B-C form a mutually recursive SCC (strongly connected component), D-E-F-G
// form a diamond SCC.
// The two specifics for each of A, B, C, D, E, F, G with a pointer type could
// be deduplicated.
// E and F are also equivalent in the diamond, even though they are different
// generics. There is potential front-end ICF (identical code folding)
// optimization here, if the function fingerprint may infer deduplication
// when not including the two different generic_ids.

fn A[T: Core.Copy](x: T, count: i32) -> T {
  B(x, count);
  return D(x, count);
}

fn B[T: Core.Copy](x: T, count: i32) {
  C(x, count);
}

fn C[T: Core.Copy](x: T, count: i32) {
  if (count <= 2) {
    Core.Print(count);
    B(x, count + 1);
  }
}

fn D[T: Core.Copy](x: T, count: i32) -> T {
  if (count > 4) {
    return x;
  }
  if (count % 2 == 0) {
    return E(x, count);
  } else {
    return F(x, count);
  }
}

fn G[T: Core.Copy](x: T, count: i32) -> T;

fn E[T: Core.Copy](x: T, count: i32) -> T {
  return G(x, count);
}

fn F[T: Core.Copy](x: T, count: i32) -> T {
  return G(x, count);
}

fn G[T: Core.Copy](x: T, count: i32) -> T {
  return D(x, count + 1);
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

