// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/payload_layout.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/payload_layout.carbon

// --- payload_layout.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// Payload tuples of different sizes: per the F-007k storage contract
// (docs/design/unions.md, "Relationship to choice types"), the payload region
// is sized and aligned by the max-of-fields rule with every payload tuple at
// offset zero: (i64, i32) is 12 bytes with 8-byte alignment, (i32) is 4 bytes
// — the region must be 16 bytes (12 rounded up to alignment 8), not their
// sum.
choice Sized {
  Small(a: i32),
  Large(a: i64, b: i32),
  None
}

fn MakeSmall(n: i32) -> Sized {
  return Sized.Small(n);
}

fn MakeLarge(a: i64, b: i32) -> Sized {
  return Sized.Large(a, b);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- payload_layout.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Sized: type = class_type @Sized [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %a.param_patt.089: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt.71e: %pattern_type.f57 = at_binding_pattern a, %a.param_patt.089 [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = at_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %u2: type = class_type @UInt, @UInt(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.952: type = tuple_type (%i64, %i32) [concrete]
// CHECK:STDOUT:   %.a22: type = custom_layout_type {size=16, align=8, .Small@0: %tuple.type.a8a, .Large@0: %tuple.type.952} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.1c0: type = struct_type {.discriminant: %u2, .payload: %.a22} [concrete]
// CHECK:STDOUT:   %complete_type.c95: <witness> = complete_type_witness %struct_type.discriminant.payload.1c0 [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u2} [concrete]
// CHECK:STDOUT:   %_.param_patt.fb2: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.b75: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.fb2 [concrete]
// CHECK:STDOUT:   %.a72: Core.Form = init_form %Sized [concrete]
// CHECK:STDOUT:   %pattern_type.698: type = pattern_type %Sized [concrete]
// CHECK:STDOUT:   %return.param_patt.590: %pattern_type.698 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.f0c: %pattern_type.698 = return_slot_pattern %return.param_patt.590, %Sized [concrete]
// CHECK:STDOUT:   %Sized.Small.type: type = fn_type @Sized.Small [concrete]
// CHECK:STDOUT:   %Sized.Small: %Sized.Small.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.452: type = facet_type <@ImplicitAs, @ImplicitAs(%u2)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.2e8: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.409: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.452 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.2e8) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.dfa: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u2, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.884: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.dfa, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.409, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.6ef: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.336: %u2 = int_value 0 [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.287: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %_.param_patt.2f0: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt.233: %pattern_type.f57 = at_binding_pattern _, %_.param_patt.2f0 [concrete]
// CHECK:STDOUT:   %Sized.Large.type: type = fn_type @Sized.Large [concrete]
// CHECK:STDOUT:   %Sized.Large: %Sized.Large.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.0f5: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.508: %u2 = int_value 1 [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.4e9: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.5c1: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %.826: type = fn_type_with_self_type %Copy.WithSelf.Op.type.5c1, %Copy.facet.4e9 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn.b95: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.135: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.996: %u2 = int_value 2 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_2.996) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.8d6: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.d68: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.4d1: %UInt.as.Copy.impl.Op.type.d68 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.0fc: %Copy.type = facet_value %u2, (%Copy.impl_witness.8d6) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.894: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.0fc) [concrete]
// CHECK:STDOUT:   %.b0b: type = fn_type_with_self_type %Copy.WithSelf.Op.type.894, %Copy.facet.0fc [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_2.996, %UInt.as.Copy.impl.Op.4d1 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.4d1, @UInt.as.Copy.impl.Op(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.f90: <bound method> = bound_method %int_2.996, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit: %.a22 = uninitialized_value [concrete]
// CHECK:STDOUT:   %Sized.val: %Sized = struct_value (%int_2.996, %uninit) [concrete]
// CHECK:STDOUT:   %.8a6: ref %Sized = temporary invalid, %Sized.val [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %MakeSmall.type: type = fn_type @MakeSmall [concrete]
// CHECK:STDOUT:   %MakeSmall: %MakeSmall.type = struct_value () [concrete]
// CHECK:STDOUT:   %MakeLarge.type: type = fn_type @MakeLarge [concrete]
// CHECK:STDOUT:   %MakeLarge: %MakeLarge.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/parts/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/parts/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Sized.Small.decl: %Sized.Small.type = fn_decl @Sized.Small [concrete = constants.%Sized.Small] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt.fb2]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt.b75]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.698 = out_param_pattern [concrete = constants.%return.param_patt.590]
// CHECK:STDOUT:     %return.patt: %pattern_type.698 = return_slot_pattern %return.param_patt, constants.%Sized [concrete = constants.%return.patt.f0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_14.9: Core.Form = init_form constants.%Sized [concrete = constants.%.a72]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %Sized = out_param call_param1
// CHECK:STDOUT:     %return: ref %Sized = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Sized.Large.decl: %Sized.Large.type = fn_decl @Sized.Large [concrete = constants.%Sized.Large] {
// CHECK:STDOUT:     %_.param_patt.loc10_14.1: %pattern_type.f57 = value_param_pattern [concrete = constants.%_.param_patt.2f0]
// CHECK:STDOUT:     %_.patt.loc10_14.1: %pattern_type.f57 = at_binding_pattern _, %_.param_patt.loc10_14.1 [concrete = constants.%_.patt.233]
// CHECK:STDOUT:     %_.param_patt.loc10_14.2: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt.fb2]
// CHECK:STDOUT:     %_.patt.loc10_14.2: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt.loc10_14.2 [concrete = constants.%_.patt.b75]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.698 = out_param_pattern [concrete = constants.%return.param_patt.590]
// CHECK:STDOUT:     %return.patt: %pattern_type.698 = return_slot_pattern %return.param_patt, constants.%Sized [concrete = constants.%return.patt.f0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_14.8: Core.Form = init_form constants.%Sized [concrete = constants.%.a72]
// CHECK:STDOUT:     %_.param.loc10_14.1: %i64 = value_param call_param0
// CHECK:STDOUT:     %_.loc10_14.1: %i64 = wrapper_binding _, %_.param.loc10_14.1
// CHECK:STDOUT:     %_.param.loc10_14.2: %i32 = value_param call_param1
// CHECK:STDOUT:     %_.loc10_14.2: %i32 = wrapper_binding _, %_.param.loc10_14.2
// CHECK:STDOUT:     %return.param: ref %Sized = out_param call_param2
// CHECK:STDOUT:     %return: ref %Sized = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Sized.decl: type = class_decl @Sized [concrete = constants.%Sized] {} {}
// CHECK:STDOUT:   %MakeSmall.decl: %MakeSmall.type = fn_decl @MakeSmall [concrete = constants.%MakeSmall] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.698 = out_param_pattern [concrete = constants.%return.param_patt.590]
// CHECK:STDOUT:     %return.patt: %pattern_type.698 = return_slot_pattern %return.param_patt, %Sized.ref.loc16 [concrete = constants.%return.patt.f0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Sized.ref.loc16: type = name_ref Sized, file.%Sized.decl [concrete = constants.%Sized]
// CHECK:STDOUT:     %.loc16_25.2: Core.Form = init_form %Sized.ref.loc16 [concrete = constants.%.a72]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %Sized = out_param call_param1
// CHECK:STDOUT:     %return: ref %Sized = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MakeLarge.decl: %MakeLarge.type = fn_decl @MakeLarge [concrete = constants.%MakeLarge] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.f57 = value_param_pattern [concrete = constants.%a.param_patt.089]
// CHECK:STDOUT:     %a.patt: %pattern_type.f57 = at_binding_pattern a, %a.param_patt [concrete = constants.%a.patt.71e]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = at_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.698 = out_param_pattern [concrete = constants.%return.param_patt.590]
// CHECK:STDOUT:     %return.patt: %pattern_type.698 = return_slot_pattern %return.param_patt, %Sized.ref.loc20 [concrete = constants.%return.patt.f0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Sized.ref.loc20: type = name_ref Sized, file.%Sized.decl [concrete = constants.%Sized]
// CHECK:STDOUT:     %.loc20_33.2: Core.Form = init_form %Sized.ref.loc20 [concrete = constants.%.a72]
// CHECK:STDOUT:     %a.param: %i64 = value_param call_param0
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %a: %i64 = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %i32 = value_param call_param1
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %b: %i32 = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %Sized = out_param call_param2
// CHECK:STDOUT:     %return: ref %Sized = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Sized {
// CHECK:STDOUT:   %a.param.loc11: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32.loc11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %a.loc11: %i32 = wrapper_binding a, %a.param.loc11
// CHECK:STDOUT:   %a.param.loc12: %i64 = value_param call_param0
// CHECK:STDOUT:   %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %a.loc12: %i64 = wrapper_binding a, %a.param.loc12
// CHECK:STDOUT:   %b.param: %i32 = value_param call_param1
// CHECK:STDOUT:   %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %b.param
// CHECK:STDOUT:   %.loc14_1.1: type = custom_layout_type {size=16, align=8, .Small@0: %tuple.type.a8a, .Large@0: %tuple.type.952} [concrete = constants.%.a22]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.1c0 [concrete = constants.%complete_type.c95]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc14_1.1: %.884 = impl_witness_access constants.%ImplicitAs.impl_witness.2e8, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc14_1.1: <bound method> = bound_method %int_2, %impl.elem0.loc14_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc14_1.1: <specific function> = specific_function %impl.elem0.loc14_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_1.2: <bound method> = bound_method %int_2, %specific_fn.loc14_1.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc14_1.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc14_1.2: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc14_1.3: %u2 = converted %int_2, %.loc14_1.2 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc14_1.4: %struct_type.discriminant = struct_literal (%.loc14_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc14_1.2: %.b0b = impl_witness_access constants.%Copy.impl_witness.8d6, element0 [concrete = constants.%UInt.as.Copy.impl.Op.4d1]
// CHECK:STDOUT:   %bound_method.loc14_1.3: <bound method> = bound_method %.loc14_1.3, %impl.elem0.loc14_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %specific_fn.loc14_1.2: <specific function> = specific_function %impl.elem0.loc14_1.2, @UInt.as.Copy.impl.Op(constants.%int_2.ecc) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_1.4: <bound method> = bound_method %.loc14_1.3, %specific_fn.loc14_1.2 [concrete = constants.%bound_method.f90]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call: init %u2 = call %bound_method.loc14_1.4(%.loc14_1.3) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc14_1.5: ref %Sized = temporary_storage
// CHECK:STDOUT:   %.loc14_1.6: ref %u2 = class_element_access %.loc14_1.5, element0
// CHECK:STDOUT:   %.loc14_1.7: init %u2 to %.loc14_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc14_1.8: ref %.a22 = class_element_access %.loc14_1.5, element1
// CHECK:STDOUT:   %uninit: %.a22 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc14_1.9: init %.a22 to %.loc14_1.8 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc14_1.10: init %Sized to %.loc14_1.5 = class_init (%.loc14_1.7, %.loc14_1.9) [concrete = constants.%Sized.val]
// CHECK:STDOUT:   %.loc14_1.11: init %Sized = converted %.loc14_1.4, %.loc14_1.10 [concrete = constants.%Sized.val]
// CHECK:STDOUT:   %.loc14_1.12: ref %Sized = temporary %.loc14_1.5, %.loc14_1.11 [concrete = constants.%.8a6]
// CHECK:STDOUT:   %.loc14_1.13: %Sized = acquire_value %.loc14_1.12 [concrete = constants.%Sized.val]
// CHECK:STDOUT:   %None: %Sized = wrapper_binding None, %.loc14_1.13
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Sized
// CHECK:STDOUT:   .Small = generated.%Sized.Small.decl
// CHECK:STDOUT:   .Large = generated.%Sized.Large.decl
// CHECK:STDOUT:   .None = %None
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Sized.Small(%_.param: %i32) -> out %return.param: %Sized {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc10_14.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc10_14.1: %.884 = impl_witness_access constants.%ImplicitAs.impl_witness.2e8, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc10_14.1: <bound method> = bound_method %int_0, %impl.elem0.loc10_14.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:   %specific_fn.loc10_14.1: <specific function> = specific_function %impl.elem0.loc10_14.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_14.2: <bound method> = bound_method %int_0, %specific_fn.loc10_14.1 [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc10_14.2(%int_0) [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc10_14.2: init %u2 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc10_14.3: init %u2 to %.loc10_14.1 = in_place_init %.loc10_14.2 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc10_14.4: ref %.a22 = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc10_14.5: ref %tuple.type.a8a = class_element_access %.loc10_14.4, element0
// CHECK:STDOUT:   %.loc11_16.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc10_14.2: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc10_14.3: <bound method> = bound_method %_.param, %impl.elem0.loc10_14.2
// CHECK:STDOUT:   %specific_fn.loc10_14.2: <specific function> = specific_function %impl.elem0.loc10_14.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:   %bound_method.loc10_14.4: <bound method> = bound_method %_.param, %specific_fn.loc10_14.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc10_14.4(%_.param)
// CHECK:STDOUT:   %.loc11_16.2: init %tuple.type.a8a to %.loc10_14.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc10_14.6: init %tuple.type.a8a = converted %.loc11_16.1, %.loc11_16.2
// CHECK:STDOUT:   %.loc10_14.7: init %tuple.type.a8a to %.loc10_14.5 = in_place_init %.loc10_14.6
// CHECK:STDOUT:   %.loc10_14.8: init %Sized to %return.param = class_init (%.loc10_14.3, %.loc10_14.7)
// CHECK:STDOUT:   return %.loc10_14.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Sized.Large(%_.param.loc10_14.1: %i64, %_.param.loc10_14.2: %i32) -> out %return.param: %Sized {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc10_14.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc10_14.1: %.884 = impl_witness_access constants.%ImplicitAs.impl_witness.2e8, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc10_14.1: <bound method> = bound_method %int_1, %impl.elem0.loc10_14.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc10_14.1: <specific function> = specific_function %impl.elem0.loc10_14.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_14.2: <bound method> = bound_method %int_1, %specific_fn.loc10_14.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc10_14.2(%int_1) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc10_14.2: init %u2 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc10_14.3: init %u2 to %.loc10_14.1 = in_place_init %.loc10_14.2 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc10_14.4: ref %.a22 = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc10_14.5: ref %tuple.type.952 = class_element_access %.loc10_14.4, element1
// CHECK:STDOUT:   %.loc12_24.1: %tuple.type.952 = tuple_literal (%_.param.loc10_14.1, %_.param.loc10_14.2)
// CHECK:STDOUT:   %impl.elem0.loc10_14.2: %.826 = impl_witness_access constants.%Copy.impl_witness.8cc, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:   %bound_method.loc10_14.3: <bound method> = bound_method %_.param.loc10_14.1, %impl.elem0.loc10_14.2
// CHECK:STDOUT:   %specific_fn.loc10_14.2: <specific function> = specific_function %impl.elem0.loc10_14.2, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.b95]
// CHECK:STDOUT:   %bound_method.loc10_14.4: <bound method> = bound_method %_.param.loc10_14.1, %specific_fn.loc10_14.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc10_14.1: init %i64 = call %bound_method.loc10_14.4(%_.param.loc10_14.1)
// CHECK:STDOUT:   %tuple.elem0: ref %i64 = tuple_access %.loc10_14.5, element0
// CHECK:STDOUT:   %.loc12_24.2: init %i64 to %tuple.elem0 = in_place_init %Int.as.Copy.impl.Op.call.loc10_14.1
// CHECK:STDOUT:   %impl.elem0.loc10_14.3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc10_14.5: <bound method> = bound_method %_.param.loc10_14.2, %impl.elem0.loc10_14.3
// CHECK:STDOUT:   %specific_fn.loc10_14.3: <specific function> = specific_function %impl.elem0.loc10_14.3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn.287]
// CHECK:STDOUT:   %bound_method.loc10_14.6: <bound method> = bound_method %_.param.loc10_14.2, %specific_fn.loc10_14.3
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc10_14.2: init %i32 = call %bound_method.loc10_14.6(%_.param.loc10_14.2)
// CHECK:STDOUT:   %tuple.elem1: ref %i32 = tuple_access %.loc10_14.5, element1
// CHECK:STDOUT:   %.loc12_24.3: init %i32 to %tuple.elem1 = in_place_init %Int.as.Copy.impl.Op.call.loc10_14.2
// CHECK:STDOUT:   %.loc12_24.4: init %tuple.type.952 to %.loc10_14.5 = tuple_init (%.loc12_24.2, %.loc12_24.3)
// CHECK:STDOUT:   %.loc10_14.6: init %tuple.type.952 = converted %.loc12_24.1, %.loc12_24.4
// CHECK:STDOUT:   %.loc10_14.7: init %Sized to %return.param = class_init (%.loc10_14.3, %.loc10_14.6)
// CHECK:STDOUT:   return %.loc10_14.7 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeSmall(%n.param: %i32) -> out %return.param: %Sized {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Sized.ref.loc17: type = name_ref Sized, file.%Sized.decl [concrete = constants.%Sized]
// CHECK:STDOUT:   %Small.ref: %Sized.Small.type = name_ref Small, generated.%Sized.Small.decl [concrete = constants.%Sized.Small]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc16_25.1: ref %Sized = splice_block %return.param {}
// CHECK:STDOUT:   %Sized.Small.call: init %Sized to %.loc16_25.1 = call %Small.ref(%n.ref)
// CHECK:STDOUT:   return %Sized.Small.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MakeLarge(%a.param: %i64, %b.param: %i32) -> out %return.param: %Sized {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Sized.ref.loc21: type = name_ref Sized, file.%Sized.decl [concrete = constants.%Sized]
// CHECK:STDOUT:   %Large.ref: %Sized.Large.type = name_ref Large, generated.%Sized.Large.decl [concrete = constants.%Sized.Large]
// CHECK:STDOUT:   %a.ref: %i64 = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %.loc20_33.1: ref %Sized = splice_block %return.param {}
// CHECK:STDOUT:   %Sized.Large.call: init %Sized to %.loc20_33.1 = call %Large.ref(%a.ref, %b.ref)
// CHECK:STDOUT:   return %Sized.Large.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
