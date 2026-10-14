// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lex/testdata/each.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lex/testdata/each.carbon
// CHECK:STDOUT: - filename: each.carbon
// CHECK:STDOUT:   tokens:

each eachx r#each ...each
// CHECK:STDOUT:   - { index: 1, kind:               "Each", line: {{ *}}[[@LINE-1]], column:   1, indent: 1, spelling: "each", has_leading_space: true }
// CHECK:STDOUT:   - { index: 2, kind:         "Identifier", line: {{ *}}[[@LINE-2]], column:   6, indent: 1, spelling: "eachx", identifier: 0, has_leading_space: true }
// CHECK:STDOUT:   - { index: 3, kind:         "Identifier", line: {{ *}}[[@LINE-3]], column:  12, indent: 1, spelling: "r#each", identifier: 2, has_leading_space: true }
// CHECK:STDOUT:   - { index: 4, kind: "PeriodPeriodPeriod", line: {{ *}}[[@LINE-4]], column:  19, indent: 1, spelling: "...", has_leading_space: true }
// CHECK:STDOUT:   - { index: 5, kind:               "Each", line: {{ *}}[[@LINE-5]], column:  22, indent: 1, spelling: "each" }
