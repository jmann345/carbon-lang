// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: C++ interop: threading, atomics, memory model, synchronization
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   8
//
// Un-SKIPped at F8b per adjudication A (fork/f008/plan.md §3 F8b, §11 item
// 1): the threading bullet's flip rides the FIRST defect-fix slice, not the
// F8a harness slice. The prior SKIP's "design lands" clause is superseded by
// the F-008 decision itself (fork/decision-log.md:637-644 sanctions the
// fixes without the doc); the threads_and_atomics.md design doc rides the
// gated design-docs digest separately (fork/ORCHESTRATION.md next-action 1).
//
// The flagship threading program: import <thread>/<atomic>, spawn two C++
// threads from an inline-C++ bridge that each fetch_add a shared
// std::atomic<int> 4x, join both, and print the joined total — proving
// cross-language data-race-free synchronization under the shared C++ memory
// model, not just API import. Join-before-print keeps the output
// deterministic (the runner's exact-stdout rule). The printed `8` alone
// cannot distinguish two threads from one (plan §5 R-1's disclosed weak
// spot); cpp_thread_condvar_diff is the concurrency arbiter.

import Core library "io";
import Cpp library "<atomic>";
import Cpp library "<thread>";

inline Cpp '''
inline std::atomic<int> counter{0};

inline void BumpFromTwoThreads(int times) {
  std::thread a([times] { for (int i = 0; i < times; ++i) counter.fetch_add(1); });
  std::thread b([times] { for (int i = 0; i < times; ++i) counter.fetch_add(1); });
  a.join();
  b.join();
}
''';

fn Run() -> i32 {
  Cpp.BumpFromTwoThreads(4);
  Core.Print(Cpp.counter.load());
  return 0;
}
