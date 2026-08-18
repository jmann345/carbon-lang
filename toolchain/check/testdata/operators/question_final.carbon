// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/question_final.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/question_final.carbon

// The W-072 dissolution probes, positive half (fork/w072/plan.md §3, W72a;
// probes P-1..P-3 and P-8): under the ratified doc's own `final impl`
// spelling (docs/design/error_handling.md `Try` impl sketches;
// docs/design/generics/details.md, "`final` impl declarations"), impl
// lookup under a SYMBOLIC query may apply the impl's `where` rewrites
// (eval_inst.cpp `ImplWitness` arm via `EvalLookupSingleFinalWitness`), so
// the `?` continue value on a symbolic choice-specific operand binds `: T`
// — the shape the non-final idiom cannot spell BY UPSTREAM DESIGN
// (specialization soundness; the permanent negative pins are
// question.carbon's generic.carbon subfile and upstream's
// impl/lookup/specialization_with_symbolic_rewrite.carbon). Impl bodies
// keep the match-reconstruct + `Diverge` idiom (fork/b1/plan.md §2.6): the
// in-body path is NOT expected to change under `final` (plan §2.2,
// correctness F-2); the in-body observation probe is
// fail_question_final.carbon's fail_inbody_recursive_branch.carbon.

// --- thread.carbon
library "[[@TEST_NAME]]";

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

// The doc's sanctioned spelling: `final` exempts this impl from
// specialization, which is exactly what licenses impl lookup to apply
// `.ContinueType = T and .BreakType = E` under a symbolic query
// (details.md; proposals p000983/p002868/p005337).
final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6): in-body
    // lookups already treated the being-defined impl as final
    // (impl_lookup.cpp `TreatImplAsFinal`), so the B1b in-body
    // non-collapse is expected unchanged by the `final` modifier — the
    // observation probe lives in fail_question_final.carbon.
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// An explicitly `T2`-typed sink (explicit generic argument, NOT deduced
// from the value): P-2's pass-as-`T` pin — a deduced sink would accept the
// unreduced projection too (the P-4 wart shape), so deduction here would
// not distinguish the outcomes.
fn Consume(generic T2: type, x: T2) {}

//@dump-sem-ir-begin
// P-1: the core prediction — the continue value of `mr?` on the SYMBOLIC
// operand `mr: MyResult(T, E)` binds `: T`, because the final impl's
// rewrite reduces the carrier to `Core.ControlFlow(T, E)` at check time.
// P-2: the bound value passes where `T` is expected (explicit-argument
// sink) and wraps back through `Ok` — the full threading round trip.
fn Thread[T: type, E: type](mr: MyResult(T, E)) -> MyResult(T, E) {
  let v: T = mr?;
  Consume(T, v);
  return MyResult(T, E).Ok(v);
}
//@dump-sem-ir-end

// --- mixed.carbon
library "[[@TEST_NAME]]";

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

final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6).
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

//@dump-sem-ir-begin
// P-3: the MIXED specific `MyResult(T, i32)` — one symbolic and one
// concrete argument. Deduction against the final impl must produce the
// partially-concrete specific (`T`, `i32`); operand and return are the
// SAME specific so the break path's `FromBreak` ImplicitAs conversion
// stays aligned projection-for-projection (the `PropagateChoice`
// configuration, now with the continue value threaded rather than sunk).
// Falsifier: deduction failure on the partially-concrete query
// (fork/w072/plan.md §2.4 step 2).
fn ThreadMixed[T: type](mr: MyResult(T, i32)) -> MyResult(T, i32) {
  let v: T = mr?;
  return MyResult(T, i32).Ok(v);
}
//@dump-sem-ir-end

// --- lib.carbon
library "[[@TEST_NAME]]";

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

// P-8 setup: choice + final impl in ONE file (the same-file requirement,
// impl_validation.cpp `FinalImplInvalidFile`), consumed from the importing
// file below.
final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6).
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

//@dump-sem-ir-begin
// P-8: import parity — the final impl's reduction must survive import
// (the impl/lookup/import_final.carbon precedent; the W-069 family is the
// named falsifier, fork/w072/plan.md §2.4 step 2). Same threading shape
// as thread.carbon, operand type imported.
fn ThreadImported[T: type, E: type](mr: MyResult(T, E)) -> MyResult(T, E) {
  let v: T = mr?;
  return MyResult(T, E).Ok(v);
}
//@dump-sem-ir-end
