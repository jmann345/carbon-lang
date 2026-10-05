// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/builtins/heap/allocate_free.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/builtins/heap/allocate_free.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Fork (SL-1, fork/slices/plan.md §4.A): the `heap.allocate` and `heap.free`
// builtins. `heap.allocate` names the element type through a `generic`
// parameter, which is not a call parameter, and returns
// `Core.MaybeUnformed(T*)` so that a failed allocation is testable with
// `pointer.is_null`.

// --- call.carbon

library "[[@TEST_NAME]]";

fn Alloc(generic T: type, n: i64) -> Core.MaybeUnformed(T*) = "heap.allocate";
fn Free[T: type](p: T*) = "heap.free";

//@dump-sem-ir-begin
fn F(n: i64) -> Core.MaybeUnformed(i32*) {
  return Alloc(i32, n);
}

fn G(p: i32*) {
  Free(p);
}
//@dump-sem-ir-end

// --- fail_incomplete_pointee.carbon

library "[[@TEST_NAME]]";

class Incomplete;

fn Alloc(generic T: type, n: i64) -> Core.MaybeUnformed(T*) = "heap.allocate";

// Predicted: `IncompleteTypeInBuiltinCall` "pointee type `Incomplete` is
// incomplete in call to builtin function heap.allocate", with the
// `ClassForwardDeclaredHere` note — the lowering multiplies the count by the
// pointee's size, so the call requires it complete.
fn F(n: i64) -> Core.MaybeUnformed(Incomplete*) {
  // CHECK:STDERR: fail_incomplete_pointee.carbon:[[@LINE+7]]:10: error: pointee type `Incomplete` is incomplete in call to builtin function heap.allocate [IncompleteTypeInBuiltinCall]
  // CHECK:STDERR:   return Alloc(Incomplete, n);
  // CHECK:STDERR:          ^~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_incomplete_pointee.carbon:[[@LINE-12]]:1: note: class was forward declared here [ClassForwardDeclaredHere]
  // CHECK:STDERR: class Incomplete;
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Alloc(Incomplete, n);
}

// --- fail_allocate_plain_pointer.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"heap.allocate\"" — the result must be `MaybeUnformed(T*)`, not `T*`.
// CHECK:STDERR: fail_allocate_plain_pointer.carbon:[[@LINE+4]]:1: error: invalid signature for builtin function "heap.allocate" [InvalidBuiltinSignature]
// CHECK:STDERR: fn Bad(generic T: type, n: i64) -> T* = "heap.allocate";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Bad(generic T: type, n: i64) -> T* = "heap.allocate";

// --- fail_free_returns.carbon

library "[[@TEST_NAME]]";

// Predicted: `InvalidBuiltinSignature` "invalid signature for builtin function
// \"heap.free\"" — the builtin returns `()`.
// CHECK:STDERR: fail_free_returns.carbon:[[@LINE+4]]:1: error: invalid signature for builtin function "heap.free" [InvalidBuiltinSignature]
// CHECK:STDERR: fn Bad[T: type](p: T*) -> i32 = "heap.free";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Bad[T: type](p: T*) -> i32 = "heap.free";

