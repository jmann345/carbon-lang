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
// decision F-010 / SC-1, fork/structural/plan.md D-SC-11, §4.C). An imported
// method NAME resolves to a `cpp_overload_set_value`
// (interop/cpp/class/import/method.carbon:279-280, :400-401); since SC-1c the
// structural check looks through a ONE-candidate C++ overload set to its
// member, imports it with the signature its declaration determines, and
// matches that (D-SC-5(c) as extended by the commit-2 review's finding 2). The
// `self` form mirrors the call-site import: a non-`const` method's object
// parameter is `Self&`, so it is `ref self` (§0.1 row 19); a `const` method's
// is `const Self&`, so it is value `self` (method.carbon's `const_this` thunk
// is called with a value) -- D-SC-11's spelling rule, refined.
//
// Hand trace (R9, no fill has run): `satisfy` and `const_method_value_self`
// are predicted positive; `fail_value_self` (value `self` against a non-`const`
// method), `fail_const_method` (`ref self` against a `const` method -- the
// shape §4.C named `const_method` and D-SC-5's break condition flagged) and
// `fail_overloaded` (two candidates) are predicted
// `ConversionFailureTypeToFacet` + `StructuralMemberMismatch` +
// `StructuralRequirementHere` + `DeductionGenericHere`, the mismatch note at
// the imported declaration for the one-candidate splits and at the call for
// `fail_overloaded`. `fail_todo_probe_import_leak` pins the R-7 residue
// (ledger W-144; commit-3 review): the look-through's import is not
// `diagnose`-aware, so the silent member-1 probe of a two-member `Pick` set
// emits `SemanticsTodo` "Unsupported: parameter type: _BitInt(23)" at the
// probe (the conversion of `b` in `Pick(b)`) even though member 2 is then
// selected; predicted exactly that one diagnostic.

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

// --- satisfy.carbon
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

// --- fail_const_method.carbon
library "[[@TEST_NAME]]";

import Cpp library "method.h";

// A `const` method against a `ref self` requirement (D-SC-5's flagged break
// condition, review fold B14): the object parameter `const Self&` imports as
// value `self`, which does not match `ref self`.
template constraint HasGet {
  fn Get(ref self) -> i32;
}

fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }

fn Test(g: Cpp.ConstGetter*) -> i32 {
  return CallGet(g);
}

// --- const_method_value_self.carbon
library "[[@TEST_NAME]]";

import Cpp library "method.h";

// The spelling that matches a `const` method: value `self`.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }

fn Test(g: Cpp.ConstGetter*) -> i32 {
  return CallGet(g);
}

// --- unmappable_param.h

// A one-candidate `Get` with the arity `HasGetN` requires, whose parameter
// type the importer cannot map (the param_unsupported.carbon shape).
struct BitGetter {
  int value;
  int Get(_BitInt(23) n) { return value; }
};

// --- fail_todo_probe_import_leak.carbon
library "[[@TEST_NAME]]";

import Cpp library "unmappable_param.h";

// R-7 residue (ledger W-144): member 1 is probed with `diagnose = false`; the
// shape checks pass (object member, one explicit parameter), the import runs
// and its type-mapping TODO leaks. Member 2 is selected regardless, so once
// the import honors `diagnose` this split loses its `fail_todo_` prefix.
template constraint HasGetN {
  fn Get(ref self, n: i32) -> i32;
}

overload fn Pick[template T: HasGetN](p: T*) -> i32 { return p->Get(1); }
overload fn Pick[template T: type](unused p: T*) -> i32 { return 0; }

fn Test(b: Cpp.BitGetter*) -> i32 {
  return Pick(b);
}
