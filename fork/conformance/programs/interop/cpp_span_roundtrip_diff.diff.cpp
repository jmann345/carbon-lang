// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_span_roundtrip_diff.carbon: the
// Carbon side's `Core.Slice(const i32)` / `std::span<const int>` values are
// a pointer and a size, so this oracle spells them as exactly that (the
// runner compiles it with `-std=c++17`, where `<span>` does not exist) and
// mirrors each step -- `Tail` as `subspan(1)` by pointer+size arithmetic, the
// bounds-checked `Sum` loop, the runtime-seeded array. printf("%d\n", ...)
// with the value as `int` mirrors `Core.Print` exactly
// (toolchain/lower/handle_call.cpp).

#include <cstdio>

struct View {
  const int* data;
  long long size;
};

auto Tail(View s) -> View { return {s.data + 1, s.size - 1}; }

auto Sum(View s) -> int {
  int total = 0;
  for (long long i = 0; i < s.size; ++i) {
    total += s.data[i];
  }
  return total;
}

auto CallSum() -> int {
  int arr[3] = {5, 6, 7};
  return Sum({arr, 3});
}

auto RuntimeSeed(int x) -> int { return x + 20; }

auto main() -> int {
  int a[3] = {RuntimeSeed(-19), 2, 3};
  View t = Tail({a, 3});
  std::printf("%d\n", static_cast<int>(t.size));
  std::printf("%d\n", t.data[0]);
  std::printf("%d\n", CallSum());
  return 0;
}
