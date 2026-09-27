// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/alternative_copy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/alternative_copy.carbon

// Choice copies through the synthesized `Core.Copy` witness (W-075,
// fork/w075/plan.md §2/§3): value-position consumption of a choice by an
// initializing destination — return position, `var` initialization,
// assignment — value-copies by way of `Copy.Op`, which for a choice self is
// the synthesized primitive-copy builtin (custom_witness.cpp
// `LookupChoiceCopyWitness`). These are the P-1 flips of the shapes that
// diagnosed `CopyOfUncopyableType` before the witness landed, plus the
// boundary shapes that never copied and the SF-1 shadowing pin.

// --- payload_free.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

//@dump-sem-ir-begin
// Return position: the alternative constant value-copies into the return
// through the synthesized witness's `Copy.Op` call.
fn MakeOn() -> Flag { return Flag.On; }

// var initialization from the constant, assignment from the constant, and
// return of a choice-typed runtime binding: all three previously-diagnosed
// shapes on one variable.
fn RoundTrip() -> Flag {
  var f: Flag = Flag.Off;
  f = Flag.On;
  return f;
}
//@dump-sem-ir-end

// --- doc_shape.carbon
library "[[@TEST_NAME]]";

// The design's canonical example (docs/design/sum_types.md:63-66 declaration,
// :74-75 consumption, R27 spelling-diffed): `var` initialization from the
// empty alternative's constant, then the None-to-Some transition on the same
// variable.
choice Optional(T: type) {
  Some(value: T),
  None
}

//@dump-sem-ir-begin
fn DocShape() -> Optional(i32) {
  var my_opt: Optional(i32) = Optional(i32).None;
  my_opt = Optional(i32).Some(42);
  // The transition back — assigning the `.None` constant is the same copy
  // path — and the pointer-rep binding return.
  my_opt = Optional(i32).None;
  return my_opt;
}
//@dump-sem-ir-end

// --- payload_free_of_payload_choice.carbon
library "[[@TEST_NAME]]";

// The W-075 minting shape (the W69b gate round's falsified P-5 sketch): a
// payload-carrying choice's payload-free alternative constant returned by
// value. `Pair(i64)` is pointer-rep/in-place, so the synthesized `Copy.Op`
// call carries a return slot.
choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

//@dump-sem-ir-begin
fn MakeNeither() -> Pair(i64) { return Pair(i64).Neither; }
//@dump-sem-ir-end

// --- boundary.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

fn Take(unused f: Flag) -> i32 { return 0; }

//@dump-sem-ir-begin
// Unaffected shapes (fork/w075/plan.md §0): a `let` binds the constant VALUE
// directly and a value param is a value binding — neither converts to an
// initializing destination, so no `Copy.Op` call appears in this dump.
let flag: Flag = Flag.On;

fn PassByValue() -> i32 { return Take(Flag.Off); }
//@dump-sem-ir-end

// --- generic.carbon
library "[[@TEST_NAME]]";

choice Opt(T: type) {
  Some(value: T),
  None
}

//@dump-sem-ir-begin
// Symbolic self: the copy inside the generic body defers witness building
// (`LookupChoiceCopyWitness` answers yes with `InstId::None`, the destroy
// posture); the concrete instantiation builds the primitive-copy witness at
// monomorphization — the least-exercised link (fork/w075/plan.md §5, P-1).
fn Make(generic T: type) -> Opt(T) { return Opt(T).None; }

fn UseConcrete() -> Opt(i32) { return Make(i32); }
//@dump-sem-ir-end

// --- shadowed_user_impl.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// sum_types.md:95-98 sanctions extending a choice with an out-of-line impl,
// but the custom-witness dispatch PRECEDES candidate-impl iteration
// (impl_lookup.cpp: "Only consider candidates when a custom witness didn't
// apply"), so this user `Core.Copy` impl is SHADOWED for choice selves: the
// copy below binds the synthesized primitive-copy `Copy.Op`, never `Op`
// declared here — the declared SF-1 consequence (fork/w075/plan.md review
// amendment 1), the same posture `Destroy` already has for choices. No
// diagnostic; deterministic.
impl Flag as Core.Copy {
  // `return self` is itself a value copy; it compiles without diagnostic and
  // keeps `self` used — the dump below pins which witness serves the call
  // site OUTSIDE the impl.
  fn Op(self) -> Self { return self; }
}

//@dump-sem-ir-begin
fn CopyIt(f: Flag) -> Flag { return f; }
//@dump-sem-ir-end

