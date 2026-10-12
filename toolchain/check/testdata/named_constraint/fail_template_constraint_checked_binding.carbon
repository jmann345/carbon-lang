// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon

// A `template constraint` can only constrain a `template` binding (fork
// decision F-010 / SC-1, fork/structural/plan.md D-SC-8(i)); a checked-generic
// self never satisfies one (D-SC-6, the conservative answer to leads issue
// 2153).

// --- fail_generic_binding.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

fn Bad(generic T: HasGet) {}

// --- fail_implicit_binding.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

fn Bad[T: HasGet](x: T) {}

// --- fail_implicit_binding_compound_use.carbon
library "[[@TEST_NAME]]";

// D-SC-6's cascade guard (review fold B7): after the binding is diagnosed, the
// use of `x` converts to `HasGet` without a second diagnostic because `T`'s own
// facet type already lists the requirement.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Bad[T: HasGet & I](x: T) -> i32 { return CallGet(x); }

// --- fail_symbolic_arg.carbon
library "[[@TEST_NAME]]";

template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  return CallGet(x);
}

// --- fail_require_in_interface_symbolic.carbon
library "[[@TEST_NAME]]";

// Structural requirements are not forwarded through an interface's `require`
// for a checked binding (D-SC-6, review fold B7; mirrors upstream's
// interface/require.carbon `fail_todo_implicit_self_impls`).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn G[T: I](x: T) -> i32 {
  return CallGet(x);
}

// --- fail_require_in_interface_blanket.carbon
library "[[@TEST_NAME]]";

// A CHECKED blanket impl of an interface that requires a template constraint is
// rejected at the `require` entry point (D-SC-8(iii)); no structural note is
// attached there (D-SC-9, review fold A5(ii)).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

impl forall [T: type] T as I {}
