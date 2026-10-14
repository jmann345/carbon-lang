// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// TODO: Add ranges and switch to "--dump-sem-ir-ranges=only".
// EXTRA-ARGS: --dump-sem-ir-ranges=if-present
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/unimplemented.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/unimplemented.carbon

// --- deref_dependent_member.carbon

library "[[@TEST_NAME]]";

// A dereference of a template-dependent expression is checked when the
// template is instantiated.
fn F[template T: type](x: T) {
  *x.n;
}

// --- fail_deref_dependent_member_non_pointer.carbon

library "[[@TEST_NAME]]";

class C {
  var n: i32;
}

fn F[template T: type](x: T) {
  *x.n;
}

fn G(c: C) {
  // CHECK:STDERR: fail_deref_dependent_member_non_pointer.carbon:[[@LINE+7]]:3: error: unable to monomorphize specific `F(C)` [ResolvingSpecificHere]
  // CHECK:STDERR:   F(c);
  // CHECK:STDERR:   ^
  // CHECK:STDERR: fail_deref_dependent_member_non_pointer.carbon:[[@LINE-7]]:3: note: cannot dereference operand of non-pointer type `i32` [DerefOfNonPointer]
  // CHECK:STDERR:   *x.n;
  // CHECK:STDERR:   ^
  // CHECK:STDERR:
  F(c);
}

// --- deref_dependent_value.carbon

library "[[@TEST_NAME]]";

class C {
  var n: i32;
}

// `c.n` uses the value of a template parameter, so a dereference of it is
// checked when the template is instantiated (proposal 2200, "Use of dependent
// value is dependent").
fn F(template c: C) {
  *c.n;
}

// CHECK:STDOUT: --- deref_dependent_member.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d: type = pattern_type %T [template]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.51d = value_param_pattern [template]
// CHECK:STDOUT:   %x.patt: %pattern_type.51d = wrapper_binding_pattern x, %x.param_patt [template]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T [template]
// CHECK:STDOUT:   %.237: type = type_of_inst @F.%.loc7_5.3 [template]
// CHECK:STDOUT:   %.f96: %.237 = splice_inst @F.%.loc7_5.3 [template]
// CHECK:STDOUT:   %.6c8: type = type_of_inst @F.%.loc7_3.4 [template]
// CHECK:STDOUT:   %.5d5: %.6c8 = splice_inst @F.%.loc7_3.4 [template]
// CHECK:STDOUT:   %require_complete.695: <witness> = require_complete_type %.6c8 [template]
// CHECK:STDOUT:   %.b0f: %.6c8 = splice_inst @F.%.loc7_3.7 [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .F = %F.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %T.patt.loc6_16.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc6_16.2 (constants.%T.patt)]
// CHECK:STDOUT:     %x.param_patt.loc6_25.1: @F.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %x.param_patt.loc6_25.2 (constants.%x.param_patt)]
// CHECK:STDOUT:     %x.patt.loc6_25.1: @F.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern x, %x.param_patt.loc6_25.1 [template = %x.patt.loc6_25.2 (constants.%x.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc6_18.1: type = splice_block %.loc6_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc6_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc6_16.2: type = symbolic_binding T, 0, template [template = %T.loc6_16.1 (constants.%T)]
// CHECK:STDOUT:     %x.param: @F.%T.loc6_16.1 (%T) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc6_16.2 [template = %T.loc6_16.1 (constants.%T)]
// CHECK:STDOUT:     %x: @F.%T.loc6_16.1 (%T) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%T.loc6_16.2: type) {
// CHECK:STDOUT:   %T.patt.loc6_16.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc6_16.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc6_16.1: type = symbolic_binding T, 0, template [template = %T.loc6_16.1 (constants.%T)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc6_16.1 [template = %pattern_type (constants.%pattern_type.51d)]
// CHECK:STDOUT:   %x.param_patt.loc6_25.2: @F.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %x.param_patt.loc6_25.2 (constants.%x.param_patt)]
// CHECK:STDOUT:   %x.patt.loc6_25.2: @F.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern x, %x.param_patt.loc6_25.2 [template = %x.patt.loc6_25.2 (constants.%x.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc6: <witness> = require_complete_type %T.loc6_16.1 [template = %require_complete.loc6 (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc7_5.3: <instruction> = access_member_action %x.ref, n [template]
// CHECK:STDOUT:   %.loc7_5.4: type = type_of_inst %.loc7_5.3 [template = %.loc7_5.4 (constants.%.237)]
// CHECK:STDOUT:   %.loc7_5.5: @F.%.loc7_5.4 (%.237) = splice_inst %.loc7_5.3 [template = %.loc7_5.5 (constants.%.f96)]
// CHECK:STDOUT:   %.loc7_3.4: <instruction> = pointer_dereference_action %.loc7_5.2, false [template]
// CHECK:STDOUT:   %.loc7_3.5: type = type_of_inst %.loc7_3.4 [template = %.loc7_3.5 (constants.%.6c8)]
// CHECK:STDOUT:   %.loc7_3.6: @F.%.loc7_3.5 (%.6c8) = splice_inst %.loc7_3.4 [template = %.loc7_3.6 (constants.%.5d5)]
// CHECK:STDOUT:   %require_complete.loc7: <witness> = require_complete_type %.loc7_3.5 [template = %require_complete.loc7 (constants.%require_complete.695)]
// CHECK:STDOUT:   %.loc7_3.7: <instruction> = convert_to_category_action %.loc7_3.2, element9 [template]
// CHECK:STDOUT:   %.loc7_3.8: @F.%.loc7_3.5 (%.6c8) = splice_inst %.loc7_3.7 [template = %.loc7_3.8 (constants.%.b0f)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @F.%T.loc6_16.1 (%T)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref: @F.%T.loc6_16.1 (%T) = name_ref x, %x
// CHECK:STDOUT:     %.loc7_5.1: type = type_of_inst %.loc7_5.3 [template = %.loc7_5.4 (constants.%.237)]
// CHECK:STDOUT:     %.loc7_5.2: @F.%.loc7_5.4 (%.237) = splice_inst %.loc7_5.3 [template = %.loc7_5.5 (constants.%.f96)]
// CHECK:STDOUT:     %.loc7_3.1: type = type_of_inst %.loc7_3.4 [template = %.loc7_3.5 (constants.%.6c8)]
// CHECK:STDOUT:     %.loc7_3.2: @F.%.loc7_3.5 (%.6c8) = splice_inst %.loc7_3.4 [template = %.loc7_3.6 (constants.%.5d5)]
// CHECK:STDOUT:     %.loc7_3.3: @F.%.loc7_3.5 (%.6c8) = splice_inst %.loc7_3.7 [template = %.loc7_3.8 (constants.%.b0f)]
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%T) {
// CHECK:STDOUT:   %T.patt.loc6_16.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc6_16.1 => constants.%T
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d
// CHECK:STDOUT:   %x.param_patt.loc6_25.2 => constants.%x.param_patt
// CHECK:STDOUT:   %x.patt.loc6_25.2 => constants.%x.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- fail_deref_dependent_member_non_pointer.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %C.elem: type = unbound_element_type %C, %i32 [concrete]
// CHECK:STDOUT:   %struct_type.n: type = struct_type {.n: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.cdf: <witness> = complete_type_witness %struct_type.n [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d: type = pattern_type %T [template]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d = value_param_pattern [template]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d = wrapper_binding_pattern x, %x.param_patt.91d [template]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T [template]
// CHECK:STDOUT:   %.237: type = type_of_inst @F.%.loc9_5.3 [template]
// CHECK:STDOUT:   %.f96: %.237 = splice_inst @F.%.loc9_5.3 [template]
// CHECK:STDOUT:   %.6c8: type = type_of_inst @F.%.loc9_3.4 [template]
// CHECK:STDOUT:   %.5d5: %.6c8 = splice_inst @F.%.loc9_3.4 [template]
// CHECK:STDOUT:   %require_complete.695: <witness> = require_complete_type %.6c8 [template]
// CHECK:STDOUT:   %.b0f: %.6c8 = splice_inst @F.%.loc9_3.7 [template]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %x.param_patt.0f9: %pattern_type.98b = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.953: %pattern_type.98b = wrapper_binding_pattern x, %x.param_patt.0f9 [concrete]
// CHECK:STDOUT:   %F.specific_fn: <specific function> = specific_function %F, @F(%C) [concrete]
// CHECK:STDOUT:   %inst.splice_block: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.f8b: %i32 = splice_block %.232 {
// CHECK:STDOUT:       %.bfd: %C = specific_inst @F.%x.ref, @F(%C)
// CHECK:STDOUT:       %n.ref: %C.elem = name_ref n, @C.%field_decl [concrete = @C.%field_decl]
// CHECK:STDOUT:       %.d33: ref %i32 = class_element_access %.bfd, element0
// CHECK:STDOUT:       %.232: %i32 = acquire_value %.d33
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.deref: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.67b: ref <error> = deref %.f8b
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .C = %C.decl
// CHECK:STDOUT:     .F = %F.decl
// CHECK:STDOUT:     .G = %G.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %C.decl: type = class_decl @C [concrete = constants.%C] {} {}
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %T.patt.loc8_16.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc8_16.2 (constants.%T.patt)]
// CHECK:STDOUT:     %x.param_patt.loc8_25.1: @F.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %x.param_patt.loc8_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc8_25.1: @F.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern x, %x.param_patt.loc8_25.1 [template = %x.patt.loc8_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc8_18.1: type = splice_block %.loc8_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc8_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc8_16.2: type = symbolic_binding T, 0, template [template = %T.loc8_16.1 (constants.%T)]
// CHECK:STDOUT:     %x.param: @F.%T.loc8_16.1 (%T) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc8_16.2 [template = %T.loc8_16.1 (constants.%T)]
// CHECK:STDOUT:     %x: @F.%T.loc8_16.1 (%T) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.98b = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.98b = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %c.param: %C = value_param call_param0
// CHECK:STDOUT:     %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %c.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @C {
// CHECK:STDOUT:   %field_decl: %C.elem = field_decl n, element0, %i32 in [concrete] {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.n [concrete = constants.%complete_type.cdf]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%C
// CHECK:STDOUT:   .n = %field_decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%T.loc8_16.2: type) {
// CHECK:STDOUT:   %T.patt.loc8_16.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc8_16.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc8_16.1: type = symbolic_binding T, 0, template [template = %T.loc8_16.1 (constants.%T)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc8_16.1 [template = %pattern_type (constants.%pattern_type.51d)]
// CHECK:STDOUT:   %x.param_patt.loc8_25.2: @F.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %x.param_patt.loc8_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc8_25.2: @F.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern x, %x.param_patt.loc8_25.2 [template = %x.patt.loc8_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8: <witness> = require_complete_type %T.loc8_16.1 [template = %require_complete.loc8 (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc9_5.3: <instruction> = access_member_action %x.ref, n [template]
// CHECK:STDOUT:   %.loc9_5.4: type = type_of_inst %.loc9_5.3 [template = %.loc9_5.4 (constants.%.237)]
// CHECK:STDOUT:   %.loc9_5.5: @F.%.loc9_5.4 (%.237) = splice_inst %.loc9_5.3 [template = %.loc9_5.5 (constants.%.f96)]
// CHECK:STDOUT:   %.loc9_3.4: <instruction> = pointer_dereference_action %.loc9_5.2, false [template]
// CHECK:STDOUT:   %.loc9_3.5: type = type_of_inst %.loc9_3.4 [template = %.loc9_3.5 (constants.%.6c8)]
// CHECK:STDOUT:   %.loc9_3.6: @F.%.loc9_3.5 (%.6c8) = splice_inst %.loc9_3.4 [template = %.loc9_3.6 (constants.%.5d5)]
// CHECK:STDOUT:   %require_complete.loc9: <witness> = require_complete_type %.loc9_3.5 [template = %require_complete.loc9 (constants.%require_complete.695)]
// CHECK:STDOUT:   %.loc9_3.7: <instruction> = convert_to_category_action %.loc9_3.2, element9 [template]
// CHECK:STDOUT:   %.loc9_3.8: @F.%.loc9_3.5 (%.6c8) = splice_inst %.loc9_3.7 [template = %.loc9_3.8 (constants.%.b0f)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @F.%T.loc8_16.1 (%T)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref: @F.%T.loc8_16.1 (%T) = name_ref x, %x
// CHECK:STDOUT:     %.loc9_5.1: type = type_of_inst %.loc9_5.3 [template = %.loc9_5.4 (constants.%.237)]
// CHECK:STDOUT:     %.loc9_5.2: @F.%.loc9_5.4 (%.237) = splice_inst %.loc9_5.3 [template = %.loc9_5.5 (constants.%.f96)]
// CHECK:STDOUT:     %.loc9_3.1: type = type_of_inst %.loc9_3.4 [template = %.loc9_3.5 (constants.%.6c8)]
// CHECK:STDOUT:     %.loc9_3.2: @F.%.loc9_3.5 (%.6c8) = splice_inst %.loc9_3.4 [template = %.loc9_3.6 (constants.%.5d5)]
// CHECK:STDOUT:     %.loc9_3.3: @F.%.loc9_3.5 (%.6c8) = splice_inst %.loc9_3.7 [template = %.loc9_3.8 (constants.%.b0f)]
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G(%c.param: %C) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %F.specific_fn: <specific function> = specific_function %F.ref, @F(constants.%C) [concrete = constants.%F.specific_fn]
// CHECK:STDOUT:   %F.call: init %empty_tuple.type = call %F.specific_fn(%c.ref)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%T) {
// CHECK:STDOUT:   %T.patt.loc8_16.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc8_16.1 => constants.%T
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d
// CHECK:STDOUT:   %x.param_patt.loc8_25.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc8_25.2 => constants.%x.patt.260
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%C) {
// CHECK:STDOUT:   %T.patt.loc8_16.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc8_16.1 => constants.%C
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.98b
// CHECK:STDOUT:   %x.param_patt.loc8_25.2 => constants.%x.param_patt.0f9
// CHECK:STDOUT:   %x.patt.loc8_25.2 => constants.%x.patt.953
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8 => constants.%complete_type.cdf
// CHECK:STDOUT:   %.loc9_5.3 => constants.%inst.splice_block
// CHECK:STDOUT:   %.loc9_5.4 => constants.%i32
// CHECK:STDOUT:   %.loc9_5.5 => <not constant>
// CHECK:STDOUT:   %.loc9_3.4 => constants.%inst.deref
// CHECK:STDOUT:   %.loc9_3.5 => <error>
// CHECK:STDOUT:   %.loc9_3.6 => <error>
// CHECK:STDOUT:   %require_complete.loc9 => <error>
// CHECK:STDOUT:   %.loc9_3.7 => <error>
// CHECK:STDOUT:   %.loc9_3.8 => <error>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- deref_dependent_value.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %C.elem: type = unbound_element_type %C, %i32 [concrete]
// CHECK:STDOUT:   %struct_type.n: type = struct_type {.n: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.cdf: <witness> = complete_type_witness %struct_type.n [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = symbolic_binding_pattern c, 0, template [template]
// CHECK:STDOUT:   %c: %C = symbolic_binding c, 0, template [template]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %.237: type = type_of_inst @F.%.loc12_5.3 [template]
// CHECK:STDOUT:   %.f96: %.237 = splice_inst @F.%.loc12_5.3 [template]
// CHECK:STDOUT:   %.6c8: type = type_of_inst @F.%.loc12_3.4 [template]
// CHECK:STDOUT:   %.5d5: %.6c8 = splice_inst @F.%.loc12_3.4 [template]
// CHECK:STDOUT:   %require_complete.695: <witness> = require_complete_type %.6c8 [template]
// CHECK:STDOUT:   %.b0f: %.6c8 = splice_inst @F.%.loc12_3.7 [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .C = %C.decl
// CHECK:STDOUT:     .F = %F.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %C.decl: type = class_decl @C [concrete = constants.%C] {} {}
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %c.patt.loc11_16.1: %pattern_type.98b = symbolic_binding_pattern c, 0, template [template = %c.patt.loc11_16.2 (constants.%c.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc11: type = splice_block %C.ref [concrete = constants.%C] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %c.loc11_16.2: %C = symbolic_binding c, 0, template [template = %c.loc11_16.1 (constants.%c)]
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @C {
// CHECK:STDOUT:   %field_decl: %C.elem = field_decl n, element0, %i32 in [concrete] {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %complete_type: <witness> = complete_type_witness constants.%struct_type.n [concrete = constants.%complete_type.cdf]
// CHECK:STDOUT:   complete_type_witness = %complete_type
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = constants.%C
// CHECK:STDOUT:   .n = %field_decl
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%c.loc11_16.2: %C) {
// CHECK:STDOUT:   %c.patt.loc11_16.2: %pattern_type.98b = symbolic_binding_pattern c, 0, template [template = %c.patt.loc11_16.2 (constants.%c.patt)]
// CHECK:STDOUT:   %c.loc11_16.1: %C = symbolic_binding c, 0, template [template = %c.loc11_16.1 (constants.%c)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %.loc12_5.3: <instruction> = access_member_action %c.ref, n [template]
// CHECK:STDOUT:   %.loc12_5.4: type = type_of_inst %.loc12_5.3 [template = %.loc12_5.4 (constants.%.237)]
// CHECK:STDOUT:   %.loc12_5.5: @F.%.loc12_5.4 (%.237) = splice_inst %.loc12_5.3 [template = %.loc12_5.5 (constants.%.f96)]
// CHECK:STDOUT:   %.loc12_3.4: <instruction> = pointer_dereference_action %.loc12_5.2, false [template]
// CHECK:STDOUT:   %.loc12_3.5: type = type_of_inst %.loc12_3.4 [template = %.loc12_3.5 (constants.%.6c8)]
// CHECK:STDOUT:   %.loc12_3.6: @F.%.loc12_3.5 (%.6c8) = splice_inst %.loc12_3.4 [template = %.loc12_3.6 (constants.%.5d5)]
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %.loc12_3.5 [template = %require_complete (constants.%require_complete.695)]
// CHECK:STDOUT:   %.loc12_3.7: <instruction> = convert_to_category_action %.loc12_3.2, element9 [template]
// CHECK:STDOUT:   %.loc12_3.8: @F.%.loc12_3.5 (%.6c8) = splice_inst %.loc12_3.7 [template = %.loc12_3.8 (constants.%.b0f)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn() {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %c.ref: %C = name_ref c, %c.loc11_16.2 [template = %c.loc11_16.1 (constants.%c)]
// CHECK:STDOUT:     %.loc12_5.1: type = type_of_inst %.loc12_5.3 [template = %.loc12_5.4 (constants.%.237)]
// CHECK:STDOUT:     %.loc12_5.2: @F.%.loc12_5.4 (%.237) = splice_inst %.loc12_5.3 [template = %.loc12_5.5 (constants.%.f96)]
// CHECK:STDOUT:     %.loc12_3.1: type = type_of_inst %.loc12_3.4 [template = %.loc12_3.5 (constants.%.6c8)]
// CHECK:STDOUT:     %.loc12_3.2: @F.%.loc12_3.5 (%.6c8) = splice_inst %.loc12_3.4 [template = %.loc12_3.6 (constants.%.5d5)]
// CHECK:STDOUT:     %.loc12_3.3: @F.%.loc12_3.5 (%.6c8) = splice_inst %.loc12_3.7 [template = %.loc12_3.8 (constants.%.b0f)]
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%c) {
// CHECK:STDOUT:   %c.patt.loc11_16.2 => constants.%c.patt
// CHECK:STDOUT:   %c.loc11_16.1 => constants.%c
// CHECK:STDOUT: }
// CHECK:STDOUT:
