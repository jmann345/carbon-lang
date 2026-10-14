// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/each_param.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/each_param.carbon

// --- statement.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn ForEach(... each n: i64) {
  ... Consume(each n);
}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  ForEach(1, 2, 3);
  ForEach();
  //@dump-sem-ir-end
}

// --- fixed_params.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn Middle(first: i64, ... each mid: i64, last: i64) {
  Consume(first);
  ... Consume(each mid);
  Consume(last);
}

fn Call() {
  //@dump-sem-ir-begin
  Middle(1, 2);
  Middle(1, 2, 3, 4);
  //@dump-sem-ir-end
}

// --- deduced_element_type.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](x: T);

//@dump-sem-ir-begin
fn ForEach[T: type](first: T, ... each next: T) {
  Consume(first);
  ... Consume(each next);
}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  ForEach(1 as i64, 2 as i64, 3 as i64);
  ForEach(true);
  //@dump-sem-ir-end
}

// --- redecl.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach(... each n: i64);

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

// --- method.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

class C {
  fn ForEach[self: Self](... each n: i64) {
    ... Consume(each n);
  }
}

fn Call(c: C) {
  //@dump-sem-ir-begin
  c.ForEach(1, 2);
  //@dump-sem-ir-end
}

// --- class_element.carbon
library "[[@TEST_NAME]]";

class C {
  var a: i64;
}

fn Consume(c: C);

//@dump-sem-ir-begin
fn ForEach(... each c: C) {
  ... Consume(each c);
}
//@dump-sem-ir-end

fn Call(c: C, d: C) {
  //@dump-sem-ir-begin
  ForEach(c, d);
  //@dump-sem-ir-end
}

// --- generic_caller.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](x: T);

fn ForEach[T: type](... each x: T) {
  ... Consume(each x);
}

//@dump-sem-ir-begin
fn Twice[U: type](a: U) {
  ForEach(a, a);
}
//@dump-sem-ir-end
