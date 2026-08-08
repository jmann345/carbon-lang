// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_generic_payload_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_generic_payload_scrutinee.carbon

// Risk R-2's counter-programs: scrutinee values of a payload-carrying generic
// choice produced by paths that complete NOTHING on the way in. The match
// gate's forced completion (`RequireCompleteType` at `MatchCondition`,
// W5-S3a) is what resolves the specific — with its payload-layout recompute
// and SF-6 check — before any repr read; without the forcing, `GetObjectRepr`
// on the unresolved specific would die on the value-block CHECK
// (sem_ir/generic.cpp).

// --- pointer_deref.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

// A pointer dereference completes nothing: completion has no nested
// `PointerType` case, a pointer's value representation is a copy, and
// `PerformPointerDereference` reads no representation. Only the match's own
// forcing establishes the pointee specific's layout.
fn F(p: P(i64)*) -> i32 {
  match (*p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}
//@dump-sem-ir-end

// --- plib.carbon
library "plib";

choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

let g: P(i64) = P(i64).Neither;

// --- imported_let.carbon
library "[[@TEST_NAME]]";

import library "plib";

//@dump-sem-ir-begin
// An imported `let` completes nothing in this file on the way in: the value
// was produced in `plib`, and the specific's definition — with the payload
// recompute — is resolved here by the match gate's forcing.
fn F() -> i32 {
  match (g) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}
//@dump-sem-ir-end

// --- fail_all_payloads_rejected.carbon
library "[[@TEST_NAME]]";

// Plan §2.5(ii): a specific ALL of whose payloads are rejected degrades at
// the SCRUTINEE gate, not the exhaustiveness bail — the error witness makes
// `GetObjectRepr` return the error type, so `GetChoiceDiscriminantType`
// returns no discriminant and the match keeps the scrutinee TODO.
class C {}

choice P(T: type) {
  A(x: T),
  B(y: T)
}

// CHECK:STDERR: fail_all_payloads_rejected.carbon:[[@LINE+7]]:9: error: unable to monomorphize specific `P(C)` [ResolvingSpecificHere]
// CHECK:STDERR: fn F(p: P(C)) -> i32 {
// CHECK:STDERR:         ^
// CHECK:STDERR: fail_all_payloads_rejected.carbon:[[@LINE-5]]:1: note: choice alternative payload type `C` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
// CHECK:STDERR: }
// CHECK:STDERR: ^
// CHECK:STDERR:
fn F(p: P(C)) -> i32 {
  // CHECK:STDERR: fail_all_payloads_rejected.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
  match (p) {
    default => { return 0; }
  }
  return -1;
}

// --- by_value_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

// The by-value-param PASSING pin (not a falsifier): parameter setup already
// completes the type, and the match's forcing is then a no-op.
fn F(p: P(i32)) -> i32 {
  match (p) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

fn Call() -> i32 {
  let n: P(i32) = P(i32).Neither;
  return F(n);
}
//@dump-sem-ir-end
