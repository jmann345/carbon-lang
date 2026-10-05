// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/span.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/span.carbon

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-8, D-SL-14): the dynamic-extent
// `std::span<T>` imports as `Core.Slice(T')`; a static extent stays a class.
// The header MOCKS `std::span` (as string_view.carbon mocks
// `basic_string_view`) so the golden is hermetic and pins the exact layout
// premise; `--target` pins the mock's `size_t` field to `unsigned long`, which
// imports as `u64` on x86_64-linux-gnu (`uint64_t` is `unsigned long` there;
// `Core.CppCompat.ULong64` is Darwin's import of it), where the class import's
// layout reaches the dump. Positives only.

// --- span.h

namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    inline constexpr size_t dynamic_extent = static_cast<size_t>(-1);

    // The layout premise (fork/slices/plan.md D-SL-1, R-6): a pointer, then a
    // size. The converting constructor is the real one's same-extent subset.
    template <typename T, size_t Extent = dynamic_extent>
    class span {
     public:
      span() = default;
      template <typename U>
      span(const span<U, Extent>& other)
          : data_(other.data()), size_(other.size()) {}
      T* data() const { return data_; }
      size_t size() const { return size_; }

     private:
      T* data_;
      size_t size_;
    };
  }
}

auto Consume(std::span<const int> s) -> void;
auto Produce() -> std::span<int>;
auto ConsumeStatic(std::span<int, 3> s) -> void;
using IntSpan3 = std::span<int, 3>;

// --- pass_and_return.carbon

library "[[@TEST_NAME]]";

import Cpp library "span.h";

// Predicted: `Cpp.Consume`'s imported parameter type is the
// `Core.Slice(const i32)` specific (no imported `span` CLASS anywhere in the
// dump); the `Slice(i32)` argument converts through the out-of-class
// `impl forall [T] Slice(T) as ImplicitAs(Slice(const T))` witness
// (`@Slice.as.ImplicitAs.impl`); the call names `Consume__carbon_thunk`
// (string_view.carbon's `Consume__carbon_thunk` shape: the `span` is not a
// simple ABI type, so the thunk takes the slice's address).
//@dump-sem-ir-begin
fn F(s: Core.Slice(i32)) {
  Cpp.Consume(s);
}
//@dump-sem-ir-end

// Predicted: `G` returns the `Core.Slice(i32)` specific through the
// out-pointer thunk form (`Produce__carbon_thunk`).
//@dump-sem-ir-begin
fn G() -> Core.Slice(i32) {
  return Cpp.Produce();
}
//@dump-sem-ir-end

// --- static_extent_is_a_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "span.h";

// `std::span<int, 3>` (named through the header's `IntSpan3` alias, the
// class/import/template.carbon `using Ai32 = A<int>` spelling) fails the
// `DynamicExtent` matcher. Predicted: an imported CLASS (`class_type @span`,
// completed by the by-value parameter) and NOT a `Slice` specific anywhere in
// the dump. The mock keeps `{T*, size_t}` for every extent -- the real
// static-extent span is a pointer only -- which is immaterial here: the split
// asserts only "a class, not a `Slice`".
//@dump-sem-ir-begin
fn H(unused p: Cpp.IntSpan3) {}
//@dump-sem-ir-end

// --- noncopyable_element_is_a_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

// `Slice(T)` requires `T: Copy & Destroy` (slice.carbon). A Carbon class with
// no `Copy` impl does not satisfy the bound, so `std::span<Carbon::NoCopy>` is
// NOT mapped -- the element is tested against `Slice`'s own binding without
// diagnostics (import.cpp `SliceElementSatisfiesBound`) -- and imports as an
// ordinary class. Predicted: a `class_type @span` for `Cpp.NoCopySpan` and no
// diagnostic at the inline C++'s `span` declaration. The Carbon class is
// declared before the inline C++ that names `Carbon::NoCopy` (the
// class/export/base.carbon `struct A : Carbon::Final {}` shape).
class NoCopy {}

inline Cpp '''
namespace std {
  using size_t = __SIZE_TYPE__;
  inline namespace __1 {
    inline constexpr size_t dynamic_extent = static_cast<size_t>(-1);
    template <typename T, size_t Extent = dynamic_extent>
    class span {
     public:
      span() = default;
      T* data() const { return data_; }
      size_t size() const { return size_; }
     private:
      T* data_;
      size_t size_;
    };
  }
}

using NoCopySpan = std::span<Carbon::NoCopy>;
''';

//@dump-sem-ir-begin
fn K(unused p: Cpp.NoCopySpan*) {}
//@dump-sem-ir-end

// CHECK:STDOUT: --- pass_and_return.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Slice.type: type = generic_class_type @Slice [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Slice.generic: %Slice.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %i64.builtin: type = int_type signed, %int_64 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %facet_type.f48: type = facet_type <@Destroy & @Copy> [concrete]
// CHECK:STDOUT:   %T.283: %facet_type.f48 = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %i32.builtin: type = int_type signed, %int_32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.2: type = fn_type @Destroy.Op.loc14_23.2 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.2: %Destroy.Op.type.1d8f74.2 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.2: <witness> = custom_witness (%Destroy.Op.1a2547.2), @Destroy [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %facet_value.53d: %facet_type.f48 = facet_value %i32, (%custom_witness.df9cc1.2, %Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Slice.33a: type = class_type @Slice, @Slice(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %pattern_type.d8a: type = pattern_type %Slice.33a [concrete]
// CHECK:STDOUT:   %s.param_patt.67e: %pattern_type.d8a = value_param_pattern [concrete]
// CHECK:STDOUT:   %s.patt.b77: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt.67e [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %Consume.cpp_overload_set.type: type = cpp_overload_set_type @Consume.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Consume.cpp_overload_set.value: %Consume.cpp_overload_set.type = cpp_overload_set_value @Consume.cpp_overload_set [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.3: type = fn_type @Destroy.Op.1 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.3: %Destroy.Op.type.1d8f74.3 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.df9cc1.3: <witness> = custom_witness (%Destroy.Op.1a2547.3), @Destroy [concrete]
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
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.type.d49: type = fn_type @Slice.as.ImplicitAs.impl.Convert, @Slice.as.ImplicitAs.impl(%T.283) [symbolic]
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.ac0: %Slice.as.ImplicitAs.impl.Convert.type.d49 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.2c1: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.e76, @Slice.as.ImplicitAs.impl(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.type.623: type = fn_type @Slice.as.ImplicitAs.impl.Convert, @Slice.as.ImplicitAs.impl(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.8a4: %Slice.as.ImplicitAs.impl.Convert.type.623 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.8bf = facet_value %Slice.33a, (%ImplicitAs.impl_witness.2c1) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.65d: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%Slice.2ea, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.29a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.65d, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Slice.as.ImplicitAs.impl.Convert.8a4, @Slice.as.ImplicitAs.impl.Convert(%facet_value.53d) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type.1d8f74.8: type = fn_type @Destroy.Op.loc15_15.5 [concrete]
// CHECK:STDOUT:   %Destroy.Op.1a2547.8: %Destroy.Op.type.1d8f74.8 = struct_value () [concrete]
// CHECK:STDOUT:   %.104: Core.Form = init_form %Slice.33a [concrete]
// CHECK:STDOUT:   %return.param_patt.aca: %pattern_type.d8a = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.58b: %pattern_type.d8a = return_slot_pattern %return.param_patt.aca, %Slice.33a [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %Produce.cpp_overload_set.type: type = cpp_overload_set_type @Produce.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Produce.cpp_overload_set.value: %Produce.cpp_overload_set.type = cpp_overload_set_value @Produce.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ptr.a31: type = ptr_type %Slice.33a [concrete]
// CHECK:STDOUT:   %Produce__carbon_thunk.type: type = fn_type @Produce__carbon_thunk [concrete]
// CHECK:STDOUT:   %Produce__carbon_thunk: %Produce__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Slice = %Core.Slice
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Consume = %Consume.cpp_overload_set.value
// CHECK:STDOUT:     .Produce = %Produce.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Slice: %Slice.type = import_ref Core//prelude/types/slice, Slice, loaded [concrete = constants.%Slice.generic]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.94c = import_ref Core//prelude/copy, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.aca = impl_witness_table (%Core.import_ref.94c), @const.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.bd6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.bd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Consume.cpp_overload_set.value: %Consume.cpp_overload_set.type = cpp_overload_set_value @Consume.cpp_overload_set [concrete = constants.%Consume.cpp_overload_set.value]
// CHECK:STDOUT:   %Consume__carbon_thunk.decl: %Consume__carbon_thunk.type = fn_decl @Consume__carbon_thunk [concrete = constants.%Consume__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.9a4: @Slice.as.ImplicitAs.impl.%Slice.as.ImplicitAs.impl.Convert.type (%Slice.as.ImplicitAs.impl.Convert.type.d49) = import_ref Core//prelude/types/slice, loc{{\d+_\d+}}, loaded [symbolic = @Slice.as.ImplicitAs.impl.%Slice.as.ImplicitAs.impl.Convert (constants.%Slice.as.ImplicitAs.impl.Convert.ac0)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.e76 = impl_witness_table (%Core.import_ref.9a4), @Slice.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Produce.cpp_overload_set.value: %Produce.cpp_overload_set.type = cpp_overload_set_value @Produce.cpp_overload_set [concrete = constants.%Produce.cpp_overload_set.value]
// CHECK:STDOUT:   %Produce__carbon_thunk.decl: %Produce__carbon_thunk.type = fn_decl @Produce__carbon_thunk [concrete = constants.%Produce__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %s.param_patt: %pattern_type.d8a = value_param_pattern [concrete = constants.%s.param_patt.67e]
// CHECK:STDOUT:     %s.patt: %pattern_type.d8a = wrapper_binding_pattern s, %s.param_patt [concrete = constants.%s.patt.b77]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %s.param: %Slice.33a = value_param call_param0
// CHECK:STDOUT:     %.loc14_23.1: type = splice_block %Slice.loc14 [concrete = constants.%Slice.33a] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:       %i32.loc14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %facet_value.loc14: %facet_type.f48 = facet_value %i32.loc14, (constants.%custom_witness.df9cc1.2, constants.%Copy.impl_witness.b51) [concrete = constants.%facet_value.53d]
// CHECK:STDOUT:       %.loc14_23.2: %facet_type.f48 = converted %i32.loc14, %facet_value.loc14 [concrete = constants.%facet_value.53d]
// CHECK:STDOUT:       %Slice.loc14: type = class_type @Slice, @Slice(constants.%facet_value.53d) [concrete = constants.%Slice.33a]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %s: %Slice.33a = wrapper_binding s, %s.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.d8a = out_param_pattern [concrete = constants.%return.param_patt.aca]
// CHECK:STDOUT:     %return.patt: %pattern_type.d8a = return_slot_pattern %return.param_patt, %Slice.loc22 [concrete = constants.%return.patt.58b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Slice.ref: %Slice.type = name_ref Slice, imports.%Core.Slice [concrete = constants.%Slice.generic]
// CHECK:STDOUT:     %i32.loc22: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %facet_value.loc22: %facet_type.f48 = facet_value %i32.loc22, (constants.%custom_witness.df9cc1.2, constants.%Copy.impl_witness.b51) [concrete = constants.%facet_value.53d]
// CHECK:STDOUT:     %.loc22_25.2: %facet_type.f48 = converted %i32.loc22, %facet_value.loc22 [concrete = constants.%facet_value.53d]
// CHECK:STDOUT:     %Slice.loc22: type = class_type @Slice, @Slice(constants.%facet_value.53d) [concrete = constants.%Slice.33a]
// CHECK:STDOUT:     %.loc22_25.3: Core.Form = init_form %Slice.loc22 [concrete = constants.%.104]
// CHECK:STDOUT:     %return.param: ref %Slice.33a = out_param call_param0
// CHECK:STDOUT:     %return: ref %Slice.33a = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_23.1(%self.param: ref %i32.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc14_23.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%s.param: %Slice.33a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Consume.ref: %Consume.cpp_overload_set.type = name_ref Consume, imports.%Consume.cpp_overload_set.value [concrete = constants.%Consume.cpp_overload_set.value]
// CHECK:STDOUT:   %s.ref: %Slice.33a = name_ref s, %s
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0: %.29a = impl_witness_access constants.%ImplicitAs.impl_witness.2c1, element0 [concrete = constants.%Slice.as.ImplicitAs.impl.Convert.8a4]
// CHECK:STDOUT:   %bound_method.loc15_15.1: <bound method> = bound_method %s.ref, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Slice.as.ImplicitAs.impl.Convert(constants.%facet_value.53d) [concrete = constants.%Slice.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_15.2: <bound method> = bound_method %s.ref, %specific_fn
// CHECK:STDOUT:   %.loc15_15.1: ref %Slice.2ea = temporary_storage
// CHECK:STDOUT:   %Slice.as.ImplicitAs.impl.Convert.call: init %Slice.2ea to %.loc15_15.1 = call %bound_method.loc15_15.2(%s.ref)
// CHECK:STDOUT:   %.loc15_15.2: init %Slice.2ea = converted %s.ref, %Slice.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc15_15.3: ref %Slice.2ea = temporary %.loc15_15.1, %.loc15_15.2
// CHECK:STDOUT:   %.loc15_15.4: %Slice.2ea = acquire_value %.loc15_15.3
// CHECK:STDOUT:   %.loc15_15.5: ref %Slice.2ea = value_as_ref %.loc15_15.4
// CHECK:STDOUT:   %addr: %ptr.6bb = addr_of %.loc15_15.5
// CHECK:STDOUT:   %Consume__carbon_thunk.call: init %empty_tuple.type = call imports.%Consume__carbon_thunk.decl(%addr)
// CHECK:STDOUT:   %Destroy.Op.bound: <bound method> = bound_method %.loc15_15.3, constants.%Destroy.Op.1a2547.8
// CHECK:STDOUT:   %Destroy.Op.call: init %empty_tuple.type = call %Destroy.Op.bound(%.loc15_15.3)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc15_15.1(%self.param: ref %ptr.774) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc15_15.2(%self.param: ref %i64.builtin) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc15_15.3(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc15_15.4(%self.param: ref %struct_type.ptr.size.043) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.Op.loc15_15.5(%self.param: ref %Slice.2ea) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() -> out %return.param: %Slice.33a {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Produce.ref: %Produce.cpp_overload_set.type = name_ref Produce, imports.%Produce.cpp_overload_set.value [concrete = constants.%Produce.cpp_overload_set.value]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %.loc22_25.1: ref %Slice.33a = splice_block %return.param {}
// CHECK:STDOUT:   %addr: %ptr.a31 = addr_of %.loc22_25.1
// CHECK:STDOUT:   %Produce__carbon_thunk.call: init %empty_tuple.type = call imports.%Produce__carbon_thunk.decl(%addr)
// CHECK:STDOUT:   %.loc23: init %Slice.33a to %.loc22_25.1 = mark_in_place_init %Produce__carbon_thunk.call
// CHECK:STDOUT:   return %.loc23 to %return.param
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- static_extent_is_a_class.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %span: type = class_type @span [concrete]
// CHECK:STDOUT:   %pattern_type.1c2: type = pattern_type %span [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.1c2 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.1c2 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %H.type: type = fn_type @H [concrete]
// CHECK:STDOUT:   %H: %H.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .IntSpan3 = %span.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %span.decl: type = class_decl @span [concrete = constants.%span] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %H.decl: %H.type = fn_decl @H [concrete = constants.%H] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.1c2 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.1c2 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %p.param: %span = value_param call_param0
// CHECK:STDOUT:     %.loc14: type = splice_block %IntSpan3.ref [concrete = constants.%span] {
// CHECK:STDOUT:       %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %IntSpan3.ref: type = name_ref IntSpan3, imports.%span.decl [concrete = constants.%span]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %span = wrapper_binding p, %p.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @H(%p.param: %span) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- noncopyable_element_is_a_class.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %span: type = class_type @span [concrete]
// CHECK:STDOUT:   %ptr.2ee: type = ptr_type %span [concrete]
// CHECK:STDOUT:   %pattern_type.b59: type = pattern_type %ptr.2ee [concrete]
// CHECK:STDOUT:   %p.param_patt.1d1: %pattern_type.b59 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt.94c: %pattern_type.b59 = wrapper_binding_pattern p, %p.param_patt.1d1 [concrete]
// CHECK:STDOUT:   %K.type: type = fn_type @K [concrete]
// CHECK:STDOUT:   %K: %K.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .NoCopySpan = %span.decl
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %span.decl: type = class_decl @span [concrete = constants.%span] {} {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %K.decl: %K.type = fn_decl @K [concrete = constants.%K] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.b59 = value_param_pattern [concrete = constants.%p.param_patt.1d1]
// CHECK:STDOUT:     %p.patt: %pattern_type.b59 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt.94c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %p.param: %ptr.2ee = value_param call_param0
// CHECK:STDOUT:     %.loc38: type = splice_block %ptr [concrete = constants.%ptr.2ee] {
// CHECK:STDOUT:       %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:       %NoCopySpan.ref: type = name_ref NoCopySpan, imports.%span.decl [concrete = constants.%span]
// CHECK:STDOUT:       %ptr: type = ptr_type %NoCopySpan.ref [concrete = constants.%ptr.2ee]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %ptr.2ee = wrapper_binding p, %p.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @K(%p.param: %ptr.2ee) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
