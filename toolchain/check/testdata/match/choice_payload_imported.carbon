// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_payload_imported.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_payload_imported.carbon

// --- signal.carbon
library "signal";

choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// --- use.carbon
library "use";

import library "signal";

//@dump-sem-ir-begin
// Destructuring the payload of a choice declared in another library: the
// alternatives' name-to-index metadata (discriminant value and payload
// field position) must arrive through the class import for the pattern to
// resolve `.Go` and extract its payload.
fn Speed(s: Signal) -> i32 {
  match (s) {
    case .Go(speed: i32) => { return speed; }
    case .Stop => { return 0; }
    default => { return -1; }
  }
  return -2;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- use.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Signal: type = class_type @Signal [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.0fa: type = custom_layout_type {size=4, align=4, .Go@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %u2: type = class_type @UInt, @UInt(%int_2) [concrete]
// CHECK:STDOUT:   %pattern_type.1de: type = pattern_type %Signal [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.1de = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.1de = at_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Speed.type: type = fn_type @Speed [concrete]
// CHECK:STDOUT:   %Speed: %Speed.type = struct_value () [concrete]
// CHECK:STDOUT:   %speed.patt: %pattern_type.6b6 = value_binding_pattern speed [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.908: %pattern_type.e71 = tuple_pattern (%speed.patt) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.452: type = facet_type <@ImplicitAs, @ImplicitAs(%u2)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.e93: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.409: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.955: %ImplicitAs.type.452 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.e93) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.119: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u2, %ImplicitAs.facet.955) [concrete]
// CHECK:STDOUT:   %.66c: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.119, %ImplicitAs.facet.955 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.409, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_2) [concrete]
// CHECK:STDOUT:   %bound_method.6ef: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_0.336: %u2 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f24: type = facet_type <@EqWith, @EqWith(%u2)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.454: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_2, %int_2) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.5fc: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_2, %int_2) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.e76: %UInt.as.EqWith.impl.Equal.type.5fc = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.16f: %EqWith.type.f24 = facet_value %u2, (%EqWith.impl_witness.454) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.c65: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u2, %EqWith.facet.16f) [concrete]
// CHECK:STDOUT:   %.7a0: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.c65, %EqWith.facet.16f [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.dac: <bound method> = bound_method %int_0.336, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.149: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.e76, @UInt.as.EqWith.impl.Equal.1(%int_2, %int_2) [concrete]
// CHECK:STDOUT:   %bound_method.dad: <bound method> = bound_method %int_0.336, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.0f5: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_1.508: %u2 = int_value 1 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f51: <bound method> = bound_method %int_1.508, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %bound_method.1da: <bound method> = bound_method %int_1.508, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
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
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.db1: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.e9b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.db1, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.Signal: type = import_ref Main//signal, Signal, loaded [concrete = constants.%Signal]
// CHECK:STDOUT:   %Main.import_ref.f4b: %Signal = import_ref Main//signal, loc5_7, loaded
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Speed.decl: %Speed.type = fn_decl @Speed [concrete = constants.%Speed] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.1de = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.1de = at_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc10 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10: Core.Form = init_form %i32.loc10 [concrete = constants.%.795f]
// CHECK:STDOUT:     %s.param: %Signal = value_param call_param0
// CHECK:STDOUT:     %Signal.ref: type = name_ref Signal, imports.%Main.Signal [concrete = constants.%Signal]
// CHECK:STDOUT:     %s: %Signal = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Speed(%s.param: %Signal) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.ref: %Signal = name_ref s, %s
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %speed.patt: %pattern_type.6b6 = value_binding_pattern speed [concrete = constants.%speed.patt]
// CHECK:STDOUT:     %.loc12_19: %pattern_type.e71 = tuple_pattern (%speed.patt) [concrete = constants.%.908]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc12: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_26.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc12_26.1: <bound method> = bound_method %int_0.loc12, %impl.elem0.loc12_26.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:   %specific_fn.loc12_26.1: <specific function> = specific_function %impl.elem0.loc12_26.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc12_26.2: <bound method> = bound_method %int_0.loc12, %specific_fn.loc12_26.1 [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %u2 = call %bound_method.loc12_26.2(%int_0.loc12) [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc12_26.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc12_26.2: %u2 = converted %int_0.loc12, %.loc12_26.1 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc12_26.3: ref %u2 = class_element_access %s.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc12_26.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc12_26.3: <bound method> = bound_method %.loc12_26.2, %impl.elem0.loc12_26.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.dac]
// CHECK:STDOUT:   %specific_fn.loc12_26.2: <specific function> = specific_function %impl.elem0.loc12_26.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2, constants.%int_2) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc12_26.4: <bound method> = bound_method %.loc12_26.2, %specific_fn.loc12_26.2 [concrete = constants.%bound_method.dad]
// CHECK:STDOUT:   %.loc12_26.4: %u2 = acquire_value %.loc12_26.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc12: init bool = call %bound_method.loc12_26.4(%.loc12_26.2, %.loc12_26.4)
// CHECK:STDOUT:   %.loc12_26.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc12
// CHECK:STDOUT:   %.loc12_26.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc12, %.loc12_26.5
// CHECK:STDOUT:   if %.loc12_26.6 br !match.case.then.loc12 else br !match.case.else.loc12
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc12:
// CHECK:STDOUT:   %.loc12_26.7: ref %.0fa = class_element_access %s.ref, element1
// CHECK:STDOUT:   %.loc12_26.8: ref %tuple.type.a8a = class_element_access %.loc12_26.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc12_26.8, element0
// CHECK:STDOUT:   %.loc12_26.9: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %speed: %i32 = wrapper_binding speed, %.loc12_26.9
// CHECK:STDOUT:   %speed.ref: %i32 = name_ref speed, %speed
// CHECK:STDOUT:   %impl.elem0.loc12_38: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc12_38.1: <bound method> = bound_method %speed.ref, %impl.elem0.loc12_38
// CHECK:STDOUT:   %specific_fn.loc12_38: <specific function> = specific_function %impl.elem0.loc12_38, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_38.2: <bound method> = bound_method %speed.ref, %specific_fn.loc12_38
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc12_38.2(%speed.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc12:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.1de = expr_pattern %Stop.ref in [concrete] {
// CHECK:STDOUT:       %Stop.ref: %Signal = name_ref Stop, imports.%Main.import_ref.f4b
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Stop.ref: %Signal = name_ref Stop, imports.%Main.import_ref.f4b
// CHECK:STDOUT:   %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_16.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc13_16.1: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc13_16.1: <specific function> = specific_function %impl.elem0.loc13_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc13_16.2: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_16.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_16: init %u2 = call %bound_method.loc13_16.2(%int_1.loc13) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc13_16.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_16 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc13_16.2: %u2 = converted %int_1.loc13, %.loc13_16.1 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc13_16.3: ref %u2 = class_element_access %s.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc13_16.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc13_16.3: <bound method> = bound_method %.loc13_16.2, %impl.elem0.loc13_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f51]
// CHECK:STDOUT:   %specific_fn.loc13_16.2: <specific function> = specific_function %impl.elem0.loc13_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2, constants.%int_2) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc13_16.4: <bound method> = bound_method %.loc13_16.2, %specific_fn.loc13_16.2 [concrete = constants.%bound_method.1da]
// CHECK:STDOUT:   %.loc13_16.4: %u2 = acquire_value %.loc13_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_16.4(%.loc13_16.2, %.loc13_16.4)
// CHECK:STDOUT:   %.loc13_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:   %.loc13_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc13, %.loc13_16.5
// CHECK:STDOUT:   if %.loc13_16.6 br !match.case.then.loc13 else br !match.case.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc13:
// CHECK:STDOUT:   %int_0.loc13: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_29.1: <bound method> = bound_method %int_0.loc13, %impl.elem0.loc13_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc13_29: <specific function> = specific_function %impl.elem0.loc13_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc13_29.2: <bound method> = bound_method %int_0.loc13, %specific_fn.loc13_29 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_29: init %i32 = call %bound_method.loc13_29.2(%int_0.loc13) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc13_29: init %i32 = converted %int_0.loc13, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_29 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc13_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc13:
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc14_25: <bound method> = bound_method %int_1.loc14, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc14_25(%int_1.loc14) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc14: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_27.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_27.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc14 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc14_25.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc14_25.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc14_25.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i32 = call %bound_method.loc14_27.2(%.loc14_25.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc14_27: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc14_27
// CHECK:STDOUT: }
// CHECK:STDOUT:
