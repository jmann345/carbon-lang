// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/index.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/index.carbon

// --- tuple_index_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Second[template T: type](p: T) -> i32 {
  return p.1;
}
//@dump-sem-ir-end

fn Use(t: (i32, i32)) -> i32 {
  return Second(t);
}

// --- array_index_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn At1[template T: type](a: T) -> i32 {
  return a[1];
}
//@dump-sem-ir-end

fn Use(a: array(i32, 3)) -> i32 {
  return At1(a);
}

// --- class_member_array_index.carbon
library "[[@TEST_NAME]]";

class Holder(template T: type) {
  var item: T;
  fn First(self) -> i32 { return self.item[0]; }
}

fn Use(h: Holder(array(i32, 2))) -> i32 {
  return h.First();
}

// --- fail_tuple_index_non_tuple_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn Use(n: i32) -> i32 {
  return Second(n);
}

// --- fail_index_non_indexable_on_instantiation.carbon
library "[[@TEST_NAME]]";

class Empty {}

fn At1[template T: type](a: T) -> i32 {
  return a[1];
}

fn Use(e: Empty) -> i32 {
  return At1(e);
}
