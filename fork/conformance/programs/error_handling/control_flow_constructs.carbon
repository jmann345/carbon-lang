// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: dedicated control flow constructs
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   -1
//
// The B1b arbiter (fork/b1/plan.md §3/§8): Carbon's dedicated error-handling
// control-flow construct is the postfix `?` operator over `Core.Try`
// (F-006), arbitrated here over a USER-DEFINED generic choice — prelude
// `Core.Result` rides the SF-9/W5-S3p round and is deliberately not named.
// Both `?` paths are observed at runtime: the continue path (Doubled(42/2)
// prints 42) and the break path (a negative input's `Err` propagates out of
// `Doubled` through `?`, prints -1). Inputs are runtime-computed (R16d), so
// the discriminant dispatch cannot be constant-folded; consumption is by
// exhaustive `match` without `default`; the `Branch` impl body uses the
// match-reconstruct style (plan §2.6; reason retexted 2026-08-18 per W-075
// — choices now carry a synthesized `Core.Copy` witness, and the body must
// still reconstruct because `Branch` returns the `ControlFlow` carrier,
// not `Self`). Impossible arms
// return their payloads, so a wrong path fails loudly by exit code, not
// just stdout.

import Core library "io";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction). The explicit generic type
// param + self-recursion is the arbiter-verified
// function/generic/deduce.carbon `ExplicitGenericParam` shape.
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6, W-073 dated
    // amendment): reachability doesn't consult match exhaustiveness; no
    // generic `ControlFlow(T, E)` value is conjurable, and through this
    // NON-final impl the interface-recursive call does not type-collapse
    // (upstream specialization soundness keeps its projections unreduced;
    // under `final` it does — toolchain/check/testdata/operators/
    // question_final.carbon), so diverge through the helper.
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

fn ParsePositive(n: i32) -> MyResult(i32, i32) {
  if (n < 0) { return MyResult(i32, i32).Err(-1); }
  return MyResult(i32, i32).Ok(n);
}

fn Doubled(n: i32) -> MyResult(i32, i32) {
  // The dedicated propagation construct: on `Err`, `?` rebuilds it through
  // `Core.Try.FromBreak` on the return type and returns it to the caller.
  var v: i32 = ParsePositive(n)?;
  return MyResult(i32, i32).Ok(v * 2);
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  match (Doubled(RuntimeSeed(1))) {
    case .Ok(v: i32) => { Core.Print(v); }
    case .Err(e: i32) => { return e; }
  }
  match (Doubled(RuntimeSeed(-50))) {
    case .Ok(v: i32) => { return v; }
    case .Err(e: i32) => { Core.Print(e); }
  }
  return 0;
}
