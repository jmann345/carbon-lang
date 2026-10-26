// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/tuple/nested_constant.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/tuple/nested_constant.carbon

// --- tuple.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  let n: ((i32, i32), i32) = ((1, 2), 3);
  return n.0.1;
}

// --- pass.carbon
library "[[@TEST_NAME]]";

fn Take(unused t: ((i32, i32), i32)) {}

fn Call() {
  let n: ((i32, i32), i32) = ((1, 2), 3);
  Take(n);
}

// --- var.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  var v: ((i32, i32), i32) = ((4, 5), 6);
  return v.0.0;
}

// --- struct.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  let s: {.a: {.b: i32, .c: i32}, .d: i32} = {.a = {.b = 1, .c = 2}, .d = 3};
  return s.a.c;
}

// --- struct_of_tuple.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  let m: {.t: (i32, i32), .u: i32} = {.t = (4, 5), .u = 6};
  return m.t.1;
}

// --- return.carbon
library "[[@TEST_NAME]]";

fn Make() -> ((i32, i32), i32) {
  return ((4, 5), 6);
}

// --- one_element.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  var v: ((i32, i32),) = ((1, 2),);
  return v.0.1;
}
