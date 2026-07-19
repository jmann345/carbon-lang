# Design sprint: six open design forks for Carbon 0.1

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

Status: **OPEN** — each paper below is an input to `fork/decision-log.md`;
per `fork/process.md`, the user decides. This README digests the six
papers, gives the dependency-sorted decision order, and records the
cross-cutting risks found by a coherence audit across all six.

## Area digests (in recommended decision order)

### 1. Error handling + C++ exception interop — [`error-handling.md`](error-handling.md)

Carbon has neither an error-handling design nor any exception
configuration: the embedded Clang compiles C++ with exceptions on while
Carbon frames have no unwind support, so a C++ exception crossing the
boundary is undefined behavior today and `Destroy` cleanups are silently
skipped. Options: **A** library-only `Core.Result` + `match`; **B**
Result + postfix `?` propagation via a `Core.Try` interface; **C**
declared-fallibility signatures (`fn F() -> T or E` with `try`/`catch`
sugar); **D** native exceptions on Itanium unwinding.
**Recommendation: Option B, staged** — B0 (size S, no dependencies,
land now): a `--cpp-exceptions={auto,none,catch}` driver flag plus
fenced (try/catch-terminate) thunks, replacing today's UB with a
documented contract; B1 (after W4 match + W5 choice payloads):
`Core.Result` in the prelude; B2: postfix `?` + `Core.Try`; B3:
catching thunks importing throwing C++ as `Result(T, Cpp.Exception)`
and a `Carbon::expected<T, E>` export header. It is the only option
closing all four milestone bullets inside upstream's written direction
(p000301 explicitly anticipates a Rust-`?`-like operator).

### 2. Un-discriminated unions + C++ union mapping — [`unions.md`](unions.md)

Carbon has no union design at all, but the audit found the expensive
half already exists: imported C++ unions get an overlapping-layout
representation (`SemIR::CustomLayoutType`) that lowers and is
golden-tested. Accepted upstream proposal p000157 requires a typed
union facility or a `Storage` primitive and left which one open.
Options: **A** native `union` declaration; **B** unsafe `Core.Storage`
primitive only; **C** C++-import-only (escape-hatch statement).
**Recommendation: Option A** — Rust-shaped safety surface (writes safe,
reads are byte reinterpretation, Strict-mode `unsafe` marking hook),
C++-compatible layout by construction, absorbing Option C's
import-construction fix and deferring Option B's `Storage` as future
work. Only option closing both 0.1 sub-bullets; it also settles the
overlapping-storage primitive that W5 choice payloads lower onto —
which the error-handling `Result` and if-let's `.Some` patterns
transitively depend on.

### 3. C++ threading/atomics/memory-model interop — [`threading-atomics.md`](threading-atomics.md)

Uniquely, this bullet is mostly already delivered by general interop
machinery — verified by compile-link-**run** experiments (atomics with
explicit orders, all four mutex types, condition variables, RAII lock
guards across the boundary, Carbon code on foreign threads). The memory
model is not actually open: accepted design commits to the C++ memory
model, and it is true by construction since Carbon lowers into the same
`llvm::Module` as Clang. Options: **A** document-and-conform (S); **B**
A + fix three verified defects (M); **C** B + `Core.Sync` veneer
library (M+); **D** Carbon-native atomics (XL, rejected).
**Recommendation: Option B** — the three defects
(`std::thread(carbon_fn)`, specialization-typed file-scope globals,
`std::atomic<CarbonClass>`) are exactly what an evaluator hits first,
and all three are small, convergent, upstreamable fixes. Sequence: doc
+ conformance programs first, then D2 (S), D3 (S-M), D1 (M). The doc's
stated exception environment comes from the error-handling decision.

### 4. Carbon-native function overloading — [`function-overloading.md`](function-overloading.md)

A second `fn F` with a different signature is a hard error today, while
imported C++ overload sets already resolve end-to-end through Clang
Sema. Upstream has unusually explicit recorded intent: closed,
same-library sets (p000998), declaration-order first-match (p002875,
pattern_matching.md), `overloaded fn` placeholder syntax. Options: **A**
marked closed overloading (`overload fn`, first-match); **B** unmarked
closed overloading; **C** pattern-dispatch overloading (value patterns);
**D** no native overloading in 0.1.
**Recommendation: Option A** — marked `overload fn`, closed
same-library sets, declaration-order first-match, no value patterns in
0.1, designed as the compile-time subset of Option C. Size L (first
match needs no ranking lattice; tentative-matching machinery is
half-built), matches every recorded upstream signal, preserves the
redeclaration-typo diagnostics contract, exports as ordinary C++
overload sets with a documented, conformance-tested divergence policy.
The first-match/no-subsumption rule established here is adopted by the
structural-conformance design.

