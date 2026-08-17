// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_atomic_global_counter_diff.carbon:
// the shared counter is a C++ GLOBAL std::atomic<int64_t> (the shape the
// Carbon side defines as a file-scope `var total: Cpp.std.atomic(i64);`),
// runtime-seeded, bumped by two threads 4x each, joined, then printed.
// printf("%d\n", ...) with the value narrowed to int mirrors the Carbon
// side's `Core.Print(total.load() as i32)` exactly
// (toolchain/lower/handle_call.cpp).

#include <atomic>
#include <cstdint>
#include <cstdio>
#include <thread>

std::atomic<int64_t> total;

auto RuntimeSeedL(int64_t x) -> int64_t { return x + 20; }

auto Bump() -> void { total.fetch_add(1); }

auto main() -> int {
  total.store(RuntimeSeedL(14));
  std::thread w1([] {
    for (int i = 0; i < 4; ++i) {
      Bump();
    }
  });
  std::thread w2([] {
    for (int i = 0; i < 4; ++i) {
      Bump();
    }
  });
  w1.join();
  w2.join();
  std::printf("%d\n", static_cast<int>(total.load()));
  return 0;
}
