// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/forward.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/forward.carbon

// --- forward.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

//@dump-sem-ir-begin
fn Forward(... each m: i64) {
  ForEach(... each m);
}
//@dump-sem-ir-end

fn Call() {
  Forward(1, 2);
}

// --- forward_expression.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);
fn Double(x: i64) -> i64;

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

//@dump-sem-ir-begin
fn ForwardDoubled(... each m: i64) {
  ForEach(... Double(each m));
}
//@dump-sem-ir-end

// --- forward_fixed.carbon
library "[[@TEST_NAME]]";

fn Middle(unused first: i64, ... unused each mid: i64, unused last: i64) {}

//@dump-sem-ir-begin
fn Outer(... each x: i64) {
  Middle(0, ... each x, 9);
}
//@dump-sem-ir-end

// --- forward_generic.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](unused x: T) {}

fn ForEach[T: type](... each x: T) {
  ... Consume(each x);
}

//@dump-sem-ir-begin
fn Forward[T: type](... each x: T) {
  ForEach(... each x);
}
//@dump-sem-ir-end

// --- forward_converted.carbon
library "[[@TEST_NAME]]";

class Wrap {
  var n: i64;
}

impl Wrap as Core.ImplicitAs(i64) {
  fn Convert(self) -> i64 { return self.n; }
}

fn ForEach(... unused each n: i64) {}