### 5. Structural conformance for templates — [`structural-conformance.md`](structural-conformance.md)

The integrated-templates bullet requires template-style structural
conformance to nominal constraints — both member modeling ("like
interfaces") and arbitrary predicates ("like C++20 expression validity
predicates"). Nothing exists; `template constraint` does not even
parse, though it is accepted design (p000818, p002200). Options: **A**
implicit structural satisfaction of interfaces for template bindings;
**B** `template constraint` + `require` validity blocks; **C** boolean
compile-time predicates only.
**Recommendation: Option B, staged** — B1: `template constraint` +
member requirements (check-phase only, can start before the template
lowering fatal is fixed); B2: validity blocks + bool predicates via
probe-mode eval-block replay (absorbing Option C's `where <bool-expr>`
form); B3: two-way C++20 concept mapping (`ConceptDecl` export with a
`__carbon_satisfies` hook, landing with W8). Do not do Option A —
upstream deliberately keeps interfaces nominal. B implements accepted
proposals plus their explicitly named future work, and pays the one
irreducible new cost (probe-mode diagnostic capture) that every
predicate-supporting option needs anyway.

### 6. Combined match control flow (if-let / let-else) — [`if-let.md`](if-let.md)

The milestone names Rust's positive (`if let`) and negative
(`let else`) forms explicitly; nothing exists at any layer, though
accepted p002188 already reserves the let-else slot as a second
refutable-match context. All candidates share the same semantic core —
a refutable single-pattern match desugaring onto W4's machinery — so
the fork is mostly surface. Options: **A** `if (let ...)` conditions +
`let ... else` declarations; **B** `is` pattern-test expressions with
flow-scoped bindings; **C** Swift-shaped `guard let ... else`; **D** no
dedicated forms (`match` only).
**Recommendation: Option A** with two riders: (1) specify both forms as
desugarings onto W4's refutable-match SemIR (check delta M, lowering
zero); (2) record that if upstream #5101 lands a different surface, the
fork re-spells mechanically while keeping the shared semantics. It fits
the parser's introducer-keyword architecture with a single-token peek
and no lexer change; Option B's chaining advantage can be added later
as let-chains. Option C is the fallback if the user weighs the #5101
`guard` snippet heavily; B should be rejected on record; D fails the
milestone as written.

## Decision order (dependency-sorted)

Decide in this order; rationale for each edge follows.

