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

// CHECK:STDERR: fail_no_candidate.carbon:[[@LINE+10]]:12: error: no member of overload set `F` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Use() { F(1.5); }
// CHECK:STDERR:            ^~~~~~
// CHECK:STDERR: fail_no_candidate.carbon:[[@LINE-6]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(x: i32);
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_no_candidate.carbon:[[@LINE-8]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(b: bool);
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use() { F(1.5); }

// --- fail_arity.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

// CHECK:STDERR: fail_arity.carbon:[[@LINE+10]]:12: error: no member of overload set `F` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Use() { F(1, 2); }
// CHECK:STDERR:            ^~~~~~~
// CHECK:STDERR: fail_arity.carbon:[[@LINE-6]]:1: note: candidate takes a different number of arguments [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(x: i32);
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_arity.carbon:[[@LINE-8]]:1: note: candidate takes a different number of arguments [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(b: bool);
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use() { F(1, 2); }

// --- fail_error_arg.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32);
overload fn F(b: bool);

// An erroneous argument is diagnosed where it arises; the call stays silent.
// CHECK:STDERR: fail_error_arg.carbon:[[@LINE+14]]:14: error: name `undeclared` not found [NameNotFound]
// CHECK:STDERR: fn Use() { F(undeclared); }
// CHECK:STDERR:              ^~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_error_arg.carbon:[[@LINE+10]]:12: error: no member of overload set `F` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Use() { F(undeclared); }
// CHECK:STDERR:            ^~~~~~~~~~~~~
// CHECK:STDERR: fail_error_arg.carbon:[[@LINE-11]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(x: i32);
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_error_arg.carbon:[[@LINE-13]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(b: bool);
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use() { F(undeclared); }

// --- fail_call_from_generic_no_match.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// An unconstrained `T` has no `ImplicitAs` impl to any parameter type, so the
// call is diagnosed once, at the definition.
// CHECK:STDERR: fail_call_from_generic_no_match.carbon:[[@LINE+10]]:39: error: no member of overload set `F` accepts this call [OverloadNoMatch]
// CHECK:STDERR: fn Gen[T: type](x: T) -> i32 { return F(x); }
// CHECK:STDERR:                                       ^~~~
// CHECK:STDERR: fail_call_from_generic_no_match.carbon:[[@LINE-8]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(unused x: i32) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_call_from_generic_no_match.carbon:[[@LINE-10]]:1: note: candidate has a parameter its argument cannot implicitly convert to [OverloadCandidateRejected]
// CHECK:STDERR: overload fn F(unused b: bool) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Gen[T: type](x: T) -> i32 { return F(x); }
