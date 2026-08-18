// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: C++ interop: threading, atomics, memory model, synchronization
// EXPECT-EXIT: 0
//
// Differential pair — the TA-D1 (W-023) arbiter, un-SKIPped at F8d off the
// F8a red baseline (fork/f008/plan.md §2.4, §3 F8d): `std::thread` is
// constructed DIRECTLY on a Carbon function — `Cpp.std.thread.thread(Work)`,
// no inline-C++ bridge — and the C++ side must execute the ACTUAL Carbon
// function body: the observable side effect is a runtime-seeded fetch_add on
// an atomic checked after `.join()` (plan §5 R-6: a pair passing with the
// Carbon body edited to a different value would prove the oracle isn't
// running the Carbon code). Shared state deliberately lives in a C++-DEFINED
// inline global (the D3 workaround, threading-atomics.md:105-109), so this
// pair arbitrates ONLY the D1 callable mapping. A SECOND same-signature
// Carbon function (`Work2`) is spawned on a second thread through the SAME
// `std::thread` constructor instantiation: if the two imports collided on
// one thunk symbol (the same-signature collision the `.argN.<mangled>`
// asm-label suffix prevents), both threads would run one body and the total
// would diverge from the oracle. Oracle: plain `std::thread(Work)` +
// `std::thread(Work2)` (cpp_thread_carbon_fn_diff.diff.cpp); byte-identical
// exit code and stdout per DIFF-1, no EXPECT-STDOUT. Joins-before-print.

import Core library "io";
import Cpp library "<atomic>";
import Cpp library "<thread>";

// Shared state in a C++-defined inline global: isolates D1 from D3.
inline Cpp '''
inline std::atomic<int> hits{0};
''';

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// Runs on the std::thread spawned DIRECTLY on the Carbon function.
fn Work() { Cpp.hits.fetch_add(RuntimeSeed(22)); }

// Same signature as `Work`, different body: both go through the same
// `std::thread` constructor instantiation, so their thunks must be distinct.
fn Work2() { Cpp.hits.fetch_add(RuntimeSeed(-13)); }

fn Run() -> i32 {
  // Prints 49 — Work's seeded 42 plus Work2's seeded 7, observed after both
  // joins. Two Work-bodies (84) or two Work2-bodies (14) would expose a
  // thunk-symbol collision.
  var t: Cpp.std.thread = Cpp.std.thread.thread(Work);
  var t2: Cpp.std.thread = Cpp.std.thread.thread(Work2);
  t.join();
  t2.join();
  Core.Print(Cpp.hits.load());
  return 0;
}
