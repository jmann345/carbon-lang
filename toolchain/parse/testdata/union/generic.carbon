// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/union/generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/union/generic.carbon

// A parameterized union parses like a generic class (the parameter list rides
// `DeclNameAndParams`); the 0.1 toolchain's `generic union` TODO is
// check-side (docs/design/unions.md, "Declaring a union").
union Slot(T: type) {
  var value: T;
  var next_free: Slot(T)*;
}
