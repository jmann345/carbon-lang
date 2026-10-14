// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/pointer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/pointer.carbon

// --- deref_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Deref[template T: type](p: T) -> i32 {
  return *p;
}
//@dump-sem-ir-end

fn Use(n: i32*) -> i32 {
  return Deref(n);
}

// --- arrow_member.carbon
library "[[@TEST_NAME]]";

class Node {
  var n: i32;
}

class Link {
  var p: Node*;
}

fn Next[template T: type](x: T) -> i32 {
  return x.p->n;
}

fn Use(link: Link) -> i32 {
  return Next(link);
}

// --- addr_of_member.carbon
library "[[@TEST_NAME]]";

class Counter {
  var n: i32;
}

//@dump-sem-ir-begin
fn Read[template T: type](ref x: T) -> i32 {
  let p: i32* = &x.n;
  return *p;
}
//@dump-sem-ir-end

fn Use(ref c: Counter) -> i32 {
  return Read(ref c);
}

// --- deref_pointer_param.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: T*) -> T {
  return *p;
}

fn Use(n: i32*) -> i32 {
  return Deref(n);
}

// --- fail_deref_non_pointer_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Use(n: i32) -> i32 {
  return Deref(n);
}
