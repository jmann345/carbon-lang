// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/tuple_segment.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/tuple_segment.carbon

// --- param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F[... each T: type](unused t: (... each T)) {}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  F((1 as i64, true));
  F(());
  //@dump-sem-ir-end
}

// --- return.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}
//@dump-sem-ir-end

fn Call() -> (i64, bool) {
  //@dump-sem-ir-begin
  return MakeTuple(1 as i64, true);
  //@dump-sem-ir-end
}

// --- let.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

interface Code {
  fn Get(self) -> i64;
}

//@dump-sem-ir-begin
fn ForEach[... each T: Code](t: (... each T)) {
  let (... each x: each T) = t;
  ... Consume(each x.Get());
}
//@dump-sem-ir-end

// --- tuple_value.carbon
library "[[@TEST_NAME]]";

fn Take[... each U: type](unused t: (... each U)) {}

//@dump-sem-ir-begin
fn Pass[... each T: type](... each x: each T) {
  Take((... each x));
}
//@dump-sem-ir-end

// --- elements_around_segment.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](unused t: (i64, ... each T, bool)) {}

fn Call() {
  //@dump-sem-ir-begin
  F((1 as i64, 2 as i32, false, true));
  F((1 as i64, true));
  //@dump-sem-ir-end
}
