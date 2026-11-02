// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of match_std_variant_diff.carbon: the same
// C++ functions, inspected by `index()` and `std::get<I>` where the Carbon
// side matches `.Alt<I>`, in the same order, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdio>
#include <optional>
#include <variant>

static auto IntOrHalf(int n) -> std::variant<int, double> {
  if (n > 0) {
    return n * 3;
  }
  return n * 0.5;
}

static auto Tenths(double d) -> int { return static_cast<int>(d * 10); }

static auto MaybeEmpty(int n) -> std::variant<std::monostate, int> {
  if (n > 0) {
    return n + 100;
  }
  return std::monostate();
}

static auto LeftOrRight(int n) -> std::variant<int, int> {
  if (n > 0) {
    return std::variant<int, int>(std::in_place_index<1>, n);
  }
  return std::variant<int, int>(std::in_place_index<0>, -n);
}

static int cell = 0;

static auto Mixed(int n) -> std::variant<bool, long, double, int*> {
  switch (n % 4) {
    case 0:
      return n > 4;
    case 1:
      return static_cast<long>(n) * 7;
    case 2:
      return n * 0.25;
    default:
      cell = n;
      return &cell;
  }
}

static std::optional<int> inner;

static auto Nested(int n) -> std::variant<std::optional<int>*, int> {
  if (n > 0) {
    inner = n * 11;
    return &inner;
  }
  if (n == 0) {
    inner = std::nullopt;
    return &inner;
  }
  return n;
}

static auto Seed(int x) -> int { return x + 2; }

static auto Print(int n) -> void { std::printf("%d\n", n); }

auto main() -> int {
  for (int n : {Seed(2), Seed(-5)}) {
    auto v = IntOrHalf(n);
    Print(v.index() == 0 ? std::get<0>(v) : Tenths(std::get<1>(v)));
  }
  for (int n : {Seed(1), Seed(-3)}) {
    auto v = MaybeEmpty(n);
    Print(v.index() == 0 ? 0 : std::get<1>(v));
  }
  for (int n : {Seed(5), Seed(-9)}) {
    auto v = LeftOrRight(n);
    Print(v.index() == 0 ? 1000 + std::get<0>(v) : 2000 + std::get<1>(v));
  }
  for (int n : {Seed(6), Seed(7), Seed(8), Seed(9), Seed(10)}) {
    auto v = Mixed(n);
    switch (v.index()) {
      case 0:
        Print(std::get<0>(v) ? 1 : 0);
        break;
      case 1:
        Print(static_cast<int>(std::get<1>(v)));
        break;
      case 2:
        Print(Tenths(std::get<2>(v)));
        break;
      default:
        Print(*std::get<3>(v));
        break;
    }
  }
  for (int n : {Seed(1), Seed(-2), Seed(-6)}) {
    auto v = Nested(n);
    if (v.index() == 0) {
      const std::optional<int>& o = *std::get<0>(v);
      Print(o.has_value() ? *o : -1);
    } else {
      Print(std::get<1>(v));
    }
  }
  return 0;
}
