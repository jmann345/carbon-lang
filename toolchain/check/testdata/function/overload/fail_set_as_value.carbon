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

fn Use() { let unused g: i32 = F; }

// --- fail_discard.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

// CHECK:STDERR: fail_discard.carbon:[[@LINE+4]]:12: error: overload set `F` can only be used as the callee of a call [OverloadSetNotCallee]
// CHECK:STDERR: fn Use() { F; }
// CHECK:STDERR:            ^
// CHECK:STDERR:
fn Use() { F; }

// --- fail_arg.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn G(unused f: i32) {}

// CHECK:STDERR: fail_arg.carbon:[[@LINE+7]]:14: error: overload set `F` can only be used as the callee of a call [OverloadSetNotCallee]
// CHECK:STDERR: fn Use() { G(F); }
// CHECK:STDERR:              ^
// CHECK:STDERR: fail_arg.carbon:[[@LINE-5]]:13: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: fn G(unused f: i32) {}
// CHECK:STDERR:             ^~~~~~
// CHECK:STDERR:
fn Use() { G(F); }

// --- fail_if_let.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

// CHECK:STDERR: fail_if_let.carbon:[[@LINE+8]]:29: error: overload set `F` can only be used as the callee of a call [OverloadSetNotCallee]
// CHECK:STDERR: fn Use() { if (let x: i32 = F) {} }
// CHECK:STDERR:                             ^
// CHECK:STDERR:
// CHECK:STDERR: fail_if_let.carbon:[[@LINE+4]]:29: error: semantics TODO: `refutable pattern binding on unsupported scrutinee type` [SemanticsTodo]
// CHECK:STDERR: fn Use() { if (let x: i32 = F) {} }
// CHECK:STDERR:                             ^
// CHECK:STDERR:
fn Use() { if (let x: i32 = F) {} }

// --- fail_addr_of.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

// CHECK:STDERR: fail_addr_of.carbon:[[@LINE+4]]:12: error: cannot take the address of non-reference expression [AddrOfNonRef]
// CHECK:STDERR: fn Use() { &F; }
// CHECK:STDERR:            ^
// CHECK:STDERR:
fn Use() { &F; }

// --- fail_member_of_set.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

// CHECK:STDERR: fail_member_of_set.carbon:[[@LINE+4]]:12: error: overload set `F` can only be used as the callee of a call [OverloadSetNotCallee]
// CHECK:STDERR: fn Use() { F.x; }
// CHECK:STDERR:            ^
// CHECK:STDERR:
fn Use() { F.x; }

// --- fail_match_scrutinee.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn Use() {
  // CHECK:STDERR: fail_match_scrutinee.carbon:[[@LINE+8]]:10: error: overload set `F` can only be used as the callee of a call [OverloadSetNotCallee]
  // CHECK:STDERR:   match (F) {
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  // CHECK:STDERR: fail_match_scrutinee.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (F) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (F) {
    default => {}
  }
}
