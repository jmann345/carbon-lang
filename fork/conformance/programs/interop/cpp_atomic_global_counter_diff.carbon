// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: C++ interop: threading, atomics, memory model, synchronization
// EXPECT-EXIT: 0

import Core library "io";
import Cpp library "<atomic>";
import Cpp library "<thread>";

var total: Cpp.std.atomic(i64);

fn Bump();

inline Cpp '''
inline std::thread w1;
inline std::thread w2;

inline void StartWorkers() {
w1 = std::thread([] { for (int i = 0; i < 4; ++i) Carbon::Bump(); });
w2 = std::thread([] { for (int i = 0; i < 4; ++i) Carbon::Bump(); });
}
inline void JoinWorkers() {
w1.join();
w2.join();
}
''';

// Runs on both bridge-spawned foreign threads.
fn Bump() { total.fetch_add(1); }

fn RuntimeSeedL(x: i64) -> i64 { return x + 20; }

fn Run() -> i32 {
  // 34 seeded + 8 bumps = prints 42.
  total.store(RuntimeSeedL(14));
  Cpp.StartWorkers();
  Cpp.JoinWorkers();
  // The `as i32` chain from `load()`'s cpp-compat return type is what
  // this adjudication run vets first (fork/f008/plan.md adjudication D).
  Core.Print(total.load() as i32);
  return 0;
}
