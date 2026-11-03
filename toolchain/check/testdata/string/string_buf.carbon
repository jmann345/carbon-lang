// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/string/string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/string/string_buf.carbon

// Fork (ST-1, fork/string/plan.md §4): the owning `Core.StringBuf`
// (D-ST-4..7).

// --- concat.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Concat(a: str, b: str) -> Core.StringBuf { return a + b; }
fn Chain(a: str) -> Core.StringBuf { return a + a + a; }
fn Dup(s: Core.StringBuf) -> Core.StringBuf { return Core.StringBuf.Make(s); }
//@dump-sem-ir-end

// --- append.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Append(s: str) -> i64 {
  var b: Core.StringBuf = Core.StringBuf.Make(s);
  b += "!";
  b += b;
  return b.Size();
}
//@dump-sem-ir-end

// --- view.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn View(b: Core.StringBuf) -> str { return b; }
fn LetView(a: str) -> i64 {
  var c: Core.StringBuf = a + a;
  let v: str = c;
  return v.Size();
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- concat.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %str: type = class_type @String [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %ptr.b46: type = ptr_type %char [concrete]
// CHECK:STDOUT:   %struct_type.ptr.size: type = struct_type {.ptr: %ptr.b46, .size: %i64} [concrete]
// CHECK:STDOUT:   %pattern_type.adf: type = pattern_type %str [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.adf = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.adf = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.adf = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %StringBuf: type = class_type @StringBuf [concrete]
// CHECK:STDOUT:   %.f4d: Core.Form = init_form %StringBuf [concrete]
// CHECK:STDOUT:   %pattern_type.5d2: type = pattern_type %StringBuf [concrete]
// CHECK:STDOUT:   %return.param_patt.9c2: %pattern_type.5d2 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c9e: %pattern_type.5d2 = return_slot_pattern %return.param_patt.9c2, %StringBuf [concrete]
// CHECK:STDOUT:   %Concat.type: type = fn_type @Concat [concrete]
// CHECK:STDOUT:   %Concat: %Concat.type = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.75d: type = facet_type <@AddWith, @AddWith(%str)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.073: <witness> = impl_witness imports.%AddWith.impl_witness_table.73b [concrete]
// CHECK:STDOUT:   %AddWith.facet.ac4: %AddWith.type.75d = facet_value %str, (%AddWith.impl_witness.073) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.dc2: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%str, %AddWith.facet.ac4) [concrete]
// CHECK:STDOUT:   %.7a2: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.dc2, %AddWith.facet.ac4 [concrete]
// CHECK:STDOUT:   %str.as.AddWith.impl.Op.type: type = fn_type @str.as.AddWith.impl.Op [concrete]
// CHECK:STDOUT:   %str.as.AddWith.impl.Op: %str.as.AddWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Chain.type: type = fn_type @Chain [concrete]
// CHECK:STDOUT:   %Chain: %Chain.type = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.aaa: <witness> = impl_witness imports.%AddWith.impl_witness_table.bf2 [concrete]
// CHECK:STDOUT:   %AddWith.facet.81e: %AddWith.type.75d = facet_value %StringBuf, (%AddWith.impl_witness.aaa) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.272: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%str, %AddWith.facet.81e) [concrete]
// CHECK:STDOUT:   %.4fb: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.272, %AddWith.facet.81e [concrete]
// CHECK:STDOUT:   %StringBuf.as.AddWith.impl.Op.type: type = fn_type @StringBuf.as.AddWith.impl.Op [concrete]
// CHECK:STDOUT:   %StringBuf.as.AddWith.impl.Op: %StringBuf.as.AddWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.impl_witness: <witness> = impl_witness imports.%Destroy.impl_witness_table [concrete]
// CHECK:STDOUT:   %Destroy.facet.7b9: %Destroy.type = facet_value %StringBuf, (%Destroy.impl_witness) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.3ac: type = fn_type @Destroy.WithSelf.SubobjectDestroy.1, @Destroy.WithSelf(%Destroy.facet.7b9) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.a17: %Destroy.WithSelf.SubobjectDestroy.type.3ac = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.17f: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.7b9) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.65f: %Destroy.WithSelf.SelfDestruct.type.17f = struct_value () [concrete]
// CHECK:STDOUT:   %s.param_patt.9a2: %pattern_type.5d2 = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt.929: %pattern_type.5d2 = wrapper_binding_pattern s, %s.param_patt.9a2 [concrete]
// CHECK:STDOUT:   %Dup.type: type = fn_type @Dup [concrete]
// CHECK:STDOUT:   %Dup: %Dup.type = struct_value () [concrete]
// CHECK:STDOUT:   %StringBuf.Make.type: type = fn_type @StringBuf.Make [concrete]
// CHECK:STDOUT:   %StringBuf.Make: %StringBuf.Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.30b: type = facet_type <@ImplicitAs, @ImplicitAs(%str)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.77c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.717 [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.30b = facet_value %StringBuf, (%ImplicitAs.impl_witness.77c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.c4b: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%str, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b84: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.c4b, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %StringBuf.as.ImplicitAs.impl.Convert.type: type = fn_type @StringBuf.as.ImplicitAs.impl.Convert [concrete]
// CHECK:STDOUT:   %StringBuf.as.ImplicitAs.impl.Convert: %StringBuf.as.ImplicitAs.impl.Convert.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.854: type = pattern_type %ptr.b46 [concrete]
// CHECK:STDOUT:   %self.param_patt.b83: %pattern_type.854 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.f58: %pattern_type.854 = wrapper_binding_pattern self, %self.param_patt.b83 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc7_74.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc7_74.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc7_74.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %self.param_patt.108: %pattern_type.f57 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f4: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt.108 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc7_74.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc7_74.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc7_74.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.8af: type = pattern_type %struct_type.ptr.size [concrete]
// CHECK:STDOUT:   %self.param_patt.9fd: %pattern_type.8af = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.95d: %pattern_type.8af = wrapper_binding_pattern self, %self.param_patt.9fd [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc7_74.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc7_74.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.dc5: %pattern_type.adf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.939: %pattern_type.adf = wrapper_binding_pattern self, %self.param_patt.dc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc7_74.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %String.elem.f15: type = unbound_element_type %str, %i64 [concrete]
// CHECK:STDOUT:   %String.elem.0b2: type = unbound_element_type %str, %ptr.b46 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc7_74.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc7_74.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %StringBuf.as.Destroy.impl.Op.type: type = fn_type @StringBuf.as.Destroy.impl.Op [concrete]
// CHECK:STDOUT:   %StringBuf.as.Destroy.impl.Op: %StringBuf.as.Destroy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .String = %Core.String
// CHECK:STDOUT:     .StringBuf = %Core.StringBuf
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.String: type = import_ref Core//prelude/types/string, String, loaded [concrete = constants.%str]
// CHECK:STDOUT:   %Core.import_ref.c9c: %String.elem.0b2 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = %field_decl.b1e]
// CHECK:STDOUT:   %Core.import_ref.704: %String.elem.f15 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = %field_decl.e70]
// CHECK:STDOUT:   %Core.StringBuf: type = import_ref Core//prelude/types/string, StringBuf, loaded [concrete = constants.%StringBuf]
// CHECK:STDOUT:   %Core.import_ref.49e: %StringBuf.Make.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.Make]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.194468.1 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3475.1: %str.as.AddWith.impl.Op.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%str.as.AddWith.impl.Op]
// CHECK:STDOUT:   %AddWith.impl_witness_table.73b = impl_witness_table (%Core.import_ref.194468.1, %Core.import_ref.9c3475.1), @str.as.AddWith.impl.c80 [concrete]
// CHECK:STDOUT:   %Core.import_ref.194468.2 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3475.2: %StringBuf.as.AddWith.impl.Op.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.AddWith.impl.Op]
// CHECK:STDOUT:   %AddWith.impl_witness_table.bf2 = impl_witness_table (%Core.import_ref.194468.2, %Core.import_ref.9c3475.2), @StringBuf.as.AddWith.impl.833 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.3486: %StringBuf.as.Destroy.impl.Op.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.Destroy.impl.Op]
// CHECK:STDOUT:   %Core.import_ref.054: %Destroy.WithSelf.SubobjectDestroy.type.3ac = import_ref Core//prelude/types/string, inst{{[0-9A-F]+}} [no loc], loaded [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.a17]
// CHECK:STDOUT:   %Core.import_ref.e4c: %Destroy.WithSelf.SelfDestruct.type.17f = import_ref Core//prelude/types/string, inst{{[0-9A-F]+}} [no loc], loaded [concrete = constants.%Destroy.WithSelf.SelfDestruct.65f]
// CHECK:STDOUT:   %Destroy.impl_witness_table = impl_witness_table (%Core.import_ref.3486, %Core.import_ref.054, %Core.import_ref.e4c), @StringBuf.as.Destroy.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.06c: %StringBuf.as.ImplicitAs.impl.Convert.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.ImplicitAs.impl.Convert]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.717 = impl_witness_table (%Core.import_ref.06c), @StringBuf.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.9cc = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %field_decl.e70: %String.elem.f15 = field_decl size, element1, %Core.import_ref.9cc in [concrete] {}
// CHECK:STDOUT:   %Core.import_ref.be6 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %field_decl.b1e: %String.elem.0b2 = field_decl ptr, element0, %Core.import_ref.be6 in [concrete] {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc7_74.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.854 = ref_param_pattern [concrete = constants.%self.param_patt.b83]
// CHECK:STDOUT:     %self.patt: %pattern_type.854 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.f58]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ptr.b46 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ptr.b46 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc7_74.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.854 = ref_param_pattern [concrete = constants.%self.param_patt.b83]
// CHECK:STDOUT:     %self.patt: %pattern_type.854 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.f58]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ptr.b46 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ptr.b46 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc7_74.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc7_74.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc7_74.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.8af = ref_param_pattern [concrete = constants.%self.param_patt.9fd]
// CHECK:STDOUT:     %self.patt: %pattern_type.8af = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.95d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.ptr.size = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.ptr.size = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc7_74.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.8af = ref_param_pattern [concrete = constants.%self.param_patt.9fd]
// CHECK:STDOUT:     %self.patt: %pattern_type.8af = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.95d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.ptr.size = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.ptr.size = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc7_74.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.adf = ref_param_pattern [concrete = constants.%self.param_patt.dc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.adf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.939]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %str = ref_param call_param0
// CHECK:STDOUT:     %self: ref %str = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc7_74.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.adf = ref_param_pattern [concrete = constants.%self.param_patt.dc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.adf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.939]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %str = ref_param call_param0
// CHECK:STDOUT:     %self: ref %str = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Concat.decl: %Concat.type = fn_decl @Concat [concrete = constants.%Concat] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %b.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.adf = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5d2 = out_param_pattern [concrete = constants.%return.param_patt.9c2]
// CHECK:STDOUT:     %return.patt: %pattern_type.5d2 = return_slot_pattern %return.param_patt, %StringBuf.ref [concrete = constants.%return.patt.c9e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %StringBuf.ref: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     %.loc5_34.2: Core.Form = init_form %StringBuf.ref [concrete = constants.%.f4d]
// CHECK:STDOUT:     %a.param: %str = value_param call_param0
// CHECK:STDOUT:     %str.loc5_14: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %a: %str = wrapper_binding a, %a.param
// CHECK:STDOUT:     %b.param: %str = value_param call_param1
// CHECK:STDOUT:     %str.loc5_22: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %b: %str = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %StringBuf = out_param call_param2
// CHECK:STDOUT:     %return: ref %StringBuf = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Chain.decl: %Chain.type = fn_decl @Chain [concrete = constants.%Chain] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5d2 = out_param_pattern [concrete = constants.%return.param_patt.9c2]
// CHECK:STDOUT:     %return.patt: %pattern_type.5d2 = return_slot_pattern %return.param_patt, %StringBuf.ref [concrete = constants.%return.patt.c9e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %StringBuf.ref: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     %.loc6_25.2: Core.Form = init_form %StringBuf.ref [concrete = constants.%.f4d]
// CHECK:STDOUT:     %a.param: %str = value_param call_param0
// CHECK:STDOUT:     %str: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %a: %str = wrapper_binding a, %a.param
// CHECK:STDOUT:     %return.param: ref %StringBuf = out_param call_param1
// CHECK:STDOUT:     %return: ref %StringBuf = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Dup.decl: %Dup.type = fn_decl @Dup [concrete = constants.%Dup] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.5d2 = value_param_pattern [concrete = constants.%s.param_patt.9a2]
// CHECK:STDOUT:     %s.patt: %pattern_type.5d2 = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt.929]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.5d2 = out_param_pattern [concrete = constants.%return.param_patt.9c2]
// CHECK:STDOUT:     %return.patt: %pattern_type.5d2 = return_slot_pattern %return.param_patt, %StringBuf.ref.loc7_34 [concrete = constants.%return.patt.c9e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc7_30: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %StringBuf.ref.loc7_34: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     %.loc7_34.2: Core.Form = init_form %StringBuf.ref.loc7_34 [concrete = constants.%.f4d]
// CHECK:STDOUT:     %s.param: %StringBuf = value_param call_param0
// CHECK:STDOUT:     %.loc7_15: type = splice_block %StringBuf.ref.loc7_15 [concrete = constants.%StringBuf] {
// CHECK:STDOUT:       %Core.ref.loc7_11: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %StringBuf.ref.loc7_15: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: %StringBuf = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref %StringBuf = out_param call_param1
// CHECK:STDOUT:     %return: ref %StringBuf = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Concat(%a.param: %str, %b.param: %str) -> out %return.param: %StringBuf {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref: %str = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %str = name_ref b, %b
// CHECK:STDOUT:   %impl.elem1: %.7a2 = impl_witness_access constants.%AddWith.impl_witness.073, element1 [concrete = constants.%str.as.AddWith.impl.Op]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %a.ref, %impl.elem1
// CHECK:STDOUT:   %.loc5_34.1: ref %StringBuf = splice_block %return.param {}
// CHECK:STDOUT:   %str.as.AddWith.impl.Op.call: init %StringBuf to %.loc5_34.1 = call %bound_method(%a.ref, %b.ref)
// CHECK:STDOUT:   return %str.as.AddWith.impl.Op.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Chain(%a.param: %str) -> out %return.param: %StringBuf {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.ref.loc6_45: %str = name_ref a, %a
// CHECK:STDOUT:   %a.ref.loc6_49: %str = name_ref a, %a
// CHECK:STDOUT:   %impl.elem1.loc6_47: %.7a2 = impl_witness_access constants.%AddWith.impl_witness.073, element1 [concrete = constants.%str.as.AddWith.impl.Op]
// CHECK:STDOUT:   %bound_method.loc6_47.1: <bound method> = bound_method %a.ref.loc6_45, %impl.elem1.loc6_47
// CHECK:STDOUT:   %.loc6_47.1: ref %StringBuf = temporary_storage
// CHECK:STDOUT:   %str.as.AddWith.impl.Op.call: init %StringBuf to %.loc6_47.1 = call %bound_method.loc6_47.1(%a.ref.loc6_45, %a.ref.loc6_49)
// CHECK:STDOUT:   %a.ref.loc6_53: %str = name_ref a, %a
// CHECK:STDOUT:   %impl.elem1.loc6_51: %.4fb = impl_witness_access constants.%AddWith.impl_witness.aaa, element1 [concrete = constants.%StringBuf.as.AddWith.impl.Op]
// CHECK:STDOUT:   %bound_method.loc6_51: <bound method> = bound_method %str.as.AddWith.impl.Op.call, %impl.elem1.loc6_51
// CHECK:STDOUT:   %.loc6_25.1: ref %StringBuf = splice_block %return.param {}
// CHECK:STDOUT:   %.loc6_47.2: ref %StringBuf = temporary %.loc6_47.1, %str.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc6_47.3: %StringBuf = acquire_value %.loc6_47.2
// CHECK:STDOUT:   %StringBuf.as.AddWith.impl.Op.call: init %StringBuf to %.loc6_25.1 = call %bound_method.loc6_51(%.loc6_47.3, %a.ref.loc6_53)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc6_47.2, constants.%Destroy.WithSelf.SelfDestruct.65f
// CHECK:STDOUT:   %Destroy.facet.loc6_47.1: %Destroy.type = facet_value constants.%StringBuf, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet.7b9]
// CHECK:STDOUT:   %.loc6_47.4: %Destroy.type = converted constants.%StringBuf, %Destroy.facet.loc6_47.1 [concrete = constants.%Destroy.facet.7b9]
// CHECK:STDOUT:   %Destroy.facet.loc6_47.2: %Destroy.type = facet_value constants.%StringBuf, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet.7b9]
// CHECK:STDOUT:   %.loc6_47.5: %Destroy.type = converted constants.%StringBuf, %Destroy.facet.loc6_47.2 [concrete = constants.%Destroy.facet.7b9]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %bound_method.loc6_47.2: <bound method> = bound_method %.loc6_47.2, %Destroy.WithSelf.SelfDestruct.specific_fn
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method.loc6_47.2(%.loc6_47.2)
// CHECK:STDOUT:   return %StringBuf.as.AddWith.impl.Op.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Dup(%s.param: %StringBuf) -> out %return.param: %StringBuf {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc7_54: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %StringBuf.ref.loc7_58: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:   %Make.ref: %StringBuf.Make.type = name_ref Make, imports.%Core.import_ref.49e [concrete = constants.%StringBuf.Make]
// CHECK:STDOUT:   %s.ref: %StringBuf = name_ref s, %s
// CHECK:STDOUT:   %.loc7_34.1: ref %StringBuf = splice_block %return.param {}
// CHECK:STDOUT:   %impl.elem0: %.b84 = impl_witness_access constants.%ImplicitAs.impl_witness.77c, element0 [concrete = constants.%StringBuf.as.ImplicitAs.impl.Convert]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %s.ref, %impl.elem0
// CHECK:STDOUT:   %.loc7_74.1: ref %str = temporary_storage
// CHECK:STDOUT:   %StringBuf.as.ImplicitAs.impl.Convert.call: init %str to %.loc7_74.1 = call %bound_method(%s.ref)
// CHECK:STDOUT:   %.loc7_74.2: init %str = converted %s.ref, %StringBuf.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc7_74.3: ref %str = temporary %.loc7_74.1, %.loc7_74.2
// CHECK:STDOUT:   %.loc7_74.4: %str = acquire_value %.loc7_74.3
// CHECK:STDOUT:   %StringBuf.Make.call: init %StringBuf to %.loc7_34.1 = call %Make.ref(%.loc7_74.4)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc7_74.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc7_74.3)
// CHECK:STDOUT:   return %StringBuf.Make.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc7_74.1(%self.param: ref %ptr.b46) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc7_74.1(%self.param: ref %ptr.b46) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc7_74.1(%self.param: ref %ptr.b46) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc7_74.2(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc7_74.2(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc7_74.2(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc7_74.3(%self.param: ref %struct_type.ptr.size) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc7_74.1: ref %i64 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc7_74.1: <bound method> = bound_method %.loc7_74.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc7_74.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc7_74.1(%.loc7_74.1)
// CHECK:STDOUT:   %.loc7_74.2: ref %ptr.b46 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc7_74.2: <bound method> = bound_method %.loc7_74.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc7_74.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc7_74.2(%.loc7_74.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc7_74.3(%self.param: ref %struct_type.ptr.size) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc7_74.3(%self.param: ref %struct_type.ptr.size) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc7_74.4(%self.param: ref %str) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %size.ref: %String.elem.f15 = name_ref size, imports.%Core.import_ref.704 [concrete = imports.%field_decl.e70]
// CHECK:STDOUT:   %.loc7_74.1: ref %i64 = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc7_74.1: <bound method> = bound_method %.loc7_74.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc7_74.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc7_74.1(%.loc7_74.1)
// CHECK:STDOUT:   %ptr.ref: %String.elem.0b2 = name_ref ptr, imports.%Core.import_ref.c9c [concrete = imports.%field_decl.b1e]
// CHECK:STDOUT:   %.loc7_74.2: ref %ptr.b46 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc7_74.2: <bound method> = bound_method %.loc7_74.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc7_74.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc7_74.2(%.loc7_74.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc7_74.4(%self.param: ref %str) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc7_74.4(%self.param: ref %str) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- append.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %str.3d4: type = class_type @String [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %ptr.b46: type = ptr_type %char [concrete]
// CHECK:STDOUT:   %pattern_type.adf: type = pattern_type %str.3d4 [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.adf = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.adf = wrapper_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Append.type: type = fn_type @Append [concrete]
// CHECK:STDOUT:   %Append: %Append.type = struct_value () [concrete]
// CHECK:STDOUT:   %StringBuf: type = class_type @StringBuf [concrete]
// CHECK:STDOUT:   %pattern_type.5d2: type = pattern_type %StringBuf [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.5d2 = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.5d2 = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   %StringBuf.Make.type: type = fn_type @StringBuf.Make [concrete]
// CHECK:STDOUT:   %StringBuf.Make: %StringBuf.Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %str.57d: %ptr.b46 = string_literal "!" [concrete]
// CHECK:STDOUT:   %int_1: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %String.val: %str.3d4 = struct_value (%str.57d, %int_1) [concrete]
// CHECK:STDOUT:   %AddAssignWith.type.2fb: type = generic_interface_type @AddAssignWith [concrete]
// CHECK:STDOUT:   %AddAssignWith.generic: %AddAssignWith.type.2fb = struct_value () [concrete]
// CHECK:STDOUT:   %AddAssignWith.type.63d: type = facet_type <@AddAssignWith, @AddAssignWith(%str.3d4)> [concrete]
// CHECK:STDOUT:   %AddAssignWith.type.d77: type = facet_type <@AddAssignWith, @AddAssignWith(%StringBuf)> [concrete]
// CHECK:STDOUT:   %AddAssignWith.impl_witness.312: <witness> = impl_witness imports.%AddAssignWith.impl_witness_table.199 [concrete]
// CHECK:STDOUT:   %AddAssignWith.facet.764: %AddAssignWith.type.63d = facet_value %StringBuf, (%AddAssignWith.impl_witness.312) [concrete]
// CHECK:STDOUT:   %AddAssignWith.WithSelf.Op.type.8b1: type = fn_type @AddAssignWith.WithSelf.Op, @AddAssignWith.WithSelf(%str.3d4, %AddAssignWith.facet.764) [concrete]
// CHECK:STDOUT:   %.e13: type = fn_type_with_self_type %AddAssignWith.WithSelf.Op.type.8b1, %AddAssignWith.facet.764 [concrete]
// CHECK:STDOUT:   %StringBuf.as.AddAssignWith.impl.Op.type.43d658.1: type = fn_type @StringBuf.as.AddAssignWith.impl.Op.1 [concrete]
// CHECK:STDOUT:   %StringBuf.as.AddAssignWith.impl.Op.cc70d5.1: %StringBuf.as.AddAssignWith.impl.Op.type.43d658.1 = struct_value () [concrete]
// CHECK:STDOUT:   %AddAssignWith.impl_witness.97f: <witness> = impl_witness imports.%AddAssignWith.impl_witness_table.aa0 [concrete]
// CHECK:STDOUT:   %AddAssignWith.facet.663: %AddAssignWith.type.d77 = facet_value %StringBuf, (%AddAssignWith.impl_witness.97f) [concrete]
// CHECK:STDOUT:   %AddAssignWith.WithSelf.Op.type.b3c: type = fn_type @AddAssignWith.WithSelf.Op, @AddAssignWith.WithSelf(%StringBuf, %AddAssignWith.facet.663) [concrete]
// CHECK:STDOUT:   %.ea1: type = fn_type_with_self_type %AddAssignWith.WithSelf.Op.type.b3c, %AddAssignWith.facet.663 [concrete]
// CHECK:STDOUT:   %StringBuf.as.AddAssignWith.impl.Op.type.43d658.2: type = fn_type @StringBuf.as.AddAssignWith.impl.Op.2 [concrete]
// CHECK:STDOUT:   %StringBuf.as.AddAssignWith.impl.Op.cc70d5.2: %StringBuf.as.AddAssignWith.impl.Op.type.43d658.2 = struct_value () [concrete]
// CHECK:STDOUT:   %StringBuf.Size.type: type = fn_type @StringBuf.Size [concrete]
// CHECK:STDOUT:   %StringBuf.Size: %StringBuf.Size.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.impl_witness: <witness> = impl_witness imports.%Destroy.impl_witness_table [concrete]
// CHECK:STDOUT:   %Destroy.facet: %Destroy.type = facet_value %StringBuf, (%Destroy.impl_witness) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.3ac: type = fn_type @Destroy.WithSelf.SubobjectDestroy, @Destroy.WithSelf(%Destroy.facet) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.a17: %Destroy.WithSelf.SubobjectDestroy.type.3ac = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.17f: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.65f: %Destroy.WithSelf.SelfDestruct.type.17f = struct_value () [concrete]
// CHECK:STDOUT:   %StringBuf.as.Destroy.impl.Op.type: type = fn_type @StringBuf.as.Destroy.impl.Op [concrete]
// CHECK:STDOUT:   %StringBuf.as.Destroy.impl.Op: %StringBuf.as.Destroy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .String = %Core.String
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .StringBuf = %Core.StringBuf
// CHECK:STDOUT:     .AddAssignWith = %Core.AddAssignWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.String: type = import_ref Core//prelude/types/string, String, loaded [concrete = constants.%str.3d4]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.StringBuf: type = import_ref Core//prelude/types/string, StringBuf, loaded [concrete = constants.%StringBuf]
// CHECK:STDOUT:   %Core.import_ref.49e: %StringBuf.Make.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.Make]
// CHECK:STDOUT:   %Core.import_ref.d0c: %StringBuf.Size.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.Size]
// CHECK:STDOUT:   %Core.AddAssignWith: %AddAssignWith.type.2fb = import_ref Core//prelude/operators/arithmetic, AddAssignWith, loaded [concrete = constants.%AddAssignWith.generic]
// CHECK:STDOUT:   %Core.import_ref.3486f7.1: %StringBuf.as.AddAssignWith.impl.Op.type.43d658.1 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.AddAssignWith.impl.Op.cc70d5.1]
// CHECK:STDOUT:   %AddAssignWith.impl_witness_table.199 = impl_witness_table (%Core.import_ref.3486f7.1), @StringBuf.as.AddAssignWith.impl.392 [concrete]
// CHECK:STDOUT:   %Core.import_ref.9c3: %StringBuf.as.AddAssignWith.impl.Op.type.43d658.2 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.AddAssignWith.impl.Op.cc70d5.2]
// CHECK:STDOUT:   %AddAssignWith.impl_witness_table.aa0 = impl_witness_table (%Core.import_ref.9c3), @StringBuf.as.AddAssignWith.impl.9c3 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.3486f7.2: %StringBuf.as.Destroy.impl.Op.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.Destroy.impl.Op]
// CHECK:STDOUT:   %Core.import_ref.054: %Destroy.WithSelf.SubobjectDestroy.type.3ac = import_ref Core//prelude/types/string, inst{{[0-9A-F]+}} [no loc], loaded [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.a17]
// CHECK:STDOUT:   %Core.import_ref.e4c: %Destroy.WithSelf.SelfDestruct.type.17f = import_ref Core//prelude/types/string, inst{{[0-9A-F]+}} [no loc], loaded [concrete = constants.%Destroy.WithSelf.SelfDestruct.65f]
// CHECK:STDOUT:   %Destroy.impl_witness_table = impl_witness_table (%Core.import_ref.3486f7.2, %Core.import_ref.054, %Core.import_ref.e4c), @StringBuf.as.Destroy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Append.decl: %Append.type = fn_decl @Append [concrete = constants.%Append] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.adf = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc5: Core.Form = init_form %i64 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %s.param: %str.3d4 = value_param call_param0
// CHECK:STDOUT:     %str.loc5: type = type_literal constants.%str.3d4 [concrete = constants.%str.3d4]
// CHECK:STDOUT:     %s: %str.3d4 = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Append(%s.param: %str.3d4) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.var: ref %StringBuf = var_storage %b.var_patt
// CHECK:STDOUT:   %Core.ref.loc6_27: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %StringBuf.ref.loc6_31: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:   %Make.ref: %StringBuf.Make.type = name_ref Make, imports.%Core.import_ref.49e [concrete = constants.%StringBuf.Make]
// CHECK:STDOUT:   %s.ref: %str.3d4 = name_ref s, %s
// CHECK:STDOUT:   %.loc6_3.1: ref %StringBuf = splice_block %b.var {}
// CHECK:STDOUT:   %StringBuf.Make.call: init %StringBuf to %.loc6_3.1 = call %Make.ref(%s.ref)
// CHECK:STDOUT:   assign %b.var, %StringBuf.Make.call
// CHECK:STDOUT:   %.loc6_14: type = splice_block %StringBuf.ref.loc6_14 [concrete = constants.%StringBuf] {
// CHECK:STDOUT:     %Core.ref.loc6_10: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %StringBuf.ref.loc6_14: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: ref %StringBuf = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.5d2 = ref_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.5d2 = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.ref.loc7: ref %StringBuf = name_ref b, %b
// CHECK:STDOUT:   %str.loc7: %ptr.b46 = string_literal "!" [concrete = constants.%str.57d]
// CHECK:STDOUT:   %int_1: %i64 = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %String.val: %str.3d4 = struct_value (%str.loc7, %int_1) [concrete = constants.%String.val]
// CHECK:STDOUT:   %impl.elem0.loc7: %.e13 = impl_witness_access constants.%AddAssignWith.impl_witness.312, element0 [concrete = constants.%StringBuf.as.AddAssignWith.impl.Op.cc70d5.1]
// CHECK:STDOUT:   %bound_method.loc7: <bound method> = bound_method %b.ref.loc7, %impl.elem0.loc7
// CHECK:STDOUT:   %StringBuf.as.AddAssignWith.impl.Op.call.loc7: init %empty_tuple.type = call %bound_method.loc7(%b.ref.loc7, %String.val)
// CHECK:STDOUT:   %b.ref.loc8_3: ref %StringBuf = name_ref b, %b
// CHECK:STDOUT:   %b.ref.loc8_8: ref %StringBuf = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0.loc8: %.ea1 = impl_witness_access constants.%AddAssignWith.impl_witness.97f, element0 [concrete = constants.%StringBuf.as.AddAssignWith.impl.Op.cc70d5.2]
// CHECK:STDOUT:   %bound_method.loc8: <bound method> = bound_method %b.ref.loc8_3, %impl.elem0.loc8
// CHECK:STDOUT:   %.loc8: %StringBuf = acquire_value %b.ref.loc8_8
// CHECK:STDOUT:   %StringBuf.as.AddAssignWith.impl.Op.call.loc8: init %empty_tuple.type = call %bound_method.loc8(%b.ref.loc8_3, %.loc8)
// CHECK:STDOUT:   %b.ref.loc9: ref %StringBuf = name_ref b, %b
// CHECK:STDOUT:   %Size.ref: %StringBuf.Size.type = name_ref Size, imports.%Core.import_ref.d0c [concrete = constants.%StringBuf.Size]
// CHECK:STDOUT:   %StringBuf.Size.bound: <bound method> = bound_method %b.ref.loc9, %Size.ref
// CHECK:STDOUT:   %.loc9: %StringBuf = acquire_value %b.ref.loc9
// CHECK:STDOUT:   %StringBuf.Size.call: init %i64 = call %StringBuf.Size.bound(%.loc9)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %b.var, constants.%Destroy.WithSelf.SelfDestruct.65f
// CHECK:STDOUT:   %Destroy.facet.loc6_3.1: %Destroy.type = facet_value constants.%StringBuf, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet]
// CHECK:STDOUT:   %.loc6_3.2: %Destroy.type = converted constants.%StringBuf, %Destroy.facet.loc6_3.1 [concrete = constants.%Destroy.facet]
// CHECK:STDOUT:   %Destroy.facet.loc6_3.2: %Destroy.type = facet_value constants.%StringBuf, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet]
// CHECK:STDOUT:   %.loc6_3.3: %Destroy.type = converted constants.%StringBuf, %Destroy.facet.loc6_3.2 [concrete = constants.%Destroy.facet]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %bound_method.loc6: <bound method> = bound_method %b.var, %Destroy.WithSelf.SelfDestruct.specific_fn
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method.loc6(%b.var)
// CHECK:STDOUT:   return %StringBuf.Size.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- view.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %StringBuf: type = class_type @StringBuf [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %ptr.b46: type = ptr_type %char [concrete]
// CHECK:STDOUT:   %struct_type.ptr.size: type = struct_type {.ptr: %ptr.b46, .size: %i64} [concrete]
// CHECK:STDOUT:   %pattern_type.5d2: type = pattern_type %StringBuf [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.5d2 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.5d2 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %str: type = class_type @String [concrete]
// CHECK:STDOUT:   %.8e1: Core.Form = init_form %str [concrete]
// CHECK:STDOUT:   %pattern_type.adf: type = pattern_type %str [concrete]
// CHECK:STDOUT:   %return.param_patt.59a: %pattern_type.adf = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.156: %pattern_type.adf = return_slot_pattern %return.param_patt.59a, %str [concrete]
// CHECK:STDOUT:   %View.type: type = fn_type @View [concrete]
// CHECK:STDOUT:   %View: %View.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.30b: type = facet_type <@ImplicitAs, @ImplicitAs(%str)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.77c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.717 [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.30b = facet_value %StringBuf, (%ImplicitAs.impl_witness.77c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.c4b: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%str, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b84: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.c4b, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %StringBuf.as.ImplicitAs.impl.Convert.type: type = fn_type @StringBuf.as.ImplicitAs.impl.Convert [concrete]
// CHECK:STDOUT:   %StringBuf.as.ImplicitAs.impl.Convert: %StringBuf.as.ImplicitAs.impl.Convert.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.adf = value_param_pattern [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %LetView.type: type = fn_type @LetView [concrete]
// CHECK:STDOUT:   %LetView: %LetView.type = struct_value () [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.5d2 = ref_binding_pattern c [concrete]
// CHECK:STDOUT:   %c.var_patt: %pattern_type.5d2 = var_pattern %c.patt [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.75d: type = facet_type <@AddWith, @AddWith(%str)> [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.073: <witness> = impl_witness imports.%AddWith.impl_witness_table.73b [concrete]
// CHECK:STDOUT:   %AddWith.facet.ac4: %AddWith.type.75d = facet_value %str, (%AddWith.impl_witness.073) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.dc2: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%str, %AddWith.facet.ac4) [concrete]
// CHECK:STDOUT:   %.7a2: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.dc2, %AddWith.facet.ac4 [concrete]
// CHECK:STDOUT:   %str.as.AddWith.impl.Op.type: type = fn_type @str.as.AddWith.impl.Op [concrete]
// CHECK:STDOUT:   %str.as.AddWith.impl.Op: %str.as.AddWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.adf = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %String.Size.type: type = fn_type @String.Size [concrete]
// CHECK:STDOUT:   %String.Size: %String.Size.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %pattern_type.854: type = pattern_type %ptr.b46 [concrete]
// CHECK:STDOUT:   %self.param_patt.b83: %pattern_type.854 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.f58: %pattern_type.854 = wrapper_binding_pattern self, %self.param_patt.b83 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_16.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc8_16.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_16.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.108: %pattern_type.f57 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f4: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt.108 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_16.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc8_16.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_16.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.8af: type = pattern_type %struct_type.ptr.size [concrete]
// CHECK:STDOUT:   %self.param_patt.9fd: %pattern_type.8af = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.95d: %pattern_type.8af = wrapper_binding_pattern self, %self.param_patt.9fd [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_16.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc8_16.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.dc5: %pattern_type.adf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.939: %pattern_type.adf = wrapper_binding_pattern self, %self.param_patt.dc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_16.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %String.elem.f15: type = unbound_element_type %str, %i64 [concrete]
// CHECK:STDOUT:   %String.elem.0b2: type = unbound_element_type %str, %ptr.b46 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc8_16.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_16.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.impl_witness: <witness> = impl_witness imports.%Destroy.impl_witness_table [concrete]
// CHECK:STDOUT:   %Destroy.facet.7b9: %Destroy.type = facet_value %StringBuf, (%Destroy.impl_witness) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.3ac: type = fn_type @Destroy.WithSelf.SubobjectDestroy.1, @Destroy.WithSelf(%Destroy.facet.7b9) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.a17: %Destroy.WithSelf.SubobjectDestroy.type.3ac = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.17f: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.7b9) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.65f: %Destroy.WithSelf.SelfDestruct.type.17f = struct_value () [concrete]
// CHECK:STDOUT:   %StringBuf.as.Destroy.impl.Op.type: type = fn_type @StringBuf.as.Destroy.impl.Op [concrete]
// CHECK:STDOUT:   %StringBuf.as.Destroy.impl.Op: %StringBuf.as.Destroy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .StringBuf = %Core.StringBuf
// CHECK:STDOUT:     .String = %Core.String
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StringBuf: type = import_ref Core//prelude/types/string, StringBuf, loaded [concrete = constants.%StringBuf]
// CHECK:STDOUT:   %Core.String: type = import_ref Core//prelude/types/string, String, loaded [concrete = constants.%str]
// CHECK:STDOUT:   %Core.import_ref.d0c: %String.Size.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%String.Size]
// CHECK:STDOUT:   %Core.import_ref.c9c: %String.elem.0b2 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = %field_decl.b1e]
// CHECK:STDOUT:   %Core.import_ref.704: %String.elem.f15 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = %field_decl.e70]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.06c: %StringBuf.as.ImplicitAs.impl.Convert.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.ImplicitAs.impl.Convert]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.717 = impl_witness_table (%Core.import_ref.06c), @StringBuf.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.194 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %str.as.AddWith.impl.Op.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%str.as.AddWith.impl.Op]
// CHECK:STDOUT:   %AddWith.impl_witness_table.73b = impl_witness_table (%Core.import_ref.194, %Core.import_ref.9c3), @str.as.AddWith.impl.c80 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.9cc = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %field_decl.e70: %String.elem.f15 = field_decl size, element1, %Core.import_ref.9cc in [concrete] {}
// CHECK:STDOUT:   %Core.import_ref.be6 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %field_decl.b1e: %String.elem.0b2 = field_decl ptr, element0, %Core.import_ref.be6 in [concrete] {}
// CHECK:STDOUT:   %Core.import_ref.3486: %StringBuf.as.Destroy.impl.Op.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.as.Destroy.impl.Op]
// CHECK:STDOUT:   %Core.import_ref.054: %Destroy.WithSelf.SubobjectDestroy.type.3ac = import_ref Core//prelude/types/string, inst{{[0-9A-F]+}} [no loc], loaded [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.a17]
// CHECK:STDOUT:   %Core.import_ref.e4c: %Destroy.WithSelf.SelfDestruct.type.17f = import_ref Core//prelude/types/string, inst{{[0-9A-F]+}} [no loc], loaded [concrete = constants.%Destroy.WithSelf.SelfDestruct.65f]
// CHECK:STDOUT:   %Destroy.impl_witness_table = impl_witness_table (%Core.import_ref.3486, %Core.import_ref.054, %Core.import_ref.e4c), @StringBuf.as.Destroy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_16.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.854 = ref_param_pattern [concrete = constants.%self.param_patt.b83]
// CHECK:STDOUT:     %self.patt: %pattern_type.854 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.f58]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ptr.b46 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ptr.b46 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc8_16.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.854 = ref_param_pattern [concrete = constants.%self.param_patt.b83]
// CHECK:STDOUT:     %self.patt: %pattern_type.854 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.f58]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ptr.b46 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ptr.b46 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_16.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc8_16.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_16.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.8af = ref_param_pattern [concrete = constants.%self.param_patt.9fd]
// CHECK:STDOUT:     %self.patt: %pattern_type.8af = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.95d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.ptr.size = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.ptr.size = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc8_16.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.8af = ref_param_pattern [concrete = constants.%self.param_patt.9fd]
// CHECK:STDOUT:     %self.patt: %pattern_type.8af = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.95d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.ptr.size = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.ptr.size = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_16.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.adf = ref_param_pattern [concrete = constants.%self.param_patt.dc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.adf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.939]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %str = ref_param call_param0
// CHECK:STDOUT:     %self: ref %str = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc8_16.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.adf = ref_param_pattern [concrete = constants.%self.param_patt.dc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.adf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.939]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %str = ref_param call_param0
// CHECK:STDOUT:     %self: ref %str = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %View.decl: %View.type = fn_decl @View [concrete = constants.%View] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.5d2 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.5d2 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.adf = out_param_pattern [concrete = constants.%return.param_patt.59a]
// CHECK:STDOUT:     %return.patt: %pattern_type.adf = return_slot_pattern %return.param_patt, %str [concrete = constants.%return.patt.156]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %str: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %.loc5_31.2: Core.Form = init_form %str [concrete = constants.%.8e1]
// CHECK:STDOUT:     %b.param: %StringBuf = value_param call_param0
// CHECK:STDOUT:     %.loc5_16: type = splice_block %StringBuf.ref [concrete = constants.%StringBuf] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %StringBuf.ref: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %StringBuf = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %str = out_param call_param1
// CHECK:STDOUT:     %return: ref %str = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %LetView.decl: %LetView.type = fn_decl @LetView [concrete = constants.%LetView] {
// CHECK:STDOUT:     %a.param_patt: %pattern_type.adf = value_param_pattern [concrete = constants.%a.param_patt]
// CHECK:STDOUT:     %a.patt: %pattern_type.adf = wrapper_binding_pattern a, %a.param_patt [concrete = constants.%a.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc6: Core.Form = init_form %i64 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %a.param: %str = value_param call_param0
// CHECK:STDOUT:     %str.loc6: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:     %a: %str = wrapper_binding a, %a.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @View(%b.param: %StringBuf) -> out %return.param: %str {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: %StringBuf = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0: %.b84 = impl_witness_access constants.%ImplicitAs.impl_witness.77c, element0 [concrete = constants.%StringBuf.as.ImplicitAs.impl.Convert]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %b.ref, %impl.elem0
// CHECK:STDOUT:   %.loc5_31.1: ref %str = splice_block %return.param {}
// CHECK:STDOUT:   %StringBuf.as.ImplicitAs.impl.Convert.call: init %str to %.loc5_31.1 = call %bound_method(%b.ref)
// CHECK:STDOUT:   %.loc5_45: init %str = converted %b.ref, %StringBuf.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   return %.loc5_45 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @LetView(%a.param: %str) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.var: ref %StringBuf = var_storage %c.var_patt
// CHECK:STDOUT:   %a.ref.loc7_27: %str = name_ref a, %a
// CHECK:STDOUT:   %a.ref.loc7_31: %str = name_ref a, %a
// CHECK:STDOUT:   %impl.elem1: %.7a2 = impl_witness_access constants.%AddWith.impl_witness.073, element1 [concrete = constants.%str.as.AddWith.impl.Op]
// CHECK:STDOUT:   %bound_method.loc7_29: <bound method> = bound_method %a.ref.loc7_27, %impl.elem1
// CHECK:STDOUT:   %.loc7_3.1: ref %StringBuf = splice_block %c.var {}
// CHECK:STDOUT:   %str.as.AddWith.impl.Op.call: init %StringBuf to %.loc7_3.1 = call %bound_method.loc7_29(%a.ref.loc7_27, %a.ref.loc7_31)
// CHECK:STDOUT:   assign %c.var, %str.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %.loc7_14: type = splice_block %StringBuf.ref [concrete = constants.%StringBuf] {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %StringBuf.ref: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %c: ref %StringBuf = wrapper_binding c, %c.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %c.patt: %pattern_type.5d2 = ref_binding_pattern c [concrete = constants.%c.patt]
// CHECK:STDOUT:     %c.var_patt: %pattern_type.5d2 = var_pattern %c.patt [concrete = constants.%c.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %c.ref: ref %StringBuf = name_ref c, %c
// CHECK:STDOUT:   %impl.elem0: %.b84 = impl_witness_access constants.%ImplicitAs.impl_witness.77c, element0 [concrete = constants.%StringBuf.as.ImplicitAs.impl.Convert]
// CHECK:STDOUT:   %bound_method.loc8: <bound method> = bound_method %c.ref, %impl.elem0
// CHECK:STDOUT:   %.loc8_16.1: ref %str = temporary_storage
// CHECK:STDOUT:   %.loc8_16.2: %StringBuf = acquire_value %c.ref
// CHECK:STDOUT:   %StringBuf.as.ImplicitAs.impl.Convert.call: init %str to %.loc8_16.1 = call %bound_method.loc8(%.loc8_16.2)
// CHECK:STDOUT:   %.loc8_16.3: init %str = converted %c.ref, %StringBuf.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc8_16.4: ref %str = temporary %.loc8_16.1, %.loc8_16.3
// CHECK:STDOUT:   %.loc8_16.5: %str = acquire_value %.loc8_16.4
// CHECK:STDOUT:   %str.loc8: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:   %v: %str = wrapper_binding v, %.loc8_16.5
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.adf = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %v.ref: %str = name_ref v, %v
// CHECK:STDOUT:   %Size.ref: %String.Size.type = name_ref Size, imports.%Core.import_ref.d0c [concrete = constants.%String.Size]
// CHECK:STDOUT:   %String.Size.bound: <bound method> = bound_method %v.ref, %Size.ref
// CHECK:STDOUT:   %String.Size.call: init %i64 = call %String.Size.bound(%v.ref)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8: <bound method> = bound_method %.loc8_16.4, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8(%.loc8_16.4)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc7: <bound method> = bound_method %c.var, constants.%Destroy.WithSelf.SelfDestruct.65f
// CHECK:STDOUT:   %Destroy.facet.loc7_3.1: %Destroy.type = facet_value constants.%StringBuf, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet.7b9]
// CHECK:STDOUT:   %.loc7_3.2: %Destroy.type = converted constants.%StringBuf, %Destroy.facet.loc7_3.1 [concrete = constants.%Destroy.facet.7b9]
// CHECK:STDOUT:   %Destroy.facet.loc7_3.2: %Destroy.type = facet_value constants.%StringBuf, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet.7b9]
// CHECK:STDOUT:   %.loc7_3.3: %Destroy.type = converted constants.%StringBuf, %Destroy.facet.loc7_3.2 [concrete = constants.%Destroy.facet.7b9]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %bound_method.loc7_3: <bound method> = bound_method %c.var, %Destroy.WithSelf.SelfDestruct.specific_fn
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc7: init %empty_tuple.type = call %bound_method.loc7_3(%c.var)
// CHECK:STDOUT:   return %String.Size.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_16.1(%self.param: ref %ptr.b46) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_16.1(%self.param: ref %ptr.b46) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_16.1(%self.param: ref %ptr.b46) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_16.2(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_16.2(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_16.2(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_16.3(%self.param: ref %struct_type.ptr.size) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc8_16.1: ref %i64 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_16.1: <bound method> = bound_method %.loc8_16.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_16.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_16.1(%.loc8_16.1)
// CHECK:STDOUT:   %.loc8_16.2: ref %ptr.b46 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_16.2: <bound method> = bound_method %.loc8_16.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_16.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_16.2(%.loc8_16.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_16.3(%self.param: ref %struct_type.ptr.size) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_16.3(%self.param: ref %struct_type.ptr.size) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_16.4(%self.param: ref %str) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %size.ref: %String.elem.f15 = name_ref size, imports.%Core.import_ref.704 [concrete = imports.%field_decl.e70]
// CHECK:STDOUT:   %.loc8_16.1: ref %i64 = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_16.1: <bound method> = bound_method %.loc8_16.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_16.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_16.1(%.loc8_16.1)
// CHECK:STDOUT:   %ptr.ref: %String.elem.0b2 = name_ref ptr, imports.%Core.import_ref.c9c [concrete = imports.%field_decl.b1e]
// CHECK:STDOUT:   %.loc8_16.2: ref %ptr.b46 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_16.2: <bound method> = bound_method %.loc8_16.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_16.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_16.2(%.loc8_16.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_16.4(%self.param: ref %str) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_16.4(%self.param: ref %str) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
