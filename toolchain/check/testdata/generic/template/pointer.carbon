// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/pointer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/pointer.carbon

// --- deref_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Deref[template T: type](p: T) -> i32 {
  return *p;
}
//@dump-sem-ir-end

fn Use(n: i32*) -> i32 {
  return Deref(n);
}

// --- arrow_member.carbon
library "[[@TEST_NAME]]";

class Node {
  var n: i32;
}

class Link {
  var p: Node*;
}

fn Next[template T: type](x: T) -> i32 {
  return x.p->n;
}

fn Use(link: Link) -> i32 {
  return Next(link);
}

// --- addr_of_member.carbon
library "[[@TEST_NAME]]";

class Counter {
  var n: i32;
}

//@dump-sem-ir-begin
fn Read[template T: type](ref x: T) -> i32 {
  let p: i32* = &x.n;
  return *p;
}
//@dump-sem-ir-end

fn Use(ref c: Counter) -> i32 {
  return Read(ref c);
}

// --- deref_pointer_param.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: T*) -> T {
  return *p;
}

fn Use(n: i32*) -> i32 {
  return Deref(n);
}

// --- fail_deref_non_pointer_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Use(n: i32) -> i32 {
  // CHECK:STDERR: fail_deref_non_pointer_on_instantiation.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `Deref(i32)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Deref(n);
  // CHECK:STDERR:          ^~~~~
  // CHECK:STDERR: fail_deref_non_pointer_on_instantiation.carbon:[[@LINE-7]]:10: note: cannot dereference operand of non-pointer type `i32` [DerefOfNonPointer]
  // CHECK:STDERR:   return *p;
  // CHECK:STDERR:          ^
  // CHECK:STDERR:
  return Deref(n);
}

