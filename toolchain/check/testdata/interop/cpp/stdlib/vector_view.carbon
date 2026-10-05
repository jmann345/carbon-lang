// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/vector_view.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/vector_view.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-9): owning C++ container ->
// `Core.Slice` view through the prelude's blanket
// `impl forall [C: CppContiguous ...] C as ImplicitAs(Slice(C.Element))`
// (core/prelude/types/cpp/slice.carbon) over the synthesized
// `CppContiguousRange` witness. The header mocks the member shape of
// `std::vector<int>` (D-SL-14; the real one is the conformance program's).
// `--target` pins `std::size_t` to `u64`. Positives only.
//
// If the hosted fill refutes the projection-in-interface-argument spelling
// (plan R-9 falsifier (ii): "no impl of `Core.ImplicitAs(Core.Slice(const
// i32))`"), the one-line contingency is the deducible-parameter spelling
// `impl forall [E: Copy & Destroy, C: CppContiguous where .Element = E] C as
// ImplicitAs(Slice(E))` (review fold rev B B9).

// --- vector_like.h

namespace std {
  using size_t = __SIZE_TYPE__;
}

class VectorLike {
 public:
  const int* data() const;
  int* data();
  std::size_t size() const;
};

class NonNullLike {
 public:
  const int* _Nonnull data() const;
  std::size_t size() const;
};

// --- view.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: view.carbon:[[@LINE+15]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./vector_like.h:8:12: warning: pointer is missing a nullability type specifier (_Nonnull, _Nullable, or _Null_unspecified) [CppInteropParseWarning]
// CHECK:STDERR:     8 |   const int* data() const;
// CHECK:STDERR:       |            ^
// CHECK:STDERR: view.carbon:[[@LINE+11]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./vector_like.h:8:12: note: insert '_Nullable' if the pointer may be null [CppInteropParseNote]
// CHECK:STDERR:     8 |   const int* data() const;
// CHECK:STDERR:       |            ^
// CHECK:STDERR:       |              _Nullable
// CHECK:STDERR: view.carbon:[[@LINE+6]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./vector_like.h:8:12: note: insert '_Nonnull' if the pointer should never be null [CppInteropParseNote]
// CHECK:STDERR:     8 |   const int* data() const;
// CHECK:STDERR:       |            ^
// CHECK:STDERR:       |              _Nonnull
// CHECK:STDERR:
import Cpp library "vector_like.h";

// Predicted: the blanket `ImplicitAs` witness over the synthesized
// `CppContiguousRange` witness (a `custom_witness` constant naming the `data`
// and `size` function decls); `data() const` is selected by the const filter
// and returns `Optional(const i32*)`, so `CppDataPointer` is the
// `Optional(T*)` impl and `Element` is `const i32`; the size converts in two
// steps, `ImplicitAs(u64)` (the as.carbon identity on `u64`) then `As(i64)`.
//@dump-sem-ir-begin
fn View(v: Cpp.VectorLike) -> Core.Slice(const i32) {
  // CHECK:STDERR: view.carbon:[[@LINE+7]]:3: error: cannot implicitly convert expression of type `Cpp.VectorLike` to `Core.Slice(const i32 as Core.Destroy & Core.Copy)` [ConversionFailure]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR: view.carbon:[[@LINE+4]]:3: note: type `Cpp.VectorLike` does not implement interface `Core.ImplicitAs(Core.Slice(const i32 as Core.Destroy & Core.Copy))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
  return v;
}
//@dump-sem-ir-end

// --- nonnull_data.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: nonnull_data.carbon:[[@LINE+15]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./vector_like.h:8:12: warning: pointer is missing a nullability type specifier (_Nonnull, _Nullable, or _Null_unspecified) [CppInteropParseWarning]
// CHECK:STDERR:     8 |   const int* data() const;
// CHECK:STDERR:       |            ^
// CHECK:STDERR: nonnull_data.carbon:[[@LINE+11]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./vector_like.h:8:12: note: insert '_Nullable' if the pointer may be null [CppInteropParseNote]
// CHECK:STDERR:     8 |   const int* data() const;
// CHECK:STDERR:       |            ^
// CHECK:STDERR:       |              _Nullable
// CHECK:STDERR: nonnull_data.carbon:[[@LINE+6]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./vector_like.h:8:12: note: insert '_Nonnull' if the pointer should never be null [CppInteropParseNote]
// CHECK:STDERR:     8 |   const int* data() const;
// CHECK:STDERR:       |            ^
// CHECK:STDERR:       |              _Nonnull
// CHECK:STDERR:
import Cpp library "vector_like.h";

