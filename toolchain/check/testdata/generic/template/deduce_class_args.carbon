// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/deduce_class_args.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/deduce_class_args.carbon

// --- holder.carbon
library "[[@TEST_NAME]]";

class Holder(T: type) {
  var item: T;
}

//@dump-sem-ir-begin
fn GetTemplate[template T: type](h: Holder(T)) -> T {
  return h.item;
}
//@dump-sem-ir-end

fn Use(h: Holder(i32)) -> i32 {
  return GetTemplate(h);
}

// --- holder_copy_constraint.carbon
library "[[@TEST_NAME]]";

class Holder(T: Core.Copy) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Use(h: Holder(i32)) -> i32 {
  return Get(h);
}

// --- holder_pointer.carbon
library "[[@TEST_NAME]]";

class Holder(T: type) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)*) -> T {
  return h->item;
}

fn Use(h: Holder(i32)*) -> i32 {
  return Get(h);
}

// --- vec_value_param.carbon
library "[[@TEST_NAME]]";

class Vec(template N: i32) {
  var a: i32;
}

fn Size[template N: i32](unused v: Vec(N)) -> i32 {
  return N;
}

fn Use(v: Vec(3)) -> i32 {
  return Size(v);
}

// --- template_class_type.carbon
library "[[@TEST_NAME]]";

class Holder(template T: type) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Use(h: Holder(i32)) -> i32 {
  return Get(h);
}

// --- class_argument_expression.carbon
library "[[@TEST_NAME]]";

class Vec(N: i32) {
  var tag: i32;
}

fn Size(template N: i32, v: Vec(N + 1)) -> i32 {
  return N + v.tag;
}

fn Use(v: Vec(4)) -> i32 {
  return Size(3, v);
}

// --- class_argument_return_type.carbon
library "[[@TEST_NAME]]";

class Vec(N: i32) {
  var tag: i32;
}

fn Make(template M: Core.IntLiteral) -> Vec(M) {
  return {.tag = 1};
}

fn Use() -> Vec(3) {
  return Make(3);
}

// --- class_template_literal_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Make(template N: i32, x: i32) -> i32 {
  var c: Arr(N) = {.a = (x, 2, 3), .n = N};
  return c.n;
}

fn Use() -> i32 {
  return Make(3, 1);
}

// --- class_template_return_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Make(template N: i32) -> Arr(N) {
  return {.a = (4, 5, 6), .n = N};
}

fn Use() -> Arr(3) {
  return Make(3);
}

// --- fail_class_template_literal_with_dependent_array_bound_count_on_instantiation.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Make(template N: i32) -> i32 {
  var c: Arr(N) = {.a = (1, 2), .n = N};
  return c.n;
}

fn Use() -> i32 {
  // CHECK:STDERR: fail_class_template_literal_with_dependent_array_bound_count_on_instantiation.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `Make(3)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Make(3);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_class_template_literal_with_dependent_array_bound_count_on_instantiation.carbon:[[@LINE-8]]:25: note: cannot initialize array of 3 elements from 2 initializers [ArrayInitFromLiteralArgCountMismatch]
  // CHECK:STDERR:   var c: Arr(N) = {.a = (1, 2), .n = N};
  // CHECK:STDERR:                         ^~~~~~
  // CHECK:STDERR:
  return Make(3);
}

// --- fail_class_template_literal_with_dependent_array_bound_unknown_field.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Make(template N: i32) -> i32 {
  // CHECK:STDERR: fail_class_template_literal_with_dependent_array_bound_unknown_field.carbon:[[@LINE+4]]:19: error: struct `Arr(N)` has no field named `m` [StructInitUnexpectedFieldInLiteral]
  // CHECK:STDERR:   var c: Arr(N) = {.a = (1, 2, 3), .m = N};
  // CHECK:STDERR:                   ^~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  var c: Arr(N) = {.a = (1, 2, 3), .m = N};
  return c.n;
}

// --- class_template_literal_with_associated_field_default_on_instantiation.carbon
library "[[@TEST_NAME]]";

