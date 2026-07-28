// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/nested_choice_designator.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/nested_choice_designator.carbon

// Designator patterns in a match nested inside another match's arms: the
// designator's scrutinee lookup and the node-stack scrutinee protocol must
// hold across the per-arm pattern context (re-platform plan R-8).

//@dump-sem-ir-begin
choice Color {
  Red,
  Green
}

choice Shape {
  Circle,
  Square
}

fn F(c: Color, s: Shape) -> i32 {
  match (c) {
    case .Red => {
      match (s) {
        case .Circle => { return 1; }
        default => { return 2; }
      }
    }
    default => {
      match (s) {
        case .Square => { return 3; }
        default => { return 4; }
      }
    }
  }
  return 0;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- nested_choice_designator.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Color: type = class_type @Color [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness.9a9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.42f, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.115: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.9a9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.19e: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.115) [concrete]
// CHECK:STDOUT:   %.e60: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.19e, %ImplicitAs.facet.115 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %struct.249: %struct_type.discriminant = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.fb7: <witness> = impl_witness imports.%Copy.impl_witness_table.fe3, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %u1, (%Copy.impl_witness.fb7) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.4d4: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.37a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.4d4, %Copy.facet [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.bd0: <bound method> = bound_method %int_0.1a7, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.61c: <bound method> = bound_method %int_0.1a7, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Color.val.d5e: %Color = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %.78d: ref %Color = temporary invalid, %Color.val.d5e [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct.a79: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound.332: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %Color.val.192: %Color = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %.596: ref %Color = temporary invalid, %Color.val.192 [concrete]
// CHECK:STDOUT:   %Shape: type = class_type @Shape [concrete]
// CHECK:STDOUT:   %Shape.val.a0c: %Shape = struct_value (%int_0.1a7) [concrete]
// CHECK:STDOUT:   %.43c: ref %Shape = temporary invalid, %Shape.val.a0c [concrete]
// CHECK:STDOUT:   %Shape.val.c47: %Shape = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %.d08: ref %Shape = temporary invalid, %Shape.val.c47 [concrete]
// CHECK:STDOUT:   %pattern_type.423: type = pattern_type %Color [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.423 = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.423 = at_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %pattern_type.6e5: type = pattern_type %Shape [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.6e5 = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.6e5 = at_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.d63: <witness> = impl_witness imports.%EqWith.impl_witness_table.cbd, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.3b6: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.d63) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.922: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.3b6) [concrete]
// CHECK:STDOUT:   %.9ed: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.922, %EqWith.facet.3b6 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.9f1: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.9f1) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet.9f1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.b7a: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_4.4eb: %i32 = int_value 4 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.42f = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.fe3 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.cbd = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Color.decl: type = class_decl @Color [concrete = constants.%Color] {} {}
// CHECK:STDOUT:   %Shape.decl: type = class_decl @Shape [concrete = constants.%Shape] {} {}
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.423 = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.423 = at_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %s.param_patt: %pattern_type.6e5 = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.6e5 = at_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc28: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %c.param: %Color = value_param call_param0
// CHECK:STDOUT:     %Color.ref: type = name_ref Color, file.%Color.decl [concrete = constants.%Color]
// CHECK:STDOUT:     %c: %Color = wrapper_binding c, %c.param
// CHECK:STDOUT:     %s.param: %Shape = value_param call_param1
// CHECK:STDOUT:     %Shape.ref: type = name_ref Shape, file.%Shape.decl [concrete = constants.%Shape]
// CHECK:STDOUT:     %s: %Shape = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Color {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc19_6.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc19_6.1: <bound method> = bound_method %int_0, %impl.elem0.loc19_6.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc19_6.1: <specific function> = specific_function %impl.elem0.loc19_6.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc19_6.2: <bound method> = bound_method %int_0, %specific_fn.loc19_6.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %u1 = call %bound_method.loc19_6.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_6.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_6.2: %u1 = converted %int_0, %.loc19_6.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_6.3: %struct_type.discriminant = struct_literal (%.loc19_6.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:   %impl.elem0.loc19_6.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc19_6.3: <bound method> = bound_method %.loc19_6.2, %impl.elem0.loc19_6.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.bd0]
// CHECK:STDOUT:   %specific_fn.loc19_6.2: <specific function> = specific_function %impl.elem0.loc19_6.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc19_6.4: <bound method> = bound_method %.loc19_6.2, %specific_fn.loc19_6.2 [concrete = constants.%bound_method.61c]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc19: init %u1 = call %bound_method.loc19_6.4(%.loc19_6.2) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_6.4: ref %Color = temporary_storage
// CHECK:STDOUT:   %.loc19_6.5: ref %u1 = class_element_access %.loc19_6.4, element0
// CHECK:STDOUT:   %.loc19_6.6: init %u1 to %.loc19_6.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc19 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc19_6.7: init %Color to %.loc19_6.4 = class_init (%.loc19_6.6) [concrete = constants.%Color.val.d5e]
// CHECK:STDOUT:   %.loc19_6.8: init %Color = converted %.loc19_6.3, %.loc19_6.7 [concrete = constants.%Color.val.d5e]
// CHECK:STDOUT:   %.loc19_6.9: ref %Color = temporary %.loc19_6.4, %.loc19_6.8 [concrete = constants.%.78d]
// CHECK:STDOUT:   %.loc19_6.10: %Color = acquire_value %.loc19_6.9 [concrete = constants.%Color.val.d5e]
// CHECK:STDOUT:   %Red: %Color = wrapper_binding Red, %.loc19_6.10
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc21_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc21_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc21_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc21_1.1: <specific function> = specific_function %impl.elem0.loc21_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc21_1.2: <bound method> = bound_method %int_1, %specific_fn.loc21_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21: init %u1 = call %bound_method.loc21_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc21_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc21_1.2: %u1 = converted %int_1, %.loc21_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc21_1.3: %struct_type.discriminant = struct_literal (%.loc21_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:   %impl.elem0.loc21_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc21_1.3: <bound method> = bound_method %.loc21_1.2, %impl.elem0.loc21_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.332]
// CHECK:STDOUT:   %specific_fn.loc21_1.2: <specific function> = specific_function %impl.elem0.loc21_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc21_1.4: <bound method> = bound_method %.loc21_1.2, %specific_fn.loc21_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc21: init %u1 = call %bound_method.loc21_1.4(%.loc21_1.2) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc21_1.4: ref %Color = temporary_storage
// CHECK:STDOUT:   %.loc21_1.5: ref %u1 = class_element_access %.loc21_1.4, element0
// CHECK:STDOUT:   %.loc21_1.6: init %u1 to %.loc21_1.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc21 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc21_1.7: init %Color to %.loc21_1.4 = class_init (%.loc21_1.6) [concrete = constants.%Color.val.192]
// CHECK:STDOUT:   %.loc21_1.8: init %Color = converted %.loc21_1.3, %.loc21_1.7 [concrete = constants.%Color.val.192]
// CHECK:STDOUT:   %.loc21_1.9: ref %Color = temporary %.loc21_1.4, %.loc21_1.8 [concrete = constants.%.596]
// CHECK:STDOUT:   %.loc21_1.10: %Color = acquire_value %.loc21_1.9 [concrete = constants.%Color.val.192]
// CHECK:STDOUT:   %Green: %Color = wrapper_binding Green, %.loc21_1.10
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Color
// CHECK:STDOUT:   .Red = %Red
// CHECK:STDOUT:   .Green = %Green
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Shape {
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant [concrete = constants.%complete_type.3a6]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc24_9.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc24_9.1: <bound method> = bound_method %int_0, %impl.elem0.loc24_9.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc24_9.1: <specific function> = specific_function %impl.elem0.loc24_9.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc24_9.2: <bound method> = bound_method %int_0, %specific_fn.loc24_9.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24: init %u1 = call %bound_method.loc24_9.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc24_9.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc24_9.2: %u1 = converted %int_0, %.loc24_9.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc24_9.3: %struct_type.discriminant = struct_literal (%.loc24_9.2) [concrete = constants.%struct.249]
// CHECK:STDOUT:   %impl.elem0.loc24_9.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc24_9.3: <bound method> = bound_method %.loc24_9.2, %impl.elem0.loc24_9.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.bd0]
// CHECK:STDOUT:   %specific_fn.loc24_9.2: <specific function> = specific_function %impl.elem0.loc24_9.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc24_9.4: <bound method> = bound_method %.loc24_9.2, %specific_fn.loc24_9.2 [concrete = constants.%bound_method.61c]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc24: init %u1 = call %bound_method.loc24_9.4(%.loc24_9.2) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc24_9.4: ref %Shape = temporary_storage
// CHECK:STDOUT:   %.loc24_9.5: ref %u1 = class_element_access %.loc24_9.4, element0
// CHECK:STDOUT:   %.loc24_9.6: init %u1 to %.loc24_9.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc24 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc24_9.7: init %Shape to %.loc24_9.4 = class_init (%.loc24_9.6) [concrete = constants.%Shape.val.a0c]
// CHECK:STDOUT:   %.loc24_9.8: init %Shape = converted %.loc24_9.3, %.loc24_9.7 [concrete = constants.%Shape.val.a0c]
// CHECK:STDOUT:   %.loc24_9.9: ref %Shape = temporary %.loc24_9.4, %.loc24_9.8 [concrete = constants.%.43c]
// CHECK:STDOUT:   %.loc24_9.10: %Shape = acquire_value %.loc24_9.9 [concrete = constants.%Shape.val.a0c]
// CHECK:STDOUT:   %Circle: %Shape = wrapper_binding Circle, %.loc24_9.10
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc26_1.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc26_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc26_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc26_1.1: <specific function> = specific_function %impl.elem0.loc26_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc26_1.2: <bound method> = bound_method %int_1, %specific_fn.loc26_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26: init %u1 = call %bound_method.loc26_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_1.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc26 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_1.2: %u1 = converted %int_1, %.loc26_1.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_1.3: %struct_type.discriminant = struct_literal (%.loc26_1.2) [concrete = constants.%struct.a79]
// CHECK:STDOUT:   %impl.elem0.loc26_1.2: %.37a = impl_witness_access constants.%Copy.impl_witness.fb7, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc26_1.3: <bound method> = bound_method %.loc26_1.2, %impl.elem0.loc26_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound.332]
// CHECK:STDOUT:   %specific_fn.loc26_1.2: <specific function> = specific_function %impl.elem0.loc26_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc26_1.4: <bound method> = bound_method %.loc26_1.2, %specific_fn.loc26_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call.loc26: init %u1 = call %bound_method.loc26_1.4(%.loc26_1.2) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_1.4: ref %Shape = temporary_storage
// CHECK:STDOUT:   %.loc26_1.5: ref %u1 = class_element_access %.loc26_1.4, element0
// CHECK:STDOUT:   %.loc26_1.6: init %u1 to %.loc26_1.5 = in_place_init %UInt.as.Copy.impl.Op.call.loc26 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc26_1.7: init %Shape to %.loc26_1.4 = class_init (%.loc26_1.6) [concrete = constants.%Shape.val.c47]
// CHECK:STDOUT:   %.loc26_1.8: init %Shape = converted %.loc26_1.3, %.loc26_1.7 [concrete = constants.%Shape.val.c47]
// CHECK:STDOUT:   %.loc26_1.9: ref %Shape = temporary %.loc26_1.4, %.loc26_1.8 [concrete = constants.%.d08]
// CHECK:STDOUT:   %.loc26_1.10: %Shape = acquire_value %.loc26_1.9 [concrete = constants.%Shape.val.c47]
// CHECK:STDOUT:   %Square: %Shape = wrapper_binding Square, %.loc26_1.10
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Shape
// CHECK:STDOUT:   .Circle = %Circle
// CHECK:STDOUT:   .Square = %Square
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%c.param: %Color, %s.param: %Shape) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.ref: %Color = name_ref c, %c
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc30: %pattern_type.423 = expr_pattern %Red.ref in [concrete] {
// CHECK:STDOUT:       %Red.ref: %Color = name_ref Red, @Color.%Red
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Red.ref: %Color = name_ref Red, @Color.%Red
// CHECK:STDOUT:   %int_0.loc30: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc30_15.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc30_15.1: <bound method> = bound_method %int_0.loc30, %impl.elem0.loc30_15.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc30_15.1: <specific function> = specific_function %impl.elem0.loc30_15.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc30_15.2: <bound method> = bound_method %int_0.loc30, %specific_fn.loc30_15.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30: init %u1 = call %bound_method.loc30_15.2(%int_0.loc30) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc30_15.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc30 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc30_15.2: %u1 = converted %int_0.loc30, %.loc30_15.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc30_15.3: ref %u1 = class_element_access %c.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc30_15.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc30_15.3: <bound method> = bound_method %.loc30_15.2, %impl.elem0.loc30_15.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc30_15.2: <specific function> = specific_function %impl.elem0.loc30_15.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc30_15.4: <bound method> = bound_method %.loc30_15.2, %specific_fn.loc30_15.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc30_15.4: %u1 = acquire_value %.loc30_15.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc30: init bool = call %bound_method.loc30_15.4(%.loc30_15.2, %.loc30_15.4)
// CHECK:STDOUT:   %.loc30_15.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc30
// CHECK:STDOUT:   %.loc30_15.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc30, %.loc30_15.5
// CHECK:STDOUT:   if %.loc30_15.6 br !match.case.then.loc30 else br !match.case.else.loc30
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc30:
// CHECK:STDOUT:   %s.ref.loc31: %Shape = name_ref s, %s
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc32: %pattern_type.6e5 = expr_pattern %Circle.ref in [concrete] {
// CHECK:STDOUT:       %Circle.ref: %Shape = name_ref Circle, @Shape.%Circle
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Circle.ref: %Shape = name_ref Circle, @Shape.%Circle
// CHECK:STDOUT:   %int_0.loc32: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc32_22.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc32_22.1: <bound method> = bound_method %int_0.loc32, %impl.elem0.loc32_22.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc32_22.1: <specific function> = specific_function %impl.elem0.loc32_22.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc32_22.2: <bound method> = bound_method %int_0.loc32, %specific_fn.loc32_22.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_22: init %u1 = call %bound_method.loc32_22.2(%int_0.loc32) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc32_22.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_22 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc32_22.2: %u1 = converted %int_0.loc32, %.loc32_22.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc32_22.3: ref %u1 = class_element_access %s.ref.loc31, element0
// CHECK:STDOUT:   %impl.elem0.loc32_22.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc32_22.3: <bound method> = bound_method %.loc32_22.2, %impl.elem0.loc32_22.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc32_22.2: <specific function> = specific_function %impl.elem0.loc32_22.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc32_22.4: <bound method> = bound_method %.loc32_22.2, %specific_fn.loc32_22.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc32_22.4: %u1 = acquire_value %.loc32_22.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc32: init bool = call %bound_method.loc32_22.4(%.loc32_22.2, %.loc32_22.4)
// CHECK:STDOUT:   %.loc32_22.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc32
// CHECK:STDOUT:   %.loc32_22.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc32, %.loc32_22.5
// CHECK:STDOUT:   if %.loc32_22.6 br !match.case.then.loc32 else br !match.case.else.loc32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc32:
// CHECK:STDOUT:   %int_1.loc32: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc32_35: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc32_35.1: <bound method> = bound_method %int_1.loc32, %impl.elem0.loc32_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc32_35: <specific function> = specific_function %impl.elem0.loc32_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc32_35.2: <bound method> = bound_method %int_1.loc32, %specific_fn.loc32_35 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_35: init %i32 = call %bound_method.loc32_35.2(%int_1.loc32) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc32_35: init %i32 = converted %int_1.loc32, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_35 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc32_35
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc32:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc33: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc33_30.1: <bound method> = bound_method %int_2, %impl.elem0.loc33 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc33: <specific function> = specific_function %impl.elem0.loc33, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc33_30.2: <bound method> = bound_method %int_2, %specific_fn.loc33 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33: init %i32 = call %bound_method.loc33_30.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc33: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc33
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc30:
// CHECK:STDOUT:   %s.ref.loc37: %Shape = name_ref s, %s
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc38: %pattern_type.6e5 = expr_pattern %Square.ref in [concrete] {
// CHECK:STDOUT:       %Square.ref: %Shape = name_ref Square, @Shape.%Square
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Square.ref: %Shape = name_ref Square, @Shape.%Square
// CHECK:STDOUT:   %int_1.loc38: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc38_22.1: %.e60 = impl_witness_access constants.%ImplicitAs.impl_witness.9a9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc38_22.1: <bound method> = bound_method %int_1.loc38, %impl.elem0.loc38_22.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc38_22.1: <specific function> = specific_function %impl.elem0.loc38_22.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc38_22.2: <bound method> = bound_method %int_1.loc38, %specific_fn.loc38_22.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc38_22: init %u1 = call %bound_method.loc38_22.2(%int_1.loc38) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc38_22.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc38_22 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc38_22.2: %u1 = converted %int_1.loc38, %.loc38_22.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc38_22.3: ref %u1 = class_element_access %s.ref.loc37, element0
// CHECK:STDOUT:   %impl.elem0.loc38_22.2: %.9ed = impl_witness_access constants.%EqWith.impl_witness.d63, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc38_22.3: <bound method> = bound_method %.loc38_22.2, %impl.elem0.loc38_22.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc38_22.2: <specific function> = specific_function %impl.elem0.loc38_22.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc38_22.4: <bound method> = bound_method %.loc38_22.2, %specific_fn.loc38_22.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc38_22.4: %u1 = acquire_value %.loc38_22.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc38: init bool = call %bound_method.loc38_22.4(%.loc38_22.2, %.loc38_22.4)
// CHECK:STDOUT:   %.loc38_22.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc38
// CHECK:STDOUT:   %.loc38_22.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc38, %.loc38_22.5
// CHECK:STDOUT:   if %.loc38_22.6 br !match.case.then.loc38 else br !match.case.else.loc38
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc38:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc38_35: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc38_35.1: <bound method> = bound_method %int_3, %impl.elem0.loc38_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc38_35: <specific function> = specific_function %impl.elem0.loc38_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc38_35.2: <bound method> = bound_method %int_3, %specific_fn.loc38_35 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc38_35: init %i32 = call %bound_method.loc38_35.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc38_35: init %i32 = converted %int_3, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc38_35 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   return %.loc38_35
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc38:
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %impl.elem0.loc39: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc39_30.1: <bound method> = bound_method %int_4, %impl.elem0.loc39 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad]
// CHECK:STDOUT:   %specific_fn.loc39: <specific function> = specific_function %impl.elem0.loc39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc39_30.2: <bound method> = bound_method %int_4, %specific_fn.loc39 [concrete = constants.%bound_method.b7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc39: init %i32 = call %bound_method.loc39_30.2(%int_4) [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc39: init %i32 = converted %int_4, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc39 [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   return %.loc39
// CHECK:STDOUT: }
// CHECK:STDOUT:
