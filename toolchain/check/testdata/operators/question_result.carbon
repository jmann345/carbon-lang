// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/question_result.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/question_result.carbon

// Postfix `?` over the prelude's `Core.Result(T, E)` (fork/eh/plan.md §4.A;
// docs/design/error_handling.md, "The `Core.Result` type" and "The
// `Core.Try` interface"): the question.carbon subfile shapes, which pinned
// the desugar over a user `MyResult`, replayed over the prelude choice and
// its `final impl ... as Try` in core/prelude/types/result.carbon. No user
// impl exists in this file — every `Branch`/`FromBreak` resolves to the
// prelude impl — and the `generic` subfile pins the `final`-impl
// type-collapse at that impl (`r?` binds `: T`). `fail_class_payload` pins
// the SF-6 payload bound against the prelude type: it belongs to the Sum
// types bullet (W-010's residue), not to `Result`.

// --- propagate.carbon
library "[[@TEST_NAME]]";

fn Open(n: i32) -> Core.Result(i32, i32) {
  if (n > 0) { return Core.Result(i32, i32).Ok(n); }
  return Core.Result(i32, i32).Err(n);
}

fn Callee(a: i32, b: i32) -> i32 { return a + b; }

//@dump-sem-ir-begin
// `?` in a `var` initializer.
fn Basic(n: i32) -> Core.Result(i32, i32) {
  var f: i32 = Open(n)?;
  return Core.Result(i32, i32).Ok(f + 1);
}

// `?` in statement position: the continue value is discarded.
fn Statement(n: i32) -> Core.Result(i32, i32) {
  Open(n)?;
  return Core.Result(i32, i32).Ok(n);
}

// A `?` chain in one statement: the inner `?` is mid-expression when its
// break path returns.
fn Chain(n: i32) -> Core.Result(i32, i32) {
  var t: i32 = Open(Open(n)?)?;
  return Core.Result(i32, i32).Ok(t);
}

// `?` in argument position of an ordinary call.
fn Argument(n: i32) -> Core.Result(i32, i32) {
  var v: i32 = Callee(n, Open(n)?);
  return Core.Result(i32, i32).Ok(v);
}
//@dump-sem-ir-end

// --- convert.carbon
library "[[@TEST_NAME]]";

// D3/F-006c: the break payload's conversion to the return type's break type
// is the ordinary `ImplicitAs` argument conversion in the prelude impl's
// `FromBreak` call. `ErrA` and `ErrB` are adapters over `i32`
// (SF-6-admissible payloads) with a user `ImplicitAs`.
class ErrA {
  adapt i32;
}

class ErrB {
  adapt i32;
}

// `Convert` returns an `ErrB` value into its return slot, which is a
// `Core.Copy` use; adapters do not inherit `Copy` from the adapted type.
impl ErrB as Core.Copy {
  fn Op(self) -> Self = "primitive_copy";
}

impl ErrA as Core.ImplicitAs(ErrB) {
  fn Convert(self) -> ErrB { return (self as i32) as ErrB; }
}

fn Inner(n: i32) -> Core.Result(i32, ErrA) {
  if (n > 0) { return Core.Result(i32, ErrA).Ok(n); }
  return Core.Result(i32, ErrA).Err(n as ErrA);
}

//@dump-sem-ir-begin
fn Outer(n: i32) -> Core.Result(i32, ErrB) {
  var v: i32 = Inner(n)?;
  return Core.Result(i32, ErrB).Ok(v);
}
//@dump-sem-ir-end

// --- unit_ok.carbon
library "[[@TEST_NAME]]";

// `Core.Result((), E)`: the `()` payload on the `Ok` side (D-EH-2's
// admission of the zero-sized empty tuple), the conventional shape for an
// operation with no interesting success value.
fn Check(n: i32) -> Core.Result((), i32) {
  if (n > 0) { return Core.Result((), i32).Ok(()); }
  return Core.Result((), i32).Err(n);
}

//@dump-sem-ir-begin
fn Both(n: i32) -> Core.Result((), i32) {
  Check(n)?;
  Check(n + 1)?;
  return Core.Result((), i32).Ok(());
}
//@dump-sem-ir-end

// --- generic.carbon
library "[[@TEST_NAME]]";

// The prelude impl is `final`, so impl lookup under a symbolic query applies
// its `where` rewrites and the continue value of `r?` on a symbolic
// `Core.Result(T, E)` operand binds `: T` (the question_final.carbon P-1
// shape, now at the PRELUDE impl).
//@dump-sem-ir-begin
fn Passthrough[T: type, E: type](r: Core.Result(T, E)) -> Core.Result(T, E) {
  let v: T = r?;
  return Core.Result(T, E).Ok(v);
}
//@dump-sem-ir-end

// --- fail_class_payload.carbon
library "[[@TEST_NAME]]";

// The SF-6 bound, inherited not widened: a payload type must be a scalar
// after adapters (toolchain/check/type.cpp `IsInSliceChoicePayloadType`), so
// a `Core.Result(SomeClass, E)` specific is diagnosed at its forcing use
// exactly as a user `MyResult(SomeClass, E)` is today.
class SomeClass {
  var x: i32;
}

fn Use(unused r: Core.Result(SomeClass, i32)) {}
