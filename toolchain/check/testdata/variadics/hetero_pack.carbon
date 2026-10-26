// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/hetero_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/hetero_pack.carbon

// --- call.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

//@dump-sem-ir-begin
fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}
//@dump-sem-ir-end

fn Call(a: A, b: B) {
  //@dump-sem-ir-begin
  ForEach(a, b, a);
  ForEach();
  //@dump-sem-ir-end
}

// --- type_pack.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Count[... each T: type](... unused each x: each T) {}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  Count(1 as i64, true);
  Count();
  //@dump-sem-ir-end
}

// --- forward.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

fn ForEach[... each T: Code](... unused each x: each T) {}

//@dump-sem-ir-begin
fn Forward[... each U: Code](... each y: each U) {
  ForEach(... each y);
}
//@dump-sem-ir-end

// --- method.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class C {
  fn F[... each T: Code](unused self, ... unused each x: each T) {}
}

fn Call(c: C, a: A) {
  //@dump-sem-ir-begin
  c.F(a, a);
  //@dump-sem-ir-end
}

// --- qualified_member.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

fn Consume(x: i64);

//@dump-sem-ir-begin
fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.(Code.Get)());
}
//@dump-sem-ir-end

// --- template_outer.carbon
library "[[@TEST_NAME]]";

interface HasV {
  fn V(self) -> i64;
}

class G {
  var n: i64;
}

impl i64 as HasV {
  fn V(self) -> i64 { return self; }
}

impl bool as HasV {
  fn V(unused self) -> i64 { return 10; }
}

fn Consume(n: i64, v: i64);

//@dump-sem-ir-begin
fn F[template U: type, ... each T: HasV](u: U, ... each x: each T) {
  ... Consume(u.n, each x.V());
}
//@dump-sem-ir-end

fn Call(g: G) {
  F(g, 1 as i64, true);
}

// --- traits.h

template<typename T> struct Traits {
  static constexpr int size = sizeof(T);
};

// --- cpp_template_outer.carbon
library "[[@TEST_NAME]]";

import Cpp library "traits.h";

fn One[V: type](unused v: V) -> i32 { return 1; }

fn Consume(n: i32, m: i32);

//@dump-sem-ir-begin
fn F[U: type, ... each T: type](unused u: U, ... each x: each T) {
  ... Consume(Cpp.Traits(U).size, One(each x));
}
//@dump-sem-ir-end

fn Call() {
  F(1 as i64, true, 2 as i32);
}

// CHECK:STDOUT: --- call.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Code.type: type = facet_type <@Code> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Code.assoc_type: type = assoc_entity_type @Code [concrete]
// CHECK:STDOUT:   %assoc0.b5d: %Code.assoc_type = assoc_entity element0, @Code.WithSelf.%Code.WithSelf.Get.decl [concrete]
// CHECK:STDOUT:   %A: type = class_type @A [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %Code.impl_witness.b31: <witness> = impl_witness @A.as.Code.impl.%Code.impl_witness_table [concrete]
// CHECK:STDOUT:   %Code.facet.cd0: %Code.type = facet_value %A, (%Code.impl_witness.b31) [concrete]
// CHECK:STDOUT:   %ptr.c28: type = ptr_type %empty_struct_type [concrete]
// CHECK:STDOUT:   %B: type = class_type @B [concrete]
// CHECK:STDOUT:   %Code.impl_witness.b20: <witness> = impl_witness @B.as.Code.impl.%Code.impl_witness_table [concrete]
// CHECK:STDOUT:   %Code.facet.a43: %Code.type = facet_value %B, (%Code.impl_witness.b20) [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.104: type = pack_type %Code.type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.2ee: type = pattern_type %pack_type.104 [symbolic]
// CHECK:STDOUT:   %T.patt.003: %pattern_type.2ee = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.104 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.cc3: %pattern_type.2ee = pack_expansion_pattern %T.patt.003, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.3c6: %Code.type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %as_type.0f9: type = facet_access_type %.3c6 [symbolic]
// CHECK:STDOUT:   %pack_type.6c6: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.2b9: type = pattern_type %pack_type.6c6 [symbolic]
// CHECK:STDOUT:   %x.param_patt.2a2: %pattern_type.2b9 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.27d: %pattern_type.2b9 = wrapper_binding_pattern x, %x.param_patt.2a2 [symbolic]
// CHECK:STDOUT:   %.e9e: %pattern_type.2b9 = pack_expansion_pattern %x.patt.27d, invalid [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.aa7: <witness> = require_complete_type %pack_type.6c6 [symbolic]
// CHECK:STDOUT:   %require_complete.d18: <witness> = require_complete_type %as_type.0f9 [symbolic]
// CHECK:STDOUT:   %Code.WithSelf.Get.type.099: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.3c6) [symbolic]
// CHECK:STDOUT:   %Code.lookup_impl_witness.57d: <witness> = lookup_impl_witness %.3c6, @Code [symbolic]
// CHECK:STDOUT:   %.131: type = fn_type_with_self_type %Code.WithSelf.Get.type.099, %.3c6 [symbolic]
// CHECK:STDOUT:   %impl.elem0.5c5: %.131 = impl_witness_access %Code.lookup_impl_witness.57d, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.f5a: <specific function> = specific_impl_function %impl.elem0.5c5, @Code.WithSelf.Get(%.3c6) [symbolic]
// CHECK:STDOUT:   %tuple.type.05e: type = tuple_type (%A, %B, %A) [concrete]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %pack_type.043: type = pack_type type, %int_3 [concrete]
// CHECK:STDOUT:   %.9eb: %pack_type.043 = pack_value (%A, %B, %A) [concrete]
// CHECK:STDOUT:   %pack_type.7e3: type = pack_type %Code.type, %int_3 [concrete]
// CHECK:STDOUT:   %.dcf: %pack_type.7e3 = pack_value (%Code.facet.cd0, %Code.facet.a43, %Code.facet.cd0) [concrete]
// CHECK:STDOUT:   %pattern_type.b85: type = pattern_type %pack_type.7e3 [concrete]
// CHECK:STDOUT:   %T.patt.198: %pattern_type.b85 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.81e: %pattern_type.b85 = pack_expansion_pattern %T.patt.198, %arity.patt [symbolic]
// CHECK:STDOUT:   %.fbc: %Code.type = pack_element %.dcf, %.4ee [symbolic]
// CHECK:STDOUT:   %as_type.cb9: type = facet_access_type %.fbc [symbolic]
// CHECK:STDOUT:   %pack_type.e98: type = pack_type %.dcf, %int_3 [concrete]
// CHECK:STDOUT:   %pattern_type.087: type = pattern_type %pack_type.e98 [concrete]
// CHECK:STDOUT:   %x.param_patt.ca2: %pattern_type.087 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.31f: %pattern_type.087 = wrapper_binding_pattern x, %x.param_patt.ca2 [concrete]
// CHECK:STDOUT:   %.553: %pattern_type.087 = pack_expansion_pattern %x.patt.31f, invalid [concrete]
// CHECK:STDOUT:   %ForEach.specific_fn.e1d: <specific function> = specific_function %ForEach, @ForEach(%int_3, %.dcf) [concrete]
// CHECK:STDOUT:   %.ee6: %pack_type.043 = pack_value (%ptr.c28, %ptr.c28, %ptr.c28) [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %pack_type.28d: type = pack_type type, %int_0 [concrete]
// CHECK:STDOUT:   %.d3f: %pack_type.28d = pack_value () [concrete]
// CHECK:STDOUT:   %pack_type.86e: type = pack_type %Code.type, %int_0 [concrete]
// CHECK:STDOUT:   %.23c: %pack_type.86e = pack_value () [concrete]
// CHECK:STDOUT:   %pattern_type.dab: type = pattern_type %pack_type.86e [concrete]
// CHECK:STDOUT:   %T.patt.1df: %pattern_type.dab = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.8a5: %pattern_type.dab = pack_expansion_pattern %T.patt.1df, %arity.patt [symbolic]
// CHECK:STDOUT:   %.ef7: %Code.type = pack_element %.23c, %.4ee [symbolic]
// CHECK:STDOUT:   %as_type.75e: type = facet_access_type %.ef7 [symbolic]
// CHECK:STDOUT:   %pack_type.592: type = pack_type %.23c, %int_0 [concrete]
// CHECK:STDOUT:   %pattern_type.e66: type = pattern_type %pack_type.592 [concrete]
// CHECK:STDOUT:   %x.param_patt.adc: %pattern_type.e66 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.df8: %pattern_type.e66 = wrapper_binding_pattern x, %x.param_patt.adc [concrete]
// CHECK:STDOUT:   %.256: %pattern_type.e66 = pack_expansion_pattern %x.patt.df8, invalid [concrete]
// CHECK:STDOUT:   %ForEach.specific_fn.a0b: <specific function> = specific_function %ForEach, @ForEach(%int_0, %.23c) [concrete]
// CHECK:STDOUT:   %.610: %pack_type.592 = pack_value () [concrete]
// CHECK:STDOUT:   %complete_type.9c9: <witness> = complete_type_witness %pack_type.e98 [concrete]
// CHECK:STDOUT:   %require_complete.4f9: <witness> = require_complete_type %as_type.cb9 [symbolic]
// CHECK:STDOUT:   %Code.WithSelf.Get.type.472: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.fbc) [symbolic]
// CHECK:STDOUT:   %.951: type = fn_type_with_self_type %Code.WithSelf.Get.type.472, %.fbc [symbolic]
// CHECK:STDOUT:   %Code.lookup_impl_witness.3fe: <witness> = lookup_impl_witness %.fbc, @Code [symbolic]
// CHECK:STDOUT:   %impl.elem0.2e5: %.951 = impl_witness_access %Code.lookup_impl_witness.3fe, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.aac: <specific function> = specific_impl_function %impl.elem0.2e5, @Code.WithSelf.Get(%.fbc) [symbolic]
// CHECK:STDOUT:   %complete_type.709: <witness> = complete_type_witness %pack_type.592 [concrete]
// CHECK:STDOUT:   %require_complete.1c1: <witness> = require_complete_type %as_type.75e [symbolic]
// CHECK:STDOUT:   %Code.WithSelf.Get.type.9ce: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.ef7) [symbolic]
// CHECK:STDOUT:   %.f16: type = fn_type_with_self_type %Code.WithSelf.Get.type.9ce, %.ef7 [symbolic]
// CHECK:STDOUT:   %Code.lookup_impl_witness.e30: <witness> = lookup_impl_witness %.ef7, @Code [symbolic]
// CHECK:STDOUT:   %impl.elem0.579: %.f16 = impl_witness_access %Code.lookup_impl_witness.e30, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.788: <specific function> = specific_impl_function %impl.elem0.579, @Code.WithSelf.Get(%.ef7) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ForEach.decl: %ForEach.type = fn_decl @ForEach [concrete = constants.%ForEach] {
// CHECK:STDOUT:     %arity.patt.loc20_12.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc20_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc20_22.1: @ForEach.%pattern_type.loc20_22 (%pattern_type.2ee) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc20_22.2 (constants.%T.patt.003)]
// CHECK:STDOUT:     %.loc20_12.1: @ForEach.%pattern_type.loc20_22 (%pattern_type.2ee) = pack_expansion_pattern %T.patt.loc20_22.1, %arity.patt.loc20_12.1 [symbolic = %.loc20_12.2 (constants.%.cc3)]
// CHECK:STDOUT:     %x.param_patt.loc20_40.1: @ForEach.%pattern_type.loc20_40 (%pattern_type.2b9) = value_param_pattern [symbolic = %x.param_patt.loc20_40.2 (constants.%x.param_patt.2a2)]
// CHECK:STDOUT:     %x.patt.loc20_40.1: @ForEach.%pattern_type.loc20_40 (%pattern_type.2b9) = wrapper_binding_pattern x, %x.param_patt.loc20_40.1 [symbolic = %x.patt.loc20_40.2 (constants.%x.patt.27d)]
// CHECK:STDOUT:     %.loc20_30.1: @ForEach.%pattern_type.loc20_40 (%pattern_type.2b9) = pack_expansion_pattern %x.patt.loc20_40.1, invalid [symbolic = %.loc20_30.2 (constants.%.e9e)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc20_12.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc20_12.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc20_24: type = splice_block %Code.ref [concrete = constants.%Code.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Code.ref: type = name_ref Code, file.%Code.decl [concrete = constants.%Code.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc20_22.2: @ForEach.%pack_type.loc20_22 (%pack_type.104) = symbolic_binding T, 1 [symbolic = %T.loc20_22.1 (constants.%T)]
// CHECK:STDOUT:     %x.param: @ForEach.%pack_type.loc20_40 (%pack_type.6c6) = value_param call_param0
// CHECK:STDOUT:     %.loc20_42.3: type = splice_block %.loc20_42.6 [symbolic = %as_type.loc20_42.1 (constants.%as_type.0f9)] {
// CHECK:STDOUT:       %T.ref: @ForEach.%pack_type.loc20_22 (%pack_type.104) = name_ref T, %T.loc20_22.2 [symbolic = %T.loc20_22.1 (constants.%T)]
// CHECK:STDOUT:       %.loc20_42.4: Core.IntLiteral = pack_index [symbolic = %.loc20_42.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc20_42.5: %Code.type = pack_element %T.ref, %.loc20_42.4 [symbolic = %.loc20_42.2 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc20_42.2: type = facet_access_type %.loc20_42.5 [symbolic = %as_type.loc20_42.1 (constants.%as_type.0f9)]
// CHECK:STDOUT:       %.loc20_42.6: type = converted %.loc20_42.5, %as_type.loc20_42.2 [symbolic = %as_type.loc20_42.1 (constants.%as_type.0f9)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @ForEach.%pack_type.loc20_40 (%pack_type.6c6) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ForEach(%arity.loc20_12.2: Core.IntLiteral, %T.loc20_22.2: @ForEach.%pack_type.loc20_22 (%pack_type.104)) {
// CHECK:STDOUT:   %arity.patt.loc20_12.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc20_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc20_12.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc20_12.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc20_22: type = pack_type constants.%Code.type, %arity.loc20_12.1 [symbolic = %pack_type.loc20_22 (constants.%pack_type.104)]
// CHECK:STDOUT:   %pattern_type.loc20_22: type = pattern_type %pack_type.loc20_22 [symbolic = %pattern_type.loc20_22 (constants.%pattern_type.2ee)]
// CHECK:STDOUT:   %T.patt.loc20_22.2: @ForEach.%pattern_type.loc20_22 (%pattern_type.2ee) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc20_22.2 (constants.%T.patt.003)]
// CHECK:STDOUT:   %T.loc20_22.1: @ForEach.%pack_type.loc20_22 (%pack_type.104) = symbolic_binding T, 1 [symbolic = %T.loc20_22.1 (constants.%T)]
// CHECK:STDOUT:   %.loc20_12.2: @ForEach.%pattern_type.loc20_22 (%pattern_type.2ee) = pack_expansion_pattern %T.patt.loc20_22.2, %arity.patt.loc20_12.2 [symbolic = %.loc20_12.2 (constants.%.cc3)]
// CHECK:STDOUT:   %.loc20_42.1: Core.IntLiteral = pack_index [symbolic = %.loc20_42.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc20_42.2: %Code.type = pack_element %T.loc20_22.1, %.loc20_42.1 [symbolic = %.loc20_42.2 (constants.%.3c6)]
// CHECK:STDOUT:   %as_type.loc20_42.1: type = facet_access_type %.loc20_42.2 [symbolic = %as_type.loc20_42.1 (constants.%as_type.0f9)]
// CHECK:STDOUT:   %pack_type.loc20_40: type = pack_type %T.loc20_22.1, %arity.loc20_12.1 [symbolic = %pack_type.loc20_40 (constants.%pack_type.6c6)]
// CHECK:STDOUT:   %pattern_type.loc20_40: type = pattern_type %pack_type.loc20_40 [symbolic = %pattern_type.loc20_40 (constants.%pattern_type.2b9)]
// CHECK:STDOUT:   %x.param_patt.loc20_40.2: @ForEach.%pattern_type.loc20_40 (%pattern_type.2b9) = value_param_pattern [symbolic = %x.param_patt.loc20_40.2 (constants.%x.param_patt.2a2)]
// CHECK:STDOUT:   %x.patt.loc20_40.2: @ForEach.%pattern_type.loc20_40 (%pattern_type.2b9) = wrapper_binding_pattern x, %x.param_patt.loc20_40.2 [symbolic = %x.patt.loc20_40.2 (constants.%x.patt.27d)]
// CHECK:STDOUT:   %.loc20_30.2: @ForEach.%pattern_type.loc20_40 (%pattern_type.2b9) = pack_expansion_pattern %x.patt.loc20_40.2, invalid [symbolic = %.loc20_30.2 (constants.%.e9e)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc20: <witness> = require_complete_type %pack_type.loc20_40 [symbolic = %require_complete.loc20 (constants.%require_complete.aa7)]
// CHECK:STDOUT:   %require_complete.loc21: <witness> = require_complete_type %as_type.loc20_42.1 [symbolic = %require_complete.loc21 (constants.%require_complete.d18)]
// CHECK:STDOUT:   %Code.WithSelf.Get.type: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.loc20_42.2) [symbolic = %Code.WithSelf.Get.type (constants.%Code.WithSelf.Get.type.099)]
// CHECK:STDOUT:   %.loc21_21: type = fn_type_with_self_type %Code.WithSelf.Get.type, %.loc20_42.2 [symbolic = %.loc21_21 (constants.%.131)]
// CHECK:STDOUT:   %Code.lookup_impl_witness: <witness> = lookup_impl_witness %.loc20_42.2, @Code [symbolic = %Code.lookup_impl_witness (constants.%Code.lookup_impl_witness.57d)]
// CHECK:STDOUT:   %impl.elem0.loc21_21.2: @ForEach.%.loc21_21 (%.131) = impl_witness_access %Code.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc21_21.2 (constants.%impl.elem0.5c5)]
// CHECK:STDOUT:   %specific_impl_fn.loc21_21.2: <specific function> = specific_impl_function %impl.elem0.loc21_21.2, @Code.WithSelf.Get(%.loc20_42.2) [symbolic = %specific_impl_fn.loc21_21.2 (constants.%specific_impl_fn.f5a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @ForEach.%pack_type.loc20_40 (%pack_type.6c6)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc20_12.2 {
// CHECK:STDOUT:       %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %x.ref: @ForEach.%pack_type.loc20_40 (%pack_type.6c6) = name_ref x, %x
// CHECK:STDOUT:       %.loc21_15.1: Core.IntLiteral = pack_index [symbolic = %.loc20_42.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc21_15.2: Core.IntLiteral = pack_index [symbolic = %.loc20_42.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc21_15.3: %Code.type = pack_element constants.%T, %.loc21_15.2 [symbolic = %.loc20_42.2 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc21: type = facet_access_type %.loc21_15.3 [symbolic = %as_type.loc20_42.1 (constants.%as_type.0f9)]
// CHECK:STDOUT:       %.loc21_15.4: type = converted %.loc21_15.3, %as_type.loc21 [symbolic = %as_type.loc20_42.1 (constants.%as_type.0f9)]
// CHECK:STDOUT:       %.loc21_15.5: @ForEach.%as_type.loc20_42.1 (%as_type.0f9) = pack_element %x.ref, %.loc21_15.1
// CHECK:STDOUT:       %Get.ref: %Code.assoc_type = name_ref Get, @Code.WithSelf.%assoc0 [concrete = constants.%assoc0.b5d]
// CHECK:STDOUT:       %impl.elem0.loc21_21.1: @ForEach.%.loc21_21 (%.131) = impl_witness_access constants.%Code.lookup_impl_witness.57d, element0 [symbolic = %impl.elem0.loc21_21.2 (constants.%impl.elem0.5c5)]
// CHECK:STDOUT:       %bound_method.loc21_21: <bound method> = bound_method %.loc21_15.5, %impl.elem0.loc21_21.1
// CHECK:STDOUT:       %.loc21_26.1: %Code.type = converted constants.%as_type.0f9, constants.%.3c6 [symbolic = %.loc20_42.2 (constants.%.3c6)]
// CHECK:STDOUT:       %.loc21_26.2: %Code.type = converted constants.%as_type.0f9, constants.%.3c6 [symbolic = %.loc20_42.2 (constants.%.3c6)]
// CHECK:STDOUT:       %specific_impl_fn.loc21_21.1: <specific function> = specific_impl_function %impl.elem0.loc21_21.1, @Code.WithSelf.Get(constants.%.3c6) [symbolic = %specific_impl_fn.loc21_21.2 (constants.%specific_impl_fn.f5a)]
// CHECK:STDOUT:       %bound_method.loc21_26: <bound method> = bound_method %.loc21_15.5, %specific_impl_fn.loc21_21.1
// CHECK:STDOUT:       %Code.WithSelf.Get.call: init %i64 = call %bound_method.loc21_26(%.loc21_15.5)
// CHECK:STDOUT:       %.loc21_26.3: %i64 = value_of_initializer %Code.WithSelf.Get.call
// CHECK:STDOUT:       %.loc21_26.4: %i64 = converted %Code.WithSelf.Get.call, %.loc21_26.3
// CHECK:STDOUT:       %Consume.call: init %empty_tuple.type = call %Consume.ref(%.loc21_26.4)
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%a.param: %A, %b.param: %B) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %ForEach.ref.loc27: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:   %a.ref.loc27_11: %A = name_ref a, %a
// CHECK:STDOUT:   %b.ref: %B = name_ref b, %b
// CHECK:STDOUT:   %a.ref.loc27_17: %A = name_ref a, %a
// CHECK:STDOUT:   %.loc27_11.1: %tuple.type.05e = pack_literal (%a.ref.loc27_11, %b.ref, %a.ref.loc27_17)
// CHECK:STDOUT:   %int_3.loc27_18.1: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:   %.loc27_18.1: %pack_type.043 = pack_value (constants.%A, constants.%B, constants.%A) [concrete = constants.%.9eb]
// CHECK:STDOUT:   %int_3.loc27_18.2: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:   %.loc27_18.2: %pack_type.043 = pack_value (constants.%A, constants.%B, constants.%A) [concrete = constants.%.9eb]
// CHECK:STDOUT:   %Code.facet.loc27_18.1: %Code.type = facet_value constants.%A, (constants.%Code.impl_witness.b31) [concrete = constants.%Code.facet.cd0]
// CHECK:STDOUT:   %.loc27_18.3: %Code.type = converted constants.%A, %Code.facet.loc27_18.1 [concrete = constants.%Code.facet.cd0]
// CHECK:STDOUT:   %Code.facet.loc27_18.2: %Code.type = facet_value constants.%B, (constants.%Code.impl_witness.b20) [concrete = constants.%Code.facet.a43]
// CHECK:STDOUT:   %.loc27_18.4: %Code.type = converted constants.%B, %Code.facet.loc27_18.2 [concrete = constants.%Code.facet.a43]
// CHECK:STDOUT:   %Code.facet.loc27_18.3: %Code.type = facet_value constants.%A, (constants.%Code.impl_witness.b31) [concrete = constants.%Code.facet.cd0]
// CHECK:STDOUT:   %.loc27_18.5: %Code.type = converted constants.%A, %Code.facet.loc27_18.3 [concrete = constants.%Code.facet.cd0]
// CHECK:STDOUT:   %.loc27_18.6: %pack_type.7e3 = pack_value (%.loc27_18.3, %.loc27_18.4, %.loc27_18.5) [concrete = constants.%.dcf]
// CHECK:STDOUT:   %.loc27_18.7: %pack_type.7e3 = converted constants.%.9eb, %.loc27_18.6 [concrete = constants.%.dcf]
// CHECK:STDOUT:   %ForEach.specific_fn.loc27: <specific function> = specific_function %ForEach.ref.loc27, @ForEach(constants.%int_3, constants.%.dcf) [concrete = constants.%ForEach.specific_fn.e1d]
// CHECK:STDOUT:   %.loc27_11.2: %pack_type.043 = pack_value (constants.%ptr.c28, constants.%ptr.c28, constants.%ptr.c28) [concrete = constants.%.ee6]
// CHECK:STDOUT:   %.loc27_11.3: %pack_type.e98 = pack_value (%a.ref.loc27_11, %b.ref, %a.ref.loc27_17)
// CHECK:STDOUT:   %.loc27_11.4: %pack_type.e98 = converted %.loc27_11.1, %.loc27_11.3
// CHECK:STDOUT:   %ForEach.call.loc27: init %empty_tuple.type = call %ForEach.specific_fn.loc27(%.loc27_11.4)
// CHECK:STDOUT:   %ForEach.ref.loc28: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:   %.loc28_11.1: %empty_tuple.type = pack_literal ()
// CHECK:STDOUT:   %int_0.loc28_11.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc28_11.2: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %int_0.loc28_11.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc28_11.3: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %.loc28_11.4: %pack_type.86e = pack_value () [concrete = constants.%.23c]
// CHECK:STDOUT:   %.loc28_11.5: %pack_type.86e = converted constants.%.d3f, %.loc28_11.4 [concrete = constants.%.23c]
// CHECK:STDOUT:   %ForEach.specific_fn.loc28: <specific function> = specific_function %ForEach.ref.loc28, @ForEach(constants.%int_0, constants.%.23c) [concrete = constants.%ForEach.specific_fn.a0b]
// CHECK:STDOUT:   %.loc28_11.6: %pack_type.592 = pack_value () [concrete = constants.%.610]
// CHECK:STDOUT:   %.loc28_11.7: %pack_type.592 = converted %.loc28_11.1, %.loc28_11.6 [concrete = constants.%.610]
// CHECK:STDOUT:   %ForEach.call.loc28: init %empty_tuple.type = call %ForEach.specific_fn.loc28(%.loc28_11.7)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity.patt.loc20_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc20_12.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc20_22 => constants.%pack_type.104
// CHECK:STDOUT:   %pattern_type.loc20_22 => constants.%pattern_type.2ee
// CHECK:STDOUT:   %T.patt.loc20_22.2 => constants.%T.patt.003
// CHECK:STDOUT:   %T.loc20_22.1 => constants.%T
// CHECK:STDOUT:   %.loc20_12.2 => constants.%.cc3
// CHECK:STDOUT:   %.loc20_42.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc20_42.2 => constants.%.3c6
// CHECK:STDOUT:   %as_type.loc20_42.1 => constants.%as_type.0f9
// CHECK:STDOUT:   %pack_type.loc20_40 => constants.%pack_type.6c6
// CHECK:STDOUT:   %pattern_type.loc20_40 => constants.%pattern_type.2b9
// CHECK:STDOUT:   %x.param_patt.loc20_40.2 => constants.%x.param_patt.2a2
// CHECK:STDOUT:   %x.patt.loc20_40.2 => constants.%x.patt.27d
// CHECK:STDOUT:   %.loc20_30.2 => constants.%.e9e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%int_3, constants.%.dcf) {
// CHECK:STDOUT:   %arity.patt.loc20_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc20_12.1 => constants.%int_3
// CHECK:STDOUT:   %pack_type.loc20_22 => constants.%pack_type.7e3
// CHECK:STDOUT:   %pattern_type.loc20_22 => constants.%pattern_type.b85
// CHECK:STDOUT:   %T.patt.loc20_22.2 => constants.%T.patt.198
// CHECK:STDOUT:   %T.loc20_22.1 => constants.%.dcf
// CHECK:STDOUT:   %.loc20_12.2 => constants.%.81e
// CHECK:STDOUT:   %.loc20_42.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc20_42.2 => constants.%.fbc
// CHECK:STDOUT:   %as_type.loc20_42.1 => constants.%as_type.cb9
// CHECK:STDOUT:   %pack_type.loc20_40 => constants.%pack_type.e98
// CHECK:STDOUT:   %pattern_type.loc20_40 => constants.%pattern_type.087
// CHECK:STDOUT:   %x.param_patt.loc20_40.2 => constants.%x.param_patt.ca2
// CHECK:STDOUT:   %x.patt.loc20_40.2 => constants.%x.patt.31f
// CHECK:STDOUT:   %.loc20_30.2 => constants.%.553
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc20 => constants.%complete_type.9c9
// CHECK:STDOUT:   %require_complete.loc21 => constants.%require_complete.4f9
// CHECK:STDOUT:   %Code.WithSelf.Get.type => constants.%Code.WithSelf.Get.type.472
// CHECK:STDOUT:   %.loc21_21 => constants.%.951
// CHECK:STDOUT:   %Code.lookup_impl_witness => constants.%Code.lookup_impl_witness.3fe
// CHECK:STDOUT:   %impl.elem0.loc21_21.2 => constants.%impl.elem0.2e5
// CHECK:STDOUT:   %specific_impl_fn.loc21_21.2 => constants.%specific_impl_fn.aac
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%int_0, constants.%.23c) {
// CHECK:STDOUT:   %arity.patt.loc20_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc20_12.1 => constants.%int_0
// CHECK:STDOUT:   %pack_type.loc20_22 => constants.%pack_type.86e
// CHECK:STDOUT:   %pattern_type.loc20_22 => constants.%pattern_type.dab
// CHECK:STDOUT:   %T.patt.loc20_22.2 => constants.%T.patt.1df
// CHECK:STDOUT:   %T.loc20_22.1 => constants.%.23c
// CHECK:STDOUT:   %.loc20_12.2 => constants.%.8a5
// CHECK:STDOUT:   %.loc20_42.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc20_42.2 => constants.%.ef7
// CHECK:STDOUT:   %as_type.loc20_42.1 => constants.%as_type.75e
// CHECK:STDOUT:   %pack_type.loc20_40 => constants.%pack_type.592
// CHECK:STDOUT:   %pattern_type.loc20_40 => constants.%pattern_type.e66
// CHECK:STDOUT:   %x.param_patt.loc20_40.2 => constants.%x.param_patt.adc
// CHECK:STDOUT:   %x.patt.loc20_40.2 => constants.%x.patt.df8
// CHECK:STDOUT:   %.loc20_30.2 => constants.%.256
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc20 => constants.%complete_type.709
// CHECK:STDOUT:   %require_complete.loc21 => constants.%require_complete.1c1
// CHECK:STDOUT:   %Code.WithSelf.Get.type => constants.%Code.WithSelf.Get.type.9ce
// CHECK:STDOUT:   %.loc21_21 => constants.%.f16
// CHECK:STDOUT:   %Code.lookup_impl_witness => constants.%Code.lookup_impl_witness.e30
// CHECK:STDOUT:   %impl.elem0.loc21_21.2 => constants.%impl.elem0.579
// CHECK:STDOUT:   %specific_impl_fn.loc21_21.2 => constants.%specific_impl_fn.788
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- type_pack.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.fc0: type = pattern_type %pack_type.c29 [symbolic]
// CHECK:STDOUT:   %T.patt.f84: %pattern_type.fc0 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.99e: %pattern_type.fc0 = pack_expansion_pattern %T.patt.f84, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.425: type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.8fb: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.9a6: type = pattern_type %pack_type.8fb [symbolic]
// CHECK:STDOUT:   %x.param_patt.18e: %pattern_type.9a6 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.9e1: %pattern_type.9a6 = wrapper_binding_pattern x, %x.param_patt.18e [symbolic]
// CHECK:STDOUT:   %.94c: %pattern_type.9a6 = pack_expansion_pattern %x.patt.9e1, invalid [symbolic]
// CHECK:STDOUT:   %Count.type: type = fn_type @Count [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Count: %Count.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.fc6: <witness> = require_complete_type %pack_type.8fb [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.3d9 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.As.impl.Convert.3d9, @Core.IntLiteral.as.As.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.As.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.d98: %i64 = int_value 1 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.abd: %pack_type.8f6 = pack_value (%i64, bool) [concrete]
// CHECK:STDOUT:   %pattern_type.b37: type = pattern_type %pack_type.8f6 [concrete]
// CHECK:STDOUT:   %T.patt.8a9: %pattern_type.b37 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.6c7: %pattern_type.b37 = pack_expansion_pattern %T.patt.8a9, %arity.patt [symbolic]
// CHECK:STDOUT:   %.867: type = pack_element %.abd, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.394: type = pack_type %.abd, %int_2 [concrete]
// CHECK:STDOUT:   %pattern_type.f36: type = pattern_type %pack_type.394 [concrete]
// CHECK:STDOUT:   %x.param_patt.b43: %pattern_type.f36 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.02f: %pattern_type.f36 = wrapper_binding_pattern x, %x.param_patt.b43 [concrete]
// CHECK:STDOUT:   %.c86: %pattern_type.f36 = pack_expansion_pattern %x.patt.02f, invalid [concrete]
// CHECK:STDOUT:   %Count.specific_fn.618: <specific function> = specific_function %Count, @Count(%int_2, %.abd) [concrete]
// CHECK:STDOUT:   %.c72: %pack_type.394 = pack_value (%int_1.d98, %true) [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %pack_type.28d: type = pack_type type, %int_0 [concrete]
// CHECK:STDOUT:   %.d3f: %pack_type.28d = pack_value () [concrete]
// CHECK:STDOUT:   %pattern_type.94c: type = pattern_type %pack_type.28d [concrete]
// CHECK:STDOUT:   %T.patt.75e: %pattern_type.94c = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.b4d: %pattern_type.94c = pack_expansion_pattern %T.patt.75e, %arity.patt [symbolic]
// CHECK:STDOUT:   %.8a1: type = pack_element %.d3f, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.54a: type = pack_type %.d3f, %int_0 [concrete]
// CHECK:STDOUT:   %pattern_type.689: type = pattern_type %pack_type.54a [concrete]
// CHECK:STDOUT:   %x.param_patt.4cc: %pattern_type.689 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.e51: %pattern_type.689 = wrapper_binding_pattern x, %x.param_patt.4cc [concrete]
// CHECK:STDOUT:   %.9cd: %pattern_type.689 = pack_expansion_pattern %x.patt.e51, invalid [concrete]
// CHECK:STDOUT:   %Count.specific_fn.cdc: <specific function> = specific_function %Count, @Count(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %.f49: %pack_type.54a = pack_value () [concrete]
// CHECK:STDOUT:   %complete_type.ad9: <witness> = complete_type_witness %pack_type.394 [concrete]
// CHECK:STDOUT:   %complete_type.57a: <witness> = complete_type_witness %pack_type.54a [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.64b: @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert.type (%Core.IntLiteral.as.As.impl.Convert.type.c5d) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.As.impl.%Core.IntLiteral.as.As.impl.Convert (constants.%Core.IntLiteral.as.As.impl.Convert.6ee)]
// CHECK:STDOUT:   %As.impl_witness_table.d22 = impl_witness_table (%Core.import_ref.64b), @Core.IntLiteral.as.As.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Count.decl: %Count.type = fn_decl @Count [concrete = constants.%Count] {
// CHECK:STDOUT:     %arity.patt.loc4_10.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_10.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc4_20.1: @Count.%pattern_type.loc4_20 (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_20.2 (constants.%T.patt.f84)]
// CHECK:STDOUT:     %.loc4_10.1: @Count.%pattern_type.loc4_20 (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc4_20.1, %arity.patt.loc4_10.1 [symbolic = %.loc4_10.2 (constants.%.99e)]
// CHECK:STDOUT:     %x.param_patt.loc4_45.1: @Count.%pattern_type.loc4_45 (%pattern_type.9a6) = value_param_pattern [symbolic = %x.param_patt.loc4_45.2 (constants.%x.param_patt.18e)]
// CHECK:STDOUT:     %x.patt.loc4_45.1: @Count.%pattern_type.loc4_45 (%pattern_type.9a6) = wrapper_binding_pattern x, %x.param_patt.loc4_45.1 [symbolic = %x.patt.loc4_45.2 (constants.%x.patt.9e1)]
// CHECK:STDOUT:     %.loc4_28.1: @Count.%pattern_type.loc4_45 (%pattern_type.9a6) = pack_expansion_pattern %x.patt.loc4_45.1, invalid [symbolic = %.loc4_28.2 (constants.%.94c)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc4_10.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_10.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc4_22.1: type = splice_block %.loc4_22.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc4_22.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc4_20.2: @Count.%pack_type.loc4_20 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc4_20.1 (constants.%T)]
// CHECK:STDOUT:     %x.param: @Count.%pack_type.loc4_45 (%pack_type.8fb) = value_param call_param0
// CHECK:STDOUT:     %.loc4_47.3: type = splice_block %.loc4_47.5 [symbolic = %.loc4_47.2 (constants.%.425)] {
// CHECK:STDOUT:       %T.ref: @Count.%pack_type.loc4_20 (%pack_type.c29) = name_ref T, %T.loc4_20.2 [symbolic = %T.loc4_20.1 (constants.%T)]
// CHECK:STDOUT:       %.loc4_47.4: Core.IntLiteral = pack_index [symbolic = %.loc4_47.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc4_47.5: type = pack_element %T.ref, %.loc4_47.4 [symbolic = %.loc4_47.2 (constants.%.425)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @Count.%pack_type.loc4_45 (%pack_type.8fb) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Count(%arity.loc4_10.2: Core.IntLiteral, %T.loc4_20.2: @Count.%pack_type.loc4_20 (%pack_type.c29)) {
// CHECK:STDOUT:   %arity.patt.loc4_10.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc4_10.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc4_10.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc4_10.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc4_20: type = pack_type type, %arity.loc4_10.1 [symbolic = %pack_type.loc4_20 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %pattern_type.loc4_20: type = pattern_type %pack_type.loc4_20 [symbolic = %pattern_type.loc4_20 (constants.%pattern_type.fc0)]
// CHECK:STDOUT:   %T.patt.loc4_20.2: @Count.%pattern_type.loc4_20 (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc4_20.2 (constants.%T.patt.f84)]
// CHECK:STDOUT:   %T.loc4_20.1: @Count.%pack_type.loc4_20 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc4_20.1 (constants.%T)]
// CHECK:STDOUT:   %.loc4_10.2: @Count.%pattern_type.loc4_20 (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc4_20.2, %arity.patt.loc4_10.2 [symbolic = %.loc4_10.2 (constants.%.99e)]
// CHECK:STDOUT:   %.loc4_47.1: Core.IntLiteral = pack_index [symbolic = %.loc4_47.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc4_47.2: type = pack_element %T.loc4_20.1, %.loc4_47.1 [symbolic = %.loc4_47.2 (constants.%.425)]
// CHECK:STDOUT:   %pack_type.loc4_45: type = pack_type %T.loc4_20.1, %arity.loc4_10.1 [symbolic = %pack_type.loc4_45 (constants.%pack_type.8fb)]
// CHECK:STDOUT:   %pattern_type.loc4_45: type = pattern_type %pack_type.loc4_45 [symbolic = %pattern_type.loc4_45 (constants.%pattern_type.9a6)]
// CHECK:STDOUT:   %x.param_patt.loc4_45.2: @Count.%pattern_type.loc4_45 (%pattern_type.9a6) = value_param_pattern [symbolic = %x.param_patt.loc4_45.2 (constants.%x.param_patt.18e)]
// CHECK:STDOUT:   %x.patt.loc4_45.2: @Count.%pattern_type.loc4_45 (%pattern_type.9a6) = wrapper_binding_pattern x, %x.param_patt.loc4_45.2 [symbolic = %x.patt.loc4_45.2 (constants.%x.patt.9e1)]
// CHECK:STDOUT:   %.loc4_28.2: @Count.%pattern_type.loc4_45 (%pattern_type.9a6) = pack_expansion_pattern %x.patt.loc4_45.2, invalid [symbolic = %.loc4_28.2 (constants.%.94c)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type.loc4_45 [symbolic = %require_complete (constants.%require_complete.fc6)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @Count.%pack_type.loc4_45 (%pack_type.8fb)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Count.ref.loc9: %Count.type = name_ref Count, file.%Count.decl [concrete = constants.%Count]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:   %impl.elem0: %.8fd = impl_witness_access constants.%As.impl_witness.0fe, element0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.3d9]
// CHECK:STDOUT:   %bound_method.loc9_11.1: <bound method> = bound_method %int_1, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.As.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.As.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_11.2: <bound method> = bound_method %int_1, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.As.impl.Convert.call: init %i64 = call %bound_method.loc9_11.2(%int_1) [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc9_11.1: %i64 = value_of_initializer %Core.IntLiteral.as.As.impl.Convert.call [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %.loc9_11.2: %i64 = converted %int_1, %.loc9_11.1 [concrete = constants.%int_1.d98]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %.loc9_11.3: %tuple.type = pack_literal (%.loc9_11.2, %true)
// CHECK:STDOUT:   %int_2.loc9_23.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc9_23.1: %pack_type.8f6 = pack_value (constants.%i64, bool) [concrete = constants.%.abd]
// CHECK:STDOUT:   %int_2.loc9_23.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc9_23.2: %pack_type.8f6 = pack_value (constants.%i64, bool) [concrete = constants.%.abd]
// CHECK:STDOUT:   %Count.specific_fn.loc9: <specific function> = specific_function %Count.ref.loc9, @Count(constants.%int_2, constants.%.abd) [concrete = constants.%Count.specific_fn.618]
// CHECK:STDOUT:   %.loc9_11.4: %pack_type.394 = pack_value (%.loc9_11.2, %true) [concrete = constants.%.c72]
// CHECK:STDOUT:   %.loc9_11.5: %pack_type.394 = converted %.loc9_11.3, %.loc9_11.4 [concrete = constants.%.c72]
// CHECK:STDOUT:   %Count.call.loc9: init %empty_tuple.type = call %Count.specific_fn.loc9(%.loc9_11.5)
// CHECK:STDOUT:   %Count.ref.loc10: %Count.type = name_ref Count, file.%Count.decl [concrete = constants.%Count]
// CHECK:STDOUT:   %.loc10_9.1: %empty_tuple.type = pack_literal ()
// CHECK:STDOUT:   %int_0.loc10_9.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc10_9.2: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %int_0.loc10_9.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc10_9.3: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %Count.specific_fn.loc10: <specific function> = specific_function %Count.ref.loc10, @Count(constants.%int_0, constants.%.d3f) [concrete = constants.%Count.specific_fn.cdc]
// CHECK:STDOUT:   %.loc10_9.4: %pack_type.54a = pack_value () [concrete = constants.%.f49]
// CHECK:STDOUT:   %.loc10_9.5: %pack_type.54a = converted %.loc10_9.1, %.loc10_9.4 [concrete = constants.%.f49]
// CHECK:STDOUT:   %Count.call.loc10: init %empty_tuple.type = call %Count.specific_fn.loc10(%.loc10_9.5)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Count(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity.patt.loc4_10.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_10.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc4_20 => constants.%pack_type.c29
// CHECK:STDOUT:   %pattern_type.loc4_20 => constants.%pattern_type.fc0
// CHECK:STDOUT:   %T.patt.loc4_20.2 => constants.%T.patt.f84
// CHECK:STDOUT:   %T.loc4_20.1 => constants.%T
// CHECK:STDOUT:   %.loc4_10.2 => constants.%.99e
// CHECK:STDOUT:   %.loc4_47.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_47.2 => constants.%.425
// CHECK:STDOUT:   %pack_type.loc4_45 => constants.%pack_type.8fb
// CHECK:STDOUT:   %pattern_type.loc4_45 => constants.%pattern_type.9a6
// CHECK:STDOUT:   %x.param_patt.loc4_45.2 => constants.%x.param_patt.18e
// CHECK:STDOUT:   %x.patt.loc4_45.2 => constants.%x.patt.9e1
// CHECK:STDOUT:   %.loc4_28.2 => constants.%.94c
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Count(constants.%int_2, constants.%.abd) {
// CHECK:STDOUT:   %arity.patt.loc4_10.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_10.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc4_20 => constants.%pack_type.8f6
// CHECK:STDOUT:   %pattern_type.loc4_20 => constants.%pattern_type.b37
// CHECK:STDOUT:   %T.patt.loc4_20.2 => constants.%T.patt.8a9
// CHECK:STDOUT:   %T.loc4_20.1 => constants.%.abd
// CHECK:STDOUT:   %.loc4_10.2 => constants.%.6c7
// CHECK:STDOUT:   %.loc4_47.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_47.2 => constants.%.867
// CHECK:STDOUT:   %pack_type.loc4_45 => constants.%pack_type.394
// CHECK:STDOUT:   %pattern_type.loc4_45 => constants.%pattern_type.f36
// CHECK:STDOUT:   %x.param_patt.loc4_45.2 => constants.%x.param_patt.b43
// CHECK:STDOUT:   %x.patt.loc4_45.2 => constants.%x.patt.02f
// CHECK:STDOUT:   %.loc4_28.2 => constants.%.c86
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.ad9
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Count(constants.%int_0, constants.%.d3f) {
// CHECK:STDOUT:   %arity.patt.loc4_10.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc4_10.1 => constants.%int_0
// CHECK:STDOUT:   %pack_type.loc4_20 => constants.%pack_type.28d
// CHECK:STDOUT:   %pattern_type.loc4_20 => constants.%pattern_type.94c
// CHECK:STDOUT:   %T.patt.loc4_20.2 => constants.%T.patt.75e
// CHECK:STDOUT:   %T.loc4_20.1 => constants.%.d3f
// CHECK:STDOUT:   %.loc4_10.2 => constants.%.b4d
// CHECK:STDOUT:   %.loc4_47.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc4_47.2 => constants.%.8a1
// CHECK:STDOUT:   %pack_type.loc4_45 => constants.%pack_type.54a
// CHECK:STDOUT:   %pattern_type.loc4_45 => constants.%pattern_type.689
// CHECK:STDOUT:   %x.param_patt.loc4_45.2 => constants.%x.param_patt.4cc
// CHECK:STDOUT:   %x.patt.loc4_45.2 => constants.%x.patt.e51
// CHECK:STDOUT:   %.loc4_28.2 => constants.%.9cd
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.57a
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- forward.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Code.type: type = facet_type <@Code> [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.104: type = pack_type %Code.type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.2ee: type = pattern_type %pack_type.104 [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %U.patt: %pattern_type.2ee = symbolic_binding_pattern U, 1 [symbolic]
// CHECK:STDOUT:   %U: %pack_type.104 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %.cc365a.2: %pattern_type.2ee = pack_expansion_pattern %U.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %.3c6e42.2: %Code.type = pack_element %U, %.4ee [symbolic]
// CHECK:STDOUT:   %as_type.0f9f76.2: type = facet_access_type %.3c6e42.2 [symbolic]
// CHECK:STDOUT:   %pack_type.6c62db.2: type = pack_type %U, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.2b9e81.2: type = pattern_type %pack_type.6c62db.2 [symbolic]
// CHECK:STDOUT:   %y.param_patt: %pattern_type.2b9e81.2 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %y.patt: %pattern_type.2b9e81.2 = wrapper_binding_pattern y, %y.param_patt [symbolic]
// CHECK:STDOUT:   %.997: %pattern_type.2b9e81.2 = pack_expansion_pattern %y.patt, invalid [symbolic]
// CHECK:STDOUT:   %Forward.type: type = fn_type @Forward [concrete]
// CHECK:STDOUT:   %Forward: %Forward.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.aa7502.2: <witness> = require_complete_type %pack_type.6c62db.2 [symbolic]
// CHECK:STDOUT:   %ForEach.specific_fn: <specific function> = specific_function %ForEach, @ForEach(%arity, %U) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Forward.decl: %Forward.type = fn_decl @Forward [concrete = constants.%Forward] {
// CHECK:STDOUT:     %arity.patt.loc10_12.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %U.patt.loc10_22.1: @Forward.%pattern_type.loc10_22 (%pattern_type.2ee) = symbolic_binding_pattern U, 1 [symbolic = %U.patt.loc10_22.2 (constants.%U.patt)]
// CHECK:STDOUT:     %.loc10_12.1: @Forward.%pattern_type.loc10_22 (%pattern_type.2ee) = pack_expansion_pattern %U.patt.loc10_22.1, %arity.patt.loc10_12.1 [symbolic = %.loc10_12.2 (constants.%.cc365a.2)]
// CHECK:STDOUT:     %y.param_patt.loc10_40.1: @Forward.%pattern_type.loc10_40 (%pattern_type.2b9e81.2) = value_param_pattern [symbolic = %y.param_patt.loc10_40.2 (constants.%y.param_patt)]
// CHECK:STDOUT:     %y.patt.loc10_40.1: @Forward.%pattern_type.loc10_40 (%pattern_type.2b9e81.2) = wrapper_binding_pattern y, %y.param_patt.loc10_40.1 [symbolic = %y.patt.loc10_40.2 (constants.%y.patt)]
// CHECK:STDOUT:     %.loc10_30.1: @Forward.%pattern_type.loc10_40 (%pattern_type.2b9e81.2) = pack_expansion_pattern %y.patt.loc10_40.1, invalid [symbolic = %.loc10_30.2 (constants.%.997)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc10_12.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc10_24: type = splice_block %Code.ref [concrete = constants.%Code.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Code.ref: type = name_ref Code, file.%Code.decl [concrete = constants.%Code.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %U.loc10_22.2: @Forward.%pack_type.loc10_22 (%pack_type.104) = symbolic_binding U, 1 [symbolic = %U.loc10_22.1 (constants.%U)]
// CHECK:STDOUT:     %y.param: @Forward.%pack_type.loc10_40 (%pack_type.6c62db.2) = value_param call_param0
// CHECK:STDOUT:     %.loc10_42.3: type = splice_block %.loc10_42.6 [symbolic = %as_type.loc10_42.1 (constants.%as_type.0f9f76.2)] {
// CHECK:STDOUT:       %U.ref: @Forward.%pack_type.loc10_22 (%pack_type.104) = name_ref U, %U.loc10_22.2 [symbolic = %U.loc10_22.1 (constants.%U)]
// CHECK:STDOUT:       %.loc10_42.4: Core.IntLiteral = pack_index [symbolic = %.loc10_42.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc10_42.5: %Code.type = pack_element %U.ref, %.loc10_42.4 [symbolic = %.loc10_42.2 (constants.%.3c6e42.2)]
// CHECK:STDOUT:       %as_type.loc10_42.2: type = facet_access_type %.loc10_42.5 [symbolic = %as_type.loc10_42.1 (constants.%as_type.0f9f76.2)]
// CHECK:STDOUT:       %.loc10_42.6: type = converted %.loc10_42.5, %as_type.loc10_42.2 [symbolic = %as_type.loc10_42.1 (constants.%as_type.0f9f76.2)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %y: @Forward.%pack_type.loc10_40 (%pack_type.6c62db.2) = wrapper_binding y, %y.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Forward(%arity.loc10_12.2: Core.IntLiteral, %U.loc10_22.2: @Forward.%pack_type.loc10_22 (%pack_type.104)) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc10_12.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc10_22: type = pack_type constants.%Code.type, %arity.loc10_12.1 [symbolic = %pack_type.loc10_22 (constants.%pack_type.104)]
// CHECK:STDOUT:   %pattern_type.loc10_22: type = pattern_type %pack_type.loc10_22 [symbolic = %pattern_type.loc10_22 (constants.%pattern_type.2ee)]
// CHECK:STDOUT:   %U.patt.loc10_22.2: @Forward.%pattern_type.loc10_22 (%pattern_type.2ee) = symbolic_binding_pattern U, 1 [symbolic = %U.patt.loc10_22.2 (constants.%U.patt)]
// CHECK:STDOUT:   %U.loc10_22.1: @Forward.%pack_type.loc10_22 (%pack_type.104) = symbolic_binding U, 1 [symbolic = %U.loc10_22.1 (constants.%U)]
// CHECK:STDOUT:   %.loc10_12.2: @Forward.%pattern_type.loc10_22 (%pattern_type.2ee) = pack_expansion_pattern %U.patt.loc10_22.2, %arity.patt.loc10_12.2 [symbolic = %.loc10_12.2 (constants.%.cc365a.2)]
// CHECK:STDOUT:   %.loc10_42.1: Core.IntLiteral = pack_index [symbolic = %.loc10_42.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc10_42.2: %Code.type = pack_element %U.loc10_22.1, %.loc10_42.1 [symbolic = %.loc10_42.2 (constants.%.3c6e42.2)]
// CHECK:STDOUT:   %as_type.loc10_42.1: type = facet_access_type %.loc10_42.2 [symbolic = %as_type.loc10_42.1 (constants.%as_type.0f9f76.2)]
// CHECK:STDOUT:   %pack_type.loc10_40: type = pack_type %U.loc10_22.1, %arity.loc10_12.1 [symbolic = %pack_type.loc10_40 (constants.%pack_type.6c62db.2)]
// CHECK:STDOUT:   %pattern_type.loc10_40: type = pattern_type %pack_type.loc10_40 [symbolic = %pattern_type.loc10_40 (constants.%pattern_type.2b9e81.2)]
// CHECK:STDOUT:   %y.param_patt.loc10_40.2: @Forward.%pattern_type.loc10_40 (%pattern_type.2b9e81.2) = value_param_pattern [symbolic = %y.param_patt.loc10_40.2 (constants.%y.param_patt)]
// CHECK:STDOUT:   %y.patt.loc10_40.2: @Forward.%pattern_type.loc10_40 (%pattern_type.2b9e81.2) = wrapper_binding_pattern y, %y.param_patt.loc10_40.2 [symbolic = %y.patt.loc10_40.2 (constants.%y.patt)]
// CHECK:STDOUT:   %.loc10_30.2: @Forward.%pattern_type.loc10_40 (%pattern_type.2b9e81.2) = pack_expansion_pattern %y.patt.loc10_40.2, invalid [symbolic = %.loc10_30.2 (constants.%.997)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type.loc10_40 [symbolic = %require_complete (constants.%require_complete.aa7502.2)]
// CHECK:STDOUT:   %ForEach.specific_fn.loc11_3.2: <specific function> = specific_function constants.%ForEach, @ForEach(%arity.loc10_12.1, %U.loc10_22.1) [symbolic = %ForEach.specific_fn.loc11_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%y.param: @Forward.%pack_type.loc10_40 (%pack_type.6c62db.2)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %ForEach.ref: %ForEach.type = name_ref ForEach, file.%ForEach.decl [concrete = constants.%ForEach]
// CHECK:STDOUT:     %.loc11_11: @Forward.%pack_type.loc10_40 (%pack_type.6c62db.2) = pack_expansion_expr %.loc11_15.5 {
// CHECK:STDOUT:       %y.ref: @Forward.%pack_type.loc10_40 (%pack_type.6c62db.2) = name_ref y, %y
// CHECK:STDOUT:       %.loc11_15.1: Core.IntLiteral = pack_index [symbolic = %.loc10_42.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc11_15.2: Core.IntLiteral = pack_index [symbolic = %.loc10_42.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc11_15.3: %Code.type = pack_element constants.%U, %.loc11_15.2 [symbolic = %.loc10_42.2 (constants.%.3c6e42.2)]
// CHECK:STDOUT:       %as_type.loc11: type = facet_access_type %.loc11_15.3 [symbolic = %as_type.loc10_42.1 (constants.%as_type.0f9f76.2)]
// CHECK:STDOUT:       %.loc11_15.4: type = converted %.loc11_15.3, %as_type.loc11 [symbolic = %as_type.loc10_42.1 (constants.%as_type.0f9f76.2)]
// CHECK:STDOUT:       %.loc11_15.5: @Forward.%as_type.loc10_42.1 (%as_type.0f9f76.2) = pack_element %y.ref, %.loc11_15.1
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %ForEach.specific_fn.loc11_3.1: <specific function> = specific_function %ForEach.ref, @ForEach(constants.%arity, constants.%U) [symbolic = %ForEach.specific_fn.loc11_3.2 (constants.%ForEach.specific_fn)]
// CHECK:STDOUT:     %ForEach.call: init %empty_tuple.type = call %ForEach.specific_fn.loc11_3.1(%.loc11_11)
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Forward(constants.%arity, constants.%U) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_12.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc10_22 => constants.%pack_type.104
// CHECK:STDOUT:   %pattern_type.loc10_22 => constants.%pattern_type.2ee
// CHECK:STDOUT:   %U.patt.loc10_22.2 => constants.%U.patt
// CHECK:STDOUT:   %U.loc10_22.1 => constants.%U
// CHECK:STDOUT:   %.loc10_12.2 => constants.%.cc365a.2
// CHECK:STDOUT:   %.loc10_42.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc10_42.2 => constants.%.3c6e42.2
// CHECK:STDOUT:   %as_type.loc10_42.1 => constants.%as_type.0f9f76.2
// CHECK:STDOUT:   %pack_type.loc10_40 => constants.%pack_type.6c62db.2
// CHECK:STDOUT:   %pattern_type.loc10_40 => constants.%pattern_type.2b9e81.2
// CHECK:STDOUT:   %y.param_patt.loc10_40.2 => constants.%y.param_patt
// CHECK:STDOUT:   %y.patt.loc10_40.2 => constants.%y.patt
// CHECK:STDOUT:   %.loc10_30.2 => constants.%.997
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- method.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Code.type: type = facet_type <@Code> [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %A: type = class_type @A [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %Code.impl_witness: <witness> = impl_witness @A.as.Code.impl.%Code.impl_witness_table [concrete]
// CHECK:STDOUT:   %Code.facet: %Code.type = facet_value %A, (%Code.impl_witness) [concrete]
// CHECK:STDOUT:   %ptr.c28: type = ptr_type %empty_struct_type [concrete]
// CHECK:STDOUT:   %C: type = class_type @C [concrete]
// CHECK:STDOUT:   %C.F.type: type = fn_type @C.F [concrete]
// CHECK:STDOUT:   %C.F: %C.F.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.777: type = tuple_type (%A, %A) [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.ebfb: %pack_type.8f6 = pack_value (%A, %A) [concrete]
// CHECK:STDOUT:   %pack_type.a94: type = pack_type %Code.type, %int_2 [concrete]
// CHECK:STDOUT:   %.bb5: %pack_type.a94 = pack_value (%Code.facet, %Code.facet) [concrete]
// CHECK:STDOUT:   %pack_type.d85: type = pack_type %.bb5, %int_2 [concrete]
// CHECK:STDOUT:   %C.F.specific_fn: <specific function> = specific_function %C.F, @C.F(%int_2, %.bb5) [concrete]
// CHECK:STDOUT:   %.235: %pack_type.8f6 = pack_value (%ptr.c28, %ptr.c28) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%c.param: %C, %a.param: %A) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %c.ref: %C = name_ref c, %c
// CHECK:STDOUT:   %F.ref: %C.F.type = name_ref F, @C.%C.F.decl [concrete = constants.%C.F]
// CHECK:STDOUT:   %C.F.bound: <bound method> = bound_method %c.ref, %F.ref
// CHECK:STDOUT:   %a.ref.loc18_7: %A = name_ref a, %a
// CHECK:STDOUT:   %a.ref.loc18_10: %A = name_ref a, %a
// CHECK:STDOUT:   %.loc18_7.1: %tuple.type.777 = pack_literal (%a.ref.loc18_7, %a.ref.loc18_10)
// CHECK:STDOUT:   %int_2.loc18_11.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc18_11.1: %pack_type.8f6 = pack_value (constants.%A, constants.%A) [concrete = constants.%.ebfb]
// CHECK:STDOUT:   %int_2.loc18_11.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc18_11.2: %pack_type.8f6 = pack_value (constants.%A, constants.%A) [concrete = constants.%.ebfb]
// CHECK:STDOUT:   %Code.facet.loc18_11.1: %Code.type = facet_value constants.%A, (constants.%Code.impl_witness) [concrete = constants.%Code.facet]
// CHECK:STDOUT:   %.loc18_11.3: %Code.type = converted constants.%A, %Code.facet.loc18_11.1 [concrete = constants.%Code.facet]
// CHECK:STDOUT:   %Code.facet.loc18_11.2: %Code.type = facet_value constants.%A, (constants.%Code.impl_witness) [concrete = constants.%Code.facet]
// CHECK:STDOUT:   %.loc18_11.4: %Code.type = converted constants.%A, %Code.facet.loc18_11.2 [concrete = constants.%Code.facet]
// CHECK:STDOUT:   %.loc18_11.5: %pack_type.a94 = pack_value (%.loc18_11.3, %.loc18_11.4) [concrete = constants.%.bb5]
// CHECK:STDOUT:   %.loc18_11.6: %pack_type.a94 = converted constants.%.ebfb, %.loc18_11.5 [concrete = constants.%.bb5]
// CHECK:STDOUT:   %C.F.specific_fn: <specific function> = specific_function %F.ref, @C.F(constants.%int_2, constants.%.bb5) [concrete = constants.%C.F.specific_fn]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %c.ref, %C.F.specific_fn
// CHECK:STDOUT:   %.loc18_7.2: %pack_type.8f6 = pack_value (constants.%ptr.c28, constants.%ptr.c28) [concrete = constants.%.235]
// CHECK:STDOUT:   %.loc18_7.3: %pack_type.d85 = pack_value (%a.ref.loc18_7, %a.ref.loc18_10)
// CHECK:STDOUT:   %.loc18_7.4: %pack_type.d85 = converted %.loc18_7.1, %.loc18_7.3
// CHECK:STDOUT:   %C.F.call: init %empty_tuple.type = call %bound_method(%c.ref, %.loc18_7.4)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- qualified_member.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Code.type: type = facet_type <@Code> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Code.assoc_type: type = assoc_entity_type @Code [concrete]
// CHECK:STDOUT:   %assoc0: %Code.assoc_type = assoc_entity element0, @Code.WithSelf.%Code.WithSelf.Get.decl [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.104: type = pack_type %Code.type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.2ee: type = pattern_type %pack_type.104 [symbolic]
// CHECK:STDOUT:   %T.patt: %pattern_type.2ee = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.104 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.cc3: %pattern_type.2ee = pack_expansion_pattern %T.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.3c6: %Code.type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %as_type: type = facet_access_type %.3c6 [symbolic]
// CHECK:STDOUT:   %pack_type.6c6: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.2b9: type = pattern_type %pack_type.6c6 [symbolic]
// CHECK:STDOUT:   %x.param_patt.2a2: %pattern_type.2b9 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.27d: %pattern_type.2b9 = wrapper_binding_pattern x, %x.param_patt.2a2 [symbolic]
// CHECK:STDOUT:   %.e9e: %pattern_type.2b9 = pack_expansion_pattern %x.patt.27d, invalid [symbolic]
// CHECK:STDOUT:   %ForEach.type: type = fn_type @ForEach [concrete]
// CHECK:STDOUT:   %ForEach: %ForEach.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.aa7: <witness> = require_complete_type %pack_type.6c6 [symbolic]
// CHECK:STDOUT:   %Code.lookup_impl_witness: <witness> = lookup_impl_witness %.3c6, @Code [symbolic]
// CHECK:STDOUT:   %Code.WithSelf.Get.type.099: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.3c6) [symbolic]
// CHECK:STDOUT:   %.131: type = fn_type_with_self_type %Code.WithSelf.Get.type.099, %.3c6 [symbolic]
// CHECK:STDOUT:   %impl.elem0: %.131 = impl_witness_access %Code.lookup_impl_witness, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn: <specific function> = specific_impl_function %impl.elem0, @Code.WithSelf.Get(%.3c6) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ForEach.decl: %ForEach.type = fn_decl @ForEach [concrete = constants.%ForEach] {
// CHECK:STDOUT:     %arity.patt.loc10_12.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc10_22.1: @ForEach.%pattern_type.loc10_22 (%pattern_type.2ee) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc10_22.2 (constants.%T.patt)]
// CHECK:STDOUT:     %.loc10_12.1: @ForEach.%pattern_type.loc10_22 (%pattern_type.2ee) = pack_expansion_pattern %T.patt.loc10_22.1, %arity.patt.loc10_12.1 [symbolic = %.loc10_12.2 (constants.%.cc3)]
// CHECK:STDOUT:     %x.param_patt.loc10_40.1: @ForEach.%pattern_type.loc10_40 (%pattern_type.2b9) = value_param_pattern [symbolic = %x.param_patt.loc10_40.2 (constants.%x.param_patt.2a2)]
// CHECK:STDOUT:     %x.patt.loc10_40.1: @ForEach.%pattern_type.loc10_40 (%pattern_type.2b9) = wrapper_binding_pattern x, %x.param_patt.loc10_40.1 [symbolic = %x.patt.loc10_40.2 (constants.%x.patt.27d)]
// CHECK:STDOUT:     %.loc10_30.1: @ForEach.%pattern_type.loc10_40 (%pattern_type.2b9) = pack_expansion_pattern %x.patt.loc10_40.1, invalid [symbolic = %.loc10_30.2 (constants.%.e9e)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %arity.loc10_12.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc10_24: type = splice_block %Code.ref.loc10 [concrete = constants.%Code.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Code.ref.loc10: type = name_ref Code, file.%Code.decl [concrete = constants.%Code.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_22.2: @ForEach.%pack_type.loc10_22 (%pack_type.104) = symbolic_binding T, 1 [symbolic = %T.loc10_22.1 (constants.%T)]
// CHECK:STDOUT:     %x.param: @ForEach.%pack_type.loc10_40 (%pack_type.6c6) = value_param call_param0
// CHECK:STDOUT:     %.loc10_42.3: type = splice_block %.loc10_42.6 [symbolic = %as_type.loc10_42.1 (constants.%as_type)] {
// CHECK:STDOUT:       %T.ref: @ForEach.%pack_type.loc10_22 (%pack_type.104) = name_ref T, %T.loc10_22.2 [symbolic = %T.loc10_22.1 (constants.%T)]
// CHECK:STDOUT:       %.loc10_42.4: Core.IntLiteral = pack_index [symbolic = %.loc10_42.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc10_42.5: %Code.type = pack_element %T.ref, %.loc10_42.4 [symbolic = %.loc10_42.2 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc10_42.2: type = facet_access_type %.loc10_42.5 [symbolic = %as_type.loc10_42.1 (constants.%as_type)]
// CHECK:STDOUT:       %.loc10_42.6: type = converted %.loc10_42.5, %as_type.loc10_42.2 [symbolic = %as_type.loc10_42.1 (constants.%as_type)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @ForEach.%pack_type.loc10_40 (%pack_type.6c6) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @ForEach(%arity.loc10_12.2: Core.IntLiteral, %T.loc10_22.2: @ForEach.%pack_type.loc10_22 (%pack_type.104)) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc10_12.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc10_12.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc10_12.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc10_22: type = pack_type constants.%Code.type, %arity.loc10_12.1 [symbolic = %pack_type.loc10_22 (constants.%pack_type.104)]
// CHECK:STDOUT:   %pattern_type.loc10_22: type = pattern_type %pack_type.loc10_22 [symbolic = %pattern_type.loc10_22 (constants.%pattern_type.2ee)]
// CHECK:STDOUT:   %T.patt.loc10_22.2: @ForEach.%pattern_type.loc10_22 (%pattern_type.2ee) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc10_22.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc10_22.1: @ForEach.%pack_type.loc10_22 (%pack_type.104) = symbolic_binding T, 1 [symbolic = %T.loc10_22.1 (constants.%T)]
// CHECK:STDOUT:   %.loc10_12.2: @ForEach.%pattern_type.loc10_22 (%pattern_type.2ee) = pack_expansion_pattern %T.patt.loc10_22.2, %arity.patt.loc10_12.2 [symbolic = %.loc10_12.2 (constants.%.cc3)]
// CHECK:STDOUT:   %.loc10_42.1: Core.IntLiteral = pack_index [symbolic = %.loc10_42.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc10_42.2: %Code.type = pack_element %T.loc10_22.1, %.loc10_42.1 [symbolic = %.loc10_42.2 (constants.%.3c6)]
// CHECK:STDOUT:   %as_type.loc10_42.1: type = facet_access_type %.loc10_42.2 [symbolic = %as_type.loc10_42.1 (constants.%as_type)]
// CHECK:STDOUT:   %pack_type.loc10_40: type = pack_type %T.loc10_22.1, %arity.loc10_12.1 [symbolic = %pack_type.loc10_40 (constants.%pack_type.6c6)]
// CHECK:STDOUT:   %pattern_type.loc10_40: type = pattern_type %pack_type.loc10_40 [symbolic = %pattern_type.loc10_40 (constants.%pattern_type.2b9)]
// CHECK:STDOUT:   %x.param_patt.loc10_40.2: @ForEach.%pattern_type.loc10_40 (%pattern_type.2b9) = value_param_pattern [symbolic = %x.param_patt.loc10_40.2 (constants.%x.param_patt.2a2)]
// CHECK:STDOUT:   %x.patt.loc10_40.2: @ForEach.%pattern_type.loc10_40 (%pattern_type.2b9) = wrapper_binding_pattern x, %x.param_patt.loc10_40.2 [symbolic = %x.patt.loc10_40.2 (constants.%x.patt.27d)]
// CHECK:STDOUT:   %.loc10_30.2: @ForEach.%pattern_type.loc10_40 (%pattern_type.2b9) = pack_expansion_pattern %x.patt.loc10_40.2, invalid [symbolic = %.loc10_30.2 (constants.%.e9e)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %pack_type.loc10_40 [symbolic = %require_complete (constants.%require_complete.aa7)]
// CHECK:STDOUT:   %Code.WithSelf.Get.type: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.loc10_42.2) [symbolic = %Code.WithSelf.Get.type (constants.%Code.WithSelf.Get.type.099)]
// CHECK:STDOUT:   %.loc11_21: type = fn_type_with_self_type %Code.WithSelf.Get.type, %.loc10_42.2 [symbolic = %.loc11_21 (constants.%.131)]
// CHECK:STDOUT:   %Code.lookup_impl_witness: <witness> = lookup_impl_witness %.loc10_42.2, @Code [symbolic = %Code.lookup_impl_witness (constants.%Code.lookup_impl_witness)]
// CHECK:STDOUT:   %impl.elem0.loc11_21.2: @ForEach.%.loc11_21 (%.131) = impl_witness_access %Code.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc11_21.2 (constants.%impl.elem0)]
// CHECK:STDOUT:   %specific_impl_fn.loc11_21.2: <specific function> = specific_impl_function %impl.elem0.loc11_21.2, @Code.WithSelf.Get(%.loc10_42.2) [symbolic = %specific_impl_fn.loc11_21.2 (constants.%specific_impl_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%x.param: @ForEach.%pack_type.loc10_40 (%pack_type.6c6)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc10_12.2 {
// CHECK:STDOUT:       %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %x.ref: @ForEach.%pack_type.loc10_40 (%pack_type.6c6) = name_ref x, %x
// CHECK:STDOUT:       %.loc11_15.1: Core.IntLiteral = pack_index [symbolic = %.loc10_42.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc11_15.2: Core.IntLiteral = pack_index [symbolic = %.loc10_42.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc11_15.3: %Code.type = pack_element constants.%T, %.loc11_15.2 [symbolic = %.loc10_42.2 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc11: type = facet_access_type %.loc11_15.3 [symbolic = %as_type.loc10_42.1 (constants.%as_type)]
// CHECK:STDOUT:       %.loc11_15.4: type = converted %.loc11_15.3, %as_type.loc11 [symbolic = %as_type.loc10_42.1 (constants.%as_type)]
// CHECK:STDOUT:       %.loc11_15.5: @ForEach.%as_type.loc10_42.1 (%as_type) = pack_element %x.ref, %.loc11_15.1
// CHECK:STDOUT:       %Code.ref.loc11: type = name_ref Code, file.%Code.decl [concrete = constants.%Code.type]
// CHECK:STDOUT:       %Get.ref: %Code.assoc_type = name_ref Get, @Code.WithSelf.%assoc0 [concrete = constants.%assoc0]
// CHECK:STDOUT:       %impl.elem0.loc11_21.1: @ForEach.%.loc11_21 (%.131) = impl_witness_access constants.%Code.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc11_21.2 (constants.%impl.elem0)]
// CHECK:STDOUT:       %bound_method.loc11_21: <bound method> = bound_method %.loc11_15.5, %impl.elem0.loc11_21.1
// CHECK:STDOUT:       %.loc11_33.1: %Code.type = converted constants.%as_type, constants.%.3c6 [symbolic = %.loc10_42.2 (constants.%.3c6)]
// CHECK:STDOUT:       %.loc11_33.2: %Code.type = converted constants.%as_type, constants.%.3c6 [symbolic = %.loc10_42.2 (constants.%.3c6)]
// CHECK:STDOUT:       %specific_impl_fn.loc11_21.1: <specific function> = specific_impl_function %impl.elem0.loc11_21.1, @Code.WithSelf.Get(constants.%.3c6) [symbolic = %specific_impl_fn.loc11_21.2 (constants.%specific_impl_fn)]
// CHECK:STDOUT:       %bound_method.loc11_33: <bound method> = bound_method %.loc11_15.5, %specific_impl_fn.loc11_21.1
// CHECK:STDOUT:       %Code.WithSelf.Get.call: init %i64 = call %bound_method.loc11_33(%.loc11_15.5)
// CHECK:STDOUT:       %.loc11_33.3: %i64 = value_of_initializer %Code.WithSelf.Get.call
// CHECK:STDOUT:       %.loc11_33.4: %i64 = converted %Code.WithSelf.Get.call, %.loc11_33.3
// CHECK:STDOUT:       %Consume.call: init %empty_tuple.type = call %Consume.ref(%.loc11_33.4)
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ForEach(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity.patt.loc10_12.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_12.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc10_22 => constants.%pack_type.104
// CHECK:STDOUT:   %pattern_type.loc10_22 => constants.%pattern_type.2ee
// CHECK:STDOUT:   %T.patt.loc10_22.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc10_22.1 => constants.%T
// CHECK:STDOUT:   %.loc10_12.2 => constants.%.cc3
// CHECK:STDOUT:   %.loc10_42.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc10_42.2 => constants.%.3c6
// CHECK:STDOUT:   %as_type.loc10_42.1 => constants.%as_type
// CHECK:STDOUT:   %pack_type.loc10_40 => constants.%pack_type.6c6
// CHECK:STDOUT:   %pattern_type.loc10_40 => constants.%pattern_type.2b9
// CHECK:STDOUT:   %x.param_patt.loc10_40.2 => constants.%x.param_patt.2a2
// CHECK:STDOUT:   %x.patt.loc10_40.2 => constants.%x.patt.27d
// CHECK:STDOUT:   %.loc10_30.2 => constants.%.e9e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- template_outer.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasV.type: type = facet_type <@HasV> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %HasV.assoc_type: type = assoc_entity_type @HasV [concrete]
// CHECK:STDOUT:   %assoc0.9a7: %HasV.assoc_type = assoc_entity element0, @HasV.WithSelf.%HasV.WithSelf.V.decl [concrete]
// CHECK:STDOUT:   %G: type = class_type @G [concrete]
// CHECK:STDOUT:   %G.elem: type = unbound_element_type %G, %i64 [concrete]
// CHECK:STDOUT:   %struct_type.n: type = struct_type {.n: %i64} [concrete]
// CHECK:STDOUT:   %complete_type.d65: <witness> = complete_type_witness %struct_type.n [concrete]
// CHECK:STDOUT:   %HasV.impl_witness.f5b: <witness> = impl_witness @i64.as.HasV.impl.%HasV.impl_witness_table [concrete]
// CHECK:STDOUT:   %HasV.facet.c93: %HasV.type = facet_value %i64, (%HasV.impl_witness.f5b) [concrete]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %HasV.impl_witness.52b: <witness> = impl_witness @bool.as.HasV.impl.%HasV.impl_witness_table [concrete]
// CHECK:STDOUT:   %HasV.facet.37f: %HasV.type = facet_value bool, (%HasV.impl_witness.52b) [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %U.patt.3a0: %pattern_type.9a5 = symbolic_binding_pattern U, 0, template [template]
// CHECK:STDOUT:   %U.67d: type = symbolic_binding U, 0, template [template]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %pack_type.0f8: type = pack_type %HasV.type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.dbb: type = pattern_type %pack_type.0f8 [symbolic]
// CHECK:STDOUT:   %T.patt.f44: %pattern_type.dbb = symbolic_binding_pattern T, 2 [symbolic]
// CHECK:STDOUT:   %T.c2e: %pack_type.0f8 = symbolic_binding T, 2 [symbolic]
// CHECK:STDOUT:   %.934: %pattern_type.dbb = pack_expansion_pattern %T.patt.f44, %arity.patt [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.2: type = pattern_type %U.67d [template]
// CHECK:STDOUT:   %u.param_patt.684: %pattern_type.51d1c4.2 = value_param_pattern [template]
// CHECK:STDOUT:   %u.patt.760: %pattern_type.51d1c4.2 = wrapper_binding_pattern u, %u.param_patt.684 [template]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.e2c: %HasV.type = pack_element %T.c2e, %.4ee [symbolic]
// CHECK:STDOUT:   %as_type.0a3: type = facet_access_type %.e2c [symbolic]
// CHECK:STDOUT:   %pack_type.c70: type = pack_type %T.c2e, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.e1a: type = pattern_type %pack_type.c70 [symbolic]
// CHECK:STDOUT:   %x.param_patt.740: %pattern_type.e1a = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.dd8: %pattern_type.e1a = wrapper_binding_pattern x, %x.param_patt.740 [symbolic]
// CHECK:STDOUT:   %.9ce: %pattern_type.e1a = pack_expansion_pattern %x.patt.dd8, invalid [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.944: <witness> = require_complete_type %U.67d [template]
// CHECK:STDOUT:   %require_complete.e40: <witness> = require_complete_type %pack_type.c70 [symbolic]
// CHECK:STDOUT:   %.237: type = type_of_inst @F.%.loc23_16.3 [template]
// CHECK:STDOUT:   %.f96: %.237 = splice_inst @F.%.loc23_16.3 [template]
// CHECK:STDOUT:   %require_complete.7b8: <witness> = require_complete_type %as_type.0a3 [symbolic]
// CHECK:STDOUT:   %HasV.WithSelf.V.type.105: type = fn_type @HasV.WithSelf.V, @HasV.WithSelf(%.e2c) [symbolic]
// CHECK:STDOUT:   %HasV.lookup_impl_witness.011: <witness> = lookup_impl_witness %.e2c, @HasV [symbolic]
// CHECK:STDOUT:   %.fcc: type = fn_type_with_self_type %HasV.WithSelf.V.type.105, %.e2c [symbolic]
// CHECK:STDOUT:   %impl.elem0.434: %.fcc = impl_witness_access %HasV.lookup_impl_witness.011, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.e7b: <specific function> = specific_impl_function %impl.elem0.434, @HasV.WithSelf.V(%.e2c) [symbolic]
// CHECK:STDOUT:   %.668: type = type_of_inst @F.%.loc23_30.4 [template]
// CHECK:STDOUT:   %.c9b: %.668 = splice_inst @F.%.loc23_30.4 [template]
// CHECK:STDOUT:   %require_complete.15f: <witness> = require_complete_type %.668 [template]
// CHECK:STDOUT:   %.d38: %.668 = splice_inst @F.%.loc23_30.7 [template]
// CHECK:STDOUT:   %pattern_type.721: type = pattern_type %G [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.c7c: type = pack_type %HasV.type, %int_2 [concrete]
// CHECK:STDOUT:   %.2b4: %pack_type.c7c = pack_value (%HasV.facet.c93, %HasV.facet.37f) [concrete]
// CHECK:STDOUT:   %pattern_type.fd8: type = pattern_type %pack_type.c7c [concrete]
// CHECK:STDOUT:   %T.patt.220: %pattern_type.fd8 = symbolic_binding_pattern T, 2 [symbolic]
// CHECK:STDOUT:   %.0eae: %pattern_type.fd8 = pack_expansion_pattern %T.patt.220, %arity.patt [symbolic]
// CHECK:STDOUT:   %u.param_patt.837: %pattern_type.721 = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt.d7a: %pattern_type.721 = wrapper_binding_pattern u, %u.param_patt.837 [concrete]
// CHECK:STDOUT:   %.af9: %HasV.type = pack_element %.2b4, %.4ee [symbolic]
// CHECK:STDOUT:   %as_type.0ec: type = facet_access_type %.af9 [symbolic]
// CHECK:STDOUT:   %pack_type.b43: type = pack_type %.2b4, %int_2 [concrete]
// CHECK:STDOUT:   %pattern_type.472: type = pattern_type %pack_type.b43 [concrete]
// CHECK:STDOUT:   %x.param_patt.15a: %pattern_type.472 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.9de: %pattern_type.472 = wrapper_binding_pattern x, %x.param_patt.15a [concrete]
// CHECK:STDOUT:   %.c6e: %pattern_type.472 = pack_expansion_pattern %x.patt.9de, invalid [concrete]
// CHECK:STDOUT:   %complete_type.ec5: <witness> = complete_type_witness %pack_type.b43 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.23c805.1: %i64 = splice_block %.0eab45.3 {
// CHECK:STDOUT:       %.b0264f.3: %G = specific_inst @F.%u.ref, @F(%G, %int_2, %.2b4)
// CHECK:STDOUT:       %n.ref.fa2776.3: %G.elem = name_ref n, @G.%field_decl [concrete = @G.%field_decl]
// CHECK:STDOUT:       %.1194f0.3: ref %i64 = class_element_access %.b0264f.3, element0
// CHECK:STDOUT:       %.0eab45.3: %i64 = acquire_value %.1194f0.3
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %require_complete.917: <witness> = require_complete_type %as_type.0ec [symbolic]
// CHECK:STDOUT:   %HasV.WithSelf.V.type.e05: type = fn_type @HasV.WithSelf.V, @HasV.WithSelf(%.af9) [symbolic]
// CHECK:STDOUT:   %.6c6: type = fn_type_with_self_type %HasV.WithSelf.V.type.e05, %.af9 [symbolic]
// CHECK:STDOUT:   %HasV.lookup_impl_witness.4c7: <witness> = lookup_impl_witness %.af9, @HasV [symbolic]
// CHECK:STDOUT:   %impl.elem0.e0d: %.6c6 = impl_witness_access %HasV.lookup_impl_witness.4c7, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.2f9: <specific function> = specific_impl_function %impl.elem0.e0d, @HasV.WithSelf.V(%.af9) [symbolic]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.d16f49.1: init %empty_tuple.type = splice_block %Consume.call.e2690d.3 {
// CHECK:STDOUT:       %.e68a44.3: %i64 = value_of_initializer @F.%HasV.WithSelf.V.call
// CHECK:STDOUT:       %.91b70b.3: %i64 = converted @F.%HasV.WithSelf.V.call, %.e68a44.3
// CHECK:STDOUT:       %Consume.call.e2690d.3: init %empty_tuple.type = call %Consume(%.23c805.1, %.91b70b.3)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %complete_type.782: <witness> = complete_type_witness %empty_tuple.type [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.60fd22.1: init %empty_tuple.type = splice_block %.d16f49.1 {}
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %U.patt.loc22_16.1: %pattern_type.9a5 = symbolic_binding_pattern U, 0, template [template = %U.patt.loc22_16.2 (constants.%U.patt.3a0)]
// CHECK:STDOUT:     %arity.patt.loc22_24.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc22_24.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc22_34.1: @F.%pattern_type.loc22_34 (%pattern_type.dbb) = symbolic_binding_pattern T, 2 [symbolic = %T.patt.loc22_34.2 (constants.%T.patt.f44)]
// CHECK:STDOUT:     %.loc22_24.1: @F.%pattern_type.loc22_34 (%pattern_type.dbb) = pack_expansion_pattern %T.patt.loc22_34.1, %arity.patt.loc22_24.1 [symbolic = %.loc22_24.2 (constants.%.934)]
// CHECK:STDOUT:     %u.param_patt.loc22_43.1: @F.%pattern_type.loc22_43 (%pattern_type.51d1c4.2) = value_param_pattern [template = %u.param_patt.loc22_43.2 (constants.%u.param_patt.684)]
// CHECK:STDOUT:     %u.patt.loc22_43.1: @F.%pattern_type.loc22_43 (%pattern_type.51d1c4.2) = wrapper_binding_pattern u, %u.param_patt.loc22_43.1 [template = %u.patt.loc22_43.2 (constants.%u.patt.760)]
// CHECK:STDOUT:     %x.param_patt.loc22_58.1: @F.%pattern_type.loc22_58 (%pattern_type.e1a) = value_param_pattern [symbolic = %x.param_patt.loc22_58.2 (constants.%x.param_patt.740)]
// CHECK:STDOUT:     %x.patt.loc22_58.1: @F.%pattern_type.loc22_58 (%pattern_type.e1a) = wrapper_binding_pattern x, %x.param_patt.loc22_58.1 [symbolic = %x.patt.loc22_58.2 (constants.%x.patt.dd8)]
// CHECK:STDOUT:     %.loc22_48.1: @F.%pattern_type.loc22_58 (%pattern_type.e1a) = pack_expansion_pattern %x.patt.loc22_58.1, invalid [symbolic = %.loc22_48.2 (constants.%.9ce)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc22_18.1: type = splice_block %.loc22_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc22_16: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc22_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %U.loc22_16.2: type = symbolic_binding U, 0, template [template = %U.loc22_16.1 (constants.%U.67d)]
// CHECK:STDOUT:     %arity.loc22_24.2: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc22_24.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc22_36: type = splice_block %HasV.ref [concrete = constants.%HasV.type] {
// CHECK:STDOUT:       %.Self.frozen.loc22_34: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %HasV.ref: type = name_ref HasV, file.%HasV.decl [concrete = constants.%HasV.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc22_34.2: @F.%pack_type.loc22_34 (%pack_type.0f8) = symbolic_binding T, 2 [symbolic = %T.loc22_34.1 (constants.%T.c2e)]
// CHECK:STDOUT:     %u.param: @F.%U.loc22_16.1 (%U.67d) = value_param call_param0
// CHECK:STDOUT:     %U.ref: type = name_ref U, %U.loc22_16.2 [template = %U.loc22_16.1 (constants.%U.67d)]
// CHECK:STDOUT:     %u: @F.%U.loc22_16.1 (%U.67d) = wrapper_binding u, %u.param
// CHECK:STDOUT:     %x.param: @F.%pack_type.loc22_58 (%pack_type.c70) = value_param call_param1
// CHECK:STDOUT:     %.loc22_60.3: type = splice_block %.loc22_60.6 [symbolic = %as_type.loc22_60.1 (constants.%as_type.0a3)] {
// CHECK:STDOUT:       %T.ref: @F.%pack_type.loc22_34 (%pack_type.0f8) = name_ref T, %T.loc22_34.2 [symbolic = %T.loc22_34.1 (constants.%T.c2e)]
// CHECK:STDOUT:       %.loc22_60.4: Core.IntLiteral = pack_index [symbolic = %.loc22_60.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc22_60.5: %HasV.type = pack_element %T.ref, %.loc22_60.4 [symbolic = %.loc22_60.2 (constants.%.e2c)]
// CHECK:STDOUT:       %as_type.loc22_60.2: type = facet_access_type %.loc22_60.5 [symbolic = %as_type.loc22_60.1 (constants.%as_type.0a3)]
// CHECK:STDOUT:       %.loc22_60.6: type = converted %.loc22_60.5, %as_type.loc22_60.2 [symbolic = %as_type.loc22_60.1 (constants.%as_type.0a3)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @F.%pack_type.loc22_58 (%pack_type.c70) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%U.loc22_16.2: type, %arity.loc22_24.2: Core.IntLiteral, %T.loc22_34.2: @F.%pack_type.loc22_34 (%pack_type.0f8)) {
// CHECK:STDOUT:   %U.patt.loc22_16.2: %pattern_type.9a5 = symbolic_binding_pattern U, 0, template [template = %U.patt.loc22_16.2 (constants.%U.patt.3a0)]
// CHECK:STDOUT:   %U.loc22_16.1: type = symbolic_binding U, 0, template [template = %U.loc22_16.1 (constants.%U.67d)]
// CHECK:STDOUT:   %arity.patt.loc22_24.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc22_24.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc22_24.1: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc22_24.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc22_34: type = pack_type constants.%HasV.type, %arity.loc22_24.1 [symbolic = %pack_type.loc22_34 (constants.%pack_type.0f8)]
// CHECK:STDOUT:   %pattern_type.loc22_34: type = pattern_type %pack_type.loc22_34 [symbolic = %pattern_type.loc22_34 (constants.%pattern_type.dbb)]
// CHECK:STDOUT:   %T.patt.loc22_34.2: @F.%pattern_type.loc22_34 (%pattern_type.dbb) = symbolic_binding_pattern T, 2 [symbolic = %T.patt.loc22_34.2 (constants.%T.patt.f44)]
// CHECK:STDOUT:   %T.loc22_34.1: @F.%pack_type.loc22_34 (%pack_type.0f8) = symbolic_binding T, 2 [symbolic = %T.loc22_34.1 (constants.%T.c2e)]
// CHECK:STDOUT:   %.loc22_24.2: @F.%pattern_type.loc22_34 (%pattern_type.dbb) = pack_expansion_pattern %T.patt.loc22_34.2, %arity.patt.loc22_24.2 [symbolic = %.loc22_24.2 (constants.%.934)]
// CHECK:STDOUT:   %pattern_type.loc22_43: type = pattern_type %U.loc22_16.1 [template = %pattern_type.loc22_43 (constants.%pattern_type.51d1c4.2)]
// CHECK:STDOUT:   %u.param_patt.loc22_43.2: @F.%pattern_type.loc22_43 (%pattern_type.51d1c4.2) = value_param_pattern [template = %u.param_patt.loc22_43.2 (constants.%u.param_patt.684)]
// CHECK:STDOUT:   %u.patt.loc22_43.2: @F.%pattern_type.loc22_43 (%pattern_type.51d1c4.2) = wrapper_binding_pattern u, %u.param_patt.loc22_43.2 [template = %u.patt.loc22_43.2 (constants.%u.patt.760)]
// CHECK:STDOUT:   %.loc22_60.1: Core.IntLiteral = pack_index [symbolic = %.loc22_60.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc22_60.2: %HasV.type = pack_element %T.loc22_34.1, %.loc22_60.1 [symbolic = %.loc22_60.2 (constants.%.e2c)]
// CHECK:STDOUT:   %as_type.loc22_60.1: type = facet_access_type %.loc22_60.2 [symbolic = %as_type.loc22_60.1 (constants.%as_type.0a3)]
// CHECK:STDOUT:   %pack_type.loc22_58: type = pack_type %T.loc22_34.1, %arity.loc22_24.1 [symbolic = %pack_type.loc22_58 (constants.%pack_type.c70)]
// CHECK:STDOUT:   %pattern_type.loc22_58: type = pattern_type %pack_type.loc22_58 [symbolic = %pattern_type.loc22_58 (constants.%pattern_type.e1a)]
// CHECK:STDOUT:   %x.param_patt.loc22_58.2: @F.%pattern_type.loc22_58 (%pattern_type.e1a) = value_param_pattern [symbolic = %x.param_patt.loc22_58.2 (constants.%x.param_patt.740)]
// CHECK:STDOUT:   %x.patt.loc22_58.2: @F.%pattern_type.loc22_58 (%pattern_type.e1a) = wrapper_binding_pattern x, %x.param_patt.loc22_58.2 [symbolic = %x.patt.loc22_58.2 (constants.%x.patt.dd8)]
// CHECK:STDOUT:   %.loc22_48.2: @F.%pattern_type.loc22_58 (%pattern_type.e1a) = pack_expansion_pattern %x.patt.loc22_58.2, invalid [symbolic = %.loc22_48.2 (constants.%.9ce)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc22_43: <witness> = require_complete_type %U.loc22_16.1 [template = %require_complete.loc22_43 (constants.%require_complete.944)]
// CHECK:STDOUT:   %require_complete.loc22_58: <witness> = require_complete_type %pack_type.loc22_58 [symbolic = %require_complete.loc22_58 (constants.%require_complete.e40)]
// CHECK:STDOUT:   %.loc23_16.3: <instruction> = access_member_action %u.ref, n [template]
// CHECK:STDOUT:   %.loc23_16.4: type = type_of_inst %.loc23_16.3 [template = %.loc23_16.4 (constants.%.237)]
// CHECK:STDOUT:   %.loc23_16.5: @F.%.loc23_16.4 (%.237) = splice_inst %.loc23_16.3 [template = %.loc23_16.5 (constants.%.f96)]
// CHECK:STDOUT:   %require_complete.loc23_20: <witness> = require_complete_type %as_type.loc22_60.1 [symbolic = %require_complete.loc23_20 (constants.%require_complete.7b8)]
// CHECK:STDOUT:   %HasV.WithSelf.V.type: type = fn_type @HasV.WithSelf.V, @HasV.WithSelf(%.loc22_60.2) [symbolic = %HasV.WithSelf.V.type (constants.%HasV.WithSelf.V.type.105)]
// CHECK:STDOUT:   %.loc23_26: type = fn_type_with_self_type %HasV.WithSelf.V.type, %.loc22_60.2 [symbolic = %.loc23_26 (constants.%.fcc)]
// CHECK:STDOUT:   %HasV.lookup_impl_witness: <witness> = lookup_impl_witness %.loc22_60.2, @HasV [symbolic = %HasV.lookup_impl_witness (constants.%HasV.lookup_impl_witness.011)]
// CHECK:STDOUT:   %impl.elem0.loc23_26.2: @F.%.loc23_26 (%.fcc) = impl_witness_access %HasV.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc23_26.2 (constants.%impl.elem0.434)]
// CHECK:STDOUT:   %specific_impl_fn.loc23_26.2: <specific function> = specific_impl_function %impl.elem0.loc23_26.2, @HasV.WithSelf.V(%.loc22_60.2) [symbolic = %specific_impl_fn.loc23_26.2 (constants.%specific_impl_fn.e7b)]
// CHECK:STDOUT:   %.loc23_30.4: <instruction> = call_action (%Consume.ref, %.loc23_16.2, %HasV.WithSelf.V.call), false [template]
// CHECK:STDOUT:   %.loc23_30.5: type = type_of_inst %.loc23_30.4 [template = %.loc23_30.5 (constants.%.668)]
// CHECK:STDOUT:   %.loc23_30.6: @F.%.loc23_30.5 (%.668) = splice_inst %.loc23_30.4 [template = %.loc23_30.6 (constants.%.c9b)]
// CHECK:STDOUT:   %require_complete.loc23_30: <witness> = require_complete_type %.loc23_30.5 [template = %require_complete.loc23_30 (constants.%require_complete.15f)]
// CHECK:STDOUT:   %.loc23_30.7: <instruction> = convert_to_category_action %.loc23_30.2, element9 [template]
// CHECK:STDOUT:   %.loc23_30.8: @F.%.loc23_30.5 (%.668) = splice_inst %.loc23_30.7 [template = %.loc23_30.8 (constants.%.d38)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%u.param: @F.%U.loc22_16.1 (%U.67d), %x.param: @F.%pack_type.loc22_58 (%pack_type.c70)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc22_24.2 {
// CHECK:STDOUT:       %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %u.ref: @F.%U.loc22_16.1 (%U.67d) = name_ref u, %u
// CHECK:STDOUT:       %.loc23_16.1: type = type_of_inst %.loc23_16.3 [template = %.loc23_16.4 (constants.%.237)]
// CHECK:STDOUT:       %.loc23_16.2: @F.%.loc23_16.4 (%.237) = splice_inst %.loc23_16.3 [template = %.loc23_16.5 (constants.%.f96)]
// CHECK:STDOUT:       %x.ref: @F.%pack_type.loc22_58 (%pack_type.c70) = name_ref x, %x
// CHECK:STDOUT:       %.loc23_20.1: Core.IntLiteral = pack_index [symbolic = %.loc22_60.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc23_20.2: Core.IntLiteral = pack_index [symbolic = %.loc22_60.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc23_20.3: %HasV.type = pack_element constants.%T.c2e, %.loc23_20.2 [symbolic = %.loc22_60.2 (constants.%.e2c)]
// CHECK:STDOUT:       %as_type.loc23: type = facet_access_type %.loc23_20.3 [symbolic = %as_type.loc22_60.1 (constants.%as_type.0a3)]
// CHECK:STDOUT:       %.loc23_20.4: type = converted %.loc23_20.3, %as_type.loc23 [symbolic = %as_type.loc22_60.1 (constants.%as_type.0a3)]
// CHECK:STDOUT:       %.loc23_20.5: @F.%as_type.loc22_60.1 (%as_type.0a3) = pack_element %x.ref, %.loc23_20.1
// CHECK:STDOUT:       %V.ref: %HasV.assoc_type = name_ref V, @HasV.WithSelf.%assoc0 [concrete = constants.%assoc0.9a7]
// CHECK:STDOUT:       %impl.elem0.loc23_26.1: @F.%.loc23_26 (%.fcc) = impl_witness_access constants.%HasV.lookup_impl_witness.011, element0 [symbolic = %impl.elem0.loc23_26.2 (constants.%impl.elem0.434)]
// CHECK:STDOUT:       %bound_method.loc23_26: <bound method> = bound_method %.loc23_20.5, %impl.elem0.loc23_26.1
// CHECK:STDOUT:       %.loc23_29.1: %HasV.type = converted constants.%as_type.0a3, constants.%.e2c [symbolic = %.loc22_60.2 (constants.%.e2c)]
// CHECK:STDOUT:       %.loc23_29.2: %HasV.type = converted constants.%as_type.0a3, constants.%.e2c [symbolic = %.loc22_60.2 (constants.%.e2c)]
// CHECK:STDOUT:       %specific_impl_fn.loc23_26.1: <specific function> = specific_impl_function %impl.elem0.loc23_26.1, @HasV.WithSelf.V(constants.%.e2c) [symbolic = %specific_impl_fn.loc23_26.2 (constants.%specific_impl_fn.e7b)]
// CHECK:STDOUT:       %bound_method.loc23_29: <bound method> = bound_method %.loc23_20.5, %specific_impl_fn.loc23_26.1
// CHECK:STDOUT:       %HasV.WithSelf.V.call: init %i64 = call %bound_method.loc23_29(%.loc23_20.5)
// CHECK:STDOUT:       %.loc23_30.1: type = type_of_inst %.loc23_30.4 [template = %.loc23_30.5 (constants.%.668)]
// CHECK:STDOUT:       %.loc23_30.2: @F.%.loc23_30.5 (%.668) = splice_inst %.loc23_30.4 [template = %.loc23_30.6 (constants.%.c9b)]
// CHECK:STDOUT:       %.loc23_30.3: @F.%.loc23_30.5 (%.668) = splice_inst %.loc23_30.7 [template = %.loc23_30.8 (constants.%.d38)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%U.67d, constants.%arity, constants.%T.c2e) {
// CHECK:STDOUT:   %U.patt.loc22_16.2 => constants.%U.patt.3a0
// CHECK:STDOUT:   %U.loc22_16.1 => constants.%U.67d
// CHECK:STDOUT:   %arity.patt.loc22_24.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc22_24.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc22_34 => constants.%pack_type.0f8
// CHECK:STDOUT:   %pattern_type.loc22_34 => constants.%pattern_type.dbb
// CHECK:STDOUT:   %T.patt.loc22_34.2 => constants.%T.patt.f44
// CHECK:STDOUT:   %T.loc22_34.1 => constants.%T.c2e
// CHECK:STDOUT:   %.loc22_24.2 => constants.%.934
// CHECK:STDOUT:   %pattern_type.loc22_43 => constants.%pattern_type.51d1c4.2
// CHECK:STDOUT:   %u.param_patt.loc22_43.2 => constants.%u.param_patt.684
// CHECK:STDOUT:   %u.patt.loc22_43.2 => constants.%u.patt.760
// CHECK:STDOUT:   %.loc22_60.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc22_60.2 => constants.%.e2c
// CHECK:STDOUT:   %as_type.loc22_60.1 => constants.%as_type.0a3
// CHECK:STDOUT:   %pack_type.loc22_58 => constants.%pack_type.c70
// CHECK:STDOUT:   %pattern_type.loc22_58 => constants.%pattern_type.e1a
// CHECK:STDOUT:   %x.param_patt.loc22_58.2 => constants.%x.param_patt.740
// CHECK:STDOUT:   %x.patt.loc22_58.2 => constants.%x.patt.dd8
// CHECK:STDOUT:   %.loc22_48.2 => constants.%.9ce
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%G, constants.%int_2, constants.%.2b4) {
// CHECK:STDOUT:   %U.patt.loc22_16.2 => constants.%U.patt.3a0
// CHECK:STDOUT:   %U.loc22_16.1 => constants.%G
// CHECK:STDOUT:   %arity.patt.loc22_24.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc22_24.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc22_34 => constants.%pack_type.c7c
// CHECK:STDOUT:   %pattern_type.loc22_34 => constants.%pattern_type.fd8
// CHECK:STDOUT:   %T.patt.loc22_34.2 => constants.%T.patt.220
// CHECK:STDOUT:   %T.loc22_34.1 => constants.%.2b4
// CHECK:STDOUT:   %.loc22_24.2 => constants.%.0eae
// CHECK:STDOUT:   %pattern_type.loc22_43 => constants.%pattern_type.721
// CHECK:STDOUT:   %u.param_patt.loc22_43.2 => constants.%u.param_patt.837
// CHECK:STDOUT:   %u.patt.loc22_43.2 => constants.%u.patt.d7a
// CHECK:STDOUT:   %.loc22_60.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc22_60.2 => constants.%.af9
// CHECK:STDOUT:   %as_type.loc22_60.1 => constants.%as_type.0ec
// CHECK:STDOUT:   %pack_type.loc22_58 => constants.%pack_type.b43
// CHECK:STDOUT:   %pattern_type.loc22_58 => constants.%pattern_type.472
// CHECK:STDOUT:   %x.param_patt.loc22_58.2 => constants.%x.param_patt.15a
// CHECK:STDOUT:   %x.patt.loc22_58.2 => constants.%x.patt.9de
// CHECK:STDOUT:   %.loc22_48.2 => constants.%.c6e
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc22_43 => constants.%complete_type.d65
// CHECK:STDOUT:   %require_complete.loc22_58 => constants.%complete_type.ec5
// CHECK:STDOUT:   %.loc23_16.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc23_16.4 => constants.%i64
// CHECK:STDOUT:   %.loc23_16.5 => <not constant>
// CHECK:STDOUT:   %require_complete.loc23_20 => constants.%require_complete.917
// CHECK:STDOUT:   %HasV.WithSelf.V.type => constants.%HasV.WithSelf.V.type.e05
// CHECK:STDOUT:   %.loc23_26 => constants.%.6c6
// CHECK:STDOUT:   %HasV.lookup_impl_witness => constants.%HasV.lookup_impl_witness.4c7
// CHECK:STDOUT:   %impl.elem0.loc23_26.2 => constants.%impl.elem0.e0d
// CHECK:STDOUT:   %specific_impl_fn.loc23_26.2 => constants.%specific_impl_fn.2f9
// CHECK:STDOUT:   %.loc23_30.4 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc23_30.5 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc23_30.6 => <not constant>
// CHECK:STDOUT:   %require_complete.loc23_30 => constants.%complete_type.782
// CHECK:STDOUT:   %.loc23_30.7 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc23_30.8 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- cpp_template_outer.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %pattern_type.9a5: type = pattern_type type [concrete]
// CHECK:STDOUT:   %int_32.be027e.1: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32.f58524.1: type = class_type @Int, @Int(%int_32.be027e.1) [concrete]
// CHECK:STDOUT:   %One.type: type = fn_type @One [concrete]
// CHECK:STDOUT:   %One: %One.type = struct_value () [concrete]
// CHECK:STDOUT:   %Consume.type: type = fn_type @Consume [concrete]
// CHECK:STDOUT:   %Consume: %Consume.type = struct_value () [concrete]
// CHECK:STDOUT:   %U.patt: %pattern_type.9a5 = symbolic_binding_pattern U, 0 [symbolic]
// CHECK:STDOUT:   %U: type = symbolic_binding U, 0 [symbolic]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic]
// CHECK:STDOUT:   %pack_type.571: type = pack_type type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.258: type = pattern_type %pack_type.571 [symbolic]
// CHECK:STDOUT:   %T.patt.468: %pattern_type.258 = symbolic_binding_pattern T, 2 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.571 = symbolic_binding T, 2 [symbolic]
// CHECK:STDOUT:   %.ffd: %pattern_type.258 = pack_expansion_pattern %T.patt.468, %arity.patt [symbolic]
// CHECK:STDOUT:   %pattern_type.51d1c4.3: type = pattern_type %U [symbolic]
// CHECK:STDOUT:   %u.param_patt.684: %pattern_type.51d1c4.3 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %u.patt.760: %pattern_type.51d1c4.3 = wrapper_binding_pattern u, %u.param_patt.684 [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.3fb: type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.632: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.0da: type = pattern_type %pack_type.632 [symbolic]
// CHECK:STDOUT:   %x.param_patt.57f: %pattern_type.0da = value_param_pattern [symbolic]
// CHECK:STDOUT:   %x.patt.4f0: %pattern_type.0da = wrapper_binding_pattern x, %x.param_patt.57f [symbolic]
// CHECK:STDOUT:   %.1ed: %pattern_type.0da = pack_expansion_pattern %x.patt.4f0, invalid [symbolic]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.9443dd.2: <witness> = require_complete_type %U [symbolic]
// CHECK:STDOUT:   %require_complete.181: <witness> = require_complete_type %pack_type.632 [symbolic]
// CHECK:STDOUT:   %Traits.type: type = cpp_type_template_type Traits [concrete]
// CHECK:STDOUT:   %Traits.template: %Traits.type = struct_value () [concrete]
// CHECK:STDOUT:   %.a92: type = template_inst %U [template]
// CHECK:STDOUT:   %.e06: type = type_of_inst @F.%.loc11_27.3 [template]
// CHECK:STDOUT:   %.156: %.e06 = splice_inst @F.%.loc11_27.3 [template]
// CHECK:STDOUT:   %.52a: type = type_of_inst @F.%.loc11_28.3 [template]
// CHECK:STDOUT:   %.62b: %.52a = splice_inst @F.%.loc11_28.3 [template]
// CHECK:STDOUT:   %One.specific_fn.6f8: <specific function> = specific_function %One, @One(%.3fb) [symbolic]
// CHECK:STDOUT:   %.15b: type = type_of_inst @F.%.loc11_46.4 [template]
// CHECK:STDOUT:   %.faa: %.15b = splice_inst @F.%.loc11_46.4 [template]
// CHECK:STDOUT:   %require_complete.b70: <witness> = require_complete_type %.15b [template]
// CHECK:STDOUT:   %.6f5: %.15b = splice_inst @F.%.loc11_46.7 [template]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %complete_type.4a1: <witness> = complete_type_witness %i64.builtin [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2.ecc [concrete]
// CHECK:STDOUT:   %.947: %pack_type.8f6 = pack_value (bool, %i32.f58524.1) [concrete]
// CHECK:STDOUT:   %pattern_type.b37: type = pattern_type %pack_type.8f6 [concrete]
// CHECK:STDOUT:   %T.patt.56f: %pattern_type.b37 = symbolic_binding_pattern T, 2 [symbolic]
// CHECK:STDOUT:   %.4c2: %pattern_type.b37 = pack_expansion_pattern %T.patt.56f, %arity.patt [symbolic]
// CHECK:STDOUT:   %u.param_patt.266: %pattern_type.f57 = value_param_pattern [concrete]
// CHECK:STDOUT:   %u.patt.47a: %pattern_type.f57 = wrapper_binding_pattern u, %u.param_patt.266 [concrete]
// CHECK:STDOUT:   %.784: type = pack_element %.947, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.74a: type = pack_type %.947, %int_2.ecc [concrete]
// CHECK:STDOUT:   %pattern_type.daf: type = pattern_type %pack_type.74a [concrete]
// CHECK:STDOUT:   %x.param_patt.7c3: %pattern_type.daf = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt.0bb: %pattern_type.daf = wrapper_binding_pattern x, %x.param_patt.7c3 [concrete]
// CHECK:STDOUT:   %.9fd: %pattern_type.daf = pack_expansion_pattern %x.patt.0bb, invalid [concrete]
// CHECK:STDOUT:   %complete_type.5e5: <witness> = complete_type_witness %pack_type.74a [concrete]
// CHECK:STDOUT:   %Traits: type = class_type @Traits [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.1: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.a13917.1: type = splice_block imports.%Traits.decl [concrete = %Traits] {}
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %const: type = const_type %i32.f58524.1 [concrete]
// CHECK:STDOUT:   %pattern_type.ed1: type = pattern_type %const [concrete]
// CHECK:STDOUT:   %size.patt: %pattern_type.ed1 = ref_binding_pattern size [concrete]
// CHECK:STDOUT:   %size.var_patt: %pattern_type.ed1 = var_pattern %size.patt [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.2: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.27f: ref %const = splice_block %size.ref.26993e.3 [concrete = imports.%size.var] {
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %size.ref.26993e.3: ref %const = name_ref size, imports.%size.var [concrete = imports.%size.var]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %One.specific_fn.11f: <specific function> = specific_function %One, @One(%.784) [symbolic]
// CHECK:STDOUT:   %size.var: ref %i32.f58524.1 = var_storage imports.%size.var_patt [concrete]
// CHECK:STDOUT:   %int_8: %i32.f58524.1 = int_value 8 [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.3: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.2a2821.1: init %empty_tuple.type = splice_block %Consume.call.8482d8.3 {
// CHECK:STDOUT:       %.1e5588.3: ref %i32.f58524.1 = as_compatible imports.%size.var [concrete = %size.var]
// CHECK:STDOUT:       %.8810d1.3: ref %i32.f58524.1 = converted imports.%size.var, %.1e5588.3 [concrete = %size.var]
// CHECK:STDOUT:       <elided>
// CHECK:STDOUT:       %.73f1ec.3: %i32.f58524.1 = acquire_value %.8810d1.3 [concrete = %int_8]
// CHECK:STDOUT:       %.6c289e.3: %i32.f58524.1 = value_of_initializer @F.%One.call
// CHECK:STDOUT:       %.5875e6.3: %i32.f58524.1 = converted @F.%One.call, %.6c289e.3
// CHECK:STDOUT:       %Consume.call.8482d8.3: init %empty_tuple.type = call %Consume(%.73f1ec.3, %.5875e6.3)
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %complete_type.782: <witness> = complete_type_witness %empty_tuple.type [concrete]
// CHECK:STDOUT:   %inst.splice_block.426619.4: <instruction> = inst_value [concrete] {
// CHECK:STDOUT:     %.05e240.1: init %empty_tuple.type = splice_block %.2a2821.1 {}
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Traits = %Traits.template
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Traits.template: %Traits.type = struct_value () [concrete = constants.%Traits.template]
// CHECK:STDOUT:   %Traits.decl: type = class_decl @Traits [concrete = constants.%Traits] {} {}
// CHECK:STDOUT:   %size.patt: %pattern_type.ed1 = ref_binding_pattern size [concrete = constants.%size.patt]
// CHECK:STDOUT:   %size.var_patt: %pattern_type.ed1 = var_pattern %size.patt [concrete = constants.%size.var_patt]
// CHECK:STDOUT:   %size.var: ref %const = var_storage %size.var_patt [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %U.patt.loc10_7.1: %pattern_type.9a5 = symbolic_binding_pattern U, 0 [symbolic = %U.patt.loc10_7.2 (constants.%U.patt)]
// CHECK:STDOUT:     %arity.patt.loc10_15.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc10_15.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc10_25.1: @F.%pattern_type.loc10_25 (%pattern_type.258) = symbolic_binding_pattern T, 2 [symbolic = %T.patt.loc10_25.2 (constants.%T.patt.468)]
// CHECK:STDOUT:     %.loc10_15.1: @F.%pattern_type.loc10_25 (%pattern_type.258) = pack_expansion_pattern %T.patt.loc10_25.1, %arity.patt.loc10_15.1 [symbolic = %.loc10_15.2 (constants.%.ffd)]
// CHECK:STDOUT:     %u.param_patt.loc10_41.1: @F.%pattern_type.loc10_41 (%pattern_type.51d1c4.3) = value_param_pattern [symbolic = %u.param_patt.loc10_41.2 (constants.%u.param_patt.684)]
// CHECK:STDOUT:     %u.patt.loc10_41.1: @F.%pattern_type.loc10_41 (%pattern_type.51d1c4.3) = wrapper_binding_pattern u, %u.param_patt.loc10_41.1 [symbolic = %u.patt.loc10_41.2 (constants.%u.patt.760)]
// CHECK:STDOUT:     %x.param_patt.loc10_56.1: @F.%pattern_type.loc10_56 (%pattern_type.0da) = value_param_pattern [symbolic = %x.param_patt.loc10_56.2 (constants.%x.param_patt.57f)]
// CHECK:STDOUT:     %x.patt.loc10_56.1: @F.%pattern_type.loc10_56 (%pattern_type.0da) = wrapper_binding_pattern x, %x.param_patt.loc10_56.1 [symbolic = %x.patt.loc10_56.2 (constants.%x.patt.4f0)]
// CHECK:STDOUT:     %.loc10_46.1: @F.%pattern_type.loc10_56 (%pattern_type.0da) = pack_expansion_pattern %x.patt.loc10_56.1, invalid [symbolic = %.loc10_46.2 (constants.%.1ed)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_9.1: type = splice_block %.loc10_9.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc10_7: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc10_9.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %U.loc10_7.2: type = symbolic_binding U, 0 [symbolic = %U.loc10_7.1 (constants.%U)]
// CHECK:STDOUT:     %arity.loc10_15.2: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc10_15.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc10_27.1: type = splice_block %.loc10_27.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen.loc10_25: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc10_27.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc10_25.2: @F.%pack_type.loc10_25 (%pack_type.571) = symbolic_binding T, 2 [symbolic = %T.loc10_25.1 (constants.%T)]
// CHECK:STDOUT:     %u.param: @F.%U.loc10_7.1 (%U) = value_param call_param0
// CHECK:STDOUT:     %U.ref.loc10: type = name_ref U, %U.loc10_7.2 [symbolic = %U.loc10_7.1 (constants.%U)]
// CHECK:STDOUT:     %u: @F.%U.loc10_7.1 (%U) = wrapper_binding u, %u.param
// CHECK:STDOUT:     %x.param: @F.%pack_type.loc10_56 (%pack_type.632) = value_param call_param1
// CHECK:STDOUT:     %.loc10_58.3: type = splice_block %.loc10_58.5 [symbolic = %.loc10_58.2 (constants.%.3fb)] {
// CHECK:STDOUT:       %T.ref: @F.%pack_type.loc10_25 (%pack_type.571) = name_ref T, %T.loc10_25.2 [symbolic = %T.loc10_25.1 (constants.%T)]
// CHECK:STDOUT:       %.loc10_58.4: Core.IntLiteral = pack_index [symbolic = %.loc10_58.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc10_58.5: type = pack_element %T.ref, %.loc10_58.4 [symbolic = %.loc10_58.2 (constants.%.3fb)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @F.%pack_type.loc10_56 (%pack_type.632) = wrapper_binding x, %x.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @F(%U.loc10_7.2: type, %arity.loc10_15.2: Core.IntLiteral, %T.loc10_25.2: @F.%pack_type.loc10_25 (%pack_type.571)) {
// CHECK:STDOUT:   %U.patt.loc10_7.2: %pattern_type.9a5 = symbolic_binding_pattern U, 0 [symbolic = %U.patt.loc10_7.2 (constants.%U.patt)]
// CHECK:STDOUT:   %U.loc10_7.1: type = symbolic_binding U, 0 [symbolic = %U.loc10_7.1 (constants.%U)]
// CHECK:STDOUT:   %arity.patt.loc10_15.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 1 [symbolic = %arity.patt.loc10_15.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc10_15.1: Core.IntLiteral = symbolic_binding <pack arity>, 1 [symbolic = %arity.loc10_15.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc10_25: type = pack_type type, %arity.loc10_15.1 [symbolic = %pack_type.loc10_25 (constants.%pack_type.571)]
// CHECK:STDOUT:   %pattern_type.loc10_25: type = pattern_type %pack_type.loc10_25 [symbolic = %pattern_type.loc10_25 (constants.%pattern_type.258)]
// CHECK:STDOUT:   %T.patt.loc10_25.2: @F.%pattern_type.loc10_25 (%pattern_type.258) = symbolic_binding_pattern T, 2 [symbolic = %T.patt.loc10_25.2 (constants.%T.patt.468)]
// CHECK:STDOUT:   %T.loc10_25.1: @F.%pack_type.loc10_25 (%pack_type.571) = symbolic_binding T, 2 [symbolic = %T.loc10_25.1 (constants.%T)]
// CHECK:STDOUT:   %.loc10_15.2: @F.%pattern_type.loc10_25 (%pattern_type.258) = pack_expansion_pattern %T.patt.loc10_25.2, %arity.patt.loc10_15.2 [symbolic = %.loc10_15.2 (constants.%.ffd)]
// CHECK:STDOUT:   %pattern_type.loc10_41: type = pattern_type %U.loc10_7.1 [symbolic = %pattern_type.loc10_41 (constants.%pattern_type.51d1c4.3)]
// CHECK:STDOUT:   %u.param_patt.loc10_41.2: @F.%pattern_type.loc10_41 (%pattern_type.51d1c4.3) = value_param_pattern [symbolic = %u.param_patt.loc10_41.2 (constants.%u.param_patt.684)]
// CHECK:STDOUT:   %u.patt.loc10_41.2: @F.%pattern_type.loc10_41 (%pattern_type.51d1c4.3) = wrapper_binding_pattern u, %u.param_patt.loc10_41.2 [symbolic = %u.patt.loc10_41.2 (constants.%u.patt.760)]
// CHECK:STDOUT:   %.loc10_58.1: Core.IntLiteral = pack_index [symbolic = %.loc10_58.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc10_58.2: type = pack_element %T.loc10_25.1, %.loc10_58.1 [symbolic = %.loc10_58.2 (constants.%.3fb)]
// CHECK:STDOUT:   %pack_type.loc10_56: type = pack_type %T.loc10_25.1, %arity.loc10_15.1 [symbolic = %pack_type.loc10_56 (constants.%pack_type.632)]
// CHECK:STDOUT:   %pattern_type.loc10_56: type = pattern_type %pack_type.loc10_56 [symbolic = %pattern_type.loc10_56 (constants.%pattern_type.0da)]
// CHECK:STDOUT:   %x.param_patt.loc10_56.2: @F.%pattern_type.loc10_56 (%pattern_type.0da) = value_param_pattern [symbolic = %x.param_patt.loc10_56.2 (constants.%x.param_patt.57f)]
// CHECK:STDOUT:   %x.patt.loc10_56.2: @F.%pattern_type.loc10_56 (%pattern_type.0da) = wrapper_binding_pattern x, %x.param_patt.loc10_56.2 [symbolic = %x.patt.loc10_56.2 (constants.%x.patt.4f0)]
// CHECK:STDOUT:   %.loc10_46.2: @F.%pattern_type.loc10_56 (%pattern_type.0da) = pack_expansion_pattern %x.patt.loc10_56.2, invalid [symbolic = %.loc10_46.2 (constants.%.1ed)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10_41: <witness> = require_complete_type %U.loc10_7.1 [symbolic = %require_complete.loc10_41 (constants.%require_complete.9443dd.2)]
// CHECK:STDOUT:   %require_complete.loc10_56: <witness> = require_complete_type %pack_type.loc10_56 [symbolic = %require_complete.loc10_56 (constants.%require_complete.181)]
// CHECK:STDOUT:   %.loc11_26.2: type = template_inst %U.loc10_7.1 [template = %.loc11_26.2 (constants.%.a92)]
// CHECK:STDOUT:   %.loc11_27.3: <instruction> = call_action (%Traits.ref, %.loc11_26.1), false [template]
// CHECK:STDOUT:   %.loc11_27.4: type = type_of_inst %.loc11_27.3 [template = %.loc11_27.4 (constants.%.e06)]
// CHECK:STDOUT:   %.loc11_27.5: @F.%.loc11_27.4 (%.e06) = splice_inst %.loc11_27.3 [template = %.loc11_27.5 (constants.%.156)]
// CHECK:STDOUT:   %.loc11_28.3: <instruction> = access_member_action %.loc11_27.2, size [template]
// CHECK:STDOUT:   %.loc11_28.4: type = type_of_inst %.loc11_28.3 [template = %.loc11_28.4 (constants.%.52a)]
// CHECK:STDOUT:   %.loc11_28.5: @F.%.loc11_28.4 (%.52a) = splice_inst %.loc11_28.3 [template = %.loc11_28.5 (constants.%.62b)]
// CHECK:STDOUT:   %One.specific_fn.loc11_35.2: <specific function> = specific_function constants.%One, @One(%.loc10_58.2) [symbolic = %One.specific_fn.loc11_35.2 (constants.%One.specific_fn.6f8)]
// CHECK:STDOUT:   %.loc11_46.4: <instruction> = call_action (%Consume.ref, %.loc11_28.2, %One.call), false [template]
// CHECK:STDOUT:   %.loc11_46.5: type = type_of_inst %.loc11_46.4 [template = %.loc11_46.5 (constants.%.15b)]
// CHECK:STDOUT:   %.loc11_46.6: @F.%.loc11_46.5 (%.15b) = splice_inst %.loc11_46.4 [template = %.loc11_46.6 (constants.%.faa)]
// CHECK:STDOUT:   %require_complete.loc11: <witness> = require_complete_type %.loc11_46.5 [template = %require_complete.loc11 (constants.%require_complete.b70)]
// CHECK:STDOUT:   %.loc11_46.7: <instruction> = convert_to_category_action %.loc11_46.2, element9 [template]
// CHECK:STDOUT:   %.loc11_46.8: @F.%.loc11_46.5 (%.15b) = splice_inst %.loc11_46.7 [template = %.loc11_46.8 (constants.%.6f5)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%u.param: @F.%U.loc10_7.1 (%U), %x.param: @F.%pack_type.loc10_56 (%pack_type.632)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     pack_expansion_statement %arity.loc10_15.2 {
// CHECK:STDOUT:       %Consume.ref: %Consume.type = name_ref Consume, file.%Consume.decl [concrete = constants.%Consume]
// CHECK:STDOUT:       %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %Traits.ref: %Traits.type = name_ref Traits, imports.%Traits.template [concrete = constants.%Traits.template]
// CHECK:STDOUT:       %U.ref.loc11: type = name_ref U, %U.loc10_7.2 [symbolic = %U.loc10_7.1 (constants.%U)]
// CHECK:STDOUT:       %.loc11_26.1: type = template_inst %U.ref.loc11 [template = %.loc11_26.2 (constants.%.a92)]
// CHECK:STDOUT:       %.loc11_27.1: type = type_of_inst %.loc11_27.3 [template = %.loc11_27.4 (constants.%.e06)]
// CHECK:STDOUT:       %.loc11_27.2: @F.%.loc11_27.4 (%.e06) = splice_inst %.loc11_27.3 [template = %.loc11_27.5 (constants.%.156)]
// CHECK:STDOUT:       %.loc11_28.1: type = type_of_inst %.loc11_28.3 [template = %.loc11_28.4 (constants.%.52a)]
// CHECK:STDOUT:       %.loc11_28.2: @F.%.loc11_28.4 (%.52a) = splice_inst %.loc11_28.3 [template = %.loc11_28.5 (constants.%.62b)]
// CHECK:STDOUT:       %One.ref: %One.type = name_ref One, file.%One.decl [concrete = constants.%One]
// CHECK:STDOUT:       %x.ref: @F.%pack_type.loc10_56 (%pack_type.632) = name_ref x, %x
// CHECK:STDOUT:       %.loc11_39.1: Core.IntLiteral = pack_index [symbolic = %.loc10_58.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc11_39.2: Core.IntLiteral = pack_index [symbolic = %.loc10_58.1 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc11_39.3: type = pack_element constants.%T, %.loc11_39.2 [symbolic = %.loc10_58.2 (constants.%.3fb)]
// CHECK:STDOUT:       %.loc11_39.4: @F.%.loc10_58.2 (%.3fb) = pack_element %x.ref, %.loc11_39.1
// CHECK:STDOUT:       %One.specific_fn.loc11_35.1: <specific function> = specific_function %One.ref, @One(constants.%.3fb) [symbolic = %One.specific_fn.loc11_35.2 (constants.%One.specific_fn.6f8)]
// CHECK:STDOUT:       %One.call: init %i32.f58524.1 = call %One.specific_fn.loc11_35.1(%.loc11_39.4)
// CHECK:STDOUT:       %.loc11_46.1: type = type_of_inst %.loc11_46.4 [template = %.loc11_46.5 (constants.%.15b)]
// CHECK:STDOUT:       %.loc11_46.2: @F.%.loc11_46.5 (%.15b) = splice_inst %.loc11_46.4 [template = %.loc11_46.6 (constants.%.faa)]
// CHECK:STDOUT:       %.loc11_46.3: @F.%.loc11_46.5 (%.15b) = splice_inst %.loc11_46.7 [template = %.loc11_46.8 (constants.%.6f5)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%U, constants.%arity, constants.%T) {
// CHECK:STDOUT:   %U.patt.loc10_7.2 => constants.%U.patt
// CHECK:STDOUT:   %U.loc10_7.1 => constants.%U
// CHECK:STDOUT:   %arity.patt.loc10_15.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_15.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc10_25 => constants.%pack_type.571
// CHECK:STDOUT:   %pattern_type.loc10_25 => constants.%pattern_type.258
// CHECK:STDOUT:   %T.patt.loc10_25.2 => constants.%T.patt.468
// CHECK:STDOUT:   %T.loc10_25.1 => constants.%T
// CHECK:STDOUT:   %.loc10_15.2 => constants.%.ffd
// CHECK:STDOUT:   %pattern_type.loc10_41 => constants.%pattern_type.51d1c4.3
// CHECK:STDOUT:   %u.param_patt.loc10_41.2 => constants.%u.param_patt.684
// CHECK:STDOUT:   %u.patt.loc10_41.2 => constants.%u.patt.760
// CHECK:STDOUT:   %.loc10_58.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc10_58.2 => constants.%.3fb
// CHECK:STDOUT:   %pack_type.loc10_56 => constants.%pack_type.632
// CHECK:STDOUT:   %pattern_type.loc10_56 => constants.%pattern_type.0da
// CHECK:STDOUT:   %x.param_patt.loc10_56.2 => constants.%x.param_patt.57f
// CHECK:STDOUT:   %x.patt.loc10_56.2 => constants.%x.patt.4f0
// CHECK:STDOUT:   %.loc10_46.2 => constants.%.1ed
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @F(constants.%i64, constants.%int_2.ecc, constants.%.947) {
// CHECK:STDOUT:   %U.patt.loc10_7.2 => constants.%U.patt
// CHECK:STDOUT:   %U.loc10_7.1 => constants.%i64
// CHECK:STDOUT:   %arity.patt.loc10_15.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc10_15.1 => constants.%int_2.ecc
// CHECK:STDOUT:   %pack_type.loc10_25 => constants.%pack_type.8f6
// CHECK:STDOUT:   %pattern_type.loc10_25 => constants.%pattern_type.b37
// CHECK:STDOUT:   %T.patt.loc10_25.2 => constants.%T.patt.56f
// CHECK:STDOUT:   %T.loc10_25.1 => constants.%.947
// CHECK:STDOUT:   %.loc10_15.2 => constants.%.4c2
// CHECK:STDOUT:   %pattern_type.loc10_41 => constants.%pattern_type.f57
// CHECK:STDOUT:   %u.param_patt.loc10_41.2 => constants.%u.param_patt.266
// CHECK:STDOUT:   %u.patt.loc10_41.2 => constants.%u.patt.47a
// CHECK:STDOUT:   %.loc10_58.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc10_58.2 => constants.%.784
// CHECK:STDOUT:   %pack_type.loc10_56 => constants.%pack_type.74a
// CHECK:STDOUT:   %pattern_type.loc10_56 => constants.%pattern_type.daf
// CHECK:STDOUT:   %x.param_patt.loc10_56.2 => constants.%x.param_patt.7c3
// CHECK:STDOUT:   %x.patt.loc10_56.2 => constants.%x.patt.0bb
// CHECK:STDOUT:   %.loc10_46.2 => constants.%.9fd
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc10_41 => constants.%complete_type.4a1
// CHECK:STDOUT:   %require_complete.loc10_56 => constants.%complete_type.5e5
// CHECK:STDOUT:   %.loc11_26.2 => constants.%i64
// CHECK:STDOUT:   %.loc11_27.3 => constants.%inst.splice_block.426619.1
// CHECK:STDOUT:   %.loc11_27.4 => type
// CHECK:STDOUT:   %.loc11_27.5 => constants.%Traits
// CHECK:STDOUT:   %.loc11_28.3 => constants.%inst.splice_block.426619.2
// CHECK:STDOUT:   %.loc11_28.4 => constants.%const
// CHECK:STDOUT:   %.loc11_28.5 => imports.%size.var
// CHECK:STDOUT:   %One.specific_fn.loc11_35.2 => constants.%One.specific_fn.11f
// CHECK:STDOUT:   %.loc11_46.4 => constants.%inst.splice_block.426619.3
// CHECK:STDOUT:   %.loc11_46.5 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc11_46.6 => <not constant>
// CHECK:STDOUT:   %require_complete.loc11 => constants.%complete_type.782
// CHECK:STDOUT:   %.loc11_46.7 => constants.%inst.splice_block.426619.4
// CHECK:STDOUT:   %.loc11_46.8 => <not constant>
// CHECK:STDOUT: }
// CHECK:STDOUT:
