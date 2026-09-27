// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/let/fail_let_else.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/let/fail_let_else.carbon

// `let`-`else` negatives (W-012): the else block must not complete normally
// (F-011a: its end must be unreachable — a nested `if` without `else` is
// rejected), the bindings are tombstoned through the else block, the form
// is function-body only (an abort, so its rows are split files), an
// irrefutable pattern warns, `LetDecl`'s modifier checks apply, `returned`
// is rejected, and the engine's scrutinee gate is shared.

// --- fail_empty_else.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  let .Some(n: i32) = o else {}
  return n;
}

// --- fail_else_ends_in_expr.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn G() {}

fn F(o: OptInt) -> i32 {
  let .Some(n: i32) = o else { G(); }
  return n;
}

// --- fail_else_partial_return.carbon
library "[[@TEST_NAME]]";

// The convergence block after a nested `if` without `else` is reachable
// from the false edge.
choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt, c: bool) -> i32 {
  let .Some(n: i32) = o else {
    if (c) {
      return 1;
    }
  }
  return n;
}

// --- fail_binding_used_in_else.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn Use(n: i32) {}

fn F(o: OptInt) -> i32 {
  let .Some(port: i32) = o else {
    Use(port);
    return -1;
  }
  return port;
}

// --- fail_file_scope.carbon
library "[[@TEST_NAME]]";

// Nothing after the `let` is checked: the diagnostic aborts the file.
let x: i32 = 1 else {}

fn F() -> i32 { return x; }

// --- fail_class_scope.carbon
library "[[@TEST_NAME]]";

class C {
  let x: i32 = 1 else {}
}

fn F() -> i32 { return C.x; }

// --- irrefutable.carbon
library "[[@TEST_NAME]]";

fn F(x: i32) -> i32 {
  let n: i32 = x else { return 0; }
  return n;
}

// --- fail_modifier_private.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(e: OptInt) -> i32 {
  private let .Some(n: i32) = e else { return -1; }
  return n;
}

// --- fail_modifier_virtual.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(e: OptInt) -> i32 {
  virtual let .Some(m: i32) = e else { return -1; }
  return m;
}

// --- fail_returned_var_else.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

fn F(o: OptInt) -> i32 {
  returned var .Some(v: i32) = o else { return 0; }
  return v;
}

// --- fail_todo_unsupported_scrutinee.carbon
library "[[@TEST_NAME]]";

class C {}

fn F(c: C) -> i32 {
  let n: C = c else { return 0; }
  return 1;
}

// --- fail_missing_initializer.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

// `let P else {...}` without `= e`: the design's grammar requires the
// initializer; diagnosed like a `let` without one, then the file aborts (the
// pattern's tombstones were never armed), so output is truncated.
fn F(o: OptInt) -> i32 {
  let .Some(n: i32) else { return 0; }
  return n;
}
