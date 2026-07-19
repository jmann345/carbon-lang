// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/exceptions/fenced_thunk.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/exceptions/fenced_thunk.carbon

// --- fenced_thunk.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
void may_throw();
''';

// Under the default `--cpp-exceptions=auto` (resolving to `catch` here), the
// call is routed through a `noexcept` thunk: the wrapped call lowers to an
// `invoke` with a terminate landing pad inside the thunk, while the Carbon
// caller itself contains no landing pads of its own.
fn F() {
  Cpp.may_throw();
}