//@dump-sem-ir-begin
fn Unwrap(... each w: Wrap) {
  ForEach(... each w);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- forward.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.5d5: type = pack_type %i64, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.b58: type = pattern_type %pack_type.5d5 [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.241: <witness> = require_complete_type %pack_type.5d5 [symbolic]
// CHECK:STDOUT:   %m.param_patt.e27: %pattern_type.b58 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %m.patt.223: %pattern_type.b58 = wrapper_binding_pattern m, %m.param_patt.e27 [symbolic]
// CHECK:STDOUT:   %.1db: %pattern_type.b58 = pack_expansion_pattern %m.patt.223, %arity.patt [symbolic]
// CHECK:STDOUT:   %Forward.type: type = fn_type @Forward [concrete]
// CHECK:STDOUT:   %Forward: %Forward.type = struct_value () [concrete]
// CHECK:STDOUT:   %ForEach.specific_fn.6ad: <specific function> = specific_function %ForEach, @ForEach(%arity) [symbolic]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.f7c: type = pack_type %i64, %int_2.ecc [concrete]
// CHECK:STDOUT:   %pattern_type.a38: type = pattern_type %pack_type.f7c [concrete]
// CHECK:STDOUT:   %m.param_patt.832: %pattern_type.a38 = value_param_pattern [concrete]
// CHECK:STDOUT:   %m.patt.c26: %pattern_type.a38 = wrapper_binding_pattern m, %m.param_patt.832 [concrete]
// CHECK:STDOUT:   %.f76: %pattern_type.a38 = pack_expansion_pattern %m.patt.c26, %arity.patt [symbolic]
// CHECK:STDOUT:   %complete_type.46f: <witness> = complete_type_witness %pack_type.f7c [concrete]
// CHECK:STDOUT:   %ForEach.specific_fn.f93: <specific function> = specific_function %ForEach, @ForEach(%int_2.ecc) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Forward.decl: %Forward.type = fn_decl @Forward [concrete = constants.%Forward] {
// CHECK:STDOUT:     %arity.patt.loc10_12.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %m.param_patt.loc10_22.1: @Forward.%pattern_type (%pattern_type.b58) = value_param_pattern [symbolic = %m.param_patt.loc10_22.2 (constants.%m.param_patt.e27)]
// CHECK:STDOUT:     %m.patt.loc10_22.1: @Forward.%pattern_type (%pattern_type.b58) = wrapper_binding_pattern m, %m.param_patt.loc10_22.1 [symbolic = %m.patt.loc10_22.2 (constants.%m.patt.223)]
// CHECK:STDOUT:     %.loc10_12.1: @Forward.%pattern_type (%pattern_type.b58) = pack_expansion_pattern %m.patt.loc10_22.1, %arity.patt.loc10_12.1 [symbolic = %.loc10_12.2 (constants.%.1db)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc10_12.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:     %m.param: @Forward.%pack_type (%pack_type.5d5) = value_param call_param0
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %m: @Forward.%pack_type (%pack_type.5d5) = wrapper_binding m, %m.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Forward(%arity.loc10_12.2: Core.IntLiteral) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc10_12.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type constants.%i64, %arity.loc10_12.1 [symbolic = %pack_type (constants.%pack_type.5d5)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type [symbolic = %pattern_type (constants.%pattern_type.b58)]
// CHECK:STDOUT:   %m.param_patt.loc10_22.2: @Forward.%pattern_type (%pattern_type.b58) = value_param_pattern [symbolic = %m.param_patt.loc10_22.2 (constants.%m.param_patt.e27)]
// CHECK:STDOUT:   %m.patt.loc10_22.2: @Forward.%pattern_type (%pattern_type.b58) = wrapper_binding_pattern m, %m.param_patt.loc10_22.2 [symbolic = %m.patt.loc10_22.2 (constants.%m.patt.223)]
// CHECK:STDOUT:   %.loc10_12.2: @Forward.%pattern_type (%pattern_type.b58) = pack_expansion_pattern %m.patt.loc10_22.2, %arity.patt.loc10_12.2 [symbolic = %.loc10_12.2 (constants.%.1db)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type [symbolic = %require_complete (constants.%require_complete.241)]
// CHECK:STDOUT:   %ForEach.specific_fn.loc11_3.2: <specific function> = specific_function constants.%ForEach, @ForEach(%arity.loc10_12.1) [symbolic = %ForEach.specific_fn.loc11_3.2 (constants.%ForEach.specific_fn.6ad)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%m.param: @Forward.%pack_type (%pack_type.5d5)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %ForEach.ref: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:     %.loc11_11: @Forward.%pack_type (%pack_type.5d5) = pack_expansion_expr %.loc11_15.2 {
// CHECK:STDOUT:       %m.ref: @Forward.%pack_type (%pack_type.5d5) = name_ref m, %m
// CHECK:STDOUT:       %.loc11_15.1: Core.IntLiteral = pack_index
// CHECK:STDOUT:       %.loc11_15.2: %i64 = pack_element %m.ref, %.loc11_15.1
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %ForEach.specific_fn.loc11_3.1: <specific function> = specific_function %ForEach.ref, @ForEach(constants.%arity) [symbolic = %ForEach.specific_fn.loc11_3.2 (constants.%ForEach.specific_fn.6ad)]
// CHECK:STDOUT:     %ForEach.call: init %empty_tuple.type = call %ForEach.specific_fn.loc11_3.1(%.loc11_11)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Forward(constants.%arity) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_12.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type.5d5
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.b58
// CHECK:STDOUT:   %m.param_patt.loc10_22.2 => constants.%m.param_patt.e27
// CHECK:STDOUT:   %m.patt.loc10_22.2 => constants.%m.patt.223
// CHECK:STDOUT:   %.loc10_12.2 => constants.%.1db
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Forward(constants.%int_2.ecc) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_12.1 => constants.%int_2.ecc
// CHECK:STDOUT:   %pack_type => constants.%pack_type.f7c
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.a38
// CHECK:STDOUT:   %m.param_patt.loc10_22.2 => constants.%m.param_patt.832
// CHECK:STDOUT:   %m.patt.loc10_22.2 => constants.%m.patt.c26
// CHECK:STDOUT:   %.loc10_12.2 => constants.%.f76
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.46f
// CHECK:STDOUT:   %ForEach.specific_fn.loc11_3.2 => constants.%ForEach.specific_fn.f93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- forward_expression.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Double.type: type = fn_type @Double [concrete]
// CHECK:STDOUT:   %Double: %Double.type = struct_value () [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type: type = pack_type %i64, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.b58: type = pattern_type %pack_type [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.241: <witness> = require_complete_type %pack_type [symbolic]
// CHECK:STDOUT:   %m.param_patt: %pattern_type.b58 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %m.patt: %pattern_type.b58 = wrapper_binding_pattern m, %m.param_patt [symbolic]
// CHECK:STDOUT:   %.1db: %pattern_type.b58 = pack_expansion_pattern %m.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForwardDoubled.type: type = fn_type @ForwardDoubled [concrete]
// CHECK:STDOUT:   %ForwardDoubled: %ForwardDoubled.type = struct_value () [concrete]
// CHECK:STDOUT:   %ForEach.specific_fn: <specific function> = specific_function %ForEach, @ForEach(%arity) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ForwardDoubled.decl: %ForwardDoubled.type = fn_decl @ForwardDoubled [concrete = constants.%ForwardDoubled] {
// CHECK:STDOUT:     %arity.patt.loc11_19.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc11_19.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %m.param_patt.loc11_29.1: @ForwardDoubled.%pattern_type (%pattern_type.b58) = value_param_pattern [symbolic = %m.param_patt.loc11_29.2 (constants.%m.param_patt)]
// CHECK:STDOUT:     %m.patt.loc11_29.1: @ForwardDoubled.%pattern_type (%pattern_type.b58) = wrapper_binding_pattern m, %m.param_patt.loc11_29.1 [symbolic = %m.patt.loc11_29.2 (constants.%m.patt)]
// CHECK:STDOUT:     %.loc11_19.1: @ForwardDoubled.%pattern_type (%pattern_type.b58) = pack_expansion_pattern %m.patt.loc11_29.1, %arity.patt.loc11_19.1 [symbolic = %.loc11_19.2 (constants.%.1db)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc11_19.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc11_19.1 (constants.%arity)]
// CHECK:STDOUT:     %m.param: @ForwardDoubled.%pack_type (%pack_type) = value_param call_param0
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %m: @ForwardDoubled.%pack_type (%pack_type) = wrapper_binding m, %m.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ForwardDoubled(%arity.loc11_19.2: Core.IntLiteral) {
// CHECK:STDOUT:   %arity.patt.loc11_19.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc11_19.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc11_19.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc11_19.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type constants.%i64, %arity.loc11_19.1 [symbolic = %pack_type (constants.%pack_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type [symbolic = %pattern_type (constants.%pattern_type.b58)]
// CHECK:STDOUT:   %m.param_patt.loc11_29.2: @ForwardDoubled.%pattern_type (%pattern_type.b58) = value_param_pattern [symbolic = %m.param_patt.loc11_29.2 (constants.%m.param_patt)]
// CHECK:STDOUT:   %m.patt.loc11_29.2: @ForwardDoubled.%pattern_type (%pattern_type.b58) = wrapper_binding_pattern m, %m.param_patt.loc11_29.2 [symbolic = %m.patt.loc11_29.2 (constants.%m.patt)]
// CHECK:STDOUT:   %.loc11_19.2: @ForwardDoubled.%pattern_type (%pattern_type.b58) = pack_expansion_pattern %m.patt.loc11_29.2, %arity.patt.loc11_19.2 [symbolic = %.loc11_19.2 (constants.%.1db)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type [symbolic = %require_complete (constants.%require_complete.241)]
// CHECK:STDOUT:   %ForEach.specific_fn.loc12_3.2: <specific function> = specific_function constants.%ForEach, @ForEach(%arity.loc11_19.1) [symbolic = %ForEach.specific_fn.loc12_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%m.param: @ForwardDoubled.%pack_type (%pack_type)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %ForEach.ref: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:     %.loc12_11: @ForwardDoubled.%pack_type (%pack_type) = pack_expansion_expr %.loc12_28.2 {
// CHECK:STDOUT:       %Double.ref: %Double.type = name_ref Double, file.%Double.decl [concrete = constants.%Double]
// CHECK:STDOUT:       %m.ref: @ForwardDoubled.%pack_type (%pack_type) = name_ref m, %m
// CHECK:STDOUT:       %.loc12_22.1: Core.IntLiteral = pack_index
// CHECK:STDOUT:       %.loc12_22.2: %i64 = pack_element %m.ref, %.loc12_22.1
// CHECK:STDOUT:       %Double.call: init %i64 = call %Double.ref(%.loc12_22.2)
// CHECK:STDOUT:       %.loc12_28.1: %i64 = value_of_initializer %Double.call
// CHECK:STDOUT:       %.loc12_28.2: %i64 = converted %Double.call, %.loc12_28.1
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %ForEach.specific_fn.loc12_3.1: <specific function> = specific_function %ForEach.ref, @ForEach(constants.%arity) [symbolic = %ForEach.specific_fn.loc12_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:     %ForEach.call: init %empty_tuple.type = call %ForEach.specific_fn.loc12_3.1(%.loc12_11)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForwardDoubled(constants.%arity) {
// CHECK:STDOUT:   %arity.patt.loc11_19.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc11_19.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.b58
// CHECK:STDOUT:   %m.param_patt.loc11_29.2 => constants.%m.param_patt
// CHECK:STDOUT:   %m.patt.loc11_29.2 => constants.%m.patt
// CHECK:STDOUT:   %.loc11_19.2 => constants.%.1db
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- forward_fixed.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type: type = pack_type %i64, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.b58: type = pattern_type %pack_type [symbolic]
// CHECK:STDOUT:   %Middle.type: type = fn_type @Middle [concrete]
// CHECK:STDOUT:   %Middle: %Middle.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.241: <witness> = require_complete_type %pack_type [symbolic]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.b58 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt: %pattern_type.b58 = wrapper_binding_pattern x, %x.param_patt [symbolic]
// CHECK:STDOUT:   %.d3b: %pattern_type.b58 = pack_expansion_pattern %x.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %Outer.type: type = fn_type @Outer [concrete]
// CHECK:STDOUT:   %Outer: %Outer.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %int_9.988: Core.IntLiteral = int_value 9 [concrete]
// CHECK:STDOUT:   %Middle.specific_fn: <specific function> = specific_function %Middle, @Middle(%arity) [symbolic]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.173: <bound method> = bound_method %int_9.988, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.b74: <bound method> = bound_method %int_9.988, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_9.458: %i64 = int_value 9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Outer.decl: %Outer.type = fn_decl @Outer [concrete = constants.%Outer] {
// CHECK:STDOUT:     %arity.patt.loc6_10.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_10.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %x.param_patt.loc6_20.1: @Outer.%pattern_type (%pattern_type.b58) = value_param_pattern [symbolic = %x.param_patt.loc6_20.2 (constants.%x.param_patt)]
// CHECK:STDOUT:     %x.patt.loc6_20.1: @Outer.%pattern_type (%pattern_type.b58) = wrapper_binding_pattern x, %x.param_patt.loc6_20.1 [symbolic = %x.patt.loc6_20.2 (constants.%x.patt)]
// CHECK:STDOUT:     %.loc6_10.1: @Outer.%pattern_type (%pattern_type.b58) = pack_expansion_pattern %x.patt.loc6_20.1, %arity.patt.loc6_10.1 [symbolic = %.loc6_10.2 (constants.%.d3b)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc6_10.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_10.1 (constants.%arity)]
// CHECK:STDOUT:     %x.param: @Outer.%pack_type (%pack_type) = value_param call_param0
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %x: @Outer.%pack_type (%pack_type) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Outer(%arity.loc6_10.2: Core.IntLiteral) {
// CHECK:STDOUT:   %arity.patt.loc6_10.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc6_10.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc6_10.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc6_10.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type constants.%i64, %arity.loc6_10.1 [symbolic = %pack_type (constants.%pack_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type [symbolic = %pattern_type (constants.%pattern_type.b58)]
// CHECK:STDOUT:   %x.param_patt.loc6_20.2: @Outer.%pattern_type (%pattern_type.b58) = value_param_pattern [symbolic = %x.param_patt.loc6_20.2 (constants.%x.param_patt)]
// CHECK:STDOUT:   %x.patt.loc6_20.2: @Outer.%pattern_type (%pattern_type.b58) = wrapper_binding_pattern x, %x.param_patt.loc6_20.2 [symbolic = %x.patt.loc6_20.2 (constants.%x.patt)]
// CHECK:STDOUT:   %.loc6_10.2: @Outer.%pattern_type (%pattern_type.b58) = pack_expansion_pattern %x.patt.loc6_20.2, %arity.patt.loc6_10.2 [symbolic = %.loc6_10.2 (constants.%.d3b)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type [symbolic = %require_complete (constants.%require_complete.241)]
// CHECK:STDOUT:   %Middle.specific_fn.loc7_3.2: <specific function> = specific_function constants.%Middle, @Middle(%arity.loc6_10.1) [symbolic = %Middle.specific_fn.loc7_3.2 (constants.%Middle.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @Outer.%pack_type (%pack_type)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Middle.ref: %Middle.type = name_ref Middle, file.%Middle.decl [concrete = constants.%Middle]
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %.loc7_13: @Outer.%pack_type (%pack_type) = pack_expansion_expr %.loc7_17.2 {
// CHECK:STDOUT:       %x.ref: @Outer.%pack_type (%pack_type) = name_ref x, %x
// CHECK:STDOUT:       %.loc7_17.1: Core.IntLiteral = pack_index
// CHECK:STDOUT:       %.loc7_17.2: %i64 = pack_element %x.ref, %.loc7_17.1
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_9: Core.IntLiteral = int_value 9 [concrete = constants.%int_9.988]
// CHECK:STDOUT:     %Middle.specific_fn.loc7_3.1: <specific function> = specific_function %Middle.ref, @Middle(constants.%arity) [symbolic = %Middle.specific_fn.loc7_3.2 (constants.%Middle.specific_fn)]
// CHECK:STDOUT:     %impl.elem0.loc7_10: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc7_10.1: <bound method> = bound_method %int_0, %impl.elem0.loc7_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:     %specific_fn.loc7_10: <specific function> = specific_function %impl.elem0.loc7_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc7_10.2: <bound method> = bound_method %int_0, %specific_fn.loc7_10 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7_10: init %i64 = call %bound_method.loc7_10.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc7_10.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7_10 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc7_10.2: %i64 = converted %int_0, %.loc7_10.1 [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %impl.elem0.loc7_25: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc7_25.1: <bound method> = bound_method %int_9, %impl.elem0.loc7_25 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.173]
// CHECK:STDOUT:     %specific_fn.loc7_25: <specific function> = specific_function %impl.elem0.loc7_25, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc7_25.2: <bound method> = bound_method %int_9, %specific_fn.loc7_25 [concrete = constants.%bound_method.b74]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7_25: init %i64 = call %bound_method.loc7_25.2(%int_9) [concrete = constants.%int_9.458]
// CHECK:STDOUT:     %.loc7_25.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc7_25 [concrete = constants.%int_9.458]
// CHECK:STDOUT:     %.loc7_25.2: %i64 = converted %int_9, %.loc7_25.1 [concrete = constants.%int_9.458]
// CHECK:STDOUT:     %Middle.call: init %empty_tuple.type = call %Middle.specific_fn.loc7_3.1(%.loc7_10.2, %.loc7_13, %.loc7_25.2)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Outer(constants.%arity) {
// CHECK:STDOUT:   %arity.patt.loc6_10.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc6_10.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.b58
// CHECK:STDOUT:   %x.param_patt.loc6_20.2 => constants.%x.param_patt
// CHECK:STDOUT:   %x.patt.loc6_20.2 => constants.%x.patt
// CHECK:STDOUT:   %.loc6_10.2 => constants.%.d3b
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- forward_generic.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %pack_type: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.48c: type = pattern_type %pack_type [symbolic]
// CHECK:STDOUT:   %x.param_patt.21b: %pattern_type.48c = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.313: %pattern_type.48c = wrapper_binding_pattern x, %x.param_patt.21b [symbolic]
// CHECK:STDOUT:   %.2cf: %pattern_type.48c = pack_expansion_pattern %x.patt.313, %arity.patt [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.d90: <witness> = require_complete_type %pack_type [symbolic]
// CHECK:STDOUT:   %Forward.type: type = fn_type @Forward [concrete]
// CHECK:STDOUT:   %Forward: %Forward.type = struct_value () [concrete]
// CHECK:STDOUT:   %ForEach.specific_fn: <specific function> = specific_function %ForEach, @ForEach(%T, %arity) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Forward.decl: %Forward.type = fn_decl @Forward [concrete = constants.%Forward] {
// CHECK:STDOUT:     %T.patt.loc10_13.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc10_13.2 (constants.%T.patt)]
// CHECK:STDOUT:     %arity.patt.loc10_21.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc10_21.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %x.param_patt.loc10_31.1: @Forward.%pattern_type (%pattern_type.48c) = value_param_pattern [symbolic = %x.param_patt.loc10_31.2 (constants.%x.param_patt.21b)]
// CHECK:STDOUT:     %x.patt.loc10_31.1: @Forward.%pattern_type (%pattern_type.48c) = wrapper_binding_pattern x, %x.param_patt.loc10_31.1 [symbolic = %x.patt.loc10_31.2 (constants.%x.patt.313)]
// CHECK:STDOUT:     %.loc10_21.1: @Forward.%pattern_type (%pattern_type.48c) = pack_expansion_pattern %x.patt.loc10_31.1, %arity.patt.loc10_21.1 [symbolic = %.loc10_21.2 (constants.%.2cf)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_15.1: type = splice_block %.loc10_15.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc10_15.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_13.2: type = symbolic_binding T, 0 [symbolic = %T.loc10_13.1 (constants.%T)]
// CHECK:STDOUT:     %arity.loc10_21.2: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc10_21.1 (constants.%arity)]
// CHECK:STDOUT:     %x.param: @Forward.%pack_type (%pack_type) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc10_13.2 [symbolic = %T.loc10_13.1 (constants.%T)]
// CHECK:STDOUT:     %x: @Forward.%pack_type (%pack_type) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Forward(%T.loc10_13.2: type, %arity.loc10_21.2: Core.IntLiteral) {
// CHECK:STDOUT:   %T.patt.loc10_13.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc10_13.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc10_13.1: type = symbolic_binding T, 0 [symbolic = %T.loc10_13.1 (constants.%T)]
// CHECK:STDOUT:   %arity.patt.loc10_21.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc10_21.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc10_21.1: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc10_21.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type: type = pack_type %T.loc10_13.1, %arity.loc10_21.1 [symbolic = %pack_type (constants.%pack_type)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type [symbolic = %pattern_type (constants.%pattern_type.48c)]
// CHECK:STDOUT:   %x.param_patt.loc10_31.2: @Forward.%pattern_type (%pattern_type.48c) = value_param_pattern [symbolic = %x.param_patt.loc10_31.2 (constants.%x.param_patt.21b)]
// CHECK:STDOUT:   %x.patt.loc10_31.2: @Forward.%pattern_type (%pattern_type.48c) = wrapper_binding_pattern x, %x.param_patt.loc10_31.2 [symbolic = %x.patt.loc10_31.2 (constants.%x.patt.313)]
// CHECK:STDOUT:   %.loc10_21.2: @Forward.%pattern_type (%pattern_type.48c) = pack_expansion_pattern %x.patt.loc10_31.2, %arity.patt.loc10_21.2 [symbolic = %.loc10_21.2 (constants.%.2cf)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type [symbolic = %require_complete (constants.%require_complete.d90)]
// CHECK:STDOUT:   %ForEach.specific_fn.loc11_3.2: <specific function> = specific_function constants.%ForEach, @ForEach(%T.loc10_13.1, %arity.loc10_21.1) [symbolic = %ForEach.specific_fn.loc11_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @Forward.%pack_type (%pack_type)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %ForEach.ref: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:     %.loc11_11: @Forward.%pack_type (%pack_type) = pack_expansion_expr %.loc11_15.2 {
// CHECK:STDOUT:       %x.ref: @Forward.%pack_type (%pack_type) = name_ref x, %x
// CHECK:STDOUT:       %.loc11_15.1: Core.IntLiteral = pack_index
// CHECK:STDOUT:       %.loc11_15.2: @Forward.%T.loc10_13.1 (%T) = pack_element %x.ref, %.loc11_15.1
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %ForEach.specific_fn.loc11_3.1: <specific function> = specific_function %ForEach.ref, @ForEach(constants.%T, constants.%arity) [symbolic = %ForEach.specific_fn.loc11_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:     %ForEach.call: init %empty_tuple.type = call %ForEach.specific_fn.loc11_3.1(%.loc11_11)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Forward(constants.%T, constants.%arity) {
// CHECK:STDOUT:   %T.patt.loc10_13.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc10_13.1 => constants.%T
// CHECK:STDOUT:   %arity.patt.loc10_21.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_21.1 => constants.%arity
// CHECK:STDOUT:   %pack_type => constants.%pack_type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.48c
// CHECK:STDOUT:   %x.param_patt.loc10_31.2 => constants.%x.param_patt.21b
// CHECK:STDOUT:   %x.patt.loc10_31.2 => constants.%x.patt.313
// CHECK:STDOUT:   %.loc10_21.2 => constants.%.2cf
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- forward_converted.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Wrap: type = class_type @Wrap [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.85a: <witness> = impl_witness @Wrap.as.ImplicitAs.impl.%ImplicitAs.impl_witness_table [concrete]
// CHECK:STDOUT:   %Wrap.as.ImplicitAs.impl.Convert.type: type = fn_type @Wrap.as.ImplicitAs.impl.Convert [concrete]
// CHECK:STDOUT:   %Wrap.as.ImplicitAs.impl.Convert: %Wrap.as.ImplicitAs.impl.Convert.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.221 = facet_value %Wrap, (%ImplicitAs.impl_witness.85a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.235: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.5d5: type = pack_type %i64, %arity [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.241: <witness> = require_complete_type %pack_type.5d5 [symbolic]
// CHECK:STDOUT:   %pack_type.761: type = pack_type %Wrap, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.106: type = pattern_type %pack_type.761 [symbolic]
// CHECK:STDOUT:   %w.param_patt: %pattern_type.106 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %w.patt: %pattern_type.106 = wrapper_binding_pattern w, %w.param_patt [symbolic]
// CHECK:STDOUT:   %.6c4: %pattern_type.106 = pack_expansion_pattern %w.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %Unwrap.type: type = fn_type @Unwrap [concrete]
// CHECK:STDOUT:   %Unwrap: %Unwrap.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.139: <witness> = require_complete_type %pack_type.761 [symbolic]
// CHECK:STDOUT:   %ForEach.specific_fn: <specific function> = specific_function %ForEach, @ForEach(%arity) [symbolic]
// CHECK:STDOUT:   %.c3d: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.235, %ImplicitAs.facet [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Unwrap.decl: %Unwrap.type = fn_decl @Unwrap [concrete = constants.%Unwrap] {
// CHECK:STDOUT:     %arity.patt.loc14_11.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc14_11.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %w.param_patt.loc14_21.1: @Unwrap.%pattern_type (%pattern_type.106) = value_param_pattern [symbolic = %w.param_patt.loc14_21.2 (constants.%w.param_patt)]
// CHECK:STDOUT:     %w.patt.loc14_21.1: @Unwrap.%pattern_type (%pattern_type.106) = wrapper_binding_pattern w, %w.param_patt.loc14_21.1 [symbolic = %w.patt.loc14_21.2 (constants.%w.patt)]
// CHECK:STDOUT:     %.loc14_11.1: @Unwrap.%pattern_type (%pattern_type.106) = pack_expansion_pattern %w.patt.loc14_21.1, %arity.patt.loc14_11.1 [symbolic = %.loc14_11.2 (constants.%.6c4)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc14_11.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc14_11.1 (constants.%arity)]
// CHECK:STDOUT:     %w.param: @Unwrap.%pack_type.loc14 (%pack_type.761) = value_param call_param0
// CHECK:STDOUT:     %Wrap.ref: type = name_ref Wrap, file.%Wrap.decl [concrete = constants.%Wrap]
// CHECK:STDOUT:     %w: @Unwrap.%pack_type.loc14 (%pack_type.761) = wrapper_binding w, %w.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Unwrap(%arity.loc14_11.2: Core.IntLiteral) {
// CHECK:STDOUT:   %arity.patt.loc14_11.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc14_11.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc14_11.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc14_11.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc14: type = pack_type constants.%Wrap, %arity.loc14_11.1 [symbolic = %pack_type.loc14 (constants.%pack_type.761)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type.loc14 [symbolic = %pattern_type (constants.%pattern_type.106)]
// CHECK:STDOUT:   %w.param_patt.loc14_21.2: @Unwrap.%pattern_type (%pattern_type.106) = value_param_pattern [symbolic = %w.param_patt.loc14_21.2 (constants.%w.param_patt)]
// CHECK:STDOUT:   %w.patt.loc14_21.2: @Unwrap.%pattern_type (%pattern_type.106) = wrapper_binding_pattern w, %w.param_patt.loc14_21.2 [symbolic = %w.patt.loc14_21.2 (constants.%w.patt)]
// CHECK:STDOUT:   %.loc14_11.2: @Unwrap.%pattern_type (%pattern_type.106) = pack_expansion_pattern %w.patt.loc14_21.2, %arity.patt.loc14_11.2 [symbolic = %.loc14_11.2 (constants.%.6c4)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc14: <witness> = require_complete_type %pack_type.loc14 [symbolic = %require_complete.loc14 (constants.%require_complete.139)]
// CHECK:STDOUT:   %ForEach.specific_fn.loc15_3.2: <specific function> = specific_function constants.%ForEach, @ForEach(%arity.loc14_11.1) [symbolic = %ForEach.specific_fn.loc15_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:   %pack_type.loc15: type = pack_type constants.%i64, %arity.loc14_11.1 [symbolic = %pack_type.loc15 (constants.%pack_type.5d5)]
// CHECK:STDOUT:   %require_complete.loc15: <witness> = require_complete_type %pack_type.loc15 [symbolic = %require_complete.loc15 (constants.%require_complete.241)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%w.param: @Unwrap.%pack_type.loc14 (%pack_type.761)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %ForEach.ref: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:     %.loc15_11.1: @Unwrap.%pack_type.loc14 (%pack_type.761) = pack_expansion_expr %.loc15_15.2 {
// CHECK:STDOUT:       %w.ref: @Unwrap.%pack_type.loc14 (%pack_type.761) = name_ref w, %w
// CHECK:STDOUT:       %.loc15_15.1: Core.IntLiteral = pack_index
// CHECK:STDOUT:       %.loc15_15.2: %Wrap = pack_element %w.ref, %.loc15_15.1
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %ForEach.specific_fn.loc15_3.1: <specific function> = specific_function %ForEach.ref, @ForEach(constants.%arity) [symbolic = %ForEach.specific_fn.loc15_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:     %.loc15_11.2: @Unwrap.%pack_type.loc15 (%pack_type.5d5) = pack_expansion_expr %.loc15_11.7 {
// CHECK:STDOUT:       %.loc15_11.4: Core.IntLiteral = pack_index
// CHECK:STDOUT:       %.loc15_11.5: %Wrap = pack_element %.loc15_11.1, %.loc15_11.4
// CHECK:STDOUT:       %impl.elem0: %.c3d = impl_witness_access constants.%ImplicitAs.impl_witness.85a, element0 [concrete = constants.%Wrap.as.ImplicitAs.impl.Convert]
// CHECK:STDOUT:       %bound_method: <bound method> = bound_method %.loc15_11.5, %impl.elem0
// CHECK:STDOUT:       %Wrap.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method(%.loc15_11.5)
// CHECK:STDOUT:       %.loc15_11.6: %i64 = value_of_initializer %Wrap.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:       %.loc15_11.7: %i64 = converted %.loc15_11.5, %.loc15_11.6
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc15_11.3: @Unwrap.%pack_type.loc15 (%pack_type.5d5) = converted %.loc15_11.1, %.loc15_11.2
// CHECK:STDOUT:     %ForEach.call: init %empty_tuple.type = call %ForEach.specific_fn.loc15_3.1(%.loc15_11.3)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Unwrap(constants.%arity) {
// CHECK:STDOUT:   %arity.patt.loc14_11.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc14_11.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc14 => constants.%pack_type.761
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.106
// CHECK:STDOUT:   %w.param_patt.loc14_21.2 => constants.%w.param_patt
// CHECK:STDOUT:   %w.patt.loc14_21.2 => constants.%w.patt
// CHECK:STDOUT:   %.loc14_11.2 => constants.%.6c4
// CHECK:STDOUT: }
// CHECK:STDOUT:
