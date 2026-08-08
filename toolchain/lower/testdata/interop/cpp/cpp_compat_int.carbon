// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/cpp_compat_int.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/cpp_compat_int.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// --- primitives.carbon

library "[[@TEST_NAME]]";

// TODO: Return `Core.CppCompat.Long32` when it's copyable.
fn DoubleLong32(l32: Core.CppCompat.Long32) -> i32 {
  // TODO: Avoid explicit conversion when multiplication on `Long32` is available.
  return 2 * (l32 as i32);
}

// TODO: Return `Core.CppCompat.ULong32` when it's copyable.
fn DoubleULong32(ul32: Core.CppCompat.ULong32) -> u32 {
  // TODO: Avoid explicit conversion when multiplication on `ULong32` is available.
  return 2 * (ul32 as u32);
}

// TODO: Return `Core.CppCompat.Long64` when it's copyable.
fn DoubleLong64(l64: Core.CppCompat.Long64) -> i64 {
  // TODO: Avoid explicit conversion when multiplication on `Long64` is available.
  return 2 * (l64 as i64);
}

// TODO: Return `Core.CppCompat.ULong64` when it's copyable.
fn DoubleULong64(ul64: Core.CppCompat.ULong64) -> u64 {
  // TODO: Avoid explicit conversion when multiplication on `ULong64` is available.
  return 2 * (ul64 as u64);
}

// TODO: Return `Core.CppCompat.LongLong64` when it's copyable.
fn DoubleLongLong64(ll64: Core.CppCompat.LongLong64) -> i64 {
  // TODO: Avoid explicit conversion when multiplication on `LongLong64` is available.
  return 2 * (ll64 as i64);
}

// TODO: Return `Core.CppCompat.ULongLong64` when it's copyable.
fn DoubleULongLong64(ull64: Core.CppCompat.ULongLong64) -> u64 {
  // TODO: Avoid explicit conversion when multiplication on `ULongLong64` is available.
  return 2 * (ull64 as u64);
}

