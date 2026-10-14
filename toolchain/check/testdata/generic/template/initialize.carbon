// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/initialize.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/initialize.carbon

// --- return_tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}
//@dump-sem-ir-end

fn Use() -> (i32, i32) {
  return Dup(4 as i32);
}

// --- return_struct.carbon
library "[[@TEST_NAME]]";

fn Mk[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = x};
}

fn Use() -> {.a: i32, .b: i32} {
  return Mk(5 as i32);
}

// --- return_array.carbon
library "[[@TEST_NAME]]";

fn Two[template T: type](x: T) -> array(T, 2) {
  return (x, x);
}

fn Use() -> array(i32, 2) {
  return Two(4 as i32);
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

// --- return_param_tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Id[template T: type](p: T) -> T {
  return p;
}
//@dump-sem-ir-end

fn Use(t: (i32, i32)) -> (i32, i32) {
  return Id(t);
}

// --- copy_struct.carbon
library "[[@TEST_NAME]]";

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Use(s: {.x: i32, .y: i32}) -> i32 {
  return Id(s).y;
}

// --- returned_var_tuple.carbon
library "[[@TEST_NAME]]";

fn Mk[template T: type](x: T) -> (T, T) {
  returned var r: (T, T) = (x, x);
  return var;
}

fn Use() -> (i32, i32) {
  return Mk(2 as i32);
}

// --- value_param_return_tuple.carbon
library "[[@TEST_NAME]]";

fn F(template N: i32) -> (i32, i32) {
  return (N, N);
}

fn Use() -> (i32, i32) {
  return F(3);
}

// --- return_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

//@dump-sem-ir-begin
fn G[template T: type](x: T) -> ((T, T), i32) {
  return (Pair(x), 1);
}
//@dump-sem-ir-end

fn Use() -> ((i32, i32), i32) {
  return G(3 as i32);
}

// --- return_two_calls.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Quad[template T: type](x: T) -> ((T, T), (T, T)) {
  return (Pair(x), Pair(x));
}

fn Use() -> ((i32, i32), (i32, i32)) {
  return Quad(3 as i32);
}

// --- return_nested_literal.carbon
library "[[@TEST_NAME]]";

fn Quad[template T: type](x: T) -> ((T, T), T) {
  return ((x, x), x);
}

fn Use() -> ((i32, i32), i32) {
  return Quad(3 as i32);
}

// --- var_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((T, T), T) {
  var y: ((T, T), T) = (Pair(x), x);
  return y;
}

fn Use() -> ((i32, i32), i32) {
  return G(3 as i32);
}

// --- var_dependent_type_from_literal_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn H(template U: type, template T: type, x: T) -> U {
  var y: U = (Pair(x), x);
  return y;
}

fn Use() -> ((i32, i32), i32) {
  return H(((i32, i32), i32), i32, 4);
}

// --- return_struct_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> {.a: (T, T), .b: T} {
  return {.a = Pair(x), .b = x};
}

fn Use() -> {.a: (i32, i32), .b: i32} {
  return G(3 as i32);
}

// --- class_method_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

class H(template T: type) {
  var a: T;
  fn Both(self) -> ((T, T), T) { return (Pair(self.a), self.a); }
}

fn Use(h: H(i32)) -> ((i32, i32), i32) {
  return h.Both();
}

// --- nontemplate_call_in_template_literal.carbon
library "[[@TEST_NAME]]";

fn PairI(x: i32) -> (i32, i32) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((i32, i32), (T, T)) {
  return (PairI(1), (x, x));
}

fn Use() -> ((i32, i32), (i32, i32)) {
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

//@dump-sem-ir-begin
fn G[template T: type](x: T) -> i32 {
  let c: C = {.a = Pair(x), .b = 1};
  return c.a.0 + c.a.1 + c.b;
}
//@dump-sem-ir-end

fn Use() -> i32 {
  return G(3 as i32);
}

// --- let_array_value_of_calls.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> T {
  let a: array((T, T), 2) = (Pair(x), Pair(x));
  return a[1].0;
}

fn Use() -> i32 {
  return G(5 as i32);
}

// --- fail_class_value_unexpected_field.carbon
library "[[@TEST_NAME]]";

class C {
  var a: (i32, i32);
  var b: i32;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> i32 {
  let c: C = {.a = Pair(x), .c = 1};
  return c.b;
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

//@dump-sem-ir-begin
fn F[template T: type](x: T) -> i32 {
  var unused y: T = x;
  return 0;
}
//@dump-sem-ir-end

fn Use(d: D) -> i32 {
  return F(d);
}

// --- destructure_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}
//@dump-sem-ir-end

fn Use(t: (i32, i32)) -> i32 {
  return Sum(t);
}

// --- destructure_member.carbon
library "[[@TEST_NAME]]";

class Outer {
  var inner: (i32, i32);
}

fn F[template T: type](x: T) -> i32 {
  let (a: i32, b: i32) = x.inner;
  return a + b;
}

fn Use(o: Outer) -> i32 {
  return F(o);
}
