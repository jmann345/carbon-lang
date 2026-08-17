// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: C++ interop: threading, atomics, memory model, synchronization
// EXPECT-EXIT: 0
//
// Un-SKIPped at F8b (fork/f008/plan.md §3 F8b), the SKIP→PASS flip off the
// F8a red baseline: F8b's triviality predicate (`IsTriviallyCopyableForExport`,
// check/cpp/export.cpp) exports all-scalar no-user-Destroy Carbon classes
// WITHOUT the thunk destructor, so libc++'s
// `static_assert(is_trivially_copyable<T>)` gate accepts `Carbon::Vec2` and
// `std::atomic<Vec2>` instantiates and operates. Differential pair:
// store/exchange/load of a `std::atomic<Vec2>` where Vec2 is an all-scalar
// Carbon class, values runtime-seeded (R16d, `RuntimeSeed(x) = x + 20`) so
// constant folding cannot fake the round trips. Oracle: the identical C++
// struct through the same operations (cpp_atomic_carbon_class_diff.diff.cpp);
// byte-identical exit code and stdout per DIFF-1, no EXPECT-STDOUT. This pair
// on real `<atomic>` is the arbiter of what the mock-header check golden
// (check/testdata/interop/cpp/class/export/trivially_copyable.carbon) only
// dump-pins — plan §5 R-2: this pair failing on real libc++ while the mock
// golden passes falsifies the fix as mock divergence. The negative side (a
// user-Destroy class must still be rejected, R-3) is pinned by
// fail_atomic_of_nontrivial_carbon_class.carbon in the same golden directory.

import Core library "io";
import Cpp library "<atomic>";

// All-scalar, no user Destroy: qualifies under the F8b §2.2 predicate.
class Vec2 {
  var x: i32;
  var y: i32;
}

fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  var a: Cpp.std.atomic(Vec2);
  var first: Vec2 = {.x = RuntimeSeed(1), .y = RuntimeSeed(2)};
  a.store(first);
  var second: Vec2 = {.x = RuntimeSeed(3), .y = RuntimeSeed(4)};
  var old: Vec2 = a.exchange(second);
  Core.Print(old.x);
  Core.Print(old.y);
  var cur: Vec2 = a.load();
  Core.Print(cur.x);
  Core.Print(cur.y);
  return 0;
}
