// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/prelude_tuple_impls.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/prelude_tuple_impls.carbon

// --- copy.carbon
library "[[@TEST_NAME]]";

fn Dup[T: Core.Copy](x: T) -> T { return x.(Core.Copy.Op)(); }

fn Call() -> (i32, i32, i32, i32) {
  //@dump-sem-ir-begin
  return Dup((1 as i32, 2 as i32, 3 as i32, 4 as i32));
  //@dump-sem-ir-end
}

// --- eq.carbon
library "[[@TEST_NAME]]";

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  //@dump-sem-ir-begin
  return a == b;
  //@dump-sem-ir-end
}

// --- ordered.carbon
library "[[@TEST_NAME]]";

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  //@dump-sem-ir-begin
  return a < b;
  //@dump-sem-ir-end
}

// CHECK:STDOUT: --- copy.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Dup.type: type = fn_type @Dup [concrete]
// CHECK:STDOUT:   %Dup: %Dup.type = struct_value () [concrete]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.dee: type = pack_type %Copy.type, %arity [symbolic]
// CHECK:STDOUT:   %T.49b: %pack_type.dee = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Copy.impl.Op.type.3bd: type = fn_type @tuple.type.as.Copy.impl.Op, @tuple.type.as.Copy.impl(%arity, %T.49b) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Copy.impl.Op.ba9: %tuple.type.as.Copy.impl.Op.type.3bd = struct_value () [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.087: type = tuple_type (%i32, %i32, %i32, %i32) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %As.type.155: type = facet_type <@As, @As(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.c5d: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl.f25(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.6ee: %Core.IntLiteral.as.As.impl.Convert.type.c5d = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.e7f: <witness> = impl_witness imports.%As.impl_witness_table.d22, @Core.IntLiteral.as.As.impl.f25(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.e79: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl.f25(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.8a4: %Core.IntLiteral.as.As.impl.Convert.type.e79 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.155 = facet_value Core.IntLiteral, (%As.impl_witness.e7f) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.d02: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i32, %As.facet) [concrete]
// CHECK:STDOUT:   %.453: type = fn_type_with_self_type %As.WithSelf.Convert.type.d02, %As.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound.3a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.8a4 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.8a4, @Core.IntLiteral.as.As.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.18b: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound.343: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.As.impl.Convert.8a4 [concrete]
// CHECK:STDOUT:   %bound_method.721: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound.0b9: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.As.impl.Convert.8a4 [concrete]
// CHECK:STDOUT:   %bound_method.a7e: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound.2f8: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.As.impl.Convert.8a4 [concrete]
// CHECK:STDOUT:   %bound_method.db8: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_4.4eb: %i32 = int_value 4 [concrete]
// CHECK:STDOUT:   %tuple.75c: %tuple.type.087 = tuple_value (%int_1.0c6, %int_2.295, %int_3.410, %int_4.4eb) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %pack_type.ca1: type = pack_type %Copy.type, %int_4.0c1 [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %.e3b: %pack_type.ca1 = pack_value (%Copy.facet.1e1, %Copy.facet.1e1, %Copy.facet.1e1, %Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.7fd: <witness> = impl_witness imports.%Copy.impl_witness_table.3fa, @tuple.type.as.Copy.impl(%int_4.0c1, %.e3b) [concrete]
// CHECK:STDOUT:   %Copy.facet.c1c: %Copy.type = facet_value %tuple.type.087, (%Copy.impl_witness.7fd) [concrete]
// CHECK:STDOUT:   %Dup.specific_fn: <specific function> = specific_function %Dup, @Dup(%Copy.facet.c1c) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.4cc: @tuple.type.as.Copy.impl.%tuple.type.as.Copy.impl.Op.type (%tuple.type.as.Copy.impl.Op.type.3bd) = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [symbolic = @tuple.type.as.Copy.impl.%tuple.type.as.Copy.impl.Op (constants.%tuple.type.as.Copy.impl.Op.ba9)]
// CHECK:STDOUT:   %Copy.impl_witness_table.3fa = impl_witness_table (%Core.import_ref.4cc), @tuple.type.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl.f25 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() -> out %return.param: %tuple.type.087 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Dup.ref: %Dup.type = name_ref Dup, file.%Dup.decl [concrete = constants.%Dup]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %i32.loc7_20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %impl.elem0.loc7_17: %.453 = impl_witness_access constants.%As.impl_witness.e7f, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.8a4]
// CHECK:STDOUT:   %bound_method.loc7_17.1: <bound method> = bound_method %int_1, %impl.elem0.loc7_17 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.3a0]
// CHECK:STDOUT:   %specific_fn.loc7_17: <specific function> = specific_function %impl.elem0.loc7_17, @Core.IntLiteral.as.As.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_17.2: <bound method> = bound_method %int_1, %specific_fn.loc7_17 [concrete = constants.%bound_method.18b]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc7_17: init %i32 = call %bound_method.loc7_17.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc7_17.1: %i32 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc7_17 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc7_17.2: %i32 = converted %int_1, %.loc7_17.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %i32.loc7_30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %impl.elem0.loc7_27: %.453 = impl_witness_access constants.%As.impl_witness.e7f, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.8a4]
// CHECK:STDOUT:   %bound_method.loc7_27.1: <bound method> = bound_method %int_2, %impl.elem0.loc7_27 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.343]
// CHECK:STDOUT:   %specific_fn.loc7_27: <specific function> = specific_function %impl.elem0.loc7_27, @Core.IntLiteral.as.As.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_27.2: <bound method> = bound_method %int_2, %specific_fn.loc7_27 [concrete = constants.%bound_method.721]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc7_27: init %i32 = call %bound_method.loc7_27.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc7_27.1: %i32 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc7_27 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc7_27.2: %i32 = converted %int_2, %.loc7_27.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %i32.loc7_40: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %impl.elem0.loc7_37: %.453 = impl_witness_access constants.%As.impl_witness.e7f, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.8a4]
// CHECK:STDOUT:   %bound_method.loc7_37.1: <bound method> = bound_method %int_3, %impl.elem0.loc7_37 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.0b9]
// CHECK:STDOUT:   %specific_fn.loc7_37: <specific function> = specific_function %impl.elem0.loc7_37, @Core.IntLiteral.as.As.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_37.2: <bound method> = bound_method %int_3, %specific_fn.loc7_37 [concrete = constants.%bound_method.a7e]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc7_37: init %i32 = call %bound_method.loc7_37.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc7_37.1: %i32 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc7_37 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc7_37.2: %i32 = converted %int_3, %.loc7_37.1 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %i32.loc7_50: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %impl.elem0.loc7_47: %.453 = impl_witness_access constants.%As.impl_witness.e7f, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.8a4]
// CHECK:STDOUT:   %bound_method.loc7_47.1: <bound method> = bound_method %int_4, %impl.elem0.loc7_47 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.2f8]
// CHECK:STDOUT:   %specific_fn.loc7_47: <specific function> = specific_function %impl.elem0.loc7_47, @Core.IntLiteral.as.As.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_47.2: <bound method> = bound_method %int_4, %specific_fn.loc7_47 [concrete = constants.%bound_method.db8]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc7_47: init %i32 = call %bound_method.loc7_47.2(%int_4) [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc7_47.1: %i32 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc7_47 [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc7_47.2: %i32 = converted %int_4, %.loc7_47.1 [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc7_53.1: %tuple.type.087 = tuple_literal (%.loc7_17.2, %.loc7_27.2, %.loc7_37.2, %.loc7_47.2) [concrete = constants.%tuple.75c]
// CHECK:STDOUT:   %Copy.facet.loc7_54.1: %Copy.type = facet_value constants.%tuple.type.087, (constants.%Copy.impl_witness.7fd) [concrete = constants.%Copy.facet.c1c]
// CHECK:STDOUT:   %.loc7_54.1: %Copy.type = converted constants.%tuple.type.087, %Copy.facet.loc7_54.1 [concrete = constants.%Copy.facet.c1c]
// CHECK:STDOUT:   %Copy.facet.loc7_54.2: %Copy.type = facet_value constants.%tuple.type.087, (constants.%Copy.impl_witness.7fd) [concrete = constants.%Copy.facet.c1c]
// CHECK:STDOUT:   %.loc7_54.2: %Copy.type = converted constants.%tuple.type.087, %Copy.facet.loc7_54.2 [concrete = constants.%Copy.facet.c1c]
// CHECK:STDOUT:   %Dup.specific_fn: <specific function> = specific_function %Dup.ref, @Dup(constants.%Copy.facet.c1c) [concrete = constants.%Dup.specific_fn]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %tuple: %tuple.type.087 = tuple_value (%.loc7_17.2, %.loc7_27.2, %.loc7_37.2, %.loc7_47.2) [concrete = constants.%tuple.75c]
// CHECK:STDOUT:   %.loc7_53.2: %tuple.type.087 = converted %.loc7_53.1, %tuple [concrete = constants.%tuple.75c]
// CHECK:STDOUT:   %Dup.call: init %tuple.type.087 to %.loc5_33.1 = call %Dup.specific_fn(%.loc7_53.2)
// CHECK:STDOUT:   return %Dup.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- eq.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %tuple.type.b3d: type = tuple_type (%i32, %i64) [concrete]
// CHECK:STDOUT:   %EqWith.type.096: type = facet_type <@EqWith, @EqWith(%tuple.type.b3d)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %Eq.type: type = facet_type <@Eq> [concrete]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type %Eq.type, %arity [symbolic]
// CHECK:STDOUT:   %T.621: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.type.951: type = fn_type @tuple.type.as.EqWith.impl.Equal, @tuple.type.as.EqWith.impl(%arity, %T.621) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.d63: %tuple.type.as.EqWith.impl.Equal.type.951 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6539.1: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.1a5: %pack_type.8f6539.1 = pack_value (%i32, %i64) [concrete]
// CHECK:STDOUT:   %pack_type.8f6539.2: type = pack_type %Eq.type, %int_2 [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Eq.facet.824: %Eq.type = facet_value %i32, (%EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.932: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %Eq.facet.0b4: %Eq.type = facet_value %i64, (%EqWith.impl_witness.932) [concrete]
// CHECK:STDOUT:   %.165: %pack_type.8f6539.2 = pack_value (%Eq.facet.824, %Eq.facet.0b4) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.302: <witness> = impl_witness imports.%EqWith.impl_witness_table.2c6, @tuple.type.as.EqWith.impl(%int_2, %.165) [concrete]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.type.bd2: type = fn_type @tuple.type.as.EqWith.impl.Equal, @tuple.type.as.EqWith.impl(%int_2, %.165) [concrete]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.622: %tuple.type.as.EqWith.impl.Equal.type.bd2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.1b3: %EqWith.type.096 = facet_value %tuple.type.b3d, (%EqWith.impl_witness.302) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.499: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%tuple.type.b3d, %EqWith.facet.1b3) [concrete]
// CHECK:STDOUT:   %.816: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.499, %EqWith.facet.1b3 [concrete]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %tuple.type.as.EqWith.impl.Equal.622, @tuple.type.as.EqWith.impl.Equal(%int_2, %.165) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.7da: @tuple.type.as.EqWith.impl.%tuple.type.as.EqWith.impl.Equal.type (%tuple.type.as.EqWith.impl.Equal.type.951) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @tuple.type.as.EqWith.impl.%tuple.type.as.EqWith.impl.Equal (constants.%tuple.type.as.EqWith.impl.Equal.d63)]
// CHECK:STDOUT:   %Core.import_ref.640 = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.2c6 = impl_witness_table (%Core.import_ref.7da, %Core.import_ref.640), @tuple.type.as.EqWith.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%a.param: %tuple.type.b3d, %b.param: %tuple.type.b3d) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %tuple.type.b3d = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %tuple.type.b3d = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.816 = impl_witness_access constants.%EqWith.impl_witness.302, element0 [concrete = constants.%tuple.type.as.EqWith.impl.Equal.622]
// CHECK:STDOUT:   %bound_method.loc5_12.1: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %int_2.loc5_12.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_12.1: %pack_type.8f6539.1 = pack_value (constants.%i32, constants.%i64) [concrete = constants.%.1a5]
// CHECK:STDOUT:   %int_2.loc5_12.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_12.2: %pack_type.8f6539.1 = pack_value (constants.%i32, constants.%i64) [concrete = constants.%.1a5]
// CHECK:STDOUT:   %int_2.loc5_12.3: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_12.3: %pack_type.8f6539.1 = pack_value (constants.%i32, constants.%i64) [concrete = constants.%.1a5]
// CHECK:STDOUT:   %int_2.loc5_12.4: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_12.4: %pack_type.8f6539.1 = pack_value (constants.%i32, constants.%i64) [concrete = constants.%.1a5]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @tuple.type.as.EqWith.impl.Equal(constants.%int_2, constants.%.165) [concrete = constants.%tuple.type.as.EqWith.impl.Equal.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_12.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc5_12.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %tuple.type.as.EqWith.impl.Equal.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- ordered.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %tuple.type.b3d: type = tuple_type (%i32, %i64) [concrete]
// CHECK:STDOUT:   %OrderedWith.type.9d1: type = facet_type <@OrderedWith, @OrderedWith(%tuple.type.b3d)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.89b: type = fn_type @Int.as.OrderedWith.impl.Less.1, @Int.as.OrderedWith.impl.ab3(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.050: %Int.as.OrderedWith.impl.Less.type.89b = struct_value () [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %Ordered.type: type = facet_type <@Ordered> [concrete]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type %Ordered.type, %arity [symbolic]
// CHECK:STDOUT:   %T.621: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %tuple.type.as.OrderedWith.impl.Less.type.973: type = fn_type @tuple.type.as.OrderedWith.impl.Less, @tuple.type.as.OrderedWith.impl(%arity, %T.621) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.OrderedWith.impl.Less.61c: %tuple.type.as.OrderedWith.impl.Less.type.973 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6539.1: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.1a5: %pack_type.8f6539.1 = pack_value (%i32, %i64) [concrete]
// CHECK:STDOUT:   %pack_type.8f6539.2: type = pack_type %Ordered.type, %int_2 [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.dcd: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.087, @Int.as.OrderedWith.impl.ab3(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Ordered.facet.ad9: %Ordered.type = facet_value %i32, (%OrderedWith.impl_witness.dcd) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.202: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.087, @Int.as.OrderedWith.impl.ab3(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %Ordered.facet.3d2: %Ordered.type = facet_value %i64, (%OrderedWith.impl_witness.202) [concrete]
// CHECK:STDOUT:   %.6ec: %pack_type.8f6539.2 = pack_value (%Ordered.facet.ad9, %Ordered.facet.3d2) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.cef: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.b9c, @tuple.type.as.OrderedWith.impl(%int_2, %.6ec) [concrete]
// CHECK:STDOUT:   %tuple.type.as.OrderedWith.impl.Less.type.c8a: type = fn_type @tuple.type.as.OrderedWith.impl.Less, @tuple.type.as.OrderedWith.impl(%int_2, %.6ec) [concrete]
// CHECK:STDOUT:   %tuple.type.as.OrderedWith.impl.Less.393: %tuple.type.as.OrderedWith.impl.Less.type.c8a = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.549: %OrderedWith.type.9d1 = facet_value %tuple.type.b3d, (%OrderedWith.impl_witness.cef) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.b56: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(%tuple.type.b3d, %OrderedWith.facet.549) [concrete]
// CHECK:STDOUT:   %.c15: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.b56, %OrderedWith.facet.549 [concrete]
// CHECK:STDOUT:   %tuple.type.as.OrderedWith.impl.Less.specific_fn: <specific function> = specific_function %tuple.type.as.OrderedWith.impl.Less.393, @tuple.type.as.OrderedWith.impl.Less(%int_2, %.6ec) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.c1c8: @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.Less.type (%Int.as.OrderedWith.impl.Less.type.89b) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.ab3.%Int.as.OrderedWith.impl.Less (constants.%Int.as.OrderedWith.impl.Less.050)]
// CHECK:STDOUT:   %Core.import_ref.30c = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.664 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9d4 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.087 = impl_witness_table (%Core.import_ref.c1c8, %Core.import_ref.30c, %Core.import_ref.664, %Core.import_ref.9d4), @Int.as.OrderedWith.impl.ab3 [concrete]
// CHECK:STDOUT:   %Core.import_ref.a69: @tuple.type.as.OrderedWith.impl.%tuple.type.as.OrderedWith.impl.Less.type (%tuple.type.as.OrderedWith.impl.Less.type.973) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @tuple.type.as.OrderedWith.impl.%tuple.type.as.OrderedWith.impl.Less (constants.%tuple.type.as.OrderedWith.impl.Less.61c)]
// CHECK:STDOUT:   %Core.import_ref.1cc = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.cc9 = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.85d = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.b9c = impl_witness_table (%Core.import_ref.a69, %Core.import_ref.1cc, %Core.import_ref.cc9, %Core.import_ref.85d), @tuple.type.as.OrderedWith.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%a.param: %tuple.type.b3d, %b.param: %tuple.type.b3d) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %tuple.type.b3d = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %tuple.type.b3d = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.c15 = impl_witness_access constants.%OrderedWith.impl_witness.cef, element0 [concrete = constants.%tuple.type.as.OrderedWith.impl.Less.393]
// CHECK:STDOUT:   %bound_method.loc5_12.1: <bound method> = bound_method %a.ref, %impl.elem0
// CHECK:STDOUT:   %int_2.loc5_12.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_12.1: %pack_type.8f6539.1 = pack_value (constants.%i32, constants.%i64) [concrete = constants.%.1a5]
// CHECK:STDOUT:   %int_2.loc5_12.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_12.2: %pack_type.8f6539.1 = pack_value (constants.%i32, constants.%i64) [concrete = constants.%.1a5]
// CHECK:STDOUT:   %int_2.loc5_12.3: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_12.3: %pack_type.8f6539.1 = pack_value (constants.%i32, constants.%i64) [concrete = constants.%.1a5]
// CHECK:STDOUT:   %int_2.loc5_12.4: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc5_12.4: %pack_type.8f6539.1 = pack_value (constants.%i32, constants.%i64) [concrete = constants.%.1a5]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @tuple.type.as.OrderedWith.impl.Less(constants.%int_2, constants.%.6ec) [concrete = constants.%tuple.type.as.OrderedWith.impl.Less.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_12.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:   %tuple.type.as.OrderedWith.impl.Less.call: init bool = call %bound_method.loc5_12.2(%a.ref, %b.ref)
// CHECK:STDOUT:   return %tuple.type.as.OrderedWith.impl.Less.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
