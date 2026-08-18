// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: dedicated control flow constructs
// EXPECT-EXIT: 0
//
// Differential pair — the W72b continue-THREADING runtime arbiter, the
// pair whose PASS discharges W-072 (fork/w072/plan.md §3 W72b, §6): under
// the ratified doc's own `final impl` spelling
// (docs/design/error_handling.md's `Try` sketches;
// docs/design/generics/details.md, "`final` impl declarations"), the `?`
// continue value on a SYMBOLIC choice-specific operand binds `: T` — the
// dissolved shape the W72a check golden proved statically
// (toolchain/check/testdata/operators/question_final.carbon). This pair
// arbitrates it at RUNTIME with the threaded values LOAD-BEARING in the
// observable payload: each step's input is computed from the PREVIOUS
// step's threaded output (`let a: T = Step(x, ..., 101)?;` then
// `let b: T = Step(a.Combine(), ..., 202)?;` and `Ok(b)` — the plan's
// Combine(a)-style chaining), so a mistyped, misrouted, or
// seed-reconstructed continue value CHANGES the output — unlike the
// sibling pair's seed-reconstruction shape (question_generic_diff, the
// break-path + layout arbiter, unchanged per R16). Instantiated at i32
// AND i64 (distinct monomorphized `Core.ControlFlow` carrier layouts);
// failure depth and seeds are runtime-computed (R16d), each step tagging
// its error with a distinct base (101/202), so byte-identical output pins
// where propagation stopped AND what value was threaded. The C++ oracle
// in question_generic_thread_diff.diff.cpp is a function TEMPLATE with
// the same explicit early-return semantics, computing the expectation
// independently. Exit code and stdout must be byte-identical per DIFF-1;
// no EXPECT-STDOUT — C++ computes the expectation. The `Branch` impl
// body uses the match-reconstruct style (fork/b1/plan.md §2.6) with the
// interface-recursive unreachable trailing return — the W-073
// simplification: under `final` the in-body recursive call
// type-collapses (the P-9 pin, question_final.carbon's
// inbody_recursive_branch split), so the former `Diverge` helper is
// deleted; the reachable control flow is unchanged.
//
// Broken-oracle drill (R-5; mechanism declared at the 2026-08-18 plan fix
// round, fork/w072/plan.md §3 W72b — strictness F-5): with no local
// bazel, the drill is a B2a-style DELIBERATE RED CI PUSH — this pair
// rides the PR branch ONCE with the injected failure depth flipped in
// this `.carbon` side only (step 1's `fail_at == 1` -> `fail_at == 3`,
// making the Carbon leg succeed where the oracle breaks), the red
// differential run is linked in the decision log as the drill evidence,
// and the flip is reverted in the next commit before landing. An
// always-green pair under the flip is falsification.

