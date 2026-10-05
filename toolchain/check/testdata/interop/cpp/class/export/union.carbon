// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/union.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/union.carbon

// A Carbon `union` exports to C++ as a genuine union (docs/design/unions.md,
// "Exporting Carbon unions to C++"; fork/unions/plan.md UN-2, D-UN-8): the
// record is created with `TagTypeKind::Union`, Carbon supplies the layout
// (size and alignment from the `CustomLayoutType` block, offset zero for every
// field), no `final` attribute and no destructor declaration are attached, and
// methods export as for classes. The `static_assert`s are the layout arbiter:
// they run in the embedded Clang, so a wrong tag kind fails `__is_union` and a
// layout disagreement fails `sizeof`/`alignof`, both as compile failures of
// this test. Passing an exported union by value INTO C++ is probed separately
// in union_by_value.carbon.

// --- exported.carbon
library "[[@TEST_NAME]]";
import Cpp;

union Wide {
  // CHECK:STDERR: exported.carbon:[[@LINE+4]]:7: error: union field `lo` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var lo: i32;
  // CHECK:STDERR:       ^~~~~~~
  // CHECK:STDERR:
  var lo: i32;
  // CHECK:STDERR: exported.carbon:[[@LINE+4]]:7: error: union field `both` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var both: i64;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var both: i64;
  fn Low(self) -> i32 { return self.lo; }
}

inline Cpp '''
static_assert(__is_union(Carbon::Wide), "kind");
// CHECK:STDERR: exported.carbon:[[@LINE+7]]:15: error: static assertion failed due to requirement 'sizeof(Carbon::Wide) == 8': layout [CppInteropParseError]
// CHECK:STDERR:    12 | static_assert(sizeof(Carbon::Wide) == 8 && alignof(Carbon::Wide) == 8,
// CHECK:STDERR:       |               ^~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: exported.carbon:[[@LINE+4]]:36: note: expression evaluates to '0 == 8' [CppInteropParseNote]
// CHECK:STDERR:    12 | static_assert(sizeof(Carbon::Wide) == 8 && alignof(Carbon::Wide) == 8,
// CHECK:STDERR:       |               ~~~~~~~~~~~~~~~~~~~~~^~~~
// CHECK:STDERR:
static_assert(sizeof(Carbon::Wide) == 8 && alignof(Carbon::Wide) == 8,
              "layout");

int Use(Carbon::Wide* w) {
  // CHECK:STDERR: exported.carbon:[[@LINE+4]]:6: error: no member named 'lo' in 'Carbon::Wide' [CppInteropParseError]
  // CHECK:STDERR:    16 |   w->lo = 3;
  // CHECK:STDERR:       |   ~  ^
  // CHECK:STDERR:
  w->lo = 3;
  return w->Low();
}

Carbon::Wide MakeWide(int v) {
  Carbon::Wide w;
  // CHECK:STDERR: exported.carbon:[[@LINE+4]]:5: error: no member named 'lo' in 'Carbon::Wide' [CppInteropParseError]
  // CHECK:STDERR:    22 |   w.lo = v;
  // CHECK:STDERR:       |   ~ ^
  // CHECK:STDERR:
  w.lo = v;
  return w;
}
''';

fn F() -> i32 {
  //@dump-sem-ir-begin
  var w: Wide = Cpp.MakeWide(1);
  return Cpp.Use(&w);
  //@dump-sem-ir-end
}

// --- static_method.carbon
library "[[@TEST_NAME]]";
import Cpp;

// The union as a C++ name scope (`Carbon::Wide::Zero`), the entry the UN-1
// placeholder guarded in `ExportNameScopeToCpp`.
union Wide {
  // CHECK:STDERR: static_method.carbon:[[@LINE+4]]:7: error: union field `lo` has type `i32`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var lo: i32;
  // CHECK:STDERR:       ^~~~~~~
  // CHECK:STDERR:
  var lo: i32;
  // CHECK:STDERR: static_method.carbon:[[@LINE+4]]:7: error: union field `both` has type `i64`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable]
  // CHECK:STDERR:   var both: i64;
  // CHECK:STDERR:       ^~~~~~~~~
  // CHECK:STDERR:
  var both: i64;
  fn Zero() -> i32 { return 0; }
}

inline Cpp '''
int CallZero() { return Carbon::Wide::Zero(); }
''';

fn F() -> i32 {
  //@dump-sem-ir-begin
  return Cpp.CallZero();
  //@dump-sem-ir-end
}

