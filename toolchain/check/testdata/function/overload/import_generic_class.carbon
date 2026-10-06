// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/import_generic_class.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/import_generic_class.carbon

// An `overload fn` set declared in a generic class and reached through an
// import (fork/overload/plan.md OV-2, §1.B.1 and §1.B.5): the imported set's
// type carries the class's self specific (`OverloadSetType.specific_id`,
// localized with the set), so naming the set through `Box(i64)` in the
// importing library substitutes that specific exactly as it does in the
// declaring file (generic_class_method_set.carbon), and each committed callee
// is a specific function of the selected member.
//
// Spelling per R3: `T: Core.Copy` because `Make` copies its `t: T` parameter
// into the `tag` field.

// --- lib.carbon

library "[[@TEST_NAME]]";

class Box(T: Core.Copy) {
  var tag: T;
  var total: i32;
  fn Make(x: i32, t: T) -> Box(T) { return {.tag = t, .total = x}; }
  overload fn Add(ref self, n: i32) { self.total = self.total + n; }
  overload fn Add(ref self, b: bool) { if (b) { self.total = self.total + 100; } }
  fn Get(self) -> i32 { return self.total; }
}

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

//@dump-sem-ir-begin
fn Use() -> i32 {
  var b: Box(i64) = Box(i64).Make(1, 0 as i64);
  b.Add(1);
  b.Add(true);
  return b.Get();
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
// CHECK:STDOUT:   %Box.type: type = generic_class_type @Box [concrete]
// CHECK:STDOUT:   %Box.generic: %Box.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %T.f84: %Copy.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.c1c: type = facet_access_type %T.f84 [symbolic]
// CHECK:STDOUT:   %Box.fc8: type = class_type @Box, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Get.type.b71: type = fn_type @Box.Get, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Get.c3a: %Box.Get.type.b71 = struct_value () [symbolic]
// CHECK:STDOUT:   %Box.Add.type.1628b5.1: type = fn_type @Box.Add.1, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Add.b04003.1: %Box.Add.type.1628b5.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Box.Add.type.1628b5.2: type = fn_type @Box.Add.2, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Add.b04003.2: %Box.Add.type.1628b5.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %Box.Add.overload_set.type.e92: type = overload_set_type @Box.Add.overload_set, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Add.overload_set.value.cd4: %Box.Add.overload_set.type.e92 = overload_set_value @Box.Add.overload_set [symbolic]
// CHECK:STDOUT:   %Box.Make.type.fef: type = fn_type @Box.Make, @Box(%T.f84) [symbolic]
// CHECK:STDOUT:   %Box.Make.22d: %Box.Make.type.fef = struct_value () [symbolic]
// CHECK:STDOUT:   %Box.elem.adb: type = unbound_element_type %Box.fc8, %i32 [symbolic]
// CHECK:STDOUT:   %Box.elem.159: type = unbound_element_type %Box.fc8, %T.as_type.c1c [symbolic]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Copy.facet.4e9: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Box.ecf: type = class_type @Box, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.elem.e42: type = unbound_element_type %Box.ecf, %i64 [concrete]
// CHECK:STDOUT:   %Box.elem.269: type = unbound_element_type %Box.ecf, %i32 [concrete]
// CHECK:STDOUT:   %Box.Make.type.75b: type = fn_type @Box.Make, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Make.a2e: %Box.Make.type.75b = struct_value () [concrete]
// CHECK:STDOUT:   %Box.Add.type.0225c6.1: type = fn_type @Box.Add.2, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Add.a2595a.1: %Box.Add.type.0225c6.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Box.Add.overload_set.type.e34: type = overload_set_type @Box.Add.overload_set, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Add.overload_set.value.a4e: %Box.Add.overload_set.type.e34 = overload_set_value @Box.Add.overload_set [concrete]
// CHECK:STDOUT:   %Box.Add.type.0225c6.2: type = fn_type @Box.Add.1, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Add.a2595a.2: %Box.Add.type.0225c6.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Box.Get.type.10a: type = fn_type @Box.Get, @Box(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Get.7c5: %Box.Get.type.10a = struct_value () [concrete]
// CHECK:STDOUT:   %struct_type.tag.total.f3f: type = struct_type {.tag: %i64, .total: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.60e: type = pattern_type %Box.ecf [concrete]
// CHECK:STDOUT:   %b.patt.931: %pattern_type.60e = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.60e = var_pattern %b.patt.931 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %As.type.998: type = facet_type <@As, @As(%i64)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.c5d: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl.f25(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.6ee: %Core.IntLiteral.as.As.impl.Convert.type.c5d = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.0fe: <witness> = impl_witness imports.%As.impl_witness_table.d22, @Core.IntLiteral.as.As.impl.f25(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.1a1: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl.f25(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.3d9: %Core.IntLiteral.as.As.impl.Convert.type.1a1 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.998 = facet_value Core.IntLiteral, (%As.impl_witness.0fe) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.7f7: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i64, %As.facet) [concrete]
// CHECK:STDOUT:   %.8fd: type = fn_type_with_self_type %As.WithSelf.Convert.type.7f7, %As.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.As.impl.Convert.3d9 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.3d9, @Core.IntLiteral.as.As.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.585: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %Box.Make.specific_fn: <specific function> = specific_function %Box.Make.a2e, @Box.Make(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %self.param_patt.359: %pattern_type.60e = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.453: %pattern_type.60e = wrapper_binding_pattern self, %self.param_patt.359 [concrete]
// CHECK:STDOUT:   %Box.Add.specific_fn.784a5d.1: <specific function> = specific_function %Box.Add.a2595a.1, @Box.Add.2(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Box.Add.specific_fn.784a5d.2: <specific function> = specific_function %Box.Add.a2595a.2, @Box.Add.1(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %Box.Get.specific_fn: <specific function> = specific_function %Box.Get.7c5, @Box.Get(%Copy.facet.4e9) [concrete]
// CHECK:STDOUT:   %self.param_patt.108: %pattern_type.f57 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f4: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt.108 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc8_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc8_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.5ec: type = pattern_type %struct_type.tag.total.f3f [concrete]
// CHECK:STDOUT:   %self.param_patt.10e: %pattern_type.5ec = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.549: %pattern_type.5ec = wrapper_binding_pattern self, %self.param_patt.10e [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc8_3.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc8_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_3.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.Box: %Box.type = import_ref Main//lib, Box, loaded [concrete = constants.%Box.generic]
// CHECK:STDOUT:   %Box.Add.decl.1b0a6f.1: %Box.Add.type.1628b5.1 = fn_decl @Box.Add.1 [symbolic = @Box.%Box.Add.2 (constants.%Box.Add.b04003.1)] {} {}
// CHECK:STDOUT:   %Box.Add.decl.1b0a6f.2: %Box.Add.type.1628b5.2 = fn_decl @Box.Add.2 [symbolic = @Box.%Box.Add.1 (constants.%Box.Add.b04003.2)] {} {}
// CHECK:STDOUT:   %Main.import_ref.54a: @Box.%Box.elem.1 (%Box.elem.159) = import_ref Main//lib, loc5_10, loaded [concrete = %field_decl.d3a]
// CHECK:STDOUT:   %Main.import_ref.245: @Box.%Box.elem.2 (%Box.elem.adb) = import_ref Main//lib, loc6_12, loaded [concrete = %field_decl.49b]
// CHECK:STDOUT:   %Main.import_ref.a7d: @Box.%Box.Make.type (%Box.Make.type.fef) = import_ref Main//lib, loc7_35, loaded [symbolic = @Box.%Box.Make (constants.%Box.Make.22d)]
// CHECK:STDOUT:   %Main.import_ref.ee6: @Box.%Box.Add.overload_set.type (%Box.Add.overload_set.type.e92) = import_ref Main//lib, loc8_37, loaded [symbolic = @Box.%Box.Add.overload_set.value (constants.%Box.Add.overload_set.value.cd4)]
// CHECK:STDOUT:   %Main.import_ref.587: @Box.%Box.Get.type (%Box.Get.type.b71) = import_ref Main//lib, loc10_23, loaded [symbolic = @Box.%Box.Get (constants.%Box.Get.c3a)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl.f25 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Main.import_ref.69c = import_ref Main//lib, loc6_14, unloaded
// CHECK:STDOUT:   %field_decl.49b: @Box.%Box.elem.2 (%Box.elem.adb) = field_decl total, element1, %Main.import_ref.69c in [concrete] {}
// CHECK:STDOUT:   %Main.import_ref.127 = import_ref Main//lib, loc5_12, unloaded
// CHECK:STDOUT:   %field_decl.d3a: @Box.%Box.elem.1 (%Box.elem.159) = field_decl tag, element0, %Main.import_ref.127 in [concrete] {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc8_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc8_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_3.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.5ec = ref_param_pattern [concrete = constants.%self.param_patt.10e]
// CHECK:STDOUT:     %self.patt: %pattern_type.5ec = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.549]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.tag.total.f3f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.tag.total.f3f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc8_3.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.5ec = ref_param_pattern [concrete = constants.%self.param_patt.10e]
// CHECK:STDOUT:     %self.patt: %pattern_type.5ec = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.549]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.tag.total.f3f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.tag.total.f3f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_3.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.60e = ref_param_pattern [concrete = constants.%self.param_patt.359]
// CHECK:STDOUT:     %self.patt: %pattern_type.60e = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.453]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Box.ecf = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Box.ecf = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc8_3.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.60e = ref_param_pattern [concrete = constants.%self.param_patt.359]
// CHECK:STDOUT:     %self.patt: %pattern_type.60e = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.453]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Box.ecf = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Box.ecf = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc7: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.var: ref %Box.ecf = var_storage %b.var_patt
// CHECK:STDOUT:   %Box.ref.loc8_21: %Box.type = name_ref Box, imports.%Main.Box [concrete = constants.%Box.generic]
// CHECK:STDOUT:   %i64.loc8_25: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %Copy.facet.loc8_28: %Copy.type = facet_value %i64.loc8_25, (constants.%Copy.impl_witness.8cc) [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %.loc8_28: %Copy.type = converted %i64.loc8_25, %Copy.facet.loc8_28 [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %Box.loc8_28: type = class_type @Box, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.ecf]
// CHECK:STDOUT:   %.loc8_29: %Box.Make.type.75b = specific_constant imports.%Main.import_ref.a7d, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Make.a2e]
// CHECK:STDOUT:   %Make.ref: %Box.Make.type.75b = name_ref Make, %.loc8_29 [concrete = constants.%Box.Make.a2e]
// CHECK:STDOUT:   %int_1.loc8: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %i64.loc8_43: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0.loc8_40: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc8_40.1: <bound method> = bound_method %int_0, %impl.elem0.loc8_40 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc8_40: <specific function> = specific_function %impl.elem0.loc8_40, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_40.2: <bound method> = bound_method %int_0, %specific_fn.loc8_40 [concrete = constants.%bound_method.585]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call: init %i64 = call %bound_method.loc8_40.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc8_40.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc8_40.2: %i64 = converted %int_0, %.loc8_40.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %Copy.facet.loc8_46.1: %Copy.type = facet_value constants.%i64, (constants.%Copy.impl_witness.8cc) [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %.loc8_46.1: %Copy.type = converted constants.%i64, %Copy.facet.loc8_46.1 [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %Copy.facet.loc8_46.2: %Copy.type = facet_value constants.%i64, (constants.%Copy.impl_witness.8cc) [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %.loc8_46.2: %Copy.type = converted constants.%i64, %Copy.facet.loc8_46.2 [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:   %Box.Make.specific_fn: <specific function> = specific_function %Make.ref, @Box.Make(constants.%Copy.facet.4e9) [concrete = constants.%Box.Make.specific_fn]
// CHECK:STDOUT:   %.loc8_3: ref %Box.ecf = splice_block %b.var {}
// CHECK:STDOUT:   %impl.elem0.loc8_35: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_35.1: <bound method> = bound_method %int_1.loc8, %impl.elem0.loc8_35 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc8_35: <specific function> = specific_function %impl.elem0.loc8_35, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_35.2: <bound method> = bound_method %int_1.loc8, %specific_fn.loc8_35 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %i32 = call %bound_method.loc8_35.2(%int_1.loc8) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_35.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_35.2: %i32 = converted %int_1.loc8, %.loc8_35.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Box.Make.call: init %Box.ecf to %.loc8_3 = call %Box.Make.specific_fn(%.loc8_35.2, %.loc8_40.2)
// CHECK:STDOUT:   assign %b.var, %Box.Make.call
// CHECK:STDOUT:   %.loc8_17.1: type = splice_block %Box.loc8_17 [concrete = constants.%Box.ecf] {
// CHECK:STDOUT:     %Box.ref.loc8_10: %Box.type = name_ref Box, imports.%Main.Box [concrete = constants.%Box.generic]
// CHECK:STDOUT:     %i64.loc8_14: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %Copy.facet.loc8_17: %Copy.type = facet_value %i64.loc8_14, (constants.%Copy.impl_witness.8cc) [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:     %.loc8_17.2: %Copy.type = converted %i64.loc8_14, %Copy.facet.loc8_17 [concrete = constants.%Copy.facet.4e9]
// CHECK:STDOUT:     %Box.loc8_17: type = class_type @Box, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.ecf]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: ref %Box.ecf = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.60e = ref_binding_pattern b [concrete = constants.%b.patt.931]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.60e = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.ref.loc9: ref %Box.ecf = name_ref b, %b
// CHECK:STDOUT:   %.loc9_4: %Box.Add.overload_set.type.e34 = specific_constant imports.%Main.import_ref.ee6, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.overload_set.value.a4e]
// CHECK:STDOUT:   %Add.ref.loc9_4: %Box.Add.overload_set.type.e34 = name_ref Add, %.loc9_4 [concrete = constants.%Box.Add.overload_set.value.a4e]
// CHECK:STDOUT:   %bound_method.loc9_4: <bound method> = bound_method %b.ref.loc9, %Add.ref.loc9_4
// CHECK:STDOUT:   %int_1.loc9: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc9_10: %Box.Add.type.1628b5.2 = specific_constant imports.%Box.Add.decl.1b0a6f.2, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.a2595a.1]
// CHECK:STDOUT:   %Add.ref.loc9_10: %Box.Add.type.1628b5.2 = name_ref Add, %.loc9_10 [concrete = constants.%Box.Add.a2595a.1]
// CHECK:STDOUT:   %Box.Add.bound.loc9: <bound method> = bound_method %b.ref.loc9, %Add.ref.loc9_10
// CHECK:STDOUT:   %Box.Add.specific_fn.loc9: <specific function> = specific_function %Add.ref.loc9_10, @Box.Add.2(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.specific_fn.784a5d.1]
// CHECK:STDOUT:   %bound_method.loc9_10: <bound method> = bound_method %b.ref.loc9, %Box.Add.specific_fn.loc9
// CHECK:STDOUT:   %impl.elem0.loc9: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_9.1: <bound method> = bound_method %int_1.loc9, %impl.elem0.loc9 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_9.2: <bound method> = bound_method %int_1.loc9, %specific_fn.loc9 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %i32 = call %bound_method.loc9_9.2(%int_1.loc9) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_9.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_9.2: %i32 = converted %int_1.loc9, %.loc9_9.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Box.Add.call.loc9: init %empty_tuple.type = call %bound_method.loc9_10(%b.ref.loc9, %.loc9_9.2)
// CHECK:STDOUT:   %b.ref.loc10: ref %Box.ecf = name_ref b, %b
// CHECK:STDOUT:   %.loc10_4: %Box.Add.overload_set.type.e34 = specific_constant imports.%Main.import_ref.ee6, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.overload_set.value.a4e]
// CHECK:STDOUT:   %Add.ref.loc10_4: %Box.Add.overload_set.type.e34 = name_ref Add, %.loc10_4 [concrete = constants.%Box.Add.overload_set.value.a4e]
// CHECK:STDOUT:   %bound_method.loc10_4: <bound method> = bound_method %b.ref.loc10, %Add.ref.loc10_4
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc10_13: %Box.Add.type.1628b5.1 = specific_constant imports.%Box.Add.decl.1b0a6f.1, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.a2595a.2]
// CHECK:STDOUT:   %Add.ref.loc10_13: %Box.Add.type.1628b5.1 = name_ref Add, %.loc10_13 [concrete = constants.%Box.Add.a2595a.2]
// CHECK:STDOUT:   %Box.Add.bound.loc10: <bound method> = bound_method %b.ref.loc10, %Add.ref.loc10_13
// CHECK:STDOUT:   %Box.Add.specific_fn.loc10: <specific function> = specific_function %Add.ref.loc10_13, @Box.Add.1(constants.%Copy.facet.4e9) [concrete = constants.%Box.Add.specific_fn.784a5d.2]
// CHECK:STDOUT:   %bound_method.loc10_13: <bound method> = bound_method %b.ref.loc10, %Box.Add.specific_fn.loc10
// CHECK:STDOUT:   %Box.Add.call.loc10: init %empty_tuple.type = call %bound_method.loc10_13(%b.ref.loc10, %true)
// CHECK:STDOUT:   %b.ref.loc11: ref %Box.ecf = name_ref b, %b
// CHECK:STDOUT:   %.loc11_11: %Box.Get.type.10a = specific_constant imports.%Main.import_ref.587, @Box(constants.%Copy.facet.4e9) [concrete = constants.%Box.Get.7c5]
// CHECK:STDOUT:   %Get.ref: %Box.Get.type.10a = name_ref Get, %.loc11_11 [concrete = constants.%Box.Get.7c5]
// CHECK:STDOUT:   %Box.Get.bound: <bound method> = bound_method %b.ref.loc11, %Get.ref
// CHECK:STDOUT:   %Box.Get.specific_fn: <specific function> = specific_function %Get.ref, @Box.Get(constants.%Copy.facet.4e9) [concrete = constants.%Box.Get.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11: <bound method> = bound_method %b.ref.loc11, %Box.Get.specific_fn
// CHECK:STDOUT:   %.loc11_10: %Box.ecf = acquire_value %b.ref.loc11
// CHECK:STDOUT:   %Box.Get.call: init %i32 = call %bound_method.loc11(%.loc11_10)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %b.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%b.var)
// CHECK:STDOUT:   return %Box.Get.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_3.1(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_3.1(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_3.1(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_3.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_3.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_3.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_3.3(%self.param: ref %struct_type.tag.total.f3f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc8_3.1: ref %i32 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.1: <bound method> = bound_method %.loc8_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.1(%.loc8_3.1)
// CHECK:STDOUT:   %.loc8_3.2: ref %i64 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.2: <bound method> = bound_method %.loc8_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.2(%.loc8_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_3.3(%self.param: ref %struct_type.tag.total.f3f) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_3.3(%self.param: ref %struct_type.tag.total.f3f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_3.4(%self.param: ref %Box.ecf) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %total.ref: %Box.elem.269 = name_ref total, imports.%Main.import_ref.245 [concrete = imports.%field_decl.49b]
// CHECK:STDOUT:   %.loc8_3.1: ref %i32 = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.1: <bound method> = bound_method %.loc8_3.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.1(%.loc8_3.1)
// CHECK:STDOUT:   %tag.ref: %Box.elem.e42 = name_ref tag, imports.%Main.import_ref.54a [concrete = imports.%field_decl.d3a]
// CHECK:STDOUT:   %.loc8_3.2: ref %i64 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_3.2: <bound method> = bound_method %.loc8_3.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_3.2(%.loc8_3.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_3.4(%self.param: ref %Box.ecf) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_3.4(%self.param: ref %Box.ecf) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
