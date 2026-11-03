// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_span_write_through_diff.carbon: the
// span is a pointer and a size (no <span> under -std=c++17).

#include <cstdio>

auto Sum(int* p, long long n) -> int {
  int t = 0;
  for (long long i = 0; i < n; ++i) {
    t += p[i];
  }
  return t;
}

auto Bump(int* p, long long n) -> void {
  for (long long i = 0; i < n; ++i) {
    p[i] += 1;
  }
}

auto main() -> int {
  int a[3] = {1, 2, 3};
  a[0] = 10;
  Bump(a, 3);
  std::printf("%d\n", Sum(a, 3));
  return 0;
}