import Core library "io";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// The doc's sanctioned spelling: `final` exempts this impl from
// specialization, which is exactly what licenses impl lookup to apply
// `.ContinueType = T and .BreakType = E` under a symbolic query
// (details.md; proposals p000983/p002868/p005337) — so the `?` continue
// values below thread as `T` instead of typing as unreduced projections.
final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable trailing return (reachability doesn't consult match
    // exhaustiveness — fork/b1/plan.md §2.6, W-073 dated amendment):
    // under this `final` impl the interface-recursive call
    // type-collapses (the P-9 pin, question_final.carbon's
    // inbody_recursive_branch split), so no `Diverge` helper is needed.
    // The match above is exhaustive; this line never executes.
    return self.(Core.Try.Branch)();
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// The per-type transform the chain applies to each threaded continue
// value — the arbiter-verified generics/checked_generics.carbon interface
// shape (a user interface with concrete impls, called through the
// witness in the generic body). Combine(x) = x + x, so the chain's Ok
// payload (2 * seed) differs from the seed and cannot be reconstructed
// without the threaded value.
interface Combinable {
  fn Combine(self) -> Self;
}

impl i32 as Combinable {
  fn Combine(self) -> Self { return self + self; }
}

impl i64 as Combinable {
  fn Combine(self) -> Self { return self + self; }
}

// A generic step: passes `x` through, or fails with the given tag.
fn Step[T: type](x: T, fail: bool, tag: i32) -> MyResult(T, i32) {
  if (fail) { return MyResult(T, i32).Err(tag); }
  return MyResult(T, i32).Ok(x);
}

// The threading chain (the dissolved shape — this is the point): both `?`
// continue values are bound `: T` (licensed by the final impl's rewrites)
// and each is load-bearing — `a` feeds step 2's input through `Combine`,
// and `b` (step 2's threaded output, = Combine(a) = 2 * seed on success)
// IS the returned Ok payload. Operand and return type are the SAME
// specific, so the break path's `FromBreak` conversion stays aligned
// (the mixed-specific `MyResult(T, i32)` configuration, question_final
// P-3), and both carrier temporaries ride the B2a symbolic-choice
// destroy widening per instantiation. `T` carries `& Core.Destroy`
// because the generic body destroys T-typed temporaries (the
// `a.Combine()` argument temp): a bare `Combinable` facet exposes only
// `Combine`, while the `type` facet the W72a probes used carries the
// Destroy witness implicitly (impl/custom_witness/destroy.carbon's
// `type as Core.Destroy` pin; the combined-facet binding shape is
// facet/call_combined_impl_witness.carbon's `G[T: A & Empty & B]`).
fn Chain[T: Combinable & Core.Destroy](x: T, fail_at: i32) -> MyResult(T, i32) {
  let a: T = Step(x, fail_at == 1, 101)?;
  let b: T = Step(a.Combine(), fail_at == 2, 202)?;
  return MyResult(T, i32).Ok(b);
}

// Prints the outcome tag (0 = Ok, 1 = Err) and the payload.
fn ProbeI(fail_at: i32, seed: i32) {
  match (Chain(seed, fail_at)) {
    case .Ok(v: i32) => {
      Core.Print(0);
      Core.Print(v);
    }
    case .Err(e: i32) => {
      Core.Print(1);
      Core.Print(e);
    }
  }
}

// The i64 instantiation: prints the outcome tag, then 1/0 for whether the
// Ok payload matches the independently runtime-computed expectation
// (Core.Print takes i32 only), or the i32 break payload directly.
// ACKNOWLEDGED CHANNEL LIMIT (review round): the i64 payload is observed
// through this single boolean, so the leg's arbitration power comes from
// the seed being HIGH-HALF-SIGNIFICANT (> 2^32): a truncate-then-extend
// width collapse of the payload (the B2a mixed-width corruption family)
// zeroes the high half and flips the boolean. With a narrow seed the
// same corruption would pass invisibly — which is why the seeds below
// do not fit in 32 bits.
fn ProbeL(fail_at: i32, seed: i64, expect: i64) {
  match (Chain(seed, fail_at)) {
    case .Ok(v: i64) => {
      Core.Print(0);
      if (v == expect) {
        Core.Print(1);
      } else {
        Core.Print(0);
      }
    }
    case .Err(e: i32) => {
      Core.Print(1);
      Core.Print(e);
    }
  }
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn RuntimeSeedL(x: i64) -> i64 { return x + 20; }

fn Run() -> i32 {
  // Depths and seeds are runtime-computed: RuntimeSeed(-20..-18) selects
  // the failing step 0..2, RuntimeSeed(22) = 42 seeds the i32 chain,
  // RuntimeSeedL(4294967320) = 2^32 + 44 the i64 chain (high-half
  // significant — see ProbeL's channel note), and
  // RuntimeSeedL(8589934660) = 2^33 + 88 is the i64 Ok expectation
  // (= 2 * (2^32 + 44)), computed WITHOUT going through the chain or
  // `Combine`.
  ProbeI(RuntimeSeed(-20), RuntimeSeed(22));
  ProbeI(RuntimeSeed(-19), RuntimeSeed(22));
  ProbeI(RuntimeSeed(-18), RuntimeSeed(22));
  ProbeL(RuntimeSeed(-20), RuntimeSeedL(4294967320), RuntimeSeedL(8589934660));
  ProbeL(RuntimeSeed(-19), RuntimeSeedL(4294967320), RuntimeSeedL(8589934660));
  ProbeL(RuntimeSeed(-18), RuntimeSeedL(4294967320), RuntimeSeedL(8589934660));
  return 0;
}
