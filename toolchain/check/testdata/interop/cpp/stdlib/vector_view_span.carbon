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
// constructor belongs to a class the importer maps to a Carbon type -- the
// specialization's `ClangDecl` inst is the `Core.Slice(const i32)`
// `ClassType`, not a `ClassDecl` -- and importing it was the round-4 ICE
// (`Casting inst {kind: ClassType ...} to wrong kind ClassDecl`, import.cpp
// `GetFunctionName`). `LookupCppConversion` now declines constructors of
// classes whose registered inst is not a `ClassDecl`, and the conversion
// falls through to the prelude's blanket impl over the synthesized
// `CppContiguousRange` witness, exactly as without `<span>`. The container is
// a class TEMPLATE specialization (the real `std::vector<int>` shape), named
// through a header alias (the class/import/template.carbon `using Ai32 =
// A<int>` spelling), so the witness is built over a specialization. The mock
// `span` is span.carbon's (D-SL-14) plus the range constructor, with the REAL
// header's parameter, a forwarding reference `R&&` (round 5): a parameter
// binding `v` is a Carbon value, invented as a C++ PRVALUE (type_mapping.cpp
// `InventPrimitiveClangArg`), which the round-4 mock's `R&` could not bind,
// so the lookup declined before the constructor was ever selected and the
// gate went unexercised. `--target` pins `unsigned long` to `u64`. The first
// three splits are positives; the fourth pins the constructor of a `span`
// that imports as an ordinary CLASS (round 5).

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
      // The real one's range constructor: a forwarding reference, so it binds
      // a prvalue (a Carbon value, the parameter splits) and an lvalue (a
      // Carbon `var`, the conformance program) alike; `explicit(Extent !=
      // dynamic_extent)` there, so implicit here. What Clang selects for a
      // container source.
      template <typename R>
      span(R&& r) : data_(r.data()), size_(r.size()) {}
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

auto MakeVecLike() -> VecLikeInt;
auto Consume(std::span<const int> s) -> void;

// --- view.carbon

library "[[@TEST_NAME]]";

import Cpp library "span_vec_like.h";

// The source is a parameter binding: a Carbon VALUE, a C++ prvalue, bound by
// `R&&` with `R = VecLike<int>`. Without the gate the range constructor
// imports and `GetFunctionName` ICEs on the `Core.Slice(const i32)`
// `ClassType`. Predicted: the range constructor IS selected and declined; no
// `span` constructor anywhere in the dump; the blanket `ImplicitAs` witness
// over a `custom_witness (%Optional..., %u64, %VecLike.Data, %VecLike.Size),
// @CppContiguousRange` for the `VecLike<int>` specialization
// (vector_view.carbon's `view` shape, over a template specialization); `view`
// is the `Core.Slice(const i32)` specific.
//@dump-sem-ir-begin
fn View(v: Cpp.VecLikeInt) -> Core.Slice(const i32) {
  let view: Core.Slice(const i32) = v;
  return view;
}
//@dump-sem-ir-end

// --- var_source.carbon

library "[[@TEST_NAME]]";

import Cpp library "span_vec_like.h";

// The conformance program's exact category: a `var` source is a durable
// reference, a C++ LVALUE, bound by `R&&` with `R = VecLike<int>&`. Predicted:
// the same decline and the same blanket-impl witness as `view`, over
// `%v.ref`; `Cpp.MakeVecLike()` is the ordinary by-value class return.
//@dump-sem-ir-begin
fn ViewVar() {
  var v: Cpp.VecLikeInt = Cpp.MakeVecLike();
  let unused view: Core.Slice(const i32) = v;
}
//@dump-sem-ir-end

// --- argument.carbon

library "[[@TEST_NAME]]";

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

// --- noncopyable_element_class_constructor.carbon

library "[[@TEST_NAME]]";

import Cpp;

// The gate keys on the IMPORTER's decision, not the `std::span` matcher's
// (round 5). A Carbon class with no `Copy` impl fails `Slice`'s `T: Copy &
// Destroy` bound, so `std::span<Carbon::NoCopy>` imports as an ordinary
// class (span.carbon's `noncopyable_element_is_a_class`, D-SL-24); its
// `ClangDecl` inst IS a `ClassDecl`, and its range constructor imports and
// is called as any converting constructor (impls/as.carbon's `s as Cpp.Dest2`
// shape). The round-4 gate, keyed on the matcher, declined it and turned this
// working conversion into `cannot implicitly convert`. Predicted: no
// diagnostic; `Cpp.NoCopySpan` is a `class_type @span`, its range constructor
// imports as a member named `span` with a `ref` parameter (`R = VecLike<
// Carbon::NoCopy>&`, passing mode by reference), and the `let` is a
// `__carbon_thunk` call with `%v.ref` and the span's address; no
// `CppContiguousRange` witness anywhere in the dump.
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
      template <typename R>
      span(R&& r) : data_(r.data()), size_(r.size()) {}
      T* _Nullable data() const { return data_; }
      size_t size() const { return size_; }
     private:
      T* _Nullable data_;
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

using NoCopySpan = std::span<Carbon::NoCopy>;
using NoCopyVec = VecLike<Carbon::NoCopy>;

auto MakeNoCopyVec() -> NoCopyVec;
''';

//@dump-sem-ir-begin
fn L() {
  var v: Cpp.NoCopyVec = Cpp.MakeNoCopyVec();
  let unused s: Cpp.NoCopySpan = v;
}
//@dump-sem-ir-end
