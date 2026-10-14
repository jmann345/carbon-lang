// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/default_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/default_init.carbon

// --- var_uninit.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F[template T: type](x: T) -> T {
  var y: T;
  y = x;
  return y;
}
//@dump-sem-ir-end

fn Use() -> i32 {
  return F(5 as i32);
}

// --- class_method_var_uninit.carbon
library "[[@TEST_NAME]]";

class Stack(template T: type) {
  var top: T;
  fn Peek(self) -> T {
    var y: T;
    y = self.top;
    return y;
  }
}

fn Use(s: Stack(i32)) -> i32 {
  return s.Peek();
}

// --- fail_var_uninit_tuple_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> T {
  var y: T;
  y = x;
  return y;
}

fn Use(t: (i32, i32)) -> (i32, i32) {
  // CHECK:STDERR: fail_var_uninit_tuple_on_instantiation.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `F((i32, i32))` [ResolvingSpecificHere]
  // CHECK:STDERR:   return F(t);
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_var_uninit_tuple_on_instantiation.carbon:[[@LINE-9]]:3: note: cannot access member of interface `Core.DefaultOrUnformed` in type `(i32, i32)` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   var y: T;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
  return F(t);
}

// --- template_interface_concrete_self.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Widen(template U: type, x: i32) -> U {
  return x;
}
//@dump-sem-ir-end

fn Use(x: i32) -> i64 {
  return Widen(i64, x);
}


// --- template_interface_facet_value.carbon
library "[[@TEST_NAME]]";

interface Tag(T: type) {}
class W {}
impl i32 as Tag(W) {}

fn F(template U: type) {
  let unused t: Tag(U) = i32;
}

fn Use() {
  F(W);
}

// --- template_interface_final_impl.carbon
library "[[@TEST_NAME]]";

interface Tag(T: type) {
  fn Id() -> i32;
}
final impl forall [T: type] i32 as Tag(T) {
  fn Id() -> i32 { return 3; }
}

//@dump-sem-ir-begin
fn Get[template U: type](unused u: U) -> i32 {
  return (i32 as Tag(U)).Id();
}
//@dump-sem-ir-end

fn Use() -> i32 {
  return Get(true);
}

// CHECK:STDOUT: --- var_uninit.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [template]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.1 = wrapper_binding_pattern x, %x.param_patt.91d [template]
// CHECK:STDOUT:   %.184347.1: Core.Form = init_form %T.67db0b.1 [template]
// CHECK:STDOUT:   %return.param_patt.41d2d9.1: %pattern_type.51d1c4.1 = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.b39: %pattern_type.51d1c4.1 = return_slot_pattern %return.param_patt.41d2d9.1, %T.67db0b.1 [template]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %y.patt.a54: %pattern_type.51d1c4.1 = ref_binding_pattern y [template]
// CHECK:STDOUT:   %y.var_patt.0b4: %pattern_type.51d1c4.1 = var_pattern %y.patt.a54 [template]
// CHECK:STDOUT:   %DefaultOrUnformed.type: type = facet_type <@DefaultOrUnformed> [concrete]
// CHECK:STDOUT:   %Self.935: %DefaultOrUnformed.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %DefaultOrUnformed.WithSelf.Op.type.8f1: type = fn_type @DefaultOrUnformed.WithSelf.Op, @DefaultOrUnformed.WithSelf(%Self.935) [symbolic]
// CHECK:STDOUT:   %DefaultOrUnformed.WithSelf.Op.ad7: %DefaultOrUnformed.WithSelf.Op.type.8f1 = struct_value () [symbolic]
// CHECK:STDOUT:   %DefaultOrUnformed.lookup_impl_witness: <witness> = lookup_impl_witness %T.67db0b.1, @DefaultOrUnformed [template]
// CHECK:STDOUT:   %DefaultOrUnformed.facet.d51: %DefaultOrUnformed.type = facet_value %T.67db0b.1, (%DefaultOrUnformed.lookup_impl_witness) [template]
// CHECK:STDOUT:   %.77d: type = type_of_inst @F.%.loc5_11.6 [template]
// CHECK:STDOUT:   %.984: %.77d = splice_inst @F.%.loc5_11.6 [template]
// CHECK:STDOUT:   %.b48: type = type_of_inst @F.%.loc5_11.9 [template]
// CHECK:STDOUT:   %.e18: %.b48 = splice_inst @F.%.loc5_11.9 [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.38eedf.1: %T.67db0b.1 = splice_inst @F.%tuple.elem0.loc5 [template]
// CHECK:STDOUT:   %.38eedf.2: %T.67db0b.1 = splice_inst @F.%tuple.elem0.loc6 [template]
// CHECK:STDOUT:   %.38eedf.3: %T.67db0b.1 = splice_inst @F.%tuple.elem0.loc7 [template]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Self.0e7: %Destroy.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.4e5: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Self.0e7) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.4a0: %Destroy.WithSelf.SelfDestruct.type.4e5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.assoc_type: type = assoc_entity_type @Destroy [concrete]
// CHECK:STDOUT:   %assoc2: %Destroy.assoc_type = assoc_entity element2, imports.%Core.import_ref.71d [concrete]
// CHECK:STDOUT:   %.8cb: type = type_of_inst @F.%.loc5_3.8 [template]
// CHECK:STDOUT:   %.c23: %.8cb = splice_inst @F.%.loc5_3.8 [template]
// CHECK:STDOUT:   %.57c: type = type_of_inst @F.%.loc5_3.11 [template]
// CHECK:STDOUT:   %.e63: %.57c = splice_inst @F.%.loc5_3.11 [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e3b: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %y.patt.479: %pattern_type.6b6 = ref_binding_pattern y [concrete]
// CHECK:STDOUT:   %y.var_patt.634: %pattern_type.6b6 = var_pattern %y.patt.479 [concrete]
// CHECK:STDOUT:   %UnformedInit.type: type = facet_type <@UnformedInit> [concrete]
// CHECK:STDOUT:   %T.fef: %UnformedInit.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.type.215: type = fn_type @T.as_type.as.DefaultOrUnformed.impl.Op.2, @T.as_type.as.DefaultOrUnformed.impl.52f(%T.fef) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.f65: %T.as_type.as.DefaultOrUnformed.impl.Op.type.215 = struct_value () [symbolic]
// CHECK:STDOUT:   %UnformedInit.impl_witness.0a2: <witness> = impl_witness imports.%UnformedInit.impl_witness_table.9b9, @Int.as.UnformedInit.impl(%int_32) [concrete]
// CHECK:STDOUT:   %UnformedInit.facet: %UnformedInit.type = facet_value %i32, (%UnformedInit.impl_witness.0a2) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness.193: <witness> = impl_witness imports.%DefaultOrUnformed.impl_witness_table.8f5, @T.as_type.as.DefaultOrUnformed.impl.52f(%UnformedInit.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.type.a67: type = fn_type @T.as_type.as.DefaultOrUnformed.impl.Op.2, @T.as_type.as.DefaultOrUnformed.impl.52f(%UnformedInit.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.72d: %T.as_type.as.DefaultOrUnformed.impl.Op.type.a67 = struct_value () [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.facet.f65: %DefaultOrUnformed.type = facet_value %i32, (%DefaultOrUnformed.impl_witness.193) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.WithSelf.Op.type.2b7: type = fn_type @DefaultOrUnformed.WithSelf.Op, @DefaultOrUnformed.WithSelf(%DefaultOrUnformed.facet.f65) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.assoc_type: type = assoc_entity_type @DefaultOrUnformed [concrete]
// CHECK:STDOUT:   %assoc0.b81: %DefaultOrUnformed.assoc_type = assoc_entity element0, imports.%Core.import_ref.d14 [concrete]
// CHECK:STDOUT:   %.8b7: type = fn_type_with_self_type %DefaultOrUnformed.WithSelf.Op.type.2b7, %DefaultOrUnformed.facet.f65 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.011: %.8b7 = splice_block %impl.elem0.d82 [concrete = %T.as_type.as.DefaultOrUnformed.impl.Op.72d] {
// CHECK:STDOUT:       %as_type: type = facet_access_type %DefaultOrUnformed.facet.f65 [concrete = %i32]
// CHECK:STDOUT:       %.fe9: type = converted %DefaultOrUnformed.facet.f65, %as_type [concrete = %i32]
// CHECK:STDOUT:       %Op.ref: %DefaultOrUnformed.assoc_type = name_ref Op, imports.%Core.import_ref.6dc [concrete = %assoc0.b81]
// CHECK:STDOUT:       %impl.elem0.d82: %.8b7 = impl_witness_access %DefaultOrUnformed.impl_witness.193, element0 [concrete = %T.as_type.as.DefaultOrUnformed.impl.Op.72d]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.1b5: init %i32 = splice_block %T.as_type.as.DefaultOrUnformed.impl.Op.call {
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %T.as_type.as.DefaultOrUnformed.impl.Op.call: init %i32 = call %T.as_type.as.DefaultOrUnformed.impl.Op.specific_fn.2c02cb.2()
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.d4b: init %i32 = splice_block %.1b5 {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.1: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.3) [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.4: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.388: init %i32 = splice_block %Int.as.Copy.impl.Op.call.f09 {
// CHECK:STDOUT:       %.3e2: %i32 = specific_inst @F.%x.ref, @F(%i32)
// CHECK:STDOUT:       %impl.elem0.88228e.2: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.606: <bound method> = bound_method %.3e2, %impl.elem0.88228e.2
// CHECK:STDOUT:       %specific_fn.96a233.2: <specific function> = specific_function %impl.elem0.88228e.2, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.65e: <bound method> = bound_method %.3e2, %specific_fn.96a233.2
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call.f09: init %i32 = call %bound_method.65e(%.3e2)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.2: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.4) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.5: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.b6f: init %i32 = splice_block %Int.as.Copy.impl.Op.call.1d5 {
// CHECK:STDOUT:       %.5b9: ref %i32 = specific_inst @F.%y.ref.loc7, @F(%i32)
// CHECK:STDOUT:       %.7bd: %i32 = acquire_value %.5b9
// CHECK:STDOUT:       %impl.elem0.88228e.1: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.ec5: <bound method> = bound_method %.7bd, %impl.elem0.88228e.1
// CHECK:STDOUT:       %specific_fn.96a233.1: <specific function> = specific_function %impl.elem0.88228e.1, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.3f1: <bound method> = bound_method %.7bd, %specific_fn.96a233.1
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call.1d5: init %i32 = call %bound_method.3f1(%.7bd)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.3: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.5) [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f: <witness> = custom_witness (%Destroy.WithSelf.Op.403, %Destroy.WithSelf.SubobjectDestroy.d01, %Destroy.WithSelf.SelfDestruct.db3), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.b41: %Destroy.type = facet_value %i32, (%custom_witness.f8f) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.11b: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.b41) [concrete]
// CHECK:STDOUT:   %.bbc: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.11b, %Destroy.facet.b41 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.6: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.702: <bound method> = splice_block %bound_method.af1 {
// CHECK:STDOUT:       %.217: ref %i32 = specific_inst @F.%y.var, @F(%i32)
// CHECK:STDOUT:       %impl.elem2: %.bbc = impl_witness_access %custom_witness.f8f, element2 [concrete = %Destroy.WithSelf.SelfDestruct.db3]
// CHECK:STDOUT:       %bound_method.af1: <bound method> = bound_method %.217, %impl.elem2
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.call: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %.702(%.217)
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.6dc: %DefaultOrUnformed.assoc_type = import_ref Core//prelude/default, loc{{\d+_\d+}}, loaded [concrete = constants.%assoc0.b81]
// CHECK:STDOUT:   %Core.import_ref.71d: @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct.type (%Destroy.WithSelf.SelfDestruct.type.4e5) = import_ref Core//prelude/destroy, loc{{\d+_\d+}}, loaded [symbolic = @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct (constants.%Destroy.WithSelf.SelfDestruct.4a0)]
// CHECK:STDOUT:   %Core.import_ref.083: @T.as_type.as.DefaultOrUnformed.impl.52f.%T.as_type.as.DefaultOrUnformed.impl.Op.type (%T.as_type.as.DefaultOrUnformed.impl.Op.type.215) = import_ref Core//prelude/default, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.DefaultOrUnformed.impl.52f.%T.as_type.as.DefaultOrUnformed.impl.Op (constants.%T.as_type.as.DefaultOrUnformed.impl.Op.f65)]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness_table.8f5 = impl_witness_table (%Core.import_ref.083), @T.as_type.as.DefaultOrUnformed.impl.52f [concrete]
// CHECK:STDOUT:   %UnformedInit.impl_witness_table.9b9 = impl_witness_table (), @Int.as.UnformedInit.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.d14: @DefaultOrUnformed.WithSelf.%DefaultOrUnformed.WithSelf.Op.type (%DefaultOrUnformed.WithSelf.Op.type.8f1) = import_ref Core//prelude/default, loc{{\d+_\d+}}, loaded [symbolic = @DefaultOrUnformed.WithSelf.%DefaultOrUnformed.WithSelf.Op (constants.%DefaultOrUnformed.WithSelf.Op.ad7)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc5 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %T.patt.loc4_16.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_16.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %x.param_patt.loc4_25.1: @F.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc4_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc4_25.1: @F.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc4_25.1 [template = %x.patt.loc4_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:     %return.param_patt.loc4_33.1: @F.%pattern_type (%pattern_type.51d1c4.1) = out_param_pattern [template = %return.param_patt.loc4_33.2 (constants.%return.param_patt.41d2d9.1)]
// CHECK:STDOUT:     %return.patt.loc4_30.1: @F.%pattern_type (%pattern_type.51d1c4.1) = return_slot_pattern %return.param_patt.loc4_33.1, %T.ref.loc4_33 [template = %return.patt.loc4_30.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc4_33: type = name_ref T, %T.loc4_16.2 [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %.loc4_33.2: Core.Form = init_form %T.ref.loc4_33 [template = %.loc4_33.1 (constants.%.184347.1)]
// CHECK:STDOUT:     %.loc4_18.1: type = splice_block %.loc4_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_16.2: type = symbolic_binding T, 0, template [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x.param: @F.%T.loc4_16.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc4_27: type = name_ref T, %T.loc4_16.2 [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x: @F.%T.loc4_16.1 (%T.67db0b.1) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref @F.%T.loc4_16.1 (%T.67db0b.1) = out_param call_param1
// CHECK:STDOUT:     %return: ref @F.%T.loc4_16.1 (%T.67db0b.1) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%T.loc4_16.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_16.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_16.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc4_16.1: type = symbolic_binding T, 0, template [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_16.1 [template = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt.loc4_25.2: @F.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc4_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc4_25.2: @F.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc4_25.2 [template = %x.patt.loc4_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:   %.loc4_33.1: Core.Form = init_form %T.loc4_16.1 [template = %.loc4_33.1 (constants.%.184347.1)]
// CHECK:STDOUT:   %return.param_patt.loc4_33.2: @F.%pattern_type (%pattern_type.51d1c4.1) = out_param_pattern [template = %return.param_patt.loc4_33.2 (constants.%return.param_patt.41d2d9.1)]
// CHECK:STDOUT:   %return.patt.loc4_30.2: @F.%pattern_type (%pattern_type.51d1c4.1) = return_slot_pattern %return.param_patt.loc4_33.2, %T.loc4_16.1 [template = %return.patt.loc4_30.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc4_16.1 [template = %require_complete (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %y.patt.loc5_8.2: @F.%pattern_type (%pattern_type.51d1c4.1) = ref_binding_pattern y [template = %y.patt.loc5_8.2 (constants.%y.patt.a54)]
// CHECK:STDOUT:   %y.var_patt.loc5_3.2: @F.%pattern_type (%pattern_type.51d1c4.1) = var_pattern %y.patt.loc5_8.2 [template = %y.var_patt.loc5_3.2 (constants.%y.var_patt.0b4)]
// CHECK:STDOUT:   %DefaultOrUnformed.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc4_16.1, @DefaultOrUnformed [template = %DefaultOrUnformed.lookup_impl_witness (constants.%DefaultOrUnformed.lookup_impl_witness)]
// CHECK:STDOUT:   %DefaultOrUnformed.facet.loc5_11.2: %DefaultOrUnformed.type = facet_value %T.loc4_16.1, (%DefaultOrUnformed.lookup_impl_witness) [template = %DefaultOrUnformed.facet.loc5_11.2 (constants.%DefaultOrUnformed.facet.d51)]
// CHECK:STDOUT:   %.loc5_11.6: <instruction> = access_member_action %.loc5_11.1, Op [template]
// CHECK:STDOUT:   %.loc5_11.7: type = type_of_inst %.loc5_11.6 [template = %.loc5_11.7 (constants.%.77d)]
// CHECK:STDOUT:   %.loc5_11.8: @F.%.loc5_11.7 (%.77d) = splice_inst %.loc5_11.6 [template = %.loc5_11.8 (constants.%.984)]
// CHECK:STDOUT:   %.loc5_11.9: <instruction> = call_action (%.loc5_11.3), false [template]
// CHECK:STDOUT:   %.loc5_11.10: type = type_of_inst %.loc5_11.9 [template = %.loc5_11.10 (constants.%.b48)]
// CHECK:STDOUT:   %.loc5_11.11: @F.%.loc5_11.10 (%.b48) = splice_inst %.loc5_11.9 [template = %.loc5_11.11 (constants.%.e18)]
// CHECK:STDOUT:   %.loc5_3.6: %tuple.type.f7a = initialize_action %.loc5_11.5, %T.loc4_16.1, %y.var, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc5: <instruction> = tuple_access %.loc5_3.6, element0 [template]
// CHECK:STDOUT:   %.loc5_3.7: @F.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5 [template = %.loc5_3.7 (constants.%.38eedf.1)]
// CHECK:STDOUT:   %.loc6_5.2: %tuple.type.f7a = initialize_action %x.ref, %T.loc4_16.1, %y.ref.loc6, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc6: <instruction> = tuple_access %.loc6_5.2, element0 [template]
// CHECK:STDOUT:   %.loc6_5.3: @F.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc6 [template = %.loc6_5.3 (constants.%.38eedf.2)]
// CHECK:STDOUT:   %.loc7_11.2: %tuple.type.f7a = initialize_action %y.ref.loc7, %T.loc4_16.1, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc7: <instruction> = tuple_access %.loc7_11.2, element0 [template]
// CHECK:STDOUT:   %.loc7_11.3: @F.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc7 [template = %.loc7_11.3 (constants.%.38eedf.3)]
// CHECK:STDOUT:   %.loc5_3.8: <instruction> = compound_member_access_action %y.var, constants.%assoc2 [template]
// CHECK:STDOUT:   %.loc5_3.9: type = type_of_inst %.loc5_3.8 [template = %.loc5_3.9 (constants.%.8cb)]
// CHECK:STDOUT:   %.loc5_3.10: @F.%.loc5_3.9 (%.8cb) = splice_inst %.loc5_3.8 [template = %.loc5_3.10 (constants.%.c23)]
// CHECK:STDOUT:   %.loc5_3.11: <instruction> = call_action (%.loc5_3.3), true [template]
// CHECK:STDOUT:   %.loc5_3.12: type = type_of_inst %.loc5_3.11 [template = %.loc5_3.12 (constants.%.57c)]
// CHECK:STDOUT:   %.loc5_3.13: @F.%.loc5_3.12 (%.57c) = splice_inst %.loc5_3.11 [template = %.loc5_3.13 (constants.%.e63)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @F.%T.loc4_16.1 (%T.67db0b.1)) -> out %return.param: @F.%T.loc4_16.1 (%T.67db0b.1) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %y.var: ref @F.%T.loc4_16.1 (%T.67db0b.1) = var_storage %y.var_patt.loc5_3.1
// CHECK:STDOUT:     %DefaultOrUnformed.facet.loc5_11.1: %DefaultOrUnformed.type = facet_value constants.%T.67db0b.1, (constants.%DefaultOrUnformed.lookup_impl_witness) [template = %DefaultOrUnformed.facet.loc5_11.2 (constants.%DefaultOrUnformed.facet.d51)]
// CHECK:STDOUT:     %.loc5_11.1: %DefaultOrUnformed.type = converted constants.%T.67db0b.1, %DefaultOrUnformed.facet.loc5_11.1 [template = %DefaultOrUnformed.facet.loc5_11.2 (constants.%DefaultOrUnformed.facet.d51)]
// CHECK:STDOUT:     %.loc5_11.2: type = type_of_inst %.loc5_11.6 [template = %.loc5_11.7 (constants.%.77d)]
// CHECK:STDOUT:     %.loc5_11.3: @F.%.loc5_11.7 (%.77d) = splice_inst %.loc5_11.6 [template = %.loc5_11.8 (constants.%.984)]
// CHECK:STDOUT:     %.loc5_11.4: type = type_of_inst %.loc5_11.9 [template = %.loc5_11.10 (constants.%.b48)]
// CHECK:STDOUT:     %.loc5_11.5: @F.%.loc5_11.10 (%.b48) = splice_inst %.loc5_11.9 [template = %.loc5_11.11 (constants.%.e18)]
// CHECK:STDOUT:     %.loc5_3.1: @F.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5 [template = %.loc5_3.7 (constants.%.38eedf.1)]
// CHECK:STDOUT:     assign %y.var, %.loc5_3.1
// CHECK:STDOUT:     %T.ref.loc5: type = name_ref T, %T.loc4_16.2 [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %y: ref @F.%T.loc4_16.1 (%T.67db0b.1) = wrapper_binding y, %y.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %y.patt.loc5_8.1: @F.%pattern_type (%pattern_type.51d1c4.1) = ref_binding_pattern y [template = %y.patt.loc5_8.2 (constants.%y.patt.a54)]
// CHECK:STDOUT:       %y.var_patt.loc5_3.1: @F.%pattern_type (%pattern_type.51d1c4.1) = var_pattern %y.patt.loc5_8.1 [template = %y.var_patt.loc5_3.2 (constants.%y.var_patt.0b4)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %y.ref.loc6: ref @F.%T.loc4_16.1 (%T.67db0b.1) = name_ref y, %y
// CHECK:STDOUT:     %x.ref: @F.%T.loc4_16.1 (%T.67db0b.1) = name_ref x, %x
// CHECK:STDOUT:     %.loc6_5.1: @F.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc6 [template = %.loc6_5.3 (constants.%.38eedf.2)]
// CHECK:STDOUT:     assign %y.ref.loc6, %.loc6_5.1
// CHECK:STDOUT:     %y.ref.loc7: ref @F.%T.loc4_16.1 (%T.67db0b.1) = name_ref y, %y
// CHECK:STDOUT:     %.loc7_11.1: @F.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc7 [template = %.loc7_11.3 (constants.%.38eedf.3)]
// CHECK:STDOUT:     %.loc5_3.2: type = type_of_inst %.loc5_3.8 [template = %.loc5_3.9 (constants.%.8cb)]
// CHECK:STDOUT:     %.loc5_3.3: @F.%.loc5_3.9 (%.8cb) = splice_inst %.loc5_3.8 [template = %.loc5_3.10 (constants.%.c23)]
// CHECK:STDOUT:     %.loc5_3.4: type = type_of_inst %.loc5_3.11 [template = %.loc5_3.12 (constants.%.57c)]
// CHECK:STDOUT:     %.loc5_3.5: @F.%.loc5_3.12 (%.57c) = splice_inst %.loc5_3.11 [template = %.loc5_3.13 (constants.%.e63)]
// CHECK:STDOUT:     return %.loc7_11.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc5(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc5(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc5(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %x.param_patt.loc4_25.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc4_25.2 => constants.%x.patt.260
// CHECK:STDOUT:   %.loc4_33.1 => constants.%.184347.1
// CHECK:STDOUT:   %return.param_patt.loc4_33.2 => constants.%return.param_patt.41d2d9.1
// CHECK:STDOUT:   %return.patt.loc4_30.2 => constants.%return.patt.b39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%i32
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt.loc4_25.2 => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt.loc4_25.2 => constants.%x.patt.e3b
// CHECK:STDOUT:   %.loc4_33.1 => constants.%.795
// CHECK:STDOUT:   %return.param_patt.loc4_33.2 => constants.%return.param_patt.a9a
// CHECK:STDOUT:   %return.patt.loc4_30.2 => constants.%return.patt.e1b
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.f8a
// CHECK:STDOUT:   %y.patt.loc5_8.2 => constants.%y.patt.479
// CHECK:STDOUT:   %y.var_patt.loc5_3.2 => constants.%y.var_patt.634
// CHECK:STDOUT:   %DefaultOrUnformed.lookup_impl_witness => constants.%DefaultOrUnformed.impl_witness.193
// CHECK:STDOUT:   %DefaultOrUnformed.facet.loc5_11.2 => constants.%DefaultOrUnformed.facet.f65
// CHECK:STDOUT:   %.loc5_11.6 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc5_11.7 => constants.%.8b7
// CHECK:STDOUT:   %.loc5_11.8 => constants.%T.as_type.as.DefaultOrUnformed.impl.Op.72d
// CHECK:STDOUT:   %.loc5_11.9 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc5_11.10 => constants.%i32
// CHECK:STDOUT:   %.loc5_11.11 => <not constant>
// CHECK:STDOUT:   %.loc5_3.6 => constants.%tuple.24243e.1
// CHECK:STDOUT:   %tuple.elem0.loc5 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc5_3.7 => <not constant>
// CHECK:STDOUT:   %.loc6_5.2 => constants.%tuple.24243e.2
// CHECK:STDOUT:   %tuple.elem0.loc6 => constants.%inst.splice_block.426619.4
// CHECK:STDOUT:   %.loc6_5.3 => <not constant>
// CHECK:STDOUT:   %.loc7_11.2 => constants.%tuple.24243e.3
// CHECK:STDOUT:   %tuple.elem0.loc7 => constants.%inst.splice_block.426619.5
// CHECK:STDOUT:   %.loc7_11.3 => <not constant>
// CHECK:STDOUT:   %.loc5_3.8 => constants.%inst.splice_block.426619.6
// CHECK:STDOUT:   %.loc5_3.9 => <bound method>
// CHECK:STDOUT:   %.loc5_3.10 => <not constant>
// CHECK:STDOUT:   %.loc5_3.11 => constants.%inst.call
// CHECK:STDOUT:   %.loc5_3.12 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc5_3.13 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- template_interface_concrete_self.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %U.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern U, 0, template [template]
// CHECK:STDOUT:   %U.67d: type = symbolic_binding U, 0, template [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %.184347.1: Core.Form = init_form %U.67d [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %U.67d [template]
// CHECK:STDOUT:   %return.param_patt.41d2d9.1: %pattern_type.51d1c4.1 = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.b39: %pattern_type.51d1c4.1 = return_slot_pattern %return.param_patt.41d2d9.1, %U.67d [template]
// CHECK:STDOUT:   %Widen.type: type = fn_type @Widen [concrete]
// CHECK:STDOUT:   %Widen: %Widen.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %U.67d [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.38e: %U.67d = splice_inst @Widen.%tuple.elem0 [template]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %complete_type.4a1: <witness> = complete_type_witness %i64.builtin [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.2: type = class_type @Int, @Int(%To) [symbolic]
// CHECK:STDOUT:   %facet_type.037: type = facet_type <@IntFitsIn, @IntFitsIn(%Int.67af24.2) & @AnyInt> [symbolic]
// CHECK:STDOUT:   %From.6a4: %facet_type.037 = symbolic_binding From, 1 [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7fa: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%To, %From.6a4) [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.643: %From.as_type.as.ImplicitAs.impl.Convert.type.7fa = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.30a: type = facet_type <@IntFitsIn, @IntFitsIn(%i64) & @AnyInt> [concrete]
// CHECK:STDOUT:   %custom_witness: <witness> = custom_witness (), @IntFitsIn, @IntFitsIn(%i64) [concrete]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.type.f15: type = fn_type @Int.as.AnyInt.impl.AsInt, @Int.as.AnyInt.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.d10: %Int.as.AnyInt.impl.AsInt.type.f15 = struct_value () [symbolic]
// CHECK:STDOUT:   %AnyInt.impl_witness.48c: <witness> = impl_witness imports.%AnyInt.impl_witness_table, @Int.as.AnyInt.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.30a = facet_value %i32, (%custom_witness, %AnyInt.impl_witness.48c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.8d3: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.992, @From.as_type.as.ImplicitAs.impl(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7ba: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.15a: %From.as_type.as.ImplicitAs.impl.Convert.type.7ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.221 = facet_value %i32, (%ImplicitAs.impl_witness.8d3) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.ed0: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.dbf: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.ed0, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %From.as_type.as.ImplicitAs.impl.Convert.15a, @From.as_type.as.ImplicitAs.impl.Convert(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %inst.splice_block: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.e28: init %i64 = splice_block %From.as_type.as.ImplicitAs.impl.Convert.call {
// CHECK:STDOUT:       %impl.elem0.5be: %.dbf = impl_witness_access %ImplicitAs.impl_witness.8d3, element0 [concrete = %From.as_type.as.ImplicitAs.impl.Convert.15a]
// CHECK:STDOUT:       %bound_method.3e8: <bound method> = bound_method @Widen.%x.ref, %impl.elem0.5be
// CHECK:STDOUT:       %specific_fn: <specific function> = specific_function %impl.elem0.5be, @From.as_type.as.ImplicitAs.impl.Convert(%int_64, %facet_value) [concrete = %From.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:       %bound_method.3a3: <bound method> = bound_method @Widen.%x.ref, %specific_fn
// CHECK:STDOUT:       %From.as_type.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.3a3(@Widen.%x.ref)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.242: %tuple.type.f7a = tuple_value (%inst.splice_block) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.2a4: @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert.type (%From.as_type.as.ImplicitAs.impl.Convert.type.7fa) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert (constants.%From.as_type.as.ImplicitAs.impl.Convert.643)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.992 = impl_witness_table (%Core.import_ref.2a4), @From.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.47b: Core.IntLiteral = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%N (constants.%N)]
// CHECK:STDOUT:   %Core.import_ref.49b: @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt.type (%Int.as.AnyInt.impl.AsInt.type.f15) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt (constants.%Int.as.AnyInt.impl.AsInt.d10)]
// CHECK:STDOUT:   %AnyInt.impl_witness_table = impl_witness_table (%Core.import_ref.47b, %Core.import_ref.49b), @Int.as.AnyInt.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Widen.decl: %Widen.type = fn_decl @Widen [concrete = constants.%Widen] {
// CHECK:STDOUT:     %U.patt.loc4_20.1: %pattern_type.9a5 = symbolic_binding_pattern U, 0, template [template = %U.patt.loc4_20.2 (constants.%U.patt.3a0)]
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt.loc4_39.1: @Widen.%pattern_type (%pattern_type.51d1c4.1) = out_param_pattern [template = %return.param_patt.loc4_39.2 (constants.%return.param_patt.41d2d9.1)]
// CHECK:STDOUT:     %return.patt.loc4_36.1: @Widen.%pattern_type (%pattern_type.51d1c4.1) = return_slot_pattern %return.param_patt.loc4_39.1, %U.ref [template = %return.patt.loc4_36.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %U.ref: type = name_ref U, %U.loc4_20.2 [template = %U.loc4_20.1 (constants.%U.67d)]
// CHECK:STDOUT:     %.loc4_39.2: Core.Form = init_form %U.ref [template = %.loc4_39.1 (constants.%.184347.1)]
// CHECK:STDOUT:     %.loc4_22.1: type = splice_block %.loc4_22.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_22.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %U.loc4_20.2: type = symbolic_binding U, 0, template [template = %U.loc4_20.1 (constants.%U.67d)]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref @Widen.%U.loc4_20.1 (%U.67d) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Widen.%U.loc4_20.1 (%U.67d) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Widen(%U.loc4_20.2: type) {
// CHECK:STDOUT:   %U.patt.loc4_20.2: %pattern_type.9a5 = symbolic_binding_pattern U, 0, template [template = %U.patt.loc4_20.2 (constants.%U.patt.3a0)]
// CHECK:STDOUT:   %U.loc4_20.1: type = symbolic_binding U, 0, template [template = %U.loc4_20.1 (constants.%U.67d)]
// CHECK:STDOUT:   %.loc4_39.1: Core.Form = init_form %U.loc4_20.1 [template = %.loc4_39.1 (constants.%.184347.1)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %U.loc4_20.1 [template = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %return.param_patt.loc4_39.2: @Widen.%pattern_type (%pattern_type.51d1c4.1) = out_param_pattern [template = %return.param_patt.loc4_39.2 (constants.%return.param_patt.41d2d9.1)]
// CHECK:STDOUT:   %return.patt.loc4_36.2: @Widen.%pattern_type (%pattern_type.51d1c4.1) = return_slot_pattern %return.param_patt.loc4_39.2, %U.loc4_20.1 [template = %return.patt.loc4_36.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %U.loc4_20.1 [template = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc5_11.2: %tuple.type.f7a = initialize_action %x.ref, %U.loc4_20.1, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc5_11.2, element0 [template]
// CHECK:STDOUT:   %.loc5_11.3: @Widen.%U.loc4_20.1 (%U.67d) = splice_inst %tuple.elem0 [template = %.loc5_11.3 (constants.%.38e)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: %i32) -> out %return.param: @Widen.%U.loc4_20.1 (%U.67d) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:     %.loc5_11.1: @Widen.%U.loc4_20.1 (%U.67d) = splice_inst %tuple.elem0 [template = %.loc5_11.3 (constants.%.38e)]
// CHECK:STDOUT:     return %.loc5_11.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Widen(constants.%U.67d) {
// CHECK:STDOUT:   %U.patt.loc4_20.2 => constants.%U.patt.3a0
// CHECK:STDOUT:   %U.loc4_20.1 => constants.%U.67d
// CHECK:STDOUT:   %.loc4_39.1 => constants.%.184347.1
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %return.param_patt.loc4_39.2 => constants.%return.param_patt.41d2d9.1
// CHECK:STDOUT:   %return.patt.loc4_36.2 => constants.%return.patt.b39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Widen(constants.%i64) {
// CHECK:STDOUT:   %U.patt.loc4_20.2 => constants.%U.patt.3a0
// CHECK:STDOUT:   %U.loc4_20.1 => constants.%i64
// CHECK:STDOUT:   %.loc4_39.1 => constants.%.bc0
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.f57
// CHECK:STDOUT:   %return.param_patt.loc4_39.2 => constants.%return.param_patt.cfc
// CHECK:STDOUT:   %return.patt.loc4_36.2 => constants.%return.patt.178
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.4a1
// CHECK:STDOUT:   %.loc5_11.2 => constants.%tuple.242
// CHECK:STDOUT:   %tuple.elem0 => constants.%inst.splice_block
// CHECK:STDOUT:   %.loc5_11.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- template_interface_final_impl.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %Tag.type.9ab: type = generic_interface_type @Tag [concrete]
// CHECK:STDOUT:   %Tag.generic: %Tag.type.9ab = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %U.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern U, 0, template [template]
// CHECK:STDOUT:   %U.67d: type = symbolic_binding U, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.3: type = pattern_type %U.67d [template]
// CHECK:STDOUT:   %u.param_patt.684: %pattern_type.51d1c4.3 = value_param_pattern [template]
// CHECK:STDOUT:   %u.patt.760: %pattern_type.51d1c4.3 = wrapper_binding_pattern u, %u.param_patt.684 [template]
// CHECK:STDOUT:   %Get.type: type = fn_type @Get [concrete]
// CHECK:STDOUT:   %Get: %Get.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %U.67d [template]
// CHECK:STDOUT:   %Tag.type.44345c.2: type = facet_type <@Tag, @Tag(%U.67d)> [template]
// CHECK:STDOUT:   %Tag.lookup_impl_witness: <witness> = lookup_impl_witness %i32, @Tag, @Tag(%U.67d) [template]
// CHECK:STDOUT:   %Tag.facet.946: %Tag.type.44345c.2 = facet_value %i32, (%Tag.lookup_impl_witness) [template]
// CHECK:STDOUT:   %.80a: type = type_of_inst @Get.%.loc12_25.3 [template]
// CHECK:STDOUT:   %.cfe: %.80a = splice_inst @Get.%.loc12_25.3 [template]
// CHECK:STDOUT:   %.bbc: type = type_of_inst @Get.%.loc12_29.3 [template]
// CHECK:STDOUT:   %.6a3: %.bbc = splice_inst @Get.%.loc12_29.3 [template]
// CHECK:STDOUT:   %.28a: %i32 = splice_inst @Get.%.loc12_30.2 [template]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %u.param_patt.56f: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt.0d7: %pattern_type.831 = wrapper_binding_pattern u, %u.param_patt.56f [concrete]
// CHECK:STDOUT:   %complete_type.127: <witness> = complete_type_witness bool [concrete]
// CHECK:STDOUT:   %Tag.type.dbe: type = facet_type <@Tag, @Tag(bool)> [concrete]
// CHECK:STDOUT:   %Tag.impl_witness.693: <witness> = impl_witness @i32.as.Tag.impl.%Tag.impl_witness_table, @i32.as.Tag.impl(bool) [concrete]
// CHECK:STDOUT:   %Tag.assoc_type.1f2: type = assoc_entity_type @Tag, @Tag(bool) [concrete]
// CHECK:STDOUT:   %assoc0.6cb: %Tag.assoc_type.1f2 = assoc_entity element0, @Tag.WithSelf.%Tag.WithSelf.Id.decl [concrete]
// CHECK:STDOUT:   %i32.as.Tag.impl.Id.type.011: type = fn_type @i32.as.Tag.impl.Id, @i32.as.Tag.impl(bool) [concrete]
// CHECK:STDOUT:   %i32.as.Tag.impl.Id.3e3: %i32.as.Tag.impl.Id.type.011 = struct_value () [concrete]
// CHECK:STDOUT:   %Tag.facet.4f7: %Tag.type.dbe = facet_value %i32, (%Tag.impl_witness.693) [concrete]
// CHECK:STDOUT:   %Tag.WithSelf.Id.type.fc2: type = fn_type @Tag.WithSelf.Id, @Tag.WithSelf(bool, %Tag.facet.4f7) [concrete]
// CHECK:STDOUT:   %.4d1: type = fn_type_with_self_type %Tag.WithSelf.Id.type.fc2, %Tag.facet.4f7 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.3c3: %.4d1 = splice_block %impl.elem0.2af [concrete = %i32.as.Tag.impl.Id.3e3] {
// CHECK:STDOUT:       %as_type: type = facet_access_type %Tag.facet.4f7 [concrete = %i32]
// CHECK:STDOUT:       %.ae0: type = converted %Tag.facet.4f7, %as_type [concrete = %i32]
// CHECK:STDOUT:       %.01a: %Tag.assoc_type.1f2 = specific_constant @Tag.WithSelf.%assoc0.loc4_17.1, @Tag.WithSelf(bool, %Tag.facet.4f7) [concrete = %assoc0.6cb]
// CHECK:STDOUT:       %Id.ref: %Tag.assoc_type.1f2 = name_ref Id, %.01a [concrete = %assoc0.6cb]
// CHECK:STDOUT:       %impl.elem0.2af: %.4d1 = impl_witness_access %Tag.impl_witness.693, element0 [concrete = %i32.as.Tag.impl.Id.3e3]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.176: init %i32 = splice_block %i32.as.Tag.impl.Id.call {
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %i32.as.Tag.impl.Id.call: init %i32 = call %i32.as.Tag.impl.Id.specific_fn.bd6790.2()
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.7e3: init %i32 = splice_block %.176 {}
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Get.decl: %Get.type = fn_decl @Get [concrete = constants.%Get] {
// CHECK:STDOUT:     %U.patt.loc11_18.1: %pattern_type.9a5 = symbolic_binding_pattern U, 0, template [template = %U.patt.loc11_18.2 (constants.%U.patt.3a0)]
// CHECK:STDOUT:     %u.param_patt.loc11_34.1: @Get.%pattern_type (%pattern_type.51d1c4.3) = value_param_pattern [template = %u.param_patt.loc11_34.2 (constants.%u.param_patt.684)]
// CHECK:STDOUT:     %u.patt.loc11_34.1: @Get.%pattern_type (%pattern_type.51d1c4.3) = wrapper_binding_pattern u, %u.param_patt.loc11_34.1 [template = %u.patt.loc11_34.2 (constants.%u.patt.760)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc11 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_42: Core.Form = init_form %i32.loc11 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc11_20.1: type = splice_block %.loc11_20.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc11_20.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %U.loc11_18.2: type = symbolic_binding U, 0, template [template = %U.loc11_18.1 (constants.%U.67d)]
// CHECK:STDOUT:     %u.param: @Get.%U.loc11_18.1 (%U.67d) = value_param call_param0
// CHECK:STDOUT:     %U.ref.loc11: type = name_ref U, %U.loc11_18.2 [template = %U.loc11_18.1 (constants.%U.67d)]
// CHECK:STDOUT:     %u: @Get.%U.loc11_18.1 (%U.67d) = wrapper_binding u, %u.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Get(%U.loc11_18.2: type) {
// CHECK:STDOUT:   %U.patt.loc11_18.2: %pattern_type.9a5 = symbolic_binding_pattern U, 0, template [template = %U.patt.loc11_18.2 (constants.%U.patt.3a0)]
// CHECK:STDOUT:   %U.loc11_18.1: type = symbolic_binding U, 0, template [template = %U.loc11_18.1 (constants.%U.67d)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %U.loc11_18.1 [template = %pattern_type (constants.%pattern_type.51d1c4.3)]
// CHECK:STDOUT:   %u.param_patt.loc11_34.2: @Get.%pattern_type (%pattern_type.51d1c4.3) = value_param_pattern [template = %u.param_patt.loc11_34.2 (constants.%u.param_patt.684)]
// CHECK:STDOUT:   %u.patt.loc11_34.2: @Get.%pattern_type (%pattern_type.51d1c4.3) = wrapper_binding_pattern u, %u.param_patt.loc11_34.2 [template = %u.patt.loc11_34.2 (constants.%u.patt.760)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %U.loc11_18.1 [template = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %Tag.type.loc12_23.2: type = facet_type <@Tag, @Tag(%U.loc11_18.1)> [template = %Tag.type.loc12_23.2 (constants.%Tag.type.44345c.2)]
// CHECK:STDOUT:   %Tag.lookup_impl_witness: <witness> = lookup_impl_witness constants.%i32, @Tag, @Tag(%U.loc11_18.1) [template = %Tag.lookup_impl_witness (constants.%Tag.lookup_impl_witness)]
// CHECK:STDOUT:   %Tag.facet.loc12_15.2: @Get.%Tag.type.loc12_23.2 (%Tag.type.44345c.2) = facet_value constants.%i32, (%Tag.lookup_impl_witness) [template = %Tag.facet.loc12_15.2 (constants.%Tag.facet.946)]
// CHECK:STDOUT:   %.loc12_25.3: <instruction> = access_member_action %.loc12_15, Id [template]
// CHECK:STDOUT:   %.loc12_25.4: type = type_of_inst %.loc12_25.3 [template = %.loc12_25.4 (constants.%.80a)]
// CHECK:STDOUT:   %.loc12_25.5: @Get.%.loc12_25.4 (%.80a) = splice_inst %.loc12_25.3 [template = %.loc12_25.5 (constants.%.cfe)]
// CHECK:STDOUT:   %.loc12_29.3: <instruction> = call_action (%.loc12_25.2), false [template]
// CHECK:STDOUT:   %.loc12_29.4: type = type_of_inst %.loc12_29.3 [template = %.loc12_29.4 (constants.%.bbc)]
// CHECK:STDOUT:   %.loc12_29.5: @Get.%.loc12_29.4 (%.bbc) = splice_inst %.loc12_29.3 [template = %.loc12_29.5 (constants.%.6a3)]
// CHECK:STDOUT:   %.loc12_30.2: <instruction> = convert_action %.loc12_29.2, constants.%i32, element10 [template]
// CHECK:STDOUT:   %.loc12_30.3: %i32 = splice_inst %.loc12_30.2 [template = %.loc12_30.3 (constants.%.28a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%u.param: @Get.%U.loc11_18.1 (%U.67d)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Tag.ref: %Tag.type.9ab = name_ref Tag, file.%Tag.decl [concrete = constants.%Tag.generic]
// CHECK:STDOUT:     %U.ref.loc12: type = name_ref U, %U.loc11_18.2 [template = %U.loc11_18.1 (constants.%U.67d)]
// CHECK:STDOUT:     %Tag.type.loc12_23.1: type = facet_type <@Tag, @Tag(constants.%U.67d)> [template = %Tag.type.loc12_23.2 (constants.%Tag.type.44345c.2)]
// CHECK:STDOUT:     %Tag.facet.loc12_15.1: @Get.%Tag.type.loc12_23.2 (%Tag.type.44345c.2) = facet_value %i32.loc12, (constants.%Tag.lookup_impl_witness) [template = %Tag.facet.loc12_15.2 (constants.%Tag.facet.946)]
// CHECK:STDOUT:     %.loc12_15: @Get.%Tag.type.loc12_23.2 (%Tag.type.44345c.2) = converted %i32.loc12, %Tag.facet.loc12_15.1 [template = %Tag.facet.loc12_15.2 (constants.%Tag.facet.946)]
// CHECK:STDOUT:     %.loc12_25.1: type = type_of_inst %.loc12_25.3 [template = %.loc12_25.4 (constants.%.80a)]
// CHECK:STDOUT:     %.loc12_25.2: @Get.%.loc12_25.4 (%.80a) = splice_inst %.loc12_25.3 [template = %.loc12_25.5 (constants.%.cfe)]
// CHECK:STDOUT:     %.loc12_29.1: type = type_of_inst %.loc12_29.3 [template = %.loc12_29.4 (constants.%.bbc)]
// CHECK:STDOUT:     %.loc12_29.2: @Get.%.loc12_29.4 (%.bbc) = splice_inst %.loc12_29.3 [template = %.loc12_29.5 (constants.%.6a3)]
// CHECK:STDOUT:     %.loc12_30.1: %i32 = splice_inst %.loc12_30.2 [template = %.loc12_30.3 (constants.%.28a)]
// CHECK:STDOUT:     return %.loc12_30.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Get(constants.%U.67d) {
// CHECK:STDOUT:   %U.patt.loc11_18.2 => constants.%U.patt.3a0
// CHECK:STDOUT:   %U.loc11_18.1 => constants.%U.67d
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.3
// CHECK:STDOUT:   %u.param_patt.loc11_34.2 => constants.%u.param_patt.684
// CHECK:STDOUT:   %u.patt.loc11_34.2 => constants.%u.patt.760
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Get(bool) {
// CHECK:STDOUT:   %U.patt.loc11_18.2 => constants.%U.patt.3a0
// CHECK:STDOUT:   %U.loc11_18.1 => bool
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.831
// CHECK:STDOUT:   %u.param_patt.loc11_34.2 => constants.%u.param_patt.56f
// CHECK:STDOUT:   %u.patt.loc11_34.2 => constants.%u.patt.0d7
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.127
// CHECK:STDOUT:   %Tag.type.loc12_23.2 => constants.%Tag.type.dbe
// CHECK:STDOUT:   %Tag.lookup_impl_witness => constants.%Tag.impl_witness.693
// CHECK:STDOUT:   %Tag.facet.loc12_15.2 => constants.%Tag.facet.4f7
// CHECK:STDOUT:   %.loc12_25.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc12_25.4 => constants.%.4d1
// CHECK:STDOUT:   %.loc12_25.5 => constants.%i32.as.Tag.impl.Id.3e3
// CHECK:STDOUT:   %.loc12_29.3 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc12_29.4 => constants.%i32
// CHECK:STDOUT:   %.loc12_29.5 => <not constant>
// CHECK:STDOUT:   %.loc12_30.2 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc12_30.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
