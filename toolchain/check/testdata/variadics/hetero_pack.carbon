// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/hetero_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/hetero_pack.carbon

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

//@dump-sem-ir-begin
fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}
//@dump-sem-ir-end

fn Call(a: A, b: B) {
  //@dump-sem-ir-begin
  ForEach(a, b, a);
  ForEach();
  //@dump-sem-ir-end
}

// --- type_pack.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Count[... each T: type](... unused each x: each T) {}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  Count(1 as i64, true);
  Count();
  //@dump-sem-ir-end
}

// --- forward.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

fn ForEach[... each T: Code](... unused each x: each T) {}

//@dump-sem-ir-begin
fn Forward[... each U: Code](... each y: each U) {
  ForEach(... each y);
}
//@dump-sem-ir-end

// --- method.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class C {
  fn F[... each T: Code](unused self, ... unused each x: each T) {}
}

fn Call(c: C, a: A) {
  //@dump-sem-ir-begin
  c.F(a, a);
  //@dump-sem-ir-end
}

// --- qualified_member.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

fn Consume(x: i64);

//@dump-sem-ir-begin
fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.(Code.Get)());
}
//@dump-sem-ir-end

// --- template_outer.carbon
library "[[@TEST_NAME]]";

interface HasV {
  fn V(self) -> i64;
}

class G {
  var n: i64;
}

impl i64 as HasV {
  fn V(self) -> i64 { return self; }
}

impl bool as HasV {
  fn V(unused self) -> i64 { return 10; }
}

fn Consume(n: i64, v: i64);

//@dump-sem-ir-begin
fn F[template U: type, ... each T: HasV](u: U, ... each x: each T) {
  ... Consume(u.n, each x.V());
}
//@dump-sem-ir-end

fn Call(g: G) {
  F(g, 1 as i64, true);
}

// --- traits.h

template<typename T> struct Traits {
  static constexpr int size = sizeof(T);
};

// --- cpp_template_outer.carbon
library "[[@TEST_NAME]]";

import Cpp library "traits.h";

fn One[V: type](unused v: V) -> i32 { return 1; }

fn Consume(n: i32, m: i32);

//@dump-sem-ir-begin
fn F[U: type, ... each T: type](unused u: U, ... each x: each T) {
  ... Consume(Cpp.Traits(U).size, One(each x));
}
//@dump-sem-ir-end

fn Call() {
  F(1 as i64, true, 2 as i32);
}