// Predicted: `data()` returns `const i32*` (a `_Nonnull` pointer imports
// without `Optional`), so `CppDataPointer` is the `T*` impl; otherwise as
// `view.carbon`.
//@dump-sem-ir-begin
fn ViewNonNull(v: Cpp.NonNullLike) -> Core.Slice(const i32) {
  // CHECK:STDERR: nonnull_data.carbon:[[@LINE+7]]:3: error: cannot implicitly convert expression of type `Cpp.NonNullLike` to `Core.Slice(const i32 as Core.Destroy & Core.Copy)` [ConversionFailure]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR: nonnull_data.carbon:[[@LINE+4]]:3: note: type `Cpp.NonNullLike` does not implement interface `Core.ImplicitAs(Core.Slice(const i32 as Core.Destroy & Core.Copy))` [MissingImplInMemberAccessInContext]
  // CHECK:STDERR:   return v;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
  return v;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- view.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %VectorLike: type = class_type @VectorLike [concrete]
// CHECK:STDOUT:   %pattern_type.62c: type = pattern_type %VectorLike [concrete]
// CHECK:STDOUT:   %v.param_patt: %pattern_type.62c = value_param_pattern [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.62c = wrapper_binding_pattern v, %v.param_patt [concrete]
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.loc13_51.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.3: %Destroy.Op.type.1d8f74.3 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.3: <witness> = custom_witness (%Destroy.Op.1a2547.3), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.ae2: <witness> = impl_witness imports.%Copy.impl_witness_table.aca, @const.as.Copy.impl(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %facet_value.d9e: %facet_type.f48 = facet_value %const.6a8, (%custom_witness.df9cc1.3, %Copy.impl_witness.ae2) [concrete]
// CHECK:STDOUT:   %Slice.2ea: type = class_type @Slice, @Slice(%facet_value.d9e) [concrete]
// CHECK:STDOUT:   %.3e4: Core.Form = init_form %Slice.2ea [concrete]
// CHECK:STDOUT:   %pattern_type.86d: type = pattern_type %Slice.2ea [concrete]
// CHECK:STDOUT:   %return.param_patt.22d: %pattern_type.86d = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.658: %pattern_type.86d = return_slot_pattern %return.param_patt.22d, %Slice.2ea [concrete]
// CHECK:STDOUT:   %View.type: type = fn_type @View [concrete]
// CHECK:STDOUT:   %View: %View.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .VectorLike = %VectorLike.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %VectorLike.decl: type = class_decl @VectorLike [concrete = constants.%VectorLike] {} {}
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.94c = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.aca = impl_witness_table (%Core.import_ref.94c), @const.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %View.decl: %View.type = fn_decl @View [concrete = constants.%View] {
// CHECK:STDOUT:     %v.param_patt: %pattern_type.62c = value_param_pattern [concrete = constants.%v.param_patt]
// CHECK:STDOUT:     %v.patt: %pattern_type.62c = wrapper_binding_pattern v, %v.param_patt [concrete = constants.%v.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.86d = out_param_pattern [concrete = constants.%return.param_patt.22d]
// CHECK:STDOUT:     %return.patt: %pattern_type.86d = return_slot_pattern %return.param_patt, %Slice [concrete = constants.%return.patt.658]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %const: type = const_type %i32 [concrete = constants.%const.6a8]
// CHECK:STDOUT:     %facet_value: %facet_type.f48 = facet_value %const, (constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2) [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %.loc13_51.1: %facet_type.f48 = converted %const, %facet_value [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %Slice: type = class_type @Slice, @Slice(constants.%facet_value.d9e) [concrete = constants.%Slice.2ea]
// CHECK:STDOUT:     %.loc13_51.2: Core.Form = init_form %Slice [concrete = constants.%.3e4]
// CHECK:STDOUT:     %v.param: %VectorLike = value_param call_param0
// CHECK:STDOUT:     %.loc13_15: type = splice_block %VectorLike.ref [concrete = constants.%VectorLike] {
// CHECK:STDOUT:       %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %VectorLike.ref: type = name_ref VectorLike, imports.%VectorLike.decl [concrete = constants.%VectorLike]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v: %VectorLike = wrapper_binding v, %v.param
// CHECK:STDOUT:     %return.param: ref %Slice.2ea = out_param call_param1
// CHECK:STDOUT:     %return: ref %Slice.2ea = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_51.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_51.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_51.3(%self.param: ref %const.6a8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @View(%v.param: %VectorLike) -> out %return.param: %Slice.2ea {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.ref: %VectorLike = name_ref v, %v
// CHECK:STDOUT:   %.loc14: %Slice.2ea = converted %v.ref, <error> [concrete = <error>]
// CHECK:STDOUT:   return <error> to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- nonnull_data.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %NonNullLike: type = class_type @NonNullLike [concrete]
// CHECK:STDOUT:   %pattern_type.c6d: type = pattern_type %NonNullLike [concrete]
// CHECK:STDOUT:   %v.param_patt: %pattern_type.c6d = value_param_pattern [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.c6d = wrapper_binding_pattern v, %v.param_patt [concrete]
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.loc10_59.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.3: %Destroy.Op.type.1d8f74.3 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.3: <witness> = custom_witness (%Destroy.Op.1a2547.3), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.ae2: <witness> = impl_witness imports.%Copy.impl_witness_table.aca, @const.as.Copy.impl(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %facet_value.d9e: %facet_type.f48 = facet_value %const.6a8, (%custom_witness.df9cc1.3, %Copy.impl_witness.ae2) [concrete]
// CHECK:STDOUT:   %Slice.2ea: type = class_type @Slice, @Slice(%facet_value.d9e) [concrete]
// CHECK:STDOUT:   %.3e4: Core.Form = init_form %Slice.2ea [concrete]
// CHECK:STDOUT:   %pattern_type.86d: type = pattern_type %Slice.2ea [concrete]
// CHECK:STDOUT:   %return.param_patt.22d: %pattern_type.86d = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.658: %pattern_type.86d = return_slot_pattern %return.param_patt.22d, %Slice.2ea [concrete]
// CHECK:STDOUT:   %ViewNonNull.type: type = fn_type @ViewNonNull [concrete]
// CHECK:STDOUT:   %ViewNonNull: %ViewNonNull.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .NonNullLike = %NonNullLike.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %NonNullLike.decl: type = class_decl @NonNullLike [concrete = constants.%NonNullLike] {} {}
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.94c = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.aca = impl_witness_table (%Core.import_ref.94c), @const.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %ViewNonNull.decl: %ViewNonNull.type = fn_decl @ViewNonNull [concrete = constants.%ViewNonNull] {
// CHECK:STDOUT:     %v.param_patt: %pattern_type.c6d = value_param_pattern [concrete = constants.%v.param_patt]
// CHECK:STDOUT:     %v.patt: %pattern_type.c6d = wrapper_binding_pattern v, %v.param_patt [concrete = constants.%v.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.86d = out_param_pattern [concrete = constants.%return.param_patt.22d]
// CHECK:STDOUT:     %return.patt: %pattern_type.86d = return_slot_pattern %return.param_patt, %Slice [concrete = constants.%return.patt.658]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %const: type = const_type %i32 [concrete = constants.%const.6a8]
// CHECK:STDOUT:     %facet_value: %facet_type.f48 = facet_value %const, (constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2) [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %.loc10_59.1: %facet_type.f48 = converted %const, %facet_value [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %Slice: type = class_type @Slice, @Slice(constants.%facet_value.d9e) [concrete = constants.%Slice.2ea]
// CHECK:STDOUT:     %.loc10_59.2: Core.Form = init_form %Slice [concrete = constants.%.3e4]
// CHECK:STDOUT:     %v.param: %NonNullLike = value_param call_param0
// CHECK:STDOUT:     %.loc10_22: type = splice_block %NonNullLike.ref [concrete = constants.%NonNullLike] {
// CHECK:STDOUT:       %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %NonNullLike.ref: type = name_ref NonNullLike, imports.%NonNullLike.decl [concrete = constants.%NonNullLike]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v: %NonNullLike = wrapper_binding v, %v.param
// CHECK:STDOUT:     %return.param: ref %Slice.2ea = out_param call_param1
// CHECK:STDOUT:     %return: ref %Slice.2ea = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc10_59.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc10_59.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc10_59.3(%self.param: ref %const.6a8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @ViewNonNull(%v.param: %NonNullLike) -> out %return.param: %Slice.2ea {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.ref: %NonNullLike = name_ref v, %v
// CHECK:STDOUT:   %.loc11: %Slice.2ea = converted %v.ref, <error> [concrete = <error>]
// CHECK:STDOUT:   return <error> to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
