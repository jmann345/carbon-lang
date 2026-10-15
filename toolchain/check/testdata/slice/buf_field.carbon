// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/buf_field.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/buf_field.carbon

// Fork (UA-2, fork/upstream/plan.md §0.6 W-108 row): a `Core.Buf(i32)` held
// in a class FIELD, destroyed through the owner's `Destroy` witness at scope
// end — the pin for W-108 ("A `Core.Buf` stored in a field is not freed",
// docs/design/slices.md, 0.1 limits). The lower twin
// (lower/testdata/slice/buf_field.carbon) decides whether `free` is reached
// (R-3); this file pins the check-level shape. Dump ranges only around the
// function bodies, as buf.carbon does (W-121).

// --- synthesized_owner.carbon

library "[[@TEST_NAME]]";

// `Owner` declares no `Destroy` impl, so destroy lookup builds the
// synthesized witness: `CanDestroyClass` answers `NonTrivial` (the field walk
// finds `Buf(i32)`'s declared witness) and upstream's
// `MakeSubobjectDestroyOpBody` (PR 7840) calls `self.b.(Destroy.SelfDestruct)`
// for the field. Predicted at the end of `F`: the `Destroy.SelfDestruct`
// witness call on `o`; in `generated`, `Owner`'s `SubobjectDestroy` body with a
// `class_element_access` of `b` and a `SelfDestruct` call bound to it.
class Owner {
  var b: Core.Buf(i32);
}

//@dump-sem-ir-begin
fn F(n: i64) -> i32 {
  var o: Owner = {.b = Core.Buf(i32).Make(n, 7)};
  return o.b.Get(0);
}
//@dump-sem-ir-end

// --- declared_owner.carbon

library "[[@TEST_NAME]]";

// `OwnerWithOp` declares its own `Destroy` impl, so destroy lookup selects it
// (D-SL-16) and its `SubobjectDestroy` is the interface's `final` placeholder
// (upstream PR 7773's stated limit: no support for objects with non-trivial
// destruction). Predicted at the end of `G`: the declared-impl destroy
// sequence on `o` (the interface's `SelfDestruct` bound through the impl
// witness); no synthesized `SubobjectDestroy` body for `OwnerWithOp`, so no
// field walk and no `SelfDestruct` call on `b`.
class OwnerWithOp {
  var b: Core.Buf(i32);

  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

//@dump-sem-ir-begin
fn G(n: i64) -> i32 {
  var o: OwnerWithOp = {.b = Core.Buf(i32).Make(n, 7)};
  return o.b.Get(0);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- synthesized_owner.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Owner: type = class_type @Owner [concrete]
// CHECK:STDOUT:   %Buf.type: type = generic_class_type @Buf [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Buf.generic: %Buf.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %facet_type.a1a: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %T.dc4: %facet_type.a1a = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Buf.049: type = class_type @Buf, @Buf(%T.dc4) [symbolic]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
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
// CHECK:STDOUT:   %n.param_patt: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.f57 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %Buf.Get.type.49f: type = fn_type @Buf.Get, @Buf(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.Get.10a: %Buf.Get.type.49f = struct_value () [symbolic]
// CHECK:STDOUT:   %Buf.Make.type.057: type = fn_type @Buf.Make, @Buf(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.Make.623: %Buf.Make.type.057 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.730: %facet_type.a1a = facet_value %i32, (%Copy.impl_witness.b51, %custom_witness.f8f19d.1) [concrete]
// CHECK:STDOUT:   %Buf.cfb: type = class_type @Buf, @Buf(%facet_value.730) [concrete]
// CHECK:STDOUT:   %Buf.Make.type.a27: type = fn_type @Buf.Make, @Buf(%facet_value.730) [concrete]
// CHECK:STDOUT:   %Buf.Make.7bc: %Buf.Make.type.a27 = struct_value () [concrete]
// CHECK:STDOUT:   %Buf.Get.type.8d6: type = fn_type @Buf.Get, @Buf(%facet_value.730) [concrete]
// CHECK:STDOUT:   %Buf.Get.2c9: %Buf.Get.type.8d6 = struct_value () [concrete]
// CHECK:STDOUT:   %Owner.elem: type = unbound_element_type %Owner, %Buf.cfb [concrete]
// CHECK:STDOUT:   %struct_type.b.749: type = struct_type {.b: %Buf.cfb} [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.287: type = pattern_type %Owner [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.287 = ref_binding_pattern o [concrete]
// CHECK:STDOUT:   %o.var_patt: %pattern_type.287 = var_pattern %o.patt [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.0b3: <witness> = impl_witness imports.%Copy.impl_witness_table.ee5 [concrete]
// CHECK:STDOUT:   %self.param_patt.260: %pattern_type.dc0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.3a3: %pattern_type.dc0 = wrapper_binding_pattern self, %self.param_patt.260 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc17_47 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc17_47 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc17_47 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.2: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.2, %Destroy.WithSelf.SubobjectDestroy.d01daf.2, %Destroy.WithSelf.SelfDestruct.db3fdb.2), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.4f4: %facet_type.a1a = facet_value Core.IntLiteral, (%Copy.impl_witness.0b3, %custom_witness.f8f19d.2) [concrete]
// CHECK:STDOUT:   %Buf.Make.specific_fn: <specific function> = specific_function %Buf.Make.7bc, @Buf.Make(%facet_value.730) [concrete]
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
// CHECK:STDOUT:   %Buf.Get.specific_fn: <specific function> = specific_function %Buf.Get.2c9, @Buf.Get(%facet_value.730) [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.235: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet.235 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %Destroy.impl_witness.500: <witness> = impl_witness imports.%Destroy.impl_witness_table, @Buf.as.Destroy.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Destroy.facet.465: %Destroy.type = facet_value %Buf.049, (%Destroy.impl_witness.500) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fe0: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.465) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.517: %Destroy.WithSelf.SelfDestruct.type.fe0 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.6dc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.1, @Destroy.WithSelf(%Destroy.facet.465) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.9f7: %Destroy.WithSelf.SubobjectDestroy.type.6dc = struct_value () [symbolic]
// CHECK:STDOUT:   %Buf.as.Destroy.impl.Op.type.413: type = fn_type @Buf.as.Destroy.impl.Op, @Buf.as.Destroy.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.as.Destroy.impl.Op.674: %Buf.as.Destroy.impl.Op.type.413 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.impl_witness.7d0: <witness> = impl_witness imports.%Destroy.impl_witness_table, @Buf.as.Destroy.impl(%facet_value.730) [concrete]
// CHECK:STDOUT:   %Destroy.facet.240: %Destroy.type = facet_value %Buf.cfb, (%Destroy.impl_witness.7d0) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.3d2: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.240) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.3b2: %Destroy.WithSelf.SelfDestruct.type.3d2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.f82: type = pattern_type %struct_type.b.749 [concrete]
// CHECK:STDOUT:   %self.param_patt.c8c: %pattern_type.f82 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.0bc: %pattern_type.f82 = wrapper_binding_pattern self, %self.param_patt.c8c [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc17_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc17_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.003: %pattern_type.287 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.0d9: %pattern_type.287 = wrapper_binding_pattern self, %self.param_patt.003 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc17_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc17_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc17_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Buf = %Core.Buf
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Buf: %Buf.type = import_ref Core//prelude/types/buf, Buf, loaded [concrete = constants.%Buf.generic]
// CHECK:STDOUT:   %Core.import_ref.cbd: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/buf, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.cbd), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.fea: @Buf.%Buf.Make.type (%Buf.Make.type.057) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.%Buf.Make (constants.%Buf.Make.623)]
// CHECK:STDOUT:   %Core.import_ref.6a6: @Buf.%Buf.Get.type (%Buf.Get.type.49f) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.%Buf.Get (constants.%Buf.Get.10a)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.bbf3 = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.ee5 = impl_witness_table (%Core.import_ref.bbf3), @Core.IntLiteral.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.e15: @Buf.as.Destroy.impl.%Buf.as.Destroy.impl.Op.type (%Buf.as.Destroy.impl.Op.type.413) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.as.Destroy.impl.%Buf.as.Destroy.impl.Op (constants.%Buf.as.Destroy.impl.Op.674)]
// CHECK:STDOUT:   %Core.import_ref.2be: @Buf.as.Destroy.impl.%Destroy.WithSelf.SubobjectDestroy.type (%Destroy.WithSelf.SubobjectDestroy.type.6dc) = import_ref Core//prelude/types/buf, inst{{[0-9A-F]+}} [no loc], loaded [symbolic = @Buf.as.Destroy.impl.%Destroy.WithSelf.SubobjectDestroy (constants.%Destroy.WithSelf.SubobjectDestroy.9f7)]
// CHECK:STDOUT:   %Core.import_ref.7fc: @Buf.as.Destroy.impl.%Destroy.WithSelf.SelfDestruct.type (%Destroy.WithSelf.SelfDestruct.type.fe0) = import_ref Core//prelude/types/buf, inst{{[0-9A-F]+}} [no loc], loaded [symbolic = @Buf.as.Destroy.impl.%Destroy.WithSelf.SelfDestruct (constants.%Destroy.WithSelf.SelfDestruct.517)]
// CHECK:STDOUT:   %Destroy.impl_witness_table = impl_witness_table (%Core.import_ref.e15, %Core.import_ref.2be, %Core.import_ref.7fc), @Buf.as.Destroy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc17_47 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.dc0 = ref_param_pattern [concrete = constants.%self.param_patt.260]
// CHECK:STDOUT:     %self.patt: %pattern_type.dc0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.3a3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref Core.IntLiteral = ref_param call_param0
// CHECK:STDOUT:     %self: ref Core.IntLiteral = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc17_47 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.dc0 = ref_param_pattern [concrete = constants.%self.param_patt.260]
// CHECK:STDOUT:     %self.patt: %pattern_type.dc0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.3a3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref Core.IntLiteral = ref_param call_param0
// CHECK:STDOUT:     %self: ref Core.IntLiteral = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc17_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f82 = ref_param_pattern [concrete = constants.%self.param_patt.c8c]
// CHECK:STDOUT:     %self.patt: %pattern_type.f82 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.0bc]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.b.749 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.b.749 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc17_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f82 = ref_param_pattern [concrete = constants.%self.param_patt.c8c]
// CHECK:STDOUT:     %self.patt: %pattern_type.f82 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.0bc]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.b.749 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.b.749 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc17_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.287 = ref_param_pattern [concrete = constants.%self.param_patt.003]
// CHECK:STDOUT:     %self.patt: %pattern_type.287 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.0d9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Owner = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Owner = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc17_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.287 = ref_param_pattern [concrete = constants.%self.param_patt.003]
// CHECK:STDOUT:     %self.patt: %pattern_type.287 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.0d9]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Owner = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Owner = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.f57 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.f57 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc16 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc16: Core.Form = init_form %i32.loc16 [concrete = constants.%.795f]
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
// CHECK:STDOUT:   %o.var: ref %Owner = var_storage %o.var_patt
// CHECK:STDOUT:   %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Buf.ref: %Buf.type = name_ref Buf, imports.%Core.Buf [concrete = constants.%Buf.generic]
// CHECK:STDOUT:   %i32.loc17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %facet_value.loc17_36: %facet_type.a1a = facet_value %i32.loc17, (constants.%Copy.impl_witness.b51, constants.%custom_witness.f8f19d.1) [concrete = constants.%facet_value.730]
// CHECK:STDOUT:   %.loc17_36: %facet_type.a1a = converted %i32.loc17, %facet_value.loc17_36 [concrete = constants.%facet_value.730]
// CHECK:STDOUT:   %Buf: type = class_type @Buf, @Buf(constants.%facet_value.730) [concrete = constants.%Buf.cfb]
// CHECK:STDOUT:   %.loc17_37: %Buf.Make.type.a27 = specific_constant imports.%Core.import_ref.fea, @Buf(constants.%facet_value.730) [concrete = constants.%Buf.Make.7bc]
// CHECK:STDOUT:   %Make.ref: %Buf.Make.type.a27 = name_ref Make, %.loc17_37 [concrete = constants.%Buf.Make.7bc]
// CHECK:STDOUT:   %n.ref: %i64 = name_ref n, %n
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %facet_value.loc17_47.1: %facet_type.a1a = facet_value Core.IntLiteral, (constants.%Copy.impl_witness.0b3, constants.%custom_witness.f8f19d.2) [concrete = constants.%facet_value.4f4]
// CHECK:STDOUT:   %.loc17_47.1: %facet_type.a1a = converted Core.IntLiteral, %facet_value.loc17_47.1 [concrete = constants.%facet_value.4f4]
// CHECK:STDOUT:   %facet_value.loc17_47.2: %facet_type.a1a = facet_value Core.IntLiteral, (constants.%Copy.impl_witness.0b3, constants.%custom_witness.f8f19d.2) [concrete = constants.%facet_value.4f4]
// CHECK:STDOUT:   %.loc17_47.2: %facet_type.a1a = converted Core.IntLiteral, %facet_value.loc17_47.2 [concrete = constants.%facet_value.4f4]
// CHECK:STDOUT:   %Buf.Make.specific_fn: <specific function> = specific_function %Make.ref, @Buf.Make(constants.%facet_value.730) [concrete = constants.%Buf.Make.specific_fn]
// CHECK:STDOUT:   %.loc17_48.1: ref %Buf.cfb = class_element_access %o.var, element0
// CHECK:STDOUT:   %impl.elem0.loc17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_46.1: <bound method> = bound_method %int_7, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_46.2: <bound method> = bound_method %int_7, %specific_fn.loc17 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %i32 = call %bound_method.loc17_46.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc17_46.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc17_46.2: %i32 = converted %int_7, %.loc17_46.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %Buf.Make.call: init %Buf.cfb to %.loc17_48.1 = call %Buf.Make.specific_fn(%n.ref, %.loc17_46.2)
// CHECK:STDOUT:   %.loc17_48.2: %struct_type.b.749 = struct_literal (%Buf.Make.call)
// CHECK:STDOUT:   %.loc17_48.3: init %Owner to %o.var = class_init (%Buf.Make.call)
// CHECK:STDOUT:   %.loc17_3: init %Owner = converted %.loc17_48.2, %.loc17_48.3
// CHECK:STDOUT:   assign %o.var, %.loc17_3
// CHECK:STDOUT:   %Owner.ref: type = name_ref Owner, file.%Owner.decl [concrete = constants.%Owner]
// CHECK:STDOUT:   %o: ref %Owner = wrapper_binding o, %o.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %o.patt: %pattern_type.287 = ref_binding_pattern o [concrete = constants.%o.patt]
// CHECK:STDOUT:     %o.var_patt: %pattern_type.287 = var_pattern %o.patt [concrete = constants.%o.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %o.ref: ref %Owner = name_ref o, %o
// CHECK:STDOUT:   %b.ref: %Owner.elem = name_ref b, @Owner.%field_decl [concrete = @Owner.%field_decl]
// CHECK:STDOUT:   %.loc18_11.1: ref %Buf.cfb = class_element_access %o.ref, element0
// CHECK:STDOUT:   %.loc18_13: %Buf.Get.type.8d6 = specific_constant imports.%Core.import_ref.6a6, @Buf(constants.%facet_value.730) [concrete = constants.%Buf.Get.2c9]
// CHECK:STDOUT:   %Get.ref: %Buf.Get.type.8d6 = name_ref Get, %.loc18_13 [concrete = constants.%Buf.Get.2c9]
// CHECK:STDOUT:   %Buf.Get.bound: <bound method> = bound_method %.loc18_11.1, %Get.ref
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %Buf.Get.specific_fn: <specific function> = specific_function %Get.ref, @Buf.Get(constants.%facet_value.730) [concrete = constants.%Buf.Get.specific_fn]
// CHECK:STDOUT:   %bound_method.loc18_19: <bound method> = bound_method %.loc18_11.1, %Buf.Get.specific_fn
// CHECK:STDOUT:   %.loc18_11.2: %Buf.cfb = acquire_value %.loc18_11.1
// CHECK:STDOUT:   %impl.elem0.loc18: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc18_18.1: <bound method> = bound_method %int_0, %impl.elem0.loc18 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc18: <specific function> = specific_function %impl.elem0.loc18, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc18_18.2: <bound method> = bound_method %int_0, %specific_fn.loc18 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18: init %i64 = call %bound_method.loc18_18.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc18_18.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc18_18.2: %i64 = converted %int_0, %.loc18_18.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %Buf.Get.call: init %i32 = call %bound_method.loc18_19(%.loc18_11.2, %.loc18_18.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %o.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%o.var)
// CHECK:STDOUT:   return %Buf.Get.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc17_47(%self.param: ref Core.IntLiteral) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc17_47(%self.param: ref Core.IntLiteral) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc17_47(%self.param: ref Core.IntLiteral) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc17_3.1(%self.param: ref %struct_type.b.749) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc17_3.1: ref %Buf.cfb = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc17_3.1, constants.%Destroy.WithSelf.SelfDestruct.3b2
// CHECK:STDOUT:   %Destroy.facet.loc17_3.1: %Destroy.type = facet_value constants.%Buf.cfb, (constants.%Destroy.impl_witness.7d0) [concrete = constants.%Destroy.facet.240]
// CHECK:STDOUT:   %.loc17_3.2: %Destroy.type = converted constants.%Buf.cfb, %Destroy.facet.loc17_3.1 [concrete = constants.%Destroy.facet.240]
// CHECK:STDOUT:   %Destroy.facet.loc17_3.2: %Destroy.type = facet_value constants.%Buf.cfb, (constants.%Destroy.impl_witness.7d0) [concrete = constants.%Destroy.facet.240]
// CHECK:STDOUT:   %.loc17_3.3: %Destroy.type = converted constants.%Buf.cfb, %Destroy.facet.loc17_3.2 [concrete = constants.%Destroy.facet.240]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %.loc17_3.1, %Destroy.WithSelf.SelfDestruct.specific_fn
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method(%.loc17_3.1)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc17_3.1(%self.param: ref %struct_type.b.749) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc17_3.1(%self.param: ref %struct_type.b.749) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc17_3.2(%self.param: ref %Owner) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: %Owner.elem = name_ref b, @Owner.%field_decl [concrete = @Owner.%field_decl]
// CHECK:STDOUT:   %.loc17_3.1: ref %Buf.cfb = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc17_3.1, constants.%Destroy.WithSelf.SelfDestruct.3b2
// CHECK:STDOUT:   %Destroy.facet.loc17_3.1: %Destroy.type = facet_value constants.%Buf.cfb, (constants.%Destroy.impl_witness.7d0) [concrete = constants.%Destroy.facet.240]
// CHECK:STDOUT:   %.loc17_3.2: %Destroy.type = converted constants.%Buf.cfb, %Destroy.facet.loc17_3.1 [concrete = constants.%Destroy.facet.240]
// CHECK:STDOUT:   %Destroy.facet.loc17_3.2: %Destroy.type = facet_value constants.%Buf.cfb, (constants.%Destroy.impl_witness.7d0) [concrete = constants.%Destroy.facet.240]
// CHECK:STDOUT:   %.loc17_3.3: %Destroy.type = converted constants.%Buf.cfb, %Destroy.facet.loc17_3.2 [concrete = constants.%Destroy.facet.240]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %.loc17_3.1, %Destroy.WithSelf.SelfDestruct.specific_fn
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method(%.loc17_3.1)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc17_3.2(%self.param: ref %Owner) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc17_3.2(%self.param: ref %Owner) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- declared_owner.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OwnerWithOp: type = class_type @OwnerWithOp [concrete]
// CHECK:STDOUT:   %Buf.type: type = generic_class_type @Buf [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Buf.generic: %Buf.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %facet_type.a1a: type = facet_type <@Copy & @Destroy> [concrete]
// CHECK:STDOUT:   %T.dc4: %facet_type.a1a = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
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
// CHECK:STDOUT:   %n.param_patt: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.f57 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %Buf.Get.type.49f: type = fn_type @Buf.Get, @Buf(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.Get.10a: %Buf.Get.type.49f = struct_value () [symbolic]
// CHECK:STDOUT:   %Buf.Make.type.057: type = fn_type @Buf.Make, @Buf(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.Make.623: %Buf.Make.type.057 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.730: %facet_type.a1a = facet_value %i32, (%Copy.impl_witness.b51, %custom_witness.f8f19d.1) [concrete]
// CHECK:STDOUT:   %Buf.cfb: type = class_type @Buf, @Buf(%facet_value.730) [concrete]
// CHECK:STDOUT:   %Buf.Make.type.a27: type = fn_type @Buf.Make, @Buf(%facet_value.730) [concrete]
// CHECK:STDOUT:   %Buf.Make.7bc: %Buf.Make.type.a27 = struct_value () [concrete]
// CHECK:STDOUT:   %Buf.Get.type.8d6: type = fn_type @Buf.Get, @Buf(%facet_value.730) [concrete]
// CHECK:STDOUT:   %Buf.Get.2c9: %Buf.Get.type.8d6 = struct_value () [concrete]
// CHECK:STDOUT:   %OwnerWithOp.elem: type = unbound_element_type %OwnerWithOp, %Buf.cfb [concrete]
// CHECK:STDOUT:   %Destroy.impl_witness: <witness> = impl_witness @OwnerWithOp.as.Destroy.impl.%Destroy.impl_witness_table [concrete]
// CHECK:STDOUT:   %pattern_type.566: type = pattern_type %OwnerWithOp [concrete]
// CHECK:STDOUT:   %Destroy.facet.731: %Destroy.type = facet_value %OwnerWithOp, (%Destroy.impl_witness) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.77d: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.731) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.4dc: %Destroy.WithSelf.SelfDestruct.type.77d = struct_value () [concrete]
// CHECK:STDOUT:   %struct_type.b.749: type = struct_type {.b: %Buf.cfb} [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.566 = ref_binding_pattern o [concrete]
// CHECK:STDOUT:   %o.var_patt: %pattern_type.566 = var_pattern %o.patt [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.0b3: <witness> = impl_witness imports.%Copy.impl_witness_table.ee5 [concrete]
// CHECK:STDOUT:   %self.param_patt.260: %pattern_type.dc0 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.3a3: %pattern_type.dc0 = wrapper_binding_pattern self, %self.param_patt.260 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc21 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc21 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc21 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.2: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.2, %Destroy.WithSelf.SubobjectDestroy.d01daf.2, %Destroy.WithSelf.SelfDestruct.db3fdb.2), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.4f4: %facet_type.a1a = facet_value Core.IntLiteral, (%Copy.impl_witness.0b3, %custom_witness.f8f19d.2) [concrete]
// CHECK:STDOUT:   %Buf.Make.specific_fn: <specific function> = specific_function %Buf.Make.7bc, @Buf.Make(%facet_value.730) [concrete]
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
// CHECK:STDOUT:   %Buf.Get.specific_fn: <specific function> = specific_function %Buf.Get.2c9, @Buf.Get(%facet_value.730) [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.235: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet.235 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Buf = %Core.Buf
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Buf: %Buf.type = import_ref Core//prelude/types/buf, Buf, loaded [concrete = constants.%Buf.generic]
// CHECK:STDOUT:   %Core.import_ref.cbd: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/buf, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.cbd), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.fea: @Buf.%Buf.Make.type (%Buf.Make.type.057) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.%Buf.Make (constants.%Buf.Make.623)]
// CHECK:STDOUT:   %Core.import_ref.6a6: @Buf.%Buf.Get.type (%Buf.Get.type.49f) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.%Buf.Get (constants.%Buf.Get.10a)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.bbf3 = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.ee5 = impl_witness_table (%Core.import_ref.bbf3), @Core.IntLiteral.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc21 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.dc0 = ref_param_pattern [concrete = constants.%self.param_patt.260]
// CHECK:STDOUT:     %self.patt: %pattern_type.dc0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.3a3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref Core.IntLiteral = ref_param call_param0
// CHECK:STDOUT:     %self: ref Core.IntLiteral = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc21 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.dc0 = ref_param_pattern [concrete = constants.%self.param_patt.260]
// CHECK:STDOUT:     %self.patt: %pattern_type.dc0 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.3a3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref Core.IntLiteral = ref_param call_param0
// CHECK:STDOUT:     %self: ref Core.IntLiteral = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.f57 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.f57 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc20 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc20: Core.Form = init_form %i32.loc20 [concrete = constants.%.795f]
// CHECK:STDOUT:     %n.param: %i64 = value_param call_param0
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %n: %i64 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G(%n.param: %i64) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.var: ref %OwnerWithOp = var_storage %o.var_patt
// CHECK:STDOUT:   %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Buf.ref: %Buf.type = name_ref Buf, imports.%Core.Buf [concrete = constants.%Buf.generic]
// CHECK:STDOUT:   %i32.loc21: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %facet_value.loc21_42: %facet_type.a1a = facet_value %i32.loc21, (constants.%Copy.impl_witness.b51, constants.%custom_witness.f8f19d.1) [concrete = constants.%facet_value.730]
// CHECK:STDOUT:   %.loc21_42: %facet_type.a1a = converted %i32.loc21, %facet_value.loc21_42 [concrete = constants.%facet_value.730]
// CHECK:STDOUT:   %Buf: type = class_type @Buf, @Buf(constants.%facet_value.730) [concrete = constants.%Buf.cfb]
// CHECK:STDOUT:   %.loc21_43: %Buf.Make.type.a27 = specific_constant imports.%Core.import_ref.fea, @Buf(constants.%facet_value.730) [concrete = constants.%Buf.Make.7bc]
// CHECK:STDOUT:   %Make.ref: %Buf.Make.type.a27 = name_ref Make, %.loc21_43 [concrete = constants.%Buf.Make.7bc]
// CHECK:STDOUT:   %n.ref: %i64 = name_ref n, %n
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %facet_value.loc21_53.1: %facet_type.a1a = facet_value Core.IntLiteral, (constants.%Copy.impl_witness.0b3, constants.%custom_witness.f8f19d.2) [concrete = constants.%facet_value.4f4]
// CHECK:STDOUT:   %.loc21_53.1: %facet_type.a1a = converted Core.IntLiteral, %facet_value.loc21_53.1 [concrete = constants.%facet_value.4f4]
// CHECK:STDOUT:   %facet_value.loc21_53.2: %facet_type.a1a = facet_value Core.IntLiteral, (constants.%Copy.impl_witness.0b3, constants.%custom_witness.f8f19d.2) [concrete = constants.%facet_value.4f4]
// CHECK:STDOUT:   %.loc21_53.2: %facet_type.a1a = converted Core.IntLiteral, %facet_value.loc21_53.2 [concrete = constants.%facet_value.4f4]
// CHECK:STDOUT:   %Buf.Make.specific_fn: <specific function> = specific_function %Make.ref, @Buf.Make(constants.%facet_value.730) [concrete = constants.%Buf.Make.specific_fn]
// CHECK:STDOUT:   %.loc21_54.1: ref %Buf.cfb = class_element_access %o.var, element0
// CHECK:STDOUT:   %impl.elem0.loc21: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc21_52.1: <bound method> = bound_method %int_7, %impl.elem0.loc21 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc21: <specific function> = specific_function %impl.elem0.loc21, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc21_52.2: <bound method> = bound_method %int_7, %specific_fn.loc21 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21: init %i32 = call %bound_method.loc21_52.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc21_52.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc21 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc21_52.2: %i32 = converted %int_7, %.loc21_52.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %Buf.Make.call: init %Buf.cfb to %.loc21_54.1 = call %Buf.Make.specific_fn(%n.ref, %.loc21_52.2)
// CHECK:STDOUT:   %.loc21_54.2: %struct_type.b.749 = struct_literal (%Buf.Make.call)
// CHECK:STDOUT:   %.loc21_54.3: init %OwnerWithOp to %o.var = class_init (%Buf.Make.call)
// CHECK:STDOUT:   %.loc21_3.1: init %OwnerWithOp = converted %.loc21_54.2, %.loc21_54.3
// CHECK:STDOUT:   assign %o.var, %.loc21_3.1
// CHECK:STDOUT:   %OwnerWithOp.ref: type = name_ref OwnerWithOp, file.%OwnerWithOp.decl [concrete = constants.%OwnerWithOp]
// CHECK:STDOUT:   %o: ref %OwnerWithOp = wrapper_binding o, %o.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %o.patt: %pattern_type.566 = ref_binding_pattern o [concrete = constants.%o.patt]
// CHECK:STDOUT:     %o.var_patt: %pattern_type.566 = var_pattern %o.patt [concrete = constants.%o.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %o.ref: ref %OwnerWithOp = name_ref o, %o
// CHECK:STDOUT:   %b.ref: %OwnerWithOp.elem = name_ref b, @OwnerWithOp.%field_decl [concrete = @OwnerWithOp.%field_decl]
// CHECK:STDOUT:   %.loc22_11.1: ref %Buf.cfb = class_element_access %o.ref, element0
// CHECK:STDOUT:   %.loc22_13: %Buf.Get.type.8d6 = specific_constant imports.%Core.import_ref.6a6, @Buf(constants.%facet_value.730) [concrete = constants.%Buf.Get.2c9]
// CHECK:STDOUT:   %Get.ref: %Buf.Get.type.8d6 = name_ref Get, %.loc22_13 [concrete = constants.%Buf.Get.2c9]
// CHECK:STDOUT:   %Buf.Get.bound: <bound method> = bound_method %.loc22_11.1, %Get.ref
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %Buf.Get.specific_fn: <specific function> = specific_function %Get.ref, @Buf.Get(constants.%facet_value.730) [concrete = constants.%Buf.Get.specific_fn]
// CHECK:STDOUT:   %bound_method.loc22_19: <bound method> = bound_method %.loc22_11.1, %Buf.Get.specific_fn
// CHECK:STDOUT:   %.loc22_11.2: %Buf.cfb = acquire_value %.loc22_11.1
// CHECK:STDOUT:   %impl.elem0.loc22: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc22_18.1: <bound method> = bound_method %int_0, %impl.elem0.loc22 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc22: <specific function> = specific_function %impl.elem0.loc22, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc22_18.2: <bound method> = bound_method %int_0, %specific_fn.loc22 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22: init %i64 = call %bound_method.loc22_18.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc22_18.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc22_18.2: %i64 = converted %int_0, %.loc22_18.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %Buf.Get.call: init %i32 = call %bound_method.loc22_19(%.loc22_11.2, %.loc22_18.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %o.var, constants.%Destroy.WithSelf.SelfDestruct.4dc
// CHECK:STDOUT:   %Destroy.facet.loc21_3.1: %Destroy.type = facet_value constants.%OwnerWithOp, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet.731]
// CHECK:STDOUT:   %.loc21_3.2: %Destroy.type = converted constants.%OwnerWithOp, %Destroy.facet.loc21_3.1 [concrete = constants.%Destroy.facet.731]
// CHECK:STDOUT:   %Destroy.facet.loc21_3.2: %Destroy.type = facet_value constants.%OwnerWithOp, (constants.%Destroy.impl_witness) [concrete = constants.%Destroy.facet.731]
// CHECK:STDOUT:   %.loc21_3.3: %Destroy.type = converted constants.%OwnerWithOp, %Destroy.facet.loc21_3.2 [concrete = constants.%Destroy.facet.731]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %bound_method.loc21_3: <bound method> = bound_method %o.var, %Destroy.WithSelf.SelfDestruct.specific_fn
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method.loc21_3(%o.var)
// CHECK:STDOUT:   return %Buf.Get.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc21(%self.param: ref Core.IntLiteral) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc21(%self.param: ref Core.IntLiteral) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc21(%self.param: ref Core.IntLiteral) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
