// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: C++ interop: threading, atomics, memory model, synchronization
// EXPECT-EXIT: 0
// SKIP: defect TA-D2 (W-021) — `Cpp.std.atomic(Vec2)` over an all-scalar Carbon class instantiates (export works) but libc++'s `static_assert(is_trivially_copyable<T>)` fires — measured 2026-07-19 over `Carbon::P` (fork/design-sprint/threading-atomics.md:102, quoted verbatim there); this pair instantiates the same assert over its own `Carbon::Vec2`: check/cpp/export.cpp does not mark exported Carbon classes trivially copyable even when they are — CompleteType adds a thunk-calling destructor to every plain exported class (check/cpp/generate_ast.cpp:489, TODO at :492 at this branch's head — post-B2a the add is guarded `!isa<ClassTemplateSpecializationDecl>`, which does not reach this defect), so `is_trivially_copyable` is false for ALL Carbon classes. Un-SKIP (and uncomment the body) when F8b (fork/f008/plan.md §3) lands the triviality predicate + conditional trivial destructor export; the mock-header red baseline this pair arbitrates on real libc++ is check/testdata/interop/cpp/class/export/fail_todo_trivially_copyable.carbon.
//
// Differential pair, written ahead of the F8b fix (write-tests-first):
// store/exchange/load of a `std::atomic<Vec2>` where Vec2 is an all-scalar
// Carbon class, values runtime-seeded (R16d, `RuntimeSeed(x) = x + 20`) so
// constant folding cannot fake the round trips. Oracle: the identical C++
// struct through the same operations (cpp_atomic_carbon_class_diff.diff.cpp);
// byte-identical exit code and stdout per DIFF-1, no EXPECT-STDOUT. Real
// `<atomic>` on the runner arbitrates what the mock-header check golden only
// dump-pins (plan §5 R-2: mock divergence falsifies the fix).

import Core library "io";
// import Cpp library "<atomic>";

// All-scalar, no user Destroy: qualifies under the F8b §2.2 predicate.
class Vec2 {
  var x: i32;
  var y: i32;
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  // Intended body once F8b lands (prints 21, 22, 23, 24):
  //   var a: Cpp.std.atomic(Vec2);
  //   var first: Vec2 = {.x = RuntimeSeed(1), .y = RuntimeSeed(2)};
  //   a.store(first);
  //   var second: Vec2 = {.x = RuntimeSeed(3), .y = RuntimeSeed(4)};
  //   var old: Vec2 = a.exchange(second);
  //   Core.Print(old.x);
  //   Core.Print(old.y);
  //   var cur: Vec2 = a.load();
  //   Core.Print(cur.x);
  //   Core.Print(cur.y);
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped without
  // uncommenting the body.
  return 1;
}
