// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/fail_question_final.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/fail_question_final.carbon

// The W-072 dissolution probes, negative half (fork/w072/plan.md §3, W72a;
// probes P-6, P-7, and the P-9 observation): the guardrails around the
// `final impl` lane. P-6 pins that a disagreeing narrower impl after the
// final impl is DIAGNOSED, never silently accepted (risk R-3); P-7 pins
// the same-file requirement for a choice defined elsewhere; P-9 observes
// the in-body interface-recursive call, predicted to stay a conversion
// error under `final` (plan §2.2, correctness F-2). STDERR pins are
// hand-written best-effort per the plan's P-6 note — the runner regen is
// the arbiter of the exact diagnostic family and spans.

// --- fail_specialize_after_final.carbon
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

// P-6: a disagreeing NARROWER impl after the final impl — the
// specialization the `final` modifier forbids (details.md, "`final` impl
// declarations"; the semantic cost stated in fork/w072/plan.md §2.2).
// Silent acceptance is the falsifier (halt per risk R-3). Diagnostic
// pinned best-effort from the final-overlap family
// (impl/lookup/impl_overlap.carbon's fail_final_overlaps_later_non_final
// precedent); the poisoned-query family
// (specialization_poison.carbon's PoisonedImplLookupConcreteResult) is
// the plan's named alternative — repin from the CI run if it differs.
// CHECK:STDERR: fail_specialize_after_final.carbon:[[@LINE+7]]:1: error: `impl` will never be used [ImplFinalOverlapsNonFinal]
// CHECK:STDERR: impl MyResult(i32, i32) as Core.Try
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_specialize_after_final.carbon:[[@LINE-26]]:1: note: `final impl` declared here would always be used instead [ImplFinalOverlapsNonFinalNote]
// CHECK:STDERR: final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
impl MyResult(i32, i32) as Core.Try
    where .ContinueType = () and .BreakType = i32 {
  fn Branch(self) -> Core.ControlFlow((), i32) {
    match (self) {
      // The disagreeing continue type: payloads route to `Break` so both
      // bindings are used without conjuring an `i32` continue value.
      case .Ok(v: i32) => { return Core.ControlFlow((), i32).Break(v); }
      case .Err(e: i32) => { return Core.ControlFlow((), i32).Break(e); }
    }
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6).
    return Diverge(Core.ControlFlow((), i32));
  }
  fn FromBreak(e: i32) -> Self { return MyResult(i32, i32).Err(e); }
}

// --- choice_lib.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// --- fail_final_impl_crossfile.carbon
library "[[@TEST_NAME]]";

import library "choice_lib";

// Returns a value of any type by never returning — the unreachable
// trailing-return helper for generic match-reconstruct bodies
// (fork/b1/plan.md §2.6, dated correction). The explicit generic type
// param + self-recursion is the arbiter-verified
// function/generic/deduce.carbon `ExplicitGenericParam` shape.
fn Diverge(generic T2: type) -> T2 { return Diverge(T2); }

// P-7: a `final impl` for a choice defined in a DIFFERENT file, with the
// interface (`Core.Try`) also imported — neither root self type nor
// interface is in this file, so the same-file rule rejects it
// (impl_validation.cpp `FinalImplInvalidFile`; the known constraint,
// fork/w072/plan.md §1). This is why every positive probe declares the
// choice and its final impl in one file.
// CHECK:STDERR: fail_final_impl_crossfile.carbon:[[@LINE+4]]:1: error: `final impl` found in file that does not contain the root self type nor the interface definition [FinalImplInvalidFile]
// CHECK:STDERR: final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
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

// --- fail_inbody_recursive_branch.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// P-9 (OBSERVATION probe, fork/w072/plan.md §3 — no gate): does the
// in-body interface-recursive call type-collapse under `final`?
// Prediction: NO — in-body lookups already treated the being-defined impl
// as final (impl_lookup.cpp `TreatImplAsFinal` via `is_being_defined`),
// and the in-body path (`GetImplSelfWitnessInsideImplDecl`) skips the
// deduced-specific substitution (plan §2.2, correctness F-2), so B1b's
// recorded non-collapse — the reason the `Diverge` idiom exists
// (fork/b1/plan.md §2.6) — stands, and the trailing interface-recursive
// return below stays a conversion error. MINTING RULE (plan §3, P-9 row):
// if the regen instead shows collapse (this subfile compiling clean),
// that FALSIFIES the eight-file "does not type-collapse" comment family
// and a follow-up work item MUST be minted to retext the family and
// revisit the idiom — the idiom is NOT revised in this plan either way.
final impl forall [T: type, E: type] MyResult(T, E) as Core.Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Core.ControlFlow(T, E) {
    match (self) {
      case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
      case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
    }
    // Best-effort pin (the fail_nonfinal_specialized_symbolic_rewrite
    // ConversionFailure shape); the regen is the arbiter of the exact
    // projection spelling and span.
    // CHECK:STDERR: fail_inbody_recursive_branch.carbon:[[@LINE+7]]:5: error: cannot implicitly convert expression of type `Core.ControlFlow(MyResult(T, E).(Core.Try.ContinueType), MyResult(T, E).(Core.Try.BreakType))` to `Core.ControlFlow(T, E)` [ConversionFailure]
    // CHECK:STDERR:     return self.(Core.Try.Branch)();
    // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR: fail_inbody_recursive_branch.carbon:[[@LINE+4]]:5: note: type `Core.ControlFlow(MyResult(T, E).(Core.Try.ContinueType), MyResult(T, E).(Core.Try.BreakType))` does not implement interface `Core.ImplicitAs(Core.ControlFlow(T, E))` [MissingImplInMemberAccessInContext]
    // CHECK:STDERR:     return self.(Core.Try.Branch)();
    // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR:
    return self.(Core.Try.Branch)();
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}
