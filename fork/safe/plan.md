<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Safe-Carbon plan: Strict by default, shared `T*` plus `exclusive T*`, loans with `bound`, operation-tied `unsafe` (SAFE-1, W-063)

**Status:** rev 1, 2026-10-12 — DRAFT FOR THE TWO PLAN REVIEWS (R29(c));
nothing is signed off. Every finding of the two reviews will be folded in
place, each marked "(amended <date>, review fold: rev A n / rev B n)", and the
fold record precedes Sign-off. Branch `claude/carbon-fork-0-1-safe` off trunk
0bdce60a5 ("ORCHESTRATION: UA-2 is PR 51, held open pending a gate"). Trunk's
floor is **128 PASS / 0 FAIL / 22 SKIP over 150 programs**, 48/56 bullets
(fork/conformance/out/scoreboard.json `totals`, generated 2026-10-06;
fork/ORCHESTRATION.md:383-384 and fork/gap-analysis.md:18-20 agree);
gap-analysis header **30 DONE / 21 PARTIAL / 4 MISSING / 1 DESIGN-ONLY**
across 56 (fork/gap-analysis.md:18); ledger max id on trunk **W-125**
(fork/inventory/work-items.json, last two ids W-124, W-125), with **W-126
and W-127 already allocated on the held UA-2 branch** (fork/ORCHESTRATION.md
:31-33), so this workstream's residue ids start at W-128 (§8.5). All docs,
proposal, prelude, toolchain and fork line numbers in this plan are against
trunk 0bdce60a5 and were opened and re-verified for this plan; where the
ledger's citations are stale the correction is in §0.2. This is a
**docs-only workstream**: no toolchain, prelude, golden or conformance-program
BODY changes (milestones.md:242 excludes implementation from the bullet;
milestones.md:267 defers memory-safety implementation to 0.2), so §4 has no
testdata matrix and §6 has no golden churn; the verification arbiter is local
`uvx prek run` plus the R31 count checks plus two adversarial document reviews
(§8). R28 note: the container cannot build the toolchain and **GitHub Actions on
the repository is DISABLED** (fork/ORCHESTRATION.md:13-18;
fork/decision-log.md:6521-6544), so no hosted check runs on this PR either;
that is consistent with R21 because upstream's own acceptance gate for a
markdown-only change is prek alone (.github/actions/test-setup/action.yml:35-36
computes `has_code` from a filter that excludes `**/*.md`, and
.github/workflows/tests.yaml:100-101 runs bazel only when it is true), and the
local prek result and the R31 count outcome are recorded in every commit
message (precedent: commit 119b35439's message).

**Items:** W-063 ("W3: safe-Carbon concrete design — five safety categories +
safe-Rust-interop analysis (next design-sprint wave)", kind design-needed,
subsystem "docs/design/safety + proposals", size XL, blocked_by none,
fork/inventory/work-items.json:1182-1198) is the owning item and is discharged
by this PR. W-064 ("Safety-strategy follow-ons: mode-syntax proposals and
stale principles doc", size M, :1199-1215) overlaps on the mode-syntax
substance, which this plan fixes; W-064 itself stays open for its stub flip
(§5). **Design authority, not reopened:** the accepted strategy
docs/design/safety/README.md (p005914), whose temporal/data-race section is
self-declared "_directional_ ... provisional until dedicated proposals fully
establish our model here" (proposals/p005914-updating-carbon-s-safety-strategy
.md:139-140) — this plan is that dedicated design; p005434's `ref`/`bound`/
`val` vocabulary, which defers "the exact and firm semantics of `bound`" and
"full safety" to "the full memory safety design" (proposals/p005434-ref-
parameters-arguments-returns-and-val-returns.md:831-842); p000257's unformed
state (proposals/p000257-initialization-of-memory-and-variables.md:143-199);
the fork decisions D-SL-4 (single 0.1 fail-stop mode, fork/decision-log.md
:3842-3846) and F-007b (union reads Strict-unsafe, :1019-1025). The fork
decision this plan mints is **F-013** — the next free fork id: F-012 is SL-1's
record (fork/decision-log.md:3769 "This entry is the decision record the
plan's §0.3 and §8.5 call F-012"; `grep -rno 'F-01[3-9]' fork/ docs/` is
empty) — with sub-decisions D-SAFE-1..23 (§0.3), auto-adopted under R29(a) and
veto-able after the fact. The option-paper role is played by the design-panel
record at the end of this plan (three attempts, two judges), which is the
research record and is not edited after rev 1. **Milestone bullet this plan
flips** (fork/gap-analysis.md:89): "Project: detailed and concrete design for
safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop
analysis)" — MISSING → DONE on document review, the row-88 precedent (:88,
DONE "by way of accepted p5914" while its program stays SKIP). R7: the bullet
string above is the character-for-character text of the conformance header at
fork/conformance/programs/project/safe_carbon_design.carbon:5 and is not
touched.

## §0 Audit: what exists, what the milestone says, and what is stale

### §0.1 Design-element table (verified in-tree at 0bdce60a5, with measurements)

| # | Design element | Status | Evidence (opened) |
| --- | --- | --- | --- |
| 1 | Safety strategy pages | EXIST: 2 files, 300 + 209 lines; README headings Overview / Safe and unsafe code / Safety modes / Memory safety model / Data races versus unsynchronized temporal safety / Safe library ecosystem / Build modes / Constraints / References | `ls docs/design/safety/` = README.md, terminology.md; `wc -l` 300/209; `grep -n '^#'` README.md:1,11,26,54,93,126,154,182,207,264,266,295 |
| 2 | Three "Future work" blocks the design must close | OPEN | docs/design/safety/README.md:89-91 (soundness model), :116-120 (package/function strictness syntax, "must include the `unsafe` keyword"), :122-124 (marking `import`s of permissive libraries) |
| 3 | Per-category enforcement commitment | FIXED by p005914 | README.md:131-135 type compile-time, initialization hybrid, spatial run-time, temporal compile-time through the type system, data-race compile-time through the type system; :145-149 "will largely match Rust's", initialization the only high-level deviation; :151-152 "substantial differences in the _details_" |
| 4 | Data-race latitude | FIXED | README.md:167-174 may not prevent non-temporal races, "_must_ detect and prevent" unsynchronized temporal bugs; :176-178 "If Carbon can, it should work to prevent data races as well" |
| 5 | Unsafe-code principles | FIXED | README.md:70-81 semantically narrow, syntactically narrow and separable, spellable with `unsafe`; "we don't model large regions ... or have a parallel unsafe variant language"; :83-87 a type conversion must not grant out-of-lifetime access |
| 6 | Terminology categories | 5 of 6: temporal, spatial, type, initialization, data-race; **no "mutation safety"** | docs/design/safety/terminology.md:156-176; memory-safe-language test :199-209; fail-stop :98-102 |
| 7 | Milestone wording | QUOTED in §0.1a below | docs/project/milestones.md:237-242; :86-88; :102-108; :265-271 |
| 8 | Directional model and its five divergences | PROVISIONAL | p005914:137-140 (provisional note), :159-168 (five), :170-175 inheritance, :177-189 shared-mutable AND exclusive-mutable pointers on Ante's model, :191-196 Swift-staged races, :198-202 iterator invalidation by exclusive-access methods, :204-222 fewer assumptions about unsafe code, erroneous not UB; :224-231 durable tradeoff differences |
| 9 | Requirements and secondary goals | FIXED | p005914:83-117 (fail-stop or compile-time rejection; zero-init allowed for initialization; no RC/GC; temporal under 1 percent, spatial 1-2 percent); :119-129 (safe Rust interop "no worse than the best Rust/C++ interop which uses extra safety annotations", data-race prevention; "clearly demonstrate where we end up and what any remaining gap there is") |
| 10 | `ref`/`bound`/`val` vocabulary | ACCEPTED, semantics deferred to this design | p005434:76-85 (bullets), :173-180 (`ref` does not dangle, no rebinding), :660-663 (plan to prevent mutation of borrowed objects in strict), :698-713 (`Invalid1`, dangling returns erroneous), :772-806 (`Conditional`; impls may drop not add `bound`), :823-843 (`ValToRef`, `[[clang::lifetimebound]]`, "deferred to the full memory safety design"), :846-856 (`noalias`, `captures(none)`), :865-870 (attributes only when established), :880-900 (`this` → `ref self` migration concern, "add back in `addr`"), :902-915 (expression type system, not object types), :1132-1144 (temporary lifetimes open), :1185-1190 (more precise lifetimes with the memory-safety design), :1226-1237 (restore `addr` for "one of the pointer semantics we create as part of the upcoming memory safety design") |
| 11 | Unformed state | ACCEPTED | docs/design/README.md:2127-2153 (interface opt-in; destruction correct and optional; hardened-mode zeroing; "any operation ... other than destruction or assignment ... is an error"); p000257:94-109 (moved-from = unformed middle ground; "Taking the address is fine"), :143-182, :184-199 (`Optional(T)` for the rest), :355-374 (zero the entire storage including padding; queryable unformed state; ABI boundaries), :630-642 (no unformed members; inheritance left to a later proposal), :760-766 (no passing/returning unformed objects) |
| 12 | Move operator | PROVISIONAL | docs/design/README.md:2160-2168 `~x` "leaves `x` in an unformed state ... This is provisional" |
| 13 | "Lifetime and move semantics" | BARE TODO | docs/design/README.md:3905-3907 (`> **TODO:**`), under "Unfinished tales" whose note allows a subsection to state otherwise (:3833-3836); the Error-handling entry (:3944-3949) is the fixed-by-decision shape |
| 14 | Pointers | FIXED | docs/design/README.md:847-860 no arithmetic, no null, `Optional(T*)`; :862-864 provenance future work; :1317-1332 `let` params by pointer or copy, `var` copies, pointer params for in/out; :3757-3758 C++ `T&` → `T*` |
| 15 | `const` qualifier | FIXED, API-subsetting only | docs/design/values.md:1266-1274 "This is exclusively an API-subsetting feature" |
| 16 | Value bindings | FIXED, experimental invalidation rule | values.md:456-468 (mutation ends the binding, erroneous not UB), :473-475 (experimental, "a more complete memory safety story"), :133-135 (TODO: align reference sub-categories with memory-safety terminology), :533-547 (C++ `const &` pins), :573-596 (`s_value.unsafe RefMemberFunction()` strawman), :1138-1152 (single indirection construct, "a single point that needs extension") |
| 17 | Union reads in Strict | DEPENDS ON THIS DESIGN | docs/design/unions.md:443-456 "The concrete spelling belongs to the safety-mode syntax design and does not exist yet — 0.1 ships the Permissive Carbon behavior" |
| 18 | Arithmetic build-mode behavior | THREE-MODE TEXT, TODO | docs/design/expressions/arithmetic.md:150-166 (development/performance/hardened), :171-173 TODO trap/wrap/zero |
| 19 | Destructors, delete through base | FIXED | docs/design/classes.md:1852-1870; `Concrete`/`Deletable`/`Destructible` compiler-determined (:1920-1957); `UnsafeDelete` (docs/design/README.md:2065-2071); `TrivialDestructor` facet, "forbidden from explicitly implementing" (docs/design/generics/details.md:4254-4290) |
| 20 | Error handling hooks | FIXED | docs/design/error_handling.md:873-882 (unrecoverable failures are the safety design's; a Carbon abort does not unwind C++ frames), D12 :992-994; C++ exceptions never unwind Carbon frames (docs/design/README.md:3969-3974) |
| 21 | Threading 0.1 contract | FIXED by F-008 | fork/design-sprint/threading-atomics.md:192-212 (C++ memory model, races UB, no compile-time detection in 0.1, one `llvm::Module`), :476-480 (W3 "will layer a type system over exactly the model this doc freezes") |
| 22 | Toolchain: `unsafe` | ONLY `unsafe as` | toolchain/lex/token_kind.def:243 `Unsafe`; parse accepts `unsafe` only before `as` (toolchain/parse/handle_expr.cpp:335-340 "TODO: Generalize this to handle a sequence of operator modifiers", :391-399 `ModifierNotAllowedOnOperator`); `UnsafeAs` interface and pointer cast (core/prelude/operators/as.carbon:12-14, :61-65, TODO "Should `unsafe as` be able to remove `const`?") |
| 23 | Toolchain: tokens for the design | `ref` :226, `returned` :228, `template` :236, `const` :190, `val` :246 exist; **no** `bound`, `addr`, `exclusive`, `permissive`, `shared`, `strict` | `grep -n` over token_kind.def (the `Addr` probe over token_kind.def and node_kind.def is empty); call.cpp:528-540 mentions "`addr self`" only in a D-OV-6 gate comment |
| 24 | Toolchain: borrow/lifetime analysis | ABSENT | `grep -ni 'borrow\|dangling\|lifetime' toolchain/check/*.cpp` → six comment hits only (convert.cpp:217-219, :2219; handle_loop_statement.cpp:212; handle_match.cpp:462; pattern_match.cpp:1736) |
| 25 | Toolchain: unformed | `var x: T;` → `(T as Core.DefaultOrUnformed).Op()`; no read diagnostic | toolchain/check/handle_let_and_var.cpp:277-305; core/prelude/default.carbon:13-54; `MaybeUnformed(T)` core/prelude/types/maybe_unformed.carbon:13-17; `Core.Buf` has no `UnformedInit` (buf.carbon:66-67) |
| 26 | Toolchain: spatial | slices fail-stop; arrays unchecked at run time | slice.carbon:39-52 `Get`/`Subslice`, :74-77 `IndexWith(i64)`; buf.carbon:48-53 `Set`; array index hardcoded `i32` with constant-only check (handle_index.cpp:165-183), lowering `CreateInBoundsGEP` (toolchain/lower/handle.cpp:47-74); `FailStop` lowering (lower/handle_call.cpp:682-700) |
| 27 | Toolchain: arithmetic | wrap, unguarded division | lower/handle_call.cpp:165-192 `SignedOverflowIsUB = false`, `CreateSDiv`/`CreateSRem` with no zero test |
| 28 | Toolchain: C++ pointer import | `_Nonnull` honored, else `Optional(T*)` | toolchain/check/cpp/import.cpp:1462-1466, :1491-1509; p006357:243-249 (null niche is the C++ null representation) |
| 29 | Toolchain: driver | no safety/build-mode option | toolchain/driver/compile_options.cpp:57-80 (`optimize` none/debug/speed/size only) |
| 30 | Prelude view signatures | `self` by value, no `bound`; `UnsafeMake` a plain fn with a comment contract | slice.carbon:26-37 (`FromArray`, `UnsafeMake` "The caller guarantees that `p` names at least `size` valid elements that outlive the view", `Data`); buf.carbon:45-56 (`Get`, `Set`, `AsSlice` → `UnsafeMake(self.ptr, self.size)`), :58-60 `impl as Destroy` frees |
| 31 | Conformance stub | SKIP; body guard returns 1 | fork/conformance/programs/project/safe_carbon_design.carbon:5-34 (quoted in §0.1b); sibling safety_strategy_doc.carbon:5-28; the row at fork/conformance/README.md:349 is SKIP |
| 32 | Gap row 89 | MISSING | fork/gap-analysis.md:89 (quoted in §5); W3 arbiter :136-141; narrative :506-518 |
| 33 | Decision-log structure (for the §8.7 count check) | H2 2 / H3 44 / H4 1 / H5 6; list items 23 dash / 0 ordered | `grep -c` over fork/decision-log.md; the live manufactured H3 at :6658 ("### 7700 splice-stepping ...") demotes the 2026-08-31 weekly entry to H4 (:6676) — left as is (§0.2 item 8) |
| 34 | Lint configuration | reflow live | .rumdl.toml:28-41 `[MD013] reflow = true`, `stern = true`, `code-spans = false`; .pre-commit-config.yaml:34-38 and :52-57 run rumdl v0.2.58 twice around check-google-doc-style and markdown-toc |

#### §0.1a The milestone wording, verbatim (docs/project/milestones.md:237-242)

> -   Detailed and concrete design for safe Carbon
>     -   Must at least include ways in which most modern C++ is safe: type and
>         initialization safety.
>     -   Must also include spatial, temporal, and mutation safety.
>     -   Will include an analysis of how this impacts _safe_ Rust interop.
>     -   Does _not_ include having a complete implementation in 0.1.

Supporting text: "Both strategy and design for memory safety allow evaluators
to be confident in safe Carbon having strong memory safety protections, and
being incrementally adoptable starting from existing C++ codebases"
(:86-88); the list "doesn't commit Carbon to any _particular_ design" but
"must have _something_ that addresses each of these bullet points" (:102-108);
"Memory safety" and "Carbon-native threading" are "explicitly deferred until at
least 0.2" (:265-271).

#### §0.1b The un-SKIP conditions, verbatim

safe_carbon_design.carbon:9 (one line in the file): "SKIP: MISSING
documentation bullet — there is no document to review: temporal/mutation
safety exists only as an explicitly "directional... provisional" section of
proposals/p005914-updating-carbon-s-safety-strategy.md, there are no dedicated
design docs or follow-up proposals for the per-category design
(type/init/spatial/temporal/mutation), no safe-Rust-interop analysis exists
anywhere, and docs/design/README.md's "Lifetime and move semantics" section is
a bare TODO. [...] Arbitrate by document review — un-SKIP when dedicated
safe-Carbon design docs covering all five categories plus the Rust-interop
analysis land, then morph the body per below." Its body comment (:30-33):
"Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before the
concrete safe-Carbon design (and its checkable toolchain surface) exists." Its
promoted-body strawman (:16-25) starts `// package Main strict;`.

safety_strategy_doc.carbon:9 (tail of the line): "Un-SKIP only when p005914's
follow-on mode-syntax proposals land: then drop this directive and morph the
body into a Strict-mode file where the `unsafe as` below is required to carry
its `unsafe` keyword." Its body (:19-28) runs `p unsafe as i32*` today.

The two conditions conflict inside safe_carbon_design.carbon: line 9 says the
docs landing un-SKIPs it, lines 30-33 say the toolchain surface must exist.
§4.2 resolves this (R10: the SKIP text is refreshed to name the landed pages
as evidence and the absent toolchain surface as the blocker; the program stays
SKIP), and the supersession of the line-9 clause is disclosed in the SKIP text
itself and in the F-013 entry.

### §0.2 Ledger, gap and process claims found stale (each corrected at §8.5 discharge)

1.  W-063's evidence pins fork/gap-analysis.md:71 and :96-102
    (work-items.json:1190-1191); the row is now :89 and the W3 text :128-141.
    Also "fork/decision-log.md:52-59" (:1193) is the W5-S1 entry today (:53).
2.  W-063's notes say fork ids beyond F-011 "are not yet assigned (register
    them by way of the W-005/DS-0 flow when the wave starts)" (:1197). W-005 was
    DISCHARGED 2026-09-27 under full autonomy (work-items.json:81;
    decision-log.md:2843-2855), so the id is minted here (F-013) with no
    registration round.
