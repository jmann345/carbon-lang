// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/overloaded/string_indexing.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/overloaded/string_indexing.carbon

// --- fail_literal_negative_index.carbon
library "[[@TEST_NAME]]";

fn TestLiteralNegativeIndex() {
  // CHECK:STDERR: fail_literal_negative_index.carbon:[[@LINE+4]]:24: error: index `-1` is negative. [StringAtIndexNegative]
  // CHECK:STDERR:   let unused c: char = "Test"[-1];
  // CHECK:STDERR:                        ^~~~~~~~~~
  // CHECK:STDERR:
  let unused c: char = "Test"[-1];
}

// --- fail_literal_out_of_bounds.carbon
library "[[@TEST_NAME]]";

fn TestLiteralOutOfBounds() {
  // CHECK:STDERR: fail_literal_out_of_bounds.carbon:[[@LINE+4]]:24: error: string index `4` is out of bounds; string has length 4. [StringAtIndexOutOfBounds]
  // CHECK:STDERR:   let unused c: char = "Test"[4];
  // CHECK:STDERR:                        ^~~~~~~~~
  // CHECK:STDERR:
  let unused c: char = "Test"[4];
}

// --- fail_wrong_type.carbon
library "[[@TEST_NAME]]";

fn TestWrongType() {
  class C{}
  //@dump-sem-ir-begin
  // CHECK:STDERR: fail_wrong_type.carbon:[[@LINE+4]]:3: error: cannot access member of interface `Core.IndexWith(type)` in type `str` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   "Test"[C];
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
  "Test"[C];
  //@dump-sem-ir-end
}

// --- fail_bad_decl.carbon
library "[[@TEST_NAME]]";

// CHECK:STDERR: fail_bad_decl.carbon:[[@LINE+4]]:1: error: invalid signature for builtin function "string.at" [InvalidBuiltinSignature]
// CHECK:STDERR: fn At(s: str, index: i64) -> i32 = "string.at";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn At(s: str, index: i64) -> i32 = "string.at";

// CHECK:STDERR: fail_bad_decl.carbon:[[@LINE+4]]:1: error: invalid signature for builtin function "string.at" [InvalidBuiltinSignature]
// CHECK:STDERR: fn At2(s: str) -> char = "string.at";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn At2(s: str) -> char = "string.at";

// CHECK:STDERR: fail_bad_decl.carbon:[[@LINE+4]]:1: error: invalid signature for builtin function "string.at" [InvalidBuiltinSignature]
// CHECK:STDERR: fn At3(s: i32, index: i64) -> char = "string.at";
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn At3(s: i32, index: i64) -> char = "string.at";

// --- test_string_indexing.carbon
library "[[@TEST_NAME]]";

fn TestStringIndexing() {
  //@dump-sem-ir-begin
  let unused c: char = "Test"[0];
  let unused d: char = "Test"[3];
  //@dump-sem-ir-end
}

