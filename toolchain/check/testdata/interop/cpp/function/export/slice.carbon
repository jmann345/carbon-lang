// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/slice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/slice.carbon

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-8): exporting a Carbon function
// whose parameter is `Core.Slice(const i32)` to C++ maps the parameter to
// `std::span<const int>`, the class template found BY NAME in the TU and
// instantiated on the recursively mapped element type (the `Core.Result` ->
// `Carbon::expected` shape, result_expected.carbon). The inline C++ mocks
// `std::span` (D-SL-14) with the pointer-then-size layout and a `(T*, size_t)`
// constructor. Predicted: no diagnostics; the exported declaration's parameter
// type is `std::span<const int>`, and `Cpp.F` calls `Carbon::Sum` through the
// export-side thunk.

// --- slice.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn Sum(s: Core.Slice(const i32)) -> i32 {
  var total: i32 = 0;
  var i: i64 = 0;
  while (i < s.Size()) {
    total += s[i];
    ++i;
  }
  return total;
}

inline Cpp '''
namespace std {
  using size_t = __SIZE_TYPE__;
  inline namespace __1 {
    inline constexpr size_t dynamic_extent = static_cast<size_t>(-1);
    template <typename T, size_t Extent = dynamic_extent>
    class span {
     public:
      span(T* p, size_t n) : data_(p), size_(n) {}
      T* data() const { return data_; }
      size_t size() const { return size_; }
     private:
      T* data_;
      size_t size_;
    };
  }
}

inline int F() {
  int a[2] = {1, 2};
  return Carbon::Sum(std::span<const int>(a, 2));
}
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.F(); }
//@dump-sem-ir-end
