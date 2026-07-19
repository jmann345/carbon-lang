// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// TODO: Extend the "int" min_prelude to support basic integer operations, so we
// can use it here.
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/converging_arms.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/converging_arms.carbon

fn A() {}
fn B() {}

//@dump-sem-ir-begin
fn F(n: i32) -> i32 {
  match (n) {
    case 0 => { return 1; }
    case 1 => { A(); }
    default => { B(); }
  }
  return 0;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- converging_arms.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %A.type: type = fn_type @A [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %A: %A.type = struct_value () [concrete]
// CHECK:STDOUT:   %B.type: type = fn_type @B [concrete]
// CHECK:STDOUT:   %B: %B.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
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
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a23: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.b3c, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a23) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.8ff: <witness> = impl_witness imports.%EqWith.impl_witness_table.468, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.a942d5.1: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.e4cecd.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.a942d5.2: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.28c: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.8ff) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.b21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.28c) [concrete]
// CHECK:STDOUT:   %.44e: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.b21, %EqWith.facet.28c [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.6da2d9.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.a942d5.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.a942d5.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.24f1fd.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.6da2d9.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.a942d5.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.a942d5.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.24f1fd.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.b586ba.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.a942d5.2 [concrete]
// CHECK:STDOUT:   %bound_method.ef58d6.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.b586ba.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.a942d5.1 [concrete]
// CHECK:STDOUT:   %bound_method.ef58d6.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.468 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc19_17 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc19_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc19: Core.Form = init_form %i32.loc19_17 [concrete = constants.%.795]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc19_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%n.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %int_0.loc21: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc21_12: %.44e = impl_witness_access constants.%EqWith.impl_witness.8ff, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.2]
// CHECK:STDOUT:   %bound_method.loc21_12.1: <bound method> = bound_method %int_0.loc21, %impl.elem0.loc21_12 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.6da2d9.1]
// CHECK:STDOUT:   %specific_fn.loc21_12: <specific function> = specific_function %impl.elem0.loc21_12, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1]
// CHECK:STDOUT:   %bound_method.loc21_12.2: <bound method> = bound_method %int_0.loc21, %specific_fn.loc21_12 [concrete = constants.%bound_method.24f1fd.1]
// CHECK:STDOUT:   %.loc21_12.1: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %Equal.ref.loc21: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = name_ref Equal, %.loc21_12.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc21: <bound method> = bound_method %int_0.loc21, %Equal.ref.loc21 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.6da2d9.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc21: <specific function> = specific_function %Equal.ref.loc21, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2]
// CHECK:STDOUT:   %bound_method.loc21_12.3: <bound method> = bound_method %int_0.loc21, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc21 [concrete = constants.%bound_method.24f1fd.2]
// CHECK:STDOUT:   %impl.elem0.loc21_10: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc21_10.1: <bound method> = bound_method %int_0.loc21, %impl.elem0.loc21_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc21_10: <specific function> = specific_function %impl.elem0.loc21_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc21_10.2: <bound method> = bound_method %int_0.loc21, %specific_fn.loc21_10 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21_10: init %i32 = call %bound_method.loc21_10.2(%int_0.loc21) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc21_10.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21_10 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc21_10.2: %i32 = converted %int_0.loc21, %.loc21_10.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc21: init bool = call %bound_method.loc21_12.3(%.loc21_10.2, %n.ref)
// CHECK:STDOUT:   %.loc21_12.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc21
// CHECK:STDOUT:   %.loc21_12.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc21, %.loc21_12.2
// CHECK:STDOUT:   if %.loc21_12.3 br !match.case.then.loc21 else br !match.case.else.loc21
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc21:
// CHECK:STDOUT:   %int_1.loc21: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc21_25: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc21_25.1: <bound method> = bound_method %int_1.loc21, %impl.elem0.loc21_25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc21_25: <specific function> = specific_function %impl.elem0.loc21_25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc21_25.2: <bound method> = bound_method %int_1.loc21, %specific_fn.loc21_25 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21_25: init %i32 = call %bound_method.loc21_25.2(%int_1.loc21) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc21_25: init %i32 = converted %int_1.loc21, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21_25 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc21_25
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc21:
// CHECK:STDOUT:   %int_1.loc22: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc22_12: %.44e = impl_witness_access constants.%EqWith.impl_witness.8ff, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.2]
// CHECK:STDOUT:   %bound_method.loc22_12.1: <bound method> = bound_method %int_1.loc22, %impl.elem0.loc22_12 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.b586ba.1]
// CHECK:STDOUT:   %specific_fn.loc22_12: <specific function> = specific_function %impl.elem0.loc22_12, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1]
// CHECK:STDOUT:   %bound_method.loc22_12.2: <bound method> = bound_method %int_1.loc22, %specific_fn.loc22_12 [concrete = constants.%bound_method.ef58d6.1]
// CHECK:STDOUT:   %.loc22_12.1: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %Equal.ref.loc22: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = name_ref Equal, %.loc22_12.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc22: <bound method> = bound_method %int_1.loc22, %Equal.ref.loc22 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.b586ba.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc22: <specific function> = specific_function %Equal.ref.loc22, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2]
// CHECK:STDOUT:   %bound_method.loc22_12.3: <bound method> = bound_method %int_1.loc22, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc22 [concrete = constants.%bound_method.ef58d6.2]
// CHECK:STDOUT:   %impl.elem0.loc22_10: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc22_10.1: <bound method> = bound_method %int_1.loc22, %impl.elem0.loc22_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc22_10: <specific function> = specific_function %impl.elem0.loc22_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc22_10.2: <bound method> = bound_method %int_1.loc22, %specific_fn.loc22_10 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22: init %i32 = call %bound_method.loc22_10.2(%int_1.loc22) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc22_10.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc22_10.2: %i32 = converted %int_1.loc22, %.loc22_10.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc22: init bool = call %bound_method.loc22_12.3(%.loc22_10.2, %n.ref)
// CHECK:STDOUT:   %.loc22_12.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc22
// CHECK:STDOUT:   %.loc22_12.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc22, %.loc22_12.2
// CHECK:STDOUT:   if %.loc22_12.3 br !match.case.then.loc22 else br !match.case.else.loc22
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc22:
// CHECK:STDOUT:   %A.ref: %A.type = name_ref A, file.%A.decl [concrete = constants.%A]
// CHECK:STDOUT:   %A.call: init %empty_tuple.type = call %A.ref()
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc22:
// CHECK:STDOUT:   %B.ref: %B.type = name_ref B, file.%B.decl [concrete = constants.%B]
// CHECK:STDOUT:   %B.call: init %empty_tuple.type = call %B.ref()
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_0.loc25: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc25: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc25_11.1: <bound method> = bound_method %int_0.loc25, %impl.elem0.loc25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc25: <specific function> = specific_function %impl.elem0.loc25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc25_11.2: <bound method> = bound_method %int_0.loc25, %specific_fn.loc25 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25: init %i32 = call %bound_method.loc25_11.2(%int_0.loc25) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc25: init %i32 = converted %int_0.loc25, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc25 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc25
// CHECK:STDOUT: }
// CHECK:STDOUT:
