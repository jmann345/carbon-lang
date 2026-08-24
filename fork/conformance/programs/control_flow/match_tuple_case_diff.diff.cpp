// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of match_tuple_case_diff.carbon: the honest
// nested-`if` counterpart of the Carbon tuple `match` — same shapes, same
// first-match-wins order, same probe values. printf("%d\n", ...) mirrors
// Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdio>

struct Pair {
  int b;
  int c;
};

struct Triple {
  int a;
  Pair inner;
};

static auto RuntimeSeed(int x) -> int { return x + 20; }

static auto Classify(Triple p) -> int {
  if (p.a == 42) {
    return p.inner.b + p.inner.c;
  }
  if (p.inner.b == 1 && p.inner.c == 2) {
    return p.a;
  }
  return 0;
}

auto main() -> int {
  std::printf("%d\n", Classify({RuntimeSeed(22), {3, 4}}));
  std::printf("%d\n", Classify({RuntimeSeed(-15), {1, 2}}));
  std::printf("%d\n", Classify({RuntimeSeed(22), {1, 2}}));
  std::printf("%d\n", Classify({RuntimeSeed(-11), {3, 4}}));
  return 0;
}
