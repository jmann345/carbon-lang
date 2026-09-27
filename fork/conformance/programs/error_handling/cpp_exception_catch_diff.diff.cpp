// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_exception_catch_diff.carbon: the SAME
// `CheckedScale` (byte-identical to the Carbon program's inline block), called
// natively inside `try`/`catch` where the Carbon side uses `?` through the
// catching thunk. Same probe values in the same order, so byte-identical
// output pins that a thrown C++ exception becomes the `.Err` alternative
// exactly when the native call throws, and that the success value crosses the
// catching thunk's return out-pointer unchanged. printf("%d\n", ...) mirrors
// Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdio>
#include <stdexcept>

// Throws on a zero factor; the runtime-selected probe below takes that path.
inline auto CheckedScale(int value, int factor) -> int {
  if (factor == 0) {
    throw std::invalid_argument("zero factor");
  }
  return value * factor;
}

auto Probe(int value, int factor) -> void {
  try {
    int v = CheckedScale(value, factor);
    std::printf("%d\n", 1);
    std::printf("%d\n", v);
  } catch (const std::invalid_argument&) {
    std::printf("%d\n", 0);
    std::printf("%d\n", 0 - 1);
  }
}

auto RuntimeSeed(int x) -> int { return x + 20; }

auto main() -> int {
  Probe(21, RuntimeSeed(-17));
  Probe(21, RuntimeSeed(-20));
  Probe(RuntimeSeed(-27), 5);
  return 0;
}
