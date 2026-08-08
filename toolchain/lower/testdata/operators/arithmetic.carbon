// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/operators/arithmetic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/operators/arithmetic.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Test each of the arithmetic operations, signed and unsigned values may lower
// differently.

fn add_i32(a: i32, b: i32) -> i32 { return a + b; }
fn add_u32(a: u32, b: u32) -> u32 { return a + b; }

fn div_i32(a: i32, b: i32) -> i32 { return a / b; }
fn div_u32(a: u32, b: u32) -> u32 { return a / b; }

fn mod_i32(a: i32, b: i32) -> i32 { return a % b; }
fn mod_u32(a: u32, b: u32) -> u32 { return a % b; }

fn mul_i32(a: i32, b: i32) -> i32 { return a * b; }
fn mul_u32(a: u32, b: u32) -> u32 { return a * b; }

fn neg_i32(a: i32) -> i32 { return -a; }
fn neg_u32(a: u32) -> u32 { return -a; }

fn sub_i32(a: i32, b: i32) -> i32 { return a - b; }
fn sub_u32(a: u32, b: u32) -> u32 { return a - b; }

// One test for non-32 bit, verify the size is correct.

fn div_i16(a: i16, b: i16) -> i16 { return a / b; }
fn div_u16(a: u16, b: u16) -> u16 { return a / b; }

