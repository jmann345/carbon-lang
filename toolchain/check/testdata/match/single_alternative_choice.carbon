// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/single_alternative_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/single_alternative_choice.carbon

// A single-alternative choice has an empty-tuple discriminant — no
// discriminant bits (handle_choice.cpp) — so its one alternative arm has
// nothing to test and is always taken: a constant-true condition, the same
// shape as an irrefutable binding arm, with the payload extraction still
// real (W-068; recorded at W5-S1, kept out of S2e's sanctioned scope, and
// admitted here at the scrutinee gate).

// --- constant_alternative.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Always {
  TheOnlyOption
}

// The single unguarded arm covers the only alternative, so the match is
// exhaustive and needs no `default` arm (SF-7 through the same coverage
// analysis as multi-alternative choices).
fn F(a: Always) -> i32 {
  match (a) {
    case .TheOnlyOption => { return 0; }
  }
  return -1;
}

// Construction was never gated: the alternative constant carries the
// empty-tuple discriminant value.
fn Construct() -> i32 {
  let a: Always = Always.TheOnlyOption;
  return F(a);
}
//@dump-sem-ir-end

// --- payload_alternative.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice OneShot {
  Only(x: i32)
}

// The arm's condition is a constant true — there is no discriminant to
// compare — but the payload extraction stays real: the bind pass reads the
// payload tuple through the payload region field of the choice's
// `{.discriminant: (), .payload: ...}` representation and initializes the
// binding from its element.
fn Get(o: OneShot) -> i32 {
  match (o) {
    case .Only(v: i32) => { return v; }
  }
  return -1;
}

fn Make(x: i32) -> OneShot {
  return OneShot.Only(x);
}
//@dump-sem-ir-end

// --- default_only.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Always {
  TheOnlyOption
}

// A `default`-only match over a single-alternative choice: the scrutinee is
// admitted independently of which arms cover what, and `default` covers
// everything as usual.
fn F(a: Always) -> i32 {
  match (a) {
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- generic_specific_payload.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Wrap(T: type) {
  Some(x: T)
}

// Composition with the W5-S3 generic-choice lifts: a specific of a
// single-alternative generic payload choice is admitted by the same
// empty-tuple-discriminant gate, and the payload destructuring resolves
// through the specific's substituted representation (S3b/S3c machinery,
// alternative-count-independent).
fn Get(w: Wrap(i32)) -> i32 {
  match (w) {
    case .Some(v: i32) => { return v; }
  }
  return -1;
}

fn Make(x: i32) -> Wrap(i32) {
  return Wrap(i32).Some(x);
}
//@dump-sem-ir-end
