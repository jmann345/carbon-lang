// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/builtins/pointer/offset.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/builtins/pointer/offset.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): the `pointer.offset` builtin, plus the
// two isolating symbolic-pointer shapes of risk R-4 (`Load`: a value read
// through a `Deref` of symbolic `T` goes through the `Copy` witness; `Store`:
// an assignment into a `Deref` of symbolic `T`). If the prelude's own compile
// fails on the same shapes, this file attributes the failure to the shape.

// --- call.carbon

library "[[@TEST_NAME]]";

fn Offset[T: type](p: T*, n: i64) -> T* = "pointer.offset";

//@dump-sem-ir-begin
fn F(p: i32*) -> i32* {
  return Offset(p, 1);
}
//@dump-sem-ir-end

// --- symbolic_deref.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Load[T: Core.Copy](p: T*) -> T {
  return *p;
}

fn Store[T: Core.Copy](p: T*, v: T) {
  *p = v;
}
//@dump-sem-ir-end

// --- fail_incomplete_pointee.carbon

library "[[@TEST_NAME]]";

class Incomplete;

fn Offset[T: type](p: T*, n: i64) -> T* = "pointer.offset";

// Predicted: `IncompleteTypeInBuiltinCall` "pointee type `Incomplete` is
// incomplete in call to builtin function pointer.offset", with the
// `ClassForwardDeclaredHere` note — the lowering strides by the pointee's
// size, so the call requires it complete (an incomplete type would lower to
// an unsized opaque struct and fail the LLVM verifier).
fn F(p: Incomplete*) -> Incomplete* {
  // CHECK:STDERR: fail_incomplete_pointee.carbon:[[@LINE+7]]:10: error: pointee type `Incomplete` is incomplete in call to builtin function pointer.offset [IncompleteTypeInBuiltinCall]
  // CHECK:STDERR:   return Offset(p, 1);
  // CHECK:STDERR:          ^~~~~~~~~~~~
  // CHECK:STDERR: fail_incomplete_pointee.carbon:[[@LINE-13]]:1: note: class was forward declared here [ClassForwardDeclaredHere]
  // CHECK:STDERR: class Incomplete;
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Offset(p, 1);
}

// --- fail_mismatched_pointee.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"pointer.offset\"" — the result pointee must be the parameter pointee.
// CHECK:STDERR: fail_mismatched_pointee.carbon:[[@LINE+4]]:1: error: invalid signature for builtin function "pointer.offset" [InvalidBuiltinSignature]
// CHECK:STDERR: fn Bad[T: type, U: type](p: T*, n: i64) -> U* = "pointer.offset";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Bad[T: type, U: type](p: T*, n: i64) -> U* = "pointer.offset";

// --- fail_non_pointer.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"pointer.offset\"" — the first parameter must be a pointer.
// CHECK:STDERR: fail_non_pointer.carbon:[[@LINE+4]]:1: error: invalid signature for builtin function "pointer.offset" [InvalidBuiltinSignature]
// CHECK:STDERR: fn Bad(p: i64, n: i64) -> i64 = "pointer.offset";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Bad(p: i64, n: i64) -> i64 = "pointer.offset";

