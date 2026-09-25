// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/struct_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/struct_pattern.carbon

// Struct case patterns over struct scrutinees (W-077): fields are
// designated (`.a = 1`, `.b = b: i32`) or shorthand (`b: i32` means
// `.b = b: i32`), resolved name-keyed and order-free against the
// scrutinee's own struct type, with a trailing `_` discarding unmentioned
// scrutinee fields. The test pass compares refutable fields against the
// scrutinee's field types in pattern order and folds the conditions into
// one bool; bindings initialize in the bind pass, in the arm's body block.

// --- literal_scrutinee.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F() -> i32 {
  match ({.a = 1, .b = 2}) {
    case {.a = 1, .b = 2} => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- reordered_fields.carbon
library "[[@TEST_NAME]]";

// The design's own reorder example (docs/design/pattern_matching.md,
// "Struct patterns"): each field-pattern matches the same-named scrutinee
// element, so field order is free. Accesses are keyed by name and emitted
// in pattern order.
//@dump-sem-ir-begin
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.b = 2, .a = 1} => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- all_binding.carbon
library "[[@TEST_NAME]]";

// An all-binding struct arm is irrefutable and discharges exhaustiveness:
// no `default` arm is needed (W-078b integration).
//@dump-sem-ir-begin
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {a: i32, b: i32} => { return a + b; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- subset_discard.carbon
library "[[@TEST_NAME]]";

// Field-subset patterns with a trailing `_` (the design's discard rule):
// the second arm is irrefutable, so no `default` arm is needed.
//@dump-sem-ir-begin
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1, _} => { return 1; }
    case {b: i32, _} => { return b; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- all_fields_discard.carbon
library "[[@TEST_NAME]]";

// A trailing `_` is valid even when all fields are actually named
// (docs/design/pattern_matching.md, "Struct patterns").
//@dump-sem-ir-begin
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1, .b = 2, _} => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- mixed_shorthand.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1, b: i32} => { return b; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- nested.carbon
library "[[@TEST_NAME]]";

// Struct patterns nest with structs and tuples in either direction.
//@dump-sem-ir-begin
fn StructOfStruct(p: {.x: i32, .y: {.a: i32, .b: i32}}) -> i32 {
  match (p) {
    case {.y = {a: i32, b: i32}, _} => { return a + b; }
  }
  return -1;
}

fn StructOfTuple(p: {.x: i32, .y: (i32, i32)}) -> i32 {
  match (p) {
    case {.y = (a: i32, b: i32), _} => { return a + b; }
  }
  return -1;
}

fn TupleOfStruct(p: ({.x: i32, .y: i32}, i32)) -> i32 {
  match (p) {
    case ({x: i32, _}, 1) => { return x; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- field_var_ref.carbon
library "[[@TEST_NAME]]";

// Field-level `var` and `ref` bindings ride the landed leaf machinery: the
// `var` storage is the FIELD's scalar type (no aggregate conversion), and
// the `ref` binding aliases the scrutinee's field, which requires a
// durable-reference scrutinee (a `var` local here).
//@dump-sem-ir-begin
fn VarField(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = var n: i32, _} => { n = n + 1; return n; }
  }
  return -1;
}

fn RefField() -> i32 {
  var s: {.a: i32, .b: i32} = {.a = 1, .b = 2};
  match (s) {
    case {.a = ref r: i32, _} => { r = 7; return r; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- unused_field.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {unused a: i32, _} => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- empty_struct.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F() -> i32 {
  match ({}) {
    case {} => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- fail_unknown_field.carbon
library "[[@TEST_NAME]]";

// Every field name in the pattern must be a field name in the scrutinee
// (docs/design/pattern_matching.md, "Struct patterns").
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.c = 1} => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_missing_fields.carbon
library "[[@TEST_NAME]]";

// Unmentioned scrutinee fields are discarded only under a trailing `_`;
// without one they are an error naming the missing fields.
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1} => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_missing_fields_all_binding.carbon
library "[[@TEST_NAME]]";

// The shape checks run at the root even for wholly irrefutable patterns:
// the struct root always runs the engine, so an all-binding subset without
// `_` still diagnoses. No coverage is recorded (errored condition), so the
// `default` arm stays live and undiagnosed.
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {a: i32} => { return a; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_duplicate_field.carbon
library "[[@TEST_NAME]]";

// A duplicated field name either dead-constrains one scrutinee field twice
// or double-binds; diagnosed where the pattern inst is built (struct
// literal parity).
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1, .a = 2, _} => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_discard_without_fields.carbon
library "[[@TEST_NAME]]";

// Parse admits bare `{_}`, but the grammar's `_` production requires at
// least one preceding field (docs/design/pattern_matching.md).
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {_} => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_struct_nonexhaustive.carbon
library "[[@TEST_NAME]]";

// A struct scrutinee's value domain is open, so constant arms are never
// exhaustive: without an irrefutable arm, a `match` with no `default` is
// nonexhaustive outright (the W-078b open-domain lane, zero-code-change).
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = 1, .b = 2} => { return 1; }
  }
  return -1;
}

// --- fail_struct_of_bool_pairs.carbon
library "[[@TEST_NAME]]";

// The root-only open-domain record: a struct-of-two-bools' four values can
// no more be union-covered than `(bool, bool)`'s — only the bool ROOT rule
// is closed (W-076), so even enumerating all four constant pairs keeps the
// exhaustiveness requirement (the bool_pair_keeps_default twin, on the
// error side: no `default` here, so the match diagnoses).
fn G(p: {.x: bool, .y: bool}) -> i32 {
  match (p) {
    case {.x = false, .y = false} => { return 0; }
    case {.x = false, .y = true} => { return 1; }
    case {.x = true, .y = false} => { return 2; }
    case {.x = true, .y = true} => { return 3; }
  }
  return -1;
}

// --- fail_todo_non_struct_scrutinee.carbon
library "[[@TEST_NAME]]";

// A struct pattern against a non-struct scrutinee stays behind the W4
// slice-gate fallback in `MatchCase` — the root `else`, the tuple lane's
// exact precedent.
fn F(x: i32) -> i32 {
  match (x) {
    case {x: i32} => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_nested_non_struct.carbon
library "[[@TEST_NAME]]";

// A nested struct pattern against a non-struct element hits the same gate
// from inside the engine's walk. The all-binding subtree is pruned by the
// TEST pass (irrefutable), so the BIND pass emits the gate's diagnostic at
// the offending subpattern.
fn F(p: (i32, i32)) -> i32 {
  match (p) {
    case ({x: i32}, 1) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_payload_struct_subpattern.carbon
library "[[@TEST_NAME]]";

choice Opt {
  Some(x: i32),
  NoValue
}

// A struct subpattern in choice-payload position: the payload is
// irrefutable, so the bind dispatch's payload fast path must reroute to
// the match-bind walk (W-077 §1.8 — the unamended fast path was a
// compiler crash), whose non-struct-element stage diagnoses the W4 TODO
// at the subpattern.
fn F(o: Opt) -> i32 {
  match (o) {
    case .Some({v: i32}) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_var_struct.carbon
library "[[@TEST_NAME]]";

// A `var` wrapping a struct pattern is gated out (W-077 §1.5): the
// match-bind `var` storage would be typed by the pattern's own struct
// type, and for field subsets that conversion contradicts the design's
// discard rule. The test-pass gate fires at the introducer and aborts.
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case var {a: i32, b: i32} => { return a + b; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_nested_var_struct.carbon
library "[[@TEST_NAME]]";

// A NESTED irrefutable `var`-wrapping-struct element: the TEST pass prunes
// the whole element as irrefutable before any `VarPattern` pre-work runs,
// so only the match-bind `var` entry's gate (W-077 §1.5) stands between
// this arm and the wrong subset-typed storage conversion.
fn F(p: ({.a: i32, .b: i32}, i32)) -> i32 {
  match (p) {
    case (var {a: i32, _}, 1) => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_todo_var_struct_field.carbon
library "[[@TEST_NAME]]";

// The designated-field variant, which parse admits (`VariablePattern` is a
// struct-pattern field and a designated field's pattern is any pattern):
// the same match-bind `var` gate fires, at the subpattern.
fn F(p: {.x: i32, .y: {.b: i32}}) -> i32 {
  match (p) {
    case {.y = var {b: i32}, _} => { return 1; }
  }
  return -1;
}

// --- fail_todo_struct_constant_leaf.carbon
library "[[@TEST_NAME]]";

// A `let`-bound struct name in case position pins the NON-CONSTANT lane of
// the R9 gate: `let` bindings bind value-category results and are not
// constants, so the case expression stays behind the exact W-076-widened
// gate string. (A concrete `StructValue` leaf would stay behind the same
// gate by its admission logic — only `IntValue`/`BoolLiteral` concrete
// constants pass — but no in-slice vehicle for one was found; W-077 §1.9.)
fn F(p: {.a: i32, .b: i32}) -> i32 {
  let s: {.a: i32, .b: i32} = {.a = 1, .b = 2};
  match (p) {
    case s => { return 1; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_error_element_recovery.carbon
library "[[@TEST_NAME]]";

// An error-typed expression FIELD is below the arm's root, so it recovers:
// the NameNotFound poisons the arm's condition, and later arms are still
// checked.
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = undeclared, .b = 2} => { return 1; }
    case {.a = 1, .b = 2} => { return 2; }
    default => { return 0; }
  }
  return -1;
}

// --- fail_pruned_subtree_shape_error.carbon
library "[[@TEST_NAME]]";

// A wholly-irrefutable struct element inside a tuple arm: the TEST pass
// prunes it (it contributes no condition and never shape-checks it), so
// the BIND pass — which would otherwise silently bind nothing — emits the
// missing-fields diagnostic at the subpattern (the tuple
// fail_pruned_subtree_shape_error twin).
fn F(p: (i32, {.x: i32, .y: i32})) -> i32 {
  match (p) {
    case (n: i32, {x: i32}) => { return n; }
  }
  return -1;
}

// --- fail_ref_binding_value_scrutinee_field.carbon
library "[[@TEST_NAME]]";

// A `ref` field binding against a value scrutinee is a real error, not a
// TODO: the scrutinee must itself be a durable reference, and the standard
// conversion machinery owns the diagnostic (W8b parity).
fn F(p: {.a: i32, .b: i32}) -> i32 {
  match (p) {
    case {.a = ref r: i32, _} => { return r; }
  }
  return -1;
}
