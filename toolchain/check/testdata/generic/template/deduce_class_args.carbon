// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/deduce_class_args.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/deduce_class_args.carbon

// --- holder.carbon
library "[[@TEST_NAME]]";

class Holder(T: type) {
  var item: T;
}

//@dump-sem-ir-begin
fn GetTemplate[template T: type](h: Holder(T)) -> T {
  return h.item;
}
//@dump-sem-ir-end

fn Use(h: Holder(i32)) -> i32 {
  return GetTemplate(h);
}

// --- holder_copy_constraint.carbon
library "[[@TEST_NAME]]";

class Holder(T: Core.Copy) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Use(h: Holder(i32)) -> i32 {
  return Get(h);
}

// --- holder_pointer.carbon
library "[[@TEST_NAME]]";

class Holder(T: type) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)*) -> T {
  return h->item;
}

fn Use(h: Holder(i32)*) -> i32 {
  return Get(h);
}

// --- vec_value_param.carbon
library "[[@TEST_NAME]]";

class Vec(template N: i32) {
  var a: i32;
}

fn Size[template N: i32](unused v: Vec(N)) -> i32 {
  return N;
}

fn Use(v: Vec(3)) -> i32 {
  return Size(v);
}

// --- template_class_type.carbon
library "[[@TEST_NAME]]";

class Holder(template T: type) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Use(h: Holder(i32)) -> i32 {
  return Get(h);
}

// --- class_argument_expression.carbon
library "[[@TEST_NAME]]";

class Vec(N: i32) {
  var tag: i32;
}

fn Size(template N: i32, v: Vec(N + 1)) -> i32 {
  return N + v.tag;
}

fn Use(v: Vec(4)) -> i32 {
  return Size(3, v);
}

// --- class_argument_return_type.carbon
library "[[@TEST_NAME]]";

class Vec(N: i32) {
  var tag: i32;
}

fn Make(template M: Core.IntLiteral) -> Vec(M) {
  return {.tag = 1};
}

fn Use() -> Vec(3) {
  return Make(3);
}
