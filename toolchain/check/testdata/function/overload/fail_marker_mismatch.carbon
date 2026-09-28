// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_marker_mismatch.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_marker_mismatch.carbon

// The `overload` marker must be on every declaration of a name or on none
// (D-OV-3).

// --- fail_unmarked_second.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }

// Diagnosed once, then recovers as if marked: the declaration is a member.
fn F(unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return F(true); }

// --- fail_marked_second.carbon

library "[[@TEST_NAME]]";

fn F(unused x: i32) -> i32 { return 1; }

// Diagnosed and not merged; no redeclaration diagnostic is emitted on top.
overload fn F(unused b: bool) -> i32 { return 2; }

// --- fail_plain_redecl_unchanged.carbon

library "[[@TEST_NAME]]";

fn G(x: i32);

// Without the marker, differing signatures remain today's redeclaration error.
fn G(b: bool);