interface HasItem {
  let Item: type;
}

class Holder {
  impl as HasItem where .Item = i32 {}
}

class Box(template T: HasItem) {
  var item: T.Item;
  var n: i32 = 5;
}

fn Make[template T: HasItem](unused x: T) -> i32 {
  var b: Box(T) = {.item = 4};
  return b.n;
}

fn Use(h: Holder) -> i32 {
  return Make(h);
}

// --- class_template_value_with_associated_field_default_on_instantiation.carbon
library "[[@TEST_NAME]]";

interface HasItem {
  let Item: type;
}

class Holder {
  impl as HasItem where .Item = i32 {}
}

class Box(template T: HasItem) {
  var item: T.Item;
  var n: i32 = 5;
}

fn Make[template T: HasItem](unused x: T) -> i32 {
  let b: Box(T) = {.item = 4};
  return b.n;
}

fn Use(h: Holder) -> i32 {
  return Make(h);
}

// --- class_template_literal_with_produced_field_default_on_instantiation.carbon
library "[[@TEST_NAME]]";

class D(template N: i32) {
  var a: i32;
  var k: i32 = N + 1;
}

fn Make(template N: i32) -> i32 {
  var d: D(N) = {.a = 4};
  return d.a + d.k;
}

fn Use() -> i32 {
  return Make(3);
}

// --- class_template_value_with_produced_field_default_on_instantiation.carbon
library "[[@TEST_NAME]]";

class D(template N: i32) {
  var a: i32;
  var k: i32 = N + 1;
}

fn Make(template N: i32) -> i32 {
  let d: D(N) = {.a = 4};
  return d.a + d.k;
}

fn Use() -> i32 {
  return Make(3);
}

// --- class_template_concrete_value_with_produced_field_default.carbon
library "[[@TEST_NAME]]";

class D(template N: i32) {
  var a: i32;
  var k: i32 = N + 1;
}

fn Make(template N: i32) -> i32 {
  let d: D(3) = {.a = N};
  return d.a + d.k;
}

fn Use() -> i32 {
  return Make(5);
}

// --- class_template_value_with_parameter_field_default.carbon
library "[[@TEST_NAME]]";

class D(template N: i32) {
  var a: i32;
  var k: i32 = N;
}

fn Make(template N: i32) -> i32 {
  let d: D(N) = {.a = 4};
  return d.a + d.k;
}

fn Use() -> i32 {
  return Make(3);
}

// --- class_template_literal_with_type_parameter_field_default_on_instantiation.carbon
library "[[@TEST_NAME]]";

class D(template T: type) {
  var a: i32;
  var k: T = 7;
}

fn Make(template T: type) -> i32 {
  var d: D(T) = {.a = 4};
  return d.a + d.k;
}

fn Use() -> i32 {
  return Make(i32);
}

// --- class_template_value_with_type_parameter_field_default_on_instantiation.carbon
library "[[@TEST_NAME]]";

class D(template T: type) {
  var a: i32;
  var k: T = 7;
}

fn Make(template T: type) -> i32 {
  let d: D(T) = {.a = 4};
  return d.a + d.k;
}

fn Use() -> i32 {
  return Make(i32);
}

// --- class_template_method_literal_with_produced_field_default.carbon
library "[[@TEST_NAME]]";

class D(template N: i32) {
  var a: i32;
  var k: i32 = N + 1;

  fn Make() -> Self {
    return {.a = 4};
  }
}

fn Use() -> i32 {
  var d: D(3) = D(3).Make();
  return d.a + d.k;
}

// --- fail_checked_generic_calls_template_with_class_template_literal.carbon
library "[[@TEST_NAME]]";

class D(template N: i32) {
  var a: i32;
  var k: i32 = N + 1;
}

fn Make(template N: i32) -> i32 {
  var d: D(N) = {.a = 4};
  return d.a + d.k;
}

