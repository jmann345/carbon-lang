# Reading list for the open design forks

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

Curated background so the human decider can evaluate the option papers
and steer the agents. Per fork: the in-repository sources first (highest
authority for this project), then the shortest external material that
teaches the concept. Times are honest estimates.

## Background for all forks (once, ~2-3 h)

-   `docs/project/goals.md` — Carbon's priorities; every design argument in
    the papers appeals to these (30 min).
-   `docs/design/README.md` — the language overview; skim to know what
    exists (45 min).
-   `toolchain/docs/adding_features.md` and `toolchain/docs/check.md` — how
    a feature physically flows lex→parse→check(SemIR)→lower; this is the
    vocabulary the cost estimates use (45 min).
-   Optional deeper: "Crafting Interpreters" (craftinginterpreters.com)
    chapters on parsing + static analysis if compiler pipelines are new to
    you; LLVM's Kaleidoscope tutorial for what "lowering to IR" means.

## F-006 Error handling (~2 h)

-   `proposals/p000301.md` — the accepted principle: errors are values, no
    implicit propagation; the fork must fit inside or consciously exit it.
-   Rust Book ch. 9 ("Error Handling") — the Result/`?` model the
    recommendation mirrors.
-   C++ `std::expected` proposal P0323 (wg21.link/p0323) — the shape Carbon
    errors would export as.
-   Herb Sutter's P0709 "Zero-overhead deterministic exceptions"
    (wg21.link/p0709) — the strongest argument for declared fallibility
    (option C) and why value-based errors won in modern designs.
-   Skim: Swift Error Handling Rationale (github.com/swiftlang/swift,
    docs/ErrorHandlingRationale) — the best survey of the whole design
    space (typed throws, unwinding vs values).
-   Concept to understand: **unwinding versus return-value propagation**, and
    why crossing an FFI boundary while unwinding is UB — this is the entire
    B0 stage.

## F-007 Unions (~1 h)

-   `proposals/p000157.md` — upstream's accepted direction that left
    "typed union vs storage primitive" open.
-   Rust Nomicon "Unions" + Rust Reference unions section — the
    writes-safe/reads-unsafe surface the recommendation copies.
-   cppreference "union" — especially anonymous unions and the
    common-initial-sequence rule; this is what C++ interop must round-trip.
-   Concept: **object representation versus active member**, and why
    discriminated `choice` and raw `union` are different layers.

## F-008 Threading/atomics interop (~1.5 h)

-   `docs/design/README.md` interop section + the paper's memory-model
    argument (shared llvm::Module ⇒ shared memory model).
-   Preshing, "An Introduction to Lock-Free Programming" and "Acquire and
    Release Semantics" (preshing.com) — the shortest good intro to memory
    orders.
-   Hans Boehm, "Threads Cannot Be Implemented As a Library" — why the
    memory model must be a _language_ property; explains what our design
    doc has to state.
-   Concept: **happens-before across a language boundary** — why "both
    languages compile to one LLVM module" closes most of this bullet.

## F-009 Function overloading (~1 h)

-   `proposals/p000998.md` (closed same-library sets) and `p002875.md`
    (declaration-order matching) — upstream's recorded lean; the
    recommendation is essentially "implement these".
-   cppreference "Overload resolution" — skim to appreciate what NOT to
    build (the ranking lattice first-match avoids).
-   Swift API Design Guidelines on overloading + Rust's deliberate absence
    of overloading (trait-based alternative) — the two poles.
-   Concept: **first-match vs best-match resolution**, and why best-match
    requires a conversion-ranking lattice that explodes in complexity.

## F-010 Template structural conformance (~1.5 h)

-   `docs/design/generics/terminology.md` — Carbon's checked-vs-template
    distinction; mandatory vocabulary.
-   `proposals/p000818.md` + `p002200.md` — the accepted `template
    constraint` design the recommendation implements.
-   C++20 concepts: cppreference "Constraints and concepts" + a skim of
    P0734 — what `require`-style validity predicates mean and what maps to
    C++ concepts in both directions.
-   Go FAQ on structural typing — the implicit-satisfaction pole (option A)
    and its costs.
-   Concept: **nominal vs structural conformance**, and **definition-checked
    vs instantiation-checked generics** — the entire integrated-templates
    bullet is about letting both coexist.

## F-011 if-let / let-else (~45 min)

-   `docs/design/pattern_matching.md` — Carbon's refutability taxonomy.
-   Rust RFC 160 (if-let) and RFC 3137 (let-else) — motivation and the
    exact semantics the recommendation adapts; note Rust's later regrets
    (if-let-chains) for evolution risk.
-   Swift `guard` documentation — the alternative negative-space spelling.
-   Concept: **refutable vs irrefutable patterns** and **divergence
    requirements** (why the `else` block must not fall through).

## Standing rule

Every future design fork presented for decision comes with a section like
these: in-repository authority first, then the minimum external reading that
makes the tradeoff legible, then the one concept to understand before
choosing.
