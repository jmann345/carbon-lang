// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/var_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/var_binding.carbon

// `var` case bindings (W-008 W8b): the bind pass emits per-arm `VarStorage`
// on demand in the arm's body block, so each arm gets its own object,
// initialized from the scrutinee where the arm has matched, never aliased
// across arms (docs/design/pattern_matching.md, "Pattern match control
// flow"). The binding is mutable and scoped to the arm's body and guard,
// extending fail_binding_scope's discipline.

// --- basic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(x: i32) -> i32 {
  match (x) {
    case var a: i32 => { a = a + 1; return a; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- guard.carbon
library "[[@TEST_NAME]]";

// The guard evaluates after the bind pass, with the arm's `var` storage
// initialized; a failed guard falls through to `default`.

//@dump-sem-ir-begin
fn G(x: i32) -> i32 {
  match (x) {
    case var a: i32 if (a > 2) => { return a; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- composition.carbon
library "[[@TEST_NAME]]";

// The design's composed shape (pattern_matching.md, "`var`":
// `case var (n: i32, m: i32)`): one `var` storage of tuple type, its
// elements bound elementwise.

//@dump-sem-ir-begin
fn H(p: (i32, i32)) -> i32 {
  match (p) {
    case var (a: i32, b: i32) => { a = a + b; return a; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- mixed_element.carbon
library "[[@TEST_NAME]]";

// The design's mixed shape (pattern_matching.md, "`var`":
// `case (var n: i32, 1)`): a `var` element is irrefutable, so the test
// pass prunes it — only the sibling literal contributes a condition — and
// the bind pass initializes the element's own storage.

//@dump-sem-ir-begin
fn M(p: (i32, i32)) -> i32 {
  match (p) {
    case (var n: i32, 1) => { n = n * 2; return n; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- fail_scope.carbon
library "[[@TEST_NAME]]";

// A `var` case binding is scoped to its own arm, exactly like a value case
// binding (fail_binding_scope.carbon).

fn S(x: i32) -> i32 {
  match (x) {
    case var a: i32 => { return a; }
    // CHECK:STDERR: fail_scope.carbon:[[@LINE+4]]:25: error: name `a` not found [NameNotFound]
    // CHECK:STDERR:     default => { return a; }
    // CHECK:STDERR:                         ^
    // CHECK:STDERR:
    default => { return a; }
  }
  return -1;
}

// --- fail_todo_refutable_var.carbon
library "[[@TEST_NAME]]";

// A `var` wrapping a refutable subtree is out of slice: the test pass
// cannot prune it without silently skipping the element tests, so it stays
// behind the W4 slice gate (W-008 plan §2.4).

fn R(p: (i32, i32)) -> i32 {
  match (p) {
    // CHECK:STDERR: fail_todo_refutable_var.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case var (5, a: i32) => { return 0; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
    case var (5, a: i32) => { return 0; }
    default => { return 0; }
  }
  return -1;
}
