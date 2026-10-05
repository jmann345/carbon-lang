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

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-9): owning C++ container ->
// `Core.Slice` view through the prelude's blanket
// `impl forall [C: CppContiguous ...] C as ImplicitAs(Slice(C.Element))`
// (core/prelude/types/slice.carbon, beside `Slice`, over the helpers of
// core/prelude/types/cpp/slice.carbon) and the synthesized
// `CppContiguousRange` witness. The header mocks the member shape of
// `std::vector<int>` (D-SL-14; the real one is the conformance program's),
// nullability-complete so that the dump carries no Clang warning. `--target`
// pins `std::size_t` to `unsigned long`, which imports as `u64` on
// x86_64-linux-gnu (`uint64_t` is `unsigned long` there, import.cpp
// `MapBuiltinIntegerType`; `Core.CppCompat.ULong64` is its Darwin import).
// Positives only.
//
// The projection `C.Element` in the interface argument is the shape of
// impl/lookup/access.carbon (`impl forall [T: Z where .Z1 impls Y] T as
// X(T.Z1.(Y.Y1))`, a concrete query resolving through two nested
// `ImplWitnessAccess`es), so the deducible-parameter spelling of review fold
// rev B B9 is not needed (plan R-9, amended at the round-1 fix).

// --- vector_like.h

namespace std {
  using size_t = __SIZE_TYPE__;
}

class VectorLike {
 public:
  const int* _Nullable data() const;
  int* _Nullable data();
  std::size_t size() const;
};

class NonNullLike {
 public:
  const int* _Nonnull data() const;
  std::size_t size() const;
};

// --- view.carbon

library "[[@TEST_NAME]]";

import Cpp library "vector_like.h";

// Predicted: the blanket `ImplicitAs` witness over the synthesized
// `CppContiguousRange` witness (a `custom_witness` constant naming the `data`
// and `size` function decls); `data() const` is selected by the const filter
// and returns `Optional(const i32*)`, so `CppDataPointer` is the
// `Optional(T*)` impl and `Element` is `const i32`; the size (`u64` under the
// `--target` pin) converts through `CppSizeToI64` -- `u64 as ImplicitAs(u64)`,
// which the first two fills showed resolving to uint.carbon's `UInt(From) as
// ImplicitAs(To)` over `FromUInt(u64)` (`AnyUInt & IntFitsIn(u64)`), not to
// as.carbon's `T: Copy` identity -- then `u64 as As(i64)` (uint.carbon's final
// impl); on Darwin the first step would be cpp/int.carbon's `final impl
// CppCompat.ULong64 as ImplicitAs(u64)`. The `Data()`/`Size()` temporaries
// destroy through the `CppContiguous` constraint's `Destroy` requirements.
//@dump-sem-ir-begin
fn View(v: Cpp.VectorLike) -> Core.Slice(const i32) {
  return v;
}
//@dump-sem-ir-end

// --- nonnull_data.carbon

library "[[@TEST_NAME]]";

import Cpp library "vector_like.h";

// Predicted: `data()` returns `const i32*` (a `_Nonnull` pointer imports
// without `Optional`), so `CppDataPointer` is the `T*` impl; otherwise as
// `view.carbon`.
//@dump-sem-ir-begin
fn ViewNonNull(v: Cpp.NonNullLike) -> Core.Slice(const i32) {
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
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.loc19_51.3 [concrete]
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
// CHECK:STDOUT:   %ptr.774: type = ptr_type %const.6a8 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.8bf: type = facet_type <@ImplicitAs, @ImplicitAs(%Slice.2ea)> [concrete]
// CHECK:STDOUT:   %From.fe9: Core.IntLiteral = symbolic_binding From, 0 [symbolic]
// CHECK:STDOUT:   %CppContiguous.type: type = facet_type <@CppContiguous> [concrete]
// CHECK:STDOUT:   %.Self.e0b: %CppContiguous.type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %CppContiguousRange.lookup_impl_witness.a5e: <witness> = lookup_impl_witness %.Self.e0b, @CppContiguousRange [symbolic_self]
// CHECK:STDOUT:   %impl.elem0.d25: type = impl_witness_access %CppContiguousRange.lookup_impl_witness.a5e, element0 [symbolic_self]
// CHECK:STDOUT:   %CppDataPointer.lookup_impl_witness.700: <witness> = lookup_impl_witness %impl.elem0.d25, @CppDataPointer [symbolic_self]
// CHECK:STDOUT:   %impl.elem0.5cb: type = impl_witness_access %CppDataPointer.lookup_impl_witness.700, element0 [symbolic_self]
// CHECK:STDOUT:   %CppContiguous_where.type.d682d6.1: type = facet_type <@CppContiguous where %impl.elem0.5cb impls @Destroy and %impl.elem0.5cb impls @Copy> [concrete]
// CHECK:STDOUT:   %C: %CppContiguous_where.type.d682d6.1 = symbolic_binding C, 0 [symbolic]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.type.72c: type = fn_type @C.as_type.as.ImplicitAs.impl.Convert, @C.as_type.as.ImplicitAs.impl(%C) [symbolic]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.9f0: %C.as_type.as.ImplicitAs.impl.Convert.type.72c = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.type.015: type = fn_type @ptr.as.OptionalStorage.impl.Get, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.972: %ptr.as.OptionalStorage.impl.Get.type.015 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.1 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.4: <witness> = custom_witness (%Destroy.Op.1a2547.4), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.caa: %Destroy.type = facet_value %ptr.774, (%custom_witness.df9cc1.4) [concrete]
// CHECK:STDOUT:   %MaybeUnformed.416: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.caa) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.a99: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%const.6a8) [concrete]
// CHECK:STDOUT:   %.f60: type = maybe_unformed_type %ptr.774 [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.d3d: %OptionalStorage.type = facet_value %ptr.774, (%OptionalStorage.impl_witness.a99) [concrete]
// CHECK:STDOUT:   %Optional.f0c: type = class_type @Optional, @Optional(%OptionalStorage.facet.d3d) [concrete]
// CHECK:STDOUT:   %UInt.type: type = generic_class_type @UInt [concrete]
// CHECK:STDOUT:   %UInt.generic: %UInt.type = struct_value () [concrete]
// CHECK:STDOUT:   %u64: type = class_type @UInt, @UInt(%int_64) [concrete]
// CHECK:STDOUT:   %u64.builtin: type = int_type unsigned, %int_64 [concrete]
// CHECK:STDOUT:   %VectorLike.Data.type: type = fn_type @VectorLike.Data [concrete]
// CHECK:STDOUT:   %VectorLike.Data: %VectorLike.Data.type = struct_value () [concrete]
// CHECK:STDOUT:   %VectorLike.Size.type: type = fn_type @VectorLike.Size [concrete]
// CHECK:STDOUT:   %VectorLike.Size: %VectorLike.Size.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.dd1: <witness> = custom_witness (%Optional.f0c, %u64, %VectorLike.Data, %VectorLike.Size), @CppContiguousRange [concrete]
// CHECK:STDOUT:   %Optional.as.CppDataPointer.impl.Raw.type.2db: type = fn_type @Optional.as.CppDataPointer.impl.Raw, @Optional.as.CppDataPointer.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %Optional.as.CppDataPointer.impl.Raw.cea: %Optional.as.CppDataPointer.impl.Raw.type.2db = struct_value () [symbolic]
// CHECK:STDOUT:   %CppDataPointer.impl_witness.2da: <witness> = impl_witness imports.%CppDataPointer.impl_witness_table.b0a, @Optional.as.CppDataPointer.impl(%const.6a8) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.7: type = fn_type @Destroy.Op.loc20_11.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.7: %Destroy.Op.type.1d8f74.7 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.7: <witness> = custom_witness (%Destroy.Op.1a2547.7), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.9: type = fn_type @Destroy.Op.loc20_11.5 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.9: %Destroy.Op.type.1d8f74.9 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.9: <witness> = custom_witness (%Destroy.Op.1a2547.9), @Destroy [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.14f: type = facet_type <@ImplicitAs, @ImplicitAs(%u64)> [concrete]
// CHECK:STDOUT:   %T.553: %ImplicitAs.type.14f = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.CppSizeToI64.impl.Op.type.e69: type = fn_type @T.as_type.as.CppSizeToI64.impl.Op, @T.as_type.as.CppSizeToI64.impl(%T.553) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.CppSizeToI64.impl.Op.2e8: %T.as_type.as.CppSizeToI64.impl.Op.type.e69 = struct_value () [symbolic]
// CHECK:STDOUT:   %UInt.e8a755.2: type = class_type @UInt, @UInt(%To.fe9) [symbolic]
// CHECK:STDOUT:   %UInt.e8a755.3: type = class_type @UInt, @UInt(%From.fe9) [symbolic]
// CHECK:STDOUT:   %FromUInt.type.9b3: type = facet_type <@FromUInt, @FromUInt(%UInt.e8a755.3)> [symbolic]
// CHECK:STDOUT:   %To.dc6: %FromUInt.type.9b3 = symbolic_binding To, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.ImplicitAs.impl.Convert.type.181: type = fn_type @UInt.as.ImplicitAs.impl.Convert.2, @UInt.as.ImplicitAs.impl.2da(%From.fe9, %To.dc6) [symbolic]
// CHECK:STDOUT:   %UInt.as.ImplicitAs.impl.Convert.cd1: %UInt.as.ImplicitAs.impl.Convert.type.181 = struct_value () [symbolic]
// CHECK:STDOUT:   %FromUInt.type.af0: type = facet_type <@FromUInt, @FromUInt(%u64)> [concrete]
// CHECK:STDOUT:   %facet_type.521: type = facet_type <@IntFitsIn, @IntFitsIn(%UInt.e8a755.2) & @AnyUInt> [symbolic]
// CHECK:STDOUT:   %From.cb2: %facet_type.521 = symbolic_binding From, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.FromUInt.impl.Convert.type.9ef: type = fn_type @UInt.as.FromUInt.impl.Convert, @UInt.as.FromUInt.impl(%To.fe9, %From.cb2) [symbolic]
// CHECK:STDOUT:   %UInt.as.FromUInt.impl.Convert.131: %UInt.as.FromUInt.impl.Convert.type.9ef = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.d9f: type = facet_type <@IntFitsIn, @IntFitsIn(%u64) & @AnyUInt> [concrete]
// CHECK:STDOUT:   %custom_witness.83a: <witness> = custom_witness (), @IntFitsIn, @IntFitsIn(%u64) [concrete]
// CHECK:STDOUT:   %UInt.as.AnyUInt.impl.AsUInt.type.d0f: type = fn_type @UInt.as.AnyUInt.impl.AsUInt, @UInt.as.AnyUInt.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %UInt.as.AnyUInt.impl.AsUInt.a74: %UInt.as.AnyUInt.impl.AsUInt.type.d0f = struct_value () [symbolic]
// CHECK:STDOUT:   %AnyUInt.impl_witness.a7a: <witness> = impl_witness imports.%AnyUInt.impl_witness_table, @UInt.as.AnyUInt.impl(%int_64) [concrete]
// CHECK:STDOUT:   %facet_value.d61: %facet_type.d9f = facet_value %u64, (%custom_witness.83a, %AnyUInt.impl_witness.a7a) [concrete]
// CHECK:STDOUT:   %FromUInt.impl_witness.8d0: <witness> = impl_witness imports.%FromUInt.impl_witness_table.be0, @UInt.as.FromUInt.impl(%int_64, %facet_value.d61) [concrete]
// CHECK:STDOUT:   %FromUInt.facet: %FromUInt.type.af0 = facet_value %u64, (%FromUInt.impl_witness.8d0) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.cbe: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.217, @UInt.as.ImplicitAs.impl.2da(%int_64, %FromUInt.facet) [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.41e: %ImplicitAs.type.14f = facet_value %u64, (%ImplicitAs.impl_witness.cbe) [concrete]
// CHECK:STDOUT:   %CppSizeToI64.impl_witness.da2: <witness> = impl_witness imports.%CppSizeToI64.impl_witness_table, @T.as_type.as.CppSizeToI64.impl(%ImplicitAs.facet.41e) [concrete]
// CHECK:STDOUT:   %facet_value.d41: %CppContiguous_where.type.d682d6.1 = facet_value %VectorLike, (%custom_witness.dd1, %custom_witness.df9cc1.3, %Copy.impl_witness.ae2, %custom_witness.df9cc1.7, %CppDataPointer.impl_witness.2da, %custom_witness.df9cc1.9, %CppSizeToI64.impl_witness.da2) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.359: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.bbb, @C.as_type.as.ImplicitAs.impl(%facet_value.d41) [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.type.e48: type = fn_type @C.as_type.as.ImplicitAs.impl.Convert, @C.as_type.as.ImplicitAs.impl(%facet_value.d41) [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.c81: %C.as_type.as.ImplicitAs.impl.Convert.type.e48 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.001: %ImplicitAs.type.8bf = facet_value %VectorLike, (%ImplicitAs.impl_witness.359) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.6fa: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%Slice.2ea, %ImplicitAs.facet.001) [concrete]
// CHECK:STDOUT:   %.0b5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.6fa, %ImplicitAs.facet.001 [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %C.as_type.as.ImplicitAs.impl.Convert.c81, @C.as_type.as.ImplicitAs.impl.Convert(%facet_value.d41) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .UInt = %Core.UInt
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
// CHECK:STDOUT:   %Core.import_ref.465: @C.as_type.as.ImplicitAs.impl.%C.as_type.as.ImplicitAs.impl.Convert.type (%C.as_type.as.ImplicitAs.impl.Convert.type.72c) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @C.as_type.as.ImplicitAs.impl.%C.as_type.as.ImplicitAs.impl.Convert (constants.%C.as_type.as.ImplicitAs.impl.Convert.9f0)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.bbb = impl_witness_table (%Core.import_ref.465), @C.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.509: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%MaybeUnformed (constants.%MaybeUnformed.ddb)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c9a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.a90 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.008: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get.type (%ptr.as.OptionalStorage.impl.Get.type.015) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get (constants.%ptr.as.OptionalStorage.impl.Get.972)]
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.509, %Core.import_ref.105, %Core.import_ref.c9a, %Core.import_ref.a90, %Core.import_ref.008, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.UInt: %UInt.type = import_ref Core//prelude/types/uint, UInt, loaded [concrete = constants.%UInt.generic]
// CHECK:STDOUT:   %Core.import_ref.6f1: type = import_ref Core//prelude/types/cpp/slice, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.CppDataPointer.impl.%T (constants.%T.67d)]
// CHECK:STDOUT:   %Core.import_ref.8e2: @Optional.as.CppDataPointer.impl.%Optional.as.CppDataPointer.impl.Raw.type (%Optional.as.CppDataPointer.impl.Raw.type.2db) = import_ref Core//prelude/types/cpp/slice, loc{{\d+_\d+}}, loaded [symbolic = @Optional.as.CppDataPointer.impl.%Optional.as.CppDataPointer.impl.Raw (constants.%Optional.as.CppDataPointer.impl.Raw.cea)]
// CHECK:STDOUT:   %CppDataPointer.impl_witness_table.b0a = impl_witness_table (%Core.import_ref.6f1, %Core.import_ref.8e2), @Optional.as.CppDataPointer.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.56d: @T.as_type.as.CppSizeToI64.impl.%T.as_type.as.CppSizeToI64.impl.Op.type (%T.as_type.as.CppSizeToI64.impl.Op.type.e69) = import_ref Core//prelude/types/cpp/slice, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.CppSizeToI64.impl.%T.as_type.as.CppSizeToI64.impl.Op (constants.%T.as_type.as.CppSizeToI64.impl.Op.2e8)]
// CHECK:STDOUT:   %CppSizeToI64.impl_witness_table = impl_witness_table (%Core.import_ref.56d), @T.as_type.as.CppSizeToI64.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b7b: @UInt.as.ImplicitAs.impl.2da.%UInt.as.ImplicitAs.impl.Convert.type (%UInt.as.ImplicitAs.impl.Convert.type.181) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.ImplicitAs.impl.2da.%UInt.as.ImplicitAs.impl.Convert (constants.%UInt.as.ImplicitAs.impl.Convert.cd1)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.217 = impl_witness_table (%Core.import_ref.b7b), @UInt.as.ImplicitAs.impl.2da [concrete]
// CHECK:STDOUT:   %Core.import_ref.ab07f: @UInt.as.FromUInt.impl.%UInt.as.FromUInt.impl.Convert.type (%UInt.as.FromUInt.impl.Convert.type.9ef) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.FromUInt.impl.%UInt.as.FromUInt.impl.Convert (constants.%UInt.as.FromUInt.impl.Convert.131)]
// CHECK:STDOUT:   %FromUInt.impl_witness_table.be0 = impl_witness_table (%Core.import_ref.ab07f), @UInt.as.FromUInt.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.47b: Core.IntLiteral = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.AnyUInt.impl.%N (constants.%N.fe9)]
// CHECK:STDOUT:   %Core.import_ref.589: @UInt.as.AnyUInt.impl.%UInt.as.AnyUInt.impl.AsUInt.type (%UInt.as.AnyUInt.impl.AsUInt.type.d0f) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.AnyUInt.impl.%UInt.as.AnyUInt.impl.AsUInt (constants.%UInt.as.AnyUInt.impl.AsUInt.a74)]
// CHECK:STDOUT:   %AnyUInt.impl_witness_table = impl_witness_table (%Core.import_ref.47b, %Core.import_ref.589), @UInt.as.AnyUInt.impl [concrete]
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
// CHECK:STDOUT:     %facet_value.loc19: %facet_type.f48 = facet_value %const, (constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2) [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %.loc19_51.2: %facet_type.f48 = converted %const, %facet_value.loc19 [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %Slice: type = class_type @Slice, @Slice(constants.%facet_value.d9e) [concrete = constants.%Slice.2ea]
// CHECK:STDOUT:     %.loc19_51.3: Core.Form = init_form %Slice [concrete = constants.%.3e4]
// CHECK:STDOUT:     %v.param: %VectorLike = value_param call_param0
// CHECK:STDOUT:     %.loc19_15: type = splice_block %VectorLike.ref [concrete = constants.%VectorLike] {
// CHECK:STDOUT:       %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %VectorLike.ref: type = name_ref VectorLike, imports.%VectorLike.decl [concrete = constants.%VectorLike]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v: %VectorLike = wrapper_binding v, %v.param
// CHECK:STDOUT:     %return.param: ref %Slice.2ea = out_param call_param1
// CHECK:STDOUT:     %return: ref %Slice.2ea = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc19_51.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc19_51.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc19_51.3(%self.param: ref %const.6a8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @View(%v.param: %VectorLike) -> out %return.param: %Slice.2ea {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.ref: %VectorLike = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0: %.0b5 = impl_witness_access constants.%ImplicitAs.impl_witness.359, element0 [concrete = constants.%C.as_type.as.ImplicitAs.impl.Convert.c81]
// CHECK:STDOUT:   %bound_method.loc20_11.1: <bound method> = bound_method %v.ref, %impl.elem0
// CHECK:STDOUT:   %facet_value.loc20_11.1: %CppContiguous_where.type.d682d6.1 = facet_value constants.%VectorLike, (constants.%custom_witness.dd1, constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2, constants.%custom_witness.df9cc1.7, constants.%CppDataPointer.impl_witness.2da, constants.%custom_witness.df9cc1.9, constants.%CppSizeToI64.impl_witness.da2) [concrete = constants.%facet_value.d41]
// CHECK:STDOUT:   %.loc20_11.1: %CppContiguous_where.type.d682d6.1 = converted constants.%VectorLike, %facet_value.loc20_11.1 [concrete = constants.%facet_value.d41]
// CHECK:STDOUT:   %facet_value.loc20_11.2: %CppContiguous_where.type.d682d6.1 = facet_value constants.%VectorLike, (constants.%custom_witness.dd1, constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2, constants.%custom_witness.df9cc1.7, constants.%CppDataPointer.impl_witness.2da, constants.%custom_witness.df9cc1.9, constants.%CppSizeToI64.impl_witness.da2) [concrete = constants.%facet_value.d41]
// CHECK:STDOUT:   %.loc20_11.2: %CppContiguous_where.type.d682d6.1 = converted constants.%VectorLike, %facet_value.loc20_11.2 [concrete = constants.%facet_value.d41]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @C.as_type.as.ImplicitAs.impl.Convert(constants.%facet_value.d41) [concrete = constants.%C.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc20_11.2: <bound method> = bound_method %v.ref, %specific_fn
// CHECK:STDOUT:   %.loc19_51.1: ref %Slice.2ea = splice_block %return.param {}
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.call: init %Slice.2ea to %.loc19_51.1 = call %bound_method.loc20_11.2(%v.ref)
// CHECK:STDOUT:   %.loc20_11.3: init %Slice.2ea = converted %v.ref, %C.as_type.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   return %.loc20_11.3 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc20_11.1(%self.param: ref %.f60) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc20_11.2(%self.param: ref %MaybeUnformed.416) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc20_11.3(%self.param: ref %Optional.f0c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc20_11.4(%self.param: ref %u64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc20_11.5(%self.param: ref %u64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
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
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
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
// CHECK:STDOUT:   %ptr.774: type = ptr_type %const.6a8 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.8bf: type = facet_type <@ImplicitAs, @ImplicitAs(%Slice.2ea)> [concrete]
// CHECK:STDOUT:   %From.fe9: Core.IntLiteral = symbolic_binding From, 0 [symbolic]
// CHECK:STDOUT:   %CppContiguous.type: type = facet_type <@CppContiguous> [concrete]
// CHECK:STDOUT:   %.Self.e0b: %CppContiguous.type = symbolic_binding .Self [symbolic_self]
// CHECK:STDOUT:   %CppContiguousRange.lookup_impl_witness.a5e: <witness> = lookup_impl_witness %.Self.e0b, @CppContiguousRange [symbolic_self]
// CHECK:STDOUT:   %impl.elem0.d25: type = impl_witness_access %CppContiguousRange.lookup_impl_witness.a5e, element0 [symbolic_self]
// CHECK:STDOUT:   %CppDataPointer.lookup_impl_witness.700: <witness> = lookup_impl_witness %impl.elem0.d25, @CppDataPointer [symbolic_self]
// CHECK:STDOUT:   %impl.elem0.5cb: type = impl_witness_access %CppDataPointer.lookup_impl_witness.700, element0 [symbolic_self]
// CHECK:STDOUT:   %CppContiguous_where.type.d682d6.1: type = facet_type <@CppContiguous where %impl.elem0.5cb impls @Destroy and %impl.elem0.5cb impls @Copy> [concrete]
// CHECK:STDOUT:   %C: %CppContiguous_where.type.d682d6.1 = symbolic_binding C, 0 [symbolic]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.type.72c: type = fn_type @C.as_type.as.ImplicitAs.impl.Convert, @C.as_type.as.ImplicitAs.impl(%C) [symbolic]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.9f0: %C.as_type.as.ImplicitAs.impl.Convert.type.72c = struct_value () [symbolic]
// CHECK:STDOUT:   %UInt.type: type = generic_class_type @UInt [concrete]
// CHECK:STDOUT:   %UInt.generic: %UInt.type = struct_value () [concrete]
// CHECK:STDOUT:   %u64: type = class_type @UInt, @UInt(%int_64) [concrete]
// CHECK:STDOUT:   %u64.builtin: type = int_type unsigned, %int_64 [concrete]
// CHECK:STDOUT:   %NonNullLike.Data.type: type = fn_type @NonNullLike.Data [concrete]
// CHECK:STDOUT:   %NonNullLike.Data: %NonNullLike.Data.type = struct_value () [concrete]
// CHECK:STDOUT:   %NonNullLike.Size.type: type = fn_type @NonNullLike.Size [concrete]
// CHECK:STDOUT:   %NonNullLike.Size: %NonNullLike.Size.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.e02: <witness> = custom_witness (%ptr.774, %u64, %NonNullLike.Data, %NonNullLike.Size), @CppContiguousRange [concrete]
// CHECK:STDOUT:   %ptr.as.CppDataPointer.impl.Raw.type.414: type = fn_type @ptr.as.CppDataPointer.impl.Raw, @ptr.as.CppDataPointer.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.CppDataPointer.impl.Raw.945: %ptr.as.CppDataPointer.impl.Raw.type.414 = struct_value () [symbolic]
// CHECK:STDOUT:   %CppDataPointer.impl_witness.44c: <witness> = impl_witness imports.%CppDataPointer.impl_witness_table.eaf, @ptr.as.CppDataPointer.impl(%const.6a8) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.loc11_11.1 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.4: <witness> = custom_witness (%Destroy.Op.1a2547.4), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.6: type = fn_type @Destroy.Op.loc11_11.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.6: %Destroy.Op.type.1d8f74.6 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.6: <witness> = custom_witness (%Destroy.Op.1a2547.6), @Destroy [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.14f: type = facet_type <@ImplicitAs, @ImplicitAs(%u64)> [concrete]
// CHECK:STDOUT:   %T.553: %ImplicitAs.type.14f = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.CppSizeToI64.impl.Op.type.e69: type = fn_type @T.as_type.as.CppSizeToI64.impl.Op, @T.as_type.as.CppSizeToI64.impl(%T.553) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.CppSizeToI64.impl.Op.2e8: %T.as_type.as.CppSizeToI64.impl.Op.type.e69 = struct_value () [symbolic]
// CHECK:STDOUT:   %UInt.e8a755.2: type = class_type @UInt, @UInt(%To.fe9) [symbolic]
// CHECK:STDOUT:   %UInt.e8a755.3: type = class_type @UInt, @UInt(%From.fe9) [symbolic]
// CHECK:STDOUT:   %FromUInt.type.9b3: type = facet_type <@FromUInt, @FromUInt(%UInt.e8a755.3)> [symbolic]
// CHECK:STDOUT:   %To.dc6: %FromUInt.type.9b3 = symbolic_binding To, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.ImplicitAs.impl.Convert.type.181: type = fn_type @UInt.as.ImplicitAs.impl.Convert.2, @UInt.as.ImplicitAs.impl.2da(%From.fe9, %To.dc6) [symbolic]
// CHECK:STDOUT:   %UInt.as.ImplicitAs.impl.Convert.cd1: %UInt.as.ImplicitAs.impl.Convert.type.181 = struct_value () [symbolic]
// CHECK:STDOUT:   %FromUInt.type.af0: type = facet_type <@FromUInt, @FromUInt(%u64)> [concrete]
// CHECK:STDOUT:   %facet_type.521: type = facet_type <@IntFitsIn, @IntFitsIn(%UInt.e8a755.2) & @AnyUInt> [symbolic]
// CHECK:STDOUT:   %From.cb2: %facet_type.521 = symbolic_binding From, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.FromUInt.impl.Convert.type.9ef: type = fn_type @UInt.as.FromUInt.impl.Convert, @UInt.as.FromUInt.impl(%To.fe9, %From.cb2) [symbolic]
// CHECK:STDOUT:   %UInt.as.FromUInt.impl.Convert.131: %UInt.as.FromUInt.impl.Convert.type.9ef = struct_value () [symbolic]
// CHECK:STDOUT:   %facet_type.d9f: type = facet_type <@IntFitsIn, @IntFitsIn(%u64) & @AnyUInt> [concrete]
// CHECK:STDOUT:   %custom_witness.83a: <witness> = custom_witness (), @IntFitsIn, @IntFitsIn(%u64) [concrete]
// CHECK:STDOUT:   %UInt.as.AnyUInt.impl.AsUInt.type.d0f: type = fn_type @UInt.as.AnyUInt.impl.AsUInt, @UInt.as.AnyUInt.impl(%N.fe9) [symbolic]
// CHECK:STDOUT:   %UInt.as.AnyUInt.impl.AsUInt.a74: %UInt.as.AnyUInt.impl.AsUInt.type.d0f = struct_value () [symbolic]
// CHECK:STDOUT:   %AnyUInt.impl_witness.a7a: <witness> = impl_witness imports.%AnyUInt.impl_witness_table, @UInt.as.AnyUInt.impl(%int_64) [concrete]
// CHECK:STDOUT:   %facet_value.d61: %facet_type.d9f = facet_value %u64, (%custom_witness.83a, %AnyUInt.impl_witness.a7a) [concrete]
// CHECK:STDOUT:   %FromUInt.impl_witness.8d0: <witness> = impl_witness imports.%FromUInt.impl_witness_table.be0, @UInt.as.FromUInt.impl(%int_64, %facet_value.d61) [concrete]
// CHECK:STDOUT:   %FromUInt.facet: %FromUInt.type.af0 = facet_value %u64, (%FromUInt.impl_witness.8d0) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.cbe: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.217, @UInt.as.ImplicitAs.impl.2da(%int_64, %FromUInt.facet) [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.41e: %ImplicitAs.type.14f = facet_value %u64, (%ImplicitAs.impl_witness.cbe) [concrete]
// CHECK:STDOUT:   %CppSizeToI64.impl_witness.da2: <witness> = impl_witness imports.%CppSizeToI64.impl_witness_table, @T.as_type.as.CppSizeToI64.impl(%ImplicitAs.facet.41e) [concrete]
// CHECK:STDOUT:   %facet_value.238: %CppContiguous_where.type.d682d6.1 = facet_value %NonNullLike, (%custom_witness.e02, %custom_witness.df9cc1.3, %Copy.impl_witness.ae2, %custom_witness.df9cc1.4, %CppDataPointer.impl_witness.44c, %custom_witness.df9cc1.6, %CppSizeToI64.impl_witness.da2) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.198: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.bbb, @C.as_type.as.ImplicitAs.impl(%facet_value.238) [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.type.57d: type = fn_type @C.as_type.as.ImplicitAs.impl.Convert, @C.as_type.as.ImplicitAs.impl(%facet_value.238) [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.f9c: %C.as_type.as.ImplicitAs.impl.Convert.type.57d = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.188: %ImplicitAs.type.8bf = facet_value %NonNullLike, (%ImplicitAs.impl_witness.198) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.b5b: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%Slice.2ea, %ImplicitAs.facet.188) [concrete]
// CHECK:STDOUT:   %.5f4: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.b5b, %ImplicitAs.facet.188 [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %C.as_type.as.ImplicitAs.impl.Convert.f9c, @C.as_type.as.ImplicitAs.impl.Convert(%facet_value.238) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .UInt = %Core.UInt
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
// CHECK:STDOUT:   %Core.import_ref.465: @C.as_type.as.ImplicitAs.impl.%C.as_type.as.ImplicitAs.impl.Convert.type (%C.as_type.as.ImplicitAs.impl.Convert.type.72c) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @C.as_type.as.ImplicitAs.impl.%C.as_type.as.ImplicitAs.impl.Convert (constants.%C.as_type.as.ImplicitAs.impl.Convert.9f0)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.bbb = impl_witness_table (%Core.import_ref.465), @C.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.UInt: %UInt.type = import_ref Core//prelude/types/uint, UInt, loaded [concrete = constants.%UInt.generic]
// CHECK:STDOUT:   %Core.import_ref.6f1: type = import_ref Core//prelude/types/cpp/slice, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.CppDataPointer.impl.%T (constants.%T.67d)]
// CHECK:STDOUT:   %Core.import_ref.4fe: @ptr.as.CppDataPointer.impl.%ptr.as.CppDataPointer.impl.Raw.type (%ptr.as.CppDataPointer.impl.Raw.type.414) = import_ref Core//prelude/types/cpp/slice, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.CppDataPointer.impl.%ptr.as.CppDataPointer.impl.Raw (constants.%ptr.as.CppDataPointer.impl.Raw.945)]
// CHECK:STDOUT:   %CppDataPointer.impl_witness_table.eaf = impl_witness_table (%Core.import_ref.6f1, %Core.import_ref.4fe), @ptr.as.CppDataPointer.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.56d: @T.as_type.as.CppSizeToI64.impl.%T.as_type.as.CppSizeToI64.impl.Op.type (%T.as_type.as.CppSizeToI64.impl.Op.type.e69) = import_ref Core//prelude/types/cpp/slice, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.CppSizeToI64.impl.%T.as_type.as.CppSizeToI64.impl.Op (constants.%T.as_type.as.CppSizeToI64.impl.Op.2e8)]
// CHECK:STDOUT:   %CppSizeToI64.impl_witness_table = impl_witness_table (%Core.import_ref.56d), @T.as_type.as.CppSizeToI64.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b7b: @UInt.as.ImplicitAs.impl.2da.%UInt.as.ImplicitAs.impl.Convert.type (%UInt.as.ImplicitAs.impl.Convert.type.181) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.ImplicitAs.impl.2da.%UInt.as.ImplicitAs.impl.Convert (constants.%UInt.as.ImplicitAs.impl.Convert.cd1)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.217 = impl_witness_table (%Core.import_ref.b7b), @UInt.as.ImplicitAs.impl.2da [concrete]
// CHECK:STDOUT:   %Core.import_ref.ab07f: @UInt.as.FromUInt.impl.%UInt.as.FromUInt.impl.Convert.type (%UInt.as.FromUInt.impl.Convert.type.9ef) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.FromUInt.impl.%UInt.as.FromUInt.impl.Convert (constants.%UInt.as.FromUInt.impl.Convert.131)]
// CHECK:STDOUT:   %FromUInt.impl_witness_table.be0 = impl_witness_table (%Core.import_ref.ab07f), @UInt.as.FromUInt.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.47b: Core.IntLiteral = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.AnyUInt.impl.%N (constants.%N.fe9)]
// CHECK:STDOUT:   %Core.import_ref.589: @UInt.as.AnyUInt.impl.%UInt.as.AnyUInt.impl.AsUInt.type (%UInt.as.AnyUInt.impl.AsUInt.type.d0f) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.AnyUInt.impl.%UInt.as.AnyUInt.impl.AsUInt (constants.%UInt.as.AnyUInt.impl.AsUInt.a74)]
// CHECK:STDOUT:   %AnyUInt.impl_witness_table = impl_witness_table (%Core.import_ref.47b, %Core.import_ref.589), @UInt.as.AnyUInt.impl [concrete]
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
// CHECK:STDOUT:     %facet_value.loc10: %facet_type.f48 = facet_value %const, (constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2) [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %.loc10_59.2: %facet_type.f48 = converted %const, %facet_value.loc10 [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %Slice: type = class_type @Slice, @Slice(constants.%facet_value.d9e) [concrete = constants.%Slice.2ea]
// CHECK:STDOUT:     %.loc10_59.3: Core.Form = init_form %Slice [concrete = constants.%.3e4]
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
// CHECK:STDOUT:   %impl.elem0: %.5f4 = impl_witness_access constants.%ImplicitAs.impl_witness.198, element0 [concrete = constants.%C.as_type.as.ImplicitAs.impl.Convert.f9c]
// CHECK:STDOUT:   %bound_method.loc11_11.1: <bound method> = bound_method %v.ref, %impl.elem0
// CHECK:STDOUT:   %facet_value.loc11_11.1: %CppContiguous_where.type.d682d6.1 = facet_value constants.%NonNullLike, (constants.%custom_witness.e02, constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2, constants.%custom_witness.df9cc1.4, constants.%CppDataPointer.impl_witness.44c, constants.%custom_witness.df9cc1.6, constants.%CppSizeToI64.impl_witness.da2) [concrete = constants.%facet_value.238]
// CHECK:STDOUT:   %.loc11_11.1: %CppContiguous_where.type.d682d6.1 = converted constants.%NonNullLike, %facet_value.loc11_11.1 [concrete = constants.%facet_value.238]
// CHECK:STDOUT:   %facet_value.loc11_11.2: %CppContiguous_where.type.d682d6.1 = facet_value constants.%NonNullLike, (constants.%custom_witness.e02, constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2, constants.%custom_witness.df9cc1.4, constants.%CppDataPointer.impl_witness.44c, constants.%custom_witness.df9cc1.6, constants.%CppSizeToI64.impl_witness.da2) [concrete = constants.%facet_value.238]
// CHECK:STDOUT:   %.loc11_11.2: %CppContiguous_where.type.d682d6.1 = converted constants.%NonNullLike, %facet_value.loc11_11.2 [concrete = constants.%facet_value.238]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @C.as_type.as.ImplicitAs.impl.Convert(constants.%facet_value.238) [concrete = constants.%C.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_11.2: <bound method> = bound_method %v.ref, %specific_fn
// CHECK:STDOUT:   %.loc10_59.1: ref %Slice.2ea = splice_block %return.param {}
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.call: init %Slice.2ea to %.loc10_59.1 = call %bound_method.loc11_11.2(%v.ref)
// CHECK:STDOUT:   %.loc11_11.3: init %Slice.2ea = converted %v.ref, %C.as_type.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   return %.loc11_11.3 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc11_11.1(%self.param: ref %ptr.774) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc11_11.2(%self.param: ref %u64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc11_11.3(%self.param: ref %u64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
