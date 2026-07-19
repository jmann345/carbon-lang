// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/fenced_thunk.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/fenced_thunk.carbon

// --- fenced_thunk.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
void may_throw();
''';

// Under the default `--cpp-exceptions=auto` (resolving to `catch` here), a
// potentially-throwing C++ callee is called through a fenced thunk.
fn F() {
  //@dump-sem-ir-begin
  Cpp.may_throw();
  //@dump-sem-ir-end
}
