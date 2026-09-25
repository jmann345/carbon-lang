// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/fail_question.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/fail_question.carbon

// Postfix `?` rejections that need a user `Core.Try` impl in scope
// (fork/b1/plan.md §3 B1b): the operand rejection, the three
// captured-region positions (the §2.4 region-position policy, risk R-2's
// falsifiers), and the D3 no-conversion pin. The §2.6 no-choice-copy pin
// that lived here FIRED as designed (W-075 synthesized the choice
// `Core.Copy` witness) and moved to question.carbon's
// return_choice_binding.carbon as a positive pin. The pre-flight shapes
// that need no impl are in fail_question_preflight.carbon.

// --- fail_operand_not_try.carbon
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
    // under `final` it does — question_final.carbon), so use the helper.
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

fn Operand(x: i32) -> MyResult(i32, i32) {
  x?;
  return MyResult(i32, i32).Ok(x);
}

// Type-position `?` at region depth 1: the operand is the TYPE `i32`, so
// this is the ordinary missing-impl rejection (`type` does not implement
// `Core.Try`) — fork/b1/plan.md §2.3, approval-gate item 7. Annotation
// positions are captured regions and take the region-policy rejection
// instead (fail_pattern_positions.carbon).
fn TypePosition() -> MyResult(i32, i32) {
  i32?;
  return MyResult(i32, i32).Ok(0);
}

// --- fail_pattern_positions.carbon
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
    // under `final` it does — question_final.carbon), so use the helper.
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

fn H(n: i32) -> MyResult(i32, i32) { return MyResult(i32, i32).Ok(n); }

// The three captured-region positions (fork/b1/plan.md §2.4's
// region-position policy): the operand H(...) and the enclosing return
// type both implement `Core.Try`, so each rejection below is provably the
// region policy, not a missing impl. A verifier crash, an orphaned
// return-terminated block, or a silent compile here falsifies the
// region-depth detection (risk R-2).
fn Guard(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  match (r) {
    case .Ok(v: i32) if (H(v)? > 0) => { return MyResult(i32, i32).Ok(v); }
    case .Ok(w: i32) => { return MyResult(i32, i32).Ok(w); }
    case .Err(e: i32) => { return MyResult(i32, i32).Err(e); }
  }
  // Unreachable trailing return (reachability doesn't consult match
  // exhaustiveness — fork/b1/plan.md §2.6): a dead constructible value.
  return MyResult(i32, i32).Err(0);
}

fn Annotation(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  var y: r? = 0;
  return MyResult(i32, i32).Ok(y);
}

// Migrated from the B1a gate pin (fail_todo_question.carbon's type
// position): a type annotation is a captured region, so `var p: i32?`
// takes the region-policy rejection — recorded as superseding §2.3's
// missing-impl expectation for annotation positions (see the plan's dated
// divergence clause). The depth-1 type-position shape keeps the
// missing-impl rejection (fail_operand_not_try.carbon).
fn TypeAnnotation() -> MyResult(i32, i32) {
  var p: i32? = 0;
  return MyResult(i32, i32).Ok(p);
}

// The `case` expression-pattern shape aborts checking at RF-4's
// non-constant-case TODO (after the region-policy rejection), so it is the
// subfile's LAST function: everything after a `context.TODO` abort would go
// unchecked, as the first regen proved when this function preceded the
// annotation shapes and silently un-pinned them.
fn ExprPattern(n: i32) -> MyResult(i32, i32) {
  match (n) {
    case H(0)? => { return MyResult(i32, i32).Ok(n); }
    default => { return MyResult(i32, i32).Err(n); }
  }
}

// --- fail_no_conversion.carbon
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
    // under `final` it does — question_final.carbon), so use the helper.
    return Diverge(Core.ControlFlow(T, E));
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// The D3 negative: with no user `ImplicitAs` from the operand's break
// type to the return type's break type, the `FromBreak` argument
// conversion — the ordinary call machinery — is what fails; no
// `?`-specific conversion path exists (fork/b1/plan.md §2.4 step 5).
class ErrA {
  adapt i32;
}

class ErrC {
  adapt i32;
}

fn Inner(n: i32) -> MyResult(i32, ErrA) {
  return MyResult(i32, ErrA).Err(n as ErrA);
}

fn Outer(n: i32) -> MyResult(i32, ErrC) {
  var v: i32 = Inner(n)?;
  return MyResult(i32, ErrC).Ok(v);
}
