// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/import/union_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/import/union_init.carbon

// An imported C++ union is a Carbon union (docs/design/unions.md, "Importing
// C++ unions"; fork/unions/plan.md UN-2, §4.B). With `is_union` set on import,
// a struct literal takes the designated single-field initialization of a
// native union (`ConvertStructToUnion`: one `class_element_access` and a
// one-element `class_init`, never a `struct_value` of the union type), the
// copy keeps C++'s copy constructor (D-UN-5's `is_cpp_scope` exclusion), and
// by-value crossings in both directions follow function/import/union.carbon.
// The negative pins are in fail_union_init.carbon.

// --- pair.h

union Pair {
  int a;
  int b;
};

// --- designated_init.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

fn F() -> i32 {
  //@dump-sem-ir-begin
  var u: Cpp.Pair = {.a = 1};
  return u.b;
  //@dump-sem-ir-end
}

// --- empty.h

union Bar {};

// --- empty_init.carbon

library "[[@TEST_NAME]]";

import Cpp library "empty.h";

// An empty aggregate keeps its landed `StructType{}` representation, so `{}`
// stays accepted: the union arm sits inside the `CustomLayoutType` branch.
fn F() {
  //@dump-sem-ir-begin
  var unused b: Cpp.Bar = {};
  //@dump-sem-ir-end
}

// --- copy.carbon

library "[[@TEST_NAME]]";

import Cpp library "pair.h";

// The copy of an imported union is C++'s (trivial) copy constructor through
// `BuildCopyWitness` (check/cpp/impl_lookup.cpp), not the primitive copy the
// native-union gate synthesizes.
fn F(a: Cpp.Pair) -> Cpp.Pair {
  //@dump-sem-ir-begin
  var b: Cpp.Pair = a;
  return b;
  //@dump-sem-ir-end
}

// --- by_value.h

union Pair {
  int a;
  int b;
};

inline int ReadA(Pair u) { return u.a; }

inline Pair MakePair(int v) {
  Pair p;
  p.a = v;
  return p;
}

// --- by_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "by_value.h";

// Carbon passes the union by value into C++ and receives one by value back.
fn F() -> i32 {
  //@dump-sem-ir-begin
  var u: Cpp.Pair = {.a = 1};
  var m: Cpp.Pair = Cpp.MakePair(2);
  return Cpp.ReadA(u) + m.b;
  //@dump-sem-ir-end
}

// CHECK:STDOUT: --- designated_init.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Pair: type = class_type @Pair [concrete]
// CHECK:STDOUT:   %Pair.elem: type = unbound_element_type %Pair, %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.64c: type = pattern_type %Pair [concrete]
// CHECK:STDOUT:   %u.patt: %pattern_type.64c = ref_binding_pattern u [concrete]
// CHECK:STDOUT:   %u.var_patt: %pattern_type.64c = var_pattern %u.patt [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %struct_type.a: type = struct_type {.a: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.a = struct_value (%int_1.5b8) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Pair.cpp_destructor.type: type = fn_type @Pair.cpp_destructor [concrete]
// CHECK:STDOUT:   %Pair.cpp_destructor: %Pair.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Pair = %Pair.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Pair.decl: type = class_decl @Pair [concrete = constants.%Pair] {} {}
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.var: ref %Pair = var_storage %u.var_patt
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc8_28.1: %struct_type.a = struct_literal (%int_1) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc8: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc8_28.1: <bound method> = bound_method %int_1, %impl.elem0.loc8 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc8: <specific function> = specific_function %impl.elem0.loc8, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_28.2: <bound method> = bound_method %int_1, %specific_fn.loc8 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc8_28.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_28.2: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_28.3: ref %i32 = class_element_access %u.var, element0
// CHECK:STDOUT:   %.loc8_28.4: init %i32 to %.loc8_28.3 = in_place_init %.loc8_28.2 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc8_28.5: init %Pair to %u.var = class_init (%.loc8_28.4)
// CHECK:STDOUT:   %.loc8_3: init %Pair = converted %.loc8_28.1, %.loc8_28.5
// CHECK:STDOUT:   assign %u.var, %.loc8_3
// CHECK:STDOUT:   %.loc8_13: type = splice_block %Pair.ref [concrete = constants.%Pair] {
// CHECK:STDOUT:     %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Pair.ref: type = name_ref Pair, imports.%Pair.decl [concrete = constants.%Pair]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %u: ref %Pair = wrapper_binding u, %u.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %u.patt: %pattern_type.64c = ref_binding_pattern u [concrete = constants.%u.patt]
// CHECK:STDOUT:     %u.var_patt: %pattern_type.64c = var_pattern %u.patt [concrete = constants.%u.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %u.ref: ref %Pair = name_ref u, %u
// CHECK:STDOUT:   %b.ref: %Pair.elem = name_ref b, @Pair.%.2 [concrete = @Pair.%.2]
// CHECK:STDOUT:   %.loc9_11.1: ref %i32 = class_element_access %u.ref, element1
// CHECK:STDOUT:   %.loc9_11.2: %i32 = acquire_value %.loc9_11.1
// CHECK:STDOUT:   %impl.elem0.loc9: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc9_11.1: <bound method> = bound_method %.loc9_11.2, %impl.elem0.loc9
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_11.2: <bound method> = bound_method %.loc9_11.2, %specific_fn.loc9
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc9_11.2(%.loc9_11.2)
// CHECK:STDOUT:   %Pair.cpp_destructor.bound: <bound method> = bound_method %u.var, constants.%Pair.cpp_destructor
// CHECK:STDOUT:   %Pair.cpp_destructor.call: init %empty_tuple.type = call %Pair.cpp_destructor.bound(%u.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- empty_init.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Bar: type = class_type @Bar [concrete]
// CHECK:STDOUT:   %empty_struct_type: type = struct_type {} [concrete]
// CHECK:STDOUT:   %pattern_type.3db: type = pattern_type %Bar [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.3db = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.3db = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   %empty_struct: %empty_struct_type = struct_value () [concrete]
// CHECK:STDOUT:   %Bar.cpp_destructor.type: type = fn_type @Bar.cpp_destructor [concrete]
// CHECK:STDOUT:   %Bar.cpp_destructor: %Bar.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Bar = %Bar.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Bar.decl: type = class_decl @Bar [concrete = constants.%Bar] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.var: ref %Bar = var_storage %b.var_patt
// CHECK:STDOUT:   %.loc10_28.1: %empty_struct_type = struct_literal () [concrete = constants.%empty_struct]
// CHECK:STDOUT:   %.loc10_28.2: init %Bar to %b.var = class_init ()
// CHECK:STDOUT:   %.loc10_3: init %Bar = converted %.loc10_28.1, %.loc10_28.2
// CHECK:STDOUT:   assign %b.var, %.loc10_3
// CHECK:STDOUT:   %.loc10_20: type = splice_block %Bar.ref [concrete = constants.%Bar] {
// CHECK:STDOUT:     %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Bar.ref: type = name_ref Bar, imports.%Bar.decl [concrete = constants.%Bar]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: ref %Bar = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.3db = ref_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.3db = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Bar.cpp_destructor.bound: <bound method> = bound_method %b.var, constants.%Bar.cpp_destructor
// CHECK:STDOUT:   %Bar.cpp_destructor.call: init %empty_tuple.type = call %Bar.cpp_destructor.bound(%b.var)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- copy.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Pair: type = class_type @Pair [concrete]
// CHECK:STDOUT:   %pattern_type.64c: type = pattern_type %Pair [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.64c = ref_binding_pattern b [concrete]
// CHECK:STDOUT:   %b.var_patt: %pattern_type.64c = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Pair.Pair.type: type = fn_type @Pair.Pair [concrete]
// CHECK:STDOUT:   %Pair.Pair: %Pair.Pair.type = struct_value () [concrete]
// CHECK:STDOUT:   %const.24f: type = const_type %Pair [concrete]
// CHECK:STDOUT:   %ptr.c3e: type = ptr_type %const.24f [concrete]
// CHECK:STDOUT:   %ptr.dc6: type = ptr_type %Pair [concrete]
// CHECK:STDOUT:   %Pair__carbon_thunk.type: type = fn_type @Pair__carbon_thunk [concrete]
// CHECK:STDOUT:   %Pair__carbon_thunk: %Pair__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %Pair.Op.type: type = fn_type @Pair.Op [concrete]
// CHECK:STDOUT:   %Pair.Op: %Pair.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.d0d: <witness> = custom_witness (%Pair.Op), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.69a: %Copy.type = facet_value %Pair, (%custom_witness.d0d) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f0: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.69a) [concrete]
// CHECK:STDOUT:   %.83f: type = fn_type_with_self_type %Copy.WithSelf.Op.type.7f0, %Copy.facet.69a [concrete]
// CHECK:STDOUT:   %Pair.cpp_destructor.type: type = fn_type @Pair.cpp_destructor [concrete]
// CHECK:STDOUT:   %Pair.cpp_destructor: %Pair.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Pair = %Pair.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Pair.decl: type = class_decl @Pair [concrete = constants.%Pair] {} {}
// CHECK:STDOUT:   %Pair.Pair.decl: %Pair.Pair.type = fn_decl @Pair.Pair [concrete = constants.%Pair.Pair] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Pair__carbon_thunk.decl: %Pair__carbon_thunk.type = fn_decl @Pair__carbon_thunk [concrete = constants.%Pair__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%a.param: %Pair) -> out %return.param: %Pair {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.var: ref %Pair = var_storage %b.var_patt
// CHECK:STDOUT:   %a.ref: %Pair = name_ref a, %a
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc11: %.83f = impl_witness_access constants.%custom_witness.d0d, element0 [concrete = constants.%Pair.Op]
// CHECK:STDOUT:   %bound_method.loc11: <bound method> = bound_method %a.ref, %impl.elem0.loc11
// CHECK:STDOUT:   %.loc11_21.1: ref %Pair = temporary_storage
// CHECK:STDOUT:   %Op.ref.loc11: %Pair.Pair.type = name_ref Op, imports.%Pair.Pair.decl [concrete = constants.%Pair.Pair]
// CHECK:STDOUT:   %.loc11_3: ref %Pair = splice_block %b.var {}
// CHECK:STDOUT:   %.loc11_21.2: ref %Pair = value_as_ref %a.ref
// CHECK:STDOUT:   %addr.loc11_21.1: %ptr.dc6 = addr_of %.loc11_21.2
// CHECK:STDOUT:   %.loc11_21.3: %ptr.c3e = as_compatible %addr.loc11_21.1
// CHECK:STDOUT:   %.loc11_21.4: %ptr.c3e = converted %addr.loc11_21.1, %.loc11_21.3
// CHECK:STDOUT:   %addr.loc11_21.2: %ptr.dc6 = addr_of %.loc11_3
// CHECK:STDOUT:   %Pair__carbon_thunk.call.loc11: init %empty_tuple.type = call imports.%Pair__carbon_thunk.decl(%.loc11_21.4, %addr.loc11_21.2)
// CHECK:STDOUT:   %.loc11_21.5: init %Pair to %.loc11_3 = mark_in_place_init %Pair__carbon_thunk.call.loc11
// CHECK:STDOUT:   assign %b.var, %.loc11_21.5
// CHECK:STDOUT:   %.loc11_13: type = splice_block %Pair.ref.loc11 [concrete = constants.%Pair] {
// CHECK:STDOUT:     %Cpp.ref.loc11: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Pair.ref.loc11: type = name_ref Pair, imports.%Pair.decl [concrete = constants.%Pair]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b: ref %Pair = wrapper_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.64c = ref_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.64c = var_pattern %b.patt [concrete = constants.%b.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.ref: ref %Pair = name_ref b, %b
// CHECK:STDOUT:   %.loc12_10.1: %Pair = acquire_value %b.ref
// CHECK:STDOUT:   %impl.elem0.loc12: %.83f = impl_witness_access constants.%custom_witness.d0d, element0 [concrete = constants.%Pair.Op]
// CHECK:STDOUT:   %bound_method.loc12: <bound method> = bound_method %.loc12_10.1, %impl.elem0.loc12
// CHECK:STDOUT:   %.loc12_10.2: ref %Pair = temporary_storage
// CHECK:STDOUT:   %Op.ref.loc12: %Pair.Pair.type = name_ref Op, imports.%Pair.Pair.decl [concrete = constants.%Pair.Pair]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %.loc12_10.3: ref %Pair = value_as_ref %.loc12_10.1
// CHECK:STDOUT:   %addr.loc12_10.1: %ptr.dc6 = addr_of %.loc12_10.3
// CHECK:STDOUT:   %.loc12_10.4: %ptr.c3e = as_compatible %addr.loc12_10.1
// CHECK:STDOUT:   %.loc12_10.5: %ptr.c3e = converted %addr.loc12_10.1, %.loc12_10.4
// CHECK:STDOUT:   %addr.loc12_10.2: %ptr.dc6 = addr_of %.loc9_25.1
// CHECK:STDOUT:   %Pair__carbon_thunk.call.loc12: init %empty_tuple.type = call imports.%Pair__carbon_thunk.decl(%.loc12_10.5, %addr.loc12_10.2)
// CHECK:STDOUT:   %.loc12_10.6: init %Pair to %.loc9_25.1 = mark_in_place_init %Pair__carbon_thunk.call.loc12
// CHECK:STDOUT:   %Pair.cpp_destructor.bound: <bound method> = bound_method %b.var, constants.%Pair.cpp_destructor
// CHECK:STDOUT:   %Pair.cpp_destructor.call: init %empty_tuple.type = call %Pair.cpp_destructor.bound(%b.var)
// CHECK:STDOUT:   return %.loc12_10.6 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- by_value.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %Pair: type = class_type @Pair [concrete]
// CHECK:STDOUT:   %Pair.elem: type = unbound_element_type %Pair, %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.64c: type = pattern_type %Pair [concrete]
// CHECK:STDOUT:   %u.patt.cac: %pattern_type.64c = ref_binding_pattern u [concrete]
// CHECK:STDOUT:   %u.var_patt: %pattern_type.64c = var_pattern %u.patt.cac [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %struct_type.a: type = struct_type {.a: Core.IntLiteral} [concrete]
// CHECK:STDOUT:   %struct: %struct_type.a = struct_value (%int_1.5b8) [concrete]
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
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %m.patt: %pattern_type.64c = ref_binding_pattern m [concrete]
// CHECK:STDOUT:   %m.var_patt: %pattern_type.64c = var_pattern %m.patt [concrete]
// CHECK:STDOUT:   %MakePair.cpp_overload_set.type: type = cpp_overload_set_type @MakePair.cpp_overload_set [concrete]
// CHECK:STDOUT:   %MakePair.cpp_overload_set.value: %MakePair.cpp_overload_set.type = cpp_overload_set_value @MakePair.cpp_overload_set [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %ptr.dc6: type = ptr_type %Pair [concrete]
// CHECK:STDOUT:   %MakePair__carbon_thunk.type: type = fn_type @MakePair__carbon_thunk [concrete]
// CHECK:STDOUT:   %MakePair__carbon_thunk: %MakePair__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT:   %ReadA.cpp_overload_set.type: type = cpp_overload_set_type @ReadA.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ReadA.cpp_overload_set.value: %ReadA.cpp_overload_set.type = cpp_overload_set_value @ReadA.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ReadA__carbon_thunk.type: type = fn_type @ReadA__carbon_thunk [concrete]
// CHECK:STDOUT:   %ReadA__carbon_thunk: %ReadA__carbon_thunk.type = struct_value () [concrete]
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
// CHECK:STDOUT:   %Pair.cpp_destructor.type: type = fn_type @Pair.cpp_destructor [concrete]
// CHECK:STDOUT:   %Pair.cpp_destructor: %Pair.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Pair = %Pair.decl
// CHECK:STDOUT:     .MakePair = %MakePair.cpp_overload_set.value
// CHECK:STDOUT:     .ReadA = %ReadA.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Pair.decl: type = class_decl @Pair [concrete = constants.%Pair] {} {}
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %MakePair.cpp_overload_set.value: %MakePair.cpp_overload_set.type = cpp_overload_set_value @MakePair.cpp_overload_set [concrete = constants.%MakePair.cpp_overload_set.value]
// CHECK:STDOUT:   %MakePair__carbon_thunk.decl: %MakePair__carbon_thunk.type = fn_decl @MakePair__carbon_thunk [concrete = constants.%MakePair__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %ReadA.cpp_overload_set.value: %ReadA.cpp_overload_set.type = cpp_overload_set_value @ReadA.cpp_overload_set [concrete = constants.%ReadA.cpp_overload_set.value]
// CHECK:STDOUT:   %ReadA__carbon_thunk.decl: %ReadA__carbon_thunk.type = fn_decl @ReadA__carbon_thunk [concrete = constants.%ReadA__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %u.var: ref %Pair = var_storage %u.var_patt
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc9_28.1: %struct_type.a = struct_literal (%int_1) [concrete = constants.%struct]
// CHECK:STDOUT:   %impl.elem0.loc9: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_28.1: <bound method> = bound_method %int_1, %impl.elem0.loc9 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc9: <specific function> = specific_function %impl.elem0.loc9, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_28.2: <bound method> = bound_method %int_1, %specific_fn.loc9 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %i32 = call %bound_method.loc9_28.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_28.2: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_28.3: ref %i32 = class_element_access %u.var, element0
// CHECK:STDOUT:   %.loc9_28.4: init %i32 to %.loc9_28.3 = in_place_init %.loc9_28.2 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_28.5: init %Pair to %u.var = class_init (%.loc9_28.4)
// CHECK:STDOUT:   %.loc9_3: init %Pair = converted %.loc9_28.1, %.loc9_28.5
// CHECK:STDOUT:   assign %u.var, %.loc9_3
// CHECK:STDOUT:   %.loc9_13: type = splice_block %Pair.ref.loc9 [concrete = constants.%Pair] {
// CHECK:STDOUT:     %Cpp.ref.loc9: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Pair.ref.loc9: type = name_ref Pair, imports.%Pair.decl [concrete = constants.%Pair]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %u: ref %Pair = wrapper_binding u, %u.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %u.patt: %pattern_type.64c = ref_binding_pattern u [concrete = constants.%u.patt.cac]
// CHECK:STDOUT:     %u.var_patt: %pattern_type.64c = var_pattern %u.patt [concrete = constants.%u.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %m.var: ref %Pair = var_storage %m.var_patt
// CHECK:STDOUT:   %Cpp.ref.loc10_21: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %MakePair.ref: %MakePair.cpp_overload_set.type = name_ref MakePair, imports.%MakePair.cpp_overload_set.value [concrete = constants.%MakePair.cpp_overload_set.value]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %.loc10_3: ref %Pair = splice_block %m.var {}
// CHECK:STDOUT:   %impl.elem0.loc10: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_34.1: <bound method> = bound_method %int_2, %impl.elem0.loc10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_34.2: <bound method> = bound_method %int_2, %specific_fn.loc10 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_34.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc10_34.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc10_34.2: %i32 = converted %int_2, %.loc10_34.1 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %addr.loc10: %ptr.dc6 = addr_of %.loc10_3
// CHECK:STDOUT:   %MakePair__carbon_thunk.call: init %empty_tuple.type = call imports.%MakePair__carbon_thunk.decl(%.loc10_34.2, %addr.loc10)
// CHECK:STDOUT:   %.loc10_35: init %Pair to %.loc10_3 = mark_in_place_init %MakePair__carbon_thunk.call
// CHECK:STDOUT:   assign %m.var, %.loc10_35
// CHECK:STDOUT:   %.loc10_13: type = splice_block %Pair.ref.loc10 [concrete = constants.%Pair] {
// CHECK:STDOUT:     %Cpp.ref.loc10_10: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:     %Pair.ref.loc10: type = name_ref Pair, imports.%Pair.decl [concrete = constants.%Pair]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %m: ref %Pair = wrapper_binding m, %m.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %m.patt: %pattern_type.64c = ref_binding_pattern m [concrete = constants.%m.patt]
// CHECK:STDOUT:     %m.var_patt: %pattern_type.64c = var_pattern %m.patt [concrete = constants.%m.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp.ref.loc11: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %ReadA.ref: %ReadA.cpp_overload_set.type = name_ref ReadA, imports.%ReadA.cpp_overload_set.value [concrete = constants.%ReadA.cpp_overload_set.value]
// CHECK:STDOUT:   %u.ref: ref %Pair = name_ref u, %u
// CHECK:STDOUT:   %.loc11_20.1: %Pair = acquire_value %u.ref
// CHECK:STDOUT:   %.loc11_20.2: ref %Pair = value_as_ref %.loc11_20.1
// CHECK:STDOUT:   %addr.loc11: %ptr.dc6 = addr_of %.loc11_20.2
// CHECK:STDOUT:   %ReadA__carbon_thunk.call: init %i32 = call imports.%ReadA__carbon_thunk.decl(%addr.loc11)
// CHECK:STDOUT:   %m.ref: ref %Pair = name_ref m, %m
// CHECK:STDOUT:   %b.ref: %Pair.elem = name_ref b, @Pair.%.2 [concrete = @Pair.%.2]
// CHECK:STDOUT:   %.loc11_26.1: ref %i32 = class_element_access %m.ref, element1
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc11_23.1: <bound method> = bound_method %ReadA__carbon_thunk.call, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc11_23.2: <bound method> = bound_method %ReadA__carbon_thunk.call, %specific_fn.loc11
// CHECK:STDOUT:   %.loc11_21.1: %i32 = value_of_initializer %ReadA__carbon_thunk.call
// CHECK:STDOUT:   %.loc11_21.2: %i32 = converted %ReadA__carbon_thunk.call, %.loc11_21.1
// CHECK:STDOUT:   %.loc11_26.2: %i32 = acquire_value %.loc11_26.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc11_23.2(%.loc11_21.2, %.loc11_26.2)
// CHECK:STDOUT:   %Pair.cpp_destructor.bound.loc10: <bound method> = bound_method %m.var, constants.%Pair.cpp_destructor
// CHECK:STDOUT:   %Pair.cpp_destructor.call.loc10: init %empty_tuple.type = call %Pair.cpp_destructor.bound.loc10(%m.var)
// CHECK:STDOUT:   %Pair.cpp_destructor.bound.loc9: <bound method> = bound_method %u.var, constants.%Pair.cpp_destructor
// CHECK:STDOUT:   %Pair.cpp_destructor.call.loc9: init %empty_tuple.type = call %Pair.cpp_destructor.bound.loc9(%u.var)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
