// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/template_constraint_require.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/template_constraint_require.carbon

// `require impls` and `template constraint`s (fork decision F-010 / SC-1,
// fork/structural/plan.md D-SC-8(iii), D-SC-19): nominal and structural
// requirements compose, a concrete `impl` of an interface requiring a template
// constraint is checked at the `require` entry point, and a TEMPLATE blanket
// impl is deferred there.

// --- require_in_template.carbon
library "[[@TEST_NAME]]";

template constraint Both {
  fn Get(self) -> i32;
  require impls Core.Destroy;
}

class C {
  // CHECK:STDERR: require_in_template.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(self) -> i32 { return 1; }
}

fn CallGet[template T: Both](x: T) -> i32 { return x.Get(); }

fn Test(c: C) -> i32 { return CallGet(c); }

// --- require_in_interface_concrete.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

class C {
  // CHECK:STDERR: require_in_interface_concrete.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Get(self) -> i32 { return 1; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Get(self) -> i32 { return 1; }
}

impl C as I {}

// --- require_in_interface_template_blanket.carbon
library "[[@TEST_NAME]]";

// The template-phase self is deferred at the `require` entry point (D-SC-19),
// and the specific `Lacking as I` resolves through the blanket impl with no
// re-check: this split PINS the SC-1 gap named in D-SC-19 and §1.G.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

impl forall [template T: type] T as I {}

class Lacking {}

// CHECK:STDERR: require_in_interface_template_blanket.carbon:[[@LINE+4]]:14: warning: binding `x` unused [UnusedBinding]
// CHECK:STDERR: fn Use[U: I](x: U) {}
// CHECK:STDERR:              ^~~~
// CHECK:STDERR:
fn Use[U: I](x: U) {}

fn Test(l: Lacking) { Use(l); }
