// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: Sum types (discriminated unions)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   1
//   0
//   1
//
// W5-S3a arbiter (fork/w5-s3/plan.md §3): specifics of a GENERIC choice as
// `match` scrutinees, payload-free and runtime-observable. Two specifics of
// one generic choice (`Pair(i32)`, `Pair(bool)`) are constructed through
// alternative constants resolved per specific and matched by discriminant
// dispatch; each match is EXHAUSTIVE WITHOUT `default` — the S3a lift also
// routes SF-7 exhaustiveness through specifics (the doc's `Optional(i32)`
// shape, sum_types.md:60-89, modulo payloads until S3b). WHICH value is
// matched is runtime-selected (a branch on a function argument, R16d), so
// constant folding cannot fake the dispatch read. Values are `let`-bound
// and passed by value — a workaround record now historical (retexted
// 2026-08-18): when this program landed, choices had no `Copy` impl
// (SF-6's recorded scope), so `var`/return initialization from a constant
// was out; W-075's synthesized choice `Core.Copy` witness lifted that,
// the `let` spelling here is retained as landed, and the `var`-from-
// constant shape is arbitrated by
// control_flow/choice_generic_roundtrip_diff.carbon.
// Expected prints derive from the source: First -> 0, Second -> 1, probed
// once per alternative per specific.

import Core library "io";

choice Pair(T: type) {
  First,
  Second
}

fn ClassifyI(p: Pair(i32)) -> i32 {
  match (p) {
    case .First => { return 0; }
    case .Second => { return 1; }
  }
  return -1;
}

fn ClassifyB(p: Pair(bool)) -> i32 {
  match (p) {
    case .First => { return 0; }
    case .Second => { return 1; }
  }
  return -1;
}

// Runtime-selected scrutinee: which of the two by-value operands is matched
// depends on `n`, so the discriminant compare cannot be constant-folded.
fn ChooseI(n: i32, a: Pair(i32), b: Pair(i32)) -> i32 {
  if (n > 0) { return ClassifyI(b); }
  return ClassifyI(a);
}

fn ChooseB(n: i32, a: Pair(bool), b: Pair(bool)) -> i32 {
  if (n > 0) { return ClassifyB(b); }
  return ClassifyB(a);
}

fn Run() -> i32 {
  let fi: Pair(i32) = Pair(i32).First;
  let si: Pair(i32) = Pair(i32).Second;
  let fb: Pair(bool) = Pair(bool).First;
  let sb: Pair(bool) = Pair(bool).Second;
  Core.Print(ChooseI(0, fi, si));
  Core.Print(ChooseI(7, fi, si));
  Core.Print(ChooseB(0, fb, sb));
  Core.Print(ChooseB(7, fb, sb));
  // Belt: a wrong discriminant roundtrip fails loudly, not just in stdout.
  if (ChooseI(7, fi, si) != 1) { return 1; }
  if (ChooseB(0, fb, sb) != 0) { return 1; }
  return 0;
}
