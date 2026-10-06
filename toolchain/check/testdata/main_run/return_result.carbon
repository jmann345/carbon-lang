// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/main_run/return_result.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/main_run/return_result.carbon

// The `Result` entry-point shapes of decision D10 (docs/design/
// error_handling.md, "Entry point"; fork/eh/plan.md §1.A.5):
// `IsValidEntryPointReturnType` accepts a `Core.Result(T, E)` specific whose
// success type is exactly `()` or `i32`, for any `E`, so `?` is usable in
// `Run` itself. The success type is matched by `TypeId` equality like the
// plain `-> i32` shape — `fail_adapter_success_type` pins that an adapter
// over `i32` is rejected in the `Result` position exactly as `-> Adapter`
// is rejected today. Lowering (lower/testdata/main_run/return_result.carbon)
// gives these functions the C ABI `i32 main()` and the exit-code epilogue.

// --- unit_ok.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Run() -> Core.Result((), i32) {
  return Core.Result((), i32).Ok(());
}
//@dump-sem-ir-end

// --- i32_ok.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Run() -> Core.Result(i32, i32) {
  return Core.Result(i32, i32).Ok(3);
}
//@dump-sem-ir-end

// --- with_question.carbon
library "[[@TEST_NAME]]";

fn Fails(n: i32) -> Core.Result((), i32) {
  return Core.Result((), i32).Err(n);
}

//@dump-sem-ir-begin
fn Run() -> Core.Result((), i32) {
  Fails(7)?;
  return Core.Result((), i32).Ok(());
}
//@dump-sem-ir-end

// --- fail_bad_success_type.carbon
library "[[@TEST_NAME]]";

// Only `()` and `i32` are D10 success types.
// CHECK:STDERR: fail_bad_success_type.carbon:[[@LINE+4]]:1: error: invalid return type for `Main.Run` function; expected `fn (...)`, `fn (...) -> i32`, `fn (...) -> Core.Result((), E)`, or `fn (...) -> Core.Result(i32, E)` [InvalidMainRunReturnType]
// CHECK:STDERR: fn Run() -> Core.Result(i64, i32) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Run() -> Core.Result(i64, i32) {
  return Core.Result(i64, i32).Ok(0);
}

// --- fail_non_result_class.carbon
library "[[@TEST_NAME]]";

class C {
  var x: i32;
}

// CHECK:STDERR: fail_non_result_class.carbon:[[@LINE+4]]:1: error: invalid return type for `Main.Run` function; expected `fn (...)`, `fn (...) -> i32`, `fn (...) -> Core.Result((), E)`, or `fn (...) -> Core.Result(i32, E)` [InvalidMainRunReturnType]
// CHECK:STDERR: fn Run() -> C {
// CHECK:STDERR: ^~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Run() -> C {
  return {.x = 0};
}

// --- fail_adapter_success_type.carbon
library "[[@TEST_NAME]]";

// An adapter over `i32` is an SF-6-admissible payload, so the specific
// itself is fine; the entry-point check still rejects it, as it rejects the
// plain `fn Run() -> Code` shape.
class Code {
  adapt i32;
}

// CHECK:STDERR: fail_adapter_success_type.carbon:[[@LINE+4]]:1: error: invalid return type for `Main.Run` function; expected `fn (...)`, `fn (...) -> i32`, `fn (...) -> Core.Result((), E)`, or `fn (...) -> Core.Result(i32, E)` [InvalidMainRunReturnType]
// CHECK:STDERR: fn Run() -> Core.Result(Code, i32) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn Run() -> Core.Result(Code, i32) {
  return Core.Result(Code, i32).Err(1);
}

