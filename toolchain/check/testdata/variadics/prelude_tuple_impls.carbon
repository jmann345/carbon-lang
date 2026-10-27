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

// --- generic_elements.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Dup[T: Core.Copy](x: T) -> (T, T) {
  let p: (T, T) = (x, x);
  return p.(Core.Copy.Op)();
}

fn Same[T: Core.Eq](a: (T, T), b: (T, T)) -> bool {
  return a == b;
}

fn Before[T: Core.Ordered, U: Core.Ordered](a: (T, U), b: (T, U)) -> bool {
  return a < b;
}
//@dump-sem-ir-end

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
// CHECK:STDOUT: --- generic_elements.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Self.f84: %Copy.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.c85f21.1: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Self.f84) [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.b85212.1: %Copy.WithSelf.Op.type.c85f21.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %pattern_type.e81: type = pattern_type %Copy.type [concrete]
// CHECK:STDOUT:   %T.patt.fe6: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.f84: %Copy.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.c1c: type = facet_access_type %T.f84 [symbolic]
// CHECK:STDOUT:   %pattern_type.2c66b4.2: type = pattern_type %T.as_type.c1c [symbolic]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.2c66b4.2 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.cec: %pattern_type.2c66b4.2 = wrapper_binding_pattern x, %x.param_patt [symbolic]
// CHECK:STDOUT:   %tuple.type.24a: type = tuple_type (%Copy.type, %Copy.type) [concrete]
// CHECK:STDOUT:   %tuple.598: %tuple.type.24a = tuple_value (%T.f84, %T.f84) [symbolic]
// CHECK:STDOUT:   %tuple.type.db8: type = tuple_type (%T.as_type.c1c, %T.as_type.c1c) [symbolic]
// CHECK:STDOUT:   %.58c: Core.Form = init_form %tuple.type.db8 [symbolic]
// CHECK:STDOUT:   %pattern_type.aac: type = pattern_type %tuple.type.db8 [symbolic]
// CHECK:STDOUT:   %return.param_patt.1c7: %pattern_type.aac = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.e7a: %pattern_type.aac = return_slot_pattern %return.param_patt.1c7, %tuple.type.db8 [symbolic]
// CHECK:STDOUT:   %Dup.type: type = fn_type @Dup [concrete]
// CHECK:STDOUT:   %Dup: %Dup.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.d83: <witness> = require_complete_type %T.as_type.c1c [symbolic]
// CHECK:STDOUT:   %require_complete.b86: <witness> = require_complete_type %tuple.type.db8 [symbolic]
// CHECK:STDOUT:   %p.patt: %pattern_type.aac = value_binding_pattern p [symbolic]
// CHECK:STDOUT:   %Copy.assoc_type: type = assoc_entity_type @Copy [concrete]
// CHECK:STDOUT:   %assoc0.7fa: %Copy.assoc_type = assoc_entity element0, imports.%Core.import_ref.b5f [concrete]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.921: <witness> = lookup_impl_witness %tuple.type.db8, @Copy [symbolic]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8ea: type = pack_type %Copy.type, %int_2 [concrete]
// CHECK:STDOUT:   %.b2f: %pack_type.8ea = pack_value (%T.f84, %T.f84) [symbolic]
// CHECK:STDOUT:   %.ae9: require_specific_def_type = require_specific_def @tuple.type.as.Copy.impl(%int_2, %.b2f) [symbolic]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %tuple.type.db8, (%Copy.lookup_impl_witness.921) [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.b87: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [symbolic]
// CHECK:STDOUT:   %.93a: type = fn_type_with_self_type %Copy.WithSelf.Op.type.b87, %Copy.facet [symbolic]
// CHECK:STDOUT:   %impl.elem0.0a9: %.93a = impl_witness_access %Copy.lookup_impl_witness.921, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.bac: <specific function> = specific_impl_function %impl.elem0.0a9, @Copy.WithSelf.Op(%Copy.facet) [symbolic]
// CHECK:STDOUT:   %Eq.type: type = facet_type <@Eq> [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %Other: type = symbolic_binding Other, 0 [symbolic]
// CHECK:STDOUT:   %EqWith.type.98e: type = facet_type <@EqWith, @EqWith(%Other)> [symbolic]
// CHECK:STDOUT:   %Self.d94: %EqWith.type.98e = symbolic_binding Self, 1 [symbolic]
// CHECK:STDOUT:   %EqWith.assoc_type.85b: type = assoc_entity_type @EqWith, @EqWith(%Other) [symbolic]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.b82: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%Other, %Self.d94) [symbolic]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.ae3: %EqWith.WithSelf.Equal.type.b82 = struct_value () [symbolic]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %pattern_type.9a587c.2: type = pattern_type %Eq.type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.2: %pattern_type.9a587c.2 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.f45530.1: %Eq.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %tuple.type.693f06.1: type = tuple_type (%Eq.type, %Eq.type) [concrete]
// CHECK:STDOUT:   %tuple.771: %tuple.type.693f06.1 = tuple_value (%T.f45530.1, %T.f45530.1) [symbolic]
// CHECK:STDOUT:   %T.as_type.190bb7.1: type = facet_access_type %T.f45530.1 [symbolic]
// CHECK:STDOUT:   %tuple.type.f50: type = tuple_type (%T.as_type.190bb7.1, %T.as_type.190bb7.1) [symbolic]
// CHECK:STDOUT:   %pattern_type.9f5: type = pattern_type %tuple.type.f50 [symbolic]
// CHECK:STDOUT:   %a.param_patt.4b6: %pattern_type.9f5 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %a.patt.895: %pattern_type.9f5 = wrapper_binding_pattern a, %a.param_patt.4b6 [symbolic]
// CHECK:STDOUT:   %b.param_patt.d8d: %pattern_type.9f5 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %b.patt.516: %pattern_type.9f5 = wrapper_binding_pattern b, %b.param_patt.d8d [symbolic]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %Same.type: type = fn_type @Same [concrete]
// CHECK:STDOUT:   %Same: %Same.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.f79: <witness> = require_complete_type %tuple.type.f50 [symbolic]
// CHECK:STDOUT:   %EqWith.type.234: type = facet_type <@EqWith, @EqWith(%tuple.type.f50)> [symbolic]
// CHECK:STDOUT:   %EqWith.assoc_type.9f8: type = assoc_entity_type @EqWith, @EqWith(%tuple.type.f50) [symbolic]
// CHECK:STDOUT:   %assoc0.3cb: %EqWith.assoc_type.9f8 = assoc_entity element0, imports.%Core.import_ref.5ba [symbolic]
// CHECK:STDOUT:   %require_complete.c13: <witness> = require_complete_type %EqWith.type.234 [symbolic]
// CHECK:STDOUT:   %assoc0.d00a4a.3: %EqWith.assoc_type.85b = assoc_entity element0, imports.%Core.import_ref.2e55e8.3 [symbolic]
// CHECK:STDOUT:   %EqWith.lookup_impl_witness.7e4: <witness> = lookup_impl_witness %tuple.type.f50, @EqWith, @EqWith(%tuple.type.f50) [symbolic]
// CHECK:STDOUT:   %pack_type.8f6539.2: type = pack_type %Eq.type, %int_2 [concrete]
// CHECK:STDOUT:   %.730: %pack_type.8f6539.2 = pack_value (%T.f45530.1, %T.f45530.1) [symbolic]
// CHECK:STDOUT:   %.a4a: require_specific_def_type = require_specific_def @tuple.type.as.EqWith.impl(%int_2, %.730) [symbolic]
// CHECK:STDOUT:   %EqWith.facet.182: %EqWith.type.234 = facet_value %tuple.type.f50, (%EqWith.lookup_impl_witness.7e4) [symbolic]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f0f: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%tuple.type.f50, %EqWith.facet.182) [symbolic]
// CHECK:STDOUT:   %.44a: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f0f, %EqWith.facet.182 [symbolic]
// CHECK:STDOUT:   %impl.elem0.dc4: %.44a = impl_witness_access %EqWith.lookup_impl_witness.7e4, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.12d: <specific function> = specific_impl_function %impl.elem0.dc4, @EqWith.WithSelf.Equal(%tuple.type.f50, %EqWith.facet.182) [symbolic]
// CHECK:STDOUT:   %Ordered.type: type = facet_type <@Ordered> [concrete]
// CHECK:STDOUT:   %OrderedWith.type.ad8: type = generic_interface_type @OrderedWith [concrete]
// CHECK:STDOUT:   %OrderedWith.generic: %OrderedWith.type.ad8 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.type.32a: type = facet_type <@OrderedWith, @OrderedWith(%Other)> [symbolic]
// CHECK:STDOUT:   %Self.7df: %OrderedWith.type.32a = symbolic_binding Self, 1 [symbolic]
// CHECK:STDOUT:   %OrderedWith.assoc_type.1d2: type = assoc_entity_type @OrderedWith, @OrderedWith(%Other) [symbolic]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.b87: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(%Other, %Self.7df) [symbolic]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.9e1: %OrderedWith.WithSelf.Less.type.b87 = struct_value () [symbolic]
// CHECK:STDOUT:   %pattern_type.9a587c.3: type = pattern_type %Ordered.type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.3: %pattern_type.9a587c.3 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.f45530.2: %Ordered.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %U.patt: %pattern_type.9a587c.3 = symbolic_binding_pattern U, 1 [symbolic]
// CHECK:STDOUT:   %U: %Ordered.type = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %tuple.type.693f06.2: type = tuple_type (%Ordered.type, %Ordered.type) [concrete]
// CHECK:STDOUT:   %tuple.a01: %tuple.type.693f06.2 = tuple_value (%T.f45530.2, %U) [symbolic]
// CHECK:STDOUT:   %T.as_type.190bb7.2: type = facet_access_type %T.f45530.2 [symbolic]
// CHECK:STDOUT:   %U.as_type: type = facet_access_type %U [symbolic]
// CHECK:STDOUT:   %tuple.type.d09: type = tuple_type (%T.as_type.190bb7.2, %U.as_type) [symbolic]
// CHECK:STDOUT:   %pattern_type.05e: type = pattern_type %tuple.type.d09 [symbolic]
// CHECK:STDOUT:   %a.param_patt.2ba: %pattern_type.05e = value_param_pattern [symbolic]
// CHECK:STDOUT:   %a.patt.407: %pattern_type.05e = wrapper_binding_pattern a, %a.param_patt.2ba [symbolic]
// CHECK:STDOUT:   %b.param_patt.65a: %pattern_type.05e = value_param_pattern [symbolic]
// CHECK:STDOUT:   %b.patt.816: %pattern_type.05e = wrapper_binding_pattern b, %b.param_patt.65a [symbolic]
// CHECK:STDOUT:   %Before.type: type = fn_type @Before [concrete]
// CHECK:STDOUT:   %Before: %Before.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.eca: <witness> = require_complete_type %tuple.type.d09 [symbolic]
// CHECK:STDOUT:   %OrderedWith.type.599: type = facet_type <@OrderedWith, @OrderedWith(%tuple.type.d09)> [symbolic]
// CHECK:STDOUT:   %OrderedWith.assoc_type.33f: type = assoc_entity_type @OrderedWith, @OrderedWith(%tuple.type.d09) [symbolic]
// CHECK:STDOUT:   %assoc0.f60: %OrderedWith.assoc_type.33f = assoc_entity element0, imports.%Core.import_ref.e7a5 [symbolic]
// CHECK:STDOUT:   %require_complete.e51: <witness> = require_complete_type %OrderedWith.type.599 [symbolic]
// CHECK:STDOUT:   %assoc0.13c: %OrderedWith.assoc_type.1d2 = assoc_entity element0, imports.%Core.import_ref.447cae.1 [symbolic]
// CHECK:STDOUT:   %OrderedWith.lookup_impl_witness.52e: <witness> = lookup_impl_witness %tuple.type.d09, @OrderedWith, @OrderedWith(%tuple.type.d09) [symbolic]
// CHECK:STDOUT:   %pack_type.8f6539.3: type = pack_type %Ordered.type, %int_2 [concrete]
// CHECK:STDOUT:   %.abb: %pack_type.8f6539.3 = pack_value (%T.f45530.2, %U) [symbolic]
// CHECK:STDOUT:   %.791: require_specific_def_type = require_specific_def @tuple.type.as.OrderedWith.impl(%int_2, %.abb) [symbolic]
// CHECK:STDOUT:   %OrderedWith.facet.cef: %OrderedWith.type.599 = facet_value %tuple.type.d09, (%OrderedWith.lookup_impl_witness.52e) [symbolic]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.24b: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(%tuple.type.d09, %OrderedWith.facet.cef) [symbolic]
// CHECK:STDOUT:   %.8e6: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.24b, %OrderedWith.facet.cef [symbolic]
// CHECK:STDOUT:   %impl.elem0.d5d: %.8e6 = impl_witness_access %OrderedWith.lookup_impl_witness.52e, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.bff: <specific function> = specific_impl_function %impl.elem0.d5d, @OrderedWith.WithSelf.Less(%tuple.type.d09, %OrderedWith.facet.cef) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Eq = %Core.Eq
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Ordered = %Core.Ordered
// CHECK:STDOUT:     .OrderedWith = %Core.OrderedWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.014: %Copy.assoc_type = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%assoc0.7fa]
// CHECK:STDOUT:   %Core.import_ref.b5f: @Copy.WithSelf.%Copy.WithSelf.Op.type (%Copy.WithSelf.Op.type.c85f21.1) = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [symbolic = @Copy.WithSelf.%Copy.WithSelf.Op (constants.%Copy.WithSelf.Op.b85212.1)]
// CHECK:STDOUT:   %Core.Eq: type = import_ref Core//prelude/operators/comparison, Eq, loaded [concrete = constants.%Eq.type]
// CHECK:STDOUT:   %Core.import_ref.725: @EqWith.WithSelf.%EqWith.assoc_type (%EqWith.assoc_type.85b) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @EqWith.WithSelf.%assoc0 (constants.%assoc0.d00a4a.3)]
// CHECK:STDOUT:   %Core.import_ref.5ba: @EqWith.WithSelf.%EqWith.WithSelf.Equal.type (%EqWith.WithSelf.Equal.type.b82) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @EqWith.WithSelf.%EqWith.WithSelf.Equal (constants.%EqWith.WithSelf.Equal.ae3)]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.2e55e8.3 = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.Ordered: type = import_ref Core//prelude/operators/comparison, Ordered, loaded [concrete = constants.%Ordered.type]
// CHECK:STDOUT:   %Core.import_ref.ef7: @OrderedWith.WithSelf.%OrderedWith.assoc_type (%OrderedWith.assoc_type.1d2) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @OrderedWith.WithSelf.%assoc0 (constants.%assoc0.13c)]
// CHECK:STDOUT:   %Core.import_ref.e7a5: @OrderedWith.WithSelf.%OrderedWith.WithSelf.Less.type (%OrderedWith.WithSelf.Less.type.b87) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @OrderedWith.WithSelf.%OrderedWith.WithSelf.Less (constants.%OrderedWith.WithSelf.Less.9e1)]
// CHECK:STDOUT:   %Core.OrderedWith: %OrderedWith.type.ad8 = import_ref Core//prelude/operators/comparison, OrderedWith, loaded [concrete = constants.%OrderedWith.generic]
// CHECK:STDOUT:   %Core.import_ref.447cae.1 = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Dup.decl: %Dup.type = fn_decl @Dup [concrete = constants.%Dup] {
// CHECK:STDOUT:     %T.patt.loc4_9.1: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_9.2 (constants.%T.patt.fe6)]
// CHECK:STDOUT:     %x.param_patt.loc4_23.1: @Dup.%pattern_type.loc4_23 (%pattern_type.2c66b4.2) = value_param_pattern [symbolic = %x.param_patt.loc4_23.2 (constants.%x.param_patt)]
// CHECK:STDOUT:     %x.patt.loc4_23.1: @Dup.%pattern_type.loc4_23 (%pattern_type.2c66b4.2) = wrapper_binding_pattern x, %x.param_patt.loc4_23.1 [symbolic = %x.patt.loc4_23.2 (constants.%x.patt.cec)]
// CHECK:STDOUT:     %return.param_patt.loc4_36.1: @Dup.%pattern_type.loc4_36 (%pattern_type.aac) = out_param_pattern [symbolic = %return.param_patt.loc4_36.2 (constants.%return.param_patt.1c7)]
// CHECK:STDOUT:     %return.patt.loc4_28.1: @Dup.%pattern_type.loc4_36 (%pattern_type.aac) = return_slot_pattern %return.param_patt.loc4_36.1, %.loc4_36.6 [symbolic = %return.patt.loc4_28.2 (constants.%return.patt.e7a)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc4_32: %Copy.type = name_ref T, %T.loc4_9.2 [symbolic = %T.loc4_9.1 (constants.%T.f84)]
// CHECK:STDOUT:     %T.ref.loc4_35: %Copy.type = name_ref T, %T.loc4_9.2 [symbolic = %T.loc4_9.1 (constants.%T.f84)]
// CHECK:STDOUT:     %.loc4_36.3: %tuple.type.24a = tuple_literal (%T.ref.loc4_32, %T.ref.loc4_35) [symbolic = %tuple.loc4 (constants.%tuple.598)]
// CHECK:STDOUT:     %T.as_type.loc4_36.1: type = facet_access_type constants.%T.f84 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:     %.loc4_36.4: type = converted constants.%T.f84, %T.as_type.loc4_36.1 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:     %T.as_type.loc4_36.2: type = facet_access_type constants.%T.f84 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:     %.loc4_36.5: type = converted constants.%T.f84, %T.as_type.loc4_36.2 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:     %.loc4_36.6: type = converted %.loc4_36.3, constants.%tuple.type.db8 [symbolic = %tuple.type (constants.%tuple.type.db8)]
// CHECK:STDOUT:     %.loc4_36.7: Core.Form = init_form %.loc4_36.6 [symbolic = %.loc4_36.2 (constants.%.58c)]
// CHECK:STDOUT:     %.loc4_15: type = splice_block %Copy.ref.loc4 [concrete = constants.%Copy.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc4: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref.loc4: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_9.2: %Copy.type = symbolic_binding T, 0 [symbolic = %T.loc4_9.1 (constants.%T.f84)]
// CHECK:STDOUT:     %x.param: @Dup.%T.as_type.loc4_25.1 (%T.as_type.c1c) = value_param call_param0
// CHECK:STDOUT:     %.loc4_25.1: type = splice_block %.loc4_25.2 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)] {
// CHECK:STDOUT:       %T.ref.loc4_25: %Copy.type = name_ref T, %T.loc4_9.2 [symbolic = %T.loc4_9.1 (constants.%T.f84)]
// CHECK:STDOUT:       %T.as_type.loc4_25.2: type = facet_access_type %T.ref.loc4_25 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:       %.loc4_25.2: type = converted %T.ref.loc4_25, %T.as_type.loc4_25.2 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @Dup.%T.as_type.loc4_25.1 (%T.as_type.c1c) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref @Dup.%tuple.type (%tuple.type.db8) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Dup.%tuple.type (%tuple.type.db8) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Same.decl: %Same.type = fn_decl @Same [concrete = constants.%Same] {
// CHECK:STDOUT:     %T.patt.loc9_10.1: %pattern_type.9a587c.2 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_10.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:     %a.param_patt.loc9_22.1: @Same.%pattern_type (%pattern_type.9f5) = value_param_pattern [symbolic = %a.param_patt.loc9_22.2 (constants.%a.param_patt.4b6)]
// CHECK:STDOUT:     %a.patt.loc9_22.1: @Same.%pattern_type (%pattern_type.9f5) = wrapper_binding_pattern a, %a.param_patt.loc9_22.1 [symbolic = %a.patt.loc9_22.2 (constants.%a.patt.895)]
// CHECK:STDOUT:     %b.param_patt.loc9_33.1: @Same.%pattern_type (%pattern_type.9f5) = value_param_pattern [symbolic = %b.param_patt.loc9_33.2 (constants.%b.param_patt.d8d)]
// CHECK:STDOUT:     %b.patt.loc9_33.1: @Same.%pattern_type (%pattern_type.9f5) = wrapper_binding_pattern b, %b.param_patt.loc9_33.1 [symbolic = %b.patt.loc9_33.2 (constants.%b.patt.516)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc9_46.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc9_46.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc9_46.2: Core.Form = init_form %.loc9_46.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %.loc9_16: type = splice_block %Eq.ref [concrete = constants.%Eq.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Eq.ref: type = name_ref Eq, imports.%Core.Eq [concrete = constants.%Eq.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc9_10.2: %Eq.type = symbolic_binding T, 0 [symbolic = %T.loc9_10.1 (constants.%T.f45530.1)]
// CHECK:STDOUT:     %a.param: @Same.%tuple.type (%tuple.type.f50) = value_param call_param0
// CHECK:STDOUT:     %.loc9_29.1: type = splice_block %.loc9_29.5 [symbolic = %tuple.type (constants.%tuple.type.f50)] {
// CHECK:STDOUT:       %T.ref.loc9_25: %Eq.type = name_ref T, %T.loc9_10.2 [symbolic = %T.loc9_10.1 (constants.%T.f45530.1)]
// CHECK:STDOUT:       %T.ref.loc9_28: %Eq.type = name_ref T, %T.loc9_10.2 [symbolic = %T.loc9_10.1 (constants.%T.f45530.1)]
// CHECK:STDOUT:       %.loc9_29.2: %tuple.type.693f06.1 = tuple_literal (%T.ref.loc9_25, %T.ref.loc9_28) [symbolic = %tuple (constants.%tuple.771)]
// CHECK:STDOUT:       %T.as_type.loc9_29.2: type = facet_access_type constants.%T.f45530.1 [symbolic = %T.as_type.loc9_29.1 (constants.%T.as_type.190bb7.1)]
// CHECK:STDOUT:       %.loc9_29.3: type = converted constants.%T.f45530.1, %T.as_type.loc9_29.2 [symbolic = %T.as_type.loc9_29.1 (constants.%T.as_type.190bb7.1)]
// CHECK:STDOUT:       %T.as_type.loc9_29.3: type = facet_access_type constants.%T.f45530.1 [symbolic = %T.as_type.loc9_29.1 (constants.%T.as_type.190bb7.1)]
// CHECK:STDOUT:       %.loc9_29.4: type = converted constants.%T.f45530.1, %T.as_type.loc9_29.3 [symbolic = %T.as_type.loc9_29.1 (constants.%T.as_type.190bb7.1)]
// CHECK:STDOUT:       %.loc9_29.5: type = converted %.loc9_29.2, constants.%tuple.type.f50 [symbolic = %tuple.type (constants.%tuple.type.f50)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: @Same.%tuple.type (%tuple.type.f50) = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: @Same.%tuple.type (%tuple.type.f50) = value_param call_param1
// CHECK:STDOUT:     %.loc9_40.1: type = splice_block %.loc9_40.5 [symbolic = %tuple.type (constants.%tuple.type.f50)] {
// CHECK:STDOUT:       %T.ref.loc9_36: %Eq.type = name_ref T, %T.loc9_10.2 [symbolic = %T.loc9_10.1 (constants.%T.f45530.1)]
// CHECK:STDOUT:       %T.ref.loc9_39: %Eq.type = name_ref T, %T.loc9_10.2 [symbolic = %T.loc9_10.1 (constants.%T.f45530.1)]
// CHECK:STDOUT:       %.loc9_40.2: %tuple.type.693f06.1 = tuple_literal (%T.ref.loc9_36, %T.ref.loc9_39) [symbolic = %tuple (constants.%tuple.771)]
// CHECK:STDOUT:       %T.as_type.loc9_40.1: type = facet_access_type constants.%T.f45530.1 [symbolic = %T.as_type.loc9_29.1 (constants.%T.as_type.190bb7.1)]
// CHECK:STDOUT:       %.loc9_40.3: type = converted constants.%T.f45530.1, %T.as_type.loc9_40.1 [symbolic = %T.as_type.loc9_29.1 (constants.%T.as_type.190bb7.1)]
// CHECK:STDOUT:       %T.as_type.loc9_40.2: type = facet_access_type constants.%T.f45530.1 [symbolic = %T.as_type.loc9_29.1 (constants.%T.as_type.190bb7.1)]
// CHECK:STDOUT:       %.loc9_40.4: type = converted constants.%T.f45530.1, %T.as_type.loc9_40.2 [symbolic = %T.as_type.loc9_29.1 (constants.%T.as_type.190bb7.1)]
// CHECK:STDOUT:       %.loc9_40.5: type = converted %.loc9_40.2, constants.%tuple.type.f50 [symbolic = %tuple.type (constants.%tuple.type.f50)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: @Same.%tuple.type (%tuple.type.f50) = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Before.decl: %Before.type = fn_decl @Before [concrete = constants.%Before] {
// CHECK:STDOUT:     %T.patt.loc13_12.1: %pattern_type.9a587c.3 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc13_12.2 (constants.%T.patt.3a0592.3)]
// CHECK:STDOUT:     %U.patt.loc13_29.1: %pattern_type.9a587c.3 = symbolic_binding_pattern U, 1 [symbolic = %U.patt.loc13_29.2 (constants.%U.patt)]
// CHECK:STDOUT:     %a.param_patt.loc13_46.1: @Before.%pattern_type (%pattern_type.05e) = value_param_pattern [symbolic = %a.param_patt.loc13_46.2 (constants.%a.param_patt.2ba)]
// CHECK:STDOUT:     %a.patt.loc13_46.1: @Before.%pattern_type (%pattern_type.05e) = wrapper_binding_pattern a, %a.param_patt.loc13_46.1 [symbolic = %a.patt.loc13_46.2 (constants.%a.patt.407)]
// CHECK:STDOUT:     %b.param_patt.loc13_57.1: @Before.%pattern_type (%pattern_type.05e) = value_param_pattern [symbolic = %b.param_patt.loc13_57.2 (constants.%b.param_patt.65a)]
// CHECK:STDOUT:     %b.patt.loc13_57.1: @Before.%pattern_type (%pattern_type.05e) = wrapper_binding_pattern b, %b.param_patt.loc13_57.1 [symbolic = %b.patt.loc13_57.2 (constants.%b.patt.816)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc13_70.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc13_70.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc13_70.2: Core.Form = init_form %.loc13_70.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %.loc13_18: type = splice_block %Ordered.ref.loc13_18 [concrete = constants.%Ordered.type] {
// CHECK:STDOUT:       %.Self.frozen.loc13_12: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc13_14: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Ordered.ref.loc13_18: type = name_ref Ordered, imports.%Core.Ordered [concrete = constants.%Ordered.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc13_12.2: %Ordered.type = symbolic_binding T, 0 [symbolic = %T.loc13_12.1 (constants.%T.f45530.2)]
// CHECK:STDOUT:     %.loc13_35: type = splice_block %Ordered.ref.loc13_35 [concrete = constants.%Ordered.type] {
// CHECK:STDOUT:       %.Self.frozen.loc13_29: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc13_31: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Ordered.ref.loc13_35: type = name_ref Ordered, imports.%Core.Ordered [concrete = constants.%Ordered.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %U.loc13_29.2: %Ordered.type = symbolic_binding U, 1 [symbolic = %U.loc13_29.1 (constants.%U)]
// CHECK:STDOUT:     %a.param: @Before.%tuple.type (%tuple.type.d09) = value_param call_param0
// CHECK:STDOUT:     %.loc13_53.1: type = splice_block %.loc13_53.5 [symbolic = %tuple.type (constants.%tuple.type.d09)] {
// CHECK:STDOUT:       %T.ref.loc13_49: %Ordered.type = name_ref T, %T.loc13_12.2 [symbolic = %T.loc13_12.1 (constants.%T.f45530.2)]
// CHECK:STDOUT:       %U.ref.loc13_52: %Ordered.type = name_ref U, %U.loc13_29.2 [symbolic = %U.loc13_29.1 (constants.%U)]
// CHECK:STDOUT:       %.loc13_53.2: %tuple.type.693f06.2 = tuple_literal (%T.ref.loc13_49, %U.ref.loc13_52) [symbolic = %tuple (constants.%tuple.a01)]
// CHECK:STDOUT:       %T.as_type.loc13_53.2: type = facet_access_type constants.%T.f45530.2 [symbolic = %T.as_type.loc13_53.1 (constants.%T.as_type.190bb7.2)]
// CHECK:STDOUT:       %.loc13_53.3: type = converted constants.%T.f45530.2, %T.as_type.loc13_53.2 [symbolic = %T.as_type.loc13_53.1 (constants.%T.as_type.190bb7.2)]
// CHECK:STDOUT:       %U.as_type.loc13_53.2: type = facet_access_type constants.%U [symbolic = %U.as_type.loc13_53.1 (constants.%U.as_type)]
// CHECK:STDOUT:       %.loc13_53.4: type = converted constants.%U, %U.as_type.loc13_53.2 [symbolic = %U.as_type.loc13_53.1 (constants.%U.as_type)]
// CHECK:STDOUT:       %.loc13_53.5: type = converted %.loc13_53.2, constants.%tuple.type.d09 [symbolic = %tuple.type (constants.%tuple.type.d09)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: @Before.%tuple.type (%tuple.type.d09) = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: @Before.%tuple.type (%tuple.type.d09) = value_param call_param1
// CHECK:STDOUT:     %.loc13_64.1: type = splice_block %.loc13_64.5 [symbolic = %tuple.type (constants.%tuple.type.d09)] {
// CHECK:STDOUT:       %T.ref.loc13_60: %Ordered.type = name_ref T, %T.loc13_12.2 [symbolic = %T.loc13_12.1 (constants.%T.f45530.2)]
// CHECK:STDOUT:       %U.ref.loc13_63: %Ordered.type = name_ref U, %U.loc13_29.2 [symbolic = %U.loc13_29.1 (constants.%U)]
// CHECK:STDOUT:       %.loc13_64.2: %tuple.type.693f06.2 = tuple_literal (%T.ref.loc13_60, %U.ref.loc13_63) [symbolic = %tuple (constants.%tuple.a01)]
// CHECK:STDOUT:       %T.as_type.loc13_64: type = facet_access_type constants.%T.f45530.2 [symbolic = %T.as_type.loc13_53.1 (constants.%T.as_type.190bb7.2)]
// CHECK:STDOUT:       %.loc13_64.3: type = converted constants.%T.f45530.2, %T.as_type.loc13_64 [symbolic = %T.as_type.loc13_53.1 (constants.%T.as_type.190bb7.2)]
// CHECK:STDOUT:       %U.as_type.loc13_64: type = facet_access_type constants.%U [symbolic = %U.as_type.loc13_53.1 (constants.%U.as_type)]
// CHECK:STDOUT:       %.loc13_64.4: type = converted constants.%U, %U.as_type.loc13_64 [symbolic = %U.as_type.loc13_53.1 (constants.%U.as_type)]
// CHECK:STDOUT:       %.loc13_64.5: type = converted %.loc13_64.2, constants.%tuple.type.d09 [symbolic = %tuple.type (constants.%tuple.type.d09)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: @Before.%tuple.type (%tuple.type.d09) = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Dup(%T.loc4_9.2: %Copy.type) {
// CHECK:STDOUT:   %T.patt.loc4_9.2: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_9.2 (constants.%T.patt.fe6)]
// CHECK:STDOUT:   %T.loc4_9.1: %Copy.type = symbolic_binding T, 0 [symbolic = %T.loc4_9.1 (constants.%T.f84)]
// CHECK:STDOUT:   %T.as_type.loc4_25.1: type = facet_access_type %T.loc4_9.1 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:   %pattern_type.loc4_23: type = pattern_type %T.as_type.loc4_25.1 [symbolic = %pattern_type.loc4_23 (constants.%pattern_type.2c66b4.2)]
// CHECK:STDOUT:   %x.param_patt.loc4_23.2: @Dup.%pattern_type.loc4_23 (%pattern_type.2c66b4.2) = value_param_pattern [symbolic = %x.param_patt.loc4_23.2 (constants.%x.param_patt)]
// CHECK:STDOUT:   %x.patt.loc4_23.2: @Dup.%pattern_type.loc4_23 (%pattern_type.2c66b4.2) = wrapper_binding_pattern x, %x.param_patt.loc4_23.2 [symbolic = %x.patt.loc4_23.2 (constants.%x.patt.cec)]
// CHECK:STDOUT:   %tuple.loc4: %tuple.type.24a = tuple_value (%T.loc4_9.1, %T.loc4_9.1) [symbolic = %tuple.loc4 (constants.%tuple.598)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.as_type.loc4_25.1, %T.as_type.loc4_25.1) [symbolic = %tuple.type (constants.%tuple.type.db8)]
// CHECK:STDOUT:   %.loc4_36.2: Core.Form = init_form %tuple.type [symbolic = %.loc4_36.2 (constants.%.58c)]
// CHECK:STDOUT:   %pattern_type.loc4_36: type = pattern_type %tuple.type [symbolic = %pattern_type.loc4_36 (constants.%pattern_type.aac)]
// CHECK:STDOUT:   %return.param_patt.loc4_36.2: @Dup.%pattern_type.loc4_36 (%pattern_type.aac) = out_param_pattern [symbolic = %return.param_patt.loc4_36.2 (constants.%return.param_patt.1c7)]
// CHECK:STDOUT:   %return.patt.loc4_28.2: @Dup.%pattern_type.loc4_36 (%pattern_type.aac) = return_slot_pattern %return.param_patt.loc4_36.2, %tuple.type [symbolic = %return.patt.loc4_28.2 (constants.%return.patt.e7a)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_23: <witness> = require_complete_type %T.as_type.loc4_25.1 [symbolic = %require_complete.loc4_23 (constants.%require_complete.d83)]
// CHECK:STDOUT:   %require_complete.loc4_28: <witness> = require_complete_type %tuple.type [symbolic = %require_complete.loc4_28 (constants.%require_complete.b86)]
// CHECK:STDOUT:   %p.patt.loc5_8.2: @Dup.%pattern_type.loc4_36 (%pattern_type.aac) = value_binding_pattern p [symbolic = %p.patt.loc5_8.2 (constants.%p.patt)]
// CHECK:STDOUT:   %.loc6_11.1: %pack_type.8ea = pack_value (%T.loc4_9.1, %T.loc4_9.1) [symbolic = %.loc6_11.1 (constants.%.b2f)]
// CHECK:STDOUT:   %.loc6_11.2: require_specific_def_type = require_specific_def @tuple.type.as.Copy.impl(constants.%int_2, %.loc6_11.1) [symbolic = %.loc6_11.2 (constants.%.ae9)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.921)]
// CHECK:STDOUT:   %Copy.facet.loc6_11: %Copy.type = facet_value %tuple.type, (%Copy.lookup_impl_witness) [symbolic = %Copy.facet.loc6_11 (constants.%Copy.facet)]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.loc6_11) [symbolic = %Copy.WithSelf.Op.type (constants.%Copy.WithSelf.Op.type.b87)]
// CHECK:STDOUT:   %.loc6_11.3: type = fn_type_with_self_type %Copy.WithSelf.Op.type, %Copy.facet.loc6_11 [symbolic = %.loc6_11.3 (constants.%.93a)]
// CHECK:STDOUT:   %impl.elem0.loc6_11.2: @Dup.%.loc6_11.3 (%.93a) = impl_witness_access %Copy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc6_11.2 (constants.%impl.elem0.0a9)]
// CHECK:STDOUT:   %specific_impl_fn.loc6_11.2: <specific function> = specific_impl_function %impl.elem0.loc6_11.2, @Copy.WithSelf.Op(%Copy.facet.loc6_11) [symbolic = %specific_impl_fn.loc6_11.2 (constants.%specific_impl_fn.bac)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @Dup.%T.as_type.loc4_25.1 (%T.as_type.c1c)) -> out %return.param: @Dup.%tuple.type (%tuple.type.db8) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref.loc5_20: @Dup.%T.as_type.loc4_25.1 (%T.as_type.c1c) = name_ref x, %x
// CHECK:STDOUT:     %x.ref.loc5_23: @Dup.%T.as_type.loc4_25.1 (%T.as_type.c1c) = name_ref x, %x
// CHECK:STDOUT:     %.loc5_24.1: @Dup.%tuple.type (%tuple.type.db8) = tuple_literal (%x.ref.loc5_20, %x.ref.loc5_23)
// CHECK:STDOUT:     %tuple.loc5: @Dup.%tuple.type (%tuple.type.db8) = tuple_value (%x.ref.loc5_20, %x.ref.loc5_23)
// CHECK:STDOUT:     %.loc5_24.2: @Dup.%tuple.type (%tuple.type.db8) = converted %.loc5_24.1, %tuple.loc5
// CHECK:STDOUT:     %.loc5_15.1: type = splice_block %.loc5_15.5 [symbolic = %tuple.type (constants.%tuple.type.db8)] {
// CHECK:STDOUT:       %T.ref.loc5_11: %Copy.type = name_ref T, %T.loc4_9.2 [symbolic = %T.loc4_9.1 (constants.%T.f84)]
// CHECK:STDOUT:       %T.ref.loc5_14: %Copy.type = name_ref T, %T.loc4_9.2 [symbolic = %T.loc4_9.1 (constants.%T.f84)]
// CHECK:STDOUT:       %.loc5_15.2: %tuple.type.24a = tuple_literal (%T.ref.loc5_11, %T.ref.loc5_14) [symbolic = %tuple.loc4 (constants.%tuple.598)]
// CHECK:STDOUT:       %T.as_type.loc5_15.1: type = facet_access_type constants.%T.f84 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:       %.loc5_15.3: type = converted constants.%T.f84, %T.as_type.loc5_15.1 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:       %T.as_type.loc5_15.2: type = facet_access_type constants.%T.f84 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:       %.loc5_15.4: type = converted constants.%T.f84, %T.as_type.loc5_15.2 [symbolic = %T.as_type.loc4_25.1 (constants.%T.as_type.c1c)]
// CHECK:STDOUT:       %.loc5_15.5: type = converted %.loc5_15.2, constants.%tuple.type.db8 [symbolic = %tuple.type (constants.%tuple.type.db8)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: @Dup.%tuple.type (%tuple.type.db8) = wrapper_binding p, %.loc5_24.2
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %p.patt.loc5_8.1: @Dup.%pattern_type.loc4_36 (%pattern_type.aac) = value_binding_pattern p [symbolic = %p.patt.loc5_8.2 (constants.%p.patt)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p.ref: @Dup.%tuple.type (%tuple.type.db8) = name_ref p, %p
// CHECK:STDOUT:     %Core.ref.loc6: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Copy.ref.loc6: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:     %Op.ref: %Copy.assoc_type = name_ref Op, imports.%Core.import_ref.014 [concrete = constants.%assoc0.7fa]
// CHECK:STDOUT:     %impl.elem0.loc6_11.1: @Dup.%.loc6_11.3 (%.93a) = impl_witness_access constants.%Copy.lookup_impl_witness.921, element0 [symbolic = %impl.elem0.loc6_11.2 (constants.%impl.elem0.0a9)]
// CHECK:STDOUT:     %bound_method.loc6_11: <bound method> = bound_method %p.ref, %impl.elem0.loc6_11.1
// CHECK:STDOUT:     %Copy.facet.loc6_27.1: %Copy.type = facet_value constants.%tuple.type.db8, (constants.%Copy.lookup_impl_witness.921) [symbolic = %Copy.facet.loc6_11 (constants.%Copy.facet)]
// CHECK:STDOUT:     %.loc6_27.1: %Copy.type = converted constants.%tuple.type.db8, %Copy.facet.loc6_27.1 [symbolic = %Copy.facet.loc6_11 (constants.%Copy.facet)]
// CHECK:STDOUT:     %Copy.facet.loc6_27.2: %Copy.type = facet_value constants.%tuple.type.db8, (constants.%Copy.lookup_impl_witness.921) [symbolic = %Copy.facet.loc6_11 (constants.%Copy.facet)]
// CHECK:STDOUT:     %.loc6_27.2: %Copy.type = converted constants.%tuple.type.db8, %Copy.facet.loc6_27.2 [symbolic = %Copy.facet.loc6_11 (constants.%Copy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc6_11.1: <specific function> = specific_impl_function %impl.elem0.loc6_11.1, @Copy.WithSelf.Op(constants.%Copy.facet) [symbolic = %specific_impl_fn.loc6_11.2 (constants.%specific_impl_fn.bac)]
// CHECK:STDOUT:     %bound_method.loc6_27: <bound method> = bound_method %p.ref, %specific_impl_fn.loc6_11.1
// CHECK:STDOUT:     %.loc4_36.1: ref @Dup.%tuple.type (%tuple.type.db8) = splice_block %return.param {}
// CHECK:STDOUT:     %Copy.WithSelf.Op.call: init @Dup.%tuple.type (%tuple.type.db8) to %.loc4_36.1 = call %bound_method.loc6_27(%p.ref)
// CHECK:STDOUT:     return %Copy.WithSelf.Op.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Same(%T.loc9_10.2: %Eq.type) {
// CHECK:STDOUT:   %T.patt.loc9_10.2: %pattern_type.9a587c.2 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_10.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:   %T.loc9_10.1: %Eq.type = symbolic_binding T, 0 [symbolic = %T.loc9_10.1 (constants.%T.f45530.1)]
// CHECK:STDOUT:   %tuple: %tuple.type.693f06.1 = tuple_value (%T.loc9_10.1, %T.loc9_10.1) [symbolic = %tuple (constants.%tuple.771)]
// CHECK:STDOUT:   %T.as_type.loc9_29.1: type = facet_access_type %T.loc9_10.1 [symbolic = %T.as_type.loc9_29.1 (constants.%T.as_type.190bb7.1)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.as_type.loc9_29.1, %T.as_type.loc9_29.1) [symbolic = %tuple.type (constants.%tuple.type.f50)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %tuple.type [symbolic = %pattern_type (constants.%pattern_type.9f5)]
// CHECK:STDOUT:   %a.param_patt.loc9_22.2: @Same.%pattern_type (%pattern_type.9f5) = value_param_pattern [symbolic = %a.param_patt.loc9_22.2 (constants.%a.param_patt.4b6)]
// CHECK:STDOUT:   %a.patt.loc9_22.2: @Same.%pattern_type (%pattern_type.9f5) = wrapper_binding_pattern a, %a.param_patt.loc9_22.2 [symbolic = %a.patt.loc9_22.2 (constants.%a.patt.895)]
// CHECK:STDOUT:   %b.param_patt.loc9_33.2: @Same.%pattern_type (%pattern_type.9f5) = value_param_pattern [symbolic = %b.param_patt.loc9_33.2 (constants.%b.param_patt.d8d)]
// CHECK:STDOUT:   %b.patt.loc9_33.2: @Same.%pattern_type (%pattern_type.9f5) = wrapper_binding_pattern b, %b.param_patt.loc9_33.2 [symbolic = %b.patt.loc9_33.2 (constants.%b.patt.516)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9: <witness> = require_complete_type %tuple.type [symbolic = %require_complete.loc9 (constants.%require_complete.f79)]
// CHECK:STDOUT:   %EqWith.type.loc10_12.2: type = facet_type <@EqWith, @EqWith(%tuple.type)> [symbolic = %EqWith.type.loc10_12.2 (constants.%EqWith.type.234)]
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %EqWith.type.loc10_12.2 [symbolic = %require_complete.loc10 (constants.%require_complete.c13)]
// CHECK:STDOUT:   %EqWith.assoc_type: type = assoc_entity_type @EqWith, @EqWith(%tuple.type) [symbolic = %EqWith.assoc_type (constants.%EqWith.assoc_type.9f8)]
// CHECK:STDOUT:   %assoc0: @Same.%EqWith.assoc_type (%EqWith.assoc_type.9f8) = assoc_entity element0, imports.%Core.import_ref.5ba [symbolic = %assoc0 (constants.%assoc0.3cb)]
// CHECK:STDOUT:   %.loc10_12.2: %pack_type.8f6539.2 = pack_value (%T.loc9_10.1, %T.loc9_10.1) [symbolic = %.loc10_12.2 (constants.%.730)]
// CHECK:STDOUT:   %.loc10_12.3: require_specific_def_type = require_specific_def @tuple.type.as.EqWith.impl(constants.%int_2, %.loc10_12.2) [symbolic = %.loc10_12.3 (constants.%.a4a)]
// CHECK:STDOUT:   %EqWith.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type, @EqWith, @EqWith(%tuple.type) [symbolic = %EqWith.lookup_impl_witness (constants.%EqWith.lookup_impl_witness.7e4)]
// CHECK:STDOUT:   %EqWith.facet: @Same.%EqWith.type.loc10_12.2 (%EqWith.type.234) = facet_value %tuple.type, (%EqWith.lookup_impl_witness) [symbolic = %EqWith.facet (constants.%EqWith.facet.182)]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%tuple.type, %EqWith.facet) [symbolic = %EqWith.WithSelf.Equal.type (constants.%EqWith.WithSelf.Equal.type.f0f)]
// CHECK:STDOUT:   %.loc10_12.4: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type, %EqWith.facet [symbolic = %.loc10_12.4 (constants.%.44a)]
// CHECK:STDOUT:   %impl.elem0.loc10_12.2: @Same.%.loc10_12.4 (%.44a) = impl_witness_access %EqWith.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc10_12.2 (constants.%impl.elem0.dc4)]
// CHECK:STDOUT:   %specific_impl_fn.loc10_12.2: <specific function> = specific_impl_function %impl.elem0.loc10_12.2, @EqWith.WithSelf.Equal(%tuple.type, %EqWith.facet) [symbolic = %specific_impl_fn.loc10_12.2 (constants.%specific_impl_fn.12d)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%a.param: @Same.%tuple.type (%tuple.type.f50), %b.param: @Same.%tuple.type (%tuple.type.f50)) -> out %return.param: bool {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %a.ref: @Same.%tuple.type (%tuple.type.f50) = name_ref a, %a
// CHECK:STDOUT:     %b.ref: @Same.%tuple.type (%tuple.type.f50) = name_ref b, %b
// CHECK:STDOUT:     %EqWith.type.loc10_12.1: type = facet_type <@EqWith, @EqWith(constants.%tuple.type.f50)> [symbolic = %EqWith.type.loc10_12.2 (constants.%EqWith.type.234)]
// CHECK:STDOUT:     %.loc10_12.1: @Same.%EqWith.assoc_type (%EqWith.assoc_type.9f8) = specific_constant imports.%Core.import_ref.725, @EqWith.WithSelf(constants.%tuple.type.f50, constants.%Self.d94) [symbolic = %assoc0 (constants.%assoc0.3cb)]
// CHECK:STDOUT:     %Equal.ref: @Same.%EqWith.assoc_type (%EqWith.assoc_type.9f8) = name_ref Equal, %.loc10_12.1 [symbolic = %assoc0 (constants.%assoc0.3cb)]
// CHECK:STDOUT:     %impl.elem0.loc10_12.1: @Same.%.loc10_12.4 (%.44a) = impl_witness_access constants.%EqWith.lookup_impl_witness.7e4, element0 [symbolic = %impl.elem0.loc10_12.2 (constants.%impl.elem0.dc4)]
// CHECK:STDOUT:     %bound_method.loc10_12.1: <bound method> = bound_method %a.ref, %impl.elem0.loc10_12.1
// CHECK:STDOUT:     %specific_impl_fn.loc10_12.1: <specific function> = specific_impl_function %impl.elem0.loc10_12.1, @EqWith.WithSelf.Equal(constants.%tuple.type.f50, constants.%EqWith.facet.182) [symbolic = %specific_impl_fn.loc10_12.2 (constants.%specific_impl_fn.12d)]
// CHECK:STDOUT:     %bound_method.loc10_12.2: <bound method> = bound_method %a.ref, %specific_impl_fn.loc10_12.1
// CHECK:STDOUT:     %EqWith.WithSelf.Equal.call: init bool = call %bound_method.loc10_12.2(%a.ref, %b.ref)
// CHECK:STDOUT:     return %EqWith.WithSelf.Equal.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Before(%T.loc13_12.2: %Ordered.type, %U.loc13_29.2: %Ordered.type) {
// CHECK:STDOUT:   %T.patt.loc13_12.2: %pattern_type.9a587c.3 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc13_12.2 (constants.%T.patt.3a0592.3)]
// CHECK:STDOUT:   %T.loc13_12.1: %Ordered.type = symbolic_binding T, 0 [symbolic = %T.loc13_12.1 (constants.%T.f45530.2)]
// CHECK:STDOUT:   %U.patt.loc13_29.2: %pattern_type.9a587c.3 = symbolic_binding_pattern U, 1 [symbolic = %U.patt.loc13_29.2 (constants.%U.patt)]
// CHECK:STDOUT:   %U.loc13_29.1: %Ordered.type = symbolic_binding U, 1 [symbolic = %U.loc13_29.1 (constants.%U)]
// CHECK:STDOUT:   %tuple: %tuple.type.693f06.2 = tuple_value (%T.loc13_12.1, %U.loc13_29.1) [symbolic = %tuple (constants.%tuple.a01)]
// CHECK:STDOUT:   %T.as_type.loc13_53.1: type = facet_access_type %T.loc13_12.1 [symbolic = %T.as_type.loc13_53.1 (constants.%T.as_type.190bb7.2)]
// CHECK:STDOUT:   %U.as_type.loc13_53.1: type = facet_access_type %U.loc13_29.1 [symbolic = %U.as_type.loc13_53.1 (constants.%U.as_type)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.as_type.loc13_53.1, %U.as_type.loc13_53.1) [symbolic = %tuple.type (constants.%tuple.type.d09)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %tuple.type [symbolic = %pattern_type (constants.%pattern_type.05e)]
// CHECK:STDOUT:   %a.param_patt.loc13_46.2: @Before.%pattern_type (%pattern_type.05e) = value_param_pattern [symbolic = %a.param_patt.loc13_46.2 (constants.%a.param_patt.2ba)]
// CHECK:STDOUT:   %a.patt.loc13_46.2: @Before.%pattern_type (%pattern_type.05e) = wrapper_binding_pattern a, %a.param_patt.loc13_46.2 [symbolic = %a.patt.loc13_46.2 (constants.%a.patt.407)]
// CHECK:STDOUT:   %b.param_patt.loc13_57.2: @Before.%pattern_type (%pattern_type.05e) = value_param_pattern [symbolic = %b.param_patt.loc13_57.2 (constants.%b.param_patt.65a)]
// CHECK:STDOUT:   %b.patt.loc13_57.2: @Before.%pattern_type (%pattern_type.05e) = wrapper_binding_pattern b, %b.param_patt.loc13_57.2 [symbolic = %b.patt.loc13_57.2 (constants.%b.patt.816)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc13: <witness> = require_complete_type %tuple.type [symbolic = %require_complete.loc13 (constants.%require_complete.eca)]
// CHECK:STDOUT:   %OrderedWith.type.loc14_12.2: type = facet_type <@OrderedWith, @OrderedWith(%tuple.type)> [symbolic = %OrderedWith.type.loc14_12.2 (constants.%OrderedWith.type.599)]
// CHECK:STDOUT:   %require_complete.loc14: <witness> = require_complete_type %OrderedWith.type.loc14_12.2 [symbolic = %require_complete.loc14 (constants.%require_complete.e51)]
// CHECK:STDOUT:   %OrderedWith.assoc_type: type = assoc_entity_type @OrderedWith, @OrderedWith(%tuple.type) [symbolic = %OrderedWith.assoc_type (constants.%OrderedWith.assoc_type.33f)]
// CHECK:STDOUT:   %assoc0: @Before.%OrderedWith.assoc_type (%OrderedWith.assoc_type.33f) = assoc_entity element0, imports.%Core.import_ref.e7a5 [symbolic = %assoc0 (constants.%assoc0.f60)]
// CHECK:STDOUT:   %.loc14_12.2: %pack_type.8f6539.3 = pack_value (%T.loc13_12.1, %U.loc13_29.1) [symbolic = %.loc14_12.2 (constants.%.abb)]
// CHECK:STDOUT:   %.loc14_12.3: require_specific_def_type = require_specific_def @tuple.type.as.OrderedWith.impl(constants.%int_2, %.loc14_12.2) [symbolic = %.loc14_12.3 (constants.%.791)]
// CHECK:STDOUT:   %OrderedWith.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type, @OrderedWith, @OrderedWith(%tuple.type) [symbolic = %OrderedWith.lookup_impl_witness (constants.%OrderedWith.lookup_impl_witness.52e)]
// CHECK:STDOUT:   %OrderedWith.facet: @Before.%OrderedWith.type.loc14_12.2 (%OrderedWith.type.599) = facet_value %tuple.type, (%OrderedWith.lookup_impl_witness) [symbolic = %OrderedWith.facet (constants.%OrderedWith.facet.cef)]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(%tuple.type, %OrderedWith.facet) [symbolic = %OrderedWith.WithSelf.Less.type (constants.%OrderedWith.WithSelf.Less.type.24b)]
// CHECK:STDOUT:   %.loc14_12.4: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type, %OrderedWith.facet [symbolic = %.loc14_12.4 (constants.%.8e6)]
// CHECK:STDOUT:   %impl.elem0.loc14_12.2: @Before.%.loc14_12.4 (%.8e6) = impl_witness_access %OrderedWith.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc14_12.2 (constants.%impl.elem0.d5d)]
// CHECK:STDOUT:   %specific_impl_fn.loc14_12.2: <specific function> = specific_impl_function %impl.elem0.loc14_12.2, @OrderedWith.WithSelf.Less(%tuple.type, %OrderedWith.facet) [symbolic = %specific_impl_fn.loc14_12.2 (constants.%specific_impl_fn.bff)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%a.param: @Before.%tuple.type (%tuple.type.d09), %b.param: @Before.%tuple.type (%tuple.type.d09)) -> out %return.param: bool {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %a.ref: @Before.%tuple.type (%tuple.type.d09) = name_ref a, %a
// CHECK:STDOUT:     %b.ref: @Before.%tuple.type (%tuple.type.d09) = name_ref b, %b
// CHECK:STDOUT:     %OrderedWith.type.loc14_12.1: type = facet_type <@OrderedWith, @OrderedWith(constants.%tuple.type.d09)> [symbolic = %OrderedWith.type.loc14_12.2 (constants.%OrderedWith.type.599)]
// CHECK:STDOUT:     %.loc14_12.1: @Before.%OrderedWith.assoc_type (%OrderedWith.assoc_type.33f) = specific_constant imports.%Core.import_ref.ef7, @OrderedWith.WithSelf(constants.%tuple.type.d09, constants.%Self.7df) [symbolic = %assoc0 (constants.%assoc0.f60)]
// CHECK:STDOUT:     %Less.ref: @Before.%OrderedWith.assoc_type (%OrderedWith.assoc_type.33f) = name_ref Less, %.loc14_12.1 [symbolic = %assoc0 (constants.%assoc0.f60)]
// CHECK:STDOUT:     %impl.elem0.loc14_12.1: @Before.%.loc14_12.4 (%.8e6) = impl_witness_access constants.%OrderedWith.lookup_impl_witness.52e, element0 [symbolic = %impl.elem0.loc14_12.2 (constants.%impl.elem0.d5d)]
// CHECK:STDOUT:     %bound_method.loc14_12.1: <bound method> = bound_method %a.ref, %impl.elem0.loc14_12.1
// CHECK:STDOUT:     %specific_impl_fn.loc14_12.1: <specific function> = specific_impl_function %impl.elem0.loc14_12.1, @OrderedWith.WithSelf.Less(constants.%tuple.type.d09, constants.%OrderedWith.facet.cef) [symbolic = %specific_impl_fn.loc14_12.2 (constants.%specific_impl_fn.bff)]
// CHECK:STDOUT:     %bound_method.loc14_12.2: <bound method> = bound_method %a.ref, %specific_impl_fn.loc14_12.1
// CHECK:STDOUT:     %OrderedWith.WithSelf.Less.call: init bool = call %bound_method.loc14_12.2(%a.ref, %b.ref)
// CHECK:STDOUT:     return %OrderedWith.WithSelf.Less.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Dup(constants.%T.f84) {
// CHECK:STDOUT:   %T.patt.loc4_9.2 => constants.%T.patt.fe6
// CHECK:STDOUT:   %T.loc4_9.1 => constants.%T.f84
// CHECK:STDOUT:   %T.as_type.loc4_25.1 => constants.%T.as_type.c1c
// CHECK:STDOUT:   %pattern_type.loc4_23 => constants.%pattern_type.2c66b4.2
// CHECK:STDOUT:   %x.param_patt.loc4_23.2 => constants.%x.param_patt
// CHECK:STDOUT:   %x.patt.loc4_23.2 => constants.%x.patt.cec
// CHECK:STDOUT:   %tuple.loc4 => constants.%tuple.598
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.db8
// CHECK:STDOUT:   %.loc4_36.2 => constants.%.58c
// CHECK:STDOUT:   %pattern_type.loc4_36 => constants.%pattern_type.aac
// CHECK:STDOUT:   %return.param_patt.loc4_36.2 => constants.%return.param_patt.1c7
// CHECK:STDOUT:   %return.patt.loc4_28.2 => constants.%return.patt.e7a
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Same(constants.%T.f45530.1) {
// CHECK:STDOUT:   %T.patt.loc9_10.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc9_10.1 => constants.%T.f45530.1
// CHECK:STDOUT:   %tuple => constants.%tuple.771
// CHECK:STDOUT:   %T.as_type.loc9_29.1 => constants.%T.as_type.190bb7.1
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.f50
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.9f5
// CHECK:STDOUT:   %a.param_patt.loc9_22.2 => constants.%a.param_patt.4b6
// CHECK:STDOUT:   %a.patt.loc9_22.2 => constants.%a.patt.895
// CHECK:STDOUT:   %b.param_patt.loc9_33.2 => constants.%b.param_patt.d8d
// CHECK:STDOUT:   %b.patt.loc9_33.2 => constants.%b.patt.516
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Before(constants.%T.f45530.2, constants.%U) {
// CHECK:STDOUT:   %T.patt.loc13_12.2 => constants.%T.patt.3a0592.3
// CHECK:STDOUT:   %T.loc13_12.1 => constants.%T.f45530.2
// CHECK:STDOUT:   %U.patt.loc13_29.2 => constants.%U.patt
// CHECK:STDOUT:   %U.loc13_29.1 => constants.%U
// CHECK:STDOUT:   %tuple => constants.%tuple.a01
// CHECK:STDOUT:   %T.as_type.loc13_53.1 => constants.%T.as_type.190bb7.2
// CHECK:STDOUT:   %U.as_type.loc13_53.1 => constants.%U.as_type
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.d09
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.05e
// CHECK:STDOUT:   %a.param_patt.loc13_46.2 => constants.%a.param_patt.2ba
// CHECK:STDOUT:   %a.patt.loc13_46.2 => constants.%a.patt.407
// CHECK:STDOUT:   %b.param_patt.loc13_57.2 => constants.%b.param_patt.65a
// CHECK:STDOUT:   %b.patt.loc13_57.2 => constants.%b.patt.816
// CHECK:STDOUT: }
// CHECK:STDOUT:
