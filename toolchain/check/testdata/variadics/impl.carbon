// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/impl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/impl.carbon

// --- select.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

//@dump-sem-ir-begin
impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}
//@dump-sem-ir-end

fn Call(t: (i64, bool), e: ()) -> i64 {
  //@dump-sem-ir-begin
  t.(Count.N)();
  return e.(Count.N)();
  //@dump-sem-ir-end
}

// --- requirement.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

//@dump-sem-ir-begin
impl forall [... each T: Code] (... each T) as Code {
  fn Get(self) -> i64 {
    let (... each x: each T) = self;
    var total: i64 = 0;
    ... total = Add(total, each x.Get());
    return total;
  }
}
//@dump-sem-ir-end

fn Call(t: (i64, (i64, i64))) -> i64 {
  //@dump-sem-ir-begin
  return t.(Code.Get)();
  //@dump-sem-ir-end
}

// --- generic_use.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

fn Use[V: Count](v: V) -> i64 { return v.N(); }

fn Call(t: (i64, bool)) -> i64 {
  //@dump-sem-ir-begin
  return Use(t);
  //@dump-sem-ir-end
}

// --- non_tuple_query.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

impl i64 as Count {
  fn N(self) -> i64 { return self; }
}

fn Call(x: i64) -> i64 {
  //@dump-sem-ir-begin
  return x.(Count.N)();
  //@dump-sem-ir-end
}

// --- symbolic_query.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

//@dump-sem-ir-begin
fn H[... each T: type](t: (... each T)) -> i64 {
  return t.(Count.N)();
}
//@dump-sem-ir-end

// --- self_query.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
  fn Twice(self) -> i64;
}

//@dump-sem-ir-begin
impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
  fn Twice(self) -> i64 { return self.(Count.N)(); }
}
//@dump-sem-ir-end

// --- lib.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Call(t: (i64, bool, i64)) -> i64 {
  //@dump-sem-ir-begin
  return t.(Count.N)();
  //@dump-sem-ir-end
}

// --- rank.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Count {
  fn N(self) -> i64;
}

impl forall [T: type] T as Count {
  fn N(unused self) -> i64 { return 1; }
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

impl forall [T: type, U: type] (T, U) as Count {
  fn N(unused self) -> i64 { return 3; }
}

fn Call(x: i64, p: (i64, bool), t: (i64, bool, i64), e: ()) -> i64 {
  //@dump-sem-ir-begin
  return Add(Add(Add(x.(Count.N)(), p.(Count.N)()), t.(Count.N)()),
             e.(Count.N)());
  //@dump-sem-ir-end
}

// --- rank_reversed.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Count {
  fn N(self) -> i64;
}

impl forall [T: type, U: type] (T, U) as Count {
  fn N(unused self) -> i64 { return 3; }
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

impl forall [T: type] T as Count {
  fn N(unused self) -> i64 { return 1; }
}

fn Call(x: i64, p: (i64, bool), t: (i64, bool, i64), e: ()) -> i64 {
  //@dump-sem-ir-begin
  return Add(Add(Add(x.(Count.N)(), p.(Count.N)()), t.(Count.N)()),
             e.(Count.N)());
  //@dump-sem-ir-end
}

// --- rank_elements_after.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T, bool) as Count {
  fn N(unused self) -> i64 { return 1; }
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

fn Call(a: (i64, bool), b: (bool, i64), c: (bool,)) -> i64 {
  //@dump-sem-ir-begin
  return Add(Add(a.(Count.N)(), b.(Count.N)()), c.(Count.N)());
  //@dump-sem-ir-end
}

// --- rank_elements_after_reversed.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

impl forall [... each T: type] (... each T, bool) as Count {
  fn N(unused self) -> i64 { return 1; }
}

fn Call(a: (i64, bool), b: (bool, i64), c: (bool,)) -> i64 {
  //@dump-sem-ir-begin
  return Add(Add(a.(Count.N)(), b.(Count.N)()), c.(Count.N)());
  //@dump-sem-ir-end
}

// --- body_expansion.carbon
library "[[@TEST_NAME]]";

interface HasN {
  let N: i64;
}
impl i64 as HasN where .N = 3 {}
impl bool as HasN where .N = 40 {}

interface Sum {
  fn Get(self) -> i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

//@dump-sem-ir-begin
impl forall [... each T: HasN] (... each T) as Sum {
  fn Get(unused self) -> i64 {
    var s: i64 = 0;
    ... s = Add(s, (each T).N);
    return s;
  }
}
//@dump-sem-ir-end

fn Call(t: (i64, bool, i64)) -> i64 {
  return t.(Sum.Get)();
}

// CHECK:STDOUT: --- select.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Count.assoc_type: type = assoc_entity_type @Count [concrete]
// CHECK:STDOUT:   %assoc0.71c: %Count.assoc_type = assoc_entity element0, @Count.WithSelf.%Count.WithSelf.N.decl [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.fc0: type = pattern_type %pack_type.c29 [symbolic]
// CHECK:STDOUT:   %T.patt.f84: %pattern_type.fc0 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.99e: %pattern_type.fc0 = pack_expansion_pattern %T.patt.f84, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.425: type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.852: type = tuple_type (%pack_type.c29) [symbolic]
// CHECK:STDOUT:   %tuple.d38: %tuple.type.852 = tuple_value (%T) [symbolic]
// CHECK:STDOUT:   %pack_type.8fb: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.423: type = tuple_type (%pack_type.8fb) [symbolic]
// CHECK:STDOUT:   %.317: <witness> = impl_self_witness %tuple.type.423, @Count [symbolic]
// CHECK:STDOUT:   %Count.impl_witness.5db: <witness> = impl_witness @tuple.type.as.Count.impl.%Count.impl_witness_table, @tuple.type.as.Count.impl(%arity, %T) [symbolic]
// CHECK:STDOUT:   %pattern_type.e36: type = pattern_type %tuple.type.423 [symbolic]
// CHECK:STDOUT:   %self.param_patt.280: %pattern_type.e36 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt.d43: %pattern_type.e36 = wrapper_binding_pattern self, %self.param_patt.280 [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.c5b: type = fn_type @tuple.type.as.Count.impl.N, @tuple.type.as.Count.impl(%arity, %T) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.e1d: %tuple.type.as.Count.impl.N.type.c5b = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.f6f: <witness> = require_complete_type %tuple.type.423 [symbolic]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_7.824: %i64 = int_value 7 [concrete]
// CHECK:STDOUT:   %tuple.type.693: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.3f9: %tuple.type.693 = tuple_value (%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.f41: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %pattern_type.ea0: type = pattern_type %tuple.type.f41 [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %pattern_type.cb1: type = pattern_type %empty_tuple.type [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.abd: %pack_type.8f6 = pack_value (%i64, bool) [concrete]
// CHECK:STDOUT:   %pattern_type.b37: type = pattern_type %pack_type.8f6 [concrete]
// CHECK:STDOUT:   %T.patt.8a9: %pattern_type.b37 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.6c7: %pattern_type.b37 = pack_expansion_pattern %T.patt.8a9, %arity.patt [symbolic]
// CHECK:STDOUT:   %.867: type = pack_element %.abd, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.394: type = pack_type %.abd, %int_2 [concrete]
// CHECK:STDOUT:   %.56c: <witness> = impl_self_witness %tuple.type.f41, @Count [concrete]
// CHECK:STDOUT:   %Count.impl_witness.897: <witness> = impl_witness @tuple.type.as.Count.impl.%Count.impl_witness_table, @tuple.type.as.Count.impl(%int_2, %.abd) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.487: type = fn_type @tuple.type.as.Count.impl.N, @tuple.type.as.Count.impl(%int_2, %.abd) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.a1e: %tuple.type.as.Count.impl.N.type.487 = struct_value () [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Count.facet.4e8: %Count.type = facet_value %tuple.type.f41, (%Count.impl_witness.897) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.7c3: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.4e8) [concrete]
// CHECK:STDOUT:   %.d99: type = fn_type_with_self_type %Count.WithSelf.N.type.7c3, %Count.facet.4e8 [concrete]
// CHECK:STDOUT:   %self.param_patt.0b2: %pattern_type.ea0 = value_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.a6d: %pattern_type.ea0 = wrapper_binding_pattern self, %self.param_patt.0b2 [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.6af: <specific function> = specific_function %tuple.type.as.Count.impl.N.a1e, @tuple.type.as.Count.impl.N(%int_2, %.abd) [concrete]
// CHECK:STDOUT:   %pack_type.28d: type = pack_type type, %int_0 [concrete]
// CHECK:STDOUT:   %.d3f: %pack_type.28d = pack_value () [concrete]
// CHECK:STDOUT:   %pattern_type.94c: type = pattern_type %pack_type.28d [concrete]
// CHECK:STDOUT:   %T.patt.75e: %pattern_type.94c = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.b4d: %pattern_type.94c = pack_expansion_pattern %T.patt.75e, %arity.patt [symbolic]
// CHECK:STDOUT:   %.8a1: type = pack_element %.d3f, %.4ee [symbolic]
// CHECK:STDOUT:   %pack_type.54a: type = pack_type %.d3f, %int_0 [concrete]
// CHECK:STDOUT:   %.406: <witness> = impl_self_witness %empty_tuple.type, @Count [concrete]
// CHECK:STDOUT:   %Count.impl_witness.f33: <witness> = impl_witness @tuple.type.as.Count.impl.%Count.impl_witness_table, @tuple.type.as.Count.impl(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.886: type = fn_type @tuple.type.as.Count.impl.N, @tuple.type.as.Count.impl(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.d02: %tuple.type.as.Count.impl.N.type.886 = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.70c: %Count.type = facet_value %empty_tuple.type, (%Count.impl_witness.f33) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.20e: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.70c) [concrete]
// CHECK:STDOUT:   %.91f: type = fn_type_with_self_type %Count.WithSelf.N.type.20e, %Count.facet.70c [concrete]
// CHECK:STDOUT:   %self.param_patt.154: %pattern_type.cb1 = value_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.462: %pattern_type.cb1 = wrapper_binding_pattern self, %self.param_patt.154 [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.a0a: <specific function> = specific_function %tuple.type.as.Count.impl.N.d02, @tuple.type.as.Count.impl.N(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %complete_type.6e7: <witness> = complete_type_witness %tuple.type.f41 [concrete]
// CHECK:STDOUT:   %complete_type.782: <witness> = complete_type_witness %empty_tuple.type [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   impl_decl @tuple.type.as.Count.impl [concrete] {
// CHECK:STDOUT:     %arity.patt.loc8_14.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc8_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc8_24.1: @tuple.type.as.Count.impl.%pattern_type (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc8_24.2 (constants.%T.patt.f84)]
// CHECK:STDOUT:     %.loc8_14.1: @tuple.type.as.Count.impl.%pattern_type (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc8_24.1, %arity.patt.loc8_14.1 [symbolic = %.loc8_14.2 (constants.%.99e)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc8_43.1: @tuple.type.as.Count.impl.%tuple.type.loc8_43.1 (%tuple.type.852) = tuple_literal (constants.%T) [symbolic = %tuple (constants.%tuple.d38)]
// CHECK:STDOUT:     %.loc8_43.2: type = converted %.loc8_43.1, constants.%tuple.type.423 [symbolic = %tuple.type.loc8_43.2 (constants.%tuple.type.423)]
// CHECK:STDOUT:     %Count.ref: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:     %arity.loc8_14.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc8_14.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc8_26.1: type = splice_block %.loc8_26.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc8_26.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc8_24.2: @tuple.type.as.Count.impl.%pack_type.loc8_24 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc8_24.1 (constants.%T)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc8: <witness> = impl_self_witness @tuple.type.as.Count.impl.%.loc8_43.2, @Count [symbolic = @tuple.type.as.Count.impl.%.loc8_54 (constants.%.317)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic impl @tuple.type.as.Count.impl(%arity.loc8_14.2: Core.IntLiteral, %T.loc8_24.2: @tuple.type.as.Count.impl.%pack_type.loc8_24 (%pack_type.c29)) {
// CHECK:STDOUT:   %arity.patt.loc8_14.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc8_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc8_14.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc8_14.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc8_24: type = pack_type type, %arity.loc8_14.1 [symbolic = %pack_type.loc8_24 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type.loc8_24 [symbolic = %pattern_type (constants.%pattern_type.fc0)]
// CHECK:STDOUT:   %T.patt.loc8_24.2: @tuple.type.as.Count.impl.%pattern_type (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc8_24.2 (constants.%T.patt.f84)]
// CHECK:STDOUT:   %T.loc8_24.1: @tuple.type.as.Count.impl.%pack_type.loc8_24 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc8_24.1 (constants.%T)]
// CHECK:STDOUT:   %.loc8_14.2: @tuple.type.as.Count.impl.%pattern_type (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc8_24.2, %arity.patt.loc8_14.2 [symbolic = %.loc8_14.2 (constants.%.99e)]
// CHECK:STDOUT:   %.loc8_37.1: Core.IntLiteral = pack_index [symbolic = %.loc8_37.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc8_37.2: type = pack_element %T.loc8_24.1, %.loc8_37.1 [symbolic = %.loc8_37.2 (constants.%.425)]
// CHECK:STDOUT:   %tuple.type.loc8_43.1: type = tuple_type (%pack_type.loc8_24) [symbolic = %tuple.type.loc8_43.1 (constants.%tuple.type.852)]
// CHECK:STDOUT:   %tuple: @tuple.type.as.Count.impl.%tuple.type.loc8_43.1 (%tuple.type.852) = tuple_value (%T.loc8_24.1) [symbolic = %tuple (constants.%tuple.d38)]
// CHECK:STDOUT:   %pack_type.loc8_43: type = pack_type %T.loc8_24.1, %arity.loc8_14.1 [symbolic = %pack_type.loc8_43 (constants.%pack_type.8fb)]
// CHECK:STDOUT:   %tuple.type.loc8_43.2: type = tuple_type (%pack_type.loc8_43) [symbolic = %tuple.type.loc8_43.2 (constants.%tuple.type.423)]
// CHECK:STDOUT:   %.loc8_54: <witness> = impl_self_witness %tuple.type.loc8_43.2, @Count [symbolic = %.loc8_54 (constants.%.317)]
// CHECK:STDOUT:   %Count.impl_witness.loc8_54.2: <witness> = impl_witness %Count.impl_witness_table, @tuple.type.as.Count.impl(%arity.loc8_14.1, %T.loc8_24.1) [symbolic = %Count.impl_witness.loc8_54.2 (constants.%Count.impl_witness.5db)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type: type = fn_type @tuple.type.as.Count.impl.N, @tuple.type.as.Count.impl(%arity.loc8_14.1, %T.loc8_24.1) [symbolic = %tuple.type.as.Count.impl.N.type (constants.%tuple.type.as.Count.impl.N.type.c5b)]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N: @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.N.type (%tuple.type.as.Count.impl.N.type.c5b) = struct_value () [symbolic = %tuple.type.as.Count.impl.N (constants.%tuple.type.as.Count.impl.N.e1d)]
// CHECK:STDOUT:
// CHECK:STDOUT:   impl: %.loc8_43.2 as %Count.ref {
// CHECK:STDOUT:     %tuple.type.as.Count.impl.N.decl: @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.N.type (%tuple.type.as.Count.impl.N.type.c5b) = fn_decl @tuple.type.as.Count.impl.N [symbolic = @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.N (constants.%tuple.type.as.Count.impl.N.e1d)] {
// CHECK:STDOUT:       %self.param_patt.loc9_15.1: @tuple.type.as.Count.impl.N.%pattern_type (%pattern_type.e36) = value_param_pattern [symbolic = %self.param_patt.loc9_15.2 (constants.%self.param_patt.280)]
// CHECK:STDOUT:       %self.patt.loc9_15.1: @tuple.type.as.Count.impl.N.%pattern_type (%pattern_type.e36) = wrapper_binding_pattern self, %self.param_patt.loc9_15.1 [symbolic = %self.patt.loc9_15.2 (constants.%self.patt.d43)]
// CHECK:STDOUT:       %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:       %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %.loc9_24: Core.Form = init_form %i64 [concrete = constants.%.bc0]
// CHECK:STDOUT:       %self.param: @tuple.type.as.Count.impl.N.%tuple.type (%tuple.type.423) = value_param call_param0
// CHECK:STDOUT:       %Self.ref: type = name_ref Self, @tuple.type.as.Count.impl.%.loc8_43.2 [symbolic = %tuple.type (constants.%tuple.type.423)]
// CHECK:STDOUT:       %self: @tuple.type.as.Count.impl.N.%tuple.type (%tuple.type.423) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:       %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Count.impl_witness_table = impl_witness_table (%tuple.type.as.Count.impl.N.decl), @tuple.type.as.Count.impl [concrete]
// CHECK:STDOUT:     %Count.impl_witness.loc8_54.1: <witness> = impl_witness %Count.impl_witness_table, @tuple.type.as.Count.impl(constants.%arity, constants.%T) [symbolic = %Count.impl_witness.loc8_54.2 (constants.%Count.impl_witness.5db)]
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .N = %tuple.type.as.Count.impl.N.decl
// CHECK:STDOUT:     extend %Count.ref
// CHECK:STDOUT:     witness = %Count.impl_witness.loc8_54.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @tuple.type.as.Count.impl.N(@tuple.type.as.Count.impl.%arity.loc8_14.2: Core.IntLiteral, @tuple.type.as.Count.impl.%T.loc8_24.2: @tuple.type.as.Count.impl.%pack_type.loc8_24 (%pack_type.c29)) {
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc9_15.1: type = pack_type type, %arity [symbolic = %pack_type.loc9_15.1 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %T: @tuple.type.as.Count.impl.N.%pack_type.loc9_15.1 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T (constants.%T)]
// CHECK:STDOUT:   %pack_type.loc9_15.2: type = pack_type %T, %arity [symbolic = %pack_type.loc9_15.2 (constants.%pack_type.8fb)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%pack_type.loc9_15.2) [symbolic = %tuple.type (constants.%tuple.type.423)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %tuple.type [symbolic = %pattern_type (constants.%pattern_type.e36)]
// CHECK:STDOUT:   %self.param_patt.loc9_15.2: @tuple.type.as.Count.impl.N.%pattern_type (%pattern_type.e36) = value_param_pattern [symbolic = %self.param_patt.loc9_15.2 (constants.%self.param_patt.280)]
// CHECK:STDOUT:   %self.patt.loc9_15.2: @tuple.type.as.Count.impl.N.%pattern_type (%pattern_type.e36) = wrapper_binding_pattern self, %self.param_patt.loc9_15.2 [symbolic = %self.patt.loc9_15.2 (constants.%self.patt.d43)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %tuple.type [symbolic = %require_complete (constants.%require_complete.f6f)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @tuple.type.as.Count.impl.N.%tuple.type (%tuple.type.423)) -> out %return.param: %i64 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:     %impl.elem0: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc9_38.1: <bound method> = bound_method %int_7, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc9_38.2: <bound method> = bound_method %int_7, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc9_38.2(%int_7) [concrete = constants.%int_7.824]
// CHECK:STDOUT:     %.loc9_38: init %i64 = converted %int_7, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_7.824]
// CHECK:STDOUT:     return %.loc9_38
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%t.param: %tuple.type.f41, %e.param: %empty_tuple.type) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.ref: %tuple.type.f41 = name_ref t, %t
// CHECK:STDOUT:   %Count.ref.loc15: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc15: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc15: %.d99 = impl_witness_access constants.%Count.impl_witness.897, element0 [concrete = constants.%tuple.type.as.Count.impl.N.a1e]
// CHECK:STDOUT:   %bound_method.loc15_4: <bound method> = bound_method %t.ref, %impl.elem0.loc15
// CHECK:STDOUT:   %int_2.loc15_15.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc15_15.1: %pack_type.8f6 = pack_value (constants.%i64, bool) [concrete = constants.%.abd]
// CHECK:STDOUT:   %int_2.loc15_15.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc15_15.2: %pack_type.8f6 = pack_value (constants.%i64, bool) [concrete = constants.%.abd]
// CHECK:STDOUT:   %specific_fn.loc15: <specific function> = specific_function %impl.elem0.loc15, @tuple.type.as.Count.impl.N(constants.%int_2, constants.%.abd) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.6af]
// CHECK:STDOUT:   %bound_method.loc15_15: <bound method> = bound_method %t.ref, %specific_fn.loc15
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc15: init %i64 = call %bound_method.loc15_15(%t.ref)
// CHECK:STDOUT:   %e.ref: %empty_tuple.type = name_ref e, %e
// CHECK:STDOUT:   %Count.ref.loc16: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc16: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc16: %.91f = impl_witness_access constants.%Count.impl_witness.f33, element0 [concrete = constants.%tuple.type.as.Count.impl.N.d02]
// CHECK:STDOUT:   %bound_method.loc16_11: <bound method> = bound_method %e.ref, %impl.elem0.loc16
// CHECK:STDOUT:   %int_0.loc16_22.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc16_22.1: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %int_0.loc16_22.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc16_22.2: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @tuple.type.as.Count.impl.N(constants.%int_0, constants.%.d3f) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.a0a]
// CHECK:STDOUT:   %bound_method.loc16_22: <bound method> = bound_method %e.ref, %specific_fn.loc16
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc16: init %i64 = call %bound_method.loc16_22(%e.ref)
// CHECK:STDOUT:   return %tuple.type.as.Count.impl.N.call.loc16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Count.impl(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity.patt.loc8_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc8_14.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc8_24 => constants.%pack_type.c29
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.fc0
// CHECK:STDOUT:   %T.patt.loc8_24.2 => constants.%T.patt.f84
// CHECK:STDOUT:   %T.loc8_24.1 => constants.%T
// CHECK:STDOUT:   %.loc8_14.2 => constants.%.99e
// CHECK:STDOUT:   %.loc8_37.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc8_37.2 => constants.%.425
// CHECK:STDOUT:   %tuple.type.loc8_43.1 => constants.%tuple.type.852
// CHECK:STDOUT:   %tuple => constants.%tuple.d38
// CHECK:STDOUT:   %pack_type.loc8_43 => constants.%pack_type.8fb
// CHECK:STDOUT:   %tuple.type.loc8_43.2 => constants.%tuple.type.423
// CHECK:STDOUT:   %.loc8_54 => constants.%.317
// CHECK:STDOUT:   %Count.impl_witness.loc8_54.2 => constants.%Count.impl_witness.5db
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type => constants.%tuple.type.as.Count.impl.N.type.c5b
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N => constants.%tuple.type.as.Count.impl.N.e1d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Count.impl.N(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity => constants.%arity
// CHECK:STDOUT:   %pack_type.loc9_15.1 => constants.%pack_type.c29
// CHECK:STDOUT:   %T => constants.%T
// CHECK:STDOUT:   %pack_type.loc9_15.2 => constants.%pack_type.8fb
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.423
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.e36
// CHECK:STDOUT:   %self.param_patt.loc9_15.2 => constants.%self.param_patt.280
// CHECK:STDOUT:   %self.patt.loc9_15.2 => constants.%self.patt.d43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Count.impl(constants.%int_2, constants.%.abd) {
// CHECK:STDOUT:   %arity.patt.loc8_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc8_14.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc8_24 => constants.%pack_type.8f6
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.b37
// CHECK:STDOUT:   %T.patt.loc8_24.2 => constants.%T.patt.8a9
// CHECK:STDOUT:   %T.loc8_24.1 => constants.%.abd
// CHECK:STDOUT:   %.loc8_14.2 => constants.%.6c7
// CHECK:STDOUT:   %.loc8_37.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc8_37.2 => constants.%.867
// CHECK:STDOUT:   %tuple.type.loc8_43.1 => constants.%tuple.type.693
// CHECK:STDOUT:   %tuple => constants.%tuple.3f9
// CHECK:STDOUT:   %pack_type.loc8_43 => constants.%pack_type.394
// CHECK:STDOUT:   %tuple.type.loc8_43.2 => constants.%tuple.type.f41
// CHECK:STDOUT:   %.loc8_54 => constants.%.56c
// CHECK:STDOUT:   %Count.impl_witness.loc8_54.2 => constants.%Count.impl_witness.897
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type => constants.%tuple.type.as.Count.impl.N.type.487
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N => constants.%tuple.type.as.Count.impl.N.a1e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Count.impl.N(constants.%int_2, constants.%.abd) {
// CHECK:STDOUT:   %arity => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc9_15.1 => constants.%pack_type.8f6
// CHECK:STDOUT:   %T => constants.%.abd
// CHECK:STDOUT:   %pack_type.loc9_15.2 => constants.%pack_type.394
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.f41
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.ea0
// CHECK:STDOUT:   %self.param_patt.loc9_15.2 => constants.%self.param_patt.0b2
// CHECK:STDOUT:   %self.patt.loc9_15.2 => constants.%self.patt.a6d
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.6e7
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Count.impl(constants.%int_0, constants.%.d3f) {
// CHECK:STDOUT:   %arity.patt.loc8_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc8_14.1 => constants.%int_0
// CHECK:STDOUT:   %pack_type.loc8_24 => constants.%pack_type.28d
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.94c
// CHECK:STDOUT:   %T.patt.loc8_24.2 => constants.%T.patt.75e
// CHECK:STDOUT:   %T.loc8_24.1 => constants.%.d3f
// CHECK:STDOUT:   %.loc8_14.2 => constants.%.b4d
// CHECK:STDOUT:   %.loc8_37.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc8_37.2 => constants.%.8a1
// CHECK:STDOUT:   %tuple.type.loc8_43.1 => constants.%empty_tuple.type
// CHECK:STDOUT:   %tuple => constants.%empty_tuple
// CHECK:STDOUT:   %pack_type.loc8_43 => constants.%pack_type.54a
// CHECK:STDOUT:   %tuple.type.loc8_43.2 => constants.%empty_tuple.type
// CHECK:STDOUT:   %.loc8_54 => constants.%.406
// CHECK:STDOUT:   %Count.impl_witness.loc8_54.2 => constants.%Count.impl_witness.f33
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type => constants.%tuple.type.as.Count.impl.N.type.886
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N => constants.%tuple.type.as.Count.impl.N.d02
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Count.impl.N(constants.%int_0, constants.%.d3f) {
// CHECK:STDOUT:   %arity => constants.%int_0
// CHECK:STDOUT:   %pack_type.loc9_15.1 => constants.%pack_type.28d
// CHECK:STDOUT:   %T => constants.%.d3f
// CHECK:STDOUT:   %pack_type.loc9_15.2 => constants.%pack_type.54a
// CHECK:STDOUT:   %tuple.type => constants.%empty_tuple.type
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.cb1
// CHECK:STDOUT:   %self.param_patt.loc9_15.2 => constants.%self.param_patt.154
// CHECK:STDOUT:   %self.patt.loc9_15.2 => constants.%self.patt.462
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.782
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- requirement.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Add.type: type = fn_type @Add [concrete]
// CHECK:STDOUT:   %Add: %Add.type = struct_value () [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %Code.type: type = facet_type <@Code> [concrete]
// CHECK:STDOUT:   %Code.assoc_type: type = assoc_entity_type @Code [concrete]
// CHECK:STDOUT:   %assoc0.b5d: %Code.assoc_type = assoc_entity element0, @Code.WithSelf.%Code.WithSelf.Get.decl [concrete]
// CHECK:STDOUT:   %Code.impl_witness.526: <witness> = impl_witness @i64.as.Code.impl.%Code.impl_witness_table [concrete]
// CHECK:STDOUT:   %Code.facet.5ec: %Code.type = facet_value %i64, (%Code.impl_witness.526) [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.5c1: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.826: type = fn_type_with_self_type %Copy.WithSelf.Op.type.5c1, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.104: type = pack_type %Code.type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.2ee: type = pattern_type %pack_type.104 [symbolic]
// CHECK:STDOUT:   %T.patt.003: %pattern_type.2ee = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T.7c0: %pack_type.104 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.cc3: %pattern_type.2ee = pack_expansion_pattern %T.patt.003, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.3c6: %Code.type = pack_element %T.7c0, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.85b: type = tuple_type (%pack_type.104) [symbolic]
// CHECK:STDOUT:   %tuple.277: %tuple.type.85b = tuple_value (%T.7c0) [symbolic]
// CHECK:STDOUT:   %pack_type.6c6: type = pack_type %T.7c0, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.950: type = tuple_type (%pack_type.6c6) [symbolic]
// CHECK:STDOUT:   %.23d: <witness> = impl_self_witness %tuple.type.950, @Code [symbolic]
// CHECK:STDOUT:   %Code.impl_witness.9e1: <witness> = impl_witness @tuple.type.as.Code.impl.%Code.impl_witness_table, @tuple.type.as.Code.impl(%arity, %T.7c0) [symbolic]
// CHECK:STDOUT:   %pattern_type.26d: type = pattern_type %tuple.type.950 [symbolic]
// CHECK:STDOUT:   %self.param_patt.929: %pattern_type.26d = value_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt.a0d: %pattern_type.26d = wrapper_binding_pattern self, %self.param_patt.929 [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.type.3f1: type = fn_type @tuple.type.as.Code.impl.Get, @tuple.type.as.Code.impl(%arity, %T.7c0) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.64e: %tuple.type.as.Code.impl.Get.type.3f1 = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.254: <witness> = require_complete_type %tuple.type.950 [symbolic]
// CHECK:STDOUT:   %as_type.0f9: type = facet_access_type %.3c6 [symbolic]
// CHECK:STDOUT:   %require_complete.aa7: <witness> = require_complete_type %pack_type.6c6 [symbolic]
// CHECK:STDOUT:   %pattern_type.2b9: type = pattern_type %pack_type.6c6 [symbolic]
// CHECK:STDOUT:   %x.patt.572: %pattern_type.2b9 = value_binding_pattern x [symbolic]
// CHECK:STDOUT:   %.20c: %pattern_type.2b9 = pack_expansion_pattern %x.patt.572, invalid [symbolic]
// CHECK:STDOUT:   %.b39: %pattern_type.26d = tuple_pattern (%.20c) [symbolic]
// CHECK:STDOUT:   %total.patt: %pattern_type.f57 = ref_binding_pattern total [concrete]
// CHECK:STDOUT:   %total.var_patt: %pattern_type.f57 = var_pattern %total.patt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %require_complete.d18: <witness> = require_complete_type %as_type.0f9 [symbolic]
// CHECK:STDOUT:   %Code.WithSelf.Get.type.099: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.3c6) [symbolic]
// CHECK:STDOUT:   %Code.lookup_impl_witness.57d: <witness> = lookup_impl_witness %.3c6, @Code [symbolic]
// CHECK:STDOUT:   %.131: type = fn_type_with_self_type %Code.WithSelf.Get.type.099, %.3c6 [symbolic]
// CHECK:STDOUT:   %impl.elem0.5c5: %.131 = impl_witness_access %Code.lookup_impl_witness.57d, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.f5a: <specific function> = specific_impl_function %impl.elem0.5c5, @Code.WithSelf.Get(%.3c6) [symbolic]
// CHECK:STDOUT:   %self.param_patt.108: %pattern_type.f57 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f4: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt.108 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc17 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc17 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc17 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.1ac: type = tuple_type (%i64, %i64) [concrete]
// CHECK:STDOUT:   %tuple.type.206: type = tuple_type (%i64, %tuple.type.1ac) [concrete]
// CHECK:STDOUT:   %pattern_type.7f1: type = pattern_type %tuple.type.206 [concrete]
// CHECK:STDOUT:   %ptr.12e: type = ptr_type %tuple.type.1ac [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.402e: %pack_type.8f6 = pack_value (%i64, %tuple.type.1ac) [concrete]
// CHECK:STDOUT:   %pack_type.a94: type = pack_type %Code.type, %int_2 [concrete]
// CHECK:STDOUT:   %.911: %pack_type.a94 = pack_value (%Code.facet.5ec, %Code.facet.5ec) [concrete]
// CHECK:STDOUT:   %pattern_type.773: type = pattern_type %pack_type.a94 [concrete]
// CHECK:STDOUT:   %T.patt.b9f: %pattern_type.773 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.65a: %pattern_type.773 = pack_expansion_pattern %T.patt.b9f, %arity.patt [symbolic]
// CHECK:STDOUT:   %.5d4: %Code.type = pack_element %.911, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.5bf: type = tuple_type (%Code.type, %Code.type) [concrete]
// CHECK:STDOUT:   %tuple.894: %tuple.type.5bf = tuple_value (%Code.facet.5ec, %Code.facet.5ec) [concrete]
// CHECK:STDOUT:   %pack_type.02b: type = pack_type %.911, %int_2 [concrete]
// CHECK:STDOUT:   %.817: <witness> = impl_self_witness %tuple.type.1ac, @Code [concrete]
// CHECK:STDOUT:   %Code.impl_witness.503: <witness> = impl_witness @tuple.type.as.Code.impl.%Code.impl_witness_table, @tuple.type.as.Code.impl(%int_2, %.911) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.type.5f5: type = fn_type @tuple.type.as.Code.impl.Get, @tuple.type.as.Code.impl(%int_2, %.911) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.a0c: %tuple.type.as.Code.impl.Get.type.5f5 = struct_value () [concrete]
// CHECK:STDOUT:   %Code.facet.761: %Code.type = facet_value %tuple.type.1ac, (%Code.impl_witness.503) [concrete]
// CHECK:STDOUT:   %.9aa: %pack_type.a94 = pack_value (%Code.facet.5ec, %Code.facet.761) [concrete]
// CHECK:STDOUT:   %.dc5: %Code.type = pack_element %.9aa, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.bf3: %tuple.type.5bf = tuple_value (%Code.facet.5ec, %Code.facet.761) [concrete]
// CHECK:STDOUT:   %pack_type.521: type = pack_type %.9aa, %int_2 [concrete]
// CHECK:STDOUT:   %.402c: <witness> = impl_self_witness %tuple.type.206, @Code [concrete]
// CHECK:STDOUT:   %Code.impl_witness.a5e: <witness> = impl_witness @tuple.type.as.Code.impl.%Code.impl_witness_table, @tuple.type.as.Code.impl(%int_2, %.9aa) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.type.137: type = fn_type @tuple.type.as.Code.impl.Get, @tuple.type.as.Code.impl(%int_2, %.9aa) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.497: %tuple.type.as.Code.impl.Get.type.137 = struct_value () [concrete]
// CHECK:STDOUT:   %Code.facet.3e8: %Code.type = facet_value %tuple.type.206, (%Code.impl_witness.a5e) [concrete]
// CHECK:STDOUT:   %Code.WithSelf.Get.type.f54: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%Code.facet.3e8) [concrete]
// CHECK:STDOUT:   %.888: type = fn_type_with_self_type %Code.WithSelf.Get.type.f54, %Code.facet.3e8 [concrete]
// CHECK:STDOUT:   %self.param_patt.14a: %pattern_type.7f1 = value_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.8d5: %pattern_type.7f1 = wrapper_binding_pattern self, %self.param_patt.14a [concrete]
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.specific_fn.9e0: <specific function> = specific_function %tuple.type.as.Code.impl.Get.497, @tuple.type.as.Code.impl.Get(%int_2, %.9aa) [concrete]
// CHECK:STDOUT:   %complete_type.1e7: <witness> = complete_type_witness %tuple.type.206 [concrete]
// CHECK:STDOUT:   %as_type.a3a: type = facet_access_type %.dc5 [symbolic]
// CHECK:STDOUT:   %.6d6: %pack_type.8f6 = pack_value (%i64.builtin, %ptr.12e) [concrete]
// CHECK:STDOUT:   %complete_type.139: <witness> = complete_type_witness %pack_type.521 [concrete]
// CHECK:STDOUT:   %pattern_type.618: type = pattern_type %pack_type.521 [concrete]
// CHECK:STDOUT:   %x.patt.fa5: %pattern_type.618 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %.c5f: %pattern_type.618 = pack_expansion_pattern %x.patt.fa5, invalid [concrete]
// CHECK:STDOUT:   %.695: %pattern_type.7f1 = tuple_pattern (%.c5f) [concrete]
// CHECK:STDOUT:   %require_complete.2e4: <witness> = require_complete_type %as_type.a3a [symbolic]
// CHECK:STDOUT:   %Code.WithSelf.Get.type.f20: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.dc5) [symbolic]
// CHECK:STDOUT:   %.524: type = fn_type_with_self_type %Code.WithSelf.Get.type.f20, %.dc5 [symbolic]
// CHECK:STDOUT:   %Code.lookup_impl_witness.0f5: <witness> = lookup_impl_witness %.dc5, @Code [symbolic]
// CHECK:STDOUT:   %impl.elem0.e83: %.524 = impl_witness_access %Code.lookup_impl_witness.0f5, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.769: <specific function> = specific_impl_function %impl.elem0.e83, @Code.WithSelf.Get(%.dc5) [symbolic]
// CHECK:STDOUT:   %complete_type.3d3: <witness> = complete_type_witness %tuple.type.1ac [concrete]
// CHECK:STDOUT:   %pattern_type.037: type = pattern_type %tuple.type.1ac [concrete]
// CHECK:STDOUT:   %self.param_patt.18a: %pattern_type.037 = value_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.92a: %pattern_type.037 = wrapper_binding_pattern self, %self.param_patt.18a [concrete]
// CHECK:STDOUT:   %as_type.6a3: type = facet_access_type %.5d4 [symbolic]
// CHECK:STDOUT:   %complete_type.ea7: <witness> = complete_type_witness %pack_type.02b [concrete]
// CHECK:STDOUT:   %pattern_type.184: type = pattern_type %pack_type.02b [concrete]
// CHECK:STDOUT:   %x.patt.a0c: %pattern_type.184 = value_binding_pattern x [concrete]
// CHECK:STDOUT:   %.bf8: %pattern_type.184 = pack_expansion_pattern %x.patt.a0c, invalid [concrete]
// CHECK:STDOUT:   %.d55: %pattern_type.037 = tuple_pattern (%.bf8) [concrete]
// CHECK:STDOUT:   %require_complete.d85: <witness> = require_complete_type %as_type.6a3 [symbolic]
// CHECK:STDOUT:   %Code.WithSelf.Get.type.a80: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.5d4) [symbolic]
// CHECK:STDOUT:   %.faa: type = fn_type_with_self_type %Code.WithSelf.Get.type.a80, %.5d4 [symbolic]
// CHECK:STDOUT:   %Code.lookup_impl_witness.88e: <witness> = lookup_impl_witness %.5d4, @Code [symbolic]
// CHECK:STDOUT:   %impl.elem0.cd4: %.faa = impl_witness_access %Code.lookup_impl_witness.88e, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn.a2f: <specific function> = specific_impl_function %impl.elem0.cd4, @Code.WithSelf.Get(%.5d4) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc17 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc17 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   impl_decl @tuple.type.as.Code.impl [concrete] {
// CHECK:STDOUT:     %arity.patt.loc14_14.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc14_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc14_24.1: @tuple.type.as.Code.impl.%pattern_type (%pattern_type.2ee) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc14_24.2 (constants.%T.patt.003)]
// CHECK:STDOUT:     %.loc14_14.1: @tuple.type.as.Code.impl.%pattern_type (%pattern_type.2ee) = pack_expansion_pattern %T.patt.loc14_24.1, %arity.patt.loc14_14.1 [symbolic = %.loc14_14.2 (constants.%.cc3)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc14_43.1: @tuple.type.as.Code.impl.%tuple.type.loc14_43.1 (%tuple.type.85b) = tuple_literal (constants.%T.7c0) [symbolic = %tuple (constants.%tuple.277)]
// CHECK:STDOUT:     %.loc14_43.2: type = converted %.loc14_43.1, constants.%tuple.type.950 [symbolic = %tuple.type.loc14_43.2 (constants.%tuple.type.950)]
// CHECK:STDOUT:     %Code.ref.loc14_48: type = name_ref Code, file.%Code.decl [concrete = constants.%Code.type]
// CHECK:STDOUT:     %arity.loc14_14.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc14_14.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc14_26: type = splice_block %Code.ref.loc14_26 [concrete = constants.%Code.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %Code.ref.loc14_26: type = name_ref Code, file.%Code.decl [concrete = constants.%Code.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc14_24.2: @tuple.type.as.Code.impl.%pack_type.loc14_24 (%pack_type.104) = symbolic_binding T, 1 [symbolic = %T.loc14_24.1 (constants.%T.7c0)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc14: <witness> = impl_self_witness @tuple.type.as.Code.impl.%.loc14_43.2, @Code [symbolic = @tuple.type.as.Code.impl.%.loc14_53 (constants.%.23d)]
// CHECK:STDOUT:   %.loc16: %pack_type.8f6 = pack_value (constants.%i64.builtin, constants.%ptr.12e) [concrete = constants.%.6d6]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic impl @tuple.type.as.Code.impl(%arity.loc14_14.2: Core.IntLiteral, %T.loc14_24.2: @tuple.type.as.Code.impl.%pack_type.loc14_24 (%pack_type.104)) {
// CHECK:STDOUT:   %arity.patt.loc14_14.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc14_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc14_14.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc14_14.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc14_24: type = pack_type constants.%Code.type, %arity.loc14_14.1 [symbolic = %pack_type.loc14_24 (constants.%pack_type.104)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type.loc14_24 [symbolic = %pattern_type (constants.%pattern_type.2ee)]
// CHECK:STDOUT:   %T.patt.loc14_24.2: @tuple.type.as.Code.impl.%pattern_type (%pattern_type.2ee) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc14_24.2 (constants.%T.patt.003)]
// CHECK:STDOUT:   %T.loc14_24.1: @tuple.type.as.Code.impl.%pack_type.loc14_24 (%pack_type.104) = symbolic_binding T, 1 [symbolic = %T.loc14_24.1 (constants.%T.7c0)]
// CHECK:STDOUT:   %.loc14_14.2: @tuple.type.as.Code.impl.%pattern_type (%pattern_type.2ee) = pack_expansion_pattern %T.patt.loc14_24.2, %arity.patt.loc14_14.2 [symbolic = %.loc14_14.2 (constants.%.cc3)]
// CHECK:STDOUT:   %.loc14_37.1: Core.IntLiteral = pack_index [symbolic = %.loc14_37.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc14_37.2: %Code.type = pack_element %T.loc14_24.1, %.loc14_37.1 [symbolic = %.loc14_37.2 (constants.%.3c6)]
// CHECK:STDOUT:   %tuple.type.loc14_43.1: type = tuple_type (%pack_type.loc14_24) [symbolic = %tuple.type.loc14_43.1 (constants.%tuple.type.85b)]
// CHECK:STDOUT:   %tuple: @tuple.type.as.Code.impl.%tuple.type.loc14_43.1 (%tuple.type.85b) = tuple_value (%T.loc14_24.1) [symbolic = %tuple (constants.%tuple.277)]
// CHECK:STDOUT:   %pack_type.loc14_43: type = pack_type %T.loc14_24.1, %arity.loc14_14.1 [symbolic = %pack_type.loc14_43 (constants.%pack_type.6c6)]
// CHECK:STDOUT:   %tuple.type.loc14_43.2: type = tuple_type (%pack_type.loc14_43) [symbolic = %tuple.type.loc14_43.2 (constants.%tuple.type.950)]
// CHECK:STDOUT:   %.loc14_53: <witness> = impl_self_witness %tuple.type.loc14_43.2, @Code [symbolic = %.loc14_53 (constants.%.23d)]
// CHECK:STDOUT:   %Code.impl_witness.loc14_53.2: <witness> = impl_witness %Code.impl_witness_table, @tuple.type.as.Code.impl(%arity.loc14_14.1, %T.loc14_24.1) [symbolic = %Code.impl_witness.loc14_53.2 (constants.%Code.impl_witness.9e1)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.type: type = fn_type @tuple.type.as.Code.impl.Get, @tuple.type.as.Code.impl(%arity.loc14_14.1, %T.loc14_24.1) [symbolic = %tuple.type.as.Code.impl.Get.type (constants.%tuple.type.as.Code.impl.Get.type.3f1)]
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get: @tuple.type.as.Code.impl.%tuple.type.as.Code.impl.Get.type (%tuple.type.as.Code.impl.Get.type.3f1) = struct_value () [symbolic = %tuple.type.as.Code.impl.Get (constants.%tuple.type.as.Code.impl.Get.64e)]
// CHECK:STDOUT:
// CHECK:STDOUT:   impl: %.loc14_43.2 as %Code.ref.loc14_48 {
// CHECK:STDOUT:     %tuple.type.as.Code.impl.Get.decl: @tuple.type.as.Code.impl.%tuple.type.as.Code.impl.Get.type (%tuple.type.as.Code.impl.Get.type.3f1) = fn_decl @tuple.type.as.Code.impl.Get [symbolic = @tuple.type.as.Code.impl.%tuple.type.as.Code.impl.Get (constants.%tuple.type.as.Code.impl.Get.64e)] {
// CHECK:STDOUT:       %self.param_patt.loc15_10.1: @tuple.type.as.Code.impl.Get.%pattern_type.loc15 (%pattern_type.26d) = value_param_pattern [symbolic = %self.param_patt.loc15_10.2 (constants.%self.param_patt.929)]
// CHECK:STDOUT:       %self.patt.loc15_10.1: @tuple.type.as.Code.impl.Get.%pattern_type.loc15 (%pattern_type.26d) = wrapper_binding_pattern self, %self.param_patt.loc15_10.1 [symbolic = %self.patt.loc15_10.2 (constants.%self.patt.a0d)]
// CHECK:STDOUT:       %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:       %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64.loc15 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %i64.loc15: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %.loc15: Core.Form = init_form %i64.loc15 [concrete = constants.%.bc0]
// CHECK:STDOUT:       %self.param: @tuple.type.as.Code.impl.Get.%tuple.type (%tuple.type.950) = value_param call_param0
// CHECK:STDOUT:       %Self.ref: type = name_ref Self, @tuple.type.as.Code.impl.%.loc14_43.2 [symbolic = %tuple.type (constants.%tuple.type.950)]
// CHECK:STDOUT:       %self: @tuple.type.as.Code.impl.Get.%tuple.type (%tuple.type.950) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:       %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Code.impl_witness_table = impl_witness_table (%tuple.type.as.Code.impl.Get.decl), @tuple.type.as.Code.impl [concrete]
// CHECK:STDOUT:     %Code.impl_witness.loc14_53.1: <witness> = impl_witness %Code.impl_witness_table, @tuple.type.as.Code.impl(constants.%arity, constants.%T.7c0) [symbolic = %Code.impl_witness.loc14_53.2 (constants.%Code.impl_witness.9e1)]
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Get = %tuple.type.as.Code.impl.Get.decl
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     .Add = <poisoned>
// CHECK:STDOUT:     extend %Code.ref.loc14_48
// CHECK:STDOUT:     witness = %Code.impl_witness.loc14_53.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @tuple.type.as.Code.impl.Get(@tuple.type.as.Code.impl.%arity.loc14_14.2: Core.IntLiteral, @tuple.type.as.Code.impl.%T.loc14_24.2: @tuple.type.as.Code.impl.%pack_type.loc14_24 (%pack_type.104)) {
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc15_10.1: type = pack_type constants.%Code.type, %arity [symbolic = %pack_type.loc15_10.1 (constants.%pack_type.104)]
// CHECK:STDOUT:   %T: @tuple.type.as.Code.impl.Get.%pack_type.loc15_10.1 (%pack_type.104) = symbolic_binding T, 1 [symbolic = %T (constants.%T.7c0)]
// CHECK:STDOUT:   %pack_type.loc15_10.2: type = pack_type %T, %arity [symbolic = %pack_type.loc15_10.2 (constants.%pack_type.6c6)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%pack_type.loc15_10.2) [symbolic = %tuple.type (constants.%tuple.type.950)]
// CHECK:STDOUT:   %pattern_type.loc15: type = pattern_type %tuple.type [symbolic = %pattern_type.loc15 (constants.%pattern_type.26d)]
// CHECK:STDOUT:   %self.param_patt.loc15_10.2: @tuple.type.as.Code.impl.Get.%pattern_type.loc15 (%pattern_type.26d) = value_param_pattern [symbolic = %self.param_patt.loc15_10.2 (constants.%self.param_patt.929)]
// CHECK:STDOUT:   %self.patt.loc15_10.2: @tuple.type.as.Code.impl.Get.%pattern_type.loc15 (%pattern_type.26d) = wrapper_binding_pattern self, %self.param_patt.loc15_10.2 [symbolic = %self.patt.loc15_10.2 (constants.%self.patt.a0d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc15: <witness> = require_complete_type %tuple.type [symbolic = %require_complete.loc15 (constants.%require_complete.254)]
// CHECK:STDOUT:   %.loc16_22.5: Core.IntLiteral = pack_index [symbolic = %.loc16_22.5 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc16_22.6: %Code.type = pack_element %T, %.loc16_22.5 [symbolic = %.loc16_22.6 (constants.%.3c6)]
// CHECK:STDOUT:   %as_type.loc16_22.2: type = facet_access_type %.loc16_22.6 [symbolic = %as_type.loc16_22.2 (constants.%as_type.0f9)]
// CHECK:STDOUT:   %require_complete.loc16: <witness> = require_complete_type %pack_type.loc15_10.2 [symbolic = %require_complete.loc16 (constants.%require_complete.aa7)]
// CHECK:STDOUT:   %pattern_type.loc16: type = pattern_type %pack_type.loc15_10.2 [symbolic = %pattern_type.loc16 (constants.%pattern_type.2b9)]
// CHECK:STDOUT:   %x.patt.loc16_20.2: @tuple.type.as.Code.impl.Get.%pattern_type.loc16 (%pattern_type.2b9) = value_binding_pattern x [symbolic = %x.patt.loc16_20.2 (constants.%x.patt.572)]
// CHECK:STDOUT:   %.loc16_10.9: @tuple.type.as.Code.impl.Get.%pattern_type.loc16 (%pattern_type.2b9) = pack_expansion_pattern %x.patt.loc16_20.2, invalid [symbolic = %.loc16_10.9 (constants.%.20c)]
// CHECK:STDOUT:   %.loc16_10.10: @tuple.type.as.Code.impl.Get.%pattern_type.loc15 (%pattern_type.26d) = tuple_pattern (%.loc16_10.9) [symbolic = %.loc16_10.10 (constants.%.b39)]
// CHECK:STDOUT:   %require_complete.loc18: <witness> = require_complete_type %as_type.loc16_22.2 [symbolic = %require_complete.loc18 (constants.%require_complete.d18)]
// CHECK:STDOUT:   %Code.WithSelf.Get.type: type = fn_type @Code.WithSelf.Get, @Code.WithSelf(%.loc16_22.6) [symbolic = %Code.WithSelf.Get.type (constants.%Code.WithSelf.Get.type.099)]
// CHECK:STDOUT:   %.loc18_34: type = fn_type_with_self_type %Code.WithSelf.Get.type, %.loc16_22.6 [symbolic = %.loc18_34 (constants.%.131)]
// CHECK:STDOUT:   %Code.lookup_impl_witness: <witness> = lookup_impl_witness %.loc16_22.6, @Code [symbolic = %Code.lookup_impl_witness (constants.%Code.lookup_impl_witness.57d)]
// CHECK:STDOUT:   %impl.elem0.loc18_34.2: @tuple.type.as.Code.impl.Get.%.loc18_34 (%.131) = impl_witness_access %Code.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc18_34.2 (constants.%impl.elem0.5c5)]
// CHECK:STDOUT:   %specific_impl_fn.loc18_34.2: <specific function> = specific_impl_function %impl.elem0.loc18_34.2, @Code.WithSelf.Get(%.loc16_22.6) [symbolic = %specific_impl_fn.loc18_34.2 (constants.%specific_impl_fn.f5a)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @tuple.type.as.Code.impl.Get.%tuple.type (%tuple.type.950)) -> out %return.param: %i64 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %self.ref: @tuple.type.as.Code.impl.Get.%tuple.type (%tuple.type.950) = name_ref self, %self
// CHECK:STDOUT:     %.loc16_10.1: @tuple.type.as.Code.impl.Get.%pack_type.loc15_10.2 (%pack_type.6c6) = pack_expansion_expr %.loc16_10.8 {
// CHECK:STDOUT:       %.loc16_10.4: Core.IntLiteral = pack_index [symbolic = %.loc16_22.5 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc16_10.5: Core.IntLiteral = pack_index [symbolic = %.loc16_22.5 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc16_10.6: %Code.type = pack_element constants.%T.7c0, %.loc16_10.5 [symbolic = %.loc16_22.6 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc16_10: type = facet_access_type %.loc16_10.6 [symbolic = %as_type.loc16_22.2 (constants.%as_type.0f9)]
// CHECK:STDOUT:       %.loc16_10.7: type = converted %.loc16_10.6, %as_type.loc16_10 [symbolic = %as_type.loc16_22.2 (constants.%as_type.0f9)]
// CHECK:STDOUT:       %.loc16_10.8: @tuple.type.as.Code.impl.Get.%as_type.loc16_22.2 (%as_type.0f9) = pack_element %self.ref, %.loc16_10.4
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc16_22.1: type = splice_block %.loc16_22.4 [symbolic = %as_type.loc16_22.2 (constants.%as_type.0f9)] {
// CHECK:STDOUT:       %T.ref: @tuple.type.as.Code.impl.Get.%pack_type.loc15_10.1 (%pack_type.104) = name_ref T, @tuple.type.as.Code.impl.%T.loc14_24.2 [symbolic = %T (constants.%T.7c0)]
// CHECK:STDOUT:       %.loc16_22.2: Core.IntLiteral = pack_index [symbolic = %.loc16_22.5 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc16_22.3: %Code.type = pack_element %T.ref, %.loc16_22.2 [symbolic = %.loc16_22.6 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc16_22.1: type = facet_access_type %.loc16_22.3 [symbolic = %as_type.loc16_22.2 (constants.%as_type.0f9)]
// CHECK:STDOUT:       %.loc16_22.4: type = converted %.loc16_22.3, %as_type.loc16_22.1 [symbolic = %as_type.loc16_22.2 (constants.%as_type.0f9)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %x: @tuple.type.as.Code.impl.Get.%pack_type.loc15_10.2 (%pack_type.6c6) = wrapper_binding x, %.loc16_10.1
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %x.patt.loc16_20.1: @tuple.type.as.Code.impl.Get.%pattern_type.loc16 (%pattern_type.2b9) = value_binding_pattern x [symbolic = %x.patt.loc16_20.2 (constants.%x.patt.572)]
// CHECK:STDOUT:       %.loc16_10.2: @tuple.type.as.Code.impl.Get.%pattern_type.loc16 (%pattern_type.2b9) = pack_expansion_pattern %x.patt.loc16_20.1, invalid [symbolic = %.loc16_10.9 (constants.%.20c)]
// CHECK:STDOUT:       %.loc16_10.3: @tuple.type.as.Code.impl.Get.%pattern_type.loc15 (%pattern_type.26d) = tuple_pattern (%.loc16_10.2) [symbolic = %.loc16_10.10 (constants.%.b39)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %total.var: ref %i64 = var_storage %total.var_patt
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc17: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc17_5.1: <bound method> = bound_method %int_0, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:     %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc17_5.2: <bound method> = bound_method %int_0, %specific_fn.loc17 [concrete = constants.%bound_method]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc17_5.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc17: init %i64 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     assign %total.var, %.loc17
// CHECK:STDOUT:     %i64.loc17: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %total: ref %i64 = wrapper_binding total, %total.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %total.patt: %pattern_type.f57 = ref_binding_pattern total [concrete = constants.%total.patt]
// CHECK:STDOUT:       %total.var_patt: %pattern_type.f57 = var_pattern %total.patt [concrete = constants.%total.var_patt]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc18_5: Core.IntLiteral = specific_constant @tuple.type.as.Code.impl.%arity.loc14_14.2, @tuple.type.as.Code.impl(constants.%arity, constants.%T.7c0) [symbolic = %arity (constants.%arity)]
// CHECK:STDOUT:     pack_expansion_statement %.loc18_5 {
// CHECK:STDOUT:       %total.ref.loc18_9: ref %i64 = name_ref total, %total
// CHECK:STDOUT:       %Add.ref: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:       %total.ref.loc18_21: ref %i64 = name_ref total, %total
// CHECK:STDOUT:       %x.ref: @tuple.type.as.Code.impl.Get.%pack_type.loc15_10.2 (%pack_type.6c6) = name_ref x, %x
// CHECK:STDOUT:       %.loc18_28.1: Core.IntLiteral = pack_index [symbolic = %.loc16_22.5 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc18_28.2: Core.IntLiteral = pack_index [symbolic = %.loc16_22.5 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc18_28.3: %Code.type = pack_element constants.%T.7c0, %.loc18_28.2 [symbolic = %.loc16_22.6 (constants.%.3c6)]
// CHECK:STDOUT:       %as_type.loc18: type = facet_access_type %.loc18_28.3 [symbolic = %as_type.loc16_22.2 (constants.%as_type.0f9)]
// CHECK:STDOUT:       %.loc18_28.4: type = converted %.loc18_28.3, %as_type.loc18 [symbolic = %as_type.loc16_22.2 (constants.%as_type.0f9)]
// CHECK:STDOUT:       %.loc18_28.5: @tuple.type.as.Code.impl.Get.%as_type.loc16_22.2 (%as_type.0f9) = pack_element %x.ref, %.loc18_28.1
// CHECK:STDOUT:       %Get.ref: %Code.assoc_type = name_ref Get, @Code.WithSelf.%assoc0 [concrete = constants.%assoc0.b5d]
// CHECK:STDOUT:       %impl.elem0.loc18_34.1: @tuple.type.as.Code.impl.Get.%.loc18_34 (%.131) = impl_witness_access constants.%Code.lookup_impl_witness.57d, element0 [symbolic = %impl.elem0.loc18_34.2 (constants.%impl.elem0.5c5)]
// CHECK:STDOUT:       %bound_method.loc18_34: <bound method> = bound_method %.loc18_28.5, %impl.elem0.loc18_34.1
// CHECK:STDOUT:       %.loc18_39.1: %Code.type = converted constants.%as_type.0f9, constants.%.3c6 [symbolic = %.loc16_22.6 (constants.%.3c6)]
// CHECK:STDOUT:       %.loc18_39.2: %Code.type = converted constants.%as_type.0f9, constants.%.3c6 [symbolic = %.loc16_22.6 (constants.%.3c6)]
// CHECK:STDOUT:       %specific_impl_fn.loc18_34.1: <specific function> = specific_impl_function %impl.elem0.loc18_34.1, @Code.WithSelf.Get(constants.%.3c6) [symbolic = %specific_impl_fn.loc18_34.2 (constants.%specific_impl_fn.f5a)]
// CHECK:STDOUT:       %bound_method.loc18_39: <bound method> = bound_method %.loc18_28.5, %specific_impl_fn.loc18_34.1
// CHECK:STDOUT:       %Code.WithSelf.Get.call: init %i64 = call %bound_method.loc18_39(%.loc18_28.5)
// CHECK:STDOUT:       %.loc18_21: %i64 = acquire_value %total.ref.loc18_21
// CHECK:STDOUT:       %.loc18_39.3: %i64 = value_of_initializer %Code.WithSelf.Get.call
// CHECK:STDOUT:       %.loc18_39.4: %i64 = converted %Code.WithSelf.Get.call, %.loc18_39.3
// CHECK:STDOUT:       %Add.call: init %i64 = call %Add.ref(%.loc18_21, %.loc18_39.4)
// CHECK:STDOUT:       assign %total.ref.loc18_9, %Add.call
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %total.ref.loc19: ref %i64 = name_ref total, %total
// CHECK:STDOUT:     %.loc19: %i64 = acquire_value %total.ref.loc19
// CHECK:STDOUT:     %impl.elem0.loc19: %.826 = impl_witness_access constants.%Copy.impl_witness.8cc, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:     %bound_method.loc19_12.1: <bound method> = bound_method %.loc19, %impl.elem0.loc19
// CHECK:STDOUT:     %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc19_12.2: <bound method> = bound_method %.loc19, %specific_fn.loc19
// CHECK:STDOUT:     %Int.as.Copy.impl.Op.call: init %i64 = call %bound_method.loc19_12.2(%.loc19)
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %total.var, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%total.var)
// CHECK:STDOUT:     return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc17(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc17(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc17(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%t.param: %tuple.type.206) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.ref: %tuple.type.206 = name_ref t, %t
// CHECK:STDOUT:   %Code.ref: type = name_ref Code, file.%Code.decl [concrete = constants.%Code.type]
// CHECK:STDOUT:   %Get.ref: %Code.assoc_type = name_ref Get, @Code.WithSelf.%assoc0 [concrete = constants.%assoc0.b5d]
// CHECK:STDOUT:   %impl.elem0: %.888 = impl_witness_access constants.%Code.impl_witness.a5e, element0 [concrete = constants.%tuple.type.as.Code.impl.Get.497]
// CHECK:STDOUT:   %bound_method.loc26_11: <bound method> = bound_method %t.ref, %impl.elem0
// CHECK:STDOUT:   %int_2.loc26_23.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc26_23.1: %pack_type.8f6 = pack_value (constants.%i64, constants.%tuple.type.1ac) [concrete = constants.%.402e]
// CHECK:STDOUT:   %int_2.loc26_23.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %.loc26_23.2: %pack_type.8f6 = pack_value (constants.%i64, constants.%tuple.type.1ac) [concrete = constants.%.402e]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @tuple.type.as.Code.impl.Get(constants.%int_2, constants.%.9aa) [concrete = constants.%tuple.type.as.Code.impl.Get.specific_fn.9e0]
// CHECK:STDOUT:   %bound_method.loc26_23: <bound method> = bound_method %t.ref, %specific_fn
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.call: init %i64 = call %bound_method.loc26_23(%t.ref)
// CHECK:STDOUT:   return %tuple.type.as.Code.impl.Get.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Code.impl(constants.%arity, constants.%T.7c0) {
// CHECK:STDOUT:   %arity.patt.loc14_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc14_14.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc14_24 => constants.%pack_type.104
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.2ee
// CHECK:STDOUT:   %T.patt.loc14_24.2 => constants.%T.patt.003
// CHECK:STDOUT:   %T.loc14_24.1 => constants.%T.7c0
// CHECK:STDOUT:   %.loc14_14.2 => constants.%.cc3
// CHECK:STDOUT:   %.loc14_37.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc14_37.2 => constants.%.3c6
// CHECK:STDOUT:   %tuple.type.loc14_43.1 => constants.%tuple.type.85b
// CHECK:STDOUT:   %tuple => constants.%tuple.277
// CHECK:STDOUT:   %pack_type.loc14_43 => constants.%pack_type.6c6
// CHECK:STDOUT:   %tuple.type.loc14_43.2 => constants.%tuple.type.950
// CHECK:STDOUT:   %.loc14_53 => constants.%.23d
// CHECK:STDOUT:   %Code.impl_witness.loc14_53.2 => constants.%Code.impl_witness.9e1
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.type => constants.%tuple.type.as.Code.impl.Get.type.3f1
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get => constants.%tuple.type.as.Code.impl.Get.64e
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Code.impl.Get(constants.%arity, constants.%T.7c0) {
// CHECK:STDOUT:   %arity => constants.%arity
// CHECK:STDOUT:   %pack_type.loc15_10.1 => constants.%pack_type.104
// CHECK:STDOUT:   %T => constants.%T.7c0
// CHECK:STDOUT:   %pack_type.loc15_10.2 => constants.%pack_type.6c6
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.950
// CHECK:STDOUT:   %pattern_type.loc15 => constants.%pattern_type.26d
// CHECK:STDOUT:   %self.param_patt.loc15_10.2 => constants.%self.param_patt.929
// CHECK:STDOUT:   %self.patt.loc15_10.2 => constants.%self.patt.a0d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Code.impl(constants.%int_2, constants.%.911) {
// CHECK:STDOUT:   %arity.patt.loc14_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc14_14.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc14_24 => constants.%pack_type.a94
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.773
// CHECK:STDOUT:   %T.patt.loc14_24.2 => constants.%T.patt.b9f
// CHECK:STDOUT:   %T.loc14_24.1 => constants.%.911
// CHECK:STDOUT:   %.loc14_14.2 => constants.%.65a
// CHECK:STDOUT:   %.loc14_37.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc14_37.2 => constants.%.5d4
// CHECK:STDOUT:   %tuple.type.loc14_43.1 => constants.%tuple.type.5bf
// CHECK:STDOUT:   %tuple => constants.%tuple.894
// CHECK:STDOUT:   %pack_type.loc14_43 => constants.%pack_type.02b
// CHECK:STDOUT:   %tuple.type.loc14_43.2 => constants.%tuple.type.1ac
// CHECK:STDOUT:   %.loc14_53 => constants.%.817
// CHECK:STDOUT:   %Code.impl_witness.loc14_53.2 => constants.%Code.impl_witness.503
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.type => constants.%tuple.type.as.Code.impl.Get.type.5f5
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get => constants.%tuple.type.as.Code.impl.Get.a0c
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Code.impl(constants.%int_2, constants.%.9aa) {
// CHECK:STDOUT:   %arity.patt.loc14_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc14_14.1 => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc14_24 => constants.%pack_type.a94
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.773
// CHECK:STDOUT:   %T.patt.loc14_24.2 => constants.%T.patt.b9f
// CHECK:STDOUT:   %T.loc14_24.1 => constants.%.9aa
// CHECK:STDOUT:   %.loc14_14.2 => constants.%.65a
// CHECK:STDOUT:   %.loc14_37.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc14_37.2 => constants.%.dc5
// CHECK:STDOUT:   %tuple.type.loc14_43.1 => constants.%tuple.type.5bf
// CHECK:STDOUT:   %tuple => constants.%tuple.bf3
// CHECK:STDOUT:   %pack_type.loc14_43 => constants.%pack_type.521
// CHECK:STDOUT:   %tuple.type.loc14_43.2 => constants.%tuple.type.206
// CHECK:STDOUT:   %.loc14_53 => constants.%.402c
// CHECK:STDOUT:   %Code.impl_witness.loc14_53.2 => constants.%Code.impl_witness.a5e
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get.type => constants.%tuple.type.as.Code.impl.Get.type.137
// CHECK:STDOUT:   %tuple.type.as.Code.impl.Get => constants.%tuple.type.as.Code.impl.Get.497
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Code.impl.Get(constants.%int_2, constants.%.9aa) {
// CHECK:STDOUT:   %arity => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc15_10.1 => constants.%pack_type.a94
// CHECK:STDOUT:   %T => constants.%.9aa
// CHECK:STDOUT:   %pack_type.loc15_10.2 => constants.%pack_type.521
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.206
// CHECK:STDOUT:   %pattern_type.loc15 => constants.%pattern_type.7f1
// CHECK:STDOUT:   %self.param_patt.loc15_10.2 => constants.%self.param_patt.14a
// CHECK:STDOUT:   %self.patt.loc15_10.2 => constants.%self.patt.8d5
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc15 => constants.%complete_type.1e7
// CHECK:STDOUT:   %.loc16_22.5 => constants.%.4ee
// CHECK:STDOUT:   %.loc16_22.6 => constants.%.dc5
// CHECK:STDOUT:   %as_type.loc16_22.2 => constants.%as_type.a3a
// CHECK:STDOUT:   %require_complete.loc16 => constants.%complete_type.139
// CHECK:STDOUT:   %pattern_type.loc16 => constants.%pattern_type.618
// CHECK:STDOUT:   %x.patt.loc16_20.2 => constants.%x.patt.fa5
// CHECK:STDOUT:   %.loc16_10.9 => constants.%.c5f
// CHECK:STDOUT:   %.loc16_10.10 => constants.%.695
// CHECK:STDOUT:   %require_complete.loc18 => constants.%require_complete.2e4
// CHECK:STDOUT:   %Code.WithSelf.Get.type => constants.%Code.WithSelf.Get.type.f20
// CHECK:STDOUT:   %.loc18_34 => constants.%.524
// CHECK:STDOUT:   %Code.lookup_impl_witness => constants.%Code.lookup_impl_witness.0f5
// CHECK:STDOUT:   %impl.elem0.loc18_34.2 => constants.%impl.elem0.e83
// CHECK:STDOUT:   %specific_impl_fn.loc18_34.2 => constants.%specific_impl_fn.769
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Code.impl.Get(constants.%int_2, constants.%.911) {
// CHECK:STDOUT:   %arity => constants.%int_2
// CHECK:STDOUT:   %pack_type.loc15_10.1 => constants.%pack_type.a94
// CHECK:STDOUT:   %T => constants.%.911
// CHECK:STDOUT:   %pack_type.loc15_10.2 => constants.%pack_type.02b
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.1ac
// CHECK:STDOUT:   %pattern_type.loc15 => constants.%pattern_type.037
// CHECK:STDOUT:   %self.param_patt.loc15_10.2 => constants.%self.param_patt.18a
// CHECK:STDOUT:   %self.patt.loc15_10.2 => constants.%self.patt.92a
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete.loc15 => constants.%complete_type.3d3
// CHECK:STDOUT:   %.loc16_22.5 => constants.%.4ee
// CHECK:STDOUT:   %.loc16_22.6 => constants.%.5d4
// CHECK:STDOUT:   %as_type.loc16_22.2 => constants.%as_type.6a3
// CHECK:STDOUT:   %require_complete.loc16 => constants.%complete_type.ea7
// CHECK:STDOUT:   %pattern_type.loc16 => constants.%pattern_type.184
// CHECK:STDOUT:   %x.patt.loc16_20.2 => constants.%x.patt.a0c
// CHECK:STDOUT:   %.loc16_10.9 => constants.%.bf8
// CHECK:STDOUT:   %.loc16_10.10 => constants.%.d55
// CHECK:STDOUT:   %require_complete.loc18 => constants.%require_complete.d85
// CHECK:STDOUT:   %Code.WithSelf.Get.type => constants.%Code.WithSelf.Get.type.a80
// CHECK:STDOUT:   %.loc18_34 => constants.%.faa
// CHECK:STDOUT:   %Code.lookup_impl_witness => constants.%Code.lookup_impl_witness.88e
// CHECK:STDOUT:   %impl.elem0.loc18_34.2 => constants.%impl.elem0.cd4
// CHECK:STDOUT:   %specific_impl_fn.loc18_34.2 => constants.%specific_impl_fn.a2f
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- generic_use.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.f41: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2 [concrete]
// CHECK:STDOUT:   %.abd: %pack_type.8f6 = pack_value (%i64, bool) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.897: <witness> = impl_witness @tuple.type.as.Count.impl.%Count.impl_witness_table, @tuple.type.as.Count.impl(%int_2, %.abd) [concrete]
// CHECK:STDOUT:   %Count.facet.4e8: %Count.type = facet_value %tuple.type.f41, (%Count.impl_witness.897) [concrete]
// CHECK:STDOUT:   %Use.specific_fn: <specific function> = specific_function %Use, @Use(%Count.facet.4e8) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%t.param: %tuple.type.f41) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Use.ref: %Use.type = name_ref Use, file.%Use.decl [concrete = constants.%Use]
// CHECK:STDOUT:   %t.ref: %tuple.type.f41 = name_ref t, %t
// CHECK:STDOUT:   %Count.facet.loc15_15.1: %Count.type = facet_value constants.%tuple.type.f41, (constants.%Count.impl_witness.897) [concrete = constants.%Count.facet.4e8]
// CHECK:STDOUT:   %.loc15_15.1: %Count.type = converted constants.%tuple.type.f41, %Count.facet.loc15_15.1 [concrete = constants.%Count.facet.4e8]
// CHECK:STDOUT:   %Count.facet.loc15_15.2: %Count.type = facet_value constants.%tuple.type.f41, (constants.%Count.impl_witness.897) [concrete = constants.%Count.facet.4e8]
// CHECK:STDOUT:   %.loc15_15.2: %Count.type = converted constants.%tuple.type.f41, %Count.facet.loc15_15.2 [concrete = constants.%Count.facet.4e8]
// CHECK:STDOUT:   %Use.specific_fn: <specific function> = specific_function %Use.ref, @Use(constants.%Count.facet.4e8) [concrete = constants.%Use.specific_fn]
// CHECK:STDOUT:   %Use.call: init %i64 = call %Use.specific_fn(%t.ref)
// CHECK:STDOUT:   return %Use.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- non_tuple_query.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Count.assoc_type: type = assoc_entity_type @Count [concrete]
// CHECK:STDOUT:   %assoc0.71c: %Count.assoc_type = assoc_entity element0, @Count.WithSelf.%Count.WithSelf.N.decl [concrete]
// CHECK:STDOUT:   %Count.impl_witness.146: <witness> = impl_witness @i64.as.Count.impl.%Count.impl_witness_table [concrete]
// CHECK:STDOUT:   %i64.as.Count.impl.N.type: type = fn_type @i64.as.Count.impl.N [concrete]
// CHECK:STDOUT:   %i64.as.Count.impl.N: %i64.as.Count.impl.N.type = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.1c5: %Count.type = facet_value %i64, (%Count.impl_witness.146) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.78e: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.1c5) [concrete]
// CHECK:STDOUT:   %.e58: type = fn_type_with_self_type %Count.WithSelf.N.type.78e, %Count.facet.1c5 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%x.param: %i64) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref: %i64 = name_ref x, %x
// CHECK:STDOUT:   %Count.ref: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0: %.e58 = impl_witness_access constants.%Count.impl_witness.146, element0 [concrete = constants.%i64.as.Count.impl.N]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %x.ref, %impl.elem0
// CHECK:STDOUT:   %i64.as.Count.impl.N.call: init %i64 = call %bound_method(%x.ref)
// CHECK:STDOUT:   return %i64.as.Count.impl.N.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- symbolic_query.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Count.assoc_type: type = assoc_entity_type @Count [concrete]
// CHECK:STDOUT:   %assoc0.71c: %Count.assoc_type = assoc_entity element0, @Count.WithSelf.%Count.WithSelf.N.decl [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.fc0: type = pattern_type %pack_type.c29 [symbolic]
// CHECK:STDOUT:   %T.patt: %pattern_type.fc0 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.99e: %pattern_type.fc0 = pack_expansion_pattern %T.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.425: type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.852: type = tuple_type (%pack_type.c29) [symbolic]
// CHECK:STDOUT:   %tuple: %tuple.type.852 = tuple_value (%T) [symbolic]
// CHECK:STDOUT:   %pack_type.8fb: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.423: type = tuple_type (%pack_type.8fb) [symbolic]
// CHECK:STDOUT:   %pattern_type.e36: type = pattern_type %tuple.type.423 [symbolic]
// CHECK:STDOUT:   %require_complete.f6f: <witness> = require_complete_type %tuple.type.423 [symbolic]
// CHECK:STDOUT:   %t.param_patt: %pattern_type.e36 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %t.patt: %pattern_type.e36 = wrapper_binding_pattern t, %t.param_patt [symbolic]
// CHECK:STDOUT:   %H.type: type = fn_type @H [concrete]
// CHECK:STDOUT:   %H: %H.type = struct_value () [concrete]
// CHECK:STDOUT:   %Count.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type.423, @Count [symbolic]
// CHECK:STDOUT:   %.f85: require_specific_def_type = require_specific_def @tuple.type.as.Count.impl(%arity, %T) [symbolic]
// CHECK:STDOUT:   %Count.facet.2b3: %Count.type = facet_value %tuple.type.423, (%Count.lookup_impl_witness) [symbolic]
// CHECK:STDOUT:   %Count.WithSelf.N.type.3c0: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.2b3) [symbolic]
// CHECK:STDOUT:   %.d75: type = fn_type_with_self_type %Count.WithSelf.N.type.3c0, %Count.facet.2b3 [symbolic]
// CHECK:STDOUT:   %impl.elem0: %.d75 = impl_witness_access %Count.lookup_impl_witness, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn: <specific function> = specific_impl_function %impl.elem0, @Count.WithSelf.N(%Count.facet.2b3) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %H.decl: %H.type = fn_decl @H [concrete = constants.%H] {
// CHECK:STDOUT:     %arity.patt.loc12_6.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc12_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc12_16.1: @H.%pattern_type.loc12_16 (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc12_16.2 (constants.%T.patt)]
// CHECK:STDOUT:     %.loc12_6.1: @H.%pattern_type.loc12_16 (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc12_16.1, %arity.patt.loc12_6.1 [symbolic = %.loc12_6.2 (constants.%.99e)]
// CHECK:STDOUT:     %t.param_patt.loc12_25.1: @H.%pattern_type.loc12_25 (%pattern_type.e36) = value_param_pattern [symbolic = %t.param_patt.loc12_25.2 (constants.%t.param_patt)]
// CHECK:STDOUT:     %t.patt.loc12_25.1: @H.%pattern_type.loc12_25 (%pattern_type.e36) = wrapper_binding_pattern t, %t.param_patt.loc12_25.1 [symbolic = %t.patt.loc12_25.2 (constants.%t.patt)]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:     %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %.loc12_44: Core.Form = init_form %i64 [concrete = constants.%.bc0]
// CHECK:STDOUT:     %arity.loc12_6.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc12_6.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc12_18.1: type = splice_block %.loc12_18.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc12_18.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc12_16.2: @H.%pack_type.loc12_16 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc12_16.1 (constants.%T)]
// CHECK:STDOUT:     %t.param: @H.%tuple.type.loc12_38.2 (%tuple.type.423) = value_param call_param0
// CHECK:STDOUT:     %.loc12_38.1: type = splice_block %.loc12_38.3 [symbolic = %tuple.type.loc12_38.2 (constants.%tuple.type.423)] {
// CHECK:STDOUT:       %.loc12_38.2: @H.%tuple.type.loc12_38.1 (%tuple.type.852) = tuple_literal (constants.%T) [symbolic = %tuple (constants.%tuple)]
// CHECK:STDOUT:       %.loc12_38.3: type = converted %.loc12_38.2, constants.%tuple.type.423 [symbolic = %tuple.type.loc12_38.2 (constants.%tuple.type.423)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %t: @H.%tuple.type.loc12_38.2 (%tuple.type.423) = wrapper_binding t, %t.param
// CHECK:STDOUT:     %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @H(%arity.loc12_6.2: Core.IntLiteral, %T.loc12_16.2: @H.%pack_type.loc12_16 (%pack_type.c29)) {
// CHECK:STDOUT:   %arity.patt.loc12_6.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc12_6.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc12_6.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc12_6.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc12_16: type = pack_type type, %arity.loc12_6.1 [symbolic = %pack_type.loc12_16 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %pattern_type.loc12_16: type = pattern_type %pack_type.loc12_16 [symbolic = %pattern_type.loc12_16 (constants.%pattern_type.fc0)]
// CHECK:STDOUT:   %T.patt.loc12_16.2: @H.%pattern_type.loc12_16 (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc12_16.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc12_16.1: @H.%pack_type.loc12_16 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc12_16.1 (constants.%T)]
// CHECK:STDOUT:   %.loc12_6.2: @H.%pattern_type.loc12_16 (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc12_16.2, %arity.patt.loc12_6.2 [symbolic = %.loc12_6.2 (constants.%.99e)]
// CHECK:STDOUT:   %.loc12_32.1: Core.IntLiteral = pack_index [symbolic = %.loc12_32.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc12_32.2: type = pack_element %T.loc12_16.1, %.loc12_32.1 [symbolic = %.loc12_32.2 (constants.%.425)]
// CHECK:STDOUT:   %tuple.type.loc12_38.1: type = tuple_type (%pack_type.loc12_16) [symbolic = %tuple.type.loc12_38.1 (constants.%tuple.type.852)]
// CHECK:STDOUT:   %tuple: @H.%tuple.type.loc12_38.1 (%tuple.type.852) = tuple_value (%T.loc12_16.1) [symbolic = %tuple (constants.%tuple)]
// CHECK:STDOUT:   %pack_type.loc12_38: type = pack_type %T.loc12_16.1, %arity.loc12_6.1 [symbolic = %pack_type.loc12_38 (constants.%pack_type.8fb)]
// CHECK:STDOUT:   %tuple.type.loc12_38.2: type = tuple_type (%pack_type.loc12_38) [symbolic = %tuple.type.loc12_38.2 (constants.%tuple.type.423)]
// CHECK:STDOUT:   %pattern_type.loc12_25: type = pattern_type %tuple.type.loc12_38.2 [symbolic = %pattern_type.loc12_25 (constants.%pattern_type.e36)]
// CHECK:STDOUT:   %t.param_patt.loc12_25.2: @H.%pattern_type.loc12_25 (%pattern_type.e36) = value_param_pattern [symbolic = %t.param_patt.loc12_25.2 (constants.%t.param_patt)]
// CHECK:STDOUT:   %t.patt.loc12_25.2: @H.%pattern_type.loc12_25 (%pattern_type.e36) = wrapper_binding_pattern t, %t.param_patt.loc12_25.2 [symbolic = %t.patt.loc12_25.2 (constants.%t.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %tuple.type.loc12_38.2 [symbolic = %require_complete (constants.%require_complete.f6f)]
// CHECK:STDOUT:   %.loc13_11.1: require_specific_def_type = require_specific_def @tuple.type.as.Count.impl(%arity.loc12_6.1, %T.loc12_16.1) [symbolic = %.loc13_11.1 (constants.%.f85)]
// CHECK:STDOUT:   %Count.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type.loc12_38.2, @Count [symbolic = %Count.lookup_impl_witness (constants.%Count.lookup_impl_witness)]
// CHECK:STDOUT:   %Count.facet.loc13_11: %Count.type = facet_value %tuple.type.loc12_38.2, (%Count.lookup_impl_witness) [symbolic = %Count.facet.loc13_11 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:   %Count.WithSelf.N.type: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.loc13_11) [symbolic = %Count.WithSelf.N.type (constants.%Count.WithSelf.N.type.3c0)]
// CHECK:STDOUT:   %.loc13_11.2: type = fn_type_with_self_type %Count.WithSelf.N.type, %Count.facet.loc13_11 [symbolic = %.loc13_11.2 (constants.%.d75)]
// CHECK:STDOUT:   %impl.elem0.loc13_11.2: @H.%.loc13_11.2 (%.d75) = impl_witness_access %Count.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc13_11.2 (constants.%impl.elem0)]
// CHECK:STDOUT:   %specific_impl_fn.loc13_11.2: <specific function> = specific_impl_function %impl.elem0.loc13_11.2, @Count.WithSelf.N(%Count.facet.loc13_11) [symbolic = %specific_impl_fn.loc13_11.2 (constants.%specific_impl_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%t.param: @H.%tuple.type.loc12_38.2 (%tuple.type.423)) -> out %return.param: %i64 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %t.ref: @H.%tuple.type.loc12_38.2 (%tuple.type.423) = name_ref t, %t
// CHECK:STDOUT:     %Count.ref: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:     %N.ref: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:     %impl.elem0.loc13_11.1: @H.%.loc13_11.2 (%.d75) = impl_witness_access constants.%Count.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc13_11.2 (constants.%impl.elem0)]
// CHECK:STDOUT:     %bound_method.loc13_11: <bound method> = bound_method %t.ref, %impl.elem0.loc13_11.1
// CHECK:STDOUT:     %Count.facet.loc13_22.1: %Count.type = facet_value constants.%tuple.type.423, (constants.%Count.lookup_impl_witness) [symbolic = %Count.facet.loc13_11 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:     %.loc13_22.1: %Count.type = converted constants.%tuple.type.423, %Count.facet.loc13_22.1 [symbolic = %Count.facet.loc13_11 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:     %Count.facet.loc13_22.2: %Count.type = facet_value constants.%tuple.type.423, (constants.%Count.lookup_impl_witness) [symbolic = %Count.facet.loc13_11 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:     %.loc13_22.2: %Count.type = converted constants.%tuple.type.423, %Count.facet.loc13_22.2 [symbolic = %Count.facet.loc13_11 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:     %specific_impl_fn.loc13_11.1: <specific function> = specific_impl_function %impl.elem0.loc13_11.1, @Count.WithSelf.N(constants.%Count.facet.2b3) [symbolic = %specific_impl_fn.loc13_11.2 (constants.%specific_impl_fn)]
// CHECK:STDOUT:     %bound_method.loc13_22: <bound method> = bound_method %t.ref, %specific_impl_fn.loc13_11.1
// CHECK:STDOUT:     %Count.WithSelf.N.call: init %i64 = call %bound_method.loc13_22(%t.ref)
// CHECK:STDOUT:     return %Count.WithSelf.N.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @H(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity.patt.loc12_6.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc12_6.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc12_16 => constants.%pack_type.c29
// CHECK:STDOUT:   %pattern_type.loc12_16 => constants.%pattern_type.fc0
// CHECK:STDOUT:   %T.patt.loc12_16.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc12_16.1 => constants.%T
// CHECK:STDOUT:   %.loc12_6.2 => constants.%.99e
// CHECK:STDOUT:   %.loc12_32.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc12_32.2 => constants.%.425
// CHECK:STDOUT:   %tuple.type.loc12_38.1 => constants.%tuple.type.852
// CHECK:STDOUT:   %tuple => constants.%tuple
// CHECK:STDOUT:   %pack_type.loc12_38 => constants.%pack_type.8fb
// CHECK:STDOUT:   %tuple.type.loc12_38.2 => constants.%tuple.type.423
// CHECK:STDOUT:   %pattern_type.loc12_25 => constants.%pattern_type.e36
// CHECK:STDOUT:   %t.param_patt.loc12_25.2 => constants.%t.param_patt
// CHECK:STDOUT:   %t.patt.loc12_25.2 => constants.%t.patt
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- self_query.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Count.assoc_type: type = assoc_entity_type @Count [concrete]
// CHECK:STDOUT:   %assoc0.71c: %Count.assoc_type = assoc_entity element0, @Count.WithSelf.%Count.WithSelf.N.decl [concrete]
// CHECK:STDOUT:   %.Self.frozen: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.fc0: type = pattern_type %pack_type.c29 [symbolic]
// CHECK:STDOUT:   %T.patt: %pattern_type.fc0 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.99e: %pattern_type.fc0 = pack_expansion_pattern %T.patt, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.425: type = pack_element %T, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.852: type = tuple_type (%pack_type.c29) [symbolic]
// CHECK:STDOUT:   %tuple: %tuple.type.852 = tuple_value (%T) [symbolic]
// CHECK:STDOUT:   %pack_type.8fb: type = pack_type %T, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.423: type = tuple_type (%pack_type.8fb) [symbolic]
// CHECK:STDOUT:   %.317: <witness> = impl_self_witness %tuple.type.423, @Count [symbolic]
// CHECK:STDOUT:   %Count.impl_witness: <witness> = impl_witness @tuple.type.as.Count.impl.%Count.impl_witness_table, @tuple.type.as.Count.impl(%arity, %T) [symbolic]
// CHECK:STDOUT:   %pattern_type.e36: type = pattern_type %tuple.type.423 [symbolic]
// CHECK:STDOUT:   %self.param_patt.280: %pattern_type.e36 = value_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt.d43: %pattern_type.e36 = wrapper_binding_pattern self, %self.param_patt.280 [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type: type = fn_type @tuple.type.as.Count.impl.N, @tuple.type.as.Count.impl(%arity, %T) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N: %tuple.type.as.Count.impl.N.type = struct_value () [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.Twice.type: type = fn_type @tuple.type.as.Count.impl.Twice, @tuple.type.as.Count.impl(%arity, %T) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.Twice: %tuple.type.as.Count.impl.Twice.type = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.f6f: <witness> = require_complete_type %tuple.type.423 [symbolic]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_7.824: %i64 = int_value 7 [concrete]
// CHECK:STDOUT:   %Count.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type.423, @Count [symbolic]
// CHECK:STDOUT:   %.f85: require_specific_def_type = require_specific_def @tuple.type.as.Count.impl(%arity, %T) [symbolic]
// CHECK:STDOUT:   %Count.facet.2b3: %Count.type = facet_value %tuple.type.423, (%Count.lookup_impl_witness) [symbolic]
// CHECK:STDOUT:   %Count.WithSelf.N.type.3c0: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.2b3) [symbolic]
// CHECK:STDOUT:   %.d75: type = fn_type_with_self_type %Count.WithSelf.N.type.3c0, %Count.facet.2b3 [symbolic]
// CHECK:STDOUT:   %impl.elem0: %.d75 = impl_witness_access %Count.lookup_impl_witness, element0 [symbolic]
// CHECK:STDOUT:   %specific_impl_fn: <specific function> = specific_impl_function %impl.elem0, @Count.WithSelf.N(%Count.facet.2b3) [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   impl_decl @tuple.type.as.Count.impl [concrete] {
// CHECK:STDOUT:     %arity.patt.loc9_14.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc9_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc9_24.1: @tuple.type.as.Count.impl.%pattern_type (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc9_24.2 (constants.%T.patt)]
// CHECK:STDOUT:     %.loc9_14.1: @tuple.type.as.Count.impl.%pattern_type (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc9_24.1, %arity.patt.loc9_14.1 [symbolic = %.loc9_14.2 (constants.%.99e)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc9_43.1: @tuple.type.as.Count.impl.%tuple.type.loc9_43.1 (%tuple.type.852) = tuple_literal (constants.%T) [symbolic = %tuple (constants.%tuple)]
// CHECK:STDOUT:     %.loc9_43.2: type = converted %.loc9_43.1, constants.%tuple.type.423 [symbolic = %tuple.type.loc9_43.2 (constants.%tuple.type.423)]
// CHECK:STDOUT:     %Count.ref: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:     %arity.loc9_14.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc9_14.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc9_26.1: type = splice_block %.loc9_26.2 [concrete = type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen]
// CHECK:STDOUT:       %.loc9_26.2: type = type_literal type [concrete = type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc9_24.2: @tuple.type.as.Count.impl.%pack_type.loc9_24 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc9_24.1 (constants.%T)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc9: <witness> = impl_self_witness @tuple.type.as.Count.impl.%.loc9_43.2, @Count [symbolic = @tuple.type.as.Count.impl.%.loc9_54 (constants.%.317)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic impl @tuple.type.as.Count.impl(%arity.loc9_14.2: Core.IntLiteral, %T.loc9_24.2: @tuple.type.as.Count.impl.%pack_type.loc9_24 (%pack_type.c29)) {
// CHECK:STDOUT:   %arity.patt.loc9_14.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc9_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc9_14.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc9_14.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc9_24: type = pack_type type, %arity.loc9_14.1 [symbolic = %pack_type.loc9_24 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type.loc9_24 [symbolic = %pattern_type (constants.%pattern_type.fc0)]
// CHECK:STDOUT:   %T.patt.loc9_24.2: @tuple.type.as.Count.impl.%pattern_type (%pattern_type.fc0) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc9_24.2 (constants.%T.patt)]
// CHECK:STDOUT:   %T.loc9_24.1: @tuple.type.as.Count.impl.%pack_type.loc9_24 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T.loc9_24.1 (constants.%T)]
// CHECK:STDOUT:   %.loc9_14.2: @tuple.type.as.Count.impl.%pattern_type (%pattern_type.fc0) = pack_expansion_pattern %T.patt.loc9_24.2, %arity.patt.loc9_14.2 [symbolic = %.loc9_14.2 (constants.%.99e)]
// CHECK:STDOUT:   %.loc9_37.1: Core.IntLiteral = pack_index [symbolic = %.loc9_37.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc9_37.2: type = pack_element %T.loc9_24.1, %.loc9_37.1 [symbolic = %.loc9_37.2 (constants.%.425)]
// CHECK:STDOUT:   %tuple.type.loc9_43.1: type = tuple_type (%pack_type.loc9_24) [symbolic = %tuple.type.loc9_43.1 (constants.%tuple.type.852)]
// CHECK:STDOUT:   %tuple: @tuple.type.as.Count.impl.%tuple.type.loc9_43.1 (%tuple.type.852) = tuple_value (%T.loc9_24.1) [symbolic = %tuple (constants.%tuple)]
// CHECK:STDOUT:   %pack_type.loc9_43: type = pack_type %T.loc9_24.1, %arity.loc9_14.1 [symbolic = %pack_type.loc9_43 (constants.%pack_type.8fb)]
// CHECK:STDOUT:   %tuple.type.loc9_43.2: type = tuple_type (%pack_type.loc9_43) [symbolic = %tuple.type.loc9_43.2 (constants.%tuple.type.423)]
// CHECK:STDOUT:   %.loc9_54: <witness> = impl_self_witness %tuple.type.loc9_43.2, @Count [symbolic = %.loc9_54 (constants.%.317)]
// CHECK:STDOUT:   %Count.impl_witness.loc9_54.2: <witness> = impl_witness %Count.impl_witness_table, @tuple.type.as.Count.impl(%arity.loc9_14.1, %T.loc9_24.1) [symbolic = %Count.impl_witness.loc9_54.2 (constants.%Count.impl_witness)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type: type = fn_type @tuple.type.as.Count.impl.N, @tuple.type.as.Count.impl(%arity.loc9_14.1, %T.loc9_24.1) [symbolic = %tuple.type.as.Count.impl.N.type (constants.%tuple.type.as.Count.impl.N.type)]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N: @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.N.type (%tuple.type.as.Count.impl.N.type) = struct_value () [symbolic = %tuple.type.as.Count.impl.N (constants.%tuple.type.as.Count.impl.N)]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.Twice.type: type = fn_type @tuple.type.as.Count.impl.Twice, @tuple.type.as.Count.impl(%arity.loc9_14.1, %T.loc9_24.1) [symbolic = %tuple.type.as.Count.impl.Twice.type (constants.%tuple.type.as.Count.impl.Twice.type)]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.Twice: @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.Twice.type (%tuple.type.as.Count.impl.Twice.type) = struct_value () [symbolic = %tuple.type.as.Count.impl.Twice (constants.%tuple.type.as.Count.impl.Twice)]
// CHECK:STDOUT:
// CHECK:STDOUT:   impl: %.loc9_43.2 as %Count.ref {
// CHECK:STDOUT:     %tuple.type.as.Count.impl.N.decl: @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.N.type (%tuple.type.as.Count.impl.N.type) = fn_decl @tuple.type.as.Count.impl.N [symbolic = @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.N (constants.%tuple.type.as.Count.impl.N)] {
// CHECK:STDOUT:       %self.param_patt.loc10_15.1: @tuple.type.as.Count.impl.N.%pattern_type (%pattern_type.e36) = value_param_pattern [symbolic = %self.param_patt.loc10_15.2 (constants.%self.param_patt.280)]
// CHECK:STDOUT:       %self.patt.loc10_15.1: @tuple.type.as.Count.impl.N.%pattern_type (%pattern_type.e36) = wrapper_binding_pattern self, %self.param_patt.loc10_15.1 [symbolic = %self.patt.loc10_15.2 (constants.%self.patt.d43)]
// CHECK:STDOUT:       %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:       %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %.loc10_24: Core.Form = init_form %i64 [concrete = constants.%.bc0]
// CHECK:STDOUT:       %self.param: @tuple.type.as.Count.impl.N.%tuple.type (%tuple.type.423) = value_param call_param0
// CHECK:STDOUT:       %Self.ref: type = name_ref Self, @tuple.type.as.Count.impl.%.loc9_43.2 [symbolic = %tuple.type (constants.%tuple.type.423)]
// CHECK:STDOUT:       %self: @tuple.type.as.Count.impl.N.%tuple.type (%tuple.type.423) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:       %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %tuple.type.as.Count.impl.Twice.decl: @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.Twice.type (%tuple.type.as.Count.impl.Twice.type) = fn_decl @tuple.type.as.Count.impl.Twice [symbolic = @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.Twice (constants.%tuple.type.as.Count.impl.Twice)] {
// CHECK:STDOUT:       %self.param_patt.loc11_12.1: @tuple.type.as.Count.impl.Twice.%pattern_type (%pattern_type.e36) = value_param_pattern [symbolic = %self.param_patt.loc11_12.2 (constants.%self.param_patt.280)]
// CHECK:STDOUT:       %self.patt.loc11_12.1: @tuple.type.as.Count.impl.Twice.%pattern_type (%pattern_type.e36) = wrapper_binding_pattern self, %self.param_patt.loc11_12.1 [symbolic = %self.patt.loc11_12.2 (constants.%self.patt.d43)]
// CHECK:STDOUT:       %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:       %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %i64: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %.loc11_21: Core.Form = init_form %i64 [concrete = constants.%.bc0]
// CHECK:STDOUT:       %self.param: @tuple.type.as.Count.impl.Twice.%tuple.type (%tuple.type.423) = value_param call_param0
// CHECK:STDOUT:       %Self.ref: type = name_ref Self, @tuple.type.as.Count.impl.%.loc9_43.2 [symbolic = %tuple.type (constants.%tuple.type.423)]
// CHECK:STDOUT:       %self: @tuple.type.as.Count.impl.Twice.%tuple.type (%tuple.type.423) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:       %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Count.impl_witness_table = impl_witness_table (%tuple.type.as.Count.impl.N.decl, %tuple.type.as.Count.impl.Twice.decl), @tuple.type.as.Count.impl [concrete]
// CHECK:STDOUT:     %Count.impl_witness.loc9_54.1: <witness> = impl_witness %Count.impl_witness_table, @tuple.type.as.Count.impl(constants.%arity, constants.%T) [symbolic = %Count.impl_witness.loc9_54.2 (constants.%Count.impl_witness)]
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .N = %tuple.type.as.Count.impl.N.decl
// CHECK:STDOUT:     .Twice = %tuple.type.as.Count.impl.Twice.decl
// CHECK:STDOUT:     .Count = <poisoned>
// CHECK:STDOUT:     extend %Count.ref
// CHECK:STDOUT:     witness = %Count.impl_witness.loc9_54.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @tuple.type.as.Count.impl.N(@tuple.type.as.Count.impl.%arity.loc9_14.2: Core.IntLiteral, @tuple.type.as.Count.impl.%T.loc9_24.2: @tuple.type.as.Count.impl.%pack_type.loc9_24 (%pack_type.c29)) {
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc10_15.1: type = pack_type type, %arity [symbolic = %pack_type.loc10_15.1 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %T: @tuple.type.as.Count.impl.N.%pack_type.loc10_15.1 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T (constants.%T)]
// CHECK:STDOUT:   %pack_type.loc10_15.2: type = pack_type %T, %arity [symbolic = %pack_type.loc10_15.2 (constants.%pack_type.8fb)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%pack_type.loc10_15.2) [symbolic = %tuple.type (constants.%tuple.type.423)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %tuple.type [symbolic = %pattern_type (constants.%pattern_type.e36)]
// CHECK:STDOUT:   %self.param_patt.loc10_15.2: @tuple.type.as.Count.impl.N.%pattern_type (%pattern_type.e36) = value_param_pattern [symbolic = %self.param_patt.loc10_15.2 (constants.%self.param_patt.280)]
// CHECK:STDOUT:   %self.patt.loc10_15.2: @tuple.type.as.Count.impl.N.%pattern_type (%pattern_type.e36) = wrapper_binding_pattern self, %self.param_patt.loc10_15.2 [symbolic = %self.patt.loc10_15.2 (constants.%self.patt.d43)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %tuple.type [symbolic = %require_complete (constants.%require_complete.f6f)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @tuple.type.as.Count.impl.N.%tuple.type (%tuple.type.423)) -> out %return.param: %i64 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:     %impl.elem0: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc10_38.1: <bound method> = bound_method %int_7, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:     %specific_fn: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc10_38.2: <bound method> = bound_method %int_7, %specific_fn [concrete = constants.%bound_method]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc10_38.2(%int_7) [concrete = constants.%int_7.824]
// CHECK:STDOUT:     %.loc10_38: init %i64 = converted %int_7, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_7.824]
// CHECK:STDOUT:     return %.loc10_38
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @tuple.type.as.Count.impl.Twice(@tuple.type.as.Count.impl.%arity.loc9_14.2: Core.IntLiteral, @tuple.type.as.Count.impl.%T.loc9_24.2: @tuple.type.as.Count.impl.%pack_type.loc9_24 (%pack_type.c29)) {
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc11_12.1: type = pack_type type, %arity [symbolic = %pack_type.loc11_12.1 (constants.%pack_type.c29)]
// CHECK:STDOUT:   %T: @tuple.type.as.Count.impl.Twice.%pack_type.loc11_12.1 (%pack_type.c29) = symbolic_binding T, 1 [symbolic = %T (constants.%T)]
// CHECK:STDOUT:   %pack_type.loc11_12.2: type = pack_type %T, %arity [symbolic = %pack_type.loc11_12.2 (constants.%pack_type.8fb)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%pack_type.loc11_12.2) [symbolic = %tuple.type (constants.%tuple.type.423)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %tuple.type [symbolic = %pattern_type (constants.%pattern_type.e36)]
// CHECK:STDOUT:   %self.param_patt.loc11_12.2: @tuple.type.as.Count.impl.Twice.%pattern_type (%pattern_type.e36) = value_param_pattern [symbolic = %self.param_patt.loc11_12.2 (constants.%self.param_patt.280)]
// CHECK:STDOUT:   %self.patt.loc11_12.2: @tuple.type.as.Count.impl.Twice.%pattern_type (%pattern_type.e36) = wrapper_binding_pattern self, %self.param_patt.loc11_12.2 [symbolic = %self.patt.loc11_12.2 (constants.%self.patt.d43)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %tuple.type [symbolic = %require_complete (constants.%require_complete.f6f)]
// CHECK:STDOUT:   %.loc11_38.1: require_specific_def_type = require_specific_def @tuple.type.as.Count.impl(%arity, %T) [symbolic = %.loc11_38.1 (constants.%.f85)]
// CHECK:STDOUT:   %Count.lookup_impl_witness: <witness> = lookup_impl_witness %tuple.type, @Count [symbolic = %Count.lookup_impl_witness (constants.%Count.lookup_impl_witness)]
// CHECK:STDOUT:   %Count.facet.loc11_38: %Count.type = facet_value %tuple.type, (%Count.lookup_impl_witness) [symbolic = %Count.facet.loc11_38 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:   %Count.WithSelf.N.type: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.loc11_38) [symbolic = %Count.WithSelf.N.type (constants.%Count.WithSelf.N.type.3c0)]
// CHECK:STDOUT:   %.loc11_38.2: type = fn_type_with_self_type %Count.WithSelf.N.type, %Count.facet.loc11_38 [symbolic = %.loc11_38.2 (constants.%.d75)]
// CHECK:STDOUT:   %impl.elem0.loc11_38.2: @tuple.type.as.Count.impl.Twice.%.loc11_38.2 (%.d75) = impl_witness_access %Count.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc11_38.2 (constants.%impl.elem0)]
// CHECK:STDOUT:   %specific_impl_fn.loc11_38.2: <specific function> = specific_impl_function %impl.elem0.loc11_38.2, @Count.WithSelf.N(%Count.facet.loc11_38) [symbolic = %specific_impl_fn.loc11_38.2 (constants.%specific_impl_fn)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @tuple.type.as.Count.impl.Twice.%tuple.type (%tuple.type.423)) -> out %return.param: %i64 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %self.ref: @tuple.type.as.Count.impl.Twice.%tuple.type (%tuple.type.423) = name_ref self, %self
// CHECK:STDOUT:     %Count.ref: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:     %N.ref: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:     %impl.elem0.loc11_38.1: @tuple.type.as.Count.impl.Twice.%.loc11_38.2 (%.d75) = impl_witness_access constants.%Count.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc11_38.2 (constants.%impl.elem0)]
// CHECK:STDOUT:     %bound_method.loc11_38: <bound method> = bound_method %self.ref, %impl.elem0.loc11_38.1
// CHECK:STDOUT:     %Count.facet.loc11_49.1: %Count.type = facet_value constants.%tuple.type.423, (constants.%Count.lookup_impl_witness) [symbolic = %Count.facet.loc11_38 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:     %.loc11_49.1: %Count.type = converted constants.%tuple.type.423, %Count.facet.loc11_49.1 [symbolic = %Count.facet.loc11_38 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:     %Count.facet.loc11_49.2: %Count.type = facet_value constants.%tuple.type.423, (constants.%Count.lookup_impl_witness) [symbolic = %Count.facet.loc11_38 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:     %.loc11_49.2: %Count.type = converted constants.%tuple.type.423, %Count.facet.loc11_49.2 [symbolic = %Count.facet.loc11_38 (constants.%Count.facet.2b3)]
// CHECK:STDOUT:     %specific_impl_fn.loc11_38.1: <specific function> = specific_impl_function %impl.elem0.loc11_38.1, @Count.WithSelf.N(constants.%Count.facet.2b3) [symbolic = %specific_impl_fn.loc11_38.2 (constants.%specific_impl_fn)]
// CHECK:STDOUT:     %bound_method.loc11_49: <bound method> = bound_method %self.ref, %specific_impl_fn.loc11_38.1
// CHECK:STDOUT:     %Count.WithSelf.N.call: init %i64 = call %bound_method.loc11_49(%self.ref)
// CHECK:STDOUT:     return %Count.WithSelf.N.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Count.impl(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity.patt.loc9_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc9_14.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc9_24 => constants.%pack_type.c29
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.fc0
// CHECK:STDOUT:   %T.patt.loc9_24.2 => constants.%T.patt
// CHECK:STDOUT:   %T.loc9_24.1 => constants.%T
// CHECK:STDOUT:   %.loc9_14.2 => constants.%.99e
// CHECK:STDOUT:   %.loc9_37.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc9_37.2 => constants.%.425
// CHECK:STDOUT:   %tuple.type.loc9_43.1 => constants.%tuple.type.852
// CHECK:STDOUT:   %tuple => constants.%tuple
// CHECK:STDOUT:   %pack_type.loc9_43 => constants.%pack_type.8fb
// CHECK:STDOUT:   %tuple.type.loc9_43.2 => constants.%tuple.type.423
// CHECK:STDOUT:   %.loc9_54 => constants.%.317
// CHECK:STDOUT:   %Count.impl_witness.loc9_54.2 => constants.%Count.impl_witness
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type => constants.%tuple.type.as.Count.impl.N.type
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N => constants.%tuple.type.as.Count.impl.N
// CHECK:STDOUT:   %tuple.type.as.Count.impl.Twice.type => constants.%tuple.type.as.Count.impl.Twice.type
// CHECK:STDOUT:   %tuple.type.as.Count.impl.Twice => constants.%tuple.type.as.Count.impl.Twice
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Count.impl.N(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity => constants.%arity
// CHECK:STDOUT:   %pack_type.loc10_15.1 => constants.%pack_type.c29
// CHECK:STDOUT:   %T => constants.%T
// CHECK:STDOUT:   %pack_type.loc10_15.2 => constants.%pack_type.8fb
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.423
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.e36
// CHECK:STDOUT:   %self.param_patt.loc10_15.2 => constants.%self.param_patt.280
// CHECK:STDOUT:   %self.patt.loc10_15.2 => constants.%self.patt.d43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Count.impl.Twice(constants.%arity, constants.%T) {
// CHECK:STDOUT:   %arity => constants.%arity
// CHECK:STDOUT:   %pack_type.loc11_12.1 => constants.%pack_type.c29
// CHECK:STDOUT:   %T => constants.%T
// CHECK:STDOUT:   %pack_type.loc11_12.2 => constants.%pack_type.8fb
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.423
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.e36
// CHECK:STDOUT:   %self.param_patt.loc11_12.2 => constants.%self.param_patt.280
// CHECK:STDOUT:   %self.patt.loc11_12.2 => constants.%self.patt.d43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- use.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %tuple.type.6e9: type = tuple_type (%i64, bool, %i64) [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %Self: %Count.type = symbolic_binding Self, 0 [symbolic]
// CHECK:STDOUT:   %Count.WithSelf.N.type.905: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Self) [symbolic]
// CHECK:STDOUT:   %Count.WithSelf.N.a85: %Count.WithSelf.N.type.905 = struct_value () [symbolic]
// CHECK:STDOUT:   %Count.assoc_type: type = assoc_entity_type @Count [concrete]
// CHECK:STDOUT:   %assoc0: %Count.assoc_type = assoc_entity element0, imports.%Main.import_ref.6c5 [concrete]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.c29: type = pack_type type, %arity [symbolic]
// CHECK:STDOUT:   %T: %pack_type.c29 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.478: type = fn_type @tuple.type.as.Count.impl.N, @tuple.type.as.Count.impl(%arity, %T) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.b04: %tuple.type.as.Count.impl.N.type.478 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %pack_type.043: type = pack_type type, %int_3 [concrete]
// CHECK:STDOUT:   %.18a: %pack_type.043 = pack_value (%i64, bool, %i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.195: <witness> = impl_witness imports.%Count.impl_witness_table, @tuple.type.as.Count.impl(%int_3, %.18a) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.cd9: type = fn_type @tuple.type.as.Count.impl.N, @tuple.type.as.Count.impl(%int_3, %.18a) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.aac: %tuple.type.as.Count.impl.N.type.cd9 = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet: %Count.type = facet_value %tuple.type.6e9, (%Count.impl_witness.195) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.9a3: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet) [concrete]
// CHECK:STDOUT:   %.322: type = fn_type_with_self_type %Count.WithSelf.N.type.9a3, %Count.facet [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn: <specific function> = specific_function %tuple.type.as.Count.impl.N.aac, @tuple.type.as.Count.impl.N(%int_3, %.18a) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Main.Count: type = import_ref Main//lib, Count, loaded [concrete = constants.%Count.type]
// CHECK:STDOUT:   %Main.import_ref.26b: %Count.assoc_type = import_ref Main//lib, loc4_20, loaded [concrete = constants.%assoc0]
// CHECK:STDOUT:   %Main.import_ref.6c5: @Count.WithSelf.%Count.WithSelf.N.type (%Count.WithSelf.N.type.905) = import_ref Main//lib, loc4_20, loaded [symbolic = @Count.WithSelf.%Count.WithSelf.N (constants.%Count.WithSelf.N.a85)]
// CHECK:STDOUT:   %Main.import_ref.739: @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.N.type (%tuple.type.as.Count.impl.N.type.478) = import_ref Main//lib, loc8_28, loaded [symbolic = @tuple.type.as.Count.impl.%tuple.type.as.Count.impl.N (constants.%tuple.type.as.Count.impl.N.b04)]
// CHECK:STDOUT:   %Count.impl_witness_table = impl_witness_table (%Main.import_ref.739), @tuple.type.as.Count.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%t.param: %tuple.type.6e9) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %t.ref: %tuple.type.6e9 = name_ref t, %t
// CHECK:STDOUT:   %Count.ref: type = name_ref Count, imports.%Main.Count [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref: %Count.assoc_type = name_ref N, imports.%Main.import_ref.26b [concrete = constants.%assoc0]
// CHECK:STDOUT:   %impl.elem0: %.322 = impl_witness_access constants.%Count.impl_witness.195, element0 [concrete = constants.%tuple.type.as.Count.impl.N.aac]
// CHECK:STDOUT:   %bound_method.loc7_11: <bound method> = bound_method %t.ref, %impl.elem0
// CHECK:STDOUT:   %int_3.loc7_22.1: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:   %.loc7_22.1: %pack_type.043 = pack_value (constants.%i64, bool, constants.%i64) [concrete = constants.%.18a]
// CHECK:STDOUT:   %int_3.loc7_22.2: Core.IntLiteral = int_value 3 [concrete = constants.%int_3]
// CHECK:STDOUT:   %.loc7_22.2: %pack_type.043 = pack_value (constants.%i64, bool, constants.%i64) [concrete = constants.%.18a]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @tuple.type.as.Count.impl.N(constants.%int_3, constants.%.18a) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_22: <bound method> = bound_method %t.ref, %specific_fn
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call: init %i64 = call %bound_method.loc7_22(%t.ref)
// CHECK:STDOUT:   return %tuple.type.as.Count.impl.N.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- rank.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Add.type: type = fn_type @Add [concrete]
// CHECK:STDOUT:   %Add: %Add.type = struct_value () [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %Count.assoc_type: type = assoc_entity_type @Count [concrete]
// CHECK:STDOUT:   %assoc0.71c: %Count.assoc_type = assoc_entity element0, @Count.WithSelf.%Count.WithSelf.N.decl [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %tuple.type.f41: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.6e9: type = tuple_type (%i64, bool, %i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.852: <witness> = impl_witness @T.as.Count.impl.%Count.impl_witness_table, @T.as.Count.impl(%i64) [concrete]
// CHECK:STDOUT:   %T.as.Count.impl.N.type.26e: type = fn_type @T.as.Count.impl.N, @T.as.Count.impl(%i64) [concrete]
// CHECK:STDOUT:   %T.as.Count.impl.N.53b: %T.as.Count.impl.N.type.26e = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.7b8: %Count.type = facet_value %i64, (%Count.impl_witness.852) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.2b0: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.7b8) [concrete]
// CHECK:STDOUT:   %.468: type = fn_type_with_self_type %Count.WithSelf.N.type.2b0, %Count.facet.7b8 [concrete]
// CHECK:STDOUT:   %T.as.Count.impl.N.specific_fn: <specific function> = specific_function %T.as.Count.impl.N.53b, @T.as.Count.impl.N(%i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.0b8: <witness> = impl_witness @tuple.type.as.Count.impl.28b.%Count.impl_witness_table, @tuple.type.as.Count.impl.28b(%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.8ec: type = fn_type @tuple.type.as.Count.impl.N.loc18, @tuple.type.as.Count.impl.28b(%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.8b0: %tuple.type.as.Count.impl.N.type.8ec = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.c96: %Count.type = facet_value %tuple.type.f41, (%Count.impl_witness.0b8) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.4f0: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.c96) [concrete]
// CHECK:STDOUT:   %.639: type = fn_type_with_self_type %Count.WithSelf.N.type.4f0, %Count.facet.c96 [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.d3c: <specific function> = specific_function %tuple.type.as.Count.impl.N.8b0, @tuple.type.as.Count.impl.N.loc18(%i64, bool) [concrete]
// CHECK:STDOUT:   %pack_type.043: type = pack_type type, %int_3.1ba [concrete]
// CHECK:STDOUT:   %.18a: %pack_type.043 = pack_value (%i64, bool, %i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.64e: <witness> = impl_witness @tuple.type.as.Count.impl.653.%Count.impl_witness_table, @tuple.type.as.Count.impl.653(%int_3.1ba, %.18a) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.f91: type = fn_type @tuple.type.as.Count.impl.N.loc14, @tuple.type.as.Count.impl.653(%int_3.1ba, %.18a) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.5f1: %tuple.type.as.Count.impl.N.type.f91 = struct_value () [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Count.facet.3e2: %Count.type = facet_value %tuple.type.6e9, (%Count.impl_witness.64e) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.c2c: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.3e2) [concrete]
// CHECK:STDOUT:   %.c02: type = fn_type_with_self_type %Count.WithSelf.N.type.c2c, %Count.facet.3e2 [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.d6f: <specific function> = specific_function %tuple.type.as.Count.impl.N.5f1, @tuple.type.as.Count.impl.N.loc14(%int_3.1ba, %.18a) [concrete]
// CHECK:STDOUT:   %pack_type.28d: type = pack_type type, %int_0 [concrete]
// CHECK:STDOUT:   %.d3f: %pack_type.28d = pack_value () [concrete]
// CHECK:STDOUT:   %Count.impl_witness.f33: <witness> = impl_witness @tuple.type.as.Count.impl.653.%Count.impl_witness_table, @tuple.type.as.Count.impl.653(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.886: type = fn_type @tuple.type.as.Count.impl.N.loc14, @tuple.type.as.Count.impl.653(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.d02: %tuple.type.as.Count.impl.N.type.886 = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.70c: %Count.type = facet_value %empty_tuple.type, (%Count.impl_witness.f33) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.20e: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.70c) [concrete]
// CHECK:STDOUT:   %.91f: type = fn_type_with_self_type %Count.WithSelf.N.type.20e, %Count.facet.70c [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.a0a: <specific function> = specific_function %tuple.type.as.Count.impl.N.d02, @tuple.type.as.Count.impl.N.loc14(%int_0, %.d3f) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%x.param: %i64, %p.param: %tuple.type.f41, %t.param: %tuple.type.6e9, %e.param: %empty_tuple.type) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Add.ref.loc23_10: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %Add.ref.loc23_14: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %Add.ref.loc23_18: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %x.ref: %i64 = name_ref x, %x
// CHECK:STDOUT:   %Count.ref.loc23_25: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc23_30: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc23_23: %.468 = impl_witness_access constants.%Count.impl_witness.852, element0 [concrete = constants.%T.as.Count.impl.N.53b]
// CHECK:STDOUT:   %bound_method.loc23_23: <bound method> = bound_method %x.ref, %impl.elem0.loc23_23
// CHECK:STDOUT:   %specific_fn.loc23_23: <specific function> = specific_function %impl.elem0.loc23_23, @T.as.Count.impl.N(constants.%i64) [concrete = constants.%T.as.Count.impl.N.specific_fn]
// CHECK:STDOUT:   %bound_method.loc23_34: <bound method> = bound_method %x.ref, %specific_fn.loc23_23
// CHECK:STDOUT:   %T.as.Count.impl.N.call: init %i64 = call %bound_method.loc23_34(%x.ref)
// CHECK:STDOUT:   %p.ref: %tuple.type.f41 = name_ref p, %p
// CHECK:STDOUT:   %Count.ref.loc23_40: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc23_45: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc23_38: %.639 = impl_witness_access constants.%Count.impl_witness.0b8, element0 [concrete = constants.%tuple.type.as.Count.impl.N.8b0]
// CHECK:STDOUT:   %bound_method.loc23_38: <bound method> = bound_method %p.ref, %impl.elem0.loc23_38
// CHECK:STDOUT:   %specific_fn.loc23_38: <specific function> = specific_function %impl.elem0.loc23_38, @tuple.type.as.Count.impl.N.loc18(constants.%i64, bool) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.d3c]
// CHECK:STDOUT:   %bound_method.loc23_49: <bound method> = bound_method %p.ref, %specific_fn.loc23_38
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc23_49: init %i64 = call %bound_method.loc23_49(%p.ref)
// CHECK:STDOUT:   %.loc23_34.1: %i64 = value_of_initializer %T.as.Count.impl.N.call
// CHECK:STDOUT:   %.loc23_34.2: %i64 = converted %T.as.Count.impl.N.call, %.loc23_34.1
// CHECK:STDOUT:   %.loc23_49.1: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc23_49
// CHECK:STDOUT:   %.loc23_49.2: %i64 = converted %tuple.type.as.Count.impl.N.call.loc23_49, %.loc23_49.1
// CHECK:STDOUT:   %Add.call.loc23_50: init %i64 = call %Add.ref.loc23_18(%.loc23_34.2, %.loc23_49.2)
// CHECK:STDOUT:   %t.ref: %tuple.type.6e9 = name_ref t, %t
// CHECK:STDOUT:   %Count.ref.loc23_56: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc23_61: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc23_54: %.c02 = impl_witness_access constants.%Count.impl_witness.64e, element0 [concrete = constants.%tuple.type.as.Count.impl.N.5f1]
// CHECK:STDOUT:   %bound_method.loc23_54: <bound method> = bound_method %t.ref, %impl.elem0.loc23_54
// CHECK:STDOUT:   %int_3.loc23_65.1: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc23_65.1: %pack_type.043 = pack_value (constants.%i64, bool, constants.%i64) [concrete = constants.%.18a]
// CHECK:STDOUT:   %int_3.loc23_65.2: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc23_65.2: %pack_type.043 = pack_value (constants.%i64, bool, constants.%i64) [concrete = constants.%.18a]
// CHECK:STDOUT:   %specific_fn.loc23_54: <specific function> = specific_function %impl.elem0.loc23_54, @tuple.type.as.Count.impl.N.loc14(constants.%int_3.1ba, constants.%.18a) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.d6f]
// CHECK:STDOUT:   %bound_method.loc23_65: <bound method> = bound_method %t.ref, %specific_fn.loc23_54
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc23_65: init %i64 = call %bound_method.loc23_65(%t.ref)
// CHECK:STDOUT:   %.loc23_50.1: %i64 = value_of_initializer %Add.call.loc23_50
// CHECK:STDOUT:   %.loc23_50.2: %i64 = converted %Add.call.loc23_50, %.loc23_50.1
// CHECK:STDOUT:   %.loc23_65.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc23_65
// CHECK:STDOUT:   %.loc23_65.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc23_65, %.loc23_65.3
// CHECK:STDOUT:   %Add.call.loc23_66: init %i64 = call %Add.ref.loc23_14(%.loc23_50.2, %.loc23_65.4)
// CHECK:STDOUT:   %e.ref: %empty_tuple.type = name_ref e, %e
// CHECK:STDOUT:   %Count.ref.loc24: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc24: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc24: %.91f = impl_witness_access constants.%Count.impl_witness.f33, element0 [concrete = constants.%tuple.type.as.Count.impl.N.d02]
// CHECK:STDOUT:   %bound_method.loc24_15: <bound method> = bound_method %e.ref, %impl.elem0.loc24
// CHECK:STDOUT:   %int_0.loc24_26.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc24_26.1: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %int_0.loc24_26.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc24_26.2: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %specific_fn.loc24: <specific function> = specific_function %impl.elem0.loc24, @tuple.type.as.Count.impl.N.loc14(constants.%int_0, constants.%.d3f) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.a0a]
// CHECK:STDOUT:   %bound_method.loc24_26: <bound method> = bound_method %e.ref, %specific_fn.loc24
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc24: init %i64 = call %bound_method.loc24_26(%e.ref)
// CHECK:STDOUT:   %.loc23_66.1: %i64 = value_of_initializer %Add.call.loc23_66
// CHECK:STDOUT:   %.loc23_66.2: %i64 = converted %Add.call.loc23_66, %.loc23_66.1
// CHECK:STDOUT:   %.loc24_26.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc24
// CHECK:STDOUT:   %.loc24_26.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc24, %.loc24_26.3
// CHECK:STDOUT:   %Add.call.loc24: init %i64 = call %Add.ref.loc23_10(%.loc23_66.2, %.loc24_26.4)
// CHECK:STDOUT:   return %Add.call.loc24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- rank_reversed.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Add.type: type = fn_type @Add [concrete]
// CHECK:STDOUT:   %Add: %Add.type = struct_value () [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %Count.assoc_type: type = assoc_entity_type @Count [concrete]
// CHECK:STDOUT:   %assoc0.71c: %Count.assoc_type = assoc_entity element0, @Count.WithSelf.%Count.WithSelf.N.decl [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %tuple.type.f41: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.6e9: type = tuple_type (%i64, bool, %i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.852: <witness> = impl_witness @T.as.Count.impl.%Count.impl_witness_table, @T.as.Count.impl(%i64) [concrete]
// CHECK:STDOUT:   %T.as.Count.impl.N.type.26e: type = fn_type @T.as.Count.impl.N, @T.as.Count.impl(%i64) [concrete]
// CHECK:STDOUT:   %T.as.Count.impl.N.53b: %T.as.Count.impl.N.type.26e = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.7b8: %Count.type = facet_value %i64, (%Count.impl_witness.852) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.2b0: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.7b8) [concrete]
// CHECK:STDOUT:   %.468: type = fn_type_with_self_type %Count.WithSelf.N.type.2b0, %Count.facet.7b8 [concrete]
// CHECK:STDOUT:   %T.as.Count.impl.N.specific_fn: <specific function> = specific_function %T.as.Count.impl.N.53b, @T.as.Count.impl.N(%i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.0b8: <witness> = impl_witness @tuple.type.as.Count.impl.28b.%Count.impl_witness_table, @tuple.type.as.Count.impl.28b(%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.8ec: type = fn_type @tuple.type.as.Count.impl.N.loc10, @tuple.type.as.Count.impl.28b(%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.8b0: %tuple.type.as.Count.impl.N.type.8ec = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.c96: %Count.type = facet_value %tuple.type.f41, (%Count.impl_witness.0b8) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.4f0: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.c96) [concrete]
// CHECK:STDOUT:   %.639: type = fn_type_with_self_type %Count.WithSelf.N.type.4f0, %Count.facet.c96 [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.d3c: <specific function> = specific_function %tuple.type.as.Count.impl.N.8b0, @tuple.type.as.Count.impl.N.loc10(%i64, bool) [concrete]
// CHECK:STDOUT:   %pack_type.043: type = pack_type type, %int_3.1ba [concrete]
// CHECK:STDOUT:   %.18a: %pack_type.043 = pack_value (%i64, bool, %i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.64e: <witness> = impl_witness @tuple.type.as.Count.impl.653.%Count.impl_witness_table, @tuple.type.as.Count.impl.653(%int_3.1ba, %.18a) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.f91: type = fn_type @tuple.type.as.Count.impl.N.loc14, @tuple.type.as.Count.impl.653(%int_3.1ba, %.18a) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.5f1: %tuple.type.as.Count.impl.N.type.f91 = struct_value () [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Count.facet.3e2: %Count.type = facet_value %tuple.type.6e9, (%Count.impl_witness.64e) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.c2c: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.3e2) [concrete]
// CHECK:STDOUT:   %.c02: type = fn_type_with_self_type %Count.WithSelf.N.type.c2c, %Count.facet.3e2 [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.d6f: <specific function> = specific_function %tuple.type.as.Count.impl.N.5f1, @tuple.type.as.Count.impl.N.loc14(%int_3.1ba, %.18a) [concrete]
// CHECK:STDOUT:   %pack_type.28d: type = pack_type type, %int_0 [concrete]
// CHECK:STDOUT:   %.d3f: %pack_type.28d = pack_value () [concrete]
// CHECK:STDOUT:   %Count.impl_witness.f33: <witness> = impl_witness @tuple.type.as.Count.impl.653.%Count.impl_witness_table, @tuple.type.as.Count.impl.653(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.886: type = fn_type @tuple.type.as.Count.impl.N.loc14, @tuple.type.as.Count.impl.653(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.d02: %tuple.type.as.Count.impl.N.type.886 = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.70c: %Count.type = facet_value %empty_tuple.type, (%Count.impl_witness.f33) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.20e: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.70c) [concrete]
// CHECK:STDOUT:   %.91f: type = fn_type_with_self_type %Count.WithSelf.N.type.20e, %Count.facet.70c [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.a0a: <specific function> = specific_function %tuple.type.as.Count.impl.N.d02, @tuple.type.as.Count.impl.N.loc14(%int_0, %.d3f) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%x.param: %i64, %p.param: %tuple.type.f41, %t.param: %tuple.type.6e9, %e.param: %empty_tuple.type) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Add.ref.loc23_10: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %Add.ref.loc23_14: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %Add.ref.loc23_18: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %x.ref: %i64 = name_ref x, %x
// CHECK:STDOUT:   %Count.ref.loc23_25: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc23_30: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc23_23: %.468 = impl_witness_access constants.%Count.impl_witness.852, element0 [concrete = constants.%T.as.Count.impl.N.53b]
// CHECK:STDOUT:   %bound_method.loc23_23: <bound method> = bound_method %x.ref, %impl.elem0.loc23_23
// CHECK:STDOUT:   %specific_fn.loc23_23: <specific function> = specific_function %impl.elem0.loc23_23, @T.as.Count.impl.N(constants.%i64) [concrete = constants.%T.as.Count.impl.N.specific_fn]
// CHECK:STDOUT:   %bound_method.loc23_34: <bound method> = bound_method %x.ref, %specific_fn.loc23_23
// CHECK:STDOUT:   %T.as.Count.impl.N.call: init %i64 = call %bound_method.loc23_34(%x.ref)
// CHECK:STDOUT:   %p.ref: %tuple.type.f41 = name_ref p, %p
// CHECK:STDOUT:   %Count.ref.loc23_40: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc23_45: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc23_38: %.639 = impl_witness_access constants.%Count.impl_witness.0b8, element0 [concrete = constants.%tuple.type.as.Count.impl.N.8b0]
// CHECK:STDOUT:   %bound_method.loc23_38: <bound method> = bound_method %p.ref, %impl.elem0.loc23_38
// CHECK:STDOUT:   %specific_fn.loc23_38: <specific function> = specific_function %impl.elem0.loc23_38, @tuple.type.as.Count.impl.N.loc10(constants.%i64, bool) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.d3c]
// CHECK:STDOUT:   %bound_method.loc23_49: <bound method> = bound_method %p.ref, %specific_fn.loc23_38
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc23_49: init %i64 = call %bound_method.loc23_49(%p.ref)
// CHECK:STDOUT:   %.loc23_34.1: %i64 = value_of_initializer %T.as.Count.impl.N.call
// CHECK:STDOUT:   %.loc23_34.2: %i64 = converted %T.as.Count.impl.N.call, %.loc23_34.1
// CHECK:STDOUT:   %.loc23_49.1: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc23_49
// CHECK:STDOUT:   %.loc23_49.2: %i64 = converted %tuple.type.as.Count.impl.N.call.loc23_49, %.loc23_49.1
// CHECK:STDOUT:   %Add.call.loc23_50: init %i64 = call %Add.ref.loc23_18(%.loc23_34.2, %.loc23_49.2)
// CHECK:STDOUT:   %t.ref: %tuple.type.6e9 = name_ref t, %t
// CHECK:STDOUT:   %Count.ref.loc23_56: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc23_61: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc23_54: %.c02 = impl_witness_access constants.%Count.impl_witness.64e, element0 [concrete = constants.%tuple.type.as.Count.impl.N.5f1]
// CHECK:STDOUT:   %bound_method.loc23_54: <bound method> = bound_method %t.ref, %impl.elem0.loc23_54
// CHECK:STDOUT:   %int_3.loc23_65.1: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc23_65.1: %pack_type.043 = pack_value (constants.%i64, bool, constants.%i64) [concrete = constants.%.18a]
// CHECK:STDOUT:   %int_3.loc23_65.2: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %.loc23_65.2: %pack_type.043 = pack_value (constants.%i64, bool, constants.%i64) [concrete = constants.%.18a]
// CHECK:STDOUT:   %specific_fn.loc23_54: <specific function> = specific_function %impl.elem0.loc23_54, @tuple.type.as.Count.impl.N.loc14(constants.%int_3.1ba, constants.%.18a) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.d6f]
// CHECK:STDOUT:   %bound_method.loc23_65: <bound method> = bound_method %t.ref, %specific_fn.loc23_54
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc23_65: init %i64 = call %bound_method.loc23_65(%t.ref)
// CHECK:STDOUT:   %.loc23_50.1: %i64 = value_of_initializer %Add.call.loc23_50
// CHECK:STDOUT:   %.loc23_50.2: %i64 = converted %Add.call.loc23_50, %.loc23_50.1
// CHECK:STDOUT:   %.loc23_65.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc23_65
// CHECK:STDOUT:   %.loc23_65.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc23_65, %.loc23_65.3
// CHECK:STDOUT:   %Add.call.loc23_66: init %i64 = call %Add.ref.loc23_14(%.loc23_50.2, %.loc23_65.4)
// CHECK:STDOUT:   %e.ref: %empty_tuple.type = name_ref e, %e
// CHECK:STDOUT:   %Count.ref.loc24: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc24: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc24: %.91f = impl_witness_access constants.%Count.impl_witness.f33, element0 [concrete = constants.%tuple.type.as.Count.impl.N.d02]
// CHECK:STDOUT:   %bound_method.loc24_15: <bound method> = bound_method %e.ref, %impl.elem0.loc24
// CHECK:STDOUT:   %int_0.loc24_26.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc24_26.1: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %int_0.loc24_26.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc24_26.2: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %specific_fn.loc24: <specific function> = specific_function %impl.elem0.loc24, @tuple.type.as.Count.impl.N.loc14(constants.%int_0, constants.%.d3f) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.a0a]
// CHECK:STDOUT:   %bound_method.loc24_26: <bound method> = bound_method %e.ref, %specific_fn.loc24
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc24: init %i64 = call %bound_method.loc24_26(%e.ref)
// CHECK:STDOUT:   %.loc23_66.1: %i64 = value_of_initializer %Add.call.loc23_66
// CHECK:STDOUT:   %.loc23_66.2: %i64 = converted %Add.call.loc23_66, %.loc23_66.1
// CHECK:STDOUT:   %.loc24_26.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc24
// CHECK:STDOUT:   %.loc24_26.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc24, %.loc24_26.3
// CHECK:STDOUT:   %Add.call.loc24: init %i64 = call %Add.ref.loc23_10(%.loc23_66.2, %.loc24_26.4)
// CHECK:STDOUT:   return %Add.call.loc24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- rank_elements_after.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Add.type: type = fn_type @Add [concrete]
// CHECK:STDOUT:   %Add: %Add.type = struct_value () [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %Count.assoc_type: type = assoc_entity_type @Count [concrete]
// CHECK:STDOUT:   %assoc0.71c: %Count.assoc_type = assoc_entity element0, @Count.WithSelf.%Count.WithSelf.N.decl [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %tuple.type.f41: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.a9d: type = tuple_type (bool, %i64) [concrete]
// CHECK:STDOUT:   %tuple.type.bc0: type = tuple_type (bool) [concrete]
// CHECK:STDOUT:   %pack_type.5da: type = pack_type type, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %.7b9: %pack_type.5da = pack_value (%i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.30e: <witness> = impl_witness @tuple.type.as.Count.impl.d86.%Count.impl_witness_table, @tuple.type.as.Count.impl.d86(%int_1.5b8, %.7b9) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.d3e: type = fn_type @tuple.type.as.Count.impl.N.loc10, @tuple.type.as.Count.impl.d86(%int_1.5b8, %.7b9) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.372: %tuple.type.as.Count.impl.N.type.d3e = struct_value () [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Count.facet.0bd: %Count.type = facet_value %tuple.type.f41, (%Count.impl_witness.30e) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.51e: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.0bd) [concrete]
// CHECK:STDOUT:   %.5f5: type = fn_type_with_self_type %Count.WithSelf.N.type.51e, %Count.facet.0bd [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.b8f: <specific function> = specific_function %tuple.type.as.Count.impl.N.372, @tuple.type.as.Count.impl.N.loc10(%int_1.5b8, %.7b9) [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2.ecc [concrete]
// CHECK:STDOUT:   %.177: %pack_type.8f6 = pack_value (bool, %i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.a80: <witness> = impl_witness @tuple.type.as.Count.impl.653.%Count.impl_witness_table, @tuple.type.as.Count.impl.653(%int_2.ecc, %.177) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.94d: type = fn_type @tuple.type.as.Count.impl.N.loc14, @tuple.type.as.Count.impl.653(%int_2.ecc, %.177) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.f7d: %tuple.type.as.Count.impl.N.type.94d = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.0cb: %Count.type = facet_value %tuple.type.a9d, (%Count.impl_witness.a80) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.6ad: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.0cb) [concrete]
// CHECK:STDOUT:   %.508: type = fn_type_with_self_type %Count.WithSelf.N.type.6ad, %Count.facet.0cb [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.078: <specific function> = specific_function %tuple.type.as.Count.impl.N.f7d, @tuple.type.as.Count.impl.N.loc14(%int_2.ecc, %.177) [concrete]
// CHECK:STDOUT:   %pack_type.28d: type = pack_type type, %int_0 [concrete]
// CHECK:STDOUT:   %.d3f: %pack_type.28d = pack_value () [concrete]
// CHECK:STDOUT:   %Count.impl_witness.550: <witness> = impl_witness @tuple.type.as.Count.impl.d86.%Count.impl_witness_table, @tuple.type.as.Count.impl.d86(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.40d: type = fn_type @tuple.type.as.Count.impl.N.loc10, @tuple.type.as.Count.impl.d86(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.3c0: %tuple.type.as.Count.impl.N.type.40d = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.37a: %Count.type = facet_value %tuple.type.bc0, (%Count.impl_witness.550) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.9c0: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.37a) [concrete]
// CHECK:STDOUT:   %.426: type = fn_type_with_self_type %Count.WithSelf.N.type.9c0, %Count.facet.37a [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.29f: <specific function> = specific_function %tuple.type.as.Count.impl.N.3c0, @tuple.type.as.Count.impl.N.loc10(%int_0, %.d3f) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%a.param: %tuple.type.f41, %b.param: %tuple.type.a9d, %c.param: %tuple.type.bc0) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Add.ref.loc19_10: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %Add.ref.loc19_14: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %a.ref: %tuple.type.f41 = name_ref a, %a
// CHECK:STDOUT:   %Count.ref.loc19_21: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc19_26: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc19_19: %.5f5 = impl_witness_access constants.%Count.impl_witness.30e, element0 [concrete = constants.%tuple.type.as.Count.impl.N.372]
// CHECK:STDOUT:   %bound_method.loc19_19: <bound method> = bound_method %a.ref, %impl.elem0.loc19_19
// CHECK:STDOUT:   %int_1.loc19_30.1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc19_30.1: %pack_type.5da = pack_value (constants.%i64) [concrete = constants.%.7b9]
// CHECK:STDOUT:   %int_1.loc19_30.2: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc19_30.2: %pack_type.5da = pack_value (constants.%i64) [concrete = constants.%.7b9]
// CHECK:STDOUT:   %specific_fn.loc19_19: <specific function> = specific_function %impl.elem0.loc19_19, @tuple.type.as.Count.impl.N.loc10(constants.%int_1.5b8, constants.%.7b9) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.b8f]
// CHECK:STDOUT:   %bound_method.loc19_30: <bound method> = bound_method %a.ref, %specific_fn.loc19_19
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc19_30: init %i64 = call %bound_method.loc19_30(%a.ref)
// CHECK:STDOUT:   %b.ref: %tuple.type.a9d = name_ref b, %b
// CHECK:STDOUT:   %Count.ref.loc19_36: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc19_41: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc19_34: %.508 = impl_witness_access constants.%Count.impl_witness.a80, element0 [concrete = constants.%tuple.type.as.Count.impl.N.f7d]
// CHECK:STDOUT:   %bound_method.loc19_34: <bound method> = bound_method %b.ref, %impl.elem0.loc19_34
// CHECK:STDOUT:   %int_2.loc19_45.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc19_45.1: %pack_type.8f6 = pack_value (bool, constants.%i64) [concrete = constants.%.177]
// CHECK:STDOUT:   %int_2.loc19_45.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc19_45.2: %pack_type.8f6 = pack_value (bool, constants.%i64) [concrete = constants.%.177]
// CHECK:STDOUT:   %specific_fn.loc19_34: <specific function> = specific_function %impl.elem0.loc19_34, @tuple.type.as.Count.impl.N.loc14(constants.%int_2.ecc, constants.%.177) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.078]
// CHECK:STDOUT:   %bound_method.loc19_45: <bound method> = bound_method %b.ref, %specific_fn.loc19_34
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc19_45: init %i64 = call %bound_method.loc19_45(%b.ref)
// CHECK:STDOUT:   %.loc19_30.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc19_30
// CHECK:STDOUT:   %.loc19_30.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc19_30, %.loc19_30.3
// CHECK:STDOUT:   %.loc19_45.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc19_45
// CHECK:STDOUT:   %.loc19_45.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc19_45, %.loc19_45.3
// CHECK:STDOUT:   %Add.call.loc19_46: init %i64 = call %Add.ref.loc19_14(%.loc19_30.4, %.loc19_45.4)
// CHECK:STDOUT:   %c.ref: %tuple.type.bc0 = name_ref c, %c
// CHECK:STDOUT:   %Count.ref.loc19_52: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc19_57: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc19_50: %.426 = impl_witness_access constants.%Count.impl_witness.550, element0 [concrete = constants.%tuple.type.as.Count.impl.N.3c0]
// CHECK:STDOUT:   %bound_method.loc19_50: <bound method> = bound_method %c.ref, %impl.elem0.loc19_50
// CHECK:STDOUT:   %int_0.loc19_61.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc19_61.1: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %int_0.loc19_61.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc19_61.2: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %specific_fn.loc19_50: <specific function> = specific_function %impl.elem0.loc19_50, @tuple.type.as.Count.impl.N.loc10(constants.%int_0, constants.%.d3f) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.29f]
// CHECK:STDOUT:   %bound_method.loc19_61: <bound method> = bound_method %c.ref, %specific_fn.loc19_50
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc19_61: init %i64 = call %bound_method.loc19_61(%c.ref)
// CHECK:STDOUT:   %.loc19_46.1: %i64 = value_of_initializer %Add.call.loc19_46
// CHECK:STDOUT:   %.loc19_46.2: %i64 = converted %Add.call.loc19_46, %.loc19_46.1
// CHECK:STDOUT:   %.loc19_61.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc19_61
// CHECK:STDOUT:   %.loc19_61.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc19_61, %.loc19_61.3
// CHECK:STDOUT:   %Add.call.loc19_62: init %i64 = call %Add.ref.loc19_10(%.loc19_46.2, %.loc19_61.4)
// CHECK:STDOUT:   return %Add.call.loc19_62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- rank_elements_after_reversed.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %Add.type: type = fn_type @Add [concrete]
// CHECK:STDOUT:   %Add: %Add.type = struct_value () [concrete]
// CHECK:STDOUT:   %Count.type: type = facet_type <@Count> [concrete]
// CHECK:STDOUT:   %Count.assoc_type: type = assoc_entity_type @Count [concrete]
// CHECK:STDOUT:   %assoc0.71c: %Count.assoc_type = assoc_entity element0, @Count.WithSelf.%Count.WithSelf.N.decl [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %tuple.type.f41: type = tuple_type (%i64, bool) [concrete]
// CHECK:STDOUT:   %tuple.type.a9d: type = tuple_type (bool, %i64) [concrete]
// CHECK:STDOUT:   %tuple.type.bc0: type = tuple_type (bool) [concrete]
// CHECK:STDOUT:   %pack_type.5da: type = pack_type type, %int_1.5b8 [concrete]
// CHECK:STDOUT:   %.7b9: %pack_type.5da = pack_value (%i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.30e: <witness> = impl_witness @tuple.type.as.Count.impl.d86.%Count.impl_witness_table, @tuple.type.as.Count.impl.d86(%int_1.5b8, %.7b9) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.d3e: type = fn_type @tuple.type.as.Count.impl.N.loc14, @tuple.type.as.Count.impl.d86(%int_1.5b8, %.7b9) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.372: %tuple.type.as.Count.impl.N.type.d3e = struct_value () [concrete]
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Count.facet.0bd: %Count.type = facet_value %tuple.type.f41, (%Count.impl_witness.30e) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.51e: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.0bd) [concrete]
// CHECK:STDOUT:   %.5f5: type = fn_type_with_self_type %Count.WithSelf.N.type.51e, %Count.facet.0bd [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.b8f: <specific function> = specific_function %tuple.type.as.Count.impl.N.372, @tuple.type.as.Count.impl.N.loc14(%int_1.5b8, %.7b9) [concrete]
// CHECK:STDOUT:   %pack_type.8f6: type = pack_type type, %int_2.ecc [concrete]
// CHECK:STDOUT:   %.177: %pack_type.8f6 = pack_value (bool, %i64) [concrete]
// CHECK:STDOUT:   %Count.impl_witness.a80: <witness> = impl_witness @tuple.type.as.Count.impl.653.%Count.impl_witness_table, @tuple.type.as.Count.impl.653(%int_2.ecc, %.177) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.94d: type = fn_type @tuple.type.as.Count.impl.N.loc10, @tuple.type.as.Count.impl.653(%int_2.ecc, %.177) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.f7d: %tuple.type.as.Count.impl.N.type.94d = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.0cb: %Count.type = facet_value %tuple.type.a9d, (%Count.impl_witness.a80) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.6ad: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.0cb) [concrete]
// CHECK:STDOUT:   %.508: type = fn_type_with_self_type %Count.WithSelf.N.type.6ad, %Count.facet.0cb [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.078: <specific function> = specific_function %tuple.type.as.Count.impl.N.f7d, @tuple.type.as.Count.impl.N.loc10(%int_2.ecc, %.177) [concrete]
// CHECK:STDOUT:   %pack_type.28d: type = pack_type type, %int_0 [concrete]
// CHECK:STDOUT:   %.d3f: %pack_type.28d = pack_value () [concrete]
// CHECK:STDOUT:   %Count.impl_witness.550: <witness> = impl_witness @tuple.type.as.Count.impl.d86.%Count.impl_witness_table, @tuple.type.as.Count.impl.d86(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.type.40d: type = fn_type @tuple.type.as.Count.impl.N.loc14, @tuple.type.as.Count.impl.d86(%int_0, %.d3f) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.3c0: %tuple.type.as.Count.impl.N.type.40d = struct_value () [concrete]
// CHECK:STDOUT:   %Count.facet.37a: %Count.type = facet_value %tuple.type.bc0, (%Count.impl_witness.550) [concrete]
// CHECK:STDOUT:   %Count.WithSelf.N.type.9c0: type = fn_type @Count.WithSelf.N, @Count.WithSelf(%Count.facet.37a) [concrete]
// CHECK:STDOUT:   %.426: type = fn_type_with_self_type %Count.WithSelf.N.type.9c0, %Count.facet.37a [concrete]
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.specific_fn.29f: <specific function> = specific_function %tuple.type.as.Count.impl.N.3c0, @tuple.type.as.Count.impl.N.loc14(%int_0, %.d3f) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Call(%a.param: %tuple.type.f41, %b.param: %tuple.type.a9d, %c.param: %tuple.type.bc0) -> out %return.param: %i64 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Add.ref.loc19_10: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %Add.ref.loc19_14: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:   %a.ref: %tuple.type.f41 = name_ref a, %a
// CHECK:STDOUT:   %Count.ref.loc19_21: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc19_26: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc19_19: %.5f5 = impl_witness_access constants.%Count.impl_witness.30e, element0 [concrete = constants.%tuple.type.as.Count.impl.N.372]
// CHECK:STDOUT:   %bound_method.loc19_19: <bound method> = bound_method %a.ref, %impl.elem0.loc19_19
// CHECK:STDOUT:   %int_1.loc19_30.1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc19_30.1: %pack_type.5da = pack_value (constants.%i64) [concrete = constants.%.7b9]
// CHECK:STDOUT:   %int_1.loc19_30.2: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc19_30.2: %pack_type.5da = pack_value (constants.%i64) [concrete = constants.%.7b9]
// CHECK:STDOUT:   %specific_fn.loc19_19: <specific function> = specific_function %impl.elem0.loc19_19, @tuple.type.as.Count.impl.N.loc14(constants.%int_1.5b8, constants.%.7b9) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.b8f]
// CHECK:STDOUT:   %bound_method.loc19_30: <bound method> = bound_method %a.ref, %specific_fn.loc19_19
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc19_30: init %i64 = call %bound_method.loc19_30(%a.ref)
// CHECK:STDOUT:   %b.ref: %tuple.type.a9d = name_ref b, %b
// CHECK:STDOUT:   %Count.ref.loc19_36: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc19_41: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc19_34: %.508 = impl_witness_access constants.%Count.impl_witness.a80, element0 [concrete = constants.%tuple.type.as.Count.impl.N.f7d]
// CHECK:STDOUT:   %bound_method.loc19_34: <bound method> = bound_method %b.ref, %impl.elem0.loc19_34
// CHECK:STDOUT:   %int_2.loc19_45.1: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc19_45.1: %pack_type.8f6 = pack_value (bool, constants.%i64) [concrete = constants.%.177]
// CHECK:STDOUT:   %int_2.loc19_45.2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc19_45.2: %pack_type.8f6 = pack_value (bool, constants.%i64) [concrete = constants.%.177]
// CHECK:STDOUT:   %specific_fn.loc19_34: <specific function> = specific_function %impl.elem0.loc19_34, @tuple.type.as.Count.impl.N.loc10(constants.%int_2.ecc, constants.%.177) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.078]
// CHECK:STDOUT:   %bound_method.loc19_45: <bound method> = bound_method %b.ref, %specific_fn.loc19_34
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc19_45: init %i64 = call %bound_method.loc19_45(%b.ref)
// CHECK:STDOUT:   %.loc19_30.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc19_30
// CHECK:STDOUT:   %.loc19_30.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc19_30, %.loc19_30.3
// CHECK:STDOUT:   %.loc19_45.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc19_45
// CHECK:STDOUT:   %.loc19_45.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc19_45, %.loc19_45.3
// CHECK:STDOUT:   %Add.call.loc19_46: init %i64 = call %Add.ref.loc19_14(%.loc19_30.4, %.loc19_45.4)
// CHECK:STDOUT:   %c.ref: %tuple.type.bc0 = name_ref c, %c
// CHECK:STDOUT:   %Count.ref.loc19_52: type = name_ref Count, file.%Count.decl [concrete = constants.%Count.type]
// CHECK:STDOUT:   %N.ref.loc19_57: %Count.assoc_type = name_ref N, @Count.WithSelf.%assoc0 [concrete = constants.%assoc0.71c]
// CHECK:STDOUT:   %impl.elem0.loc19_50: %.426 = impl_witness_access constants.%Count.impl_witness.550, element0 [concrete = constants.%tuple.type.as.Count.impl.N.3c0]
// CHECK:STDOUT:   %bound_method.loc19_50: <bound method> = bound_method %c.ref, %impl.elem0.loc19_50
// CHECK:STDOUT:   %int_0.loc19_61.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc19_61.1: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %int_0.loc19_61.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0]
// CHECK:STDOUT:   %.loc19_61.2: %pack_type.28d = pack_value () [concrete = constants.%.d3f]
// CHECK:STDOUT:   %specific_fn.loc19_50: <specific function> = specific_function %impl.elem0.loc19_50, @tuple.type.as.Count.impl.N.loc14(constants.%int_0, constants.%.d3f) [concrete = constants.%tuple.type.as.Count.impl.N.specific_fn.29f]
// CHECK:STDOUT:   %bound_method.loc19_61: <bound method> = bound_method %c.ref, %specific_fn.loc19_50
// CHECK:STDOUT:   %tuple.type.as.Count.impl.N.call.loc19_61: init %i64 = call %bound_method.loc19_61(%c.ref)
// CHECK:STDOUT:   %.loc19_46.1: %i64 = value_of_initializer %Add.call.loc19_46
// CHECK:STDOUT:   %.loc19_46.2: %i64 = converted %Add.call.loc19_46, %.loc19_46.1
// CHECK:STDOUT:   %.loc19_61.3: %i64 = value_of_initializer %tuple.type.as.Count.impl.N.call.loc19_61
// CHECK:STDOUT:   %.loc19_61.4: %i64 = converted %tuple.type.as.Count.impl.N.call.loc19_61, %.loc19_61.3
// CHECK:STDOUT:   %Add.call.loc19_62: init %i64 = call %Add.ref.loc19_10(%.loc19_46.2, %.loc19_61.4)
// CHECK:STDOUT:   return %Add.call.loc19_62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- body_expansion.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %HasN.type: type = facet_type <@HasN> [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %HasN.assoc_type: type = assoc_entity_type @HasN [concrete]
// CHECK:STDOUT:   %assoc0.4bc: %HasN.assoc_type = assoc_entity element0, @HasN.WithSelf.%N [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
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
// CHECK:STDOUT:   %.bc0: Core.Form = init_form %i64 [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %return.param_patt.cfc: %pattern_type.f57 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %HasN.impl_witness.d5e: <witness> = impl_witness @i64.as.HasN.impl.%HasN.impl_witness_table [concrete]
// CHECK:STDOUT:   %HasN.facet.0c4: %HasN.type = facet_value %i64, (%HasN.impl_witness.d5e) [concrete]
// CHECK:STDOUT:   %HasN.impl_witness.39b: <witness> = impl_witness @bool.as.HasN.impl.%HasN.impl_witness_table [concrete]
// CHECK:STDOUT:   %HasN.facet.949: %HasN.type = facet_value bool, (%HasN.impl_witness.39b) [concrete]
// CHECK:STDOUT:   %Sum.type: type = facet_type <@Sum> [concrete]
// CHECK:STDOUT:   %return.patt.178: %pattern_type.f57 = return_slot_pattern %return.param_patt.cfc, %i64 [concrete]
// CHECK:STDOUT:   %Add.type: type = fn_type @Add [concrete]
// CHECK:STDOUT:   %Add: %Add.type = struct_value () [concrete]
// CHECK:STDOUT:   %.Self.frozen.e58: type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %arity.patt: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic]
// CHECK:STDOUT:   %pack_type.e84: type = pack_type %HasN.type, %arity [symbolic]
// CHECK:STDOUT:   %pattern_type.932: type = pattern_type %pack_type.e84 [symbolic]
// CHECK:STDOUT:   %T.patt.b23: %pattern_type.932 = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %T.cb9: %pack_type.e84 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %.853: %pattern_type.932 = pack_expansion_pattern %T.patt.b23, %arity.patt [symbolic]
// CHECK:STDOUT:   %.4ee: Core.IntLiteral = pack_index [symbolic]
// CHECK:STDOUT:   %.fc8: %HasN.type = pack_element %T.cb9, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.2d2: type = tuple_type (%pack_type.e84) [symbolic]
// CHECK:STDOUT:   %tuple.88b: %tuple.type.2d2 = tuple_value (%T.cb9) [symbolic]
// CHECK:STDOUT:   %pack_type.fce: type = pack_type %T.cb9, %arity [symbolic]
// CHECK:STDOUT:   %tuple.type.57a: type = tuple_type (%pack_type.fce) [symbolic]
// CHECK:STDOUT:   %.991: <witness> = impl_self_witness %tuple.type.57a, @Sum [symbolic]
// CHECK:STDOUT:   %Sum.impl_witness.668: <witness> = impl_witness @tuple.type.as.Sum.impl.%Sum.impl_witness_table, @tuple.type.as.Sum.impl(%arity, %T.cb9) [symbolic]
// CHECK:STDOUT:   %pattern_type.37d: type = pattern_type %tuple.type.57a [symbolic]
// CHECK:STDOUT:   %self.param_patt.3d0: %pattern_type.37d = value_param_pattern [symbolic]
// CHECK:STDOUT:   %self.patt.5a6: %pattern_type.37d = wrapper_binding_pattern self, %self.param_patt.3d0 [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get.type.515: type = fn_type @tuple.type.as.Sum.impl.Get, @tuple.type.as.Sum.impl(%arity, %T.cb9) [symbolic]
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get.afc: %tuple.type.as.Sum.impl.Get.type.515 = struct_value () [symbolic]
// CHECK:STDOUT:   %require_complete.0cf: <witness> = require_complete_type %tuple.type.57a [symbolic]
// CHECK:STDOUT:   %s.patt: %pattern_type.f57 = ref_binding_pattern s [concrete]
// CHECK:STDOUT:   %s.var_patt: %pattern_type.f57 = var_pattern %s.patt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %bound_method.0c1: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.2e4: %i64 = int_value 0 [concrete]
// CHECK:STDOUT:   %as_type.8b7: type = facet_access_type %.fc8 [symbolic]
// CHECK:STDOUT:   %HasN.lookup_impl_witness.413: <witness> = lookup_impl_witness %.fc8, @HasN [symbolic]
// CHECK:STDOUT:   %impl.elem0.815: %i64 = impl_witness_access %HasN.lookup_impl_witness.413, element0 [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.8cc: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.494: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_64) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.d73: %Int.as.Copy.impl.Op.type.494 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i64, (%Copy.impl_witness.8cc) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.5c1: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.826: type = fn_type_with_self_type %Copy.WithSelf.Op.type.5c1, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.d73, @Int.as.Copy.impl.Op(%int_64) [concrete]
// CHECK:STDOUT:   %self.param_patt.108: %pattern_type.f57 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f4: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt.108 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc18 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc18 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc18 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.6e9: type = tuple_type (%i64, bool, %i64) [concrete]
// CHECK:STDOUT:   %pattern_type.701: type = pattern_type %tuple.type.6e9 [concrete]
// CHECK:STDOUT:   %pack_type.fa3: type = pack_type %HasN.type, %int_3.1ba [concrete]
// CHECK:STDOUT:   %.294: %pack_type.fa3 = pack_value (%HasN.facet.0c4, %HasN.facet.949, %HasN.facet.0c4) [concrete]
// CHECK:STDOUT:   %pattern_type.07b: type = pattern_type %pack_type.fa3 [concrete]
// CHECK:STDOUT:   %T.patt.c66: %pattern_type.07b = symbolic_binding_pattern T, 1 [symbolic]
// CHECK:STDOUT:   %.28d: %pattern_type.07b = pack_expansion_pattern %T.patt.c66, %arity.patt [symbolic]
// CHECK:STDOUT:   %.b4a: %HasN.type = pack_element %.294, %.4ee [symbolic]
// CHECK:STDOUT:   %tuple.type.5bc: type = tuple_type (%HasN.type, %HasN.type, %HasN.type) [concrete]
// CHECK:STDOUT:   %tuple.6f0: %tuple.type.5bc = tuple_value (%HasN.facet.0c4, %HasN.facet.949, %HasN.facet.0c4) [concrete]
// CHECK:STDOUT:   %pack_type.3e9: type = pack_type %.294, %int_3.1ba [concrete]
// CHECK:STDOUT:   %.1c3: <witness> = impl_self_witness %tuple.type.6e9, @Sum [concrete]
// CHECK:STDOUT:   %Sum.impl_witness.051: <witness> = impl_witness @tuple.type.as.Sum.impl.%Sum.impl_witness_table, @tuple.type.as.Sum.impl(%int_3.1ba, %.294) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get.type.91f: type = fn_type @tuple.type.as.Sum.impl.Get, @tuple.type.as.Sum.impl(%int_3.1ba, %.294) [concrete]
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get.4ae: %tuple.type.as.Sum.impl.Get.type.91f = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.094: %pattern_type.701 = value_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.bd6: %pattern_type.701 = wrapper_binding_pattern self, %self.param_patt.094 [concrete]
// CHECK:STDOUT:   %complete_type.af6: <witness> = complete_type_witness %tuple.type.6e9 [concrete]
// CHECK:STDOUT:   %as_type.e21: type = facet_access_type %.b4a [symbolic]
// CHECK:STDOUT:   %HasN.lookup_impl_witness.fb2: <witness> = lookup_impl_witness %.b4a, @HasN [symbolic]
// CHECK:STDOUT:   %impl.elem0.661: %i64 = impl_witness_access %HasN.lookup_impl_witness.fb2, element0 [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/parts/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc18 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc18 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   impl_decl @tuple.type.as.Sum.impl [concrete] {
// CHECK:STDOUT:     %arity.patt.loc16_14.1: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc16_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:     %T.patt.loc16_24.1: @tuple.type.as.Sum.impl.%pattern_type (%pattern_type.932) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc16_24.2 (constants.%T.patt.b23)]
// CHECK:STDOUT:     %.loc16_14.1: @tuple.type.as.Sum.impl.%pattern_type (%pattern_type.932) = pack_expansion_pattern %T.patt.loc16_24.1, %arity.patt.loc16_14.1 [symbolic = %.loc16_14.2 (constants.%.853)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc16_43.1: @tuple.type.as.Sum.impl.%tuple.type.loc16_43.1 (%tuple.type.2d2) = tuple_literal (constants.%T.cb9) [symbolic = %tuple (constants.%tuple.88b)]
// CHECK:STDOUT:     %.loc16_43.2: type = converted %.loc16_43.1, constants.%tuple.type.57a [symbolic = %tuple.type.loc16_43.2 (constants.%tuple.type.57a)]
// CHECK:STDOUT:     %Sum.ref: type = name_ref Sum, file.%Sum.decl [concrete = constants.%Sum.type]
// CHECK:STDOUT:     %arity.loc16_14.2: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc16_14.1 (constants.%arity)]
// CHECK:STDOUT:     %.loc16_26: type = splice_block %HasN.ref [concrete = constants.%HasN.type] {
// CHECK:STDOUT:       %.Self.frozen: type = symbolic_binding .Self [symbolic_self = constants.%.Self.frozen.e58]
// CHECK:STDOUT:       %HasN.ref: type = name_ref HasN, file.%HasN.decl [concrete = constants.%HasN.type]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %T.loc16_24.2: @tuple.type.as.Sum.impl.%pack_type.loc16_24 (%pack_type.e84) = symbolic_binding T, 1 [symbolic = %T.loc16_24.1 (constants.%T.cb9)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc16: <witness> = impl_self_witness @tuple.type.as.Sum.impl.%.loc16_43.2, @Sum [symbolic = @tuple.type.as.Sum.impl.%.loc16_52 (constants.%.991)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic impl @tuple.type.as.Sum.impl(%arity.loc16_14.2: Core.IntLiteral, %T.loc16_24.2: @tuple.type.as.Sum.impl.%pack_type.loc16_24 (%pack_type.e84)) {
// CHECK:STDOUT:   %arity.patt.loc16_14.2: %pattern_type.dc0 = symbolic_binding_pattern <pack arity>, 0 [symbolic = %arity.patt.loc16_14.2 (constants.%arity.patt)]
// CHECK:STDOUT:   %arity.loc16_14.1: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity.loc16_14.1 (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc16_24: type = pack_type constants.%HasN.type, %arity.loc16_14.1 [symbolic = %pack_type.loc16_24 (constants.%pack_type.e84)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %pack_type.loc16_24 [symbolic = %pattern_type (constants.%pattern_type.932)]
// CHECK:STDOUT:   %T.patt.loc16_24.2: @tuple.type.as.Sum.impl.%pattern_type (%pattern_type.932) = symbolic_binding_pattern T, 1 [symbolic = %T.patt.loc16_24.2 (constants.%T.patt.b23)]
// CHECK:STDOUT:   %T.loc16_24.1: @tuple.type.as.Sum.impl.%pack_type.loc16_24 (%pack_type.e84) = symbolic_binding T, 1 [symbolic = %T.loc16_24.1 (constants.%T.cb9)]
// CHECK:STDOUT:   %.loc16_14.2: @tuple.type.as.Sum.impl.%pattern_type (%pattern_type.932) = pack_expansion_pattern %T.patt.loc16_24.2, %arity.patt.loc16_14.2 [symbolic = %.loc16_14.2 (constants.%.853)]
// CHECK:STDOUT:   %.loc16_37.1: Core.IntLiteral = pack_index [symbolic = %.loc16_37.1 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc16_37.2: %HasN.type = pack_element %T.loc16_24.1, %.loc16_37.1 [symbolic = %.loc16_37.2 (constants.%.fc8)]
// CHECK:STDOUT:   %tuple.type.loc16_43.1: type = tuple_type (%pack_type.loc16_24) [symbolic = %tuple.type.loc16_43.1 (constants.%tuple.type.2d2)]
// CHECK:STDOUT:   %tuple: @tuple.type.as.Sum.impl.%tuple.type.loc16_43.1 (%tuple.type.2d2) = tuple_value (%T.loc16_24.1) [symbolic = %tuple (constants.%tuple.88b)]
// CHECK:STDOUT:   %pack_type.loc16_43: type = pack_type %T.loc16_24.1, %arity.loc16_14.1 [symbolic = %pack_type.loc16_43 (constants.%pack_type.fce)]
// CHECK:STDOUT:   %tuple.type.loc16_43.2: type = tuple_type (%pack_type.loc16_43) [symbolic = %tuple.type.loc16_43.2 (constants.%tuple.type.57a)]
// CHECK:STDOUT:   %.loc16_52: <witness> = impl_self_witness %tuple.type.loc16_43.2, @Sum [symbolic = %.loc16_52 (constants.%.991)]
// CHECK:STDOUT:   %Sum.impl_witness.loc16_52.2: <witness> = impl_witness %Sum.impl_witness_table, @tuple.type.as.Sum.impl(%arity.loc16_14.1, %T.loc16_24.1) [symbolic = %Sum.impl_witness.loc16_52.2 (constants.%Sum.impl_witness.668)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get.type: type = fn_type @tuple.type.as.Sum.impl.Get, @tuple.type.as.Sum.impl(%arity.loc16_14.1, %T.loc16_24.1) [symbolic = %tuple.type.as.Sum.impl.Get.type (constants.%tuple.type.as.Sum.impl.Get.type.515)]
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get: @tuple.type.as.Sum.impl.%tuple.type.as.Sum.impl.Get.type (%tuple.type.as.Sum.impl.Get.type.515) = struct_value () [symbolic = %tuple.type.as.Sum.impl.Get (constants.%tuple.type.as.Sum.impl.Get.afc)]
// CHECK:STDOUT:
// CHECK:STDOUT:   impl: %.loc16_43.2 as %Sum.ref {
// CHECK:STDOUT:     %tuple.type.as.Sum.impl.Get.decl: @tuple.type.as.Sum.impl.%tuple.type.as.Sum.impl.Get.type (%tuple.type.as.Sum.impl.Get.type.515) = fn_decl @tuple.type.as.Sum.impl.Get [symbolic = @tuple.type.as.Sum.impl.%tuple.type.as.Sum.impl.Get (constants.%tuple.type.as.Sum.impl.Get.afc)] {
// CHECK:STDOUT:       %self.param_patt.loc17_17.1: @tuple.type.as.Sum.impl.Get.%pattern_type (%pattern_type.37d) = value_param_pattern [symbolic = %self.param_patt.loc17_17.2 (constants.%self.param_patt.3d0)]
// CHECK:STDOUT:       %self.patt.loc17_17.1: @tuple.type.as.Sum.impl.Get.%pattern_type (%pattern_type.37d) = wrapper_binding_pattern self, %self.param_patt.loc17_17.1 [symbolic = %self.patt.loc17_17.2 (constants.%self.patt.5a6)]
// CHECK:STDOUT:       %return.param_patt: %pattern_type.f57 = out_param_pattern [concrete = constants.%return.param_patt.cfc]
// CHECK:STDOUT:       %return.patt: %pattern_type.f57 = return_slot_pattern %return.param_patt, %i64.loc17 [concrete = constants.%return.patt.178]
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %i64.loc17: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:       %.loc17: Core.Form = init_form %i64.loc17 [concrete = constants.%.bc0]
// CHECK:STDOUT:       %self.param: @tuple.type.as.Sum.impl.Get.%tuple.type (%tuple.type.57a) = value_param call_param0
// CHECK:STDOUT:       %Self.ref: type = name_ref Self, @tuple.type.as.Sum.impl.%.loc16_43.2 [symbolic = %tuple.type (constants.%tuple.type.57a)]
// CHECK:STDOUT:       %self: @tuple.type.as.Sum.impl.Get.%tuple.type (%tuple.type.57a) = wrapper_binding self, %self.param
// CHECK:STDOUT:       %return.param: ref %i64 = out_param call_param1
// CHECK:STDOUT:       %return: ref %i64 = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %Sum.impl_witness_table = impl_witness_table (%tuple.type.as.Sum.impl.Get.decl), @tuple.type.as.Sum.impl [concrete]
// CHECK:STDOUT:     %Sum.impl_witness.loc16_52.1: <witness> = impl_witness %Sum.impl_witness_table, @tuple.type.as.Sum.impl(constants.%arity, constants.%T.cb9) [symbolic = %Sum.impl_witness.loc16_52.2 (constants.%Sum.impl_witness.668)]
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Get = %tuple.type.as.Sum.impl.Get.decl
// CHECK:STDOUT:     .Add = <poisoned>
// CHECK:STDOUT:     .T = <poisoned>
// CHECK:STDOUT:     extend %Sum.ref
// CHECK:STDOUT:     witness = %Sum.impl_witness.loc16_52.1
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @tuple.type.as.Sum.impl.Get(@tuple.type.as.Sum.impl.%arity.loc16_14.2: Core.IntLiteral, @tuple.type.as.Sum.impl.%T.loc16_24.2: @tuple.type.as.Sum.impl.%pack_type.loc16_24 (%pack_type.e84)) {
// CHECK:STDOUT:   %arity: Core.IntLiteral = symbolic_binding <pack arity>, 0 [symbolic = %arity (constants.%arity)]
// CHECK:STDOUT:   %pack_type.loc17_17.1: type = pack_type constants.%HasN.type, %arity [symbolic = %pack_type.loc17_17.1 (constants.%pack_type.e84)]
// CHECK:STDOUT:   %T: @tuple.type.as.Sum.impl.Get.%pack_type.loc17_17.1 (%pack_type.e84) = symbolic_binding T, 1 [symbolic = %T (constants.%T.cb9)]
// CHECK:STDOUT:   %pack_type.loc17_17.2: type = pack_type %T, %arity [symbolic = %pack_type.loc17_17.2 (constants.%pack_type.fce)]
// CHECK:STDOUT:   %tuple.type: type = tuple_type (%pack_type.loc17_17.2) [symbolic = %tuple.type (constants.%tuple.type.57a)]
// CHECK:STDOUT:   %pattern_type: type = pattern_type %tuple.type [symbolic = %pattern_type (constants.%pattern_type.37d)]
// CHECK:STDOUT:   %self.param_patt.loc17_17.2: @tuple.type.as.Sum.impl.Get.%pattern_type (%pattern_type.37d) = value_param_pattern [symbolic = %self.param_patt.loc17_17.2 (constants.%self.param_patt.3d0)]
// CHECK:STDOUT:   %self.patt.loc17_17.2: @tuple.type.as.Sum.impl.Get.%pattern_type (%pattern_type.37d) = wrapper_binding_pattern self, %self.param_patt.loc17_17.2 [symbolic = %self.patt.loc17_17.2 (constants.%self.patt.5a6)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type %tuple.type [symbolic = %require_complete (constants.%require_complete.0cf)]
// CHECK:STDOUT:   %.loc19_21.3: Core.IntLiteral = pack_index [symbolic = %.loc19_21.3 (constants.%.4ee)]
// CHECK:STDOUT:   %.loc19_21.4: %HasN.type = pack_element %T, %.loc19_21.3 [symbolic = %.loc19_21.4 (constants.%.fc8)]
// CHECK:STDOUT:   %as_type.loc19_28.2: type = facet_access_type %.loc19_21.4 [symbolic = %as_type.loc19_28.2 (constants.%as_type.8b7)]
// CHECK:STDOUT:   %HasN.lookup_impl_witness: <witness> = lookup_impl_witness %.loc19_21.4, @HasN [symbolic = %HasN.lookup_impl_witness (constants.%HasN.lookup_impl_witness.413)]
// CHECK:STDOUT:   %impl.elem0.loc19_28.2: %i64 = impl_witness_access %HasN.lookup_impl_witness, element0 [symbolic = %impl.elem0.loc19_28.2 (constants.%impl.elem0.815)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn(%self.param: @tuple.type.as.Sum.impl.Get.%tuple.type (%tuple.type.57a)) -> out %return.param: %i64 {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %s.var: ref %i64 = var_storage %s.var_patt
// CHECK:STDOUT:     %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     %impl.elem0.loc18: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:     %bound_method.loc18_5.1: <bound method> = bound_method %int_0, %impl.elem0.loc18 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.0a3]
// CHECK:STDOUT:     %specific_fn.loc18: <specific function> = specific_function %impl.elem0.loc18, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:     %bound_method.loc18_5.2: <bound method> = bound_method %int_0, %specific_fn.loc18 [concrete = constants.%bound_method.0c1]
// CHECK:STDOUT:     %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc18_5.2(%int_0) [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     %.loc18: init %i64 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_0.2e4]
// CHECK:STDOUT:     assign %s.var, %.loc18
// CHECK:STDOUT:     %i64.loc18: type = type_literal constants.%i64 [concrete = constants.%i64]
// CHECK:STDOUT:     %s: ref %i64 = wrapper_binding s, %s.var
// CHECK:STDOUT:     name_binding_decl {
// CHECK:STDOUT:       %s.patt: %pattern_type.f57 = ref_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:       %s.var_patt: %pattern_type.f57 = var_pattern %s.patt [concrete = constants.%s.var_patt]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %.loc19_5: Core.IntLiteral = specific_constant @tuple.type.as.Sum.impl.%arity.loc16_14.2, @tuple.type.as.Sum.impl(constants.%arity, constants.%T.cb9) [symbolic = %arity (constants.%arity)]
// CHECK:STDOUT:     pack_expansion_statement %.loc19_5 {
// CHECK:STDOUT:       %s.ref.loc19_9: ref %i64 = name_ref s, %s
// CHECK:STDOUT:       %Add.ref: %Add.type = name_ref Add, file.%Add.decl [concrete = constants.%Add]
// CHECK:STDOUT:       %s.ref.loc19_17: ref %i64 = name_ref s, %s
// CHECK:STDOUT:       %T.ref: @tuple.type.as.Sum.impl.Get.%pack_type.loc17_17.1 (%pack_type.e84) = name_ref T, @tuple.type.as.Sum.impl.%T.loc16_24.2 [symbolic = %T (constants.%T.cb9)]
// CHECK:STDOUT:       %.loc19_21.1: Core.IntLiteral = pack_index [symbolic = %.loc19_21.3 (constants.%.4ee)]
// CHECK:STDOUT:       %.loc19_21.2: %HasN.type = pack_element %T.ref, %.loc19_21.1 [symbolic = %.loc19_21.4 (constants.%.fc8)]
// CHECK:STDOUT:       %as_type.loc19_28.1: type = facet_access_type %.loc19_21.2 [symbolic = %as_type.loc19_28.2 (constants.%as_type.8b7)]
// CHECK:STDOUT:       %.loc19_28: type = converted %.loc19_21.2, %as_type.loc19_28.1 [symbolic = %as_type.loc19_28.2 (constants.%as_type.8b7)]
// CHECK:STDOUT:       %N.ref: %HasN.assoc_type = name_ref N, @N.%assoc0 [concrete = constants.%assoc0.4bc]
// CHECK:STDOUT:       %impl.elem0.loc19_28.1: %i64 = impl_witness_access constants.%HasN.lookup_impl_witness.413, element0 [symbolic = %impl.elem0.loc19_28.2 (constants.%impl.elem0.815)]
// CHECK:STDOUT:       %.loc19_17: %i64 = acquire_value %s.ref.loc19_17
// CHECK:STDOUT:       %Add.call: init %i64 = call %Add.ref(%.loc19_17, %impl.elem0.loc19_28.1)
// CHECK:STDOUT:       assign %s.ref.loc19_9, %Add.call
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s.ref.loc20: ref %i64 = name_ref s, %s
// CHECK:STDOUT:     %.loc20: %i64 = acquire_value %s.ref.loc20
// CHECK:STDOUT:     %impl.elem0.loc20: %.826 = impl_witness_access constants.%Copy.impl_witness.8cc, element0 [concrete = constants.%Int.as.Copy.impl.Op.d73]
// CHECK:STDOUT:     %bound_method.loc20_12.1: <bound method> = bound_method %.loc20, %impl.elem0.loc20
// CHECK:STDOUT:     %specific_fn.loc20: <specific function> = specific_function %impl.elem0.loc20, @Int.as.Copy.impl.Op(constants.%int_64) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:     %bound_method.loc20_12.2: <bound method> = bound_method %.loc20, %specific_fn.loc20
// CHECK:STDOUT:     %Int.as.Copy.impl.Op.call: init %i64 = call %bound_method.loc20_12.2(%.loc20)
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %s.var, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:     %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%s.var)
// CHECK:STDOUT:     return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc18(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc18(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc18(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Sum.impl(constants.%arity, constants.%T.cb9) {
// CHECK:STDOUT:   %arity.patt.loc16_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc16_14.1 => constants.%arity
// CHECK:STDOUT:   %pack_type.loc16_24 => constants.%pack_type.e84
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.932
// CHECK:STDOUT:   %T.patt.loc16_24.2 => constants.%T.patt.b23
// CHECK:STDOUT:   %T.loc16_24.1 => constants.%T.cb9
// CHECK:STDOUT:   %.loc16_14.2 => constants.%.853
// CHECK:STDOUT:   %.loc16_37.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc16_37.2 => constants.%.fc8
// CHECK:STDOUT:   %tuple.type.loc16_43.1 => constants.%tuple.type.2d2
// CHECK:STDOUT:   %tuple => constants.%tuple.88b
// CHECK:STDOUT:   %pack_type.loc16_43 => constants.%pack_type.fce
// CHECK:STDOUT:   %tuple.type.loc16_43.2 => constants.%tuple.type.57a
// CHECK:STDOUT:   %.loc16_52 => constants.%.991
// CHECK:STDOUT:   %Sum.impl_witness.loc16_52.2 => constants.%Sum.impl_witness.668
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get.type => constants.%tuple.type.as.Sum.impl.Get.type.515
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get => constants.%tuple.type.as.Sum.impl.Get.afc
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Sum.impl.Get(constants.%arity, constants.%T.cb9) {
// CHECK:STDOUT:   %arity => constants.%arity
// CHECK:STDOUT:   %pack_type.loc17_17.1 => constants.%pack_type.e84
// CHECK:STDOUT:   %T => constants.%T.cb9
// CHECK:STDOUT:   %pack_type.loc17_17.2 => constants.%pack_type.fce
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.57a
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.37d
// CHECK:STDOUT:   %self.param_patt.loc17_17.2 => constants.%self.param_patt.3d0
// CHECK:STDOUT:   %self.patt.loc17_17.2 => constants.%self.patt.5a6
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Sum.impl(constants.%int_3.1ba, constants.%.294) {
// CHECK:STDOUT:   %arity.patt.loc16_14.2 => constants.%arity.patt
// CHECK:STDOUT:   %arity.loc16_14.1 => constants.%int_3.1ba
// CHECK:STDOUT:   %pack_type.loc16_24 => constants.%pack_type.fa3
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.07b
// CHECK:STDOUT:   %T.patt.loc16_24.2 => constants.%T.patt.c66
// CHECK:STDOUT:   %T.loc16_24.1 => constants.%.294
// CHECK:STDOUT:   %.loc16_14.2 => constants.%.28d
// CHECK:STDOUT:   %.loc16_37.1 => constants.%.4ee
// CHECK:STDOUT:   %.loc16_37.2 => constants.%.b4a
// CHECK:STDOUT:   %tuple.type.loc16_43.1 => constants.%tuple.type.5bc
// CHECK:STDOUT:   %tuple => constants.%tuple.6f0
// CHECK:STDOUT:   %pack_type.loc16_43 => constants.%pack_type.3e9
// CHECK:STDOUT:   %tuple.type.loc16_43.2 => constants.%tuple.type.6e9
// CHECK:STDOUT:   %.loc16_52 => constants.%.1c3
// CHECK:STDOUT:   %Sum.impl_witness.loc16_52.2 => constants.%Sum.impl_witness.051
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get.type => constants.%tuple.type.as.Sum.impl.Get.type.91f
// CHECK:STDOUT:   %tuple.type.as.Sum.impl.Get => constants.%tuple.type.as.Sum.impl.Get.4ae
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @tuple.type.as.Sum.impl.Get(constants.%int_3.1ba, constants.%.294) {
// CHECK:STDOUT:   %arity => constants.%int_3.1ba
// CHECK:STDOUT:   %pack_type.loc17_17.1 => constants.%pack_type.fa3
// CHECK:STDOUT:   %T => constants.%.294
// CHECK:STDOUT:   %pack_type.loc17_17.2 => constants.%pack_type.3e9
// CHECK:STDOUT:   %tuple.type => constants.%tuple.type.6e9
// CHECK:STDOUT:   %pattern_type => constants.%pattern_type.701
// CHECK:STDOUT:   %self.param_patt.loc17_17.2 => constants.%self.param_patt.094
// CHECK:STDOUT:   %self.patt.loc17_17.2 => constants.%self.patt.bd6
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete => constants.%complete_type.af6
// CHECK:STDOUT:   %.loc19_21.3 => constants.%.4ee
// CHECK:STDOUT:   %.loc19_21.4 => constants.%.b4a
// CHECK:STDOUT:   %as_type.loc19_28.2 => constants.%as_type.e21
// CHECK:STDOUT:   %HasN.lookup_impl_witness => constants.%HasN.lookup_impl_witness.fb2
// CHECK:STDOUT:   %impl.elem0.loc19_28.2 => constants.%impl.elem0.661
// CHECK:STDOUT: }
// CHECK:STDOUT:
