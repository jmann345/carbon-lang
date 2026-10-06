// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/if_expr/arm_temporary.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/if_expr/arm_temporary.carbon

// --- member_of_temporary.carbon

library "[[@TEST_NAME]]";

class C {
  var x: i32;
}

fn Make(x: i32) -> C { return {.x = x}; }

// Each arm's `Make(...)` temporary is destroyed at the end of that arm, after
// its member has been read, rather than in the `if.expr.result` block: only
// the taken arm's temporary exists there, and neither arm's creation of it
// dominates that block.
//@dump-sem-ir-begin
fn F(c: bool) -> i32 {
  return if c then Make(1).x else Make(2).x;
}
//@dump-sem-ir-end

// --- fail_todo_by_ref_result.carbon

library "[[@TEST_NAME]]";

class C {
  var x: i32;
}

fn Make(x: i32) -> C { return {.x = x}; }

fn Use(c: C);

fn G(c: bool) {
  // A class value refers to the object it was formed from, here the arm's own
  // temporary, which the arm would destroy before the `if` expression's value
  // is used; the arm is diagnosed instead.
  // CHECK:STDERR: fail_todo_by_ref_result.carbon:[[@LINE+4]]:12: error: semantics TODO: `destroying temporaries of a conditionally evaluated operand whose value is not passed by copy` [SemanticsTodo]
  // CHECK:STDERR:   Use(if c then Make(1) else Make(2));
  // CHECK:STDERR:            ^~~~~~~~~~~~
  // CHECK:STDERR:
  Use(if c then Make(1) else Make(2));
}

// CHECK:STDOUT: --- member_of_temporary.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %C.elem: type = unbound_element_type %C, %i32 [concrete]
// CHECK:STDOUT:   %struct_type.x: type = struct_type {.x: %i32} [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %Make.type: type = fn_type @Make [concrete]
// CHECK:STDOUT:   %Make: %Make.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.831 = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc16_26.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc16_26.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc16_26.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.946: type = pattern_type %struct_type.x [concrete]
// CHECK:STDOUT:   %self.param_patt.3f5: %pattern_type.946 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.7ec: %pattern_type.946 = wrapper_binding_pattern self, %self.param_patt.3f5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc16_26.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc16_26.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.99a: %pattern_type.98b = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.cbd: %pattern_type.98b = wrapper_binding_pattern self, %self.param_patt.99a [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc16_26.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc16_26.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc16_26.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc16_26.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc16_26.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc16_26.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.946 = ref_param_pattern [concrete = constants.%self.param_patt.3f5]
// CHECK:STDOUT:     %self.patt: %pattern_type.946 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.7ec]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.x = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.x = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc16_26.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.946 = ref_param_pattern [concrete = constants.%self.param_patt.3f5]
// CHECK:STDOUT:     %self.patt: %pattern_type.946 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.7ec]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.x = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.x = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc16_26.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.98b = ref_param_pattern [concrete = constants.%self.param_patt.99a]
// CHECK:STDOUT:     %self.patt: %pattern_type.98b = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.cbd]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %C = ref_param call_param0
// CHECK:STDOUT:     %self: ref %C = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc16_26.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.98b = ref_param_pattern [concrete = constants.%self.param_patt.99a]
// CHECK:STDOUT:     %self.patt: %pattern_type.98b = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.cbd]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %C = ref_param call_param0
// CHECK:STDOUT:     %self: ref %C = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %c.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.831 = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc15_18: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %c.param: bool = value_param call_param0
// CHECK:STDOUT:     %.loc15_9: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %c: bool = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%c.param: bool) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.ref: bool = name_ref c, %c
// CHECK:STDOUT:   if %c.ref br !if.expr.then else br !if.expr.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.expr.then:
// CHECK:STDOUT:   %Make.ref.loc16_20: %Make.type = name_ref Make, file.%Make.decl [concrete = constants.%Make]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc16_26.1: ref %C = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc16_25: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_25.1: <bound method> = bound_method %int_1, %impl.elem0.loc16_25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc16_25: <specific function> = specific_function %impl.elem0.loc16_25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_25.2: <bound method> = bound_method %int_1, %specific_fn.loc16_25 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_25: init %i32 = call %bound_method.loc16_25.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc16_25.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_25 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc16_25.2: %i32 = converted %int_1, %.loc16_25.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Make.call.loc16_26: init %C to %.loc16_26.1 = call %Make.ref.loc16_20(%.loc16_25.2)
// CHECK:STDOUT:   %.loc16_26.2: ref %C = temporary %.loc16_26.1, %Make.call.loc16_26
// CHECK:STDOUT:   %x.ref.loc16_27: %C.elem = name_ref x, @C.%field_decl [concrete = @C.%field_decl]
// CHECK:STDOUT:   %.loc16_27.1: ref %i32 = class_element_access %.loc16_26.2, element0
// CHECK:STDOUT:   %.loc16_27.2: %i32 = acquire_value %.loc16_27.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc16_26: <bound method> = bound_method %.loc16_26.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc16_26: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc16_26(%.loc16_26.2)
// CHECK:STDOUT:   br !if.expr.result(%.loc16_27.2)
// CHECK:STDOUT:
// CHECK:STDOUT: !if.expr.else:
// CHECK:STDOUT:   %Make.ref.loc16_35: %Make.type = name_ref Make, file.%Make.decl [concrete = constants.%Make]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc16_41.1: ref %C = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc16_40: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_40.1: <bound method> = bound_method %int_2, %impl.elem0.loc16_40 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc16_40: <specific function> = specific_function %impl.elem0.loc16_40, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_40.2: <bound method> = bound_method %int_2, %specific_fn.loc16_40 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_40: init %i32 = call %bound_method.loc16_40.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc16_40.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16_40 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc16_40.2: %i32 = converted %int_2, %.loc16_40.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %Make.call.loc16_41: init %C to %.loc16_41.1 = call %Make.ref.loc16_35(%.loc16_40.2)
// CHECK:STDOUT:   %.loc16_41.2: ref %C = temporary %.loc16_41.1, %Make.call.loc16_41
// CHECK:STDOUT:   %x.ref.loc16_42: %C.elem = name_ref x, @C.%field_decl [concrete = @C.%field_decl]
// CHECK:STDOUT:   %.loc16_42.1: ref %i32 = class_element_access %.loc16_41.2, element0
// CHECK:STDOUT:   %.loc16_42.2: %i32 = acquire_value %.loc16_42.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc16_41: <bound method> = bound_method %.loc16_41.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc16_41: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc16_41(%.loc16_41.2)
// CHECK:STDOUT:   br !if.expr.result(%.loc16_42.2)
// CHECK:STDOUT:
// CHECK:STDOUT: !if.expr.result:
// CHECK:STDOUT:   %.loc16_10: %i32 = block_arg !if.expr.result
// CHECK:STDOUT:   %impl.elem0.loc16_10: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc16_10.1: <bound method> = bound_method %.loc16_10, %impl.elem0.loc16_10
// CHECK:STDOUT:   %specific_fn.loc16_10: <specific function> = specific_function %impl.elem0.loc16_10, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_10.2: <bound method> = bound_method %.loc16_10, %specific_fn.loc16_10
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc16_10.2(%.loc16_10)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc16_26.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc16_26.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc16_26.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc16_26.2(%self.param: ref %struct_type.x) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc16: ref %i32 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc16, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc16)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc16_26.2(%self.param: ref %struct_type.x) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc16_26.2(%self.param: ref %struct_type.x) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc16_26.3(%self.param: ref %C) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref: %C.elem = name_ref x, @C.%field_decl [concrete = @C.%field_decl]
// CHECK:STDOUT:   %.loc16: ref %i32 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc16, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc16)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc16_26.3(%self.param: ref %C) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc16_26.3(%self.param: ref %C) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
