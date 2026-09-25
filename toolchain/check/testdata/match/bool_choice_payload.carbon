// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/bool_choice_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/bool_choice_payload.carbon

// Bool constants as choice-alternative payload subpatterns (W-076 plan
// §1.7): the constant admission in `DoMatchCaseExprPattern` is the single
// shared leaf lane for every expression-pattern position, and `bool` is
// an in-slice choice payload type (`IsInSliceChoicePayloadType`), so
// `case .Tag(true)` goes live with the W-076 widening through the same
// generic lane as tuple elements — no payload-specific code. Coverage is
// unaffected: a `.Tag(true)` payload is refutable, so the arm records
// nothing toward exhaustiveness — the `.Some(42)` rule — and only
// `.None` records, so the match keeps its `default` arm.

//@dump-sem-ir-begin
choice Wrap {
  Tag(b: bool),
  None
}

fn F(w: Wrap) -> i32 {
  match (w) {
    case .Tag(true) => { return 1; }
    case .Tag(false) => { return 0; }
    case .None => { return 2; }
    default => { return 3; }
  }
  return -1;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- bool_choice_payload.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Wrap: type = class_type @Wrap [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.bc0: type = tuple_type (bool) [concrete]
// CHECK:STDOUT:   %.f86: type = custom_layout_type {size=1, align=1, .Tag@0: %tuple.type.bc0} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.5bf: type = struct_type {.discriminant: %u1, .payload: %.f86} [concrete]
// CHECK:STDOUT:   %complete_type.d2b: <witness> = complete_type_witness %struct_type.discriminant.payload.5bf [concrete]
// CHECK:STDOUT:   %struct_type.discriminant: type = struct_type {.discriminant: %u1} [concrete]
// CHECK:STDOUT:   %_.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %_.patt: %pattern_type.831 = wrapper_binding_pattern _, %_.param_patt [concrete]
// CHECK:STDOUT:   %.7c1: Core.Form = init_form %Wrap [concrete]
// CHECK:STDOUT:   %pattern_type.c16: type = pattern_type %Wrap [concrete]
// CHECK:STDOUT:   %return.param_patt.b76: %pattern_type.c16 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.41d: %pattern_type.c16 = return_slot_pattern %return.param_patt.b76, %Wrap [concrete]
// CHECK:STDOUT:   %Wrap.Tag.type: type = fn_type @Wrap.Tag [concrete]
// CHECK:STDOUT:   %Wrap.Tag: %Wrap.Tag.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %Copy.facet.7af: %Copy.type = facet_value bool, (%Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d02: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.7af) [concrete]
// CHECK:STDOUT:   %.e28: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d02, %Copy.facet.7af [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.type: type = fn_type @bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op: %bool.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %struct: %struct_type.discriminant = struct_value (%int_1.233) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.0c5: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.38a: %UInt.as.Copy.impl.Op.type.0c5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.334: <witness> = impl_witness imports.%Copy.impl_witness_table.ae7, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.type.c97: type = fn_type @UInt.as.Copy.impl.Op, @UInt.as.Copy.impl(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.d9c: %UInt.as.Copy.impl.Op.type.c97 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.18b: %Copy.type = facet_value %u1, (%Copy.impl_witness.334) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.703: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.18b) [concrete]
// CHECK:STDOUT:   %.952: type = fn_type_with_self_type %Copy.WithSelf.Op.type.703, %Copy.facet.18b [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.bound: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.d9c [concrete]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %UInt.as.Copy.impl.Op.d9c, @UInt.as.Copy.impl.Op(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.edd: <bound method> = bound_method %int_1.233, %UInt.as.Copy.impl.Op.specific_fn [concrete]
// CHECK:STDOUT:   %uninit: %.f86 = uninitialized_value [concrete]
// CHECK:STDOUT:   %Wrap.val: %Wrap = struct_value (%int_1.233, %uninit) [concrete]
// CHECK:STDOUT:   %.456: ref %Wrap = temporary invalid, %Wrap.val [concrete]
// CHECK:STDOUT:   %w.param_patt: %pattern_type.c16 = value_param_pattern [concrete]
// CHECK:STDOUT:   %w.patt: %pattern_type.c16 = wrapper_binding_pattern w, %w.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %pattern_type.d79: type = pattern_type %tuple.type.bc0 [concrete]
// CHECK:STDOUT:   %.4bb: %pattern_type.d79 = tuple_pattern (@F.%expr_patt.loc31) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.type.539: type = facet_type <@EqWith, @EqWith(bool)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.fb2: <witness> = impl_witness imports.%EqWith.impl_witness_table.5db [concrete]
// CHECK:STDOUT:   %EqWith.facet.6a4: %EqWith.type.539 = facet_value bool, (%EqWith.impl_witness.fb2) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f71: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(bool, %EqWith.facet.6a4) [concrete]
// CHECK:STDOUT:   %.4ef: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f71, %EqWith.facet.6a4 [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.type: type = fn_type @bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal: %bool.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.e7c: <bound method> = bound_method %true, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %.2e4: %pattern_type.d79 = tuple_pattern (@F.%expr_patt.loc32) [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.ed3: <bound method> = bound_method %false, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.9c3475.1: %bool.as.Copy.impl.Op.type = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.9c3475.1), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.791: @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op.type (%UInt.as.Copy.impl.Op.type.0c5) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.Copy.impl.%UInt.as.Copy.impl.Op (constants.%UInt.as.Copy.impl.Op.38a)]
// CHECK:STDOUT:   %Copy.impl_witness_table.ae7 = impl_witness_table (%Core.import_ref.791), @UInt.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.a874: %bool.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.5db = impl_witness_table (%Core.import_ref.a874, %Core.import_ref.e3a), @bool.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Wrap.Tag.decl: %Wrap.Tag.type = fn_decl @Wrap.Tag [concrete = constants.%Wrap.Tag] {
// CHECK:STDOUT:     %_.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%_.param_patt]
// CHECK:STDOUT:     %_.patt: %pattern_type.831 = wrapper_binding_pattern _, %_.param_patt [concrete = constants.%_.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.c16 = out_param_pattern [concrete = constants.%return.param_patt.b76]
// CHECK:STDOUT:     %return.patt: %pattern_type.c16 = return_slot_pattern %return.param_patt, constants.%Wrap [concrete = constants.%return.patt.41d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc24_13.9: Core.Form = init_form constants.%Wrap [concrete = constants.%.7c1]
// CHECK:STDOUT:     %_.param: bool = value_param call_param0
// CHECK:STDOUT:     %_: bool = wrapper_binding _, %_.param
// CHECK:STDOUT:     %return.param: ref %Wrap = out_param call_param1
// CHECK:STDOUT:     %return: ref %Wrap = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Wrap.decl: type = class_decl @Wrap [concrete = constants.%Wrap] {} {}
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %w.param_patt: %pattern_type.c16 = value_param_pattern [concrete = constants.%w.param_patt]
// CHECK:STDOUT:     %w.patt: %pattern_type.c16 = wrapper_binding_pattern w, %w.param_patt [concrete = constants.%w.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc29: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %w.param: %Wrap = value_param call_param0
// CHECK:STDOUT:     %Wrap.ref: type = name_ref Wrap, file.%Wrap.decl [concrete = constants.%Wrap]
// CHECK:STDOUT:     %w: %Wrap = wrapper_binding w, %w.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Wrap {
// CHECK:STDOUT:   %b.param: bool = value_param call_param0
// CHECK:STDOUT:   %.loc25: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %b: bool = wrapper_binding b, %b.param
// CHECK:STDOUT:   %.loc27_1.1: type = custom_layout_type {size=1, align=1, .Tag@0: %tuple.type.bc0} [concrete = constants.%.f86]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.discriminant.payload.5bf [concrete = constants.%complete_type.d2b]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc27_1.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc27_1.1: <bound method> = bound_method %int_1, %impl.elem0.loc27_1.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc27_1.1: <specific function> = specific_function %impl.elem0.loc27_1.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc27_1.2: <bound method> = bound_method %int_1, %specific_fn.loc27_1.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc27_1.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc27_1.2: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc27_1.3: %u1 = converted %int_1, %.loc27_1.2 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc27_1.4: %struct_type.discriminant = struct_literal (%.loc27_1.3) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc27_1.2: %.952 = impl_witness_access constants.%Copy.impl_witness.334, element0 [concrete = constants.%UInt.as.Copy.impl.Op.d9c]
// CHECK:STDOUT:   %bound_method.loc27_1.3: <bound method> = bound_method %.loc27_1.3, %impl.elem0.loc27_1.2 [concrete = constants.%UInt.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %specific_fn.loc27_1.2: <specific function> = specific_function %impl.elem0.loc27_1.2, @UInt.as.Copy.impl.Op(constants.%int_1.5b8) [concrete = constants.%UInt.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc27_1.4: <bound method> = bound_method %.loc27_1.3, %specific_fn.loc27_1.2 [concrete = constants.%bound_method.edd]
// CHECK:STDOUT:   %UInt.as.Copy.impl.Op.call: init %u1 = call %bound_method.loc27_1.4(%.loc27_1.3) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc27_1.5: ref %Wrap = temporary_storage
// CHECK:STDOUT:   %.loc27_1.6: ref %u1 = class_element_access %.loc27_1.5, element0
// CHECK:STDOUT:   %.loc27_1.7: init %u1 to %.loc27_1.6 = in_place_init %UInt.as.Copy.impl.Op.call [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc27_1.8: ref %.f86 = class_element_access %.loc27_1.5, element1
// CHECK:STDOUT:   %uninit: %.f86 = uninitialized_value [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc27_1.9: init %.f86 to %.loc27_1.8 = in_place_init %uninit [concrete = constants.%uninit]
// CHECK:STDOUT:   %.loc27_1.10: init %Wrap to %.loc27_1.5 = class_init (%.loc27_1.7, %.loc27_1.9) [concrete = constants.%Wrap.val]
// CHECK:STDOUT:   %.loc27_1.11: init %Wrap = converted %.loc27_1.4, %.loc27_1.10 [concrete = constants.%Wrap.val]
// CHECK:STDOUT:   %.loc27_1.12: ref %Wrap = temporary %.loc27_1.5, %.loc27_1.11 [concrete = constants.%.456]
// CHECK:STDOUT:   %.loc27_1.13: %Wrap = acquire_value %.loc27_1.12 [concrete = constants.%Wrap.val]
// CHECK:STDOUT:   %None: %Wrap = wrapper_binding None, %.loc27_1.13
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%Wrap
// CHECK:STDOUT:   .Tag = generated.%Wrap.Tag.decl
// CHECK:STDOUT:   .None = %None
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Wrap.Tag(%_.param: bool) -> out %return.param: %Wrap {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc24_13.1: ref %u1 = class_element_access %return.param, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc24_13.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc24_13.1: <bound method> = bound_method %int_0, %impl.elem0.loc24_13.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0.loc24_13.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc24_13.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %u1 = call %bound_method.loc24_13.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc24_13.2: init %u1 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc24_13.3: init %u1 to %.loc24_13.1 = in_place_init %.loc24_13.2 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc24_13.4: ref %.f86 = class_element_access %return.param, element1
// CHECK:STDOUT:   %.loc24_13.5: ref %tuple.type.bc0 = class_element_access %.loc24_13.4, element0
// CHECK:STDOUT:   %.loc25_15.1: %tuple.type.bc0 = tuple_literal (%_.param)
// CHECK:STDOUT:   %impl.elem0.loc24_13.2: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc24_13.3: <bound method> = bound_method %_.param, %impl.elem0.loc24_13.2
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call: init bool = call %bound_method.loc24_13.3(%_.param)
// CHECK:STDOUT:   %.loc25_15.2: init %tuple.type.bc0 to %.loc24_13.5 = tuple_init (%bool.as.Copy.impl.Op.call)
// CHECK:STDOUT:   %.loc24_13.6: init %tuple.type.bc0 = converted %.loc25_15.1, %.loc25_15.2
// CHECK:STDOUT:   %.loc24_13.7: init %tuple.type.bc0 to %.loc24_13.5 = in_place_init %.loc24_13.6
// CHECK:STDOUT:   %.loc24_13.8: init %Wrap to %return.param = class_init (%.loc24_13.3, %.loc24_13.7)
// CHECK:STDOUT:   return %.loc24_13.8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%w.param: %Wrap) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %w.ref: %Wrap = name_ref w, %w
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc31: %pattern_type.831 = expr_pattern %true in [concrete] {
// CHECK:STDOUT:       %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc31_15: %pattern_type.d79 = tuple_pattern (%expr_patt.loc31) [concrete = constants.%.4bb]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc31: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc31_21.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc31_21.1: <bound method> = bound_method %int_0.loc31, %impl.elem0.loc31_21.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc31_21.1: <specific function> = specific_function %impl.elem0.loc31_21.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc31_21.2: <bound method> = bound_method %int_0.loc31, %specific_fn.loc31_21.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_21: init %u1 = call %bound_method.loc31_21.2(%int_0.loc31) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc31_21.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_21 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc31_21.2: %u1 = converted %int_0.loc31, %.loc31_21.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc31_21.3: ref %u1 = class_element_access %w.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc31_21.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc31_21.3: <bound method> = bound_method %.loc31_21.2, %impl.elem0.loc31_21.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc31_21.2: <specific function> = specific_function %impl.elem0.loc31_21.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc31_21.4: <bound method> = bound_method %.loc31_21.2, %specific_fn.loc31_21.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc31_21.4: %u1 = acquire_value %.loc31_21.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc31: init bool = call %bound_method.loc31_21.4(%.loc31_21.2, %.loc31_21.4)
// CHECK:STDOUT:   %.loc31_21.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc31
// CHECK:STDOUT:   %.loc31_21.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc31, %.loc31_21.5
// CHECK:STDOUT:   %false.loc31: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc31_21.6 br !match.case.then.loc31_21.1 else br !match.<unexpected BranchWithArg>.loc31(%false.loc31)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc31_21.1:
// CHECK:STDOUT:   %.loc31_21.7: ref %.f86 = class_element_access %w.ref, element1
// CHECK:STDOUT:   %.loc31_21.8: ref %tuple.type.bc0 = class_element_access %.loc31_21.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc31: ref bool = tuple_access %.loc31_21.8, element0
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc31_21.3: %.4ef = impl_witness_access constants.%EqWith.impl_witness.fb2, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc31_21.5: <bound method> = bound_method %true, %impl.elem0.loc31_21.3 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.e7c]
// CHECK:STDOUT:   %.loc31_21.9: bool = acquire_value %tuple.elem0.loc31
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc31: init bool = call %bound_method.loc31_21.5(%true, %.loc31_21.9)
// CHECK:STDOUT:   %.loc31_21.10: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc31
// CHECK:STDOUT:   %.loc31_21.11: bool = converted %bool.as.EqWith.impl.Equal.call.loc31, %.loc31_21.10
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>.loc31(%.loc31_21.11)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>.loc31:
// CHECK:STDOUT:   %.loc31_21.12: bool = block_arg !match.<unexpected BranchWithArg>.loc31
// CHECK:STDOUT:   if %.loc31_21.12 br !match.case.then.loc31_21.2 else br !match.case.else.loc31
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc31_21.2:
// CHECK:STDOUT:   %int_1.loc31: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc31_34: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc31_34.1: <bound method> = bound_method %int_1.loc31, %impl.elem0.loc31_34 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc31_34: <specific function> = specific_function %impl.elem0.loc31_34, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc31_34.2: <bound method> = bound_method %int_1.loc31, %specific_fn.loc31_34 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_34: init %i32 = call %bound_method.loc31_34.2(%int_1.loc31) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc31_34: init %i32 = converted %int_1.loc31, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc31_34 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc31_34
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc31:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc32: %pattern_type.831 = expr_pattern %false.loc32_15 in [concrete] {
// CHECK:STDOUT:       %false.loc32_15: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc32_15: %pattern_type.d79 = tuple_pattern (%expr_patt.loc32) [concrete = constants.%.2e4]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc32_22: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc32_22.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc32_22.1: <bound method> = bound_method %int_0.loc32_22, %impl.elem0.loc32_22.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc32_22.1: <specific function> = specific_function %impl.elem0.loc32_22.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc32_22.2: <bound method> = bound_method %int_0.loc32_22, %specific_fn.loc32_22.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_22: init %u1 = call %bound_method.loc32_22.2(%int_0.loc32_22) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc32_22.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_22 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc32_22.2: %u1 = converted %int_0.loc32_22, %.loc32_22.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc32_22.3: ref %u1 = class_element_access %w.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc32_22.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc32_22.3: <bound method> = bound_method %.loc32_22.2, %impl.elem0.loc32_22.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc32_22.2: <specific function> = specific_function %impl.elem0.loc32_22.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc32_22.4: <bound method> = bound_method %.loc32_22.2, %specific_fn.loc32_22.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc32_22.4: %u1 = acquire_value %.loc32_22.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc32: init bool = call %bound_method.loc32_22.4(%.loc32_22.2, %.loc32_22.4)
// CHECK:STDOUT:   %.loc32_22.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc32
// CHECK:STDOUT:   %.loc32_22.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc32, %.loc32_22.5
// CHECK:STDOUT:   %false.loc32_22: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc32_22.6 br !match.case.then.loc32_22.1 else br !match.<unexpected BranchWithArg>.loc32(%false.loc32_22)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc32_22.1:
// CHECK:STDOUT:   %.loc32_22.7: ref %.f86 = class_element_access %w.ref, element1
// CHECK:STDOUT:   %.loc32_22.8: ref %tuple.type.bc0 = class_element_access %.loc32_22.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc32: ref bool = tuple_access %.loc32_22.8, element0
// CHECK:STDOUT:   %false.loc32_15: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc32_22.3: %.4ef = impl_witness_access constants.%EqWith.impl_witness.fb2, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc32_22.5: <bound method> = bound_method %false.loc32_15, %impl.elem0.loc32_22.3 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.ed3]
// CHECK:STDOUT:   %.loc32_22.9: bool = acquire_value %tuple.elem0.loc32
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc32: init bool = call %bound_method.loc32_22.5(%false.loc32_15, %.loc32_22.9)
// CHECK:STDOUT:   %.loc32_22.10: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc32
// CHECK:STDOUT:   %.loc32_22.11: bool = converted %bool.as.EqWith.impl.Equal.call.loc32, %.loc32_22.10
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>.loc32(%.loc32_22.11)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>.loc32:
// CHECK:STDOUT:   %.loc32_22.12: bool = block_arg !match.<unexpected BranchWithArg>.loc32
// CHECK:STDOUT:   if %.loc32_22.12 br !match.case.then.loc32_22.2 else br !match.case.else.loc32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc32_22.2:
// CHECK:STDOUT:   %int_0.loc32_34: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc32_35: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc32_35.1: <bound method> = bound_method %int_0.loc32_34, %impl.elem0.loc32_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc32_35: <specific function> = specific_function %impl.elem0.loc32_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc32_35.2: <bound method> = bound_method %int_0.loc32_34, %specific_fn.loc32_35 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_35: init %i32 = call %bound_method.loc32_35.2(%int_0.loc32_34) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc32_35: init %i32 = converted %int_0.loc32_34, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc32_35 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc32_35
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc32:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc33: %pattern_type.c16 = expr_pattern %None.ref in [concrete] {
// CHECK:STDOUT:       %None.ref: %Wrap = name_ref None, @Wrap.%None
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %None.ref: %Wrap = name_ref None, @Wrap.%None
// CHECK:STDOUT:   %int_1.loc33: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc33_16.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc33_16.1: <bound method> = bound_method %int_1.loc33, %impl.elem0.loc33_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc33_16.1: <specific function> = specific_function %impl.elem0.loc33_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc33_16.2: <bound method> = bound_method %int_1.loc33, %specific_fn.loc33_16.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33_16: init %u1 = call %bound_method.loc33_16.2(%int_1.loc33) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc33_16.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33_16 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc33_16.2: %u1 = converted %int_1.loc33, %.loc33_16.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc33_16.3: ref %u1 = class_element_access %w.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc33_16.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc33_16.3: <bound method> = bound_method %.loc33_16.2, %impl.elem0.loc33_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc33_16.2: <specific function> = specific_function %impl.elem0.loc33_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc33_16.4: <bound method> = bound_method %.loc33_16.2, %specific_fn.loc33_16.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc33_16.4: %u1 = acquire_value %.loc33_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc33: init bool = call %bound_method.loc33_16.4(%.loc33_16.2, %.loc33_16.4)
// CHECK:STDOUT:   %.loc33_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc33
// CHECK:STDOUT:   %.loc33_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc33, %.loc33_16.5
// CHECK:STDOUT:   if %.loc33_16.6 br !match.case.then.loc33 else br !match.case.else.loc33
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc33:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc33_29: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc33_29.1: <bound method> = bound_method %int_2, %impl.elem0.loc33_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc33_29: <specific function> = specific_function %impl.elem0.loc33_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc33_29.2: <bound method> = bound_method %int_2, %specific_fn.loc33_29 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33_29: init %i32 = call %bound_method.loc33_29.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc33_29: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc33_29 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc33_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc33:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc34: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc34_26.1: <bound method> = bound_method %int_3, %impl.elem0.loc34 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc34: <specific function> = specific_function %impl.elem0.loc34, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc34_26.2: <bound method> = bound_method %int_3, %specific_fn.loc34 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34: init %i32 = call %bound_method.loc34_26.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc34: init %i32 = converted %int_3, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc34 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   return %.loc34
// CHECK:STDOUT: }
// CHECK:STDOUT:
