// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/hetero_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/hetero_pack.carbon

// --- call.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}

fn Call(a: A, b: B) {
  ForEach(a, b, a);
  ForEach();
}

// --- layout.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn One[V: type](unused v: V) -> i64 { return 1; }

fn Count[... each T: type](... each x: each T) -> i64 {
  var n: i64 = 0;
  ... n = Add(n, One(each x));
  return n;
}

fn Call() -> i64 {
  return Count(1 as i64, true, 2 as i32);
}

// --- forward.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}

fn Forward[... each U: Code](... each y: each U) {
  ForEach(... each y);
}

fn Call(a: A, b: B) {
  Forward(a, b);
}

// --- lib.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn One[V: type](unused v: V) -> i64 { return 1; }

fn Count[... each T: type](... each x: each T) -> i64 {
  var n: i64 = 0;
  ... n = Add(n, One(each x));
  return n;
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Call(a: A, b: B) -> i64 {
  ForEach(a, b, a);
  return Count(1 as i64, true, 2 as i32);
}
