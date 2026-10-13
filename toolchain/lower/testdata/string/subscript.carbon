// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/string/subscript.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/string/subscript.carbon

// Fork (ST-1, fork/string/plan.md §4): `str` subscripts convert to `i64`
// before "string.at" (D-ST-9): a literal subscript on a runtime `str` is an
// `i64` constant index, and a `u8` subscript is zero-extended.

fn Literal(s: str) -> char { return s[0]; }
fn Unsigned(s: str, i: u8) -> char { return s[i]; }
fn Signed(s: str, i: i64) -> char { return s[i]; }
