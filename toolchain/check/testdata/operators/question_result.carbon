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

// CHECK:STDERR: fail_class_payload.carbon:[[@LINE+7]]:15: error: parameter has incomplete type `Core.Result(SomeClass, i32)` in function definition [IncompleteTypeInFunctionParam]
// CHECK:STDERR: fn Use(unused r: Core.Result(SomeClass, i32)) {}
// CHECK:STDERR:               ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: {{.*}}/prelude/types/result.carbon:28:1: note: choice alternative payload type `SomeClass` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
// CHECK:STDERR: choice Result(T: type, E: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Use(unused r: Core.Result(SomeClass, i32)) {}

// CHECK:STDOUT: --- propagate.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Result.250: type = class_type @Result, @Result(%i32, %i32) [concrete]
// CHECK:STDOUT:   %.4ba: Core.Form = init_form %Result.250 [concrete]
// CHECK:STDOUT:   %pattern_type.321: type = pattern_type %Result.250 [concrete]
// CHECK:STDOUT:   %return.param_patt.8f8: %pattern_type.321 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.d36: %pattern_type.321 = return_slot_pattern %return.param_patt.8f8, %Result.250 [concrete]
// CHECK:STDOUT:   %Open.type: type = fn_type @Open [concrete]
// CHECK:STDOUT:   %Open: %Open.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.bf4: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a, .Err@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.f26: type = struct_type {.discriminant: %u1, .payload: %.bf4} [concrete]
// CHECK:STDOUT:   %Result.Ok.type.39c: type = fn_type @Result.Ok, @Result(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Result.Ok.e0a: %Result.Ok.type.39c = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %OrderedWith.type.ad8: type = generic_interface_type @OrderedWith [concrete]
// CHECK:STDOUT:   %OrderedWith.generic: %OrderedWith.type.ad8 = struct_value () [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.e0a, @Result.Ok(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Callee.type: type = fn_type @Callee [concrete]
// CHECK:STDOUT:   %Callee: %Callee.type = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
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
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.468: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.f19: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.667: %Result.as.Try.impl.Branch.type.f19 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.40d: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.faf: %Result.as.Try.impl.FromBreak.type.40d = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.4c8: %Try.type = facet_value %Result.250, (%Try.impl_witness.468) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.330: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.4c8) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.934: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.4c8) [concrete]
// CHECK:STDOUT:   %.c8a: type = fn_type_with_self_type %Try.WithSelf.Branch.type.330, %Try.facet.4c8 [concrete]
// CHECK:STDOUT:   %ControlFlow.32a: type = class_type @ControlFlow, @ControlFlow(%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.315: type = pattern_type %ControlFlow.32a [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.536: <specific function> = specific_function %Result.as.Try.impl.Branch.667, @Result.as.Try.impl.Branch(%i32, %i32) [concrete]
// CHECK:STDOUT:   %.b63: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.88b: type = struct_type {.discriminant: %u1, .payload: %.b63} [concrete]
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
// CHECK:STDOUT:   %pattern_type.322: type = pattern_type %u1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
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
// CHECK:STDOUT:   %.ff6: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.934, %Try.facet.4c8 [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.faf, @Result.as.Try.impl.FromBreak(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %self.param_patt.7c1: %pattern_type.322 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.945: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt.7c1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_23.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc13_23.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_23.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_23.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc13_23.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_23.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_23.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc13_23.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6f4: type = pattern_type %.b63 [concrete]
// CHECK:STDOUT:   %self.param_patt.a94: %pattern_type.6f4 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.399: %pattern_type.6f4 = wrapper_binding_pattern self, %self.param_patt.a94 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_23.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc13_23.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_23.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.5d2: type = pattern_type %struct_type.discriminant.payload.88b [concrete]
// CHECK:STDOUT:   %self.param_patt.b0e: %pattern_type.5d2 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.6f7: %pattern_type.5d2 = wrapper_binding_pattern self, %self.param_patt.b0e [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_23.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc13_23.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.e9f: %pattern_type.315 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.519: %pattern_type.315 = wrapper_binding_pattern self, %self.param_patt.e9f [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_23.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc13_23.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.6: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_23.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.6: %Destroy.WithSelf.SelfDestruct.type.fbceb5.6 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.69d: type = pattern_type %.bf4 [concrete]
// CHECK:STDOUT:   %self.param_patt.e4d: %pattern_type.69d = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.571: %pattern_type.69d = wrapper_binding_pattern self, %self.param_patt.e4d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_22.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.7: type = fn_type @Destroy.WithSelf.Op.loc13_22.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.7: %Destroy.WithSelf.Op.type.ef016f.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.7: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_22.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.7: %Destroy.WithSelf.SelfDestruct.type.fbceb5.7 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.68e: type = pattern_type %struct_type.discriminant.payload.f26 [concrete]
// CHECK:STDOUT:   %self.param_patt.3b4: %pattern_type.68e = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.c9e: %pattern_type.68e = wrapper_binding_pattern self, %self.param_patt.3b4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_22.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.8: type = fn_type @Destroy.WithSelf.Op.loc13_22.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.8: %Destroy.WithSelf.Op.type.ef016f.8 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.393: %pattern_type.321 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.a2d: %pattern_type.321 = wrapper_binding_pattern self, %self.param_patt.393 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_22.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.9: type = fn_type @Destroy.WithSelf.Op.loc13_22.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.9: %Destroy.WithSelf.Op.type.ef016f.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.9: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_22.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.9: %Destroy.WithSelf.SelfDestruct.type.fbceb5.9 = struct_value () [concrete]
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
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Result = %Core.Result.0b3
// CHECK:STDOUT:     .OrderedWith = %Core.OrderedWith
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Result.0b3: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.OrderedWith: %OrderedWith.type.ad8 = import_ref Core//prelude/operators/comparison, OrderedWith, loaded [concrete = constants.%OrderedWith.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3a: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.b21 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.8a3a), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_23.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc13_23.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_23.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc13_23.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_23.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc13_23.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_23.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6f4 = ref_param_pattern [concrete = constants.%self.param_patt.a94]
// CHECK:STDOUT:     %self.patt: %pattern_type.6f4 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.399]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.b63 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.b63 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc13_23.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6f4 = ref_param_pattern [concrete = constants.%self.param_patt.a94]
// CHECK:STDOUT:     %self.patt: %pattern_type.6f4 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.399]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.b63 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.b63 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_23.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.5d2 = ref_param_pattern [concrete = constants.%self.param_patt.b0e]
// CHECK:STDOUT:     %self.patt: %pattern_type.5d2 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.6f7]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.88b = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.88b = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc13_23.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.5d2 = ref_param_pattern [concrete = constants.%self.param_patt.b0e]
// CHECK:STDOUT:     %self.patt: %pattern_type.5d2 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.6f7]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.88b = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.88b = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_23.6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.315 = ref_param_pattern [concrete = constants.%self.param_patt.e9f]
// CHECK:STDOUT:     %self.patt: %pattern_type.315 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.519]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ControlFlow.32a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ControlFlow.32a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc13_23.6 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.315 = ref_param_pattern [concrete = constants.%self.param_patt.e9f]
// CHECK:STDOUT:     %self.patt: %pattern_type.315 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.519]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ControlFlow.32a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ControlFlow.32a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_22.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.69d = ref_param_pattern [concrete = constants.%self.param_patt.e4d]
// CHECK:STDOUT:     %self.patt: %pattern_type.69d = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.571]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.bf4 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.bf4 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.7: %Destroy.WithSelf.Op.type.ef016f.7 = fn_decl @Destroy.WithSelf.Op.loc13_22.1 [concrete = constants.%Destroy.WithSelf.Op.403171.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.69d = ref_param_pattern [concrete = constants.%self.param_patt.e4d]
// CHECK:STDOUT:     %self.patt: %pattern_type.69d = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.571]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.bf4 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.bf4 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_22.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.68e = ref_param_pattern [concrete = constants.%self.param_patt.3b4]
// CHECK:STDOUT:     %self.patt: %pattern_type.68e = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c9e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.f26 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.f26 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.8: %Destroy.WithSelf.Op.type.ef016f.8 = fn_decl @Destroy.WithSelf.Op.loc13_22.2 [concrete = constants.%Destroy.WithSelf.Op.403171.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.68e = ref_param_pattern [concrete = constants.%self.param_patt.3b4]
// CHECK:STDOUT:     %self.patt: %pattern_type.68e = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c9e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.f26 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.f26 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_22.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.321 = ref_param_pattern [concrete = constants.%self.param_patt.393]
// CHECK:STDOUT:     %self.patt: %pattern_type.321 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a2d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Result.250 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Result.250 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.9: %Destroy.WithSelf.Op.type.ef016f.9 = fn_decl @Destroy.WithSelf.Op.loc13_22.3 [concrete = constants.%Destroy.WithSelf.Op.403171.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.321 = ref_param_pattern [concrete = constants.%self.param_patt.393]
// CHECK:STDOUT:     %self.patt: %pattern_type.321 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a2d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Result.250 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Result.250 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Basic.decl: %Basic.type = fn_decl @Basic [concrete = constants.%Basic] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.321 = out_param_pattern [concrete = constants.%return.param_patt.8f8]
// CHECK:STDOUT:     %return.patt: %pattern_type.321 = return_slot_pattern %return.param_patt, %Result.loc12 [concrete = constants.%return.patt.d36]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc12: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc12_33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc12_38: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Result.loc12: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:     %.loc12_41.3: Core.Form = init_form %Result.loc12 [concrete = constants.%.4ba]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc12_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %Result.250 = out_param call_param1
// CHECK:STDOUT:     %return: ref %Result.250 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Statement.decl: %Statement.type = fn_decl @Statement [concrete = constants.%Statement] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.321 = out_param_pattern [concrete = constants.%return.param_patt.8f8]
// CHECK:STDOUT:     %return.patt: %pattern_type.321 = return_slot_pattern %return.param_patt, %Result.loc18 [concrete = constants.%return.patt.d36]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc18: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc18: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc18_37: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc18_42: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Result.loc18: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:     %.loc18_45.3: Core.Form = init_form %Result.loc18 [concrete = constants.%.4ba]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc18_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %Result.250 = out_param call_param1
// CHECK:STDOUT:     %return: ref %Result.250 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Chain.decl: %Chain.type = fn_decl @Chain [concrete = constants.%Chain] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.321 = out_param_pattern [concrete = constants.%return.param_patt.8f8]
// CHECK:STDOUT:     %return.patt: %pattern_type.321 = return_slot_pattern %return.param_patt, %Result.loc25 [concrete = constants.%return.patt.d36]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc25: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc25: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc25_33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc25_38: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Result.loc25: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:     %.loc25_41.4: Core.Form = init_form %Result.loc25 [concrete = constants.%.4ba]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc25_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %Result.250 = out_param call_param1
// CHECK:STDOUT:     %return: ref %Result.250 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Argument.decl: %Argument.type = fn_decl @Argument [concrete = constants.%Argument] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.321 = out_param_pattern [concrete = constants.%return.param_patt.8f8]
// CHECK:STDOUT:     %return.patt: %pattern_type.321 = return_slot_pattern %return.param_patt, %Result.loc31 [concrete = constants.%return.patt.d36]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc31: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc31: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc31_36: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc31_41: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Result.loc31: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:     %.loc31_44.3: Core.Form = init_form %Result.loc31 [concrete = constants.%.4ba]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc31_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %Result.250 = out_param call_param1
// CHECK:STDOUT:     %return: ref %Result.250 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Basic(%n.param: %i32) -> out %return.param: %Result.250 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %f.var: ref %i32 = var_storage %f.var_patt
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc13_22.1: ref %Result.250 = temporary_storage
// CHECK:STDOUT:   %Open.call: init %Result.250 to %.loc13_22.1 = call %Open.ref(%n.ref)
// CHECK:STDOUT:   %.loc13_22.2: ref %Result.250 = temporary %.loc13_22.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.c8a = impl_witness_access constants.%Try.impl_witness.468, element2 [concrete = constants.%Result.as.Try.impl.Branch.667]
// CHECK:STDOUT:   %bound_method.loc13_23.1: <bound method> = bound_method %.loc13_22.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc13_23.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.536]
// CHECK:STDOUT:   %bound_method.loc13_23.2: <bound method> = bound_method %.loc13_22.2, %specific_fn.loc13_23.1
// CHECK:STDOUT:   %.loc13_23.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc13_22.3: %Result.250 = acquire_value %.loc13_22.2
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc13_23.1 = call %bound_method.loc13_23.2(%.loc13_22.3)
// CHECK:STDOUT:   %.loc13_23.2: ref %ControlFlow.32a = temporary %.loc13_23.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_23.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_23.3: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_23.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc13_23.2: <specific function> = specific_function %impl.elem0.loc13_23.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_23.4: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_23.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13: init %u1 = call %bound_method.loc13_23.4(%int_1.loc13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_23.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_23.4: %u1 = converted %int_1.loc13, %.loc13_23.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_23.5: ref %u1 = class_element_access %.loc13_23.2, element0
// CHECK:STDOUT:   %impl.elem0.loc13_23.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_23.5: <bound method> = bound_method %.loc13_23.4, %impl.elem0.loc13_23.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc13_23.3: <specific function> = specific_function %impl.elem0.loc13_23.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_23.6: <bound method> = bound_method %.loc13_23.4, %specific_fn.loc13_23.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc13_23.6: %u1 = acquire_value %.loc13_23.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc13_23.6(%.loc13_23.4, %.loc13_23.6)
// CHECK:STDOUT:   %.loc13_23.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc13_23.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc13_23.7
// CHECK:STDOUT:   if %.loc13_23.8 br !.loc13_23.1 else br !.loc13_23.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_23.1:
// CHECK:STDOUT:   %.loc13_23.9: ref %.b63 = class_element_access %.loc13_23.2, element1
// CHECK:STDOUT:   %.loc13_23.10: ref %tuple.type.a8a = class_element_access %.loc13_23.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc13_23.1: ref %i32 = tuple_access %.loc13_23.10, element0
// CHECK:STDOUT:   %.loc13_23.11: %i32 = acquire_value %tuple.elem0.loc13_23.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.250, (constants.%Try.impl_witness.468) [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %.loc13_23.12: %Try.type = converted constants.%Result.250, %Try.facet [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %impl.elem3: %.ff6 = impl_witness_access constants.%Try.impl_witness.468, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.faf]
// CHECK:STDOUT:   %specific_fn.loc13_23.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc12_41.1: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.250 to %.loc12_41.1 = call %specific_fn.loc13_23.4(%.loc13_23.11)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_23.1: <bound method> = bound_method %.loc13_23.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_23.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_23.1(%.loc13_23.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_22.1: <bound method> = bound_method %.loc13_22.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_22.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_22.1(%.loc13_22.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1: <bound method> = bound_method %f.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.1(%f.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_23.2:
// CHECK:STDOUT:   %.loc13_23.13: ref %.b63 = class_element_access %.loc13_23.2, element1
// CHECK:STDOUT:   %.loc13_23.14: ref %tuple.type.a8a = class_element_access %.loc13_23.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc13_23.2: ref %i32 = tuple_access %.loc13_23.14, element0
// CHECK:STDOUT:   %.loc13_23.15: %i32 = acquire_value %tuple.elem0.loc13_23.2
// CHECK:STDOUT:   %impl.elem0.loc13_23.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc13_23.7: <bound method> = bound_method %.loc13_23.15, %impl.elem0.loc13_23.3
// CHECK:STDOUT:   %specific_fn.loc13_23.5: <specific function> = specific_function %impl.elem0.loc13_23.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_23.8: <bound method> = bound_method %.loc13_23.15, %specific_fn.loc13_23.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc13_23.8(%.loc13_23.15)
// CHECK:STDOUT:   assign %f.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %f: ref %i32 = wrapper_binding f, %f.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %f.patt: %pattern_type.6b6 = ref_binding_pattern f [concrete = constants.%f.patt]
// CHECK:STDOUT:     %f.var_patt: %pattern_type.6b6 = var_pattern %f.patt [concrete = constants.%f.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ref.loc14: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc14: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc14_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc14_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Result.loc14: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:   %.loc14_31: %Result.Ok.type.39c = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %Ok.ref: %Result.Ok.type.39c = name_ref Ok, %.loc14_31 [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %f.ref: ref %i32 = name_ref f, %f
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:   %bound_method.loc14_37.1: <bound method> = bound_method %f.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc14_37: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:   %bound_method.loc14_37.2: <bound method> = bound_method %f.ref, %specific_fn.loc14_37
// CHECK:STDOUT:   %.loc14_35: %i32 = acquire_value %f.ref
// CHECK:STDOUT:   %.loc14_37.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc14_37.1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %.loc14_35, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:   %bound_method.loc14_37.3: <bound method> = bound_method %.loc14_35, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_39.1: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc14_39: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_39.2: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14_39 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i32 = call %bound_method.loc14_39.2(%int_1.loc14) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14_39.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14_39.2: %i32 = converted %int_1.loc14, %.loc14_39.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc14_37.3(%.loc14_35, %.loc14_39.2)
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc12_41.2: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc14_37.2: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc14_37.3: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc14_37.2
// CHECK:STDOUT:   %Result.Ok.call: init %Result.250 to %.loc12_41.2 = call %Result.Ok.specific_fn(%.loc14_37.3)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_23.2: <bound method> = bound_method %.loc13_23.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_23.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_23.2(%.loc13_23.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_22.2: <bound method> = bound_method %.loc13_22.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_22.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_22.2(%.loc13_22.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2: <bound method> = bound_method %f.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_3.2(%f.var)
// CHECK:STDOUT:   return %Result.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_23.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_23.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_23.1(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_23.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_23.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_23.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_23.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_23.3(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_23.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_23.4(%self.param: ref %.b63) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_23.4(%self.param: ref %.b63) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_23.4(%self.param: ref %.b63) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_23.5(%self.param: ref %struct_type.discriminant.payload.88b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc13_23.1: ref %.b63 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_23.1: <bound method> = bound_method %.loc13_23.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_23.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_23.1(%.loc13_23.1)
// CHECK:STDOUT:   %.loc13_23.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_23.2: <bound method> = bound_method %.loc13_23.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_23.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_23.2(%.loc13_23.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_23.5(%self.param: ref %struct_type.discriminant.payload.88b) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_23.5(%self.param: ref %struct_type.discriminant.payload.88b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_23.6(%self.param: ref %ControlFlow.32a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_23.6(%self.param: ref %ControlFlow.32a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_23.6(%self.param: ref %ControlFlow.32a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_22.1(%self.param: ref %.bf4) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_22.1(%self.param: ref %.bf4) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_22.1(%self.param: ref %.bf4) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.7(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.7(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_22.2(%self.param: ref %struct_type.discriminant.payload.f26) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc13_22.1: ref %.bf4 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_22.1: <bound method> = bound_method %.loc13_22.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.7
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_22.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_22.1(%.loc13_22.1)
// CHECK:STDOUT:   %.loc13_22.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_22.2: <bound method> = bound_method %.loc13_22.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_22.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_22.2(%.loc13_22.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_22.2(%self.param: ref %struct_type.discriminant.payload.f26) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_22.2(%self.param: ref %struct_type.discriminant.payload.f26) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.8(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.8(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_22.3(%self.param: ref %Result.250) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_22.3(%self.param: ref %Result.250) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_22.3(%self.param: ref %Result.250) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.9(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.9(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Statement(%n.param: %i32) -> out %return.param: %Result.250 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc19: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc19_9.1: ref %Result.250 = temporary_storage
// CHECK:STDOUT:   %Open.call: init %Result.250 to %.loc19_9.1 = call %Open.ref(%n.ref.loc19)
// CHECK:STDOUT:   %.loc19_9.2: ref %Result.250 = temporary %.loc19_9.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.c8a = impl_witness_access constants.%Try.impl_witness.468, element2 [concrete = constants.%Result.as.Try.impl.Branch.667]
// CHECK:STDOUT:   %bound_method.loc19_10.1: <bound method> = bound_method %.loc19_9.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc19_10.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.536]
// CHECK:STDOUT:   %bound_method.loc19_10.2: <bound method> = bound_method %.loc19_9.2, %specific_fn.loc19_10.1
// CHECK:STDOUT:   %.loc19_10.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc19_9.3: %Result.250 = acquire_value %.loc19_9.2
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc19_10.1 = call %bound_method.loc19_10.2(%.loc19_9.3)
// CHECK:STDOUT:   %.loc19_10.2: ref %ControlFlow.32a = temporary %.loc19_10.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc19_10.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc19_10.3: <bound method> = bound_method %int_1, %impl.elem0.loc19_10.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc19_10.2: <specific function> = specific_function %impl.elem0.loc19_10.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc19_10.4: <bound method> = bound_method %int_1, %specific_fn.loc19_10.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc19_10.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc19_10.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc19_10.4: %u1 = converted %int_1, %.loc19_10.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc19_10.5: ref %u1 = class_element_access %.loc19_10.2, element0
// CHECK:STDOUT:   %impl.elem0.loc19_10.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc19_10.5: <bound method> = bound_method %.loc19_10.4, %impl.elem0.loc19_10.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc19_10.3: <specific function> = specific_function %impl.elem0.loc19_10.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc19_10.6: <bound method> = bound_method %.loc19_10.4, %specific_fn.loc19_10.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc19_10.6: %u1 = acquire_value %.loc19_10.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc19_10.6(%.loc19_10.4, %.loc19_10.6)
// CHECK:STDOUT:   %.loc19_10.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc19_10.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc19_10.7
// CHECK:STDOUT:   if %.loc19_10.8 br !.loc19_10.1 else br !.loc19_10.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc19_10.1:
// CHECK:STDOUT:   %.loc19_10.9: ref %.b63 = class_element_access %.loc19_10.2, element1
// CHECK:STDOUT:   %.loc19_10.10: ref %tuple.type.a8a = class_element_access %.loc19_10.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc19_10.1: ref %i32 = tuple_access %.loc19_10.10, element0
// CHECK:STDOUT:   %.loc19_10.11: %i32 = acquire_value %tuple.elem0.loc19_10.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.250, (constants.%Try.impl_witness.468) [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %.loc19_10.12: %Try.type = converted constants.%Result.250, %Try.facet [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %impl.elem3: %.ff6 = impl_witness_access constants.%Try.impl_witness.468, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.faf]
// CHECK:STDOUT:   %specific_fn.loc19_10.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc18_45.1: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.250 to %.loc18_45.1 = call %specific_fn.loc19_10.4(%.loc19_10.11)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc19_10.1: <bound method> = bound_method %.loc19_10.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc19_10.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc19_10.1(%.loc19_10.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc19_9.1: <bound method> = bound_method %.loc19_9.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc19_9.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc19_9.1(%.loc19_9.2)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc19_10.2:
// CHECK:STDOUT:   %.loc19_10.13: ref %.b63 = class_element_access %.loc19_10.2, element1
// CHECK:STDOUT:   %.loc19_10.14: ref %tuple.type.a8a = class_element_access %.loc19_10.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc19_10.2: ref %i32 = tuple_access %.loc19_10.14, element0
// CHECK:STDOUT:   %.loc19_10.15: %i32 = acquire_value %tuple.elem0.loc19_10.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc19_10.2: <bound method> = bound_method %.loc19_10.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc19_10.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc19_10.2(%.loc19_10.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc19_9.2: <bound method> = bound_method %.loc19_9.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc19_9.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc19_9.2(%.loc19_9.2)
// CHECK:STDOUT:   %Core.ref.loc20: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc20: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc20_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc20_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Result.loc20: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:   %.loc20: %Result.Ok.type.39c = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %Ok.ref: %Result.Ok.type.39c = name_ref Ok, %.loc20 [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %n.ref.loc20: %i32 = name_ref n, %n
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc18_45.2: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.Ok.call: init %Result.250 to %.loc18_45.2 = call %Result.Ok.specific_fn(%n.ref.loc20)
// CHECK:STDOUT:   return %Result.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Chain(%n.param: %i32) -> out %return.param: %Result.250 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.var: ref %i32 = var_storage %t.var_patt
// CHECK:STDOUT:   %Open.ref.loc26_16: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %Open.ref.loc26_21: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc26_27.1: ref %Result.250 = temporary_storage
// CHECK:STDOUT:   %Open.call.loc26_27: init %Result.250 to %.loc26_27.1 = call %Open.ref.loc26_21(%n.ref)
// CHECK:STDOUT:   %.loc26_27.2: ref %Result.250 = temporary %.loc26_27.1, %Open.call.loc26_27
// CHECK:STDOUT:   %impl.elem2.loc26_28: %.c8a = impl_witness_access constants.%Try.impl_witness.468, element2 [concrete = constants.%Result.as.Try.impl.Branch.667]
// CHECK:STDOUT:   %bound_method.loc26_28.1: <bound method> = bound_method %.loc26_27.2, %impl.elem2.loc26_28
// CHECK:STDOUT:   %specific_fn.loc26_28.1: <specific function> = specific_function %impl.elem2.loc26_28, @Result.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.536]
// CHECK:STDOUT:   %bound_method.loc26_28.2: <bound method> = bound_method %.loc26_27.2, %specific_fn.loc26_28.1
// CHECK:STDOUT:   %.loc26_28.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc26_27.3: %Result.250 = acquire_value %.loc26_27.2
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call.loc26_28: init %ControlFlow.32a to %.loc26_28.1 = call %bound_method.loc26_28.2(%.loc26_27.3)
// CHECK:STDOUT:   %.loc26_28.2: ref %ControlFlow.32a = temporary %.loc26_28.1, %Result.as.Try.impl.Branch.call.loc26_28
// CHECK:STDOUT:   %int_1.loc26_28: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc26_28.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc26_28.3: <bound method> = bound_method %int_1.loc26_28, %impl.elem0.loc26_28.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc26_28.2: <specific function> = specific_function %impl.elem0.loc26_28.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc26_28.4: <bound method> = bound_method %int_1.loc26_28, %specific_fn.loc26_28.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26_28: init %u1 = call %bound_method.loc26_28.4(%int_1.loc26_28) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_28.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26_28 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_28.4: %u1 = converted %int_1.loc26_28, %.loc26_28.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_28.5: ref %u1 = class_element_access %.loc26_28.2, element0
// CHECK:STDOUT:   %impl.elem0.loc26_28.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc26_28.5: <bound method> = bound_method %.loc26_28.4, %impl.elem0.loc26_28.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc26_28.3: <specific function> = specific_function %impl.elem0.loc26_28.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc26_28.6: <bound method> = bound_method %.loc26_28.4, %specific_fn.loc26_28.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc26_28.6: %u1 = acquire_value %.loc26_28.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc26_28: init bool = call %bound_method.loc26_28.6(%.loc26_28.4, %.loc26_28.6)
// CHECK:STDOUT:   %.loc26_28.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc26_28
// CHECK:STDOUT:   %.loc26_28.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc26_28, %.loc26_28.7
// CHECK:STDOUT:   if %.loc26_28.8 br !.loc26_28.1 else br !.loc26_28.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc26_28.1:
// CHECK:STDOUT:   %.loc26_28.9: ref %.b63 = class_element_access %.loc26_28.2, element1
// CHECK:STDOUT:   %.loc26_28.10: ref %tuple.type.a8a = class_element_access %.loc26_28.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc26_28.1: ref %i32 = tuple_access %.loc26_28.10, element0
// CHECK:STDOUT:   %.loc26_28.11: %i32 = acquire_value %tuple.elem0.loc26_28.1
// CHECK:STDOUT:   %Try.facet.loc26_28: %Try.type = facet_value constants.%Result.250, (constants.%Try.impl_witness.468) [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %.loc26_28.12: %Try.type = converted constants.%Result.250, %Try.facet.loc26_28 [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %impl.elem3.loc26_28: %.ff6 = impl_witness_access constants.%Try.impl_witness.468, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.faf]
// CHECK:STDOUT:   %specific_fn.loc26_28.4: <specific function> = specific_function %impl.elem3.loc26_28, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc25_41.1: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call.loc26_28: init %Result.250 to %.loc25_41.1 = call %specific_fn.loc26_28.4(%.loc26_28.11)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_28.1: <bound method> = bound_method %.loc26_28.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_28.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_28.1(%.loc26_28.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_27.1: <bound method> = bound_method %.loc26_27.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_27.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_27.1(%.loc26_27.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_3.1: <bound method> = bound_method %t.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_3.1(%t.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call.loc26_28 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc26_28.2:
// CHECK:STDOUT:   %.loc26_28.13: ref %.b63 = class_element_access %.loc26_28.2, element1
// CHECK:STDOUT:   %.loc26_28.14: ref %tuple.type.a8a = class_element_access %.loc26_28.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc26_28.2: ref %i32 = tuple_access %.loc26_28.14, element0
// CHECK:STDOUT:   %.loc26_28.15: %i32 = acquire_value %tuple.elem0.loc26_28.2
// CHECK:STDOUT:   %.loc26_29.1: ref %Result.250 = temporary_storage
// CHECK:STDOUT:   %Open.call.loc26_29: init %Result.250 to %.loc26_29.1 = call %Open.ref.loc26_16(%.loc26_28.15)
// CHECK:STDOUT:   %.loc26_29.2: ref %Result.250 = temporary %.loc26_29.1, %Open.call.loc26_29
// CHECK:STDOUT:   %impl.elem2.loc26_30: %.c8a = impl_witness_access constants.%Try.impl_witness.468, element2 [concrete = constants.%Result.as.Try.impl.Branch.667]
// CHECK:STDOUT:   %bound_method.loc26_30.1: <bound method> = bound_method %.loc26_29.2, %impl.elem2.loc26_30
// CHECK:STDOUT:   %specific_fn.loc26_30.1: <specific function> = specific_function %impl.elem2.loc26_30, @Result.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.536]
// CHECK:STDOUT:   %bound_method.loc26_30.2: <bound method> = bound_method %.loc26_29.2, %specific_fn.loc26_30.1
// CHECK:STDOUT:   %.loc26_30.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc26_29.3: %Result.250 = acquire_value %.loc26_29.2
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call.loc26_30: init %ControlFlow.32a to %.loc26_30.1 = call %bound_method.loc26_30.2(%.loc26_29.3)
// CHECK:STDOUT:   %.loc26_30.2: ref %ControlFlow.32a = temporary %.loc26_30.1, %Result.as.Try.impl.Branch.call.loc26_30
// CHECK:STDOUT:   %int_1.loc26_30: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc26_30.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc26_30.3: <bound method> = bound_method %int_1.loc26_30, %impl.elem0.loc26_30.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc26_30.2: <specific function> = specific_function %impl.elem0.loc26_30.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc26_30.4: <bound method> = bound_method %int_1.loc26_30, %specific_fn.loc26_30.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26_30: init %u1 = call %bound_method.loc26_30.4(%int_1.loc26_30) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_30.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26_30 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_30.4: %u1 = converted %int_1.loc26_30, %.loc26_30.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_30.5: ref %u1 = class_element_access %.loc26_30.2, element0
// CHECK:STDOUT:   %impl.elem0.loc26_30.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc26_30.5: <bound method> = bound_method %.loc26_30.4, %impl.elem0.loc26_30.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc26_30.3: <specific function> = specific_function %impl.elem0.loc26_30.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc26_30.6: <bound method> = bound_method %.loc26_30.4, %specific_fn.loc26_30.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc26_30.6: %u1 = acquire_value %.loc26_30.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc26_30: init bool = call %bound_method.loc26_30.6(%.loc26_30.4, %.loc26_30.6)
// CHECK:STDOUT:   %.loc26_30.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc26_30
// CHECK:STDOUT:   %.loc26_30.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc26_30, %.loc26_30.7
// CHECK:STDOUT:   if %.loc26_30.8 br !.loc26_30.1 else br !.loc26_30.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc26_30.1:
// CHECK:STDOUT:   %.loc26_30.9: ref %.b63 = class_element_access %.loc26_30.2, element1
// CHECK:STDOUT:   %.loc26_30.10: ref %tuple.type.a8a = class_element_access %.loc26_30.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc26_30.1: ref %i32 = tuple_access %.loc26_30.10, element0
// CHECK:STDOUT:   %.loc26_30.11: %i32 = acquire_value %tuple.elem0.loc26_30.1
// CHECK:STDOUT:   %Try.facet.loc26_30: %Try.type = facet_value constants.%Result.250, (constants.%Try.impl_witness.468) [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %.loc26_30.12: %Try.type = converted constants.%Result.250, %Try.facet.loc26_30 [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %impl.elem3.loc26_30: %.ff6 = impl_witness_access constants.%Try.impl_witness.468, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.faf]
// CHECK:STDOUT:   %specific_fn.loc26_30.4: <specific function> = specific_function %impl.elem3.loc26_30, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc25_41.2: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call.loc26_30: init %Result.250 to %.loc25_41.2 = call %specific_fn.loc26_30.4(%.loc26_30.11)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_30.1: <bound method> = bound_method %.loc26_30.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_30.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_30.1(%.loc26_30.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_29.1: <bound method> = bound_method %.loc26_29.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_29.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_29.1(%.loc26_29.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_28.2: <bound method> = bound_method %.loc26_28.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_28.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_28.2(%.loc26_28.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_27.2: <bound method> = bound_method %.loc26_27.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_27.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_27.2(%.loc26_27.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_3.2: <bound method> = bound_method %t.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_3.2(%t.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call.loc26_30 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc26_30.2:
// CHECK:STDOUT:   %.loc26_30.13: ref %.b63 = class_element_access %.loc26_30.2, element1
// CHECK:STDOUT:   %.loc26_30.14: ref %tuple.type.a8a = class_element_access %.loc26_30.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc26_30.2: ref %i32 = tuple_access %.loc26_30.14, element0
// CHECK:STDOUT:   %.loc26_30.15: %i32 = acquire_value %tuple.elem0.loc26_30.2
// CHECK:STDOUT:   %impl.elem0.loc26_30.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc26_30.7: <bound method> = bound_method %.loc26_30.15, %impl.elem0.loc26_30.3
// CHECK:STDOUT:   %specific_fn.loc26_30.5: <specific function> = specific_function %impl.elem0.loc26_30.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc26_30.8: <bound method> = bound_method %.loc26_30.15, %specific_fn.loc26_30.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc26_30.8(%.loc26_30.15)
// CHECK:STDOUT:   assign %t.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %t: ref %i32 = wrapper_binding t, %t.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %t.patt: %pattern_type.6b6 = ref_binding_pattern t [concrete = constants.%t.patt]
// CHECK:STDOUT:     %t.var_patt: %pattern_type.6b6 = var_pattern %t.patt [concrete = constants.%t.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ref.loc27: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc27: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc27_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc27_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Result.loc27: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:   %.loc27_31: %Result.Ok.type.39c = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %Ok.ref: %Result.Ok.type.39c = name_ref Ok, %.loc27_31 [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %t.ref: ref %i32 = name_ref t, %t
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc25_41.3: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc27_35: %i32 = acquire_value %t.ref
// CHECK:STDOUT:   %Result.Ok.call: init %Result.250 to %.loc25_41.3 = call %Result.Ok.specific_fn(%.loc27_35)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_30.2: <bound method> = bound_method %.loc26_30.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_30.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_30.2(%.loc26_30.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_29.2: <bound method> = bound_method %.loc26_29.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_29.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_29.2(%.loc26_29.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_28.3: <bound method> = bound_method %.loc26_28.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_28.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_28.3(%.loc26_28.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_27.3: <bound method> = bound_method %.loc26_27.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_27.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_27.3(%.loc26_27.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc26_3.3: <bound method> = bound_method %t.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc26_3.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc26_3.3(%t.var)
// CHECK:STDOUT:   return %Result.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Argument(%n.param: %i32) -> out %return.param: %Result.250 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %i32 = var_storage %v.var_patt
// CHECK:STDOUT:   %Callee.ref: %Callee.type = name_ref Callee, file.%Callee.decl [concrete = constants.%Callee]
// CHECK:STDOUT:   %n.ref.loc32_23: %i32 = name_ref n, %n
// CHECK:STDOUT:   %Open.ref: %Open.type = name_ref Open, file.%Open.decl [concrete = constants.%Open]
// CHECK:STDOUT:   %n.ref.loc32_31: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc32_32.1: ref %Result.250 = temporary_storage
// CHECK:STDOUT:   %Open.call: init %Result.250 to %.loc32_32.1 = call %Open.ref(%n.ref.loc32_31)
// CHECK:STDOUT:   %.loc32_32.2: ref %Result.250 = temporary %.loc32_32.1, %Open.call
// CHECK:STDOUT:   %impl.elem2: %.c8a = impl_witness_access constants.%Try.impl_witness.468, element2 [concrete = constants.%Result.as.Try.impl.Branch.667]
// CHECK:STDOUT:   %bound_method.loc32_33.1: <bound method> = bound_method %.loc32_32.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc32_33.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.536]
// CHECK:STDOUT:   %bound_method.loc32_33.2: <bound method> = bound_method %.loc32_32.2, %specific_fn.loc32_33.1
// CHECK:STDOUT:   %.loc32_33.1: ref %ControlFlow.32a = temporary_storage
// CHECK:STDOUT:   %.loc32_32.3: %Result.250 = acquire_value %.loc32_32.2
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.32a to %.loc32_33.1 = call %bound_method.loc32_33.2(%.loc32_32.3)
// CHECK:STDOUT:   %.loc32_33.2: ref %ControlFlow.32a = temporary %.loc32_33.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc32_33.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc32_33.3: <bound method> = bound_method %int_1, %impl.elem0.loc32_33.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc32_33.2: <specific function> = specific_function %impl.elem0.loc32_33.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc32_33.4: <bound method> = bound_method %int_1, %specific_fn.loc32_33.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc32_33.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc32_33.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc32_33.4: %u1 = converted %int_1, %.loc32_33.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc32_33.5: ref %u1 = class_element_access %.loc32_33.2, element0
// CHECK:STDOUT:   %impl.elem0.loc32_33.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc32_33.5: <bound method> = bound_method %.loc32_33.4, %impl.elem0.loc32_33.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc32_33.3: <specific function> = specific_function %impl.elem0.loc32_33.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc32_33.6: <bound method> = bound_method %.loc32_33.4, %specific_fn.loc32_33.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc32_33.6: %u1 = acquire_value %.loc32_33.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc32_33.6(%.loc32_33.4, %.loc32_33.6)
// CHECK:STDOUT:   %.loc32_33.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc32_33.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc32_33.7
// CHECK:STDOUT:   if %.loc32_33.8 br !.loc32_33.1 else br !.loc32_33.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc32_33.1:
// CHECK:STDOUT:   %.loc32_33.9: ref %.b63 = class_element_access %.loc32_33.2, element1
// CHECK:STDOUT:   %.loc32_33.10: ref %tuple.type.a8a = class_element_access %.loc32_33.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc32_33.1: ref %i32 = tuple_access %.loc32_33.10, element0
// CHECK:STDOUT:   %.loc32_33.11: %i32 = acquire_value %tuple.elem0.loc32_33.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.250, (constants.%Try.impl_witness.468) [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %.loc32_33.12: %Try.type = converted constants.%Result.250, %Try.facet [concrete = constants.%Try.facet.4c8]
// CHECK:STDOUT:   %impl.elem3: %.ff6 = impl_witness_access constants.%Try.impl_witness.468, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.faf]
// CHECK:STDOUT:   %specific_fn.loc32_33.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%i32) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc31_44.1: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.250 to %.loc31_44.1 = call %specific_fn.loc32_33.4(%.loc32_33.11)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_33.1: <bound method> = bound_method %.loc32_33.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_33.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_33.1(%.loc32_33.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_32.1: <bound method> = bound_method %.loc32_32.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_32.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_32.1(%.loc32_32.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_3.1: <bound method> = bound_method %v.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_3.1(%v.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc32_33.2:
// CHECK:STDOUT:   %.loc32_33.13: ref %.b63 = class_element_access %.loc32_33.2, element1
// CHECK:STDOUT:   %.loc32_33.14: ref %tuple.type.a8a = class_element_access %.loc32_33.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc32_33.2: ref %i32 = tuple_access %.loc32_33.14, element0
// CHECK:STDOUT:   %.loc32_33.15: %i32 = acquire_value %tuple.elem0.loc32_33.2
// CHECK:STDOUT:   %Callee.call: init %i32 = call %Callee.ref(%n.ref.loc32_23, %.loc32_33.15)
// CHECK:STDOUT:   assign %v.var, %Callee.call
// CHECK:STDOUT:   %i32.loc32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt.113]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ref.loc33: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc33: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc33_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc33_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Result.loc33: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:   %.loc33_31: %Result.Ok.type.39c = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %Ok.ref: %Result.Ok.type.39c = name_ref Ok, %.loc33_31 [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %v.ref: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc31_44.2: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc33_35: %i32 = acquire_value %v.ref
// CHECK:STDOUT:   %Result.Ok.call: init %Result.250 to %.loc31_44.2 = call %Result.Ok.specific_fn(%.loc33_35)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_33.2: <bound method> = bound_method %.loc32_33.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_33.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_33.2(%.loc32_33.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_32.2: <bound method> = bound_method %.loc32_32.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_32.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_32.2(%.loc32_32.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_3.2: <bound method> = bound_method %v.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_3.2(%v.var)
// CHECK:STDOUT:   return %Result.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- convert.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %ErrA: type = class_type @ErrA [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %ErrB: type = class_type @ErrB [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.af5: type = facet_type <@ImplicitAs, @ImplicitAs(%ErrB)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.6f9: <witness> = impl_witness @ErrA.as.ImplicitAs.impl.%ImplicitAs.impl_witness_table [concrete]
// CHECK:STDOUT:   %pattern_type.ecb: type = pattern_type %ErrA [concrete]
// CHECK:STDOUT:   %ErrA.as.ImplicitAs.impl.Convert.type: type = fn_type @ErrA.as.ImplicitAs.impl.Convert [concrete]
// CHECK:STDOUT:   %ErrA.as.ImplicitAs.impl.Convert: %ErrA.as.ImplicitAs.impl.Convert.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.53c: %ImplicitAs.type.af5 = facet_value %ErrA, (%ImplicitAs.impl_witness.6f9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.487: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%ErrB, %ImplicitAs.facet.53c) [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Result.9ab: type = class_type @Result, @Result(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %pattern_type.89f: type = pattern_type %Result.9ab [concrete]
// CHECK:STDOUT:   %Inner.type: type = fn_type @Inner [concrete]
// CHECK:STDOUT:   %Inner: %Inner.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.bb7: type = tuple_type (%ErrA) [concrete]
// CHECK:STDOUT:   %.e62: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a, .Err@0: %tuple.type.bb7} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.9f6: type = struct_type {.discriminant: %u1, .payload: %.e62} [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %OrderedWith.type.ad8: type = generic_interface_type @OrderedWith [concrete]
// CHECK:STDOUT:   %OrderedWith.generic: %OrderedWith.type.ad8 = struct_value () [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Result.4bc: type = class_type @Result, @Result(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %.ca7: Core.Form = init_form %Result.4bc [concrete]
// CHECK:STDOUT:   %pattern_type.1a6: type = pattern_type %Result.4bc [concrete]
// CHECK:STDOUT:   %return.param_patt.e81: %pattern_type.1a6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.3c2: %pattern_type.1a6 = return_slot_pattern %return.param_patt.e81, %Result.4bc [concrete]
// CHECK:STDOUT:   %Outer.type: type = fn_type @Outer [concrete]
// CHECK:STDOUT:   %Outer: %Outer.type = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Ok.type.8f5: type = fn_type @Result.Ok, @Result(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %Result.Ok.013: %Result.Ok.type.8f5 = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt.113: %pattern_type.6b6 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt.113 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.bca: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.fee: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.1b8: %Result.as.Try.impl.FromBreak.type.fee = struct_value () [concrete]
// CHECK:STDOUT:   %Try.impl_witness.be9: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.865: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.ac3: %Result.as.Try.impl.Branch.type.865 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.2d0: %Try.type = facet_value %Result.9ab, (%Try.impl_witness.be9) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.bb4: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.2d0) [concrete]
// CHECK:STDOUT:   %.4f0: type = fn_type_with_self_type %Try.WithSelf.Branch.type.bb4, %Try.facet.2d0 [concrete]
// CHECK:STDOUT:   %ControlFlow.46a: type = class_type @ControlFlow, @ControlFlow(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %pattern_type.639: type = pattern_type %ControlFlow.46a [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.1a3: <specific function> = specific_function %Result.as.Try.impl.Branch.ac3, @Result.as.Try.impl.Branch(%i32, %ErrA) [concrete]
// CHECK:STDOUT:   %.873: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.bb7} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.615: type = struct_type {.discriminant: %u1, .payload: %.873} [concrete]
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
// CHECK:STDOUT:   %pattern_type.322: type = pattern_type %u1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
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
// CHECK:STDOUT:   %Try.facet.c72: %Try.type = facet_value %Result.4bc, (%Try.impl_witness.bca) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.cd6: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.c72) [concrete]
// CHECK:STDOUT:   %.377: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.cd6, %Try.facet.c72 [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.1b8, @Result.as.Try.impl.FromBreak(%i32, %ErrB) [concrete]
// CHECK:STDOUT:   %.4e3: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.487, %ImplicitAs.facet.53c [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %self.param_patt.7c1: %pattern_type.322 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.945: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt.7c1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_24.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc32_24.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc32_24.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_24.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc32_24.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc32_24.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_24.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc32_24.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.4ba: %pattern_type.ecb = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.7d0: %pattern_type.ecb = wrapper_binding_pattern self, %self.param_patt.4ba [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_24.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc32_24.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc32_24.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.814: type = pattern_type %tuple.type.bb7 [concrete]
// CHECK:STDOUT:   %self.param_patt.1eb: %pattern_type.814 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.fae: %pattern_type.814 = wrapper_binding_pattern self, %self.param_patt.1eb [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_24.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc32_24.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.d1c: type = pattern_type %.873 [concrete]
// CHECK:STDOUT:   %self.param_patt.83d: %pattern_type.d1c = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e09: %pattern_type.d1c = wrapper_binding_pattern self, %self.param_patt.83d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_24.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc32_24.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.6: type = fn_type @Destroy.WithSelf.SelfDestruct.loc32_24.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.6: %Destroy.WithSelf.SelfDestruct.type.fbceb5.6 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.582: type = pattern_type %struct_type.discriminant.payload.615 [concrete]
// CHECK:STDOUT:   %self.param_patt.f61: %pattern_type.582 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.c88: %pattern_type.582 = wrapper_binding_pattern self, %self.param_patt.f61 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_24.7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.7: type = fn_type @Destroy.WithSelf.Op.loc32_24.7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.7: %Destroy.WithSelf.Op.type.ef016f.7 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.f2b: %pattern_type.639 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.657: %pattern_type.639 = wrapper_binding_pattern self, %self.param_patt.f2b [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_24.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.8: type = fn_type @Destroy.WithSelf.Op.loc32_24.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.8: %Destroy.WithSelf.Op.type.ef016f.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.8: type = fn_type @Destroy.WithSelf.SelfDestruct.loc32_24.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.8: %Destroy.WithSelf.SelfDestruct.type.fbceb5.8 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.0c4: type = pattern_type %.e62 [concrete]
// CHECK:STDOUT:   %self.param_patt.c23: %pattern_type.0c4 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.b8d: %pattern_type.0c4 = wrapper_binding_pattern self, %self.param_patt.c23 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_23.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.9: type = fn_type @Destroy.WithSelf.Op.loc32_23.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.9: %Destroy.WithSelf.Op.type.ef016f.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.9: type = fn_type @Destroy.WithSelf.SelfDestruct.loc32_23.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.9: %Destroy.WithSelf.SelfDestruct.type.fbceb5.9 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.c15: type = pattern_type %struct_type.discriminant.payload.9f6 [concrete]
// CHECK:STDOUT:   %self.param_patt.ebd: %pattern_type.c15 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.c4b: %pattern_type.c15 = wrapper_binding_pattern self, %self.param_patt.ebd [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_23.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.10: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.10: type = fn_type @Destroy.WithSelf.Op.loc32_23.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.10: %Destroy.WithSelf.Op.type.ef016f.10 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.a40: %pattern_type.89f = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.6d8: %pattern_type.89f = wrapper_binding_pattern self, %self.param_patt.a40 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc32_23.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.11: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.11: type = fn_type @Destroy.WithSelf.Op.loc32_23.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.11: %Destroy.WithSelf.Op.type.ef016f.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.11: type = fn_type @Destroy.WithSelf.SelfDestruct.loc32_23.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.11: %Destroy.WithSelf.SelfDestruct.type.fbceb5.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn.9ac: <specific function> = specific_function %Result.Ok.013, @Result.Ok(%i32, %ErrB) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Result = %Core.Result
// CHECK:STDOUT:     .OrderedWith = %Core.OrderedWith
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.Result: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.OrderedWith: %OrderedWith.type.ad8 = import_ref Core//prelude/operators/comparison, OrderedWith, loaded [concrete = constants.%OrderedWith.generic]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_24.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc32_24.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_24.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc32_24.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_24.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc32_24.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_24.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ecb = ref_param_pattern [concrete = constants.%self.param_patt.4ba]
// CHECK:STDOUT:     %self.patt: %pattern_type.ecb = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.7d0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ErrA = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ErrA = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc32_24.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ecb = ref_param_pattern [concrete = constants.%self.param_patt.4ba]
// CHECK:STDOUT:     %self.patt: %pattern_type.ecb = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.7d0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ErrA = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ErrA = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_24.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.814 = ref_param_pattern [concrete = constants.%self.param_patt.1eb]
// CHECK:STDOUT:     %self.patt: %pattern_type.814 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.fae]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.bb7 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.bb7 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc32_24.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.814 = ref_param_pattern [concrete = constants.%self.param_patt.1eb]
// CHECK:STDOUT:     %self.patt: %pattern_type.814 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.fae]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.bb7 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.bb7 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_24.6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.d1c = ref_param_pattern [concrete = constants.%self.param_patt.83d]
// CHECK:STDOUT:     %self.patt: %pattern_type.d1c = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e09]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.873 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.873 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc32_24.6 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.d1c = ref_param_pattern [concrete = constants.%self.param_patt.83d]
// CHECK:STDOUT:     %self.patt: %pattern_type.d1c = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e09]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.873 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.873 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_24.7 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.582 = ref_param_pattern [concrete = constants.%self.param_patt.f61]
// CHECK:STDOUT:     %self.patt: %pattern_type.582 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c88]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.615 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.615 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.7: %Destroy.WithSelf.Op.type.ef016f.7 = fn_decl @Destroy.WithSelf.Op.loc32_24.7 [concrete = constants.%Destroy.WithSelf.Op.403171.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.582 = ref_param_pattern [concrete = constants.%self.param_patt.f61]
// CHECK:STDOUT:     %self.patt: %pattern_type.582 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c88]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.615 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.615 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_24.8 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.639 = ref_param_pattern [concrete = constants.%self.param_patt.f2b]
// CHECK:STDOUT:     %self.patt: %pattern_type.639 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.657]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ControlFlow.46a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ControlFlow.46a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.8: %Destroy.WithSelf.Op.type.ef016f.8 = fn_decl @Destroy.WithSelf.Op.loc32_24.8 [concrete = constants.%Destroy.WithSelf.Op.403171.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.639 = ref_param_pattern [concrete = constants.%self.param_patt.f2b]
// CHECK:STDOUT:     %self.patt: %pattern_type.639 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.657]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ControlFlow.46a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ControlFlow.46a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_23.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0c4 = ref_param_pattern [concrete = constants.%self.param_patt.c23]
// CHECK:STDOUT:     %self.patt: %pattern_type.0c4 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.b8d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e62 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e62 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.9: %Destroy.WithSelf.Op.type.ef016f.9 = fn_decl @Destroy.WithSelf.Op.loc32_23.1 [concrete = constants.%Destroy.WithSelf.Op.403171.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0c4 = ref_param_pattern [concrete = constants.%self.param_patt.c23]
// CHECK:STDOUT:     %self.patt: %pattern_type.0c4 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.b8d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e62 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e62 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.10: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_23.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.10] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.c15 = ref_param_pattern [concrete = constants.%self.param_patt.ebd]
// CHECK:STDOUT:     %self.patt: %pattern_type.c15 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c4b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.9f6 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.9f6 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.10: %Destroy.WithSelf.Op.type.ef016f.10 = fn_decl @Destroy.WithSelf.Op.loc32_23.2 [concrete = constants.%Destroy.WithSelf.Op.403171.10] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.c15 = ref_param_pattern [concrete = constants.%self.param_patt.ebd]
// CHECK:STDOUT:     %self.patt: %pattern_type.c15 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c4b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.9f6 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.9f6 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.11: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc32_23.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.11] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.89f = ref_param_pattern [concrete = constants.%self.param_patt.a40]
// CHECK:STDOUT:     %self.patt: %pattern_type.89f = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.6d8]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Result.9ab = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Result.9ab = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.11: %Destroy.WithSelf.Op.type.ef016f.11 = fn_decl @Destroy.WithSelf.Op.loc32_23.3 [concrete = constants.%Destroy.WithSelf.Op.403171.11] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.89f = ref_param_pattern [concrete = constants.%self.param_patt.a40]
// CHECK:STDOUT:     %self.patt: %pattern_type.89f = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.6d8]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Result.9ab = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Result.9ab = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Outer.decl: %Outer.type = fn_decl @Outer [concrete = constants.%Outer] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.1a6 = out_param_pattern [concrete = constants.%return.param_patt.e81]
// CHECK:STDOUT:     %return.patt: %pattern_type.1a6 = return_slot_pattern %return.param_patt, %Result.loc31 [concrete = constants.%return.patt.3c2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc31: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc31: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc31_33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ErrB.ref.loc31: type = name_ref ErrB, file.%ErrB.decl [concrete = constants.%ErrB]
// CHECK:STDOUT:     %Result.loc31: type = class_type @Result, @Result(constants.%i32, constants.%ErrB) [concrete = constants.%Result.4bc]
// CHECK:STDOUT:     %.loc31_42.3: Core.Form = init_form %Result.loc31 [concrete = constants.%.ca7]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc31_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %Result.4bc = out_param call_param1
// CHECK:STDOUT:     %return: ref %Result.4bc = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Outer(%n.param: %i32) -> out %return.param: %Result.4bc {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %i32 = var_storage %v.var_patt
// CHECK:STDOUT:   %Inner.ref: %Inner.type = name_ref Inner, file.%Inner.decl [concrete = constants.%Inner]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc32_23.1: ref %Result.9ab = temporary_storage
// CHECK:STDOUT:   %Inner.call: init %Result.9ab to %.loc32_23.1 = call %Inner.ref(%n.ref)
// CHECK:STDOUT:   %.loc32_23.2: ref %Result.9ab = temporary %.loc32_23.1, %Inner.call
// CHECK:STDOUT:   %impl.elem2: %.4f0 = impl_witness_access constants.%Try.impl_witness.be9, element2 [concrete = constants.%Result.as.Try.impl.Branch.ac3]
// CHECK:STDOUT:   %bound_method.loc32_24.1: <bound method> = bound_method %.loc32_23.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc32_24.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%i32, constants.%ErrA) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.1a3]
// CHECK:STDOUT:   %bound_method.loc32_24.2: <bound method> = bound_method %.loc32_23.2, %specific_fn.loc32_24.1
// CHECK:STDOUT:   %.loc32_24.1: ref %ControlFlow.46a = temporary_storage
// CHECK:STDOUT:   %.loc32_23.3: %Result.9ab = acquire_value %.loc32_23.2
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.46a to %.loc32_24.1 = call %bound_method.loc32_24.2(%.loc32_23.3)
// CHECK:STDOUT:   %.loc32_24.2: ref %ControlFlow.46a = temporary %.loc32_24.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc32_24.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc32_24.3: <bound method> = bound_method %int_1, %impl.elem0.loc32_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc32_24.2: <specific function> = specific_function %impl.elem0.loc32_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc32_24.4: <bound method> = bound_method %int_1, %specific_fn.loc32_24.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc32_24.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc32_24.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc32_24.4: %u1 = converted %int_1, %.loc32_24.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc32_24.5: ref %u1 = class_element_access %.loc32_24.2, element0
// CHECK:STDOUT:   %impl.elem0.loc32_24.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc32_24.5: <bound method> = bound_method %.loc32_24.4, %impl.elem0.loc32_24.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc32_24.3: <specific function> = specific_function %impl.elem0.loc32_24.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc32_24.6: <bound method> = bound_method %.loc32_24.4, %specific_fn.loc32_24.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc32_24.6: %u1 = acquire_value %.loc32_24.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc32_24.6(%.loc32_24.4, %.loc32_24.6)
// CHECK:STDOUT:   %.loc32_24.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc32_24.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc32_24.7
// CHECK:STDOUT:   if %.loc32_24.8 br !.loc32_24.1 else br !.loc32_24.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc32_24.1:
// CHECK:STDOUT:   %.loc32_24.9: ref %.873 = class_element_access %.loc32_24.2, element1
// CHECK:STDOUT:   %.loc32_24.10: ref %tuple.type.bb7 = class_element_access %.loc32_24.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc32_24.1: ref %ErrA = tuple_access %.loc32_24.10, element0
// CHECK:STDOUT:   %.loc32_24.11: %ErrA = acquire_value %tuple.elem0.loc32_24.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.4bc, (constants.%Try.impl_witness.bca) [concrete = constants.%Try.facet.c72]
// CHECK:STDOUT:   %.loc32_24.12: %Try.type = converted constants.%Result.4bc, %Try.facet [concrete = constants.%Try.facet.c72]
// CHECK:STDOUT:   %impl.elem3: %.377 = impl_witness_access constants.%Try.impl_witness.bca, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.1b8]
// CHECK:STDOUT:   %specific_fn.loc32_24.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%i32, constants.%ErrB) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc31_42.1: ref %Result.4bc = splice_block %return.param {}
// CHECK:STDOUT:   %impl.elem0.loc32_24.3: %.4e3 = impl_witness_access constants.%ImplicitAs.impl_witness.6f9, element0 [concrete = constants.%ErrA.as.ImplicitAs.impl.Convert]
// CHECK:STDOUT:   %bound_method.loc32_24.7: <bound method> = bound_method %.loc32_24.11, %impl.elem0.loc32_24.3
// CHECK:STDOUT:   %ErrA.as.ImplicitAs.impl.Convert.call: init %ErrB = call %bound_method.loc32_24.7(%.loc32_24.11)
// CHECK:STDOUT:   %.loc32_24.13: %ErrB = value_of_initializer %ErrA.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc32_24.14: %ErrB = converted %.loc32_24.11, %.loc32_24.13
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.4bc to %.loc31_42.1 = call %specific_fn.loc32_24.4(%.loc32_24.14)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_24.1: <bound method> = bound_method %.loc32_24.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.8
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_24.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_24.1(%.loc32_24.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_23.1: <bound method> = bound_method %.loc32_23.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.11
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_23.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_23.1(%.loc32_23.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_3.1: <bound method> = bound_method %v.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_3.1(%v.var)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc32_24.2:
// CHECK:STDOUT:   %.loc32_24.15: ref %.873 = class_element_access %.loc32_24.2, element1
// CHECK:STDOUT:   %.loc32_24.16: ref %tuple.type.a8a = class_element_access %.loc32_24.15, element0
// CHECK:STDOUT:   %tuple.elem0.loc32_24.2: ref %i32 = tuple_access %.loc32_24.16, element0
// CHECK:STDOUT:   %.loc32_24.17: %i32 = acquire_value %tuple.elem0.loc32_24.2
// CHECK:STDOUT:   %impl.elem0.loc32_24.4: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc32_24.8: <bound method> = bound_method %.loc32_24.17, %impl.elem0.loc32_24.4
// CHECK:STDOUT:   %specific_fn.loc32_24.5: <specific function> = specific_function %impl.elem0.loc32_24.4, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc32_24.9: <bound method> = bound_method %.loc32_24.17, %specific_fn.loc32_24.5
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc32_24.9(%.loc32_24.17)
// CHECK:STDOUT:   assign %v.var, %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   %i32.loc32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt.113]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.6b6 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ref.loc33: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc33: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %ErrB.ref.loc33: type = name_ref ErrB, file.%ErrB.decl [concrete = constants.%ErrB]
// CHECK:STDOUT:   %Result.loc33: type = class_type @Result, @Result(constants.%i32, constants.%ErrB) [concrete = constants.%Result.4bc]
// CHECK:STDOUT:   %.loc33_32: %Result.Ok.type.8f5 = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%ErrB) [concrete = constants.%Result.Ok.013]
// CHECK:STDOUT:   %Ok.ref: %Result.Ok.type.8f5 = name_ref Ok, %.loc33_32 [concrete = constants.%Result.Ok.013]
// CHECK:STDOUT:   %v.ref: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%i32, constants.%ErrB) [concrete = constants.%Result.Ok.specific_fn.9ac]
// CHECK:STDOUT:   %.loc31_42.2: ref %Result.4bc = splice_block %return.param {}
// CHECK:STDOUT:   %.loc33_36: %i32 = acquire_value %v.ref
// CHECK:STDOUT:   %Result.Ok.call: init %Result.4bc to %.loc31_42.2 = call %Result.Ok.specific_fn(%.loc33_36)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_24.2: <bound method> = bound_method %.loc32_24.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.8
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_24.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_24.2(%.loc32_24.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_23.2: <bound method> = bound_method %.loc32_23.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.11
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_23.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_23.2(%.loc32_23.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_3.2: <bound method> = bound_method %v.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_3.2(%v.var)
// CHECK:STDOUT:   return %Result.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_24.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_24.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_24.1(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_24.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_24.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_24.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_24.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_24.3(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_24.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_24.4(%self.param: ref %ErrA) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_24.4(%self.param: ref %ErrA) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_24.4(%self.param: ref %ErrA) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_24.5(%self.param: ref %tuple.type.bb7) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %ErrA = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_24.5(%self.param: ref %tuple.type.bb7) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_24.5(%self.param: ref %tuple.type.bb7) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_24.6(%self.param: ref %.873) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_24.6(%self.param: ref %.873) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_24.6(%self.param: ref %.873) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_24.7(%self.param: ref %struct_type.discriminant.payload.615) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc32_24.1: ref %.873 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_24.1: <bound method> = bound_method %.loc32_24.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_24.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_24.1(%.loc32_24.1)
// CHECK:STDOUT:   %.loc32_24.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_24.2: <bound method> = bound_method %.loc32_24.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_24.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_24.2(%.loc32_24.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_24.7(%self.param: ref %struct_type.discriminant.payload.615) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_24.7(%self.param: ref %struct_type.discriminant.payload.615) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.7(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.7(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_24.8(%self.param: ref %ControlFlow.46a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_24.8(%self.param: ref %ControlFlow.46a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_24.8(%self.param: ref %ControlFlow.46a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.8(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.8(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_23.1(%self.param: ref %.e62) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_23.1(%self.param: ref %.e62) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_23.1(%self.param: ref %.e62) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.9(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.9(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_23.2(%self.param: ref %struct_type.discriminant.payload.9f6) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc32_23.1: ref %.e62 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_23.1: <bound method> = bound_method %.loc32_23.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_23.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_23.1(%.loc32_23.1)
// CHECK:STDOUT:   %.loc32_23.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc32_23.2: <bound method> = bound_method %.loc32_23.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc32_23.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc32_23.2(%.loc32_23.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_23.2(%self.param: ref %struct_type.discriminant.payload.9f6) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_23.2(%self.param: ref %struct_type.discriminant.payload.9f6) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.10(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.10(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc32_23.3(%self.param: ref %Result.9ab) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc32_23.3(%self.param: ref %Result.9ab) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc32_23.3(%self.param: ref %Result.9ab) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.11(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.11(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- unit_ok.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %Result.610: type = class_type @Result, @Result(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %.0b9: Core.Form = init_form %Result.610 [concrete]
// CHECK:STDOUT:   %pattern_type.f2b: type = pattern_type %Result.610 [concrete]
// CHECK:STDOUT:   %return.param_patt.51d: %pattern_type.f2b = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.391: %pattern_type.f2b = return_slot_pattern %return.param_patt.51d, %Result.610 [concrete]
// CHECK:STDOUT:   %Check.type: type = fn_type @Check [concrete]
// CHECK:STDOUT:   %Check: %Check.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cb1: type = pattern_type %empty_tuple.type [concrete]
// CHECK:STDOUT:   %tuple.type.9fb: type = tuple_type (%empty_tuple.type) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e98: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.9fb, .Err@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.11d: type = struct_type {.discriminant: %u1, .payload: %.e98} [concrete]
// CHECK:STDOUT:   %Result.Ok.type.3fe: type = fn_type @Result.Ok, @Result(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Result.Ok.a6a: %Result.Ok.type.3fe = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %OrderedWith.type.ad8: type = generic_interface_type @OrderedWith [concrete]
// CHECK:STDOUT:   %OrderedWith.generic: %OrderedWith.type.ad8 = struct_value () [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.a6a, @Result.Ok(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Both.type: type = fn_type @Both [concrete]
// CHECK:STDOUT:   %Both: %Both.type = struct_value () [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.96d: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.180: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.7da: %Result.as.Try.impl.Branch.type.180 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.b3a: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.8ac: %Result.as.Try.impl.FromBreak.type.b3a = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.f81: %Try.type = facet_value %Result.610, (%Try.impl_witness.96d) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.d04: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.f81) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.5a7: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.f81) [concrete]
// CHECK:STDOUT:   %.0db: type = fn_type_with_self_type %Try.WithSelf.Branch.type.d04, %Try.facet.f81 [concrete]
// CHECK:STDOUT:   %ControlFlow.19f: type = class_type @ControlFlow, @ControlFlow(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.108: type = pattern_type %ControlFlow.19f [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.a5c: <specific function> = specific_function %Result.as.Try.impl.Branch.7da, @Result.as.Try.impl.Branch(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %.e4c: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.9fb, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.d20: type = struct_type {.discriminant: %u1, .payload: %.e4c} [concrete]
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
// CHECK:STDOUT:   %pattern_type.322: type = pattern_type %u1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
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
// CHECK:STDOUT:   %.a04: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.5a7, %Try.facet.f81 [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.8ac, @Result.as.Try.impl.FromBreak(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %self.param_patt.7c1: %pattern_type.322 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.945: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt.7c1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_11.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc13_11.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_11.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.65a: %pattern_type.cb1 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.df1: %pattern_type.cb1 = wrapper_binding_pattern self, %self.param_patt.65a [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_11.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc13_11.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_11.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.559: type = pattern_type %tuple.type.9fb [concrete]
// CHECK:STDOUT:   %self.param_patt.383: %pattern_type.559 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.363: %pattern_type.559 = wrapper_binding_pattern self, %self.param_patt.383 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_11.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc13_11.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_11.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc13_11.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_11.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_11.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc13_11.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e34: type = pattern_type %.e4c [concrete]
// CHECK:STDOUT:   %self.param_patt.d79: %pattern_type.e34 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e37: %pattern_type.e34 = wrapper_binding_pattern self, %self.param_patt.d79 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_11.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc13_11.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.6: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_11.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.6: %Destroy.WithSelf.SelfDestruct.type.fbceb5.6 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.a36: type = pattern_type %struct_type.discriminant.payload.d20 [concrete]
// CHECK:STDOUT:   %self.param_patt.1aa: %pattern_type.a36 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.c7f: %pattern_type.a36 = wrapper_binding_pattern self, %self.param_patt.1aa [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_11.7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.7: type = fn_type @Destroy.WithSelf.Op.loc13_11.7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.7: %Destroy.WithSelf.Op.type.ef016f.7 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.270: %pattern_type.108 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.cbf: %pattern_type.108 = wrapper_binding_pattern self, %self.param_patt.270 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_11.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.8: type = fn_type @Destroy.WithSelf.Op.loc13_11.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.8: %Destroy.WithSelf.Op.type.ef016f.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.8: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_11.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.8: %Destroy.WithSelf.SelfDestruct.type.fbceb5.8 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.d16: type = pattern_type %.e98 [concrete]
// CHECK:STDOUT:   %self.param_patt.736: %pattern_type.d16 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.ba3: %pattern_type.d16 = wrapper_binding_pattern self, %self.param_patt.736 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_10.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.9: type = fn_type @Destroy.WithSelf.Op.loc13_10.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.9: %Destroy.WithSelf.Op.type.ef016f.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.9: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_10.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.9: %Destroy.WithSelf.SelfDestruct.type.fbceb5.9 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e76: type = pattern_type %struct_type.discriminant.payload.11d [concrete]
// CHECK:STDOUT:   %self.param_patt.dd5: %pattern_type.e76 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.28b: %pattern_type.e76 = wrapper_binding_pattern self, %self.param_patt.dd5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_10.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.10: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.10: type = fn_type @Destroy.WithSelf.Op.loc13_10.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.10: %Destroy.WithSelf.Op.type.ef016f.10 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.9d4: %pattern_type.f2b = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.c75: %pattern_type.f2b = wrapper_binding_pattern self, %self.param_patt.9d4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_10.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.11: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.11: type = fn_type @Destroy.WithSelf.Op.loc13_10.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.11: %Destroy.WithSelf.Op.type.ef016f.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.11: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_10.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.11: %Destroy.WithSelf.SelfDestruct.type.fbceb5.11 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.1: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.1: %Int.as.AddWith.impl.Op.type.1eac76.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.2: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.2: %Int.as.AddWith.impl.Op.type.1eac76.2 = struct_value () [symbolic]
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
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Result = %Core.Result.0b3
// CHECK:STDOUT:     .OrderedWith = %Core.OrderedWith
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Result.0b3: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.OrderedWith: %OrderedWith.type.ad8 = import_ref Core//prelude/operators/comparison, OrderedWith, loaded [concrete = constants.%OrderedWith.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.b21 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.8a3), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_11.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc13_11.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_11.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cb1 = ref_param_pattern [concrete = constants.%self.param_patt.65a]
// CHECK:STDOUT:     %self.patt: %pattern_type.cb1 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.df1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %empty_tuple.type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %empty_tuple.type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc13_11.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cb1 = ref_param_pattern [concrete = constants.%self.param_patt.65a]
// CHECK:STDOUT:     %self.patt: %pattern_type.cb1 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.df1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %empty_tuple.type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %empty_tuple.type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_11.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.559 = ref_param_pattern [concrete = constants.%self.param_patt.383]
// CHECK:STDOUT:     %self.patt: %pattern_type.559 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.363]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.9fb = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.9fb = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc13_11.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.559 = ref_param_pattern [concrete = constants.%self.param_patt.383]
// CHECK:STDOUT:     %self.patt: %pattern_type.559 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.363]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.9fb = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.9fb = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_11.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc13_11.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_11.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc13_11.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_11.6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e34 = ref_param_pattern [concrete = constants.%self.param_patt.d79]
// CHECK:STDOUT:     %self.patt: %pattern_type.e34 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e37]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e4c = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e4c = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc13_11.6 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e34 = ref_param_pattern [concrete = constants.%self.param_patt.d79]
// CHECK:STDOUT:     %self.patt: %pattern_type.e34 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e37]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e4c = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e4c = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_11.7 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a36 = ref_param_pattern [concrete = constants.%self.param_patt.1aa]
// CHECK:STDOUT:     %self.patt: %pattern_type.a36 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c7f]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.d20 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.d20 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.7: %Destroy.WithSelf.Op.type.ef016f.7 = fn_decl @Destroy.WithSelf.Op.loc13_11.7 [concrete = constants.%Destroy.WithSelf.Op.403171.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a36 = ref_param_pattern [concrete = constants.%self.param_patt.1aa]
// CHECK:STDOUT:     %self.patt: %pattern_type.a36 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c7f]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.d20 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.d20 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_11.8 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.108 = ref_param_pattern [concrete = constants.%self.param_patt.270]
// CHECK:STDOUT:     %self.patt: %pattern_type.108 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.cbf]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ControlFlow.19f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ControlFlow.19f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.8: %Destroy.WithSelf.Op.type.ef016f.8 = fn_decl @Destroy.WithSelf.Op.loc13_11.8 [concrete = constants.%Destroy.WithSelf.Op.403171.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.108 = ref_param_pattern [concrete = constants.%self.param_patt.270]
// CHECK:STDOUT:     %self.patt: %pattern_type.108 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.cbf]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ControlFlow.19f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ControlFlow.19f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_10.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.d16 = ref_param_pattern [concrete = constants.%self.param_patt.736]
// CHECK:STDOUT:     %self.patt: %pattern_type.d16 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.ba3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e98 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e98 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.9: %Destroy.WithSelf.Op.type.ef016f.9 = fn_decl @Destroy.WithSelf.Op.loc13_10.1 [concrete = constants.%Destroy.WithSelf.Op.403171.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.d16 = ref_param_pattern [concrete = constants.%self.param_patt.736]
// CHECK:STDOUT:     %self.patt: %pattern_type.d16 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.ba3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e98 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e98 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.10: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_10.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.10] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e76 = ref_param_pattern [concrete = constants.%self.param_patt.dd5]
// CHECK:STDOUT:     %self.patt: %pattern_type.e76 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.28b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.11d = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.11d = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.10: %Destroy.WithSelf.Op.type.ef016f.10 = fn_decl @Destroy.WithSelf.Op.loc13_10.2 [concrete = constants.%Destroy.WithSelf.Op.403171.10] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e76 = ref_param_pattern [concrete = constants.%self.param_patt.dd5]
// CHECK:STDOUT:     %self.patt: %pattern_type.e76 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.28b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.11d = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.11d = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.11: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_10.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.11] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f2b = ref_param_pattern [concrete = constants.%self.param_patt.9d4]
// CHECK:STDOUT:     %self.patt: %pattern_type.f2b = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c75]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Result.610 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Result.610 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.11: %Destroy.WithSelf.Op.type.ef016f.11 = fn_decl @Destroy.WithSelf.Op.loc13_10.3 [concrete = constants.%Destroy.WithSelf.Op.403171.11] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f2b = ref_param_pattern [concrete = constants.%self.param_patt.9d4]
// CHECK:STDOUT:     %self.patt: %pattern_type.f2b = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c75]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Result.610 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Result.610 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Both.decl: %Both.type = fn_decl @Both [concrete = constants.%Both] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f2b = out_param_pattern [concrete = constants.%return.param_patt.51d]
// CHECK:STDOUT:     %return.patt: %pattern_type.f2b = return_slot_pattern %return.param_patt, %Result.loc12 [concrete = constants.%return.patt.391]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc12: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %.loc12_33: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %i32.loc12_36: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12_39.4: type = converted %.loc12_33, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:     %Result.loc12: type = class_type @Result, @Result(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.610]
// CHECK:STDOUT:     %.loc12_39.5: Core.Form = init_form %Result.loc12 [concrete = constants.%.0b9]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc12_12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %Result.610 = out_param call_param1
// CHECK:STDOUT:     %return: ref %Result.610 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Both(%n.param: %i32) -> out %return.param: %Result.610 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Check.ref.loc13: %Check.type = name_ref Check, file.%Check.decl [concrete = constants.%Check]
// CHECK:STDOUT:   %n.ref.loc13: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc13_10.1: ref %Result.610 = temporary_storage
// CHECK:STDOUT:   %Check.call.loc13: init %Result.610 to %.loc13_10.1 = call %Check.ref.loc13(%n.ref.loc13)
// CHECK:STDOUT:   %.loc13_10.2: ref %Result.610 = temporary %.loc13_10.1, %Check.call.loc13
// CHECK:STDOUT:   %impl.elem2.loc13: %.0db = impl_witness_access constants.%Try.impl_witness.96d, element2 [concrete = constants.%Result.as.Try.impl.Branch.7da]
// CHECK:STDOUT:   %bound_method.loc13_11.1: <bound method> = bound_method %.loc13_10.2, %impl.elem2.loc13
// CHECK:STDOUT:   %specific_fn.loc13_11.1: <specific function> = specific_function %impl.elem2.loc13, @Result.as.Try.impl.Branch(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.a5c]
// CHECK:STDOUT:   %bound_method.loc13_11.2: <bound method> = bound_method %.loc13_10.2, %specific_fn.loc13_11.1
// CHECK:STDOUT:   %.loc13_11.1: ref %ControlFlow.19f = temporary_storage
// CHECK:STDOUT:   %.loc13_10.3: %Result.610 = acquire_value %.loc13_10.2
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call.loc13: init %ControlFlow.19f to %.loc13_11.1 = call %bound_method.loc13_11.2(%.loc13_10.3)
// CHECK:STDOUT:   %.loc13_11.2: ref %ControlFlow.19f = temporary %.loc13_11.1, %Result.as.Try.impl.Branch.call.loc13
// CHECK:STDOUT:   %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_11.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_11.3: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_11.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc13_11.2: <specific function> = specific_function %impl.elem0.loc13_11.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_11.4: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_11.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13: init %u1 = call %bound_method.loc13_11.4(%int_1.loc13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_11.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_11.4: %u1 = converted %int_1.loc13, %.loc13_11.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_11.5: ref %u1 = class_element_access %.loc13_11.2, element0
// CHECK:STDOUT:   %impl.elem0.loc13_11.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_11.5: <bound method> = bound_method %.loc13_11.4, %impl.elem0.loc13_11.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc13_11.3: <specific function> = specific_function %impl.elem0.loc13_11.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_11.6: <bound method> = bound_method %.loc13_11.4, %specific_fn.loc13_11.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc13_11.6: %u1 = acquire_value %.loc13_11.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_11.6(%.loc13_11.4, %.loc13_11.6)
// CHECK:STDOUT:   %.loc13_11.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:   %.loc13_11.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc13, %.loc13_11.7
// CHECK:STDOUT:   if %.loc13_11.8 br !.loc13_11.1 else br !.loc13_11.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_11.1:
// CHECK:STDOUT:   %.loc13_11.9: ref %.e4c = class_element_access %.loc13_11.2, element1
// CHECK:STDOUT:   %.loc13_11.10: ref %tuple.type.a8a = class_element_access %.loc13_11.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc13_11.1: ref %i32 = tuple_access %.loc13_11.10, element0
// CHECK:STDOUT:   %.loc13_11.11: %i32 = acquire_value %tuple.elem0.loc13_11.1
// CHECK:STDOUT:   %Try.facet.loc13: %Try.type = facet_value constants.%Result.610, (constants.%Try.impl_witness.96d) [concrete = constants.%Try.facet.f81]
// CHECK:STDOUT:   %.loc13_11.12: %Try.type = converted constants.%Result.610, %Try.facet.loc13 [concrete = constants.%Try.facet.f81]
// CHECK:STDOUT:   %impl.elem3.loc13: %.a04 = impl_witness_access constants.%Try.impl_witness.96d, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.8ac]
// CHECK:STDOUT:   %specific_fn.loc13_11.4: <specific function> = specific_function %impl.elem3.loc13, @Result.as.Try.impl.FromBreak(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc12_39.1: ref %Result.610 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call.loc13: init %Result.610 to %.loc12_39.1 = call %specific_fn.loc13_11.4(%.loc13_11.11)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_11.1: <bound method> = bound_method %.loc13_11.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.8
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_11.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_11.1(%.loc13_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_10.1: <bound method> = bound_method %.loc13_10.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.11
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_10.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_10.1(%.loc13_10.2)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call.loc13 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_11.2:
// CHECK:STDOUT:   %.loc13_11.13: ref %.e4c = class_element_access %.loc13_11.2, element1
// CHECK:STDOUT:   %.loc13_11.14: ref %tuple.type.9fb = class_element_access %.loc13_11.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc13_11.2: ref %empty_tuple.type = tuple_access %.loc13_11.14, element0
// CHECK:STDOUT:   %empty_tuple.loc13: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc13_11.15: %empty_tuple.type = converted %tuple.elem0.loc13_11.2, %empty_tuple.loc13 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_11.2: <bound method> = bound_method %.loc13_11.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.8
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_11.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_11.2(%.loc13_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_10.2: <bound method> = bound_method %.loc13_10.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.11
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_10.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_10.2(%.loc13_10.2)
// CHECK:STDOUT:   %Check.ref.loc14: %Check.type = name_ref Check, file.%Check.decl [concrete = constants.%Check]
// CHECK:STDOUT:   %n.ref.loc14: %i32 = name_ref n, %n
// CHECK:STDOUT:   %int_1.loc14_13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:   %bound_method.loc14_11.1: <bound method> = bound_method %n.ref.loc14, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc14_11: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:   %bound_method.loc14_11.2: <bound method> = bound_method %n.ref.loc14, %specific_fn.loc14_11
// CHECK:STDOUT:   %.loc14_11.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc14_11.1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %n.ref.loc14, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:   %bound_method.loc14_11.3: <bound method> = bound_method %n.ref.loc14, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc14_13: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_13.1: <bound method> = bound_method %int_1.loc14_13, %impl.elem0.loc14_13 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc14_13: <specific function> = specific_function %impl.elem0.loc14_13, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_13.2: <bound method> = bound_method %int_1.loc14_13, %specific_fn.loc14_13 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_13: init %i32 = call %bound_method.loc14_13.2(%int_1.loc14_13) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14_13.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_13 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14_13.2: %i32 = converted %int_1.loc14_13, %.loc14_13.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc14_11.3(%n.ref.loc14, %.loc14_13.2)
// CHECK:STDOUT:   %.loc14_14.1: ref %Result.610 = temporary_storage
// CHECK:STDOUT:   %.loc14_11.2: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc14_11.3: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc14_11.2
// CHECK:STDOUT:   %Check.call.loc14: init %Result.610 to %.loc14_14.1 = call %Check.ref.loc14(%.loc14_11.3)
// CHECK:STDOUT:   %.loc14_14.2: ref %Result.610 = temporary %.loc14_14.1, %Check.call.loc14
// CHECK:STDOUT:   %impl.elem2.loc14: %.0db = impl_witness_access constants.%Try.impl_witness.96d, element2 [concrete = constants.%Result.as.Try.impl.Branch.7da]
// CHECK:STDOUT:   %bound_method.loc14_15.1: <bound method> = bound_method %.loc14_14.2, %impl.elem2.loc14
// CHECK:STDOUT:   %specific_fn.loc14_15.1: <specific function> = specific_function %impl.elem2.loc14, @Result.as.Try.impl.Branch(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.a5c]
// CHECK:STDOUT:   %bound_method.loc14_15.2: <bound method> = bound_method %.loc14_14.2, %specific_fn.loc14_15.1
// CHECK:STDOUT:   %.loc14_15.1: ref %ControlFlow.19f = temporary_storage
// CHECK:STDOUT:   %.loc14_14.3: %Result.610 = acquire_value %.loc14_14.2
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call.loc14: init %ControlFlow.19f to %.loc14_15.1 = call %bound_method.loc14_15.2(%.loc14_14.3)
// CHECK:STDOUT:   %.loc14_15.2: ref %ControlFlow.19f = temporary %.loc14_15.1, %Result.as.Try.impl.Branch.call.loc14
// CHECK:STDOUT:   %int_1.loc14_15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14_15.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_15.3: <bound method> = bound_method %int_1.loc14_15, %impl.elem0.loc14_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc14_15.2: <specific function> = specific_function %impl.elem0.loc14_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_15.4: <bound method> = bound_method %int_1.loc14_15, %specific_fn.loc14_15.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_15: init %u1 = call %bound_method.loc14_15.4(%int_1.loc14_15) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_15.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_15 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_15.4: %u1 = converted %int_1.loc14_15, %.loc14_15.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc14_15.5: ref %u1 = class_element_access %.loc14_15.2, element0
// CHECK:STDOUT:   %impl.elem0.loc14_15.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_15.5: <bound method> = bound_method %.loc14_15.4, %impl.elem0.loc14_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc14_15.3: <specific function> = specific_function %impl.elem0.loc14_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_15.6: <bound method> = bound_method %.loc14_15.4, %specific_fn.loc14_15.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc14_15.6: %u1 = acquire_value %.loc14_15.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_15.6(%.loc14_15.4, %.loc14_15.6)
// CHECK:STDOUT:   %.loc14_15.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_15.8: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_15.7
// CHECK:STDOUT:   if %.loc14_15.8 br !.loc14_15.1 else br !.loc14_15.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_15.1:
// CHECK:STDOUT:   %.loc14_15.9: ref %.e4c = class_element_access %.loc14_15.2, element1
// CHECK:STDOUT:   %.loc14_15.10: ref %tuple.type.a8a = class_element_access %.loc14_15.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc14_15.1: ref %i32 = tuple_access %.loc14_15.10, element0
// CHECK:STDOUT:   %.loc14_15.11: %i32 = acquire_value %tuple.elem0.loc14_15.1
// CHECK:STDOUT:   %Try.facet.loc14: %Try.type = facet_value constants.%Result.610, (constants.%Try.impl_witness.96d) [concrete = constants.%Try.facet.f81]
// CHECK:STDOUT:   %.loc14_15.12: %Try.type = converted constants.%Result.610, %Try.facet.loc14 [concrete = constants.%Try.facet.f81]
// CHECK:STDOUT:   %impl.elem3.loc14: %.a04 = impl_witness_access constants.%Try.impl_witness.96d, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.8ac]
// CHECK:STDOUT:   %specific_fn.loc14_15.4: <specific function> = specific_function %impl.elem3.loc14, @Result.as.Try.impl.FromBreak(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc12_39.2: ref %Result.610 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call.loc14: init %Result.610 to %.loc12_39.2 = call %specific_fn.loc14_15.4(%.loc14_15.11)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_15.1: <bound method> = bound_method %.loc14_15.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.8
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_15.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_15.1(%.loc14_15.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_14.1: <bound method> = bound_method %.loc14_14.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.11
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_14.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_14.1(%.loc14_14.2)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call.loc14 to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_15.2:
// CHECK:STDOUT:   %.loc14_15.13: ref %.e4c = class_element_access %.loc14_15.2, element1
// CHECK:STDOUT:   %.loc14_15.14: ref %tuple.type.9fb = class_element_access %.loc14_15.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc14_15.2: ref %empty_tuple.type = tuple_access %.loc14_15.14, element0
// CHECK:STDOUT:   %empty_tuple.loc14: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc14_15.15: %empty_tuple.type = converted %tuple.elem0.loc14_15.2, %empty_tuple.loc14 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_15.2: <bound method> = bound_method %.loc14_15.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.8
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_15.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_15.2(%.loc14_15.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_14.2: <bound method> = bound_method %.loc14_14.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.11
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_14.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_14.2(%.loc14_14.2)
// CHECK:STDOUT:   %Core.ref.loc15: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc15: %Result.type = name_ref Result, imports.%Core.Result.0b3 [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %.loc15_23: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %.loc15_29: type = converted %.loc15_23, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   %Result.loc15: type = class_type @Result, @Result(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.610]
// CHECK:STDOUT:   %.loc15_30: %Result.Ok.type.3fe = specific_constant imports.%Core.import_ref.597, @Result(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.Ok.a6a]
// CHECK:STDOUT:   %Ok.ref: %Result.Ok.type.3fe = name_ref Ok, %.loc15_30 [concrete = constants.%Result.Ok.a6a]
// CHECK:STDOUT:   %.loc15_35.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc12_39.3: ref %Result.610 = splice_block %return.param {}
// CHECK:STDOUT:   %empty_tuple.loc15: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc15_35.2: %empty_tuple.type = converted %.loc15_35.1, %empty_tuple.loc15 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Result.Ok.call: init %Result.610 to %.loc12_39.3 = call %Result.Ok.specific_fn(%.loc15_35.2)
// CHECK:STDOUT:   return %Result.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_11.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_11.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_11.1(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_11.2(%self.param: ref %empty_tuple.type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_11.2(%self.param: ref %empty_tuple.type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_11.2(%self.param: ref %empty_tuple.type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_11.3(%self.param: ref %tuple.type.9fb) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %empty_tuple.type = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_11.3(%self.param: ref %tuple.type.9fb) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_11.3(%self.param: ref %tuple.type.9fb) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_11.4(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_11.4(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_11.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_11.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_11.5(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_11.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_11.6(%self.param: ref %.e4c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_11.6(%self.param: ref %.e4c) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_11.6(%self.param: ref %.e4c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_11.7(%self.param: ref %struct_type.discriminant.payload.d20) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc13_11.1: ref %.e4c = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_11.1: <bound method> = bound_method %.loc13_11.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_11.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_11.1(%.loc13_11.1)
// CHECK:STDOUT:   %.loc13_11.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_11.2: <bound method> = bound_method %.loc13_11.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_11.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_11.2(%.loc13_11.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_11.7(%self.param: ref %struct_type.discriminant.payload.d20) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_11.7(%self.param: ref %struct_type.discriminant.payload.d20) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.7(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.7(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_11.8(%self.param: ref %ControlFlow.19f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_11.8(%self.param: ref %ControlFlow.19f) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_11.8(%self.param: ref %ControlFlow.19f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.8(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.8(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_10.1(%self.param: ref %.e98) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_10.1(%self.param: ref %.e98) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_10.1(%self.param: ref %.e98) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.9(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.9(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_10.2(%self.param: ref %struct_type.discriminant.payload.11d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc13_10.1: ref %.e98 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_10.1: <bound method> = bound_method %.loc13_10.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_10.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_10.1(%.loc13_10.1)
// CHECK:STDOUT:   %.loc13_10.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_10.2: <bound method> = bound_method %.loc13_10.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_10.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_10.2(%.loc13_10.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_10.2(%self.param: ref %struct_type.discriminant.payload.11d) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_10.2(%self.param: ref %struct_type.discriminant.payload.11d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.10(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.10(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_10.3(%self.param: ref %Result.610) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_10.3(%self.param: ref %Result.610) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_10.3(%self.param: ref %Result.610) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.11(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.11(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %E.patt: %pattern_type.9a5 = symbolic_binding_pattern E, 1 [symbolic]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.17989b.1: type = tuple_type (%E) [symbolic]
// CHECK:STDOUT:   %tuple.type.026b76.1: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Result: type = class_type @Result, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %pattern_type.b59: type = pattern_type %Result [symbolic]
// CHECK:STDOUT:   %return.param_patt.27f: %pattern_type.b59 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %Result.Ok.type: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok: %Result.Ok.type = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.441886.1: <witness> = require_complete_type %E [symbolic]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %.cf1: Core.Form = init_form %Result [symbolic]
// CHECK:STDOUT:   %require_complete.9c7: <witness> = require_complete_type %Result [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %r.param_patt: %pattern_type.b59 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %r.patt: %pattern_type.b59 = wrapper_binding_pattern r, %r.param_patt [symbolic]
// CHECK:STDOUT:   %return.patt.6cd: %pattern_type.b59 = return_slot_pattern %return.param_patt.27f, %Result [symbolic]
// CHECK:STDOUT:   %Passthrough.type: type = fn_type @Passthrough [concrete]
// CHECK:STDOUT:   %Passthrough: %Passthrough.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.51d1c4.1 = value_binding_pattern v [symbolic]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %Try.impl_witness: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak: %Result.as.Try.impl.FromBreak.type = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch: %Result.as.Try.impl.Branch.type = struct_value () [symbolic]
// CHECK:STDOUT:   %ControlFlow.eda317.2: type = class_type @ControlFlow, @ControlFlow(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %.bef625.2: type = custom_layout_type {size=0, align=0, .Continue@0: %tuple.type.026b76.1, .Break@0: %tuple.type.17989b.1} [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %Result.as.Try.impl.Branch, @Result.as.Try.impl.Branch(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value %Result, (%Try.impl_witness) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.851: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet) [symbolic]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.3ed: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet) [symbolic]
// CHECK:STDOUT:   %.7e5: type = fn_type_with_self_type %Try.WithSelf.Branch.type.851, %Try.facet [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
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
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.aae: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.3ed, %Try.facet [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak, @Result.as.Try.impl.FromBreak(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.c3f: <witness> = lookup_impl_witness %ControlFlow.eda317.2, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet: %Destroy.type = facet_value %ControlFlow.eda317.2, (%Destroy.lookup_impl_witness.c3f) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.7d7: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %.97f: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.7d7, %Destroy.facet [symbolic]
// CHECK:STDOUT:   %impl.elem2: %.97f = impl_witness_access %Destroy.lookup_impl_witness.c3f, element2 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.fdc: <specific function> = specific_impl_function %impl.elem2, @Destroy.WithSelf.SelfDestruct(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok, @Result.Ok(%T.67d, %E) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Result: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok)]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Passthrough.decl: %Passthrough.type = fn_decl @Passthrough [concrete = constants.%Passthrough] {
// CHECK:STDOUT:     %T.patt.loc8_17.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc8_17.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:     %E.patt.loc8_26.1: %pattern_type.9a5 = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc8_26.2 (constants.%E.patt)]
// CHECK:STDOUT:     %r.param_patt.loc8_35.1: @Passthrough.%pattern_type.loc8 (%pattern_type.b59) = value_param_pattern [symbolic = %r.param_patt.loc8_35.2 (constants.%r.param_patt)]
// CHECK:STDOUT:     %r.patt.loc8_35.1: @Passthrough.%pattern_type.loc8 (%pattern_type.b59) = wrapper_binding_pattern r, %r.param_patt.loc8_35.1 [symbolic = %r.patt.loc8_35.2 (constants.%r.patt)]
// CHECK:STDOUT:     %return.param_patt.loc8_75.1: @Passthrough.%pattern_type.loc8 (%pattern_type.b59) = out_param_pattern [symbolic = %return.param_patt.loc8_75.2 (constants.%return.param_patt.27f)]
// CHECK:STDOUT:     %return.patt.loc8_56.1: @Passthrough.%pattern_type.loc8 (%pattern_type.b59) = return_slot_pattern %return.param_patt.loc8_75.1, %Result.loc8_75 [symbolic = %return.patt.loc8_56.2 (constants.%return.patt.6cd)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc8_59: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc8_63: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %T.ref.loc8_71: type = name_ref T, %T.loc8_17.2 [symbolic = %T.loc8_17.1 (constants.%T.67d)]
// CHECK:STDOUT:     %E.ref.loc8_74: type = name_ref E, %E.loc8_26.2 [symbolic = %E.loc8_26.1 (constants.%E)]
// CHECK:STDOUT:     %Result.loc8_75: type = class_type @Result, @Result(constants.%T.67d, constants.%E) [symbolic = %Result.loc8_53.1 (constants.%Result)]
// CHECK:STDOUT:     %.loc8_75.4: Core.Form = init_form %Result.loc8_75 [symbolic = %.loc8_75.3 (constants.%.cf1)]
// CHECK:STDOUT:     %.loc8_19.1: type = splice_block %.loc8_19.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc8_17: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc8_19.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc8_17.2: type = symbolic_binding T, 0 [symbolic = %T.loc8_17.1 (constants.%T.67d)]
// CHECK:STDOUT:     %.loc8_28.1: type = splice_block %.loc8_28.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc8_26: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc8_28.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %E.loc8_26.2: type = symbolic_binding E, 1 [symbolic = %E.loc8_26.1 (constants.%E)]
// CHECK:STDOUT:     %r.param: @Passthrough.%Result.loc8_53.1 (%Result) = value_param call_param0
// CHECK:STDOUT:     %.loc8_53: type = splice_block %Result.loc8_53.2 [symbolic = %Result.loc8_53.1 (constants.%Result)] {
// CHECK:STDOUT:       %Core.ref.loc8_37: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Result.ref.loc8_41: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:       %T.ref.loc8_49: type = name_ref T, %T.loc8_17.2 [symbolic = %T.loc8_17.1 (constants.%T.67d)]
// CHECK:STDOUT:       %E.ref.loc8_52: type = name_ref E, %E.loc8_26.2 [symbolic = %E.loc8_26.1 (constants.%E)]
// CHECK:STDOUT:       %Result.loc8_53.2: type = class_type @Result, @Result(constants.%T.67d, constants.%E) [symbolic = %Result.loc8_53.1 (constants.%Result)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %r: @Passthrough.%Result.loc8_53.1 (%Result) = wrapper_binding r, %r.param
// CHECK:STDOUT:     %return.param: ref @Passthrough.%Result.loc8_53.1 (%Result) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Passthrough.%Result.loc8_53.1 (%Result) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Passthrough(%T.loc8_17.2: type, %E.loc8_26.2: type) {
// CHECK:STDOUT:   %T.patt.loc8_17.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc8_17.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:   %T.loc8_17.1: type = symbolic_binding T, 0 [symbolic = %T.loc8_17.1 (constants.%T.67d)]
// CHECK:STDOUT:   %E.patt.loc8_26.2: %pattern_type.9a5 = symbolic_binding_pattern E, 1 [symbolic = %E.patt.loc8_26.2 (constants.%E.patt)]
// CHECK:STDOUT:   %E.loc8_26.1: type = symbolic_binding E, 1 [symbolic = %E.loc8_26.1 (constants.%E)]
// CHECK:STDOUT:   %Result.loc8_53.1: type = class_type @Result, @Result(%T.loc8_17.1, %E.loc8_26.1) [symbolic = %Result.loc8_53.1 (constants.%Result)]
// CHECK:STDOUT:   %pattern_type.loc8: type = pattern_type %Result.loc8_53.1 [symbolic = %pattern_type.loc8 (constants.%pattern_type.b59)]
// CHECK:STDOUT:   %r.param_patt.loc8_35.2: @Passthrough.%pattern_type.loc8 (%pattern_type.b59) = value_param_pattern [symbolic = %r.param_patt.loc8_35.2 (constants.%r.param_patt)]
// CHECK:STDOUT:   %r.patt.loc8_35.2: @Passthrough.%pattern_type.loc8 (%pattern_type.b59) = wrapper_binding_pattern r, %r.param_patt.loc8_35.2 [symbolic = %r.patt.loc8_35.2 (constants.%r.patt)]
// CHECK:STDOUT:   %.loc8_75.3: Core.Form = init_form %Result.loc8_53.1 [symbolic = %.loc8_75.3 (constants.%.cf1)]
// CHECK:STDOUT:   %return.param_patt.loc8_75.2: @Passthrough.%pattern_type.loc8 (%pattern_type.b59) = out_param_pattern [symbolic = %return.param_patt.loc8_75.2 (constants.%return.param_patt.27f)]
// CHECK:STDOUT:   %return.patt.loc8_56.2: @Passthrough.%pattern_type.loc8 (%pattern_type.b59) = return_slot_pattern %return.param_patt.loc8_75.2, %Result.loc8_53.1 [symbolic = %return.patt.loc8_56.2 (constants.%return.patt.6cd)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8: <witness> = require_complete_type %Result.loc8_53.1 [symbolic = %require_complete.loc8 (constants.%require_complete.9c7)]
// CHECK:STDOUT:   %require_complete.loc9_10: <witness> = require_complete_type %T.loc8_17.1 [symbolic = %require_complete.loc9_10 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %pattern_type.loc9: type = pattern_type %T.loc8_17.1 [symbolic = %pattern_type.loc9 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %v.patt.loc9_8.2: @Passthrough.%pattern_type.loc9 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc9_8.2 (constants.%v.patt)]
// CHECK:STDOUT:   %Try.impl_witness: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%T.loc8_17.1, %E.loc8_26.1) [symbolic = %Try.impl_witness (constants.%Try.impl_witness)]
// CHECK:STDOUT:   %Try.facet.loc9_15.2: %Try.type = facet_value %Result.loc8_53.1, (%Try.impl_witness) [symbolic = %Try.facet.loc9_15.2 (constants.%Try.facet)]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.loc9_15.2) [symbolic = %Try.WithSelf.Branch.type (constants.%Try.WithSelf.Branch.type.851)]
// CHECK:STDOUT:   %.loc9_15.20: type = fn_type_with_self_type %Try.WithSelf.Branch.type, %Try.facet.loc9_15.2 [symbolic = %.loc9_15.20 (constants.%.7e5)]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.loc8_17.1, %E.loc8_26.1) [symbolic = %Result.as.Try.impl.Branch.type (constants.%Result.as.Try.impl.Branch.type)]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch: @Passthrough.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type) = struct_value () [symbolic = %Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch)]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %Result.as.Try.impl.Branch, @Result.as.Try.impl.Branch(%T.loc8_17.1, %E.loc8_26.1) [symbolic = %Result.as.Try.impl.Branch.specific_fn (constants.%Result.as.Try.impl.Branch.specific_fn)]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %tuple.type.loc9_15.1: type = tuple_type (%T.loc8_17.1) [symbolic = %tuple.type.loc9_15.1 (constants.%tuple.type.026b76.1)]
// CHECK:STDOUT:   %tuple.type.loc9_15.2: type = tuple_type (%E.loc8_26.1) [symbolic = %tuple.type.loc9_15.2 (constants.%tuple.type.17989b.1)]
// CHECK:STDOUT:   %.loc9_15.21: type = custom_layout_type {size=0, align=0, .Continue@0: @Passthrough.%tuple.type.loc9_15.1 (%tuple.type.026b76.1), .Break@0: @Passthrough.%tuple.type.loc9_15.2 (%tuple.type.17989b.1)} [symbolic = %.loc9_15.21 (constants.%.bef625.2)]
// CHECK:STDOUT:   %require_complete.loc9_15: <witness> = require_complete_type %E.loc8_26.1 [symbolic = %require_complete.loc9_15 (constants.%require_complete.441886.1)]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.loc9_15.2) [symbolic = %Try.WithSelf.FromBreak.type (constants.%Try.WithSelf.FromBreak.type.3ed)]
// CHECK:STDOUT:   %.loc9_15.22: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type, %Try.facet.loc9_15.2 [symbolic = %.loc9_15.22 (constants.%.aae)]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.loc8_17.1, %E.loc8_26.1) [symbolic = %Result.as.Try.impl.FromBreak.type (constants.%Result.as.Try.impl.FromBreak.type)]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak: @Passthrough.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type) = struct_value () [symbolic = %Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak)]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak, @Result.as.Try.impl.FromBreak(%T.loc8_17.1, %E.loc8_26.1) [symbolic = %Result.as.Try.impl.FromBreak.specific_fn (constants.%Result.as.Try.impl.FromBreak.specific_fn)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %ControlFlow, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.c3f)]
// CHECK:STDOUT:   %Destroy.facet.loc9_15.5: %Destroy.type = facet_value %ControlFlow, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc9_15.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet.loc9_15.5) [symbolic = %Destroy.WithSelf.SelfDestruct.type (constants.%Destroy.WithSelf.SelfDestruct.type.7d7)]
// CHECK:STDOUT:   %.loc9_15.23: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type, %Destroy.facet.loc9_15.5 [symbolic = %.loc9_15.23 (constants.%.97f)]
// CHECK:STDOUT:   %impl.elem2.loc9_15.4: @Passthrough.%.loc9_15.23 (%.97f) = impl_witness_access %Destroy.lookup_impl_witness, element2 [symbolic = %impl.elem2.loc9_15.4 (constants.%impl.elem2)]
// CHECK:STDOUT:   %specific_impl_fn.loc9_15.3: <specific function> = specific_impl_function %impl.elem2.loc9_15.4, @Destroy.WithSelf.SelfDestruct(%Destroy.facet.loc9_15.5) [symbolic = %specific_impl_fn.loc9_15.3 (constants.%specific_impl_fn.fdc)]
// CHECK:STDOUT:   %Result.Ok.type: type = fn_type @Result.Ok, @Result(%T.loc8_17.1, %E.loc8_26.1) [symbolic = %Result.Ok.type (constants.%Result.Ok.type)]
// CHECK:STDOUT:   %Result.Ok: @Passthrough.%Result.Ok.type (%Result.Ok.type) = struct_value () [symbolic = %Result.Ok (constants.%Result.Ok)]
// CHECK:STDOUT:   %Result.Ok.specific_fn.loc10_27.2: <specific function> = specific_function %Result.Ok, @Result.Ok(%T.loc8_17.1, %E.loc8_26.1) [symbolic = %Result.Ok.specific_fn.loc10_27.2 (constants.%Result.Ok.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%r.param: @Passthrough.%Result.loc8_53.1 (%Result)) -> out %return.param: @Passthrough.%Result.loc8_53.1 (%Result) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %r.ref: @Passthrough.%Result.loc8_53.1 (%Result) = name_ref r, %r
// CHECK:STDOUT:     %impl.elem2.loc9_15.1: @Passthrough.%.loc9_15.20 (%.7e5) = impl_witness_access constants.%Try.impl_witness, element2 [symbolic = %Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch)]
// CHECK:STDOUT:     %bound_method.loc9_15.1: <bound method> = bound_method %r.ref, %impl.elem2.loc9_15.1
// CHECK:STDOUT:     %specific_fn.loc9_15.1: <specific function> = specific_function %impl.elem2.loc9_15.1, @Result.as.Try.impl.Branch(constants.%T.67d, constants.%E) [symbolic = %Result.as.Try.impl.Branch.specific_fn (constants.%Result.as.Try.impl.Branch.specific_fn)]
// CHECK:STDOUT:     %bound_method.loc9_15.2: <bound method> = bound_method %r.ref, %specific_fn.loc9_15.1
// CHECK:STDOUT:     %.loc9_15.1: ref @Passthrough.%ControlFlow (%ControlFlow.eda317.2) = temporary_storage
// CHECK:STDOUT:     %Result.as.Try.impl.Branch.call: init @Passthrough.%ControlFlow (%ControlFlow.eda317.2) to %.loc9_15.1 = call %bound_method.loc9_15.2(%r.ref)
// CHECK:STDOUT:     %.loc9_15.2: ref @Passthrough.%ControlFlow (%ControlFlow.eda317.2) = temporary %.loc9_15.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %impl.elem0.loc9_15.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:     %bound_method.loc9_15.3: <bound method> = bound_method %int_1, %impl.elem0.loc9_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:     %specific_fn.loc9_15.2: <specific function> = specific_function %impl.elem0.loc9_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc9_15.4: <bound method> = bound_method %int_1, %specific_fn.loc9_15.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc9_15.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc9_15.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc9_15.4: %u1 = converted %int_1, %.loc9_15.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:     %.loc9_15.5: ref %u1 = class_element_access %.loc9_15.2, element0
// CHECK:STDOUT:     %impl.elem0.loc9_15.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:     %bound_method.loc9_15.5: <bound method> = bound_method %.loc9_15.4, %impl.elem0.loc9_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:     %specific_fn.loc9_15.3: <specific function> = specific_function %impl.elem0.loc9_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:     %bound_method.loc9_15.6: <bound method> = bound_method %.loc9_15.4, %specific_fn.loc9_15.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:     %.loc9_15.6: %u1 = acquire_value %.loc9_15.5
// CHECK:STDOUT:     %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc9_15.6(%.loc9_15.4, %.loc9_15.6)
// CHECK:STDOUT:     %.loc9_15.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:     %.loc9_15.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc9_15.7
// CHECK:STDOUT:     if %.loc9_15.8 br !.loc9_15.1 else br !.loc9_15.2
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc9_15.1:
// CHECK:STDOUT:     %.loc9_15.9: ref @Passthrough.%.loc9_15.21 (%.bef625.2) = class_element_access %.loc9_15.2, element1
// CHECK:STDOUT:     %.loc9_15.10: ref @Passthrough.%tuple.type.loc9_15.2 (%tuple.type.17989b.1) = class_element_access %.loc9_15.9, element1
// CHECK:STDOUT:     %tuple.elem0.loc9_15.1: ref @Passthrough.%E.loc8_26.1 (%E) = tuple_access %.loc9_15.10, element0
// CHECK:STDOUT:     %.loc9_15.11: @Passthrough.%E.loc8_26.1 (%E) = acquire_value %tuple.elem0.loc9_15.1
// CHECK:STDOUT:     %Try.facet.loc9_15.1: %Try.type = facet_value constants.%Result, (constants.%Try.impl_witness) [symbolic = %Try.facet.loc9_15.2 (constants.%Try.facet)]
// CHECK:STDOUT:     %.loc9_15.12: %Try.type = converted constants.%Result, %Try.facet.loc9_15.1 [symbolic = %Try.facet.loc9_15.2 (constants.%Try.facet)]
// CHECK:STDOUT:     %impl.elem3: @Passthrough.%.loc9_15.22 (%.aae) = impl_witness_access constants.%Try.impl_witness, element3 [symbolic = %Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak)]
// CHECK:STDOUT:     %specific_fn.loc9_15.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%T.67d, constants.%E) [symbolic = %Result.as.Try.impl.FromBreak.specific_fn (constants.%Result.as.Try.impl.FromBreak.specific_fn)]
// CHECK:STDOUT:     %.loc8_75.1: ref @Passthrough.%Result.loc8_53.1 (%Result) = splice_block %return.param {}
// CHECK:STDOUT:     %Result.as.Try.impl.FromBreak.call: init @Passthrough.%Result.loc8_53.1 (%Result) to %.loc8_75.1 = call %specific_fn.loc9_15.4(%.loc9_15.11)
// CHECK:STDOUT:     %impl.elem2.loc9_15.2: @Passthrough.%.loc9_15.23 (%.97f) = impl_witness_access constants.%Destroy.lookup_impl_witness.c3f, element2 [symbolic = %impl.elem2.loc9_15.4 (constants.%impl.elem2)]
// CHECK:STDOUT:     %bound_method.loc9_15.7: <bound method> = bound_method %.loc9_15.2, %impl.elem2.loc9_15.2
// CHECK:STDOUT:     %Destroy.facet.loc9_15.1: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness.c3f) [symbolic = %Destroy.facet.loc9_15.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc9_15.13: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc9_15.1 [symbolic = %Destroy.facet.loc9_15.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc9_15.2: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness.c3f) [symbolic = %Destroy.facet.loc9_15.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc9_15.14: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc9_15.2 [symbolic = %Destroy.facet.loc9_15.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc9_15.1: <specific function> = specific_impl_function %impl.elem2.loc9_15.2, @Destroy.WithSelf.SelfDestruct(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc9_15.3 (constants.%specific_impl_fn.fdc)]
// CHECK:STDOUT:     %bound_method.loc9_15.8: <bound method> = bound_method %.loc9_15.2, %specific_impl_fn.loc9_15.1
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call.loc9_15.1: init %empty_tuple.type = call %bound_method.loc9_15.8(%.loc9_15.2)
// CHECK:STDOUT:     return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT:   !.loc9_15.2:
// CHECK:STDOUT:     %.loc9_15.15: ref @Passthrough.%.loc9_15.21 (%.bef625.2) = class_element_access %.loc9_15.2, element1
// CHECK:STDOUT:     %.loc9_15.16: ref @Passthrough.%tuple.type.loc9_15.1 (%tuple.type.026b76.1) = class_element_access %.loc9_15.15, element0
// CHECK:STDOUT:     %tuple.elem0.loc9_15.2: ref @Passthrough.%T.loc8_17.1 (%T.67d) = tuple_access %.loc9_15.16, element0
// CHECK:STDOUT:     %.loc9_15.17: @Passthrough.%T.loc8_17.1 (%T.67d) = acquire_value %tuple.elem0.loc9_15.2
// CHECK:STDOUT:     %T.ref.loc9: type = name_ref T, %T.loc8_17.2 [symbolic = %T.loc8_17.1 (constants.%T.67d)]
// CHECK:STDOUT:     %v: @Passthrough.%T.loc8_17.1 (%T.67d) = wrapper_binding v, %.loc9_15.17
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %v.patt.loc9_8.1: @Passthrough.%pattern_type.loc9 (%pattern_type.51d1c4.1) = value_binding_pattern v [symbolic = %v.patt.loc9_8.2 (constants.%v.patt)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Core.ref.loc10: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc10: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %T.ref.loc10: type = name_ref T, %T.loc8_17.2 [symbolic = %T.loc8_17.1 (constants.%T.67d)]
// CHECK:STDOUT:     %E.ref.loc10: type = name_ref E, %E.loc8_26.2 [symbolic = %E.loc8_26.1 (constants.%E)]
// CHECK:STDOUT:     %Result.loc10: type = class_type @Result, @Result(constants.%T.67d, constants.%E) [symbolic = %Result.loc8_53.1 (constants.%Result)]
// CHECK:STDOUT:     %.loc10: @Passthrough.%Result.Ok.type (%Result.Ok.type) = specific_constant imports.%Core.import_ref.597, @Result(constants.%T.67d, constants.%E) [symbolic = %Result.Ok (constants.%Result.Ok)]
// CHECK:STDOUT:     %Ok.ref: @Passthrough.%Result.Ok.type (%Result.Ok.type) = name_ref Ok, %.loc10 [symbolic = %Result.Ok (constants.%Result.Ok)]
// CHECK:STDOUT:     %v.ref: @Passthrough.%T.loc8_17.1 (%T.67d) = name_ref v, %v
// CHECK:STDOUT:     %Result.Ok.specific_fn.loc10_27.1: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%T.67d, constants.%E) [symbolic = %Result.Ok.specific_fn.loc10_27.2 (constants.%Result.Ok.specific_fn)]
// CHECK:STDOUT:     %.loc8_75.2: ref @Passthrough.%Result.loc8_53.1 (%Result) = splice_block %return.param {}
// CHECK:STDOUT:     %Result.Ok.call: init @Passthrough.%Result.loc8_53.1 (%Result) to %.loc8_75.2 = call %Result.Ok.specific_fn.loc10_27.1(%v.ref)
// CHECK:STDOUT:     %impl.elem2.loc9_15.3: @Passthrough.%.loc9_15.23 (%.97f) = impl_witness_access constants.%Destroy.lookup_impl_witness.c3f, element2 [symbolic = %impl.elem2.loc9_15.4 (constants.%impl.elem2)]
// CHECK:STDOUT:     %bound_method.loc9_15.9: <bound method> = bound_method %.loc9_15.2, %impl.elem2.loc9_15.3
// CHECK:STDOUT:     %Destroy.facet.loc9_15.3: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness.c3f) [symbolic = %Destroy.facet.loc9_15.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc9_15.18: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc9_15.3 [symbolic = %Destroy.facet.loc9_15.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc9_15.4: %Destroy.type = facet_value constants.%ControlFlow.eda317.2, (constants.%Destroy.lookup_impl_witness.c3f) [symbolic = %Destroy.facet.loc9_15.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc9_15.19: %Destroy.type = converted constants.%ControlFlow.eda317.2, %Destroy.facet.loc9_15.4 [symbolic = %Destroy.facet.loc9_15.5 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc9_15.2: <specific function> = specific_impl_function %impl.elem2.loc9_15.3, @Destroy.WithSelf.SelfDestruct(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc9_15.3 (constants.%specific_impl_fn.fdc)]
// CHECK:STDOUT:     %bound_method.loc9_15.10: <bound method> = bound_method %.loc9_15.2, %specific_impl_fn.loc9_15.2
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call.loc9_15.2: init %empty_tuple.type = call %bound_method.loc9_15.10(%.loc9_15.2)
// CHECK:STDOUT:     return %Result.Ok.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Passthrough(constants.%T.67d, constants.%E) {
// CHECK:STDOUT:   %T.patt.loc8_17.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc8_17.1 => constants.%T.67d
// CHECK:STDOUT:   %E.patt.loc8_26.2 => constants.%E.patt
// CHECK:STDOUT:   %E.loc8_26.1 => constants.%E
// CHECK:STDOUT:   %Result.loc8_53.1 => constants.%Result
// CHECK:STDOUT:   %pattern_type.loc8 => constants.%pattern_type.b59
// CHECK:STDOUT:   %r.param_patt.loc8_35.2 => constants.%r.param_patt
// CHECK:STDOUT:   %r.patt.loc8_35.2 => constants.%r.patt
// CHECK:STDOUT:   %.loc8_75.3 => constants.%.cf1
// CHECK:STDOUT:   %return.param_patt.loc8_75.2 => constants.%return.param_patt.27f
// CHECK:STDOUT:   %return.patt.loc8_56.2 => constants.%return.patt.6cd
// CHECK:STDOUT: }
// CHECK:STDOUT:
