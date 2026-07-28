// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/binding_choice_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/binding_choice_scrutinee.carbon

// A `case` binding pattern also binds a choice-typed scrutinee's value, and
// the bound value can itself be matched again in the arm's body — a nested
// match through a case binding (re-platform plan S2b; nested-match stack
// discipline per risks R-2/R-8).
//@dump-sem-ir-begin
choice Signal {
  Go(speed: i32),
  Stop,
  Wait
}

fn Classify(s: Signal) -> i32 {
  match (s) {
    case .Stop => { return 0; }
    case c: Signal => {
      match (c) {
        case .Wait => { return 1; }
        default => { return 2; }
      }
    }
    default => { return 3; }
  }
  return -1;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- binding_choice_scrutinee.carbon
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
// CHECK:STDOUT:   %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete]
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
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.0e0: <witness> = impl_witness imports.%Copy.impl_witness_table.367, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.987: %Copy.type = facet_value %i32, (%Copy.impl_witness.0e0) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d09: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.987) [concrete]
// CHECK:STDOUT:   %.7a6: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d09, %Copy.facet.987 [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.409 [concrete]
// CHECK:STDOUT:   %bound_method.0f5: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72 [concrete]
// CHECK:STDOUT:   %int_1.508: %u2 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.2cb: %struct_type.discriminant = struct_value (%int_1.508) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.f92: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.d68: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.4d1: %UInt.as.Copy.impl.Op.type.d68 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.842: %Copy.type = facet_value %u2, (%Copy.impl_witness.f92) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.21e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.842) [concrete]
// CHECK:STDOUT:   %.594: type = fn_type_with_self_type %Copy.WithSelf.Op.type.21e, %Copy.facet.842 [concrete]
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
// CHECK:STDOUT:   %s.patt: %pattern_type.1de = at_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Classify.type: type = fn_type @Classify [concrete]
// CHECK:STDOUT:   %Classify: %Classify.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.f24: type = facet_type <@EqWith, @EqWith(%u2)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.454: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.5fc: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_2.ecc, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.e76: %UInt.as.EqWith.impl.Equal.type.5fc = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.16f: %EqWith.type.f24 = facet_value %u2, (%EqWith.impl_witness.454) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.c65: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u2, %EqWith.facet.16f) [concrete]
// CHECK:STDOUT:   %.7a0: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.c65, %EqWith.facet.16f [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f51: <bound method> = bound_method %int_1.508, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.149: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.e76, @UInt.as.EqWith.impl.Equal.1(%int_2.ecc, %int_2.ecc) [concrete]
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
// CHECK:STDOUT:   %c.patt: %pattern_type.1de = value_binding_pattern c [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.99a: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.e76 [concrete]
// CHECK:STDOUT:   %bound_method.64f: <bound method> = bound_method %int_2.996, %UInt.as.EqWith.impl.Equal.specific_fn.149 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.367 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Signal.Go.decl: %Signal.Go.type = fn_decl @Signal.Go [concrete = constants.%Signal.Go] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.6b6 = at_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.1de = out_param_pattern [concrete = constants.%return.param_patt.463]
// CHECK:STDOUT:     %return.patt: %pattern_type.1de = return_slot_pattern %return.param_patt, constants.%Signal [concrete = constants.%return.patt.a55]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc18_15.9: Core.Form = init_form constants.%Signal [concrete = constants.%.1d7]
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
// CHECK:STDOUT:     %s.patt: %pattern_type.1de = at_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc24: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %s.param: %Signal = value_param call_param0
// CHECK:STDOUT:     %Signal.ref.loc24: type = name_ref Signal, file.%Signal.decl [concrete = constants.%Signal]
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
// CHECK:STDOUT:   %.loc22_1.1: type = custom_layout_type {size=4, align=4, .Go@0: %tuple.type.a8a} [concrete = constants.%.0fa]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.de4 [concrete = constants.%complete_type.b1b]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc20_7.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc20_7.1: <bound method> = bound_method %int_1, %impl.elem0.loc20_7.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc20_7.1: <specific function> = specific_function %impl.elem0.loc20_7.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc20_7.2: <bound method> = bound_method %int_1, %specific_fn.loc20_7.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20: init %u2 = call %bound_method.loc20_7.2(%int_1) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc20_7.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc20_7.2: %u2 = converted %int_1, %.loc20_7.1 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc20_7.3: %struct_type.discriminant = struct_literal (%.loc20_7.2) [concrete = constants.%struct.2cb]
// CHECK:STDOUT:   %impl.elem0.loc20_7.2: %.594 = impl_witness_access constants.%Copy.impl_witness.f92, element0 [concrete = constants.%UInt.as.Copy.impl.Op.4d1]
// CHECK:STDOUT:   %bound_method.loc20_7.3: <bound method> = bound_method %.loc20_7.2, %impl.elem0.loc20_7.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.1e1]
// CHECK:STDOUT:   %specific_fn.loc20_7.2: <specific function> = specific_function %impl.elem0.loc20_7.2, @UInt.as.Copy.impl.Op(constants.%int_2.ecc) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc20_7.4: <bound method> = bound_method %.loc20_7.2, %specific_fn.loc20_7.2 [concrete = constants.%bound_method.373]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc20: init %u2 = call %bound_method.loc20_7.4(%.loc20_7.2) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc20_7.4: ref %Signal = temporary_storage
// CHECK:STDOUT:   %.loc20_7.5: ref %u2 = class_element_access %.loc20_7.4, element0
// CHECK:STDOUT:   %.loc20_7.6: init %u2 to %.loc20_7.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc20 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc20_7.7: ref %.0fa = class_element_access %.loc20_7.4, element1
// CHECK:STDOUT:   %uninit.loc20: %.0fa = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc20_7.8: init %.0fa to %.loc20_7.7 = in_place_init %uninit.loc20 [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc20_7.9: init %Signal to %.loc20_7.4 = class_init (%.loc20_7.6, %.loc20_7.8) [concrete = constants.%Signal.val.b94]
// CHECK:STDOUT:   %.loc20_7.10: init %Signal = converted %.loc20_7.3, %.loc20_7.9 [concrete = constants.%Signal.val.b94]
// CHECK:STDOUT:   %.loc20_7.11: ref %Signal = temporary %.loc20_7.4, %.loc20_7.10 [concrete = constants.%.763]
// CHECK:STDOUT:   %.loc20_7.12: %Signal = acquire_value %.loc20_7.11 [concrete = constants.%Signal.val.b94]
// CHECK:STDOUT:   %Stop: %Signal = wrapper_binding Stop, %.loc20_7.12
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc22_1.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc22_1.1: <bound method> = bound_method %int_2, %impl.elem0.loc22_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc22_1.1: <specific function> = specific_function %impl.elem0.loc22_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc22_1.2: <bound method> = bound_method %int_2, %specific_fn.loc22_1.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22: init %u2 = call %bound_method.loc22_1.2(%int_2) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc22_1.2: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc22_1.3: %u2 = converted %int_2, %.loc22_1.2 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc22_1.4: %struct_type.discriminant = struct_literal (%.loc22_1.3) [concrete = constants.%struct.40a]
// CHECK:STDOUT:   %impl.elem0.loc22_1.2: %.594 = impl_witness_access constants.%Copy.impl_witness.f92, element0 [concrete = constants.%UInt.as.Copy.impl.Op.4d1]
// CHECK:STDOUT:   %bound_method.loc22_1.3: <bound method> = bound_method %.loc22_1.3, %impl.elem0.loc22_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.424]
// CHECK:STDOUT:   %specific_fn.loc22_1.2: <specific function> = specific_function %impl.elem0.loc22_1.2, @UInt.as.Copy.impl.Op(constants.%int_2.ecc) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc22_1.4: <bound method> = bound_method %.loc22_1.3, %specific_fn.loc22_1.2 [concrete = constants.%bound_method.f90]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc22: init %u2 = call %bound_method.loc22_1.4(%.loc22_1.3) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc22_1.5: ref %Signal = temporary_storage
// CHECK:STDOUT:   %.loc22_1.6: ref %u2 = class_element_access %.loc22_1.5, element0
// CHECK:STDOUT:   %.loc22_1.7: init %u2 to %.loc22_1.6 = in_place_init %UInt.as.Copy.impl.Op.call.loc22 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc22_1.8: ref %.0fa = class_element_access %.loc22_1.5, element1
// CHECK:STDOUT:   %uninit.loc22: %.0fa = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc22_1.9: init %.0fa to %.loc22_1.8 = in_place_init %uninit.loc22 [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc22_1.10: init %Signal to %.loc22_1.5 = class_init (%.loc22_1.7, %.loc22_1.9) [concrete = constants.%Signal.val.4b5]
// CHECK:STDOUT:   %.loc22_1.11: init %Signal = converted %.loc22_1.4, %.loc22_1.10 [concrete = constants.%Signal.val.4b5]
// CHECK:STDOUT:   %.loc22_1.12: ref %Signal = temporary %.loc22_1.5, %.loc22_1.11 [concrete = constants.%.8ce]
// CHECK:STDOUT:   %.loc22_1.13: %Signal = acquire_value %.loc22_1.12 [concrete = constants.%Signal.val.4b5]
// CHECK:STDOUT:   %Wait: %Signal = wrapper_binding Wait, %.loc22_1.13
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
// CHECK:STDOUT:   %.loc18_15.1: ref %u2 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc18_15.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc18_15.1: <bound method> = bound_method %int_0, %impl.elem0.loc18_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.941]
// CHECK:STDOUT:   %specific_fn.loc18_15.1: <specific function> = specific_function %impl.elem0.loc18_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc18_15.2: <bound method> = bound_method %int_0, %specific_fn.loc18_15.1 [concrete = constants.%bound_method.6ef]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u2 = call %bound_method.loc18_15.2(%int_0) [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc18_15.2: init %u2 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc18_15.3: init %u2 to %.loc18_15.1 = in_place_init %.loc18_15.2 [concrete = constants.%int_0.336]
// CHECK:STDOUT:   %.loc18_15.4: ref %.0fa = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc18_15.5: ref %tuple.type.a8a = class_element_access %.loc18_15.4, element0
// CHECK:STDOUT:   %.loc19_17.1: %tuple.type.a8a = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc18_15.2: %.7a6 = impl_witness_access constants.%Copy.impl_witness.0e0, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc18_15.3: <bound method> = bound_method %_.param, %impl.elem0.loc18_15.2
// CHECK:STDOUT:   %specific_fn.loc18_15.2: <specific function> = specific_function %impl.elem0.loc18_15.2, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc18_15.4: <bound method> = bound_method %_.param, %specific_fn.loc18_15.2
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc18_15.4(%_.param)
// CHECK:STDOUT:   %.loc19_17.2: init %tuple.type.a8a to %.loc18_15.5 = tuple_init (%Int.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc18_15.6: init %tuple.type.a8a = converted %.loc19_17.1, %.loc19_17.2
// CHECK:STDOUT:   %.loc18_15.7: init %tuple.type.a8a to %.loc18_15.5 = in_place_init %.loc18_15.6
// CHECK:STDOUT:   %.loc18_15.8: init %Signal to %return.param = class_init (%.loc18_15.3, %.loc18_15.7)
// CHECK:STDOUT:   return %.loc18_15.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Classify(%s.param: %Signal) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.ref: %Signal = name_ref s, %s
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc26: %pattern_type.1de = expr_pattern %Stop.ref in [concrete] {
// CHECK:STDOUT:       %Stop.ref: %Signal = name_ref Stop, @Signal.%Stop
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Stop.ref: %Signal = name_ref Stop, @Signal.%Stop
// CHECK:STDOUT:   %int_1.loc26: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc26_16.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc26_16.1: <bound method> = bound_method %int_1.loc26, %impl.elem0.loc26_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.48e]
// CHECK:STDOUT:   %specific_fn.loc26_16.1: <specific function> = specific_function %impl.elem0.loc26_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc26_16.2: <bound method> = bound_method %int_1.loc26, %specific_fn.loc26_16.1 [concrete = constants.%bound_method.0f5]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26_16: init %u2 = call %bound_method.loc26_16.2(%int_1.loc26) [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc26_16.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26_16 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc26_16.2: %u2 = converted %int_1.loc26, %.loc26_16.1 [concrete = constants.%int_1.508]
// CHECK:STDOUT:   %.loc26_16.3: ref %u2 = class_element_access %s.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc26_16.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc26_16.3: <bound method> = bound_method %.loc26_16.2, %impl.elem0.loc26_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f51]
// CHECK:STDOUT:   %specific_fn.loc26_16.2: <specific function> = specific_function %impl.elem0.loc26_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc26_16.4: <bound method> = bound_method %.loc26_16.2, %specific_fn.loc26_16.2 [concrete = constants.%bound_method.1da]
// CHECK:STDOUT:   %.loc26_16.4: %u2 = acquire_value %.loc26_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc26: init bool = call %bound_method.loc26_16.4(%.loc26_16.2, %.loc26_16.4)
// CHECK:STDOUT:   %.loc26_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc26
// CHECK:STDOUT:   %.loc26_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc26, %.loc26_16.5
// CHECK:STDOUT:   if %.loc26_16.6 br !match.case.then.loc26 else br !match.case.else.loc26
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc26:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc26_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc26_29.1: <bound method> = bound_method %int_0, %impl.elem0.loc26_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc26_29: <specific function> = specific_function %impl.elem0.loc26_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc26_29.2: <bound method> = bound_method %int_0, %specific_fn.loc26_29 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26_29: init %i32 = call %bound_method.loc26_29.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc26_29: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26_29 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc26_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc26:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %c.patt: %pattern_type.1de = value_binding_pattern c [concrete = constants.%c.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !match.case.then.loc27 else br !match.case.else.loc27
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc27:
// CHECK:STDOUT:   %Signal.ref.loc27: type = name_ref Signal, file.%Signal.decl [concrete = constants.%Signal]
// CHECK:STDOUT:   %c: %Signal = wrapper_binding c, %s.ref
// CHECK:STDOUT:   %c.ref: %Signal = name_ref c, %c
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc29: %pattern_type.1de = expr_pattern %Wait.ref in [concrete] {
// CHECK:STDOUT:       %Wait.ref: %Signal = name_ref Wait, @Signal.%Wait
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Wait.ref: %Signal = name_ref Wait, @Signal.%Wait
// CHECK:STDOUT:   %int_2.loc29: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc29_20.1: %.66c = impl_witness_access constants.%ImplicitAs.impl_witness.e93, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.409]
// CHECK:STDOUT:   %bound_method.loc29_20.1: <bound method> = bound_method %int_2.loc29, %impl.elem0.loc29_20.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.6c9]
// CHECK:STDOUT:   %specific_fn.loc29_20.1: <specific function> = specific_function %impl.elem0.loc29_20.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_2.ecc) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.a72]
// CHECK:STDOUT:   %bound_method.loc29_20.2: <bound method> = bound_method %int_2.loc29, %specific_fn.loc29_20.1 [concrete = constants.%bound_method.135]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_20: init %u2 = call %bound_method.loc29_20.2(%int_2.loc29) [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc29_20.1: %u2 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_20 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc29_20.2: %u2 = converted %int_2.loc29, %.loc29_20.1 [concrete = constants.%int_2.996]
// CHECK:STDOUT:   %.loc29_20.3: ref %u2 = class_element_access %c.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc29_20.2: %.7a0 = impl_witness_access constants.%EqWith.impl_witness.454, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.e76]
// CHECK:STDOUT:   %bound_method.loc29_20.3: <bound method> = bound_method %.loc29_20.2, %impl.elem0.loc29_20.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.99a]
// CHECK:STDOUT:   %specific_fn.loc29_20.2: <specific function> = specific_function %impl.elem0.loc29_20.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_2.ecc, constants.%int_2.ecc) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.149]
// CHECK:STDOUT:   %bound_method.loc29_20.4: <bound method> = bound_method %.loc29_20.2, %specific_fn.loc29_20.2 [concrete = constants.%bound_method.64f]
// CHECK:STDOUT:   %.loc29_20.4: %u2 = acquire_value %.loc29_20.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc29: init bool = call %bound_method.loc29_20.4(%.loc29_20.2, %.loc29_20.4)
// CHECK:STDOUT:   %.loc29_20.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc29
// CHECK:STDOUT:   %.loc29_20.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc29, %.loc29_20.5
// CHECK:STDOUT:   if %.loc29_20.6 br !match.case.then.loc29 else br !match.case.else.loc29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc29:
// CHECK:STDOUT:   %int_1.loc29: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc29_33: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc29_33.1: <bound method> = bound_method %int_1.loc29, %impl.elem0.loc29_33 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc29_33: <specific function> = specific_function %impl.elem0.loc29_33, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc29_33.2: <bound method> = bound_method %int_1.loc29, %specific_fn.loc29_33 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_33: init %i32 = call %bound_method.loc29_33.2(%int_1.loc29) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc29_33: init %i32 = converted %int_1.loc29, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc29_33 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc29_33
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc29:
// CHECK:STDOUT:   %int_2.loc30: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc30: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc30_30.1: <bound method> = bound_method %int_2.loc30, %impl.elem0.loc30 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc30: <specific function> = specific_function %impl.elem0.loc30, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc30_30.2: <bound method> = bound_method %int_2.loc30, %specific_fn.loc30 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30: init %i32 = call %bound_method.loc30_30.2(%int_2.loc30) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc30: init %i32 = converted %int_2.loc30, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc30
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc27:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc33: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc33_26.1: <bound method> = bound_method %int_3, %impl.elem0.loc33 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc33: <specific function> = specific_function %impl.elem0.loc33, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc33_26.2: <bound method> = bound_method %int_3, %specific_fn.loc33 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33: init %i32 = call %bound_method.loc33_26.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc33: init %i32 = converted %int_3, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   return %.loc33
// CHECK:STDOUT: }
// CHECK:STDOUT:
