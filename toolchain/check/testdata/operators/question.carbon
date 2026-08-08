// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/question.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/question.carbon

// Postfix `?` over user-defined generic choices (fork/b1/plan.md §3 B1b):
// the `Core.Try` desugar — Branch call, `Core.ControlFlow` discriminant
// dispatch, break-path `FromBreak` + early return, continue-path value.
// Impl bodies use the match-reconstruct style throughout (plan §2.6):
// choices have no `Core.Copy`, so `Branch` destructures `self` and rebuilds
// the carrier alternative in return position instead of returning a
// choice-typed binding.

// --- propagate.carbon
library "[[@TEST_NAME]]";

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
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

fn Open(n: i32) -> MyResult(i32, i32) {
  if (n > 0) { return MyResult(i32, i32).Ok(n); }
  return MyResult(i32, i32).Err(n);
}

fn Callee(a: i32, b: i32) -> i32 { return a + b; }

//@dump-sem-ir-begin
// `?` in a `var` initializer: the region-position policy's over-fire
// falsifier (fork/b1/plan.md §2.4) — initializers run at region depth 1
// and must compile.
fn Basic(n: i32) -> MyResult(i32, i32) {
  var f: i32 = Open(n)?;
  return MyResult(i32, i32).Ok(f + 1);
}

// `?` in statement position: the continue value is discarded.
fn Statement(n: i32) -> MyResult(i32, i32) {
  Open(n)?;
  return MyResult(i32, i32).Ok(n);
}

// A `?` chain in one statement: the inner `?` is mid-expression — an
// argument of the pending outer call — when its break path returns
// (plan §2.8, risk R-2).
fn Chain(n: i32) -> MyResult(i32, i32) {
  var t: i32 = Open(Open(n)?)?;
  return MyResult(i32, i32).Ok(t);
}

// `?` in argument position of an ordinary call (risk R-2's
// partially-built-expression falsifier).
fn Argument(n: i32) -> MyResult(i32, i32) {
  var v: i32 = Callee(n, Open(n)?);
  return MyResult(i32, i32).Ok(v);
}

// `?` inside a `match` arm body: `GetCurrentFunctionForReturn` is
// scope-stack-based, so `?` targets the enclosing FUNCTION (D4), and the
// break path's discharge is the return's whole-function discharge, not the
// arm's (risk R-2).
fn InArm(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  match (r) {
    case .Ok(v: i32) => {
      var w: i32 = Open(v)?;
      return MyResult(i32, i32).Ok(w);
    }
    case .Err(e: i32) => { return MyResult(i32, i32).Err(e); }
  }
}

// `?` inside both arms of an `if` expression: branched CFG at region
// depth 1 must compile (risk R-2).
fn InIfExpr(n: i32, c: bool) -> MyResult(i32, i32) {
  var v: i32 = if c then Open(n)? else Open(n + 1)?;
  return MyResult(i32, i32).Ok(v);
}
//@dump-sem-ir-end

// --- two_specifics.carbon
library "[[@TEST_NAME]]";

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
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

//@dump-sem-ir-begin
// Two specifics in one function (risk R-3's falsifier): the two Branch
// calls must resolve to DISTINCT `Core.ControlFlow` specifics —
// `ControlFlow(i32, i32)` and `ControlFlow(i64, i32)` — with the correct
// payload types; a shared or stale specific is the falsification.
fn Both(a: MyResult(i32, i32), b: MyResult(i64, i32)) -> MyResult(i64, i32) {
  var x: i32 = a?;
  var y: i64 = b?;
  return MyResult(i64, i32).Ok(y + (x as i64));
}
//@dump-sem-ir-end

// --- repeat.carbon
library "[[@TEST_NAME]]";

// `x??`: repetition — the first `?`'s continue value itself implements
// `Core.Try`. Class-based impls (adapters over i32) keep the carrier
// payloads SF-6-scalar.
class Inner {
  adapt i32;
}

class Outer {
  adapt i32;
}

// Adapters do not inherit `Core.Copy` from their adapted type
// (class/adapter/adapt_copy.carbon), and `FromBreak`/`Twice` below return
// adapter VALUES into the return slot — a `Core.Copy` use.
impl Inner as Core.Copy {
  fn Op(self) -> Self = "primitive_copy";
}

impl Outer as Core.Copy {
  fn Op(self) -> Self = "primitive_copy";
}

impl Inner as Core.Try where .ContinueType = i32 and .BreakType = i32 {
  fn Branch(self) -> Core.ControlFlow(i32, i32) {
    if ((self as i32) < 0) {
      return Core.ControlFlow(i32, i32).Break(self as i32);
    }
    return Core.ControlFlow(i32, i32).Continue(self as i32);
  }
  fn FromBreak(b: i32) -> Self { return b as Inner; }
}

impl Outer as Core.Try where .ContinueType = Inner and .BreakType = i32 {
  fn Branch(self) -> Core.ControlFlow(Inner, i32) {
    if ((self as i32) < 0) {
      return Core.ControlFlow(Inner, i32).Break(self as i32);
    }
    return Core.ControlFlow(Inner, i32).Continue((self as i32) as Inner);
  }
  fn FromBreak(b: i32) -> Self { return b as Outer; }
}

//@dump-sem-ir-begin
fn Twice(x: Outer) -> Outer {
  var v: i32 = x??;
  return v as Outer;
}
//@dump-sem-ir-end

// --- generic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// `?` inside a generic function body: the operand and the return type are
// the SYMBOLIC facet binding `R`, so the Branch witness comes from the
// facet bound, the carrier is a symbolic `ControlFlow` specific, and the
// extracted payloads have symbolic types (plan §3's R-8-style scope-in).
fn PropagateOnly[R: Core.Try where .BreakType = i32](r: R) -> R {
  let unused c: R.ContinueType = r?;
  return R.FromBreak(0);
}
//@dump-sem-ir-end

// --- convert.carbon
library "[[@TEST_NAME]]";

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
  }
  fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
}

// D3/F-006c: the break payload's conversion to the RETURN type's break type
// is the ordinary `ImplicitAs` argument conversion in the `FromBreak` call —
// no `?`-specific conversion machinery exists. `ErrA` and `ErrB` are
// adapters over `i32` (SF-6-admissible payloads) with a user `ImplicitAs`.
class ErrA {
  adapt i32;
}

class ErrB {
  adapt i32;
}

// `Convert` returns an `ErrB` VALUE into its return slot, which is a
// `Core.Copy` use; adapters do not inherit `Copy` from the adapted type.
impl ErrB as Core.Copy {
  fn Op(self) -> Self = "primitive_copy";
}

impl ErrA as Core.ImplicitAs(ErrB) {
  fn Convert(self) -> ErrB { return (self as i32) as ErrB; }
}

fn Inner(n: i32) -> MyResult(i32, ErrA) {
  if (n > 0) { return MyResult(i32, ErrA).Ok(n); }
  return MyResult(i32, ErrA).Err(n as ErrA);
}

//@dump-sem-ir-begin
fn Outer(n: i32) -> MyResult(i32, ErrB) {
  var v: i32 = Inner(n)?;
  return MyResult(i32, ErrB).Ok(v);
}
//@dump-sem-ir-end
