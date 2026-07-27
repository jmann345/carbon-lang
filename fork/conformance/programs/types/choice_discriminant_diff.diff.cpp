// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of choice_discriminant_diff.carbon: the same
// three-state sum held in a std::variant, classified through index() — the
// language-provided discriminant — with the payload never read (slice 2
// territory on the Carbon side, so the C++ side must not observe it either).
// Alternative order matches the Carbon choice declaration order:
// Go(int) = 0, Stop = 1, Wait = 2. printf("%d\n", ...) mirrors Core.Print's
// lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdio>
#include <variant>

namespace {

struct StopT {};
struct WaitT {};
using Signal = std::variant<int, StopT, WaitT>;

auto Classify(const Signal& s) -> int {
  switch (s.index()) {
    case 1:  // StopT
      return 0;
    case 2:  // WaitT
      return 1;
    default:  // int payload (Go)
      return 2;
  }
}

}  // namespace

auto main() -> int {
  int base = 55;
  Signal go = base + 5;
  Signal stop = StopT{};
  Signal wait = WaitT{};
  std::printf("%d\n", Classify(go));
  std::printf("%d\n", Classify(stop));
  std::printf("%d\n", Classify(wait));
  return 0;
}