3.  The gap narrative says there is "no runtime bounds checking"
    (fork/gap-analysis.md:516); SL-1 landed the fail-stop checks (row 79 :79,
    D-SL-4). The narrative sentence is amended at discharge.
4.  Row 88's evidence says the strategy's residual future work is "soundness
    model/mode syntax" (:88); both are closed by this PR, so row 88's evidence
    cell is refreshed too (no status change: it is already DONE).
5.  The rulebook's R31 parenthetical says "the fork's `.rumdl.toml` has MD013
    off but MD018/MD004/MD069 on" (fork/rulebook.md:342-343); since UA-1
    adopted upstream's config (D-UA-4, fork/upstream/plan.md:368-370;
    .rumdl.toml:28-41) MD013 reflow is ON. One-sentence correction in the
    discharge commit, dated.
6.  safe_carbon_design.carbon's SKIP line un-SKIP clause ("when dedicated
    safe-Carbon design docs ... land") is superseded by its own body guard
    (§0.1b); the refreshed SKIP text records the supersession.
7.  W-064's notes say the stub "Flips when p005914's follow-on mode-syntax
    proposals land" (work-items.json:1214); after this PR the syntax is fixed
    by F-013 but has no toolchain surface, so W-064's flip condition is
    reworded to "when stage 1 (§1.9) lands".
8.  fork/decision-log.md:6658 carries a manufactured H3 that demotes the
    2026-08-31 weekly entry to H4 (:6676). NOT repaired by this PR (it is
    outside the workstream and a repair changes heading counts in a file this
    PR also appends to; keeping the baseline H2 2 / H3 44 / H4 1 / H5 6 makes
    the §8.7 count check unambiguous: H3 becomes exactly 45). Recorded as a
    residue note, not an item.

### §0.3 Decisions this plan auto-adopts (R29(a): design recommendation under V-2/V-3, veto-able after the fact)

The synthesis follows the panel's two judges (record at the end of this plan):
attempt B ("Places, projections and shared cells") is the base — `T*` is the
shared-mutable pointer, `ref` is exclusive access, one dataflow pass, `bound`
the only annotation, library `Guarded`/`Box` — with attempt A's explicit
exclusive pointer kind, loan vocabulary, `bound` contract, callee-contract
versus body-mode split, warning twins, `unsafe impl` opt-in and four-part
Rust verdict grafted in, and attempt C's `unsafe import` marker, P1/P2/P3
first enforceable subset, arithmetic answer, `Core.DynCast`, `unsafe class`
interim, rollout posture, per-row Stage column and discharge mechanics grafted
in. Every fatal flaw either judge named is resolved by a decision below and
the resolution is cross-referenced. One fork id, F-013, carries all of them,
because the rules are interdependent (T4 and M2 are one rule seen from two
sides); the break conditions are per decision.

-   **D-SAFE-1 — Taxonomy.** _Mutation safety_ is defined as the aliasing
    discipline under which temporal safety survives mutation
    (exclusive-XOR-shared access plus the no-invalidation rule, D-SAFE-9);
    _data-race safety_ (terminology.md:174-176) is its cross-thread case.
    terminology.md gains the entry; safety/README.md:131-135's list gains a
    "Mutation safety" row that names data-race safety as its thread-crossing
    corollary. This closes the gap between milestones.md:240 and
    terminology.md:156-176 (§0.1 row 6). Break condition: upstream adds a
    conflicting definition of "mutation safety" to terminology.md — the fork
    entry is renamed, the rules are not reopened.
-   **D-SAFE-2 — Soundness model S0 (closes safety/README.md:89-91).** A
    Strict function body cannot cause a safety bug provided (a) every callee
    meets its declared signature contract (loans and `bound`, `unsafe fn`
    marking, the `Send`/`Sync` facets) and (b) every `unsafe`-marked
    operation's stated obligation holds there. Signatures are the contract;
    Strict bodies are checked against them; Permissive bodies, `unsafe fn`
    bodies and C++ are trusted to meet them (review is where (a) is
    established for those); every point where the programmer takes on an
    obligation the checker cannot discharge is spelled `unsafe` at the
    operation (README.md:70-81 made precise). The prelude is the first client:
    `Core.Slice`, `Core.Buf`, `Core.Optional` are Permissive-implemented
    behind Strict-checkable signatures (slice.carbon:24-77, buf.carbon:26-64,
    optional.carbon:186-203). Break condition: a program that Strict accepts
    with no `unsafe` spelled and that exhibits a safety bug (terminology.md
    :150-176) — a model bug; the page is amended and the counterexample joins
    the §4.1 regression set.
-   **D-SAFE-3 — Strict is the language default; Permissive is spelled with
    `unsafe`.** A file is Strict unless its package declaration reads
    `unsafe permissive package P (library "L")?;` (also `unsafe permissive
    impl package P;` and `unsafe permissive library "L";`), extending the
    grammar at docs/design/code_and_name_organization/README.md:312-316; a
    function body is Strict unless its definition carries `unsafe permissive
    fn F(...) { ... }`. `permissive` is a contextual keyword valid only after
    `unsafe`, so README.md:116-120's requirement that the permissive spelling
    "must include the `unsafe` keyword" holds and `grep unsafe` finds every
    Permissive unit. The stub's `package Main strict;` strawman
    (safe_carbon_design.carbon:16) is superseded: Strict needs no word.
    Rollout (attempt C's posture, adopted as the implementation rule, not
    the language rule): the 0.1 toolchain has no modes, so every file today
    behaves as Permissive-unmarked; stage 3 ships `--strict-checks=warn` as
    the default and stage 4 flips it to `error`; the design page states the
    language rule and the rollout both. Break condition: owner veto of
    Strict-by-default, or a stage-1 parse ambiguity between `unsafe
    permissive` and the `unsafe` expression prefix (none exists on paper:
    the prefix form never precedes `permissive`, `package`, `impl`,
    `library` or `fn`).
