// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/initialize.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/initialize.carbon

// --- return_param_tuple.carbon
library "[[@TEST_NAME]]";

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Use(t: (i32, i32)) -> (i32, i32) {
  return Id(t);
}

// --- return_tuple.carbon
library "[[@TEST_NAME]]";

fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Use() -> (i32, i32) {
  return Dup(4 as i32);
}

// --- class_method_return_tuple.carbon
library "[[@TEST_NAME]]";

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Use(h: H(i32)) -> (i32, i32) {
  return h.Both();
}

// --- return_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((T, T), i32) {
  return (Pair(x), 1);
}

fn Use() -> ((i32, i32), i32) {
  return G(3 as i32);
}

// --- let_class_value_of_call.carbon
library "[[@TEST_NAME]]";

class C {
  var a: (i32, i32);
  var b: i32;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> i32 {
  let c: C = {.a = Pair(x), .b = 1};
  return c.a.0 + c.a.1 + c.b;
}

fn Use() -> i32 {
  return G(3 as i32);
}

// --- return_struct_convert.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> {.a: i64} {
  return x;
}

fn Use(s: {.a: i32}) -> {.a: i64} {
  return F(s);
}

// --- var_with_destructor.carbon
library "[[@TEST_NAME]]";

class D {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n + 10}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn F[template T: type](x: T) -> i32 {
  var unused y: T = x;
  return 0;
}

fn Use(d: D) -> i32 {
  return F(d);
}

// --- destructure_param.carbon
library "[[@TEST_NAME]]";

fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}

fn Use(t: (i32, i32)) -> i32 {
  return Sum(t);
}
