// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_set_as_value.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_set_as_value.carbon

// In 0.1 an overload set may be named only as the callee of a call (F-009,
// D-OV-4 step 6). Uses that convert the set value diagnose
// `OverloadSetNotCallee`; other non-call uses reach the landed diagnostic that
// precedes any conversion.

// --- fail_let.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn Use() { let g: i32 = F; }

// --- fail_discard.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn Use() { F; }

// --- fail_arg.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn G(unused f: i32) {}

fn Use() { G(F); }

// --- fail_if_let.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn Use() { if (let x: i32 = F) {} }

// --- fail_addr_of.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn Use() { &F; }

// --- fail_member_of_set.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn Use() { F.x; }

// --- fail_match_scrutinee.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn Use() {
  match (F) {
    default => {}
  }
}
