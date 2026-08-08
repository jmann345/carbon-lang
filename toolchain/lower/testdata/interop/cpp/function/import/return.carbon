// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/import/return.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/import/return.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// --- ints.h

unsigned char ReturnU8();
unsigned short ReturnU16();
unsigned int ReturnU32();
unsigned long ReturnU64();

signed char ReturnI8();
signed short ReturnI16();
signed int ReturnI32();
signed long ReturnI64();

// --- import_ints.carbon

library "[[@TEST_NAME]]";

import Cpp library "ints.h";

fn GetU8() -> u8 { return Cpp.ReturnU8(); }
fn GetU16() -> u16 { return Cpp.ReturnU16(); }
fn GetU32() -> u32 { return Cpp.ReturnU32(); }
fn GetU64() -> u64 { return Cpp.ReturnU64(); }

fn GetI8() -> i8 { return Cpp.ReturnI8(); }
fn GetI16() -> i16 { return Cpp.ReturnI16(); }
fn GetI32() -> i32 { return Cpp.ReturnI32(); }
fn GetI64() -> i64 { return Cpp.ReturnI64(); }

fn Use(a: u8, b: u16, c: u32, d: u64, e: i8, f: i16, g: i32, h: i64);

fn Lets() {
  let my_u8: u8 = Cpp.ReturnU8();
  let my_u16: u16 = Cpp.ReturnU16();
  let my_u32: u32 = Cpp.ReturnU32();
  let my_u64: u64 = Cpp.ReturnU64();

  let my_i8: i8 = Cpp.ReturnI8();
  let my_i16: i16 = Cpp.ReturnI16();
  let my_i32: i32 = Cpp.ReturnI32();
  let my_i64: i64 = Cpp.ReturnI64();

  Use(my_u8, my_u16, my_u32, my_u64, my_i8, my_i16, my_i32, my_i64);
}

fn Vars() {
  var my_u8: u8 = Cpp.ReturnU8();
  var my_u16: u16 = Cpp.ReturnU16();
  var my_u32: u32 = Cpp.ReturnU32();
  var my_u64: u64 = Cpp.ReturnU64();

  var my_i8: i8 = Cpp.ReturnI8();
  var my_i16: i16 = Cpp.ReturnI16();
  var my_i32: i32 = Cpp.ReturnI32();
  var my_i64: i64 = Cpp.ReturnI64();

  Use(my_u8, my_u16, my_u32, my_u64, my_i8, my_i16, my_i32, my_i64);
}

// --- class.h

struct X {
  X();
  X(const X&);
  ~X();

  void* _Nonnull p;
  void* _Nonnull q;
};

X Make();

// --- import_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "class.h";

fn GetX() -> Cpp.X { return Cpp.Make(); }

fn Let() {
  let _: Cpp.X = Cpp.Make();
}

fn Var() {
  var _: Cpp.X = Cpp.Make();
}

// --- indirect_return_with_args.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class C {};
class D {};
C f(D);
''';

fn Call(x: Cpp.D) -> Cpp.C {
  return Cpp.f(x);
}

