// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_todo_import_member.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_todo_import_member.carbon

// A MEMBER of an `overload fn` set reached through an import — here the
// selected member named inside an imported generic's body, resolved when the
// importing library instantiates the generic — is gated exactly like the set
// (D-OV-7, "overload set import"): importing the member's `FunctionDecl`
// without its set would give it an un-indexed mangled name that collapses
// onto its siblings'. OV-2 lifts the gate with real set import.

// --- lib.carbon

library "[[@TEST_NAME]]";

overload fn P(unused x: i32) -> i32 { return 1; }
overload fn P(unused b: bool) -> i32 { return 2; }

fn Gen[T: Core.ImplicitAs(i32)](x: T) -> i32 { return P(x); }

// --- fail_use_lib.carbon

library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> i32 { return Gen(7 as i16); }