fn H(generic M: i32) -> i32 {
  // CHECK:STDERR: fail_checked_generic_calls_template_with_class_template_literal.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `Make(M)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Make(M);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_checked_generic_calls_template_with_class_template_literal.carbon:[[@LINE-12]]:16: note: value of type `<bound method>` is not callable [CallToNonCallable]
  // CHECK:STDERR:   var k: i32 = N + 1;
  // CHECK:STDERR:                ^~~~~
  // CHECK:STDERR:
  return Make(M);
}

// --- fail_checked_generic_calls_template_with_class_template_value.carbon
library "[[@TEST_NAME]]";

class D(template N: i32) {
  var a: i32;
  var k: i32 = N + 1;
}

fn Make(template N: i32) -> i32 {
  let d: D(N) = {.a = 4};
  return d.a + d.k;
}

fn H(generic M: i32) -> i32 {
  // CHECK:STDERR: fail_checked_generic_calls_template_with_class_template_value.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `Make(M)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Make(M);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_checked_generic_calls_template_with_class_template_value.carbon:[[@LINE-12]]:16: note: value of type `<bound method>` is not callable [CallToNonCallable]
  // CHECK:STDERR:   var k: i32 = N + 1;
  // CHECK:STDERR:                ^~~~~
  // CHECK:STDERR:
  return Make(M);
}

// --- fail_checked_generic_calls_template_with_class_template_runtime_literal.carbon
library "[[@TEST_NAME]]";

class D(template N: i32) {
  var a: i32;
  var k: i32 = N + 1;
}

fn Make(template N: i32, x: i32) -> i32 {
  var d: D(N) = {.a = x};
  return d.a + d.k;
}

fn H(generic M: i32, x: i32) -> i32 {
  // CHECK:STDERR: fail_checked_generic_calls_template_with_class_template_runtime_literal.carbon:[[@LINE+7]]:10: error: unable to monomorphize specific `Make(M)` [ResolvingSpecificHere]
  // CHECK:STDERR:   return Make(M, x);
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR: fail_checked_generic_calls_template_with_class_template_runtime_literal.carbon:[[@LINE-12]]:16: note: value of type `<bound method>` is not callable [CallToNonCallable]
  // CHECK:STDERR:   var k: i32 = N + 1;
  // CHECK:STDERR:                ^~~~~
  // CHECK:STDERR:
  return Make(M, x);
}

// --- class_template_field_of_where_alias.carbon
library "[[@TEST_NAME]]";

interface HasItem {
  let Item: type;
}

class Holder {
  impl as HasItem where .Item = i32 {}
}

class Tag(U: type) {
  var x: i32;
}

class D(template T: HasItem) {
  alias FT = HasItem where .Item = T.Item;
  var c: Tag({.a: FT});
  var k: i32;
}

fn G() -> i32 {
  var d: D(Holder) = {.c = {.x = 1}, .k = 2};
  return d.c.x + d.k;
}

