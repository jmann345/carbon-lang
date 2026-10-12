<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Safe-Carbon plan: Strict by default, shared `T*` plus `exclusive T*`, loans with `bound`, operation-tied `unsafe` (SAFE-1, W-063)

**Status:** rev 3, 2026-10-12 — the two plan reviews (R29(c)) have run:
review A REJECT (three BLOCKERs, eight MAJOR, nine MINOR), review B
APPROVE-WITH-AMENDMENTS (seven MAJOR, eight MINOR), and the focused re-review
of the three BLOCKER folds returned APPROVE-WITH-AMENDMENTS (two MAJOR, five
MINOR); every finding is folded in place, each marked "(amended 2026-10-12,
review fold: A-n / B-n)" or "(amended 2026-10-12, re-review fold: RR-n)", the
two fold records precede Sign-off, and rev 3 is signed off for
implementation. Branch `claude/carbon-fork-0-1-safe` off
trunk 0bdce60a5 ("ORCHESTRATION: UA-2 is PR 51, held open pending a gate").
Trunk's floor is **128 PASS / 0 FAIL / 22 SKIP over 150 programs**, 48/56
bullets (fork/conformance/out/scoreboard.json `totals`, generated 2026-10-06;
fork/ORCHESTRATION.md:56-57 and :343 and fork/gap-analysis.md:18-20 agree —
re-pinned, B10); gap-analysis header **30 DONE / 21 PARTIAL / 4 MISSING / 1
DESIGN-ONLY** across 56 (fork/gap-analysis.md:18); ledger max id on trunk
**W-125** (fork/inventory/work-items.json, last two ids W-124, W-125), with
**W-126 and W-127 already allocated on the held UA-2 branch**
(fork/ORCHESTRATION.md:35, re-pinned, B10), so this workstream's residue ids
start at W-128 today (§8.5 allocates at discharge over every live branch
head, B11). All docs, proposal, prelude, toolchain and fork line numbers in
this plan are against trunk 0bdce60a5 and were opened and re-verified for this
plan; where the ledger's citations are stale the correction is in §0.2. This
workstream makes **no toolchain, prelude, golden or program-body change**
(amended 2026-10-12, review fold: B7 — "docs-only" withdrawn: the PR also
edits two conformance SKIP lines and fork/inventory/work-items.json, which
make upstream's `has_code` filter true, .github/actions/test-setup/action.yml
:35-36 `'!{**/*.md,LICENSE,CODEOWNERS,.git*}'`); milestones.md:242 excludes
implementation from the bullet and milestones.md:267 defers memory-safety
implementation to 0.2, so §4 has no testdata matrix and §6 has no golden
churn; the verification arbiter is local `uvx prek run` plus the R31 count
checks, `runner.py --self-test` for the two SKIP lines and a `json.load`
parse for the ledger, the nightly compile step of §8.1a for the today's-syntax
examples, plus two adversarial document reviews (§8). R28 note: the container
cannot build the toolchain and **GitHub Actions on the repository is
DISABLED** (fork/ORCHESTRATION.md:13-18; fork/decision-log.md:6521-6544), so
no hosted check runs on this PR; upstream's `tests.yaml:100-101` would run
bazel for this PR (`has_code` is true), and nothing it builds is touched —
the local gate is therefore a **stated deviation from R23's sentence that the
runner-side prek is the authority**, recorded in the F-013 entry (D-SAFE-23),
with the local prek result and the R31 count outcome recorded in every commit
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
| 35 | Strategy lineage (amended 2026-10-12, review fold: A-17) | FIXED; cited by the pages' References | p000196:42-48 (compile-time proven safety increasing incrementally; dynamic checks "amenable to being optimized away or being manually disabled for performance-critical use cases" — the posture SP4's per-site `GetUnchecked` keeps and A-13(c) names); p004880:60-70 ("Update our safety strategy, and establish a detailed strategy for memory safety"; "Design for compile-time & type-system based temporal and mutation safety" — the commitment the milestone bullet discharges); safety/README.md:297-300 lists proposal 196 as a live reference |

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

-   **D-SAFE-1 — Taxonomy.** _Mutation safety_: a mutation of an object never
    invalidates a live access path to that object or its sub-objects
    (iterator and reference invalidation, change of a sum's alternative under
    a payload reference) — an access property in terminology.md:156-176's
    phrasing, enforced by the aliasing discipline (exclusive-XOR-shared access
    plus the no-invalidation rule, D-SAFE-9). _Data-race safety_
    (terminology.md:174-176) is its cross-thread companion, enforced by the
    same facets (D-SAFE-16), not a sub-case: two threads writing one `Plain`
    `i32` race without invalidating anything (amended 2026-10-12, review
    fold: A-19 — the rev-1 "mechanism" definition and the "cross-thread case"
    nesting withdrawn). terminology.md gains the entry; safety/README.md
    :131-135's list gains a "Mutation safety" row that names data-race safety
    as its thread-crossing companion. This closes the gap between
    milestones.md:240 and terminology.md:156-176 (§0.1 row 6). Break
    condition: upstream adds a conflicting definition of "mutation safety" to
    terminology.md — the fork entry is renamed, the rules are not reopened.
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
    read, whose result is a ⊥ pointer — T6, RR-1), `unsafe s[i]` where `[]`
    resolves to an `unsafe fn`. The prefix
    applies to the innermost call, dereference, subscript or field read that
    follows the keyword — in `unsafe x.M(args).N()` it marks `x.M(args)` only,
    and `unsafe (x.M(args).N())` widens it by parenthesizing; an infix or
    assignment operator that resolves to an `unsafe fn` (a C++ member
    `operator=`, `operator+`, `operator+=`: `c = 42` at fork/conformance/
    programs/interop/cpp_operator_import_assignment.carbon:26) is spelled with
    the parenthesized form, `unsafe (c = 42)`, `unsafe (a + b)`, `unsafe (a
    += b)`, the parse note being that `unsafe (` begins a prefix expression
    whose operand is the parenthesized expression's outermost operator
    application (amended 2026-10-12, review fold: A-16, A-12). This supersedes
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
    attempt-C graft both judges asked for); importing a Strict library needs
    no marker. `import Cpp ...` needs no marker either, and that is a named
    asymmetry against README.md:122-124's one-rule ask (amended 2026-10-12,
    review fold: A-13(d)): a by-value C++ function is called unmarked while a
    by-value function of a Permissive Carbon library needs `unsafe import`,
    because the `Cpp.` prefix on every C++ name is itself the audit marker an
    `unsafe import` would duplicate, and D-SAFE-18 marks every
    pointer-carrying C++ call at the operation. Attempt A's driver flag alone
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
    sources only in comments (three testdata files; `grep -rnw`), `addr` in
    CHECK lines and comments and in **one source line**,
    third_party/examples/re2/re2.carbon:769 `private fn Init(addr self: Self,
    pattern: StringPiece, options: Options);` — the historic spelling, in a
    file no target builds (amended 2026-10-12, review fold: B9; the rev-1
    "only in CHECK lines and comments" claim withdrawn here, in §6 and R-7);
    the fork chooses `addr self: Self*` over that historic `addr self: Self`
    because the receiver is the address-taking form p005434:1226-1237
    contemplates ("one of the pointer semantics"), so its declared type is
    the pointer type the body sees; `permissive` nowhere. Break condition: a
    prelude or interop API that needs a fourth kind (exclusive-const) — added
    additively; the `exclusive` spelling is a mechanical rename.
-   **D-SAFE-8 — `ref` bindings inherit the kind of their source.** A `ref`
    formed from a place is exclusive access (p005434:82, :173-180 kept); a
    `ref` formed from `*p` inherits `p`'s kind: exclusive from `exclusive T*`,
    shared-mutable from `T*` (M3 applies to uses of it), const from `const
    T*`. So p005434:717-720 (`Valid1(bound p: i32*) -> ref i32 { return *p;
    }`; re-pinned, B10) and :826 (`ValToRef`) stay valid in both modes (judge
    2 fatal B), the result being a shared-kind `ref`. A `ref` or result whose
    loan set mixes kinds — p005434:772-779's `Conditional(b, bound ref r: C,
    bound p: C*) -> ref C` carries `{(r, exclusive), (*p, shared)}` — has the
    **weakest** kind (shared if any loan is shared, const if any is const),
    and T4 applies to every place in the set: program `Pick` in §4.1 (a
    shared-kind `ref` to `y` obtained from `Pick(false, x, q)` cannot be
    assigned a new `Buf` while `q2->AsSlice()` views `y`) is
    `StrictInvalidatingThroughShared` — a non-`Plain` assignment through
    shared-kind access, rejected even with no live view, the view `v` being
    a second reason (amended 2026-10-12, review fold: A-5; the diagnostic
    name corrected from `StrictSharedBorrowInvalidated`, re-review fold:
    RR-7).
    `noalias`/`captures(none)` are emitted
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
    (classes.md:1941-1944; details.md:4254-4290), defined **structurally** to
    match the invalidation definition above (amended 2026-10-12, review fold:
    A-3, B2, B12): a type is `Plain` when (i) it is `Copy` with trivial
    destruction — no user destructor in either spelling, classes.md
    :1852-1870's `fn destroy(self)` / `fn destroy(ref self)` or the prelude's
    `impl as Destroy { fn Op(ref self) }` form (buf.carbon:58-60, D-SL-16; the
    mutation page discloses in one dated sentence that the fork's prelude uses
    the interface form classes.md does not name) — and (ii) every sub-object
    exists **and is formed** at a fixed offset regardless of the value
    (amended 2026-10-12, re-review fold: RR-6: `DefaultOptionalStorage(T)`
    is {`MaybeUnformed(T)`, `bool`}, optional.carbon:140-143, and the
    pointer storage is the one-word `MaybeUnformed(T*)`, :188-189 — every
    sub-object has a fixed offset and what varies is formedness, so the
    exclusions below follow from (ii) only with that word), closed under
    arrays/tuples/structs/classes of `Plain` fields. Membership table (§2.7):
    integers, floats, `bool`, `char`, all three pointer kinds, `Slice(T)` and
    the prelude's `String` (= `str`: a non-owning `{Char*, i64}` with `impl as
    Copy`, no `Destroy`, `impl String as UnformedInit`, string.carbon:16-28 —
    B2) **are** `Plain`; `Buf`, `Box`, payload `choice`s, `Core.Optional(T)`
    for every `T` (a class over `MaybeUnformed`/null-niche storage whose
    payload sub-object exists only for `Some`, optional.carbon:13-60,
    :186-203), `MaybeUnformed(T)` and unions with a pointer-carrying field
    (unions.md:241) are **not** — so `*d = Optional(i32*).None()` through a
    shared `Optional(i32*)*` is `StrictInvalidatingThroughShared`, and M5's
    "alternative cannot change while a payload reference lives" is a
    consequence of (c) rather than a contradiction of it (program `Alt2` in
    §4.1). The rev-1 representational wording ("`Copy` with trivial
    destruction, no `choice` payload", which admitted `Optional(T*)` and
    listed `String` as non-`Plain`) is withdrawn. Attempt B's definition
    replaces attempt A's `SharedAssignable` (judge 2's graft). This is
    p005914:198-202 made checkable: iterators hold `T*`, `Push` is `ref self`
    and so "precludes any outstanding shared mutable pointers". Break
    condition (R-1): a migration corpus in which more than 30 percent of C++
    non-`const` methods end up exclusive (the `Optional(T*)` exclusion makes
    linked-structure heads exclusive-only through pointers — counted in that
    corpus) — then a finer rule (assignment through `T*` when no sub-loan
    into the old value can exist, needing per-field loan tracking) or an
    `unsafe impl T as Core.Plain` opt-in.
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
    value binding of a non-`Plain` type is a shared loan — from a
    materialized temporary it owns the storage instead, D-SAFE-17, RR-5 —
    of a `Plain` type an eager copy with no loan — D-SAFE-17, M8; `p->f`,
    `(*p).f`, `case
    .Some(ref v)`, `Subslice`, `FromArray`, `AsSlice` produce sub-loans;
    loans reached through an owning indirection — a `Buf`'s elements, a
    `Box`'s pointee — are _interior loans_ on the owner). **Copies preserve
    loans** (amended 2026-10-12, review fold: A-2): a copy, relocation,
    `ImplicitAs`/`As` conversion or `Copy.Op` of a loan-carrying value carries
    the same loan set — the prelude's `impl forall [T: Copy] T as
    ImplicitAs(T)` (as.carbon:38-40) and every `Copy`/`ImplicitAs` impl are
    not loan boundaries, so `let t = s; return t;` of a view is exactly
    `return s;`, and D-SAFE-11(a)'s "no `bound` parameter → free result"
    applies to functions that _produce_ values, never to the identity
    conversions a `let`, a `return` or an argument pass goes through. A copy
    of an **exclusive** carrier is never a second live exclusive carrier of
    the same loan (amended 2026-10-12, re-review fold: RR-3): a same-kind
    copy — `let q: exclusive i32* = p;` for `p: exclusive i32*` — is a move
    of the loan, the source dead until the copy's last use (NLL, T3), and an
    exclusive carrier reached through a shared path (a `Plain` field of type
    `exclusive T*` read through a shared pointer) is copied as a reborrow at
    shared kind, so T8 never sees two live exclusive carriers of one loan.
    **Reborrow** (amended 2026-10-12, review fold: A-4): forming a shared loan
    from an exclusive carrier — the `exclusive T*` → `T*` downgrade, a
    `bound self` by value, an `addr self` call, `&*p` at shared kind —
    _suspends_ the carrier's exclusivity; until every derived loan is dead the
    carrier may be used only at shared kind (reads, `Plain` writes, `addr` and
    `const` methods, further shared loans), and an invalidating use of it is
    `StrictSharedBorrowInvalidated` — which is how EX-M-1 reads: `vec->Get(0)`
    while `a` lives is a shared use, `vec->Push(3)` is legal only once `a`,
    `b` and `first` are dead. T3 liveness: from creation to last use of any
    carrier (NLL on SemIR's block graph); at scope exit the destroyed `var`'s
    loans must be dead (`StrictBorrowOutlivesPlace`). T4 conflicts: a live
    exclusive loan excludes every other access to overlapping places except
    through the suspended carrier at shared kind (the reborrow clause); a
    live shared loan excludes exclusive loans and invalidating operations
    (D-SAFE-9), and an invalidating operation on `P` kills every interior
    loan on `P` (`StrictSharedBorrowInvalidated`,
    `StrictExclusiveBorrowConflict`); for a carrier whose loan set mixes
    kinds, T4 is applied to every place in the set at the weakest kind
    (D-SAFE-8, A-5). T5 is D-SAFE-11. **Store rule (attempt
    B's, judge 2's fatal-flaw repair for attempt A's T5(a)):** storing a
    loan-carrying value into a place `P` (field write, store through a
    pointer, container insert through a `bound`-free API, global) requires
    every loan to outlive `root(P)` — by lexical nesting for locals, by
    D-SAFE-11 for parameters, and a free or ⊥ destination accepts only free
    loans (`StrictStoreOutlivesSource`); so `let h: Holder* =
    GetGlobalHolder(); h->p = &y;` is rejected. T6 the unsafe boundary: the
    result of `unsafe as` from a non-pointer, of any `unsafe fn` or
    unannotated C++ call, anything read through an unverified pointer, **a
    value of pointer-carrying type read from a union field (`unsafe u.p`),
    and the pointer `unsafe &u.f` itself, ⊥ on formation for every field
    type** (amended 2026-10-12, review fold: A-1: the union read discharges
    only the punning obligation, unions.md:445-447, and a write `u.n =
    0x1234` through another field is safe, so the loans stored in `u` say
    nothing about the bytes read back — program `Wild` in §4.1 is the
    README.md:83-87 case; amended 2026-10-12, re-review fold: RR-1: rev 2
    marked the value _loaded_ through `unsafe &u.f` rather than the pointer,
    which is not modular — a Strict callee that returns the pointee of a
    `bound` pointer-to-pointer parameter is correct code that cannot see the
    union, and 11(a) would give its result over `unsafe &u.p` the non-⊥ loan
    set {(u.p, shared)}; with the pointer itself ⊥, because a pointer into a
    union aliases every field (unions.md:417-418), passing it to a `bound`
    parameter, dereferencing it, binding a `ref` through it and every copy
    of it fall under the next sentence, and a call result whose `bound`
    arguments include a ⊥ carrier is ⊥ — program `Wild3` in §4.1), and every
    pointer
    field of an `unsafe class` (D-SAFE-11(g)) is ⊥; a ⊥ pointer may be copied,
    compared, stored and passed, but `*p`, `p->m`, `ref` binding, view
    formation or passing it to a `bound` parameter needs `unsafe *p`
    (D-SAFE-5) whose obligation is that the storage outlives every derived
    use; `unsafe as` between pointer types preserves the loan set of its
    operand, so a conversion never extends a lifetime (README.md:83-87), and
    its obligation is that **a valid, complete object of the destination type
    lives at that address for the loan's lifetime** — extent included, so
    `(&x) unsafe as i64*` for `x: i32` is the caster's bug, not a checker hole
    (amended 2026-10-12, review fold: A-14; stated on type_safety.md). T7 is
    D-SAFE-12. T8 codegen honesty: `noalias`/`captures(none)` are emitted for
    exclusive loans only where the checker established them —
    intra-function, and on `ref`/`exclusive T*` parameters of functions that
    are **not exported to C++, not address-taken (no function value crosses
    to C++ or Permissive code), and whose every Carbon call site in the
    package is Strict-checked** (a whole-package fact; otherwise never), per
    p005434:865-870 — amended 2026-10-12, review fold: A-7: the fork's own
    corpus has C++ calling `fn Bump(ref self, n: i32)` (fork/conformance/
    programs/interop/cpp_export_method.carbon:31-33 called from `inline Cpp`)
    and `std::thread(Work)` taking a Carbon function value
    (cpp_thread_carbon_fn_diff.carbon:38-45), and both are callers the
    whole-package fact must count; Permissive or C++ callers that alias such
    a parameter produce erroneous behavior, never UB (p005914:204-222). First
    enforceable
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
    loan set of a call's result is the union of the loan sets of the arguments
    passed to `bound` parameters (`self` included), with kind = the parameter's
    kind (`ref`/`exclusive T*` → exclusive, value/`T*`/`const` → shared), a
    mixed set taking the weakest kind (D-SAFE-8, A-5); a function with no
    `bound` parameters returns free values — subject to the Store rule, and
    never read as applying to a copy, conversion or `Copy.Op` of an existing
    value (T2's copies-preserve-loans clause, A-2), so a prelude function
    whose result can carry a loan from a parameter — a view of `self`, a `T`
    payload returned from `self`, a `T` argument stored into the result —
    without `bound` on that parameter is a W-128 defect under SP3's signature
    rule (RR-2), not a loan boundary; a ⊥ argument to a `bound` parameter
    makes the result ⊥, after the `unsafe` T6 demands for the pass (RR-1).
    (b) In the callee a non-`bound` pointer/`ref` parameter may not
    escape (not returned, not stored, not passed as a `bound` argument whose
    result escapes: `StrictEscapeOfUnboundParam`); a `bound` parameter may
    escape only into the return value. (c) Returning a loan on a local,
    temporary or `var` parameter is `StrictDanglingReturn` (p005434:698-713's
    erroneous cases become hard errors in Strict). (d) For the duration of a
    returned loan the bound argument stays borrowed in the caller at the
    parameter's kind: p005434:826-830 asks for the bound parameter to be
    "immutable for the duration", which this design **narrows** to "not
    invalidated" — a shared-kind bound argument stays writable in its `Plain`
    fields through other aliases (the D-SAFE-17 narrowing applied at a second
    site; a dated narrowing on the temporal page, in §4.3's list and in the
    F-013 entry — amended 2026-10-12, review fold: A-13(b)). (e) Impls may drop
    but not add `bound` (p005434:782-806, kept) — which is why the prelude's
    interfaces `IndexWith.At` and `Copy.Op` carry `bound self` themselves
    (SP3, RR-2). (f) Named form, pinned now and
    implemented at stage 6: `bound(a)` with `[a: Core.Lifetime]` as a deduced
    parameter — `fn Push[a: Core.Lifetime](list: bound(a) List*, node: bound(a)
    Node*)` lets `list->head = node` pass the Store rule; `class Iter(T: type,
    a: Core.Lifetime)` holds `bound(a)` pointer fields; bare `bound` is the
    elision form. The rule behind the example (amended 2026-10-12, review fold:
    B13(e)): one name is one loan set — every argument passed to a `bound(a)`
    parameter, every `bound(a)` field of the receiver and the result join a
    single set whose kind is the weakest among them; a store from a place in set
    `a` into a place in set `a` passes the Store rule; two names are unrelated
    sets, and an outlives relation between names (`a: b`) is deferred to the
    stage-6 plan (W-134), with the bare-`bound` stage expressing none. (g)
    Interim (attempt C's graft): until stage 6 a Strict class with a non-owning
    pointer field is declared `unsafe class`: its invariant is the author's,
    every construction site in Strict is `unsafe` because construction may store
    non-free loans, its pointer fields are ⊥ (T6: reads through them need
    `unsafe *`), and the Store rule treats them as a ⊥ destination that accepts
    only free loans — so EX-TM-4 `Store`'s `h->p = &y` is
    `StrictStoreOutlivesSource` by rule (amended 2026-10-12, review fold: A-15),
    closing attempt A's R4 window with an auditable spelling. Break condition:
    upstream amends p005434's `bound` with different semantics — a V-3 review;
    the fork keeps whichever is lower-divergence and records the delta.
-   **D-SAFE-12 — Temporaries: diagnose, do not extend.** A `ref` binding or
    `bound` result may carry a loan on a temporary only until the end of the
    full-expression; later use is `StrictBorrowOfTemporary`, with the fix
    p005434:1140-1142 suggests (`var x = ...;`). This makes the C++ divergence
    at docs/design/interoperability/philosophy_and_goals.md:456-465 (full
    path, review A) a compile error, never a dangling pointer; today's
    toolchain already rejects `let ref r: Core.String = MakeString();` by
    p005434:173-175's rule ("cannot bind durable reference to non-reference
    value of type `str`", nightly 2026.10.12), so `StrictBorrowOfTemporary`
    is reachable only through a `bound` result or a pointer formed from a
    temporary (EX-TM-7b; amended 2026-10-12, review fold: B1); the
    builder-chain idiom values.md:414-421 flags stays
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
    projection is the existing `x unsafe as T` (the read form
    optional.carbon:200 `value unsafe as T*` uses; :194 is the assignment
    form `result unsafe as T* = self;` — re-pinned, B10); in Permissive `&x`
    is allowed and the callee is _assumed_
    to form `x` (p000257:102-104 "Taking the address is fine"), reads of
    unformed storage being erroneous-with-a-defined-value by I5. I4 moves
    (makes README.md:2160-2168 concrete): `~x` yields an initializing
    expression with `x`'s old value and leaves `x` unformed; the default move
    of a class is a bitwise relocation followed by marking the source
    unformed; `impl as Core.Move` customizes, with the signature `interface
    Move { fn Op[ref self: Self]() -> Self; }` whose contract is "returns the
    old value as an initializing expression and leaves `self` unformed" and
    whose default impl for `Relocatable` types is the bitwise relocation
    (amended 2026-10-12, review fold: B13(d)); only entire reference
    expressions may be moved from (values.md:117-118; `*p` stays future work,
    :119-122); after `~x` I2 forbids use until reassignment — p000257's
    middle ground, neither Rust's nor C++'s. `Core.Relocatable` is a
    compiler-determined facet defined structurally (amended 2026-10-12,
    review fold: A-20): all fields `Relocatable`; the three pointer kinds,
    integers, floats, `bool`, `char` are; imported C++ types are iff
    trivially relocatable; `unsafe impl T as Core.Relocatable {}` opts a
    pinned type out or in — self-reference is a property of values, not
    types, and what makes relocation safe is T4 (a self-loan is a live shared
    loan on `x` that forbids the invalidating `~x`), so "no self-pointers" is
    not a criterion. The facet decides by-value crossing to Rust
    (D-SAFE-19). I5 every mode: Release `make_uninitialized` zero-fills the
    whole object including padding (p000257:355-358; README.md:2147-2149's
    hook, promoted from "hardened" to the Release baseline, which
    p005914:87-88 permits — a dated departure disclosed by a §2.9-style
    blockquote at README.md:2147, amended 2026-10-12, review fold: A-13(e));
    Debug poison-fills and
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
    length and a loan: `FromArray` takes `bound p`; `Data`/`Get`/`AsSlice`,
    **`Subslice`, `Slice(T) as ImplicitAs(Slice(const T))`'s `Convert`
    (slice.carbon:80-84), the C++-container `C as
    ImplicitAs(Slice(C.Element))`'s `Convert` (:100-106) and every other
    producer whose result views `self`'s storage** take `bound self`
    (amended 2026-10-12, review fold: A-2 — programs `Launder1`/`Launder2`
    in §4.1). **The W-128 audit rule** (amended 2026-10-12, re-review fold:
    RR-2 — rev 2's receiver-only grep, a view- or `Self`-returning function
    whose receiver is not `bound`, missed results of type `T` and
    loan-carrying non-receiver parameters): W-128 reviews every prelude
    signature under 11(b)/(c) as if its body were Strict-checked, the body
    itself trusted (D-SAFE-18) — every parameter, receiver, value or pointer,
    including a type parameter `T` that may be instantiated to a
    pointer-carrying type, whose loans can reach the result or be stored into
    `self` is marked `bound`, or the function becomes `unsafe fn`; because an
    impl may drop but not add `bound` (p005434:782-784), the interface
    declarations `IndexWith.At` (core/prelude/operators/index.carbon:9) and
    `Copy.Op` (core/prelude/copy.carbon:10) carry `bound self` so that impls
    may keep it — the prelude's primitive copies and identity conversions
    stay governed by T2 (loan set preserved; RR-3's rule for exclusive
    carriers), the interface's `bound self` being what lets a user-written
    `Copy.Op` keep its loan without 11(a) reading the result as free. Named
    hits today: `Optional(T).Get` (result `T`, optional.carbon:40-42) and
    `Optional(T).Some` (a `T` argument stored into the result, no receiver,
    :34-36), `OptionalStorage.Get` (:22), `Try.Branch` (:69-78, the `o?`
    path), `Buf(T).Make` (`fill: T` stored, buf.carbon:28), `Buf.Get` (:45),
    `Buf.At` (:72-75), `Slice.At` (slice.carbon:74-77) — programs
    `Launder4`/`Launder5` in §4.1 (`Core.String` is audited the same way);
    `UnsafeMake` becomes `unsafe fn
    Make(p: T*, size: i64)` with slice.carbon:29-30's comment as its stated
    obligation — the **prelude churn is a named residue item (W-128), gated,
    never assumed in an example** (judge 2 fatal D). SP4 unchecked access is
    `unsafe fn GetUnchecked[bound self: Self](i: i64) -> T` on `Slice`/`Buf`
    (the W-114 opt-out README.md:223-226 promises); no build flag disables
    checks — README.md:260-262's promise that Carbon "will provide a way to
    disable the default hardening in release builds, but not in a supported
    way" is **withdrawn by the fork, dated** (amended 2026-10-12, review
    fold: A-13(c)): the per-site `unsafe fn GetUnchecked` is the only
    disable, which keeps p000196:45-48's "manually disabled for
    performance-critical use cases" at the site rather than the build. SP5
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
    compiler-determined facets, each defined structurally (amended
    2026-10-12, review fold: A-10, B14 — these are the fork's definitions;
    their soundness argument is Rust's auto-trait argument, a D-SAFE-22
    "External facts" item, UNVERIFIED until the writer cites it): a type is
    `Send` when all fields are, and `Sync` when all fields are; a `T*`
    (shared-mutable) field or a `Slice(T)` field makes the type **neither
    `Send` nor `Sync`** (a shared-mutable reference is thread-local — the
    Ante rule, from training knowledge, D-SAFE-22 — and `Slice` reaches a
    `T*` through `Data(self) -> T*`, slice.carbon:37, even from `const
    Slice*`, because `const` is API-subsetting only, as.carbon:41-43);
    `exclusive T*` is `Send` iff `T: Send` and `Sync` iff `T: Sync`; `const
    T*` is `Send` iff `T: Sync` and `Sync` iff `T: Sync`; `Core.Atomic(T)` is
    `Send` and `Sync` and not `Freeze`; `Freeze` = no interior mutability;
    `Core.Guarded(T)` is neither; imported C++ types are neither unless
    annotated; `unsafe impl T as Core.Send {}` / `as Core.Sync {}` opt in.
    `Sync ⇔ const Self*: Send` is then a consequence, not the rule (the rev-1
    pair of sentences was circular). Enforcement is at thread-crossing APIs
    as generic constraints, staged facets → `--strict-concurrency=warn` →
    `error` (p005914:191-196), **with the thread-boundary lifetime rule**
    (amended 2026-10-12, review fold: A-6): a thread-crossing API accepts
    only a free loan set (`'static` in D-SAFE-19's mapping) — `Core.Thread.
    Spawn[F: Core.Send & Core.Call](f: F)` requires `f`'s loan set to be free
    (`StrictBorrowOutlivesPlace` at the spawn otherwise) — or is a scoped
    API whose join lies inside the borrow (`Core.Thread.Scope(fn (ref s:
    Scope) { s.Spawn(...); })`, where the scope's loans are live until the
    closing join), so `Spawn(fn (var q: exclusive i32*) { *q = 1; }, &x)` on
    a local `x` is rejected (program `Race` in §4.1). Consequently Strict
    Carbon has no data races between Carbon-spawned threads — stronger than
    README.md:167-174 requires, permitted by :176-178 — and the "must" (no
    unsynchronized use-after-free) follows from D-SAFE-7 plus this rule
    **once the thread API's lifetime contract is fixed as above at stage 5**
    (the rev-1 "theorem" sentence lacked this premise). The 0.1 Permissive
    contract "races are UB" (threading-atomics.md:192-200, :476-480) is
    untouched: it describes Permissive code and C++ threads. Break
    condition: facet synthesis cannot see through imported C++ layouts — the
    C++ default (neither, unless annotated) already covers it.
