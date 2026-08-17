// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/uint.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/single_payload_alternative.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/single_payload_alternative.carbon

// --- single_payload_alternative.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A single payload-carrying alternative (review F-A1): with fewer than two
// alternatives there are no discriminant bits, so the discriminant field is
// the empty tuple, and the composed constructor pairs a zero-bit `()`
// discriminant initialization with the payload-region store.
choice OneShot {
  Only(x: i32)
}

fn Make(x: i32) -> OneShot {
  return OneShot.Only(x);
}

// A constructor call bound directly, and one through a function call.
let direct: OneShot = OneShot.Only(3);
let made: OneShot = Make(7);
//@dump-sem-ir-end

// CHECK:STDOUT: --- single_payload_alternative.carbon
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
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Make.type: type = fn_type @Make [concrete]
// CHECK:STDOUT:   %Make: %Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %direct.patt: %pattern_type.bc6 = value_binding_pattern direct [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %made.patt: %pattern_type.bc6 = value_binding_pattern made [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.7ff: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %OneShot.Only.decl: %OneShot.Only.type = fn_decl @OneShot.Only [concrete = constants.%OneShot.Only] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.bc6 = out_param_pattern [concrete = constants.%return.param_patt.9f6]
// CHECK:STDOUT:     %return.patt: %pattern_type.bc6 = return_slot_pattern %return.param_patt, constants.%OneShot [concrete = constants.%return.patt.941]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc8_16.9: Core.Form = init_form constants.%OneShot [concrete = constants.%.9bb]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %OneShot = out_param call_param1
// CHECK:STDOUT:     %return: ref %OneShot = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %OneShot.decl: type = class_decl @OneShot [concrete = constants.%OneShot] {} {}
// CHECK:STDOUT:   %Make.decl: %Make.type = fn_decl @Make [concrete = constants.%Make] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.bc6 = out_param_pattern [concrete = constants.%return.param_patt.9f6]
// CHECK:STDOUT:     %return.patt: %pattern_type.bc6 = return_slot_pattern %return.param_patt, %OneShot.ref.loc12 [concrete = constants.%return.patt.941]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %OneShot.ref.loc12: type = name_ref OneShot, file.%OneShot.decl [concrete = constants.%OneShot]
// CHECK:STDOUT:     %.loc12_20.2: Core.Form = init_form %OneShot.ref.loc12 [concrete = constants.%.9bb]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %OneShot = out_param call_param1
// CHECK:STDOUT:     %return: ref %OneShot = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc17_37.1: ref %OneShot = temporary @__global_init.%.loc17_37, @__global_init.%OneShot.Only.call
// CHECK:STDOUT:   %.loc17_37.2: %OneShot = acquire_value %.loc17_37.1
// CHECK:STDOUT:   %OneShot.ref.loc17: type = name_ref OneShot, %OneShot.decl [concrete = constants.%OneShot]
// CHECK:STDOUT:   %direct: %OneShot = wrapper_binding direct, %.loc17_37.2
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %direct.patt: %pattern_type.bc6 = value_binding_pattern direct [concrete = constants.%direct.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc18_27.1: ref %OneShot = temporary @__global_init.%.loc18_27, @__global_init.%Make.call
// CHECK:STDOUT:   %.loc18_27.2: %OneShot = acquire_value %.loc18_27.1
// CHECK:STDOUT:   %OneShot.ref.loc18: type = name_ref OneShot, %OneShot.decl [concrete = constants.%OneShot]
// CHECK:STDOUT:   %made: %OneShot = wrapper_binding made, %.loc18_27.2
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %made.patt: %pattern_type.bc6 = value_binding_pattern made [concrete = constants.%made.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @OneShot {
// CHECK:STDOUT:   %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:   %.loc10: type = custom_layout_type {size=4, align=4, .Only@0: %tuple.type.a8a} [concrete = constants.%.e0f]
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
// CHECK:STDOUT:   %.loc8_16.1: ref %empty_tuple.type = class_element_access %return.param, element0
// CHECK:STDOUT:   %.loc10_1.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc10_1.2: init %empty_tuple.type to %.loc8_16.1 = tuple_init () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc8_16.2: init %empty_tuple.type = converted %.loc10_1.1, %.loc10_1.2 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc8_16.3: init %empty_tuple.type to %.loc8_16.1 = in_place_init %.loc8_16.2 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc8_16.4: ref %.e0f = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc8_16.5: ref %tuple.type.a8a = class_element_access %.loc8_16.4, element0
// CHECK:STDOUT:   %.loc10_1.3: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc8_16.1: <bound method> = bound_method %_.param, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_16.2: <bound method> = bound_method %_.param, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc8_16.2(%_.param)
// CHECK:STDOUT:   %.loc10_1.4: init %tuple.type.a8a to %.loc8_16.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc8_16.6: init %tuple.type.a8a = converted %.loc10_1.3, %.loc10_1.4
// CHECK:STDOUT:   %.loc8_16.7: init %tuple.type.a8a to %.loc8_16.5 = in_place_init %.loc8_16.6
// CHECK:STDOUT:   %.loc8_16.8: init %OneShot to %return.param = class_init (%.loc8_16.3, %.loc8_16.7)
// CHECK:STDOUT:   return %.loc8_16.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Make(%x.param: %i32) -> out %return.param: %OneShot {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %OneShot.ref.loc13: type = name_ref OneShot, file.%OneShot.decl [concrete = constants.%OneShot]
// CHECK:STDOUT:   %Only.ref: %OneShot.Only.type = name_ref Only, generated.%OneShot.Only.decl [concrete = constants.%OneShot.Only]
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %.loc12_20.1: ref %OneShot = splice_block %return.param {}
// CHECK:STDOUT:   %OneShot.Only.call: init %OneShot to %.loc12_20.1 = call %Only.ref(%x.ref)
// CHECK:STDOUT:   return %OneShot.Only.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @__global_init() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %OneShot.ref: type = name_ref OneShot, file.%OneShot.decl [concrete = constants.%OneShot]
// CHECK:STDOUT:   %Only.ref: %OneShot.Only.type = name_ref Only, generated.%OneShot.Only.decl [concrete = constants.%OneShot.Only]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc17_37: ref %OneShot = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_36.1: <bound method> = bound_method %int_3, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc17_36.2: <bound method> = bound_method %int_3, %specific_fn.loc17 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %i32 = call %bound_method.loc17_36.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc17_36.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc17_36.2: %i32 = converted %int_3, %.loc17_36.1 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %OneShot.Only.call: init %OneShot to %.loc17_37 = call %Only.ref(%.loc17_36.2)
// CHECK:STDOUT:   %Make.ref: %Make.type = name_ref Make, file.%Make.decl [concrete = constants.%Make]
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %.loc18_27: ref %OneShot = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc18: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_26.1: <bound method> = bound_method %int_7, %impl.elem0.loc18 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc18: <specific function> = specific_function %impl.elem0.loc18, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc18_26.2: <bound method> = bound_method %int_7, %specific_fn.loc18 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18: init %i32 = call %bound_method.loc18_26.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc18_26.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc18_26.2: %i32 = converted %int_7, %.loc18_26.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %Make.call: init %OneShot to %.loc18_27 = call %Make.ref(%.loc18_26.2)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
