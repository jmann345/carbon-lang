// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/initialize.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/initialize.carbon

// --- return_tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}
//@dump-sem-ir-end

fn Use() -> (i32, i32) {
  return Dup(4 as i32);
}

// --- return_struct.carbon
library "[[@TEST_NAME]]";

fn Mk[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = x};
}

fn Use() -> {.a: i32, .b: i32} {
  return Mk(5 as i32);
}

// --- return_array.carbon
library "[[@TEST_NAME]]";

fn Two[template T: type](x: T) -> array(T, 2) {
  return (x, x);
}

fn Use() -> array(i32, 2) {
  return Two(4 as i32);
}

// --- class_method_return_tuple.carbon
library "[[@TEST_NAME]]";

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Use(h: H(i32)) -> (i32, i32) {
  return h.Both();
}

// --- return_param_tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Id[template T: type](p: T) -> T {
  return p;
}
//@dump-sem-ir-end

fn Use(t: (i32, i32)) -> (i32, i32) {
  return Id(t);
}

// --- copy_struct.carbon
library "[[@TEST_NAME]]";

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Use(s: {.x: i32, .y: i32}) -> i32 {
  return Id(s).y;
}

// --- returned_var_tuple.carbon
library "[[@TEST_NAME]]";

fn Mk[template T: type](x: T) -> (T, T) {
  returned var r: (T, T) = (x, x);
  return var;
}

fn Use() -> (i32, i32) {
  return Mk(2 as i32);
}

// --- value_param_return_tuple.carbon
library "[[@TEST_NAME]]";

fn F(template N: i32) -> (i32, i32) {
  return (N, N);
}

fn Use() -> (i32, i32) {
  return F(3);
}

// --- return_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

//@dump-sem-ir-begin
fn G[template T: type](x: T) -> ((T, T), i32) {
  return (Pair(x), 1);
}
//@dump-sem-ir-end

fn Use() -> ((i32, i32), i32) {
  return G(3 as i32);
}

// --- return_two_calls.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Quad[template T: type](x: T) -> ((T, T), (T, T)) {
  return (Pair(x), Pair(x));
}

fn Use() -> ((i32, i32), (i32, i32)) {
  return Quad(3 as i32);
}

// --- return_nested_literal.carbon
library "[[@TEST_NAME]]";

fn Quad[template T: type](x: T) -> ((T, T), T) {
  return ((x, x), x);
}

fn Use() -> ((i32, i32), i32) {
  return Quad(3 as i32);
}

// --- var_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((T, T), T) {
  var y: ((T, T), T) = (Pair(x), x);
  return y;
}

fn Use() -> ((i32, i32), i32) {
  return G(3 as i32);
}

// --- var_dependent_type_from_literal_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn H(template U: type, template T: type, x: T) -> U {
  var y: U = (Pair(x), x);
  return y;
}

fn Use() -> ((i32, i32), i32) {
  return H(((i32, i32), i32), i32, 4);
}

// --- return_struct_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> {.a: (T, T), .b: T} {
  return {.a = Pair(x), .b = x};
}

fn Use() -> {.a: (i32, i32), .b: i32} {
  return G(3 as i32);
}

// --- class_method_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

class H(template T: type) {
  var a: T;
  fn Both(self) -> ((T, T), T) { return (Pair(self.a), self.a); }
}

fn Use(h: H(i32)) -> ((i32, i32), i32) {
  return h.Both();
}

// --- nontemplate_call_in_template_literal.carbon
library "[[@TEST_NAME]]";

fn PairI(x: i32) -> (i32, i32) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((i32, i32), (T, T)) {
  return (PairI(1), (x, x));
}

fn Use() -> ((i32, i32), (i32, i32)) {
  return G(3 as i32);
}

// --- let_class_value_of_call.carbon
library "[[@TEST_NAME]]";

class C {
  var a: (i32, i32);
  var b: i32;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

//@dump-sem-ir-begin
fn G[template T: type](x: T) -> i32 {
  let c: C = {.a = Pair(x), .b = 1};
  return c.a.0 + c.a.1 + c.b;
}
//@dump-sem-ir-end

fn Use() -> i32 {
  return G(3 as i32);
}

// --- let_array_value_of_calls.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> T {
  let a: array((T, T), 2) = (Pair(x), Pair(x));
  return a[1].0;
}

fn Use() -> i32 {
  return G(5 as i32);
}

// --- fail_class_value_unexpected_field.carbon
library "[[@TEST_NAME]]";

class C {
  var a: (i32, i32);
  var b: i32;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> i32 {
  // CHECK:STDERR: fail_class_value_unexpected_field.carbon:[[@LINE+4]]:14: error: struct `C` has no field named `c` [StructInitUnexpectedFieldInLiteral]
  // CHECK:STDERR:   let c: C = {.a = Pair(x), .c = 1};
  // CHECK:STDERR:              ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let c: C = {.a = Pair(x), .c = 1};
  return c.b;
}

// --- return_struct_convert.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> {.a: i64} {
  return x;
}

fn Use(s: {.a: i32}) -> {.a: i64} {
  return F(s);
}

// --- var_with_destructor.carbon
library "[[@TEST_NAME]]";

class D {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n + 10}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

//@dump-sem-ir-begin
fn F[template T: type](x: T) -> i32 {
  var unused y: T = x;
  return 0;
}
//@dump-sem-ir-end

fn Use(d: D) -> i32 {
  return F(d);
}

// --- destructure_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}
//@dump-sem-ir-end

fn Use(t: (i32, i32)) -> i32 {
  return Sum(t);
}

// --- destructure_member.carbon
library "[[@TEST_NAME]]";

class Outer {
  var inner: (i32, i32);
}

fn F[template T: type](x: T) -> i32 {
  let (a: i32, b: i32) = x.inner;
  return a + b;
}

fn Use(o: Outer) -> i32 {
  return F(o);
}


// --- return_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn M[template T: type](x: T) -> (T, T) {
  return (x, 1);
}
//@dump-sem-ir-end

fn Use() -> (i32, i32) {
  return M(4 as i32);
}

// --- return_struct_constant_field.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = 2};
}

fn Use() -> {.a: i32, .b: i32} {
  return M(4 as i32);
}

// --- return_array_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> array(T, 2) {
  return (x, 3);
}

fn Use() -> array(i32, 2) {
  return M(4 as i32);
}

// --- var_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> (T, T) {
  var p: (T, T) = (x, 1);
  return p;
}

fn Use() -> (i32, i32) {
  return M(4 as i32);
}

// --- assign_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T, y: T) -> (T, T) {
  var t: (T, T) = (x, y);
  t = (x, 1);
  return t;
}

fn Use() -> (i32, i32) {
  return M(4 as i32, 9 as i32);
}

// --- return_nested_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> ((T, T), T) {
  return ((x, 2), 3);
}

fn Use() -> ((i32, i32), i32) {
  return M(4 as i32);
}

// --- template_value_element.carbon
library "[[@TEST_NAME]]";

fn M(template N: i32, x: i32) -> (i32, i32) {
  return (N, x);
}

fn Use() -> (i32, i32) {
  return M(3, 4);
}

// --- return_class_constant_field.carbon
library "[[@TEST_NAME]]";

class P(T: type) {
  var a: T;
  var b: T;
}

fn M[template T: type](x: T) -> P(T) {
  return {.a = x, .b = 1};
}

fn Use() -> P(i32) {
  return M(4 as i32);
}

// --- var_class_constant_field.carbon
library "[[@TEST_NAME]]";

class P(T: type) {
  var a: T;
  var b: T;
}

fn M[template T: type](x: T) -> T {
  var p: P(T) = {.a = x, .b = 2};
  return p.b;
}

fn Use() -> i32 {
  return M(4 as i32);
}

