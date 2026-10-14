// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/pack_expansion.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/pack_expansion.carbon

// --- sum.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, each n);
  return total;
}

fn SumOfDoubles(... each m: i64) -> i64 {
  return Sum(... Add(each m, each m));
}

fn Call() -> i64 {
  return Add(Add(Sum(1, 2, 3), Sum()), SumOfDoubles(4, 5));
}

// --- generic_element.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](unused x: T) {}

fn ForEach[T: type](... each x: T) {
  ... Consume(each x);
}

fn Run() {
  ForEach(true, false);
  ForEach(1 as i32);
}

// --- class_element.carbon
library "[[@TEST_NAME]]";

class C {
  var a: i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Get(c: C) -> i64 {
  return c.a;
}

fn SumFields(... each c: C) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, Get(each c));
  return total;
}

fn Call(c: C, d: C) -> i64 {
  return SumFields(c, d);
}

// --- arg_order.carbon
library "[[@TEST_NAME]]";

fn P(x: i64) -> i64;

fn Digits(first: i64, ... unused each mid: i64, unused last: i64) -> i64 {
  return first;
}

fn Plain(... each x: i64) -> i64 {
  return Digits(P(1), ... P(each x), P(9));
}

fn Call() -> i64 {
  return Plain(2, 3);
}

// --- forward_converted_field.carbon
library "[[@TEST_NAME]]";

class Wrap {
  var n: i64;
}

impl Wrap as Core.ImplicitAs(i64) {
  fn Convert(self) -> i64 { return self.n; }
}

class Holder {
  var w: Wrap;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, each n);
  return total;
}

fn SumHeld(... each h: Holder) -> i64 {
  return Sum(... each h.w);
}

fn Call(h: Holder, k: Holder) -> i64 {
  return SumHeld(h, k);
}

// --- lib.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, each n);
  return total;
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Call() -> i64 {
  return Add(Sum(1, 2), Sum(3, 4, 5));
}