// CHECK:STDOUT: --- fail_wrong_type.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %str.3d4: type = class_type @String [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %ptr.b46: type = ptr_type %char [concrete]
// CHECK:STDOUT:   %str.4f8: %ptr.b46 = string_literal "Test" [concrete]
// CHECK:STDOUT:   %int_4: %i64 = int_value 4 [concrete]
// CHECK:STDOUT:   %String.val: %str.3d4 = struct_value (%str.4f8, %int_4) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @TestWrongType() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %str: %ptr.b46 = string_literal "Test" [concrete = constants.%str.4f8]
// CHECK:STDOUT:   %int_4: %i64 = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:   %String.val: %str.3d4 = struct_value (%str, %int_4) [concrete = constants.%String.val]
// CHECK:STDOUT:   %C.ref: type = name_ref C, %C.decl [concrete = constants.%C]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- test_string_indexing.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %pattern_type.2ff: type = pattern_type %char [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.2ff = value_binding_pattern c [concrete]
// CHECK:STDOUT:   %str.3d4: type = class_type @String [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %ptr.b46: type = ptr_type %char [concrete]
// CHECK:STDOUT:   %str.4f8: %ptr.b46 = string_literal "Test" [concrete]
// CHECK:STDOUT:   %int_4: %i64 = int_value 4 [concrete]
// CHECK:STDOUT:   %String.val: %str.3d4 = struct_value (%str.4f8, %int_4) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %IndexWith.type.385: type = facet_type <@IndexWith, @IndexWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %T.2f3: %ImplicitAs.type.221 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.type.62ebd3.1: type = fn_type @str.as.IndexWith.impl.At.1, @str.as.IndexWith.impl(%T.2f3) [symbolic]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.887ac3.1: %str.as.IndexWith.impl.At.type.62ebd3.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.type.62ebd3.2: type = fn_type @str.as.IndexWith.impl.At.2, @str.as.IndexWith.impl(%T.2f3) [symbolic]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.887ac3.2: %str.as.IndexWith.impl.At.type.62ebd3.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.227: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %IndexWith.impl_witness.567: <witness> = impl_witness imports.%IndexWith.impl_witness_table, @str.as.IndexWith.impl(%ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.type.e2e5ac.1: type = fn_type @str.as.IndexWith.impl.At.2, @str.as.IndexWith.impl(%ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.0889f8.1: %str.as.IndexWith.impl.At.type.e2e5ac.1 = struct_value () [concrete]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.type.e2e5ac.2: type = fn_type @str.as.IndexWith.impl.At.1, @str.as.IndexWith.impl(%ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.0889f8.2: %str.as.IndexWith.impl.At.type.e2e5ac.2 = struct_value () [concrete]
// CHECK:STDOUT:   %IndexWith.facet.3c4: %IndexWith.type.385 = facet_value %str.3d4, (%IndexWith.impl_witness.567) [concrete]
// CHECK:STDOUT:   %IndexWith.WithSelf.At.type.f9f: type = fn_type @IndexWith.WithSelf.At, @IndexWith.WithSelf(Core.IntLiteral, %IndexWith.facet.3c4) [concrete]
// CHECK:STDOUT:   %.f6c: type = fn_type_with_self_type %IndexWith.WithSelf.At.type.f9f, %IndexWith.facet.3c4 [concrete]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.bound.628c52.1: <bound method> = bound_method %String.val, %str.as.IndexWith.impl.At.0889f8.2 [concrete]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.specific_fn.787c8f.1: <specific function> = specific_function %str.as.IndexWith.impl.At.0889f8.2, @str.as.IndexWith.impl.At.1(%ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.4f6ce0.1: <bound method> = bound_method %String.val, %str.as.IndexWith.impl.At.specific_fn.787c8f.1 [concrete]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.bound.628c52.2: <bound method> = bound_method %String.val, %str.as.IndexWith.impl.At.0889f8.1 [concrete]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.specific_fn.787c8f.2: <specific function> = specific_function %str.as.IndexWith.impl.At.0889f8.1, @str.as.IndexWith.impl.At.2(%ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.4f6ce0.2: <bound method> = bound_method %String.val, %str.as.IndexWith.impl.At.specific_fn.787c8f.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_84: %char = int_value 84 [concrete]
// CHECK:STDOUT:   %d.patt: %pattern_type.2ff = value_binding_pattern d [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.740: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.bd2: %i64 = int_value 3 [concrete]
// CHECK:STDOUT:   %int_116: %char = int_value 116 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.c1f = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.169: @str.as.IndexWith.impl.%str.as.IndexWith.impl.At.type.2 (%str.as.IndexWith.impl.At.type.62ebd3.1) = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [symbolic = @str.as.IndexWith.impl.%str.as.IndexWith.impl.At.2 (constants.%str.as.IndexWith.impl.At.887ac3.1)]
// CHECK:STDOUT:   %IndexWith.impl_witness_table = impl_witness_table (%Core.import_ref.c1f, %Core.import_ref.169), @str.as.IndexWith.impl [concrete]
// CHECK:STDOUT:   %Core.At.6f4: @str.as.IndexWith.impl.%str.as.IndexWith.impl.At.type.1 (%str.as.IndexWith.impl.At.type.62ebd3.2) = import_ref Core//prelude/types/string, At, loaded [symbolic = @str.as.IndexWith.impl.%str.as.IndexWith.impl.At.1 (constants.%str.as.IndexWith.impl.At.887ac3.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @TestStringIndexing() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %str.loc5: %ptr.b46 = string_literal "Test" [concrete = constants.%str.4f8]
// CHECK:STDOUT:   %int_4.loc5: %i64 = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:   %String.val.loc5: %str.3d4 = struct_value (%str.loc5, %int_4.loc5) [concrete = constants.%String.val]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem1.loc5: %.f6c = impl_witness_access constants.%IndexWith.impl_witness.567, element1 [concrete = constants.%str.as.IndexWith.impl.At.0889f8.2]
// CHECK:STDOUT:   %bound_method.loc5_32.1: <bound method> = bound_method %String.val.loc5, %impl.elem1.loc5 [concrete = constants.%str.as.IndexWith.impl.At.bound.628c52.1]
// CHECK:STDOUT:   %ImplicitAs.facet.loc5_32.1: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (constants.%ImplicitAs.impl_witness.227) [concrete = constants.%ImplicitAs.facet]
// CHECK:STDOUT:   %.loc5_32.1: %ImplicitAs.type.221 = converted Core.IntLiteral, %ImplicitAs.facet.loc5_32.1 [concrete = constants.%ImplicitAs.facet]
// CHECK:STDOUT:   %ImplicitAs.facet.loc5_32.2: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (constants.%ImplicitAs.impl_witness.227) [concrete = constants.%ImplicitAs.facet]
// CHECK:STDOUT:   %.loc5_32.2: %ImplicitAs.type.221 = converted Core.IntLiteral, %ImplicitAs.facet.loc5_32.2 [concrete = constants.%ImplicitAs.facet]
// CHECK:STDOUT:   %specific_fn.loc5_32: <specific function> = specific_function %impl.elem1.loc5, @str.as.IndexWith.impl.At.1(constants.%ImplicitAs.facet) [concrete = constants.%str.as.IndexWith.impl.At.specific_fn.787c8f.1]
// CHECK:STDOUT:   %bound_method.loc5_32.2: <bound method> = bound_method %String.val.loc5, %specific_fn.loc5_32 [concrete = constants.%bound_method.4f6ce0.1]
// CHECK:STDOUT:   %.loc5_32.3: %str.as.IndexWith.impl.At.type.e2e5ac.1 = specific_constant imports.%Core.At.6f4, @str.as.IndexWith.impl(constants.%ImplicitAs.facet) [concrete = constants.%str.as.IndexWith.impl.At.0889f8.1]
// CHECK:STDOUT:   %At.ref.loc5: %str.as.IndexWith.impl.At.type.e2e5ac.1 = name_ref At, %.loc5_32.3 [concrete = constants.%str.as.IndexWith.impl.At.0889f8.1]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.bound.loc5: <bound method> = bound_method %String.val.loc5, %At.ref.loc5 [concrete = constants.%str.as.IndexWith.impl.At.bound.628c52.2]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.specific_fn.loc5: <specific function> = specific_function %At.ref.loc5, @str.as.IndexWith.impl.At.2(constants.%ImplicitAs.facet) [concrete = constants.%str.as.IndexWith.impl.At.specific_fn.787c8f.2]
// CHECK:STDOUT:   %bound_method.loc5_32.3: <bound method> = bound_method %String.val.loc5, %str.as.IndexWith.impl.At.specific_fn.loc5 [concrete = constants.%bound_method.4f6ce0.2]
// CHECK:STDOUT:   %impl.elem0.loc5: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc5_31.1: <bound method> = bound_method %int_0, %impl.elem0.loc5 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:   %specific_fn.loc5_31: <specific function> = specific_function %impl.elem0.loc5, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_31.2: <bound method> = bound_method %int_0, %specific_fn.loc5_31 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5: init %i64 = call %bound_method.loc5_31.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc5_31.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %.loc5_31.2: %i64 = converted %int_0, %.loc5_31.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.loc5: init %char = call %bound_method.loc5_32.3(%String.val.loc5, %.loc5_31.2) [concrete = constants.%int_84]
// CHECK:STDOUT:   %.loc5_32.4: %char = value_of_initializer %str.as.IndexWith.impl.At.call.loc5 [concrete = constants.%int_84]
// CHECK:STDOUT:   %.loc5_32.5: %char = converted %str.as.IndexWith.impl.At.call.loc5, %.loc5_32.4 [concrete = constants.%int_84]
// CHECK:STDOUT:   %char.loc5: type = type_literal constants.%char [concrete = constants.%char]
// CHECK:STDOUT:   %c: %char = wrapper_binding c, %.loc5_32.5
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %c.patt: %pattern_type.2ff = value_binding_pattern c [concrete = constants.%c.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %str.loc6: %ptr.b46 = string_literal "Test" [concrete = constants.%str.4f8]
// CHECK:STDOUT:   %int_4.loc6: %i64 = int_value 4 [concrete = constants.%int_4]
// CHECK:STDOUT:   %String.val.loc6: %str.3d4 = struct_value (%str.loc6, %int_4.loc6) [concrete = constants.%String.val]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem1.loc6: %.f6c = impl_witness_access constants.%IndexWith.impl_witness.567, element1 [concrete = constants.%str.as.IndexWith.impl.At.0889f8.2]
// CHECK:STDOUT:   %bound_method.loc6_32.1: <bound method> = bound_method %String.val.loc6, %impl.elem1.loc6 [concrete = constants.%str.as.IndexWith.impl.At.bound.628c52.1]
// CHECK:STDOUT:   %ImplicitAs.facet.loc6_32.1: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (constants.%ImplicitAs.impl_witness.227) [concrete = constants.%ImplicitAs.facet]
// CHECK:STDOUT:   %.loc6_32.1: %ImplicitAs.type.221 = converted Core.IntLiteral, %ImplicitAs.facet.loc6_32.1 [concrete = constants.%ImplicitAs.facet]
// CHECK:STDOUT:   %ImplicitAs.facet.loc6_32.2: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (constants.%ImplicitAs.impl_witness.227) [concrete = constants.%ImplicitAs.facet]
// CHECK:STDOUT:   %.loc6_32.2: %ImplicitAs.type.221 = converted Core.IntLiteral, %ImplicitAs.facet.loc6_32.2 [concrete = constants.%ImplicitAs.facet]
// CHECK:STDOUT:   %specific_fn.loc6_32: <specific function> = specific_function %impl.elem1.loc6, @str.as.IndexWith.impl.At.1(constants.%ImplicitAs.facet) [concrete = constants.%str.as.IndexWith.impl.At.specific_fn.787c8f.1]
// CHECK:STDOUT:   %bound_method.loc6_32.2: <bound method> = bound_method %String.val.loc6, %specific_fn.loc6_32 [concrete = constants.%bound_method.4f6ce0.1]
// CHECK:STDOUT:   %.loc6_32.3: %str.as.IndexWith.impl.At.type.e2e5ac.1 = specific_constant imports.%Core.At.6f4, @str.as.IndexWith.impl(constants.%ImplicitAs.facet) [concrete = constants.%str.as.IndexWith.impl.At.0889f8.1]
// CHECK:STDOUT:   %At.ref.loc6: %str.as.IndexWith.impl.At.type.e2e5ac.1 = name_ref At, %.loc6_32.3 [concrete = constants.%str.as.IndexWith.impl.At.0889f8.1]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.bound.loc6: <bound method> = bound_method %String.val.loc6, %At.ref.loc6 [concrete = constants.%str.as.IndexWith.impl.At.bound.628c52.2]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.specific_fn.loc6: <specific function> = specific_function %At.ref.loc6, @str.as.IndexWith.impl.At.2(constants.%ImplicitAs.facet) [concrete = constants.%str.as.IndexWith.impl.At.specific_fn.787c8f.2]
// CHECK:STDOUT:   %bound_method.loc6_32.3: <bound method> = bound_method %String.val.loc6, %str.as.IndexWith.impl.At.specific_fn.loc6 [concrete = constants.%bound_method.4f6ce0.2]
// CHECK:STDOUT:   %impl.elem0.loc6: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc6_31.1: <bound method> = bound_method %int_3, %impl.elem0.loc6 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c]
// CHECK:STDOUT:   %specific_fn.loc6_31: <specific function> = specific_function %impl.elem0.loc6, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_31.2: <bound method> = bound_method %int_3, %specific_fn.loc6_31 [concrete = constants.%bound_method.740]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6: init %i64 = call %bound_method.loc6_31.2(%int_3) [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc6_31.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc6 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc6_31.2: %i64 = converted %int_3, %.loc6_31.1 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %str.as.IndexWith.impl.At.call.loc6: init %char = call %bound_method.loc6_32.3(%String.val.loc6, %.loc6_31.2) [concrete = constants.%int_116]
// CHECK:STDOUT:   %.loc6_32.4: %char = value_of_initializer %str.as.IndexWith.impl.At.call.loc6 [concrete = constants.%int_116]
// CHECK:STDOUT:   %.loc6_32.5: %char = converted %str.as.IndexWith.impl.At.call.loc6, %.loc6_32.4 [concrete = constants.%int_116]
// CHECK:STDOUT:   %char.loc6: type = type_literal constants.%char [concrete = constants.%char]
// CHECK:STDOUT:   %d: %char = wrapper_binding d, %.loc6_32.5
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %d.patt: %pattern_type.2ff = value_binding_pattern d [concrete = constants.%d.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
