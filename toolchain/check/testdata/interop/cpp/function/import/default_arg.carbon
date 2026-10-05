// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
// EXTRA-ARGS: --clang-arg=--std=c++23
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/import/default_arg.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/import/default_arg.carbon

// --- functions.h

auto GlobalNoReturn(int a, int b, int c = 1, int d = 2) -> void;
auto GlobalReturnInt(int a, int b, int c = 1, int d = 2) -> int;

struct X {
  void B(int a, int b = 1);
  static void C(int a, int b = 1);
  void D(this X, int a, int b = 1);
};

// --- call_without_default.carbon

library "[[@TEST_NAME]]";

import Cpp library "functions.h";

fn Call() {
  //@dump-sem-ir-begin
  Cpp.GlobalNoReturn(1, 2, 3, 4);
  let unused value: i32 = Cpp.GlobalReturnInt(1, 2, 3, 4);
  ({} as Cpp.X).B(1, 2);
  Cpp.X.C(1, 2);
  ({} as Cpp.X).D(1, 2);
  //@dump-sem-ir-end
}

// --- call_with_default.carbon
//@include-in-dumps
library "[[@TEST_NAME]]";

import Cpp library "functions.h";

fn Call() {
  // //@dump-sem-ir-begin
  Cpp.GlobalNoReturn(1, 2);
  let unused value: i32 = Cpp.GlobalReturnInt(1, 2);
  Cpp.GlobalNoReturn(1, 2, 3);
  ({} as Cpp.X).B(1);
  Cpp.X.C(1);
  ({} as Cpp.X).D(1);
  // //@dump-sem-ir-end
}

// --- fail_call_too_few_args.carbon

library "[[@TEST_NAME]]";

import Cpp library "functions.h";

fn Call() {
  //@dump-sem-ir-begin
  Cpp.GlobalNoReturn(1);

  Cpp.GlobalNoReturn();

  Cpp.GlobalReturnInt(1);

  Cpp.GlobalReturnInt();

  ({} as Cpp.X).B();

  Cpp.X.C();

  ({} as Cpp.X).D();
  //@dump-sem-ir-end
}
