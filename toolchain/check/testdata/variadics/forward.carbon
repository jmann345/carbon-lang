// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/forward.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/forward.carbon

// --- forward.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

//@dump-sem-ir-begin
fn Forward(... each m: i64) {
  ForEach(... each m);
}
//@dump-sem-ir-end

fn Call() {
  Forward(1, 2);
}

// --- forward_expression.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);
fn Double(x: i64) -> i64;

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

//@dump-sem-ir-begin
fn ForwardDoubled(... each m: i64) {
  ForEach(... Double(each m));
}
//@dump-sem-ir-end

// --- forward_fixed.carbon
library "[[@TEST_NAME]]";

fn Middle(first: i64, ... each mid: i64, last: i64);

//@dump-sem-ir-begin
fn Outer(... each x: i64) {
  Middle(0, ... each x, 9);
}
//@dump-sem-ir-end

// --- forward_generic.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](x: T);

fn ForEach[T: type](... each x: T) {
  ... Consume(each x);
}

//@dump-sem-ir-begin
fn Forward[T: type](... each x: T) {
  ForEach(... each x);
}
//@dump-sem-ir-end

// --- forward_converted.carbon
library "[[@TEST_NAME]]";

class Wrap {
  var n: i64;
}

impl Wrap as Core.ImplicitAs(i64) {
  fn Convert(self) -> i64 { return self.n; }
}

fn ForEach(... each n: i64);

//@dump-sem-ir-begin
fn Unwrap(... each w: Wrap) {
  ForEach(... each w);
}
//@dump-sem-ir-end
