// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_call.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_call.carbon

// --- fail_too_few_args.carbon
library "[[@TEST_NAME]]";

fn Middle(first: i64, ... each mid: i64, last: i64);

fn F() {
  // CHECK:STDERR: fail_too_few_args.carbon:[[@LINE+7]]:3: error: 1 argument passed to function expecting at least 2 arguments [CallArgCountTooFewForPack]
  // CHECK:STDERR:   Middle(1);
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR: fail_too_few_args.carbon:[[@LINE-6]]:1: note: calling function declared here [InCallToVariadicFunction]
  // CHECK:STDERR: fn Middle(first: i64, ... each mid: i64, last: i64);
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  Middle(1);
}

// --- fail_expansion_for_singular_param.carbon
library "[[@TEST_NAME]]";

fn Head(first: i64, ... each rest: i64);

fn F(... each n: i64) {
  // CHECK:STDERR: fail_expansion_for_singular_param.carbon:[[@LINE+4]]:8: error: pack expansion argument cannot match a parameter that is not a pack expansion [PackExpansionArgForSingularParam]
  // CHECK:STDERR:   Head(... each n);
  // CHECK:STDERR:        ^~~~~~~~~~
  // CHECK:STDERR:
  Head(... each n);
}

// --- fail_expansion_without_pack_param.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  // CHECK:STDERR: fail_expansion_without_pack_param.carbon:[[@LINE+4]]:11: error: pack expansion argument is not matched by a pack expansion parameter [PackExpansionArgWithoutPackParam]
  // CHECK:STDERR:   Consume(... each n);
  // CHECK:STDERR:           ^~~~~~~~~~
  // CHECK:STDERR:
  Consume(... each n);
}

// --- fail_element_conversion.carbon
library "[[@TEST_NAME]]";

class C {}

fn ForEach(... unused each n: i64) {}

fn F() {
  // CHECK:STDERR: fail_element_conversion.carbon:[[@LINE+10]]:14: error: cannot implicitly convert expression of type `C` to `i64` [ConversionFailure]
  // CHECK:STDERR:   ForEach(1, {} as C);
  // CHECK:STDERR:              ^~~~~~~
  // CHECK:STDERR: fail_element_conversion.carbon:[[@LINE+7]]:14: note: type `C` does not implement interface `Core.ImplicitAs(i64)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   ForEach(1, {} as C);
  // CHECK:STDERR:              ^~~~~~~
  // CHECK:STDERR: fail_element_conversion.carbon:[[@LINE-9]]:12: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: fn ForEach(... unused each n: i64) {}
  // CHECK:STDERR:            ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ForEach(1, {} as C);
}

// --- fail_self_after_pack.carbon
library "[[@TEST_NAME]]";

class C {
  fn F(... each n: i64, self: Self);
}

fn G(c: C) {
  c.F(1, 2);
}

// --- fail_self_in_implicit_list_with_pack.carbon
library "[[@TEST_NAME]]";

class C {
  fn F[self: Self](... each n: i64, last: i64);
  fn G[self: Self](... each n: i64);
}

fn H(c: C) {
  c.F(1, 2);
  c.G(1, 2);
}
