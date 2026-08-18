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

// CHECK:STDOUT: --- propagate.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %MyResult.type: type = generic_class_type @MyResult [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %MyResult.generic: %MyResult.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.type.fd7: type = fn_type @MyResult.Ok, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.460: %MyResult.Ok.type.fd7 = struct_value () [symbolic]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %MyResult.Err.type.110: type = fn_type @MyResult.Err, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.Err.899: %MyResult.Err.type.110 = struct_value () [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %MyResult.21e: type = class_type @MyResult, @MyResult(%i32, %i32) [concrete]
// CHECK:STDOUT:   %.4de: Core.Form = init_form %MyResult.21e [concrete]
// CHECK:STDOUT:   %pattern_type.90f: type = pattern_type %MyResult.21e [concrete]
// CHECK:STDOUT:   %return.param_patt.8cb: %pattern_type.90f = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.6c9: %pattern_type.90f = return_slot_pattern %return.param_patt.8cb, %MyResult.21e [concrete]
// CHECK:STDOUT:   %Open.type: type = fn_type @Open [concrete]
// CHECK:STDOUT:   %Open: %Open.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.bf4: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a, .Err@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.f26: type = struct_type {.discriminant: %u1, .payload: %.bf4} [concrete]
// CHECK:STDOUT:   %MyResult.Ok.type.94a: type = fn_type @MyResult.Ok, @MyResult(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.de7: %MyResult.Ok.type.94a = struct_value () [concrete]
// CHECK:STDOUT:   %MyResult.Err.type.6f5: type = fn_type @MyResult.Err, @MyResult(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.Err.8b7: %MyResult.Err.type.6f5 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %MyResult.Ok.de7, @MyResult.Ok(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.Err.specific_fn.24b: <specific function> = specific_function %MyResult.Err.8b7, @MyResult.Err(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Callee.type: type = fn_type @Callee [concrete]
// CHECK:STDOUT:   %Callee: %Callee.type = struct_value () [concrete]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.1: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.1: %Int.as.AddWith.impl.Op.type.1eac76.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.2: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.2: %Int.as.AddWith.impl.Op.type.1eac76.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %Basic.type: type = fn_type @Basic [concrete]
// CHECK:STDOUT:   %Basic: %Basic.type = struct_value () [concrete]
// CHECK:STDOUT:   %f.patt: %pattern_type.6b6 = ref_binding_pattern f [concrete]
// CHECK:STDOUT:   %f.var_patt: %pattern_type.6b6 = var_pattern %f.patt [concrete]
// CHECK:STDOUT:   %Try.impl_witness.cda: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type.dbd: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.b50: %MyResult.as.Try.impl.Branch.type.dbd = struct_value () [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type.b1c: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.c92: %MyResult.as.Try.impl.FromBreak.type.b1c = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.172: %Try.type = facet_value %MyResult.21e, (%Try.impl_witness.cda) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.d04: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.172) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.4e8: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.172) [concrete]
// CHECK:STDOUT:   %.5f8: type = fn_type_with_self_type %Try.WithSelf.Branch.type.d04, %Try.facet.172 [concrete]
// CHECK:STDOUT:   %ControlFlow.32a: type = class_type @ControlFlow, @ControlFlow(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch.b50, @MyResult.as.Try.impl.Branch(%i32, %i32) [concrete]
// CHECK:STDOUT:   %.b63: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.88b: type = struct_type {.discriminant: %u1, .payload: %.b63} [concrete]
// CHECK:STDOUT:   %.046: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.4e8, %Try.facet.172 [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak.c92, @MyResult.as.Try.impl.FromBreak(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc45_23.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc45_23.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.11: type = fn_type @Destroy.Op.loc45_22.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.11: %Destroy.Op.type.1d8f74.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.aa4: <witness> = impl_witness imports.%AddWith.impl_witness_table.b21, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.1: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.2: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.2: %Int.as.AddWith.impl.Op.type.bddb3c.2 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.3de: %AddWith.type.832 = facet_value %i32, (%AddWith.impl_witness.aa4) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.b60: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(Core.IntLiteral, %AddWith.facet.3de) [concrete]
// CHECK:STDOUT:   %.fbe: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.b60, %AddWith.facet.3de [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.1: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.2, @Int.as.AddWith.impl.Op.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.2: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.1, @Int.as.AddWith.impl.Op.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Statement.type: type = fn_type @Statement [concrete]
// CHECK:STDOUT:   %Statement: %Statement.type = struct_value () [concrete]
// CHECK:STDOUT:   %Chain.type: type = fn_type @Chain [concrete]
// CHECK:STDOUT:   %Chain: %Chain.type = struct_value () [concrete]
// CHECK:STDOUT:   %t.patt: %pattern_type.6b6 = ref_binding_pattern t [concrete]
// CHECK:STDOUT:   %t.var_patt: %pattern_type.6b6 = var_pattern %t.patt [concrete]
// CHECK:STDOUT:   %Argument.type: type = fn_type @Argument [concrete]
// CHECK:STDOUT:   %Argument: %Argument.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt.113: %pattern_type.6b6 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt.113 [concrete]
// CHECK:STDOUT:   %r.param_patt: %pattern_type.90f = value_param_pattern [concrete]
// CHECK:STDOUT:   %r.patt: %pattern_type.90f = at_binding_pattern r, %r.param_patt [concrete]
// CHECK:STDOUT:   %InArm.type: type = fn_type @InArm [concrete]
// CHECK:STDOUT:   %InArm: %InArm.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt.424: %pattern_type.6b6 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %.13b: %pattern_type.e71 = tuple_pattern (%v.patt.424) [concrete]
// CHECK:STDOUT:   %w.patt: %pattern_type.6b6 = ref_binding_pattern w [concrete]
// CHECK:STDOUT:   %w.var_patt: %pattern_type.6b6 = var_pattern %w.patt [concrete]
// CHECK:STDOUT:   %e.patt.2e6: %pattern_type.6b6 = value_binding_pattern e [concrete]
// CHECK:STDOUT:   %.37b: %pattern_type.e71 = tuple_pattern (%e.patt.2e6) [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.831 = at_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %InIfExpr.type: type = fn_type @InIfExpr [concrete]
// CHECK:STDOUT:   %InIfExpr: %InIfExpr.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3a: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.b21 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.8a3a), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %MyResult.Ok.decl: @MyResult.%MyResult.Ok.type (%MyResult.Ok.type.fd7) = fn_decl @MyResult.Ok [symbolic = @MyResult.%MyResult.Ok (constants.%MyResult.Ok.460)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.Err.decl: @MyResult.%MyResult.Err.type (%MyResult.Err.type.110) = fn_decl @MyResult.Err [symbolic = @MyResult.%MyResult.Err (constants.%MyResult.Err.899)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Basic.decl: %Basic.type = fn_decl @Basic [concrete = constants.%Basic] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc44 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc44: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc44_30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc44_35: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc44: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc44_38.3: Core.Form = init_form %MyResult.loc44 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc44_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Statement.decl: %Statement.type = fn_decl @Statement [concrete = constants.%Statement] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc50 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc50: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc50_34: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc50_39: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc50: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc50_42.3: Core.Form = init_form %MyResult.loc50 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc50_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Chain.decl: %Chain.type = fn_decl @Chain [concrete = constants.%Chain] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc58 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc58: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc58_30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc58_35: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc58: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc58_38.4: Core.Form = init_form %MyResult.loc58 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc58_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Argument.decl: %Argument.type = fn_decl @Argument [concrete = constants.%Argument] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc65 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc65: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc65_33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc65_38: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc65: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc65_41.3: Core.Form = init_form %MyResult.loc65 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc65_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %InArm.decl: %InArm.type = fn_decl @InArm [concrete = constants.%InArm] {
// CHECK:STDOUT:     %r.param_patt: %pattern_type.90f = value_param_pattern [concrete = constants.%r.param_patt]
// CHECK:STDOUT:     %r.patt: %pattern_type.90f = at_binding_pattern r, %r.param_patt [concrete = constants.%r.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc74_53 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc74_36: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc74_45: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc74_50: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc74_53: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc74_53.5: Core.Form = init_form %MyResult.loc74_53 [concrete = constants.%.4de]
// CHECK:STDOUT:     %r.param: %MyResult.21e = value_param call_param0
// CHECK:STDOUT:     %.loc74_30: type = splice_block %MyResult.loc74_30 [concrete = constants.%MyResult.21e] {
// CHECK:STDOUT:       %MyResult.ref.loc74_13: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %i32.loc74_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc74_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %MyResult.loc74_30: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %r: %MyResult.21e = wrapper_binding r, %r.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %InIfExpr.decl: %InIfExpr.type = fn_decl @InIfExpr [concrete = constants.%InIfExpr] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %c.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.831 = at_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc89 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc89: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc89_42: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc89_47: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc89: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc89_50.4: Core.Form = init_form %MyResult.loc89 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc89_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %c.param: bool = value_param call_param1
// CHECK:STDOUT:     %.loc89_24: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %c: bool = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param2
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Basic(%n.param: %i32) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %f.var: ref %i32 = var_storage %f.var_patt
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc45_22.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call: init %MyResult.21e to %.loc45_22.1 = call %Open.ref(%n.ref)
// CHECK:STDOUT:   %.loc45_22.2: ref %MyResult.21e = temporary %.loc45_22.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.5f8 = impl_witness_access constants.%Try.impl_witness.cda, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc45_23.1: <bound method> = bound_method %.loc45_22.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc45_23.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc45_23.2: <bound method> = bound_method %.loc45_22.2, %specific_fn.loc45_23.1
// CHECK:STDOUT:   %.loc45_23.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc45_22.3: %MyResult.21e = acquire_value %.loc45_22.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc45_23.1 = call %bound_method.loc45_23.2(%.loc45_22.3)
// CHECK:STDOUT:   %.loc45_23.2: ref %ControlFlow.32a = temporary %.loc45_23.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc45: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc45_23.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc45_23.3: <bound method> = bound_method %int_1.loc45, %impl.elem0.loc45_23.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc45_23.2: <specific function> = specific_function %impl.elem0.loc45_23.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc45_23.4: <bound method> = bound_method %int_1.loc45, %specific_fn.loc45_23.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc45: init %u1 = call %bound_method.loc45_23.4(%int_1.loc45) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc45_23.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc45 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc45_23.4: %u1 = converted %int_1.loc45, %.loc45_23.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc45_23.5: ref %u1 = class_element_access %.loc45_23.2, element0
// CHECK:STDOUT:   %impl.elem0.loc45_23.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc45_23.5: <bound method> = bound_method %.loc45_23.4, %impl.elem0.loc45_23.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc45_23.3: <specific function> = specific_function %impl.elem0.loc45_23.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc45_23.6: <bound method> = bound_method %.loc45_23.4, %specific_fn.loc45_23.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc45_23.6: %u1 = acquire_value %.loc45_23.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc45_23.6(%.loc45_23.4, %.loc45_23.6)
// CHECK:STDOUT:   %.loc45_23.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc45_23.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc45_23.7
// CHECK:STDOUT:   if %.loc45_23.8 br !.loc45_23.1 else br !.loc45_23.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc45_23.1:
// CHECK:STDOUT:   %.loc45_23.9: ref %.b63 = class_element_access %.loc45_23.2, element1
// CHECK:STDOUT:   %.loc45_23.10: ref %tuple.type.a8a = class_element_access %.loc45_23.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc45_23.1: ref %i32 = tuple_access %.loc45_23.10, element0
// CHECK:STDOUT:   %.loc45_23.11: %i32 = acquire_value %tuple.elem0.loc45_23.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.cda) [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %.loc45_23.12: %Try.type = converted constants.%MyResult.21e, %Try.facet [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %impl.elem3: %.046 = impl_witness_access constants.%Try.impl_witness.cda, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc45_23.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc44_38.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.21e to %.loc44_38.1 = call %specific_fn.loc45_23.4(%.loc45_23.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_23.1: <bound method> = bound_method %.loc45_23.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc45_23.1: init %empty_tuple.type = call %Destroy.Op.bound.loc45_23.1(%.loc45_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_22.1: <bound method> = bound_method %.loc45_22.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc45_22.1: init %empty_tuple.type = call %Destroy.Op.bound.loc45_22.1(%.loc45_22.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_3.1: <bound method> = bound_method %f.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc45_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc45_3.1(%f.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc45_23.2:
// CHECK:STDOUT:   %.loc45_23.13: ref %.b63 = class_element_access %.loc45_23.2, element1
// CHECK:STDOUT:   %.loc45_23.14: ref %tuple.type.a8a = class_element_access %.loc45_23.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc45_23.2: ref %i32 = tuple_access %.loc45_23.14, element0
// CHECK:STDOUT:   %.loc45_23.15: %i32 = acquire_value %tuple.elem0.loc45_23.2
// CHECK:STDOUT:   %impl.elem0.loc45_23.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc45_23.7: <bound method> = bound_method %.loc45_23.15, %impl.elem0.loc45_23.3
// CHECK:STDOUT:   %specific_fn.loc45_23.5: <specific function> = specific_function %impl.elem0.loc45_23.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc45_23.8: <bound method> = bound_method %.loc45_23.15, %specific_fn.loc45_23.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc45_23.8(%.loc45_23.15)
// CHECK:STDOUT:   assign %f.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc45: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %f: ref %i32 = wrapper_binding f, %f.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %f.patt: %pattern_type.6b6 = ref_binding_pattern f [concrete = constants.%f.patt]
// CHECK:STDOUT:     %f.var_patt: %pattern_type.6b6 = var_pattern %f.patt [concrete = constants.%f.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc46: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc46_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc46_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc46: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc46_28: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc46_28 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %f.ref: ref %i32 = name_ref f, %f
// CHECK:STDOUT:   %int_1.loc46: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:   %bound_method.loc46_34.1: <bound method> = bound_method %f.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc46_34: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:   %bound_method.loc46_34.2: <bound method> = bound_method %f.ref, %specific_fn.loc46_34
// CHECK:STDOUT:   %.loc46_32: %i32 = acquire_value %f.ref
// CHECK:STDOUT:   %.loc46_34.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc46_34.1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %.loc46_32, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:   %bound_method.loc46_34.3: <bound method> = bound_method %.loc46_32, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc46: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc46_36.1: <bound method> = bound_method %int_1.loc46, %impl.elem0.loc46 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc46_36: <specific function> = specific_function %impl.elem0.loc46, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc46_36.2: <bound method> = bound_method %int_1.loc46, %specific_fn.loc46_36 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc46: init %i32 = call %bound_method.loc46_36.2(%int_1.loc46) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc46_36.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc46 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc46_36.2: %i32 = converted %int_1.loc46, %.loc46_36.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc46_34.3(%.loc46_32, %.loc46_36.2)
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc44_38.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc46_34.2: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc46_34.3: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc46_34.2
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc44_38.2 = call %MyResult.Ok.specific_fn(%.loc46_34.3)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_23.2: <bound method> = bound_method %.loc45_23.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc45_23.2: init %empty_tuple.type = call %Destroy.Op.bound.loc45_23.2(%.loc45_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_22.2: <bound method> = bound_method %.loc45_22.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc45_22.2: init %empty_tuple.type = call %Destroy.Op.bound.loc45_22.2(%.loc45_22.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_3.2: <bound method> = bound_method %f.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc45_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc45_3.2(%f.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_23.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_23.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_23.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_23.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_23.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_23.6(%self.param: ref %.b63) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_23.7(%self.param: ref %struct_type.discriminant.payload.88b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_23.8(%self.param: ref %ControlFlow.32a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_22.1(%self.param: ref %.bf4) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_22.2(%self.param: ref %struct_type.discriminant.payload.f26) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc45_22.3(%self.param: ref %MyResult.21e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Statement(%n.param: %i32) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc51: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc51_9.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call: init %MyResult.21e to %.loc51_9.1 = call %Open.ref(%n.ref.loc51)
// CHECK:STDOUT:   %.loc51_9.2: ref %MyResult.21e = temporary %.loc51_9.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.5f8 = impl_witness_access constants.%Try.impl_witness.cda, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc51_10.1: <bound method> = bound_method %.loc51_9.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc51_10.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc51_10.2: <bound method> = bound_method %.loc51_9.2, %specific_fn.loc51_10.1
// CHECK:STDOUT:   %.loc51_10.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc51_9.3: %MyResult.21e = acquire_value %.loc51_9.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc51_10.1 = call %bound_method.loc51_10.2(%.loc51_9.3)
// CHECK:STDOUT:   %.loc51_10.2: ref %ControlFlow.32a = temporary %.loc51_10.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc51_10.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc51_10.3: <bound method> = bound_method %int_1, %impl.elem0.loc51_10.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc51_10.2: <specific function> = specific_function %impl.elem0.loc51_10.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc51_10.4: <bound method> = bound_method %int_1, %specific_fn.loc51_10.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc51_10.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc51_10.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc51_10.4: %u1 = converted %int_1, %.loc51_10.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc51_10.5: ref %u1 = class_element_access %.loc51_10.2, element0
// CHECK:STDOUT:   %impl.elem0.loc51_10.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc51_10.5: <bound method> = bound_method %.loc51_10.4, %impl.elem0.loc51_10.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc51_10.3: <specific function> = specific_function %impl.elem0.loc51_10.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc51_10.6: <bound method> = bound_method %.loc51_10.4, %specific_fn.loc51_10.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc51_10.6: %u1 = acquire_value %.loc51_10.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc51_10.6(%.loc51_10.4, %.loc51_10.6)
// CHECK:STDOUT:   %.loc51_10.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc51_10.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc51_10.7
// CHECK:STDOUT:   if %.loc51_10.8 br !.loc51_10.1 else br !.loc51_10.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc51_10.1:
// CHECK:STDOUT:   %.loc51_10.9: ref %.b63 = class_element_access %.loc51_10.2, element1
// CHECK:STDOUT:   %.loc51_10.10: ref %tuple.type.a8a = class_element_access %.loc51_10.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc51_10.1: ref %i32 = tuple_access %.loc51_10.10, element0
// CHECK:STDOUT:   %.loc51_10.11: %i32 = acquire_value %tuple.elem0.loc51_10.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.cda) [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %.loc51_10.12: %Try.type = converted constants.%MyResult.21e, %Try.facet [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %impl.elem3: %.046 = impl_witness_access constants.%Try.impl_witness.cda, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc51_10.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc50_42.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.21e to %.loc50_42.1 = call %specific_fn.loc51_10.4(%.loc51_10.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc51_10.1: <bound method> = bound_method %.loc51_10.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc51_10.1: init %empty_tuple.type = call %Destroy.Op.bound.loc51_10.1(%.loc51_10.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc51_9.1: <bound method> = bound_method %.loc51_9.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc51_9.1: init %empty_tuple.type = call %Destroy.Op.bound.loc51_9.1(%.loc51_9.2)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc51_10.2:
// CHECK:STDOUT:   %.loc51_10.13: ref %.b63 = class_element_access %.loc51_10.2, element1
// CHECK:STDOUT:   %.loc51_10.14: ref %tuple.type.a8a = class_element_access %.loc51_10.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc51_10.2: ref %i32 = tuple_access %.loc51_10.14, element0
// CHECK:STDOUT:   %.loc51_10.15: %i32 = acquire_value %tuple.elem0.loc51_10.2
// CHECK:STDOUT:   %Destroy.Op.bound.loc51_10.2: <bound method> = bound_method %.loc51_10.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc51_10.2: init %empty_tuple.type = call %Destroy.Op.bound.loc51_10.2(%.loc51_10.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc51_9.2: <bound method> = bound_method %.loc51_9.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc51_9.2: init %empty_tuple.type = call %Destroy.Op.bound.loc51_9.2(%.loc51_9.2)
// CHECK:STDOUT:   %MyResult.ref.loc52: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc52_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc52_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc52: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc52: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc52 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %n.ref.loc52: %i32 = name_ref n, %n
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc50_42.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc50_42.2 = call %MyResult.Ok.specific_fn(%n.ref.loc52)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Chain(%n.param: %i32) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.var: ref %i32 = var_storage %t.var_patt
// CHECK:STDOUT:   %Open.ref.loc59_16: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %Open.ref.loc59_21: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc59_27.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call.loc59_27: init %MyResult.21e to %.loc59_27.1 = call %Open.ref.loc59_21(%n.ref)
// CHECK:STDOUT:   %.loc59_27.2: ref %MyResult.21e = temporary %.loc59_27.1, %Open.call.loc59_27
// CHECK:STDOUT:   %impl.elem2.loc59_28: %.5f8 = impl_witness_access constants.%Try.impl_witness.cda, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc59_28.1: <bound method> = bound_method %.loc59_27.2, %impl.elem2.loc59_28
// CHECK:STDOUT:   %specific_fn.loc59_28.1: <specific function> = specific_function %impl.elem2.loc59_28, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc59_28.2: <bound method> = bound_method %.loc59_27.2, %specific_fn.loc59_28.1
// CHECK:STDOUT:   %.loc59_28.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc59_27.3: %MyResult.21e = acquire_value %.loc59_27.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc59_28: init %ControlFlow.32a to %.loc59_28.1 = call %bound_method.loc59_28.2(%.loc59_27.3)
// CHECK:STDOUT:   %.loc59_28.2: ref %ControlFlow.32a = temporary %.loc59_28.1, %MyResult.as.Try.impl.Branch.call.loc59_28
// CHECK:STDOUT:   %int_1.loc59_28: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc59_28.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc59_28.3: <bound method> = bound_method %int_1.loc59_28, %impl.elem0.loc59_28.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc59_28.2: <specific function> = specific_function %impl.elem0.loc59_28.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc59_28.4: <bound method> = bound_method %int_1.loc59_28, %specific_fn.loc59_28.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc59_28: init %u1 = call %bound_method.loc59_28.4(%int_1.loc59_28) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc59_28.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc59_28 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc59_28.4: %u1 = converted %int_1.loc59_28, %.loc59_28.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc59_28.5: ref %u1 = class_element_access %.loc59_28.2, element0
// CHECK:STDOUT:   %impl.elem0.loc59_28.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc59_28.5: <bound method> = bound_method %.loc59_28.4, %impl.elem0.loc59_28.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc59_28.3: <specific function> = specific_function %impl.elem0.loc59_28.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc59_28.6: <bound method> = bound_method %.loc59_28.4, %specific_fn.loc59_28.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc59_28.6: %u1 = acquire_value %.loc59_28.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc59_28: init bool = call %bound_method.loc59_28.6(%.loc59_28.4, %.loc59_28.6)
// CHECK:STDOUT:   %.loc59_28.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc59_28
// CHECK:STDOUT:   %.loc59_28.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc59_28, %.loc59_28.7
// CHECK:STDOUT:   if %.loc59_28.8 br !.loc59_28.1 else br !.loc59_28.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc59_28.1:
// CHECK:STDOUT:   %.loc59_28.9: ref %.b63 = class_element_access %.loc59_28.2, element1
// CHECK:STDOUT:   %.loc59_28.10: ref %tuple.type.a8a = class_element_access %.loc59_28.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc59_28.1: ref %i32 = tuple_access %.loc59_28.10, element0
// CHECK:STDOUT:   %.loc59_28.11: %i32 = acquire_value %tuple.elem0.loc59_28.1
// CHECK:STDOUT:   %Try.facet.loc59_28: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.cda) [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %.loc59_28.12: %Try.type = converted constants.%MyResult.21e, %Try.facet.loc59_28 [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %impl.elem3.loc59_28: %.046 = impl_witness_access constants.%Try.impl_witness.cda, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc59_28.4: <specific function> = specific_function %impl.elem3.loc59_28, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc58_38.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc59_28: init %MyResult.21e to %.loc58_38.1 = call %specific_fn.loc59_28.4(%.loc59_28.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_28.1: <bound method> = bound_method %.loc59_28.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc59_28.1: init %empty_tuple.type = call %Destroy.Op.bound.loc59_28.1(%.loc59_28.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_27.1: <bound method> = bound_method %.loc59_27.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc59_27.1: init %empty_tuple.type = call %Destroy.Op.bound.loc59_27.1(%.loc59_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_3.1: <bound method> = bound_method %t.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc59_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc59_3.1(%t.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc59_28 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc59_28.2:
// CHECK:STDOUT:   %.loc59_28.13: ref %.b63 = class_element_access %.loc59_28.2, element1
// CHECK:STDOUT:   %.loc59_28.14: ref %tuple.type.a8a = class_element_access %.loc59_28.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc59_28.2: ref %i32 = tuple_access %.loc59_28.14, element0
// CHECK:STDOUT:   %.loc59_28.15: %i32 = acquire_value %tuple.elem0.loc59_28.2
// CHECK:STDOUT:   %.loc59_29.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call.loc59_29: init %MyResult.21e to %.loc59_29.1 = call %Open.ref.loc59_16(%.loc59_28.15)
// CHECK:STDOUT:   %.loc59_29.2: ref %MyResult.21e = temporary %.loc59_29.1, %Open.call.loc59_29
// CHECK:STDOUT:   %impl.elem2.loc59_30: %.5f8 = impl_witness_access constants.%Try.impl_witness.cda, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc59_30.1: <bound method> = bound_method %.loc59_29.2, %impl.elem2.loc59_30
// CHECK:STDOUT:   %specific_fn.loc59_30.1: <specific function> = specific_function %impl.elem2.loc59_30, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc59_30.2: <bound method> = bound_method %.loc59_29.2, %specific_fn.loc59_30.1
// CHECK:STDOUT:   %.loc59_30.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc59_29.3: %MyResult.21e = acquire_value %.loc59_29.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc59_30: init %ControlFlow.32a to %.loc59_30.1 = call %bound_method.loc59_30.2(%.loc59_29.3)
// CHECK:STDOUT:   %.loc59_30.2: ref %ControlFlow.32a = temporary %.loc59_30.1, %MyResult.as.Try.impl.Branch.call.loc59_30
// CHECK:STDOUT:   %int_1.loc59_30: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc59_30.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc59_30.3: <bound method> = bound_method %int_1.loc59_30, %impl.elem0.loc59_30.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc59_30.2: <specific function> = specific_function %impl.elem0.loc59_30.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc59_30.4: <bound method> = bound_method %int_1.loc59_30, %specific_fn.loc59_30.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc59_30: init %u1 = call %bound_method.loc59_30.4(%int_1.loc59_30) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc59_30.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc59_30 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc59_30.4: %u1 = converted %int_1.loc59_30, %.loc59_30.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc59_30.5: ref %u1 = class_element_access %.loc59_30.2, element0
// CHECK:STDOUT:   %impl.elem0.loc59_30.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc59_30.5: <bound method> = bound_method %.loc59_30.4, %impl.elem0.loc59_30.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc59_30.3: <specific function> = specific_function %impl.elem0.loc59_30.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc59_30.6: <bound method> = bound_method %.loc59_30.4, %specific_fn.loc59_30.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc59_30.6: %u1 = acquire_value %.loc59_30.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc59_30: init bool = call %bound_method.loc59_30.6(%.loc59_30.4, %.loc59_30.6)
// CHECK:STDOUT:   %.loc59_30.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc59_30
// CHECK:STDOUT:   %.loc59_30.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc59_30, %.loc59_30.7
// CHECK:STDOUT:   if %.loc59_30.8 br !.loc59_30.1 else br !.loc59_30.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc59_30.1:
// CHECK:STDOUT:   %.loc59_30.9: ref %.b63 = class_element_access %.loc59_30.2, element1
// CHECK:STDOUT:   %.loc59_30.10: ref %tuple.type.a8a = class_element_access %.loc59_30.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc59_30.1: ref %i32 = tuple_access %.loc59_30.10, element0
// CHECK:STDOUT:   %.loc59_30.11: %i32 = acquire_value %tuple.elem0.loc59_30.1
// CHECK:STDOUT:   %Try.facet.loc59_30: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.cda) [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %.loc59_30.12: %Try.type = converted constants.%MyResult.21e, %Try.facet.loc59_30 [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %impl.elem3.loc59_30: %.046 = impl_witness_access constants.%Try.impl_witness.cda, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc59_30.4: <specific function> = specific_function %impl.elem3.loc59_30, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc58_38.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc59_30: init %MyResult.21e to %.loc58_38.2 = call %specific_fn.loc59_30.4(%.loc59_30.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_30.1: <bound method> = bound_method %.loc59_30.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc59_30.1: init %empty_tuple.type = call %Destroy.Op.bound.loc59_30.1(%.loc59_30.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_29.1: <bound method> = bound_method %.loc59_29.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc59_29.1: init %empty_tuple.type = call %Destroy.Op.bound.loc59_29.1(%.loc59_29.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_28.2: <bound method> = bound_method %.loc59_28.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc59_28.2: init %empty_tuple.type = call %Destroy.Op.bound.loc59_28.2(%.loc59_28.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_27.2: <bound method> = bound_method %.loc59_27.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc59_27.2: init %empty_tuple.type = call %Destroy.Op.bound.loc59_27.2(%.loc59_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_3.2: <bound method> = bound_method %t.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc59_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc59_3.2(%t.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc59_30 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc59_30.2:
// CHECK:STDOUT:   %.loc59_30.13: ref %.b63 = class_element_access %.loc59_30.2, element1
// CHECK:STDOUT:   %.loc59_30.14: ref %tuple.type.a8a = class_element_access %.loc59_30.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc59_30.2: ref %i32 = tuple_access %.loc59_30.14, element0
// CHECK:STDOUT:   %.loc59_30.15: %i32 = acquire_value %tuple.elem0.loc59_30.2
// CHECK:STDOUT:   %impl.elem0.loc59_30.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc59_30.7: <bound method> = bound_method %.loc59_30.15, %impl.elem0.loc59_30.3
// CHECK:STDOUT:   %specific_fn.loc59_30.5: <specific function> = specific_function %impl.elem0.loc59_30.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc59_30.8: <bound method> = bound_method %.loc59_30.15, %specific_fn.loc59_30.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc59_30.8(%.loc59_30.15)
// CHECK:STDOUT:   assign %t.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc59: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %t: ref %i32 = wrapper_binding t, %t.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %t.patt: %pattern_type.6b6 = ref_binding_pattern t [concrete = constants.%t.patt]
// CHECK:STDOUT:     %t.var_patt: %pattern_type.6b6 = var_pattern %t.patt [concrete = constants.%t.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc60: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc60_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc60_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc60: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc60_28: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc60_28 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %t.ref: ref %i32 = name_ref t, %t
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc58_38.3: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc60_32: %i32 = acquire_value %t.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc58_38.3 = call %MyResult.Ok.specific_fn(%.loc60_32)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_30.2: <bound method> = bound_method %.loc59_30.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc59_30.2: init %empty_tuple.type = call %Destroy.Op.bound.loc59_30.2(%.loc59_30.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_29.2: <bound method> = bound_method %.loc59_29.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc59_29.2: init %empty_tuple.type = call %Destroy.Op.bound.loc59_29.2(%.loc59_29.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_28.3: <bound method> = bound_method %.loc59_28.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc59_28.3: init %empty_tuple.type = call %Destroy.Op.bound.loc59_28.3(%.loc59_28.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_27.3: <bound method> = bound_method %.loc59_27.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc59_27.3: init %empty_tuple.type = call %Destroy.Op.bound.loc59_27.3(%.loc59_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc59_3.3: <bound method> = bound_method %t.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc59_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc59_3.3(%t.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Argument(%n.param: %i32) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %i32 = var_storage %v.var_patt
// CHECK:STDOUT:   %Callee.ref: %Callee.type = name_ref Callee, file.%Callee.decl [concrete = constants.%Callee]
// CHECK:STDOUT:   %n.ref.loc66_23: %i32 = name_ref n, %n
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc66_31: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc66_32.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call: init %MyResult.21e to %.loc66_32.1 = call %Open.ref(%n.ref.loc66_31)
// CHECK:STDOUT:   %.loc66_32.2: ref %MyResult.21e = temporary %.loc66_32.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.5f8 = impl_witness_access constants.%Try.impl_witness.cda, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc66_33.1: <bound method> = bound_method %.loc66_32.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc66_33.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc66_33.2: <bound method> = bound_method %.loc66_32.2, %specific_fn.loc66_33.1
// CHECK:STDOUT:   %.loc66_33.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc66_32.3: %MyResult.21e = acquire_value %.loc66_32.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc66_33.1 = call %bound_method.loc66_33.2(%.loc66_32.3)
// CHECK:STDOUT:   %.loc66_33.2: ref %ControlFlow.32a = temporary %.loc66_33.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc66_33.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc66_33.3: <bound method> = bound_method %int_1, %impl.elem0.loc66_33.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc66_33.2: <specific function> = specific_function %impl.elem0.loc66_33.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc66_33.4: <bound method> = bound_method %int_1, %specific_fn.loc66_33.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc66_33.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc66_33.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc66_33.4: %u1 = converted %int_1, %.loc66_33.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc66_33.5: ref %u1 = class_element_access %.loc66_33.2, element0
// CHECK:STDOUT:   %impl.elem0.loc66_33.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc66_33.5: <bound method> = bound_method %.loc66_33.4, %impl.elem0.loc66_33.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc66_33.3: <specific function> = specific_function %impl.elem0.loc66_33.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc66_33.6: <bound method> = bound_method %.loc66_33.4, %specific_fn.loc66_33.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc66_33.6: %u1 = acquire_value %.loc66_33.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc66_33.6(%.loc66_33.4, %.loc66_33.6)
// CHECK:STDOUT:   %.loc66_33.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc66_33.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc66_33.7
// CHECK:STDOUT:   if %.loc66_33.8 br !.loc66_33.1 else br !.loc66_33.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc66_33.1:
// CHECK:STDOUT:   %.loc66_33.9: ref %.b63 = class_element_access %.loc66_33.2, element1
// CHECK:STDOUT:   %.loc66_33.10: ref %tuple.type.a8a = class_element_access %.loc66_33.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc66_33.1: ref %i32 = tuple_access %.loc66_33.10, element0
// CHECK:STDOUT:   %.loc66_33.11: %i32 = acquire_value %tuple.elem0.loc66_33.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.cda) [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %.loc66_33.12: %Try.type = converted constants.%MyResult.21e, %Try.facet [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %impl.elem3: %.046 = impl_witness_access constants.%Try.impl_witness.cda, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc66_33.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc65_41.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.21e to %.loc65_41.1 = call %specific_fn.loc66_33.4(%.loc66_33.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc66_33.1: <bound method> = bound_method %.loc66_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc66_33.1: init %empty_tuple.type = call %Destroy.Op.bound.loc66_33.1(%.loc66_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc66_32.1: <bound method> = bound_method %.loc66_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc66_32.1: init %empty_tuple.type = call %Destroy.Op.bound.loc66_32.1(%.loc66_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc66_3.1: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc66_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc66_3.1(%v.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc66_33.2:
// CHECK:STDOUT:   %.loc66_33.13: ref %.b63 = class_element_access %.loc66_33.2, element1
// CHECK:STDOUT:   %.loc66_33.14: ref %tuple.type.a8a = class_element_access %.loc66_33.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc66_33.2: ref %i32 = tuple_access %.loc66_33.14, element0
// CHECK:STDOUT:   %.loc66_33.15: %i32 = acquire_value %tuple.elem0.loc66_33.2
// CHECK:STDOUT:   %Callee.call: init %i32 = call %Callee.ref(%n.ref.loc66_23, %.loc66_33.15)
// CHECK:STDOUT:   assign %v.var, %Callee.call
// CHECK:STDOUT:   %i32.loc66: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt.113]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc67: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc67_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc67_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc67: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc67_28: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc67_28 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %v.ref: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc65_41.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc67_32: %i32 = acquire_value %v.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc65_41.2 = call %MyResult.Ok.specific_fn(%.loc67_32)
// CHECK:STDOUT:   %Destroy.Op.bound.loc66_33.2: <bound method> = bound_method %.loc66_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc66_33.2: init %empty_tuple.type = call %Destroy.Op.bound.loc66_33.2(%.loc66_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc66_32.2: <bound method> = bound_method %.loc66_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc66_32.2: init %empty_tuple.type = call %Destroy.Op.bound.loc66_32.2(%.loc66_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc66_3.2: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc66_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc66_3.2(%v.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @InArm(%r.param: %MyResult.21e) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %r.ref: %MyResult.21e = name_ref r, %r
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt.424]
// CHECK:STDOUT:     %.loc76_15: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc76: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc76_22.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc76_22.1: <bound method> = bound_method %int_0.loc76, %impl.elem0.loc76_22.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc76_22.1: <specific function> = specific_function %impl.elem0.loc76_22.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc76_22.2: <bound method> = bound_method %int_0.loc76, %specific_fn.loc76_22.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc76: init %u1 = call %bound_method.loc76_22.2(%int_0.loc76) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc76_22.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc76 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc76_22.2: %u1 = converted %int_0.loc76, %.loc76_22.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc76_22.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc76_22.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc76_22.3: <bound method> = bound_method %.loc76_22.2, %impl.elem0.loc76_22.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc76_22.2: <specific function> = specific_function %impl.elem0.loc76_22.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc76_22.4: <bound method> = bound_method %.loc76_22.2, %specific_fn.loc76_22.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc76_22.4: %u1 = acquire_value %.loc76_22.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc76: init bool = call %bound_method.loc76_22.4(%.loc76_22.2, %.loc76_22.4)
// CHECK:STDOUT:   %.loc76_22.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc76
// CHECK:STDOUT:   %.loc76_22.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc76, %.loc76_22.5
// CHECK:STDOUT:   if %.loc76_22.6 br !match.case.then.loc76 else br !match.case.else.loc76
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc76:
// CHECK:STDOUT:   %.loc76_22.7: ref %.bf4 = class_element_access %r.ref, element1
// CHECK:STDOUT:   %.loc76_22.8: ref %tuple.type.a8a = class_element_access %.loc76_22.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc76: ref %i32 = tuple_access %.loc76_22.8, element0
// CHECK:STDOUT:   %.loc76_22.9: %i32 = acquire_value %tuple.elem0.loc76
// CHECK:STDOUT:   %i32.loc76: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc76_22.9
// CHECK:STDOUT:   %w.var: ref %i32 = var_storage %w.var_patt
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %v.ref: %i32 = name_ref v, %v
// CHECK:STDOUT:   %.loc77_26.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call: init %MyResult.21e to %.loc77_26.1 = call %Open.ref(%v.ref)
// CHECK:STDOUT:   %.loc77_26.2: ref %MyResult.21e = temporary %.loc77_26.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.5f8 = impl_witness_access constants.%Try.impl_witness.cda, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc77_27.1: <bound method> = bound_method %.loc77_26.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc77_27.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc77_27.2: <bound method> = bound_method %.loc77_26.2, %specific_fn.loc77_27.1
// CHECK:STDOUT:   %.loc77_27.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc77_26.3: %MyResult.21e = acquire_value %.loc77_26.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc77_27.1 = call %bound_method.loc77_27.2(%.loc77_26.3)
// CHECK:STDOUT:   %.loc77_27.2: ref %ControlFlow.32a = temporary %.loc77_27.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc77: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc77_27.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc77_27.3: <bound method> = bound_method %int_1.loc77, %impl.elem0.loc77_27.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc77_27.2: <specific function> = specific_function %impl.elem0.loc77_27.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc77_27.4: <bound method> = bound_method %int_1.loc77, %specific_fn.loc77_27.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc77: init %u1 = call %bound_method.loc77_27.4(%int_1.loc77) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc77_27.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc77 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc77_27.4: %u1 = converted %int_1.loc77, %.loc77_27.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc77_27.5: ref %u1 = class_element_access %.loc77_27.2, element0
// CHECK:STDOUT:   %impl.elem0.loc77_27.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc77_27.5: <bound method> = bound_method %.loc77_27.4, %impl.elem0.loc77_27.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc77_27.3: <specific function> = specific_function %impl.elem0.loc77_27.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc77_27.6: <bound method> = bound_method %.loc77_27.4, %specific_fn.loc77_27.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc77_27.6: %u1 = acquire_value %.loc77_27.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc77: init bool = call %bound_method.loc77_27.6(%.loc77_27.4, %.loc77_27.6)
// CHECK:STDOUT:   %.loc77_27.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc77
// CHECK:STDOUT:   %.loc77_27.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc77, %.loc77_27.7
// CHECK:STDOUT:   if %.loc77_27.8 br !.loc77_27.1 else br !.loc77_27.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc77_27.1:
// CHECK:STDOUT:   %.loc77_27.9: ref %.b63 = class_element_access %.loc77_27.2, element1
// CHECK:STDOUT:   %.loc77_27.10: ref %tuple.type.a8a = class_element_access %.loc77_27.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc77_27.1: ref %i32 = tuple_access %.loc77_27.10, element0
// CHECK:STDOUT:   %.loc77_27.11: %i32 = acquire_value %tuple.elem0.loc77_27.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.cda) [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %.loc77_27.12: %Try.type = converted constants.%MyResult.21e, %Try.facet [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %impl.elem3: %.046 = impl_witness_access constants.%Try.impl_witness.cda, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc77_27.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc74_53.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.21e to %.loc74_53.1 = call %specific_fn.loc77_27.4(%.loc77_27.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc77_27.1: <bound method> = bound_method %.loc77_27.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc77_27.1: init %empty_tuple.type = call %Destroy.Op.bound.loc77_27.1(%.loc77_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc77_26.1: <bound method> = bound_method %.loc77_26.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc77_26.1: init %empty_tuple.type = call %Destroy.Op.bound.loc77_26.1(%.loc77_26.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc77_7.1: <bound method> = bound_method %w.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc77_7.1: init %empty_tuple.type = call %Destroy.Op.bound.loc77_7.1(%w.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc77_27.2:
// CHECK:STDOUT:   %.loc77_27.13: ref %.b63 = class_element_access %.loc77_27.2, element1
// CHECK:STDOUT:   %.loc77_27.14: ref %tuple.type.a8a = class_element_access %.loc77_27.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc77_27.2: ref %i32 = tuple_access %.loc77_27.14, element0
// CHECK:STDOUT:   %.loc77_27.15: %i32 = acquire_value %tuple.elem0.loc77_27.2
// CHECK:STDOUT:   %impl.elem0.loc77_27.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc77_27.7: <bound method> = bound_method %.loc77_27.15, %impl.elem0.loc77_27.3
// CHECK:STDOUT:   %specific_fn.loc77_27.5: <specific function> = specific_function %impl.elem0.loc77_27.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc77_27.8: <bound method> = bound_method %.loc77_27.15, %specific_fn.loc77_27.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc77_27.8(%.loc77_27.15)
// CHECK:STDOUT:   assign %w.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc77: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %w: ref %i32 = wrapper_binding w, %w.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %w.patt: %pattern_type.6b6 = ref_binding_pattern w [concrete = constants.%w.patt]
// CHECK:STDOUT:     %w.var_patt: %pattern_type.6b6 = var_pattern %w.patt [concrete = constants.%w.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc78: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc78_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc78_28: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc78: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc78_32: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc78_32 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %w.ref: ref %i32 = name_ref w, %w
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc74_53.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc78_36: %i32 = acquire_value %w.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc74_53.2 = call %MyResult.Ok.specific_fn(%.loc78_36)
// CHECK:STDOUT:   %Destroy.Op.bound.loc77_27.2: <bound method> = bound_method %.loc77_27.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc77_27.2: init %empty_tuple.type = call %Destroy.Op.bound.loc77_27.2(%.loc77_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc77_26.2: <bound method> = bound_method %.loc77_26.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc77_26.2: init %empty_tuple.type = call %Destroy.Op.bound.loc77_26.2(%.loc77_26.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc77_7.2: <bound method> = bound_method %w.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc77_7.2: init %empty_tuple.type = call %Destroy.Op.bound.loc77_7.2(%w.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc76:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %e.patt: %pattern_type.6b6 = value_binding_pattern e [concrete = constants.%e.patt.2e6]
// CHECK:STDOUT:     %.loc80_16: %pattern_type.e71 = tuple_pattern (%e.patt) [concrete = constants.%.37b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc80: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc80_23.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc80_23.1: <bound method> = bound_method %int_1.loc80, %impl.elem0.loc80_23.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc80_23.1: <specific function> = specific_function %impl.elem0.loc80_23.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc80_23.2: <bound method> = bound_method %int_1.loc80, %specific_fn.loc80_23.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc80: init %u1 = call %bound_method.loc80_23.2(%int_1.loc80) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc80_23.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc80 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc80_23.2: %u1 = converted %int_1.loc80, %.loc80_23.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc80_23.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc80_23.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc80_23.3: <bound method> = bound_method %.loc80_23.2, %impl.elem0.loc80_23.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc80_23.2: <specific function> = specific_function %impl.elem0.loc80_23.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc80_23.4: <bound method> = bound_method %.loc80_23.2, %specific_fn.loc80_23.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc80_23.4: %u1 = acquire_value %.loc80_23.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc80: init bool = call %bound_method.loc80_23.4(%.loc80_23.2, %.loc80_23.4)
// CHECK:STDOUT:   %.loc80_23.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc80
// CHECK:STDOUT:   %.loc80_23.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc80, %.loc80_23.5
// CHECK:STDOUT:   if %.loc80_23.6 br !match.case.then.loc80 else br !match.case.else.loc80
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc80:
// CHECK:STDOUT:   %.loc80_23.7: ref %.bf4 = class_element_access %r.ref, element1
// CHECK:STDOUT:   %.loc80_23.8: ref %tuple.type.a8a = class_element_access %.loc80_23.7, element1
// CHECK:STDOUT:   %tuple.elem0.loc80: ref %i32 = tuple_access %.loc80_23.8, element0
// CHECK:STDOUT:   %.loc80_23.9: %i32 = acquire_value %tuple.elem0.loc80
// CHECK:STDOUT:   %i32.loc80_18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %e: %i32 = wrapper_binding e, %.loc80_23.9
// CHECK:STDOUT:   %MyResult.ref.loc80: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc80_44: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc80_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc80: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc80_53: %MyResult.Err.type.6f5 = specific_constant generated.%MyResult.Err.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Err.8b7]
// CHECK:STDOUT:   %Err.ref.loc80: %MyResult.Err.type.6f5 = name_ref Err, %.loc80_53 [concrete = constants.%MyResult.Err.8b7]
// CHECK:STDOUT:   %e.ref: %i32 = name_ref e, %e
// CHECK:STDOUT:   %MyResult.Err.specific_fn.loc80: <specific function> = specific_function %Err.ref.loc80, @MyResult.Err(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Err.specific_fn.24b]
// CHECK:STDOUT:   %.loc74_53.3: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.Err.call.loc80: init %MyResult.21e to %.loc74_53.3 = call %MyResult.Err.specific_fn.loc80(%e.ref)
// CHECK:STDOUT:   return %MyResult.Err.call.loc80 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc80:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %MyResult.ref.loc84: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc84_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc84_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc84: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc84_28: %MyResult.Err.type.6f5 = specific_constant generated.%MyResult.Err.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Err.8b7]
// CHECK:STDOUT:   %Err.ref.loc84: %MyResult.Err.type.6f5 = name_ref Err, %.loc84_28 [concrete = constants.%MyResult.Err.8b7]
// CHECK:STDOUT:   %int_0.loc84: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %MyResult.Err.specific_fn.loc84: <specific function> = specific_function %Err.ref.loc84, @MyResult.Err(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Err.specific_fn.24b]
// CHECK:STDOUT:   %.loc74_53.4: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %impl.elem0.loc84: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc84_33.1: <bound method> = bound_method %int_0.loc84, %impl.elem0.loc84 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc84: <specific function> = specific_function %impl.elem0.loc84, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc84_33.2: <bound method> = bound_method %int_0.loc84, %specific_fn.loc84 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc84: init %i32 = call %bound_method.loc84_33.2(%int_0.loc84) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc84_33.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc84 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc84_33.2: %i32 = converted %int_0.loc84, %.loc84_33.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %MyResult.Err.call.loc84: init %MyResult.21e to %.loc74_53.4 = call %MyResult.Err.specific_fn.loc84(%.loc84_33.2)
// CHECK:STDOUT:   return %MyResult.Err.call.loc84 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @InIfExpr(%n.param: %i32, %c.param: bool) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %i32 = var_storage %v.var_patt
// CHECK:STDOUT:   %c.ref: bool = name_ref c, %c
// CHECK:STDOUT:   if %c.ref br !if.expr.then else br !if.expr.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.expr.then:
// CHECK:STDOUT:   %Open.ref.loc90_26: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc90_31: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc90_32.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call.loc90_32: init %MyResult.21e to %.loc90_32.1 = call %Open.ref.loc90_26(%n.ref.loc90_31)
// CHECK:STDOUT:   %.loc90_32.2: ref %MyResult.21e = temporary %.loc90_32.1, %Open.call.loc90_32
// CHECK:STDOUT:   %impl.elem2.loc90_33: %.5f8 = impl_witness_access constants.%Try.impl_witness.cda, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc90_33.1: <bound method> = bound_method %.loc90_32.2, %impl.elem2.loc90_33
// CHECK:STDOUT:   %specific_fn.loc90_33.1: <specific function> = specific_function %impl.elem2.loc90_33, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc90_33.2: <bound method> = bound_method %.loc90_32.2, %specific_fn.loc90_33.1
// CHECK:STDOUT:   %.loc90_33.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc90_32.3: %MyResult.21e = acquire_value %.loc90_32.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc90_33: init %ControlFlow.32a to %.loc90_33.1 = call %bound_method.loc90_33.2(%.loc90_32.3)
// CHECK:STDOUT:   %.loc90_33.2: ref %ControlFlow.32a = temporary %.loc90_33.1, %MyResult.as.Try.impl.Branch.call.loc90_33
// CHECK:STDOUT:   %int_1.loc90_33: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc90_33.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc90_33.3: <bound method> = bound_method %int_1.loc90_33, %impl.elem0.loc90_33.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc90_33.2: <specific function> = specific_function %impl.elem0.loc90_33.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc90_33.4: <bound method> = bound_method %int_1.loc90_33, %specific_fn.loc90_33.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc90_33: init %u1 = call %bound_method.loc90_33.4(%int_1.loc90_33) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc90_33.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc90_33 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc90_33.4: %u1 = converted %int_1.loc90_33, %.loc90_33.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc90_33.5: ref %u1 = class_element_access %.loc90_33.2, element0
// CHECK:STDOUT:   %impl.elem0.loc90_33.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc90_33.5: <bound method> = bound_method %.loc90_33.4, %impl.elem0.loc90_33.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc90_33.3: <specific function> = specific_function %impl.elem0.loc90_33.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc90_33.6: <bound method> = bound_method %.loc90_33.4, %specific_fn.loc90_33.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc90_33.6: %u1 = acquire_value %.loc90_33.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc90_33: init bool = call %bound_method.loc90_33.6(%.loc90_33.4, %.loc90_33.6)
// CHECK:STDOUT:   %.loc90_33.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc90_33
// CHECK:STDOUT:   %.loc90_33.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc90_33, %.loc90_33.7
// CHECK:STDOUT:   if %.loc90_33.8 br !.loc90_33.1 else br !.loc90_33.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc90_33.1:
// CHECK:STDOUT:   %.loc90_33.9: ref %.b63 = class_element_access %.loc90_33.2, element1
// CHECK:STDOUT:   %.loc90_33.10: ref %tuple.type.a8a = class_element_access %.loc90_33.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc90_33.1: ref %i32 = tuple_access %.loc90_33.10, element0
// CHECK:STDOUT:   %.loc90_33.11: %i32 = acquire_value %tuple.elem0.loc90_33.1
// CHECK:STDOUT:   %Try.facet.loc90_33: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.cda) [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %.loc90_33.12: %Try.type = converted constants.%MyResult.21e, %Try.facet.loc90_33 [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %impl.elem3.loc90_33: %.046 = impl_witness_access constants.%Try.impl_witness.cda, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc90_33.4: <specific function> = specific_function %impl.elem3.loc90_33, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc89_50.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc90_33: init %MyResult.21e to %.loc89_50.1 = call %specific_fn.loc90_33.4(%.loc90_33.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_33.1: <bound method> = bound_method %.loc90_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc90_33.1: init %empty_tuple.type = call %Destroy.Op.bound.loc90_33.1(%.loc90_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_32.1: <bound method> = bound_method %.loc90_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc90_32.1: init %empty_tuple.type = call %Destroy.Op.bound.loc90_32.1(%.loc90_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_3.1: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc90_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc90_3.1(%v.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc90_33 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc90_33.2:
// CHECK:STDOUT:   %.loc90_33.13: ref %.b63 = class_element_access %.loc90_33.2, element1
// CHECK:STDOUT:   %.loc90_33.14: ref %tuple.type.a8a = class_element_access %.loc90_33.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc90_33.2: ref %i32 = tuple_access %.loc90_33.14, element0
// CHECK:STDOUT:   %.loc90_33.15: %i32 = acquire_value %tuple.elem0.loc90_33.2
// CHECK:STDOUT:   br !if.expr.result(%.loc90_33.15)
// CHECK:STDOUT:
// CHECK:STDOUT: !if.expr.else:
// CHECK:STDOUT:   %Open.ref.loc90_40: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc90_45: %i32 = name_ref n, %n
// CHECK:STDOUT:   %int_1.loc90_49: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:   %bound_method.loc90_47.1: <bound method> = bound_method %n.ref.loc90_45, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc90_47: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:   %bound_method.loc90_47.2: <bound method> = bound_method %n.ref.loc90_45, %specific_fn.loc90_47
// CHECK:STDOUT:   %.loc90_47.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc90_47.1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %n.ref.loc90_45, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:   %bound_method.loc90_47.3: <bound method> = bound_method %n.ref.loc90_45, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc90_49: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc90_49.1: <bound method> = bound_method %int_1.loc90_49, %impl.elem0.loc90_49 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc90_49: <specific function> = specific_function %impl.elem0.loc90_49, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc90_49.2: <bound method> = bound_method %int_1.loc90_49, %specific_fn.loc90_49 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc90_49: init %i32 = call %bound_method.loc90_49.2(%int_1.loc90_49) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc90_49.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc90_49 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc90_49.2: %i32 = converted %int_1.loc90_49, %.loc90_49.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc90_47.3(%n.ref.loc90_45, %.loc90_49.2)
// CHECK:STDOUT:   %.loc90_50.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %.loc90_47.2: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc90_47.3: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc90_47.2
// CHECK:STDOUT:   %Open.call.loc90_50: init %MyResult.21e to %.loc90_50.1 = call %Open.ref.loc90_40(%.loc90_47.3)
// CHECK:STDOUT:   %.loc90_50.2: ref %MyResult.21e = temporary %.loc90_50.1, %Open.call.loc90_50
// CHECK:STDOUT:   %impl.elem2.loc90_51: %.5f8 = impl_witness_access constants.%Try.impl_witness.cda, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc90_51.1: <bound method> = bound_method %.loc90_50.2, %impl.elem2.loc90_51
// CHECK:STDOUT:   %specific_fn.loc90_51.1: <specific function> = specific_function %impl.elem2.loc90_51, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc90_51.2: <bound method> = bound_method %.loc90_50.2, %specific_fn.loc90_51.1
// CHECK:STDOUT:   %.loc90_51.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc90_50.3: %MyResult.21e = acquire_value %.loc90_50.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc90_51: init %ControlFlow.32a to %.loc90_51.1 = call %bound_method.loc90_51.2(%.loc90_50.3)
// CHECK:STDOUT:   %.loc90_51.2: ref %ControlFlow.32a = temporary %.loc90_51.1, %MyResult.as.Try.impl.Branch.call.loc90_51
// CHECK:STDOUT:   %int_1.loc90_51: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc90_51.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc90_51.3: <bound method> = bound_method %int_1.loc90_51, %impl.elem0.loc90_51.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc90_51.2: <specific function> = specific_function %impl.elem0.loc90_51.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc90_51.4: <bound method> = bound_method %int_1.loc90_51, %specific_fn.loc90_51.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc90_51: init %u1 = call %bound_method.loc90_51.4(%int_1.loc90_51) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc90_51.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc90_51 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc90_51.4: %u1 = converted %int_1.loc90_51, %.loc90_51.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc90_51.5: ref %u1 = class_element_access %.loc90_51.2, element0
// CHECK:STDOUT:   %impl.elem0.loc90_51.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc90_51.5: <bound method> = bound_method %.loc90_51.4, %impl.elem0.loc90_51.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc90_51.3: <specific function> = specific_function %impl.elem0.loc90_51.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc90_51.6: <bound method> = bound_method %.loc90_51.4, %specific_fn.loc90_51.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc90_51.6: %u1 = acquire_value %.loc90_51.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc90_51: init bool = call %bound_method.loc90_51.6(%.loc90_51.4, %.loc90_51.6)
// CHECK:STDOUT:   %.loc90_51.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc90_51
// CHECK:STDOUT:   %.loc90_51.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc90_51, %.loc90_51.7
// CHECK:STDOUT:   if %.loc90_51.8 br !.loc90_51.1 else br !.loc90_51.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc90_51.1:
// CHECK:STDOUT:   %.loc90_51.9: ref %.b63 = class_element_access %.loc90_51.2, element1
// CHECK:STDOUT:   %.loc90_51.10: ref %tuple.type.a8a = class_element_access %.loc90_51.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc90_51.1: ref %i32 = tuple_access %.loc90_51.10, element0
// CHECK:STDOUT:   %.loc90_51.11: %i32 = acquire_value %tuple.elem0.loc90_51.1
// CHECK:STDOUT:   %Try.facet.loc90_51: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.cda) [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %.loc90_51.12: %Try.type = converted constants.%MyResult.21e, %Try.facet.loc90_51 [concrete = constants.%Try.facet.172]
// CHECK:STDOUT:   %impl.elem3.loc90_51: %.046 = impl_witness_access constants.%Try.impl_witness.cda, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc90_51.4: <specific function> = specific_function %impl.elem3.loc90_51, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc89_50.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc90_51: init %MyResult.21e to %.loc89_50.2 = call %specific_fn.loc90_51.4(%.loc90_51.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_51.1: <bound method> = bound_method %.loc90_51.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc90_51.1: init %empty_tuple.type = call %Destroy.Op.bound.loc90_51.1(%.loc90_51.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_50.1: <bound method> = bound_method %.loc90_50.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc90_50.1: init %empty_tuple.type = call %Destroy.Op.bound.loc90_50.1(%.loc90_50.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_33.2: <bound method> = bound_method %.loc90_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc90_33.2: init %empty_tuple.type = call %Destroy.Op.bound.loc90_33.2(%.loc90_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_32.2: <bound method> = bound_method %.loc90_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc90_32.2: init %empty_tuple.type = call %Destroy.Op.bound.loc90_32.2(%.loc90_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_3.2: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc90_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc90_3.2(%v.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc90_51 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc90_51.2:
// CHECK:STDOUT:   %.loc90_51.13: ref %.b63 = class_element_access %.loc90_51.2, element1
// CHECK:STDOUT:   %.loc90_51.14: ref %tuple.type.a8a = class_element_access %.loc90_51.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc90_51.2: ref %i32 = tuple_access %.loc90_51.14, element0
// CHECK:STDOUT:   %.loc90_51.15: %i32 = acquire_value %tuple.elem0.loc90_51.2
// CHECK:STDOUT:   br !if.expr.result(%.loc90_51.15)
// CHECK:STDOUT:
// CHECK:STDOUT: !if.expr.result:
// CHECK:STDOUT:   %.loc90_16: %i32 = block_arg !if.expr.result
// CHECK:STDOUT:   %impl.elem0.loc90_16: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc90_16.1: <bound method> = bound_method %.loc90_16, %impl.elem0.loc90_16
// CHECK:STDOUT:   %specific_fn.loc90_16: <specific function> = specific_function %impl.elem0.loc90_16, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc90_16.2: <bound method> = bound_method %.loc90_16, %specific_fn.loc90_16
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc90_16.2(%.loc90_16)
// CHECK:STDOUT:   assign %v.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc90: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt.113]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc91: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc91_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc91_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc91: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc91_28: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc91_28 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %v.ref: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc89_50.3: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc91_32: %i32 = acquire_value %v.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc89_50.3 = call %MyResult.Ok.specific_fn(%.loc91_32)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_51.2: <bound method> = bound_method %.loc90_51.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc90_51.2: init %empty_tuple.type = call %Destroy.Op.bound.loc90_51.2(%.loc90_51.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_50.2: <bound method> = bound_method %.loc90_50.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc90_50.2: init %empty_tuple.type = call %Destroy.Op.bound.loc90_50.2(%.loc90_50.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_33.3: <bound method> = bound_method %.loc90_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc90_33.3: init %empty_tuple.type = call %Destroy.Op.bound.loc90_33.3(%.loc90_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_32.3: <bound method> = bound_method %.loc90_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc90_32.3: init %empty_tuple.type = call %Destroy.Op.bound.loc90_32.3(%.loc90_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc90_3.3: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc90_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc90_3.3(%v.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- two_specifics.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %MyResult.type: type = generic_class_type @MyResult [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %MyResult.generic: %MyResult.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.type.fd7: type = fn_type @MyResult.Ok, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.460: %MyResult.Ok.type.fd7 = struct_value () [symbolic]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %From.fe9: Core.IntLiteral = symbolic_binding From, 0 [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %MyResult.21e: type = class_type @MyResult, @MyResult(%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.90f: type = pattern_type %MyResult.21e [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.90f = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.90f = at_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %MyResult.964: type = class_type @MyResult, @MyResult(%i64, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.99b: type = pattern_type %MyResult.964 [concrete]
// CHECK:STDOUT:   %b.param_patt.341: %pattern_type.99b = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt.402: %pattern_type.99b = at_binding_pattern b, %b.param_patt.341 [concrete]
// CHECK:STDOUT:   %.b38bf: Core.Form = init_form %MyResult.964 [concrete]
// CHECK:STDOUT:   %return.param_patt.411: %pattern_type.99b = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.1d9: %pattern_type.99b = return_slot_pattern %return.param_patt.411, %MyResult.964 [concrete]
// CHECK:STDOUT:   %Both.type: type = fn_type @Both [concrete]
// CHECK:STDOUT:   %Both: %Both.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %tuple.type.f67: type = tuple_type (%i64) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.type.547: type = fn_type @MyResult.Ok, @MyResult(%i64, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.f46: %MyResult.Ok.type.547 = struct_value () [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = ref_binding_pattern x [concrete]
// CHECK:STDOUT:   %x.var_patt: %pattern_type.6b6 = var_pattern %x.patt [concrete]
// CHECK:STDOUT:   %Try.impl_witness.8e7: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i64, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type.e04: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%i64, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.871: %MyResult.as.Try.impl.Branch.type.e04 = struct_value () [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type.5c3: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%i64, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.ae9: %MyResult.as.Try.impl.FromBreak.type.5c3 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.impl_witness.cda: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type.dbd: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.b50: %MyResult.as.Try.impl.Branch.type.dbd = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.172: %Try.type = facet_value %MyResult.21e, (%Try.impl_witness.cda) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.d04: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.172) [concrete]
// CHECK:STDOUT:   %.5f8: type = fn_type_with_self_type %Try.WithSelf.Branch.type.d04, %Try.facet.172 [concrete]
// CHECK:STDOUT:   %ControlFlow.32a: type = class_type @ControlFlow, @ControlFlow(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn.1fe: <specific function> = specific_function %MyResult.as.Try.impl.Branch.b50, @MyResult.as.Try.impl.Branch(%i32, %i32) [concrete]
// CHECK:STDOUT:   %.b63: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.88b: type = struct_type {.discriminant: %u1, .payload: %.b63} [concrete]
// CHECK:STDOUT:   %Try.facet.93f: %Try.type = facet_value %MyResult.964, (%Try.impl_witness.8e7) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.0dc: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.93f) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.13d: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.93f) [concrete]
// CHECK:STDOUT:   %.79f: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.13d, %Try.facet.93f [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak.ae9, @MyResult.as.Try.impl.FromBreak(%i64, %i32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc39_17.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc39_17.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.287: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %y.patt: %pattern_type.f57 = ref_binding_pattern y [concrete]
// CHECK:STDOUT:   %y.var_patt: %pattern_type.f57 = var_pattern %y.patt [concrete]
// CHECK:STDOUT:   %.ea8: type = fn_type_with_self_type %Try.WithSelf.Branch.type.0dc, %Try.facet.93f [concrete]
// CHECK:STDOUT:   %ControlFlow.3df: type = class_type @ControlFlow, @ControlFlow(%i64, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn.019: <specific function> = specific_function %MyResult.as.Try.impl.Branch.871, @MyResult.as.Try.impl.Branch(%i64, %i32) [concrete]
// CHECK:STDOUT:   %.75f: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.f67, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.c1f: type = struct_type {.discriminant: %u1, .payload: %.75f} [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.10: type = fn_type @Destroy.Op.loc40_17.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.10: %Destroy.Op.type.1d8f74.10 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.14: type = fn_type @Destroy.Op.loc40_17.6 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.14: %Destroy.Op.type.1d8f74.14 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.4e9: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.5c1: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %.826: type = fn_type_with_self_type %Copy.WithSelf.Op.type.5c1, %Copy.facet.4e9 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.b95: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT:   %As.type.998: type = facet_type <@As, @As(%i64)> [concrete]
// CHECK:STDOUT:   %To.d23: Core.IntLiteral = symbolic_binding To, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.type.a00: type = fn_type @Int.as.As.impl.Convert.2, @Int.as.As.impl.c50(%From.fe9, %To.d23) [symbolic]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.3b9: %Int.as.As.impl.Convert.type.a00 = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.017: <witness> = impl_witness imports.%As.impl_witness_table.dc5, @Int.as.As.impl.c50(%int_32, %int_64) [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.type.430: type = fn_type @Int.as.As.impl.Convert.2, @Int.as.As.impl.c50(%int_32, %int_64) [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.9d1: %Int.as.As.impl.Convert.type.430 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.998 = facet_value %i32, (%As.impl_witness.017) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.bdc: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i64, %As.facet) [concrete]
// CHECK:STDOUT:   %.115: type = fn_type_with_self_type %As.WithSelf.Convert.type.bdc, %As.facet [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Int.as.As.impl.Convert.9d1, @Int.as.As.impl.Convert.2(%int_32, %int_64) [concrete]
// CHECK:STDOUT:   %AddWith.type.313: type = facet_type <@AddWith, @AddWith(%i64)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.aee: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.6b6: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.e5a: %Int.as.AddWith.impl.Op.type.6b6 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.cd2: %AddWith.type.313 = facet_value %i64, (%AddWith.impl_witness.aee) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.24d: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i64, %AddWith.facet.cd2) [concrete]
// CHECK:STDOUT:   %.67a: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.24d, %AddWith.facet.cd2 [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f02: <specific function> = specific_function %Int.as.AddWith.impl.Op.e5a, @Int.as.AddWith.impl.Op.1(%int_64) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %MyResult.Ok.f46, @MyResult.Ok(%i64, %i32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.a86: @Int.as.As.impl.c50.%Int.as.As.impl.Convert.type (%Int.as.As.impl.Convert.type.a00) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.As.impl.c50.%Int.as.As.impl.Convert (constants.%Int.as.As.impl.Convert.3b9)]
// CHECK:STDOUT:   %As.impl_witness_table.dc5 = impl_witness_table (%Core.import_ref.a86), @Int.as.As.impl.c50 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %MyResult.Ok.decl: @MyResult.%MyResult.Ok.type (%MyResult.Ok.type.fd7) = fn_decl @MyResult.Ok [symbolic = @MyResult.%MyResult.Ok (constants.%MyResult.Ok.460)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Both.decl: %Both.type = fn_decl @Both [concrete = constants.%Both] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.90f = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.90f = at_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.99b = value_param_pattern [concrete = constants.%b.param_patt.341]
// CHECK:STDOUT:     %b.patt: %pattern_type.99b = at_binding_pattern b, %b.param_patt [concrete = constants.%b.patt.402]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.99b = out_param_pattern [concrete = constants.%return.param_patt.411]
// CHECK:STDOUT:     %return.patt: %pattern_type.99b = return_slot_pattern %return.param_patt, %MyResult.loc38_75 [concrete = constants.%return.patt.1d9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc38_58: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i64.loc38_67: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %i32.loc38_72: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc38_75: type = class_type @MyResult, @MyResult(constants.%i64, constants.%i32) [concrete = constants.%MyResult.964]
// CHECK:STDOUT:     %.loc38_75.4: Core.Form = init_form %MyResult.loc38_75 [concrete = constants.%.b38bf]
// CHECK:STDOUT:     %a.param: %MyResult.21e = value_param call_param0
// CHECK:STDOUT:     %.loc38_29: type = splice_block %MyResult.loc38_29 [concrete = constants.%MyResult.21e] {
// CHECK:STDOUT:       %MyResult.ref.loc38_12: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %i32.loc38_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc38_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %MyResult.loc38_29: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %MyResult.21e = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %MyResult.964 = value_param call_param1
// CHECK:STDOUT:     %.loc38_52: type = splice_block %MyResult.loc38_52 [concrete = constants.%MyResult.964] {
// CHECK:STDOUT:       %MyResult.ref.loc38_35: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %i64.loc38_44: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %i32.loc38_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %MyResult.loc38_52: type = class_type @MyResult, @MyResult(constants.%i64, constants.%i32) [concrete = constants.%MyResult.964]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %MyResult.964 = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %MyResult.964 = out_param call_param2
// CHECK:STDOUT:     %return: ref %MyResult.964 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Both(%a.param: %MyResult.21e, %b.param: %MyResult.964) -> out %return.param: %MyResult.964 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.var: ref %i32 = var_storage %x.var_patt
// CHECK:STDOUT:   %a.ref: %MyResult.21e = name_ref a, %a
// CHECK:STDOUT:   %impl.elem2.loc39: %.5f8 = impl_witness_access constants.%Try.impl_witness.cda, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc39_17.1: <bound method> = bound_method %a.ref, %impl.elem2.loc39
// CHECK:STDOUT:   %specific_fn.loc39_17.1: <specific function> = specific_function %impl.elem2.loc39, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn.1fe]
// CHECK:STDOUT:   %bound_method.loc39_17.2: <bound method> = bound_method %a.ref, %specific_fn.loc39_17.1
// CHECK:STDOUT:   %.loc39_17.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc39: init %ControlFlow.32a to %.loc39_17.1 = call %bound_method.loc39_17.2(%a.ref)
// CHECK:STDOUT:   %.loc39_17.2: ref %ControlFlow.32a = temporary %.loc39_17.1, %MyResult.as.Try.impl.Branch.call.loc39
// CHECK:STDOUT:   %int_1.loc39: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc39_17.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc39_17.3: <bound method> = bound_method %int_1.loc39, %impl.elem0.loc39_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc39_17.2: <specific function> = specific_function %impl.elem0.loc39_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc39_17.4: <bound method> = bound_method %int_1.loc39, %specific_fn.loc39_17.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc39: init %u1 = call %bound_method.loc39_17.4(%int_1.loc39) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc39_17.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc39 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc39_17.4: %u1 = converted %int_1.loc39, %.loc39_17.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc39_17.5: ref %u1 = class_element_access %.loc39_17.2, element0
// CHECK:STDOUT:   %impl.elem0.loc39_17.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc39_17.5: <bound method> = bound_method %.loc39_17.4, %impl.elem0.loc39_17.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc39_17.3: <specific function> = specific_function %impl.elem0.loc39_17.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc39_17.6: <bound method> = bound_method %.loc39_17.4, %specific_fn.loc39_17.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc39_17.6: %u1 = acquire_value %.loc39_17.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc39: init bool = call %bound_method.loc39_17.6(%.loc39_17.4, %.loc39_17.6)
// CHECK:STDOUT:   %.loc39_17.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc39
// CHECK:STDOUT:   %.loc39_17.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc39, %.loc39_17.7
// CHECK:STDOUT:   if %.loc39_17.8 br !.loc39_17.1 else br !.loc39_17.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc39_17.1:
// CHECK:STDOUT:   %.loc39_17.9: ref %.b63 = class_element_access %.loc39_17.2, element1
// CHECK:STDOUT:   %.loc39_17.10: ref %tuple.type.a8a = class_element_access %.loc39_17.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc39_17.1: ref %i32 = tuple_access %.loc39_17.10, element0
// CHECK:STDOUT:   %.loc39_17.11: %i32 = acquire_value %tuple.elem0.loc39_17.1
// CHECK:STDOUT:   %Try.facet.loc39: %Try.type = facet_value constants.%MyResult.964, (constants.%Try.impl_witness.8e7) [concrete = constants.%Try.facet.93f]
// CHECK:STDOUT:   %.loc39_17.12: %Try.type = converted constants.%MyResult.964, %Try.facet.loc39 [concrete = constants.%Try.facet.93f]
// CHECK:STDOUT:   %impl.elem3.loc39: %.79f = impl_witness_access constants.%Try.impl_witness.8e7, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.ae9]
// CHECK:STDOUT:   %specific_fn.loc39_17.4: <specific function> = specific_function %impl.elem3.loc39, @MyResult.as.Try.impl.FromBreak(constants.%i64, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc38_75.1: ref %MyResult.964 = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc39: init %MyResult.964 to %.loc38_75.1 = call %specific_fn.loc39_17.4(%.loc39_17.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc39_17.1: <bound method> = bound_method %.loc39_17.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc39_17.1: init %empty_tuple.type = call %Destroy.Op.bound.loc39_17.1(%.loc39_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc39_3.1: <bound method> = bound_method %x.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc39_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc39_3.1(%x.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc39 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc39_17.2:
// CHECK:STDOUT:   %.loc39_17.13: ref %.b63 = class_element_access %.loc39_17.2, element1
// CHECK:STDOUT:   %.loc39_17.14: ref %tuple.type.a8a = class_element_access %.loc39_17.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc39_17.2: ref %i32 = tuple_access %.loc39_17.14, element0
// CHECK:STDOUT:   %.loc39_17.15: %i32 = acquire_value %tuple.elem0.loc39_17.2
// CHECK:STDOUT:   %impl.elem0.loc39_17.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc39_17.7: <bound method> = bound_method %.loc39_17.15, %impl.elem0.loc39_17.3
// CHECK:STDOUT:   %specific_fn.loc39_17.5: <specific function> = specific_function %impl.elem0.loc39_17.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:   %bound_method.loc39_17.8: <bound method> = bound_method %.loc39_17.15, %specific_fn.loc39_17.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc39: init %i32 = call %bound_method.loc39_17.8(%.loc39_17.15)
// CHECK:STDOUT:   assign %x.var, %Int.as.Copy.impl.Op.call.loc39
// CHECK:STDOUT:   %i32.loc39: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %x: ref %i32 = wrapper_binding x, %x.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = ref_binding_pattern x [concrete = constants.%x.patt]
// CHECK:STDOUT:     %x.var_patt: %pattern_type.6b6 = var_pattern %x.patt [concrete = constants.%x.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %y.var: ref %i64 = var_storage %y.var_patt
// CHECK:STDOUT:   %b.ref: %MyResult.964 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem2.loc40: %.ea8 = impl_witness_access constants.%Try.impl_witness.8e7, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.871]
// CHECK:STDOUT:   %bound_method.loc40_17.1: <bound method> = bound_method %b.ref, %impl.elem2.loc40
// CHECK:STDOUT:   %specific_fn.loc40_17.1: <specific function> = specific_function %impl.elem2.loc40, @MyResult.as.Try.impl.Branch(constants.%i64, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn.019]
// CHECK:STDOUT:   %bound_method.loc40_17.2: <bound method> = bound_method %b.ref, %specific_fn.loc40_17.1
// CHECK:STDOUT:   %.loc40_17.1: ref %ControlFlow.3df = temporary_storage
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc40: init %ControlFlow.3df to %.loc40_17.1 = call %bound_method.loc40_17.2(%b.ref)
// CHECK:STDOUT:   %.loc40_17.2: ref %ControlFlow.3df = temporary %.loc40_17.1, %MyResult.as.Try.impl.Branch.call.loc40
// CHECK:STDOUT:   %int_1.loc40: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc40_17.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc40_17.3: <bound method> = bound_method %int_1.loc40, %impl.elem0.loc40_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc40_17.2: <specific function> = specific_function %impl.elem0.loc40_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc40_17.4: <bound method> = bound_method %int_1.loc40, %specific_fn.loc40_17.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc40: init %u1 = call %bound_method.loc40_17.4(%int_1.loc40) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc40_17.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc40 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc40_17.4: %u1 = converted %int_1.loc40, %.loc40_17.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc40_17.5: ref %u1 = class_element_access %.loc40_17.2, element0
// CHECK:STDOUT:   %impl.elem0.loc40_17.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc40_17.5: <bound method> = bound_method %.loc40_17.4, %impl.elem0.loc40_17.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc40_17.3: <specific function> = specific_function %impl.elem0.loc40_17.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc40_17.6: <bound method> = bound_method %.loc40_17.4, %specific_fn.loc40_17.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc40_17.6: %u1 = acquire_value %.loc40_17.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc40: init bool = call %bound_method.loc40_17.6(%.loc40_17.4, %.loc40_17.6)
// CHECK:STDOUT:   %.loc40_17.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc40
// CHECK:STDOUT:   %.loc40_17.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc40, %.loc40_17.7
// CHECK:STDOUT:   if %.loc40_17.8 br !.loc40_17.1 else br !.loc40_17.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc40_17.1:
// CHECK:STDOUT:   %.loc40_17.9: ref %.75f = class_element_access %.loc40_17.2, element1
// CHECK:STDOUT:   %.loc40_17.10: ref %tuple.type.a8a = class_element_access %.loc40_17.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc40_17.1: ref %i32 = tuple_access %.loc40_17.10, element0
// CHECK:STDOUT:   %.loc40_17.11: %i32 = acquire_value %tuple.elem0.loc40_17.1
// CHECK:STDOUT:   %Try.facet.loc40: %Try.type = facet_value constants.%MyResult.964, (constants.%Try.impl_witness.8e7) [concrete = constants.%Try.facet.93f]
// CHECK:STDOUT:   %.loc40_17.12: %Try.type = converted constants.%MyResult.964, %Try.facet.loc40 [concrete = constants.%Try.facet.93f]
// CHECK:STDOUT:   %impl.elem3.loc40: %.79f = impl_witness_access constants.%Try.impl_witness.8e7, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.ae9]
// CHECK:STDOUT:   %specific_fn.loc40_17.4: <specific function> = specific_function %impl.elem3.loc40, @MyResult.as.Try.impl.FromBreak(constants.%i64, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc38_75.2: ref %MyResult.964 = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc40: init %MyResult.964 to %.loc38_75.2 = call %specific_fn.loc40_17.4(%.loc40_17.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc40_17.1: <bound method> = bound_method %.loc40_17.2, constants.%Destroy.Op.1a2547.14
// CHECK:STDOUT:   %Destroy.Op.call.loc40_17.1: init %empty_tuple.type = call %Destroy.Op.bound.loc40_17.1(%.loc40_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc40_3.1: <bound method> = bound_method %y.var, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc40_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc40_3.1(%y.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc39_17.2: <bound method> = bound_method %.loc39_17.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc39_17.2: init %empty_tuple.type = call %Destroy.Op.bound.loc39_17.2(%.loc39_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc39_3.2: <bound method> = bound_method %x.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc39_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc39_3.2(%x.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc40 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc40_17.2:
// CHECK:STDOUT:   %.loc40_17.13: ref %.75f = class_element_access %.loc40_17.2, element1
// CHECK:STDOUT:   %.loc40_17.14: ref %tuple.type.f67 = class_element_access %.loc40_17.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc40_17.2: ref %i64 = tuple_access %.loc40_17.14, element0
// CHECK:STDOUT:   %.loc40_17.15: %i64 = acquire_value %tuple.elem0.loc40_17.2
// CHECK:STDOUT:   %impl.elem0.loc40_17.3: %.826 = impl_witness_access constants.%Copy.impl_witness.8cc, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc40_17.7: <bound method> = bound_method %.loc40_17.15, %impl.elem0.loc40_17.3
// CHECK:STDOUT:   %specific_fn.loc40_17.5: <specific function> = specific_function %impl.elem0.loc40_17.3, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.b95]
// CHECK:STDOUT:   %bound_method.loc40_17.8: <bound method> = bound_method %.loc40_17.15, %specific_fn.loc40_17.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc40: init %i64 = call %bound_method.loc40_17.8(%.loc40_17.15)
// CHECK:STDOUT:   assign %y.var, %Int.as.Copy.impl.Op.call.loc40
// CHECK:STDOUT:   %i64.loc40: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %y: ref %i64 = wrapper_binding y, %y.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %y.patt: %pattern_type.f57 = ref_binding_pattern y [concrete = constants.%y.patt]
// CHECK:STDOUT:     %y.var_patt: %pattern_type.f57 = var_pattern %y.patt [concrete = constants.%y.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc41: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i64.loc41_19: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %i32.loc41: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc41: type = class_type @MyResult, @MyResult(constants.%i64, constants.%i32) [concrete = constants.%MyResult.964]
// CHECK:STDOUT:   %.loc41_28: %MyResult.Ok.type.547 = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i64, constants.%i32) [concrete = constants.%MyResult.Ok.f46]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.547 = name_ref Ok, %.loc41_28 [concrete = constants.%MyResult.Ok.f46]
// CHECK:STDOUT:   %y.ref: ref %i64 = name_ref y, %y
// CHECK:STDOUT:   %x.ref: ref %i32 = name_ref x, %x
// CHECK:STDOUT:   %i64.loc41_42: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0.loc41: %.115 = impl_witness_access constants.%As.impl_witness.017, element0 [concrete = constants.%Int.as.As.impl.Convert.9d1]
// CHECK:STDOUT:   %bound_method.loc41_39.1: <bound method> = bound_method %x.ref, %impl.elem0.loc41
// CHECK:STDOUT:   %specific_fn.loc41_39: <specific function> = specific_function %impl.elem0.loc41, @Int.as.As.impl.Convert.2(constants.%int_32, constants.%int_64) [concrete = constants.%Int.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc41_39.2: <bound method> = bound_method %x.ref, %specific_fn.loc41_39
// CHECK:STDOUT:   %.loc41_37: %i32 = acquire_value %x.ref
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call: init %i64 = call %bound_method.loc41_39.2(%.loc41_37)
// CHECK:STDOUT:   %.loc41_39.1: %i64 = value_of_initializer %Int.as.As.impl.Convert.call
// CHECK:STDOUT:   %.loc41_39.2: %i64 = converted %x.ref, %.loc41_39.1
// CHECK:STDOUT:   %impl.elem1: %.67a = impl_witness_access constants.%AddWith.impl_witness.aee, element1 [concrete = constants.%Int.as.AddWith.impl.Op.e5a]
// CHECK:STDOUT:   %bound_method.loc41_34.1: <bound method> = bound_method %y.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc41_34: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_64) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f02]
// CHECK:STDOUT:   %bound_method.loc41_34.2: <bound method> = bound_method %y.ref, %specific_fn.loc41_34
// CHECK:STDOUT:   %.loc41_32: %i64 = acquire_value %y.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i64 = call %bound_method.loc41_34.2(%.loc41_32, %.loc41_39.2)
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i64, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc38_75.3: ref %MyResult.964 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc41_34.1: %i64 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc41_34.2: %i64 = converted %Int.as.AddWith.impl.Op.call, %.loc41_34.1
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.964 to %.loc38_75.3 = call %MyResult.Ok.specific_fn(%.loc41_34.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc40_17.2: <bound method> = bound_method %.loc40_17.2, constants.%Destroy.Op.1a2547.14
// CHECK:STDOUT:   %Destroy.Op.call.loc40_17.2: init %empty_tuple.type = call %Destroy.Op.bound.loc40_17.2(%.loc40_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc40_3.2: <bound method> = bound_method %y.var, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc40_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc40_3.2(%y.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc39_17.3: <bound method> = bound_method %.loc39_17.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc39_17.3: init %empty_tuple.type = call %Destroy.Op.bound.loc39_17.3(%.loc39_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc39_3.3: <bound method> = bound_method %x.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc39_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc39_3.3(%x.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc39_17.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc39_17.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc39_17.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc39_17.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc39_17.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc39_17.6(%self.param: ref %.b63) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc39_17.7(%self.param: ref %struct_type.discriminant.payload.88b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc39_17.8(%self.param: ref %ControlFlow.32a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc40_17.1(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc40_17.2(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc40_17.3(%self.param: ref %tuple.type.f67) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc40_17.4(%self.param: ref %.75f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc40_17.5(%self.param: ref %struct_type.discriminant.payload.c1f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc40_17.6(%self.param: ref %ControlFlow.3df) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- repeat.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Inner: type = class_type @Inner [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Outer: type = class_type @Outer [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.228: <witness> = impl_witness @Outer.as.Copy.impl.%Copy.impl_witness_table [concrete]
// CHECK:STDOUT:   %pattern_type.d6c: type = pattern_type %Outer [concrete]
// CHECK:STDOUT:   %.50e: Core.Form = init_form %Outer [concrete]
// CHECK:STDOUT:   %return.param_patt.756: %pattern_type.d6c = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.991: %pattern_type.d6c = return_slot_pattern %return.param_patt.756, %Outer [concrete]
// CHECK:STDOUT:   %Outer.as.Copy.impl.Op.type: type = fn_type @Outer.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %Outer.as.Copy.impl.Op: %Outer.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.aba: %Copy.type = facet_value %Outer, (%Copy.impl_witness.228) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.f9e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.aba) [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.impl_witness.f65: <witness> = impl_witness @Inner.as.Try.impl.%Try.impl_witness_table [concrete]
// CHECK:STDOUT:   %ControlFlow.32a: type = class_type @ControlFlow, @ControlFlow(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Inner.as.Try.impl.Branch.type: type = fn_type @Inner.as.Try.impl.Branch [concrete]
// CHECK:STDOUT:   %Inner.as.Try.impl.Branch: %Inner.as.Try.impl.Branch.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Try.facet.5c9: %Try.type = facet_value %Inner, (%Try.impl_witness.f65) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.70d: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.5c9) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.b63: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.88b: type = struct_type {.discriminant: %u1, .payload: %.b63} [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.edf: <witness> = impl_witness @Outer.as.Try.impl.%Try.impl_witness_table [concrete]
// CHECK:STDOUT:   %ControlFlow.e96: type = class_type @ControlFlow, @ControlFlow(%Inner, %i32) [concrete]
// CHECK:STDOUT:   %Outer.as.Try.impl.Branch.type: type = fn_type @Outer.as.Try.impl.Branch [concrete]
// CHECK:STDOUT:   %Outer.as.Try.impl.Branch: %Outer.as.Try.impl.Branch.type = struct_value () [concrete]
// CHECK:STDOUT:   %Outer.as.Try.impl.FromBreak.type: type = fn_type @Outer.as.Try.impl.FromBreak [concrete]
// CHECK:STDOUT:   %Outer.as.Try.impl.FromBreak: %Outer.as.Try.impl.FromBreak.type = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.a46: %Try.type = facet_value %Outer, (%Try.impl_witness.edf) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.ae4: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.a46) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.c01: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.a46) [concrete]
// CHECK:STDOUT:   %tuple.type.c08: type = tuple_type (%Inner) [concrete]
// CHECK:STDOUT:   %.f6f: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.c08, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.76c: type = struct_type {.discriminant: %u1, .payload: %.f6f} [concrete]
// CHECK:STDOUT:   %.d1e: type = fn_type_with_self_type %Copy.WithSelf.Op.type.f9e, %Copy.facet.aba [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.d6c = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.d6c = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %Twice.type: type = fn_type @Twice [concrete]
// CHECK:STDOUT:   %Twice: %Twice.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete]
// CHECK:STDOUT:   %.f87: type = fn_type_with_self_type %Try.WithSelf.Branch.type.ae4, %Try.facet.a46 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.768: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.c01, %Try.facet.a46 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc47_17.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.10: type = fn_type @Destroy.Op.loc47_17.10 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.10: %Destroy.Op.type.1d8f74.10 = struct_value () [concrete]
// CHECK:STDOUT:   %.2c6: type = fn_type_with_self_type %Try.WithSelf.Branch.type.70d, %Try.facet.5c9 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.13: type = fn_type @Destroy.Op.loc47_18.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.13: %Destroy.Op.type.1d8f74.13 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Twice.decl: %Twice.type = fn_decl @Twice [concrete = constants.%Twice] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.d6c = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.d6c = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.d6c = out_param_pattern [concrete = constants.%return.param_patt.756]
// CHECK:STDOUT:     %return.patt: %pattern_type.d6c = return_slot_pattern %return.param_patt, %Outer.ref.loc46_23 [concrete = constants.%return.patt.991]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Outer.ref.loc46_23: type = name_ref Outer, file.%Outer.decl [concrete = constants.%Outer]
// CHECK:STDOUT:     %.loc46: Core.Form = init_form %Outer.ref.loc46_23 [concrete = constants.%.50e]
// CHECK:STDOUT:     %x.param: %Outer = value_param call_param0
// CHECK:STDOUT:     %Outer.ref.loc46_13: type = name_ref Outer, file.%Outer.decl [concrete = constants.%Outer]
// CHECK:STDOUT:     %x: %Outer = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %Outer = out_param call_param1
// CHECK:STDOUT:     %return: ref %Outer = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Twice(%x.param: %Outer) -> out %return.param: %Outer {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %i32 = var_storage %v.var_patt
// CHECK:STDOUT:   %x.ref: %Outer = name_ref x, %x
// CHECK:STDOUT:   %impl.elem2.loc47_17: %.f87 = impl_witness_access constants.%Try.impl_witness.edf, element2 [concrete = constants.%Outer.as.Try.impl.Branch]
// CHECK:STDOUT:   %bound_method.loc47_17.1: <bound method> = bound_method %x.ref, %impl.elem2.loc47_17
// CHECK:STDOUT:   %.loc47_17.1: ref %ControlFlow.e96 = temporary_storage
// CHECK:STDOUT:   %Outer.as.Try.impl.Branch.call: init %ControlFlow.e96 to %.loc47_17.1 = call %bound_method.loc47_17.1(%x.ref)
// CHECK:STDOUT:   %.loc47_17.2: ref %ControlFlow.e96 = temporary %.loc47_17.1, %Outer.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc47_17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc47_17.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc47_17.2: <bound method> = bound_method %int_1.loc47_17, %impl.elem0.loc47_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc47_17.1: <specific function> = specific_function %impl.elem0.loc47_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc47_17.3: <bound method> = bound_method %int_1.loc47_17, %specific_fn.loc47_17.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc47_17: init %u1 = call %bound_method.loc47_17.3(%int_1.loc47_17) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_17.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc47_17 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_17.4: %u1 = converted %int_1.loc47_17, %.loc47_17.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_17.5: ref %u1 = class_element_access %.loc47_17.2, element0
// CHECK:STDOUT:   %impl.elem0.loc47_17.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc47_17.4: <bound method> = bound_method %.loc47_17.4, %impl.elem0.loc47_17.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc47_17.2: <specific function> = specific_function %impl.elem0.loc47_17.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc47_17.5: <bound method> = bound_method %.loc47_17.4, %specific_fn.loc47_17.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc47_17.6: %u1 = acquire_value %.loc47_17.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc47_17: init bool = call %bound_method.loc47_17.5(%.loc47_17.4, %.loc47_17.6)
// CHECK:STDOUT:   %.loc47_17.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc47_17
// CHECK:STDOUT:   %.loc47_17.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc47_17, %.loc47_17.7
// CHECK:STDOUT:   if %.loc47_17.8 br !.loc47_17.1 else br !.loc47_17.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc47_17.1:
// CHECK:STDOUT:   %.loc47_17.9: ref %.f6f = class_element_access %.loc47_17.2, element1
// CHECK:STDOUT:   %.loc47_17.10: ref %tuple.type.a8a = class_element_access %.loc47_17.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc47_17.1: ref %i32 = tuple_access %.loc47_17.10, element0
// CHECK:STDOUT:   %.loc47_17.11: %i32 = acquire_value %tuple.elem0.loc47_17.1
// CHECK:STDOUT:   %Try.facet.loc47_17: %Try.type = facet_value constants.%Outer, (constants.%Try.impl_witness.edf) [concrete = constants.%Try.facet.a46]
// CHECK:STDOUT:   %.loc47_17.12: %Try.type = converted constants.%Outer, %Try.facet.loc47_17 [concrete = constants.%Try.facet.a46]
// CHECK:STDOUT:   %impl.elem3.loc47_17: %.768 = impl_witness_access constants.%Try.impl_witness.edf, element3 [concrete = constants.%Outer.as.Try.impl.FromBreak]
// CHECK:STDOUT:   %Outer.as.Try.impl.FromBreak.call.loc47_17: init %Outer = call %impl.elem3.loc47_17(%.loc47_17.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc47_17.1: <bound method> = bound_method %.loc47_17.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc47_17.1: init %empty_tuple.type = call %Destroy.Op.bound.loc47_17.1(%.loc47_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc47_3.1: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc47_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc47_3.1(%v.var)
// CHECK:STDOUT:   return %Outer.as.Try.impl.FromBreak.call.loc47_17
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc47_17.2:
// CHECK:STDOUT:   %.loc47_17.13: ref %.f6f = class_element_access %.loc47_17.2, element1
// CHECK:STDOUT:   %.loc47_17.14: ref %tuple.type.c08 = class_element_access %.loc47_17.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc47_17.2: ref %Inner = tuple_access %.loc47_17.14, element0
// CHECK:STDOUT:   %.loc47_17.15: %Inner = acquire_value %tuple.elem0.loc47_17.2
// CHECK:STDOUT:   %impl.elem2.loc47_18: %.2c6 = impl_witness_access constants.%Try.impl_witness.f65, element2 [concrete = constants.%Inner.as.Try.impl.Branch]
// CHECK:STDOUT:   %bound_method.loc47_18.1: <bound method> = bound_method %.loc47_17.15, %impl.elem2.loc47_18
// CHECK:STDOUT:   %.loc47_18.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %Inner.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc47_18.1 = call %bound_method.loc47_18.1(%.loc47_17.15)
// CHECK:STDOUT:   %.loc47_18.2: ref %ControlFlow.32a = temporary %.loc47_18.1, %Inner.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc47_18: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc47_18.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc47_18.2: <bound method> = bound_method %int_1.loc47_18, %impl.elem0.loc47_18.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc47_18.1: <specific function> = specific_function %impl.elem0.loc47_18.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc47_18.3: <bound method> = bound_method %int_1.loc47_18, %specific_fn.loc47_18.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc47_18: init %u1 = call %bound_method.loc47_18.3(%int_1.loc47_18) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_18.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc47_18 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_18.4: %u1 = converted %int_1.loc47_18, %.loc47_18.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_18.5: ref %u1 = class_element_access %.loc47_18.2, element0
// CHECK:STDOUT:   %impl.elem0.loc47_18.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc47_18.4: <bound method> = bound_method %.loc47_18.4, %impl.elem0.loc47_18.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc47_18.2: <specific function> = specific_function %impl.elem0.loc47_18.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc47_18.5: <bound method> = bound_method %.loc47_18.4, %specific_fn.loc47_18.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc47_18.6: %u1 = acquire_value %.loc47_18.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc47_18: init bool = call %bound_method.loc47_18.5(%.loc47_18.4, %.loc47_18.6)
// CHECK:STDOUT:   %.loc47_18.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc47_18
// CHECK:STDOUT:   %.loc47_18.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc47_18, %.loc47_18.7
// CHECK:STDOUT:   if %.loc47_18.8 br !.loc47_18.1 else br !.loc47_18.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc47_18.1:
// CHECK:STDOUT:   %.loc47_18.9: ref %.b63 = class_element_access %.loc47_18.2, element1
// CHECK:STDOUT:   %.loc47_18.10: ref %tuple.type.a8a = class_element_access %.loc47_18.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc47_18.1: ref %i32 = tuple_access %.loc47_18.10, element0
// CHECK:STDOUT:   %.loc47_18.11: %i32 = acquire_value %tuple.elem0.loc47_18.1
// CHECK:STDOUT:   %Try.facet.loc47_18: %Try.type = facet_value constants.%Outer, (constants.%Try.impl_witness.edf) [concrete = constants.%Try.facet.a46]
// CHECK:STDOUT:   %.loc47_18.12: %Try.type = converted constants.%Outer, %Try.facet.loc47_18 [concrete = constants.%Try.facet.a46]
// CHECK:STDOUT:   %impl.elem3.loc47_18: %.768 = impl_witness_access constants.%Try.impl_witness.edf, element3 [concrete = constants.%Outer.as.Try.impl.FromBreak]
// CHECK:STDOUT:   %Outer.as.Try.impl.FromBreak.call.loc47_18: init %Outer = call %impl.elem3.loc47_18(%.loc47_18.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc47_18.1: <bound method> = bound_method %.loc47_18.2, constants.%Destroy.Op.1a2547.13
// CHECK:STDOUT:   %Destroy.Op.call.loc47_18.1: init %empty_tuple.type = call %Destroy.Op.bound.loc47_18.1(%.loc47_18.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc47_17.2: <bound method> = bound_method %.loc47_17.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc47_17.2: init %empty_tuple.type = call %Destroy.Op.bound.loc47_17.2(%.loc47_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc47_3.2: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc47_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc47_3.2(%v.var)
// CHECK:STDOUT:   return %Outer.as.Try.impl.FromBreak.call.loc47_18
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc47_18.2:
// CHECK:STDOUT:   %.loc47_18.13: ref %.b63 = class_element_access %.loc47_18.2, element1
// CHECK:STDOUT:   %.loc47_18.14: ref %tuple.type.a8a = class_element_access %.loc47_18.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc47_18.2: ref %i32 = tuple_access %.loc47_18.14, element0
// CHECK:STDOUT:   %.loc47_18.15: %i32 = acquire_value %tuple.elem0.loc47_18.2
// CHECK:STDOUT:   %impl.elem0.loc47_18.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc47_18.6: <bound method> = bound_method %.loc47_18.15, %impl.elem0.loc47_18.3
// CHECK:STDOUT:   %specific_fn.loc47_18.3: <specific function> = specific_function %impl.elem0.loc47_18.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc47_18.7: <bound method> = bound_method %.loc47_18.15, %specific_fn.loc47_18.3
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc47_18.7(%.loc47_18.15)
// CHECK:STDOUT:   assign %v.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.ref: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %Outer.ref.loc48: type = name_ref Outer, file.%Outer.decl [concrete = constants.%Outer]
// CHECK:STDOUT:   %.loc48_12.1: ref %Outer = as_compatible %v.ref
// CHECK:STDOUT:   %.loc48_12.2: ref %Outer = converted %v.ref, %.loc48_12.1
// CHECK:STDOUT:   %.loc48_12.3: %Outer = acquire_value %.loc48_12.2
// CHECK:STDOUT:   %impl.elem0.loc48: %.d1e = impl_witness_access constants.%Copy.impl_witness.228, element0 [concrete = constants.%Outer.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc48: <bound method> = bound_method %.loc48_12.3, %impl.elem0.loc48
// CHECK:STDOUT:   %Outer.as.Copy.impl.Op.call: init %Outer = call %bound_method.loc48(%.loc48_12.3)
// CHECK:STDOUT:   %Destroy.Op.bound.loc47_18.2: <bound method> = bound_method %.loc47_18.2, constants.%Destroy.Op.1a2547.13
// CHECK:STDOUT:   %Destroy.Op.call.loc47_18.2: init %empty_tuple.type = call %Destroy.Op.bound.loc47_18.2(%.loc47_18.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc47_17.3: <bound method> = bound_method %.loc47_17.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc47_17.3: init %empty_tuple.type = call %Destroy.Op.bound.loc47_17.3(%.loc47_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc47_3.3: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc47_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc47_3.3(%v.var)
// CHECK:STDOUT:   return %Outer.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.5(%self.param: ref %Inner) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.6(%self.param: ref %tuple.type.c08) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.7(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.8(%self.param: ref %.f6f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.9(%self.param: ref %struct_type.discriminant.payload.76c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_17.10(%self.param: ref %ControlFlow.e96) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_18.1(%self.param: ref %.b63) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_18.2(%self.param: ref %struct_type.discriminant.payload.88b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc47_18.3(%self.param: ref %ControlFlow.32a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.197: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %E.patt: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %MyResult.type: type = generic_class_type @MyResult [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %MyResult.generic: %MyResult.type = struct_value () [concrete]
// CHECK:STDOUT:   %MyResult.52ca24.1: type = class_type @MyResult, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %pattern_type.946bb9.1: type = pattern_type %E [symbolic]
// CHECK:STDOUT:   %e.param_patt.92c2b1.1: %pattern_type.946bb9.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %e.patt.1c0fff.1: %pattern_type.946bb9.1 = at_binding_pattern e, %e.param_patt.92c2b1.1 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %UInt.type: type = generic_class_type @UInt [concrete]
// CHECK:STDOUT:   %UInt.generic: %UInt.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.026b76.1: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %require_complete.441886.1: <witness> = require_complete_type %E [symbolic]
// CHECK:STDOUT:   %.6c705e.1: Core.Form = init_form %MyResult.52ca24.1 [symbolic]
// CHECK:STDOUT:   %pattern_type.6db5df.1: type = pattern_type %MyResult.52ca24.1 [symbolic]
// CHECK:STDOUT:   %return.param_patt.296c1c.1: %pattern_type.6db5df.1 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.971efd.1: %pattern_type.6db5df.1 = return_slot_pattern %return.param_patt.296c1c.1, %MyResult.52ca24.1 [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.type.fd7821.1: type = fn_type @MyResult.Ok, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.4604d7.1: %MyResult.Ok.type.fd7821.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.090415.1: <witness> = require_complete_type %MyResult.52ca24.1 [symbolic]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %MyResult.Err.type.11093c.1: type = fn_type @MyResult.Err, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.Err.899cd4.1: %MyResult.Err.type.11093c.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %Self.cc4: %Try.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.030: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Self.cc4) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.e67: %Try.WithSelf.FromBreak.type.030 = struct_value () [symbolic]
// CHECK:STDOUT:   %ControlFlow.type: type = generic_class_type @ControlFlow [concrete]
// CHECK:STDOUT:   %ControlFlow.generic: %ControlFlow.type = struct_value () [concrete]
// CHECK:STDOUT:   %.Self.frozen.5e9: %Try.type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %.Self.frozen.as_type: type = facet_access_type %.Self.frozen.5e9 [symbolic_self]
// CHECK:STDOUT:   %Try.assoc_type: type = assoc_entity_type @Try [concrete]
// CHECK:STDOUT:   %assoc0.de3: %Try.assoc_type = assoc_entity element0, imports.%Core.import_ref.c56 [concrete]
// CHECK:STDOUT:   %assoc1.f63: %Try.assoc_type = assoc_entity element1, imports.%Core.import_ref.9a9 [concrete]
// CHECK:STDOUT:   %.Self: %Try.type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %v.patt.291: %pattern_type.51d1c4.1 = value_binding_pattern v [symbolic]
// CHECK:STDOUT:   %pattern_type.b26: type = pattern_type %tuple.type.026b76.1 [symbolic]
// CHECK:STDOUT:   %.946: %pattern_type.b26 = tuple_pattern (%v.patt.291) [symbolic]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %MyResult.Err.specific_fn: <specific function> = specific_function %MyResult.Err.899cd4.1, @MyResult.Err(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MakeMR.type: type = fn_type @MakeMR [concrete]
// CHECK:STDOUT:   %MakeMR: %MakeMR.type = struct_value () [concrete]
// CHECK:STDOUT:   %Discard.type: type = fn_type @Discard [concrete]
// CHECK:STDOUT:   %Discard: %Discard.type = struct_value () [concrete]
// CHECK:STDOUT:   %Try.lookup_impl_witness.73a: <witness> = lookup_impl_witness %.Self.frozen.5e9, @Try [symbolic_self]
// CHECK:STDOUT:   %impl.elem1.660: type = impl_witness_access %Try.lookup_impl_witness.73a, element1 [symbolic_self]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Try.lookup_impl_witness.775: <witness> = lookup_impl_witness %.Self, @Try [symbolic_self]
// CHECK:STDOUT:   %impl.elem1.d8a: type = impl_witness_access %Try.lookup_impl_witness.775, element1 [symbolic_self]
// CHECK:STDOUT:   %Try_where.type.00c: type = facet_type <@Try where %impl.elem1.d8a = %i32> [concrete]
// CHECK:STDOUT:   %pattern_type.df6: type = pattern_type %Try_where.type.00c [concrete]
// CHECK:STDOUT:   %R.patt: %pattern_type.df6 = symbolic_binding_pattern R, 0 [symbolic]
// CHECK:STDOUT:   %R: %Try_where.type.00c = symbolic_binding R, 0 [symbolic]
// CHECK:STDOUT:   %R.as_type: type = facet_access_type %R [symbolic]
// CHECK:STDOUT:   %pattern_type.239: type = pattern_type %R.as_type [symbolic]
// CHECK:STDOUT:   %r.param_patt: %pattern_type.239 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %r.patt: %pattern_type.239 = at_binding_pattern r, %r.param_patt [symbolic]
// CHECK:STDOUT:   %.802: Core.Form = init_form %R.as_type [symbolic]
// CHECK:STDOUT:   %return.param_patt.aed: %pattern_type.239 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.0bca: %pattern_type.239 = return_slot_pattern %return.param_patt.aed, %R.as_type [symbolic]
// CHECK:STDOUT:   %PropagateOnly.type: type = fn_type @PropagateOnly [concrete]
// CHECK:STDOUT:   %PropagateOnly: %PropagateOnly.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.b5f: <witness> = require_complete_type %R.as_type [symbolic]
// CHECK:STDOUT:   %Try.lookup_impl_witness.832: <witness> = lookup_impl_witness %R, @Try [symbolic]
// CHECK:STDOUT:   %Try.facet.1ad: %Try.type = facet_value %R.as_type, (%Try.lookup_impl_witness.832) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.ef1: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.1ad) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.4c3: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.1ad) [symbolic]
// CHECK:STDOUT:   %impl.elem0.fca: type = impl_witness_access %Try.lookup_impl_witness.832, element0 [symbolic]
// CHECK:STDOUT:   %require_complete.677: <witness> = require_complete_type %impl.elem0.fca [symbolic]
// CHECK:STDOUT:   %pattern_type.b1f: type = pattern_type %impl.elem0.fca [symbolic]
// CHECK:STDOUT:   %c.patt: %pattern_type.b1f = value_binding_pattern c [symbolic]
// CHECK:STDOUT:   %.392: type = fn_type_with_self_type %Try.WithSelf.Branch.type.ef1, %Try.facet.1ad [symbolic]
// CHECK:STDOUT:   %impl.elem2.f77: %.392 = impl_witness_access %Try.lookup_impl_witness.832, element2 [symbolic]
// CHECK:STDOUT:   %ControlFlow.67f: type = class_type @ControlFlow, @ControlFlow(%impl.elem0.fca, %i32) [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.8ea: <specific function> = specific_impl_function %impl.elem2.f77, @Try.WithSelf.Branch(%Try.facet.1ad) [symbolic]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %tuple.type.c39: type = tuple_type (%impl.elem0.fca) [symbolic]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.990: type = custom_layout_type {size=0, align=0, .Continue@0: %tuple.type.c39, .Break@0: %tuple.type.a8a} [symbolic]
// CHECK:STDOUT:   %assoc3: %Try.assoc_type = assoc_entity element3, imports.%Core.import_ref.271 [concrete]
// CHECK:STDOUT:   %.287: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.4c3, %Try.facet.1ad [symbolic]
// CHECK:STDOUT:   %impl.elem3.d05: %.287 = impl_witness_access %Try.lookup_impl_witness.832, element3 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.9a1: <specific function> = specific_impl_function %impl.elem3.d05, @Try.WithSelf.FromBreak(%Try.facet.1ad) [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.dc9: <witness> = lookup_impl_witness %ControlFlow.67f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.a42: %Destroy.type = facet_value %ControlFlow.67f, (%Destroy.lookup_impl_witness.dc9) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.4a0: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.a42) [symbolic]
// CHECK:STDOUT:   %.425: type = fn_type_with_self_type %Destroy.WithSelf.Op.type.4a0, %Destroy.facet.a42 [symbolic]
// CHECK:STDOUT:   %impl.elem0.324: %.425 = impl_witness_access %Destroy.lookup_impl_witness.dc9, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.92b: <specific function> = specific_impl_function %impl.elem0.324, @Destroy.WithSelf.Op(%Destroy.facet.a42) [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %mr.param_patt: %pattern_type.6db5df.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %mr.patt.c42: %pattern_type.6db5df.1 = at_binding_pattern mr, %mr.param_patt [symbolic]
// CHECK:STDOUT:   %PropagateChoice.type: type = fn_type @PropagateChoice [concrete]
// CHECK:STDOUT:   %PropagateChoice: %PropagateChoice.type = struct_value () [concrete]
// CHECK:STDOUT:   %Try.lookup_impl_witness.669: <witness> = lookup_impl_witness %MyResult.52ca24.1, @Try [symbolic]
// CHECK:STDOUT:   %.fa0: require_specific_def_type = require_specific_def @MyResult.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Try.facet.a01: %Try.type = facet_value %MyResult.52ca24.1, (%Try.lookup_impl_witness.669) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.a69: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.a01) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.e24: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.a01) [symbolic]
// CHECK:STDOUT:   %.7bc: type = fn_type_with_self_type %Try.WithSelf.Branch.type.a69, %Try.facet.a01 [symbolic]
// CHECK:STDOUT:   %impl.elem2.1c7: %.7bc = impl_witness_access %Try.lookup_impl_witness.669, element2 [symbolic]
// CHECK:STDOUT:   %impl.elem0.c83: type = impl_witness_access %Try.lookup_impl_witness.669, element0 [symbolic]
// CHECK:STDOUT:   %impl.elem1.ffc: type = impl_witness_access %Try.lookup_impl_witness.669, element1 [symbolic]
// CHECK:STDOUT:   %ControlFlow.76f: type = class_type @ControlFlow, @ControlFlow(%impl.elem0.c83, %impl.elem1.ffc) [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.acd: <specific function> = specific_impl_function %impl.elem2.1c7, @Try.WithSelf.Branch(%Try.facet.a01) [symbolic]
// CHECK:STDOUT:   %require_complete.3f5: <witness> = require_complete_type %impl.elem0.c83 [symbolic]
// CHECK:STDOUT:   %require_complete.faf: <witness> = require_complete_type %impl.elem1.ffc [symbolic]
// CHECK:STDOUT:   %tuple.type.79f: type = tuple_type (%impl.elem0.c83) [symbolic]
// CHECK:STDOUT:   %tuple.type.5cc: type = tuple_type (%impl.elem1.ffc) [symbolic]
// CHECK:STDOUT:   %.202: type = custom_layout_type {size=0, align=0, .Continue@0: %tuple.type.79f, .Break@0: %tuple.type.5cc} [symbolic]
// CHECK:STDOUT:   %.572: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.e24, %Try.facet.a01 [symbolic]
// CHECK:STDOUT:   %impl.elem3.092: %.572 = impl_witness_access %Try.lookup_impl_witness.669, element3 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.717: <specific function> = specific_impl_function %impl.elem3.092, @Try.WithSelf.FromBreak(%Try.facet.a01) [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.6a1: <witness> = lookup_impl_witness %ControlFlow.76f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.aae: %Destroy.type = facet_value %ControlFlow.76f, (%Destroy.lookup_impl_witness.6a1) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.3ae: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.aae) [symbolic]
// CHECK:STDOUT:   %.eb5: type = fn_type_with_self_type %Destroy.WithSelf.Op.type.3ae, %Destroy.facet.aae [symbolic]
// CHECK:STDOUT:   %impl.elem0.0fe: %.eb5 = impl_witness_access %Destroy.lookup_impl_witness.6a1, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.966: <specific function> = specific_impl_function %impl.elem0.0fe, @Destroy.WithSelf.Op(%Destroy.facet.aae) [symbolic]
// CHECK:STDOUT:   %Discard.specific_fn.e50: <specific function> = specific_function %Discard, @Discard(%impl.elem0.c83) [symbolic]
// CHECK:STDOUT:   %t.param_patt: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt: %pattern_type.51d1c4.1 = at_binding_pattern t, %t.param_patt [symbolic]
// CHECK:STDOUT:   %WidenedVar.type: type = fn_type @WidenedVar [concrete]
// CHECK:STDOUT:   %WidenedVar: %WidenedVar.type = struct_value () [concrete]
// CHECK:STDOUT:   %mr.patt.63f: %pattern_type.6db5df.1 = ref_binding_pattern mr [symbolic]
// CHECK:STDOUT:   %mr.var_patt: %pattern_type.6db5df.1 = var_pattern %mr.patt.63f [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn.1fe786.2: <specific function> = specific_function %MyResult.Ok.4604d7.1, @MyResult.Ok(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.61e: <witness> = lookup_impl_witness %MyResult.52ca24.1, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.510: %Destroy.type = facet_value %MyResult.52ca24.1, (%Destroy.lookup_impl_witness.61e) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.a70: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.510) [symbolic]
// CHECK:STDOUT:   %.713: type = fn_type_with_self_type %Destroy.WithSelf.Op.type.a70, %Destroy.facet.510 [symbolic]
// CHECK:STDOUT:   %impl.elem0.c14: %.713 = impl_witness_access %Destroy.lookup_impl_witness.61e, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.3fd: <specific function> = specific_impl_function %impl.elem0.c14, @Destroy.WithSelf.Op(%Destroy.facet.510) [symbolic]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %WidenedScrutinee.type: type = fn_type @WidenedScrutinee [concrete]
// CHECK:STDOUT:   %WidenedScrutinee: %WidenedScrutinee.type = struct_value () [concrete]
// CHECK:STDOUT:   %MyResult.f7e: type = class_type @MyResult, @MyResult(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %MakeMR.specific_fn: <specific function> = specific_function %MakeMR, @MakeMR(%T.67d, %i32) [symbolic]
// CHECK:STDOUT:   %.611: type = custom_layout_type {size=0, align=0, .Ok@0: %tuple.type.026b76.1, .Err@0: %tuple.type.a8a} [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.daf: <witness> = lookup_impl_witness %MyResult.f7e, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.2ac: %Destroy.type = facet_value %MyResult.f7e, (%Destroy.lookup_impl_witness.daf) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.533: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.2ac) [symbolic]
// CHECK:STDOUT:   %.51e: type = fn_type_with_self_type %Destroy.WithSelf.Op.type.533, %Destroy.facet.2ac [symbolic]
// CHECK:STDOUT:   %impl.elem0.e7e: %.51e = impl_witness_access %Destroy.lookup_impl_witness.daf, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.3e4: <specific function> = specific_impl_function %impl.elem0.e7e, @Destroy.WithSelf.Op(%Destroy.facet.2ac) [symbolic]
// CHECK:STDOUT:   %Discard.specific_fn.628: <specific function> = specific_function %Discard, @Discard(%T.67d) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %e.patt.2e6: %pattern_type.6b6 = value_binding_pattern e [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.37b: %pattern_type.e71 = tuple_pattern (%e.patt.2e6) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .UInt = %Core.UInt
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ControlFlow = %Core.ControlFlow
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Negate = %Core.Negate
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.UInt: %UInt.type = import_ref Core//prelude/types/uint, UInt, loaded [concrete = constants.%UInt.generic]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.import_ref.baf: %Try.assoc_type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = constants.%assoc0.de3]
// CHECK:STDOUT:   %Core.import_ref.814: %Try.assoc_type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = constants.%assoc1.f63]
// CHECK:STDOUT:   %Core.import_ref.8ab: %Try.assoc_type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = constants.%assoc3]
// CHECK:STDOUT:   %Core.import_ref.c56: type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = %ContinueType]
// CHECK:STDOUT:   %ContinueType: type = assoc_const_decl @ContinueType [concrete] {}
// CHECK:STDOUT:   %Core.import_ref.9a9: type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = %BreakType]
// CHECK:STDOUT:   %BreakType: type = assoc_const_decl @BreakType [concrete] {}
// CHECK:STDOUT:   %Core.ControlFlow: %ControlFlow.type = import_ref Core//prelude/try, ControlFlow, loaded [concrete = constants.%ControlFlow.generic]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.271: @Try.WithSelf.%Try.WithSelf.FromBreak.type (%Try.WithSelf.FromBreak.type.030) = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [symbolic = @Try.WithSelf.%Try.WithSelf.FromBreak (constants.%Try.WithSelf.FromBreak.e67)]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Negate: type = import_ref Core//prelude/operators/arithmetic, Negate, loaded [concrete = constants.%Negate.type]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %MyResult.Ok.decl: @MyResult.%MyResult.Ok.type (%MyResult.Ok.type.fd7821.1) = fn_decl @MyResult.Ok [symbolic = @MyResult.%MyResult.Ok (constants.%MyResult.Ok.4604d7.1)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.Err.decl: @MyResult.%MyResult.Err.type (%MyResult.Err.type.11093c.1) = fn_decl @MyResult.Err [symbolic = @MyResult.%MyResult.Err (constants.%MyResult.Err.899cd4.1)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %PropagateOnly.decl: %PropagateOnly.type = fn_decl @PropagateOnly [concrete = constants.%PropagateOnly] {
// CHECK:STDOUT:     %R.patt.loc58_19.1: %pattern_type.df6 = symbolic_binding_pattern R, 0 [symbolic = %R.patt.loc58_19.2 (constants.%R.patt)]
// CHECK:STDOUT:     %r.param_patt.loc58_55.1: @PropagateOnly.%pattern_type.loc58 (%pattern_type.239) = value_param_pattern [symbolic = %r.param_patt.loc58_55.2 (constants.%r.param_patt)]
// CHECK:STDOUT:     %r.patt.loc58_55.1: @PropagateOnly.%pattern_type.loc58 (%pattern_type.239) = at_binding_pattern r, %r.param_patt.loc58_55.1 [symbolic = %r.patt.loc58_55.2 (constants.%r.patt)]
// CHECK:STDOUT:     %return.param_patt.loc58_63.1: @PropagateOnly.%pattern_type.loc58 (%pattern_type.239) = out_param_pattern [symbolic = %return.param_patt.loc58_63.2 (constants.%return.param_patt.aed)]
// CHECK:STDOUT:     %return.patt.loc58_60.1: @PropagateOnly.%pattern_type.loc58 (%pattern_type.239) = return_slot_pattern %return.param_patt.loc58_63.1, %.loc58_63.4 [symbolic = %return.patt.loc58_60.2 (constants.%return.patt.0bca)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %R.ref.loc58_63: %Try_where.type.00c = name_ref R, %R.loc58_19.2 [symbolic = %R.loc58_19.1 (constants.%R)]
// CHECK:STDOUT:     %R.as_type.loc58_63: type = facet_access_type %R.ref.loc58_63 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     %.loc58_63.4: type = converted %R.ref.loc58_63, %R.as_type.loc58_63 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     %.loc58_63.5: Core.Form = init_form %.loc58_63.4 [symbolic = %.loc58_63.3 (constants.%.802)]
// CHECK:STDOUT:     %.loc58_30.1: type = splice_block %.loc58_30.2 [concrete = constants.%Try_where.type.00c] {
// CHECK:STDOUT:       %.Self.frozen.loc58_19: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Try.ref: type = name_ref Try, imports.%Core.Try [concrete = constants.%Try.type]
// CHECK:STDOUT:       %.Self.frozen.loc58_30: %Try.type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.5e9]
// CHECK:STDOUT:       %base_facet_type = requirement_base_facet_type %Try.ref [concrete]
// CHECK:STDOUT:       %.Self.ref: %Try.type = name_ref .Self, %.Self.frozen.loc58_30 [symbolic_self = constants.%.Self.frozen.5e9]
// CHECK:STDOUT:       %.Self.as_type: type = facet_access_type %.Self.ref [symbolic_self = constants.%.Self.frozen.as_type]
// CHECK:STDOUT:       %.loc58_36: type = converted %.Self.ref, %.Self.as_type [symbolic_self = constants.%.Self.frozen.as_type]
// CHECK:STDOUT:       %BreakType.ref: %Try.assoc_type = name_ref BreakType, imports.%Core.import_ref.814 [concrete = constants.%assoc1.f63]
// CHECK:STDOUT:       %impl.elem1.loc58_36.1: type = impl_witness_access constants.%Try.lookup_impl_witness.73a, element1 [symbolic_self = constants.%impl.elem1.660]
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %rewrite.loc58_47.1 = requirement_rewrite %impl.elem1.loc58_36.1, %i32 [concrete]
// CHECK:STDOUT:       %impl.elem1.loc58_36.2: type = impl_witness_access constants.%Try.lookup_impl_witness.775, element1 [symbolic_self = constants.%impl.elem1.d8a]
// CHECK:STDOUT:       %rewrite.loc58_47.2 = requirement_rewrite %impl.elem1.loc58_36.2, %i32 [concrete]
// CHECK:STDOUT:       %.loc58_30.2: type = where_expr [concrete = constants.%Try_where.type.00c] {
// CHECK:STDOUT:         %base_facet_type = requirement_base_facet_type %Try.ref [concrete]
// CHECK:STDOUT:         %rewrite.loc58_47.2 = requirement_rewrite %impl.elem1.loc58_36.2, %i32 [concrete]
// CHECK:STDOUT:       }
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %R.loc58_19.2: %Try_where.type.00c = symbolic_binding R, 0 [symbolic = %R.loc58_19.1 (constants.%R)]
// CHECK:STDOUT:     %r.param: @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) = value_param call_param0
// CHECK:STDOUT:     %.loc58_57.1: type = splice_block %.loc58_57.2 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)] {
// CHECK:STDOUT:       %R.ref.loc58_57: %Try_where.type.00c = name_ref R, %R.loc58_19.2 [symbolic = %R.loc58_19.1 (constants.%R)]
// CHECK:STDOUT:       %R.as_type.loc58_57.2: type = facet_access_type %R.ref.loc58_57 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:       %.loc58_57.2: type = converted %R.ref.loc58_57, %R.as_type.loc58_57.2 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %r: @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) = wrapper_binding r, %r.param
// CHECK:STDOUT:     %return.param: ref @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) = out_param call_param1
// CHECK:STDOUT:     %return: ref @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %PropagateChoice.decl: %PropagateChoice.type = fn_decl @PropagateChoice [concrete = constants.%PropagateChoice] {
// CHECK:STDOUT:     %T.patt.loc66_21.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc66_21.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:     %E.patt.loc66_30.1: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc66_30.2 (constants.%E.patt)]
// CHECK:STDOUT:     %mr.param_patt.loc66_40.1: @PropagateChoice.%pattern_type.loc66_40 (%pattern_type.6db5df.1) = value_param_pattern [symbolic = %mr.param_patt.loc66_40.2 (constants.%mr.param_patt)]
// CHECK:STDOUT:     %mr.patt.loc66_40.1: @PropagateChoice.%pattern_type.loc66_40 (%pattern_type.6db5df.1) = at_binding_pattern mr, %mr.param_patt.loc66_40.1 [symbolic = %mr.patt.loc66_40.2 (constants.%mr.patt.c42)]
// CHECK:STDOUT:     %e.param_patt.loc66_59.1: @PropagateChoice.%pattern_type.loc66_59 (%pattern_type.946bb9.1) = value_param_pattern [symbolic = %e.param_patt.loc66_59.2 (constants.%e.param_patt.92c2b1.1)]
// CHECK:STDOUT:     %e.patt.loc66_59.1: @PropagateChoice.%pattern_type.loc66_59 (%pattern_type.946bb9.1) = at_binding_pattern e, %e.param_patt.loc66_59.1 [symbolic = %e.patt.loc66_59.2 (constants.%e.patt.1c0fff.1)]
// CHECK:STDOUT:     %return.param_patt.loc67_21.1: @PropagateChoice.%pattern_type.loc66_40 (%pattern_type.6db5df.1) = out_param_pattern [symbolic = %return.param_patt.loc67_21.2 (constants.%return.param_patt.296c1c.1)]
// CHECK:STDOUT:     %return.patt.loc67_5.1: @PropagateChoice.%pattern_type.loc66_40 (%pattern_type.6db5df.1) = return_slot_pattern %return.param_patt.loc67_21.1, %MyResult.loc67 [symbolic = %return.patt.loc67_5.2 (constants.%return.patt.971efd.1)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc67: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %T.ref.loc67: type = name_ref T, %T.loc66_21.2 [symbolic = %T.loc66_21.1 (constants.%T.67d)]
// CHECK:STDOUT:     %E.ref.loc67: type = name_ref E, %E.loc66_30.2 [symbolic = %E.loc66_30.1 (constants.%E)]
// CHECK:STDOUT:     %MyResult.loc67: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc66_55.1 (constants.%MyResult.52ca24.1)]
// CHECK:STDOUT:     %.loc67_21.4: Core.Form = init_form %MyResult.loc67 [symbolic = %.loc67_21.3 (constants.%.6c705e.1)]
// CHECK:STDOUT:     %.loc66_23.1: type = splice_block %.loc66_23.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc66_21: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc66_23.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc66_21.2: type = symbolic_binding T, 0 [symbolic = %T.loc66_21.1 (constants.%T.67d)]
// CHECK:STDOUT:     %.loc66_32.1: type = splice_block %.loc66_32.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc66_30: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc66_32.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %E.loc66_30.2: type = symbolic_binding E, 1 [symbolic = %E.loc66_30.1 (constants.%E)]
// CHECK:STDOUT:     %mr.param: @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) = value_param call_param0
// CHECK:STDOUT:     %.loc66_55: type = splice_block %MyResult.loc66_55.2 [symbolic = %MyResult.loc66_55.1 (constants.%MyResult.52ca24.1)] {
// CHECK:STDOUT:       %MyResult.ref.loc66: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %T.ref.loc66: type = name_ref T, %T.loc66_21.2 [symbolic = %T.loc66_21.1 (constants.%T.67d)]
// CHECK:STDOUT:       %E.ref.loc66_54: type = name_ref E, %E.loc66_30.2 [symbolic = %E.loc66_30.1 (constants.%E)]
// CHECK:STDOUT:       %MyResult.loc66_55.2: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc66_55.1 (constants.%MyResult.52ca24.1)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %mr: @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) = wrapper_binding mr, %mr.param
// CHECK:STDOUT:     %e.param: @PropagateChoice.%E.loc66_30.1 (%E) = value_param call_param1
// CHECK:STDOUT:     %E.ref.loc66_61: type = name_ref E, %E.loc66_30.2 [symbolic = %E.loc66_30.1 (constants.%E)]
// CHECK:STDOUT:     %e: @PropagateChoice.%E.loc66_30.1 (%E) = wrapper_binding e, %e.param
// CHECK:STDOUT:     %return.param: ref @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) = out_param call_param2
// CHECK:STDOUT:     %return: ref @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %WidenedVar.decl: %WidenedVar.type = fn_decl @WidenedVar [concrete = constants.%WidenedVar] {
// CHECK:STDOUT:     %T.patt.loc90_16.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc90_16.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:     %E.patt.loc90_25.1: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc90_25.2 (constants.%E.patt)]
// CHECK:STDOUT:     %t.param_patt.loc90_34.1: @WidenedVar.%pattern_type.loc90_34 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %t.param_patt.loc90_34.2 (constants.%t.param_patt)]
// CHECK:STDOUT:     %t.patt.loc90_34.1: @WidenedVar.%pattern_type.loc90_34 (%pattern_type.51d1c4.1) = at_binding_pattern t, %t.param_patt.loc90_34.1 [symbolic = %t.patt.loc90_34.2 (constants.%t.patt)]
// CHECK:STDOUT:     %e.param_patt.loc90_47.1: @WidenedVar.%pattern_type.loc90_47 (%pattern_type.946bb9.1) = value_param_pattern [symbolic = %e.param_patt.loc90_47.2 (constants.%e.param_patt.92c2b1.1)]
// CHECK:STDOUT:     %e.patt.loc90_47.1: @WidenedVar.%pattern_type.loc90_47 (%pattern_type.946bb9.1) = at_binding_pattern e, %e.param_patt.loc90_47.1 [symbolic = %e.patt.loc90_47.2 (constants.%e.patt.1c0fff.1)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc90_18.1: type = splice_block %.loc90_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc90_16: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc90_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc90_16.2: type = symbolic_binding T, 0 [symbolic = %T.loc90_16.1 (constants.%T.67d)]
// CHECK:STDOUT:     %.loc90_27.1: type = splice_block %.loc90_27.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc90_25: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc90_27.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %E.loc90_25.2: type = symbolic_binding E, 1 [symbolic = %E.loc90_25.1 (constants.%E)]
// CHECK:STDOUT:     %t.param: @WidenedVar.%T.loc90_16.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc90: type = name_ref T, %T.loc90_16.2 [symbolic = %T.loc90_16.1 (constants.%T.67d)]
// CHECK:STDOUT:     %t: @WidenedVar.%T.loc90_16.1 (%T.67d) = wrapper_binding t, %t.param
// CHECK:STDOUT:     %e.param: @WidenedVar.%E.loc90_25.1 (%E) = value_param call_param1
// CHECK:STDOUT:     %E.ref.loc90: type = name_ref E, %E.loc90_25.2 [symbolic = %E.loc90_25.1 (constants.%E)]
// CHECK:STDOUT:     %e: @WidenedVar.%E.loc90_25.1 (%E) = wrapper_binding e, %e.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %WidenedScrutinee.decl: %WidenedScrutinee.type = fn_decl @WidenedScrutinee [concrete = constants.%WidenedScrutinee] {
// CHECK:STDOUT:     %T.patt.loc101_22.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc101_22.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:     %t.param_patt.loc101_31.1: @WidenedScrutinee.%pattern_type.loc101 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %t.param_patt.loc101_31.2 (constants.%t.param_patt)]
// CHECK:STDOUT:     %t.patt.loc101_31.1: @WidenedScrutinee.%pattern_type.loc101 (%pattern_type.51d1c4.1) = at_binding_pattern t, %t.param_patt.loc101_31.1 [symbolic = %t.patt.loc101_31.2 (constants.%t.patt)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc101 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc101: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc101_39: Core.Form = init_form %i32.loc101 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc101_24.1: type = splice_block %.loc101_24.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %.loc101_24.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc101_22.2: type = symbolic_binding T, 0 [symbolic = %T.loc101_22.1 (constants.%T.67d)]
// CHECK:STDOUT:     %t.param: @WidenedScrutinee.%T.loc101_22.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc101: type = name_ref T, %T.loc101_22.2 [symbolic = %T.loc101_22.1 (constants.%T.67d)]
// CHECK:STDOUT:     %t: @WidenedScrutinee.%T.loc101_22.1 (%T.67d) = wrapper_binding t, %t.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @PropagateOnly(%R.loc58_19.2: %Try_where.type.00c) {
// CHECK:STDOUT:   %R.patt.loc58_19.2: %pattern_type.df6 = symbolic_binding_pattern R, 0 [symbolic = %R.patt.loc58_19.2 (constants.%R.patt)]
// CHECK:STDOUT:   %R.loc58_19.1: %Try_where.type.00c = symbolic_binding R, 0 [symbolic = %R.loc58_19.1 (constants.%R)]
// CHECK:STDOUT:   %R.as_type.loc58_57.1: type = facet_access_type %R.loc58_19.1 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:   %pattern_type.loc58: type = pattern_type %R.as_type.loc58_57.1 [symbolic = %pattern_type.loc58 (constants.%pattern_type.239)]
// CHECK:STDOUT:   %r.param_patt.loc58_55.2: @PropagateOnly.%pattern_type.loc58 (%pattern_type.239) = value_param_pattern [symbolic = %r.param_patt.loc58_55.2 (constants.%r.param_patt)]
// CHECK:STDOUT:   %r.patt.loc58_55.2: @PropagateOnly.%pattern_type.loc58 (%pattern_type.239) = at_binding_pattern r, %r.param_patt.loc58_55.2 [symbolic = %r.patt.loc58_55.2 (constants.%r.patt)]
// CHECK:STDOUT:   %.loc58_63.3: Core.Form = init_form %R.as_type.loc58_57.1 [symbolic = %.loc58_63.3 (constants.%.802)]
// CHECK:STDOUT:   %return.param_patt.loc58_63.2: @PropagateOnly.%pattern_type.loc58 (%pattern_type.239) = out_param_pattern [symbolic = %return.param_patt.loc58_63.2 (constants.%return.param_patt.aed)]
// CHECK:STDOUT:   %return.patt.loc58_60.2: @PropagateOnly.%pattern_type.loc58 (%pattern_type.239) = return_slot_pattern %return.param_patt.loc58_63.2, %R.as_type.loc58_57.1 [symbolic = %return.patt.loc58_60.2 (constants.%return.patt.0bca)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc58: <witness> = require_complete_type %R.as_type.loc58_57.1 [symbolic = %require_complete.loc58 (constants.%require_complete.b5f)]
// CHECK:STDOUT:   %Try.lookup_impl_witness: <witness> = lookup_impl_witness %R.loc58_19.1, @Try [symbolic = %Try.lookup_impl_witness (constants.%Try.lookup_impl_witness.832)]
// CHECK:STDOUT:   %impl.elem0.loc59_18.2: type = impl_witness_access %Try.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc59_18.2 (constants.%impl.elem0.fca)]
// CHECK:STDOUT:   %require_complete.loc59: <witness> = require_complete_type %impl.elem0.loc59_18.2 [symbolic = %require_complete.loc59 (constants.%require_complete.677)]
// CHECK:STDOUT:   %pattern_type.loc59: type = pattern_type %impl.elem0.loc59_18.2 [symbolic = %pattern_type.loc59 (constants.%pattern_type.b1f)]
// CHECK:STDOUT:   %c.patt.loc59_15.2: @PropagateOnly.%pattern_type.loc59 (%pattern_type.b1f) = value_binding_pattern c [symbolic = %c.patt.loc59_15.2 (constants.%c.patt)]
// CHECK:STDOUT:   %Try.facet.loc59_35.4: %Try.type = facet_value %R.as_type.loc58_57.1, (%Try.lookup_impl_witness) [symbolic = %Try.facet.loc59_35.4 (constants.%Try.facet.1ad)]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.loc59_35.4) [symbolic = %Try.WithSelf.Branch.type (constants.%Try.WithSelf.Branch.type.ef1)]
// CHECK:STDOUT:   %.loc59_35.22: type = fn_type_with_self_type %Try.WithSelf.Branch.type, %Try.facet.loc59_35.4 [symbolic = %.loc59_35.22 (constants.%.392)]
// CHECK:STDOUT:   %impl.elem2.loc59_35.2: @PropagateOnly.%.loc59_35.22 (%.392) = impl_witness_access %Try.lookup_impl_witness, element2 [symbolic = %impl.elem2.loc59_35.2 (constants.%impl.elem2.f77)]
// CHECK:STDOUT:   %specific_impl_fn.loc59_35.5: <specific function> = specific_impl_function %impl.elem2.loc59_35.2, @Try.WithSelf.Branch(%Try.facet.loc59_35.4) [symbolic = %specific_impl_fn.loc59_35.5 (constants.%specific_impl_fn.8ea)]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%impl.elem0.loc59_18.2) [symbolic = %tuple.type (constants.%tuple.type.c39)]
// CHECK:STDOUT:   %.loc59_35.23: type = custom_layout_type {size=0, align=0, .Continue@0: @PropagateOnly.%tuple.type (%tuple.type.c39), .Break@0: %tuple.type.a8a} [symbolic = %.loc59_35.23 (constants.%.990)]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.loc59_35.4) [symbolic = %Try.WithSelf.FromBreak.type (constants.%Try.WithSelf.FromBreak.type.4c3)]
// CHECK:STDOUT:   %.loc59_35.24: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type, %Try.facet.loc59_35.4 [symbolic = %.loc59_35.24 (constants.%.287)]
// CHECK:STDOUT:   %impl.elem3.loc59_35.2: @PropagateOnly.%.loc59_35.24 (%.287) = impl_witness_access %Try.lookup_impl_witness, element3 [symbolic = %impl.elem3.loc59_35.2 (constants.%impl.elem3.d05)]
// CHECK:STDOUT:   %specific_impl_fn.loc59_35.6: <specific function> = specific_impl_function %impl.elem3.loc59_35.2, @Try.WithSelf.FromBreak(%Try.facet.loc59_35.4) [symbolic = %specific_impl_fn.loc59_35.6 (constants.%specific_impl_fn.9a1)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %ControlFlow, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.dc9)]
// CHECK:STDOUT:   %Destroy.facet.loc59_35.5: %Destroy.type = facet_value %ControlFlow, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc59_35.5 (constants.%Destroy.facet.a42)]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.loc59_35.5) [symbolic = %Destroy.WithSelf.Op.type (constants.%Destroy.WithSelf.Op.type.4a0)]
// CHECK:STDOUT:   %.loc59_35.25: type = fn_type_with_self_type %Destroy.WithSelf.Op.type, %Destroy.facet.loc59_35.5 [symbolic = %.loc59_35.25 (constants.%.425)]
// CHECK:STDOUT:   %impl.elem0.loc59_35.5: @PropagateOnly.%.loc59_35.25 (%.425) = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc59_35.5 (constants.%impl.elem0.324)]
// CHECK:STDOUT:   %specific_impl_fn.loc59_35.7: <specific function> = specific_impl_function %impl.elem0.loc59_35.5, @Destroy.WithSelf.Op(%Destroy.facet.loc59_35.5) [symbolic = %specific_impl_fn.loc59_35.7 (constants.%specific_impl_fn.92b)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%r.param: @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type)) -> out %return.param: @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %r.ref: @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) = name_ref r, %r
// CHECK:STDOUT:     %impl.elem2.loc59_35.1: @PropagateOnly.%.loc59_35.22 (%.392) = impl_witness_access constants.%Try.lookup_impl_witness.832, element2 [symbolic = %impl.elem2.loc59_35.2 (constants.%impl.elem2.f77)]
// CHECK:STDOUT:     %bound_method.loc59_35.1: <bound method> = bound_method %r.ref, %impl.elem2.loc59_35.1
// CHECK:STDOUT:     %Try.facet.loc59_35.1: %Try.type = facet_value constants.%R.as_type, (constants.%Try.lookup_impl_witness.832) [symbolic = %Try.facet.loc59_35.4 (constants.%Try.facet.1ad)]
// CHECK:STDOUT:     %.loc59_35.1: %Try.type = converted constants.%R.as_type, %Try.facet.loc59_35.1 [symbolic = %Try.facet.loc59_35.4 (constants.%Try.facet.1ad)]
// CHECK:STDOUT:     %Try.facet.loc59_35.2: %Try.type = facet_value constants.%R.as_type, (constants.%Try.lookup_impl_witness.832) [symbolic = %Try.facet.loc59_35.4 (constants.%Try.facet.1ad)]
// CHECK:STDOUT:     %.loc59_35.2: %Try.type = converted constants.%R.as_type, %Try.facet.loc59_35.2 [symbolic = %Try.facet.loc59_35.4 (constants.%Try.facet.1ad)]
// CHECK:STDOUT:     %specific_impl_fn.loc59_35.1: <specific function> = specific_impl_function %impl.elem2.loc59_35.1, @Try.WithSelf.Branch(constants.%Try.facet.1ad) [symbolic = %specific_impl_fn.loc59_35.5 (constants.%specific_impl_fn.8ea)]
// CHECK:STDOUT:     %bound_method.loc59_35.2: <bound method> = bound_method %r.ref, %specific_impl_fn.loc59_35.1
// CHECK:STDOUT:     %.loc59_35.3: ref @PropagateOnly.%ControlFlow (%ControlFlow.67f) = temporary_storage
// CHECK:STDOUT:     %Try.WithSelf.Branch.call: init @PropagateOnly.%ControlFlow (%ControlFlow.67f) to %.loc59_35.3 = call %bound_method.loc59_35.2(%r.ref)
// CHECK:STDOUT:     %.loc59_35.4: ref @PropagateOnly.%ControlFlow (%ControlFlow.67f) = temporary %.loc59_35.3, %Try.WithSelf.Branch.call
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc59_35.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc59_35.3: <bound method> = bound_method %int_1, %impl.elem0.loc59_35.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc59_35.1: <specific function> = specific_function %impl.elem0.loc59_35.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc59_35.4: <bound method> = bound_method %int_1, %specific_fn.loc59_35.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc59: init %u1 = call %bound_method.loc59_35.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc59_35.5: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc59 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc59_35.6: %u1 = converted %int_1, %.loc59_35.5 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc59_35.7: ref %u1 = class_element_access %.loc59_35.4, element0
// CHECK:STDOUT:     %impl.elem0.loc59_35.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc59_35.5: <bound method> = bound_method %.loc59_35.6, %impl.elem0.loc59_35.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:     %specific_fn.loc59_35.2: <specific function> = specific_function %impl.elem0.loc59_35.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc59_35.6: <bound method> = bound_method %.loc59_35.6, %specific_fn.loc59_35.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc59_35.8: %u1 = acquire_value %.loc59_35.7
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc59_35.6(%.loc59_35.6, %.loc59_35.8)
// CHECK:STDOUT:     %.loc59_35.9: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:     %.loc59_35.10: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc59_35.9
// CHECK:STDOUT:     if %.loc59_35.10 br !.loc59_35.1 else br !.loc59_35.2
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc59_35.1:
// CHECK:STDOUT:     %.loc59_35.11: ref @PropagateOnly.%.loc59_35.23 (%.990) = class_element_access %.loc59_35.4, element1
// CHECK:STDOUT:     %.loc59_35.12: ref %tuple.type.a8a = class_element_access %.loc59_35.11, element1
// CHECK:STDOUT:     %tuple.elem0.loc59_35.1: ref %i32 = tuple_access %.loc59_35.12, element0
// CHECK:STDOUT:     %.loc59_35.13: %i32 = acquire_value %tuple.elem0.loc59_35.1
// CHECK:STDOUT:     %Try.facet.loc59_35.3: %Try.type = facet_value constants.%R.as_type, (constants.%Try.lookup_impl_witness.832) [symbolic = %Try.facet.loc59_35.4 (constants.%Try.facet.1ad)]
// CHECK:STDOUT:     %.loc59_35.14: %Try.type = converted constants.%R.as_type, %Try.facet.loc59_35.3 [symbolic = %Try.facet.loc59_35.4 (constants.%Try.facet.1ad)]
// CHECK:STDOUT:     %impl.elem3.loc59_35.1: @PropagateOnly.%.loc59_35.24 (%.287) = impl_witness_access constants.%Try.lookup_impl_witness.832, element3 [symbolic = %impl.elem3.loc59_35.2 (constants.%impl.elem3.d05)]
// CHECK:STDOUT:     %specific_impl_fn.loc59_35.2: <specific function> = specific_impl_function %impl.elem3.loc59_35.1, @Try.WithSelf.FromBreak(constants.%Try.facet.1ad) [symbolic = %specific_impl_fn.loc59_35.6 (constants.%specific_impl_fn.9a1)]
// CHECK:STDOUT:     %.loc58_63.1: ref @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) = splice_block %return.param {}
// CHECK:STDOUT:     %Try.WithSelf.FromBreak.call.loc59: init @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) to %.loc58_63.1 = call %specific_impl_fn.loc59_35.2(%.loc59_35.13)
// CHECK:STDOUT:     %impl.elem0.loc59_35.3: @PropagateOnly.%.loc59_35.25 (%.425) = impl_witness_access constants.%Destroy.lookup_impl_witness.dc9, element0 [symbolic = %impl.elem0.loc59_35.5 (constants.%impl.elem0.324)]
// CHECK:STDOUT:     %bound_method.loc59_35.7: <bound method> = bound_method %.loc59_35.4, %impl.elem0.loc59_35.3
// CHECK:STDOUT:     %Destroy.facet.loc59_35.1: %Destroy.type = facet_value constants.%ControlFlow.67f, (constants.%Destroy.lookup_impl_witness.dc9) [symbolic = %Destroy.facet.loc59_35.5 (constants.%Destroy.facet.a42)]
// CHECK:STDOUT:     %.loc59_35.15: %Destroy.type = converted constants.%ControlFlow.67f, %Destroy.facet.loc59_35.1 [symbolic = %Destroy.facet.loc59_35.5 (constants.%Destroy.facet.a42)]
// CHECK:STDOUT:     %Destroy.facet.loc59_35.2: %Destroy.type = facet_value constants.%ControlFlow.67f, (constants.%Destroy.lookup_impl_witness.dc9) [symbolic = %Destroy.facet.loc59_35.5 (constants.%Destroy.facet.a42)]
// CHECK:STDOUT:     %.loc59_35.16: %Destroy.type = converted constants.%ControlFlow.67f, %Destroy.facet.loc59_35.2 [symbolic = %Destroy.facet.loc59_35.5 (constants.%Destroy.facet.a42)]
// CHECK:STDOUT:     %specific_impl_fn.loc59_35.3: <specific function> = specific_impl_function %impl.elem0.loc59_35.3, @Destroy.WithSelf.Op(constants.%Destroy.facet.a42) [symbolic = %specific_impl_fn.loc59_35.7 (constants.%specific_impl_fn.92b)]
// CHECK:STDOUT:     %bound_method.loc59_35.8: <bound method> = bound_method %.loc59_35.4, %specific_impl_fn.loc59_35.3
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc59_35.1: init %empty_tuple.type = call %bound_method.loc59_35.8(%.loc59_35.4)
// CHECK:STDOUT:     return %Try.WithSelf.FromBreak.call.loc59 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc59_35.2:
// CHECK:STDOUT:     %.loc59_35.17: ref @PropagateOnly.%.loc59_35.23 (%.990) = class_element_access %.loc59_35.4, element1
// CHECK:STDOUT:     %.loc59_35.18: ref @PropagateOnly.%tuple.type (%tuple.type.c39) = class_element_access %.loc59_35.17, element0
// CHECK:STDOUT:     %tuple.elem0.loc59_35.2: ref @PropagateOnly.%impl.elem0.loc59_18.2 (%impl.elem0.fca) = tuple_access %.loc59_35.18, element0
// CHECK:STDOUT:     %.loc59_35.19: @PropagateOnly.%impl.elem0.loc59_18.2 (%impl.elem0.fca) = acquire_value %tuple.elem0.loc59_35.2
// CHECK:STDOUT:     %.loc59_18.1: type = splice_block %impl.elem0.loc59_18.1 [symbolic = %impl.elem0.loc59_18.2 (constants.%impl.elem0.fca)] {
// CHECK:STDOUT:       %R.ref.loc59: %Try_where.type.00c = name_ref R, %R.loc58_19.2 [symbolic = %R.loc58_19.1 (constants.%R)]
// CHECK:STDOUT:       %R.as_type.loc59: type = facet_access_type %R.ref.loc59 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:       %.loc59_18.2: type = converted %R.ref.loc59, %R.as_type.loc59 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:       %ContinueType.ref: %Try.assoc_type = name_ref ContinueType, imports.%Core.import_ref.baf [concrete = constants.%assoc0.de3]
// CHECK:STDOUT:       %impl.elem0.loc59_18.1: type = impl_witness_access constants.%Try.lookup_impl_witness.832, element0 [symbolic = %impl.elem0.loc59_18.2 (constants.%impl.elem0.fca)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %c: @PropagateOnly.%impl.elem0.loc59_18.2 (%impl.elem0.fca) = wrapper_binding c, %.loc59_35.19
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %c.patt.loc59_15.1: @PropagateOnly.%pattern_type.loc59 (%pattern_type.b1f) = value_binding_pattern c [symbolic = %c.patt.loc59_15.2 (constants.%c.patt)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %R.ref.loc60: %Try_where.type.00c = name_ref R, %R.loc58_19.2 [symbolic = %R.loc58_19.1 (constants.%R)]
// CHECK:STDOUT:     %R.as_type.loc60: type = facet_access_type %R.ref.loc60 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     %.loc60_11: type = converted %R.ref.loc60, %R.as_type.loc60 [symbolic = %R.as_type.loc58_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     %FromBreak.ref: %Try.assoc_type = name_ref FromBreak, imports.%Core.import_ref.8ab [concrete = constants.%assoc3]
// CHECK:STDOUT:     %impl.elem3.loc60: @PropagateOnly.%.loc59_35.24 (%.287) = impl_witness_access constants.%Try.lookup_impl_witness.832, element3 [symbolic = %impl.elem3.loc59_35.2 (constants.%impl.elem3.d05)]
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %specific_impl_fn.loc60: <specific function> = specific_impl_function %impl.elem3.loc60, @Try.WithSelf.FromBreak(constants.%Try.facet.1ad) [symbolic = %specific_impl_fn.loc59_35.6 (constants.%specific_impl_fn.9a1)]
// CHECK:STDOUT:     %.loc58_63.2: ref @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) = splice_block %return.param {}
// CHECK:STDOUT:     %impl.elem0.loc60: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc60_22.1: <bound method> = bound_method %int_0, %impl.elem0.loc60 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc60: <specific function> = specific_function %impl.elem0.loc60, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc60_22.2: <bound method> = bound_method %int_0, %specific_fn.loc60 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc60: init %i32 = call %bound_method.loc60_22.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc60_22.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc60 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc60_22.2: %i32 = converted %int_0, %.loc60_22.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %Try.WithSelf.FromBreak.call.loc60: init @PropagateOnly.%R.as_type.loc58_57.1 (%R.as_type) to %.loc58_63.2 = call %specific_impl_fn.loc60(%.loc60_22.2)
// CHECK:STDOUT:     %impl.elem0.loc59_35.4: @PropagateOnly.%.loc59_35.25 (%.425) = impl_witness_access constants.%Destroy.lookup_impl_witness.dc9, element0 [symbolic = %impl.elem0.loc59_35.5 (constants.%impl.elem0.324)]
// CHECK:STDOUT:     %bound_method.loc59_35.9: <bound method> = bound_method %.loc59_35.4, %impl.elem0.loc59_35.4
// CHECK:STDOUT:     %Destroy.facet.loc59_35.3: %Destroy.type = facet_value constants.%ControlFlow.67f, (constants.%Destroy.lookup_impl_witness.dc9) [symbolic = %Destroy.facet.loc59_35.5 (constants.%Destroy.facet.a42)]
// CHECK:STDOUT:     %.loc59_35.20: %Destroy.type = converted constants.%ControlFlow.67f, %Destroy.facet.loc59_35.3 [symbolic = %Destroy.facet.loc59_35.5 (constants.%Destroy.facet.a42)]
// CHECK:STDOUT:     %Destroy.facet.loc59_35.4: %Destroy.type = facet_value constants.%ControlFlow.67f, (constants.%Destroy.lookup_impl_witness.dc9) [symbolic = %Destroy.facet.loc59_35.5 (constants.%Destroy.facet.a42)]
// CHECK:STDOUT:     %.loc59_35.21: %Destroy.type = converted constants.%ControlFlow.67f, %Destroy.facet.loc59_35.4 [symbolic = %Destroy.facet.loc59_35.5 (constants.%Destroy.facet.a42)]
// CHECK:STDOUT:     %specific_impl_fn.loc59_35.4: <specific function> = specific_impl_function %impl.elem0.loc59_35.4, @Destroy.WithSelf.Op(constants.%Destroy.facet.a42) [symbolic = %specific_impl_fn.loc59_35.7 (constants.%specific_impl_fn.92b)]
// CHECK:STDOUT:     %bound_method.loc59_35.10: <bound method> = bound_method %.loc59_35.4, %specific_impl_fn.loc59_35.4
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc59_35.2: init %empty_tuple.type = call %bound_method.loc59_35.10(%.loc59_35.4)
// CHECK:STDOUT:     return %Try.WithSelf.FromBreak.call.loc60 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @PropagateChoice(%T.loc66_21.2: type, %E.loc66_30.2: type) {
// CHECK:STDOUT:   %T.patt.loc66_21.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc66_21.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc66_21.1: type = symbolic_binding T, 0 [symbolic = %T.loc66_21.1 (constants.%T.67d)]
// CHECK:STDOUT:   %E.patt.loc66_30.2: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc66_30.2 (constants.%E.patt)]
// CHECK:STDOUT:   %E.loc66_30.1: type = symbolic_binding E, 1 [symbolic = %E.loc66_30.1 (constants.%E)]
// CHECK:STDOUT:   %MyResult.loc66_55.1: type = class_type @MyResult, @MyResult(%T.loc66_21.1, %E.loc66_30.1) [symbolic = %MyResult.loc66_55.1 (constants.%MyResult.52ca24.1)]
// CHECK:STDOUT:   %pattern_type.loc66_40: type = pattern_type %MyResult.loc66_55.1 [symbolic = %pattern_type.loc66_40 (constants.%pattern_type.6db5df.1)]
// CHECK:STDOUT:   %mr.param_patt.loc66_40.2: @PropagateChoice.%pattern_type.loc66_40 (%pattern_type.6db5df.1) = value_param_pattern [symbolic = %mr.param_patt.loc66_40.2 (constants.%mr.param_patt)]
// CHECK:STDOUT:   %mr.patt.loc66_40.2: @PropagateChoice.%pattern_type.loc66_40 (%pattern_type.6db5df.1) = at_binding_pattern mr, %mr.param_patt.loc66_40.2 [symbolic = %mr.patt.loc66_40.2 (constants.%mr.patt.c42)]
// CHECK:STDOUT:   %pattern_type.loc66_59: type = pattern_type %E.loc66_30.1 [symbolic = %pattern_type.loc66_59 (constants.%pattern_type.946bb9.1)]
// CHECK:STDOUT:   %e.param_patt.loc66_59.2: @PropagateChoice.%pattern_type.loc66_59 (%pattern_type.946bb9.1) = value_param_pattern [symbolic = %e.param_patt.loc66_59.2 (constants.%e.param_patt.92c2b1.1)]
// CHECK:STDOUT:   %e.patt.loc66_59.2: @PropagateChoice.%pattern_type.loc66_59 (%pattern_type.946bb9.1) = at_binding_pattern e, %e.param_patt.loc66_59.2 [symbolic = %e.patt.loc66_59.2 (constants.%e.patt.1c0fff.1)]
// CHECK:STDOUT:   %.loc67_21.3: Core.Form = init_form %MyResult.loc66_55.1 [symbolic = %.loc67_21.3 (constants.%.6c705e.1)]
// CHECK:STDOUT:   %return.param_patt.loc67_21.2: @PropagateChoice.%pattern_type.loc66_40 (%pattern_type.6db5df.1) = out_param_pattern [symbolic = %return.param_patt.loc67_21.2 (constants.%return.param_patt.296c1c.1)]
// CHECK:STDOUT:   %return.patt.loc67_5.2: @PropagateChoice.%pattern_type.loc66_40 (%pattern_type.6db5df.1) = return_slot_pattern %return.param_patt.loc67_21.2, %MyResult.loc66_55.1 [symbolic = %return.patt.loc67_5.2 (constants.%return.patt.971efd.1)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc66_40: <witness> = require_complete_type %MyResult.loc66_55.1 [symbolic = %require_complete.loc66_40 (constants.%require_complete.090415.1)]
// CHECK:STDOUT:   %require_complete.loc66_59: <witness> = require_complete_type %E.loc66_30.1 [symbolic = %require_complete.loc66_59 (constants.%require_complete.441886.1)]
// CHECK:STDOUT:   %.loc82_13.22: require_specific_def_type = require_specific_def @MyResult.as.Try.impl(%T.loc66_21.1, %E.loc66_30.1) [symbolic = %.loc82_13.22 (constants.%.fa0)]
// CHECK:STDOUT:   %Try.lookup_impl_witness: <witness> = lookup_impl_witness %MyResult.loc66_55.1, @Try [symbolic = %Try.lookup_impl_witness (constants.%Try.lookup_impl_witness.669)]
// CHECK:STDOUT:   %Try.facet.loc82_13.4: %Try.type = facet_value %MyResult.loc66_55.1, (%Try.lookup_impl_witness) [symbolic = %Try.facet.loc82_13.4 (constants.%Try.facet.a01)]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.loc82_13.4) [symbolic = %Try.WithSelf.Branch.type (constants.%Try.WithSelf.Branch.type.a69)]
// CHECK:STDOUT:   %.loc82_13.23: type = fn_type_with_self_type %Try.WithSelf.Branch.type, %Try.facet.loc82_13.4 [symbolic = %.loc82_13.23 (constants.%.7bc)]
// CHECK:STDOUT:   %impl.elem2.loc82_13.2: @PropagateChoice.%.loc82_13.23 (%.7bc) = impl_witness_access %Try.lookup_impl_witness, element2 [symbolic = %impl.elem2.loc82_13.2 (constants.%impl.elem2.1c7)]
// CHECK:STDOUT:   %specific_impl_fn.loc82_13.5: <specific function> = specific_impl_function %impl.elem2.loc82_13.2, @Try.WithSelf.Branch(%Try.facet.loc82_13.4) [symbolic = %specific_impl_fn.loc82_13.5 (constants.%specific_impl_fn.acd)]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %tuple.type.loc82_13.1: type = tuple_type (%impl.elem0.1) [symbolic = %tuple.type.loc82_13.1 (constants.%tuple.type.79f)]
// CHECK:STDOUT:   %tuple.type.loc82_13.2: type = tuple_type (%impl.elem1) [symbolic = %tuple.type.loc82_13.2 (constants.%tuple.type.5cc)]
// CHECK:STDOUT:   %.loc82_13.24: type = custom_layout_type {size=0, align=0, .Continue@0: @PropagateChoice.%tuple.type.loc82_13.1 (%tuple.type.79f), .Break@0: @PropagateChoice.%tuple.type.loc82_13.2 (%tuple.type.5cc)} [symbolic = %.loc82_13.24 (constants.%.202)]
// CHECK:STDOUT:   %require_complete.loc82_13.1: <witness> = require_complete_type %impl.elem1 [symbolic = %require_complete.loc82_13.1 (constants.%require_complete.faf)]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.loc82_13.4) [symbolic = %Try.WithSelf.FromBreak.type (constants.%Try.WithSelf.FromBreak.type.e24)]
// CHECK:STDOUT:   %.loc82_13.25: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type, %Try.facet.loc82_13.4 [symbolic = %.loc82_13.25 (constants.%.572)]
// CHECK:STDOUT:   %impl.elem3.loc82_13.2: @PropagateChoice.%.loc82_13.25 (%.572) = impl_witness_access %Try.lookup_impl_witness, element3 [symbolic = %impl.elem3.loc82_13.2 (constants.%impl.elem3.092)]
// CHECK:STDOUT:   %specific_impl_fn.loc82_13.6: <specific function> = specific_impl_function %impl.elem3.loc82_13.2, @Try.WithSelf.FromBreak(%Try.facet.loc82_13.4) [symbolic = %specific_impl_fn.loc82_13.6 (constants.%specific_impl_fn.717)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %ControlFlow, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.6a1)]
// CHECK:STDOUT:   %Destroy.facet.loc82_13.5: %Destroy.type = facet_value %ControlFlow, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc82_13.5 (constants.%Destroy.facet.aae)]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.loc82_13.5) [symbolic = %Destroy.WithSelf.Op.type (constants.%Destroy.WithSelf.Op.type.3ae)]
// CHECK:STDOUT:   %.loc82_13.26: type = fn_type_with_self_type %Destroy.WithSelf.Op.type, %Destroy.facet.loc82_13.5 [symbolic = %.loc82_13.26 (constants.%.eb5)]
// CHECK:STDOUT:   %impl.elem0.loc82_13.5: @PropagateChoice.%.loc82_13.26 (%.eb5) = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc82_13.5 (constants.%impl.elem0.0fe)]
// CHECK:STDOUT:   %specific_impl_fn.loc82_13.7: <specific function> = specific_impl_function %impl.elem0.loc82_13.5, @Destroy.WithSelf.Op(%Destroy.facet.loc82_13.5) [symbolic = %specific_impl_fn.loc82_13.7 (constants.%specific_impl_fn.966)]
// CHECK:STDOUT:   %require_complete.loc82_13.2: <witness> = require_complete_type %impl.elem0.1 [symbolic = %require_complete.loc82_13.2 (constants.%require_complete.3f5)]
// CHECK:STDOUT:   %Discard.specific_fn.loc82_3.2: <specific function> = specific_function constants.%Discard, @Discard(%impl.elem0.1) [symbolic = %Discard.specific_fn.loc82_3.2 (constants.%Discard.specific_fn.e50)]
// CHECK:STDOUT:   %MyResult.Err.type: type = fn_type @MyResult.Err, @MyResult(%T.loc66_21.1, %E.loc66_30.1) [symbolic = %MyResult.Err.type (constants.%MyResult.Err.type.11093c.1)]
// CHECK:STDOUT:   %MyResult.Err: @PropagateChoice.%MyResult.Err.type (%MyResult.Err.type.11093c.1) = struct_value () [symbolic = %MyResult.Err (constants.%MyResult.Err.899cd4.1)]
// CHECK:STDOUT:   %MyResult.Err.specific_fn.loc83_24.2: <specific function> = specific_function %MyResult.Err, @MyResult.Err(%T.loc66_21.1, %E.loc66_30.1) [symbolic = %MyResult.Err.specific_fn.loc83_24.2 (constants.%MyResult.Err.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%mr.param: @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1), %e.param: @PropagateChoice.%E.loc66_30.1 (%E)) -> out %return.param: @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Discard.ref: %Discard.type = name_ref Discard, file.%Discard.decl [concrete = constants.%Discard]
// CHECK:STDOUT:     %mr.ref: @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) = name_ref mr, %mr
// CHECK:STDOUT:     %impl.elem2.loc82_13.1: @PropagateChoice.%.loc82_13.23 (%.7bc) = impl_witness_access constants.%Try.lookup_impl_witness.669, element2 [symbolic = %impl.elem2.loc82_13.2 (constants.%impl.elem2.1c7)]
// CHECK:STDOUT:     %bound_method.loc82_13.1: <bound method> = bound_method %mr.ref, %impl.elem2.loc82_13.1
// CHECK:STDOUT:     %Try.facet.loc82_13.1: %Try.type = facet_value constants.%MyResult.52ca24.1, (constants.%Try.lookup_impl_witness.669) [symbolic = %Try.facet.loc82_13.4 (constants.%Try.facet.a01)]
// CHECK:STDOUT:     %.loc82_13.1: %Try.type = converted constants.%MyResult.52ca24.1, %Try.facet.loc82_13.1 [symbolic = %Try.facet.loc82_13.4 (constants.%Try.facet.a01)]
// CHECK:STDOUT:     %Try.facet.loc82_13.2: %Try.type = facet_value constants.%MyResult.52ca24.1, (constants.%Try.lookup_impl_witness.669) [symbolic = %Try.facet.loc82_13.4 (constants.%Try.facet.a01)]
// CHECK:STDOUT:     %.loc82_13.2: %Try.type = converted constants.%MyResult.52ca24.1, %Try.facet.loc82_13.2 [symbolic = %Try.facet.loc82_13.4 (constants.%Try.facet.a01)]
// CHECK:STDOUT:     %specific_impl_fn.loc82_13.1: <specific function> = specific_impl_function %impl.elem2.loc82_13.1, @Try.WithSelf.Branch(constants.%Try.facet.a01) [symbolic = %specific_impl_fn.loc82_13.5 (constants.%specific_impl_fn.acd)]
// CHECK:STDOUT:     %bound_method.loc82_13.2: <bound method> = bound_method %mr.ref, %specific_impl_fn.loc82_13.1
// CHECK:STDOUT:     %.loc82_13.3: ref @PropagateChoice.%ControlFlow (%ControlFlow.76f) = temporary_storage
// CHECK:STDOUT:     %Try.WithSelf.Branch.call: init @PropagateChoice.%ControlFlow (%ControlFlow.76f) to %.loc82_13.3 = call %bound_method.loc82_13.2(%mr.ref)
// CHECK:STDOUT:     %.loc82_13.4: ref @PropagateChoice.%ControlFlow (%ControlFlow.76f) = temporary %.loc82_13.3, %Try.WithSelf.Branch.call
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc82_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc82_13.3: <bound method> = bound_method %int_1, %impl.elem0.loc82_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc82_13.1: <specific function> = specific_function %impl.elem0.loc82_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc82_13.4: <bound method> = bound_method %int_1, %specific_fn.loc82_13.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc82_13.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc82_13.5: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc82_13.6: %u1 = converted %int_1, %.loc82_13.5 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc82_13.7: ref %u1 = class_element_access %.loc82_13.4, element0
// CHECK:STDOUT:     %impl.elem0.loc82_13.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc82_13.5: <bound method> = bound_method %.loc82_13.6, %impl.elem0.loc82_13.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:     %specific_fn.loc82_13.2: <specific function> = specific_function %impl.elem0.loc82_13.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc82_13.6: <bound method> = bound_method %.loc82_13.6, %specific_fn.loc82_13.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc82_13.8: %u1 = acquire_value %.loc82_13.7
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc82_13.6(%.loc82_13.6, %.loc82_13.8)
// CHECK:STDOUT:     %.loc82_13.9: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:     %.loc82_13.10: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc82_13.9
// CHECK:STDOUT:     if %.loc82_13.10 br !.loc82_13.1 else br !.loc82_13.2
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc82_13.1:
// CHECK:STDOUT:     %.loc82_13.11: ref @PropagateChoice.%.loc82_13.24 (%.202) = class_element_access %.loc82_13.4, element1
// CHECK:STDOUT:     %.loc82_13.12: ref @PropagateChoice.%tuple.type.loc82_13.2 (%tuple.type.5cc) = class_element_access %.loc82_13.11, element1
// CHECK:STDOUT:     %tuple.elem0.loc82_13.1: ref @PropagateChoice.%impl.elem1 (%impl.elem1.ffc) = tuple_access %.loc82_13.12, element0
// CHECK:STDOUT:     %.loc82_13.13: @PropagateChoice.%impl.elem1 (%impl.elem1.ffc) = acquire_value %tuple.elem0.loc82_13.1
// CHECK:STDOUT:     %Try.facet.loc82_13.3: %Try.type = facet_value constants.%MyResult.52ca24.1, (constants.%Try.lookup_impl_witness.669) [symbolic = %Try.facet.loc82_13.4 (constants.%Try.facet.a01)]
// CHECK:STDOUT:     %.loc82_13.14: %Try.type = converted constants.%MyResult.52ca24.1, %Try.facet.loc82_13.3 [symbolic = %Try.facet.loc82_13.4 (constants.%Try.facet.a01)]
// CHECK:STDOUT:     %impl.elem3.loc82_13.1: @PropagateChoice.%.loc82_13.25 (%.572) = impl_witness_access constants.%Try.lookup_impl_witness.669, element3 [symbolic = %impl.elem3.loc82_13.2 (constants.%impl.elem3.092)]
// CHECK:STDOUT:     %specific_impl_fn.loc82_13.2: <specific function> = specific_impl_function %impl.elem3.loc82_13.1, @Try.WithSelf.FromBreak(constants.%Try.facet.a01) [symbolic = %specific_impl_fn.loc82_13.6 (constants.%specific_impl_fn.717)]
// CHECK:STDOUT:     %.loc67_21.1: ref @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) = splice_block %return.param {}
// CHECK:STDOUT:     %Try.WithSelf.FromBreak.call: init @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) to %.loc67_21.1 = call %specific_impl_fn.loc82_13.2(%.loc82_13.13)
// CHECK:STDOUT:     %impl.elem0.loc82_13.3: @PropagateChoice.%.loc82_13.26 (%.eb5) = impl_witness_access constants.%Destroy.lookup_impl_witness.6a1, element0 [symbolic = %impl.elem0.loc82_13.5 (constants.%impl.elem0.0fe)]
// CHECK:STDOUT:     %bound_method.loc82_13.7: <bound method> = bound_method %.loc82_13.4, %impl.elem0.loc82_13.3
// CHECK:STDOUT:     %Destroy.facet.loc82_13.1: %Destroy.type = facet_value constants.%ControlFlow.76f, (constants.%Destroy.lookup_impl_witness.6a1) [symbolic = %Destroy.facet.loc82_13.5 (constants.%Destroy.facet.aae)]
// CHECK:STDOUT:     %.loc82_13.15: %Destroy.type = converted constants.%ControlFlow.76f, %Destroy.facet.loc82_13.1 [symbolic = %Destroy.facet.loc82_13.5 (constants.%Destroy.facet.aae)]
// CHECK:STDOUT:     %Destroy.facet.loc82_13.2: %Destroy.type = facet_value constants.%ControlFlow.76f, (constants.%Destroy.lookup_impl_witness.6a1) [symbolic = %Destroy.facet.loc82_13.5 (constants.%Destroy.facet.aae)]
// CHECK:STDOUT:     %.loc82_13.16: %Destroy.type = converted constants.%ControlFlow.76f, %Destroy.facet.loc82_13.2 [symbolic = %Destroy.facet.loc82_13.5 (constants.%Destroy.facet.aae)]
// CHECK:STDOUT:     %specific_impl_fn.loc82_13.3: <specific function> = specific_impl_function %impl.elem0.loc82_13.3, @Destroy.WithSelf.Op(constants.%Destroy.facet.aae) [symbolic = %specific_impl_fn.loc82_13.7 (constants.%specific_impl_fn.966)]
// CHECK:STDOUT:     %bound_method.loc82_13.8: <bound method> = bound_method %.loc82_13.4, %specific_impl_fn.loc82_13.3
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc82_13.1: init %empty_tuple.type = call %bound_method.loc82_13.8(%.loc82_13.4)
// CHECK:STDOUT:     return %Try.WithSelf.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc82_13.2:
// CHECK:STDOUT:     %.loc82_13.17: ref @PropagateChoice.%.loc82_13.24 (%.202) = class_element_access %.loc82_13.4, element1
// CHECK:STDOUT:     %.loc82_13.18: ref @PropagateChoice.%tuple.type.loc82_13.1 (%tuple.type.79f) = class_element_access %.loc82_13.17, element0
// CHECK:STDOUT:     %tuple.elem0.loc82_13.2: ref @PropagateChoice.%impl.elem0.1 (%impl.elem0.c83) = tuple_access %.loc82_13.18, element0
// CHECK:STDOUT:     %.loc82_13.19: @PropagateChoice.%impl.elem0.1 (%impl.elem0.c83) = acquire_value %tuple.elem0.loc82_13.2
// CHECK:STDOUT:     %Discard.specific_fn.loc82_3.1: <specific function> = specific_function %Discard.ref, @Discard(constants.%impl.elem0.c83) [symbolic = %Discard.specific_fn.loc82_3.2 (constants.%Discard.specific_fn.e50)]
// CHECK:STDOUT:     %Discard.call: init %empty_tuple.type = call %Discard.specific_fn.loc82_3.1(%.loc82_13.19)
// CHECK:STDOUT:     %impl.elem0.loc82_13.4: @PropagateChoice.%.loc82_13.26 (%.eb5) = impl_witness_access constants.%Destroy.lookup_impl_witness.6a1, element0 [symbolic = %impl.elem0.loc82_13.5 (constants.%impl.elem0.0fe)]
// CHECK:STDOUT:     %bound_method.loc82_13.9: <bound method> = bound_method %.loc82_13.4, %impl.elem0.loc82_13.4
// CHECK:STDOUT:     %Destroy.facet.loc82_13.3: %Destroy.type = facet_value constants.%ControlFlow.76f, (constants.%Destroy.lookup_impl_witness.6a1) [symbolic = %Destroy.facet.loc82_13.5 (constants.%Destroy.facet.aae)]
// CHECK:STDOUT:     %.loc82_13.20: %Destroy.type = converted constants.%ControlFlow.76f, %Destroy.facet.loc82_13.3 [symbolic = %Destroy.facet.loc82_13.5 (constants.%Destroy.facet.aae)]
// CHECK:STDOUT:     %Destroy.facet.loc82_13.4: %Destroy.type = facet_value constants.%ControlFlow.76f, (constants.%Destroy.lookup_impl_witness.6a1) [symbolic = %Destroy.facet.loc82_13.5 (constants.%Destroy.facet.aae)]
// CHECK:STDOUT:     %.loc82_13.21: %Destroy.type = converted constants.%ControlFlow.76f, %Destroy.facet.loc82_13.4 [symbolic = %Destroy.facet.loc82_13.5 (constants.%Destroy.facet.aae)]
// CHECK:STDOUT:     %specific_impl_fn.loc82_13.4: <specific function> = specific_impl_function %impl.elem0.loc82_13.4, @Destroy.WithSelf.Op(constants.%Destroy.facet.aae) [symbolic = %specific_impl_fn.loc82_13.7 (constants.%specific_impl_fn.966)]
// CHECK:STDOUT:     %bound_method.loc82_13.10: <bound method> = bound_method %.loc82_13.4, %specific_impl_fn.loc82_13.4
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call.loc82_13.2: init %empty_tuple.type = call %bound_method.loc82_13.10(%.loc82_13.4)
// CHECK:STDOUT:     %MyResult.ref.loc83: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %T.ref.loc83: type = name_ref T, %T.loc66_21.2 [symbolic = %T.loc66_21.1 (constants.%T.67d)]
// CHECK:STDOUT:     %E.ref.loc83: type = name_ref E, %E.loc66_30.2 [symbolic = %E.loc66_30.1 (constants.%E)]
// CHECK:STDOUT:     %MyResult.loc83: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc66_55.1 (constants.%MyResult.52ca24.1)]
// CHECK:STDOUT:     %.loc83: @PropagateChoice.%MyResult.Err.type (%MyResult.Err.type.11093c.1) = specific_constant generated.%MyResult.Err.decl, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.Err (constants.%MyResult.Err.899cd4.1)]
// CHECK:STDOUT:     %Err.ref: @PropagateChoice.%MyResult.Err.type (%MyResult.Err.type.11093c.1) = name_ref Err, %.loc83 [symbolic = %MyResult.Err (constants.%MyResult.Err.899cd4.1)]
// CHECK:STDOUT:     %e.ref: @PropagateChoice.%E.loc66_30.1 (%E) = name_ref e, %e
// CHECK:STDOUT:     %MyResult.Err.specific_fn.loc83_24.1: <specific function> = specific_function %Err.ref, @MyResult.Err(constants.%T.67d, constants.%E) [symbolic = %MyResult.Err.specific_fn.loc83_24.2 (constants.%MyResult.Err.specific_fn)]
// CHECK:STDOUT:     %.loc67_21.2: ref @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) = splice_block %return.param {}
// CHECK:STDOUT:     %MyResult.Err.call: init @PropagateChoice.%MyResult.loc66_55.1 (%MyResult.52ca24.1) to %.loc67_21.2 = call %MyResult.Err.specific_fn.loc83_24.1(%e.ref)
// CHECK:STDOUT:     return %MyResult.Err.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @WidenedVar(%T.loc90_16.2: type, %E.loc90_25.2: type) {
// CHECK:STDOUT:   %T.patt.loc90_16.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc90_16.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc90_16.1: type = symbolic_binding T, 0 [symbolic = %T.loc90_16.1 (constants.%T.67d)]
// CHECK:STDOUT:   %E.patt.loc90_25.2: %pattern_type.98f = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc90_25.2 (constants.%E.patt)]
// CHECK:STDOUT:   %E.loc90_25.1: type = symbolic_binding E, 1 [symbolic = %E.loc90_25.1 (constants.%E)]
// CHECK:STDOUT:   %pattern_type.loc90_34: type = pattern_type %T.loc90_16.1 [symbolic = %pattern_type.loc90_34 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %t.param_patt.loc90_34.2: @WidenedVar.%pattern_type.loc90_34 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %t.param_patt.loc90_34.2 (constants.%t.param_patt)]
// CHECK:STDOUT:   %t.patt.loc90_34.2: @WidenedVar.%pattern_type.loc90_34 (%pattern_type.51d1c4.1) = at_binding_pattern t, %t.param_patt.loc90_34.2 [symbolic = %t.patt.loc90_34.2 (constants.%t.patt)]
// CHECK:STDOUT:   %pattern_type.loc90_47: type = pattern_type %E.loc90_25.1 [symbolic = %pattern_type.loc90_47 (constants.%pattern_type.946bb9.1)]
// CHECK:STDOUT:   %e.param_patt.loc90_47.2: @WidenedVar.%pattern_type.loc90_47 (%pattern_type.946bb9.1) = value_param_pattern [symbolic = %e.param_patt.loc90_47.2 (constants.%e.param_patt.92c2b1.1)]
// CHECK:STDOUT:   %e.patt.loc90_47.2: @WidenedVar.%pattern_type.loc90_47 (%pattern_type.946bb9.1) = at_binding_pattern e, %e.param_patt.loc90_47.2 [symbolic = %e.patt.loc90_47.2 (constants.%e.patt.1c0fff.1)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc90_34: <witness> = require_complete_type %T.loc90_16.1 [symbolic = %require_complete.loc90_34 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %require_complete.loc90_47: <witness> = require_complete_type %E.loc90_25.1 [symbolic = %require_complete.loc90_47 (constants.%require_complete.441886.1)]
// CHECK:STDOUT:   %MyResult.loc91_31.2: type = class_type @MyResult, @MyResult(%T.loc90_16.1, %E.loc90_25.1) [symbolic = %MyResult.loc91_31.2 (constants.%MyResult.52ca24.1)]
// CHECK:STDOUT:   %require_complete.loc91: <witness> = require_complete_type %MyResult.loc91_31.2 [symbolic = %require_complete.loc91 (constants.%require_complete.090415.1)]
// CHECK:STDOUT:   %pattern_type.loc91: type = pattern_type %MyResult.loc91_31.2 [symbolic = %pattern_type.loc91 (constants.%pattern_type.6db5df.1)]
// CHECK:STDOUT:   %mr.patt.loc91_16.2: @WidenedVar.%pattern_type.loc91 (%pattern_type.6db5df.1) = ref_binding_pattern mr [symbolic = %mr.patt.loc91_16.2 (constants.%mr.patt.63f)]
// CHECK:STDOUT:   %mr.var_patt.loc91_3.2: @WidenedVar.%pattern_type.loc91 (%pattern_type.6db5df.1) = var_pattern %mr.patt.loc91_16.2 [symbolic = %mr.var_patt.loc91_3.2 (constants.%mr.var_patt)]
// CHECK:STDOUT:   %MyResult.Ok.type: type = fn_type @MyResult.Ok, @MyResult(%T.loc90_16.1, %E.loc90_25.1) [symbolic = %MyResult.Ok.type (constants.%MyResult.Ok.type.fd7821.1)]
// CHECK:STDOUT:   %MyResult.Ok: @WidenedVar.%MyResult.Ok.type (%MyResult.Ok.type.fd7821.1) = struct_value () [symbolic = %MyResult.Ok (constants.%MyResult.Ok.4604d7.1)]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn.loc91_49.2: <specific function> = specific_function %MyResult.Ok, @MyResult.Ok(%T.loc90_16.1, %E.loc90_25.1) [symbolic = %MyResult.Ok.specific_fn.loc91_49.2 (constants.%MyResult.Ok.specific_fn.1fe786.2)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %MyResult.loc91_31.2, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.61e)]
// CHECK:STDOUT:   %Destroy.facet.loc91_3.3: %Destroy.type = facet_value %MyResult.loc91_31.2, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc91_3.3 (constants.%Destroy.facet.510)]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.loc91_3.3) [symbolic = %Destroy.WithSelf.Op.type (constants.%Destroy.WithSelf.Op.type.a70)]
// CHECK:STDOUT:   %.loc91_3.4: type = fn_type_with_self_type %Destroy.WithSelf.Op.type, %Destroy.facet.loc91_3.3 [symbolic = %.loc91_3.4 (constants.%.713)]
// CHECK:STDOUT:   %impl.elem0.loc91_3.2: @WidenedVar.%.loc91_3.4 (%.713) = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc91_3.2 (constants.%impl.elem0.c14)]
// CHECK:STDOUT:   %specific_impl_fn.loc91_3.2: <specific function> = specific_impl_function %impl.elem0.loc91_3.2, @Destroy.WithSelf.Op(%Destroy.facet.loc91_3.3) [symbolic = %specific_impl_fn.loc91_3.2 (constants.%specific_impl_fn.3fd)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @WidenedVar.%T.loc90_16.1 (%T.67d), %e.param: @WidenedVar.%E.loc90_25.1 (%E)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %mr.var: ref @WidenedVar.%MyResult.loc91_31.2 (%MyResult.52ca24.1) = var_storage %mr.var_patt.loc91_3.1
// CHECK:STDOUT:     %MyResult.ref.loc91_35: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %T.ref.loc91_44: type = name_ref T, %T.loc90_16.2 [symbolic = %T.loc90_16.1 (constants.%T.67d)]
// CHECK:STDOUT:     %E.ref.loc91_47: type = name_ref E, %E.loc90_25.2 [symbolic = %E.loc90_25.1 (constants.%E)]
// CHECK:STDOUT:     %MyResult.loc91_48: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc91_31.2 (constants.%MyResult.52ca24.1)]
// CHECK:STDOUT:     %.loc91_49: @WidenedVar.%MyResult.Ok.type (%MyResult.Ok.type.fd7821.1) = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.Ok (constants.%MyResult.Ok.4604d7.1)]
// CHECK:STDOUT:     %Ok.ref: @WidenedVar.%MyResult.Ok.type (%MyResult.Ok.type.fd7821.1) = name_ref Ok, %.loc91_49 [symbolic = %MyResult.Ok (constants.%MyResult.Ok.4604d7.1)]
// CHECK:STDOUT:     %t.ref: @WidenedVar.%T.loc90_16.1 (%T.67d) = name_ref t, %t
// CHECK:STDOUT:     %MyResult.Ok.specific_fn.loc91_49.1: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%T.67d, constants.%E) [symbolic = %MyResult.Ok.specific_fn.loc91_49.2 (constants.%MyResult.Ok.specific_fn.1fe786.2)]
// CHECK:STDOUT:     %.loc91_3.1: ref @WidenedVar.%MyResult.loc91_31.2 (%MyResult.52ca24.1) = splice_block %mr.var {}
// CHECK:STDOUT:     %MyResult.Ok.call: init @WidenedVar.%MyResult.loc91_31.2 (%MyResult.52ca24.1) to %.loc91_3.1 = call %MyResult.Ok.specific_fn.loc91_49.1(%t.ref)
// CHECK:STDOUT:     assign %mr.var, %MyResult.Ok.call
// CHECK:STDOUT:     %.loc91_31: type = splice_block %MyResult.loc91_31.1 [symbolic = %MyResult.loc91_31.2 (constants.%MyResult.52ca24.1)] {
// CHECK:STDOUT:       %MyResult.ref.loc91_18: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %T.ref.loc91_27: type = name_ref T, %T.loc90_16.2 [symbolic = %T.loc90_16.1 (constants.%T.67d)]
// CHECK:STDOUT:       %E.ref.loc91_30: type = name_ref E, %E.loc90_25.2 [symbolic = %E.loc90_25.1 (constants.%E)]
// CHECK:STDOUT:       %MyResult.loc91_31.1: type = class_type @MyResult, @MyResult(constants.%T.67d, constants.%E) [symbolic = %MyResult.loc91_31.2 (constants.%MyResult.52ca24.1)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %mr: ref @WidenedVar.%MyResult.loc91_31.2 (%MyResult.52ca24.1) = wrapper_binding mr, %mr.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %mr.patt.loc91_16.1: @WidenedVar.%pattern_type.loc91 (%pattern_type.6db5df.1) = ref_binding_pattern mr [symbolic = %mr.patt.loc91_16.2 (constants.%mr.patt.63f)]
// CHECK:STDOUT:       %mr.var_patt.loc91_3.1: @WidenedVar.%pattern_type.loc91 (%pattern_type.6db5df.1) = var_pattern %mr.patt.loc91_16.1 [symbolic = %mr.var_patt.loc91_3.2 (constants.%mr.var_patt)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %impl.elem0.loc91_3.1: @WidenedVar.%.loc91_3.4 (%.713) = impl_witness_access constants.%Destroy.lookup_impl_witness.61e, element0 [symbolic = %impl.elem0.loc91_3.2 (constants.%impl.elem0.c14)]
// CHECK:STDOUT:     %bound_method.loc91_3.1: <bound method> = bound_method %mr.var, %impl.elem0.loc91_3.1
// CHECK:STDOUT:     %Destroy.facet.loc91_3.1: %Destroy.type = facet_value constants.%MyResult.52ca24.1, (constants.%Destroy.lookup_impl_witness.61e) [symbolic = %Destroy.facet.loc91_3.3 (constants.%Destroy.facet.510)]
// CHECK:STDOUT:     %.loc91_3.2: %Destroy.type = converted constants.%MyResult.52ca24.1, %Destroy.facet.loc91_3.1 [symbolic = %Destroy.facet.loc91_3.3 (constants.%Destroy.facet.510)]
// CHECK:STDOUT:     %Destroy.facet.loc91_3.2: %Destroy.type = facet_value constants.%MyResult.52ca24.1, (constants.%Destroy.lookup_impl_witness.61e) [symbolic = %Destroy.facet.loc91_3.3 (constants.%Destroy.facet.510)]
// CHECK:STDOUT:     %.loc91_3.3: %Destroy.type = converted constants.%MyResult.52ca24.1, %Destroy.facet.loc91_3.2 [symbolic = %Destroy.facet.loc91_3.3 (constants.%Destroy.facet.510)]
// CHECK:STDOUT:     %specific_impl_fn.loc91_3.1: <specific function> = specific_impl_function %impl.elem0.loc91_3.1, @Destroy.WithSelf.Op(constants.%Destroy.facet.510) [symbolic = %specific_impl_fn.loc91_3.2 (constants.%specific_impl_fn.3fd)]
// CHECK:STDOUT:     %bound_method.loc91_3.2: <bound method> = bound_method %mr.var, %specific_impl_fn.loc91_3.1
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call: init %empty_tuple.type = call %bound_method.loc91_3.2(%mr.var)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @WidenedScrutinee(%T.loc101_22.2: type) {
// CHECK:STDOUT:   %T.patt.loc101_22.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc101_22.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc101_22.1: type = symbolic_binding T, 0 [symbolic = %T.loc101_22.1 (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc101: type = pattern_type %T.loc101_22.1 [symbolic = %pattern_type.loc101 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %t.param_patt.loc101_31.2: @WidenedScrutinee.%pattern_type.loc101 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %t.param_patt.loc101_31.2 (constants.%t.param_patt)]
// CHECK:STDOUT:   %t.patt.loc101_31.2: @WidenedScrutinee.%pattern_type.loc101 (%pattern_type.51d1c4.1) = at_binding_pattern t, %t.param_patt.loc101_31.2 [symbolic = %t.patt.loc101_31.2 (constants.%t.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc101: <witness> = require_complete_type %T.loc101_22.1 [symbolic = %require_complete.loc101 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %MakeMR.specific_fn.loc102_10.2: <specific function> = specific_function constants.%MakeMR, @MakeMR(%T.loc101_22.1, constants.%i32) [symbolic = %MakeMR.specific_fn.loc102_10.2 (constants.%MakeMR.specific_fn)]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %MyResult, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.daf)]
// CHECK:STDOUT:   %Destroy.facet.loc102_26.3: %Destroy.type = facet_value %MyResult, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc102_26.3 (constants.%Destroy.facet.2ac)]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type: type = fn_type @Destroy.WithSelf.Op, @Destroy.WithSelf(%Destroy.facet.loc102_26.3) [symbolic = %Destroy.WithSelf.Op.type (constants.%Destroy.WithSelf.Op.type.533)]
// CHECK:STDOUT:   %.loc102_26.5: type = fn_type_with_self_type %Destroy.WithSelf.Op.type, %Destroy.facet.loc102_26.3 [symbolic = %.loc102_26.5 (constants.%.51e)]
// CHECK:STDOUT:   %impl.elem0.loc102_26.2: @WidenedScrutinee.%.loc102_26.5 (%.51e) = impl_witness_access %Destroy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc102_26.2 (constants.%impl.elem0.e7e)]
// CHECK:STDOUT:   %specific_impl_fn.loc102_26.2: <specific function> = specific_impl_function %impl.elem0.loc102_26.2, @Destroy.WithSelf.Op(%Destroy.facet.loc102_26.3) [symbolic = %specific_impl_fn.loc102_26.2 (constants.%specific_impl_fn.3e4)]
// CHECK:STDOUT:   %v.patt.loc103_15.2: @WidenedScrutinee.%pattern_type.loc101 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc103_15.2 (constants.%v.patt.291)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc101_22.1) [symbolic = %tuple.type (constants.%tuple.type.026b76.1)]
// CHECK:STDOUT:   %pattern_type.loc103: type = pattern_type %tuple.type [symbolic = %pattern_type.loc103 (constants.%pattern_type.b26)]
// CHECK:STDOUT:   %.loc103_15.2: @WidenedScrutinee.%pattern_type.loc103 (%pattern_type.b26) = tuple_pattern (%v.patt.loc103_15.2) [symbolic = %.loc103_15.2 (constants.%.946)]
// CHECK:STDOUT:   %.loc103_20.10: type = custom_layout_type {size=0, align=0, .Ok@0: @WidenedScrutinee.%tuple.type (%tuple.type.026b76.1), .Err@0: %tuple.type.a8a} [symbolic = %.loc103_20.10 (constants.%.611)]
// CHECK:STDOUT:   %Discard.specific_fn.loc104_7.2: <specific function> = specific_function constants.%Discard, @Discard(%T.loc101_22.1) [symbolic = %Discard.specific_fn.loc104_7.2 (constants.%Discard.specific_fn.628)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @WidenedScrutinee.%T.loc101_22.1 (%T.67d)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %MakeMR.ref: %MakeMR.type = name_ref MakeMR, file.%MakeMR.decl [concrete = constants.%MakeMR]
// CHECK:STDOUT:     %T.ref.loc102: type = name_ref T, %T.loc101_22.2 [symbolic = %T.loc101_22.1 (constants.%T.67d)]
// CHECK:STDOUT:     %i32.loc102: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %t.ref: @WidenedScrutinee.%T.loc101_22.1 (%T.67d) = name_ref t, %t
// CHECK:STDOUT:     %MakeMR.specific_fn.loc102_10.1: <specific function> = specific_function %MakeMR.ref, @MakeMR(constants.%T.67d, constants.%i32) [symbolic = %MakeMR.specific_fn.loc102_10.2 (constants.%MakeMR.specific_fn)]
// CHECK:STDOUT:     %.loc102_26.1: ref @WidenedScrutinee.%MyResult (%MyResult.f7e) = temporary_storage
// CHECK:STDOUT:     %MakeMR.call: init @WidenedScrutinee.%MyResult (%MyResult.f7e) to %.loc102_26.1 = call %MakeMR.specific_fn.loc102_10.1(%t.ref)
// CHECK:STDOUT:     %.loc102_26.2: ref @WidenedScrutinee.%MyResult (%MyResult.f7e) = temporary %.loc102_26.1, %MakeMR.call
// CHECK:STDOUT:     %impl.elem0.loc102_26.1: @WidenedScrutinee.%.loc102_26.5 (%.51e) = impl_witness_access constants.%Destroy.lookup_impl_witness.daf, element0 [symbolic = %impl.elem0.loc102_26.2 (constants.%impl.elem0.e7e)]
// CHECK:STDOUT:     %bound_method.loc102_26.1: <bound method> = bound_method %.loc102_26.2, %impl.elem0.loc102_26.1
// CHECK:STDOUT:     %Destroy.facet.loc102_26.1: %Destroy.type = facet_value constants.%MyResult.f7e, (constants.%Destroy.lookup_impl_witness.daf) [symbolic = %Destroy.facet.loc102_26.3 (constants.%Destroy.facet.2ac)]
// CHECK:STDOUT:     %.loc102_26.3: %Destroy.type = converted constants.%MyResult.f7e, %Destroy.facet.loc102_26.1 [symbolic = %Destroy.facet.loc102_26.3 (constants.%Destroy.facet.2ac)]
// CHECK:STDOUT:     %Destroy.facet.loc102_26.2: %Destroy.type = facet_value constants.%MyResult.f7e, (constants.%Destroy.lookup_impl_witness.daf) [symbolic = %Destroy.facet.loc102_26.3 (constants.%Destroy.facet.2ac)]
// CHECK:STDOUT:     %.loc102_26.4: %Destroy.type = converted constants.%MyResult.f7e, %Destroy.facet.loc102_26.2 [symbolic = %Destroy.facet.loc102_26.3 (constants.%Destroy.facet.2ac)]
// CHECK:STDOUT:     %specific_impl_fn.loc102_26.1: <specific function> = specific_impl_function %impl.elem0.loc102_26.1, @Destroy.WithSelf.Op(constants.%Destroy.facet.2ac) [symbolic = %specific_impl_fn.loc102_26.2 (constants.%specific_impl_fn.3e4)]
// CHECK:STDOUT:     %bound_method.loc102_26.2: <bound method> = bound_method %.loc102_26.2, %specific_impl_fn.loc102_26.1
// CHECK:STDOUT:     %Destroy.WithSelf.Op.call: init %empty_tuple.type = call %bound_method.loc102_26.2(%.loc102_26.2)
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %v.patt.loc103_15.1: @WidenedScrutinee.%pattern_type.loc101 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc103_15.2 (constants.%v.patt.291)]
// CHECK:STDOUT:       %.loc103_15.1: @WidenedScrutinee.%pattern_type.loc103 (%pattern_type.b26) = tuple_pattern (%v.patt.loc103_15.1) [symbolic = %.loc103_15.2 (constants.%.946)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc103_20.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc103_20.1: <bound method> = bound_method %int_0, %impl.elem0.loc103_20.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:     %specific_fn.loc103_20.1: <specific function> = specific_function %impl.elem0.loc103_20.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc103_20.2: <bound method> = bound_method %int_0, %specific_fn.loc103_20.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc103: init %u1 = call %bound_method.loc103_20.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc103_20.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc103 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc103_20.2: %u1 = converted %int_0, %.loc103_20.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:     %.loc103_20.3: ref %u1 = class_element_access %.loc102_26.2, element0
// CHECK:STDOUT:     %impl.elem0.loc103_20.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc103_20.3: <bound method> = bound_method %.loc103_20.2, %impl.elem0.loc103_20.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:     %specific_fn.loc103_20.2: <specific function> = specific_function %impl.elem0.loc103_20.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc103_20.4: <bound method> = bound_method %.loc103_20.2, %specific_fn.loc103_20.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:     %.loc103_20.4: %u1 = acquire_value %.loc103_20.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc103: init bool = call %bound_method.loc103_20.4(%.loc103_20.2, %.loc103_20.4)
// CHECK:STDOUT:     %.loc103_20.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc103
// CHECK:STDOUT:     %.loc103_20.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc103, %.loc103_20.5
// CHECK:STDOUT:     if %.loc103_20.6 br !match.case.then.loc103 else br !match.case.else.loc103
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc103:
// CHECK:STDOUT:     %.loc103_20.7: ref @WidenedScrutinee.%.loc103_20.10 (%.611) = class_element_access %.loc102_26.2, element1
// CHECK:STDOUT:     %.loc103_20.8: ref @WidenedScrutinee.%tuple.type (%tuple.type.026b76.1) = class_element_access %.loc103_20.7, element0
// CHECK:STDOUT:     %tuple.elem0.loc103: ref @WidenedScrutinee.%T.loc101_22.1 (%T.67d) = tuple_access %.loc103_20.8, element0
// CHECK:STDOUT:     %.loc103_20.9: @WidenedScrutinee.%T.loc101_22.1 (%T.67d) = acquire_value %tuple.elem0.loc103
// CHECK:STDOUT:     %T.ref.loc103: type = name_ref T, %T.loc101_22.2 [symbolic = %T.loc101_22.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v: @WidenedScrutinee.%T.loc101_22.1 (%T.67d) = wrapper_binding v, %.loc103_20.9
// CHECK:STDOUT:     %Discard.ref: %Discard.type = name_ref Discard, file.%Discard.decl [concrete = constants.%Discard]
// CHECK:STDOUT:     %v.ref: @WidenedScrutinee.%T.loc101_22.1 (%T.67d) = name_ref v, %v
// CHECK:STDOUT:     %Discard.specific_fn.loc104_7.1: <specific function> = specific_function %Discard.ref, @Discard(constants.%T.67d) [symbolic = %Discard.specific_fn.loc104_7.2 (constants.%Discard.specific_fn.628)]
// CHECK:STDOUT:     %Discard.call: init %empty_tuple.type = call %Discard.specific_fn.loc104_7.1(%v.ref)
// CHECK:STDOUT:     %int_1.loc105: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc105: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc105_15.1: <bound method> = bound_method %int_1.loc105, %impl.elem0.loc105 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:     %specific_fn.loc105: <specific function> = specific_function %impl.elem0.loc105, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc105_15.2: <bound method> = bound_method %int_1.loc105, %specific_fn.loc105 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc105: init %i32 = call %bound_method.loc105_15.2(%int_1.loc105) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     %.loc105: init %i32 = converted %int_1.loc105, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc105 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     return %.loc105
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc103:
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %e.patt: %pattern_type.6b6 = value_binding_pattern e [concrete = constants.%e.patt.2e6]
// CHECK:STDOUT:       %.loc107_16: %pattern_type.e71 = tuple_pattern (%e.patt) [concrete = constants.%.37b]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_1.loc107: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc107_23.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc107_23.1: <bound method> = bound_method %int_1.loc107, %impl.elem0.loc107_23.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc107_23.1: <specific function> = specific_function %impl.elem0.loc107_23.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc107_23.2: <bound method> = bound_method %int_1.loc107, %specific_fn.loc107_23.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc107: init %u1 = call %bound_method.loc107_23.2(%int_1.loc107) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc107_23.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc107 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc107_23.2: %u1 = converted %int_1.loc107, %.loc107_23.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc107_23.3: ref %u1 = class_element_access %.loc102_26.2, element0
// CHECK:STDOUT:     %impl.elem0.loc107_23.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc107_23.3: <bound method> = bound_method %.loc107_23.2, %impl.elem0.loc107_23.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:     %specific_fn.loc107_23.2: <specific function> = specific_function %impl.elem0.loc107_23.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc107_23.4: <bound method> = bound_method %.loc107_23.2, %specific_fn.loc107_23.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc107_23.4: %u1 = acquire_value %.loc107_23.3
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call.loc107: init bool = call %bound_method.loc107_23.4(%.loc107_23.2, %.loc107_23.4)
// CHECK:STDOUT:     %.loc107_23.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc107
// CHECK:STDOUT:     %.loc107_23.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc107, %.loc107_23.5
// CHECK:STDOUT:     if %.loc107_23.6 br !match.case.then.loc107 else br !match.case.else.loc107
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.then.loc107:
// CHECK:STDOUT:     %.loc107_23.7: ref @WidenedScrutinee.%.loc103_20.10 (%.611) = class_element_access %.loc102_26.2, element1
// CHECK:STDOUT:     %.loc107_23.8: ref %tuple.type.a8a = class_element_access %.loc107_23.7, element1
// CHECK:STDOUT:     %tuple.elem0.loc107: ref %i32 = tuple_access %.loc107_23.8, element0
// CHECK:STDOUT:     %.loc107_23.9: %i32 = acquire_value %tuple.elem0.loc107
// CHECK:STDOUT:     %i32.loc107: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %e: %i32 = wrapper_binding e, %.loc107_23.9
// CHECK:STDOUT:     %e.ref: %i32 = name_ref e, %e
// CHECK:STDOUT:     %impl.elem0.loc107_35: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:     %bound_method.loc107_35.1: <bound method> = bound_method %e.ref, %impl.elem0.loc107_35
// CHECK:STDOUT:     %specific_fn.loc107_35: <specific function> = specific_function %impl.elem0.loc107_35, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc107_35.2: <bound method> = bound_method %e.ref, %specific_fn.loc107_35
// CHECK:STDOUT:     %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc107_35.2(%e.ref)
// CHECK:STDOUT:     return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.case.else.loc107:
// CHECK:STDOUT:     br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT:   !match.done:
// CHECK:STDOUT:     %int_1.loc111: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:     %bound_method.loc111_10: <bound method> = bound_method %int_1.loc111, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:     %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc111_10(%int_1.loc111) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %impl.elem0.loc111: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc111_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc111 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:     %specific_fn.loc111: <specific function> = specific_function %impl.elem0.loc111, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc111_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc111 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:     %.loc111_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %.loc111_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc111_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc111: init %i32 = call %bound_method.loc111_12.2(%.loc111_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     %.loc111_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc111 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:     return %.loc111_12
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @PropagateOnly(constants.%R) {
// CHECK:STDOUT:   %R.patt.loc58_19.2 => constants.%R.patt
// CHECK:STDOUT:   %R.loc58_19.1 => constants.%R
// CHECK:STDOUT:   %R.as_type.loc58_57.1 => constants.%R.as_type
// CHECK:STDOUT:   %pattern_type.loc58 => constants.%pattern_type.239
// CHECK:STDOUT:   %r.param_patt.loc58_55.2 => constants.%r.param_patt
// CHECK:STDOUT:   %r.patt.loc58_55.2 => constants.%r.patt
// CHECK:STDOUT:   %.loc58_63.3 => constants.%.802
// CHECK:STDOUT:   %return.param_patt.loc58_63.2 => constants.%return.param_patt.aed
// CHECK:STDOUT:   %return.patt.loc58_60.2 => constants.%return.patt.0bca
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @PropagateChoice(constants.%T.67d, constants.%E) {
// CHECK:STDOUT:   %T.patt.loc66_21.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc66_21.1 => constants.%T.67d
// CHECK:STDOUT:   %E.patt.loc66_30.2 => constants.%E.patt
// CHECK:STDOUT:   %E.loc66_30.1 => constants.%E
// CHECK:STDOUT:   %MyResult.loc66_55.1 => constants.%MyResult.52ca24.1
// CHECK:STDOUT:   %pattern_type.loc66_40 => constants.%pattern_type.6db5df.1
// CHECK:STDOUT:   %mr.param_patt.loc66_40.2 => constants.%mr.param_patt
// CHECK:STDOUT:   %mr.patt.loc66_40.2 => constants.%mr.patt.c42
// CHECK:STDOUT:   %pattern_type.loc66_59 => constants.%pattern_type.946bb9.1
// CHECK:STDOUT:   %e.param_patt.loc66_59.2 => constants.%e.param_patt.92c2b1.1
// CHECK:STDOUT:   %e.patt.loc66_59.2 => constants.%e.patt.1c0fff.1
// CHECK:STDOUT:   %.loc67_21.3 => constants.%.6c705e.1
// CHECK:STDOUT:   %return.param_patt.loc67_21.2 => constants.%return.param_patt.296c1c.1
// CHECK:STDOUT:   %return.patt.loc67_5.2 => constants.%return.patt.971efd.1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @WidenedVar(constants.%T.67d, constants.%E) {
// CHECK:STDOUT:   %T.patt.loc90_16.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc90_16.1 => constants.%T.67d
// CHECK:STDOUT:   %E.patt.loc90_25.2 => constants.%E.patt
// CHECK:STDOUT:   %E.loc90_25.1 => constants.%E
// CHECK:STDOUT:   %pattern_type.loc90_34 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %t.param_patt.loc90_34.2 => constants.%t.param_patt
// CHECK:STDOUT:   %t.patt.loc90_34.2 => constants.%t.patt
// CHECK:STDOUT:   %pattern_type.loc90_47 => constants.%pattern_type.946bb9.1
// CHECK:STDOUT:   %e.param_patt.loc90_47.2 => constants.%e.param_patt.92c2b1.1
// CHECK:STDOUT:   %e.patt.loc90_47.2 => constants.%e.patt.1c0fff.1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @WidenedScrutinee(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc101_22.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc101_22.1 => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc101 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %t.param_patt.loc101_31.2 => constants.%t.param_patt
// CHECK:STDOUT:   %t.patt.loc101_31.2 => constants.%t.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- convert.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %MyResult.type: type = generic_class_type @MyResult [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %MyResult.generic: %MyResult.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.type.fd7: type = fn_type @MyResult.Ok, @MyResult(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %MyResult.Ok.460: %MyResult.Ok.type.fd7 = struct_value () [symbolic]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ErrA: type = class_type @ErrA [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %ErrB: type = class_type @ErrB [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.af5: type = facet_type <@ImplicitAs, @ImplicitAs(%ErrB)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.6f9: <witness> = impl_witness @ErrA.as.ImplicitAs.impl.%ImplicitAs.impl_witness_table [concrete]
// CHECK:STDOUT:   %ErrA.as.ImplicitAs.impl.Convert.type: type = fn_type @ErrA.as.ImplicitAs.impl.Convert [concrete]
// CHECK:STDOUT:   %ErrA.as.ImplicitAs.impl.Convert: %ErrA.as.ImplicitAs.impl.Convert.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.53c: %ImplicitAs.type.af5 = facet_value %ErrA, (%ImplicitAs.impl_witness.6f9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.487: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%ErrB, %ImplicitAs.facet.53c) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %MyResult.4a3: type = class_type @MyResult, @MyResult(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %Inner.type: type = fn_type @Inner [concrete]
// CHECK:STDOUT:   %Inner: %Inner.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.bb7: type = tuple_type (%ErrA) [concrete]
// CHECK:STDOUT:   %.e62: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a, .Err@0: %tuple.type.bb7} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.9f6: type = struct_type {.discriminant: %u1, .payload: %.e62} [concrete]
// CHECK:STDOUT:   %MyResult.819: type = class_type @MyResult, @MyResult(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %.38d: Core.Form = init_form %MyResult.819 [concrete]
// CHECK:STDOUT:   %pattern_type.695: type = pattern_type %MyResult.819 [concrete]
// CHECK:STDOUT:   %return.param_patt.cc3: %pattern_type.695 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.acc: %pattern_type.695 = return_slot_pattern %return.param_patt.cc3, %MyResult.819 [concrete]
// CHECK:STDOUT:   %Outer.type: type = fn_type @Outer [concrete]
// CHECK:STDOUT:   %Outer: %Outer.type = struct_value () [concrete]
// CHECK:STDOUT:   %MyResult.Ok.type.d53: type = fn_type @MyResult.Ok, @MyResult(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.b68: %MyResult.Ok.type.d53 = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt.113: %pattern_type.6b6 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt.113 [concrete]
// CHECK:STDOUT:   %Try.impl_witness.10e: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type.4ce: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.2ad: %MyResult.as.Try.impl.FromBreak.type.4ce = struct_value () [concrete]
// CHECK:STDOUT:   %Try.impl_witness.00f: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type.cbc: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.ea2: %MyResult.as.Try.impl.Branch.type.cbc = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.03f: %Try.type = facet_value %MyResult.4a3, (%Try.impl_witness.00f) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.c59: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.03f) [concrete]
// CHECK:STDOUT:   %.872: type = fn_type_with_self_type %Try.WithSelf.Branch.type.c59, %Try.facet.03f [concrete]
// CHECK:STDOUT:   %ControlFlow.46a: type = class_type @ControlFlow, @ControlFlow(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch.ea2, @MyResult.as.Try.impl.Branch(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %.873: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.bb7} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.615: type = struct_type {.discriminant: %u1, .payload: %.873} [concrete]
// CHECK:STDOUT:   %Try.facet.505: %Try.type = facet_value %MyResult.819, (%Try.impl_witness.10e) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.b6d: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.505) [concrete]
// CHECK:STDOUT:   %.edc: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.b6d, %Try.facet.505 [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak.2ad, @MyResult.as.Try.impl.FromBreak(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %.4e3: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.487, %ImplicitAs.facet.53c [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc62_24.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.10: type = fn_type @Destroy.Op.loc62_24.10 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.10: %Destroy.Op.type.1d8f74.10 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.13: type = fn_type @Destroy.Op.loc62_23.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.13: %Destroy.Op.type.1d8f74.13 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn.d1d: <specific function> = specific_function %MyResult.Ok.b68, @MyResult.Ok(%i32, %ErrB) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %MyResult.Ok.decl: @MyResult.%MyResult.Ok.type (%MyResult.Ok.type.fd7) = fn_decl @MyResult.Ok [symbolic = @MyResult.%MyResult.Ok (constants.%MyResult.Ok.460)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Outer.decl: %Outer.type = fn_decl @Outer [concrete = constants.%Outer] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.695 = out_param_pattern [concrete = constants.%return.param_patt.cc3]
// CHECK:STDOUT:     %return.patt: %pattern_type.695 = return_slot_pattern %return.param_patt, %MyResult.loc61 [concrete = constants.%return.patt.acc]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc61: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc61_30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ErrB.ref.loc61: type = name_ref ErrB, file.%ErrB.decl [concrete = constants.%ErrB]
// CHECK:STDOUT:     %MyResult.loc61: type = class_type @MyResult, @MyResult(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.819]
// CHECK:STDOUT:     %.loc61_39.3: Core.Form = init_form %MyResult.loc61 [concrete = constants.%.38d]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc61_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MyResult.819 = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.819 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Outer(%n.param: %i32) -> out %return.param: %MyResult.819 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %i32 = var_storage %v.var_patt
// CHECK:STDOUT:   %Inner.ref: %Inner.type = name_ref Inner, file.%Inner.decl [concrete = constants.%Inner]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc62_23.1: ref %MyResult.4a3 = temporary_storage
// CHECK:STDOUT:   %Inner.call: init %MyResult.4a3 to %.loc62_23.1 = call %Inner.ref(%n.ref)
// CHECK:STDOUT:   %.loc62_23.2: ref %MyResult.4a3 = temporary %.loc62_23.1, %Inner.call
// CHECK:STDOUT:   %impl.elem2: %.872 = impl_witness_access constants.%Try.impl_witness.00f, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.ea2]
// CHECK:STDOUT:   %bound_method.loc62_24.1: <bound method> = bound_method %.loc62_23.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc62_24.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%ErrA) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc62_24.2: <bound method> = bound_method %.loc62_23.2, %specific_fn.loc62_24.1
// CHECK:STDOUT:   %.loc62_24.1: ref %ControlFlow.46a = temporary_storage
// CHECK:STDOUT:   %.loc62_23.3: %MyResult.4a3 = acquire_value %.loc62_23.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.46a to %.loc62_24.1 = call %bound_method.loc62_24.2(%.loc62_23.3)
// CHECK:STDOUT:   %.loc62_24.2: ref %ControlFlow.46a = temporary %.loc62_24.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc62_24.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc62_24.3: <bound method> = bound_method %int_1, %impl.elem0.loc62_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc62_24.2: <specific function> = specific_function %impl.elem0.loc62_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc62_24.4: <bound method> = bound_method %int_1, %specific_fn.loc62_24.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc62_24.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc62_24.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc62_24.4: %u1 = converted %int_1, %.loc62_24.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc62_24.5: ref %u1 = class_element_access %.loc62_24.2, element0
// CHECK:STDOUT:   %impl.elem0.loc62_24.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc62_24.5: <bound method> = bound_method %.loc62_24.4, %impl.elem0.loc62_24.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc62_24.3: <specific function> = specific_function %impl.elem0.loc62_24.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc62_24.6: <bound method> = bound_method %.loc62_24.4, %specific_fn.loc62_24.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc62_24.6: %u1 = acquire_value %.loc62_24.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc62_24.6(%.loc62_24.4, %.loc62_24.6)
// CHECK:STDOUT:   %.loc62_24.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc62_24.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc62_24.7
// CHECK:STDOUT:   if %.loc62_24.8 br !.loc62_24.1 else br !.loc62_24.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc62_24.1:
// CHECK:STDOUT:   %.loc62_24.9: ref %.873 = class_element_access %.loc62_24.2, element1
// CHECK:STDOUT:   %.loc62_24.10: ref %tuple.type.bb7 = class_element_access %.loc62_24.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc62_24.1: ref %ErrA = tuple_access %.loc62_24.10, element0
// CHECK:STDOUT:   %.loc62_24.11: %ErrA = acquire_value %tuple.elem0.loc62_24.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.819, (constants.%Try.impl_witness.10e) [concrete = constants.%Try.facet.505]
// CHECK:STDOUT:   %.loc62_24.12: %Try.type = converted constants.%MyResult.819, %Try.facet [concrete = constants.%Try.facet.505]
// CHECK:STDOUT:   %impl.elem3: %.edc = impl_witness_access constants.%Try.impl_witness.10e, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.2ad]
// CHECK:STDOUT:   %specific_fn.loc62_24.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc61_39.1: ref %MyResult.819 = splice_block %return.param {}
// CHECK:STDOUT:   %impl.elem0.loc62_24.3: %.4e3 = impl_witness_access constants.%ImplicitAs.impl_witness.6f9, element0 [concrete = constants.%ErrA.as.ImplicitAs.impl.Convert]
// CHECK:STDOUT:   %bound_method.loc62_24.7: <bound method> = bound_method %.loc62_24.11, %impl.elem0.loc62_24.3
// CHECK:STDOUT:   %ErrA.as.ImplicitAs.impl.Convert.call: init %ErrB = call %bound_method.loc62_24.7(%.loc62_24.11)
// CHECK:STDOUT:   %.loc62_24.13: %ErrB = value_of_initializer %ErrA.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc62_24.14: %ErrB = converted %.loc62_24.11, %.loc62_24.13
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.819 to %.loc61_39.1 = call %specific_fn.loc62_24.4(%.loc62_24.14)
// CHECK:STDOUT:   %Destroy.Op.bound.loc62_24.1: <bound method> = bound_method %.loc62_24.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc62_24.1: init %empty_tuple.type = call %Destroy.Op.bound.loc62_24.1(%.loc62_24.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc62_23.1: <bound method> = bound_method %.loc62_23.2, constants.%Destroy.Op.1a2547.13
// CHECK:STDOUT:   %Destroy.Op.call.loc62_23.1: init %empty_tuple.type = call %Destroy.Op.bound.loc62_23.1(%.loc62_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc62_3.1: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc62_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc62_3.1(%v.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc62_24.2:
// CHECK:STDOUT:   %.loc62_24.15: ref %.873 = class_element_access %.loc62_24.2, element1
// CHECK:STDOUT:   %.loc62_24.16: ref %tuple.type.a8a = class_element_access %.loc62_24.15, element0
// CHECK:STDOUT:   %tuple.elem0.loc62_24.2: ref %i32 = tuple_access %.loc62_24.16, element0
// CHECK:STDOUT:   %.loc62_24.17: %i32 = acquire_value %tuple.elem0.loc62_24.2
// CHECK:STDOUT:   %impl.elem0.loc62_24.4: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc62_24.8: <bound method> = bound_method %.loc62_24.17, %impl.elem0.loc62_24.4
// CHECK:STDOUT:   %specific_fn.loc62_24.5: <specific function> = specific_function %impl.elem0.loc62_24.4, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc62_24.9: <bound method> = bound_method %.loc62_24.17, %specific_fn.loc62_24.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc62_24.9(%.loc62_24.17)
// CHECK:STDOUT:   assign %v.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc62: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt.113]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc63: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc63: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %ErrB.ref.loc63: type = name_ref ErrB, file.%ErrB.decl [concrete = constants.%ErrB]
// CHECK:STDOUT:   %MyResult.loc63: type = class_type @MyResult, @MyResult(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.819]
// CHECK:STDOUT:   %.loc63_29: %MyResult.Ok.type.d53 = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.Ok.b68]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.d53 = name_ref Ok, %.loc63_29 [concrete = constants.%MyResult.Ok.b68]
// CHECK:STDOUT:   %v.ref: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.Ok.specific_fn.d1d]
// CHECK:STDOUT:   %.loc61_39.2: ref %MyResult.819 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc63_33: %i32 = acquire_value %v.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.819 to %.loc61_39.2 = call %MyResult.Ok.specific_fn(%.loc63_33)
// CHECK:STDOUT:   %Destroy.Op.bound.loc62_24.2: <bound method> = bound_method %.loc62_24.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc62_24.2: init %empty_tuple.type = call %Destroy.Op.bound.loc62_24.2(%.loc62_24.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc62_23.2: <bound method> = bound_method %.loc62_23.2, constants.%Destroy.Op.1a2547.13
// CHECK:STDOUT:   %Destroy.Op.call.loc62_23.2: init %empty_tuple.type = call %Destroy.Op.bound.loc62_23.2(%.loc62_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc62_3.2: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc62_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc62_3.2(%v.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.6(%self.param: ref %ErrA) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.7(%self.param: ref %tuple.type.bb7) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.8(%self.param: ref %.873) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.9(%self.param: ref %struct_type.discriminant.payload.615) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_24.10(%self.param: ref %ControlFlow.46a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_23.1(%self.param: ref %.e62) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_23.2(%self.param: ref %struct_type.discriminant.payload.9f6) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc62_23.3(%self.param: ref %MyResult.4a3) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
