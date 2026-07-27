// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/mixed_payload_alternatives.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/mixed_payload_alternatives.carbon

// --- mixed_payload_alternatives.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice MaybeInt {
  None(),
  Missing,
  Some(x: i64)
}

// A zero-parameter function alternative of a payload-carrying choice: its
// constructor must cover the payload region with an uninitialized value so
// the class_init's element count matches the object representation.
fn MakeNone() -> MaybeInt {
  return MaybeInt.None();
}

// A parenless constant alternative: the conversion covers the payload field.
let missing: MaybeInt = MaybeInt.Missing;

// A payload-carrying alternative.
fn MakeSome(x: i64) -> MaybeInt {
  return MaybeInt.Some(x);
}

let none: MaybeInt = MakeNone();
let some: MaybeInt = MakeSome(42);
//@dump-sem-ir-end

// CHECK:STDOUT: --- mixed_payload_alternatives.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %MaybeInt: type = class_type @MaybeInt [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.f57 = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %u2: type = class_type @UInt, @UInt(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %tuple.type.f67: type = tuple_type (%i64) [concrete]
// CHECK:STDOUT:   %.74a: type = custom_layout_type {size=8, align=8, .Some@0: %tuple.type.f67} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.b2b: type = struct_type {.discriminant: %u2, .payload: %.74a} [concrete]
// CHECK:STDOUT:   %complete_type.4d8: <witness> = complete_type_witness %struct_type.discriminant.payload.b2b [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u2} [concrete]
// CHECK:STDOUT:   %.159: Core.Form = init_form %MaybeInt [concrete]
// CHECK:STDOUT:   %pattern_type.e20: type = pattern_type %MaybeInt [concrete]
// CHECK:STDOUT:   %return.param_patt.728: %pattern_type.e20 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.af0: %pattern_type.e20 = return_slot_pattern %return.param_patt.728, %MaybeInt [concrete]
// CHECK:STDOUT:   %MaybeInt.None.type: type = fn_type @MaybeInt.None [concrete]
// CHECK:STDOUT:   %MaybeInt.None: %MaybeInt.None.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.452: type = facet_type <@ImplicitAs, @ImplicitAs(%u2)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.e93: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.409: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.955: %ImplicitAs.type.452 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.e93) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.119: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u2, %ImplicitAs.facet.955) [concrete]
// CHECK:STDOUT:   %.66c: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.119, %ImplicitAs.facet.955 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.409, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.6ef: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_0.336: %u2 = int_value 0 [concrete]
// CHECK:STDOUT:   %uninit: %.74a = uninitialized_value [concrete]
// CHECK:STDOUT:   %MaybeInt.val.4b9: %MaybeInt = struct_value (%int_0.336, %uninit) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.0f5: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_1.508: %u2 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.508) [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.f92: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.d68: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.4d1: %UInt.as.Copy.impl.Op.type.d68 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.842: %Copy.type = facet_value %u2, (%Copy.impl_witness.f92) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.21e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.842) [concrete]
// CHECK:STDOUT:   %.594: type = fn_type_with_self_type %Copy.WithSelf.Op.type.21e, %Copy.facet.842 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.508, %UInt.as.Copy.impl.Op.4d1 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.4d1, @UInt.as.Copy.impl.Op(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.373: <bound method> = bound_method %int_1.508, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %MaybeInt.val.173: %MaybeInt = struct_value (%int_1.508, %uninit) [concrete]
// CHECK:STDOUT:   %.9bb: ref %MaybeInt = temporary invalid, %MaybeInt.val.173 [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.f57 = at_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %MaybeInt.Some.type: type = fn_type @MaybeInt.Some [concrete]
// CHECK:STDOUT:   %MaybeInt.Some: %MaybeInt.Some.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.135: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_2.996: %u2 = int_value 2 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.c5e: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.b84: %Copy.type = facet_value %i64, (%Copy.impl_witness.c5e) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.70a: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.b84) [concrete]
// CHECK:STDOUT:   %.3cb: type = fn_type_with_self_type %Copy.WithSelf.Op.type.70a, %Copy.facet.b84 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT:   %MakeNone.type: type = fn_type @MakeNone [concrete]
// CHECK:STDOUT:   %MakeNone: %MakeNone.type = struct_value () [concrete]
// CHECK:STDOUT:   %missing.patt: %pattern_type.e20 = value_binding_pattern missing [concrete]
// CHECK:STDOUT:   %MakeSome.type: type = fn_type @MakeSome [concrete]
// CHECK:STDOUT:   %MakeSome: %MakeSome.type = struct_value () [concrete]
// CHECK:STDOUT:   %none.patt: %pattern_type.e20 = value_binding_pattern none [concrete]
// CHECK:STDOUT:   %some.patt: %pattern_type.e20 = value_binding_pattern some [concrete]
// CHECK:STDOUT:   %int_42.20e: Core.IntLiteral = int_value 42 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.091: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.6e8: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.091) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.a04: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.6e8) [concrete]
// CHECK:STDOUT:   %.f34: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.a04, %ImplicitAs.facet.6e8 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.c8b: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.f5c: <bound method> = bound_method %int_42.20e, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_42.b15: %i64 = int_value 42 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/parts/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/parts/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %MaybeInt.None.decl: %MaybeInt.None.type = fn_decl @MaybeInt.None [concrete = constants.%MaybeInt.None] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e20 = out_param_pattern [concrete = constants.%return.param_patt.728]
// CHECK:STDOUT:     %return.patt: %pattern_type.e20 = return_slot_pattern %return.param_patt, constants.%MaybeInt [concrete = constants.%return.patt.af0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_17.7: Core.Form = init_form constants.%MaybeInt [concrete = constants.%.159]
// CHECK:STDOUT:     %return.param: ref %MaybeInt = out_param call_param0
// CHECK:STDOUT:     %return: ref %MaybeInt = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MaybeInt.Some.decl: %MaybeInt.Some.type = fn_decl @MaybeInt.Some [concrete = constants.%MaybeInt.Some] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.f57 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.f57 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e20 = out_param_pattern [concrete = constants.%return.param_patt.728]
// CHECK:STDOUT:     %return.patt: %pattern_type.e20 = return_slot_pattern %return.param_patt, constants.%MaybeInt [concrete = constants.%return.patt.af0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_17.9: Core.Form = init_form constants.%MaybeInt [concrete = constants.%.159]
// CHECK:STDOUT:     %_.param: %i64 = value_param call_param0
// CHECK:STDOUT:     %_: %i64 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %MaybeInt = out_param call_param1
// CHECK:STDOUT:     %return: ref %MaybeInt = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %MaybeInt.decl: type = class_decl @MaybeInt [concrete = constants.%MaybeInt] {} {}
// CHECK:STDOUT:   %MakeNone.decl: %MakeNone.type = fn_decl @MakeNone [concrete = constants.%MakeNone] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e20 = out_param_pattern [concrete = constants.%return.param_patt.728]
// CHECK:STDOUT:     %return.patt: %pattern_type.e20 = return_slot_pattern %return.param_patt, %MaybeInt.ref.loc13 [concrete = constants.%return.patt.af0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MaybeInt.ref.loc13: type = name_ref MaybeInt, file.%MaybeInt.decl [concrete = constants.%MaybeInt]
// CHECK:STDOUT:     %.loc13_18.2: Core.Form = init_form %MaybeInt.ref.loc13 [concrete = constants.%.159]
// CHECK:STDOUT:     %return.param: ref %MaybeInt = out_param call_param0
// CHECK:STDOUT:     %return: ref %MaybeInt = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MaybeInt.ref.loc18: type = name_ref MaybeInt, %MaybeInt.decl [concrete = constants.%MaybeInt]
// CHECK:STDOUT:   %missing: %MaybeInt = wrapper_binding missing, @__global_init.%Missing.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %missing.patt: %pattern_type.e20 = value_binding_pattern missing [concrete = constants.%missing.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MakeSome.decl: %MakeSome.type = fn_decl @MakeSome [concrete = constants.%MakeSome] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.f57 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.f57 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e20 = out_param_pattern [concrete = constants.%return.param_patt.728]
// CHECK:STDOUT:     %return.patt: %pattern_type.e20 = return_slot_pattern %return.param_patt, %MaybeInt.ref.loc21 [concrete = constants.%return.patt.af0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %MaybeInt.ref.loc21: type = name_ref MaybeInt, file.%MaybeInt.decl [concrete = constants.%MaybeInt]
// CHECK:STDOUT:     %.loc21_24.2: Core.Form = init_form %MaybeInt.ref.loc21 [concrete = constants.%.159]
// CHECK:STDOUT:     %x.param: %i64 = value_param call_param0
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %x: %i64 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %MaybeInt = out_param call_param1
// CHECK:STDOUT:     %return: ref %MaybeInt = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc25_31.1: ref %MaybeInt = temporary @__global_init.%.loc25, @__global_init.%MakeNone.call
// CHECK:STDOUT:   %.loc25_31.2: %MaybeInt = acquire_value %.loc25_31.1
// CHECK:STDOUT:   %MaybeInt.ref.loc25: type = name_ref MaybeInt, %MaybeInt.decl [concrete = constants.%MaybeInt]
// CHECK:STDOUT:   %none: %MaybeInt = wrapper_binding none, %.loc25_31.2
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %none.patt: %pattern_type.e20 = value_binding_pattern none [concrete = constants.%none.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc26_33.1: ref %MaybeInt = temporary @__global_init.%.loc26_33, @__global_init.%MakeSome.call
// CHECK:STDOUT:   %.loc26_33.2: %MaybeInt = acquire_value %.loc26_33.1
// CHECK:STDOUT:   %MaybeInt.ref.loc26: type = name_ref MaybeInt, %MaybeInt.decl [concrete = constants.%MaybeInt]
// CHECK:STDOUT:   %some: %MaybeInt = wrapper_binding some, %.loc26_33.2
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %some.patt: %pattern_type.e20 = value_binding_pattern some [concrete = constants.%some.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @MaybeInt {
// CHECK:STDOUT:   %x.param: %i64 = value_param call_param0
// CHECK:STDOUT:   %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %x: %i64 = wrapper_binding x, %x.param
// CHECK:STDOUT:   %.loc8: type = custom_layout_type {size=8, align=8, .Some@0: %tuple.type.f67} [concrete = constants.%.74a]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.b2b [concrete = constants.%complete_type.4d8]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_10.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc6_10.1: <bound method> = bound_method %int_1, %impl.elem0.loc6_10.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc6_10.1: <specific function> = specific_function %impl.elem0.loc6_10.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc6_10.2: <bound method> = bound_method %int_1, %specific_fn.loc6_10.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc6_10.2(%int_1) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_10.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_10.2: %u2 = converted %int_1, %.loc6_10.1 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_10.3: %struct_type.discriminant = struct_literal (%.loc6_10.2) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc6_10.2: %.594 = impl_witness_access constants.%Copy.impl_witness.f92, element0 [concrete = constants.%UInt.as.Copy.impl.Op.4d1]
// CHECK:STDOUT:   %bound_method.loc6_10.3: <bound method> = bound_method %.loc6_10.2, %impl.elem0.loc6_10.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %specific_fn.loc6_10.2: <specific function> = specific_function %impl.elem0.loc6_10.2, @UInt.as.Copy.impl.Op(constants.%int_2.ecc) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_10.4: <bound method> = bound_method %.loc6_10.2, %specific_fn.loc6_10.2 [concrete = constants.%bound_method.373]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call: init %u2 = call %bound_method.loc6_10.4(%.loc6_10.2) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_10.4: ref %MaybeInt = temporary_storage
// CHECK:STDOUT:   %.loc6_10.5: ref %u2 = class_element_access %.loc6_10.4, element0
// CHECK:STDOUT:   %.loc6_10.6: init %u2 to %.loc6_10.5 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_10.7: ref %.74a = class_element_access %.loc6_10.4, element1
// CHECK:STDOUT:   %uninit: %.74a = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc6_10.8: init %.74a to %.loc6_10.7 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc6_10.9: init %MaybeInt to %.loc6_10.4 = class_init (%.loc6_10.6, %.loc6_10.8) [concrete = constants.%MaybeInt.val.173]
// CHECK:STDOUT:   %.loc6_10.10: init %MaybeInt = converted %.loc6_10.3, %.loc6_10.9 [concrete = constants.%MaybeInt.val.173]
// CHECK:STDOUT:   %.loc6_10.11: ref %MaybeInt = temporary %.loc6_10.4, %.loc6_10.10 [concrete = constants.%.9bb]
// CHECK:STDOUT:   %.loc6_10.12: %MaybeInt = acquire_value %.loc6_10.11 [concrete = constants.%MaybeInt.val.173]
// CHECK:STDOUT:   %Missing: %MaybeInt = wrapper_binding Missing, %.loc6_10.12
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%MaybeInt
// CHECK:STDOUT:   .None = generated.%MaybeInt.None.decl
// CHECK:STDOUT:   .Missing = %Missing
// CHECK:STDOUT:   .Some = generated.%MaybeInt.Some.decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MaybeInt.None() -> out %return.param: %MaybeInt {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc4_17.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc4_17.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc4_17.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc4_17.2(%int_0) [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc4_17.2: init %u2 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc4_17.3: init %u2 to %.loc4_17.1 = in_place_init %.loc4_17.2 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc4_17.4: ref %.74a = class_element_access %return.param, element1
// CHECK:STDOUT:   %uninit: %.74a = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc4_17.5: init %.74a to %.loc4_17.4 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc4_17.6: init %MaybeInt to %return.param = class_init (%.loc4_17.3, %.loc4_17.5) [concrete = constants.%MaybeInt.val.4b9]
// CHECK:STDOUT:   return %.loc4_17.6 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MaybeInt.Some(%_.param: %i64) -> out %return.param: %MaybeInt {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc4_17.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc4_17.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc4_17.1: <bound method> = bound_method %int_2, %impl.elem0.loc4_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc4_17.1: <specific function> = specific_function %impl.elem0.loc4_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc4_17.2: <bound method> = bound_method %int_2, %specific_fn.loc4_17.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc4_17.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc4_17.2: init %u2 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc4_17.3: init %u2 to %.loc4_17.1 = in_place_init %.loc4_17.2 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc4_17.4: ref %.74a = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc4_17.5: ref %tuple.type.f67 = class_element_access %.loc4_17.4, element0
// CHECK:STDOUT:   %.loc8_1.1: %tuple.type.f67 = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc4_17.2: %.3cb = impl_witness_access constants.%Copy.impl_witness.c5e, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc4_17.3: <bound method> = bound_method %_.param, %impl.elem0.loc4_17.2
// CHECK:STDOUT:   %specific_fn.loc4_17.2: <specific function> = specific_function %impl.elem0.loc4_17.2, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc4_17.4: <bound method> = bound_method %_.param, %specific_fn.loc4_17.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i64 = call %bound_method.loc4_17.4(%_.param)
// CHECK:STDOUT:   %.loc8_1.2: init %tuple.type.f67 to %.loc4_17.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc4_17.6: init %tuple.type.f67 = converted %.loc8_1.1, %.loc8_1.2
// CHECK:STDOUT:   %.loc4_17.7: init %tuple.type.f67 to %.loc4_17.5 = in_place_init %.loc4_17.6
// CHECK:STDOUT:   %.loc4_17.8: init %MaybeInt to %return.param = class_init (%.loc4_17.3, %.loc4_17.7)
// CHECK:STDOUT:   return %.loc4_17.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeNone() -> out %return.param: %MaybeInt {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %MaybeInt.ref.loc14: type = name_ref MaybeInt, file.%MaybeInt.decl [concrete = constants.%MaybeInt]
// CHECK:STDOUT:   %None.ref: %MaybeInt.None.type = name_ref None, generated.%MaybeInt.None.decl [concrete = constants.%MaybeInt.None]
// CHECK:STDOUT:   %.loc13_18.1: ref %MaybeInt = splice_block %return.param {}
// CHECK:STDOUT:   %MaybeInt.None.call: init %MaybeInt to %.loc13_18.1 = call %None.ref()
// CHECK:STDOUT:   return %MaybeInt.None.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeSome(%x.param: %i64) -> out %return.param: %MaybeInt {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %MaybeInt.ref.loc22: type = name_ref MaybeInt, file.%MaybeInt.decl [concrete = constants.%MaybeInt]
// CHECK:STDOUT:   %Some.ref: %MaybeInt.Some.type = name_ref Some, generated.%MaybeInt.Some.decl [concrete = constants.%MaybeInt.Some]
// CHECK:STDOUT:   %x.ref: %i64 = name_ref x, %x
// CHECK:STDOUT:   %.loc21_24.1: ref %MaybeInt = splice_block %return.param {}
// CHECK:STDOUT:   %MaybeInt.Some.call: init %MaybeInt to %.loc21_24.1 = call %Some.ref(%x.ref)
// CHECK:STDOUT:   return %MaybeInt.Some.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %MaybeInt.ref: type = name_ref MaybeInt, file.%MaybeInt.decl [concrete = constants.%MaybeInt]
// CHECK:STDOUT:   %Missing.ref: %MaybeInt = name_ref Missing, @MaybeInt.%Missing
// CHECK:STDOUT:   %MakeNone.ref: %MakeNone.type = name_ref MakeNone, file.%MakeNone.decl [concrete = constants.%MakeNone]
// CHECK:STDOUT:   %.loc25: ref %MaybeInt = temporary_storage
// CHECK:STDOUT:   %MakeNone.call: init %MaybeInt to %.loc25 = call %MakeNone.ref()
// CHECK:STDOUT:   %MakeSome.ref: %MakeSome.type = name_ref MakeSome, file.%MakeSome.decl [concrete = constants.%MakeSome]
// CHECK:STDOUT:   %int_42: Core.IntLiteral = int_value 42 [concrete = constants.%int_42.20e]
// CHECK:STDOUT:   %.loc26_33: ref %MaybeInt = temporary_storage
// CHECK:STDOUT:   %impl.elem0: %.f34 = impl_witness_access constants.%ImplicitAs.impl_witness.091, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc26_31.1: <bound method> = bound_method %int_42, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.c8b]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc26_31.2: <bound method> = bound_method %int_42, %specific_fn [concrete = constants.%bound_method.f5c]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc26_31.2(%int_42) [concrete = constants.%int_42.b15]
// CHECK:STDOUT:   %.loc26_31.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_42.b15]
// CHECK:STDOUT:   %.loc26_31.2: %i64 = converted %int_42, %.loc26_31.1 [concrete = constants.%int_42.b15]
// CHECK:STDOUT:   %MakeSome.call: init %MaybeInt to %.loc26_33 = call %MakeSome.ref(%.loc26_31.2)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
