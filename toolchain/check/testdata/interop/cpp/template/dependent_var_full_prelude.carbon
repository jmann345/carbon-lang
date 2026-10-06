// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/template/dependent_var_full_prelude.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/template/dependent_var_full_prelude.carbon

// Fork (UA-2, fork/upstream/plan.md §0.6 W-043 row): generic_call.carbon's
// shape under the REAL prelude. generic_call.carbon passes under
// min_prelude/convert.carbon, whose parts/default.carbon:19 declares an
// unconstrained `impl forall [T: type] T as DefaultOrUnformed`; the real
// prelude's blanket impl requires `T: UnformedInit` (core/prelude/default
// .carbon:52), which cannot be decided for a template-dependent type, so an
// UNINITIALIZED dependent `var` fails at its default initialization. The
// conformance programs interop/cpp_template_symbolic_arg.carbon and
// cpp_template_on_carbon_generic.carbon measured this on hosted run
// 37407530104 and on upstream nightly 2026.09.28; this file pins both the
// failing shape and the shape that works (initialization through the C++
// default constructor, class/import/template.carbon's pin).

// --- header.h

struct X {};

template<typename T> struct S {};

// --- fail_unformed_dependent_var.carbon

library "[[@TEST_NAME]]";

import Cpp library "header.h";

// Predicted: `ConversionFailureTypeToFacet` "cannot convert type `<splice of
// ...>` into type implementing `Core.DefaultOrUnformed`" at the `var`.
fn F[T: type](unused x: T) {
  // CHECK:STDERR: fail_unformed_dependent_var.carbon:[[@LINE+4]]:3: error: cannot convert type `<splice of <cannot stringify inst69000041: {kind: ConvertToValueAction, arg0: inst6900003E, arg1: inst(TypeType), type: type(inst(InstType))}>>` into type implementing `Core.DefaultOrUnformed` [ConversionFailureTypeToFacet]
  // CHECK:STDERR:   var unused v: Cpp.S(T);
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var unused v: Cpp.S(T);
}

fn G() {
  F({} as Cpp.X);
}

// --- ctor_init_dependent_var.carbon

library "[[@TEST_NAME]]";

import Cpp library "header.h";

// Predicted: no diagnostic; the constructor call and the return are
// template-dependent actions instantiated for `F(Cpp.X)`.
//@dump-sem-ir-begin
fn F[T: type](unused x: T) -> Cpp.S(T) {
  var v: Cpp.S(T) = Cpp.S(T).S();
  return v;
}
//@dump-sem-ir-end

fn G() -> Cpp.S(Cpp.X) {
  return F({} as Cpp.X);
}

