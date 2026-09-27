// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/question_optional.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/question_optional.carbon
// CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:71:42: error: cannot access member of interface `Destroy` in type `T` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:       return ControlFlow(T, ()).Continue(self.Get());
// CHECK:STDERR:                                          ^~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:71:42: error: cannot access member of interface `Destroy` in type `T` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:       return ControlFlow(T, ()).Continue(self.Get());
// CHECK:STDERR:                                          ^~~~~~~~~~
// CHECK:STDERR:

// Postfix `?` over `Core.Optional(T)` (fork/eh/plan.md §4.A; decision D9 of
// docs/design/error_handling.md): the prelude's `final impl forall [T:
// OptionalStorage] Optional(T) as Try where .ContinueType = T and .BreakType
// = ()` in core/prelude/types/optional.carbon, over the placeholder
// `HasValue()`/`Get()` API (D-EH-1). The carrier is `Core.ControlFlow(T,
// ())`, whose `()` payload is admitted by D-EH-2. The two `fail_*_in_*`
// subfiles pin D9's "no implicit bridge": absence does not become an error
// value and an error does not become absence — each direction is the
// ordinary `()`/`E` conversion failure at the prelude `FromBreak` call.
// `fail_class_element` pins the SF-6 bound on the carrier specific:
// `Optional(i32)` and `Optional(T*)` are the 0.1 `?` surface.

// --- some_none.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(o: Core.Optional(i32)) -> Core.Optional(i32) {
  return Core.Optional(i32).Some(o? + 1);
}
//@dump-sem-ir-end

// --- pointer_niche.carbon
library "[[@TEST_NAME]]";

// The pointer storage (null is `None`): `p?` is the held `i32*`.
//@dump-sem-ir-begin
fn Deref(p: Core.Optional(i32*)) -> Core.Optional(i32) {
  return Core.Optional(i32).Some(*(p?));
}
//@dump-sem-ir-end

// --- fail_optional_in_result.carbon
library "[[@TEST_NAME]]";

// D9: `Optional?` inside a `Result`-returning function is a `()`-to-`E`
// conversion failure at `Core.Result(i32, i32).(Core.Try.FromBreak)`.
fn Bridge(o: Core.Optional(i32)) -> Core.Result(i32, i32) {
  // CHECK:STDERR: fail_optional_in_result.carbon:[[@LINE+10]]:35: error: cannot implicitly convert expression of type `()` to `i32` [ConversionFailure]
  // CHECK:STDERR:   return Core.Result(i32, i32).Ok(o?);
  // CHECK:STDERR:                                   ^~
  // CHECK:STDERR: fail_optional_in_result.carbon:[[@LINE+7]]:35: note: type `()` does not implement interface `Core.ImplicitAs(i32)` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return Core.Result(i32, i32).Ok(o?);
  // CHECK:STDERR:                                   ^~
  // CHECK:STDERR: {{.*}}/prelude/types/result.carbon:51:16: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR:   fn FromBreak(b: E) -> Self { return Result(T, E).Err(b); }
  // CHECK:STDERR:                ^~~~
  // CHECK:STDERR:
  return Core.Result(i32, i32).Ok(o?);
}

// --- fail_result_in_optional.carbon
library "[[@TEST_NAME]]";

// D9, the converse: `Result?` inside an `Optional`-returning function is an
// `E`-to-`()` conversion failure at `Core.Optional(i32).(Core.Try.FromBreak)`.
fn Swallow(r: Core.Result(i32, i32)) -> Core.Optional(i32) {
  // CHECK:STDERR: fail_result_in_optional.carbon:[[@LINE+10]]:34: error: cannot implicitly convert expression of type `i32` to `()` [ConversionFailure]
  // CHECK:STDERR:   return Core.Optional(i32).Some(r?);
  // CHECK:STDERR:                                  ^~
  // CHECK:STDERR: fail_result_in_optional.carbon:[[@LINE+7]]:34: note: type `i32` does not implement interface `Core.ImplicitAs(())` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return Core.Optional(i32).Some(r?);
  // CHECK:STDERR:                                  ^~
  // CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:75:23: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR:   fn FromBreak(unused b: ()) -> Self { return Optional(T).None(); }
  // CHECK:STDERR:                       ^~~~~
  // CHECK:STDERR:
  return Core.Optional(i32).Some(r?);
}

// --- fail_class_element.carbon
library "[[@TEST_NAME]]";

// `Core.Optional(str)` is a fine type (`str` is `Copy & Destroy`), but its
// `Branch` forms the `Core.ControlFlow(str, ())` specific, whose `str`
// payload fails SF-6 (toolchain/check/type.cpp `IsInSliceChoicePayloadType`).
fn Element(s: Core.Optional(str)) -> Core.Optional(str) {
  // CHECK:STDERR: fail_class_element.carbon:[[@LINE+24]]:34: error: function returns incomplete type `Core.ControlFlow(str, ())` [IncompleteTypeInFunctionReturnType]
  // CHECK:STDERR:   return Core.Optional(str).Some(s?);
  // CHECK:STDERR:                                  ^~
  // CHECK:STDERR: {{.*}}/prelude/try.carbon:21:1: note: choice alternative payload type `str` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR: choice ControlFlow(C: type, B: type) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:69:19: note: return type declared here [IncompleteReturnTypeHere]
  // CHECK:STDERR:   fn Branch(self) -> ControlFlow(T, ()) {
  // CHECK:STDERR:                   ^~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:71:14: error: unable to monomorphize specific `Core.Continue(())` [ResolvingSpecificHere]
  // CHECK:STDERR:       return ControlFlow(T, ()).Continue(self.Get());
  // CHECK:STDERR:              ^~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: {{.*}}/prelude/try.carbon:21:1: note: choice alternative payload type `str` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR: choice ControlFlow(C: type, B: type) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:73:12: error: unable to monomorphize specific `Core.Break(())` [ResolvingSpecificHere]
  // CHECK:STDERR:     return ControlFlow(T, ()).Break(());
  // CHECK:STDERR:            ^~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: {{.*}}/prelude/try.carbon:21:1: note: choice alternative payload type `str` is not trivially copyable and destructible in this specific [ChoicePayloadNotTrivialInSpecific]
  // CHECK:STDERR: choice ControlFlow(C: type, B: type) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Core.Optional(str).Some(s?);
}

