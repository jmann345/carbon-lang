# Threading, atomics, and the C++ memory model

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [The memory model](#the-memory-model)
    -   [Carbon adopts the C++ memory model](#carbon-adopts-the-c-memory-model)
    -   [Happens-before crosses the language boundary](#happens-before-crosses-the-language-boundary)
    -   [Data races](#data-races)
    -   [Atomicity is a property of the type](#atomicity-is-a-property-of-the-type)
-   [Using C++ threading from Carbon](#using-c-threading-from-carbon)
    -   [Atomics](#atomics)
    -   [Mutexes and RAII guards](#mutexes-and-raii-guards)
    -   [Condition variables](#condition-variables)
    -   [Threads: any thread may run Carbon code](#threads-any-thread-may-run-carbon-code)
    -   [Thread-local storage](#thread-local-storage)
    -   [C++20 surface](#c20-surface)
-   [Documented limitations and their planned fixes](#documented-limitations-and-their-planned-fixes)
    -   [L1: A Carbon function as a `std::thread` callable](#l1-a-carbon-function-as-a-stdthread-callable)
    -   [L2: `std::atomic` over a Carbon class](#l2-stdatomic-over-a-carbon-class)
    -   [L3: File-scope globals of C++ template specialization type](#l3-file-scope-globals-of-c-template-specialization-type)
-   [The exception environment](#the-exception-environment)
-   [Non-goals for 0.1](#non-goals-for-01)
-   [Conformance arbitration](#conformance-arbitration)
-   [Alternatives considered](#alternatives-considered)
-   [Open sub-forks](#open-sub-forks)
-   [References](#references)

<!-- tocstop -->

## Overview

In 0.1, Carbon's threading story is C++'s threading story, used through
interop. The
[milestones](/docs/project/milestones.md#features-explicitly-deferred-until-at-least-02)
explicitly defer Carbon-native threading and coroutines/async until at least
0.2 (Carbon-native atomics and thread-local storage are not named there
separately; this document treats them as subsumed under the native-threading
deferral). What 0.1 delivers is the
[milestone bullet](/docs/project/milestones.md#functions-statements-expressions-etc): "support
for C++'s threading and atomic primitives, memory model, and synchronization
tools". Concretely:

-   Mixed Carbon/C++ programs have **one memory model — C++'s** — and
    synchronization operations performed in either language order memory
    accesses in both. This is not an aspiration layered on top of the
    toolchain; it is [true by construction](#happens-before-crosses-the-language-boundary)
    of how mixed files are compiled.
-   Carbon code uses `std::atomic`, `std::mutex`, `std::condition_variable`,
    `std::thread`, and the rest of the C++ synchronization vocabulary directly,
    through the ordinary
    [C++ import mechanism](README.md#importing-c-apis-into-carbon). There is no
    threading-specific interop machinery and no wrapper layer; the
    [general interop surface](#using-c-threading-from-carbon) carries the whole
    bullet.
-   Carbon functions are ordinary native functions: **any thread may run Carbon
    code**, whoever created it.

Three specific defects in the current toolchain prevent the most obvious
spellings of three idioms; they are specified as
[documented limitations with planned fixes](#documented-limitations-and-their-planned-fixes),
fixed by fork decision
[F-008](/fork/decision-log.md#f-008-threadingatomics-interop--fix-the-three-defects-2026-07-19).
Each has a supported pure-user-code workaround until its fix lands.

> OPEN (sub-fork): this document's file name. The ratified option paper names
> the deliverable `docs/design/interoperability/threads_and_atomics.md`; it
> landed as `threading.md` (the name the design README and interop README now
> link to). Recommendation: keep `threading.md` — shorter, already linked —
> recording the divergence from the paper as a ratified sub-decision.

This design was fixed by fork decision F-008. The rejected alternatives —
documenting around the defects, a `Core.Sync` veneer library, and
Carbon-native atomics — are summarized under
[Alternatives considered](#alternatives-considered) and are not relitigated
here.

## The memory model

### Carbon adopts the C++ memory model

**Carbon 0.1 adopts the C++ memory model unchanged** — the C++20 rules of
[intro.races] and [atomics.order]. This realizes the accepted interop goal of
[compatibility with the C++ memory model](philosophy_and_goals.md#compatibility-with-the-c-memory-model)
(proposal
[#175](https://github.com/carbon-language/carbon-lang/pull/175)) and the
[language overview's](../README.md#bidirectional-interoperability-with-c-and-c)
statement that C++ and Carbon will use the same memory model; the
[project FAQ](/docs/project/faq.md#what-is-carbons-memory-model) commits to
matching C++'s memory model closely "to maintain zero-overhead
interoperability".

The consequences, stated as rules:

-   An ordinary Carbon memory access is a C++ non-atomic access. It has no
    atomicity, no ordering effect, and no synchronization effect.
-   An operation on an imported C++ synchronization type — an atomic access, a
    mutex acquisition or release, a thread creation or join — has exactly the
    semantics C++ gives it, including its ordering and synchronization
    effects, regardless of whether the operation is written in Carbon or in
    C++.
-   The definitions of _sequenced before_, _synchronizes with_,
    _happens before_, and _data race_ are C++'s definitions, applied to the
    union of all Carbon and C++ evaluations in the program as a single set.
    There is no per-language partition of the ordering relations.

Carbon adds no memory-model constructs of its own in 0.1: no per-access atomic
syntax, no fences beyond the imported `std::atomic_*_fence` functions, and no
`volatile` (Carbon has no `volatile` qualifier at all).

### Happens-before crosses the language boundary

A happens-before edge established by any synchronization operation orders
Carbon accesses exactly as it orders C++ accesses — regardless of which
language performs the synchronizing operation and which language performs the
ordered accesses. If a Carbon store to a plain field happens-before a C++
release store to an atomic, a C++ thread that observes that store with an
acquire load also observes the Carbon store, and vice versa in every
combination.

This guarantee is by construction, at two levels:

-   **Within a mixed file: one `llvm::Module`.** When a Carbon file imports
    C++, the toolchain does not compile the two languages separately and link
    the results; Carbon lowering builds its IR into the _same_ `llvm::Module`
    that the embedded Clang's `CodeGenerator` produced for the imported C++
    (`toolchain/lower/context.cpp`, `toolchain/lower/lower.cpp`,
    `toolchain/lower/file_context.cpp`). Carbon-generated and Clang-generated
    IR share one module, one optimization pass pipeline, and one target
    backend, so LLVM's implementation of the C++11 atomics and ordering rules
    applies uniformly to every access in the file. There is no boundary at
    which an ordering guarantee could be dropped, because after lowering there
    is no boundary.
-   **Across separately compiled translation units**, including under the
    [mixed-toolchain mode](philosophy_and_goals.md#support-mixing-carbon-and-c-toolchains):
    Carbon and C++ TUs interoperate through the target's C++ ABI and the same
    LLVM atomics lowering that Clang uses, exactly as two C++ TUs from
    different compilers do. Object-level atomic operations on the same
    addresses compose under the target architecture's rules, which is what the
    C++ memory model's own cross-TU guarantee rests on.

### Data races

Two conflicting accesses (same memory location, at least one a write, not both
atomic) from different threads, neither happening-before the other, are a
**data race, and the behavior is undefined** — exactly C++'s rule, applied
across both languages.

Carbon 0.1 provides no compile-time data-race protection. This is a stated
property of 0.1 Permissive Carbon, not a permanent position: the
[safety design](../safety/README.md#memory-safety-model) plans compile-time
data-race enforcement through the type system as part of safe Carbon, and
reserves latitude on
[races that are not also temporal-safety violations](../safety/README.md#data-races-versus-unsynchronized-temporal-safety).
Nothing in this document forecloses that design; it specifies the model that
the future safety layer will police. The planned dynamic mitigation is the
Debug + [ThreadSanitizer](https://clang.llvm.org/docs/ThreadSanitizer.html)
[build mode](../safety/README.md#build-modes), which applies to
mixed programs as it does to pure C++ ones.

### Atomicity is a property of the type

In 0.1, atomicity is obtained exclusively by using an imported C++ atomic
type: `Cpp.std.atomic(T)`, `Cpp.std.atomic_flag`, and (under
[C++20](#c20-surface)) `Cpp.std.atomic_ref(T)`. There is no Carbon syntax that
makes an individual access atomic, and no Carbon type qualifier for
atomicity. A plain Carbon `var` is never atomic, whatever its size.

## Using C++ threading from Carbon

Everything in this section works through the general interop machinery —
header import, template instantiation through the embedded Clang,
`ref` arguments binding to C++ `T&` parameters (proposal
[#5434](https://github.com/carbon-language/carbon-lang/pull/5434)), imported
operator overloads, and synthesized destruction of C++ locals at Carbon scope
exit. No threading-specific compiler support exists, and none is needed for
this surface. Every form shown below has been verified by compiling, linking,
and executing it against the arbiter toolchain (fork decision
[F-004](/fork/decision-log.md)).

The relevant standard library headers are imported like any others:

```carbon
import Cpp library "<atomic>";
import Cpp library "<mutex>";
import Cpp library "<shared_mutex>";
import Cpp library "<condition_variable>";
import Cpp library "<thread>";
import Cpp library "<vector>";
import Cpp library "<chrono>";
```

### Atomics

`Cpp.std.atomic(T)` instantiates and behaves as `std::atomic<T>` for the
argument type, including for `bool`, integer, floating-point, and pointer
specializations. Loads, stores, read-modify-write operations, memory-order
arguments (with their C++ defaults), compare-exchange through `ref`
arguments, and the atomic's operator sugar are all usable:

```carbon
fn Demo() -> i32 {
  var a: Cpp.std.atomic(i32);
  a.store(41);
  a.fetch_add(1);                                  // Sequentially consistent.
  a.store(1, Cpp.std.memory_order_release);        // Explicit ordering.
  let observed: i32 = a.load(Cpp.std.memory_order_acquire);

  var expected: i32 = observed;
  a.compare_exchange_strong(ref expected, 7);      // C++ `T&` takes `ref`.
  a.exchange(9);

  a = 5;                                           // atomic `operator=`.
  a += 2;                                          // atomic `operator+=`.
  let v: i32 = a;                                  // `operator T` conversion.
  return v;
}
```

`Cpp.std.atomic_flag` (`test_and_set`/`clear`), `Cpp.std.atomic(bool)`,
`Cpp.std.atomic(f64)`, and pointer atomics — including storing and loading the
address of a Carbon object through `Cpp.std.atomic(i32*)` — follow the same
pattern. The `memory_order_*` constants import as ordinary constants. The
free-function fences `atomic_thread_fence` and `atomic_signal_fence` are C++11
library functions and import in the default language mode like the rest of
this surface — no [C++20 flag](#c20-surface) is required.

### Mutexes and RAII guards

`Cpp.std.mutex`, `Cpp.std.recursive_mutex`, `Cpp.std.shared_mutex`, and their
member functions (`lock`, `unlock`, `try_lock`, `lock_shared`, ...) are usable
as locals and as file-scope Carbon globals.

RAII locking is part of the contract: C++ destructors of imported types run at
Carbon scope exit through the synthesized `Destroy` impl, so
`lock_guard`/`unique_lock` idioms carry over — the mutex is held exactly while
the guard object is alive:

```carbon
fn WithLock(m: Cpp.std.mutex*) {
  var g: Cpp.std.lock_guard(Cpp.std.mutex)
      = Cpp.std.lock_guard(Cpp.std.mutex).lock_guard(ref *m);
  // Critical section: `*m` is held.
}   // `g` is destroyed; `*m` is released.
```

RAII guards are the recommended locking style; bare `lock()`/`unlock()` pairs
are legal but carry the same hazards they carry in C++. A guard binding like
`g` exists only for its destructor and is never read; the toolchain's
"binding unused" warning on it is expected and intentional for this idiom.

### Condition variables

`Cpp.std.condition_variable` supports the full wait/notify protocol from
Carbon, including the standard wait-loop-under-`unique_lock` idiom with
`Cpp.cv.wait(ref ul)` and notification from another thread via `notify_one` /
`notify_all`. A complete producer/consumer exchange — a C++ worker thread
locking, writing, and notifying while Carbon waits in a predicate loop — is
expressible today with shared state on the C++ side of the file (see
[L3](#l3-file-scope-globals-of-c-template-specialization-type) for why the
shared state currently lives there).

### Threads: any thread may run Carbon code

Carbon functions are ordinary native functions with no runtime, no TLS setup
requirement, and no main-thread assumption. Running a Carbon function on a
`std::thread`, a thread pool, or any foreign thread is defined, and
synchronization performed on that thread composes with the rest of the
program per the [memory model](#the-memory-model):

```carbon
fn Work();

inline Cpp '''
inline void SpawnAndJoinWorkers(int n) {
  std::vector<std::thread> ts;
  for (int i = 0; i < n; ++i) ts.emplace_back([] { Carbon::Work(); });
  for (auto& t : ts) t.join();
}
''';

// Runs on each worker thread.
fn Work() {}

fn Run() { Cpp.SpawnAndJoinWorkers(4); }
```

The bridge's `std::vector` comes from the `import Cpp library "<vector>";` in
this section's [import list](#using-c-threading-from-carbon); the
`inline Cpp '''...'''` form itself requires some prior `import Cpp ...`
declaration in the file. That form is implemented in the toolchain
(`toolchain/parse/handle_inline_decl.cpp`) but its section in the
[interop README](README.md#importing-c-apis-into-carbon) is still a TODO
placeholder — this document depends on the implemented behavior, not on a
written specification.

The inline-C++ spawn bridge shown here is the supported workaround for
[limitation L1](#l1-a-carbon-function-as-a-stdthread-callable); when L1's fix
lands, `Cpp.std.thread.thread(Work)` is spelled directly in Carbon and the
bridge becomes unnecessary. Thread management utilities —
`Cpp.std.this_thread.yield()`,
`Cpp.std.this_thread.sleep_for(Cpp.std.chrono.milliseconds.duration(10))`
(note that the imported constructor is named `duration` through the alias),
`Cpp.std.thread.hardware_concurrency()` — are ordinary imported calls.

### Thread-local storage

C++ `thread_local` variables are readable and writable from Carbon as
`Cpp.name`, with C++'s per-thread semantics. Carbon has no native
thread-local storage class in 0.1; declaring thread-local state means
declaring it in C++ (typically as an `inline thread_local` variable in
[inline C++](README.md#importing-c-apis-into-carbon) or an imported header).

### C++20 surface

The embedded Clang compiles imported C++ in its default language mode unless
the user passes `--clang-arg=-std=c++20`. With that flag, the C++20
synchronization surface imports and works: `std::jthread`,
`atomic::wait`/`notify_one`/`notify_all`, and `std::atomic_ref`. Without the
flag, that surface is absent exactly as it would be for a C++17 compilation.
(The free-function fences are not part of this surface: they are C++11
functions, [available in the default mode](#atomics).)

> OPEN (sub-fork): whether this document's examples and the conformance suite
> pin `--clang-arg=-std=c++20`, or track Clang's default mode and mark the
> C++20 surface "works with flag". Recommendation: pin C++20 in the
> conformance suite and document the flag here, keeping the default-mode
> behavior tested by at least one program.

## Documented limitations and their planned fixes

Three defects in the current toolchain block the most direct spellings of
three idioms. Fork decision
[F-008](/fork/decision-log.md#f-008-threadingatomics-interop--fix-the-three-defects-2026-07-19)
commits to fixing all three; until each fix lands, the limitation and its
workaround below are the specified 0.1 behavior. All three fixes make the
general interop machinery more complete — none adds new syntax or new
semantics — and each is intended to be upstreamable. They land as separate
child branches under the fork's merge gating (decision
[F-002](/fork/decision-log.md)), sequenced L2, L3, L1 (smallest first). The
ratified option paper carries a contingency for L1, the largest fix: if it
proves deeper than estimated, it can degrade to a documented limitation
without reopening this document — the bridge workaround remains supported
either way.

> OPEN (sub-fork): whether L1's fix is 0.1-blocking — gating the bullet's
> scoreboard closure on the direct `Cpp.std.thread.thread(Work)` spelling — or
> committed-but-degradable per the option paper's contingency, with the bullet
> arbitrated on the working surface plus L2/L3. Recommendation:
> committed-but-degradable — the workaround program arbitrates the bullet
> meanwhile, and a direct-spelling program is added when the fix lands.

> OPEN (sub-fork): upstreaming policy for the three fixes — send each patch
> upstream after it lands in the fork, or keep them fork-local until upstream
> shows interest. Recommendation: fork-first, upstream-second — they are
> generic interop completions with no fork-specific design content, and
> upstreaming them reduces permanent merge burden.

### L1: A Carbon function as a `std::thread` callable

**Limitation.** Constructing a thread directly from a Carbon function value —
`Cpp.std.thread.thread(Work)` — is rejected in the check phase: there is no
mapping from a Carbon function value to a C++ callable in the interop type
mapping (`toolchain/check/cpp/type_mapping.cpp`,
`toolchain/check/cpp/overload_resolution.cpp`).

**Workaround (supported).** Spawn through an inline-C++ bridge that calls the
Carbon function back through its exported `Carbon::` name, as shown
[above](#threads-any-thread-may-run-carbon-code). The bridge is pure user
code; the Carbon function itself needs no annotation.

**Planned fix.** Map a _concrete, non-generic_ Carbon function value used as a
C++ call argument to a C++ function pointer whose pointee type is the
function's exported C++ signature, reusing the reverse-interop machinery that
already synthesizes `Carbon::F` declarations (`toolchain/check/cpp/export.cpp`),
and let Clang's overload resolution take it from there — which resolves the
`std::thread` constructor for a `void(*)()` exactly as it does in C++. Generic
and deduced-parameter functions remain unsupported with the current
diagnostic. Signature ABI compatibility is checked, not assumed; this is the
largest of the three fixes. Upstream's accepted lambdas proposal
([#3848](https://github.com/carbon-language/carbon-lang/pull/3848)) will
eventually give callables a richer mapping; that work supersedes rather than
conflicts with this fix (standing upstream-watch rule,
[fork/process.md](/fork/process.md)).

### L2: `std::atomic` over a Carbon class

**Limitation.** Instantiating `Cpp.std.atomic(P)` on a Carbon class `P` fails
libc++'s `static_assert(is_trivially_copyable<...>)` even when `P` is in fact
trivially copyable: the export machinery gives every exported Carbon class a
non-trivial C++ surface — in particular, a destructor with a function body
that calls back into the Carbon `Destroy` thunk
(`toolchain/check/cpp/generate_ast.cpp`, `toolchain/check/cpp/export.cpp`) —
so `std::is_trivially_copyable` never holds for the synthesized
`CXXRecordDecl`. The template instantiation itself already succeeds; the
triviality trait is the only blocker.

**Workaround (supported).** Declare the payload struct in C++ and use
`Cpp.std.atomic(Cpp.PayloadType)`; the Carbon side reads and writes the
payload's fields through ordinary interop.

**Planned fix.** When exporting a Carbon class that is
[trivially copyable](../unions.md#trivially-destructible-and-trivially-copyable-types)
— the predicate defined in the unions design (subsuming trivial
destructibility) and reused here, not restated — make the synthesized record
trivially copyable in Clang's eyes. This is more than setting a flag: for
classes satisfying the predicate, the destructor-thunk export named above must
be suppressed or replaced by a trivial destructor, and the remaining special
members left trivial, so that `std::is_trivially_copyable` holds in C++. This
fix is also the first slice of
the general "C++ templates instantiated on Carbon types" interop quality work:
any C++ template that gates on triviality traits benefits, not just
`std::atomic`.

### L3: File-scope globals of C++ template specialization type

**Limitation.** A file-scope Carbon global whose type is an imported C++
_template specialization_ — for example
`var gcount: Cpp.std.atomic(i32);` — compiles but fails to **link** with an
undefined symbol for the variable. The definition is not lost — file-level
lowering emits a defined global for the variable — but member calls on it
reference a _second_, auto-renamed external declaration of the same mangled
name: two emission paths in file-level lowering (the non-C++ global path and
the Clang-decl path fed by the export machinery's assembly-label attribute;
`toolchain/lower/file_context.cpp`, `toolchain/check/cpp/export.cpp`) each
create a global with the same name in the one `llvm::Module`, LLVM renames
the second on collision, and the two are never unified — so the access path
links against an undefined duplicate. Globals of plain imported class types
(`var gm: Cpp.std.mutex;`) take a single path and work today.

**Workaround (supported).** Keep shared state in C++-defined `inline` globals
and access them from Carbon as `Cpp.name`:

```carbon
inline Cpp '''
inline std::atomic<int> counter{0};
''';

fn Bump() { Cpp.counter.fetch_add(1, Cpp.std.memory_order_relaxed); }
```

(As with every `inline Cpp` block, the file must contain a prior
`import Cpp ...` declaration — here, the `<atomic>` import.)

**Planned fix.** Unify the symbol between the two global-emission paths in
file-level lowering (`toolchain/lower/file_context.cpp`) so that member-call
access references the emitted definition instead of a renamed duplicate
declaration, with a regression test in the lowering testdata and an execution
conformance program. This is a lowering completeness bug with no design
content.

## The exception environment

Several C++ threading APIs are potentially throwing: `std::thread`'s
constructor, `std::mutex::lock`, and `std::condition_variable` operations can
throw `std::system_error`. This document adds no exception rules of its own;
the boundary is governed entirely by the
[error handling design](../error_handling.md#interoperating-with-c-exceptions)
(fork decision [F-006](/fork/decision-log.md)):

-   The [`--cpp-exceptions`](../error_handling.md#the---cpp-exceptions-compile-option)
    option (default `auto`) configures the boundary. In `none` mode, imported
    threading code is compiled `-fno-exceptions` and no callee can throw. In
    `catch` mode, a call from Carbon to a potentially-throwing threading API
    is [fenced](../error_handling.md#the-fenced-boundary-terminate-semantics)
    by default: if the callee throws, the program prints a boundary diagnostic
    and terminates via `std::terminate` — defined behavior, never unwinding of
    Carbon frames.
-   A call site that wants to _handle_ the failure uses a
    [catching import](../error_handling.md#catching-imports-resultt-cppexception),
    consuming the call as `Core.Result(T, Cpp.Exception)`. For example, thread
    creation against resource exhaustion can be caught and surfaced as a
    value.
-   A C++ exception thrown on a foreign thread that is running Carbon code
    follows the same rules on that thread's stack: it never unwinds the Carbon
    frames there; it either stays within C++ frames, reaches a fence, or is
    captured by a catching thunk.

Dependency, stated plainly: the fenced boundary is stage B0 of the error
handling design and is not yet implemented — until it lands, an exception
escaping into a Carbon frame is undefined behavior, as it is everywhere in
today's interop. Catching imports are stage
[B3](../error_handling.md#implementation-staging), which depends on B0-B2 —
including the unimplemented `match` and choice-payload work — so the
handle-the-failure path is materially further out than the fence. Conformance
programs for this area therefore stay off throwing paths (no thread-creation
failure paths, no interruptible waits) until B0 is in the arbiter toolchain.

## Non-goals for 0.1

Stated to bound the contract:

-   **Carbon-native threads, atomics, thread-local storage, and async.** The
    [milestones](/docs/project/milestones.md#features-explicitly-deferred-until-at-least-02)
    explicitly defer "Carbon-native threading" and "Coroutines, async,
    generators, etc." until at least 0.2; native atomics and thread-local
    storage are not named there and are treated here as subsumed under the
    native-threading deferral. Nothing here presupposes their design.
-   **Data-race safety.** A 0.2+ safe-Carbon deliverable
    ([above](#data-races)); 0.1 is Permissive.
-   **Signal-handler guarantees.** `volatile sig_atomic_t`-style guarantees
    and async-signal-safety of Carbon code are unspecified in 0.1.
-   **`volatile`.** Carbon has no `volatile`; importing C++ APIs that traffic
    in `volatile`-qualified types is outside this contract.
-   **C `_Atomic` and `<stdatomic.h>`.** Untested and unspecified in 0.1;
    C++'s `<atomic>` is the supported spelling.
-   **Exception behavior of threading APIs** beyond what the
    [error handling design](../error_handling.md) specifies.

> OPEN (sub-fork): whether `volatile` and C `_Atomic`/`<stdatomic.h>` are
> merely untested (silently out of contract) or called out as explicit,
> diagnosed non-goals; C-header interop consumers may care. Recommendation:
> explicit non-goals in 0.1 as written above, with no new diagnostics.

> OPEN (sub-fork): whether to reserve the names `Core.Thread`, `Core.Atomic`,
> and `Core.MemoryOrder` now so 0.1-era code does not squat spellings the 0.2
> native design will want. Recommendation: reserve them (cheap now, awkward
> to reclaim later), without defining anything under them.

## Conformance arbitration

Per the fork's standing rules ([fork/process.md](/fork/process.md)), this
bullet is closed only by passing conformance programs under
`fork/conformance/programs/interop/`, not by this document. The area's
programs must produce deterministic output under the runner's exact-match
rule: results are printed only after joining all threads, and only from the
main thread. Functional coverage spans the
[working surface](#using-c-threading-from-carbon) (atomic RMW and orderings,
mutex/RAII, condition-variable producer/consumer, Carbon code on foreign
threads, `thread_local`) plus, as each
[fix](#documented-limitations-and-their-planned-fixes) lands, a program
spelling the previously blocked idiom directly.

> OPEN (sub-fork): how hard to arbitrate the memory model itself — add a
> stress program (N threads x M relaxed increments summing to exactly N*M,
> and/or release/acquire message passing) and/or a TSan-mode run to the
> scoreboard, accepting flake risk on a 4-core container. Recommendation:
> include the deterministic stress program (its expected total is exact, not
> timing-dependent); keep TSan as a non-scoreboard diagnostic run in 0.1.

## Alternatives considered

The alternatives for this area were researched in
[fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md)
and rejected in fork decision
[F-008](/fork/decision-log.md#f-008-threadingatomics-interop--fix-the-three-defects-2026-07-19):

-   **Document-and-conform only** (no toolchain fixes): rejected because the
    three defects are exactly the idioms an evaluating C++ developer writes
    in their first hour (`std::thread(fn)`, a global atomic counter,
    `std::atomic<MyType>`); documenting around them would calcify the
    workarounds into permanent warts.
-   **A `Core.Sync` veneer library** over `Cpp.std`: rejected as
    upstream-divergence risk for sugar — its names would quietly pre-empt the
    0.2 native-threading design, and every test written against it would need
    rewriting when that design lands.
-   **Carbon-native atomics** lowered directly to LLVM: rejected as a
    violation of the milestone's own scoping, which defers native threading
    precisely so 0.1 does not need it.

That decision is final; this document specifies the chosen design rather than
relitigating it.

## Open sub-forks

Collected from the body above; each is a point with more than one defensible
answer, to be decided by the user, never silently by an agent
([fork/process.md](/fork/process.md), "Sub-forks are forks").

1.  **C++ language mode for examples and conformance**
    ([C++20 surface](#c20-surface)): pin `--clang-arg=-std=c++20` or track
    Clang's default. _Recommendation: pin C++20 in the conformance suite and
    document the flag._
2.  **Upstreaming policy for the L1-L3 fixes**
    ([Documented limitations](#documented-limitations-and-their-planned-fixes)):
    fork-first-then-upstream or fork-local until pulled. _Recommendation:
    fork-first, upstream-second._
3.  **`volatile` / C `_Atomic` posture** ([Non-goals](#non-goals-for-01)):
    explicit non-goals or merely untested. _Recommendation: explicit
    non-goals in 0.1._
4.  **Name reservation for 0.2** ([Non-goals](#non-goals-for-01)): reserve
    `Core.Thread` / `Core.Atomic` / `Core.MemoryOrder` now or not.
    _Recommendation: reserve, defining nothing._
5.  **Memory-model arbitration depth**
    ([Conformance arbitration](#conformance-arbitration)): stress program
    and/or TSan run in the scoreboard. _Recommendation: deterministic stress
    program in the scoreboard; TSan as a non-scoreboard diagnostic run._
6.  **Is L1's fix 0.1-blocking?**
    ([Documented limitations](#documented-limitations-and-their-planned-fixes)):
    gate the bullet's closure on the direct `std::thread(carbon_fn)` spelling,
    or treat the fix as committed-but-degradable per the option paper's
    contingency. _Recommendation: committed-but-degradable; the workaround
    program arbitrates the bullet meanwhile._
7.  **Document file name** ([Overview](#overview)): keep `threading.md` or
    rename to the option paper's `threads_and_atomics.md`. _Recommendation:
    keep `threading.md`, recording the divergence as a ratified
    sub-decision._

## References

-   [Milestones: the threading/atomics interop bullet and the 0.2 deferral of native threading](/docs/project/milestones.md)
-   [Interoperability philosophy and goals: compatibility with the C++ memory model](philosophy_and_goals.md#compatibility-with-the-c-memory-model)
    / Proposal
    [#175: C++ interoperability goals](https://github.com/carbon-language/carbon-lang/pull/175)
-   [Language overview: bidirectional interoperability](../README.md#bidirectional-interoperability-with-c-and-c)
-   [Safety: memory safety model, data races, build modes](../safety/README.md)
-   [Error handling: interoperating with C++ exceptions](../error_handling.md#interoperating-with-c-exceptions)
    (fork decision F-006)
-   [Unions: trivially destructible and trivially copyable types](../unions.md#trivially-destructible-and-trivially-copyable-types)
    (the predicate L2's fix reuses)
-   Proposal
    [#5434: `ref` parameters, arguments, returns and `val` returns](https://github.com/carbon-language/carbon-lang/pull/5434)
    (covers `ref` arguments binding to C++ `T&`); Proposal
    [#3848: Lambdas](https://github.com/carbon-language/carbon-lang/pull/3848)
-   Fork decision
    [F-008: Threading/atomics interop — fix the three defects](/fork/decision-log.md#f-008-threadingatomics-interop--fix-the-three-defects-2026-07-19)
    and option paper
    [fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md)
    (including the executed capability matrix this document's working surface
    is derived from)
