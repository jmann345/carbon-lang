// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_pack_expansion.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_pack_expansion.carbon

// --- fail_nested.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  // CHECK:STDERR: fail_nested.carbon:[[@LINE+7]]:7: error: pack expansion cannot contain another pack expansion [NestedPackExpansion]
  // CHECK:STDERR:   ... ... Consume(each n);
  // CHECK:STDERR:       ^~~
  // CHECK:STDERR: fail_nested.carbon:[[@LINE+4]]:3: note: enclosing pack expansion is here [EnclosingPackExpansion]
  // CHECK:STDERR:   ... ... Consume(each n);
  // CHECK:STDERR:   ^~~
  // CHECK:STDERR:
  ... ... Consume(each n);
}

// --- fail_without_each_name.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... unused each n: i64) {
  // CHECK:STDERR: fail_without_each_name.carbon:[[@LINE+8]]:3: error: pack expansion does not use any each-name [PackExpansionWithoutEachName]
  // CHECK:STDERR:   ... Consume(1);
  // CHECK:STDERR:   ^~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_without_each_name.carbon:[[@LINE-5]]:10: warning: binding `n` unused [UnusedBinding]
  // CHECK:STDERR: fn F(... each n: i64) {
  // CHECK:STDERR:          ^~~~~~~~~~~
  // CHECK:STDERR:
  ... Consume(1);
}

// --- fail_two_pack_patterns.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_two_pack_patterns.carbon:[[@LINE+7]]:23: error: parameter list can contain at most one pack expansion pattern [MultiplePackExpansionPatterns]
// CHECK:STDERR: fn F(... each a: i64, ... each b: i64);
// CHECK:STDERR:                       ^~~
// CHECK:STDERR: fail_two_pack_patterns.carbon:[[@LINE+4]]:6: note: previous pack expansion pattern is here [PreviousPackExpansionPattern]
// CHECK:STDERR: fn F(... each a: i64, ... each b: i64);
// CHECK:STDERR:      ^~~~~~~~~~~~~~~
// CHECK:STDERR:
fn F(... each a: i64, ... each b: i64);

// --- fail_variadic_virtual.carbon
library "[[@TEST_NAME]]";

base class B {
  // CHECK:STDERR: fail_variadic_virtual.carbon:[[@LINE+4]]:3: error: generic virtual function [GenericVirtual]
  // CHECK:STDERR:   virtual fn F(self, ... each n: i64);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  virtual fn F(self, ... each n: i64);
}

// --- fail_incomplete_element.carbon
library "[[@TEST_NAME]]";

interface I;

fn G(... unused each x: type) {}

fn F(... each p: I*) {
  G(... *each p);
}

// --- fail_incomplete_element_after_error.carbon
library "[[@TEST_NAME]]";

interface I;

fn G(... unused each x: I) {}

fn F(... each p: I) {
  G(... each p);
}
