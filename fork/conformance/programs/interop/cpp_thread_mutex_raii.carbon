// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — synthesizing Carbon overloads for imported C++ types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//
// Mutex/RAII across the language boundary — measured matrix row 8
// (fork/design-sprint/threading-atomics.md:89, verified by execution
// 2026-07-19; part of the F-008 F8a working-surface pair, fork/f008/plan.md
// §2.5). Probe 1: a `unique_lock` constructed from Carbon holds the mutex
// (`owns_lock()` observably true — prints `1`), then unlocks explicitly.
// Probe 2: a `lock_guard` lives and dies inside `LockInScope`'s function
// scope; its release at Carbon scope exit IS the synthesized Core.Destroy
// impl running the C++ destructor — if that Destroy did not run, the mutex
// would still be held and the `try_lock` after the call would fail, so `2`
// never prints (OUTPUT-MISMATCH). The file-scope `var gm: Cpp.std.mutex;`
// is the measured matrix row 14 shape (plain imported-class Carbon globals
// link fine — deliberately NOT the specialization-typed shape, which is
// defect D3's separate arbiter, cpp_atomic_global_counter_diff). Ctor
// spellings verbatim from row 8: `Cpp.std.lock_guard(Cpp.std.mutex)
// .lock_guard(ref gm)`. Deterministic single-threaded output.
//
// Bullet attachment (disclosed in fork/f008/plan.md §2.5): at F8a this
// program attaches to the synthesized-overloads bullet it genuinely
// arbitrates — the RAII release is the synthesized Destroy impl doing
// observable work. It re-homes to the threading bullet at F8b together with
// that bullet's SKIP→PASS flip (adjudication A: no bullet flips on the
// harness slice).

import Core library "io";
import Cpp library "<mutex>";

var gm: Cpp.std.mutex;

// The lock_guard's release at function-scope exit is the synthesized
// Core.Destroy impl invoking `~lock_guard()`.
fn LockInScope() {
  var unused g: Cpp.std.lock_guard(Cpp.std.mutex)
      = Cpp.std.lock_guard(Cpp.std.mutex).lock_guard(ref gm);
}

fn Run() -> i32 {
  // Probe 1: the unique_lock holds the mutex while it lives.
  var ul: Cpp.std.unique_lock(Cpp.std.mutex)
      = Cpp.std.unique_lock(Cpp.std.mutex).unique_lock(ref gm);
  if (ul.owns_lock()) {
    Core.Print(1);
  }
  ul.unlock();

  // Probe 2: guard acquired and RAII-released inside the callee's scope;
  // try_lock on the (now unlocked) mutex must succeed.
  LockInScope();
  if (gm.try_lock()) {
    Core.Print(2);
    gm.unlock();
  }
  return 0;
}
