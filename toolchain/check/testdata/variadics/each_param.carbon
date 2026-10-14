// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/each_param.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/each_param.carbon

// --- statement.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn ForEach(... each n: i64) {
  ... Consume(each n);
}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  ForEach(1, 2, 3);
  ForEach();
  //@dump-sem-ir-end
}

// --- fixed_params.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn Middle(first: i64, ... each mid: i64, last: i64) {
  Consume(first);
  ... Consume(each mid);
  Consume(last);
}

fn Call() {
  //@dump-sem-ir-begin
  Middle(1, 2);
  Middle(1, 2, 3, 4);
  //@dump-sem-ir-end
}

// --- deduced_element_type.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](unused x: T) {}

//@dump-sem-ir-begin
fn ForEach[T: type](first: T, ... each next: T) {
  Consume(first);
  ... Consume(each next);
}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  ForEach(1 as i64, 2 as i64, 3 as i64);
  ForEach(true);
  //@dump-sem-ir-end
}

// --- redecl.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach(... each n: i64);

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

// --- method.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

class C {
  fn ForEach(unused self, ... each n: i64) {
    ... Consume(each n);
  }
}

fn Call(c: C) {
  //@dump-sem-ir-begin
  c.ForEach(1, 2);
  //@dump-sem-ir-end
}

// --- class_element.carbon
library "[[@TEST_NAME]]";

class C {
  var a: i64;
}

fn Consume(c: C);

//@dump-sem-ir-begin
fn ForEach(... each c: C) {
  ... Consume(each c);
}
//@dump-sem-ir-end

fn Call(c: C, d: C) {
  //@dump-sem-ir-begin
  ForEach(c, d);
  //@dump-sem-ir-end
}

// --- generic_caller.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](unused x: T) {}

fn ForEach[T: type](... each x: T) {
  ... Consume(each x);
}