// CHECK:STDOUT: --- exported.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Wide: type = class_type @Wide [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.f3d: type = pattern_type %Wide [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.1: type = fn_type @Destroy.Op.loc4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.1: %Destroy.Op.type.1d8f74.1 = struct_value () [concrete]
// CHECK:STDOUT:   %w.patt.f4a: %pattern_type.f3d = ref_binding_pattern w [concrete]
// CHECK:STDOUT:   %w.var_patt: %pattern_type.f3d = var_pattern %w.patt.f4a [concrete]
// CHECK:STDOUT:   %MakeWide.cpp_overload_set.type: type = cpp_overload_set_type @MakeWide.cpp_overload_set [concrete]
// CHECK:STDOUT:   %MakeWide.cpp_overload_set.value: %MakeWide.cpp_overload_set.type = cpp_overload_set_value @MakeWide.cpp_overload_set [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %ptr.567: type = ptr_type %Wide [concrete]
// CHECK:STDOUT:   %MakeWide__carbon_thunk.type: type = fn_type @MakeWide__carbon_thunk [concrete]
// CHECK:STDOUT:   %MakeWide__carbon_thunk: %MakeWide__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %Use.cpp_overload_set.type: type = cpp_overload_set_type @Use.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Use.cpp_overload_set.value: %Use.cpp_overload_set.type = cpp_overload_set_value @Use.cpp_overload_set [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Some.type.71e: type = fn_type @ptr.as.OptionalStorage.impl.Some, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Some.caa: %ptr.as.OptionalStorage.impl.Some.type.71e = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.1 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.bf3: %Destroy.type = facet_value %ptr.567, (%custom_witness.df9cc1.2) [concrete]
// CHECK:STDOUT:   %MaybeUnformed.e77: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.bf3) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.6cd: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%Wide) [concrete]
// CHECK:STDOUT:   %.d0e: type = maybe_unformed_type %ptr.567 [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.bad: %OptionalStorage.type = facet_value %ptr.567, (%OptionalStorage.impl_witness.6cd) [concrete]
// CHECK:STDOUT:   %Optional.738: type = class_type @Optional, @Optional(%OptionalStorage.facet.bad) [concrete]
// CHECK:STDOUT:   %Use__carbon_thunk.type: type = fn_type @Use__carbon_thunk [concrete]
// CHECK:STDOUT:   %Use__carbon_thunk: %Use__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.47b: type = facet_type <@ImplicitAs, @ImplicitAs(%Optional.738)> [concrete]
// CHECK:STDOUT:   %OptionalAs.type.3b8: type = facet_type <@OptionalAs, @OptionalAs(%T.220)> [symbolic]
// CHECK:STDOUT:   %U.042: %OptionalAs.type.3b8 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.type.ad5: type = fn_type @U.as_type.as.ImplicitAs.impl.Convert.2, @U.as_type.as.ImplicitAs.impl.167(%T.220, %U.042) [symbolic]
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.331: %U.as_type.as.ImplicitAs.impl.Convert.type.ad5 = struct_value () [symbolic]
// CHECK:STDOUT:   %OptionalAs.type.7bb: type = facet_type <@OptionalAs, @OptionalAs(%OptionalStorage.facet.bad)> [concrete]
// CHECK:STDOUT:   %T.as_type.as.OptionalAs.impl.Convert.type.774: type = fn_type @T.as_type.as.OptionalAs.impl.Convert, @T.as_type.as.OptionalAs.impl(%T.220) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalAs.impl.Convert.5f9: %T.as_type.as.OptionalAs.impl.Convert.type.774 = struct_value () [symbolic]
// CHECK:STDOUT:   %OptionalAs.impl_witness.0e3: <witness> = impl_witness imports.%OptionalAs.impl_witness_table.2e9, @T.as_type.as.OptionalAs.impl(%OptionalStorage.facet.bad) [concrete]
// CHECK:STDOUT:   %OptionalAs.facet: %OptionalAs.type.7bb = facet_value %ptr.567, (%OptionalAs.impl_witness.0e3) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.50b: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.bb5, @U.as_type.as.ImplicitAs.impl.167(%OptionalStorage.facet.bad, %OptionalAs.facet) [concrete]
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.type.e2f: type = fn_type @U.as_type.as.ImplicitAs.impl.Convert.2, @U.as_type.as.ImplicitAs.impl.167(%OptionalStorage.facet.bad, %OptionalAs.facet) [concrete]
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.6e6: %U.as_type.as.ImplicitAs.impl.Convert.type.e2f = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.369: %ImplicitAs.type.47b = facet_value %ptr.567, (%ImplicitAs.impl_witness.50b) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.4e5: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%Optional.738, %ImplicitAs.facet.369) [concrete]
// CHECK:STDOUT:   %.4dd: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.4e5, %ImplicitAs.facet.369 [concrete]
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %U.as_type.as.ImplicitAs.impl.Convert.6e6, @U.as_type.as.ImplicitAs.impl.Convert.2(%OptionalStorage.facet.bad, %OptionalAs.facet) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.5: type = fn_type @Destroy.Op.loc30_18.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.5: %Destroy.Op.type.1d8f74.5 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .MakeWide = %MakeWide.cpp_overload_set.value
// CHECK:STDOUT:     .Use = %Use.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MakeWide.cpp_overload_set.value: %MakeWide.cpp_overload_set.type = cpp_overload_set_value @MakeWide.cpp_overload_set [concrete = constants.%MakeWide.cpp_overload_set.value]
// CHECK:STDOUT:   %MakeWide__carbon_thunk.decl: %MakeWide__carbon_thunk.type = fn_decl @MakeWide__carbon_thunk [concrete = constants.%MakeWide__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Use.cpp_overload_set.value: %Use.cpp_overload_set.type = cpp_overload_set_value @Use.cpp_overload_set [concrete = constants.%Use.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.import_ref.509: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%MaybeUnformed (constants.%MaybeUnformed.ddb)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.fa7: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Some.type (%ptr.as.OptionalStorage.impl.Some.type.71e) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Some (constants.%ptr.as.OptionalStorage.impl.Some.caa)]
// CHECK:STDOUT:   %Core.import_ref.a90 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.306 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.509, %Core.import_ref.105, %Core.import_ref.fa7, %Core.import_ref.a90, %Core.import_ref.306, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Use__carbon_thunk.decl: %Use__carbon_thunk.type = fn_decl @Use__carbon_thunk [concrete = constants.%Use__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:     %.loc30_20.1: type = splice_block %Optional [concrete = constants.%Optional.738] {
// CHECK:STDOUT:       %OptionalStorage.facet: %OptionalStorage.type = facet_value constants.%ptr.567, (constants.%OptionalStorage.impl_witness.6cd) [concrete = constants.%OptionalStorage.facet.bad]
// CHECK:STDOUT:       %.loc30_20.2: %OptionalStorage.type = converted constants.%ptr.567, %OptionalStorage.facet [concrete = constants.%OptionalStorage.facet.bad]
// CHECK:STDOUT:       %Optional: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.bad) [concrete = constants.%Optional.738]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.eb9: @U.as_type.as.ImplicitAs.impl.167.%U.as_type.as.ImplicitAs.impl.Convert.type (%U.as_type.as.ImplicitAs.impl.Convert.type.ad5) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @U.as_type.as.ImplicitAs.impl.167.%U.as_type.as.ImplicitAs.impl.Convert (constants.%U.as_type.as.ImplicitAs.impl.Convert.331)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.bb5 = impl_witness_table (%Core.import_ref.eb9), @U.as_type.as.ImplicitAs.impl.167 [concrete]
// CHECK:STDOUT:   %Core.import_ref.017d8: @T.as_type.as.OptionalAs.impl.%T.as_type.as.OptionalAs.impl.Convert.type (%T.as_type.as.OptionalAs.impl.Convert.type.774) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalAs.impl.%T.as_type.as.OptionalAs.impl.Convert (constants.%T.as_type.as.OptionalAs.impl.Convert.5f9)]
// CHECK:STDOUT:   %OptionalAs.impl_witness_table.2e9 = impl_witness_table (%Core.import_ref.017d8), @T.as_type.as.OptionalAs.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %w.var: ref %Wide = var_storage %w.var_patt
// CHECK:STDOUT:   %Cpp.ref.loc29: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %MakeWide.ref: %MakeWide.cpp_overload_set.type = name_ref MakeWide, imports.%MakeWide.cpp_overload_set.value [concrete = constants.%MakeWide.cpp_overload_set.value]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %.loc29_3: ref %Wide = splice_block %w.var {}
// CHECK:STDOUT:   %impl.elem0.loc29: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc29_30.1: <bound method> = bound_method %int_1, %impl.elem0.loc29 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc29: <specific function> = specific_function %impl.elem0.loc29, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc29_30.2: <bound method> = bound_method %int_1, %specific_fn.loc29 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc29_30.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc29_30.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc29_30.2: %i32 = converted %int_1, %.loc29_30.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %addr.loc29: %ptr.567 = addr_of %.loc29_3
// CHECK:STDOUT:   %MakeWide__carbon_thunk.call: init %empty_tuple.type = call imports.%MakeWide__carbon_thunk.decl(%.loc29_30.2, %addr.loc29)
// CHECK:STDOUT:   %.loc29_31: init %Wide to %.loc29_3 = mark_in_place_init %MakeWide__carbon_thunk.call
// CHECK:STDOUT:   assign %w.var, %.loc29_31
// CHECK:STDOUT:   %Wide.ref: type = name_ref Wide, file.%Wide.decl [concrete = constants.%Wide]
// CHECK:STDOUT:   %w: ref %Wide = wrapper_binding w, %w.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %w.patt: %pattern_type.f3d = ref_binding_pattern w [concrete = constants.%w.patt.f4a]
// CHECK:STDOUT:     %w.var_patt: %pattern_type.f3d = var_pattern %w.patt [concrete = constants.%w.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp.ref.loc30: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Use.ref: %Use.cpp_overload_set.type = name_ref Use, imports.%Use.cpp_overload_set.value [concrete = constants.%Use.cpp_overload_set.value]
// CHECK:STDOUT:   %w.ref: ref %Wide = name_ref w, %w
// CHECK:STDOUT:   %addr.loc30: %ptr.567 = addr_of %w.ref
// CHECK:STDOUT:   %impl.elem0.loc30: %.4dd = impl_witness_access constants.%ImplicitAs.impl_witness.50b, element0 [concrete = constants.%U.as_type.as.ImplicitAs.impl.Convert.6e6]
// CHECK:STDOUT:   %bound_method.loc30_18.1: <bound method> = bound_method %addr.loc30, %impl.elem0.loc30
// CHECK:STDOUT:   %specific_fn.loc30: <specific function> = specific_function %impl.elem0.loc30, @U.as_type.as.ImplicitAs.impl.Convert.2(constants.%OptionalStorage.facet.bad, constants.%OptionalAs.facet) [concrete = constants.%U.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc30_18.2: <bound method> = bound_method %addr.loc30, %specific_fn.loc30
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call: init %Optional.738 = call %bound_method.loc30_18.2(%addr.loc30)
// CHECK:STDOUT:   %.loc30_18.1: init %Optional.738 = converted %addr.loc30, %U.as_type.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc30_18.2: ref %Optional.738 = temporary_storage
// CHECK:STDOUT:   %.loc30_18.3: ref %Optional.738 = temporary %.loc30_18.2, %.loc30_18.1
// CHECK:STDOUT:   %.loc30_18.4: %Optional.738 = acquire_value %.loc30_18.3
// CHECK:STDOUT:   %Use__carbon_thunk.call: init %i32 = call imports.%Use__carbon_thunk.decl(%.loc30_18.4)
// CHECK:STDOUT:   %Destroy.Op.bound.loc30: <bound method> = bound_method %.loc30_18.3, constants.%Destroy.Op.1a2547.5
// CHECK:STDOUT:   %Destroy.Op.call.loc30: init %empty_tuple.type = call %Destroy.Op.bound.loc30(%.loc30_18.3)
// CHECK:STDOUT:   %Destroy.Op.bound.loc29: <bound method> = bound_method %w.var, constants.%Destroy.Op.1a2547.1
// CHECK:STDOUT:   %Destroy.Op.call.loc29: init %empty_tuple.type = call %Destroy.Op.bound.loc29(%w.var)
// CHECK:STDOUT:   return %Use__carbon_thunk.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc30_18.1(%self.param: ref %.d0e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc30_18.2(%self.param: ref %MaybeUnformed.e77) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc30_18.3(%self.param: ref %Optional.738) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- static_method.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %CallZero.cpp_overload_set.type: type = cpp_overload_set_type @CallZero.cpp_overload_set [concrete]
// CHECK:STDOUT:   %CallZero.cpp_overload_set.value: %CallZero.cpp_overload_set.type = cpp_overload_set_value @CallZero.cpp_overload_set [concrete]
// CHECK:STDOUT:   %CallZero__carbon_thunk.type: type = fn_type @CallZero__carbon_thunk [concrete]
// CHECK:STDOUT:   %CallZero__carbon_thunk: %CallZero__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .CallZero = %CallZero.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %CallZero.cpp_overload_set.value: %CallZero.cpp_overload_set.type = cpp_overload_set_value @CallZero.cpp_overload_set [concrete = constants.%CallZero.cpp_overload_set.value]
// CHECK:STDOUT:   %CallZero__carbon_thunk.decl: %CallZero__carbon_thunk.type = fn_decl @CallZero__carbon_thunk [concrete = constants.%CallZero__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %CallZero.ref: %CallZero.cpp_overload_set.type = name_ref CallZero, imports.%CallZero.cpp_overload_set.value [concrete = constants.%CallZero.cpp_overload_set.value]
// CHECK:STDOUT:   %CallZero__carbon_thunk.call: init %i32 = call imports.%CallZero__carbon_thunk.decl()
// CHECK:STDOUT:   return %CallZero__carbon_thunk.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
