// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_exceptions_fence_value_diff.carbon:
// the SAME helper functions (byte-identical to the Carbon program's inline
// block), called natively — plain C++ calls with no B0 fence thunks
// anywhere, exceptions on (the runner compiles this with bare
// `clang++ -std=c++17`, matching the Carbon side's default
// `--cpp-exceptions=auto` -> `catch` resolution). Same probe values in the
// same order, so byte-identical output pins that Carbon's fenced (for the
// potentially-throwing `CheckedScale`) and unfenced (for the `noexcept`
// `SaturatingAdd`) boundary call paths are value-transparent when nothing
// throws. printf("%d\n", ...) mirrors Core.Print's lowering exactly
// (toolchain/lower/handle_call.cpp).

#include <cstdio>
#include <stdexcept>

// Potentially throwing: `throw` on a guarded path the probe values never
// take. Calls from Carbon cross the fenced (noexcept) thunk.
inline auto CheckedScale(int value, int factor) -> int {
  if (factor == 0) {
    throw std::invalid_argument("zero factor");
  }
  return value * factor;
}

// noexcept: exempt from the fence (IsCppThunkFenceRequired); plain call.
inline auto SaturatingAdd(int a, int b) noexcept -> int {
  long long sum = static_cast<long long>(a) + b;
  if (sum > 2147483647LL) {
    return 2147483647;
  }
  if (sum < -2147483648LL) {
    return -2147483647 - 1;
  }
  return static_cast<int>(sum);
}

auto main() -> int {
  int acc = CheckedScale(21, 2);
  std::printf("%d\n", acc);
  std::printf("%d\n", CheckedScale(0 - acc, 5));
  std::printf("%d\n", SaturatingAdd(2147483647, acc));
  std::printf("%d\n", SaturatingAdd(0 - 2147483647 - 1, 0 - 1));
  std::printf("%d\n", CheckedScale(SaturatingAdd(acc, 8), 2));
  return 0;
}