// CHECK:STDOUT: --- deref_param.carbon
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
// CHECK:STDOUT:   %Deref.type: type = fn_type @Deref [concrete]
// CHECK:STDOUT:   %Deref: %Deref.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %.6c8: type = type_of_inst @Deref.%.loc5_10.3 [template]
// CHECK:STDOUT:   %.5d5: %.6c8 = splice_inst @Deref.%.loc5_10.3 [template]
// CHECK:STDOUT:   %.28a: %i32 = splice_inst @Deref.%.loc5_12.2 [template]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.f00: type = pattern_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %p.param_patt.b89: %pattern_type.f00 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.f8d: %pattern_type.f00 = wrapper_binding_pattern p, %p.param_patt.b89 [concrete]
// CHECK:STDOUT:   %complete_type.07f: <witness> = complete_type_witness %ptr.d08 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.31b: ref %i32 = splice_block %.311 {
// CHECK:STDOUT:       %.a86: %ptr.d08 = specific_inst @Deref.%p.ref, @Deref(%ptr.d08)
// CHECK:STDOUT:       %.311: ref %i32 = deref %.a86
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
// CHECK:STDOUT:     %.9cc: init %i32 = splice_block %Int.as.Copy.impl.Op.call {
// CHECK:STDOUT:       %.821: %i32 = acquire_value %.31b
// CHECK:STDOUT:       %impl.elem0.882: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.174: <bound method> = bound_method %.821, %impl.elem0.882
// CHECK:STDOUT:       %specific_fn: <specific function> = specific_function %impl.elem0.882, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.3d6: <bound method> = bound_method %.821, %specific_fn
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.3d6(%.821)
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
// CHECK:STDOUT:   %Deref.decl: %Deref.type = fn_decl @Deref [concrete = constants.%Deref] {
// CHECK:STDOUT:     %T.patt.loc4_20.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_20.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %p.param_patt.loc4_29.1: @Deref.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %p.param_patt.loc4_29.2 (constants.%p.param_patt.e58)]
// CHECK:STDOUT:     %p.patt.loc4_29.1: @Deref.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern p, %p.param_patt.loc4_29.1 [template = %p.patt.loc4_29.2 (constants.%p.patt.0ba)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_37: Core.Form = init_form %i32 [concrete = constants.%.795]
// CHECK:STDOUT:     %.loc4_22.1: type = splice_block %.loc4_22.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_22.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_20.2: type = symbolic_binding T, 0, template [template = %T.loc4_20.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %p.param: @Deref.%T.loc4_20.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc4_20.2 [template = %T.loc4_20.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %p: @Deref.%T.loc4_20.1 (%T.67db0b.1) = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Deref(%T.loc4_20.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_20.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_20.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc4_20.1: type = symbolic_binding T, 0, template [template = %T.loc4_20.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_20.1 [template = %pattern_type (constants.%pattern_type.51d)]
// CHECK:STDOUT:   %p.param_patt.loc4_29.2: @Deref.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %p.param_patt.loc4_29.2 (constants.%p.param_patt.e58)]
// CHECK:STDOUT:   %p.patt.loc4_29.2: @Deref.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern p, %p.param_patt.loc4_29.2 [template = %p.patt.loc4_29.2 (constants.%p.patt.0ba)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc4_20.1 [template = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc5_10.3: <instruction> = pointer_dereference_action %p.ref, false [template]
// CHECK:STDOUT:   %.loc5_10.4: type = type_of_inst %.loc5_10.3 [template = %.loc5_10.4 (constants.%.6c8)]
// CHECK:STDOUT:   %.loc5_10.5: @Deref.%.loc5_10.4 (%.6c8) = splice_inst %.loc5_10.3 [template = %.loc5_10.5 (constants.%.5d5)]
// CHECK:STDOUT:   %.loc5_12.2: <instruction> = convert_action %.loc5_10.2, constants.%i32, element10 [template]
// CHECK:STDOUT:   %.loc5_12.3: %i32 = splice_inst %.loc5_12.2 [template = %.loc5_12.3 (constants.%.28a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%p.param: @Deref.%T.loc4_20.1 (%T.67db0b.1)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %p.ref: @Deref.%T.loc4_20.1 (%T.67db0b.1) = name_ref p, %p
// CHECK:STDOUT:     %.loc5_10.1: type = type_of_inst %.loc5_10.3 [template = %.loc5_10.4 (constants.%.6c8)]
// CHECK:STDOUT:     %.loc5_10.2: @Deref.%.loc5_10.4 (%.6c8) = splice_inst %.loc5_10.3 [template = %.loc5_10.5 (constants.%.5d5)]
// CHECK:STDOUT:     %.loc5_12.1: %i32 = splice_inst %.loc5_12.2 [template = %.loc5_12.3 (constants.%.28a)]
// CHECK:STDOUT:     return %.loc5_12.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Deref(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc4_20.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_20.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d
// CHECK:STDOUT:   %p.param_patt.loc4_29.2 => constants.%p.param_patt.e58
// CHECK:STDOUT:   %p.patt.loc4_29.2 => constants.%p.patt.0ba
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Deref(constants.%ptr.d08) {
// CHECK:STDOUT:   %T.patt.loc4_20.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_20.1 => constants.%ptr.d08
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.f00
// CHECK:STDOUT:   %p.param_patt.loc4_29.2 => constants.%p.param_patt.b89
// CHECK:STDOUT:   %p.patt.loc4_29.2 => constants.%p.patt.f8d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.07f
// CHECK:STDOUT:   %.loc5_10.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc5_10.4 => constants.%i32
// CHECK:STDOUT:   %.loc5_10.5 => <not constant>
// CHECK:STDOUT:   %.loc5_12.2 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc5_12.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- addr_of_member.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Counter: type = class_type @Counter [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Counter.elem: type = unbound_element_type %Counter, %i32 [concrete]
// CHECK:STDOUT:   %struct_type.n: type = struct_type {.n: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.cdf: <witness> = complete_type_witness %struct_type.n [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %x.param_patt.2ca: %pattern_type.51d = ref_param_pattern [template]
// CHECK:STDOUT:   %x.patt.c65: %pattern_type.51d = wrapper_binding_pattern x, %x.param_patt.2ca [template]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Read.type: type = fn_type @Read [concrete]
// CHECK:STDOUT:   %Read: %Read.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.f00: type = pattern_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.f00 = value_binding_pattern p [concrete]
// CHECK:STDOUT:   %.237: type = type_of_inst @Read.%.loc9_19.3 [template]
// CHECK:STDOUT:   %.f96: %.237 = splice_inst @Read.%.loc9_19.3 [template]
// CHECK:STDOUT:   %.400: type = type_of_inst @Read.%.loc9_17.4 [template]
// CHECK:STDOUT:   %.45e: %.400 = splice_inst @Read.%.loc9_17.4 [template]
// CHECK:STDOUT:   %.996: %ptr.d08 = splice_inst @Read.%.loc9_17.7 [template]
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
// CHECK:STDOUT:   %pattern_type.f85: type = pattern_type %Counter [concrete]
// CHECK:STDOUT:   %x.param_patt.3ba: %pattern_type.f85 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.2b1: %pattern_type.f85 = wrapper_binding_pattern x, %x.param_patt.3ba [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.4c2: ref %i32 = splice_block %.41f {
// CHECK:STDOUT:       %.540: ref %Counter = specific_inst @Read.%x.ref, @Read(%Counter)
// CHECK:STDOUT:       %n.ref: %Counter.elem = name_ref n, @Counter.%field_decl [concrete = @Counter.%field_decl]
// CHECK:STDOUT:       %.41f: ref %i32 = class_element_access %.540, element0
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.addr_of: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %addr: %ptr.d08 = addr_of %.4c2
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.5a5: %ptr.d08 = splice_block %addr {}
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Read.decl: %Read.type = fn_decl @Read [concrete = constants.%Read] {
// CHECK:STDOUT:     %T.patt.loc8_19.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc8_19.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %x.param_patt.loc8_32.1: @Read.%pattern_type (%pattern_type.51d) = ref_param_pattern [template = %x.param_patt.loc8_32.2 (constants.%x.param_patt.2ca)]
// CHECK:STDOUT:     %x.patt.loc8_32.1: @Read.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern x, %x.param_patt.loc8_32.1 [template = %x.patt.loc8_32.2 (constants.%x.patt.c65)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_40: Core.Form = init_form %i32.loc8 [concrete = constants.%.795]
// CHECK:STDOUT:     %.loc8_21.1: type = splice_block %.loc8_21.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc8_21.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc8_19.2: type = symbolic_binding T, 0, template [template = %T.loc8_19.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x.param: ref @Read.%T.loc8_19.1 (%T.67db0b.1) = ref_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc8_19.2 [template = %T.loc8_19.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x: ref @Read.%T.loc8_19.1 (%T.67db0b.1) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Read(%T.loc8_19.2: type) {
// CHECK:STDOUT:   %T.patt.loc8_19.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc8_19.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc8_19.1: type = symbolic_binding T, 0, template [template = %T.loc8_19.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc8_19.1 [template = %pattern_type (constants.%pattern_type.51d)]
// CHECK:STDOUT:   %x.param_patt.loc8_32.2: @Read.%pattern_type (%pattern_type.51d) = ref_param_pattern [template = %x.param_patt.loc8_32.2 (constants.%x.param_patt.2ca)]
// CHECK:STDOUT:   %x.patt.loc8_32.2: @Read.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern x, %x.param_patt.loc8_32.2 [template = %x.patt.loc8_32.2 (constants.%x.patt.c65)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc8_19.1 [template = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc9_19.3: <instruction> = access_member_action %x.ref, n [template]
// CHECK:STDOUT:   %.loc9_19.4: type = type_of_inst %.loc9_19.3 [template = %.loc9_19.4 (constants.%.237)]
// CHECK:STDOUT:   %.loc9_19.5: @Read.%.loc9_19.4 (%.237) = splice_inst %.loc9_19.3 [template = %.loc9_19.5 (constants.%.f96)]
// CHECK:STDOUT:   %.loc9_17.4: <instruction> = addr_of_action %.loc9_19.2 [template]
// CHECK:STDOUT:   %.loc9_17.5: type = type_of_inst %.loc9_17.4 [template = %.loc9_17.5 (constants.%.400)]
// CHECK:STDOUT:   %.loc9_17.6: @Read.%.loc9_17.5 (%.400) = splice_inst %.loc9_17.4 [template = %.loc9_17.6 (constants.%.45e)]
// CHECK:STDOUT:   %.loc9_17.7: <instruction> = convert_to_value_action %.loc9_17.2, constants.%ptr.d08 [template]
// CHECK:STDOUT:   %.loc9_17.8: %ptr.d08 = splice_inst %.loc9_17.7 [template = %.loc9_17.8 (constants.%.996)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: ref @Read.%T.loc8_19.1 (%T.67db0b.1)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref: ref @Read.%T.loc8_19.1 (%T.67db0b.1) = name_ref x, %x
// CHECK:STDOUT:     %.loc9_19.1: type = type_of_inst %.loc9_19.3 [template = %.loc9_19.4 (constants.%.237)]
// CHECK:STDOUT:     %.loc9_19.2: @Read.%.loc9_19.4 (%.237) = splice_inst %.loc9_19.3 [template = %.loc9_19.5 (constants.%.f96)]
// CHECK:STDOUT:     %.loc9_17.1: type = type_of_inst %.loc9_17.4 [template = %.loc9_17.5 (constants.%.400)]
// CHECK:STDOUT:     %.loc9_17.2: @Read.%.loc9_17.5 (%.400) = splice_inst %.loc9_17.4 [template = %.loc9_17.6 (constants.%.45e)]
// CHECK:STDOUT:     %.loc9_17.3: %ptr.d08 = splice_inst %.loc9_17.7 [template = %.loc9_17.8 (constants.%.996)]
// CHECK:STDOUT:     %.loc9_13: type = splice_block %ptr [concrete = constants.%ptr.d08] {
// CHECK:STDOUT:       %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %ptr: type = ptr_type %i32.loc9 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.d08 = wrapper_binding p, %.loc9_17.3
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %p.patt: %pattern_type.f00 = value_binding_pattern p [concrete = constants.%p.patt]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p.ref: %ptr.d08 = name_ref p, %p
// CHECK:STDOUT:     %.loc10_10.1: ref %i32 = deref %p.ref
// CHECK:STDOUT:     %.loc10_10.2: %i32 = acquire_value %.loc10_10.1
// CHECK:STDOUT:     %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:     %bound_method.loc10_10.1: <bound method> = bound_method %.loc10_10.2, %impl.elem0
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc10_10.2: <bound method> = bound_method %.loc10_10.2, %specific_fn
// CHECK:STDOUT:     %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc10_10.2(%.loc10_10.2)
// CHECK:STDOUT:     return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Read(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc8_19.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc8_19.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d
// CHECK:STDOUT:   %x.param_patt.loc8_32.2 => constants.%x.param_patt.2ca
// CHECK:STDOUT:   %x.patt.loc8_32.2 => constants.%x.patt.c65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Read(constants.%Counter) {
// CHECK:STDOUT:   %T.patt.loc8_19.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc8_19.1 => constants.%Counter
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.f85
// CHECK:STDOUT:   %x.param_patt.loc8_32.2 => constants.%x.param_patt.3ba
// CHECK:STDOUT:   %x.patt.loc8_32.2 => constants.%x.patt.2b1
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.cdf
// CHECK:STDOUT:   %.loc9_19.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc9_19.4 => constants.%i32
// CHECK:STDOUT:   %.loc9_19.5 => <not constant>
// CHECK:STDOUT:   %.loc9_17.4 => constants.%inst.addr_of
// CHECK:STDOUT:   %.loc9_17.5 => constants.%ptr.d08
// CHECK:STDOUT:   %.loc9_17.6 => <not constant>
// CHECK:STDOUT:   %.loc9_17.7 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc9_17.8 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
