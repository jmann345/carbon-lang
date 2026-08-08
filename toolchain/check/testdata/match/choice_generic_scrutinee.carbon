// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_generic_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_generic_scrutinee.carbon

// Specifics of a generic choice as `match` scrutinees (W5-S3a,
// fork/w5-s3/plan.md §3): the scrutinee gate forces the specific's
// definition resolution (`RequireCompleteType` at `MatchCondition`), and
// `GetChoiceDiscriminantType` reads the object representation through the
// specific, so payload-free generic choices dispatch and are covered by the
// SF-7 exhaustiveness analysis exactly like concrete choices. Payload
// synthesis in generic choices stays behind its definition TODO (S3b).

// --- basic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  A,
  B
}

// A specific of a payload-free generic choice is an admitted scrutinee:
// both alternatives are covered by unguarded arms, so no `default` arm is
// required (SF-7 through the shared alternative table).
fn Classify(p: P(i32)) -> i32 {
  match (p) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}

// The alternative constant resolves through the specific's scope; a `let`
// binds the value directly — returning or `var`-initializing from the
// constant would require a `Copy` impl, which choices do not have (see
// fork/conformance/programs/types/choice_payload_construct.carbon).
fn Construct() -> i32 {
  let b: P(i32) = P(i32).B;
  return Classify(b);
}
//@dump-sem-ir-end

// --- two_specifics.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  A,
  B
}

// Two specifics of one generic choice matched in one function: each match
// dispatches on its own specific's discriminant, and each is exhaustive on
// its own — the alternative table is shared through the `class_id`, the
// coverage is per statement.
fn G(a: P(i32), b: P(bool)) -> i32 {
  match (a) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  match (b) {
    case .A => { return 2; }
    case .B => { return 3; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- symbolic_specific.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  A,
  B
}

// A SYMBOLIC specific as scrutinee (risk R-8's scope-in): matching
// `x: P(T)` inside a generic body is admitted by the same gate lift — the
// payload-free choice's representation witness is concrete, and the forced
// completion defers the specific's requirement to monomorphization
// (`require_complete_type`).
fn F(T:! type, x: P(T)) -> i32 {
  match (x) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}

fn Call(p: P(i32)) -> i32 {
  return F(i32, p);
}
//@dump-sem-ir-end

// --- plib.carbon
library "plib";

choice P(T: type) {
  A,
  B
}

// --- use_imported.carbon
library "[[@TEST_NAME]]";

import library "plib";

//@dump-sem-ir-begin
// Matching a specific of a generic choice declared in another library: the
// `is_choice` entity flag, the alternative table, and the generic's
// definition must arrive through import for the scrutinee gate's forced
// specific resolution and the designator resolution to work.
fn Classify(p: P(i32)) -> i32 {
  match (p) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}

fn Construct() -> i32 {
  let a: P(i32) = P(i32).A;
  return Classify(a);
}
//@dump-sem-ir-end

// --- fail_nonexhaustive.carbon
library "[[@TEST_NAME]]";

choice P(T: type) {
  A,
  B
}

// A non-exhaustive match on a specific names the missing alternative, with
// the scrutinee's specific type in the message.
fn F(p: P(i32)) -> i32 {
  // CHECK:STDERR: fail_nonexhaustive.carbon:[[@LINE+4]]:3: error: `match` on choice `P(i32)` has no `default` arm and does not cover alternative `.B` [MatchNonexhaustive]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (p) {
    case .A => { return 0; }
  }
  return -1;
}

// --- fail_two_specifics_one_nonexhaustive.carbon
library "[[@TEST_NAME]]";

choice P(T: type) {
  A,
  B
}

// The R-5 pin: coverage identity is shared across specifics through the
// `class_id`, but coverage itself is per match statement — the exhaustive
// `P(i32)` match compiles in silence while the `P(bool)` match right after
// it is diagnosed, naming its own missing alternative. Coverage bleeding
// between the statements (or between the specifics) would falsify this.
fn F(a: P(i32), b: P(bool)) -> i32 {
  match (a) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  // CHECK:STDERR: fail_two_specifics_one_nonexhaustive.carbon:[[@LINE+4]]:3: error: `match` on choice `P(bool)` has no `default` arm and does not cover alternative `.B` [MatchNonexhaustive]
  // CHECK:STDERR:   match (b) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (b) {
    case .A => { return 2; }
  }
  return -1;
}

// --- fail_todo_single_alternative_specific.carbon
library "[[@TEST_NAME]]";

choice Always(T: type) {
  Sunny
}

// W-068 composition on the post-deletion path: a single-alternative
// specific's discriminant is the empty tuple, not an integer, so
// `GetChoiceDiscriminantType` still rejects it — the fewer-than-two gate
// composes with the lifted specifics gate and the scrutinee TODO survives.
fn F(a: Always(i32)) {
  // CHECK:STDERR: fail_todo_single_alternative_specific.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (a) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (a) {
    case .Sunny => { return; }
  }
}

// --- fail_todo_empty_choice_specific.carbon
library "[[@TEST_NAME]]";

choice Never(T: type) {}

// The zero-alternative composition: an empty generic choice's specific also
// keeps the scrutinee TODO (W-068).
fn F(n: Never(i32)) {
  // CHECK:STDERR: fail_todo_empty_choice_specific.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (n) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (n) {
    default => { return; }
  }
}

// --- fail_todo_mixed_partial_table.carbon
library "[[@TEST_NAME]]";

// The S3a partial-table window (plan §2.5 i): the parameterized alternative
// of a MIXED generic choice is still rejected at the definition (payload
// synthesis is S3b), so it gets no alternative-table entry — and a match on
// a specific covering only the constant alternatives is judged exhaustive
// IN SILENCE, `.Tag` uncovered. The pairing of the definition TODO with the
// silent pass below pins the window until S3b populates parameterized rows;
// this mirrors the S2e recorded deviation (3) error-recovery semantics
// (coverage over surviving alternatives only).
choice P(T: type) {
  // CHECK:STDERR: fail_todo_mixed_partial_table.carbon:[[@LINE+4]]:6: error: semantics TODO: `choice alternative payload with generic or Self-dependent type` [SemanticsTodo]
  // CHECK:STDERR:   Tag(n: i32),
  // CHECK:STDERR:      ^~~~~~~~
  // CHECK:STDERR:
  Tag(n: i32),
  A,
  B
}

fn F(p: P(i32)) -> i32 {
  match (p) {
    case .A => { return 0; }
    case .B => { return 1; }
  }
  return -1;
}
