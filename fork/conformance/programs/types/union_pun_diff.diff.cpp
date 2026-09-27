// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of union_pun_diff.carbon: the same seeded
// `int` and `long long` values, read back byte-wise and half-wise through
// `std::memcpy` (defined C++, no union-member reads), so the oracle states
// what a little-endian byte reinterpretation must print without itself
// relying on union punning. printf("%d\n", ...) mirrors Core.Print's lowering
// exactly (toolchain/lower/handle_call.cpp).

#include <cstdio>
#include <cstring>

namespace {

auto RuntimeSeed(int x) -> int { return x + 20; }

}  // namespace

auto main() -> int {
  // word = 0x01020304.
  int word = RuntimeSeed(16909040);
  signed char bytes[4];
  std::memcpy(bytes, &word, sizeof(bytes));
  for (signed char b : bytes) {
    std::printf("%d\n", static_cast<int>(b));
  }
  // both = 7 << 32 | 9.
  long long both = static_cast<long long>(RuntimeSeed(-13)) * 4294967296LL +
                   static_cast<long long>(RuntimeSeed(-11));
  int lo;
  std::memcpy(&lo, &both, sizeof(lo));
  int halves[2];
  std::memcpy(halves, &both, sizeof(halves));
  std::printf("%d\n", lo);
  std::printf("%d\n", halves[1]);
  return 0;
}
