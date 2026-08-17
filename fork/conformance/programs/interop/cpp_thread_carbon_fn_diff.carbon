// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: C++ interop: threading, atomics, memory model, synchronization
// EXPECT-EXIT: 0
// SKIP: defect TA-D1 (W-023) — `Cpp.std.thread.thread(Work)` with a Carbon function as the callable fails check with: error: call argument of type `<type of Work>` is not supported [CppCallArgTypeNotSupported] (measured 2026-07-19, fork/design-sprint/threading-atomics.md:101): TryMapType in check/cpp/type_mapping.cpp has no SemIR::FunctionType case, so the argument falls to `default:` and arg invention fails — the same diagnostic the F8a probe check/testdata/interop/cpp/function/import/fail_todo_carbon_fn_as_callable.carbon pins against a mock header. Un-SKIP (and uncomment the body) when F8d (fork/f008/plan.md §3) lands the concrete-Carbon-fn-as-C++-callable mapping — or, under the plan's §2.4 sanctioned degrade path, this pair STAYS SKIP with its text updated in place (documented limitation; un-SKIP condition becomes W-023's upstream-watch, p003848 lambdas). Never rewritten to an inline-C++ bridge spawn: a bridge oracle would pass with zero Carbon-fn-callable support (plan §2.4).
//
// Differential pair, written ahead of the F8d fix (write-tests-first): the
// C++ side's `std::thread` must execute the ACTUAL Carbon function body —
// the observable side effect is a runtime-seeded fetch_add on an atomic
// checked after `.join()` (plan §5 R-6: a pair passing with the Carbon body
// edited to a different value would prove the oracle isn't running the
// Carbon code). Shared state deliberately lives in a C++-DEFINED inline
// global (the D3 workaround, threading-atomics.md:105-109), so this pair
// arbitrates ONLY the D1 callable mapping. Oracle: plain
// `std::thread(Work)` (cpp_thread_carbon_fn_diff.diff.cpp); byte-identical
// exit code and stdout per DIFF-1, no EXPECT-STDOUT. Join-before-print.

import Core library "io";
// import Cpp library "<atomic>";
// import Cpp library "<thread>";
//
// // Shared state in a C++-defined inline global: isolates D1 from D3.
// inline Cpp '''
// inline std::atomic<int> hits{0};
// ''';
//
// // Runs on the std::thread spawned DIRECTLY on the Carbon function.
// fn Work() { Cpp.hits.fetch_add(RuntimeSeed(22)); }

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  // Intended body once F8d lands (prints 42 — the Carbon body's seeded add):
  //   var t: Cpp.std.thread = Cpp.std.thread.thread(Work);
  //   t.join();
  //   Core.Print(Cpp.hits.load());
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped without
  // uncommenting the body.
  return 1;
}
