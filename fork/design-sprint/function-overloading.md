# Design option paper: Carbon-native function overloading

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Problem statement](#problem-statement)
    -   [0.1 milestone bullets this area closes](#01-milestone-bullets-this-area-closes)
-   [Constraints](#constraints)
    -   [Design-principle constraints (upstream is unusually explicit here)](#design-principle-constraints-upstream-is-unusually-explicit-here)
    -   [Interop constraints from the milestone](#interop-constraints-from-the-milestone)
    -   [Implementation realities in this toolchain](#implementation-realities-in-this-toolchain)
-   [Prior art](#prior-art)
-   [Options](#options)
    -   [Option A: Marked closed overloading — `overload fn`, declaration-order first-match](#option-a-marked-closed-overloading-—-overload-fn-declaration-order-first-match)
    -   [Option B: Unmarked closed overloading (C++/Swift surface, Carbon resolution)](#option-b-unmarked-closed-overloading-cswift-surface-carbon-resolution)
    -   [Option C: Pattern-dispatch overloading (value patterns as overloads)](#option-c-pattern-dispatch-overloading-value-patterns-as-overloads)
    -   [Option D: No Carbon-native overloading in 0.1 (Rust/Zig discipline)](#option-d-no-carbon-native-overloading-in-01-rustzig-discipline)
-   [Recommendation](#recommendation)
-   [Dependencies on other workstreams](#dependencies-on-other-workstreams)
-   [Open questions for the user (beyond option choice)](#open-questions-for-the-user-beyond-option-choice)
-   [References](#references)

<!-- tocstop -->

## Problem statement

Carbon 0.1 requires function overloading declared in Carbon itself. Today the
fork (== upstream trunk `99cda60`) has the C++ _import_ half fully working and
the Carbon-native half entirely absent:

-   `docs/design/pattern_matching.md:696`: "We do not yet have an approved
    design for overloaded functions, but it is anticipated that declaration
    order will be used in that case too."
-   `docs/design/README.md:3822` has a placeholder section "Pattern matching
    as function overload resolution" whose entire body is a TODO.
-   In the toolchain, declaring `fn F(n: i32);` followed by `fn F(x: f64);`
    is a hard error today: either "duplicate name"
    (`toolchain/check/handle_function.cpp:250` →
    `DiagnoseDuplicateName`) or "redeclaration differs at parameter N"
    (`toolchain/check/merge.cpp:218`, `RedeclParamDiffers`). Name lookup
    binds one instruction per name per scope
    (`toolchain/check/decl_name_stack.cpp:188-193`).
-   By contrast, **imported C++ overload sets already work end-to-end**: the
    checker stores a `SemIR::CppOverloadSet`
    (`toolchain/sem_ir/cpp_overload_set.h:22`) holding a Clang
    `UnresolvedSet` of candidates, and calls dispatch through real Clang Sema
    overload resolution
    (`toolchain/check/cpp/overload_resolution.cpp`, 357 lines;
    `PerformCppOverloadResolution`), including default arguments and
    literal-driven resolution
    (`toolchain/check/testdata/interop/cpp/function/import/overloads.carbon`).

So the gap is precisely the `MISSING` row in `fork/gap-analysis.md` line 42:
Carbon-side overload _declaration_ and _resolution_, plus exporting such sets
to C++.

### 0.1 milestone bullets this area closes

From `docs/project/milestones.md` ("Functions", lines 154-164):

-   **"Function overloading"** (line 156) — the primary target; currently
    MISSING, no design and no implementation.
-   **"Exporting Carbon functions and methods and calling them from C++"**
    (line 159) — DONE for single functions
    (`toolchain/check/cpp/export.cpp`, 1202 lines); this area extends it to
    overload _sets_, which is implied by parity ("callable from C++" is a
    fork requirement for exported overloads).

Bullets this area touches but does **not** close:

-   "Importing C++ overload sets into Carbon overload sets where the model
    (closed overloading) fits" (lines 160-161) — already DONE by way of Clang Sema.
    Note the milestone text itself names Carbon's model: **closed
    overloading**.
-   "Importing C++ open-overload-sets-as-extension-points (`swap`, etc)"
    (lines 162-164) — separate work (W8); Carbon's answer to _open_
    overloading is interfaces, not this design.
-   "Operator overloading: Exporting Carbon overloads into C++" (line 132) —
    operators route through Core interfaces
    (`toolchain/check/operator.h`), not function overload sets; separate W8
    item.

## Constraints

### Design-principle constraints (upstream is unusually explicit here)

Unlike error handling or unions, upstream has left a dense trail of recorded
intent. Any design that ignores it maximizes divergence risk on future merges
(standing rule 5, `fork/process.md`):

1.  **Closed, same-library sets only.** The accepted principle
    [p000998](/proposals/p000998-principle-one-static-open-extension-mechanism.md)
    (`docs/project/principles/static_open_extension.md:52-56`): "function
    overloading is limited in Carbon to only signatures defined together in
    the same library... Closed overloading in Carbon also simplifies what
    gets exported to C++." Interfaces are the _only_ open extension
    mechanism; there is no ADL in Carbon
    (`docs/design/generics/goals.md:216-242`).
2.  **Declaration-order, first-match resolution.**
    `docs/design/pattern_matching.md:696` anticipates declaration order; the
    accepted functions proposal
    [p002875](/proposals/p002875-functions-function-types-and-function-calls.md)
    (Future work → Overloading) states "our current intent is to use the
    former approach" — check each candidate in turn until one matches, not
    C++/Swift-style best-match — and sketches placeholder syntax
    `overloaded fn`, modeled as a `match_first` block of `Call` impls.
3.  **No overloading on return type.** p002875: "we do not permit overloading
    on return types, and we don't want type information to propagate from the
    context... inwards to the call."
4.  **Overloading must not break checked generics.** A checked-generic body
    is type-checked once against interfaces
    (`docs/design/generics/goals.md:216-242`); overload resolution happens at
    non-generic call sites (or against a deduced candidate list), never
    deferred to instantiation.
5.  **Information accumulation**
    ([p000875](/proposals/p000875-principle-information-accumulation.md)): a
    call site can only see overloads declared above it (or in the imported
    api). Same top-down rule C++ uses; it must fall out of the design rather
    than be violated by it.
6.  **Syntactic redeclaration matching**
    ([p003763](/proposals/p003763-matching-redeclarations.md)): today "two
    declarations differ" ⇒ error. The design must specify which differences
    mean "new overload" vs "invalid redeclaration" — this is the sharpest
    diagnostic-quality fork in the whole area (see Options A vs B).

### Interop constraints from the milestone

-   Exported Carbon overload sets must be callable from C++ with ordinary C++
    syntax. The export machinery creates real Clang decls in a mapped
    `DeclContext` (`ExportFunctionToCpp`,
    `toolchain/check/cpp/export.cpp:1023`; `clang::FunctionDecl::Create` at
    line 455, `clang::FunctionTemplateDecl::Create` at line 1015). Multiple
    same-name `FunctionDecl`s in one context _are_ a C++ overload set — C++
    callers then resolve with **C++ rules**. Carbon first-match and C++
    best-viable-match can disagree on the same argument list; the design must
    say what happens (accept-and-document vs restrict exports).
-   Import direction must stay Clang-exact
    (`docs/design/interoperability/README.md:66-69` — "respecting C++'s
    semantics, including its complex overload resolution rules"). Nothing in
    this area may route imported C++ sets through Carbon resolution.
-   The interop design doc's own "Overload resolution" section is an empty
    TODO (`docs/design/interoperability/README.md:210`) — whichever option is
    chosen should also fill that section.

### Implementation realities in this toolchain

What a Carbon-native overload set has to thread through, with current state:

| Subsystem | Current state | Needed change |
| --- | --- | --- |
| `toolchain/lex/token_kind.def` | no `overload` keyword | +1 keyword (Options A/C only) |
| `toolchain/parse/` | `fn` decls fully parsed; modifier machinery exists (`keyword_modifier_set.h`) | modifier plumbing only |
| name lookup / decl merge | one inst per name; `TryMergeRedecl` (`check/handle_function.cpp:183-261`) merges or errors | branch to "add to overload set" |
| SemIR entity | `CppOverloadSet` store exists as a template to mirror (`sem_ir/cpp_overload_set.h`) | new `OverloadSet` store + decl inst kind (`sem_ir/inst_kind.def`, `typed_insts.h`) |
| call path | `PerformCall` dispatches on callee kind incl. `CalleeCppOverloadSet` (`check/call.cpp:345-368`) | new `CalleeOverloadSet` case + resolution loop |
| tentative matching | already half-built: `ConvertToValueOfType(..., diagnose=false)` and `TryConvertToValueOfType` (`check/convert.h:175-196`); `DeduceImplArguments` returns `None` on failure (`check/deduce.h:23-28`) | non-diagnosing variant of `DeduceGenericCallArguments` (`check/deduce.h:14`), candidate loop that discards failed speculative insts |
| mangling | `Mangler::Mangle(FunctionId, SpecificId)` mangles qualified name + generic-specific fingerprint only (`sem_ir/mangler.cpp:186`) — two non-generic overloads would collide at link time | add signature fingerprint for overloaded functions (`MangleFingerprint` already exists) |
| cross-library import | `check/import_ref.cpp` (5013 lines) lazily imports single decls | import whole sets; poisoning rules |
| export | per-function export works incl. thunks (`cpp/export.cpp:785-1023`; weak_odr thunks landed 2026-07) | loop over set members; coherence check |
| lowering | none needed — resolution is fully compile-time; each selected callee lowers as today | — |
| ordered-candidate precedent | `match_first` blocks for impls: `parse/handle_match_first.cpp`, `check/testdata/match_first/` | reusable pattern for set semantics |

## Prior art

-   **C++**: open overloading + ADL + best-viable-match. Carbon's principles
    explicitly reject the open part and ADL (p000998); the import direction
    already embeds the real thing by way of Clang Sema.
-   **Swift**: unmarked overloading with most-specific-match ranking; a known
    source of exponential type-checker blowups ("expression too complex") and
    subtle source-compat breaks when overloads are added. A caution against
    best-match ranking.
-   **Rust**: no function overloading; traits (+ method resolution) instead.
    This is exactly Carbon's answer for _open_ extension, but Carbon's
    milestone still demands closed overloading for C++ migration parity.
-   **Zig**: no overloading; `comptime` + `anytype` dispatch inside one
    function body. Maps to Carbon's templates, not to this bullet.
-   **Carbon upstream's own sketch**: p002875 models an overload set as one
    function type with a `match_first` block of `Call` impls — first-match,
    order-sensitive, compile-time.

## Options

### Option A: Marked closed overloading — `overload fn`, declaration-order first-match

Every member of a set carries an `overload` declaration modifier; all members
must live in the same library. Resolution tries candidates in declaration
order and takes the first that matches (arity ⇒ deduction ⇒ implicit
conversions). This is upstream's recorded lean, made concrete.

```carbon
package Geometry api;

overload fn Dist(a: i64, b: i64) -> i64 { return Abs(a - b); }
overload fn Dist(a: f64, b: f64) -> f64 { return FAbs(a - b); }
overload fn Dist[T:! Numeric](a: Vec2(T), b: Vec2(T)) -> T { ... }

fn Use() {
  Dist(3, 5);            // candidate 1 (exact)
  Dist(1.5, 0.25);       // candidate 2
  Dist(v1, v2);          // candidate 3 by way of deduction
  var n: i32 = 4;
  Dist(n, n);            // candidate 1: first match after i32 -> i64
                         // implicit conversion; candidate 2 never tried.
}
```

Rules (the proposal-sized core):

-   A second `overload fn F` with a _different_ signature extends the set; a
    second declaration **without** `overload` keeps today's
    `RedeclParamDiffers`/`DiagnoseDuplicateName` errors — accidental
    collisions stay loud, and p003763's syntactic matching still governs
    redeclaration of each individual member (forward declaration + definition
    must match exactly, per member).
-   Set is frozen at the library boundary (p000998). `api`-file order defines
    resolution order; `impl` files may only _define_ members, not add them.
-   Methods overload the same way (`overload fn Append[addr self: Self*]
    (x: i32);` / `(s: str);` in one class body). Interface members: excluded
    in 0.1 (associated functions stay non-overloaded).
-   A call resolves against the members visible at the call site (information
    accumulation, p000875).
-   No-match diagnostic lists every candidate with its first failure reason,
    mirroring the Clang note style users already get from imported sets.
-   Naming an overload set other than as a callee (for example taking its value) is
    an error in 0.1; p002875's single-function-type-with-many-`Call`-impls
    model is the documented future path.

**C++ interop story.** Import: unchanged. Export: iterate the set through the
existing `ExportFunctionToCpp` path; C++ sees N `FunctionDecl`s and applies
C++ resolution. Divergence example, documented and conformance-tested:
`overload fn F(x: i64); overload fn F(x: f64);` called with an `i32`/`int`
argument — Carbon picks the first candidate; C++ rejects the call as
ambiguous (two equal-rank standard conversions). Divergence is only ever
_which member or whether_ — never a wrong-ABI call, since each exported
member keeps its own thunked symbol. A `fork/rulebook.md` rule: every
exported-overload conformance test asserts both directions' resolution.

**Implementation cost: L.** Touches: `lex/token_kind.def` (S),
`parse/keyword_modifier_set.h` + decl handlers (S),
`sem_ir/{overload_set.h,inst_kind.def,typed_insts.h,ids.h,file.h}` (M),
`check/handle_function.cpp` `TryMergeRedecl` branch (M), `check/call.cpp` +
`sem_ir/function.h` new callee kind and first-match loop (M — the loop is
simple _because_ first-match needs no ranking), non-diagnosing
`DeduceGenericCallArguments` (M), `sem_ir/mangler.cpp` signature fingerprint
(S), `check/import_ref.cpp` set import (M), `cpp/export.cpp` member loop (S),
`check/name_lookup.cpp` poisoning (S), plus golden + conformance tests.
Stageable: non-generic sets first (drops the deduce work from the first
land), generics second, export third.

**Evolution risk vs upstream: LOW** on semantics (every recorded upstream
signal — p000998, p002875, pattern_matching.md:696, milestones.md:161 —
points exactly here). **MEDIUM-LOW** on surface: upstream's placeholder
spells the marker `overloaded fn` and could yet choose unmarked; a keyword
rename or marker removal is a mechanical migration.

### Option B: Unmarked closed overloading (C++/Swift surface, Carbon resolution)

Same semantics as Option A (closed, same-library, declaration-order
first-match) but with no keyword: any same-scope `fn F` declarations with
differing signatures silently form a set, as in C++.

```carbon
fn Log(level: i32) { ... }
fn Log(msg: str) { ... }     // just works, no marker
```

**C++ interop story.** Identical to Option A.

**Implementation cost: L** (marginally less parse work than A, but more
diagnostics work). The hidden cost is diagnostic regression: today's
`RedeclParamDiffers` family (`check/merge.cpp:218,357,505`) catches
signature typos in forward-decl/definition pairs at the second declaration.
Unmarked, `fn F(x: i32);` ... `fn F(x: i64) { ... }` becomes a legal
two-member set whose first member is never defined — the error moves to
link/export time or to a confusing call-site resolution. C++ compilers live
with exactly this; Carbon's redeclaration design (p003763) was written to
avoid it. Distinguishing "intended overload" from "botched redeclaration"
without a marker requires heuristics.

**Evolution risk vs upstream: MEDIUM.** Semantics converge; but if upstream
lands a marker (their own placeholder used one), every unmarked fork
overload set becomes a migration diff, and the interim diagnostic behavior
will have diverged in ways users notice.

### Option C: Pattern-dispatch overloading (value patterns as overloads)

The original Carbon aspiration (`docs/design/README.md:3822`): a function
call _is_ a pattern match, an overload set _is_ an ordered list of `case`
patterns, and signatures may contain refutable patterns —
`pattern_matching.md:670-676` explicitly reserves overloaded functions as
"a third context" permitting refutable patterns.

```carbon
overload fn Fib(0) -> i64 { return 0; }
overload fn Fib(1) -> i64 { return 1; }
overload fn Fib(n: i64) -> i64 { return Fib(n - 1) + Fib(n - 2); }
```

Type-based members resolve at compile time as in Option A; value-pattern
members compile the whole set into one dispatcher function containing a
`match` over the argument tuple (runtime dispatch when values aren't
constants).

**C++ interop story.** Type-distinct members export as in Option A.
Value-pattern members share a signature, so the set exports as a _single_
C++ function wrapping the dispatcher — coherent, and arguably the cleanest
export story of all options. Import unchanged.

**Implementation cost: XL, and blocked.** Everything in Option A **plus**
refutable patterns in `fn` signatures (parse + check), a dispatcher
synthesis in lowering, and — the blocker — working `match` semantics: all 15
check handlers in `toolchain/check/handle_match.cpp` are `context.TODO`
stubs today (gap-analysis W4). Exhaustiveness/usefulness checking
(`pattern_matching.md:620-701`) must also exist to diagnose dead overloads.

**Evolution risk vs upstream: MEDIUM.** Upstream's docs aspire to this
framing, but there is zero active work and the placeholder section has sat
untouched; the risk is converging on _details_ upstream never wrote down.
Critically, Option A is a strict subset: declaration-order first-match _is_
match-case order, so A can grow into C without breaking programs.

### Option D: No Carbon-native overloading in 0.1 (Rust/Zig discipline)

Ship 0.1 with distinct names (`ParseInt`/`ParseFloat`), checked generics for
type dispatch, and imported C++ overload sets only.

**C++ interop story.** Import unchanged; export of overload sets moot.
Migration of overloaded C++ APIs to Carbon requires renaming — every such
API grows a name-mangling scheme in user code, and mechanical C++→Carbon
translation of headers with overloads has no target.

**Implementation cost: S** (docs only: record the restriction, keep today's
errors).

**Evolution risk vs upstream: HIGH by omission.** Upstream states flatly "We
intend to support function overloading" (p002875 Future work). The fork
would fail the explicit milestone bullet (`milestones.md:156`), contradict
decision **F-001** (chase the full official checklist), and require
renegotiating the gap-analysis scoreboard definition.

## Recommendation

**Option A** — marked `overload fn`, closed same-library sets,
declaration-order first-match, no value patterns in 0.1 — designed
explicitly as the compile-time subset of Option C.

Rationale:

1.  **It is the only option that is simultaneously milestone-closing, cheap
    enough, and upstream-convergent.** Every recorded upstream signal
    (p000998, p002875, pattern_matching.md:696, milestones.md:161's own
    "closed overloading" phrasing) describes exactly these semantics; the
    fork would be writing down upstream's intent, not diverging from it.
    If upstream later lands its own proposal, the merge is a syntax rename
    at worst (standing rule 5).
2.  **First-match keeps the toolchain cost at L, not XL.** No ranking
    lattice, no ambiguity metric, no Swift-style solver: the resolution loop
    is "for each candidate in order: try arity, tentative deduction,
    non-diagnosing conversions; commit first success" — and the tentative
    machinery is already half-built (`convert.h:175-196`,
    `DeduceImplArguments`). The `CppOverloadSet`/`CalleeCppOverloadSet`
    pattern (`sem_ir/cpp_overload_set.h`, `check/call.cpp:362`) is a proven
    in-tree template for the entity and call-path shape.
3.  **The marker preserves Carbon's diagnostic contract.** p003763's
    redeclaration matching keeps catching typos; sets are grep-able and
    intent-explicit, consistent with the explicitness rationale in
    `static_open_extension.md:63-65`.
4.  **Forward-compatible with the long-term aspiration.** Declaration-order
    first-match is match-case order; if the fork (or upstream) later
    implements pattern-dispatch (Option C) on top of W4's match semantics,
    existing sets keep their meaning and value-pattern members slot in.

Suggested staging against the arbiter (fork/conformance):

1.  Non-generic same-file sets: entity + resolution loop + mangling
    (scoreboard: first `overload fn` execution tests PASS).
2.  Generic members (non-diagnosing deduction) + cross-library import.
3.  Export to C++ + bidirectional conformance tests incl. one documented
    divergence case.
4.  Docs: new `docs/design/functions.md` section + fill
    `interoperability/README.md:210` TODO + retire the
    `docs/design/README.md:3822` placeholder.

## Dependencies on other workstreams

-   **W1 conformance harness** (arbiter): needed to execution-test resolution
    order; no design dependency.
-   **W4 match semantics**: none for Option A (this is the point); hard
    blocker only for Option C. The two should share the
    pattern-matching vocabulary of `pattern_matching.md` so a future merge of
    the models is textual, not semantic.
-   **W2 siblings**: if-let/let-else shares the refutable-pattern-context
    taxonomy (`pattern_matching.md:670-676` lists overloads and `let`-`else`
    as the two anticipated new contexts) — keep the two papers' terminology
    aligned. Error-handling and unions: no coupling.
-   **W6 variadics** (p002240, designed but 0% implemented): the resolution
    loop's arity pre-check must be written as "arity _range_" from day one so
    variadic candidates can join sets later without reworking the loop.
-   **W8 interop frontier**: operator export (milestones.md:132) and
    swap-style extension-point import remain separate; but the export
    coherence rule established here (documented divergence + conformance
    tests) should be reused there.
-   **Upstream watch** (standing rule 5): before implementing, re-check
    upstream for a landed overloading proposal or leads issue; the newest
    local proposal is p007493 (2026-07) with no overloading movement, but
    this is the single most likely area for upstream to design next given
    the 0.1 checklist.

## Open questions for the user (beyond option choice)

1.  **Marker spelling and placement**: `overload fn` (modifier, recommended)
    vs p002875's `overloaded fn` vs marking only the second-and-later
    members. Recommendation: modifier on _every_ member, so any single
    declaration reveals the set exists.
2.  **Mixed generic/non-generic sets and ordering discipline**: pure
    declaration order (recommended, simplest and matches the anticipated
    rule) vs any specificity preference (for example non-generic before generic),
    which reintroduces ranking complexity.
3.  **Export coherence policy**: accept documented Carbon-vs-C++ resolution
    divergence (recommended for 0.1), or add a per-set opt-in/opt-out for
    export, or attempt a conservative "reject export when members overlap
    under C++ rules" check (undecidable in general, heuristic at best).
4.  **Method sets and `self`**: are overloads distinguishable _only_ by
    explicit parameters, or also by `self` shape (`self` vs `addr self`)?
    Recommendation for 0.1: explicit parameters only; `self`-shape
    overloading deferred (parallels p002875's open issue
    [#3154](https://github.com/carbon-language/carbon-lang/issues/3154) on
    expression-category dispatch).
5.  **Naming a set outside a call**: hard error in 0.1 (recommended), or
    implement the p002875 model (one function type, many `Call` impls) now —
    which drags in `Call`-interface work that is itself future-work upstream.
6.  **Default arguments**: C++ import supports them
    (`check/testdata/interop/cpp/function/import/default_arg.carbon`), but
    Carbon-native default arguments are undesigned. Overloading substitutes
    for many cases; decide whether to leave default args out of 0.1
    entirely (recommended) or open a sibling design fork.
7.  **Diagnostic investment**: minimal "no viable candidate" for 0.1, or
    per-candidate failure notes (Clang-style) from day one? The latter is
    what C++ users expect and roughly doubles the resolution-loop
    diagnostics code.
8.  **Overload sets and `alias`/`export name`**: does an alias re-export the
    whole set (recommended) and is that transitive through `export import`?
    Needs a one-paragraph rule either way.

## References

-   `docs/project/milestones.md:154-164` — the 0.1 function bullets, incl.
    the "(closed overloading)" characterization.
-   `docs/project/principles/static_open_extension.md` /
    [p000998](/proposals/p000998-principle-one-static-open-extension-mechanism.md)
    — closed overloading, same-library restriction.
-   [p002875](/proposals/p002875-functions-function-types-and-function-calls.md)
    — Future work: Overloading (`overloaded fn` placeholder, first-match
    intent, `match_first` model); overloading-on-category issue
    [#3154](https://github.com/carbon-language/carbon-lang/issues/3154).
-   `docs/design/pattern_matching.md:670-701` /
    [p002188](/proposals/p002188-pattern-matching-syntax-and-semantics.md) —
    declaration-order anticipation; overloads as a future refutable context.
-   [p003763](/proposals/p003763-matching-redeclarations.md) — syntactic
    redeclaration matching that overload declarations must compose with.
-   `docs/design/generics/goals.md:216-253` — checked generics replace open
    overloading; `docs/design/README.md:3822` — placeholder section.
-   Toolchain: `toolchain/sem_ir/cpp_overload_set.h`,
    `toolchain/check/cpp/overload_resolution.{h,cpp}`,
    `toolchain/check/call.cpp:345-368`,
    `toolchain/check/handle_function.cpp:183-261`,
    `toolchain/check/merge.cpp:202-527`, `toolchain/check/convert.h:175-196`,
    `toolchain/check/deduce.h`, `toolchain/sem_ir/mangler.cpp:186`,
    `toolchain/check/cpp/export.cpp:455-1023`,
    `toolchain/check/import_ref.cpp`.
-   Prior art: C++ overload resolution + ADL; Swift overload ranking (and its
    type-checker cost); Rust traits-not-overloads; Zig comptime dispatch;
    upstream discussion trail by way of
    [generics goals](https://github.com/carbon-language/carbon-lang/blob/trunk/docs/design/generics/goals.md)
    and
    [design README](https://github.com/carbon-language/carbon-lang/blob/trunk/docs/design/README.md).
