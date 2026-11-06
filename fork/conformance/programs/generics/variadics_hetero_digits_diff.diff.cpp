// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of variadics_hetero_digits_diff.carbon: each
// Carbon function over a pack of different types is a function template over a
// parameter pack, each statement expansion `... body;` is a comma fold
// `((body), ...)`, whose operands are evaluated left to right, and each
// interface implementation is a member function of the struct.
// printf("%d\n", ...) mirrors Core.Print's lowering.

#include <cstdint>
#include <cstdio>

struct One {
  int64_t v;
  auto Width() const -> int64_t { return 1; }
  auto Value() const -> int64_t { return v; }
};

struct Two {
  int64_t v;
  auto Width() const -> int64_t { return 2; }
  auto Value() const -> int64_t { return v; }
};

static auto Pow10(int64_t n) -> int64_t {
  int64_t result = 1;
  for (int64_t i = 0; i < n; ++i) {
    result *= 10;
  }
  return result;
}

template <typename... T>
static auto Cat(T... d) -> int64_t {
  int64_t width = 0;
  ((width += d.Width()), ...);
  std::printf("%d\n", static_cast<int>(width));
  int64_t result = 0;
  ((result = result * Pow10(d.Width()) + d.Value()), ...);
  return result;
}

template <typename... T>
static auto Sum(T... x) -> int64_t {
  int64_t total = 0;
  ((total += static_cast<int64_t>(x)), ...);
  return total;
}

auto main() -> int {
  Two a{74};
  One b{2};
  Two c{7};
  One d{4};
  Two e{22};
  std::printf("%d\n", static_cast<int>(Cat(a, b, c, d)));
  std::printf("%d\n", static_cast<int>(Cat(d, e)));
  std::printf("%d\n", static_cast<int>(Cat()));
  std::printf("%d\n", static_cast<int>(Sum(static_cast<int8_t>(-7),
                                           static_cast<int16_t>(300),
                                           static_cast<int32_t>(40000))));
  std::printf("%d\n", static_cast<int>(Sum(static_cast<int32_t>(5))));
  return 0;
}
