// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/single_alternative_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/single_alternative_choice.carbon

// A single-alternative choice has an empty-tuple discriminant — no
// discriminant bits (handle_choice.cpp) — so its one alternative arm has
// nothing to test and is always taken: a constant-true condition, the same
// shape as an irrefutable binding arm, with the payload extraction still
// real (W-068; recorded at W5-S1, kept out of S2e's sanctioned scope, and
// admitted here at the scrutinee gate).

// --- constant_alternative.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Always {
  TheOnlyOption
}

// The single unguarded arm covers the only alternative, so the match is
// exhaustive and needs no `default` arm (SF-7 through the same coverage
// analysis as multi-alternative choices).
fn F(a: Always) -> i32 {
  match (a) {
    case .TheOnlyOption => { return 0; }
  }
  return -1;
}

// Construction was never gated: the alternative constant carries the
// empty-tuple discriminant value.
fn Construct() -> i32 {
  let a: Always = Always.TheOnlyOption;
  return F(a);
}
//@dump-sem-ir-end

// --- payload_alternative.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice OneShot {
  Only(x: i32)
}

// The arm's condition is a constant true — there is no discriminant to
// compare — but the payload extraction stays real: the bind pass reads the
// payload tuple through the payload region field of the choice's
// `{.discriminant: (), .payload: ...}` representation and initializes the
// binding from its element.
fn Get(o: OneShot) -> i32 {
  match (o) {
    case .Only(v: i32) => { return v; }
  }
  return -1;
}

fn Make(x: i32) -> OneShot {
  return OneShot.Only(x);
}
//@dump-sem-ir-end

// --- default_only.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Always {
  TheOnlyOption
}