// CHECK:STDOUT: --- ctor_init_dependent_var.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.51d: type = pattern_type %T.67d [symbolic]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d = wrapper_binding_pattern x, %x.param_patt.91d [symbolic]
// CHECK:STDOUT:   %S.type: type = cpp_type_template_type S [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %S.template: %S.type = struct_value () [concrete]
// CHECK:STDOUT:   %.a92: type = template_inst %T.67d [template]
// CHECK:STDOUT:   %.d46302.1: type = type_of_inst @F.%.loc9_38.1 [template]
// CHECK:STDOUT:   %.de1469.1: %.d46302.1 = splice_inst @F.%.loc9_38.1 [template]
// CHECK:STDOUT:   %.5372ba.1: type = splice_inst @F.%.loc9_38.4 [template]
// CHECK:STDOUT:   %.cd79f1.1: Core.Form = init_form %.5372ba.1 [template]
// CHECK:STDOUT:   %pattern_type.fcb8f3.1: type = pattern_type %.5372ba.1 [template]
// CHECK:STDOUT:   %return.param_patt.2e9ac5.1: %pattern_type.fcb8f3.1 = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.7fc6a1.1: %pattern_type.fcb8f3.1 = return_slot_pattern %return.param_patt.2e9ac5.1, %.5372ba.1 [template]
// CHECK:STDOUT:   %.961: <instruction> = call_action (%S.template, %.a92), false [template]
// CHECK:STDOUT:   %.7d1: type = type_of_inst %.961 [template]
// CHECK:STDOUT:   %.774: %.7d1 = splice_inst %.961 [template]
// CHECK:STDOUT:   %.c8c: <instruction> = convert_to_value_action %.774, type [template]
// CHECK:STDOUT:   %.5372ba.2: type = splice_inst %.c8c [template]
// CHECK:STDOUT:   %.cd79f1.2: Core.Form = init_form %.5372ba.2 [template]
// CHECK:STDOUT:   %pattern_type.fcb8f3.2: type = pattern_type %.5372ba.2 [template]
// CHECK:STDOUT:   %return.param_patt.2e9ac5.2: %pattern_type.fcb8f3.2 = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.7fc6a1.2: %pattern_type.fcb8f3.2 = return_slot_pattern %return.param_patt.2e9ac5.2, %.5372ba.2 [template]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [symbolic]
// CHECK:STDOUT:   %require_complete.cb0614.1: <witness> = require_complete_type %.5372ba.1 [template]
// CHECK:STDOUT:   %.d46302.2: type = type_of_inst @F.%.loc10_17.5 [template]
// CHECK:STDOUT:   %.de1469.2: %.d46302.2 = splice_inst @F.%.loc10_17.5 [template]
// CHECK:STDOUT:   %.5372ba.3: type = splice_inst @F.%.loc10_17.8 [template]
// CHECK:STDOUT:   %require_complete.cb0614.2: <witness> = require_complete_type %.5372ba.3 [template]
// CHECK:STDOUT:   %pattern_type.fcb8f3.3: type = pattern_type %.5372ba.3 [template]
// CHECK:STDOUT:   %v.patt.126: %pattern_type.fcb8f3.3 = ref_binding_pattern v [template]
// CHECK:STDOUT:   %v.var_patt.768: %pattern_type.fcb8f3.3 = var_pattern %v.patt.126 [template]
// CHECK:STDOUT:   %.d46302.3: type = type_of_inst @F.%.loc10_28.3 [template]
// CHECK:STDOUT:   %.de1469.3: %.d46302.3 = splice_inst @F.%.loc10_28.3 [template]
// CHECK:STDOUT:   %.bdb: type = type_of_inst @F.%.loc10_29.3 [template]
// CHECK:STDOUT:   %.e48: %.bdb = splice_inst @F.%.loc10_29.3 [template]
// CHECK:STDOUT:   %.5d9: type = type_of_inst @F.%.loc10_32.3 [template]
// CHECK:STDOUT:   %.3a4: %.5d9 = splice_inst @F.%.loc10_32.3 [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.5d6323.1: %.5372ba.3 = splice_inst @F.%tuple.elem0.loc10 [template]
// CHECK:STDOUT:   %.5d6323.2: %.5372ba.1 = splice_inst @F.%tuple.elem0.loc11 [template]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Self.0e7: %Destroy.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.4e5: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Self.0e7) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.4a0: %Destroy.WithSelf.SelfDestruct.type.4e5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.assoc_type: type = assoc_entity_type @Destroy [concrete]
// CHECK:STDOUT:   %assoc2: %Destroy.assoc_type = assoc_entity element2, imports.%Core.import_ref.71d [concrete]
// CHECK:STDOUT:   %.8cb: type = type_of_inst @F.%.loc10_3.8 [template]
// CHECK:STDOUT:   %.c23: %.8cb = splice_inst @F.%.loc10_3.8 [template]
// CHECK:STDOUT:   %.57c: type = type_of_inst @F.%.loc10_3.11 [template]
// CHECK:STDOUT:   %.e63: %.57c = splice_inst @F.%.loc10_3.11 [template]
// CHECK:STDOUT:   %X: type = class_type @X [concrete]
// CHECK:STDOUT:   %S: type = class_type @S [concrete]
// CHECK:STDOUT:   %.cb5: Core.Form = init_form %S [concrete]
// CHECK:STDOUT:   %pattern_type.981: type = pattern_type %S [concrete]
// CHECK:STDOUT:   %return.param_patt.c2b: %pattern_type.981 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.36a: %pattern_type.981 = return_slot_pattern %return.param_patt.c2b, %S [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness %empty_struct_type [concrete]
// CHECK:STDOUT:   %pattern_type.fa7: type = pattern_type %X [concrete]
// CHECK:STDOUT:   %x.param_patt.468: %pattern_type.fa7 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.af8: %pattern_type.fa7 = wrapper_binding_pattern x, %x.param_patt.468 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.788c94.1: type = splice_block imports.%S.decl [concrete = %S] {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.895013.1: type = splice_block %S [concrete = %S] {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.788c94.2: type = splice_block imports.%S.decl [concrete = %S] {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.4: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.895013.2: type = splice_block %S [concrete = %S] {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.patt.5fa: %pattern_type.981 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt.e69: %pattern_type.981 = var_pattern %v.patt.5fa [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.5: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.788c94.3: type = splice_block imports.%S.decl [concrete = %S] {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %S.S.cpp_overload_set.type: type = cpp_overload_set_type @S.S.cpp_overload_set [concrete]
// CHECK:STDOUT:   %S.S.cpp_overload_set.value: %S.S.cpp_overload_set.type = cpp_overload_set_value @S.S.cpp_overload_set [concrete]
// CHECK:STDOUT:   %inst.name_ref: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %S.ref: %S.S.cpp_overload_set.type = name_ref S, imports.%S.S.cpp_overload_set.value [concrete = %S.S.cpp_overload_set.value]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %ptr.c75: type = ptr_type %S [concrete]
// CHECK:STDOUT:   %S__carbon_thunk.type.a385a5.1: type = fn_type @S__carbon_thunk.1 [concrete]
// CHECK:STDOUT:   %S__carbon_thunk.3db2cd.1: %S__carbon_thunk.type.a385a5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.6: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.d3e: init %S = splice_block %.9eb {
// CHECK:STDOUT:       %.46b016.2: ref %S = specific_inst @F.%v.var, @F(%X)
// CHECK:STDOUT:       %addr.219: %ptr.c75 = addr_of %.46b016.2
// CHECK:STDOUT:       %S__carbon_thunk.call.626: init %empty_tuple.type = call imports.%S__carbon_thunk.decl.377064.1(%addr.219)
// CHECK:STDOUT:       %.9eb: init %S to %.46b016.2 = mark_in_place_init %S__carbon_thunk.call.626
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.splice_block.426619.7: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.a17: init %S = splice_block %.d3e {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.1: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.7) [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %S.S.type.0e9520.2: type = fn_type @S.S.2 [concrete]
// CHECK:STDOUT:   %S.S.ce82cd.2: %S.S.type.0e9520.2 = struct_value () [concrete]
// CHECK:STDOUT:   %const.91b: type = const_type %S [concrete]
// CHECK:STDOUT:   %ptr.0dc: type = ptr_type %const.91b [concrete]
// CHECK:STDOUT:   %S__carbon_thunk.type.a385a5.2: type = fn_type @S__carbon_thunk.2 [concrete]
// CHECK:STDOUT:   %S__carbon_thunk.3db2cd.2: %S__carbon_thunk.type.a385a5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %S.Op.type: type = fn_type @S.Op [concrete]
// CHECK:STDOUT:   %S.Op: %S.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.d0d: <witness> = custom_witness (%S.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.1b5: %Copy.type = facet_value %S, (%custom_witness.d0d) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.fda: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1b5) [concrete]
// CHECK:STDOUT:   %.eb9: type = fn_type_with_self_type %Copy.WithSelf.Op.type.fda, %Copy.facet.1b5 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.8: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.a4d: init %S = splice_block %.71b {
// CHECK:STDOUT:       %.2cd: ref %S = specific_inst @F.%v.ref, @F(%X)
// CHECK:STDOUT:       %.a90: %S = acquire_value %.2cd
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %impl.elem0.430: %.eb9 = impl_witness_access %custom_witness.d0d, element0 [concrete = %S.Op]
// CHECK:STDOUT:       %bound_method.79a: <bound method> = bound_method %.a90, %impl.elem0.430
// CHECK:STDOUT:       %.746: ref %S = temporary_storage
// CHECK:STDOUT:       %Op.ref: %S.S.type.0e9520.2 = name_ref Op, imports.%S.S.decl.11684c.2 [concrete = %S.S.ce82cd.2]
// CHECK:STDOUT:       %.0b8: ref %S = specific_inst @F.%return.param, @F(%X)
// CHECK:STDOUT:       %.62c: ref %S = value_as_ref %.a90
// CHECK:STDOUT:       %addr.4e3: %ptr.c75 = addr_of %.62c
// CHECK:STDOUT:       %.f32: %ptr.0dc = as_compatible %addr.4e3
// CHECK:STDOUT:       %.f0b: %ptr.0dc = converted %addr.4e3, %.f32
// CHECK:STDOUT:       %addr.7c9: %ptr.c75 = addr_of %.0b8
// CHECK:STDOUT:       %S__carbon_thunk.call.729: init %empty_tuple.type = call imports.%S__carbon_thunk.decl.377064.2(%.f0b, %addr.7c9)
// CHECK:STDOUT:       %.71b: init %S to %.0b8 = mark_in_place_init %S__carbon_thunk.call.729
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.2: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.8) [concrete]
// CHECK:STDOUT:   %self.param_patt.471: %pattern_type.981 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f0: %pattern_type.981 = wrapper_binding_pattern self, %self.param_patt.471 [concrete]
// CHECK:STDOUT:   %S.cpp_destructor.type: type = fn_type @S.cpp_destructor [concrete]
// CHECK:STDOUT:   %S.cpp_destructor: %S.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc10 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc10 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.842d8c.2: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.2, %S.cpp_destructor, %Destroy.WithSelf.SelfDestruct.db3fdb.2), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.008: %Destroy.type = facet_value %S, (%custom_witness.842d8c.2) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.4e8: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.008) [concrete]
// CHECK:STDOUT:   %.162: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.4e8, %Destroy.facet.008 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.9: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.038: <bound method> = splice_block %bound_method.085 {
// CHECK:STDOUT:       %.46b016.1: ref %S = specific_inst @F.%v.var, @F(%X)
// CHECK:STDOUT:       %impl.elem2: %.162 = impl_witness_access %custom_witness.842d8c.2, element2 [concrete = %Destroy.WithSelf.SelfDestruct.db3fdb.2]
// CHECK:STDOUT:       %bound_method.085: <bound method> = bound_method %.46b016.1, %impl.elem2
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.call: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %.038(%.46b016.1)
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .S = %S.template
// CHECK:STDOUT:     .X = %X.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %S.template: %S.type = struct_value () [concrete = constants.%S.template]
// CHECK:STDOUT:   %Core.import_ref.71d: @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct.type (%Destroy.WithSelf.SelfDestruct.type.4e5) = import_ref Core//prelude/destroy, loc{{\d+_\d+}}, loaded [symbolic = @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct (constants.%Destroy.WithSelf.SelfDestruct.4a0)]
// CHECK:STDOUT:   %X.decl: type = class_decl @X [concrete = constants.%X] {} {}
// CHECK:STDOUT:   %S.decl: type = class_decl @S [concrete = constants.%S] {} {}
// CHECK:STDOUT:   %S.S.cpp_overload_set.value: %S.S.cpp_overload_set.type = cpp_overload_set_value @S.S.cpp_overload_set [concrete = constants.%S.S.cpp_overload_set.value]
// CHECK:STDOUT:   %S__carbon_thunk.decl.377064.1: %S__carbon_thunk.type.a385a5.1 = fn_decl @S__carbon_thunk.1 [concrete = constants.%S__carbon_thunk.3db2cd.1] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %S.S.decl.11684c.2: %S.S.type.0e9520.2 = fn_decl @S.S.2 [concrete = constants.%S.S.ce82cd.2] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %S__carbon_thunk.decl.377064.2: %S__carbon_thunk.type.a385a5.2 = fn_decl @S__carbon_thunk.2 [concrete = constants.%S__carbon_thunk.3db2cd.2] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %S.cpp_destructor.decl: %S.cpp_destructor.type = fn_decl @S.cpp_destructor [concrete = constants.%S.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc10 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.981 = ref_param_pattern [concrete = constants.%self.param_patt.471]
// CHECK:STDOUT:     %self.patt: %pattern_type.981 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %S = ref_param call_param0
// CHECK:STDOUT:     %self: ref %S = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %T.patt.loc9_7.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_7.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:     %x.param_patt.loc9_23.1: @F.%pattern_type.loc9_23 (%pattern_type.51d) = value_param_pattern [symbolic = %x.param_patt.loc9_23.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc9_23.1: @F.%pattern_type.loc9_23 (%pattern_type.51d) = wrapper_binding_pattern x, %x.param_patt.loc9_23.1 [symbolic = %x.patt.loc9_23.2 (constants.%x.patt.260)]
// CHECK:STDOUT:     %return.param_patt.loc9_38.1: @F.%pattern_type.loc9_38 (%pattern_type.fcb8f3.1) = out_param_pattern [template = %return.param_patt.loc9_38.2 (constants.%return.param_patt.2e9ac5.1)]
// CHECK:STDOUT:     %return.patt.loc9_28.1: @F.%pattern_type.loc9_38 (%pattern_type.fcb8f3.1) = return_slot_pattern %return.param_patt.loc9_38.1, %.loc9_38.9 [template = %return.patt.loc9_28.2 (constants.%return.patt.7fc6a1.1)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Cpp.ref.loc9: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %S.ref.loc9: %S.type = name_ref S, imports.%S.template [concrete = constants.%S.template]
// CHECK:STDOUT:     %T.ref.loc9_37: type = name_ref T, %T.loc9_7.2 [symbolic = %T.loc9_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %.loc9_37.2: type = template_inst %T.ref.loc9_37 [template = %.loc9_37.1 (constants.%.a92)]
// CHECK:STDOUT:     %.loc9_38.7: type = type_of_inst %.loc9_38.1 [template = %.loc9_38.2 (constants.%.d46302.1)]
// CHECK:STDOUT:     %.loc9_38.8: @F.%.loc9_38.2 (%.d46302.1) = splice_inst %.loc9_38.1 [template = %.loc9_38.3 (constants.%.de1469.1)]
// CHECK:STDOUT:     %.loc9_38.9: type = splice_inst %.loc9_38.4 [template = %.loc9_38.5 (constants.%.5372ba.1)]
// CHECK:STDOUT:     %.loc9_38.10: Core.Form = init_form %.loc9_38.9 [template = %.loc9_38.6 (constants.%.cd79f1.1)]
// CHECK:STDOUT:     %.loc9_9.1: type = splice_block %.loc9_9.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc9_9.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc9_7.2: type = symbolic_binding T, 0 [symbolic = %T.loc9_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x.param: @F.%T.loc9_7.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc9_25: type = name_ref T, %T.loc9_7.2 [symbolic = %T.loc9_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %x: @F.%T.loc9_7.1 (%T.67d) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref @F.%.loc9_38.5 (%.5372ba.1) = out_param call_param1
// CHECK:STDOUT:     %return: ref @F.%.loc9_38.5 (%.5372ba.1) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%T.loc9_7.2: type) {
// CHECK:STDOUT:   %T.patt.loc9_7.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_7.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:   %T.loc9_7.1: type = symbolic_binding T, 0 [symbolic = %T.loc9_7.1 (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type.loc9_23: type = pattern_type %T.loc9_7.1 [symbolic = %pattern_type.loc9_23 (constants.%pattern_type.51d)]
// CHECK:STDOUT:   %x.param_patt.loc9_23.2: @F.%pattern_type.loc9_23 (%pattern_type.51d) = value_param_pattern [symbolic = %x.param_patt.loc9_23.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc9_23.2: @F.%pattern_type.loc9_23 (%pattern_type.51d) = wrapper_binding_pattern x, %x.param_patt.loc9_23.2 [symbolic = %x.patt.loc9_23.2 (constants.%x.patt.260)]
// CHECK:STDOUT:   %.loc9_37.1: type = template_inst %T.loc9_7.1 [template = %.loc9_37.1 (constants.%.a92)]
// CHECK:STDOUT:   %.loc9_38.1: <instruction> = call_action (%S.ref.loc9, %.loc9_37.2), false [template]
// CHECK:STDOUT:   %.loc9_38.2: type = type_of_inst %.loc9_38.1 [template = %.loc9_38.2 (constants.%.d46302.1)]
// CHECK:STDOUT:   %.loc9_38.3: @F.%.loc9_38.2 (%.d46302.1) = splice_inst %.loc9_38.1 [template = %.loc9_38.3 (constants.%.de1469.1)]
// CHECK:STDOUT:   %.loc9_38.4: <instruction> = convert_to_value_action %.loc9_38.8, type [template]
// CHECK:STDOUT:   %.loc9_38.5: type = splice_inst %.loc9_38.4 [template = %.loc9_38.5 (constants.%.5372ba.1)]
// CHECK:STDOUT:   %.loc9_38.6: Core.Form = init_form %.loc9_38.5 [template = %.loc9_38.6 (constants.%.cd79f1.1)]
// CHECK:STDOUT:   %pattern_type.loc9_38: type = pattern_type %.loc9_38.5 [template = %pattern_type.loc9_38 (constants.%pattern_type.fcb8f3.1)]
// CHECK:STDOUT:   %return.param_patt.loc9_38.2: @F.%pattern_type.loc9_38 (%pattern_type.fcb8f3.1) = out_param_pattern [template = %return.param_patt.loc9_38.2 (constants.%return.param_patt.2e9ac5.1)]
// CHECK:STDOUT:   %return.patt.loc9_28.2: @F.%pattern_type.loc9_38 (%pattern_type.fcb8f3.1) = return_slot_pattern %return.param_patt.loc9_38.2, %.loc9_38.5 [template = %return.patt.loc9_28.2 (constants.%return.patt.7fc6a1.1)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9_23: <witness> = require_complete_type %T.loc9_7.1 [symbolic = %require_complete.loc9_23 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc9_28: <witness> = require_complete_type %.loc9_38.5 [template = %require_complete.loc9_28 (constants.%require_complete.cb0614.1)]
// CHECK:STDOUT:   %.loc10_17.5: <instruction> = call_action (%S.ref.loc10_13, %.loc10_16), false [template]
// CHECK:STDOUT:   %.loc10_17.6: type = type_of_inst %.loc10_17.5 [template = %.loc10_17.6 (constants.%.d46302.2)]
// CHECK:STDOUT:   %.loc10_17.7: @F.%.loc10_17.6 (%.d46302.2) = splice_inst %.loc10_17.5 [template = %.loc10_17.7 (constants.%.de1469.2)]
// CHECK:STDOUT:   %.loc10_17.8: <instruction> = convert_to_value_action %.loc10_17.3, type [template]
// CHECK:STDOUT:   %.loc10_17.9: type = splice_inst %.loc10_17.8 [template = %.loc10_17.9 (constants.%.5372ba.3)]
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %.loc10_17.9 [template = %require_complete.loc10 (constants.%require_complete.cb0614.2)]
// CHECK:STDOUT:   %pattern_type.loc10: type = pattern_type %.loc10_17.9 [template = %pattern_type.loc10 (constants.%pattern_type.fcb8f3.3)]
// CHECK:STDOUT:   %v.patt.loc10_8.2: @F.%pattern_type.loc10 (%pattern_type.fcb8f3.3) = ref_binding_pattern v [template = %v.patt.loc10_8.2 (constants.%v.patt.126)]
// CHECK:STDOUT:   %v.var_patt.loc10_3.2: @F.%pattern_type.loc10 (%pattern_type.fcb8f3.3) = var_pattern %v.patt.loc10_8.2 [template = %v.var_patt.loc10_3.2 (constants.%v.var_patt.768)]
// CHECK:STDOUT:   %.loc10_28.3: <instruction> = call_action (%S.ref.loc10_24, %.loc10_27), false [template]
// CHECK:STDOUT:   %.loc10_28.4: type = type_of_inst %.loc10_28.3 [template = %.loc10_28.4 (constants.%.d46302.3)]
// CHECK:STDOUT:   %.loc10_28.5: @F.%.loc10_28.4 (%.d46302.3) = splice_inst %.loc10_28.3 [template = %.loc10_28.5 (constants.%.de1469.3)]
// CHECK:STDOUT:   %.loc10_29.3: <instruction> = access_member_action %.loc10_28.2, S [template]
// CHECK:STDOUT:   %.loc10_29.4: type = type_of_inst %.loc10_29.3 [template = %.loc10_29.4 (constants.%.bdb)]
// CHECK:STDOUT:   %.loc10_29.5: @F.%.loc10_29.4 (%.bdb) = splice_inst %.loc10_29.3 [template = %.loc10_29.5 (constants.%.e48)]
// CHECK:STDOUT:   %.loc10_32.3: <instruction> = call_action (%.loc10_29.2), false [template]
// CHECK:STDOUT:   %.loc10_32.4: type = type_of_inst %.loc10_32.3 [template = %.loc10_32.4 (constants.%.5d9)]
// CHECK:STDOUT:   %.loc10_32.5: @F.%.loc10_32.4 (%.5d9) = splice_inst %.loc10_32.3 [template = %.loc10_32.5 (constants.%.3a4)]
// CHECK:STDOUT:   %.loc10_3.6: %tuple.type.f7a = initialize_action %.loc10_32.2, %.loc10_17.9, %v.var, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc10: <instruction> = tuple_access %.loc10_3.6, element0 [template]
// CHECK:STDOUT:   %.loc10_3.7: @F.%.loc10_17.9 (%.5372ba.3) = splice_inst %tuple.elem0.loc10 [template = %.loc10_3.7 (constants.%.5d6323.1)]
// CHECK:STDOUT:   %.loc11_11.2: %tuple.type.f7a = initialize_action %v.ref, %.loc9_38.5, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0.loc11: <instruction> = tuple_access %.loc11_11.2, element0 [template]
// CHECK:STDOUT:   %.loc11_11.3: @F.%.loc9_38.5 (%.5372ba.1) = splice_inst %tuple.elem0.loc11 [template = %.loc11_11.3 (constants.%.5d6323.2)]
// CHECK:STDOUT:   %.loc10_3.8: <instruction> = compound_member_access_action %v.var, constants.%assoc2 [template]
// CHECK:STDOUT:   %.loc10_3.9: type = type_of_inst %.loc10_3.8 [template = %.loc10_3.9 (constants.%.8cb)]
// CHECK:STDOUT:   %.loc10_3.10: @F.%.loc10_3.9 (%.8cb) = splice_inst %.loc10_3.8 [template = %.loc10_3.10 (constants.%.c23)]
// CHECK:STDOUT:   %.loc10_3.11: <instruction> = call_action (%.loc10_3.3), true [template]
// CHECK:STDOUT:   %.loc10_3.12: type = type_of_inst %.loc10_3.11 [template = %.loc10_3.12 (constants.%.57c)]
// CHECK:STDOUT:   %.loc10_3.13: @F.%.loc10_3.12 (%.57c) = splice_inst %.loc10_3.11 [template = %.loc10_3.13 (constants.%.e63)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @F.%T.loc9_7.1 (%T.67d)) -> out %return.param: @F.%.loc9_38.5 (%.5372ba.1) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %v.var: ref @F.%.loc10_17.9 (%.5372ba.3) = var_storage %v.var_patt.loc10_3.1
// CHECK:STDOUT:     %Cpp.ref.loc10_21: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %S.ref.loc10_24: %S.type = name_ref S, imports.%S.template [concrete = constants.%S.template]
// CHECK:STDOUT:     %T.ref.loc10_27: type = name_ref T, %T.loc9_7.2 [symbolic = %T.loc9_7.1 (constants.%T.67d)]
// CHECK:STDOUT:     %.loc10_27: type = template_inst %T.ref.loc10_27 [template = %.loc9_37.1 (constants.%.a92)]
// CHECK:STDOUT:     %.loc10_28.1: type = type_of_inst %.loc10_28.3 [template = %.loc10_28.4 (constants.%.d46302.3)]
// CHECK:STDOUT:     %.loc10_28.2: @F.%.loc10_28.4 (%.d46302.3) = splice_inst %.loc10_28.3 [template = %.loc10_28.5 (constants.%.de1469.3)]
// CHECK:STDOUT:     %.loc10_29.1: type = type_of_inst %.loc10_29.3 [template = %.loc10_29.4 (constants.%.bdb)]
// CHECK:STDOUT:     %.loc10_29.2: @F.%.loc10_29.4 (%.bdb) = splice_inst %.loc10_29.3 [template = %.loc10_29.5 (constants.%.e48)]
// CHECK:STDOUT:     %.loc10_32.1: type = type_of_inst %.loc10_32.3 [template = %.loc10_32.4 (constants.%.5d9)]
// CHECK:STDOUT:     %.loc10_32.2: @F.%.loc10_32.4 (%.5d9) = splice_inst %.loc10_32.3 [template = %.loc10_32.5 (constants.%.3a4)]
// CHECK:STDOUT:     %.loc10_3.1: @F.%.loc10_17.9 (%.5372ba.3) = splice_inst %tuple.elem0.loc10 [template = %.loc10_3.7 (constants.%.5d6323.1)]
// CHECK:STDOUT:     assign %v.var, %.loc10_3.1
// CHECK:STDOUT:     %.loc10_17.1: type = splice_block %.loc10_17.4 [template = %.loc10_17.9 (constants.%.5372ba.3)] {
// CHECK:STDOUT:       %Cpp.ref.loc10_10: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %S.ref.loc10_13: %S.type = name_ref S, imports.%S.template [concrete = constants.%S.template]
// CHECK:STDOUT:       %T.ref.loc10_16: type = name_ref T, %T.loc9_7.2 [symbolic = %T.loc9_7.1 (constants.%T.67d)]
// CHECK:STDOUT:       %.loc10_16: type = template_inst %T.ref.loc10_16 [template = %.loc9_37.1 (constants.%.a92)]
// CHECK:STDOUT:       %.loc10_17.2: type = type_of_inst %.loc10_17.5 [template = %.loc10_17.6 (constants.%.d46302.2)]
// CHECK:STDOUT:       %.loc10_17.3: @F.%.loc10_17.6 (%.d46302.2) = splice_inst %.loc10_17.5 [template = %.loc10_17.7 (constants.%.de1469.2)]
// CHECK:STDOUT:       %.loc10_17.4: type = splice_inst %.loc10_17.8 [template = %.loc10_17.9 (constants.%.5372ba.3)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v: ref @F.%.loc10_17.9 (%.5372ba.3) = wrapper_binding v, %v.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %v.patt.loc10_8.1: @F.%pattern_type.loc10 (%pattern_type.fcb8f3.3) = ref_binding_pattern v [template = %v.patt.loc10_8.2 (constants.%v.patt.126)]
// CHECK:STDOUT:       %v.var_patt.loc10_3.1: @F.%pattern_type.loc10 (%pattern_type.fcb8f3.3) = var_pattern %v.patt.loc10_8.1 [template = %v.var_patt.loc10_3.2 (constants.%v.var_patt.768)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v.ref: ref @F.%.loc10_17.9 (%.5372ba.3) = name_ref v, %v
// CHECK:STDOUT:     %.loc11_11.1: @F.%.loc9_38.5 (%.5372ba.1) = splice_inst %tuple.elem0.loc11 [template = %.loc11_11.3 (constants.%.5d6323.2)]
// CHECK:STDOUT:     %.loc10_3.2: type = type_of_inst %.loc10_3.8 [template = %.loc10_3.9 (constants.%.8cb)]
// CHECK:STDOUT:     %.loc10_3.3: @F.%.loc10_3.9 (%.8cb) = splice_inst %.loc10_3.8 [template = %.loc10_3.10 (constants.%.c23)]
// CHECK:STDOUT:     %.loc10_3.4: type = type_of_inst %.loc10_3.11 [template = %.loc10_3.12 (constants.%.57c)]
// CHECK:STDOUT:     %.loc10_3.5: @F.%.loc10_3.12 (%.57c) = splice_inst %.loc10_3.11 [template = %.loc10_3.13 (constants.%.e63)]
// CHECK:STDOUT:     return %.loc11_11.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc10(%self.param: ref %S) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc10(%self.param: ref %S) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %S.cpp_destructor.call: init %empty_tuple.type = call imports.%S.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc9_7.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc9_7.1 => constants.%T.67d
// CHECK:STDOUT:   %pattern_type.loc9_23 => constants.%pattern_type.51d
// CHECK:STDOUT:   %x.param_patt.loc9_23.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc9_23.2 => constants.%x.patt.260
// CHECK:STDOUT:   %.loc9_37.1 => constants.%.a92
// CHECK:STDOUT:   %.loc9_38.1 => constants.%.961
// CHECK:STDOUT:   %.loc9_38.2 => constants.%.7d1
// CHECK:STDOUT:   %.loc9_38.3 => constants.%.774
// CHECK:STDOUT:   %.loc9_38.4 => constants.%.c8c
// CHECK:STDOUT:   %.loc9_38.5 => constants.%.5372ba.2
// CHECK:STDOUT:   %.loc9_38.6 => constants.%.cd79f1.2
// CHECK:STDOUT:   %pattern_type.loc9_38 => constants.%pattern_type.fcb8f3.2
// CHECK:STDOUT:   %return.param_patt.loc9_38.2 => constants.%return.param_patt.2e9ac5.2
// CHECK:STDOUT:   %return.patt.loc9_28.2 => constants.%return.patt.7fc6a1.2
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%X) {
// CHECK:STDOUT:   %T.patt.loc9_7.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc9_7.1 => constants.%X
// CHECK:STDOUT:   %pattern_type.loc9_23 => constants.%pattern_type.fa7
// CHECK:STDOUT:   %x.param_patt.loc9_23.2 => constants.%x.param_patt.468
// CHECK:STDOUT:   %x.patt.loc9_23.2 => constants.%x.patt.af8
// CHECK:STDOUT:   %.loc9_37.1 => constants.%X
// CHECK:STDOUT:   %.loc9_38.1 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc9_38.2 => type
// CHECK:STDOUT:   %.loc9_38.3 => constants.%S
// CHECK:STDOUT:   %.loc9_38.4 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc9_38.5 => constants.%S
// CHECK:STDOUT:   %.loc9_38.6 => constants.%.cb5
// CHECK:STDOUT:   %pattern_type.loc9_38 => constants.%pattern_type.981
// CHECK:STDOUT:   %return.param_patt.loc9_38.2 => constants.%return.param_patt.c2b
// CHECK:STDOUT:   %return.patt.loc9_28.2 => constants.%return.patt.36a
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9_23 => constants.%complete_type
// CHECK:STDOUT:   %require_complete.loc9_28 => constants.%complete_type
// CHECK:STDOUT:   %.loc10_17.5 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc10_17.6 => type
// CHECK:STDOUT:   %.loc10_17.7 => constants.%S
// CHECK:STDOUT:   %.loc10_17.8 => constants.%inst.splice_block.426619.4
// CHECK:STDOUT:   %.loc10_17.9 => constants.%S
// CHECK:STDOUT:   %require_complete.loc10 => constants.%complete_type
// CHECK:STDOUT:   %pattern_type.loc10 => constants.%pattern_type.981
// CHECK:STDOUT:   %v.patt.loc10_8.2 => constants.%v.patt.5fa
// CHECK:STDOUT:   %v.var_patt.loc10_3.2 => constants.%v.var_patt.e69
// CHECK:STDOUT:   %.loc10_28.3 => constants.%inst.splice_block.426619.5
// CHECK:STDOUT:   %.loc10_28.4 => type
// CHECK:STDOUT:   %.loc10_28.5 => constants.%S
// CHECK:STDOUT:   %.loc10_29.3 => constants.%inst.name_ref
// CHECK:STDOUT:   %.loc10_29.4 => constants.%S.S.cpp_overload_set.type
// CHECK:STDOUT:   %.loc10_29.5 => constants.%S.S.cpp_overload_set.value
// CHECK:STDOUT:   %.loc10_32.3 => constants.%inst.splice_block.426619.6
// CHECK:STDOUT:   %.loc10_32.4 => constants.%S
// CHECK:STDOUT:   %.loc10_32.5 => <not constant>
// CHECK:STDOUT:   %.loc10_3.6 => constants.%tuple.24243e.1
// CHECK:STDOUT:   %tuple.elem0.loc10 => constants.%inst.splice_block.426619.7
// CHECK:STDOUT:   %.loc10_3.7 => <not constant>
// CHECK:STDOUT:   %.loc11_11.2 => constants.%tuple.24243e.2
// CHECK:STDOUT:   %tuple.elem0.loc11 => constants.%inst.splice_block.426619.8
// CHECK:STDOUT:   %.loc11_11.3 => <not constant>
// CHECK:STDOUT:   %.loc10_3.8 => constants.%inst.splice_block.426619.9
// CHECK:STDOUT:   %.loc10_3.9 => <bound method>
// CHECK:STDOUT:   %.loc10_3.10 => <not constant>
// CHECK:STDOUT:   %.loc10_3.11 => constants.%inst.call
// CHECK:STDOUT:   %.loc10_3.12 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc10_3.13 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
