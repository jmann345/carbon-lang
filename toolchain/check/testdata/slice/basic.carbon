// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/basic.carbon
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

// Fork (SL-1, fork/slices/plan.md §4.A): `Core.Slice(T)` (D-SL-1..3, 7, 10).
// Positives only, one dump range per function.

// --- from_array_index.carbon

library "[[@TEST_NAME]]";

// Predicted: a `FromArray` specific with `N = 4` deduced from
// `array(i32, 4)*`; the literal subscript converted to `i64` by the
// literal-subscript rule (check/handle_index.cpp: `Slice(i32)` implements
// `IndexWith(i64)` and not `IndexWith(Core.IntLiteral)`), so the
// `Slice(i32) as IndexWith(i64)` witness and an `At` call with an `i64`
// argument producing a value of type `i32`.
//@dump-sem-ir-begin
fn F() -> i32 {
  var a: array(i32, 4) = (1, 2, 3, 4);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  return s[1];
}
//@dump-sem-ir-end

// --- index_runtime_subscript.carbon

library "[[@TEST_NAME]]";

// Predicted: an `i64` subscript dispatches `IndexWith(i64)` directly, with no
// conversion of `i` (an `i32` subscript is the `fail_subscript_i32` pin in
// fail_basic.carbon).
//@dump-sem-ir-begin
fn G(s: Core.Slice(i32), i: i64) -> i32 {
  return s[i];
}
//@dump-sem-ir-end

// --- subslice_and_size.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn H(s: Core.Slice(i32)) -> i64 {
  return s.Subslice(1, 3).Size();
}
//@dump-sem-ir-end

// --- const_view.carbon

library "[[@TEST_NAME]]";

// Predicted: the out-of-class `impl forall [T] Slice(T) as
// ImplicitAs(Slice(const T))` witness (D-SL-10).
//@dump-sem-ir-begin
fn K(s: Core.Slice(i32)) -> Core.Slice(const i32) {
  return s;
}
//@dump-sem-ir-end

// --- iterate.carbon

library "[[@TEST_NAME]]";

// Predicted: the `Slice(T) as Iterate` witness with `NewCursor` and `Next`
// calls (D-SL-7).
//@dump-sem-ir-begin
fn Sum(s: Core.Slice(i32)) -> i32 {
  var t: i32 = 0;
  for (x: i32 in s) {
    t += x;
  }
  return t;
}
//@dump-sem-ir-end

// --- unformed.carbon

library "[[@TEST_NAME]]";

// Predicted: the `DefaultOrUnformed` blanket impl over `UnformedInit`; no
// `ConversionFailureTypeToFacet`. The only diagnostic is the `UnusedBinding`
// WARNING on `s` (a warning needs no `fail_` prefix: patterns/unused.carbon).
//@dump-sem-ir-begin
fn U() {
  // CHECK:STDERR: unformed.carbon:[[@LINE+4]]:7: warning: binding `s` unused [UnusedBinding]
  // CHECK:STDERR:   var s: Core.Slice(i32);
  // CHECK:STDERR:       ^~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var s: Core.Slice(i32);
}
//@dump-sem-ir-end

// --- generic_element.carbon

library "[[@TEST_NAME]]";

