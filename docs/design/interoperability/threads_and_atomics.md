# Threads, atomics, and the memory model

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [The memory-model contract](#the-memory-model-contract)
-   [In the 0.1 toolchain](#in-the-01-toolchain)
-   [Alternatives considered](#alternatives-considered)
-   [References](#references)

<!-- tocstop -->

## Overview

Carbon 0.1 has no threads, atomics, or synchronization of its own. A Carbon
program uses C++'s: `std::thread`, `std::atomic`, `std::mutex`, and the rest of
the C++ standard library's threading support are imported like any other C++
API, and they apply to Carbon code with their C++ meaning. This page states that
contract. It is fixed by fork decision F-008 (2026-07-19,
[decision log](/fork/decision-log.md)), whose design paper is
[fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md);
Carbon-native threading is deferred to at least 0.2
([milestones](/docs/project/milestones.md#features-explicitly-deferred-until-at-least-02)).

## The memory-model contract

1.  Carbon 0.1 adopts the C++ memory model unchanged (C++20 `[intro.races]`
    and `[atomics.order]`). The interoperability goals require compatibility
    with it
    ([Compatibility with the C++ memory model](philosophy_and_goals.md#compatibility-with-the-c-memory-model)),
    and the [FAQ](/docs/project/faq.md#what-is-carbons-memory-model) commits
    Carbon to matching it closely.
2.  Ordinary Carbon accesses are C++ non-atomic accesses. Two conflicting
    accesses from different threads, at least one a write and not both atomic,
    with no happens-before ordering between them, are a data race, and a data
    race is undefined behavior, as in C++. The 0.1 toolchain does not detect
    data races; data-race safety belongs to the
    [safety design](../safety/README.md).
3.  Atomicity is a property of an object's type, and the atomic types come from
    C++: `Cpp.std.atomic(T)` is `std::atomic<T>`. Carbon 0.1 has no per-access
    atomic syntax and no `volatile`.
4.  Synchronization composes across the language boundary: a happens-before
    edge established by a C++ atomic operation, mutex, or condition variable
    orders Carbon accesses exactly as it orders C++ accesses. In a compilation
    that imports C++, the toolchain lowers the Carbon code into the same LLVM
    module as the C++ code (`toolchain/lower/context.cpp`, the `llvm_module_`
    initializer), so both use the same atomic instructions.
5.  Any thread may run Carbon code. Carbon functions are ordinary native
    functions with no thread affinity: a `std::thread` can run a Carbon function
    directly, and C++ code can call Carbon functions from threads it started.
    C++ `thread_local` variables are usable from Carbon, each thread seeing its
    own; Carbon has no thread-local storage class of its own in 0.1.
6.  C++ destructors run at Carbon scope exit, so the guards `std::lock_guard`
    and `std::unique_lock` lock and unlock as they do in C++, and are the
    intended locking style.
7.  Not in 0.1: Carbon-native threads, atomics, and async; guarantees for signal
    handlers; C `_Atomic` interop. F-008 leaves the exception behavior of
    threading APIs to the exception-interop design, which fork decision F-006
    fixes: a C++ exception, including one thrown by a threading API, never
    unwinds a Carbon frame
    ([Interoperating with C++ exceptions](../error_handling.md#interoperating-with-c-exceptions),
    with the `--cpp-exceptions` option of fork work item W-016).

Held PR 53 (fork decision F-013, D-SAFE-16) names `Core.Thread` and
`Core.Atomic(T)`, a Carbon signature over `Cpp.std.atomic(T)`, for the fifth
stage of its safety design (fork work item W-149). Whether to reserve
`Core.MemoryOrder` is an open question. Nothing in 0.1 declares any of the
three.

## In the 0.1 toolchain

This program exercises points 3 to 6 of the contract:

```carbon
import Core library "io";
import Cpp library "<atomic>";
import Cpp library "<mutex>";
import Cpp library "<thread>";

import Cpp inline '''c++
inline thread_local int per_thread = 0;
''';

// Atomicity is a property of the object's type, an imported C++ type.
var hits: Cpp.std.atomic(i32);
// An ordinary Carbon variable, protected by a C++ mutex.
var total: i32 = 0;
var total_mutex: Cpp.std.mutex;

fn Work() {
  hits.fetch_add(1);
  Cpp.per_thread += 5;
  // The guard's C++ destructor unlocks the mutex at Carbon scope exit.
  var unused lock: Cpp.std.lock_guard(Cpp.std.mutex) =
      Cpp.std.lock_guard(Cpp.std.mutex).lock_guard(ref total_mutex);
  total += Cpp.per_thread;
}

fn Run() -> i32 {
  Cpp.per_thread = 100;
  // A `std::thread` runs a Carbon function directly.
  var a: Cpp.std.thread = Cpp.std.thread.thread(Work);
  var b: Cpp.std.thread = Cpp.std.thread.thread(Work);
  a.join();
  b.join();
  // Each thread saw its own `per_thread`, starting at zero.
  Core.Print(hits.load());
  Core.Print(total);
  Core.Print(Cpp.per_thread);
  return 0;
}
```

This prints `2`, `10`, and `100`: both threads ran `Work`, each saw its own
`per_thread` starting at zero, and the main thread's copy kept `100`. The fork's
conformance programs in `fork/conformance/programs/interop/`,
`cpp_threading_atomics.carbon`, `cpp_thread_carbon_fn_diff.carbon` (a
`std::thread` constructed on a Carbon function),
`cpp_atomic_carbon_class_diff.carbon` (a `std::atomic` of an exported Carbon
class with only scalar fields), `cpp_atomic_global_counter_diff.carbon` (a
Carbon global of type `Cpp.std.atomic(i64)` bumped from threads that C++
started), `cpp_thread_mutex_raii.carbon`, and `cpp_thread_condvar_diff.carbon`,
exercise the contract; all six pass.

## Alternatives considered

F-008 compared four options (the design paper's "Options"): Option A,
"Document-and-conform - adopt the C++ memory model, fix nothing", which
documents the contract and leaves three toolchain defects unfixed; Option B,
"Option A + targeted toolchain fixes for the three verified defects", the
choice (`std::thread` on a Carbon function, a Carbon global of a C++ template
specialization type, and `std::atomic` of a Carbon class, all fixed in the
fork's toolchain, fork work items W-021 to W-023); Option C, "Option B + a
`Core.Sync` veneer library", which adds a `Core.Sync` library veneer over the
C++ types; and Option D, "Carbon-native atomics
lowered directly to LLVM". The veneer and native atomics were rejected for 0.1
as new design ahead of the 0.2 concurrency work.

## References

-   Fork decision F-008, [decision log](/fork/decision-log.md)
-   [fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md)
-   Proposal
    [#175: C++ interoperability goals](/proposals/p000175-c-interoperability-goals.md)
