// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/import/union_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/import/union_init.carbon

// Designated initialization of an imported C++ union (fork/unions/plan.md
// UN-2, §4.B): the same lowering as a native union — the union's byte-array
// storage, one `store i32` through a byte-offset GEP at offset zero, and a
// read of the other member through the same offset.

// --- pair.h

union Pair {
  int a;
  int b;
};

// --- designated_init.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

fn F() -> i32 {
  var u: Cpp.Pair = {.a = 1};
  return u.b;
}