// CHECK:STDOUT: --- holder.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %Holder.type: type = generic_class_type @Holder [concrete]
// CHECK:STDOUT:   %Holder.generic: %Holder.type = struct_value () [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.2: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %Holder.6169eb.2: type = class_type @Holder, @Holder(%T.67db0b.2) [template]
// CHECK:STDOUT:   %pattern_type.673: type = pattern_type %Holder.6169eb.2 [template]
// CHECK:STDOUT:   %h.param_patt.99d: %pattern_type.673 = value_param_pattern [template]
// CHECK:STDOUT:   %h.patt.fe8: %pattern_type.673 = wrapper_binding_pattern h, %h.param_patt.99d [template]
// CHECK:STDOUT:   %.184: Core.Form = init_form %T.67db0b.2 [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.2: type = pattern_type %T.67db0b.2 [template]
// CHECK:STDOUT:   %return.param_patt.41d: %pattern_type.51d1c4.2 = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.b39: %pattern_type.51d1c4.2 = return_slot_pattern %return.param_patt.41d, %T.67db0b.2 [template]
// CHECK:STDOUT:   %GetTemplate.type: type = fn_type @GetTemplate [concrete]
// CHECK:STDOUT:   %GetTemplate: %GetTemplate.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.2: <witness> = require_complete_type %T.67db0b.2 [template]
// CHECK:STDOUT:   %require_complete.775: <witness> = require_complete_type %Holder.6169eb.2 [template]
// CHECK:STDOUT:   %.1d9: type = type_of_inst @GetTemplate.%.loc9_11.3 [template]
// CHECK:STDOUT:   %.1f3: %.1d9 = splice_inst @GetTemplate.%.loc9_11.3 [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.38e: %T.67db0b.2 = splice_inst @GetTemplate.%tuple.elem0 [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Holder.cdf: type = class_type @Holder, @Holder(%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.4aa: type = pattern_type %Holder.cdf [concrete]
// CHECK:STDOUT:   %h.param_patt.cbc: %pattern_type.4aa = value_param_pattern [concrete]
// CHECK:STDOUT:   %h.patt.5f9: %pattern_type.4aa = wrapper_binding_pattern h, %h.param_patt.cbc [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %Holder.elem.339: type = unbound_element_type %Holder.cdf, %i32 [concrete]
// CHECK:STDOUT:   %struct_type.item.47f: type = struct_type {.item: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.a69: <witness> = complete_type_witness %struct_type.item.47f [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.884: %i32 = splice_block %.f82 {
// CHECK:STDOUT:       %.aa5: %Holder.cdf = specific_inst @GetTemplate.%h.ref, @GetTemplate(%i32)
// CHECK:STDOUT:       %item.ref: %Holder.elem.339 = name_ref item, @Holder.%field_decl [concrete = @Holder.%field_decl]
// CHECK:STDOUT:       %.004: ref %i32 = class_element_access %.aa5, element0
// CHECK:STDOUT:       %.f82: %i32 = acquire_value %.004
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.85d: init %i32 = splice_block %Int.as.Copy.impl.Op.call {
// CHECK:STDOUT:       %impl.elem0.882: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.e67: <bound method> = bound_method %.884, %impl.elem0.882
// CHECK:STDOUT:       %specific_fn: <specific function> = specific_function %impl.elem0.882, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.5f8: <bound method> = bound_method %.884, %specific_fn
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.5f8(%.884)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.242: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.2) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %GetTemplate.decl: %GetTemplate.type = fn_decl @GetTemplate [concrete = constants.%GetTemplate] {
// CHECK:STDOUT:     %T.patt.loc8_26.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc8_26.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:     %h.param_patt.loc8_35.1: @GetTemplate.%pattern_type.loc8_35 (%pattern_type.673) = value_param_pattern [template = %h.param_patt.loc8_35.2 (constants.%h.param_patt.99d)]
// CHECK:STDOUT:     %h.patt.loc8_35.1: @GetTemplate.%pattern_type.loc8_35 (%pattern_type.673) = wrapper_binding_pattern h, %h.param_patt.loc8_35.1 [template = %h.patt.loc8_35.2 (constants.%h.patt.fe8)]
// CHECK:STDOUT:     %return.param_patt.loc8_51.1: @GetTemplate.%pattern_type.loc8_51 (%pattern_type.51d1c4.2) = out_param_pattern [template = %return.param_patt.loc8_51.2 (constants.%return.param_patt.41d)]
// CHECK:STDOUT:     %return.patt.loc8_48.1: @GetTemplate.%pattern_type.loc8_51 (%pattern_type.51d1c4.2) = return_slot_pattern %return.param_patt.loc8_51.1, %T.ref.loc8_51 [template = %return.patt.loc8_48.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc8_51: type = name_ref T, %T.loc8_26.2 [template = %T.loc8_26.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %.loc8_51.2: Core.Form = init_form %T.ref.loc8_51 [template = %.loc8_51.1 (constants.%.184)]
// CHECK:STDOUT:     %.loc8_28.1: type = splice_block %.loc8_28.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc8_28.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc8_26.2: type = symbolic_binding T, 0, template [template = %T.loc8_26.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %h.param: @GetTemplate.%Holder.loc8_45.1 (%Holder.6169eb.2) = value_param call_param0
// CHECK:STDOUT:     %.loc8_45: type = splice_block %Holder.loc8_45.2 [template = %Holder.loc8_45.1 (constants.%Holder.6169eb.2)] {
// CHECK:STDOUT:       %Holder.ref: %Holder.type = name_ref Holder, file.%Holder.decl [concrete = constants.%Holder.generic]
// CHECK:STDOUT:       %T.ref.loc8_44: type = name_ref T, %T.loc8_26.2 [template = %T.loc8_26.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:       %Holder.loc8_45.2: type = class_type @Holder, @Holder(constants.%T.67db0b.2) [template = %Holder.loc8_45.1 (constants.%Holder.6169eb.2)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %h: @GetTemplate.%Holder.loc8_45.1 (%Holder.6169eb.2) = wrapper_binding h, %h.param
// CHECK:STDOUT:     %return.param: ref @GetTemplate.%T.loc8_26.1 (%T.67db0b.2) = out_param call_param1
// CHECK:STDOUT:     %return: ref @GetTemplate.%T.loc8_26.1 (%T.67db0b.2) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @GetTemplate(%T.loc8_26.2: type) {
// CHECK:STDOUT:   %T.patt.loc8_26.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc8_26.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:   %T.loc8_26.1: type = symbolic_binding T, 0, template [template = %T.loc8_26.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:   %Holder.loc8_45.1: type = class_type @Holder, @Holder(%T.loc8_26.1) [template = %Holder.loc8_45.1 (constants.%Holder.6169eb.2)]
// CHECK:STDOUT:   %pattern_type.loc8_35: type = pattern_type %Holder.loc8_45.1 [template = %pattern_type.loc8_35 (constants.%pattern_type.673)]
// CHECK:STDOUT:   %h.param_patt.loc8_35.2: @GetTemplate.%pattern_type.loc8_35 (%pattern_type.673) = value_param_pattern [template = %h.param_patt.loc8_35.2 (constants.%h.param_patt.99d)]
// CHECK:STDOUT:   %h.patt.loc8_35.2: @GetTemplate.%pattern_type.loc8_35 (%pattern_type.673) = wrapper_binding_pattern h, %h.param_patt.loc8_35.2 [template = %h.patt.loc8_35.2 (constants.%h.patt.fe8)]
// CHECK:STDOUT:   %.loc8_51.1: Core.Form = init_form %T.loc8_26.1 [template = %.loc8_51.1 (constants.%.184)]
// CHECK:STDOUT:   %pattern_type.loc8_51: type = pattern_type %T.loc8_26.1 [template = %pattern_type.loc8_51 (constants.%pattern_type.51d1c4.2)]
// CHECK:STDOUT:   %return.param_patt.loc8_51.2: @GetTemplate.%pattern_type.loc8_51 (%pattern_type.51d1c4.2) = out_param_pattern [template = %return.param_patt.loc8_51.2 (constants.%return.param_patt.41d)]
// CHECK:STDOUT:   %return.patt.loc8_48.2: @GetTemplate.%pattern_type.loc8_51 (%pattern_type.51d1c4.2) = return_slot_pattern %return.param_patt.loc8_51.2, %T.loc8_26.1 [template = %return.patt.loc8_48.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8: <witness> = require_complete_type %Holder.loc8_45.1 [template = %require_complete.loc8 (constants.%require_complete.775)]
// CHECK:STDOUT:   %.loc9_11.3: <instruction> = access_member_action %h.ref, item [template]
// CHECK:STDOUT:   %.loc9_11.4: type = type_of_inst %.loc9_11.3 [template = %.loc9_11.4 (constants.%.1d9)]
// CHECK:STDOUT:   %.loc9_11.5: @GetTemplate.%.loc9_11.4 (%.1d9) = splice_inst %.loc9_11.3 [template = %.loc9_11.5 (constants.%.1f3)]
// CHECK:STDOUT:   %require_complete.loc9: <witness> = require_complete_type %T.loc8_26.1 [template = %require_complete.loc9 (constants.%require_complete.9443dd.2)]
// CHECK:STDOUT:   %.loc9_16.2: %tuple.type.f7a = initialize_action %.loc9_11.2, %T.loc8_26.1, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc9_16.2, element0 [template]
// CHECK:STDOUT:   %.loc9_16.3: @GetTemplate.%T.loc8_26.1 (%T.67db0b.2) = splice_inst %tuple.elem0 [template = %.loc9_16.3 (constants.%.38e)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%h.param: @GetTemplate.%Holder.loc8_45.1 (%Holder.6169eb.2)) -> out %return.param: @GetTemplate.%T.loc8_26.1 (%T.67db0b.2) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %h.ref: @GetTemplate.%Holder.loc8_45.1 (%Holder.6169eb.2) = name_ref h, %h
// CHECK:STDOUT:     %.loc9_11.1: type = type_of_inst %.loc9_11.3 [template = %.loc9_11.4 (constants.%.1d9)]
// CHECK:STDOUT:     %.loc9_11.2: @GetTemplate.%.loc9_11.4 (%.1d9) = splice_inst %.loc9_11.3 [template = %.loc9_11.5 (constants.%.1f3)]
// CHECK:STDOUT:     %.loc9_16.1: @GetTemplate.%T.loc8_26.1 (%T.67db0b.2) = splice_inst %tuple.elem0 [template = %.loc9_16.3 (constants.%.38e)]
// CHECK:STDOUT:     return %.loc9_16.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @GetTemplate(constants.%T.67db0b.2) {
// CHECK:STDOUT:   %T.patt.loc8_26.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc8_26.1 => constants.%T.67db0b.2
// CHECK:STDOUT:   %Holder.loc8_45.1 => constants.%Holder.6169eb.2
// CHECK:STDOUT:   %pattern_type.loc8_35 => constants.%pattern_type.673
// CHECK:STDOUT:   %h.param_patt.loc8_35.2 => constants.%h.param_patt.99d
// CHECK:STDOUT:   %h.patt.loc8_35.2 => constants.%h.patt.fe8
// CHECK:STDOUT:   %.loc8_51.1 => constants.%.184
// CHECK:STDOUT:   %pattern_type.loc8_51 => constants.%pattern_type.51d1c4.2
// CHECK:STDOUT:   %return.param_patt.loc8_51.2 => constants.%return.param_patt.41d
// CHECK:STDOUT:   %return.patt.loc8_48.2 => constants.%return.patt.b39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @GetTemplate(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc8_26.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc8_26.1 => constants.%i32
// CHECK:STDOUT:   %Holder.loc8_45.1 => constants.%Holder.cdf
// CHECK:STDOUT:   %pattern_type.loc8_35 => constants.%pattern_type.4aa
// CHECK:STDOUT:   %h.param_patt.loc8_35.2 => constants.%h.param_patt.cbc
// CHECK:STDOUT:   %h.patt.loc8_35.2 => constants.%h.patt.5f9
// CHECK:STDOUT:   %.loc8_51.1 => constants.%.795
// CHECK:STDOUT:   %pattern_type.loc8_51 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %return.param_patt.loc8_51.2 => constants.%return.param_patt.a9a
// CHECK:STDOUT:   %return.patt.loc8_48.2 => constants.%return.patt.e1b
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8 => constants.%complete_type.a69
// CHECK:STDOUT:   %.loc9_11.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc9_11.4 => constants.%i32
// CHECK:STDOUT:   %.loc9_11.5 => <not constant>
// CHECK:STDOUT:   %require_complete.loc9 => constants.%complete_type.f8a
// CHECK:STDOUT:   %.loc9_16.2 => constants.%tuple.242
// CHECK:STDOUT:   %tuple.elem0 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc9_16.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
