// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_span.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_span.carbon

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-8): static extents are honestly
// unmapped. The mock header is span.carbon's, reduced to what this split
// names (the Clang-echoed candidate note cites the smallest header; plan §4).

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
      T* data() const { return data_; }
      size_t size() const { return size_; }

     private:
      T* data_;
      size_t size_;
    };
  }
}

auto ConsumeStatic(std::span<int, 3> s) -> void;

// --- fail_static_extent_from_slice.carbon

library "[[@TEST_NAME]]";

import Cpp library "span.h";

// A `Core.Slice(i32)` argument maps to `std::span<int>` (the export arm) and
// does not convert to the static-extent parameter `std::span<int, 3>`: the
// mock has no converting constructor, as the real one's is implicit only for
// a matching extent. Predicted: Clang's forwarded "no matching function for
// call to 'ConsumeStatic'" with the candidate note naming `std::span<int, 3>`.
fn F(p: i32*) {
  Cpp.ConsumeStatic(Core.Slice(i32).UnsafeMake(p, 3));
}
