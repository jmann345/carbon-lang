// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/fail_todo_generic_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/fail_todo_generic_payload.carbon

// --- fail_todo_generic_payload.carbon
library "[[@TEST_NAME]]";

// Payload alternatives of a generic choice are out of slice even when the
// payload type itself is concrete: the representation is computed at the
// definition, before any arguments are known.
choice C(T: type) {
  Wrap(a: T),
  Concrete(b: i32),
  Nothing
}
