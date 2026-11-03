// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_sum_type_roundtrip_diff.carbon: the
// Carbon sum type values are the `std::optional` and `std::variant` values
// they convert to, built with the same runtime seeds, and the two Carbon
// functions the C++ side calls are written here in C++, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdio>
#include <optional>
#include <variant>

static auto TakeOptional(std::optional<int> o) -> int {
  return o.has_value() ? *o + 1 : -1;
}

static auto TakeOptionalRef(const std::optional<int>& o) -> int {
  return o.has_value() ? *o + 2 : -2;
}

static auto TakeVariant(std::variant<int, double> v) -> int {
  return v.index() == 0 ? std::get<0>(v)
                        : static_cast<int>(std::get<1>(v) * 10);
}

static auto TakePair(const std::variant<int, int>& v) -> int {
  return static_cast<int>(v.index()) * 100 +
         (v.index() == 0 ? std::get<0>(v) : std::get<1>(v));
}

static auto TakeEmpty(std::variant<std::monostate, int> v) -> int {
  return v.index() == 0 ? -7 : std::get<1>(v);
}

static auto TakePointer(std::optional<int*> o) -> int {
  return o.has_value() ? (*o != nullptr ? **o : 0) : -1;
}

static auto TakeIntOrPointer(std::variant<int, int*> v) -> int {
  if (v.index() == 0) {
    return std::get<0>(v);
  }
  return std::get<1>(v) != nullptr ? *std::get<1>(v) * 2 : -9;
}

static auto Seed(int x) -> int { return x + 5; }

static auto SeedF(double x) -> double { return x + x; }

static auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) {
    return n * 4;
  }
  return std::nullopt;
}

static auto InspectVariant(std::variant<int, double> v) -> int {
  if (v.index() == 0) {
    return std::get<0>(v) + 1;
  }
  return TakeVariant(std::variant<int, double>(std::get<1>(v))) + 2;
}

static auto UseMakeOptional(int n) -> int {
  std::optional<int> o = MakeOptional(n);
  return o.has_value() ? *o : -3;
}

static auto UseInspectVariant(int n) -> int {
  if (n > 0) {
    return InspectVariant(std::variant<int, double>(n));
  }
  return InspectVariant(std::variant<int, double>(n * 1.5));
}

static auto Print(int n) -> void { std::printf("%d\n", n); }

auto main() -> int {
  std::optional<int> some = Seed(30);
  std::optional<int> none = std::nullopt;
  Print(TakeOptional(some));
  Print(TakeOptionalRef(some));
  Print(TakeOptional(none));
  Print(TakeOptional(std::nullopt));
  Print(TakeOptional(std::optional<int>(Seed(40))));
  Print(TakeOptionalRef(std::nullopt));
  double half = SeedF(1.25);
  Print(TakeVariant(std::variant<int, double>(std::in_place_index<1>, half)));
  Print(
      TakeVariant(std::variant<int, double>(std::in_place_index<0>, Seed(4))));
  Print(TakePair(std::variant<int, int>(std::in_place_index<1>, Seed(2))));
  Print(TakePair(std::variant<int, int>(std::in_place_index<0>, Seed(3))));
  Print(TakeEmpty(std::variant<std::monostate, int>(std::monostate())));
  Print(TakeEmpty(std::variant<std::monostate, int>(Seed(6))));
  Print(UseMakeOptional(Seed(1)));
  Print(UseMakeOptional(Seed(-8)));
  Print(UseInspectVariant(Seed(2)));
  Print(UseInspectVariant(Seed(-7)));
  int cell = Seed(10);
  Print(TakePointer(std::optional<int*>(&cell)));
  Print(TakePointer(std::optional<int*>(static_cast<int*>(nullptr))));
  Print(TakePointer(std::nullopt));
  Print(TakeIntOrPointer(
      std::variant<int, int*>(std::in_place_index<0>, Seed(7))));
  Print(
      TakeIntOrPointer(std::variant<int, int*>(std::in_place_index<1>, &cell)));
  Print(TakeIntOrPointer(std::variant<int, int*>(std::in_place_index<1>,
                                                 static_cast<int*>(nullptr))));
  return 0;
}