//@dump-sem-ir-begin
fn Twice[U: type](a: U) {
  ForEach(a, a);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- statement.carbon
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
// CHECK:STDOUT:   %pack_type.5d5: type = pack_type %i64, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.b58: type = pattern_type %pack_type.5d5 [symbolic]
// CHECK:STDOUT:   %n.param_patt.601: %pattern_type.b58 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %n.patt.068: %pattern_type.b58 = wrapper_binding_pattern n, %n.param_patt.601 [symbolic]
// CHECK:STDOUT:   %.a5f: %pattern_type.b58 = pack_expansion_pattern %n.patt.068, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.241: <witness> = require_complete_type %pack_type.5d5 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (Core.IntLiteral, Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %pack_type.1ff: type = pack_type %i64, %int_3.1ba [concrete]
// CHECK:STDOUT:   %pattern_type.cf1: type = pattern_type %pack_type.1ff [concrete]
// CHECK:STDOUT:   %n.param_patt.fcc: %pattern_type.cf1 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt.c43: %pattern_type.cf1 = wrapper_binding_pattern n, %n.param_patt.fcc [concrete]
// CHECK:STDOUT:   %.ad1: %pattern_type.cf1 = pack_expansion_pattern %n.patt.c43, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForEach.specific_fn.9c5: <specific function> = specific_function %ForEach, @ForEach(%int_3.1ba) [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5d4: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.c9c: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.405: %i64 = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.740: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.bd2: %i64 = int_value 3 [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %pack_type.71f: type = pack_type %i64, %int_0 [concrete]
// CHECK:STDOUT:   %pattern_type.02a: type = pattern_type %pack_type.71f [concrete]
// CHECK:STDOUT:   %n.param_patt.2b7: %pattern_type.02a = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt.6be: %pattern_type.02a = wrapper_binding_pattern n, %n.param_patt.2b7 [concrete]
// CHECK:STDOUT:   %.864: %pattern_type.02a = pack_expansion_pattern %n.patt.6be, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForEach.specific_fn.61e: <specific function> = specific_function %ForEach, @ForEach(%int_0) [concrete]
// CHECK:STDOUT:   %complete_type.50f: <witness> = complete_type_witness %pack_type.1ff [concrete]
// CHECK:STDOUT:   %complete_type.f3b: <witness> = complete_type_witness %pack_type.71f [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ForEach.decl: %ForEach.type = fn_decl @ForEach [concrete = constants.%ForEach] {
// CHECK:STDOUT:     %arity.patt.loc6_12.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %n.param_patt.loc6_22.1: @ForEach.%pattern_type (%pattern_type.b58) = value_param_pattern [symbolic = %n.param_patt.loc6_22.2 (constants.%n.param_patt.601)]
// CHECK:STDOUT:     %n.patt.loc6_22.1: @ForEach.%pattern_type (%pattern_type.b58) = wrapper_binding_pattern n, %n.param_patt.loc6_22.1 [symbolic = %n.patt.loc6_22.2 (constants.%n.patt.068)]
// CHECK:STDOUT:     %.loc6_12.1: @ForEach.%pattern_type (%pattern_type.b58) = pack_expansion_pattern %n.patt.loc6_22.1, %arity.patt.loc6_12.1 [symbolic = %.loc6_12.2 (constants.%.a5f)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc6_12.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_12.1 (constants.%arity)]
// CHECK:STDOUT:     %n.param: @ForEach.%pack_type (%pack_type.5d5) = value_param call_param0
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %n: @ForEach.%pack_type (%pack_type.5d5) = wrapper_binding n, %n.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ForEach(%arity.loc6_12.2: Core.IntLiteral) {
// CHECK:STDOUT:   %arity.patt.loc6_12.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc6_12.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_12.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type constants.%i64, %arity.loc6_12.1 [symbolic = %pack_type (constants.%pack_type.5d5)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type [symbolic = %pattern_type (constants.%pattern_type.b58)]
// CHECK:STDOUT:   %n.param_patt.loc6_22.2: @ForEach.%pattern_type (%pattern_type.b58) = value_param_pattern [symbolic = %n.param_patt.loc6_22.2 (constants.%n.param_patt.601)]
// CHECK:STDOUT:   %n.patt.loc6_22.2: @ForEach.%pattern_type (%pattern_type.b58) = wrapper_binding_pattern n, %n.param_patt.loc6_22.2 [symbolic = %n.patt.loc6_22.2 (constants.%n.patt.068)]
// CHECK:STDOUT:   %.loc6_12.2: @ForEach.%pattern_type (%pattern_type.b58) = pack_expansion_pattern %n.patt.loc6_22.2, %arity.patt.loc6_12.2 [symbolic = %.loc6_12.2 (constants.%.a5f)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type [symbolic = %require_complete (constants.%require_complete.241)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%n.param: @ForEach.%pack_type (%pack_type.5d5)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc6_12.2 {
// CHECK:STDOUT:       %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %n.ref: @ForEach.%pack_type (%pack_type.5d5) = name_ref n, %n
// CHECK:STDOUT:       %.loc7_15.1: Core.IntLiteral = pack_index
// CHECK:STDOUT:       %.loc7_15.2: %i64 = pack_element %n.ref, %.loc7_15.1
// CHECK:STDOUT:       %Consume.call: init %empty_tuple.type = call %Consume.ref(%.loc7_15.2)
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %ForEach.ref.loc13: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %int_3.loc13_17: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc13_11.1: %tuple.type = pack_literal (%int_1, %int_2, %int_3.loc13_17)
// CHECK:STDOUT:   %int_3.loc13_18.1: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %int_3.loc13_18.2: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %ForEach.specific_fn.loc13: <specific function> = specific_function %ForEach.ref.loc13, @ForEach(constants.%int_3.1ba) [concrete = constants.%ForEach.specific_fn.9c5]
// CHECK:STDOUT:   %impl.elem0.loc13_11: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc13_11.1: <bound method> = bound_method %int_1, %impl.elem0.loc13_11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:   %specific_fn.loc13_11: <specific function> = specific_function %impl.elem0.loc13_11, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_11.2: <bound method> = bound_method %int_1, %specific_fn.loc13_11 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_11: init %i64 = call %bound_method.loc13_11.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc13_11.2: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_11 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc13_11.3: %i64 = converted %int_1, %.loc13_11.2 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %impl.elem0.loc13_14: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc13_14.1: <bound method> = bound_method %int_2, %impl.elem0.loc13_14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5d4]
// CHECK:STDOUT:   %specific_fn.loc13_14: <specific function> = specific_function %impl.elem0.loc13_14, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_14.2: <bound method> = bound_method %int_2, %specific_fn.loc13_14 [concrete = constants.%bound_method.c9c]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_14: init %i64 = call %bound_method.loc13_14.2(%int_2) [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc13_14.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_14 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc13_14.2: %i64 = converted %int_2, %.loc13_14.1 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %impl.elem0.loc13_17: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc13_17.1: <bound method> = bound_method %int_3.loc13_17, %impl.elem0.loc13_17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c]
// CHECK:STDOUT:   %specific_fn.loc13_17: <specific function> = specific_function %impl.elem0.loc13_17, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_17.2: <bound method> = bound_method %int_3.loc13_17, %specific_fn.loc13_17 [concrete = constants.%bound_method.740]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_17: init %i64 = call %bound_method.loc13_17.2(%int_3.loc13_17) [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc13_17.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_17 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc13_17.2: %i64 = converted %int_3.loc13_17, %.loc13_17.1 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc13_11.4: %pack_type.1ff = pack_value (%.loc13_11.3, %.loc13_14.2, %.loc13_17.2)
// CHECK:STDOUT:   %.loc13_11.5: %pack_type.1ff = converted %.loc13_11.1, %.loc13_11.4
// CHECK:STDOUT:   %ForEach.call.loc13: init %empty_tuple.type = call %ForEach.specific_fn.loc13(%.loc13_11.5)
// CHECK:STDOUT:   %ForEach.ref.loc14: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:   %.loc14_11.1: %empty_tuple.type = pack_literal ()
// CHECK:STDOUT:   %int_0.loc14_11.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %int_0.loc14_11.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %ForEach.specific_fn.loc14: <specific function> = specific_function %ForEach.ref.loc14, @ForEach(constants.%int_0) [concrete = constants.%ForEach.specific_fn.61e]
// CHECK:STDOUT:   %.loc14_11.2: %pack_type.71f = pack_value ()
// CHECK:STDOUT:   %.loc14_11.3: %pack_type.71f = converted %.loc14_11.1, %.loc14_11.2
// CHECK:STDOUT:   %ForEach.call.loc14: init %empty_tuple.type = call %ForEach.specific_fn.loc14(%.loc14_11.3)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%arity) {
// CHECK:STDOUT:   %arity.patt.loc6_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_12.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type.5d5
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.b58
// CHECK:STDOUT:   %n.param_patt.loc6_22.2 => constants.%n.param_patt.601
// CHECK:STDOUT:   %n.patt.loc6_22.2 => constants.%n.patt.068
// CHECK:STDOUT:   %.loc6_12.2 => constants.%.a5f
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%int_3.1ba) {
// CHECK:STDOUT:   %arity.patt.loc6_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_12.1 => constants.%int_3.1ba
// CHECK:STDOUT:   %pack_type => constants.%pack_type.1ff
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.cf1
// CHECK:STDOUT:   %n.param_patt.loc6_22.2 => constants.%n.param_patt.fcc
// CHECK:STDOUT:   %n.patt.loc6_22.2 => constants.%n.patt.c43
// CHECK:STDOUT:   %.loc6_12.2 => constants.%.ad1
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.50f
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%int_0) {
// CHECK:STDOUT:   %arity.patt.loc6_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_12.1 => constants.%int_0
// CHECK:STDOUT:   %pack_type => constants.%pack_type.71f
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.02a
// CHECK:STDOUT:   %n.param_patt.loc6_22.2 => constants.%n.param_patt.2b7
// CHECK:STDOUT:   %n.patt.loc6_22.2 => constants.%n.patt.6be
// CHECK:STDOUT:   %.loc6_12.2 => constants.%.864
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.f3b
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- fixed_params.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Middle.type: type = fn_type @Middle [concrete]
// CHECK:STDOUT:   %Middle: %Middle.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %pack_type.71f: type = pack_type %i64, %int_0 [concrete]
// CHECK:STDOUT:   %Middle.specific_fn.38b: <specific function> = specific_function %Middle, @Middle(%int_0) [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5d4: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.c9c: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.405: %i64 = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %int_4.0c1: Core.IntLiteral = int_value 4 [concrete]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %pack_type.f7c: type = pack_type %i64, %int_2.ecc [concrete]
// CHECK:STDOUT:   %Middle.specific_fn.f1d: <specific function> = specific_function %Middle, @Middle(%int_2.ecc) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.740: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.bd2: %i64 = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.b50: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.912: <bound method> = bound_method %int_4.0c1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_4.825: %i64 = int_value 4 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Middle.ref.loc13: %Middle.type = name_ref Middle, file.%Middle.decl [concrete = constants.%Middle]
// CHECK:STDOUT:   %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2.loc13: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc13_14.1: %empty_tuple.type = pack_literal ()
// CHECK:STDOUT:   %int_0.loc13_14.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %int_0.loc13_14.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %Middle.specific_fn.loc13: <specific function> = specific_function %Middle.ref.loc13, @Middle(constants.%int_0) [concrete = constants.%Middle.specific_fn.38b]
// CHECK:STDOUT:   %impl.elem0.loc13_10: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc13_10.1: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:   %specific_fn.loc13_10: <specific function> = specific_function %impl.elem0.loc13_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_10.2: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_10 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_10: init %i64 = call %bound_method.loc13_10.2(%int_1.loc13) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc13_10.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_10 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc13_10.2: %i64 = converted %int_1.loc13, %.loc13_10.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc13_14.2: %pack_type.71f = pack_value ()
// CHECK:STDOUT:   %.loc13_14.3: %pack_type.71f = converted %.loc13_14.1, %.loc13_14.2
// CHECK:STDOUT:   %impl.elem0.loc13_13: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc13_13.1: <bound method> = bound_method %int_2.loc13, %impl.elem0.loc13_13 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5d4]
// CHECK:STDOUT:   %specific_fn.loc13_13: <specific function> = specific_function %impl.elem0.loc13_13, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_13.2: <bound method> = bound_method %int_2.loc13, %specific_fn.loc13_13 [concrete = constants.%bound_method.c9c]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_13: init %i64 = call %bound_method.loc13_13.2(%int_2.loc13) [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc13_13.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_13 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc13_13.2: %i64 = converted %int_2.loc13, %.loc13_13.1 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %Middle.call.loc13: init %empty_tuple.type = call %Middle.specific_fn.loc13(%.loc13_10.2, %.loc13_14.3, %.loc13_13.2)
// CHECK:STDOUT:   %Middle.ref.loc14: %Middle.type = name_ref Middle, file.%Middle.decl [concrete = constants.%Middle]
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2.loc14_13: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %int_4: Core.IntLiteral = int_value 4 [concrete = constants.%int_4.0c1]
// CHECK:STDOUT:   %.loc14_13.1: %tuple.type = pack_literal (%int_2.loc14_13, %int_3)
// CHECK:STDOUT:   %int_2.loc14_20.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %int_2.loc14_20.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %Middle.specific_fn.loc14: <specific function> = specific_function %Middle.ref.loc14, @Middle(constants.%int_2.ecc) [concrete = constants.%Middle.specific_fn.f1d]
// CHECK:STDOUT:   %impl.elem0.loc14_10: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc14_10.1: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:   %specific_fn.loc14_10: <specific function> = specific_function %impl.elem0.loc14_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_10.2: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14_10 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_10: init %i64 = call %bound_method.loc14_10.2(%int_1.loc14) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc14_10.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_10 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc14_10.2: %i64 = converted %int_1.loc14, %.loc14_10.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %impl.elem0.loc14_13: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc14_13.1: <bound method> = bound_method %int_2.loc14_13, %impl.elem0.loc14_13 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5d4]
// CHECK:STDOUT:   %specific_fn.loc14_13: <specific function> = specific_function %impl.elem0.loc14_13, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_13.2: <bound method> = bound_method %int_2.loc14_13, %specific_fn.loc14_13 [concrete = constants.%bound_method.c9c]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_13: init %i64 = call %bound_method.loc14_13.2(%int_2.loc14_13) [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc14_13.2: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_13 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc14_13.3: %i64 = converted %int_2.loc14_13, %.loc14_13.2 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %impl.elem0.loc14_16: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc14_16.1: <bound method> = bound_method %int_3, %impl.elem0.loc14_16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.e9c]
// CHECK:STDOUT:   %specific_fn.loc14_16: <specific function> = specific_function %impl.elem0.loc14_16, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_16.2: <bound method> = bound_method %int_3, %specific_fn.loc14_16 [concrete = constants.%bound_method.740]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_16: init %i64 = call %bound_method.loc14_16.2(%int_3) [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc14_16.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_16 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc14_16.2: %i64 = converted %int_3, %.loc14_16.1 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc14_13.4: %pack_type.f7c = pack_value (%.loc14_13.3, %.loc14_16.2)
// CHECK:STDOUT:   %.loc14_13.5: %pack_type.f7c = converted %.loc14_13.1, %.loc14_13.4
// CHECK:STDOUT:   %impl.elem0.loc14_19: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc14_19.1: <bound method> = bound_method %int_4, %impl.elem0.loc14_19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.b50]
// CHECK:STDOUT:   %specific_fn.loc14_19: <specific function> = specific_function %impl.elem0.loc14_19, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_19.2: <bound method> = bound_method %int_4, %specific_fn.loc14_19 [concrete = constants.%bound_method.912]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_19: init %i64 = call %bound_method.loc14_19.2(%int_4) [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %.loc14_19.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_19 [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %.loc14_19.2: %i64 = converted %int_4, %.loc14_19.1 [concrete = constants.%int_4.825]
// CHECK:STDOUT:   %Middle.call.loc14: init %empty_tuple.type = call %Middle.specific_fn.loc14(%.loc14_10.2, %.loc14_13.5, %.loc14_19.2)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- deduced_element_type.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T [symbolic]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T [symbolic]
// CHECK:STDOUT:   %first.param_patt.4f2: %pattern_type.51d1c4.1 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %first.patt.2a6: %pattern_type.51d1c4.1 = wrapper_binding_pattern first, %first.param_patt.4f2 [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %pack_type.2fb: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.48c: type = pattern_type %pack_type.2fb [symbolic]
// CHECK:STDOUT:   %next.param_patt.273: %pattern_type.48c = value_param_pattern [symbolic]
// CHECK:STDOUT:   %next.patt.893: %pattern_type.48c = wrapper_binding_pattern next, %next.param_patt.273 [symbolic]
// CHECK:STDOUT:   %.0a4: %pattern_type.48c = pack_expansion_pattern %next.patt.893, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.d90: <witness> = require_complete_type %pack_type.2fb [symbolic]
// CHECK:STDOUT:   %Consume.specific_fn.86b: <specific function> = specific_function %Consume, @Consume(%T) [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %complete_type.4a1: <witness> = complete_type_witness %i64.builtin [concrete]
// CHECK:STDOUT:   %As.type.998: type = facet_type <@As, @As(%i64)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.c5d: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.6ee: %Core.IntLiteral.as.As.impl.Convert.type.c5d = struct_value () [symbolic]
// CHECK:STDOUT:   %As.impl_witness.0fe: <witness> = impl_witness imports.%As.impl_witness_table.d22, @Core.IntLiteral.as.As.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.type.1a1: type = fn_type @Core.IntLiteral.as.As.impl.Convert, @Core.IntLiteral.as.As.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.3d9: %Core.IntLiteral.as.As.impl.Convert.type.1a1 = struct_value () [concrete]
// CHECK:STDOUT:   %As.facet: %As.type.998 = facet_value Core.IntLiteral, (%As.impl_witness.0fe) [concrete]
// CHECK:STDOUT:   %As.WithSelf.Convert.type.7f7: type = fn_type @As.WithSelf.Convert, @As.WithSelf(%i64, %As.facet) [concrete]
// CHECK:STDOUT:   %.8fd: type = fn_type_with_self_type %As.WithSelf.Convert.type.7f7, %As.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound.ab2: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.3d9 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.3d9, @Core.IntLiteral.as.As.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.991: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound.d11: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.As.impl.Convert.3d9 [concrete]
// CHECK:STDOUT:   %bound_method.b92: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.405: %i64 = int_value 2 [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound.eee: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.As.impl.Convert.3d9 [concrete]
// CHECK:STDOUT:   %bound_method.2c8: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.bd2: %i64 = int_value 3 [concrete]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%i64, %i64) [concrete]
// CHECK:STDOUT:   %first.param_patt.a4b: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %first.patt.4d6: %pattern_type.f57 = wrapper_binding_pattern first, %first.param_patt.a4b [concrete]
// CHECK:STDOUT:   %pack_type.f7c: type = pack_type %i64, %int_2.ecc [concrete]
// CHECK:STDOUT:   %pattern_type.a38: type = pattern_type %pack_type.f7c [concrete]
// CHECK:STDOUT:   %next.param_patt.c0d: %pattern_type.a38 = value_param_pattern [concrete]
// CHECK:STDOUT:   %next.patt.228: %pattern_type.a38 = wrapper_binding_pattern next, %next.param_patt.c0d [concrete]
// CHECK:STDOUT:   %.87e: %pattern_type.a38 = pack_expansion_pattern %next.patt.228, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForEach.specific_fn.b11: <specific function> = specific_function %ForEach, @ForEach(%i64, %int_2.ecc) [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %first.param_patt.deb: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %first.patt.06b: %pattern_type.831 = wrapper_binding_pattern first, %first.param_patt.deb [concrete]
// CHECK:STDOUT:   %pack_type.8ed: type = pack_type bool, %int_0 [concrete]
// CHECK:STDOUT:   %pattern_type.9b0: type = pattern_type %pack_type.8ed [concrete]
// CHECK:STDOUT:   %next.param_patt.e27: %pattern_type.9b0 = value_param_pattern [concrete]
// CHECK:STDOUT:   %next.patt.f92: %pattern_type.9b0 = wrapper_binding_pattern next, %next.param_patt.e27 [concrete]
// CHECK:STDOUT:   %.469: %pattern_type.9b0 = pack_expansion_pattern %next.patt.f92, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForEach.specific_fn.370: <specific function> = specific_function %ForEach, @ForEach(bool, %int_0) [concrete]
// CHECK:STDOUT:   %complete_type.46f: <witness> = complete_type_witness %pack_type.f7c [concrete]
// CHECK:STDOUT:   %Consume.specific_fn.e83: <specific function> = specific_function %Consume, @Consume(%i64) [concrete]
// CHECK:STDOUT:   %complete_type.127: <witness> = complete_type_witness bool [concrete]
// CHECK:STDOUT:   %complete_type.db7: <witness> = complete_type_witness %pack_type.8ed [concrete]
// CHECK:STDOUT:   %Consume.specific_fn.272: <specific function> = specific_function %Consume, @Consume(bool) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ForEach.decl: %ForEach.type = fn_decl @ForEach [concrete = constants.%ForEach] {
// CHECK:STDOUT:     %T.patt.loc6_13.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc6_13.2 (constants.%T.patt)]
// CHECK:STDOUT:     %first.param_patt.loc6_26.1: @ForEach.%pattern_type.loc6_26 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %first.param_patt.loc6_26.2 (constants.%first.param_patt.4f2)]
// CHECK:STDOUT:     %first.patt.loc6_26.1: @ForEach.%pattern_type.loc6_26 (%pattern_type.51d1c4.1) = wrapper_binding_pattern first, %first.param_patt.loc6_26.1 [symbolic = %first.patt.loc6_26.2 (constants.%first.patt.2a6)]
// CHECK:STDOUT:     %arity.patt.loc6_31.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc6_31.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %next.param_patt.loc6_44.1: @ForEach.%pattern_type.loc6_44 (%pattern_type.48c) = value_param_pattern [symbolic = %next.param_patt.loc6_44.2 (constants.%next.param_patt.273)]
// CHECK:STDOUT:     %next.patt.loc6_44.1: @ForEach.%pattern_type.loc6_44 (%pattern_type.48c) = wrapper_binding_pattern next, %next.param_patt.loc6_44.1 [symbolic = %next.patt.loc6_44.2 (constants.%next.patt.893)]
// CHECK:STDOUT:     %.loc6_31.1: @ForEach.%pattern_type.loc6_44 (%pattern_type.48c) = pack_expansion_pattern %next.patt.loc6_44.1, %arity.patt.loc6_31.1 [symbolic = %.loc6_31.2 (constants.%.0a4)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc6_15.1: type = splice_block %.loc6_15.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc6_15.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc6_13.2: type = symbolic_binding T, 0 [symbolic = %T.loc6_13.1 (constants.%T)]
// CHECK:STDOUT:     %first.param: @ForEach.%T.loc6_13.1 (%T) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc6_28: type = name_ref T, %T.loc6_13.2 [symbolic = %T.loc6_13.1 (constants.%T)]
// CHECK:STDOUT:     %first: @ForEach.%T.loc6_13.1 (%T) = wrapper_binding first, %first.param
// CHECK:STDOUT:     %arity.loc6_31.2: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc6_31.1 (constants.%arity)]
// CHECK:STDOUT:     %next.param: @ForEach.%pack_type (%pack_type.2fb) = value_param call_param1
// CHECK:STDOUT:     %T.ref.loc6_46: type = name_ref T, %T.loc6_13.2 [symbolic = %T.loc6_13.1 (constants.%T)]
// CHECK:STDOUT:     %next: @ForEach.%pack_type (%pack_type.2fb) = wrapper_binding next, %next.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ForEach(%T.loc6_13.2: type, %arity.loc6_31.2: Core.IntLiteral) {
// CHECK:STDOUT:   %T.patt.loc6_13.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc6_13.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc6_13.1: type = symbolic_binding T, 0 [symbolic = %T.loc6_13.1 (constants.%T)]
// CHECK:STDOUT:   %pattern_type.loc6_26: type = pattern_type %T.loc6_13.1 [symbolic = %pattern_type.loc6_26 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %first.param_patt.loc6_26.2: @ForEach.%pattern_type.loc6_26 (%pattern_type.51d1c4.1) = value_param_pattern [symbolic = %first.param_patt.loc6_26.2 (constants.%first.param_patt.4f2)]
// CHECK:STDOUT:   %first.patt.loc6_26.2: @ForEach.%pattern_type.loc6_26 (%pattern_type.51d1c4.1) = wrapper_binding_pattern first, %first.param_patt.loc6_26.2 [symbolic = %first.patt.loc6_26.2 (constants.%first.patt.2a6)]
// CHECK:STDOUT:   %arity.patt.loc6_31.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc6_31.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc6_31.1: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc6_31.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type %T.loc6_13.1, %arity.loc6_31.1 [symbolic = %pack_type (constants.%pack_type.2fb)]
// CHECK:STDOUT:   %pattern_type.loc6_44: type = pattern_type %pack_type [symbolic = %pattern_type.loc6_44 (constants.%pattern_type.48c)]
// CHECK:STDOUT:   %next.param_patt.loc6_44.2: @ForEach.%pattern_type.loc6_44 (%pattern_type.48c) = value_param_pattern [symbolic = %next.param_patt.loc6_44.2 (constants.%next.param_patt.273)]
// CHECK:STDOUT:   %next.patt.loc6_44.2: @ForEach.%pattern_type.loc6_44 (%pattern_type.48c) = wrapper_binding_pattern next, %next.param_patt.loc6_44.2 [symbolic = %next.patt.loc6_44.2 (constants.%next.patt.893)]
// CHECK:STDOUT:   %.loc6_31.2: @ForEach.%pattern_type.loc6_44 (%pattern_type.48c) = pack_expansion_pattern %next.patt.loc6_44.2, %arity.patt.loc6_31.2 [symbolic = %.loc6_31.2 (constants.%.0a4)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc6_26: <witness> = require_complete_type %T.loc6_13.1 [symbolic = %require_complete.loc6_26 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc6_44: <witness> = require_complete_type %pack_type [symbolic = %require_complete.loc6_44 (constants.%require_complete.d90)]
// CHECK:STDOUT:   %Consume.specific_fn.loc7_3.2: <specific function> = specific_function constants.%Consume, @Consume(%T.loc6_13.1) [symbolic = %Consume.specific_fn.loc7_3.2 (constants.%Consume.specific_fn.86b)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%first.param: @ForEach.%T.loc6_13.1 (%T), %next.param: @ForEach.%pack_type (%pack_type.2fb)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Consume.ref.loc7: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:     %first.ref: @ForEach.%T.loc6_13.1 (%T) = name_ref first, %first
// CHECK:STDOUT:     %Consume.specific_fn.loc7_3.1: <specific function> = specific_function %Consume.ref.loc7, @Consume(constants.%T) [symbolic = %Consume.specific_fn.loc7_3.2 (constants.%Consume.specific_fn.86b)]
// CHECK:STDOUT:     %Consume.call.loc7: init %empty_tuple.type = call %Consume.specific_fn.loc7_3.1(%first.ref)
// CHECK:STDOUT:     pack_expansion_statement %arity.loc6_31.2 {
// CHECK:STDOUT:       %Consume.ref.loc8: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %next.ref: @ForEach.%pack_type (%pack_type.2fb) = name_ref next, %next
// CHECK:STDOUT:       %.loc8_15.1: Core.IntLiteral = pack_index
// CHECK:STDOUT:       %.loc8_15.2: @ForEach.%T.loc6_13.1 (%T) = pack_element %next.ref, %.loc8_15.1
// CHECK:STDOUT:       %Consume.specific_fn.loc8: <specific function> = specific_function %Consume.ref.loc8, @Consume(constants.%T) [symbolic = %Consume.specific_fn.loc7_3.2 (constants.%Consume.specific_fn.86b)]
// CHECK:STDOUT:       %Consume.call.loc8: init %empty_tuple.type = call %Consume.specific_fn.loc8(%.loc8_15.2)
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %ForEach.ref.loc14: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %i64.loc14_16: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0.loc14_13: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc14_13.1: <bound method> = bound_method %int_1, %impl.elem0.loc14_13 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.ab2]
// CHECK:STDOUT:   %specific_fn.loc14_13: <specific function> = specific_function %impl.elem0.loc14_13, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_13.2: <bound method> = bound_method %int_1, %specific_fn.loc14_13 [concrete = constants.%bound_method.991]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc14_13: init %i64 = call %bound_method.loc14_13.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc14_13.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc14_13 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc14_13.2: %i64 = converted %int_1, %.loc14_13.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %int_2.loc14_21: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %i64.loc14_26: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0.loc14_23: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc14_23.1: <bound method> = bound_method %int_2.loc14_21, %impl.elem0.loc14_23 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.d11]
// CHECK:STDOUT:   %specific_fn.loc14_23: <specific function> = specific_function %impl.elem0.loc14_23, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_23.2: <bound method> = bound_method %int_2.loc14_21, %specific_fn.loc14_23 [concrete = constants.%bound_method.b92]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc14_23: init %i64 = call %bound_method.loc14_23.2(%int_2.loc14_21) [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc14_23.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc14_23 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc14_23.2: %i64 = converted %int_2.loc14_21, %.loc14_23.1 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %i64.loc14_36: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0.loc14_33: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc14_33.1: <bound method> = bound_method %int_3, %impl.elem0.loc14_33 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound.eee]
// CHECK:STDOUT:   %specific_fn.loc14_33: <specific function> = specific_function %impl.elem0.loc14_33, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_33.2: <bound method> = bound_method %int_3, %specific_fn.loc14_33 [concrete = constants.%bound_method.2c8]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call.loc14_33: init %i64 = call %bound_method.loc14_33.2(%int_3) [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc14_33.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call.loc14_33 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc14_33.2: %i64 = converted %int_3, %.loc14_33.1 [concrete = constants.%int_3.bd2]
// CHECK:STDOUT:   %.loc14_23.3: %tuple.type = pack_literal (%.loc14_23.2, %.loc14_33.2)
// CHECK:STDOUT:   %int_2.loc14_39.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %int_2.loc14_39.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %ForEach.specific_fn.loc14: <specific function> = specific_function %ForEach.ref.loc14, @ForEach(constants.%i64, constants.%int_2.ecc) [concrete = constants.%ForEach.specific_fn.b11]
// CHECK:STDOUT:   %.loc14_23.4: %pack_type.f7c = pack_value (%.loc14_23.2, %.loc14_33.2)
// CHECK:STDOUT:   %.loc14_23.5: %pack_type.f7c = converted %.loc14_23.3, %.loc14_23.4
// CHECK:STDOUT:   %ForEach.call.loc14: init %empty_tuple.type = call %ForEach.specific_fn.loc14(%.loc14_13.2, %.loc14_23.5)
// CHECK:STDOUT:   %ForEach.ref.loc15: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc15_15.1: %empty_tuple.type = pack_literal ()
// CHECK:STDOUT:   %int_0.loc15_15.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %int_0.loc15_15.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %ForEach.specific_fn.loc15: <specific function> = specific_function %ForEach.ref.loc15, @ForEach(bool, constants.%int_0) [concrete = constants.%ForEach.specific_fn.370]
// CHECK:STDOUT:   %.loc15_15.2: %pack_type.8ed = pack_value ()
// CHECK:STDOUT:   %.loc15_15.3: %pack_type.8ed = converted %.loc15_15.1, %.loc15_15.2
// CHECK:STDOUT:   %ForEach.call.loc15: init %empty_tuple.type = call %ForEach.specific_fn.loc15(%true, %.loc15_15.3)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%T, constants.%arity) {
// CHECK:STDOUT:   %T.patt.loc6_13.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc6_13.1 => constants.%T
// CHECK:STDOUT:   %pattern_type.loc6_26 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %first.param_patt.loc6_26.2 => constants.%first.param_patt.4f2
// CHECK:STDOUT:   %first.patt.loc6_26.2 => constants.%first.patt.2a6
// CHECK:STDOUT:   %arity.patt.loc6_31.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_31.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type.2fb
// CHECK:STDOUT:   %pattern_type.loc6_44 => constants.%pattern_type.48c
// CHECK:STDOUT:   %next.param_patt.loc6_44.2 => constants.%next.param_patt.273
// CHECK:STDOUT:   %next.patt.loc6_44.2 => constants.%next.patt.893
// CHECK:STDOUT:   %.loc6_31.2 => constants.%.0a4
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%i64, constants.%int_2.ecc) {
// CHECK:STDOUT:   %T.patt.loc6_13.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc6_13.1 => constants.%i64
// CHECK:STDOUT:   %pattern_type.loc6_26 => constants.%pattern_type.f57
// CHECK:STDOUT:   %first.param_patt.loc6_26.2 => constants.%first.param_patt.a4b
// CHECK:STDOUT:   %first.patt.loc6_26.2 => constants.%first.patt.4d6
// CHECK:STDOUT:   %arity.patt.loc6_31.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_31.1 => constants.%int_2.ecc
// CHECK:STDOUT:   %pack_type => constants.%pack_type.f7c
// CHECK:STDOUT:   %pattern_type.loc6_44 => constants.%pattern_type.a38
// CHECK:STDOUT:   %next.param_patt.loc6_44.2 => constants.%next.param_patt.c0d
// CHECK:STDOUT:   %next.patt.loc6_44.2 => constants.%next.patt.228
// CHECK:STDOUT:   %.loc6_31.2 => constants.%.87e
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc6_26 => constants.%complete_type.4a1
// CHECK:STDOUT:   %require_complete.loc6_44 => constants.%complete_type.46f
// CHECK:STDOUT:   %Consume.specific_fn.loc7_3.2 => constants.%Consume.specific_fn.e83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(bool, constants.%int_0) {
// CHECK:STDOUT:   %T.patt.loc6_13.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc6_13.1 => bool
// CHECK:STDOUT:   %pattern_type.loc6_26 => constants.%pattern_type.831
// CHECK:STDOUT:   %first.param_patt.loc6_26.2 => constants.%first.param_patt.deb
// CHECK:STDOUT:   %first.patt.loc6_26.2 => constants.%first.patt.06b
// CHECK:STDOUT:   %arity.patt.loc6_31.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_31.1 => constants.%int_0
// CHECK:STDOUT:   %pack_type => constants.%pack_type.8ed
// CHECK:STDOUT:   %pattern_type.loc6_44 => constants.%pattern_type.9b0
// CHECK:STDOUT:   %next.param_patt.loc6_44.2 => constants.%next.param_patt.e27
// CHECK:STDOUT:   %next.patt.loc6_44.2 => constants.%next.patt.f92
// CHECK:STDOUT:   %.loc6_31.2 => constants.%.469
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc6_26 => constants.%complete_type.127
// CHECK:STDOUT:   %require_complete.loc6_44 => constants.%complete_type.db7
// CHECK:STDOUT:   %Consume.specific_fn.loc7_3.2 => constants.%Consume.specific_fn.272
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- method.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %C.ForEach.type: type = fn_type @C.ForEach [concrete]
// CHECK:STDOUT:   %C.ForEach: %C.ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (Core.IntLiteral, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %pack_type.f7c: type = pack_type %i64, %int_2.ecc [concrete]
// CHECK:STDOUT:   %C.ForEach.specific_fn: <specific function> = specific_function %C.ForEach, @C.ForEach(%int_2.ecc) [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5d4: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.c9c: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.405: %i64 = int_value 2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%c.param: %C) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %ForEach.ref: %C.ForEach.type = name_ref ForEach, @C.%C.ForEach.decl [concrete = constants.%C.ForEach]
// CHECK:STDOUT:   %C.ForEach.bound: <bound method> = bound_method %c.ref, %ForEach.ref
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %int_2.loc13_16: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc13_13.1: %tuple.type = pack_literal (%int_1, %int_2.loc13_16)
// CHECK:STDOUT:   %int_2.loc13_17.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %int_2.loc13_17.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %C.ForEach.specific_fn: <specific function> = specific_function %ForEach.ref, @C.ForEach(constants.%int_2.ecc) [concrete = constants.%C.ForEach.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_17: <bound method> = bound_method %c.ref, %C.ForEach.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc13_13: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc13_13.1: <bound method> = bound_method %int_1, %impl.elem0.loc13_13 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.89f]
// CHECK:STDOUT:   %specific_fn.loc13_13: <specific function> = specific_function %impl.elem0.loc13_13, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_13.2: <bound method> = bound_method %int_1, %specific_fn.loc13_13 [concrete = constants.%bound_method.c5e]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_13: init %i64 = call %bound_method.loc13_13.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc13_13.2: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_13 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc13_13.3: %i64 = converted %int_1, %.loc13_13.2 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %impl.elem0.loc13_16: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc13_16.1: <bound method> = bound_method %int_2.loc13_16, %impl.elem0.loc13_16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.5d4]
// CHECK:STDOUT:   %specific_fn.loc13_16: <specific function> = specific_function %impl.elem0.loc13_16, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_16.2: <bound method> = bound_method %int_2.loc13_16, %specific_fn.loc13_16 [concrete = constants.%bound_method.c9c]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_16: init %i64 = call %bound_method.loc13_16.2(%int_2.loc13_16) [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc13_16.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_16 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc13_16.2: %i64 = converted %int_2.loc13_16, %.loc13_16.1 [concrete = constants.%int_2.405]
// CHECK:STDOUT:   %.loc13_13.4: %pack_type.f7c = pack_value (%.loc13_13.3, %.loc13_16.2)
// CHECK:STDOUT:   %.loc13_13.5: %pack_type.f7c = converted %.loc13_13.1, %.loc13_13.4
// CHECK:STDOUT:   %C.ForEach.call: init %empty_tuple.type = call %bound_method.loc13_17(%c.ref, %.loc13_13.5)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- class_element.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.164: type = pack_type %C, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.43f: type = pattern_type %pack_type.164 [symbolic]
// CHECK:STDOUT:   %c.param_patt.d85: %pattern_type.43f = value_param_pattern [symbolic]
// CHECK:STDOUT:   %c.patt.05c: %pattern_type.43f = wrapper_binding_pattern c, %c.param_patt.d85 [symbolic]
// CHECK:STDOUT:   %.c89: %pattern_type.43f = pack_expansion_pattern %c.patt.05c, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.2e6: <witness> = require_complete_type %pack_type.164 [symbolic]
// CHECK:STDOUT:   %tuple.type.748: type = tuple_type (%C, %C) [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.b0a: type = pack_type %C, %int_2 [concrete]
// CHECK:STDOUT:   %pattern_type.6be: type = pattern_type %pack_type.b0a [concrete]
// CHECK:STDOUT:   %c.param_patt.d49: %pattern_type.6be = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt.825: %pattern_type.6be = wrapper_binding_pattern c, %c.param_patt.d49 [concrete]
// CHECK:STDOUT:   %.8f3: %pattern_type.6be = pack_expansion_pattern %c.patt.825, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForEach.specific_fn: <specific function> = specific_function %ForEach, @ForEach(%int_2) [concrete]
// CHECK:STDOUT:   %complete_type.b46: <witness> = complete_type_witness %pack_type.b0a [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ForEach.decl: %ForEach.type = fn_decl @ForEach [concrete = constants.%ForEach] {
// CHECK:STDOUT:     %arity.patt.loc10_12.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %c.param_patt.loc10_22.1: @ForEach.%pattern_type (%pattern_type.43f) = value_param_pattern [symbolic = %c.param_patt.loc10_22.2 (constants.%c.param_patt.d85)]
// CHECK:STDOUT:     %c.patt.loc10_22.1: @ForEach.%pattern_type (%pattern_type.43f) = wrapper_binding_pattern c, %c.param_patt.loc10_22.1 [symbolic = %c.patt.loc10_22.2 (constants.%c.patt.05c)]
// CHECK:STDOUT:     %.loc10_12.1: @ForEach.%pattern_type (%pattern_type.43f) = pack_expansion_pattern %c.patt.loc10_22.1, %arity.patt.loc10_12.1 [symbolic = %.loc10_12.2 (constants.%.c89)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc10_12.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:     %c.param: @ForEach.%pack_type (%pack_type.164) = value_param call_param0
// CHECK:STDOUT:     %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: @ForEach.%pack_type (%pack_type.164) = wrapper_binding c, %c.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ForEach(%arity.loc10_12.2: Core.IntLiteral) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc10_12.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type constants.%C, %arity.loc10_12.1 [symbolic = %pack_type (constants.%pack_type.164)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type [symbolic = %pattern_type (constants.%pattern_type.43f)]
// CHECK:STDOUT:   %c.param_patt.loc10_22.2: @ForEach.%pattern_type (%pattern_type.43f) = value_param_pattern [symbolic = %c.param_patt.loc10_22.2 (constants.%c.param_patt.d85)]
// CHECK:STDOUT:   %c.patt.loc10_22.2: @ForEach.%pattern_type (%pattern_type.43f) = wrapper_binding_pattern c, %c.param_patt.loc10_22.2 [symbolic = %c.patt.loc10_22.2 (constants.%c.patt.05c)]
// CHECK:STDOUT:   %.loc10_12.2: @ForEach.%pattern_type (%pattern_type.43f) = pack_expansion_pattern %c.patt.loc10_22.2, %arity.patt.loc10_12.2 [symbolic = %.loc10_12.2 (constants.%.c89)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type [symbolic = %require_complete (constants.%require_complete.2e6)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%c.param: @ForEach.%pack_type (%pack_type.164)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc10_12.2 {
// CHECK:STDOUT:       %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %c.ref: @ForEach.%pack_type (%pack_type.164) = name_ref c, %c
// CHECK:STDOUT:       %.loc11_15.1: Core.IntLiteral = pack_index
// CHECK:STDOUT:       %.loc11_15.2: %C = pack_element %c.ref, %.loc11_15.1
// CHECK:STDOUT:       %Consume.call: init %empty_tuple.type = call %Consume.ref(%.loc11_15.2)
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%c.param: %C, %d.param: %C) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %ForEach.ref: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %d.ref: %C = name_ref d, %d
// CHECK:STDOUT:   %.loc17_11.1: %tuple.type.748 = pack_literal (%c.ref, %d.ref)
// CHECK:STDOUT:   %int_2.loc17_15.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %int_2.loc17_15.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %ForEach.specific_fn: <specific function> = specific_function %ForEach.ref, @ForEach(constants.%int_2) [concrete = constants.%ForEach.specific_fn]
// CHECK:STDOUT:   %.loc17_11.2: %pack_type.b0a = pack_value (%c.ref, %d.ref)
// CHECK:STDOUT:   %.loc17_11.3: %pack_type.b0a = converted %.loc17_11.1, %.loc17_11.2
// CHECK:STDOUT:   %ForEach.call: init %empty_tuple.type = call %ForEach.specific_fn(%.loc17_11.3)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%arity) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_12.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type.164
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.43f
// CHECK:STDOUT:   %c.param_patt.loc10_22.2 => constants.%c.param_patt.d85
// CHECK:STDOUT:   %c.patt.loc10_22.2 => constants.%c.patt.05c
// CHECK:STDOUT:   %.loc10_12.2 => constants.%.c89
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%int_2) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_12.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type => constants.%pack_type.b0a
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6be
// CHECK:STDOUT:   %c.param_patt.loc10_22.2 => constants.%c.param_patt.d49
// CHECK:STDOUT:   %c.patt.loc10_22.2 => constants.%c.patt.825
// CHECK:STDOUT:   %.loc10_12.2 => constants.%.8f3
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.b46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic_caller.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %U.patt: %pattern_type.9a5 = symbolic_binding_pattern U, 0 [symbolic]
// CHECK:STDOUT:   %U: type = symbolic_binding U, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.2: type = pattern_type %U [symbolic]
// CHECK:STDOUT:   %a.param_patt: %pattern_type.51d1c4.2 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %a.patt: %pattern_type.51d1c4.2 = wrapper_binding_pattern a, %a.param_patt [symbolic]
// CHECK:STDOUT:   %Twice.type: type = fn_type @Twice [concrete]
// CHECK:STDOUT:   %Twice: %Twice.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.2: <witness> = require_complete_type %U [symbolic]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%U, %U) [symbolic]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.fbf: type = pack_type %U, %int_2 [symbolic]
// CHECK:STDOUT:   %ForEach.specific_fn: <specific function> = specific_function %ForEach, @ForEach(%U, %int_2) [symbolic]
// CHECK:STDOUT:   %require_complete.4a8: <witness> = require_complete_type %pack_type.fbf [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Twice.decl: %Twice.type = fn_decl @Twice [concrete = constants.%Twice] {
// CHECK:STDOUT:     %U.patt.loc10_11.1: %pattern_type.9a5 = symbolic_binding_pattern U, 0 [symbolic = %U.patt.loc10_11.2 (constants.%U.patt)]
// CHECK:STDOUT:     %a.param_patt.loc10_20.1: @Twice.%pattern_type (%pattern_type.51d1c4.2) = value_param_pattern [symbolic = %a.param_patt.loc10_20.2 (constants.%a.param_patt)]
// CHECK:STDOUT:     %a.patt.loc10_20.1: @Twice.%pattern_type (%pattern_type.51d1c4.2) = wrapper_binding_pattern a, %a.param_patt.loc10_20.1 [symbolic = %a.patt.loc10_20.2 (constants.%a.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_13.1: type = splice_block %.loc10_13.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc10_13.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %U.loc10_11.2: type = symbolic_binding U, 0 [symbolic = %U.loc10_11.1 (constants.%U)]
// CHECK:STDOUT:     %a.param: @Twice.%U.loc10_11.1 (%U) = value_param call_param0
// CHECK:STDOUT:     %U.ref: type = name_ref U, %U.loc10_11.2 [symbolic = %U.loc10_11.1 (constants.%U)]
// CHECK:STDOUT:     %a: @Twice.%U.loc10_11.1 (%U) = wrapper_binding a, %a.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Twice(%U.loc10_11.2: type) {
// CHECK:STDOUT:   %U.patt.loc10_11.2: %pattern_type.9a5 = symbolic_binding_pattern U, 0 [symbolic = %U.patt.loc10_11.2 (constants.%U.patt)]
// CHECK:STDOUT:   %U.loc10_11.1: type = symbolic_binding U, 0 [symbolic = %U.loc10_11.1 (constants.%U)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %U.loc10_11.1 [symbolic = %pattern_type (constants.%pattern_type.51d1c4.2)]
// CHECK:STDOUT:   %a.param_patt.loc10_20.2: @Twice.%pattern_type (%pattern_type.51d1c4.2) = value_param_pattern [symbolic = %a.param_patt.loc10_20.2 (constants.%a.param_patt)]
// CHECK:STDOUT:   %a.patt.loc10_20.2: @Twice.%pattern_type (%pattern_type.51d1c4.2) = wrapper_binding_pattern a, %a.param_patt.loc10_20.2 [symbolic = %a.patt.loc10_20.2 (constants.%a.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10: <witness> = require_complete_type %U.loc10_11.1 [symbolic = %require_complete.loc10 (constants.%require_complete.9443dd.2)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%U.loc10_11.1, %U.loc10_11.1) [symbolic = %tuple.type (constants.%tuple.type)]
// CHECK:STDOUT:   %ForEach.specific_fn.loc11_3.2: <specific function> = specific_function constants.%ForEach, @ForEach(%U.loc10_11.1, constants.%int_2) [symbolic = %ForEach.specific_fn.loc11_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:   %pack_type: type = pack_type %U.loc10_11.1, constants.%int_2 [symbolic = %pack_type (constants.%pack_type.fbf)]
// CHECK:STDOUT:   %require_complete.loc11: <witness> = require_complete_type %pack_type [symbolic = %require_complete.loc11 (constants.%require_complete.4a8)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%a.param: @Twice.%U.loc10_11.1 (%U)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %ForEach.ref: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:     %a.ref.loc11_11: @Twice.%U.loc10_11.1 (%U) = name_ref a, %a
// CHECK:STDOUT:     %a.ref.loc11_14: @Twice.%U.loc10_11.1 (%U) = name_ref a, %a
// CHECK:STDOUT:     %.loc11_11.1: @Twice.%tuple.type (%tuple.type) = pack_literal (%a.ref.loc11_11, %a.ref.loc11_14)
// CHECK:STDOUT:     %int_2.loc11_15.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:     %int_2.loc11_15.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:     %ForEach.specific_fn.loc11_3.1: <specific function> = specific_function %ForEach.ref, @ForEach(constants.%U, constants.%int_2) [symbolic = %ForEach.specific_fn.loc11_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:     %.loc11_11.2: @Twice.%pack_type (%pack_type.fbf) = pack_value (%a.ref.loc11_11, %a.ref.loc11_14)
// CHECK:STDOUT:     %.loc11_11.3: @Twice.%pack_type (%pack_type.fbf) = converted %.loc11_11.1, %.loc11_11.2
// CHECK:STDOUT:     %ForEach.call: init %empty_tuple.type = call %ForEach.specific_fn.loc11_3.1(%.loc11_11.3)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Twice(constants.%U) {
// CHECK:STDOUT:   %U.patt.loc10_11.2 => constants.%U.patt
// CHECK:STDOUT:   %U.loc10_11.1 => constants.%U
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.2
// CHECK:STDOUT:   %a.param_patt.loc10_20.2 => constants.%a.param_patt
// CHECK:STDOUT:   %a.patt.loc10_20.2 => constants.%a.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
