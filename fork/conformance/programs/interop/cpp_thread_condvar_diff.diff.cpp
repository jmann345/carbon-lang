// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_thread_condvar_diff.carbon: a plain
// C++ worker thread runs the same protocol — release-order store of the
// runtime-seeded handoff value into a `std::atomic<int>`, then `ready` set
// under the mutex (guard held through the notify) and `notify_one`; main
// loops on `cv.wait`, unlocks, joins, and prints with an acquire-order
// load. Join-before-print, same print order, same seeds — byte-identical
// output pins the cross-thread handoff behavior. printf("%d\n", ...)
// mirrors Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <atomic>
#include <condition_variable>
#include <cstdio>
#include <mutex>
#include <thread>

std::mutex m;
std::condition_variable cv;
int ready = 0;
std::atomic<int> handoff{0};

auto RuntimeSeed(int x) -> int { return x + 20; }

auto Worker() -> void {
  handoff.store(RuntimeSeed(22), std::memory_order_release);
  std::lock_guard<std::mutex> g(m);
  ready = 1;
  cv.notify_one();
}

auto main() -> int {
  std::thread worker(Worker);
  std::unique_lock<std::mutex> ul(m);
  while (ready == 0) {
    cv.wait(ul);
  }
  ul.unlock();
  worker.join();
  std::printf("%d\n", handoff.load(std::memory_order_acquire));
  std::printf("%d\n", ready);
  return 0;
}
