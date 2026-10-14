// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of variadics_sum_diff.carbon: each Carbon
// variadic function is a function template over a parameter pack, and each
// statement expansion `... body;` is a comma fold `((body), ...)`, whose
// operands are evaluated left to right. printf("%d\n", ...) mirrors
// Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdint>
#include <cstdio>

template <typename... C>
static auto Horner(int64_t x, C... c) -> int64_t {
  int64_t total = 0;
  ((total = total * x + static_cast<int64_t>(c)), ...);
  return total;
}

template <typename... N>
static auto Sum(N... n) -> int64_t {
  int64_t total = 0;
  ((total += static_cast<int64_t>(n)), ...);
  return total;
}

template <typename... N>
static auto SumOfSquares(N... n) -> int64_t {
  return Sum(static_cast<int64_t>(n) * static_cast<int64_t>(n)...);
}

auto main() -> int {
  std::printf("%d\n", static_cast<int>(Horner(10, 1, 2, 3)));
  std::printf("%d\n", static_cast<int>(Horner(2, 1, 0, 1, 1)));
  std::printf("%d\n", static_cast<int>(Horner(7)));
  std::printf("%d\n", static_cast<int>(SumOfSquares(1, 2, 3, 4)));
  std::printf("%d\n", static_cast<int>(SumOfSquares()));
  return 0;
}
