// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/class/adapter/destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/class/adapter/destroy.carbon

// Fork (OP-2, fork/optional2/plan.md §4): an adapter declares no fields, and
// its object is an object of the adapted type (docs/design/classes.md,
// "Adapters"), so destroying an adapter destroys it as the adapted type (fork
// design F-016): the adapter's `SubobjectDestroy` calls the adapted type's
// `SelfDestruct` when that type has destruction work, and is the no-op builtin
// when it has none.

// --- destructible.carbon

library "[[@TEST_NAME]]";

class P {
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

class AdaptP {
  adapt P;
}

class AdaptAdaptP {
  adapt AdaptP;
}

fn MakeP() -> P;

//@dump-sem-ir-begin
fn F() {
  var unused a: AdaptP = MakeP() as AdaptP;
  var unused b: AdaptAdaptP = MakeP() as AdaptAdaptP;
}
//@dump-sem-ir-end

// --- trivial.carbon

library "[[@TEST_NAME]]";

class AdaptI32 {
  adapt i32;
}

fn MakeAdaptI32() -> AdaptI32;

//@dump-sem-ir-begin
fn G() {
  var unused c: AdaptI32 = MakeAdaptI32();
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- destructible.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %P: type = class_type @P [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.impl_witness: <witness> = impl_witness @P.as.Destroy.impl.%Destroy.impl_witness_table [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Destroy.facet.7aa: %Destroy.type = facet_value %P, (%Destroy.impl_witness) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.8cf: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.7aa) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.73c: %Destroy.WithSelf.SelfDestruct.type.8cf = struct_value () [concrete]
// CHECK:STDOUT:   %AdaptP: type = class_type @AdaptP [concrete]
// CHECK:STDOUT:   %AdaptAdaptP: type = class_type @AdaptAdaptP [concrete]
// CHECK:STDOUT:   %MakeP.type: type = fn_type @MakeP [concrete]
// CHECK:STDOUT:   %MakeP: %MakeP.type = struct_value () [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.c89: type = pattern_type %AdaptP [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.c89 = ref_binding_pattern a [concrete]
// CHECK:STDOUT:   %a.var_patt: %pattern_type.c89 = var_pattern %a.patt [concrete]
// CHECK:STDOUT:   %pattern_type.bc6: type = pattern_type %AdaptAdaptP [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.bc6 = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.bc6 = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   %self.param_patt.ee5: %pattern_type.c89 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.c5e: %pattern_type.c89 = wrapper_binding_pattern self, %self.param_patt.ee5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc23_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc23_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc23_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.220: %pattern_type.bc6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.225: %pattern_type.bc6 = wrapper_binding_pattern self, %self.param_patt.220 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc23_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc23_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc23_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc23_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.c89 = ref_param_pattern [concrete = constants.%self.param_patt.ee5]
// CHECK:STDOUT:     %self.patt: %pattern_type.c89 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c5e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %AdaptP = ref_param call_param0
// CHECK:STDOUT:     %self: ref %AdaptP = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc23_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.c89 = ref_param_pattern [concrete = constants.%self.param_patt.ee5]
// CHECK:STDOUT:     %self.patt: %pattern_type.c89 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c5e]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %AdaptP = ref_param call_param0
// CHECK:STDOUT:     %self: ref %AdaptP = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc23_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.bc6 = ref_param_pattern [concrete = constants.%self.param_patt.220]
// CHECK:STDOUT:     %self.patt: %pattern_type.bc6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.225]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %AdaptAdaptP = ref_param call_param0
// CHECK:STDOUT:     %self: ref %AdaptAdaptP = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc23_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.bc6 = ref_param_pattern [concrete = constants.%self.param_patt.220]
// CHECK:STDOUT:     %self.patt: %pattern_type.bc6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.225]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %AdaptAdaptP = ref_param call_param0
// CHECK:STDOUT:     %self: ref %AdaptAdaptP = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.var: ref %AdaptP = var_storage %a.var_patt
// CHECK:STDOUT:   %MakeP.ref.loc22: %MakeP.type = name_ref MakeP, file.%MakeP.decl [concrete = constants.%MakeP]
// CHECK:STDOUT:   %.loc22_3: ref %AdaptP = splice_block %a.var {}
// CHECK:STDOUT:   %MakeP.call.loc22: init %P to %.loc22_3 = call %MakeP.ref.loc22()
// CHECK:STDOUT:   %AdaptP.ref.loc22_37: type = name_ref AdaptP, file.%AdaptP.decl [concrete = constants.%AdaptP]
// CHECK:STDOUT:   %.loc22_34.1: init %AdaptP = as_compatible %MakeP.call.loc22
// CHECK:STDOUT:   %.loc22_34.2: init %AdaptP = converted %MakeP.call.loc22, %.loc22_34.1
// CHECK:STDOUT:   assign %a.var, %.loc22_34.2
// CHECK:STDOUT:   %AdaptP.ref.loc22_17: type = name_ref AdaptP, file.%AdaptP.decl [concrete = constants.%AdaptP]
// CHECK:STDOUT:   %a: ref %AdaptP = wrapper_binding a, %a.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.c89 = ref_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:     %a.var_patt: %pattern_type.c89 = var_pattern %a.patt [concrete = constants.%a.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.var: ref %AdaptAdaptP = var_storage %b.var_patt
// CHECK:STDOUT:   %MakeP.ref.loc23: %MakeP.type = name_ref MakeP, file.%MakeP.decl [concrete = constants.%MakeP]
// CHECK:STDOUT:   %.loc23_3: ref %AdaptAdaptP = splice_block %b.var {}
// CHECK:STDOUT:   %MakeP.call.loc23: init %P to %.loc23_3 = call %MakeP.ref.loc23()
// CHECK:STDOUT:   %AdaptAdaptP.ref.loc23_42: type = name_ref AdaptAdaptP, file.%AdaptAdaptP.decl [concrete = constants.%AdaptAdaptP]
// CHECK:STDOUT:   %.loc23_39.1: init %AdaptAdaptP = as_compatible %MakeP.call.loc23
// CHECK:STDOUT:   %.loc23_39.2: init %AdaptAdaptP = converted %MakeP.call.loc23, %.loc23_39.1
// CHECK:STDOUT:   assign %b.var, %.loc23_39.2
// CHECK:STDOUT:   %AdaptAdaptP.ref.loc23_17: type = name_ref AdaptAdaptP, file.%AdaptAdaptP.decl [concrete = constants.%AdaptAdaptP]
// CHECK:STDOUT:   %b: ref %AdaptAdaptP = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.bc6 = ref_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.bc6 = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc23: <bound method> = bound_method %b.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc23: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc23(%b.var)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc22: <bound method> = bound_method %a.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc22: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc22(%a.var)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc23_3.1(%self.param: ref %AdaptP) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc23_3.1: ref %P = as_compatible %self.param
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc23_3.1, constants.%Destroy.WithSelf.SelfDestruct.73c
// CHECK:STDOUT:   %Destroy.facet.loc23_3.1: %Destroy.type = facet_value constants.%P, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet.7aa]
// CHECK:STDOUT:   %.loc23_3.2: %Destroy.type = converted constants.%P, %Destroy.facet.loc23_3.1 [concrete = constants.%Destroy.facet.7aa]
// CHECK:STDOUT:   %Destroy.facet.loc23_3.2: %Destroy.type = facet_value constants.%P, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet.7aa]
// CHECK:STDOUT:   %.loc23_3.3: %Destroy.type = converted constants.%P, %Destroy.facet.loc23_3.2 [concrete = constants.%Destroy.facet.7aa]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %.loc23_3.1, %Destroy.WithSelf.SelfDestruct.specific_fn
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method(%.loc23_3.1)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc23_3.1(%self.param: ref %AdaptP) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc23_3.1(%self.param: ref %AdaptP) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc23_3.2(%self.param: ref %AdaptAdaptP) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc23: ref %AdaptP = as_compatible %self.param
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc23, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc23)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc23_3.2(%self.param: ref %AdaptAdaptP) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc23_3.2(%self.param: ref %AdaptAdaptP) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- trivial.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %AdaptI32: type = class_type @AdaptI32 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.009: type = pattern_type %AdaptI32 [concrete]
// CHECK:STDOUT:   %MakeAdaptI32.type: type = fn_type @MakeAdaptI32 [concrete]
// CHECK:STDOUT:   %MakeAdaptI32: %MakeAdaptI32.type = struct_value () [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.009 = ref_binding_pattern c [concrete]
// CHECK:STDOUT:   %c.var_patt: %pattern_type.009 = var_pattern %c.patt [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc12_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.ddf: %pattern_type.009 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.415: %pattern_type.009 = wrapper_binding_pattern self, %self.param_patt.ddf [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc12_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc12_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.009 = ref_param_pattern [concrete = constants.%self.param_patt.ddf]
// CHECK:STDOUT:     %self.patt: %pattern_type.009 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.415]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %AdaptI32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %AdaptI32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc12_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.009 = ref_param_pattern [concrete = constants.%self.param_patt.ddf]
// CHECK:STDOUT:     %self.patt: %pattern_type.009 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.415]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %AdaptI32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %AdaptI32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.var: ref %AdaptI32 = var_storage %c.var_patt
// CHECK:STDOUT:   %MakeAdaptI32.ref: %MakeAdaptI32.type = name_ref MakeAdaptI32, file.%MakeAdaptI32.decl [concrete = constants.%MakeAdaptI32]
// CHECK:STDOUT:   %MakeAdaptI32.call: init %AdaptI32 = call %MakeAdaptI32.ref()
// CHECK:STDOUT:   assign %c.var, %MakeAdaptI32.call
// CHECK:STDOUT:   %AdaptI32.ref: type = name_ref AdaptI32, file.%AdaptI32.decl [concrete = constants.%AdaptI32]
// CHECK:STDOUT:   %c: ref %AdaptI32 = wrapper_binding c, %c.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %c.patt: %pattern_type.009 = ref_binding_pattern c [concrete = constants.%c.patt]
// CHECK:STDOUT:     %c.var_patt: %pattern_type.009 = var_pattern %c.patt [concrete = constants.%c.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %c.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%c.var)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_3.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.2(%self.param: ref %AdaptI32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_3.2(%self.param: ref %AdaptI32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_3.2(%self.param: ref %AdaptI32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
