// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of match_std_optional_diff.carbon: the same
// C++ functions, inspected with `has_value()` and `*` where the Carbon side
// matches `.Some` and `.None`, in the same order, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdint>
#include <cstdio>
#include <optional>

static int target = 0;

static auto MaybeTwice(int n) -> std::optional<int> {
  if (n > 0) {
    return n * 2;
  }
  return std::nullopt;
}

static auto MaybeAddress(int n) -> std::optional<int*> {
  target = n * 3;
  if (n > 0) {
    return &target;
  }
  if (n == 0) {
    return nullptr;
  }
  return std::nullopt;
}

static auto MaybeWide(int n) -> std::optional<std::int64_t> {
  if (n > 0) {
    return static_cast<std::int64_t>(n) * 1000000000;
  }
  return std::nullopt;
}

static auto Seed(int x) -> int { return x + 4; }

template <typename T>
static auto Unwrap(std::optional<T> o, T fallback) -> T {
  return o.has_value() ? *o : fallback;
}

static auto Show(int n) -> void {
  auto o = MaybeTwice(n);
  std::printf("%d\n", o.has_value() ? *o : -1);
}

static auto ShowPointer(int n) -> void {
  auto o = MaybeAddress(n);
  if (!o.has_value()) {
    std::printf("%d\n", -1);
  } else if (*o == nullptr) {
    std::printf("%d\n", 0);
  } else {
    std::printf("%d\n", **o);
  }
}

static auto ShowWide(int n) -> void {
  auto o = MaybeWide(n);
  std::printf("%d\n", o.has_value() ? static_cast<int>(*o / 1000000000) : -1);
}

auto main() -> int {
  Show(Seed(3));
  Show(Seed(-7));
  if (auto o = MaybeTwice(Seed(1)); o.has_value()) {
    std::printf("%d\n", *o);
  }
  ShowPointer(Seed(1));
  ShowPointer(Seed(-4));
  ShowPointer(Seed(-9));
  ShowWide(Seed(5));
  ShowWide(Seed(-5));
  auto some = MaybeTwice(Seed(17));
  auto none = MaybeTwice(Seed(-17));
  int fallback = Seed(-11);
  std::printf("%d\n", Unwrap(some, fallback));
  std::printf("%d\n", Unwrap(none, fallback));
  if (some.has_value()) {
    std::printf("%d\n", *some);
  }
  return 0;
}
