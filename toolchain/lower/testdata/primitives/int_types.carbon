// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/primitives/int_types.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/primitives/int_types.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// --- pass_and_return.carbon

library "[[@TEST_NAME]]";

fn F_i8(a: i8) -> i8 { return a; }
fn F_u16(a: u16) -> u16 { return a; }
fn F_i64(a: i64) -> i64 { return a; }
fn F_u65536(a: u65536) -> u65536 { return a; }

// --- load_and_store.carbon

library "[[@TEST_NAME]]";

fn LoadStore_Bytes(p: Core.Int(24)*, n: Core.Int(24)) -> Core.Int(24) {
  let v: Core.Int(24) = *p;
  *p = n;
  return v;
}

fn LoadStore_NotBytes(p: Core.Int(13)*, n: Core.Int(13)) -> Core.Int(13) {
  let v: Core.Int(13) = *p;
  *p = n;
  return v;
}

// --- convert.carbon

library "[[@TEST_NAME]]";

fn ImplicitWidenSigned(a: i8) -> i32 { return a; }
fn ImplicitWidenUnsigned(a: u8) -> u32 { return a; }
fn ImplicitWidenUnsignedToSigned(a: u8) -> i32 { return a; }
fn ImplicitWidenCustom(a: Core.Int(4)) -> Core.Int(5) { return a; }
fn ImplicitWidenUnsignedCustom(a: Core.UInt(4)) -> Core.UInt(5) { return a; }

