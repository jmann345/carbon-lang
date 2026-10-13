// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// C++17 oracle for optional_compare_diff.carbon: the same comparisons over
// std::optional<int>, printed as printf("%d\n", x).

#include <cstdio>
#include <optional>

static auto B(bool b) -> int { return b ? 1 : 0; }

static auto Make(int n) -> std::optional<int> {
  if (n < 0) {
    return std::nullopt;
  }
  return n;
}

// The six comparisons of `a` with `b`, in the order ==, !=, <, <=, >, >=.
static auto Row(std::optional<int> a, std::optional<int> b) -> void {
  std::printf("%d\n", B(a == b));
  std::printf("%d\n", B(a != b));
  std::printf("%d\n", B(a < b));
  std::printf("%d\n", B(a <= b));
  std::printf("%d\n", B(a > b));
  std::printf("%d\n", B(a >= b));
}

auto main() -> int {
  Row(Make(-1), Make(-2));
  Row(Make(-1), Make(0));
  Row(Make(0), Make(-1));
  Row(Make(0), Make(1));
  Row(Make(1), Make(1));
  Row(Make(1), Make(0));
  return 0;
}
