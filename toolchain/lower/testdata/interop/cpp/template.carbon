// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/template.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/template.carbon

// --- function_template.h

template<typename T> T identity(T x) { return x; }

class Class {};

// --- call.carbon

library "[[@TEST_NAME]]";

import Cpp library "function_template.h";

fn PassI32(a: i32) -> i32 {
  return Cpp.identity(a);
}

fn PassI32Explicitly(a: i32) -> i32 {
  return Cpp.identity(i32, a);
}

fn PassClass(a: Cpp.Class) -> Cpp.Class {
  return Cpp.identity(a);
}

// --- variadic.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
template<typename ...T>
auto foo(int, T...) -> void;
''';

fn Call1() {
  //@dump-sem-ir-begin
  Cpp.foo(1);
  //@dump-sem-ir-end
}

fn Call2() {
  //@dump-sem-ir-begin
  Cpp.foo(1, 2);
  //@dump-sem-ir-end
}

fn Call3() {
  //@dump-sem-ir-begin
  Cpp.foo(1, 2, 3);
  //@dump-sem-ir-end
}

// --- variadic_thunk.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class X {};
template<typename ...T>
auto foo(X, T...) -> void;
''';

fn Call1() {
  //@dump-sem-ir-begin
  Cpp.foo({} as Cpp.X);
  //@dump-sem-ir-end
}

fn Call2() {
  //@dump-sem-ir-begin
  Cpp.foo({} as Cpp.X, 2);
  //@dump-sem-ir-end
}

fn Call3() {
  //@dump-sem-ir-begin
  Cpp.foo({} as Cpp.X, 2, 3);
  //@dump-sem-ir-end
}