-   **D-SAFE-4 — Callee contract and body mode are different things.**
    `unsafe fn F(...)` declares that calling `F` carries an obligation the
    checker cannot discharge; in Strict every call is spelled `unsafe F(args)`
    / `unsafe x.M(args)`; the body of an `unsafe fn` is still checked in its
    file's mode (marking a callee never un-checks its body). `unsafe
    permissive fn` is the body-mode marker: a Permissive body that is safe to
    call and never colors callers (p005914:97-98: safe and unsafe code "freely
    mixed"). Attempt C's conflation (an `unsafe fn` body being Permissive) is
    rejected (judge 1 fatal, item C). Break condition: a prelude function that
    needs both (unsafe to call AND Permissive body) — spelled `unsafe
    permissive unsafe fn`? No: the two modifiers compose as `unsafe fn` on the
    declaration plus `unsafe permissive` on the definition; if the parser
    cannot carry both, the body marker moves to a post-signature position
    (attempt A's R6 form) without changing semantics.
-   **D-SAFE-5 — Operation-tied `unsafe` is a uniform expression prefix.**
    Forms: `p unsafe as T` (exists, as.carbon:61-65), `unsafe F(args)` and
    `unsafe x.M(args)` (call of an `unsafe fn`), `unsafe *p` and `unsafe p->m`
    (dereference of an unverified pointer, D-SAFE-10), `unsafe u.f` (union
    field read, the spelling unions.md:450-452 defers to this design; writes
    need none, F-007b), `unsafe &u.f` (address of a union field: a deferred
    read), `unsafe s[i]` where `[]` resolves to an `unsafe fn`. The prefix
    applies to the one postfix expression that follows it. This supersedes
    values.md:579-596's `s_value.unsafe RefMemberFunction()` strawman (the
    member-access path has no modifier hook, handle_expr.cpp:335-340 only
    generalizes the trailing-operator path — judge 1 on attempt A's R9) and is
    recorded as a dated amendment there. Break condition: stage 1 finds the
    prefix ambiguous against `unsafe as` (it is not: `unsafe` followed by `as`
    remains the infix modifier by the existing one-token lookahead,
    handle_expr.cpp:391-394) — then the spelling moves, the set of marked
    operations does not.
-   **D-SAFE-6 — Permissive imports are marked (closes README.md:122-124).**
    A Strict file that imports a library whose API file is Permissive writes
    `unsafe import P library "L";` (declaration-level `unsafe` modifier, the
    attempt-C graft both judges asked for); importing a Strict library or
    `import Cpp ...` needs no marker because the per-operation rules carry
    the keyword at each call. Attempt A's driver flag alone
    (`--warn-permissive-imports`) is rejected as weaker than a source marker
    an audit greps. Break condition: a migration corpus where the marker is on
    more than half of all imports of a Strict file — then the marker becomes
    per-package (one `unsafe import` for the package) and the driver flag is
    added for discoverability.
-   **D-SAFE-7 — Three pointer kinds; `T*` is the shared-mutable one.**
    `T*` is the Ante-style shared-mutable pointer (any number may alias; only
    non-invalidating operations through it, D-SAFE-9); `exclusive T*` is the
    NEW exclusive-mutable kind (Rust `&mut T`; the explicit pointer kind
    p005914:182-184 names); `const T*` is the shared-const kind and `const`
    keeps exactly values.md:1266-1270's API-subsetting meaning (nothing new is
    read into `const`; attempt A's re-meaning of `const` is rejected, judge 1
    fatal A). `&x` on a place under exclusive access (an owner, a `ref`
    binding, `*p` for `p: exclusive T*`) yields `exclusive T*`, which converts
    implicitly to `T*` (downgrade: the loan becomes shared) and to `const T*`;
    `T*` converts implicitly to `const T*`; nothing converts upward except
    `unsafe as` (and `unsafe as` is the only cast that removes `const`,
    convert.cpp:1843-1846, answering as.carbon:62's TODO). Receivers: `ref
    self: Self` is exclusive access (p005434:82); `addr self: Self*` is the
    shared-mutable receiver, restoring `addr` exactly for the purpose
    p005434:1226-1237 reserves it; `ref self: const Self` and by-value `self`
    are const access. Why `T*` is shared: the C++ `T&` → `T*` mapping
    (docs/design/README.md:3757-3758) and the prelude's own `Slice.ptr: T*`
    / `Buf.ptr: T*` fields (slice.carbon:58, buf.carbon:62) are shared views
    of one block; an exclusive `T*` would turn every one into an unverified
    `noalias` claim (judge 1 fatal A; judge 2 fatal B resolved by the explicit
    exclusive kind). Keyword fallout, verified: `exclusive` occurs in `.carbon`
    sources only in comments (three testdata files; `grep -rnw`), `addr` only
    in CHECK lines and comments, `permissive` nowhere. Break condition: a
    prelude or interop API that needs a fourth kind (exclusive-const) — added
    additively; the `exclusive` spelling is a mechanical rename.
-   **D-SAFE-8 — `ref` bindings inherit the kind of their source.** A `ref`
    formed from a place is exclusive access (p005434:82, :173-180 kept); a
    `ref` formed from `*p` inherits `p`'s kind: exclusive from `exclusive T*`,
    shared-mutable from `T*` (M3 applies to uses of it), const from `const
    T*`. So p005434:710-713 (`Valid1(bound p: i32*) -> ref i32 { return *p;
    }`) and :826 (`ValToRef`) stay valid in both modes (judge 2 fatal B), the
    result being a shared-kind `ref`. `noalias`/`captures(none)` are emitted
    only for exclusive-kind refs and only under D-SAFE-10's T8, which narrows
    p005434:82's "The address of a `ref` binding is `nocapture` and `noalias`"
    to the exclusive kind — a dated amendment on the temporal page and in the
    F-013 entry. Break condition: an accepted p005434 example that becomes
    invalid in Permissive mode (none may; §4.1 lists them as "ACCEPTS").
-   **D-SAFE-9 — The no-invalidation rule and `Core.Plain`.** An operation on
    a place `P` is _invalidating_ if it can end the lifetime of any object
    reachable from `P` or change which sub-objects exist at an address: (a)
    destruction of `P` or a sub-object; (b) `~P`; (c) assignment to `P` or a
    sub-object unless the assigned type is `Core.Plain`; (d) a call whose
    receiver is exclusive (`ref self: Self`); (e) forming an exclusive loan.
    Invalidating operations require exclusive access: forbidden through `T*`
    and `const T*`, forbidden on the owner while any shared loan is live.
    Everything else (reads, overwriting `Plain` fields, `addr`/`const`
    methods) is permitted through any number of aliases. `Core.Plain` is a
    compiler-determined facet in the `Concrete`/`TrivialDestructor` pattern
    (classes.md:1941-1944; details.md:4254-4290): `Copy` with trivial
    destruction, no user `Destroy` impl, no `choice` payload, closed under
    arrays/tuples/structs/classes of `Plain` fields; pointers and `Slice` are
    `Plain`; `Buf`, `String`, `Box`, payload `choice`s are not (attempt B's
    definition replaces attempt A's `SharedAssignable`, judge 2's graft). This
    is p005914:198-202 made checkable: iterators hold `T*`, `Push` is `ref
    self` and so "precludes any outstanding shared mutable pointers". Break
    condition (R-1): a migration corpus in which more than 30 percent of C++
    non-`const` methods end up exclusive — then a finer rule (assignment
    through `T*` when no sub-loan into the old value can exist, needing
    per-field loan tracking) or an `unsafe impl T as Core.Plain` opt-in.
-   **D-SAFE-10 — Loans (T1-T8) plus the Store rule.** Vocabulary: a _place_
    is a durable reference expression's storage (values.md:306-315); a
    _loan_ is (place, kind ∈ {exclusive, shared}, origin); every pointer
    value, `ref` binding, value binding and value of a class transitively
    containing a pointer carries a loan set; ⊥ means _unverified_, the empty
    set means _free_ (globals, allocator-owned storage held by Permissive
    code). Loans are a property of values, not of types (p005434:902-915):
    `T*` stays the single indirection construct (values.md:1138-1152). T1
    ownership (one owner: `var`, `var` parameter, field, temporary, or the
    allocator behind a free pointer; no RC/GC, p005914:107-109). T2 forming
    (`&x` exclusive; downgrade on conversion; `let ref r = x;` exclusive; a
    value binding is a shared loan unless copied; `p->f`, `(*p).f`, `case
    .Some(ref v)`, `Subslice`, `FromArray`, `AsSlice` produce sub-loans;
    loans reached through an owning indirection — a `Buf`'s elements, a
    `Box`'s pointee — are _interior loans_ on the owner). T3 liveness: from
    creation to last use of any carrier (NLL on SemIR's block graph); at scope
    exit the destroyed `var`'s loans must be dead (`StrictBorrowOutlivesPlace`).
    T4 conflicts: a live exclusive loan excludes every other access to
    overlapping places; a live shared loan excludes exclusive loans and
    invalidating operations (D-SAFE-9), and an invalidating operation on `P`
    kills every interior loan on `P` (`StrictSharedBorrowInvalidated`,
    `StrictExclusiveBorrowConflict`). T5 is D-SAFE-11. **Store rule (attempt
    B's, judge 2's fatal-flaw repair for attempt A's T5(a)):** storing a
    loan-carrying value into a place `P` (field write, store through a
    pointer, container insert through a `bound`-free API, global) requires
    every loan to outlive `root(P)` — by lexical nesting for locals, by
    D-SAFE-11 for parameters, and a free or ⊥ destination accepts only free
    loans (`StrictStoreOutlivesSource`); so `let h: Holder* =
    GetGlobalHolder(); h->p = &y;` is rejected. T6 the unsafe boundary: the
    result of `unsafe as` from a non-pointer, of any `unsafe fn` or
    unannotated C++ call, and anything read through an unverified pointer is
    ⊥; a ⊥ pointer may be copied, compared, stored and passed, but `*p`,
    `p->m`, `ref` binding, view formation or passing it to a `bound` parameter
    needs `unsafe *p` (D-SAFE-5) whose obligation is that the storage outlives
    every derived use; `unsafe as` preserves the loan set of its operand, so a
    conversion never extends a lifetime (README.md:83-87). T7 is D-SAFE-12. T8
    codegen honesty: `noalias`/`captures(none)` are emitted for exclusive
    loans only where the checker established them — intra-function, and on
    `ref`/`exclusive T*` parameters of functions whose every caller is
    Strict-checked (a whole-package fact; otherwise never), per
    p005434:865-870; Permissive or C++ callers that alias such a parameter
    produce erroneous behavior, never UB (p005914:204-222). First enforceable
    subset (attempt C's graft, both judges): P1 `&local`/`&param`, P2 pointer
    parameters and `ref` bindings, P3 everything else (returned, loaded,
    converted, C++) — with P3 needing `unsafe *p` and P1/P2 never escaping;
    it is a strict subset of T1-T8 with no loan sets and ships as stage 3's
    first checker (§1.9), **but only together with the prelude churn of
    D-SAFE-14** (judge 2 fatal C: without `bound` on `AsSlice`/`FromArray`
    a view escapes as a class value and the P-rule never fires). Break
    condition: any Strict-accepted counterexample; judge 2's three programs
    (`Leak`, the scope-escaping `FromArray`, the global `Holder` store) are
    the standing regression set in §4.1 and on the temporal page.
-   **D-SAFE-11 — `bound` semantics fixed; named lifetimes pinned.** (a) The
    loan set of a call's result is the union of the loan sets of the
    arguments passed to `bound` parameters (`self` included), with kind = the
    parameter's kind (`ref`/`exclusive T*` → exclusive, value/`T*`/`const`
    → shared); a function with no `bound` parameters returns free values —
    subject to the Store rule. (b) In the callee a non-`bound` pointer/`ref`
    parameter may not escape (not returned, not stored, not passed as a
    `bound` argument whose result escapes: `StrictEscapeOfUnboundParam`); a
    `bound` parameter may escape only into the return value. (c) Returning a
    loan on a local, temporary or `var` parameter is `StrictDanglingReturn`
    (p005434:698-713's erroneous cases become hard errors in Strict). (d) For
    the duration of a returned loan the bound argument stays borrowed in the
    caller (p005434:826-830's "immutable for the duration" is T4 applied).
    (e) Impls may drop but not add `bound` (p005434:782-806, kept). (f)
    Named form, pinned now and implemented at stage 6: `bound(a)` with `[a:
    Core.Lifetime]` as a deduced parameter — `fn Push[a: Core.Lifetime](list:
    bound(a) List*, node: bound(a) Node*)` lets `list->head = node` pass the
    Store rule; `class Iter(T: type, a: Core.Lifetime)` holds `bound(a)`
    pointer fields; bare `bound` is the elision form. (g) Interim (attempt
    C's graft): until stage 6 a Strict class with a non-owning pointer field
    is declared `unsafe class` (its invariant is the author's; every
    construction site in Strict is `unsafe`), closing attempt A's R4 window
    with an auditable spelling. Break condition: upstream amends p005434's
    `bound` with different semantics — a V-3 review; the fork keeps whichever
    is lower-divergence and records the delta.
-   **D-SAFE-12 — Temporaries: diagnose, do not extend.** A `ref` binding or
    `bound` result may carry a loan on a temporary only until the end of the
    full-expression; later use is `StrictBorrowOfTemporary`, with the fix
    p005434:1140-1142 suggests (`var x = ...;`). This makes the C++ divergence
    at philosophy_and_goals.md:456-465 a compile error, never a dangling
    pointer; the builder-chain idiom values.md:414-421 flags stays
    unsupported. Break condition: a migration corpus where builder chains
    dominate — an owner call on extension.
-   **D-SAFE-13 — Initialization: definite formation, zero-fill, moves.** I1
    today's desugaring (handle_let_and_var.cpp:277-305, default.carbon:38-54)
    and the unformed contract (README.md:2134-2153) are kept. I2 Strict runs a
    flow-sensitive _definite-formation_ analysis (the same pass as the borrow
    checker) over each local `var` of an `UnformedInit`-only type, each
    `MaybeUnformed(T)` and each moved-from object: every read, member access,
    method call, value binding, `&x`, `ref` binding or pass-by-value must be
    dominated on every path by assignment from a formed value, else
    `StrictUseOfUnformed`; conditional initialization is rejected and
    `Optional(T)` is the sanctioned escape (README.md:2129-2132's own
    suggestion). I3 `&x` of a possibly-unformed `x` is permitted in Strict
    only when `x: MaybeUnformed(T)` (maybe_unformed.carbon:13-17), whose
    projection is the existing `x unsafe as T` (the form optional.carbon:194
    already uses); in Permissive `&x` is allowed and the callee is _assumed_
    to form `x` (p000257:102-104 "Taking the address is fine"), reads of
    unformed storage being erroneous-with-a-defined-value by I5. I4 moves
    (makes README.md:2160-2168 concrete): `~x` yields an initializing
    expression with `x`'s old value and leaves `x` unformed; the default move
    of a class is a bitwise relocation followed by marking the source
    unformed; `impl as Core.Move` customizes; only entire reference
    expressions may be moved from (values.md:117-118; `*p` stays future work,
    :119-122); after `~x` I2 forbids use until reassignment — p000257's
    middle ground, neither Rust's nor C++'s. `Core.Relocatable` is the
    inferred facet for bitwise-movable types (no self-pointers, all fields
    relocatable, imported C++ types only when trivially relocatable) and
    decides by-value crossing to Rust (D-SAFE-19). I5 every mode: Release
    `make_uninitialized` zero-fills the whole object including padding
    (p000257:355-358; README.md:2147-2149's hook, promoted from "hardened" to
    the Release baseline, which p005914:87-88 permits); Debug poison-fills and
    detects (README.md:231-235). I6 no unformed members (p000257:630-637; the
    `extend base` subobject is an ordinary field for I2, closing :639-642),
    no passing/returning unformed objects (:760-764), `Optional(T*)`'s
    `MaybeUnformed(T*)` storage is Permissive prelude code behind a safe API.
    Break condition: a benchmark in the fork showing more than 0.5 percent
    from zero-fill alone — then zero-fill is scoped to escaped-unformed
    objects only (the same pass knows which).
-   **D-SAFE-14 — Spatial: fail-stop everywhere, `unsafe fn` is the opt-out,
    views carry loans.** SP1 no arithmetic (README.md:847-856;
    `pointer.offset` prelude-private, slice.carbon:19). SP2 every element
    access through `array(T, N)`, `Core.Slice(T)`, `Core.Buf(T)` is
    bounds-checked and a violation fails-stop in every build mode (D-SL-4
    retained as the Release baseline README.md:219-222 requires); the array
    gap — constant indices rejected at compile time (eval.cpp:1080-1116
    `ArrayIndexOutOfBounds`), runtime indices lowered unchecked
    (lower/handle.cpp:47-74) — is a stage-2 lowering residue: `ArrayIndex`
    emits the same compare-and-`fail_stop` sequence as `Slice.Get`, and
    array subscripts go through `IndexWith(i64)` instead of the hardcoded
    `i32` (handle_index.cpp:165-170's TODO; W-116). SP3 views carry their
    length and a loan: `FromArray` takes `bound p`, `Data`/`Get`/`AsSlice`
    take `bound self`, `UnsafeMake` becomes `unsafe fn Make(p: T*, size:
    i64)` with slice.carbon:29-30's comment as its stated obligation — the
    **prelude churn is a named residue item (W-128), gated, never assumed in
    an example** (judge 2 fatal D). SP4 unchecked access is `unsafe fn
    GetUnchecked[bound self: Self](i: i64) -> T` on `Slice`/`Buf` (the W-114
    opt-out README.md:223-226 promises); no build flag disables checks; the
    benchmarking-only disable (README.md:260-262) stays unsupported. SP5
    hardening extensions (CFI, HWASAN) carry no Strict guarantee
    (README.md:266-283). The fail-stop message text stays fixed (W-113) so
    `fail_stop` needs no formatting runtime. Break condition: none for the
    semantics; the unchecked-accessor name is the residue item's.
-   **D-SAFE-15 — Arithmetic (amends arithmetic.md:150-166, answers its
    :171-173 TODO).** Release: signed overflow wraps (the existing lowering,
    lower/handle_call.cpp:165-181, made normative) and signed or unsigned
    division/remainder by zero fails-stop (NEW guard before `CreateSDiv`/
    `CreateSRem`, :188-192; stage 2). Debug: overflow fails-stop with a
    diagnostic. Compile-time overflow is already rejected. The "performance
    build ... behavior ... is not defined" row is withdrawn for Carbon code
    because p005914:85-88 forbids UB in safe code and bounds checks make
    overflow a logic bug rather than a memory bug. Break condition: a
    real-world benchmark (p005914:110-111's class) where the loss of `nsw`
    exceeds 0.5 percent — an owner call on a performance-build opt-in.
-   **D-SAFE-16 — Data races: inferred facets, staged, all races prevented
    among Carbon threads.** `Core.Send`, `Core.Sync`, `Core.Freeze` are
    compiler-determined facets: a type is `Send` if all fields are;
    `exclusive T*: Send ⇔ T: Send`; `const T*: Send ⇔ T: Sync`; `T*`
    (shared-mutable) and `Slice(T)` are never `Send` (a shared-mutable
    reference is thread-local — the Ante rule, from training knowledge,
    D-SAFE-22); `Sync ⇔ const Self*: Send`; `Freeze` = no interior
    mutability; `Core.Guarded(T)` is neither; imported C++ types are neither
    unless annotated; `unsafe impl T as Core.Send {}` opts in. Enforcement is
    at thread-crossing APIs as generic constraints (a 0.2 `Core.Thread.Spawn[F:
    Core.Send & Core.Call]`), staged facets → `--strict-concurrency=warn` →
    `error` (p005914:191-196). Consequently Strict Carbon has no data races
    between Carbon-spawned threads — stronger than README.md:167-174
    requires, permitted by :176-178 — and the "must" (no unsynchronized
    use-after-free) is a theorem of D-SAFE-7 plus this rule. The 0.1
    Permissive contract "races are UB" (threading-atomics.md:192-200,
    :476-480) is untouched: it describes Permissive code and C++ threads.
    Break condition: facet synthesis cannot see through imported C++ layouts
    — the C++ default (neither, unless annotated) already covers it.
-   **D-SAFE-17 — Value bindings through shared pointers (MS-5, ratified
    explicitly).** A value binding of a `Plain` type formed from `*p` acquires
    eagerly (a copy); a value binding of a non-`Plain` type formed from `*p`
    is a shared loan under which invalidating operations are prevented (T4),
    while `Plain`-field writes through _other_ shared aliases during the
    binding remain erroneous (values.md:456-468) and are Debug-detected by a
    value-binding shadow flag. Memory safety holds (plain fields carry no
    ownership; owning fields cannot be written through `T*`; exclusive writes
    are statically dead for the binding's lifetime); what is narrowed is
    p005434:660-663's plan to prevent _all_ mutation of borrowed objects in
    strict (judge 1 fatal B: must be ratified, not inherited). Alternative
    recorded: eager acquisition for every type (always copy — simplest,
    costly for large owning types). Consequence for Rust (D-SAFE-19): such a
    parameter exports as `&SharedView<T>`, not `&T`. Break condition: a
    demonstrated memory-safety (not correctness) consequence — then the
    eager-copy alternative is adopted.
-   **D-SAFE-18 — C++ is Permissive Carbon.** C++ code is trusted to meet
    declared contracts (S0). In Strict a C++ function whose signature involves
    any pointer, reference, view or `this` is unsafe to call (`unsafe
    Cpp.F(...)`, `StrictCppCallUnannotated`) unless its declaration carries
    annotations the importer maps: `_Nonnull` (honored today,
    import.cpp:1462-1509), `[[clang::lifetimebound]]` → `bound`
    (p005434:823-826 already equates them), a noescape-style attribute →
    non-`bound` (attribute names are D-SAFE-22 items), thread-safety
    annotations → facets; pointers returned by C++ are ⊥ (T6) —
    p005914:204-208's "no assumption that a call to C++ code won't save a
    copy of pointers" as a checkable rule. C++ `T&` → `T*` (shared,
    README.md:3757-3758); non-`const` C++ methods import as `ref self`
    (exclusive, invalidating — the conservative reading, callable through
    `exclusive T*`; through shared `T*` only as `unsafe`, or by way of
    `Core.Guarded`), `const` methods as const access; a future
    non-invalidation annotation on a C++ method maps to `addr self`.
    Permissive is Strict with three facts _assumed_ rather than proved
    (attempt B's framing, judge 2's graft): unannotated C++ pointer parameters
    do not escape; C++ non-`const` methods may be called through shared
    pointers; union reads, `unsafe fn` calls, `unsafe *`, raw casts need no
    marker. Every other analysis (definite formation, bounds, zero-fill,
    exclusivity over Carbon-owned places) runs in both modes; Permissive
    emits the warning twins (`MaybeUnformedRead`, `PermissiveAliasedExclusive`,
    `PermissiveUnannotatedCppCall`) so a file's Strict-readiness is visible
    before the flip — what makes p005914:99-104's per-function granularity
    mechanical. Migration ladder: file → `unsafe permissive package`; function
    → delete its `unsafe permissive` after fixing its warnings; file → delete
    the package modifier. Break condition (R-8): the planned C++-migration
    examples (p005914:188-189) show the unannotated-call rule on more than
    half of call sites in Strict — then an import-side allowlist of
    known-benign signature shapes (by-value, `const T&` of `Freeze` types)
    is added as an explicitly trusted assumption.
-   **D-SAFE-19 — Safe-Rust interop mapping and verdict.** Transport: C-ABI
    shims generated per function on both sides (Crubit-style) over Carbon's
    existing C++-ABI lowering (threading-atomics.md:205-212), `extern "C"`
    only, never `"C-unwind"`; a Rust panic reaching Carbon aborts, a Carbon
    fail-stop under Rust frames is a process abort and Rust `Drop` does not
    run (documented; terminology.md:98-102; error_handling.md:873-882).
    Mapping (table on the page, with attempt C's Stage column): `exclusive T*`
    ↔ `&mut T` (sound only for Strict-checked functions; the generator refuses
    `&mut` for Permissive ones); `const T*` ↔ `&T` iff `T: Core.Freeze`, else
    `&SharedView<T>`; `T*` ↔ `&Shared<T>` where `Shared<T>` is a generated
    `UnsafeCell`-based wrapper exposing exactly the non-invalidating surface
    (`get`/`set` on `Plain` fields, `addr self` methods) — **safe Rust**,
    because `Cell` semantics are what the no-invalidation rule is (attempt
    B's spelling; attempt A's "durable gap" becomes a wrapper); `bound` ↔ one
    elided lifetime, `bound(a)` ↔ named lifetimes (stage 6), `'static` ↔
    free; `Core.Relocatable` types by value as `#[repr(C)]` with a generated
    `Drop` thunk, others as owning opaque handles; `Optional(T*)` ↔
    `Option<&T>`/`Option<NonNull<T>>` by representation (p006357:243-249);
    `Slice(T)` ↔ `&[T]` by a two-word shim, never by layout; `choice` ↔ a
    `#[repr(C)]` tagged union through the shim; `Core.Str` ↔ `&str` only with
    a UTF-8 obligation (`Core.Utf8`, residue); interfaces/vtables and
    inheritance opaque both ways (p005914:170-175); generics instantiated on
    the defining side; `Send`/`Sync` emitted as `unsafe impl` exactly when the
    Carbon facet holds, nothing exported `Send`/`Sync` before stage 5. Verdict
    (attempt A's four parts): (1) safe Rust → Strict Carbon: every
    Strict-checked function over relocatable values, the three pointer kinds
    with `bound`-expressible lifetimes, `Optional(T*)`, `Slice`, `Core.Result`
    and `repr`-declared `choice` exports as a safe `fn`; Permissive functions
    always export `unsafe fn` (an audit signal); (2) Strict Carbon → safe
    Rust: a Rust fn with `#[repr(C)]`-mappable types and elidable lifetimes
    imports safe with `bound` derived from its signature, so T6 does not
    apply to Rust results whose lifetimes are declared; (3) remaining gap, as
    p005914:127-129 asks: named lifetimes and outlives bounds wait on stage 6,
    `Send`/`Sync` export on stage 5, interface- and inheritance-typed APIs
    are opaque, `SharedView<T>` instead of `&T` for D-SAFE-17's case,
    multi-lifetime Rust APIs import conservatively — every gap degrades to
    `unsafe` on one side with a stated obligation, never to UB; (4)
    performance: no runtime cost beyond the shim call; spatial checks match
    Rust's index checks (1-2 percent), temporal is compile-time on both sides.
    Break condition: a Rust soundness argument against the `Shared<T>`
    wrapper (an `UnsafeCell` reachable from a `Sync` type, say) — then `T*`
    falls back to a raw pointer on the Rust side (attempt A's durable gap)
    and the page says so.
-   **D-SAFE-20 — Library surface, all residue, none in 0.1.** `Core.Plain`,
    `Core.Relocatable`, `Core.Send`/`Sync`/`Freeze` (compiler-determined;
    `unsafe impl` opt-in), `Core.Lifetime` (stage 6), `Core.Box(T)` (unique
    owning heap handle: `fn Deref[bound ref self: Self]() -> ref T`, `fn
    DerefShared[bound addr self: Self*]() -> T*`, `impl as Destroy` in the
    buf.carbon:58-60 shape), `Core.Guarded(T)` (the one opt-in run-time
    exclusivity check: a `bool` busy flag plus `fail_stop` "carbon:
    Core.Guarded re-entered; terminating", `Modify[addr self: Self*](f)` gives
    `f` a `ref` to the value for the call; no builtin), `Core.DynCast(Derived*)
    (p: Base*) -> Optional(Derived*)` (checked downcast through the vtable for
    `Deletable` classes; `p unsafe as Derived*` is the unchecked one, closing
    p005914:170-175's inheritance divergence inside type safety),
    `Core.Move`, `Core.Utf8`; `UnsafeDelete`/`UnsafeAllowDelete`
    (classes.md:1950-1957) become `unsafe fn`. Break condition: none; each
    is a filed item with its own gate.
-   **D-SAFE-21 — Staging, what 0.1 claims, and the discharge.** Stage 0
    (this PR): the pages; no toolchain change. Stage 1: lex/parse `exclusive`,
    `permissive` (contextual), `bound`, `addr`, the mode spellings, `unsafe
    fn`, `unsafe impl`, `unsafe class`, `unsafe import`, the `unsafe` prefix
    forms — recorded in SemIR, unenforced; this un-SKIPs both documentation
    stubs (§4.2). Stage 2: runtime hardening regardless of mode (array index
    fail-stop, division by zero fail-stop, `--build-mode=debug|release`,
    Release zero-fill). Stage 3: Strict static checks without loan sets
    (unsafe-op marking, definite formation, the C++-call rule, the P1/P2/P3
    subset, warning twins), `--strict-checks=warn` default. Stage 4: the loan
    checker (T1-T8, `bound`, no-invalidation, `exclusive`), `error` default,
    `noalias` under T8. Stage 5: facets, `Core.Thread`,
    `--strict-concurrency`. Stage 6: `bound(a)`/`Core.Lifetime`,
    `Core.DynCast`, the Rust binding generator. **0.1 claims no executable
    behavior**: no Strict program is accepted or rejected by the 0.1
    toolchain; safe_carbon_design.carbon stays SKIP with its guard (§4.2);
    gap row 89 flips MISSING → DONE on document review by the row-88
    precedent, because the bullet itself excludes implementation
    (milestones.md:242) and DESIGN-ONLY (:14 "designed, zero implementation")
    is the status of a bullet whose text _requires_ implementation (row 53
    variadics); W-063 is discharged; residue items W-128.. are filed at
    discharge (§8.5). Break condition: the owner reads row 89 as DESIGN-ONLY —
    a one-cell edit and header delta MISSING −1 / DESIGN-ONLY +1 instead, no
    page changes.
-   **D-SAFE-22 — External facts are quarantined.** Every claim about Rust,
    Clang attributes, LLVM semantics, Ante's spellings, Swift, Hylo or
    hardened libc++ that the panel marked "from training knowledge" (the
    `extern "C"` abort-on-unwind rule and `C-unwind`; `[[clang::lifetimebound]]`
    and the noescape attribute names; LLVM `sdiv`/`srem` by zero being
    undefined; Ante's exact reference spellings and thread rule; the
    hardened-libc++ cost figure; `Cell`/`UnsafeCell` soundness conditions;
    Crubit's trust model) appears on the landed pages only in an "External
    facts" appendix with a status column (VERIFIED against a primary source
    by the writer, else UNVERIFIED), phrased as "we expect" where UNVERIFIED;
    no normative Carbon rule depends on an UNVERIFIED item (the Rust mapping
    rows depend on them and are therefore labelled "analysis", not "rule",
    which is what milestones.md:241 asks for — an analysis). Break condition:
    the writer verifies an item — the tag is removed in a dated edit.
-   **D-SAFE-23 — Fork id, reviews and the merge gate for a docs-only PR.**
    One id, F-013, with D-SAFE-1..23 and one break-condition register. Plan
    reviews: TWO (R29(c)). Document reviews of the landed pages: **TWO**, not
    one, because R29(c)'s reduction to one applies "once hosted verification
    ... is fully green" and a docs PR has no hosted verification to
    substitute (and Actions is disabled) — the second review is the arbiter
    the harness lacks (W-002: "no arbitration channel for ... document-review
    bullets", work-items.json:37). Briefs are the rulebook's design-doc rows
    (fork/rulebook.md:98-101). Merge gate: local `uvx prek run` (pinned hooks
    v0.2.58, R22) to a fixpoint plus the R31 count checks, both recorded in
    each commit message; R21 parity holds because upstream's own gate for
    markdown-only changes is prek alone (test-setup/action.yml:35-36,
    tests.yaml:100-101). Break condition: Actions returns before the merge —
    then `Fork: hosted verification` mode `gate` is dispatched once on the
    branch head for the record (prek is its first step) and the result is
    stamped in ORCHESTRATION.

### §0.4 The split decision: one docs-only PR (R29(b)), five reviewable commits

One PR, "SAFE-1: safe-Carbon design (F-013)", because the milestone feature
is one bullet and the six pages cross-reference each other (a page landing
without its neighbours would leave dangling links and a half-closed
Future-work block). Commits are per-reviewable-unit (§3). Rejected splits:
(a) one PR per category — rejected because the temporal and mutation pages
define one rule set and the README rewrite indexes all six; (b) landing the
README rewrite first as its own PR — rejected because its closed Future-work
blocks would point at pages not yet on trunk; (c) a toolchain slice (stage 1
syntax, stage 2 hardening) in the same PR — rejected because nothing can be
filled or gated while Actions is disabled (fork/ORCHESTRATION.md:13-18) and
the bullet excludes implementation; stage 1 and 2 are residue items W-129 and
W-130 with their own plans later.

## §1 Design (synthesized; normative text for the pages)

What follows is the design the pages state. Each rule family names the page
that owns it (§2) and the decision that fixes it (§0.3). Examples marked
"today's syntax" compile against the 0.1 toolchain as cited in §4.1; "NEW"
marks syntax the design fixes but no toolchain parses.

### §1.1 Soundness model, taxonomy and modes (owner: safety/README.md)

S0 (D-SAFE-2): signatures are the contract; Strict bodies are checked;
Permissive bodies, `unsafe fn` bodies and C++ are trusted; every obligation
the checker cannot discharge is spelled `unsafe` at the operation. Six names,
two nested (D-SAFE-1): type, initialization, spatial, temporal, mutation
(⊃ data-race). Modes (D-SAFE-3, 4, 5, 6):

```carbon
package Geometry library "Shapes";                 // Strict (default)
unsafe permissive package Audio library "Glue";    // Permissive file (NEW)
unsafe permissive fn Glue(p: Cpp.Widget*) { ... }  // Permissive body, safe to call (NEW)
unsafe fn Make(p: T*, size: i64) -> Self;          // unsafe to call; body in file mode (NEW)
unsafe import Audio library "Glue";                // Strict file importing a Permissive API (NEW)
let q: i32* = p unsafe as i32*;                    // exists today
let v: T = unsafe s.GetUnchecked(i);               // call of an unsafe fn (NEW)
let r: i32 = unsafe *q;                            // unverified dereference (NEW)
let a: i32 = unsafe u.i;                           // union field read (NEW spelling)
```

### §1.2 Type safety (owner: type_safety.md)

TY1 (static, unchanged): values are accessed only at their declared type;
conversions go through `ImplicitAs`/`As`/`UnsafeAs` (as.carbon:12-34). The
type-unsafe operations are enumerated and each is an `unsafe` operation in
Strict (D-SAFE-5): pointer reinterpretation and `const` removal by `unsafe
as`; union field read `unsafe u.f` and `unsafe &u.f` (F-007b; the read rule
is unchanged: defined byte reinterpretation, never UB, unions.md:369-393);
deleting through a non-`Deletable` base (`UnsafeDelete` → `unsafe fn`);
downcast `p unsafe as Derived*` with `Core.DynCast` as the checked form
(D-SAFE-20); dereference of an unverified pointer `unsafe *p` (T6);
integer-to-pointer `unsafe as` yielding ⊥. TY2 (D-SAFE-4) `unsafe fn` and
the call spelling; the prelude's `Unsafe`-prefixed functions are the first
`unsafe fn`s (residue W-128). TY3 `template` parameters never weaken TY1
(instantiation type-checks every operation, docs/design/templates.md;
generics/terminology.md:82-96). TY4 null is never a hole: `Optional(T*)`
(README.md:858-860), `_Nonnull` honored (import.cpp:1462-1509). Diagnostics:
`StrictUnsafeCallUnmarked` ("call to `unsafe fn` {0} requires `unsafe` in
Strict Carbon"), `StrictUnionReadUnmarked`, `StrictUnverifiedDeref`.
Permissive differs only in not requiring the keyword at the same operations;
the set of unsafe operations is identical (an audit grep finds everything in
Strict files and `unsafe permissive` finds the rest).

### §1.3 Initialization safety (owner: initialization_safety.md)

I1-I6 per D-SAFE-13. Diagnostics: `StrictUseOfUnformed` ("`{0}` may be
unformed here; initialize it on every path or use `Optional({1})`"),
`StrictAddressOfUnformed`, `StrictMoveFromNonEntire`, Permissive warning twin
`MaybeUnformedRead`; Debug runtime message "carbon: read of unformed object;
terminating". C++ consequence: C++-constructed objects are always formed;
C++ out-parameters need `MaybeUnformed(T)` in Strict or a Permissive body;
release zero-fill means C++ reading a Carbon unformed object through a stale
pointer sees zeros, never garbage (erroneous, defined).

### §1.4 Spatial safety (owner: spatial_safety.md)

SP1-SP5 per D-SAFE-14; arithmetic per D-SAFE-15 (the one path by which a
checked index could be computed wrongly without the program noticing).
Runtime behavior: one stderr line naming the operation then `abort()`
(terminology.md:98-102; messages slices.md:197-203 plus "carbon: array index
out of bounds; terminating" and "carbon: division by zero; terminating").
C++ consequence: `std::span`/`std::string_view` ↔ `Core.Slice`/`Core.Str`
(README.md:3760-3762) gain the Carbon-side check at no C++ cost; raw
pointer-plus-length APIs are one `unsafe Core.Slice(T).Make(p, n)` per site,
the single audit line of a migrated buffer API; Permissive removes only the
keyword, never the check.

### §1.5 Temporal safety (owner: temporal_safety.md; defines the pointer kinds and loans for §1.6)

Pointer kinds and receivers (D-SAFE-7), `ref` inheritance (D-SAFE-8), loans
T1-T8 with the Store rule and the P1/P2/P3 subset (D-SAFE-10), `bound` and
`bound(a)` and `unsafe class` (D-SAFE-11), temporaries (D-SAFE-12),
relocation (D-SAFE-13 I4). Diagnostics: `StrictExclusiveBorrowConflict`
("`{0}` is borrowed exclusively by `{1}` here, used again at {2}"),
`StrictSharedBorrowInvalidated`, `StrictBorrowOutlivesPlace`,
`StrictBorrowOfTemporary`, `StrictEscapeOfUnboundParam`,
`StrictDanglingReturn`, `StrictStoreOutlivesSource`, `StrictUnverifiedDeref`,
`StrictCppCallUnannotated`, Permissive twin `PermissiveAliasedExclusive`. No
runtime temporal mechanism exists in Release (no RC/GC, no quarantine, no
tagging: p005914:107-117; README.md:266-283); Debug has ASan-class detection
for Permissive and `unsafe` code (README.md:231-235). The unsafe-code
contract, stated as the design's named narrowing of p005914:209-211 (attempt
B's biggest divergence, kept and disclosed): a dangling access created by
unsafe Carbon or C++ breaking a contract is a bug _of the unsafe code_ —
Carbon never miscompiles it (T8), Debug detects it; making it defined in
Release would need quarantine-class hardening outside the under-1-percent
budget and is rejected.

### §1.6 Mutation safety (owner: mutation_safety.md)

M1 the lattice restated from the pointer's side (D-SAFE-7); M2
exclusive-XOR-shared per place (T4); M3 the no-invalidation rule and
`Core.Plain` (D-SAFE-9); M4 method classification by receiver (`ref self`
may invalidate; `addr self` body is checked under M3 — may assign `Plain`
fields, call `addr`/`const` methods, read anything; may not assign a
`String`/`Buf`/`choice` field, call exclusive methods, move or destroy; `ref
self: const Self`/`self` no mutation); interior mutability is a type's
private Permissive business (`Core.Atomic(T)` over `Cpp.std.atomic(T)`,
threading-atomics.md:201-204) and such a type is not `Freeze`; M5 `match`
through an exclusive path binds payloads as exclusive sub-loans, through a
shared path as shared sub-loans whose alternative cannot change while they
live (M3c subsumes Ante's sum-type restriction); M6 `Core.Guarded(T)`
(D-SAFE-20) as the opt-in dynamic exclusivity cell for the observer /
back-pointer idioms the rule rejects through `T*`; M7 data races (D-SAFE-16);
M8 value bindings (D-SAFE-17). Diagnostics: `StrictInvalidatingThroughShared`
("assignment to `*p` of non-`Plain` type `Buf(i32)` requires exclusive
access; use an `exclusive` pointer, `Core.Guarded`, or `unsafe`"),
`StrictNotSend`, `StrictNotSync`, Debug report `MutationDuringValueBinding`.
C++ consequence per D-SAFE-18: a migrated C++ class partitions its mutating
methods into `addr self` (element writes, non-invalidating) and `ref self`
(`push_back`, `clear`, assignment) — the partition IS the invalidation
surface the C++ standard documents per container.

### §1.7 Safe-Rust interop (owner: rust_interop.md)

Per D-SAFE-19 and D-SAFE-22: the asymmetry (toward C++ Carbon assumes
little; toward Rust Carbon must promise), the mapping table with the Stage
column (0.1 / after stage 4 / after stage 5 / after stage 6), the four-part
verdict, and the External-facts appendix.

### §1.8 C++ interop and migration (cross-cutting; each page has a "C++ interop consequence" section)

Per D-SAFE-18 with the worked migration example (`Normalize` through a
Permissive glue file, a Strict caller, and a Strict direct call after
annotation) on the README page.

### §1.9 Staging and what 0.1 claims

Per D-SAFE-21; the "Implementation staging" table appears on every page
with the rows that page owns.

## §2 Deliverable spec (file by file)

Every new page follows the landed-page anatomy (docs/design/error_handling.md
:3-7 license, :9-40 toc markers, Overview, :70-74 fixed-by-decision status
paragraph, normative sections, :884-919 "Implementation staging" table,
:921-994 "Decisions within this design" mapped to the fork sub-decisions,
:996-1009 "Alternatives considered" citing the record, :1011-1032
"References"), with a toolchain-status sentence in the status paragraph
("No part of this page is implemented in the toolchain (fork workstream
SAFE-1, stage 0); see Implementation staging") in the unions.md:84-88 shape.
Pages cite F-013 and this plan's panel record, not a pNNNN file (the fork
replaces the proposal committee, fork/process.md:18-22; error_handling.md
:1026-1029 precedent), so **no file is added under proposals/** (the
check-proposal-names hook would rename it to the PR number,
.pre-commit-config.yaml:151-161; W-063's "+ proposals" subsystem is
corrected at discharge). Every page carries an "External facts" appendix
(D-SAFE-22) where it cites any.

### §2.1 docs/design/safety/README.md — rewrite in place, history kept

Sections after the rewrite (toc regenerated by the hook): Overview
(unchanged) · Safe and unsafe code (unchanged text; the :89-91 Future-work
block becomes "> **Resolved (fork amendment 2026-10-DD, F-013 D-SAFE-2).**
The soundness model is stated below." with an in-page link to the new
"Soundness model" heading, keeping the original three lines quoted inside
the block) · NEW
"Soundness model" (S0 verbatim from §1.1; the prelude-as-first-client
paragraph) · Safety modes (keep :95-114; the :116-120 block becomes
"> **Resolved (fork amendment 2026-10-DD, F-013 D-SAFE-3/D-SAFE-4).**" plus
the grammar and the mode example of §1.1; the :122-124 block becomes
"> **Resolved (... D-SAFE-6).**" plus the `unsafe import` rule; a NEW
"Rollout" paragraph with the stage-3 `--strict-checks=warn` posture; a NEW
"Operation-tied `unsafe`" subsection listing the D-SAFE-5 forms) · Memory
safety model (:128-136 list gains "- [Mutation safety]: compile-time
enforcement through pointer kinds and binding conventions; data-race safety
is its cross-thread case." with the link to terminology; :145-152 unchanged;
NEW "Safe Carbon design" index paragraph linking the six pages with one
sentence each; NEW "Pointer kinds at a glance" table — kind / spelling / Rust
analogue / what may be done through it) · Data races versus unsynchronized
temporal safety (unchanged, plus one dated sentence: "The fork design
prevents all data races between Carbon-spawned threads (D-SAFE-16), which
this section permits.") · Safe library ecosystem (unchanged) · Build modes
(unchanged; one dated blockquote after :222: "The 0.1 toolchain has a single
mode in which the release baseline's bounds checks are unconditional
(D-SL-4); see spatial_safety.md.") · Constraints (unchanged) · NEW "C++
migration example" (the `Normalize` ladder of §1.8) · References (add F-013,
fork/safe/plan.md, the six pages, p005434, p000257). Worked examples this
page must contain: the mode example of §1.1 (NEW) and the migration ladder
(NEW, with the C++ header and the three Carbon files).

### §2.2 docs/design/safety/terminology.md — amendment

After "_Data-race safety_" (:174-176) add "#### _Mutation safety_" with the
D-SAFE-1 definition and the nesting sentence, and a dated note under
_Data-race safety_: "(fork amendment 2026-10-DD, F-013: the cross-thread
case of mutation safety)". Under _Memory-safe language_ (:199-209) no change
(the fork design satisfies the test as written; say so on the README page).

### §2.3 docs/design/safety/type_safety.md (new)

Outline: Overview · Status (F-013; toolchain: `unsafe as` only) · Rules TY1-TY4
with the operation table (operation / today / Strict spelling / mechanism) ·
Diagnostics · Worked examples · C++ interop consequence · Implementation
staging (stage 1 spellings, stage 3 marking diagnostics, stage 6
`Core.DynCast`) · Decisions (D-SAFE-4, 5, 20) · Alternatives (attempt A's
`.unsafe` member form; attempt C's Permissive-body `unsafe fn`) · References
· External facts (none expected). Worked examples, exactly:

```carbon
// EX-TY-1 (today's syntax; runs today — the body of safety_strategy_doc.carbon:19-28)
fn Run() -> i32 {
  var x: i32 = 42;
  let p: i32* = &x;
  let q: i32* = p unsafe as i32*;
  Core.Print(*q);
  if (*q != 42) { return 1; }
  return 0;
}
// EX-TY-2 (NEW): union read is the unsafe operation; writes are safe
union U { var i: i32; var f: f32; }
fn ReadU() -> i32 {
  var u: U = {.i = 1};
  let a: i32 = unsafe u.i;      // Strict: marker required; Permissive: `u.i`
  let s: i32* = unsafe &u.i;    // address of a union field is a deferred read
  return a;
}
// EX-TY-3 (NEW): a converted pointer is unverified; its dereference is the audit point
fn Deref(p: i32*) -> i32 {
  let q: i32* = p unsafe as i32*;   // type obligation only (README.md:83-87)
  return unsafe *q;                  // temporal obligation, spelled separately
}
// EX-TY-4 (NEW): unsafe fn and its call; checked downcast
unsafe fn Make(p: T*, size: i64) -> Self;        // on Core.Slice(T), residue W-128
let v: Core.Slice(i32) = unsafe Core.Slice(i32).Make(raw, n);
let d: Optional(Derived*) = Core.DynCast(Derived*)(b);   // safe; `b unsafe as Derived*` is unchecked
```

### §2.4 docs/design/safety/initialization_safety.md (new)

Outline: Overview · Status (toolchain: desugaring exists, no read diagnostic)
· Rules I1-I6 · Diagnostics · Worked examples · C++ interop consequence ·
Implementation staging (stage 2 zero-fill, stage 3 definite formation, stage
4 moves) · Decisions (D-SAFE-13) · Alternatives (attempt C's runtime-tracked
address escape in Strict; attempt A's `Assume()`) · References · External
facts (`-ftrivial-auto-var-init=zero` cost, UNVERIFIED). Worked examples:

```carbon
// EX-I-1 (today's syntax; accepted today with no diagnostic — Strict rejects)
fn Choose(c: bool) -> i32 {
  var x: i32;              // unformed: i32 is UnformedInit, not Default
  if (c) { x = 1; }
  return x;                // Strict: StrictUseOfUnformed. Permissive, Release: 0.
}
// EX-I-2 (today's syntax; accepted today)
fn Choose2(c: bool) -> i32 {
  var x: Optional(i32) = .None;
  if (c) { x = .Some(1); }
  return x.GetOr(0);
}
// EX-I-3 (rejected today: `var b: Core.Buf(i32);` has no DefaultOrUnformed impl, W-115)
fn NeedsInit() { var b: Core.Buf(i32); }
// EX-I-4 (NEW): moves re-form on assignment
fn Take() {
  var s: String = "a";
  var t: String = ~s;      // s is now unformed (I4)
  s = "b";                 // fine: assignment re-forms s; a read before this is StrictUseOfUnformed
}
// EX-I-5 (today's syntax for the type; the out-parameter migration shape)
fn Fill(p: MaybeUnformed(i32)*);
fn Out() -> i32 {
  var x: MaybeUnformed(i32);
  Fill(&x);                       // Strict: allowed only because x is MaybeUnformed
  return x unsafe as i32;         // the existing projection (optional.carbon:194 shape)
}
```

### §2.5 docs/design/safety/spatial_safety.md (new)

Outline: Overview · Status (toolchain: slices/`Buf` fail-stop live, D-SL-4;
arrays unchecked at run time; no unchecked accessor) · Rules SP1-SP5 ·
Arithmetic (D-SAFE-15) · Runtime behavior and messages · Worked examples ·
C++ interop consequence · Implementation staging (stage 2 array check and
division guard; W-128 prelude churn) · Decisions (D-SAFE-14, 15) ·
Alternatives (a build flag that disables checks; attempt C's `--unhardened`)
· References · External facts (LLVM `sdiv` by zero UNVERIFIED;
hardened-libc++ figure UNVERIFIED). Worked examples:

```carbon
// EX-SP-1 (today's syntax; runs today)
fn Sum(s: Core.Slice(i32)) -> i32 {
  var total: i32 = 0;
  var i: i64 = 0;
  while (i < s.Size()) { total += s[i]; ++i; }   // checked; final impl Slice(T) as IndexWith(i64)
  return total;
}
// EX-SP-2 (today's syntax; runs today — slices_bounds_fail_stop.carbon, EXPECT-EXIT -6)
fn Oob() -> i32 {
  var a: array(i32, 2) = (1, 2);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  Core.Print(s[RuntimeSeed(-18) as i64]);   // index 2: one stderr line, abort()
  return 0;
}
// EX-SP-3 (today's syntax; rejected today: ArrayIndexOutOfBounds, eval.cpp:1080-1116)
fn ConstOob() -> i32 { var a: array(i32, 2) = (1, 2); return a[2]; }
// EX-SP-4 (today's syntax; accepted today and lowered UNCHECKED — stage 2 closes it)
fn RuntimeArr(i: i32) -> i32 { var a: array(i32, 2) = (1, 2); return a[i]; }
// EX-SP-5 (NEW): the only opt-out
fn Hot(s: Core.Slice(i32), i: i64) -> i32 { return unsafe s.GetUnchecked(i); }
// EX-SP-6 (today's syntax; today `x / y` with y == 0 is emitted unguarded — stage 2 makes it fail-stop)
fn Div(x: i32, y: i32) -> i32 { return x / y; }
```

### §2.6 docs/design/safety/temporal_safety.md (new)

Outline: Overview · Status (toolchain: no analysis; tokens `bound`, `addr`,
`exclusive` absent) · Vocabulary (place, loan, kind, origin, ⊥, free,
interior) · Pointer kinds and receivers (D-SAFE-7, with the conversion
lattice diagram as a table) · `ref` bindings (D-SAFE-8, with the dated
narrowing of p005434:82) · Rules T1-T8 and the Store rule · The first
enforceable subset (P1/P2/P3) · `bound`, `bound(a)`, `unsafe class`
(D-SAFE-11) · Temporaries (D-SAFE-12) · Relocation and `~x` (D-SAFE-13 I4,
`Core.Relocatable`) · The unsafe-code contract (§1.5's narrowing) ·
Diagnostics · Worked examples (including the regression set) · C++ interop
consequence · Implementation staging (stage 1 tokens, stage 3 P-subset with
W-128, stage 4 loans, stage 6 named lifetimes) · Decisions (D-SAFE-7, 8, 10,
11, 12) · Alternatives (attempt A's exclusive-by-default `T*`; attempt B's
no-exclusive-pointer; attempt C's `derived(...)` and `exclusive ref`,
rejected because they duplicate `bound` and `ref`, p005434:81-85, :846-856)
· References · External facts (Rust `&mut`/`noalias`, NLL, Polonius —
UNVERIFIED unless the writer verifies). Worked examples:

```carbon
// EX-TM-1 (NEW: `bound` token): result borrows both, shared
fn Longest(bound a: const String*, bound b: const String*) -> const String* {
  if (a->Size() > b->Size()) { return a; } else { return b; }
}
// EX-TM-2 (today's syntax; accepted today — p005434:700-704 calls it invalid; Strict: StrictDanglingReturn)
fn Bad() -> i32* { var x: i32 = 4; return &x; }
// EX-TM-3 (today's syntax for everything but the `bound` on AsSlice, which is W-128)
fn Use() {
  var s: String = "abc";
  let p: const String* = &s;        // shared loan on s
  Core.Print(p->Size());            // last use of p: loan ends (NLL)
  s = "def";                        // OK after p is dead; before it: StrictSharedBorrowInvalidated
  var buf: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  let v: Core.Slice(i32) = buf.AsSlice();   // AsSlice is [bound self] after W-128: v holds an interior loan on buf
  buf.Set(1, 7);                    // OK: Set is non-invalidating and i32 is Plain
  Core.Print(v[1]);                 // prints 7
  // buf = Core.Buf(i32).Make(1, 0); // StrictSharedBorrowInvalidated: assignment destroys the block v views
}
// EX-TM-4 (regression set, judge 2 — all three are accepted by today's toolchain and must be
// rejected by stage 4; the first two also by stage 3 once W-128 lands)
fn Leak() -> Core.Slice(i32) {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  return b.AsSlice();               // StrictBorrowOutlivesPlace: b's Destroy frees the block
}
fn Escape() -> i32 {
  var s: Core.Slice(i32);
  { var a: array(i32, 2) = (1, 2); s = Core.Slice(i32).FromArray(&a); }
  return s[0];                      // StrictBorrowOutlivesPlace (a ended)
}
class Holder { var p: i32*; }       // Strict: `unsafe class Holder` until bound(a) lands (D-SAFE-11g)
fn GetGlobalHolder() -> Holder*;
fn Store() { var y: i32 = 1; let h: Holder* = GetGlobalHolder(); h->p = &y; }  // StrictStoreOutlivesSource
// EX-TM-5 (NEW): exclusive pointer and the P-subset
fn Bump(p: exclusive i32*) { *p += 1; }           // P2: deref ok; exclusive loan on *p
fn Run() -> i32 { var x: i32 = 41; Bump(&x); return x; }   // &x yields exclusive i32*
fn Peek() -> i32 { let r: i32* = Lookup(); return unsafe *r; }   // P3: Lookup has no bound
// EX-TM-6 (NEW, stage 6): named lifetimes
fn Push[a: Core.Lifetime](list: bound(a) List*, node: bound(a) Node*) { list->head = .Some(node); }
// EX-TM-7 (today's syntax): temporaries are diagnosed, not extended
fn Temp() { let ref r: String = MakeString(); Core.Print(r.Size()); }  // StrictBorrowOfTemporary; fix: var
```

### §2.7 docs/design/safety/mutation_safety.md (new)

Outline: Overview · Definition (D-SAFE-1) · M1-M8 · `Core.Plain` (the
definition and the membership table) · `Core.Guarded(T)` (its Carbon source,
runnable-shaped) · Data races and the facets (D-SAFE-16, with the facet
table) · Value bindings (D-SAFE-17, with the memory-safety argument and the
recorded alternative) · Diagnostics · Worked examples · C++ interop
consequence (the method partition) · Implementation staging (stage 4 M1-M5,
stage 5 M7) · Decisions (D-SAFE-9, 16, 17, 20) · Alternatives (attempt A's
`shared T*` qualifier with exclusive `T*`; Swift-style dynamic exclusivity
on every access, rejected on budget and README.md:266-283) · References ·
External facts (Swift's law of exclusivity, Ante's rules, `RefCell` —
UNVERIFIED unless verified). Worked examples:

```carbon
// EX-M-1 (NEW: `addr`, `exclusive`)
class IntVec {
  fn Push[ref self: Self](v: i32);                 // exclusive: may reallocate
  fn Set[addr self: Self*](i: i64, v: i32);        // non-invalidating: i32 is Plain
  fn Get[bound self: Self](i: i64) -> const i32*;  // result: shared loan on self
  fn Len(self) -> i64;
  private var buf: Core.Buf(i32);  private var len: i64;
}
fn Fill(vec: exclusive IntVec*) {
  let a: IntVec* = vec;           // downgrade: shared loan on *vec
  let b: IntVec* = vec;           // many shared pointers: fine
  a->Set(0, 1);  b->Set(1, 2);    // aliased mutation: fine
  // vec->Push(3);                // StrictSharedBorrowInvalidated while a or b is live
  let first: const i32* = vec->Get(0);
  a->Set(0, 5);                   // fine: *first now reads 5 — observable, not dangling
  Core.Print(*first);
  vec->Push(3);                   // fine: a, b, first are dead (NLL)
}
// EX-M-2 (NEW): the opt-in dynamic cell for observer idioms
fn Observe(counter: Core.Guarded(Core.Buf(i32))*, p: Core.Buf(i32)*) {
  counter->Modify(fn (ref b: Core.Buf(i32)) { b.Push(1); });   // dynamic exclusivity
  // p->Push(1);                  // StrictInvalidatingThroughShared
}
// EX-M-3 (NEW, stage 5): facets at the thread boundary
fn Spawn[T: Core.Send](f: fn (var t: T));
fn BadSpawn(p: i32*) { Spawn(fn (var q: i32*) { *q = 1; }, p); }   // StrictNotSend: `i32*` is not Send
// EX-M-4 (today's syntax; accepted today — erroneous per values.md:456-468; Strict rejects)
fn ValueBinding() -> i32 {
  var a: i32 = 1;
  let b: i32 = a;                 // value binding to a
  a = 2;                          // Strict: StrictSharedBorrowInvalidated (b is live below)
  return b;
}
// EX-M-5 (NEW): payload references through a shared path
fn Alt(c: Optional(String)*) {
  match (*c) { case .Some(ref s) => { Core.Print(s.Size()); } default => {} }   // shared sub-loan; *c cannot change alternative while s lives
}
```

### §2.8 docs/design/safety/rust_interop.md (new)

Outline: Overview and the bar (p005914:121-129; README.md:193-199) · The
asymmetry · Mapping table (rows: ownership transfer / aliasing and
mutability / lifetimes at the boundary / unwinding and panics / `Send`,
`Sync` versus Carbon threads / ABI and representation; columns: Carbon side
(this design) / Rust side / boundary rule and what safe Rust can rely on /
Stage) · The `Shared<T>` and `SharedView<T>` wrappers (Rust sketch in a
fence, labelled analysis) · Three exported-signature examples (Carbon
declaration → generated Rust declaration, per stage) · Verdict (four parts)
· Performance parity · Decisions (D-SAFE-19, 22) · Alternatives (attempt
A's raw-pointer export of `T*` as the durable gap; attempt C's 0.1 cxx-level
posture) · References · External facts (every Rust fact; `extern "C"` abort
rule and `C-unwind`; `Option<NonNull<T>>` niche; Crubit's trust model — all
UNVERIFIED until the writer verifies). Worked examples (Carbon side is
NEW syntax; Rust side is analysis):

```carbon
fn At[bound self: Self](i: i64) -> const i32*;      // → fn at<'a>(&'a self, i: i64) -> &'a i32   (stage 4; i32: Freeze)
fn Bump(p: exclusive Counter*);                     // → fn bump(p: &mut Counter)                 (stage 4)
fn Observe(p: Node*);                               // → fn observe(p: &Shared<Node>)             (stage 4; safe, Cell-shaped)
fn Longest(bound a: const Str*, bound b: const Str*) -> const Str*;   // → fn longest<'a>(a: &'a str, b: &'a str) -> &'a str (stage 6 for two names)
```

### §2.9 docs/design/README.md — "Lifetime and move semantics" replacement (:3905-3907)

Replace the bare `> **TODO:**` with the following verbatim text (the
Error-handling entry's shape, :3944-3949; fenced here so the link checker
does not resolve page links that do not exist until commit 3 lands):

```markdown
> **Note:** Unlike the rest of this section, lifetime and move semantics are
> not provisional: the design is fixed by fork decision
> [F-013](/fork/decision-log.md) and specified normatively in
> [Temporal safety](safety/temporal_safety.md) (pointer kinds, loans, `bound`,
> relocation and the move operator `~x`) and
> [Mutation safety](safety/mutation_safety.md) (exclusivity, the
> no-invalidation rule, data races). Toolchain status: none of it is
> implemented in 0.1 (fork workstream SAFE-1, stage 0); see the pages'
> Implementation staging tables.
```

Also: the Move section (:2160-2168) keeps its text and gains a dated
blockquote "the fork fixes `~x` as a destructive move leaving the source
unformed (F-013 D-SAFE-13); the provisional note above is history"; the
"Safety" tale (:3838-3901) gains one dated sentence pointing at the six
pages; the Unfinished-tales toc line is regenerated by the hook.

### §2.10 Sibling-page amendments (dated, history unrewritten)

-   docs/design/unions.md:450-452: after "does not exist yet" a dated
    blockquote: "**Amendment (2026-10-DD, SAFE-1 — F-013 D-SAFE-5):** the
    spelling is `unsafe u.f` (and `unsafe &u.f`); see
    safety/type_safety.md. 0.1 still ships the Permissive behavior."
-   docs/design/expressions/arithmetic.md after :166: a dated blockquote with
    D-SAFE-15 (Release wrap, Debug fail-stop, division by zero fail-stop in
    both; the performance-build UB row withdrawn for Carbon code; the
    :171-173 TODO answered: wrap, not zero).
-   docs/design/values.md:133-135: dated answer to the TODO (durable entire =
    place; `ref` = exclusive access, or the kind of its source pointer; value
    binding = shared read; `T*`/`exclusive T*`/`const T*` the three kinds);
    :473-475: dated note "pinned by F-013 D-SAFE-17"; :579-596: dated note
    "superseded by the prefix form `unsafe s_value.RefMemberFunction()`,
    D-SAFE-5".
-   docs/project/principles/safety_strategy.md: one dated blockquote after
    its Overview heading: "This principles document predates the accepted
    strategy (p005914, docs/design/safety/README.md) and the fork's safe-Carbon
    design (F-013); where they differ — three build modes including
    'hardened' (:151-160, :255-256), the runtime-first expectation
    (:316-319, :453-454) — the design documents govern. Kept as history."
    (W-064's "stale principles doc" half; the stub half stays W-064's.)

### §2.11 Conformance stubs (SKIP text only; bodies unchanged)

fork/conformance/programs/project/safe_carbon_design.carbon:9 is replaced by
(one line in the file; R10 exact evidence; the superseded clause disclosed):

> SKIP: documentation bullet with no toolchain surface — the design EXISTS and
> is arbitrated by document review: docs/design/safety/README.md (rewritten,
> soundness model + mode syntax), type_safety.md, initialization_safety.md,
> spatial_safety.md, temporal_safety.md, mutation_safety.md and
> rust_interop.md landed under fork decision F-013 (fork/decision-log.md
> "SAFE-1 / F-013", fork/safe/plan.md), closing p005914's provisional section
> and docs/design/README.md's "Lifetime and move semantics" TODO; gap row 89
> is DONE on that review. This program stays SKIP because no 0.1 toolchain
> surface can observe the design: `exclusive`, `permissive`, `bound`, `addr`
> are not tokens (toolchain/lex/token_kind.def has `unsafe` :243, `ref` :226
> only), `unsafe` parses only before `as` (toolchain/parse/handle_expr.cpp
> :391-399), and no Strict diagnostic exists in toolchain/check. The earlier
> un-SKIP clause ("when dedicated safe-Carbon design docs ... land") is
> superseded by the body guard below. Un-SKIP when SAFE-1 stage 1 (ledger
> item W-129: mode spellings, `unsafe fn`, the `unsafe` prefix parsed and
> recorded) lands: then drop this directive and morph the body per below.

The promoted-body strawman (:16-25) is rewritten in the fixed syntax: no
`package Main strict;` line (Strict is the default), `let q: i32* = p unsafe
as i32*;` kept as the required-keyword line, `// var a: array(i32, 2) = (1,
2); a[2];` as the compile-time spatial rejection, and `// let r: i32 = unsafe
*q;` as the temporal audit point — still comments, still not compile-verified
(R6 cannot apply to syntax no toolchain parses; disclosed in the comment).
The guard body (:29-34) is unchanged.

fork/conformance/programs/project/safety_strategy_doc.carbon:9: the tail
"Un-SKIP only when p005914's follow-on mode-syntax proposals land" becomes
"The mode syntax is now fixed by F-013 (docs/design/safety/README.md 'Safety
modes'; Strict is the default, Permissive is `unsafe permissive package`);
un-SKIP when SAFE-1 stage 1 (W-129) lands, then morph the body into a
default-mode (Strict) file where the `unsafe as` below is required to carry
its keyword — it already does." Body unchanged. `runner.py --self-test`
before each commit touching programs (R7; the hook runs it).

### §2.12 Fork state files (discharge commit; §8.5-8.7 spell the edits)

fork/gap-analysis.md (row 89, row 88 evidence, header, narrative :516),
fork/inventory/work-items.json (W-063 discharged, W-064 reworded, residue
W-128..W-134 filed), fork/decision-log.md (F-013 entry), fork/ORCHESTRATION.md
(header, branch table, next actions), fork/rulebook.md (the R31 correction
of §0.2 item 5), fork/conformance/README.md (unchanged: statuses only).

## §3 Commit structure (PR "SAFE-1: safe-Carbon design (F-013)")

1.  `SAFE-1 (1/5): safety README rewrite, soundness model, modes;
    terminology gains mutation safety` — §2.1, §2.2. Reviewable alone (the
    page index links are to pages that commit 2-4 add; the PR is reviewed as
    a whole, each commit is a self-contained diff).
2.  `SAFE-1 (2/5): type, initialization and spatial safety pages` — §2.3-2.5.
3.  `SAFE-1 (3/5): temporal and mutation safety pages` — §2.6, §2.7.
4.  `SAFE-1 (4/5): safe-Rust interop analysis; sibling-page amendments` —
    §2.8, §2.9, §2.10.
5.  `SAFE-1 (5/5): discharge — F-013 entry, ledger, gap row 89, stub SKIP
    refresh, ORCHESTRATION` — §2.11, §2.12 (the residue ids are allocated in
    this commit by grepping the max W-id across trunk AND the held UA-2
    branch, §8.5).

Every commit message records: the local prek command and result (hooks
skipped by `SKIP=`: fix-cc-deps, check-build-graph, check-bazel-mod-deps,
forbid-llvm-googletest — bazel-backed, R22), the R31 heading/list counts
before and after per touched file, and the heading-set `comm -13` result
(commit 119b35439's message is the shape). Authorship: owner is author,
Claude co-author (fork/ORCHESTRATION.md:470).

## §4 Design conformance (how a design is tested without a toolchain)

### §4.1 The checklist: every rule has a worked example with a known outcome today

A rule is "conformant" when its page carries a worked example whose outcome
against the 0.1 toolchain is one of: ACCEPTS (compiles and runs today, with
the program or golden that proves it), REJECTS (diagnosed today, with the
diagnostic name and its source), ACCEPTS-UNCHECKED (compiles today but the
design says Strict must reject or the runtime must check — a stage-N gate,
with the residue id), or NEW-SYNTAX (no toolchain parses it; the stage that
will). The reviewers check the table against the pages; a rule with no row
is a finding.

| Rule | Example | Today | Evidence | Stage |
| --- | --- | --- | --- | --- |
| TY1 `unsafe as` | EX-TY-1 | ACCEPTS | safety_strategy_doc.carbon body; check/testdata/as/unsafe_as.carbon; lower/testdata/pointer/convert.carbon | — |
| TY1 union read | EX-TY-2 | NEW-SYNTAX (Permissive read ACCEPTS today: types/union_basic.carbon) | unions.md:450-456 | 1, 3 |
| TY1 unverified deref | EX-TY-3 | NEW-SYNTAX | handle_expr.cpp:391-399 | 1, 3 |
| TY2 `unsafe fn` | EX-TY-4 | NEW-SYNTAX | token_kind.def (no modifier) | 1, 3 |
| TY4 null | `Optional(T*)` | ACCEPTS | stdlib/optional_pointer_niche.carbon; import.cpp:1491-1509 | — |
| I2 definite formation | EX-I-1 | ACCEPTS-UNCHECKED | no `*Unformed*` diagnostic in toolchain/check | 3 (W-131) |
| I2 `Optional` escape | EX-I-2 | ACCEPTS | optional.carbon | — |
| I1 non-unformable type | EX-I-3 | REJECTS | W-115 (gap-analysis.md:79); buf.carbon:66-67 | — |
| I4 move | EX-I-4 | NEW-SYNTAX | README.md:2160-2168 provisional | 4 |
| I3 `MaybeUnformed` | EX-I-5 | ACCEPTS (type and projection exist) | maybe_unformed.carbon:13-17; optional.carbon:194 | 3 for the Strict rule |
| SP2 slice check | EX-SP-1, EX-SP-2 | ACCEPTS | stdlib/slices_bounds_fail_stop.carbon EXPECT-EXIT −6; slice.carbon:39-44 | — |
| SP2 constant array | EX-SP-3 | REJECTS | eval.cpp:1080-1116 `ArrayIndexOutOfBounds` | — |
| SP2 runtime array | EX-SP-4 | ACCEPTS-UNCHECKED | lower/handle.cpp:47-74 | 2 (W-130) |
| SP4 unchecked | EX-SP-5 | NEW-SYNTAX | slice.carbon (no accessor) | 1 + W-128 |
| D-SAFE-15 division | EX-SP-6 | ACCEPTS-UNCHECKED | handle_call.cpp:188-192 | 2 (W-130) |
| T5 `bound` | EX-TM-1 | NEW-SYNTAX | token_kind.def (no `bound`) | 1, 4 |
| T5c dangling return | EX-TM-2 | ACCEPTS-UNCHECKED | p005434:700-704 (erroneous) | 3 (P-subset) |
| T3/T4 NLL | EX-TM-3 | ACCEPTS-UNCHECKED (Permissive semantics today) | — | 4 |
| Regression set | EX-TM-4 | ACCEPTS-UNCHECKED | judge 2's programs; buf.carbon:54-60; slice.carbon:26-28 | 3 (`Leak`, `Escape` with W-128), 4 (`Store`) |
| P-subset / `exclusive` | EX-TM-5 | NEW-SYNTAX | — | 1, 3 |
| T5f named | EX-TM-6 | NEW-SYNTAX | — | 6 |
| T7 temporaries | EX-TM-7 | ACCEPTS-UNCHECKED | convert.cpp:2219 TODO | 4 |
| M3/M4 `addr` | EX-M-1 | NEW-SYNTAX | call.cpp:528-540 (gate xii) | 1, 4 |
| M6 `Guarded` | EX-M-2 | NEW-SYNTAX (library) | — | 4 (W-128) |
| M7 facets | EX-M-3 | NEW-SYNTAX | — | 5 (W-133) |
| M8 value binding | EX-M-4 | ACCEPTS-UNCHECKED | values.md:456-468 | 4 |
| M5 payload refs | EX-M-5 | ACCEPTS today as Permissive (`ref` payload bindings exist, handle_binding_pattern.cpp:518-528) | — | 4 |
| Modes | §1.1 block | NEW-SYNTAX | code_org README.md:312-316 grammar | 1 |
| Rust rows | §2.8 | ANALYSIS (D-SAFE-22) | — | 4-6 |

### §4.2 The stub: un-SKIP condition and body morph plan

Condition (restated from §2.11): stage 1 (W-129) parses and records the
mode spellings, `unsafe fn`, and the `unsafe` prefix forms. Morph plan at
that time: delete the SKIP line; body = a default-mode (Strict) file with
`var x: i32 = 42; let p: i32* = &x; let q: i32* = p unsafe as i32*;
Core.Print(*q); return 0;` (EXPECT-STDOUT 42 as the header already says),
plus one line per further-landed stage: stage 2 adds a runtime array index
in bounds (and a sibling `_fail_stop` program with EXPECT-EXIT −6 for the
out-of-bounds twin, the slices precedent), stage 3 adds a `fail_` split
with EX-I-1 and EX-TM-2 as REJECTS goldens, stage 4 adds EX-M-1. The
guard return 1 is replaced only at stage 1. `safety_strategy_doc.carbon`
un-SKIPs at stage 1 with no body change (its body is already the Strict
shape). Both stay SKIP in this PR; the bullet rolls up SKIP
(fork/conformance/README.md:217-218), which does not affect the row-89 flip
(document review, row-88 precedent).

### §4.3 What the reviews test instead of a toolchain

Adversary 1 ("contradictions with accepted proposals + sibling designs"):
every D-SAFE against p005914, p005434, p000257, values.md, unions.md,
arithmetic.md, classes.md, error_handling.md, threading-atomics.md,
slices.md; the two dated narrowings (p005434:82 in D-SAFE-8, p005434:663 in
D-SAFE-17) and the withdrawal of arithmetic.md's performance-build row must
each be found explicitly disclosed. Adversary 2 ("interop /
implementation-cost errors against the actual toolchain"): every §4.1
"Today" cell re-verified by opening the cited file; every NEW spelling
checked for a token or parser collision (handle_expr.cpp, token_kind.def,
code_org grammar); the regression set traced by hand through the loan rules;
the Rust rows checked for an unlabelled training-knowledge claim (D-SAFE-22).

## §5 Scoreboard and gap-row effect

-   Conformance: **no program moves**. 128 PASS / 0 FAIL / 22 SKIP over 150
    stays; both documentation stubs stay SKIP with refreshed evidence
    (§2.11); `runner.py --self-test` must be clean (the hook runs it on every
    program edit). The bullet "Project: detailed and concrete design for
    safe Carbon (...)" rolls up SKIP, as before.
-   Gap row 89 (fork/gap-analysis.md:89): MISSING → **DONE**, evidence cell
    rewritten to: "Fork design F-013 (SAFE-1, fork/safe/plan.md):
    docs/design/safety/README.md rewritten (soundness model, Strict-by-default
    mode syntax with `unsafe permissive`, `unsafe import`, operation-tied
    `unsafe`), six pages type_safety / initialization_safety / spatial_safety
    / temporal_safety (three pointer kinds `T*`/`exclusive T*`/`const T*`,
    loans, `bound`, relocation) / mutation_safety (no-invalidation rule,
    `Core.Plain`, `Core.Guarded`, `Send`/`Sync`) / rust_interop (mapping
    table, four-part verdict), terminology gains mutation safety, README
    'Lifetime and move semantics' fixed by decision; DONE on document review
    (row 88 precedent), implementation excluded by the bullet. Gated residue,
    each a filed item: stage 1 syntax (W-129), stage 2 hardening (W-130),
    stage 3 static checks (W-131), stage 4 loan checker (W-132), stage 5
    facets (W-133), stage 6 named lifetimes + Rust generator (W-134), prelude
    `bound`/`unsafe fn` churn (W-128); the conformance stub stays SKIP until
    W-129." Header delta **MISSING −1 / DONE +1** → "31 DONE / 21 PARTIAL /
    3 MISSING / 1 DESIGN-ONLY". Row 88's evidence cell: "residual future-work
    on soundness model/mode syntax and a stale conflicting principles doc"
    → "soundness model and mode syntax closed by F-013 (row 89); the
    principles doc carries a supersession note; the program stays SKIP until
    W-129". Narrative :516 "and no runtime bounds checking" → "(runtime bounds
    checking landed at SL-1)". Bullet text untouched (R7). The stub stays SKIP
    until a toolchain surface exists — stated in the row, the SKIP text and
    the F-013 entry.
-   Scoreboard line in ORCHESTRATION (:383-384) unchanged; the bullets-green
    count 48/56 unchanged.

## §6 Churn inventory (verified by grep at 0bdce60a5)

No toolchain, prelude, golden or conformance-BODY file changes: §4 testdata
and golden churn are "none, because no toolchain file changes". Markdown
touched: docs/design/safety/README.md (rewrite), terminology.md (amendment),
six new pages, docs/design/README.md (:2160-2168 note, :3838-3901 sentence,
:3905-3907 replacement; toc regenerated), docs/design/unions.md (:450-456
amendment), docs/design/expressions/arithmetic.md (after :166),
docs/design/values.md (:133-135, :473-475, :579-596 notes),
docs/project/principles/safety_strategy.md (one blockquote), fork/
gap-analysis.md, fork/inventory/work-items.json, fork/decision-log.md,
fork/ORCHESTRATION.md, fork/rulebook.md (one sentence), fork/safe/plan.md.
Conformance headers only: the two stubs' SKIP lines and the strawman
comment. Name collisions, verified: `exclusive` appears in `.carbon` sources
only in three comments, `addr` only in CHECK lines and comments,
`permissive`/`Send`/`Sync`/`Freeze`/`Relocatable`/`DynCast` nowhere;
`Plain`, `Guarded`, `Box` are user class names in interop testdata (no
`Core.` prefix, so no clash with prelude names). Contention: none of the
touched docs are on the held UA-2 branch's diff except fork/gap-analysis.md,
fork/inventory/work-items.json and fork/ORCHESTRATION.md (UA-2 files W-126/
W-127 and re-cites rows); whichever lands second rebases, and the residue
ids start at W-128 so no id collides (§8.5).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — `Core.Plain` too coarse.** `addr` methods cannot overwrite a
    `String` field, so migrated classes with string members need exclusive
    receivers more often than C++ needed non-`const`. Falsifier: the
    migration corpus (p005914:188-189) with more than 30 percent of
    non-`const` methods ending exclusive. Contingency: D-SAFE-9's break
    condition.
-   **R-2 — the `ref`-kind inheritance (D-SAFE-8) is novel.** A shared-kind
    `ref` is a `ref` through which M3 forbids invalidating operations; no
    accepted text has that notion. Falsifier: a p005434 example that the
    rule makes invalid in Permissive, or a `ref self: Self` method body that
    the rule accepts yet invalidates through a shared `ref`. Contingency:
    forbid `ref` from shared `*p` in Strict only (attempt B's rule) while
    keeping Permissive compatibility — p005434's examples are Permissive
    programs.
-   **R-3 — `noalias` withheld across Permissive/C++ callers (T8).** Strict
    code loses `&mut`-derived optimizations at boundaries unless the package
    is wholly Strict. Falsifier: more than 1 percent regression on the
    p005914:110-111 benchmark class comparing with/without attributes.
    Contingency: a link-time all-callers-Strict fact (LTO) re-enables them;
    attributes are never emitted unestablished.
-   **R-4 — the bare-`bound` stage cannot express stores through parameters.**
    Linked structures are Strict-rejected until stage 6 (p005434:1185-1190
    already defers). Falsifier: migration pilots blocked on it before stage
    6. Contingency: `unsafe class` interim (D-SAFE-11g) now; pull stage 6
    forward — its syntax is fixed here.
-   **R-5 — Strict-by-default re-means every file in the tree once stage 3
    lands.** Mitigation is the warn-first rollout (D-SAFE-3) and the prelude
    being ported first (W-128). Falsifier: owner veto. Contingency: the
    page states the default as a language rule; the toolchain flip date is
    a rollout, not a design, question.
-   **R-6 — parser work for the prefix `unsafe` and `unsafe permissive`.**
    Cost, not design risk; D-SAFE-5's break condition moves spellings, never
    the marked set. Falsifier: a stage-1 ambiguity report.
-   **R-7 — `exclusive`/`permissive`/`bound`/`addr` keyword fallout.**
    Verified empty in `.carbon` sources (§6); `permissive` is contextual.
    Falsifier: an upstream merge introducing an identifier `exclusive` or
    `bound` — then raw identifiers (`r#bound`) at the merge.
-   **R-8 — every unannotated pointer-carrying C++ call is unsafe in Strict.**
    Mixed codebases live in Permissive longer (the intended path,
    p005914:99-104). Falsifier and contingency: D-SAFE-18's.
-   **R-9 — facet synthesis is placeholder machinery today.** `Send`/`Sync`/
    `Plain`/`Relocatable` rely on the `TrivialDestructor`/`Concrete` synthesis
    (custom_witness.cpp:180-205 and the SF-6 allowlist note). Falsifier:
    synthesis cannot see through imported C++ layouts. Contingency: the C++
    default (neither) already holds.
-   **R-10 — the MS-5 narrowing (D-SAFE-17) is the decision most likely to be
    vetoed.** Falsifier: a memory-safety consequence (none by the argument on
    the page). Contingency: eager copy for all types.
-   **R-11 — external facts.** D-SAFE-22 quarantines them; the risk is a
    writer promoting an UNVERIFIED item to a rule. Falsifier: adversary 2
    finds one. Contingency: it is a NEEDS-FIX finding, fixed by the fixer.
-   **R-12 — the docs-only merge gate is local-only.** With Actions disabled
    there is no second machine. Falsifier: a hook version drift between the
    pinned rumdl v0.2.58 and whatever `uvx prek` resolves (R31 probe used
    0.2.78). Contingency: prek runs the pinned hook by rev (R22); any
    difference is recorded in the commit message; D-SAFE-23's break
    condition dispatches `gate` once Actions returns.
-   **R-13 — reflow manufacture (R31).** Six long pages plus a decision-log
    append. Falsifier: a changed heading or list count after prek (§8.1).
    Contingency: rephrase, never revert.
-   **R-14 — row 89 DONE versus DESIGN-ONLY.** D-SAFE-21 argues DONE from the
    bullet's own exclusion of implementation (milestones.md:242) and the
    row-88 precedent; the owner may read the header's DONE definition
    ("implemented with real test coverage", :12-13) literally. Falsifier:
    owner veto. Contingency: D-SAFE-21's break condition (one cell, one
    header delta).

Rejected alternatives (not risks): exclusive-by-default `T*` (attempt A;
judge 1 fatal A); no exclusive pointer kind (attempt B; both judges' fatal
B); `derived(...)` on returns and `exclusive ref` (attempt C; duplicate
`bound`/`ref`, p005434:81-85, :846-856); Permissive as the default mode
(attempt C; terminology.md:200-201); closing the lifetime TODO with "0.1 has
no move" (attempt C; judge 2 fatal E); `const T*` re-meant as "aliasable"
(attempt A R7; values.md:1266-1270); Swift-style dynamic exclusivity on
every access (budget, README.md:266-283); quarantine-class hardening for
dangling unsafe accesses (budget); a `proposals/` file (hook rename, process);
five fork ids (interdependent rules).

## §8 Verification and discharge

1.  **Local prek to a fixpoint, with R31 counts, per commit.** (a) Before:
    for every touched `*.md`, record heading counts per level (`for l in 1 2
    3 4 5 6; do grep -c "^$(printf '#%.0s' $(seq 1 $l)) " <f>; done`) and
    list-item counts including indented items (`grep -cE '^\s*-   '`,
    `grep -cE '^\s*[0-9]+\. '`), and save the set of heading lines (`grep
    -n '^#' <f> > before`). (b) Run `SKIP=fix-cc-deps,check-build-graph,
    check-bazel-mod-deps,forbid-llvm-googletest uvx prek run --files
    <touched>` repeatedly until a run changes nothing. (c) `git diff -U0 |
    grep -nE '^\+\s*#{1,6} [0-9]|^\+#[0-9]'` must be empty. (d) Re-count (a)
    and `comm -13` the heading-line sets: every count unchanged and no new
    heading line, except the ones this commit deliberately adds (the new
    pages' own headings; the decision-log H3 +1). (e) `uvx rumdl check
    <touched>` exits 0 (MD013 residue lines are rewritten by hand or fenced
    with `<!-- rumdl-disable MD013 -->` / `<!-- rumdl-enable MD013 -->`,
    precedents fork/overload/plan.md:357/:484). (f) Commit, recording (b)-(e)
    in the message. R25: all edits by Edit/Write; no shell append to
    committed markdown.
2.  **Two plan reviews** (this document; R29(c)), then the fixer (R11) folds
    with "(amended <date>, review fold: ...)" marks and the fold record;
    then the writer.
3.  **Two document reviews of the landed pages** (D-SAFE-23; briefs §4.3);
    fixer separate; a review silent more than an hour is relaunched
    (R29(e)); findings cite (R8); dispositions cite, not narrate (R17).
4.  **Conformance:** `python3 fork/conformance/runner.py --self-test` clean
    after the stub edits (R7; the hook runs it). No scoreboard regeneration
    is possible (hosted runners only, ORCHESTRATION.md:405-407) and none is
    needed: no program moves (§5).
5.  **Ledger edits (fork/inventory/work-items.json):** W-063 — notes prefixed
    "DISCHARGED (fork/safe/plan.md SAFE-1, 2026-10-DD; branch
    claude/carbon-fork-0-1-safe; commits <shas>; F-013 with D-SAFE-1..23):
    ..." , evidence re-pinned to :89 / :128-141 / the six pages / the F-013
    heading, subsystem corrected to "docs/design/safety" (no proposals/ file,
    §2). W-064 — notes reworded per §0.2 item 7. Residue items filed with
    the **ids allocated at discharge by `grep -o '"W-[0-9]*"'` over
    work-items.json on trunk AND on the UA-2 branch head (05a5c30f7 or later),
    taking max+1** — expected W-128 prelude `bound`/`unsafe fn` churn and the
    library surface of D-SAFE-20 (`Core.Plain`, `Relocatable`, `Box`,
    `Guarded`, `Move`, `DynCast`, `Utf8`; `UnsafeDelete` → `unsafe fn`; `Slice
    .UnsafeMake` → `unsafe fn Make`; `GetUnchecked`); W-129 stage 1 syntax
    (tokens, mode spellings, `unsafe fn`/`impl`/`class`/`import`, the `unsafe`
    prefix; un-SKIPs both stubs); W-130 stage 2 hardening (array index
    fail-stop with `IndexWith(i64)` subscripts — absorbs W-116's `i32` note —
    division-by-zero fail-stop, `--build-mode`, Release zero-fill; absorbs
    W-114's opt-out as "spelled by W-128"); W-131 stage 3 Strict static
    checks (definite formation, unsafe-op marking, the C++-call rule and
    annotation mapping, P1/P2/P3 subset, warning twins, `--strict-checks`);
    W-132 stage 4 loan checker (T1-T8, Store rule, `bound`, `exclusive`,
    no-invalidation, `addr`, `noalias` under T8, Debug value-binding flag);
    W-133 stage 5 facets and threads (`Send`/`Sync`/`Freeze`, `unsafe impl`,
    `Core.Thread`, `--strict-concurrency`); W-134 stage 6 (`bound(a)`/
    `Core.Lifetime`, `Core.DynCast`, the Rust binding generator with
    `Shared<T>`/`SharedView<T>`). Each item: kind implementation-needed, bullet
    = the row-89 string, evidence = the owning page and the §4.1 rows,
    blocked_by = the previous stage (W-130 and W-129 unblocked), notes naming
    the design decision and its break condition.
6.  **Docs edits:** §2 spells each page and amendment; §5 spells the gap
    row 89 and row 88 cells, the header delta and the narrative fix; the
    rulebook correction (§0.2 item 5): in R31's parenthetical replace "the
    fork's `.rumdl.toml` has MD013 off but MD018/MD004/MD069 on" with "the
    fork's `.rumdl.toml` had MD013 off until UA-1 adopted upstream's reflow
    config, D-UA-4, 2026-10-06; it is on now" — one sentence, dated, no rule
    renumbered.
7.  **Decision-log entry:** heading `### SAFE-1 / F-013: Safe Carbon —
    Strict by default, shared `T*` plus `exclusive T*`, loans with `bound`,
    operation-tied `unsafe` (2026-10-DD)`, inserted **before** "### SL-2:
    std::span ↔ Core.Slice mapping ..." (:2863) — newest-first in the landed
    region (SL-2 2026-10-05 at :2863 precedes OV-3 and SL-1). Contents:
    context (the milestone bullet verbatim; p005914:139-140; W-063); the
    panel (three attempts, two judges, winner B with grafts, the resolved
    fatal flaws, each in one sentence); D-SAFE-1..23 with break conditions
    verbatim from §0.3; the §0.2 corrections verbatim; the V-3a
    divergence-register line (fork spellings: `exclusive`, `unsafe
    permissive`, `unsafe import`, `unsafe class`, `addr` restored, the
    prefix `unsafe` forms, `Core.Plain`/`Guarded`/`Box`/`Send`/`Sync`/
    `Freeze`/`Relocatable`/`Lifetime` names; and the three dated narrowings
    of accepted text — p005434:82, p005434:663, arithmetic.md:155-158 —
    each a rename or a one-paragraph amendment away from an upstream
    decision); the residue items by title with the ids allocated at
    discharge; the R29(a) auto-adoption note and the two-document-review
    rule (D-SAFE-23). **Count check for this file:** before H2 2 / H3 44 /
    H4 1 / H5 6, dash items 23, ordered 0; after H3 must be exactly 45 and
    every other count unchanged (the new entry uses bold labels, not
    sub-headings, and its lists are dash items — record the new dash count
    and verify it equals 23 plus the number of items the entry adds); the
    pre-existing manufactured H3 at :6658 stays (§0.2 item 8). ORCHESTRATION
    stamp: header "Last updated" paragraph, the branch table row
    `claude/carbon-fork-0-1-safe` ("MERGED — SAFE-1 docs, F-013; gap row 89
    DONE; stubs stay SKIP until W-129"), next actions (W-129 first when an
    arbiter exists).

## Hand-off notes for the writer

1.  Read §1 and §0.3 first; the pages restate them. Do not re-derive rules
    from the panel record — it is history; where the record and §0.3
    differ, §0.3 wins (it is the synthesis).
2.  Use the verified anchors in this plan; re-open each cited file before
    quoting it on a page (line numbers move; the pages cite file:line of
    trunk at the writer's base commit and say so once in the status
    paragraph).
3.  Every page: license block, the toc marker pair that the markdown-toc
    hook fills (never write that pair in prose or in a code span: the hook
    matches it anywhere and generates a table of contents between the two,
    which is what happened to this plan's first prek pass), Overview,
    the status paragraph (F-013; toolchain status; stage), the sections of
    §2, the Implementation-staging table (only the rows the page owns),
    Decisions (D-SAFE ids), Alternatives (name the attempt and the judge's
    reason), References, External facts (D-SAFE-22; put the status column
    in; verify what you can and say how).
4.  R31 before you write: no line may begin with `#NNNN`, `*`, `+`, `-` (unless
    a real list item) or `N.` (unless a real ordered item); write "PR 51",
    "proposal 257", "p005434"; keep code spans short so none wraps; spell
    deltas as words ("plus two") or inside spans; emphasis `_x_`/`**x**`;
    headings never end in `.`, `,` or `;`; list items are a dash, three
    spaces, then the text, nested by four spaces (the style hook also
    rewrites the three-letter abbreviation of "consistency" to
    "disadvantages" and collapses spaces inside code spans — spell
    "consistency" out and never encode whitespace in a span).
    check-google-doc-style rewrites the Latin abbreviations, the three-letter
    synonym of "by way of" and the short forms of "repository" even inside
    code spans and fences — do not use them (write "for example", "that is",
    "by way of", "repository"), or fence a verbatim quote between the
    column-0 ignore/resume markers (precedent fork/w078b/plan.md:31-34).
5.  Worked examples are the contract (§4.1): keep the EX-ids, keep the
    "today's syntax"/NEW marks, keep the regression set verbatim.
6.  Nothing under proposals/; nothing in toolchain/, core/, or program
    bodies; the two SKIP lines are the only conformance edits (§2.11), and
    `runner.py --self-test` must pass after each.
7.  Commit per §3 with the §8.1 records in each message; owner author, Claude
    co-author; push the branch; open the PR with the fold record and the
    review verdicts linked; do not merge without the two document reviews.
8.  Dates: replace every "2026-10-DD" with the commit date.

## Design panel record (three attempts, two judges; verbatim where scored)

**Attempt A — "Strict Carbon by default: owners, loans, and operation-tied
`unsafe`" (Rust-shaped).** Thesis: Strict default (file Strict unless
`unsafe package`, body unless `fn F() -> T unsafe { }`); type safety static
with every unsafe op spelled; initialization by definite-assignment over
unformed plus release zero-fill; spatial fail-stop in every mode; temporal by
a borrow checker over loans on places with `bound`/`bound(a)`; mutation by a
three-kind lattice — exclusive `T*`, `const T*` (re-meant as shared-immutable),
NEW `shared T*` — with an Ante-style no-invalidation rule and
`SharedAssignable`; auto `Send`/`Sync`; T1-T8 loans, T6 unverified deref
`unsafe *p`, T8 codegen honesty; Rust table where `shared T*` is "the one
durable gap"; stages 0-6. Named divergences: `T*` exclusive by default,
`const` acquiring "shared", all races prevented, arithmetic wrap, `.unsafe`
member spelling.

**Attempt B — "Places, projections and shared cells" (MVS core from
`ref`/`val`/`var`/`bound`, Ante-style shared-mutable `T*`, origin tracking).**
Thesis: Carbon already has an MVS skeleton; add an exclusivity law over
places, reinterpret `T*` as shared-mutable with invalidation defined
structurally (`Core.Plain`), one annotation (`bound`) backed by origin sets
with explicit formation/kill/use/store rules and a fixpoint, inferred facets
(`Plain`, `Relocatable`, `Send`, `Sync`), definite initialization plus
zero-fill; `addr self` restored; no exclusive pointer _type_ (deliberate);
`Core.Guarded(T)` as the one opt-in runtime check; `Core.Box(T)`; MS-5
(plain-field writes during a non-`Plain` value binding erroneous, not
prevented); Permissive = Strict with three assumed facts; Rust table with
`Shared<T>`/`SharedView<T>` safe wrappers; S0-S5 stages.

**Attempt C — "Ratchet: hardened runtime core now, annotated borrows later".**
Thesis: three stages; stage 1 (0.1-deliverable) hardened type/init/spatial
(fail-stop bounds, zero-fill, div-zero fail-stop) plus a Strict mode whose
only temporal rule is the non-escaping pointer rule (P1/P2/P3); stage 2 adds
`exclusive ref` and `derived(...)` on signatures with a function-local
region analysis; stage 3 thread markers; Permissive the 0.1 default with
`package Main strict;`; `unsafe import`; `unsafe fn` bodies Permissive;
closes the lifetime TODO by stating 0.1 has no destructive move; Rust interop
at the cxx level in 0.1; gap-row/ledger mechanics spelled in the house format.

**Judge 1 — winner B, narrowly over A** (scores A 38: fid 9, conc 9, cpp 7,
impl 6, consistency 7; B 40: 8, 9, 7, 8, 8; C 36: 6, 7, 8, 9, 6). "On the two
most-weighted axes they tie ... B wins the tiebreak on implementability (one
dataflow pass, no named lifetimes, library-only `Guarded`/`Box`) and on the
Rust analysis (a safe `Shared<T>` spelling where A declares a durable gap). C
is not a candidate base: its 0.1 scope leaves temporal/mutation
'provisional-with-syntax'". Grafts from A: the explicit exclusive pointer
kind as a third kind beside shared `T*` and `const T*` (resolving B's fatal
gap, keeping `T*` shared so README.md:3757-3758 and the prelude's `ptr: T*`
stay sound); the T5 `bound` contract with `bound(a)`/`Core.Lifetime` pinned;
callee contract versus body mode; Permissive warning twins; `unsafe impl`
and the taxonomy sentence; the four-part Rust verdict. From C: `unsafe
import`; the P1/P2/P3 first enforceable subset; the arithmetic answer with
W-113's fixed text; `Core.DynCast`; the gap-row/ledger mechanics. Fatal: A's
`T*`-exclusive and `const` re-meaning; B's no-exclusive-pointer and
un-ratified MS-5; C's provisional temporal/mutation and lifetime-TODO
closure, `derived`/`exclusive ref`, Permissive default; all three: training-
knowledge facts cited normatively.

**Judge 2 — winner A** (scores A 36: fid 8, conc 8, cpp 7, impl 6, consistency
7; B 33: 7, 8, 5, 7, 6; C 31: 5, 6, 8, 7, 5). "It is the only design whose
central mechanism I could not refute with a program ... B is simpler to
implement but its single-pointer-kind choice contradicts p005434:710-713/826 and
makes `ref self` ... unreachable through a pointer in Strict; repairing that
means adding the exclusive pointer kind, which turns B into A. C's stage-1
temporal claim is unsound against `Core.Slice`." Grafts from B: the Store rule;
SS-4's explicit prelude churn as a filed residue; `Core.Plain` as the normative
`SharedAssignable`; `Core.Guarded(T)`; "Permissive is Strict with assumed
facts"; `Core.Relocatable`; IS-2's `extend base` closure. From C: the rollout
posture with `--default-safety-mode`; `unsafe import`; the S1a/S1b executable
0.1-optional slice; `unsafe class` interim; the per-row Stage column. Fatal: C's
stage-1 soundness claim (counterexamples `Leak`, the scope-escaping
`FromArray`); B's "no `ref` from `*p`"; A's T5(a) without a store rule (the
global `Holder` program); any synthesis keeping the prelude view types as they
are; C's closure text for the lifetime TODO.

**Synthesis rule applied here:** base B (judge 1's winner, judge 2's
"B plus the exclusive kind is A"), grafts as listed by both judges, every
fatal item resolved by a named D-SAFE (A-fatal → D-SAFE-7; B-fatal →
D-SAFE-7/8/17; C-fatal → D-SAFE-10/11/13/21; training knowledge →
D-SAFE-22; prelude churn → D-SAFE-14/W-128). Where the two judges' winners
differ, the difference is exactly the exclusive pointer kind, which both
asked for; the synthesis has it.

## Review fold record (rev 1, 2026-10-12)

| Finding | Fold |
| --- | --- |
| (none yet — the two plan reviews have not run) | — |

## Sign-off

Left for the two plan reviews (R29(c)). On sign-off this section records the
rev, the date, the verdicts (OK / NEEDS-FIX with cited findings) and the fold
marks; later amendments continue to be folded in place, each marked
"(amended <date>, review fold: ...)".
