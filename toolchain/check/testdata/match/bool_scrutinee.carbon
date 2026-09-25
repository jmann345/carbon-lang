// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/bool_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/bool_scrutinee.carbon

// Bool scrutinees (W-076): the design treats `bool` like a choice type
// whose alternatives are `false` and `true`
// (docs/design/pattern_matching.md), so `case true`/`case false` dispatch
// through the expression-pattern `==` lane (`bool as EqWith(Self)`, hence
// the full prelude) and covering both values discharges the `default`
// requirement.

// --- exhaustive.carbon
library "[[@TEST_NAME]]";

// The design's own worked example shape (pattern_matching.md, `IsTrue`):
// `case false` + `case true` with no `default` is considered exhaustive.
// CAVEAT: the design also marks code after such a match unreachable; that
// half is not delivered — the resumption block stays CFG-reachable, so
// the trailing `return` is required, parity with exhaustive_choice
// .carbon's trailing `return -1;` (shared pre-existing residue, not
// W-076 scope).
//@dump-sem-ir-begin
fn IsTrue(b: bool) -> i32 {
  match (b) {
    case false => { return 0; }
    case true => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- with_default.carbon
library "[[@TEST_NAME]]";

// One value covered plus `default`: `has_default` short-circuits the
// exhaustiveness check, no bool-specific code runs.
//@dump-sem-ir-begin
fn F(b: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- constant_expr_case.carbon
library "[[@TEST_NAME]]";

// A constant bool expression `case` classifies by its evaluated constant
// (a concrete `BoolLiteral`), never its syntax: `case 1 == 1` covers
// `true` (eval's builtin `IntLiteral` comparison folds it), and together
// with `case false` the match is exhaustive without `default`.
//@dump-sem-ir-begin
fn G(b: bool) -> i32 {
  match (b) {
    case 1 == 1 => { return 1; }
    case false => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- constant_scrutinee.carbon
library "[[@TEST_NAME]]";

// A constant bool scrutinee: each arm's comparison constant-folds through
// eval's builtin `bool.eq` (`BuiltinFunctionKind::BoolEq`), mirroring
// match/constant_scrutinee.carbon's integer shape.
//@dump-sem-ir-begin
fn H() -> i32 {
  match (true) {
    case false => { return 0; }
    case true => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- compose.carbon
library "[[@TEST_NAME]]";

// Guards and binding arms compose with a bool scrutinee for free: the
// guarded arm records nothing toward coverage (every guard can fail), the
// binding arm is irrefutable, and the `default` arm stays accepted.
//@dump-sem-ir-begin
fn Compose(b: bool, c: bool) -> i32 {
  match (b) {
    case true if (c) => { return 2; }
    case b2: bool => { if (b2) { return 1; } return 0; }
    default => { return -2; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- var_ref_binding.carbon
library "[[@TEST_NAME]]";

// `var` and `ref` case bindings on a bool scrutinee ride the W8b
// machinery unchanged: per-arm `var` storage, and a `ref` binding
// aliasing a durable scrutinee.
//@dump-sem-ir-begin
fn VarBinding(b: bool) -> i32 {
  match (b) {
    case var v: bool => { v = false; if (v) { return 1; } return 0; }
    default => { return -2; }
  }
  return -1;
}

fn RefBinding() -> i32 {
  var x: bool = true;
  match (x) {
    case ref r: bool => { r = false; }
    default => { return -2; }
  }
  if (x) { return 1; }
  return 0;
}
//@dump-sem-ir-end

// --- order.carbon
library "[[@TEST_NAME]]";

// Coverage is order-irrelevant: `case true` first, then `case false`, is
// exhaustive the same way exhaustive.carbon's domain order is.
//@dump-sem-ir-begin
fn TrueFirst(b: bool) -> i32 {
  match (b) {
    case true => { return 1; }
    case false => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end
