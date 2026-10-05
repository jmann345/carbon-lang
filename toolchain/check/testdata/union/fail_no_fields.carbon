// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/fail_no_fields.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/fail_no_fields.carbon

// A Carbon-authored union must declare at least one field
// (docs/design/unions.md, "Union members").

// --- fail_empty.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_empty.carbon:[[@LINE+4]]:1: error: union `Empty` must declare at least one field [UnionWithoutFields]
// CHECK:STDERR: union Empty {}
// CHECK:STDERR: ^~~~~~~~~~~~~
// CHECK:STDERR:
union Empty {}

// --- fail_only_fns.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_only_fns.carbon:[[@LINE+4]]:1: error: union `OnlyFns` must declare at least one field [UnionWithoutFields]
// CHECK:STDERR: union OnlyFns {
// CHECK:STDERR: ^~~~~~~~~~~~~~~
// CHECK:STDERR:
union OnlyFns {
  fn F() {}
}
