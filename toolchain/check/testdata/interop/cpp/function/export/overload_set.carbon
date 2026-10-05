// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set.carbon

// Exporting a Carbon `overload fn` set to C++ (fork decision F-009;
// fork/overload/plan.md OV-3, §1.C, §4.C). C++ name lookup of the set's name
// receives every exportable member as its own declaration, so C++ sees an
// ordinary C++ overload set and resolves calls to it under C++'s rules —
// best viable match — while Carbon call sites resolve the same set by
// declaration-order first-match. The divergence is documented, not prevented
// (docs/design/functions_overloading.md, "Documented divergence"): C++ may
// select a different member than Carbon would, or reject as ambiguous a call
// Carbon accepts; it can never call a member with the wrong ABI, because each
// member is its own C++ declaration with its own symbol. The dumped ranges
// pin the Carbon side's selections; the lower twin pins the C++ side's.

// --- overload_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(unused x: i64) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// `true` is an exact match for `F(bool)`, and `7L` for `F(long)` — `i64` maps
// to `long`. A plain `7` is NOT passed here: under C++ rules `int -> long`
// and `int -> bool` are both Conversion rank, so `Carbon::F(7)` is ambiguous
// (`fail_cpp_ambiguous` below), where Carbon's first-match selects `F(i64)`.
inline Cpp '''
inline int CallBool() { return Carbon::F(true); }
inline int CallWithLong() { return Carbon::F(7L); }
''';

//@dump-sem-ir-begin
fn Use() -> i32 { return F(7) + F(true) + Cpp.CallBool() + Cpp.CallWithLong(); }
//@dump-sem-ir-end

// --- divergence.carbon

library "[[@TEST_NAME]]";

import Cpp;

// The two sides select DIFFERENT members for the same argument type: Carbon
// takes the first member (`i32` widens to `i64`, an implicit conversion), C++
// takes `Pick(int)` (an exact match outranks the `int -> long` conversion).
overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

inline Cpp '''
inline int FromCpp(int v) { return Carbon::Pick(v); }
''';

//@dump-sem-ir-begin
fn Use(n: i32) -> i32 { return Pick(n) + Cpp.FromCpp(n); }
//@dump-sem-ir-end

// --- method_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

// Members in class scope export as C++ member-function overloads of the
// exported class; `ref self` members are lvalue-ref-qualified.
class Acc {
  var total: i32;
  fn Make() -> Acc { return {.total = 0}; }
  overload fn Add(ref self, x: i32) { self.total = self.total + x; }
  overload fn Add(ref self, flag: bool) {
    if (flag) { self.total = self.total + 100; }
  }
  fn Get(self) -> i32 { return self.total; }
}

inline Cpp '''
inline int Drive() {
  auto a = Carbon::Acc::Make();
  a.Add(1);
  a.Add(true);
  return a.Get();
}
''';

//@dump-sem-ir-begin
fn Use() -> i32 { return Cpp.Drive(); }
//@dump-sem-ir-end

// --- fail_cpp_ambiguous.carbon

library "[[@TEST_NAME]]";

import Cpp;

// The "whether" half of the divergence: Carbon's first-match accepts `F(7)`
// (the literal converts to `i64`), while under C++ rules `int -> long` and
// `int -> bool` are both Conversion rank ([over.ics.rank]/4.1 demotes only
// pointer and member-pointer conversions to `bool`), so Clang rejects
// `Carbon::F(7)` as ambiguous.
overload fn F(unused x: i64) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return F(7); }

inline Cpp '''
// CHECK:STDERR: fail_cpp_ambiguous.carbon:[[@LINE+10]]:40: error: call to 'F' is ambiguous [CppInteropParseError]
// CHECK:STDERR:    27 | inline int CallWithPlainInt() { return Carbon::F(7); }
// CHECK:STDERR:       |                                        ^~~~~~~~~
// CHECK:STDERR: fail_cpp_ambiguous.carbon:[[@LINE-9]]:37: note: candidate function [CppInteropParseNote]
// CHECK:STDERR:    11 | overload fn F(unused x: i64) -> i32 { return 1; }
// CHECK:STDERR:       |                                     ^
// CHECK:STDERR: fail_cpp_ambiguous.carbon:[[@LINE-11]]:38: note: candidate function [CppInteropParseNote]
// CHECK:STDERR:    12 | overload fn F(unused b: bool) -> i32 { return 2; }
// CHECK:STDERR:       |                                      ^
// CHECK:STDERR:
inline int CallWithPlainInt() { return Carbon::F(7); }
''';

// --- fail_todo_partial_export.carbon

library "[[@TEST_NAME]]";

import Cpp;

// A member whose signature has no C++ mapping (a tuple-typed parameter) is
// omitted from the exported set after the per-function export path emits its
// semantics TODO, which is an error: the unit is rejected until the member
// maps. The mappable member is still delivered to Clang, so the TODO is the
// only diagnostic — `Carbon::F(7)` resolves and no "no member named 'F'"
// cascade follows (sub-fork F-009i, fork/overload/plan.md §1.C.1).
overload fn F(unused x: i32) -> i32 { return 1; }
// CHECK:STDERR: fail_todo_partial_export.carbon:[[@LINE+4]]:1: error: semantics TODO: `failed to map C++ type to Carbon` [SemanticsTodo]
// CHECK:STDERR: overload fn F(unused p: (i32, i32)) -> i32 { return 2; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn F(unused p: (i32, i32)) -> i32 { return 2; }

inline Cpp '''
inline int CallInt() { return Carbon::F(7); }
''';

fn Use() -> i32 { return Cpp.CallInt(); }


// --- fail_todo_generic_class_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

// A set in a generic class (OV-2) reached from C++ through a specialization
// of the exported class template: the per-function export path stops at the
// generic class's scope with a semantics TODO for EVERY member it is asked
// to export — one diagnostic per member, as `constructor.carbon`'s
// `fail_todo_call_generic_class_constructor` gets one for its one function —
// and the empty list is the single-function "no declarations" outcome, so
// Clang then reports the missing member. The N-fold TODO is recorded
// residue, not a diagnostic of OV-3's own.
class Box(T: type) {
  var total: i32;
  // CHECK:STDERR: fail_todo_generic_class_set.carbon:[[@LINE+4]]:3: error: semantics TODO: `non-class non-namespace name scope` [SemanticsTodo]
  // CHECK:STDERR:   overload fn Add(ref self, n: i32) { self.total = self.total + n; }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  overload fn Add(ref self, n: i32) { self.total = self.total + n; }
  // CHECK:STDERR: fail_todo_generic_class_set.carbon:[[@LINE+4]]:3: error: semantics TODO: `non-class non-namespace name scope` [SemanticsTodo]
  // CHECK:STDERR:   overload fn Add(ref self, b: bool) { if (b) { self.total = self.total + 100; } }
  // CHECK:STDERR:   ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  overload fn Add(ref self, b: bool) { if (b) { self.total = self.total + 100; } }
}

inline Cpp '''
// CHECK:STDERR: fail_todo_generic_class_set.carbon:[[@LINE+4]]:44: error: no member named 'Add' in 'Carbon::Box<int>' [CppInteropParseError]
// CHECK:STDERR:    33 | inline void Drive(Carbon::Box<int>& b) { b.Add(1); }
// CHECK:STDERR:       |                                          ~ ^
// CHECK:STDERR:
inline void Drive(Carbon::Box<int>& b) { b.Add(1); }
''';

// CHECK:STDOUT: --- overload_set.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type.eb3ec9.1: type = fn_type @F.loc6 [concrete]
// CHECK:STDOUT:   %F.7088cc.1: %F.type.eb3ec9.1 = struct_value () [concrete]
// CHECK:STDOUT:   %F.overload_set.type: type = overload_set_type @F.overload_set [concrete]
// CHECK:STDOUT:   %F.overload_set.value: %F.overload_set.type = overload_set_value @F.overload_set [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %F.type.eb3ec9.2: type = fn_type @F.loc7 [concrete]
// CHECK:STDOUT:   %F.7088cc.2: %F.type.eb3ec9.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.227: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.55a = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.235: %ImplicitAs.type.221 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.227) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.da7: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.235) [concrete]
// CHECK:STDOUT:   %.03f: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.da7, %ImplicitAs.facet.235 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.59d: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.9e6: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33 [concrete]
// CHECK:STDOUT:   %int_7.824: %i64 = int_value 7 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
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
// CHECK:STDOUT:   %CallBool.cpp_overload_set.type: type = cpp_overload_set_type @CallBool.cpp_overload_set [concrete]
// CHECK:STDOUT:   %CallBool.cpp_overload_set.value: %CallBool.cpp_overload_set.type = cpp_overload_set_value @CallBool.cpp_overload_set [concrete]
// CHECK:STDOUT:   %CallBool__carbon_thunk.type: type = fn_type @CallBool__carbon_thunk [concrete]
// CHECK:STDOUT:   %CallBool__carbon_thunk: %CallBool__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %CallWithLong.cpp_overload_set.type: type = cpp_overload_set_type @CallWithLong.cpp_overload_set [concrete]
// CHECK:STDOUT:   %CallWithLong.cpp_overload_set.value: %CallWithLong.cpp_overload_set.type = cpp_overload_set_value @CallWithLong.cpp_overload_set [concrete]
// CHECK:STDOUT:   %CallWithLong__carbon_thunk.type: type = fn_type @CallWithLong__carbon_thunk [concrete]
// CHECK:STDOUT:   %CallWithLong__carbon_thunk: %CallWithLong__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .CallBool = %CallBool.cpp_overload_set.value
// CHECK:STDOUT:     .CallWithLong = %CallWithLong.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %CallBool.cpp_overload_set.value: %CallBool.cpp_overload_set.type = cpp_overload_set_value @CallBool.cpp_overload_set [concrete = constants.%CallBool.cpp_overload_set.value]
// CHECK:STDOUT:   %CallBool__carbon_thunk.decl: %CallBool__carbon_thunk.type = fn_decl @CallBool__carbon_thunk [concrete = constants.%CallBool__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %CallWithLong.cpp_overload_set.value: %CallWithLong.cpp_overload_set.type = cpp_overload_set_value @CallWithLong.cpp_overload_set [concrete = constants.%CallWithLong.cpp_overload_set.value]
// CHECK:STDOUT:   %CallWithLong__carbon_thunk.decl: %CallWithLong__carbon_thunk.type = fn_decl @CallWithLong__carbon_thunk [concrete = constants.%CallWithLong__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc19_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref.loc19_26: %F.overload_set.type = name_ref F, file.%F.overload_set.value [concrete = constants.%F.overload_set.value]
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %F.ref.loc19_29: %F.type.eb3ec9.1 = name_ref F, file.%F.decl.loc6 [concrete = constants.%F.7088cc.1]
// CHECK:STDOUT:   %impl.elem0: %.03f = impl_witness_access constants.%ImplicitAs.impl_witness.227, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.a1b]
// CHECK:STDOUT:   %bound_method.loc19_28.1: <bound method> = bound_method %int_7, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.59d]
// CHECK:STDOUT:   %specific_fn.loc19_28: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.f33]
// CHECK:STDOUT:   %bound_method.loc19_28.2: <bound method> = bound_method %int_7, %specific_fn.loc19_28 [concrete = constants.%bound_method.9e6]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc19_28.2(%int_7) [concrete = constants.%int_7.824]
// CHECK:STDOUT:   %.loc19_28.1: %i64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_7.824]
// CHECK:STDOUT:   %.loc19_28.2: %i64 = converted %int_7, %.loc19_28.1 [concrete = constants.%int_7.824]
// CHECK:STDOUT:   %F.call.loc19_29: init %i32 = call %F.ref.loc19_29(%.loc19_28.2)
// CHECK:STDOUT:   %F.ref.loc19_33: %F.overload_set.type = name_ref F, file.%F.overload_set.value [concrete = constants.%F.overload_set.value]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %F.ref.loc19_39: %F.type.eb3ec9.2 = name_ref F, file.%F.decl.loc7 [concrete = constants.%F.7088cc.2]
// CHECK:STDOUT:   %F.call.loc19_39: init %i32 = call %F.ref.loc19_39(%true)
// CHECK:STDOUT:   %impl.elem1.loc19_31: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc19_31.1: <bound method> = bound_method %F.call.loc19_29, %impl.elem1.loc19_31
// CHECK:STDOUT:   %specific_fn.loc19_31: <specific function> = specific_function %impl.elem1.loc19_31, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc19_31.2: <bound method> = bound_method %F.call.loc19_29, %specific_fn.loc19_31
// CHECK:STDOUT:   %.loc19_29.1: %i32 = value_of_initializer %F.call.loc19_29
// CHECK:STDOUT:   %.loc19_29.2: %i32 = converted %F.call.loc19_29, %.loc19_29.1
// CHECK:STDOUT:   %.loc19_39.1: %i32 = value_of_initializer %F.call.loc19_39
// CHECK:STDOUT:   %.loc19_39.2: %i32 = converted %F.call.loc19_39, %.loc19_39.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc19_31: init %i32 = call %bound_method.loc19_31.2(%.loc19_29.2, %.loc19_39.2)
// CHECK:STDOUT:   %Cpp.ref.loc19_43: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %CallBool.ref: %CallBool.cpp_overload_set.type = name_ref CallBool, imports.%CallBool.cpp_overload_set.value [concrete = constants.%CallBool.cpp_overload_set.value]
// CHECK:STDOUT:   %CallBool__carbon_thunk.call: init %i32 = call imports.%CallBool__carbon_thunk.decl()
// CHECK:STDOUT:   %impl.elem1.loc19_41: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc19_41.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc19_31, %impl.elem1.loc19_41
// CHECK:STDOUT:   %specific_fn.loc19_41: <specific function> = specific_function %impl.elem1.loc19_41, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc19_41.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc19_31, %specific_fn.loc19_41
// CHECK:STDOUT:   %.loc19_31.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc19_31
// CHECK:STDOUT:   %.loc19_31.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc19_31, %.loc19_31.1
// CHECK:STDOUT:   %.loc19_56.1: %i32 = value_of_initializer %CallBool__carbon_thunk.call
// CHECK:STDOUT:   %.loc19_56.2: %i32 = converted %CallBool__carbon_thunk.call, %.loc19_56.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc19_41: init %i32 = call %bound_method.loc19_41.2(%.loc19_31.2, %.loc19_56.2)
// CHECK:STDOUT:   %Cpp.ref.loc19_60: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %CallWithLong.ref: %CallWithLong.cpp_overload_set.type = name_ref CallWithLong, imports.%CallWithLong.cpp_overload_set.value [concrete = constants.%CallWithLong.cpp_overload_set.value]
// CHECK:STDOUT:   %CallWithLong__carbon_thunk.call: init %i32 = call imports.%CallWithLong__carbon_thunk.decl()
// CHECK:STDOUT:   %impl.elem1.loc19_58: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc19_58.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc19_41, %impl.elem1.loc19_58
// CHECK:STDOUT:   %specific_fn.loc19_58: <specific function> = specific_function %impl.elem1.loc19_58, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc19_58.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc19_41, %specific_fn.loc19_58
// CHECK:STDOUT:   %.loc19_41.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc19_41
// CHECK:STDOUT:   %.loc19_41.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc19_41, %.loc19_41.1
// CHECK:STDOUT:   %.loc19_77.1: %i32 = value_of_initializer %CallWithLong__carbon_thunk.call
// CHECK:STDOUT:   %.loc19_77.2: %i32 = converted %CallWithLong__carbon_thunk.call, %.loc19_77.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc19_58: init %i32 = call %bound_method.loc19_58.2(%.loc19_41.2, %.loc19_77.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call.loc19_58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- divergence.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Pick.type.113fcf.1: type = fn_type @Pick.loc9 [concrete]
// CHECK:STDOUT:   %Pick.bd7a10.1: %Pick.type.113fcf.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Pick.overload_set.type: type = overload_set_type @Pick.overload_set [concrete]
// CHECK:STDOUT:   %Pick.overload_set.value: %Pick.overload_set.type = overload_set_value @Pick.overload_set [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.2: type = class_type @Int, @Int(%To) [symbolic]
// CHECK:STDOUT:   %facet_type.037: type = facet_type <@IntFitsIn, @IntFitsIn(%Int.67af24.2) & @AnyInt> [symbolic]
// CHECK:STDOUT:   %From.6a4: %facet_type.037 = symbolic_binding From, 1 [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7fa: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%To, %From.6a4) [symbolic]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.643: %From.as_type.as.ImplicitAs.impl.Convert.type.7fa = struct_value () [symbolic]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.221: type = facet_type <@ImplicitAs, @ImplicitAs(%i64)> [concrete]
// CHECK:STDOUT:   %facet_type.30a: type = facet_type <@IntFitsIn, @IntFitsIn(%i64) & @AnyInt> [concrete]
// CHECK:STDOUT:   %custom_witness: <witness> = custom_witness (), @IntFitsIn, @IntFitsIn(%i64) [concrete]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.type.f15: type = fn_type @Int.as.AnyInt.impl.AsInt, @Int.as.AnyInt.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AnyInt.impl.AsInt.d10: %Int.as.AnyInt.impl.AsInt.type.f15 = struct_value () [symbolic]
// CHECK:STDOUT:   %AnyInt.impl_witness.48c: <witness> = impl_witness imports.%AnyInt.impl_witness_table, @Int.as.AnyInt.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value: %facet_type.30a = facet_value %i32, (%custom_witness, %AnyInt.impl_witness.48c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.8d3: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.992, @From.as_type.as.ImplicitAs.impl(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.type.7ba: type = fn_type @From.as_type.as.ImplicitAs.impl.Convert, @From.as_type.as.ImplicitAs.impl(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.15a: %From.as_type.as.ImplicitAs.impl.Convert.type.7ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.4f1: %ImplicitAs.type.221 = facet_value %i32, (%ImplicitAs.impl_witness.8d3) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.ed0: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i64, %ImplicitAs.facet.4f1) [concrete]
// CHECK:STDOUT:   %.dbf: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.ed0, %ImplicitAs.facet.4f1 [concrete]
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %From.as_type.as.ImplicitAs.impl.Convert.15a, @From.as_type.as.ImplicitAs.impl.Convert(%int_64, %facet_value) [concrete]
// CHECK:STDOUT:   %FromCpp.cpp_overload_set.type: type = cpp_overload_set_type @FromCpp.cpp_overload_set [concrete]
// CHECK:STDOUT:   %FromCpp.cpp_overload_set.value: %FromCpp.cpp_overload_set.type = cpp_overload_set_value @FromCpp.cpp_overload_set [concrete]
// CHECK:STDOUT:   %FromCpp__carbon_thunk.type: type = fn_type @FromCpp__carbon_thunk [concrete]
// CHECK:STDOUT:   %FromCpp__carbon_thunk: %FromCpp__carbon_thunk.type = struct_value () [concrete]
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
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .FromCpp = %FromCpp.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.2a4: @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert.type (%From.as_type.as.ImplicitAs.impl.Convert.type.7fa) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @From.as_type.as.ImplicitAs.impl.%From.as_type.as.ImplicitAs.impl.Convert (constants.%From.as_type.as.ImplicitAs.impl.Convert.643)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.992 = impl_witness_table (%Core.import_ref.2a4), @From.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.47b: Core.IntLiteral = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%N (constants.%N)]
// CHECK:STDOUT:   %Core.import_ref.49b: @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt.type (%Int.as.AnyInt.impl.AsInt.type.f15) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AnyInt.impl.%Int.as.AnyInt.impl.AsInt (constants.%Int.as.AnyInt.impl.AsInt.d10)]
// CHECK:STDOUT:   %AnyInt.impl_witness_table = impl_witness_table (%Core.import_ref.47b, %Core.import_ref.49b), @Int.as.AnyInt.impl [concrete]
// CHECK:STDOUT:   %FromCpp.cpp_overload_set.value: %FromCpp.cpp_overload_set.type = cpp_overload_set_value @FromCpp.cpp_overload_set [concrete = constants.%FromCpp.cpp_overload_set.value]
// CHECK:STDOUT:   %FromCpp__carbon_thunk.decl: %FromCpp__carbon_thunk.type = fn_decl @FromCpp__carbon_thunk [concrete = constants.%FromCpp__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc17_19 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc17_19: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc17_19: Core.Form = init_form %i32.loc17_19 [concrete = constants.%.795f]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc17_11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use(%n.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Pick.ref.loc17_32: %Pick.overload_set.type = name_ref Pick, file.%Pick.overload_set.value [concrete = constants.%Pick.overload_set.value]
// CHECK:STDOUT:   %n.ref.loc17_37: %i32 = name_ref n, %n
// CHECK:STDOUT:   %Pick.ref.loc17_38: %Pick.type.113fcf.1 = name_ref Pick, file.%Pick.decl.loc9 [concrete = constants.%Pick.bd7a10.1]
// CHECK:STDOUT:   %impl.elem0: %.dbf = impl_witness_access constants.%ImplicitAs.impl_witness.8d3, element0 [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.15a]
// CHECK:STDOUT:   %bound_method.loc17_37.1: <bound method> = bound_method %n.ref.loc17_37, %impl.elem0
// CHECK:STDOUT:   %specific_fn.loc17_37: <specific function> = specific_function %impl.elem0, @From.as_type.as.ImplicitAs.impl.Convert(constants.%int_64, constants.%facet_value) [concrete = constants.%From.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc17_37.2: <bound method> = bound_method %n.ref.loc17_37, %specific_fn.loc17_37
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call: init %i64 = call %bound_method.loc17_37.2(%n.ref.loc17_37)
// CHECK:STDOUT:   %.loc17_37.1: %i64 = value_of_initializer %From.as_type.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc17_37.2: %i64 = converted %n.ref.loc17_37, %.loc17_37.1
// CHECK:STDOUT:   %Pick.call: init %i32 = call %Pick.ref.loc17_38(%.loc17_37.2)
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %FromCpp.ref: %FromCpp.cpp_overload_set.type = name_ref FromCpp, imports.%FromCpp.cpp_overload_set.value [concrete = constants.%FromCpp.cpp_overload_set.value]
// CHECK:STDOUT:   %n.ref.loc17_54: %i32 = name_ref n, %n
// CHECK:STDOUT:   %FromCpp__carbon_thunk.call: init %i32 = call imports.%FromCpp__carbon_thunk.decl(%n.ref.loc17_54)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc17_40.1: <bound method> = bound_method %Pick.call, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc17_40: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc17_40.2: <bound method> = bound_method %Pick.call, %specific_fn.loc17_40
// CHECK:STDOUT:   %.loc17_38.1: %i32 = value_of_initializer %Pick.call
// CHECK:STDOUT:   %.loc17_38.2: %i32 = converted %Pick.call, %.loc17_38.1
// CHECK:STDOUT:   %.loc17_55.1: %i32 = value_of_initializer %FromCpp__carbon_thunk.call
// CHECK:STDOUT:   %.loc17_55.2: %i32 = converted %FromCpp__carbon_thunk.call, %.loc17_55.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc17_40.2(%.loc17_38.2, %.loc17_55.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- method_set.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %Drive.cpp_overload_set.type: type = cpp_overload_set_type @Drive.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Drive.cpp_overload_set.value: %Drive.cpp_overload_set.type = cpp_overload_set_value @Drive.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Drive__carbon_thunk.type: type = fn_type @Drive__carbon_thunk [concrete]
// CHECK:STDOUT:   %Drive__carbon_thunk: %Drive__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Drive = %Drive.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Drive.cpp_overload_set.value: %Drive.cpp_overload_set.type = cpp_overload_set_value @Drive.cpp_overload_set [concrete = constants.%Drive.cpp_overload_set.value]
// CHECK:STDOUT:   %Drive__carbon_thunk.decl: %Drive__carbon_thunk.type = fn_decl @Drive__carbon_thunk [concrete = constants.%Drive__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc28: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Drive.ref: %Drive.cpp_overload_set.type = name_ref Drive, imports.%Drive.cpp_overload_set.value [concrete = constants.%Drive.cpp_overload_set.value]
// CHECK:STDOUT:   %Drive__carbon_thunk.call: init %i32 = call imports.%Drive__carbon_thunk.decl()
// CHECK:STDOUT:   return %Drive__carbon_thunk.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