// CHECK:STDOUT: --- call.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.f57 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %MaybeUnformed.type: type = generic_class_type @MaybeUnformed [concrete]
// CHECK:STDOUT:   %MaybeUnformed.generic: %MaybeUnformed.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Alloc.type: type = fn_type @Alloc [concrete]
// CHECK:STDOUT:   %Alloc: %Alloc.type = struct_value () [concrete]
// CHECK:STDOUT:   %Free.type: type = fn_type @Free [concrete]
// CHECK:STDOUT:   %Free: %Free.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.f00: type = pattern_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type: type = fn_type @Destroy.Op [concrete]
// CHECK:STDOUT:   %Destroy.Op: %Destroy.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9: <witness> = custom_witness (%Destroy.Op), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.4c4: %Destroy.type = facet_value %ptr.d08, (%custom_witness.df9) [concrete]
// CHECK:STDOUT:   %MaybeUnformed.b84: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.4c4) [concrete]
// CHECK:STDOUT:   %.d9a: Core.Form = init_form %MaybeUnformed.b84 [concrete]
// CHECK:STDOUT:   %pattern_type.1da: type = pattern_type %MaybeUnformed.b84 [concrete]
// CHECK:STDOUT:   %return.param_patt.ede: %pattern_type.1da = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.9a2: %pattern_type.1da = return_slot_pattern %return.param_patt.ede, %MaybeUnformed.b84 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %Alloc.specific_fn: <specific function> = specific_function %Alloc, @Alloc(%i32) [concrete]
// CHECK:STDOUT:   %p.param_patt.b89: %pattern_type.f00 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.f8d: %pattern_type.f00 = wrapper_binding_pattern p, %p.param_patt.b89 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %Free.specific_fn: <specific function> = specific_function %Free, @Free(%i32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .MaybeUnformed = %Core.MaybeUnformed
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.MaybeUnformed: %MaybeUnformed.type = import_ref Core//prelude/types/maybe_unformed, MaybeUnformed, loaded [concrete = constants.%MaybeUnformed.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.f57 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.f57 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.1da = out_param_pattern [concrete = constants.%return.param_patt.ede]
// CHECK:STDOUT:     %return.patt: %pattern_type.1da = return_slot_pattern %return.param_patt, %MaybeUnformed [concrete = constants.%return.patt.9a2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %MaybeUnformed.ref: %MaybeUnformed.type = name_ref MaybeUnformed, imports.%Core.MaybeUnformed [concrete = constants.%MaybeUnformed.generic]
// CHECK:STDOUT:     %i32.loc8: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ptr: type = ptr_type %i32.loc8 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     %Destroy.facet: %Destroy.type = facet_value %ptr, (constants.%custom_witness.df9) [concrete = constants.%Destroy.facet.4c4]
// CHECK:STDOUT:     %.loc8_40.1: %Destroy.type = converted %ptr, %Destroy.facet [concrete = constants.%Destroy.facet.4c4]
// CHECK:STDOUT:     %MaybeUnformed: type = class_type @MaybeUnformed, @MaybeUnformed(constants.%Destroy.facet.4c4) [concrete = constants.%MaybeUnformed.b84]
// CHECK:STDOUT:     %.loc8_40.2: Core.Form = init_form %MaybeUnformed [concrete = constants.%.d9a]
// CHECK:STDOUT:     %n.param: %i64 = value_param call_param0
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %n: %i64 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %MaybeUnformed.b84 = out_param call_param1
// CHECK:STDOUT:     %return: ref %MaybeUnformed.b84 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.f00 = value_param_pattern [concrete = constants.%p.param_patt.b89]
// CHECK:STDOUT:     %p.patt: %pattern_type.f00 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.f8d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %p.param: %ptr.d08 = value_param call_param0
// CHECK:STDOUT:     %.loc12: type = splice_block %ptr [concrete = constants.%ptr.d08] {
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %ptr: type = ptr_type %i32 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.d08 = wrapper_binding p, %p.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op(%self.param: ref %ptr.d08) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%n.param: %i64) -> out %return.param: %MaybeUnformed.b84 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Alloc.ref: %Alloc.type = name_ref Alloc, file.%Alloc.decl [concrete = constants.%Alloc]
// CHECK:STDOUT:   %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %n.ref: %i64 = name_ref n, %n
// CHECK:STDOUT:   %Alloc.specific_fn: <specific function> = specific_function %Alloc.ref, @Alloc(constants.%i32) [concrete = constants.%Alloc.specific_fn]
// CHECK:STDOUT:   %Alloc.call: init %MaybeUnformed.b84 = call %Alloc.specific_fn(%n.ref)
// CHECK:STDOUT:   return %Alloc.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G(%p.param: %ptr.d08) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Free.ref: %Free.type = name_ref Free, file.%Free.decl [concrete = constants.%Free]
// CHECK:STDOUT:   %p.ref: %ptr.d08 = name_ref p, %p
// CHECK:STDOUT:   %Free.specific_fn: <specific function> = specific_function %Free.ref, @Free(constants.%i32) [concrete = constants.%Free.specific_fn]
// CHECK:STDOUT:   %Free.call: init %empty_tuple.type = call %Free.specific_fn(%p.ref)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
