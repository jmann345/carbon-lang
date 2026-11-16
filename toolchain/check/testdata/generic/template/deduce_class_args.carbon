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

// --- fail_todo_holder.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Holder(T)` is a deferred `call_action`, and a
// template parameter is not deduced through it (fork work item W-396).

class Holder(T: type) {
  var item: T;
}

//@dump-sem-ir-begin
fn GetTemplate[template T: type](h: Holder(T)) -> T {
  return h.item;
}
//@dump-sem-ir-end

fn Use(h: Holder(i32)) -> i32 {
  // CHECK:STDERR: fail_todo_holder.carbon:[[@LINE+7]]:10: error: cannot deduce value for generic parameter `T` [DeductionIncomplete]
  // CHECK:STDERR:   return GetTemplate(h);
  // CHECK:STDERR:          ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_todo_holder.carbon:[[@LINE-9]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn GetTemplate[template T: type](h: Holder(T)) -> T {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return GetTemplate(h);
}

// --- fail_todo_holder_copy_constraint.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_holder (W-396).

class Holder(T: Core.Copy) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Use(h: Holder(i32)) -> i32 {
  // CHECK:STDERR: fail_todo_holder_copy_constraint.carbon:[[@LINE+7]]:10: error: cannot deduce value for generic parameter `T` [DeductionIncomplete]
  // CHECK:STDERR:   return Get(h);
  // CHECK:STDERR:          ^~~~~~
  // CHECK:STDERR: fail_todo_holder_copy_constraint.carbon:[[@LINE-8]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn Get[template T: type](h: Holder(T)) -> T {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Get(h);
}

// --- fail_todo_holder_pointer.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_holder (W-396).

class Holder(T: type) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)*) -> T {
  return h->item;
}

fn Use(h: Holder(i32)*) -> i32 {
  // CHECK:STDERR: fail_todo_holder_pointer.carbon:[[@LINE+7]]:10: error: cannot deduce value for generic parameter `T` [DeductionIncomplete]
  // CHECK:STDERR:   return Get(h);
  // CHECK:STDERR:          ^~~~~~
  // CHECK:STDERR: fail_todo_holder_pointer.carbon:[[@LINE-8]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn Get[template T: type](h: Holder(T)*) -> T {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Get(h);
}

// --- fail_todo_vec_value_param.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_holder, for a value parameter (W-396).

class Vec(template N: i32) {
  var a: i32;
}

fn Size[template N: i32](unused v: Vec(N)) -> i32 {
  return N;
}

fn Use(v: Vec(3)) -> i32 {
  // CHECK:STDERR: fail_todo_vec_value_param.carbon:[[@LINE+7]]:10: error: cannot deduce value for generic parameter `N` [DeductionIncomplete]
  // CHECK:STDERR:   return Size(v);
  // CHECK:STDERR:          ^~~~~~~
  // CHECK:STDERR: fail_todo_vec_value_param.carbon:[[@LINE-8]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn Size[template N: i32](unused v: Vec(N)) -> i32 {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Size(v);
}

// --- fail_todo_template_class_type.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_holder, for a class template (W-396).

