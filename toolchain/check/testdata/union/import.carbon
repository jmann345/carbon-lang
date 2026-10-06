// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/union/import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/union/import.carbon

// An imported union keeps `is_union` and its `custom_layout_type`
// representation, so designated initialization, field access and copy work
// across the import.

// --- lib.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn Read(u: IntOrBytes) -> i32 { return u.word; }

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

//@dump-sem-ir-begin
fn Use() -> i32 {
  var v: IntOrBytes = {.word = 5};
  var w: IntOrBytes = v;
  w.bytes[0] = 1;
  return Read(w) + w.word;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- use.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %IntOrBytes: type = class_type @IntOrBytes [concrete]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %int_8: Core.IntLiteral = int_value 8 [concrete]
// CHECK:STDOUT:   %i8: type = class_type @Int, @Int(%int_8) [concrete]
// CHECK:STDOUT:   %array_type: type = array_type %int_4, %i8 [concrete]
// CHECK:STDOUT:   %.e9a: type = custom_layout_type {size=4, align=4, .word@0: %i32, .bytes@0: %array_type} [concrete]
// CHECK:STDOUT:   %pattern_type.970: type = pattern_type %IntOrBytes [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete]
// CHECK:STDOUT:   %int_5.64b: Core.IntLiteral = int_value 5 [concrete]
// CHECK:STDOUT:   %struct_type.word: type = struct_type {.word: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.word = struct_value (%int_5.64b) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.c9d: <bound method> = bound_method %int_5.64b, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_5.eef: %i32 = int_value 5 [concrete]
// CHECK:STDOUT:   %w.patt: %pattern_type.970 = ref_binding_pattern w [concrete]
// CHECK:STDOUT:   %w.var_patt: %pattern_type.970 = var_pattern %w.patt [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f5: type = fn_type @Copy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.416: %Copy.WithSelf.Op.type.7f5 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.bab: <witness> = custom_witness (%Copy.WithSelf.Op.416), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.b97: %Copy.type = facet_value %IntOrBytes, (%custom_witness.bab) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.c4f: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.b97) [concrete]
// CHECK:STDOUT:   %.2da: type = fn_type_with_self_type %Copy.WithSelf.Op.type.c4f, %Copy.facet.b97 [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.ff6: type = unbound_element_type %IntOrBytes, %array_type [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.869: type = facet_type <@ImplicitAs, @ImplicitAs(%i8)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.1b5: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.f5b: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.868: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.f5b = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.41f: %ImplicitAs.type.869 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.1b5) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.999: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i8, %ImplicitAs.facet.41f) [concrete]
// CHECK:STDOUT:   %.5d4: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.999, %ImplicitAs.facet.41f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0ab: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.868 [concrete]
// CHECK:STDOUT:   %pattern_type.0cf: type = pattern_type %i8 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.868, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_8) [concrete]
// CHECK:STDOUT:   %bound_method.272: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda [concrete]
// CHECK:STDOUT:   %int_1.f1e: %i8 = int_value 1 [concrete]
// CHECK:STDOUT:   %Read.type: type = fn_type @Read [concrete]
// CHECK:STDOUT:   %Read: %Read.type = struct_value () [concrete]
// CHECK:STDOUT:   %IntOrBytes.elem.a3f: type = unbound_element_type %IntOrBytes, %i32 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc8_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.6c8: %pattern_type.0cf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.136: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt.6c8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc8_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.9c7: type = pattern_type %array_type [concrete]
// CHECK:STDOUT:   %self.param_patt.078: %pattern_type.9c7 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d53: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt.078 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc8_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cf0: type = pattern_type %.e9a [concrete]
// CHECK:STDOUT:   %self.param_patt.bc5: %pattern_type.cf0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.928: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt.bc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc8_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.453: %pattern_type.970 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e2e: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt.453 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc8_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.IntOrBytes: type = import_ref Main//lib, IntOrBytes, loaded [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %Main.Read: %Read.type = import_ref Main//lib, Read, loaded [concrete = constants.%Read]
// CHECK:STDOUT:   %Main.import_ref.a8c: %IntOrBytes.elem.a3f = import_ref Main//lib, loc4_11, loaded [concrete = %field_decl.2be]
// CHECK:STDOUT:   %Main.import_ref.184: %IntOrBytes.elem.ff6 = import_ref Main//lib, loc5_12, loaded [concrete = %field_decl.bec]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Main.import_ref.7a0 = import_ref Main//lib, loc5_25, unloaded
// CHECK:STDOUT:   %field_decl.bec: %IntOrBytes.elem.ff6 = field_decl bytes, element1, %Main.import_ref.7a0 in [concrete] {}
// CHECK:STDOUT:   %Main.import_ref.69c = import_ref Main//lib, loc4_13, unloaded
// CHECK:STDOUT:   %field_decl.2be: %IntOrBytes.elem.a3f = field_decl word, element0, %Main.import_ref.69c in [concrete] {}
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc8_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc8_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.0cf = ref_param_pattern [concrete = constants.%self.param_patt.6c8]
// CHECK:STDOUT:     %self.patt: %pattern_type.0cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.136]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc8_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.9c7 = ref_param_pattern [concrete = constants.%self.param_patt.078]
// CHECK:STDOUT:     %self.patt: %pattern_type.9c7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d53]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %array_type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %array_type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_3.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc8_3.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cf0 = ref_param_pattern [concrete = constants.%self.param_patt.bc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.cf0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.928]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e9a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e9a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_3.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc8_3.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.970 = ref_param_pattern [concrete = constants.%self.param_patt.453]
// CHECK:STDOUT:     %self.patt: %pattern_type.970 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e2e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %IntOrBytes = ref_param call_param0
// CHECK:STDOUT:     %self: ref %IntOrBytes = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc6: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.var: ref %IntOrBytes = var_storage %v.var_patt
// CHECK:STDOUT:   %int_5: Core.IntLiteral = int_value 5 [concrete = constants.%int_5.64b]
// CHECK:STDOUT:   %.loc7_33.1: %struct_type.word = struct_literal (%int_5) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc7: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc7_33.1: <bound method> = bound_method %int_5, %impl.elem0.loc7 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f6c]
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc7_33.2: <bound method> = bound_method %int_5, %specific_fn.loc7 [concrete = constants.%bound_method.c9d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7: init %i32 = call %bound_method.loc7_33.2(%int_5) [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc7_33.2: init %i32 = converted %int_5, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc7_33.3: ref %i32 = class_element_access %v.var, element0
// CHECK:STDOUT:   %.loc7_33.4: init %i32 to %.loc7_33.3 = in_place_init %.loc7_33.2 [concrete = constants.%int_5.eef]
// CHECK:STDOUT:   %.loc7_33.5: init %IntOrBytes to %v.var = class_init (%.loc7_33.4)
// CHECK:STDOUT:   %.loc7_3: init %IntOrBytes = converted %.loc7_33.1, %.loc7_33.5
// CHECK:STDOUT:   assign %v.var, %.loc7_3
// CHECK:STDOUT:   %IntOrBytes.ref.loc7: type = name_ref IntOrBytes, imports.%Main.IntOrBytes [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %v: ref %IntOrBytes = wrapper_binding v, %v.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.970 = ref_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %v.var_patt: %pattern_type.970 = var_pattern %v.patt [concrete = constants.%v.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %w.var: ref %IntOrBytes = var_storage %w.var_patt
// CHECK:STDOUT:   %v.ref: ref %IntOrBytes = name_ref v, %v
// CHECK:STDOUT:   %.loc8_23: %IntOrBytes = acquire_value %v.ref
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc8: %.2da = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc8: <bound method> = bound_method %.loc8_23, %impl.elem0.loc8
// CHECK:STDOUT:   %.loc8_3: ref %IntOrBytes = splice_block %w.var {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call: init %IntOrBytes to %.loc8_3 = call %bound_method.loc8(%.loc8_23)
// CHECK:STDOUT:   assign %w.var, %Copy.WithSelf.Op.call
// CHECK:STDOUT:   %IntOrBytes.ref.loc8: type = name_ref IntOrBytes, imports.%Main.IntOrBytes [concrete = constants.%IntOrBytes]
// CHECK:STDOUT:   %w: ref %IntOrBytes = wrapper_binding w, %w.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %w.patt: %pattern_type.970 = ref_binding_pattern w [concrete = constants.%w.patt]
// CHECK:STDOUT:     %w.var_patt: %pattern_type.970 = var_pattern %w.patt [concrete = constants.%w.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %w.ref.loc9: ref %IntOrBytes = name_ref w, %w
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, imports.%Main.import_ref.184 [concrete = imports.%field_decl.bec]
// CHECK:STDOUT:   %.loc9_4: ref %array_type = class_element_access %w.ref.loc9, element1
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9_11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_11.1: <bound method> = bound_method %int_0, %impl.elem0.loc9_11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc9_11: <specific function> = specific_function %impl.elem0.loc9_11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc9_11.2: <bound method> = bound_method %int_0, %specific_fn.loc9_11 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_11: init %i32 = call %bound_method.loc9_11.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc9_11.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_11 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc9_11.2: %i32 = converted %int_0, %.loc9_11.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc9_12: ref %i8 = array_index %.loc9_4, %.loc9_11.2
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc9_14: %.5d4 = impl_witness_access constants.%ImplicitAs.impl_witness.1b5, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.868]
// CHECK:STDOUT:   %bound_method.loc9_14.1: <bound method> = bound_method %int_1, %impl.elem0.loc9_14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0ab]
// CHECK:STDOUT:   %specific_fn.loc9_14: <specific function> = specific_function %impl.elem0.loc9_14, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.cda]
// CHECK:STDOUT:   %bound_method.loc9_14.2: <bound method> = bound_method %int_1, %specific_fn.loc9_14 [concrete = constants.%bound_method.272]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_14: init %i8 = call %bound_method.loc9_14.2(%int_1) [concrete = constants.%int_1.f1e]
// CHECK:STDOUT:   %.loc9_14: init %i8 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_14 [concrete = constants.%int_1.f1e]
// CHECK:STDOUT:   assign %.loc9_12, %.loc9_14
// CHECK:STDOUT:   %Read.ref: %Read.type = name_ref Read, imports.%Main.Read [concrete = constants.%Read]
// CHECK:STDOUT:   %w.ref.loc10_15: ref %IntOrBytes = name_ref w, %w
// CHECK:STDOUT:   %.loc10_15: %IntOrBytes = acquire_value %w.ref.loc10_15
// CHECK:STDOUT:   %Read.call: init %i32 = call %Read.ref(%.loc10_15)
// CHECK:STDOUT:   %w.ref.loc10_20: ref %IntOrBytes = name_ref w, %w
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, imports.%Main.import_ref.a8c [concrete = imports.%field_decl.2be]
// CHECK:STDOUT:   %.loc10_21.1: ref %i32 = class_element_access %w.ref.loc10_20, element0
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc10_18.1: <bound method> = bound_method %Read.call, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc10_18.2: <bound method> = bound_method %Read.call, %specific_fn.loc10
// CHECK:STDOUT:   %.loc10_16.1: %i32 = value_of_initializer %Read.call
// CHECK:STDOUT:   %.loc10_16.2: %i32 = converted %Read.call, %.loc10_16.1
// CHECK:STDOUT:   %.loc10_21.2: %i32 = acquire_value %.loc10_21.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc10_18.2(%.loc10_16.2, %.loc10_21.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8: <bound method> = bound_method %w.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8(%w.var)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc7: <bound method> = bound_method %v.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc7: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc7(%v.var)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_3.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_3.2(%self.param: ref %i8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_3.2(%self.param: ref %i8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:   %.loc8_3.1: ref %i8 = array_index %self.param, %int_3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.1: <bound method> = bound_method %.loc8_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.1(%.loc8_3.1)
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc8_3.2: ref %i8 = array_index %self.param, %int_2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.2: <bound method> = bound_method %.loc8_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.2(%.loc8_3.2)
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc8_3.3: ref %i8 = array_index %self.param, %int_1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.3: <bound method> = bound_method %.loc8_3.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.3: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.3(%.loc8_3.3)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %.loc8_3.4: ref %i8 = array_index %self.param, %int_0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.4: <bound method> = bound_method %.loc8_3.4, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.4: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.4(%.loc8_3.4)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_3.3(%self.param: ref %array_type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_3.3(%self.param: ref %array_type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_3.4(%self.param: ref %.e9a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_3.4(%self.param: ref %.e9a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %bytes.ref: %IntOrBytes.elem.ff6 = name_ref bytes, imports.%Main.import_ref.184 [concrete = imports.%field_decl.bec]
// CHECK:STDOUT:   %.loc8_3.1: ref %array_type = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.1: <bound method> = bound_method %.loc8_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.1(%.loc8_3.1)
// CHECK:STDOUT:   %word.ref: %IntOrBytes.elem.a3f = name_ref word, imports.%Main.import_ref.a8c [concrete = imports.%field_decl.2be]
// CHECK:STDOUT:   %.loc8_3.2: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.2: <bound method> = bound_method %.loc8_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.2(%.loc8_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_3.5(%self.param: ref %IntOrBytes) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_3.5(%self.param: ref %IntOrBytes) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
