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
    // CHECK:STDERR: fail_unknown_field.carbon:[[@LINE+4]]:16: error: struct pattern field `c` is not a field of the match scrutinee's type `{.a: i32, .b: i32}` [MatchCaseStructPatternUnknownField]
    // CHECK:STDERR:     case {.c = 1} => { return 1; }
    // CHECK:STDERR:                ^
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_missing_fields.carbon:[[@LINE+4]]:10: error: struct pattern has no trailing `_` and does not name field `b` of the match scrutinee's type `{.a: i32, .b: i32}` [MatchCaseStructPatternMissingFields]
    // CHECK:STDERR:     case {.a = 1} => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_missing_fields_all_binding.carbon:[[@LINE+4]]:10: error: struct pattern has no trailing `_` and does not name field `b` of the match scrutinee's type `{.a: i32, .b: i32}` [MatchCaseStructPatternMissingFields]
    // CHECK:STDERR:     case {a: i32} => { return a; }
    // CHECK:STDERR:          ^~~~~~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_duplicate_field.carbon:[[@LINE+7]]:24: error: duplicated field name `a` in struct pattern [StructPatternNameDuplicate]
    // CHECK:STDERR:     case {.a = 1, .a = 2, _} => { return 1; }
    // CHECK:STDERR:                        ^
    // CHECK:STDERR: fail_duplicate_field.carbon:[[@LINE+4]]:16: note: field with the same name here [StructPatternNamePrevious]
    // CHECK:STDERR:     case {.a = 1, .a = 2, _} => { return 1; }
    // CHECK:STDERR:                ^
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_discard_without_fields.carbon:[[@LINE+4]]:10: error: `_` in a struct pattern requires at least one named field before it [StructPatternDiscardWithoutFields]
    // CHECK:STDERR:     case {_} => { return 1; }
    // CHECK:STDERR:          ^~~
    // CHECK:STDERR:
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
  // CHECK:STDERR: fail_struct_nonexhaustive.carbon:[[@LINE+4]]:3: error: `match` on `{.a: i32, .b: i32}` has no `default` arm and no `case` arm that matches every value [MatchNonexhaustiveNoIrrefutableArm]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
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
  // CHECK:STDERR: fail_struct_of_bool_pairs.carbon:[[@LINE+4]]:3: error: `match` on `{.x: bool, .y: bool}` has no `default` arm and no `case` arm that matches every value [MatchNonexhaustiveNoIrrefutableArm]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
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
    // CHECK:STDERR: fail_todo_non_struct_scrutinee.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case {x: i32} => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_todo_nested_non_struct.carbon:[[@LINE+8]]:11: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case ({x: i32}, 1) => { return 1; }
    // CHECK:STDERR:           ^~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_todo_nested_non_struct.carbon:[[@LINE+4]]:12: warning: binding `x` unused [UnusedBinding]
    // CHECK:STDERR:     case ({x: i32}, 1) => { return 1; }
    // CHECK:STDERR:            ^~~~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_todo_payload_struct_subpattern.carbon:[[@LINE+8]]:16: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case .Some({v: i32}) => { return 1; }
    // CHECK:STDERR:                ^~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_todo_payload_struct_subpattern.carbon:[[@LINE+4]]:17: warning: binding `v` unused [UnusedBinding]
    // CHECK:STDERR:     case .Some({v: i32}) => { return 1; }
    // CHECK:STDERR:                 ^~~~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_todo_var_struct.carbon:[[@LINE+4]]:5: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case var {a: i32, b: i32} => { return a + b; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_todo_nested_var_struct.carbon:[[@LINE+8]]:11: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case (var {a: i32, _}, 1) => { return 1; }
    // CHECK:STDERR:           ^~~~~~~~~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_todo_nested_var_struct.carbon:[[@LINE+4]]:16: warning: binding `a` unused [UnusedBinding]
    // CHECK:STDERR:     case (var {a: i32, _}, 1) => { return 1; }
    // CHECK:STDERR:                ^~~~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_todo_var_struct_field.carbon:[[@LINE+8]]:16: error: semantics TODO: `match `case` pattern other than an integer literal, or a case guard` [SemanticsTodo]
    // CHECK:STDERR:     case {.y = var {b: i32}, _} => { return 1; }
    // CHECK:STDERR:                ^~~~~~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_todo_var_struct_field.carbon:[[@LINE+4]]:21: warning: binding `b` unused [UnusedBinding]
    // CHECK:STDERR:     case {.y = var {b: i32}, _} => { return 1; }
    // CHECK:STDERR:                     ^~~~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_todo_struct_constant_leaf.carbon:[[@LINE+4]]:5: error: semantics TODO: `match case expression pattern that is not a constant integer or `bool`` [SemanticsTodo]
    // CHECK:STDERR:     case s => { return 1; }
    // CHECK:STDERR:     ^~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_error_element_recovery.carbon:[[@LINE+4]]:16: error: name `undeclared` not found [NameNotFound]
    // CHECK:STDERR:     case {.a = undeclared, .b = 2} => { return 1; }
    // CHECK:STDERR:                ^~~~~~~~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_pruned_subtree_shape_error.carbon:[[@LINE+8]]:19: error: struct pattern has no trailing `_` and does not name field `y` of the match scrutinee's type `{.x: i32, .y: i32}` [MatchCaseStructPatternMissingFields]
    // CHECK:STDERR:     case (n: i32, {x: i32}) => { return n; }
    // CHECK:STDERR:                   ^~~~~~~~
    // CHECK:STDERR:
    // CHECK:STDERR: fail_pruned_subtree_shape_error.carbon:[[@LINE+4]]:20: warning: binding `x` unused [UnusedBinding]
    // CHECK:STDERR:     case (n: i32, {x: i32}) => { return n; }
    // CHECK:STDERR:                    ^~~~~~
    // CHECK:STDERR:
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
  // CHECK:STDERR: fail_ref_binding_value_scrutinee_field.carbon:[[@LINE+4]]:10: error: cannot bind durable reference to non-reference value of type `i32` [ConversionFailureNonRefToRef]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  match (p) {
    case {.a = ref r: i32, _} => { return r; }
  }
  return -1;
}

