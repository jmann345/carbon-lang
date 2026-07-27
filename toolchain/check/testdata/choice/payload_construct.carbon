// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/payload_construct.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/payload_construct.carbon

// --- payload_construct.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice IntResult {
  Ok(value: i32),
  Err
}

// A payload-free alternative constant of a payload-carrying choice: the
// constant covers the payload region with an uninitialized value.
let err: IntResult = IntResult.Err;

// Function-like construction of a payload alternative.
fn Make(n: i32) -> IntResult {
  return IntResult.Ok(n);
}

fn Use(n: i32) {
  // A local of a payload-carrying choice type; its scope exit exercises the
  // destroy-witness path for the payload region.
  // CHECK:STDERR: payload_construct.carbon:[[@LINE+4]]:7: warning: binding `r` unused [UnusedBinding]
  // CHECK:STDERR:   var r: IntResult = Make(n);
  // CHECK:STDERR:       ^~~~~~~~~~~~
  // CHECK:STDERR:
  var r: IntResult = Make(n);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- payload_construct.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %IntResult: type = class_type @IntResult [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.2a5: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.898: type = struct_type {.discriminant: %u1, .payload: %.2a5} [concrete]
// CHECK:STDOUT:   %complete_type.697: <witness> = complete_type_witness %struct_type.discriminant.payload.898 [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.918: Core.Form = init_form %IntResult [concrete]
// CHECK:STDOUT:   %pattern_type.e14: type = pattern_type %IntResult [concrete]
// CHECK:STDOUT:   %return.param_patt.3e8: %pattern_type.e14 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.437: %pattern_type.e14 = return_slot_pattern %return.param_patt.3e8, %IntResult [concrete]
// CHECK:STDOUT:   %IntResult.Ok.type: type = fn_type @IntResult.Ok [concrete]
// CHECK:STDOUT:   %IntResult.Ok: %IntResult.Ok.type = struct_value () [concrete]
// CHECK:STDOUT:   %u1.builtin: type = int_type unsigned, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.fb7: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.771: %Copy.type = facet_value %u1, (%Copy.impl_witness.fb7) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4d4: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.771) [concrete]
// CHECK:STDOUT:   %.37a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4d4, %Copy.facet.771 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit: %.2a5 = uninitialized_value [concrete]
// CHECK:STDOUT:   %IntResult.val: %IntResult = struct_value (%int_1.233, %uninit) [concrete]
// CHECK:STDOUT:   %.942: ref %IntResult = temporary invalid, %IntResult.val [concrete]
// CHECK:STDOUT:   %err.patt: %pattern_type.e14 = value_binding_pattern err [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %Make.type: type = fn_type @Make [concrete]
// CHECK:STDOUT:   %Make: %Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %r.patt: %pattern_type.e14 = ref_binding_pattern r [concrete]
// CHECK:STDOUT:   %r.var_patt: %pattern_type.e14 = var_pattern %r.patt [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc25_3.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/parts/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/parts/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %IntResult.Ok.decl: %IntResult.Ok.type = fn_decl @IntResult.Ok [concrete = constants.%IntResult.Ok] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e14 = out_param_pattern [concrete = constants.%return.param_patt.3e8]
// CHECK:STDOUT:     %return.patt: %pattern_type.e14 = return_slot_pattern %return.param_patt, constants.%IntResult [concrete = constants.%return.patt.437]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_18.9: Core.Form = init_form constants.%IntResult [concrete = constants.%.918]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %IntResult = out_param call_param1
// CHECK:STDOUT:     %return: ref %IntResult = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %IntResult.decl: type = class_decl @IntResult [concrete = constants.%IntResult] {} {}
// CHECK:STDOUT:   %IntResult.ref: type = name_ref IntResult, %IntResult.decl [concrete = constants.%IntResult]
// CHECK:STDOUT:   %err: %IntResult = wrapper_binding err, @__global_init.%Err.ref
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %err.patt: %pattern_type.e14 = value_binding_pattern err [concrete = constants.%err.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Make.decl: %Make.type = fn_decl @Make [concrete = constants.%Make] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.e14 = out_param_pattern [concrete = constants.%return.param_patt.3e8]
// CHECK:STDOUT:     %return.patt: %pattern_type.e14 = return_slot_pattern %return.param_patt, %IntResult.ref.loc14 [concrete = constants.%return.patt.437]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %IntResult.ref.loc14: type = name_ref IntResult, file.%IntResult.decl [concrete = constants.%IntResult]
// CHECK:STDOUT:     %.loc14_20.2: Core.Form = init_form %IntResult.ref.loc14 [concrete = constants.%.918]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %IntResult = out_param call_param1
// CHECK:STDOUT:     %return: ref %IntResult = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @IntResult {
// CHECK:STDOUT:   %value.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %value: %i32 = wrapper_binding value, %value.param
// CHECK:STDOUT:   %.loc7_1.1: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.a8a} [concrete = constants.%.2a5]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.898 [concrete = constants.%complete_type.697]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc7_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.3: %u1 = converted %int_1, %.loc7_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.4: %struct_type.discriminant = struct_literal (%.loc7_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc7_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.3, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.3, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.5: ref %IntResult = temporary_storage
// CHECK:STDOUT:   %.loc7_1.6: ref %u1 = class_element_access %.loc7_1.5, element0
// CHECK:STDOUT:   %.loc7_1.7: init %u1 to %.loc7_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.8: ref %.2a5 = class_element_access %.loc7_1.5, element1
// CHECK:STDOUT:   %uninit: %.2a5 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc7_1.9: init %.2a5 to %.loc7_1.8 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc7_1.10: init %IntResult to %.loc7_1.5 = class_init (%.loc7_1.7, %.loc7_1.9) [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %.loc7_1.11: init %IntResult = converted %.loc7_1.4, %.loc7_1.10 [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %.loc7_1.12: ref %IntResult = temporary %.loc7_1.5, %.loc7_1.11 [concrete = constants.%.942]
// CHECK:STDOUT:   %.loc7_1.13: %IntResult = acquire_value %.loc7_1.12 [concrete = constants.%IntResult.val]
// CHECK:STDOUT:   %Err: %IntResult = wrapper_binding Err, %.loc7_1.13
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%IntResult
// CHECK:STDOUT:   .Ok = generated.%IntResult.Ok.decl
// CHECK:STDOUT:   .Err = %Err
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @IntResult.Ok(%_.param: %i32) -> out %return.param: %IntResult {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc4_18.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc4_18.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc4_18.1: <bound method> = bound_method %int_0, %impl.elem0.loc4_18.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc4_18.1: <specific function> = specific_function %impl.elem0.loc4_18.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc4_18.2: <bound method> = bound_method %int_0, %specific_fn.loc4_18.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc4_18.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc4_18.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc4_18.3: init %u1 to %.loc4_18.1 = in_place_init %.loc4_18.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc4_18.4: ref %.2a5 = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc4_18.5: ref %tuple.type.a8a = class_element_access %.loc4_18.4, element0
// CHECK:STDOUT:   %.loc5_17.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc4_18.2: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc4_18.3: <bound method> = bound_method %_.param, %impl.elem0.loc4_18.2
// CHECK:STDOUT:   %specific_fn.loc4_18.2: <specific function> = specific_function %impl.elem0.loc4_18.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc4_18.4: <bound method> = bound_method %_.param, %specific_fn.loc4_18.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc4_18.4(%_.param)
// CHECK:STDOUT:   %.loc5_17.2: init %tuple.type.a8a to %.loc4_18.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc4_18.6: init %tuple.type.a8a = converted %.loc5_17.1, %.loc5_17.2
// CHECK:STDOUT:   %.loc4_18.7: init %tuple.type.a8a to %.loc4_18.5 = in_place_init %.loc4_18.6
// CHECK:STDOUT:   %.loc4_18.8: init %IntResult to %return.param = class_init (%.loc4_18.3, %.loc4_18.7)
// CHECK:STDOUT:   return %.loc4_18.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Make(%n.param: %i32) -> out %return.param: %IntResult {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %IntResult.ref.loc15: type = name_ref IntResult, file.%IntResult.decl [concrete = constants.%IntResult]
// CHECK:STDOUT:   %Ok.ref: %IntResult.Ok.type = name_ref Ok, generated.%IntResult.Ok.decl [concrete = constants.%IntResult.Ok]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc14_20.1: ref %IntResult = splice_block %return.param {}
// CHECK:STDOUT:   %IntResult.Ok.call: init %IntResult to %.loc14_20.1 = call %Ok.ref(%n.ref)
// CHECK:STDOUT:   return %IntResult.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use(%n.param: %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %r.var: ref %IntResult = var_storage %r.var_patt
// CHECK:STDOUT:   %Make.ref: %Make.type = name_ref Make, file.%Make.decl [concrete = constants.%Make]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc25: ref %IntResult = splice_block %r.var {}
// CHECK:STDOUT:   %Make.call: init %IntResult to %.loc25 = call %Make.ref(%n.ref)
// CHECK:STDOUT:   assign %r.var, %Make.call
// CHECK:STDOUT:   %IntResult.ref: type = name_ref IntResult, file.%IntResult.decl [concrete = constants.%IntResult]
// CHECK:STDOUT:   %r: ref %IntResult = wrapper_binding r, %r.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %r.patt: %pattern_type.e14 = ref_binding_pattern r [concrete = constants.%r.patt]
// CHECK:STDOUT:     %r.var_patt: %pattern_type.e14 = var_pattern %r.patt [concrete = constants.%r.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %r.var, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%r.var)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_3.1(%self.param: ref %u1.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_3.2(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_3.3(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_3.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_3.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_3.6(%self.param: ref %.2a5) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_3.7(%self.param: ref %struct_type.discriminant.payload.898) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc25_3.8(%self.param: ref %IntResult) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %IntResult.ref: type = name_ref IntResult, file.%IntResult.decl [concrete = constants.%IntResult]
// CHECK:STDOUT:   %Err.ref: %IntResult = name_ref Err, @IntResult.%Err
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