// CHECK:STDOUT: --- payload_free.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Flag: type = class_type @Flag [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %.97d: Core.Form = init_form %Flag [concrete]
// CHECK:STDOUT:   %pattern_type.5bc: type = pattern_type %Flag [concrete]
// CHECK:STDOUT:   %return.param_patt.f50: %pattern_type.5bc = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.aa2: %pattern_type.5bc = return_slot_pattern %return.param_patt.f50, %Flag [concrete]
// CHECK:STDOUT:   %MakeOn.type: type = fn_type @MakeOn [concrete]
// CHECK:STDOUT:   %MakeOn: %MakeOn.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.Op.type: type = fn_type @Copy.Op [concrete]
// CHECK:STDOUT:   %Copy.Op: %Copy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.14b: <witness> = custom_witness (%Copy.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.fb5: %Copy.type = facet_value %Flag, (%custom_witness.14b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.46e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.fb5) [concrete]
// CHECK:STDOUT:   %.819: type = fn_type_with_self_type %Copy.WithSelf.Op.type.46e, %Copy.facet.fb5 [concrete]
// CHECK:STDOUT:   %RoundTrip.type: type = fn_type @RoundTrip [concrete]
// CHECK:STDOUT:   %RoundTrip: %RoundTrip.type = struct_value () [concrete]
// CHECK:STDOUT:   %f.patt: %pattern_type.5bc = ref_binding_pattern f [concrete]
// CHECK:STDOUT:   %f.var_patt: %pattern_type.5bc = var_pattern %f.patt [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc17_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %MakeOn.decl: %MakeOn.type = fn_decl @MakeOn [concrete = constants.%MakeOn] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5bc = out_param_pattern [concrete = constants.%return.param_patt.f50]
// CHECK:STDOUT:     %return.patt: %pattern_type.5bc = return_slot_pattern %return.param_patt, %Flag.ref.loc11_16 [concrete = constants.%return.patt.aa2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Flag.ref.loc11_16: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:     %.loc11_16.2: Core.Form = init_form %Flag.ref.loc11_16 [concrete = constants.%.97d]
// CHECK:STDOUT:     %return.param: ref %Flag = out_param call_param0
// CHECK:STDOUT:     %return: ref %Flag = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %RoundTrip.decl: %RoundTrip.type = fn_decl @RoundTrip [concrete = constants.%RoundTrip] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5bc = out_param_pattern [concrete = constants.%return.param_patt.f50]
// CHECK:STDOUT:     %return.patt: %pattern_type.5bc = return_slot_pattern %return.param_patt, %Flag.ref.loc16 [concrete = constants.%return.patt.aa2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Flag.ref.loc16: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:     %.loc16_19.2: Core.Form = init_form %Flag.ref.loc16 [concrete = constants.%.97d]
// CHECK:STDOUT:     %return.param: ref %Flag = out_param call_param0
// CHECK:STDOUT:     %return: ref %Flag = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeOn() -> out %return.param: %Flag {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Flag.ref.loc11_30: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:   %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:   %impl.elem0: %.819 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %On.ref, %impl.elem0
// CHECK:STDOUT:   %.loc11_16.1: ref %Flag = splice_block %return.param {}
// CHECK:STDOUT:   %Copy.Op.call: init %Flag to %.loc11_16.1 = call %bound_method(%On.ref)
// CHECK:STDOUT:   return %Copy.Op.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @RoundTrip() -> out %return.param: %Flag {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %f.var: ref %Flag = var_storage %f.var_patt
// CHECK:STDOUT:   %Flag.ref.loc17_17: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:   %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:   %impl.elem0.loc17: %.819 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc17: <bound method> = bound_method %Off.ref, %impl.elem0.loc17
// CHECK:STDOUT:   %.loc17: ref %Flag = splice_block %f.var {}
// CHECK:STDOUT:   %Copy.Op.call.loc17: init %Flag to %.loc17 = call %bound_method.loc17(%Off.ref)
// CHECK:STDOUT:   assign %f.var, %Copy.Op.call.loc17
// CHECK:STDOUT:   %Flag.ref.loc17_10: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:   %f: ref %Flag = wrapper_binding f, %f.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %f.patt: %pattern_type.5bc = ref_binding_pattern f [concrete = constants.%f.patt]
// CHECK:STDOUT:     %f.var_patt: %pattern_type.5bc = var_pattern %f.patt [concrete = constants.%f.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %f.ref.loc18: ref %Flag = name_ref f, %f
// CHECK:STDOUT:   %Flag.ref.loc18: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:   %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:   %impl.elem0.loc18: %.819 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc18: <bound method> = bound_method %On.ref, %impl.elem0.loc18
// CHECK:STDOUT:   %.loc18: ref %Flag = splice_block %f.ref.loc18 {}
// CHECK:STDOUT:   %Copy.Op.call.loc18: init %Flag to %.loc18 = call %bound_method.loc18(%On.ref)
// CHECK:STDOUT:   assign %f.ref.loc18, %Copy.Op.call.loc18
// CHECK:STDOUT:   %f.ref.loc19: ref %Flag = name_ref f, %f
// CHECK:STDOUT:   %.loc19: %Flag = acquire_value %f.ref.loc19
// CHECK:STDOUT:   %impl.elem0.loc19: %.819 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc19: <bound method> = bound_method %.loc19, %impl.elem0.loc19
// CHECK:STDOUT:   %.loc16_19.1: ref %Flag = splice_block %return.param {}
// CHECK:STDOUT:   %Copy.Op.call.loc19: init %Flag to %.loc16_19.1 = call %bound_method.loc19(%.loc19)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %f.var, constants.%Destroy.Op.1a2547.4
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%f.var)
// CHECK:STDOUT:   return %Copy.Op.call.loc19 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc17_3.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc17_3.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc17_3.3(%self.param: ref %struct_type.discriminant) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc17_3.4(%self.param: ref %Flag) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- doc_shape.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Optional.Some.type.d69: type = fn_type @Optional.Some, @Optional(%T.67d) [symbolic]
// CHECK:STDOUT:   %Optional.Some.424: %Optional.Some.type.d69 = struct_value () [symbolic]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Optional.d7e: type = class_type @Optional, @Optional(%i32) [concrete]
// CHECK:STDOUT:   %.da7: Core.Form = init_form %Optional.d7e [concrete]
// CHECK:STDOUT:   %pattern_type.e8f: type = pattern_type %Optional.d7e [concrete]
// CHECK:STDOUT:   %return.param_patt.f4f: %pattern_type.e8f = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.882: %pattern_type.e8f = return_slot_pattern %return.param_patt.f4f, %Optional.d7e [concrete]
// CHECK:STDOUT:   %DocShape.type: type = fn_type @DocShape [concrete]
// CHECK:STDOUT:   %DocShape: %DocShape.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.e99: type = struct_type {.discriminant: %u1, .payload: %.e8e} [concrete]
// CHECK:STDOUT:   %Optional.Some.type.fb9: type = fn_type @Optional.Some, @Optional(%i32) [concrete]
// CHECK:STDOUT:   %Optional.Some.f27: %Optional.Some.type.fb9 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.060: %.e8e = uninitialized_value [concrete]
// CHECK:STDOUT:   %Optional.val.dae: %Optional.d7e = struct_value (%int_1.233, %uninit.060) [concrete]
// CHECK:STDOUT:   %my_opt.patt: %pattern_type.e8f = ref_binding_pattern my_opt [concrete]
// CHECK:STDOUT:   %my_opt.var_patt: %pattern_type.e8f = var_pattern %my_opt.patt [concrete]
// CHECK:STDOUT:   %Copy.Op.type: type = fn_type @Copy.Op [concrete]
// CHECK:STDOUT:   %Copy.Op: %Copy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.14b: <witness> = custom_witness (%Copy.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.78c: %Copy.type = facet_value %Optional.d7e, (%custom_witness.14b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.ed6: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.78c) [concrete]
// CHECK:STDOUT:   %.db3: type = fn_type_with_self_type %Copy.WithSelf.Op.type.ed6, %Copy.facet.78c [concrete]
// CHECK:STDOUT:   %Copy.Op.bound: <bound method> = bound_method %Optional.val.dae, %Copy.Op [concrete]
// CHECK:STDOUT:   %int_42.20e: Core.IntLiteral = int_value 42 [concrete]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Optional.Some.f27, @Optional.Some(%i32) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.098: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_42.ac4: %i32 = int_value 42 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc14_3.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Optional.Some.decl: @Optional.%Optional.Some.type (%Optional.Some.type.d69) = fn_decl @Optional.Some [symbolic = @Optional.%Optional.Some (constants.%Optional.Some.424)] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %DocShape.decl: %DocShape.type = fn_decl @DocShape [concrete = constants.%DocShape] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e8f = out_param_pattern [concrete = constants.%return.param_patt.f4f]
// CHECK:STDOUT:     %return.patt: %pattern_type.e8f = return_slot_pattern %return.param_patt, %Optional.loc13 [concrete = constants.%return.patt.882]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Optional.ref.loc13: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Optional.loc13: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:     %.loc13_30.2: Core.Form = init_form %Optional.loc13 [concrete = constants.%.da7]
// CHECK:STDOUT:     %return.param: ref %Optional.d7e = out_param call_param0
// CHECK:STDOUT:     %return: ref %Optional.d7e = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @DocShape() -> out %return.param: %Optional.d7e {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %my_opt.var: ref %Optional.d7e = var_storage %my_opt.var_patt
// CHECK:STDOUT:   %Optional.ref.loc14_31: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %i32.loc14_40: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Optional.loc14_43: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:   %.loc14_44: %Optional.d7e = specific_constant @Optional.%.loc10_1.13, @Optional(constants.%i32) [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:   %None.ref.loc14: %Optional.d7e = name_ref None, %.loc14_44 [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:   %impl.elem0.loc14: %.db3 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc14: <bound method> = bound_method %None.ref.loc14, %impl.elem0.loc14 [concrete = constants.%Copy.Op.bound]
// CHECK:STDOUT:   %.loc14_3: ref %Optional.d7e = splice_block %my_opt.var {}
// CHECK:STDOUT:   %Copy.Op.call.loc14: init %Optional.d7e to %.loc14_3 = call %bound_method.loc14(%None.ref.loc14) [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:   assign %my_opt.var, %Copy.Op.call.loc14
// CHECK:STDOUT:   %.loc14_27: type = splice_block %Optional.loc14_27 [concrete = constants.%Optional.d7e] {
// CHECK:STDOUT:     %Optional.ref.loc14_15: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32.loc14_24: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Optional.loc14_27: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %my_opt: ref %Optional.d7e = wrapper_binding my_opt, %my_opt.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %my_opt.patt: %pattern_type.e8f = ref_binding_pattern my_opt [concrete = constants.%my_opt.patt]
// CHECK:STDOUT:     %my_opt.var_patt: %pattern_type.e8f = var_pattern %my_opt.patt [concrete = constants.%my_opt.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %my_opt.ref.loc15: ref %Optional.d7e = name_ref my_opt, %my_opt
// CHECK:STDOUT:   %Optional.ref.loc15: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Optional.loc15: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:   %.loc15_25: %Optional.Some.type.fb9 = specific_constant generated.%Optional.Some.decl, @Optional(constants.%i32) [concrete = constants.%Optional.Some.f27]
// CHECK:STDOUT:   %Some.ref: %Optional.Some.type.fb9 = name_ref Some, %.loc15_25 [concrete = constants.%Optional.Some.f27]
// CHECK:STDOUT:   %int_42: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:   %Optional.Some.specific_fn: <specific function> = specific_function %Some.ref, @Optional.Some(constants.%i32) [concrete = constants.%Optional.Some.specific_fn]
// CHECK:STDOUT:   %.loc15_3: ref %Optional.d7e = splice_block %my_opt.ref.loc15 {}
// CHECK:STDOUT:   %impl.elem0.loc15: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_31.1: <bound method> = bound_method %int_42, %impl.elem0.loc15 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.bf3]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0.loc15, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc15_31.2: <bound method> = bound_method %int_42, %specific_fn [concrete = constants.%bound_method.098]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc15_31.2(%int_42) [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc15_31.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %.loc15_31.2: %i32 = converted %int_42, %.loc15_31.1 [concrete = constants.%int_42.ac4]
// CHECK:STDOUT:   %Optional.Some.call: init %Optional.d7e to %.loc15_3 = call %Optional.Some.specific_fn(%.loc15_31.2)
// CHECK:STDOUT:   assign %my_opt.ref.loc15, %Optional.Some.call
// CHECK:STDOUT:   %my_opt.ref.loc18: ref %Optional.d7e = name_ref my_opt, %my_opt
// CHECK:STDOUT:   %Optional.ref.loc18: %Optional.type = name_ref Optional, file.%Optional.decl [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %i32.loc18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Optional.loc18: type = class_type @Optional, @Optional(constants.%i32) [concrete = constants.%Optional.d7e]
// CHECK:STDOUT:   %.loc18_25: %Optional.d7e = specific_constant @Optional.%.loc10_1.13, @Optional(constants.%i32) [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:   %None.ref.loc18: %Optional.d7e = name_ref None, %.loc18_25 [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:   %impl.elem0.loc18: %.db3 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc18: <bound method> = bound_method %None.ref.loc18, %impl.elem0.loc18 [concrete = constants.%Copy.Op.bound]
// CHECK:STDOUT:   %.loc18_3: ref %Optional.d7e = splice_block %my_opt.ref.loc18 {}
// CHECK:STDOUT:   %Copy.Op.call.loc18: init %Optional.d7e to %.loc18_3 = call %bound_method.loc18(%None.ref.loc18) [concrete = constants.%Optional.val.dae]
// CHECK:STDOUT:   assign %my_opt.ref.loc18, %Copy.Op.call.loc18
// CHECK:STDOUT:   %my_opt.ref.loc19: ref %Optional.d7e = name_ref my_opt, %my_opt
// CHECK:STDOUT:   %.loc19: %Optional.d7e = acquire_value %my_opt.ref.loc19
// CHECK:STDOUT:   %impl.elem0.loc19: %.db3 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method.loc19: <bound method> = bound_method %.loc19, %impl.elem0.loc19
// CHECK:STDOUT:   %.loc13_30.1: ref %Optional.d7e = splice_block %return.param {}
// CHECK:STDOUT:   %Copy.Op.call.loc19: init %Optional.d7e to %.loc13_30.1 = call %bound_method.loc19(%.loc19)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %my_opt.var, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%my_opt.var)
// CHECK:STDOUT:   return %Copy.Op.call.loc19 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_3.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_3.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_3.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_3.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_3.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_3.6(%self.param: ref %.e8e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_3.7(%self.param: ref %struct_type.discriminant.payload.e99) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_3.8(%self.param: ref %Optional.d7e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- payload_free_of_payload_choice.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Pair.type: type = generic_class_type @Pair [concrete]
// CHECK:STDOUT:   %Pair.generic: %Pair.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Pair.01a: type = class_type @Pair, @Pair(%i64) [concrete]
// CHECK:STDOUT:   %.02d: Core.Form = init_form %Pair.01a [concrete]
// CHECK:STDOUT:   %pattern_type.fc3: type = pattern_type %Pair.01a [concrete]
// CHECK:STDOUT:   %return.param_patt.fa2: %pattern_type.fc3 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c93: %pattern_type.fc3 = return_slot_pattern %return.param_patt.fa2, %Pair.01a [concrete]
// CHECK:STDOUT:   %MakeNeither.type: type = fn_type @MakeNeither [concrete]
// CHECK:STDOUT:   %MakeNeither: %MakeNeither.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.1ac: type = tuple_type (%i64, %i64) [concrete]
// CHECK:STDOUT:   %.58e: type = custom_layout_type {size=16, align=8, .Both@0: %tuple.type.1ac} [concrete]
// CHECK:STDOUT:   %uninit.ccc: %.58e = uninitialized_value [concrete]
// CHECK:STDOUT:   %Pair.val.765: %Pair.01a = struct_value (%int_1.233, %uninit.ccc) [concrete]
// CHECK:STDOUT:   %Copy.Op.type: type = fn_type @Copy.Op [concrete]
// CHECK:STDOUT:   %Copy.Op: %Copy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.14b: <witness> = custom_witness (%Copy.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.7f8: %Copy.type = facet_value %Pair.01a, (%custom_witness.14b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4da: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.7f8) [concrete]
// CHECK:STDOUT:   %.129: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4da, %Copy.facet.7f8 [concrete]
// CHECK:STDOUT:   %Copy.Op.bound: <bound method> = bound_method %Pair.val.765, %Copy.Op [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %MakeNeither.decl: %MakeNeither.type = fn_decl @MakeNeither [concrete = constants.%MakeNeither] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.fc3 = out_param_pattern [concrete = constants.%return.param_patt.fa2]
// CHECK:STDOUT:     %return.patt: %pattern_type.fc3 = return_slot_pattern %return.param_patt, %Pair.loc13_29 [concrete = constants.%return.patt.c93]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Pair.ref.loc13_21: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:     %i64.loc13_26: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %Pair.loc13_29: type = class_type @Pair, @Pair(constants.%i64) [concrete = constants.%Pair.01a]
// CHECK:STDOUT:     %.loc13_29.2: Core.Form = init_form %Pair.loc13_29 [concrete = constants.%.02d]
// CHECK:STDOUT:     %return.param: ref %Pair.01a = out_param call_param0
// CHECK:STDOUT:     %return: ref %Pair.01a = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeNeither() -> out %return.param: %Pair.01a {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Pair.ref.loc13_40: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair.generic]
// CHECK:STDOUT:   %i64.loc13_45: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %Pair.loc13_48: type = class_type @Pair, @Pair(constants.%i64) [concrete = constants.%Pair.01a]
// CHECK:STDOUT:   %.loc13_49: %Pair.01a = specific_constant @Pair.%.loc10_1.13, @Pair(constants.%i64) [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:   %Neither.ref: %Pair.01a = name_ref Neither, %.loc13_49 [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:   %impl.elem0: %.129 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %Neither.ref, %impl.elem0 [concrete = constants.%Copy.Op.bound]
// CHECK:STDOUT:   %.loc13_29.1: ref %Pair.01a = splice_block %return.param {}
// CHECK:STDOUT:   %Copy.Op.call: init %Pair.01a to %.loc13_29.1 = call %bound_method(%Neither.ref) [concrete = constants.%Pair.val.765]
// CHECK:STDOUT:   return %Copy.Op.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- boundary.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Flag: type = class_type @Flag [concrete]
// CHECK:STDOUT:   %pattern_type.5bc: type = pattern_type %Flag [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Take.type: type = fn_type @Take [concrete]
// CHECK:STDOUT:   %Take: %Take.type = struct_value () [concrete]
// CHECK:STDOUT:   %flag.patt: %pattern_type.5bc = value_binding_pattern flag [concrete]
// CHECK:STDOUT:   %PassByValue.type: type = fn_type @PassByValue [concrete]
// CHECK:STDOUT:   %PassByValue: %PassByValue.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Flag.ref: type = name_ref Flag, %Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:   %flag: %Flag = wrapper_binding flag, @__global_init.%On.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %flag.patt: %pattern_type.5bc = value_binding_pattern flag [concrete = constants.%flag.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %PassByValue.decl: %PassByValue.type = fn_decl @PassByValue [concrete = constants.%PassByValue] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc16: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @PassByValue() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Take.ref: %Take.type = name_ref Take, file.%Take.decl [concrete = constants.%Take]
// CHECK:STDOUT:   %Flag.ref: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:   %Off.ref: %Flag = name_ref Off, @Flag.%Off
// CHECK:STDOUT:   %Take.call: init %i32 = call %Take.ref(%Off.ref)
// CHECK:STDOUT:   return %Take.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Flag.ref: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:   %On.ref: %Flag = name_ref On, @Flag.%On
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Opt.type: type = generic_class_type @Opt [concrete]
// CHECK:STDOUT:   %Opt.generic: %Opt.type = struct_value () [concrete]
// CHECK:STDOUT:   %Opt.ba7: type = class_type @Opt, @Opt(%T.67d) [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.026: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %.a2d: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic]
// CHECK:STDOUT:   %.3c3: Core.Form = init_form %Opt.ba7 [symbolic]
// CHECK:STDOUT:   %pattern_type.86b: type = pattern_type %Opt.ba7 [symbolic]
// CHECK:STDOUT:   %return.param_patt.e2a: %pattern_type.86b = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.ac3: %pattern_type.86b = return_slot_pattern %return.param_patt.e2a, %Opt.ba7 [symbolic]
// CHECK:STDOUT:   %require_complete.dd1: <witness> = require_complete_type %Opt.ba7 [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %Opt.val.a5e: %Opt.ba7 = struct_value (%int_1.233, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %Make.type: type = fn_type @Make [concrete]
// CHECK:STDOUT:   %Make: %Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.f2c: <witness> = lookup_impl_witness %Opt.ba7, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.facet.9cd: %Copy.type = facet_value %Opt.ba7, (%Copy.lookup_impl_witness.f2c) [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.f44: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.9cd) [symbolic]
// CHECK:STDOUT:   %.c8e: type = fn_type_with_self_type %Copy.WithSelf.Op.type.f44, %Copy.facet.9cd [symbolic]
// CHECK:STDOUT:   %impl.elem0.a1a: %.c8e = impl_witness_access %Copy.lookup_impl_witness.f2c, element0 [symbolic]
// CHECK:STDOUT:   %bound_method.50a: <bound method> = bound_method %Opt.val.a5e, %impl.elem0.a1a [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.84c: <specific function> = specific_impl_function %impl.elem0.a1a, @Copy.WithSelf.Op(%Copy.facet.9cd) [symbolic]
// CHECK:STDOUT:   %bound_method.8fd: <bound method> = bound_method %Opt.val.a5e, %specific_impl_fn.84c [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Opt.46d: type = class_type @Opt, @Opt(%i32) [concrete]
// CHECK:STDOUT:   %.bda: Core.Form = init_form %Opt.46d [concrete]
// CHECK:STDOUT:   %pattern_type.25d: type = pattern_type %Opt.46d [concrete]
// CHECK:STDOUT:   %return.param_patt.63c: %pattern_type.25d = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c82: %pattern_type.25d = return_slot_pattern %return.param_patt.63c, %Opt.46d [concrete]
// CHECK:STDOUT:   %UseConcrete.type: type = fn_type @UseConcrete [concrete]
// CHECK:STDOUT:   %UseConcrete: %UseConcrete.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.e99: type = struct_type {.discriminant: %u1, .payload: %.e8e} [concrete]
// CHECK:STDOUT:   %complete_type.378: <witness> = complete_type_witness %struct_type.discriminant.payload.e99 [concrete]
// CHECK:STDOUT:   %uninit.060: %.e8e = uninitialized_value [concrete]
// CHECK:STDOUT:   %Opt.val.b51: %Opt.46d = struct_value (%int_1.233, %uninit.060) [concrete]
// CHECK:STDOUT:   %Make.specific_fn: <specific function> = specific_function %Make, @Make(%i32) [concrete]
// CHECK:STDOUT:   %Copy.Op.type: type = fn_type @Copy.Op [concrete]
// CHECK:STDOUT:   %Copy.Op: %Copy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.14b: <witness> = custom_witness (%Copy.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.468: %Copy.type = facet_value %Opt.46d, (%custom_witness.14b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.6b2: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.468) [concrete]
// CHECK:STDOUT:   %.ea1: type = fn_type_with_self_type %Copy.WithSelf.Op.type.6b2, %Copy.facet.468 [concrete]
// CHECK:STDOUT:   %Copy.Op.bound: <bound method> = bound_method %Opt.val.b51, %Copy.Op [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Make.decl: %Make.type = fn_decl @Make [concrete = constants.%Make] {
// CHECK:STDOUT:     %T.patt.loc13_18.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc13_18.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:     %return.param_patt.loc13_34.1: @Make.%pattern_type (%pattern_type.86b) = out_param_pattern [symbolic = %return.param_patt.loc13_34.2 (constants.%return.param_patt.e2a)]
// CHECK:STDOUT:     %return.patt.loc13_26.1: @Make.%pattern_type (%pattern_type.86b) = return_slot_pattern %return.param_patt.loc13_34.1, %Opt.loc13_34.2 [symbolic = %return.patt.loc13_26.2 (constants.%return.patt.ac3)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Opt.ref.loc13_29: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:     %T.ref.loc13_33: type = name_ref T, %T.loc13_18.2 [symbolic = %T.loc13_18.1 (constants.%T.67d)]
// CHECK:STDOUT:     %Opt.loc13_34.2: type = class_type @Opt, @Opt(constants.%T.67d) [symbolic = %Opt.loc13_34.1 (constants.%Opt.ba7)]
// CHECK:STDOUT:     %.loc13_34.3: Core.Form = init_form %Opt.loc13_34.2 [symbolic = %.loc13_34.2 (constants.%.3c3)]
// CHECK:STDOUT:     %.loc13_20.1: type = splice_block %.loc13_20.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc13_20.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc13_18.2: type = symbolic_binding T, 0 [symbolic = %T.loc13_18.1 (constants.%T.67d)]
// CHECK:STDOUT:     %return.param: ref @Make.%Opt.loc13_34.1 (%Opt.ba7) = out_param call_param0
// CHECK:STDOUT:     %return: ref @Make.%Opt.loc13_34.1 (%Opt.ba7) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %UseConcrete.decl: %UseConcrete.type = fn_decl @UseConcrete [concrete = constants.%UseConcrete] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.25d = out_param_pattern [concrete = constants.%return.param_patt.63c]
// CHECK:STDOUT:     %return.patt: %pattern_type.25d = return_slot_pattern %return.param_patt, %Opt [concrete = constants.%return.patt.c82]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Opt.ref: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:     %i32.loc15_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Opt: type = class_type @Opt, @Opt(constants.%i32) [concrete = constants.%Opt.46d]
// CHECK:STDOUT:     %.loc15_28.2: Core.Form = init_form %Opt [concrete = constants.%.bda]
// CHECK:STDOUT:     %return.param: ref %Opt.46d = out_param call_param0
// CHECK:STDOUT:     %return: ref %Opt.46d = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Make(%T.loc13_18.2: type) {
// CHECK:STDOUT:   %T.patt.loc13_18.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc13_18.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc13_18.1: type = symbolic_binding T, 0 [symbolic = %T.loc13_18.1 (constants.%T.67d)]
// CHECK:STDOUT:   %Opt.loc13_34.1: type = class_type @Opt, @Opt(%T.loc13_18.1) [symbolic = %Opt.loc13_34.1 (constants.%Opt.ba7)]
// CHECK:STDOUT:   %.loc13_34.2: Core.Form = init_form %Opt.loc13_34.1 [symbolic = %.loc13_34.2 (constants.%.3c3)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Opt.loc13_34.1 [symbolic = %pattern_type (constants.%pattern_type.86b)]
// CHECK:STDOUT:   %return.param_patt.loc13_34.2: @Make.%pattern_type (%pattern_type.86b) = out_param_pattern [symbolic = %return.param_patt.loc13_34.2 (constants.%return.param_patt.e2a)]
// CHECK:STDOUT:   %return.patt.loc13_26.2: @Make.%pattern_type (%pattern_type.86b) = return_slot_pattern %return.param_patt.loc13_34.2, %Opt.loc13_34.1 [symbolic = %return.patt.loc13_26.2 (constants.%return.patt.ac3)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %Opt.loc13_34.1 [symbolic = %require_complete (constants.%require_complete.dd1)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc13_18.1) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc13_51.4: type = custom_layout_type {size=0, align=0, .Some@0: @Make.%tuple.type (%tuple.type.026)} [symbolic = %.loc13_51.4 (constants.%.a2d)]
// CHECK:STDOUT:   %uninit: @Make.%.loc13_51.4 (%.a2d) = uninitialized_value [symbolic = %uninit (constants.%uninit.37a)]
// CHECK:STDOUT:   %Opt.val: @Make.%Opt.loc13_34.1 (%Opt.ba7) = struct_value (constants.%int_1.233, %uninit) [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %Opt.loc13_34.1, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.f2c)]
// CHECK:STDOUT:   %Copy.facet.loc13_51.3: %Copy.type = facet_value %Opt.loc13_34.1, (%Copy.lookup_impl_witness) [symbolic = %Copy.facet.loc13_51.3 (constants.%Copy.facet.9cd)]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.loc13_51.3) [symbolic = %Copy.WithSelf.Op.type (constants.%Copy.WithSelf.Op.type.f44)]
// CHECK:STDOUT:   %.loc13_51.5: type = fn_type_with_self_type %Copy.WithSelf.Op.type, %Copy.facet.loc13_51.3 [symbolic = %.loc13_51.5 (constants.%.c8e)]
// CHECK:STDOUT:   %impl.elem0.loc13_51.2: @Make.%.loc13_51.5 (%.c8e) = impl_witness_access %Copy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc13_51.2 (constants.%impl.elem0.a1a)]
// CHECK:STDOUT:   %bound_method.loc13_51.3: <bound method> = bound_method %Opt.val, %impl.elem0.loc13_51.2 [symbolic = %bound_method.loc13_51.3 (constants.%bound_method.50a)]
// CHECK:STDOUT:   %specific_impl_fn.loc13_51.2: <specific function> = specific_impl_function %impl.elem0.loc13_51.2, @Copy.WithSelf.Op(%Copy.facet.loc13_51.3) [symbolic = %specific_impl_fn.loc13_51.2 (constants.%specific_impl_fn.84c)]
// CHECK:STDOUT:   %bound_method.loc13_51.4: <bound method> = bound_method %Opt.val, %specific_impl_fn.loc13_51.2 [symbolic = %bound_method.loc13_51.4 (constants.%bound_method.8fd)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn() -> out %return.param: @Make.%Opt.loc13_34.1 (%Opt.ba7) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Opt.ref.loc13_45: %Opt.type = name_ref Opt, file.%Opt.decl [concrete = constants.%Opt.generic]
// CHECK:STDOUT:     %T.ref.loc13_49: type = name_ref T, %T.loc13_18.2 [symbolic = %T.loc13_18.1 (constants.%T.67d)]
// CHECK:STDOUT:     %Opt.loc13_50: type = class_type @Opt, @Opt(constants.%T.67d) [symbolic = %Opt.loc13_34.1 (constants.%Opt.ba7)]
// CHECK:STDOUT:     %.loc13_51.1: @Make.%Opt.loc13_34.1 (%Opt.ba7) = specific_constant @Opt.%.loc6_1.13, @Opt(constants.%T.67d) [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:     %None.ref: @Make.%Opt.loc13_34.1 (%Opt.ba7) = name_ref None, %.loc13_51.1 [symbolic = %Opt.val (constants.%Opt.val.a5e)]
// CHECK:STDOUT:     %impl.elem0.loc13_51.1: @Make.%.loc13_51.5 (%.c8e) = impl_witness_access constants.%Copy.lookup_impl_witness.f2c, element0 [symbolic = %impl.elem0.loc13_51.2 (constants.%impl.elem0.a1a)]
// CHECK:STDOUT:     %bound_method.loc13_51.1: <bound method> = bound_method %None.ref, %impl.elem0.loc13_51.1 [symbolic = %bound_method.loc13_51.3 (constants.%bound_method.50a)]
// CHECK:STDOUT:     %Copy.facet.loc13_51.1: %Copy.type = facet_value constants.%Opt.ba7, (constants.%Copy.lookup_impl_witness.f2c) [symbolic = %Copy.facet.loc13_51.3 (constants.%Copy.facet.9cd)]
// CHECK:STDOUT:     %.loc13_51.2: %Copy.type = converted constants.%Opt.ba7, %Copy.facet.loc13_51.1 [symbolic = %Copy.facet.loc13_51.3 (constants.%Copy.facet.9cd)]
// CHECK:STDOUT:     %Copy.facet.loc13_51.2: %Copy.type = facet_value constants.%Opt.ba7, (constants.%Copy.lookup_impl_witness.f2c) [symbolic = %Copy.facet.loc13_51.3 (constants.%Copy.facet.9cd)]
// CHECK:STDOUT:     %.loc13_51.3: %Copy.type = converted constants.%Opt.ba7, %Copy.facet.loc13_51.2 [symbolic = %Copy.facet.loc13_51.3 (constants.%Copy.facet.9cd)]
// CHECK:STDOUT:     %specific_impl_fn.loc13_51.1: <specific function> = specific_impl_function %impl.elem0.loc13_51.1, @Copy.WithSelf.Op(constants.%Copy.facet.9cd) [symbolic = %specific_impl_fn.loc13_51.2 (constants.%specific_impl_fn.84c)]
// CHECK:STDOUT:     %bound_method.loc13_51.2: <bound method> = bound_method %None.ref, %specific_impl_fn.loc13_51.1 [symbolic = %bound_method.loc13_51.4 (constants.%bound_method.8fd)]
// CHECK:STDOUT:     %.loc13_34.1: ref @Make.%Opt.loc13_34.1 (%Opt.ba7) = splice_block %return.param {}
// CHECK:STDOUT:     %Copy.WithSelf.Op.call: init @Make.%Opt.loc13_34.1 (%Opt.ba7) to %.loc13_34.1 = call %bound_method.loc13_51.2(%None.ref)
// CHECK:STDOUT:     return %Copy.WithSelf.Op.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @UseConcrete() -> out %return.param: %Opt.46d {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Make.ref: %Make.type = name_ref Make, file.%Make.decl [concrete = constants.%Make]
// CHECK:STDOUT:   %i32.loc15_44: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Make.specific_fn: <specific function> = specific_function %Make.ref, @Make(constants.%i32) [concrete = constants.%Make.specific_fn]
// CHECK:STDOUT:   %.loc15_28.1: ref %Opt.46d = splice_block %return.param {}
// CHECK:STDOUT:   %Make.call: init %Opt.46d to %.loc15_28.1 = call %Make.specific_fn()
// CHECK:STDOUT:   return %Make.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Make(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc13_18.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc13_18.1 => constants.%T.67d
// CHECK:STDOUT:   %Opt.loc13_34.1 => constants.%Opt.ba7
// CHECK:STDOUT:   %.loc13_34.2 => constants.%.3c3
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.86b
// CHECK:STDOUT:   %return.param_patt.loc13_34.2 => constants.%return.param_patt.e2a
// CHECK:STDOUT:   %return.patt.loc13_26.2 => constants.%return.patt.ac3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Make(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc13_18.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc13_18.1 => constants.%i32
// CHECK:STDOUT:   %Opt.loc13_34.1 => constants.%Opt.46d
// CHECK:STDOUT:   %.loc13_34.2 => constants.%.bda
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.25d
// CHECK:STDOUT:   %return.param_patt.loc13_34.2 => constants.%return.param_patt.63c
// CHECK:STDOUT:   %return.patt.loc13_26.2 => constants.%return.patt.c82
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.378
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc13_51.4 => constants.%.e8e
// CHECK:STDOUT:   %uninit => constants.%uninit.060
// CHECK:STDOUT:   %Opt.val => constants.%Opt.val.b51
// CHECK:STDOUT:   %Copy.lookup_impl_witness => constants.%custom_witness.14b
// CHECK:STDOUT:   %Copy.facet.loc13_51.3 => constants.%Copy.facet.468
// CHECK:STDOUT:   %Copy.WithSelf.Op.type => constants.%Copy.WithSelf.Op.type.6b2
// CHECK:STDOUT:   %.loc13_51.5 => constants.%.ea1
// CHECK:STDOUT:   %impl.elem0.loc13_51.2 => constants.%Copy.Op
// CHECK:STDOUT:   %bound_method.loc13_51.3 => constants.%Copy.Op.bound
// CHECK:STDOUT:   %specific_impl_fn.loc13_51.2 => constants.%Copy.Op
// CHECK:STDOUT:   %bound_method.loc13_51.4 => constants.%Copy.Op.bound
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- shadowed_user_impl.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Flag: type = class_type @Flag [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %pattern_type.5bc: type = pattern_type %Flag [concrete]
// CHECK:STDOUT:   %.97d: Core.Form = init_form %Flag [concrete]
// CHECK:STDOUT:   %return.param_patt.f50: %pattern_type.5bc = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.aa2: %pattern_type.5bc = return_slot_pattern %return.param_patt.f50, %Flag [concrete]
// CHECK:STDOUT:   %Copy.Op.type: type = fn_type @Copy.Op [concrete]
// CHECK:STDOUT:   %Copy.Op: %Copy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.14b: <witness> = custom_witness (%Copy.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.fb5: %Copy.type = facet_value %Flag, (%custom_witness.14b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.46e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.fb5) [concrete]
// CHECK:STDOUT:   %.819: type = fn_type_with_self_type %Copy.WithSelf.Op.type.46e, %Copy.facet.fb5 [concrete]
// CHECK:STDOUT:   %f.param_patt: %pattern_type.5bc = value_param_pattern [concrete]
// CHECK:STDOUT:   %f.patt: %pattern_type.5bc = wrapper_binding_pattern f, %f.param_patt [concrete]
// CHECK:STDOUT:   %CopyIt.type: type = fn_type @CopyIt [concrete]
// CHECK:STDOUT:   %CopyIt: %CopyIt.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %CopyIt.decl: %CopyIt.type = fn_decl @CopyIt [concrete = constants.%CopyIt] {
// CHECK:STDOUT:     %f.param_patt: %pattern_type.5bc = value_param_pattern [concrete = constants.%f.param_patt]
// CHECK:STDOUT:     %f.patt: %pattern_type.5bc = wrapper_binding_pattern f, %f.param_patt [concrete = constants.%f.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5bc = out_param_pattern [concrete = constants.%return.param_patt.f50]
// CHECK:STDOUT:     %return.patt: %pattern_type.5bc = return_slot_pattern %return.param_patt, %Flag.ref.loc24_23 [concrete = constants.%return.patt.aa2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Flag.ref.loc24_23: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:     %.loc24_23.2: Core.Form = init_form %Flag.ref.loc24_23 [concrete = constants.%.97d]
// CHECK:STDOUT:     %f.param: %Flag = value_param call_param0
// CHECK:STDOUT:     %Flag.ref.loc24_14: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:     %f: %Flag = wrapper_binding f, %f.param
// CHECK:STDOUT:     %return.param: ref %Flag = out_param call_param1
// CHECK:STDOUT:     %return: ref %Flag = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @CopyIt(%f.param: %Flag) -> out %return.param: %Flag {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %f.ref: %Flag = name_ref f, %f
// CHECK:STDOUT:   %impl.elem0: %.819 = impl_witness_access constants.%custom_witness.14b, element0 [concrete = constants.%Copy.Op]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %f.ref, %impl.elem0
// CHECK:STDOUT:   %.loc24_23.1: ref %Flag = splice_block %return.param {}
// CHECK:STDOUT:   %Copy.Op.call: init %Flag to %.loc24_23.1 = call %bound_method(%f.ref)
// CHECK:STDOUT:   return %Copy.Op.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