// CHECK:STDOUT: --- some_none.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.Some.type.304: type = fn_type @Optional.Some, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.Some.2a0: %Optional.Some.type.304 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type.f48 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %DefaultOptionalStorage.d50: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.type.a12: type = fn_type @T.as_type.as.OptionalStorage.impl.Get, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.d32: %T.as_type.as.OptionalStorage.impl.Get.type.a12 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.type.e5a: type = fn_type @T.as_type.as.OptionalStorage.impl.Has, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.4ee: %T.as_type.as.OptionalStorage.impl.Has.type.e5a = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Some.type.492: type = fn_type @T.as_type.as.OptionalStorage.impl.Some, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Some.89a: %T.as_type.as.OptionalStorage.impl.Some.type.492 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.None.type.0a1: type = fn_type @T.as_type.as.OptionalStorage.impl.None, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.None.e06: %T.as_type.as.OptionalStorage.impl.None.type.0a1 = struct_value () [symbolic]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc4_26.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.f48 = facet_value %i32, (%custom_witness.df9cc1.2, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.c8c: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.460, @T.as_type.as.OptionalStorage.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet: %OptionalStorage.type = facet_value %i32, (%OptionalStorage.impl_witness.c8c) [concrete]
// CHECK:STDOUT:   %Optional.755: type = class_type @Optional, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %pattern_type.591: type = pattern_type %Optional.755 [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.591 = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.591 = wrapper_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %.d22: Core.Form = init_form %Optional.755 [concrete]
// CHECK:STDOUT:   %return.param_patt.849: %pattern_type.591 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.893: %pattern_type.591 = return_slot_pattern %return.param_patt.849, %Optional.755 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.Some.type.0b0: type = fn_type @Optional.Some, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.Some.4b6: %Optional.Some.type.0b0 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.type.ff4: type = fn_type @Optional.as.Try.impl.FromBreak, @Optional.as.Try.impl(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.13f: %Optional.as.Try.impl.FromBreak.type.ff4 = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.type.b35: type = fn_type @Optional.as.Try.impl.Branch, @Optional.as.Try.impl(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.c49: %Optional.as.Try.impl.Branch.type.b35 = struct_value () [symbolic]
// CHECK:STDOUT:   %tuple.type.9fb: type = tuple_type (%empty_tuple.type) [concrete]
// CHECK:STDOUT:   %Try.impl_witness.0d4: <witness> = impl_witness imports.%Try.impl_witness_table, @Optional.as.Try.impl(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.type.037: type = fn_type @Optional.as.Try.impl.Branch, @Optional.as.Try.impl(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.e19: %Optional.as.Try.impl.Branch.type.037 = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.type.418: type = fn_type @Optional.as.Try.impl.FromBreak, @Optional.as.Try.impl(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.a73: %Optional.as.Try.impl.FromBreak.type.418 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value %Optional.755, (%Try.impl_witness.0d4) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.7fa: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.0e0: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet) [concrete]
// CHECK:STDOUT:   %.7bc: type = fn_type_with_self_type %Try.WithSelf.Branch.type.7fa, %Try.facet [concrete]
// CHECK:STDOUT:   %ControlFlow.59f: type = class_type @ControlFlow, @ControlFlow(%i32, %empty_tuple.type) [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %Optional.as.Try.impl.Branch.e19, @Optional.as.Try.impl.Branch(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.96b: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.a8a, .Break@0: %tuple.type.9fb} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.196: type = struct_type {.discriminant: %u1, .payload: %.96b} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
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
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %.514: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.0e0, %Try.facet [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Optional.as.Try.impl.FromBreak.a73, @Optional.as.Try.impl.FromBreak(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.10: type = fn_type @Destroy.Op.loc5_35.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.10: %Destroy.Op.type.1d8f74.10 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.1: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.1: %Int.as.AddWith.impl.Op.type.1eac76.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.2: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.2: %Int.as.AddWith.impl.Op.type.1eac76.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Optional.Some.4b6, @Optional.Some(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.48e: @Optional.%Optional.Some.type (%Optional.Some.type.304) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.Some (constants.%Optional.Some.2a0)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.5fb: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%DefaultOptionalStorage (constants.%DefaultOptionalStorage.d50)]
// CHECK:STDOUT:   %Core.import_ref.77c: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.None.type (%T.as_type.as.OptionalStorage.impl.None.type.0a1) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.None (constants.%T.as_type.as.OptionalStorage.impl.None.e06)]
// CHECK:STDOUT:   %Core.import_ref.d06: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Some.type (%T.as_type.as.OptionalStorage.impl.Some.type.492) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Some (constants.%T.as_type.as.OptionalStorage.impl.Some.89a)]
// CHECK:STDOUT:   %Core.import_ref.f08: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has.type (%T.as_type.as.OptionalStorage.impl.Has.type.e5a) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has (constants.%T.as_type.as.OptionalStorage.impl.Has.4ee)]
// CHECK:STDOUT:   %Core.import_ref.25e: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get.type (%T.as_type.as.OptionalStorage.impl.Get.type.a12) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get (constants.%T.as_type.as.OptionalStorage.impl.Get.d32)]
// CHECK:STDOUT:   %Core.import_ref.e6b = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.460 = impl_witness_table (%Core.import_ref.5fb, %Core.import_ref.77c, %Core.import_ref.d06, %Core.import_ref.f08, %Core.import_ref.25e, %Core.import_ref.e6b), @T.as_type.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.import_ref.c11 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f64 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.1ad: @Optional.as.Try.impl.%Optional.as.Try.impl.Branch.type (%Optional.as.Try.impl.Branch.type.b35) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.Try.impl.%Optional.as.Try.impl.Branch (constants.%Optional.as.Try.impl.Branch.c49)]
// CHECK:STDOUT:   %Core.import_ref.85f: @Optional.as.Try.impl.%Optional.as.Try.impl.FromBreak.type (%Optional.as.Try.impl.FromBreak.type.ff4) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.Try.impl.%Optional.as.Try.impl.FromBreak (constants.%Optional.as.Try.impl.FromBreak.13f)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.c11, %Core.import_ref.f64, %Core.import_ref.1ad, %Core.import_ref.85f), @Optional.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3a: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.b21 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.8a3a), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.591 = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.591 = wrapper_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.591 = out_param_pattern [concrete = constants.%return.param_patt.849]
// CHECK:STDOUT:     %return.patt: %pattern_type.591 = return_slot_pattern %return.param_patt, %Optional.loc4_49 [concrete = constants.%return.patt.893]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc4_32: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref.loc4_36: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32.loc4_46: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %OptionalStorage.facet.loc4_49: %OptionalStorage.type = facet_value %i32.loc4_46, (constants.%OptionalStorage.impl_witness.c8c) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %.loc4_49.3: %OptionalStorage.type = converted %i32.loc4_46, %OptionalStorage.facet.loc4_49 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %Optional.loc4_49: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.755]
// CHECK:STDOUT:     %.loc4_49.4: Core.Form = init_form %Optional.loc4_49 [concrete = constants.%.d22]
// CHECK:STDOUT:     %o.param: %Optional.755 = value_param call_param0
// CHECK:STDOUT:     %.loc4_26.1: type = splice_block %Optional.loc4_26 [concrete = constants.%Optional.755] {
// CHECK:STDOUT:       %Core.ref.loc4_9: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc4_13: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc4_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %OptionalStorage.facet.loc4_26: %OptionalStorage.type = facet_value %i32.loc4_23, (constants.%OptionalStorage.impl_witness.c8c) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:       %.loc4_26.2: %OptionalStorage.type = converted %i32.loc4_23, %OptionalStorage.facet.loc4_26 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:       %Optional.loc4_26: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.755]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %o: %Optional.755 = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %Optional.755 = out_param call_param1
// CHECK:STDOUT:     %return: ref %Optional.755 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc4_26.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc4_26.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%o.param: %Optional.755) -> out %return.param: %Optional.755 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc5: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Optional.ref.loc5: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %i32.loc5: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %OptionalStorage.facet.loc5_27: %OptionalStorage.type = facet_value %i32.loc5, (constants.%OptionalStorage.impl_witness.c8c) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc5_27: %OptionalStorage.type = converted %i32.loc5, %OptionalStorage.facet.loc5_27 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %Optional.loc5: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.755]
// CHECK:STDOUT:   %.loc5_28: %Optional.Some.type.0b0 = specific_constant imports.%Core.import_ref.48e, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.Some.4b6]
// CHECK:STDOUT:   %Some.ref: %Optional.Some.type.0b0 = name_ref Some, %.loc5_28 [concrete = constants.%Optional.Some.4b6]
// CHECK:STDOUT:   %o.ref: %Optional.755 = name_ref o, %o
// CHECK:STDOUT:   %impl.elem2: %.7bc = impl_witness_access constants.%Try.impl_witness.0d4, element2 [concrete = constants.%Optional.as.Try.impl.Branch.e19]
// CHECK:STDOUT:   %bound_method.loc5_35.1: <bound method> = bound_method %o.ref, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc5_35.1: <specific function> = specific_function %impl.elem2, @Optional.as.Try.impl.Branch(constants.%OptionalStorage.facet) [concrete = constants.%Optional.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_35.2: <bound method> = bound_method %o.ref, %specific_fn.loc5_35.1
// CHECK:STDOUT:   %.loc5_35.1: ref %ControlFlow.59f = temporary_storage
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.call: init %ControlFlow.59f to %.loc5_35.1 = call %bound_method.loc5_35.2(%o.ref)
// CHECK:STDOUT:   %.loc5_35.2: ref %ControlFlow.59f = temporary %.loc5_35.1, %Optional.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1.loc5_35: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc5_35.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc5_35.3: <bound method> = bound_method %int_1.loc5_35, %impl.elem0.loc5_35.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc5_35.2: <specific function> = specific_function %impl.elem0.loc5_35.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc5_35.4: <bound method> = bound_method %int_1.loc5_35, %specific_fn.loc5_35.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_35: init %u1 = call %bound_method.loc5_35.4(%int_1.loc5_35) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc5_35.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_35 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc5_35.4: %u1 = converted %int_1.loc5_35, %.loc5_35.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc5_35.5: ref %u1 = class_element_access %.loc5_35.2, element0
// CHECK:STDOUT:   %impl.elem0.loc5_35.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc5_35.5: <bound method> = bound_method %.loc5_35.4, %impl.elem0.loc5_35.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc5_35.3: <specific function> = specific_function %impl.elem0.loc5_35.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc5_35.6: <bound method> = bound_method %.loc5_35.4, %specific_fn.loc5_35.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc5_35.6: %u1 = acquire_value %.loc5_35.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc5_35.6(%.loc5_35.4, %.loc5_35.6)
// CHECK:STDOUT:   %.loc5_35.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc5_35.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc5_35.7
// CHECK:STDOUT:   if %.loc5_35.8 br !.loc5_35.1 else br !.loc5_35.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc5_35.1:
// CHECK:STDOUT:   %.loc5_35.9: ref %.96b = class_element_access %.loc5_35.2, element1
// CHECK:STDOUT:   %.loc5_35.10: ref %tuple.type.9fb = class_element_access %.loc5_35.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc5_35.1: ref %empty_tuple.type = tuple_access %.loc5_35.10, element0
// CHECK:STDOUT:   %tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc5_35.11: %empty_tuple.type = converted %tuple.elem0.loc5_35.1, %tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Optional.755, (constants.%Try.impl_witness.0d4) [concrete = constants.%Try.facet]
// CHECK:STDOUT:   %.loc5_35.12: %Try.type = converted constants.%Optional.755, %Try.facet [concrete = constants.%Try.facet]
// CHECK:STDOUT:   %impl.elem3: %.514 = impl_witness_access constants.%Try.impl_witness.0d4, element3 [concrete = constants.%Optional.as.Try.impl.FromBreak.a73]
// CHECK:STDOUT:   %specific_fn.loc5_35.4: <specific function> = specific_function %impl.elem3, @Optional.as.Try.impl.FromBreak(constants.%OptionalStorage.facet) [concrete = constants.%Optional.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc4_49.1: ref %Optional.755 = splice_block %return.param {}
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.call: init %Optional.755 to %.loc4_49.1 = call %specific_fn.loc5_35.4(%.loc5_35.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc5_35.1: <bound method> = bound_method %.loc5_35.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc5_35.1: init %empty_tuple.type = call %Destroy.Op.bound.loc5_35.1(%.loc5_35.2)
// CHECK:STDOUT:   return %Optional.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc5_35.2:
// CHECK:STDOUT:   %.loc5_35.13: ref %.96b = class_element_access %.loc5_35.2, element1
// CHECK:STDOUT:   %.loc5_35.14: ref %tuple.type.a8a = class_element_access %.loc5_35.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc5_35.2: ref %i32 = tuple_access %.loc5_35.14, element0
// CHECK:STDOUT:   %.loc5_35.15: %i32 = acquire_value %tuple.elem0.loc5_35.2
// CHECK:STDOUT:   %int_1.loc5_39: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:   %bound_method.loc5_37.1: <bound method> = bound_method %.loc5_35.15, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc5_37: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:   %bound_method.loc5_37.2: <bound method> = bound_method %.loc5_35.15, %specific_fn.loc5_37
// CHECK:STDOUT:   %.loc5_37.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc5_37.1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %.loc5_35.15, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:   %bound_method.loc5_37.3: <bound method> = bound_method %.loc5_35.15, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc5_39: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc5_39.1: <bound method> = bound_method %int_1.loc5_39, %impl.elem0.loc5_39 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc5_39: <specific function> = specific_function %impl.elem0.loc5_39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc5_39.2: <bound method> = bound_method %int_1.loc5_39, %specific_fn.loc5_39 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_39: init %i32 = call %bound_method.loc5_39.2(%int_1.loc5_39) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc5_39.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_39 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc5_39.2: %i32 = converted %int_1.loc5_39, %.loc5_39.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc5_37.3(%.loc5_35.15, %.loc5_39.2)
// CHECK:STDOUT:   %OptionalStorage.facet.loc5_40.1: %OptionalStorage.type = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.c8c) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc5_40.1: %OptionalStorage.type = converted constants.%i32, %OptionalStorage.facet.loc5_40.1 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %OptionalStorage.facet.loc5_40.2: %OptionalStorage.type = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.c8c) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc5_40.2: %OptionalStorage.type = converted constants.%i32, %OptionalStorage.facet.loc5_40.2 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Some.ref, @Optional.Some(constants.%OptionalStorage.facet) [concrete = constants.%Optional.Some.specific_fn]
// CHECK:STDOUT:   %.loc4_49.2: ref %Optional.755 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc5_37.2: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc5_37.3: %i32 = converted %Int.as.AddWith.impl.Op.call, %.loc5_37.2
// CHECK:STDOUT:   %Optional.Some.call: init %Optional.755 to %.loc4_49.2 = call %Optional.Some.specific_fn(%.loc5_37.3)
// CHECK:STDOUT:   %Destroy.Op.bound.loc5_35.2: <bound method> = bound_method %.loc5_35.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc5_35.2: init %empty_tuple.type = call %Destroy.Op.bound.loc5_35.2(%.loc5_35.2)
// CHECK:STDOUT:   return %Optional.Some.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_35.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_35.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_35.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_35.4(%self.param: ref %empty_tuple.type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_35.5(%self.param: ref %tuple.type.9fb) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_35.6(%self.param: ref %.96b) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_35.7(%self.param: ref %struct_type.discriminant.payload.196) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_35.8(%self.param: ref %ControlFlow.59f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- pointer_niche.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.Some.type.304: type = fn_type @Optional.Some, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.Some.2a0: %Optional.Some.type.304 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %DefaultOptionalStorage.d50: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Some.type.492: type = fn_type @T.as_type.as.OptionalStorage.impl.Some, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Some.89a: %T.as_type.as.OptionalStorage.impl.Some.type.492 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.None.type.0a1: type = fn_type @T.as_type.as.OptionalStorage.impl.None, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.None.e06: %T.as_type.as.OptionalStorage.impl.None.type.0a1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.type.015: type = fn_type @ptr.as.OptionalStorage.impl.Get, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.972: %ptr.as.OptionalStorage.impl.Get.type.015 = struct_value () [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.type.0e1: type = fn_type @ptr.as.OptionalStorage.impl.Has, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.05c: %ptr.as.OptionalStorage.impl.Has.type.0e1 = struct_value () [symbolic]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.0ce: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%i32) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.f91: %OptionalStorage.type = facet_value %ptr.d08, (%OptionalStorage.impl_witness.0ce) [concrete]
// CHECK:STDOUT:   %Optional.5b3: type = class_type @Optional, @Optional(%OptionalStorage.facet.f91) [concrete]
// CHECK:STDOUT:   %pattern_type.ef8: type = pattern_type %Optional.5b3 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.ef8 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.ef8 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.loc5_54.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.3: %Destroy.Op.type.1d8f74.3 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.3: <witness> = custom_witness (%Destroy.Op.1a2547.3), @Destroy [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type = facet_value %i32, (%custom_witness.df9cc1.3, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.c8c: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.460, @T.as_type.as.OptionalStorage.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.097: %OptionalStorage.type = facet_value %i32, (%OptionalStorage.impl_witness.c8c) [concrete]
// CHECK:STDOUT:   %Optional.755: type = class_type @Optional, @Optional(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %.d22: Core.Form = init_form %Optional.755 [concrete]
// CHECK:STDOUT:   %pattern_type.591: type = pattern_type %Optional.755 [concrete]
// CHECK:STDOUT:   %return.param_patt.849: %pattern_type.591 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.893: %pattern_type.591 = return_slot_pattern %return.param_patt.849, %Optional.755 [concrete]
// CHECK:STDOUT:   %Deref.type: type = fn_type @Deref [concrete]
// CHECK:STDOUT:   %Deref: %Deref.type = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.Some.type.0b0: type = fn_type @Optional.Some, @Optional(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %Optional.Some.4b6: %Optional.Some.type.0b0 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.type.ff4: type = fn_type @Optional.as.Try.impl.FromBreak, @Optional.as.Try.impl(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.13f: %Optional.as.Try.impl.FromBreak.type.ff4 = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.type.b35: type = fn_type @Optional.as.Try.impl.Branch, @Optional.as.Try.impl(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.c49: %Optional.as.Try.impl.Branch.type.b35 = struct_value () [symbolic]
// CHECK:STDOUT:   %tuple.type.9fb: type = tuple_type (%empty_tuple.type) [concrete]
// CHECK:STDOUT:   %Try.impl_witness.0d4: <witness> = impl_witness imports.%Try.impl_witness_table, @Optional.as.Try.impl(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.type.418: type = fn_type @Optional.as.Try.impl.FromBreak, @Optional.as.Try.impl(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.a73: %Optional.as.Try.impl.FromBreak.type.418 = struct_value () [concrete]
// CHECK:STDOUT:   %Try.impl_witness.b48: <witness> = impl_witness imports.%Try.impl_witness_table, @Optional.as.Try.impl(%OptionalStorage.facet.f91) [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.type.7de: type = fn_type @Optional.as.Try.impl.Branch, @Optional.as.Try.impl(%OptionalStorage.facet.f91) [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.b3f: %Optional.as.Try.impl.Branch.type.7de = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.687: %Try.type = facet_value %Optional.5b3, (%Try.impl_witness.b48) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.ca7: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.687) [concrete]
// CHECK:STDOUT:   %.d27: type = fn_type_with_self_type %Try.WithSelf.Branch.type.ca7, %Try.facet.687 [concrete]
// CHECK:STDOUT:   %ControlFlow.729: type = class_type @ControlFlow, @ControlFlow(%ptr.d08, %empty_tuple.type) [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.specific_fn: <specific function> = specific_function %Optional.as.Try.impl.Branch.b3f, @Optional.as.Try.impl.Branch(%OptionalStorage.facet.f91) [concrete]
// CHECK:STDOUT:   %tuple.type.581: type = tuple_type (%ptr.d08) [concrete]
// CHECK:STDOUT:   %.293: type = custom_layout_type {size=8, align=8, .Continue@0: %tuple.type.581, .Break@0: %tuple.type.9fb} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.735: type = struct_type {.discriminant: %u1, .payload: %.293} [concrete]
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
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %Try.facet.99d: %Try.type = facet_value %Optional.755, (%Try.impl_witness.0d4) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.0e0: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.99d) [concrete]
// CHECK:STDOUT:   %.514: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.0e0, %Try.facet.99d [concrete]
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Optional.as.Try.impl.FromBreak.a73, @Optional.as.Try.impl.FromBreak(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.11: type = fn_type @Destroy.Op.loc6_37.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.11: %Destroy.Op.type.1d8f74.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Optional.Some.4b6, @Optional.Some(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.48e: @Optional.%Optional.Some.type (%Optional.Some.type.304) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.Some (constants.%Optional.Some.2a0)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.5fb: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%DefaultOptionalStorage (constants.%DefaultOptionalStorage.d50)]
// CHECK:STDOUT:   %Core.import_ref.77c: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.None.type (%T.as_type.as.OptionalStorage.impl.None.type.0a1) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.None (constants.%T.as_type.as.OptionalStorage.impl.None.e06)]
// CHECK:STDOUT:   %Core.import_ref.d06: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Some.type (%T.as_type.as.OptionalStorage.impl.Some.type.492) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Some (constants.%T.as_type.as.OptionalStorage.impl.Some.89a)]
// CHECK:STDOUT:   %Core.import_ref.fad = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.818 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.e6b = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.460 = impl_witness_table (%Core.import_ref.5fb, %Core.import_ref.77c, %Core.import_ref.d06, %Core.import_ref.fad, %Core.import_ref.818, %Core.import_ref.e6b), @T.as_type.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.509: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%MaybeUnformed (constants.%MaybeUnformed.ddb)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c9a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.5751: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has.type (%ptr.as.OptionalStorage.impl.Has.type.0e1) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has (constants.%ptr.as.OptionalStorage.impl.Has.05c)]
// CHECK:STDOUT:   %Core.import_ref.008: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get.type (%ptr.as.OptionalStorage.impl.Get.type.015) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get (constants.%ptr.as.OptionalStorage.impl.Get.972)]
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.509, %Core.import_ref.105, %Core.import_ref.c9a, %Core.import_ref.5751, %Core.import_ref.008, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.import_ref.c11 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f64 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.1ad: @Optional.as.Try.impl.%Optional.as.Try.impl.Branch.type (%Optional.as.Try.impl.Branch.type.b35) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.Try.impl.%Optional.as.Try.impl.Branch (constants.%Optional.as.Try.impl.Branch.c49)]
// CHECK:STDOUT:   %Core.import_ref.85f: @Optional.as.Try.impl.%Optional.as.Try.impl.FromBreak.type (%Optional.as.Try.impl.FromBreak.type.ff4) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.Try.impl.%Optional.as.Try.impl.FromBreak (constants.%Optional.as.Try.impl.FromBreak.13f)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.c11, %Core.import_ref.f64, %Core.import_ref.1ad, %Core.import_ref.85f), @Optional.as.Try.impl [concrete]
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
// CHECK:STDOUT:   %Deref.decl: %Deref.type = fn_decl @Deref [concrete = constants.%Deref] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.ef8 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.ef8 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.591 = out_param_pattern [concrete = constants.%return.param_patt.849]
// CHECK:STDOUT:     %return.patt: %pattern_type.591 = return_slot_pattern %return.param_patt, %Optional.loc5_54 [concrete = constants.%return.patt.893]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc5_37: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref.loc5_41: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32.loc5_51: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %OptionalStorage.facet.loc5_54: %OptionalStorage.type = facet_value %i32.loc5_51, (constants.%OptionalStorage.impl_witness.c8c) [concrete = constants.%OptionalStorage.facet.097]
// CHECK:STDOUT:     %.loc5_54.3: %OptionalStorage.type = converted %i32.loc5_51, %OptionalStorage.facet.loc5_54 [concrete = constants.%OptionalStorage.facet.097]
// CHECK:STDOUT:     %Optional.loc5_54: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.097) [concrete = constants.%Optional.755]
// CHECK:STDOUT:     %.loc5_54.4: Core.Form = init_form %Optional.loc5_54 [concrete = constants.%.d22]
// CHECK:STDOUT:     %p.param: %Optional.5b3 = value_param call_param0
// CHECK:STDOUT:     %.loc5_31.1: type = splice_block %Optional.loc5_31 [concrete = constants.%Optional.5b3] {
// CHECK:STDOUT:       %Core.ref.loc5_13: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc5_17: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc5_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %ptr: type = ptr_type %i32.loc5_27 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:       %OptionalStorage.facet.loc5_31: %OptionalStorage.type = facet_value %ptr, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet.f91]
// CHECK:STDOUT:       %.loc5_31.2: %OptionalStorage.type = converted %ptr, %OptionalStorage.facet.loc5_31 [concrete = constants.%OptionalStorage.facet.f91]
// CHECK:STDOUT:       %Optional.loc5_31: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.f91) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %Optional.5b3 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %Optional.755 = out_param call_param1
// CHECK:STDOUT:     %return: ref %Optional.755 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_54.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_54.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Deref(%p.param: %Optional.5b3) -> out %return.param: %Optional.755 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc6: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Optional.ref.loc6: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %i32.loc6: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %OptionalStorage.facet.loc6_27: %OptionalStorage.type = facet_value %i32.loc6, (constants.%OptionalStorage.impl_witness.c8c) [concrete = constants.%OptionalStorage.facet.097]
// CHECK:STDOUT:   %.loc6_27: %OptionalStorage.type = converted %i32.loc6, %OptionalStorage.facet.loc6_27 [concrete = constants.%OptionalStorage.facet.097]
// CHECK:STDOUT:   %Optional.loc6: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.097) [concrete = constants.%Optional.755]
// CHECK:STDOUT:   %.loc6_28: %Optional.Some.type.0b0 = specific_constant imports.%Core.import_ref.48e, @Optional(constants.%OptionalStorage.facet.097) [concrete = constants.%Optional.Some.4b6]
// CHECK:STDOUT:   %Some.ref: %Optional.Some.type.0b0 = name_ref Some, %.loc6_28 [concrete = constants.%Optional.Some.4b6]
// CHECK:STDOUT:   %p.ref: %Optional.5b3 = name_ref p, %p
// CHECK:STDOUT:   %impl.elem2: %.d27 = impl_witness_access constants.%Try.impl_witness.b48, element2 [concrete = constants.%Optional.as.Try.impl.Branch.b3f]
// CHECK:STDOUT:   %bound_method.loc6_37.1: <bound method> = bound_method %p.ref, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc6_37.1: <specific function> = specific_function %impl.elem2, @Optional.as.Try.impl.Branch(constants.%OptionalStorage.facet.f91) [concrete = constants.%Optional.as.Try.impl.Branch.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_37.2: <bound method> = bound_method %p.ref, %specific_fn.loc6_37.1
// CHECK:STDOUT:   %.loc6_37.1: ref %ControlFlow.729 = temporary_storage
// CHECK:STDOUT:   %Optional.as.Try.impl.Branch.call: init %ControlFlow.729 to %.loc6_37.1 = call %bound_method.loc6_37.2(%p.ref)
// CHECK:STDOUT:   %.loc6_37.2: ref %ControlFlow.729 = temporary %.loc6_37.1, %Optional.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_37.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc6_37.3: <bound method> = bound_method %int_1, %impl.elem0.loc6_37.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc6_37.2: <specific function> = specific_function %impl.elem0.loc6_37.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_37.4: <bound method> = bound_method %int_1, %specific_fn.loc6_37.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc6_37.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc6_37.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc6_37.4: %u1 = converted %int_1, %.loc6_37.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc6_37.5: ref %u1 = class_element_access %.loc6_37.2, element0
// CHECK:STDOUT:   %impl.elem0.loc6_37.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc6_37.5: <bound method> = bound_method %.loc6_37.4, %impl.elem0.loc6_37.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc6_37.3: <specific function> = specific_function %impl.elem0.loc6_37.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc6_37.6: <bound method> = bound_method %.loc6_37.4, %specific_fn.loc6_37.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc6_37.6: %u1 = acquire_value %.loc6_37.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc6_37.6(%.loc6_37.4, %.loc6_37.6)
// CHECK:STDOUT:   %.loc6_37.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc6_37.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc6_37.7
// CHECK:STDOUT:   if %.loc6_37.8 br !.loc6_37.1 else br !.loc6_37.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc6_37.1:
// CHECK:STDOUT:   %.loc6_37.9: ref %.293 = class_element_access %.loc6_37.2, element1
// CHECK:STDOUT:   %.loc6_37.10: ref %tuple.type.9fb = class_element_access %.loc6_37.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc6_37.1: ref %empty_tuple.type = tuple_access %.loc6_37.10, element0
// CHECK:STDOUT:   %tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_37.11: %empty_tuple.type = converted %tuple.elem0.loc6_37.1, %tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Optional.755, (constants.%Try.impl_witness.0d4) [concrete = constants.%Try.facet.99d]
// CHECK:STDOUT:   %.loc6_37.12: %Try.type = converted constants.%Optional.755, %Try.facet [concrete = constants.%Try.facet.99d]
// CHECK:STDOUT:   %impl.elem3: %.514 = impl_witness_access constants.%Try.impl_witness.0d4, element3 [concrete = constants.%Optional.as.Try.impl.FromBreak.a73]
// CHECK:STDOUT:   %specific_fn.loc6_37.4: <specific function> = specific_function %impl.elem3, @Optional.as.Try.impl.FromBreak(constants.%OptionalStorage.facet.097) [concrete = constants.%Optional.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc5_54.1: ref %Optional.755 = splice_block %return.param {}
// CHECK:STDOUT:   %Optional.as.Try.impl.FromBreak.call: init %Optional.755 to %.loc5_54.1 = call %specific_fn.loc6_37.4(%.loc6_37.11)
// CHECK:STDOUT:   %Destroy.Op.bound.loc6_37.1: <bound method> = bound_method %.loc6_37.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc6_37.1: init %empty_tuple.type = call %Destroy.Op.bound.loc6_37.1(%.loc6_37.2)
// CHECK:STDOUT:   return %Optional.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc6_37.2:
// CHECK:STDOUT:   %.loc6_37.13: ref %.293 = class_element_access %.loc6_37.2, element1
// CHECK:STDOUT:   %.loc6_37.14: ref %tuple.type.581 = class_element_access %.loc6_37.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc6_37.2: ref %ptr.d08 = tuple_access %.loc6_37.14, element0
// CHECK:STDOUT:   %.loc6_37.15: %ptr.d08 = acquire_value %tuple.elem0.loc6_37.2
// CHECK:STDOUT:   %.loc6_34.1: ref %i32 = deref %.loc6_37.15
// CHECK:STDOUT:   %OptionalStorage.facet.loc6_39.1: %OptionalStorage.type = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.c8c) [concrete = constants.%OptionalStorage.facet.097]
// CHECK:STDOUT:   %.loc6_39.1: %OptionalStorage.type = converted constants.%i32, %OptionalStorage.facet.loc6_39.1 [concrete = constants.%OptionalStorage.facet.097]
// CHECK:STDOUT:   %OptionalStorage.facet.loc6_39.2: %OptionalStorage.type = facet_value constants.%i32, (constants.%OptionalStorage.impl_witness.c8c) [concrete = constants.%OptionalStorage.facet.097]
// CHECK:STDOUT:   %.loc6_39.2: %OptionalStorage.type = converted constants.%i32, %OptionalStorage.facet.loc6_39.2 [concrete = constants.%OptionalStorage.facet.097]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Some.ref, @Optional.Some(constants.%OptionalStorage.facet.097) [concrete = constants.%Optional.Some.specific_fn]
// CHECK:STDOUT:   %.loc5_54.2: ref %Optional.755 = splice_block %return.param {}
// CHECK:STDOUT:   %.loc6_34.2: %i32 = acquire_value %.loc6_34.1
// CHECK:STDOUT:   %Optional.Some.call: init %Optional.755 to %.loc5_54.2 = call %Optional.Some.specific_fn(%.loc6_34.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc6_37.2: <bound method> = bound_method %.loc6_37.2, constants.%Destroy.Op.1a2547.11
// CHECK:STDOUT:   %Destroy.Op.call.loc6_37.2: init %empty_tuple.type = call %Destroy.Op.bound.loc6_37.2(%.loc6_37.2)
// CHECK:STDOUT:   return %Optional.Some.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_37.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_37.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_37.3(%self.param: ref %tuple.type.581) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_37.4(%self.param: ref %empty_tuple.type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_37.5(%self.param: ref %tuple.type.9fb) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_37.6(%self.param: ref %.293) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_37.7(%self.param: ref %struct_type.discriminant.payload.735) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_37.8(%self.param: ref %ControlFlow.729) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