// CHECK:STDOUT: --- call.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Offset.type: type = fn_type @Offset [concrete]
// CHECK:STDOUT:   %Offset: %Offset.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.f00: type = pattern_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %p.param_patt.b89: %pattern_type.f00 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.f8d: %pattern_type.f00 = wrapper_binding_pattern p, %p.param_patt.b89 [concrete]
// CHECK:STDOUT:   %.952: Core.Form = init_form %ptr.d08 [concrete]
// CHECK:STDOUT:   %return.param_patt.7dd: %pattern_type.f00 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.dbe: %pattern_type.f00 = return_slot_pattern %return.param_patt.7dd, %ptr.d08 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Offset.specific_fn: <specific function> = specific_function %Offset, @Offset(%i32) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.227: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.f00 = value_param_pattern [concrete = constants.%p.param_patt.b89]
// CHECK:STDOUT:     %p.patt: %pattern_type.f00 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.f8d]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f00 = out_param_pattern [concrete = constants.%return.param_patt.7dd]
// CHECK:STDOUT:     %return.patt: %pattern_type.f00 = return_slot_pattern %return.param_patt, %ptr.loc7_21 [concrete = constants.%return.patt.dbe]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc7_18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ptr.loc7_21: type = ptr_type %i32.loc7_18 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     %.loc7_21: Core.Form = init_form %ptr.loc7_21 [concrete = constants.%.952]
// CHECK:STDOUT:     %p.param: %ptr.d08 = value_param call_param0
// CHECK:STDOUT:     %.loc7_12: type = splice_block %ptr.loc7_12 [concrete = constants.%ptr.d08] {
// CHECK:STDOUT:       %i32.loc7_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %ptr.loc7_12: type = ptr_type %i32.loc7_9 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.d08 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %ptr.d08 = out_param call_param1
// CHECK:STDOUT:     %return: ref %ptr.d08 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%p.param: %ptr.d08) -> out %return.param: %ptr.d08 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Offset.ref: %Offset.type = name_ref Offset, file.%Offset.decl [concrete = constants.%Offset]
// CHECK:STDOUT:   %p.ref: %ptr.d08 = name_ref p, %p
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %Offset.specific_fn: <specific function> = specific_function %Offset.ref, @Offset(constants.%i32) [concrete = constants.%Offset.specific_fn]
// CHECK:STDOUT:   %impl.elem0: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc8_20.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_20.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc8_20.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc8_20.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc8_20.2: %i64 = converted %int_1, %.loc8_20.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %Offset.call: init %ptr.d08 = call %Offset.specific_fn(%p.ref, %.loc8_20.2)
// CHECK:STDOUT:   return %Offset.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- symbolic_deref.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %pattern_type.e81: type = pattern_type %Copy.type [concrete]
// CHECK:STDOUT:   %T.patt.fe6: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.f84: %Copy.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type: type = facet_access_type %T.f84 [symbolic]
// CHECK:STDOUT:   %ptr.215: type = ptr_type %T.as_type [symbolic]
// CHECK:STDOUT:   %pattern_type.d5b: type = pattern_type %ptr.215 [symbolic]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.d5b = value_param_pattern [symbolic]
// CHECK:STDOUT:   %p.patt: %pattern_type.d5b = wrapper_binding_pattern p, %p.param_patt [symbolic]
// CHECK:STDOUT:   %.1ce700.2: Core.Form = init_form %T.as_type [symbolic]
// CHECK:STDOUT:   %pattern_type.2c66b4.2: type = pattern_type %T.as_type [symbolic]
// CHECK:STDOUT:   %return.param_patt.bf4475.2: %pattern_type.2c66b4.2 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %return.patt.f44: %pattern_type.2c66b4.2 = return_slot_pattern %return.param_patt.bf4475.2, %T.as_type [symbolic]
// CHECK:STDOUT:   %Load.type: type = fn_type @Load [concrete]
// CHECK:STDOUT:   %Load: %Load.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.94b: <witness> = require_complete_type %ptr.215 [symbolic]
// CHECK:STDOUT:   %require_complete.d83: <witness> = require_complete_type %T.as_type [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.d9c: <witness> = lookup_impl_witness %T.f84, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.c85f21.2: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%T.f84) [symbolic]
// CHECK:STDOUT:   %.c29: type = fn_type_with_self_type %Copy.WithSelf.Op.type.c85f21.2, %T.f84 [symbolic]
// CHECK:STDOUT:   %impl.elem0.bd2: %.c29 = impl_witness_access %Copy.lookup_impl_witness.d9c, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.e2a: <specific function> = specific_impl_function %impl.elem0.bd2, @Copy.WithSelf.Op(%T.f84) [symbolic]
// CHECK:STDOUT:   %v.param_patt: %pattern_type.2c66b4.2 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %v.patt: %pattern_type.2c66b4.2 = wrapper_binding_pattern v, %v.param_patt [symbolic]
// CHECK:STDOUT:   %Store.type: type = fn_type @Store [concrete]
// CHECK:STDOUT:   %Store: %Store.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/parts/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Load.decl: %Load.type = fn_decl @Load [concrete = constants.%Load] {
// CHECK:STDOUT:     %T.patt.loc5_10.1: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_10.2 (constants.%T.patt.fe6)]
// CHECK:STDOUT:     %p.param_patt.loc5_24.1: @Load.%pattern_type.loc5_24 (%pattern_type.d5b) = value_param_pattern [symbolic = %p.param_patt.loc5_24.2 (constants.%p.param_patt)]
// CHECK:STDOUT:     %p.patt.loc5_24.1: @Load.%pattern_type.loc5_24 (%pattern_type.d5b) = wrapper_binding_pattern p, %p.param_patt.loc5_24.1 [symbolic = %p.patt.loc5_24.2 (constants.%p.patt)]
// CHECK:STDOUT:     %return.param_patt.loc5_33.1: @Load.%pattern_type.loc5_33 (%pattern_type.2c66b4.2) = out_param_pattern [symbolic = %return.param_patt.loc5_33.2 (constants.%return.param_patt.bf4475.2)]
// CHECK:STDOUT:     %return.patt.loc5_30.1: @Load.%pattern_type.loc5_33 (%pattern_type.2c66b4.2) = return_slot_pattern %return.param_patt.loc5_33.1, %.loc5_33.3 [symbolic = %return.patt.loc5_30.2 (constants.%return.patt.f44)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc5_33: %Copy.type = name_ref T, %T.loc5_10.2 [symbolic = %T.loc5_10.1 (constants.%T.f84)]
// CHECK:STDOUT:     %T.as_type.loc5_33: type = facet_access_type %T.ref.loc5_33 [symbolic = %T.as_type.loc5_27.1 (constants.%T.as_type)]
// CHECK:STDOUT:     %.loc5_33.3: type = converted %T.ref.loc5_33, %T.as_type.loc5_33 [symbolic = %T.as_type.loc5_27.1 (constants.%T.as_type)]
// CHECK:STDOUT:     %.loc5_33.4: Core.Form = init_form %.loc5_33.3 [symbolic = %.loc5_33.2 (constants.%.1ce700.2)]
// CHECK:STDOUT:     %.loc5_16: type = splice_block %Copy.ref [concrete = constants.%Copy.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc5_10.2: %Copy.type = symbolic_binding T, 0 [symbolic = %T.loc5_10.1 (constants.%T.f84)]
// CHECK:STDOUT:     %p.param: @Load.%ptr.loc5_27.1 (%ptr.215) = value_param call_param0
// CHECK:STDOUT:     %.loc5_27.1: type = splice_block %ptr.loc5_27.2 [symbolic = %ptr.loc5_27.1 (constants.%ptr.215)] {
// CHECK:STDOUT:       %T.ref.loc5_26: %Copy.type = name_ref T, %T.loc5_10.2 [symbolic = %T.loc5_10.1 (constants.%T.f84)]
// CHECK:STDOUT:       %T.as_type.loc5_27.2: type = facet_access_type %T.ref.loc5_26 [symbolic = %T.as_type.loc5_27.1 (constants.%T.as_type)]
// CHECK:STDOUT:       %.loc5_27.2: type = converted %T.ref.loc5_26, %T.as_type.loc5_27.2 [symbolic = %T.as_type.loc5_27.1 (constants.%T.as_type)]
// CHECK:STDOUT:       %ptr.loc5_27.2: type = ptr_type %.loc5_27.2 [symbolic = %ptr.loc5_27.1 (constants.%ptr.215)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: @Load.%ptr.loc5_27.1 (%ptr.215) = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref @Load.%T.as_type.loc5_27.1 (%T.as_type) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Load.%T.as_type.loc5_27.1 (%T.as_type) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Store.decl: %Store.type = fn_decl @Store [concrete = constants.%Store] {
// CHECK:STDOUT:     %T.patt.loc9_11.1: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_11.2 (constants.%T.patt.fe6)]
// CHECK:STDOUT:     %p.param_patt.loc9_25.1: @Store.%pattern_type.loc9_25 (%pattern_type.d5b) = value_param_pattern [symbolic = %p.param_patt.loc9_25.2 (constants.%p.param_patt)]
// CHECK:STDOUT:     %p.patt.loc9_25.1: @Store.%pattern_type.loc9_25 (%pattern_type.d5b) = wrapper_binding_pattern p, %p.param_patt.loc9_25.1 [symbolic = %p.patt.loc9_25.2 (constants.%p.patt)]
// CHECK:STDOUT:     %v.param_patt.loc9_32.1: @Store.%pattern_type.loc9_32 (%pattern_type.2c66b4.2) = value_param_pattern [symbolic = %v.param_patt.loc9_32.2 (constants.%v.param_patt)]
// CHECK:STDOUT:     %v.patt.loc9_32.1: @Store.%pattern_type.loc9_32 (%pattern_type.2c66b4.2) = wrapper_binding_pattern v, %v.param_patt.loc9_32.1 [symbolic = %v.patt.loc9_32.2 (constants.%v.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc9_17: type = splice_block %Copy.ref [concrete = constants.%Copy.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc9_11.2: %Copy.type = symbolic_binding T, 0 [symbolic = %T.loc9_11.1 (constants.%T.f84)]
// CHECK:STDOUT:     %p.param: @Store.%ptr.loc9_28.1 (%ptr.215) = value_param call_param0
// CHECK:STDOUT:     %.loc9_28.1: type = splice_block %ptr.loc9_28.2 [symbolic = %ptr.loc9_28.1 (constants.%ptr.215)] {
// CHECK:STDOUT:       %T.ref.loc9_27: %Copy.type = name_ref T, %T.loc9_11.2 [symbolic = %T.loc9_11.1 (constants.%T.f84)]
// CHECK:STDOUT:       %T.as_type.loc9_28.2: type = facet_access_type %T.ref.loc9_27 [symbolic = %T.as_type.loc9_28.1 (constants.%T.as_type)]
// CHECK:STDOUT:       %.loc9_28.2: type = converted %T.ref.loc9_27, %T.as_type.loc9_28.2 [symbolic = %T.as_type.loc9_28.1 (constants.%T.as_type)]
// CHECK:STDOUT:       %ptr.loc9_28.2: type = ptr_type %.loc9_28.2 [symbolic = %ptr.loc9_28.1 (constants.%ptr.215)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: @Store.%ptr.loc9_28.1 (%ptr.215) = wrapper_binding p, %p.param
// CHECK:STDOUT:     %v.param: @Store.%T.as_type.loc9_28.1 (%T.as_type) = value_param call_param1
// CHECK:STDOUT:     %.loc9_34.1: type = splice_block %.loc9_34.2 [symbolic = %T.as_type.loc9_28.1 (constants.%T.as_type)] {
// CHECK:STDOUT:       %T.ref.loc9_34: %Copy.type = name_ref T, %T.loc9_11.2 [symbolic = %T.loc9_11.1 (constants.%T.f84)]
// CHECK:STDOUT:       %T.as_type.loc9_34: type = facet_access_type %T.ref.loc9_34 [symbolic = %T.as_type.loc9_28.1 (constants.%T.as_type)]
// CHECK:STDOUT:       %.loc9_34.2: type = converted %T.ref.loc9_34, %T.as_type.loc9_34 [symbolic = %T.as_type.loc9_28.1 (constants.%T.as_type)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v: @Store.%T.as_type.loc9_28.1 (%T.as_type) = wrapper_binding v, %v.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Load(%T.loc5_10.2: %Copy.type) {
// CHECK:STDOUT:   %T.patt.loc5_10.2: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc5_10.2 (constants.%T.patt.fe6)]
// CHECK:STDOUT:   %T.loc5_10.1: %Copy.type = symbolic_binding T, 0 [symbolic = %T.loc5_10.1 (constants.%T.f84)]
// CHECK:STDOUT:   %T.as_type.loc5_27.1: type = facet_access_type %T.loc5_10.1 [symbolic = %T.as_type.loc5_27.1 (constants.%T.as_type)]
// CHECK:STDOUT:   %ptr.loc5_27.1: type = ptr_type %T.as_type.loc5_27.1 [symbolic = %ptr.loc5_27.1 (constants.%ptr.215)]
// CHECK:STDOUT:   %pattern_type.loc5_24: type = pattern_type %ptr.loc5_27.1 [symbolic = %pattern_type.loc5_24 (constants.%pattern_type.d5b)]
// CHECK:STDOUT:   %p.param_patt.loc5_24.2: @Load.%pattern_type.loc5_24 (%pattern_type.d5b) = value_param_pattern [symbolic = %p.param_patt.loc5_24.2 (constants.%p.param_patt)]
// CHECK:STDOUT:   %p.patt.loc5_24.2: @Load.%pattern_type.loc5_24 (%pattern_type.d5b) = wrapper_binding_pattern p, %p.param_patt.loc5_24.2 [symbolic = %p.patt.loc5_24.2 (constants.%p.patt)]
// CHECK:STDOUT:   %.loc5_33.2: Core.Form = init_form %T.as_type.loc5_27.1 [symbolic = %.loc5_33.2 (constants.%.1ce700.2)]
// CHECK:STDOUT:   %pattern_type.loc5_33: type = pattern_type %T.as_type.loc5_27.1 [symbolic = %pattern_type.loc5_33 (constants.%pattern_type.2c66b4.2)]
// CHECK:STDOUT:   %return.param_patt.loc5_33.2: @Load.%pattern_type.loc5_33 (%pattern_type.2c66b4.2) = out_param_pattern [symbolic = %return.param_patt.loc5_33.2 (constants.%return.param_patt.bf4475.2)]
// CHECK:STDOUT:   %return.patt.loc5_30.2: @Load.%pattern_type.loc5_33 (%pattern_type.2c66b4.2) = return_slot_pattern %return.param_patt.loc5_33.2, %T.as_type.loc5_27.1 [symbolic = %return.patt.loc5_30.2 (constants.%return.patt.f44)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc5_24: <witness> = require_complete_type %ptr.loc5_27.1 [symbolic = %require_complete.loc5_24 (constants.%require_complete.94b)]
// CHECK:STDOUT:   %require_complete.loc5_30: <witness> = require_complete_type %T.as_type.loc5_27.1 [symbolic = %require_complete.loc5_30 (constants.%require_complete.d83)]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%T.loc5_10.1) [symbolic = %Copy.WithSelf.Op.type (constants.%Copy.WithSelf.Op.type.c85f21.2)]
// CHECK:STDOUT:   %.loc6_10.5: type = fn_type_with_self_type %Copy.WithSelf.Op.type, %T.loc5_10.1 [symbolic = %.loc6_10.5 (constants.%.c29)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc5_10.1, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.d9c)]
// CHECK:STDOUT:   %impl.elem0.loc6_10.2: @Load.%.loc6_10.5 (%.c29) = impl_witness_access %Copy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc6_10.2 (constants.%impl.elem0.bd2)]
// CHECK:STDOUT:   %specific_impl_fn.loc6_10.2: <specific function> = specific_impl_function %impl.elem0.loc6_10.2, @Copy.WithSelf.Op(%T.loc5_10.1) [symbolic = %specific_impl_fn.loc6_10.2 (constants.%specific_impl_fn.e2a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%p.param: @Load.%ptr.loc5_27.1 (%ptr.215)) -> out %return.param: @Load.%T.as_type.loc5_27.1 (%T.as_type) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %p.ref: @Load.%ptr.loc5_27.1 (%ptr.215) = name_ref p, %p
// CHECK:STDOUT:     %.loc6_10.1: ref @Load.%T.as_type.loc5_27.1 (%T.as_type) = deref %p.ref
// CHECK:STDOUT:     %.loc6_10.2: @Load.%T.as_type.loc5_27.1 (%T.as_type) = acquire_value %.loc6_10.1
// CHECK:STDOUT:     %impl.elem0.loc6_10.1: @Load.%.loc6_10.5 (%.c29) = impl_witness_access constants.%Copy.lookup_impl_witness.d9c, element0 [symbolic = %impl.elem0.loc6_10.2 (constants.%impl.elem0.bd2)]
// CHECK:STDOUT:     %bound_method.loc6_10.1: <bound method> = bound_method %.loc6_10.2, %impl.elem0.loc6_10.1
// CHECK:STDOUT:     %.loc6_10.3: %Copy.type = converted constants.%T.as_type, constants.%T.f84 [symbolic = %T.loc5_10.1 (constants.%T.f84)]
// CHECK:STDOUT:     %.loc6_10.4: %Copy.type = converted constants.%T.as_type, constants.%T.f84 [symbolic = %T.loc5_10.1 (constants.%T.f84)]
// CHECK:STDOUT:     %specific_impl_fn.loc6_10.1: <specific function> = specific_impl_function %impl.elem0.loc6_10.1, @Copy.WithSelf.Op(constants.%T.f84) [symbolic = %specific_impl_fn.loc6_10.2 (constants.%specific_impl_fn.e2a)]
// CHECK:STDOUT:     %bound_method.loc6_10.2: <bound method> = bound_method %.loc6_10.2, %specific_impl_fn.loc6_10.1
// CHECK:STDOUT:     %.loc5_33.1: ref @Load.%T.as_type.loc5_27.1 (%T.as_type) = splice_block %return.param {}
// CHECK:STDOUT:     %Copy.WithSelf.Op.call: init @Load.%T.as_type.loc5_27.1 (%T.as_type) to %.loc5_33.1 = call %bound_method.loc6_10.2(%.loc6_10.2)
// CHECK:STDOUT:     return %Copy.WithSelf.Op.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Store(%T.loc9_11.2: %Copy.type) {
// CHECK:STDOUT:   %T.patt.loc9_11.2: %pattern_type.e81 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc9_11.2 (constants.%T.patt.fe6)]
// CHECK:STDOUT:   %T.loc9_11.1: %Copy.type = symbolic_binding T, 0 [symbolic = %T.loc9_11.1 (constants.%T.f84)]
// CHECK:STDOUT:   %T.as_type.loc9_28.1: type = facet_access_type %T.loc9_11.1 [symbolic = %T.as_type.loc9_28.1 (constants.%T.as_type)]
// CHECK:STDOUT:   %ptr.loc9_28.1: type = ptr_type %T.as_type.loc9_28.1 [symbolic = %ptr.loc9_28.1 (constants.%ptr.215)]
// CHECK:STDOUT:   %pattern_type.loc9_25: type = pattern_type %ptr.loc9_28.1 [symbolic = %pattern_type.loc9_25 (constants.%pattern_type.d5b)]
// CHECK:STDOUT:   %p.param_patt.loc9_25.2: @Store.%pattern_type.loc9_25 (%pattern_type.d5b) = value_param_pattern [symbolic = %p.param_patt.loc9_25.2 (constants.%p.param_patt)]
// CHECK:STDOUT:   %p.patt.loc9_25.2: @Store.%pattern_type.loc9_25 (%pattern_type.d5b) = wrapper_binding_pattern p, %p.param_patt.loc9_25.2 [symbolic = %p.patt.loc9_25.2 (constants.%p.patt)]
// CHECK:STDOUT:   %pattern_type.loc9_32: type = pattern_type %T.as_type.loc9_28.1 [symbolic = %pattern_type.loc9_32 (constants.%pattern_type.2c66b4.2)]
// CHECK:STDOUT:   %v.param_patt.loc9_32.2: @Store.%pattern_type.loc9_32 (%pattern_type.2c66b4.2) = value_param_pattern [symbolic = %v.param_patt.loc9_32.2 (constants.%v.param_patt)]
// CHECK:STDOUT:   %v.patt.loc9_32.2: @Store.%pattern_type.loc9_32 (%pattern_type.2c66b4.2) = wrapper_binding_pattern v, %v.param_patt.loc9_32.2 [symbolic = %v.patt.loc9_32.2 (constants.%v.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc9_25: <witness> = require_complete_type %ptr.loc9_28.1 [symbolic = %require_complete.loc9_25 (constants.%require_complete.94b)]
// CHECK:STDOUT:   %require_complete.loc9_32: <witness> = require_complete_type %T.as_type.loc9_28.1 [symbolic = %require_complete.loc9_32 (constants.%require_complete.d83)]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%T.loc9_11.1) [symbolic = %Copy.WithSelf.Op.type (constants.%Copy.WithSelf.Op.type.c85f21.2)]
// CHECK:STDOUT:   %.loc10_8.3: type = fn_type_with_self_type %Copy.WithSelf.Op.type, %T.loc9_11.1 [symbolic = %.loc10_8.3 (constants.%.c29)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc9_11.1, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.d9c)]
// CHECK:STDOUT:   %impl.elem0.loc10_8.2: @Store.%.loc10_8.3 (%.c29) = impl_witness_access %Copy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc10_8.2 (constants.%impl.elem0.bd2)]
// CHECK:STDOUT:   %specific_impl_fn.loc10_8.2: <specific function> = specific_impl_function %impl.elem0.loc10_8.2, @Copy.WithSelf.Op(%T.loc9_11.1) [symbolic = %specific_impl_fn.loc10_8.2 (constants.%specific_impl_fn.e2a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%p.param: @Store.%ptr.loc9_28.1 (%ptr.215), %v.param: @Store.%T.as_type.loc9_28.1 (%T.as_type)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %p.ref: @Store.%ptr.loc9_28.1 (%ptr.215) = name_ref p, %p
// CHECK:STDOUT:     %.loc10_3.1: ref @Store.%T.as_type.loc9_28.1 (%T.as_type) = deref %p.ref
// CHECK:STDOUT:     %v.ref: @Store.%T.as_type.loc9_28.1 (%T.as_type) = name_ref v, %v
// CHECK:STDOUT:     %impl.elem0.loc10_8.1: @Store.%.loc10_8.3 (%.c29) = impl_witness_access constants.%Copy.lookup_impl_witness.d9c, element0 [symbolic = %impl.elem0.loc10_8.2 (constants.%impl.elem0.bd2)]
// CHECK:STDOUT:     %bound_method.loc10_8.1: <bound method> = bound_method %v.ref, %impl.elem0.loc10_8.1
// CHECK:STDOUT:     %.loc10_8.1: %Copy.type = converted constants.%T.as_type, constants.%T.f84 [symbolic = %T.loc9_11.1 (constants.%T.f84)]
// CHECK:STDOUT:     %.loc10_8.2: %Copy.type = converted constants.%T.as_type, constants.%T.f84 [symbolic = %T.loc9_11.1 (constants.%T.f84)]
// CHECK:STDOUT:     %specific_impl_fn.loc10_8.1: <specific function> = specific_impl_function %impl.elem0.loc10_8.1, @Copy.WithSelf.Op(constants.%T.f84) [symbolic = %specific_impl_fn.loc10_8.2 (constants.%specific_impl_fn.e2a)]
// CHECK:STDOUT:     %bound_method.loc10_8.2: <bound method> = bound_method %v.ref, %specific_impl_fn.loc10_8.1
// CHECK:STDOUT:     %.loc10_3.2: ref @Store.%T.as_type.loc9_28.1 (%T.as_type) = splice_block %.loc10_3.1 {}
// CHECK:STDOUT:     %Copy.WithSelf.Op.call: init @Store.%T.as_type.loc9_28.1 (%T.as_type) to %.loc10_3.2 = call %bound_method.loc10_8.2(%v.ref)
// CHECK:STDOUT:     assign %.loc10_3.1, %Copy.WithSelf.Op.call
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Load(constants.%T.f84) {
// CHECK:STDOUT:   %T.patt.loc5_10.2 => constants.%T.patt.fe6
// CHECK:STDOUT:   %T.loc5_10.1 => constants.%T.f84
// CHECK:STDOUT:   %T.as_type.loc5_27.1 => constants.%T.as_type
// CHECK:STDOUT:   %ptr.loc5_27.1 => constants.%ptr.215
// CHECK:STDOUT:   %pattern_type.loc5_24 => constants.%pattern_type.d5b
// CHECK:STDOUT:   %p.param_patt.loc5_24.2 => constants.%p.param_patt
// CHECK:STDOUT:   %p.patt.loc5_24.2 => constants.%p.patt
// CHECK:STDOUT:   %.loc5_33.2 => constants.%.1ce700.2
// CHECK:STDOUT:   %pattern_type.loc5_33 => constants.%pattern_type.2c66b4.2
// CHECK:STDOUT:   %return.param_patt.loc5_33.2 => constants.%return.param_patt.bf4475.2
// CHECK:STDOUT:   %return.patt.loc5_30.2 => constants.%return.patt.f44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Store(constants.%T.f84) {
// CHECK:STDOUT:   %T.patt.loc9_11.2 => constants.%T.patt.fe6
// CHECK:STDOUT:   %T.loc9_11.1 => constants.%T.f84
// CHECK:STDOUT:   %T.as_type.loc9_28.1 => constants.%T.as_type
// CHECK:STDOUT:   %ptr.loc9_28.1 => constants.%ptr.215
// CHECK:STDOUT:   %pattern_type.loc9_25 => constants.%pattern_type.d5b
// CHECK:STDOUT:   %p.param_patt.loc9_25.2 => constants.%p.param_patt
// CHECK:STDOUT:   %p.patt.loc9_25.2 => constants.%p.patt
// CHECK:STDOUT:   %pattern_type.loc9_32 => constants.%pattern_type.2c66b4.2
// CHECK:STDOUT:   %v.param_patt.loc9_32.2 => constants.%v.param_patt
// CHECK:STDOUT:   %v.patt.loc9_32.2 => constants.%v.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