class Holder(template T: type) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Use(h: Holder(i32)) -> i32 {
  // CHECK:STDERR: fail_todo_template_class_type.carbon:[[@LINE+7]]:10: error: cannot deduce value for generic parameter `T` [DeductionIncomplete]
  // CHECK:STDERR:   return Get(h);
  // CHECK:STDERR:          ^~~~~~
  // CHECK:STDERR: fail_todo_template_class_type.carbon:[[@LINE-8]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
  // CHECK:STDERR: fn Get[template T: type](h: Holder(T)) -> T {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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

// --- todo_fail_class_template_literal_with_dependent_array_bound_unknown_field.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Arr(N)` is a deferred `call_action`, so the
// literal's unknown field is diagnosed only on instantiation, which this
// split never makes (fork work item W-398).

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Make(template N: i32) -> i32 {
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

// --- fail_todo_impl_forall_formed_self.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Box(T)` in the impl's self is a deferred
// `call_action`, so the template binding is reported unused and the impl is
// not found for `Box(i32)` (fork work item W-400).

class Box(T: type) {
  var item: T;
}

interface I {
  fn Val(self) -> i32;
}

// CHECK:STDERR: fail_todo_impl_forall_formed_self.carbon:[[@LINE+4]]:13: error: `impl` with unused generic binding [ImplUnusedBinding]
// CHECK:STDERR: impl forall [template T: type] Box(T) as I {
// CHECK:STDERR:             ^~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
impl forall [template T: type] Box(T) as I {
  // CHECK:STDERR: fail_todo_impl_forall_formed_self.carbon:[[@LINE+4]]:10: warning: binding `self` unused [UnusedBinding]
  // CHECK:STDERR:   fn Val(self) -> i32 { return 11; }
  // CHECK:STDERR:          ^~~~
  // CHECK:STDERR:
  fn Val(self) -> i32 { return 11; }
}

fn Use(h: Box(i32)) -> i32 {
  // CHECK:STDERR: fail_todo_impl_forall_formed_self.carbon:[[@LINE+4]]:10: error: cannot access member of interface `I` in type `Box(i32)` that does not implement that interface [MissingImplInMemberAccess]
  // CHECK:STDERR:   return h.(I.Val)();
  // CHECK:STDERR:          ^~~~~~~~~
  // CHECK:STDERR:
  return h.(I.Val)();
}

// CHECK:STDOUT: --- fail_todo_holder.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %Holder.type: type = generic_class_type @Holder [concrete]
// CHECK:STDOUT:   %Holder.generic: %Holder.type = struct_value () [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.2: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %.58f: type = type_of_inst @GetTemplate.%.loc10_45.1 [template]
// CHECK:STDOUT:   %.572: %.58f = splice_inst @GetTemplate.%.loc10_45.1 [template]
// CHECK:STDOUT:   %.5372ba.1: type = splice_inst @GetTemplate.%.loc10_45.4 [template]
// CHECK:STDOUT:   %pattern_type.fcb8f3.1: type = pattern_type %.5372ba.1 [template]
// CHECK:STDOUT:   %h.param_patt.e4c369.1: %pattern_type.fcb8f3.1 = value_param_pattern [template]
// CHECK:STDOUT:   %h.patt.d66407.1: %pattern_type.fcb8f3.1 = wrapper_binding_pattern h, %h.param_patt.e4c369.1 [template]
// CHECK:STDOUT:   %.184: Core.Form = init_form %T.67db0b.2 [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.2: type = pattern_type %T.67db0b.2 [template]
// CHECK:STDOUT:   %return.param_patt.41d: %pattern_type.51d1c4.2 = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.b39: %pattern_type.51d1c4.2 = return_slot_pattern %return.param_patt.41d, %T.67db0b.2 [template]
// CHECK:STDOUT:   %.f23: <instruction> = call_action (%Holder.generic, %T.67db0b.2), false [template]
// CHECK:STDOUT:   %.033: type = type_of_inst %.f23 [template]
// CHECK:STDOUT:   %.9ac: %.033 = splice_inst %.f23 [template]
// CHECK:STDOUT:   %.c8c: <instruction> = convert_to_value_action %.9ac, type [template]
// CHECK:STDOUT:   %.5372ba.2: type = splice_inst %.c8c [template]
// CHECK:STDOUT:   %pattern_type.fcb8f3.2: type = pattern_type %.5372ba.2 [template]
// CHECK:STDOUT:   %h.param_patt.e4c369.2: %pattern_type.fcb8f3.2 = value_param_pattern [template]
// CHECK:STDOUT:   %h.patt.d66407.2: %pattern_type.fcb8f3.2 = wrapper_binding_pattern h, %h.param_patt.e4c369.2 [template]
// CHECK:STDOUT:   %GetTemplate.type: type = fn_type @GetTemplate [concrete]
// CHECK:STDOUT:   %GetTemplate: %GetTemplate.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.cb0: <witness> = require_complete_type %.5372ba.1 [template]
// CHECK:STDOUT:   %require_complete.9443dd.2: <witness> = require_complete_type %T.67db0b.2 [template]
// CHECK:STDOUT:   %.1d9: type = type_of_inst @GetTemplate.%.loc11_11.3 [template]
// CHECK:STDOUT:   %.1f3: %.1d9 = splice_inst @GetTemplate.%.loc11_11.3 [template]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.38e: %T.67db0b.2 = splice_inst @GetTemplate.%tuple.elem0 [template]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %GetTemplate.decl: %GetTemplate.type = fn_decl @GetTemplate [concrete = constants.%GetTemplate] {
// CHECK:STDOUT:     %T.patt.loc10_26.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc10_26.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:     %h.param_patt.loc10_35.1: @GetTemplate.%pattern_type.loc10_35 (%pattern_type.fcb8f3.1) = value_param_pattern [template = %h.param_patt.loc10_35.2 (constants.%h.param_patt.e4c369.1)]
// CHECK:STDOUT:     %h.patt.loc10_35.1: @GetTemplate.%pattern_type.loc10_35 (%pattern_type.fcb8f3.1) = wrapper_binding_pattern h, %h.param_patt.loc10_35.1 [template = %h.patt.loc10_35.2 (constants.%h.patt.d66407.1)]
// CHECK:STDOUT:     %return.param_patt.loc10_51.1: @GetTemplate.%pattern_type.loc10_51 (%pattern_type.51d1c4.2) = out_param_pattern [template = %return.param_patt.loc10_51.2 (constants.%return.param_patt.41d)]
// CHECK:STDOUT:     %return.patt.loc10_48.1: @GetTemplate.%pattern_type.loc10_51 (%pattern_type.51d1c4.2) = return_slot_pattern %return.param_patt.loc10_51.1, %T.ref.loc10_51 [template = %return.patt.loc10_48.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc10_51: type = name_ref T, %T.loc10_26.2 [template = %T.loc10_26.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %.loc10_51.2: Core.Form = init_form %T.ref.loc10_51 [template = %.loc10_51.1 (constants.%.184)]
// CHECK:STDOUT:     %.loc10_28.1: type = splice_block %.loc10_28.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc10_28.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_26.2: type = symbolic_binding T, 0, template [template = %T.loc10_26.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %h.param: @GetTemplate.%.loc10_45.5 (%.5372ba.1) = value_param call_param0
// CHECK:STDOUT:     %.loc10_45.6: type = splice_block %.loc10_45.9 [template = %.loc10_45.5 (constants.%.5372ba.1)] {
// CHECK:STDOUT:       %Holder.ref: %Holder.type = name_ref Holder, file.%Holder.decl [concrete = constants.%Holder.generic]
// CHECK:STDOUT:       %T.ref.loc10_44: type = name_ref T, %T.loc10_26.2 [template = %T.loc10_26.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:       %.loc10_45.7: type = type_of_inst %.loc10_45.1 [template = %.loc10_45.2 (constants.%.58f)]
// CHECK:STDOUT:       %.loc10_45.8: @GetTemplate.%.loc10_45.2 (%.58f) = splice_inst %.loc10_45.1 [template = %.loc10_45.3 (constants.%.572)]
// CHECK:STDOUT:       %.loc10_45.9: type = splice_inst %.loc10_45.4 [template = %.loc10_45.5 (constants.%.5372ba.1)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %h: @GetTemplate.%.loc10_45.5 (%.5372ba.1) = wrapper_binding h, %h.param
// CHECK:STDOUT:     %return.param: ref @GetTemplate.%T.loc10_26.1 (%T.67db0b.2) = out_param call_param1
// CHECK:STDOUT:     %return: ref @GetTemplate.%T.loc10_26.1 (%T.67db0b.2) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @GetTemplate(%T.loc10_26.2: type) {
// CHECK:STDOUT:   %T.patt.loc10_26.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc10_26.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:   %T.loc10_26.1: type = symbolic_binding T, 0, template [template = %T.loc10_26.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:   %.loc10_45.1: <instruction> = call_action (%Holder.ref, %T.ref.loc10_44), false [template]
// CHECK:STDOUT:   %.loc10_45.2: type = type_of_inst %.loc10_45.1 [template = %.loc10_45.2 (constants.%.58f)]
// CHECK:STDOUT:   %.loc10_45.3: @GetTemplate.%.loc10_45.2 (%.58f) = splice_inst %.loc10_45.1 [template = %.loc10_45.3 (constants.%.572)]
// CHECK:STDOUT:   %.loc10_45.4: <instruction> = convert_to_value_action %.loc10_45.8, type [template]
// CHECK:STDOUT:   %.loc10_45.5: type = splice_inst %.loc10_45.4 [template = %.loc10_45.5 (constants.%.5372ba.1)]
// CHECK:STDOUT:   %pattern_type.loc10_35: type = pattern_type %.loc10_45.5 [template = %pattern_type.loc10_35 (constants.%pattern_type.fcb8f3.1)]
// CHECK:STDOUT:   %h.param_patt.loc10_35.2: @GetTemplate.%pattern_type.loc10_35 (%pattern_type.fcb8f3.1) = value_param_pattern [template = %h.param_patt.loc10_35.2 (constants.%h.param_patt.e4c369.1)]
// CHECK:STDOUT:   %h.patt.loc10_35.2: @GetTemplate.%pattern_type.loc10_35 (%pattern_type.fcb8f3.1) = wrapper_binding_pattern h, %h.param_patt.loc10_35.2 [template = %h.patt.loc10_35.2 (constants.%h.patt.d66407.1)]
// CHECK:STDOUT:   %.loc10_51.1: Core.Form = init_form %T.loc10_26.1 [template = %.loc10_51.1 (constants.%.184)]
// CHECK:STDOUT:   %pattern_type.loc10_51: type = pattern_type %T.loc10_26.1 [template = %pattern_type.loc10_51 (constants.%pattern_type.51d1c4.2)]
// CHECK:STDOUT:   %return.param_patt.loc10_51.2: @GetTemplate.%pattern_type.loc10_51 (%pattern_type.51d1c4.2) = out_param_pattern [template = %return.param_patt.loc10_51.2 (constants.%return.param_patt.41d)]
// CHECK:STDOUT:   %return.patt.loc10_48.2: @GetTemplate.%pattern_type.loc10_51 (%pattern_type.51d1c4.2) = return_slot_pattern %return.param_patt.loc10_51.2, %T.loc10_26.1 [template = %return.patt.loc10_48.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10_35: <witness> = require_complete_type %.loc10_45.5 [template = %require_complete.loc10_35 (constants.%require_complete.cb0)]
// CHECK:STDOUT:   %require_complete.loc10_48: <witness> = require_complete_type %T.loc10_26.1 [template = %require_complete.loc10_48 (constants.%require_complete.9443dd.2)]
// CHECK:STDOUT:   %.loc11_11.3: <instruction> = access_member_action %h.ref, item [template]
// CHECK:STDOUT:   %.loc11_11.4: type = type_of_inst %.loc11_11.3 [template = %.loc11_11.4 (constants.%.1d9)]
// CHECK:STDOUT:   %.loc11_11.5: @GetTemplate.%.loc11_11.4 (%.1d9) = splice_inst %.loc11_11.3 [template = %.loc11_11.5 (constants.%.1f3)]
// CHECK:STDOUT:   %.loc11_16.2: %tuple.type = initialize_action %.loc11_11.2, %T.loc10_26.1, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc11_16.2, element0 [template]
// CHECK:STDOUT:   %.loc11_16.3: @GetTemplate.%T.loc10_26.1 (%T.67db0b.2) = splice_inst %tuple.elem0 [template = %.loc11_16.3 (constants.%.38e)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%h.param: @GetTemplate.%.loc10_45.5 (%.5372ba.1)) -> out %return.param: @GetTemplate.%T.loc10_26.1 (%T.67db0b.2) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %h.ref: @GetTemplate.%.loc10_45.5 (%.5372ba.1) = name_ref h, %h
// CHECK:STDOUT:     %.loc11_11.1: type = type_of_inst %.loc11_11.3 [template = %.loc11_11.4 (constants.%.1d9)]
// CHECK:STDOUT:     %.loc11_11.2: @GetTemplate.%.loc11_11.4 (%.1d9) = splice_inst %.loc11_11.3 [template = %.loc11_11.5 (constants.%.1f3)]
// CHECK:STDOUT:     %.loc11_16.1: @GetTemplate.%T.loc10_26.1 (%T.67db0b.2) = splice_inst %tuple.elem0 [template = %.loc11_16.3 (constants.%.38e)]
// CHECK:STDOUT:     return %.loc11_16.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @GetTemplate(constants.%T.67db0b.2) {
// CHECK:STDOUT:   %T.patt.loc10_26.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc10_26.1 => constants.%T.67db0b.2
// CHECK:STDOUT:   %.loc10_45.1 => constants.%.f23
// CHECK:STDOUT:   %.loc10_45.2 => constants.%.033
// CHECK:STDOUT:   %.loc10_45.3 => constants.%.9ac
// CHECK:STDOUT:   %.loc10_45.4 => constants.%.c8c
// CHECK:STDOUT:   %.loc10_45.5 => constants.%.5372ba.2
// CHECK:STDOUT:   %pattern_type.loc10_35 => constants.%pattern_type.fcb8f3.2
// CHECK:STDOUT:   %h.param_patt.loc10_35.2 => constants.%h.param_patt.e4c369.2
// CHECK:STDOUT:   %h.patt.loc10_35.2 => constants.%h.patt.d66407.2
// CHECK:STDOUT:   %.loc10_51.1 => constants.%.184
// CHECK:STDOUT:   %pattern_type.loc10_51 => constants.%pattern_type.51d1c4.2
// CHECK:STDOUT:   %return.param_patt.loc10_51.2 => constants.%return.param_patt.41d
// CHECK:STDOUT:   %return.patt.loc10_48.2 => constants.%return.patt.b39
// CHECK:STDOUT: }
// CHECK:STDOUT:
