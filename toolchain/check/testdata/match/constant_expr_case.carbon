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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/constant_expr_case.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/constant_expr_case.carbon
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/try.carbon:20:1: error: name `Core.ImplicitAs` implicitly referenced here, but not found [CoreNameNotFound]
// CHECK:STDERR: choice ControlFlow(C: type, B: type) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Constant integer expression patterns (plan RF-4): a `case` expression is
// admitted whenever its value is a concrete constant integer, so constant
// arithmetic works the same way as a plain literal. Each comparison still
// evaluates the expression `==` the scrutinee, in that operand order.
//@dump-sem-ir-begin
fn F(x: i32) -> i32 {
  match (x) {
    case 2 + 3 => { return 1; }
    case -(4 * 4) => { return 2; }
    default => { return 0; }
  }
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- constant_expr_case.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness: <witness> = impl_witness imports.%AddWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %AddWith.facet: %AddWith.type.832 = facet_value Core.IntLiteral, (%AddWith.impl_witness) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.8da: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(Core.IntLiteral, %AddWith.facet) [concrete]
// CHECK:STDOUT:   %.cef: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.8da, %AddWith.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.AddWith.impl.Op.type: type = fn_type @Core.IntLiteral.as.AddWith.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.AddWith.impl.Op: %Core.IntLiteral.as.AddWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.AddWith.impl.Op.bound: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.AddWith.impl.Op [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
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
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.79851e.1: <bound method> = bound_method %int_5.64b, %T.as_type.as.EqWith.impl.Equal.a942d5.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.a942d5.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.315c23.1: <bound method> = bound_method %int_5.64b, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.79851e.2: <bound method> = bound_method %int_5.64b, %T.as_type.as.EqWith.impl.Equal.a942d5.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.a942d5.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.315c23.2: <bound method> = bound_method %int_5.64b, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.740: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.1c5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.740, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %MulWith.type.fbc: type = facet_type <@MulWith, @MulWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %MulWith.impl_witness: <witness> = impl_witness imports.%MulWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %MulWith.facet: %MulWith.type.fbc = facet_value Core.IntLiteral, (%MulWith.impl_witness) [concrete]
// CHECK:STDOUT:   %MulWith.WithSelf.Op.type.b82: type = fn_type @MulWith.WithSelf.Op, @MulWith.WithSelf(Core.IntLiteral, %MulWith.facet) [concrete]
// CHECK:STDOUT:   %.3ea: type = fn_type_with_self_type %MulWith.WithSelf.Op.type.b82, %MulWith.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.MulWith.impl.Op.type: type = fn_type @Core.IntLiteral.as.MulWith.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.MulWith.impl.Op: %Core.IntLiteral.as.MulWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.MulWith.impl.Op.bound: <bound method> = bound_method %int_4, %Core.IntLiteral.as.MulWith.impl.Op [concrete]
// CHECK:STDOUT:   %int_16: Core.IntLiteral = int_value 16 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.db1: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.e9b: type = fn_type_with_self_type %Negate.WithSelf.Op.type.db1, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_16, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-16.8e1: Core.IntLiteral = int_value -16 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.7c01bf.1: <bound method> = bound_method %int_-16.8e1, %T.as_type.as.EqWith.impl.Equal.a942d5.2 [concrete]
// CHECK:STDOUT:   %bound_method.5dbf8f.1: <bound method> = bound_method %int_-16.8e1, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.7c01bf.2: <bound method> = bound_method %int_-16.8e1, %T.as_type.as.EqWith.impl.Equal.a942d5.1 [concrete]
// CHECK:STDOUT:   %bound_method.5dbf8f.2: <bound method> = bound_method %int_-16.8e1, %T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.492: <bound method> = bound_method %int_-16.8e1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.d88: <bound method> = bound_method %int_-16.8e1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-16.831: %i32 = int_value -16 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.abd97d.1 = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3475.1: %Core.IntLiteral.as.AddWith.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op]
// CHECK:STDOUT:   %AddWith.impl_witness_table = impl_witness_table (%Core.import_ref.abd97d.1, %Core.import_ref.9c3475.1), @Core.IntLiteral.as.AddWith.impl.8f4 [concrete]
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.468 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.b3c = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd97d.2 = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3475.2: %Core.IntLiteral.as.MulWith.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.MulWith.impl.Op]
// CHECK:STDOUT:   %MulWith.impl_witness_table = impl_witness_table (%Core.import_ref.abd97d.2, %Core.import_ref.9c3475.2), @Core.IntLiteral.as.MulWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd97d.3 = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3475.3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd97d.3, %Core.import_ref.9c3475.3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = at_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc20_17 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc20_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc20: Core.Form = init_form %i32.loc20_17 [concrete = constants.%.795f]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc20_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%x.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc22: %pattern_type.dc0 = expr_pattern %.loc22_12.5 in [concrete] {
// CHECK:STDOUT:       %int_2.loc22: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:       %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:       %impl.elem1.loc22: %.cef = impl_witness_access constants.%AddWith.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc22_12.3: <bound method> = bound_method %int_2.loc22, %impl.elem1.loc22 [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op.bound]
// CHECK:STDOUT:       %Core.IntLiteral.as.AddWith.impl.Op.call: init Core.IntLiteral = call %bound_method.loc22_12.3(%int_2.loc22, %int_3) [concrete = constants.%int_5.64b]
// CHECK:STDOUT:       %.loc22_12.4: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.AddWith.impl.Op.call [concrete = constants.%int_5.64b]
// CHECK:STDOUT:       %.loc22_12.5: Core.IntLiteral = converted %Core.IntLiteral.as.AddWith.impl.Op.call, %.loc22_12.4 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc22_12.1: Core.IntLiteral = splice_block %.loc22_12.5 [concrete = constants.%int_5.64b] {
// CHECK:STDOUT:     %int_2.loc22: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:     %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:     %impl.elem1.loc22: %.cef = impl_witness_access constants.%AddWith.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op]
// CHECK:STDOUT:     %bound_method.loc22_12.3: <bound method> = bound_method %int_2.loc22, %impl.elem1.loc22 [concrete = constants.%Core.IntLiteral.as.AddWith.impl.Op.bound]
// CHECK:STDOUT:     %Core.IntLiteral.as.AddWith.impl.Op.call: init Core.IntLiteral = call %bound_method.loc22_12.3(%int_2.loc22, %int_3) [concrete = constants.%int_5.64b]
// CHECK:STDOUT:     %.loc22_12.4: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.AddWith.impl.Op.call [concrete = constants.%int_5.64b]
// CHECK:STDOUT:     %.loc22_12.5: Core.IntLiteral = converted %Core.IntLiteral.as.AddWith.impl.Op.call, %.loc22_12.4 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %impl.elem0.loc22_16: %.44e = impl_witness_access constants.%EqWith.impl_witness.8ff, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.2]
// CHECK:STDOUT:   %bound_method.loc22_16.1: <bound method> = bound_method %.loc22_12.1, %impl.elem0.loc22_16 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.79851e.1]
// CHECK:STDOUT:   %specific_fn.loc22_16: <specific function> = specific_function %impl.elem0.loc22_16, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1]
// CHECK:STDOUT:   %bound_method.loc22_16.2: <bound method> = bound_method %.loc22_12.1, %specific_fn.loc22_16 [concrete = constants.%bound_method.315c23.1]
// CHECK:STDOUT:   %.loc22_16.1: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %Equal.ref.loc22: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = name_ref Equal, %.loc22_16.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc22: <bound method> = bound_method %.loc22_12.1, %Equal.ref.loc22 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.79851e.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc22: <specific function> = specific_function %Equal.ref.loc22, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2]
// CHECK:STDOUT:   %bound_method.loc22_16.3: <bound method> = bound_method %.loc22_12.1, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc22 [concrete = constants.%bound_method.315c23.2]
// CHECK:STDOUT:   %impl.elem0.loc22_12: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc22_12.1: <bound method> = bound_method %.loc22_12.1, %impl.elem0.loc22_12 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc22_12: <specific function> = specific_function %impl.elem0.loc22_12, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc22_12.2: <bound method> = bound_method %.loc22_12.1, %specific_fn.loc22_12 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22_12: init %i32 = call %bound_method.loc22_12.2(%.loc22_12.1) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc22_12.2: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22_12 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc22_12.3: %i32 = converted %.loc22_12.1, %.loc22_12.2 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc22: init bool = call %bound_method.loc22_16.3(%.loc22_12.3, %x.ref)
// CHECK:STDOUT:   %.loc22_16.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc22
// CHECK:STDOUT:   %.loc22_16.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc22, %.loc22_16.2
// CHECK:STDOUT:   if %.loc22_16.3 br !match.case.then.loc22 else br !match.case.else.loc22
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc22:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc22_29: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc22_29.1: <bound method> = bound_method %int_1, %impl.elem0.loc22_29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc22_29: <specific function> = specific_function %impl.elem0.loc22_29, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc22_29.2: <bound method> = bound_method %int_1, %specific_fn.loc22_29 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22_29: init %i32 = call %bound_method.loc22_29.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc22_29: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22_29 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc22_29
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc22:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt.loc23: %pattern_type.dc0 = expr_pattern %.loc23_10.5 in [concrete] {
// CHECK:STDOUT:       %int_4.loc23_12: Core.IntLiteral = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:       %int_4.loc23_16: Core.IntLiteral = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:       %impl.elem1.loc23_14: %.3ea = impl_witness_access constants.%MulWith.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.MulWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc23_14: <bound method> = bound_method %int_4.loc23_12, %impl.elem1.loc23_14 [concrete = constants.%Core.IntLiteral.as.MulWith.impl.Op.bound]
// CHECK:STDOUT:       %Core.IntLiteral.as.MulWith.impl.Op.call: init Core.IntLiteral = call %bound_method.loc23_14(%int_4.loc23_12, %int_4.loc23_16) [concrete = constants.%int_16]
// CHECK:STDOUT:       %impl.elem1.loc23_10: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:       %bound_method.loc23_10.3: <bound method> = bound_method %Core.IntLiteral.as.MulWith.impl.Op.call, %impl.elem1.loc23_10 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:       %.loc23_14.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.MulWith.impl.Op.call [concrete = constants.%int_16]
// CHECK:STDOUT:       %.loc23_14.2: Core.IntLiteral = converted %Core.IntLiteral.as.MulWith.impl.Op.call, %.loc23_14.1 [concrete = constants.%int_16]
// CHECK:STDOUT:       %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc23_10.3(%.loc23_14.2) [concrete = constants.%int_-16.8e1]
// CHECK:STDOUT:       %.loc23_10.4: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-16.8e1]
// CHECK:STDOUT:       %.loc23_10.5: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc23_10.4 [concrete = constants.%int_-16.8e1]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc23_10.1: Core.IntLiteral = splice_block %.loc23_10.5 [concrete = constants.%int_-16.8e1] {
// CHECK:STDOUT:     %int_4.loc23_12: Core.IntLiteral = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:     %int_4.loc23_16: Core.IntLiteral = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:     %impl.elem1.loc23_14: %.3ea = impl_witness_access constants.%MulWith.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.MulWith.impl.Op]
// CHECK:STDOUT:     %bound_method.loc23_14: <bound method> = bound_method %int_4.loc23_12, %impl.elem1.loc23_14 [concrete = constants.%Core.IntLiteral.as.MulWith.impl.Op.bound]
// CHECK:STDOUT:     %Core.IntLiteral.as.MulWith.impl.Op.call: init Core.IntLiteral = call %bound_method.loc23_14(%int_4.loc23_12, %int_4.loc23_16) [concrete = constants.%int_16]
// CHECK:STDOUT:     %impl.elem1.loc23_10: %.e9b = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:     %bound_method.loc23_10.3: <bound method> = bound_method %Core.IntLiteral.as.MulWith.impl.Op.call, %impl.elem1.loc23_10 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:     %.loc23_14.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.MulWith.impl.Op.call [concrete = constants.%int_16]
// CHECK:STDOUT:     %.loc23_14.2: Core.IntLiteral = converted %Core.IntLiteral.as.MulWith.impl.Op.call, %.loc23_14.1 [concrete = constants.%int_16]
// CHECK:STDOUT:     %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc23_10.3(%.loc23_14.2) [concrete = constants.%int_-16.8e1]
// CHECK:STDOUT:     %.loc23_10.4: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-16.8e1]
// CHECK:STDOUT:     %.loc23_10.5: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc23_10.4 [concrete = constants.%int_-16.8e1]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %impl.elem0.loc23_19: %.44e = impl_witness_access constants.%EqWith.impl_witness.8ff, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.2]
// CHECK:STDOUT:   %bound_method.loc23_19.1: <bound method> = bound_method %.loc23_10.1, %impl.elem0.loc23_19 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.7c01bf.1]
// CHECK:STDOUT:   %specific_fn.loc23_19: <specific function> = specific_function %impl.elem0.loc23_19, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.1]
// CHECK:STDOUT:   %bound_method.loc23_19.2: <bound method> = bound_method %.loc23_10.1, %specific_fn.loc23_19 [concrete = constants.%bound_method.5dbf8f.1]
// CHECK:STDOUT:   %.loc23_19.1: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %Equal.ref.loc23: %T.as_type.as.EqWith.impl.Equal.type.e4cecd.1 = name_ref Equal, %.loc23_19.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.a942d5.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.loc23: <bound method> = bound_method %.loc23_10.1, %Equal.ref.loc23 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.7c01bf.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.loc23: <specific function> = specific_function %Equal.ref.loc23, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.76b46b.2]
// CHECK:STDOUT:   %bound_method.loc23_19.3: <bound method> = bound_method %.loc23_10.1, %T.as_type.as.EqWith.impl.Equal.specific_fn.loc23 [concrete = constants.%bound_method.5dbf8f.2]
// CHECK:STDOUT:   %impl.elem0.loc23_10: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc23_10.1: <bound method> = bound_method %.loc23_10.1, %impl.elem0.loc23_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.492]
// CHECK:STDOUT:   %specific_fn.loc23_10: <specific function> = specific_function %impl.elem0.loc23_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc23_10.2: <bound method> = bound_method %.loc23_10.1, %specific_fn.loc23_10 [concrete = constants.%bound_method.d88]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_10: init %i32 = call %bound_method.loc23_10.2(%.loc23_10.1) [concrete = constants.%int_-16.831]
// CHECK:STDOUT:   %.loc23_10.2: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_10 [concrete = constants.%int_-16.831]
// CHECK:STDOUT:   %.loc23_10.3: %i32 = converted %.loc23_10.1, %.loc23_10.2 [concrete = constants.%int_-16.831]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call.loc23: init bool = call %bound_method.loc23_19.3(%.loc23_10.3, %x.ref)
// CHECK:STDOUT:   %.loc23_19.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call.loc23
// CHECK:STDOUT:   %.loc23_19.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call.loc23, %.loc23_19.2
// CHECK:STDOUT:   if %.loc23_19.3 br !match.case.then.loc23 else br !match.case.else.loc23
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc23:
// CHECK:STDOUT:   %int_2.loc23: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc23_32: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc23_32.1: <bound method> = bound_method %int_2.loc23, %impl.elem0.loc23_32 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc23_32: <specific function> = specific_function %impl.elem0.loc23_32, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc23_32.2: <bound method> = bound_method %int_2.loc23, %specific_fn.loc23_32 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_32: init %i32 = call %bound_method.loc23_32.2(%int_2.loc23) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc23_32: init %i32 = converted %int_2.loc23, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc23_32 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc23_32
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc23:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc24: %.1c5 = impl_witness_access constants.%ImplicitAs.impl_witness.a23, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc24_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc24: <specific function> = specific_function %impl.elem0.loc24, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc24_26.2: <bound method> = bound_method %int_0, %specific_fn.loc24 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24: init %i32 = call %bound_method.loc24_26.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc24: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc24 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc24
// CHECK:STDOUT: }
// CHECK:STDOUT:
