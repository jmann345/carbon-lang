// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
// EXTRA-ARGS: --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/auto_resolves_none.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/auto_resolves_none.carbon

// --- auto_resolves_none.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
void may_throw();
''';

// The default `--cpp-exceptions=auto` resolves to `none` when the user's
// Clang arguments disable exceptions: the call stays direct, with no thunk.
fn F() {
  //@dump-sem-ir-begin
  Cpp.may_throw();
  //@dump-sem-ir-end
}
