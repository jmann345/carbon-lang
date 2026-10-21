// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/variant.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/variant.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1, F-020): a
// `std::variant<Ts...>` specialization of one to eight alternatives
// converts by value to `Core.CppCompat.StdVariant<N>(Ts'...)`, whose
// alternative `.Alt<I>` is the C++ alternative `I`: `index()`, then
// `std::get<I>`; back through the default constructor and `emplace<I>`.

// --- sum.h

// Mocks of libc++'s `std::optional` and `std::variant`, as string_view.carbon
// and span.carbon mock theirs, so the goldens are hermetic: the members the
// conversions call (`has_value`, `value`, `emplace`, `index`, `std::get`),
// libc++'s inline namespace, and `size_t` pinned by `--target`.
namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template <typename T>
    class optional {
     public:
      optional() : value_(), engaged_(false) {}
      optional(T value) : value_(value), engaged_(true) {}
      bool has_value() const { return engaged_; }
      const T& value() const { return value_; }
      template <typename... A>
      T& emplace(A&&... args) {
        value_ = T(args...);
        engaged_ = true;
        return value_;
      }

     private:
      T value_;
      bool engaged_;
    };

    struct monostate {};

    template <typename... Ts>
    class variant {
     public:
      variant() : index_(0) { emplace<0>(); }
      size_t index() const { return index_; }
      template <size_t I, typename... A>
      __type_pack_element<I, Ts...>& emplace(A&&... args) {
        index_ = I;
        auto* p = reinterpret_cast<__type_pack_element<I, Ts...>*>(storage_);
        *p = __type_pack_element<I, Ts...>(args...);
        return *p;
      }
      alignas(8) unsigned char storage_[8];
      size_t index_;
    };

    template <size_t I, typename... Ts>
    const __type_pack_element<I, Ts...>& get(const variant<Ts...>& v) {
      return *reinterpret_cast<const __type_pack_element<I, Ts...>*>(
          v.storage_);
    }
  }
}

inline auto IntOrHalf(int n) -> std::variant<int, double> {
  std::variant<int, double> v;
  if (n > 0) {
    v.emplace<0>(n);
  } else {
    v.emplace<1>(n * 0.5);
  }
  return v;
}

inline auto MaybeEmpty(int n) -> std::variant<std::monostate, int> {
  std::variant<std::monostate, int> v;
  if (n > 0) v.emplace<1>(n);
  return v;
}

inline auto LeftOrRight(int n) -> std::variant<int, int> {
  std::variant<int, int> v;
  v.emplace<1>(n);
  return v;
}

inline auto TakePair(const std::variant<int, int>& v) -> int {
  return static_cast<int>(v.index());
}

using Nine = std::variant<int, int, int, int, int, int, int, int, int>;
inline auto MakeNine() -> Nine { return Nine(); }

inline auto Nested() -> std::variant<std::optional<int>, int> {
  return std::variant<std::optional<int>, int>();
}

inline auto TakeIntOrPointer(std::variant<int, int*> v) -> int {
  if (v.index() == 0) return std::get<0>(v);
  return std::get<1>(v) ? *std::get<1>(v) : -1;
}

// --- declared.h

#include "sum.h"

// Declared and not defined: nothing in the translation unit instantiates
// `std::variant<int, short>`.
auto TakeIntOrShort(std::variant<int, short> v) -> int;

// --- match.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Predicted: one `index` thunk call, one equality test per alternative but
// the last, a `std::get<I>` thunk call per alternative, and
// `StdVariant2(i32, f64).Alt<I>` into one `temporary_storage`.
//@dump-sem-ir-begin
fn F(n: i32) -> i32 {
  match (Cpp.IntOrHalf(n)) {
    case .Alt0(i: i32) => {
      return i;
    }
    case .Alt1(unused d: f64) => {
      return -1;
    }
  }
  return -2;
}
//@dump-sem-ir-end

// --- monostate.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::monostate` alternative has the payload `()`; no `std::get` call.
//@dump-sem-ir-begin
fn M(n: i32) -> i32 {
  match (Cpp.MaybeEmpty(n)) {
    case .Alt0(unused empty: ()) => {
      return 0;
    }
    case .Alt1(i: i32) => {
      return i;
    }
  }
  return -1;
}
//@dump-sem-ir-end

// --- duplicate.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Duplicate alternative types are told apart by index, both ways.
//@dump-sem-ir-begin
fn D(n: i32) -> i32 {
  match (Cpp.LeftOrRight(n)) {
    case .Alt0(unused left: i32) => {
      return 0;
    }
    case .Alt1(right: i32) => {
      return Cpp.TakePair(Core.CppCompat.StdVariant2(i32, i32).Alt1(right));
    }
  }
  return -1;
}
//@dump-sem-ir-end

// --- pointer_reverse.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A pointer alternative converts back through `emplace<1>` with the payload's
// `Get()`, or with no argument when the payload is null; every arm is built,
// so a variant holding its `int` alternative reaches it too
// (fork/sumtype-interop/plan.md §1.5).
//@dump-sem-ir-begin
fn R(p: Core.Optional(i32*)) -> i32 {
  return Cpp.TakeIntOrPointer(
      Core.CppCompat.StdVariant2(i32, Core.Optional(i32*)).Alt1(p));
}
//@dump-sem-ir-end

fn I(n: i32) -> i32 {
  return Cpp.TakeIntOrPointer(
      Core.CppCompat.StdVariant2(i32, Core.Optional(i32*)).Alt0(n));
}

// --- declared_by_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "declared.h";

// A by-value parameter whose specialization nothing else instantiates: the
// class offered to overload resolution is instantiated first
// (fork/sumtype-interop/plan.md §1.5).
fn D(n: i32) -> i32 {
  return Cpp.TakeIntOrShort(Core.CppCompat.StdVariant2(i32, i16).Alt0(n));
}

// --- fail_todo_too_many_alternatives.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// `Core.CppCompat` declares `StdVariant1` to `StdVariant8` (plan §1.2).
fn N() -> i32 {
  // CHECK:STDERR: fail_todo_too_many_alternatives.carbon:[[@LINE+7]]:9: error: C++ type `std::variant<int, int, int, int, int, int, int, int, int>` has no Carbon sum type [CppSumTypeNotMapped]
  // CHECK:STDERR:   match (Cpp.MakeNine()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_todo_too_many_alternatives.carbon:[[@LINE+4]]:9: note: `std::variant` with 9 alternatives; at most 8 have a Carbon sum type [CppSumTypeTooManyAlternatives]
  // CHECK:STDERR:   match (Cpp.MakeNine()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  match (Cpp.MakeNine()) {
    default => {
      return 0;
    }
  }
  return 1;
}

// --- fail_todo_nested_by_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::optional` held by value in a `std::variant` is a class payload
// (SF-6, plan §1.3); held by pointer it is a pointer payload.
fn V() -> i32 {
  // CHECK:STDERR: fail_todo_nested_by_value.carbon:[[@LINE+7]]:9: error: C++ type `std::variant<std::optional<int>, int>` has no Carbon sum type [CppSumTypeNotMapped]
  // CHECK:STDERR:   match (Cpp.Nested()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~
  // CHECK:STDERR: fail_todo_nested_by_value.carbon:[[@LINE+4]]:9: note: alternative 0 has type `std::optional<int>`, which is not a choice payload type in 0.1 [CppSumTypeAlternativeNotAdmitted]
  // CHECK:STDERR:   match (Cpp.Nested()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~
  // CHECK:STDERR:
  match (Cpp.Nested()) {
    default => {
      return 0;
    }
  }
  return 1;
}

// --- fail_index_out_of_range.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn R(n: i32) -> i32 {
  match (Cpp.IntOrHalf(n)) {
    // CHECK:STDERR: fail_index_out_of_range.carbon:[[@LINE+4]]:10: error: member name `Alt2` not found in `Core.CppCompat.StdVariant2(i32, f64)` [MemberNameNotFoundInSpecificScope]
    // CHECK:STDERR:     case .Alt2(i: i32) => {
    // CHECK:STDERR:          ^~~~~~~~~~~~~
    // CHECK:STDERR:
    case .Alt2(i: i32) => {
      return i;
    }
    default => {
      return -1;
    }
  }
  return -2;
}

// CHECK:STDOUT: --- match.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %IntOrHalf.cpp_overload_set.type: type = cpp_overload_set_type @IntOrHalf.cpp_overload_set [concrete]
// CHECK:STDOUT:   %IntOrHalf.cpp_overload_set.value: %IntOrHalf.cpp_overload_set.type = cpp_overload_set_value @IntOrHalf.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant: type = class_type @variant [concrete]
// CHECK:STDOUT:   %pattern_type.d46: type = pattern_type %variant [concrete]
// CHECK:STDOUT:   %ptr.515: type = ptr_type %variant [concrete]
// CHECK:STDOUT:   %IntOrHalf__carbon_thunk.type: type = fn_type @IntOrHalf__carbon_thunk [concrete]
// CHECK:STDOUT:   %IntOrHalf__carbon_thunk: %IntOrHalf__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %u64: type = class_type @UInt, @UInt(%int_64) [concrete]
// CHECK:STDOUT:   %f64.dc1: type = class_type @Float, @Float(%int_64) [concrete]
// CHECK:STDOUT:   %StdVariant2.type: type = generic_class_type @StdVariant2 [concrete]
// CHECK:STDOUT:   %StdVariant2.generic: %StdVariant2.type = struct_value () [concrete]
// CHECK:STDOUT:   %T1: type = symbolic_binding T1, 1 [symbolic]
// CHECK:STDOUT:   %T0: type = symbolic_binding T0, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.type.45e: type = fn_type @StdVariant2.Alt1, @StdVariant2(%T0, %T1) [symbolic]
// CHECK:STDOUT:   %StdVariant2.Alt1.b0b: %StdVariant2.Alt1.type.45e = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.type.460: type = fn_type @StdVariant2.Alt0, @StdVariant2(%T0, %T1) [symbolic]
// CHECK:STDOUT:   %StdVariant2.Alt0.050: %StdVariant2.Alt0.type.460 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %StdVariant2.3c2: type = class_type @StdVariant2, @StdVariant2(%i32, %f64.dc1) [concrete]
// CHECK:STDOUT:   %pattern_type.fb7: type = pattern_type %f64.dc1 [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.2fd: type = tuple_type (%f64.dc1) [concrete]
// CHECK:STDOUT:   %.181: type = custom_layout_type {size=8, align=8, .Alt0@0: %tuple.type.a8a, .Alt1@0: %tuple.type.2fd} [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.type.38e: type = fn_type @StdVariant2.Alt0, @StdVariant2(%i32, %f64.dc1) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.cdc: %StdVariant2.Alt0.type.38e = struct_value () [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.type.20d: type = fn_type @StdVariant2.Alt1, @StdVariant2(%i32, %f64.dc1) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.d01: %StdVariant2.Alt1.type.20d = struct_value () [concrete]
// CHECK:STDOUT:   %variant.index.cpp_overload_set.type: type = cpp_overload_set_type @variant.index.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant.index.cpp_overload_set.value: %variant.index.cpp_overload_set.type = cpp_overload_set_value @variant.index.cpp_overload_set [concrete]
// CHECK:STDOUT:   %index__carbon_thunk.type: type = fn_type @index__carbon_thunk [concrete]
// CHECK:STDOUT:   %index__carbon_thunk: %index__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.14f: type = facet_type <@ImplicitAs, @ImplicitAs(%u64)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.8d9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.b18: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.633: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.b18 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.e08: %ImplicitAs.type.14f = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.8d9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.17c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u64, %ImplicitAs.facet.e08) [concrete]
// CHECK:STDOUT:   %.ed5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.17c, %ImplicitAs.facet.e08 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.633 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.633, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.95d: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53 [concrete]
// CHECK:STDOUT:   %int_0.07a: %u64 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.be8: type = facet_type <@EqWith, @EqWith(%u64)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.304: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.987: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.27d: %UInt.as.EqWith.impl.Equal.type.987 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.20e: %EqWith.type.be8 = facet_value %u64, (%EqWith.impl_witness.304) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.320: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u64, %EqWith.facet.20e) [concrete]
// CHECK:STDOUT:   %.707: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.320, %EqWith.facet.20e [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.e60: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.27d, @UInt.as.EqWith.impl.Equal.1(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %get.cpp_overload_set.type: type = cpp_overload_set_type @get.cpp_overload_set [concrete]
// CHECK:STDOUT:   %get.cpp_overload_set.value: %get.cpp_overload_set.type = cpp_overload_set_value @get.cpp_overload_set [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %const.c5d: type = const_type %variant [concrete]
// CHECK:STDOUT:   %ptr.4fb: type = ptr_type %const.c5d [concrete]
// CHECK:STDOUT:   %get__carbon_thunk.type.32b667.1: type = fn_type @get__carbon_thunk.1 [concrete]
// CHECK:STDOUT:   %get__carbon_thunk.7fe809.1: %get__carbon_thunk.type.32b667.1 = struct_value () [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.specific_fn: <specific function> = specific_function %StdVariant2.Alt0.cdc, @StdVariant2.Alt0(%i32, %f64.dc1) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.633 [concrete]
// CHECK:STDOUT:   %bound_method.7e7: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53 [concrete]
// CHECK:STDOUT:   %int_1.01f: %u64 = int_value 1 [concrete]
// CHECK:STDOUT:   %const.cfc: type = const_type %f64.dc1 [concrete]
// CHECK:STDOUT:   %get__carbon_thunk.type.32b667.2: type = fn_type @get__carbon_thunk.2 [concrete]
// CHECK:STDOUT:   %get__carbon_thunk.7fe809.2: %get__carbon_thunk.type.32b667.2 = struct_value () [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.specific_fn: <specific function> = specific_function %StdVariant2.Alt1.d01, @StdVariant2.Alt1(%i32, %f64.dc1) [concrete]
// CHECK:STDOUT:   %self.param_patt.09b: %pattern_type.d46 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.485: %pattern_type.d46 = wrapper_binding_pattern self, %self.param_patt.09b [concrete]
// CHECK:STDOUT:   %variant.cpp_destructor.type: type = fn_type @variant.cpp_destructor [concrete]
// CHECK:STDOUT:   %variant.cpp_destructor: %variant.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc11 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc11 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %i.patt: %pattern_type.6b6 = value_binding_pattern i [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.544: %pattern_type.e71 = tuple_pattern (%i.patt) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %d.patt: %pattern_type.fb7 = value_binding_pattern d [concrete]
// CHECK:STDOUT:   %pattern_type.c08: type = pattern_type %tuple.type.2fd [concrete]
// CHECK:STDOUT:   %.648: %pattern_type.c08 = tuple_pattern (%d.patt) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.e21: <bound method> = bound_method %int_2, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-2.962: Core.IntLiteral = int_value -2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.33f: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-2.c83: %i32 = int_value -2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .IntOrHalf = %IntOrHalf.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %IntOrHalf.cpp_overload_set.value: %IntOrHalf.cpp_overload_set.type = cpp_overload_set_value @IntOrHalf.cpp_overload_set [concrete = constants.%IntOrHalf.cpp_overload_set.value]
// CHECK:STDOUT:   %IntOrHalf__carbon_thunk.decl: %IntOrHalf__carbon_thunk.type = fn_decl @IntOrHalf__carbon_thunk [concrete = constants.%IntOrHalf__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StdVariant2: %StdVariant2.type = import_ref Core//prelude/types/cpp/sum, StdVariant2, loaded [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %Core.import_ref.3b7: @StdVariant2.%StdVariant2.Alt0.type (%StdVariant2.Alt0.type.460) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdVariant2.%StdVariant2.Alt0 (constants.%StdVariant2.Alt0.050)]
// CHECK:STDOUT:   %Core.import_ref.e76: @StdVariant2.%StdVariant2.Alt1.type (%StdVariant2.Alt1.type.45e) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdVariant2.%StdVariant2.Alt1 (constants.%StdVariant2.Alt1.b0b)]
// CHECK:STDOUT:   %variant.index.cpp_overload_set.value: %variant.index.cpp_overload_set.type = cpp_overload_set_value @variant.index.cpp_overload_set [concrete = constants.%variant.index.cpp_overload_set.value]
// CHECK:STDOUT:   %index__carbon_thunk.decl: %index__carbon_thunk.type = fn_decl @index__carbon_thunk [concrete = constants.%index__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %get.cpp_overload_set.value: %get.cpp_overload_set.type = cpp_overload_set_value @get.cpp_overload_set [concrete = constants.%get.cpp_overload_set.value]
// CHECK:STDOUT:   %get__carbon_thunk.decl.a4a8cc.1: %get__carbon_thunk.type.32b667.1 = fn_decl @get__carbon_thunk.1 [concrete = constants.%get__carbon_thunk.7fe809.1] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %get__carbon_thunk.decl.a4a8cc.2: %get__carbon_thunk.type.32b667.2 = fn_decl @get__carbon_thunk.2 [concrete = constants.%get__carbon_thunk.7fe809.2] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %variant.cpp_destructor.decl: %variant.cpp_destructor.type = fn_decl @variant.cpp_destructor [concrete = constants.%variant.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc11 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.d46 = ref_param_pattern [concrete = constants.%self.param_patt.09b]
// CHECK:STDOUT:     %self.patt: %pattern_type.d46 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.485]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %variant = ref_param call_param0
// CHECK:STDOUT:     %self: ref %variant = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc10_17 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc10_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10: Core.Form = init_form %i32.loc10_17 [concrete = constants.%.795f]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc10_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%n.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %IntOrHalf.ref: %IntOrHalf.cpp_overload_set.type = name_ref IntOrHalf, imports.%IntOrHalf.cpp_overload_set.value [concrete = constants.%IntOrHalf.cpp_overload_set.value]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc11_25.1: ref %variant = temporary_storage
// CHECK:STDOUT:   %addr.loc11_25: %ptr.515 = addr_of %.loc11_25.1
// CHECK:STDOUT:   %IntOrHalf__carbon_thunk.call: init %empty_tuple.type = call imports.%IntOrHalf__carbon_thunk.decl(%n.ref, %addr.loc11_25)
// CHECK:STDOUT:   %.loc11_25.2: init %variant to %.loc11_25.1 = mark_in_place_init %IntOrHalf__carbon_thunk.call
// CHECK:STDOUT:   %.loc11_25.3: ref %variant = temporary %.loc11_25.1, %.loc11_25.2
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdVariant2.ref: %StdVariant2.type = name_ref StdVariant2, imports.%Core.StdVariant2 [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %StdVariant2: type = class_type @StdVariant2, @StdVariant2(constants.%i32, constants.%f64.dc1) [concrete = constants.%StdVariant2.3c2]
// CHECK:STDOUT:   %.loc11_25.4: %variant = acquire_value %.loc11_25.3
// CHECK:STDOUT:   %.loc11_26.1: ref %StdVariant2.3c2 = temporary_storage
// CHECK:STDOUT:   %index.ref: %variant.index.cpp_overload_set.type = name_ref index, imports.%variant.index.cpp_overload_set.value [concrete = constants.%variant.index.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc11_26.1: <bound method> = bound_method %.loc11_25.4, %index.ref
// CHECK:STDOUT:   %index__carbon_thunk.call: init %u64 = call imports.%index__carbon_thunk.decl(%.loc11_25.4)
// CHECK:STDOUT:   %int_0.loc11_26.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc11_26.1: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc11_26.2: <bound method> = bound_method %int_0.loc11_26.1, %impl.elem0.loc11_26.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e]
// CHECK:STDOUT:   %specific_fn.loc11_26.1: <specific function> = specific_function %impl.elem0.loc11_26.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc11_26.3: <bound method> = bound_method %int_0.loc11_26.1, %specific_fn.loc11_26.1 [concrete = constants.%bound_method.95d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_26.1: init %u64 = call %bound_method.loc11_26.3(%int_0.loc11_26.1) [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc11_26.2: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_26.1 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc11_26.3: %u64 = converted %int_0.loc11_26.1, %.loc11_26.2 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %impl.elem0.loc11_26.2: %.707 = impl_witness_access constants.%EqWith.impl_witness.304, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.27d]
// CHECK:STDOUT:   %bound_method.loc11_26.4: <bound method> = bound_method %index__carbon_thunk.call, %impl.elem0.loc11_26.2
// CHECK:STDOUT:   %specific_fn.loc11_26.2: <specific function> = specific_function %impl.elem0.loc11_26.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_64, constants.%int_64) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.e60]
// CHECK:STDOUT:   %bound_method.loc11_26.5: <bound method> = bound_method %index__carbon_thunk.call, %specific_fn.loc11_26.2
// CHECK:STDOUT:   %.loc11_26.4: %u64 = value_of_initializer %index__carbon_thunk.call
// CHECK:STDOUT:   %.loc11_26.5: %u64 = converted %index__carbon_thunk.call, %.loc11_26.4
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc11: init bool = call %bound_method.loc11_26.5(%.loc11_26.5, %.loc11_26.3)
// CHECK:STDOUT:   %.loc11_26.6: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc11
// CHECK:STDOUT:   %.loc11_26.7: bool = converted %UInt.as.EqWith.impl.Equal.call.loc11, %.loc11_26.6
// CHECK:STDOUT:   if %.loc11_26.7 br !.loc11_26.1 else br !.loc11_26.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc11_26.1:
// CHECK:STDOUT:   %get.ref.loc11_26.1: %get.cpp_overload_set.type = name_ref get, imports.%get.cpp_overload_set.value [concrete = constants.%get.cpp_overload_set.value]
// CHECK:STDOUT:   %int_0.loc11_26.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc11_26.3: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc11_26.6: <bound method> = bound_method %int_0.loc11_26.2, %impl.elem0.loc11_26.3 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e]
// CHECK:STDOUT:   %specific_fn.loc11_26.3: <specific function> = specific_function %impl.elem0.loc11_26.3, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc11_26.7: <bound method> = bound_method %int_0.loc11_26.2, %specific_fn.loc11_26.3 [concrete = constants.%bound_method.95d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_26.2: init %u64 = call %bound_method.loc11_26.7(%int_0.loc11_26.2) [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc11_26.8: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_26.2 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc11_26.9: %u64 = converted %int_0.loc11_26.2, %.loc11_26.8 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc11_25.5: ref %variant = value_as_ref %.loc11_25.4
// CHECK:STDOUT:   %addr.loc11_26.1: %ptr.515 = addr_of %.loc11_25.5
// CHECK:STDOUT:   %.loc11_26.10: %ptr.4fb = as_compatible %addr.loc11_26.1
// CHECK:STDOUT:   %.loc11_26.11: %ptr.4fb = converted %addr.loc11_26.1, %.loc11_26.10
// CHECK:STDOUT:   %get__carbon_thunk.call.loc11_26.1: ref %const.6a8 = call imports.%get__carbon_thunk.decl.a4a8cc.1(%.loc11_26.11)
// CHECK:STDOUT:   %.loc11_26.12: %StdVariant2.Alt0.type.38e = specific_constant imports.%Core.import_ref.3b7, @StdVariant2(constants.%i32, constants.%f64.dc1) [concrete = constants.%StdVariant2.Alt0.cdc]
// CHECK:STDOUT:   %Alt0.ref: %StdVariant2.Alt0.type.38e = name_ref Alt0, %.loc11_26.12 [concrete = constants.%StdVariant2.Alt0.cdc]
// CHECK:STDOUT:   %StdVariant2.Alt0.specific_fn: <specific function> = specific_function %Alt0.ref, @StdVariant2.Alt0(constants.%i32, constants.%f64.dc1) [concrete = constants.%StdVariant2.Alt0.specific_fn]
// CHECK:STDOUT:   %.loc11_26.13: ref %StdVariant2.3c2 = splice_block %.loc11_26.1 {}
// CHECK:STDOUT:   %.loc11_26.14: ref %i32 = as_compatible %get__carbon_thunk.call.loc11_26.1
// CHECK:STDOUT:   %.loc11_26.15: ref %i32 = converted %get__carbon_thunk.call.loc11_26.1, %.loc11_26.14
// CHECK:STDOUT:   %.loc11_26.16: %i32 = acquire_value %.loc11_26.15
// CHECK:STDOUT:   %StdVariant2.Alt0.call: init %StdVariant2.3c2 to %.loc11_26.13 = call %StdVariant2.Alt0.specific_fn(%.loc11_26.16)
// CHECK:STDOUT:   assign %.loc11_26.1, %StdVariant2.Alt0.call
// CHECK:STDOUT:   br !.loc11_26.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc11_26.2:
// CHECK:STDOUT:   %get.ref.loc11_26.2: %get.cpp_overload_set.type = name_ref get, imports.%get.cpp_overload_set.value [concrete = constants.%get.cpp_overload_set.value]
// CHECK:STDOUT:   %int_1.loc11: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc11_26.4: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc11_26.8: <bound method> = bound_method %int_1.loc11, %impl.elem0.loc11_26.4 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0]
// CHECK:STDOUT:   %specific_fn.loc11_26.4: <specific function> = specific_function %impl.elem0.loc11_26.4, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc11_26.9: <bound method> = bound_method %int_1.loc11, %specific_fn.loc11_26.4 [concrete = constants.%bound_method.7e7]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_26.3: init %u64 = call %bound_method.loc11_26.9(%int_1.loc11) [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc11_26.17: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11_26.3 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc11_26.18: %u64 = converted %int_1.loc11, %.loc11_26.17 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc11_25.6: ref %variant = value_as_ref %.loc11_25.4
// CHECK:STDOUT:   %addr.loc11_26.2: %ptr.515 = addr_of %.loc11_25.6
// CHECK:STDOUT:   %.loc11_26.19: %ptr.4fb = as_compatible %addr.loc11_26.2
// CHECK:STDOUT:   %.loc11_26.20: %ptr.4fb = converted %addr.loc11_26.2, %.loc11_26.19
// CHECK:STDOUT:   %get__carbon_thunk.call.loc11_26.2: ref %const.cfc = call imports.%get__carbon_thunk.decl.a4a8cc.2(%.loc11_26.20)
// CHECK:STDOUT:   %.loc11_26.21: %StdVariant2.Alt1.type.20d = specific_constant imports.%Core.import_ref.e76, @StdVariant2(constants.%i32, constants.%f64.dc1) [concrete = constants.%StdVariant2.Alt1.d01]
// CHECK:STDOUT:   %Alt1.ref: %StdVariant2.Alt1.type.20d = name_ref Alt1, %.loc11_26.21 [concrete = constants.%StdVariant2.Alt1.d01]
// CHECK:STDOUT:   %StdVariant2.Alt1.specific_fn: <specific function> = specific_function %Alt1.ref, @StdVariant2.Alt1(constants.%i32, constants.%f64.dc1) [concrete = constants.%StdVariant2.Alt1.specific_fn]
// CHECK:STDOUT:   %.loc11_26.22: ref %StdVariant2.3c2 = splice_block %.loc11_26.1 {}
// CHECK:STDOUT:   %.loc11_26.23: ref %f64.dc1 = as_compatible %get__carbon_thunk.call.loc11_26.2
// CHECK:STDOUT:   %.loc11_26.24: ref %f64.dc1 = converted %get__carbon_thunk.call.loc11_26.2, %.loc11_26.23
// CHECK:STDOUT:   %.loc11_26.25: %f64.dc1 = acquire_value %.loc11_26.24
// CHECK:STDOUT:   %StdVariant2.Alt1.call: init %StdVariant2.3c2 to %.loc11_26.22 = call %StdVariant2.Alt1.specific_fn(%.loc11_26.25)
// CHECK:STDOUT:   assign %.loc11_26.1, %StdVariant2.Alt1.call
// CHECK:STDOUT:   br !.loc11_26.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc11_26.3:
// CHECK:STDOUT:   %.loc11_26.26: %StdVariant2.3c2 = acquire_value %.loc11_26.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc11_25.3, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc11_25.3)
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %i.patt: %pattern_type.6b6 = value_binding_pattern i [concrete = constants.%i.patt]
// CHECK:STDOUT:     %.loc12_17: %pattern_type.e71 = tuple_pattern (%i.patt) [concrete = constants.%.544]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc12: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_24.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc12_24.1: <bound method> = bound_method %int_0.loc12, %impl.elem0.loc12_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc12_24.1: <specific function> = specific_function %impl.elem0.loc12_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc12_24.2: <bound method> = bound_method %int_0.loc12, %specific_fn.loc12_24.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %u1 = call %bound_method.loc12_24.2(%int_0.loc12) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_24.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_24.2: %u1 = converted %int_0.loc12, %.loc12_24.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_24.3: ref %u1 = class_element_access %.loc11_26.26, element0
// CHECK:STDOUT:   %impl.elem0.loc12_24.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc12_24.3: <bound method> = bound_method %.loc12_24.2, %impl.elem0.loc12_24.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc12_24.2: <specific function> = specific_function %impl.elem0.loc12_24.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc12_24.4: <bound method> = bound_method %.loc12_24.2, %specific_fn.loc12_24.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc12_24.4: %u1 = acquire_value %.loc12_24.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc12: init bool = call %bound_method.loc12_24.4(%.loc12_24.2, %.loc12_24.4)
// CHECK:STDOUT:   %.loc12_24.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc12
// CHECK:STDOUT:   %.loc12_24.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc12, %.loc12_24.5
// CHECK:STDOUT:   if %.loc12_24.6 br !match.case.then.loc12 else br !match.case.else.loc12
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc12:
// CHECK:STDOUT:   %.loc12_24.7: ref %.181 = class_element_access %.loc11_26.26, element1
// CHECK:STDOUT:   %.loc12_24.8: ref %tuple.type.a8a = class_element_access %.loc12_24.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc12: ref %i32 = tuple_access %.loc12_24.8, element0
// CHECK:STDOUT:   %.loc12_24.9: %i32 = acquire_value %tuple.elem0.loc12
// CHECK:STDOUT:   %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i: %i32 = wrapper_binding i, %.loc12_24.9
// CHECK:STDOUT:   %i.ref: %i32 = name_ref i, %i
// CHECK:STDOUT:   %impl.elem0.loc13: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc13_14.1: <bound method> = bound_method %i.ref, %impl.elem0.loc13
// CHECK:STDOUT:   %specific_fn.loc13: <specific function> = specific_function %impl.elem0.loc13, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_14.2: <bound method> = bound_method %i.ref, %specific_fn.loc13
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc13_14.2(%i.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc12:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %d.patt: %pattern_type.fb7 = value_binding_pattern d [concrete = constants.%d.patt]
// CHECK:STDOUT:     %.loc15_24: %pattern_type.c08 = tuple_pattern (%d.patt) [concrete = constants.%.648]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc15: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_31.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_31.1: <bound method> = bound_method %int_1.loc15, %impl.elem0.loc15_31.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc15_31.1: <specific function> = specific_function %impl.elem0.loc15_31.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_31.2: <bound method> = bound_method %int_1.loc15, %specific_fn.loc15_31.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %u1 = call %bound_method.loc15_31.2(%int_1.loc15) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_31.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_31.2: %u1 = converted %int_1.loc15, %.loc15_31.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_31.3: ref %u1 = class_element_access %.loc11_26.26, element0
// CHECK:STDOUT:   %impl.elem0.loc15_31.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_31.3: <bound method> = bound_method %.loc15_31.2, %impl.elem0.loc15_31.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc15_31.2: <specific function> = specific_function %impl.elem0.loc15_31.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_31.4: <bound method> = bound_method %.loc15_31.2, %specific_fn.loc15_31.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc15_31.4: %u1 = acquire_value %.loc15_31.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_31.4(%.loc15_31.2, %.loc15_31.4)
// CHECK:STDOUT:   %.loc15_31.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_31.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_31.5
// CHECK:STDOUT:   if %.loc15_31.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %.loc15_31.7: ref %.181 = class_element_access %.loc11_26.26, element1
// CHECK:STDOUT:   %.loc15_31.8: ref %tuple.type.2fd = class_element_access %.loc15_31.7, element1
// CHECK:STDOUT:   %tuple.elem0.loc15: ref %f64.dc1 = tuple_access %.loc15_31.8, element0
// CHECK:STDOUT:   %.loc15_31.9: %f64.dc1 = acquire_value %tuple.elem0.loc15
// CHECK:STDOUT:   %f64.loc15: type = type_literal constants.%f64.dc1 [concrete = constants.%f64.dc1]
// CHECK:STDOUT:   %d: %f64.dc1 = wrapper_binding d, %.loc15_31.9
// CHECK:STDOUT:   %int_1.loc16: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc16: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16_14: <bound method> = bound_method %int_1.loc16, %impl.elem1.loc16 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc16: init Core.IntLiteral = call %bound_method.loc16_14(%int_1.loc16) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_16.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc16, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_16.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc16, %specific_fn.loc16 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc16_14.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc16 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc16_14.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc16, %.loc16_14.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_16.2(%.loc16_14.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc16_16: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc16, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc16_16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1.loc19: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc19_10: <bound method> = bound_method %int_2, %impl.elem1.loc19 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc19: init Core.IntLiteral = call %bound_method.loc19_10(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc19: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %specific_fn.loc19 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc19_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc19 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc19_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %.loc19_10.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_12.2(%.loc19_10.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc19_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   return %.loc19_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc11(%self.param: ref %variant) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc11(%self.param: ref %variant) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %variant.cpp_destructor.call: init %empty_tuple.type = call imports.%variant.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- monostate.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %M.type: type = fn_type @M [concrete]
// CHECK:STDOUT:   %M.e50: %M.type = struct_value () [concrete]
// CHECK:STDOUT:   %MaybeEmpty.cpp_overload_set.type: type = cpp_overload_set_type @MaybeEmpty.cpp_overload_set [concrete]
// CHECK:STDOUT:   %MaybeEmpty.cpp_overload_set.value: %MaybeEmpty.cpp_overload_set.type = cpp_overload_set_value @MaybeEmpty.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant: type = class_type @variant [concrete]
// CHECK:STDOUT:   %pattern_type.f15: type = pattern_type %variant [concrete]
// CHECK:STDOUT:   %ptr.378: type = ptr_type %variant [concrete]
// CHECK:STDOUT:   %MaybeEmpty__carbon_thunk.type: type = fn_type @MaybeEmpty__carbon_thunk [concrete]
// CHECK:STDOUT:   %MaybeEmpty__carbon_thunk: %MaybeEmpty__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %u64: type = class_type @UInt, @UInt(%int_64) [concrete]
// CHECK:STDOUT:   %StdVariant2.type: type = generic_class_type @StdVariant2 [concrete]
// CHECK:STDOUT:   %StdVariant2.generic: %StdVariant2.type = struct_value () [concrete]
// CHECK:STDOUT:   %T1: type = symbolic_binding T1, 1 [symbolic]
// CHECK:STDOUT:   %T0: type = symbolic_binding T0, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.type.45e: type = fn_type @StdVariant2.Alt1, @StdVariant2(%T0, %T1) [symbolic]
// CHECK:STDOUT:   %StdVariant2.Alt1.b0b: %StdVariant2.Alt1.type.45e = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.type.460: type = fn_type @StdVariant2.Alt0, @StdVariant2(%T0, %T1) [symbolic]
// CHECK:STDOUT:   %StdVariant2.Alt0.050: %StdVariant2.Alt0.type.460 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %StdVariant2.4d2: type = class_type @StdVariant2, @StdVariant2(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.cb1: type = pattern_type %empty_tuple.type [concrete]
// CHECK:STDOUT:   %tuple.type.9fb: type = tuple_type (%empty_tuple.type) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.b2c: type = custom_layout_type {size=4, align=4, .Alt0@0: %tuple.type.9fb, .Alt1@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.type.f87: type = fn_type @StdVariant2.Alt0, @StdVariant2(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.1cd: %StdVariant2.Alt0.type.f87 = struct_value () [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.type.363: type = fn_type @StdVariant2.Alt1, @StdVariant2(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.5ca: %StdVariant2.Alt1.type.363 = struct_value () [concrete]
// CHECK:STDOUT:   %variant.index.cpp_overload_set.type: type = cpp_overload_set_type @variant.index.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant.index.cpp_overload_set.value: %variant.index.cpp_overload_set.type = cpp_overload_set_value @variant.index.cpp_overload_set [concrete]
// CHECK:STDOUT:   %index__carbon_thunk.type: type = fn_type @index__carbon_thunk [concrete]
// CHECK:STDOUT:   %index__carbon_thunk: %index__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.14f: type = facet_type <@ImplicitAs, @ImplicitAs(%u64)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.8d9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.b18: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.633: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.b18 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.e08: %ImplicitAs.type.14f = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.8d9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.17c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u64, %ImplicitAs.facet.e08) [concrete]
// CHECK:STDOUT:   %.ed5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.17c, %ImplicitAs.facet.e08 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.633 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.633, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.95d: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53 [concrete]
// CHECK:STDOUT:   %int_0.07a: %u64 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.be8: type = facet_type <@EqWith, @EqWith(%u64)> [concrete]
// CHECK:STDOUT:   %M.d23: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M.d23) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.304: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.987: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.27d: %UInt.as.EqWith.impl.Equal.type.987 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.20e: %EqWith.type.be8 = facet_value %u64, (%EqWith.impl_witness.304) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.320: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u64, %EqWith.facet.20e) [concrete]
// CHECK:STDOUT:   %.707: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.320, %EqWith.facet.20e [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.e60: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.27d, @UInt.as.EqWith.impl.Equal.1(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %empty_tuple: %empty_tuple.type = tuple_value () [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.specific_fn: <specific function> = specific_function %StdVariant2.Alt0.1cd, @StdVariant2.Alt0(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %get.cpp_overload_set.type: type = cpp_overload_set_type @get.cpp_overload_set [concrete]
// CHECK:STDOUT:   %get.cpp_overload_set.value: %get.cpp_overload_set.type = cpp_overload_set_value @get.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.633 [concrete]
// CHECK:STDOUT:   %bound_method.7e7: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53 [concrete]
// CHECK:STDOUT:   %int_1.01f: %u64 = int_value 1 [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %const.fda: type = const_type %variant [concrete]
// CHECK:STDOUT:   %ptr.a39: type = ptr_type %const.fda [concrete]
// CHECK:STDOUT:   %get__carbon_thunk.type: type = fn_type @get__carbon_thunk [concrete]
// CHECK:STDOUT:   %get__carbon_thunk: %get__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.specific_fn: <specific function> = specific_function %StdVariant2.Alt1.5ca, @StdVariant2.Alt1(%empty_tuple.type, %i32) [concrete]
// CHECK:STDOUT:   %self.param_patt.08c: %pattern_type.f15 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.56b: %pattern_type.f15 = wrapper_binding_pattern self, %self.param_patt.08c [concrete]
// CHECK:STDOUT:   %variant.cpp_destructor.type: type = fn_type @variant.cpp_destructor [concrete]
// CHECK:STDOUT:   %variant.cpp_destructor: %variant.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT:   %empty.patt: %pattern_type.cb1 = value_binding_pattern empty [concrete]
// CHECK:STDOUT:   %pattern_type.559: type = pattern_type %tuple.type.9fb [concrete]
// CHECK:STDOUT:   %.5bf: %pattern_type.559 = tuple_pattern (%empty.patt) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %i.patt: %pattern_type.6b6 = value_binding_pattern i [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.544: %pattern_type.e71 = tuple_pattern (%i.patt) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .MaybeEmpty = %MaybeEmpty.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MaybeEmpty.cpp_overload_set.value: %MaybeEmpty.cpp_overload_set.type = cpp_overload_set_value @MaybeEmpty.cpp_overload_set [concrete = constants.%MaybeEmpty.cpp_overload_set.value]
// CHECK:STDOUT:   %MaybeEmpty__carbon_thunk.decl: %MaybeEmpty__carbon_thunk.type = fn_decl @MaybeEmpty__carbon_thunk [concrete = constants.%MaybeEmpty__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StdVariant2: %StdVariant2.type = import_ref Core//prelude/types/cpp/sum, StdVariant2, loaded [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %Core.import_ref.3b7: @StdVariant2.%StdVariant2.Alt0.type (%StdVariant2.Alt0.type.460) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdVariant2.%StdVariant2.Alt0 (constants.%StdVariant2.Alt0.050)]
// CHECK:STDOUT:   %Core.import_ref.e76: @StdVariant2.%StdVariant2.Alt1.type (%StdVariant2.Alt1.type.45e) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdVariant2.%StdVariant2.Alt1 (constants.%StdVariant2.Alt1.b0b)]
// CHECK:STDOUT:   %variant.index.cpp_overload_set.value: %variant.index.cpp_overload_set.type = cpp_overload_set_value @variant.index.cpp_overload_set [concrete = constants.%variant.index.cpp_overload_set.value]
// CHECK:STDOUT:   %index__carbon_thunk.decl: %index__carbon_thunk.type = fn_decl @index__carbon_thunk [concrete = constants.%index__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %get.cpp_overload_set.value: %get.cpp_overload_set.type = cpp_overload_set_value @get.cpp_overload_set [concrete = constants.%get.cpp_overload_set.value]
// CHECK:STDOUT:   %get__carbon_thunk.decl: %get__carbon_thunk.type = fn_decl @get__carbon_thunk [concrete = constants.%get__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %variant.cpp_destructor.decl: %variant.cpp_destructor.type = fn_decl @variant.cpp_destructor [concrete = constants.%variant.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc9 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f15 = ref_param_pattern [concrete = constants.%self.param_patt.08c]
// CHECK:STDOUT:     %self.patt: %pattern_type.f15 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.56b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %variant = ref_param call_param0
// CHECK:STDOUT:     %self: ref %variant = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %M.decl: %M.type = fn_decl @M [concrete = constants.%M.e50] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_17 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8: Core.Form = init_form %i32.loc8_17 [concrete = constants.%.795f]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc8_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @M(%n.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %MaybeEmpty.ref: %MaybeEmpty.cpp_overload_set.type = name_ref MaybeEmpty, imports.%MaybeEmpty.cpp_overload_set.value [concrete = constants.%MaybeEmpty.cpp_overload_set.value]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc9_26.1: ref %variant = temporary_storage
// CHECK:STDOUT:   %addr.loc9_26: %ptr.378 = addr_of %.loc9_26.1
// CHECK:STDOUT:   %MaybeEmpty__carbon_thunk.call: init %empty_tuple.type = call imports.%MaybeEmpty__carbon_thunk.decl(%n.ref, %addr.loc9_26)
// CHECK:STDOUT:   %.loc9_26.2: init %variant to %.loc9_26.1 = mark_in_place_init %MaybeEmpty__carbon_thunk.call
// CHECK:STDOUT:   %.loc9_26.3: ref %variant = temporary %.loc9_26.1, %.loc9_26.2
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdVariant2.ref: %StdVariant2.type = name_ref StdVariant2, imports.%Core.StdVariant2 [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %StdVariant2: type = class_type @StdVariant2, @StdVariant2(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%StdVariant2.4d2]
// CHECK:STDOUT:   %.loc9_26.4: %variant = acquire_value %.loc9_26.3
// CHECK:STDOUT:   %.loc9_27.1: ref %StdVariant2.4d2 = temporary_storage
// CHECK:STDOUT:   %index.ref: %variant.index.cpp_overload_set.type = name_ref index, imports.%variant.index.cpp_overload_set.value [concrete = constants.%variant.index.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc9_27.1: <bound method> = bound_method %.loc9_26.4, %index.ref
// CHECK:STDOUT:   %index__carbon_thunk.call: init %u64 = call imports.%index__carbon_thunk.decl(%.loc9_26.4)
// CHECK:STDOUT:   %int_0.loc9: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9_27.1: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc9_27.2: <bound method> = bound_method %int_0.loc9, %impl.elem0.loc9_27.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e]
// CHECK:STDOUT:   %specific_fn.loc9_27.1: <specific function> = specific_function %impl.elem0.loc9_27.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc9_27.3: <bound method> = bound_method %int_0.loc9, %specific_fn.loc9_27.1 [concrete = constants.%bound_method.95d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_27.1: init %u64 = call %bound_method.loc9_27.3(%int_0.loc9) [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc9_27.2: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_27.1 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc9_27.3: %u64 = converted %int_0.loc9, %.loc9_27.2 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %impl.elem0.loc9_27.2: %.707 = impl_witness_access constants.%EqWith.impl_witness.304, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.27d]
// CHECK:STDOUT:   %bound_method.loc9_27.4: <bound method> = bound_method %index__carbon_thunk.call, %impl.elem0.loc9_27.2
// CHECK:STDOUT:   %specific_fn.loc9_27.2: <specific function> = specific_function %impl.elem0.loc9_27.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_64, constants.%int_64) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.e60]
// CHECK:STDOUT:   %bound_method.loc9_27.5: <bound method> = bound_method %index__carbon_thunk.call, %specific_fn.loc9_27.2
// CHECK:STDOUT:   %.loc9_27.4: %u64 = value_of_initializer %index__carbon_thunk.call
// CHECK:STDOUT:   %.loc9_27.5: %u64 = converted %index__carbon_thunk.call, %.loc9_27.4
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc9: init bool = call %bound_method.loc9_27.5(%.loc9_27.5, %.loc9_27.3)
// CHECK:STDOUT:   %.loc9_27.6: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc9
// CHECK:STDOUT:   %.loc9_27.7: bool = converted %UInt.as.EqWith.impl.Equal.call.loc9, %.loc9_27.6
// CHECK:STDOUT:   if %.loc9_27.7 br !.loc9_27.1 else br !.loc9_27.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_27.1:
// CHECK:STDOUT:   %empty_tuple.loc9: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc9_27.8: %StdVariant2.Alt0.type.f87 = specific_constant imports.%Core.import_ref.3b7, @StdVariant2(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%StdVariant2.Alt0.1cd]
// CHECK:STDOUT:   %Alt0.ref: %StdVariant2.Alt0.type.f87 = name_ref Alt0, %.loc9_27.8 [concrete = constants.%StdVariant2.Alt0.1cd]
// CHECK:STDOUT:   %StdVariant2.Alt0.specific_fn: <specific function> = specific_function %Alt0.ref, @StdVariant2.Alt0(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%StdVariant2.Alt0.specific_fn]
// CHECK:STDOUT:   %.loc9_27.9: ref %StdVariant2.4d2 = splice_block %.loc9_27.1 {}
// CHECK:STDOUT:   %StdVariant2.Alt0.call: init %StdVariant2.4d2 to %.loc9_27.9 = call %StdVariant2.Alt0.specific_fn(%empty_tuple.loc9)
// CHECK:STDOUT:   assign %.loc9_27.1, %StdVariant2.Alt0.call
// CHECK:STDOUT:   br !.loc9_27.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_27.2:
// CHECK:STDOUT:   %get.ref: %get.cpp_overload_set.type = name_ref get, imports.%get.cpp_overload_set.value [concrete = constants.%get.cpp_overload_set.value]
// CHECK:STDOUT:   %int_1.loc9: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc9_27.3: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc9_27.6: <bound method> = bound_method %int_1.loc9, %impl.elem0.loc9_27.3 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0]
// CHECK:STDOUT:   %specific_fn.loc9_27.3: <specific function> = specific_function %impl.elem0.loc9_27.3, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc9_27.7: <bound method> = bound_method %int_1.loc9, %specific_fn.loc9_27.3 [concrete = constants.%bound_method.7e7]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_27.2: init %u64 = call %bound_method.loc9_27.7(%int_1.loc9) [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc9_27.10: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_27.2 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc9_27.11: %u64 = converted %int_1.loc9, %.loc9_27.10 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc9_26.5: ref %variant = value_as_ref %.loc9_26.4
// CHECK:STDOUT:   %addr.loc9_27: %ptr.378 = addr_of %.loc9_26.5
// CHECK:STDOUT:   %.loc9_27.12: %ptr.a39 = as_compatible %addr.loc9_27
// CHECK:STDOUT:   %.loc9_27.13: %ptr.a39 = converted %addr.loc9_27, %.loc9_27.12
// CHECK:STDOUT:   %get__carbon_thunk.call: ref %const.6a8 = call imports.%get__carbon_thunk.decl(%.loc9_27.13)
// CHECK:STDOUT:   %.loc9_27.14: %StdVariant2.Alt1.type.363 = specific_constant imports.%Core.import_ref.e76, @StdVariant2(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%StdVariant2.Alt1.5ca]
// CHECK:STDOUT:   %Alt1.ref: %StdVariant2.Alt1.type.363 = name_ref Alt1, %.loc9_27.14 [concrete = constants.%StdVariant2.Alt1.5ca]
// CHECK:STDOUT:   %StdVariant2.Alt1.specific_fn: <specific function> = specific_function %Alt1.ref, @StdVariant2.Alt1(constants.%empty_tuple.type, constants.%i32) [concrete = constants.%StdVariant2.Alt1.specific_fn]
// CHECK:STDOUT:   %.loc9_27.15: ref %StdVariant2.4d2 = splice_block %.loc9_27.1 {}
// CHECK:STDOUT:   %.loc9_27.16: ref %i32 = as_compatible %get__carbon_thunk.call
// CHECK:STDOUT:   %.loc9_27.17: ref %i32 = converted %get__carbon_thunk.call, %.loc9_27.16
// CHECK:STDOUT:   %.loc9_27.18: %i32 = acquire_value %.loc9_27.17
// CHECK:STDOUT:   %StdVariant2.Alt1.call: init %StdVariant2.4d2 to %.loc9_27.15 = call %StdVariant2.Alt1.specific_fn(%.loc9_27.18)
// CHECK:STDOUT:   assign %.loc9_27.1, %StdVariant2.Alt1.call
// CHECK:STDOUT:   br !.loc9_27.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_27.3:
// CHECK:STDOUT:   %.loc9_27.19: %StdVariant2.4d2 = acquire_value %.loc9_27.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc9_26.3, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc9_26.3)
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %empty.patt: %pattern_type.cb1 = value_binding_pattern empty [concrete = constants.%empty.patt]
// CHECK:STDOUT:     %.loc10_28: %pattern_type.559 = tuple_pattern (%empty.patt) [concrete = constants.%.5bf]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc10: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc10_34.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc10_34.1: <bound method> = bound_method %int_0.loc10, %impl.elem0.loc10_34.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc10_34.1: <specific function> = specific_function %impl.elem0.loc10_34.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc10_34.2: <bound method> = bound_method %int_0.loc10, %specific_fn.loc10_34.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %u1 = call %bound_method.loc10_34.2(%int_0.loc10) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc10_34.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc10_34.2: %u1 = converted %int_0.loc10, %.loc10_34.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc10_34.3: ref %u1 = class_element_access %.loc9_27.19, element0
// CHECK:STDOUT:   %impl.elem0.loc10_34.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc10_34.3: <bound method> = bound_method %.loc10_34.2, %impl.elem0.loc10_34.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc10_34.2: <specific function> = specific_function %impl.elem0.loc10_34.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc10_34.4: <bound method> = bound_method %.loc10_34.2, %specific_fn.loc10_34.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc10_34.4: %u1 = acquire_value %.loc10_34.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc10: init bool = call %bound_method.loc10_34.4(%.loc10_34.2, %.loc10_34.4)
// CHECK:STDOUT:   %.loc10_34.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc10
// CHECK:STDOUT:   %.loc10_34.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc10, %.loc10_34.5
// CHECK:STDOUT:   if %.loc10_34.6 br !match.case.then.loc10 else br !match.case.else.loc10
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc10:
// CHECK:STDOUT:   %.loc10_34.7: ref %.b2c = class_element_access %.loc9_27.19, element1
// CHECK:STDOUT:   %.loc10_34.8: ref %tuple.type.9fb = class_element_access %.loc10_34.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc10: ref %empty_tuple.type = tuple_access %.loc10_34.8, element0
// CHECK:STDOUT:   %empty_tuple.loc10: %empty_tuple.type = tuple_value () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc10_34.9: %empty_tuple.type = converted %tuple.elem0.loc10, %empty_tuple.loc10 [concrete = constants.%empty_tuple]
// CHECK:STDOUT:   %.loc10_31.1: type = splice_block %.loc10_31.3 [concrete = constants.%empty_tuple.type] {
// CHECK:STDOUT:     %.loc10_31.2: %empty_tuple.type = tuple_literal () [concrete = constants.%empty_tuple]
// CHECK:STDOUT:     %.loc10_31.3: type = converted %.loc10_31.2, constants.%empty_tuple.type [concrete = constants.%empty_tuple.type]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %empty: %empty_tuple.type = wrapper_binding empty, %.loc10_34.9
// CHECK:STDOUT:   %int_0.loc11: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_15.1: <bound method> = bound_method %int_0.loc11, %impl.elem0.loc11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc11_15.2: <bound method> = bound_method %int_0.loc11, %specific_fn.loc11 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_15.2(%int_0.loc11) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc11: init %i32 = converted %int_0.loc11, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc11
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc10:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %i.patt: %pattern_type.6b6 = value_binding_pattern i [concrete = constants.%i.patt]
// CHECK:STDOUT:     %.loc13_17: %pattern_type.e71 = tuple_pattern (%i.patt) [concrete = constants.%.544]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_24.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_24.1: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc13_24.1: <specific function> = specific_function %impl.elem0.loc13_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_24.2: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_24.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13: init %u1 = call %bound_method.loc13_24.2(%int_1.loc13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_24.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_24.2: %u1 = converted %int_1.loc13, %.loc13_24.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_24.3: ref %u1 = class_element_access %.loc9_27.19, element0
// CHECK:STDOUT:   %impl.elem0.loc13_24.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_24.3: <bound method> = bound_method %.loc13_24.2, %impl.elem0.loc13_24.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc13_24.2: <specific function> = specific_function %impl.elem0.loc13_24.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_24.4: <bound method> = bound_method %.loc13_24.2, %specific_fn.loc13_24.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc13_24.4: %u1 = acquire_value %.loc13_24.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_24.4(%.loc13_24.2, %.loc13_24.4)
// CHECK:STDOUT:   %.loc13_24.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:   %.loc13_24.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc13, %.loc13_24.5
// CHECK:STDOUT:   if %.loc13_24.6 br !match.case.then.loc13 else br !match.case.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc13:
// CHECK:STDOUT:   %.loc13_24.7: ref %.b2c = class_element_access %.loc9_27.19, element1
// CHECK:STDOUT:   %.loc13_24.8: ref %tuple.type.a8a = class_element_access %.loc13_24.7, element1
// CHECK:STDOUT:   %tuple.elem0.loc13: ref %i32 = tuple_access %.loc13_24.8, element0
// CHECK:STDOUT:   %.loc13_24.9: %i32 = acquire_value %tuple.elem0.loc13
// CHECK:STDOUT:   %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i: %i32 = wrapper_binding i, %.loc13_24.9
// CHECK:STDOUT:   %i.ref: %i32 = name_ref i, %i
// CHECK:STDOUT:   %impl.elem0.loc14: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_14.1: <bound method> = bound_method %i.ref, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_14.2: <bound method> = bound_method %i.ref, %specific_fn.loc14
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc14_14.2(%i.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc13:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc17_10: <bound method> = bound_method %int_1.loc17, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc17_10(%int_1.loc17) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc17 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc17_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc17_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc17_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %i32 = call %bound_method.loc17_12.2(%.loc17_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc17_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc17_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9(%self.param: ref %variant) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9(%self.param: ref %variant) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %variant.cpp_destructor.call: init %empty_tuple.type = call imports.%variant.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- duplicate.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %D.type: type = fn_type @D [concrete]
// CHECK:STDOUT:   %D: %D.type = struct_value () [concrete]
// CHECK:STDOUT:   %LeftOrRight.cpp_overload_set.type: type = cpp_overload_set_type @LeftOrRight.cpp_overload_set [concrete]
// CHECK:STDOUT:   %LeftOrRight.cpp_overload_set.value: %LeftOrRight.cpp_overload_set.type = cpp_overload_set_value @LeftOrRight.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant: type = class_type @variant [concrete]
// CHECK:STDOUT:   %pattern_type.2c9: type = pattern_type %variant [concrete]
// CHECK:STDOUT:   %ptr.b2b: type = ptr_type %variant [concrete]
// CHECK:STDOUT:   %LeftOrRight__carbon_thunk.type: type = fn_type @LeftOrRight__carbon_thunk [concrete]
// CHECK:STDOUT:   %LeftOrRight__carbon_thunk: %LeftOrRight__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %UInt.type: type = generic_class_type @UInt [concrete]
// CHECK:STDOUT:   %UInt.generic: %UInt.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %u64: type = class_type @UInt, @UInt(%int_64) [concrete]
// CHECK:STDOUT:   %StdVariant2.type: type = generic_class_type @StdVariant2 [concrete]
// CHECK:STDOUT:   %StdVariant2.generic: %StdVariant2.type = struct_value () [concrete]
// CHECK:STDOUT:   %T1: type = symbolic_binding T1, 1 [symbolic]
// CHECK:STDOUT:   %T0: type = symbolic_binding T0, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.type.45e: type = fn_type @StdVariant2.Alt1, @StdVariant2(%T0, %T1) [symbolic]
// CHECK:STDOUT:   %StdVariant2.Alt1.b0b: %StdVariant2.Alt1.type.45e = struct_value () [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.type.460: type = fn_type @StdVariant2.Alt0, @StdVariant2(%T0, %T1) [symbolic]
// CHECK:STDOUT:   %StdVariant2.Alt0.050: %StdVariant2.Alt0.type.460 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %StdVariant2.c29: type = class_type @StdVariant2, @StdVariant2(%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.8db: type = custom_layout_type {size=4, align=4, .Alt0@0: %tuple.type.a8a, .Alt1@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.81e: type = struct_type {.discriminant: %u1, .payload: %.8db} [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.type.e09: type = fn_type @StdVariant2.Alt0, @StdVariant2(%i32, %i32) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.49d: %StdVariant2.Alt0.type.e09 = struct_value () [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.type.ab3: type = fn_type @StdVariant2.Alt1, @StdVariant2(%i32, %i32) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.f5d: %StdVariant2.Alt1.type.ab3 = struct_value () [concrete]
// CHECK:STDOUT:   %variant.index.cpp_overload_set.type: type = cpp_overload_set_type @variant.index.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant.index.cpp_overload_set.value: %variant.index.cpp_overload_set.type = cpp_overload_set_value @variant.index.cpp_overload_set [concrete]
// CHECK:STDOUT:   %index__carbon_thunk.type: type = fn_type @index__carbon_thunk [concrete]
// CHECK:STDOUT:   %index__carbon_thunk: %index__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.14f: type = facet_type <@ImplicitAs, @ImplicitAs(%u64)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.8d9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.b18: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.633: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.b18 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.e08: %ImplicitAs.type.14f = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.8d9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.17c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u64, %ImplicitAs.facet.e08) [concrete]
// CHECK:STDOUT:   %.ed5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.17c, %ImplicitAs.facet.e08 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.633 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.633, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.95d: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53 [concrete]
// CHECK:STDOUT:   %int_0.07a: %u64 = int_value 0 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.be8: type = facet_type <@EqWith, @EqWith(%u64)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.304: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.987: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.27d: %UInt.as.EqWith.impl.Equal.type.987 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.20e: %EqWith.type.be8 = facet_value %u64, (%EqWith.impl_witness.304) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.320: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u64, %EqWith.facet.20e) [concrete]
// CHECK:STDOUT:   %.707: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.320, %EqWith.facet.20e [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.e60: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.27d, @UInt.as.EqWith.impl.Equal.1(%int_64, %int_64) [concrete]
// CHECK:STDOUT:   %get.cpp_overload_set.type: type = cpp_overload_set_type @get.cpp_overload_set [concrete]
// CHECK:STDOUT:   %get.cpp_overload_set.value: %get.cpp_overload_set.type = cpp_overload_set_value @get.cpp_overload_set [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %const.404: type = const_type %variant [concrete]
// CHECK:STDOUT:   %ptr.940: type = ptr_type %const.404 [concrete]
// CHECK:STDOUT:   %get__carbon_thunk.type.32b667.1: type = fn_type @get__carbon_thunk.1 [concrete]
// CHECK:STDOUT:   %get__carbon_thunk.7fe809.1: %get__carbon_thunk.type.32b667.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.760: type = pattern_type %StdVariant2.c29 [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt0.specific_fn: <specific function> = specific_function %StdVariant2.Alt0.49d, @StdVariant2.Alt0(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.633 [concrete]
// CHECK:STDOUT:   %bound_method.7e7: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53 [concrete]
// CHECK:STDOUT:   %int_1.01f: %u64 = int_value 1 [concrete]
// CHECK:STDOUT:   %get__carbon_thunk.type.32b667.2: type = fn_type @get__carbon_thunk.2 [concrete]
// CHECK:STDOUT:   %get__carbon_thunk.7fe809.2: %get__carbon_thunk.type.32b667.2 = struct_value () [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.specific_fn: <specific function> = specific_function %StdVariant2.Alt1.f5d, @StdVariant2.Alt1(%i32, %i32) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %self.param_patt.19b: %pattern_type.2c9 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.2a4: %pattern_type.2c9 = wrapper_binding_pattern self, %self.param_patt.19b [concrete]
// CHECK:STDOUT:   %variant.cpp_destructor.type: type = fn_type @variant.cpp_destructor [concrete]
// CHECK:STDOUT:   %variant.cpp_destructor: %variant.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %left.patt: %pattern_type.6b6 = value_binding_pattern left [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.74c2: %pattern_type.e71 = tuple_pattern (%left.patt) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %pattern_type.322: type = pattern_type %u1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %right.patt: %pattern_type.6b6 = value_binding_pattern right [concrete]
// CHECK:STDOUT:   %.d0f: %pattern_type.e71 = tuple_pattern (%right.patt) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %TakePair.cpp_overload_set.type: type = cpp_overload_set_type @TakePair.cpp_overload_set [concrete]
// CHECK:STDOUT:   %TakePair.cpp_overload_set.value: %TakePair.cpp_overload_set.type = cpp_overload_set_value @TakePair.cpp_overload_set [concrete]
// CHECK:STDOUT:   %TakePair__carbon_thunk.type: type = fn_type @TakePair__carbon_thunk [concrete]
// CHECK:STDOUT:   %TakePair__carbon_thunk: %TakePair__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %variant.variant.cpp_overload_set.type: type = cpp_overload_set_type @variant.variant.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant.variant.cpp_overload_set.value: %variant.variant.cpp_overload_set.type = cpp_overload_set_value @variant.variant.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant__carbon_thunk.type: type = fn_type @variant__carbon_thunk [concrete]
// CHECK:STDOUT:   %variant__carbon_thunk: %variant__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %variant.emplace.cpp_overload_set.type: type = cpp_overload_set_type @variant.emplace.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant.emplace.cpp_overload_set.value: %variant.emplace.cpp_overload_set.type = cpp_overload_set_value @variant.emplace.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.type.12b0d0.1: type = fn_type @emplace__carbon_thunk.1 [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.8001d1.1: %emplace__carbon_thunk.type.12b0d0.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.type.12b0d0.2: type = fn_type @emplace__carbon_thunk.2 [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.8001d1.2: %emplace__carbon_thunk.type.12b0d0.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.7c1: %pattern_type.322 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.945: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt.7c1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_74.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc14_74.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_74.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_74.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc14_74.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.bba: type = pattern_type %.8db [concrete]
// CHECK:STDOUT:   %self.param_patt.db2: %pattern_type.bba = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.33f: %pattern_type.bba = wrapper_binding_pattern self, %self.param_patt.db2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_74.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc14_74.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_74.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.c46: type = pattern_type %struct_type.discriminant.payload.81e [concrete]
// CHECK:STDOUT:   %self.param_patt.34f: %pattern_type.c46 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.a3d: %pattern_type.c46 = wrapper_binding_pattern self, %self.param_patt.34f [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_74.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc14_74.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.da9: %pattern_type.760 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.3c3: %pattern_type.760 = wrapper_binding_pattern self, %self.param_patt.da9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_74.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.7: type = fn_type @Destroy.WithSelf.Op.loc14_74.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.7: %Destroy.WithSelf.Op.type.ef016f.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.7: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_74.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.7: %Destroy.WithSelf.SelfDestruct.type.fbceb5.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .UInt = %Core.UInt
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .Negate = %Core.Negate
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .LeftOrRight = %LeftOrRight.cpp_overload_set.value
// CHECK:STDOUT:     .TakePair = %TakePair.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %LeftOrRight.cpp_overload_set.value: %LeftOrRight.cpp_overload_set.type = cpp_overload_set_value @LeftOrRight.cpp_overload_set [concrete = constants.%LeftOrRight.cpp_overload_set.value]
// CHECK:STDOUT:   %LeftOrRight__carbon_thunk.decl: %LeftOrRight__carbon_thunk.type = fn_decl @LeftOrRight__carbon_thunk [concrete = constants.%LeftOrRight__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.UInt: %UInt.type = import_ref Core//prelude/types/uint, UInt, loaded [concrete = constants.%UInt.generic]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .StdVariant2 = %Core.StdVariant2
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StdVariant2: %StdVariant2.type = import_ref Core//prelude/types/cpp/sum, StdVariant2, loaded [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %Core.import_ref.3b7: @StdVariant2.%StdVariant2.Alt0.type (%StdVariant2.Alt0.type.460) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdVariant2.%StdVariant2.Alt0 (constants.%StdVariant2.Alt0.050)]
// CHECK:STDOUT:   %Core.import_ref.e76: @StdVariant2.%StdVariant2.Alt1.type (%StdVariant2.Alt1.type.45e) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdVariant2.%StdVariant2.Alt1 (constants.%StdVariant2.Alt1.b0b)]
// CHECK:STDOUT:   %variant.index.cpp_overload_set.value: %variant.index.cpp_overload_set.type = cpp_overload_set_value @variant.index.cpp_overload_set [concrete = constants.%variant.index.cpp_overload_set.value]
// CHECK:STDOUT:   %index__carbon_thunk.decl: %index__carbon_thunk.type = fn_decl @index__carbon_thunk [concrete = constants.%index__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %get.cpp_overload_set.value: %get.cpp_overload_set.type = cpp_overload_set_value @get.cpp_overload_set [concrete = constants.%get.cpp_overload_set.value]
// CHECK:STDOUT:   %get__carbon_thunk.decl.a4a8cc.1: %get__carbon_thunk.type.32b667.1 = fn_decl @get__carbon_thunk.1 [concrete = constants.%get__carbon_thunk.7fe809.1] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %get__carbon_thunk.decl.a4a8cc.2: %get__carbon_thunk.type.32b667.2 = fn_decl @get__carbon_thunk.2 [concrete = constants.%get__carbon_thunk.7fe809.2] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %variant.cpp_destructor.decl: %variant.cpp_destructor.type = fn_decl @variant.cpp_destructor [concrete = constants.%variant.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %TakePair.cpp_overload_set.value: %TakePair.cpp_overload_set.type = cpp_overload_set_value @TakePair.cpp_overload_set [concrete = constants.%TakePair.cpp_overload_set.value]
// CHECK:STDOUT:   %TakePair__carbon_thunk.decl: %TakePair__carbon_thunk.type = fn_decl @TakePair__carbon_thunk [concrete = constants.%TakePair__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %variant.variant.cpp_overload_set.value: %variant.variant.cpp_overload_set.type = cpp_overload_set_value @variant.variant.cpp_overload_set [concrete = constants.%variant.variant.cpp_overload_set.value]
// CHECK:STDOUT:   %variant__carbon_thunk.decl: %variant__carbon_thunk.type = fn_decl @variant__carbon_thunk [concrete = constants.%variant__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %variant.emplace.cpp_overload_set.value: %variant.emplace.cpp_overload_set.type = cpp_overload_set_value @variant.emplace.cpp_overload_set [concrete = constants.%variant.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %emplace__carbon_thunk.decl.b5d853.1: %emplace__carbon_thunk.type.12b0d0.1 = fn_decl @emplace__carbon_thunk.1 [concrete = constants.%emplace__carbon_thunk.8001d1.1] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.decl.b5d853.2: %emplace__carbon_thunk.type.12b0d0.2 = fn_decl @emplace__carbon_thunk.2 [concrete = constants.%emplace__carbon_thunk.8001d1.2] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Negate: type = import_ref Core//prelude/operators/arithmetic, Negate, loaded [concrete = constants.%Negate.type]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc9 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.2c9 = ref_param_pattern [concrete = constants.%self.param_patt.19b]
// CHECK:STDOUT:     %self.patt: %pattern_type.2c9 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.2a4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %variant = ref_param call_param0
// CHECK:STDOUT:     %self: ref %variant = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_74.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc14_74.1 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_74.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc14_74.2 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_74.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.bba = ref_param_pattern [concrete = constants.%self.param_patt.db2]
// CHECK:STDOUT:     %self.patt: %pattern_type.bba = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.33f]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.8db = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.8db = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc14_74.3 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.bba = ref_param_pattern [concrete = constants.%self.param_patt.db2]
// CHECK:STDOUT:     %self.patt: %pattern_type.bba = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.33f]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.8db = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.8db = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_74.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.c46 = ref_param_pattern [concrete = constants.%self.param_patt.34f]
// CHECK:STDOUT:     %self.patt: %pattern_type.c46 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a3d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.81e = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.81e = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc14_74.4 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.c46 = ref_param_pattern [concrete = constants.%self.param_patt.34f]
// CHECK:STDOUT:     %self.patt: %pattern_type.c46 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.a3d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.81e = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.81e = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_74.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.760 = ref_param_pattern [concrete = constants.%self.param_patt.da9]
// CHECK:STDOUT:     %self.patt: %pattern_type.760 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.3c3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %StdVariant2.c29 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %StdVariant2.c29 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.7: %Destroy.WithSelf.Op.type.ef016f.7 = fn_decl @Destroy.WithSelf.Op.loc14_74.5 [concrete = constants.%Destroy.WithSelf.Op.403171.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.760 = ref_param_pattern [concrete = constants.%self.param_patt.da9]
// CHECK:STDOUT:     %self.patt: %pattern_type.760 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.3c3]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %StdVariant2.c29 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %StdVariant2.c29 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %D.decl: %D.type = fn_decl @D [concrete = constants.%D] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_17 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8: Core.Form = init_form %i32.loc8_17 [concrete = constants.%.795f]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc8_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @D(%n.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref.loc9: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %LeftOrRight.ref: %LeftOrRight.cpp_overload_set.type = name_ref LeftOrRight, imports.%LeftOrRight.cpp_overload_set.value [concrete = constants.%LeftOrRight.cpp_overload_set.value]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc9_27.1: ref %variant = temporary_storage
// CHECK:STDOUT:   %addr.loc9_27: %ptr.b2b = addr_of %.loc9_27.1
// CHECK:STDOUT:   %LeftOrRight__carbon_thunk.call: init %empty_tuple.type = call imports.%LeftOrRight__carbon_thunk.decl(%n.ref, %addr.loc9_27)
// CHECK:STDOUT:   %.loc9_27.2: init %variant to %.loc9_27.1 = mark_in_place_init %LeftOrRight__carbon_thunk.call
// CHECK:STDOUT:   %.loc9_27.3: ref %variant = temporary %.loc9_27.1, %.loc9_27.2
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdVariant2.ref.loc9: %StdVariant2.type = name_ref StdVariant2, imports.%Core.StdVariant2 [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %StdVariant2.loc9: type = class_type @StdVariant2, @StdVariant2(constants.%i32, constants.%i32) [concrete = constants.%StdVariant2.c29]
// CHECK:STDOUT:   %.loc9_27.4: %variant = acquire_value %.loc9_27.3
// CHECK:STDOUT:   %.loc9_28.1: ref %StdVariant2.c29 = temporary_storage
// CHECK:STDOUT:   %index.ref: %variant.index.cpp_overload_set.type = name_ref index, imports.%variant.index.cpp_overload_set.value [concrete = constants.%variant.index.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc9_28.1: <bound method> = bound_method %.loc9_27.4, %index.ref
// CHECK:STDOUT:   %index__carbon_thunk.call: init %u64 = call imports.%index__carbon_thunk.decl(%.loc9_27.4)
// CHECK:STDOUT:   %int_0.loc9_28.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9_28.1: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc9_28.2: <bound method> = bound_method %int_0.loc9_28.1, %impl.elem0.loc9_28.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e]
// CHECK:STDOUT:   %specific_fn.loc9_28.1: <specific function> = specific_function %impl.elem0.loc9_28.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc9_28.3: <bound method> = bound_method %int_0.loc9_28.1, %specific_fn.loc9_28.1 [concrete = constants.%bound_method.95d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_28.1: init %u64 = call %bound_method.loc9_28.3(%int_0.loc9_28.1) [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc9_28.2: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_28.1 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc9_28.3: %u64 = converted %int_0.loc9_28.1, %.loc9_28.2 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %impl.elem0.loc9_28.2: %.707 = impl_witness_access constants.%EqWith.impl_witness.304, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.27d]
// CHECK:STDOUT:   %bound_method.loc9_28.4: <bound method> = bound_method %index__carbon_thunk.call, %impl.elem0.loc9_28.2
// CHECK:STDOUT:   %specific_fn.loc9_28.2: <specific function> = specific_function %impl.elem0.loc9_28.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_64, constants.%int_64) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.e60]
// CHECK:STDOUT:   %bound_method.loc9_28.5: <bound method> = bound_method %index__carbon_thunk.call, %specific_fn.loc9_28.2
// CHECK:STDOUT:   %.loc9_28.4: %u64 = value_of_initializer %index__carbon_thunk.call
// CHECK:STDOUT:   %.loc9_28.5: %u64 = converted %index__carbon_thunk.call, %.loc9_28.4
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc9: init bool = call %bound_method.loc9_28.5(%.loc9_28.5, %.loc9_28.3)
// CHECK:STDOUT:   %.loc9_28.6: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc9
// CHECK:STDOUT:   %.loc9_28.7: bool = converted %UInt.as.EqWith.impl.Equal.call.loc9, %.loc9_28.6
// CHECK:STDOUT:   if %.loc9_28.7 br !.loc9_28.1 else br !.loc9_28.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_28.1:
// CHECK:STDOUT:   %get.ref.loc9_28.1: %get.cpp_overload_set.type = name_ref get, imports.%get.cpp_overload_set.value [concrete = constants.%get.cpp_overload_set.value]
// CHECK:STDOUT:   %int_0.loc9_28.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc9_28.3: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc9_28.6: <bound method> = bound_method %int_0.loc9_28.2, %impl.elem0.loc9_28.3 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e]
// CHECK:STDOUT:   %specific_fn.loc9_28.3: <specific function> = specific_function %impl.elem0.loc9_28.3, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc9_28.7: <bound method> = bound_method %int_0.loc9_28.2, %specific_fn.loc9_28.3 [concrete = constants.%bound_method.95d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_28.2: init %u64 = call %bound_method.loc9_28.7(%int_0.loc9_28.2) [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc9_28.8: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_28.2 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc9_28.9: %u64 = converted %int_0.loc9_28.2, %.loc9_28.8 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc9_27.5: ref %variant = value_as_ref %.loc9_27.4
// CHECK:STDOUT:   %addr.loc9_28.1: %ptr.b2b = addr_of %.loc9_27.5
// CHECK:STDOUT:   %.loc9_28.10: %ptr.940 = as_compatible %addr.loc9_28.1
// CHECK:STDOUT:   %.loc9_28.11: %ptr.940 = converted %addr.loc9_28.1, %.loc9_28.10
// CHECK:STDOUT:   %get__carbon_thunk.call.loc9_28.1: ref %const.6a8 = call imports.%get__carbon_thunk.decl.a4a8cc.1(%.loc9_28.11)
// CHECK:STDOUT:   %.loc9_28.12: %StdVariant2.Alt0.type.e09 = specific_constant imports.%Core.import_ref.3b7, @StdVariant2(constants.%i32, constants.%i32) [concrete = constants.%StdVariant2.Alt0.49d]
// CHECK:STDOUT:   %Alt0.ref: %StdVariant2.Alt0.type.e09 = name_ref Alt0, %.loc9_28.12 [concrete = constants.%StdVariant2.Alt0.49d]
// CHECK:STDOUT:   %StdVariant2.Alt0.specific_fn: <specific function> = specific_function %Alt0.ref, @StdVariant2.Alt0(constants.%i32, constants.%i32) [concrete = constants.%StdVariant2.Alt0.specific_fn]
// CHECK:STDOUT:   %.loc9_28.13: ref %StdVariant2.c29 = splice_block %.loc9_28.1 {}
// CHECK:STDOUT:   %.loc9_28.14: ref %i32 = as_compatible %get__carbon_thunk.call.loc9_28.1
// CHECK:STDOUT:   %.loc9_28.15: ref %i32 = converted %get__carbon_thunk.call.loc9_28.1, %.loc9_28.14
// CHECK:STDOUT:   %.loc9_28.16: %i32 = acquire_value %.loc9_28.15
// CHECK:STDOUT:   %StdVariant2.Alt0.call: init %StdVariant2.c29 to %.loc9_28.13 = call %StdVariant2.Alt0.specific_fn(%.loc9_28.16)
// CHECK:STDOUT:   assign %.loc9_28.1, %StdVariant2.Alt0.call
// CHECK:STDOUT:   br !.loc9_28.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_28.2:
// CHECK:STDOUT:   %get.ref.loc9_28.2: %get.cpp_overload_set.type = name_ref get, imports.%get.cpp_overload_set.value [concrete = constants.%get.cpp_overload_set.value]
// CHECK:STDOUT:   %int_1.loc9: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc9_28.4: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc9_28.8: <bound method> = bound_method %int_1.loc9, %impl.elem0.loc9_28.4 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0]
// CHECK:STDOUT:   %specific_fn.loc9_28.4: <specific function> = specific_function %impl.elem0.loc9_28.4, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc9_28.9: <bound method> = bound_method %int_1.loc9, %specific_fn.loc9_28.4 [concrete = constants.%bound_method.7e7]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_28.3: init %u64 = call %bound_method.loc9_28.9(%int_1.loc9) [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc9_28.17: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_28.3 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc9_28.18: %u64 = converted %int_1.loc9, %.loc9_28.17 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc9_27.6: ref %variant = value_as_ref %.loc9_27.4
// CHECK:STDOUT:   %addr.loc9_28.2: %ptr.b2b = addr_of %.loc9_27.6
// CHECK:STDOUT:   %.loc9_28.19: %ptr.940 = as_compatible %addr.loc9_28.2
// CHECK:STDOUT:   %.loc9_28.20: %ptr.940 = converted %addr.loc9_28.2, %.loc9_28.19
// CHECK:STDOUT:   %get__carbon_thunk.call.loc9_28.2: ref %const.6a8 = call imports.%get__carbon_thunk.decl.a4a8cc.2(%.loc9_28.20)
// CHECK:STDOUT:   %.loc9_28.21: %StdVariant2.Alt1.type.ab3 = specific_constant imports.%Core.import_ref.e76, @StdVariant2(constants.%i32, constants.%i32) [concrete = constants.%StdVariant2.Alt1.f5d]
// CHECK:STDOUT:   %Alt1.ref.loc9: %StdVariant2.Alt1.type.ab3 = name_ref Alt1, %.loc9_28.21 [concrete = constants.%StdVariant2.Alt1.f5d]
// CHECK:STDOUT:   %StdVariant2.Alt1.specific_fn.loc9: <specific function> = specific_function %Alt1.ref.loc9, @StdVariant2.Alt1(constants.%i32, constants.%i32) [concrete = constants.%StdVariant2.Alt1.specific_fn]
// CHECK:STDOUT:   %.loc9_28.22: ref %StdVariant2.c29 = splice_block %.loc9_28.1 {}
// CHECK:STDOUT:   %.loc9_28.23: ref %i32 = as_compatible %get__carbon_thunk.call.loc9_28.2
// CHECK:STDOUT:   %.loc9_28.24: ref %i32 = converted %get__carbon_thunk.call.loc9_28.2, %.loc9_28.23
// CHECK:STDOUT:   %.loc9_28.25: %i32 = acquire_value %.loc9_28.24
// CHECK:STDOUT:   %StdVariant2.Alt1.call.loc9: init %StdVariant2.c29 to %.loc9_28.22 = call %StdVariant2.Alt1.specific_fn.loc9(%.loc9_28.25)
// CHECK:STDOUT:   assign %.loc9_28.1, %StdVariant2.Alt1.call.loc9
// CHECK:STDOUT:   br !.loc9_28.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_28.3:
// CHECK:STDOUT:   %.loc9_28.26: %StdVariant2.c29 = acquire_value %.loc9_28.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9: <bound method> = bound_method %.loc9_27.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9(%.loc9_27.3)
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %left.patt: %pattern_type.6b6 = value_binding_pattern left [concrete = constants.%left.patt]
// CHECK:STDOUT:     %.loc10_27: %pattern_type.e71 = tuple_pattern (%left.patt) [concrete = constants.%.74c2]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc10: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc10_34.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc10_34.1: <bound method> = bound_method %int_0.loc10, %impl.elem0.loc10_34.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc10_34.1: <specific function> = specific_function %impl.elem0.loc10_34.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc10_34.2: <bound method> = bound_method %int_0.loc10, %specific_fn.loc10_34.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %u1 = call %bound_method.loc10_34.2(%int_0.loc10) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc10_34.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc10_34.2: %u1 = converted %int_0.loc10, %.loc10_34.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc10_34.3: ref %u1 = class_element_access %.loc9_28.26, element0
// CHECK:STDOUT:   %impl.elem0.loc10_34.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc10_34.3: <bound method> = bound_method %.loc10_34.2, %impl.elem0.loc10_34.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc10_34.2: <specific function> = specific_function %impl.elem0.loc10_34.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc10_34.4: <bound method> = bound_method %.loc10_34.2, %specific_fn.loc10_34.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc10_34.4: %u1 = acquire_value %.loc10_34.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc10: init bool = call %bound_method.loc10_34.4(%.loc10_34.2, %.loc10_34.4)
// CHECK:STDOUT:   %.loc10_34.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc10
// CHECK:STDOUT:   %.loc10_34.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc10, %.loc10_34.5
// CHECK:STDOUT:   if %.loc10_34.6 br !match.case.then.loc10 else br !match.case.else.loc10
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc10:
// CHECK:STDOUT:   %.loc10_34.7: ref %.8db = class_element_access %.loc9_28.26, element1
// CHECK:STDOUT:   %.loc10_34.8: ref %tuple.type.a8a = class_element_access %.loc10_34.7, element0
// CHECK:STDOUT:   %tuple.elem0.loc10: ref %i32 = tuple_access %.loc10_34.8, element0
// CHECK:STDOUT:   %.loc10_34.9: %i32 = acquire_value %tuple.elem0.loc10
// CHECK:STDOUT:   %i32.loc10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %left: %i32 = wrapper_binding left, %.loc10_34.9
// CHECK:STDOUT:   %int_0.loc11: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_15.1: <bound method> = bound_method %int_0.loc11, %impl.elem0.loc11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc11_15.2: <bound method> = bound_method %int_0.loc11, %specific_fn.loc11 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_15.2(%int_0.loc11) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc11: init %i32 = converted %int_0.loc11, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc11
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc10:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %right.patt: %pattern_type.6b6 = value_binding_pattern right [concrete = constants.%right.patt]
// CHECK:STDOUT:     %.loc13_21: %pattern_type.e71 = tuple_pattern (%right.patt) [concrete = constants.%.d0f]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc13: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc13_28.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_28.1: <bound method> = bound_method %int_1.loc13, %impl.elem0.loc13_28.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc13_28.1: <specific function> = specific_function %impl.elem0.loc13_28.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_28.2: <bound method> = bound_method %int_1.loc13, %specific_fn.loc13_28.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13: init %u1 = call %bound_method.loc13_28.2(%int_1.loc13) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_28.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_28.2: %u1 = converted %int_1.loc13, %.loc13_28.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc13_28.3: ref %u1 = class_element_access %.loc9_28.26, element0
// CHECK:STDOUT:   %impl.elem0.loc13_28.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_28.3: <bound method> = bound_method %.loc13_28.2, %impl.elem0.loc13_28.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc13_28.2: <specific function> = specific_function %impl.elem0.loc13_28.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_28.4: <bound method> = bound_method %.loc13_28.2, %specific_fn.loc13_28.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc13_28.4: %u1 = acquire_value %.loc13_28.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_28.4(%.loc13_28.2, %.loc13_28.4)
// CHECK:STDOUT:   %.loc13_28.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:   %.loc13_28.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc13, %.loc13_28.5
// CHECK:STDOUT:   if %.loc13_28.6 br !match.case.then.loc13 else br !match.case.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc13:
// CHECK:STDOUT:   %.loc13_28.7: ref %.8db = class_element_access %.loc9_28.26, element1
// CHECK:STDOUT:   %.loc13_28.8: ref %tuple.type.a8a = class_element_access %.loc13_28.7, element1
// CHECK:STDOUT:   %tuple.elem0.loc13: ref %i32 = tuple_access %.loc13_28.8, element0
// CHECK:STDOUT:   %.loc13_28.9: %i32 = acquire_value %tuple.elem0.loc13
// CHECK:STDOUT:   %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %right: %i32 = wrapper_binding right, %.loc13_28.9
// CHECK:STDOUT:   %Cpp.ref.loc14: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %TakePair.ref: %TakePair.cpp_overload_set.type = name_ref TakePair, imports.%TakePair.cpp_overload_set.value [concrete = constants.%TakePair.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %CppCompat.ref: <namespace> = name_ref CppCompat, imports.%CppCompat.f0dbf9.1 [concrete = imports.%CppCompat.f0dbf9.1]
// CHECK:STDOUT:   %StdVariant2.ref.loc14_41: %StdVariant2.type = name_ref StdVariant2, imports.%Core.StdVariant2 [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %i32.loc14_54: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i32.loc14_59: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %StdVariant2.loc14_62: type = class_type @StdVariant2, @StdVariant2(constants.%i32, constants.%i32) [concrete = constants.%StdVariant2.c29]
// CHECK:STDOUT:   %.loc14_63: %StdVariant2.Alt1.type.ab3 = specific_constant imports.%Core.import_ref.e76, @StdVariant2(constants.%i32, constants.%i32) [concrete = constants.%StdVariant2.Alt1.f5d]
// CHECK:STDOUT:   %Alt1.ref.loc14: %StdVariant2.Alt1.type.ab3 = name_ref Alt1, %.loc14_63 [concrete = constants.%StdVariant2.Alt1.f5d]
// CHECK:STDOUT:   %right.ref: %i32 = name_ref right, %right
// CHECK:STDOUT:   %StdVariant2.Alt1.specific_fn.loc14: <specific function> = specific_function %Alt1.ref.loc14, @StdVariant2.Alt1(constants.%i32, constants.%i32) [concrete = constants.%StdVariant2.Alt1.specific_fn]
// CHECK:STDOUT:   %.loc14_74.1: ref %StdVariant2.c29 = temporary_storage
// CHECK:STDOUT:   %StdVariant2.Alt1.call.loc14: init %StdVariant2.c29 to %.loc14_74.1 = call %StdVariant2.Alt1.specific_fn.loc14(%right.ref)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdVariant2.ref.loc14_74: %StdVariant2.type = name_ref StdVariant2, imports.%Core.StdVariant2 [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %StdVariant2.loc14_74: type = class_type @StdVariant2, @StdVariant2(constants.%i32, constants.%i32) [concrete = constants.%StdVariant2.c29]
// CHECK:STDOUT:   %.loc14_74.2: ref %StdVariant2.c29 = temporary %.loc14_74.1, %StdVariant2.Alt1.call.loc14
// CHECK:STDOUT:   %.loc14_74.3: %StdVariant2.c29 = acquire_value %.loc14_74.2
// CHECK:STDOUT:   %.loc14_74.4: ref %variant = temporary_storage
// CHECK:STDOUT:   %variant.ref: %variant.variant.cpp_overload_set.type = name_ref variant, imports.%variant.variant.cpp_overload_set.value [concrete = constants.%variant.variant.cpp_overload_set.value]
// CHECK:STDOUT:   %.loc14_74.5: ref %variant = splice_block %.loc14_74.4 {}
// CHECK:STDOUT:   %addr.loc14_74.1: %ptr.b2b = addr_of %.loc14_74.5
// CHECK:STDOUT:   %variant__carbon_thunk.call: init %empty_tuple.type = call imports.%variant__carbon_thunk.decl(%addr.loc14_74.1)
// CHECK:STDOUT:   %.loc14_74.6: init %variant to %.loc14_74.5 = mark_in_place_init %variant__carbon_thunk.call
// CHECK:STDOUT:   assign %.loc14_74.4, %.loc14_74.6
// CHECK:STDOUT:   %int_0.loc14_74.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_74.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_74.1: <bound method> = bound_method %int_0.loc14_74.1, %impl.elem0.loc14_74.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc14_74.1: <specific function> = specific_function %impl.elem0.loc14_74.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_74.2: <bound method> = bound_method %int_0.loc14_74.1, %specific_fn.loc14_74.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_74.1: init %u1 = call %bound_method.loc14_74.2(%int_0.loc14_74.1) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_74.7: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_74.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_74.8: %u1 = converted %int_0.loc14_74.1, %.loc14_74.7 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_74.9: ref %u1 = class_element_access %.loc14_74.3, element0
// CHECK:STDOUT:   %impl.elem0.loc14_74.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_74.3: <bound method> = bound_method %.loc14_74.8, %impl.elem0.loc14_74.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc14_74.2: <specific function> = specific_function %impl.elem0.loc14_74.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_74.4: <bound method> = bound_method %.loc14_74.8, %specific_fn.loc14_74.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc14_74.10: %u1 = acquire_value %.loc14_74.9
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_74.4(%.loc14_74.8, %.loc14_74.10)
// CHECK:STDOUT:   %.loc14_74.11: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_74.12: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_74.11
// CHECK:STDOUT:   if %.loc14_74.12 br !.loc14_74.1 else br !.loc14_74.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_74.1:
// CHECK:STDOUT:   %.loc14_74.13: ref %.8db = class_element_access %.loc14_74.3, element1
// CHECK:STDOUT:   %.loc14_74.14: ref %tuple.type.a8a = class_element_access %.loc14_74.13, element0
// CHECK:STDOUT:   %tuple.elem0.loc14_74.1: ref %i32 = tuple_access %.loc14_74.14, element0
// CHECK:STDOUT:   %.loc14_74.15: %i32 = acquire_value %tuple.elem0.loc14_74.1
// CHECK:STDOUT:   %emplace.ref.loc14_74.1: %variant.emplace.cpp_overload_set.type = name_ref emplace, imports.%variant.emplace.cpp_overload_set.value [concrete = constants.%variant.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc14_74.5: <bound method> = bound_method %.loc14_74.4, %emplace.ref.loc14_74.1
// CHECK:STDOUT:   %int_0.loc14_74.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc14_74.3: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc14_74.6: <bound method> = bound_method %int_0.loc14_74.2, %impl.elem0.loc14_74.3 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e]
// CHECK:STDOUT:   %specific_fn.loc14_74.3: <specific function> = specific_function %impl.elem0.loc14_74.3, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc14_74.7: <bound method> = bound_method %int_0.loc14_74.2, %specific_fn.loc14_74.3 [concrete = constants.%bound_method.95d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_74.2: init %u64 = call %bound_method.loc14_74.7(%int_0.loc14_74.2) [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc14_74.16: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_74.2 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc14_74.17: %u64 = converted %int_0.loc14_74.2, %.loc14_74.16 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc14_74.18: %variant = acquire_value %.loc14_74.4
// CHECK:STDOUT:   %impl.elem0.loc14_74.4: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_74.8: <bound method> = bound_method %.loc14_74.15, %impl.elem0.loc14_74.4
// CHECK:STDOUT:   %specific_fn.loc14_74.4: <specific function> = specific_function %impl.elem0.loc14_74.4, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_74.9: <bound method> = bound_method %.loc14_74.15, %specific_fn.loc14_74.4
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc14_74.1: init %i32 = call %bound_method.loc14_74.9(%.loc14_74.15)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %addr.loc14_74.2: %ptr.d08 = addr_of %args.var.1
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc14_74.1: ref %i32 = call imports.%emplace__carbon_thunk.decl.b5d853.1(%.loc14_74.18, %addr.loc14_74.2)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   br !.loc14_74.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_74.2:
// CHECK:STDOUT:   %.loc14_74.19: ref %.8db = class_element_access %.loc14_74.3, element1
// CHECK:STDOUT:   %.loc14_74.20: ref %tuple.type.a8a = class_element_access %.loc14_74.19, element1
// CHECK:STDOUT:   %tuple.elem0.loc14_74.2: ref %i32 = tuple_access %.loc14_74.20, element0
// CHECK:STDOUT:   %.loc14_74.21: %i32 = acquire_value %tuple.elem0.loc14_74.2
// CHECK:STDOUT:   %emplace.ref.loc14_74.2: %variant.emplace.cpp_overload_set.type = name_ref emplace, imports.%variant.emplace.cpp_overload_set.value [concrete = constants.%variant.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc14_74.10: <bound method> = bound_method %.loc14_74.4, %emplace.ref.loc14_74.2
// CHECK:STDOUT:   %int_1.loc14: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc14_74.5: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc14_74.11: <bound method> = bound_method %int_1.loc14, %impl.elem0.loc14_74.5 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0]
// CHECK:STDOUT:   %specific_fn.loc14_74.5: <specific function> = specific_function %impl.elem0.loc14_74.5, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc14_74.12: <bound method> = bound_method %int_1.loc14, %specific_fn.loc14_74.5 [concrete = constants.%bound_method.7e7]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_74.3: init %u64 = call %bound_method.loc14_74.12(%int_1.loc14) [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc14_74.22: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_74.3 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc14_74.23: %u64 = converted %int_1.loc14, %.loc14_74.22 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc14_74.24: %variant = acquire_value %.loc14_74.4
// CHECK:STDOUT:   %impl.elem0.loc14_74.6: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_74.13: <bound method> = bound_method %.loc14_74.21, %impl.elem0.loc14_74.6
// CHECK:STDOUT:   %specific_fn.loc14_74.6: <specific function> = specific_function %impl.elem0.loc14_74.6, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_74.14: <bound method> = bound_method %.loc14_74.21, %specific_fn.loc14_74.6
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc14_74.2: init %i32 = call %bound_method.loc14_74.14(%.loc14_74.21)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %addr.loc14_74.3: %ptr.d08 = addr_of %args.var.2
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc14_74.2: ref %i32 = call imports.%emplace__carbon_thunk.decl.b5d853.2(%.loc14_74.24, %addr.loc14_74.3)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   br !.loc14_74.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_74.3:
// CHECK:STDOUT:   %.loc14_74.25: %variant = acquire_value %.loc14_74.4
// CHECK:STDOUT:   %.loc14_74.26: %variant = converted %StdVariant2.Alt1.call.loc14, %.loc14_74.25
// CHECK:STDOUT:   %.loc14_74.27: ref %variant = value_as_ref %.loc14_74.26
// CHECK:STDOUT:   %addr.loc14_75: %ptr.b2b = addr_of %.loc14_74.27
// CHECK:STDOUT:   %.loc14_75.1: %ptr.940 = as_compatible %addr.loc14_75
// CHECK:STDOUT:   %.loc14_75.2: %ptr.940 = converted %addr.loc14_75, %.loc14_75.1
// CHECK:STDOUT:   %TakePair__carbon_thunk.call: init %i32 = call imports.%TakePair__carbon_thunk.decl(%.loc14_75.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14: <bound method> = bound_method %.loc14_74.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.7
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14(%.loc14_74.2)
// CHECK:STDOUT:   return %TakePair__carbon_thunk.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc13:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_1.loc17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc17_10: <bound method> = bound_method %int_1.loc17, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc17_10(%int_1.loc17) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc17 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc17_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc17_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc17_10.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %i32 = call %bound_method.loc17_12.2(%.loc17_10.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc17_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc17_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9(%self.param: ref %variant) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9(%self.param: ref %variant) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %variant.cpp_destructor.call: init %empty_tuple.type = call imports.%variant.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_74.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_74.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_74.1(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_74.2(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_74.2(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_74.2(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_74.3(%self.param: ref %.8db) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_74.3(%self.param: ref %.8db) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_74.3(%self.param: ref %.8db) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_74.4(%self.param: ref %struct_type.discriminant.payload.81e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc14_74.1: ref %.8db = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_74.1: <bound method> = bound_method %.loc14_74.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_74.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_74.1(%.loc14_74.1)
// CHECK:STDOUT:   %.loc14_74.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_74.2: <bound method> = bound_method %.loc14_74.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_74.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_74.2(%.loc14_74.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_74.4(%self.param: ref %struct_type.discriminant.payload.81e) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_74.4(%self.param: ref %struct_type.discriminant.payload.81e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_74.5(%self.param: ref %StdVariant2.c29) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_74.5(%self.param: ref %StdVariant2.c29) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_74.5(%self.param: ref %StdVariant2.c29) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.7(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- pointer_reverse.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.Get.type.bb9: type = fn_type @Optional.Get, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.Get.fa1: %Optional.Get.type.bb9 = struct_value () [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.type.e9e: type = fn_type @Optional.HasValue, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.6cd: %Optional.HasValue.type.e9e = struct_value () [symbolic]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.type.015: type = fn_type @ptr.as.OptionalStorage.impl.Get, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Get.972: %ptr.as.OptionalStorage.impl.Get.type.015 = struct_value () [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.type.0e1: type = fn_type @ptr.as.OptionalStorage.impl.Has, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.05c: %ptr.as.OptionalStorage.impl.Has.type.0e1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.4ee: %Destroy.type = facet_value %ptr.d08, (%custom_witness.f8f19d.1) [concrete]
// CHECK:STDOUT:   %MaybeUnformed.729: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.4ee) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.0ce: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%i32) [concrete]
// CHECK:STDOUT:   %.0f8: type = maybe_unformed_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet: %OptionalStorage.type = facet_value %ptr.d08, (%OptionalStorage.impl_witness.0ce) [concrete]
// CHECK:STDOUT:   %Optional.5b3: type = class_type @Optional, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %pattern_type.ef8: type = pattern_type %Optional.5b3 [concrete]
// CHECK:STDOUT:   %p.param_patt: %pattern_type.ef8 = value_param_pattern [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.ef8 = wrapper_binding_pattern p, %p.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %R.type: type = fn_type @R [concrete]
// CHECK:STDOUT:   %R: %R.type = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.HasValue.type.c62: type = fn_type @Optional.HasValue, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.HasValue.84d: %Optional.HasValue.type.c62 = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.Get.type.76f: type = fn_type @Optional.Get, @Optional(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.Get.d19: %Optional.Get.type.76f = struct_value () [concrete]
// CHECK:STDOUT:   %TakeIntOrPointer.cpp_overload_set.type: type = cpp_overload_set_type @TakeIntOrPointer.cpp_overload_set [concrete]
// CHECK:STDOUT:   %TakeIntOrPointer.cpp_overload_set.value: %TakeIntOrPointer.cpp_overload_set.type = cpp_overload_set_value @TakeIntOrPointer.cpp_overload_set [concrete]
// CHECK:STDOUT:   %StdVariant2.type: type = generic_class_type @StdVariant2 [concrete]
// CHECK:STDOUT:   %StdVariant2.generic: %StdVariant2.type = struct_value () [concrete]
// CHECK:STDOUT:   %T1: type = symbolic_binding T1, 1 [symbolic]
// CHECK:STDOUT:   %T0: type = symbolic_binding T0, 0 [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %UInt.type: type = generic_class_type @UInt [concrete]
// CHECK:STDOUT:   %UInt.generic: %UInt.type = struct_value () [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.type.45e: type = fn_type @StdVariant2.Alt1, @StdVariant2(%T0, %T1) [symbolic]
// CHECK:STDOUT:   %StdVariant2.Alt1.b0b: %StdVariant2.Alt1.type.45e = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %StdVariant2.4b0: type = class_type @StdVariant2, @StdVariant2(%i32, %Optional.5b3) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e2f: type = tuple_type (%Optional.5b3) [concrete]
// CHECK:STDOUT:   %.b13: type = custom_layout_type {size=8, align=8, .Alt0@0: %tuple.type.a8a, .Alt1@0: %tuple.type.e2f} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.b75: type = struct_type {.discriminant: %u1, .payload: %.b13} [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.type.377: type = fn_type @StdVariant2.Alt1, @StdVariant2(%i32, %Optional.5b3) [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.01f: %StdVariant2.Alt1.type.377 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.fd1: type = pattern_type %StdVariant2.4b0 [concrete]
// CHECK:STDOUT:   %StdVariant2.Alt1.specific_fn: <specific function> = specific_function %StdVariant2.Alt1.01f, @StdVariant2.Alt1(%i32, %Optional.5b3) [concrete]
// CHECK:STDOUT:   %variant: type = class_type @variant [concrete]
// CHECK:STDOUT:   %ptr.159: type = ptr_type %variant [concrete]
// CHECK:STDOUT:   %TakeIntOrPointer__carbon_thunk.type: type = fn_type @TakeIntOrPointer__carbon_thunk [concrete]
// CHECK:STDOUT:   %TakeIntOrPointer__carbon_thunk: %TakeIntOrPointer__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %u64: type = class_type @UInt, @UInt(%int_64) [concrete]
// CHECK:STDOUT:   %variant.variant.cpp_overload_set.type: type = cpp_overload_set_type @variant.variant.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant.variant.cpp_overload_set.value: %variant.variant.cpp_overload_set.type = cpp_overload_set_value @variant.variant.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant__carbon_thunk.type: type = fn_type @variant__carbon_thunk [concrete]
// CHECK:STDOUT:   %variant__carbon_thunk: %variant__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %pattern_type.322: type = pattern_type %u1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %variant.emplace.cpp_overload_set.type: type = cpp_overload_set_type @variant.emplace.cpp_overload_set [concrete]
// CHECK:STDOUT:   %variant.emplace.cpp_overload_set.value: %variant.emplace.cpp_overload_set.type = cpp_overload_set_value @variant.emplace.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.14f: type = facet_type <@ImplicitAs, @ImplicitAs(%u64)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.8d9: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.b18: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_64) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.633: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.b18 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.e08: %ImplicitAs.type.14f = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.8d9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.17c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u64, %ImplicitAs.facet.e08) [concrete]
// CHECK:STDOUT:   %.ed5: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.17c, %ImplicitAs.facet.e08 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.633 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.633, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_64) [concrete]
// CHECK:STDOUT:   %bound_method.95d: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53 [concrete]
// CHECK:STDOUT:   %int_0.07a: %u64 = int_value 0 [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.type.12b0d0.1: type = fn_type @emplace__carbon_thunk.1 [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.8001d1.1: %emplace__carbon_thunk.type.12b0d0.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Optional.HasValue.specific_fn: <specific function> = specific_function %Optional.HasValue.84d, @Optional.HasValue(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Optional.Get.specific_fn: <specific function> = specific_function %Optional.Get.d19, @Optional.Get(%OptionalStorage.facet) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.633 [concrete]
// CHECK:STDOUT:   %bound_method.7e7: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53 [concrete]
// CHECK:STDOUT:   %int_1.01f: %u64 = int_value 1 [concrete]
// CHECK:STDOUT:   %ptr.c36: type = ptr_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.type.12b0d0.2: type = fn_type @emplace__carbon_thunk.2 [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.8001d1.2: %emplace__carbon_thunk.type.12b0d0.2 = struct_value () [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.type.12b0d0.3: type = fn_type @emplace__carbon_thunk.3 [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.8001d1.3: %emplace__carbon_thunk.type.12b0d0.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.7c14: %pattern_type.322 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.945: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt.7c14 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_66.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc13_66.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.3: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_66.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.3: %Destroy.WithSelf.SelfDestruct.type.fbceb5.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_66.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc13_66.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.59d: type = pattern_type %.0f8 [concrete]
// CHECK:STDOUT:   %self.param_patt.9e1: %pattern_type.59d = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.8da: %pattern_type.59d = wrapper_binding_pattern self, %self.param_patt.9e1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_66.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc13_66.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6db: type = pattern_type %MaybeUnformed.729 [concrete]
// CHECK:STDOUT:   %self.param_patt.e99: %pattern_type.6db = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e88: %pattern_type.6db = wrapper_binding_pattern self, %self.param_patt.e99 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_66.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc13_66.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.d96: %pattern_type.ef8 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.77d: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt.d96 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_66.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.7: type = fn_type @Destroy.WithSelf.Op.loc13_66.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.7: %Destroy.WithSelf.Op.type.ef016f.7 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.7: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_66.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.7: %Destroy.WithSelf.SelfDestruct.type.fbceb5.7 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.26e: type = pattern_type %tuple.type.e2f [concrete]
// CHECK:STDOUT:   %self.param_patt.a2b: %pattern_type.26e = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.114: %pattern_type.26e = wrapper_binding_pattern self, %self.param_patt.a2b [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_66.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.8: type = fn_type @Destroy.WithSelf.Op.loc13_66.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.8: %Destroy.WithSelf.Op.type.ef016f.8 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6b1: type = pattern_type %.b13 [concrete]
// CHECK:STDOUT:   %self.param_patt.f26: %pattern_type.6b1 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.3d7: %pattern_type.6b1 = wrapper_binding_pattern self, %self.param_patt.f26 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_66.7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.9: type = fn_type @Destroy.WithSelf.Op.loc13_66.7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.9: %Destroy.WithSelf.Op.type.ef016f.9 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.9: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_66.7 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.9: %Destroy.WithSelf.SelfDestruct.type.fbceb5.9 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.fa7: type = pattern_type %struct_type.discriminant.payload.b75 [concrete]
// CHECK:STDOUT:   %self.param_patt.b71: %pattern_type.fa7 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.2fd: %pattern_type.fa7 = wrapper_binding_pattern self, %self.param_patt.b71 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_66.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.10: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.10: type = fn_type @Destroy.WithSelf.Op.loc13_66.8 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.10: %Destroy.WithSelf.Op.type.ef016f.10 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.8ef: %pattern_type.fd1 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.21a: %pattern_type.fd1 = wrapper_binding_pattern self, %self.param_patt.8ef [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc13_66.9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.11: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.11: type = fn_type @Destroy.WithSelf.Op.loc13_66.9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.11: %Destroy.WithSelf.Op.type.ef016f.11 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.11: type = fn_type @Destroy.WithSelf.SelfDestruct.loc13_66.9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.11: %Destroy.WithSelf.SelfDestruct.type.fbceb5.11 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .UInt = %Core.UInt
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .TakeIntOrPointer = %TakeIntOrPointer.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.729: @Optional.%Optional.HasValue.type (%Optional.HasValue.type.e9e) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.HasValue (constants.%Optional.HasValue.6cd)]
// CHECK:STDOUT:   %Core.import_ref.497: @Optional.%Optional.Get.type (%Optional.Get.type.bb9) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.Get (constants.%Optional.Get.fa1)]
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.import_ref.509: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%MaybeUnformed (constants.%MaybeUnformed.ddb)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.c9a = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.575: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has.type (%ptr.as.OptionalStorage.impl.Has.type.0e1) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has (constants.%ptr.as.OptionalStorage.impl.Has.05c)]
// CHECK:STDOUT:   %Core.import_ref.008: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get.type (%ptr.as.OptionalStorage.impl.Get.type.015) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Get (constants.%ptr.as.OptionalStorage.impl.Get.972)]
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.509, %Core.import_ref.105, %Core.import_ref.c9a, %Core.import_ref.575, %Core.import_ref.008, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %TakeIntOrPointer.cpp_overload_set.value: %TakeIntOrPointer.cpp_overload_set.type = cpp_overload_set_value @TakeIntOrPointer.cpp_overload_set [concrete = constants.%TakeIntOrPointer.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .StdVariant2 = %Core.StdVariant2
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StdVariant2: %StdVariant2.type = import_ref Core//prelude/types/cpp/sum, StdVariant2, loaded [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %Core.import_ref.e76: @StdVariant2.%StdVariant2.Alt1.type (%StdVariant2.Alt1.type.45e) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdVariant2.%StdVariant2.Alt1 (constants.%StdVariant2.Alt1.b0b)]
// CHECK:STDOUT:   %TakeIntOrPointer__carbon_thunk.decl: %TakeIntOrPointer__carbon_thunk.type = fn_decl @TakeIntOrPointer__carbon_thunk [concrete = constants.%TakeIntOrPointer__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.UInt: %UInt.type = import_ref Core//prelude/types/uint, UInt, loaded [concrete = constants.%UInt.generic]
// CHECK:STDOUT:   %variant.variant.cpp_overload_set.value: %variant.variant.cpp_overload_set.type = cpp_overload_set_value @variant.variant.cpp_overload_set [concrete = constants.%variant.variant.cpp_overload_set.value]
// CHECK:STDOUT:   %variant__carbon_thunk.decl: %variant__carbon_thunk.type = fn_decl @variant__carbon_thunk [concrete = constants.%variant__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %variant.emplace.cpp_overload_set.value: %variant.emplace.cpp_overload_set.type = cpp_overload_set_value @variant.emplace.cpp_overload_set [concrete = constants.%variant.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %emplace__carbon_thunk.decl.b5d853.1: %emplace__carbon_thunk.type.12b0d0.1 = fn_decl @emplace__carbon_thunk.1 [concrete = constants.%emplace__carbon_thunk.8001d1.1] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %emplace__carbon_thunk.decl.b5d853.2: %emplace__carbon_thunk.type.12b0d0.2 = fn_decl @emplace__carbon_thunk.2 [concrete = constants.%emplace__carbon_thunk.8001d1.2] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:     %OptionalStorage.facet: %OptionalStorage.type = facet_value constants.%ptr.d08, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %.loc13: %OptionalStorage.type = converted constants.%ptr.d08, %OptionalStorage.facet [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %Optional: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %emplace__carbon_thunk.decl.b5d853.3: %emplace__carbon_thunk.type.12b0d0.3 = fn_decl @emplace__carbon_thunk.3 [concrete = constants.%emplace__carbon_thunk.8001d1.3] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:     %OptionalStorage.facet: %OptionalStorage.type = facet_value constants.%ptr.d08, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %.loc13: %OptionalStorage.type = converted constants.%ptr.d08, %OptionalStorage.facet [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:     %Optional: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_66.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c14]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc13_66.1 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c14]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_66.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc13_66.2 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_66.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.59d = ref_param_pattern [concrete = constants.%self.param_patt.9e1]
// CHECK:STDOUT:     %self.patt: %pattern_type.59d = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.8da]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.0f8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.0f8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc13_66.3 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.59d = ref_param_pattern [concrete = constants.%self.param_patt.9e1]
// CHECK:STDOUT:     %self.patt: %pattern_type.59d = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.8da]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.0f8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.0f8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_66.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6db = ref_param_pattern [concrete = constants.%self.param_patt.e99]
// CHECK:STDOUT:     %self.patt: %pattern_type.6db = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e88]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %MaybeUnformed.729 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %MaybeUnformed.729 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc13_66.4 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6db = ref_param_pattern [concrete = constants.%self.param_patt.e99]
// CHECK:STDOUT:     %self.patt: %pattern_type.6db = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e88]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %MaybeUnformed.729 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %MaybeUnformed.729 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.7: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.7 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_66.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.7: %Destroy.WithSelf.Op.type.ef016f.7 = fn_decl @Destroy.WithSelf.Op.loc13_66.5 [concrete = constants.%Destroy.WithSelf.Op.403171.7] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.8: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.8 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_66.6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.26e = ref_param_pattern [concrete = constants.%self.param_patt.a2b]
// CHECK:STDOUT:     %self.patt: %pattern_type.26e = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.114]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.e2f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.e2f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.8: %Destroy.WithSelf.Op.type.ef016f.8 = fn_decl @Destroy.WithSelf.Op.loc13_66.6 [concrete = constants.%Destroy.WithSelf.Op.403171.8] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.26e = ref_param_pattern [concrete = constants.%self.param_patt.a2b]
// CHECK:STDOUT:     %self.patt: %pattern_type.26e = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.114]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.e2f = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.e2f = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.9: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.9 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_66.7 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b1 = ref_param_pattern [concrete = constants.%self.param_patt.f26]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b1 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.3d7]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.b13 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.b13 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.9: %Destroy.WithSelf.Op.type.ef016f.9 = fn_decl @Destroy.WithSelf.Op.loc13_66.7 [concrete = constants.%Destroy.WithSelf.Op.403171.9] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b1 = ref_param_pattern [concrete = constants.%self.param_patt.f26]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b1 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.3d7]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.b13 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.b13 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.10: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.10 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_66.8 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.10] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.fa7 = ref_param_pattern [concrete = constants.%self.param_patt.b71]
// CHECK:STDOUT:     %self.patt: %pattern_type.fa7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.2fd]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.b75 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.b75 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.10: %Destroy.WithSelf.Op.type.ef016f.10 = fn_decl @Destroy.WithSelf.Op.loc13_66.8 [concrete = constants.%Destroy.WithSelf.Op.403171.10] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.fa7 = ref_param_pattern [concrete = constants.%self.param_patt.b71]
// CHECK:STDOUT:     %self.patt: %pattern_type.fa7 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.2fd]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.b75 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.b75 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.11: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.11 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc13_66.9 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.11] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.fd1 = ref_param_pattern [concrete = constants.%self.param_patt.8ef]
// CHECK:STDOUT:     %self.patt: %pattern_type.fd1 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.21a]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %StdVariant2.4b0 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %StdVariant2.4b0 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.11: %Destroy.WithSelf.Op.type.ef016f.11 = fn_decl @Destroy.WithSelf.Op.loc13_66.9 [concrete = constants.%Destroy.WithSelf.Op.403171.11] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.fd1 = ref_param_pattern [concrete = constants.%self.param_patt.8ef]
// CHECK:STDOUT:     %self.patt: %pattern_type.fd1 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.21a]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %StdVariant2.4b0 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %StdVariant2.4b0 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %R.decl: %R.type = fn_decl @R [concrete = constants.%R] {
// CHECK:STDOUT:     %p.param_patt: %pattern_type.ef8 = value_param_pattern [concrete = constants.%p.param_patt]
// CHECK:STDOUT:     %p.patt: %pattern_type.ef8 = wrapper_binding_pattern p, %p.param_patt [concrete = constants.%p.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc11_33 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc11_33: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_33: Core.Form = init_form %i32.loc11_33 [concrete = constants.%.795]
// CHECK:STDOUT:     %p.param: %Optional.5b3 = value_param call_param0
// CHECK:STDOUT:     %.loc11_27.1: type = splice_block %Optional.loc11 [concrete = constants.%Optional.5b3] {
// CHECK:STDOUT:       %Core.ref.loc11: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %Optional.ref.loc11: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:       %i32.loc11_23: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %ptr.loc11: type = ptr_type %i32.loc11_23 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:       %OptionalStorage.facet.loc11: %OptionalStorage.type = facet_value %ptr.loc11, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:       %.loc11_27.2: %OptionalStorage.type = converted %ptr.loc11, %OptionalStorage.facet.loc11 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:       %Optional.loc11: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %p: %Optional.5b3 = wrapper_binding p, %p.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @R(%p.param: %Optional.5b3) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %TakeIntOrPointer.ref: %TakeIntOrPointer.cpp_overload_set.type = name_ref TakeIntOrPointer, imports.%TakeIntOrPointer.cpp_overload_set.value [concrete = constants.%TakeIntOrPointer.cpp_overload_set.value]
// CHECK:STDOUT:   %Core.ref.loc13_7: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %CppCompat.ref: <namespace> = name_ref CppCompat, imports.%CppCompat.f0dbf9.1 [concrete = imports.%CppCompat.f0dbf9.1]
// CHECK:STDOUT:   %StdVariant2.ref.loc13_21: %StdVariant2.type = name_ref StdVariant2, imports.%Core.StdVariant2 [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %i32.loc13_34: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %Core.ref.loc13_39: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %Optional.ref.loc13: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %i32.loc13_53: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %ptr.loc13: type = ptr_type %i32.loc13_53 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:   %OptionalStorage.facet.loc13_57: %OptionalStorage.type = facet_value %ptr.loc13, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc13_57: %OptionalStorage.type = converted %ptr.loc13, %OptionalStorage.facet.loc13_57 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %Optional.loc13_57: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   %StdVariant2.loc13_58: type = class_type @StdVariant2, @StdVariant2(constants.%i32, constants.%Optional.5b3) [concrete = constants.%StdVariant2.4b0]
// CHECK:STDOUT:   %.loc13_59: %StdVariant2.Alt1.type.377 = specific_constant imports.%Core.import_ref.e76, @StdVariant2(constants.%i32, constants.%Optional.5b3) [concrete = constants.%StdVariant2.Alt1.01f]
// CHECK:STDOUT:   %Alt1.ref: %StdVariant2.Alt1.type.377 = name_ref Alt1, %.loc13_59 [concrete = constants.%StdVariant2.Alt1.01f]
// CHECK:STDOUT:   %p.ref: %Optional.5b3 = name_ref p, %p
// CHECK:STDOUT:   %StdVariant2.Alt1.specific_fn: <specific function> = specific_function %Alt1.ref, @StdVariant2.Alt1(constants.%i32, constants.%Optional.5b3) [concrete = constants.%StdVariant2.Alt1.specific_fn]
// CHECK:STDOUT:   %.loc13_66.1: ref %StdVariant2.4b0 = temporary_storage
// CHECK:STDOUT:   %StdVariant2.Alt1.call: init %StdVariant2.4b0 to %.loc13_66.1 = call %StdVariant2.Alt1.specific_fn(%p.ref)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %OptionalStorage.facet.loc13_66: %OptionalStorage.type = facet_value constants.%ptr.d08, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %.loc13_66.2: %OptionalStorage.type = converted constants.%ptr.d08, %OptionalStorage.facet.loc13_66 [concrete = constants.%OptionalStorage.facet]
// CHECK:STDOUT:   %Optional.loc13_66: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   %StdVariant2.ref.loc13_66: %StdVariant2.type = name_ref StdVariant2, imports.%Core.StdVariant2 [concrete = constants.%StdVariant2.generic]
// CHECK:STDOUT:   %StdVariant2.loc13_66: type = class_type @StdVariant2, @StdVariant2(constants.%i32, constants.%Optional.5b3) [concrete = constants.%StdVariant2.4b0]
// CHECK:STDOUT:   %.loc13_66.3: ref %StdVariant2.4b0 = temporary %.loc13_66.1, %StdVariant2.Alt1.call
// CHECK:STDOUT:   %.loc13_66.4: %StdVariant2.4b0 = acquire_value %.loc13_66.3
// CHECK:STDOUT:   %.loc13_66.5: ref %variant = temporary_storage
// CHECK:STDOUT:   %variant.ref: %variant.variant.cpp_overload_set.type = name_ref variant, imports.%variant.variant.cpp_overload_set.value [concrete = constants.%variant.variant.cpp_overload_set.value]
// CHECK:STDOUT:   %.loc13_66.6: ref %variant = splice_block %.loc13_66.5 {}
// CHECK:STDOUT:   %addr.loc13_66.1: %ptr.159 = addr_of %.loc13_66.6
// CHECK:STDOUT:   %variant__carbon_thunk.call: init %empty_tuple.type = call imports.%variant__carbon_thunk.decl(%addr.loc13_66.1)
// CHECK:STDOUT:   %.loc13_66.7: init %variant to %.loc13_66.6 = mark_in_place_init %variant__carbon_thunk.call
// CHECK:STDOUT:   assign %.loc13_66.5, %.loc13_66.7
// CHECK:STDOUT:   %int_0.loc13_66.1: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_66.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_66.1: <bound method> = bound_method %int_0.loc13_66.1, %impl.elem0.loc13_66.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc13_66.1: <specific function> = specific_function %impl.elem0.loc13_66.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_66.2: <bound method> = bound_method %int_0.loc13_66.1, %specific_fn.loc13_66.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_66.1: init %u1 = call %bound_method.loc13_66.2(%int_0.loc13_66.1) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_66.8: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_66.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_66.9: %u1 = converted %int_0.loc13_66.1, %.loc13_66.8 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_66.10: ref %u1 = class_element_access %.loc13_66.4, element0
// CHECK:STDOUT:   %impl.elem0.loc13_66.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_66.3: <bound method> = bound_method %.loc13_66.9, %impl.elem0.loc13_66.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc13_66.2: <specific function> = specific_function %impl.elem0.loc13_66.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_66.4: <bound method> = bound_method %.loc13_66.9, %specific_fn.loc13_66.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc13_66.11: %u1 = acquire_value %.loc13_66.10
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc13_66.4(%.loc13_66.9, %.loc13_66.11)
// CHECK:STDOUT:   %.loc13_66.12: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc13_66.13: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc13_66.12
// CHECK:STDOUT:   if %.loc13_66.13 br !.loc13_66.1 else br !.loc13_66.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_66.1:
// CHECK:STDOUT:   %.loc13_66.14: ref %.b13 = class_element_access %.loc13_66.4, element1
// CHECK:STDOUT:   %.loc13_66.15: ref %tuple.type.a8a = class_element_access %.loc13_66.14, element0
// CHECK:STDOUT:   %tuple.elem0.loc13_66.1: ref %i32 = tuple_access %.loc13_66.15, element0
// CHECK:STDOUT:   %.loc13_66.16: %i32 = acquire_value %tuple.elem0.loc13_66.1
// CHECK:STDOUT:   %emplace.ref.loc13_66.1: %variant.emplace.cpp_overload_set.type = name_ref emplace, imports.%variant.emplace.cpp_overload_set.value [concrete = constants.%variant.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc13_66.5: <bound method> = bound_method %.loc13_66.5, %emplace.ref.loc13_66.1
// CHECK:STDOUT:   %int_0.loc13_66.2: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc13_66.3: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc13_66.6: <bound method> = bound_method %int_0.loc13_66.2, %impl.elem0.loc13_66.3 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.28e]
// CHECK:STDOUT:   %specific_fn.loc13_66.3: <specific function> = specific_function %impl.elem0.loc13_66.3, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc13_66.7: <bound method> = bound_method %int_0.loc13_66.2, %specific_fn.loc13_66.3 [concrete = constants.%bound_method.95d]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_66.2: init %u64 = call %bound_method.loc13_66.7(%int_0.loc13_66.2) [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc13_66.17: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_66.2 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc13_66.18: %u64 = converted %int_0.loc13_66.2, %.loc13_66.17 [concrete = constants.%int_0.07a]
// CHECK:STDOUT:   %.loc13_66.19: %variant = acquire_value %.loc13_66.5
// CHECK:STDOUT:   %impl.elem0.loc13_66.4: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc13_66.8: <bound method> = bound_method %.loc13_66.16, %impl.elem0.loc13_66.4
// CHECK:STDOUT:   %specific_fn.loc13_66.4: <specific function> = specific_function %impl.elem0.loc13_66.4, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_66.9: <bound method> = bound_method %.loc13_66.16, %specific_fn.loc13_66.4
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc13_66.9(%.loc13_66.16)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %addr.loc13_66.2: %ptr.d08 = addr_of %args.var.1
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc13_66.1: ref %i32 = call imports.%emplace__carbon_thunk.decl.b5d853.1(%.loc13_66.19, %addr.loc13_66.2)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   br !.loc13_66.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_66.2:
// CHECK:STDOUT:   %.loc13_66.20: ref %.b13 = class_element_access %.loc13_66.4, element1
// CHECK:STDOUT:   %.loc13_66.21: ref %tuple.type.e2f = class_element_access %.loc13_66.20, element1
// CHECK:STDOUT:   %tuple.elem0.loc13_66.2: ref %Optional.5b3 = tuple_access %.loc13_66.21, element0
// CHECK:STDOUT:   %.loc13_66.22: %Optional.5b3 = acquire_value %tuple.elem0.loc13_66.2
// CHECK:STDOUT:   %.loc13_66.23: %Optional.HasValue.type.c62 = specific_constant imports.%Core.import_ref.729, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.HasValue.84d]
// CHECK:STDOUT:   %HasValue.ref: %Optional.HasValue.type.c62 = name_ref HasValue, %.loc13_66.23 [concrete = constants.%Optional.HasValue.84d]
// CHECK:STDOUT:   %Optional.HasValue.bound: <bound method> = bound_method %.loc13_66.22, %HasValue.ref
// CHECK:STDOUT:   %Optional.HasValue.specific_fn: <specific function> = specific_function %HasValue.ref, @Optional.HasValue(constants.%OptionalStorage.facet) [concrete = constants.%Optional.HasValue.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_66.10: <bound method> = bound_method %.loc13_66.22, %Optional.HasValue.specific_fn
// CHECK:STDOUT:   %Optional.HasValue.call: init bool = call %bound_method.loc13_66.10(%.loc13_66.22)
// CHECK:STDOUT:   %.loc13_66.24: bool = value_of_initializer %Optional.HasValue.call
// CHECK:STDOUT:   %.loc13_66.25: bool = converted %Optional.HasValue.call, %.loc13_66.24
// CHECK:STDOUT:   if %.loc13_66.25 br !.loc13_66.4 else br !.loc13_66.5
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_66.4:
// CHECK:STDOUT:   %.loc13_66.26: %Optional.Get.type.76f = specific_constant imports.%Core.import_ref.497, @Optional(constants.%OptionalStorage.facet) [concrete = constants.%Optional.Get.d19]
// CHECK:STDOUT:   %Get.ref: %Optional.Get.type.76f = name_ref Get, %.loc13_66.26 [concrete = constants.%Optional.Get.d19]
// CHECK:STDOUT:   %Optional.Get.bound: <bound method> = bound_method %.loc13_66.22, %Get.ref
// CHECK:STDOUT:   %Optional.Get.specific_fn: <specific function> = specific_function %Get.ref, @Optional.Get(constants.%OptionalStorage.facet) [concrete = constants.%Optional.Get.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_66.11: <bound method> = bound_method %.loc13_66.22, %Optional.Get.specific_fn
// CHECK:STDOUT:   %Optional.Get.call: init %ptr.d08 = call %bound_method.loc13_66.11(%.loc13_66.22)
// CHECK:STDOUT:   %emplace.ref.loc13_66.2: %variant.emplace.cpp_overload_set.type = name_ref emplace, imports.%variant.emplace.cpp_overload_set.value [concrete = constants.%variant.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc13_66.12: <bound method> = bound_method %.loc13_66.5, %emplace.ref.loc13_66.2
// CHECK:STDOUT:   %int_1.loc13_66.1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc13_66.5: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc13_66.13: <bound method> = bound_method %int_1.loc13_66.1, %impl.elem0.loc13_66.5 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0]
// CHECK:STDOUT:   %specific_fn.loc13_66.5: <specific function> = specific_function %impl.elem0.loc13_66.5, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc13_66.14: <bound method> = bound_method %int_1.loc13_66.1, %specific_fn.loc13_66.5 [concrete = constants.%bound_method.7e7]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_66.3: init %u64 = call %bound_method.loc13_66.14(%int_1.loc13_66.1) [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc13_66.27: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_66.3 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc13_66.28: %u64 = converted %int_1.loc13_66.1, %.loc13_66.27 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc13_66.29: %variant = acquire_value %.loc13_66.5
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %addr.loc13_66.3: %ptr.c36 = addr_of %args.var.2
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc13_66.2: ref %Optional.5b3 = call imports.%emplace__carbon_thunk.decl.b5d853.2(%.loc13_66.29, %addr.loc13_66.3)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   br !.loc13_66.6
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_66.5:
// CHECK:STDOUT:   %emplace.ref.loc13_66.3: %variant.emplace.cpp_overload_set.type = name_ref emplace, imports.%variant.emplace.cpp_overload_set.value [concrete = constants.%variant.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc13_66.15: <bound method> = bound_method %.loc13_66.5, %emplace.ref.loc13_66.3
// CHECK:STDOUT:   %int_1.loc13_66.2: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc13_66.6: %.ed5 = impl_witness_access constants.%ImplicitAs.impl_witness.8d9, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.633]
// CHECK:STDOUT:   %bound_method.loc13_66.16: <bound method> = bound_method %int_1.loc13_66.2, %impl.elem0.loc13_66.6 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.eb0]
// CHECK:STDOUT:   %specific_fn.loc13_66.6: <specific function> = specific_function %impl.elem0.loc13_66.6, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_64) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e53]
// CHECK:STDOUT:   %bound_method.loc13_66.17: <bound method> = bound_method %int_1.loc13_66.2, %specific_fn.loc13_66.6 [concrete = constants.%bound_method.7e7]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_66.4: init %u64 = call %bound_method.loc13_66.17(%int_1.loc13_66.2) [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc13_66.30: %u64 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_66.4 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc13_66.31: %u64 = converted %int_1.loc13_66.2, %.loc13_66.30 [concrete = constants.%int_1.01f]
// CHECK:STDOUT:   %.loc13_66.32: %variant = acquire_value %.loc13_66.5
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc13_66.3: ref %Optional.5b3 = call imports.%emplace__carbon_thunk.decl.b5d853.3(%.loc13_66.32)
// CHECK:STDOUT:   br !.loc13_66.6
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_66.6:
// CHECK:STDOUT:   br !.loc13_66.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc13_66.3:
// CHECK:STDOUT:   %.loc13_66.33: %variant = acquire_value %.loc13_66.5
// CHECK:STDOUT:   %.loc13_66.34: %variant = converted %StdVariant2.Alt1.call, %.loc13_66.33
// CHECK:STDOUT:   %.loc13_66.35: ref %variant = value_as_ref %.loc13_66.34
// CHECK:STDOUT:   %addr.loc13_67: %ptr.159 = addr_of %.loc13_66.35
// CHECK:STDOUT:   %TakeIntOrPointer__carbon_thunk.call: init %i32 = call imports.%TakeIntOrPointer__carbon_thunk.decl(%addr.loc13_67)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc13_66.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.11
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc13_66.3)
// CHECK:STDOUT:   return %TakeIntOrPointer__carbon_thunk.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_66.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_66.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_66.1(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_66.2(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_66.2(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_66.2(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_66.3(%self.param: ref %.0f8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_66.3(%self.param: ref %.0f8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_66.3(%self.param: ref %.0f8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_66.4(%self.param: ref %MaybeUnformed.729) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_66.4(%self.param: ref %MaybeUnformed.729) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_66.4(%self.param: ref %MaybeUnformed.729) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_66.5(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_66.5(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_66.5(%self.param: ref %Optional.5b3) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.7(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.7(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_66.6(%self.param: ref %tuple.type.e2f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %Optional.5b3 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.7
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_66.6(%self.param: ref %tuple.type.e2f) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_66.6(%self.param: ref %tuple.type.e2f) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.8(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.8(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_66.7(%self.param: ref %.b13) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_66.7(%self.param: ref %.b13) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_66.7(%self.param: ref %.b13) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.9(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.9(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_66.8(%self.param: ref %struct_type.discriminant.payload.b75) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc13_66.1: ref %.b13 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_66.1: <bound method> = bound_method %.loc13_66.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.9
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_66.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_66.1(%.loc13_66.1)
// CHECK:STDOUT:   %.loc13_66.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc13_66.2: <bound method> = bound_method %.loc13_66.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc13_66.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc13_66.2(%.loc13_66.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_66.8(%self.param: ref %struct_type.discriminant.payload.b75) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_66.8(%self.param: ref %struct_type.discriminant.payload.b75) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.10(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.10(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc13_66.9(%self.param: ref %StdVariant2.4b0) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc13_66.9(%self.param: ref %StdVariant2.4b0) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc13_66.9(%self.param: ref %StdVariant2.4b0) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.11(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.11(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
