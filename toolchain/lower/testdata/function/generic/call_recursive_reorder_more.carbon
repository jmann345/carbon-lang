// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/generic/call_recursive_reorder_more.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/generic/call_recursive_reorder_more.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Builds on `call_recursive_reorder.carbon`.

fn F[T: type, U: type, V: type](x: T, y: U, z: V, count: i32) -> i32 {
  if (count > 2) {
    return count;
  }
  return F(x, z, y, count + 1);
}

fn M() {
  var val_i16 : i16;
  var val_i32 : i32;
  var val_i64 : i64;
  var val_f64 : f64;
  var val_bool : bool;

  var ptr_i16 : i16* = &val_i16;
  var ptr_i32 : i32* = &val_i32;
  var ptr_i64 : i64* = &val_i64;
  var ptr_bool : bool* = &val_bool;

  // Insert noise: non equivalent with the second set of calls.
  // (4*2 + 1 functions generated; first 3 coalesce with each other - self
  // recursion - , 4th remains as 2 specifics, 5th is already self recursion.
  // Start: 9 functions. End: 6 functions.
  F(val_i16, ptr_i32, ptr_bool, 0);
  F(val_i32, ptr_bool, ptr_i64, 0);
  F(val_bool, ptr_bool, ptr_i16, 0);
  F(val_i64, val_bool, ptr_bool, 0);
  F(val_f64, ptr_bool, ptr_bool, 0);

  // All equivalent (6*2 + 1 generated initially, coalesced to one)
  // Start: 13 functions. End: 1 function.
  F(ptr_bool, ptr_i16, ptr_i32, 0);
  F(ptr_bool, ptr_i16, ptr_i64, 0);
  F(ptr_i32, ptr_bool, ptr_i16, 0);
  F(ptr_i32, ptr_bool, ptr_i64, 0);
  F(ptr_i16, ptr_i32, ptr_i64, 0);
  F(ptr_i64, ptr_bool, ptr_i16, 0);
  F(ptr_bool, ptr_bool, ptr_bool, 0);
}

