// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/import/virtual_base.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/import/virtual_base.carbon

// --- diamond.h

struct A {
  A();
  int a;
};

struct B : virtual A {
  B();
  int b;
};

struct C : virtual A {
  C();
  int c;
};

struct D : B, C {
  int d;
};

// Layout of D (x86_64):
//
// 0:  B | 0: vptr
// 8:    | 8: int B::b
// 12: (4 bytes padding)
// 16: C | 0: vptr
// 24:   | 8: int C::c
// 28: int D::d
// 32: A | 0: int A::a
// 36: (4 bytes padding)
// 40: (end of D)

// --- use_diamond.carbon

library "[[@TEST_NAME]]";

import Cpp library "diamond.h";

fn Make() {
  // This should construct a 40-byte object, using a construtor with a `...C1`
  // mangled name for D (a complete object constructor), which should call
  // constructors with `...C2` mangled names for A, B, and C (base subobject
  // constructors).
  var _: Cpp.D = Cpp.D.D();
}

fn AccessD(d: Cpp.D) -> i32 {
  // This should read an i32 at offset 28.
  return d.d;
}
