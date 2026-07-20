// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of match_switch_diff.carbon: the honest
// literal `switch` counterpart of the Carbon `match` — same cases, same
// default, same probe values. printf("%d\n", ...) mirrors Core.Print's
// lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdio>

static auto Grade(int score) -> int {
  switch (score) {
    case 90:
      return 4;
    case 80:
      return 3;
    case 70:
      return 2;
    case 60:
      return 1;
    default:
      return 0;
  }
}

auto main() -> int {
  std::printf("%d\n", Grade(90));
  std::printf("%d\n", Grade(80));
  std::printf("%d\n", Grade(70));
  std::printf("%d\n", Grade(60));
  std::printf("%d\n", Grade(100));
  std::printf("%d\n", Grade(61));
  std::printf("%d\n", Grade(-90));
  return 0;
}
