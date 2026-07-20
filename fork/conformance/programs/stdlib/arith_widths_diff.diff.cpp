// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of arith_widths_diff.carbon. printf("%d\n",
// ...) mirrors Core.Print's exact lowering (toolchain/lower/handle_call.cpp:
// printf with the "%d\n" format string, argument sign-extended-or-truncated
// to i32).

#include <cstdint>
#include <cstdio>

auto main() -> int {
  int32_t a = -7;
  int32_t b = 2;
  std::printf("%d\n", a + b);
  std::printf("%d\n", a - b);
  std::printf("%d\n", a * b);
  std::printf("%d\n", a / b);
  std::printf("%d\n", a % b);

  int64_t big = 6000000000;
  int64_t off = 5999999879;
  std::printf("%d\n", static_cast<int32_t>(big - off));

  uint8_t byte = 200;
  std::printf("%d\n", static_cast<int32_t>(byte) * 3);

  int16_t narrow = 300;
  std::printf("%d\n", static_cast<int32_t>(narrow) - 45);
  return 0;
}
