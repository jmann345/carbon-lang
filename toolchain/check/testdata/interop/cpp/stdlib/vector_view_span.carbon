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
