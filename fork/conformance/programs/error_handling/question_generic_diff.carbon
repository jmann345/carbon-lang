// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Error handling: dedicated control flow constructs
// EXPECT-EXIT: 0
//
// Differential pair — the B2a W-071 discharge arbiter (fork/b2/plan.md
// §2.5): a GENERIC `?` chain whose operands are SYMBOLIC choice specifics
// (`MyResult(T, i32)` under `T: type`), instantiated at TWO distinct type
// arguments (i32 and i64) so the monomorphized `Core.ControlFlow`
// carriers are distinct specifics with distinct payload layouts at
// runtime. The C++ oracle in question_generic_diff.diff.cpp is a function
// TEMPLATE with explicit early returns — the control flow the generic `?`
// desugars to — instantiated at the matching types. The failure is
// injected at a RUNTIME-SELECTED depth (0 = none, 1 = first step, 2 =
// second step) and every payload is runtime-computed (R16d), each step
// tagging its error with a distinct base (101/202), so byte-identical
// output pins WHERE propagation stopped inside the generic body and WHAT
// the break payload was. The i64 leg additionally compares the continue
// payload against a runtime-computed expectation, so a corrupted i64
// payload roundtrip through the wider carrier layout breaks the
// byte-identical-output requirement. Exit code and stdout must be
// byte-identical per DIFF-1; no EXPECT-STDOUT — C++ computes the
// expectation. The `Branch` impl body uses the match-reconstruct style
// (fork/b1/plan.md §2.6).

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
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6, dated
    // correction): reachability doesn't consult match exhaustiveness; no
    // generic `ControlFlow(T, E)` value is conjurable, and the
    // interface-recursive call does not type-collapse (its return type's
    // associated-constant projections are not reduced by this impl's own
    // `where` rewrites), so diverge through the helper.
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// A generic step: passes `x` through, or fails with the given tag.
fn Step[T: type](x: T, fail: bool, tag: i32) -> MyResult(T, i32) {
  if (fail) { return MyResult(T, i32).Err(tag); }
  return MyResult(T, i32).Ok(x);
}

// The generic `?` chain (the W-071 shape, runtime-arbitrated): both `?`
// operands are temporaries of the SYMBOLIC choice specific
// `MyResult(T, i32)`, so their carrier and operand discharges both ride
// `CanDestroyClass`'s choice clause at check time and re-derive concrete
// witnesses per instantiation.
fn Chain[T: type](x: T, fail_at: i32) -> MyResult(T, i32) {
  let a: T = Step(x, fail_at == 1, 101)?;
  let b: T = Step(a, fail_at == 2, 202)?;
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
// continue payload matches the runtime-computed expectation (Core.Print
// takes i32 only), or the i32 break payload directly.
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

fn RuntimeSeed(x: i32) -> i32 { return x + 40; }

fn RuntimeSeedL(x: i64) -> i64 { return x + 40; }

fn Run() -> i32 {
  // Depths and seeds are runtime-computed: RuntimeSeed(-40..-38) selects
  // the failing step 0..2, RuntimeSeed(2) = 42 seeds the i32 chain and
  // RuntimeSeedL(4) = 44 the i64 chain.
  ProbeI(RuntimeSeed(-40), RuntimeSeed(2));
  ProbeI(RuntimeSeed(-39), RuntimeSeed(2));
  ProbeI(RuntimeSeed(-38), RuntimeSeed(2));
  ProbeL(RuntimeSeed(-40), RuntimeSeedL(4), RuntimeSeedL(4));
  ProbeL(RuntimeSeed(-39), RuntimeSeedL(4), RuntimeSeedL(4));
  ProbeL(RuntimeSeed(-38), RuntimeSeedL(4), RuntimeSeedL(4));
  return 0;
}
