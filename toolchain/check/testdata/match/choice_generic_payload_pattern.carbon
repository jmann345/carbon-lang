// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_generic_payload_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_generic_payload_pattern.carbon

// Payload destructuring on specifics of generic choices (W5-S3c,
// fork/w5-s3/plan.md §3 S3c) — everything past the S3b minimal pin
// (choice/generic_payload.carbon's destructure subfile): multi-parameter
// payloads resolved per specific, guards composing with payload bindings,
// substituted binding conversions (risk label R-7), imported generics, and
// the R-8 counterpart — destructuring from a SYMBOLIC payload tuple inside
// a generic body. Every positive match here is exhaustive without
// `default`: S2e's coverage analysis records a destructuring arm as
// covering its alternative (coverage is by alternative index, not pattern
// shape — see the recording in handle_match.cpp's `MatchCase`).

// --- multi.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Multi-parameter payload destructuring on concrete specifics: one
// subpattern per declared parameter, positionally, against the SUBSTITUTED
// payload tuple — `(i32, i32)` for `Pair(i32)` and `(i64, i64)` for
// `Pair(i64)`, resolved through `GetChoicePayloadInfo`'s specific-resolved
// reads at both the case check (arity) and the bind pass (element
// extraction).
choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Sum32(p: Pair(i32)) -> i32 {
  match (p) {
    case .Both(x: i32, y: i32) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Sum64(p: Pair(i64)) -> i64 {
  match (p) {
    case .Both(x: i64, y: i64) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Run() -> i32 {
  let a: Pair(i32) = Pair(i32).Both(1, 2);
  let b: Pair(i64) = Pair(i64).Both(3, 4);
  if (Sum64(b) != 7) {
    return 1;
  }
  return Sum32(a) - 3;
}
//@dump-sem-ir-end

// --- guard.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A guard on a payload-destructuring arm of a specific scrutinee (S2d
// composing with S3b's parameterized table rows): the arm's test compares
// the discriminant, the bind pass extracts the substituted payload and
// initializes `v`, and only then does the guard evaluate — with `v` in
// scope. A failed guard falls through to the unguarded `.Some` arm. The
// guarded arm contributes nothing to coverage, so exhaustiveness rests on
// the unguarded `.Some` and `.None` arms alone.
choice Opt(T: type) {
  Some(value: T),
  None
}

fn Sign(o: Opt(i32)) -> i32 {
  match (o) {
    case .Some(v: i32) if (v > 0) => { return v; }
    case .Some(w: i32) => { return w - 1; }
    case .None => { return -10; }
  }
  // Unreachable: every arm returns.
  return -2;
}

fn Run() -> i32 {
  let s: Opt(i32) = Opt(i32).Some(7);
  return Sign(s) - 7;
}
//@dump-sem-ir-end

// --- binding_conversion.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Substituted binding conversions (risk label R-7, re-derived for
// specifics): the binding's declared type differs from the substituted
// payload element type, and the bind pass converts per element — `i32`
// payload to `i64` binding through the prelude's `ImplicitAs` — with the
// conversion's temporaries deferred to the arm scope's cleanups
// (`DeferCleanups`, the S2c shape; the concrete precedent is
// choice_payload_multi.carbon). By the bind pass the specific's payload
// tuple is fully concrete, so this rides the same machinery.
choice Opt(T: type) {
  Some(value: T),
  None
}

fn Widen(o: Opt(i32)) -> i64 {
  match (o) {
    case .Some(v: i64) => { return v; }
    case .None => { return -1; }
  }
  // Unreachable: every arm returns.
  return -2;
}

fn Run() -> i32 {
  let s: Opt(i32) = Opt(i32).Some(42);
  if (Widen(s) != 42) {
    return 1;
  }
  return 0;
}
//@dump-sem-ir-end

// --- plib.carbon
library "plib";

choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

// --- use_imported.carbon
library "[[@TEST_NAME]]";

import library "plib";

//@dump-sem-ir-begin
// Destructuring a specific of a generic choice declared in another
// library: the parameterized alternative's table row (name, discriminant
// index, payload field position) arrives through the class import, and the
// importing file resolves the payload region and tuple through the local
// specific (the S3b import path: canonically-minted `CustomLayoutType`
// blocks and constant-carrying alternative bindings), so both the case
// check and the bind pass read specific-resolved types here.
fn Sum(p: P(i32)) -> i32 {
  match (p) {
    case .Both(x: i32, y: i32) => { return x + y; }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Construct() -> i32 {
  let b: P(i32) = P(i32).Both(20, 22);
  return Sum(b) - 42;
}
//@dump-sem-ir-end

// --- symbolic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// The R-8 counterpart: destructuring from a SYMBOLIC payload tuple inside
// a generic body. The scrutinee gate's forced completion resolves the
// symbolic specific's definition (the completer's `ClassType` case runs
// `ResolveSpecificDefinition` even for symbolic arguments), so
// `GetChoicePayloadInfo` reads the substituted-but-symbolic payload region
// and tuple — the sentinel-layout `CustomLayoutType` and `(T, T)` — purely
// structurally, and the bind pass emits the element accesses with symbolic
// types. The payload bindings bind values of type `T` without copying
// (`let`-binding semantics); they flow into `Discard` by value for the
// same reason. Exhaustiveness is discharged symbolically too: coverage
// reads the generic's shared alternative table. Only `Call`'s concrete
// instantiation lowers.
choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

fn Discard[U: type](_: U, _: U) {}

fn Classify[T: type](p: P(T)) -> i32 {
  match (p) {
    case .Both(a: T, b: T) => {
      Discard(a, b);
      return 1;
    }
    case .Neither => { return 0; }
  }
  // Unreachable: every arm returns.
  return -1;
}

fn Call(p: P(i32)) -> i32 {
  return Classify(p);
}
//@dump-sem-ir-end

// --- fail_nonexhaustive_payload.carbon
library "[[@TEST_NAME]]";

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

// Coverage is recorded by alternative, not pattern shape: the
// destructuring arm covers exactly `.Both`, so the missing `.Neither` is
// named. (The discharge direction — destructuring arms counting toward
// full coverage — is pinned by the exhaustive positive subfiles above.)
fn F(p: Pair(i32)) -> i32 {
  // CHECK:STDERR: fail_nonexhaustive_payload.carbon:[[@LINE+4]]:3: error: `match` on choice `Pair(i32)` has no `default` arm and does not cover alternative `.Neither` [MatchNonexhaustive]
  // CHECK:STDERR:   match (p) {
  // CHECK:STDERR:   ^~~~~~~~~~~
  // CHECK:STDERR:
  match (p) {
    case .Both(x: i32, y: i32) => { return x + y; }
  }
  return -1;
}
