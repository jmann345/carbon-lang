// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/fail_no_match.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/fail_no_match.carbon

// When no member accepts a call, the call is diagnosed with one note per
// member giving the first step of the match test that failed (D-OV-4 step 4).

// --- fail_no_candidate.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn Use() { F(1.5); }

// --- fail_arity.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

fn Use() { F(1, 2); }

// --- fail_error_arg.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

// An erroneous argument is diagnosed where it arises; the call stays silent.
fn Use() { F(undeclared); }

// --- fail_call_from_generic_no_match.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// An unconstrained `T` has no `ImplicitAs` impl to any parameter type, so the
// call is diagnosed once, at the definition.
fn Gen[T: type](x: T) -> i32 { return F(x); }
