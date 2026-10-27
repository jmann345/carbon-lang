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

// --- eq_wider_facet.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Same[... each T: Core.Eq & Core.Copy](a: (... each T), b: (... each T))
    -> bool {
  return a == b;
}
//@dump-sem-ir-end

fn Call(a: (i32, bool), b: (i32, bool)) -> bool {
  return Same(a, b);
}

// --- forward_wider_facet.carbon
library "[[@TEST_NAME]]";

fn TakeTuple[... each U: Core.Copy](unused u: (... each U)) {}
fn TakeTypes[... each U: type](unused u: (... each U)) {}
fn TakeOne[U: Core.Copy](unused u: U) {}

//@dump-sem-ir-begin
fn TakePack[... each U: Core.Copy](... unused each u: each U) {}

fn ForwardTuple[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  TakeTuple(t);
  TakeTypes(t);
  TakeOne(t);
}

fn ForwardPack[... each T: Core.Copy & Core.Destroy](... each x: each T) {
  TakePack(... each x);
}
//@dump-sem-ir-end

fn Call() {
  ForwardTuple((1 as i32, true));
  ForwardPack(2 as i32, false);
}

// --- import_forward_wider_facet_lib.carbon
library "[[@TEST_NAME]]";

fn G[... each U: Core.Copy](u: (... each U)) -> (... each U) { return u; }

fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) -> (... each T) {
  return G(t);
}

// --- import_forward_wider_facet.carbon
library "[[@TEST_NAME]]";

import library "import_forward_wider_facet_lib";

//@dump-sem-ir-begin
fn Concrete() -> (i32, bool) {
  return F((1 as i32, true));
}

