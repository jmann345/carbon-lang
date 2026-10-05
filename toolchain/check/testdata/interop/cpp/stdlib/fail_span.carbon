// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_span.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_span.carbon
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

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-8): static extents are honestly
// unmapped. The mock header is span.carbon's.

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

// --- fail_static_extent_from_slice.carbon

library "[[@TEST_NAME]]";

import Cpp library "span.h";

// A `Core.Slice(i32)` argument maps to `std::span<int>` (the export arm) and
// does not convert to the static-extent parameter `std::span<int, 3>`: the
// mock's converting constructor is same-extent only, as the real one's is
// implicit only for a matching extent. Predicted: Clang's forwarded "no
// matching function for call to 'ConsumeStatic'" with the candidate note
// naming `std::span<int, 3>`.
fn F(p: i32*) {
  // CHECK:STDERR: fail_static_extent_from_slice.carbon:[[@LINE+8]]:53: error: no matching function for call to 'ConsumeStatic' [CppInteropParseError]
  // CHECK:STDERR:    13 |   Cpp.ConsumeStatic(Core.Slice(i32).UnsafeMake(p, 3));
  // CHECK:STDERR:       |                                                     ^
  // CHECK:STDERR: fail_static_extent_from_slice.carbon:[[@LINE-12]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./span.h:29:6: note: candidate function not viable: no known conversion from 'span<[...], (default) dynamic_extent aka 18446744073709551615>' to 'span<[...], 3>' for 1st argument [CppInteropParseNote]
  // CHECK:STDERR:    29 | auto ConsumeStatic(std::span<int, 3> s) -> void;
  // CHECK:STDERR:       |      ^             ~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  Cpp.ConsumeStatic(Core.Slice(i32).UnsafeMake(p, 3));
}
