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
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6, dated amendment):
    // reachability analysis does not consult match exhaustiveness, so an
    // exhaustive match still needs a trailing terminator; in a generic body
    // no `ControlFlow(T, E)` value is conjurable, so recurse through the
    // interface.
    return self.(Core.Try.Branch)();
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
  // CHECK:STDERR: generic.carbon:[[@LINE+8]]:34: error: cannot access member of interface `Core.Destroy` in type `Core.ControlFlow(R.(Core.Try.ContinueType), i32)` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   let unused c: R.ContinueType = r?;
  // CHECK:STDERR:                                  ^~
  // CHECK:STDERR:
  // CHECK:STDERR: generic.carbon:[[@LINE+4]]:34: error: cannot access member of interface `Core.Destroy` in type `Core.ControlFlow(R.(Core.Try.ContinueType), i32)` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   let unused c: R.ContinueType = r?;
  // CHECK:STDERR:                                  ^~
  // CHECK:STDERR:
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
    // Unreachable-terminator idiom (fork/b1/plan.md §2.6): reachability
    // doesn't consult match exhaustiveness; no generic `ControlFlow(T, E)`
    // value is conjurable, so recurse through the interface.
    return self.(Core.Try.Branch)();
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
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
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
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
// CHECK:STDOUT:   %Try.impl_witness.6d2: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type.dbd: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.b50: %MyResult.as.Try.impl.Branch.type.dbd = struct_value () [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type.b1c: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.c92: %MyResult.as.Try.impl.FromBreak.type.b1c = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.7da: %Try.type = facet_value %MyResult.21e, (%Try.impl_witness.6d2) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.a49: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.7da) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.c77: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.7da) [concrete]
// CHECK:STDOUT:   %.d76: type = fn_type_with_self_type %Try.WithSelf.Branch.type.a49, %Try.facet.7da [concrete]
// CHECK:STDOUT:   %ControlFlow.32a: type = class_type @ControlFlow, @ControlFlow(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch.b50, @MyResult.as.Try.impl.Branch(%i32, %i32) [concrete]
// CHECK:STDOUT:   %.b63: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.88b: type = struct_type {.discriminant: %u1, .payload: %.b63} [concrete]
// CHECK:STDOUT:   %.1e7: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.c77, %Try.facet.7da [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak.c92, @MyResult.as.Try.impl.FromBreak(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc31_23.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc31_23.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.11: type = fn_type @Destroy.Op.loc31_22.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.11: %Destroy.Op.type.1d8f74.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.3ff: <witness> = impl_witness imports.%AddWith.impl_witness_table.fff, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.720bef.1: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.b91858.1: %Int.as.AddWith.impl.Op.type.720bef.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.720bef.2: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.b91858.2: %Int.as.AddWith.impl.Op.type.720bef.2 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.51c: %AddWith.type.832 = facet_value %i32, (%AddWith.impl_witness.3ff) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.42c: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(Core.IntLiteral, %AddWith.facet.51c) [concrete]
// CHECK:STDOUT:   %.0d8: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.42c, %AddWith.facet.51c [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.0618ee.1: <specific function> = specific_function %Int.as.AddWith.impl.Op.b91858.2, @Int.as.AddWith.impl.Op.2(%int_32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.0618ee.2: <specific function> = specific_function %Int.as.AddWith.impl.Op.b91858.1, @Int.as.AddWith.impl.Op.3(%int_32, %ImplicitAs.facet.9f1) [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3a: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.fff = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.8a3a), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
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
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc30 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc30: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc30_30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc30_35: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc30: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc30_38.3: Core.Form = init_form %MyResult.loc30 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc30_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Statement.decl: %Statement.type = fn_decl @Statement [concrete = constants.%Statement] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc36 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc36: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc36_34: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc36_39: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc36: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc36_42.3: Core.Form = init_form %MyResult.loc36 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc36_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Chain.decl: %Chain.type = fn_decl @Chain [concrete = constants.%Chain] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc44 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc44: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc44_30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc44_35: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc44: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc44_38.4: Core.Form = init_form %MyResult.loc44 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc44_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Argument.decl: %Argument.type = fn_decl @Argument [concrete = constants.%Argument] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc51 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc51: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc51_33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc51_38: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc51: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc51_41.3: Core.Form = init_form %MyResult.loc51 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc51_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MyResult.21e = out_param call_param1
// CHECK:STDOUT:     %return: ref %MyResult.21e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %InArm.decl: %InArm.type = fn_decl @InArm [concrete = constants.%InArm] {
// CHECK:STDOUT:     %r.param_patt: %pattern_type.90f = value_param_pattern [concrete = constants.%r.param_patt]
// CHECK:STDOUT:     %r.patt: %pattern_type.90f = at_binding_pattern r, %r.param_patt [concrete = constants.%r.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.90f = out_param_pattern [concrete = constants.%return.param_patt.8cb]
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc60_53 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc60_36: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc60_45: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc60_50: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc60_53: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc60_53.4: Core.Form = init_form %MyResult.loc60_53 [concrete = constants.%.4de]
// CHECK:STDOUT:     %r.param: %MyResult.21e = value_param call_param0
// CHECK:STDOUT:     %.loc60_30: type = splice_block %MyResult.loc60_30 [concrete = constants.%MyResult.21e] {
// CHECK:STDOUT:       %MyResult.ref.loc60_13: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %i32.loc60_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc60_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %MyResult.loc60_30: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
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
// CHECK:STDOUT:     %return.patt: %pattern_type.90f = return_slot_pattern %return.param_patt, %MyResult.loc72 [concrete = constants.%return.patt.6c9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc72: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc72_42: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc72_47: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc72: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     %.loc72_50.4: Core.Form = init_form %MyResult.loc72 [concrete = constants.%.4de]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc72_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %c.param: bool = value_param call_param1
// CHECK:STDOUT:     %.loc72_24: type = type_literal bool [concrete = bool]
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
// CHECK:STDOUT:   %.loc31_22.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call: init %MyResult.21e to %.loc31_22.1 = call %Open.ref(%n.ref)
// CHECK:STDOUT:   %.loc31_22.2: ref %MyResult.21e = temporary %.loc31_22.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.d76 = impl_witness_access constants.%Try.impl_witness.6d2, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc31_23.1: <bound method> = bound_method %.loc31_22.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc31_23.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc31_23.2: <bound method> = bound_method %.loc31_22.2, %specific_fn.loc31_23.1
// CHECK:STDOUT:   %.loc31_23.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc31_22.3: %MyResult.21e = acquire_value %.loc31_22.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc31_23.1 = call %bound_method.loc31_23.2(%.loc31_22.3)
// CHECK:STDOUT:   %.loc31_23.2: ref %ControlFlow.32a = temporary %.loc31_23.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc31: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc31_23.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc31_23.3: <bound method> = bound_method %int_1.loc31, %impl.elem0.loc31_23.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc31_23.2: <specific function> = specific_function %impl.elem0.loc31_23.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc31_23.4: <bound method> = bound_method %int_1.loc31, %specific_fn.loc31_23.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31: init %u1 = call %bound_method.loc31_23.4(%int_1.loc31) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc31_23.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc31_23.4: %u1 = converted %int_1.loc31, %.loc31_23.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc31_23.5: ref %u1 = class_element_access %.loc31_23.2, element0
// CHECK:STDOUT:   %impl.elem0.loc31_23.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc31_23.5: <bound method> = bound_method %.loc31_23.4, %impl.elem0.loc31_23.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc31_23.3: <specific function> = specific_function %impl.elem0.loc31_23.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc31_23.6: <bound method> = bound_method %.loc31_23.4, %specific_fn.loc31_23.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc31_23.6: %u1 = acquire_value %.loc31_23.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc31_23.6(%.loc31_23.4, %.loc31_23.6)
// CHECK:STDOUT:   %.loc31_23.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc31_23.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc31_23.7
// CHECK:STDOUT:   if %.loc31_23.8 br !.loc31_23.1 else br !.loc31_23.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc31_23.1:
// CHECK:STDOUT:   %.loc31_23.9: ref %.b63 = class_element_access %.loc31_23.2, element1
// CHECK:STDOUT:   %.loc31_23.10: ref %tuple.type.a8a = class_element_access %.loc31_23.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc31_23.1: ref %i32 = tuple_access %.loc31_23.10, element0
// CHECK:STDOUT:   %.loc31_23.11: %i32 = acquire_value %tuple.elem0.loc31_23.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.6d2) [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %.loc31_23.12: %Try.type = converted constants.%MyResult.21e, %Try.facet [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %impl.elem3: %.1e7 = impl_witness_access constants.%Try.impl_witness.6d2, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc31_23.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc30_38.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.21e to %.loc30_38.1 = call %specific_fn.loc31_23.4(%.loc31_23.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc31_23.1: <bound method> = bound_method %.loc31_23.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc31_23.1: init %empty_tuple.type = call %Destroy.Op.bound.loc31_23.1(%.loc31_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc31_22.1: <bound method> = bound_method %.loc31_22.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc31_22.1: init %empty_tuple.type = call %Destroy.Op.bound.loc31_22.1(%.loc31_22.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc31_3.1: <bound method> = bound_method %f.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc31_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc31_3.1(%f.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc31_23.2:
// CHECK:STDOUT:   %.loc31_23.13: ref %.b63 = class_element_access %.loc31_23.2, element1
// CHECK:STDOUT:   %.loc31_23.14: ref %tuple.type.a8a = class_element_access %.loc31_23.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc31_23.2: ref %i32 = tuple_access %.loc31_23.14, element0
// CHECK:STDOUT:   %.loc31_23.15: %i32 = acquire_value %tuple.elem0.loc31_23.2
// CHECK:STDOUT:   %impl.elem0.loc31_23.3: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc31_23.7: <bound method> = bound_method %.loc31_23.15, %impl.elem0.loc31_23.3
// CHECK:STDOUT:   %specific_fn.loc31_23.5: <specific function> = specific_function %impl.elem0.loc31_23.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc31_23.8: <bound method> = bound_method %.loc31_23.15, %specific_fn.loc31_23.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc31_23.8(%.loc31_23.15)
// CHECK:STDOUT:   assign %f.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc31: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %f: ref %i32 = wrapper_binding f, %f.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %f.patt: %pattern_type.6b6 = ref_binding_pattern f [concrete = constants.%f.patt]
// CHECK:STDOUT:     %f.var_patt: %pattern_type.6b6 = var_pattern %f.patt [concrete = constants.%f.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc32: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc32_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc32_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc32: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc32_28: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc32_28 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %f.ref: ref %i32 = name_ref f, %f
// CHECK:STDOUT:   %int_1.loc32: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.0d8 = impl_witness_access constants.%AddWith.impl_witness.3ff, element1 [concrete = constants.%Int.as.AddWith.impl.Op.b91858.2]
// CHECK:STDOUT:   %bound_method.loc32_34.1: <bound method> = bound_method %f.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc32_34: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.0618ee.1]
// CHECK:STDOUT:   %bound_method.loc32_34.2: <bound method> = bound_method %f.ref, %specific_fn.loc32_34
// CHECK:STDOUT:   %.loc32_32: %i32 = acquire_value %f.ref
// CHECK:STDOUT:   %.loc32_34.1: %Int.as.AddWith.impl.Op.type.720bef.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.AddWith.impl.Op.b91858.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.720bef.1 = name_ref Op, %.loc32_34.1 [concrete = constants.%Int.as.AddWith.impl.Op.b91858.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %.loc32_32, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.0618ee.2]
// CHECK:STDOUT:   %bound_method.loc32_34.3: <bound method> = bound_method %.loc32_32, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc32: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc32_36.1: <bound method> = bound_method %int_1.loc32, %impl.elem0.loc32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc32_36: <specific function> = specific_function %impl.elem0.loc32, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc32_36.2: <bound method> = bound_method %int_1.loc32, %specific_fn.loc32_36 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32: init %i32 = call %bound_method.loc32_36.2(%int_1.loc32) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc32_36.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc32_36.2: %i32 = converted %int_1.loc32, %.loc32_36.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc32_34.3(%.loc32_32, %.loc32_36.2)
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc30_38.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc32_34.2: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc32_34.3: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc32_34.2
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc30_38.2 = call %MyResult.Ok.specific_fn(%.loc32_34.3)
// CHECK:STDOUT:   %Destroy.Op.bound.loc31_23.2: <bound method> = bound_method %.loc31_23.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc31_23.2: init %empty_tuple.type = call %Destroy.Op.bound.loc31_23.2(%.loc31_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc31_22.2: <bound method> = bound_method %.loc31_22.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc31_22.2: init %empty_tuple.type = call %Destroy.Op.bound.loc31_22.2(%.loc31_22.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc31_3.2: <bound method> = bound_method %f.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc31_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc31_3.2(%f.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_23.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_23.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_23.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_23.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_23.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_23.6(%self.param: ref %.b63) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_23.7(%self.param: ref %struct_type.discriminant.payload.88b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_23.8(%self.param: ref %ControlFlow.32a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_22.1(%self.param: ref %.bf4) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_22.2(%self.param: ref %struct_type.discriminant.payload.f26) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc31_22.3(%self.param: ref %MyResult.21e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Statement(%n.param: %i32) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc37: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc37_9.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call: init %MyResult.21e to %.loc37_9.1 = call %Open.ref(%n.ref.loc37)
// CHECK:STDOUT:   %.loc37_9.2: ref %MyResult.21e = temporary %.loc37_9.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.d76 = impl_witness_access constants.%Try.impl_witness.6d2, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc37_10.1: <bound method> = bound_method %.loc37_9.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc37_10.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc37_10.2: <bound method> = bound_method %.loc37_9.2, %specific_fn.loc37_10.1
// CHECK:STDOUT:   %.loc37_10.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc37_9.3: %MyResult.21e = acquire_value %.loc37_9.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc37_10.1 = call %bound_method.loc37_10.2(%.loc37_9.3)
// CHECK:STDOUT:   %.loc37_10.2: ref %ControlFlow.32a = temporary %.loc37_10.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc37_10.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc37_10.3: <bound method> = bound_method %int_1, %impl.elem0.loc37_10.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc37_10.2: <specific function> = specific_function %impl.elem0.loc37_10.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc37_10.4: <bound method> = bound_method %int_1, %specific_fn.loc37_10.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc37_10.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc37_10.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc37_10.4: %u1 = converted %int_1, %.loc37_10.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc37_10.5: ref %u1 = class_element_access %.loc37_10.2, element0
// CHECK:STDOUT:   %impl.elem0.loc37_10.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc37_10.5: <bound method> = bound_method %.loc37_10.4, %impl.elem0.loc37_10.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc37_10.3: <specific function> = specific_function %impl.elem0.loc37_10.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc37_10.6: <bound method> = bound_method %.loc37_10.4, %specific_fn.loc37_10.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc37_10.6: %u1 = acquire_value %.loc37_10.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc37_10.6(%.loc37_10.4, %.loc37_10.6)
// CHECK:STDOUT:   %.loc37_10.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc37_10.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc37_10.7
// CHECK:STDOUT:   if %.loc37_10.8 br !.loc37_10.1 else br !.loc37_10.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc37_10.1:
// CHECK:STDOUT:   %.loc37_10.9: ref %.b63 = class_element_access %.loc37_10.2, element1
// CHECK:STDOUT:   %.loc37_10.10: ref %tuple.type.a8a = class_element_access %.loc37_10.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc37_10.1: ref %i32 = tuple_access %.loc37_10.10, element0
// CHECK:STDOUT:   %.loc37_10.11: %i32 = acquire_value %tuple.elem0.loc37_10.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.6d2) [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %.loc37_10.12: %Try.type = converted constants.%MyResult.21e, %Try.facet [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %impl.elem3: %.1e7 = impl_witness_access constants.%Try.impl_witness.6d2, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc37_10.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc36_42.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.21e to %.loc36_42.1 = call %specific_fn.loc37_10.4(%.loc37_10.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc37_10.1: <bound method> = bound_method %.loc37_10.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc37_10.1: init %empty_tuple.type = call %Destroy.Op.bound.loc37_10.1(%.loc37_10.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc37_9.1: <bound method> = bound_method %.loc37_9.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc37_9.1: init %empty_tuple.type = call %Destroy.Op.bound.loc37_9.1(%.loc37_9.2)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc37_10.2:
// CHECK:STDOUT:   %.loc37_10.13: ref %.b63 = class_element_access %.loc37_10.2, element1
// CHECK:STDOUT:   %.loc37_10.14: ref %tuple.type.a8a = class_element_access %.loc37_10.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc37_10.2: ref %i32 = tuple_access %.loc37_10.14, element0
// CHECK:STDOUT:   %.loc37_10.15: %i32 = acquire_value %tuple.elem0.loc37_10.2
// CHECK:STDOUT:   %Destroy.Op.bound.loc37_10.2: <bound method> = bound_method %.loc37_10.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc37_10.2: init %empty_tuple.type = call %Destroy.Op.bound.loc37_10.2(%.loc37_10.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc37_9.2: <bound method> = bound_method %.loc37_9.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc37_9.2: init %empty_tuple.type = call %Destroy.Op.bound.loc37_9.2(%.loc37_9.2)
// CHECK:STDOUT:   %MyResult.ref.loc38: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc38_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc38_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc38: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc38: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc38 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %n.ref.loc38: %i32 = name_ref n, %n
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc36_42.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc36_42.2 = call %MyResult.Ok.specific_fn(%n.ref.loc38)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Chain(%n.param: %i32) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.var: ref %i32 = var_storage %t.var_patt
// CHECK:STDOUT:   %Open.ref.loc45_16: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %Open.ref.loc45_21: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc45_27.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call.loc45_27: init %MyResult.21e to %.loc45_27.1 = call %Open.ref.loc45_21(%n.ref)
// CHECK:STDOUT:   %.loc45_27.2: ref %MyResult.21e = temporary %.loc45_27.1, %Open.call.loc45_27
// CHECK:STDOUT:   %impl.elem2.loc45_28: %.d76 = impl_witness_access constants.%Try.impl_witness.6d2, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc45_28.1: <bound method> = bound_method %.loc45_27.2, %impl.elem2.loc45_28
// CHECK:STDOUT:   %specific_fn.loc45_28.1: <specific function> = specific_function %impl.elem2.loc45_28, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc45_28.2: <bound method> = bound_method %.loc45_27.2, %specific_fn.loc45_28.1
// CHECK:STDOUT:   %.loc45_28.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc45_27.3: %MyResult.21e = acquire_value %.loc45_27.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc45_28: init %ControlFlow.32a to %.loc45_28.1 = call %bound_method.loc45_28.2(%.loc45_27.3)
// CHECK:STDOUT:   %.loc45_28.2: ref %ControlFlow.32a = temporary %.loc45_28.1, %MyResult.as.Try.impl.Branch.call.loc45_28
// CHECK:STDOUT:   %int_1.loc45_28: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc45_28.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc45_28.3: <bound method> = bound_method %int_1.loc45_28, %impl.elem0.loc45_28.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc45_28.2: <specific function> = specific_function %impl.elem0.loc45_28.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc45_28.4: <bound method> = bound_method %int_1.loc45_28, %specific_fn.loc45_28.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc45_28: init %u1 = call %bound_method.loc45_28.4(%int_1.loc45_28) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc45_28.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc45_28 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc45_28.4: %u1 = converted %int_1.loc45_28, %.loc45_28.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc45_28.5: ref %u1 = class_element_access %.loc45_28.2, element0
// CHECK:STDOUT:   %impl.elem0.loc45_28.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc45_28.5: <bound method> = bound_method %.loc45_28.4, %impl.elem0.loc45_28.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc45_28.3: <specific function> = specific_function %impl.elem0.loc45_28.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc45_28.6: <bound method> = bound_method %.loc45_28.4, %specific_fn.loc45_28.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc45_28.6: %u1 = acquire_value %.loc45_28.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc45_28: init bool = call %bound_method.loc45_28.6(%.loc45_28.4, %.loc45_28.6)
// CHECK:STDOUT:   %.loc45_28.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc45_28
// CHECK:STDOUT:   %.loc45_28.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc45_28, %.loc45_28.7
// CHECK:STDOUT:   if %.loc45_28.8 br !.loc45_28.1 else br !.loc45_28.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc45_28.1:
// CHECK:STDOUT:   %.loc45_28.9: ref %.b63 = class_element_access %.loc45_28.2, element1
// CHECK:STDOUT:   %.loc45_28.10: ref %tuple.type.a8a = class_element_access %.loc45_28.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc45_28.1: ref %i32 = tuple_access %.loc45_28.10, element0
// CHECK:STDOUT:   %.loc45_28.11: %i32 = acquire_value %tuple.elem0.loc45_28.1
// CHECK:STDOUT:   %Try.facet.loc45_28: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.6d2) [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %.loc45_28.12: %Try.type = converted constants.%MyResult.21e, %Try.facet.loc45_28 [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %impl.elem3.loc45_28: %.1e7 = impl_witness_access constants.%Try.impl_witness.6d2, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc45_28.4: <specific function> = specific_function %impl.elem3.loc45_28, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc44_38.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc45_28: init %MyResult.21e to %.loc44_38.1 = call %specific_fn.loc45_28.4(%.loc45_28.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_28.1: <bound method> = bound_method %.loc45_28.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc45_28.1: init %empty_tuple.type = call %Destroy.Op.bound.loc45_28.1(%.loc45_28.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_27.1: <bound method> = bound_method %.loc45_27.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc45_27.1: init %empty_tuple.type = call %Destroy.Op.bound.loc45_27.1(%.loc45_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_3.1: <bound method> = bound_method %t.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc45_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc45_3.1(%t.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc45_28 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc45_28.2:
// CHECK:STDOUT:   %.loc45_28.13: ref %.b63 = class_element_access %.loc45_28.2, element1
// CHECK:STDOUT:   %.loc45_28.14: ref %tuple.type.a8a = class_element_access %.loc45_28.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc45_28.2: ref %i32 = tuple_access %.loc45_28.14, element0
// CHECK:STDOUT:   %.loc45_28.15: %i32 = acquire_value %tuple.elem0.loc45_28.2
// CHECK:STDOUT:   %.loc45_29.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call.loc45_29: init %MyResult.21e to %.loc45_29.1 = call %Open.ref.loc45_16(%.loc45_28.15)
// CHECK:STDOUT:   %.loc45_29.2: ref %MyResult.21e = temporary %.loc45_29.1, %Open.call.loc45_29
// CHECK:STDOUT:   %impl.elem2.loc45_30: %.d76 = impl_witness_access constants.%Try.impl_witness.6d2, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc45_30.1: <bound method> = bound_method %.loc45_29.2, %impl.elem2.loc45_30
// CHECK:STDOUT:   %specific_fn.loc45_30.1: <specific function> = specific_function %impl.elem2.loc45_30, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc45_30.2: <bound method> = bound_method %.loc45_29.2, %specific_fn.loc45_30.1
// CHECK:STDOUT:   %.loc45_30.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc45_29.3: %MyResult.21e = acquire_value %.loc45_29.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc45_30: init %ControlFlow.32a to %.loc45_30.1 = call %bound_method.loc45_30.2(%.loc45_29.3)
// CHECK:STDOUT:   %.loc45_30.2: ref %ControlFlow.32a = temporary %.loc45_30.1, %MyResult.as.Try.impl.Branch.call.loc45_30
// CHECK:STDOUT:   %int_1.loc45_30: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc45_30.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc45_30.3: <bound method> = bound_method %int_1.loc45_30, %impl.elem0.loc45_30.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc45_30.2: <specific function> = specific_function %impl.elem0.loc45_30.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc45_30.4: <bound method> = bound_method %int_1.loc45_30, %specific_fn.loc45_30.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc45_30: init %u1 = call %bound_method.loc45_30.4(%int_1.loc45_30) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc45_30.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc45_30 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc45_30.4: %u1 = converted %int_1.loc45_30, %.loc45_30.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc45_30.5: ref %u1 = class_element_access %.loc45_30.2, element0
// CHECK:STDOUT:   %impl.elem0.loc45_30.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc45_30.5: <bound method> = bound_method %.loc45_30.4, %impl.elem0.loc45_30.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc45_30.3: <specific function> = specific_function %impl.elem0.loc45_30.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc45_30.6: <bound method> = bound_method %.loc45_30.4, %specific_fn.loc45_30.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc45_30.6: %u1 = acquire_value %.loc45_30.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc45_30: init bool = call %bound_method.loc45_30.6(%.loc45_30.4, %.loc45_30.6)
// CHECK:STDOUT:   %.loc45_30.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc45_30
// CHECK:STDOUT:   %.loc45_30.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc45_30, %.loc45_30.7
// CHECK:STDOUT:   if %.loc45_30.8 br !.loc45_30.1 else br !.loc45_30.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc45_30.1:
// CHECK:STDOUT:   %.loc45_30.9: ref %.b63 = class_element_access %.loc45_30.2, element1
// CHECK:STDOUT:   %.loc45_30.10: ref %tuple.type.a8a = class_element_access %.loc45_30.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc45_30.1: ref %i32 = tuple_access %.loc45_30.10, element0
// CHECK:STDOUT:   %.loc45_30.11: %i32 = acquire_value %tuple.elem0.loc45_30.1
// CHECK:STDOUT:   %Try.facet.loc45_30: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.6d2) [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %.loc45_30.12: %Try.type = converted constants.%MyResult.21e, %Try.facet.loc45_30 [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %impl.elem3.loc45_30: %.1e7 = impl_witness_access constants.%Try.impl_witness.6d2, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc45_30.4: <specific function> = specific_function %impl.elem3.loc45_30, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc44_38.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc45_30: init %MyResult.21e to %.loc44_38.2 = call %specific_fn.loc45_30.4(%.loc45_30.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_30.1: <bound method> = bound_method %.loc45_30.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc45_30.1: init %empty_tuple.type = call %Destroy.Op.bound.loc45_30.1(%.loc45_30.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_29.1: <bound method> = bound_method %.loc45_29.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc45_29.1: init %empty_tuple.type = call %Destroy.Op.bound.loc45_29.1(%.loc45_29.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_28.2: <bound method> = bound_method %.loc45_28.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc45_28.2: init %empty_tuple.type = call %Destroy.Op.bound.loc45_28.2(%.loc45_28.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_27.2: <bound method> = bound_method %.loc45_27.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc45_27.2: init %empty_tuple.type = call %Destroy.Op.bound.loc45_27.2(%.loc45_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_3.2: <bound method> = bound_method %t.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc45_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc45_3.2(%t.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc45_30 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc45_30.2:
// CHECK:STDOUT:   %.loc45_30.13: ref %.b63 = class_element_access %.loc45_30.2, element1
// CHECK:STDOUT:   %.loc45_30.14: ref %tuple.type.a8a = class_element_access %.loc45_30.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc45_30.2: ref %i32 = tuple_access %.loc45_30.14, element0
// CHECK:STDOUT:   %.loc45_30.15: %i32 = acquire_value %tuple.elem0.loc45_30.2
// CHECK:STDOUT:   %impl.elem0.loc45_30.3: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc45_30.7: <bound method> = bound_method %.loc45_30.15, %impl.elem0.loc45_30.3
// CHECK:STDOUT:   %specific_fn.loc45_30.5: <specific function> = specific_function %impl.elem0.loc45_30.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc45_30.8: <bound method> = bound_method %.loc45_30.15, %specific_fn.loc45_30.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc45_30.8(%.loc45_30.15)
// CHECK:STDOUT:   assign %t.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc45: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %t: ref %i32 = wrapper_binding t, %t.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %t.patt: %pattern_type.6b6 = ref_binding_pattern t [concrete = constants.%t.patt]
// CHECK:STDOUT:     %t.var_patt: %pattern_type.6b6 = var_pattern %t.patt [concrete = constants.%t.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc46: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc46_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc46_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc46: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc46_28: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc46_28 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %t.ref: ref %i32 = name_ref t, %t
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc44_38.3: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc46_32: %i32 = acquire_value %t.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc44_38.3 = call %MyResult.Ok.specific_fn(%.loc46_32)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_30.2: <bound method> = bound_method %.loc45_30.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc45_30.2: init %empty_tuple.type = call %Destroy.Op.bound.loc45_30.2(%.loc45_30.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_29.2: <bound method> = bound_method %.loc45_29.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc45_29.2: init %empty_tuple.type = call %Destroy.Op.bound.loc45_29.2(%.loc45_29.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_28.3: <bound method> = bound_method %.loc45_28.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc45_28.3: init %empty_tuple.type = call %Destroy.Op.bound.loc45_28.3(%.loc45_28.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_27.3: <bound method> = bound_method %.loc45_27.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc45_27.3: init %empty_tuple.type = call %Destroy.Op.bound.loc45_27.3(%.loc45_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc45_3.3: <bound method> = bound_method %t.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc45_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc45_3.3(%t.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Argument(%n.param: %i32) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %i32 = var_storage %v.var_patt
// CHECK:STDOUT:   %Callee.ref: %Callee.type = name_ref Callee, file.%Callee.decl [concrete = constants.%Callee]
// CHECK:STDOUT:   %n.ref.loc52_23: %i32 = name_ref n, %n
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc52_31: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc52_32.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call: init %MyResult.21e to %.loc52_32.1 = call %Open.ref(%n.ref.loc52_31)
// CHECK:STDOUT:   %.loc52_32.2: ref %MyResult.21e = temporary %.loc52_32.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.d76 = impl_witness_access constants.%Try.impl_witness.6d2, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc52_33.1: <bound method> = bound_method %.loc52_32.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc52_33.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc52_33.2: <bound method> = bound_method %.loc52_32.2, %specific_fn.loc52_33.1
// CHECK:STDOUT:   %.loc52_33.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc52_32.3: %MyResult.21e = acquire_value %.loc52_32.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc52_33.1 = call %bound_method.loc52_33.2(%.loc52_32.3)
// CHECK:STDOUT:   %.loc52_33.2: ref %ControlFlow.32a = temporary %.loc52_33.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc52_33.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc52_33.3: <bound method> = bound_method %int_1, %impl.elem0.loc52_33.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc52_33.2: <specific function> = specific_function %impl.elem0.loc52_33.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc52_33.4: <bound method> = bound_method %int_1, %specific_fn.loc52_33.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc52_33.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc52_33.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc52_33.4: %u1 = converted %int_1, %.loc52_33.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc52_33.5: ref %u1 = class_element_access %.loc52_33.2, element0
// CHECK:STDOUT:   %impl.elem0.loc52_33.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc52_33.5: <bound method> = bound_method %.loc52_33.4, %impl.elem0.loc52_33.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc52_33.3: <specific function> = specific_function %impl.elem0.loc52_33.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc52_33.6: <bound method> = bound_method %.loc52_33.4, %specific_fn.loc52_33.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc52_33.6: %u1 = acquire_value %.loc52_33.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc52_33.6(%.loc52_33.4, %.loc52_33.6)
// CHECK:STDOUT:   %.loc52_33.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc52_33.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc52_33.7
// CHECK:STDOUT:   if %.loc52_33.8 br !.loc52_33.1 else br !.loc52_33.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc52_33.1:
// CHECK:STDOUT:   %.loc52_33.9: ref %.b63 = class_element_access %.loc52_33.2, element1
// CHECK:STDOUT:   %.loc52_33.10: ref %tuple.type.a8a = class_element_access %.loc52_33.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc52_33.1: ref %i32 = tuple_access %.loc52_33.10, element0
// CHECK:STDOUT:   %.loc52_33.11: %i32 = acquire_value %tuple.elem0.loc52_33.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.6d2) [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %.loc52_33.12: %Try.type = converted constants.%MyResult.21e, %Try.facet [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %impl.elem3: %.1e7 = impl_witness_access constants.%Try.impl_witness.6d2, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc52_33.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc51_41.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.21e to %.loc51_41.1 = call %specific_fn.loc52_33.4(%.loc52_33.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc52_33.1: <bound method> = bound_method %.loc52_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc52_33.1: init %empty_tuple.type = call %Destroy.Op.bound.loc52_33.1(%.loc52_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc52_32.1: <bound method> = bound_method %.loc52_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc52_32.1: init %empty_tuple.type = call %Destroy.Op.bound.loc52_32.1(%.loc52_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc52_3.1: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc52_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc52_3.1(%v.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc52_33.2:
// CHECK:STDOUT:   %.loc52_33.13: ref %.b63 = class_element_access %.loc52_33.2, element1
// CHECK:STDOUT:   %.loc52_33.14: ref %tuple.type.a8a = class_element_access %.loc52_33.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc52_33.2: ref %i32 = tuple_access %.loc52_33.14, element0
// CHECK:STDOUT:   %.loc52_33.15: %i32 = acquire_value %tuple.elem0.loc52_33.2
// CHECK:STDOUT:   %Callee.call: init %i32 = call %Callee.ref(%n.ref.loc52_23, %.loc52_33.15)
// CHECK:STDOUT:   assign %v.var, %Callee.call
// CHECK:STDOUT:   %i32.loc52: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt.113]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc53: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc53_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc53_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc53: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc53_28: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc53_28 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %v.ref: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc51_41.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc53_32: %i32 = acquire_value %v.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc51_41.2 = call %MyResult.Ok.specific_fn(%.loc53_32)
// CHECK:STDOUT:   %Destroy.Op.bound.loc52_33.2: <bound method> = bound_method %.loc52_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc52_33.2: init %empty_tuple.type = call %Destroy.Op.bound.loc52_33.2(%.loc52_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc52_32.2: <bound method> = bound_method %.loc52_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc52_32.2: init %empty_tuple.type = call %Destroy.Op.bound.loc52_32.2(%.loc52_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc52_3.2: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc52_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc52_3.2(%v.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @InArm(%r.param: %MyResult.21e) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %r.ref: %MyResult.21e = name_ref r, %r
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt.424]
// CHECK:STDOUT:     %.loc62_15: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc62_22.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc62_22.1: <bound method> = bound_method %int_0, %impl.elem0.loc62_22.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc62_22.1: <specific function> = specific_function %impl.elem0.loc62_22.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc62_22.2: <bound method> = bound_method %int_0, %specific_fn.loc62_22.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc62: init %u1 = call %bound_method.loc62_22.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc62_22.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc62 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc62_22.2: %u1 = converted %int_0, %.loc62_22.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc62_22.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc62_22.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc62_22.3: <bound method> = bound_method %.loc62_22.2, %impl.elem0.loc62_22.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc62_22.2: <specific function> = specific_function %impl.elem0.loc62_22.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc62_22.4: <bound method> = bound_method %.loc62_22.2, %specific_fn.loc62_22.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc62_22.4: %u1 = acquire_value %.loc62_22.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc62: init bool = call %bound_method.loc62_22.4(%.loc62_22.2, %.loc62_22.4)
// CHECK:STDOUT:   %.loc62_22.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc62
// CHECK:STDOUT:   %.loc62_22.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc62, %.loc62_22.5
// CHECK:STDOUT:   if %.loc62_22.6 br !match.case.then.loc62 else br !match.case.else.loc62
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc62:
// CHECK:STDOUT:   %.loc62_22.7: ref %.bf4 = class_element_access %r.ref, element1
// CHECK:STDOUT:   %.loc62_22.8: ref %tuple.type.a8a = class_element_access %.loc62_22.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc62: ref %i32 = tuple_access %.loc62_22.8, element0
// CHECK:STDOUT:   %.loc62_22.9: %i32 = acquire_value %tuple.elem0.loc62
// CHECK:STDOUT:   %i32.loc62: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc62_22.9
// CHECK:STDOUT:   %w.var: ref %i32 = var_storage %w.var_patt
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %v.ref: %i32 = name_ref v, %v
// CHECK:STDOUT:   %.loc63_26.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call: init %MyResult.21e to %.loc63_26.1 = call %Open.ref(%v.ref)
// CHECK:STDOUT:   %.loc63_26.2: ref %MyResult.21e = temporary %.loc63_26.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.d76 = impl_witness_access constants.%Try.impl_witness.6d2, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc63_27.1: <bound method> = bound_method %.loc63_26.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc63_27.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc63_27.2: <bound method> = bound_method %.loc63_26.2, %specific_fn.loc63_27.1
// CHECK:STDOUT:   %.loc63_27.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc63_26.3: %MyResult.21e = acquire_value %.loc63_26.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc63_27.1 = call %bound_method.loc63_27.2(%.loc63_26.3)
// CHECK:STDOUT:   %.loc63_27.2: ref %ControlFlow.32a = temporary %.loc63_27.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc63: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc63_27.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc63_27.3: <bound method> = bound_method %int_1.loc63, %impl.elem0.loc63_27.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc63_27.2: <specific function> = specific_function %impl.elem0.loc63_27.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc63_27.4: <bound method> = bound_method %int_1.loc63, %specific_fn.loc63_27.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc63: init %u1 = call %bound_method.loc63_27.4(%int_1.loc63) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc63_27.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc63 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc63_27.4: %u1 = converted %int_1.loc63, %.loc63_27.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc63_27.5: ref %u1 = class_element_access %.loc63_27.2, element0
// CHECK:STDOUT:   %impl.elem0.loc63_27.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc63_27.5: <bound method> = bound_method %.loc63_27.4, %impl.elem0.loc63_27.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc63_27.3: <specific function> = specific_function %impl.elem0.loc63_27.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc63_27.6: <bound method> = bound_method %.loc63_27.4, %specific_fn.loc63_27.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc63_27.6: %u1 = acquire_value %.loc63_27.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc63: init bool = call %bound_method.loc63_27.6(%.loc63_27.4, %.loc63_27.6)
// CHECK:STDOUT:   %.loc63_27.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc63
// CHECK:STDOUT:   %.loc63_27.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc63, %.loc63_27.7
// CHECK:STDOUT:   if %.loc63_27.8 br !.loc63_27.1 else br !.loc63_27.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc63_27.1:
// CHECK:STDOUT:   %.loc63_27.9: ref %.b63 = class_element_access %.loc63_27.2, element1
// CHECK:STDOUT:   %.loc63_27.10: ref %tuple.type.a8a = class_element_access %.loc63_27.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc63_27.1: ref %i32 = tuple_access %.loc63_27.10, element0
// CHECK:STDOUT:   %.loc63_27.11: %i32 = acquire_value %tuple.elem0.loc63_27.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.6d2) [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %.loc63_27.12: %Try.type = converted constants.%MyResult.21e, %Try.facet [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %impl.elem3: %.1e7 = impl_witness_access constants.%Try.impl_witness.6d2, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc63_27.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc60_53.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.21e to %.loc60_53.1 = call %specific_fn.loc63_27.4(%.loc63_27.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc63_27.1: <bound method> = bound_method %.loc63_27.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc63_27.1: init %empty_tuple.type = call %Destroy.Op.bound.loc63_27.1(%.loc63_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc63_26.1: <bound method> = bound_method %.loc63_26.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc63_26.1: init %empty_tuple.type = call %Destroy.Op.bound.loc63_26.1(%.loc63_26.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc63_7.1: <bound method> = bound_method %w.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc63_7.1: init %empty_tuple.type = call %Destroy.Op.bound.loc63_7.1(%w.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc63_27.2:
// CHECK:STDOUT:   %.loc63_27.13: ref %.b63 = class_element_access %.loc63_27.2, element1
// CHECK:STDOUT:   %.loc63_27.14: ref %tuple.type.a8a = class_element_access %.loc63_27.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc63_27.2: ref %i32 = tuple_access %.loc63_27.14, element0
// CHECK:STDOUT:   %.loc63_27.15: %i32 = acquire_value %tuple.elem0.loc63_27.2
// CHECK:STDOUT:   %impl.elem0.loc63_27.3: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc63_27.7: <bound method> = bound_method %.loc63_27.15, %impl.elem0.loc63_27.3
// CHECK:STDOUT:   %specific_fn.loc63_27.5: <specific function> = specific_function %impl.elem0.loc63_27.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc63_27.8: <bound method> = bound_method %.loc63_27.15, %specific_fn.loc63_27.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc63_27.8(%.loc63_27.15)
// CHECK:STDOUT:   assign %w.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc63: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %w: ref %i32 = wrapper_binding w, %w.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %w.patt: %pattern_type.6b6 = ref_binding_pattern w [concrete = constants.%w.patt]
// CHECK:STDOUT:     %w.var_patt: %pattern_type.6b6 = var_pattern %w.patt [concrete = constants.%w.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc64: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc64_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc64_28: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc64: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc64_32: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc64_32 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %w.ref: ref %i32 = name_ref w, %w
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc60_53.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc64_36: %i32 = acquire_value %w.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc60_53.2 = call %MyResult.Ok.specific_fn(%.loc64_36)
// CHECK:STDOUT:   %Destroy.Op.bound.loc63_27.2: <bound method> = bound_method %.loc63_27.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc63_27.2: init %empty_tuple.type = call %Destroy.Op.bound.loc63_27.2(%.loc63_27.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc63_26.2: <bound method> = bound_method %.loc63_26.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc63_26.2: init %empty_tuple.type = call %Destroy.Op.bound.loc63_26.2(%.loc63_26.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc63_7.2: <bound method> = bound_method %w.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc63_7.2: init %empty_tuple.type = call %Destroy.Op.bound.loc63_7.2(%w.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc62:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %e.patt: %pattern_type.6b6 = value_binding_pattern e [concrete = constants.%e.patt.2e6]
// CHECK:STDOUT:     %.loc66_16: %pattern_type.e71 = tuple_pattern (%e.patt) [concrete = constants.%.37b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc66: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc66_23.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc66_23.1: <bound method> = bound_method %int_1.loc66, %impl.elem0.loc66_23.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc66_23.1: <specific function> = specific_function %impl.elem0.loc66_23.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc66_23.2: <bound method> = bound_method %int_1.loc66, %specific_fn.loc66_23.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc66: init %u1 = call %bound_method.loc66_23.2(%int_1.loc66) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc66_23.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc66 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc66_23.2: %u1 = converted %int_1.loc66, %.loc66_23.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc66_23.3: ref %u1 = class_element_access %r.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc66_23.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc66_23.3: <bound method> = bound_method %.loc66_23.2, %impl.elem0.loc66_23.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc66_23.2: <specific function> = specific_function %impl.elem0.loc66_23.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc66_23.4: <bound method> = bound_method %.loc66_23.2, %specific_fn.loc66_23.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc66_23.4: %u1 = acquire_value %.loc66_23.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc66: init bool = call %bound_method.loc66_23.4(%.loc66_23.2, %.loc66_23.4)
// CHECK:STDOUT:   %.loc66_23.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc66
// CHECK:STDOUT:   %.loc66_23.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc66, %.loc66_23.5
// CHECK:STDOUT:   if %.loc66_23.6 br !match.case.then.loc66 else br !match.case.else.loc66
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc66:
// CHECK:STDOUT:   %.loc66_23.7: ref %.bf4 = class_element_access %r.ref, element1
// CHECK:STDOUT:   %.loc66_23.8: ref %tuple.type.a8a = class_element_access %.loc66_23.7, element1
// CHECK:STDOUT:   %tuple.elem0.loc66: ref %i32 = tuple_access %.loc66_23.8, element0
// CHECK:STDOUT:   %.loc66_23.9: %i32 = acquire_value %tuple.elem0.loc66
// CHECK:STDOUT:   %i32.loc66_18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %e: %i32 = wrapper_binding e, %.loc66_23.9
// CHECK:STDOUT:   %MyResult.ref.loc66: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc66_44: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc66_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc66: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc66_53: %MyResult.Err.type.6f5 = specific_constant generated.%MyResult.Err.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Err.8b7]
// CHECK:STDOUT:   %Err.ref: %MyResult.Err.type.6f5 = name_ref Err, %.loc66_53 [concrete = constants.%MyResult.Err.8b7]
// CHECK:STDOUT:   %e.ref: %i32 = name_ref e, %e
// CHECK:STDOUT:   %MyResult.Err.specific_fn: <specific function> = specific_function %Err.ref, @MyResult.Err(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Err.specific_fn.24b]
// CHECK:STDOUT:   %.loc60_53.3: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.Err.call: init %MyResult.21e to %.loc60_53.3 = call %MyResult.Err.specific_fn(%e.ref)
// CHECK:STDOUT:   return %MyResult.Err.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc66:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @InIfExpr(%n.param: %i32, %c.param: bool) -> out %return.param: %MyResult.21e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %i32 = var_storage %v.var_patt
// CHECK:STDOUT:   %c.ref: bool = name_ref c, %c
// CHECK:STDOUT:   if %c.ref br !if.expr.then else br !if.expr.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.expr.then:
// CHECK:STDOUT:   %Open.ref.loc73_26: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc73_31: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc73_32.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %Open.call.loc73_32: init %MyResult.21e to %.loc73_32.1 = call %Open.ref.loc73_26(%n.ref.loc73_31)
// CHECK:STDOUT:   %.loc73_32.2: ref %MyResult.21e = temporary %.loc73_32.1, %Open.call.loc73_32
// CHECK:STDOUT:   %impl.elem2.loc73_33: %.d76 = impl_witness_access constants.%Try.impl_witness.6d2, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc73_33.1: <bound method> = bound_method %.loc73_32.2, %impl.elem2.loc73_33
// CHECK:STDOUT:   %specific_fn.loc73_33.1: <specific function> = specific_function %impl.elem2.loc73_33, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc73_33.2: <bound method> = bound_method %.loc73_32.2, %specific_fn.loc73_33.1
// CHECK:STDOUT:   %.loc73_33.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc73_32.3: %MyResult.21e = acquire_value %.loc73_32.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc73_33: init %ControlFlow.32a to %.loc73_33.1 = call %bound_method.loc73_33.2(%.loc73_32.3)
// CHECK:STDOUT:   %.loc73_33.2: ref %ControlFlow.32a = temporary %.loc73_33.1, %MyResult.as.Try.impl.Branch.call.loc73_33
// CHECK:STDOUT:   %int_1.loc73_33: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc73_33.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc73_33.3: <bound method> = bound_method %int_1.loc73_33, %impl.elem0.loc73_33.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc73_33.2: <specific function> = specific_function %impl.elem0.loc73_33.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc73_33.4: <bound method> = bound_method %int_1.loc73_33, %specific_fn.loc73_33.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc73_33: init %u1 = call %bound_method.loc73_33.4(%int_1.loc73_33) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc73_33.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc73_33 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc73_33.4: %u1 = converted %int_1.loc73_33, %.loc73_33.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc73_33.5: ref %u1 = class_element_access %.loc73_33.2, element0
// CHECK:STDOUT:   %impl.elem0.loc73_33.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc73_33.5: <bound method> = bound_method %.loc73_33.4, %impl.elem0.loc73_33.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc73_33.3: <specific function> = specific_function %impl.elem0.loc73_33.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc73_33.6: <bound method> = bound_method %.loc73_33.4, %specific_fn.loc73_33.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc73_33.6: %u1 = acquire_value %.loc73_33.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc73_33: init bool = call %bound_method.loc73_33.6(%.loc73_33.4, %.loc73_33.6)
// CHECK:STDOUT:   %.loc73_33.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc73_33
// CHECK:STDOUT:   %.loc73_33.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc73_33, %.loc73_33.7
// CHECK:STDOUT:   if %.loc73_33.8 br !.loc73_33.1 else br !.loc73_33.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc73_33.1:
// CHECK:STDOUT:   %.loc73_33.9: ref %.b63 = class_element_access %.loc73_33.2, element1
// CHECK:STDOUT:   %.loc73_33.10: ref %tuple.type.a8a = class_element_access %.loc73_33.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc73_33.1: ref %i32 = tuple_access %.loc73_33.10, element0
// CHECK:STDOUT:   %.loc73_33.11: %i32 = acquire_value %tuple.elem0.loc73_33.1
// CHECK:STDOUT:   %Try.facet.loc73_33: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.6d2) [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %.loc73_33.12: %Try.type = converted constants.%MyResult.21e, %Try.facet.loc73_33 [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %impl.elem3.loc73_33: %.1e7 = impl_witness_access constants.%Try.impl_witness.6d2, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc73_33.4: <specific function> = specific_function %impl.elem3.loc73_33, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc72_50.1: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc73_33: init %MyResult.21e to %.loc72_50.1 = call %specific_fn.loc73_33.4(%.loc73_33.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_33.1: <bound method> = bound_method %.loc73_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc73_33.1: init %empty_tuple.type = call %Destroy.Op.bound.loc73_33.1(%.loc73_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_32.1: <bound method> = bound_method %.loc73_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc73_32.1: init %empty_tuple.type = call %Destroy.Op.bound.loc73_32.1(%.loc73_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_3.1: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc73_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc73_3.1(%v.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc73_33 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc73_33.2:
// CHECK:STDOUT:   %.loc73_33.13: ref %.b63 = class_element_access %.loc73_33.2, element1
// CHECK:STDOUT:   %.loc73_33.14: ref %tuple.type.a8a = class_element_access %.loc73_33.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc73_33.2: ref %i32 = tuple_access %.loc73_33.14, element0
// CHECK:STDOUT:   %.loc73_33.15: %i32 = acquire_value %tuple.elem0.loc73_33.2
// CHECK:STDOUT:   br !if.expr.result(%.loc73_33.15)
// CHECK:STDOUT:
// CHECK:STDOUT: !if.expr.else:
// CHECK:STDOUT:   %Open.ref.loc73_40: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc73_45: %i32 = name_ref n, %n
// CHECK:STDOUT:   %int_1.loc73_49: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.0d8 = impl_witness_access constants.%AddWith.impl_witness.3ff, element1 [concrete = constants.%Int.as.AddWith.impl.Op.b91858.2]
// CHECK:STDOUT:   %bound_method.loc73_47.1: <bound method> = bound_method %n.ref.loc73_45, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc73_47: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.0618ee.1]
// CHECK:STDOUT:   %bound_method.loc73_47.2: <bound method> = bound_method %n.ref.loc73_45, %specific_fn.loc73_47
// CHECK:STDOUT:   %.loc73_47.1: %Int.as.AddWith.impl.Op.type.720bef.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.AddWith.impl.Op.b91858.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.720bef.1 = name_ref Op, %.loc73_47.1 [concrete = constants.%Int.as.AddWith.impl.Op.b91858.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %n.ref.loc73_45, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.9f1) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.0618ee.2]
// CHECK:STDOUT:   %bound_method.loc73_47.3: <bound method> = bound_method %n.ref.loc73_45, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc73_49: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc73_49.1: <bound method> = bound_method %int_1.loc73_49, %impl.elem0.loc73_49 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc73_49: <specific function> = specific_function %impl.elem0.loc73_49, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc73_49.2: <bound method> = bound_method %int_1.loc73_49, %specific_fn.loc73_49 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc73_49: init %i32 = call %bound_method.loc73_49.2(%int_1.loc73_49) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc73_49.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc73_49 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc73_49.2: %i32 = converted %int_1.loc73_49, %.loc73_49.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc73_47.3(%n.ref.loc73_45, %.loc73_49.2)
// CHECK:STDOUT:   %.loc73_50.1: ref %MyResult.21e = temporary_storage
// CHECK:STDOUT:   %.loc73_47.2: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc73_47.3: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc73_47.2
// CHECK:STDOUT:   %Open.call.loc73_50: init %MyResult.21e to %.loc73_50.1 = call %Open.ref.loc73_40(%.loc73_47.3)
// CHECK:STDOUT:   %.loc73_50.2: ref %MyResult.21e = temporary %.loc73_50.1, %Open.call.loc73_50
// CHECK:STDOUT:   %impl.elem2.loc73_51: %.d76 = impl_witness_access constants.%Try.impl_witness.6d2, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc73_51.1: <bound method> = bound_method %.loc73_50.2, %impl.elem2.loc73_51
// CHECK:STDOUT:   %specific_fn.loc73_51.1: <specific function> = specific_function %impl.elem2.loc73_51, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc73_51.2: <bound method> = bound_method %.loc73_50.2, %specific_fn.loc73_51.1
// CHECK:STDOUT:   %.loc73_51.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc73_50.3: %MyResult.21e = acquire_value %.loc73_50.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc73_51: init %ControlFlow.32a to %.loc73_51.1 = call %bound_method.loc73_51.2(%.loc73_50.3)
// CHECK:STDOUT:   %.loc73_51.2: ref %ControlFlow.32a = temporary %.loc73_51.1, %MyResult.as.Try.impl.Branch.call.loc73_51
// CHECK:STDOUT:   %int_1.loc73_51: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc73_51.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc73_51.3: <bound method> = bound_method %int_1.loc73_51, %impl.elem0.loc73_51.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc73_51.2: <specific function> = specific_function %impl.elem0.loc73_51.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc73_51.4: <bound method> = bound_method %int_1.loc73_51, %specific_fn.loc73_51.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc73_51: init %u1 = call %bound_method.loc73_51.4(%int_1.loc73_51) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc73_51.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc73_51 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc73_51.4: %u1 = converted %int_1.loc73_51, %.loc73_51.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc73_51.5: ref %u1 = class_element_access %.loc73_51.2, element0
// CHECK:STDOUT:   %impl.elem0.loc73_51.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc73_51.5: <bound method> = bound_method %.loc73_51.4, %impl.elem0.loc73_51.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc73_51.3: <specific function> = specific_function %impl.elem0.loc73_51.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc73_51.6: <bound method> = bound_method %.loc73_51.4, %specific_fn.loc73_51.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc73_51.6: %u1 = acquire_value %.loc73_51.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc73_51: init bool = call %bound_method.loc73_51.6(%.loc73_51.4, %.loc73_51.6)
// CHECK:STDOUT:   %.loc73_51.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc73_51
// CHECK:STDOUT:   %.loc73_51.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc73_51, %.loc73_51.7
// CHECK:STDOUT:   if %.loc73_51.8 br !.loc73_51.1 else br !.loc73_51.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc73_51.1:
// CHECK:STDOUT:   %.loc73_51.9: ref %.b63 = class_element_access %.loc73_51.2, element1
// CHECK:STDOUT:   %.loc73_51.10: ref %tuple.type.a8a = class_element_access %.loc73_51.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc73_51.1: ref %i32 = tuple_access %.loc73_51.10, element0
// CHECK:STDOUT:   %.loc73_51.11: %i32 = acquire_value %tuple.elem0.loc73_51.1
// CHECK:STDOUT:   %Try.facet.loc73_51: %Try.type = facet_value constants.%MyResult.21e, (constants.%Try.impl_witness.6d2) [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %.loc73_51.12: %Try.type = converted constants.%MyResult.21e, %Try.facet.loc73_51 [concrete = constants.%Try.facet.7da]
// CHECK:STDOUT:   %impl.elem3.loc73_51: %.1e7 = impl_witness_access constants.%Try.impl_witness.6d2, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.c92]
// CHECK:STDOUT:   %specific_fn.loc73_51.4: <specific function> = specific_function %impl.elem3.loc73_51, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc72_50.2: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc73_51: init %MyResult.21e to %.loc72_50.2 = call %specific_fn.loc73_51.4(%.loc73_51.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_51.1: <bound method> = bound_method %.loc73_51.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc73_51.1: init %empty_tuple.type = call %Destroy.Op.bound.loc73_51.1(%.loc73_51.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_50.1: <bound method> = bound_method %.loc73_50.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc73_50.1: init %empty_tuple.type = call %Destroy.Op.bound.loc73_50.1(%.loc73_50.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_33.2: <bound method> = bound_method %.loc73_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc73_33.2: init %empty_tuple.type = call %Destroy.Op.bound.loc73_33.2(%.loc73_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_32.2: <bound method> = bound_method %.loc73_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc73_32.2: init %empty_tuple.type = call %Destroy.Op.bound.loc73_32.2(%.loc73_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_3.2: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc73_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc73_3.2(%v.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc73_51 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc73_51.2:
// CHECK:STDOUT:   %.loc73_51.13: ref %.b63 = class_element_access %.loc73_51.2, element1
// CHECK:STDOUT:   %.loc73_51.14: ref %tuple.type.a8a = class_element_access %.loc73_51.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc73_51.2: ref %i32 = tuple_access %.loc73_51.14, element0
// CHECK:STDOUT:   %.loc73_51.15: %i32 = acquire_value %tuple.elem0.loc73_51.2
// CHECK:STDOUT:   br !if.expr.result(%.loc73_51.15)
// CHECK:STDOUT:
// CHECK:STDOUT: !if.expr.result:
// CHECK:STDOUT:   %.loc73_16: %i32 = block_arg !if.expr.result
// CHECK:STDOUT:   %impl.elem0.loc73_16: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc73_16.1: <bound method> = bound_method %.loc73_16, %impl.elem0.loc73_16
// CHECK:STDOUT:   %specific_fn.loc73_16: <specific function> = specific_function %impl.elem0.loc73_16, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc73_16.2: <bound method> = bound_method %.loc73_16, %specific_fn.loc73_16
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc73_16.2(%.loc73_16)
// CHECK:STDOUT:   assign %v.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc73: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt.113]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc74: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc74_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc74_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc74: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:   %.loc74_28: %MyResult.Ok.type.94a = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.94a = name_ref Ok, %.loc74_28 [concrete = constants.%MyResult.Ok.de7]
// CHECK:STDOUT:   %v.ref: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc72_50.3: ref %MyResult.21e = splice_block %return.param {}
// CHECK:STDOUT:   %.loc74_32: %i32 = acquire_value %v.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.21e to %.loc72_50.3 = call %MyResult.Ok.specific_fn(%.loc74_32)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_51.2: <bound method> = bound_method %.loc73_51.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc73_51.2: init %empty_tuple.type = call %Destroy.Op.bound.loc73_51.2(%.loc73_51.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_50.2: <bound method> = bound_method %.loc73_50.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc73_50.2: init %empty_tuple.type = call %Destroy.Op.bound.loc73_50.2(%.loc73_50.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_33.3: <bound method> = bound_method %.loc73_33.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc73_33.3: init %empty_tuple.type = call %Destroy.Op.bound.loc73_33.3(%.loc73_33.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_32.3: <bound method> = bound_method %.loc73_32.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc73_32.3: init %empty_tuple.type = call %Destroy.Op.bound.loc73_32.3(%.loc73_32.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc73_3.3: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc73_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc73_3.3(%v.var)
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
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
// CHECK:STDOUT:   %Try.impl_witness.852: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i64, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type.e04: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%i64, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.871: %MyResult.as.Try.impl.Branch.type.e04 = struct_value () [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type.5c3: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%i64, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.ae9: %MyResult.as.Try.impl.FromBreak.type.5c3 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.impl_witness.6d2: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type.dbd: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.b50: %MyResult.as.Try.impl.Branch.type.dbd = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.7da: %Try.type = facet_value %MyResult.21e, (%Try.impl_witness.6d2) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.a49: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.7da) [concrete]
// CHECK:STDOUT:   %.d76: type = fn_type_with_self_type %Try.WithSelf.Branch.type.a49, %Try.facet.7da [concrete]
// CHECK:STDOUT:   %ControlFlow.32a: type = class_type @ControlFlow, @ControlFlow(%i32, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn.1fe: <specific function> = specific_function %MyResult.as.Try.impl.Branch.b50, @MyResult.as.Try.impl.Branch(%i32, %i32) [concrete]
// CHECK:STDOUT:   %.b63: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.88b: type = struct_type {.discriminant: %u1, .payload: %.b63} [concrete]
// CHECK:STDOUT:   %Try.facet.1d6: %Try.type = facet_value %MyResult.964, (%Try.impl_witness.852) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.cb8: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.1d6) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.0f6: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.1d6) [concrete]
// CHECK:STDOUT:   %.51d: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.0f6, %Try.facet.1d6 [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak.ae9, @MyResult.as.Try.impl.FromBreak(%i64, %i32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc25_17.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc25_17.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.287: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %y.patt: %pattern_type.f57 = ref_binding_pattern y [concrete]
// CHECK:STDOUT:   %y.var_patt: %pattern_type.f57 = var_pattern %y.patt [concrete]
// CHECK:STDOUT:   %.579: type = fn_type_with_self_type %Try.WithSelf.Branch.type.cb8, %Try.facet.1d6 [concrete]
// CHECK:STDOUT:   %ControlFlow.3df: type = class_type @ControlFlow, @ControlFlow(%i64, %i32) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn.019: <specific function> = specific_function %MyResult.as.Try.impl.Branch.871, @MyResult.as.Try.impl.Branch(%i64, %i32) [concrete]
// CHECK:STDOUT:   %.75f: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.f67, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.c1f: type = struct_type {.discriminant: %u1, .payload: %.75f} [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.10: type = fn_type @Destroy.Op.loc26_17.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.10: %Destroy.Op.type.1d8f74.10 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.14: type = fn_type @Destroy.Op.loc26_17.6 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.14: %Destroy.Op.type.1d8f74.14 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.c5e: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.b84: %Copy.type = facet_value %i64, (%Copy.impl_witness.c5e) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.70a: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.b84) [concrete]
// CHECK:STDOUT:   %.3cb: type = fn_type_with_self_type %Copy.WithSelf.Op.type.70a, %Copy.facet.b84 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.b95: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT:   %As.type.998: type = facet_type <@As, @As(%i64)> [concrete]
// CHECK:STDOUT:   %To.d23: Core.IntLiteral = symbolic_binding To, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.type.a00: type = fn_type @Int.as.As.impl.Convert.2, @Int.as.As.impl.c50(%From.fe9, %To.d23) [symbolic]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.3b9: %Int.as.As.impl.Convert.type.a00 = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.40c: <witness> = impl_witness imports.%As.impl_witness_table.72c, @Int.as.As.impl.c50(%int_32, %int_64) [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.type.430: type = fn_type @Int.as.As.impl.Convert.2, @Int.as.As.impl.c50(%int_32, %int_64) [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.9d1: %Int.as.As.impl.Convert.type.430 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.998 = facet_value %i32, (%As.impl_witness.40c) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.6f8: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i64, %As.facet) [concrete]
// CHECK:STDOUT:   %.6c4: type = fn_type_with_self_type %As.WithSelf.Convert.type.6f8, %As.facet [concrete]
// CHECK:STDOUT:   %Int.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Int.as.As.impl.Convert.9d1, @Int.as.As.impl.Convert.2(%int_32, %int_64) [concrete]
// CHECK:STDOUT:   %AddWith.type.313: type = facet_type <@AddWith, @AddWith(%i64)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.2f5: <witness> = impl_witness imports.%AddWith.impl_witness_table.9d9, @Int.as.AddWith.impl.3af(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.6b6: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.e5a: %Int.as.AddWith.impl.Op.type.6b6 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.6cd: %AddWith.type.313 = facet_value %i64, (%AddWith.impl_witness.2f5) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.04f: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i64, %AddWith.facet.6cd) [concrete]
// CHECK:STDOUT:   %.875: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.04f, %AddWith.facet.6cd [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f02: <specific function> = specific_function %Int.as.AddWith.impl.Op.e5a, @Int.as.AddWith.impl.Op.1(%int_64) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %MyResult.Ok.f46, @MyResult.Ok(%i64, %i32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.a86: @Int.as.As.impl.c50.%Int.as.As.impl.Convert.type (%Int.as.As.impl.Convert.type.a00) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.As.impl.c50.%Int.as.As.impl.Convert (constants.%Int.as.As.impl.Convert.3b9)]
// CHECK:STDOUT:   %As.impl_witness_table.72c = impl_witness_table (%Core.import_ref.a86), @Int.as.As.impl.c50 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6842: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.9d9 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.6842), @Int.as.AddWith.impl.3af [concrete]
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
// CHECK:STDOUT:     %return.patt: %pattern_type.99b = return_slot_pattern %return.param_patt, %MyResult.loc24_75 [concrete = constants.%return.patt.1d9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc24_58: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i64.loc24_67: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %i32.loc24_72: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %MyResult.loc24_75: type = class_type @MyResult, @MyResult(constants.%i64, constants.%i32) [concrete = constants.%MyResult.964]
// CHECK:STDOUT:     %.loc24_75.4: Core.Form = init_form %MyResult.loc24_75 [concrete = constants.%.b38bf]
// CHECK:STDOUT:     %a.param: %MyResult.21e = value_param call_param0
// CHECK:STDOUT:     %.loc24_29: type = splice_block %MyResult.loc24_29 [concrete = constants.%MyResult.21e] {
// CHECK:STDOUT:       %MyResult.ref.loc24_12: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %i32.loc24_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc24_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %MyResult.loc24_29: type = class_type @MyResult, @MyResult(constants.%i32, constants.%i32) [concrete = constants.%MyResult.21e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: %MyResult.21e = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %MyResult.964 = value_param call_param1
// CHECK:STDOUT:     %.loc24_52: type = splice_block %MyResult.loc24_52 [concrete = constants.%MyResult.964] {
// CHECK:STDOUT:       %MyResult.ref.loc24_35: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:       %i64.loc24_44: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %i32.loc24_49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %MyResult.loc24_52: type = class_type @MyResult, @MyResult(constants.%i64, constants.%i32) [concrete = constants.%MyResult.964]
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
// CHECK:STDOUT:   %impl.elem2.loc25: %.d76 = impl_witness_access constants.%Try.impl_witness.6d2, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.b50]
// CHECK:STDOUT:   %bound_method.loc25_17.1: <bound method> = bound_method %a.ref, %impl.elem2.loc25
// CHECK:STDOUT:   %specific_fn.loc25_17.1: <specific function> = specific_function %impl.elem2.loc25, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn.1fe]
// CHECK:STDOUT:   %bound_method.loc25_17.2: <bound method> = bound_method %a.ref, %specific_fn.loc25_17.1
// CHECK:STDOUT:   %.loc25_17.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc25: init %ControlFlow.32a to %.loc25_17.1 = call %bound_method.loc25_17.2(%a.ref)
// CHECK:STDOUT:   %.loc25_17.2: ref %ControlFlow.32a = temporary %.loc25_17.1, %MyResult.as.Try.impl.Branch.call.loc25
// CHECK:STDOUT:   %int_1.loc25: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc25_17.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc25_17.3: <bound method> = bound_method %int_1.loc25, %impl.elem0.loc25_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc25_17.2: <specific function> = specific_function %impl.elem0.loc25_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc25_17.4: <bound method> = bound_method %int_1.loc25, %specific_fn.loc25_17.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25: init %u1 = call %bound_method.loc25_17.4(%int_1.loc25) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_17.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_17.4: %u1 = converted %int_1.loc25, %.loc25_17.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc25_17.5: ref %u1 = class_element_access %.loc25_17.2, element0
// CHECK:STDOUT:   %impl.elem0.loc25_17.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc25_17.5: <bound method> = bound_method %.loc25_17.4, %impl.elem0.loc25_17.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc25_17.3: <specific function> = specific_function %impl.elem0.loc25_17.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc25_17.6: <bound method> = bound_method %.loc25_17.4, %specific_fn.loc25_17.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc25_17.6: %u1 = acquire_value %.loc25_17.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc25: init bool = call %bound_method.loc25_17.6(%.loc25_17.4, %.loc25_17.6)
// CHECK:STDOUT:   %.loc25_17.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc25
// CHECK:STDOUT:   %.loc25_17.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc25, %.loc25_17.7
// CHECK:STDOUT:   if %.loc25_17.8 br !.loc25_17.1 else br !.loc25_17.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc25_17.1:
// CHECK:STDOUT:   %.loc25_17.9: ref %.b63 = class_element_access %.loc25_17.2, element1
// CHECK:STDOUT:   %.loc25_17.10: ref %tuple.type.a8a = class_element_access %.loc25_17.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc25_17.1: ref %i32 = tuple_access %.loc25_17.10, element0
// CHECK:STDOUT:   %.loc25_17.11: %i32 = acquire_value %tuple.elem0.loc25_17.1
// CHECK:STDOUT:   %Try.facet.loc25: %Try.type = facet_value constants.%MyResult.964, (constants.%Try.impl_witness.852) [concrete = constants.%Try.facet.1d6]
// CHECK:STDOUT:   %.loc25_17.12: %Try.type = converted constants.%MyResult.964, %Try.facet.loc25 [concrete = constants.%Try.facet.1d6]
// CHECK:STDOUT:   %impl.elem3.loc25: %.51d = impl_witness_access constants.%Try.impl_witness.852, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.ae9]
// CHECK:STDOUT:   %specific_fn.loc25_17.4: <specific function> = specific_function %impl.elem3.loc25, @MyResult.as.Try.impl.FromBreak(constants.%i64, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc24_75.1: ref %MyResult.964 = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc25: init %MyResult.964 to %.loc24_75.1 = call %specific_fn.loc25_17.4(%.loc25_17.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc25_17.1: <bound method> = bound_method %.loc25_17.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc25_17.1: init %empty_tuple.type = call %Destroy.Op.bound.loc25_17.1(%.loc25_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc25_3.1: <bound method> = bound_method %x.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc25_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc25_3.1(%x.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc25 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc25_17.2:
// CHECK:STDOUT:   %.loc25_17.13: ref %.b63 = class_element_access %.loc25_17.2, element1
// CHECK:STDOUT:   %.loc25_17.14: ref %tuple.type.a8a = class_element_access %.loc25_17.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc25_17.2: ref %i32 = tuple_access %.loc25_17.14, element0
// CHECK:STDOUT:   %.loc25_17.15: %i32 = acquire_value %tuple.elem0.loc25_17.2
// CHECK:STDOUT:   %impl.elem0.loc25_17.3: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc25_17.7: <bound method> = bound_method %.loc25_17.15, %impl.elem0.loc25_17.3
// CHECK:STDOUT:   %specific_fn.loc25_17.5: <specific function> = specific_function %impl.elem0.loc25_17.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:   %bound_method.loc25_17.8: <bound method> = bound_method %.loc25_17.15, %specific_fn.loc25_17.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc25: init %i32 = call %bound_method.loc25_17.8(%.loc25_17.15)
// CHECK:STDOUT:   assign %x.var, %Int.as.Copy.impl.Op.call.loc25
// CHECK:STDOUT:   %i32.loc25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %x: ref %i32 = wrapper_binding x, %x.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = ref_binding_pattern x [concrete = constants.%x.patt]
// CHECK:STDOUT:     %x.var_patt: %pattern_type.6b6 = var_pattern %x.patt [concrete = constants.%x.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %y.var: ref %i64 = var_storage %y.var_patt
// CHECK:STDOUT:   %b.ref: %MyResult.964 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem2.loc26: %.579 = impl_witness_access constants.%Try.impl_witness.852, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.871]
// CHECK:STDOUT:   %bound_method.loc26_17.1: <bound method> = bound_method %b.ref, %impl.elem2.loc26
// CHECK:STDOUT:   %specific_fn.loc26_17.1: <specific function> = specific_function %impl.elem2.loc26, @MyResult.as.Try.impl.Branch(constants.%i64, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn.019]
// CHECK:STDOUT:   %bound_method.loc26_17.2: <bound method> = bound_method %b.ref, %specific_fn.loc26_17.1
// CHECK:STDOUT:   %.loc26_17.1: ref %ControlFlow.3df = temporary_storage
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call.loc26: init %ControlFlow.3df to %.loc26_17.1 = call %bound_method.loc26_17.2(%b.ref)
// CHECK:STDOUT:   %.loc26_17.2: ref %ControlFlow.3df = temporary %.loc26_17.1, %MyResult.as.Try.impl.Branch.call.loc26
// CHECK:STDOUT:   %int_1.loc26: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc26_17.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc26_17.3: <bound method> = bound_method %int_1.loc26, %impl.elem0.loc26_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc26_17.2: <specific function> = specific_function %impl.elem0.loc26_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc26_17.4: <bound method> = bound_method %int_1.loc26, %specific_fn.loc26_17.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26: init %u1 = call %bound_method.loc26_17.4(%int_1.loc26) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_17.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_17.4: %u1 = converted %int_1.loc26, %.loc26_17.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_17.5: ref %u1 = class_element_access %.loc26_17.2, element0
// CHECK:STDOUT:   %impl.elem0.loc26_17.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc26_17.5: <bound method> = bound_method %.loc26_17.4, %impl.elem0.loc26_17.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc26_17.3: <specific function> = specific_function %impl.elem0.loc26_17.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc26_17.6: <bound method> = bound_method %.loc26_17.4, %specific_fn.loc26_17.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc26_17.6: %u1 = acquire_value %.loc26_17.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc26: init bool = call %bound_method.loc26_17.6(%.loc26_17.4, %.loc26_17.6)
// CHECK:STDOUT:   %.loc26_17.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc26
// CHECK:STDOUT:   %.loc26_17.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc26, %.loc26_17.7
// CHECK:STDOUT:   if %.loc26_17.8 br !.loc26_17.1 else br !.loc26_17.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc26_17.1:
// CHECK:STDOUT:   %.loc26_17.9: ref %.75f = class_element_access %.loc26_17.2, element1
// CHECK:STDOUT:   %.loc26_17.10: ref %tuple.type.a8a = class_element_access %.loc26_17.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc26_17.1: ref %i32 = tuple_access %.loc26_17.10, element0
// CHECK:STDOUT:   %.loc26_17.11: %i32 = acquire_value %tuple.elem0.loc26_17.1
// CHECK:STDOUT:   %Try.facet.loc26: %Try.type = facet_value constants.%MyResult.964, (constants.%Try.impl_witness.852) [concrete = constants.%Try.facet.1d6]
// CHECK:STDOUT:   %.loc26_17.12: %Try.type = converted constants.%MyResult.964, %Try.facet.loc26 [concrete = constants.%Try.facet.1d6]
// CHECK:STDOUT:   %impl.elem3.loc26: %.51d = impl_witness_access constants.%Try.impl_witness.852, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.ae9]
// CHECK:STDOUT:   %specific_fn.loc26_17.4: <specific function> = specific_function %impl.elem3.loc26, @MyResult.as.Try.impl.FromBreak(constants.%i64, constants.%i32) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc24_75.2: ref %MyResult.964 = splice_block %return.param {}
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call.loc26: init %MyResult.964 to %.loc24_75.2 = call %specific_fn.loc26_17.4(%.loc26_17.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc26_17.1: <bound method> = bound_method %.loc26_17.2, constants.%Destroy.Op.1a2547.14
// CHECK:STDOUT:   %Destroy.Op.call.loc26_17.1: init %empty_tuple.type = call %Destroy.Op.bound.loc26_17.1(%.loc26_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc26_3.1: <bound method> = bound_method %y.var, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc26_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc26_3.1(%y.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc25_17.2: <bound method> = bound_method %.loc25_17.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc25_17.2: init %empty_tuple.type = call %Destroy.Op.bound.loc25_17.2(%.loc25_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc25_3.2: <bound method> = bound_method %x.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc25_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc25_3.2(%x.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call.loc26 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc26_17.2:
// CHECK:STDOUT:   %.loc26_17.13: ref %.75f = class_element_access %.loc26_17.2, element1
// CHECK:STDOUT:   %.loc26_17.14: ref %tuple.type.f67 = class_element_access %.loc26_17.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc26_17.2: ref %i64 = tuple_access %.loc26_17.14, element0
// CHECK:STDOUT:   %.loc26_17.15: %i64 = acquire_value %tuple.elem0.loc26_17.2
// CHECK:STDOUT:   %impl.elem0.loc26_17.3: %.3cb = impl_witness_access constants.%Copy.impl_witness.c5e, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc26_17.7: <bound method> = bound_method %.loc26_17.15, %impl.elem0.loc26_17.3
// CHECK:STDOUT:   %specific_fn.loc26_17.5: <specific function> = specific_function %impl.elem0.loc26_17.3, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.b95]
// CHECK:STDOUT:   %bound_method.loc26_17.8: <bound method> = bound_method %.loc26_17.15, %specific_fn.loc26_17.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc26: init %i64 = call %bound_method.loc26_17.8(%.loc26_17.15)
// CHECK:STDOUT:   assign %y.var, %Int.as.Copy.impl.Op.call.loc26
// CHECK:STDOUT:   %i64.loc26: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %y: ref %i64 = wrapper_binding y, %y.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %y.patt: %pattern_type.f57 = ref_binding_pattern y [concrete = constants.%y.patt]
// CHECK:STDOUT:     %y.var_patt: %pattern_type.f57 = var_pattern %y.patt [concrete = constants.%y.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc27: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i64.loc27_19: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %i32.loc27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %MyResult.loc27: type = class_type @MyResult, @MyResult(constants.%i64, constants.%i32) [concrete = constants.%MyResult.964]
// CHECK:STDOUT:   %.loc27_28: %MyResult.Ok.type.547 = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i64, constants.%i32) [concrete = constants.%MyResult.Ok.f46]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.547 = name_ref Ok, %.loc27_28 [concrete = constants.%MyResult.Ok.f46]
// CHECK:STDOUT:   %y.ref: ref %i64 = name_ref y, %y
// CHECK:STDOUT:   %x.ref: ref %i32 = name_ref x, %x
// CHECK:STDOUT:   %i64.loc27_42: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0.loc27: %.6c4 = impl_witness_access constants.%As.impl_witness.40c, element0 [concrete = constants.%Int.as.As.impl.Convert.9d1]
// CHECK:STDOUT:   %bound_method.loc27_39.1: <bound method> = bound_method %x.ref, %impl.elem0.loc27
// CHECK:STDOUT:   %specific_fn.loc27_39: <specific function> = specific_function %impl.elem0.loc27, @Int.as.As.impl.Convert.2(constants.%int_32, constants.%int_64) [concrete = constants.%Int.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc27_39.2: <bound method> = bound_method %x.ref, %specific_fn.loc27_39
// CHECK:STDOUT:   %.loc27_37: %i32 = acquire_value %x.ref
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call: init %i64 = call %bound_method.loc27_39.2(%.loc27_37)
// CHECK:STDOUT:   %.loc27_39.1: %i64 = value_of_initializer %Int.as.As.impl.Convert.call
// CHECK:STDOUT:   %.loc27_39.2: %i64 = converted %x.ref, %.loc27_39.1
// CHECK:STDOUT:   %impl.elem1: %.875 = impl_witness_access constants.%AddWith.impl_witness.2f5, element1 [concrete = constants.%Int.as.AddWith.impl.Op.e5a]
// CHECK:STDOUT:   %bound_method.loc27_34.1: <bound method> = bound_method %y.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc27_34: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_64) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f02]
// CHECK:STDOUT:   %bound_method.loc27_34.2: <bound method> = bound_method %y.ref, %specific_fn.loc27_34
// CHECK:STDOUT:   %.loc27_32: %i64 = acquire_value %y.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i64 = call %bound_method.loc27_34.2(%.loc27_32, %.loc27_39.2)
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i64, constants.%i32) [concrete = constants.%MyResult.Ok.specific_fn]
// CHECK:STDOUT:   %.loc24_75.3: ref %MyResult.964 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc27_34.1: %i64 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc27_34.2: %i64 = converted %Int.as.AddWith.impl.Op.call, %.loc27_34.1
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.964 to %.loc24_75.3 = call %MyResult.Ok.specific_fn(%.loc27_34.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc26_17.2: <bound method> = bound_method %.loc26_17.2, constants.%Destroy.Op.1a2547.14
// CHECK:STDOUT:   %Destroy.Op.call.loc26_17.2: init %empty_tuple.type = call %Destroy.Op.bound.loc26_17.2(%.loc26_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc26_3.2: <bound method> = bound_method %y.var, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc26_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc26_3.2(%y.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc25_17.3: <bound method> = bound_method %.loc25_17.2, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc25_17.3: init %empty_tuple.type = call %Destroy.Op.bound.loc25_17.3(%.loc25_17.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc25_3.3: <bound method> = bound_method %x.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc25_3.3: init %empty_tuple.type = call %Destroy.Op.bound.loc25_3.3(%x.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_17.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_17.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_17.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_17.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_17.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_17.6(%self.param: ref %.b63) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_17.7(%self.param: ref %struct_type.discriminant.payload.88b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_17.8(%self.param: ref %ControlFlow.32a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc26_17.1(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc26_17.2(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc26_17.3(%self.param: ref %tuple.type.f67) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc26_17.4(%self.param: ref %.75f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc26_17.5(%self.param: ref %struct_type.discriminant.payload.c1f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc26_17.6(%self.param: ref %ControlFlow.3df) {
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
// CHECK:STDOUT:   %Copy.impl_witness.fff: <witness> = impl_witness @Outer.as.Copy.impl.%Copy.impl_witness_table [concrete]
// CHECK:STDOUT:   %pattern_type.d6c: type = pattern_type %Outer [concrete]
// CHECK:STDOUT:   %.50e: Core.Form = init_form %Outer [concrete]
// CHECK:STDOUT:   %return.param_patt.756: %pattern_type.d6c = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.991: %pattern_type.d6c = return_slot_pattern %return.param_patt.756, %Outer [concrete]
// CHECK:STDOUT:   %Outer.as.Copy.impl.Op.type: type = fn_type @Outer.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %Outer.as.Copy.impl.Op: %Outer.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.e77: %Copy.type = facet_value %Outer, (%Copy.impl_witness.fff) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.fe9: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.e77) [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.impl_witness.9a1: <witness> = impl_witness @Inner.as.Try.impl.%Try.impl_witness_table [concrete]
// CHECK:STDOUT:   %ControlFlow.32a: type = class_type @ControlFlow, @ControlFlow(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Inner.as.Try.impl.Branch.type: type = fn_type @Inner.as.Try.impl.Branch [concrete]
// CHECK:STDOUT:   %Inner.as.Try.impl.Branch: %Inner.as.Try.impl.Branch.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Try.facet.b4c: %Try.type = facet_value %Inner, (%Try.impl_witness.9a1) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.da2: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.b4c) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.b63: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.88b: type = struct_type {.discriminant: %u1, .payload: %.b63} [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.bd6: <witness> = impl_witness @Outer.as.Try.impl.%Try.impl_witness_table [concrete]
// CHECK:STDOUT:   %ControlFlow.e96: type = class_type @ControlFlow, @ControlFlow(%Inner, %i32) [concrete]
// CHECK:STDOUT:   %Outer.as.Try.impl.Branch.type: type = fn_type @Outer.as.Try.impl.Branch [concrete]
// CHECK:STDOUT:   %Outer.as.Try.impl.Branch: %Outer.as.Try.impl.Branch.type = struct_value () [concrete]
// CHECK:STDOUT:   %Outer.as.Try.impl.FromBreak.type: type = fn_type @Outer.as.Try.impl.FromBreak [concrete]
// CHECK:STDOUT:   %Outer.as.Try.impl.FromBreak: %Outer.as.Try.impl.FromBreak.type = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.0f9: %Try.type = facet_value %Outer, (%Try.impl_witness.bd6) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.35e: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.0f9) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.2ac: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.0f9) [concrete]
// CHECK:STDOUT:   %tuple.type.c08: type = tuple_type (%Inner) [concrete]
// CHECK:STDOUT:   %.f6f: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.c08, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.76c: type = struct_type {.discriminant: %u1, .payload: %.f6f} [concrete]
// CHECK:STDOUT:   %.9ca: type = fn_type_with_self_type %Copy.WithSelf.Op.type.fe9, %Copy.facet.e77 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.d6c = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.d6c = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %Twice.type: type = fn_type @Twice [concrete]
// CHECK:STDOUT:   %Twice: %Twice.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete]
// CHECK:STDOUT:   %.658: type = fn_type_with_self_type %Try.WithSelf.Branch.type.35e, %Try.facet.0f9 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.c57: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.2ac, %Try.facet.0f9 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc47_17.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.10: type = fn_type @Destroy.Op.loc47_17.10 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.10: %Destroy.Op.type.1d8f74.10 = struct_value () [concrete]
// CHECK:STDOUT:   %.5777: type = fn_type_with_self_type %Try.WithSelf.Branch.type.da2, %Try.facet.b4c [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.13: type = fn_type @Destroy.Op.loc47_18.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.13: %Destroy.Op.type.1d8f74.13 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
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
// CHECK:STDOUT:   %impl.elem2.loc47_17: %.658 = impl_witness_access constants.%Try.impl_witness.bd6, element2 [concrete = constants.%Outer.as.Try.impl.Branch]
// CHECK:STDOUT:   %bound_method.loc47_17.1: <bound method> = bound_method %x.ref, %impl.elem2.loc47_17
// CHECK:STDOUT:   %.loc47_17.1: ref %ControlFlow.e96 = temporary_storage
// CHECK:STDOUT:   %Outer.as.Try.impl.Branch.call: init %ControlFlow.e96 to %.loc47_17.1 = call %bound_method.loc47_17.1(%x.ref)
// CHECK:STDOUT:   %.loc47_17.2: ref %ControlFlow.e96 = temporary %.loc47_17.1, %Outer.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc47_17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc47_17.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc47_17.2: <bound method> = bound_method %int_1.loc47_17, %impl.elem0.loc47_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc47_17.1: <specific function> = specific_function %impl.elem0.loc47_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc47_17.3: <bound method> = bound_method %int_1.loc47_17, %specific_fn.loc47_17.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc47_17: init %u1 = call %bound_method.loc47_17.3(%int_1.loc47_17) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_17.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc47_17 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_17.4: %u1 = converted %int_1.loc47_17, %.loc47_17.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_17.5: ref %u1 = class_element_access %.loc47_17.2, element0
// CHECK:STDOUT:   %impl.elem0.loc47_17.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
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
// CHECK:STDOUT:   %Try.facet.loc47_17: %Try.type = facet_value constants.%Outer, (constants.%Try.impl_witness.bd6) [concrete = constants.%Try.facet.0f9]
// CHECK:STDOUT:   %.loc47_17.12: %Try.type = converted constants.%Outer, %Try.facet.loc47_17 [concrete = constants.%Try.facet.0f9]
// CHECK:STDOUT:   %impl.elem3.loc47_17: %.c57 = impl_witness_access constants.%Try.impl_witness.bd6, element3 [concrete = constants.%Outer.as.Try.impl.FromBreak]
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
// CHECK:STDOUT:   %impl.elem2.loc47_18: %.5777 = impl_witness_access constants.%Try.impl_witness.9a1, element2 [concrete = constants.%Inner.as.Try.impl.Branch]
// CHECK:STDOUT:   %bound_method.loc47_18.1: <bound method> = bound_method %.loc47_17.15, %impl.elem2.loc47_18
// CHECK:STDOUT:   %.loc47_18.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %Inner.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc47_18.1 = call %bound_method.loc47_18.1(%.loc47_17.15)
// CHECK:STDOUT:   %.loc47_18.2: ref %ControlFlow.32a = temporary %.loc47_18.1, %Inner.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc47_18: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc47_18.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc47_18.2: <bound method> = bound_method %int_1.loc47_18, %impl.elem0.loc47_18.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc47_18.1: <specific function> = specific_function %impl.elem0.loc47_18.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc47_18.3: <bound method> = bound_method %int_1.loc47_18, %specific_fn.loc47_18.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc47_18: init %u1 = call %bound_method.loc47_18.3(%int_1.loc47_18) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_18.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc47_18 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_18.4: %u1 = converted %int_1.loc47_18, %.loc47_18.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc47_18.5: ref %u1 = class_element_access %.loc47_18.2, element0
// CHECK:STDOUT:   %impl.elem0.loc47_18.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
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
// CHECK:STDOUT:   %Try.facet.loc47_18: %Try.type = facet_value constants.%Outer, (constants.%Try.impl_witness.bd6) [concrete = constants.%Try.facet.0f9]
// CHECK:STDOUT:   %.loc47_18.12: %Try.type = converted constants.%Outer, %Try.facet.loc47_18 [concrete = constants.%Try.facet.0f9]
// CHECK:STDOUT:   %impl.elem3.loc47_18: %.c57 = impl_witness_access constants.%Try.impl_witness.bd6, element3 [concrete = constants.%Outer.as.Try.impl.FromBreak]
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
// CHECK:STDOUT:   %impl.elem0.loc47_18.3: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
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
// CHECK:STDOUT:   %impl.elem0.loc48: %.9ca = impl_witness_access constants.%Copy.impl_witness.fff, element0 [concrete = constants.%Outer.as.Copy.impl.Op]
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
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %Self.cc4: %Try.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.030: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Self.cc4) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.e67: %Try.WithSelf.FromBreak.type.030 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %.Self.frozen.5e9: %Try.type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %.Self.frozen.as_type: type = facet_access_type %.Self.frozen.5e9 [symbolic_self]
// CHECK:STDOUT:   %Try.assoc_type: type = assoc_entity_type @Try [concrete]
// CHECK:STDOUT:   %assoc1.f63: %Try.assoc_type = assoc_entity element1, imports.%Core.import_ref.9a9 [concrete]
// CHECK:STDOUT:   %Try.lookup_impl_witness.73a: <witness> = lookup_impl_witness %.Self.frozen.5e9, @Try [symbolic_self]
// CHECK:STDOUT:   %impl.elem1.660: type = impl_witness_access %Try.lookup_impl_witness.73a, element1 [symbolic_self]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.Self: %Try.type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Try.lookup_impl_witness.775: <witness> = lookup_impl_witness %.Self, @Try [symbolic_self]
// CHECK:STDOUT:   %impl.elem1.d8a: type = impl_witness_access %Try.lookup_impl_witness.775, element1 [symbolic_self]
// CHECK:STDOUT:   %Try_where.type: type = facet_type <@Try where %impl.elem1.d8a = %i32> [concrete]
// CHECK:STDOUT:   %pattern_type.df6: type = pattern_type %Try_where.type [concrete]
// CHECK:STDOUT:   %R.patt: %pattern_type.df6 = symbolic_binding_pattern R, 0 [symbolic]
// CHECK:STDOUT:   %R: %Try_where.type = symbolic_binding R, 0 [symbolic]
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
// CHECK:STDOUT:   %assoc0.de3: %Try.assoc_type = assoc_entity element0, imports.%Core.import_ref.c56 [concrete]
// CHECK:STDOUT:   %Try.lookup_impl_witness.832: <witness> = lookup_impl_witness %R, @Try [symbolic]
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value %R.as_type, (%Try.lookup_impl_witness.832) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.ef1: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.4c3: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet) [symbolic]
// CHECK:STDOUT:   %impl.elem0.fca: type = impl_witness_access %Try.lookup_impl_witness.832, element0 [symbolic]
// CHECK:STDOUT:   %require_complete.677: <witness> = require_complete_type %impl.elem0.fca [symbolic]
// CHECK:STDOUT:   %pattern_type.b1f: type = pattern_type %impl.elem0.fca [symbolic]
// CHECK:STDOUT:   %c.patt: %pattern_type.b1f = value_binding_pattern c [symbolic]
// CHECK:STDOUT:   %.392: type = fn_type_with_self_type %Try.WithSelf.Branch.type.ef1, %Try.facet [symbolic]
// CHECK:STDOUT:   %impl.elem2: %.392 = impl_witness_access %Try.lookup_impl_witness.832, element2 [symbolic]
// CHECK:STDOUT:   %ControlFlow.67f: type = class_type @ControlFlow, @ControlFlow(%impl.elem0.fca, %i32) [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.8ea: <specific function> = specific_impl_function %impl.elem2, @Try.WithSelf.Branch(%Try.facet) [symbolic]
// CHECK:STDOUT:   %tuple.type.c39: type = tuple_type (%impl.elem0.fca) [symbolic]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.990: type = custom_layout_type {size=0, align=0, .Continue@0: %tuple.type.c39, .Break@0: %tuple.type.a8a} [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %assoc3: %Try.assoc_type = assoc_entity element3, imports.%Core.import_ref.271 [concrete]
// CHECK:STDOUT:   %.287: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.4c3, %Try.facet [symbolic]
// CHECK:STDOUT:   %impl.elem3: %.287 = impl_witness_access %Try.lookup_impl_witness.832, element3 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.9a1: <specific function> = specific_impl_function %impl.elem3, @Try.WithSelf.FromBreak(%Try.facet) [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.import_ref.baf: %Try.assoc_type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = constants.%assoc0.de3]
// CHECK:STDOUT:   %Core.import_ref.814: %Try.assoc_type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = constants.%assoc1.f63]
// CHECK:STDOUT:   %Core.import_ref.8ab: %Try.assoc_type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = constants.%assoc3]
// CHECK:STDOUT:   %Core.import_ref.9a9: type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = %BreakType]
// CHECK:STDOUT:   %BreakType: type = assoc_const_decl @BreakType [concrete] {}
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.c56: type = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [concrete = %ContinueType]
// CHECK:STDOUT:   %ContinueType: type = assoc_const_decl @ContinueType [concrete] {}
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.271: @Try.WithSelf.%Try.WithSelf.FromBreak.type (%Try.WithSelf.FromBreak.type.030) = import_ref Core//prelude/try, loc{{\d+_\d+}}, loaded [symbolic = @Try.WithSelf.%Try.WithSelf.FromBreak (constants.%Try.WithSelf.FromBreak.e67)]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %PropagateOnly.decl: %PropagateOnly.type = fn_decl @PropagateOnly [concrete = constants.%PropagateOnly] {
// CHECK:STDOUT:     %R.patt.loc8_19.1: %pattern_type.df6 = symbolic_binding_pattern R, 0 [symbolic = %R.patt.loc8_19.2 (constants.%R.patt)]
// CHECK:STDOUT:     %r.param_patt.loc8_55.1: @PropagateOnly.%pattern_type.loc8 (%pattern_type.239) = value_param_pattern [symbolic = %r.param_patt.loc8_55.2 (constants.%r.param_patt)]
// CHECK:STDOUT:     %r.patt.loc8_55.1: @PropagateOnly.%pattern_type.loc8 (%pattern_type.239) = at_binding_pattern r, %r.param_patt.loc8_55.1 [symbolic = %r.patt.loc8_55.2 (constants.%r.patt)]
// CHECK:STDOUT:     %return.param_patt.loc8_63.1: @PropagateOnly.%pattern_type.loc8 (%pattern_type.239) = out_param_pattern [symbolic = %return.param_patt.loc8_63.2 (constants.%return.param_patt.aed)]
// CHECK:STDOUT:     %return.patt.loc8_60.1: @PropagateOnly.%pattern_type.loc8 (%pattern_type.239) = return_slot_pattern %return.param_patt.loc8_63.1, %.loc8_63.4 [symbolic = %return.patt.loc8_60.2 (constants.%return.patt.0bca)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %R.ref.loc8_63: %Try_where.type = name_ref R, %R.loc8_19.2 [symbolic = %R.loc8_19.1 (constants.%R)]
// CHECK:STDOUT:     %R.as_type.loc8_63: type = facet_access_type %R.ref.loc8_63 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     %.loc8_63.4: type = converted %R.ref.loc8_63, %R.as_type.loc8_63 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     %.loc8_63.5: Core.Form = init_form %.loc8_63.4 [symbolic = %.loc8_63.3 (constants.%.802)]
// CHECK:STDOUT:     %.loc8_30.1: type = splice_block %.loc8_30.2 [concrete = constants.%Try_where.type] {
// CHECK:STDOUT:       %.Self.frozen.loc8_19: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.197]
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Try.ref: type = name_ref Try, imports.%Core.Try [concrete = constants.%Try.type]
// CHECK:STDOUT:       %.Self.frozen.loc8_30: %Try.type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.5e9]
// CHECK:STDOUT:       %base_facet_type = requirement_base_facet_type %Try.ref [concrete]
// CHECK:STDOUT:       %.Self.ref: %Try.type = name_ref .Self, %.Self.frozen.loc8_30 [symbolic_self = constants.%.Self.frozen.5e9]
// CHECK:STDOUT:       %.Self.as_type: type = facet_access_type %.Self.ref [symbolic_self = constants.%.Self.frozen.as_type]
// CHECK:STDOUT:       %.loc8_36: type = converted %.Self.ref, %.Self.as_type [symbolic_self = constants.%.Self.frozen.as_type]
// CHECK:STDOUT:       %BreakType.ref: %Try.assoc_type = name_ref BreakType, imports.%Core.import_ref.814 [concrete = constants.%assoc1.f63]
// CHECK:STDOUT:       %impl.elem1.loc8_36.1: type = impl_witness_access constants.%Try.lookup_impl_witness.73a, element1 [symbolic_self = constants.%impl.elem1.660]
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %rewrite.loc8_47.1 = requirement_rewrite %impl.elem1.loc8_36.1, %i32 [concrete]
// CHECK:STDOUT:       %impl.elem1.loc8_36.2: type = impl_witness_access constants.%Try.lookup_impl_witness.775, element1 [symbolic_self = constants.%impl.elem1.d8a]
// CHECK:STDOUT:       %rewrite.loc8_47.2 = requirement_rewrite %impl.elem1.loc8_36.2, %i32 [concrete]
// CHECK:STDOUT:       %.loc8_30.2: type = where_expr [concrete = constants.%Try_where.type] {
// CHECK:STDOUT:         %base_facet_type = requirement_base_facet_type %Try.ref [concrete]
// CHECK:STDOUT:         %rewrite.loc8_47.2 = requirement_rewrite %impl.elem1.loc8_36.2, %i32 [concrete]
// CHECK:STDOUT:       }
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %R.loc8_19.2: %Try_where.type = symbolic_binding R, 0 [symbolic = %R.loc8_19.1 (constants.%R)]
// CHECK:STDOUT:     %r.param: @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) = value_param call_param0
// CHECK:STDOUT:     %.loc8_57.1: type = splice_block %.loc8_57.2 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)] {
// CHECK:STDOUT:       %R.ref.loc8_57: %Try_where.type = name_ref R, %R.loc8_19.2 [symbolic = %R.loc8_19.1 (constants.%R)]
// CHECK:STDOUT:       %R.as_type.loc8_57.2: type = facet_access_type %R.ref.loc8_57 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:       %.loc8_57.2: type = converted %R.ref.loc8_57, %R.as_type.loc8_57.2 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %r: @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) = wrapper_binding r, %r.param
// CHECK:STDOUT:     %return.param: ref @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) = out_param call_param1
// CHECK:STDOUT:     %return: ref @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @PropagateOnly(%R.loc8_19.2: %Try_where.type) {
// CHECK:STDOUT:   %R.patt.loc8_19.2: %pattern_type.df6 = symbolic_binding_pattern R, 0 [symbolic = %R.patt.loc8_19.2 (constants.%R.patt)]
// CHECK:STDOUT:   %R.loc8_19.1: %Try_where.type = symbolic_binding R, 0 [symbolic = %R.loc8_19.1 (constants.%R)]
// CHECK:STDOUT:   %R.as_type.loc8_57.1: type = facet_access_type %R.loc8_19.1 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:   %pattern_type.loc8: type = pattern_type %R.as_type.loc8_57.1 [symbolic = %pattern_type.loc8 (constants.%pattern_type.239)]
// CHECK:STDOUT:   %r.param_patt.loc8_55.2: @PropagateOnly.%pattern_type.loc8 (%pattern_type.239) = value_param_pattern [symbolic = %r.param_patt.loc8_55.2 (constants.%r.param_patt)]
// CHECK:STDOUT:   %r.patt.loc8_55.2: @PropagateOnly.%pattern_type.loc8 (%pattern_type.239) = at_binding_pattern r, %r.param_patt.loc8_55.2 [symbolic = %r.patt.loc8_55.2 (constants.%r.patt)]
// CHECK:STDOUT:   %.loc8_63.3: Core.Form = init_form %R.as_type.loc8_57.1 [symbolic = %.loc8_63.3 (constants.%.802)]
// CHECK:STDOUT:   %return.param_patt.loc8_63.2: @PropagateOnly.%pattern_type.loc8 (%pattern_type.239) = out_param_pattern [symbolic = %return.param_patt.loc8_63.2 (constants.%return.param_patt.aed)]
// CHECK:STDOUT:   %return.patt.loc8_60.2: @PropagateOnly.%pattern_type.loc8 (%pattern_type.239) = return_slot_pattern %return.param_patt.loc8_63.2, %R.as_type.loc8_57.1 [symbolic = %return.patt.loc8_60.2 (constants.%return.patt.0bca)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8: <witness> = require_complete_type %R.as_type.loc8_57.1 [symbolic = %require_complete.loc8 (constants.%require_complete.b5f)]
// CHECK:STDOUT:   %Try.lookup_impl_witness: <witness> = lookup_impl_witness %R.loc8_19.1, @Try [symbolic = %Try.lookup_impl_witness (constants.%Try.lookup_impl_witness.832)]
// CHECK:STDOUT:   %impl.elem0.loc9_18.2: type = impl_witness_access %Try.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc9_18.2 (constants.%impl.elem0.fca)]
// CHECK:STDOUT:   %require_complete.loc9: <witness> = require_complete_type %impl.elem0.loc9_18.2 [symbolic = %require_complete.loc9 (constants.%require_complete.677)]
// CHECK:STDOUT:   %pattern_type.loc9: type = pattern_type %impl.elem0.loc9_18.2 [symbolic = %pattern_type.loc9 (constants.%pattern_type.b1f)]
// CHECK:STDOUT:   %c.patt.loc9_15.2: @PropagateOnly.%pattern_type.loc9 (%pattern_type.b1f) = value_binding_pattern c [symbolic = %c.patt.loc9_15.2 (constants.%c.patt)]
// CHECK:STDOUT:   %Try.facet.loc9_35.4: %Try.type = facet_value %R.as_type.loc8_57.1, (%Try.lookup_impl_witness) [symbolic = %Try.facet.loc9_35.4 (constants.%Try.facet)]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.loc9_35.4) [symbolic = %Try.WithSelf.Branch.type (constants.%Try.WithSelf.Branch.type.ef1)]
// CHECK:STDOUT:   %.loc9_35.18: type = fn_type_with_self_type %Try.WithSelf.Branch.type, %Try.facet.loc9_35.4 [symbolic = %.loc9_35.18 (constants.%.392)]
// CHECK:STDOUT:   %impl.elem2.loc9_35.2: @PropagateOnly.%.loc9_35.18 (%.392) = impl_witness_access %Try.lookup_impl_witness, element2 [symbolic = %impl.elem2.loc9_35.2 (constants.%impl.elem2)]
// CHECK:STDOUT:   %specific_impl_fn.loc9_35.3: <specific function> = specific_impl_function %impl.elem2.loc9_35.2, @Try.WithSelf.Branch(%Try.facet.loc9_35.4) [symbolic = %specific_impl_fn.loc9_35.3 (constants.%specific_impl_fn.8ea)]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%impl.elem0.loc9_18.2) [symbolic = %tuple.type (constants.%tuple.type.c39)]
// CHECK:STDOUT:   %.loc9_35.19: type = custom_layout_type {size=0, align=0, .Continue@0: @PropagateOnly.%tuple.type (%tuple.type.c39), .Break@0: %tuple.type.a8a} [symbolic = %.loc9_35.19 (constants.%.990)]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.loc9_35.4) [symbolic = %Try.WithSelf.FromBreak.type (constants.%Try.WithSelf.FromBreak.type.4c3)]
// CHECK:STDOUT:   %.loc9_35.20: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type, %Try.facet.loc9_35.4 [symbolic = %.loc9_35.20 (constants.%.287)]
// CHECK:STDOUT:   %impl.elem3.loc9_35.2: @PropagateOnly.%.loc9_35.20 (%.287) = impl_witness_access %Try.lookup_impl_witness, element3 [symbolic = %impl.elem3.loc9_35.2 (constants.%impl.elem3)]
// CHECK:STDOUT:   %specific_impl_fn.loc9_35.4: <specific function> = specific_impl_function %impl.elem3.loc9_35.2, @Try.WithSelf.FromBreak(%Try.facet.loc9_35.4) [symbolic = %specific_impl_fn.loc9_35.4 (constants.%specific_impl_fn.9a1)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%r.param: @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type)) -> out %return.param: @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %r.ref: @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) = name_ref r, %r
// CHECK:STDOUT:     %impl.elem2.loc9_35.1: @PropagateOnly.%.loc9_35.18 (%.392) = impl_witness_access constants.%Try.lookup_impl_witness.832, element2 [symbolic = %impl.elem2.loc9_35.2 (constants.%impl.elem2)]
// CHECK:STDOUT:     %bound_method.loc9_35.1: <bound method> = bound_method %r.ref, %impl.elem2.loc9_35.1
// CHECK:STDOUT:     %Try.facet.loc9_35.1: %Try.type = facet_value constants.%R.as_type, (constants.%Try.lookup_impl_witness.832) [symbolic = %Try.facet.loc9_35.4 (constants.%Try.facet)]
// CHECK:STDOUT:     %.loc9_35.1: %Try.type = converted constants.%R.as_type, %Try.facet.loc9_35.1 [symbolic = %Try.facet.loc9_35.4 (constants.%Try.facet)]
// CHECK:STDOUT:     %Try.facet.loc9_35.2: %Try.type = facet_value constants.%R.as_type, (constants.%Try.lookup_impl_witness.832) [symbolic = %Try.facet.loc9_35.4 (constants.%Try.facet)]
// CHECK:STDOUT:     %.loc9_35.2: %Try.type = converted constants.%R.as_type, %Try.facet.loc9_35.2 [symbolic = %Try.facet.loc9_35.4 (constants.%Try.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc9_35.1: <specific function> = specific_impl_function %impl.elem2.loc9_35.1, @Try.WithSelf.Branch(constants.%Try.facet) [symbolic = %specific_impl_fn.loc9_35.3 (constants.%specific_impl_fn.8ea)]
// CHECK:STDOUT:     %bound_method.loc9_35.2: <bound method> = bound_method %r.ref, %specific_impl_fn.loc9_35.1
// CHECK:STDOUT:     %.loc9_35.3: ref @PropagateOnly.%ControlFlow (%ControlFlow.67f) = temporary_storage
// CHECK:STDOUT:     %Try.WithSelf.Branch.call: init @PropagateOnly.%ControlFlow (%ControlFlow.67f) to %.loc9_35.3 = call %bound_method.loc9_35.2(%r.ref)
// CHECK:STDOUT:     %.loc9_35.4: ref @PropagateOnly.%ControlFlow (%ControlFlow.67f) = temporary %.loc9_35.3, %Try.WithSelf.Branch.call
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc9_35.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc9_35.3: <bound method> = bound_method %int_1, %impl.elem0.loc9_35.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:     %specific_fn.loc9_35.1: <specific function> = specific_function %impl.elem0.loc9_35.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:     %bound_method.loc9_35.4: <bound method> = bound_method %int_1, %specific_fn.loc9_35.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %u1 = call %bound_method.loc9_35.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc9_35.5: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc9_35.6: %u1 = converted %int_1, %.loc9_35.5 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc9_35.7: ref %u1 = class_element_access %.loc9_35.4, element0
// CHECK:STDOUT:     %impl.elem0.loc9_35.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc9_35.5: <bound method> = bound_method %.loc9_35.6, %impl.elem0.loc9_35.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:     %specific_fn.loc9_35.2: <specific function> = specific_function %impl.elem0.loc9_35.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc9_35.6: <bound method> = bound_method %.loc9_35.6, %specific_fn.loc9_35.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc9_35.8: %u1 = acquire_value %.loc9_35.7
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc9_35.6(%.loc9_35.6, %.loc9_35.8)
// CHECK:STDOUT:     %.loc9_35.9: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:     %.loc9_35.10: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc9_35.9
// CHECK:STDOUT:     if %.loc9_35.10 br !.loc9_35.1 else br !.loc9_35.2
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc9_35.1:
// CHECK:STDOUT:     %.loc9_35.11: ref @PropagateOnly.%.loc9_35.19 (%.990) = class_element_access %.loc9_35.4, element1
// CHECK:STDOUT:     %.loc9_35.12: ref %tuple.type.a8a = class_element_access %.loc9_35.11, element1
// CHECK:STDOUT:     %tuple.elem0.loc9_35.1: ref %i32 = tuple_access %.loc9_35.12, element0
// CHECK:STDOUT:     %.loc9_35.13: %i32 = acquire_value %tuple.elem0.loc9_35.1
// CHECK:STDOUT:     %Try.facet.loc9_35.3: %Try.type = facet_value constants.%R.as_type, (constants.%Try.lookup_impl_witness.832) [symbolic = %Try.facet.loc9_35.4 (constants.%Try.facet)]
// CHECK:STDOUT:     %.loc9_35.14: %Try.type = converted constants.%R.as_type, %Try.facet.loc9_35.3 [symbolic = %Try.facet.loc9_35.4 (constants.%Try.facet)]
// CHECK:STDOUT:     %impl.elem3.loc9_35.1: @PropagateOnly.%.loc9_35.20 (%.287) = impl_witness_access constants.%Try.lookup_impl_witness.832, element3 [symbolic = %impl.elem3.loc9_35.2 (constants.%impl.elem3)]
// CHECK:STDOUT:     %specific_impl_fn.loc9_35.2: <specific function> = specific_impl_function %impl.elem3.loc9_35.1, @Try.WithSelf.FromBreak(constants.%Try.facet) [symbolic = %specific_impl_fn.loc9_35.4 (constants.%specific_impl_fn.9a1)]
// CHECK:STDOUT:     %.loc8_63.1: ref @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) = splice_block %return.param {}
// CHECK:STDOUT:     %Try.WithSelf.FromBreak.call.loc9: init @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) to %.loc8_63.1 = call %specific_impl_fn.loc9_35.2(%.loc9_35.13)
// CHECK:STDOUT:     return %Try.WithSelf.FromBreak.call.loc9 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc9_35.2:
// CHECK:STDOUT:     %.loc9_35.15: ref @PropagateOnly.%.loc9_35.19 (%.990) = class_element_access %.loc9_35.4, element1
// CHECK:STDOUT:     %.loc9_35.16: ref @PropagateOnly.%tuple.type (%tuple.type.c39) = class_element_access %.loc9_35.15, element0
// CHECK:STDOUT:     %tuple.elem0.loc9_35.2: ref @PropagateOnly.%impl.elem0.loc9_18.2 (%impl.elem0.fca) = tuple_access %.loc9_35.16, element0
// CHECK:STDOUT:     %.loc9_35.17: @PropagateOnly.%impl.elem0.loc9_18.2 (%impl.elem0.fca) = acquire_value %tuple.elem0.loc9_35.2
// CHECK:STDOUT:     %.loc9_18.1: type = splice_block %impl.elem0.loc9_18.1 [symbolic = %impl.elem0.loc9_18.2 (constants.%impl.elem0.fca)] {
// CHECK:STDOUT:       %R.ref.loc9: %Try_where.type = name_ref R, %R.loc8_19.2 [symbolic = %R.loc8_19.1 (constants.%R)]
// CHECK:STDOUT:       %R.as_type.loc9: type = facet_access_type %R.ref.loc9 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:       %.loc9_18.2: type = converted %R.ref.loc9, %R.as_type.loc9 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:       %ContinueType.ref: %Try.assoc_type = name_ref ContinueType, imports.%Core.import_ref.baf [concrete = constants.%assoc0.de3]
// CHECK:STDOUT:       %impl.elem0.loc9_18.1: type = impl_witness_access constants.%Try.lookup_impl_witness.832, element0 [symbolic = %impl.elem0.loc9_18.2 (constants.%impl.elem0.fca)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %c: @PropagateOnly.%impl.elem0.loc9_18.2 (%impl.elem0.fca) = wrapper_binding c, %.loc9_35.17
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %c.patt.loc9_15.1: @PropagateOnly.%pattern_type.loc9 (%pattern_type.b1f) = value_binding_pattern c [symbolic = %c.patt.loc9_15.2 (constants.%c.patt)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %R.ref.loc10: %Try_where.type = name_ref R, %R.loc8_19.2 [symbolic = %R.loc8_19.1 (constants.%R)]
// CHECK:STDOUT:     %R.as_type.loc10: type = facet_access_type %R.ref.loc10 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     %.loc10_11: type = converted %R.ref.loc10, %R.as_type.loc10 [symbolic = %R.as_type.loc8_57.1 (constants.%R.as_type)]
// CHECK:STDOUT:     %FromBreak.ref: %Try.assoc_type = name_ref FromBreak, imports.%Core.import_ref.8ab [concrete = constants.%assoc3]
// CHECK:STDOUT:     %impl.elem3.loc10: @PropagateOnly.%.loc9_35.20 (%.287) = impl_witness_access constants.%Try.lookup_impl_witness.832, element3 [symbolic = %impl.elem3.loc9_35.2 (constants.%impl.elem3)]
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %specific_impl_fn.loc10: <specific function> = specific_impl_function %impl.elem3.loc10, @Try.WithSelf.FromBreak(constants.%Try.facet) [symbolic = %specific_impl_fn.loc9_35.4 (constants.%specific_impl_fn.9a1)]
// CHECK:STDOUT:     %.loc8_63.2: ref @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) = splice_block %return.param {}
// CHECK:STDOUT:     %impl.elem0.loc10: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc10_22.1: <bound method> = bound_method %int_0, %impl.elem0.loc10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:     %bound_method.loc10_22.2: <bound method> = bound_method %int_0, %specific_fn.loc10 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_22.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc10_22.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc10_22.2: %i32 = converted %int_0, %.loc10_22.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %Try.WithSelf.FromBreak.call.loc10: init @PropagateOnly.%R.as_type.loc8_57.1 (%R.as_type) to %.loc8_63.2 = call %specific_impl_fn.loc10(%.loc10_22.2)
// CHECK:STDOUT:     return %Try.WithSelf.FromBreak.call.loc10 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_35.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_35.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @PropagateOnly(constants.%R) {
// CHECK:STDOUT:   %R.patt.loc8_19.2 => constants.%R.patt
// CHECK:STDOUT:   %R.loc8_19.1 => constants.%R
// CHECK:STDOUT:   %R.as_type.loc8_57.1 => constants.%R.as_type
// CHECK:STDOUT:   %pattern_type.loc8 => constants.%pattern_type.239
// CHECK:STDOUT:   %r.param_patt.loc8_55.2 => constants.%r.param_patt
// CHECK:STDOUT:   %r.patt.loc8_55.2 => constants.%r.patt
// CHECK:STDOUT:   %.loc8_63.3 => constants.%.802
// CHECK:STDOUT:   %return.param_patt.loc8_63.2 => constants.%return.param_patt.aed
// CHECK:STDOUT:   %return.patt.loc8_60.2 => constants.%return.patt.0bca
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ErrA: type = class_type @ErrA [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %ErrB: type = class_type @ErrB [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.af5: type = facet_type <@ImplicitAs, @ImplicitAs(%ErrB)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.b05: <witness> = impl_witness @ErrA.as.ImplicitAs.impl.%ImplicitAs.impl_witness_table [concrete]
// CHECK:STDOUT:   %ErrA.as.ImplicitAs.impl.Convert.type: type = fn_type @ErrA.as.ImplicitAs.impl.Convert [concrete]
// CHECK:STDOUT:   %ErrA.as.ImplicitAs.impl.Convert: %ErrA.as.ImplicitAs.impl.Convert.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.855: %ImplicitAs.type.af5 = facet_value %ErrA, (%ImplicitAs.impl_witness.b05) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.704: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%ErrB, %ImplicitAs.facet.855) [concrete]
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
// CHECK:STDOUT:   %Try.impl_witness.3be: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.type.4ce: type = fn_type @MyResult.as.Try.impl.FromBreak, @MyResult.as.Try.impl(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.2ad: %MyResult.as.Try.impl.FromBreak.type.4ce = struct_value () [concrete]
// CHECK:STDOUT:   %Try.impl_witness.468: <witness> = impl_witness @MyResult.as.Try.impl.%Try.impl_witness_table, @MyResult.as.Try.impl(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.type.cbc: type = fn_type @MyResult.as.Try.impl.Branch, @MyResult.as.Try.impl(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.ea2: %MyResult.as.Try.impl.Branch.type.cbc = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.0aa: %Try.type = facet_value %MyResult.4a3, (%Try.impl_witness.468) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.dee: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.0aa) [concrete]
// CHECK:STDOUT:   %.6e3: type = fn_type_with_self_type %Try.WithSelf.Branch.type.dee, %Try.facet.0aa [concrete]
// CHECK:STDOUT:   %ControlFlow.46a: type = class_type @ControlFlow, @ControlFlow(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.Branch.ea2, @MyResult.as.Try.impl.Branch(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %.873: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.bb7} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.615: type = struct_type {.discriminant: %u1, .payload: %.873} [concrete]
// CHECK:STDOUT:   %Try.facet.16b: %Try.type = facet_value %MyResult.819, (%Try.impl_witness.3be) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.108: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.16b) [concrete]
// CHECK:STDOUT:   %.f75: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.108, %Try.facet.16b [concrete]
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %MyResult.as.Try.impl.FromBreak.2ad, @MyResult.as.Try.impl.FromBreak(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %.66c: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.704, %ImplicitAs.facet.855 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc48_24.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.10: type = fn_type @Destroy.Op.loc48_24.10 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.10: %Destroy.Op.type.1d8f74.10 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.13: type = fn_type @Destroy.Op.loc48_23.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.13: %Destroy.Op.type.1d8f74.13 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %MyResult.Ok.specific_fn.d1d: <specific function> = specific_function %MyResult.Ok.b68, @MyResult.Ok(%i32, %ErrB) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
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
// CHECK:STDOUT:     %return.patt: %pattern_type.695 = return_slot_pattern %return.param_patt, %MyResult.loc47 [concrete = constants.%return.patt.acc]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MyResult.ref.loc47: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:     %i32.loc47_30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ErrB.ref.loc47: type = name_ref ErrB, file.%ErrB.decl [concrete = constants.%ErrB]
// CHECK:STDOUT:     %MyResult.loc47: type = class_type @MyResult, @MyResult(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.819]
// CHECK:STDOUT:     %.loc47_39.3: Core.Form = init_form %MyResult.loc47 [concrete = constants.%.38d]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc47_13: type = type_literal constants.%i32 [concrete = constants.%i32]
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
// CHECK:STDOUT:   %.loc48_23.1: ref %MyResult.4a3 = temporary_storage
// CHECK:STDOUT:   %Inner.call: init %MyResult.4a3 to %.loc48_23.1 = call %Inner.ref(%n.ref)
// CHECK:STDOUT:   %.loc48_23.2: ref %MyResult.4a3 = temporary %.loc48_23.1, %Inner.call
// CHECK:STDOUT:   %impl.elem2: %.6e3 = impl_witness_access constants.%Try.impl_witness.468, element2 [concrete = constants.%MyResult.as.Try.impl.Branch.ea2]
// CHECK:STDOUT:   %bound_method.loc48_24.1: <bound method> = bound_method %.loc48_23.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc48_24.1: <specific function> = specific_function %impl.elem2, @MyResult.as.Try.impl.Branch(constants.%i32, constants.%ErrA) [concrete = constants.%MyResult.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc48_24.2: <bound method> = bound_method %.loc48_23.2, %specific_fn.loc48_24.1
// CHECK:STDOUT:   %.loc48_24.1: ref %ControlFlow.46a = temporary_storage
// CHECK:STDOUT:   %.loc48_23.3: %MyResult.4a3 = acquire_value %.loc48_23.2
// CHECK:STDOUT:   %MyResult.as.Try.impl.Branch.call: init %ControlFlow.46a to %.loc48_24.1 = call %bound_method.loc48_24.2(%.loc48_23.3)
// CHECK:STDOUT:   %.loc48_24.2: ref %ControlFlow.46a = temporary %.loc48_24.1, %MyResult.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc48_24.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc48_24.3: <bound method> = bound_method %int_1, %impl.elem0.loc48_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc48_24.2: <specific function> = specific_function %impl.elem0.loc48_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc48_24.4: <bound method> = bound_method %int_1, %specific_fn.loc48_24.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc48_24.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc48_24.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc48_24.4: %u1 = converted %int_1, %.loc48_24.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc48_24.5: ref %u1 = class_element_access %.loc48_24.2, element0
// CHECK:STDOUT:   %impl.elem0.loc48_24.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc48_24.5: <bound method> = bound_method %.loc48_24.4, %impl.elem0.loc48_24.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc48_24.3: <specific function> = specific_function %impl.elem0.loc48_24.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc48_24.6: <bound method> = bound_method %.loc48_24.4, %specific_fn.loc48_24.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc48_24.6: %u1 = acquire_value %.loc48_24.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc48_24.6(%.loc48_24.4, %.loc48_24.6)
// CHECK:STDOUT:   %.loc48_24.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc48_24.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc48_24.7
// CHECK:STDOUT:   if %.loc48_24.8 br !.loc48_24.1 else br !.loc48_24.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc48_24.1:
// CHECK:STDOUT:   %.loc48_24.9: ref %.873 = class_element_access %.loc48_24.2, element1
// CHECK:STDOUT:   %.loc48_24.10: ref %tuple.type.bb7 = class_element_access %.loc48_24.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc48_24.1: ref %ErrA = tuple_access %.loc48_24.10, element0
// CHECK:STDOUT:   %.loc48_24.11: %ErrA = acquire_value %tuple.elem0.loc48_24.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%MyResult.819, (constants.%Try.impl_witness.3be) [concrete = constants.%Try.facet.16b]
// CHECK:STDOUT:   %.loc48_24.12: %Try.type = converted constants.%MyResult.819, %Try.facet [concrete = constants.%Try.facet.16b]
// CHECK:STDOUT:   %impl.elem3: %.f75 = impl_witness_access constants.%Try.impl_witness.3be, element3 [concrete = constants.%MyResult.as.Try.impl.FromBreak.2ad]
// CHECK:STDOUT:   %specific_fn.loc48_24.4: <specific function> = specific_function %impl.elem3, @MyResult.as.Try.impl.FromBreak(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc47_39.1: ref %MyResult.819 = splice_block %return.param {}
// CHECK:STDOUT:   %impl.elem0.loc48_24.3: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.b05, element0 [concrete = constants.%ErrA.as.ImplicitAs.impl.Convert]
// CHECK:STDOUT:   %bound_method.loc48_24.7: <bound method> = bound_method %.loc48_24.11, %impl.elem0.loc48_24.3
// CHECK:STDOUT:   %ErrA.as.ImplicitAs.impl.Convert.call: init %ErrB = call %bound_method.loc48_24.7(%.loc48_24.11)
// CHECK:STDOUT:   %.loc48_24.13: %ErrB = value_of_initializer %ErrA.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc48_24.14: %ErrB = converted %.loc48_24.11, %.loc48_24.13
// CHECK:STDOUT:   %MyResult.as.Try.impl.FromBreak.call: init %MyResult.819 to %.loc47_39.1 = call %specific_fn.loc48_24.4(%.loc48_24.14)
// CHECK:STDOUT:   %Destroy.Op.bound.loc48_24.1: <bound method> = bound_method %.loc48_24.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc48_24.1: init %empty_tuple.type = call %Destroy.Op.bound.loc48_24.1(%.loc48_24.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc48_23.1: <bound method> = bound_method %.loc48_23.2, constants.%Destroy.Op.1a2547.13
// CHECK:STDOUT:   %Destroy.Op.call.loc48_23.1: init %empty_tuple.type = call %Destroy.Op.bound.loc48_23.1(%.loc48_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc48_3.1: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc48_3.1: init %empty_tuple.type = call %Destroy.Op.bound.loc48_3.1(%v.var)
// CHECK:STDOUT:   return %MyResult.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc48_24.2:
// CHECK:STDOUT:   %.loc48_24.15: ref %.873 = class_element_access %.loc48_24.2, element1
// CHECK:STDOUT:   %.loc48_24.16: ref %tuple.type.a8a = class_element_access %.loc48_24.15, element0
// CHECK:STDOUT:   %tuple.elem0.loc48_24.2: ref %i32 = tuple_access %.loc48_24.16, element0
// CHECK:STDOUT:   %.loc48_24.17: %i32 = acquire_value %tuple.elem0.loc48_24.2
// CHECK:STDOUT:   %impl.elem0.loc48_24.4: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc48_24.8: <bound method> = bound_method %.loc48_24.17, %impl.elem0.loc48_24.4
// CHECK:STDOUT:   %specific_fn.loc48_24.5: <specific function> = specific_function %impl.elem0.loc48_24.4, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc48_24.9: <bound method> = bound_method %.loc48_24.17, %specific_fn.loc48_24.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc48_24.9(%.loc48_24.17)
// CHECK:STDOUT:   assign %v.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc48: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt.113]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MyResult.ref.loc49: %MyResult.type = name_ref MyResult, file.%MyResult.decl [concrete = constants.%MyResult.generic]
// CHECK:STDOUT:   %i32.loc49: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %ErrB.ref.loc49: type = name_ref ErrB, file.%ErrB.decl [concrete = constants.%ErrB]
// CHECK:STDOUT:   %MyResult.loc49: type = class_type @MyResult, @MyResult(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.819]
// CHECK:STDOUT:   %.loc49_29: %MyResult.Ok.type.d53 = specific_constant generated.%MyResult.Ok.decl, @MyResult(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.Ok.b68]
// CHECK:STDOUT:   %Ok.ref: %MyResult.Ok.type.d53 = name_ref Ok, %.loc49_29 [concrete = constants.%MyResult.Ok.b68]
// CHECK:STDOUT:   %v.ref: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %MyResult.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @MyResult.Ok(constants.%i32, constants.%ErrB) [concrete = constants.%MyResult.Ok.specific_fn.d1d]
// CHECK:STDOUT:   %.loc47_39.2: ref %MyResult.819 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc49_33: %i32 = acquire_value %v.ref
// CHECK:STDOUT:   %MyResult.Ok.call: init %MyResult.819 to %.loc47_39.2 = call %MyResult.Ok.specific_fn(%.loc49_33)
// CHECK:STDOUT:   %Destroy.Op.bound.loc48_24.2: <bound method> = bound_method %.loc48_24.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc48_24.2: init %empty_tuple.type = call %Destroy.Op.bound.loc48_24.2(%.loc48_24.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc48_23.2: <bound method> = bound_method %.loc48_23.2, constants.%Destroy.Op.1a2547.13
// CHECK:STDOUT:   %Destroy.Op.call.loc48_23.2: init %empty_tuple.type = call %Destroy.Op.bound.loc48_23.2(%.loc48_23.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc48_3.2: <bound method> = bound_method %v.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call.loc48_3.2: init %empty_tuple.type = call %Destroy.Op.bound.loc48_3.2(%v.var)
// CHECK:STDOUT:   return %MyResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.6(%self.param: ref %ErrA) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.7(%self.param: ref %tuple.type.bb7) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.8(%self.param: ref %.873) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.9(%self.param: ref %struct_type.discriminant.payload.615) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_24.10(%self.param: ref %ControlFlow.46a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_23.1(%self.param: ref %.e62) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_23.2(%self.param: ref %struct_type.discriminant.payload.9f6) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc48_23.3(%self.param: ref %MyResult.4a3) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
