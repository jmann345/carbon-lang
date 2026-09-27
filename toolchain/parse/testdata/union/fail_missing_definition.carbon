// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/union/fail_missing_definition.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/union/fail_missing_definition.carbon

// CHECK:STDERR: fail_missing_definition.carbon:[[@LINE+4]]:8: error: `union` declarations must either end with a `;` or have a `{ ... }` block for a definition [ExpectedDeclSemiOrDefinition]
// CHECK:STDERR: union U
// CHECK:STDERR:        ^
// CHECK:STDERR:
union U

// CHECK:STDOUT: - filename: fail_missing_definition.carbon
// CHECK:STDOUT:   ╭─FileStart ''
// CHECK:STDOUT:   │ ╭─UnionIntroducer 'union'
// CHECK:STDOUT:   │ ├─IdentifierNameNotBeforeSignature 'U'
// CHECK:STDOUT:   ├─UnionDecl 'U' has_error
// CHECK:STDOUT:   ├─FileEnd ''
// CHECK:STDOUT:   (root)
