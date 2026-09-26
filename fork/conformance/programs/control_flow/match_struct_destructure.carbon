// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — good switch equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   100
//   33
//   7004
//   1
//   2
//   19
//
// Struct destructuring in `match` (W-077): a struct-typed value dispatched
// by constant-field arms (`case {.tag = 1, _}` — the trailing `_` discards
// unmentioned fields, docs/design/pattern_matching.md "Struct patterns"),
// destructured by a designated binding arm (`.value = v: i32`) and by a
// shorthand all-binding arm (`case {tag: i32, value: i32}`, which is
// irrefutable and discharges exhaustiveness, so `Dispatch` has no
// `default`), with reordered designated fields exercised in `Reordered`.
// The C++ mental model is a `switch` on one member plus member reads:
//   switch (s.tag) { case 1: return 100; case 2: return s.value;
//                    default: return s.tag * 1000 + s.value; }
// Runtime inputs go through the RuntimeSeed(x) = x + 20 convention so the
// arms run against real runtime values, not constant folds
// (match_irrefutable_no_default.carbon precedent). Expected values derived
// by hand from the C++ mental model (R16(d)):
//   Dispatch(1, 5)   -> tag 1 arm      -> 100
//   Dispatch(2, 33)  -> tag 2 arm      -> value = 33
//   Dispatch(7, 4)   -> binding arm    -> 7 * 1000 + 4 = 7004
//   Reordered(21, 22) -> {.b = 22, .a = 21} arm -> 1
//   Reordered(21, 23) -> {.a = 21, .b = 23} arm -> 2
//   Reordered(9, 10)  -> all-binding arm        -> 9 + 10 = 19

import Core library "io";

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// switch (s.tag) with member reads: constant-field arms first, then the
// all-binding catch-all (spelled as shorthand bindings, no `default`).
fn Dispatch(a: i32, b: i32) -> i32 {
  var s: {.tag: i32, .value: i32} = {.tag = a, .value = b};
  match (s) {
    case {.tag = 1, _} => { return 100; }
    case {.tag = 2, .value = v: i32} => { return v; }
    case {tag: i32, value: i32} => { return tag * 1000 + value; }
  }
  // Unreachable belt: the all-binding arm always matches. If a
  // checker/lowering bug let the match fall through, this makes the
  // program fail loudly (exit 1 below).
  return -1;
}

// Reordered designated fields dispatch by value equality on both fields:
// each field-pattern matches the same-named element, order-free.
fn Reordered(c: i32, d: i32) -> i32 {
  var s: {.a: i32, .b: i32} = {.a = c, .b = d};
  match (s) {
    case {.b = 22, .a = 21} => { return 1; }
    case {.a = 21, .b = 23} => { return 2; }
    case {a: i32, b: i32} => { return a + b; }
  }
  return -1;
}

fn Run() -> i32 {
  // Constant-field arms win first-match-wins; the subset+`_` arm ignores
  // `.value` entirely.
  Core.Print(Dispatch(RuntimeSeed(-19), RuntimeSeed(-15)));
  // The designated binding arm returns the destructured field.
  Core.Print(Dispatch(RuntimeSeed(-18), RuntimeSeed(13)));
  // The shorthand all-binding arm destructures both fields.
  Core.Print(Dispatch(RuntimeSeed(-13), RuntimeSeed(-16)));
  // Reordered designated fields: both orders dispatch correctly.
  Core.Print(Reordered(RuntimeSeed(1), RuntimeSeed(2)));
  Core.Print(Reordered(RuntimeSeed(1), RuntimeSeed(3)));
  Core.Print(Reordered(RuntimeSeed(-11), RuntimeSeed(-10)));
  // Exit-code belt.
  if (Dispatch(RuntimeSeed(-18), RuntimeSeed(13)) != 33) { return 1; }
  return 0;
}
