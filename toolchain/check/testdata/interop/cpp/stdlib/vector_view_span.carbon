// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/vector_view_span.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/vector_view_span.carbon

// Fork (SL-2 round 4, fork/slices/plan.md §4.B; D-SL-9): the owning -> view
// conversion when the TU ALSO declares `std::span` -- the hosted conformance
// shape (cpp_span_view.carbon includes `<span>` and `<vector>`), which
// vector_view.carbon's header does not reach. With `std::span` in the TU,
// `MapToCppType(Core.Slice(const i32))` is `std::span<const int>`, so the
// `ImplicitAs` lookup first asks Clang for a C++ conversion
// (operators.cpp `LookupCppConversion`), and Clang's initialization sequence
// selects `span`'s RANGE CONSTRUCTOR for a `VecLike<int>` source. That
// constructor belongs to a class with a custom Carbon mapping -- the
// specialization's inst is the `Core.Slice(const i32)` `ClassType`, not a
// `ClassDecl` -- and importing it was the round-4 ICE (`Casting inst {kind:
// ClassType ...} to wrong kind ClassDecl`, import.cpp `GetFunctionName`).
// `LookupCppConversion` now declines constructors of mapped classes, and the
// conversion falls through to the prelude's blanket impl over the synthesized
// `CppContiguousRange` witness, exactly as without `<span>`. The container is
// a class TEMPLATE specialization (the real `std::vector<int>` shape), named
// through a header alias (the class/import/template.carbon `using Ai32 =
// A<int>` spelling), so the witness is built over a specialization. The mock
// `span` is span.carbon's (D-SL-14) plus the range constructor; `--target`
// pins `unsigned long` to `u64`. Positives only.

// --- span_vec_like.h

namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    inline constexpr size_t dynamic_extent = static_cast<size_t>(-1);

    template <typename T, size_t Extent = dynamic_extent>
    class span {
     public:
      span() = default;
      template <typename U>
      span(const span<U, Extent>& other)
          : data_(other.data()), size_(other.size()) {}
      // The real one's range constructor (`explicit(Extent !=
      // dynamic_extent)`, so implicit here): what Clang selects for a
      // container source.
      template <typename R>
      span(R& r) : data_(r.data()), size_(r.size()) {}
      T* data() const { return data_; }
      size_t size() const { return size_; }

     private:
      T* data_;
      size_t size_;
    };
  }
}

template <typename T>
struct VecLike {
  const T* _Nullable data() const;
  T* _Nullable data();
  unsigned long size() const;
};
using VecLikeInt = VecLike<int>;

auto Consume(std::span<const int> s) -> void;

// --- view.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: view.carbon:[[@LINE+15]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./span_vec_like.h:20:8: warning: pointer is missing a nullability type specifier (_Nonnull, _Nullable, or _Null_unspecified) [CppInteropParseWarning]
// CHECK:STDERR:    20 |       T* data() const { return data_; }
// CHECK:STDERR:       |        ^
// CHECK:STDERR: view.carbon:[[@LINE+11]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./span_vec_like.h:20:8: note: insert '_Nullable' if the pointer may be null [CppInteropParseNote]
// CHECK:STDERR:    20 |       T* data() const { return data_; }
// CHECK:STDERR:       |        ^
// CHECK:STDERR:       |          _Nullable
// CHECK:STDERR: view.carbon:[[@LINE+6]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./span_vec_like.h:20:8: note: insert '_Nonnull' if the pointer should never be null [CppInteropParseNote]
// CHECK:STDERR:    20 |       T* data() const { return data_; }
// CHECK:STDERR:       |        ^
// CHECK:STDERR:       |          _Nonnull
// CHECK:STDERR:
import Cpp library "span_vec_like.h";

// Predicted: no `span` constructor anywhere in the dump; the blanket
// `ImplicitAs` witness over a `custom_witness (%Optional..., %u64,
// %VecLike.Data, %VecLike.Size), @CppContiguousRange` for the `VecLike<int>`
// specialization (vector_view.carbon's `view` shape, over a template
// specialization); `view` is the `Core.Slice(const i32)` specific.
//@dump-sem-ir-begin
fn View(v: Cpp.VecLikeInt) -> Core.Slice(const i32) {
  let view: Core.Slice(const i32) = v;
  return view;
}
//@dump-sem-ir-end

// --- argument.carbon

library "[[@TEST_NAME]]";

// CHECK:STDERR: argument.carbon:[[@LINE+15]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./span_vec_like.h:20:8: warning: pointer is missing a nullability type specifier (_Nonnull, _Nullable, or _Null_unspecified) [CppInteropParseWarning]
// CHECK:STDERR:    20 |       T* data() const { return data_; }
// CHECK:STDERR:       |        ^
// CHECK:STDERR: argument.carbon:[[@LINE+11]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./span_vec_like.h:20:8: note: insert '_Nullable' if the pointer may be null [CppInteropParseNote]
// CHECK:STDERR:    20 |       T* data() const { return data_; }
// CHECK:STDERR:       |        ^
// CHECK:STDERR:       |          _Nullable
// CHECK:STDERR: argument.carbon:[[@LINE+6]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./span_vec_like.h:20:8: note: insert '_Nonnull' if the pointer should never be null [CppInteropParseNote]
// CHECK:STDERR:    20 |       T* data() const { return data_; }
// CHECK:STDERR:       |        ^
// CHECK:STDERR:       |          _Nonnull
// CHECK:STDERR:
import Cpp library "span_vec_like.h";

// Predicted: `Consume`'s parameter imports as the `Core.Slice(const i32)`
// specific; the argument converts through the same blanket impl (the
// conformance program's `Cpp.SumSpan(v)` shape), and the call names
// `Consume__carbon_thunk` with the slice temporary's address
// (span.carbon's `pass_and_return` shape).
//@dump-sem-ir-begin
fn Pass(v: Cpp.VecLikeInt) {
  Cpp.Consume(v);
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- view.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %VecLike: type = class_type @VecLike [concrete]
// CHECK:STDOUT:   %pattern_type.efe: type = pattern_type %VecLike [concrete]
// CHECK:STDOUT:   %v.param_patt: %pattern_type.efe = value_param_pattern [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.efe = wrapper_binding_pattern v, %v.param_patt [concrete]
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type.f48 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.loc12_51.3 [concrete]
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
// CHECK:STDOUT:   %struct_type.ptr.size.043: type = struct_type {.ptr: %ptr.774, .size: %i64} [concrete]
// CHECK:STDOUT:   %view.patt: %pattern_type.86d = value_binding_pattern view [concrete]
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
// CHECK:STDOUT:   %VecLike.Data.type: type = fn_type @VecLike.Data [concrete]
// CHECK:STDOUT:   %VecLike.Data: %VecLike.Data.type = struct_value () [concrete]
// CHECK:STDOUT:   %VecLike.Size.type: type = fn_type @VecLike.Size [concrete]
// CHECK:STDOUT:   %VecLike.Size: %VecLike.Size.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.dd1: <witness> = custom_witness (%Optional.f0c, %u64, %VecLike.Data, %VecLike.Size), @CppContiguousRange [concrete]
// CHECK:STDOUT:   %Optional.as.CppDataPointer.impl.Raw.type.2db: type = fn_type @Optional.as.CppDataPointer.impl.Raw, @Optional.as.CppDataPointer.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %Optional.as.CppDataPointer.impl.Raw.cea: %Optional.as.CppDataPointer.impl.Raw.type.2db = struct_value () [symbolic]
// CHECK:STDOUT:   %CppDataPointer.impl_witness.2da: <witness> = impl_witness imports.%CppDataPointer.impl_witness_table.b0a, @Optional.as.CppDataPointer.impl(%const.6a8) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.7: type = fn_type @Destroy.Op.loc13_37.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.7: %Destroy.Op.type.1d8f74.7 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.7: <witness> = custom_witness (%Destroy.Op.1a2547.7), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.9: type = fn_type @Destroy.Op.loc13_37.5 [concrete]
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
// CHECK:STDOUT:   %facet_value.db5: %CppContiguous_where.type.d682d6.1 = facet_value %VecLike, (%custom_witness.dd1, %custom_witness.df9cc1.3, %Copy.impl_witness.ae2, %custom_witness.df9cc1.7, %CppDataPointer.impl_witness.2da, %custom_witness.df9cc1.9, %CppSizeToI64.impl_witness.da2) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.d31: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.bbb, @C.as_type.as.ImplicitAs.impl(%facet_value.db5) [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.type.df7: type = fn_type @C.as_type.as.ImplicitAs.impl.Convert, @C.as_type.as.ImplicitAs.impl(%facet_value.db5) [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.c59: %C.as_type.as.ImplicitAs.impl.Convert.type.df7 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.db7: %ImplicitAs.type.8bf = facet_value %VecLike, (%ImplicitAs.impl_witness.d31) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.123: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%Slice.2ea, %ImplicitAs.facet.db7) [concrete]
// CHECK:STDOUT:   %.d2b: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.123, %ImplicitAs.facet.db7 [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %C.as_type.as.ImplicitAs.impl.Convert.c59, @C.as_type.as.ImplicitAs.impl.Convert(%facet_value.db5) [concrete]
// CHECK:STDOUT:   %Slice.as.Copy.impl.Op.type.001: type = fn_type @Slice.as.Copy.impl.Op, @Slice.as.Copy.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %Slice.as.Copy.impl.Op.ff6: %Slice.as.Copy.impl.Op.type.001 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.75b: <witness> = impl_witness imports.%Copy.impl_witness_table.50b, @Slice.as.Copy.impl(%facet_value.d9e) [concrete]
// CHECK:STDOUT:   %Slice.as.Copy.impl.Op.type.693: type = fn_type @Slice.as.Copy.impl.Op, @Slice.as.Copy.impl(%facet_value.d9e) [concrete]
// CHECK:STDOUT:   %Slice.as.Copy.impl.Op.76f: %Slice.as.Copy.impl.Op.type.693 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.461: %Copy.type = facet_value %Slice.2ea, (%Copy.impl_witness.75b) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.230: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.461) [concrete]
// CHECK:STDOUT:   %.d56: type = fn_type_with_self_type %Copy.WithSelf.Op.type.230, %Copy.facet.461 [concrete]
// CHECK:STDOUT:   %Slice.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Slice.as.Copy.impl.Op.76f, @Slice.as.Copy.impl.Op(%facet_value.d9e) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.13: type = fn_type @Destroy.Op.loc13_37.9 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.13: %Destroy.Op.type.1d8f74.13 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .UInt = %Core.UInt
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .VecLikeInt = %VecLike.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %VecLike.decl: type = class_decl @VecLike [concrete = constants.%VecLike] {} {}
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
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.69e: @Slice.as.Copy.impl.%Slice.as.Copy.impl.Op.type (%Slice.as.Copy.impl.Op.type.001) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.Copy.impl.%Slice.as.Copy.impl.Op (constants.%Slice.as.Copy.impl.Op.ff6)]
// CHECK:STDOUT:   %Copy.impl_witness_table.50b = impl_witness_table (%Core.import_ref.69e), @Slice.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %View.decl: %View.type = fn_decl @View [concrete = constants.%View] {
// CHECK:STDOUT:     %v.param_patt: %pattern_type.efe = value_param_pattern [concrete = constants.%v.param_patt]
// CHECK:STDOUT:     %v.patt: %pattern_type.efe = wrapper_binding_pattern v, %v.param_patt [concrete = constants.%v.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.86d = out_param_pattern [concrete = constants.%return.param_patt.22d]
// CHECK:STDOUT:     %return.patt: %pattern_type.86d = return_slot_pattern %return.param_patt, %Slice.loc12 [concrete = constants.%return.patt.658]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref.loc12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Slice.ref.loc12: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %const.loc12: type = const_type %i32.loc12 [concrete = constants.%const.6a8]
// CHECK:STDOUT:     %facet_value.loc12: %facet_type.f48 = facet_value %const.loc12, (constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2) [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %.loc12_51.2: %facet_type.f48 = converted %const.loc12, %facet_value.loc12 [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %Slice.loc12: type = class_type @Slice, @Slice(constants.%facet_value.d9e) [concrete = constants.%Slice.2ea]
// CHECK:STDOUT:     %.loc12_51.3: Core.Form = init_form %Slice.loc12 [concrete = constants.%.3e4]
// CHECK:STDOUT:     %v.param: %VecLike = value_param call_param0
// CHECK:STDOUT:     %.loc12_15: type = splice_block %VecLikeInt.ref [concrete = constants.%VecLike] {
// CHECK:STDOUT:       %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %VecLikeInt.ref: type = name_ref VecLikeInt, imports.%VecLike.decl [concrete = constants.%VecLike]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v: %VecLike = wrapper_binding v, %v.param
// CHECK:STDOUT:     %return.param: ref %Slice.2ea = out_param call_param1
// CHECK:STDOUT:     %return: ref %Slice.2ea = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_51.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_51.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc12_51.3(%self.param: ref %const.6a8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @View(%v.param: %VecLike) -> out %return.param: %Slice.2ea {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %v.ref: %VecLike = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc13: %.d2b = impl_witness_access constants.%ImplicitAs.impl_witness.d31, element0 [concrete = constants.%C.as_type.as.ImplicitAs.impl.Convert.c59]
// CHECK:STDOUT:   %bound_method.loc13_37.1: <bound method> = bound_method %v.ref, %impl.elem0.loc13
// CHECK:STDOUT:   %facet_value.loc13_37.1: %CppContiguous_where.type.d682d6.1 = facet_value constants.%VecLike, (constants.%custom_witness.dd1, constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2, constants.%custom_witness.df9cc1.7, constants.%CppDataPointer.impl_witness.2da, constants.%custom_witness.df9cc1.9, constants.%CppSizeToI64.impl_witness.da2) [concrete = constants.%facet_value.db5]
// CHECK:STDOUT:   %.loc13_37.1: %CppContiguous_where.type.d682d6.1 = converted constants.%VecLike, %facet_value.loc13_37.1 [concrete = constants.%facet_value.db5]
// CHECK:STDOUT:   %facet_value.loc13_37.2: %CppContiguous_where.type.d682d6.1 = facet_value constants.%VecLike, (constants.%custom_witness.dd1, constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2, constants.%custom_witness.df9cc1.7, constants.%CppDataPointer.impl_witness.2da, constants.%custom_witness.df9cc1.9, constants.%CppSizeToI64.impl_witness.da2) [concrete = constants.%facet_value.db5]
// CHECK:STDOUT:   %.loc13_37.2: %CppContiguous_where.type.d682d6.1 = converted constants.%VecLike, %facet_value.loc13_37.2 [concrete = constants.%facet_value.db5]
// CHECK:STDOUT:   %specific_fn.loc13: <specific function> = specific_function %impl.elem0.loc13, @C.as_type.as.ImplicitAs.impl.Convert(constants.%facet_value.db5) [concrete = constants.%C.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_37.2: <bound method> = bound_method %v.ref, %specific_fn.loc13
// CHECK:STDOUT:   %.loc13_37.3: ref %Slice.2ea = temporary_storage
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.call: init %Slice.2ea to %.loc13_37.3 = call %bound_method.loc13_37.2(%v.ref)
// CHECK:STDOUT:   %.loc13_37.4: init %Slice.2ea = converted %v.ref, %C.as_type.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc13_37.5: ref %Slice.2ea = temporary %.loc13_37.3, %.loc13_37.4
// CHECK:STDOUT:   %.loc13_37.6: %Slice.2ea = acquire_value %.loc13_37.5
// CHECK:STDOUT:   %.loc13_33.1: type = splice_block %Slice.loc13 [concrete = constants.%Slice.2ea] {
// CHECK:STDOUT:     %Core.ref.loc13: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Slice.ref.loc13: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:     %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %const.loc13: type = const_type %i32.loc13 [concrete = constants.%const.6a8]
// CHECK:STDOUT:     %facet_value.loc13_33: %facet_type.f48 = facet_value %const.loc13, (constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2) [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %.loc13_33.2: %facet_type.f48 = converted %const.loc13, %facet_value.loc13_33 [concrete = constants.%facet_value.d9e]
// CHECK:STDOUT:     %Slice.loc13: type = class_type @Slice, @Slice(constants.%facet_value.d9e) [concrete = constants.%Slice.2ea]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %view: %Slice.2ea = wrapper_binding view, %.loc13_37.6
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %view.patt: %pattern_type.86d = value_binding_pattern view [concrete = constants.%view.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %view.ref: %Slice.2ea = name_ref view, %view
// CHECK:STDOUT:   %impl.elem0.loc14: %.d56 = impl_witness_access constants.%Copy.impl_witness.75b, element0 [concrete = constants.%Slice.as.Copy.impl.Op.76f]
// CHECK:STDOUT:   %bound_method.loc14_10.1: <bound method> = bound_method %view.ref, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Slice.as.Copy.impl.Op(constants.%facet_value.d9e) [concrete = constants.%Slice.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_10.2: <bound method> = bound_method %view.ref, %specific_fn.loc14
// CHECK:STDOUT:   %.loc12_51.1: ref %Slice.2ea = splice_block %return.param {}
// CHECK:STDOUT:   %Slice.as.Copy.impl.Op.call: init %Slice.2ea to %.loc12_51.1 = call %bound_method.loc14_10.2(%view.ref)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %.loc13_37.5, constants.%Destroy.Op.1a2547.13
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%.loc13_37.5)
// CHECK:STDOUT:   return %Slice.as.Copy.impl.Op.call to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_37.1(%self.param: ref %.f60) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_37.2(%self.param: ref %MaybeUnformed.416) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_37.3(%self.param: ref %Optional.f0c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_37.4(%self.param: ref %u64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_37.5(%self.param: ref %u64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_37.6(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_37.7(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_37.8(%self.param: ref %struct_type.ptr.size.043) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_37.9(%self.param: ref %Slice.2ea) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- argument.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %VecLike: type = class_type @VecLike [concrete]
// CHECK:STDOUT:   %pattern_type.efe: type = pattern_type %VecLike [concrete]
// CHECK:STDOUT:   %v.param_patt: %pattern_type.efe = value_param_pattern [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.efe = wrapper_binding_pattern v, %v.param_patt [concrete]
// CHECK:STDOUT:   %Pass.type: type = fn_type @Pass [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Pass: %Pass.type = struct_value () [concrete]
// CHECK:STDOUT:   %Consume.cpp_overload_set.type: type = cpp_overload_set_type @Consume.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Consume.cpp_overload_set.value: %Consume.cpp_overload_set.type = cpp_overload_set_value @Consume.cpp_overload_set [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N.fe9: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.3: %Destroy.Op.type.1d8f74.3 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.3: <witness> = custom_witness (%Destroy.Op.1a2547.3), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.ae2: <witness> = impl_witness imports.%Copy.impl_witness_table.aca, @const.as.Copy.impl(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %facet_value.d9e: %facet_type.f48 = facet_value %const.6a8, (%custom_witness.df9cc1.3, %Copy.impl_witness.ae2) [concrete]
// CHECK:STDOUT:   %Slice.2ea: type = class_type @Slice, @Slice(%facet_value.d9e) [concrete]
// CHECK:STDOUT:   %ptr.6bb: type = ptr_type %Slice.2ea [concrete]
// CHECK:STDOUT:   %Consume__carbon_thunk.type: type = fn_type @Consume__carbon_thunk [concrete]
// CHECK:STDOUT:   %Consume__carbon_thunk: %Consume__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %ptr.774: type = ptr_type %const.6a8 [concrete]
// CHECK:STDOUT:   %struct_type.ptr.size.043: type = struct_type {.ptr: %ptr.774, .size: %i64} [concrete]
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
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.type.015: type = fn_type @ptr.as.OptionalStorage.impl.Get, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.972: %ptr.as.OptionalStorage.impl.Get.type.015 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.4: type = fn_type @Destroy.Op.4 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.4: %Destroy.Op.type.1d8f74.4 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.4: <witness> = custom_witness (%Destroy.Op.1a2547.4), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.caa: %Destroy.type = facet_value %ptr.774, (%custom_witness.df9cc1.4) [concrete]
// CHECK:STDOUT:   %MaybeUnformed.416: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.caa) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.a99: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%const.6a8) [concrete]
// CHECK:STDOUT:   %.f60: type = maybe_unformed_type %ptr.774 [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.d3d: %OptionalStorage.type = facet_value %ptr.774, (%OptionalStorage.impl_witness.a99) [concrete]
// CHECK:STDOUT:   %Optional.f0c: type = class_type @Optional, @Optional(%OptionalStorage.facet.d3d) [concrete]
// CHECK:STDOUT:   %u64: type = class_type @UInt, @UInt(%int_64) [concrete]
// CHECK:STDOUT:   %u64.builtin: type = int_type unsigned, %int_64 [concrete]
// CHECK:STDOUT:   %VecLike.Data.type: type = fn_type @VecLike.Data [concrete]
// CHECK:STDOUT:   %VecLike.Data: %VecLike.Data.type = struct_value () [concrete]
// CHECK:STDOUT:   %VecLike.Size.type: type = fn_type @VecLike.Size [concrete]
// CHECK:STDOUT:   %VecLike.Size: %VecLike.Size.type = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.dd1: <witness> = custom_witness (%Optional.f0c, %u64, %VecLike.Data, %VecLike.Size), @CppContiguousRange [concrete]
// CHECK:STDOUT:   %Optional.as.CppDataPointer.impl.Raw.type.2db: type = fn_type @Optional.as.CppDataPointer.impl.Raw, @Optional.as.CppDataPointer.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %Optional.as.CppDataPointer.impl.Raw.cea: %Optional.as.CppDataPointer.impl.Raw.type.2db = struct_value () [symbolic]
// CHECK:STDOUT:   %CppDataPointer.impl_witness.2da: <witness> = impl_witness imports.%CppDataPointer.impl_witness_table.b0a, @Optional.as.CppDataPointer.impl(%const.6a8) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.7: type = fn_type @Destroy.Op.loc13_15.3 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.7: %Destroy.Op.type.1d8f74.7 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.7: <witness> = custom_witness (%Destroy.Op.1a2547.7), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.9: type = fn_type @Destroy.Op.loc13_15.5 [concrete]
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
// CHECK:STDOUT:   %facet_value.db5: %CppContiguous_where.type.d682d6.1 = facet_value %VecLike, (%custom_witness.dd1, %custom_witness.df9cc1.3, %Copy.impl_witness.ae2, %custom_witness.df9cc1.7, %CppDataPointer.impl_witness.2da, %custom_witness.df9cc1.9, %CppSizeToI64.impl_witness.da2) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.d31: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.bbb, @C.as_type.as.ImplicitAs.impl(%facet_value.db5) [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.type.df7: type = fn_type @C.as_type.as.ImplicitAs.impl.Convert, @C.as_type.as.ImplicitAs.impl(%facet_value.db5) [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.c59: %C.as_type.as.ImplicitAs.impl.Convert.type.df7 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.db7: %ImplicitAs.type.8bf = facet_value %VecLike, (%ImplicitAs.impl_witness.d31) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.123: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%Slice.2ea, %ImplicitAs.facet.db7) [concrete]
// CHECK:STDOUT:   %.d2b: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.123, %ImplicitAs.facet.db7 [concrete]
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %C.as_type.as.ImplicitAs.impl.Convert.c59, @C.as_type.as.ImplicitAs.impl.Convert(%facet_value.db5) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.13: type = fn_type @Destroy.Op.loc13_15.9 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.13: %Destroy.Op.type.1d8f74.13 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .VecLikeInt = %VecLike.decl
// CHECK:STDOUT:     .Consume = %Consume.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %VecLike.decl: type = class_decl @VecLike [concrete = constants.%VecLike] {} {}
// CHECK:STDOUT:   %Consume.cpp_overload_set.value: %Consume.cpp_overload_set.type = cpp_overload_set_value @Consume.cpp_overload_set [concrete = constants.%Consume.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.import_ref.94c = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.aca = impl_witness_table (%Core.import_ref.94c), @const.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Consume__carbon_thunk.decl: %Consume__carbon_thunk.type = fn_decl @Consume__carbon_thunk [concrete = constants.%Consume__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.465: @C.as_type.as.ImplicitAs.impl.%C.as_type.as.ImplicitAs.impl.Convert.type (%C.as_type.as.ImplicitAs.impl.Convert.type.72c) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @C.as_type.as.ImplicitAs.impl.%C.as_type.as.ImplicitAs.impl.Convert (constants.%C.as_type.as.ImplicitAs.impl.Convert.9f0)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.bbb = impl_witness_table (%Core.import_ref.465), @C.as_type.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.509: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%MaybeUnformed (constants.%MaybeUnformed.ddb)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c9a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.a90 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.008: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get.type (%ptr.as.OptionalStorage.impl.Get.type.015) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get (constants.%ptr.as.OptionalStorage.impl.Get.972)]
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.509, %Core.import_ref.105, %Core.import_ref.c9a, %Core.import_ref.a90, %Core.import_ref.008, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
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
// CHECK:STDOUT:   %Pass.decl: %Pass.type = fn_decl @Pass [concrete = constants.%Pass] {
// CHECK:STDOUT:     %v.param_patt: %pattern_type.efe = value_param_pattern [concrete = constants.%v.param_patt]
// CHECK:STDOUT:     %v.patt: %pattern_type.efe = wrapper_binding_pattern v, %v.param_patt [concrete = constants.%v.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %v.param: %VecLike = value_param call_param0
// CHECK:STDOUT:     %.loc12: type = splice_block %VecLikeInt.ref [concrete = constants.%VecLike] {
// CHECK:STDOUT:       %Cpp.ref.loc12: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %VecLikeInt.ref: type = name_ref VecLikeInt, imports.%VecLike.decl [concrete = constants.%VecLike]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %v: %VecLike = wrapper_binding v, %v.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Pass(%v.param: %VecLike) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref.loc13: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Consume.ref: %Consume.cpp_overload_set.type = name_ref Consume, imports.%Consume.cpp_overload_set.value [concrete = constants.%Consume.cpp_overload_set.value]
// CHECK:STDOUT:   %v.ref: %VecLike = name_ref v, %v
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0: %.d2b = impl_witness_access constants.%ImplicitAs.impl_witness.d31, element0 [concrete = constants.%C.as_type.as.ImplicitAs.impl.Convert.c59]
// CHECK:STDOUT:   %bound_method.loc13_15.1: <bound method> = bound_method %v.ref, %impl.elem0
// CHECK:STDOUT:   %facet_value.loc13_15.1: %CppContiguous_where.type.d682d6.1 = facet_value constants.%VecLike, (constants.%custom_witness.dd1, constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2, constants.%custom_witness.df9cc1.7, constants.%CppDataPointer.impl_witness.2da, constants.%custom_witness.df9cc1.9, constants.%CppSizeToI64.impl_witness.da2) [concrete = constants.%facet_value.db5]
// CHECK:STDOUT:   %.loc13_15.1: %CppContiguous_where.type.d682d6.1 = converted constants.%VecLike, %facet_value.loc13_15.1 [concrete = constants.%facet_value.db5]
// CHECK:STDOUT:   %facet_value.loc13_15.2: %CppContiguous_where.type.d682d6.1 = facet_value constants.%VecLike, (constants.%custom_witness.dd1, constants.%custom_witness.df9cc1.3, constants.%Copy.impl_witness.ae2, constants.%custom_witness.df9cc1.7, constants.%CppDataPointer.impl_witness.2da, constants.%custom_witness.df9cc1.9, constants.%CppSizeToI64.impl_witness.da2) [concrete = constants.%facet_value.db5]
// CHECK:STDOUT:   %.loc13_15.2: %CppContiguous_where.type.d682d6.1 = converted constants.%VecLike, %facet_value.loc13_15.2 [concrete = constants.%facet_value.db5]
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @C.as_type.as.ImplicitAs.impl.Convert(constants.%facet_value.db5) [concrete = constants.%C.as_type.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_15.2: <bound method> = bound_method %v.ref, %specific_fn
// CHECK:STDOUT:   %.loc13_15.3: ref %Slice.2ea = temporary_storage
// CHECK:STDOUT:   %C.as_type.as.ImplicitAs.impl.Convert.call: init %Slice.2ea to %.loc13_15.3 = call %bound_method.loc13_15.2(%v.ref)
// CHECK:STDOUT:   %.loc13_15.4: init %Slice.2ea = converted %v.ref, %C.as_type.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc13_15.5: ref %Slice.2ea = temporary %.loc13_15.3, %.loc13_15.4
// CHECK:STDOUT:   %.loc13_15.6: %Slice.2ea = acquire_value %.loc13_15.5
// CHECK:STDOUT:   %.loc13_15.7: ref %Slice.2ea = value_as_ref %.loc13_15.6
// CHECK:STDOUT:   %addr: %ptr.6bb = addr_of %.loc13_15.7
// CHECK:STDOUT:   %Consume__carbon_thunk.call: init %empty_tuple.type = call imports.%Consume__carbon_thunk.decl(%addr)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %.loc13_15.5, constants.%Destroy.Op.1a2547.13
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%.loc13_15.5)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_15.1(%self.param: ref %.f60) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_15.2(%self.param: ref %MaybeUnformed.416) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_15.3(%self.param: ref %Optional.f0c) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_15.4(%self.param: ref %u64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_15.5(%self.param: ref %u64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_15.6(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_15.7(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_15.8(%self.param: ref %struct_type.ptr.size.043) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc13_15.9(%self.param: ref %Slice.2ea) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
