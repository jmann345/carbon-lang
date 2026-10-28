// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/as/maybe_unformed_value_repr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/as/maybe_unformed_value_repr.carbon

// Fork (OP-2, fork/optional2/plan.md §4, W-171): removing `MaybeUnformed` from
// a value whose value representation differs from the result's goes through a
// reference (`value_as_ref`, then `acquire_value`); `MaybeUnformed(bool)` is
// passed by pointer and `bool` by copy. Where the two representations agree,
// or are unknown until a specific is lowered, the conversion is an
// `as_compatible` alone, and lowering converts the representation per specific
// (lower/testdata/builtins/maybe_unformed_value_repr.carbon).

// --- bool.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn FromBool(m: Core.MaybeUnformed(bool)) -> bool { return m unsafe as bool; }
//@dump-sem-ir-end

// --- i32.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn FromI32(m: Core.MaybeUnformed(i32)) -> i32 { return m unsafe as i32; }
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Unwrap[T: Core.Copy & Core.Destroy](m: Core.MaybeUnformed(T)) -> T {
  return m unsafe as T;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- bool.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %MaybeUnformed.type: type = generic_class_type @MaybeUnformed [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %MaybeUnformed.generic: %MaybeUnformed.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %self.param_patt.40d: %pattern_type.831 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.560: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt.40d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f: <witness> = custom_witness (%Destroy.WithSelf.Op.403, %Destroy.WithSelf.SubobjectDestroy.d01, %Destroy.WithSelf.SelfDestruct.db3), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.75f: %Destroy.type = facet_value bool, (%custom_witness.f8f) [concrete]
// CHECK:STDOUT:   %MaybeUnformed.5b2: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.75f) [concrete]
// CHECK:STDOUT:   %pattern_type.42a: type = pattern_type %MaybeUnformed.5b2 [concrete]
// CHECK:STDOUT:   %m.param_patt: %pattern_type.42a = value_param_pattern [concrete]
// CHECK:STDOUT:   %m.patt: %pattern_type.42a = wrapper_binding_pattern m, %m.param_patt [concrete]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %FromBool.type: type = fn_type @FromBool [concrete]
// CHECK:STDOUT:   %FromBool: %FromBool.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value bool, (%Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d02: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.e28: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d02, %Copy.facet [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.type: type = fn_type @bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op: %bool.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .MaybeUnformed = %Core.MaybeUnformed
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.MaybeUnformed: %MaybeUnformed.type = import_ref Core//prelude/types/maybe_unformed, MaybeUnformed, loaded [concrete = constants.%MaybeUnformed.generic]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.9c3: %bool.as.Copy.impl.Op.type = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.9c3), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc5 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %FromBool.decl: %FromBool.type = fn_decl @FromBool [concrete = constants.%FromBool] {
// CHECK:STDOUT:     %m.param_patt: %pattern_type.42a = value_param_pattern [concrete = constants.%m.param_patt]
// CHECK:STDOUT:     %m.patt: %pattern_type.42a = wrapper_binding_pattern m, %m.param_patt [concrete = constants.%m.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc5_45.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc5_45.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc5_45.2: Core.Form = init_form %.loc5_45.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %m.param: %MaybeUnformed.5b2 = value_param call_param0
// CHECK:STDOUT:     %.loc5_39.1: type = splice_block %MaybeUnformed [concrete = constants.%MaybeUnformed.5b2] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %MaybeUnformed.ref: %MaybeUnformed.type = name_ref MaybeUnformed, imports.%Core.MaybeUnformed [concrete = constants.%MaybeUnformed.generic]
// CHECK:STDOUT:       %.loc5_35: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:       %Destroy.facet: %Destroy.type = facet_value %.loc5_35, (constants.%custom_witness.f8f) [concrete = constants.%Destroy.facet.75f]
// CHECK:STDOUT:       %.loc5_39.2: %Destroy.type = converted %.loc5_35, %Destroy.facet [concrete = constants.%Destroy.facet.75f]
// CHECK:STDOUT:       %MaybeUnformed: type = class_type @MaybeUnformed, @MaybeUnformed(constants.%Destroy.facet.75f) [concrete = constants.%MaybeUnformed.5b2]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %m: %MaybeUnformed.5b2 = wrapper_binding m, %m.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param1
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc5(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc5(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc5(%self.param: ref bool) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @FromBool(%m.param: %MaybeUnformed.5b2) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %m.ref: %MaybeUnformed.5b2 = name_ref m, %m
// CHECK:STDOUT:   %.loc5_71: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:   %.loc5_68.1: ref %MaybeUnformed.5b2 = value_as_ref %m.ref
// CHECK:STDOUT:   %.loc5_68.2: ref bool = as_compatible %.loc5_68.1
// CHECK:STDOUT:   %.loc5_68.3: bool = acquire_value %.loc5_68.2
// CHECK:STDOUT:   %.loc5_68.4: bool = converted %m.ref, %.loc5_68.3
// CHECK:STDOUT:   %impl.elem0: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %.loc5_68.4, %impl.elem0
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call: init bool = call %bound_method(%.loc5_68.4)
// CHECK:STDOUT:   return %bool.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- i32.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %MaybeUnformed.type: type = generic_class_type @MaybeUnformed [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %MaybeUnformed.generic: %MaybeUnformed.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
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
// CHECK:STDOUT:   %MaybeUnformed.515: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.b41) [concrete]
// CHECK:STDOUT:   %pattern_type.7cb: type = pattern_type %MaybeUnformed.515 [concrete]
// CHECK:STDOUT:   %m.param_patt: %pattern_type.7cb = value_param_pattern [concrete]
// CHECK:STDOUT:   %m.patt: %pattern_type.7cb = wrapper_binding_pattern m, %m.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %FromI32.type: type = fn_type @FromI32 [concrete]
// CHECK:STDOUT:   %FromI32: %FromI32.type = struct_value () [concrete]
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
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .MaybeUnformed = %Core.MaybeUnformed
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.MaybeUnformed: %MaybeUnformed.type = import_ref Core//prelude/types/maybe_unformed, MaybeUnformed, loaded [concrete = constants.%MaybeUnformed.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
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
// CHECK:STDOUT:   %FromI32.decl: %FromI32.type = fn_decl @FromI32 [concrete = constants.%FromI32] {
// CHECK:STDOUT:     %m.param_patt: %pattern_type.7cb = value_param_pattern [concrete = constants.%m.param_patt]
// CHECK:STDOUT:     %m.patt: %pattern_type.7cb = wrapper_binding_pattern m, %m.param_patt [concrete = constants.%m.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc5_43 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc5_43: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc5_43: Core.Form = init_form %i32.loc5_43 [concrete = constants.%.795]
// CHECK:STDOUT:     %m.param: %MaybeUnformed.515 = value_param call_param0
// CHECK:STDOUT:     %.loc5_37.1: type = splice_block %MaybeUnformed [concrete = constants.%MaybeUnformed.515] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %MaybeUnformed.ref: %MaybeUnformed.type = name_ref MaybeUnformed, imports.%Core.MaybeUnformed [concrete = constants.%MaybeUnformed.generic]
// CHECK:STDOUT:       %i32.loc5_34: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %Destroy.facet: %Destroy.type = facet_value %i32.loc5_34, (constants.%custom_witness.f8f) [concrete = constants.%Destroy.facet.b41]
// CHECK:STDOUT:       %.loc5_37.2: %Destroy.type = converted %i32.loc5_34, %Destroy.facet [concrete = constants.%Destroy.facet.b41]
// CHECK:STDOUT:       %MaybeUnformed: type = class_type @MaybeUnformed, @MaybeUnformed(constants.%Destroy.facet.b41) [concrete = constants.%MaybeUnformed.515]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %m: %MaybeUnformed.515 = wrapper_binding m, %m.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
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
// CHECK:STDOUT: fn @FromI32(%m.param: %MaybeUnformed.515) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %m.ref: %MaybeUnformed.515 = name_ref m, %m
// CHECK:STDOUT:   %i32.loc5_68: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %.loc5_65.1: %i32 = as_compatible %m.ref
// CHECK:STDOUT:   %.loc5_65.2: %i32 = converted %m.ref, %.loc5_65.1
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc5_65.1: <bound method> = bound_method %.loc5_65.2, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_65.2: <bound method> = bound_method %.loc5_65.2, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc5_65.2(%.loc5_65.2)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %BitAndWith.generic: %BitAndWith.type.a06 = struct_value () [concrete]
// CHECK:STDOUT:   %BitAndWith.type.411: type = facet_type <@BitAndWith, @BitAndWith(type)> [concrete]
// CHECK:STDOUT:   %BitAndWith.impl_witness: <witness> = impl_witness imports.%BitAndWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %BitAndWith.facet: %BitAndWith.type.411 = facet_value type, (%BitAndWith.impl_witness) [concrete]
// CHECK:STDOUT:   %BitAndWith.WithSelf.Op.type.0cf: type = fn_type @BitAndWith.WithSelf.Op, @BitAndWith.WithSelf(type, %BitAndWith.facet) [concrete]
// CHECK:STDOUT:   %.85c: type = fn_type_with_self_type %BitAndWith.WithSelf.Op.type.0cf, %BitAndWith.facet [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.type: type = fn_type @type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op: %type.as.BitAndWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.bound: <bound method> = bound_method %Copy.type, %type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %pattern_type.143: type = pattern_type %facet_type [concrete]
// CHECK:STDOUT:   %T.patt.256: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.dc4: %facet_type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.type: type = generic_class_type @MaybeUnformed [concrete]
// CHECK:STDOUT:   %MaybeUnformed.generic: %MaybeUnformed.type = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.5d6: type = facet_access_type %T.dc4 [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.491: <witness> = lookup_impl_witness %T.dc4, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet: %Destroy.type = facet_value %T.as_type.5d6, (%Destroy.lookup_impl_witness.491) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.d0b: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %pattern_type.f04: type = pattern_type %MaybeUnformed.d0b [symbolic]
// CHECK:STDOUT:   %m.param_patt: %pattern_type.f04 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %m.patt: %pattern_type.f04 = wrapper_binding_pattern m, %m.param_patt [symbolic]
// CHECK:STDOUT:   %.273: Core.Form = init_form %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %pattern_type.0e9: type = pattern_type %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %return.param_patt.7e1: %pattern_type.0e9 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.dca: %pattern_type.0e9 = return_slot_pattern %return.param_patt.7e1, %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %Unwrap.type: type = fn_type @Unwrap [concrete]
// CHECK:STDOUT:   %Unwrap: %Unwrap.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.eb0: <witness> = require_complete_type %MaybeUnformed.d0b [symbolic]
// CHECK:STDOUT:   %require_complete.091: <witness> = require_complete_type %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.fd8: <witness> = lookup_impl_witness %T.dc4, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %T.as_type.5d6, (%Copy.lookup_impl_witness.fd8) [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.39e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [symbolic]
// CHECK:STDOUT:   %.843: type = fn_type_with_self_type %Copy.WithSelf.Op.type.39e, %Copy.facet [symbolic]
// CHECK:STDOUT:   %impl.elem0.f20: %.843 = impl_witness_access %Copy.lookup_impl_witness.fd8, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.6a5: <specific function> = specific_impl_function %impl.elem0.f20, @Copy.WithSelf.Op(%Copy.facet) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     .MaybeUnformed = %Core.MaybeUnformed
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT:   %Core.MaybeUnformed: %MaybeUnformed.type = import_ref Core//prelude/types/maybe_unformed, MaybeUnformed, loaded [concrete = constants.%MaybeUnformed.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Unwrap.decl: %Unwrap.type = fn_decl @Unwrap [concrete = constants.%Unwrap] {
// CHECK:STDOUT:     %T.patt.loc5_12.1: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_12.2 (constants.%T.patt.256)]
// CHECK:STDOUT:     %m.param_patt.loc5_41.1: @Unwrap.%pattern_type.loc5_41 (%pattern_type.f04) = value_param_pattern [symbolic = %m.param_patt.loc5_41.2 (constants.%m.param_patt)]
// CHECK:STDOUT:     %m.patt.loc5_41.1: @Unwrap.%pattern_type.loc5_41 (%pattern_type.f04) = wrapper_binding_pattern m, %m.param_patt.loc5_41.1 [symbolic = %m.patt.loc5_41.2 (constants.%m.patt)]
// CHECK:STDOUT:     %return.param_patt.loc5_69.1: @Unwrap.%pattern_type.loc5_69 (%pattern_type.0e9) = out_param_pattern [symbolic = %return.param_patt.loc5_69.2 (constants.%return.param_patt.7e1)]
// CHECK:STDOUT:     %return.patt.loc5_66.1: @Unwrap.%pattern_type.loc5_69 (%pattern_type.0e9) = return_slot_pattern %return.param_patt.loc5_69.1, %.loc5_69.3 [symbolic = %return.patt.loc5_66.2 (constants.%return.patt.dca)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc5_69: %facet_type = name_ref T, %T.loc5_12.2 [symbolic = %T.loc5_12.1 (constants.%T.dc4)]
// CHECK:STDOUT:     %T.as_type.loc5_69: type = facet_access_type %T.ref.loc5_69 [symbolic = %T.as_type.loc5_63.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:     %.loc5_69.3: type = converted %T.ref.loc5_69, %T.as_type.loc5_69 [symbolic = %T.as_type.loc5_63.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:     %.loc5_69.4: Core.Form = init_form %.loc5_69.3 [symbolic = %.loc5_69.2 (constants.%.273)]
// CHECK:STDOUT:     %.loc5_24.1: type = splice_block %.loc5_24.3 [concrete = constants.%facet_type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc5_14: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc5_26: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc5: <bound method> = bound_method %Copy.ref, %impl.elem1 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method.loc5(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc5_24.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc5_24.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc5_24.2 [concrete = constants.%facet_type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc5_12.2: %facet_type = symbolic_binding T, 0 [symbolic = %T.loc5_12.1 (constants.%T.dc4)]
// CHECK:STDOUT:     %m.param: @Unwrap.%MaybeUnformed.loc5_63.1 (%MaybeUnformed.d0b) = value_param call_param0
// CHECK:STDOUT:     %.loc5_63.1: type = splice_block %MaybeUnformed.loc5_63.2 [symbolic = %MaybeUnformed.loc5_63.1 (constants.%MaybeUnformed.d0b)] {
// CHECK:STDOUT:       %Core.ref.loc5_43: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %MaybeUnformed.ref: %MaybeUnformed.type = name_ref MaybeUnformed, imports.%Core.MaybeUnformed [concrete = constants.%MaybeUnformed.generic]
// CHECK:STDOUT:       %T.ref.loc5_62: %facet_type = name_ref T, %T.loc5_12.2 [symbolic = %T.loc5_12.1 (constants.%T.dc4)]
// CHECK:STDOUT:       %T.as_type.loc5_63.2: type = facet_access_type %T.ref.loc5_62 [symbolic = %T.as_type.loc5_63.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:       %Destroy.facet.loc5_63.2: %Destroy.type = facet_value %T.as_type.loc5_63.2, (constants.%Destroy.lookup_impl_witness.491) [symbolic = %Destroy.facet.loc5_63.1 (constants.%Destroy.facet)]
// CHECK:STDOUT:       %.loc5_63.2: %Destroy.type = converted %T.ref.loc5_62, %Destroy.facet.loc5_63.2 [symbolic = %Destroy.facet.loc5_63.1 (constants.%Destroy.facet)]
// CHECK:STDOUT:       %MaybeUnformed.loc5_63.2: type = class_type @MaybeUnformed, @MaybeUnformed(constants.%Destroy.facet) [symbolic = %MaybeUnformed.loc5_63.1 (constants.%MaybeUnformed.d0b)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %m: @Unwrap.%MaybeUnformed.loc5_63.1 (%MaybeUnformed.d0b) = wrapper_binding m, %m.param
// CHECK:STDOUT:     %return.param: ref @Unwrap.%T.as_type.loc5_63.1 (%T.as_type.5d6) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Unwrap.%T.as_type.loc5_63.1 (%T.as_type.5d6) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Unwrap(%T.loc5_12.2: %facet_type) {
// CHECK:STDOUT:   %T.patt.loc5_12.2: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_12.2 (constants.%T.patt.256)]
// CHECK:STDOUT:   %T.loc5_12.1: %facet_type = symbolic_binding T, 0 [symbolic = %T.loc5_12.1 (constants.%T.dc4)]
// CHECK:STDOUT:   %T.as_type.loc5_63.1: type = facet_access_type %T.loc5_12.1 [symbolic = %T.as_type.loc5_63.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc5_12.1, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.491)]
// CHECK:STDOUT:   %Destroy.facet.loc5_63.1: %Destroy.type = facet_value %T.as_type.loc5_63.1, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc5_63.1 (constants.%Destroy.facet)]
// CHECK:STDOUT:   %MaybeUnformed.loc5_63.1: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.loc5_63.1) [symbolic = %MaybeUnformed.loc5_63.1 (constants.%MaybeUnformed.d0b)]
// CHECK:STDOUT:   %pattern_type.loc5_41: type = pattern_type %MaybeUnformed.loc5_63.1 [symbolic = %pattern_type.loc5_41 (constants.%pattern_type.f04)]
// CHECK:STDOUT:   %m.param_patt.loc5_41.2: @Unwrap.%pattern_type.loc5_41 (%pattern_type.f04) = value_param_pattern [symbolic = %m.param_patt.loc5_41.2 (constants.%m.param_patt)]
// CHECK:STDOUT:   %m.patt.loc5_41.2: @Unwrap.%pattern_type.loc5_41 (%pattern_type.f04) = wrapper_binding_pattern m, %m.param_patt.loc5_41.2 [symbolic = %m.patt.loc5_41.2 (constants.%m.patt)]
// CHECK:STDOUT:   %.loc5_69.2: Core.Form = init_form %T.as_type.loc5_63.1 [symbolic = %.loc5_69.2 (constants.%.273)]
// CHECK:STDOUT:   %pattern_type.loc5_69: type = pattern_type %T.as_type.loc5_63.1 [symbolic = %pattern_type.loc5_69 (constants.%pattern_type.0e9)]
// CHECK:STDOUT:   %return.param_patt.loc5_69.2: @Unwrap.%pattern_type.loc5_69 (%pattern_type.0e9) = out_param_pattern [symbolic = %return.param_patt.loc5_69.2 (constants.%return.param_patt.7e1)]
// CHECK:STDOUT:   %return.patt.loc5_66.2: @Unwrap.%pattern_type.loc5_69 (%pattern_type.0e9) = return_slot_pattern %return.param_patt.loc5_69.2, %T.as_type.loc5_63.1 [symbolic = %return.patt.loc5_66.2 (constants.%return.patt.dca)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc5: <witness> = require_complete_type %MaybeUnformed.loc5_63.1 [symbolic = %require_complete.loc5 (constants.%require_complete.eb0)]
// CHECK:STDOUT:   %require_complete.loc6: <witness> = require_complete_type %T.as_type.loc5_63.1 [symbolic = %require_complete.loc6 (constants.%require_complete.091)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc5_12.1, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.fd8)]
// CHECK:STDOUT:   %Copy.facet.loc6_19.3: %Copy.type = facet_value %T.as_type.loc5_63.1, (%Copy.lookup_impl_witness) [symbolic = %Copy.facet.loc6_19.3 (constants.%Copy.facet)]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.loc6_19.3) [symbolic = %Copy.WithSelf.Op.type (constants.%Copy.WithSelf.Op.type.39e)]
// CHECK:STDOUT:   %.loc6_19.5: type = fn_type_with_self_type %Copy.WithSelf.Op.type, %Copy.facet.loc6_19.3 [symbolic = %.loc6_19.5 (constants.%.843)]
// CHECK:STDOUT:   %impl.elem0.loc6_19.2: @Unwrap.%.loc6_19.5 (%.843) = impl_witness_access %Copy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc6_19.2 (constants.%impl.elem0.f20)]
// CHECK:STDOUT:   %specific_impl_fn.loc6_19.2: <specific function> = specific_impl_function %impl.elem0.loc6_19.2, @Copy.WithSelf.Op(%Copy.facet.loc6_19.3) [symbolic = %specific_impl_fn.loc6_19.2 (constants.%specific_impl_fn.6a5)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%m.param: @Unwrap.%MaybeUnformed.loc5_63.1 (%MaybeUnformed.d0b)) -> out %return.param: @Unwrap.%T.as_type.loc5_63.1 (%T.as_type.5d6) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %m.ref: @Unwrap.%MaybeUnformed.loc5_63.1 (%MaybeUnformed.d0b) = name_ref m, %m
// CHECK:STDOUT:     %T.ref.loc6: %facet_type = name_ref T, %T.loc5_12.2 [symbolic = %T.loc5_12.1 (constants.%T.dc4)]
// CHECK:STDOUT:     %T.as_type.loc6: type = facet_access_type %T.ref.loc6 [symbolic = %T.as_type.loc5_63.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:     %.loc6_22: type = converted %T.ref.loc6, %T.as_type.loc6 [symbolic = %T.as_type.loc5_63.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:     %.loc6_19.1: @Unwrap.%T.as_type.loc5_63.1 (%T.as_type.5d6) = as_compatible %m.ref
// CHECK:STDOUT:     %.loc6_19.2: @Unwrap.%T.as_type.loc5_63.1 (%T.as_type.5d6) = converted %m.ref, %.loc6_19.1
// CHECK:STDOUT:     %impl.elem0.loc6_19.1: @Unwrap.%.loc6_19.5 (%.843) = impl_witness_access constants.%Copy.lookup_impl_witness.fd8, element0 [symbolic = %impl.elem0.loc6_19.2 (constants.%impl.elem0.f20)]
// CHECK:STDOUT:     %bound_method.loc6_19.1: <bound method> = bound_method %.loc6_19.2, %impl.elem0.loc6_19.1
// CHECK:STDOUT:     %Copy.facet.loc6_19.1: %Copy.type = facet_value constants.%T.as_type.5d6, (constants.%Copy.lookup_impl_witness.fd8) [symbolic = %Copy.facet.loc6_19.3 (constants.%Copy.facet)]
// CHECK:STDOUT:     %.loc6_19.3: %Copy.type = converted constants.%T.as_type.5d6, %Copy.facet.loc6_19.1 [symbolic = %Copy.facet.loc6_19.3 (constants.%Copy.facet)]
// CHECK:STDOUT:     %Copy.facet.loc6_19.2: %Copy.type = facet_value constants.%T.as_type.5d6, (constants.%Copy.lookup_impl_witness.fd8) [symbolic = %Copy.facet.loc6_19.3 (constants.%Copy.facet)]
// CHECK:STDOUT:     %.loc6_19.4: %Copy.type = converted constants.%T.as_type.5d6, %Copy.facet.loc6_19.2 [symbolic = %Copy.facet.loc6_19.3 (constants.%Copy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc6_19.1: <specific function> = specific_impl_function %impl.elem0.loc6_19.1, @Copy.WithSelf.Op(constants.%Copy.facet) [symbolic = %specific_impl_fn.loc6_19.2 (constants.%specific_impl_fn.6a5)]
// CHECK:STDOUT:     %bound_method.loc6_19.2: <bound method> = bound_method %.loc6_19.2, %specific_impl_fn.loc6_19.1
// CHECK:STDOUT:     %.loc5_69.1: ref @Unwrap.%T.as_type.loc5_63.1 (%T.as_type.5d6) = splice_block %return.param {}
// CHECK:STDOUT:     %Copy.WithSelf.Op.call: init @Unwrap.%T.as_type.loc5_63.1 (%T.as_type.5d6) to %.loc5_69.1 = call %bound_method.loc6_19.2(%.loc6_19.2)
// CHECK:STDOUT:     return %Copy.WithSelf.Op.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Unwrap(constants.%T.dc4) {
// CHECK:STDOUT:   %T.patt.loc5_12.2 => constants.%T.patt.256
// CHECK:STDOUT:   %T.loc5_12.1 => constants.%T.dc4
// CHECK:STDOUT:   %T.as_type.loc5_63.1 => constants.%T.as_type.5d6
// CHECK:STDOUT:   %Destroy.lookup_impl_witness => constants.%Destroy.lookup_impl_witness.491
// CHECK:STDOUT:   %Destroy.facet.loc5_63.1 => constants.%Destroy.facet
// CHECK:STDOUT:   %MaybeUnformed.loc5_63.1 => constants.%MaybeUnformed.d0b
// CHECK:STDOUT:   %pattern_type.loc5_41 => constants.%pattern_type.f04
// CHECK:STDOUT:   %m.param_patt.loc5_41.2 => constants.%m.param_patt
// CHECK:STDOUT:   %m.patt.loc5_41.2 => constants.%m.patt
// CHECK:STDOUT:   %.loc5_69.2 => constants.%.273
// CHECK:STDOUT:   %pattern_type.loc5_69 => constants.%pattern_type.0e9
// CHECK:STDOUT:   %return.param_patt.loc5_69.2 => constants.%return.param_patt.7e1
// CHECK:STDOUT:   %return.patt.loc5_66.2 => constants.%return.patt.dca
// CHECK:STDOUT: }
// CHECK:STDOUT:
