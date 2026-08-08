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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/basic.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

fn A() {}
fn B() {}
fn C() {}
fn D() {}

//@dump-sem-ir-begin
fn F(n: i32) {
  match (n) {
    case 1 => { A(); }
    case 2 => { B(); }
    default => { C(); }
  }
  D();
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- basic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %A.type: type = fn_type @A [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %A: %A.type = struct_value () [concrete]
// CHECK:STDOUT:   %B.type: type = fn_type @B [concrete]
// CHECK:STDOUT:   %B: %B.type = struct_value () [concrete]
// CHECK:STDOUT:   %C.type: type = fn_type @C [concrete]
// CHECK:STDOUT:   %C: %C.type = struct_value () [concrete]
// CHECK:STDOUT:   %D.type: type = fn_type @D [concrete]
// CHECK:STDOUT:   %D: %D.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = at_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
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
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.b586ba.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.a942d5.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.a942d5.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.ef58d6.1: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.b586ba.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.a942d5.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.a942d5.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.ef58d6.2: <bound method> = bound_method %int_1.5b8, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.9723f2.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.a942d5.2 [concrete]
// CHECK:STDOUT:   %bound_method.d8c28e.1: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.9723f2.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.a942d5.1 [concrete]
// CHECK:STDOUT:   %bound_method.d8c28e.2: <bound method> = bound_method %int_2.ecc, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
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
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%n.param: %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc23: %pattern_type.dc0 = expr_pattern %int_1 in [concrete] {
// CHECK:STDOUT:       %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc23_12: %.44e = impl_witness_access constants.%EqWith.impl_witness.8ff, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.2]
// CHECK:STDOUT:   %bound_method.loc23_12.1: <bound method> = bound_method %int_1, %impl.elem0.loc23_12 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.b586ba.1]
// CHECK:STDOUT:   %specific_fn.loc23_12: <specific function> = specific_function %impl.elem0.loc23_12, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1]
// CHECK:STDOUT:   %bound_method.loc23_12.2: <bound method> = bound_method %int_1, %specific_fn.loc23_12 [concrete = constants.%bound_method.ef58d6.1]
// CHECK:STDOUT:   %.loc23_12.1: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %Equal.ref.loc23: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = name_ref Equal, %.loc23_12.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc23: <bound method> = bound_method %int_1, %Equal.ref.loc23 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.b586ba.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc23: <specific function> = specific_function %Equal.ref.loc23, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2]
// CHECK:STDOUT:   %bound_method.loc23_12.3: <bound method> = bound_method %int_1, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc23 [concrete = constants.%bound_method.ef58d6.2]
// CHECK:STDOUT:   %impl.elem0.loc23_10: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc23_10.1: <bound method> = bound_method %int_1, %impl.elem0.loc23_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc23_10: <specific function> = specific_function %impl.elem0.loc23_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc23_10.2: <bound method> = bound_method %int_1, %specific_fn.loc23_10 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23: init %i32 = call %bound_method.loc23_10.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc23_10.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc23_10.2: %i32 = converted %int_1, %.loc23_10.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc23: init bool = call %bound_method.loc23_12.3(%.loc23_10.2, %n.ref)
// CHECK:STDOUT:   %.loc23_12.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc23
// CHECK:STDOUT:   %.loc23_12.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc23, %.loc23_12.2
// CHECK:STDOUT:   if %.loc23_12.3 br !match.case.then.loc23 else br !match.case.else.loc23
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc23:
// CHECK:STDOUT:   %A.ref: %A.type = name_ref A, file.%A.decl [concrete = constants.%A]
// CHECK:STDOUT:   %A.call: init %empty_tuple.type = call %A.ref()
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc23:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc24: %pattern_type.dc0 = expr_pattern %int_2 in [concrete] {
// CHECK:STDOUT:       %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc24_12: %.44e = impl_witness_access constants.%EqWith.impl_witness.8ff, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.2]
// CHECK:STDOUT:   %bound_method.loc24_12.1: <bound method> = bound_method %int_2, %impl.elem0.loc24_12 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.9723f2.1]
// CHECK:STDOUT:   %specific_fn.loc24_12: <specific function> = specific_function %impl.elem0.loc24_12, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1]
// CHECK:STDOUT:   %bound_method.loc24_12.2: <bound method> = bound_method %int_2, %specific_fn.loc24_12 [concrete = constants.%bound_method.d8c28e.1]
// CHECK:STDOUT:   %.loc24_12.1: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %Equal.ref.loc24: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = name_ref Equal, %.loc24_12.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc24: <bound method> = bound_method %int_2, %Equal.ref.loc24 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.9723f2.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc24: <specific function> = specific_function %Equal.ref.loc24, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2]
// CHECK:STDOUT:   %bound_method.loc24_12.3: <bound method> = bound_method %int_2, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc24 [concrete = constants.%bound_method.d8c28e.2]
// CHECK:STDOUT:   %impl.elem0.loc24_10: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_10.1: <bound method> = bound_method %int_2, %impl.elem0.loc24_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc24_10: <specific function> = specific_function %impl.elem0.loc24_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc24_10.2: <bound method> = bound_method %int_2, %specific_fn.loc24_10 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24: init %i32 = call %bound_method.loc24_10.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc24_10.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc24_10.2: %i32 = converted %int_2, %.loc24_10.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc24: init bool = call %bound_method.loc24_12.3(%.loc24_10.2, %n.ref)
// CHECK:STDOUT:   %.loc24_12.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc24
// CHECK:STDOUT:   %.loc24_12.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc24, %.loc24_12.2
// CHECK:STDOUT:   if %.loc24_12.3 br !match.case.then.loc24 else br !match.case.else.loc24
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc24:
// CHECK:STDOUT:   %B.ref: %B.type = name_ref B, file.%B.decl [concrete = constants.%B]
// CHECK:STDOUT:   %B.call: init %empty_tuple.type = call %B.ref()
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc24:
// CHECK:STDOUT:   %C.ref: %C.type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:   %C.call: init %empty_tuple.type = call %C.ref()
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %D.ref: %D.type = name_ref D, file.%D.decl [concrete = constants.%D]
// CHECK:STDOUT:   %D.call: init %empty_tuple.type = call %D.ref()
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
