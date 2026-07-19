# Design option paper: C++ threading/atomics/memory-model interop

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Problem statement](#problem-statement)
    -   [0.1 milestone bullets this area closes](#01-milestone-bullets-this-area-closes)
    -   [The surprise: most of this bullet already works](#the-surprise-most-of-this-bullet-already-works)
    -   [Measured state of the toolchain (2026-07-19)](#measured-state-of-the-toolchain-2026-07-19)
-   [Constraints](#constraints)
    -   [Design-principle constraints](#design-principle-constraints)
    -   [Interop constraints from the milestone](#interop-constraints-from-the-milestone)
    -   [Implementation realities in this toolchain](#implementation-realities-in-this-toolchain)
-   [The memory-model contract every option must state](#the-memory-model-contract-every-option-must-state)
-   [Options](#options)
    -   [Option A: Document-and-conform — adopt the C++ memory model, fix nothing](#option-a-document-and-conform--adopt-the-c-memory-model-fix-nothing)
    -   [Option B: Option A + targeted toolchain fixes for the three verified defects](#option-b-option-a--targeted-toolchain-fixes-for-the-three-verified-defects)
    -   [Option C: Option B + a `Core.Sync` veneer library](#option-c-option-b--a-coresync-veneer-library)
    -   [Option D: Carbon-native atomics lowered directly to LLVM](#option-d-carbon-native-atomics-lowered-directly-to-llvm)
-   [Recommendation](#recommendation)
-   [Dependencies on other workstreams](#dependencies-on-other-workstreams)
-   [Open questions for the user (beyond option choice)](#open-questions-for-the-user-beyond-option-choice)
-   [References](#references)

<!-- tocstop -->

## Problem statement

### 0.1 milestone bullets this area closes

Exactly one bullet, from `docs/project/milestones.md:176-177`:

> -   C++ interop: support for C++'s threading and atomic primitives, memory
>     model, and synchronization tools

Its scope boundary is set two sections later (`milestones.md:271`):
**Carbon-native threading is explicitly deferred until at least 0.2.** So the
0.1 deliverable is *interop-only*: Carbon code must be able to use
`std::thread`/`std::atomic`/`std::mutex` and friends, and mixed Carbon/C++
programs must have a defined memory model. The `fork/gap-analysis.md` row is:

> | C++ interop: threading, atomics, memory model, synchronization | MISSING |
> No dedicated support, tests, or design doc anywhere in toolchain/ or
> docs/design/. |

Closing the bullet also chips at two secondary bullets: "Goal: design docs
documented, cohesive, understandable without placeholders" (this area gets a
non-placeholder design doc) and the W8 arbiter's "build and run tests of most
C++ interoperability".

### The surprise: most of this bullet already works

Every other paper in this design sprint (error handling, unions, overloading,
if-let) covers a feature with **no design and no implementation**. This one is
different: the audit's "no *dedicated* support" is literally true — there is
no threading-specific code in `toolchain/` — but the *general* interop
machinery (embedded Clang, template import, `ref` parameters, synthesized
`Destroy` impls, single-LLVM-module lowering) turns out to already carry
almost the entire bullet. This paper is grounded in a fresh empirical run, not
just code reading: every claim below was compiled, linked, **and executed**
against the arbiter toolchain (nightly `2026.07.19`, per decision F-004) on
2026-07-19.

What is actually missing is (a) the **design doc** stating the memory-model
contract for mixed TUs, (b) fixes for **three specific defects** found by the
experiments, and (c) **conformance programs** so the scoreboard can arbitrate
the bullet. The options below differ mainly in how much of (b) is in scope.

### Measured state of the toolchain (2026-07-19)

Verified working end-to-end (compile → link → run, correct output):

| # | Capability | Evidence (form used) |
| --- | --- | --- |
| 1 | `import Cpp library "<atomic>"` / `"<mutex>"` / `"<thread>"` / `"<shared_mutex>"` / `"<condition_variable>"` / `"<chrono>"` | Headers come from the libc++ tree bundled with the toolchain runtimes (`toolchain/driver/clang_runtimes.cpp:269`) |
| 2 | `var a: Cpp.std.atomic(i32)` (local); `.store(41)`, `.fetch_add(1)`, `.load()` | printed `42` |
| 3 | Explicit orders: `a.store(1, Cpp.std.memory_order_release)`, `a.load(Cpp.std.memory_order_acquire)`; the `memory_order_*` constants import as ordinary enum constants | ran |
| 4 | `a.compare_exchange_strong(ref expected, 7)`, `a.exchange(9)` — C++ `T&` parameters take Carbon `ref` arguments (p005434 / `toolchain/lower/testdata/interop/cpp/reference.carbon`) | ran |
| 5 | Operator sugar: `a = 5` (atomic `operator=`), `var v: i32 = a` (`operator T` implicit conversion), `a += 2` (`operator+=`) | printed `7` |
| 6 | `Cpp.std.atomic_flag` `test_and_set`/`clear`; `atomic(bool)`; `atomic(i32*)` storing/loading a Carbon `&x`; `atomic(f64)` | ran |
| 7 | `Cpp.std.mutex` / `recursive_mutex` / `shared_mutex` / `condition_variable` locals; `lock`/`unlock`/`try_lock`/`lock_shared`/`notify_one`/`notify_all` | ran |
| 8 | **RAII across the boundary**: `var g: Cpp.std.lock_guard(Cpp.std.mutex) = Cpp.std.lock_guard(Cpp.std.mutex).lock_guard(ref m);` — mutex verifiably held while `g` lives, released when the Carbon scope ends (C++ destructor runs via the synthesized `Destroy` impl) | `try_lock` probes printed `1` then `2` |
| 9 | **Full producer/consumer**: C++ inline globals (`inline std::mutex m; inline std::condition_variable cv; inline int ready;`) accessed from Carbon as `Cpp.m`/`Cpp.cv`/`Cpp.ready`; Carbon takes `unique_lock`, loops on `Cpp.cv.wait(ref ul)`; a worker thread — `std::thread(Carbon::Worker).detach()` in inline C++, reverse interop per `check/cpp/export.cpp` — locks, writes, notifies | printed `1`, exited 0 |
| 10 | **A Carbon function runs on a foreign thread** and synchronizes with the main thread through a release/acquire `std::atomic` pair | printed `7`, `1` |
| 11 | `Cpp.std.this_thread.yield()`, `sleep_for(Cpp.std.chrono.milliseconds.duration(10))` (note: ctor is named `duration` through the alias), `Cpp.std.thread.hardware_concurrency()` | ran |
| 12 | C++ `thread_local` inline globals read/written from Carbon (`Cpp.tls_counter`) | printed `42` |
| 13 | C++20 surface with `--clang-arg=-std=c++20`: `std::jthread` visible, `a.notify_all()`, `atomic_thread_fence`/`atomic_signal_fence` | ran |
| 14 | File-scope Carbon `var gm: Cpp.std.mutex;` and globals of plain imported structs | ran |

Verified **broken** (the three defects):

| # | Defect | Failure mode |
| --- | --- | --- |
| D1 | `Cpp.std.thread.thread(Work)` with a Carbon function as the callable | check error: `` call argument of type `<type of Work>` is not supported `` — there is no Carbon-function-value → C++-callable mapping in `check/cpp/type_mapping.cpp` / `overload_resolution.cpp` |
| D2 | `Cpp.std.atomic(P)` over a Carbon class `P` | the template *instantiates* on the Carbon type (export works), but libc++'s `static_assert(is_trivially_copyable<Carbon::P>)` fires: `check/cpp/export.cpp` does not mark exported Carbon classes trivially copyable even when they are |
| D3 | File-scope Carbon `var gcount: Cpp.std.atomic(i32);` | compiles, but **links** with `undefined symbol: _Cgcount.Main.1` — global emission for variables whose type is an imported C++ *template specialization* loses the definition (plain imported classes like `std::mutex` are fine, so this is specific to specialization-typed globals in `toolchain/lower/` file-level lowering) |

Workarounds for all three exist today and are pure user-code: spawn via an
inline-C++ bridge that calls back through `Carbon::` (D1), keep shared state
in C++-defined inline globals accessed as `Cpp.name` (D3), and use C++ structs
for atomic payloads (D2). The producer/consumer program above uses exactly
these patterns.

## Constraints

### Design-principle constraints

-   **The memory model is already decided in principle.** Accepted proposal
    p000175 ("C++ interoperability goals", now
    `docs/design/interoperability/philosophy_and_goals.md:217-221`):
    "It must be straightforward for any Carbon interoperability code to be
    compatible with the C++ memory model. This does not mean that Carbon must
    exclusively use the C++ memory model, only that it must be supported."
    `docs/design/README.md:3434-3435` goes further: "C++ and Carbon will use
    the same memory model", and `docs/project/faq.md:471-476`: "Carbon will
    match C++'s memory model closely in order to maintain zero-overhead
    interoperability." Any 0.1 option that is not "adopt the C++ memory model"
    contradicts accepted design.
-   **Data-race safety is explicitly not a 0.1 problem.**
    `docs/design/safety/README.md:136` (via p005914) plans *compile-time*
    data-race enforcement as part of safe Carbon (0.2+), and
    `safety/README.md:154-177` reserves the option of tolerating pure data
    races that are not also temporal-safety bugs. The 0.1 doc must therefore
    say "races are UB, no static protection yet" without foreclosing the 0.2
    design. `safety/README.md:245` names Debug+ThreadSanitizer as the planned
    dynamic mitigation.
-   **Performance goals** (`docs/project/goals.md`,
    "Performance-critical software"): no wrappers that add locks, allocation,
    or virtual dispatch around atomics; zero-overhead is the bar the FAQ sets
    for the memory model specifically.
-   **Minimize bridge code** (`philosophy_and_goals.md`): the D1 workaround
    (hand-written inline-C++ spawn bridges) is tolerated, not blessed — the
    principle pushes toward eventually fixing it.

### Interop constraints from the milestone

-   The bullet is *interop support*, not language features; native threading
    is 0.2 (`milestones.md:271`). Options must not smuggle in Carbon-native
    concurrency design.
-   The W8 arbiter (`fork/gap-analysis.md`) requires *executed* interop tests;
    per `fork/process.md` standing rule 2, this bullet flips only when
    conformance programs under `fork/conformance/programs/interop/` PASS.
-   Exception configuration is a sibling bullet (`milestones.md:178-183`):
    `std::thread`/`std::mutex` APIs can throw (`std::system_error`), so this
    area's conformance programs must stay off throwing paths until the
    error-handling paper's choice lands (see Dependencies).

### Implementation realities in this toolchain

-   **One `llvm::Module` per mixed file.** Carbon lowering builds its module
    *from* the Clang `CodeGenerator`'s module when C++ is imported
    (`toolchain/lower/context.cpp:37-47`, `toolchain/lower/lower.cpp:26`,
    `toolchain/lower/file_context.cpp:67`). Clang-generated and
    Carbon-generated IR share one module, one pass pipeline, one target — so
    the C++11 atomics semantics LLVM IR implements apply uniformly. This is
    the load-bearing fact for the memory-model story.
-   The checker embeds a real Clang (`toolchain/check/cpp/`, ~10k lines);
    template import is spelled `Cpp.std.atomic(i32)` and instantiates through
    Clang Sema (`check/testdata/interop/cpp/template/class_template.carbon`),
    with overload resolution, default arguments (`memory_order` defaults come
    through), thunks (`check/cpp/thunk.cpp`,
    `toolchain/docs/check/cpp/thunks.md`), and reverse interop
    (`check/cpp/export.cpp`).
-   The C++ language mode is Clang's default unless the user passes
    `--clang-arg=-std=c++20` (the pattern used across
    `check/testdata/interop/cpp/`); C++20-only surface (`jthread`,
    `atomic::wait/notify`, `atomic_ref`) is gated on that flag.
-   `carbon link` builds and links libc++/compiler-rt runtimes on demand
    (`toolchain/driver/clang_runtimes.cpp`); pthread linkage needed by
    `std::thread` already works on the supported glibc targets (verified by
    execution, not assumed).
-   The fork's conformance runner (`fork/conformance/runner.py`) executes
    programs with a 30s timeout and exact-stdout matching — multithreaded
    conformance programs must be written to have deterministic output
    (join-before-print, ordered prints only on the main thread).

## The memory-model contract every option must state

All four options share one deliverable: a new
`docs/design/interoperability/threads_and_atomics.md` (slotting into the
interop README's TOC, which currently has ~10 `TODO:` sections but none for
threading). Its normative content, which the user is signing off on with any
option:

1.  **Carbon 0.1 adopts the C++ memory model unchanged** (C++20
    [intro.races], [atomics.order]), per p000175 /
    `philosophy_and_goals.md:217-221` and `faq.md:471`.
2.  **Ordinary Carbon accesses are C++ non-atomic accesses.** Two conflicting
    accesses from different threads, at least one a write and not both
    atomic, are a data race and undefined behavior — exactly C++'s rule.
    0.1 provides no compile-time race detection; that is the 0.2+ safe-Carbon
    design (`safety/README.md:136,154-177`). Dynamic detection is
    Debug+TSan (`safety/README.md:245`).
3.  **Atomicity is a property of the object's type**, obtained exclusively via
    imported C++ types (`Cpp.std.atomic(T)`, `Cpp.std.atomic_flag`,
    `Cpp.std.atomic_ref(T)` under C++20). Carbon adds no per-access atomic
    syntax in 0.1 and has no `volatile`.
4.  **Synchronization operations compose across the language boundary.** A
    happens-before edge established by a C++ atomic/mutex operation orders
    Carbon accesses exactly as it orders C++ accesses. Mechanism guarantee:
    mixed files lower into a single `llvm::Module`
    (`lower/context.cpp:37-47`); separately compiled TUs interoperate through
    the target's C++ ABI and the same LLVM atomics lowering, including under
    the mixed-toolchain mode promised by
    `philosophy_and_goals.md` ("Support mixing Carbon and C++ toolchains").
5.  **Any thread may run Carbon code.** Carbon functions are ordinary native
    functions with no runtime TLS or main-thread assumptions; running them on
    `std::thread`s, thread pools, or foreign runtimes is defined (empirically
    exercised: rows 9-10 above). C++ `thread_local` variables are usable from
    Carbon (row 12); Carbon has no native thread-local storage class in 0.1.
6.  **RAII interop is part of the contract**: C++ destructors of guard types
    run at Carbon scope exit (row 8), so `lock_guard`/`unique_lock` idioms
    are the blessed locking style.
7.  Non-goals for 0.1, stated to prevent scope creep: Carbon-native threads /
    atomics / async (0.2+, `milestones.md:266-277`), signal-handler
    guarantees, `_Atomic` C interop, and exception behavior of threading APIs
    (deferred to the exception-interop design).

## Options

### Option A: Document-and-conform — adopt the C++ memory model, fix nothing

**Design sketch.** Ship the design doc above, verbatim workaround patterns
included, and conformance programs that exercise only the working surface.
Idiomatic 0.1 threading code looks like:

```carbon
import Cpp library "<atomic>";
import Cpp library "<mutex>";
import Cpp library "<thread>";

// Shared state lives on the C++ side of the file (defect D3 workaround).
fn Work();
inline Cpp '''
inline std::atomic<int> counter{0};
inline void SpawnAndJoinWorkers(int n) {
  std::vector<std::thread> ts;
  for (int i = 0; i < n; ++i) ts.emplace_back([] { Carbon::Work(); });
  for (auto& t : ts) t.join();
}
''';

fn Work() { Cpp.counter.fetch_add(1, Cpp.std.memory_order_relaxed); }

fn Run() -> i32 {
  Cpp.SpawnAndJoinWorkers(4);
  var m: Cpp.std.mutex;
  var g: Cpp.std.lock_guard(Cpp.std.mutex)
      = Cpp.std.lock_guard(Cpp.std.mutex).lock_guard(ref m);
  return if Cpp.counter.load() == 4 then 0 else 1;
}
```

**C++ interop story.** Everything *is* C++ interop; nothing new is imported
or exported. The doc documents D1-D3 as "known limitations" with the bridge
patterns as the supported idiom.

**Implementation cost: S.** One design doc (~300 lines); 5-6 conformance
programs under `fork/conformance/programs/interop/` (atomic RMW + orders;
mutex/lock_guard RAII; condvar producer/consumer; thread-runs-Carbon-fn;
thread_local; racing-counter with N threads summing to an exact total). Zero
toolchain changes — nothing in `toolchain/` is touched.

**Evolution risk vs upstream: minimal.** Upstream has no competing doc (no
proposal in `proposals/` touches threading; web search finds only the FAQ
line), and the doc restates what p000175 already committed to. The risk is
*milestone-lawyering*: an evaluator who writes
`var t: Cpp.std.thread = ...(callback)` or a global atomic hits D1/D3 and may
reasonably say the bullet's "support" is not met. The scoreboard would go
green while the ergonomic floor stays low.

### Option B: Option A + targeted toolchain fixes for the three verified defects

Everything in A, plus fix D1-D3 so the *obvious* spellings work.

**Design sketch.** The doc's "limitations" section shrinks to notes; these
become legal:

```carbon
import Cpp library "<atomic>";
import Cpp library "<thread>";

var total: Cpp.std.atomic(i64);            // D3 fixed: specialization-typed global

class Vec2 { var x: f32; var y: f32; }     // trivially copyable Carbon class

fn Producer() { total += 1; }

fn Run() -> i32 {
  var last: Cpp.std.atomic(Vec2);          // D2 fixed: atomic over Carbon type
  var t: Cpp.std.thread
      = Cpp.std.thread.thread(Producer);   // D1 fixed: Carbon fn as callable
  t.join();
  return (total.load() - 1) as i32;
}
```

**C++ interop story.**

-   D1: map a *concrete, non-generic* Carbon function value to a C++ function
    pointer whose pointee signature is the function's exported thunk-free C++
    signature; reuse the reverse-interop machinery that already synthesizes
    `Carbon::F` `FunctionDecl`s (`check/cpp/export.cpp`) and let Clang Sema
    resolve the ctor template on `void(*)()`. Generic/deduced-parameter
    functions stay unsupported with today's diagnostic.
-   D2: when exporting a Carbon class whose members are all trivially
    copyable and which uses the default `Copy`/`Destroy`, mark the synthesized
    `CXXRecordDecl`'s special members trivial so `is_trivially_copyable`
    holds. (The instantiation side already works — the static_assert is the
    only blocker.)
-   D3: emit definitions for file-scope globals whose type is an imported C++
    template specialization. The repro (`_Cgcount.Main.1` undefined at link,
    while `std::mutex`-typed and plain-struct-typed globals link fine)
    localizes the bug to the file-level lowering path for specialization
    types; root-cause work starts in `toolchain/lower/file_context.cpp`
    global emission plus the C++ `custom global` handling in
    `toolchain/lower/testdata/interop/cpp/globals.carbon`'s covered path.

**Implementation cost: M overall.**

-   D2: **S** — `toolchain/check/cpp/export.cpp` (predicate over the Carbon
    class's fields + synthesized-impl triviality) plus one check testdata
    file mirroring `check/testdata/interop/cpp/class/`.
-   D3: **S-M** — `toolchain/lower/file_context.cpp` / `constant.cpp` (global
    emission), likely a mangling/`specific` interaction; regression test in
    `lower/testdata/interop/cpp/globals.carbon` + an execution conformance
    program.
-   D1: **M** — `toolchain/check/cpp/type_mapping.cpp` (new Carbon-fn-type →
    C++ function-pointer mapping), `check/cpp/overload_resolution.cpp`
    (argument conversion), `check/cpp/thunk.cpp`/`export.cpp` (guarantee a
    C-ABI symbol for the callee); this is the riskiest fix because signature
    ABI compatibility must be checked, not assumed.

All three are fork-local patches to the *fork-built* toolchain (decision
F-005 gives us the build runner); each is small enough to also send upstream.

**Evolution risk vs upstream: low, and convergent.** All three fixes make
existing general interop machinery more complete — no new syntax, no new
semantics beyond what upstream's own machinery implies. Upstream is highly
likely to want each fix (D1 in particular matches
"minimize bridge code"); upstream landing a different D1 (e.g. via their
lambda work, p003848) would supersede rather than conflict with ours.

### Option C: Option B + a `Core.Sync` veneer library

Everything in B, plus a small Carbon library so evaluator-facing code doesn't
spell `Cpp.std` for the common 90%.

**Design sketch.**

```carbon
// core/sync.carbon (new), all zero-overhead adapters over Cpp.std:
import Core library "sync";

var counter: Core.AtomicI32;               // adapter for Cpp.std.atomic(i32)

fn Run() -> i32 {
  counter.FetchAdd(1, Core.MemoryOrder.Relaxed);
  var m: Core.Mutex;
  var g: Core.LockGuard = Core.LockGuard.Make(ref m);   // RAII as in B
  var t: Core.Thread = Core.Thread.Spawn(SomeFn);       // needs B's D1 fix
  t.Join();
  return counter.Load() - 1;
}
```

`Core.AtomicI32`/`Core.Mutex` are `adapt`-style wrappers (the pattern
`core/prelude/types/cpp/` already uses for `CppCompat` integer adapters);
`Core.MemoryOrder` is a Carbon `choice` mapping 1:1 to `std::memory_order`.

**C++ interop story.** Pure sugar over B; every operation still bottoms out
in the imported libc++ entities, so the memory-model contract is unchanged
and C++ code sees the same `std::` objects (a `Core.Mutex*` is convertible to
`std::mutex*` for bridge APIs).

**Implementation cost: M+.** B's cost, plus a new `core/sync.carbon` (~200-400
lines) with execution tests. No compiler changes beyond B, *but*: `core/`
currently has no dedicated unit-test suite (gap-analysis, stdlib area
summary), `Core.Sync` would be the first Core library whose implementation
imports `Cpp` — a build-graph novelty (`core/BUILD` currently compiles the
prelude without Clang; wiring `import Cpp` into prelude compilation touches
`toolchain/check/` driver defaults) — and naming/API choices here are
*Carbon-native library design*, which the milestone deliberately deferred.

**Evolution risk vs upstream: moderate.** Upstream will design native
threading for 0.2 with committee-level care (async, effects, and data-race
safety interactions are all named in `milestones.md:266-277` and
p005233's discussion of async directions); any names we pick
(`Core.Thread.Spawn`, `Core.MemoryOrder`) will likely be replaced. The veneer
is deletable (library-only), but every conformance program written against it
would need rewriting when upstream's design lands — so it should never be
what the conformance suite tests.

### Option D: Carbon-native atomics lowered directly to LLVM

For completeness: add language-level atomics now — a
`Core.Atomic(T)` builtin backed by new SemIR insts lowering to LLVM
`atomicrmw`/`cmpxchg`/fence, Rust-`std::sync::atomic`-style.

**Design sketch.**

```carbon
var flag: Core.Atomic(bool);
fn Signal() { flag.Store(true, Core.MemoryOrder.Release); }
fn Wait() { while (not flag.Load(Core.MemoryOrder.Acquire)) {} }
```

**C++ interop story.** Would need an ABI-compatibility rule making
`Core.Atomic(T)` layout-identical to `std::atomic<T>` (as Rust's
`AtomicU32`/C++ interop does informally) so the two sides can share objects —
an extra design axis C++ interop alone doesn't have.

**Implementation cost: XL.** New builtins in `toolchain/check/` +
`toolchain/sem_ir/` (inst kinds, typed insts, formatter/coverage tests per
the fork rulebook direction), new lowering in `toolchain/lower/handle_*.cpp`,
prelude API in `core/prelude/`, plus the design doc. Touches every layer the
way variadics (W6) does.

**Evolution risk vs upstream: high — and it violates the milestone's own
scoping.** `milestones.md:271` defers native threading precisely so 0.1
doesn't need this; upstream's eventual native design will be entangled with
effects/async (p005233) and data-race safety (p005914) in ways we'd guess
wrong today. Rejected unless the user wants to pull 0.2 work forward.

## Recommendation

**Option B.** Rationale:

1.  **The bullet's substance is already delivered by general interop**; the
    measured matrix shows atomics (including orders, CAS, operator sugar),
    all four mutex types, condition variables, RAII guards, thread_local, and
    Carbon-code-on-foreign-threads all working today. What separates
    "technically arbitrable" (A) from "honestly closed" (B) is exactly the
    three defects an evaluator will hit in their first hour:
    `std::thread(carbon_fn)`, a global atomic counter, and
    `std::atomic<MyType>`. All three have small, convergent, upstreamable
    fixes.
2.  **The memory-model question is not actually open** — p000175, the FAQ,
    and `docs/design/README.md` all commit to the C++ memory model, and the
    single-`llvm::Module` lowering architecture makes it true by
    construction. The design doc writes down what the toolchain already does,
    which is the cheapest kind of design doc to keep cohesive.
3.  **A is too little** (documents around holes rather than closing them; the
    workaround idioms would calcify into evaluator-visible warts), **C adds
    upstream-divergence risk for sugar** (and quietly starts the 0.2
    native-threading design a year early via naming decisions), **D is
    scope-violating**.
4.  Sequencing within B: land the doc + conformance programs first (they
    arbitrate A-level function immediately and are pure fork assets), then
    D2 (S), D3 (S-M), D1 (M) as separate child branches per F-002 merge
    gating. If D1 proves deeper than M (ABI checking), it can degrade to a
    documented limitation without reopening the doc — the bridge pattern
    remains supported either way.

## Dependencies on other workstreams

-   **W1 conformance harness** (done): the runner exists; this area adds the
    first *multithreaded* execution programs, which must be written for
    deterministic stdout (join-then-print) under the runner's exact-match
    rule and 30s timeout (`fork/conformance/runner.py`).
-   **W2 sibling: error handling / exception interop**
    (`fork/design-sprint/error-handling.md`): `std::thread` construction,
    `mutex::lock`, and `condition_variable` methods can throw
    `std::system_error`. Until the exception-interop configuration lands
    (`milestones.md:178-183`), this area's doc must declare throwing paths
    out of contract and conformance programs must avoid them. Whatever
    `-fno-except`-vs-exceptions default that paper picks becomes this doc's
    stated environment.
-   **W3 safe-Carbon design**: the 0.2 data-race-safety design (p005914's
    provisional Ante-style shared-mutation direction) will layer a type
    system over exactly the model this doc freezes; the doc must keep its
    "races are UB" wording forward-compatible (it describes 0.1 *Permissive*
    Carbon, not the eventual Strict mode).
-   **W8 interop frontier**: D1/D2/D3 fixes live in the same files W8 will
    churn (`check/cpp/export.cpp`, `type_mapping.cpp`, lower globals);
    coordinate branch ordering. D2 is also a direct prerequisite quality-fix
    for W8's "C++ templates instantiated on Carbon types" arbiter line.
-   **F-005 fork toolchain builds**: A needs no toolchain build; B's three
    fixes are the first compiler patches this fork ships through the
    self-hosted runner + full-test-suite merge gate.
-   **Upstream watch** (standing rule 5): upstream's lambda implementation
    (p003848 accepted) would give C++ callables a second, better mapping for
    D1; check for movement before starting that fix.

## Open questions for the user (beyond option choice)

1.  **C++ language mode for the contract.** Pin the conformance suite (and
    the doc's examples) to `--clang-arg=-std=c++20` — gaining `jthread`,
    `atomic::wait/notify`, `atomic_ref` — or track Clang's default and mark
    C++20 surface "works with flag"? (Recommend: pin C++20 in conformance,
    document the flag.)
2.  **Upstreaming policy for the D1-D3 patches.** They are generic interop
    fixes with no fork-specific design content; sending them upstream reduces
    permanent merge burden (rule 5) but costs review latency. Ship
    fork-first, upstream-second?
3.  **How hard to arbitrate "memory model" itself.** Beyond
    functional programs, do we want a stress conformance program (N threads ×
    M relaxed increments == N*M; message-passing with release/acquire) and/or
    a TSan-mode run (`safety/README.md:245`) in the scoreboard, accepting
    that scheduling-dependent tests can flake in a 4-core container?
4.  **Is D1 (Carbon fn → C++ callable) 0.1-blocking or a stretch?** It is
    the biggest ergonomic gap but has a clean workaround; deferring it
    shrinks B to two S-sized fixes.
5.  **Naming reservation.** Even without Option C, should the doc reserve
    `Core.Thread`/`Core.Atomic`/`Core.MemoryOrder` names for 0.2 so
    evaluators don't squat them? (Cheap now, awkward later.)
6.  **`volatile` and C `_Atomic`.** Both are currently outside the contract
    (Carbon has no `volatile`; `_Atomic` untested). Explicit non-goals in the
    doc, or does C-header interop (`<stdatomic.h>` consumers) matter to the
    evaluation story?

## References

-   `docs/project/milestones.md:176-177,266-277` — the bullet and the 0.2
    deferral
-   `docs/design/interoperability/philosophy_and_goals.md:217-221` (p000175)
    — C++ memory-model compatibility goal
-   `docs/project/faq.md:471-476`; `docs/design/README.md:3430-3435` — same
    memory model, zero overhead
-   `docs/design/safety/README.md:136,154-177,245` (p005914) — data-race
    safety is 0.2+, TSan build mode
-   `toolchain/lower/context.cpp:37-47`, `toolchain/lower/lower.cpp:26`,
    `toolchain/lower/file_context.cpp:67` — Clang and Carbon share one
    `llvm::Module`
-   `toolchain/check/cpp/` (`import.cpp`, `export.cpp`, `type_mapping.cpp`,
    `overload_resolution.cpp`, `thunk.cpp`) — the machinery the options
    build on; `toolchain/docs/check/cpp/thunks.md`
-   `toolchain/check/testdata/interop/cpp/template/class_template.carbon` —
    template import form; `toolchain/lower/testdata/interop/cpp/reference.carbon`
    — `ref` arguments to C++ `T&` (p005434)
-   `toolchain/driver/clang_runtimes.cpp` — bundled libc++/runtimes
-   proposals p000175, p005914, p005434, p006357, p006358, p006177, p003848,
    p005233
-   Prior art: Rust `std::sync::atomic` (C++-model adoption in a second
    language), Swift's C interop atomics story and `Atomics` package, Zig
    `std.atomic` (LLVM-model native atomics — the Option D shape)
-   Empirical run: nightly toolchain `2026.07.19` (decision F-004), programs
    in this session's scratchpad; every "ran"/"printed" claim in the measured
    matrix was executed on 2026-07-19
