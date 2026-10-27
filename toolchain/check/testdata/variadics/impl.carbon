// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/impl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/impl.carbon

// --- select.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

//@dump-sem-ir-begin
impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}
//@dump-sem-ir-end

fn Call(t: (i64, bool), e: ()) -> i64 {
  //@dump-sem-ir-begin
  t.(Count.N)();
  return e.(Count.N)();
  //@dump-sem-ir-end
}

// --- requirement.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

//@dump-sem-ir-begin
impl forall [... each T: Code] (... each T) as Code {
  fn Get(self) -> i64 {
    let (... each x: each T) = self;
    var total: i64 = 0;
    ... total = Add(total, each x.Get());
    return total;
  }
}
//@dump-sem-ir-end

fn Call(t: (i64, (i64, i64))) -> i64 {
  //@dump-sem-ir-begin
  return t.(Code.Get)();
  //@dump-sem-ir-end
}

// --- generic_use.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

fn Use[V: Count](v: V) -> i64 { return v.N(); }

fn Call(t: (i64, bool)) -> i64 {
  //@dump-sem-ir-begin
  return Use(t);
  //@dump-sem-ir-end
}

// --- non_tuple_query.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

impl i64 as Count {
  fn N(self) -> i64 { return self; }
}

fn Call(x: i64) -> i64 {
  //@dump-sem-ir-begin
  return x.(Count.N)();
  //@dump-sem-ir-end
}

// --- symbolic_query.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

//@dump-sem-ir-begin
fn H[... each T: type](t: (... each T)) -> i64 {
  return t.(Count.N)();
}
//@dump-sem-ir-end

// --- self_query.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
  fn Twice(self) -> i64;
}

//@dump-sem-ir-begin
impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
  fn Twice(self) -> i64 { return self.(Count.N)(); }
}
//@dump-sem-ir-end

// --- lib.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Call(t: (i64, bool, i64)) -> i64 {
  //@dump-sem-ir-begin
  return t.(Count.N)();
  //@dump-sem-ir-end
}

// --- rank.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Count {
  fn N(self) -> i64;
}

impl forall [T: type] T as Count {
  fn N(unused self) -> i64 { return 1; }
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

impl forall [T: type, U: type] (T, U) as Count {
  fn N(unused self) -> i64 { return 3; }
}

fn Call(x: i64, p: (i64, bool), t: (i64, bool, i64), e: ()) -> i64 {
  //@dump-sem-ir-begin
  return Add(Add(Add(x.(Count.N)(), p.(Count.N)()), t.(Count.N)()),
             e.(Count.N)());
  //@dump-sem-ir-end
}

// --- rank_reversed.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Count {
  fn N(self) -> i64;
}

impl forall [T: type, U: type] (T, U) as Count {
  fn N(unused self) -> i64 { return 3; }
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

impl forall [T: type] T as Count {
  fn N(unused self) -> i64 { return 1; }
}

fn Call(x: i64, p: (i64, bool), t: (i64, bool, i64), e: ()) -> i64 {
  //@dump-sem-ir-begin
  return Add(Add(Add(x.(Count.N)(), p.(Count.N)()), t.(Count.N)()),
             e.(Count.N)());
  //@dump-sem-ir-end
}

// --- rank_elements_after.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T, bool) as Count {
  fn N(unused self) -> i64 { return 1; }
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

fn Call(a: (i64, bool), b: (bool, i64), c: (bool,)) -> i64 {
  //@dump-sem-ir-begin
  return Add(Add(a.(Count.N)(), b.(Count.N)()), c.(Count.N)());
  //@dump-sem-ir-end
}

// --- rank_elements_after_reversed.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

impl forall [... each T: type] (... each T, bool) as Count {
  fn N(unused self) -> i64 { return 1; }
}

fn Call(a: (i64, bool), b: (bool, i64), c: (bool,)) -> i64 {
  //@dump-sem-ir-begin
  return Add(Add(a.(Count.N)(), b.(Count.N)()), c.(Count.N)());
  //@dump-sem-ir-end
}

// --- body_expansion.carbon
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

//@dump-sem-ir-begin
impl forall [... each T: HasN] (... each T) as Sum {
  fn Get(unused self) -> i64 {
    var s: i64 = 0;
    ... s = Add(s, (each T).N);
    return s;
  }
}
//@dump-sem-ir-end

fn Call(t: (i64, bool, i64)) -> i64 {
  return t.(Sum.Get)();
}
