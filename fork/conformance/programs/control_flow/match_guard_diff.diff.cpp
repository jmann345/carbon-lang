// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of match_guard_diff.carbon: the honest
// `if`/`else if` chain counterpart of the guarded Carbon `match` — same
// conditions in the same order (first match wins, a failed guard falls
// through), same probe values. `&&` mirrors the Carbon guard's
// short-circuiting `and`. printf("%d\n", ...) mirrors Core.Print's
// lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdio>

static auto Bucket(int n) -> int {
  if (n == 0) {
    return 100;
  } else if (n < 0) {
    return 0 - n;
  } else if (n > 99 && n < 1000) {
    return n - 100;
  } else {
    return 7;
  }
}

auto main() -> int {
  std::printf("%d\n", Bucket(0));
  std::printf("%d\n", Bucket(-5));
  std::printf("%d\n", Bucket(500));
  std::printf("%d\n", Bucket(50));
  std::printf("%d\n", Bucket(1000));
  return 0;
}