1.  **Error handling** — the most constraining choice. Its option
    selection determines whether a `catch`-style construct exists (which
    would overlap if-let's territory under Option C), fixes the
    exception environment the threading contract must state, and its B0
    stage (exception-mode flag + fenced thunks) is S-sized with zero
    dependencies and should land immediately regardless.
2.  **Unions** — independent of every other *decision*, but it settles
    the overlapping-storage primitive that W5 choice payloads lower
    onto; W5 in turn gates error-handling B1 (`Result` as a payload
    choice) and if-let's motivating `.Some` examples. Deciding it second
    unblocks the longest implementation chain.
3.  **Threading/atomics** — fully unblocked once error handling picks
    the `--cpp-exceptions` default; otherwise independent and the
    smallest. Its D2 fix (trivially-copyable export marking) is also the
    first slice of the Carbon-type-into-Clang-AST machinery that
    structural conformance's interop stage shares.
4.  **Function overloading** — independent of 1-3 (Option A explicitly
    avoids the W4 dependency), but must be decided before structural
    conformance because the declaration-order/first-match,
    no-subsumption rule is jointly owned by both papers.
5.  **Structural conformance** — consumes the ordering rule from the
    overloading decision (constraints-as-overload-filters,
    no-subsumption) and shares W8 export machinery with threading's D2.
6.  **If-let / let-else** — consumes the error-handling decision (the
    diverging-else rule and the future `?` desugar target) and is
    hard-gated on W4 match implementation anyway, so deciding it last
    loses no calendar time.

Parallelism note: after decisions land, five tracks can proceed while
W4/W5 are built — error-handling B0, unions, threading (doc + D2/D3),
overloading stages 1-2, and structural-conformance B1 all have no W4/W5
dependency. Only error-handling B1+ and if-let wait on W4/W5.

## Cross-cutting risks (coherence audit findings)

1.  **The storage-primitive decision authority is split across papers.**
    Error-handling defers choice-payload storage to "W5, not here";
    the unions paper claims that same decision ("whatever primitive we
    pick here is what `choice` lowers onto"). The recommendations are
    compatible, but the decision chain must be made explicit:
    unions → W5 choice payloads → error-handling B1 / if-let examples.
    If unions were decided as Option C, W5 would build the storage
    machinery ad hoc and the chain breaks.
2.  **Two papers specify different desugar targets for `?`.**
    Error-handling desugars `expr?` onto a *match expression* (whose
    arms yield values — a form W4's statement-match deliverable may not
    include); if-let says a future `?`/`try` "would typically desugar to
    let-else". Both are semantically fine but W4's scope must be pinned
    to a single shared refutable-match SemIR core that both desugar
    onto, or W4 gets specified twice.
3.  **The "diverging else" / noreturn rule has no owner.** If-let ships
    a syntactic divergence list (`return`/`break`/`continue`) for 0.1
    and defers a noreturn-type rule "to the error-handling design" —
    but the error-handling paper never claims that deliverable (its
    panic/abort split is itself deferred to the safety workstream).
    Assign an owner explicitly or `else { Abort(); }` stays rejected
    indefinitely.
4.  **Overload resolution and constraint satisfaction need one shared
    speculative-checking subsystem.** Overloading's candidate loop
    (arity → tentative deduction → non-diagnosing conversions) does not
    include a constraint-satisfaction step; once `template constraint`
    exists, a constrained candidate's "match" must include
    non-diagnosing satisfaction probing — the same probe-mode machinery
    structural conformance's B2 builds. Neither paper budgets the
    other's requirement; spec the probe/`diagnose=false` subsystem once
    and have both consume it.
5.  **`check/cpp/export.cpp` (and `thunk.cpp`/`type_mapping.cpp`) is a
    five-way contention point.** Error-handling B3 (expected mapping +
    catching thunks), unions export, overloading set export, threading
    D1/D2, and structural-conformance B3 (`ConceptDecl` +
    `__carbon_satisfies`) all land in the same files that W8 also
    extends. Each paper says "coordinate with W8"; no single owner or
    branch ordering exists. Risk: serialized rebases or conflicting
    refactors — W8 should publish a refactor-first plan before any two
    of these start concurrently.
6.  **Threading's contract text can strengthen once B0 lands.** The
    threading paper declares throwing paths "out of contract" pending
    the exception decision; with error-handling B0's fenced thunks, a
    `std::system_error` from `std::thread`/`mutex` becomes a *defined
    terminate at the boundary* — a strictly stronger statement neither
    paper currently makes. The threading doc should be written against
    B0's semantics, and the `--cpp-exceptions` default (open question 3
    in error-handling) must be decided before the threading doc freezes.
7.  **"Trivially copyable" needs one definition.** Threading D2 (mark
    exported Carbon classes trivially copyable), unions' 0.1 field
    restriction (trivially copyable + destructible fields), and the
    `Carbon::expected` export all need the same predicate over Carbon
    classes — which no design doc currently defines. Define it once
    (likely in the unions or D2 work, whichever lands first) and reuse.
8.  **Carbon-type-export-into-Clang-AST is a shared blocker with a
    cheap first slice.** Structural conformance's concept-satisfaction
    import for Carbon types, `std::atomic<CarbonClass>` (threading D2),
    and gap row 38 (C++ templates on Carbon types) are the same
    machinery; threading D2 is the smallest entry point and should land
    first so the others inherit it.
9.  **Nobody owns `Optional`'s redesign.** Error-handling gives
    `Optional` a `Try` impl and if-let's flagship examples pattern-match
    `.Some(x: T)`, but the prelude `Optional` is a self-described
    placeholder and no paper claims rebuilding it as a payload choice.
    Fold it into W5's deliverables explicitly.
10. **The refutable-context taxonomy spans three papers.** p002188's
    "contexts permitting refutable patterns" list is extended by if-let
    (let-else as context two) and referenced by overloading (overloads
    as anticipated context three, though Option A excludes refutable
    patterns in 0.1). The design-doc amendment to
    `docs/design/pattern_matching.md:670-676` (if-let's deliverable)
    should enumerate all three contexts so the fork's docs stay
    coherent with both decisions.
