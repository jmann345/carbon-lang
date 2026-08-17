// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_thread_carbon_fn_diff.carbon: a
// std::thread constructed directly on a named function (the exact shape the
// Carbon side spells `Cpp.std.thread.thread(Work)` once F8d lands), whose
// body performs the same runtime-seeded fetch_add on the shared atomic;
// joined, then the atomic is printed. printf("%d\n", ...) mirrors
// Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <atomic>
#include <cstdio>
#include <thread>

std::atomic<int> hits{0};

auto RuntimeSeed(int x) -> int { return x + 20; }

auto Work() -> void { hits.fetch_add(RuntimeSeed(22)); }

auto main() -> int {
  std::thread t(Work);
  t.join();
  std::printf("%d\n", hits.load());
  return 0;
}
