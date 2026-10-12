// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/import/template_constraint.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/import/template_constraint.carbon

// A C++ class as the argument of a `template constraint` binding (fork
// decision F-010 / SC-1, fork/structural/plan.md D-SC-11, §4.C). Imported C++
// methods take `ref self`, so a constraint meant for C++ classes spells its
// methods `fn Get(ref self)`.
//
// Hand trace at implementation time (R9): an imported method NAME resolves to a
// `cpp_overload_set_value` (interop/cpp/class/import/method.carbon:279-280,
// :400-401), which the single-function predicate of D-SC-5(c) rejects as a
// mismatch, so the `satisfy` and `const_method` splits §4.C predicts positive
// are expected to fill NEGATIVE until the predicate learns to resolve a
// one-member C++ overload set (D-SC-11's break condition; residue filed with
// the commit). They carry the `fail_todo_` prefix for that reason.

// --- method.h

struct Counter {
  int value;
  Counter(int v) : value(v) {}
  int Get() { return value; }
  int Twice(int n) { return 2 * n; }
};

struct Overloaded {
  int Get();
  int Get(int);
};

struct ConstGetter {
  int value;
  int Get() const { return value; }
};

// --- fail_todo_satisfy.carbon
library "[[@TEST_NAME]]";

import Cpp library "method.h";

template constraint HasGet {
  fn Get(ref self) -> i32;
}

fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }

fn Test(c: Cpp.Counter*) -> i32 {
  return CallGet(c);
}

// --- fail_value_self.carbon
library "[[@TEST_NAME]]";

import Cpp library "method.h";

// The spelling rule of D-SC-11: a value `self` requirement does not match an
// imported (`ref self`) method.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }

fn Test(c: Cpp.Counter*) -> i32 {
  return CallGet(c);
}

// --- fail_overloaded.carbon
library "[[@TEST_NAME]]";

import Cpp library "method.h";

// An overloaded C++ method is not a single function (D-SC-5(c)).
template constraint HasGet {
  fn Get(ref self) -> i32;
}

fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }

fn Test(o: Cpp.Overloaded*) -> i32 {
  return CallGet(o);
}

// --- fail_todo_const_method.carbon
library "[[@TEST_NAME]]";

import Cpp library "method.h";

// A `const` method against a `ref self` requirement (D-SC-5's flagged break
// condition, review fold B14).
template constraint HasGet {
  fn Get(ref self) -> i32;
}

fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }

fn Test(g: Cpp.ConstGetter*) -> i32 {
  return CallGet(g);
}
