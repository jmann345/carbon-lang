// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_hetero_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_hetero_pack.carbon

// --- fail_missing_impl.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class C {}

fn ForEach[... each T: Code](... each x: each T);

fn Call(a: A, c: C) {
  ForEach(a, c);
}

// --- fail_missing_member.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

fn ForEach[... each T: Code](... each x: each T) {
  ... each x.Missing();
}

// --- fail_convert_element.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach[... each T: type](... each x: each T) {
  ... Consume(each x);
}

// --- fail_each_type_not_pack.carbon
library "[[@TEST_NAME]]";

fn F[T: type](... each x: each T);

// --- fail_two_explicit_packs.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... each x: each T, ... each y: each T);
