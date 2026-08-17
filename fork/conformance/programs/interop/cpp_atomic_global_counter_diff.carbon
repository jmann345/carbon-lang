// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: C++ interop: threading, atomics, memory model, synchronization
// EXPECT-EXIT: 0
// SKIP: defect TA-D3 (W-022) — a file-scope Carbon `var` typed by an imported C++ template SPECIALIZATION compiles but fails to LINK: measured 2026-07-19 with `var gcount: Cpp.std.atomic(i32);`, `undefined symbol: _Cgcount.Main.1` (fork/design-sprint/threading-atomics.md:103). Plain imported-class globals (`std::mutex`, matrix row 14) link fine, localizing the defect to specialization-typed global emission in toolchain/lower/ (the F8a mechanism probe is lower/testdata/interop/cpp/globals_carbon_defined.carbon). Un-SKIP (and uncomment the body) when F8c (fork/f008/plan.md §3) lands the global-definition-emission fix; a one-off runner compile+link of THIS pair is F8c's first-step H0 ("fixed upstream") adjudication run (plan §2.3, adjudication D) — run BEFORE choosing any fix site.
//
// Differential pair, written ahead of the F8c fix (write-tests-first): a
// file-scope Carbon `var total: Cpp.std.atomic(i64);` is seeded at runtime
// (R16d), bumped by two bridge-spawned threads calling back into the
// exported Carbon `Bump` (4x each), joined, and printed — exit-code +
// stdout equality with the oracle's C++ global `std::atomic<int64_t>` is
// the LINK-LEVEL arbiter D3 needs (plan §5 R-4: wrong total after a
// successful link means the wrong object was defined). Oracle:
// cpp_atomic_global_counter_diff.diff.cpp; byte-identical exit code and
// stdout per DIFF-1, no EXPECT-STDOUT. Join-before-print.

import Core library "io";
// import Cpp library "<atomic>";
// import Cpp library "<thread>";
//
// var total: Cpp.std.atomic(i64);
//
// fn Bump();
//
// inline Cpp '''
// inline std::thread w1;
// inline std::thread w2;
//
// inline void StartWorkers() {
//   w1 = std::thread([] { for (int i = 0; i < 4; ++i) Carbon::Bump(); });
//   w2 = std::thread([] { for (int i = 0; i < 4; ++i) Carbon::Bump(); });
// }
// inline void JoinWorkers() {
//   w1.join();
//   w2.join();
// }
// ''';
//
// // Runs on both bridge-spawned foreign threads.
// fn Bump() { total.fetch_add(1); }

fn RuntimeSeedL(x: i64) -> i64 { return x + 20; }

fn Run() -> i32 {
  // Intended body once F8c lands (34 seeded + 8 bumps = prints 42):
  //   total.store(RuntimeSeedL(14));
  //   Cpp.StartWorkers();
  //   Cpp.JoinWorkers();
  //   // NOTE: the `as i32` chain from `load()`'s cpp-compat return type
  //   // is statically unverified; F8c's first-step adjudication run
  //   // vets it before this pair is un-SKIPped (fork/f008/plan.md).
  //   Core.Print(total.load() as i32);
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped without
  // uncommenting the body.
  return 1;
}