-   **D-SAFE-17 — Value bindings through shared pointers (MS-5, ratified
    explicitly).** A value binding of a `Plain` type — from `*p` or from an
    owner — acquires eagerly (a copy, README.md:1319-1321) and carries no
    loan, so `let b: i32 = a; a = 2; return b;` is **accepted in Strict and
    returns 1** (EX-M-4a; values.md:456-468's erroneous reading does not
    arise, and the values.md:473-475 dated note says so — amended 2026-10-12,
    review fold: A-8, B3); a value binding of a non-`Plain` type, from `*p`
    or from an owner, is a shared loan on the bound object for the binding's
    NLL lifetime (T2) under which invalidating operations are
    `StrictSharedBorrowInvalidated` (T4; EX-M-4b) — this is M8 stated as a
    rule — while `Plain`-field writes through _other_ shared aliases during
    the binding remain erroneous (values.md:456-468) and are Debug-detected
    by a value-binding shadow flag: Debug keeps, in shadow memory keyed by
    object address (never in the object's layout), a per-object count of
    live non-`Plain` value bindings, incremented when the binding is formed
    and decremented at its last use as stage 4 computes it; a `Plain`-field
    write through `T*` or `addr self` whose target's count is non-zero
    reports `MutationDuringValueBinding` (amended 2026-10-12, review fold:
    B13(c)). A value binding of a non-`Plain` type initialized from an
    initializing expression — a materialized temporary, values.md:186-192's
    third source, neither `*p` nor an owner — takes ownership of the
    materialized storage, values.md:192's `var` rule applied to `let`, and
    carries no loan on it, so `let o: Core.Optional(i32) =
    Core.Optional(i32).Some(1);` followed by `o.HasValue()` on the next line
    is accepted; the loans carried _by_ the value are unaffected, which is
    why EX-TM-7b's view of a temporary `Buf` stays `StrictBorrowOfTemporary`
    (amended 2026-10-12, re-review fold: RR-5). Memory safety holds (plain
    fields carry no
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
    annotations → facets — the family is Clang's Thread Safety Analysis
    attributes (`capability`, `guarded_by`, `requires_capability`,
    `acquire_capability`/`release_capability`; names a D-SAFE-22 item): a C++
    class every one of whose data members is `guarded_by` a `capability`
    member imports as `Sync`, nothing else does (amended 2026-10-12, review
    fold: B13(b)); pointers returned by C++ are ⊥ (T6) — p005914:204-208's
    "no assumption that a call to C++ code won't save a copy of pointers" as
    a checkable rule. C++ `T&` → `T*` (shared, README.md:3757-3758);
    non-`const` C++ methods import as `ref self` (exclusive, invalidating —
    the conservative reading, callable through `exclusive T*`; through
    shared `T*` only as `unsafe`, or by way of `Core.Guarded`), `const`
    methods as const access; a future non-invalidation annotation on a C++
    method maps to `addr self`. The prelude's synthesized
    `CppRangeForIterate`/`CppContiguousRange` witnesses (the path
    cpp_iterate_generic_member_range.carbon:50-55 and the `C as
    ImplicitAs(Slice(C.Element))` impl take to `begin()`/`end()`/`data()`/
    `size()`) are **trusted prelude code**, Permissive-implemented behind a
    Strict signature like the rest of the prelude (D-SAFE-2), so §1.2's "an
    audit grep finds everything" reads "everything outside the prelude"
    (amended 2026-10-12, review fold: A-12). **R-8's contingency is decided
    now** (amended 2026-10-12, review fold: A-12 — measured on the fork's
    corpus as Strict files, nine of fourteen C++ call sites in six interop
    programs are unsafe under the bare rule, above the "more than half"
    falsifier before any pilot): the importer carries an explicitly trusted
    **allowlist of benign signature shapes** that need no marker — (1)
    by-value parameters and by-value returns; (2) `const T&` parameters of
    `Freeze` types; (3) the members of `std::atomic<T>` and `std::thread`
    that F-008 models (threading-atomics.md:192-212: `fetch_add`, `load`,
    `store`, the constructor taking a Carbon function value, `join`), the
    function value crossing being the A-7 export case (no `noalias`); (4)
    `std::span<T>`/`std::span<const T>` parameters when the Carbon argument
    is a loan-carrying `Slice` whose extent the Carbon side proves (the
    cpp_span_view.carbon:62-69 shape, SL-2). Everything else keeps
    `StrictCppCallUnannotated`; the allowlist is one table on the README
    page and is the trusted assumption a document review re-measures against
    the corpus (the §4.1 "interop corpus Strict-readiness" row). Permissive
    is Strict with three facts _assumed_ rather than proved (attempt B's
    framing, judge 2's graft) plus the error-to-warning downgrades of §1.1's
    matrix (amended 2026-10-12, review fold: B4): unannotated C++ pointer
    parameters do not escape — **the Permissive reading of p005914:206-208,
    named as a departure** (amended 2026-10-12, review fold: A-13(a)): it is
    a diagnostic assumption only, never a codegen one, because T8 withholds
    `noalias`/`captures(none)` at every such boundary; C++ non-`const`
    methods may be called through shared pointers; union reads, `unsafe fn`
    calls and `unsafe *` need no marker. `unsafe as` is required in **both**
    modes (amended 2026-10-12, review fold: A-11: the rev-1 "raw casts need
    no marker" is deleted — it is enforced today in Permissive-unmarked
    files, toolchain/check/testdata/as/unsafe_as.carbon, the stub's line
    safety_strategy_doc.carbon:24 depends on it, and README.md:105-107
    limits Permissive's omissions to C++-interop and migration patterns).
    Every other analysis (definite formation, bounds, zero-fill, exclusivity
    over Carbon-owned places) runs in both modes; Permissive emits the
    warning twins of §1.1's matrix (`MaybeUnformedRead`,
    `PermissiveAliasedExclusive`, `PermissiveDanglingLoan`,
    `PermissiveUnannotatedCppCall`) so a file's Strict-readiness is visible
    before the flip — what makes p005914:99-104's per-function granularity
    mechanical. Migration ladder: file → `unsafe permissive package`; function
    → delete its `unsafe permissive` after fixing its warnings; file → delete
    the package modifier (the `Normalize` ladder, §1.8). Break condition
    (R-8, re-based on the allowlist): the planned C++-migration examples
    (p005914:188-189) still show the unannotated-call rule on more than half
    of call sites in Strict with the allowlist in force — then the allowlist
    grows by named shapes, each a dated edit of the README table, never by
    dropping the rule.
-   **D-SAFE-19 — Safe-Rust interop mapping and verdict.** Transport
    (**analysis**, not rule — amended 2026-10-12, review fold: B14: its
    three facts are D-SAFE-22 items the writer verifies against the Rust
    reference and the Rustonomicon or labels UNVERIFIED): C-ABI shims
    generated per function on both sides (Crubit-style) over Carbon's
    existing C++-ABI lowering (threading-atomics.md:205-212), `extern "C"`
    only, never `"C-unwind"`; a Rust panic reaching Carbon aborts, a Carbon
    fail-stop under Rust frames is a process abort and Rust `Drop` does not
    run (documented; terminology.md:98-102; error_handling.md:873-882).
    Mapping (table on the page, with attempt C's Stage column): `exclusive T*`
    ↔ `&mut T` (sound only for Strict-checked functions; the generator refuses
    `&mut` for Permissive ones); `T*` ↔ `&Shared<T>` where `Shared<T>` is a
    generated `UnsafeCell`-based wrapper exposing exactly the
    non-invalidating surface (`get`/`set` on `Plain` fields, `addr self`
    methods) — **safe Rust**, because `Cell` semantics are what the
    no-invalidation rule is (attempt B's spelling; attempt A's "durable gap"
    becomes a wrapper); `const T*` ↔ `&SharedView<T>` (the read-only
    `Cell`-shaped view) by default, and ↔ `&T` **only when `T: Core.Freeze`
    and no `T*` to the same object is reachable from Rust in the exported
    signature set** — in practice never for an exported class, because
    Rust's `&T` asserts no mutation for the reference's lifetime while
    Carbon writes `Plain` fields through `T*` aliases during a live `const
    T*` (EX-TM-3, EX-M-1), so an `IntVec` reachable as both `&IntVec` and
    `&Shared<IntVec>` would make `Shared::set` UB for the first (amended
    2026-10-12, review fold: A-9); `Slice(T)` ↔ `&SharedSlice<T>` (a
    `&[Cell<T>]`-shaped view through a two-word shim, never by layout), and
    ↔ `&[T]` only for `Slice(const T)` of a `Freeze` type under the same
    proviso (`Buf.Set` during a live view is the plan's own EX-TM-3 — A-9);
    `bound` ↔ one elided lifetime, `bound(a)` ↔ named lifetimes (stage 6),
    `'static` ↔ free; `Core.Relocatable` types by value as `#[repr(C)]` with
    a generated `Drop` thunk, others as owning opaque handles; `Optional(T*)`
    ↔ `Option<&Shared<T>>` by representation (p006357:243-249; not
    `Option<&T>` — A-9), `Optional(exclusive T*)` ↔ `Option<&mut T>`;
    `choice` ↔ a `#[repr(C)]` tagged union through the shim; `Core.String`
    (the prelude's `str`; docs/design/README.md:3762's `Core.Str` is the same
    type under the interop design's name — the pages say `Core.String` and
    note the alias once, B13(g)) ↔ `&str` only with a UTF-8 obligation
    (`Core.Utf8`, residue); interfaces/vtables and inheritance opaque both
    ways (p005914:170-175); generics instantiated on the defining side;
    `Send`/`Sync` emitted as `unsafe impl` exactly when the Carbon facet
    holds, nothing exported `Send`/`Sync` before stage 5. Verdict (attempt
    A's four parts): (1) safe Rust → Strict Carbon: every Strict-checked
    function over relocatable values, `exclusive T*`, `T*` as `&Shared<T>`,
    `const T*` as `&SharedView<T>`, with `bound`-expressible lifetimes,
    `Optional(T*)` as `Option<&Shared<T>>`, `Slice` as `&SharedSlice<T>`,
    `Core.Result` and `repr`-declared `choice` exports as a safe `fn`;
    Permissive functions always export `unsafe fn` (an audit signal); (2)
    Strict Carbon → safe Rust: a Rust fn with `#[repr(C)]`-mappable types and
    elidable lifetimes imports safe with `bound` derived from its signature,
    so T6 does not apply to Rust results whose lifetimes are declared — except
    a Rust fn taking `&T` together with a Carbon callback, which imports
    `unsafe` (the callback can write through a `T*` alias and re-enter —
    A-9); (3) remaining gap, as p005914:127-129 asks: `&T`/`&[T]` are never
    produced for exported classes and slices (`SharedView`/`SharedSlice`
    instead, the D-SAFE-17 case generalized — moved here from part (1),
    A-9), named lifetimes and outlives bounds wait on stage 6, `Send`/`Sync`
    export on stage 5, interface- and inheritance-typed APIs are opaque,
    `&T`-plus-callback imports are `unsafe`, multi-lifetime Rust APIs import
    conservatively — every gap degrades to `unsafe` on one side with a
    stated obligation, never to UB; (4)
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
    (milestones.md:242) — **and the discharge commit amends the legend**
    (fork/gap-analysis.md:12-14) so DONE is not self-contradictory for
    documentation bullets: after "**DONE** (implemented with real test
    coverage" add "; for a documentation bullet whose text excludes
    implementation, DONE on document review while its program stays SKIP —
    rows 88 and 89)" (amended 2026-10-12, review fold: B6: the rev-1 reading
    of DESIGN-ONLY as "a bullet whose text requires implementation" is not
    supported by row 53's text, which is a feature name; the legend edit is
    listed in §2.12 and §5); W-063 is discharged; residue items W-128.. are
    filed at discharge (§8.5). Break condition: the owner reads row 89 as
    DESIGN-ONLY — a one-cell edit, the legend sentence reverted and header
    delta MISSING −1 / DESIGN-ONLY +1 instead, no page changes.
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
-   **D-SAFE-23 — Fork id, reviews and the merge gate for a PR with no
    toolchain, prelude, golden or program-body change.** One id, F-013, with
    D-SAFE-1..23 and one break-condition register. Plan reviews: TWO
    (R29(c)). Document reviews of the landed pages: **TWO**, not one, because
    R29(c)'s reduction to one applies "once hosted verification ... is fully
    green" and a docs PR has no hosted verification to substitute (and
    Actions is disabled) — the second review is the arbiter the harness
    lacks (W-002: "no arbitration channel for ... document-review bullets",
    work-items.json:37). Briefs are the rulebook's design-doc rows
    (fork/rulebook.md:98-101). Merge gate (amended 2026-10-12, review fold:
    B7): local `uvx prek run` (pinned hooks v0.2.58, R22) to a fixpoint plus
    the R31 count checks for every markdown file; `python3
    fork/conformance/runner.py --self-test` for the two `.carbon` SKIP lines
    (R7) and `python3 -c 'import json; json.load(open(...))'` for
    fork/inventory/work-items.json — the non-markdown churn that makes
    upstream's `has_code` filter true (test-setup/action.yml:35-36); the
    nightly compile step of §8.1a for the today's-syntax examples; all
    recorded in each commit message. This is **not** R21 parity by
    "markdown-only" (the rev-1 claim is withdrawn): upstream's
    tests.yaml:100-101 would run bazel, which builds nothing this PR touches,
    and the rulebook has no docs-only rule — R23 says the runner-side prek
    "remains the authority" — so the local gate is a **stated deviation from
    R23's authority sentence while Actions is disabled**, recorded in the
    F-013 entry with the exact gate that ran. Break condition: Actions
    returns before the merge — then `Fork: hosted verification` mode `gate`
    is dispatched once on the branch head for the record (prek is its first
    step) and the result is stamped in ORCHESTRATION.

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

Diagnostic matrix (amended 2026-10-12, review fold: B4 — the one place that
says, per diagnostic, what each mode does; the pages' Diagnostics sections
copy their rows from it; D-SAFE-18's "three assumed facts" are the three
`none` rows, everything else downgrades to a warning twin in Permissive):

| Diagnostic (owner) | Strict | Permissive | Debug runtime |
| --- | --- | --- | --- |
| `StrictUnsafeCallUnmarked` (§1.2) | error | none — assumed fact | — |
| `StrictUnionReadUnmarked` (§1.2) | error | none — assumed fact | — |
| `StrictUnverifiedDeref` (§1.2, §1.5) | error | none — assumed fact | ASan-class detection (README.md:231-235) |
| missing `unsafe` before `as` (existing `ConversionFailure`-class error) | error | error (A-11) | — |
| `StrictUseOfUnformed` (§1.3) | error | warning `MaybeUnformedRead`; Release reads zero (I5) | "carbon: read of unformed object; terminating" |
| `StrictAddressOfUnformed` (§1.3) | error | none — I3's Permissive assumption (the callee forms it) | same as above on a later read |
| `StrictMoveFromNonEntire` (§1.3) | error | error (a type rule, values.md:117-118, not a safety relaxation) | — |
| `StrictExclusiveBorrowConflict` (§1.5) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictSharedBorrowInvalidated` (§1.5) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` for the value-binding case (D-SAFE-17) |
| `StrictBorrowOutlivesPlace`, `StrictBorrowOfTemporary`, `StrictDanglingReturn`, `StrictStoreOutlivesSource`, `StrictEscapeOfUnboundParam` (§1.5) | error | warning `PermissiveDanglingLoan` | ASan-class detection |
| `StrictCppCallUnannotated` (§1.5) | error | warning `PermissiveUnannotatedCppCall` — assumed fact (A-13(a)) | — |
| `StrictInvalidatingThroughShared` (§1.6) | error | warning `PermissiveAliasedExclusive`; none for a C++ non-`const` method through `T*` — assumed fact | — |
| `StrictNotSend`, `StrictNotSync` (§1.6, stage 5) | error | warning (`--strict-concurrency=warn`) | — |
| bounds and division-by-zero (§1.4) | fail-stop | fail-stop (identical) | fail-stop (identical) |

### §1.2 Type safety (owner: type_safety.md)

TY1 (static, unchanged): values are accessed only at their declared type;
conversions go through `ImplicitAs`/`As`/`UnsafeAs` (as.carbon:12-34). The
type-unsafe operations are enumerated and each is an `unsafe` operation in
Strict (D-SAFE-5): pointer reinterpretation and `const` removal by `unsafe
as`; union field read `unsafe u.f` and `unsafe &u.f`, the latter yielding a
⊥ pointer (T6, RR-1) (F-007b; the read rule is unchanged: defined byte
reinterpretation, never UB, unions.md:369-393);
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
Permissive differs only in not requiring the keyword at three of these
operations (the `none` rows of §1.1's matrix; `unsafe as` keeps its keyword
in both modes, A-11); the set of unsafe operations is identical (an audit
grep finds everything outside the prelude in Strict files — the prelude's
synthesized C++ witnesses are trusted prelude code, D-SAFE-18 — and `unsafe
permissive` finds the rest). The `unsafe as` obligation between pointer
types includes extent: a valid, complete object of the destination type
lives at the address for the loan's lifetime (A-14).

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
C++ consequence: `std::span`/`std::string_view` ↔ `Core.Slice`/`Core.String`
(README.md:3760-3762 names the latter `Core.Str`; the pages use the prelude's
`Core.String` and note the alias once, B13(g)) gain the Carbon-side check at
no C++ cost; raw pointer-plus-length APIs are one `unsafe Core.Slice(T).Make(p,
n)` per site, the single audit line of a migrated buffer API; Permissive
removes only the keyword, never the check (the fail-stop rows of §1.1's
matrix are identical in every mode).

### §1.5 Temporal safety (owner: temporal_safety.md; defines the pointer kinds and loans for §1.6)

Pointer kinds and receivers (D-SAFE-7), `ref` inheritance (D-SAFE-8), loans
T1-T8 with the Store rule and the P1/P2/P3 subset (D-SAFE-10), `bound` and
`bound(a)` and `unsafe class` (D-SAFE-11), temporaries (D-SAFE-12),
relocation (D-SAFE-13 I4). The "Pointer kinds at a glance" table the README
page carries (drafted here, amended 2026-10-12, review fold: B13(f)):

| Kind | Spelling | Formed by | Loan kind | Through it you may | Receiver form | Rust analogue (D-SAFE-19) |
| --- | --- | --- | --- | --- | --- | --- |
| exclusive-mutable | `exclusive T*` (NEW) | `&x` on an owner, a `ref`, or `*p` for `p: exclusive T*` | exclusive | everything: read, write, invalidate (`ref self` calls, assignment of non-`Plain`, `~`, destroy) | `ref self: Self` | `&mut T` |
| shared-mutable | `T*` | downgrade from `exclusive T*`; `&x` on a place already under shared access; C++ `T&` | shared | read; write `Plain` fields; `addr`/`const` methods; form further shared loans | `addr self: Self*` (restored) | `&Shared<T>` |
| shared-const | `const T*` | conversion from either kind; C++ `const T&` | shared (const) | read; `const` methods | `ref self: const Self`, by-value `self` | `&SharedView<T>` (`&T` only under the D-SAFE-19 proviso) |
| unverified (any kind) | the same spellings, loan set ⊥ | `unsafe as` from non-pointers, `unsafe fn`/C++ results, union reads and `unsafe &u.f` (RR-1), `unsafe class` fields | ⊥ | copy, compare, store, pass; `unsafe *p` to use | — | raw pointer |

Diagnostics: `StrictExclusiveBorrowConflict`
("`{0}` is borrowed exclusively by `{1}` here, used again at {2}"),
`StrictSharedBorrowInvalidated`, `StrictBorrowOutlivesPlace`,
`StrictBorrowOfTemporary`, `StrictEscapeOfUnboundParam`,
`StrictDanglingReturn`, `StrictStoreOutlivesSource`, `StrictUnverifiedDeref`,
`StrictCppCallUnannotated`, Permissive twins `PermissiveAliasedExclusive`,
`PermissiveDanglingLoan` and `PermissiveUnannotatedCppCall` (§1.1 matrix). No
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
fields (`i32`, pointers, `Slice`, the prelude's non-owning `String`), call
`addr`/`const` methods, read anything; may not assign a
`Buf`/`Box`/`Optional`/payload-`choice` field, call exclusive methods, move
or destroy — amended 2026-10-12, review fold: B2; `ref self: const
Self`/`self` no mutation); interior mutability is a type's private
Permissive business (`Core.Atomic(T)` over `Cpp.std.atomic(T)`,
threading-atomics.md:201-204) and such a type is not `Freeze`; M5 `match`
through an exclusive path binds payloads as exclusive sub-loans, through a
shared path as shared sub-loans whose alternative cannot change while they
live — a consequence of M3(c) now that sums are non-`Plain` (A-3; the rev-1
"M3c subsumes Ante's sum-type restriction" stands on that footing); M6
`Core.Guarded(T)` (D-SAFE-20) as the opt-in dynamic exclusivity cell for the
observer / back-pointer idioms the rule rejects through `T*`; M7 data races
(D-SAFE-16); M8 value bindings, stated (D-SAFE-17, A-8/B3): a value binding
of a `Plain` type copies eagerly and holds no loan — mutation of the source
afterwards is accepted; a value binding of a non-`Plain` type is a shared
loan for its NLL lifetime, under which an invalidating operation on the
bound object is `StrictSharedBorrowInvalidated` and a `Plain`-field write
through another alias is erroneous, Debug-reported — and from a materialized
temporary it owns the storage and holds no loan (RR-5). Diagnostics:
`StrictInvalidatingThroughShared`
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
annotation) on the README page — written here so the document reviews have
normative text to diff against (amended 2026-10-12, review fold: B5). All
four rungs are NEW syntax (D-SAFE-3/5/6/18); the C++ header is today's C++
(`_Nonnull` is honored by import.cpp:1462-1509; the noescape attribute's name
is a D-SAFE-22 item).

```cpp
// normalize.h — the C++ API being migrated (EX-MIG-0)
struct Vec3 { float x, y, z; };
// Scales `*v` to unit length in place; stores the old length in `*len`.
void Normalize(Vec3* v, float* len);
// The annotated twin a later rung switches to: neither pointer escapes.
void NormalizeChecked(Vec3* _Nonnull v, float* _Nonnull len);  // plus the noescape attribute (D-SAFE-22) on both
```

```carbon
// EX-MIG-1 (rung 1): a Permissive glue file wraps the unannotated call behind a Carbon signature.
unsafe permissive package Geometry library "Glue";
import Cpp library "normalize.h";
fn NormalizeGlue(v: Cpp.Vec3*) -> f32 {
  var len: f32 = 0.0;
  Cpp.Normalize(v, &len);      // Permissive: no marker; stage 3 warns PermissiveUnannotatedCppCall (§1.1 matrix)
  return len;
}

// EX-MIG-2 (rung 2): a Strict file calls the glue; the import is the audit line.
package Geometry library "Shapes";
unsafe import Geometry library "Glue";        // D-SAFE-6: the API file is Permissive
fn Unit(v: exclusive Cpp.Vec3*) -> f32 {
  return NormalizeGlue(v);                    // accepted: a Carbon signature; `v` downgrades to shared `T*` (T2)
}

// EX-MIG-3 (rung 3): the same Strict file calls C++ directly, before annotation.
fn UnitDirect(v: exclusive Cpp.Vec3*) -> f32 {
  var len: f32 = 0.0;
  Cpp.Normalize(v, &len);                     // StrictCppCallUnannotated: pointer parameters, no annotation
  unsafe Cpp.Normalize(v, &len);              // accepted: the obligation (neither pointer is saved) is the caller's
  return len;
}

// EX-MIG-4 (rung 4): after the header gains annotations, the call is safe with no marker.
fn UnitChecked(v: exclusive Cpp.Vec3*) -> f32 {
  var len: f32 = 0.0;
  Cpp.NormalizeChecked(v, &len);              // accepted: `_Nonnull` + noescape import as non-`bound` parameters (D-SAFE-18);
  return len;                                 //   `&len` is a P1 loan on a local passed to a non-`bound` parameter — fine
}
```

Expected diagnostics per rung: rung 1 none in 0.1,
`PermissiveUnannotatedCppCall` (warning) from stage 3; rung 2 none (an `unsafe
import` is a marker, not a diagnostic); rung 3 `StrictCppCallUnannotated` on the
unmarked line from stage 3, none on the marked line; rung 4 none. The ladder a
migrating codebase walks is 1 → 2 → 4, with 3 as the audited shortcut when the
header cannot be annotated. §4.1 carries a row for the ladder.

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
sentence each; NEW "Pointer kinds at a glance" table — the §1.5 table
verbatim; NEW "C++ call allowlist" table — the four D-SAFE-18 shapes, each
with its reason and the corpus program that exercises it, A-12) · Data
races versus unsynchronized
temporal safety (unchanged, plus one dated sentence: "The fork design
prevents all data races between Carbon-spawned threads (D-SAFE-16), which
this section permits.") · Safe library ecosystem (unchanged) · Build modes
(unchanged; one dated blockquote after :222: "The 0.1 toolchain has a single
mode in which the release baseline's bounds checks are unconditional
(D-SL-4); see spatial_safety.md."; and after :262 a dated blockquote
withdrawing the benchmarking disable, A-13(c)) · Constraints (unchanged) ·
NEW "C++ migration example" (the `Normalize` ladder of §1.8, EX-MIG-0..4
verbatim) · References (add F-013, fork/safe/plan.md, the six pages,
p005434, p000257, p000196, p004880 — A-17). Worked examples this page must
contain: the mode example of §1.1 (NEW), the §1.1 diagnostic matrix and the
migration ladder (NEW, with the C++ header and the four rungs).

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
  let s: i32* = unsafe &u.i;    // address of a union field: a deferred read, and s is a ⊥ pointer (T6, RR-1) — `*s` needs `unsafe *s`
  return a;
}
// EX-TY-3 (NEW): a converted pointer is unverified; its dereference is the audit point
fn Deref(p: i32*) -> i32 {
  let q: i32* = p unsafe as i32*;   // type obligation, extent included (A-14); never a lifetime (README.md:83-87)
  return unsafe *q;                  // temporal obligation, spelled separately (p is a P2 parameter: ⊥ only if its source was)
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
// EX-I-2 (today's syntax; accepted today — compile-verified on nightly 2026.10.12, exit 0;
// amended 2026-10-12, review fold: A-18, B1: no `GetOr`, no bare `Optional`, no `.None` designator)
fn Choose2(c: bool) -> i32 {
  var x: Core.Optional(i32) = Core.Optional(i32).None();
  if (c) { x = Core.Optional(i32).Some(1); }
  if (x.HasValue()) { return x.Get(); }
  return 0;
}
// EX-I-3 (rejected today: `var b: Core.Buf(i32);` has no DefaultOrUnformed impl, W-115)
fn NeedsInit() { var b: Core.Buf(i32); }
// EX-I-4 (NEW `~`; Core.Buf is the fork prelude's owning type — B2): moves re-form on assignment
fn Take() {
  var s: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  var t: Core.Buf(i32) = ~s;      // s is now unformed (I4); no Destroy runs on it
  s = Core.Buf(i32).Make(2, 0);   // fine: assignment re-forms s; a read before this is StrictUseOfUnformed
}
// EX-I-5 (today's syntax for the type — compile-verified with the body `*p unsafe as i32 = 1;`, exit 0;
// amended 2026-10-12, review fold: B1: `Core.` qualified) — the out-parameter migration shape
fn Fill(p: Core.MaybeUnformed(i32)*);
fn Out() -> i32 {
  var x: Core.MaybeUnformed(i32);
  Fill(&x);                       // Strict: allowed only because x is MaybeUnformed
  return x unsafe as i32;         // the existing read projection (optional.carbon:200 shape; B10)
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
fn Longest(bound a: const Core.String*, bound b: const Core.String*) -> const Core.String* {
  if (a->Size() > b->Size()) { return a; } else { return b; }
}
// EX-TM-2 (today's syntax; accepted today — p005434:705-709 `Invalid1` calls it invalid (re-pinned, B10); Strict: StrictDanglingReturn)
fn Bad() -> i32* { var x: i32 = 4; return &x; }
// EX-TM-3 (today's syntax for everything but the `bound` on AsSlice, which is W-128; amended
// 2026-10-12, review fold: B2 — the prelude's String is Plain, so the invalidating assignment is a Buf's)
fn Use() {
  var s: Core.String = "abc";
  let p: const Core.String* = &s;   // shared loan on s
  Core.Print(p->Size());
  s = "def";                        // OK even while p is live: String is Plain (B2), assignment is non-invalidating
  var buf: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  let v: Core.Slice(i32) = buf.AsSlice();   // AsSlice is [bound self] after W-128: v holds an interior loan on buf
  buf.Set(1, 7);                    // OK: Set is non-invalidating and i32 is Plain
  Core.Print(v[1]);                 // prints 7; last use of v: loan ends (NLL)
  buf = Core.Buf(i32).Make(1, 0);   // OK after v is dead; before it: StrictSharedBorrowInvalidated (the block v views is freed)
}
// EX-TM-4 (regression set, judge 2 — all three are accepted by today's toolchain and must be
// rejected by stage 4; the first two also by stage 3 once W-128 lands)
fn Leak() -> Core.Slice(i32) {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  return b.AsSlice();               // StrictBorrowOutlivesPlace: b's Destroy frees the block (the return copy keeps the loan, T2/A-2)
}
fn Escape() -> i32 {
  var s: Core.Slice(i32);
  { var a: array(i32, 2) = (1, 2); s = Core.Slice(i32).FromArray(&a); }
  return s[0];                      // StrictBorrowOutlivesPlace (a ended)
}
unsafe class Holder { var p: i32*; }  // D-SAFE-11(g): fields ⊥, a ⊥ store destination (A-15); plain `class` until bound(a) lands at stage 6
fn GetGlobalHolder() -> Holder*;
fn Store() { var y: i32 = 1; let h: Holder* = GetGlobalHolder(); h->p = &y; }  // StrictStoreOutlivesSource: a ⊥ destination accepts only free loans
// EX-TM-5 (NEW): exclusive pointer and the P-subset
fn Bump(p: exclusive i32*) { *p += 1; }           // P2: deref ok; exclusive loan on *p
fn Run() -> i32 { var x: i32 = 41; Bump(&x); return x; }   // &x yields exclusive i32*
fn Peek() -> i32 { let r: i32* = Lookup(); return unsafe *r; }   // P3: Lookup has no bound
// EX-TM-6 (NEW, stage 6): named lifetimes
fn Push[a: Core.Lifetime](list: bound(a) List*, node: bound(a) Node*) { list->head = .Some(node); }
// EX-TM-7 (today's syntax; REJECTED today — "cannot bind durable reference to non-reference value of
// type `str`", nightly 2026.10.12, p005434:173-175's rule; amended 2026-10-12, review fold: B1)
fn Temp() { let ref r: Core.String = MakeString(); Core.Print(r.Size()); }  // rejected today and in both modes; fix: var
// EX-TM-7b (today's syntax except the `bound self` on AsSlice, W-128): a `bound` result on a temporary
fn Temp2() { let v: Core.Slice(i32) = Core.Buf(i32).Make(4, 0).AsSlice(); Core.Print(v[0]); }  // StrictBorrowOfTemporary: v's loan is on the temporary Buf, dead at the `;`
// EX-TM-8 (regression set, review A — amended 2026-10-12, review fold: A-1, A-2, A-5; re-review fold:
// RR-1 Wild3, RR-2 Launder4/Launder5, RR-7 UsePick's diagnostic; each must be rejected by stage 4 with
// the named diagnostic; today's toolchain accepts the fork-syntax parts)
union U { var p: i32*; var n: i64; }                       // union is fork syntax (types/union_basic.carbon)
fn Wild() -> i32 {
  var x: i32 = 1;
  var u: U = {.p = &x};             // Store rule: x outlives root(u) — accepted
  u.n = 0x1234;                     // union write: safe, no marker (F-007b)
  let q: i32* = unsafe u.p;         // union read: the punning obligation only; q is ⊥ (T6, A-1)
  return *q;                        // StrictUnverifiedDeref: needs `unsafe *q` — the README.md:83-87 case
}
fn Load(bound q: i32**) -> i32* { return *q; }   // correct Strict code, accepted: a read through a verified bound
                                                 // pointer; result loan set = q's at shared kind (11(a))
fn Wild3() -> i32 {
  var x: i32 = 1;
  var u: U = {.p = &x};
  u.n = 0x1234;                     // union write: safe
  let q: i32* = Load(unsafe &u.p);  // StrictUnverifiedDeref: `unsafe &u.p` is a ⊥ pointer on formation (T6, RR-1), and
                                    // passing ⊥ to a bound parameter needs the T6 `unsafe`; Load itself cannot see the union
  return *q;                        // with that `unsafe` spelled, q is ⊥ (a bound call over a ⊥ argument, 11(a)) — `unsafe *q` again
}
fn Launder1() -> Core.Slice(i32) {
  var a: array(i32, 2) = (1, 2);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  return s.Subslice(0, 2);          // StrictDanglingReturn: Subslice is [bound self] (W-128, A-2) — a sub-loan on a
}
fn Launder2() -> Core.Slice(const i32) {
  var v: Cpp.std.vector(i32) = Cpp.MakeVector();         // the cpp_span_view.carbon:64-65 shape
  let view: Core.Slice(const i32) = v;                   // the container ImplicitAs is [bound self] (W-128, A-2)
  return view;                      // StrictDanglingReturn: the return copy keeps the loan on v (T2)
}
fn Launder3() -> Core.Slice(i32) {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  let s: Core.Slice(i32) = b.AsSlice();
  let t: Core.Slice(i32) = s;       // Copy.Op is not a loan boundary (T2): t carries s's loan
  return t;                         // StrictBorrowOutlivesPlace, as Leak
}
fn Launder4() -> i32* {
  var x: i32 = 1;
  var o: Core.Optional(i32*) = Core.Optional(i32*).Some(&x);   // Store rule: x outlives o — accepted; Some's `bound value` (W-128, RR-2) puts x's loan in o
  return o.Get();                   // StrictDanglingReturn: Get is [bound self] after W-128 (RR-2) — rev 2's receiver grep missed a result of type T
}
fn Launder5() -> Core.Optional(i32*) {
  var x: i32 = 1;
  return Core.Optional(i32*).Some(&x);   // StrictDanglingReturn: Some has no receiver; `bound value` (W-128, RR-2) carries the loan on x into the result
}
fn Pick(b: bool, bound ref r: Core.Buf(i32), bound p: Core.Buf(i32)*) -> ref Core.Buf(i32) {
  if (b) { return r; } else { return *p; }               // p005434:772-779's Conditional: result kind is the weakest (shared)
}
fn UsePick() {
  var x: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  var y: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  let q: Core.Buf(i32)* = &y;  let q2: Core.Buf(i32)* = &y;
  let ref z: Core.Buf(i32) = Pick(false, x, q);          // z: shared-kind ref whose loan set covers x and y (A-5)
  let v: Core.Slice(i32) = q2->AsSlice();                // interior loan on y
  z = Core.Buf(i32).Make(5, 0);     // StrictInvalidatingThroughShared (RR-7): a non-Plain assignment through a shared-kind ref, rejected regardless of v; y's live view is the second reason
  Core.Print(v[0]);
}
```

### §2.7 docs/design/safety/mutation_safety.md (new)

Outline: Overview · Definition (D-SAFE-1) · M1-M8 · `Core.Plain` (the definition
and the membership table of D-SAFE-9, `Optional(T*)` listed as non-`Plain` and
`String` as `Plain`) · `Core.Guarded(T)` (a Carbon sketch in NEW syntax — `addr
self` does not parse today, so it is labelled "sketch, not compile-verified",
B13(a)) · Data races and the facets (D-SAFE-16, with the facet table) · Value
bindings (D-SAFE-17, with the memory-safety argument and the recorded
alternative) · Diagnostics · Worked examples · C++ interop consequence (the
method partition) · Implementation staging (stage 4 M1-M5, stage 5 M7) ·
Decisions (D-SAFE-9, 16, 17, 20) · Alternatives (attempt A's `shared T*`
qualifier with exclusive `T*`; Swift-style dynamic exclusivity on every access,
rejected on budget and README.md:266-283) · References · External facts (Swift's
law of exclusivity, Ante's rules, `RefCell` — UNVERIFIED unless verified).
Worked examples:

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
// EX-M-3 (NEW, stage 5): facets at the thread boundary, and the thread-boundary lifetime rule (A-6)
fn Spawn[T: Core.Send](f: fn (var t: T), t: T);          // Core.Thread.Spawn's shape: `t`'s loan set must be free
fn BadSpawn(p: i32*) { Spawn(fn (var q: i32*) { *q = 1; }, p); }   // StrictNotSend: `i32*` is not Send
fn Race() { var x: i32 = 0; Spawn(fn (var q: exclusive i32*) { *q = 1; }, &x); }   // StrictBorrowOutlivesPlace at the spawn: &x is a loan on a local, not free
fn Scoped() { var x: i32 = 0; Core.Thread.Scope(fn (ref s: Core.Thread.Scope) { s.Spawn(fn (var q: exclusive i32*) { *q = 1; }, &x); }); }   // fine: joined inside the borrow
// EX-M-4a (today's syntax; accepted today and in Strict — amended 2026-10-12, review fold: A-8, B3:
// i32 is Plain, the binding copies eagerly (D-SAFE-17), there is no loan to invalidate; b is 1)
fn ValueBinding() -> i32 {
  var a: i32 = 1;
  let b: i32 = a;                 // eager copy
  a = 2;                          // accepted in every mode
  return b;                       // 1
}
// EX-M-4b (fork-prelude syntax; accepted today — M8: a non-Plain value binding is a shared loan)
fn ValueBinding2() -> i64 {
  var a: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  let b: Core.Buf(i32) = a;       // shared loan on a for b's lifetime (T2)
  a = Core.Buf(i32).Make(2, 0);   // Strict: StrictSharedBorrowInvalidated (assignment of a non-Plain type is invalidating, 9(c); b is live below)
  return b.Size();
}
// EX-M-5 (NEW-SYNTAX: payload `match` on Core.Optional, which is not a choice today, optional.carbon:64-68 — RR-4; Core.Buf per B2):
// payload references through a shared path
fn Alt(c: Core.Optional(Core.Buf(i32))*) {
  match (*c) { case .Some(ref s) => { Core.Print(s.Size()); } default => {} }   // shared sub-loan; *c cannot change alternative while s lives (M3(c): Optional is non-Plain)
}
// EX-M-6 (regression, review A-3; NEW-SYNTAX for the same reason as EX-M-5, RR-4): the alternative cannot change through another shared alias either
fn Alt2(c: Core.Optional(i32*)*, d: Core.Optional(i32*)*) {   // two shared T* to one object: allowed
  match (*c) {
    case .Some(ref p) => {
      *d = Core.Optional(i32*).None();   // StrictInvalidatingThroughShared: Optional(i32*) is not Plain (D-SAFE-9, A-3)
      Core.Print(**p);
    }
    default => {}
  }
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
fn At[bound self: Self](i: i64) -> const i32*;      // → fn at<'a>(&'a SharedView<Self>, i: i64) -> &'a SharedView<i32>   (stage 4; never &'a i32 for an exported class — A-9)
fn Bump(p: exclusive Counter*);                     // → fn bump(p: &mut Counter)                 (stage 4)
fn Observe(p: Node*);                               // → fn observe(p: &Shared<Node>)             (stage 4; safe, Cell-shaped)
fn Longest(bound a: const Core.String*, bound b: const Core.String*) -> const Core.String*;   // → fn longest<'a>(a: &'a SharedView<str>, b: &'a SharedView<str>) -> &'a SharedView<str> (stage 6 for two names; &str needs Core.Utf8 and the Freeze proviso)
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
unformed-state paragraph at :2147-2149 ("Types may define additional
initialization for the hardened build mode ... integers to be set to `0`")
gains the same-shaped dated blockquote "the fork promotes this zeroing to the
Release baseline for every type (F-013 D-SAFE-13 I5); there is no separate
hardened mode" (A-13(e)); the
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
    :473-475: dated note "pinned by F-013 D-SAFE-17: a value binding of a
    `Core.Plain` type acquires eagerly and is unaffected by later mutation
    (EX-M-4a is accepted, `b` is 1); a value binding of a non-`Plain` type is
    a shared loan under which invalidating operations are rejected in Strict
    and `Plain`-field writes through other aliases stay erroneous" (A-8);
    :579-596: dated note "superseded by the prefix form `unsafe
    s_value.RefMemberFunction()`, D-SAFE-5".
-   docs/design/slices.md:52-53 ("The storage it names must outlive it") and
    :86-88 (`UnsafeMake`'s caller guarantee): after :53 a dated blockquote
    "**Amendment (2026-10-DD, SAFE-1 — F-013 D-SAFE-14 SP3):** in Strict
    Carbon this obligation is checked — views carry a loan on their storage
    (safety/temporal_safety.md), the view-producing prelude functions take
    `bound self`/`bound p` and `UnsafeMake` becomes `unsafe fn Make` under
    residue item W-128; 0.1 keeps the unchecked contract above." (amended
    2026-10-12, review fold: B15; §6 lists the file.)
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

fork/gap-analysis.md (row 89, row 88 evidence, header, narrative :516, and
the :12-14 legend sentence of D-SAFE-21 — B6),
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
before and after per touched file, the heading-set `comm -13` result
(commit 119b35439's message is the shape), and — for commits 2 and 3 — the
§8.1a nightly compile outcome of every today's-syntax example on the page
(B1). Authorship: owner is author, Claude co-author
(fork/ORCHESTRATION.md:470).

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
| TY1 `unsafe as` | EX-TY-1 | ACCEPTS (measured 2026-10-12: nightly exit 0 with `import Core library "io";` prepended for `Core.Print`, which the prelude alone does not provide) | safety_strategy_doc.carbon body; check/testdata/as/unsafe_as.carbon; lower/testdata/pointer/convert.carbon | — |
| TY1 union read | EX-TY-2 | NEW-SYNTAX (Permissive read ACCEPTS today: types/union_basic.carbon) | unions.md:450-456 | 1, 3 |
| TY1 unverified deref | EX-TY-3 | NEW-SYNTAX | handle_expr.cpp:391-399 | 1, 3 |
| TY2 `unsafe fn` | EX-TY-4 | NEW-SYNTAX | token_kind.def (no modifier) | 1, 3 |
| TY4 null | `Optional(T*)` | ACCEPTS | stdlib/optional_pointer_niche.carbon; import.cpp:1491-1509 | — |
| I2 definite formation | EX-I-1 | ACCEPTS-UNCHECKED | no `*Unformed*` diagnostic in toolchain/check; nightly 2026.10.12 exit 0, no diagnostic (B1) | 3 (W-131) |
| I2 `Optional` escape | EX-I-2 | ACCEPTS | optional.carbon:31-40 (`None`/`Some`/`HasValue`/`Get`); compile-verified on nightly 2026.10.12, exit 0 (A-18, B1) | — |
| I1 non-unformable type | EX-I-3 | REJECTS | W-115 (gap-analysis.md:79); buf.carbon:66-67 | — |
| I4 move | EX-I-4 | NEW-SYNTAX | README.md:2160-2168 provisional | 4 |
| I3 `MaybeUnformed` | EX-I-5 | ACCEPTS (type and projection exist) | maybe_unformed.carbon:13-17; optional.carbon:200; compile-verified on nightly 2026.10.12 with a bodied `Fill`, exit 0 (B1) | 3 for the Strict rule |
| SP2 slice check | EX-SP-1, EX-SP-2 | ACCEPTS | stdlib/slices_bounds_fail_stop.carbon EXPECT-EXIT −6; slice.carbon:39-44 | — |
| SP2 constant array | EX-SP-3 | REJECTS | eval.cpp:1080-1116 `ArrayIndexOutOfBounds` | — |
| SP2 runtime array | EX-SP-4 | ACCEPTS-UNCHECKED | lower/handle.cpp:47-74 | 2 (W-130) |
| SP4 unchecked | EX-SP-5 | NEW-SYNTAX | slice.carbon (no accessor) | 1 + W-128 |
| D-SAFE-15 division | EX-SP-6 | ACCEPTS-UNCHECKED | handle_call.cpp:188-192 | 2 (W-130) |
| T5 `bound` | EX-TM-1 | NEW-SYNTAX | token_kind.def (no `bound`) | 1, 4 |
| T5c dangling return | EX-TM-2 | ACCEPTS-UNCHECKED | p005434:705-709 `Invalid1` (erroneous; re-pinned, B10); nightly exit 0 (B1) | 3 (P-subset) |
| T3/T4 NLL | EX-TM-3 | ACCEPTS-UNCHECKED (Permissive semantics today; the `String` assignment under a live `const String*` compiles on the nightly, exit 0, and is accepted in Strict too — B2) (measured 2026-10-12: the literal `Core.Print(p->Size())` of the §2.6 block is rejected by the nightly, "cannot implicitly convert expression of type `i64` to `i32`"; the page spells it `Core.Print(p->Size() as i32)`, the slices.md idiom, which exits 0 — the outcome stands, the spelling on the page is the measured one) | — | 4 |
| Regression set | EX-TM-4 | ACCEPTS-UNCHECKED | judge 2's programs; buf.carbon:54-60; slice.carbon:26-28 | 3 (`Leak`, `Escape` with W-128), 4 (`Store`) |
| P-subset / `exclusive` | EX-TM-5 | NEW-SYNTAX | — | 1, 3 |
| T5f named | EX-TM-6 | NEW-SYNTAX | — | 6 |
| T7 temporaries, `ref` | EX-TM-7 | REJECTS today ("cannot bind durable reference to non-reference value of type `str`", nightly 2026.10.12; p005434:173-175) — amended 2026-10-12, review fold: B1 (measured 2026-10-12: the literal §2.6 line alone is rejected first with "name `MakeString` not found"; with the declaration `fn MakeString() -> Core.String;` and `r.Size() as i32`, as the page spells it, the first diagnostic is the quoted one, exit 1) | convert.cpp:2219 TODO is the extension point | — |
| T7 temporaries, `bound` result | EX-TM-7b | ACCEPTS-UNCHECKED (fork prelude; `bound self` is W-128) | buf.carbon:54-56 | 4 (W-128) |
| T6 union laundering (A-1, RR-1) | EX-TM-8 `Wild`/`Wild3` | NEW-SYNTAX (`unsafe u.p`, `unsafe &u.p`, `bound`; the union is fork syntax, types/union_basic.carbon; the nightly has no `union`) | unions.md:241, :369-380, :417-418 (a pointer into a union aliases every field: `unsafe &u.f` is ⊥ on formation) | 1, 3 |
| T2 copies preserve loans, W-128 signature audit (A-2, RR-2) | EX-TM-8 `Launder1`/`Launder2`/`Launder3`/`Launder4`/`Launder5` | ACCEPTS-UNCHECKED (fork prelude) | slice.carbon:46-56, :74-77, :80-84, :100-106; as.carbon:38-40; optional.carbon:34-42, :69-78; buf.carbon:28, :45, :72-75; index.carbon:9; copy.carbon:10; p005434:782-784 | 3 with W-128 (`Launder1`, `Launder2`, `Launder4`, `Launder5`), 4 (`Launder3`) |
| D-SAFE-8 mixed-kind result (A-5) | EX-TM-8 `Pick`/`UsePick` | NEW-SYNTAX (`bound`) | p005434:772-779 | 1, 4 |
| M3/M4 `addr`, reborrow (A-4) | EX-M-1 | NEW-SYNTAX | call.cpp:528-540 (gate xii) | 1, 4 |
| M6 `Guarded` | EX-M-2 | NEW-SYNTAX (library) | — | 4 (W-128) |
| M7 facets, thread-boundary lifetime (A-6) | EX-M-3 (`BadSpawn`, `Race`, `Scoped`) | NEW-SYNTAX | — | 5 (W-133) |
| M8 value binding, `Plain` | EX-M-4a | ACCEPTS (today and in Strict; `b` is 1) — amended 2026-10-12, review fold: A-8, B3 | nightly 2026.10.12 exit 0; values.md:456-468 does not arise for an eager copy | — |
| M8 value binding, non-`Plain` | EX-M-4b | ACCEPTS-UNCHECKED (fork prelude) | values.md:456-468; buf.carbon:58-60 | 4 |
| M5 payload refs | EX-M-5 | NEW-SYNTAX (payload `match` on `Core.Optional`: optional.carbon:64-68 says `Optional` "is not a choice" and the `match` form "applies once an approved `Optional` design makes it one", so `case .Some(ref s)` does not parse against the fork prelude; `ref` payload bindings exist today only for user `choice` types, handle_binding_pattern.cpp:518-528 — amended 2026-10-12, re-review fold: RR-4; rev 1's "ACCEPTS today as Permissive" withdrawn) | optional.carbon:30-46, :64-68 | 4 plus the choice-based `Optional` redesign the prelude comment names |
| M3(c) sums non-`Plain` (A-3) | EX-M-6 `Alt2` | NEW-SYNTAX (the same `match`-on-`Optional` form as EX-M-5, RR-4; rev 2's "ACCEPTS-UNCHECKED (fork syntax)" withdrawn) | optional.carbon:13-60, :64-68, :186-203 | 4 plus the `Optional` redesign |
| Modes | §1.1 block | NEW-SYNTAX | code_org README.md:312-316 grammar | 1 |
| Diagnostic matrix | §1.1 table | NEW (B4) | — | 3 (warn), 4 (error) |
| C++ migration ladder (B5) | EX-MIG-0..4 | NEW-SYNTAX | import.cpp:1462-1509 for `_Nonnull` | 1, 3 |
| Interop corpus Strict-readiness (A-12) | the six interop programs of review A's table, re-measured with the D-SAFE-18 allowlist in force | ANALYSIS: with the allowlist, cpp_span_view (shape 4), cpp_thread_carbon_fn_diff (shape 3) and cpp_export_method (by-value) need no marker; cpp_operator_import_assignment's `c = 42` stays `unsafe (c = 42)` (A-16); cpp_iterate_generic_member_range goes through trusted prelude witnesses; cpp_template_carbon_class has no C++ call — one marked site of fourteen | fork/conformance/programs/interop/*.carbon | 3; the document reviews re-run this row |
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
slices.md; the dated narrowings (p005434:82 in D-SAFE-8, p005434:663 in
D-SAFE-17, p005434:826-830 in D-SAFE-11(d) — A-13(b)), the withdrawal of
arithmetic.md's performance-build row and of README.md:260-262's
benchmarking disable (A-13(c)), the Permissive reading of p005914:206-208
(A-13(a)), the `import Cpp` asymmetry (A-13(d)) and the zero-fill promotion
at README.md:2147 (A-13(e)) must each be found explicitly disclosed.
Adversary 2 ("interop /
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
    3 MISSING / 1 DESIGN-ONLY"; the :12-14 legend gains D-SAFE-21's
    documentation-bullet sentence in the same commit (B6). Row 88's evidence
    cell: "residual future-work
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
docs/design/slices.md (one blockquote after :53 — B15),
docs/project/principles/safety_strategy.md (one blockquote), fork/
gap-analysis.md (legend sentence included — B6), fork/inventory/work-items
.json, fork/decision-log.md, fork/ORCHESTRATION.md, fork/rulebook.md (one
sentence), fork/safe/plan.md. Conformance headers only: the two stubs' SKIP
lines and the strawman comment. Name collisions, verified: `exclusive`
appears in `.carbon` sources only in three comments, `addr` in CHECK lines
and comments plus one unbuilt source line (third_party/examples/re2/re2.carbon
:769, the historic `addr self: Self` — B9),
`permissive`/`Send`/`Sync`/`Freeze`/`Relocatable`/`DynCast` nowhere;
`Plain`, `Guarded`, `Box` are user class names in interop testdata (no
`Core.` prefix, so no clash with prelude names). Contention: none of the
touched docs are on the held UA-2 branch's diff except fork/gap-analysis.md,
fork/inventory/work-items.json and fork/ORCHESTRATION.md (UA-2 files W-126/
W-127 and re-cites rows); whichever lands second rebases, and the residue
ids start at W-128 so no id collides (§8.5).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — `Core.Plain` too coarse.** `addr` methods cannot overwrite a
    `Buf`, `Box`, `Optional` or payload-`choice` field (an owning string,
    once the prelude has one — today's `String` is `Plain`, B2), so migrated
    classes with owning members or `Optional(T*)` links need exclusive
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
    Contingency: a link-time all-callers-Strict fact (LTO) re-enables them,
    under the same exclusion as T8 — never for a function exported to C++ or
    whose value crosses to C++ or Permissive code (A-7); attributes are never
    emitted unestablished.
-   **R-4 — the bare-`bound` stage cannot express stores through parameters.**
    Linked structures are Strict-rejected until stage 6 (p005434:1185-1190
    already defers). Falsifier: migration pilots blocked on it before stage
    six. Contingency: `unsafe class` interim (D-SAFE-11g) now; pull stage 6
    forward — its syntax is fixed here (rephrased so no continuation line
    begins with a digit and a period, B8).
-   **R-5 — Strict-by-default re-means every file in the tree once stage 3
    lands.** Mitigation is the warn-first rollout (D-SAFE-3) and the prelude
    being ported first (W-128). Falsifier: owner veto. Contingency: the
    page states the default as a language rule; the toolchain flip date is
    a rollout, not a design, question.
-   **R-6 — parser work for the prefix `unsafe` and `unsafe permissive`.**
    Cost, not design risk; D-SAFE-5's break condition moves spellings, never
    the marked set. Falsifier: a stage-1 ambiguity report.
-   **R-7 — `exclusive`/`permissive`/`bound`/`addr` keyword fallout.**
    Verified in `.carbon` sources (§6): empty except re2.carbon:769's
    historic `addr self: Self` in an unbuilt example (B9), which stage 1
    re-spells; `permissive` is contextual. Falsifier: an upstream merge
    introducing an identifier `exclusive` or `bound` — then raw identifiers
    (`r#bound`) at the merge.
-   **R-8 — every unannotated pointer-carrying C++ call outside the
    allowlist is unsafe in Strict.** Mixed codebases live in Permissive
    longer (the intended path, p005914:99-104); the bare rule already tripped
    its own falsifier on the fork corpus (nine of fourteen sites), so the
    allowlist is in force from rev 2 (A-12). Falsifier and contingency:
    D-SAFE-18's re-based break condition.
-   **R-9 — facet synthesis is placeholder machinery today.** `Send`/`Sync`/
    `Plain`/`Relocatable` rely on the `TrivialDestructor`/`Concrete` synthesis
    (custom_witness.cpp:277-298, the SF-6 allowlist note; :180-182 is the
    `DestroyFormat` enum — re-pinned, B10). Falsifier:
    synthesis cannot see through imported C++ layouts. Contingency: the C++
    default (neither) already holds.
-   **R-10 — the MS-5 narrowing (D-SAFE-17) is the decision most likely to be
    vetoed.** Falsifier: a memory-safety consequence (none by the argument on
    the page). Contingency: eager copy for all types.
-   **R-11 — external facts.** D-SAFE-22 quarantines them; the risk is a
    writer promoting an UNVERIFIED item to a rule. Falsifier: adversary 2
    finds one. Contingency: it is a NEEDS-FIX finding, fixed by the fixer.
-   **R-12 — the merge gate is local-only (a stated R23 deviation, B7).** With
    Actions disabled there is no second machine. Falsifier: a hook version drift
    between the pinned rumdl v0.2.58 and whatever `uvx prek` resolves (R31 probe
    used 0.2.78). Contingency: prek runs the pinned hook by rev (R22); any
    difference is recorded in the commit message; D-SAFE-23's break condition
    dispatches `gate` once Actions returns.
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
    committed markdown. **(1a) Compile every today's-syntax example**
    (amended 2026-10-12, review fold: B1, R6's principle): for each example
    marked "today's syntax" on a page, write it to the scratchpad with no
    `package` line and run `/home/user/nightly/tc/carbon_toolchain-0.0.0-0.
    nightly.2026.10.12/bin/carbon compile --output-last-input-only <f>` (the
    upstream subset: no `Core.Slice`, `Core.Buf`, `match`, `union`); the
    exit status and first diagnostic line must match the §4.1 "Today" cell;
    for the fork subset cite the scoreboard program that proves the cell
    (stdlib/slices_bounds_fail_stop.carbon for EX-SP-1/2) or mark the cell
    "fork prelude, not compile-verified in this PR"; record the outcomes in
    commit 2's and 3's messages. Rev 2's own run: EX-I-2 exit 0, EX-I-5 exit
    0, EX-M-4a exit 0, EX-TM-3's `String` part exit 0, EX-TM-7 rejected with
    "cannot bind durable reference to non-reference value of type `str`".
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
    work-items.json on trunk AND on the head of every live
    `claude/carbon-fork-0-1-*` branch, remote and local worktree alike
    (today: ua2 at W-127, sc and cmake at W-125 — the cmake worktree is
    local-only and files residue for gap row 87), taking max+1 and recording
    the grep result per head in the discharge commit message** (amended
    2026-10-12, review fold: B11) — expected W-128 prelude `bound`/`unsafe
    fn` churn (including the signature audit of SP3, A-2/RR-2, with `bound
    self` on `interface IndexWith.At` and `interface Copy.Op`) and the
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
    `Freeze`/`Relocatable`/`Lifetime` names; and the dated narrowings and
    departures from accepted text — p005434:82, p005434:663,
    p005434:826-830, arithmetic.md:155-158, README.md:260-262,
    README.md:2147, the Permissive reading of p005914:206-208, the `import
    Cpp` asymmetry (A-13) — each a rename or a one-paragraph amendment away
    from an upstream decision); the residue items by title with the ids
    allocated at discharge; the R29(a) auto-adoption note, the
    two-document-review rule and the R23-deviation statement of the local
    gate (D-SAFE-23, B7). **Count check for this file:** before H2 2 / H3 44 /
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
    "today's syntax"/NEW marks, keep both regression sets (EX-TM-4, EX-TM-8,
    EX-M-6) verbatim, qualify prelude names with `Core.`, and run §8.1a
    before each page commit.
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

## Review fold record (rev 2, 2026-10-12)

Reviews: A (strategy fidelity and soundness; scratchpad safe1_review_A.md) —
**REJECT**, 3 BLOCKER / 8 MAJOR / 9 MINOR; B (concreteness, consistency,
deliverable and process; safe1_review_B.md) — **APPROVE-WITH-AMENDMENTS**, 7
MAJOR / 8 MINOR. The fixer re-opened every file:line both reviews cite
(unions.md:241/:369-380/:417-418; slice.carbon:24-110; optional.carbon
:13-60/:186-203; string.carbon:16-28; as.carbon:38-65; buf.carbon:45-67;
p005434:173-176/:698-722/:772-780/:823-832/:865-870; p005914:85-88/:97-104/
:204-211; p004880:60-72; p000196:42-48; safety README.md:83-91/:105-124/
:260-262/:297-300; terminology.md:156-177; docs/design/README.md:1317-1322/
:2145-2150/:2160-2168/:3757-3763; values.md:117-122/:456-475; classes.md
:1852-1870; slices.md:50-54/:84-90; re2.carbon:769; ORCHESTRATION.md:31-36/
:56-57/:343/:383-384; custom_witness.cpp:180-182/:277-280; action.yml:33-37;
gap-analysis.md:10-20/:53/:88-89; the six interop programs; unsafe_as.carbon
testdata; the decision-log counts) and compiled the examples B1 names on the
nightly (§8.1a). **Every finding is accepted; none is rejected.** Grades are
the reviews'; "CONFIRMED" below is the fixer's own trace.

| Finding | Grade | Fixer trace | Disposition and where it landed |
| --- | --- | --- | --- |
| A-1 union read launders loans | BLOCKER | CONFIRMED: unions.md:241 admits `T*` fields, :369-380 defines any byte pattern as a pointer read, :417-418 hands the dereference to "the ordinary pointer rules"; rev-1 T6 did not list union reads | ACCEPTED — T6 adds union-read and `unsafe &u.f`-loaded pointer values to the ⊥ sources (D-SAFE-10); `Wild` in EX-TM-8 and a §4.1 row |
| A-2 unmarked prelude producers; no copies-preserve-loans rule | BLOCKER | CONFIRMED: slice.carbon:46-52 `Subslice(self)`, :54-56 `Copy.Op(self)`, :80-84 and :100-106 `Convert(self)` all return views of `self` without `bound`; as.carbon:38-40 makes `let t = s` a `Copy.Op` call | ACCEPTED — T2 "copies preserve loans" clause (D-SAFE-10); D-SAFE-11(a) scoped to producers; SP3's W-128 list extended with the producer-audit rule (D-SAFE-14); `Launder1-3` in EX-TM-8 and §4.1 |
| A-3 `Optional(T*)` is `Plain` by the letter | BLOCKER | CONFIRMED: optional.carbon:30-45 is a class with `adapt`, :186-203 null-niche `MaybeUnformed(T*)` storage with `primitive_copy` and no `Destroy` | ACCEPTED — `Plain` made structural (fixed-offset sub-objects), `Optional(T)`/`MaybeUnformed(T)`/pointer-carrying unions excluded, membership table rewritten (D-SAFE-9); M5 restated as a consequence (§1.6); `Alt2` as EX-M-6 and a §4.1 row |
| A-4 T4 rejects EX-M-1; reborrow unstated | MAJOR | CONFIRMED from the plan's own T4 wording against EX-M-1 | ACCEPTED — reborrow/suspension clause in T2 and T4 (D-SAFE-10); EX-M-1 row names it |
| A-5 mixed-kind `bound` result kind undefined | MAJOR | CONFIRMED: p005434:772-779 `Conditional` | ACCEPTED — weakest-kind rule in D-SAFE-8 and D-SAFE-11(a), T4 over every place (D-SAFE-10); `Pick`/`UsePick` in EX-TM-8 and §4.1 |
| A-6 `Send` loans cross a spawn unconstrained | MAJOR | CONFIRMED from D-SAFE-16 plus EX-M-3's by-value signature | ACCEPTED — thread-boundary lifetime rule (free loan set or scoped join) in D-SAFE-16; the "theorem" sentence made conditional; `Race`/`Scoped` in EX-M-3 and §4.1 |
| A-7 T8 ignores C++ callers and function values | MAJOR | CONFIRMED: cpp_export_method.carbon:31-33 `Bump(ref self)` called from `inline Cpp`; cpp_thread_carbon_fn_diff.carbon:38-45 `std::thread(Work)` | ACCEPTED — T8's condition adds not-exported and not-address-taken (D-SAFE-10); R-3's LTO contingency carries the same exclusion |
| A-8 / B3 EX-M-4 contradicts D-SAFE-17 and T2 | MAJOR / MAJOR | CONFIRMED: README.md:1319-1321 copies `i32`; the example compiles (nightly exit 0) | ACCEPTED — EX-M-4a kept as `i32`, outcome ACCEPTS (`b` is 1); EX-M-4b added with `Core.Buf(i32)` rejected by T4; M8 stated as a rule in D-SAFE-17 and §1.6; values.md:473-475 note says which (§2.10); §4.1 rows |
| A-9 `&T`/`&[T]` rows inconsistent with `&Shared<T>` | MAJOR | CONFIRMED against EX-TM-3 and EX-M-1 | ACCEPTED — D-SAFE-19 rows rewritten (`&SharedView<T>` default, `&T` only under the no-reachable-`T*` proviso, `&SharedSlice<T>`, `Option<&Shared<T>>`, `&T`-plus-callback imports `unsafe`); verdict part (1) narrowed, gaps moved to part (3); §2.8 examples |
| A-10 `Sync` circular; `Slice` gets no answer | MAJOR | CONFIRMED: slice.carbon:37 `Data(self) -> T*`; as.carbon:41-43 strips `const` | ACCEPTED — structural `Send`/`Sync` rules, `T*`/`Slice` fields make a type neither, `Core.Atomic` `Sync`, `Sync ⇔ const Self*: Send` demoted to a consequence (D-SAFE-16) |
| A-11 "raw casts need no marker" in Permissive | MAJOR | CONFIRMED: toolchain/check/testdata/as/unsafe_as.carbon; README.md:105-107 | ACCEPTED — deleted; `unsafe as` required in both modes (D-SAFE-18, §1.1 matrix row, §1.2) |
| A-12 R-8's falsifier met on the fork corpus | MAJOR | CONFIRMED on the six programs (nine of fourteen sites) | ACCEPTED — the import-side allowlist decided now (four shapes, D-SAFE-18); synthesized witnesses declared trusted prelude code; "interop corpus Strict-readiness" row in §4.1 (one marked site of fourteen with the allowlist); R-8 re-based; operator spelling per A-16 |
| A-13 five undisclosed departures | MINOR | CONFIRMED: p005914:206-208; p005434:826-830; README.md:260-262 "will provide"; README.md:122-124; README.md:2147 | ACCEPTED — (a) named in D-SAFE-18; (b) D-SAFE-11(d) narrowing dated and listed in §4.3 and §8.7; (c) README.md:260-262 withdrawn, dated (D-SAFE-14, §2.1); (d) asymmetry and reason in D-SAFE-6; (e) blockquote at :2147 in §2.9 |
| A-14 `unsafe as` obligation lacks extent | MINOR (PLAUSIBLE) | CONFIRMED as a gap in the written obligation | ACCEPTED — extent sentence in T6 (D-SAFE-10), §1.2 and EX-TY-3's comment |
| A-15 `unsafe class` fields unspecified | MINOR | CONFIRMED | ACCEPTED — fields ⊥, ⊥ store destination, construction `unsafe` because it may store non-free loans (D-SAFE-11(g), T6); EX-TM-4 `Holder` re-spelled |
| A-16 no operator spelling; "one postfix expression" ambiguous | MINOR | CONFIRMED: cpp_operator_import_assignment.carbon:26 | ACCEPTED — innermost-operand rule and `unsafe (c = 42)` form with its parse note (D-SAFE-5) |
| A-17 p000196/p004880 uncited | MINOR | CONFIRMED: README.md:297-300; p004880:60-70 | ACCEPTED — §0.1 row 35 "Strategy lineage"; §2.1 References |
| A-18 / B1 EX-I-2 does not compile | MINOR / MAJOR | CONFIRMED: no `GetOr` in optional.carbon; rewritten form compiles, nightly exit 0 | ACCEPTED — EX-I-2 rewritten (§2.4); §4.1 cell cites the compile; §8.1a compile step added; EX-I-5 `Core.`-qualified (exit 0); EX-TM-7 reclassified REJECTS with the diagnostic text and EX-TM-7b added for `StrictBorrowOfTemporary` through a `bound` result (D-SAFE-12, §2.6, §4.1); `String` bare names qualified; commit messages record outcomes (§3) |
| A-19 mutation safety mechanism-shaped; nesting false | MINOR | CONFIRMED: terminology.md:156-177 | ACCEPTED — D-SAFE-1 redefined as an access property; data-race safety a companion, not a sub-case |
| A-20 `Relocatable` "no self-pointers" not structural | MINOR (PLAUSIBLE) | CONFIRMED as a type/value confusion | ACCEPTED — structural definition citing T4 (D-SAFE-13 I4) |
| B2 `String` is `Plain` under the plan's own rule | MAJOR | CONFIRMED: string.carbon:16-28; `s = "def"` under a live `const String*` compiles, nightly exit 0 | ACCEPTED — `String` in the `Plain` table (D-SAFE-9); EX-TM-3 keeps `String` as the accepted case and moves the rejection to `Buf`; EX-I-4, EX-M-5 use `Core.Buf(i32)`; M4 and R-1 re-worded |
| B4 Permissive defined three ways; no matrix | MAJOR | CONFIRMED from :564-572, :754-756, :779-780, :957 | ACCEPTED — the diagnostic matrix in §1.1; D-SAFE-18's sentence reads "three assumed facts plus the downgrades in the matrix"; §1.2/§1.4 reference it; twin `PermissiveDanglingLoan` named |
| B5 `Normalize` ladder unwritten | MAJOR | CONFIRMED: two mentions, no code | ACCEPTED — EX-MIG-0..4 (C++ header, four rungs, expected diagnostics) in §1.8; §2.1 and §4.1 reference them |
| B6 row 89 DONE contradicts the legend | MAJOR (PLAUSIBLE) | CONFIRMED: gap-analysis.md:12-14 legend; row 53's text is a feature name | ACCEPTED — legend amended in the discharge commit (D-SAFE-21), listed in §2.12 and §5; break condition reverts the sentence |
| B7 "docs-only gate" inaccurate; no docs-only rule | MAJOR | CONFIRMED: action.yml:35-36 filter; §2.11's `.carbon` edits and work-items.json | ACCEPTED — status paragraph and D-SAFE-23 reworded; `.carbon`/`.json` gates named; local gate recorded as a stated R23 deviation in the F-013 entry (§8.7); R-12 retitled |
| B8 manufactured ordered item at :1433 | MINOR | CONFIRMED: a continuation line at list indent beginning with the digit six, a period and "Contingency:"; count twenty-nine versus twenty-eight authored | ACCEPTED — R-4 rephrased ("stage six"); ordered count is twenty-eight after the fold (below) |
| B9 `addr` fallout claim false | MINOR | CONFIRMED: re2.carbon:769 | ACCEPTED — D-SAFE-7, §6 and R-7 corrected; the `addr self: Self*` choice explained |
| B10 six anchors drifted | MINOR | CONFIRMED: all six | ACCEPTED — re-pinned in the status paragraph, D-SAFE-8, D-SAFE-13, EX-TM-2, §2.4, §4.1, R-9 |
| B11 residue-id race with other branches | MINOR (PLAUSIBLE) | CONFIRMED: the cmake worktree is local-only at W-125; ua2 at W-127, sc at W-125 | ACCEPTED — §8.5 allocates over every live `claude/carbon-fork-0-1-*` head including local worktrees and records the grep per head |
| B12 `Plain`'s destructor criterion versus classes.md | MINOR | CONFIRMED: classes.md:1852-1870 `fn destroy`; `grep Destroy` empty there | ACCEPTED — both spellings named in D-SAFE-9 plus the dated disclosure sentence on the mutation page |
| B13 seven concreteness gaps | MINOR (PLAUSIBLE) | CONFIRMED as gaps | ACCEPTED — (a) `Guarded` labelled a NEW-syntax sketch (§2.7); (b) Clang Thread Safety Analysis attribute family and its import rule (D-SAFE-18); (c) shadow-memory binding count (D-SAFE-17); (d) `Core.Move` signature (D-SAFE-13); (e) `bound(a)` one-name-one-set rule, outlives deferred to W-134 (D-SAFE-11(f)); (f) pointer-kinds table drafted in §1.5; (g) `Core.String` chosen, `Core.Str` noted as the README's alias (§1.4, D-SAFE-19) |
| B14 facet rules and transport paragraph lean on unlisted facts | MINOR (PLAUSIBLE) | CONFIRMED | ACCEPTED — facet rules stated as fork definitions with Rust's argument quarantined (D-SAFE-16); transport paragraph labelled analysis with its three facts as D-SAFE-22 items (D-SAFE-19) |
| B15 slices.md not amended | MINOR | CONFIRMED: slices.md:52-53, :86-88 | ACCEPTED — dated blockquote added to §2.10; file added to §6 |

R31 count check for this fold (fork/safe/plan.md; the R-4 rephrasing is the
one deliberate list change and the slices.md item the one deliberate dash
addition). Before the fold: headings H1 one / H2 thirteen / H3 twenty-eight /
H4 two; dash items forty-four; ordered items twenty-nine (twenty-eight
authored plus the B8 manufactured item). After the fold and the prek
fixpoint: headings unchanged at every level; dash items forty-five; ordered
items twenty-eight — the counts are spelled in words here because the
fold's own first draft wrapped "ordered 28." onto a line start and
manufactured a twenty-ninth item, the exact R31 hazard, caught by the count
diff. The prek passes, the heading-set `comm -13` result (one heading
renamed: this section's rev) and the manufactured-heading grep (empty) are
in the rev-2 commit message.

## Review fold record (rev 3, 2026-10-12 — the focused re-review)

Re-review of the three BLOCKER folds (scratchpad safe1_rereview.md, against
rev 2 at 2b630f9b6): **APPROVE-WITH-AMENDMENTS**, 2 MAJOR / 5 MINOR; each of
A-1, A-2 and A-3 traced RESOLVED against its original counterexample, and
A-4 through A-12 re-traced RESOLVED. The fixer re-opened every file:line the
re-review cites (unions.md:417-418; safety README.md:83-87;
optional.carbon:17-26/:30-46/:64-78/:140-143/:186-204; buf.carbon:28/:45/
:72-75; slice.carbon:74-77; core/prelude/operators/index.carbon:9;
core/prelude/copy.carbon:10; as.carbon:37-43; p005434:782-784;
values.md:168/:186-192; handle_binding_pattern.cpp:518-528) and re-ran the
`case .X(ref …)` grep over testdata and the conformance programs (empty, as
the re-review says). **Every finding is accepted; none is rejected.** Grades
are the re-review's; "CONFIRMED" is the fixer's own trace.

| Finding | Grade | Fixer trace | Disposition and where it landed |
| --- | --- | --- | --- |
| RR-1 `unsafe &u.f` marked at the load site, not modular | MAJOR | CONFIRMED: rev-2 T6 (:480-486) marked the value loaded through the pointer; D-SAFE-11(a) gives a `bound` call result the argument's loans, so a correct Strict callee returning `*q` for `bound q: i32**` launders `unsafe &u.p` into the non-⊥ set {(u.p, shared)}; unions.md:417-418 makes a pointer into a union alias every field | ACCEPTED — T6: the pointer `unsafe &u.f` is itself ⊥ on formation for every field type; 11(a): a ⊥ argument to a `bound` parameter makes the result ⊥; D-SAFE-5, §1.2 and the §1.5 kinds table say so; EX-TY-2's comment; `Load`/`Wild3` in EX-TM-8 and the §4.1 row |
| RR-2 W-128 producer audit under-inclusive | MAJOR | CONFIRMED: optional.carbon:40-42 `Get(self)` returns `T` with no `bound self`, :34-36 `Some(value: T)` has no receiver, :69-78 `Branch(self)`, :22 `OptionalStorage.Get`; buf.carbon:28 `Make(size, fill: T)`, :45 `Get`, :72-75 `At`; slice.carbon:74-77 `At`; index.carbon:9 and copy.carbon:10 are interface methods and p005434:782-784 lets impls omit but never add `bound` — the rev-2 receiver grep fires on none of them | ACCEPTED — SP3's grep replaced by the signature-under-11(b)/(c) rule (every parameter whose loans can reach the result or `self` is `bound`, else `unsafe fn`; `bound self` on `interface IndexWith.At` and `interface Copy.Op`, with T2 still governing primitive copies); the hits named; D-SAFE-11(a) and (e) cross-reference it; `Launder4`/`Launder5` in EX-TM-8 and the §4.1 row; §8.5's W-128 text |
| RR-3 same-kind copy of an exclusive carrier | MINOR | CONFIRMED: T2's reborrow clause covers exclusive to shared only; `let q: exclusive i32* = p;` left two live exclusive carriers of one loan, each a T8 `noalias` candidate | ACCEPTED — T2: a same-kind copy is a move of the loan (source dead until the copy's last use); an exclusive carrier reached through a shared path copies as a shared reborrow |
| RR-4 EX-M-5/EX-M-6 rows misclassified | MINOR | CONFIRMED: optional.carbon:30-46 is a class with `adapt`, :64-68 says `Optional` is not a choice and the `match` form waits on an approved design; the `case .X(ref …)` grep over testdata and conformance programs is empty | ACCEPTED — both §4.1 rows NEW-SYNTAX citing optional.carbon:64-68 (rev 1's EX-M-5 "ACCEPTS today as Permissive" and rev 2's EX-M-6 cell withdrawn); the examples keep the design's `Optional` shape, their header comments say so |
| RR-5 non-`Plain` value binding from a temporary has no rule | MINOR | CONFIRMED: D-SAFE-17 named only `*p` and an owner as sources; values.md:186-192 makes the third source a materialized temporary (its lifetime values.md:168's open question); D-SAFE-12's letter would reject `o.HasValue()` on the line after `let o = Core.Optional(i32).Some(1);` | ACCEPTED — D-SAFE-17: such a binding takes ownership of the materialized storage (values.md:192's `var` rule applied to `let`) and carries no loan on it; loans carried by the value are unaffected (EX-TM-7b unchanged); T2 and §1.6 M8 cross-reference it |
| RR-6 criterion (ii) does not exclude what the table excludes | MINOR | CONFIRMED: optional.carbon:140-143 `DefaultOptionalStorage(T)` = {`MaybeUnformed(T)`, `bool`} and :188-189 `MaybeUnformed(T*)` have fixed offsets; only formedness varies | ACCEPTED — D-SAFE-9 (ii) reads "exists and is formed at a fixed offset", with the two citations |
| RR-7 (A-5 nit) `UsePick`'s diagnostic name | MINOR | CONFIRMED: §1.6 names `StrictInvalidatingThroughShared` for a non-`Plain` assignment through shared access; D-SAFE-8 :373 and `UsePick` :1495 said `StrictSharedBorrowInvalidated` | ACCEPTED — renamed in both places; `v` kept as the second reason |

R31 count check for this fold (fork/safe/plan.md; this section's heading is
the one deliberate heading addition and no list item is added). Before the
fold: headings H1 one / H2 thirteen / H3 twenty-eight / H4 two; dash items
forty-five; ordered items twenty-eight. After the fold and the prek fixpoint:
H2 fourteen, every other level unchanged; dash items forty-five; ordered
items twenty-eight. The prek passes, the heading-set `comm -13` result (one
line, this heading) and the manufactured-heading grep (empty) are in the
rev-3 commit message.

## Sign-off

Rev 3, 2026-10-12. Verdicts: review A REJECT (3 BLOCKER / 8 MAJOR / 9
MINOR), review B APPROVE-WITH-AMENDMENTS (7 MAJOR / 8 MINOR), focused
re-review of the three BLOCKER folds APPROVE-WITH-AMENDMENTS (2 MAJOR / 5
MINOR; each BLOCKER traced RESOLVED against its original counterexample, no
finding rejected); all 42 findings folded in place with "(amended
2026-10-12, review fold: ...)" and "(amended 2026-10-12, re-review fold:
RR-n)" marks and the two records above. The re-review did not REJECT, so
**rev 3 is signed off for implementation**: the writer starts from §1 and
§0.3 per the hand-off notes, the two document reviews of the landed pages
(D-SAFE-23) are the next review gate, and later amendments continue to be
folded in place, each marked "(amended <date>, review fold: ...)".
