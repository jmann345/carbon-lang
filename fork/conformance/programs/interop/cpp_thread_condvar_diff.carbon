// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: C++ interop — exporting Carbon functions/methods to C++
// EXPECT-EXIT: 0
//
// Differential pair — the F-008 concurrency arbiter (fork/f008/plan.md §2.5,
// R-1): a bridge-spawned worker thread runs the EXPORTED Carbon function
// `Worker` (`std::thread(Carbon::Worker)` in the inline C++ bridge — the
// `.join()` determinism variant of the measured matrix row 9,
// fork/design-sprint/threading-atomics.md:90), publishes a runtime-seeded
// handoff value through a release-order `std::atomic<int>` store, then sets
// `ready` under the mutex and notifies; the Carbon main thread loops on
// `Cpp.cv.wait(ref ul)`, joins, and prints with an acquire-order load.
// A single-threaded execution of this wait/notify protocol deadlock-timeouts
// (the waiter blocks with no second thread to notify), so passing REQUIRES
// the second thread — the printed value crossing threads is the R-1
// concurrency arbiter. Oracle: a plain C++ thread doing the same
// (cpp_thread_condvar_diff.diff.cpp); byte-identical exit code and stdout
// per DIFF-1, no EXPECT-STDOUT. Join-before-print: all prints happen on the
// main thread after `.join()` returns.
//
// Bullet attachment (disclosed in fork/f008/plan.md §2.5): at F8a this
// program attaches to the exporting bullet it genuinely arbitrates at
// execution level — its worker IS an exported Carbon function run from C++,
// on a foreign thread. It re-homes to the threading bullet at F8b together
// with that bullet's SKIP→PASS flip (adjudication A: no bullet flips on the
// harness slice).

import Core library "io";
import Cpp library "<atomic>";
import Cpp library "<condition_variable>";
import Cpp library "<mutex>";
import Cpp library "<thread>";

fn Worker();

inline Cpp '''
inline std::mutex m;
inline std::condition_variable cv;
inline int ready = 0;
inline std::atomic<int> handoff{0};
inline std::thread worker;

inline void StartWorker() { worker = std::thread(Carbon::Worker); }
inline void JoinWorker() { worker.join(); }
''';

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// Runs on the bridge-spawned foreign thread: publish the handoff value with
// release ordering, then set `ready` under the mutex and notify (the guard
// is held through the notify; it releases at function-scope exit).
fn Worker() {
  Cpp.handoff.store(RuntimeSeed(22), Cpp.std.memory_order_release);
  var unused g: Cpp.std.lock_guard(Cpp.std.mutex)
      = Cpp.std.lock_guard(Cpp.std.mutex).lock_guard(ref Cpp.m);
  Cpp.ready = 1;
  Cpp.cv.notify_one();
}

fn Run() -> i32 {
  Cpp.StartWorker();
  var ul: Cpp.std.unique_lock(Cpp.std.mutex)
      = Cpp.std.unique_lock(Cpp.std.mutex).unique_lock(ref Cpp.m);
  while (Cpp.ready == 0) {
    Cpp.cv.wait(ref ul);
  }
  ul.unlock();
  Cpp.JoinWorker();
  // Join-before-print: the worker has fully finished; the acquire load pairs
  // with the worker's release store.
  Core.Print(Cpp.handoff.load(Cpp.std.memory_order_acquire));
  Core.Print(Cpp.ready);
  return 0;
}
