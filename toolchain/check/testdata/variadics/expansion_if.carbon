// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/expansion_if.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/expansion_if.carbon

// --- if_else.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn F(... each b: bool) {
  ... if (each b) {
    Consume(1);
  } else {
    Consume(0);
  }
}
//@dump-sem-ir-end

// --- else_if_return.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn First(... each b: bool) -> i64 {
  ... if (each b) {
    return 1;
  } else if (true) {
    Consume(2);
  }
  return 0;
}
//@dump-sem-ir-end

// --- generic.carbon
library "[[@TEST_NAME]]";

interface Less {
  fn Lt(self, other: Self) -> bool;
}

//@dump-sem-ir-begin
fn AnyLess[T: Less](first: T, ... each next: T) -> bool {
  ... if (each next.Lt(first)) {
    return true;
  }
  return false;
}
//@dump-sem-ir-end

// --- nested.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn F(... each b: bool) {
  ... if (each b) {
    if (each b) {
      Consume(1);
    }
  }
}
//@dump-sem-ir-end

// --- fail_question_body_position.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn InExpression(... each x: i64) {
  // CHECK:STDERR: fail_question_body_position.carbon:[[@LINE+7]]:15: error: `?` requires the enclosing function to have a declared return type that implements `Core.Try` [QuestionNoDeclaredReturnType]
  // CHECK:STDERR:   ... Consume(each x?);
  // CHECK:STDERR:               ^~~~~~~
  // CHECK:STDERR: fail_question_body_position.carbon:[[@LINE-4]]:1: note: there was no return type provided [ReturnTypeOmittedNote]
  // CHECK:STDERR: fn InExpression(... each x: i64) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ... Consume(each x?);
}

fn InCondition(... each b: bool) {
  // CHECK:STDERR: fail_question_body_position.carbon:[[@LINE+7]]:11: error: `?` requires the enclosing function to have a declared return type that implements `Core.Try` [QuestionNoDeclaredReturnType]
  // CHECK:STDERR:   ... if (each b?) {
  // CHECK:STDERR:           ^~~~~~~
  // CHECK:STDERR: fail_question_body_position.carbon:[[@LINE-4]]:1: note: there was no return type provided [ReturnTypeOmittedNote]
  // CHECK:STDERR: fn InCondition(... each b: bool) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  ... if (each b?) {
    Consume(1);
  }
}

// CHECK:STDOUT: --- if_else.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type: type = pack_type bool, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.601: type = pattern_type %pack_type [symbolic]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.601 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %b.patt: %pattern_type.601 = wrapper_binding_pattern b, %b.param_patt [symbolic]
// CHECK:STDOUT:   %.835: %pattern_type.601 = pack_expansion_pattern %b.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.7b2: <witness> = require_complete_type %pack_type [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.c5e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %arity.patt.loc6_6.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %b.param_patt.loc6_16.1: @F.%pattern_type (%pattern_type.601) = value_param_pattern [symbolic = %b.param_patt.loc6_16.2 (constants.%b.param_patt)]
// CHECK:STDOUT:     %b.patt.loc6_16.1: @F.%pattern_type (%pattern_type.601) = wrapper_binding_pattern b, %b.param_patt.loc6_16.1 [symbolic = %b.patt.loc6_16.2 (constants.%b.patt)]
// CHECK:STDOUT:     %.loc6_6.1: @F.%pattern_type (%pattern_type.601) = pack_expansion_pattern %b.patt.loc6_16.1, %arity.patt.loc6_6.1 [symbolic = %.loc6_6.2 (constants.%.835)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc6_6.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_6.1 (constants.%arity)]
// CHECK:STDOUT:     %b.param: @F.%pack_type (%pack_type) = value_param call_param0
// CHECK:STDOUT:     %.loc6_18: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: @F.%pack_type (%pack_type) = wrapper_binding b, %b.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%arity.loc6_6.2: Core.IntLiteral) {
// CHECK:STDOUT:   %arity.patt.loc6_6.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc6_6.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_6.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type bool, %arity.loc6_6.1 [symbolic = %pack_type (constants.%pack_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type [symbolic = %pattern_type (constants.%pattern_type.601)]
// CHECK:STDOUT:   %b.param_patt.loc6_16.2: @F.%pattern_type (%pattern_type.601) = value_param_pattern [symbolic = %b.param_patt.loc6_16.2 (constants.%b.param_patt)]
// CHECK:STDOUT:   %b.patt.loc6_16.2: @F.%pattern_type (%pattern_type.601) = wrapper_binding_pattern b, %b.param_patt.loc6_16.2 [symbolic = %b.patt.loc6_16.2 (constants.%b.patt)]
// CHECK:STDOUT:   %.loc6_6.2: @F.%pattern_type (%pattern_type.601) = pack_expansion_pattern %b.patt.loc6_16.2, %arity.patt.loc6_6.2 [symbolic = %.loc6_6.2 (constants.%.835)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type [symbolic = %require_complete (constants.%require_complete.7b2)]
// CHECK:STDOUT:   %.loc7_11.3: Core.IntLiteral = pack_index [symbolic = %.loc7_11.3 (constants.%.4ee)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%b.param: @F.%pack_type (%pack_type)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc6_6.2 {
// CHECK:STDOUT:       %b.ref: @F.%pack_type (%pack_type) = name_ref b, %b
// CHECK:STDOUT:       %.loc7_11.1: Core.IntLiteral = pack_index [symbolic = %.loc7_11.3 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc7_11.2: bool = pack_element %b.ref, %.loc7_11.1
// CHECK:STDOUT:       if %.loc7_11.2 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.then:
// CHECK:STDOUT:       %Consume.ref.loc8: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:       %impl.elem0.loc8: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:       %bound_method.loc8_13.1: <bound method> = bound_method %int_1, %impl.elem0.loc8 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:       %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:       %bound_method.loc8_13.2: <bound method> = bound_method %int_1, %specific_fn.loc8 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:       %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %i64 = call %bound_method.loc8_13.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:       %.loc8_13.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:       %.loc8_13.2: %i64 = converted %int_1, %.loc8_13.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:       %Consume.call.loc8: init %empty_tuple.type = call %Consume.ref.loc8(%.loc8_13.2)
// CHECK:STDOUT:       br !if.done
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.else:
// CHECK:STDOUT:       %Consume.ref.loc10: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:       %impl.elem0.loc10: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:       %bound_method.loc10_13.1: <bound method> = bound_method %int_0, %impl.elem0.loc10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:       %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:       %bound_method.loc10_13.2: <bound method> = bound_method %int_0, %specific_fn.loc10 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:       %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i64 = call %bound_method.loc10_13.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:       %.loc10_13.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:       %.loc10_13.2: %i64 = converted %int_0, %.loc10_13.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:       %Consume.call.loc10: init %empty_tuple.type = call %Consume.ref.loc10(%.loc10_13.2)
// CHECK:STDOUT:       br !if.done
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.done:
// CHECK:STDOUT:       pack_expansion_next
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%arity) {
// CHECK:STDOUT:   %arity.patt.loc6_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_6.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.601
// CHECK:STDOUT:   %b.param_patt.loc6_16.2 => constants.%b.param_patt
// CHECK:STDOUT:   %b.patt.loc6_16.2 => constants.%b.patt
// CHECK:STDOUT:   %.loc6_6.2 => constants.%.835
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- else_if_return.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type: type = pack_type bool, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.601: type = pattern_type %pack_type [symbolic]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.601 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %b.patt: %pattern_type.601 = wrapper_binding_pattern b, %b.param_patt [symbolic]
// CHECK:STDOUT:   %.835: %pattern_type.601 = pack_expansion_pattern %b.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %First.type: type = fn_type @First [concrete]
// CHECK:STDOUT:   %First: %First.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.7b2: <witness> = require_complete_type %pack_type [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.c5e: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5d4: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.c9c: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.405: %i64 = int_value 2 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %First.decl: %First.type = fn_decl @First [concrete = constants.%First] {
// CHECK:STDOUT:     %arity.patt.loc6_10.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_10.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %b.param_patt.loc6_20.1: @First.%pattern_type (%pattern_type.601) = value_param_pattern [symbolic = %b.param_patt.loc6_20.2 (constants.%b.param_patt)]
// CHECK:STDOUT:     %b.patt.loc6_20.1: @First.%pattern_type (%pattern_type.601) = wrapper_binding_pattern b, %b.param_patt.loc6_20.1 [symbolic = %b.patt.loc6_20.2 (constants.%b.patt)]
// CHECK:STDOUT:     %.loc6_10.1: @First.%pattern_type (%pattern_type.601) = pack_expansion_pattern %b.patt.loc6_20.1, %arity.patt.loc6_10.1 [symbolic = %.loc6_10.2 (constants.%.835)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc6_31: Core.Form = init_form %i64 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %arity.loc6_10.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_10.1 (constants.%arity)]
// CHECK:STDOUT:     %b.param: @First.%pack_type (%pack_type) = value_param call_param0
// CHECK:STDOUT:     %.loc6_22: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: @First.%pack_type (%pack_type) = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @First(%arity.loc6_10.2: Core.IntLiteral) {
// CHECK:STDOUT:   %arity.patt.loc6_10.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_10.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc6_10.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_10.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type bool, %arity.loc6_10.1 [symbolic = %pack_type (constants.%pack_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type [symbolic = %pattern_type (constants.%pattern_type.601)]
// CHECK:STDOUT:   %b.param_patt.loc6_20.2: @First.%pattern_type (%pattern_type.601) = value_param_pattern [symbolic = %b.param_patt.loc6_20.2 (constants.%b.param_patt)]
// CHECK:STDOUT:   %b.patt.loc6_20.2: @First.%pattern_type (%pattern_type.601) = wrapper_binding_pattern b, %b.param_patt.loc6_20.2 [symbolic = %b.patt.loc6_20.2 (constants.%b.patt)]
// CHECK:STDOUT:   %.loc6_10.2: @First.%pattern_type (%pattern_type.601) = pack_expansion_pattern %b.patt.loc6_20.2, %arity.patt.loc6_10.2 [symbolic = %.loc6_10.2 (constants.%.835)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type [symbolic = %require_complete (constants.%require_complete.7b2)]
// CHECK:STDOUT:   %.loc7_11.3: Core.IntLiteral = pack_index [symbolic = %.loc7_11.3 (constants.%.4ee)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%b.param: @First.%pack_type (%pack_type)) -> out %return.param: %i64 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc6_10.2 {
// CHECK:STDOUT:       %b.ref: @First.%pack_type (%pack_type) = name_ref b, %b
// CHECK:STDOUT:       %.loc7_11.1: Core.IntLiteral = pack_index [symbolic = %.loc7_11.3 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc7_11.2: bool = pack_element %b.ref, %.loc7_11.1
// CHECK:STDOUT:       if %.loc7_11.2 br !if.then.loc7 else br !if.else.loc7
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.then.loc7:
// CHECK:STDOUT:       %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:       %impl.elem0.loc8: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:       %bound_method.loc8_13.1: <bound method> = bound_method %int_1, %impl.elem0.loc8 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:       %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:       %bound_method.loc8_13.2: <bound method> = bound_method %int_1, %specific_fn.loc8 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:       %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8: init %i64 = call %bound_method.loc8_13.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:       %.loc8: init %i64 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc8 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:       return %.loc8
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.else.loc7:
// CHECK:STDOUT:       %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:       if %true br !if.then.loc9 else br !if.else.loc9
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.then.loc9:
// CHECK:STDOUT:       %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:       %impl.elem0.loc10: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:       %bound_method.loc10_13.1: <bound method> = bound_method %int_2, %impl.elem0.loc10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5d4]
// CHECK:STDOUT:       %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:       %bound_method.loc10_13.2: <bound method> = bound_method %int_2, %specific_fn.loc10 [concrete = constants.%bound_method.c9c]
// CHECK:STDOUT:       %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i64 = call %bound_method.loc10_13.2(%int_2) [concrete = constants.%int_2.405]
// CHECK:STDOUT:       %.loc10_13.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_2.405]
// CHECK:STDOUT:       %.loc10_13.2: %i64 = converted %int_2, %.loc10_13.1 [concrete = constants.%int_2.405]
// CHECK:STDOUT:       %Consume.call: init %empty_tuple.type = call %Consume.ref(%.loc10_13.2)
// CHECK:STDOUT:       br !if.else.loc9
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.else.loc9:
// CHECK:STDOUT:       br !if.done
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.done:
// CHECK:STDOUT:       pack_expansion_next
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc12: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc12_11.1: <bound method> = bound_method %int_0, %impl.elem0.loc12 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:     %specific_fn.loc12: <specific function> = specific_function %impl.elem0.loc12, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc12_11.2: <bound method> = bound_method %int_0, %specific_fn.loc12 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %i64 = call %bound_method.loc12_11.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc12: init %i64 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     return %.loc12
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @First(constants.%arity) {
// CHECK:STDOUT:   %arity.patt.loc6_10.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_10.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.601
// CHECK:STDOUT:   %b.param_patt.loc6_20.2 => constants.%b.param_patt
// CHECK:STDOUT:   %b.patt.loc6_20.2 => constants.%b.patt
// CHECK:STDOUT:   %.loc6_10.2 => constants.%.835
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Less.type: type = facet_type <@Less> [concrete]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %Less.assoc_type: type = assoc_entity_type @Less [concrete]
// CHECK:STDOUT:   %assoc0.a62: %Less.assoc_type = assoc_entity element0, @Less.WithSelf.%Less.WithSelf.Lt.decl [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.585: type = pattern_type %Less.type [concrete]
// CHECK:STDOUT:   %T.patt.96d: %pattern_type.585 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.7fb: %Less.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.7aa: type = facet_access_type %T.7fb [symbolic]
// CHECK:STDOUT:   %pattern_type.29d: type = pattern_type %T.as_type.7aa [symbolic]
// CHECK:STDOUT:   %first.param_patt: %pattern_type.29d = value_param_pattern [symbolic]
// CHECK:STDOUT:   %first.patt: %pattern_type.29d = wrapper_binding_pattern first, %first.param_patt [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %pack_type: type = pack_type %T.as_type.7aa, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.474: type = pattern_type %pack_type [symbolic]
// CHECK:STDOUT:   %next.param_patt: %pattern_type.474 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %next.patt: %pattern_type.474 = wrapper_binding_pattern next, %next.param_patt [symbolic]
// CHECK:STDOUT:   %.061: %pattern_type.474 = pack_expansion_pattern %next.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %AnyLess.type: type = fn_type @AnyLess [concrete]
// CHECK:STDOUT:   %AnyLess: %AnyLess.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.ff1: <witness> = require_complete_type %T.as_type.7aa [symbolic]
// CHECK:STDOUT:   %require_complete.6a7: <witness> = require_complete_type %pack_type [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %Less.WithSelf.Lt.type.7f6: type = fn_type @Less.WithSelf.Lt, @Less.WithSelf(%T.7fb) [symbolic]
// CHECK:STDOUT:   %Less.lookup_impl_witness: <witness> = lookup_impl_witness %T.7fb, @Less [symbolic]
// CHECK:STDOUT:   %.5b5: type = fn_type_with_self_type %Less.WithSelf.Lt.type.7f6, %T.7fb [symbolic]
// CHECK:STDOUT:   %impl.elem0.295: %.5b5 = impl_witness_access %Less.lookup_impl_witness, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.f75: <specific function> = specific_impl_function %impl.elem0.295, @Less.WithSelf.Lt(%T.7fb) [symbolic]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value bool, (%Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d02: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.e28: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d02, %Copy.facet [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.type: type = fn_type @bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op: %bool.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.bound.1b3: <bound method> = bound_method %true, %bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.bound.84b: <bound method> = bound_method %false, %bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.9c3: %bool.as.Copy.impl.Op.type = import_ref Core//prelude/parts/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.9c3), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %AnyLess.decl: %AnyLess.type = fn_decl @AnyLess [concrete = constants.%AnyLess] {
// CHECK:STDOUT:     %T.patt.loc8_13.1: %pattern_type.585 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc8_13.2 (constants.%T.patt.96d)]
// CHECK:STDOUT:     %first.param_patt.loc8_26.1: @AnyLess.%pattern_type.loc8_26 (%pattern_type.29d) = value_param_pattern [symbolic = %first.param_patt.loc8_26.2 (constants.%first.param_patt)]
// CHECK:STDOUT:     %first.patt.loc8_26.1: @AnyLess.%pattern_type.loc8_26 (%pattern_type.29d) = wrapper_binding_pattern first, %first.param_patt.loc8_26.1 [symbolic = %first.patt.loc8_26.2 (constants.%first.patt)]
// CHECK:STDOUT:     %arity.patt.loc8_31.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc8_31.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %next.param_patt.loc8_44.1: @AnyLess.%pattern_type.loc8_44 (%pattern_type.474) = value_param_pattern [symbolic = %next.param_patt.loc8_44.2 (constants.%next.param_patt)]
// CHECK:STDOUT:     %next.patt.loc8_44.1: @AnyLess.%pattern_type.loc8_44 (%pattern_type.474) = wrapper_binding_pattern next, %next.param_patt.loc8_44.1 [symbolic = %next.patt.loc8_44.2 (constants.%next.patt)]
// CHECK:STDOUT:     %.loc8_31.1: @AnyLess.%pattern_type.loc8_44 (%pattern_type.474) = pack_expansion_pattern %next.patt.loc8_44.1, %arity.patt.loc8_31.1 [symbolic = %.loc8_31.2 (constants.%.061)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc8_52.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc8_52.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc8_52.2: Core.Form = init_form %.loc8_52.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %.loc8_15: type = splice_block %Less.ref [concrete = constants.%Less.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Less.ref: type = name_ref Less, file.%Less.decl [concrete = constants.%Less.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc8_13.2: %Less.type = symbolic_binding T, 0 [symbolic = %T.loc8_13.1 (constants.%T.7fb)]
// CHECK:STDOUT:     %first.param: @AnyLess.%T.as_type.loc8_28.1 (%T.as_type.7aa) = value_param call_param0
// CHECK:STDOUT:     %.loc8_28.1: type = splice_block %.loc8_28.2 [symbolic = %T.as_type.loc8_28.1 (constants.%T.as_type.7aa)] {
// CHECK:STDOUT:       %T.ref.loc8_28: %Less.type = name_ref T, %T.loc8_13.2 [symbolic = %T.loc8_13.1 (constants.%T.7fb)]
// CHECK:STDOUT:       %T.as_type.loc8_28.2: type = facet_access_type %T.ref.loc8_28 [symbolic = %T.as_type.loc8_28.1 (constants.%T.as_type.7aa)]
// CHECK:STDOUT:       %.loc8_28.2: type = converted %T.ref.loc8_28, %T.as_type.loc8_28.2 [symbolic = %T.as_type.loc8_28.1 (constants.%T.as_type.7aa)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %first: @AnyLess.%T.as_type.loc8_28.1 (%T.as_type.7aa) = wrapper_binding first, %first.param
// CHECK:STDOUT:     %arity.loc8_31.2: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc8_31.1 (constants.%arity)]
// CHECK:STDOUT:     %next.param: @AnyLess.%pack_type (%pack_type) = value_param call_param1
// CHECK:STDOUT:     %.loc8_46.1: type = splice_block %.loc8_46.2 [symbolic = %T.as_type.loc8_28.1 (constants.%T.as_type.7aa)] {
// CHECK:STDOUT:       %T.ref.loc8_46: %Less.type = name_ref T, %T.loc8_13.2 [symbolic = %T.loc8_13.1 (constants.%T.7fb)]
// CHECK:STDOUT:       %T.as_type.loc8_46: type = facet_access_type %T.ref.loc8_46 [symbolic = %T.as_type.loc8_28.1 (constants.%T.as_type.7aa)]
// CHECK:STDOUT:       %.loc8_46.2: type = converted %T.ref.loc8_46, %T.as_type.loc8_46 [symbolic = %T.as_type.loc8_28.1 (constants.%T.as_type.7aa)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %next: @AnyLess.%pack_type (%pack_type) = wrapper_binding next, %next.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param2
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @AnyLess(%T.loc8_13.2: %Less.type, %arity.loc8_31.2: Core.IntLiteral) {
// CHECK:STDOUT:   %T.patt.loc8_13.2: %pattern_type.585 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc8_13.2 (constants.%T.patt.96d)]
// CHECK:STDOUT:   %T.loc8_13.1: %Less.type = symbolic_binding T, 0 [symbolic = %T.loc8_13.1 (constants.%T.7fb)]
// CHECK:STDOUT:   %T.as_type.loc8_28.1: type = facet_access_type %T.loc8_13.1 [symbolic = %T.as_type.loc8_28.1 (constants.%T.as_type.7aa)]
// CHECK:STDOUT:   %pattern_type.loc8_26: type = pattern_type %T.as_type.loc8_28.1 [symbolic = %pattern_type.loc8_26 (constants.%pattern_type.29d)]
// CHECK:STDOUT:   %first.param_patt.loc8_26.2: @AnyLess.%pattern_type.loc8_26 (%pattern_type.29d) = value_param_pattern [symbolic = %first.param_patt.loc8_26.2 (constants.%first.param_patt)]
// CHECK:STDOUT:   %first.patt.loc8_26.2: @AnyLess.%pattern_type.loc8_26 (%pattern_type.29d) = wrapper_binding_pattern first, %first.param_patt.loc8_26.2 [symbolic = %first.patt.loc8_26.2 (constants.%first.patt)]
// CHECK:STDOUT:   %arity.patt.loc8_31.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc8_31.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc8_31.1: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc8_31.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type %T.as_type.loc8_28.1, %arity.loc8_31.1 [symbolic = %pack_type (constants.%pack_type)]
// CHECK:STDOUT:   %pattern_type.loc8_44: type = pattern_type %pack_type [symbolic = %pattern_type.loc8_44 (constants.%pattern_type.474)]
// CHECK:STDOUT:   %next.param_patt.loc8_44.2: @AnyLess.%pattern_type.loc8_44 (%pattern_type.474) = value_param_pattern [symbolic = %next.param_patt.loc8_44.2 (constants.%next.param_patt)]
// CHECK:STDOUT:   %next.patt.loc8_44.2: @AnyLess.%pattern_type.loc8_44 (%pattern_type.474) = wrapper_binding_pattern next, %next.param_patt.loc8_44.2 [symbolic = %next.patt.loc8_44.2 (constants.%next.patt)]
// CHECK:STDOUT:   %.loc8_31.2: @AnyLess.%pattern_type.loc8_44 (%pattern_type.474) = pack_expansion_pattern %next.patt.loc8_44.2, %arity.patt.loc8_31.2 [symbolic = %.loc8_31.2 (constants.%.061)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8_26: <witness> = require_complete_type %T.as_type.loc8_28.1 [symbolic = %require_complete.loc8_26 (constants.%require_complete.ff1)]
// CHECK:STDOUT:   %require_complete.loc8_44: <witness> = require_complete_type %pack_type [symbolic = %require_complete.loc8_44 (constants.%require_complete.6a7)]
// CHECK:STDOUT:   %.loc9_11.3: Core.IntLiteral = pack_index [symbolic = %.loc9_11.3 (constants.%.4ee)]
// CHECK:STDOUT:   %Less.WithSelf.Lt.type: type = fn_type @Less.WithSelf.Lt, @Less.WithSelf(%T.loc8_13.1) [symbolic = %Less.WithSelf.Lt.type (constants.%Less.WithSelf.Lt.type.7f6)]
// CHECK:STDOUT:   %.loc9_20: type = fn_type_with_self_type %Less.WithSelf.Lt.type, %T.loc8_13.1 [symbolic = %.loc9_20 (constants.%.5b5)]
// CHECK:STDOUT:   %Less.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc8_13.1, @Less [symbolic = %Less.lookup_impl_witness (constants.%Less.lookup_impl_witness)]
// CHECK:STDOUT:   %impl.elem0.loc9_20.2: @AnyLess.%.loc9_20 (%.5b5) = impl_witness_access %Less.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc9_20.2 (constants.%impl.elem0.295)]
// CHECK:STDOUT:   %specific_impl_fn.loc9_20.2: <specific function> = specific_impl_function %impl.elem0.loc9_20.2, @Less.WithSelf.Lt(%T.loc8_13.1) [symbolic = %specific_impl_fn.loc9_20.2 (constants.%specific_impl_fn.f75)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%first.param: @AnyLess.%T.as_type.loc8_28.1 (%T.as_type.7aa), %next.param: @AnyLess.%pack_type (%pack_type)) -> out %return.param: bool {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc8_31.2 {
// CHECK:STDOUT:       %next.ref: @AnyLess.%pack_type (%pack_type) = name_ref next, %next
// CHECK:STDOUT:       %.loc9_11.1: Core.IntLiteral = pack_index [symbolic = %.loc9_11.3 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc9_11.2: @AnyLess.%T.as_type.loc8_28.1 (%T.as_type.7aa) = pack_element %next.ref, %.loc9_11.1
// CHECK:STDOUT:       %Lt.ref: %Less.assoc_type = name_ref Lt, @Less.WithSelf.%assoc0 [concrete = constants.%assoc0.a62]
// CHECK:STDOUT:       %impl.elem0.loc9_20.1: @AnyLess.%.loc9_20 (%.5b5) = impl_witness_access constants.%Less.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc9_20.2 (constants.%impl.elem0.295)]
// CHECK:STDOUT:       %bound_method.loc9_20: <bound method> = bound_method %.loc9_11.2, %impl.elem0.loc9_20.1
// CHECK:STDOUT:       %first.ref: @AnyLess.%T.as_type.loc8_28.1 (%T.as_type.7aa) = name_ref first, %first
// CHECK:STDOUT:       %.loc9_29.1: %Less.type = converted constants.%T.as_type.7aa, constants.%T.7fb [symbolic = %T.loc8_13.1 (constants.%T.7fb)]
// CHECK:STDOUT:       %.loc9_29.2: %Less.type = converted constants.%T.as_type.7aa, constants.%T.7fb [symbolic = %T.loc8_13.1 (constants.%T.7fb)]
// CHECK:STDOUT:       %.loc9_29.3: %Less.type = converted constants.%T.as_type.7aa, constants.%T.7fb [symbolic = %T.loc8_13.1 (constants.%T.7fb)]
// CHECK:STDOUT:       %.loc9_29.4: %Less.type = converted constants.%T.as_type.7aa, constants.%T.7fb [symbolic = %T.loc8_13.1 (constants.%T.7fb)]
// CHECK:STDOUT:       %specific_impl_fn.loc9_20.1: <specific function> = specific_impl_function %impl.elem0.loc9_20.1, @Less.WithSelf.Lt(constants.%T.7fb) [symbolic = %specific_impl_fn.loc9_20.2 (constants.%specific_impl_fn.f75)]
// CHECK:STDOUT:       %bound_method.loc9_29: <bound method> = bound_method %.loc9_11.2, %specific_impl_fn.loc9_20.1
// CHECK:STDOUT:       %Less.WithSelf.Lt.call: init bool = call %bound_method.loc9_29(%.loc9_11.2, %first.ref)
// CHECK:STDOUT:       %.loc9_30.1: bool = value_of_initializer %Less.WithSelf.Lt.call
// CHECK:STDOUT:       %.loc9_30.2: bool = converted %Less.WithSelf.Lt.call, %.loc9_30.1
// CHECK:STDOUT:       if %.loc9_30.2 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.then:
// CHECK:STDOUT:       %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:       %impl.elem0.loc10: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:       %bound_method.loc10: <bound method> = bound_method %true, %impl.elem0.loc10 [concrete = constants.%bool.as.Copy.impl.Op.bound.1b3]
// CHECK:STDOUT:       %bool.as.Copy.impl.Op.call.loc10: init bool = call %bound_method.loc10(%true) [concrete = constants.%true]
// CHECK:STDOUT:       return %bool.as.Copy.impl.Op.call.loc10
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.else:
// CHECK:STDOUT:       pack_expansion_next
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %false: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:     %impl.elem0.loc12: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:     %bound_method.loc12: <bound method> = bound_method %false, %impl.elem0.loc12 [concrete = constants.%bool.as.Copy.impl.Op.bound.84b]
// CHECK:STDOUT:     %bool.as.Copy.impl.Op.call.loc12: init bool = call %bound_method.loc12(%false) [concrete = constants.%false]
// CHECK:STDOUT:     return %bool.as.Copy.impl.Op.call.loc12
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @AnyLess(constants.%T.7fb, constants.%arity) {
// CHECK:STDOUT:   %T.patt.loc8_13.2 => constants.%T.patt.96d
// CHECK:STDOUT:   %T.loc8_13.1 => constants.%T.7fb
// CHECK:STDOUT:   %T.as_type.loc8_28.1 => constants.%T.as_type.7aa
// CHECK:STDOUT:   %pattern_type.loc8_26 => constants.%pattern_type.29d
// CHECK:STDOUT:   %first.param_patt.loc8_26.2 => constants.%first.param_patt
// CHECK:STDOUT:   %first.patt.loc8_26.2 => constants.%first.patt
// CHECK:STDOUT:   %arity.patt.loc8_31.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc8_31.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type
// CHECK:STDOUT:   %pattern_type.loc8_44 => constants.%pattern_type.474
// CHECK:STDOUT:   %next.param_patt.loc8_44.2 => constants.%next.param_patt
// CHECK:STDOUT:   %next.patt.loc8_44.2 => constants.%next.patt
// CHECK:STDOUT:   %.loc8_31.2 => constants.%.061
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- nested.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type: type = pack_type bool, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.601: type = pattern_type %pack_type [symbolic]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.601 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %b.patt: %pattern_type.601 = wrapper_binding_pattern b, %b.param_patt [symbolic]
// CHECK:STDOUT:   %.835: %pattern_type.601 = pack_expansion_pattern %b.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.7b2: <witness> = require_complete_type %pack_type [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
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
// CHECK:STDOUT:     %arity.patt.loc6_6.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %b.param_patt.loc6_16.1: @F.%pattern_type (%pattern_type.601) = value_param_pattern [symbolic = %b.param_patt.loc6_16.2 (constants.%b.param_patt)]
// CHECK:STDOUT:     %b.patt.loc6_16.1: @F.%pattern_type (%pattern_type.601) = wrapper_binding_pattern b, %b.param_patt.loc6_16.1 [symbolic = %b.patt.loc6_16.2 (constants.%b.patt)]
// CHECK:STDOUT:     %.loc6_6.1: @F.%pattern_type (%pattern_type.601) = pack_expansion_pattern %b.patt.loc6_16.1, %arity.patt.loc6_6.1 [symbolic = %.loc6_6.2 (constants.%.835)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc6_6.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_6.1 (constants.%arity)]
// CHECK:STDOUT:     %b.param: @F.%pack_type (%pack_type) = value_param call_param0
// CHECK:STDOUT:     %.loc6_18: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: @F.%pack_type (%pack_type) = wrapper_binding b, %b.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%arity.loc6_6.2: Core.IntLiteral) {
// CHECK:STDOUT:   %arity.patt.loc6_6.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc6_6.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_6.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type bool, %arity.loc6_6.1 [symbolic = %pack_type (constants.%pack_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type [symbolic = %pattern_type (constants.%pattern_type.601)]
// CHECK:STDOUT:   %b.param_patt.loc6_16.2: @F.%pattern_type (%pattern_type.601) = value_param_pattern [symbolic = %b.param_patt.loc6_16.2 (constants.%b.param_patt)]
// CHECK:STDOUT:   %b.patt.loc6_16.2: @F.%pattern_type (%pattern_type.601) = wrapper_binding_pattern b, %b.param_patt.loc6_16.2 [symbolic = %b.patt.loc6_16.2 (constants.%b.patt)]
// CHECK:STDOUT:   %.loc6_6.2: @F.%pattern_type (%pattern_type.601) = pack_expansion_pattern %b.patt.loc6_16.2, %arity.patt.loc6_6.2 [symbolic = %.loc6_6.2 (constants.%.835)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type [symbolic = %require_complete (constants.%require_complete.7b2)]
// CHECK:STDOUT:   %.loc7_11.3: Core.IntLiteral = pack_index [symbolic = %.loc7_11.3 (constants.%.4ee)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%b.param: @F.%pack_type (%pack_type)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc6_6.2 {
// CHECK:STDOUT:       %b.ref.loc7: @F.%pack_type (%pack_type) = name_ref b, %b
// CHECK:STDOUT:       %.loc7_11.1: Core.IntLiteral = pack_index [symbolic = %.loc7_11.3 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc7_11.2: bool = pack_element %b.ref.loc7, %.loc7_11.1
// CHECK:STDOUT:       if %.loc7_11.2 br !if.then.loc7 else br !if.else.loc7
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.then.loc7:
// CHECK:STDOUT:       %b.ref.loc8: @F.%pack_type (%pack_type) = name_ref b, %b
// CHECK:STDOUT:       %.loc8_9.1: Core.IntLiteral = pack_index [symbolic = %.loc7_11.3 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc8_9.2: bool = pack_element %b.ref.loc8, %.loc8_9.1
// CHECK:STDOUT:       if %.loc8_9.2 br !if.then.loc8 else br !if.else.loc8
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.then.loc8:
// CHECK:STDOUT:       %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:       %impl.elem0: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:       %bound_method.loc9_15.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:       %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:       %bound_method.loc9_15.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:       %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc9_15.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:       %.loc9_15.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.d98]
// CHECK:STDOUT:       %.loc9_15.2: %i64 = converted %int_1, %.loc9_15.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:       %Consume.call: init %empty_tuple.type = call %Consume.ref(%.loc9_15.2)
// CHECK:STDOUT:       br !if.else.loc8
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.else.loc8:
// CHECK:STDOUT:       br !if.else.loc7
// CHECK:STDOUT:
// CHECK:STDOUT:     !if.else.loc7:
// CHECK:STDOUT:       pack_expansion_next
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%arity) {
// CHECK:STDOUT:   %arity.patt.loc6_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_6.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.601
// CHECK:STDOUT:   %b.param_patt.loc6_16.2 => constants.%b.param_patt
// CHECK:STDOUT:   %b.patt.loc6_16.2 => constants.%b.patt
// CHECK:STDOUT:   %.loc6_6.2 => constants.%.835
// CHECK:STDOUT: }
// CHECK:STDOUT:
