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
// the break payload was. The i64 leg additionally compares the Ok
// payload against a runtime-computed expectation, so a corrupted i64
// payload roundtrip through the wider specific's layout breaks the
// byte-identical-output requirement. Exit code and stdout must be
// byte-identical per DIFF-1; no EXPECT-STDOUT — C++ computes the
// expectation. The `Branch` impl body uses the match-reconstruct style
// (fork/b1/plan.md §2.6).
//
// SCOPE (retexted at the W-072 dissolution, fork/w072/plan.md §3): what
// this pair arbitrates at runtime is BREAK-path propagation — that each
// instantiation's `?` early-returns at the runtime-selected depth with
// the right converted payload, riding the B2a symbolic-choice destroy
// widening for its carrier and operand temporaries. The `?` CONTINUE
// values are consumed through the check golden's proven deduced-sink
// shape (`Discard`) — a DESIGN CHOICE of this pair (kept unchanged per
// R16), not a language limit. The honest two-part statement replacing
// the earlier narrowing: (i) through this pair's NON-final impl the
// continue value does type as the unreduced projection
// `MyResult(T, i32).(Core.Try.ContinueType)` — that is upstream-DESIGNED
// specialization soundness (docs/design/generics/details.md, "`final`
// impl declarations"), not pending rewrite-reduction; (ii) under the
// ratified doc's own `final impl` spelling
// (docs/design/error_handling.md's `Try` sketches) the continue value
// threads as `T` with no compiler change
// (toolchain/check/testdata/operators/question_final.carbon). The Ok
// payload is reconstructed from `x` — the identical value, since `Step`
// passes `x` through — keeping the output table and the layout-roundtrip
// observation intact; the continue-THREADING runtime arbiter is the W72b
// sibling pair (question_generic_thread_diff, staged in
// fork/w072/plan.md §3).

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

// Payload sink — the check golden's proven deduced-sink shape
// (toolchain/check/testdata/operators/question.carbon `Discard`).
fn Discard[U: type](_: U) {}

// The generic `?` chain (the W-071 shape, runtime-arbitrated): both `?`
// operands are temporaries of the SYMBOLIC choice specific
// `MyResult(T, i32)`, so their carrier and operand discharges both ride
// `CanDestroyClass`'s choice clause at check time and re-derive concrete
// witnesses per instantiation. Operand and return type are the SAME
// specific, so the break path's `FromBreak` conversion aligns
// projection-for-projection (the check golden's `PropagateChoice`
// configuration); continue values go through `Discard` — this pair's
// design choice, per the SCOPE note in the header (the `final impl`
// threading arbiter is the W72b sibling pair).
fn Chain[T: type](x: T, fail_at: i32) -> MyResult(T, i32) {
  Discard(Step(x, fail_at == 1, 101)?);
  Discard(Step(x, fail_at == 2, 202)?);
  return MyResult(T, i32).Ok(x);
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
// Ok payload matches the runtime-computed expectation (Core.Print takes
// i32 only), or the i32 break payload directly.
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