// Predicted: clean. The literal converts to `i64` (`IndexWith(Core.IntLiteral)`
// has no candidate for the symbolic `Slice(T)`; the `IndexWith(i64)` impl
// has), and because that impl is `final` the symbolic lookup resolves it here
// rather than deferring to the specific, so `.ElementType` rewrites to `T` and
// `s[0]` has type `T`. (Round 4: through the non-final impl the hosted fill
// pinned `cannot implicitly convert ... Core.Slice(T).(Core.IndexWith(i64)
// .ElementType) to T` — the rewrite of a non-final impl is not known in a
// symbolic context, since a more specific impl could still exist.)
//@dump-sem-ir-begin
fn First[T: Core.Copy & Core.Destroy](s: Core.Slice(T)) -> T {
  return s[0];
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- from_array_index.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %array_type.88c: type = array_type %int_4.0c1, %i32 [concrete]
// CHECK:STDOUT:   %ptr.958: type = ptr_type %array_type.88c [concrete]
// CHECK:STDOUT:   %pattern_type.c6c: type = pattern_type %array_type.88c [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.c6c = ref_binding_pattern a [concrete]
// CHECK:STDOUT:   %a.var_patt: %pattern_type.c6c = var_pattern %a.patt [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %tuple.type.d46: type = tuple_type (Core.IntLiteral, Core.IntLiteral, Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %tuple.d0e: %tuple.type.d46 = tuple_value (%int_1.5b8, %int_2.ecc, %int_3.1ba, %int_4.0c1) [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.b7a: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_4.4eb: %i32 = int_value 4 [concrete]
// CHECK:STDOUT:   %array: %array_type.88c = tuple_value (%int_1.0c6, %int_2.295, %int_3.410, %int_4.4eb) [concrete]
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %facet_type.a1a: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %T.dc4: %facet_type.a1a = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Slice.FromArray.type.645: type = fn_type @Slice.FromArray, @Slice(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Slice.FromArray.b30: %Slice.FromArray.type.645 = struct_value () [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.227: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc13_24.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.a1a = facet_value %i32, (%Copy.impl_witness.b51, %custom_witness.df9cc1.2) [concrete]
// CHECK:STDOUT:   %Slice.8ee: type = class_type @Slice, @Slice(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.FromArray.type.784: type = fn_type @Slice.FromArray, @Slice(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.FromArray.901: %Slice.FromArray.type.784 = struct_value () [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %struct_type.ptr.size.0cc: type = struct_type {.ptr: %ptr.d08, .size: %i64} [concrete]
// CHECK:STDOUT:   %pattern_type.095: type = pattern_type %Slice.8ee [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.095 = value_binding_pattern s [concrete]
// CHECK:STDOUT:   %Slice.FromArray.specific_fn: <specific function> = specific_function %Slice.FromArray.901, @Slice.FromArray(%facet_value, %int_4.0c1) [concrete]
// CHECK:STDOUT:   %IndexWith.type.df6: type = generic_interface_type @IndexWith [concrete]
// CHECK:STDOUT:   %IndexWith.generic: %IndexWith.type.df6 = struct_value () [concrete]
// CHECK:STDOUT:   %IndexWith.type.3ea: type = facet_type <@IndexWith, @IndexWith(%i64)> [concrete]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.type.b97: type = fn_type @Slice.as.IndexWith.impl.At, @Slice.as.IndexWith.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.6f3: %Slice.as.IndexWith.impl.At.type.b97 = struct_value () [symbolic]
// CHECK:STDOUT:   %IndexWith.impl_witness.2c7: <witness> = impl_witness imports.%IndexWith.impl_witness_table, @Slice.as.IndexWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.type.cda: type = fn_type @Slice.as.IndexWith.impl.At, @Slice.as.IndexWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.c7d: %Slice.as.IndexWith.impl.At.type.cda = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.235: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet.235 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.c5e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %IndexWith.facet: %IndexWith.type.3ea = facet_value %Slice.8ee, (%IndexWith.impl_witness.2c7) [concrete]
// CHECK:STDOUT:   %IndexWith.WithSelf.At.type.35a: type = fn_type @IndexWith.WithSelf.At, @IndexWith.WithSelf(%i64, %IndexWith.facet) [concrete]
// CHECK:STDOUT:   %.88b: type = fn_type_with_self_type %IndexWith.WithSelf.At.type.35a, %IndexWith.facet [concrete]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.specific_fn: <specific function> = specific_function %Slice.as.IndexWith.impl.At.c7d, @Slice.as.IndexWith.impl.At(%facet_value) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.7: type = fn_type @Destroy.Op.loc13_56.5 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.7: %Destroy.Op.type.1d8f74.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .IndexWith = %Core.IndexWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.import_ref.38f: @Slice.%Slice.FromArray.type (%Slice.FromArray.type.645) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.%Slice.FromArray (constants.%Slice.FromArray.b30)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.IndexWith: %IndexWith.type.df6 = import_ref Core//prelude/operators/index, IndexWith, loaded [concrete = constants.%IndexWith.generic]
// CHECK:STDOUT:   %Core.import_ref.ef4 = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.d81: @Slice.as.IndexWith.impl.%Slice.as.IndexWith.impl.At.type (%Slice.as.IndexWith.impl.At.type.b97) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.IndexWith.impl.%Slice.as.IndexWith.impl.At (constants.%Slice.as.IndexWith.impl.At.6f3)]
// CHECK:STDOUT:   %IndexWith.impl_witness_table = impl_witness_table (%Core.import_ref.ef4, %Core.import_ref.d81), @Slice.as.IndexWith.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc11 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11: Core.Form = init_form %i32.loc11 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %a.var: ref %array_type.88c = var_storage %a.var_patt
// CHECK:STDOUT:   %int_1.loc12_27: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2.loc12_30: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %int_3.loc12_33: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %int_4.loc12_36: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %.loc12_37.1: %tuple.type.d46 = tuple_literal (%int_1.loc12_27, %int_2.loc12_30, %int_3.loc12_33, %int_4.loc12_36) [concrete = constants.%tuple.d0e]
// CHECK:STDOUT:   %impl.elem0.loc12_37.1: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_37.1: <bound method> = bound_method %int_1.loc12_27, %impl.elem0.loc12_37.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc12_37.1: <specific function> = specific_function %impl.elem0.loc12_37.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc12_37.2: <bound method> = bound_method %int_1.loc12_27, %specific_fn.loc12_37.1 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_37.1: init %i32 = call %bound_method.loc12_37.2(%int_1.loc12_27) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc12_37.2: init %i32 = converted %int_1.loc12_27, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_37.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc12_37.3: ref %i32 = array_index %a.var, %int_0
// CHECK:STDOUT:   %.loc12_37.4: init %i32 to %.loc12_37.3 = in_place_init %.loc12_37.2 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %impl.elem0.loc12_37.2: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_37.3: <bound method> = bound_method %int_2.loc12_30, %impl.elem0.loc12_37.2 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc12_37.2: <specific function> = specific_function %impl.elem0.loc12_37.2, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc12_37.4: <bound method> = bound_method %int_2.loc12_30, %specific_fn.loc12_37.2 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_37.2: init %i32 = call %bound_method.loc12_37.4(%int_2.loc12_30) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc12_37.5: init %i32 = converted %int_2.loc12_30, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_37.2 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %int_1.loc12_37: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc12_37.6: ref %i32 = array_index %a.var, %int_1.loc12_37
// CHECK:STDOUT:   %.loc12_37.7: init %i32 to %.loc12_37.6 = in_place_init %.loc12_37.5 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %impl.elem0.loc12_37.3: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_37.5: <bound method> = bound_method %int_3.loc12_33, %impl.elem0.loc12_37.3 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc12_37.3: <specific function> = specific_function %impl.elem0.loc12_37.3, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc12_37.6: <bound method> = bound_method %int_3.loc12_33, %specific_fn.loc12_37.3 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_37.3: init %i32 = call %bound_method.loc12_37.6(%int_3.loc12_33) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc12_37.8: init %i32 = converted %int_3.loc12_33, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_37.3 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %int_2.loc12_37: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc12_37.9: ref %i32 = array_index %a.var, %int_2.loc12_37
// CHECK:STDOUT:   %.loc12_37.10: init %i32 to %.loc12_37.9 = in_place_init %.loc12_37.8 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %impl.elem0.loc12_37.4: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_37.7: <bound method> = bound_method %int_4.loc12_36, %impl.elem0.loc12_37.4 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.aad]
// CHECK:STDOUT:   %specific_fn.loc12_37.4: <specific function> = specific_function %impl.elem0.loc12_37.4, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc12_37.8: <bound method> = bound_method %int_4.loc12_36, %specific_fn.loc12_37.4 [concrete = constants.%bound_method.b7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_37.4: init %i32 = call %bound_method.loc12_37.8(%int_4.loc12_36) [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc12_37.11: init %i32 = converted %int_4.loc12_36, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_37.4 [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %int_3.loc12_37: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc12_37.12: ref %i32 = array_index %a.var, %int_3.loc12_37
// CHECK:STDOUT:   %.loc12_37.13: init %i32 to %.loc12_37.12 = in_place_init %.loc12_37.11 [concrete = constants.%int_4.4eb]
// CHECK:STDOUT:   %.loc12_37.14: init %array_type.88c to %a.var = array_init (%.loc12_37.4, %.loc12_37.7, %.loc12_37.10, %.loc12_37.13) [concrete = constants.%array]
// CHECK:STDOUT:   %.loc12_3: init %array_type.88c = converted %.loc12_37.1, %.loc12_37.14 [concrete = constants.%array]
// CHECK:STDOUT:   assign %a.var, %.loc12_3
// CHECK:STDOUT:   %.loc12_22: type = splice_block %array_type [concrete = constants.%array_type.88c] {
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %int_4.loc12_21: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:     %array_type: type = array_type %int_4.loc12_21, %i32.loc12 [concrete = constants.%array_type.88c]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %a: ref %array_type.88c = wrapper_binding a, %a.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.c6c = ref_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:     %a.var_patt: %pattern_type.c6c = var_pattern %a.patt [concrete = constants.%a.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ref.loc13_28: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Slice.ref.loc13_32: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %i32.loc13_39: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %facet_value.loc13_42: %facet_type.a1a = facet_value %i32.loc13_39, (constants.%Copy.impl_witness.b51, constants.%custom_witness.df9cc1.2) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc13_42: %facet_type.a1a = converted %i32.loc13_39, %facet_value.loc13_42 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %Slice.loc13_42: type = class_type @Slice, @Slice(constants.%facet_value) [concrete = constants.%Slice.8ee]
// CHECK:STDOUT:   %.loc13_43: %Slice.FromArray.type.784 = specific_constant imports.%Core.import_ref.38f, @Slice(constants.%facet_value) [concrete = constants.%Slice.FromArray.901]
// CHECK:STDOUT:   %FromArray.ref: %Slice.FromArray.type.784 = name_ref FromArray, %.loc13_43 [concrete = constants.%Slice.FromArray.901]
// CHECK:STDOUT:   %a.ref: ref %array_type.88c = name_ref a, %a
// CHECK:STDOUT:   %addr: %ptr.958 = addr_of %a.ref
// CHECK:STDOUT:   %facet_value.loc13_56.1: %facet_type.a1a = facet_value constants.%i32, (constants.%Copy.impl_witness.b51, constants.%custom_witness.df9cc1.2) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc13_56.1: %facet_type.a1a = converted constants.%i32, %facet_value.loc13_56.1 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %facet_value.loc13_56.2: %facet_type.a1a = facet_value constants.%i32, (constants.%Copy.impl_witness.b51, constants.%custom_witness.df9cc1.2) [concrete = constants.%facet_value]
// CHECK:STDOUT:   %.loc13_56.2: %facet_type.a1a = converted constants.%i32, %facet_value.loc13_56.2 [concrete = constants.%facet_value]
// CHECK:STDOUT:   %Slice.FromArray.specific_fn: <specific function> = specific_function %FromArray.ref, @Slice.FromArray(constants.%facet_value, constants.%int_4.0c1) [concrete = constants.%Slice.FromArray.specific_fn]
// CHECK:STDOUT:   %.loc13_56.3: ref %Slice.8ee = temporary_storage
// CHECK:STDOUT:   %Slice.FromArray.call: init %Slice.8ee to %.loc13_56.3 = call %Slice.FromArray.specific_fn(%addr)
// CHECK:STDOUT:   %.loc13_56.4: ref %Slice.8ee = temporary %.loc13_56.3, %Slice.FromArray.call
// CHECK:STDOUT:   %.loc13_56.5: %Slice.8ee = acquire_value %.loc13_56.4
// CHECK:STDOUT:   %.loc13_24.1: type = splice_block %Slice.loc13_24 [concrete = constants.%Slice.8ee] {
// CHECK:STDOUT:     %Core.ref.loc13_10: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Slice.ref.loc13_14: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:     %i32.loc13_21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %facet_value.loc13_24: %facet_type.a1a = facet_value %i32.loc13_21, (constants.%Copy.impl_witness.b51, constants.%custom_witness.df9cc1.2) [concrete = constants.%facet_value]
// CHECK:STDOUT:     %.loc13_24.2: %facet_type.a1a = converted %i32.loc13_21, %facet_value.loc13_24 [concrete = constants.%facet_value]
// CHECK:STDOUT:     %Slice.loc13_24: type = class_type @Slice, @Slice(constants.%facet_value) [concrete = constants.%Slice.8ee]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: %Slice.8ee = wrapper_binding s, %.loc13_56.5
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.095 = value_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s.ref: %Slice.8ee = name_ref s, %s
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc14_12.1: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:   %specific_fn.loc14_12: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc14_12.2: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14_12 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i64 = call %bound_method.loc14_12.2(%int_1.loc14) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc14_12.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc14_12.2: %i64 = converted %int_1.loc14, %.loc14_12.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %impl.elem1: %.88b = impl_witness_access constants.%IndexWith.impl_witness.2c7, element1 [concrete = constants.%Slice.as.IndexWith.impl.At.c7d]
// CHECK:STDOUT:   %bound_method.loc14_13.1: <bound method> = bound_method %s.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc14_13: <specific function> = specific_function %impl.elem1, @Slice.as.IndexWith.impl.At(constants.%facet_value) [concrete = constants.%Slice.as.IndexWith.impl.At.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_13.2: <bound method> = bound_method %s.ref, %specific_fn.loc14_13
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.call: init %i32 = call %bound_method.loc14_13.2(%s.ref, %.loc14_12.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc13: <bound method> = bound_method %.loc13_56.4, constants.%Destroy.Op.1a2547.7
// CHECK:STDOUT:   %Destroy.Op.call.loc13: init %empty_tuple.type = call %Destroy.Op.bound.loc13(%.loc13_56.4)
// CHECK:STDOUT:   %Destroy.Op.bound.loc12: <bound method> = bound_method %a.var, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call.loc12: init %empty_tuple.type = call %Destroy.Op.bound.loc12(%a.var)
// CHECK:STDOUT:   return %Slice.as.IndexWith.impl.At.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_24.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_24.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_56.1(%self.param: ref %ptr.d08) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_56.2(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_56.3(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_56.4(%self.param: ref %struct_type.ptr.size.0cc) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_56.5(%self.param: ref %Slice.8ee) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12(%self.param: ref %array_type.88c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- index_runtime_subscript.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %i.param_patt: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %i.patt: %pattern_type.f57 = wrapper_binding_pattern i, %i.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc8_23.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type = facet_value %i32, (%custom_witness.df9cc1.2, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Slice.33a: type = class_type @Slice, @Slice(%facet_value) [concrete]
// CHECK:STDOUT:   %pattern_type.d8a: type = pattern_type %Slice.33a [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.d8a = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %IndexWith.type.df6: type = generic_interface_type @IndexWith [concrete]
// CHECK:STDOUT:   %IndexWith.generic: %IndexWith.type.df6 = struct_value () [concrete]
// CHECK:STDOUT:   %IndexWith.type.3ea: type = facet_type <@IndexWith, @IndexWith(%i64)> [concrete]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.type.e30: type = fn_type @Slice.as.IndexWith.impl.At, @Slice.as.IndexWith.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.09b: %Slice.as.IndexWith.impl.At.type.e30 = struct_value () [symbolic]
// CHECK:STDOUT:   %IndexWith.impl_witness.2a6: <witness> = impl_witness imports.%IndexWith.impl_witness_table, @Slice.as.IndexWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.type.7ea: type = fn_type @Slice.as.IndexWith.impl.At, @Slice.as.IndexWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.e25: %Slice.as.IndexWith.impl.At.type.7ea = struct_value () [concrete]
// CHECK:STDOUT:   %IndexWith.facet: %IndexWith.type.3ea = facet_value %Slice.33a, (%IndexWith.impl_witness.2a6) [concrete]
// CHECK:STDOUT:   %IndexWith.WithSelf.At.type.7b7: type = fn_type @IndexWith.WithSelf.At, @IndexWith.WithSelf(%i64, %IndexWith.facet) [concrete]
// CHECK:STDOUT:   %.054: type = fn_type_with_self_type %IndexWith.WithSelf.At.type.7b7, %IndexWith.facet [concrete]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.specific_fn: <specific function> = specific_function %Slice.as.IndexWith.impl.At.e25, @Slice.as.IndexWith.impl.At(%facet_value) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .IndexWith = %Core.IndexWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.IndexWith: %IndexWith.type.df6 = import_ref Core//prelude/operators/index, IndexWith, loaded [concrete = constants.%IndexWith.generic]
// CHECK:STDOUT:   %Core.import_ref.ef4 = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.868: @Slice.as.IndexWith.impl.%Slice.as.IndexWith.impl.At.type (%Slice.as.IndexWith.impl.At.type.e30) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.IndexWith.impl.%Slice.as.IndexWith.impl.At (constants.%Slice.as.IndexWith.impl.At.09b)]
// CHECK:STDOUT:   %IndexWith.impl_witness_table = impl_witness_table (%Core.import_ref.ef4, %Core.import_ref.868), @Slice.as.IndexWith.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.d8a = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %i.param_patt: %pattern_type.f57 = value_param_pattern [concrete = constants.%i.param_patt]
// CHECK:STDOUT:     %i.patt: %pattern_type.f57 = wrapper_binding_pattern i, %i.param_patt [concrete = constants.%i.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_37 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8_37: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_37: Core.Form = init_form %i32.loc8_37 [concrete = constants.%.795f]
// CHECK:STDOUT:     %s.param: %Slice.33a = value_param call_param0
// CHECK:STDOUT:     %.loc8_23.1: type = splice_block %Slice [concrete = constants.%Slice.33a] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:       %i32.loc8_20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %facet_value: %facet_type = facet_value %i32.loc8_20, (constants.%custom_witness.df9cc1.2, constants.%Copy.impl_witness.b51) [concrete = constants.%facet_value]
// CHECK:STDOUT:       %.loc8_23.2: %facet_type = converted %i32.loc8_20, %facet_value [concrete = constants.%facet_value]
// CHECK:STDOUT:       %Slice: type = class_type @Slice, @Slice(constants.%facet_value) [concrete = constants.%Slice.33a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: %Slice.33a = wrapper_binding s, %s.param
// CHECK:STDOUT:     %i.param: %i64 = value_param call_param1
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %i: %i64 = wrapper_binding i, %i.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc8_23.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc8_23.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G(%s.param: %Slice.33a, %i.param: %i64) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.ref: %Slice.33a = name_ref s, %s
// CHECK:STDOUT:   %i.ref: %i64 = name_ref i, %i
// CHECK:STDOUT:   %impl.elem1: %.054 = impl_witness_access constants.%IndexWith.impl_witness.2a6, element1 [concrete = constants.%Slice.as.IndexWith.impl.At.e25]
// CHECK:STDOUT:   %bound_method.loc9_13.1: <bound method> = bound_method %s.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem1, @Slice.as.IndexWith.impl.At(constants.%facet_value) [concrete = constants.%Slice.as.IndexWith.impl.At.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_13.2: <bound method> = bound_method %s.ref, %specific_fn
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.call: init %i32 = call %bound_method.loc9_13.2(%s.ref, %i.ref)
// CHECK:STDOUT:   return %Slice.as.IndexWith.impl.At.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- subslice_and_size.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type.f48 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Slice.Subslice.type.63e: type = fn_type @Slice.Subslice, @Slice(%T.283) [symbolic]
// CHECK:STDOUT:   %Slice.Subslice.63a: %Slice.Subslice.type.63e = struct_value () [symbolic]
// CHECK:STDOUT:   %Slice.Size.type.45f: type = fn_type @Slice.Size, @Slice(%T.283) [symbolic]
// CHECK:STDOUT:   %Slice.Size.1c7: %Slice.Size.type.45f = struct_value () [symbolic]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.227: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc5_23.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.f48 = facet_value %i32, (%custom_witness.df9cc1.2, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Slice.33a: type = class_type @Slice, @Slice(%facet_value) [concrete]
// CHECK:STDOUT:   %pattern_type.d8a: type = pattern_type %Slice.33a [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.d8a = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %H.type: type = fn_type @H [concrete]
// CHECK:STDOUT:   %H: %H.type = struct_value () [concrete]
// CHECK:STDOUT:   %Slice.Size.type.d4a: type = fn_type @Slice.Size, @Slice(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.Size.e1d: %Slice.Size.type.d4a = struct_value () [concrete]
// CHECK:STDOUT:   %Slice.Subslice.type.f45: type = fn_type @Slice.Subslice, @Slice(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.Subslice.4c2: %Slice.Subslice.type.f45 = struct_value () [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %struct_type.ptr.size.0cc: type = struct_type {.ptr: %ptr.d08, .size: %i64} [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Slice.Subslice.specific_fn: <specific function> = specific_function %Slice.Subslice.4c2, @Slice.Subslice(%facet_value) [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.c5e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.740: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.bd2: %i64 = int_value 3 [concrete]
// CHECK:STDOUT:   %Slice.Size.specific_fn: <specific function> = specific_function %Slice.Size.e1d, @Slice.Size(%facet_value) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.7: type = fn_type @Destroy.Op.loc6_25.5 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.7: %Destroy.Op.type.1d8f74.7 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.import_ref.717: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/slice, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.717), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b6e: @Slice.%Slice.Size.type (%Slice.Size.type.45f) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.%Slice.Size (constants.%Slice.Size.1c7)]
// CHECK:STDOUT:   %Core.import_ref.eb2: @Slice.%Slice.Subslice.type (%Slice.Subslice.type.63e) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.%Slice.Subslice (constants.%Slice.Subslice.63a)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %H.decl: %H.type = fn_decl @H [concrete = constants.%H] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.d8a = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc5_29: Core.Form = init_form %i64 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %s.param: %Slice.33a = value_param call_param0
// CHECK:STDOUT:     %.loc5_23.1: type = splice_block %Slice [concrete = constants.%Slice.33a] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %facet_value: %facet_type.f48 = facet_value %i32, (constants.%custom_witness.df9cc1.2, constants.%Copy.impl_witness.b51) [concrete = constants.%facet_value]
// CHECK:STDOUT:       %.loc5_23.2: %facet_type.f48 = converted %i32, %facet_value [concrete = constants.%facet_value]
// CHECK:STDOUT:       %Slice: type = class_type @Slice, @Slice(constants.%facet_value) [concrete = constants.%Slice.33a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: %Slice.33a = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_23.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_23.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @H(%s.param: %Slice.33a) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.ref: %Slice.33a = name_ref s, %s
// CHECK:STDOUT:   %.loc6_11: %Slice.Subslice.type.f45 = specific_constant imports.%Core.import_ref.eb2, @Slice(constants.%facet_value) [concrete = constants.%Slice.Subslice.4c2]
// CHECK:STDOUT:   %Subslice.ref: %Slice.Subslice.type.f45 = name_ref Subslice, %.loc6_11 [concrete = constants.%Slice.Subslice.4c2]
// CHECK:STDOUT:   %Slice.Subslice.bound: <bound method> = bound_method %s.ref, %Subslice.ref
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %Slice.Subslice.specific_fn: <specific function> = specific_function %Subslice.ref, @Slice.Subslice(constants.%facet_value) [concrete = constants.%Slice.Subslice.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_25: <bound method> = bound_method %s.ref, %Slice.Subslice.specific_fn
// CHECK:STDOUT:   %.loc6_25.1: ref %Slice.33a = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc6_21: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc6_21.1: <bound method> = bound_method %int_1, %impl.elem0.loc6_21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:   %specific_fn.loc6_21: <specific function> = specific_function %impl.elem0.loc6_21, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_21.2: <bound method> = bound_method %int_1, %specific_fn.loc6_21 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_21: init %i64 = call %bound_method.loc6_21.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc6_21.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_21 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc6_21.2: %i64 = converted %int_1, %.loc6_21.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %impl.elem0.loc6_24: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc6_24.1: <bound method> = bound_method %int_3, %impl.elem0.loc6_24 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c]
// CHECK:STDOUT:   %specific_fn.loc6_24: <specific function> = specific_function %impl.elem0.loc6_24, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_24.2: <bound method> = bound_method %int_3, %specific_fn.loc6_24 [concrete = constants.%bound_method.740]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_24: init %i64 = call %bound_method.loc6_24.2(%int_3) [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc6_24.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6_24 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc6_24.2: %i64 = converted %int_3, %.loc6_24.1 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %Slice.Subslice.call: init %Slice.33a to %.loc6_25.1 = call %bound_method.loc6_25(%s.ref, %.loc6_21.2, %.loc6_24.2)
// CHECK:STDOUT:   %.loc6_25.2: ref %Slice.33a = temporary %.loc6_25.1, %Slice.Subslice.call
// CHECK:STDOUT:   %.loc6_26: %Slice.Size.type.d4a = specific_constant imports.%Core.import_ref.b6e, @Slice(constants.%facet_value) [concrete = constants.%Slice.Size.e1d]
// CHECK:STDOUT:   %Size.ref: %Slice.Size.type.d4a = name_ref Size, %.loc6_26 [concrete = constants.%Slice.Size.e1d]
// CHECK:STDOUT:   %Slice.Size.bound: <bound method> = bound_method %.loc6_25.2, %Size.ref
// CHECK:STDOUT:   %Slice.Size.specific_fn: <specific function> = specific_function %Size.ref, @Slice.Size(constants.%facet_value) [concrete = constants.%Slice.Size.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_32: <bound method> = bound_method %.loc6_25.2, %Slice.Size.specific_fn
// CHECK:STDOUT:   %.loc6_25.3: %Slice.33a = acquire_value %.loc6_25.2
// CHECK:STDOUT:   %Slice.Size.call: init %i64 = call %bound_method.loc6_32(%.loc6_25.3)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %.loc6_25.2, constants.%Destroy.Op.1a2547.7
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%.loc6_25.2)
// CHECK:STDOUT:   return %Slice.Size.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_25.1(%self.param: ref %ptr.d08) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_25.2(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_25.3(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_25.4(%self.param: ref %struct_type.ptr.size.0cc) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc6_25.5(%self.param: ref %Slice.33a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- const_view.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type.f48 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc7_23.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value.53d: %facet_type.f48 = facet_value %i32, (%custom_witness.df9cc1.2, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Slice.33a: type = class_type @Slice, @Slice(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %pattern_type.d8a: type = pattern_type %Slice.33a [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.d8a = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.loc7_49 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.3: %Destroy.Op.type.1d8f74.3 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.3: <witness> = custom_witness (%Destroy.Op.1a2547.3), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.ae2: <witness> = impl_witness imports.%Copy.impl_witness_table.aca, @const.as.Copy.impl(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %facet_value.d9e: %facet_type.f48 = facet_value %const.6a8, (%custom_witness.df9cc1.3, %Copy.impl_witness.ae2) [concrete]
// CHECK:STDOUT:   %Slice.2ea: type = class_type @Slice, @Slice(%facet_value.d9e) [concrete]
// CHECK:STDOUT:   %.3e4: Core.Form = init_form %Slice.2ea [concrete]
// CHECK:STDOUT:   %pattern_type.86d: type = pattern_type %Slice.2ea [concrete]
// CHECK:STDOUT:   %return.param_patt.22d: %pattern_type.86d = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.658: %pattern_type.86d = return_slot_pattern %return.param_patt.22d, %Slice.2ea [concrete]
// CHECK:STDOUT:   %K.type: type = fn_type @K [concrete]
// CHECK:STDOUT:   %K: %K.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.8bf: type = facet_type <@ImplicitAs, @ImplicitAs(%Slice.2ea)> [concrete]
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.type.d49: type = fn_type @Slice.as.ImplicitAs.impl.Convert, @Slice.as.ImplicitAs.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.ac0: %Slice.as.ImplicitAs.impl.Convert.type.d49 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.2c1: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.e76, @Slice.as.ImplicitAs.impl(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.type.623: type = fn_type @Slice.as.ImplicitAs.impl.Convert, @Slice.as.ImplicitAs.impl(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.8a4: %Slice.as.ImplicitAs.impl.Convert.type.623 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.8bf = facet_value %Slice.33a, (%ImplicitAs.impl_witness.2c1) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.65d: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%Slice.2ea, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.29a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.65d, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Slice.as.ImplicitAs.impl.Convert.8a4, @Slice.as.ImplicitAs.impl.Convert(%facet_value.53d) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.94c = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.aca = impl_witness_table (%Core.import_ref.94c), @const.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.9a4: @Slice.as.ImplicitAs.impl.%Slice.as.ImplicitAs.impl.Convert.type (%Slice.as.ImplicitAs.impl.Convert.type.d49) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.ImplicitAs.impl.%Slice.as.ImplicitAs.impl.Convert (constants.%Slice.as.ImplicitAs.impl.Convert.ac0)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.e76 = impl_witness_table (%Core.import_ref.9a4), @Slice.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %K.decl: %K.type = fn_decl @K [concrete = constants.%K] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.d8a = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.86d = out_param_pattern [concrete = constants.%return.param_patt.22d]
// CHECK:STDOUT:     %return.patt: %pattern_type.86d = return_slot_pattern %return.param_patt, %Slice.loc7_49 [concrete = constants.%return.patt.658]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc7_29: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Slice.ref.loc7_33: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:     %i32.loc7_46: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %const: type = const_type %i32.loc7_46 [concrete = constants.%const.6a8]
// CHECK:STDOUT:     %facet_value.loc7_49: %facet_type.f48 = facet_value %const, (constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2) [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %.loc7_49.2: %facet_type.f48 = converted %const, %facet_value.loc7_49 [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %Slice.loc7_49: type = class_type @Slice, @Slice(constants.%facet_value.d9e) [concrete = constants.%Slice.2ea]
// CHECK:STDOUT:     %.loc7_49.3: Core.Form = init_form %Slice.loc7_49 [concrete = constants.%.3e4]
// CHECK:STDOUT:     %s.param: %Slice.33a = value_param call_param0
// CHECK:STDOUT:     %.loc7_23.1: type = splice_block %Slice.loc7_23 [concrete = constants.%Slice.33a] {
// CHECK:STDOUT:       %Core.ref.loc7_9: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Slice.ref.loc7_13: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:       %i32.loc7_20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %facet_value.loc7_23: %facet_type.f48 = facet_value %i32.loc7_20, (constants.%custom_witness.df9cc1.2, constants.%Copy.impl_witness.b51) [concrete = constants.%facet_value.53d]
// CHECK:STDOUT:       %.loc7_23.2: %facet_type.f48 = converted %i32.loc7_20, %facet_value.loc7_23 [concrete = constants.%facet_value.53d]
// CHECK:STDOUT:       %Slice.loc7_23: type = class_type @Slice, @Slice(constants.%facet_value.53d) [concrete = constants.%Slice.33a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: %Slice.33a = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref %Slice.2ea = out_param call_param1
// CHECK:STDOUT:     %return: ref %Slice.2ea = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc7_23.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc7_23.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc7_49(%self.param: ref %const.6a8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @K(%s.param: %Slice.33a) -> out %return.param: %Slice.2ea {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.ref: %Slice.33a = name_ref s, %s
// CHECK:STDOUT:   %impl.elem0: %.29a = impl_witness_access constants.%ImplicitAs.impl_witness.2c1, element0 [concrete = constants.%Slice.as.ImplicitAs.impl.Convert.8a4]
// CHECK:STDOUT:   %bound_method.loc8_11.1: <bound method> = bound_method %s.ref, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Slice.as.ImplicitAs.impl.Convert(constants.%facet_value.53d) [concrete = constants.%Slice.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_11.2: <bound method> = bound_method %s.ref, %specific_fn
// CHECK:STDOUT:   %.loc7_49.1: ref %Slice.2ea = splice_block %return.param {}
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.call: init %Slice.2ea to %.loc7_49.1 = call %bound_method.loc8_11.2(%s.ref)
// CHECK:STDOUT:   %.loc8: init %Slice.2ea = converted %s.ref, %Slice.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   return %.loc8 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- iterate.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N.fe9) [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type.f48 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.2: type = class_type @Int, @Int(%To) [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc7_25.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %facet_value.53d: %facet_type.f48 = facet_value %i32, (%custom_witness.df9cc1.2, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Slice.33a: type = class_type @Slice, @Slice(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %pattern_type.d8a: type = pattern_type %Slice.33a [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.d8a = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Sum.type: type = fn_type @Sum [concrete]
// CHECK:STDOUT:   %Sum: %Sum.type = struct_value () [concrete]
// CHECK:STDOUT:   %t.patt: %pattern_type.6b6 = ref_binding_pattern t [concrete]
// CHECK:STDOUT:   %t.var_patt: %pattern_type.6b6 = var_pattern %t.patt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %facet_type.037: type = facet_type <@IntFitsIn, @IntFitsIn(%Int.67af24.2) & @AnyInt> [symbolic]
// CHECK:STDOUT:   %From.6a4: %facet_type.037 = symbolic_binding From, 1 [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7fa: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%To, %From.6a4) [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.643: %From.as_type.as.ImplicitAs.impl.Convert.type.7fa = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %Iterate.type: type = facet_type <@Iterate> [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.Get.type.bb9: type = fn_type @Optional.Get, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.Get.fa1: %Optional.Get.type.bb9 = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.type.e9e: type = fn_type @Optional.HasValue, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.6cd: %Optional.HasValue.type.e9e = struct_value () [symbolic]
// CHECK:STDOUT:   %DefaultOptionalStorage.d50: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.type.a12: type = fn_type @T.as_type.as.OptionalStorage.impl.Get, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Get.d32: %T.as_type.as.OptionalStorage.impl.Get.type.a12 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.type.e5a: type = fn_type @T.as_type.as.OptionalStorage.impl.Has, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Has.4ee: %T.as_type.as.OptionalStorage.impl.Has.type.e5a = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Some.type.492: type = fn_type @T.as_type.as.OptionalStorage.impl.Some, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.Some.89a: %T.as_type.as.OptionalStorage.impl.Some.type.492 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.None.type.0a1: type = fn_type @T.as_type.as.OptionalStorage.impl.None, @T.as_type.as.OptionalStorage.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalStorage.impl.None.e06: %T.as_type.as.OptionalStorage.impl.None.type.0a1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.Next.type.93f: type = fn_type @Slice.as.Iterate.impl.Next, @Slice.as.Iterate.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.Next.da5: %Slice.as.Iterate.impl.Next.type.93f = struct_value () [symbolic]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.NewCursor.type.5f1: type = fn_type @Slice.as.Iterate.impl.NewCursor, @Slice.as.Iterate.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.NewCursor.322: %Slice.as.Iterate.impl.NewCursor.type.5f1 = struct_value () [symbolic]
// CHECK:STDOUT:   %ptr.643: type = ptr_type %i64 [concrete]
// CHECK:STDOUT:   %Iterate.impl_witness.42c: <witness> = impl_witness imports.%Iterate.impl_witness_table.d36, @Slice.as.Iterate.impl(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.NewCursor.type.df1: type = fn_type @Slice.as.Iterate.impl.NewCursor, @Slice.as.Iterate.impl(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.NewCursor.f88: %Slice.as.Iterate.impl.NewCursor.type.df1 = struct_value () [concrete]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.Next.type.440: type = fn_type @Slice.as.Iterate.impl.Next, @Slice.as.Iterate.impl(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.Next.43b: %Slice.as.Iterate.impl.Next.type.440 = struct_value () [concrete]
// CHECK:STDOUT:   %Iterate.facet.641: %Iterate.type = facet_value %Slice.33a, (%Iterate.impl_witness.42c) [concrete]
// CHECK:STDOUT:   %Iterate.WithSelf.NewCursor.type.e0d: type = fn_type @Iterate.WithSelf.NewCursor, @Iterate.WithSelf(%Iterate.facet.641) [concrete]
// CHECK:STDOUT:   %Iterate.WithSelf.Next.type.155: type = fn_type @Iterate.WithSelf.Next, @Iterate.WithSelf(%Iterate.facet.641) [concrete]
// CHECK:STDOUT:   %.a41: type = fn_type_with_self_type %Iterate.WithSelf.NewCursor.type.e0d, %Iterate.facet.641 [concrete]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.NewCursor.specific_fn: <specific function> = specific_function %Slice.as.Iterate.impl.NewCursor.f88, @Slice.as.Iterate.impl.NewCursor(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %.b8f: type = fn_type_with_self_type %Iterate.WithSelf.Next.type.155, %Iterate.facet.641 [concrete]
// CHECK:STDOUT:   %DefaultOptionalStorage.bfa: type = class_type @DefaultOptionalStorage, @DefaultOptionalStorage(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.c8c: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.460, @T.as_type.as.OptionalStorage.impl(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.097: %OptionalStorage.type = facet_value %i32, (%OptionalStorage.impl_witness.c8c) [concrete]
// CHECK:STDOUT:   %Optional.755: type = class_type @Optional, @Optional(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %Slice.as.Iterate.impl.Next.specific_fn: <specific function> = specific_function %Slice.as.Iterate.impl.Next.43b, @Slice.as.Iterate.impl.Next(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %Optional.HasValue.type.af3: type = fn_type @Optional.HasValue, @Optional(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %Optional.HasValue.4f6: %Optional.HasValue.type.af3 = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.Get.type.336: type = fn_type @Optional.Get, @Optional(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %Optional.Get.0a8: %Optional.Get.type.336 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.facet.d07318.2: %Destroy.type = facet_value %i32, (%custom_witness.df9cc1.2) [concrete]
// CHECK:STDOUT:   %MaybeUnformed.023: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.d07318.2) [concrete]
// CHECK:STDOUT:   %.1d6: type = maybe_unformed_type %i32 [concrete]
// CHECK:STDOUT:   %struct_type.value.has_value.ad0: type = struct_type {.value: %MaybeUnformed.023, .has_value: bool} [concrete]
// CHECK:STDOUT:   %Optional.HasValue.specific_fn: <specific function> = specific_function %Optional.HasValue.4f6, @Optional.HasValue(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %Optional.Get.specific_fn: <specific function> = specific_function %Optional.Get.0a8, @Optional.Get(%OptionalStorage.facet.097) [concrete]
// CHECK:STDOUT:   %AddAssignWith.type.2fb: type = generic_interface_type @AddAssignWith [concrete]
// CHECK:STDOUT:   %AddAssignWith.generic: %AddAssignWith.type.2fb = struct_value () [concrete]
// CHECK:STDOUT:   %AddAssignWith.type.941: type = facet_type <@AddAssignWith, @AddAssignWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.type.a58fbe.1: type = fn_type @Int.as.AddAssignWith.impl.Op.1, @Int.as.AddAssignWith.impl(%N.fe9, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.45b360.1: %Int.as.AddAssignWith.impl.Op.type.a58fbe.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.type.a58fbe.2: type = fn_type @Int.as.AddAssignWith.impl.Op.2, @Int.as.AddAssignWith.impl(%N.fe9, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.45b360.2: %Int.as.AddAssignWith.impl.Op.type.a58fbe.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.138: type = facet_type <@IntFitsIn, @IntFitsIn(%i32) & @AnyInt> [concrete]
// CHECK:STDOUT:   %custom_witness.36a: <witness> = custom_witness (), @IntFitsIn, @IntFitsIn(%i32) [concrete]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.type.f15: type = fn_type @Int.as.AnyInt.impl.AsInt, @Int.as.AnyInt.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.d10: %Int.as.AnyInt.impl.AsInt.type.f15 = struct_value () [symbolic]
// CHECK:STDOUT:   %AnyInt.impl_witness.48c: <witness> = impl_witness imports.%AnyInt.impl_witness_table, @Int.as.AnyInt.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value.cd1: %facet_type.138 = facet_value %i32, (%custom_witness.36a, %AnyInt.impl_witness.48c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.1d8: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.992, @From.as_type.as.ImplicitAs.impl(%int_32, %facet_value.cd1) [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.e88: %ImplicitAs.type.914 = facet_value %i32, (%ImplicitAs.impl_witness.1d8) [concrete]
// CHECK:STDOUT:   %AddAssignWith.impl_witness.e9d: <witness> = impl_witness imports.%AddAssignWith.impl_witness_table, @Int.as.AddAssignWith.impl(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.type.0b80aa.1: type = fn_type @Int.as.AddAssignWith.impl.Op.2, @Int.as.AddAssignWith.impl(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.d34738.1: %Int.as.AddAssignWith.impl.Op.type.0b80aa.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.type.0b80aa.2: type = fn_type @Int.as.AddAssignWith.impl.Op.1, @Int.as.AddAssignWith.impl(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.d34738.2: %Int.as.AddAssignWith.impl.Op.type.0b80aa.2 = struct_value () [concrete]
// CHECK:STDOUT:   %AddAssignWith.facet.e5e: %AddAssignWith.type.941 = facet_value %i32, (%AddAssignWith.impl_witness.e9d) [concrete]
// CHECK:STDOUT:   %AddAssignWith.WithSelf.Op.type.640: type = fn_type @AddAssignWith.WithSelf.Op, @AddAssignWith.WithSelf(%i32, %AddAssignWith.facet.e5e) [concrete]
// CHECK:STDOUT:   %.004: type = fn_type_with_self_type %AddAssignWith.WithSelf.Op.type.640, %AddAssignWith.facet.e5e [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.specific_fn.d76216.1: <specific function> = specific_function %Int.as.AddAssignWith.impl.Op.d34738.2, @Int.as.AddAssignWith.impl.Op.1(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.specific_fn.d76216.2: <specific function> = specific_function %Int.as.AddAssignWith.impl.Op.d34738.1, @Int.as.AddAssignWith.impl.Op.2(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.10: type = fn_type @Destroy.Op.loc9_19.6 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.10: %Destroy.Op.type.1d8f74.10 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.12: type = fn_type @Destroy.Op.loc9_19.8 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.12: %Destroy.Op.type.1d8f74.12 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Iterate = %Core.Iterate
// CHECK:STDOUT:     .AddAssignWith = %Core.AddAssignWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.import_ref.717: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/slice, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.717), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.2a4: @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert.type (%From.as_type.as.ImplicitAs.impl.Convert.type.7fa) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert (constants.%From.as_type.as.ImplicitAs.impl.Convert.643)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.992 = impl_witness_table (%Core.import_ref.2a4), @From.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.Iterate: type = import_ref Core//prelude/iterate, Iterate, loaded [concrete = constants.%Iterate.type]
// CHECK:STDOUT:   %Core.import_ref.bb6: @Optional.%Optional.HasValue.type (%Optional.HasValue.type.e9e) = import_ref Core//prelude/iterate, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Optional.%Optional.HasValue (constants.%Optional.HasValue.6cd)]
// CHECK:STDOUT:   %Core.import_ref.dab: @Optional.%Optional.Get.type (%Optional.Get.type.bb9) = import_ref Core//prelude/iterate, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Optional.%Optional.Get (constants.%Optional.Get.fa1)]
// CHECK:STDOUT:   %Core.import_ref.0c6: type = import_ref Core//prelude/iterate, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%DefaultOptionalStorage (constants.%DefaultOptionalStorage.d50)]
// CHECK:STDOUT:   %Core.import_ref.dc3: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.None.type (%T.as_type.as.OptionalStorage.impl.None.type.0a1) = import_ref Core//prelude/iterate, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.None (constants.%T.as_type.as.OptionalStorage.impl.None.e06)]
// CHECK:STDOUT:   %Core.import_ref.c53: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Some.type (%T.as_type.as.OptionalStorage.impl.Some.type.492) = import_ref Core//prelude/iterate, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Some (constants.%T.as_type.as.OptionalStorage.impl.Some.89a)]
// CHECK:STDOUT:   %Core.import_ref.ed4: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has.type (%T.as_type.as.OptionalStorage.impl.Has.type.e5a) = import_ref Core//prelude/iterate, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Has (constants.%T.as_type.as.OptionalStorage.impl.Has.4ee)]
// CHECK:STDOUT:   %Core.import_ref.e9c: @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get.type (%T.as_type.as.OptionalStorage.impl.Get.type.a12) = import_ref Core//prelude/iterate, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @T.as_type.as.OptionalStorage.impl.%T.as_type.as.OptionalStorage.impl.Get (constants.%T.as_type.as.OptionalStorage.impl.Get.d32)]
// CHECK:STDOUT:   %Core.import_ref.0b2 = import_ref Core//prelude/iterate, inst{{[0-9A-F]+}} [indirect], unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.460 = impl_witness_table (%Core.import_ref.0c6, %Core.import_ref.dc3, %Core.import_ref.c53, %Core.import_ref.ed4, %Core.import_ref.e9c, %Core.import_ref.0b2), @T.as_type.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.9a513d.2 = import_ref Core//prelude/iterate, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.ffe = import_ref Core//prelude/iterate, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.2b1: @Slice.as.Iterate.impl.%Slice.as.Iterate.impl.NewCursor.type (%Slice.as.Iterate.impl.NewCursor.type.5f1) = import_ref Core//prelude/iterate, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.Iterate.impl.%Slice.as.Iterate.impl.NewCursor (constants.%Slice.as.Iterate.impl.NewCursor.322)]
// CHECK:STDOUT:   %Core.import_ref.6c6: @Slice.as.Iterate.impl.%Slice.as.Iterate.impl.Next.type (%Slice.as.Iterate.impl.Next.type.93f) = import_ref Core//prelude/iterate, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.Iterate.impl.%Slice.as.Iterate.impl.Next (constants.%Slice.as.Iterate.impl.Next.da5)]
// CHECK:STDOUT:   %Iterate.impl_witness_table.d36 = impl_witness_table (%Core.import_ref.9a513d.2, %Core.import_ref.ffe, %Core.import_ref.2b1, %Core.import_ref.6c6), @Slice.as.Iterate.impl [concrete]
// CHECK:STDOUT:   %Core.AddAssignWith: %AddAssignWith.type.2fb = import_ref Core//prelude/operators/arithmetic, AddAssignWith, loaded [concrete = constants.%AddAssignWith.generic]
// CHECK:STDOUT:   %Core.import_ref.098: @Int.as.AddAssignWith.impl.%Int.as.AddAssignWith.impl.Op.type.2 (%Int.as.AddAssignWith.impl.Op.type.a58fbe.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddAssignWith.impl.%Int.as.AddAssignWith.impl.Op.2 (constants.%Int.as.AddAssignWith.impl.Op.45b360.1)]
// CHECK:STDOUT:   %AddAssignWith.impl_witness_table = impl_witness_table (%Core.import_ref.098), @Int.as.AddAssignWith.impl [concrete]
// CHECK:STDOUT:   %Core.Op.1b1: @Int.as.AddAssignWith.impl.%Int.as.AddAssignWith.impl.Op.type.1 (%Int.as.AddAssignWith.impl.Op.type.a58fbe.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddAssignWith.impl.%Int.as.AddAssignWith.impl.Op.1 (constants.%Int.as.AddAssignWith.impl.Op.45b360.2)]
// CHECK:STDOUT:   %Core.import_ref.47b: Core.IntLiteral = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%N (constants.%N.fe9)]
// CHECK:STDOUT:   %Core.import_ref.49b: @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt.type (%Int.as.AnyInt.impl.AsInt.type.f15) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt (constants.%Int.as.AnyInt.impl.AsInt.d10)]
// CHECK:STDOUT:   %AnyInt.impl_witness_table = impl_witness_table (%Core.import_ref.47b, %Core.import_ref.49b), @Int.as.AnyInt.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Sum.decl: %Sum.type = fn_decl @Sum [concrete = constants.%Sum] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.d8a = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc7_31 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc7_31: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc7_31: Core.Form = init_form %i32.loc7_31 [concrete = constants.%.795f]
// CHECK:STDOUT:     %s.param: %Slice.33a = value_param call_param0
// CHECK:STDOUT:     %.loc7_25.1: type = splice_block %Slice [concrete = constants.%Slice.33a] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:       %i32.loc7_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %facet_value: %facet_type.f48 = facet_value %i32.loc7_22, (constants.%custom_witness.df9cc1.2, constants.%Copy.impl_witness.b51) [concrete = constants.%facet_value.53d]
// CHECK:STDOUT:       %.loc7_25.2: %facet_type.f48 = converted %i32.loc7_22, %facet_value [concrete = constants.%facet_value.53d]
// CHECK:STDOUT:       %Slice: type = class_type @Slice, @Slice(constants.%facet_value.53d) [concrete = constants.%Slice.33a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: %Slice.33a = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc7_25.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc7_25.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Sum(%s.param: %Slice.33a) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.var: ref %i32 = var_storage %t.var_patt
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc8: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_3.1: <bound method> = bound_method %int_0, %impl.elem0.loc8 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc8_3.2: <bound method> = bound_method %int_0, %specific_fn.loc8 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc8_3.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc8: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   assign %t.var, %.loc8
// CHECK:STDOUT:   %i32.loc8: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %t: ref %i32 = wrapper_binding t, %t.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %t.patt: %pattern_type.6b6 = ref_binding_pattern t [concrete = constants.%t.patt]
// CHECK:STDOUT:     %t.var_patt: %pattern_type.6b6 = var_pattern %t.patt [concrete = constants.%t.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete = constants.%x.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s.ref: %Slice.33a = name_ref s, %s
// CHECK:STDOUT:   %impl.elem2: %.a41 = impl_witness_access constants.%Iterate.impl_witness.42c, element2 [concrete = constants.%Slice.as.Iterate.impl.NewCursor.f88]
// CHECK:STDOUT:   %bound_method.loc9_19.1: <bound method> = bound_method %s.ref, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc9_19.1: <specific function> = specific_function %impl.elem2, @Slice.as.Iterate.impl.NewCursor(constants.%facet_value.53d) [concrete = constants.%Slice.as.Iterate.impl.NewCursor.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_19.2: <bound method> = bound_method %s.ref, %specific_fn.loc9_19.1
// CHECK:STDOUT:   %Slice.as.Iterate.impl.NewCursor.call: init %i64 = call %bound_method.loc9_19.2(%s.ref)
// CHECK:STDOUT:   %var: ref %i64 = var_storage invalid
// CHECK:STDOUT:   assign %var, %Slice.as.Iterate.impl.NewCursor.call
// CHECK:STDOUT:   br !for.next
// CHECK:STDOUT:
// CHECK:STDOUT: !for.next:
// CHECK:STDOUT:   %addr: %ptr.643 = addr_of %var
// CHECK:STDOUT:   %impl.elem3: %.b8f = impl_witness_access constants.%Iterate.impl_witness.42c, element3 [concrete = constants.%Slice.as.Iterate.impl.Next.43b]
// CHECK:STDOUT:   %bound_method.loc9_19.3: <bound method> = bound_method %s.ref, %impl.elem3
// CHECK:STDOUT:   %specific_fn.loc9_19.2: <specific function> = specific_function %impl.elem3, @Slice.as.Iterate.impl.Next(constants.%facet_value.53d) [concrete = constants.%Slice.as.Iterate.impl.Next.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_19.4: <bound method> = bound_method %s.ref, %specific_fn.loc9_19.2
// CHECK:STDOUT:   %.loc9_19.1: ref %Optional.755 = temporary_storage
// CHECK:STDOUT:   %Slice.as.Iterate.impl.Next.call: init %Optional.755 to %.loc9_19.1 = call %bound_method.loc9_19.4(%s.ref, %addr)
// CHECK:STDOUT:   %.loc9_19.2: ref %Optional.755 = temporary %.loc9_19.1, %Slice.as.Iterate.impl.Next.call
// CHECK:STDOUT:   %.loc9_19.3: %Optional.HasValue.type.af3 = specific_constant imports.%Core.import_ref.bb6, @Optional(constants.%OptionalStorage.facet.097) [concrete = constants.%Optional.HasValue.4f6]
// CHECK:STDOUT:   %HasValue.ref: %Optional.HasValue.type.af3 = name_ref HasValue, %.loc9_19.3 [concrete = constants.%Optional.HasValue.4f6]
// CHECK:STDOUT:   %Optional.HasValue.bound: <bound method> = bound_method %.loc9_19.2, %HasValue.ref
// CHECK:STDOUT:   %Optional.HasValue.specific_fn: <specific function> = specific_function %HasValue.ref, @Optional.HasValue(constants.%OptionalStorage.facet.097) [concrete = constants.%Optional.HasValue.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_19.5: <bound method> = bound_method %.loc9_19.2, %Optional.HasValue.specific_fn
// CHECK:STDOUT:   %.loc9_19.4: %Optional.755 = acquire_value %.loc9_19.2
// CHECK:STDOUT:   %Optional.HasValue.call: init bool = call %bound_method.loc9_19.5(%.loc9_19.4)
// CHECK:STDOUT:   %.loc9_19.5: bool = value_of_initializer %Optional.HasValue.call
// CHECK:STDOUT:   %.loc9_19.6: bool = converted %Optional.HasValue.call, %.loc9_19.5
// CHECK:STDOUT:   if %.loc9_19.6 br !for.body else br !for.done
// CHECK:STDOUT:
// CHECK:STDOUT: !for.body:
// CHECK:STDOUT:   %.loc9_19.7: %Optional.Get.type.336 = specific_constant imports.%Core.import_ref.dab, @Optional(constants.%OptionalStorage.facet.097) [concrete = constants.%Optional.Get.0a8]
// CHECK:STDOUT:   %Get.ref: %Optional.Get.type.336 = name_ref Get, %.loc9_19.7 [concrete = constants.%Optional.Get.0a8]
// CHECK:STDOUT:   %Optional.Get.bound: <bound method> = bound_method %.loc9_19.2, %Get.ref
// CHECK:STDOUT:   %Optional.Get.specific_fn: <specific function> = specific_function %Get.ref, @Optional.Get(constants.%OptionalStorage.facet.097) [concrete = constants.%Optional.Get.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_19.6: <bound method> = bound_method %.loc9_19.2, %Optional.Get.specific_fn
// CHECK:STDOUT:   %.loc9_19.8: %Optional.755 = acquire_value %.loc9_19.2
// CHECK:STDOUT:   %Optional.Get.call: init %i32 = call %bound_method.loc9_19.6(%.loc9_19.8)
// CHECK:STDOUT:   %.loc9_19.9: %i32 = value_of_initializer %Optional.Get.call
// CHECK:STDOUT:   %.loc9_19.10: %i32 = converted %Optional.Get.call, %.loc9_19.9
// CHECK:STDOUT:   %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %x: %i32 = wrapper_binding x, %.loc9_19.10
// CHECK:STDOUT:   %t.ref.loc10: ref %i32 = name_ref t, %t
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %impl.elem0.loc10: %.004 = impl_witness_access constants.%AddAssignWith.impl_witness.e9d, element0 [concrete = constants.%Int.as.AddAssignWith.impl.Op.d34738.2]
// CHECK:STDOUT:   %bound_method.loc10_7.1: <bound method> = bound_method %t.ref.loc10, %impl.elem0.loc10
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Int.as.AddAssignWith.impl.Op.1(constants.%int_32, constants.%ImplicitAs.facet.e88) [concrete = constants.%Int.as.AddAssignWith.impl.Op.specific_fn.d76216.1]
// CHECK:STDOUT:   %bound_method.loc10_7.2: <bound method> = bound_method %t.ref.loc10, %specific_fn.loc10
// CHECK:STDOUT:   %.loc10: %Int.as.AddAssignWith.impl.Op.type.0b80aa.1 = specific_constant imports.%Core.Op.1b1, @Int.as.AddAssignWith.impl(constants.%int_32, constants.%ImplicitAs.facet.e88) [concrete = constants.%Int.as.AddAssignWith.impl.Op.d34738.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddAssignWith.impl.Op.type.0b80aa.1 = name_ref Op, %.loc10 [concrete = constants.%Int.as.AddAssignWith.impl.Op.d34738.1]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.bound: <bound method> = bound_method %t.ref.loc10, %Op.ref
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddAssignWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.e88) [concrete = constants.%Int.as.AddAssignWith.impl.Op.specific_fn.d76216.2]
// CHECK:STDOUT:   %bound_method.loc10_7.3: <bound method> = bound_method %t.ref.loc10, %Int.as.AddAssignWith.impl.Op.specific_fn
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.call: init %empty_tuple.type = call %bound_method.loc10_7.3(%t.ref.loc10, %x.ref)
// CHECK:STDOUT:   %Destroy.Op.bound.loc9_19.1: <bound method> = bound_method %.loc9_19.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc9_19.1: init %empty_tuple.type = call %Destroy.Op.bound.loc9_19.1(%.loc9_19.2)
// CHECK:STDOUT:   br !for.next
// CHECK:STDOUT:
// CHECK:STDOUT: !for.done:
// CHECK:STDOUT:   %Destroy.Op.bound.loc9_19.2: <bound method> = bound_method %.loc9_19.2, constants.%Destroy.Op.1a2547.10
// CHECK:STDOUT:   %Destroy.Op.call.loc9_19.2: init %empty_tuple.type = call %Destroy.Op.bound.loc9_19.2(%.loc9_19.2)
// CHECK:STDOUT:   %Destroy.Op.bound.loc9_19.3: <bound method> = bound_method %var, constants.%Destroy.Op.1a2547.12
// CHECK:STDOUT:   %Destroy.Op.call.loc9_19.3: init %empty_tuple.type = call %Destroy.Op.bound.loc9_19.3(%var)
// CHECK:STDOUT:   %t.ref.loc12: ref %i32 = name_ref t, %t
// CHECK:STDOUT:   %.loc12: %i32 = acquire_value %t.ref.loc12
// CHECK:STDOUT:   %impl.elem0.loc12: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc12_10.1: <bound method> = bound_method %.loc12, %impl.elem0.loc12
// CHECK:STDOUT:   %specific_fn.loc12: <specific function> = specific_function %impl.elem0.loc12, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_10.2: <bound method> = bound_method %.loc12, %specific_fn.loc12
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc12_10.2(%.loc12)
// CHECK:STDOUT:   %Destroy.Op.bound.loc8: <bound method> = bound_method %t.var, constants.%Destroy.Op.1a2547.2
// CHECK:STDOUT:   %Destroy.Op.call.loc8: init %empty_tuple.type = call %Destroy.Op.bound.loc8(%t.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_19.1(%self.param: ref %.1d6) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_19.2(%self.param: ref %MaybeUnformed.023) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_19.3(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_19.4(%self.param: ref %struct_type.value.has_value.ad0) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_19.5(%self.param: ref %DefaultOptionalStorage.bfa) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_19.6(%self.param: ref %Optional.755) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_19.7(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_19.8(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- unformed.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %U.type: type = fn_type @U [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %U.815: %U.type = struct_value () [concrete]
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc13_24.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type = facet_value %i32, (%custom_witness.df9cc1.2, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Slice.33a: type = class_type @Slice, @Slice(%facet_value) [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %struct_type.ptr.size.0cc: type = struct_type {.ptr: %ptr.d08, .size: %i64} [concrete]
// CHECK:STDOUT:   %pattern_type.d8a: type = pattern_type %Slice.33a [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.d8a = ref_binding_pattern s [concrete]
// CHECK:STDOUT:   %s.var_patt: %pattern_type.d8a = var_pattern %s.patt [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.type: type = facet_type <@DefaultOrUnformed> [concrete]
// CHECK:STDOUT:   %UnformedInit.type: type = facet_type <@UnformedInit> [concrete]
// CHECK:STDOUT:   %T.fef: %UnformedInit.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.type.215: type = fn_type @T.as_type.as.DefaultOrUnformed.impl.Op.2, @T.as_type.as.DefaultOrUnformed.impl.52f(%T.fef) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.f65: %T.as_type.as.DefaultOrUnformed.impl.Op.type.215 = struct_value () [symbolic]
// CHECK:STDOUT:   %UnformedInit.impl_witness.75c: <witness> = impl_witness imports.%UnformedInit.impl_witness_table.59c, @Slice.as.UnformedInit.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %UnformedInit.facet: %UnformedInit.type = facet_value %Slice.33a, (%UnformedInit.impl_witness.75c) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness.d34: <witness> = impl_witness imports.%DefaultOrUnformed.impl_witness_table.8f5, @T.as_type.as.DefaultOrUnformed.impl.52f(%UnformedInit.facet) [concrete]
// CHECK:STDOUT:   %DefaultOrUnformed.facet: %DefaultOrUnformed.type = facet_value %Slice.33a, (%DefaultOrUnformed.impl_witness.d34) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.7: type = fn_type @Destroy.Op.loc13_3.5 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.7: %Destroy.Op.type.1d8f74.7 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .DefaultOrUnformed = %Core.DefaultOrUnformed
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.DefaultOrUnformed: type = import_ref Core//prelude/default, DefaultOrUnformed, loaded [concrete = constants.%DefaultOrUnformed.type]
// CHECK:STDOUT:   %Core.import_ref.083: @T.as_type.as.DefaultOrUnformed.impl.52f.%T.as_type.as.DefaultOrUnformed.impl.Op.type (%T.as_type.as.DefaultOrUnformed.impl.Op.type.215) = import_ref Core//prelude/default, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.DefaultOrUnformed.impl.52f.%T.as_type.as.DefaultOrUnformed.impl.Op (constants.%T.as_type.as.DefaultOrUnformed.impl.Op.f65)]
// CHECK:STDOUT:   %DefaultOrUnformed.impl_witness_table.8f5 = impl_witness_table (%Core.import_ref.083), @T.as_type.as.DefaultOrUnformed.impl.52f [concrete]
// CHECK:STDOUT:   %UnformedInit.impl_witness_table.59c = impl_witness_table (), @Slice.as.UnformedInit.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %U.decl: %U.type = fn_decl @U [concrete = constants.%U.815] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @U() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.var: ref %Slice.33a = var_storage %s.var_patt
// CHECK:STDOUT:   %DefaultOrUnformed.facet: %DefaultOrUnformed.type = facet_value constants.%Slice.33a, (constants.%DefaultOrUnformed.impl_witness.d34) [concrete = constants.%DefaultOrUnformed.facet]
// CHECK:STDOUT:   %.loc13_25.1: %DefaultOrUnformed.type = converted constants.%Slice.33a, %DefaultOrUnformed.facet [concrete = constants.%DefaultOrUnformed.facet]
// CHECK:STDOUT:   %as_type: type = facet_access_type %.loc13_25.1 [concrete = constants.%Slice.33a]
// CHECK:STDOUT:   %.loc13_25.2: type = converted %.loc13_25.1, %as_type [concrete = constants.%Slice.33a]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %.loc13_3: ref %Slice.33a = splice_block %s.var {}
// CHECK:STDOUT:   %T.as_type.as.DefaultOrUnformed.impl.Op.call: init %Slice.33a to %.loc13_3 = call %T.as_type.as.DefaultOrUnformed.impl.Op.specific_fn()
// CHECK:STDOUT:   assign %s.var, %T.as_type.as.DefaultOrUnformed.impl.Op.call
// CHECK:STDOUT:   %.loc13_24.1: type = splice_block %Slice [concrete = constants.%Slice.33a] {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %facet_value: %facet_type = facet_value %i32, (constants.%custom_witness.df9cc1.2, constants.%Copy.impl_witness.b51) [concrete = constants.%facet_value]
// CHECK:STDOUT:     %.loc13_24.2: %facet_type = converted %i32, %facet_value [concrete = constants.%facet_value]
// CHECK:STDOUT:     %Slice: type = class_type @Slice, @Slice(constants.%facet_value) [concrete = constants.%Slice.33a]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: ref %Slice.33a = wrapper_binding s, %s.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.d8a = ref_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:     %s.var_patt: %pattern_type.d8a = var_pattern %s.patt [concrete = constants.%s.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %s.var, constants.%Destroy.Op.1a2547.7
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%s.var)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_24.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_24.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_3.1(%self.param: ref %ptr.d08) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_3.2(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_3.3(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_3.4(%self.param: ref %struct_type.ptr.size.0cc) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_3.5(%self.param: ref %Slice.33a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic_element.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: %type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %BitAndWith.generic: %BitAndWith.type.a06 = struct_value () [concrete]
// CHECK:STDOUT:   %BitAndWith.type.802: type = facet_type <@BitAndWith, @BitAndWith(type)> [concrete]
// CHECK:STDOUT:   %BitAndWith.impl_witness: <witness> = impl_witness imports.%BitAndWith.impl_witness_table [concrete]
// CHECK:STDOUT:   %BitAndWith.facet: %BitAndWith.type.802 = facet_value type, (%BitAndWith.impl_witness) [concrete]
// CHECK:STDOUT:   %BitAndWith.WithSelf.Op.type.76f: type = fn_type @BitAndWith.WithSelf.Op, @BitAndWith.WithSelf(type, %BitAndWith.facet) [concrete]
// CHECK:STDOUT:   %.eef: type = fn_type_with_self_type %BitAndWith.WithSelf.Op.type.76f, %BitAndWith.facet [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.type: type = fn_type @type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op: %type.as.BitAndWith.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %type.as.BitAndWith.impl.Op.bound: <bound method> = bound_method %Copy.type, %type.as.BitAndWith.impl.Op [concrete]
// CHECK:STDOUT:   %facet_type.a1a: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %pattern_type.143: type = pattern_type %facet_type.a1a [concrete]
// CHECK:STDOUT:   %T.patt.256: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.dc4: %facet_type.a1a = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %T.as_type.5d6: type = facet_access_type %T.dc4 [symbolic]
// CHECK:STDOUT:   %Slice: type = class_type @Slice, @Slice(%T.dc4) [symbolic]
// CHECK:STDOUT:   %pattern_type.f90: type = pattern_type %Slice [symbolic]
// CHECK:STDOUT:   %pattern_type.0e9: type = pattern_type %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %return.param_patt.7e1: %pattern_type.0e9 = out_param_pattern [symbolic]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.227: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %require_complete.dda: <witness> = require_complete_type %Slice [symbolic]
// CHECK:STDOUT:   %.273: Core.Form = init_form %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %require_complete.091: <witness> = require_complete_type %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.f90 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %s.patt: %pattern_type.f90 = wrapper_binding_pattern s, %s.param_patt [symbolic]
// CHECK:STDOUT:   %return.patt.dca: %pattern_type.0e9 = return_slot_pattern %return.param_patt.7e1, %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %First.type: type = fn_type @First [concrete]
// CHECK:STDOUT:   %First: %First.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %IndexWith.type.df6: type = generic_interface_type @IndexWith [concrete]
// CHECK:STDOUT:   %IndexWith.generic: %IndexWith.type.df6 = struct_value () [concrete]
// CHECK:STDOUT:   %IndexWith.type.3ea: type = facet_type <@IndexWith, @IndexWith(%i64)> [concrete]
// CHECK:STDOUT:   %IndexWith.impl_witness: <witness> = impl_witness imports.%IndexWith.impl_witness_table, @Slice.as.IndexWith.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.type: type = fn_type @Slice.as.IndexWith.impl.At, @Slice.as.IndexWith.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At: %Slice.as.IndexWith.impl.At.type = struct_value () [symbolic]
// CHECK:STDOUT:   %.b7e: require_specific_def_type = require_specific_def @Slice.as.IndexWith.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %IndexWith.facet: %IndexWith.type.3ea = facet_value %Slice, (%IndexWith.impl_witness) [symbolic]
// CHECK:STDOUT:   %IndexWith.WithSelf.At.type.8f4: type = fn_type @IndexWith.WithSelf.At, @IndexWith.WithSelf(%i64, %IndexWith.facet) [symbolic]
// CHECK:STDOUT:   %.4ff: type = fn_type_with_self_type %IndexWith.WithSelf.At.type.8f4, %IndexWith.facet [symbolic]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.specific_fn: <specific function> = specific_function %Slice.as.IndexWith.impl.At, @Slice.as.IndexWith.impl.At(%T.dc4) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .IndexWith = %Core.IndexWith
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.ad2 = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.ad2, %Core.import_ref.9c3), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.import_ref.717: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/slice, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.717), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.IndexWith: %IndexWith.type.df6 = import_ref Core//prelude/operators/index, IndexWith, loaded [concrete = constants.%IndexWith.generic]
// CHECK:STDOUT:   %Core.import_ref.ef4 = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.d81: @Slice.as.IndexWith.impl.%Slice.as.IndexWith.impl.At.type (%Slice.as.IndexWith.impl.At.type) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.IndexWith.impl.%Slice.as.IndexWith.impl.At (constants.%Slice.as.IndexWith.impl.At)]
// CHECK:STDOUT:   %IndexWith.impl_witness_table = impl_witness_table (%Core.import_ref.ef4, %Core.import_ref.d81), @Slice.as.IndexWith.impl [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %First.decl: %First.type = fn_decl @First [concrete = constants.%First] {
// CHECK:STDOUT:     %T.patt.loc13_11.1: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc13_11.2 (constants.%T.patt.256)]
// CHECK:STDOUT:     %s.param_patt.loc13_40.1: @First.%pattern_type.loc13_40 (%pattern_type.f90) = value_param_pattern [symbolic = %s.param_patt.loc13_40.2 (constants.%s.param_patt)]
// CHECK:STDOUT:     %s.patt.loc13_40.1: @First.%pattern_type.loc13_40 (%pattern_type.f90) = wrapper_binding_pattern s, %s.param_patt.loc13_40.1 [symbolic = %s.patt.loc13_40.2 (constants.%s.patt)]
// CHECK:STDOUT:     %return.param_patt.loc13_60.1: @First.%pattern_type.loc13_60 (%pattern_type.0e9) = out_param_pattern [symbolic = %return.param_patt.loc13_60.2 (constants.%return.param_patt.7e1)]
// CHECK:STDOUT:     %return.patt.loc13_57.1: @First.%pattern_type.loc13_60 (%pattern_type.0e9) = return_slot_pattern %return.param_patt.loc13_60.1, %.loc13_60.3 [symbolic = %return.patt.loc13_57.2 (constants.%return.patt.dca)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc13_60: %facet_type.a1a = name_ref T, %T.loc13_11.2 [symbolic = %T.loc13_11.1 (constants.%T.dc4)]
// CHECK:STDOUT:     %T.as_type.loc13_60.2: type = facet_access_type %T.ref.loc13_60 [symbolic = %T.as_type.loc13_60.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:     %.loc13_60.3: type = converted %T.ref.loc13_60, %T.as_type.loc13_60.2 [symbolic = %T.as_type.loc13_60.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:     %.loc13_60.4: Core.Form = init_form %.loc13_60.3 [symbolic = %.loc13_60.2 (constants.%.273)]
// CHECK:STDOUT:     %.loc13_23.1: type = splice_block %.loc13_23.3 [concrete = constants.%facet_type.a1a] {
// CHECK:STDOUT:       %.Self.frozen: %type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc13_13: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc13_25: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1.loc13: %.eef = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc13: <bound method> = bound_method %Copy.ref, %impl.elem1.loc13 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method.loc13(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type.a1a]
// CHECK:STDOUT:       %.loc13_23.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type.a1a]
// CHECK:STDOUT:       %.loc13_23.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc13_23.2 [concrete = constants.%facet_type.a1a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc13_11.2: %facet_type.a1a = symbolic_binding T, 0 [symbolic = %T.loc13_11.1 (constants.%T.dc4)]
// CHECK:STDOUT:     %s.param: @First.%Slice.loc13_54.1 (%Slice) = value_param call_param0
// CHECK:STDOUT:     %.loc13_54: type = splice_block %Slice.loc13_54.2 [symbolic = %Slice.loc13_54.1 (constants.%Slice)] {
// CHECK:STDOUT:       %Core.ref.loc13_42: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:       %T.ref.loc13_53: %facet_type.a1a = name_ref T, %T.loc13_11.2 [symbolic = %T.loc13_11.1 (constants.%T.dc4)]
// CHECK:STDOUT:       %Slice.loc13_54.2: type = class_type @Slice, @Slice(constants.%T.dc4) [symbolic = %Slice.loc13_54.1 (constants.%Slice)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: @First.%Slice.loc13_54.1 (%Slice) = wrapper_binding s, %s.param
// CHECK:STDOUT:     %return.param: ref @First.%T.as_type.loc13_60.1 (%T.as_type.5d6) = out_param call_param1
// CHECK:STDOUT:     %return: ref @First.%T.as_type.loc13_60.1 (%T.as_type.5d6) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @First(%T.loc13_11.2: %facet_type.a1a) {
// CHECK:STDOUT:   %T.patt.loc13_11.2: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc13_11.2 (constants.%T.patt.256)]
// CHECK:STDOUT:   %T.loc13_11.1: %facet_type.a1a = symbolic_binding T, 0 [symbolic = %T.loc13_11.1 (constants.%T.dc4)]
// CHECK:STDOUT:   %Slice.loc13_54.1: type = class_type @Slice, @Slice(%T.loc13_11.1) [symbolic = %Slice.loc13_54.1 (constants.%Slice)]
// CHECK:STDOUT:   %pattern_type.loc13_40: type = pattern_type %Slice.loc13_54.1 [symbolic = %pattern_type.loc13_40 (constants.%pattern_type.f90)]
// CHECK:STDOUT:   %s.param_patt.loc13_40.2: @First.%pattern_type.loc13_40 (%pattern_type.f90) = value_param_pattern [symbolic = %s.param_patt.loc13_40.2 (constants.%s.param_patt)]
// CHECK:STDOUT:   %s.patt.loc13_40.2: @First.%pattern_type.loc13_40 (%pattern_type.f90) = wrapper_binding_pattern s, %s.param_patt.loc13_40.2 [symbolic = %s.patt.loc13_40.2 (constants.%s.patt)]
// CHECK:STDOUT:   %T.as_type.loc13_60.1: type = facet_access_type %T.loc13_11.1 [symbolic = %T.as_type.loc13_60.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:   %.loc13_60.2: Core.Form = init_form %T.as_type.loc13_60.1 [symbolic = %.loc13_60.2 (constants.%.273)]
// CHECK:STDOUT:   %pattern_type.loc13_60: type = pattern_type %T.as_type.loc13_60.1 [symbolic = %pattern_type.loc13_60 (constants.%pattern_type.0e9)]
// CHECK:STDOUT:   %return.param_patt.loc13_60.2: @First.%pattern_type.loc13_60 (%pattern_type.0e9) = out_param_pattern [symbolic = %return.param_patt.loc13_60.2 (constants.%return.param_patt.7e1)]
// CHECK:STDOUT:   %return.patt.loc13_57.2: @First.%pattern_type.loc13_60 (%pattern_type.0e9) = return_slot_pattern %return.param_patt.loc13_60.2, %T.as_type.loc13_60.1 [symbolic = %return.patt.loc13_57.2 (constants.%return.patt.dca)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc13_40: <witness> = require_complete_type %Slice.loc13_54.1 [symbolic = %require_complete.loc13_40 (constants.%require_complete.dda)]
// CHECK:STDOUT:   %require_complete.loc13_57: <witness> = require_complete_type %T.as_type.loc13_60.1 [symbolic = %require_complete.loc13_57 (constants.%require_complete.091)]
// CHECK:STDOUT:   %.loc14_13.1: require_specific_def_type = require_specific_def @Slice.as.IndexWith.impl(%T.loc13_11.1) [symbolic = %.loc14_13.1 (constants.%.b7e)]
// CHECK:STDOUT:   %IndexWith.impl_witness: <witness> = impl_witness imports.%IndexWith.impl_witness_table, @Slice.as.IndexWith.impl(%T.loc13_11.1) [symbolic = %IndexWith.impl_witness (constants.%IndexWith.impl_witness)]
// CHECK:STDOUT:   %IndexWith.facet: %IndexWith.type.3ea = facet_value %Slice.loc13_54.1, (%IndexWith.impl_witness) [symbolic = %IndexWith.facet (constants.%IndexWith.facet)]
// CHECK:STDOUT:   %IndexWith.WithSelf.At.type: type = fn_type @IndexWith.WithSelf.At, @IndexWith.WithSelf(constants.%i64, %IndexWith.facet) [symbolic = %IndexWith.WithSelf.At.type (constants.%IndexWith.WithSelf.At.type.8f4)]
// CHECK:STDOUT:   %.loc14_13.2: type = fn_type_with_self_type %IndexWith.WithSelf.At.type, %IndexWith.facet [symbolic = %.loc14_13.2 (constants.%.4ff)]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.type: type = fn_type @Slice.as.IndexWith.impl.At, @Slice.as.IndexWith.impl(%T.loc13_11.1) [symbolic = %Slice.as.IndexWith.impl.At.type (constants.%Slice.as.IndexWith.impl.At.type)]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At: @First.%Slice.as.IndexWith.impl.At.type (%Slice.as.IndexWith.impl.At.type) = struct_value () [symbolic = %Slice.as.IndexWith.impl.At (constants.%Slice.as.IndexWith.impl.At)]
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.specific_fn: <specific function> = specific_function %Slice.as.IndexWith.impl.At, @Slice.as.IndexWith.impl.At(%T.loc13_11.1) [symbolic = %Slice.as.IndexWith.impl.At.specific_fn (constants.%Slice.as.IndexWith.impl.At.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%s.param: @First.%Slice.loc13_54.1 (%Slice)) -> out %return.param: @First.%T.as_type.loc13_60.1 (%T.as_type.5d6) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %s.ref: @First.%Slice.loc13_54.1 (%Slice) = name_ref s, %s
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc14_12.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:     %specific_fn.loc14_12: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc14_12.2: <bound method> = bound_method %int_0, %specific_fn.loc14_12 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc14_12.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc14_12.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc14_12.2: %i64 = converted %int_0, %.loc14_12.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %impl.elem1.loc14: @First.%.loc14_13.2 (%.4ff) = impl_witness_access constants.%IndexWith.impl_witness, element1 [symbolic = %Slice.as.IndexWith.impl.At (constants.%Slice.as.IndexWith.impl.At)]
// CHECK:STDOUT:     %bound_method.loc14_13.1: <bound method> = bound_method %s.ref, %impl.elem1.loc14
// CHECK:STDOUT:     %specific_fn.loc14_13: <specific function> = specific_function %impl.elem1.loc14, @Slice.as.IndexWith.impl.At(constants.%T.dc4) [symbolic = %Slice.as.IndexWith.impl.At.specific_fn (constants.%Slice.as.IndexWith.impl.At.specific_fn)]
// CHECK:STDOUT:     %bound_method.loc14_13.2: <bound method> = bound_method %s.ref, %specific_fn.loc14_13
// CHECK:STDOUT:     %.loc13_60.1: ref @First.%T.as_type.loc13_60.1 (%T.as_type.5d6) = splice_block %return.param {}
// CHECK:STDOUT:     %Slice.as.IndexWith.impl.At.call: init @First.%T.as_type.loc13_60.1 (%T.as_type.5d6) to %.loc13_60.1 = call %bound_method.loc14_13.2(%s.ref, %.loc14_12.2)
// CHECK:STDOUT:     return %Slice.as.IndexWith.impl.At.call to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @First(constants.%T.dc4) {
// CHECK:STDOUT:   %T.patt.loc13_11.2 => constants.%T.patt.256
// CHECK:STDOUT:   %T.loc13_11.1 => constants.%T.dc4
// CHECK:STDOUT:   %Slice.loc13_54.1 => constants.%Slice
// CHECK:STDOUT:   %pattern_type.loc13_40 => constants.%pattern_type.f90
// CHECK:STDOUT:   %s.param_patt.loc13_40.2 => constants.%s.param_patt
// CHECK:STDOUT:   %s.patt.loc13_40.2 => constants.%s.patt
// CHECK:STDOUT:   %T.as_type.loc13_60.1 => constants.%T.as_type.5d6
// CHECK:STDOUT:   %.loc13_60.2 => constants.%.273
// CHECK:STDOUT:   %pattern_type.loc13_60 => constants.%pattern_type.0e9
// CHECK:STDOUT:   %return.param_patt.loc13_60.2 => constants.%return.param_patt.7e1
// CHECK:STDOUT:   %return.patt.loc13_57.2 => constants.%return.patt.dca
// CHECK:STDOUT: }
// CHECK:STDOUT:
