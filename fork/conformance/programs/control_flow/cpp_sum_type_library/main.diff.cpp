// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_sum_type_library: the library's C++
// functions, inspected where the Carbon units match, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdio>
#include <optional>
#include <variant>

static auto MaybeSquare(int n) -> std::optional<int> {
  if (n > 0) {
    return n * n;
  }
  return std::nullopt;
}

static auto CountOrFlag(int n) -> std::variant<int, bool> {
  if (n > 0) {
    return n + 1;
  }
  return n == 0;
}

static auto Seed(int x) -> int { return x - 3; }

static auto Print(int n) -> void { std::printf("%d\n", n); }

auto main() -> int {
  for (int n : {Seed(9), Seed(1)}) {
    auto o = MaybeSquare(n);
    Print(o.has_value() ? *o : -1);
  }
  auto first = CountOrFlag(Seed(10));
  Print(first.index() == 0 ? std::get<0>(first) : (std::get<1>(first) ? 1 : 0));
  auto second = CountOrFlag(Seed(3));
  Print(second.index() == 0 ? std::get<0>(second)
                            : (std::get<1>(second) ? -2 : -3));
  return 0;
}
