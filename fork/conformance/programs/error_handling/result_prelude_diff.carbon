// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: dedicated control flow constructs
// EXPECT-EXIT: 0
//
// Differential pair — the EH-A prelude `Core.Result` arbiter (fork/eh/plan.md
// §5.A.1): the question_propagation_diff shape (a 3-deep call chain
// Top → Mid → Leaf with the failure injected at a RUNTIME-SELECTED depth)
// over the PRELUDE `Core.Result(i32, E)` and its `final impl ... as
// Core.Try` (core/prelude/types/result.carbon) — no user choice and no user
// `Try` impl appear here — plus one `ImplicitAs` error-conversion layer:
// `Leaf`/`Mid`/`Fail` produce `Core.Result(i32, ErrA)`, `Top` returns
// `Core.Result(i32, ErrB)`, and every error crosses the `ErrA -> ErrB`
// conversion (which adds 1000) exactly once, inside the prelude `FromBreak`
// call at one of `Top`'s two `?` sites (D3/F-006c). The C++ oracle in
// result_prelude_diff.diff.cpp is a struct-shaped result with explicit
// early returns and the same +1000 layer. Byte-identical exit code and
// stdout are required per DIFF-1; no EXPECT-STDOUT — C++ computes the
// expectation. Hand-derived table, both sides (seed = RuntimeSeed(22) = 42):
// depth 0 → `0`, `84` (2 * seed); depth 1 → `1`, `1101`; depth 2 → `1`,
// `1202`; depth 3 → `1`, `1303`.

import Core library "io";

class ErrA {
  adapt i32;
}

class ErrB {
  adapt i32;
}

impl ErrA as Core.Copy {
  fn Op(self) -> Self = "primitive_copy";
}

impl ErrB as Core.Copy {
  fn Op(self) -> Self = "primitive_copy";
}

// The one conversion layer: an `ErrA` code becomes `code + 1000` as `ErrB`.
impl ErrA as Core.ImplicitAs(ErrB) {
  fn Convert(self) -> ErrB { return ((self as i32) + 1000) as ErrB; }
}

fn Fail(code: i32) -> Core.Result(i32, ErrA) {
  return Core.Result(i32, ErrA).Err(code as ErrA);
}

fn Leaf(n: i32, fail_at: i32) -> Core.Result(i32, ErrA) {
  if (fail_at == 3) { return Core.Result(i32, ErrA).Err((303 as i32) as ErrA); }
  return Core.Result(i32, ErrA).Ok(n * 2);
}

fn Mid(n: i32, fail_at: i32) -> Core.Result(i32, ErrA) {
  // `?` over the prelude type: `ErrA` propagates as `ErrA`, no conversion.
  var v: i32 = Leaf(n, fail_at)?;
  if (fail_at == 2) { return Core.Result(i32, ErrA).Err((202 as i32) as ErrA); }
  return Core.Result(i32, ErrA).Ok(v);
}

fn Top(n: i32, fail_at: i32) -> Core.Result(i32, ErrB) {
  // Both `?` sites convert a propagated `ErrA` to this function's `ErrB`.
  var v: i32 = Mid(n, fail_at)?;
  if (fail_at == 1) { Fail(101)?; }
  return Core.Result(i32, ErrB).Ok(v);
}

// Prints the outcome tag (0 = Ok, 1 = Err) and the payload.
fn Probe(fail_at: i32, seed: i32) {
  match (Top(seed, fail_at)) {
    case .Ok(v: i32) => {
      Core.Print(0);
      Core.Print(v);
    }
    case .Err(e: ErrB) => {
      Core.Print(1);
      Core.Print(e as i32);
    }
  }
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  // Depths and seeds are both runtime-computed: RuntimeSeed(-20..-17)
  // selects the failing level 0..3, RuntimeSeed(22) = 42 seeds the chain.
  Probe(RuntimeSeed(-20), RuntimeSeed(22));
  Probe(RuntimeSeed(-19), RuntimeSeed(22));
  Probe(RuntimeSeed(-18), RuntimeSeed(22));
  Probe(RuntimeSeed(-17), RuntimeSeed(22));
  return 0;
}
