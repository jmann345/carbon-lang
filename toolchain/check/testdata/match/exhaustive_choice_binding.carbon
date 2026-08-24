// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/exhaustive_choice_binding.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/exhaustive_choice_binding.carbon

// An unguarded binding-pattern arm is irrefutable — it covers every
// scrutinee value — so a choice `match` containing one is exhaustive
// without a `default` arm and without covering each alternative (SF-7;
// re-platform plan S2e).

// --- final_binding_arm.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

// `.Stop` is covered by an alternative arm; everything else falls to the
// irrefutable binding arm, which discharges the `default` requirement.
fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    // CHECK:STDERR: final_binding_arm.carbon:[[@LINE+4]]:10: warning: binding `other` unused [UnusedBinding]
    // CHECK:STDERR:     case other: Signal => { return 1; }
    // CHECK:STDERR:          ^~~~~~~~~~~~~
    // CHECK:STDERR:
    case other: Signal => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- only_binding_arm.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// A single irrefutable arm alone is exhaustive.
fn Consume(f: Flag) -> i32 {
  match (f) {
    // CHECK:STDERR: only_binding_arm.carbon:[[@LINE+4]]:10: warning: binding `whole` unused [UnusedBinding]
    // CHECK:STDERR:     case whole: Flag => { return 7; }
    // CHECK:STDERR:          ^~~~~~~~~~~
    // CHECK:STDERR:
    case whole: Flag => { return 7; }
  }
  return -1;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- final_binding_arm.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Signal: type = class_type @Signal [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %u2: type = class_type @UInt, @UInt(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.0fa: type = custom_layout_type {size=4, align=4, .Go@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.de4: type = struct_type {.discriminant: %u2, .payload: %.0fa} [concrete]
// CHECK:STDOUT:   %complete_type.b1b: <witness> = complete_type_witness %struct_type.discriminant.payload.de4 [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u2} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.6b6 = wrapper_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.1d7: Core.Form = init_form %Signal [concrete]
// CHECK:STDOUT:   %pattern_type.1de: type = pattern_type %Signal [concrete]
// CHECK:STDOUT:   %return.param_patt.463: %pattern_type.1de = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.a55: %pattern_type.1de = return_slot_pattern %return.param_patt.463, %Signal [concrete]
// CHECK:STDOUT:   %Signal.Go.type: type = fn_type @Signal.Go [concrete]
// CHECK:STDOUT:   %Signal.Go: %Signal.Go.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.452: type = facet_type <@ImplicitAs, @ImplicitAs(%u2)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.2e8: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.409: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.d95 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.e6c: %ImplicitAs.type.452 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.2e8) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.dfa: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u2, %ImplicitAs.facet.e6c) [concrete]
// CHECK:STDOUT:   %.884: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.dfa, %ImplicitAs.facet.e6c [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.409, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.6ef: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_0.336: %u2 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.0f5: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_1.508: %u2 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.2cb: %struct_type.discriminant = struct_value (%int_1.508) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.8d6: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.d68: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.4d1: %UInt.as.Copy.impl.Op.type.d68 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.0fc: %Copy.type = facet_value %u2, (%Copy.impl_witness.8d6) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.894: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.0fc) [concrete]
// CHECK:STDOUT:   %.b0b: type = fn_type_with_self_type %Copy.WithSelf.Op.type.894, %Copy.facet.0fc [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.1e1: <bound method> = bound_method %int_1.508, %UInt.as.Copy.impl.Op.4d1 [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.4d1, @UInt.as.Copy.impl.Op(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.373: <bound method> = bound_method %int_1.508, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit: %.0fa = uninitialized_value [concrete]
// CHECK:STDOUT:   %Signal.val.b94: %Signal = struct_value (%int_1.508, %uninit) [concrete]
// CHECK:STDOUT:   %.763: ref %Signal = temporary invalid, %Signal.val.b94 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.135: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_2.996: %u2 = int_value 2 [concrete]
// CHECK:STDOUT:   %struct.40a: %struct_type.discriminant = struct_value (%int_2.996) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.424: <bound method> = bound_method %int_2.996, %UInt.as.Copy.impl.Op.4d1 [concrete]
// CHECK:STDOUT:   %bound_method.f90: <bound method> = bound_method %int_2.996, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Signal.val.4b5: %Signal = struct_value (%int_2.996, %uninit) [concrete]
// CHECK:STDOUT:   %.8ce: ref %Signal = temporary invalid, %Signal.val.4b5 [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.1de = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.1de = wrapper_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.f24: type = facet_type <@EqWith, @EqWith(%u2)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.db5: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.5fc: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.e76: %UInt.as.EqWith.impl.Equal.type.5fc = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.d05: %EqWith.type.f24 = facet_value %u2, (%EqWith.impl_witness.db5) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.52c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u2, %EqWith.facet.d05) [concrete]
// CHECK:STDOUT:   %.616: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.52c, %EqWith.facet.d05 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.508, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.149: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.e76, @UInt.as.EqWith.impl.Equal.1(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %bound_method.1da: <bound method> = bound_method %int_1.508, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %other.patt.ae2: %pattern_type.1de = value_binding_pattern other [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Signal.Go.decl: %Signal.Go.type = fn_decl @Signal.Go [concrete = constants.%Signal.Go] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = wrapper_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.1de = out_param_pattern [concrete = constants.%return.param_patt.463]
// CHECK:STDOUT:     %return.patt: %pattern_type.1de = return_slot_pattern %return.param_patt, constants.%Signal [concrete = constants.%return.patt.a55]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_15.9: Core.Form = init_form constants.%Signal [concrete = constants.%.1d7]
// CHECK:STDOUT:     %_.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %_: %i32 = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %Signal = out_param call_param1
// CHECK:STDOUT:     %return: ref %Signal = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Signal.decl: type = class_decl @Signal [concrete = constants.%Signal] {} {}
// CHECK:STDOUT:   %Classify.decl: %Classify.type = fn_decl @Classify [concrete = constants.%Classify] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.1de = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.1de = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %s.param: %Signal = value_param call_param0
// CHECK:STDOUT:     %Signal.ref.loc12: type = name_ref Signal, file.%Signal.decl [concrete = constants.%Signal]
// CHECK:STDOUT:     %s: %Signal = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Signal {
// CHECK:STDOUT:   %speed.param: %i32 = value_param call_param0
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %speed: %i32 = wrapper_binding speed, %speed.param
// CHECK:STDOUT:   %.loc8_1.1: type = custom_layout_type {size=4, align=4, .Go@0: %tuple.type.a8a} [concrete = constants.%.0fa]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.de4 [concrete = constants.%complete_type.b1b]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_7.1: %.884 = impl_witness_access constants.%ImplicitAs.impl_witness.2e8, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc6_7.1: <bound method> = bound_method %int_1, %impl.elem0.loc6_7.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc6_7.1: <specific function> = specific_function %impl.elem0.loc6_7.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc6_7.2: <bound method> = bound_method %int_1, %specific_fn.loc6_7.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6: init %u2 = call %bound_method.loc6_7.2(%int_1) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_7.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_7.2: %u2 = converted %int_1, %.loc6_7.1 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_7.3: %struct_type.discriminant = struct_literal (%.loc6_7.2) [concrete = constants.%struct.2cb]
// CHECK:STDOUT:   %impl.elem0.loc6_7.2: %.b0b = impl_witness_access constants.%Copy.impl_witness.8d6, element0 [concrete = constants.%UInt.as.Copy.impl.Op.4d1]
// CHECK:STDOUT:   %bound_method.loc6_7.3: <bound method> = bound_method %.loc6_7.2, %impl.elem0.loc6_7.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.1e1]
// CHECK:STDOUT:   %specific_fn.loc6_7.2: <specific function> = specific_function %impl.elem0.loc6_7.2, @UInt.as.Copy.impl.Op(constants.%int_2.ecc) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_7.4: <bound method> = bound_method %.loc6_7.2, %specific_fn.loc6_7.2 [concrete = constants.%bound_method.373]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc6: init %u2 = call %bound_method.loc6_7.4(%.loc6_7.2) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_7.4: ref %Signal = temporary_storage
// CHECK:STDOUT:   %.loc6_7.5: ref %u2 = class_element_access %.loc6_7.4, element0
// CHECK:STDOUT:   %.loc6_7.6: init %u2 to %.loc6_7.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc6 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc6_7.7: ref %.0fa = class_element_access %.loc6_7.4, element1
// CHECK:STDOUT:   %uninit.loc6: %.0fa = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc6_7.8: init %.0fa to %.loc6_7.7 = in_place_init %uninit.loc6 [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc6_7.9: init %Signal to %.loc6_7.4 = class_init (%.loc6_7.6, %.loc6_7.8) [concrete = constants.%Signal.val.b94]
// CHECK:STDOUT:   %.loc6_7.10: init %Signal = converted %.loc6_7.3, %.loc6_7.9 [concrete = constants.%Signal.val.b94]
// CHECK:STDOUT:   %.loc6_7.11: ref %Signal = temporary %.loc6_7.4, %.loc6_7.10 [concrete = constants.%.763]
// CHECK:STDOUT:   %.loc6_7.12: %Signal = acquire_value %.loc6_7.11 [concrete = constants.%Signal.val.b94]
// CHECK:STDOUT:   %Stop: %Signal = wrapper_binding Stop, %.loc6_7.12
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc8_1.1: %.884 = impl_witness_access constants.%ImplicitAs.impl_witness.2e8, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc8_1.1: <bound method> = bound_method %int_2, %impl.elem0.loc8_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc8_1.1: <specific function> = specific_function %impl.elem0.loc8_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc8_1.2: <bound method> = bound_method %int_2, %specific_fn.loc8_1.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %u2 = call %bound_method.loc8_1.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc8_1.2: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc8_1.3: %u2 = converted %int_2, %.loc8_1.2 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc8_1.4: %struct_type.discriminant = struct_literal (%.loc8_1.3) [concrete = constants.%struct.40a]
// CHECK:STDOUT:   %impl.elem0.loc8_1.2: %.b0b = impl_witness_access constants.%Copy.impl_witness.8d6, element0 [concrete = constants.%UInt.as.Copy.impl.Op.4d1]
// CHECK:STDOUT:   %bound_method.loc8_1.3: <bound method> = bound_method %.loc8_1.3, %impl.elem0.loc8_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.424]
// CHECK:STDOUT:   %specific_fn.loc8_1.2: <specific function> = specific_function %impl.elem0.loc8_1.2, @UInt.as.Copy.impl.Op(constants.%int_2.ecc) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_1.4: <bound method> = bound_method %.loc8_1.3, %specific_fn.loc8_1.2 [concrete = constants.%bound_method.f90]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc8: init %u2 = call %bound_method.loc8_1.4(%.loc8_1.3) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc8_1.5: ref %Signal = temporary_storage
// CHECK:STDOUT:   %.loc8_1.6: ref %u2 = class_element_access %.loc8_1.5, element0
// CHECK:STDOUT:   %.loc8_1.7: init %u2 to %.loc8_1.6 = in_place_init %UInt.as.Copy.impl.Op.call.loc8 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc8_1.8: ref %.0fa = class_element_access %.loc8_1.5, element1
// CHECK:STDOUT:   %uninit.loc8: %.0fa = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc8_1.9: init %.0fa to %.loc8_1.8 = in_place_init %uninit.loc8 [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc8_1.10: init %Signal to %.loc8_1.5 = class_init (%.loc8_1.7, %.loc8_1.9) [concrete = constants.%Signal.val.4b5]
// CHECK:STDOUT:   %.loc8_1.11: init %Signal = converted %.loc8_1.4, %.loc8_1.10 [concrete = constants.%Signal.val.4b5]
// CHECK:STDOUT:   %.loc8_1.12: ref %Signal = temporary %.loc8_1.5, %.loc8_1.11 [concrete = constants.%.8ce]
// CHECK:STDOUT:   %.loc8_1.13: %Signal = acquire_value %.loc8_1.12 [concrete = constants.%Signal.val.4b5]
// CHECK:STDOUT:   %Wait: %Signal = wrapper_binding Wait, %.loc8_1.13
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Signal
// CHECK:STDOUT:   .Go = generated.%Signal.Go.decl
// CHECK:STDOUT:   .Stop = %Stop
// CHECK:STDOUT:   .Wait = %Wait
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Signal.Go(%_.param: %i32) -> out %return.param: %Signal {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc4_15.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc4_15.1: %.884 = impl_witness_access constants.%ImplicitAs.impl_witness.2e8, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc4_15.1: <bound method> = bound_method %int_0, %impl.elem0.loc4_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:   %specific_fn.loc4_15.1: <specific function> = specific_function %impl.elem0.loc4_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc4_15.2: <bound method> = bound_method %int_0, %specific_fn.loc4_15.1 [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc4_15.2(%int_0) [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc4_15.2: init %u2 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc4_15.3: init %u2 to %.loc4_15.1 = in_place_init %.loc4_15.2 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc4_15.4: ref %.0fa = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc4_15.5: ref %tuple.type.a8a = class_element_access %.loc4_15.4, element0
// CHECK:STDOUT:   %.loc5_17.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc4_15.2: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc4_15.3: <bound method> = bound_method %_.param, %impl.elem0.loc4_15.2
// CHECK:STDOUT:   %specific_fn.loc4_15.2: <specific function> = specific_function %impl.elem0.loc4_15.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc4_15.4: <bound method> = bound_method %_.param, %specific_fn.loc4_15.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc4_15.4(%_.param)
// CHECK:STDOUT:   %.loc5_17.2: init %tuple.type.a8a to %.loc4_15.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc4_15.6: init %tuple.type.a8a = converted %.loc5_17.1, %.loc5_17.2
// CHECK:STDOUT:   %.loc4_15.7: init %tuple.type.a8a to %.loc4_15.5 = in_place_init %.loc4_15.6
// CHECK:STDOUT:   %.loc4_15.8: init %Signal to %return.param = class_init (%.loc4_15.3, %.loc4_15.7)
// CHECK:STDOUT:   return %.loc4_15.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify(%s.param: %Signal) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.ref: %Signal = name_ref s, %s
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.1de = expr_pattern %Stop.ref in [concrete] {
// CHECK:STDOUT:       %Stop.ref: %Signal = name_ref Stop, @Signal.%Stop
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Stop.ref: %Signal = name_ref Stop, @Signal.%Stop
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14_16.1: %.884 = impl_witness_access constants.%ImplicitAs.impl_witness.2e8, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc14_16.1: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc14_16.1: <specific function> = specific_function %impl.elem0.loc14_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc14_16.2: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14_16.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_16: init %u2 = call %bound_method.loc14_16.2(%int_1.loc14) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc14_16.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_16 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc14_16.2: %u2 = converted %int_1.loc14, %.loc14_16.1 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc14_16.3: ref %u2 = class_element_access %s.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc14_16.2: %.616 = impl_witness_access constants.%EqWith.impl_witness.db5, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc14_16.3: <bound method> = bound_method %.loc14_16.2, %impl.elem0.loc14_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc14_16.2: <specific function> = specific_function %impl.elem0.loc14_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc14_16.4: <bound method> = bound_method %.loc14_16.2, %specific_fn.loc14_16.2 [concrete = constants.%bound_method.1da]
// CHECK:STDOUT:   %.loc14_16.4: %u2 = acquire_value %.loc14_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc14_16.4(%.loc14_16.2, %.loc14_16.4)
// CHECK:STDOUT:   %.loc14_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc14_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc14_16.5
// CHECK:STDOUT:   if %.loc14_16.6 br !match.case.then.loc14 else br !match.case.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc14:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_29: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_29.1: <bound method> = bound_method %int_0, %impl.elem0.loc14_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc14_29: <specific function> = specific_function %impl.elem0.loc14_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_29.2: <bound method> = bound_method %int_0, %specific_fn.loc14_29 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_29: init %i32 = call %bound_method.loc14_29.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc14_29: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_29 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc14_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc14:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %other.patt: %pattern_type.1de = value_binding_pattern other [concrete = constants.%other.patt.ae2]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then.loc19 else br !match.case.else.loc19
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc19:
// CHECK:STDOUT:   %Signal.ref.loc19: type = name_ref Signal, file.%Signal.decl [concrete = constants.%Signal]
// CHECK:STDOUT:   %other: %Signal = wrapper_binding other, %s.ref
// CHECK:STDOUT:   %int_1.loc19: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc19: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_37.1: <bound method> = bound_method %int_1.loc19, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_37.2: <bound method> = bound_method %int_1.loc19, %specific_fn.loc19 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_37.2(%int_1.loc19) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc19: init %i32 = converted %int_1.loc19, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc19
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc19:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc21: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc21_10: <bound method> = bound_method %int_1.loc21, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc21_10(%int_1.loc21) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc21_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc21: <specific function> = specific_function %impl.elem0.loc21, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc21_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc21 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc21_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc21_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc21_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21: init %i32 = call %bound_method.loc21_12.2(%.loc21_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc21_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc21_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- only_binding_arm.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Flag: type = class_type @Flag [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %complete_type.3a6: <witness> = complete_type_witness %struct_type.discriminant [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %struct.249: %struct_type.discriminant = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.334: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.334) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.703: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.952: type = fn_type_with_self_type %Copy.WithSelf.Op.type.703, %Copy.facet [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.bd0: <bound method> = bound_method %int_0.1a7, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.61c: <bound method> = bound_method %int_0.1a7, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Flag.val.246: %Flag = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %.a8b: ref %Flag = temporary invalid, %Flag.val.246 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.a79: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.332: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Flag.val.cba: %Flag = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %.c9b: ref %Flag = temporary invalid, %Flag.val.cba [concrete]
// CHECK:STDOUT:   %pattern_type.5bc: type = pattern_type %Flag [concrete]
// CHECK:STDOUT:   %f.param_patt: %pattern_type.5bc = value_param_pattern [concrete]
// CHECK:STDOUT:   %f.patt: %pattern_type.5bc = wrapper_binding_pattern f, %f.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %whole.patt: %pattern_type.5bc = value_binding_pattern whole [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.7ff: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Flag.decl: type = class_decl @Flag [concrete = constants.%Flag] {} {}
// CHECK:STDOUT:   %Consume.decl: %Consume.type = fn_decl @Consume [concrete = constants.%Consume] {
// CHECK:STDOUT:     %f.param_patt: %pattern_type.5bc = value_param_pattern [concrete = constants.%f.param_patt]
// CHECK:STDOUT:     %f.patt: %pattern_type.5bc = wrapper_binding_pattern f, %f.param_patt [concrete = constants.%f.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %f.param: %Flag = value_param call_param0
// CHECK:STDOUT:     %Flag.ref.loc10: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:     %f: %Flag = wrapper_binding f, %f.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Flag {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc5_6.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc5_6.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_6.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc5_6.1: <specific function> = specific_function %impl.elem0.loc5_6.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc5_6.2: <bound method> = bound_method %int_0, %specific_fn.loc5_6.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5: init %u1 = call %bound_method.loc5_6.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.2: %u1 = converted %int_0, %.loc5_6.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.3: %struct_type.discriminant = struct_literal (%.loc5_6.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:   %impl.elem0.loc5_6.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc5_6.3: <bound method> = bound_method %.loc5_6.2, %impl.elem0.loc5_6.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.bd0]
// CHECK:STDOUT:   %specific_fn.loc5_6.2: <specific function> = specific_function %impl.elem0.loc5_6.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_6.4: <bound method> = bound_method %.loc5_6.2, %specific_fn.loc5_6.2 [concrete = constants.%bound_method.61c]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc5: init %u1 = call %bound_method.loc5_6.4(%.loc5_6.2) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.4: ref %Flag = temporary_storage
// CHECK:STDOUT:   %.loc5_6.5: ref %u1 = class_element_access %.loc5_6.4, element0
// CHECK:STDOUT:   %.loc5_6.6: init %u1 to %.loc5_6.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc5 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc5_6.7: init %Flag to %.loc5_6.4 = class_init (%.loc5_6.6) [concrete = constants.%Flag.val.246]
// CHECK:STDOUT:   %.loc5_6.8: init %Flag = converted %.loc5_6.3, %.loc5_6.7 [concrete = constants.%Flag.val.246]
// CHECK:STDOUT:   %.loc5_6.9: ref %Flag = temporary %.loc5_6.4, %.loc5_6.8 [concrete = constants.%.a8b]
// CHECK:STDOUT:   %.loc5_6.10: %Flag = acquire_value %.loc5_6.9 [concrete = constants.%Flag.val.246]
// CHECK:STDOUT:   %Off: %Flag = wrapper_binding Off, %.loc5_6.10
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc7_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc7_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc7_1.1: <specific function> = specific_function %impl.elem0.loc7_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc7_1.2: <bound method> = bound_method %int_1, %specific_fn.loc7_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %u1 = call %bound_method.loc7_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.2: %u1 = converted %int_1, %.loc7_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.3: %struct_type.discriminant = struct_literal (%.loc7_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:   %impl.elem0.loc7_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc7_1.3: <bound method> = bound_method %.loc7_1.2, %impl.elem0.loc7_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.332]
// CHECK:STDOUT:   %specific_fn.loc7_1.2: <specific function> = specific_function %impl.elem0.loc7_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_1.4: <bound method> = bound_method %.loc7_1.2, %specific_fn.loc7_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc7: init %u1 = call %bound_method.loc7_1.4(%.loc7_1.2) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.4: ref %Flag = temporary_storage
// CHECK:STDOUT:   %.loc7_1.5: ref %u1 = class_element_access %.loc7_1.4, element0
// CHECK:STDOUT:   %.loc7_1.6: init %u1 to %.loc7_1.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc7 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc7_1.7: init %Flag to %.loc7_1.4 = class_init (%.loc7_1.6) [concrete = constants.%Flag.val.cba]
// CHECK:STDOUT:   %.loc7_1.8: init %Flag = converted %.loc7_1.3, %.loc7_1.7 [concrete = constants.%Flag.val.cba]
// CHECK:STDOUT:   %.loc7_1.9: ref %Flag = temporary %.loc7_1.4, %.loc7_1.8 [concrete = constants.%.c9b]
// CHECK:STDOUT:   %.loc7_1.10: %Flag = acquire_value %.loc7_1.9 [concrete = constants.%Flag.val.cba]
// CHECK:STDOUT:   %On: %Flag = wrapper_binding On, %.loc7_1.10
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Flag
// CHECK:STDOUT:   .Off = %Off
// CHECK:STDOUT:   .On = %On
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Consume(%f.param: %Flag) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %f.ref: %Flag = name_ref f, %f
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %whole.patt: %pattern_type.5bc = value_binding_pattern whole [concrete = constants.%whole.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %Flag.ref.loc16: type = name_ref Flag, file.%Flag.decl [concrete = constants.%Flag]
// CHECK:STDOUT:   %whole: %Flag = wrapper_binding whole, %f.ref
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %impl.elem0.loc16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_35.1: <bound method> = bound_method %int_7, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_35.2: <bound method> = bound_method %int_7, %specific_fn.loc16 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_35.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc16: init %i32 = converted %int_7, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   return %.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc18_10: <bound method> = bound_method %int_1, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc18_10(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc18: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc18 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc18: <specific function> = specific_function %impl.elem0.loc18, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc18_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc18 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc18_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc18_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc18_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18: init %i32 = call %bound_method.loc18_12.2(%.loc18_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc18_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc18_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
