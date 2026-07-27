// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of choice_payload_roundtrip_diff.carbon
// (compiled only once the Carbon side un-SKIPs at W5 slice 2): the same sum
// in a std::variant, payload extracted via std::get_if — the C++ oracle for
// the round-tripped payload value per DIFF-1. printf("%d\n", ...) mirrors
// Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdio>
#include <variant>

namespace {

struct ErrT {};
using IntResult = std::variant<int, ErrT>;

auto Consume(const IntResult& r) -> int {
  if (const int* value = std::get_if<int>(&r)) {
    return *value;
  }
  return -1;
}

}  // namespace

auto main() -> int {
  int base = 40;
  std::printf("%d\n", Consume(IntResult(base + 2)));
  std::printf("%d\n", Consume(IntResult(ErrT{})));
  return 0;
}
