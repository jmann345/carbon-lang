// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/tuple_segment.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/tuple_segment.carbon

// --- make_tuple.carbon
library "[[@TEST_NAME]]";

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}

fn Call() -> (i64, bool, i32) {
  return MakeTuple(1 as i64, true, 2 as i32);
}

// --- let.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

fn Sum[... each T: Code](t: (... each T)) -> i64 {
  let (... each x: each T) = t;
  var total: i64 = 0;
  ... total = Add(total, each x.Get());
  return total;
}

fn Call(t: (i64, i64, i64)) -> i64 {
  return Sum(t);
}

// --- impl.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

impl forall [... each T: Code] (... each T) as Code {
  fn Get(self) -> i64 {
    let (... each x: each T) = self;
    var total: i64 = 0;
    ... total = Add(total, each x.Get());
    return total;
  }
}

fn Call(t: (i64, (i64, i64))) -> i64 {
  return t.(Code.Get)();
}

// --- one_tuple.carbon
library "[[@TEST_NAME]]";

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}

fn Call() -> (i64,) {
  return MakeTuple(5 as i64);
}

// --- self_return.carbon
library "[[@TEST_NAME]]";

interface Cp {
  fn Op(self) -> Self;
}

fn Make[T: type](x: T) -> T {
  return Make(x);
}

impl forall [... each T: type] (... each T) as Cp {
  fn Op(self) -> Self { return Make(self); }
}

fn Call(t: (i64, i64, i64, i64)) -> (i64, i64, i64, i64) {
  return t.(Cp.Op)();
}

// --- impl_body.carbon
library "[[@TEST_NAME]]";

interface HasN {
  let N: i64;
}
impl i64 as HasN where .N = 3 {}
impl bool as HasN where .N = 40 {}

interface Sum {
  fn Get(self) -> i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

impl forall [... each T: HasN] (... each T) as Sum {
  fn Get(unused self) -> i64 {
    var s: i64 = 0;
    ... s = Add(s, (each T).N);
    return s;
  }
}

fn Call(t: (i64, bool, i64)) -> i64 {
  return t.(Sum.Get)();
}

// --- impl_lib.carbon
library "[[@TEST_NAME]]";

interface HasN {
  let N: i64;
}
impl i64 as HasN where .N = 3 {}
impl bool as HasN where .N = 40 {}

interface Sum {
  fn Get(self) -> i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

impl forall [... each T: HasN] (... each T) as Sum {
  fn Get(unused self) -> i64 {
    var s: i64 = 0;
    ... s = Add(s, (each T).N);
    return s;
  }
}

// --- impl_use.carbon
library "[[@TEST_NAME]]";

import library "impl_lib";

fn Call(t: (i64, bool, i64)) -> i64 {
  return t.(Sum.Get)();
}
