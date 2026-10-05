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
// premise; `--target` pins the mock's `size_t` field to `unsigned long`
// (`Core.CppCompat.ULong64`) where the class import's layout reaches the dump.
// Positives only.

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
