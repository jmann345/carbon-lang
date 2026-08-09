// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/fail_question_generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/fail_question_generic.carbon

// The B2a probes bounding the W-071 discharge (fork/b2/plan.md §2.2-2.3,
// §3): the uniformity pin for symbolic-typed operand TEMPORARIES (risks
// R-2/R-3 — the widening must not leak past choice specifics, and the
// `MakeR()?` shape must diagnose cleanly, not crash), and the SF-6 negative
// probe for a rejected instantiation of the widened symbolic-choice `var`
// shape (risk R-8 — diagnostic, not crash, at monomorphization).

// --- fail_symbolic_temporary_uniformity.carbon
library "[[@TEST_NAME]]";

// The §2.3 uniformity pin, side by side: an operand that is itself a
// TEMPORARY of a bare symbolic-binding type (`MakeR(R)?`) diagnoses exactly
// what a `var` of the same type diagnoses — the ordinary missing
// `Core.Destroy` for a symbolic non-choice type (a language-wide bound
// question upstream answers with interface bounds, per
// generic/fail_generic_copy.carbon's `T: Core.Destroy`). `?` gets no
// carve-out in either direction: if `VarSide` starts compiling, the §2.2
// clause is keyed too wide (R-2's falsifier); if `QuestionSide` crashes or
// compiles silently, the uniformity policy is falsified (R-3) and §2.3's
// pre-declared narrowed-gate fallback applies instead.

// Declaration-only maker (the abstract.carbon `ReturnAbstract` precedent):
// returns a value of the caller's facet binding.
fn MakeR(generic R2: Core.Try where .BreakType = i32) -> R2;

fn QuestionSide[R: Core.Try where .BreakType = i32](e: i32) -> R {
  // The operand temporary's destroy is attempted once per exclusive
  // discharge path: the break path's whole-function discharge and the
  // statement-end temporary discharge. The CARRIER temporary's destroy
  // resolves (a symbolic choice specific, §2.2); only the operand fails.
  // CHECK:STDERR: fail_symbolic_temporary_uniformity.carbon:[[@LINE+8]]:34: error: cannot access member of interface `Core.Destroy` in type `R` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   let unused c: R.ContinueType = MakeR(R)?;
  // CHECK:STDERR:                                  ^~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: fail_symbolic_temporary_uniformity.carbon:[[@LINE+4]]:34: error: cannot access member of interface `Core.Destroy` in type `R` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   let unused c: R.ContinueType = MakeR(R)?;
  // CHECK:STDERR:                                  ^~~~~~~~
  // CHECK:STDERR:
  let unused c: R.ContinueType = MakeR(R)?;
  return R.FromBreak(e);
}

fn VarSide[R: Core.Try where .BreakType = i32]() -> R {
  // The same missing destroy, one discharge path (the return): initializing
  // from the call is an in-place init, so the `var` storage is the only
  // registered cleanup (the eval/call.carbon fail_todo_dependent_call_type
  // location shape).
  // CHECK:STDERR: fail_symbolic_temporary_uniformity.carbon:[[@LINE+4]]:3: error: cannot access member of interface `Core.Destroy` in type `R` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   var unused x: R = MakeR(R);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var unused x: R = MakeR(R);
  return R.FromBreak(0);
}

// --- fail_sf6_rejected_instantiation.carbon
library "[[@TEST_NAME]]";

// The R-8 negative probe (fork/b2/plan.md §3, §5): §2.2's structural trust
// lets the widened symbolic-choice `var` shape compile GENERICALLY, so an
// SF-6-REJECTED instantiation reaches the monomorphization-time payload
// check for the first time — and must land as the clean
// `ChoicePayloadNotTrivialInSpecific` diagnostic (the S3b eval hook), not a
// CARBON_CHECK crash, an unresolved-witness eval retry loop, or a silent
// compile.

// A defined non-adapter class: never an SF-6 payload scalar.
class Fat {
  var a: i32;
  var b: i32;
}

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// Compiles generically post-B2a (the question.carbon WidenedVar shape): the
// symbolic specific's destroy answer is structural, and the payload check
// defers while any payload field is symbolic.
fn Widened(generic T: type) {
  var unused mr: MyResult(T, i32) = MyResult(T, i32).Err(0);
}

fn Trigger() {
  // CHECK:STDERR: fail_sf6_rejected_instantiation.carbon:[[@LINE+10]]:3: error: unable to monomorphize specific `Widened(Fat)` [ResolvingSpecificHere]
  // CHECK:STDERR:   Widened(Fat);
  // CHECK:STDERR:   ^~~~~~~
  // CHECK:STDERR: fail_sf6_rejected_instantiation.carbon:[[@LINE-7]]:18: note: `MyResult(T, i32)` evaluates to incomplete type `MyResult(Fat, i32)` [IncompleteTypeInMonomorphization]
  // CHECK:STDERR:   var unused mr: MyResult(T, i32) = MyResult(T, i32).Err(0);
  // CHECK:STDERR:                  ^~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_sf6_rejected_instantiation.carbon:[[@LINE-19]]:1: note: choice alternative payload type `Fat` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR: choice MyResult(T: type, E: type) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  Widened(Fat);
}