// A `default`-only match over a single-alternative choice: the scrutinee is
// admitted independently of which arms cover what, and `default` covers
// everything as usual.
fn F(a: Always) -> i32 {
  match (a) {
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- generic_specific_payload.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Wrap(T: type) {
  Some(x: T)
}

// Composition with the W5-S3 generic-choice lifts: a specific of a
// single-alternative generic payload choice is admitted by the same
// empty-tuple-discriminant gate, and the payload destructuring resolves
// through the specific's substituted representation (S3b/S3c machinery,
// alternative-count-independent).
fn Get(w: Wrap(i32)) -> i32 {
  match (w) {
    case .Some(v: i32) => { return v; }
  }
  return -1;
}

fn Make(x: i32) -> Wrap(i32) {
  return Wrap(i32).Some(x);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- constant_alternative.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Always: type = class_type @Always [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %empty_tuple.type} [concrete]
// CHECK:STDOUT:   %complete_type.a0b: <witness> = complete_type_witness %struct_type.discriminant [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%empty_tuple) [concrete]
// CHECK:STDOUT:   %Always.val: %Always = struct_value (%empty_tuple) [concrete]
// CHECK:STDOUT:   %.302: ref %Always = temporary invalid, %Always.val [concrete]
// CHECK:STDOUT:   %pattern_type.29f: type = pattern_type %Always [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.29f = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt.700: %pattern_type.29f = at_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %Construct.type: type = fn_type @Construct [concrete]
// CHECK:STDOUT:   %Construct: %Construct.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt.5c7: %pattern_type.29f = value_binding_pattern a [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Always.decl: type = class_decl @Always [concrete = constants.%Always] {} {}
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.29f = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.29f = at_binding_pattern a, %a.param_patt [concrete = constants.%a.patt.700]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %a.param: %Always = value_param call_param0
// CHECK:STDOUT:     %Always.ref: type = name_ref Always, file.%Always.decl [concrete = constants.%Always]
// CHECK:STDOUT:     %a: %Always = wrapper_binding a, %a.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Construct.decl: %Construct.type = fn_decl @Construct [concrete = constants.%Construct] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc20: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Always {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.a0b]
// CHECK:STDOUT:   %.loc6_1.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.2: %empty_tuple.type = converted %.loc6_1.1, %empty_tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.3: %struct_type.discriminant = struct_literal (%.loc6_1.2) [concrete = constants.%struct]
// CHECK:STDOUT:   %.loc6_1.4: ref %Always = temporary_storage
// CHECK:STDOUT:   %.loc6_1.5: ref %empty_tuple.type = class_element_access %.loc6_1.4, element0
// CHECK:STDOUT:   %.loc6_1.6: init %empty_tuple.type to %.loc6_1.5 = tuple_init () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.7: init %empty_tuple.type = converted %.loc6_1.2, %.loc6_1.6 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.8: init %empty_tuple.type to %.loc6_1.5 = in_place_init %.loc6_1.7 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.9: init %Always to %.loc6_1.4 = class_init (%.loc6_1.8) [concrete = constants.%Always.val]
// CHECK:STDOUT:   %.loc6_1.10: init %Always = converted %.loc6_1.3, %.loc6_1.9 [concrete = constants.%Always.val]
// CHECK:STDOUT:   %.loc6_1.11: ref %Always = temporary %.loc6_1.4, %.loc6_1.10 [concrete = constants.%.302]
// CHECK:STDOUT:   %.loc6_1.12: %Always = acquire_value %.loc6_1.11 [concrete = constants.%Always.val]
// CHECK:STDOUT:   %TheOnlyOption: %Always = wrapper_binding TheOnlyOption, %.loc6_1.12
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Always
// CHECK:STDOUT:   .TheOnlyOption = %TheOnlyOption
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%a.param: %Always) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Always = name_ref a, %a
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.29f = expr_pattern %TheOnlyOption.ref in [concrete] {
// CHECK:STDOUT:       %TheOnlyOption.ref: %Always = name_ref TheOnlyOption, @Always.%TheOnlyOption
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %TheOnlyOption.ref: %Always = name_ref TheOnlyOption, @Always.%TheOnlyOption
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_38.1: <bound method> = bound_method %int_0, %impl.elem0.loc13 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc13: <specific function> = specific_function %impl.elem0.loc13, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_38.2: <bound method> = bound_method %int_0, %specific_fn.loc13 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13: init %i32 = call %bound_method.loc13_38.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc13: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc15_10: <bound method> = bound_method %int_1, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc15_10(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc15: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc15_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc15 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc15: <specific function> = specific_function %impl.elem0.loc15, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc15 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc15_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc15_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc15_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %i32 = call %bound_method.loc15_12.2(%.loc15_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc15_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc15_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Construct() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Always.ref.loc21_19: type = name_ref Always, file.%Always.decl [concrete = constants.%Always]
// CHECK:STDOUT:   %TheOnlyOption.ref: %Always = name_ref TheOnlyOption, @Always.%TheOnlyOption
// CHECK:STDOUT:   %Always.ref.loc21_10: type = name_ref Always, file.%Always.decl [concrete = constants.%Always]
// CHECK:STDOUT:   %a: %Always = wrapper_binding a, %TheOnlyOption.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.29f = value_binding_pattern a [concrete = constants.%a.patt.5c7]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F.ref: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %a.ref: %Always = name_ref a, %a
// CHECK:STDOUT:   %F.call: init %i32 = call %F.ref(%a.ref)
// CHECK:STDOUT:   return %F.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- payload_alternative.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %OneShot: type = class_type @OneShot [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e0f: type = custom_layout_type {size=4, align=4, .Only@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.334: type = struct_type {.discriminant: %empty_tuple.type, .payload: %.e0f} [concrete]
// CHECK:STDOUT:   %complete_type.9aa: <witness> = complete_type_witness %struct_type.discriminant.payload.334 [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.9bb: Core.Form = init_form %OneShot [concrete]
// CHECK:STDOUT:   %pattern_type.bc6: type = pattern_type %OneShot [concrete]
// CHECK:STDOUT:   %return.param_patt.9f6: %pattern_type.bc6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.941: %pattern_type.bc6 = return_slot_pattern %return.param_patt.9f6, %OneShot [concrete]
// CHECK:STDOUT:   %OneShot.Only.type: type = fn_type @OneShot.Only [concrete]
// CHECK:STDOUT:   %OneShot.Only: %OneShot.Only.type = struct_value () [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.bc6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.bc6 = at_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Get.type: type = fn_type @Get [concrete]
// CHECK:STDOUT:   %Get: %Get.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.13b: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %Make.type: type = fn_type @Make [concrete]
// CHECK:STDOUT:   %Make: %Make.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %OneShot.Only.decl: %OneShot.Only.type = fn_decl @OneShot.Only [concrete = constants.%OneShot.Only] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.bc6 = out_param_pattern [concrete = constants.%return.param_patt.9f6]
// CHECK:STDOUT:     %return.patt: %pattern_type.bc6 = return_slot_pattern %return.param_patt, constants.%OneShot [concrete = constants.%return.patt.941]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_16.9: Core.Form = init_form constants.%OneShot [concrete = constants.%.9bb]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %OneShot = out_param call_param1
// CHECK:STDOUT:     %return: ref %OneShot = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %OneShot.decl: type = class_decl @OneShot [concrete = constants.%OneShot] {} {}
// CHECK:STDOUT:   %Get.decl: %Get.type = fn_decl @Get [concrete = constants.%Get] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.bc6 = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.bc6 = at_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc13 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13: Core.Form = init_form %i32.loc13 [concrete = constants.%.795f]
// CHECK:STDOUT:     %o.param: %OneShot = value_param call_param0
// CHECK:STDOUT:     %OneShot.ref: type = name_ref OneShot, file.%OneShot.decl [concrete = constants.%OneShot]
// CHECK:STDOUT:     %o: %OneShot = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Make.decl: %Make.type = fn_decl @Make [concrete = constants.%Make] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.bc6 = out_param_pattern [concrete = constants.%return.param_patt.9f6]
// CHECK:STDOUT:     %return.patt: %pattern_type.bc6 = return_slot_pattern %return.param_patt, %OneShot.ref.loc20 [concrete = constants.%return.patt.941]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %OneShot.ref.loc20: type = name_ref OneShot, file.%OneShot.decl [concrete = constants.%OneShot]
// CHECK:STDOUT:     %.loc20_20.2: Core.Form = init_form %OneShot.ref.loc20 [concrete = constants.%.9bb]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %OneShot = out_param call_param1
// CHECK:STDOUT:     %return: ref %OneShot = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @OneShot {
// CHECK:STDOUT:   %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:   %.loc6: type = custom_layout_type {size=4, align=4, .Only@0: %tuple.type.a8a} [concrete = constants.%.e0f]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.334 [concrete = constants.%complete_type.9aa]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%OneShot
// CHECK:STDOUT:   .Only = generated.%OneShot.Only.decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @OneShot.Only(%_.param: %i32) -> out %return.param: %OneShot {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc4_16.1: ref %empty_tuple.type = class_element_access %return.param, element0
// CHECK:STDOUT:   %.loc6_1.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.2: init %empty_tuple.type to %.loc4_16.1 = tuple_init () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc4_16.2: init %empty_tuple.type = converted %.loc6_1.1, %.loc6_1.2 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc4_16.3: init %empty_tuple.type to %.loc4_16.1 = in_place_init %.loc4_16.2 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc4_16.4: ref %.e0f = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc4_16.5: ref %tuple.type.a8a = class_element_access %.loc4_16.4, element0
// CHECK:STDOUT:   %.loc6_1.3: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc4_16.1: <bound method> = bound_method %_.param, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc4_16.2: <bound method> = bound_method %_.param, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc4_16.2(%_.param)
// CHECK:STDOUT:   %.loc6_1.4: init %tuple.type.a8a to %.loc4_16.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc4_16.6: init %tuple.type.a8a = converted %.loc6_1.3, %.loc6_1.4
// CHECK:STDOUT:   %.loc4_16.7: init %tuple.type.a8a to %.loc4_16.5 = in_place_init %.loc4_16.6
// CHECK:STDOUT:   %.loc4_16.8: init %OneShot to %return.param = class_init (%.loc4_16.3, %.loc4_16.7)
// CHECK:STDOUT:   return %.loc4_16.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Get(%o.param: %OneShot) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.ref: %OneShot = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc15_17: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc15_24.1: ref %.e0f = class_element_access %o.ref, element1
// CHECK:STDOUT:   %.loc15_24.2: ref %tuple.type.a8a = class_element_access %.loc15_24.1, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc15_24.2, element0
// CHECK:STDOUT:   %.loc15_24.3: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc15_24.3
// CHECK:STDOUT:   %v.ref: %i32 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc15: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc15_36.1: <bound method> = bound_method %v.ref, %impl.elem0.loc15
// CHECK:STDOUT:   %specific_fn.loc15: <specific function> = specific_function %impl.elem0.loc15, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_36.2: <bound method> = bound_method %v.ref, %specific_fn.loc15
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc15_36.2(%v.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc17_10: <bound method> = bound_method %int_1, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc17_10(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc17_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc17 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %.loc17_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc17_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc17_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc17_12.2(%.loc17_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc17_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc17_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Make(%x.param: %i32) -> out %return.param: %OneShot {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %OneShot.ref.loc21: type = name_ref OneShot, file.%OneShot.decl [concrete = constants.%OneShot]
// CHECK:STDOUT:   %Only.ref: %OneShot.Only.type = name_ref Only, generated.%OneShot.Only.decl [concrete = constants.%OneShot.Only]
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %.loc20_20.1: ref %OneShot = splice_block %return.param {}
// CHECK:STDOUT:   %OneShot.Only.call: init %OneShot to %.loc20_20.1 = call %Only.ref(%x.ref)
// CHECK:STDOUT:   return %OneShot.Only.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- default_only.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Always: type = class_type @Always [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %empty_tuple.type} [concrete]
// CHECK:STDOUT:   %complete_type.a0b: <witness> = complete_type_witness %struct_type.discriminant [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%empty_tuple) [concrete]
// CHECK:STDOUT:   %Always.val: %Always = struct_value (%empty_tuple) [concrete]
// CHECK:STDOUT:   %.302: ref %Always = temporary invalid, %Always.val [concrete]
// CHECK:STDOUT:   %pattern_type.29f: type = pattern_type %Always [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.29f = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.29f = at_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Always.decl: type = class_decl @Always [concrete = constants.%Always] {} {}
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.29f = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.29f = at_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %a.param: %Always = value_param call_param0
// CHECK:STDOUT:     %Always.ref: type = name_ref Always, file.%Always.decl [concrete = constants.%Always]
// CHECK:STDOUT:     %a: %Always = wrapper_binding a, %a.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Always {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.a0b]
// CHECK:STDOUT:   %.loc6_1.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.2: %empty_tuple.type = converted %.loc6_1.1, %empty_tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.3: %struct_type.discriminant = struct_literal (%.loc6_1.2) [concrete = constants.%struct]
// CHECK:STDOUT:   %.loc6_1.4: ref %Always = temporary_storage
// CHECK:STDOUT:   %.loc6_1.5: ref %empty_tuple.type = class_element_access %.loc6_1.4, element0
// CHECK:STDOUT:   %.loc6_1.6: init %empty_tuple.type to %.loc6_1.5 = tuple_init () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.7: init %empty_tuple.type = converted %.loc6_1.2, %.loc6_1.6 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.8: init %empty_tuple.type to %.loc6_1.5 = in_place_init %.loc6_1.7 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc6_1.9: init %Always to %.loc6_1.4 = class_init (%.loc6_1.8) [concrete = constants.%Always.val]
// CHECK:STDOUT:   %.loc6_1.10: init %Always = converted %.loc6_1.3, %.loc6_1.9 [concrete = constants.%Always.val]
// CHECK:STDOUT:   %.loc6_1.11: ref %Always = temporary %.loc6_1.4, %.loc6_1.10 [concrete = constants.%.302]
// CHECK:STDOUT:   %.loc6_1.12: %Always = acquire_value %.loc6_1.11 [concrete = constants.%Always.val]
// CHECK:STDOUT:   %TheOnlyOption: %Always = wrapper_binding TheOnlyOption, %.loc6_1.12
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Always
// CHECK:STDOUT:   .TheOnlyOption = %TheOnlyOption
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%a.param: %Always) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %Always = name_ref a, %a
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_26.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_26.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc13_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc13: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic_specific_payload.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98f: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.d47: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Wrap.type: type = generic_class_type @Wrap [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Wrap.generic: %Wrap.type = struct_value () [concrete]
// CHECK:STDOUT:   %Wrap.8a2: type = class_type @Wrap, @Wrap(%T.67d) [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.800: %pattern_type.51d1c4.1 = at_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %tuple.type.026: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %.a2d: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic]
// CHECK:STDOUT:   %struct_type.discriminant.payload.55f: type = struct_type {.discriminant: %empty_tuple.type, .payload: %.a2d} [symbolic]
// CHECK:STDOUT:   %complete_type.f9b: <witness> = complete_type_witness %struct_type.discriminant.payload.55f [symbolic]
// CHECK:STDOUT:   %_.param_patt.339: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %_.patt.fd3: %pattern_type.51d1c4.1 = at_binding_pattern _, %_.param_patt.339 [symbolic]
// CHECK:STDOUT:   %.f64: Core.Form = init_form %Wrap.8a2 [symbolic]
// CHECK:STDOUT:   %pattern_type.e27: type = pattern_type %Wrap.8a2 [symbolic]
// CHECK:STDOUT:   %return.param_patt.3dc: %pattern_type.e27 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.e36: %pattern_type.e27 = return_slot_pattern %return.param_patt.3dc, %Wrap.8a2 [symbolic]
// CHECK:STDOUT:   %Wrap.Some.type.8ef: type = fn_type @Wrap.Some, @Wrap(%T.67d) [symbolic]
// CHECK:STDOUT:   %Wrap.Some.65d: %Wrap.Some.type.8ef = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.78a: <witness> = require_complete_type %Wrap.8a2 [symbolic]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %Wrap.val.25e: %Wrap.8a2 = struct_value (%empty_tuple, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Wrap.aab: type = class_type @Wrap, @Wrap(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.f1a: type = pattern_type %Wrap.aab [concrete]
// CHECK:STDOUT:   %w.param_patt: %pattern_type.f1a = value_param_pattern [concrete]
// CHECK:STDOUT:   %w.patt: %pattern_type.f1a = at_binding_pattern w, %w.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Get.type: type = fn_type @Get [concrete]
// CHECK:STDOUT:   %Get: %Get.type = struct_value () [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.fbe: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.5c2: type = struct_type {.discriminant: %empty_tuple.type, .payload: %.e8e} [concrete]
// CHECK:STDOUT:   %complete_type.a8a: <witness> = complete_type_witness %struct_type.discriminant.payload.5c2 [concrete]
// CHECK:STDOUT:   %Wrap.Some.type.db4: type = fn_type @Wrap.Some, @Wrap(%i32) [concrete]
// CHECK:STDOUT:   %Wrap.Some.fe1: %Wrap.Some.type.db4 = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.13b: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %.8c4: Core.Form = init_form %Wrap.aab [concrete]
// CHECK:STDOUT:   %return.param_patt.93a: %pattern_type.f1a = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.3f3: %pattern_type.f1a = return_slot_pattern %return.param_patt.93a, %Wrap.aab [concrete]
// CHECK:STDOUT:   %Make.type: type = fn_type @Make [concrete]
// CHECK:STDOUT:   %Make: %Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %_.param_patt.fb2: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.b75: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.fb2 [concrete]
// CHECK:STDOUT:   %Wrap.Some.specific_fn: <specific function> = specific_function %Wrap.Some.fe1, @Wrap.Some(%i32) [concrete]
// CHECK:STDOUT:   %uninit.060: %.e8e = uninitialized_value [concrete]
// CHECK:STDOUT:   %Wrap.val.09b: %Wrap.aab = struct_value (%empty_tuple, %uninit.060) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Wrap.Some.decl: @Wrap.%Wrap.Some.type (%Wrap.Some.type.8ef) = fn_decl @Wrap.Some [symbolic = @Wrap.%Wrap.Some (constants.%Wrap.Some.65d)] {
// CHECK:STDOUT:     %_.param_patt.loc4_22.1: @Wrap.Some.%pattern_type.loc4_22.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc4_22.2 (constants.%_.param_patt.339)]
// CHECK:STDOUT:     %_.patt.loc4_22.1: @Wrap.Some.%pattern_type.loc4_22.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc4_22.1 [symbolic = %_.patt.loc4_22.2 (constants.%_.patt.fd3)]
// CHECK:STDOUT:     %return.param_patt.loc4_22.1: @Wrap.Some.%pattern_type.loc4_22.2 (%pattern_type.e27) = out_param_pattern [symbolic = %return.param_patt.loc4_22.2 (constants.%return.param_patt.3dc)]
// CHECK:STDOUT:     %return.patt.loc4_22.1: @Wrap.Some.%pattern_type.loc4_22.2 (%pattern_type.e27) = return_slot_pattern %return.param_patt.loc4_22.1, %Wrap.loc4_22.2 [symbolic = %return.patt.loc4_22.2 (constants.%return.patt.e36)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Wrap.loc4_22.2: type = class_type @Wrap, @Wrap(constants.%T.67d) [symbolic = %Wrap.loc4_22.1 (constants.%Wrap.8a2)]
// CHECK:STDOUT:     %.loc4_22.11: Core.Form = init_form %Wrap.loc4_22.2 [symbolic = %.loc4_22.9 (constants.%.f64)]
// CHECK:STDOUT:     %_.param: @Wrap.Some.%T (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %_: @Wrap.Some.%T (%T.67d) = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref @Wrap.Some.%Wrap.loc4_22.1 (%Wrap.8a2) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Wrap.Some.%Wrap.loc4_22.1 (%Wrap.8a2) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Wrap.decl: %Wrap.type = class_decl @Wrap [concrete = constants.%Wrap.generic] {
// CHECK:STDOUT:     %T.patt.loc4_14.1: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_14.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_16.1: type = splice_block %.loc4_16.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_16.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_14.2: type = symbolic_binding T, 0 [symbolic = %T.loc4_14.1 (constants.%T.67d)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Get.decl: %Get.type = fn_decl @Get [concrete = constants.%Get] {
// CHECK:STDOUT:     %w.param_patt: %pattern_type.f1a = value_param_pattern [concrete = constants.%w.param_patt]
// CHECK:STDOUT:     %w.patt: %pattern_type.f1a = at_binding_pattern w, %w.param_patt [concrete = constants.%w.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc13_25 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc13_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13_25: Core.Form = init_form %i32.loc13_25 [concrete = constants.%.795f]
// CHECK:STDOUT:     %w.param: %Wrap.aab = value_param call_param0
// CHECK:STDOUT:     %.loc13_19: type = splice_block %Wrap [concrete = constants.%Wrap.aab] {
// CHECK:STDOUT:       %Wrap.ref: %Wrap.type = name_ref Wrap, file.%Wrap.decl [concrete = constants.%Wrap.generic]
// CHECK:STDOUT:       %i32.loc13_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Wrap: type = class_type @Wrap, @Wrap(constants.%i32) [concrete = constants.%Wrap.aab]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %w: %Wrap.aab = wrapper_binding w, %w.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Make.decl: %Make.type = fn_decl @Make [concrete = constants.%Make] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt.cee]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt.fbe]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f1a = out_param_pattern [concrete = constants.%return.param_patt.93a]
// CHECK:STDOUT:     %return.patt: %pattern_type.f1a = return_slot_pattern %return.param_patt, %Wrap.loc20 [concrete = constants.%return.patt.3f3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Wrap.ref.loc20: %Wrap.type = name_ref Wrap, file.%Wrap.decl [concrete = constants.%Wrap.generic]
// CHECK:STDOUT:     %i32.loc20_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Wrap.loc20: type = class_type @Wrap, @Wrap(constants.%i32) [concrete = constants.%Wrap.aab]
// CHECK:STDOUT:     %.loc20_28.2: Core.Form = init_form %Wrap.loc20 [concrete = constants.%.8c4]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc20_12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %Wrap.aab = out_param call_param1
// CHECK:STDOUT:     %return: ref %Wrap.aab = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic class @Wrap(%T.loc4_14.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_14.2: %pattern_type.98f = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_14.2 (constants.%T.patt.d47)]
// CHECK:STDOUT:   %T.loc4_14.1: type = symbolic_binding T, 0 [symbolic = %T.loc4_14.1 (constants.%T.67d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_14.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt: @Wrap.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %x.param_patt (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt: @Wrap.%pattern_type (%pattern_type.51d1c4.1) = at_binding_pattern x, %x.param_patt [symbolic = %x.patt (constants.%x.patt.800)]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc4_14.1 [symbolic = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc4_14.1) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc6_1.2: type = custom_layout_type {size=0, align=0, .Some@0: @Wrap.%tuple.type (%tuple.type.026)} [symbolic = %.loc6_1.2 (constants.%.a2d)]
// CHECK:STDOUT:   %struct_type.discriminant.payload: type = struct_type {.discriminant: %empty_tuple.type, .payload: @Wrap.%.loc6_1.2 (%.a2d)} [symbolic = %struct_type.discriminant.payload (constants.%struct_type.discriminant.payload.55f)]
// CHECK:STDOUT:   %complete_type.loc6_1.2: <witness> = complete_type_witness %struct_type.discriminant.payload [symbolic = %complete_type.loc6_1.2 (constants.%complete_type.f9b)]
// CHECK:STDOUT:   %Wrap.Some.type: type = fn_type @Wrap.Some, @Wrap(%T.loc4_14.1) [symbolic = %Wrap.Some.type (constants.%Wrap.Some.type.8ef)]
// CHECK:STDOUT:   %Wrap.Some: @Wrap.%Wrap.Some.type (%Wrap.Some.type.8ef) = struct_value () [symbolic = %Wrap.Some (constants.%Wrap.Some.65d)]
// CHECK:STDOUT:
// CHECK:STDOUT:   class {
// CHECK:STDOUT:     %x.param: @Wrap.%T.loc4_14.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc4_14.2 [symbolic = %T.loc4_14.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @Wrap.%T.loc4_14.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %.loc6_1.1: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic = %.loc6_1.2 (constants.%.a2d)]
// CHECK:STDOUT:     %complete_type.loc6_1.1: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.55f [symbolic = %complete_type.loc6_1.2 (constants.%complete_type.f9b)]
// CHECK:STDOUT:     complete_type_witness = %complete_type.loc6_1.1
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = constants.%Wrap.8a2
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Some = generated.%Wrap.Some.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Wrap.Some(@Wrap.%T.loc4_14.2: type) {
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic = %T (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc4_22.1: type = pattern_type %T [symbolic = %pattern_type.loc4_22.1 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %_.param_patt.loc4_22.2: @Wrap.Some.%pattern_type.loc4_22.1 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %_.param_patt.loc4_22.2 (constants.%_.param_patt.339)]
// CHECK:STDOUT:   %_.patt.loc4_22.2: @Wrap.Some.%pattern_type.loc4_22.1 (%pattern_type.51d1c4.1) = at_binding_pattern _, %_.param_patt.loc4_22.2 [symbolic = %_.patt.loc4_22.2 (constants.%_.patt.fd3)]
// CHECK:STDOUT:   %Wrap.loc4_22.1: type = class_type @Wrap, @Wrap(%T) [symbolic = %Wrap.loc4_22.1 (constants.%Wrap.8a2)]
// CHECK:STDOUT:   %.loc4_22.9: Core.Form = init_form %Wrap.loc4_22.1 [symbolic = %.loc4_22.9 (constants.%.f64)]
// CHECK:STDOUT:   %pattern_type.loc4_22.2: type = pattern_type %Wrap.loc4_22.1 [symbolic = %pattern_type.loc4_22.2 (constants.%pattern_type.e27)]
// CHECK:STDOUT:   %return.param_patt.loc4_22.2: @Wrap.Some.%pattern_type.loc4_22.2 (%pattern_type.e27) = out_param_pattern [symbolic = %return.param_patt.loc4_22.2 (constants.%return.param_patt.3dc)]
// CHECK:STDOUT:   %return.patt.loc4_22.2: @Wrap.Some.%pattern_type.loc4_22.2 (%pattern_type.e27) = return_slot_pattern %return.param_patt.loc4_22.2, %Wrap.loc4_22.1 [symbolic = %return.patt.loc4_22.2 (constants.%return.patt.e36)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_22.1: <witness> = require_complete_type %T [symbolic = %require_complete.loc4_22.1 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc4_22.2: <witness> = require_complete_type %Wrap.loc4_22.1 [symbolic = %require_complete.loc4_22.2 (constants.%require_complete.78a)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T) [symbolic = %tuple.type (constants.%tuple.type.026)]
// CHECK:STDOUT:   %.loc4_22.10: type = custom_layout_type {size=0, align=0, .Some@0: @Wrap.Some.%tuple.type (%tuple.type.026)} [symbolic = %.loc4_22.10 (constants.%.a2d)]
// CHECK:STDOUT:   %uninit.loc4_22.2: @Wrap.Some.%.loc4_22.10 (%.a2d) = uninitialized_value [symbolic = %uninit.loc4_22.2 (constants.%uninit.37a)]
// CHECK:STDOUT:   %Wrap.val: @Wrap.Some.%Wrap.loc4_22.1 (%Wrap.8a2) = struct_value (constants.%empty_tuple, %uninit.loc4_22.2) [symbolic = %Wrap.val (constants.%Wrap.val.25e)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%_.param: @Wrap.Some.%T (%T.67d)) -> out %return.param: @Wrap.Some.%Wrap.loc4_22.1 (%Wrap.8a2) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %.loc4_22.1: ref %empty_tuple.type = class_element_access %return.param, element0
// CHECK:STDOUT:     %.loc6_1.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc6_1.2: init %empty_tuple.type to %.loc4_22.1 = tuple_init () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc4_22.2: init %empty_tuple.type = converted %.loc6_1.1, %.loc6_1.2 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc4_22.3: init %empty_tuple.type to %.loc4_22.1 = in_place_init %.loc4_22.2 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc4_22.4: ref @Wrap.Some.%.loc4_22.10 (%.a2d) = class_element_access %return.param, element1
// CHECK:STDOUT:     %.loc4_22.5: ref @Wrap.Some.%tuple.type (%tuple.type.026) = class_element_access %.loc4_22.4, element0
// CHECK:STDOUT:     %.loc6_1.3: init @Wrap.Some.%tuple.type (%tuple.type.026) to %.loc4_22.5 = tuple_init (%_.param)
// CHECK:STDOUT:     %uninit.loc4_22.1: @Wrap.Some.%.loc4_22.10 (%.a2d) = uninitialized_value [symbolic = %uninit.loc4_22.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc4_22.6: init @Wrap.Some.%.loc4_22.10 (%.a2d) to %.loc4_22.4 = in_place_init %uninit.loc4_22.1 [symbolic = %uninit.loc4_22.2 (constants.%uninit.37a)]
// CHECK:STDOUT:     %.loc4_22.7: init @Wrap.Some.%Wrap.loc4_22.1 (%Wrap.8a2) to %return.param = class_init (%.loc4_22.3, %.loc4_22.6) [symbolic = %Wrap.val (constants.%Wrap.val.25e)]
// CHECK:STDOUT:     %.loc4_22.8: init @Wrap.Some.%Wrap.loc4_22.1 (%Wrap.8a2) = update_init %.loc4_22.7, %.loc6_1.3
// CHECK:STDOUT:     %tuple.elem0: ref @Wrap.Some.%T (%T.67d) = tuple_access %.loc4_22.5, element0
// CHECK:STDOUT:     %.loc6_1.4: init @Wrap.Some.%T (%T.67d) to %tuple.elem0 = in_place_init %_.param
// CHECK:STDOUT:     return %.loc4_22.8 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Get(%w.param: %Wrap.aab) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %w.ref: %Wrap.aab = name_ref w, %w
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc15_17: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %.loc15_24.1: ref %.e8e = class_element_access %w.ref, element1
// CHECK:STDOUT:   %.loc15_24.2: ref %tuple.type.a8a = class_element_access %.loc15_24.1, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc15_24.2, element0
// CHECK:STDOUT:   %.loc15_24.3: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc15_24.3
// CHECK:STDOUT:   %v.ref: %i32 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc15: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc15_36.1: <bound method> = bound_method %v.ref, %impl.elem0.loc15
// CHECK:STDOUT:   %specific_fn.loc15: <specific function> = specific_function %impl.elem0.loc15, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_36.2: <bound method> = bound_method %v.ref, %specific_fn.loc15
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc15_36.2(%v.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc17_10: <bound method> = bound_method %int_1, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc17_10(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc17_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc17 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %.loc17_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc17_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc17_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc17_12.2(%.loc17_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc17_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc17_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Make(%x.param: %i32) -> out %return.param: %Wrap.aab {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Wrap.ref.loc21: %Wrap.type = name_ref Wrap, file.%Wrap.decl [concrete = constants.%Wrap.generic]
// CHECK:STDOUT:   %i32.loc21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Wrap.loc21: type = class_type @Wrap, @Wrap(constants.%i32) [concrete = constants.%Wrap.aab]
// CHECK:STDOUT:   %.loc21: %Wrap.Some.type.db4 = specific_constant generated.%Wrap.Some.decl, @Wrap(constants.%i32) [concrete = constants.%Wrap.Some.fe1]
// CHECK:STDOUT:   %Some.ref: %Wrap.Some.type.db4 = name_ref Some, %.loc21 [concrete = constants.%Wrap.Some.fe1]
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %Wrap.Some.specific_fn: <specific function> = specific_function %Some.ref, @Wrap.Some(constants.%i32) [concrete = constants.%Wrap.Some.specific_fn]
// CHECK:STDOUT:   %.loc20_28.1: ref %Wrap.aab = splice_block %return.param {}
// CHECK:STDOUT:   %Wrap.Some.call: init %Wrap.aab to %.loc20_28.1 = call %Wrap.Some.specific_fn(%x.ref)
// CHECK:STDOUT:   return %Wrap.Some.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Wrap(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc4_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_14.1 => constants.%T.67d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Wrap.Some(constants.%T.67d) {
// CHECK:STDOUT:   %T => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc4_22.1 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %_.param_patt.loc4_22.2 => constants.%_.param_patt.339
// CHECK:STDOUT:   %_.patt.loc4_22.2 => constants.%_.patt.fd3
// CHECK:STDOUT:   %Wrap.loc4_22.1 => constants.%Wrap.8a2
// CHECK:STDOUT:   %.loc4_22.9 => constants.%.f64
// CHECK:STDOUT:   %pattern_type.loc4_22.2 => constants.%pattern_type.e27
// CHECK:STDOUT:   %return.param_patt.loc4_22.2 => constants.%return.param_patt.3dc
// CHECK:STDOUT:   %return.patt.loc4_22.2 => constants.%return.patt.e36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Wrap(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_14.2 => constants.%T.patt.d47
// CHECK:STDOUT:   %T.loc4_14.1 => constants.%i32
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt => constants.%x.patt.fbe
// CHECK:STDOUT:   %require_complete => constants.%complete_type.f8a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc6_1.2 => constants.%.e8e
// CHECK:STDOUT:   %struct_type.discriminant.payload => constants.%struct_type.discriminant.payload.5c2
// CHECK:STDOUT:   %complete_type.loc6_1.2 => constants.%complete_type.a8a
// CHECK:STDOUT:   %Wrap.Some.type => constants.%Wrap.Some.type.db4
// CHECK:STDOUT:   %Wrap.Some => constants.%Wrap.Some.fe1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Wrap.Some(constants.%i32) {
// CHECK:STDOUT:   %T => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc4_22.1 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %_.param_patt.loc4_22.2 => constants.%_.param_patt.fb2
// CHECK:STDOUT:   %_.patt.loc4_22.2 => constants.%_.patt.b75
// CHECK:STDOUT:   %Wrap.loc4_22.1 => constants.%Wrap.aab
// CHECK:STDOUT:   %.loc4_22.9 => constants.%.8c4
// CHECK:STDOUT:   %pattern_type.loc4_22.2 => constants.%pattern_type.f1a
// CHECK:STDOUT:   %return.param_patt.loc4_22.2 => constants.%return.param_patt.93a
// CHECK:STDOUT:   %return.patt.loc4_22.2 => constants.%return.patt.3f3
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_22.1 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc4_22.2 => constants.%complete_type.a8a
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.a8a
// CHECK:STDOUT:   %.loc4_22.10 => constants.%.e8e
// CHECK:STDOUT:   %uninit.loc4_22.2 => constants.%uninit.060
// CHECK:STDOUT:   %Wrap.val => constants.%Wrap.val.09b
// CHECK:STDOUT: }
// CHECK:STDOUT:
