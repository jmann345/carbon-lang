// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/fail_bool_case_type_mismatch.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/fail_bool_case_type_mismatch.carbon

// Classification is by the checked expression's constant representation,
// never its declared type (plan RF-4), so a type-mismatched bool/int
// constant now reaches the `==` build and produces a real missing-impl
// operator diagnostic instead of the old constant-admission TODO (W-076
// plan §2.5) — the same recorded behavior as RF-4's int-adapter
// constants.

// --- fail_bool_case_on_int.carbon
library "[[@TEST_NAME]]";

// `bool as EqWith(i32)` does not exist.
fn F(n: i32) -> i32 {
  match (n) {
    // CHECK:STDERR: fail_bool_case_on_int.carbon:[[@LINE+4]]:5: error: cannot access member of interface `Core.EqWith(i32)` in type `bool` that does not implement that interface [MissingImplInMemberAccess]
    // CHECK:STDERR:     case true => { return 1; }
    // CHECK:STDERR:     ^~~~~~~~~~~~
    // CHECK:STDERR:
    case true => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_int_case_on_bool.carbon
library "[[@TEST_NAME]]";

// `Core.IntLiteral as EqWith(bool)` does not exist.
fn G(b: bool) -> i32 {
  match (b) {
    // CHECK:STDERR: fail_int_case_on_bool.carbon:[[@LINE+4]]:5: error: cannot access member of interface `Core.EqWith(bool)` in type `Core.IntLiteral` that does not implement that interface [MissingImplInMemberAccess]
    // CHECK:STDERR:     case 5 => { return 1; }
    // CHECK:STDERR:     ^~~~~~~~~
    // CHECK:STDERR:
    case 5 => { return 1; }
    default => { return 0; }
  }
  return -1;
}
