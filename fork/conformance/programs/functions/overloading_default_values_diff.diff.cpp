// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of overloading_default_values_diff.carbon:
// overloads with a default argument, selected by C++'s best viable match.
// printf("%d\n", ...) mirrors Core.Print's lowering exactly
// (toolchain/lower/handle_call.cpp).

#include <cstdio>

auto F(int x, int y = 2) -> int { return x * 10 + y; }
auto F(bool b) -> int {
  if (b) {
    return -1;
  }
  return -2;
}

struct Counter {
  int start;
  auto Plus(int n = 1) const -> int { return start + n; }
  auto Plus(bool b) const -> int {
    if (b) {
      return start * 2;
    }
    return 0;
  }
};

auto Seed(int x) -> int { return x + 20; }

auto main() -> int {
  std::printf("%d\n", F(Seed(-19)));
  std::printf("%d\n", F(Seed(-19), Seed(-15)));
  std::printf("%d\n", F(true));
  std::printf("%d\n", F(false));
  const Counter c = {Seed(80)};
  std::printf("%d\n", c.Plus());
  std::printf("%d\n", c.Plus(Seed(-13)));
  std::printf("%d\n", c.Plus(true));
  return 0;
}