// CHECK:STDOUT: --- return_tuple.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [template]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.1 = wrapper_binding_pattern x, %x.param_patt.91d [template]
// CHECK:STDOUT:   %tuple.type.693: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.3df: %tuple.type.693 = tuple_value (%T.67db0b.1, %T.67db0b.1) [template]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67db0b.1, %T.67db0b.1) [template]
// CHECK:STDOUT:   %.ce8: Core.Form = init_form %tuple.type.07a [template]
// CHECK:STDOUT:   %pattern_type.c3f: type = pattern_type %tuple.type.07a [template]
// CHECK:STDOUT:   %return.param_patt.e22: %pattern_type.c3f = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.1a0: %pattern_type.c3f = return_slot_pattern %return.param_patt.e22, %tuple.type.07a [template]
// CHECK:STDOUT:   %Dup.type: type = fn_type @Dup [concrete]
// CHECK:STDOUT:   %Dup: %Dup.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %require_complete.22a: <witness> = require_complete_type %tuple.type.07a [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.ac2: ref <instruction> = splice_block %tuple.elem0 {
// CHECK:STDOUT:       %tuple.elem0: ref @Dup.%T.loc4_18.1 (%T.67db0b.1) = tuple_access @Dup.%return.param, element0
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.b669fb.1: %T.67db0b.1 = splice_inst @Dup.%tuple.elem0.loc5_15.1 [template]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.7a3: ref <instruction> = splice_block %tuple.elem1 {
// CHECK:STDOUT:       %tuple.elem1: ref @Dup.%T.loc4_18.1 (%T.67db0b.1) = tuple_access @Dup.%return.param, element1
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.b669fb.2: %T.67db0b.1 = splice_inst @Dup.%tuple.elem0.loc5_15.2 [template]
// CHECK:STDOUT:   %tuple.8e4: %tuple.type.07a = tuple_value (%.b669fb.1, %.b669fb.2) [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.94e: %tuple.type.693 = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %.c11: Core.Form = init_form %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %return.param_patt.a90: %pattern_type.394 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.2ed: %pattern_type.394 = return_slot_pattern %return.param_patt.a90, %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e3b: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %complete_type.6c4: <witness> = complete_type_witness %tuple.type.e55 [concrete]
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
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.492: init %i32 = splice_block %.e45 {
// CHECK:STDOUT:       %.97afc0.2: %i32 = specific_inst @Dup.%x.ref.loc5_11, @Dup(%i32)
// CHECK:STDOUT:       %impl.elem0.88228e.2: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.de4da6.2: <bound method> = bound_method %.97afc0.2, %impl.elem0.88228e.2
// CHECK:STDOUT:       %specific_fn.96a233.2: <specific function> = specific_function %impl.elem0.88228e.2, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.56d925.2: <bound method> = bound_method %.97afc0.2, %specific_fn.96a233.2
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call.359493.2: init %i32 = call %bound_method.56d925.2(%.97afc0.2)
// CHECK:STDOUT:       %tuple.elem0: ref @Dup.%T.loc4_18.1 (%T.67db0b.1) = tuple_access @Dup.%return.param, element0
// CHECK:STDOUT:       %.531e: ref %i32 = specific_inst %tuple.elem0, @Dup(%i32)
// CHECK:STDOUT:       %.e45: init %i32 to %.531e = in_place_init %Int.as.Copy.impl.Op.call.359493.2
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.1: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.3) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.4: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.60a: init %i32 = splice_block %.06b {
// CHECK:STDOUT:       %.97afc0.1: %i32 = specific_inst @Dup.%x.ref.loc5_14, @Dup(%i32)
// CHECK:STDOUT:       %impl.elem0.88228e.1: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.de4da6.1: <bound method> = bound_method %.97afc0.1, %impl.elem0.88228e.1
// CHECK:STDOUT:       %specific_fn.96a233.1: <specific function> = specific_function %impl.elem0.88228e.1, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.56d925.1: <bound method> = bound_method %.97afc0.1, %specific_fn.96a233.1
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call.359493.1: init %i32 = call %bound_method.56d925.1(%.97afc0.1)
// CHECK:STDOUT:       %tuple.elem1: ref @Dup.%T.loc4_18.1 (%T.67db0b.1) = tuple_access @Dup.%return.param, element1
// CHECK:STDOUT:       %.190: ref %i32 = specific_inst %tuple.elem1, @Dup(%i32)
// CHECK:STDOUT:       %.06b: init %i32 to %.190 = in_place_init %Int.as.Copy.impl.Op.call.359493.1
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.2: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.4) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Dup.decl: %Dup.type = fn_decl @Dup [concrete = constants.%Dup] {
// CHECK:STDOUT:     %T.patt.loc4_18.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_18.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %x.param_patt.loc4_27.1: @Dup.%pattern_type.loc4_27 (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc4_27.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc4_27.1: @Dup.%pattern_type.loc4_27 (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc4_27.1 [template = %x.patt.loc4_27.2 (constants.%x.patt.260)]
// CHECK:STDOUT:     %return.param_patt.loc4_40.1: @Dup.%pattern_type.loc4_40 (%pattern_type.c3f) = out_param_pattern [template = %return.param_patt.loc4_40.2 (constants.%return.param_patt.e22)]
// CHECK:STDOUT:     %return.patt.loc4_32.1: @Dup.%pattern_type.loc4_40 (%pattern_type.c3f) = return_slot_pattern %return.param_patt.loc4_40.1, %.loc4_40.3 [template = %return.patt.loc4_32.2 (constants.%return.patt.1a0)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc4_36: type = name_ref T, %T.loc4_18.2 [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %T.ref.loc4_39: type = name_ref T, %T.loc4_18.2 [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %.loc4_40.2: %tuple.type.693 = tuple_literal (%T.ref.loc4_36, %T.ref.loc4_39) [template = %tuple.loc4 (constants.%tuple.3df)]
// CHECK:STDOUT:     %.loc4_40.3: type = converted %.loc4_40.2, constants.%tuple.type.07a [template = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:     %.loc4_40.4: Core.Form = init_form %.loc4_40.3 [template = %.loc4_40.1 (constants.%.ce8)]
// CHECK:STDOUT:     %.loc4_20.1: type = splice_block %.loc4_20.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_20.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_18.2: type = symbolic_binding T, 0, template [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x.param: @Dup.%T.loc4_18.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc4_29: type = name_ref T, %T.loc4_18.2 [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x: @Dup.%T.loc4_18.1 (%T.67db0b.1) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref @Dup.%tuple.type (%tuple.type.07a) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Dup.%tuple.type (%tuple.type.07a) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Dup(%T.loc4_18.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_18.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_18.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc4_18.1: type = symbolic_binding T, 0, template [template = %T.loc4_18.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type.loc4_27: type = pattern_type %T.loc4_18.1 [template = %pattern_type.loc4_27 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt.loc4_27.2: @Dup.%pattern_type.loc4_27 (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc4_27.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc4_27.2: @Dup.%pattern_type.loc4_27 (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc4_27.2 [template = %x.patt.loc4_27.2 (constants.%x.patt.260)]
// CHECK:STDOUT:   %tuple.loc4: %tuple.type.693 = tuple_value (%T.loc4_18.1, %T.loc4_18.1) [template = %tuple.loc4 (constants.%tuple.3df)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%T.loc4_18.1, %T.loc4_18.1) [template = %tuple.type (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc4_40.1: Core.Form = init_form %tuple.type [template = %.loc4_40.1 (constants.%.ce8)]
// CHECK:STDOUT:   %pattern_type.loc4_40: type = pattern_type %tuple.type [template = %pattern_type.loc4_40 (constants.%pattern_type.c3f)]
// CHECK:STDOUT:   %return.param_patt.loc4_40.2: @Dup.%pattern_type.loc4_40 (%pattern_type.c3f) = out_param_pattern [template = %return.param_patt.loc4_40.2 (constants.%return.param_patt.e22)]
// CHECK:STDOUT:   %return.patt.loc4_32.2: @Dup.%pattern_type.loc4_40 (%pattern_type.c3f) = return_slot_pattern %return.param_patt.loc4_40.2, %tuple.type [template = %return.patt.loc4_32.2 (constants.%return.patt.1a0)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_27: <witness> = require_complete_type %T.loc4_18.1 [template = %require_complete.loc4_27 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %require_complete.loc4_32: <witness> = require_complete_type %tuple.type [template = %require_complete.loc4_32 (constants.%require_complete.22a)]
// CHECK:STDOUT:   %.loc5_15.5: %tuple.type.f7a = initialize_action %x.ref.loc5_11, %T.loc4_18.1, constants.%inst.splice_block.426619.1, true [template]
// CHECK:STDOUT:   %tuple.elem0.loc5_15.1: <instruction> = tuple_access %.loc5_15.5, element0 [template]
// CHECK:STDOUT:   %.loc5_15.6: @Dup.%T.loc4_18.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5_15.1 [template = %.loc5_15.6 (constants.%.b669fb.1)]
// CHECK:STDOUT:   %.loc5_15.7: %tuple.type.f7a = initialize_action %x.ref.loc5_14, %T.loc4_18.1, constants.%inst.splice_block.426619.2, true [template]
// CHECK:STDOUT:   %tuple.elem0.loc5_15.2: <instruction> = tuple_access %.loc5_15.7, element0 [template]
// CHECK:STDOUT:   %.loc5_15.8: @Dup.%T.loc4_18.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5_15.2 [template = %.loc5_15.8 (constants.%.b669fb.2)]
// CHECK:STDOUT:   %tuple.loc5: @Dup.%tuple.type (%tuple.type.07a) = tuple_value (%.loc5_15.6, %.loc5_15.8) [template = %tuple.loc5 (constants.%tuple.8e4)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @Dup.%T.loc4_18.1 (%T.67db0b.1)) -> out %return.param: @Dup.%tuple.type (%tuple.type.07a) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref.loc5_11: @Dup.%T.loc4_18.1 (%T.67db0b.1) = name_ref x, %x
// CHECK:STDOUT:     %x.ref.loc5_14: @Dup.%T.loc4_18.1 (%T.67db0b.1) = name_ref x, %x
// CHECK:STDOUT:     %.loc5_15.1: @Dup.%tuple.type (%tuple.type.07a) = tuple_literal (%x.ref.loc5_11, %x.ref.loc5_14)
// CHECK:STDOUT:     %.loc5_15.2: @Dup.%T.loc4_18.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5_15.1 [template = %.loc5_15.6 (constants.%.b669fb.1)]
// CHECK:STDOUT:     %.loc5_15.3: @Dup.%T.loc4_18.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5_15.2 [template = %.loc5_15.8 (constants.%.b669fb.2)]
// CHECK:STDOUT:     %.loc5_15.4: init @Dup.%tuple.type (%tuple.type.07a) to %return.param = tuple_init (%.loc5_15.2, %.loc5_15.3) [template = %tuple.loc5 (constants.%tuple.8e4)]
// CHECK:STDOUT:     %.loc5_16: init @Dup.%tuple.type (%tuple.type.07a) = converted %.loc5_15.1, %.loc5_15.4 [template = %tuple.loc5 (constants.%tuple.8e4)]
// CHECK:STDOUT:     return %.loc5_16 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Dup(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc4_18.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_18.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type.loc4_27 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %x.param_patt.loc4_27.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc4_27.2 => constants.%x.patt.260
// CHECK:STDOUT:   %tuple.loc4 => constants.%tuple.3df
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.07a
// CHECK:STDOUT:   %.loc4_40.1 => constants.%.ce8
// CHECK:STDOUT:   %pattern_type.loc4_40 => constants.%pattern_type.c3f
// CHECK:STDOUT:   %return.param_patt.loc4_40.2 => constants.%return.param_patt.e22
// CHECK:STDOUT:   %return.patt.loc4_32.2 => constants.%return.patt.1a0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Dup(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_18.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_18.1 => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc4_27 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt.loc4_27.2 => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt.loc4_27.2 => constants.%x.patt.e3b
// CHECK:STDOUT:   %tuple.loc4 => constants.%tuple.94e
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc4_40.1 => constants.%.c11
// CHECK:STDOUT:   %pattern_type.loc4_40 => constants.%pattern_type.394
// CHECK:STDOUT:   %return.param_patt.loc4_40.2 => constants.%return.param_patt.a90
// CHECK:STDOUT:   %return.patt.loc4_32.2 => constants.%return.patt.2ed
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_27 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc4_32 => constants.%complete_type.6c4
// CHECK:STDOUT:   %.loc5_15.5 => constants.%tuple.24243e.1
// CHECK:STDOUT:   %tuple.elem0.loc5_15.1 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc5_15.6 => <not constant>
// CHECK:STDOUT:   %.loc5_15.7 => constants.%tuple.24243e.2
// CHECK:STDOUT:   %tuple.elem0.loc5_15.2 => constants.%inst.splice_block.426619.4
// CHECK:STDOUT:   %.loc5_15.8 => <not constant>
// CHECK:STDOUT:   %tuple.loc5 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- return_param_tuple.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %p.param_patt.e58: %pattern_type.51d = value_param_pattern [template]
// CHECK:STDOUT:   %p.patt.0ba: %pattern_type.51d = wrapper_binding_pattern p, %p.param_patt.e58 [template]
// CHECK:STDOUT:   %.184: Core.Form = init_form %T.67db0b.1 [template]
// CHECK:STDOUT:   %return.param_patt.41d: %pattern_type.51d = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.b39: %pattern_type.51d = return_slot_pattern %return.param_patt.41d, %T.67db0b.1 [template]
// CHECK:STDOUT:   %Id.type: type = fn_type @Id [concrete]
// CHECK:STDOUT:   %Id: %Id.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.38e: %T.67db0b.1 = splice_inst @Id.%tuple.elem0 [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %.c11: Core.Form = init_form %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %return.param_patt.a90: %pattern_type.394 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.2ed: %pattern_type.394 = return_slot_pattern %return.param_patt.a90, %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %p.param_patt.e62: %pattern_type.394 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.07f: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt.e62 [concrete]
// CHECK:STDOUT:   %complete_type.6c4: <witness> = complete_type_witness %tuple.type.e55 [concrete]
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
// CHECK:STDOUT:   %inst.splice_block: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.def: init %tuple.type.e55 = splice_block %.adc {
// CHECK:STDOUT:       %.d23: %tuple.type.e55 = specific_inst @Id.%p.ref, @Id(%tuple.type.e55)
// CHECK:STDOUT:       %tuple.elem0.ccc: %i32 = tuple_access %.d23, element0
// CHECK:STDOUT:       %impl.elem0.88228e.1: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.6f5: <bound method> = bound_method %tuple.elem0.ccc, %impl.elem0.88228e.1
// CHECK:STDOUT:       %specific_fn.96a233.1: <specific function> = specific_function %impl.elem0.88228e.1, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.6f3: <bound method> = bound_method %tuple.elem0.ccc, %specific_fn.96a233.1
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call.c34: init %i32 = call %bound_method.6f3(%tuple.elem0.ccc)
// CHECK:STDOUT:       %.6ae: ref %tuple.type.e55 = specific_inst @Id.%return.param, @Id(%tuple.type.e55)
// CHECK:STDOUT:       %tuple.elem0.ac2: ref %i32 = tuple_access %.6ae, element0
// CHECK:STDOUT:       %.310: init %i32 to %tuple.elem0.ac2 = in_place_init %Int.as.Copy.impl.Op.call.c34
// CHECK:STDOUT:       %tuple.elem1.b60: %i32 = tuple_access %.d23, element1
// CHECK:STDOUT:       %impl.elem0.88228e.2: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.6e4: <bound method> = bound_method %tuple.elem1.b60, %impl.elem0.88228e.2
// CHECK:STDOUT:       %specific_fn.96a233.2: <specific function> = specific_function %impl.elem0.88228e.2, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.7d7: <bound method> = bound_method %tuple.elem1.b60, %specific_fn.96a233.2
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call.7ff: init %i32 = call %bound_method.7d7(%tuple.elem1.b60)
// CHECK:STDOUT:       %tuple.elem1.3d1: ref %i32 = tuple_access %.6ae, element1
// CHECK:STDOUT:       %.fb3: init %i32 to %tuple.elem1.3d1 = in_place_init %Int.as.Copy.impl.Op.call.7ff
// CHECK:STDOUT:       %.adc: init %tuple.type.e55 to %.6ae = tuple_init (%.310, %.fb3)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.242: %tuple.type.f7a = tuple_value (%inst.splice_block) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Id.decl: %Id.type = fn_decl @Id [concrete = constants.%Id] {
// CHECK:STDOUT:     %T.patt.loc4_17.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_17.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %p.param_patt.loc4_26.1: @Id.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %p.param_patt.loc4_26.2 (constants.%p.param_patt.e58)]
// CHECK:STDOUT:     %p.patt.loc4_26.1: @Id.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern p, %p.param_patt.loc4_26.1 [template = %p.patt.loc4_26.2 (constants.%p.patt.0ba)]
// CHECK:STDOUT:     %return.param_patt.loc4_34.1: @Id.%pattern_type (%pattern_type.51d) = out_param_pattern [template = %return.param_patt.loc4_34.2 (constants.%return.param_patt.41d)]
// CHECK:STDOUT:     %return.patt.loc4_31.1: @Id.%pattern_type (%pattern_type.51d) = return_slot_pattern %return.param_patt.loc4_34.1, %T.ref.loc4_34 [template = %return.patt.loc4_31.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc4_34: type = name_ref T, %T.loc4_17.2 [template = %T.loc4_17.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %.loc4_34.2: Core.Form = init_form %T.ref.loc4_34 [template = %.loc4_34.1 (constants.%.184)]
// CHECK:STDOUT:     %.loc4_19.1: type = splice_block %.loc4_19.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_19.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_17.2: type = symbolic_binding T, 0, template [template = %T.loc4_17.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %p.param: @Id.%T.loc4_17.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc4_28: type = name_ref T, %T.loc4_17.2 [template = %T.loc4_17.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %p: @Id.%T.loc4_17.1 (%T.67db0b.1) = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref @Id.%T.loc4_17.1 (%T.67db0b.1) = out_param call_param1
// CHECK:STDOUT:     %return: ref @Id.%T.loc4_17.1 (%T.67db0b.1) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Id(%T.loc4_17.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_17.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_17.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc4_17.1: type = symbolic_binding T, 0, template [template = %T.loc4_17.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_17.1 [template = %pattern_type (constants.%pattern_type.51d)]
// CHECK:STDOUT:   %p.param_patt.loc4_26.2: @Id.%pattern_type (%pattern_type.51d) = value_param_pattern [template = %p.param_patt.loc4_26.2 (constants.%p.param_patt.e58)]
// CHECK:STDOUT:   %p.patt.loc4_26.2: @Id.%pattern_type (%pattern_type.51d) = wrapper_binding_pattern p, %p.param_patt.loc4_26.2 [template = %p.patt.loc4_26.2 (constants.%p.patt.0ba)]
// CHECK:STDOUT:   %.loc4_34.1: Core.Form = init_form %T.loc4_17.1 [template = %.loc4_34.1 (constants.%.184)]
// CHECK:STDOUT:   %return.param_patt.loc4_34.2: @Id.%pattern_type (%pattern_type.51d) = out_param_pattern [template = %return.param_patt.loc4_34.2 (constants.%return.param_patt.41d)]
// CHECK:STDOUT:   %return.patt.loc4_31.2: @Id.%pattern_type (%pattern_type.51d) = return_slot_pattern %return.param_patt.loc4_34.2, %T.loc4_17.1 [template = %return.patt.loc4_31.2 (constants.%return.patt.b39)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc4_17.1 [template = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc5_11.2: %tuple.type.f7a = initialize_action %p.ref, %T.loc4_17.1, %return.param, false [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc5_11.2, element0 [template]
// CHECK:STDOUT:   %.loc5_11.3: @Id.%T.loc4_17.1 (%T.67db0b.1) = splice_inst %tuple.elem0 [template = %.loc5_11.3 (constants.%.38e)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%p.param: @Id.%T.loc4_17.1 (%T.67db0b.1)) -> out %return.param: @Id.%T.loc4_17.1 (%T.67db0b.1) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %p.ref: @Id.%T.loc4_17.1 (%T.67db0b.1) = name_ref p, %p
// CHECK:STDOUT:     %.loc5_11.1: @Id.%T.loc4_17.1 (%T.67db0b.1) = splice_inst %tuple.elem0 [template = %.loc5_11.3 (constants.%.38e)]
// CHECK:STDOUT:     return %.loc5_11.1 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Id(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc4_17.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_17.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d
// CHECK:STDOUT:   %p.param_patt.loc4_26.2 => constants.%p.param_patt.e58
// CHECK:STDOUT:   %p.patt.loc4_26.2 => constants.%p.patt.0ba
// CHECK:STDOUT:   %.loc4_34.1 => constants.%.184
// CHECK:STDOUT:   %return.param_patt.loc4_34.2 => constants.%return.param_patt.41d
// CHECK:STDOUT:   %return.patt.loc4_31.2 => constants.%return.patt.b39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Id(constants.%tuple.type.e55) {
// CHECK:STDOUT:   %T.patt.loc4_17.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_17.1 => constants.%tuple.type.e55
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.394
// CHECK:STDOUT:   %p.param_patt.loc4_26.2 => constants.%p.param_patt.e62
// CHECK:STDOUT:   %p.patt.loc4_26.2 => constants.%p.patt.07f
// CHECK:STDOUT:   %.loc4_34.1 => constants.%.c11
// CHECK:STDOUT:   %return.param_patt.loc4_34.2 => constants.%return.param_patt.a90
// CHECK:STDOUT:   %return.patt.loc4_31.2 => constants.%return.patt.2ed
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.6c4
// CHECK:STDOUT:   %.loc5_11.2 => constants.%tuple.242
// CHECK:STDOUT:   %tuple.elem0 => constants.%inst.splice_block
// CHECK:STDOUT:   %.loc5_11.3 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- return_tuple_of_call.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [template]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.1 = wrapper_binding_pattern x, %x.param_patt.91d [template]
// CHECK:STDOUT:   %tuple.type.693: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.3df: %tuple.type.693 = tuple_value (%T.67db0b.1, %T.67db0b.1) [template]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67db0b.1, %T.67db0b.1) [template]
// CHECK:STDOUT:   %Pair.type: type = fn_type @Pair [concrete]
// CHECK:STDOUT:   %Pair: %Pair.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %require_complete.22a: <witness> = require_complete_type %tuple.type.07a [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.55c: type = tuple_type (%tuple.type.693, type) [concrete]
// CHECK:STDOUT:   %tuple.1ef: %tuple.type.55c = tuple_value (%tuple.3df, %i32) [template]
// CHECK:STDOUT:   %tuple.type.40a: type = tuple_type (%tuple.type.07a, %i32) [template]
// CHECK:STDOUT:   %.feb: Core.Form = init_form %tuple.type.40a [template]
// CHECK:STDOUT:   %pattern_type.e92: type = pattern_type %tuple.type.40a [template]
// CHECK:STDOUT:   %return.param_patt.332: %pattern_type.e92 = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.8ca: %pattern_type.e92 = return_slot_pattern %return.param_patt.332, %tuple.type.40a [template]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %require_complete.c0e: <witness> = require_complete_type %tuple.type.40a [template]
// CHECK:STDOUT:   %.a0c: type = type_of_inst @G.%.loc9_17.3 [template]
// CHECK:STDOUT:   %.33e: %.a0c = splice_inst @G.%.loc9_17.3 [template]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %tuple.type.6e7: type = tuple_type (%.a0c, Core.IntLiteral) [template]
// CHECK:STDOUT:   %tuple.2db: %tuple.type.6e7 = tuple_value (%.33e, %int_1.5b8) [template]
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.36d: ref <instruction> = splice_block %tuple.elem0.e8e {
// CHECK:STDOUT:       %tuple.elem0.e8e: ref @G.%tuple.type.loc8_45.1 (%tuple.type.07a) = tuple_access @G.%return.param, element0
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.03e: %tuple.type.07a = splice_inst @G.%tuple.elem0 [template]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %tuple.da3: %tuple.type.40a = tuple_value (%.03e, %int_1.0c6) [template]
// CHECK:STDOUT:   %tuple.94e: %tuple.type.693 = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.5bb: %tuple.type.55c = tuple_value (%tuple.94e, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.7fb: type = tuple_type (%tuple.type.e55, %i32) [concrete]
// CHECK:STDOUT:   %.9c9: Core.Form = init_form %tuple.type.7fb [concrete]
// CHECK:STDOUT:   %pattern_type.1a2: type = pattern_type %tuple.type.7fb [concrete]
// CHECK:STDOUT:   %return.param_patt.c7b: %pattern_type.1a2 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.5bc: %pattern_type.1a2 = return_slot_pattern %return.param_patt.c7b, %tuple.type.7fb [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e3b: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %complete_type.935: <witness> = complete_type_witness %tuple.type.7fb [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.4: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.e07: init %tuple.type.e55 = splice_block %Pair.call {
// CHECK:STDOUT:       %.76c: %i32 = specific_inst @G.%x.ref, @G(%i32)
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %.81c: ref %tuple.type.e55 = splice_block %.f94 {
// CHECK:STDOUT:         %tuple.elem0.e8e: ref @G.%tuple.type.loc8_45.1 (%tuple.type.07a) = tuple_access @G.%return.param, element0
// CHECK:STDOUT:         %.f94: ref %tuple.type.e55 = specific_inst %tuple.elem0.e8e, @G(%i32)
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %Pair.call: init %tuple.type.e55 to %.81c = call %Pair.specific_fn.023a53.2(%.76c)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.type.34b: type = tuple_type (%tuple.type.e55, Core.IntLiteral) [concrete]
// CHECK:STDOUT:   %complete_type.6c4: <witness> = complete_type_witness %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.5: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.121: init %tuple.type.e55 = splice_block %.e07 {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.1: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.5) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %T.patt.loc8_16.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc8_16.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %x.param_patt.loc8_25.1: @G.%pattern_type.loc8_25 (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc8_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc8_25.1: @G.%pattern_type.loc8_25 (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc8_25.1 [template = %x.patt.loc8_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:     %return.param_patt.loc8_45.1: @G.%pattern_type.loc8_45 (%pattern_type.e92) = out_param_pattern [template = %return.param_patt.loc8_45.2 (constants.%return.param_patt.332)]
// CHECK:STDOUT:     %return.patt.loc8_30.1: @G.%pattern_type.loc8_45 (%pattern_type.e92) = return_slot_pattern %return.param_patt.loc8_45.1, %.loc8_45.4 [template = %return.patt.loc8_30.2 (constants.%return.patt.8ca)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc8_35: type = name_ref T, %T.loc8_16.2 [template = %T.loc8_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %T.ref.loc8_38: type = name_ref T, %T.loc8_16.2 [template = %T.loc8_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %.loc8_39: %tuple.type.693 = tuple_literal (%T.ref.loc8_35, %T.ref.loc8_38) [template = %tuple.loc8_39 (constants.%tuple.3df)]
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8_45.2: %tuple.type.55c = tuple_literal (%.loc8_39, %i32) [template = %tuple.loc8_45 (constants.%tuple.1ef)]
// CHECK:STDOUT:     %.loc8_45.3: type = converted constants.%tuple.3df, constants.%tuple.type.07a [template = %tuple.type.loc8_45.1 (constants.%tuple.type.07a)]
// CHECK:STDOUT:     %.loc8_45.4: type = converted %.loc8_45.2, constants.%tuple.type.40a [template = %tuple.type.loc8_45.2 (constants.%tuple.type.40a)]
// CHECK:STDOUT:     %.loc8_45.5: Core.Form = init_form %.loc8_45.4 [template = %.loc8_45.1 (constants.%.feb)]
// CHECK:STDOUT:     %.loc8_18.1: type = splice_block %.loc8_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc8_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc8_16.2: type = symbolic_binding T, 0, template [template = %T.loc8_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x.param: @G.%T.loc8_16.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc8_27: type = name_ref T, %T.loc8_16.2 [template = %T.loc8_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x: @G.%T.loc8_16.1 (%T.67db0b.1) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref @G.%tuple.type.loc8_45.2 (%tuple.type.40a) = out_param call_param1
// CHECK:STDOUT:     %return: ref @G.%tuple.type.loc8_45.2 (%tuple.type.40a) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @G(%T.loc8_16.2: type) {
// CHECK:STDOUT:   %T.patt.loc8_16.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc8_16.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc8_16.1: type = symbolic_binding T, 0, template [template = %T.loc8_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type.loc8_25: type = pattern_type %T.loc8_16.1 [template = %pattern_type.loc8_25 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt.loc8_25.2: @G.%pattern_type.loc8_25 (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc8_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc8_25.2: @G.%pattern_type.loc8_25 (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc8_25.2 [template = %x.patt.loc8_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:   %tuple.loc8_39: %tuple.type.693 = tuple_value (%T.loc8_16.1, %T.loc8_16.1) [template = %tuple.loc8_39 (constants.%tuple.3df)]
// CHECK:STDOUT:   %tuple.loc8_45: %tuple.type.55c = tuple_value (%tuple.loc8_39, constants.%i32) [template = %tuple.loc8_45 (constants.%tuple.1ef)]
// CHECK:STDOUT:   %tuple.type.loc8_45.1: type = tuple_type (%T.loc8_16.1, %T.loc8_16.1) [template = %tuple.type.loc8_45.1 (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %tuple.type.loc8_45.2: type = tuple_type (%tuple.type.loc8_45.1, constants.%i32) [template = %tuple.type.loc8_45.2 (constants.%tuple.type.40a)]
// CHECK:STDOUT:   %.loc8_45.1: Core.Form = init_form %tuple.type.loc8_45.2 [template = %.loc8_45.1 (constants.%.feb)]
// CHECK:STDOUT:   %pattern_type.loc8_45: type = pattern_type %tuple.type.loc8_45.2 [template = %pattern_type.loc8_45 (constants.%pattern_type.e92)]
// CHECK:STDOUT:   %return.param_patt.loc8_45.2: @G.%pattern_type.loc8_45 (%pattern_type.e92) = out_param_pattern [template = %return.param_patt.loc8_45.2 (constants.%return.param_patt.332)]
// CHECK:STDOUT:   %return.patt.loc8_30.2: @G.%pattern_type.loc8_45 (%pattern_type.e92) = return_slot_pattern %return.param_patt.loc8_45.2, %tuple.type.loc8_45.2 [template = %return.patt.loc8_30.2 (constants.%return.patt.8ca)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8_25: <witness> = require_complete_type %T.loc8_16.1 [template = %require_complete.loc8_25 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %require_complete.loc8_30: <witness> = require_complete_type %tuple.type.loc8_45.2 [template = %require_complete.loc8_30 (constants.%require_complete.c0e)]
// CHECK:STDOUT:   %.loc9_17.3: <instruction> = call_action (%Pair.ref, %x.ref), false [template]
// CHECK:STDOUT:   %.loc9_17.4: type = type_of_inst %.loc9_17.3 [template = %.loc9_17.4 (constants.%.a0c)]
// CHECK:STDOUT:   %.loc9_17.5: @G.%.loc9_17.4 (%.a0c) = splice_inst %.loc9_17.3 [template = %.loc9_17.5 (constants.%.33e)]
// CHECK:STDOUT:   %tuple.type.loc9: type = tuple_type (%.loc9_17.4, Core.IntLiteral) [template = %tuple.type.loc9 (constants.%tuple.type.6e7)]
// CHECK:STDOUT:   %tuple.loc9_21.1: @G.%tuple.type.loc9 (%tuple.type.6e7) = tuple_value (%.loc9_17.5, constants.%int_1.5b8) [template = %tuple.loc9_21.1 (constants.%tuple.2db)]
// CHECK:STDOUT:   %require_complete.loc9: <witness> = require_complete_type %tuple.type.loc8_45.1 [template = %require_complete.loc9 (constants.%require_complete.22a)]
// CHECK:STDOUT:   %.loc9_21.6: %tuple.type.f7a = initialize_action %.loc9_17.2, %tuple.type.loc8_45.1, constants.%inst.splice_block.426619.3, true [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc9_21.6, element0 [template]
// CHECK:STDOUT:   %.loc9_21.7: @G.%tuple.type.loc8_45.1 (%tuple.type.07a) = splice_inst %tuple.elem0 [template = %.loc9_21.7 (constants.%.03e)]
// CHECK:STDOUT:   %tuple.loc9_21.2: @G.%tuple.type.loc8_45.2 (%tuple.type.40a) = tuple_value (%.loc9_21.7, constants.%int_1.0c6) [template = %tuple.loc9_21.2 (constants.%tuple.da3)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @G.%T.loc8_16.1 (%T.67db0b.1)) -> out %return.param: @G.%tuple.type.loc8_45.2 (%tuple.type.40a) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Pair.ref: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair]
// CHECK:STDOUT:     %x.ref: @G.%T.loc8_16.1 (%T.67db0b.1) = name_ref x, %x
// CHECK:STDOUT:     %.loc9_17.1: type = type_of_inst %.loc9_17.3 [template = %.loc9_17.4 (constants.%.a0c)]
// CHECK:STDOUT:     %.loc9_17.2: @G.%.loc9_17.4 (%.a0c) = splice_inst %.loc9_17.3 [template = %.loc9_17.5 (constants.%.33e)]
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %.loc9_21.1: @G.%tuple.type.loc9 (%tuple.type.6e7) = tuple_literal (%.loc9_17.2, %int_1) [template = %tuple.loc9_21.1 (constants.%tuple.2db)]
// CHECK:STDOUT:     %.loc9_21.2: @G.%tuple.type.loc8_45.1 (%tuple.type.07a) = splice_inst %tuple.elem0 [template = %.loc9_21.7 (constants.%.03e)]
// CHECK:STDOUT:     %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc9_21.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc9_21.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method.953]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc9_21.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     %.loc9_21.3: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     %tuple.elem1: ref %i32 = tuple_access %return.param, element1
// CHECK:STDOUT:     %.loc9_21.4: init %i32 to %tuple.elem1 = in_place_init %.loc9_21.3 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:     %.loc9_21.5: init @G.%tuple.type.loc8_45.2 (%tuple.type.40a) to %return.param = tuple_init (%.loc9_21.2, %.loc9_21.4) [template = %tuple.loc9_21.2 (constants.%tuple.da3)]
// CHECK:STDOUT:     %.loc9_22: init @G.%tuple.type.loc8_45.2 (%tuple.type.40a) = converted %.loc9_21.1, %.loc9_21.5 [template = %tuple.loc9_21.2 (constants.%tuple.da3)]
// CHECK:STDOUT:     return %.loc9_22 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @G(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc8_16.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc8_16.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type.loc8_25 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %x.param_patt.loc8_25.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc8_25.2 => constants.%x.patt.260
// CHECK:STDOUT:   %tuple.loc8_39 => constants.%tuple.3df
// CHECK:STDOUT:   %tuple.loc8_45 => constants.%tuple.1ef
// CHECK:STDOUT:   %tuple.type.loc8_45.1 => constants.%tuple.type.07a
// CHECK:STDOUT:   %tuple.type.loc8_45.2 => constants.%tuple.type.40a
// CHECK:STDOUT:   %.loc8_45.1 => constants.%.feb
// CHECK:STDOUT:   %pattern_type.loc8_45 => constants.%pattern_type.e92
// CHECK:STDOUT:   %return.param_patt.loc8_45.2 => constants.%return.param_patt.332
// CHECK:STDOUT:   %return.patt.loc8_30.2 => constants.%return.patt.8ca
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @G(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc8_16.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc8_16.1 => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc8_25 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt.loc8_25.2 => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt.loc8_25.2 => constants.%x.patt.e3b
// CHECK:STDOUT:   %tuple.loc8_39 => constants.%tuple.94e
// CHECK:STDOUT:   %tuple.loc8_45 => constants.%tuple.5bb
// CHECK:STDOUT:   %tuple.type.loc8_45.1 => constants.%tuple.type.e55
// CHECK:STDOUT:   %tuple.type.loc8_45.2 => constants.%tuple.type.7fb
// CHECK:STDOUT:   %.loc8_45.1 => constants.%.9c9
// CHECK:STDOUT:   %pattern_type.loc8_45 => constants.%pattern_type.1a2
// CHECK:STDOUT:   %return.param_patt.loc8_45.2 => constants.%return.param_patt.c7b
// CHECK:STDOUT:   %return.patt.loc8_30.2 => constants.%return.patt.5bc
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc8_25 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc8_30 => constants.%complete_type.935
// CHECK:STDOUT:   %.loc9_17.3 => constants.%inst.splice_block.426619.4
// CHECK:STDOUT:   %.loc9_17.4 => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc9_17.5 => <not constant>
// CHECK:STDOUT:   %tuple.type.loc9 => constants.%tuple.type.34b
// CHECK:STDOUT:   %tuple.loc9_21.1 => <not constant>
// CHECK:STDOUT:   %require_complete.loc9 => constants.%complete_type.6c4
// CHECK:STDOUT:   %.loc9_21.6 => constants.%tuple.24243e.1
// CHECK:STDOUT:   %tuple.elem0 => constants.%inst.splice_block.426619.5
// CHECK:STDOUT:   %.loc9_21.7 => <not constant>
// CHECK:STDOUT:   %tuple.loc9_21.2 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- let_class_value_of_call.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %C.elem.010: type = unbound_element_type %C, %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %C.elem.e33: type = unbound_element_type %C, %i32 [concrete]
// CHECK:STDOUT:   %.Self.frozen.e58: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [template]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.1 = wrapper_binding_pattern x, %x.param_patt.91d [template]
// CHECK:STDOUT:   %Pair.type: type = fn_type @Pair [concrete]
// CHECK:STDOUT:   %Pair: %Pair.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.98b: type = pattern_type %C [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.98b = value_binding_pattern c [concrete]
// CHECK:STDOUT:   %.a0c: type = type_of_inst @G.%.loc14_26.3 [template]
// CHECK:STDOUT:   %.33e: %.a0c = splice_inst @G.%.loc14_26.3 [template]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %struct_type.a.b.e8a: type = struct_type {.a: %.a0c, .b: Core.IntLiteral} [template]
// CHECK:STDOUT:   %struct: %struct_type.a.b.e8a = struct_value (%.33e, %int_1.5b8) [template]
// CHECK:STDOUT:   %.021: %C = splice_inst @G.%.loc14_35.3 [template]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e3b: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.053: init %tuple.type.e55 = splice_block %Pair.call {
// CHECK:STDOUT:       %.76c: %i32 = specific_inst @G.%x.ref, @G(%i32)
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %.f14: ref %tuple.type.e55 = splice_block %.863 {
// CHECK:STDOUT:         %.29d: ref %C = temporary_storage
// CHECK:STDOUT:         %.863: ref %tuple.type.e55 = class_element_access %.29d, element0
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %Pair.call: init %tuple.type.e55 to %.f14 = call %Pair.specific_fn.023a53.2(%.76c)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %struct_type.a.b.2df: type = struct_type {.a: %tuple.type.e55, .b: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.4: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.de5: %C = splice_block %.53d {
// CHECK:STDOUT:       %.ca0: %struct_type.a.b.2df = specific_inst @G.%.loc14_35.1, @G(%i32)
// CHECK:STDOUT:       %.14a: init %tuple.type.e55 = specific_inst @G.%.loc14_26.2, @G(%i32)
// CHECK:STDOUT:       %impl.elem0.0e6: %.b7a = impl_witness_access %ImplicitAs.impl_witness.a2a, element0 [concrete = %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:       %bound_method.ba1: <bound method> = bound_method @G.%int_1.loc14, %impl.elem0.0e6 [concrete = %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:       %specific_fn.ab8: <specific function> = specific_function %impl.elem0.0e6, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete = %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:       %bound_method.fd6: <bound method> = bound_method @G.%int_1.loc14, %specific_fn.ab8 [concrete = %bound_method.953]
// CHECK:STDOUT:       %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.fd6(@G.%int_1.loc14) [concrete = %int_1.0c6]
// CHECK:STDOUT:       %.a55: init %i32 = converted @G.%int_1.loc14, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = %int_1.0c6]
// CHECK:STDOUT:       %.e5a: ref %i32 = class_element_access %.29d, element1
// CHECK:STDOUT:       %.25d: init %i32 to %.e5a = in_place_init %.a55 [concrete = %int_1.0c6]
// CHECK:STDOUT:       %.eb3: init %C to %.29d = class_init (%.14a, %.25d)
// CHECK:STDOUT:       %.66a: ref %C = temporary %.29d, %.eb3
// CHECK:STDOUT:       %.53d: %C = acquire_value %.66a
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %T.patt.loc13_16.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc13_16.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %x.param_patt.loc13_25.1: @G.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc13_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc13_25.1: @G.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc13_25.1 [template = %x.patt.loc13_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13_33: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc13_18.1: type = splice_block %.loc13_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.e58]
// CHECK:STDOUT:       %.loc13_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc13_16.2: type = symbolic_binding T, 0, template [template = %T.loc13_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x.param: @G.%T.loc13_16.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc13_16.2 [template = %T.loc13_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x: @G.%T.loc13_16.1 (%T.67db0b.1) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @G(%T.loc13_16.2: type) {
// CHECK:STDOUT:   %T.patt.loc13_16.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc13_16.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc13_16.1: type = symbolic_binding T, 0, template [template = %T.loc13_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc13_16.1 [template = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt.loc13_25.2: @G.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc13_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc13_25.2: @G.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc13_25.2 [template = %x.patt.loc13_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc13_16.1 [template = %require_complete (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %.loc14_26.3: <instruction> = call_action (%Pair.ref, %x.ref), false [template]
// CHECK:STDOUT:   %.loc14_26.4: type = type_of_inst %.loc14_26.3 [template = %.loc14_26.4 (constants.%.a0c)]
// CHECK:STDOUT:   %.loc14_26.5: @G.%.loc14_26.4 (%.a0c) = splice_inst %.loc14_26.3 [template = %.loc14_26.5 (constants.%.33e)]
// CHECK:STDOUT:   %struct_type.a.b: type = struct_type {.a: @G.%.loc14_26.4 (%.a0c), .b: Core.IntLiteral} [template = %struct_type.a.b (constants.%struct_type.a.b.e8a)]
// CHECK:STDOUT:   %struct: @G.%struct_type.a.b (%struct_type.a.b.e8a) = struct_value (%.loc14_26.5, constants.%int_1.5b8) [template = %struct (constants.%struct)]
// CHECK:STDOUT:   %.loc14_35.3: <instruction> = convert_to_value_action %.loc14_35.1, constants.%C [template]
// CHECK:STDOUT:   %.loc14_35.4: %C = splice_inst %.loc14_35.3 [template = %.loc14_35.4 (constants.%.021)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @G.%T.loc13_16.1 (%T.67db0b.1)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Pair.ref: %Pair.type = name_ref Pair, file.%Pair.decl [concrete = constants.%Pair]
// CHECK:STDOUT:     %x.ref: @G.%T.loc13_16.1 (%T.67db0b.1) = name_ref x, %x
// CHECK:STDOUT:     %.loc14_26.1: type = type_of_inst %.loc14_26.3 [template = %.loc14_26.4 (constants.%.a0c)]
// CHECK:STDOUT:     %.loc14_26.2: @G.%.loc14_26.4 (%.a0c) = splice_inst %.loc14_26.3 [template = %.loc14_26.5 (constants.%.33e)]
// CHECK:STDOUT:     %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %.loc14_35.1: @G.%struct_type.a.b (%struct_type.a.b.e8a) = struct_literal (%.loc14_26.2, %int_1.loc14) [template = %struct (constants.%struct)]
// CHECK:STDOUT:     %.loc14_35.2: %C = splice_inst %.loc14_35.3 [template = %.loc14_35.4 (constants.%.021)]
// CHECK:STDOUT:     %C.ref: type = name_ref C, file.%C.decl [concrete = constants.%C]
// CHECK:STDOUT:     %c: %C = wrapper_binding c, %.loc14_35.2
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %c.patt: %pattern_type.98b = value_binding_pattern c [concrete = constants.%c.patt]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %c.ref.loc15_10: %C = name_ref c, %c
// CHECK:STDOUT:     %a.ref.loc15_11: %C.elem.010 = name_ref a, @C.%field_decl.loc4 [concrete = @C.%field_decl.loc4]
// CHECK:STDOUT:     %.loc15_11.1: ref %tuple.type.e55 = class_element_access %c.ref.loc15_10, element0
// CHECK:STDOUT:     %tuple.elem0.loc15_11: ref %i32 = tuple_access %.loc15_11.1, element0
// CHECK:STDOUT:     %.loc15_11.2: %i32 = acquire_value %tuple.elem0.loc15_11
// CHECK:STDOUT:     %tuple.elem1.loc15_11: ref %i32 = tuple_access %.loc15_11.1, element1
// CHECK:STDOUT:     %.loc15_11.3: %i32 = acquire_value %tuple.elem1.loc15_11
// CHECK:STDOUT:     %tuple.loc15_11: %tuple.type.e55 = tuple_value (%.loc15_11.2, %.loc15_11.3)
// CHECK:STDOUT:     %.loc15_11.4: %tuple.type.e55 = converted %.loc15_11.1, %tuple.loc15_11
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:     %tuple.elem0.loc15_13: %i32 = tuple_access %.loc15_11.4, element0
// CHECK:STDOUT:     %c.ref.loc15_18: %C = name_ref c, %c
// CHECK:STDOUT:     %a.ref.loc15_19: %C.elem.010 = name_ref a, @C.%field_decl.loc4 [concrete = @C.%field_decl.loc4]
// CHECK:STDOUT:     %.loc15_19.1: ref %tuple.type.e55 = class_element_access %c.ref.loc15_18, element0
// CHECK:STDOUT:     %tuple.elem0.loc15_19: ref %i32 = tuple_access %.loc15_19.1, element0
// CHECK:STDOUT:     %.loc15_19.2: %i32 = acquire_value %tuple.elem0.loc15_19
// CHECK:STDOUT:     %tuple.elem1.loc15_19: ref %i32 = tuple_access %.loc15_19.1, element1
// CHECK:STDOUT:     %.loc15_19.3: %i32 = acquire_value %tuple.elem1.loc15_19
// CHECK:STDOUT:     %tuple.loc15_19: %tuple.type.e55 = tuple_value (%.loc15_19.2, %.loc15_19.3)
// CHECK:STDOUT:     %.loc15_19.4: %tuple.type.e55 = converted %.loc15_19.1, %tuple.loc15_19
// CHECK:STDOUT:     %int_1.loc15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %tuple.elem1.loc15_21: %i32 = tuple_access %.loc15_19.4, element1
// CHECK:STDOUT:     %impl.elem1.loc15_16: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:     %bound_method.loc15_16.1: <bound method> = bound_method %tuple.elem0.loc15_13, %impl.elem1.loc15_16
// CHECK:STDOUT:     %specific_fn.loc15_16: <specific function> = specific_function %impl.elem1.loc15_16, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:     %bound_method.loc15_16.2: <bound method> = bound_method %tuple.elem0.loc15_13, %specific_fn.loc15_16
// CHECK:STDOUT:     %Int.as.AddWith.impl.Op.call.loc15_16: init %i32 = call %bound_method.loc15_16.2(%tuple.elem0.loc15_13, %tuple.elem1.loc15_21)
// CHECK:STDOUT:     %c.ref.loc15_26: %C = name_ref c, %c
// CHECK:STDOUT:     %b.ref: %C.elem.e33 = name_ref b, @C.%field_decl.loc5 [concrete = @C.%field_decl.loc5]
// CHECK:STDOUT:     %.loc15_27.1: ref %i32 = class_element_access %c.ref.loc15_26, element1
// CHECK:STDOUT:     %.loc15_27.2: %i32 = acquire_value %.loc15_27.1
// CHECK:STDOUT:     %impl.elem1.loc15_24: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:     %bound_method.loc15_24.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc15_16, %impl.elem1.loc15_24
// CHECK:STDOUT:     %specific_fn.loc15_24: <specific function> = specific_function %impl.elem1.loc15_24, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:     %bound_method.loc15_24.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc15_16, %specific_fn.loc15_24
// CHECK:STDOUT:     %.loc15_16.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc15_16
// CHECK:STDOUT:     %.loc15_16.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc15_16, %.loc15_16.1
// CHECK:STDOUT:     %Int.as.AddWith.impl.Op.call.loc15_24: init %i32 = call %bound_method.loc15_24.2(%.loc15_16.2, %.loc15_27.2)
// CHECK:STDOUT:     return %Int.as.AddWith.impl.Op.call.loc15_24
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @G(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc13_16.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc13_16.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %x.param_patt.loc13_25.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc13_25.2 => constants.%x.patt.260
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @G(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc13_16.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc13_16.1 => constants.%i32
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt.loc13_25.2 => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt.loc13_25.2 => constants.%x.patt.e3b
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.f8a
// CHECK:STDOUT:   %.loc14_26.3 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc14_26.4 => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc14_26.5 => <not constant>
// CHECK:STDOUT:   %struct_type.a.b => constants.%struct_type.a.b.2df
// CHECK:STDOUT:   %struct => <not constant>
// CHECK:STDOUT:   %.loc14_35.3 => constants.%inst.splice_block.426619.4
// CHECK:STDOUT:   %.loc14_35.4 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- var_with_destructor.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %D: type = class_type @D [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.990: <witness> = impl_witness @D.as.Copy.impl.%Copy.impl_witness_table [concrete]
// CHECK:STDOUT:   %pattern_type.d8d: type = pattern_type %D [concrete]
// CHECK:STDOUT:   %D.as.Copy.impl.Op.type: type = fn_type @D.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %D.as.Copy.impl.Op: %D.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %D, (%Copy.impl_witness.990) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.866: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Self.0e7: %Destroy.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.4e5: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Self.0e7) [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.4a0: %Destroy.WithSelf.SelfDestruct.type.4e5 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.impl_witness: <witness> = impl_witness @D.as.Destroy.impl.%Destroy.impl_witness_table [concrete]
// CHECK:STDOUT:   %Destroy.facet.101d86.1: %Destroy.type = facet_value %D, (%Destroy.impl_witness) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.937: type = fn_type @Destroy.WithSelf.SelfDestruct, @Destroy.WithSelf(%Destroy.facet.101d86.1) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.ac2: %Destroy.WithSelf.SelfDestruct.type.937 = struct_value () [concrete]
// CHECK:STDOUT:   %struct_type.n: type = struct_type {.n: %i32} [concrete]
// CHECK:STDOUT:   %complete_type.cdf: <witness> = complete_type_witness %struct_type.n [concrete]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %.Self.frozen.e58: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %T.patt.3a0592.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.2: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.4: type = pattern_type %T.67db0b.2 [template]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.4 = value_param_pattern [template]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.4 = wrapper_binding_pattern x, %x.param_patt.91d [template]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67db0b.2 [template]
// CHECK:STDOUT:   %y.patt.a54: %pattern_type.51d1c4.4 = ref_binding_pattern y [template]
// CHECK:STDOUT:   %y.var_patt.0b4: %pattern_type.51d1c4.4 = var_pattern %y.patt.a54 [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %.38e: %T.67db0b.2 = splice_inst @F.%tuple.elem0 [template]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %Destroy.assoc_type: type = assoc_entity_type @Destroy [concrete]
// CHECK:STDOUT:   %assoc2: %Destroy.assoc_type = assoc_entity element2, imports.%Core.import_ref.71d [concrete]
// CHECK:STDOUT:   %.8cb: type = type_of_inst @F.%.loc15_3.8 [template]
// CHECK:STDOUT:   %.c23: %.8cb = splice_inst @F.%.loc15_3.8 [template]
// CHECK:STDOUT:   %.57c: type = type_of_inst @F.%.loc15_3.11 [template]
// CHECK:STDOUT:   %.e63: %.57c = splice_inst @F.%.loc15_3.11 [template]
// CHECK:STDOUT:   %x.param_patt.23b: %pattern_type.d8d = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.c51: %pattern_type.d8d = wrapper_binding_pattern x, %x.param_patt.23b [concrete]
// CHECK:STDOUT:   %y.patt.c11: %pattern_type.d8d = ref_binding_pattern y [concrete]
// CHECK:STDOUT:   %y.var_patt.096: %pattern_type.d8d = var_pattern %y.patt.c11 [concrete]
// CHECK:STDOUT:   %.b54: type = fn_type_with_self_type %Copy.WithSelf.Op.type.866, %Copy.facet [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.480: init %D = splice_block %D.as.Copy.impl.Op.call {
// CHECK:STDOUT:       %.24c: %D = specific_inst @F.%x.ref, @F(%D)
// CHECK:STDOUT:       %impl.elem0.22f: %.b54 = impl_witness_access %Copy.impl_witness.990, element0 [concrete = %D.as.Copy.impl.Op]
// CHECK:STDOUT:       %bound_method.78a: <bound method> = bound_method %.24c, %impl.elem0.22f
// CHECK:STDOUT:       %.1e4ee1.2: ref %D = specific_inst @F.%y.var, @F(%D)
// CHECK:STDOUT:       %D.as.Copy.impl.Op.call: init %D to %.1e4ee1.2 = call %bound_method.78a(%.24c)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.242: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.1) [concrete]
// CHECK:STDOUT:   %.bb2: type = fn_type_with_self_type %Destroy.WithSelf.SelfDestruct.type.937, %Destroy.facet.101d86.1 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.459: <bound method> = splice_block %bound_method.d6c {
// CHECK:STDOUT:       %.1e4ee1.1: ref %D = specific_inst @F.%y.var, @F(%D)
// CHECK:STDOUT:       %impl.elem2: %.bb2 = impl_witness_access %Destroy.impl_witness, element2 [concrete = %Destroy.WithSelf.SelfDestruct.ac2]
// CHECK:STDOUT:       %bound_method.d6c: <bound method> = bound_method %.1e4ee1.1, %impl.elem2
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.specific_fn: <specific function> = specific_function %Destroy.WithSelf.SelfDestruct.ac2, @Destroy.WithSelf.SelfDestruct(%Destroy.facet.101d86.1) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.823: init %empty_tuple.type = splice_block %Destroy.WithSelf.SelfDestruct.call {
// CHECK:STDOUT:       %Destroy.facet.101d86.2: %Destroy.type = facet_value %D, (%Destroy.impl_witness) [concrete = %Destroy.facet.101d86.1]
// CHECK:STDOUT:       %.77be7d.1: %Destroy.type = converted %D, %Destroy.facet.101d86.2 [concrete = %Destroy.facet.101d86.1]
// CHECK:STDOUT:       %Destroy.facet.101d86.3: %Destroy.type = facet_value %D, (%Destroy.impl_witness) [concrete = %Destroy.facet.101d86.1]
// CHECK:STDOUT:       %.77be7d.2: %Destroy.type = converted %D, %Destroy.facet.101d86.3 [concrete = %Destroy.facet.101d86.1]
// CHECK:STDOUT:       %specific_fn: <specific function> = specific_function %impl.elem2, @Destroy.WithSelf.SelfDestruct(%Destroy.facet.101d86.1) [concrete = %Destroy.WithSelf.SelfDestruct.specific_fn]
// CHECK:STDOUT:       %bound_method.6e3: <bound method> = bound_method %.1e4ee1.1, %specific_fn
// CHECK:STDOUT:       %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %bound_method.6e3(%.1e4ee1.1)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.71d: @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct.type (%Destroy.WithSelf.SelfDestruct.type.4e5) = import_ref Core//prelude/destroy, loc{{\d+_\d+}}, loaded [symbolic = @Destroy.WithSelf.%Destroy.WithSelf.SelfDestruct (constants.%Destroy.WithSelf.SelfDestruct.4a0)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %T.patt.loc14_16.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc14_16.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:     %x.param_patt.loc14_25.1: @F.%pattern_type (%pattern_type.51d1c4.4) = value_param_pattern [template = %x.param_patt.loc14_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc14_25.1: @F.%pattern_type (%pattern_type.51d1c4.4) = wrapper_binding_pattern x, %x.param_patt.loc14_25.1 [template = %x.patt.loc14_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc14_33: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %.loc14_18.1: type = splice_block %.loc14_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.e58]
// CHECK:STDOUT:       %.loc14_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc14_16.2: type = symbolic_binding T, 0, template [template = %T.loc14_16.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %x.param: @F.%T.loc14_16.1 (%T.67db0b.2) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc14: type = name_ref T, %T.loc14_16.2 [template = %T.loc14_16.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %x: @F.%T.loc14_16.1 (%T.67db0b.2) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%T.loc14_16.2: type) {
// CHECK:STDOUT:   %T.patt.loc14_16.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc14_16.2 (constants.%T.patt.3a0592.2)]
// CHECK:STDOUT:   %T.loc14_16.1: type = symbolic_binding T, 0, template [template = %T.loc14_16.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc14_16.1 [template = %pattern_type (constants.%pattern_type.51d1c4.4)]
// CHECK:STDOUT:   %x.param_patt.loc14_25.2: @F.%pattern_type (%pattern_type.51d1c4.4) = value_param_pattern [template = %x.param_patt.loc14_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc14_25.2: @F.%pattern_type (%pattern_type.51d1c4.4) = wrapper_binding_pattern x, %x.param_patt.loc14_25.2 [template = %x.patt.loc14_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc14_16.1 [template = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %y.patt.loc15_15.2: @F.%pattern_type (%pattern_type.51d1c4.4) = ref_binding_pattern y [template = %y.patt.loc15_15.2 (constants.%y.patt.a54)]
// CHECK:STDOUT:   %y.var_patt.loc15_3.2: @F.%pattern_type (%pattern_type.51d1c4.4) = var_pattern %y.patt.loc15_15.2 [template = %y.var_patt.loc15_3.2 (constants.%y.var_patt.0b4)]
// CHECK:STDOUT:   %.loc15_3.6: %tuple.type.f7a = initialize_action %x.ref, %T.loc14_16.1, %y.var, false [template]
// CHECK:STDOUT:   %tuple.elem0: <instruction> = tuple_access %.loc15_3.6, element0 [template]
// CHECK:STDOUT:   %.loc15_3.7: @F.%T.loc14_16.1 (%T.67db0b.2) = splice_inst %tuple.elem0 [template = %.loc15_3.7 (constants.%.38e)]
// CHECK:STDOUT:   %.loc15_3.8: <instruction> = compound_member_access_action %y.var, constants.%assoc2 [template]
// CHECK:STDOUT:   %.loc15_3.9: type = type_of_inst %.loc15_3.8 [template = %.loc15_3.9 (constants.%.8cb)]
// CHECK:STDOUT:   %.loc15_3.10: @F.%.loc15_3.9 (%.8cb) = splice_inst %.loc15_3.8 [template = %.loc15_3.10 (constants.%.c23)]
// CHECK:STDOUT:   %.loc15_3.11: <instruction> = call_action (%.loc15_3.3), true [template]
// CHECK:STDOUT:   %.loc15_3.12: type = type_of_inst %.loc15_3.11 [template = %.loc15_3.12 (constants.%.57c)]
// CHECK:STDOUT:   %.loc15_3.13: @F.%.loc15_3.12 (%.57c) = splice_inst %.loc15_3.11 [template = %.loc15_3.13 (constants.%.e63)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @F.%T.loc14_16.1 (%T.67db0b.2)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %y.var: ref @F.%T.loc14_16.1 (%T.67db0b.2) = var_storage %y.var_patt.loc15_3.1
// CHECK:STDOUT:     %x.ref: @F.%T.loc14_16.1 (%T.67db0b.2) = name_ref x, %x
// CHECK:STDOUT:     %.loc15_3.1: @F.%T.loc14_16.1 (%T.67db0b.2) = splice_inst %tuple.elem0 [template = %.loc15_3.7 (constants.%.38e)]
// CHECK:STDOUT:     assign %y.var, %.loc15_3.1
// CHECK:STDOUT:     %T.ref.loc15: type = name_ref T, %T.loc14_16.2 [template = %T.loc14_16.1 (constants.%T.67db0b.2)]
// CHECK:STDOUT:     %y: ref @F.%T.loc14_16.1 (%T.67db0b.2) = wrapper_binding y, %y.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %y.patt.loc15_15.1: @F.%pattern_type (%pattern_type.51d1c4.4) = ref_binding_pattern y [template = %y.patt.loc15_15.2 (constants.%y.patt.a54)]
// CHECK:STDOUT:       %y.var_patt.loc15_3.1: @F.%pattern_type (%pattern_type.51d1c4.4) = var_pattern %y.patt.loc15_15.1 [template = %y.var_patt.loc15_3.2 (constants.%y.var_patt.0b4)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:     %bound_method.loc16_11.1: <bound method> = bound_method %int_0, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc16_11.2: <bound method> = bound_method %int_0, %specific_fn [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc16_11.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc16: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:     %.loc15_3.2: type = type_of_inst %.loc15_3.8 [template = %.loc15_3.9 (constants.%.8cb)]
// CHECK:STDOUT:     %.loc15_3.3: @F.%.loc15_3.9 (%.8cb) = splice_inst %.loc15_3.8 [template = %.loc15_3.10 (constants.%.c23)]
// CHECK:STDOUT:     %.loc15_3.4: type = type_of_inst %.loc15_3.11 [template = %.loc15_3.12 (constants.%.57c)]
// CHECK:STDOUT:     %.loc15_3.5: @F.%.loc15_3.12 (%.57c) = splice_inst %.loc15_3.11 [template = %.loc15_3.13 (constants.%.e63)]
// CHECK:STDOUT:     return %.loc16
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%T.67db0b.2) {
// CHECK:STDOUT:   %T.patt.loc14_16.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc14_16.1 => constants.%T.67db0b.2
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.4
// CHECK:STDOUT:   %x.param_patt.loc14_25.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc14_25.2 => constants.%x.patt.260
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%D) {
// CHECK:STDOUT:   %T.patt.loc14_16.2 => constants.%T.patt.3a0592.2
// CHECK:STDOUT:   %T.loc14_16.1 => constants.%D
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.d8d
// CHECK:STDOUT:   %x.param_patt.loc14_25.2 => constants.%x.param_patt.23b
// CHECK:STDOUT:   %x.patt.loc14_25.2 => constants.%x.patt.c51
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.cdf
// CHECK:STDOUT:   %y.patt.loc15_15.2 => constants.%y.patt.c11
// CHECK:STDOUT:   %y.var_patt.loc15_3.2 => constants.%y.var_patt.096
// CHECK:STDOUT:   %.loc15_3.6 => constants.%tuple.242
// CHECK:STDOUT:   %tuple.elem0 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc15_3.7 => <not constant>
// CHECK:STDOUT:   %.loc15_3.8 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc15_3.9 => <bound method>
// CHECK:STDOUT:   %.loc15_3.10 => <not constant>
// CHECK:STDOUT:   %.loc15_3.11 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc15_3.12 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc15_3.13 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- destructure_param.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen.e58: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67d [template]
// CHECK:STDOUT:   %p.param_patt.e58: %pattern_type.51d1c4.1 = value_param_pattern [template]
// CHECK:STDOUT:   %p.patt.0ba: %pattern_type.51d1c4.1 = wrapper_binding_pattern p, %p.param_patt.e58 [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Sum.type: type = fn_type @Sum [concrete]
// CHECK:STDOUT:   %Sum: %Sum.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %T.67d [template]
// CHECK:STDOUT:   %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %.d82: %pattern_type.394 = tuple_pattern (%a.patt, %b.patt) [concrete]
// CHECK:STDOUT:   %.be7: %tuple.type.e55 = splice_inst @Sum.%.loc5_22.3 [template]
// CHECK:STDOUT:   %tuple.elem0: %i32 = tuple_access %.be7, element0 [template]
// CHECK:STDOUT:   %tuple.elem1: %i32 = tuple_access %.be7, element1 [template]
// CHECK:STDOUT:   %.6ec818.1: %i32 = splice_inst @Sum.%.loc5_26.3 [template]
// CHECK:STDOUT:   %.6ec818.2: %i32 = splice_inst @Sum.%.loc5_26.5 [template]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %p.param_patt.e62: %pattern_type.394 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.07f: %pattern_type.394 = wrapper_binding_pattern p, %p.param_patt.e62 [concrete]
// CHECK:STDOUT:   %complete_type.6c4: <witness> = complete_type_witness %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %inst.specific_inst.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.f95: %tuple.type.e55 = specific_inst @Sum.%p.ref, @Sum(%tuple.type.e55)
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.specific_inst.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.fbb: %i32 = specific_inst @Sum.%tuple.elem0.loc5_26.1, @Sum(%tuple.type.e55)
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %inst.specific_inst.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.1ec: %i32 = specific_inst @Sum.%tuple.elem1.loc5_26.1, @Sum(%tuple.type.e55)
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Sum.decl: %Sum.type = fn_decl @Sum [concrete = constants.%Sum] {
// CHECK:STDOUT:     %T.patt.loc4_18.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_18.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:     %p.param_patt.loc4_27.1: @Sum.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %p.param_patt.loc4_27.2 (constants.%p.param_patt.e58)]
// CHECK:STDOUT:     %p.patt.loc4_27.1: @Sum.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern p, %p.param_patt.loc4_27.1 [template = %p.patt.loc4_27.2 (constants.%p.patt.0ba)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc4 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc4: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_35: Core.Form = init_form %i32.loc4 [concrete = constants.%.795]
// CHECK:STDOUT:     %.loc4_20.1: type = splice_block %.loc4_20.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.e58]
// CHECK:STDOUT:       %.loc4_20.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_18.2: type = symbolic_binding T, 0, template [template = %T.loc4_18.1 (constants.%T.67d)]
// CHECK:STDOUT:     %p.param: @Sum.%T.loc4_18.1 (%T.67d) = value_param call_param0
// CHECK:STDOUT:     %T.ref: type = name_ref T, %T.loc4_18.2 [template = %T.loc4_18.1 (constants.%T.67d)]
// CHECK:STDOUT:     %p: @Sum.%T.loc4_18.1 (%T.67d) = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Sum(%T.loc4_18.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_18.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_18.2 (constants.%T.patt.3a0)]
// CHECK:STDOUT:   %T.loc4_18.1: type = symbolic_binding T, 0, template [template = %T.loc4_18.1 (constants.%T.67d)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %T.loc4_18.1 [template = %pattern_type (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %p.param_patt.loc4_27.2: @Sum.%pattern_type (%pattern_type.51d1c4.1) = value_param_pattern [template = %p.param_patt.loc4_27.2 (constants.%p.param_patt.e58)]
// CHECK:STDOUT:   %p.patt.loc4_27.2: @Sum.%pattern_type (%pattern_type.51d1c4.1) = wrapper_binding_pattern p, %p.param_patt.loc4_27.2 [template = %p.patt.loc4_27.2 (constants.%p.patt.0ba)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %T.loc4_18.1 [template = %require_complete (constants.%require_complete.944)]
// CHECK:STDOUT:   %.loc5_22.3: <instruction> = convert_action %p.ref, constants.%tuple.type.e55, element2 [template]
// CHECK:STDOUT:   %.loc5_22.4: %tuple.type.e55 = splice_inst %.loc5_22.3 [template = %.loc5_22.4 (constants.%.be7)]
// CHECK:STDOUT:   %tuple.elem0.loc5_26.2: %i32 = tuple_access %.loc5_22.4, element0 [template = %tuple.elem0.loc5_26.2 (constants.%tuple.elem0)]
// CHECK:STDOUT:   %tuple.elem1.loc5_26.2: %i32 = tuple_access %.loc5_22.4, element1 [template = %tuple.elem1.loc5_26.2 (constants.%tuple.elem1)]
// CHECK:STDOUT:   %.loc5_26.3: <instruction> = convert_to_value_action %tuple.elem0.loc5_26.1, constants.%i32 [template]
// CHECK:STDOUT:   %.loc5_26.4: %i32 = splice_inst %.loc5_26.3 [template = %.loc5_26.4 (constants.%.6ec818.1)]
// CHECK:STDOUT:   %.loc5_26.5: <instruction> = convert_to_value_action %tuple.elem1.loc5_26.1, constants.%i32 [template]
// CHECK:STDOUT:   %.loc5_26.6: %i32 = splice_inst %.loc5_26.5 [template = %.loc5_26.6 (constants.%.6ec818.2)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%p.param: @Sum.%T.loc4_18.1 (%T.67d)) -> out %return.param: %i32 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %p.ref: @Sum.%T.loc4_18.1 (%T.67d) = name_ref p, %p
// CHECK:STDOUT:     %.loc5_22.1: %tuple.type.e55 = splice_inst %.loc5_22.3 [template = %.loc5_22.4 (constants.%.be7)]
// CHECK:STDOUT:     %tuple.elem0.loc5_26.1: %i32 = tuple_access %.loc5_22.1, element0 [template = %tuple.elem0.loc5_26.2 (constants.%tuple.elem0)]
// CHECK:STDOUT:     %tuple.elem1.loc5_26.1: %i32 = tuple_access %.loc5_22.1, element1 [template = %tuple.elem1.loc5_26.2 (constants.%tuple.elem1)]
// CHECK:STDOUT:     %.loc5_26.1: %i32 = splice_inst %.loc5_26.3 [template = %.loc5_26.4 (constants.%.6ec818.1)]
// CHECK:STDOUT:     %i32.loc5_11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %a: %i32 = wrapper_binding a, %.loc5_26.1
// CHECK:STDOUT:     %.loc5_26.2: %i32 = splice_inst %.loc5_26.5 [template = %.loc5_26.6 (constants.%.6ec818.2)]
// CHECK:STDOUT:     %i32.loc5_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %b: %i32 = wrapper_binding b, %.loc5_26.2
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:       %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:       %.loc5_22.2: %pattern_type.394 = tuple_pattern (%a.patt, %b.patt) [concrete = constants.%.d82]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a.ref: %i32 = name_ref a, %a
// CHECK:STDOUT:     %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:     %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:     %bound_method.loc6_12.1: <bound method> = bound_method %a.ref, %impl.elem1
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:     %bound_method.loc6_12.2: <bound method> = bound_method %a.ref, %specific_fn
// CHECK:STDOUT:     %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc6_12.2(%a.ref, %b.ref)
// CHECK:STDOUT:     return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Sum(constants.%T.67d) {
// CHECK:STDOUT:   %T.patt.loc4_18.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc4_18.1 => constants.%T.67d
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %p.param_patt.loc4_27.2 => constants.%p.param_patt.e58
// CHECK:STDOUT:   %p.patt.loc4_27.2 => constants.%p.patt.0ba
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Sum(constants.%tuple.type.e55) {
// CHECK:STDOUT:   %T.patt.loc4_18.2 => constants.%T.patt.3a0
// CHECK:STDOUT:   %T.loc4_18.1 => constants.%tuple.type.e55
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.394
// CHECK:STDOUT:   %p.param_patt.loc4_27.2 => constants.%p.param_patt.e62
// CHECK:STDOUT:   %p.patt.loc4_27.2 => constants.%p.patt.07f
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.6c4
// CHECK:STDOUT:   %.loc5_22.3 => constants.%inst.specific_inst.426619.1
// CHECK:STDOUT:   %.loc5_22.4 => <not constant>
// CHECK:STDOUT:   %tuple.elem0.loc5_26.2 => <not constant>
// CHECK:STDOUT:   %tuple.elem1.loc5_26.2 => <not constant>
// CHECK:STDOUT:   %.loc5_26.3 => constants.%inst.specific_inst.426619.2
// CHECK:STDOUT:   %.loc5_26.4 => <not constant>
// CHECK:STDOUT:   %.loc5_26.5 => constants.%inst.specific_inst.426619.3
// CHECK:STDOUT:   %.loc5_26.6 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- return_tuple_constant_element.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %T.patt.3a0592.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template]
// CHECK:STDOUT:   %T.67db0b.1: type = symbolic_binding T, 0, template [template]
// CHECK:STDOUT:   %pattern_type.51d1c4.1: type = pattern_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %x.param_patt.91d: %pattern_type.51d1c4.1 = value_param_pattern [template]
// CHECK:STDOUT:   %x.patt.260: %pattern_type.51d1c4.1 = wrapper_binding_pattern x, %x.param_patt.91d [template]
// CHECK:STDOUT:   %tuple.type.693: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.3df: %tuple.type.693 = tuple_value (%T.67db0b.1, %T.67db0b.1) [template]
// CHECK:STDOUT:   %tuple.type.07a: type = tuple_type (%T.67db0b.1, %T.67db0b.1) [template]
// CHECK:STDOUT:   %.ce8b: Core.Form = init_form %tuple.type.07a [template]
// CHECK:STDOUT:   %pattern_type.c3f: type = pattern_type %tuple.type.07a [template]
// CHECK:STDOUT:   %return.param_patt.e22: %pattern_type.c3f = out_param_pattern [template]
// CHECK:STDOUT:   %return.patt.1a0: %pattern_type.c3f = return_slot_pattern %return.param_patt.e22, %tuple.type.07a [template]
// CHECK:STDOUT:   %M.type: type = fn_type @M [concrete]
// CHECK:STDOUT:   %M: %M.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.1: <witness> = require_complete_type %T.67db0b.1 [template]
// CHECK:STDOUT:   %require_complete.22a: <witness> = require_complete_type %tuple.type.07a [template]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %tuple.type.f3b: type = tuple_type (%T.67db0b.1, Core.IntLiteral) [template]
// CHECK:STDOUT:   %tuple.type.f7a: type = tuple_type (<instruction>) [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.ac2: ref <instruction> = splice_block %tuple.elem0 {
// CHECK:STDOUT:       %tuple.elem0: ref @M.%T.loc4_16.1 (%T.67db0b.1) = tuple_access @M.%return.param, element0
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.b669fb.1: %T.67db0b.1 = splice_inst @M.%tuple.elem0.loc5_15.1 [template]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.7a3: ref <instruction> = splice_block %tuple.elem1 {
// CHECK:STDOUT:       %tuple.elem1: ref @M.%T.loc4_16.1 (%T.67db0b.1) = tuple_access @M.%return.param, element1
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.b669fb.2: %T.67db0b.1 = splice_inst @M.%tuple.elem0.loc5_15.2 [template]
// CHECK:STDOUT:   %tuple.8e4: %tuple.type.07a = tuple_value (%.b669fb.1, %.b669fb.2) [template]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.94e: %tuple.type.693 = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %.c11: Core.Form = init_form %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %return.param_patt.a90: %pattern_type.394 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.2ed: %pattern_type.394 = return_slot_pattern %return.param_patt.a90, %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %complete_type.f8a: <witness> = complete_type_witness %i32.builtin [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt.cee: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e3b: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt.cee [concrete]
// CHECK:STDOUT:   %complete_type.6c4: <witness> = complete_type_witness %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %tuple.type.66e: type = tuple_type (%i32, Core.IntLiteral) [concrete]
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
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.46b: init %i32 = splice_block %.e13 {
// CHECK:STDOUT:       %.968: %i32 = specific_inst @M.%x.ref, @M(%i32)
// CHECK:STDOUT:       %impl.elem0.882: %.737 = impl_witness_access %Copy.impl_witness.b51, element0 [concrete = %Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:       %bound_method.906: <bound method> = bound_method %.968, %impl.elem0.882
// CHECK:STDOUT:       %specific_fn.96a: <specific function> = specific_function %impl.elem0.882, @Int.as.Copy.impl.Op(%int_32) [concrete = %Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:       %bound_method.875: <bound method> = bound_method %.968, %specific_fn.96a
// CHECK:STDOUT:       %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.875(%.968)
// CHECK:STDOUT:       %tuple.elem0: ref @M.%T.loc4_16.1 (%T.67db0b.1) = tuple_access @M.%return.param, element0
// CHECK:STDOUT:       %.11a: ref %i32 = specific_inst %tuple.elem0, @M(%i32)
// CHECK:STDOUT:       %.e13: init %i32 to %.11a = in_place_init %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.1: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.3) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.4: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.8d0: init %i32 = splice_block %.a11 [concrete = %int_1.0c6] {
// CHECK:STDOUT:       %impl.elem0.0e6: %.b7a = impl_witness_access %ImplicitAs.impl_witness.a2a, element0 [concrete = %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:       %bound_method.ba1: <bound method> = bound_method %int_1.5b8, %impl.elem0.0e6 [concrete = %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:       %specific_fn.ab8: <specific function> = specific_function %impl.elem0.0e6, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete = %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:       %bound_method.fd6: <bound method> = bound_method %int_1.5b8, %specific_fn.ab8 [concrete = %bound_method.953]
// CHECK:STDOUT:       %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.fd6(%int_1.5b8) [concrete = %int_1.0c6]
// CHECK:STDOUT:       %tuple.elem1: ref @M.%T.loc4_16.1 (%T.67db0b.1) = tuple_access @M.%return.param, element1
// CHECK:STDOUT:       %.fce: ref %i32 = specific_inst %tuple.elem1, @M(%i32)
// CHECK:STDOUT:       %.a11: init %i32 to %.fce = in_place_init %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = %int_1.0c6]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.24243e.2: %tuple.type.f7a = tuple_value (%inst.splice_block.426619.4) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %M.decl: %M.type = fn_decl @M [concrete = constants.%M] {
// CHECK:STDOUT:     %T.patt.loc4_16.1: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_16.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:     %x.param_patt.loc4_25.1: @M.%pattern_type.loc4_25 (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc4_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:     %x.patt.loc4_25.1: @M.%pattern_type.loc4_25 (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc4_25.1 [template = %x.patt.loc4_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:     %return.param_patt.loc4_38.1: @M.%pattern_type.loc4_38 (%pattern_type.c3f) = out_param_pattern [template = %return.param_patt.loc4_38.2 (constants.%return.param_patt.e22)]
// CHECK:STDOUT:     %return.patt.loc4_30.1: @M.%pattern_type.loc4_38 (%pattern_type.c3f) = return_slot_pattern %return.param_patt.loc4_38.1, %.loc4_38.3 [template = %return.patt.loc4_30.2 (constants.%return.patt.1a0)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.ref.loc4_34: type = name_ref T, %T.loc4_16.2 [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %T.ref.loc4_37: type = name_ref T, %T.loc4_16.2 [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %.loc4_38.2: %tuple.type.693 = tuple_literal (%T.ref.loc4_34, %T.ref.loc4_37) [template = %tuple.loc4 (constants.%tuple.3df)]
// CHECK:STDOUT:     %.loc4_38.3: type = converted %.loc4_38.2, constants.%tuple.type.07a [template = %tuple.type.loc4 (constants.%tuple.type.07a)]
// CHECK:STDOUT:     %.loc4_38.4: Core.Form = init_form %.loc4_38.3 [template = %.loc4_38.1 (constants.%.ce8b)]
// CHECK:STDOUT:     %.loc4_18.1: type = splice_block %.loc4_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_16.2: type = symbolic_binding T, 0, template [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x.param: @M.%T.loc4_16.1 (%T.67db0b.1) = value_param call_param0
// CHECK:STDOUT:     %T.ref.loc4_27: type = name_ref T, %T.loc4_16.2 [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:     %x: @M.%T.loc4_16.1 (%T.67db0b.1) = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref @M.%tuple.type.loc4 (%tuple.type.07a) = out_param call_param1
// CHECK:STDOUT:     %return: ref @M.%tuple.type.loc4 (%tuple.type.07a) = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @M(%T.loc4_16.2: type) {
// CHECK:STDOUT:   %T.patt.loc4_16.2: %pattern_type.9a5 = symbolic_binding_pattern T, 0, template [template = %T.patt.loc4_16.2 (constants.%T.patt.3a0592.1)]
// CHECK:STDOUT:   %T.loc4_16.1: type = symbolic_binding T, 0, template [template = %T.loc4_16.1 (constants.%T.67db0b.1)]
// CHECK:STDOUT:   %pattern_type.loc4_25: type = pattern_type %T.loc4_16.1 [template = %pattern_type.loc4_25 (constants.%pattern_type.51d1c4.1)]
// CHECK:STDOUT:   %x.param_patt.loc4_25.2: @M.%pattern_type.loc4_25 (%pattern_type.51d1c4.1) = value_param_pattern [template = %x.param_patt.loc4_25.2 (constants.%x.param_patt.91d)]
// CHECK:STDOUT:   %x.patt.loc4_25.2: @M.%pattern_type.loc4_25 (%pattern_type.51d1c4.1) = wrapper_binding_pattern x, %x.param_patt.loc4_25.2 [template = %x.patt.loc4_25.2 (constants.%x.patt.260)]
// CHECK:STDOUT:   %tuple.loc4: %tuple.type.693 = tuple_value (%T.loc4_16.1, %T.loc4_16.1) [template = %tuple.loc4 (constants.%tuple.3df)]
// CHECK:STDOUT:   %tuple.type.loc4: type = tuple_type (%T.loc4_16.1, %T.loc4_16.1) [template = %tuple.type.loc4 (constants.%tuple.type.07a)]
// CHECK:STDOUT:   %.loc4_38.1: Core.Form = init_form %tuple.type.loc4 [template = %.loc4_38.1 (constants.%.ce8b)]
// CHECK:STDOUT:   %pattern_type.loc4_38: type = pattern_type %tuple.type.loc4 [template = %pattern_type.loc4_38 (constants.%pattern_type.c3f)]
// CHECK:STDOUT:   %return.param_patt.loc4_38.2: @M.%pattern_type.loc4_38 (%pattern_type.c3f) = out_param_pattern [template = %return.param_patt.loc4_38.2 (constants.%return.param_patt.e22)]
// CHECK:STDOUT:   %return.patt.loc4_30.2: @M.%pattern_type.loc4_38 (%pattern_type.c3f) = return_slot_pattern %return.param_patt.loc4_38.2, %tuple.type.loc4 [template = %return.patt.loc4_30.2 (constants.%return.patt.1a0)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_25: <witness> = require_complete_type %T.loc4_16.1 [template = %require_complete.loc4_25 (constants.%require_complete.9443dd.1)]
// CHECK:STDOUT:   %require_complete.loc4_30: <witness> = require_complete_type %tuple.type.loc4 [template = %require_complete.loc4_30 (constants.%require_complete.22a)]
// CHECK:STDOUT:   %tuple.type.loc5: type = tuple_type (%T.loc4_16.1, Core.IntLiteral) [template = %tuple.type.loc5 (constants.%tuple.type.f3b)]
// CHECK:STDOUT:   %.loc5_15.5: %tuple.type.f7a = initialize_action %x.ref, %T.loc4_16.1, constants.%inst.splice_block.426619.1, true [template]
// CHECK:STDOUT:   %tuple.elem0.loc5_15.1: <instruction> = tuple_access %.loc5_15.5, element0 [template]
// CHECK:STDOUT:   %.loc5_15.6: @M.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5_15.1 [template = %.loc5_15.6 (constants.%.b669fb.1)]
// CHECK:STDOUT:   %.loc5_15.7: %tuple.type.f7a = initialize_action %int_1, %T.loc4_16.1, constants.%inst.splice_block.426619.2, true [template]
// CHECK:STDOUT:   %tuple.elem0.loc5_15.2: <instruction> = tuple_access %.loc5_15.7, element0 [template]
// CHECK:STDOUT:   %.loc5_15.8: @M.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5_15.2 [template = %.loc5_15.8 (constants.%.b669fb.2)]
// CHECK:STDOUT:   %tuple.loc5: @M.%tuple.type.loc4 (%tuple.type.07a) = tuple_value (%.loc5_15.6, %.loc5_15.8) [template = %tuple.loc5 (constants.%tuple.8e4)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @M.%T.loc4_16.1 (%T.67db0b.1)) -> out %return.param: @M.%tuple.type.loc4 (%tuple.type.07a) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %x.ref: @M.%T.loc4_16.1 (%T.67db0b.1) = name_ref x, %x
// CHECK:STDOUT:     %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:     %.loc5_15.1: @M.%tuple.type.loc5 (%tuple.type.f3b) = tuple_literal (%x.ref, %int_1)
// CHECK:STDOUT:     %.loc5_15.2: @M.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5_15.1 [template = %.loc5_15.6 (constants.%.b669fb.1)]
// CHECK:STDOUT:     %.loc5_15.3: @M.%T.loc4_16.1 (%T.67db0b.1) = splice_inst %tuple.elem0.loc5_15.2 [template = %.loc5_15.8 (constants.%.b669fb.2)]
// CHECK:STDOUT:     %.loc5_15.4: init @M.%tuple.type.loc4 (%tuple.type.07a) to %return.param = tuple_init (%.loc5_15.2, %.loc5_15.3) [template = %tuple.loc5 (constants.%tuple.8e4)]
// CHECK:STDOUT:     %.loc5_16: init @M.%tuple.type.loc4 (%tuple.type.07a) = converted %.loc5_15.1, %.loc5_15.4 [template = %tuple.loc5 (constants.%tuple.8e4)]
// CHECK:STDOUT:     return %.loc5_16 to %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @M(constants.%T.67db0b.1) {
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%T.67db0b.1
// CHECK:STDOUT:   %pattern_type.loc4_25 => constants.%pattern_type.51d1c4.1
// CHECK:STDOUT:   %x.param_patt.loc4_25.2 => constants.%x.param_patt.91d
// CHECK:STDOUT:   %x.patt.loc4_25.2 => constants.%x.patt.260
// CHECK:STDOUT:   %tuple.loc4 => constants.%tuple.3df
// CHECK:STDOUT:   %tuple.type.loc4 => constants.%tuple.type.07a
// CHECK:STDOUT:   %.loc4_38.1 => constants.%.ce8b
// CHECK:STDOUT:   %pattern_type.loc4_38 => constants.%pattern_type.c3f
// CHECK:STDOUT:   %return.param_patt.loc4_38.2 => constants.%return.param_patt.e22
// CHECK:STDOUT:   %return.patt.loc4_30.2 => constants.%return.patt.1a0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @M(constants.%i32) {
// CHECK:STDOUT:   %T.patt.loc4_16.2 => constants.%T.patt.3a0592.1
// CHECK:STDOUT:   %T.loc4_16.1 => constants.%i32
// CHECK:STDOUT:   %pattern_type.loc4_25 => constants.%pattern_type.6b6
// CHECK:STDOUT:   %x.param_patt.loc4_25.2 => constants.%x.param_patt.cee
// CHECK:STDOUT:   %x.patt.loc4_25.2 => constants.%x.patt.e3b
// CHECK:STDOUT:   %tuple.loc4 => constants.%tuple.94e
// CHECK:STDOUT:   %tuple.type.loc4 => constants.%tuple.type.e55
// CHECK:STDOUT:   %.loc4_38.1 => constants.%.c11
// CHECK:STDOUT:   %pattern_type.loc4_38 => constants.%pattern_type.394
// CHECK:STDOUT:   %return.param_patt.loc4_38.2 => constants.%return.param_patt.a90
// CHECK:STDOUT:   %return.patt.loc4_30.2 => constants.%return.patt.2ed
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc4_25 => constants.%complete_type.f8a
// CHECK:STDOUT:   %require_complete.loc4_30 => constants.%complete_type.6c4
// CHECK:STDOUT:   %tuple.type.loc5 => constants.%tuple.type.66e
// CHECK:STDOUT:   %.loc5_15.5 => constants.%tuple.24243e.1
// CHECK:STDOUT:   %tuple.elem0.loc5_15.1 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc5_15.6 => <not constant>
// CHECK:STDOUT:   %.loc5_15.7 => constants.%tuple.24243e.2
// CHECK:STDOUT:   %tuple.elem0.loc5_15.2 => constants.%inst.splice_block.426619.4
// CHECK:STDOUT:   %.loc5_15.8 => constants.%int_1.0c6
// CHECK:STDOUT:   %tuple.loc5 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
