// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/span.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/span.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-8, R-6): the IR-level twin of
// check stdlib/span.carbon's `pass_and_return`. Predicted: an import-side
// thunk definition named after the callee's Itanium mangling plus
// `.carbon_thunk._` (thunks.carbon:117 `@_ZN9NeedThunkC1ERKS_.carbon_thunk._`),
// so the name carries `4span` and the all-ones extent 18446744073709551615 of
// the mangled `std::span<const int, dynamic_extent>` parameter; the thunk
// takes `ptr` (the `Slice` storage's address) and calls the real `Consume`
// with a by-value `span` load; `Produce`'s out-pointer thunk writes 16 bytes
// into the Carbon return slot. No `memcpy` between differently sized types
// (the layout premise's IR-level check).

// --- span.h

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

// --- span.carbon

library "[[@TEST_NAME]]";

import Cpp library "span.h";

fn F(s: Core.Slice(i32)) {
  Cpp.Consume(s);
}

fn G() -> Core.Slice(i32) {
  return Cpp.Produce();
}
