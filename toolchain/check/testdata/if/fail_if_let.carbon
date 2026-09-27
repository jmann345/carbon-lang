// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/if/fail_if_let.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/if/fail_if_let.carbon

// Pattern-condition negatives (W-012): scoping (the bindings are visible in
// the then-block only), the irrefutable-pattern warning, the reserved
// `and`/`or` chain, the tombstoned initializer, late alternative resolution
// with the `match` diagnostics, `?` in a binding's type, and the engine's
// slice gates reached through the shared context (each an abort, so one row
// per split file).

// --- fail_binding_in_else.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn Use(n: i32) {}

fn F(o: OptInt) {
  if (let .Some(n: i32) = o) {
    Use(n);
  } else {
    Use(n);
  }
}

// --- fail_binding_after.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn Use(n: i32) {}

fn F(o: OptInt) {
  if (let .Some(n: i32) = o) {
    Use(n);
  }
  Use(n);
}

// --- fail_binding_in_else_if_condition.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn Use(n: i32) {}

fn F(o: OptInt) {
  if (let .Some(n: i32) = o) {
    Use(n);
  } else if (n > 0) {
  }
}

// --- irrefutable_binding.carbon
library "[[@TEST_NAME]]";

// A binding root cannot fail: a warning, not an error.
fn Use(n: i32) {}

fn F(x: i32) {
  if (let n: i32 = x) {
    Use(n);
  }
}

// --- irrefutable_single_alternative.carbon
library "[[@TEST_NAME]]";

// A single-alternative choice's alternative with an all-binding payload
// cannot fail either (the test is a constant `true`).
choice Only {
  Just(x: i32)
}

fn Use(n: i32) {}

fn F(o: Only) {
  if (let .Just(n: i32) = o) {
    Use(n);
  }
}

// --- fail_chain_reserved.carbon
library "[[@TEST_NAME]]";

fn F(x: bool, y: bool) {
  if (let true = x and y) {
  }
}

// --- fail_binding_in_initializer.carbon
library "[[@TEST_NAME]]";

// The bindings are tombstoned while the initializer is checked; the errored
// initializer then fails the scrutinee gate.
fn Use(n: i32) {}

fn F() {
  if (let n: i32 = n) {
    Use(n);
  }
}

// --- fail_unknown_alternative.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  if (let .Nope = opt) {
  }
}

// --- fail_missing_parens.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  if (let .Some = opt) {
  }
}

// --- fail_unexpected_parens.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  if (let .None(1) = opt) {
  }
}

// --- fail_arg_count.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  if (let .Some(1, 2) = opt) {
  }
}

// --- unused_binding.carbon
library "[[@TEST_NAME]]";

// An unused if-let binding warns at the if-let scope's pop, like any local.
choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  if (let .Some(n: i32) = opt) {
  }
}

// --- fail_question_in_pattern_type.carbon
library "[[@TEST_NAME]]";

// `?` inside the pattern (a binding's type expression) is at region depth
// greater than 1 and stays banned.
choice OptInt {
  Some(x: i32),
  None
}

fn F() -> i32 { return 0; }

fn G(opt: OptInt) -> i32 {
  if (let .Some(n: F()?) = opt) {
    return n;
  }
  return 0;
}

// --- fail_todo_unsupported_scrutinee.carbon
library "[[@TEST_NAME]]";

class C {}

fn F(c: C) {
  if (let n: C = c) {
  }
}

// --- fail_todo_binding_free_var.carbon
library "[[@TEST_NAME]]";

fn F(x: i32) {
  if (var 5 = x) {
  }
}

// --- fail_todo_var_bare_alternative.carbon
library "[[@TEST_NAME]]";

// `var` on a binding-free pattern has no storage to name: the empty
// synthetic payload root of a bare `.None` hits the binding-free-`var` gate
// at pattern time (fork/w012/plan.md §1.1).
choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  if (var .None = opt) {
  }
}

// --- fail_todo_var_refutable_tuple.carbon
library "[[@TEST_NAME]]";

// A `var` root over a refutable subtree stays behind the engine's slice
// gate, in a pattern condition as in a `case`.
fn F(pair: (i32, i32)) {
  if (var (0, n: i32) = pair) {
  }
}

// --- fail_todo_form_binding.carbon
library "[[@TEST_NAME]]";

fn F(x: i32) {
  if (let n:? form(var i32) = x) {
  }
}

// --- fail_todo_compile_time_binding.carbon
library "[[@TEST_NAME]]";

fn F(x: i32) {
  if (let template n: i32 = x) {
  }
}

// --- fail_todo_qualified_alternative.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(opt: OptInt) {
  if (let OptInt.None = opt) {
  }
}

// --- fail_incomplete_scrutinee.carbon
library "[[@TEST_NAME]]";

class C;

fn F(p: C*) {
  if (let .Some(n: i32) = *p) {
  }
}
