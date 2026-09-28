// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// EXTRA-ARGS: --mangle-string-fingerprint
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/mangle_string.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/mangle_string.carbon

// Members are mangled by set-relative index, not by a fingerprint (D-OV-5), so
// the string-fingerprint mode changes nothing about the `:overload<N>` names.

// --- first_match_order.carbon

library "[[@TEST_NAME]]";

overload fn Pick(x: i64) -> i32 { return 1; }
overload fn Pick(x: i32) -> i32 { return 2; }

fn Use(n: i32) -> i32 { return Pick(n); }
