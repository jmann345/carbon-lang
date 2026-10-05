// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/buf.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): `Core.Buf(T)` (D-SL-6).

// --- make_get_set.carbon

library "[[@TEST_NAME]]";

// Predicted: `Make`/`Set`/`IndexWith.At`/`Get` calls and, at the end of `F`,
// the `Destroy` witness call on `b` from the user impl inside the generic
// class (`@Buf.as.Destroy.impl`) — the arbiter of risk R-12.
//@dump-sem-ir-begin
fn F(n: i64) -> i32 {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(n, 7);
  b.Set(0, 9);
  return b[0] + b.Get(1);
}
//@dump-sem-ir-end

// --- as_slice.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn S(b: Core.Buf(i32)) -> Core.Slice(i32) {
  return b.AsSlice();
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- make_get_set.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.f57 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Buf.type: type = generic_class_type @Buf [concrete]
// CHECK:STDOUT:   %Buf.generic: %Buf.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %facet_type.a1a: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %T.dc4: %facet_type.a1a = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.227: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %Buf.Set.type.8ad: type = fn_type @Buf.Set, @Buf(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.Set.43d: %Buf.Set.type.8ad = struct_value () [symbolic]
// CHECK:STDOUT:   %Buf.Get.type.49f: type = fn_type @Buf.Get, @Buf(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.Get.10a: %Buf.Get.type.49f = struct_value () [symbolic]
// CHECK:STDOUT:   %Buf.Make.type.057: type = fn_type @Buf.Make, @Buf(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.Make.623: %Buf.Make.type.057 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc9_22.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.7b6: %facet_type.a1a = facet_value %i32, (%Copy.impl_witness.b51, %custom_witness.df9cc1.2) [concrete]
// CHECK:STDOUT:   %Buf.e51: type = class_type @Buf, @Buf(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %Buf.Make.type.c24: type = fn_type @Buf.Make, @Buf(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %Buf.Make.f5b: %Buf.Make.type.c24 = struct_value () [concrete]
// CHECK:STDOUT:   %Buf.Get.type.e5d: type = fn_type @Buf.Get, @Buf(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %Buf.Get.0f8: %Buf.Get.type.e5d = struct_value () [concrete]
// CHECK:STDOUT:   %Buf.Set.type.cea: type = fn_type @Buf.Set, @Buf(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %Buf.Set.b0f: %Buf.Set.type.cea = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6dd: type = pattern_type %Buf.e51 [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6dd = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.6dd = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.0b3: <witness> = impl_witness imports.%Copy.impl_witness_table.ee5 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.loc9_49 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.3: %Destroy.Op.type.1d8f74.3 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.3: <witness> = custom_witness (%Destroy.Op.1a2547.3), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.399: %facet_type.a1a = facet_value Core.IntLiteral, (%Copy.impl_witness.0b3, %custom_witness.df9cc1.3) [concrete]
// CHECK:STDOUT:   %Buf.Make.specific_fn: <specific function> = specific_function %Buf.Make.f5b, @Buf.Make(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.7ff: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %int_9.988: Core.IntLiteral = int_value 9 [concrete]
// CHECK:STDOUT:   %Buf.Set.specific_fn: <specific function> = specific_function %Buf.Set.b0f, @Buf.Set(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.235: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet.235 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f46: <bound method> = bound_method %int_9.988, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.9bf: <bound method> = bound_method %int_9.988, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_9.056: %i32 = int_value 9 [concrete]
// CHECK:STDOUT:   %IndexWith.type.df6: type = generic_interface_type @IndexWith [concrete]
// CHECK:STDOUT:   %IndexWith.generic: %IndexWith.type.df6 = struct_value () [concrete]
// CHECK:STDOUT:   %IndexWith.type.3ea: type = facet_type <@IndexWith, @IndexWith(%i64)> [concrete]
// CHECK:STDOUT:   %Buf.as.IndexWith.impl.At.type.35d: type = fn_type @Buf.as.IndexWith.impl.At, @Buf.as.IndexWith.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.as.IndexWith.impl.At.061: %Buf.as.IndexWith.impl.At.type.35d = struct_value () [symbolic]
// CHECK:STDOUT:   %IndexWith.impl_witness.b0f: <witness> = impl_witness imports.%IndexWith.impl_witness_table, @Buf.as.IndexWith.impl(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %Buf.as.IndexWith.impl.At.type.423: type = fn_type @Buf.as.IndexWith.impl.At, @Buf.as.IndexWith.impl(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %Buf.as.IndexWith.impl.At.2e9: %Buf.as.IndexWith.impl.At.type.423 = struct_value () [concrete]
// CHECK:STDOUT:   %IndexWith.facet: %IndexWith.type.3ea = facet_value %Buf.e51, (%IndexWith.impl_witness.b0f) [concrete]
// CHECK:STDOUT:   %IndexWith.WithSelf.At.type.33d: type = fn_type @IndexWith.WithSelf.At, @IndexWith.WithSelf(%i64, %IndexWith.facet) [concrete]
// CHECK:STDOUT:   %.964: type = fn_type_with_self_type %IndexWith.WithSelf.At.type.33d, %IndexWith.facet [concrete]
// CHECK:STDOUT:   %Buf.as.IndexWith.impl.At.specific_fn: <specific function> = specific_function %Buf.as.IndexWith.impl.At.2e9, @Buf.as.IndexWith.impl.At(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Buf.Get.specific_fn.de2: <specific function> = specific_function %Buf.Get.0f8, @Buf.Get(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.c5e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %Buf.as.Destroy.impl.Op.type.05c: type = fn_type @Buf.as.Destroy.impl.Op, @Buf.as.Destroy.impl(%facet_value.7b6) [concrete]
// CHECK:STDOUT:   %Buf.as.Destroy.impl.Op.305: %Buf.as.Destroy.impl.Op.type.05c = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Buf = %Core.Buf
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .IndexWith = %Core.IndexWith
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Buf: %Buf.type = import_ref Core//prelude/types/buf, Buf, loaded [concrete = constants.%Buf.generic]
// CHECK:STDOUT:   %Core.import_ref.cbd: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/buf, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.cbd), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.fea: @Buf.%Buf.Make.type (%Buf.Make.type.057) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.%Buf.Make (constants.%Buf.Make.623)]
// CHECK:STDOUT:   %Core.import_ref.6a6: @Buf.%Buf.Get.type (%Buf.Get.type.49f) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.%Buf.Get (constants.%Buf.Get.10a)]
// CHECK:STDOUT:   %Core.import_ref.4c3: @Buf.%Buf.Set.type (%Buf.Set.type.8ad) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.%Buf.Set (constants.%Buf.Set.43d)]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.bbf3 = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.ee5 = impl_witness_table (%Core.import_ref.bbf3), @Core.IntLiteral.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.IndexWith: %IndexWith.type.df6 = import_ref Core//prelude/operators/index, IndexWith, loaded [concrete = constants.%IndexWith.generic]
// CHECK:STDOUT:   %Core.import_ref.5c7 = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.443: @Buf.as.IndexWith.impl.%Buf.as.IndexWith.impl.At.type (%Buf.as.IndexWith.impl.At.type.35d) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.as.IndexWith.impl.%Buf.as.IndexWith.impl.At (constants.%Buf.as.IndexWith.impl.At.061)]
// CHECK:STDOUT:   %IndexWith.impl_witness_table = impl_witness_table (%Core.import_ref.5c7, %Core.import_ref.443), @Buf.as.IndexWith.impl [concrete]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.f57 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.f57 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8: Core.Form = init_form %i32.loc8 [concrete = constants.%.795f]
// CHECK:STDOUT:     %n.param: %i64 = value_param call_param0
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %n: %i64 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%n.param: %i64) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.var: ref %Buf.e51 = var_storage %b.var_patt
// CHECK:STDOUT:   %Core.ref.loc9_26: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Buf.ref.loc9_30: %Buf.type = name_ref Buf, imports.%Core.Buf [concrete = constants.%Buf.generic]
// CHECK:STDOUT:   %i32.loc9_35: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %facet_value.loc9_38: %facet_type.a1a = facet_value %i32.loc9_35, (constants.%Copy.impl_witness.b51, constants.%custom_witness.df9cc1.2) [concrete = constants.%facet_value.7b6]
// CHECK:STDOUT:   %.loc9_38: %facet_type.a1a = converted %i32.loc9_35, %facet_value.loc9_38 [concrete = constants.%facet_value.7b6]
// CHECK:STDOUT:   %Buf.loc9_38: type = class_type @Buf, @Buf(constants.%facet_value.7b6) [concrete = constants.%Buf.e51]
// CHECK:STDOUT:   %.loc9_39: %Buf.Make.type.c24 = specific_constant imports.%Core.import_ref.fea, @Buf(constants.%facet_value.7b6) [concrete = constants.%Buf.Make.f5b]
// CHECK:STDOUT:   %Make.ref: %Buf.Make.type.c24 = name_ref Make, %.loc9_39 [concrete = constants.%Buf.Make.f5b]
// CHECK:STDOUT:   %n.ref: %i64 = name_ref n, %n
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %facet_value.loc9_49.1: %facet_type.a1a = facet_value Core.IntLiteral, (constants.%Copy.impl_witness.0b3, constants.%custom_witness.df9cc1.3) [concrete = constants.%facet_value.399]
// CHECK:STDOUT:   %.loc9_49.1: %facet_type.a1a = converted Core.IntLiteral, %facet_value.loc9_49.1 [concrete = constants.%facet_value.399]
// CHECK:STDOUT:   %facet_value.loc9_49.2: %facet_type.a1a = facet_value Core.IntLiteral, (constants.%Copy.impl_witness.0b3, constants.%custom_witness.df9cc1.3) [concrete = constants.%facet_value.399]
// CHECK:STDOUT:   %.loc9_49.2: %facet_type.a1a = converted Core.IntLiteral, %facet_value.loc9_49.2 [concrete = constants.%facet_value.399]
// CHECK:STDOUT:   %Buf.Make.specific_fn: <specific function> = specific_function %Make.ref, @Buf.Make(constants.%facet_value.7b6) [concrete = constants.%Buf.Make.specific_fn]
// CHECK:STDOUT:   %.loc9_3: ref %Buf.e51 = splice_block %b.var {}
// CHECK:STDOUT:   %impl.elem0.loc9: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_48.1: <bound method> = bound_method %int_7, %impl.elem0.loc9 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc9_48.2: <bound method> = bound_method %int_7, %specific_fn.loc9 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %i32 = call %bound_method.loc9_48.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc9_48.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc9_48.2: %i32 = converted %int_7, %.loc9_48.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %Buf.Make.call: init %Buf.e51 to %.loc9_3 = call %Buf.Make.specific_fn(%n.ref, %.loc9_48.2)
// CHECK:STDOUT:   assign %b.var, %Buf.Make.call
// CHECK:STDOUT:   %.loc9_22.1: type = splice_block %Buf.loc9_22 [concrete = constants.%Buf.e51] {
// CHECK:STDOUT:     %Core.ref.loc9_10: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Buf.ref.loc9_14: %Buf.type = name_ref Buf, imports.%Core.Buf [concrete = constants.%Buf.generic]
// CHECK:STDOUT:     %i32.loc9_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %facet_value.loc9_22: %facet_type.a1a = facet_value %i32.loc9_19, (constants.%Copy.impl_witness.b51, constants.%custom_witness.df9cc1.2) [concrete = constants.%facet_value.7b6]
// CHECK:STDOUT:     %.loc9_22.2: %facet_type.a1a = converted %i32.loc9_19, %facet_value.loc9_22 [concrete = constants.%facet_value.7b6]
// CHECK:STDOUT:     %Buf.loc9_22: type = class_type @Buf, @Buf(constants.%facet_value.7b6) [concrete = constants.%Buf.e51]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: ref %Buf.e51 = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.6dd = ref_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.6dd = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.ref.loc10: ref %Buf.e51 = name_ref b, %b
// CHECK:STDOUT:   %.loc10_4: %Buf.Set.type.cea = specific_constant imports.%Core.import_ref.4c3, @Buf(constants.%facet_value.7b6) [concrete = constants.%Buf.Set.b0f]
// CHECK:STDOUT:   %Set.ref: %Buf.Set.type.cea = name_ref Set, %.loc10_4 [concrete = constants.%Buf.Set.b0f]
// CHECK:STDOUT:   %Buf.Set.bound: <bound method> = bound_method %b.ref.loc10, %Set.ref
// CHECK:STDOUT:   %int_0.loc10: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %int_9: Core.IntLiteral = int_value 9 [concrete = constants.%int_9.988]
// CHECK:STDOUT:   %facet_value.loc10_13.1: %facet_type.a1a = facet_value Core.IntLiteral, (constants.%Copy.impl_witness.0b3, constants.%custom_witness.df9cc1.3) [concrete = constants.%facet_value.399]
// CHECK:STDOUT:   %.loc10_13.1: %facet_type.a1a = converted Core.IntLiteral, %facet_value.loc10_13.1 [concrete = constants.%facet_value.399]
// CHECK:STDOUT:   %facet_value.loc10_13.2: %facet_type.a1a = facet_value Core.IntLiteral, (constants.%Copy.impl_witness.0b3, constants.%custom_witness.df9cc1.3) [concrete = constants.%facet_value.399]
// CHECK:STDOUT:   %.loc10_13.2: %facet_type.a1a = converted Core.IntLiteral, %facet_value.loc10_13.2 [concrete = constants.%facet_value.399]
// CHECK:STDOUT:   %Buf.Set.specific_fn: <specific function> = specific_function %Set.ref, @Buf.Set(constants.%facet_value.7b6) [concrete = constants.%Buf.Set.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_13: <bound method> = bound_method %b.ref.loc10, %Buf.Set.specific_fn
// CHECK:STDOUT:   %.loc10_3: %Buf.e51 = acquire_value %b.ref.loc10
// CHECK:STDOUT:   %impl.elem0.loc10_9: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc10_9.1: <bound method> = bound_method %int_0.loc10, %impl.elem0.loc10_9 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc10_9: <specific function> = specific_function %impl.elem0.loc10_9, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc10_9.2: <bound method> = bound_method %int_0.loc10, %specific_fn.loc10_9 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_9: init %i64 = call %bound_method.loc10_9.2(%int_0.loc10) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc10_9.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_9 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc10_9.2: %i64 = converted %int_0.loc10, %.loc10_9.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %impl.elem0.loc10_12: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_12.1: <bound method> = bound_method %int_9, %impl.elem0.loc10_12 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.f46]
// CHECK:STDOUT:   %specific_fn.loc10_12: <specific function> = specific_function %impl.elem0.loc10_12, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc10_12.2: <bound method> = bound_method %int_9, %specific_fn.loc10_12 [concrete = constants.%bound_method.9bf]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_12: init %i32 = call %bound_method.loc10_12.2(%int_9) [concrete = constants.%int_9.056]
// CHECK:STDOUT:   %.loc10_12.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_12 [concrete = constants.%int_9.056]
// CHECK:STDOUT:   %.loc10_12.2: %i32 = converted %int_9, %.loc10_12.1 [concrete = constants.%int_9.056]
// CHECK:STDOUT:   %Buf.Set.call: init %empty_tuple.type = call %bound_method.loc10_13(%.loc10_3, %.loc10_9.2, %.loc10_12.2)
// CHECK:STDOUT:   %b.ref.loc11_10: ref %Buf.e51 = name_ref b, %b
// CHECK:STDOUT:   %int_0.loc11: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc11_12: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc11_12.1: <bound method> = bound_method %int_0.loc11, %impl.elem0.loc11_12 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc11_12: <specific function> = specific_function %impl.elem0.loc11_12, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc11_12.2: <bound method> = bound_method %int_0.loc11, %specific_fn.loc11_12 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_12: init %i64 = call %bound_method.loc11_12.2(%int_0.loc11) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc11_12.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_12 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc11_12.2: %i64 = converted %int_0.loc11, %.loc11_12.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %impl.elem1.loc11_13: %.964 = impl_witness_access constants.%IndexWith.impl_witness.b0f, element1 [concrete = constants.%Buf.as.IndexWith.impl.At.2e9]
// CHECK:STDOUT:   %bound_method.loc11_13.1: <bound method> = bound_method %b.ref.loc11_10, %impl.elem1.loc11_13
// CHECK:STDOUT:   %specific_fn.loc11_13: <specific function> = specific_function %impl.elem1.loc11_13, @Buf.as.IndexWith.impl.At(constants.%facet_value.7b6) [concrete = constants.%Buf.as.IndexWith.impl.At.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_13.2: <bound method> = bound_method %b.ref.loc11_10, %specific_fn.loc11_13
// CHECK:STDOUT:   %.loc11_10: %Buf.e51 = acquire_value %b.ref.loc11_10
// CHECK:STDOUT:   %Buf.as.IndexWith.impl.At.call: init %i32 = call %bound_method.loc11_13.2(%.loc11_10, %.loc11_12.2)
// CHECK:STDOUT:   %b.ref.loc11_17: ref %Buf.e51 = name_ref b, %b
// CHECK:STDOUT:   %.loc11_18: %Buf.Get.type.e5d = specific_constant imports.%Core.import_ref.6a6, @Buf(constants.%facet_value.7b6) [concrete = constants.%Buf.Get.0f8]
// CHECK:STDOUT:   %Get.ref: %Buf.Get.type.e5d = name_ref Get, %.loc11_18 [concrete = constants.%Buf.Get.0f8]
// CHECK:STDOUT:   %Buf.Get.bound: <bound method> = bound_method %b.ref.loc11_17, %Get.ref
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %Buf.Get.specific_fn: <specific function> = specific_function %Get.ref, @Buf.Get(constants.%facet_value.7b6) [concrete = constants.%Buf.Get.specific_fn.de2]
// CHECK:STDOUT:   %bound_method.loc11_24: <bound method> = bound_method %b.ref.loc11_17, %Buf.Get.specific_fn
// CHECK:STDOUT:   %.loc11_17: %Buf.e51 = acquire_value %b.ref.loc11_17
// CHECK:STDOUT:   %impl.elem0.loc11_23: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc11_23.1: <bound method> = bound_method %int_1, %impl.elem0.loc11_23 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:   %specific_fn.loc11_23: <specific function> = specific_function %impl.elem0.loc11_23, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc11_23.2: <bound method> = bound_method %int_1, %specific_fn.loc11_23 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_23: init %i64 = call %bound_method.loc11_23.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc11_23.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_23 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc11_23.2: %i64 = converted %int_1, %.loc11_23.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %Buf.Get.call: init %i32 = call %bound_method.loc11_24(%.loc11_17, %.loc11_23.2)
// CHECK:STDOUT:   %impl.elem1.loc11_15: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc11_15.1: <bound method> = bound_method %Buf.as.IndexWith.impl.At.call, %impl.elem1.loc11_15
// CHECK:STDOUT:   %specific_fn.loc11_15: <specific function> = specific_function %impl.elem1.loc11_15, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc11_15.2: <bound method> = bound_method %Buf.as.IndexWith.impl.At.call, %specific_fn.loc11_15
// CHECK:STDOUT:   %.loc11_13.1: %i32 = value_of_initializer %Buf.as.IndexWith.impl.At.call
// CHECK:STDOUT:   %.loc11_13.2: %i32 = converted %Buf.as.IndexWith.impl.At.call, %.loc11_13.1
// CHECK:STDOUT:   %.loc11_24.1: %i32 = value_of_initializer %Buf.Get.call
// CHECK:STDOUT:   %.loc11_24.2: %i32 = converted %Buf.Get.call, %.loc11_24.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc11_15.2(%.loc11_13.2, %.loc11_24.2)
// CHECK:STDOUT:   %Buf.as.Destroy.impl.Op.bound: <bound method> = bound_method %b.var, constants.%Buf.as.Destroy.impl.Op.305
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %bound_method.loc9_3: <bound method> = bound_method %b.var, %Buf.as.Destroy.impl.Op.specific_fn
// CHECK:STDOUT:   %Buf.as.Destroy.impl.Op.call: init %empty_tuple.type = call %bound_method.loc9_3(%b.var)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_22.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_22.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc9_49(%self.param: ref Core.IntLiteral) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: --- as_slice.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Buf.type: type = generic_class_type @Buf [concrete]
// CHECK:STDOUT:   %Buf.generic: %Buf.type = struct_value () [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %facet_type: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %T.dc4: %facet_type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Buf.AsSlice.type.58b: type = fn_type @Buf.AsSlice, @Buf(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.AsSlice.f5b: %Buf.AsSlice.type.58b = struct_value () [symbolic]
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc5_21.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type = facet_value %i32, (%Copy.impl_witness.b51, %custom_witness.df9cc1.2) [concrete]
// CHECK:STDOUT:   %Buf.e51: type = class_type @Buf, @Buf(%facet_value) [concrete]
// CHECK:STDOUT:   %pattern_type.6dd: type = pattern_type %Buf.e51 [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.6dd = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6dd = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %Slice.8ee: type = class_type @Slice, @Slice(%facet_value) [concrete]
// CHECK:STDOUT:   %.97d: Core.Form = init_form %Slice.8ee [concrete]
// CHECK:STDOUT:   %pattern_type.095: type = pattern_type %Slice.8ee [concrete]
// CHECK:STDOUT:   %return.param_patt.578: %pattern_type.095 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.cb0: %pattern_type.095 = return_slot_pattern %return.param_patt.578, %Slice.8ee [concrete]
// CHECK:STDOUT:   %S.type: type = fn_type @S [concrete]
// CHECK:STDOUT:   %S: %S.type = struct_value () [concrete]
// CHECK:STDOUT:   %Buf.AsSlice.type.37a: type = fn_type @Buf.AsSlice, @Buf(%facet_value) [concrete]
// CHECK:STDOUT:   %Buf.AsSlice.ae5: %Buf.AsSlice.type.37a = struct_value () [concrete]
// CHECK:STDOUT:   %Buf.AsSlice.specific_fn.6d8: <specific function> = specific_function %Buf.AsSlice.ae5, @Buf.AsSlice(%facet_value) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Buf = %Core.Buf
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Buf: %Buf.type = import_ref Core//prelude/types/buf, Buf, loaded [concrete = constants.%Buf.generic]
// CHECK:STDOUT:   %Core.import_ref.d5c: @Buf.%Buf.AsSlice.type (%Buf.AsSlice.type.58b) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.%Buf.AsSlice (constants.%Buf.AsSlice.f5b)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %S.decl: %S.type = fn_decl @S [concrete = constants.%S] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.6dd = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.6dd = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.095 = out_param_pattern [concrete = constants.%return.param_patt.578]
// CHECK:STDOUT:     %return.patt: %pattern_type.095 = return_slot_pattern %return.param_patt, %Slice [concrete = constants.%return.patt.cb0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc5_27: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:     %i32.loc5_38: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %facet_value.loc5_41: %facet_type = facet_value %i32.loc5_38, (constants.%Copy.impl_witness.b51, constants.%custom_witness.df9cc1.2) [concrete = constants.%facet_value]
// CHECK:STDOUT:     %.loc5_41.2: %facet_type = converted %i32.loc5_38, %facet_value.loc5_41 [concrete = constants.%facet_value]
// CHECK:STDOUT:     %Slice: type = class_type @Slice, @Slice(constants.%facet_value) [concrete = constants.%Slice.8ee]
// CHECK:STDOUT:     %.loc5_41.3: Core.Form = init_form %Slice [concrete = constants.%.97d]
// CHECK:STDOUT:     %b.param: %Buf.e51 = value_param call_param0
// CHECK:STDOUT:     %.loc5_21.1: type = splice_block %Buf [concrete = constants.%Buf.e51] {
// CHECK:STDOUT:       %Core.ref.loc5_9: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Buf.ref: %Buf.type = name_ref Buf, imports.%Core.Buf [concrete = constants.%Buf.generic]
// CHECK:STDOUT:       %i32.loc5_18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %facet_value.loc5_21: %facet_type = facet_value %i32.loc5_18, (constants.%Copy.impl_witness.b51, constants.%custom_witness.df9cc1.2) [concrete = constants.%facet_value]
// CHECK:STDOUT:       %.loc5_21.2: %facet_type = converted %i32.loc5_18, %facet_value.loc5_21 [concrete = constants.%facet_value]
// CHECK:STDOUT:       %Buf: type = class_type @Buf, @Buf(constants.%facet_value) [concrete = constants.%Buf.e51]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Buf.e51 = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %Slice.8ee = out_param call_param1
// CHECK:STDOUT:     %return: ref %Slice.8ee = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_21.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc5_21.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @S(%b.param: %Buf.e51) -> out %return.param: %Slice.8ee {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: %Buf.e51 = name_ref b, %b
// CHECK:STDOUT:   %.loc6: %Buf.AsSlice.type.37a = specific_constant imports.%Core.import_ref.d5c, @Buf(constants.%facet_value) [concrete = constants.%Buf.AsSlice.ae5]
// CHECK:STDOUT:   %AsSlice.ref: %Buf.AsSlice.type.37a = name_ref AsSlice, %.loc6 [concrete = constants.%Buf.AsSlice.ae5]
// CHECK:STDOUT:   %Buf.AsSlice.bound: <bound method> = bound_method %b.ref, %AsSlice.ref
// CHECK:STDOUT:   %Buf.AsSlice.specific_fn: <specific function> = specific_function %AsSlice.ref, @Buf.AsSlice(constants.%facet_value) [concrete = constants.%Buf.AsSlice.specific_fn.6d8]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %b.ref, %Buf.AsSlice.specific_fn
// CHECK:STDOUT:   %.loc5_41.1: ref %Slice.8ee = splice_block %return.param {}
// CHECK:STDOUT:   %Buf.AsSlice.call: init %Slice.8ee to %.loc5_41.1 = call %bound_method(%b.ref)
// CHECK:STDOUT:   return %Buf.AsSlice.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
