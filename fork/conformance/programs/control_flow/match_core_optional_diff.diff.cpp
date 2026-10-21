// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of match_core_optional_diff.carbon: the same
// values held in `std::optional<int>` and a nullable `int*`, inspected with
// `has_value()` and `*` (null for the pointer's `None`) where the Carbon side
// matches `.Some` and `.None`, in the same order, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdio>
#include <optional>

static auto Seed(int x) -> int { return x * 3 - 4; }

static auto MaybePositive(int n) -> std::optional<int> {
  if (n > 0) {
    return n;
  }
  return std::nullopt;
}

static auto Show(std::optional<int> o) -> void {
  std::printf("%d\n", o.has_value() ? *o : -1);
}

static auto ShowPointer(int* p) -> void {
  std::printf("%d\n", p != nullptr ? *p : 0);
}

static auto MaybeWide(int n) -> std::optional<long long> {
  if (n > 0) {
    return n;
  }
  return std::nullopt;
}

static auto CountSome(std::optional<long long> o) -> int {
  return o.has_value() ? 1 : 0;
}

auto main() -> int {
  Show(MaybePositive(Seed(5)));
  Show(MaybePositive(Seed(1)));
  int cell = Seed(7);
  ShowPointer(&cell);
  ShowPointer(nullptr);
  if (auto o = MaybePositive(Seed(4)); o.has_value()) {
    std::printf("%d\n", *o + 100);
  }
  std::printf("%d\n", CountSome(MaybeWide(Seed(2))));
  std::printf("%d\n", CountSome(MaybeWide(Seed(-2))));
  return 0;
}