// CHECK:STDOUT: --- literal_scrutinee.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %struct_type.a.b: type = struct_type {.a: Core.IntLiteral, .b: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.a.b = struct_value (%int_1.5b8, %int_2) [concrete]
// CHECK:STDOUT:   %pattern_type.39a: type = pattern_type %struct_type.a.b [concrete]
// CHECK:STDOUT:   %.93a: %pattern_type.39a = struct_pattern (@F.%expr_patt.loc6_16, @F.%expr_patt.loc6_24), false [concrete]
// CHECK:STDOUT:   %EqWith.type.aee: type = facet_type <@EqWith, @EqWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness: <witness> = impl_witness imports.%EqWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %EqWith.facet: %EqWith.type.aee = facet_value Core.IntLiteral, (%EqWith.impl_witness) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.4b8: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(Core.IntLiteral, %EqWith.facet) [concrete]
// CHECK:STDOUT:   %.afe: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.4b8, %EqWith.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.type: type = fn_type @Core.IntLiteral.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal: %Core.IntLiteral.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.bound.75f: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.bound.313: <bound method> = bound_method %int_2, %Core.IntLiteral.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a87: %Core.IntLiteral.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @Core.IntLiteral.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_1.loc5: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2.loc5: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_25.1: %struct_type.a.b = struct_literal (%int_1.loc5, %int_2.loc5) [concrete = constants.%struct]
// CHECK:STDOUT:   %struct: %struct_type.a.b = struct_value (%int_1.loc5, %int_2.loc5) [concrete = constants.%struct]
// CHECK:STDOUT:   %.loc5_25.2: %struct_type.a.b = converted %.loc5_25.1, %struct [concrete = constants.%struct]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc6_16: %pattern_type.dc0 = expr_pattern %int_1.loc6_16 in [concrete] {
// CHECK:STDOUT:       %int_1.loc6_16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc6_24: %pattern_type.dc0 = expr_pattern %int_2.loc6 in [concrete] {
// CHECK:STDOUT:       %int_2.loc6: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc6_25: %pattern_type.39a = struct_pattern (%expr_patt.loc6_16, %expr_patt.loc6_24), false [concrete = constants.%.93a]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc5_25.3: Core.IntLiteral = struct_access %.loc5_25.2, element0 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc5_25.4: Core.IntLiteral = struct_access %.loc5_25.2, element1 [concrete = constants.%int_2]
// CHECK:STDOUT:   %int_1.loc6_16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_27.1: %.afe = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc6_27.1: <bound method> = bound_method %int_1.loc6_16, %impl.elem0.loc6_27.1 [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal.bound.75f]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_27.1: init bool = call %bound_method.loc6_27.1(%int_1.loc6_16, %.loc5_25.3) [concrete = constants.%true]
// CHECK:STDOUT:   %.loc6_27.1: bool = value_of_initializer %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_27.1 [concrete = constants.%true]
// CHECK:STDOUT:   %.loc6_27.2: bool = converted %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_27.1, %.loc6_27.1 [concrete = constants.%true]
// CHECK:STDOUT:   %int_2.loc6: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem0.loc6_27.2: %.afe = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc6_27.2: <bound method> = bound_method %int_2.loc6, %impl.elem0.loc6_27.2 [concrete = constants.%Core.IntLiteral.as.EqWith.impl.Equal.bound.313]
// CHECK:STDOUT:   %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_27.2: init bool = call %bound_method.loc6_27.2(%int_2.loc6, %.loc5_25.4) [concrete = constants.%true]
// CHECK:STDOUT:   %.loc6_27.3: bool = value_of_initializer %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_27.2 [concrete = constants.%true]
// CHECK:STDOUT:   %.loc6_27.4: bool = converted %Core.IntLiteral.as.EqWith.impl.Equal.call.loc6_27.2, %.loc6_27.3 [concrete = constants.%true]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc6_27.2 br !match.case.then.loc6_27.1 else br !match.<unexpected BranchWithArg>(%false)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc6_27.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>(%.loc6_27.4)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>:
// CHECK:STDOUT:   %.loc6_27.5: bool = block_arg !match.<unexpected BranchWithArg> [concrete = constants.%true]
// CHECK:STDOUT:   if %.loc6_27.5 br !match.case.then.loc6_27.2 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc6_27.2:
// CHECK:STDOUT:   %int_1.loc6_39: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_40: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_40.1: <bound method> = bound_method %int_1.loc6_39, %impl.elem0.loc6_40 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6: <specific function> = specific_function %impl.elem0.loc6_40, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_40.2: <bound method> = bound_method %int_1.loc6_39, %specific_fn.loc6 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6: init %i32 = call %bound_method.loc6_40.2(%int_1.loc6_39) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_40: init %i32 = converted %int_1.loc6_39, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc6_40
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc7: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc7_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc7 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_26.2: <bound method> = bound_method %int_0, %specific_fn.loc7 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %i32 = call %bound_method.loc7_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc7: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- reordered_fields.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.20e3: type = pattern_type %struct_type.a.b [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %struct_type.b.a: type = struct_type {.b: Core.IntLiteral, .a: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %pattern_type.50c: type = pattern_type %struct_type.b.a [concrete]
// CHECK:STDOUT:   %.2bc: %pattern_type.50c = struct_pattern (@F.%expr_patt.loc10_16, @F.%expr_patt.loc10_24), false [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.811140.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.ee93db.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.811140.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.ee93db.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8_32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_32: Core.Form = init_form %i32.loc8_32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %struct_type.a.b = value_param call_param0
// CHECK:STDOUT:     %.loc8_26: type = splice_block %struct_type.a.b [concrete = constants.%struct_type.a.b] {
// CHECK:STDOUT:       %i32.loc8_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc8_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %struct_type.a.b = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %struct_type.a.b) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %struct_type.a.b = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc10_16: %pattern_type.dc0 = expr_pattern %int_2 in [concrete] {
// CHECK:STDOUT:       %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc10_24: %pattern_type.dc0 = expr_pattern %int_1.loc10_24 in [concrete] {
// CHECK:STDOUT:       %int_1.loc10_24: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc10_25: %pattern_type.50c = struct_pattern (%expr_patt.loc10_16, %expr_patt.loc10_24), false [concrete = constants.%.2bc]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc9_10.1: %i32 = struct_access %p.ref, element1
// CHECK:STDOUT:   %.loc9_10.2: %i32 = struct_access %p.ref, element0
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc10_27.1: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc10_27.1: <bound method> = bound_method %int_2, %impl.elem0.loc10_27.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.811140.1]
// CHECK:STDOUT:   %specific_fn.loc10_27.1: <specific function> = specific_function %impl.elem0.loc10_27.1, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc10_27.2: <bound method> = bound_method %int_2, %specific_fn.loc10_27.1 [concrete = constants.%bound_method.ee93db.1]
// CHECK:STDOUT:   %.loc10_27.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc10_27.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc10_27.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc10_27.1: <bound method> = bound_method %int_2, %Equal.ref.loc10_27.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.811140.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc10_27.1: <specific function> = specific_function %Equal.ref.loc10_27.1, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc10_27.3: <bound method> = bound_method %int_2, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc10_27.1 [concrete = constants.%bound_method.ee93db.2]
// CHECK:STDOUT:   %impl.elem0.loc10_16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_16.1: <bound method> = bound_method %int_2, %impl.elem0.loc10_16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc10_16: <specific function> = specific_function %impl.elem0.loc10_16, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_16.2: <bound method> = bound_method %int_2, %specific_fn.loc10_16 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_16: init %i32 = call %bound_method.loc10_16.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc10_16.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_16 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc10_16.2: %i32 = converted %int_2, %.loc10_16.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc10_27.1: init bool = call %bound_method.loc10_27.3(%.loc10_16.2, %.loc9_10.1)
// CHECK:STDOUT:   %.loc10_27.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc10_27.1
// CHECK:STDOUT:   %.loc10_27.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc10_27.1, %.loc10_27.2
// CHECK:STDOUT:   %int_1.loc10_24: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc10_27.2: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc10_27.4: <bound method> = bound_method %int_1.loc10_24, %impl.elem0.loc10_27.2 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc10_27.2: <specific function> = specific_function %impl.elem0.loc10_27.2, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc10_27.5: <bound method> = bound_method %int_1.loc10_24, %specific_fn.loc10_27.2 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc10_27.4: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc10_27.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc10_27.4 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc10_27.2: <bound method> = bound_method %int_1.loc10_24, %Equal.ref.loc10_27.2 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc10_27.2: <specific function> = specific_function %Equal.ref.loc10_27.2, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc10_27.6: <bound method> = bound_method %int_1.loc10_24, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc10_27.2 [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc10_24: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_24.1: <bound method> = bound_method %int_1.loc10_24, %impl.elem0.loc10_24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc10_24: <specific function> = specific_function %impl.elem0.loc10_24, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_24.2: <bound method> = bound_method %int_1.loc10_24, %specific_fn.loc10_24 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_24: init %i32 = call %bound_method.loc10_24.2(%int_1.loc10_24) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_24.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_24 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_24.2: %i32 = converted %int_1.loc10_24, %.loc10_24.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc10_27.2: init bool = call %bound_method.loc10_27.6(%.loc10_24.2, %.loc9_10.2)
// CHECK:STDOUT:   %.loc10_27.5: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc10_27.2
// CHECK:STDOUT:   %.loc10_27.6: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc10_27.2, %.loc10_27.5
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc10_27.3 br !match.case.then.loc10_27.1 else br !match.<unexpected BranchWithArg>(%false)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc10_27.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>(%.loc10_27.6)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>:
// CHECK:STDOUT:   %.loc10_27.7: bool = block_arg !match.<unexpected BranchWithArg>
// CHECK:STDOUT:   if %.loc10_27.7 br !match.case.then.loc10_27.2 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc10_27.2:
// CHECK:STDOUT:   %int_1.loc10_39: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc10_40: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_40.1: <bound method> = bound_method %int_1.loc10_39, %impl.elem0.loc10_40 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc10_40: <specific function> = specific_function %impl.elem0.loc10_40, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_40.2: <bound method> = bound_method %int_1.loc10_39, %specific_fn.loc10_40 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_40: init %i32 = call %bound_method.loc10_40.2(%int_1.loc10_39) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_40: init %i32 = converted %int_1.loc10_39, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_40 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc10_40
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_26.2: <bound method> = bound_method %int_0, %specific_fn.loc11 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc11: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- all_binding.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.20e3: type = pattern_type %struct_type.a.b [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %.fdf: %pattern_type.20e3 = struct_pattern (%a.patt, %b.patt), false [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc6_32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc6_32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_32: Core.Form = init_form %i32.loc6_32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %struct_type.a.b = value_param call_param0
// CHECK:STDOUT:     %.loc6_26: type = splice_block %struct_type.a.b [concrete = constants.%struct_type.a.b] {
// CHECK:STDOUT:       %i32.loc6_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc6_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %struct_type.a.b = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %struct_type.a.b) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %struct_type.a.b = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc8: %pattern_type.20e3 = struct_pattern (%a.patt, %b.patt), false [concrete = constants.%.fdf]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc7_10.1: %i32 = struct_access %p.ref, element0
// CHECK:STDOUT:   %.loc7_10.2: %i32 = struct_access %p.ref, element1
// CHECK:STDOUT:   %i32.loc8_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %a: %i32 = wrapper_binding a, %.loc7_10.1
// CHECK:STDOUT:   %i32.loc8_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %.loc7_10.2
// CHECK:STDOUT:   %a.ref: %i32 = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem1.loc8: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc8_41.1: <bound method> = bound_method %a.ref, %impl.elem1.loc8
// CHECK:STDOUT:   %specific_fn.loc8: <specific function> = specific_function %impl.elem1.loc8, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc8_41.2: <bound method> = bound_method %a.ref, %specific_fn.loc8
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc8_41.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %impl.elem1.loc10: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc10_10: <bound method> = bound_method %int_1, %impl.elem1.loc10 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc10_10(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc10 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %.loc10_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc10_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc10_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc10_12.2(%.loc10_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc10_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc10_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- subset_discard.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.20e3: type = pattern_type %struct_type.a.b [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %struct_type.a: type = struct_type {.a: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %pattern_type.31b: type = pattern_type %struct_type.a [concrete]
// CHECK:STDOUT:   %.05e: %pattern_type.31b = struct_pattern (@F.%expr_patt), true [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %struct_type.b: type = struct_type {.b: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.b29: type = pattern_type %struct_type.b [concrete]
// CHECK:STDOUT:   %.1bc: %pattern_type.b29 = struct_pattern (%b.patt), true [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc6_32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc6_32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_32: Core.Form = init_form %i32.loc6_32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %struct_type.a.b = value_param call_param0
// CHECK:STDOUT:     %.loc6_26: type = splice_block %struct_type.a.b [concrete = constants.%struct_type.a.b] {
// CHECK:STDOUT:       %i32.loc6_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc6_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %struct_type.a.b = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %struct_type.a.b) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %struct_type.a.b = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.dc0 = expr_pattern %int_1.loc8_16 in [concrete] {
// CHECK:STDOUT:       %int_1.loc8_16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc8_20: %pattern_type.31b = struct_pattern (%expr_patt), true [concrete = constants.%.05e]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc7_10.1: %i32 = struct_access %p.ref, element0
// CHECK:STDOUT:   %int_1.loc8_16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc8_22: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc8_22.1: <bound method> = bound_method %int_1.loc8_16, %impl.elem0.loc8_22 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc8_22: <specific function> = specific_function %impl.elem0.loc8_22, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc8_22.2: <bound method> = bound_method %int_1.loc8_16, %specific_fn.loc8_22 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc8_22.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc8_22.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.loc8_16, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc8_22.3: <bound method> = bound_method %int_1.loc8_16, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc8_16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_16.1: <bound method> = bound_method %int_1.loc8_16, %impl.elem0.loc8_16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc8_16: <specific function> = specific_function %impl.elem0.loc8_16, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_16.2: <bound method> = bound_method %int_1.loc8_16, %specific_fn.loc8_16 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_16: init %i32 = call %bound_method.loc8_16.2(%int_1.loc8_16) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_16.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_16 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_16.2: %i32 = converted %int_1.loc8_16, %.loc8_16.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc8_22.3(%.loc8_16.2, %.loc7_10.1)
// CHECK:STDOUT:   %.loc8_22.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc8_22.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc8_22.2
// CHECK:STDOUT:   if %.loc8_22.3 br !match.case.then.loc8 else br !match.case.else.loc8
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc8:
// CHECK:STDOUT:   %int_1.loc8_34: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc8_35: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_35.1: <bound method> = bound_method %int_1.loc8_34, %impl.elem0.loc8_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc8_35: <specific function> = specific_function %impl.elem0.loc8_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_35.2: <bound method> = bound_method %int_1.loc8_34, %specific_fn.loc8_35 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_35: init %i32 = call %bound_method.loc8_35.2(%int_1.loc8_34) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_35: init %i32 = converted %int_1.loc8_34, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_35 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc8_35
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc8:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc9: %pattern_type.b29 = struct_pattern (%b.patt), true [concrete = constants.%.1bc]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then.loc9 else br !match.case.else.loc9
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc9:
// CHECK:STDOUT:   %.loc7_10.2: %i32 = struct_access %p.ref, element1
// CHECK:STDOUT:   %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %.loc7_10.2
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0.loc9: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc9_34.1: <bound method> = bound_method %b.ref, %impl.elem0.loc9
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_34.2: <bound method> = bound_method %b.ref, %specific_fn.loc9
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc9_34.2(%b.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc9:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc11: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc11_10: <bound method> = bound_method %int_1.loc11, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc11_10(%int_1.loc11) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc11 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc11_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc11_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc11_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_12.2(%.loc11_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc11_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc11_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- all_fields_discard.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b.b4c: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.20e3: type = pattern_type %struct_type.a.b.b4c [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %struct_type.a.b.cfd: type = struct_type {.a: Core.IntLiteral, .b: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %pattern_type.39a: type = pattern_type %struct_type.a.b.cfd [concrete]
// CHECK:STDOUT:   %.68d: %pattern_type.39a = struct_pattern (@F.%expr_patt.loc8_16, @F.%expr_patt.loc8_24), true [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.811140.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %bound_method.ee93db.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.811140.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %bound_method.ee93db.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc6_32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc6_32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_32: Core.Form = init_form %i32.loc6_32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %struct_type.a.b.b4c = value_param call_param0
// CHECK:STDOUT:     %.loc6_26: type = splice_block %struct_type.a.b [concrete = constants.%struct_type.a.b.b4c] {
// CHECK:STDOUT:       %i32.loc6_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc6_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b.b4c]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %struct_type.a.b.b4c = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %struct_type.a.b.b4c) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %struct_type.a.b.b4c = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc8_16: %pattern_type.dc0 = expr_pattern %int_1.loc8_16 in [concrete] {
// CHECK:STDOUT:       %int_1.loc8_16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc8_24: %pattern_type.dc0 = expr_pattern %int_2 in [concrete] {
// CHECK:STDOUT:       %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc8_28: %pattern_type.39a = struct_pattern (%expr_patt.loc8_16, %expr_patt.loc8_24), true [concrete = constants.%.68d]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc7_10.1: %i32 = struct_access %p.ref, element0
// CHECK:STDOUT:   %.loc7_10.2: %i32 = struct_access %p.ref, element1
// CHECK:STDOUT:   %int_1.loc8_16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc8_30.1: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc8_30.1: <bound method> = bound_method %int_1.loc8_16, %impl.elem0.loc8_30.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc8_30.1: <specific function> = specific_function %impl.elem0.loc8_30.1, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc8_30.2: <bound method> = bound_method %int_1.loc8_16, %specific_fn.loc8_30.1 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc8_30.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc8_30.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc8_30.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc8_30.1: <bound method> = bound_method %int_1.loc8_16, %Equal.ref.loc8_30.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc8_30.1: <specific function> = specific_function %Equal.ref.loc8_30.1, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc8_30.3: <bound method> = bound_method %int_1.loc8_16, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc8_30.1 [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc8_16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_16.1: <bound method> = bound_method %int_1.loc8_16, %impl.elem0.loc8_16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc8_16: <specific function> = specific_function %impl.elem0.loc8_16, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_16.2: <bound method> = bound_method %int_1.loc8_16, %specific_fn.loc8_16 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_16: init %i32 = call %bound_method.loc8_16.2(%int_1.loc8_16) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_16.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_16 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_16.2: %i32 = converted %int_1.loc8_16, %.loc8_16.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc8_30.1: init bool = call %bound_method.loc8_30.3(%.loc8_16.2, %.loc7_10.1)
// CHECK:STDOUT:   %.loc8_30.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc8_30.1
// CHECK:STDOUT:   %.loc8_30.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc8_30.1, %.loc8_30.2
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc8_30.2: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc8_30.4: <bound method> = bound_method %int_2, %impl.elem0.loc8_30.2 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.811140.1]
// CHECK:STDOUT:   %specific_fn.loc8_30.2: <specific function> = specific_function %impl.elem0.loc8_30.2, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc8_30.5: <bound method> = bound_method %int_2, %specific_fn.loc8_30.2 [concrete = constants.%bound_method.ee93db.1]
// CHECK:STDOUT:   %.loc8_30.4: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref.loc8_30.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc8_30.4 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc8_30.2: <bound method> = bound_method %int_2, %Equal.ref.loc8_30.2 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.811140.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc8_30.2: <specific function> = specific_function %Equal.ref.loc8_30.2, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc8_30.6: <bound method> = bound_method %int_2, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc8_30.2 [concrete = constants.%bound_method.ee93db.2]
// CHECK:STDOUT:   %impl.elem0.loc8_24: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_24.1: <bound method> = bound_method %int_2, %impl.elem0.loc8_24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc8_24: <specific function> = specific_function %impl.elem0.loc8_24, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_24.2: <bound method> = bound_method %int_2, %specific_fn.loc8_24 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_24: init %i32 = call %bound_method.loc8_24.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc8_24.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_24 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc8_24.2: %i32 = converted %int_2, %.loc8_24.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc8_30.2: init bool = call %bound_method.loc8_30.6(%.loc8_24.2, %.loc7_10.2)
// CHECK:STDOUT:   %.loc8_30.5: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc8_30.2
// CHECK:STDOUT:   %.loc8_30.6: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc8_30.2, %.loc8_30.5
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc8_30.3 br !match.case.then.loc8_30.1 else br !match.<unexpected BranchWithArg>(%false)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc8_30.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>(%.loc8_30.6)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>:
// CHECK:STDOUT:   %.loc8_30.7: bool = block_arg !match.<unexpected BranchWithArg>
// CHECK:STDOUT:   if %.loc8_30.7 br !match.case.then.loc8_30.2 else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc8_30.2:
// CHECK:STDOUT:   %int_1.loc8_42: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc8_43: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_43.1: <bound method> = bound_method %int_1.loc8_42, %impl.elem0.loc8_43 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc8_43: <specific function> = specific_function %impl.elem0.loc8_43, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_43.2: <bound method> = bound_method %int_1.loc8_42, %specific_fn.loc8_43 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_43: init %i32 = call %bound_method.loc8_43.2(%int_1.loc8_42) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_43: init %i32 = converted %int_1.loc8_42, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8_43 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc8_43
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc9 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_26.2: <bound method> = bound_method %int_0, %specific_fn.loc9 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %i32 = call %bound_method.loc9_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc9: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- mixed_shorthand.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b.b4c: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.20e3: type = pattern_type %struct_type.a.b.b4c [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %struct_type.a.b.f91: type = struct_type {.a: Core.IntLiteral, .b: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.8a1: type = pattern_type %struct_type.a.b.f91 [concrete]
// CHECK:STDOUT:   %.10d: %pattern_type.8a1 = struct_pattern (@F.%expr_patt, %b.patt), false [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc4_32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc4_32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_32: Core.Form = init_form %i32.loc4_32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %struct_type.a.b.b4c = value_param call_param0
// CHECK:STDOUT:     %.loc4_26: type = splice_block %struct_type.a.b [concrete = constants.%struct_type.a.b.b4c] {
// CHECK:STDOUT:       %i32.loc4_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc4_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b.b4c]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %struct_type.a.b.b4c = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %struct_type.a.b.b4c) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %struct_type.a.b.b4c = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.dc0 = expr_pattern %int_1 in [concrete] {
// CHECK:STDOUT:       %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc6_25: %pattern_type.8a1 = struct_pattern (%expr_patt, %b.patt), false [concrete = constants.%.10d]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc5_10.1: %i32 = struct_access %p.ref, element0
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_27: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc6_27.1: <bound method> = bound_method %int_1, %impl.elem0.loc6_27 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc6_27: <specific function> = specific_function %impl.elem0.loc6_27, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc6_27.2: <bound method> = bound_method %int_1, %specific_fn.loc6_27 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc6_27.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc6_27.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc6_27.3: <bound method> = bound_method %int_1, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc6_16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_16.1: <bound method> = bound_method %int_1, %impl.elem0.loc6_16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6_16: <specific function> = specific_function %impl.elem0.loc6_16, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_16.2: <bound method> = bound_method %int_1, %specific_fn.loc6_16 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6: init %i32 = call %bound_method.loc6_16.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_16.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_16.2: %i32 = converted %int_1, %.loc6_16.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc6_27.3(%.loc6_16.2, %.loc5_10.1)
// CHECK:STDOUT:   %.loc6_27.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc6_27.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc6_27.2
// CHECK:STDOUT:   if %.loc6_27.3 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc5_10.2: %i32 = struct_access %p.ref, element1
// CHECK:STDOUT:   %i32.loc6: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %.loc5_10.2
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0.loc6_39: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc6_39.1: <bound method> = bound_method %b.ref, %impl.elem0.loc6_39
// CHECK:STDOUT:   %specific_fn.loc6_39: <specific function> = specific_function %impl.elem0.loc6_39, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_39.2: <bound method> = bound_method %b.ref, %specific_fn.loc6_39
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc6_39.2(%b.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc7: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc7_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc7 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_26.2: <bound method> = bound_method %int_0, %specific_fn.loc7 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %i32 = call %bound_method.loc7_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc7: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- nested.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %struct_type.x.y.a3b: type = struct_type {.x: %i32, .y: %struct_type.a.b} [concrete]
// CHECK:STDOUT:   %pattern_type.de3: type = pattern_type %struct_type.x.y.a3b [concrete]
// CHECK:STDOUT:   %p.param_patt.3b6: %pattern_type.de3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.825: %pattern_type.de3 = wrapper_binding_pattern p, %p.param_patt.3b6 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %StructOfStruct.type: type = fn_type @StructOfStruct [concrete]
// CHECK:STDOUT:   %StructOfStruct: %StructOfStruct.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %pattern_type.20e3: type = pattern_type %struct_type.a.b [concrete]
// CHECK:STDOUT:   %.fdf: %pattern_type.20e3 = struct_pattern (%a.patt, %b.patt), false [concrete]
// CHECK:STDOUT:   %struct_type.y.98c: type = struct_type {.y: %struct_type.a.b} [concrete]
// CHECK:STDOUT:   %pattern_type.1a5: type = pattern_type %struct_type.y.98c [concrete]
// CHECK:STDOUT:   %.9a5: %pattern_type.1a5 = struct_pattern (%.fdf), true [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %tuple.type.24b: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.b59: %tuple.type.24b = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %struct_type.x.y.38e: type = struct_type {.x: %i32, .y: %tuple.type.e55} [concrete]
// CHECK:STDOUT:   %pattern_type.ef7: type = pattern_type %struct_type.x.y.38e [concrete]
// CHECK:STDOUT:   %p.param_patt.347: %pattern_type.ef7 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.bbb: %pattern_type.ef7 = wrapper_binding_pattern p, %p.param_patt.347 [concrete]
// CHECK:STDOUT:   %StructOfTuple.type: type = fn_type @StructOfTuple [concrete]
// CHECK:STDOUT:   %StructOfTuple: %StructOfTuple.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %.d82: %pattern_type.394 = tuple_pattern (%a.patt, %b.patt) [concrete]
// CHECK:STDOUT:   %struct_type.y.3a3: type = struct_type {.y: %tuple.type.e55} [concrete]
// CHECK:STDOUT:   %pattern_type.423: type = pattern_type %struct_type.y.3a3 [concrete]
// CHECK:STDOUT:   %.0fb: %pattern_type.423 = struct_pattern (%.d82), true [concrete]
// CHECK:STDOUT:   %struct_type.x.y.fb8: type = struct_type {.x: %i32, .y: %i32} [concrete]
// CHECK:STDOUT:   %tuple.c27: %tuple.type.24b = tuple_value (%struct_type.x.y.fb8, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.fa3: type = tuple_type (%struct_type.x.y.fb8, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.1b7: type = pattern_type %tuple.type.fa3 [concrete]
// CHECK:STDOUT:   %p.param_patt.540: %pattern_type.1b7 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.e82: %pattern_type.1b7 = wrapper_binding_pattern p, %p.param_patt.540 [concrete]
// CHECK:STDOUT:   %TupleOfStruct.type: type = fn_type @TupleOfStruct [concrete]
// CHECK:STDOUT:   %TupleOfStruct: %TupleOfStruct.type = struct_value () [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %struct_type.x: type = struct_type {.x: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.946: type = pattern_type %struct_type.x [concrete]
// CHECK:STDOUT:   %.610: %pattern_type.946 = struct_pattern (%x.patt), true [concrete]
// CHECK:STDOUT:   %tuple.type.e59: type = tuple_type (%struct_type.x, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %pattern_type.243: type = pattern_type %tuple.type.e59 [concrete]
// CHECK:STDOUT:   %.ada: %pattern_type.243 = tuple_pattern (%.610, @TupleOfStruct.%expr_patt) [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %StructOfStruct.decl: %StructOfStruct.type = fn_decl @StructOfStruct [concrete = constants.%StructOfStruct] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.de3 = value_param_pattern [concrete = constants.%p.param_patt.3b6]
// CHECK:STDOUT:     %p.patt: %pattern_type.de3 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.825]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc5_60 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc5_60: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc5_60: Core.Form = init_form %i32.loc5_60 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %struct_type.x.y.a3b = value_param call_param0
// CHECK:STDOUT:     %.loc5_54: type = splice_block %struct_type.x.y [concrete = constants.%struct_type.x.y.a3b] {
// CHECK:STDOUT:       %i32.loc5_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc5_41: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc5_50: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b]
// CHECK:STDOUT:       %struct_type.x.y: type = struct_type {.x: %i32, .y: %struct_type.a.b} [concrete = constants.%struct_type.x.y.a3b]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %struct_type.x.y.a3b = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %StructOfTuple.decl: %StructOfTuple.type = fn_decl @StructOfTuple [concrete = constants.%StructOfTuple] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.ef7 = value_param_pattern [concrete = constants.%p.param_patt.347]
// CHECK:STDOUT:     %p.patt: %pattern_type.ef7 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.bbb]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc12_51 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc12_51: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12_51: Core.Form = init_form %i32.loc12_51 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %struct_type.x.y.38e = value_param call_param0
// CHECK:STDOUT:     %.loc12_45: type = splice_block %struct_type.x.y [concrete = constants.%struct_type.x.y.38e] {
// CHECK:STDOUT:       %i32.loc12_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc12_36: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc12_41: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc12_44.1: %tuple.type.24b = tuple_literal (%i32.loc12_36, %i32.loc12_41) [concrete = constants.%tuple.b59]
// CHECK:STDOUT:       %.loc12_44.2: type = converted %.loc12_44.1, constants.%tuple.type.e55 [concrete = constants.%tuple.type.e55]
// CHECK:STDOUT:       %struct_type.x.y: type = struct_type {.x: %i32, .y: %tuple.type.e55} [concrete = constants.%struct_type.x.y.38e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %struct_type.x.y.38e = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %TupleOfStruct.decl: %TupleOfStruct.type = fn_decl @TupleOfStruct [concrete = constants.%TupleOfStruct] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.1b7 = value_param_pattern [concrete = constants.%p.param_patt.540]
// CHECK:STDOUT:     %p.patt: %pattern_type.1b7 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.e82]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc19_51 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc19_51: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc19_51: Core.Form = init_form %i32.loc19_51 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %tuple.type.fa3 = value_param call_param0
// CHECK:STDOUT:     %.loc19_45.1: type = splice_block %.loc19_45.3 [concrete = constants.%tuple.type.fa3] {
// CHECK:STDOUT:       %i32.loc19_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc19_36: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %struct_type.x.y: type = struct_type {.x: %i32, .y: %i32} [concrete = constants.%struct_type.x.y.fb8]
// CHECK:STDOUT:       %i32.loc19_42: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc19_45.2: %tuple.type.24b = tuple_literal (%struct_type.x.y, %i32.loc19_42) [concrete = constants.%tuple.c27]
// CHECK:STDOUT:       %.loc19_45.3: type = converted %.loc19_45.2, constants.%tuple.type.fa3 [concrete = constants.%tuple.type.fa3]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %tuple.type.fa3 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @StructOfStruct(%p.param: %struct_type.x.y.a3b) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %struct_type.x.y.a3b = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc7_31: %pattern_type.20e3 = struct_pattern (%a.patt, %b.patt), false [concrete = constants.%.fdf]
// CHECK:STDOUT:     %.loc7_35: %pattern_type.1a5 = struct_pattern (%.loc7_31), true [concrete = constants.%.9a5]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc6_10.1: %struct_type.a.b = struct_access %p.ref, element1
// CHECK:STDOUT:   %.loc6_10.2: %i32 = struct_access %.loc6_10.1, element0
// CHECK:STDOUT:   %.loc6_10.3: %i32 = struct_access %.loc6_10.1, element1
// CHECK:STDOUT:   %i32.loc7_20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %a: %i32 = wrapper_binding a, %.loc6_10.2
// CHECK:STDOUT:   %i32.loc7_28: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %.loc6_10.3
// CHECK:STDOUT:   %a.ref: %i32 = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem1.loc7: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc7_51.1: <bound method> = bound_method %a.ref, %impl.elem1.loc7
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem1.loc7, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc7_51.2: <bound method> = bound_method %a.ref, %specific_fn.loc7
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc7_51.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc9: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc9_10: <bound method> = bound_method %int_1, %impl.elem1.loc9 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc9_10(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc9 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc9_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc9_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc9_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc9_12.2(%.loc9_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc9_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc9_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @StructOfTuple(%p.param: %struct_type.x.y.38e) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %struct_type.x.y.38e = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc14_31: %pattern_type.394 = tuple_pattern (%a.patt, %b.patt) [concrete = constants.%.d82]
// CHECK:STDOUT:     %.loc14_35: %pattern_type.423 = struct_pattern (%.loc14_31), true [concrete = constants.%.0fb]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc13: %tuple.type.e55 = struct_access %p.ref, element1
// CHECK:STDOUT:   %tuple.elem0: %i32 = tuple_access %.loc13, element0
// CHECK:STDOUT:   %tuple.elem1: %i32 = tuple_access %.loc13, element1
// CHECK:STDOUT:   %i32.loc14_20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %a: %i32 = wrapper_binding a, %tuple.elem0
// CHECK:STDOUT:   %i32.loc14_28: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %tuple.elem1
// CHECK:STDOUT:   %a.ref: %i32 = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem1.loc14: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc14_51.1: <bound method> = bound_method %a.ref, %impl.elem1.loc14
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem1.loc14, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc14_51.2: <bound method> = bound_method %a.ref, %specific_fn.loc14
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc14_51.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc16: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16_10: <bound method> = bound_method %int_1, %impl.elem1.loc16 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc16_10(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc16 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc16_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc16_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc16_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc16_12.2(%.loc16_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc16_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc16_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @TupleOfStruct(%p.param: %tuple.type.fa3) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %tuple.type.fa3 = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete = constants.%x.patt]
// CHECK:STDOUT:     %.loc21_21: %pattern_type.946 = struct_pattern (%x.patt), true [concrete = constants.%.610]
// CHECK:STDOUT:     %expr_patt: %pattern_type.dc0 = expr_pattern %int_1 in [concrete] {
// CHECK:STDOUT:       %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc21_25: %pattern_type.243 = tuple_pattern (%.loc21_21, %expr_patt) [concrete = constants.%.ada]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem1: %i32 = tuple_access %p.ref, element1
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc21_27: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc21_27.1: <bound method> = bound_method %int_1, %impl.elem0.loc21_27 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc21_27: <specific function> = specific_function %impl.elem0.loc21_27, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc21_27.2: <bound method> = bound_method %int_1, %specific_fn.loc21_27 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc21_27.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc21_27.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc21_27.3: <bound method> = bound_method %int_1, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc21_24: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc21_24.1: <bound method> = bound_method %int_1, %impl.elem0.loc21_24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc21_24: <specific function> = specific_function %impl.elem0.loc21_24, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc21_24.2: <bound method> = bound_method %int_1, %specific_fn.loc21_24 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21: init %i32 = call %bound_method.loc21_24.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc21_24.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc21_24.2: %i32 = converted %int_1, %.loc21_24.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc21_27.3(%.loc21_24.2, %tuple.elem1)
// CHECK:STDOUT:   %.loc21_27.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc21_27.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc21_27.2
// CHECK:STDOUT:   if %.loc21_27.3 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %tuple.elem0: %struct_type.x.y.fb8 = tuple_access %p.ref, element0
// CHECK:STDOUT:   %.loc20: %i32 = struct_access %tuple.elem0, element0
// CHECK:STDOUT:   %i32.loc21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %x: %i32 = wrapper_binding x, %.loc20
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %impl.elem0.loc21_39: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc21_39.1: <bound method> = bound_method %x.ref, %impl.elem0.loc21_39
// CHECK:STDOUT:   %specific_fn.loc21_39: <specific function> = specific_function %impl.elem0.loc21_39, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc21_39.2: <bound method> = bound_method %x.ref, %specific_fn.loc21_39
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc21_39.2(%x.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc22: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc22_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc22 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc22: <specific function> = specific_function %impl.elem0.loc22, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc22_26.2: <bound method> = bound_method %int_0, %specific_fn.loc22 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22: init %i32 = call %bound_method.loc22_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc22: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- field_var_ref.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b.b4c: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.20e3: type = pattern_type %struct_type.a.b.b4c [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %VarField.type: type = fn_type @VarField [concrete]
// CHECK:STDOUT:   %VarField: %VarField.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = ref_binding_pattern n [concrete]
// CHECK:STDOUT:   %n.var_patt: %pattern_type.6b6 = var_pattern %n.patt [concrete]
// CHECK:STDOUT:   %struct_type.a: type = struct_type {.a: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.506: type = pattern_type %struct_type.a [concrete]
// CHECK:STDOUT:   %.bed: %pattern_type.506 = struct_pattern (%n.var_patt), true [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.1: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.1: %Int.as.AddWith.impl.Op.type.1eac76.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.2: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.2: %Int.as.AddWith.impl.Op.type.1eac76.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.aa4: <witness> = impl_witness imports.%AddWith.impl_witness_table.b21, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.1: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.2: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.2: %Int.as.AddWith.impl.Op.type.bddb3c.2 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.3de: %AddWith.type.832 = facet_value %i32, (%AddWith.impl_witness.aa4) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.b60: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(Core.IntLiteral, %AddWith.facet.3de) [concrete]
// CHECK:STDOUT:   %.fbe: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.b60, %AddWith.facet.3de [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.1: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.2, @Int.as.AddWith.impl.Op.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.2: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.1, @Int.as.AddWith.impl.Op.3(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc10_16.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %RefField.type: type = fn_type @RefField [concrete]
// CHECK:STDOUT:   %RefField: %RefField.type = struct_value () [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.20e3 = ref_binding_pattern s [concrete]
// CHECK:STDOUT:   %s.var_patt: %pattern_type.20e3 = var_pattern %s.patt [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %struct_type.a.b.cfd: type = struct_type {.a: Core.IntLiteral, .b: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct.4aa: %struct_type.a.b.cfd = struct_value (%int_1.5b8, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %struct.631: %struct_type.a.b.b4c = struct_value (%int_1.0c6, %int_2.295) [concrete]
// CHECK:STDOUT:   %r.patt: %pattern_type.6b6 = ref_binding_pattern r [concrete]
// CHECK:STDOUT:   %.b4f: %pattern_type.506 = struct_pattern (%r.patt), true [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.7ff: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.loc16 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.3: %Destroy.Op.type.1d8f74.3 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3a: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.b21 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.8a3a), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %VarField.decl: %VarField.type = fn_decl @VarField [concrete = constants.%VarField] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_39 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8_39: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_39: Core.Form = init_form %i32.loc8_39 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %struct_type.a.b.b4c = value_param call_param0
// CHECK:STDOUT:     %.loc8_33: type = splice_block %struct_type.a.b [concrete = constants.%struct_type.a.b.b4c] {
// CHECK:STDOUT:       %i32.loc8_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc8_30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b.b4c]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %struct_type.a.b.b4c = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %RefField.decl: %RefField.type = fn_decl @RefField [concrete = constants.%RefField] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc15 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc15: Core.Form = init_form %i32.loc15 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @VarField(%p.param: %struct_type.a.b.b4c) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %struct_type.a.b.b4c = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = ref_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:     %n.var_patt: %pattern_type.6b6 = var_pattern %n.patt [concrete = constants.%n.var_patt]
// CHECK:STDOUT:     %.loc10_29: %pattern_type.506 = struct_pattern (%n.var_patt), true [concrete = constants.%.bed]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc9: %i32 = struct_access %p.ref, element0
// CHECK:STDOUT:   %n.var: ref %i32 = var_storage %n.var_patt
// CHECK:STDOUT:   %impl.elem0.loc9: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc9_10.1: <bound method> = bound_method %.loc9, %impl.elem0.loc9
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_10.2: <bound method> = bound_method %.loc9, %specific_fn.loc9
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc9: init %i32 = call %bound_method.loc9_10.2(%.loc9)
// CHECK:STDOUT:   assign %n.var, %Int.as.Copy.impl.Op.call.loc9
// CHECK:STDOUT:   %i32.loc10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %n: ref %i32 = wrapper_binding n, %n.var
// CHECK:STDOUT:   %n.ref.loc10_36: ref %i32 = name_ref n, %n
// CHECK:STDOUT:   %n.ref.loc10_40: ref %i32 = name_ref n, %n
// CHECK:STDOUT:   %int_1.loc10: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc10: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:   %bound_method.loc10_42.1: <bound method> = bound_method %n.ref.loc10_40, %impl.elem1.loc10
// CHECK:STDOUT:   %specific_fn.loc10_42: <specific function> = specific_function %impl.elem1.loc10, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:   %bound_method.loc10_42.2: <bound method> = bound_method %n.ref.loc10_40, %specific_fn.loc10_42
// CHECK:STDOUT:   %.loc10_40: %i32 = acquire_value %n.ref.loc10_40
// CHECK:STDOUT:   %.loc10_42: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc10_42 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %.loc10_40, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:   %bound_method.loc10_42.3: <bound method> = bound_method %.loc10_40, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc10_44: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_44.1: <bound method> = bound_method %int_1.loc10, %impl.elem0.loc10_44 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc10_44: <specific function> = specific_function %impl.elem0.loc10_44, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_44.2: <bound method> = bound_method %int_1.loc10, %specific_fn.loc10_44 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_44.2(%int_1.loc10) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_44.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc10_44.2: %i32 = converted %int_1.loc10, %.loc10_44.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc10_42.3(%.loc10_40, %.loc10_44.2)
// CHECK:STDOUT:   assign %n.ref.loc10_36, %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %n.ref.loc10_54: ref %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc10_54: %i32 = acquire_value %n.ref.loc10_54
// CHECK:STDOUT:   %impl.elem0.loc10_54: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc10_54.1: <bound method> = bound_method %.loc10_54, %impl.elem0.loc10_54
// CHECK:STDOUT:   %specific_fn.loc10_54: <specific function> = specific_function %impl.elem0.loc10_54, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_54.2: <bound method> = bound_method %.loc10_54, %specific_fn.loc10_54
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc10: init %i32 = call %bound_method.loc10_54.2(%.loc10_54)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %n.var, constants.%Destroy.Op.1a2547.2
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%n.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call.loc10
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc12: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc12: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc12_10: <bound method> = bound_method %int_1.loc12, %impl.elem1.loc12 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc12_10(%int_1.loc12) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc12: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc12 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc12: <specific function> = specific_function %impl.elem0.loc12, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc12 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc12_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc12_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc12_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %i32 = call %bound_method.loc12_12.2(%.loc12_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc12_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc12_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc10_16.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc10_16.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @RefField() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.var: ref %struct_type.a.b.b4c = var_storage %s.var_patt
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc16_46.1: %struct_type.a.b.cfd = struct_literal (%int_1.loc16, %int_2) [concrete = constants.%struct.4aa]
// CHECK:STDOUT:   %impl.elem0.loc16_46.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_46.1: <bound method> = bound_method %int_1.loc16, %impl.elem0.loc16_46.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc16_46.1: <specific function> = specific_function %impl.elem0.loc16_46.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_46.2: <bound method> = bound_method %int_1.loc16, %specific_fn.loc16_46.1 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_46.1: init %i32 = call %bound_method.loc16_46.2(%int_1.loc16) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc16_46.2: init %i32 = converted %int_1.loc16, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_46.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc16_46.3: ref %i32 = struct_access %s.var, element0
// CHECK:STDOUT:   %.loc16_46.4: init %i32 to %.loc16_46.3 = in_place_init %.loc16_46.2 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %impl.elem0.loc16_46.2: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_46.3: <bound method> = bound_method %int_2, %impl.elem0.loc16_46.2 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc16_46.2: <specific function> = specific_function %impl.elem0.loc16_46.2, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_46.4: <bound method> = bound_method %int_2, %specific_fn.loc16_46.2 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_46.2: init %i32 = call %bound_method.loc16_46.4(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc16_46.5: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_46.2 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc16_46.6: ref %i32 = struct_access %s.var, element1
// CHECK:STDOUT:   %.loc16_46.7: init %i32 to %.loc16_46.6 = in_place_init %.loc16_46.5 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc16_46.8: init %struct_type.a.b.b4c to %s.var = struct_init (%.loc16_46.4, %.loc16_46.7) [concrete = constants.%struct.631]
// CHECK:STDOUT:   %.loc16_3: init %struct_type.a.b.b4c = converted %.loc16_46.1, %.loc16_46.8 [concrete = constants.%struct.631]
// CHECK:STDOUT:   assign %s.var, %.loc16_3
// CHECK:STDOUT:   %.loc16_27: type = splice_block %struct_type.a.b [concrete = constants.%struct_type.a.b.b4c] {
// CHECK:STDOUT:     %i32.loc16_15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc16_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b.b4c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: ref %struct_type.a.b.b4c = wrapper_binding s, %s.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.20e3 = ref_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:     %s.var_patt: %pattern_type.20e3 = var_pattern %s.patt [concrete = constants.%s.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s.ref: ref %struct_type.a.b.b4c = name_ref s, %s
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %r.patt: %pattern_type.6b6 = ref_binding_pattern r [concrete = constants.%r.patt]
// CHECK:STDOUT:     %.loc18_29: %pattern_type.506 = struct_pattern (%r.patt), true [concrete = constants.%.b4f]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc17: ref %i32 = struct_access %s.ref, element0
// CHECK:STDOUT:   %i32.loc18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %r: ref %i32 = wrapper_binding r, %.loc17
// CHECK:STDOUT:   %r.ref.loc18_36: ref %i32 = name_ref r, %r
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %impl.elem0.loc18_38: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_38.1: <bound method> = bound_method %int_7, %impl.elem0.loc18_38 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc18_38: <specific function> = specific_function %impl.elem0.loc18_38, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc18_38.2: <bound method> = bound_method %int_7, %specific_fn.loc18_38 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18: init %i32 = call %bound_method.loc18_38.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc18_38: init %i32 = converted %int_7, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   assign %r.ref.loc18_36, %.loc18_38
// CHECK:STDOUT:   %r.ref.loc18_50: ref %i32 = name_ref r, %r
// CHECK:STDOUT:   %.loc18_50: %i32 = acquire_value %r.ref.loc18_50
// CHECK:STDOUT:   %impl.elem0.loc18_50: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc18_50.1: <bound method> = bound_method %.loc18_50, %impl.elem0.loc18_50
// CHECK:STDOUT:   %specific_fn.loc18_50: <specific function> = specific_function %impl.elem0.loc18_50, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc18_50.2: <bound method> = bound_method %.loc18_50, %specific_fn.loc18_50
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc18_50.2(%.loc18_50)
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_3.1: <bound method> = bound_method %s.var, constants.%Destroy.Op.1a2547.3
// CHECK:STDOUT:   %Destroy.Op.call.loc16_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc16_3.1(%s.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc20: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc20_10: <bound method> = bound_method %int_1.loc20, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc20_10(%int_1.loc20) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc20: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc20_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc20 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc20: <specific function> = specific_function %impl.elem0.loc20, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc20_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc20 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc20_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc20_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc20_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20: init %i32 = call %bound_method.loc20_12.2(%.loc20_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc20_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %Destroy.Op.bound.loc16_3.2: <bound method> = bound_method %s.var, constants.%Destroy.Op.1a2547.3
// CHECK:STDOUT:   %Destroy.Op.call.loc16_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc16_3.2(%s.var)
// CHECK:STDOUT:   return %.loc20_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc16(%self.param: ref %struct_type.a.b.b4c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- unused_field.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.20e3: type = pattern_type %struct_type.a.b [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %struct_type.a: type = struct_type {.a: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.506: type = pattern_type %struct_type.a [concrete]
// CHECK:STDOUT:   %.ff8: %pattern_type.506 = struct_pattern (%a.patt), true [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.20e3 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.20e3 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc4_32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc4_32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_32: Core.Form = init_form %i32.loc4_32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %p.param: %struct_type.a.b = value_param call_param0
// CHECK:STDOUT:     %.loc4_26: type = splice_block %struct_type.a.b [concrete = constants.%struct_type.a.b] {
// CHECK:STDOUT:       %i32.loc4_14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc4_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %struct_type.a.b: type = struct_type {.a: %i32, .b: %i32} [concrete = constants.%struct_type.a.b]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %struct_type.a.b = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %struct_type.a.b) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: %struct_type.a.b = name_ref p, %p
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:     %.loc6_27: %pattern_type.506 = struct_pattern (%a.patt), true [concrete = constants.%.ff8]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc5: %i32 = struct_access %p.ref, element0
// CHECK:STDOUT:   %i32.loc6: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %a: %i32 = wrapper_binding a, %.loc5
// CHECK:STDOUT:   %int_1.loc6: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_42.1: <bound method> = bound_method %int_1.loc6, %impl.elem0.loc6 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6: <specific function> = specific_function %impl.elem0.loc6, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_42.2: <bound method> = bound_method %int_1.loc6, %specific_fn.loc6 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6: init %i32 = call %bound_method.loc6_42.2(%int_1.loc6) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_42: init %i32 = converted %int_1.loc6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc6_42
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc8: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc8_10: <bound method> = bound_method %int_1.loc8, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc8_10(%int_1.loc8) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc8: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc8 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc8 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc8_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc8_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc8_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %i32 = call %bound_method.loc8_12.2(%.loc8_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc8_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc8_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- empty_struct.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %empty_struct: %empty_struct_type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.a96: type = pattern_type %empty_struct_type [concrete]
// CHECK:STDOUT:   %.39f: %pattern_type.a96 = struct_pattern (), false [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc5_11.1: %empty_struct_type = struct_literal () [concrete = constants.%empty_struct]
// CHECK:STDOUT:   %empty_struct: %empty_struct_type = struct_value () [concrete = constants.%empty_struct]
// CHECK:STDOUT:   %.loc5_11.2: %empty_struct_type = converted %.loc5_11.1, %empty_struct [concrete = constants.%empty_struct]
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %.loc6_11: %pattern_type.a96 = struct_pattern (), false [concrete = constants.%.39f]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_1.loc6: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_26.1: <bound method> = bound_method %int_1.loc6, %impl.elem0.loc6 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6: <specific function> = specific_function %impl.elem0.loc6, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_26.2: <bound method> = bound_method %int_1.loc6, %specific_fn.loc6 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6: init %i32 = call %bound_method.loc6_26.2(%int_1.loc6) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_26: init %i32 = converted %int_1.loc6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc6_26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc8: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc8_10: <bound method> = bound_method %int_1.loc8, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc8_10(%int_1.loc8) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc8: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc8 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc8 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc8_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc8_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc8_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %i32 = call %bound_method.loc8_12.2(%.loc8_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc8_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc8_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
