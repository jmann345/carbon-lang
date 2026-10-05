// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/convert.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/enum/anonymous.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/enum/anonymous.carbon

// --- anon.h

enum { a, b, c };

void F(decltype(a)) {}

class C {
 public:
  enum { d, e, f };

  void F(decltype(d)) {}
};

// --- copy_enum.carbon

library "[[@TEST_NAME]]";

import Cpp library "anon.h";

//@dump-sem-ir-begin
fn G() {
  Cpp.F(Cpp.b);

  Cpp.C.C().F(Cpp.C.e);
}
//@dump-sem-ir-end
