// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
// EXTRA-ARGS: --cpp-exceptions=none
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/fail_throw_in_none.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/fail_throw_in_none.carbon

// --- fail_throw_in_none.carbon

library "[[@TEST_NAME]]";

import Cpp;

// In `none` mode, `throw` in imported C++ is diagnosed exactly as Clang
// diagnoses it under `-fno-exceptions`.
inline Cpp '''
// CHECK:STDERR: fail_throw_in_none.carbon:[[@LINE+4]]:24: error: cannot use 'throw' with exceptions disabled [CppInteropParseError]
// CHECK:STDERR:     9 | void always_throws() { throw 42; }
// CHECK:STDERR:       |                        ^
// CHECK:STDERR:
void always_throws() { throw 42; }
''';

fn F() {
  Cpp.always_throws();
}
