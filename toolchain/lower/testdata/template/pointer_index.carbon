// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/pointer_index.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/pointer_index.carbon

// --- deref_param.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Use(n: i32*) -> i32 {
  return Deref(n);
}

// --- addr_of_member.carbon
library "[[@TEST_NAME]]";

class Counter {
  var n: i32;
}

fn Bump[template T: type](ref x: T) -> i32 {
  let q: i32* = &x.n;
  *q += 1;
  return x.n;
}

fn Use(ref c: Counter) -> i32 {
  return Bump(ref c);
}

// --- tuple_index_param.carbon
library "[[@TEST_NAME]]";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn Use(t: (i32, i32)) -> i32 {
  return Second(t);
}

// --- array_index_param.carbon
library "[[@TEST_NAME]]";

fn At1[template T: type](a: T) -> i32 {
  return a[1];
}

fn Use(a: array(i32, 3)) -> i32 {
  return At1(a);
}
