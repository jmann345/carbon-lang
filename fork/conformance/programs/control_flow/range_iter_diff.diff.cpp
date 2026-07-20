// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of range_iter_diff.carbon: Core.Range /
// Core.InclusiveRange become the canonical C++ counting loops; the array
// iteration becomes a range-based for over a C array. printf("%d\n", ...)
// mirrors Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdio>

auto main() -> int {
  int sum = 0;
  for (int n = 0; n < 10; ++n) {
    sum += n;
  }
  std::printf("%d\n", sum);

  int isum = 0;
  for (int n = 3; n <= 7; ++n) {
    isum += n;
  }
  std::printf("%d\n", isum);

  int a[5] = {2, 4, 8, 16, 32};
  int arr_sum = 0;
  for (int n : a) {
    std::printf("%d\n", n);
    arr_sum += n;
  }
  std::printf("%d\n", arr_sum);
  return 0;
}
