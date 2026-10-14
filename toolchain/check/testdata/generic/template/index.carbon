// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/index.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/index.carbon

// --- tuple_index_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Second[template T: type](p: T) -> i32 {
  return p.1;
}
//@dump-sem-ir-end

fn Use(t: (i32, i32)) -> i32 {
  return Second(t);
}

// --- array_index_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn At1[template T: type](a: T) -> i32 {
  return a[1];
}
//@dump-sem-ir-end

fn Use(a: array(i32, 3)) -> i32 {
  return At1(a);
}

// --- class_member_array_index.carbon
library "[[@TEST_NAME]]";

class Holder(template T: type) {
  var item: T;
  fn First(self) -> i32 { return self.item[0]; }
}

fn Use(h: Holder(array(i32, 2))) -> i32 {
  return h.First();
}

// --- fail_tuple_index_non_tuple_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn Use(n: i32) -> i32 {
  // CHECK:STDERR: fail_tuple_index_non_tuple_on_instantiation.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `Second(i32)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Second(n);
  // CHECK:STDERR:          ^~~~~~
  // CHECK:STDERR: fail_tuple_index_non_tuple_on_instantiation.carbon:[[@LINE-7]]:10: note: type `i32` does not support tuple indexing; only tuples can be indexed that way [TupleIndexOnANonTupleType]
  // CHECK:STDERR:   return p.1;
  // CHECK:STDERR:          ^~~
  // CHECK:STDERR:
  return Second(n);
}

// --- fail_index_non_indexable_on_instantiation.carbon
library "[[@TEST_NAME]]";

class Empty {}

fn At1[template T: type](a: T) -> i32 {
  return a[1];
}

fn Use(e: Empty) -> i32 {
  // CHECK:STDERR: fail_index_non_indexable_on_instantiation.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `At1(Empty)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return At1(e);
  // CHECK:STDERR:          ^~~
  // CHECK:STDERR: fail_index_non_indexable_on_instantiation.carbon:[[@LINE-7]]:10: note: cannot access member of interface `Core.IndexWith(Core.IntLiteral)` in type `Empty` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   return a[1];
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  return At1(e);
}

// CHECK:STDOUT: --- tuple_index_param.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %p.param_patt.e58: %pattern_type.51d = value_param_pattern [template]
// CHECK:STDOUT:   %p.patt.0ba: %pattern_type.51d = wrapper_binding_pattern p, %p.param_patt.e58 [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Second.type: type = fn_type @Second [concrete]
// CHECK:STDOUT:   %Second: %Second.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %.a9b: type = type_of_inst @Second.%.loc5_11.3 [template]
// CHECK:STDOUT:   %.f4b: %.a9b = splice_inst @Second.%.loc5_11.3 [template]
// CHECK:STDOUT:   %.28a: %i32 = splice_inst @Second.%.loc5_13.2 [template]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %p.param_patt.e62: %pattern_type.394 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.07f: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt.e62 [concrete]
// CHECK:STDOUT:   %complete_type.6c4: <witness> = complete_type_witness %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.46d: %i32 = splice_block %tuple.elem1 {
// CHECK:STDOUT:       %.b62: %tuple.type.e55 = specific_inst @Second.%p.ref, @Second(%tuple.type.e55)
// CHECK:STDOUT:       %tuple.elem1: %i32 = tuple_access %.b62, element1
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.41e: init %i32 = splice_block %Int.as.Copy.impl.Op.call {
// CHECK:STDOUT:       %impl.elem0.882: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.bf1: <bound method> = bound_method %.46d, %impl.elem0.882
// CHECK:STDOUT:       %specific_fn: <specific function> = specific_function %impl.elem0.882, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.8c3: <bound method> = bound_method %.46d, %specific_fn
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.8c3(%.46d)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Second.decl: %Second.type = fn_decl @Second [concrete = constants.%Second] {
// CHECK:STDOUT:     %T.patt.loc4_21.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_21.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %p.param_patt.loc4_30.1: @Second.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %p.param_patt.loc4_30.2 (constants.%p.param_patt.e58)]
// CHECK:STDOUT:     %p.patt.loc4_30.1: @Second.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern p, %p.param_patt.loc4_30.1 [template = %p.patt.loc4_30.2 (constants.%p.patt.0ba)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_38: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %.loc4_23.1: type = splice_block %.loc4_23.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_23.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_21.2: type = symbolic_binding T, 0, template [template = %T.loc4_21.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %p.param: @Second.%T.loc4_21.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc4_21.2 [template = %T.loc4_21.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %p: @Second.%T.loc4_21.1 (%T.67db0b.1) = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Second(%T.loc4_21.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_21.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_21.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc4_21.1: type = symbolic_binding T, 0, template [template = %T.loc4_21.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_21.1 [template = %pattern_type (constants.%pattern_type.51d)]
// CHECK:STDOUT:   %p.param_patt.loc4_30.2: @Second.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %p.param_patt.loc4_30.2 (constants.%p.param_patt.e58)]
// CHECK:STDOUT:   %p.patt.loc4_30.2: @Second.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern p, %p.param_patt.loc4_30.2 [template = %p.patt.loc4_30.2 (constants.%p.patt.0ba)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc4_21.1 [template = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc5_11.3: <instruction> = tuple_index_action %p.ref, %int_1 [template]
// CHECK:STDOUT:   %.loc5_11.4: type = type_of_inst %.loc5_11.3 [template = %.loc5_11.4 (constants.%.a9b)]
// CHECK:STDOUT:   %.loc5_11.5: @Second.%.loc5_11.4 (%.a9b) = splice_inst %.loc5_11.3 [template = %.loc5_11.5 (constants.%.f4b)]
// CHECK:STDOUT:   %.loc5_13.2: <instruction> = convert_action %.loc5_11.2, constants.%i32, element10 [template]
// CHECK:STDOUT:   %.loc5_13.3: %i32 = splice_inst %.loc5_13.2 [template = %.loc5_13.3 (constants.%.28a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%p.param: @Second.%T.loc4_21.1 (%T.67db0b.1)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %p.ref: @Second.%T.loc4_21.1 (%T.67db0b.1) = name_ref p, %p
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:     %.loc5_11.1: type = type_of_inst %.loc5_11.3 [template = %.loc5_11.4 (constants.%.a9b)]
// CHECK:STDOUT:     %.loc5_11.2: @Second.%.loc5_11.4 (%.a9b) = splice_inst %.loc5_11.3 [template = %.loc5_11.5 (constants.%.f4b)]
// CHECK:STDOUT:     %.loc5_13.1: %i32 = splice_inst %.loc5_13.2 [template = %.loc5_13.3 (constants.%.28a)]
// CHECK:STDOUT:     return %.loc5_13.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Second(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc4_21.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_21.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d
// CHECK:STDOUT:   %p.param_patt.loc4_30.2 => constants.%p.param_patt.e58
// CHECK:STDOUT:   %p.patt.loc4_30.2 => constants.%p.patt.0ba
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Second(constants.%tuple.type.e55) {
// CHECK:STDOUT:   %T.patt.loc4_21.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_21.1 => constants.%tuple.type.e55
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.394
// CHECK:STDOUT:   %p.param_patt.loc4_30.2 => constants.%p.param_patt.e62
// CHECK:STDOUT:   %p.patt.loc4_30.2 => constants.%p.patt.07f
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.6c4
// CHECK:STDOUT:   %.loc5_11.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc5_11.4 => constants.%i32
// CHECK:STDOUT:   %.loc5_11.5 => <not constant>
// CHECK:STDOUT:   %.loc5_13.2 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc5_13.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- array_index_param.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %a.param_patt.dac: %pattern_type.51d1c4.1 = value_param_pattern [template]
// CHECK:STDOUT:   %a.patt.46c: %pattern_type.51d1c4.1 = wrapper_binding_pattern a, %a.param_patt.dac [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %At1.type: type = fn_type @At1 [concrete]
// CHECK:STDOUT:   %At1: %At1.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %.2dd: type = type_of_inst @At1.%.loc5_13.3 [template]
// CHECK:STDOUT:   %.61f: %.2dd = splice_inst @At1.%.loc5_13.3 [template]
// CHECK:STDOUT:   %.28a: %i32 = splice_inst @At1.%.loc5_14.2 [template]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %array_type: type = array_type %int_3, %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.771: type = pattern_type %array_type [concrete]
// CHECK:STDOUT:   %a.param_patt.109: %pattern_type.771 = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt.e19: %pattern_type.771 = wrapper_binding_pattern a, %a.param_patt.109 [concrete]
// CHECK:STDOUT:   %complete_type.b77: <witness> = complete_type_witness %array_type [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.f0b: %i32 = splice_block %.85a {
// CHECK:STDOUT:       %.ff9: %array_type = specific_inst @At1.%a.ref, @At1(%array_type)
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %.8c8: ref %array_type = value_as_ref %.ff9
// CHECK:STDOUT:       %.b34: ref %i32 = array_index %.8c8, %.f2d
// CHECK:STDOUT:       %.85a: %i32 = acquire_value %.b34
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.064: init %i32 = splice_block %Int.as.Copy.impl.Op.call {
// CHECK:STDOUT:       %impl.elem0.882: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.452: <bound method> = bound_method %.f0b, %impl.elem0.882
// CHECK:STDOUT:       %specific_fn.96a: <specific function> = specific_function %impl.elem0.882, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.71c: <bound method> = bound_method %.f0b, %specific_fn.96a
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.71c(%.f0b)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %At1.decl: %At1.type = fn_decl @At1 [concrete = constants.%At1] {
// CHECK:STDOUT:     %T.patt.loc4_18.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_18.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %a.param_patt.loc4_27.1: @At1.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %a.param_patt.loc4_27.2 (constants.%a.param_patt.dac)]
// CHECK:STDOUT:     %a.patt.loc4_27.1: @At1.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern a, %a.param_patt.loc4_27.1 [template = %a.patt.loc4_27.2 (constants.%a.patt.46c)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_35: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc4_20.1: type = splice_block %.loc4_20.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_20.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_18.2: type = symbolic_binding T, 0, template [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %a.param: @At1.%T.loc4_18.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc4_18.2 [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %a: @At1.%T.loc4_18.1 (%T.67db0b.1) = wrapper_binding a, %a.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @At1(%T.loc4_18.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_18.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_18.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc4_18.1: type = symbolic_binding T, 0, template [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_18.1 [template = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %a.param_patt.loc4_27.2: @At1.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %a.param_patt.loc4_27.2 (constants.%a.param_patt.dac)]
// CHECK:STDOUT:   %a.patt.loc4_27.2: @At1.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern a, %a.param_patt.loc4_27.2 [template = %a.patt.loc4_27.2 (constants.%a.patt.46c)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc4_18.1 [template = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc5_13.3: <instruction> = index_action %a.ref, %int_1 [template]
// CHECK:STDOUT:   %.loc5_13.4: type = type_of_inst %.loc5_13.3 [template = %.loc5_13.4 (constants.%.2dd)]
// CHECK:STDOUT:   %.loc5_13.5: @At1.%.loc5_13.4 (%.2dd) = splice_inst %.loc5_13.3 [template = %.loc5_13.5 (constants.%.61f)]
// CHECK:STDOUT:   %.loc5_14.2: <instruction> = convert_action %.loc5_13.2, constants.%i32, element10 [template]
// CHECK:STDOUT:   %.loc5_14.3: %i32 = splice_inst %.loc5_14.2 [template = %.loc5_14.3 (constants.%.28a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%a.param: @At1.%T.loc4_18.1 (%T.67db0b.1)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %a.ref: @At1.%T.loc4_18.1 (%T.67db0b.1) = name_ref a, %a
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %.loc5_13.1: type = type_of_inst %.loc5_13.3 [template = %.loc5_13.4 (constants.%.2dd)]
// CHECK:STDOUT:     %.loc5_13.2: @At1.%.loc5_13.4 (%.2dd) = splice_inst %.loc5_13.3 [template = %.loc5_13.5 (constants.%.61f)]
// CHECK:STDOUT:     %.loc5_14.1: %i32 = splice_inst %.loc5_14.2 [template = %.loc5_14.3 (constants.%.28a)]
// CHECK:STDOUT:     return %.loc5_14.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @At1(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc4_18.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_18.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %a.param_patt.loc4_27.2 => constants.%a.param_patt.dac
// CHECK:STDOUT:   %a.patt.loc4_27.2 => constants.%a.patt.46c
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @At1(constants.%array_type) {
// CHECK:STDOUT:   %T.patt.loc4_18.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_18.1 => constants.%array_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.771
// CHECK:STDOUT:   %a.param_patt.loc4_27.2 => constants.%a.param_patt.109
// CHECK:STDOUT:   %a.patt.loc4_27.2 => constants.%a.patt.e19
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.b77
// CHECK:STDOUT:   %.loc5_13.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc5_13.4 => constants.%i32
// CHECK:STDOUT:   %.loc5_13.5 => <not constant>
// CHECK:STDOUT:   %.loc5_14.2 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc5_14.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
