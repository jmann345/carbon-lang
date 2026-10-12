// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon

// Unsatisfied `template constraint` requirements (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-5, D-SC-9): the conversion error carries notes
// naming the first unsatisfied requirement, in declaration order.

// --- fail_missing.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class Lacking {
  fn Other(self) -> i32 { return 0; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(l: Lacking) -> i32 {
  return CallGet(l);
}

// --- fail_wrong_return.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(self) -> bool { return true; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  return CallGet(c);
}

// --- fail_wrong_self.carbon
library "[[@TEST_NAME]]";

// A value `self` requirement is not satisfied by a `ref self` method.
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(ref self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  return CallGet(c);
}

// --- fail_wrong_arity.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  fn Get(self, n: i32) -> i32 { return n; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  return CallGet(c);
}

// --- fail_external_impl.carbon
library "[[@TEST_NAME]]";

// p002200: an external `impl C as A` does not satisfy; lookup in `C` itself
// finds nothing.
interface A {
  fn F(self);
}

template constraint HasF {
  fn F(self);
}

class C {}

impl C as A {
  fn F(self) {}
}

fn CallF[template T: HasF](x: T) { x.F(); }

fn Test(c: C) {
  CallF(c);
}

// --- fail_private.carbon
library "[[@TEST_NAME]]";

// A private member does not satisfy from outside the class (review fold A1).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  private fn Get(self) -> i32 { return 1; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  return CallGet(c);
}

// --- fail_overload_set.carbon
library "[[@TEST_NAME]]";

// An `overload fn` set is not a single function (review fold A10).
template constraint HasGet {
  fn Get(self) -> i32;
}

class C {
  overload fn Get(self) -> i32 { return 1; }
  overload fn Get(self, n: i32) -> i32 { return n; }
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 {
  return CallGet(c);
}

// --- fail_incomplete.carbon
library "[[@TEST_NAME]]";

// An incomplete type cannot satisfy a requirement (D-SC-5(a), review fold B6):
// the TYPE is the facet argument.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Inc;

fn F(template T: HasGet) {}

fn Test() {
  F(Inc);
}

// --- fail_incomplete_class_param.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

class Inc;

class Box(template T: HasGet) {}

fn Test() {
  var b: Box(Inc) = {};
}
