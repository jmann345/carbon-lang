// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/enum.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/enum.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// --- enum_member.h

struct C {
  enum E : short {
    a,
    b = 7,
    c
  };

  static void F(E);
};

// --- pass_as_arg.carbon

library "[[@TEST_NAME]]";

import Cpp library "enum_member.h";

fn Pass() {
  Cpp.C.F(Cpp.C.a);
  Cpp.C.F(Cpp.C.a);
  Cpp.C.F(Cpp.C.b);
  Cpp.C.F(Cpp.C.c);
  Cpp.C.F(Cpp.C.E.a);
  Cpp.C.F(Cpp.C.E.b);
  Cpp.C.F(Cpp.C.E.c);
}

// --- convert.carbon

library "[[@TEST_NAME]]";

import Cpp library "enum_member.h";

fn TakeI16(n: i16);

fn PassEnum() {
  TakeI16(Cpp.C.b as i16);
}

fn ConvertEnumToI16(e: Cpp.C.E) {
  TakeI16(e as i16);
}

fn ConvertI16ToEnum(n: i16) {
  Cpp.C.F(n as Cpp.C.E);
}

// --- bitmask.h

enum Bits {
  A = 1 << 0,
  B = 1 << 1,
  C = 1 << 2,
};

void Take(Bits b);

// --- use_bitmask.carbon

library "[[@TEST_NAME]]";

import Cpp library "bitmask.h";

fn CompileTime() {
  Cpp.Take(Cpp.A & Cpp.C);
  Cpp.Take(Cpp.A | Cpp.C);
  Cpp.Take(Cpp.A ^ Cpp.C);
  Cpp.Take(^Cpp.A);
}

fn Runtime(a: Cpp.Bits, b: Cpp.Bits) {
  Cpp.Take(a & b);
  Cpp.Take(a | b);
  Cpp.Take(a ^ b);
  // TODO: This produces a value with bits set that are not in the range of
  // representable values of the enumeration. Should we produce `^a & 7`
  // instead?
  Cpp.Take(^a);
}

// --- compare.carbon

library "[[@TEST_NAME]]";

import Cpp library "enum_member.h";

fn Compare(a: Cpp.C.E, b: Cpp.C.E) -> bool {
  return a == b;
}

fn CompareGeneric[U: type, T: Core.EqWith(U)](x: T, y: U) -> bool {
  return x == y;
}

fn CallCompareGeneric(a: Cpp.C.E, b: Cpp.C.E) -> bool {
  return CompareGeneric(a, b);
}

// --- compare_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "enum_member.h";

inline Cpp '''
enum E2 {};
struct ConvertToEnum {
  operator C::E() const;
  operator E2() const;
};
struct ConvertToEnum2 {
  operator C::E() const;
};
''';

fn Compare(a: Cpp.C.E, b: Cpp.ConvertToEnum) -> bool {
  return a == b;
}

fn Compare2(a: Cpp.E2, b: Cpp.ConvertToEnum) -> bool {
  return a == b;
}

fn Compare3(a: Cpp.C.E, b: Cpp.ConvertToEnum2) -> bool {
  return a == b;
}

fn CompareGeneric[U: type, T: Core.EqWith(U)](x: T, y: U) -> bool {
  return x == y;
}

// Vary both arguments to ensure they're both included in the fingerprint for
// the thunk.
fn CallCompareGeneric(a: Cpp.C.E, b: Cpp.ConvertToEnum) -> bool {
  return CompareGeneric(a, b);
}

fn CallCompareGeneric2(a: Cpp.E2, b: Cpp.ConvertToEnum) -> bool {
  return CompareGeneric(a, b);
}

fn CallCompareGeneric3(a: Cpp.C.E, b: Cpp.ConvertToEnum2) -> bool {
  return CompareGeneric(a, b);
}

