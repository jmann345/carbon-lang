// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/bool_tuple_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/bool_tuple_scrutinee.carbon

// Tuple elements of bool (W-076 plan §1.5): the tuple walk gates by
// pattern kind and shape, not element type, so once the scrutinee gate
// admits `bool` elementwise and the constant admission accepts
// `BoolLiteral`, bool tuple elements compare through the same generic
// leaf lane as the whole-pattern case (`bool as EqWith(bool)`).

// --- mixed_tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(t: (bool, i32)) -> i32 {
  match (t) {
    case (true, 1) => { return 1; }
    case (false, n: i32) => { return n; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- bool_pair_keeps_default.carbon
library "[[@TEST_NAME]]";

// Tuple exhaustiveness itself stays `default`-requiring: only the bool
// ROOT rule extends (W-076 plan §4 P5), so a `(bool, bool)` match whose
// constant arms enumerate all four value pairs still keeps its `default`
// arm. The boundary is pinned here explicitly.
//@dump-sem-ir-begin
fn G(t: (bool, bool)) -> i32 {
  match (t) {
    case (false, false) => { return 0; }
    case (false, true) => { return 1; }
    case (true, false) => { return 2; }
    case (true, true) => { return 3; }
    default => { return 4; }
  }
  return -1;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- mixed_tuple.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.24b: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.2f5: %tuple.type.24b = tuple_value (bool, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.68a: type = tuple_type (bool, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.541: type = pattern_type %tuple.type.68a [concrete]
// CHECK:STDOUT:   %t.param_patt: %pattern_type.541 = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt: %pattern_type.541 = wrapper_binding_pattern t, %t.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %tuple.type.3c2: type = tuple_type (bool, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %pattern_type.c79: type = pattern_type %tuple.type.3c2 [concrete]
// CHECK:STDOUT:   %.ac8: %pattern_type.c79 = tuple_pattern (@F.%expr_patt.loc6_11, @F.%expr_patt.loc6_17) [concrete]
// CHECK:STDOUT:   %EqWith.type.539: type = facet_type <@EqWith, @EqWith(bool)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.fb2: <witness> = impl_witness imports.%EqWith.impl_witness_table.5db [concrete]
// CHECK:STDOUT:   %EqWith.facet.6a4: %EqWith.type.539 = facet_value bool, (%EqWith.impl_witness.fb2) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f71: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(bool, %EqWith.facet.6a4) [concrete]
// CHECK:STDOUT:   %.4ef: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f71, %EqWith.facet.6a4 [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.type: type = fn_type @bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal: %bool.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.e7c: <bound method> = bound_method %true, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.29e975.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.42af37.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %.7a8: %pattern_type.541 = tuple_pattern (@F.%expr_patt.loc7, %n.patt) [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.ed3: <bound method> = bound_method %false, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a87: %bool.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.5db = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @bool.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %t.param_patt: %pattern_type.541 = value_param_pattern [concrete = constants.%t.param_patt]
// CHECK:STDOUT:     %t.patt: %pattern_type.541 = wrapper_binding_pattern t, %t.param_patt [concrete = constants.%t.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc4_25 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc4_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_25: Core.Form = init_form %i32.loc4_25 [concrete = constants.%.795f]
// CHECK:STDOUT:     %t.param: %tuple.type.68a = value_param call_param0
// CHECK:STDOUT:     %.loc4_19.1: type = splice_block %.loc4_19.3 [concrete = constants.%tuple.type.68a] {
// CHECK:STDOUT:       %.loc4_10: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:       %i32.loc4_16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc4_19.2: %tuple.type.24b = tuple_literal (%.loc4_10, %i32.loc4_16) [concrete = constants.%tuple.2f5]
// CHECK:STDOUT:       %.loc4_19.3: type = converted %.loc4_19.2, constants.%tuple.type.68a [concrete = constants.%tuple.type.68a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: %tuple.type.68a = wrapper_binding t, %t.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%t.param: %tuple.type.68a) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.ref: %tuple.type.68a = name_ref t, %t
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc6_11: %pattern_type.831 = expr_pattern %true in [concrete] {
// CHECK:STDOUT:       %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc6_17: %pattern_type.dc0 = expr_pattern %int_1.loc6_17 in [concrete] {
// CHECK:STDOUT:       %int_1.loc6_17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc6_18: %pattern_type.c79 = tuple_pattern (%expr_patt.loc6_11, %expr_patt.loc6_17) [concrete = constants.%.ac8]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0.loc5_10.1: bool = tuple_access %t.ref, element0
// CHECK:STDOUT:   %tuple.elem1.loc5_10.1: %i32 = tuple_access %t.ref, element1
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc6_20.1: %.4ef = impl_witness_access constants.%EqWith.impl_witness.fb2, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc6_20.1: <bound method> = bound_method %true, %impl.elem0.loc6_20.1 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.e7c]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc6: init bool = call %bound_method.loc6_20.1(%true, %tuple.elem0.loc5_10.1)
// CHECK:STDOUT:   %.loc6_20.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc6
// CHECK:STDOUT:   %.loc6_20.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc6, %.loc6_20.1
// CHECK:STDOUT:   %int_1.loc6_17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_20.2: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc6_20.2: <bound method> = bound_method %int_1.loc6_17, %impl.elem0.loc6_20.2 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.1]
// CHECK:STDOUT:   %specific_fn.loc6_20: <specific function> = specific_function %impl.elem0.loc6_20.2, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc6_20.3: <bound method> = bound_method %int_1.loc6_17, %specific_fn.loc6_20 [concrete = constants.%bound_method.42af37.1]
// CHECK:STDOUT:   %.loc6_20.3: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc6_20.3 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.loc6_17, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.29e975.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc6_20.4: <bound method> = bound_method %int_1.loc6_17, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.42af37.2]
// CHECK:STDOUT:   %impl.elem0.loc6_17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_17.1: <bound method> = bound_method %int_1.loc6_17, %impl.elem0.loc6_17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6_17: <specific function> = specific_function %impl.elem0.loc6_17, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_17.2: <bound method> = bound_method %int_1.loc6_17, %specific_fn.loc6_17 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_17: init %i32 = call %bound_method.loc6_17.2(%int_1.loc6_17) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_17.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_17 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_17.2: %i32 = converted %int_1.loc6_17, %.loc6_17.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc6_20.4(%.loc6_17.2, %tuple.elem1.loc5_10.1)
// CHECK:STDOUT:   %.loc6_20.4: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc6_20.5: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc6_20.4
// CHECK:STDOUT:   %false.loc6: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc6_20.2 br !match.case.then.loc6_20.1 else br !match.<unexpected BranchWithArg>(%false.loc6)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc6_20.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>(%.loc6_20.5)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>:
// CHECK:STDOUT:   %.loc6_20.6: bool = block_arg !match.<unexpected BranchWithArg>
// CHECK:STDOUT:   if %.loc6_20.6 br !match.case.then.loc6_20.2 else br !match.case.else.loc6
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc6_20.2:
// CHECK:STDOUT:   %int_1.loc6_32: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc6_33: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc6_33.1: <bound method> = bound_method %int_1.loc6_32, %impl.elem0.loc6_33 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc6_33: <specific function> = specific_function %impl.elem0.loc6_33, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_33.2: <bound method> = bound_method %int_1.loc6_32, %specific_fn.loc6_33 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_33: init %i32 = call %bound_method.loc6_33.2(%int_1.loc6_32) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc6_33: init %i32 = converted %int_1.loc6_32, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_33 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc6_33
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc6:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc7: %pattern_type.831 = expr_pattern %false.loc7 in [concrete] {
// CHECK:STDOUT:       %false.loc7: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:     %.loc7_24: %pattern_type.541 = tuple_pattern (%expr_patt.loc7, %n.patt) [concrete = constants.%.7a8]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0.loc5_10.2: bool = tuple_access %t.ref, element0
// CHECK:STDOUT:   %false.loc7: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc7_26: %.4ef = impl_witness_access constants.%EqWith.impl_witness.fb2, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc7_26: <bound method> = bound_method %false.loc7, %impl.elem0.loc7_26 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.ed3]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc7: init bool = call %bound_method.loc7_26(%false.loc7, %tuple.elem0.loc5_10.2)
// CHECK:STDOUT:   %.loc7_26.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc7
// CHECK:STDOUT:   %.loc7_26.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc7, %.loc7_26.1
// CHECK:STDOUT:   if %.loc7_26.2 br !match.case.then.loc7 else br !match.case.else.loc7
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc7:
// CHECK:STDOUT:   %tuple.elem1.loc5_10.2: %i32 = tuple_access %t.ref, element1
// CHECK:STDOUT:   %i32.loc7: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %n: %i32 = wrapper_binding n, %tuple.elem1.loc5_10.2
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %impl.elem0.loc7_38: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc7_38.1: <bound method> = bound_method %n.ref, %impl.elem0.loc7_38
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7_38, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_38.2: <bound method> = bound_method %n.ref, %specific_fn.loc7
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc7_38.2(%n.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc7:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc8: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc8 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_26.2: <bound method> = bound_method %int_0, %specific_fn.loc8 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %i32 = call %bound_method.loc8_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc8: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc8
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- bool_pair_keeps_default.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %tuple.type.24b: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple: %tuple.type.24b = tuple_value (bool, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.784: type = tuple_type (bool, bool) [concrete]
// CHECK:STDOUT:   %pattern_type.860: type = pattern_type %tuple.type.784 [concrete]
// CHECK:STDOUT:   %t.param_patt: %pattern_type.860 = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt: %pattern_type.860 = wrapper_binding_pattern t, %t.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %.e1c: %pattern_type.860 = tuple_pattern (@G.%expr_patt.loc10_11, @G.%expr_patt.loc10_18) [concrete]
// CHECK:STDOUT:   %EqWith.type.539: type = facet_type <@EqWith, @EqWith(bool)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness: <witness> = impl_witness imports.%EqWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %EqWith.facet: %EqWith.type.539 = facet_value bool, (%EqWith.impl_witness) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f71: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(bool, %EqWith.facet) [concrete]
// CHECK:STDOUT:   %.4ef: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f71, %EqWith.facet [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.type: type = fn_type @bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal: %bool.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.ed3: <bound method> = bound_method %false, %bool.as.EqWith.impl.Equal [concrete]
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
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %.e71: %pattern_type.860 = tuple_pattern (@G.%expr_patt.loc11_11, @G.%expr_patt.loc11_18) [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.bound.e7c: <bound method> = bound_method %true, %bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %.c9e: %pattern_type.860 = tuple_pattern (@G.%expr_patt.loc12_11, @G.%expr_patt.loc12_17) [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %.aca: %pattern_type.860 = tuple_pattern (@G.%expr_patt.loc13_11, @G.%expr_patt.loc13_17) [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.b7a: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_4.4eb: %i32 = int_value 4 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a87: %bool.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @bool.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %t.param_patt: %pattern_type.860 = value_param_pattern [concrete = constants.%t.param_patt]
// CHECK:STDOUT:     %t.patt: %pattern_type.860 = wrapper_binding_pattern t, %t.param_patt [concrete = constants.%t.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_26: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %t.param: %tuple.type.784 = value_param call_param0
// CHECK:STDOUT:     %.loc8_20.1: type = splice_block %.loc8_20.3 [concrete = constants.%tuple.type.784] {
// CHECK:STDOUT:       %.loc8_10: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:       %.loc8_16: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:       %.loc8_20.2: %tuple.type.24b = tuple_literal (%.loc8_10, %.loc8_16) [concrete = constants.%tuple]
// CHECK:STDOUT:       %.loc8_20.3: type = converted %.loc8_20.2, constants.%tuple.type.784 [concrete = constants.%tuple.type.784]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: %tuple.type.784 = wrapper_binding t, %t.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G(%t.param: %tuple.type.784) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.ref: %tuple.type.784 = name_ref t, %t
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc10_11: %pattern_type.831 = expr_pattern %false.loc10_11 in [concrete] {
// CHECK:STDOUT:       %false.loc10_11: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc10_18: %pattern_type.831 = expr_pattern %false.loc10_18 in [concrete] {
// CHECK:STDOUT:       %false.loc10_18: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc10_23: %pattern_type.860 = tuple_pattern (%expr_patt.loc10_11, %expr_patt.loc10_18) [concrete = constants.%.e1c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0.loc9_10.1: bool = tuple_access %t.ref, element0
// CHECK:STDOUT:   %tuple.elem1.loc9_10.1: bool = tuple_access %t.ref, element1
// CHECK:STDOUT:   %false.loc10_11: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc10_25.1: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc10_25.1: <bound method> = bound_method %false.loc10_11, %impl.elem0.loc10_25.1 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.ed3]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc10_25.1: init bool = call %bound_method.loc10_25.1(%false.loc10_11, %tuple.elem0.loc9_10.1)
// CHECK:STDOUT:   %.loc10_25.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc10_25.1
// CHECK:STDOUT:   %.loc10_25.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc10_25.1, %.loc10_25.1
// CHECK:STDOUT:   %false.loc10_18: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc10_25.2: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc10_25.2: <bound method> = bound_method %false.loc10_18, %impl.elem0.loc10_25.2 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.ed3]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc10_25.2: init bool = call %bound_method.loc10_25.2(%false.loc10_18, %tuple.elem1.loc9_10.1)
// CHECK:STDOUT:   %.loc10_25.3: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc10_25.2
// CHECK:STDOUT:   %.loc10_25.4: bool = converted %bool.as.EqWith.impl.Equal.call.loc10_25.2, %.loc10_25.3
// CHECK:STDOUT:   %false.loc10_25: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc10_25.2 br !match.case.then.loc10_25.1 else br !match.<unexpected BranchWithArg>.loc10(%false.loc10_25)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc10_25.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>.loc10(%.loc10_25.4)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>.loc10:
// CHECK:STDOUT:   %.loc10_25.5: bool = block_arg !match.<unexpected BranchWithArg>.loc10
// CHECK:STDOUT:   if %.loc10_25.5 br !match.case.then.loc10_25.2 else br !match.case.else.loc10
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc10_25.2:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc10_38: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_38.1: <bound method> = bound_method %int_0, %impl.elem0.loc10_38 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10_38, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_38.2: <bound method> = bound_method %int_0, %specific_fn.loc10 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_38.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc10_38: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc10_38
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc10:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc11_11: %pattern_type.831 = expr_pattern %false.loc11_11 in [concrete] {
// CHECK:STDOUT:       %false.loc11_11: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc11_18: %pattern_type.831 = expr_pattern %true.loc11 in [concrete] {
// CHECK:STDOUT:       %true.loc11: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc11_22: %pattern_type.860 = tuple_pattern (%expr_patt.loc11_11, %expr_patt.loc11_18) [concrete = constants.%.e71]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0.loc9_10.2: bool = tuple_access %t.ref, element0
// CHECK:STDOUT:   %tuple.elem1.loc9_10.2: bool = tuple_access %t.ref, element1
// CHECK:STDOUT:   %false.loc11_11: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc11_24.1: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc11_24.1: <bound method> = bound_method %false.loc11_11, %impl.elem0.loc11_24.1 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.ed3]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc11_24.1: init bool = call %bound_method.loc11_24.1(%false.loc11_11, %tuple.elem0.loc9_10.2)
// CHECK:STDOUT:   %.loc11_24.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc11_24.1
// CHECK:STDOUT:   %.loc11_24.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc11_24.1, %.loc11_24.1
// CHECK:STDOUT:   %true.loc11: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc11_24.2: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc11_24.2: <bound method> = bound_method %true.loc11, %impl.elem0.loc11_24.2 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.e7c]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc11_24.2: init bool = call %bound_method.loc11_24.2(%true.loc11, %tuple.elem1.loc9_10.2)
// CHECK:STDOUT:   %.loc11_24.3: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc11_24.2
// CHECK:STDOUT:   %.loc11_24.4: bool = converted %bool.as.EqWith.impl.Equal.call.loc11_24.2, %.loc11_24.3
// CHECK:STDOUT:   %false.loc11_24: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc11_24.2 br !match.case.then.loc11_24.1 else br !match.<unexpected BranchWithArg>.loc11(%false.loc11_24)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc11_24.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>.loc11(%.loc11_24.4)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>.loc11:
// CHECK:STDOUT:   %.loc11_24.5: bool = block_arg !match.<unexpected BranchWithArg>.loc11
// CHECK:STDOUT:   if %.loc11_24.5 br !match.case.then.loc11_24.2 else br !match.case.else.loc11
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc11_24.2:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc11_37: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_37.1: <bound method> = bound_method %int_1, %impl.elem0.loc11_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_37.2: <bound method> = bound_method %int_1, %specific_fn.loc11 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_37.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc11_37: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc11_37
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc11:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc12_11: %pattern_type.831 = expr_pattern %true.loc12 in [concrete] {
// CHECK:STDOUT:       %true.loc12: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc12_17: %pattern_type.831 = expr_pattern %false.loc12_17 in [concrete] {
// CHECK:STDOUT:       %false.loc12_17: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc12_22: %pattern_type.860 = tuple_pattern (%expr_patt.loc12_11, %expr_patt.loc12_17) [concrete = constants.%.c9e]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0.loc9_10.3: bool = tuple_access %t.ref, element0
// CHECK:STDOUT:   %tuple.elem1.loc9_10.3: bool = tuple_access %t.ref, element1
// CHECK:STDOUT:   %true.loc12: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc12_24.1: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc12_24.1: <bound method> = bound_method %true.loc12, %impl.elem0.loc12_24.1 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.e7c]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc12_24.1: init bool = call %bound_method.loc12_24.1(%true.loc12, %tuple.elem0.loc9_10.3)
// CHECK:STDOUT:   %.loc12_24.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc12_24.1
// CHECK:STDOUT:   %.loc12_24.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc12_24.1, %.loc12_24.1
// CHECK:STDOUT:   %false.loc12_17: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc12_24.2: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc12_24.2: <bound method> = bound_method %false.loc12_17, %impl.elem0.loc12_24.2 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.ed3]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc12_24.2: init bool = call %bound_method.loc12_24.2(%false.loc12_17, %tuple.elem1.loc9_10.3)
// CHECK:STDOUT:   %.loc12_24.3: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc12_24.2
// CHECK:STDOUT:   %.loc12_24.4: bool = converted %bool.as.EqWith.impl.Equal.call.loc12_24.2, %.loc12_24.3
// CHECK:STDOUT:   %false.loc12_24: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc12_24.2 br !match.case.then.loc12_24.1 else br !match.<unexpected BranchWithArg>.loc12(%false.loc12_24)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc12_24.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>.loc12(%.loc12_24.4)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>.loc12:
// CHECK:STDOUT:   %.loc12_24.5: bool = block_arg !match.<unexpected BranchWithArg>.loc12
// CHECK:STDOUT:   if %.loc12_24.5 br !match.case.then.loc12_24.2 else br !match.case.else.loc12
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc12_24.2:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc12_37: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_37.1: <bound method> = bound_method %int_2, %impl.elem0.loc12_37 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc12: <specific function> = specific_function %impl.elem0.loc12_37, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_37.2: <bound method> = bound_method %int_2, %specific_fn.loc12 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %i32 = call %bound_method.loc12_37.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc12_37: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc12_37
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc12:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc13_11: %pattern_type.831 = expr_pattern %true.loc13_11 in [concrete] {
// CHECK:STDOUT:       %true.loc13_11: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %expr_patt.loc13_17: %pattern_type.831 = expr_pattern %true.loc13_17 in [concrete] {
// CHECK:STDOUT:       %true.loc13_17: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc13_21: %pattern_type.860 = tuple_pattern (%expr_patt.loc13_11, %expr_patt.loc13_17) [concrete = constants.%.aca]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0.loc9_10.4: bool = tuple_access %t.ref, element0
// CHECK:STDOUT:   %tuple.elem1.loc9_10.4: bool = tuple_access %t.ref, element1
// CHECK:STDOUT:   %true.loc13_11: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc13_23.1: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc13_23.1: <bound method> = bound_method %true.loc13_11, %impl.elem0.loc13_23.1 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.e7c]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc13_23.1: init bool = call %bound_method.loc13_23.1(%true.loc13_11, %tuple.elem0.loc9_10.4)
// CHECK:STDOUT:   %.loc13_23.1: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc13_23.1
// CHECK:STDOUT:   %.loc13_23.2: bool = converted %bool.as.EqWith.impl.Equal.call.loc13_23.1, %.loc13_23.1
// CHECK:STDOUT:   %true.loc13_17: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %impl.elem0.loc13_23.2: %.4ef = impl_witness_access constants.%EqWith.impl_witness, element0 [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %bound_method.loc13_23.2: <bound method> = bound_method %true.loc13_17, %impl.elem0.loc13_23.2 [concrete = constants.%bool.as.EqWith.impl.Equal.bound.e7c]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.call.loc13_23.2: init bool = call %bound_method.loc13_23.2(%true.loc13_17, %tuple.elem1.loc9_10.4)
// CHECK:STDOUT:   %.loc13_23.3: bool = value_of_initializer %bool.as.EqWith.impl.Equal.call.loc13_23.2
// CHECK:STDOUT:   %.loc13_23.4: bool = converted %bool.as.EqWith.impl.Equal.call.loc13_23.2, %.loc13_23.3
// CHECK:STDOUT:   %false.loc13: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   if %.loc13_23.2 br !match.case.then.loc13_23.1 else br !match.<unexpected BranchWithArg>.loc13(%false.loc13)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc13_23.1:
// CHECK:STDOUT:   br !match.<unexpected BranchWithArg>.loc13(%.loc13_23.4)
// CHECK:STDOUT:
// CHECK:STDOUT: !match.<unexpected BranchWithArg>.loc13:
// CHECK:STDOUT:   %.loc13_23.5: bool = block_arg !match.<unexpected BranchWithArg>.loc13
// CHECK:STDOUT:   if %.loc13_23.5 br !match.case.then.loc13_23.2 else br !match.case.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc13_23.2:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc13_36: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_36.1: <bound method> = bound_method %int_3, %impl.elem0.loc13_36 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc13: <specific function> = specific_function %impl.elem0.loc13_36, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_36.2: <bound method> = bound_method %int_3, %specific_fn.loc13 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13: init %i32 = call %bound_method.loc13_36.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc13_36: init %i32 = converted %int_3, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   return %.loc13_36
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc13:
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %impl.elem0.loc14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_26.1: <bound method> = bound_method %int_4, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad]
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_26.2: <bound method> = bound_method %int_4, %specific_fn.loc14 [concrete = constants.%bound_method.b7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i32 = call %bound_method.loc14_26.2(%int_4) [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc14: init %i32 = converted %int_4, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   return %.loc14
// CHECK:STDOUT: }
// CHECK:STDOUT:
