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

// --- index_class_with_index_with.carbon
library "[[@TEST_NAME]]";

class Vec(T: type) {
  var tag: i32;
  impl as Core.IndexWith(i32) where .ElementType = i32 {
    fn At(self, unused i: i32) -> i32 { return self.tag; }
  }
}

//@dump-sem-ir-begin
fn Get[template T: type](v: Vec(T), i: i32) -> i32 {
  return v[i];
}
//@dump-sem-ir-end

fn Use(v: Vec(bool)) -> i32 {
  return Get(v, 0);
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
// CHECK:STDOUT: --- index_class_with_index_with.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.e58: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %Vec.type: type = generic_class_type @Vec [concrete]
// CHECK:STDOUT:   %Vec.generic: %Vec.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %SubscriptType: type = symbolic_binding SubscriptType, 0 [symbolic]
// CHECK:STDOUT:   %IndexWith.type.cce: type = facet_type <@IndexWith, @IndexWith(%SubscriptType)> [symbolic]
// CHECK:STDOUT:   %Self.6c2: %IndexWith.type.cce = symbolic_binding Self, 1 [symbolic]
// CHECK:STDOUT:   %IndexWith.WithSelf.At.type.eec: type = fn_type @IndexWith.WithSelf.At, @IndexWith.WithSelf(%SubscriptType, %Self.6c2) [symbolic]
// CHECK:STDOUT:   %IndexWith.WithSelf.At.b6a: %IndexWith.WithSelf.At.type.eec = struct_value () [symbolic]
// CHECK:STDOUT:   %IndexWith.type.7ec: type = facet_type <@IndexWith, @IndexWith(%i32)> [concrete]
// CHECK:STDOUT:   %IndexWith.assoc_type.e5c: type = assoc_entity_type @IndexWith, @IndexWith(%i32) [concrete]
// CHECK:STDOUT:   %assoc1.1b9: %IndexWith.assoc_type.e5c = assoc_entity element1, imports.%Core.import_ref.54c [concrete]
// CHECK:STDOUT:   %i.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %struct_type.tag: type = struct_type {.tag: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.26b: <witness> = complete_type_witness %struct_type.tag [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.2: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %Vec.2301bb.2: type = class_type @Vec, @Vec(%T.67db0b.2) [template]
// CHECK:STDOUT:   %pattern_type.9317eb.2: type = pattern_type %Vec.2301bb.2 [template]
// CHECK:STDOUT:   %v.param_patt.48f: %pattern_type.9317eb.2 = value_param_pattern [template]
// CHECK:STDOUT:   %v.patt.317: %pattern_type.9317eb.2 = wrapper_binding_pattern v, %v.param_patt.48f [template]
// CHECK:STDOUT:   %i.patt.d2f74c.2: %pattern_type.6b6 = wrapper_binding_pattern i, %i.param_patt [concrete]
// CHECK:STDOUT:   %Get.type: type = fn_type @Get [concrete]
// CHECK:STDOUT:   %Get: %Get.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.debde9.2: <witness> = require_complete_type %Vec.2301bb.2 [template]
// CHECK:STDOUT:   %.8cb: type = type_of_inst @Get.%.loc12_13.5 [template]
// CHECK:STDOUT:   %.c23: %.8cb = splice_inst @Get.%.loc12_13.5 [template]
// CHECK:STDOUT:   %.682: type = type_of_inst @Get.%.loc12_13.8 [template]
// CHECK:STDOUT:   %.c2b: %.682 = splice_inst @Get.%.loc12_13.8 [template]
// CHECK:STDOUT:   %.28a: %i32 = splice_inst @Get.%.loc12_14.2 [template]
// CHECK:STDOUT:   %Vec.f02: type = class_type @Vec, @Vec(bool) [concrete]
// CHECK:STDOUT:   %pattern_type.992: type = pattern_type %Vec.f02 [concrete]
// CHECK:STDOUT:   %v.param_patt.8f2: %pattern_type.992 = value_param_pattern [concrete]
// CHECK:STDOUT:   %v.patt.b43: %pattern_type.992 = wrapper_binding_pattern v, %v.param_patt.8f2 [concrete]
// CHECK:STDOUT:   %IndexWith.impl_witness.98a: <witness> = impl_witness @Vec.as.IndexWith.impl.%IndexWith.impl_witness_table, @Vec.as.IndexWith.impl(bool) [concrete]
// CHECK:STDOUT:   %Vec.as.IndexWith.impl.At.type.ef4: type = fn_type @Vec.as.IndexWith.impl.At, @Vec.as.IndexWith.impl(bool) [concrete]
// CHECK:STDOUT:   %Vec.as.IndexWith.impl.At.2df: %Vec.as.IndexWith.impl.At.type.ef4 = struct_value () [concrete]
// CHECK:STDOUT:   %IndexWith.facet.ea2: %IndexWith.type.7ec = facet_value %Vec.f02, (%IndexWith.impl_witness.98a) [concrete]
// CHECK:STDOUT:   %IndexWith.WithSelf.At.type.714: type = fn_type @IndexWith.WithSelf.At, @IndexWith.WithSelf(%i32, %IndexWith.facet.ea2) [concrete]
// CHECK:STDOUT:   %.3df: type = fn_type_with_self_type %IndexWith.WithSelf.At.type.714, %IndexWith.facet.ea2 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.65a: <bound method> = splice_block %bound_method.229 {
// CHECK:STDOUT:       %.0d0: %Vec.f02 = specific_inst @Get.%v.ref, @Get(bool)
// CHECK:STDOUT:       %impl.elem1.d26: %.3df = impl_witness_access %IndexWith.impl_witness.98a, element1 [concrete = %Vec.as.IndexWith.impl.At.2df]
// CHECK:STDOUT:       %bound_method.229: <bound method> = bound_method %.0d0, %impl.elem1.d26
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Vec.as.IndexWith.impl.At.specific_fn: <specific function> = specific_function %Vec.as.IndexWith.impl.At.2df, @Vec.as.IndexWith.impl.At(bool) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.fcd: init %i32 = splice_block %Vec.as.IndexWith.impl.At.call {
// CHECK:STDOUT:       %specific_fn: <specific function> = specific_function %impl.elem1.d26, @Vec.as.IndexWith.impl.At(bool) [concrete = %Vec.as.IndexWith.impl.At.specific_fn]
// CHECK:STDOUT:       %bound_method.68a: <bound method> = bound_method %.0d0, %specific_fn
// CHECK:STDOUT:       %Vec.as.IndexWith.impl.At.call: init %i32 = call %bound_method.68a(%.0d0, @Get.%i.ref)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.0f5: init %i32 = splice_block %.fcd {}
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.54c: @IndexWith.WithSelf.%IndexWith.WithSelf.At.type (%IndexWith.WithSelf.At.type.eec) = import_ref Core//prelude/operators/index, loc{{\d+_\d+}}, loaded [symbolic = @IndexWith.WithSelf.%IndexWith.WithSelf.At (constants.%IndexWith.WithSelf.At.b6a)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Get.decl: %Get.type = fn_decl @Get [concrete = constants.%Get] {
// CHECK:STDOUT:     %T.patt.loc11_18.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc11_18.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:     %v.param_patt.loc11_27.1: @Get.%pattern_type (%pattern_type.9317eb.2) = value_param_pattern [template = %v.param_patt.loc11_27.2 (constants.%v.param_patt.48f)]
// CHECK:STDOUT:     %v.patt.loc11_27.1: @Get.%pattern_type (%pattern_type.9317eb.2) = wrapper_binding_pattern v, %v.param_patt.loc11_27.1 [template = %v.patt.loc11_27.2 (constants.%v.patt.317)]
// CHECK:STDOUT:     %i.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%i.param_patt]
// CHECK:STDOUT:     %i.patt: %pattern_type.6b6 = wrapper_binding_pattern i, %i.param_patt [concrete = constants.%i.patt.d2f74c.2]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc11_48 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc11_48: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_48: Core.Form = init_form %i32.loc11_48 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc11_20.1: type = splice_block %.loc11_20.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.e58]
// CHECK:STDOUT:       %.loc11_20.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc11_18.2: type = symbolic_binding T, 0, template [template = %T.loc11_18.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %v.param: @Get.%Vec.loc11_34.1 (%Vec.2301bb.2) = value_param call_param0
// CHECK:STDOUT:     %.loc11_34: type = splice_block %Vec.loc11_34.2 [template = %Vec.loc11_34.1 (constants.%Vec.2301bb.2)] {
// CHECK:STDOUT:       %Vec.ref: %Vec.type = name_ref Vec, file.%Vec.decl [concrete = constants.%Vec.generic]
// CHECK:STDOUT:       %T.ref: type = name_ref T, %T.loc11_18.2 [template = %T.loc11_18.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:       %Vec.loc11_34.2: type = class_type @Vec, @Vec(constants.%T.67db0b.2) [template = %Vec.loc11_34.1 (constants.%Vec.2301bb.2)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v: @Get.%Vec.loc11_34.1 (%Vec.2301bb.2) = wrapper_binding v, %v.param
// CHECK:STDOUT:     %i.param: %i32 = value_param call_param1
// CHECK:STDOUT:     %i32.loc11_40: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i: %i32 = wrapper_binding i, %i.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Get(%T.loc11_18.2: type) {
// CHECK:STDOUT:   %T.patt.loc11_18.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc11_18.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:   %T.loc11_18.1: type = symbolic_binding T, 0, template [template = %T.loc11_18.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:   %Vec.loc11_34.1: type = class_type @Vec, @Vec(%T.loc11_18.1) [template = %Vec.loc11_34.1 (constants.%Vec.2301bb.2)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %Vec.loc11_34.1 [template = %pattern_type (constants.%pattern_type.9317eb.2)]
// CHECK:STDOUT:   %v.param_patt.loc11_27.2: @Get.%pattern_type (%pattern_type.9317eb.2) = value_param_pattern [template = %v.param_patt.loc11_27.2 (constants.%v.param_patt.48f)]
// CHECK:STDOUT:   %v.patt.loc11_27.2: @Get.%pattern_type (%pattern_type.9317eb.2) = wrapper_binding_pattern v, %v.param_patt.loc11_27.2 [template = %v.patt.loc11_27.2 (constants.%v.patt.317)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %Vec.loc11_34.1 [template = %require_complete (constants.%require_complete.debde9.2)]
// CHECK:STDOUT:   %.loc12_13.5: <instruction> = compound_member_access_action %v.ref, constants.%assoc1.1b9 [template]
// CHECK:STDOUT:   %.loc12_13.6: type = type_of_inst %.loc12_13.5 [template = %.loc12_13.6 (constants.%.8cb)]
// CHECK:STDOUT:   %.loc12_13.7: @Get.%.loc12_13.6 (%.8cb) = splice_inst %.loc12_13.5 [template = %.loc12_13.7 (constants.%.c23)]
// CHECK:STDOUT:   %.loc12_13.8: <instruction> = call_action (%.loc12_13.2, %i.ref), true [template]
// CHECK:STDOUT:   %.loc12_13.9: type = type_of_inst %.loc12_13.8 [template = %.loc12_13.9 (constants.%.682)]
// CHECK:STDOUT:   %.loc12_13.10: @Get.%.loc12_13.9 (%.682) = splice_inst %.loc12_13.8 [template = %.loc12_13.10 (constants.%.c2b)]
// CHECK:STDOUT:   %.loc12_14.2: <instruction> = convert_action %.loc12_13.4, constants.%i32, element10 [template]
// CHECK:STDOUT:   %.loc12_14.3: %i32 = splice_inst %.loc12_14.2 [template = %.loc12_14.3 (constants.%.28a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%v.param: @Get.%Vec.loc11_34.1 (%Vec.2301bb.2), %i.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %v.ref: @Get.%Vec.loc11_34.1 (%Vec.2301bb.2) = name_ref v, %v
// CHECK:STDOUT:     %i.ref: %i32 = name_ref i, %i
// CHECK:STDOUT:     %.loc12_13.1: type = type_of_inst %.loc12_13.5 [template = %.loc12_13.6 (constants.%.8cb)]
// CHECK:STDOUT:     %.loc12_13.2: @Get.%.loc12_13.6 (%.8cb) = splice_inst %.loc12_13.5 [template = %.loc12_13.7 (constants.%.c23)]
// CHECK:STDOUT:     %.loc12_13.3: type = type_of_inst %.loc12_13.8 [template = %.loc12_13.9 (constants.%.682)]
// CHECK:STDOUT:     %.loc12_13.4: @Get.%.loc12_13.9 (%.682) = splice_inst %.loc12_13.8 [template = %.loc12_13.10 (constants.%.c2b)]
// CHECK:STDOUT:     %.loc12_14.1: %i32 = splice_inst %.loc12_14.2 [template = %.loc12_14.3 (constants.%.28a)]
// CHECK:STDOUT:     return %.loc12_14.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Get(constants.%T.67db0b.2) {
// CHECK:STDOUT:   %T.patt.loc11_18.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc11_18.1 => constants.%T.67db0b.2
// CHECK:STDOUT:   %Vec.loc11_34.1 => constants.%Vec.2301bb.2
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.9317eb.2
// CHECK:STDOUT:   %v.param_patt.loc11_27.2 => constants.%v.param_patt.48f
// CHECK:STDOUT:   %v.patt.loc11_27.2 => constants.%v.patt.317
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Get(bool) {
// CHECK:STDOUT:   %T.patt.loc11_18.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc11_18.1 => bool
// CHECK:STDOUT:   %Vec.loc11_34.1 => constants.%Vec.f02
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.992
// CHECK:STDOUT:   %v.param_patt.loc11_27.2 => constants.%v.param_patt.8f2
// CHECK:STDOUT:   %v.patt.loc11_27.2 => constants.%v.patt.b43
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.26b
// CHECK:STDOUT:   %.loc12_13.5 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc12_13.6 => <bound method>
// CHECK:STDOUT:   %.loc12_13.7 => <not constant>
// CHECK:STDOUT:   %.loc12_13.8 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc12_13.9 => constants.%i32
// CHECK:STDOUT:   %.loc12_13.10 => <not constant>
// CHECK:STDOUT:   %.loc12_14.2 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc12_14.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
