// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/slice/write_through.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/slice/write_through.carbon

// --- write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Write(s: Core.Slice(i32), i: i64) {
  s[i] = s[0] + 1;
}
//@dump-sem-ir-end

// --- generic_write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Fill[T: Core.Copy & Core.Destroy](s: Core.Slice(T), v: T) {
  s[0] = v;
}
//@dump-sem-ir-end

// --- generic_write_const_element.carbon
library "[[@TEST_NAME]]";

// W-327's current behavior, pinned: the generic body writes through
// `Slice(T)`, and the specific at `T = const i32` is not diagnosed.
fn Fill[T: Core.Copy & Core.Destroy](s: Core.Slice(T), v: T) {
  s[0] = v;
}

fn G(c: Core.Slice(const i32)) {
  Fill(c, c[1]);
}

// --- fail_const_element.carbon
library "[[@TEST_NAME]]";

fn W(s: Core.Slice(const i32)) {
  // CHECK:STDERR: fail_const_element.carbon:[[@LINE+4]]:3: error: expression is not assignable [AssignmentToNonAssignable]
  // CHECK:STDERR:   s[0] = 1;
  // CHECK:STDERR:   ^~~~
  // CHECK:STDERR:
  s[0] = 1;
}

// --- buf_write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn BufWrite(b: Core.Buf(i32)) {
  b[0] = 7;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- write.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N.fe9) [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type.f48 = symbolic_binding T, 0 [symbolic]
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
// CHECK:STDOUT:   %i.param_patt: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %i.patt: %pattern_type.f57 = wrapper_binding_pattern i, %i.param_patt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f: <witness> = custom_witness (%Destroy.WithSelf.Op.403, %Destroy.WithSelf.SubobjectDestroy.d01, %Destroy.WithSelf.SelfDestruct.db3), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.f48 = facet_value %i32, (%custom_witness.f8f, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Slice.649: type = class_type @Slice, @Slice(%facet_value) [concrete]
// CHECK:STDOUT:   %pattern_type.bbd: type = pattern_type %Slice.649 [concrete]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.bbd = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.bbd = wrapper_binding_pattern s, %s.param_patt [concrete]
// CHECK:STDOUT:   %Write.type: type = fn_type @Write [concrete]
// CHECK:STDOUT:   %Write: %Write.type = struct_value () [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.type.841: type = generic_interface_type @IndirectIndexWith [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.generic: %IndirectIndexWith.type.841 = struct_value () [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.type.fb1: type = facet_type <@IndirectIndexWith, @IndirectIndexWith(%i64)> [concrete]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.type.ef1: type = fn_type @Slice.as.IndirectIndexWith.impl.Ref, @Slice.as.IndirectIndexWith.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.a92: %Slice.as.IndirectIndexWith.impl.Ref.type.ef1 = struct_value () [symbolic]
// CHECK:STDOUT:   %IndirectIndexWith.impl_witness.9b2: <witness> = impl_witness imports.%IndirectIndexWith.impl_witness_table, @Slice.as.IndirectIndexWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.type.08d: type = fn_type @Slice.as.IndirectIndexWith.impl.Ref, @Slice.as.IndirectIndexWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.00b: %Slice.as.IndirectIndexWith.impl.Ref.type.08d = struct_value () [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.facet.b2a: %IndirectIndexWith.type.fb1 = facet_value %Slice.649, (%IndirectIndexWith.impl_witness.9b2) [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.WithSelf.Ref.type.ae1: type = fn_type @IndirectIndexWith.WithSelf.Ref, @IndirectIndexWith.WithSelf(%i64, %IndirectIndexWith.facet.b2a) [concrete]
// CHECK:STDOUT:   %.ed2: type = fn_type_with_self_type %IndirectIndexWith.WithSelf.Ref.type.ae1, %IndirectIndexWith.facet.b2a [concrete]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.specific_fn: <specific function> = specific_function %Slice.as.IndirectIndexWith.impl.Ref.00b, @Slice.as.IndirectIndexWith.impl.Ref(%facet_value) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %IndexWith.type.df6: type = generic_interface_type @IndexWith [concrete]
// CHECK:STDOUT:   %IndexWith.generic: %IndexWith.type.df6 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.235: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet.235 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.1: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%N.fe9, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.1: %Int.as.AddWith.impl.Op.type.1eac76.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.2: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%N.fe9, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.2: %Int.as.AddWith.impl.Op.type.1eac76.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.aa4: <witness> = impl_witness imports.%AddWith.impl_witness_table.b21, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.1: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.2: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.2: %Int.as.AddWith.impl.Op.type.bddb3c.2 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.3de: %AddWith.type.832 = facet_value %i32, (%AddWith.impl_witness.aa4) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.b60: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(Core.IntLiteral, %AddWith.facet.3de) [concrete]
// CHECK:STDOUT:   %.fbe: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.b60, %AddWith.facet.3de [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.1: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.2, @Int.as.AddWith.impl.Op.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.2: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.1, @Int.as.AddWith.impl.Op.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .IndirectIndexWith = %Core.IndirectIndexWith
// CHECK:STDOUT:     .IndexWith = %Core.IndexWith
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.import_ref.717: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/slice, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.717), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.IndirectIndexWith: %IndirectIndexWith.type.841 = import_ref Core//prelude/operators/index, IndirectIndexWith, loaded [concrete = constants.%IndirectIndexWith.generic]
// CHECK:STDOUT:   %Core.import_ref.ef4 = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.440: @Slice.as.IndirectIndexWith.impl.%Slice.as.IndirectIndexWith.impl.Ref.type (%Slice.as.IndirectIndexWith.impl.Ref.type.ef1) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.IndirectIndexWith.impl.%Slice.as.IndirectIndexWith.impl.Ref (constants.%Slice.as.IndirectIndexWith.impl.Ref.a92)]
// CHECK:STDOUT:   %IndirectIndexWith.impl_witness_table = impl_witness_table (%Core.import_ref.ef4, %Core.import_ref.440), @Slice.as.IndirectIndexWith.impl [concrete]
// CHECK:STDOUT:   %Core.IndexWith: %IndexWith.type.df6 = import_ref Core//prelude/operators/index, IndexWith, loaded [concrete = constants.%IndexWith.generic]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3a: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.b21 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.8a3a), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc4 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Write.decl: %Write.type = fn_decl @Write [concrete = constants.%Write] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.bbd = value_param_pattern [concrete = constants.%s.param_patt]
// CHECK:STDOUT:     %s.patt: %pattern_type.bbd = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt]
// CHECK:STDOUT:     %i.param_patt: %pattern_type.f57 = value_param_pattern [concrete = constants.%i.param_patt]
// CHECK:STDOUT:     %i.patt: %pattern_type.f57 = wrapper_binding_pattern i, %i.param_patt [concrete = constants.%i.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %s.param: %Slice.649 = value_param call_param0
// CHECK:STDOUT:     %.loc4_27.1: type = splice_block %Slice [concrete = constants.%Slice.649] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %facet_value: %facet_type.f48 = facet_value %i32, (constants.%custom_witness.f8f, constants.%Copy.impl_witness.b51) [concrete = constants.%facet_value]
// CHECK:STDOUT:       %.loc4_27.2: %facet_type.f48 = converted %i32, %facet_value [concrete = constants.%facet_value]
// CHECK:STDOUT:       %Slice: type = class_type @Slice, @Slice(constants.%facet_value) [concrete = constants.%Slice.649]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: %Slice.649 = wrapper_binding s, %s.param
// CHECK:STDOUT:     %i.param: %i64 = value_param call_param1
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %i: %i64 = wrapper_binding i, %i.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc4(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc4(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Write(%s.param: %Slice.649, %i.param: %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %s.ref.loc5_3: %Slice.649 = name_ref s, %s
// CHECK:STDOUT:   %i.ref: %i64 = name_ref i, %i
// CHECK:STDOUT:   %impl.elem1.loc5_6: %.ed2 = impl_witness_access constants.%IndirectIndexWith.impl_witness.9b2, element1 [concrete = constants.%Slice.as.IndirectIndexWith.impl.Ref.00b]
// CHECK:STDOUT:   %bound_method.loc5_6.1: <bound method> = bound_method %s.ref.loc5_3, %impl.elem1.loc5_6
// CHECK:STDOUT:   %specific_fn.loc5_6: <specific function> = specific_function %impl.elem1.loc5_6, @Slice.as.IndirectIndexWith.impl.Ref(constants.%facet_value) [concrete = constants.%Slice.as.IndirectIndexWith.impl.Ref.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_6.2: <bound method> = bound_method %s.ref.loc5_3, %specific_fn.loc5_6
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.call.loc5_6: ref %i32 = call %bound_method.loc5_6.2(%s.ref.loc5_3, %i.ref)
// CHECK:STDOUT:   %s.ref.loc5_10: %Slice.649 = name_ref s, %s
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc5_12: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc5_12.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_12 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc5_12: <specific function> = specific_function %impl.elem0.loc5_12, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc5_12.2: <bound method> = bound_method %int_0, %specific_fn.loc5_12 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_12: init %i64 = call %bound_method.loc5_12.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc5_12.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_12 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc5_12.2: %i64 = converted %int_0, %.loc5_12.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %impl.elem1.loc5_13: %.ed2 = impl_witness_access constants.%IndirectIndexWith.impl_witness.9b2, element1 [concrete = constants.%Slice.as.IndirectIndexWith.impl.Ref.00b]
// CHECK:STDOUT:   %bound_method.loc5_13.1: <bound method> = bound_method %s.ref.loc5_10, %impl.elem1.loc5_13
// CHECK:STDOUT:   %specific_fn.loc5_13: <specific function> = specific_function %impl.elem1.loc5_13, @Slice.as.IndirectIndexWith.impl.Ref(constants.%facet_value) [concrete = constants.%Slice.as.IndirectIndexWith.impl.Ref.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_13.2: <bound method> = bound_method %s.ref.loc5_10, %specific_fn.loc5_13
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.call.loc5_13: ref %i32 = call %bound_method.loc5_13.2(%s.ref.loc5_10, %.loc5_12.2)
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc5_15: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:   %bound_method.loc5_15.1: <bound method> = bound_method %Slice.as.IndirectIndexWith.impl.Ref.call.loc5_13, %impl.elem1.loc5_15
// CHECK:STDOUT:   %specific_fn.loc5_15: <specific function> = specific_function %impl.elem1.loc5_15, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:   %bound_method.loc5_15.2: <bound method> = bound_method %Slice.as.IndirectIndexWith.impl.Ref.call.loc5_13, %specific_fn.loc5_15
// CHECK:STDOUT:   %.loc5_13: %i32 = acquire_value %Slice.as.IndirectIndexWith.impl.Ref.call.loc5_13
// CHECK:STDOUT:   %.loc5_15: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc5_15 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %.loc5_13, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:   %bound_method.loc5_15.3: <bound method> = bound_method %.loc5_13, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc5_17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc5_17.1: <bound method> = bound_method %int_1, %impl.elem0.loc5_17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc5_17: <specific function> = specific_function %impl.elem0.loc5_17, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc5_17.2: <bound method> = bound_method %int_1, %specific_fn.loc5_17 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_17: init %i32 = call %bound_method.loc5_17.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc5_17.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_17 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc5_17.2: %i32 = converted %int_1, %.loc5_17.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc5_15.3(%.loc5_13, %.loc5_17.2)
// CHECK:STDOUT:   assign %Slice.as.IndirectIndexWith.impl.Ref.call.loc5_6, %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic_write.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.e58: type = symbolic_binding .Self [symbolic_self]
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
// CHECK:STDOUT:   %Copy.lookup_impl_witness.fd8: <witness> = lookup_impl_witness %T.dc4, @Copy [symbolic]
// CHECK:STDOUT:   %Copy.facet.40c: %Copy.type = facet_value %T.as_type.5d6, (%Copy.lookup_impl_witness.fd8) [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.39e: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.40c) [symbolic]
// CHECK:STDOUT:   %.843: type = fn_type_with_self_type %Copy.WithSelf.Op.type.39e, %Copy.facet.40c [symbolic]
// CHECK:STDOUT:   %impl.elem0.f20: %.843 = impl_witness_access %Copy.lookup_impl_witness.fd8, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.6a5: <specific function> = specific_impl_function %impl.elem0.f20, @Copy.WithSelf.Op(%Copy.facet.40c) [symbolic]
// CHECK:STDOUT:   %require_complete.091: <witness> = require_complete_type %T.as_type.5d6 [symbolic]
// CHECK:STDOUT:   %s.param_patt: %pattern_type.f90 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %s.patt: %pattern_type.f90 = wrapper_binding_pattern s, %s.param_patt [symbolic]
// CHECK:STDOUT:   %v.param_patt: %pattern_type.0e9 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %v.patt: %pattern_type.0e9 = wrapper_binding_pattern v, %v.param_patt [symbolic]
// CHECK:STDOUT:   %Fill.type: type = fn_type @Fill [concrete]
// CHECK:STDOUT:   %Fill: %Fill.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %IndexWith.type.df6: type = generic_interface_type @IndexWith [concrete]
// CHECK:STDOUT:   %IndexWith.generic: %IndexWith.type.df6 = struct_value () [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.type.841: type = generic_interface_type @IndirectIndexWith [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.generic: %IndirectIndexWith.type.841 = struct_value () [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.type.fb1: type = facet_type <@IndirectIndexWith, @IndirectIndexWith(%i64)> [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.impl_witness: <witness> = impl_witness imports.%IndirectIndexWith.impl_witness_table, @Slice.as.IndirectIndexWith.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.type: type = fn_type @Slice.as.IndirectIndexWith.impl.Ref, @Slice.as.IndirectIndexWith.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref: %Slice.as.IndirectIndexWith.impl.Ref.type = struct_value () [symbolic]
// CHECK:STDOUT:   %.d34: require_specific_def_type = require_specific_def @Slice.as.IndirectIndexWith.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.facet.c9c: %IndirectIndexWith.type.fb1 = facet_value %Slice, (%IndirectIndexWith.impl_witness) [symbolic]
// CHECK:STDOUT:   %IndirectIndexWith.WithSelf.Ref.type.03f: type = fn_type @IndirectIndexWith.WithSelf.Ref, @IndirectIndexWith.WithSelf(%i64, %IndirectIndexWith.facet.c9c) [symbolic]
// CHECK:STDOUT:   %.dd7: type = fn_type_with_self_type %IndirectIndexWith.WithSelf.Ref.type.03f, %IndirectIndexWith.facet.c9c [symbolic]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.specific_fn: <specific function> = specific_function %Slice.as.IndirectIndexWith.impl.Ref, @Slice.as.IndirectIndexWith.impl.Ref(%T.dc4) [symbolic]
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
// CHECK:STDOUT:     .IndirectIndexWith = %Core.IndirectIndexWith
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.BitAndWith: %BitAndWith.type.a06 = import_ref Core//prelude/operators/bitwise, BitAndWith, loaded [concrete = constants.%BitAndWith.generic]
// CHECK:STDOUT:   %Core.import_ref.05b = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %type.as.BitAndWith.impl.Op.type = import_ref Core//prelude/operators/bitwise, loc{{\d+_\d+}}, loaded [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:   %BitAndWith.impl_witness_table = impl_witness_table (%Core.import_ref.05b, %Core.import_ref.9c3), @type.as.BitAndWith.impl [concrete]
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.import_ref.717: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/slice, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.717), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.IndexWith: %IndexWith.type.df6 = import_ref Core//prelude/operators/index, IndexWith, loaded [concrete = constants.%IndexWith.generic]
// CHECK:STDOUT:   %Core.import_ref.ef4 = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.78b: @Slice.as.IndirectIndexWith.impl.%Slice.as.IndirectIndexWith.impl.Ref.type (%Slice.as.IndirectIndexWith.impl.Ref.type) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.IndirectIndexWith.impl.%Slice.as.IndirectIndexWith.impl.Ref (constants.%Slice.as.IndirectIndexWith.impl.Ref)]
// CHECK:STDOUT:   %IndirectIndexWith.impl_witness_table = impl_witness_table (%Core.import_ref.ef4, %Core.import_ref.78b), @Slice.as.IndirectIndexWith.impl [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.IndirectIndexWith: %IndirectIndexWith.type.841 = import_ref Core//prelude/operators/index, IndirectIndexWith, loaded [concrete = constants.%IndirectIndexWith.generic]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Fill.decl: %Fill.type = fn_decl @Fill [concrete = constants.%Fill] {
// CHECK:STDOUT:     %T.patt.loc4_10.1: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_10.2 (constants.%T.patt.256)]
// CHECK:STDOUT:     %s.param_patt.loc4_39.1: @Fill.%pattern_type.loc4_39 (%pattern_type.f90) = value_param_pattern [symbolic = %s.param_patt.loc4_39.2 (constants.%s.param_patt)]
// CHECK:STDOUT:     %s.patt.loc4_39.1: @Fill.%pattern_type.loc4_39 (%pattern_type.f90) = wrapper_binding_pattern s, %s.param_patt.loc4_39.1 [symbolic = %s.patt.loc4_39.2 (constants.%s.patt)]
// CHECK:STDOUT:     %v.param_patt.loc4_57.1: @Fill.%pattern_type.loc4_57 (%pattern_type.0e9) = value_param_pattern [symbolic = %v.param_patt.loc4_57.2 (constants.%v.param_patt)]
// CHECK:STDOUT:     %v.patt.loc4_57.1: @Fill.%pattern_type.loc4_57 (%pattern_type.0e9) = wrapper_binding_pattern v, %v.param_patt.loc4_57.1 [symbolic = %v.patt.loc4_57.2 (constants.%v.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc4_22.1: type = splice_block %.loc4_22.3 [concrete = constants.%facet_type.a1a] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.e58]
// CHECK:STDOUT:       %Core.ref.loc4_12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Copy.ref: type = name_ref Copy, imports.%Core.Copy [concrete = constants.%Copy.type]
// CHECK:STDOUT:       %Core.ref.loc4_24: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Destroy.ref: type = name_ref Destroy, imports.%Core.Destroy [concrete = constants.%Destroy.type]
// CHECK:STDOUT:       %impl.elem1.loc4: %.85c = impl_witness_access constants.%BitAndWith.impl_witness, element1 [concrete = constants.%type.as.BitAndWith.impl.Op]
// CHECK:STDOUT:       %bound_method.loc4: <bound method> = bound_method %Copy.ref, %impl.elem1.loc4 [concrete = constants.%type.as.BitAndWith.impl.Op.bound]
// CHECK:STDOUT:       %type.as.BitAndWith.impl.Op.call: init type = call %bound_method.loc4(%Copy.ref, %Destroy.ref) [concrete = constants.%facet_type.a1a]
// CHECK:STDOUT:       %.loc4_22.2: type = value_of_initializer %type.as.BitAndWith.impl.Op.call [concrete = constants.%facet_type.a1a]
// CHECK:STDOUT:       %.loc4_22.3: type = converted %type.as.BitAndWith.impl.Op.call, %.loc4_22.2 [concrete = constants.%facet_type.a1a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_10.2: %facet_type.a1a = symbolic_binding T, 0 [symbolic = %T.loc4_10.1 (constants.%T.dc4)]
// CHECK:STDOUT:     %s.param: @Fill.%Slice.loc4_53.1 (%Slice) = value_param call_param0
// CHECK:STDOUT:     %.loc4_53: type = splice_block %Slice.loc4_53.2 [symbolic = %Slice.loc4_53.1 (constants.%Slice)] {
// CHECK:STDOUT:       %Core.ref.loc4_41: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:       %T.ref.loc4_52: %facet_type.a1a = name_ref T, %T.loc4_10.2 [symbolic = %T.loc4_10.1 (constants.%T.dc4)]
// CHECK:STDOUT:       %Slice.loc4_53.2: type = class_type @Slice, @Slice(constants.%T.dc4) [symbolic = %Slice.loc4_53.1 (constants.%Slice)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: @Fill.%Slice.loc4_53.1 (%Slice) = wrapper_binding s, %s.param
// CHECK:STDOUT:     %v.param: @Fill.%T.as_type.loc4_59.1 (%T.as_type.5d6) = value_param call_param1
// CHECK:STDOUT:     %.loc4_59.1: type = splice_block %.loc4_59.2 [symbolic = %T.as_type.loc4_59.1 (constants.%T.as_type.5d6)] {
// CHECK:STDOUT:       %T.ref.loc4_59: %facet_type.a1a = name_ref T, %T.loc4_10.2 [symbolic = %T.loc4_10.1 (constants.%T.dc4)]
// CHECK:STDOUT:       %T.as_type.loc4_59.2: type = facet_access_type %T.ref.loc4_59 [symbolic = %T.as_type.loc4_59.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:       %.loc4_59.2: type = converted %T.ref.loc4_59, %T.as_type.loc4_59.2 [symbolic = %T.as_type.loc4_59.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v: @Fill.%T.as_type.loc4_59.1 (%T.as_type.5d6) = wrapper_binding v, %v.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Fill(%T.loc4_10.2: %facet_type.a1a) {
// CHECK:STDOUT:   %T.patt.loc4_10.2: %pattern_type.143 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_10.2 (constants.%T.patt.256)]
// CHECK:STDOUT:   %T.loc4_10.1: %facet_type.a1a = symbolic_binding T, 0 [symbolic = %T.loc4_10.1 (constants.%T.dc4)]
// CHECK:STDOUT:   %Slice.loc4_53.1: type = class_type @Slice, @Slice(%T.loc4_10.1) [symbolic = %Slice.loc4_53.1 (constants.%Slice)]
// CHECK:STDOUT:   %pattern_type.loc4_39: type = pattern_type %Slice.loc4_53.1 [symbolic = %pattern_type.loc4_39 (constants.%pattern_type.f90)]
// CHECK:STDOUT:   %s.param_patt.loc4_39.2: @Fill.%pattern_type.loc4_39 (%pattern_type.f90) = value_param_pattern [symbolic = %s.param_patt.loc4_39.2 (constants.%s.param_patt)]
// CHECK:STDOUT:   %s.patt.loc4_39.2: @Fill.%pattern_type.loc4_39 (%pattern_type.f90) = wrapper_binding_pattern s, %s.param_patt.loc4_39.2 [symbolic = %s.patt.loc4_39.2 (constants.%s.patt)]
// CHECK:STDOUT:   %T.as_type.loc4_59.1: type = facet_access_type %T.loc4_10.1 [symbolic = %T.as_type.loc4_59.1 (constants.%T.as_type.5d6)]
// CHECK:STDOUT:   %pattern_type.loc4_57: type = pattern_type %T.as_type.loc4_59.1 [symbolic = %pattern_type.loc4_57 (constants.%pattern_type.0e9)]
// CHECK:STDOUT:   %v.param_patt.loc4_57.2: @Fill.%pattern_type.loc4_57 (%pattern_type.0e9) = value_param_pattern [symbolic = %v.param_patt.loc4_57.2 (constants.%v.param_patt)]
// CHECK:STDOUT:   %v.patt.loc4_57.2: @Fill.%pattern_type.loc4_57 (%pattern_type.0e9) = wrapper_binding_pattern v, %v.param_patt.loc4_57.2 [symbolic = %v.patt.loc4_57.2 (constants.%v.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_39: <witness> = require_complete_type %Slice.loc4_53.1 [symbolic = %require_complete.loc4_39 (constants.%require_complete.dda)]
// CHECK:STDOUT:   %require_complete.loc4_57: <witness> = require_complete_type %T.as_type.loc4_59.1 [symbolic = %require_complete.loc4_57 (constants.%require_complete.091)]
// CHECK:STDOUT:   %.loc5_6.2: require_specific_def_type = require_specific_def @Slice.as.IndirectIndexWith.impl(%T.loc4_10.1) [symbolic = %.loc5_6.2 (constants.%.d34)]
// CHECK:STDOUT:   %IndirectIndexWith.impl_witness: <witness> = impl_witness imports.%IndirectIndexWith.impl_witness_table, @Slice.as.IndirectIndexWith.impl(%T.loc4_10.1) [symbolic = %IndirectIndexWith.impl_witness (constants.%IndirectIndexWith.impl_witness)]
// CHECK:STDOUT:   %IndirectIndexWith.facet: %IndirectIndexWith.type.fb1 = facet_value %Slice.loc4_53.1, (%IndirectIndexWith.impl_witness) [symbolic = %IndirectIndexWith.facet (constants.%IndirectIndexWith.facet.c9c)]
// CHECK:STDOUT:   %IndirectIndexWith.WithSelf.Ref.type: type = fn_type @IndirectIndexWith.WithSelf.Ref, @IndirectIndexWith.WithSelf(constants.%i64, %IndirectIndexWith.facet) [symbolic = %IndirectIndexWith.WithSelf.Ref.type (constants.%IndirectIndexWith.WithSelf.Ref.type.03f)]
// CHECK:STDOUT:   %.loc5_6.3: type = fn_type_with_self_type %IndirectIndexWith.WithSelf.Ref.type, %IndirectIndexWith.facet [symbolic = %.loc5_6.3 (constants.%.dd7)]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.type: type = fn_type @Slice.as.IndirectIndexWith.impl.Ref, @Slice.as.IndirectIndexWith.impl(%T.loc4_10.1) [symbolic = %Slice.as.IndirectIndexWith.impl.Ref.type (constants.%Slice.as.IndirectIndexWith.impl.Ref.type)]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref: @Fill.%Slice.as.IndirectIndexWith.impl.Ref.type (%Slice.as.IndirectIndexWith.impl.Ref.type) = struct_value () [symbolic = %Slice.as.IndirectIndexWith.impl.Ref (constants.%Slice.as.IndirectIndexWith.impl.Ref)]
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.specific_fn: <specific function> = specific_function %Slice.as.IndirectIndexWith.impl.Ref, @Slice.as.IndirectIndexWith.impl.Ref(%T.loc4_10.1) [symbolic = %Slice.as.IndirectIndexWith.impl.Ref.specific_fn (constants.%Slice.as.IndirectIndexWith.impl.Ref.specific_fn)]
// CHECK:STDOUT:   %Copy.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc4_10.1, @Copy [symbolic = %Copy.lookup_impl_witness (constants.%Copy.lookup_impl_witness.fd8)]
// CHECK:STDOUT:   %Copy.facet.loc5_10.3: %Copy.type = facet_value %T.as_type.loc4_59.1, (%Copy.lookup_impl_witness) [symbolic = %Copy.facet.loc5_10.3 (constants.%Copy.facet.40c)]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.loc5_10.3) [symbolic = %Copy.WithSelf.Op.type (constants.%Copy.WithSelf.Op.type.39e)]
// CHECK:STDOUT:   %.loc5_10.3: type = fn_type_with_self_type %Copy.WithSelf.Op.type, %Copy.facet.loc5_10.3 [symbolic = %.loc5_10.3 (constants.%.843)]
// CHECK:STDOUT:   %impl.elem0.loc5_10.2: @Fill.%.loc5_10.3 (%.843) = impl_witness_access %Copy.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc5_10.2 (constants.%impl.elem0.f20)]
// CHECK:STDOUT:   %specific_impl_fn.loc5_10.2: <specific function> = specific_impl_function %impl.elem0.loc5_10.2, @Copy.WithSelf.Op(%Copy.facet.loc5_10.3) [symbolic = %specific_impl_fn.loc5_10.2 (constants.%specific_impl_fn.6a5)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%s.param: @Fill.%Slice.loc4_53.1 (%Slice), %v.param: @Fill.%T.as_type.loc4_59.1 (%T.as_type.5d6)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %s.ref: @Fill.%Slice.loc4_53.1 (%Slice) = name_ref s, %s
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc5_5: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc5_5.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_5 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:     %specific_fn.loc5_5: <specific function> = specific_function %impl.elem0.loc5_5, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc5_5.2: <bound method> = bound_method %int_0, %specific_fn.loc5_5 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc5_5.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc5_5.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc5_5.2: %i64 = converted %int_0, %.loc5_5.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %impl.elem1.loc5: @Fill.%.loc5_6.3 (%.dd7) = impl_witness_access constants.%IndirectIndexWith.impl_witness, element1 [symbolic = %Slice.as.IndirectIndexWith.impl.Ref (constants.%Slice.as.IndirectIndexWith.impl.Ref)]
// CHECK:STDOUT:     %bound_method.loc5_6.1: <bound method> = bound_method %s.ref, %impl.elem1.loc5
// CHECK:STDOUT:     %specific_fn.loc5_6: <specific function> = specific_function %impl.elem1.loc5, @Slice.as.IndirectIndexWith.impl.Ref(constants.%T.dc4) [symbolic = %Slice.as.IndirectIndexWith.impl.Ref.specific_fn (constants.%Slice.as.IndirectIndexWith.impl.Ref.specific_fn)]
// CHECK:STDOUT:     %bound_method.loc5_6.2: <bound method> = bound_method %s.ref, %specific_fn.loc5_6
// CHECK:STDOUT:     %Slice.as.IndirectIndexWith.impl.Ref.call: ref @Fill.%T.as_type.loc4_59.1 (%T.as_type.5d6) = call %bound_method.loc5_6.2(%s.ref, %.loc5_5.2)
// CHECK:STDOUT:     %v.ref: @Fill.%T.as_type.loc4_59.1 (%T.as_type.5d6) = name_ref v, %v
// CHECK:STDOUT:     %impl.elem0.loc5_10.1: @Fill.%.loc5_10.3 (%.843) = impl_witness_access constants.%Copy.lookup_impl_witness.fd8, element0 [symbolic = %impl.elem0.loc5_10.2 (constants.%impl.elem0.f20)]
// CHECK:STDOUT:     %bound_method.loc5_10.1: <bound method> = bound_method %v.ref, %impl.elem0.loc5_10.1
// CHECK:STDOUT:     %Copy.facet.loc5_10.1: %Copy.type = facet_value constants.%T.as_type.5d6, (constants.%Copy.lookup_impl_witness.fd8) [symbolic = %Copy.facet.loc5_10.3 (constants.%Copy.facet.40c)]
// CHECK:STDOUT:     %.loc5_10.1: %Copy.type = converted constants.%T.as_type.5d6, %Copy.facet.loc5_10.1 [symbolic = %Copy.facet.loc5_10.3 (constants.%Copy.facet.40c)]
// CHECK:STDOUT:     %Copy.facet.loc5_10.2: %Copy.type = facet_value constants.%T.as_type.5d6, (constants.%Copy.lookup_impl_witness.fd8) [symbolic = %Copy.facet.loc5_10.3 (constants.%Copy.facet.40c)]
// CHECK:STDOUT:     %.loc5_10.2: %Copy.type = converted constants.%T.as_type.5d6, %Copy.facet.loc5_10.2 [symbolic = %Copy.facet.loc5_10.3 (constants.%Copy.facet.40c)]
// CHECK:STDOUT:     %specific_impl_fn.loc5_10.1: <specific function> = specific_impl_function %impl.elem0.loc5_10.1, @Copy.WithSelf.Op(constants.%Copy.facet.40c) [symbolic = %specific_impl_fn.loc5_10.2 (constants.%specific_impl_fn.6a5)]
// CHECK:STDOUT:     %bound_method.loc5_10.2: <bound method> = bound_method %v.ref, %specific_impl_fn.loc5_10.1
// CHECK:STDOUT:     %.loc5_6.1: ref @Fill.%T.as_type.loc4_59.1 (%T.as_type.5d6) = splice_block %Slice.as.IndirectIndexWith.impl.Ref.call {}
// CHECK:STDOUT:     %Copy.WithSelf.Op.call: init @Fill.%T.as_type.loc4_59.1 (%T.as_type.5d6) to %.loc5_6.1 = call %bound_method.loc5_10.2(%v.ref)
// CHECK:STDOUT:     assign %Slice.as.IndirectIndexWith.impl.Ref.call, %Copy.WithSelf.Op.call
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Fill(constants.%T.dc4) {
// CHECK:STDOUT:   %T.patt.loc4_10.2 => constants.%T.patt.256
// CHECK:STDOUT:   %T.loc4_10.1 => constants.%T.dc4
// CHECK:STDOUT:   %Slice.loc4_53.1 => constants.%Slice
// CHECK:STDOUT:   %pattern_type.loc4_39 => constants.%pattern_type.f90
// CHECK:STDOUT:   %s.param_patt.loc4_39.2 => constants.%s.param_patt
// CHECK:STDOUT:   %s.patt.loc4_39.2 => constants.%s.patt
// CHECK:STDOUT:   %T.as_type.loc4_59.1 => constants.%T.as_type.5d6
// CHECK:STDOUT:   %pattern_type.loc4_57 => constants.%pattern_type.0e9
// CHECK:STDOUT:   %v.param_patt.loc4_57.2 => constants.%v.param_patt
// CHECK:STDOUT:   %v.patt.loc4_57.2 => constants.%v.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- buf_write.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Buf.type: type = generic_class_type @Buf [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Buf.generic: %Buf.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
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
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.a1a = facet_value %i32, (%Copy.impl_witness.b51, %custom_witness.f8f19d.1) [concrete]
// CHECK:STDOUT:   %Buf.cfb: type = class_type @Buf, @Buf(%facet_value) [concrete]
// CHECK:STDOUT:   %pattern_type.055: type = pattern_type %Buf.cfb [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.055 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.055 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %BufWrite.type: type = fn_type @BufWrite [concrete]
// CHECK:STDOUT:   %BufWrite: %BufWrite.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %IndexWith.type.df6: type = generic_interface_type @IndexWith [concrete]
// CHECK:STDOUT:   %IndexWith.generic: %IndexWith.type.df6 = struct_value () [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.type.841: type = generic_interface_type @IndirectIndexWith [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.generic: %IndirectIndexWith.type.841 = struct_value () [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.type.fb1: type = facet_type <@IndirectIndexWith, @IndirectIndexWith(%i64)> [concrete]
// CHECK:STDOUT:   %Buf.as.IndirectIndexWith.impl.Ref.type.211: type = fn_type @Buf.as.IndirectIndexWith.impl.Ref, @Buf.as.IndirectIndexWith.impl(%T.dc4) [symbolic]
// CHECK:STDOUT:   %Buf.as.IndirectIndexWith.impl.Ref.dfe: %Buf.as.IndirectIndexWith.impl.Ref.type.211 = struct_value () [symbolic]
// CHECK:STDOUT:   %IndirectIndexWith.impl_witness.63f: <witness> = impl_witness imports.%IndirectIndexWith.impl_witness_table, @Buf.as.IndirectIndexWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Buf.as.IndirectIndexWith.impl.Ref.type.a7c: type = fn_type @Buf.as.IndirectIndexWith.impl.Ref, @Buf.as.IndirectIndexWith.impl(%facet_value) [concrete]
// CHECK:STDOUT:   %Buf.as.IndirectIndexWith.impl.Ref.0c9: %Buf.as.IndirectIndexWith.impl.Ref.type.a7c = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.235: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet.235 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.facet.739: %IndirectIndexWith.type.fb1 = facet_value %Buf.cfb, (%IndirectIndexWith.impl_witness.63f) [concrete]
// CHECK:STDOUT:   %IndirectIndexWith.WithSelf.Ref.type.388: type = fn_type @IndirectIndexWith.WithSelf.Ref, @IndirectIndexWith.WithSelf(%i64, %IndirectIndexWith.facet.739) [concrete]
// CHECK:STDOUT:   %.6d8: type = fn_type_with_self_type %IndirectIndexWith.WithSelf.Ref.type.388, %IndirectIndexWith.facet.739 [concrete]
// CHECK:STDOUT:   %Buf.as.IndirectIndexWith.impl.Ref.specific_fn: <specific function> = specific_function %Buf.as.IndirectIndexWith.impl.Ref.0c9, @Buf.as.IndirectIndexWith.impl.Ref(%facet_value) [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
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
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Buf = %Core.Buf
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .IndexWith = %Core.IndexWith
// CHECK:STDOUT:     .IndirectIndexWith = %Core.IndirectIndexWith
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Buf: %Buf.type = import_ref Core//prelude/types/buf, Buf, loaded [concrete = constants.%Buf.generic]
// CHECK:STDOUT:   %Core.import_ref.cbd: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/buf, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.cbd), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.IndexWith: %IndexWith.type.df6 = import_ref Core//prelude/operators/index, IndexWith, loaded [concrete = constants.%IndexWith.generic]
// CHECK:STDOUT:   %Core.import_ref.5c7 = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.272: @Buf.as.IndirectIndexWith.impl.%Buf.as.IndirectIndexWith.impl.Ref.type (%Buf.as.IndirectIndexWith.impl.Ref.type.211) = import_ref Core//prelude/types/buf, loc{{\d+_\d+}}, loaded [symbolic = @Buf.as.IndirectIndexWith.impl.%Buf.as.IndirectIndexWith.impl.Ref (constants.%Buf.as.IndirectIndexWith.impl.Ref.dfe)]
// CHECK:STDOUT:   %IndirectIndexWith.impl_witness_table = impl_witness_table (%Core.import_ref.5c7, %Core.import_ref.272), @Buf.as.IndirectIndexWith.impl [concrete]
// CHECK:STDOUT:   %Core.IndirectIndexWith: %IndirectIndexWith.type.841 = import_ref Core//prelude/operators/index, IndirectIndexWith, loaded [concrete = constants.%IndirectIndexWith.generic]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc4 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %BufWrite.decl: %BufWrite.type = fn_decl @BufWrite [concrete = constants.%BufWrite] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.055 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.055 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %b.param: %Buf.cfb = value_param call_param0
// CHECK:STDOUT:     %.loc4_28.1: type = splice_block %Buf [concrete = constants.%Buf.cfb] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Buf.ref: %Buf.type = name_ref Buf, imports.%Core.Buf [concrete = constants.%Buf.generic]
// CHECK:STDOUT:       %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %facet_value: %facet_type.a1a = facet_value %i32, (constants.%Copy.impl_witness.b51, constants.%custom_witness.f8f19d.1) [concrete = constants.%facet_value]
// CHECK:STDOUT:       %.loc4_28.2: %facet_type.a1a = converted %i32, %facet_value [concrete = constants.%facet_value]
// CHECK:STDOUT:       %Buf: type = class_type @Buf, @Buf(constants.%facet_value) [concrete = constants.%Buf.cfb]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %Buf.cfb = wrapper_binding b, %b.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc4(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc4(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @BufWrite(%b.param: %Buf.cfb) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: %Buf.cfb = name_ref b, %b
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc5_5: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc5_5.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_5 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc5_5: <specific function> = specific_function %impl.elem0.loc5_5, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc5_5.2: <bound method> = bound_method %int_0, %specific_fn.loc5_5 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_5: init %i64 = call %bound_method.loc5_5.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc5_5.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_5 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc5_5.2: %i64 = converted %int_0, %.loc5_5.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %impl.elem1: %.6d8 = impl_witness_access constants.%IndirectIndexWith.impl_witness.63f, element1 [concrete = constants.%Buf.as.IndirectIndexWith.impl.Ref.0c9]
// CHECK:STDOUT:   %bound_method.loc5_6.1: <bound method> = bound_method %b.ref, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc5_6: <specific function> = specific_function %impl.elem1, @Buf.as.IndirectIndexWith.impl.Ref(constants.%facet_value) [concrete = constants.%Buf.as.IndirectIndexWith.impl.Ref.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_6.2: <bound method> = bound_method %b.ref, %specific_fn.loc5_6
// CHECK:STDOUT:   %Buf.as.IndirectIndexWith.impl.Ref.call: ref %i32 = call %bound_method.loc5_6.2(%b.ref, %.loc5_5.2)
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %impl.elem0.loc5_8: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc5_8.1: <bound method> = bound_method %int_7, %impl.elem0.loc5_8 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc5_8: <specific function> = specific_function %impl.elem0.loc5_8, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc5_8.2: <bound method> = bound_method %int_7, %specific_fn.loc5_8 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_8: init %i32 = call %bound_method.loc5_8.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc5_8: init %i32 = converted %int_7, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_8 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   assign %Buf.as.IndirectIndexWith.impl.Ref.call, %.loc5_8
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
