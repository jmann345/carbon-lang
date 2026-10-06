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
// Impl bodies use the match-reconstruct style throughout (plan §2.6;
// reason re-derived 2026-08-18 per W-075's synthesized choice `Core.Copy`
// witness): `Branch` destructures `self` and rebuilds the carrier
// alternative because it returns the `ControlFlow` carrier, not `Self` —
// the historical no-`Core.Copy` bound is discharged, and the flipped
// tripwire pin is the return_choice_binding subfile below.

// --- propagate.carbon
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
  // Unreachable trailing return (reachability doesn't consult match
  // exhaustiveness — fork/b1/plan.md §2.6): a dead constructible value.
  return MyResult(i32, i32).Err(0);
}

// `?` inside both arms of an `if` expression: branched CFG at region
// depth 1 must compile (risk R-2). Each arm owns the desugar's two
// temporaries (the operand and the carrier) and destroys them at the end of
// the arm — in the continue block, before the branch to `if.expr.result` —
// because neither the other arm's blocks nor the convergence block is
// dominated by their creation (upstream's SSA verifier, PR 7771).
fn InIfExpr(n: i32, c: bool) -> MyResult(i32, i32) {
  var v: i32 = if c then Open(n)? else Open(n + 1)?;
  return MyResult(i32, i32).Ok(v);
}

// `?` in the right-hand operand of a short-circuit operator: that operand is
// evaluated only when the left-hand one doesn't decide the result, so the
// desugar's two temporaries are destroyed at the end of the `and.rhs` block,
// before the branch to `and.result` — the same rule as the `if` expression
// arms above.
fn InShortCircuit(n: i32, c: bool) -> MyResult(i32, i32) {
  var v: bool = c and Open(n)? > 0;
  return MyResult(i32, i32).Ok(if v then 1 else 0);
}
//@dump-sem-ir-end

// --- two_specifics.carbon
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

// The W-071 discharge test (fork/b2/plan.md §2.2-2.3), restored POSITIVE
// from the B1b fail_todo_generic TODO pin: `?` on a SYMBOLIC operand type is
// ungated. The symbolic `Core.ControlFlow` carrier specific's standard
// cleanup discharge resolves through `CanDestroyClass`'s choice clause
// (custom_witness.cpp) — destroyable-deferred `NonTrivial` on the strength
// of SF-6's per-specific payload guarantee, with each concrete
// monomorphization re-deriving its own witness.

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

// Maker for the scrutinee-temporary probe below; explicit `generic` params
// because `E2` is not deducible from the value arguments. Defined, not
// declaration-only: a GENERIC function must be defined to be callable
// (MissingGenericFunctionDefinition), unlike the non-generic
// declaration-only precedent.
fn MakeMR(generic T2: type, generic E2: type, x: T2) -> MyResult(T2, E2) {
  return MyResult(T2, E2).Ok(x);
}

// Payload-binding sink (the match/choice_generic_payload_pattern.carbon
// `Discard` shape): consumes a symbolic-typed payload binding by value.
fn Discard[U: type](_: U) {}

//@dump-sem-ir-begin
// The recorded W-071 discharge body: a facet-bound operand `r: R`. The
// carrier is `Core.ControlFlow(R.ContinueType, i32)` — a symbolic specific
// whose payload projections carry no `Destroy` bound.
fn PropagateOnly[R: Core.Try where .BreakType = i32](r: R) -> R {
  let unused c: R.ContinueType = r?;
  return R.FromBreak(0);
}

// The second symbolic shape: the operand is itself a symbolic CHOICE
// specific (`mr: MyResult(T, E)`), not a facet binding — both the operand's
// own future discharges and the carrier's go through the choice clause.
fn PropagateChoice[T: type, E: type](mr: MyResult(T, E), e: E)
    -> MyResult(T, E) {
  // Deliberate NEGATIVE pin (W-072 dissolution — fork/w072/plan.md §3,
  // P-4): through this NON-final impl the continue value types as the
  // unreduced projection `MyResult(T, E).(Core.Try.ContinueType)`, so it
  // is consumed through the DEDUCED sink rather than a `T`-annotated
  // binding. That refusal is upstream-DESIGNED specialization soundness
  // (docs/design/generics/details.md, "`final` impl declarations"; the
  // fail_nonfinal pin in upstream's
  // impl/lookup/specialization_with_symbolic_rewrite.carbon), not a
  // compiler gap — a non-final parameterized impl may be specialized at
  // monomorphization, so its `where` rewrites cannot be assumed. The
  // sanctioned spelling for `T`-typed threading is the ratified doc's own
  // `final impl` (docs/design/error_handling.md's `Try` sketches):
  // question_final.carbon. Reduction firing HERE would mean
  // specialization soundness is broken (plan risk R-2: halt).
  Discard(mr?);
  return MyResult(T, E).Err(e);
}

// The §2.2 widening is language-wide, pinned deliberately rather than
// incidentally: a plain `var` of a symbolic choice specific in a generic
// body compiles — its destroy is the same deferred-`NonTrivial` answer the
// `?` carrier gets.
fn WidenedVar[T: type, E: type](t: T, unused e: E) {
  var unused mr: MyResult(T, E) = MyResult(T, E).Ok(t);
}

// ...and so does a `match` scrutinee TEMPORARY of a symbolic choice
// specific (the same discharge, registered by the scrutinee
// materialization; the arm shapes are the proven
// match/choice_generic_payload_pattern.carbon symbolic destructuring).
// `MyResult(T, i32)` is also the MIXED-specific edge pinned by §2.2: one
// symbolic argument makes the whole specific's constant symbolic, so the
// clause fires and the concrete monomorphization re-derives per specific.
fn WidenedScrutinee[T: type](t: T) -> i32 {
  match (MakeMR(T, i32, t)) {
    case .Ok(v: T) => {
      Discard(v);
      return 1;
    }
    case .Err(e: i32) => { return e; }
  }
  // Unreachable trailing return (reachability doesn't consult match
  // exhaustiveness — fork/b1/plan.md §2.6).
  return -1;
}
//@dump-sem-ir-end

// --- convert.carbon
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

// --- return_choice_binding.carbon
library "[[@TEST_NAME]]";

choice MyResult(T: type, E: type) {
  Ok(v: T),
  Err(e: E)
}

// The §2.6 tripwire, FIRED as designed (W-075, fork/w075/plan.md P-2): this
// subfile lived in fail_question.carbon pinning that returning a
// choice-typed BINDING value-copies the choice and choices had no
// `Core.Copy`. With the W-075 synthesized choice copy witness the
// pass-through shape compiles, and §2.6 is re-derived: the match-reconstruct
// `Branch` bodies STAY — against the `ControlFlow` carrier a `return self;`
// body is a type mismatch regardless of copyability — but the copy bound
// they also relied on is discharged (docs/design/error_handling.md carries
// the dated amendment; rewriting the prelude `Try` sketches is not W75a
// scope).
//@dump-sem-ir-begin
fn Passthrough(r: MyResult(i32, i32)) -> MyResult(i32, i32) {
  return r;
}
//@dump-sem-ir-end