fn Generic[... each T: Core.Copy & Core.Destroy & Core.Eq](t: (... each T))
    -> (... each T) {
  return F(t);
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
// CHECK:STDOUT: --- eq_wider_facet.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
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
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %BitAndWith.generic: %BitAndWith.type.a06 = struct_value () [concrete]
// CHECK:STDOUT:   %BitAndWith.type.411: type = facet_type <@BitAndWith, @BitAndWith(type)> [concrete]
// CHECK:STDOUT:   %BitAndWith.impl_witness: <witness> = impl_witness imports.%BitAndWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %BitAndWith.facet: %BitAndWith.type.411 = facet_value type, (%BitAndWith.impl_witness) [concrete]
// CHECK:STDOUT:   %BitAndWith.WithSelf.Op.type.0cf: type = fn_type @BitAndWith.WithSelf.Op, @BitAndWith.WithSelf(type, %BitAndWith.facet) [concrete]
// CHECK:STDOUT:   %.85c: type = fn_type_with_self_type %BitAndWith.WithSelf.Op.type.0cf, %BitAndWith.facet [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.type: type = fn_type @type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op: %type.as.BitAndWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.bound: <bound method> = bound_method %Eq.type, %type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Copy & @Eq> [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.dee276.1: type = pack_type %facet_type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.f66aac.1: type = pattern_type %pack_type.dee276.1 [symbolic]
// CHECK:STDOUT:   %T.patt.fcff5e.1: %pattern_type.f66aac.1 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T.49b384.1: %pack_type.dee276.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.c7260c.1: %pattern_type.f66aac.1 = pack_expansion_pattern %T.patt.fcff5e.1, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.375b6f.1: %facet_type = pack_element %T.49b384.1, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.7dbd9d.1: type = tuple_type (%pack_type.dee276.1) [symbolic]
// CHECK:STDOUT:   %tuple.8465a0.1: %tuple.type.7dbd9d.1 = tuple_value (%T.49b384.1) [symbolic]
// CHECK:STDOUT:   %pack_type.8fe525.1: type = pack_type %T.49b384.1, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.e97d0c.1: type = tuple_type (%pack_type.8fe525.1) [symbolic]
// CHECK:STDOUT:   %pattern_type.605822.1: type = pattern_type %tuple.type.e97d0c.1 [symbolic]
// CHECK:STDOUT:   %a.param_patt.8cd: %pattern_type.605822.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %a.patt.956: %pattern_type.605822.1 = wrapper_binding_pattern a, %a.param_patt.8cd [symbolic]
// CHECK:STDOUT:   %b.param_patt.a3e: %pattern_type.605822.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %b.patt.ce0: %pattern_type.605822.1 = wrapper_binding_pattern b, %b.param_patt.a3e [symbolic]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %Same.type: type = fn_type @Same [concrete]
// CHECK:STDOUT:   %Same: %Same.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.b74760.1: <witness> = require_complete_type %tuple.type.e97d0c.1 [symbolic]
// CHECK:STDOUT:   %EqWith.type.23f: type = facet_type <@EqWith, @EqWith(%tuple.type.e97d0c.1)> [symbolic]
// CHECK:STDOUT:   %EqWith.assoc_type.9a8: type = assoc_entity_type @EqWith, @EqWith(%tuple.type.e97d0c.1) [symbolic]
// CHECK:STDOUT:   %assoc0.151: %EqWith.assoc_type.9a8 = assoc_entity element0, imports.%Core.import_ref.5ba [symbolic]
// CHECK:STDOUT:   %require_complete.576: <witness> = require_complete_type %EqWith.type.23f [symbolic]
// CHECK:STDOUT:   %assoc0.d00a4a.3: %EqWith.assoc_type.85b = assoc_entity element0, imports.%Core.import_ref.2e55e8.3 [symbolic]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type %Eq.type, %arity [symbolic]
// CHECK:STDOUT:   %T.621: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.type.951: type = fn_type @tuple.type.as.EqWith.impl.Equal, @tuple.type.as.EqWith.impl(%arity, %T.621) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.d63: %tuple.type.as.EqWith.impl.Equal.type.951 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.lookup_impl_witness.69b: <witness> = lookup_impl_witness %tuple.type.e97d0c.1, @EqWith, @EqWith(%tuple.type.e97d0c.1) [symbolic]
// CHECK:STDOUT:   %.229: %pack_type.c29 = pack_facet_value %T.49b384.1 [symbolic]
// CHECK:STDOUT:   %.cd3: require_specific_def_type = require_specific_def @tuple.type.as.EqWith.impl(%arity, %.229) [symbolic]
// CHECK:STDOUT:   %EqWith.facet.419: %EqWith.type.23f = facet_value %tuple.type.e97d0c.1, (%EqWith.lookup_impl_witness.69b) [symbolic]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.f5a: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%tuple.type.e97d0c.1, %EqWith.facet.419) [symbolic]
// CHECK:STDOUT:   %.1b2: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.f5a, %EqWith.facet.419 [symbolic]
// CHECK:STDOUT:   %impl.elem0.bc9: %.1b2 = impl_witness_access %EqWith.lookup_impl_witness.69b, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.617: <specific function> = specific_impl_function %impl.elem0.bc9, @EqWith.WithSelf.Equal(%tuple.type.e97d0c.1, %EqWith.facet.419) [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.6ed: type = tuple_type (%i32, bool) [concrete]
// CHECK:STDOUT:   %pattern_type.cae: type = pattern_type %tuple.type.6ed [concrete]
// CHECK:STDOUT:   %a.param_patt.9a5: %pattern_type.cae = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt.c43: %pattern_type.cae = wrapper_binding_pattern a, %a.param_patt.9a5 [concrete]
// CHECK:STDOUT:   %b.param_patt.9f9: %pattern_type.cae = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt.3a3: %pattern_type.cae = wrapper_binding_pattern b, %b.param_patt.9f9 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8ea: type = pack_type %facet_type, %int_2 [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.type.9a2: type = fn_type @Int.as.EqWith.impl.Equal.1, @Int.as.EqWith.impl.e9c(%N, %M) [symbolic]
// CHECK:STDOUT:   %Int.as.EqWith.impl.Equal.792: %Int.as.EqWith.impl.Equal.type.9a2 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.34c: <witness> = impl_witness imports.%EqWith.impl_witness_table.09e, @Int.as.EqWith.impl.e9c(%int_32, %int_32) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value.d3a: %facet_type = facet_value %i32, (%EqWith.impl_witness.34c, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.fb2: <witness> = impl_witness imports.%EqWith.impl_witness_table.5db [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %facet_value.352: %facet_type = facet_value bool, (%EqWith.impl_witness.fb2, %Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %.406: %pack_type.8ea = pack_value (%facet_value.d3a, %facet_value.352) [concrete]
// CHECK:STDOUT:   %pattern_type.488: type = pattern_type %pack_type.8ea [concrete]
// CHECK:STDOUT:   %T.patt.31f: %pattern_type.488 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.586: %pattern_type.488 = pack_expansion_pattern %T.patt.31f, %arity.patt [symbolic]
// CHECK:STDOUT:   %.5a9: %facet_type = pack_element %.406, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.24a: type = tuple_type (%facet_type, %facet_type) [concrete]
// CHECK:STDOUT:   %tuple.c64: %tuple.type.24a = tuple_value (%facet_value.d3a, %facet_value.352) [concrete]
// CHECK:STDOUT:   %pack_type.fd0: type = pack_type %.406, %int_2 [concrete]
// CHECK:STDOUT:   %complete_type.61e: <witness> = complete_type_witness %tuple.type.6ed [concrete]
// CHECK:STDOUT:   %EqWith.type.8be: type = facet_type <@EqWith, @EqWith(%tuple.type.6ed)> [concrete]
// CHECK:STDOUT:   %EqWith.assoc_type.224: type = assoc_entity_type @EqWith, @EqWith(%tuple.type.6ed) [concrete]
// CHECK:STDOUT:   %assoc0.6c9: %EqWith.assoc_type.224 = assoc_entity element0, imports.%Core.import_ref.5ba [concrete]
// CHECK:STDOUT:   %complete_type.0cd: <witness> = complete_type_witness %EqWith.type.8be [concrete]
// CHECK:STDOUT:   %pack_type.8f6539.2: type = pack_type %Eq.type, %int_2 [concrete]
// CHECK:STDOUT:   %Eq.facet.824: %Eq.type = facet_value %i32, (%EqWith.impl_witness.34c) [concrete]
// CHECK:STDOUT:   %Eq.facet.c12: %Eq.type = facet_value bool, (%EqWith.impl_witness.fb2) [concrete]
// CHECK:STDOUT:   %.d1e: %pack_type.8f6539.2 = pack_value (%Eq.facet.824, %Eq.facet.c12) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.281: <witness> = impl_witness imports.%EqWith.impl_witness_table.2c6, @tuple.type.as.EqWith.impl(%int_2, %.d1e) [concrete]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.type.0a3: type = fn_type @tuple.type.as.EqWith.impl.Equal, @tuple.type.as.EqWith.impl(%int_2, %.d1e) [concrete]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.dc7: %tuple.type.as.EqWith.impl.Equal.type.0a3 = struct_value () [concrete]
// CHECK:STDOUT:   %.5f9: require_specific_def_type = require_specific_def @tuple.type.as.EqWith.impl(%int_2, %.d1e) [concrete]
// CHECK:STDOUT:   %EqWith.facet.015: %EqWith.type.8be = facet_value %tuple.type.6ed, (%EqWith.impl_witness.281) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.170: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%tuple.type.6ed, %EqWith.facet.015) [concrete]
// CHECK:STDOUT:   %.ae3: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.170, %EqWith.facet.015 [concrete]
// CHECK:STDOUT:   %tuple.type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %tuple.type.as.EqWith.impl.Equal.dc7, @tuple.type.as.EqWith.impl.Equal(%int_2, %.d1e) [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal.type: type = fn_type @bool.as.EqWith.impl.Equal [concrete]
// CHECK:STDOUT:   %bool.as.EqWith.impl.Equal: %bool.as.EqWith.impl.Equal.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Eq = %Core.Eq
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Eq: type = import_ref Core//prelude/operators/comparison, Eq, loaded [concrete = constants.%Eq.type]
// CHECK:STDOUT:   %Core.import_ref.725: @EqWith.WithSelf.%EqWith.assoc_type (%EqWith.assoc_type.85b) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @EqWith.WithSelf.%assoc0 (constants.%assoc0.d00a4a.3)]
// CHECK:STDOUT:   %Core.import_ref.5ba: @EqWith.WithSelf.%EqWith.WithSelf.Equal.type (%EqWith.WithSelf.Equal.type.b82) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @EqWith.WithSelf.%EqWith.WithSelf.Equal (constants.%EqWith.WithSelf.Equal.ae3)]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.2e55e8.3 = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.7da: @tuple.type.as.EqWith.impl.%tuple.type.as.EqWith.impl.Equal.type (%tuple.type.as.EqWith.impl.Equal.type.951) = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [symbolic = @tuple.type.as.EqWith.impl.%tuple.type.as.EqWith.impl.Equal (constants.%tuple.type.as.EqWith.impl.Equal.d63)]
// CHECK:STDOUT:   %Core.import_ref.640 = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.2c6 = impl_witness_table (%Core.import_ref.7da, %Core.import_ref.640), @tuple.type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.074: @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal.type (%Int.as.EqWith.impl.Equal.type.9a2) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.EqWith.impl.e9c.%Int.as.EqWith.impl.Equal (constants.%Int.as.EqWith.impl.Equal.792)]
// CHECK:STDOUT:   %Core.import_ref.449 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.09e = impl_witness_table (%Core.import_ref.074, %Core.import_ref.449), @Int.as.EqWith.impl.e9c [concrete]
// CHECK:STDOUT:   %Core.import_ref.bd66 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd66), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.a87: %bool.as.EqWith.impl.Equal.type = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.EqWith.impl.Equal]
// CHECK:STDOUT:   %Core.import_ref.e3a = import_ref Core//prelude/operators/comparison, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.5db = impl_witness_table (%Core.import_ref.a87, %Core.import_ref.e3a), @bool.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.bbf = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.bbf), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Same.decl: %Same.type = fn_decl @Same [concrete = constants.%Same] {
// CHECK:STDOUT:     %arity.patt.loc4_9.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_9.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc4_19.1: @Same.%pattern_type.loc4_19 (%pattern_type.f66aac.1) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_19.2 (constants.%T.patt.fcff5e.1)]
// CHECK:STDOUT:     %.loc4_9.1: @Same.%pattern_type.loc4_19 (%pattern_type.f66aac.1) = pack_expansion_pattern %T.patt.loc4_19.1, %arity.patt.loc4_9.1 [symbolic = %.loc4_9.2 (constants.%.c7260c.1)]
// CHECK:STDOUT:     %a.param_patt.loc4_43.1: @Same.%pattern_type.loc4_43 (%pattern_type.605822.1) = value_param_pattern [symbolic = %a.param_patt.loc4_43.2 (constants.%a.param_patt.8cd)]
// CHECK:STDOUT:     %a.patt.loc4_43.1: @Same.%pattern_type.loc4_43 (%pattern_type.605822.1) = wrapper_binding_pattern a, %a.param_patt.loc4_43.1 [symbolic = %a.patt.loc4_43.2 (constants.%a.patt.956)]
// CHECK:STDOUT:     %b.param_patt.loc4_60.1: @Same.%pattern_type.loc4_43 (%pattern_type.605822.1) = value_param_pattern [symbolic = %b.param_patt.loc4_60.2 (constants.%b.param_patt.a3e)]
// CHECK:STDOUT:     %b.patt.loc4_60.1: @Same.%pattern_type.loc4_43 (%pattern_type.605822.1) = wrapper_binding_pattern b, %b.param_patt.loc4_60.1 [symbolic = %b.patt.loc4_60.2 (constants.%b.patt.ce0)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc5_8.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5_8.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc5_8.2: Core.Form = init_form %.loc5_8.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %arity.loc4_9.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_9.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc4_29.1: type = splice_block %.loc4_29.3 [concrete = constants.%facet_type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc4_21: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Eq.ref: type = name_ref Eq, imports.%Core.Eq [concrete = constants.%Eq.type]
// CHECK:STDOUT:       %Core.ref.loc4_31: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %impl.elem1: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc4: <bound method> = bound_method %Eq.ref, %impl.elem1 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method.loc4(%Eq.ref, %Copy.ref) [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc4_29.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc4_29.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc4_29.2 [concrete = constants.%facet_type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_19.2: @Same.%pack_type.loc4_19 (%pack_type.dee276.1) = symbolic_binding T, 1 [symbolic = %T.loc4_19.1 (constants.%T.49b384.1)]
// CHECK:STDOUT:     %a.param: @Same.%tuple.type.loc4_56.2 (%tuple.type.e97d0c.1) = value_param call_param0
// CHECK:STDOUT:     %.loc4_56.1: type = splice_block %.loc4_56.3 [symbolic = %tuple.type.loc4_56.2 (constants.%tuple.type.e97d0c.1)] {
// CHECK:STDOUT:       %.loc4_56.2: @Same.%tuple.type.loc4_56.1 (%tuple.type.7dbd9d.1) = tuple_literal (constants.%T.49b384.1) [symbolic = %tuple (constants.%tuple.8465a0.1)]
// CHECK:STDOUT:       %.loc4_56.3: type = converted %.loc4_56.2, constants.%tuple.type.e97d0c.1 [symbolic = %tuple.type.loc4_56.2 (constants.%tuple.type.e97d0c.1)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: @Same.%tuple.type.loc4_56.2 (%tuple.type.e97d0c.1) = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: @Same.%tuple.type.loc4_56.2 (%tuple.type.e97d0c.1) = value_param call_param1
// CHECK:STDOUT:     %.loc4_73.1: type = splice_block %.loc4_73.3 [symbolic = %tuple.type.loc4_56.2 (constants.%tuple.type.e97d0c.1)] {
// CHECK:STDOUT:       %.loc4_73.2: @Same.%tuple.type.loc4_56.1 (%tuple.type.7dbd9d.1) = tuple_literal (constants.%T.49b384.1) [symbolic = %tuple (constants.%tuple.8465a0.1)]
// CHECK:STDOUT:       %.loc4_73.3: type = converted %.loc4_73.2, constants.%tuple.type.e97d0c.1 [symbolic = %tuple.type.loc4_56.2 (constants.%tuple.type.e97d0c.1)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: @Same.%tuple.type.loc4_56.2 (%tuple.type.e97d0c.1) = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Same(%arity.loc4_9.2: Core.IntLiteral, %T.loc4_19.2: @Same.%pack_type.loc4_19 (%pack_type.dee276.1)) {
// CHECK:STDOUT:   %arity.patt.loc4_9.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_9.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc4_9.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_9.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc4_19: type = pack_type constants.%facet_type, %arity.loc4_9.1 [symbolic = %pack_type.loc4_19 (constants.%pack_type.dee276.1)]
// CHECK:STDOUT:   %pattern_type.loc4_19: type = pattern_type %pack_type.loc4_19 [symbolic = %pattern_type.loc4_19 (constants.%pattern_type.f66aac.1)]
// CHECK:STDOUT:   %T.patt.loc4_19.2: @Same.%pattern_type.loc4_19 (%pattern_type.f66aac.1) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_19.2 (constants.%T.patt.fcff5e.1)]
// CHECK:STDOUT:   %T.loc4_19.1: @Same.%pack_type.loc4_19 (%pack_type.dee276.1) = symbolic_binding T, 1 [symbolic = %T.loc4_19.1 (constants.%T.49b384.1)]
// CHECK:STDOUT:   %.loc4_9.2: @Same.%pattern_type.loc4_19 (%pattern_type.f66aac.1) = pack_expansion_pattern %T.patt.loc4_19.2, %arity.patt.loc4_9.2 [symbolic = %.loc4_9.2 (constants.%.c7260c.1)]
// CHECK:STDOUT:   %.loc4_50.1: Core.IntLiteral = pack_index [symbolic = %.loc4_50.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc4_50.2: %facet_type = pack_element %T.loc4_19.1, %.loc4_50.1 [symbolic = %.loc4_50.2 (constants.%.375b6f.1)]
// CHECK:STDOUT:   %tuple.type.loc4_56.1: type = tuple_type (%pack_type.loc4_19) [symbolic = %tuple.type.loc4_56.1 (constants.%tuple.type.7dbd9d.1)]
// CHECK:STDOUT:   %tuple: @Same.%tuple.type.loc4_56.1 (%tuple.type.7dbd9d.1) = tuple_value (%T.loc4_19.1) [symbolic = %tuple (constants.%tuple.8465a0.1)]
// CHECK:STDOUT:   %pack_type.loc4_56: type = pack_type %T.loc4_19.1, %arity.loc4_9.1 [symbolic = %pack_type.loc4_56 (constants.%pack_type.8fe525.1)]
// CHECK:STDOUT:   %tuple.type.loc4_56.2: type = tuple_type (%pack_type.loc4_56) [symbolic = %tuple.type.loc4_56.2 (constants.%tuple.type.e97d0c.1)]
// CHECK:STDOUT:   %pattern_type.loc4_43: type = pattern_type %tuple.type.loc4_56.2 [symbolic = %pattern_type.loc4_43 (constants.%pattern_type.605822.1)]
// CHECK:STDOUT:   %a.param_patt.loc4_43.2: @Same.%pattern_type.loc4_43 (%pattern_type.605822.1) = value_param_pattern [symbolic = %a.param_patt.loc4_43.2 (constants.%a.param_patt.8cd)]
// CHECK:STDOUT:   %a.patt.loc4_43.2: @Same.%pattern_type.loc4_43 (%pattern_type.605822.1) = wrapper_binding_pattern a, %a.param_patt.loc4_43.2 [symbolic = %a.patt.loc4_43.2 (constants.%a.patt.956)]
// CHECK:STDOUT:   %b.param_patt.loc4_60.2: @Same.%pattern_type.loc4_43 (%pattern_type.605822.1) = value_param_pattern [symbolic = %b.param_patt.loc4_60.2 (constants.%b.param_patt.a3e)]
// CHECK:STDOUT:   %b.patt.loc4_60.2: @Same.%pattern_type.loc4_43 (%pattern_type.605822.1) = wrapper_binding_pattern b, %b.param_patt.loc4_60.2 [symbolic = %b.patt.loc4_60.2 (constants.%b.patt.ce0)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4: <witness> = require_complete_type %tuple.type.loc4_56.2 [symbolic = %require_complete.loc4 (constants.%require_complete.b74760.1)]
// CHECK:STDOUT:   %EqWith.type.loc6_12.2: type = facet_type <@EqWith, @EqWith(%tuple.type.loc4_56.2)> [symbolic = %EqWith.type.loc6_12.2 (constants.%EqWith.type.23f)]
// CHECK:STDOUT:   %require_complete.loc6: <witness> = require_complete_type %EqWith.type.loc6_12.2 [symbolic = %require_complete.loc6 (constants.%require_complete.576)]
// CHECK:STDOUT:   %EqWith.assoc_type: type = assoc_entity_type @EqWith, @EqWith(%tuple.type.loc4_56.2) [symbolic = %EqWith.assoc_type (constants.%EqWith.assoc_type.9a8)]
// CHECK:STDOUT:   %assoc0: @Same.%EqWith.assoc_type (%EqWith.assoc_type.9a8) = assoc_entity element0, imports.%Core.import_ref.5ba [symbolic = %assoc0 (constants.%assoc0.151)]
// CHECK:STDOUT:   %pack_type.loc6: type = pack_type constants.%Eq.type, %arity.loc4_9.1 [symbolic = %pack_type.loc6 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %.loc6_12.2: @Same.%pack_type.loc6 (%pack_type.c29) = pack_facet_value %T.loc4_19.1 [symbolic = %.loc6_12.2 (constants.%.229)]
// CHECK:STDOUT:   %.loc6_12.3: require_specific_def_type = require_specific_def @tuple.type.as.EqWith.impl(%arity.loc4_9.1, %.loc6_12.2) [symbolic = %.loc6_12.3 (constants.%.cd3)]
// CHECK:STDOUT:   %EqWith.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type.loc4_56.2, @EqWith, @EqWith(%tuple.type.loc4_56.2) [symbolic = %EqWith.lookup_impl_witness (constants.%EqWith.lookup_impl_witness.69b)]
// CHECK:STDOUT:   %EqWith.facet: @Same.%EqWith.type.loc6_12.2 (%EqWith.type.23f) = facet_value %tuple.type.loc4_56.2, (%EqWith.lookup_impl_witness) [symbolic = %EqWith.facet (constants.%EqWith.facet.419)]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%tuple.type.loc4_56.2, %EqWith.facet) [symbolic = %EqWith.WithSelf.Equal.type (constants.%EqWith.WithSelf.Equal.type.f5a)]
// CHECK:STDOUT:   %.loc6_12.4: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type, %EqWith.facet [symbolic = %.loc6_12.4 (constants.%.1b2)]
// CHECK:STDOUT:   %impl.elem0.loc6_12.2: @Same.%.loc6_12.4 (%.1b2) = impl_witness_access %EqWith.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc6_12.2 (constants.%impl.elem0.bc9)]
// CHECK:STDOUT:   %specific_impl_fn.loc6_12.2: <specific function> = specific_impl_function %impl.elem0.loc6_12.2, @EqWith.WithSelf.Equal(%tuple.type.loc4_56.2, %EqWith.facet) [symbolic = %specific_impl_fn.loc6_12.2 (constants.%specific_impl_fn.617)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%a.param: @Same.%tuple.type.loc4_56.2 (%tuple.type.e97d0c.1), %b.param: @Same.%tuple.type.loc4_56.2 (%tuple.type.e97d0c.1)) -> out %return.param: bool {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %a.ref: @Same.%tuple.type.loc4_56.2 (%tuple.type.e97d0c.1) = name_ref a, %a
// CHECK:STDOUT:     %b.ref: @Same.%tuple.type.loc4_56.2 (%tuple.type.e97d0c.1) = name_ref b, %b
// CHECK:STDOUT:     %EqWith.type.loc6_12.1: type = facet_type <@EqWith, @EqWith(constants.%tuple.type.e97d0c.1)> [symbolic = %EqWith.type.loc6_12.2 (constants.%EqWith.type.23f)]
// CHECK:STDOUT:     %.loc6_12.1: @Same.%EqWith.assoc_type (%EqWith.assoc_type.9a8) = specific_constant imports.%Core.import_ref.725, @EqWith.WithSelf(constants.%tuple.type.e97d0c.1, constants.%Self.d94) [symbolic = %assoc0 (constants.%assoc0.151)]
// CHECK:STDOUT:     %Equal.ref: @Same.%EqWith.assoc_type (%EqWith.assoc_type.9a8) = name_ref Equal, %.loc6_12.1 [symbolic = %assoc0 (constants.%assoc0.151)]
// CHECK:STDOUT:     %impl.elem0.loc6_12.1: @Same.%.loc6_12.4 (%.1b2) = impl_witness_access constants.%EqWith.lookup_impl_witness.69b, element0 [symbolic = %impl.elem0.loc6_12.2 (constants.%impl.elem0.bc9)]
// CHECK:STDOUT:     %bound_method.loc6_12.1: <bound method> = bound_method %a.ref, %impl.elem0.loc6_12.1
// CHECK:STDOUT:     %specific_impl_fn.loc6_12.1: <specific function> = specific_impl_function %impl.elem0.loc6_12.1, @EqWith.WithSelf.Equal(constants.%tuple.type.e97d0c.1, constants.%EqWith.facet.419) [symbolic = %specific_impl_fn.loc6_12.2 (constants.%specific_impl_fn.617)]
// CHECK:STDOUT:     %bound_method.loc6_12.2: <bound method> = bound_method %a.ref, %specific_impl_fn.loc6_12.1
// CHECK:STDOUT:     %EqWith.WithSelf.Equal.call: init bool = call %bound_method.loc6_12.2(%a.ref, %b.ref)
// CHECK:STDOUT:     return %EqWith.WithSelf.Equal.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Same(constants.%arity, constants.%T.49b384.1) {
// CHECK:STDOUT:   %arity.patt.loc4_9.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_9.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc4_19 => constants.%pack_type.dee276.1
// CHECK:STDOUT:   %pattern_type.loc4_19 => constants.%pattern_type.f66aac.1
// CHECK:STDOUT:   %T.patt.loc4_19.2 => constants.%T.patt.fcff5e.1
// CHECK:STDOUT:   %T.loc4_19.1 => constants.%T.49b384.1
// CHECK:STDOUT:   %.loc4_9.2 => constants.%.c7260c.1
// CHECK:STDOUT:   %.loc4_50.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_50.2 => constants.%.375b6f.1
// CHECK:STDOUT:   %tuple.type.loc4_56.1 => constants.%tuple.type.7dbd9d.1
// CHECK:STDOUT:   %tuple => constants.%tuple.8465a0.1
// CHECK:STDOUT:   %pack_type.loc4_56 => constants.%pack_type.8fe525.1
// CHECK:STDOUT:   %tuple.type.loc4_56.2 => constants.%tuple.type.e97d0c.1
// CHECK:STDOUT:   %pattern_type.loc4_43 => constants.%pattern_type.605822.1
// CHECK:STDOUT:   %a.param_patt.loc4_43.2 => constants.%a.param_patt.8cd
// CHECK:STDOUT:   %a.patt.loc4_43.2 => constants.%a.patt.956
// CHECK:STDOUT:   %b.param_patt.loc4_60.2 => constants.%b.param_patt.a3e
// CHECK:STDOUT:   %b.patt.loc4_60.2 => constants.%b.patt.ce0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Same(constants.%int_2, constants.%.406) {
// CHECK:STDOUT:   %arity.patt.loc4_9.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_9.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc4_19 => constants.%pack_type.8ea
// CHECK:STDOUT:   %pattern_type.loc4_19 => constants.%pattern_type.488
// CHECK:STDOUT:   %T.patt.loc4_19.2 => constants.%T.patt.31f
// CHECK:STDOUT:   %T.loc4_19.1 => constants.%.406
// CHECK:STDOUT:   %.loc4_9.2 => constants.%.586
// CHECK:STDOUT:   %.loc4_50.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_50.2 => constants.%.5a9
// CHECK:STDOUT:   %tuple.type.loc4_56.1 => constants.%tuple.type.24a
// CHECK:STDOUT:   %tuple => constants.%tuple.c64
// CHECK:STDOUT:   %pack_type.loc4_56 => constants.%pack_type.fd0
// CHECK:STDOUT:   %tuple.type.loc4_56.2 => constants.%tuple.type.6ed
// CHECK:STDOUT:   %pattern_type.loc4_43 => constants.%pattern_type.cae
// CHECK:STDOUT:   %a.param_patt.loc4_43.2 => constants.%a.param_patt.9a5
// CHECK:STDOUT:   %a.patt.loc4_43.2 => constants.%a.patt.c43
// CHECK:STDOUT:   %b.param_patt.loc4_60.2 => constants.%b.param_patt.9f9
// CHECK:STDOUT:   %b.patt.loc4_60.2 => constants.%b.patt.3a3
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4 => constants.%complete_type.61e
// CHECK:STDOUT:   %EqWith.type.loc6_12.2 => constants.%EqWith.type.8be
// CHECK:STDOUT:   %require_complete.loc6 => constants.%complete_type.0cd
// CHECK:STDOUT:   %EqWith.assoc_type => constants.%EqWith.assoc_type.224
// CHECK:STDOUT:   %assoc0 => constants.%assoc0.6c9
// CHECK:STDOUT:   %pack_type.loc6 => constants.%pack_type.8f6539.2
// CHECK:STDOUT:   %.loc6_12.2 => constants.%.d1e
// CHECK:STDOUT:   %.loc6_12.3 => constants.%.5f9
// CHECK:STDOUT:   %EqWith.lookup_impl_witness => constants.%EqWith.impl_witness.281
// CHECK:STDOUT:   %EqWith.facet => constants.%EqWith.facet.015
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type => constants.%EqWith.WithSelf.Equal.type.170
// CHECK:STDOUT:   %.loc6_12.4 => constants.%.ae3
// CHECK:STDOUT:   %impl.elem0.loc6_12.2 => constants.%tuple.type.as.EqWith.impl.Equal.dc7
// CHECK:STDOUT:   %specific_impl_fn.loc6_12.2 => constants.%tuple.type.as.EqWith.impl.Equal.specific_fn
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- forward_wider_facet.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.dee: type = pack_type %Copy.type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.f66: type = pattern_type %pack_type.dee [symbolic]
// CHECK:STDOUT:   %U.patt.fcf: %pattern_type.f66 = symbolic_binding_pattern U, 1 [symbolic]
// CHECK:STDOUT:   %U.49b: %pack_type.dee = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %.c7260c.1: %pattern_type.f66 = pack_expansion_pattern %U.patt.fcf, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.375b6f.1: %Copy.type = pack_element %U.49b, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.8fe525.1: type = pack_type %U.49b, %arity [symbolic]
// CHECK:STDOUT:   %TakeTuple.type: type = fn_type @TakeTuple [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %TakeTuple: %TakeTuple.type = struct_value () [concrete]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type type, %arity [symbolic]
// CHECK:STDOUT:   %TakeTypes.type: type = fn_type @TakeTypes [concrete]
// CHECK:STDOUT:   %TakeTypes: %TakeTypes.type = struct_value () [concrete]
// CHECK:STDOUT:   %TakeOne.type: type = fn_type @TakeOne [concrete]
// CHECK:STDOUT:   %TakeOne: %TakeOne.type = struct_value () [concrete]
// CHECK:STDOUT:   %as_type.bf997a.1: type = facet_access_type %.375b6f.1 [symbolic]
// CHECK:STDOUT:   %pattern_type.550da3.1: type = pattern_type %pack_type.8fe525.1 [symbolic]
// CHECK:STDOUT:   %u.param_patt.045: %pattern_type.550da3.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %u.patt.17f2e6.1: %pattern_type.550da3.1 = wrapper_binding_pattern u, %u.param_patt.045 [symbolic]
// CHECK:STDOUT:   %.a57364.1: %pattern_type.550da3.1 = pack_expansion_pattern %u.patt.17f2e6.1, invalid [symbolic]
// CHECK:STDOUT:   %u.patt.17f2e6.2: %pattern_type.550da3.1 = wrapper_binding_pattern u, %u.param_patt.045 [symbolic]
// CHECK:STDOUT:   %.a57364.2: %pattern_type.550da3.1 = pack_expansion_pattern %u.patt.17f2e6.2, invalid [symbolic]
// CHECK:STDOUT:   %TakePack.type: type = fn_type @TakePack [concrete]
// CHECK:STDOUT:   %TakePack: %TakePack.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.6607ff.1: <witness> = require_complete_type %pack_type.8fe525.1 [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %BitAndWith.generic: %BitAndWith.type.a06 = struct_value () [concrete]
// CHECK:STDOUT:   %BitAndWith.type.411: type = facet_type <@BitAndWith, @BitAndWith(type)> [concrete]
// CHECK:STDOUT:   %BitAndWith.impl_witness: <witness> = impl_witness imports.%BitAndWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %BitAndWith.facet: %BitAndWith.type.411 = facet_value type, (%BitAndWith.impl_witness) [concrete]
// CHECK:STDOUT:   %BitAndWith.WithSelf.Op.type.0cf: type = fn_type @BitAndWith.WithSelf.Op, @BitAndWith.WithSelf(type, %BitAndWith.facet) [concrete]
// CHECK:STDOUT:   %.85c: type = fn_type_with_self_type %BitAndWith.WithSelf.Op.type.0cf, %BitAndWith.facet [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.type: type = fn_type @type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op: %type.as.BitAndWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.bound: <bound method> = bound_method %Copy.type, %type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %pack_type.f50: type = pack_type %facet_type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.b23: type = pattern_type %pack_type.f50 [symbolic]
// CHECK:STDOUT:   %T.patt.0e6: %pattern_type.b23 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T.cd9: %pack_type.f50 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.dcc: %pattern_type.b23 = pack_expansion_pattern %T.patt.0e6, %arity.patt [symbolic]
// CHECK:STDOUT:   %.e27: %facet_type = pack_element %T.cd9, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.5c4: type = tuple_type (%pack_type.f50) [symbolic]
// CHECK:STDOUT:   %tuple.4b7: %tuple.type.5c4 = tuple_value (%T.cd9) [symbolic]
// CHECK:STDOUT:   %pack_type.b88: type = pack_type %T.cd9, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.a1b: type = tuple_type (%pack_type.b88) [symbolic]
// CHECK:STDOUT:   %pattern_type.877: type = pattern_type %tuple.type.a1b [symbolic]
// CHECK:STDOUT:   %t.param_patt.846: %pattern_type.877 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt.185: %pattern_type.877 = wrapper_binding_pattern t, %t.param_patt.846 [symbolic]
// CHECK:STDOUT:   %ForwardTuple.type: type = fn_type @ForwardTuple [concrete]
// CHECK:STDOUT:   %ForwardTuple: %ForwardTuple.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.91b: <witness> = require_complete_type %tuple.type.a1b [symbolic]
// CHECK:STDOUT:   %require_complete.769: <witness> = require_complete_type %pack_type.dee [symbolic]
// CHECK:STDOUT:   %as_type.e47: type = facet_access_type %.e27 [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.f06: <witness> = lookup_impl_witness %.e27, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.facet.623: %Copy.type = facet_value %as_type.e47, (%Copy.lookup_impl_witness.f06) [symbolic]
// CHECK:STDOUT:   %.573: %pack_type.dee = pack_facet_value %T.cd9 [symbolic]
// CHECK:STDOUT:   %TakeTuple.specific_fn.d54: <specific function> = specific_function %TakeTuple, @TakeTuple(%arity, %.573) [symbolic]
// CHECK:STDOUT:   %require_complete.03d: <witness> = require_complete_type %pack_type.c29 [symbolic]
// CHECK:STDOUT:   %.d6e: %pack_type.c29 = pack_facet_value %T.cd9 [symbolic]
// CHECK:STDOUT:   %TakeTypes.specific_fn.6e4: <specific function> = specific_function %TakeTypes, @TakeTypes(%arity, %.d6e) [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.7ee: <witness> = lookup_impl_witness %tuple.type.a1b, @Copy [symbolic]
// CHECK:STDOUT:   %.ef6: require_specific_def_type = require_specific_def @tuple.type.as.Copy.impl(%arity, %.573) [symbolic]
// CHECK:STDOUT:   %Copy.facet.964: %Copy.type = facet_value %tuple.type.a1b, (%Copy.lookup_impl_witness.7ee) [symbolic]
// CHECK:STDOUT:   %TakeOne.specific_fn.ec8: <specific function> = specific_function %TakeOne, @TakeOne(%Copy.facet.964) [symbolic]
// CHECK:STDOUT:   %pattern_type.6e5: type = pattern_type %pack_type.b88 [symbolic]
// CHECK:STDOUT:   %x.param_patt.841: %pattern_type.6e5 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.755: %pattern_type.6e5 = wrapper_binding_pattern x, %x.param_patt.841 [symbolic]
// CHECK:STDOUT:   %.757: %pattern_type.6e5 = pack_expansion_pattern %x.patt.755, invalid [symbolic]
// CHECK:STDOUT:   %ForwardPack.type: type = fn_type @ForwardPack [concrete]
// CHECK:STDOUT:   %ForwardPack: %ForwardPack.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.689: <witness> = require_complete_type %pack_type.b88 [symbolic]
// CHECK:STDOUT:   %u.param_patt.741: %pattern_type.6e5 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %u.patt.af6: %pattern_type.6e5 = wrapper_binding_pattern u, %u.param_patt.741 [symbolic]
// CHECK:STDOUT:   %.de9: %pattern_type.6e5 = pack_expansion_pattern %u.patt.af6, invalid [symbolic]
// CHECK:STDOUT:   %TakePack.specific_fn.58a: <specific function> = specific_function %TakePack, @TakePack(%arity, %.573) [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %As.type.116: type = generic_interface_type @As [concrete]
// CHECK:STDOUT:   %As.generic: %As.type.116 = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.6ed: type = tuple_type (%i32, bool) [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2.ecc [concrete]
// CHECK:STDOUT:   %.89b: %pack_type.8f6 = pack_value (%i32, bool) [concrete]
// CHECK:STDOUT:   %pack_type.e2e: type = pack_type %facet_type, %int_2.ecc [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc22_32.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc22_32.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc22_32.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.730: %facet_type = facet_value %i32, (%Copy.impl_witness.b51, %custom_witness.f8f19d.1) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc22_32.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc22_32.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc22_32.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.2: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.2, %Destroy.WithSelf.SubobjectDestroy.d01daf.2, %Destroy.WithSelf.SelfDestruct.db3fdb.2), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.d7b: %facet_type = facet_value bool, (%Copy.impl_witness.5e1, %custom_witness.f8f19d.2) [concrete]
// CHECK:STDOUT:   %.91e: %pack_type.e2e = pack_value (%facet_value.730, %facet_value.d7b) [concrete]
// CHECK:STDOUT:   %pattern_type.28f: type = pattern_type %pack_type.e2e [concrete]
// CHECK:STDOUT:   %T.patt.769: %pattern_type.28f = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.156: %pattern_type.28f = pack_expansion_pattern %T.patt.769, %arity.patt [symbolic]
// CHECK:STDOUT:   %.302: %facet_type = pack_element %.91e, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.56f: type = tuple_type (%facet_type, %facet_type) [concrete]
// CHECK:STDOUT:   %tuple.8a9: %tuple.type.56f = tuple_value (%facet_value.730, %facet_value.d7b) [concrete]
// CHECK:STDOUT:   %pack_type.601: type = pack_type %.91e, %int_2.ecc [concrete]
// CHECK:STDOUT:   %pattern_type.cae: type = pattern_type %tuple.type.6ed [concrete]
// CHECK:STDOUT:   %t.param_patt.cc8: %pattern_type.cae = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt.9ba: %pattern_type.cae = wrapper_binding_pattern t, %t.param_patt.cc8 [concrete]
// CHECK:STDOUT:   %as_type.d6c: type = facet_access_type %.302 [symbolic]
// CHECK:STDOUT:   %pattern_type.e75: type = pattern_type %pack_type.601 [concrete]
// CHECK:STDOUT:   %x.param_patt.8a4: %pattern_type.e75 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.bc6: %pattern_type.e75 = wrapper_binding_pattern x, %x.param_patt.8a4 [concrete]
// CHECK:STDOUT:   %.0b7: %pattern_type.e75 = pack_expansion_pattern %x.patt.bc6, invalid [concrete]
// CHECK:STDOUT:   %complete_type.61e: <witness> = complete_type_witness %tuple.type.6ed [concrete]
// CHECK:STDOUT:   %pack_type.8ea: type = pack_type %Copy.type, %int_2.ecc [concrete]
// CHECK:STDOUT:   %complete_type.08d: <witness> = complete_type_witness %pack_type.8ea [concrete]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.f12: <witness> = lookup_impl_witness %.302, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.facet.104: %Copy.type = facet_value %as_type.d6c, (%Copy.lookup_impl_witness.f12) [symbolic]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.facet.7af: %Copy.type = facet_value bool, (%Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %.a46: %pack_type.8ea = pack_value (%Copy.facet.1e1, %Copy.facet.7af) [concrete]
// CHECK:STDOUT:   %pattern_type.488: type = pattern_type %pack_type.8ea [concrete]
// CHECK:STDOUT:   %U.patt.31f: %pattern_type.488 = symbolic_binding_pattern U, 1 [symbolic]
// CHECK:STDOUT:   %.586726.1: %pattern_type.488 = pack_expansion_pattern %U.patt.31f, %arity.patt [symbolic]
// CHECK:STDOUT:   %.c2c: %Copy.type = pack_element %.a46, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.52b: type = pack_type %.a46, %int_2.ecc [concrete]
// CHECK:STDOUT:   %TakeTuple.specific_fn.224: <specific function> = specific_function %TakeTuple, @TakeTuple(%int_2.ecc, %.a46) [concrete]
// CHECK:STDOUT:   %complete_type.907: <witness> = complete_type_witness %pack_type.8f6 [concrete]
// CHECK:STDOUT:   %TakeTypes.specific_fn.873: <specific function> = specific_function %TakeTypes, @TakeTypes(%int_2.ecc, %.89b) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.278: <witness> = impl_witness imports.%Copy.impl_witness_table.3fa, @tuple.type.as.Copy.impl(%int_2.ecc, %.a46) [concrete]
// CHECK:STDOUT:   %.67f: require_specific_def_type = require_specific_def @tuple.type.as.Copy.impl(%int_2.ecc, %.a46) [concrete]
// CHECK:STDOUT:   %Copy.facet.77e: %Copy.type = facet_value %tuple.type.6ed, (%Copy.impl_witness.278) [concrete]
// CHECK:STDOUT:   %TakeOne.specific_fn.da3: <specific function> = specific_function %TakeOne, @TakeOne(%Copy.facet.77e) [concrete]
// CHECK:STDOUT:   %complete_type.375: <witness> = complete_type_witness %pack_type.601 [concrete]
// CHECK:STDOUT:   %as_type.ba9: type = facet_access_type %.c2c [symbolic]
// CHECK:STDOUT:   %pattern_type.756: type = pattern_type %pack_type.52b [concrete]
// CHECK:STDOUT:   %u.param_patt.40d: %pattern_type.756 = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt.4ce: %pattern_type.756 = wrapper_binding_pattern u, %u.param_patt.40d [concrete]
// CHECK:STDOUT:   %.cc4: %pattern_type.756 = pack_expansion_pattern %u.patt.4ce, invalid [concrete]
// CHECK:STDOUT:   %TakePack.specific_fn.e0e: <specific function> = specific_function %TakePack, @TakePack(%int_2.ecc, %.a46) [concrete]
// CHECK:STDOUT:   %complete_type.a69: <witness> = complete_type_witness %pack_type.52b [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .As = %Core.As
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.0ae = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.3fa = impl_witness_table (%Core.import_ref.0ae), @tuple.type.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.As: %As.type.116 = import_ref Core//prelude/operators/as, As, loaded [concrete = constants.%As.generic]
// CHECK:STDOUT:   %Core.import_ref.bd66 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd66), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.bbf = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.bbf), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %TakePack.decl: %TakePack.type = fn_decl @TakePack [concrete = constants.%TakePack] {
// CHECK:STDOUT:     %arity.patt.loc8_13.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc8_13.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %U.patt.loc8_23.1: @TakePack.%pattern_type.loc8_23 (%pattern_type.f66) = symbolic_binding_pattern U, 1 [symbolic = %U.patt.loc8_23.2 (constants.%U.patt.fcf)]
// CHECK:STDOUT:     %.loc8_13.1: @TakePack.%pattern_type.loc8_23 (%pattern_type.f66) = pack_expansion_pattern %U.patt.loc8_23.1, %arity.patt.loc8_13.1 [symbolic = %.loc8_13.2 (constants.%.c7260c.1)]
// CHECK:STDOUT:     %u.param_patt.loc8_53.1: @TakePack.%pattern_type.loc8_53 (%pattern_type.550da3.1) = value_param_pattern [symbolic = %u.param_patt.loc8_53.2 (constants.%u.param_patt.045)]
// CHECK:STDOUT:     %u.patt.loc8_53.1: @TakePack.%pattern_type.loc8_53 (%pattern_type.550da3.1) = wrapper_binding_pattern u, %u.param_patt.loc8_53.1 [symbolic = %u.patt.loc8_53.2 (constants.%u.patt.17f2e6.1)]
// CHECK:STDOUT:     %.loc8_36.1: @TakePack.%pattern_type.loc8_53 (%pattern_type.550da3.1) = pack_expansion_pattern %u.patt.loc8_53.1, invalid [symbolic = %.loc8_36.2 (constants.%.a57364.1)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc8_13.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc8_13.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc8_29: type = splice_block %Copy.ref [concrete = constants.%Copy.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %U.loc8_23.2: @TakePack.%pack_type.loc8_23 (%pack_type.dee) = symbolic_binding U, 1 [symbolic = %U.loc8_23.1 (constants.%U.49b)]
// CHECK:STDOUT:     %u.param: @TakePack.%pack_type.loc8_53 (%pack_type.8fe525.1) = value_param call_param0
// CHECK:STDOUT:     %.loc8_55.3: type = splice_block %.loc8_55.6 [symbolic = %as_type.loc8_55.1 (constants.%as_type.bf997a.1)] {
// CHECK:STDOUT:       %U.ref: @TakePack.%pack_type.loc8_23 (%pack_type.dee) = name_ref U, %U.loc8_23.2 [symbolic = %U.loc8_23.1 (constants.%U.49b)]
// CHECK:STDOUT:       %.loc8_55.4: Core.IntLiteral = pack_index [symbolic = %.loc8_55.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc8_55.5: %Copy.type = pack_element %U.ref, %.loc8_55.4 [symbolic = %.loc8_55.2 (constants.%.375b6f.1)]
// CHECK:STDOUT:       %as_type.loc8_55.2: type = facet_access_type %.loc8_55.5 [symbolic = %as_type.loc8_55.1 (constants.%as_type.bf997a.1)]
// CHECK:STDOUT:       %.loc8_55.6: type = converted %.loc8_55.5, %as_type.loc8_55.2 [symbolic = %as_type.loc8_55.1 (constants.%as_type.bf997a.1)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %u: @TakePack.%pack_type.loc8_53 (%pack_type.8fe525.1) = wrapper_binding u, %u.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %ForwardTuple.decl: %ForwardTuple.type = fn_decl @ForwardTuple [concrete = constants.%ForwardTuple] {
// CHECK:STDOUT:     %arity.patt.loc10_17.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_17.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc10_27.1: @ForwardTuple.%pattern_type.loc10_27 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc10_27.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:     %.loc10_17.1: @ForwardTuple.%pattern_type.loc10_27 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc10_27.1, %arity.patt.loc10_17.1 [symbolic = %.loc10_17.2 (constants.%.dcc)]
// CHECK:STDOUT:     %t.param_patt.loc10_56.1: @ForwardTuple.%pattern_type.loc10_56 (%pattern_type.877) = value_param_pattern [symbolic = %t.param_patt.loc10_56.2 (constants.%t.param_patt.846)]
// CHECK:STDOUT:     %t.patt.loc10_56.1: @ForwardTuple.%pattern_type.loc10_56 (%pattern_type.877) = wrapper_binding_pattern t, %t.param_patt.loc10_56.1 [symbolic = %t.patt.loc10_56.2 (constants.%t.patt.185)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc10_17.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_17.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc10_39.1: type = splice_block %.loc10_39.3 [concrete = constants.%facet_type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc10_29: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc10_41: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method: <bound method> = bound_method %Copy.ref, %impl.elem1 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc10_39.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc10_39.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc10_39.2 [concrete = constants.%facet_type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_27.2: @ForwardTuple.%pack_type.loc10_27 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc10_27.1 (constants.%T.cd9)]
// CHECK:STDOUT:     %t.param: @ForwardTuple.%tuple.type.loc10_69.2 (%tuple.type.a1b) = value_param call_param0
// CHECK:STDOUT:     %.loc10_69.1: type = splice_block %.loc10_69.3 [symbolic = %tuple.type.loc10_69.2 (constants.%tuple.type.a1b)] {
// CHECK:STDOUT:       %.loc10_69.2: @ForwardTuple.%tuple.type.loc10_69.1 (%tuple.type.5c4) = tuple_literal (constants.%T.cd9) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:       %.loc10_69.3: type = converted %.loc10_69.2, constants.%tuple.type.a1b [symbolic = %tuple.type.loc10_69.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: @ForwardTuple.%tuple.type.loc10_69.2 (%tuple.type.a1b) = wrapper_binding t, %t.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %ForwardPack.decl: %ForwardPack.type = fn_decl @ForwardPack [concrete = constants.%ForwardPack] {
// CHECK:STDOUT:     %arity.patt.loc16_16.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc16_16.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc16_26.1: @ForwardPack.%pattern_type.loc16_26 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc16_26.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:     %.loc16_16.1: @ForwardPack.%pattern_type.loc16_26 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc16_26.1, %arity.patt.loc16_16.1 [symbolic = %.loc16_16.2 (constants.%.dcc)]
// CHECK:STDOUT:     %x.param_patt.loc16_64.1: @ForwardPack.%pattern_type.loc16_64 (%pattern_type.6e5) = value_param_pattern [symbolic = %x.param_patt.loc16_64.2 (constants.%x.param_patt.841)]
// CHECK:STDOUT:     %x.patt.loc16_64.1: @ForwardPack.%pattern_type.loc16_64 (%pattern_type.6e5) = wrapper_binding_pattern x, %x.param_patt.loc16_64.1 [symbolic = %x.patt.loc16_64.2 (constants.%x.patt.755)]
// CHECK:STDOUT:     %.loc16_54.1: @ForwardPack.%pattern_type.loc16_64 (%pattern_type.6e5) = pack_expansion_pattern %x.patt.loc16_64.1, invalid [symbolic = %.loc16_54.2 (constants.%.757)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc16_16.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc16_16.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc16_38.1: type = splice_block %.loc16_38.3 [concrete = constants.%facet_type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc16_28: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc16_40: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method: <bound method> = bound_method %Copy.ref, %impl.elem1 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc16_38.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc16_38.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc16_38.2 [concrete = constants.%facet_type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc16_26.2: @ForwardPack.%pack_type.loc16_26 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc16_26.1 (constants.%T.cd9)]
// CHECK:STDOUT:     %x.param: @ForwardPack.%pack_type.loc16_64 (%pack_type.b88) = value_param call_param0
// CHECK:STDOUT:     %.loc16_66.3: type = splice_block %.loc16_66.6 [symbolic = %as_type.loc16_66.1 (constants.%as_type.e47)] {
// CHECK:STDOUT:       %T.ref: @ForwardPack.%pack_type.loc16_26 (%pack_type.f50) = name_ref T, %T.loc16_26.2 [symbolic = %T.loc16_26.1 (constants.%T.cd9)]
// CHECK:STDOUT:       %.loc16_66.4: Core.IntLiteral = pack_index [symbolic = %.loc16_66.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc16_66.5: %facet_type = pack_element %T.ref, %.loc16_66.4 [symbolic = %.loc16_66.2 (constants.%.e27)]
// CHECK:STDOUT:       %as_type.loc16_66.2: type = facet_access_type %.loc16_66.5 [symbolic = %as_type.loc16_66.1 (constants.%as_type.e47)]
// CHECK:STDOUT:       %.loc16_66.6: type = converted %.loc16_66.5, %as_type.loc16_66.2 [symbolic = %as_type.loc16_66.1 (constants.%as_type.e47)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @ForwardPack.%pack_type.loc16_64 (%pack_type.b88) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @TakePack(%arity.loc8_13.2: Core.IntLiteral, %U.loc8_23.2: @TakePack.%pack_type.loc8_23 (%pack_type.dee)) {
// CHECK:STDOUT:   %arity.patt.loc8_13.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc8_13.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc8_13.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc8_13.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc8_23: type = pack_type constants.%Copy.type, %arity.loc8_13.1 [symbolic = %pack_type.loc8_23 (constants.%pack_type.dee)]
// CHECK:STDOUT:   %pattern_type.loc8_23: type = pattern_type %pack_type.loc8_23 [symbolic = %pattern_type.loc8_23 (constants.%pattern_type.f66)]
// CHECK:STDOUT:   %U.patt.loc8_23.2: @TakePack.%pattern_type.loc8_23 (%pattern_type.f66) = symbolic_binding_pattern U, 1 [symbolic = %U.patt.loc8_23.2 (constants.%U.patt.fcf)]
// CHECK:STDOUT:   %U.loc8_23.1: @TakePack.%pack_type.loc8_23 (%pack_type.dee) = symbolic_binding U, 1 [symbolic = %U.loc8_23.1 (constants.%U.49b)]
// CHECK:STDOUT:   %.loc8_13.2: @TakePack.%pattern_type.loc8_23 (%pattern_type.f66) = pack_expansion_pattern %U.patt.loc8_23.2, %arity.patt.loc8_13.2 [symbolic = %.loc8_13.2 (constants.%.c7260c.1)]
// CHECK:STDOUT:   %.loc8_55.1: Core.IntLiteral = pack_index [symbolic = %.loc8_55.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc8_55.2: %Copy.type = pack_element %U.loc8_23.1, %.loc8_55.1 [symbolic = %.loc8_55.2 (constants.%.375b6f.1)]
// CHECK:STDOUT:   %as_type.loc8_55.1: type = facet_access_type %.loc8_55.2 [symbolic = %as_type.loc8_55.1 (constants.%as_type.bf997a.1)]
// CHECK:STDOUT:   %pack_type.loc8_53: type = pack_type %U.loc8_23.1, %arity.loc8_13.1 [symbolic = %pack_type.loc8_53 (constants.%pack_type.8fe525.1)]
// CHECK:STDOUT:   %pattern_type.loc8_53: type = pattern_type %pack_type.loc8_53 [symbolic = %pattern_type.loc8_53 (constants.%pattern_type.550da3.1)]
// CHECK:STDOUT:   %u.param_patt.loc8_53.2: @TakePack.%pattern_type.loc8_53 (%pattern_type.550da3.1) = value_param_pattern [symbolic = %u.param_patt.loc8_53.2 (constants.%u.param_patt.045)]
// CHECK:STDOUT:   %u.patt.loc8_53.2: @TakePack.%pattern_type.loc8_53 (%pattern_type.550da3.1) = wrapper_binding_pattern u, %u.param_patt.loc8_53.2 [symbolic = %u.patt.loc8_53.2 (constants.%u.patt.17f2e6.1)]
// CHECK:STDOUT:   %.loc8_36.2: @TakePack.%pattern_type.loc8_53 (%pattern_type.550da3.1) = pack_expansion_pattern %u.patt.loc8_53.2, invalid [symbolic = %.loc8_36.2 (constants.%.a57364.1)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type.loc8_53 [symbolic = %require_complete (constants.%require_complete.6607ff.1)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%u.param: @TakePack.%pack_type.loc8_53 (%pack_type.8fe525.1)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ForwardTuple(%arity.loc10_17.2: Core.IntLiteral, %T.loc10_27.2: @ForwardTuple.%pack_type.loc10_27 (%pack_type.f50)) {
// CHECK:STDOUT:   %arity.patt.loc10_17.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_17.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc10_17.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_17.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc10_27: type = pack_type constants.%facet_type, %arity.loc10_17.1 [symbolic = %pack_type.loc10_27 (constants.%pack_type.f50)]
// CHECK:STDOUT:   %pattern_type.loc10_27: type = pattern_type %pack_type.loc10_27 [symbolic = %pattern_type.loc10_27 (constants.%pattern_type.b23)]
// CHECK:STDOUT:   %T.patt.loc10_27.2: @ForwardTuple.%pattern_type.loc10_27 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc10_27.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:   %T.loc10_27.1: @ForwardTuple.%pack_type.loc10_27 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc10_27.1 (constants.%T.cd9)]
// CHECK:STDOUT:   %.loc10_17.2: @ForwardTuple.%pattern_type.loc10_27 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc10_27.2, %arity.patt.loc10_17.2 [symbolic = %.loc10_17.2 (constants.%.dcc)]
// CHECK:STDOUT:   %.loc10_63.1: Core.IntLiteral = pack_index [symbolic = %.loc10_63.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc10_63.2: %facet_type = pack_element %T.loc10_27.1, %.loc10_63.1 [symbolic = %.loc10_63.2 (constants.%.e27)]
// CHECK:STDOUT:   %tuple.type.loc10_69.1: type = tuple_type (%pack_type.loc10_27) [symbolic = %tuple.type.loc10_69.1 (constants.%tuple.type.5c4)]
// CHECK:STDOUT:   %tuple: @ForwardTuple.%tuple.type.loc10_69.1 (%tuple.type.5c4) = tuple_value (%T.loc10_27.1) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:   %pack_type.loc10_69: type = pack_type %T.loc10_27.1, %arity.loc10_17.1 [symbolic = %pack_type.loc10_69 (constants.%pack_type.b88)]
// CHECK:STDOUT:   %tuple.type.loc10_69.2: type = tuple_type (%pack_type.loc10_69) [symbolic = %tuple.type.loc10_69.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:   %pattern_type.loc10_56: type = pattern_type %tuple.type.loc10_69.2 [symbolic = %pattern_type.loc10_56 (constants.%pattern_type.877)]
// CHECK:STDOUT:   %t.param_patt.loc10_56.2: @ForwardTuple.%pattern_type.loc10_56 (%pattern_type.877) = value_param_pattern [symbolic = %t.param_patt.loc10_56.2 (constants.%t.param_patt.846)]
// CHECK:STDOUT:   %t.patt.loc10_56.2: @ForwardTuple.%pattern_type.loc10_56 (%pattern_type.877) = wrapper_binding_pattern t, %t.param_patt.loc10_56.2 [symbolic = %t.patt.loc10_56.2 (constants.%t.patt.185)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %tuple.type.loc10_69.2 [symbolic = %require_complete.loc10 (constants.%require_complete.91b)]
// CHECK:STDOUT:   %pack_type.loc11: type = pack_type constants.%Copy.type, %arity.loc10_17.1 [symbolic = %pack_type.loc11 (constants.%pack_type.dee)]
// CHECK:STDOUT:   %require_complete.loc11: <witness> = require_complete_type %pack_type.loc11 [symbolic = %require_complete.loc11 (constants.%require_complete.769)]
// CHECK:STDOUT:   %as_type: type = facet_access_type %.loc10_63.2 [symbolic = %as_type (constants.%as_type.e47)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.loc11: <witness> = lookup_impl_witness %.loc10_63.2, @Copy [symbolic = %Copy.lookup_impl_witness.loc11 (constants.%Copy.lookup_impl_witness.f06)]
// CHECK:STDOUT:   %Copy.facet.loc11: %Copy.type = facet_value %as_type, (%Copy.lookup_impl_witness.loc11) [symbolic = %Copy.facet.loc11 (constants.%Copy.facet.623)]
// CHECK:STDOUT:   %.loc11_14.3: @ForwardTuple.%pack_type.loc11 (%pack_type.dee) = pack_facet_value %T.loc10_27.1 [symbolic = %.loc11_14.3 (constants.%.573)]
// CHECK:STDOUT:   %TakeTuple.specific_fn.loc11_3.2: <specific function> = specific_function constants.%TakeTuple, @TakeTuple(%arity.loc10_17.1, %.loc11_14.3) [symbolic = %TakeTuple.specific_fn.loc11_3.2 (constants.%TakeTuple.specific_fn.d54)]
// CHECK:STDOUT:   %pack_type.loc12: type = pack_type type, %arity.loc10_17.1 [symbolic = %pack_type.loc12 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %require_complete.loc12: <witness> = require_complete_type %pack_type.loc12 [symbolic = %require_complete.loc12 (constants.%require_complete.03d)]
// CHECK:STDOUT:   %.loc12_14.3: @ForwardTuple.%pack_type.loc12 (%pack_type.c29) = pack_facet_value %T.loc10_27.1 [symbolic = %.loc12_14.3 (constants.%.d6e)]
// CHECK:STDOUT:   %TakeTypes.specific_fn.loc12_3.2: <specific function> = specific_function constants.%TakeTypes, @TakeTypes(%arity.loc10_17.1, %.loc12_14.3) [symbolic = %TakeTypes.specific_fn.loc12_3.2 (constants.%TakeTypes.specific_fn.6e4)]
// CHECK:STDOUT:   %.loc13_12.3: require_specific_def_type = require_specific_def @tuple.type.as.Copy.impl(%arity.loc10_17.1, %.loc11_14.3) [symbolic = %.loc13_12.3 (constants.%.ef6)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.loc13: <witness> = lookup_impl_witness %tuple.type.loc10_69.2, @Copy [symbolic = %Copy.lookup_impl_witness.loc13 (constants.%Copy.lookup_impl_witness.7ee)]
// CHECK:STDOUT:   %Copy.facet.loc13_12.3: %Copy.type = facet_value %tuple.type.loc10_69.2, (%Copy.lookup_impl_witness.loc13) [symbolic = %Copy.facet.loc13_12.3 (constants.%Copy.facet.964)]
// CHECK:STDOUT:   %TakeOne.specific_fn.loc13_3.2: <specific function> = specific_function constants.%TakeOne, @TakeOne(%Copy.facet.loc13_12.3) [symbolic = %TakeOne.specific_fn.loc13_3.2 (constants.%TakeOne.specific_fn.ec8)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @ForwardTuple.%tuple.type.loc10_69.2 (%tuple.type.a1b)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %TakeTuple.ref: %TakeTuple.type = name_ref TakeTuple, file.%TakeTuple.decl [concrete = constants.%TakeTuple]
// CHECK:STDOUT:     %t.ref.loc11: @ForwardTuple.%tuple.type.loc10_69.2 (%tuple.type.a1b) = name_ref t, %t
// CHECK:STDOUT:     %.loc11_14.1: @ForwardTuple.%pack_type.loc11 (%pack_type.dee) = pack_facet_value constants.%T.cd9 [symbolic = %.loc11_14.3 (constants.%.573)]
// CHECK:STDOUT:     %.loc11_14.2: @ForwardTuple.%pack_type.loc11 (%pack_type.dee) = converted constants.%T.cd9, %.loc11_14.1 [symbolic = %.loc11_14.3 (constants.%.573)]
// CHECK:STDOUT:     %TakeTuple.specific_fn.loc11_3.1: <specific function> = specific_function %TakeTuple.ref, @TakeTuple(constants.%arity, constants.%.573) [symbolic = %TakeTuple.specific_fn.loc11_3.2 (constants.%TakeTuple.specific_fn.d54)]
// CHECK:STDOUT:     %TakeTuple.call: init %empty_tuple.type = call %TakeTuple.specific_fn.loc11_3.1(%t.ref.loc11)
// CHECK:STDOUT:     %TakeTypes.ref: %TakeTypes.type = name_ref TakeTypes, file.%TakeTypes.decl [concrete = constants.%TakeTypes]
// CHECK:STDOUT:     %t.ref.loc12: @ForwardTuple.%tuple.type.loc10_69.2 (%tuple.type.a1b) = name_ref t, %t
// CHECK:STDOUT:     %.loc12_14.1: @ForwardTuple.%pack_type.loc12 (%pack_type.c29) = pack_facet_value constants.%T.cd9 [symbolic = %.loc12_14.3 (constants.%.d6e)]
// CHECK:STDOUT:     %.loc12_14.2: @ForwardTuple.%pack_type.loc12 (%pack_type.c29) = converted constants.%T.cd9, %.loc12_14.1 [symbolic = %.loc12_14.3 (constants.%.d6e)]
// CHECK:STDOUT:     %TakeTypes.specific_fn.loc12_3.1: <specific function> = specific_function %TakeTypes.ref, @TakeTypes(constants.%arity, constants.%.d6e) [symbolic = %TakeTypes.specific_fn.loc12_3.2 (constants.%TakeTypes.specific_fn.6e4)]
// CHECK:STDOUT:     %TakeTypes.call: init %empty_tuple.type = call %TakeTypes.specific_fn.loc12_3.1(%t.ref.loc12)
// CHECK:STDOUT:     %TakeOne.ref: %TakeOne.type = name_ref TakeOne, file.%TakeOne.decl [concrete = constants.%TakeOne]
// CHECK:STDOUT:     %t.ref.loc13: @ForwardTuple.%tuple.type.loc10_69.2 (%tuple.type.a1b) = name_ref t, %t
// CHECK:STDOUT:     %Copy.facet.loc13_12.1: %Copy.type = facet_value constants.%tuple.type.a1b, (constants.%Copy.lookup_impl_witness.7ee) [symbolic = %Copy.facet.loc13_12.3 (constants.%Copy.facet.964)]
// CHECK:STDOUT:     %.loc13_12.1: %Copy.type = converted constants.%tuple.type.a1b, %Copy.facet.loc13_12.1 [symbolic = %Copy.facet.loc13_12.3 (constants.%Copy.facet.964)]
// CHECK:STDOUT:     %Copy.facet.loc13_12.2: %Copy.type = facet_value constants.%tuple.type.a1b, (constants.%Copy.lookup_impl_witness.7ee) [symbolic = %Copy.facet.loc13_12.3 (constants.%Copy.facet.964)]
// CHECK:STDOUT:     %.loc13_12.2: %Copy.type = converted constants.%tuple.type.a1b, %Copy.facet.loc13_12.2 [symbolic = %Copy.facet.loc13_12.3 (constants.%Copy.facet.964)]
// CHECK:STDOUT:     %TakeOne.specific_fn.loc13_3.1: <specific function> = specific_function %TakeOne.ref, @TakeOne(constants.%Copy.facet.964) [symbolic = %TakeOne.specific_fn.loc13_3.2 (constants.%TakeOne.specific_fn.ec8)]
// CHECK:STDOUT:     %TakeOne.call: init %empty_tuple.type = call %TakeOne.specific_fn.loc13_3.1(%t.ref.loc13)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ForwardPack(%arity.loc16_16.2: Core.IntLiteral, %T.loc16_26.2: @ForwardPack.%pack_type.loc16_26 (%pack_type.f50)) {
// CHECK:STDOUT:   %arity.patt.loc16_16.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc16_16.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc16_16.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc16_16.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc16_26: type = pack_type constants.%facet_type, %arity.loc16_16.1 [symbolic = %pack_type.loc16_26 (constants.%pack_type.f50)]
// CHECK:STDOUT:   %pattern_type.loc16_26: type = pattern_type %pack_type.loc16_26 [symbolic = %pattern_type.loc16_26 (constants.%pattern_type.b23)]
// CHECK:STDOUT:   %T.patt.loc16_26.2: @ForwardPack.%pattern_type.loc16_26 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc16_26.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:   %T.loc16_26.1: @ForwardPack.%pack_type.loc16_26 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc16_26.1 (constants.%T.cd9)]
// CHECK:STDOUT:   %.loc16_16.2: @ForwardPack.%pattern_type.loc16_26 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc16_26.2, %arity.patt.loc16_16.2 [symbolic = %.loc16_16.2 (constants.%.dcc)]
// CHECK:STDOUT:   %.loc16_66.1: Core.IntLiteral = pack_index [symbolic = %.loc16_66.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc16_66.2: %facet_type = pack_element %T.loc16_26.1, %.loc16_66.1 [symbolic = %.loc16_66.2 (constants.%.e27)]
// CHECK:STDOUT:   %as_type.loc16_66.1: type = facet_access_type %.loc16_66.2 [symbolic = %as_type.loc16_66.1 (constants.%as_type.e47)]
// CHECK:STDOUT:   %pack_type.loc16_64: type = pack_type %T.loc16_26.1, %arity.loc16_16.1 [symbolic = %pack_type.loc16_64 (constants.%pack_type.b88)]
// CHECK:STDOUT:   %pattern_type.loc16_64: type = pattern_type %pack_type.loc16_64 [symbolic = %pattern_type.loc16_64 (constants.%pattern_type.6e5)]
// CHECK:STDOUT:   %x.param_patt.loc16_64.2: @ForwardPack.%pattern_type.loc16_64 (%pattern_type.6e5) = value_param_pattern [symbolic = %x.param_patt.loc16_64.2 (constants.%x.param_patt.841)]
// CHECK:STDOUT:   %x.patt.loc16_64.2: @ForwardPack.%pattern_type.loc16_64 (%pattern_type.6e5) = wrapper_binding_pattern x, %x.param_patt.loc16_64.2 [symbolic = %x.patt.loc16_64.2 (constants.%x.patt.755)]
// CHECK:STDOUT:   %.loc16_54.2: @ForwardPack.%pattern_type.loc16_64 (%pattern_type.6e5) = pack_expansion_pattern %x.patt.loc16_64.2, invalid [symbolic = %.loc16_54.2 (constants.%.757)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc16: <witness> = require_complete_type %pack_type.loc16_64 [symbolic = %require_complete.loc16 (constants.%require_complete.689)]
// CHECK:STDOUT:   %pack_type.loc17: type = pack_type constants.%Copy.type, %arity.loc16_16.1 [symbolic = %pack_type.loc17 (constants.%pack_type.dee)]
// CHECK:STDOUT:   %require_complete.loc17: <witness> = require_complete_type %pack_type.loc17 [symbolic = %require_complete.loc17 (constants.%require_complete.769)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %.loc16_66.2, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.f06)]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %as_type.loc16_66.1, (%Copy.lookup_impl_witness) [symbolic = %Copy.facet (constants.%Copy.facet.623)]
// CHECK:STDOUT:   %.loc17_22.3: @ForwardPack.%pack_type.loc17 (%pack_type.dee) = pack_facet_value %T.loc16_26.1 [symbolic = %.loc17_22.3 (constants.%.573)]
// CHECK:STDOUT:   %TakePack.specific_fn.loc17_3.2: <specific function> = specific_function constants.%TakePack, @TakePack(%arity.loc16_16.1, %.loc17_22.3) [symbolic = %TakePack.specific_fn.loc17_3.2 (constants.%TakePack.specific_fn.58a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @ForwardPack.%pack_type.loc16_64 (%pack_type.b88)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %TakePack.ref: %TakePack.type = name_ref TakePack, file.%TakePack.decl [concrete = constants.%TakePack]
// CHECK:STDOUT:     %.loc17_12: @ForwardPack.%pack_type.loc16_64 (%pack_type.b88) = pack_expansion_expr %.loc17_16.5 {
// CHECK:STDOUT:       %x.ref: @ForwardPack.%pack_type.loc16_64 (%pack_type.b88) = name_ref x, %x
// CHECK:STDOUT:       %.loc17_16.1: Core.IntLiteral = pack_index [symbolic = %.loc16_66.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc17_16.2: Core.IntLiteral = pack_index [symbolic = %.loc16_66.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc17_16.3: %facet_type = pack_element constants.%T.cd9, %.loc17_16.2 [symbolic = %.loc16_66.2 (constants.%.e27)]
// CHECK:STDOUT:       %as_type.loc17: type = facet_access_type %.loc17_16.3 [symbolic = %as_type.loc16_66.1 (constants.%as_type.e47)]
// CHECK:STDOUT:       %.loc17_16.4: type = converted %.loc17_16.3, %as_type.loc17 [symbolic = %as_type.loc16_66.1 (constants.%as_type.e47)]
// CHECK:STDOUT:       %.loc17_16.5: @ForwardPack.%as_type.loc16_66.1 (%as_type.e47) = pack_element %x.ref, %.loc17_16.1
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc17_22.1: @ForwardPack.%pack_type.loc17 (%pack_type.dee) = pack_facet_value constants.%T.cd9 [symbolic = %.loc17_22.3 (constants.%.573)]
// CHECK:STDOUT:     %.loc17_22.2: @ForwardPack.%pack_type.loc17 (%pack_type.dee) = converted constants.%T.cd9, %.loc17_22.1 [symbolic = %.loc17_22.3 (constants.%.573)]
// CHECK:STDOUT:     %TakePack.specific_fn.loc17_3.1: <specific function> = specific_function %TakePack.ref, @TakePack(constants.%arity, constants.%.573) [symbolic = %TakePack.specific_fn.loc17_3.2 (constants.%TakePack.specific_fn.58a)]
// CHECK:STDOUT:     %TakePack.call: init %empty_tuple.type = call %TakePack.specific_fn.loc17_3.1(%.loc17_12)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @TakePack(constants.%arity, constants.%U.49b) {
// CHECK:STDOUT:   %arity.patt.loc8_13.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc8_13.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc8_23 => constants.%pack_type.dee
// CHECK:STDOUT:   %pattern_type.loc8_23 => constants.%pattern_type.f66
// CHECK:STDOUT:   %U.patt.loc8_23.2 => constants.%U.patt.fcf
// CHECK:STDOUT:   %U.loc8_23.1 => constants.%U.49b
// CHECK:STDOUT:   %.loc8_13.2 => constants.%.c7260c.1
// CHECK:STDOUT:   %.loc8_55.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc8_55.2 => constants.%.375b6f.1
// CHECK:STDOUT:   %as_type.loc8_55.1 => constants.%as_type.bf997a.1
// CHECK:STDOUT:   %pack_type.loc8_53 => constants.%pack_type.8fe525.1
// CHECK:STDOUT:   %pattern_type.loc8_53 => constants.%pattern_type.550da3.1
// CHECK:STDOUT:   %u.param_patt.loc8_53.2 => constants.%u.param_patt.045
// CHECK:STDOUT:   %u.patt.loc8_53.2 => constants.%u.patt.17f2e6.2
// CHECK:STDOUT:   %.loc8_36.2 => constants.%.a57364.2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForwardTuple(constants.%arity, constants.%T.cd9) {
// CHECK:STDOUT:   %arity.patt.loc10_17.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_17.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc10_27 => constants.%pack_type.f50
// CHECK:STDOUT:   %pattern_type.loc10_27 => constants.%pattern_type.b23
// CHECK:STDOUT:   %T.patt.loc10_27.2 => constants.%T.patt.0e6
// CHECK:STDOUT:   %T.loc10_27.1 => constants.%T.cd9
// CHECK:STDOUT:   %.loc10_17.2 => constants.%.dcc
// CHECK:STDOUT:   %.loc10_63.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc10_63.2 => constants.%.e27
// CHECK:STDOUT:   %tuple.type.loc10_69.1 => constants.%tuple.type.5c4
// CHECK:STDOUT:   %tuple => constants.%tuple.4b7
// CHECK:STDOUT:   %pack_type.loc10_69 => constants.%pack_type.b88
// CHECK:STDOUT:   %tuple.type.loc10_69.2 => constants.%tuple.type.a1b
// CHECK:STDOUT:   %pattern_type.loc10_56 => constants.%pattern_type.877
// CHECK:STDOUT:   %t.param_patt.loc10_56.2 => constants.%t.param_patt.846
// CHECK:STDOUT:   %t.patt.loc10_56.2 => constants.%t.patt.185
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForwardPack(constants.%arity, constants.%T.cd9) {
// CHECK:STDOUT:   %arity.patt.loc16_16.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc16_16.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc16_26 => constants.%pack_type.f50
// CHECK:STDOUT:   %pattern_type.loc16_26 => constants.%pattern_type.b23
// CHECK:STDOUT:   %T.patt.loc16_26.2 => constants.%T.patt.0e6
// CHECK:STDOUT:   %T.loc16_26.1 => constants.%T.cd9
// CHECK:STDOUT:   %.loc16_16.2 => constants.%.dcc
// CHECK:STDOUT:   %.loc16_66.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc16_66.2 => constants.%.e27
// CHECK:STDOUT:   %as_type.loc16_66.1 => constants.%as_type.e47
// CHECK:STDOUT:   %pack_type.loc16_64 => constants.%pack_type.b88
// CHECK:STDOUT:   %pattern_type.loc16_64 => constants.%pattern_type.6e5
// CHECK:STDOUT:   %x.param_patt.loc16_64.2 => constants.%x.param_patt.841
// CHECK:STDOUT:   %x.patt.loc16_64.2 => constants.%x.patt.755
// CHECK:STDOUT:   %.loc16_54.2 => constants.%.757
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @TakePack(constants.%arity, constants.%.573) {
// CHECK:STDOUT:   %arity.patt.loc8_13.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc8_13.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc8_23 => constants.%pack_type.dee
// CHECK:STDOUT:   %pattern_type.loc8_23 => constants.%pattern_type.f66
// CHECK:STDOUT:   %U.patt.loc8_23.2 => constants.%U.patt.fcf
// CHECK:STDOUT:   %U.loc8_23.1 => constants.%.573
// CHECK:STDOUT:   %.loc8_13.2 => constants.%.c7260c.1
// CHECK:STDOUT:   %.loc8_55.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc8_55.2 => constants.%Copy.facet.623
// CHECK:STDOUT:   %as_type.loc8_55.1 => constants.%as_type.e47
// CHECK:STDOUT:   %pack_type.loc8_53 => constants.%pack_type.b88
// CHECK:STDOUT:   %pattern_type.loc8_53 => constants.%pattern_type.6e5
// CHECK:STDOUT:   %u.param_patt.loc8_53.2 => constants.%u.param_patt.741
// CHECK:STDOUT:   %u.patt.loc8_53.2 => constants.%u.patt.af6
// CHECK:STDOUT:   %.loc8_36.2 => constants.%.de9
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%require_complete.689
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForwardTuple(constants.%int_2.ecc, constants.%.91e) {
// CHECK:STDOUT:   %arity.patt.loc10_17.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_17.1 => constants.%int_2.ecc
// CHECK:STDOUT:   %pack_type.loc10_27 => constants.%pack_type.e2e
// CHECK:STDOUT:   %pattern_type.loc10_27 => constants.%pattern_type.28f
// CHECK:STDOUT:   %T.patt.loc10_27.2 => constants.%T.patt.769
// CHECK:STDOUT:   %T.loc10_27.1 => constants.%.91e
// CHECK:STDOUT:   %.loc10_17.2 => constants.%.156
// CHECK:STDOUT:   %.loc10_63.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc10_63.2 => constants.%.302
// CHECK:STDOUT:   %tuple.type.loc10_69.1 => constants.%tuple.type.56f
// CHECK:STDOUT:   %tuple => constants.%tuple.8a9
// CHECK:STDOUT:   %pack_type.loc10_69 => constants.%pack_type.601
// CHECK:STDOUT:   %tuple.type.loc10_69.2 => constants.%tuple.type.6ed
// CHECK:STDOUT:   %pattern_type.loc10_56 => constants.%pattern_type.cae
// CHECK:STDOUT:   %t.param_patt.loc10_56.2 => constants.%t.param_patt.cc8
// CHECK:STDOUT:   %t.patt.loc10_56.2 => constants.%t.patt.9ba
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10 => constants.%complete_type.61e
// CHECK:STDOUT:   %pack_type.loc11 => constants.%pack_type.8ea
// CHECK:STDOUT:   %require_complete.loc11 => constants.%complete_type.08d
// CHECK:STDOUT:   %as_type => constants.%as_type.d6c
// CHECK:STDOUT:   %Copy.lookup_impl_witness.loc11 => constants.%Copy.lookup_impl_witness.f12
// CHECK:STDOUT:   %Copy.facet.loc11 => constants.%Copy.facet.104
// CHECK:STDOUT:   %.loc11_14.3 => constants.%.a46
// CHECK:STDOUT:   %TakeTuple.specific_fn.loc11_3.2 => constants.%TakeTuple.specific_fn.224
// CHECK:STDOUT:   %pack_type.loc12 => constants.%pack_type.8f6
// CHECK:STDOUT:   %require_complete.loc12 => constants.%complete_type.907
// CHECK:STDOUT:   %.loc12_14.3 => constants.%.89b
// CHECK:STDOUT:   %TakeTypes.specific_fn.loc12_3.2 => constants.%TakeTypes.specific_fn.873
// CHECK:STDOUT:   %.loc13_12.3 => constants.%.67f
// CHECK:STDOUT:   %Copy.lookup_impl_witness.loc13 => constants.%Copy.impl_witness.278
// CHECK:STDOUT:   %Copy.facet.loc13_12.3 => constants.%Copy.facet.77e
// CHECK:STDOUT:   %TakeOne.specific_fn.loc13_3.2 => constants.%TakeOne.specific_fn.da3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForwardPack(constants.%int_2.ecc, constants.%.91e) {
// CHECK:STDOUT:   %arity.patt.loc16_16.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc16_16.1 => constants.%int_2.ecc
// CHECK:STDOUT:   %pack_type.loc16_26 => constants.%pack_type.e2e
// CHECK:STDOUT:   %pattern_type.loc16_26 => constants.%pattern_type.28f
// CHECK:STDOUT:   %T.patt.loc16_26.2 => constants.%T.patt.769
// CHECK:STDOUT:   %T.loc16_26.1 => constants.%.91e
// CHECK:STDOUT:   %.loc16_16.2 => constants.%.156
// CHECK:STDOUT:   %.loc16_66.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc16_66.2 => constants.%.302
// CHECK:STDOUT:   %as_type.loc16_66.1 => constants.%as_type.d6c
// CHECK:STDOUT:   %pack_type.loc16_64 => constants.%pack_type.601
// CHECK:STDOUT:   %pattern_type.loc16_64 => constants.%pattern_type.e75
// CHECK:STDOUT:   %x.param_patt.loc16_64.2 => constants.%x.param_patt.8a4
// CHECK:STDOUT:   %x.patt.loc16_64.2 => constants.%x.patt.bc6
// CHECK:STDOUT:   %.loc16_54.2 => constants.%.0b7
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc16 => constants.%complete_type.375
// CHECK:STDOUT:   %pack_type.loc17 => constants.%pack_type.8ea
// CHECK:STDOUT:   %require_complete.loc17 => constants.%complete_type.08d
// CHECK:STDOUT:   %Copy.lookup_impl_witness => constants.%Copy.lookup_impl_witness.f12
// CHECK:STDOUT:   %Copy.facet => constants.%Copy.facet.104
// CHECK:STDOUT:   %.loc17_22.3 => constants.%.a46
// CHECK:STDOUT:   %TakePack.specific_fn.loc17_3.2 => constants.%TakePack.specific_fn.e0e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @TakePack(constants.%int_2.ecc, constants.%.a46) {
// CHECK:STDOUT:   %arity.patt.loc8_13.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc8_13.1 => constants.%int_2.ecc
// CHECK:STDOUT:   %pack_type.loc8_23 => constants.%pack_type.8ea
// CHECK:STDOUT:   %pattern_type.loc8_23 => constants.%pattern_type.488
// CHECK:STDOUT:   %U.patt.loc8_23.2 => constants.%U.patt.31f
// CHECK:STDOUT:   %U.loc8_23.1 => constants.%.a46
// CHECK:STDOUT:   %.loc8_13.2 => constants.%.586726.1
// CHECK:STDOUT:   %.loc8_55.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc8_55.2 => constants.%.c2c
// CHECK:STDOUT:   %as_type.loc8_55.1 => constants.%as_type.ba9
// CHECK:STDOUT:   %pack_type.loc8_53 => constants.%pack_type.52b
// CHECK:STDOUT:   %pattern_type.loc8_53 => constants.%pattern_type.756
// CHECK:STDOUT:   %u.param_patt.loc8_53.2 => constants.%u.param_patt.40d
// CHECK:STDOUT:   %u.patt.loc8_53.2 => constants.%u.patt.4ce
// CHECK:STDOUT:   %.loc8_36.2 => constants.%.cc4
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.a69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- import_forward_wider_facet.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.693: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.760: %tuple.type.693 = tuple_value (%i32, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.6ed: type = tuple_type (%i32, bool) [concrete]
// CHECK:STDOUT:   %.52d: Core.Form = init_form %tuple.type.6ed [concrete]
// CHECK:STDOUT:   %pattern_type.cae: type = pattern_type %tuple.type.6ed [concrete]
// CHECK:STDOUT:   %return.param_patt.e86: %pattern_type.cae = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.904: %pattern_type.cae = return_slot_pattern %return.param_patt.e86, %tuple.type.6ed [concrete]
// CHECK:STDOUT:   %Concrete.type: type = fn_type @Concrete [concrete]
// CHECK:STDOUT:   %Concrete: %Concrete.type = struct_value () [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48fc7.1: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %pack_type.18c88c.1: type = pack_type %facet_type.f48fc7.1, %arity [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %As.type.116: type = generic_interface_type @As [concrete]
// CHECK:STDOUT:   %As.generic: %As.type.116 = struct_value () [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.8a4 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.8a4, @Core.IntLiteral.as.As.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %tuple.078: %tuple.type.6ed = tuple_value (%int_1.0c6, %true) [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.89b: %pack_type.8f6 = pack_value (%i32, bool) [concrete]
// CHECK:STDOUT:   %pack_type.6eb: type = pack_type %facet_type.f48fc7.1, %int_2 [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc7_28.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc7_28.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc7_28.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value.178: %facet_type.f48fc7.1 = facet_value %i32, (%custom_witness.f8f19d.1, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %self.param_patt.40d: %pattern_type.831 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.560: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt.40d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc7_28.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc7_28.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc7_28.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.2: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.2, %Destroy.WithSelf.SubobjectDestroy.d01daf.2, %Destroy.WithSelf.SelfDestruct.db3fdb.2), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %facet_value.aa6: %facet_type.f48fc7.1 = facet_value bool, (%custom_witness.f8f19d.2, %Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %.38e: %pack_type.6eb = pack_value (%facet_value.178, %facet_value.aa6) [concrete]
// CHECK:STDOUT:   %F.specific_fn.7de: <specific function> = specific_function %F, @F(%int_2, %.38e) [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %BitAndWith.generic: %BitAndWith.type.a06 = struct_value () [concrete]
// CHECK:STDOUT:   %BitAndWith.type.411: type = facet_type <@BitAndWith, @BitAndWith(type)> [concrete]
// CHECK:STDOUT:   %BitAndWith.impl_witness: <witness> = impl_witness imports.%BitAndWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %BitAndWith.facet: %BitAndWith.type.411 = facet_value type, (%BitAndWith.impl_witness) [concrete]
// CHECK:STDOUT:   %BitAndWith.WithSelf.Op.type.0cf: type = fn_type @BitAndWith.WithSelf.Op, @BitAndWith.WithSelf(type, %BitAndWith.facet) [concrete]
// CHECK:STDOUT:   %.85c: type = fn_type_with_self_type %BitAndWith.WithSelf.Op.type.0cf, %BitAndWith.facet [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.type: type = fn_type @type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op: %type.as.BitAndWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.bound.e6a: <bound method> = bound_method %Copy.type, %type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %Eq.type: type = facet_type <@Eq> [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.bound.6ae: <bound method> = bound_method %facet_type.f48fc7.1, %type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %facet_type.f48fc7.2: type = facet_type <@Destroy & @Copy & @Eq> [concrete]
// CHECK:STDOUT:   %pack_type.18c88c.2: type = pack_type %facet_type.f48fc7.2, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.4fea90.2: type = pattern_type %pack_type.18c88c.2 [symbolic]
// CHECK:STDOUT:   %T.patt.dda460.2: %pattern_type.4fea90.2 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T.b9dbda.2: %pack_type.18c88c.2 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.d7b3f5.2: %pattern_type.4fea90.2 = pack_expansion_pattern %T.patt.dda460.2, %arity.patt [symbolic]
// CHECK:STDOUT:   %.2fac42.2: %facet_type.f48fc7.2 = pack_element %T.b9dbda.2, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.be394e.2: type = tuple_type (%pack_type.18c88c.2) [symbolic]
// CHECK:STDOUT:   %tuple.5b4b0d.2: %tuple.type.be394e.2 = tuple_value (%T.b9dbda.2) [symbolic]
// CHECK:STDOUT:   %pack_type.9f5019.2: type = pack_type %T.b9dbda.2, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.6277e2.2: type = tuple_type (%pack_type.9f5019.2) [symbolic]
// CHECK:STDOUT:   %pattern_type.38532c.2: type = pattern_type %tuple.type.6277e2.2 [symbolic]
// CHECK:STDOUT:   %t.param_patt.3848f4.2: %pattern_type.38532c.2 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt.f8d902.2: %pattern_type.38532c.2 = wrapper_binding_pattern t, %t.param_patt.3848f4.2 [symbolic]
// CHECK:STDOUT:   %.374b4c.2: Core.Form = init_form %tuple.type.6277e2.2 [symbolic]
// CHECK:STDOUT:   %return.param_patt.5a734b.2: %pattern_type.38532c.2 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.bce: %pattern_type.38532c.2 = return_slot_pattern %return.param_patt.5a734b.2, %tuple.type.6277e2.2 [symbolic]
// CHECK:STDOUT:   %Generic.type: type = fn_type @Generic [concrete]
// CHECK:STDOUT:   %Generic: %Generic.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.6ec572.2: <witness> = require_complete_type %tuple.type.6277e2.2 [symbolic]
// CHECK:STDOUT:   %require_complete.e52: <witness> = require_complete_type %pack_type.18c88c.1 [symbolic]
// CHECK:STDOUT:   %as_type.639ae5.2: type = facet_access_type %.2fac42.2 [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.6a8: <witness> = lookup_impl_witness %.2fac42.2, @Destroy [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.f574a8.2: <witness> = lookup_impl_witness %.2fac42.2, @Copy [symbolic]
// CHECK:STDOUT:   %facet_value.71b: %facet_type.f48fc7.1 = facet_value %as_type.639ae5.2, (%Destroy.lookup_impl_witness.6a8, %Copy.lookup_impl_witness.f574a8.2) [symbolic]
// CHECK:STDOUT:   %.ba7: %pack_type.18c88c.1 = pack_facet_value %T.b9dbda.2 [symbolic]
// CHECK:STDOUT:   %F.specific_fn.aab: <specific function> = specific_function %F, @F(%arity, %.ba7) [symbolic]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.type: type = fn_type @bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op: %bool.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.F: %F.type = import_ref Main//import_forward_wider_facet_lib, F, loaded [concrete = constants.%F]
// CHECK:STDOUT:   %Core.048aa3.1: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .As = %Core.As
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     .Eq = %Core.Eq
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.As: %As.type.116 = import_ref Core//prelude/operators/as, As, loaded [concrete = constants.%As.generic]
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl.f25 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.9c3475.1: %bool.as.Copy.impl.Op.type = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.9c3475.1), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3475.2: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3475.2), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT:   %Core.Eq: type = import_ref Core//prelude/operators/comparison, Eq, loaded [concrete = constants.%Eq.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc7_28.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc7_28.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc7_28.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc7_28.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Concrete.decl: %Concrete.type = fn_decl @Concrete [concrete = constants.%Concrete] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.cae = out_param_pattern [concrete = constants.%return.param_patt.e86]
// CHECK:STDOUT:     %return.patt: %pattern_type.cae = return_slot_pattern %return.param_patt, %.loc6_28.3 [concrete = constants.%return.patt.904]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc6: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6_24: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc6_28.2: %tuple.type.693 = tuple_literal (%i32.loc6, %.loc6_24) [concrete = constants.%tuple.760]
// CHECK:STDOUT:     %.loc6_28.3: type = converted %.loc6_28.2, constants.%tuple.type.6ed [concrete = constants.%tuple.type.6ed]
// CHECK:STDOUT:     %.loc6_28.4: Core.Form = init_form %.loc6_28.3 [concrete = constants.%.52d]
// CHECK:STDOUT:     %return.param: ref %tuple.type.6ed = out_param call_param0
// CHECK:STDOUT:     %return: ref %tuple.type.6ed = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Generic.decl: %Generic.type = fn_decl @Generic [concrete = constants.%Generic] {
// CHECK:STDOUT:     %arity.patt.loc10_12.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc10_22.1: @Generic.%pattern_type.loc10_22 (%pattern_type.4fea90.2) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc10_22.2 (constants.%T.patt.dda460.2)]
// CHECK:STDOUT:     %.loc10_12.1: @Generic.%pattern_type.loc10_22 (%pattern_type.4fea90.2) = pack_expansion_pattern %T.patt.loc10_22.1, %arity.patt.loc10_12.1 [symbolic = %.loc10_12.2 (constants.%.d7b3f5.2)]
// CHECK:STDOUT:     %t.param_patt.loc10_61.1: @Generic.%pattern_type.loc10_61 (%pattern_type.38532c.2) = value_param_pattern [symbolic = %t.param_patt.loc10_61.2 (constants.%t.param_patt.3848f4.2)]
// CHECK:STDOUT:     %t.patt.loc10_61.1: @Generic.%pattern_type.loc10_61 (%pattern_type.38532c.2) = wrapper_binding_pattern t, %t.param_patt.loc10_61.1 [symbolic = %t.patt.loc10_61.2 (constants.%t.patt.f8d902.2)]
// CHECK:STDOUT:     %return.param_patt.loc11_19.1: @Generic.%pattern_type.loc10_61 (%pattern_type.38532c.2) = out_param_pattern [symbolic = %return.param_patt.loc11_19.2 (constants.%return.param_patt.5a734b.2)]
// CHECK:STDOUT:     %return.patt.loc11_5.1: @Generic.%pattern_type.loc10_61 (%pattern_type.38532c.2) = return_slot_pattern %return.param_patt.loc11_19.1, %.loc11_19.4 [symbolic = %return.patt.loc11_5.2 (constants.%return.patt.bce)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc11_19.3: @Generic.%tuple.type.loc10_74.1 (%tuple.type.be394e.2) = tuple_literal (constants.%T.b9dbda.2) [symbolic = %tuple (constants.%tuple.5b4b0d.2)]
// CHECK:STDOUT:     %.loc11_19.4: type = converted %.loc11_19.3, constants.%tuple.type.6277e2.2 [symbolic = %tuple.type.loc10_74.2 (constants.%tuple.type.6277e2.2)]
// CHECK:STDOUT:     %.loc11_19.5: Core.Form = init_form %.loc11_19.4 [symbolic = %.loc11_19.2 (constants.%.374b4c.2)]
// CHECK:STDOUT:     %arity.loc10_12.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc10_49.1: type = splice_block %.loc10_49.3 [concrete = constants.%facet_type.f48fc7.2] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc10_24: <namespace> = name_ref Core, imports.%Core.048aa3.1 [concrete = imports.%Core.048aa3.1]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc10_36: <namespace> = name_ref Core, imports.%Core.048aa3.1 [concrete = imports.%Core.048aa3.1]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1.loc10_34: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc10_34: <bound method> = bound_method %Copy.ref, %impl.elem1.loc10_34 [concrete = constants.%type.as.BitAndWith.impl.Op.bound.e6a]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call.loc10_34: init type = call %bound_method.loc10_34(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type.f48fc7.1]
// CHECK:STDOUT:       %Core.ref.loc10_51: <namespace> = name_ref Core, imports.%Core.048aa3.1 [concrete = imports.%Core.048aa3.1]
// CHECK:STDOUT:       %Eq.ref: type = name_ref Eq, imports.%Core.Eq [concrete = constants.%Eq.type]
// CHECK:STDOUT:       %impl.elem1.loc10_49: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc10_49: <bound method> = bound_method %type.as.BitAndWith.impl.Op.call.loc10_34, %impl.elem1.loc10_49 [concrete = constants.%type.as.BitAndWith.impl.Op.bound.6ae]
// CHECK:STDOUT:       %.loc10_34.1: type = value_of_initializer %type.as.BitAndWith.impl.Op.call.loc10_34 [concrete = constants.%facet_type.f48fc7.1]
// CHECK:STDOUT:       %.loc10_34.2: type = converted %type.as.BitAndWith.impl.Op.call.loc10_34, %.loc10_34.1 [concrete = constants.%facet_type.f48fc7.1]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call.loc10_49: init type = call %bound_method.loc10_49(%.loc10_34.2, %Eq.ref) [concrete = constants.%facet_type.f48fc7.2]
// CHECK:STDOUT:       %.loc10_49.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call.loc10_49 [concrete = constants.%facet_type.f48fc7.2]
// CHECK:STDOUT:       %.loc10_49.3: type = converted %type.as.BitAndWith.impl.Op.call.loc10_49, %.loc10_49.2 [concrete = constants.%facet_type.f48fc7.2]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_22.2: @Generic.%pack_type.loc10_22 (%pack_type.18c88c.2) = symbolic_binding T, 1 [symbolic = %T.loc10_22.1 (constants.%T.b9dbda.2)]
// CHECK:STDOUT:     %t.param: @Generic.%tuple.type.loc10_74.2 (%tuple.type.6277e2.2) = value_param call_param0
// CHECK:STDOUT:     %.loc10_74.1: type = splice_block %.loc10_74.3 [symbolic = %tuple.type.loc10_74.2 (constants.%tuple.type.6277e2.2)] {
// CHECK:STDOUT:       %.loc10_74.2: @Generic.%tuple.type.loc10_74.1 (%tuple.type.be394e.2) = tuple_literal (constants.%T.b9dbda.2) [symbolic = %tuple (constants.%tuple.5b4b0d.2)]
// CHECK:STDOUT:       %.loc10_74.3: type = converted %.loc10_74.2, constants.%tuple.type.6277e2.2 [symbolic = %tuple.type.loc10_74.2 (constants.%tuple.type.6277e2.2)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: @Generic.%tuple.type.loc10_74.2 (%tuple.type.6277e2.2) = wrapper_binding t, %t.param
// CHECK:STDOUT:     %return.param: ref @Generic.%tuple.type.loc10_74.2 (%tuple.type.6277e2.2) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Generic.%tuple.type.loc10_74.2 (%tuple.type.6277e2.2) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Concrete() -> out %return.param: %tuple.type.6ed {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref: %F.type = name_ref F, imports.%Main.F [concrete = constants.%F]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %i32.loc7: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %impl.elem0: %.453 = impl_witness_access constants.%As.impl_witness.e7f, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.8a4]
// CHECK:STDOUT:   %bound_method.loc7_15.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.As.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_15.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call: init %i32 = call %bound_method.loc7_15.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc7_15.1: %i32 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc7_15.2: %i32 = converted %int_1, %.loc7_15.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc7_27.1: %tuple.type.6ed = tuple_literal (%.loc7_15.2, %true) [concrete = constants.%tuple.078]
// CHECK:STDOUT:   %int_2.loc7_28.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc7_28.1: %pack_type.8f6 = pack_value (constants.%i32, bool) [concrete = constants.%.89b]
// CHECK:STDOUT:   %int_2.loc7_28.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc7_28.2: %pack_type.8f6 = pack_value (constants.%i32, bool) [concrete = constants.%.89b]
// CHECK:STDOUT:   %facet_value.loc7_28.1: %facet_type.f48fc7.1 = facet_value constants.%i32, (constants.%custom_witness.f8f19d.1, constants.%Copy.impl_witness.b51) [concrete = constants.%facet_value.178]
// CHECK:STDOUT:   %.loc7_28.3: %facet_type.f48fc7.1 = converted constants.%i32, %facet_value.loc7_28.1 [concrete = constants.%facet_value.178]
// CHECK:STDOUT:   %facet_value.loc7_28.2: %facet_type.f48fc7.1 = facet_value bool, (constants.%custom_witness.f8f19d.2, constants.%Copy.impl_witness.5e1) [concrete = constants.%facet_value.aa6]
// CHECK:STDOUT:   %.loc7_28.4: %facet_type.f48fc7.1 = converted bool, %facet_value.loc7_28.2 [concrete = constants.%facet_value.aa6]
// CHECK:STDOUT:   %.loc7_28.5: %pack_type.6eb = pack_value (%.loc7_28.3, %.loc7_28.4) [concrete = constants.%.38e]
// CHECK:STDOUT:   %.loc7_28.6: %pack_type.6eb = converted constants.%.89b, %.loc7_28.5 [concrete = constants.%.38e]
// CHECK:STDOUT:   %F.specific_fn: <specific function> = specific_function %F.ref, @F(constants.%int_2, constants.%.38e) [concrete = constants.%F.specific_fn.7de]
// CHECK:STDOUT:   %.loc6_28.1: ref %tuple.type.6ed = splice_block %return.param {}
// CHECK:STDOUT:   %tuple: %tuple.type.6ed = tuple_value (%.loc7_15.2, %true) [concrete = constants.%tuple.078]
// CHECK:STDOUT:   %.loc7_27.2: %tuple.type.6ed = converted %.loc7_27.1, %tuple [concrete = constants.%tuple.078]
// CHECK:STDOUT:   %F.call: init %tuple.type.6ed to %.loc6_28.1 = call %F.specific_fn(%.loc7_27.2)
// CHECK:STDOUT:   return %F.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc7_28.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc7_28.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc7_28.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc7_28.2(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc7_28.2(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc7_28.2(%self.param: ref bool) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Generic(%arity.loc10_12.2: Core.IntLiteral, %T.loc10_22.2: @Generic.%pack_type.loc10_22 (%pack_type.18c88c.2)) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc10_12.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc10_22: type = pack_type constants.%facet_type.f48fc7.2, %arity.loc10_12.1 [symbolic = %pack_type.loc10_22 (constants.%pack_type.18c88c.2)]
// CHECK:STDOUT:   %pattern_type.loc10_22: type = pattern_type %pack_type.loc10_22 [symbolic = %pattern_type.loc10_22 (constants.%pattern_type.4fea90.2)]
// CHECK:STDOUT:   %T.patt.loc10_22.2: @Generic.%pattern_type.loc10_22 (%pattern_type.4fea90.2) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc10_22.2 (constants.%T.patt.dda460.2)]
// CHECK:STDOUT:   %T.loc10_22.1: @Generic.%pack_type.loc10_22 (%pack_type.18c88c.2) = symbolic_binding T, 1 [symbolic = %T.loc10_22.1 (constants.%T.b9dbda.2)]
// CHECK:STDOUT:   %.loc10_12.2: @Generic.%pattern_type.loc10_22 (%pattern_type.4fea90.2) = pack_expansion_pattern %T.patt.loc10_22.2, %arity.patt.loc10_12.2 [symbolic = %.loc10_12.2 (constants.%.d7b3f5.2)]
// CHECK:STDOUT:   %.loc10_68.1: Core.IntLiteral = pack_index [symbolic = %.loc10_68.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc10_68.2: %facet_type.f48fc7.2 = pack_element %T.loc10_22.1, %.loc10_68.1 [symbolic = %.loc10_68.2 (constants.%.2fac42.2)]
// CHECK:STDOUT:   %tuple.type.loc10_74.1: type = tuple_type (%pack_type.loc10_22) [symbolic = %tuple.type.loc10_74.1 (constants.%tuple.type.be394e.2)]
// CHECK:STDOUT:   %tuple: @Generic.%tuple.type.loc10_74.1 (%tuple.type.be394e.2) = tuple_value (%T.loc10_22.1) [symbolic = %tuple (constants.%tuple.5b4b0d.2)]
// CHECK:STDOUT:   %pack_type.loc10_74: type = pack_type %T.loc10_22.1, %arity.loc10_12.1 [symbolic = %pack_type.loc10_74 (constants.%pack_type.9f5019.2)]
// CHECK:STDOUT:   %tuple.type.loc10_74.2: type = tuple_type (%pack_type.loc10_74) [symbolic = %tuple.type.loc10_74.2 (constants.%tuple.type.6277e2.2)]
// CHECK:STDOUT:   %pattern_type.loc10_61: type = pattern_type %tuple.type.loc10_74.2 [symbolic = %pattern_type.loc10_61 (constants.%pattern_type.38532c.2)]
// CHECK:STDOUT:   %t.param_patt.loc10_61.2: @Generic.%pattern_type.loc10_61 (%pattern_type.38532c.2) = value_param_pattern [symbolic = %t.param_patt.loc10_61.2 (constants.%t.param_patt.3848f4.2)]
// CHECK:STDOUT:   %t.patt.loc10_61.2: @Generic.%pattern_type.loc10_61 (%pattern_type.38532c.2) = wrapper_binding_pattern t, %t.param_patt.loc10_61.2 [symbolic = %t.patt.loc10_61.2 (constants.%t.patt.f8d902.2)]
// CHECK:STDOUT:   %.loc11_19.2: Core.Form = init_form %tuple.type.loc10_74.2 [symbolic = %.loc11_19.2 (constants.%.374b4c.2)]
// CHECK:STDOUT:   %return.param_patt.loc11_19.2: @Generic.%pattern_type.loc10_61 (%pattern_type.38532c.2) = out_param_pattern [symbolic = %return.param_patt.loc11_19.2 (constants.%return.param_patt.5a734b.2)]
// CHECK:STDOUT:   %return.patt.loc11_5.2: @Generic.%pattern_type.loc10_61 (%pattern_type.38532c.2) = return_slot_pattern %return.param_patt.loc11_19.2, %tuple.type.loc10_74.2 [symbolic = %return.patt.loc11_5.2 (constants.%return.patt.bce)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %tuple.type.loc10_74.2 [symbolic = %require_complete.loc10 (constants.%require_complete.6ec572.2)]
// CHECK:STDOUT:   %pack_type.loc12: type = pack_type constants.%facet_type.f48fc7.1, %arity.loc10_12.1 [symbolic = %pack_type.loc12 (constants.%pack_type.18c88c.1)]
// CHECK:STDOUT:   %require_complete.loc12: <witness> = require_complete_type %pack_type.loc12 [symbolic = %require_complete.loc12 (constants.%require_complete.e52)]
// CHECK:STDOUT:   %as_type: type = facet_access_type %.loc10_68.2 [symbolic = %as_type (constants.%as_type.639ae5.2)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %.loc10_68.2, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.6a8)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %.loc10_68.2, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.f574a8.2)]
// CHECK:STDOUT:   %facet_value: %facet_type.f48fc7.1 = facet_value %as_type, (%Destroy.lookup_impl_witness, %Copy.lookup_impl_witness) [symbolic = %facet_value (constants.%facet_value.71b)]
// CHECK:STDOUT:   %.loc12_13.3: @Generic.%pack_type.loc12 (%pack_type.18c88c.1) = pack_facet_value %T.loc10_22.1 [symbolic = %.loc12_13.3 (constants.%.ba7)]
// CHECK:STDOUT:   %F.specific_fn.loc12_10.2: <specific function> = specific_function constants.%F, @F(%arity.loc10_12.1, %.loc12_13.3) [symbolic = %F.specific_fn.loc12_10.2 (constants.%F.specific_fn.aab)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @Generic.%tuple.type.loc10_74.2 (%tuple.type.6277e2.2)) -> out %return.param: @Generic.%tuple.type.loc10_74.2 (%tuple.type.6277e2.2) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %F.ref: %F.type = name_ref F, imports.%Main.F [concrete = constants.%F]
// CHECK:STDOUT:     %t.ref: @Generic.%tuple.type.loc10_74.2 (%tuple.type.6277e2.2) = name_ref t, %t
// CHECK:STDOUT:     %.loc12_13.1: @Generic.%pack_type.loc12 (%pack_type.18c88c.1) = pack_facet_value constants.%T.b9dbda.2 [symbolic = %.loc12_13.3 (constants.%.ba7)]
// CHECK:STDOUT:     %.loc12_13.2: @Generic.%pack_type.loc12 (%pack_type.18c88c.1) = converted constants.%T.b9dbda.2, %.loc12_13.1 [symbolic = %.loc12_13.3 (constants.%.ba7)]
// CHECK:STDOUT:     %F.specific_fn.loc12_10.1: <specific function> = specific_function %F.ref, @F(constants.%arity, constants.%.ba7) [symbolic = %F.specific_fn.loc12_10.2 (constants.%F.specific_fn.aab)]
// CHECK:STDOUT:     %.loc11_19.1: ref @Generic.%tuple.type.loc10_74.2 (%tuple.type.6277e2.2) = splice_block %return.param {}
// CHECK:STDOUT:     %F.call: init @Generic.%tuple.type.loc10_74.2 (%tuple.type.6277e2.2) to %.loc11_19.1 = call %F.specific_fn.loc12_10.1(%t.ref)
// CHECK:STDOUT:     return %F.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Generic(constants.%arity, constants.%T.b9dbda.2) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_12.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc10_22 => constants.%pack_type.18c88c.2
// CHECK:STDOUT:   %pattern_type.loc10_22 => constants.%pattern_type.4fea90.2
// CHECK:STDOUT:   %T.patt.loc10_22.2 => constants.%T.patt.dda460.2
// CHECK:STDOUT:   %T.loc10_22.1 => constants.%T.b9dbda.2
// CHECK:STDOUT:   %.loc10_12.2 => constants.%.d7b3f5.2
// CHECK:STDOUT:   %.loc10_68.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc10_68.2 => constants.%.2fac42.2
// CHECK:STDOUT:   %tuple.type.loc10_74.1 => constants.%tuple.type.be394e.2
// CHECK:STDOUT:   %tuple => constants.%tuple.5b4b0d.2
// CHECK:STDOUT:   %pack_type.loc10_74 => constants.%pack_type.9f5019.2
// CHECK:STDOUT:   %tuple.type.loc10_74.2 => constants.%tuple.type.6277e2.2
// CHECK:STDOUT:   %pattern_type.loc10_61 => constants.%pattern_type.38532c.2
// CHECK:STDOUT:   %t.param_patt.loc10_61.2 => constants.%t.param_patt.3848f4.2
// CHECK:STDOUT:   %t.patt.loc10_61.2 => constants.%t.patt.f8d902.2
// CHECK:STDOUT:   %.loc11_19.2 => constants.%.374b4c.2
// CHECK:STDOUT:   %return.param_patt.loc11_19.2 => constants.%return.param_patt.5a734b.2
// CHECK:STDOUT:   %return.patt.loc11_5.2 => constants.%return.patt.bce
// CHECK:STDOUT: }
// CHECK:STDOUT:
