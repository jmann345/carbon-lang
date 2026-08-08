// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of choice_generic_diff.carbon: a class
// template over `std::variant<T, std::monostate>` probed via `index()` —
// alternative 0 is the payload (`Some`), alternative 1 is `std::monostate`
// (`None`), the same numbering the Carbon side's discriminant-dispatch
// classification returns. Same construction sequence, same runtime-computed
// payload seeds — including the collision probe `c64`, whose payload's low
// byte is 1 (`None`'s discriminant on the Carbon side) — and same probe
// order over the two instantiations (`int` / `int64_t`, mirroring
// `Opt(i32)` / `Opt(i64)`), so byte-identical output pins the per-specific
// construction, dispatch, and collision-probe behavior.
// printf("%d\n", ...) mirrors Core.Print's lowering exactly
// (toolchain/lower/handle_call.cpp).

#include <cstdint>
#include <cstdio>
#include <variant>

template <typename T>
class Opt {
 public:
  static auto Some(T value) -> Opt {
    return Opt(VariantT(std::in_place_index<0>, value));
  }
  static auto None() -> Opt { return Opt(VariantT(std::in_place_index<1>)); }

  auto index() const -> int { return static_cast<int>(v_.index()); }

 private:
  using VariantT = std::variant<T, std::monostate>;

  explicit Opt(VariantT v) : v_(v) {}

  VariantT v_;
};

auto RuntimeSeed(int x) -> int { return x + 20; }

auto RuntimeSeedL(int64_t x) -> int64_t { return x + 20; }

auto main() -> int {
  Opt<int> s32 = Opt<int>::Some(RuntimeSeed(22));
  Opt<int> n32 = Opt<int>::None();
  std::printf("%d\n", s32.index());
  std::printf("%d\n", n32.index());
  Opt<int64_t> s64 = Opt<int64_t>::Some(RuntimeSeedL(44));
  // The collision probe: 237 + 20 = 257, low byte 1.
  Opt<int64_t> c64 = Opt<int64_t>::Some(RuntimeSeedL(237));
  Opt<int64_t> n64 = Opt<int64_t>::None();
  std::printf("%d\n", s64.index());
  std::printf("%d\n", c64.index());
  std::printf("%d\n", n64.index());
  return 0;
}
