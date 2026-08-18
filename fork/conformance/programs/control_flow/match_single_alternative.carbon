// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   7
//   5
//
// Choices with fewer than two alternatives as `match` scrutinees (W-068).
// A single-alternative choice has no discriminant bits — its discriminant
// field is the empty tuple — so the one alternative arm is always taken
// with no discriminant test, and the match is exhaustive with that one arm
// (docs/design/pattern_matching.md, "Refutability, overlap, usefulness,
// and exhaustiveness": the alternatives are a closed set; sum_types.md
// alternative patterns). The payload extraction must still be real:
// `Unwrap` destructures `.Value(n: i32)` and returns the payload, with the
// payload argument runtime-computed via RuntimeSeed (x + 20) so constant
// folding cannot fake the extraction (R16d; expected prints derive from
// the seed arithmetic: 22 + 20 = 42, -13 + 20 = 7, and Classify's literal
// 5). `Impossible` pins the empty-choice half: `Never {}` is admitted as a
// scrutinee TYPE and every match over it is vacuously exhaustive, but it
// has no constructors, so the function can only ever compile and link —
// no call site can exist.

import Core library "io";

choice Wrapped {
  Value(n: i32)
}

choice Unit {
  Only
}

choice Never {}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// Single-alternative payload consumption: always-taken arm, real payload
// extraction, no `default` needed (the one arm covers the one alternative).
fn Unwrap(w: Wrapped) -> i32 {
  match (w) {
    case .Value(n: i32) => { return n; }
  }
  return -1;
}

// The payload-free shape: a constant alternative with an empty-tuple
// discriminant value, matched by its always-taken designator arm.
fn Classify(u: Unit) -> i32 {
  match (u) {
    case .Only => { return 5; }
  }
  return -1;
}

// The empty-choice half: type admission only. The `default` arm is
// dynamically dead — `Never` values cannot be constructed.
fn Impossible(n: Never) -> i32 {
  match (n) {
    default => { return -1; }
  }
  return -2;
}

fn Run() -> i32 {
  // Call-initialized `var`s, per the choice_payload_construct.carbon
  // precedent: initializing a `var` from a choice *value* would require a
  // `Copy` impl, which choices do not have.
  var w: Wrapped = Wrapped.Value(RuntimeSeed(22));
  Core.Print(Unwrap(w));
  var w2: Wrapped = Wrapped.Value(RuntimeSeed(-13));
  Core.Print(Unwrap(w2));
  let u: Unit = Unit.Only;
  Core.Print(Classify(u));
  return 0;
}
