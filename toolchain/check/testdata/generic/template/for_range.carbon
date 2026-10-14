// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/for_range.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/for_range.carbon

// --- range_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}
//@dump-sem-ir-end

// --- range_param_called_array.carbon
library "[[@TEST_NAME]]";

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Use(a: array(i32, 3)) -> i32 {
  return Sum(a);
}

// --- range_member_array.carbon
library "[[@TEST_NAME]]";

class W {
  var a: array(i32, 3);
}

fn F[template T: type](w: T) -> i32 {
  var s: i32 = 0;
  for (e: i32 in w.a) {
    s += e;
  }
  return s;
}

fn Use(w: W) -> i32 {
  return F(w);
}

// --- range_core_range.carbon
library "[[@TEST_NAME]]";

class W {
  var n: i32;
}

fn Count[template T: type](w: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in Core.Range(w.n)) {
    s += x;
  }
  return s;
}

fn Use(w: W) -> i32 {
  return Count(w);
}

// --- range_dependent_bound.carbon
library "[[@TEST_NAME]]";

fn Sum(template N: i32, a: array(i32, N)) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Use(a: array(i32, 3)) -> i32 {
  return Sum(3, a);
}

// CHECK:STDOUT: --- range_param.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.51d1c4.1 = value_param_pattern [template]
// CHECK:STDOUT:   %a.patt: %pattern_type.51d1c4.1 = wrapper_binding_pattern a, %a.param_patt [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Sum.type: type = fn_type @Sum [concrete]
// CHECK:STDOUT:   %Sum: %Sum.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %s.patt: %pattern_type.6b6 = ref_binding_pattern s [concrete]
// CHECK:STDOUT:   %s.var_patt: %pattern_type.6b6 = var_pattern %s.patt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.2: type = class_type @Int, @Int(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.037: type = facet_type <@IntFitsIn, @IntFitsIn(%Int.67af24.2) & @AnyInt> [symbolic]
// CHECK:STDOUT:   %From.6a4: %facet_type.037 = symbolic_binding From, 1 [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7fa: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%To, %From.6a4) [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.643: %From.as_type.as.ImplicitAs.impl.Convert.type.7fa = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Self.0e7: %Destroy.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.4e5: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Self.0e7) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.4a0: %Destroy.WithSelf.SelfDestruct.type.4e5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Iterate.assoc_type: type = assoc_entity_type @Iterate [concrete]
// CHECK:STDOUT:   %assoc2.10f: %Iterate.assoc_type = assoc_entity element2, imports.%Core.import_ref.d55 [concrete]
// CHECK:STDOUT:   %.8cb5e6.1: type = type_of_inst @Sum.%.loc6_19.25 [template]
// CHECK:STDOUT:   %.c234ea.1: %.8cb5e6.1 = splice_inst @Sum.%.loc6_19.25 [template]
// CHECK:STDOUT:   %.57c638.1: type = type_of_inst @Sum.%.loc6_19.28 [template]
// CHECK:STDOUT:   %.e63d45.1: %.57c638.1 = splice_inst @Sum.%.loc6_19.28 [template]
// CHECK:STDOUT:   %require_complete.a7a: <witness> = require_complete_type %.57c638.1 [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.13d: %.57c638.1 = splice_inst @Sum.%tuple.elem0 [template]
// CHECK:STDOUT:   %ptr.194: type = ptr_type %.57c638.1 [template]
// CHECK:STDOUT:   %require_complete.ddb: <witness> = require_complete_type %ptr.194 [template]
// CHECK:STDOUT:   %assoc3: %Iterate.assoc_type = assoc_entity element3, imports.%Core.import_ref.48d [concrete]
// CHECK:STDOUT:   %.8cb5e6.2: type = type_of_inst @Sum.%.loc6_19.33 [template]
// CHECK:STDOUT:   %.c234ea.2: %.8cb5e6.2 = splice_inst @Sum.%.loc6_19.33 [template]
// CHECK:STDOUT:   %.271: type = type_of_inst @Sum.%.loc6_19.36 [template]
// CHECK:STDOUT:   %.088: %.271 = splice_inst @Sum.%.loc6_19.36 [template]
// CHECK:STDOUT:   %require_complete.d53: <witness> = require_complete_type %.271 [template]
// CHECK:STDOUT:   %.ea4: %.271 = splice_inst @Sum.%.loc6_19.39 [template]
// CHECK:STDOUT:   %.c99: type = type_of_inst @Sum.%.loc6_19.41 [template]
// CHECK:STDOUT:   %.f7f: %.c99 = splice_inst @Sum.%.loc6_19.41 [template]
// CHECK:STDOUT:   %.5ee: type = type_of_inst @Sum.%.loc6_19.44 [template]
// CHECK:STDOUT:   %.711: %.5ee = splice_inst @Sum.%.loc6_19.44 [template]
// CHECK:STDOUT:   %.498: bool = splice_inst @Sum.%.loc6_19.47 [template]
// CHECK:STDOUT:   %.1c3: type = type_of_inst @Sum.%.loc6_19.49 [template]
// CHECK:STDOUT:   %.3a7: %.1c3 = splice_inst @Sum.%.loc6_19.49 [template]
// CHECK:STDOUT:   %.c54: type = type_of_inst @Sum.%.loc6_19.52 [template]
// CHECK:STDOUT:   %.424: %.c54 = splice_inst @Sum.%.loc6_19.52 [template]
// CHECK:STDOUT:   %.6ec: %i32 = splice_inst @Sum.%.loc6_19.55 [template]
// CHECK:STDOUT:   %AddAssignWith.type.941: type = facet_type <@AddAssignWith, @AddAssignWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.type.a58fbe.1: type = fn_type @Int.as.AddAssignWith.impl.Op.1, @Int.as.AddAssignWith.impl(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.45b360.1: %Int.as.AddAssignWith.impl.Op.type.a58fbe.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.type.a58fbe.2: type = fn_type @Int.as.AddAssignWith.impl.Op.2, @Int.as.AddAssignWith.impl(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.45b360.2: %Int.as.AddAssignWith.impl.Op.type.a58fbe.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.138: type = facet_type <@IntFitsIn, @IntFitsIn(%i32) & @AnyInt> [concrete]
// CHECK:STDOUT:   %custom_witness.36a: <witness> = custom_witness (), @IntFitsIn, @IntFitsIn(%i32) [concrete]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.type.f15: type = fn_type @Int.as.AnyInt.impl.AsInt, @Int.as.AnyInt.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.d10: %Int.as.AnyInt.impl.AsInt.type.f15 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %AnyInt.impl_witness.48c: <witness> = impl_witness imports.%AnyInt.impl_witness_table, @Int.as.AnyInt.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.138 = facet_value %i32, (%custom_witness.36a, %AnyInt.impl_witness.48c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.1d8: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.992, @From.as_type.as.ImplicitAs.impl(%int_32, %facet_value) [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.e88: %ImplicitAs.type.914 = facet_value %i32, (%ImplicitAs.impl_witness.1d8) [concrete]
// CHECK:STDOUT:   %AddAssignWith.impl_witness.e9d: <witness> = impl_witness imports.%AddAssignWith.impl_witness_table, @Int.as.AddAssignWith.impl(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.type.0b80aa.1: type = fn_type @Int.as.AddAssignWith.impl.Op.2, @Int.as.AddAssignWith.impl(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.d34738.1: %Int.as.AddAssignWith.impl.Op.type.0b80aa.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.type.0b80aa.2: type = fn_type @Int.as.AddAssignWith.impl.Op.1, @Int.as.AddAssignWith.impl(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.d34738.2: %Int.as.AddAssignWith.impl.Op.type.0b80aa.2 = struct_value () [concrete]
// CHECK:STDOUT:   %AddAssignWith.facet.e5e: %AddAssignWith.type.941 = facet_value %i32, (%AddAssignWith.impl_witness.e9d) [concrete]
// CHECK:STDOUT:   %AddAssignWith.WithSelf.Op.type.640: type = fn_type @AddAssignWith.WithSelf.Op, @AddAssignWith.WithSelf(%i32, %AddAssignWith.facet.e5e) [concrete]
// CHECK:STDOUT:   %.004: type = fn_type_with_self_type %AddAssignWith.WithSelf.Op.type.640, %AddAssignWith.facet.e5e [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.specific_fn.d76216.1: <specific function> = specific_function %Int.as.AddAssignWith.impl.Op.d34738.2, @Int.as.AddAssignWith.impl.Op.1(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.specific_fn.d76216.2: <specific function> = specific_function %Int.as.AddAssignWith.impl.Op.d34738.1, @Int.as.AddAssignWith.impl.Op.2(%int_32, %ImplicitAs.facet.e88) [concrete]
// CHECK:STDOUT:   %Destroy.assoc_type: type = assoc_entity_type @Destroy [concrete]
// CHECK:STDOUT:   %assoc2.d28: %Destroy.assoc_type = assoc_entity element2, imports.%Core.import_ref.f0e4 [concrete]
// CHECK:STDOUT:   %.8cb5e6.3: type = type_of_inst @Sum.%.loc6_19.57 [template]
// CHECK:STDOUT:   %.c234ea.3: %.8cb5e6.3 = splice_inst @Sum.%.loc6_19.57 [template]
// CHECK:STDOUT:   %.57c638.2: type = type_of_inst @Sum.%.loc6_19.60 [template]
// CHECK:STDOUT:   %.e63d45.2: %.57c638.2 = splice_inst @Sum.%.loc6_19.60 [template]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.2a4: @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert.type (%From.as_type.as.ImplicitAs.impl.Convert.type.7fa) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert (constants.%From.as_type.as.ImplicitAs.impl.Convert.643)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.992 = impl_witness_table (%Core.import_ref.2a4), @From.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.d55 = import_ref Core//prelude/iterate, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.48d = import_ref Core//prelude/iterate, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.098: @Int.as.AddAssignWith.impl.%Int.as.AddAssignWith.impl.Op.type.2 (%Int.as.AddAssignWith.impl.Op.type.a58fbe.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddAssignWith.impl.%Int.as.AddAssignWith.impl.Op.2 (constants.%Int.as.AddAssignWith.impl.Op.45b360.1)]
// CHECK:STDOUT:   %AddAssignWith.impl_witness_table = impl_witness_table (%Core.import_ref.098), @Int.as.AddAssignWith.impl [concrete]
// CHECK:STDOUT:   %Core.Op.1b1: @Int.as.AddAssignWith.impl.%Int.as.AddAssignWith.impl.Op.type.1 (%Int.as.AddAssignWith.impl.Op.type.a58fbe.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddAssignWith.impl.%Int.as.AddAssignWith.impl.Op.1 (constants.%Int.as.AddAssignWith.impl.Op.45b360.2)]
// CHECK:STDOUT:   %Core.import_ref.47b: Core.IntLiteral = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%N (constants.%N)]
// CHECK:STDOUT:   %Core.import_ref.49b: @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt.type (%Int.as.AnyInt.impl.AsInt.type.f15) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt (constants.%Int.as.AnyInt.impl.AsInt.d10)]
// CHECK:STDOUT:   %AnyInt.impl_witness_table = impl_witness_table (%Core.import_ref.47b, %Core.import_ref.49b), @Int.as.AnyInt.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.f0e4: @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct.type (%Destroy.WithSelf.SelfDestruct.type.4e5) = import_ref Core//prelude/iterate, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct (constants.%Destroy.WithSelf.SelfDestruct.4a0)]
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
// CHECK:STDOUT:   %Sum.decl: %Sum.type = fn_decl @Sum [concrete = constants.%Sum] {
// CHECK:STDOUT:     %T.patt.loc4_18.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_18.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %a.param_patt.loc4_27.1: @Sum.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %a.param_patt.loc4_27.2 (constants.%a.param_patt)]
// CHECK:STDOUT:     %a.patt.loc4_27.1: @Sum.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern a, %a.param_patt.loc4_27.1 [template = %a.patt.loc4_27.2 (constants.%a.patt)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc4 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc4: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_35: Core.Form = init_form %i32.loc4 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc4_20.1: type = splice_block %.loc4_20.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_20.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_18.2: type = symbolic_binding T, 0, template [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %a.param: @Sum.%T.loc4_18.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc4_18.2 [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %a: @Sum.%T.loc4_18.1 (%T.67db0b.1) = wrapper_binding a, %a.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Sum(%T.loc4_18.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_18.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_18.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc4_18.1: type = symbolic_binding T, 0, template [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_18.1 [template = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %a.param_patt.loc4_27.2: @Sum.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %a.param_patt.loc4_27.2 (constants.%a.param_patt)]
// CHECK:STDOUT:   %a.patt.loc4_27.2: @Sum.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern a, %a.param_patt.loc4_27.2 [template = %a.patt.loc4_27.2 (constants.%a.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4: <witness> = require_complete_type %T.loc4_18.1 [template = %require_complete.loc4 (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc6_19.25: <instruction> = compound_member_access_action %a.ref, constants.%assoc2.10f [template]
// CHECK:STDOUT:   %.loc6_19.26: type = type_of_inst %.loc6_19.25 [template = %.loc6_19.26 (constants.%.8cb5e6.1)]
// CHECK:STDOUT:   %.loc6_19.27: @Sum.%.loc6_19.26 (%.8cb5e6.1) = splice_inst %.loc6_19.25 [template = %.loc6_19.27 (constants.%.c234ea.1)]
// CHECK:STDOUT:   %.loc6_19.28: <instruction> = call_action (%.loc6_19.2), true [template]
// CHECK:STDOUT:   %.loc6_19.29: type = type_of_inst %.loc6_19.28 [template = %.loc6_19.29 (constants.%.57c638.1)]
// CHECK:STDOUT:   %.loc6_19.30: @Sum.%.loc6_19.29 (%.57c638.1) = splice_inst %.loc6_19.28 [template = %.loc6_19.30 (constants.%.e63d45.1)]
// CHECK:STDOUT:   %require_complete.loc6_19.1: <witness> = require_complete_type %.loc6_19.29 [template = %require_complete.loc6_19.1 (constants.%require_complete.a7a)]
// CHECK:STDOUT:   %.loc6_19.31: %tuple.type.f7a = initialize_action %.loc6_19.4, %.loc6_19.29, %var, false [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc6_19.31, element0 [template]
// CHECK:STDOUT:   %.loc6_19.32: @Sum.%.loc6_19.29 (%.57c638.1) = splice_inst %tuple.elem0 [template = %.loc6_19.32 (constants.%.13d)]
// CHECK:STDOUT:   %ptr: type = ptr_type %.loc6_19.29 [template = %ptr (constants.%ptr.194)]
// CHECK:STDOUT:   %require_complete.loc6_19.2: <witness> = require_complete_type %ptr [template = %require_complete.loc6_19.2 (constants.%require_complete.ddb)]
// CHECK:STDOUT:   %.loc6_19.33: <instruction> = compound_member_access_action %a.ref, constants.%assoc3 [template]
// CHECK:STDOUT:   %.loc6_19.34: type = type_of_inst %.loc6_19.33 [template = %.loc6_19.34 (constants.%.8cb5e6.2)]
// CHECK:STDOUT:   %.loc6_19.35: @Sum.%.loc6_19.34 (%.8cb5e6.2) = splice_inst %.loc6_19.33 [template = %.loc6_19.35 (constants.%.c234ea.2)]
// CHECK:STDOUT:   %.loc6_19.36: <instruction> = call_action (%.loc6_19.7, %addr), true [template]
// CHECK:STDOUT:   %.loc6_19.37: type = type_of_inst %.loc6_19.36 [template = %.loc6_19.37 (constants.%.271)]
// CHECK:STDOUT:   %.loc6_19.38: @Sum.%.loc6_19.37 (%.271) = splice_inst %.loc6_19.36 [template = %.loc6_19.38 (constants.%.088)]
// CHECK:STDOUT:   %require_complete.loc6_19.3: <witness> = require_complete_type %.loc6_19.37 [template = %require_complete.loc6_19.3 (constants.%require_complete.d53)]
// CHECK:STDOUT:   %.loc6_19.39: <instruction> = convert_to_category_action %.loc6_19.9, element2 [template]
// CHECK:STDOUT:   %.loc6_19.40: @Sum.%.loc6_19.37 (%.271) = splice_inst %.loc6_19.39 [template = %.loc6_19.40 (constants.%.ea4)]
// CHECK:STDOUT:   %.loc6_19.41: <instruction> = access_member_action %.loc6_19.10, HasValue [template]
// CHECK:STDOUT:   %.loc6_19.42: type = type_of_inst %.loc6_19.41 [template = %.loc6_19.42 (constants.%.c99)]
// CHECK:STDOUT:   %.loc6_19.43: @Sum.%.loc6_19.42 (%.c99) = splice_inst %.loc6_19.41 [template = %.loc6_19.43 (constants.%.f7f)]
// CHECK:STDOUT:   %.loc6_19.44: <instruction> = call_action (%.loc6_19.12), false [template]
// CHECK:STDOUT:   %.loc6_19.45: type = type_of_inst %.loc6_19.44 [template = %.loc6_19.45 (constants.%.5ee)]
// CHECK:STDOUT:   %.loc6_19.46: @Sum.%.loc6_19.45 (%.5ee) = splice_inst %.loc6_19.44 [template = %.loc6_19.46 (constants.%.711)]
// CHECK:STDOUT:   %.loc6_19.47: <instruction> = convert_to_value_action %.loc6_19.14, bool [template]
// CHECK:STDOUT:   %.loc6_19.48: bool = splice_inst %.loc6_19.47 [template = %.loc6_19.48 (constants.%.498)]
// CHECK:STDOUT:   %.loc6_19.49: <instruction> = access_member_action %.loc6_19.10, Get [template]
// CHECK:STDOUT:   %.loc6_19.50: type = type_of_inst %.loc6_19.49 [template = %.loc6_19.50 (constants.%.1c3)]
// CHECK:STDOUT:   %.loc6_19.51: @Sum.%.loc6_19.50 (%.1c3) = splice_inst %.loc6_19.49 [template = %.loc6_19.51 (constants.%.3a7)]
// CHECK:STDOUT:   %.loc6_19.52: <instruction> = call_action (%.loc6_19.17), false [template]
// CHECK:STDOUT:   %.loc6_19.53: type = type_of_inst %.loc6_19.52 [template = %.loc6_19.53 (constants.%.c54)]
// CHECK:STDOUT:   %.loc6_19.54: @Sum.%.loc6_19.53 (%.c54) = splice_inst %.loc6_19.52 [template = %.loc6_19.54 (constants.%.424)]
// CHECK:STDOUT:   %.loc6_19.55: <instruction> = convert_to_value_action %.loc6_19.19, constants.%i32 [template]
// CHECK:STDOUT:   %.loc6_19.56: %i32 = splice_inst %.loc6_19.55 [template = %.loc6_19.56 (constants.%.6ec)]
// CHECK:STDOUT:   %.loc6_19.57: <instruction> = compound_member_access_action %var, constants.%assoc2.d28 [template]
// CHECK:STDOUT:   %.loc6_19.58: type = type_of_inst %.loc6_19.57 [template = %.loc6_19.58 (constants.%.8cb5e6.3)]
// CHECK:STDOUT:   %.loc6_19.59: @Sum.%.loc6_19.58 (%.8cb5e6.3) = splice_inst %.loc6_19.57 [template = %.loc6_19.59 (constants.%.c234ea.3)]
// CHECK:STDOUT:   %.loc6_19.60: <instruction> = call_action (%.loc6_19.22), true [template]
// CHECK:STDOUT:   %.loc6_19.61: type = type_of_inst %.loc6_19.60 [template = %.loc6_19.61 (constants.%.57c638.2)]
// CHECK:STDOUT:   %.loc6_19.62: @Sum.%.loc6_19.61 (%.57c638.2) = splice_inst %.loc6_19.60 [template = %.loc6_19.62 (constants.%.e63d45.2)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%a.param: @Sum.%T.loc4_18.1 (%T.67db0b.1)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %s.var: ref %i32 = var_storage %s.var_patt
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc5: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc5_3.1: <bound method> = bound_method %int_0, %impl.elem0.loc5 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:     %specific_fn.loc5: <specific function> = specific_function %impl.elem0.loc5, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc5_3.2: <bound method> = bound_method %int_0, %specific_fn.loc5 [concrete = constants.%bound_method]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc5_3.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc5: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     assign %s.var, %.loc5
// CHECK:STDOUT:     %i32.loc5: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %s: ref %i32 = wrapper_binding s, %s.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %s.patt: %pattern_type.6b6 = ref_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:       %s.var_patt: %pattern_type.6b6 = var_pattern %s.patt [concrete = constants.%s.var_patt]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %x.patt: %pattern_type.6b6 = value_binding_pattern x [concrete = constants.%x.patt]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a.ref: @Sum.%T.loc4_18.1 (%T.67db0b.1) = name_ref a, %a
// CHECK:STDOUT:     %.loc6_19.1: type = type_of_inst %.loc6_19.25 [template = %.loc6_19.26 (constants.%.8cb5e6.1)]
// CHECK:STDOUT:     %.loc6_19.2: @Sum.%.loc6_19.26 (%.8cb5e6.1) = splice_inst %.loc6_19.25 [template = %.loc6_19.27 (constants.%.c234ea.1)]
// CHECK:STDOUT:     %.loc6_19.3: type = type_of_inst %.loc6_19.28 [template = %.loc6_19.29 (constants.%.57c638.1)]
// CHECK:STDOUT:     %.loc6_19.4: @Sum.%.loc6_19.29 (%.57c638.1) = splice_inst %.loc6_19.28 [template = %.loc6_19.30 (constants.%.e63d45.1)]
// CHECK:STDOUT:     %var: ref @Sum.%.loc6_19.29 (%.57c638.1) = var_storage invalid
// CHECK:STDOUT:     %.loc6_19.5: @Sum.%.loc6_19.29 (%.57c638.1) = splice_inst %tuple.elem0 [template = %.loc6_19.32 (constants.%.13d)]
// CHECK:STDOUT:     assign %var, %.loc6_19.5
// CHECK:STDOUT:     br !for.next
// CHECK:STDOUT:
// CHECK:STDOUT:   !for.next:
// CHECK:STDOUT:     %addr: @Sum.%ptr (%ptr.194) = addr_of %var
// CHECK:STDOUT:     %.loc6_19.6: type = type_of_inst %.loc6_19.33 [template = %.loc6_19.34 (constants.%.8cb5e6.2)]
// CHECK:STDOUT:     %.loc6_19.7: @Sum.%.loc6_19.34 (%.8cb5e6.2) = splice_inst %.loc6_19.33 [template = %.loc6_19.35 (constants.%.c234ea.2)]
// CHECK:STDOUT:     %.loc6_19.8: type = type_of_inst %.loc6_19.36 [template = %.loc6_19.37 (constants.%.271)]
// CHECK:STDOUT:     %.loc6_19.9: @Sum.%.loc6_19.37 (%.271) = splice_inst %.loc6_19.36 [template = %.loc6_19.38 (constants.%.088)]
// CHECK:STDOUT:     %.loc6_19.10: @Sum.%.loc6_19.37 (%.271) = splice_inst %.loc6_19.39 [template = %.loc6_19.40 (constants.%.ea4)]
// CHECK:STDOUT:     %.loc6_19.11: type = type_of_inst %.loc6_19.41 [template = %.loc6_19.42 (constants.%.c99)]
// CHECK:STDOUT:     %.loc6_19.12: @Sum.%.loc6_19.42 (%.c99) = splice_inst %.loc6_19.41 [template = %.loc6_19.43 (constants.%.f7f)]
// CHECK:STDOUT:     %.loc6_19.13: type = type_of_inst %.loc6_19.44 [template = %.loc6_19.45 (constants.%.5ee)]
// CHECK:STDOUT:     %.loc6_19.14: @Sum.%.loc6_19.45 (%.5ee) = splice_inst %.loc6_19.44 [template = %.loc6_19.46 (constants.%.711)]
// CHECK:STDOUT:     %.loc6_19.15: bool = splice_inst %.loc6_19.47 [template = %.loc6_19.48 (constants.%.498)]
// CHECK:STDOUT:     if %.loc6_19.15 br !for.body else br !for.done
// CHECK:STDOUT:
// CHECK:STDOUT:   !for.body:
// CHECK:STDOUT:     %.loc6_19.16: type = type_of_inst %.loc6_19.49 [template = %.loc6_19.50 (constants.%.1c3)]
// CHECK:STDOUT:     %.loc6_19.17: @Sum.%.loc6_19.50 (%.1c3) = splice_inst %.loc6_19.49 [template = %.loc6_19.51 (constants.%.3a7)]
// CHECK:STDOUT:     %.loc6_19.18: type = type_of_inst %.loc6_19.52 [template = %.loc6_19.53 (constants.%.c54)]
// CHECK:STDOUT:     %.loc6_19.19: @Sum.%.loc6_19.53 (%.c54) = splice_inst %.loc6_19.52 [template = %.loc6_19.54 (constants.%.424)]
// CHECK:STDOUT:     %.loc6_19.20: %i32 = splice_inst %.loc6_19.55 [template = %.loc6_19.56 (constants.%.6ec)]
// CHECK:STDOUT:     %i32.loc6: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %.loc6_19.20
// CHECK:STDOUT:     %s.ref.loc7: ref %i32 = name_ref s, %s
// CHECK:STDOUT:     %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:     %impl.elem0.loc7: %.004 = impl_witness_access constants.%AddAssignWith.impl_witness.e9d, element0 [concrete = constants.%Int.as.AddAssignWith.impl.Op.d34738.2]
// CHECK:STDOUT:     %bound_method.loc7_7.1: <bound method> = bound_method %s.ref.loc7, %impl.elem0.loc7
// CHECK:STDOUT:     %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7, @Int.as.AddAssignWith.impl.Op.1(constants.%int_32, constants.%ImplicitAs.facet.e88) [concrete = constants.%Int.as.AddAssignWith.impl.Op.specific_fn.d76216.1]
// CHECK:STDOUT:     %bound_method.loc7_7.2: <bound method> = bound_method %s.ref.loc7, %specific_fn.loc7
// CHECK:STDOUT:     %.loc7: %Int.as.AddAssignWith.impl.Op.type.0b80aa.1 = specific_constant imports.%Core.Op.1b1, @Int.as.AddAssignWith.impl(constants.%int_32, constants.%ImplicitAs.facet.e88) [concrete = constants.%Int.as.AddAssignWith.impl.Op.d34738.1]
// CHECK:STDOUT:     %Op.ref: %Int.as.AddAssignWith.impl.Op.type.0b80aa.1 = name_ref Op, %.loc7 [concrete = constants.%Int.as.AddAssignWith.impl.Op.d34738.1]
// CHECK:STDOUT:     %Int.as.AddAssignWith.impl.Op.bound: <bound method> = bound_method %s.ref.loc7, %Op.ref
// CHECK:STDOUT:     %Int.as.AddAssignWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddAssignWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.e88) [concrete = constants.%Int.as.AddAssignWith.impl.Op.specific_fn.d76216.2]
// CHECK:STDOUT:     %bound_method.loc7_7.3: <bound method> = bound_method %s.ref.loc7, %Int.as.AddAssignWith.impl.Op.specific_fn
// CHECK:STDOUT:     %Int.as.AddAssignWith.impl.Op.call: init %empty_tuple.type = call %bound_method.loc7_7.3(%s.ref.loc7, %x.ref)
// CHECK:STDOUT:     br !for.next
// CHECK:STDOUT:
// CHECK:STDOUT:   !for.done:
// CHECK:STDOUT:     %.loc6_19.21: type = type_of_inst %.loc6_19.57 [template = %.loc6_19.58 (constants.%.8cb5e6.3)]
// CHECK:STDOUT:     %.loc6_19.22: @Sum.%.loc6_19.58 (%.8cb5e6.3) = splice_inst %.loc6_19.57 [template = %.loc6_19.59 (constants.%.c234ea.3)]
// CHECK:STDOUT:     %.loc6_19.23: type = type_of_inst %.loc6_19.60 [template = %.loc6_19.61 (constants.%.57c638.2)]
// CHECK:STDOUT:     %.loc6_19.24: @Sum.%.loc6_19.61 (%.57c638.2) = splice_inst %.loc6_19.60 [template = %.loc6_19.62 (constants.%.e63d45.2)]
// CHECK:STDOUT:     %s.ref.loc9: ref %i32 = name_ref s, %s
// CHECK:STDOUT:     %.loc9: %i32 = acquire_value %s.ref.loc9
// CHECK:STDOUT:     %impl.elem0.loc9: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:     %bound_method.loc9_10.1: <bound method> = bound_method %.loc9, %impl.elem0.loc9
// CHECK:STDOUT:     %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc9_10.2: <bound method> = bound_method %.loc9, %specific_fn.loc9
// CHECK:STDOUT:     %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc9_10.2(%.loc9)
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %s.var, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%s.var)
// CHECK:STDOUT:     return %Int.as.Copy.impl.Op.call
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
// CHECK:STDOUT: specific @Sum(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc4_18.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_18.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %a.param_patt.loc4_27.2 => constants.%a.param_patt
// CHECK:STDOUT:   %a.patt.loc4_27.2 => constants.%a.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
