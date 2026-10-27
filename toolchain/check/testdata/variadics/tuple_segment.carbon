// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/tuple_segment.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/tuple_segment.carbon

// --- param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F[... each T: type](unused t: (... each T)) {}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  F((1 as i64, true));
  F(());
  //@dump-sem-ir-end
}

// --- return.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}
//@dump-sem-ir-end

fn Call() -> (i64, bool) {
  //@dump-sem-ir-begin
  return MakeTuple(1 as i64, true);
  //@dump-sem-ir-end
}

// --- let.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

interface Code {
  fn Get(self) -> i64;
}

//@dump-sem-ir-begin
fn ForEach[... each T: Code](t: (... each T)) {
  let (... each x: each T) = t;
  ... Consume(each x.Get());
}
//@dump-sem-ir-end

// --- tuple_value.carbon
library "[[@TEST_NAME]]";

fn Take[... each U: type](unused t: (... each U)) {}

//@dump-sem-ir-begin
fn Pass[... each T: type](... each x: each T) {
  Take((... each x));
}
//@dump-sem-ir-end

// --- elements_around_segment.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](unused t: (i64, ... each T, bool)) {}

fn Call() {
  //@dump-sem-ir-begin
  F((1 as i64, 2 as i32, false, true));
  F((1 as i64, true));
  //@dump-sem-ir-end
}

// CHECK:STDOUT: --- param.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.fc0: type = pattern_type %pack_type.c29 [symbolic]
// CHECK:STDOUT:   %T.patt.f84: %pattern_type.fc0 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.99e: %pattern_type.fc0 = pack_expansion_pattern %T.patt.f84, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.425: type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.852: type = tuple_type (%pack_type.c29) [symbolic]
// CHECK:STDOUT:   %tuple.d38: %tuple.type.852 = tuple_value (%T) [symbolic]
// CHECK:STDOUT:   %pack_type.8fb: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.423: type = tuple_type (%pack_type.8fb) [symbolic]
// CHECK:STDOUT:   %pattern_type.e36: type = pattern_type %tuple.type.423 [symbolic]
// CHECK:STDOUT:   %t.param_patt.001: %pattern_type.e36 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt.569: %pattern_type.e36 = wrapper_binding_pattern t, %t.param_patt.001 [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.f6f: <witness> = require_complete_type %tuple.type.423 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %As.type.998: type = facet_type <@As, @As(%i64)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.c5d: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.6ee: %Core.IntLiteral.as.As.impl.Convert.type.c5d = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.0fe: <witness> = impl_witness imports.%As.impl_witness_table.d22, @Core.IntLiteral.as.As.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.1a1: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.3d9: %Core.IntLiteral.as.As.impl.Convert.type.1a1 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.998 = facet_value Core.IntLiteral, (%As.impl_witness.0fe) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.7f7: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i64, %As.facet) [concrete]
// CHECK:STDOUT:   %.8fd: type = fn_type_with_self_type %As.WithSelf.Convert.type.7f7, %As.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.3d9 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.3d9, @Core.IntLiteral.as.As.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %tuple.type.f41: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.f52: %tuple.type.f41 = tuple_value (%int_1.d98, %true) [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.abd: %pack_type.8f6 = pack_value (%i64, bool) [concrete]
// CHECK:STDOUT:   %pattern_type.b37: type = pattern_type %pack_type.8f6 [concrete]
// CHECK:STDOUT:   %T.patt.8a9: %pattern_type.b37 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.6c7: %pattern_type.b37 = pack_expansion_pattern %T.patt.8a9, %arity.patt [symbolic]
// CHECK:STDOUT:   %.867: type = pack_element %.abd, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.693: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.3f9: %tuple.type.693 = tuple_value (%i64, bool) [concrete]
// CHECK:STDOUT:   %pack_type.394: type = pack_type %.abd, %int_2 [concrete]
// CHECK:STDOUT:   %pattern_type.ea0: type = pattern_type %tuple.type.f41 [concrete]
// CHECK:STDOUT:   %t.param_patt.15d: %pattern_type.ea0 = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt.355: %pattern_type.ea0 = wrapper_binding_pattern t, %t.param_patt.15d [concrete]
// CHECK:STDOUT:   %F.specific_fn.f39: <specific function> = specific_function %F, @F(%int_2, %.abd) [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %pack_type.28d: type = pack_type type, %int_0 [concrete]
// CHECK:STDOUT:   %.d3f: %pack_type.28d = pack_value () [concrete]
// CHECK:STDOUT:   %pattern_type.94c: type = pattern_type %pack_type.28d [concrete]
// CHECK:STDOUT:   %T.patt.75e: %pattern_type.94c = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.b4d: %pattern_type.94c = pack_expansion_pattern %T.patt.75e, %arity.patt [symbolic]
// CHECK:STDOUT:   %.8a1: type = pack_element %.d3f, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.54a: type = pack_type %.d3f, %int_0 [concrete]
// CHECK:STDOUT:   %pattern_type.cb1: type = pattern_type %empty_tuple.type [concrete]
// CHECK:STDOUT:   %t.param_patt.e86: %pattern_type.cb1 = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt.efd: %pattern_type.cb1 = wrapper_binding_pattern t, %t.param_patt.e86 [concrete]
// CHECK:STDOUT:   %F.specific_fn.fba: <specific function> = specific_function %F, @F(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %complete_type.6e7: <witness> = complete_type_witness %tuple.type.f41 [concrete]
// CHECK:STDOUT:   %complete_type.782: <witness> = complete_type_witness %empty_tuple.type [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %arity.patt.loc4_6.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc4_16.1: @F.%pattern_type.loc4_16 (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_16.2 (constants.%T.patt.f84)]
// CHECK:STDOUT:     %.loc4_6.1: @F.%pattern_type.loc4_16 (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc4_16.1, %arity.patt.loc4_6.1 [symbolic = %.loc4_6.2 (constants.%.99e)]
// CHECK:STDOUT:     %t.param_patt.loc4_32.1: @F.%pattern_type.loc4_32 (%pattern_type.e36) = value_param_pattern [symbolic = %t.param_patt.loc4_32.2 (constants.%t.param_patt.001)]
// CHECK:STDOUT:     %t.patt.loc4_32.1: @F.%pattern_type.loc4_32 (%pattern_type.e36) = wrapper_binding_pattern t, %t.param_patt.loc4_32.1 [symbolic = %t.patt.loc4_32.2 (constants.%t.patt.569)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc4_6.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_6.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc4_18.1: type = splice_block %.loc4_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_16.2: @F.%pack_type.loc4_16 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc4_16.1 (constants.%T)]
// CHECK:STDOUT:     %t.param: @F.%tuple.type.loc4_45.2 (%tuple.type.423) = value_param call_param0
// CHECK:STDOUT:     %.loc4_45.1: type = splice_block %.loc4_45.3 [symbolic = %tuple.type.loc4_45.2 (constants.%tuple.type.423)] {
// CHECK:STDOUT:       %.loc4_45.2: @F.%tuple.type.loc4_45.1 (%tuple.type.852) = tuple_literal (constants.%T) [symbolic = %tuple (constants.%tuple.d38)]
// CHECK:STDOUT:       %.loc4_45.3: type = converted %.loc4_45.2, constants.%tuple.type.423 [symbolic = %tuple.type.loc4_45.2 (constants.%tuple.type.423)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: @F.%tuple.type.loc4_45.2 (%tuple.type.423) = wrapper_binding t, %t.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%arity.loc4_6.2: Core.IntLiteral, %T.loc4_16.2: @F.%pack_type.loc4_16 (%pack_type.c29)) {
// CHECK:STDOUT:   %arity.patt.loc4_6.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc4_6.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_6.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc4_16: type = pack_type type, %arity.loc4_6.1 [symbolic = %pack_type.loc4_16 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %pattern_type.loc4_16: type = pattern_type %pack_type.loc4_16 [symbolic = %pattern_type.loc4_16 (constants.%pattern_type.fc0)]
// CHECK:STDOUT:   %T.patt.loc4_16.2: @F.%pattern_type.loc4_16 (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_16.2 (constants.%T.patt.f84)]
// CHECK:STDOUT:   %T.loc4_16.1: @F.%pack_type.loc4_16 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc4_16.1 (constants.%T)]
// CHECK:STDOUT:   %.loc4_6.2: @F.%pattern_type.loc4_16 (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc4_16.2, %arity.patt.loc4_6.2 [symbolic = %.loc4_6.2 (constants.%.99e)]
// CHECK:STDOUT:   %.loc4_39.1: Core.IntLiteral = pack_index [symbolic = %.loc4_39.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc4_39.2: type = pack_element %T.loc4_16.1, %.loc4_39.1 [symbolic = %.loc4_39.2 (constants.%.425)]
// CHECK:STDOUT:   %tuple.type.loc4_45.1: type = tuple_type (%pack_type.loc4_16) [symbolic = %tuple.type.loc4_45.1 (constants.%tuple.type.852)]
// CHECK:STDOUT:   %tuple: @F.%tuple.type.loc4_45.1 (%tuple.type.852) = tuple_value (%T.loc4_16.1) [symbolic = %tuple (constants.%tuple.d38)]
// CHECK:STDOUT:   %pack_type.loc4_45: type = pack_type %T.loc4_16.1, %arity.loc4_6.1 [symbolic = %pack_type.loc4_45 (constants.%pack_type.8fb)]
// CHECK:STDOUT:   %tuple.type.loc4_45.2: type = tuple_type (%pack_type.loc4_45) [symbolic = %tuple.type.loc4_45.2 (constants.%tuple.type.423)]
// CHECK:STDOUT:   %pattern_type.loc4_32: type = pattern_type %tuple.type.loc4_45.2 [symbolic = %pattern_type.loc4_32 (constants.%pattern_type.e36)]
// CHECK:STDOUT:   %t.param_patt.loc4_32.2: @F.%pattern_type.loc4_32 (%pattern_type.e36) = value_param_pattern [symbolic = %t.param_patt.loc4_32.2 (constants.%t.param_patt.001)]
// CHECK:STDOUT:   %t.patt.loc4_32.2: @F.%pattern_type.loc4_32 (%pattern_type.e36) = wrapper_binding_pattern t, %t.param_patt.loc4_32.2 [symbolic = %t.patt.loc4_32.2 (constants.%t.patt.569)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %tuple.type.loc4_45.2 [symbolic = %require_complete (constants.%require_complete.f6f)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @F.%tuple.type.loc4_45.2 (%tuple.type.423)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref.loc9: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc9_8.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_8.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call: init %i64 = call %bound_method.loc9_8.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc9_8.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc9_8.2: %i64 = converted %int_1, %.loc9_8.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc9_20.1: %tuple.type.f41 = tuple_literal (%.loc9_8.2, %true) [concrete = constants.%tuple.f52]
// CHECK:STDOUT:   %int_2.loc9_21.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc9_21.1: %pack_type.8f6 = pack_value (constants.%i64, bool) [concrete = constants.%.abd]
// CHECK:STDOUT:   %int_2.loc9_21.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc9_21.2: %pack_type.8f6 = pack_value (constants.%i64, bool) [concrete = constants.%.abd]
// CHECK:STDOUT:   %F.specific_fn.loc9: <specific function> = specific_function %F.ref.loc9, @F(constants.%int_2, constants.%.abd) [concrete = constants.%F.specific_fn.f39]
// CHECK:STDOUT:   %tuple: %tuple.type.f41 = tuple_value (%.loc9_8.2, %true) [concrete = constants.%tuple.f52]
// CHECK:STDOUT:   %.loc9_20.2: %tuple.type.f41 = converted %.loc9_20.1, %tuple [concrete = constants.%tuple.f52]
// CHECK:STDOUT:   %F.call.loc9: init %empty_tuple.type = call %F.specific_fn.loc9(%.loc9_20.2)
// CHECK:STDOUT:   %F.ref.loc10: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %.loc10_6.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %int_0.loc10_7.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc10_7.1: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %int_0.loc10_7.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc10_7.2: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %F.specific_fn.loc10: <specific function> = specific_function %F.ref.loc10, @F(constants.%int_0, constants.%.d3f) [concrete = constants.%F.specific_fn.fba]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc10_6.2: %empty_tuple.type = converted %.loc10_6.1, %empty_tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %F.call.loc10: init %empty_tuple.type = call %F.specific_fn.loc10(%.loc10_6.2)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity.patt.loc4_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_6.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc4_16 => constants.%pack_type.c29
// CHECK:STDOUT:   %pattern_type.loc4_16 => constants.%pattern_type.fc0
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt.f84
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%T
// CHECK:STDOUT:   %.loc4_6.2 => constants.%.99e
// CHECK:STDOUT:   %.loc4_39.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_39.2 => constants.%.425
// CHECK:STDOUT:   %tuple.type.loc4_45.1 => constants.%tuple.type.852
// CHECK:STDOUT:   %tuple => constants.%tuple.d38
// CHECK:STDOUT:   %pack_type.loc4_45 => constants.%pack_type.8fb
// CHECK:STDOUT:   %tuple.type.loc4_45.2 => constants.%tuple.type.423
// CHECK:STDOUT:   %pattern_type.loc4_32 => constants.%pattern_type.e36
// CHECK:STDOUT:   %t.param_patt.loc4_32.2 => constants.%t.param_patt.001
// CHECK:STDOUT:   %t.patt.loc4_32.2 => constants.%t.patt.569
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%int_2, constants.%.abd) {
// CHECK:STDOUT:   %arity.patt.loc4_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_6.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc4_16 => constants.%pack_type.8f6
// CHECK:STDOUT:   %pattern_type.loc4_16 => constants.%pattern_type.b37
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt.8a9
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%.abd
// CHECK:STDOUT:   %.loc4_6.2 => constants.%.6c7
// CHECK:STDOUT:   %.loc4_39.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_39.2 => constants.%.867
// CHECK:STDOUT:   %tuple.type.loc4_45.1 => constants.%tuple.type.693
// CHECK:STDOUT:   %tuple => constants.%tuple.3f9
// CHECK:STDOUT:   %pack_type.loc4_45 => constants.%pack_type.394
// CHECK:STDOUT:   %tuple.type.loc4_45.2 => constants.%tuple.type.f41
// CHECK:STDOUT:   %pattern_type.loc4_32 => constants.%pattern_type.ea0
// CHECK:STDOUT:   %t.param_patt.loc4_32.2 => constants.%t.param_patt.15d
// CHECK:STDOUT:   %t.patt.loc4_32.2 => constants.%t.patt.355
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.6e7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%int_0, constants.%.d3f) {
// CHECK:STDOUT:   %arity.patt.loc4_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_6.1 => constants.%int_0
// CHECK:STDOUT:   %pack_type.loc4_16 => constants.%pack_type.28d
// CHECK:STDOUT:   %pattern_type.loc4_16 => constants.%pattern_type.94c
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt.75e
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%.d3f
// CHECK:STDOUT:   %.loc4_6.2 => constants.%.b4d
// CHECK:STDOUT:   %.loc4_39.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_39.2 => constants.%.8a1
// CHECK:STDOUT:   %tuple.type.loc4_45.1 => constants.%empty_tuple.type
// CHECK:STDOUT:   %tuple => constants.%empty_tuple
// CHECK:STDOUT:   %pack_type.loc4_45 => constants.%pack_type.54a
// CHECK:STDOUT:   %tuple.type.loc4_45.2 => constants.%empty_tuple.type
// CHECK:STDOUT:   %pattern_type.loc4_32 => constants.%pattern_type.cb1
// CHECK:STDOUT:   %t.param_patt.loc4_32.2 => constants.%t.param_patt.e86
// CHECK:STDOUT:   %t.patt.loc4_32.2 => constants.%t.patt.efd
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.782
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- return.carbon
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
// CHECK:STDOUT:   %T.patt.fcf: %pattern_type.f66 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T.49b: %pack_type.dee = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.c72: %pattern_type.f66 = pack_expansion_pattern %T.patt.fcf, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.375: %Copy.type = pack_element %T.49b, %.4ee [symbolic]
// CHECK:STDOUT:   %as_type.bf9: type = facet_access_type %.375 [symbolic]
// CHECK:STDOUT:   %pack_type.8fe: type = pack_type %T.49b, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.550: type = pattern_type %pack_type.8fe [symbolic]
// CHECK:STDOUT:   %x.param_patt.da7: %pattern_type.550 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.c61: %pattern_type.550 = wrapper_binding_pattern x, %x.param_patt.da7 [symbolic]
// CHECK:STDOUT:   %.c31: %pattern_type.550 = pack_expansion_pattern %x.patt.c61, invalid [symbolic]
// CHECK:STDOUT:   %tuple.type.7db: type = tuple_type (%pack_type.dee) [symbolic]
// CHECK:STDOUT:   %tuple.846: %tuple.type.7db = tuple_value (%T.49b) [symbolic]
// CHECK:STDOUT:   %tuple.type.e97: type = tuple_type (%pack_type.8fe) [symbolic]
// CHECK:STDOUT:   %.4a2: Core.Form = init_form %tuple.type.e97 [symbolic]
// CHECK:STDOUT:   %pattern_type.605: type = pattern_type %tuple.type.e97 [symbolic]
// CHECK:STDOUT:   %return.param_patt.969: %pattern_type.605 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.1e6: %pattern_type.605 = return_slot_pattern %return.param_patt.969, %tuple.type.e97 [symbolic]
// CHECK:STDOUT:   %MakeTuple.type: type = fn_type @MakeTuple [concrete]
// CHECK:STDOUT:   %MakeTuple: %MakeTuple.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.660: <witness> = require_complete_type %pack_type.8fe [symbolic]
// CHECK:STDOUT:   %require_complete.b74: <witness> = require_complete_type %tuple.type.e97 [symbolic]
// CHECK:STDOUT:   %require_complete.16c: <witness> = require_complete_type %as_type.bf9 [symbolic]
// CHECK:STDOUT:   %tuple.type.24a: type = tuple_type (%Copy.type, %Copy.type) [concrete]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.5fe: <witness> = lookup_impl_witness %.375, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.510: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%.375) [symbolic]
// CHECK:STDOUT:   %.b29: type = fn_type_with_self_type %Copy.WithSelf.Op.type.510, %.375 [symbolic]
// CHECK:STDOUT:   %impl.elem0.4e2: %.b29 = impl_witness_access %Copy.lookup_impl_witness.5fe, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.825: <specific function> = specific_impl_function %impl.elem0.4e2, @Copy.WithSelf.Op(%.375) [symbolic]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %tuple.type.f41: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %.6fd: Core.Form = init_form %tuple.type.f41 [concrete]
// CHECK:STDOUT:   %pattern_type.ea0: type = pattern_type %tuple.type.f41 [concrete]
// CHECK:STDOUT:   %return.param_patt.893: %pattern_type.ea0 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.279: %pattern_type.ea0 = return_slot_pattern %return.param_patt.893, %tuple.type.f41 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %As.type.116: type = generic_interface_type @As [concrete]
// CHECK:STDOUT:   %As.generic: %As.type.116 = struct_value () [concrete]
// CHECK:STDOUT:   %As.type.998: type = facet_type <@As, @As(%i64)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.c5d: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.6ee: %Core.IntLiteral.as.As.impl.Convert.type.c5d = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.0fe: <witness> = impl_witness imports.%As.impl_witness_table.d22, @Core.IntLiteral.as.As.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.1a1: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.3d9: %Core.IntLiteral.as.As.impl.Convert.type.1a1 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.998 = facet_value Core.IntLiteral, (%As.impl_witness.0fe) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.7f7: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i64, %As.facet) [concrete]
// CHECK:STDOUT:   %.8fd: type = fn_type_with_self_type %As.WithSelf.Convert.type.7f7, %As.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.3d9 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.3d9, @Core.IntLiteral.as.As.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.abd: %pack_type.8f6 = pack_value (%i64, bool) [concrete]
// CHECK:STDOUT:   %pack_type.8ea: type = pack_type %Copy.type, %int_2 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Copy.facet.4e9: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %Copy.facet.7af: %Copy.type = facet_value bool, (%Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %.ea1: %pack_type.8ea = pack_value (%Copy.facet.4e9, %Copy.facet.7af) [concrete]
// CHECK:STDOUT:   %pattern_type.488: type = pattern_type %pack_type.8ea [concrete]
// CHECK:STDOUT:   %T.patt.31f: %pattern_type.488 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.586: %pattern_type.488 = pack_expansion_pattern %T.patt.31f, %arity.patt [symbolic]
// CHECK:STDOUT:   %.405: %Copy.type = pack_element %.ea1, %.4ee [symbolic]
// CHECK:STDOUT:   %as_type.841: type = facet_access_type %.405 [symbolic]
// CHECK:STDOUT:   %pack_type.3d7: type = pack_type %.ea1, %int_2 [concrete]
// CHECK:STDOUT:   %pattern_type.2ee: type = pattern_type %pack_type.3d7 [concrete]
// CHECK:STDOUT:   %x.param_patt.3f5: %pattern_type.2ee = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.765: %pattern_type.2ee = wrapper_binding_pattern x, %x.param_patt.3f5 [concrete]
// CHECK:STDOUT:   %.f24: %pattern_type.2ee = pack_expansion_pattern %x.patt.765, invalid [concrete]
// CHECK:STDOUT:   %tuple.20e: %tuple.type.24a = tuple_value (%Copy.facet.4e9, %Copy.facet.7af) [concrete]
// CHECK:STDOUT:   %MakeTuple.specific_fn: <specific function> = specific_function %MakeTuple, @MakeTuple(%int_2, %.ea1) [concrete]
// CHECK:STDOUT:   %.f38: %pack_type.3d7 = pack_value (%int_1.d98, %true) [concrete]
// CHECK:STDOUT:   %complete_type.c16: <witness> = complete_type_witness %pack_type.3d7 [concrete]
// CHECK:STDOUT:   %complete_type.6e7: <witness> = complete_type_witness %tuple.type.f41 [concrete]
// CHECK:STDOUT:   %require_complete.a57: <witness> = require_complete_type %as_type.841 [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.27b: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%.405) [symbolic]
// CHECK:STDOUT:   %.3b8: type = fn_type_with_self_type %Copy.WithSelf.Op.type.27b, %.405 [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.471: <witness> = lookup_impl_witness %.405, @Copy [symbolic]
// CHECK:STDOUT:   %impl.elem0.953: %.3b8 = impl_witness_access %Copy.lookup_impl_witness.471, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.c6f: <specific function> = specific_impl_function %impl.elem0.953, @Copy.WithSelf.Op(%.405) [symbolic]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.type: type = fn_type @bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op: %bool.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .As = %Core.As
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/parts/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/parts/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/parts/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.As: %As.type.116 = import_ref Core//prelude/parts/as, As, loaded [concrete = constants.%As.generic]
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.9c3: %bool.as.Copy.impl.Op.type = import_ref Core//prelude/parts/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.9c3), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %MakeTuple.decl: %MakeTuple.type = fn_decl @MakeTuple [concrete = constants.%MakeTuple] {
// CHECK:STDOUT:     %arity.patt.loc4_14.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc4_24.1: @MakeTuple.%pattern_type.loc4_24 (%pattern_type.f66) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_24.2 (constants.%T.patt.fcf)]
// CHECK:STDOUT:     %.loc4_14.1: @MakeTuple.%pattern_type.loc4_24 (%pattern_type.f66) = pack_expansion_pattern %T.patt.loc4_24.1, %arity.patt.loc4_14.1 [symbolic = %.loc4_14.2 (constants.%.c72)]
// CHECK:STDOUT:     %x.param_patt.loc4_47.1: @MakeTuple.%pattern_type.loc4_47 (%pattern_type.550) = value_param_pattern [symbolic = %x.param_patt.loc4_47.2 (constants.%x.param_patt.da7)]
// CHECK:STDOUT:     %x.patt.loc4_47.1: @MakeTuple.%pattern_type.loc4_47 (%pattern_type.550) = wrapper_binding_pattern x, %x.param_patt.loc4_47.1 [symbolic = %x.patt.loc4_47.2 (constants.%x.patt.c61)]
// CHECK:STDOUT:     %.loc4_37.1: @MakeTuple.%pattern_type.loc4_47 (%pattern_type.550) = pack_expansion_pattern %x.patt.loc4_47.1, invalid [symbolic = %.loc4_37.2 (constants.%.c31)]
// CHECK:STDOUT:     %return.param_patt.loc4_71.1: @MakeTuple.%pattern_type.loc4_71 (%pattern_type.605) = out_param_pattern [symbolic = %return.param_patt.loc4_71.2 (constants.%return.param_patt.969)]
// CHECK:STDOUT:     %return.patt.loc4_57.1: @MakeTuple.%pattern_type.loc4_71 (%pattern_type.605) = return_slot_pattern %return.param_patt.loc4_71.1, %.loc4_71.3 [symbolic = %return.patt.loc4_57.2 (constants.%return.patt.1e6)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_71.2: @MakeTuple.%tuple.type.loc4_71.1 (%tuple.type.7db) = tuple_literal (constants.%T.49b) [symbolic = %tuple (constants.%tuple.846)]
// CHECK:STDOUT:     %.loc4_71.3: type = converted %.loc4_71.2, constants.%tuple.type.e97 [symbolic = %tuple.type.loc4_71.2 (constants.%tuple.type.e97)]
// CHECK:STDOUT:     %.loc4_71.4: Core.Form = init_form %.loc4_71.3 [symbolic = %.loc4_71.1 (constants.%.4a2)]
// CHECK:STDOUT:     %arity.loc4_14.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_14.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc4_30: type = splice_block %Copy.ref [concrete = constants.%Copy.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_24.2: @MakeTuple.%pack_type.loc4_24 (%pack_type.dee) = symbolic_binding T, 1 [symbolic = %T.loc4_24.1 (constants.%T.49b)]
// CHECK:STDOUT:     %x.param: @MakeTuple.%pack_type.loc4_47 (%pack_type.8fe) = value_param call_param0
// CHECK:STDOUT:     %.loc4_49.3: type = splice_block %.loc4_49.6 [symbolic = %as_type.loc4_49.1 (constants.%as_type.bf9)] {
// CHECK:STDOUT:       %T.ref: @MakeTuple.%pack_type.loc4_24 (%pack_type.dee) = name_ref T, %T.loc4_24.2 [symbolic = %T.loc4_24.1 (constants.%T.49b)]
// CHECK:STDOUT:       %.loc4_49.4: Core.IntLiteral = pack_index [symbolic = %.loc4_49.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc4_49.5: %Copy.type = pack_element %T.ref, %.loc4_49.4 [symbolic = %.loc4_49.2 (constants.%.375)]
// CHECK:STDOUT:       %as_type.loc4_49.2: type = facet_access_type %.loc4_49.5 [symbolic = %as_type.loc4_49.1 (constants.%as_type.bf9)]
// CHECK:STDOUT:       %.loc4_49.6: type = converted %.loc4_49.5, %as_type.loc4_49.2 [symbolic = %as_type.loc4_49.1 (constants.%as_type.bf9)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @MakeTuple.%pack_type.loc4_47 (%pack_type.8fe) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref @MakeTuple.%tuple.type.loc4_71.2 (%tuple.type.e97) = out_param call_param1
// CHECK:STDOUT:     %return: ref @MakeTuple.%tuple.type.loc4_71.2 (%tuple.type.e97) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @MakeTuple(%arity.loc4_14.2: Core.IntLiteral, %T.loc4_24.2: @MakeTuple.%pack_type.loc4_24 (%pack_type.dee)) {
// CHECK:STDOUT:   %arity.patt.loc4_14.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc4_14.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_14.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc4_24: type = pack_type constants.%Copy.type, %arity.loc4_14.1 [symbolic = %pack_type.loc4_24 (constants.%pack_type.dee)]
// CHECK:STDOUT:   %pattern_type.loc4_24: type = pattern_type %pack_type.loc4_24 [symbolic = %pattern_type.loc4_24 (constants.%pattern_type.f66)]
// CHECK:STDOUT:   %T.patt.loc4_24.2: @MakeTuple.%pattern_type.loc4_24 (%pattern_type.f66) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_24.2 (constants.%T.patt.fcf)]
// CHECK:STDOUT:   %T.loc4_24.1: @MakeTuple.%pack_type.loc4_24 (%pack_type.dee) = symbolic_binding T, 1 [symbolic = %T.loc4_24.1 (constants.%T.49b)]
// CHECK:STDOUT:   %.loc4_14.2: @MakeTuple.%pattern_type.loc4_24 (%pattern_type.f66) = pack_expansion_pattern %T.patt.loc4_24.2, %arity.patt.loc4_14.2 [symbolic = %.loc4_14.2 (constants.%.c72)]
// CHECK:STDOUT:   %.loc4_49.1: Core.IntLiteral = pack_index [symbolic = %.loc4_49.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc4_49.2: %Copy.type = pack_element %T.loc4_24.1, %.loc4_49.1 [symbolic = %.loc4_49.2 (constants.%.375)]
// CHECK:STDOUT:   %as_type.loc4_49.1: type = facet_access_type %.loc4_49.2 [symbolic = %as_type.loc4_49.1 (constants.%as_type.bf9)]
// CHECK:STDOUT:   %pack_type.loc4_47: type = pack_type %T.loc4_24.1, %arity.loc4_14.1 [symbolic = %pack_type.loc4_47 (constants.%pack_type.8fe)]
// CHECK:STDOUT:   %pattern_type.loc4_47: type = pattern_type %pack_type.loc4_47 [symbolic = %pattern_type.loc4_47 (constants.%pattern_type.550)]
// CHECK:STDOUT:   %x.param_patt.loc4_47.2: @MakeTuple.%pattern_type.loc4_47 (%pattern_type.550) = value_param_pattern [symbolic = %x.param_patt.loc4_47.2 (constants.%x.param_patt.da7)]
// CHECK:STDOUT:   %x.patt.loc4_47.2: @MakeTuple.%pattern_type.loc4_47 (%pattern_type.550) = wrapper_binding_pattern x, %x.param_patt.loc4_47.2 [symbolic = %x.patt.loc4_47.2 (constants.%x.patt.c61)]
// CHECK:STDOUT:   %.loc4_37.2: @MakeTuple.%pattern_type.loc4_47 (%pattern_type.550) = pack_expansion_pattern %x.patt.loc4_47.2, invalid [symbolic = %.loc4_37.2 (constants.%.c31)]
// CHECK:STDOUT:   %tuple.type.loc4_71.1: type = tuple_type (%pack_type.loc4_24) [symbolic = %tuple.type.loc4_71.1 (constants.%tuple.type.7db)]
// CHECK:STDOUT:   %tuple: @MakeTuple.%tuple.type.loc4_71.1 (%tuple.type.7db) = tuple_value (%T.loc4_24.1) [symbolic = %tuple (constants.%tuple.846)]
// CHECK:STDOUT:   %tuple.type.loc4_71.2: type = tuple_type (%pack_type.loc4_47) [symbolic = %tuple.type.loc4_71.2 (constants.%tuple.type.e97)]
// CHECK:STDOUT:   %.loc4_71.1: Core.Form = init_form %tuple.type.loc4_71.2 [symbolic = %.loc4_71.1 (constants.%.4a2)]
// CHECK:STDOUT:   %pattern_type.loc4_71: type = pattern_type %tuple.type.loc4_71.2 [symbolic = %pattern_type.loc4_71 (constants.%pattern_type.605)]
// CHECK:STDOUT:   %return.param_patt.loc4_71.2: @MakeTuple.%pattern_type.loc4_71 (%pattern_type.605) = out_param_pattern [symbolic = %return.param_patt.loc4_71.2 (constants.%return.param_patt.969)]
// CHECK:STDOUT:   %return.patt.loc4_57.2: @MakeTuple.%pattern_type.loc4_71 (%pattern_type.605) = return_slot_pattern %return.param_patt.loc4_71.2, %tuple.type.loc4_71.2 [symbolic = %return.patt.loc4_57.2 (constants.%return.patt.1e6)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_47: <witness> = require_complete_type %pack_type.loc4_47 [symbolic = %require_complete.loc4_47 (constants.%require_complete.660)]
// CHECK:STDOUT:   %require_complete.loc4_57: <witness> = require_complete_type %tuple.type.loc4_71.2 [symbolic = %require_complete.loc4_57 (constants.%require_complete.b74)]
// CHECK:STDOUT:   %require_complete.loc5: <witness> = require_complete_type %as_type.loc4_49.1 [symbolic = %require_complete.loc5 (constants.%require_complete.16c)]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%.loc4_49.2) [symbolic = %Copy.WithSelf.Op.type (constants.%Copy.WithSelf.Op.type.510)]
// CHECK:STDOUT:   %.loc5_21.15: type = fn_type_with_self_type %Copy.WithSelf.Op.type, %.loc4_49.2 [symbolic = %.loc5_21.15 (constants.%.b29)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %.loc4_49.2, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.5fe)]
// CHECK:STDOUT:   %impl.elem0.loc5_21.2: @MakeTuple.%.loc5_21.15 (%.b29) = impl_witness_access %Copy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc5_21.2 (constants.%impl.elem0.4e2)]
// CHECK:STDOUT:   %specific_impl_fn.loc5_21.2: <specific function> = specific_impl_function %impl.elem0.loc5_21.2, @Copy.WithSelf.Op(%.loc4_49.2) [symbolic = %specific_impl_fn.loc5_21.2 (constants.%specific_impl_fn.825)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @MakeTuple.%pack_type.loc4_47 (%pack_type.8fe)) -> out %return.param: @MakeTuple.%tuple.type.loc4_71.2 (%tuple.type.e97) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref: @MakeTuple.%pack_type.loc4_47 (%pack_type.8fe) = name_ref x, %x
// CHECK:STDOUT:     %.loc5_21.1: @MakeTuple.%tuple.type.loc4_71.2 (%tuple.type.e97) = tuple_literal (%x.ref)
// CHECK:STDOUT:     %.loc5_21.2: init @MakeTuple.%tuple.type.loc4_71.2 (%tuple.type.e97) to %return.param = pack_segment_init {
// CHECK:STDOUT:       %.loc5_21.3: Core.IntLiteral = pack_index [symbolic = %.loc4_49.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc5_21.4: Core.IntLiteral = pack_index [symbolic = %.loc4_49.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc5_21.5: %Copy.type = pack_element constants.%T.49b, %.loc5_21.4 [symbolic = %.loc4_49.2 (constants.%.375)]
// CHECK:STDOUT:       %as_type.loc5_21.1: type = facet_access_type %.loc5_21.5 [symbolic = %as_type.loc4_49.1 (constants.%as_type.bf9)]
// CHECK:STDOUT:       %.loc5_21.6: type = converted %.loc5_21.5, %as_type.loc5_21.1 [symbolic = %as_type.loc4_49.1 (constants.%as_type.bf9)]
// CHECK:STDOUT:       %.loc5_21.7: @MakeTuple.%as_type.loc4_49.1 (%as_type.bf9) = pack_element %x.ref, %.loc5_21.3
// CHECK:STDOUT:       %.loc5_21.8: Core.IntLiteral = pack_index [symbolic = %.loc4_49.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc5_21.9: %Copy.type = pack_element constants.%T.49b, %.loc5_21.8 [symbolic = %.loc4_49.2 (constants.%.375)]
// CHECK:STDOUT:       %as_type.loc5_21.2: type = facet_access_type %.loc5_21.9 [symbolic = %as_type.loc4_49.1 (constants.%as_type.bf9)]
// CHECK:STDOUT:       %.loc5_21.10: type = converted %.loc5_21.9, %as_type.loc5_21.2 [symbolic = %as_type.loc4_49.1 (constants.%as_type.bf9)]
// CHECK:STDOUT:       %impl.elem0.loc5_21.1: @MakeTuple.%.loc5_21.15 (%.b29) = impl_witness_access constants.%Copy.lookup_impl_witness.5fe, element0 [symbolic = %impl.elem0.loc5_21.2 (constants.%impl.elem0.4e2)]
// CHECK:STDOUT:       %bound_method.loc5_21.1: <bound method> = bound_method %.loc5_21.7, %impl.elem0.loc5_21.1
// CHECK:STDOUT:       %.loc5_21.11: %Copy.type = converted constants.%as_type.bf9, constants.%.375 [symbolic = %.loc4_49.2 (constants.%.375)]
// CHECK:STDOUT:       %.loc5_21.12: %Copy.type = converted constants.%as_type.bf9, constants.%.375 [symbolic = %.loc4_49.2 (constants.%.375)]
// CHECK:STDOUT:       %specific_impl_fn.loc5_21.1: <specific function> = specific_impl_function %impl.elem0.loc5_21.1, @Copy.WithSelf.Op(constants.%.375) [symbolic = %specific_impl_fn.loc5_21.2 (constants.%specific_impl_fn.825)]
// CHECK:STDOUT:       %bound_method.loc5_21.2: <bound method> = bound_method %.loc5_21.7, %specific_impl_fn.loc5_21.1
// CHECK:STDOUT:       %.loc5_21.13: ref @MakeTuple.%as_type.loc4_49.1 (%as_type.bf9) = pack_element %return.param, %.loc5_21.3
// CHECK:STDOUT:       %Copy.WithSelf.Op.call: init @MakeTuple.%as_type.loc4_49.1 (%as_type.bf9) to %.loc5_21.13 = call %bound_method.loc5_21.2(%.loc5_21.7)
// CHECK:STDOUT:       %.loc5_21.14: init @MakeTuple.%as_type.loc4_49.1 (%as_type.bf9) to %.loc5_21.13 = in_place_init %Copy.WithSelf.Op.call
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc5_22: init @MakeTuple.%tuple.type.loc4_71.2 (%tuple.type.e97) = converted %.loc5_21.1, %.loc5_21.2
// CHECK:STDOUT:     return %.loc5_22 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() -> out %return.param: %tuple.type.f41 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %MakeTuple.ref: %MakeTuple.type = name_ref MakeTuple, file.%MakeTuple.decl [concrete = constants.%MakeTuple]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %i64.loc11: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc11_22.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_22.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call: init %i64 = call %bound_method.loc11_22.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc11_22.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc11_22.2: %i64 = converted %int_1, %.loc11_22.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc11_22.3: %tuple.type.f41 = pack_literal (%.loc11_22.2, %true)
// CHECK:STDOUT:   %int_2.loc11_34.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc11_34.1: %pack_type.8f6 = pack_value (constants.%i64, bool) [concrete = constants.%.abd]
// CHECK:STDOUT:   %int_2.loc11_34.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc11_34.2: %pack_type.8f6 = pack_value (constants.%i64, bool) [concrete = constants.%.abd]
// CHECK:STDOUT:   %Copy.facet.loc11_34.1: %Copy.type = facet_value constants.%i64, (constants.%Copy.impl_witness.8cc) [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %.loc11_34.3: %Copy.type = converted constants.%i64, %Copy.facet.loc11_34.1 [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %Copy.facet.loc11_34.2: %Copy.type = facet_value bool, (constants.%Copy.impl_witness.5e1) [concrete = constants.%Copy.facet.7af]
// CHECK:STDOUT:   %.loc11_34.4: %Copy.type = converted bool, %Copy.facet.loc11_34.2 [concrete = constants.%Copy.facet.7af]
// CHECK:STDOUT:   %.loc11_34.5: %pack_type.8ea = pack_value (%.loc11_34.3, %.loc11_34.4) [concrete = constants.%.ea1]
// CHECK:STDOUT:   %.loc11_34.6: %pack_type.8ea = converted constants.%.abd, %.loc11_34.5 [concrete = constants.%.ea1]
// CHECK:STDOUT:   %MakeTuple.specific_fn: <specific function> = specific_function %MakeTuple.ref, @MakeTuple(constants.%int_2, constants.%.ea1) [concrete = constants.%MakeTuple.specific_fn]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %.loc11_22.4: %pack_type.3d7 = pack_value (%.loc11_22.2, %true) [concrete = constants.%.f38]
// CHECK:STDOUT:   %.loc11_22.5: %pack_type.3d7 = converted %.loc11_22.3, %.loc11_22.4 [concrete = constants.%.f38]
// CHECK:STDOUT:   %MakeTuple.call: init %tuple.type.f41 to %.loc9_24.1 = call %MakeTuple.specific_fn(%.loc11_22.5)
// CHECK:STDOUT:   return %MakeTuple.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @MakeTuple(constants.%arity, constants.%T.49b) {
// CHECK:STDOUT:   %arity.patt.loc4_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_14.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc4_24 => constants.%pack_type.dee
// CHECK:STDOUT:   %pattern_type.loc4_24 => constants.%pattern_type.f66
// CHECK:STDOUT:   %T.patt.loc4_24.2 => constants.%T.patt.fcf
// CHECK:STDOUT:   %T.loc4_24.1 => constants.%T.49b
// CHECK:STDOUT:   %.loc4_14.2 => constants.%.c72
// CHECK:STDOUT:   %.loc4_49.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_49.2 => constants.%.375
// CHECK:STDOUT:   %as_type.loc4_49.1 => constants.%as_type.bf9
// CHECK:STDOUT:   %pack_type.loc4_47 => constants.%pack_type.8fe
// CHECK:STDOUT:   %pattern_type.loc4_47 => constants.%pattern_type.550
// CHECK:STDOUT:   %x.param_patt.loc4_47.2 => constants.%x.param_patt.da7
// CHECK:STDOUT:   %x.patt.loc4_47.2 => constants.%x.patt.c61
// CHECK:STDOUT:   %.loc4_37.2 => constants.%.c31
// CHECK:STDOUT:   %tuple.type.loc4_71.1 => constants.%tuple.type.7db
// CHECK:STDOUT:   %tuple => constants.%tuple.846
// CHECK:STDOUT:   %tuple.type.loc4_71.2 => constants.%tuple.type.e97
// CHECK:STDOUT:   %.loc4_71.1 => constants.%.4a2
// CHECK:STDOUT:   %pattern_type.loc4_71 => constants.%pattern_type.605
// CHECK:STDOUT:   %return.param_patt.loc4_71.2 => constants.%return.param_patt.969
// CHECK:STDOUT:   %return.patt.loc4_57.2 => constants.%return.patt.1e6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @MakeTuple(constants.%int_2, constants.%.ea1) {
// CHECK:STDOUT:   %arity.patt.loc4_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_14.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc4_24 => constants.%pack_type.8ea
// CHECK:STDOUT:   %pattern_type.loc4_24 => constants.%pattern_type.488
// CHECK:STDOUT:   %T.patt.loc4_24.2 => constants.%T.patt.31f
// CHECK:STDOUT:   %T.loc4_24.1 => constants.%.ea1
// CHECK:STDOUT:   %.loc4_14.2 => constants.%.586
// CHECK:STDOUT:   %.loc4_49.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_49.2 => constants.%.405
// CHECK:STDOUT:   %as_type.loc4_49.1 => constants.%as_type.841
// CHECK:STDOUT:   %pack_type.loc4_47 => constants.%pack_type.3d7
// CHECK:STDOUT:   %pattern_type.loc4_47 => constants.%pattern_type.2ee
// CHECK:STDOUT:   %x.param_patt.loc4_47.2 => constants.%x.param_patt.3f5
// CHECK:STDOUT:   %x.patt.loc4_47.2 => constants.%x.patt.765
// CHECK:STDOUT:   %.loc4_37.2 => constants.%.f24
// CHECK:STDOUT:   %tuple.type.loc4_71.1 => constants.%tuple.type.24a
// CHECK:STDOUT:   %tuple => constants.%tuple.20e
// CHECK:STDOUT:   %tuple.type.loc4_71.2 => constants.%tuple.type.f41
// CHECK:STDOUT:   %.loc4_71.1 => constants.%.6fd
// CHECK:STDOUT:   %pattern_type.loc4_71 => constants.%pattern_type.ea0
// CHECK:STDOUT:   %return.param_patt.loc4_71.2 => constants.%return.param_patt.893
// CHECK:STDOUT:   %return.patt.loc4_57.2 => constants.%return.patt.279
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_47 => constants.%complete_type.c16
// CHECK:STDOUT:   %require_complete.loc4_57 => constants.%complete_type.6e7
// CHECK:STDOUT:   %require_complete.loc5 => constants.%require_complete.a57
// CHECK:STDOUT:   %Copy.WithSelf.Op.type => constants.%Copy.WithSelf.Op.type.27b
// CHECK:STDOUT:   %.loc5_21.15 => constants.%.3b8
// CHECK:STDOUT:   %Copy.lookup_impl_witness => constants.%Copy.lookup_impl_witness.471
// CHECK:STDOUT:   %impl.elem0.loc5_21.2 => constants.%impl.elem0.953
// CHECK:STDOUT:   %specific_impl_fn.loc5_21.2 => constants.%specific_impl_fn.c6f
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- let.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %Code.type: type = facet_type <@Code> [concrete]
// CHECK:STDOUT:   %Code.assoc_type: type = assoc_entity_type @Code [concrete]
// CHECK:STDOUT:   %assoc0: %Code.assoc_type = assoc_entity element0, @Code.WithSelf.%Code.WithSelf.Get.decl [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.104: type = pack_type %Code.type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.2ee: type = pattern_type %pack_type.104 [symbolic]
// CHECK:STDOUT:   %T.patt: %pattern_type.2ee = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.104 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.cc3: %pattern_type.2ee = pack_expansion_pattern %T.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.3c6: %Code.type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.85b: type = tuple_type (%pack_type.104) [symbolic]
// CHECK:STDOUT:   %tuple: %tuple.type.85b = tuple_value (%T) [symbolic]
// CHECK:STDOUT:   %pack_type.6c6: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.950: type = tuple_type (%pack_type.6c6) [symbolic]
// CHECK:STDOUT:   %pattern_type.26d: type = pattern_type %tuple.type.950 [symbolic]
// CHECK:STDOUT:   %t.param_patt: %pattern_type.26d = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt: %pattern_type.26d = wrapper_binding_pattern t, %t.param_patt [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.254: <witness> = require_complete_type %tuple.type.950 [symbolic]
// CHECK:STDOUT:   %as_type: type = facet_access_type %.3c6 [symbolic]
// CHECK:STDOUT:   %require_complete.aa7: <witness> = require_complete_type %pack_type.6c6 [symbolic]
// CHECK:STDOUT:   %pattern_type.2b9: type = pattern_type %pack_type.6c6 [symbolic]
// CHECK:STDOUT:   %x.patt.572: %pattern_type.2b9 = value_binding_pattern x [symbolic]
// CHECK:STDOUT:   %.20c: %pattern_type.2b9 = pack_expansion_pattern %x.patt.572, invalid [symbolic]
// CHECK:STDOUT:   %.b39: %pattern_type.26d = tuple_pattern (%.20c) [symbolic]
// CHECK:STDOUT:   %require_complete.d18: <witness> = require_complete_type %as_type [symbolic]
// CHECK:STDOUT:   %Code.WithSelf.Get.type.099: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.3c6) [symbolic]
// CHECK:STDOUT:   %Code.lookup_impl_witness: <witness> = lookup_impl_witness %.3c6, @Code [symbolic]
// CHECK:STDOUT:   %.131: type = fn_type_with_self_type %Code.WithSelf.Get.type.099, %.3c6 [symbolic]
// CHECK:STDOUT:   %impl.elem0: %.131 = impl_witness_access %Code.lookup_impl_witness, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn: <specific function> = specific_impl_function %impl.elem0, @Code.WithSelf.Get(%.3c6) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ForEach.decl: %ForEach.type = fn_decl @ForEach [concrete = constants.%ForEach] {
// CHECK:STDOUT:     %arity.patt.loc10_12.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc10_22.1: @ForEach.%pattern_type.loc10_22 (%pattern_type.2ee) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc10_22.2 (constants.%T.patt)]
// CHECK:STDOUT:     %.loc10_12.1: @ForEach.%pattern_type.loc10_22 (%pattern_type.2ee) = pack_expansion_pattern %T.patt.loc10_22.1, %arity.patt.loc10_12.1 [symbolic = %.loc10_12.2 (constants.%.cc3)]
// CHECK:STDOUT:     %t.param_patt.loc10_31.1: @ForEach.%pattern_type.loc10_31 (%pattern_type.26d) = value_param_pattern [symbolic = %t.param_patt.loc10_31.2 (constants.%t.param_patt)]
// CHECK:STDOUT:     %t.patt.loc10_31.1: @ForEach.%pattern_type.loc10_31 (%pattern_type.26d) = wrapper_binding_pattern t, %t.param_patt.loc10_31.1 [symbolic = %t.patt.loc10_31.2 (constants.%t.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc10_12.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc10_24: type = splice_block %Code.ref [concrete = constants.%Code.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Code.ref: type = name_ref Code, file.%Code.decl [concrete = constants.%Code.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_22.2: @ForEach.%pack_type.loc10_22 (%pack_type.104) = symbolic_binding T, 1 [symbolic = %T.loc10_22.1 (constants.%T)]
// CHECK:STDOUT:     %t.param: @ForEach.%tuple.type.loc10_44.2 (%tuple.type.950) = value_param call_param0
// CHECK:STDOUT:     %.loc10_44.1: type = splice_block %.loc10_44.3 [symbolic = %tuple.type.loc10_44.2 (constants.%tuple.type.950)] {
// CHECK:STDOUT:       %.loc10_44.2: @ForEach.%tuple.type.loc10_44.1 (%tuple.type.85b) = tuple_literal (constants.%T) [symbolic = %tuple (constants.%tuple)]
// CHECK:STDOUT:       %.loc10_44.3: type = converted %.loc10_44.2, constants.%tuple.type.950 [symbolic = %tuple.type.loc10_44.2 (constants.%tuple.type.950)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: @ForEach.%tuple.type.loc10_44.2 (%tuple.type.950) = wrapper_binding t, %t.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ForEach(%arity.loc10_12.2: Core.IntLiteral, %T.loc10_22.2: @ForEach.%pack_type.loc10_22 (%pack_type.104)) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc10_12.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc10_22: type = pack_type constants.%Code.type, %arity.loc10_12.1 [symbolic = %pack_type.loc10_22 (constants.%pack_type.104)]
// CHECK:STDOUT:   %pattern_type.loc10_22: type = pattern_type %pack_type.loc10_22 [symbolic = %pattern_type.loc10_22 (constants.%pattern_type.2ee)]
// CHECK:STDOUT:   %T.patt.loc10_22.2: @ForEach.%pattern_type.loc10_22 (%pattern_type.2ee) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc10_22.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc10_22.1: @ForEach.%pack_type.loc10_22 (%pack_type.104) = symbolic_binding T, 1 [symbolic = %T.loc10_22.1 (constants.%T)]
// CHECK:STDOUT:   %.loc10_12.2: @ForEach.%pattern_type.loc10_22 (%pattern_type.2ee) = pack_expansion_pattern %T.patt.loc10_22.2, %arity.patt.loc10_12.2 [symbolic = %.loc10_12.2 (constants.%.cc3)]
// CHECK:STDOUT:   %.loc10_38.1: Core.IntLiteral = pack_index [symbolic = %.loc10_38.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc10_38.2: %Code.type = pack_element %T.loc10_22.1, %.loc10_38.1 [symbolic = %.loc10_38.2 (constants.%.3c6)]
// CHECK:STDOUT:   %tuple.type.loc10_44.1: type = tuple_type (%pack_type.loc10_22) [symbolic = %tuple.type.loc10_44.1 (constants.%tuple.type.85b)]
// CHECK:STDOUT:   %tuple: @ForEach.%tuple.type.loc10_44.1 (%tuple.type.85b) = tuple_value (%T.loc10_22.1) [symbolic = %tuple (constants.%tuple)]
// CHECK:STDOUT:   %pack_type.loc10_44: type = pack_type %T.loc10_22.1, %arity.loc10_12.1 [symbolic = %pack_type.loc10_44 (constants.%pack_type.6c6)]
// CHECK:STDOUT:   %tuple.type.loc10_44.2: type = tuple_type (%pack_type.loc10_44) [symbolic = %tuple.type.loc10_44.2 (constants.%tuple.type.950)]
// CHECK:STDOUT:   %pattern_type.loc10_31: type = pattern_type %tuple.type.loc10_44.2 [symbolic = %pattern_type.loc10_31 (constants.%pattern_type.26d)]
// CHECK:STDOUT:   %t.param_patt.loc10_31.2: @ForEach.%pattern_type.loc10_31 (%pattern_type.26d) = value_param_pattern [symbolic = %t.param_patt.loc10_31.2 (constants.%t.param_patt)]
// CHECK:STDOUT:   %t.patt.loc10_31.2: @ForEach.%pattern_type.loc10_31 (%pattern_type.26d) = wrapper_binding_pattern t, %t.param_patt.loc10_31.2 [symbolic = %t.patt.loc10_31.2 (constants.%t.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %tuple.type.loc10_44.2 [symbolic = %require_complete.loc10 (constants.%require_complete.254)]
// CHECK:STDOUT:   %as_type.loc11_20.2: type = facet_access_type %.loc10_38.2 [symbolic = %as_type.loc11_20.2 (constants.%as_type)]
// CHECK:STDOUT:   %require_complete.loc11: <witness> = require_complete_type %pack_type.loc10_44 [symbolic = %require_complete.loc11 (constants.%require_complete.aa7)]
// CHECK:STDOUT:   %pattern_type.loc11: type = pattern_type %pack_type.loc10_44 [symbolic = %pattern_type.loc11 (constants.%pattern_type.2b9)]
// CHECK:STDOUT:   %x.patt.loc11_18.2: @ForEach.%pattern_type.loc11 (%pattern_type.2b9) = value_binding_pattern x [symbolic = %x.patt.loc11_18.2 (constants.%x.patt.572)]
// CHECK:STDOUT:   %.loc11_8.9: @ForEach.%pattern_type.loc11 (%pattern_type.2b9) = pack_expansion_pattern %x.patt.loc11_18.2, invalid [symbolic = %.loc11_8.9 (constants.%.20c)]
// CHECK:STDOUT:   %.loc11_8.10: @ForEach.%pattern_type.loc10_31 (%pattern_type.26d) = tuple_pattern (%.loc11_8.9) [symbolic = %.loc11_8.10 (constants.%.b39)]
// CHECK:STDOUT:   %require_complete.loc12: <witness> = require_complete_type %as_type.loc11_20.2 [symbolic = %require_complete.loc12 (constants.%require_complete.d18)]
// CHECK:STDOUT:   %Code.WithSelf.Get.type: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.loc10_38.2) [symbolic = %Code.WithSelf.Get.type (constants.%Code.WithSelf.Get.type.099)]
// CHECK:STDOUT:   %.loc12_21: type = fn_type_with_self_type %Code.WithSelf.Get.type, %.loc10_38.2 [symbolic = %.loc12_21 (constants.%.131)]
// CHECK:STDOUT:   %Code.lookup_impl_witness: <witness> = lookup_impl_witness %.loc10_38.2, @Code [symbolic = %Code.lookup_impl_witness (constants.%Code.lookup_impl_witness)]
// CHECK:STDOUT:   %impl.elem0.loc12_21.2: @ForEach.%.loc12_21 (%.131) = impl_witness_access %Code.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc12_21.2 (constants.%impl.elem0)]
// CHECK:STDOUT:   %specific_impl_fn.loc12_21.2: <specific function> = specific_impl_function %impl.elem0.loc12_21.2, @Code.WithSelf.Get(%.loc10_38.2) [symbolic = %specific_impl_fn.loc12_21.2 (constants.%specific_impl_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @ForEach.%tuple.type.loc10_44.2 (%tuple.type.950)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %t.ref: @ForEach.%tuple.type.loc10_44.2 (%tuple.type.950) = name_ref t, %t
// CHECK:STDOUT:     %.loc11_8.1: @ForEach.%pack_type.loc10_44 (%pack_type.6c6) = pack_expansion_expr %.loc11_8.8 {
// CHECK:STDOUT:       %.loc11_8.4: Core.IntLiteral = pack_index [symbolic = %.loc10_38.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc11_8.5: Core.IntLiteral = pack_index [symbolic = %.loc10_38.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc11_8.6: %Code.type = pack_element constants.%T, %.loc11_8.5 [symbolic = %.loc10_38.2 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc11_8: type = facet_access_type %.loc11_8.6 [symbolic = %as_type.loc11_20.2 (constants.%as_type)]
// CHECK:STDOUT:       %.loc11_8.7: type = converted %.loc11_8.6, %as_type.loc11_8 [symbolic = %as_type.loc11_20.2 (constants.%as_type)]
// CHECK:STDOUT:       %.loc11_8.8: @ForEach.%as_type.loc11_20.2 (%as_type) = pack_element %t.ref, %.loc11_8.4
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc11_20.1: type = splice_block %.loc11_20.4 [symbolic = %as_type.loc11_20.2 (constants.%as_type)] {
// CHECK:STDOUT:       %T.ref: @ForEach.%pack_type.loc10_22 (%pack_type.104) = name_ref T, %T.loc10_22.2 [symbolic = %T.loc10_22.1 (constants.%T)]
// CHECK:STDOUT:       %.loc11_20.2: Core.IntLiteral = pack_index [symbolic = %.loc10_38.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc11_20.3: %Code.type = pack_element %T.ref, %.loc11_20.2 [symbolic = %.loc10_38.2 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc11_20.1: type = facet_access_type %.loc11_20.3 [symbolic = %as_type.loc11_20.2 (constants.%as_type)]
// CHECK:STDOUT:       %.loc11_20.4: type = converted %.loc11_20.3, %as_type.loc11_20.1 [symbolic = %as_type.loc11_20.2 (constants.%as_type)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @ForEach.%pack_type.loc10_44 (%pack_type.6c6) = wrapper_binding x, %.loc11_8.1
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %x.patt.loc11_18.1: @ForEach.%pattern_type.loc11 (%pattern_type.2b9) = value_binding_pattern x [symbolic = %x.patt.loc11_18.2 (constants.%x.patt.572)]
// CHECK:STDOUT:       %.loc11_8.2: @ForEach.%pattern_type.loc11 (%pattern_type.2b9) = pack_expansion_pattern %x.patt.loc11_18.1, invalid [symbolic = %.loc11_8.9 (constants.%.20c)]
// CHECK:STDOUT:       %.loc11_8.3: @ForEach.%pattern_type.loc10_31 (%pattern_type.26d) = tuple_pattern (%.loc11_8.2) [symbolic = %.loc11_8.10 (constants.%.b39)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     pack_expansion_statement %arity.loc10_12.2 {
// CHECK:STDOUT:       %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %x.ref: @ForEach.%pack_type.loc10_44 (%pack_type.6c6) = name_ref x, %x
// CHECK:STDOUT:       %.loc12_15.1: Core.IntLiteral = pack_index [symbolic = %.loc10_38.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc12_15.2: Core.IntLiteral = pack_index [symbolic = %.loc10_38.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc12_15.3: %Code.type = pack_element constants.%T, %.loc12_15.2 [symbolic = %.loc10_38.2 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc12: type = facet_access_type %.loc12_15.3 [symbolic = %as_type.loc11_20.2 (constants.%as_type)]
// CHECK:STDOUT:       %.loc12_15.4: type = converted %.loc12_15.3, %as_type.loc12 [symbolic = %as_type.loc11_20.2 (constants.%as_type)]
// CHECK:STDOUT:       %.loc12_15.5: @ForEach.%as_type.loc11_20.2 (%as_type) = pack_element %x.ref, %.loc12_15.1
// CHECK:STDOUT:       %Get.ref: %Code.assoc_type = name_ref Get, @Code.WithSelf.%assoc0 [concrete = constants.%assoc0]
// CHECK:STDOUT:       %impl.elem0.loc12_21.1: @ForEach.%.loc12_21 (%.131) = impl_witness_access constants.%Code.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc12_21.2 (constants.%impl.elem0)]
// CHECK:STDOUT:       %bound_method.loc12_21: <bound method> = bound_method %.loc12_15.5, %impl.elem0.loc12_21.1
// CHECK:STDOUT:       %.loc12_26.1: %Code.type = converted constants.%as_type, constants.%.3c6 [symbolic = %.loc10_38.2 (constants.%.3c6)]
// CHECK:STDOUT:       %.loc12_26.2: %Code.type = converted constants.%as_type, constants.%.3c6 [symbolic = %.loc10_38.2 (constants.%.3c6)]
// CHECK:STDOUT:       %specific_impl_fn.loc12_21.1: <specific function> = specific_impl_function %impl.elem0.loc12_21.1, @Code.WithSelf.Get(constants.%.3c6) [symbolic = %specific_impl_fn.loc12_21.2 (constants.%specific_impl_fn)]
// CHECK:STDOUT:       %bound_method.loc12_26: <bound method> = bound_method %.loc12_15.5, %specific_impl_fn.loc12_21.1
// CHECK:STDOUT:       %Code.WithSelf.Get.call: init %i64 = call %bound_method.loc12_26(%.loc12_15.5)
// CHECK:STDOUT:       %.loc12_26.3: %i64 = value_of_initializer %Code.WithSelf.Get.call
// CHECK:STDOUT:       %.loc12_26.4: %i64 = converted %Code.WithSelf.Get.call, %.loc12_26.3
// CHECK:STDOUT:       %Consume.call: init %empty_tuple.type = call %Consume.ref(%.loc12_26.4)
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_12.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc10_22 => constants.%pack_type.104
// CHECK:STDOUT:   %pattern_type.loc10_22 => constants.%pattern_type.2ee
// CHECK:STDOUT:   %T.patt.loc10_22.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc10_22.1 => constants.%T
// CHECK:STDOUT:   %.loc10_12.2 => constants.%.cc3
// CHECK:STDOUT:   %.loc10_38.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc10_38.2 => constants.%.3c6
// CHECK:STDOUT:   %tuple.type.loc10_44.1 => constants.%tuple.type.85b
// CHECK:STDOUT:   %tuple => constants.%tuple
// CHECK:STDOUT:   %pack_type.loc10_44 => constants.%pack_type.6c6
// CHECK:STDOUT:   %tuple.type.loc10_44.2 => constants.%tuple.type.950
// CHECK:STDOUT:   %pattern_type.loc10_31 => constants.%pattern_type.26d
// CHECK:STDOUT:   %t.param_patt.loc10_31.2 => constants.%t.param_patt
// CHECK:STDOUT:   %t.patt.loc10_31.2 => constants.%t.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- tuple_value.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.fc0: type = pattern_type %pack_type.c29 [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %Take.type: type = fn_type @Take [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Take: %Take.type = struct_value () [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.fc0 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.99e70e.2: %pattern_type.fc0 = pack_expansion_pattern %T.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %.425d33.2: type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.8fbe7d.2: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.9a6: type = pattern_type %pack_type.8fbe7d.2 [symbolic]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.9a6 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt: %pattern_type.9a6 = wrapper_binding_pattern x, %x.param_patt [symbolic]
// CHECK:STDOUT:   %.94c: %pattern_type.9a6 = pack_expansion_pattern %x.patt, invalid [symbolic]
// CHECK:STDOUT:   %Pass.type: type = fn_type @Pass [concrete]
// CHECK:STDOUT:   %Pass: %Pass.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.fc6: <witness> = require_complete_type %pack_type.8fbe7d.2 [symbolic]
// CHECK:STDOUT:   %tuple.type.4239cb.2: type = tuple_type (%pack_type.8fbe7d.2) [symbolic]
// CHECK:STDOUT:   %Take.specific_fn: <specific function> = specific_function %Take, @Take(%arity, %T) [symbolic]
// CHECK:STDOUT:   %require_complete.f6f58d.2: <witness> = require_complete_type %tuple.type.4239cb.2 [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Pass.decl: %Pass.type = fn_decl @Pass [concrete = constants.%Pass] {
// CHECK:STDOUT:     %arity.patt.loc6_9.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_9.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc6_19.1: @Pass.%pattern_type.loc6_19 (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc6_19.2 (constants.%T.patt)]
// CHECK:STDOUT:     %.loc6_9.1: @Pass.%pattern_type.loc6_19 (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc6_19.1, %arity.patt.loc6_9.1 [symbolic = %.loc6_9.2 (constants.%.99e70e.2)]
// CHECK:STDOUT:     %x.param_patt.loc6_37.1: @Pass.%pattern_type.loc6_37 (%pattern_type.9a6) = value_param_pattern [symbolic = %x.param_patt.loc6_37.2 (constants.%x.param_patt)]
// CHECK:STDOUT:     %x.patt.loc6_37.1: @Pass.%pattern_type.loc6_37 (%pattern_type.9a6) = wrapper_binding_pattern x, %x.param_patt.loc6_37.1 [symbolic = %x.patt.loc6_37.2 (constants.%x.patt)]
// CHECK:STDOUT:     %.loc6_27.1: @Pass.%pattern_type.loc6_37 (%pattern_type.9a6) = pack_expansion_pattern %x.patt.loc6_37.1, invalid [symbolic = %.loc6_27.2 (constants.%.94c)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc6_9.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_9.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc6_21.1: type = splice_block %.loc6_21.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc6_21.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc6_19.2: @Pass.%pack_type.loc6_19 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc6_19.1 (constants.%T)]
// CHECK:STDOUT:     %x.param: @Pass.%pack_type.loc6_37 (%pack_type.8fbe7d.2) = value_param call_param0
// CHECK:STDOUT:     %.loc6_39.3: type = splice_block %.loc6_39.5 [symbolic = %.loc6_39.2 (constants.%.425d33.2)] {
// CHECK:STDOUT:       %T.ref: @Pass.%pack_type.loc6_19 (%pack_type.c29) = name_ref T, %T.loc6_19.2 [symbolic = %T.loc6_19.1 (constants.%T)]
// CHECK:STDOUT:       %.loc6_39.4: Core.IntLiteral = pack_index [symbolic = %.loc6_39.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc6_39.5: type = pack_element %T.ref, %.loc6_39.4 [symbolic = %.loc6_39.2 (constants.%.425d33.2)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @Pass.%pack_type.loc6_37 (%pack_type.8fbe7d.2) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Pass(%arity.loc6_9.2: Core.IntLiteral, %T.loc6_19.2: @Pass.%pack_type.loc6_19 (%pack_type.c29)) {
// CHECK:STDOUT:   %arity.patt.loc6_9.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_9.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc6_9.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_9.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc6_19: type = pack_type type, %arity.loc6_9.1 [symbolic = %pack_type.loc6_19 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %pattern_type.loc6_19: type = pattern_type %pack_type.loc6_19 [symbolic = %pattern_type.loc6_19 (constants.%pattern_type.fc0)]
// CHECK:STDOUT:   %T.patt.loc6_19.2: @Pass.%pattern_type.loc6_19 (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc6_19.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc6_19.1: @Pass.%pack_type.loc6_19 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc6_19.1 (constants.%T)]
// CHECK:STDOUT:   %.loc6_9.2: @Pass.%pattern_type.loc6_19 (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc6_19.2, %arity.patt.loc6_9.2 [symbolic = %.loc6_9.2 (constants.%.99e70e.2)]
// CHECK:STDOUT:   %.loc6_39.1: Core.IntLiteral = pack_index [symbolic = %.loc6_39.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc6_39.2: type = pack_element %T.loc6_19.1, %.loc6_39.1 [symbolic = %.loc6_39.2 (constants.%.425d33.2)]
// CHECK:STDOUT:   %pack_type.loc6_37: type = pack_type %T.loc6_19.1, %arity.loc6_9.1 [symbolic = %pack_type.loc6_37 (constants.%pack_type.8fbe7d.2)]
// CHECK:STDOUT:   %pattern_type.loc6_37: type = pattern_type %pack_type.loc6_37 [symbolic = %pattern_type.loc6_37 (constants.%pattern_type.9a6)]
// CHECK:STDOUT:   %x.param_patt.loc6_37.2: @Pass.%pattern_type.loc6_37 (%pattern_type.9a6) = value_param_pattern [symbolic = %x.param_patt.loc6_37.2 (constants.%x.param_patt)]
// CHECK:STDOUT:   %x.patt.loc6_37.2: @Pass.%pattern_type.loc6_37 (%pattern_type.9a6) = wrapper_binding_pattern x, %x.param_patt.loc6_37.2 [symbolic = %x.patt.loc6_37.2 (constants.%x.patt)]
// CHECK:STDOUT:   %.loc6_27.2: @Pass.%pattern_type.loc6_37 (%pattern_type.9a6) = pack_expansion_pattern %x.patt.loc6_37.2, invalid [symbolic = %.loc6_27.2 (constants.%.94c)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc6: <witness> = require_complete_type %pack_type.loc6_37 [symbolic = %require_complete.loc6 (constants.%require_complete.fc6)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%pack_type.loc6_37) [symbolic = %tuple.type (constants.%tuple.type.4239cb.2)]
// CHECK:STDOUT:   %Take.specific_fn.loc7_3.2: <specific function> = specific_function constants.%Take, @Take(%arity.loc6_9.1, %T.loc6_19.1) [symbolic = %Take.specific_fn.loc7_3.2 (constants.%Take.specific_fn)]
// CHECK:STDOUT:   %require_complete.loc7: <witness> = require_complete_type %tuple.type [symbolic = %require_complete.loc7 (constants.%require_complete.f6f58d.2)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @Pass.%pack_type.loc6_37 (%pack_type.8fbe7d.2)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Take.ref: %Take.type = name_ref Take, file.%Take.decl [concrete = constants.%Take]
// CHECK:STDOUT:     %x.ref: @Pass.%pack_type.loc6_37 (%pack_type.8fbe7d.2) = name_ref x, %x
// CHECK:STDOUT:     %.loc7_19.1: @Pass.%tuple.type (%tuple.type.4239cb.2) = tuple_literal (%x.ref)
// CHECK:STDOUT:     %Take.specific_fn.loc7_3.1: <specific function> = specific_function %Take.ref, @Take(constants.%arity, constants.%T) [symbolic = %Take.specific_fn.loc7_3.2 (constants.%Take.specific_fn)]
// CHECK:STDOUT:     %tuple: @Pass.%tuple.type (%tuple.type.4239cb.2) = tuple_value (%x.ref)
// CHECK:STDOUT:     %.loc7_19.2: @Pass.%tuple.type (%tuple.type.4239cb.2) = converted %.loc7_19.1, %tuple
// CHECK:STDOUT:     %Take.call: init %empty_tuple.type = call %Take.specific_fn.loc7_3.1(%.loc7_19.2)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Pass(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity.patt.loc6_9.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_9.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc6_19 => constants.%pack_type.c29
// CHECK:STDOUT:   %pattern_type.loc6_19 => constants.%pattern_type.fc0
// CHECK:STDOUT:   %T.patt.loc6_19.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc6_19.1 => constants.%T
// CHECK:STDOUT:   %.loc6_9.2 => constants.%.99e70e.2
// CHECK:STDOUT:   %.loc6_39.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc6_39.2 => constants.%.425d33.2
// CHECK:STDOUT:   %pack_type.loc6_37 => constants.%pack_type.8fbe7d.2
// CHECK:STDOUT:   %pattern_type.loc6_37 => constants.%pattern_type.9a6
// CHECK:STDOUT:   %x.param_patt.loc6_37.2 => constants.%x.param_patt
// CHECK:STDOUT:   %x.patt.loc6_37.2 => constants.%x.patt
// CHECK:STDOUT:   %.loc6_27.2 => constants.%.94c
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- elements_around_segment.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %As.type.998: type = facet_type <@As, @As(%i64)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.c5d: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.6ee: %Core.IntLiteral.as.As.impl.Convert.type.c5d = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.0fe: <witness> = impl_witness imports.%As.impl_witness_table.d22, @Core.IntLiteral.as.As.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.1a1: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.3d9: %Core.IntLiteral.as.As.impl.Convert.type.1a1 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet.bd1: %As.type.998 = facet_value Core.IntLiteral, (%As.impl_witness.0fe) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.7f7: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i64, %As.facet.bd1) [concrete]
// CHECK:STDOUT:   %.8fd: type = fn_type_with_self_type %As.WithSelf.Convert.type.7f7, %As.facet.bd1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound.ab2: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.3d9 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn.200: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.3d9, @Core.IntLiteral.as.As.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.991: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.specific_fn.200 [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %As.type.155: type = facet_type <@As, @As(%i32)> [concrete]
// CHECK:STDOUT:   %As.impl_witness.e7f: <witness> = impl_witness imports.%As.impl_witness_table.d22, @Core.IntLiteral.as.As.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.e79: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.8a4: %Core.IntLiteral.as.As.impl.Convert.type.e79 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet.bda: %As.type.155 = facet_value Core.IntLiteral, (%As.impl_witness.e7f) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.d02: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i32, %As.facet.bda) [concrete]
// CHECK:STDOUT:   %.453: type = fn_type_with_self_type %As.WithSelf.Convert.type.d02, %As.facet.bda [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound.343: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.As.impl.Convert.8a4 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn.923: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.8a4, @Core.IntLiteral.as.As.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.721: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.As.impl.Convert.specific_fn.923 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %tuple.type.111: type = tuple_type (%i64, %i32, bool, bool) [concrete]
// CHECK:STDOUT:   %tuple.9d0: %tuple.type.111 = tuple_value (%int_1.d98, %int_2.295, %false, %true) [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2.ecc [concrete]
// CHECK:STDOUT:   %.89b: %pack_type.8f6 = pack_value (%i32, bool) [concrete]
// CHECK:STDOUT:   %F.specific_fn.0d2: <specific function> = specific_function %F, @F(%int_2.ecc, %.89b) [concrete]
// CHECK:STDOUT:   %tuple.type.f41: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.f52: %tuple.type.f41 = tuple_value (%int_1.d98, %true) [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %pack_type.28d: type = pack_type type, %int_0 [concrete]
// CHECK:STDOUT:   %.d3f: %pack_type.28d = pack_value () [concrete]
// CHECK:STDOUT:   %F.specific_fn.fba: <specific function> = specific_function %F, @F(%int_0, %.d3f) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref.loc7: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %int_1.loc7: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %i64.loc7: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0.loc7_8: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc7_8.1: <bound method> = bound_method %int_1.loc7, %impl.elem0.loc7_8 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.ab2]
// CHECK:STDOUT:   %specific_fn.loc7_8: <specific function> = specific_function %impl.elem0.loc7_8, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn.200]
// CHECK:STDOUT:   %bound_method.loc7_8.2: <bound method> = bound_method %int_1.loc7, %specific_fn.loc7_8 [concrete = constants.%bound_method.991]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc7_8: init %i64 = call %bound_method.loc7_8.2(%int_1.loc7) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc7_8.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc7_8 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc7_8.2: %i64 = converted %int_1.loc7, %.loc7_8.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %int_2.loc7_16: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %impl.elem0.loc7_18: %.453 = impl_witness_access constants.%As.impl_witness.e7f, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.8a4]
// CHECK:STDOUT:   %bound_method.loc7_18.1: <bound method> = bound_method %int_2.loc7_16, %impl.elem0.loc7_18 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.343]
// CHECK:STDOUT:   %specific_fn.loc7_18: <specific function> = specific_function %impl.elem0.loc7_18, @Core.IntLiteral.as.As.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn.923]
// CHECK:STDOUT:   %bound_method.loc7_18.2: <bound method> = bound_method %int_2.loc7_16, %specific_fn.loc7_18 [concrete = constants.%bound_method.721]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc7_18: init %i32 = call %bound_method.loc7_18.2(%int_2.loc7_16) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc7_18.1: %i32 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc7_18 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc7_18.2: %i32 = converted %int_2.loc7_16, %.loc7_18.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %true.loc7: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc7_37.1: %tuple.type.111 = tuple_literal (%.loc7_8.2, %.loc7_18.2, %false, %true.loc7) [concrete = constants.%tuple.9d0]
// CHECK:STDOUT:   %int_2.loc7_38.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc7_38.1: %pack_type.8f6 = pack_value (constants.%i32, bool) [concrete = constants.%.89b]
// CHECK:STDOUT:   %int_2.loc7_38.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc7_38.2: %pack_type.8f6 = pack_value (constants.%i32, bool) [concrete = constants.%.89b]
// CHECK:STDOUT:   %F.specific_fn.loc7: <specific function> = specific_function %F.ref.loc7, @F(constants.%int_2.ecc, constants.%.89b) [concrete = constants.%F.specific_fn.0d2]
// CHECK:STDOUT:   %tuple.loc7: %tuple.type.111 = tuple_value (%.loc7_8.2, %.loc7_18.2, %false, %true.loc7) [concrete = constants.%tuple.9d0]
// CHECK:STDOUT:   %.loc7_37.2: %tuple.type.111 = converted %.loc7_37.1, %tuple.loc7 [concrete = constants.%tuple.9d0]
// CHECK:STDOUT:   %F.call.loc7: init %empty_tuple.type = call %F.specific_fn.loc7(%.loc7_37.2)
// CHECK:STDOUT:   %F.ref.loc8: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %int_1.loc8: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %i64.loc8: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0.loc8: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc8_8.1: <bound method> = bound_method %int_1.loc8, %impl.elem0.loc8 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.ab2]
// CHECK:STDOUT:   %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn.200]
// CHECK:STDOUT:   %bound_method.loc8_8.2: <bound method> = bound_method %int_1.loc8, %specific_fn.loc8 [concrete = constants.%bound_method.991]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc8: init %i64 = call %bound_method.loc8_8.2(%int_1.loc8) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc8_8.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc8 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc8_8.2: %i64 = converted %int_1.loc8, %.loc8_8.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %true.loc8: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc8_20.1: %tuple.type.f41 = tuple_literal (%.loc8_8.2, %true.loc8) [concrete = constants.%tuple.f52]
// CHECK:STDOUT:   %int_0.loc8_21.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc8_21.1: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %int_0.loc8_21.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc8_21.2: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %F.specific_fn.loc8: <specific function> = specific_function %F.ref.loc8, @F(constants.%int_0, constants.%.d3f) [concrete = constants.%F.specific_fn.fba]
// CHECK:STDOUT:   %tuple.loc8: %tuple.type.f41 = tuple_value (%.loc8_8.2, %true.loc8) [concrete = constants.%tuple.f52]
// CHECK:STDOUT:   %.loc8_20.2: %tuple.type.f41 = converted %.loc8_20.1, %tuple.loc8 [concrete = constants.%tuple.f52]
// CHECK:STDOUT:   %F.call.loc8: init %empty_tuple.type = call %F.specific_fn.loc8(%.loc8_20.2)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