// CHECK:STDOUT: --- unit_ok.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Result.610: type = class_type @Result, @Result(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %.0b9: Core.Form = init_form %Result.610 [concrete]
// CHECK:STDOUT:   %pattern_type.f2b: type = pattern_type %Result.610 [concrete]
// CHECK:STDOUT:   %return.param_patt.51d: %pattern_type.f2b = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.391: %pattern_type.f2b = return_slot_pattern %return.param_patt.51d, %Result.610 [concrete]
// CHECK:STDOUT:   %Run.type: type = fn_type @Run [concrete]
// CHECK:STDOUT:   %Run: %Run.type = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Ok.type.3fe: type = fn_type @Result.Ok, @Result(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Result.Ok.a6a: %Result.Ok.type.3fe = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.a6a, @Result.Ok(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Result: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f2b = out_param_pattern [concrete = constants.%return.param_patt.51d]
// CHECK:STDOUT:     %return.patt: %pattern_type.f2b = return_slot_pattern %return.param_patt, %Result.loc4 [concrete = constants.%return.patt.391]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc4: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc4: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %.loc4_26: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %i32.loc4: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_32.2: type = converted %.loc4_26, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:     %Result.loc4: type = class_type @Result, @Result(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.610]
// CHECK:STDOUT:     %.loc4_32.3: Core.Form = init_form %Result.loc4 [concrete = constants.%.0b9]
// CHECK:STDOUT:     %return.param: ref %Result.610 = out_param call_param0
// CHECK:STDOUT:     %return: ref %Result.610 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %Result.610 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc5: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc5: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %.loc5_23: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %i32.loc5: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %.loc5_29: type = converted %.loc5_23, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   %Result.loc5: type = class_type @Result, @Result(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.610]
// CHECK:STDOUT:   %.loc5_30: %Result.Ok.type.3fe = specific_constant imports.%Core.import_ref.597, @Result(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.Ok.a6a]
// CHECK:STDOUT:   %Ok.ref: %Result.Ok.type.3fe = name_ref Ok, %.loc5_30 [concrete = constants.%Result.Ok.a6a]
// CHECK:STDOUT:   %.loc5_35.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc4_32.1: ref %Result.610 = splice_block %return.param {}
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc5_35.2: %empty_tuple.type = converted %.loc5_35.1, %empty_tuple [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Result.Ok.call: init %Result.610 to %.loc4_32.1 = call %Result.Ok.specific_fn(%.loc5_35.2)
// CHECK:STDOUT:   return %Result.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- i32_ok.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Result.250: type = class_type @Result, @Result(%i32, %i32) [concrete]
// CHECK:STDOUT:   %.4ba: Core.Form = init_form %Result.250 [concrete]
// CHECK:STDOUT:   %pattern_type.321: type = pattern_type %Result.250 [concrete]
// CHECK:STDOUT:   %return.param_patt.8f8: %pattern_type.321 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.d36: %pattern_type.321 = return_slot_pattern %return.param_patt.8f8, %Result.250 [concrete]
// CHECK:STDOUT:   %Run.type: type = fn_type @Run [concrete]
// CHECK:STDOUT:   %Run: %Run.type = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Ok.type.39c: type = fn_type @Result.Ok, @Result(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Result.Ok.e0a: %Result.Ok.type.39c = struct_value () [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.e0a, @Result.Ok(%i32, %i32) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Result = %Core.Result
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Result: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.321 = out_param_pattern [concrete = constants.%return.param_patt.8f8]
// CHECK:STDOUT:     %return.patt: %pattern_type.321 = return_slot_pattern %return.param_patt, %Result.loc4 [concrete = constants.%return.patt.d36]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc4: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc4: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %i32.loc4_25: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %i32.loc4_30: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %Result.loc4: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:     %.loc4_33.2: Core.Form = init_form %Result.loc4 [concrete = constants.%.4ba]
// CHECK:STDOUT:     %return.param: ref %Result.250 = out_param call_param0
// CHECK:STDOUT:     %return: ref %Result.250 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %Result.250 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Core.ref.loc5: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc5: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %i32.loc5_22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc5_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Result.loc5: type = class_type @Result, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.250]
// CHECK:STDOUT:   %.loc5_31: %Result.Ok.type.39c = specific_constant imports.%Core.import_ref.597, @Result(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %Ok.ref: %Result.Ok.type.39c = name_ref Ok, %.loc5_31 [concrete = constants.%Result.Ok.e0a]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%i32, constants.%i32) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc4_33.1: ref %Result.250 = splice_block %return.param {}
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc5_35.1: <bound method> = bound_method %int_3, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_35.2: <bound method> = bound_method %int_3, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc5_35.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc5_35.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc5_35.2: %i32 = converted %int_3, %.loc5_35.1 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %Result.Ok.call: init %Result.250 to %.loc4_33.1 = call %Result.Ok.specific_fn(%.loc5_35.2)
// CHECK:STDOUT:   return %Result.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- with_question.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Result.type: type = generic_class_type @Result [concrete]
// CHECK:STDOUT:   %Result.generic: %Result.type = struct_value () [concrete]
// CHECK:STDOUT:   %E: type = symbolic_binding E, 1 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Result.Ok.type.898: type = fn_type @Result.Ok, @Result(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.Ok.58a: %Result.Ok.type.898 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %Result.610: type = class_type @Result, @Result(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %.0b9: Core.Form = init_form %Result.610 [concrete]
// CHECK:STDOUT:   %pattern_type.f2b: type = pattern_type %Result.610 [concrete]
// CHECK:STDOUT:   %return.param_patt.51d: %pattern_type.f2b = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.391: %pattern_type.f2b = return_slot_pattern %return.param_patt.51d, %Result.610 [concrete]
// CHECK:STDOUT:   %Fails.type: type = fn_type @Fails [concrete]
// CHECK:STDOUT:   %Fails: %Fails.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cb1: type = pattern_type %empty_tuple.type [concrete]
// CHECK:STDOUT:   %tuple.type.9fb: type = tuple_type (%empty_tuple.type) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e98: type = custom_layout_type {size=4, align=4, .Ok@0: %tuple.type.9fb, .Err@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.11d: type = struct_type {.discriminant: %u1, .payload: %.e98} [concrete]
// CHECK:STDOUT:   %Result.Ok.type.3fe: type = fn_type @Result.Ok, @Result(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Result.Ok.a6a: %Result.Ok.type.3fe = struct_value () [concrete]
// CHECK:STDOUT:   %Run.type: type = fn_type @Run [concrete]
// CHECK:STDOUT:   %Run: %Run.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.7ff: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT:   %Try.type: type = facet_type <@Try> [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.834: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.9cc: %Result.as.Try.impl.FromBreak.type.834 = struct_value () [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.d6a: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%T.67d, %E) [symbolic]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.513: %Result.as.Try.impl.Branch.type.d6a = struct_value () [symbolic]
// CHECK:STDOUT:   %Try.impl_witness.96d: <witness> = impl_witness imports.%Try.impl_witness_table, @Result.as.Try.impl(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.type.180: type = fn_type @Result.as.Try.impl.Branch, @Result.as.Try.impl(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.7da: %Result.as.Try.impl.Branch.type.180 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.type.b3a: type = fn_type @Result.as.Try.impl.FromBreak, @Result.as.Try.impl(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.8ac: %Result.as.Try.impl.FromBreak.type.b3a = struct_value () [concrete]
// CHECK:STDOUT:   %Try.facet.f81: %Try.type = facet_value %Result.610, (%Try.impl_witness.96d) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.Branch.type.d04: type = fn_type @Try.WithSelf.Branch, @Try.WithSelf(%Try.facet.f81) [concrete]
// CHECK:STDOUT:   %Try.WithSelf.FromBreak.type.5a7: type = fn_type @Try.WithSelf.FromBreak, @Try.WithSelf(%Try.facet.f81) [concrete]
// CHECK:STDOUT:   %.0db: type = fn_type_with_self_type %Try.WithSelf.Branch.type.d04, %Try.facet.f81 [concrete]
// CHECK:STDOUT:   %ControlFlow.19f: type = class_type @ControlFlow, @ControlFlow(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.108: type = pattern_type %ControlFlow.19f [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.specific_fn.a5c: <specific function> = specific_function %Result.as.Try.impl.Branch.7da, @Result.as.Try.impl.Branch(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %.e4c: type = custom_layout_type {size=4, align=4, .Continue@0: %tuple.type.9fb, .Break@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.d20: type = struct_type {.discriminant: %u1, .payload: %.e4c} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %pattern_type.322: type = pattern_type %u1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %.a04: type = fn_type_with_self_type %Try.WithSelf.FromBreak.type.5a7, %Try.facet.f81 [concrete]
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.specific_fn: <specific function> = specific_function %Result.as.Try.impl.FromBreak.8ac, @Result.as.Try.impl.FromBreak(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %self.param_patt.7c1: %pattern_type.322 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.945: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt.7c1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_11.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc9_11.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9_11.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.65a: %pattern_type.cb1 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.df1: %pattern_type.cb1 = wrapper_binding_pattern self, %self.param_patt.65a [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_11.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc9_11.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9_11.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.559: type = pattern_type %tuple.type.9fb [concrete]
// CHECK:STDOUT:   %self.param_patt.383: %pattern_type.559 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.363: %pattern_type.559 = wrapper_binding_pattern self, %self.param_patt.383 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_11.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc9_11.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_11.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc9_11.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9_11.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_11.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc9_11.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e34: type = pattern_type %.e4c [concrete]
// CHECK:STDOUT:   %self.param_patt.d79: %pattern_type.e34 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e37: %pattern_type.e34 = wrapper_binding_pattern self, %self.param_patt.d79 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_11.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc9_11.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.6: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9_11.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.6: %Destroy.WithSelf.SelfDestruct.type.fbceb5.6 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.a36: type = pattern_type %struct_type.discriminant.payload.d20 [concrete]
// CHECK:STDOUT:   %self.param_patt.1aa: %pattern_type.a36 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.c7f: %pattern_type.a36 = wrapper_binding_pattern self, %self.param_patt.1aa [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_11.7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.7: type = fn_type @Destroy.WithSelf.Op.loc9_11.7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.7: %Destroy.WithSelf.Op.type.ef016f.7 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.270: %pattern_type.108 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.cbf: %pattern_type.108 = wrapper_binding_pattern self, %self.param_patt.270 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_11.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.8: type = fn_type @Destroy.WithSelf.Op.loc9_11.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.8: %Destroy.WithSelf.Op.type.ef016f.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.8: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9_11.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.8: %Destroy.WithSelf.SelfDestruct.type.fbceb5.8 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.d16: type = pattern_type %.e98 [concrete]
// CHECK:STDOUT:   %self.param_patt.736: %pattern_type.d16 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.ba3: %pattern_type.d16 = wrapper_binding_pattern self, %self.param_patt.736 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_10.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.9: type = fn_type @Destroy.WithSelf.Op.loc9_10.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.9: %Destroy.WithSelf.Op.type.ef016f.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.9: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9_10.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.9: %Destroy.WithSelf.SelfDestruct.type.fbceb5.9 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e76: type = pattern_type %struct_type.discriminant.payload.11d [concrete]
// CHECK:STDOUT:   %self.param_patt.dd5: %pattern_type.e76 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.28b: %pattern_type.e76 = wrapper_binding_pattern self, %self.param_patt.dd5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_10.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.10: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.10: type = fn_type @Destroy.WithSelf.Op.loc9_10.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.10: %Destroy.WithSelf.Op.type.ef016f.10 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.9d4: %pattern_type.f2b = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.c75: %pattern_type.f2b = wrapper_binding_pattern self, %self.param_patt.9d4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9_10.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.11: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.11: type = fn_type @Destroy.WithSelf.Op.loc9_10.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.11: %Destroy.WithSelf.Op.type.ef016f.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.11: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9_10.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.11: %Destroy.WithSelf.SelfDestruct.type.fbceb5.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Result.Ok.a6a, @Result.Ok(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Result = %Core.Result
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Try = %Core.Try
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Result: %Result.type = import_ref Core//prelude/types/result, Result, loaded [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %Core.import_ref.597: @Result.%Result.Ok.type (%Result.Ok.type.898) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.%Result.Ok (constants.%Result.Ok.58a)]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.Try: type = import_ref Core//prelude/try, Try, loaded [concrete = constants.%Try.type]
// CHECK:STDOUT:   %Core.import_ref.0b3 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.6e9 = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9f4: @Result.as.Try.impl.%Result.as.Try.impl.Branch.type (%Result.as.Try.impl.Branch.type.d6a) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.Branch (constants.%Result.as.Try.impl.Branch.513)]
// CHECK:STDOUT:   %Core.import_ref.6a4: @Result.as.Try.impl.%Result.as.Try.impl.FromBreak.type (%Result.as.Try.impl.FromBreak.type.834) = import_ref Core//prelude/types/result, loc{{\d+_\d+}}, loaded [symbolic = @Result.as.Try.impl.%Result.as.Try.impl.FromBreak (constants.%Result.as.Try.impl.FromBreak.9cc)]
// CHECK:STDOUT:   %Try.impl_witness_table = impl_witness_table (%Core.import_ref.0b3, %Core.import_ref.6e9, %Core.import_ref.9f4, %Core.import_ref.6a4), @Result.as.Try.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_11.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc9_11.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_11.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cb1 = ref_param_pattern [concrete = constants.%self.param_patt.65a]
// CHECK:STDOUT:     %self.patt: %pattern_type.cb1 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.df1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %empty_tuple.type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %empty_tuple.type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc9_11.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.cb1 = ref_param_pattern [concrete = constants.%self.param_patt.65a]
// CHECK:STDOUT:     %self.patt: %pattern_type.cb1 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.df1]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %empty_tuple.type = ref_param call_param0
// CHECK:STDOUT:     %self: ref %empty_tuple.type = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_11.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.559 = ref_param_pattern [concrete = constants.%self.param_patt.383]
// CHECK:STDOUT:     %self.patt: %pattern_type.559 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.363]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.9fb = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.9fb = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc9_11.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.559 = ref_param_pattern [concrete = constants.%self.param_patt.383]
// CHECK:STDOUT:     %self.patt: %pattern_type.559 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.363]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.9fb = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.9fb = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_11.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc9_11.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_11.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc9_11.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_11.6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e34 = ref_param_pattern [concrete = constants.%self.param_patt.d79]
// CHECK:STDOUT:     %self.patt: %pattern_type.e34 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e37]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e4c = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e4c = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc9_11.6 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e34 = ref_param_pattern [concrete = constants.%self.param_patt.d79]
// CHECK:STDOUT:     %self.patt: %pattern_type.e34 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e37]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e4c = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e4c = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_11.7 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a36 = ref_param_pattern [concrete = constants.%self.param_patt.1aa]
// CHECK:STDOUT:     %self.patt: %pattern_type.a36 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c7f]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.d20 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.d20 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.7: %Destroy.WithSelf.Op.type.ef016f.7 = fn_decl @Destroy.WithSelf.Op.loc9_11.7 [concrete = constants.%Destroy.WithSelf.Op.403171.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.a36 = ref_param_pattern [concrete = constants.%self.param_patt.1aa]
// CHECK:STDOUT:     %self.patt: %pattern_type.a36 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c7f]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.d20 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.d20 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_11.8 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.108 = ref_param_pattern [concrete = constants.%self.param_patt.270]
// CHECK:STDOUT:     %self.patt: %pattern_type.108 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.cbf]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ControlFlow.19f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ControlFlow.19f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.8: %Destroy.WithSelf.Op.type.ef016f.8 = fn_decl @Destroy.WithSelf.Op.loc9_11.8 [concrete = constants.%Destroy.WithSelf.Op.403171.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.108 = ref_param_pattern [concrete = constants.%self.param_patt.270]
// CHECK:STDOUT:     %self.patt: %pattern_type.108 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.cbf]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ControlFlow.19f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ControlFlow.19f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_10.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.d16 = ref_param_pattern [concrete = constants.%self.param_patt.736]
// CHECK:STDOUT:     %self.patt: %pattern_type.d16 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.ba3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e98 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e98 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.9: %Destroy.WithSelf.Op.type.ef016f.9 = fn_decl @Destroy.WithSelf.Op.loc9_10.1 [concrete = constants.%Destroy.WithSelf.Op.403171.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.d16 = ref_param_pattern [concrete = constants.%self.param_patt.736]
// CHECK:STDOUT:     %self.patt: %pattern_type.d16 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.ba3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e98 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e98 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.10: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_10.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.10] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e76 = ref_param_pattern [concrete = constants.%self.param_patt.dd5]
// CHECK:STDOUT:     %self.patt: %pattern_type.e76 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.28b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.11d = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.11d = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.10: %Destroy.WithSelf.Op.type.ef016f.10 = fn_decl @Destroy.WithSelf.Op.loc9_10.2 [concrete = constants.%Destroy.WithSelf.Op.403171.10] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e76 = ref_param_pattern [concrete = constants.%self.param_patt.dd5]
// CHECK:STDOUT:     %self.patt: %pattern_type.e76 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.28b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.11d = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.11d = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.11: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9_10.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.11] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f2b = ref_param_pattern [concrete = constants.%self.param_patt.9d4]
// CHECK:STDOUT:     %self.patt: %pattern_type.f2b = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c75]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Result.610 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Result.610 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.11: %Destroy.WithSelf.Op.type.ef016f.11 = fn_decl @Destroy.WithSelf.Op.loc9_10.3 [concrete = constants.%Destroy.WithSelf.Op.403171.11] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f2b = ref_param_pattern [concrete = constants.%self.param_patt.9d4]
// CHECK:STDOUT:     %self.patt: %pattern_type.f2b = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.c75]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Result.610 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Result.610 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Run.decl: %Run.type = fn_decl @Run [concrete = constants.%Run] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f2b = out_param_pattern [concrete = constants.%return.param_patt.51d]
// CHECK:STDOUT:     %return.patt: %pattern_type.f2b = return_slot_pattern %return.param_patt, %Result.loc8 [concrete = constants.%return.patt.391]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc8: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Result.ref.loc8: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:     %.loc8_26: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %i32.loc8: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_32.3: type = converted %.loc8_26, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:     %Result.loc8: type = class_type @Result, @Result(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.610]
// CHECK:STDOUT:     %.loc8_32.4: Core.Form = init_form %Result.loc8 [concrete = constants.%.0b9]
// CHECK:STDOUT:     %return.param: ref %Result.610 = out_param call_param0
// CHECK:STDOUT:     %return: ref %Result.610 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() -> out %return.param: %Result.610 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Fails.ref: %Fails.type = name_ref Fails, file.%Fails.decl [concrete = constants.%Fails]
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %.loc9_10.1: ref %Result.610 = temporary_storage
// CHECK:STDOUT:   %impl.elem0.loc9_9: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_9.1: <bound method> = bound_method %int_7, %impl.elem0.loc9_9 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.66b]
// CHECK:STDOUT:   %specific_fn.loc9_9: <specific function> = specific_function %impl.elem0.loc9_9, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc9_9.2: <bound method> = bound_method %int_7, %specific_fn.loc9_9 [concrete = constants.%bound_method.7ff]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_9: init %i32 = call %bound_method.loc9_9.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc9_9.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_9 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc9_9.2: %i32 = converted %int_7, %.loc9_9.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %Fails.call: init %Result.610 to %.loc9_10.1 = call %Fails.ref(%.loc9_9.2)
// CHECK:STDOUT:   %.loc9_10.2: ref %Result.610 = temporary %.loc9_10.1, %Fails.call
// CHECK:STDOUT:   %impl.elem2: %.0db = impl_witness_access constants.%Try.impl_witness.96d, element2 [concrete = constants.%Result.as.Try.impl.Branch.7da]
// CHECK:STDOUT:   %bound_method.loc9_11.1: <bound method> = bound_method %.loc9_10.2, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc9_11.1: <specific function> = specific_function %impl.elem2, @Result.as.Try.impl.Branch(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.as.Try.impl.Branch.specific_fn.a5c]
// CHECK:STDOUT:   %bound_method.loc9_11.2: <bound method> = bound_method %.loc9_10.2, %specific_fn.loc9_11.1
// CHECK:STDOUT:   %.loc9_11.1: ref %ControlFlow.19f = temporary_storage
// CHECK:STDOUT:   %.loc9_10.3: %Result.610 = acquire_value %.loc9_10.2
// CHECK:STDOUT:   %Result.as.Try.impl.Branch.call: init %ControlFlow.19f to %.loc9_11.1 = call %bound_method.loc9_11.2(%.loc9_10.3)
// CHECK:STDOUT:   %.loc9_11.2: ref %ControlFlow.19f = temporary %.loc9_11.1, %Result.as.Try.impl.Branch.call
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc9_11.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc9_11.3: <bound method> = bound_method %int_1, %impl.elem0.loc9_11.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc9_11.2: <specific function> = specific_function %impl.elem0.loc9_11.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc9_11.4: <bound method> = bound_method %int_1, %specific_fn.loc9_11.2 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_11: init %u1 = call %bound_method.loc9_11.4(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc9_11.3: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_11 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc9_11.4: %u1 = converted %int_1, %.loc9_11.3 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc9_11.5: ref %u1 = class_element_access %.loc9_11.2, element0
// CHECK:STDOUT:   %impl.elem0.loc9_11.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc9_11.5: <bound method> = bound_method %.loc9_11.4, %impl.elem0.loc9_11.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc9_11.3: <specific function> = specific_function %impl.elem0.loc9_11.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc9_11.6: <bound method> = bound_method %.loc9_11.4, %specific_fn.loc9_11.3 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc9_11.6: %u1 = acquire_value %.loc9_11.5
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc9_11.6(%.loc9_11.4, %.loc9_11.6)
// CHECK:STDOUT:   %.loc9_11.7: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc9_11.8: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc9_11.7
// CHECK:STDOUT:   if %.loc9_11.8 br !.loc9_11.1 else br !.loc9_11.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_11.1:
// CHECK:STDOUT:   %.loc9_11.9: ref %.e4c = class_element_access %.loc9_11.2, element1
// CHECK:STDOUT:   %.loc9_11.10: ref %tuple.type.a8a = class_element_access %.loc9_11.9, element1
// CHECK:STDOUT:   %tuple.elem0.loc9_11.1: ref %i32 = tuple_access %.loc9_11.10, element0
// CHECK:STDOUT:   %.loc9_11.11: %i32 = acquire_value %tuple.elem0.loc9_11.1
// CHECK:STDOUT:   %Try.facet: %Try.type = facet_value constants.%Result.610, (constants.%Try.impl_witness.96d) [concrete = constants.%Try.facet.f81]
// CHECK:STDOUT:   %.loc9_11.12: %Try.type = converted constants.%Result.610, %Try.facet [concrete = constants.%Try.facet.f81]
// CHECK:STDOUT:   %impl.elem3: %.a04 = impl_witness_access constants.%Try.impl_witness.96d, element3 [concrete = constants.%Result.as.Try.impl.FromBreak.8ac]
// CHECK:STDOUT:   %specific_fn.loc9_11.4: <specific function> = specific_function %impl.elem3, @Result.as.Try.impl.FromBreak(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.as.Try.impl.FromBreak.specific_fn]
// CHECK:STDOUT:   %.loc8_32.1: ref %Result.610 = splice_block %return.param {}
// CHECK:STDOUT:   %Result.as.Try.impl.FromBreak.call: init %Result.610 to %.loc8_32.1 = call %specific_fn.loc9_11.4(%.loc9_11.11)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_11.1: <bound method> = bound_method %.loc9_11.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.8
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_11.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_11.1(%.loc9_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_10.1: <bound method> = bound_method %.loc9_10.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.11
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_10.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_10.1(%.loc9_10.2)
// CHECK:STDOUT:   return %Result.as.Try.impl.FromBreak.call to %return.param
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_11.2:
// CHECK:STDOUT:   %.loc9_11.13: ref %.e4c = class_element_access %.loc9_11.2, element1
// CHECK:STDOUT:   %.loc9_11.14: ref %tuple.type.9fb = class_element_access %.loc9_11.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc9_11.2: ref %empty_tuple.type = tuple_access %.loc9_11.14, element0
// CHECK:STDOUT:   %empty_tuple.loc9: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc9_11.15: %empty_tuple.type = converted %tuple.elem0.loc9_11.2, %empty_tuple.loc9 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_11.2: <bound method> = bound_method %.loc9_11.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.8
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_11.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_11.2(%.loc9_11.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_10.2: <bound method> = bound_method %.loc9_10.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.11
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_10.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_10.2(%.loc9_10.2)
// CHECK:STDOUT:   %Core.ref.loc10: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Result.ref.loc10: %Result.type = name_ref Result, imports.%Core.Result [concrete = constants.%Result.generic]
// CHECK:STDOUT:   %.loc10_23: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %i32.loc10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %.loc10_29: type = converted %.loc10_23, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   %Result.loc10: type = class_type @Result, @Result(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.610]
// CHECK:STDOUT:   %.loc10_30: %Result.Ok.type.3fe = specific_constant imports.%Core.import_ref.597, @Result(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.Ok.a6a]
// CHECK:STDOUT:   %Ok.ref: %Result.Ok.type.3fe = name_ref Ok, %.loc10_30 [concrete = constants.%Result.Ok.a6a]
// CHECK:STDOUT:   %.loc10_35.1: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Result.Ok.specific_fn: <specific function> = specific_function %Ok.ref, @Result.Ok(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%Result.Ok.specific_fn]
// CHECK:STDOUT:   %.loc8_32.2: ref %Result.610 = splice_block %return.param {}
// CHECK:STDOUT:   %empty_tuple.loc10: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc10_35.2: %empty_tuple.type = converted %.loc10_35.1, %empty_tuple.loc10 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %Result.Ok.call: init %Result.610 to %.loc8_32.2 = call %Result.Ok.specific_fn(%.loc10_35.2)
// CHECK:STDOUT:   return %Result.Ok.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_11.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_11.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_11.1(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_11.2(%self.param: ref %empty_tuple.type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_11.2(%self.param: ref %empty_tuple.type) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_11.2(%self.param: ref %empty_tuple.type) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_11.3(%self.param: ref %tuple.type.9fb) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %empty_tuple.type = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_11.3(%self.param: ref %tuple.type.9fb) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_11.3(%self.param: ref %tuple.type.9fb) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_11.4(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_11.4(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_11.4(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_11.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_11.5(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_11.5(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_11.6(%self.param: ref %.e4c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_11.6(%self.param: ref %.e4c) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_11.6(%self.param: ref %.e4c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_11.7(%self.param: ref %struct_type.discriminant.payload.d20) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc9_11.1: ref %.e4c = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_11.1: <bound method> = bound_method %.loc9_11.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_11.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_11.1(%.loc9_11.1)
// CHECK:STDOUT:   %.loc9_11.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_11.2: <bound method> = bound_method %.loc9_11.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_11.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_11.2(%.loc9_11.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_11.7(%self.param: ref %struct_type.discriminant.payload.d20) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_11.7(%self.param: ref %struct_type.discriminant.payload.d20) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.7(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.7(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_11.8(%self.param: ref %ControlFlow.19f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_11.8(%self.param: ref %ControlFlow.19f) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_11.8(%self.param: ref %ControlFlow.19f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.8(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.8(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_10.1(%self.param: ref %.e98) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_10.1(%self.param: ref %.e98) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_10.1(%self.param: ref %.e98) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.9(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.9(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_10.2(%self.param: ref %struct_type.discriminant.payload.11d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc9_10.1: ref %.e98 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_10.1: <bound method> = bound_method %.loc9_10.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_10.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_10.1(%.loc9_10.1)
// CHECK:STDOUT:   %.loc9_10.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_10.2: <bound method> = bound_method %.loc9_10.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_10.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_10.2(%.loc9_10.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_10.2(%self.param: ref %struct_type.discriminant.payload.11d) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_10.2(%self.param: ref %struct_type.discriminant.payload.11d) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.10(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.10(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9_10.3(%self.param: ref %Result.610) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_10.3(%self.param: ref %Result.610) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_10.3(%self.param: ref %Result.610) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.11(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.11(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
