// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
// EXTRA-ARGS: --cpp-exceptions=catch --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/catch_overrides_clang_arg.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/catch_overrides_clang_arg.carbon

// --- catch_overrides_clang_arg.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
void may_throw();
''';

// An explicit `--cpp-exceptions=catch` is a boundary-semantics contract: its
// flags are appended after the user's Clang arguments, so it wins over
// `--clang-arg=-fno-exceptions` and the callee is fenced through a thunk.
fn F() {
  //@dump-sem-ir-begin
  Cpp.may_throw();
  //@dump-sem-ir-end
}
