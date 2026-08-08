// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: dedicated control flow constructs
// EXPECT-EXIT: 0
//
// Differential pair — the B1b `?` propagation arbiter (fork/b1/plan.md §3).
// The C++ oracle in question_propagation_diff.diff.cpp is a struct-shaped
// result (`{bool ok; int v;}`) with explicit early returns — the exact
// control flow `?` desugars to — over the same 3-deep call chain
// (Top → Mid → Leaf). The failure is injected at a RUNTIME-SELECTED depth
// (0 = no failure, 1..3 = the failing level), and every payload is
// runtime-computed (R16d), each level tagging its error with a distinct
// base (10/20/30) and its accumulator, so byte-identical output pins WHERE
// propagation stopped and WHAT the break payload was after crossing one or
// two `?` boundaries. Byte-identical exit code and stdout are required per
// DIFF-1; no EXPECT-STDOUT — C++ computes the expectation. The `Branch`
// impl body uses the match-reconstruct style (plan §2.6).

import Core library "io";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6): reachability
    // doesn't consult match exhaustiveness; no generic `ControlFlow(T, E)`
    // value is conjurable, so recurse through the interface.
    return self.(Core.Try.Branch)();
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

fn Leaf(n: i32, fail_at: i32) -> MyResult(i32, i32) {
  if (fail_at == 3) { return MyResult(i32, i32).Err(30 + n); }
  return MyResult(i32, i32).Ok(n + 1);
}

fn Mid(n: i32, fail_at: i32) -> MyResult(i32, i32) {
  var v: i32 = Leaf(n, fail_at)?;
  if (fail_at == 2) { return MyResult(i32, i32).Err(20 + v); }
  return MyResult(i32, i32).Ok(v + 1);
}

fn Top(n: i32, fail_at: i32) -> MyResult(i32, i32) {
  var v: i32 = Mid(n, fail_at)?;
  if (fail_at == 1) { return MyResult(i32, i32).Err(10 + v); }
  return MyResult(i32, i32).Ok(v + 1);
}

// Prints the outcome tag (0 = Ok, 1 = Err) and the payload.
fn Probe(fail_at: i32, seed: i32) {
  match (Top(seed, fail_at)) {
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

fn RuntimeSeed(x: i32) -> i32 { return x + 40; }

fn Run() -> i32 {
  // Depths and seeds are both runtime-computed: RuntimeSeed(-40..-37)
  // selects the failing level 0..3, RuntimeSeed(2) = 42 seeds the chain.
  Probe(RuntimeSeed(-40), RuntimeSeed(2));
  Probe(RuntimeSeed(-39), RuntimeSeed(2));
  Probe(RuntimeSeed(-38), RuntimeSeed(2));
  Probe(RuntimeSeed(-37), RuntimeSeed(2));
  return 0;
}
