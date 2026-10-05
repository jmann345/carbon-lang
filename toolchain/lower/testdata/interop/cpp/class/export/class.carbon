// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
// EXTRA-ARGS: --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/export/class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/export/class.carbon

// --- pointer.carbon
library "[[@TEST_NAME]]";

import Cpp;

class A {
  var x: i32;
  var y: i32;
}

inline Cpp '''
Carbon::A *pass(Carbon::A *p) { return p; }
void call() { pass(nullptr); }
''';

fn DoIt() { Cpp.call(); }

// --- layout.carbon

library "[[@TEST_NAME]]";

import Cpp;

base class LayoutA {
  var x: i32*;
  var y: i32;
}

class LayoutB {
  var a: LayoutA;
  var b: i32;
}

class LayoutC {
  extend base: LayoutA;
  var c: i32;
}

fn CallLayoutA(a: LayoutA*);
fn CallLayoutB(b: LayoutB*);
fn CallLayoutC(b: LayoutC*);

inline Cpp '''
void f() {
  Carbon::LayoutA a;
  Carbon::CallLayoutA(&a);
}

void g() {
  Carbon::LayoutB b;
  Carbon::CallLayoutB(&b);
}

void h() {
  Carbon::LayoutC c;
  Carbon::CallLayoutC(&c);
  Carbon::CallLayoutA(&c);
}
''';

// --- field.carbon

library "[[@TEST_NAME]]";

import Cpp;

class FieldC {
  var a: i32;
  var b: i32;
}

inline Cpp '''
void F(Carbon::FieldC& c) {
  c.a = 12;
  c.b = 34;
}
''';

fn G() {
  var c: FieldC = {.a = 0, .b = 0};
  Cpp.F(ref c);
}
