// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/tuple_segment_destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/tuple_segment_destroy.carbon

// --- var.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  var unused u: (... each T) = t;
}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  F((1 as i32, true));
  //@dump-sem-ir-end
}

// --- let_from_call.carbon
library "[[@TEST_NAME]]";

fn G[... each T: Core.Copy & Core.Destroy](t: (... each T)) -> (... each T) {
  return t;
}

//@dump-sem-ir-begin
fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  let unused u: (... each T) = G(t);
}
//@dump-sem-ir-end

// --- discarded_result.carbon
library "[[@TEST_NAME]]";

fn G[... each T: Core.Copy & Core.Destroy](t: (... each T)) -> (... each T) {
  return t;
}

//@dump-sem-ir-begin
fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  G(t);
}
//@dump-sem-ir-end

// --- fail_missing_destroy.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](t: (... each T)) {
  var unused u: (... each T) = t;
}

fn G[... each T: Core.Copy](t: (... each T)) -> (... each T) {
  return t;
}

fn H[... each T: Core.Copy](t: (... each T)) {
  G(t);
}
