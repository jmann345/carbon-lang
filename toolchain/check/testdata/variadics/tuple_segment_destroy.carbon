// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/tuple_segment_destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/tuple_segment_destroy.carbon

// --- var.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  var unused u: (... each T) = t;
}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  F((1 as i32, true));
  //@dump-sem-ir-end
}

// --- let_from_call.carbon
library "[[@TEST_NAME]]";

fn G[... each T: Core.Copy & Core.Destroy](t: (... each T)) -> (... each T) {
  return t;
}

//@dump-sem-ir-begin
fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  let unused u: (... each T) = G(t);
}
//@dump-sem-ir-end

// --- discarded_result.carbon
library "[[@TEST_NAME]]";

fn G[... each T: Core.Copy & Core.Destroy](t: (... each T)) -> (... each T) {
  return t;
}

//@dump-sem-ir-begin
fn F[... each T: Core.Copy & Core.Destroy](t: (... each T)) {
  G(t);
}
//@dump-sem-ir-end

// --- fail_missing_destroy.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](t: (... each T)) {
  // CHECK:STDERR: fail_missing_destroy.carbon:[[@LINE+4]]:3: error: cannot access member of interface `Core.Destroy` in type `(... each T)` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   var unused u: (... each T) = t;
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var unused u: (... each T) = t;
}

fn G[... each T: Core.Copy](t: (... each T)) -> (... each T) {
  return t;
}

fn H[... each T: Core.Copy](t: (... each T)) {
  // CHECK:STDERR: fail_missing_destroy.carbon:[[@LINE+4]]:3: error: cannot access member of interface `Core.Destroy` in type `(... each T)` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   G(t);
  // CHECK:STDERR:   ^~~~
  // CHECK:STDERR:
  G(t);
}

// CHECK:STDOUT: --- var.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
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
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.f50: type = pack_type %facet_type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.b23: type = pattern_type %pack_type.f50 [symbolic]
// CHECK:STDOUT:   %T.patt.0e6: %pattern_type.b23 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T.cd9: %pack_type.f50 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.dcc: %pattern_type.b23 = pack_expansion_pattern %T.patt.0e6, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.e27: %facet_type = pack_element %T.cd9, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.5c4: type = tuple_type (%pack_type.f50) [symbolic]
// CHECK:STDOUT:   %tuple.4b7: %tuple.type.5c4 = tuple_value (%T.cd9) [symbolic]
// CHECK:STDOUT:   %pack_type.b88: type = pack_type %T.cd9, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.a1b: type = tuple_type (%pack_type.b88) [symbolic]
// CHECK:STDOUT:   %pattern_type.877: type = pattern_type %tuple.type.a1b [symbolic]
// CHECK:STDOUT:   %t.param_patt.846: %pattern_type.877 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt.185: %pattern_type.877 = wrapper_binding_pattern t, %t.param_patt.846 [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.91b: <witness> = require_complete_type %tuple.type.a1b [symbolic]
// CHECK:STDOUT:   %u.patt.238: %pattern_type.877 = ref_binding_pattern u [symbolic]
// CHECK:STDOUT:   %u.var_patt.7bb: %pattern_type.877 = var_pattern %u.patt.238 [symbolic]
// CHECK:STDOUT:   %as_type.e47: type = facet_access_type %.e27 [symbolic]
// CHECK:STDOUT:   %require_complete.c4a: <witness> = require_complete_type %as_type.e47 [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.f06: <witness> = lookup_impl_witness %.e27, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.facet.623: %Copy.type = facet_value %as_type.e47, (%Copy.lookup_impl_witness.f06) [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.514: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.623) [symbolic]
// CHECK:STDOUT:   %.2c1: type = fn_type_with_self_type %Copy.WithSelf.Op.type.514, %Copy.facet.623 [symbolic]
// CHECK:STDOUT:   %impl.elem0.48f: %.2c1 = impl_witness_access %Copy.lookup_impl_witness.f06, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.6f7: <specific function> = specific_impl_function %impl.elem0.48f, @Copy.WithSelf.Op(%Copy.facet.623) [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.ec7: <witness> = lookup_impl_witness %tuple.type.a1b, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.2a8: %Destroy.type = facet_value %tuple.type.a1b, (%Destroy.lookup_impl_witness.ec7) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.e63: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.2a8) [symbolic]
// CHECK:STDOUT:   %.24c: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.e63, %Destroy.facet.2a8 [symbolic]
// CHECK:STDOUT:   %impl.elem2: %.24c = impl_witness_access %Destroy.lookup_impl_witness.ec7, element2 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.098: <specific function> = specific_impl_function %impl.elem2, @Destroy.WithSelf.SelfDestruct.1(%Destroy.facet.2a8) [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %As.type.116: type = generic_interface_type @As [concrete]
// CHECK:STDOUT:   %As.generic: %As.type.116 = struct_value () [concrete]
// CHECK:STDOUT:   %As.type.155: type = facet_type <@As, @As(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.c5d: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl.f25(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.6ee: %Core.IntLiteral.as.As.impl.Convert.type.c5d = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.e7f: <witness> = impl_witness imports.%As.impl_witness_table.d22, @Core.IntLiteral.as.As.impl.f25(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.e79: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl.f25(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.8a4: %Core.IntLiteral.as.As.impl.Convert.type.e79 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.155 = facet_value Core.IntLiteral, (%As.impl_witness.e7f) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.d02: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i32, %As.facet) [concrete]
// CHECK:STDOUT:   %.453: type = fn_type_with_self_type %As.WithSelf.Convert.type.d02, %As.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.8a4 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.8a4, @Core.IntLiteral.as.As.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %tuple.type.6ed: type = tuple_type (%i32, bool) [concrete]
// CHECK:STDOUT:   %tuple.078: %tuple.type.6ed = tuple_value (%int_1.0c6, %true) [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.89b: %pack_type.8f6 = pack_value (%i32, bool) [concrete]
// CHECK:STDOUT:   %pack_type.e2e: type = pack_type %facet_type, %int_2 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc11_21.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc11_21.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc11_21.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.730: %facet_type = facet_value %i32, (%Copy.impl_witness.b51, %custom_witness.f8f19d.1) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %self.param_patt.40d: %pattern_type.831 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.560: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt.40d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc11_21.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc11_21.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc11_21.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.2: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.2, %Destroy.WithSelf.SubobjectDestroy.d01daf.2, %Destroy.WithSelf.SelfDestruct.db3fdb.2), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value.d7b: %facet_type = facet_value bool, (%Copy.impl_witness.5e1, %custom_witness.f8f19d.2) [concrete]
// CHECK:STDOUT:   %.91e: %pack_type.e2e = pack_value (%facet_value.730, %facet_value.d7b) [concrete]
// CHECK:STDOUT:   %pattern_type.28f: type = pattern_type %pack_type.e2e [concrete]
// CHECK:STDOUT:   %T.patt.769: %pattern_type.28f = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.156: %pattern_type.28f = pack_expansion_pattern %T.patt.769, %arity.patt [symbolic]
// CHECK:STDOUT:   %.302: %facet_type = pack_element %.91e, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.56f: type = tuple_type (%facet_type, %facet_type) [concrete]
// CHECK:STDOUT:   %tuple.8a9: %tuple.type.56f = tuple_value (%facet_value.730, %facet_value.d7b) [concrete]
// CHECK:STDOUT:   %pack_type.601: type = pack_type %.91e, %int_2 [concrete]
// CHECK:STDOUT:   %pattern_type.cae: type = pattern_type %tuple.type.6ed [concrete]
// CHECK:STDOUT:   %t.param_patt.cc8: %pattern_type.cae = value_param_pattern [concrete]
// CHECK:STDOUT:   %t.patt.9ba: %pattern_type.cae = wrapper_binding_pattern t, %t.param_patt.cc8 [concrete]
// CHECK:STDOUT:   %F.specific_fn: <specific function> = specific_function %F, @F(%int_2, %.91e) [concrete]
// CHECK:STDOUT:   %complete_type.61e: <witness> = complete_type_witness %tuple.type.6ed [concrete]
// CHECK:STDOUT:   %u.patt.ce9: %pattern_type.cae = ref_binding_pattern u [concrete]
// CHECK:STDOUT:   %u.var_patt.102: %pattern_type.cae = var_pattern %u.patt.ce9 [concrete]
// CHECK:STDOUT:   %as_type.d6c: type = facet_access_type %.302 [symbolic]
// CHECK:STDOUT:   %require_complete.91f: <witness> = require_complete_type %as_type.d6c [symbolic]
// CHECK:STDOUT:   %Copy.lookup_impl_witness.f12: <witness> = lookup_impl_witness %.302, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.facet.104: %Copy.type = facet_value %as_type.d6c, (%Copy.lookup_impl_witness.f12) [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.04b: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.104) [symbolic]
// CHECK:STDOUT:   %.a4b: type = fn_type_with_self_type %Copy.WithSelf.Op.type.04b, %Copy.facet.104 [symbolic]
// CHECK:STDOUT:   %impl.elem0.83c: %.a4b = impl_witness_access %Copy.lookup_impl_witness.f12, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.504: <specific function> = specific_impl_function %impl.elem0.83c, @Copy.WithSelf.Op(%Copy.facet.104) [symbolic]
// CHECK:STDOUT:   %self.param_patt.3ef: %pattern_type.cae = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.26b: %pattern_type.cae = wrapper_binding_pattern self, %self.param_patt.3ef [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.3: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.3, %Destroy.WithSelf.SubobjectDestroy.d01daf.3, %Destroy.WithSelf.SelfDestruct.db3fdb.3), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.de8: %Destroy.type = facet_value %tuple.type.6ed, (%custom_witness.f8f19d.3) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.d16: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.de8) [concrete]
// CHECK:STDOUT:   %.515: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.d16, %Destroy.facet.de8 [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.type: type = fn_type @bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op: %bool.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .As = %Core.As
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3475.1: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3475.1), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.As: %As.type.116 = import_ref Core//prelude/operators/as, As, loaded [concrete = constants.%As.generic]
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.f25.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl.f25 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.9c3475.2: %bool.as.Copy.impl.Op.type = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.9c3475.2), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc11_21.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc11_21.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc11_21.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc11_21.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cae = ref_param_pattern [concrete = constants.%self.param_patt.3ef]
// CHECK:STDOUT:     %self.patt: %pattern_type.cae = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.26b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.6ed = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.6ed = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc5 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cae = ref_param_pattern [concrete = constants.%self.param_patt.3ef]
// CHECK:STDOUT:     %self.patt: %pattern_type.cae = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.26b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.6ed = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.6ed = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %arity.patt.loc4_6.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc4_16.1: @F.%pattern_type.loc4_16 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_16.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:     %.loc4_6.1: @F.%pattern_type.loc4_16 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc4_16.1, %arity.patt.loc4_6.1 [symbolic = %.loc4_6.2 (constants.%.dcc)]
// CHECK:STDOUT:     %t.param_patt.loc4_45.1: @F.%pattern_type.loc4_45 (%pattern_type.877) = value_param_pattern [symbolic = %t.param_patt.loc4_45.2 (constants.%t.param_patt.846)]
// CHECK:STDOUT:     %t.patt.loc4_45.1: @F.%pattern_type.loc4_45 (%pattern_type.877) = wrapper_binding_pattern t, %t.param_patt.loc4_45.1 [symbolic = %t.patt.loc4_45.2 (constants.%t.patt.185)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc4_6.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_6.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc4_28.1: type = splice_block %.loc4_28.3 [concrete = constants.%facet_type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc4_18: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc4_30: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc4: <bound method> = bound_method %Copy.ref, %impl.elem1 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method.loc4(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc4_28.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc4_28.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc4_28.2 [concrete = constants.%facet_type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_16.2: @F.%pack_type.loc4_16 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc4_16.1 (constants.%T.cd9)]
// CHECK:STDOUT:     %t.param: @F.%tuple.type.loc4_58.2 (%tuple.type.a1b) = value_param call_param0
// CHECK:STDOUT:     %.loc4_58.1: type = splice_block %.loc4_58.3 [symbolic = %tuple.type.loc4_58.2 (constants.%tuple.type.a1b)] {
// CHECK:STDOUT:       %.loc4_58.2: @F.%tuple.type.loc4_58.1 (%tuple.type.5c4) = tuple_literal (constants.%T.cd9) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:       %.loc4_58.3: type = converted %.loc4_58.2, constants.%tuple.type.a1b [symbolic = %tuple.type.loc4_58.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: @F.%tuple.type.loc4_58.2 (%tuple.type.a1b) = wrapper_binding t, %t.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%arity.loc4_6.2: Core.IntLiteral, %T.loc4_16.2: @F.%pack_type.loc4_16 (%pack_type.f50)) {
// CHECK:STDOUT:   %arity.patt.loc4_6.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc4_6.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_6.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc4_16: type = pack_type constants.%facet_type, %arity.loc4_6.1 [symbolic = %pack_type.loc4_16 (constants.%pack_type.f50)]
// CHECK:STDOUT:   %pattern_type.loc4_16: type = pattern_type %pack_type.loc4_16 [symbolic = %pattern_type.loc4_16 (constants.%pattern_type.b23)]
// CHECK:STDOUT:   %T.patt.loc4_16.2: @F.%pattern_type.loc4_16 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_16.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:   %T.loc4_16.1: @F.%pack_type.loc4_16 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc4_16.1 (constants.%T.cd9)]
// CHECK:STDOUT:   %.loc4_6.2: @F.%pattern_type.loc4_16 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc4_16.2, %arity.patt.loc4_6.2 [symbolic = %.loc4_6.2 (constants.%.dcc)]
// CHECK:STDOUT:   %.loc4_52.1: Core.IntLiteral = pack_index [symbolic = %.loc4_52.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc4_52.2: %facet_type = pack_element %T.loc4_16.1, %.loc4_52.1 [symbolic = %.loc4_52.2 (constants.%.e27)]
// CHECK:STDOUT:   %tuple.type.loc4_58.1: type = tuple_type (%pack_type.loc4_16) [symbolic = %tuple.type.loc4_58.1 (constants.%tuple.type.5c4)]
// CHECK:STDOUT:   %tuple: @F.%tuple.type.loc4_58.1 (%tuple.type.5c4) = tuple_value (%T.loc4_16.1) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:   %pack_type.loc4_58: type = pack_type %T.loc4_16.1, %arity.loc4_6.1 [symbolic = %pack_type.loc4_58 (constants.%pack_type.b88)]
// CHECK:STDOUT:   %tuple.type.loc4_58.2: type = tuple_type (%pack_type.loc4_58) [symbolic = %tuple.type.loc4_58.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:   %pattern_type.loc4_45: type = pattern_type %tuple.type.loc4_58.2 [symbolic = %pattern_type.loc4_45 (constants.%pattern_type.877)]
// CHECK:STDOUT:   %t.param_patt.loc4_45.2: @F.%pattern_type.loc4_45 (%pattern_type.877) = value_param_pattern [symbolic = %t.param_patt.loc4_45.2 (constants.%t.param_patt.846)]
// CHECK:STDOUT:   %t.patt.loc4_45.2: @F.%pattern_type.loc4_45 (%pattern_type.877) = wrapper_binding_pattern t, %t.param_patt.loc4_45.2 [symbolic = %t.patt.loc4_45.2 (constants.%t.patt.185)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4: <witness> = require_complete_type %tuple.type.loc4_58.2 [symbolic = %require_complete.loc4 (constants.%require_complete.91b)]
// CHECK:STDOUT:   %u.patt.loc5_15.2: @F.%pattern_type.loc4_45 (%pattern_type.877) = ref_binding_pattern u [symbolic = %u.patt.loc5_15.2 (constants.%u.patt.238)]
// CHECK:STDOUT:   %u.var_patt.loc5_3.2: @F.%pattern_type.loc4_45 (%pattern_type.877) = var_pattern %u.patt.loc5_15.2 [symbolic = %u.var_patt.loc5_3.2 (constants.%u.var_patt.7bb)]
// CHECK:STDOUT:   %as_type.loc5_32.3: type = facet_access_type %.loc4_52.2 [symbolic = %as_type.loc5_32.3 (constants.%as_type.e47)]
// CHECK:STDOUT:   %require_complete.loc5: <witness> = require_complete_type %as_type.loc5_32.3 [symbolic = %require_complete.loc5 (constants.%require_complete.c4a)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %.loc4_52.2, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.f06)]
// CHECK:STDOUT:   %Copy.facet.loc5_32.3: %Copy.type = facet_value %as_type.loc5_32.3, (%Copy.lookup_impl_witness) [symbolic = %Copy.facet.loc5_32.3 (constants.%Copy.facet.623)]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.loc5_32.3) [symbolic = %Copy.WithSelf.Op.type (constants.%Copy.WithSelf.Op.type.514)]
// CHECK:STDOUT:   %.loc5_32.14: type = fn_type_with_self_type %Copy.WithSelf.Op.type, %Copy.facet.loc5_32.3 [symbolic = %.loc5_32.14 (constants.%.2c1)]
// CHECK:STDOUT:   %impl.elem0.loc5_32.2: @F.%.loc5_32.14 (%.2c1) = impl_witness_access %Copy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc5_32.2 (constants.%impl.elem0.48f)]
// CHECK:STDOUT:   %specific_impl_fn.loc5_32.2: <specific function> = specific_impl_function %impl.elem0.loc5_32.2, @Copy.WithSelf.Op(%Copy.facet.loc5_32.3) [symbolic = %specific_impl_fn.loc5_32.2 (constants.%specific_impl_fn.6f7)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type.loc4_58.2, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.ec7)]
// CHECK:STDOUT:   %Destroy.facet.loc5_3.3: %Destroy.type = facet_value %tuple.type.loc4_58.2, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc5_3.3 (constants.%Destroy.facet.2a8)]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type: type = fn_type @Destroy.WithSelf.SelfDestruct.1, @Destroy.WithSelf(%Destroy.facet.loc5_3.3) [symbolic = %Destroy.WithSelf.SelfDestruct.type (constants.%Destroy.WithSelf.SelfDestruct.type.e63)]
// CHECK:STDOUT:   %.loc5_3.4: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type, %Destroy.facet.loc5_3.3 [symbolic = %.loc5_3.4 (constants.%.24c)]
// CHECK:STDOUT:   %impl.elem2.loc5_3.2: @F.%.loc5_3.4 (%.24c) = impl_witness_access %Destroy.lookup_impl_witness, element2 [symbolic = %impl.elem2.loc5_3.2 (constants.%impl.elem2)]
// CHECK:STDOUT:   %specific_impl_fn.loc5_3.2: <specific function> = specific_impl_function %impl.elem2.loc5_3.2, @Destroy.WithSelf.SelfDestruct.1(%Destroy.facet.loc5_3.3) [symbolic = %specific_impl_fn.loc5_3.2 (constants.%specific_impl_fn.098)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @F.%tuple.type.loc4_58.2 (%tuple.type.a1b)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %u.var: ref @F.%tuple.type.loc4_58.2 (%tuple.type.a1b) = var_storage %u.var_patt.loc5_3.1
// CHECK:STDOUT:     %t.ref: @F.%tuple.type.loc4_58.2 (%tuple.type.a1b) = name_ref t, %t
// CHECK:STDOUT:     %.loc5_32.1: init @F.%tuple.type.loc4_58.2 (%tuple.type.a1b) to %u.var = pack_segment_init {
// CHECK:STDOUT:       %.loc5_32.2: Core.IntLiteral = pack_index [symbolic = %.loc4_52.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc5_32.3: Core.IntLiteral = pack_index [symbolic = %.loc4_52.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc5_32.4: %facet_type = pack_element constants.%T.cd9, %.loc5_32.3 [symbolic = %.loc4_52.2 (constants.%.e27)]
// CHECK:STDOUT:       %as_type.loc5_32.1: type = facet_access_type %.loc5_32.4 [symbolic = %as_type.loc5_32.3 (constants.%as_type.e47)]
// CHECK:STDOUT:       %.loc5_32.5: type = converted %.loc5_32.4, %as_type.loc5_32.1 [symbolic = %as_type.loc5_32.3 (constants.%as_type.e47)]
// CHECK:STDOUT:       %.loc5_32.6: @F.%as_type.loc5_32.3 (%as_type.e47) = pack_element %t.ref, %.loc5_32.2
// CHECK:STDOUT:       %.loc5_32.7: Core.IntLiteral = pack_index [symbolic = %.loc4_52.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc5_32.8: %facet_type = pack_element constants.%T.cd9, %.loc5_32.7 [symbolic = %.loc4_52.2 (constants.%.e27)]
// CHECK:STDOUT:       %as_type.loc5_32.2: type = facet_access_type %.loc5_32.8 [symbolic = %as_type.loc5_32.3 (constants.%as_type.e47)]
// CHECK:STDOUT:       %.loc5_32.9: type = converted %.loc5_32.8, %as_type.loc5_32.2 [symbolic = %as_type.loc5_32.3 (constants.%as_type.e47)]
// CHECK:STDOUT:       %impl.elem0.loc5_32.1: @F.%.loc5_32.14 (%.2c1) = impl_witness_access constants.%Copy.lookup_impl_witness.f06, element0 [symbolic = %impl.elem0.loc5_32.2 (constants.%impl.elem0.48f)]
// CHECK:STDOUT:       %bound_method.loc5_32.1: <bound method> = bound_method %.loc5_32.6, %impl.elem0.loc5_32.1
// CHECK:STDOUT:       %Copy.facet.loc5_32.1: %Copy.type = facet_value constants.%as_type.e47, (constants.%Copy.lookup_impl_witness.f06) [symbolic = %Copy.facet.loc5_32.3 (constants.%Copy.facet.623)]
// CHECK:STDOUT:       %.loc5_32.10: %Copy.type = converted constants.%as_type.e47, %Copy.facet.loc5_32.1 [symbolic = %Copy.facet.loc5_32.3 (constants.%Copy.facet.623)]
// CHECK:STDOUT:       %Copy.facet.loc5_32.2: %Copy.type = facet_value constants.%as_type.e47, (constants.%Copy.lookup_impl_witness.f06) [symbolic = %Copy.facet.loc5_32.3 (constants.%Copy.facet.623)]
// CHECK:STDOUT:       %.loc5_32.11: %Copy.type = converted constants.%as_type.e47, %Copy.facet.loc5_32.2 [symbolic = %Copy.facet.loc5_32.3 (constants.%Copy.facet.623)]
// CHECK:STDOUT:       %specific_impl_fn.loc5_32.1: <specific function> = specific_impl_function %impl.elem0.loc5_32.1, @Copy.WithSelf.Op(constants.%Copy.facet.623) [symbolic = %specific_impl_fn.loc5_32.2 (constants.%specific_impl_fn.6f7)]
// CHECK:STDOUT:       %bound_method.loc5_32.2: <bound method> = bound_method %.loc5_32.6, %specific_impl_fn.loc5_32.1
// CHECK:STDOUT:       %.loc5_32.12: ref @F.%as_type.loc5_32.3 (%as_type.e47) = pack_element %u.var, %.loc5_32.2
// CHECK:STDOUT:       %Copy.WithSelf.Op.call: init @F.%as_type.loc5_32.3 (%as_type.e47) to %.loc5_32.12 = call %bound_method.loc5_32.2(%.loc5_32.6)
// CHECK:STDOUT:       %.loc5_32.13: init @F.%as_type.loc5_32.3 (%as_type.e47) to %.loc5_32.12 = in_place_init %Copy.WithSelf.Op.call
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc5_3.1: init @F.%tuple.type.loc4_58.2 (%tuple.type.a1b) = converted %t.ref, %.loc5_32.1
// CHECK:STDOUT:     assign %u.var, %.loc5_3.1
// CHECK:STDOUT:     %.loc5_28.1: type = splice_block %.loc5_28.3 [symbolic = %tuple.type.loc4_58.2 (constants.%tuple.type.a1b)] {
// CHECK:STDOUT:       %.loc5_28.2: @F.%tuple.type.loc4_58.1 (%tuple.type.5c4) = tuple_literal (constants.%T.cd9) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:       %.loc5_28.3: type = converted %.loc5_28.2, constants.%tuple.type.a1b [symbolic = %tuple.type.loc4_58.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %u: ref @F.%tuple.type.loc4_58.2 (%tuple.type.a1b) = wrapper_binding u, %u.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %u.patt.loc5_15.1: @F.%pattern_type.loc4_45 (%pattern_type.877) = ref_binding_pattern u [symbolic = %u.patt.loc5_15.2 (constants.%u.patt.238)]
// CHECK:STDOUT:       %u.var_patt.loc5_3.1: @F.%pattern_type.loc4_45 (%pattern_type.877) = var_pattern %u.patt.loc5_15.1 [symbolic = %u.var_patt.loc5_3.2 (constants.%u.var_patt.7bb)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %impl.elem2.loc5_3.1: @F.%.loc5_3.4 (%.24c) = impl_witness_access constants.%Destroy.lookup_impl_witness.ec7, element2 [symbolic = %impl.elem2.loc5_3.2 (constants.%impl.elem2)]
// CHECK:STDOUT:     %bound_method.loc5_3.1: <bound method> = bound_method %u.var, %impl.elem2.loc5_3.1
// CHECK:STDOUT:     %Destroy.facet.loc5_3.1: %Destroy.type = facet_value constants.%tuple.type.a1b, (constants.%Destroy.lookup_impl_witness.ec7) [symbolic = %Destroy.facet.loc5_3.3 (constants.%Destroy.facet.2a8)]
// CHECK:STDOUT:     %.loc5_3.2: %Destroy.type = converted constants.%tuple.type.a1b, %Destroy.facet.loc5_3.1 [symbolic = %Destroy.facet.loc5_3.3 (constants.%Destroy.facet.2a8)]
// CHECK:STDOUT:     %Destroy.facet.loc5_3.2: %Destroy.type = facet_value constants.%tuple.type.a1b, (constants.%Destroy.lookup_impl_witness.ec7) [symbolic = %Destroy.facet.loc5_3.3 (constants.%Destroy.facet.2a8)]
// CHECK:STDOUT:     %.loc5_3.3: %Destroy.type = converted constants.%tuple.type.a1b, %Destroy.facet.loc5_3.2 [symbolic = %Destroy.facet.loc5_3.3 (constants.%Destroy.facet.2a8)]
// CHECK:STDOUT:     %specific_impl_fn.loc5_3.1: <specific function> = specific_impl_function %impl.elem2.loc5_3.1, @Destroy.WithSelf.SelfDestruct.1(constants.%Destroy.facet.2a8) [symbolic = %specific_impl_fn.loc5_3.2 (constants.%specific_impl_fn.098)]
// CHECK:STDOUT:     %bound_method.loc5_3.2: <bound method> = bound_method %u.var, %specific_impl_fn.loc5_3.1
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method.loc5_3.2(%u.var)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref: %F.type = name_ref F, file.%F.decl [concrete = constants.%F]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %impl.elem0: %.453 = impl_witness_access constants.%As.impl_witness.e7f, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.8a4]
// CHECK:STDOUT:   %bound_method.loc11_8.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.As.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_8.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call: init %i32 = call %bound_method.loc11_8.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc11_8.1: %i32 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc11_8.2: %i32 = converted %int_1, %.loc11_8.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc11_20.1: %tuple.type.6ed = tuple_literal (%.loc11_8.2, %true) [concrete = constants.%tuple.078]
// CHECK:STDOUT:   %int_2.loc11_21.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc11_21.1: %pack_type.8f6 = pack_value (constants.%i32, bool) [concrete = constants.%.89b]
// CHECK:STDOUT:   %int_2.loc11_21.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc11_21.2: %pack_type.8f6 = pack_value (constants.%i32, bool) [concrete = constants.%.89b]
// CHECK:STDOUT:   %facet_value.loc11_21.1: %facet_type = facet_value constants.%i32, (constants.%Copy.impl_witness.b51, constants.%custom_witness.f8f19d.1) [concrete = constants.%facet_value.730]
// CHECK:STDOUT:   %.loc11_21.3: %facet_type = converted constants.%i32, %facet_value.loc11_21.1 [concrete = constants.%facet_value.730]
// CHECK:STDOUT:   %facet_value.loc11_21.2: %facet_type = facet_value bool, (constants.%Copy.impl_witness.5e1, constants.%custom_witness.f8f19d.2) [concrete = constants.%facet_value.d7b]
// CHECK:STDOUT:   %.loc11_21.4: %facet_type = converted bool, %facet_value.loc11_21.2 [concrete = constants.%facet_value.d7b]
// CHECK:STDOUT:   %.loc11_21.5: %pack_type.e2e = pack_value (%.loc11_21.3, %.loc11_21.4) [concrete = constants.%.91e]
// CHECK:STDOUT:   %.loc11_21.6: %pack_type.e2e = converted constants.%.89b, %.loc11_21.5 [concrete = constants.%.91e]
// CHECK:STDOUT:   %F.specific_fn: <specific function> = specific_function %F.ref, @F(constants.%int_2, constants.%.91e) [concrete = constants.%F.specific_fn]
// CHECK:STDOUT:   %tuple: %tuple.type.6ed = tuple_value (%.loc11_8.2, %true) [concrete = constants.%tuple.078]
// CHECK:STDOUT:   %.loc11_20.2: %tuple.type.6ed = converted %.loc11_20.1, %tuple [concrete = constants.%tuple.078]
// CHECK:STDOUT:   %F.call: init %empty_tuple.type = call %F.specific_fn(%.loc11_20.2)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc11_21.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc11_21.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc11_21.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc11_21.2(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc11_21.2(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc11_21.2(%self.param: ref bool) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc5(%self.param: ref %tuple.type.6ed) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %tuple.elem1: ref bool = tuple_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc5_3.1: <bound method> = bound_method %tuple.elem1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc5_3.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc5_3.1(%tuple.elem1)
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc5_3.2: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc5_3.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc5_3.2(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc5(%self.param: ref %tuple.type.6ed) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc5(%self.param: ref %tuple.type.6ed) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%arity, constants.%T.cd9) {
// CHECK:STDOUT:   %arity.patt.loc4_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_6.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc4_16 => constants.%pack_type.f50
// CHECK:STDOUT:   %pattern_type.loc4_16 => constants.%pattern_type.b23
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt.0e6
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%T.cd9
// CHECK:STDOUT:   %.loc4_6.2 => constants.%.dcc
// CHECK:STDOUT:   %.loc4_52.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_52.2 => constants.%.e27
// CHECK:STDOUT:   %tuple.type.loc4_58.1 => constants.%tuple.type.5c4
// CHECK:STDOUT:   %tuple => constants.%tuple.4b7
// CHECK:STDOUT:   %pack_type.loc4_58 => constants.%pack_type.b88
// CHECK:STDOUT:   %tuple.type.loc4_58.2 => constants.%tuple.type.a1b
// CHECK:STDOUT:   %pattern_type.loc4_45 => constants.%pattern_type.877
// CHECK:STDOUT:   %t.param_patt.loc4_45.2 => constants.%t.param_patt.846
// CHECK:STDOUT:   %t.patt.loc4_45.2 => constants.%t.patt.185
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%int_2, constants.%.91e) {
// CHECK:STDOUT:   %arity.patt.loc4_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_6.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc4_16 => constants.%pack_type.e2e
// CHECK:STDOUT:   %pattern_type.loc4_16 => constants.%pattern_type.28f
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt.769
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%.91e
// CHECK:STDOUT:   %.loc4_6.2 => constants.%.156
// CHECK:STDOUT:   %.loc4_52.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_52.2 => constants.%.302
// CHECK:STDOUT:   %tuple.type.loc4_58.1 => constants.%tuple.type.56f
// CHECK:STDOUT:   %tuple => constants.%tuple.8a9
// CHECK:STDOUT:   %pack_type.loc4_58 => constants.%pack_type.601
// CHECK:STDOUT:   %tuple.type.loc4_58.2 => constants.%tuple.type.6ed
// CHECK:STDOUT:   %pattern_type.loc4_45 => constants.%pattern_type.cae
// CHECK:STDOUT:   %t.param_patt.loc4_45.2 => constants.%t.param_patt.cc8
// CHECK:STDOUT:   %t.patt.loc4_45.2 => constants.%t.patt.9ba
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4 => constants.%complete_type.61e
// CHECK:STDOUT:   %u.patt.loc5_15.2 => constants.%u.patt.ce9
// CHECK:STDOUT:   %u.var_patt.loc5_3.2 => constants.%u.var_patt.102
// CHECK:STDOUT:   %as_type.loc5_32.3 => constants.%as_type.d6c
// CHECK:STDOUT:   %require_complete.loc5 => constants.%require_complete.91f
// CHECK:STDOUT:   %Copy.lookup_impl_witness => constants.%Copy.lookup_impl_witness.f12
// CHECK:STDOUT:   %Copy.facet.loc5_32.3 => constants.%Copy.facet.104
// CHECK:STDOUT:   %Copy.WithSelf.Op.type => constants.%Copy.WithSelf.Op.type.04b
// CHECK:STDOUT:   %.loc5_32.14 => constants.%.a4b
// CHECK:STDOUT:   %impl.elem0.loc5_32.2 => constants.%impl.elem0.83c
// CHECK:STDOUT:   %specific_impl_fn.loc5_32.2 => constants.%specific_impl_fn.504
// CHECK:STDOUT:   %Destroy.lookup_impl_witness => constants.%custom_witness.f8f19d.3
// CHECK:STDOUT:   %Destroy.facet.loc5_3.3 => constants.%Destroy.facet.de8
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type => constants.%Destroy.WithSelf.SelfDestruct.type.d16
// CHECK:STDOUT:   %.loc5_3.4 => constants.%.515
// CHECK:STDOUT:   %impl.elem2.loc5_3.2 => constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %specific_impl_fn.loc5_3.2 => constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- let_from_call.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
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
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.f50: type = pack_type %facet_type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.b23: type = pattern_type %pack_type.f50 [symbolic]
// CHECK:STDOUT:   %T.patt.0e6: %pattern_type.b23 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T.cd9: %pack_type.f50 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.dcc: %pattern_type.b23 = pack_expansion_pattern %T.patt.0e6, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.e27: %facet_type = pack_element %T.cd9, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.5c4: type = tuple_type (%pack_type.f50) [symbolic]
// CHECK:STDOUT:   %tuple.4b7: %tuple.type.5c4 = tuple_value (%T.cd9) [symbolic]
// CHECK:STDOUT:   %pack_type.b88: type = pack_type %T.cd9, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.a1b: type = tuple_type (%pack_type.b88) [symbolic]
// CHECK:STDOUT:   %pattern_type.877: type = pattern_type %tuple.type.a1b [symbolic]
// CHECK:STDOUT:   %t.param_patt: %pattern_type.877 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt: %pattern_type.877 = wrapper_binding_pattern t, %t.param_patt [symbolic]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.91b: <witness> = require_complete_type %tuple.type.a1b [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %u.patt: %pattern_type.877 = value_binding_pattern u [symbolic]
// CHECK:STDOUT:   %G.specific_fn: <specific function> = specific_function %G, @G(%arity, %T.cd9) [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.ec7: <witness> = lookup_impl_witness %tuple.type.a1b, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet: %Destroy.type = facet_value %tuple.type.a1b, (%Destroy.lookup_impl_witness.ec7) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.e63: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %.24c: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.e63, %Destroy.facet [symbolic]
// CHECK:STDOUT:   %impl.elem2: %.24c = impl_witness_access %Destroy.lookup_impl_witness.ec7, element2 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.098: <specific function> = specific_impl_function %impl.elem2, @Destroy.WithSelf.SelfDestruct(%Destroy.facet) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %arity.patt.loc8_6.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc8_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc8_16.1: @F.%pattern_type.loc8_16 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc8_16.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:     %.loc8_6.1: @F.%pattern_type.loc8_16 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc8_16.1, %arity.patt.loc8_6.1 [symbolic = %.loc8_6.2 (constants.%.dcc)]
// CHECK:STDOUT:     %t.param_patt.loc8_45.1: @F.%pattern_type.loc8_45 (%pattern_type.877) = value_param_pattern [symbolic = %t.param_patt.loc8_45.2 (constants.%t.param_patt)]
// CHECK:STDOUT:     %t.patt.loc8_45.1: @F.%pattern_type.loc8_45 (%pattern_type.877) = wrapper_binding_pattern t, %t.param_patt.loc8_45.1 [symbolic = %t.patt.loc8_45.2 (constants.%t.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc8_6.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc8_6.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc8_28.1: type = splice_block %.loc8_28.3 [concrete = constants.%facet_type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc8_18: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc8_30: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc8: <bound method> = bound_method %Copy.ref, %impl.elem1 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method.loc8(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc8_28.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc8_28.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc8_28.2 [concrete = constants.%facet_type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc8_16.2: @F.%pack_type.loc8_16 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc8_16.1 (constants.%T.cd9)]
// CHECK:STDOUT:     %t.param: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = value_param call_param0
// CHECK:STDOUT:     %.loc8_58.1: type = splice_block %.loc8_58.3 [symbolic = %tuple.type.loc8_58.2 (constants.%tuple.type.a1b)] {
// CHECK:STDOUT:       %.loc8_58.2: @F.%tuple.type.loc8_58.1 (%tuple.type.5c4) = tuple_literal (constants.%T.cd9) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:       %.loc8_58.3: type = converted %.loc8_58.2, constants.%tuple.type.a1b [symbolic = %tuple.type.loc8_58.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = wrapper_binding t, %t.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%arity.loc8_6.2: Core.IntLiteral, %T.loc8_16.2: @F.%pack_type.loc8_16 (%pack_type.f50)) {
// CHECK:STDOUT:   %arity.patt.loc8_6.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc8_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc8_6.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc8_6.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc8_16: type = pack_type constants.%facet_type, %arity.loc8_6.1 [symbolic = %pack_type.loc8_16 (constants.%pack_type.f50)]
// CHECK:STDOUT:   %pattern_type.loc8_16: type = pattern_type %pack_type.loc8_16 [symbolic = %pattern_type.loc8_16 (constants.%pattern_type.b23)]
// CHECK:STDOUT:   %T.patt.loc8_16.2: @F.%pattern_type.loc8_16 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc8_16.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:   %T.loc8_16.1: @F.%pack_type.loc8_16 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc8_16.1 (constants.%T.cd9)]
// CHECK:STDOUT:   %.loc8_6.2: @F.%pattern_type.loc8_16 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc8_16.2, %arity.patt.loc8_6.2 [symbolic = %.loc8_6.2 (constants.%.dcc)]
// CHECK:STDOUT:   %.loc8_52.1: Core.IntLiteral = pack_index [symbolic = %.loc8_52.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc8_52.2: %facet_type = pack_element %T.loc8_16.1, %.loc8_52.1 [symbolic = %.loc8_52.2 (constants.%.e27)]
// CHECK:STDOUT:   %tuple.type.loc8_58.1: type = tuple_type (%pack_type.loc8_16) [symbolic = %tuple.type.loc8_58.1 (constants.%tuple.type.5c4)]
// CHECK:STDOUT:   %tuple: @F.%tuple.type.loc8_58.1 (%tuple.type.5c4) = tuple_value (%T.loc8_16.1) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:   %pack_type.loc8_58: type = pack_type %T.loc8_16.1, %arity.loc8_6.1 [symbolic = %pack_type.loc8_58 (constants.%pack_type.b88)]
// CHECK:STDOUT:   %tuple.type.loc8_58.2: type = tuple_type (%pack_type.loc8_58) [symbolic = %tuple.type.loc8_58.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:   %pattern_type.loc8_45: type = pattern_type %tuple.type.loc8_58.2 [symbolic = %pattern_type.loc8_45 (constants.%pattern_type.877)]
// CHECK:STDOUT:   %t.param_patt.loc8_45.2: @F.%pattern_type.loc8_45 (%pattern_type.877) = value_param_pattern [symbolic = %t.param_patt.loc8_45.2 (constants.%t.param_patt)]
// CHECK:STDOUT:   %t.patt.loc8_45.2: @F.%pattern_type.loc8_45 (%pattern_type.877) = wrapper_binding_pattern t, %t.param_patt.loc8_45.2 [symbolic = %t.patt.loc8_45.2 (constants.%t.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %tuple.type.loc8_58.2 [symbolic = %require_complete (constants.%require_complete.91b)]
// CHECK:STDOUT:   %u.patt.loc9_15.2: @F.%pattern_type.loc8_45 (%pattern_type.877) = value_binding_pattern u [symbolic = %u.patt.loc9_15.2 (constants.%u.patt)]
// CHECK:STDOUT:   %G.specific_fn.loc9_32.2: <specific function> = specific_function constants.%G, @G(%arity.loc8_6.1, %T.loc8_16.1) [symbolic = %G.specific_fn.loc9_32.2 (constants.%G.specific_fn)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type.loc8_58.2, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.ec7)]
// CHECK:STDOUT:   %Destroy.facet.loc9_35.3: %Destroy.type = facet_value %tuple.type.loc8_58.2, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc9_35.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet.loc9_35.3) [symbolic = %Destroy.WithSelf.SelfDestruct.type (constants.%Destroy.WithSelf.SelfDestruct.type.e63)]
// CHECK:STDOUT:   %.loc9_35.7: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type, %Destroy.facet.loc9_35.3 [symbolic = %.loc9_35.7 (constants.%.24c)]
// CHECK:STDOUT:   %impl.elem2.loc9_35.2: @F.%.loc9_35.7 (%.24c) = impl_witness_access %Destroy.lookup_impl_witness, element2 [symbolic = %impl.elem2.loc9_35.2 (constants.%impl.elem2)]
// CHECK:STDOUT:   %specific_impl_fn.loc9_35.2: <specific function> = specific_impl_function %impl.elem2.loc9_35.2, @Destroy.WithSelf.SelfDestruct(%Destroy.facet.loc9_35.3) [symbolic = %specific_impl_fn.loc9_35.2 (constants.%specific_impl_fn.098)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %G.ref: %G.type = name_ref G, file.%G.decl [concrete = constants.%G]
// CHECK:STDOUT:     %t.ref: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = name_ref t, %t
// CHECK:STDOUT:     %G.specific_fn.loc9_32.1: <specific function> = specific_function %G.ref, @G(constants.%arity, constants.%T.cd9) [symbolic = %G.specific_fn.loc9_32.2 (constants.%G.specific_fn)]
// CHECK:STDOUT:     %.loc9_35.1: ref @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = temporary_storage
// CHECK:STDOUT:     %G.call: init @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) to %.loc9_35.1 = call %G.specific_fn.loc9_32.1(%t.ref)
// CHECK:STDOUT:     %.loc9_35.2: ref @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = temporary %.loc9_35.1, %G.call
// CHECK:STDOUT:     %.loc9_35.3: ref @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = converted %G.call, %.loc9_35.2
// CHECK:STDOUT:     %.loc9_35.4: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = acquire_value %.loc9_35.3
// CHECK:STDOUT:     %.loc9_28.1: type = splice_block %.loc9_28.3 [symbolic = %tuple.type.loc8_58.2 (constants.%tuple.type.a1b)] {
// CHECK:STDOUT:       %.loc9_28.2: @F.%tuple.type.loc8_58.1 (%tuple.type.5c4) = tuple_literal (constants.%T.cd9) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:       %.loc9_28.3: type = converted %.loc9_28.2, constants.%tuple.type.a1b [symbolic = %tuple.type.loc8_58.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %u: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = wrapper_binding u, %.loc9_35.4
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %u.patt.loc9_15.1: @F.%pattern_type.loc8_45 (%pattern_type.877) = value_binding_pattern u [symbolic = %u.patt.loc9_15.2 (constants.%u.patt)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %impl.elem2.loc9_35.1: @F.%.loc9_35.7 (%.24c) = impl_witness_access constants.%Destroy.lookup_impl_witness.ec7, element2 [symbolic = %impl.elem2.loc9_35.2 (constants.%impl.elem2)]
// CHECK:STDOUT:     %bound_method.loc9_35.1: <bound method> = bound_method %.loc9_35.2, %impl.elem2.loc9_35.1
// CHECK:STDOUT:     %Destroy.facet.loc9_35.1: %Destroy.type = facet_value constants.%tuple.type.a1b, (constants.%Destroy.lookup_impl_witness.ec7) [symbolic = %Destroy.facet.loc9_35.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc9_35.5: %Destroy.type = converted constants.%tuple.type.a1b, %Destroy.facet.loc9_35.1 [symbolic = %Destroy.facet.loc9_35.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc9_35.2: %Destroy.type = facet_value constants.%tuple.type.a1b, (constants.%Destroy.lookup_impl_witness.ec7) [symbolic = %Destroy.facet.loc9_35.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc9_35.6: %Destroy.type = converted constants.%tuple.type.a1b, %Destroy.facet.loc9_35.2 [symbolic = %Destroy.facet.loc9_35.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc9_35.1: <specific function> = specific_impl_function %impl.elem2.loc9_35.1, @Destroy.WithSelf.SelfDestruct(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc9_35.2 (constants.%specific_impl_fn.098)]
// CHECK:STDOUT:     %bound_method.loc9_35.2: <bound method> = bound_method %.loc9_35.2, %specific_impl_fn.loc9_35.1
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method.loc9_35.2(%.loc9_35.2)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%arity, constants.%T.cd9) {
// CHECK:STDOUT:   %arity.patt.loc8_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc8_6.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc8_16 => constants.%pack_type.f50
// CHECK:STDOUT:   %pattern_type.loc8_16 => constants.%pattern_type.b23
// CHECK:STDOUT:   %T.patt.loc8_16.2 => constants.%T.patt.0e6
// CHECK:STDOUT:   %T.loc8_16.1 => constants.%T.cd9
// CHECK:STDOUT:   %.loc8_6.2 => constants.%.dcc
// CHECK:STDOUT:   %.loc8_52.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc8_52.2 => constants.%.e27
// CHECK:STDOUT:   %tuple.type.loc8_58.1 => constants.%tuple.type.5c4
// CHECK:STDOUT:   %tuple => constants.%tuple.4b7
// CHECK:STDOUT:   %pack_type.loc8_58 => constants.%pack_type.b88
// CHECK:STDOUT:   %tuple.type.loc8_58.2 => constants.%tuple.type.a1b
// CHECK:STDOUT:   %pattern_type.loc8_45 => constants.%pattern_type.877
// CHECK:STDOUT:   %t.param_patt.loc8_45.2 => constants.%t.param_patt
// CHECK:STDOUT:   %t.patt.loc8_45.2 => constants.%t.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- discarded_result.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %BitAndWith.type.a06: type = generic_interface_type @BitAndWith [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
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
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.f50: type = pack_type %facet_type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.b23: type = pattern_type %pack_type.f50 [symbolic]
// CHECK:STDOUT:   %T.patt.0e6: %pattern_type.b23 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T.cd9: %pack_type.f50 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.dcc: %pattern_type.b23 = pack_expansion_pattern %T.patt.0e6, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.e27: %facet_type = pack_element %T.cd9, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.5c4: type = tuple_type (%pack_type.f50) [symbolic]
// CHECK:STDOUT:   %tuple.4b7: %tuple.type.5c4 = tuple_value (%T.cd9) [symbolic]
// CHECK:STDOUT:   %pack_type.b88: type = pack_type %T.cd9, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.a1b: type = tuple_type (%pack_type.b88) [symbolic]
// CHECK:STDOUT:   %pattern_type.877: type = pattern_type %tuple.type.a1b [symbolic]
// CHECK:STDOUT:   %t.param_patt: %pattern_type.877 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt: %pattern_type.877 = wrapper_binding_pattern t, %t.param_patt [symbolic]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.91b: <witness> = require_complete_type %tuple.type.a1b [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %G.specific_fn: <specific function> = specific_function %G, @G(%arity, %T.cd9) [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.ec7: <witness> = lookup_impl_witness %tuple.type.a1b, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet: %Destroy.type = facet_value %tuple.type.a1b, (%Destroy.lookup_impl_witness.ec7) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.e63: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet) [symbolic]
// CHECK:STDOUT:   %.24c: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.e63, %Destroy.facet [symbolic]
// CHECK:STDOUT:   %impl.elem2: %.24c = impl_witness_access %Destroy.lookup_impl_witness.ec7, element2 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.098: <specific function> = specific_impl_function %impl.elem2, @Destroy.WithSelf.SelfDestruct(%Destroy.facet) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .BitAndWith = %Core.BitAndWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %arity.patt.loc8_6.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc8_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc8_16.1: @F.%pattern_type.loc8_16 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc8_16.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:     %.loc8_6.1: @F.%pattern_type.loc8_16 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc8_16.1, %arity.patt.loc8_6.1 [symbolic = %.loc8_6.2 (constants.%.dcc)]
// CHECK:STDOUT:     %t.param_patt.loc8_45.1: @F.%pattern_type.loc8_45 (%pattern_type.877) = value_param_pattern [symbolic = %t.param_patt.loc8_45.2 (constants.%t.param_patt)]
// CHECK:STDOUT:     %t.patt.loc8_45.1: @F.%pattern_type.loc8_45 (%pattern_type.877) = wrapper_binding_pattern t, %t.param_patt.loc8_45.1 [symbolic = %t.patt.loc8_45.2 (constants.%t.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc8_6.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc8_6.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc8_28.1: type = splice_block %.loc8_28.3 [concrete = constants.%facet_type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Core.ref.loc8_18: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc8_30: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc8: <bound method> = bound_method %Copy.ref, %impl.elem1 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method.loc8(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc8_28.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type]
// CHECK:STDOUT:       %.loc8_28.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc8_28.2 [concrete = constants.%facet_type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc8_16.2: @F.%pack_type.loc8_16 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc8_16.1 (constants.%T.cd9)]
// CHECK:STDOUT:     %t.param: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = value_param call_param0
// CHECK:STDOUT:     %.loc8_58.1: type = splice_block %.loc8_58.3 [symbolic = %tuple.type.loc8_58.2 (constants.%tuple.type.a1b)] {
// CHECK:STDOUT:       %.loc8_58.2: @F.%tuple.type.loc8_58.1 (%tuple.type.5c4) = tuple_literal (constants.%T.cd9) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:       %.loc8_58.3: type = converted %.loc8_58.2, constants.%tuple.type.a1b [symbolic = %tuple.type.loc8_58.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = wrapper_binding t, %t.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%arity.loc8_6.2: Core.IntLiteral, %T.loc8_16.2: @F.%pack_type.loc8_16 (%pack_type.f50)) {
// CHECK:STDOUT:   %arity.patt.loc8_6.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc8_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc8_6.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc8_6.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc8_16: type = pack_type constants.%facet_type, %arity.loc8_6.1 [symbolic = %pack_type.loc8_16 (constants.%pack_type.f50)]
// CHECK:STDOUT:   %pattern_type.loc8_16: type = pattern_type %pack_type.loc8_16 [symbolic = %pattern_type.loc8_16 (constants.%pattern_type.b23)]
// CHECK:STDOUT:   %T.patt.loc8_16.2: @F.%pattern_type.loc8_16 (%pattern_type.b23) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc8_16.2 (constants.%T.patt.0e6)]
// CHECK:STDOUT:   %T.loc8_16.1: @F.%pack_type.loc8_16 (%pack_type.f50) = symbolic_binding T, 1 [symbolic = %T.loc8_16.1 (constants.%T.cd9)]
// CHECK:STDOUT:   %.loc8_6.2: @F.%pattern_type.loc8_16 (%pattern_type.b23) = pack_expansion_pattern %T.patt.loc8_16.2, %arity.patt.loc8_6.2 [symbolic = %.loc8_6.2 (constants.%.dcc)]
// CHECK:STDOUT:   %.loc8_52.1: Core.IntLiteral = pack_index [symbolic = %.loc8_52.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc8_52.2: %facet_type = pack_element %T.loc8_16.1, %.loc8_52.1 [symbolic = %.loc8_52.2 (constants.%.e27)]
// CHECK:STDOUT:   %tuple.type.loc8_58.1: type = tuple_type (%pack_type.loc8_16) [symbolic = %tuple.type.loc8_58.1 (constants.%tuple.type.5c4)]
// CHECK:STDOUT:   %tuple: @F.%tuple.type.loc8_58.1 (%tuple.type.5c4) = tuple_value (%T.loc8_16.1) [symbolic = %tuple (constants.%tuple.4b7)]
// CHECK:STDOUT:   %pack_type.loc8_58: type = pack_type %T.loc8_16.1, %arity.loc8_6.1 [symbolic = %pack_type.loc8_58 (constants.%pack_type.b88)]
// CHECK:STDOUT:   %tuple.type.loc8_58.2: type = tuple_type (%pack_type.loc8_58) [symbolic = %tuple.type.loc8_58.2 (constants.%tuple.type.a1b)]
// CHECK:STDOUT:   %pattern_type.loc8_45: type = pattern_type %tuple.type.loc8_58.2 [symbolic = %pattern_type.loc8_45 (constants.%pattern_type.877)]
// CHECK:STDOUT:   %t.param_patt.loc8_45.2: @F.%pattern_type.loc8_45 (%pattern_type.877) = value_param_pattern [symbolic = %t.param_patt.loc8_45.2 (constants.%t.param_patt)]
// CHECK:STDOUT:   %t.patt.loc8_45.2: @F.%pattern_type.loc8_45 (%pattern_type.877) = wrapper_binding_pattern t, %t.param_patt.loc8_45.2 [symbolic = %t.patt.loc8_45.2 (constants.%t.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %tuple.type.loc8_58.2 [symbolic = %require_complete (constants.%require_complete.91b)]
// CHECK:STDOUT:   %G.specific_fn.loc9_3.2: <specific function> = specific_function constants.%G, @G(%arity.loc8_6.1, %T.loc8_16.1) [symbolic = %G.specific_fn.loc9_3.2 (constants.%G.specific_fn)]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type.loc8_58.2, @Destroy [symbolic = %Destroy.lookup_impl_witness (constants.%Destroy.lookup_impl_witness.ec7)]
// CHECK:STDOUT:   %Destroy.facet.loc9_6.3: %Destroy.type = facet_value %tuple.type.loc8_58.2, (%Destroy.lookup_impl_witness) [symbolic = %Destroy.facet.loc9_6.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet.loc9_6.3) [symbolic = %Destroy.WithSelf.SelfDestruct.type (constants.%Destroy.WithSelf.SelfDestruct.type.e63)]
// CHECK:STDOUT:   %.loc9_6.5: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type, %Destroy.facet.loc9_6.3 [symbolic = %.loc9_6.5 (constants.%.24c)]
// CHECK:STDOUT:   %impl.elem2.loc9_6.2: @F.%.loc9_6.5 (%.24c) = impl_witness_access %Destroy.lookup_impl_witness, element2 [symbolic = %impl.elem2.loc9_6.2 (constants.%impl.elem2)]
// CHECK:STDOUT:   %specific_impl_fn.loc9_6.2: <specific function> = specific_impl_function %impl.elem2.loc9_6.2, @Destroy.WithSelf.SelfDestruct(%Destroy.facet.loc9_6.3) [symbolic = %specific_impl_fn.loc9_6.2 (constants.%specific_impl_fn.098)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %G.ref: %G.type = name_ref G, file.%G.decl [concrete = constants.%G]
// CHECK:STDOUT:     %t.ref: @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = name_ref t, %t
// CHECK:STDOUT:     %G.specific_fn.loc9_3.1: <specific function> = specific_function %G.ref, @G(constants.%arity, constants.%T.cd9) [symbolic = %G.specific_fn.loc9_3.2 (constants.%G.specific_fn)]
// CHECK:STDOUT:     %.loc9_6.1: ref @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = temporary_storage
// CHECK:STDOUT:     %G.call: init @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) to %.loc9_6.1 = call %G.specific_fn.loc9_3.1(%t.ref)
// CHECK:STDOUT:     %.loc9_6.2: ref @F.%tuple.type.loc8_58.2 (%tuple.type.a1b) = temporary %.loc9_6.1, %G.call
// CHECK:STDOUT:     %impl.elem2.loc9_6.1: @F.%.loc9_6.5 (%.24c) = impl_witness_access constants.%Destroy.lookup_impl_witness.ec7, element2 [symbolic = %impl.elem2.loc9_6.2 (constants.%impl.elem2)]
// CHECK:STDOUT:     %bound_method.loc9_6.1: <bound method> = bound_method %.loc9_6.2, %impl.elem2.loc9_6.1
// CHECK:STDOUT:     %Destroy.facet.loc9_6.1: %Destroy.type = facet_value constants.%tuple.type.a1b, (constants.%Destroy.lookup_impl_witness.ec7) [symbolic = %Destroy.facet.loc9_6.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc9_6.3: %Destroy.type = converted constants.%tuple.type.a1b, %Destroy.facet.loc9_6.1 [symbolic = %Destroy.facet.loc9_6.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %Destroy.facet.loc9_6.2: %Destroy.type = facet_value constants.%tuple.type.a1b, (constants.%Destroy.lookup_impl_witness.ec7) [symbolic = %Destroy.facet.loc9_6.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %.loc9_6.4: %Destroy.type = converted constants.%tuple.type.a1b, %Destroy.facet.loc9_6.2 [symbolic = %Destroy.facet.loc9_6.3 (constants.%Destroy.facet)]
// CHECK:STDOUT:     %specific_impl_fn.loc9_6.1: <specific function> = specific_impl_function %impl.elem2.loc9_6.1, @Destroy.WithSelf.SelfDestruct(constants.%Destroy.facet) [symbolic = %specific_impl_fn.loc9_6.2 (constants.%specific_impl_fn.098)]
// CHECK:STDOUT:     %bound_method.loc9_6.2: <bound method> = bound_method %.loc9_6.2, %specific_impl_fn.loc9_6.1
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method.loc9_6.2(%.loc9_6.2)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%arity, constants.%T.cd9) {
// CHECK:STDOUT:   %arity.patt.loc8_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc8_6.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc8_16 => constants.%pack_type.f50
// CHECK:STDOUT:   %pattern_type.loc8_16 => constants.%pattern_type.b23
// CHECK:STDOUT:   %T.patt.loc8_16.2 => constants.%T.patt.0e6
// CHECK:STDOUT:   %T.loc8_16.1 => constants.%T.cd9
// CHECK:STDOUT:   %.loc8_6.2 => constants.%.dcc
// CHECK:STDOUT:   %.loc8_52.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc8_52.2 => constants.%.e27
// CHECK:STDOUT:   %tuple.type.loc8_58.1 => constants.%tuple.type.5c4
// CHECK:STDOUT:   %tuple => constants.%tuple.4b7
// CHECK:STDOUT:   %pack_type.loc8_58 => constants.%pack_type.b88
// CHECK:STDOUT:   %tuple.type.loc8_58.2 => constants.%tuple.type.a1b
// CHECK:STDOUT:   %pattern_type.loc8_45 => constants.%pattern_type.877
// CHECK:STDOUT:   %t.param_patt.loc8_45.2 => constants.%t.param_patt
// CHECK:STDOUT:   %t.patt.loc8_45.2 => constants.%t.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
