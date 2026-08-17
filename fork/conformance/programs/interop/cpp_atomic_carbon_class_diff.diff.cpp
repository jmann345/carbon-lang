// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_atomic_carbon_class_diff.carbon: the
// identical all-scalar struct through the same std::atomic<Vec2>
// store/exchange/load sequence with the same runtime-seeded values, so
// byte-identical output pins the whole-object atomic round trips the Carbon
// side performs on its exported class once F8b lands.
// printf("%d\n", ...) mirrors Core.Print's lowering exactly
// (toolchain/lower/handle_call.cpp).

#include <atomic>
#include <cstdio>

struct Vec2 {
  int x;
  int y;
};

auto RuntimeSeed(int x) -> int { return x + 20; }

auto main() -> int {
  std::atomic<Vec2> a;
  Vec2 first{RuntimeSeed(1), RuntimeSeed(2)};
  a.store(first);
  Vec2 second{RuntimeSeed(3), RuntimeSeed(4)};
  Vec2 old = a.exchange(second);
  std::printf("%d\n", old.x);
  std::printf("%d\n", old.y);
  Vec2 cur = a.load();
  std::printf("%d\n", cur.x);
  std::printf("%d\n", cur.y);
  return 0;
}
