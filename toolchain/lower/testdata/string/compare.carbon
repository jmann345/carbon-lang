// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/string/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/string/compare.carbon

// Fork (ST-1, fork/string/plan.md §4): comparisons call the prelude's impl
// functions, whose bodies are in the prelude object.

fn Eq(a: str, b: str) -> bool { return a == b; }
fn Lt(a: str, b: str) -> bool { return a < b; }
fn EqBufStr(a: Core.StringBuf, b: str) -> bool { return a == b; }
