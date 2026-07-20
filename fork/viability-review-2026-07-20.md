# Viability review — 2026-07-20 (independent, adversarial)

Commissioned to refute, not to grade homework. Every claim below was
re-derived from the tree, git history, or the branch diffs — not from
fork/ self-descriptions. Style per rulebook R17: one-line justifications,
citations inline.

**Verdict: VIABLE-WITH-CHANGES** — with one hard scope carve-out
(Windows) and one honesty correction (this is a fork dialect's 0.1, not
the official one). Details in §6.

---

## 1. Velocity vs remaining work

### What has actually shipped (verified)

-   Merged compiler source since upstream 99cda60: **~201 lines**
    (handle_match.cpp +186/−16, node_stack.h +7/−7, inst_namer.cpp +8;
    `git diff 99cda60..HEAD --numstat`). Everything else in the product
    column is testdata (~1,025 lines) and fork-authored design docs
    (~1,670 lines: docs/design/error_handling.md 873, docs/design/unions.md
    656, sum_types.md/READMEs remainder).
-   In flight: B0 (~90 compiler lines + 9 testdata files, branch
    claude/carbon-fork-0-1-7mwfb7-b0-exceptions @ b2b3df4) and W5-S1
    (plan only at c0211ec; no compiler diff yet on
    claude/carbon-fork-0-1-7mwfb7-w5-choice).
-   Loop timing evidence (fork/trial-w4/retrospective.md): autoupdate ~7
    min, warm full gate ~4 min, end-to-end implement→merged ≈ one working
    day, including a 3.5h runner-offline stall (R14).

So: ~11M subagent tokens in ~20h bought one merged S-size slice, one
near-done S/M slice, a 101-program smoke suite, 5 design decisions with
docs, and the process machinery. Token cost per merged compiler line to
date is absurd (~50K tokens/line) but that is day-1 amortization; the
marginal slice (W4 trial ≈ 1.0M, B0 ≈ 0.8M) is the honest unit:
**~1–1.5M tokens and ~0.5–1 calendar days per S/M slice.**

### Remaining inventory, priced in slices

17 SKIP bullets (scoreboard bullets map, 18 SKIP-status minus
match-switch flipped by 5a83b0e). Mapping to workstreams
(fork/gap-analysis.md:75-174) and pricing in W4-S1-equivalent slices:

| Work | Size | Slice estimate | Velocity evidence? |
| --- | --- | --- | --- |
| Match completion (guards, bindings, non-int, exhaustiveness) | L | 4–6 | partial — but see §2 rework cliff |
| W5 choice payloads (4 planned slices, 3ce4b85) | L | 4–6 | plan only |
| Error handling B1–B3 (F-006) | L | 4–6 | B0 only |
| Unions implementation (F-007) | L | 4–6 | none |
| if-let/let-else (F-011) | M | 2–3 | none |
| Function overloading (F-009) | M–L | 3–5 | none |
| W7 templates completion + structural conformance (F-010); the lower/handle.cpp:363 CARBON_FATAL | L | 5–8 | none |
| W6 definition-checked variadics | **XL** | 10–20 | **none** |
| W8 C++ interop frontier (templates-on-Carbon-types, operator/concept export, B3 overlap, F-008 threading defects) | **XL** | 8–15 | none |
| W9 stdlib (slices/heap/String/Optional/span; partly blocked on W6) | L | 4–8 | none |
| W3 safe-Carbon design (doc-only) | **XL** | 3–5 design sprints | design-sprint pattern proven |
| W11 CMake/Make + evaluator docs | M | 2–4 | none |
| W12 Unicode lexer | S | 1–2 | pattern proven |
| W10 Windows | **XL** | 10–20 **+ hardware that does not exist** | **structurally blocked** |

Total ex-Windows: **~55–105 slices**. Tokens: ~1.5M/slice average
including planning/review/decision overhead → **~85–160M further
subagent tokens (≈8–15× spend to date)**. At Bun-comparable blended
pricing that is an order-tens-of-thousands-of-dollars burn — real money,
but not the binding constraint.

### Is end-of-year plausible?

Arithmetic: ~115 working days remain in 2026. At the observed 1
merged-slice/day with 2 in flight, 55–105 slices fits — _if_ 1.5–2
slices/day sustains. Three compounding drags say it won't sustain
cleanly:

1.  **The velocity evidence covers only the easiest slice class.** W4-S1
    and B0 are S-size slices on well-scaffolded ground (mirroring sibling
    handlers, R3). Zero evidence exists for XL compiler engineering —
    variadics pack typechecking, template lowering, Clang-side Carbon-type
    instantiation — which is where compiler schedules die. Extrapolating
    Bun-benchmark velocity from these two slices is exactly the
    overfitting this review exists to catch.
2.  **Rework debt is already booked** (§2): W5-S2 destructuring cannot
    build on W4-S1's ==-chain; part of the "velocity" was a shortcut the
    next slice pays back.
3.  **Upstream drift is zero today and only grows** (§5); every upstream
    merge is a full-gate cycle plus conflict risk exactly in the files
    the fork edits (handle_match.cpp, handle_choice.cpp).

**Honest extrapolation:** fork-scoped "0.1 minus Windows" (Linux/macOS,
fork-ratified designs) by end of 2026 is _plausible but fragile_ — call
it a coin flip conditional on XL slices behaving and the changes in §6
landing. **The official checklist including "installs on Windows"
(docs/project/milestones.md) is not reachable at all with current
infrastructure** — no Windows runner exists, clang_runtimes.cpp
hard-errors on Windows, LLD has no COFF wiring (gap-analysis.md:68) —
and no amount of agent tokens conjures a Windows CI machine. This is not
a multi-year burn at current rates, but it is also not "0.1 by
December" as officially defined.

## 2. Merged code quality (W4 match, fresh-eyes C++ compiler review)

Read: toolchain/check/handle_match.cpp @ HEAD (merged by way of 5a83b0e).

**Good:** clean, commented, design-cited (pattern_matching.md operand
order at :141-145 — a real subtlety the adversarial review caught);
TODO-gated at every unsupported edge with 6 fail_todo testdata files;
scrutinee converted to value once (:47) with temporary cleanup handled
and the cleanup-soundness argument written down (:52-56); B0's in-flight
code is genuinely competent Clang-API work
(ResolveExceptionSpec/canThrow mirroring Sema::MarkFunctionReferenced,
thunk.cpp diff on b2b3df4).

**Not upstream-mergeable as-is — two structural findings:**

-   **F-Q1: parse-tree index arithmetic.** handle_match.cpp:106-111 sniffs
    the case pattern by peeking raw postorder indices
    (`node_id.index + 1`, `+ 2`) to detect "single IntLiteral then
    MatchCase". This is brittle coupling to parse-tree layout that no
    other check handler uses; the comment at :99-105 admits its purpose is
    to keep pattern nodes from "reaching their handlers outside of a
    pattern-matching context" — that is, it dodges integrating with the
    pattern machinery (handle_pattern / pattern SemIR) that upstream
    routes every `let`/`var`/param pattern through. A Carbon reviewer
    would bounce this and ask for the pattern-stack route.
-   **F-Q2: no SemIR representation of match.** Cases desugar directly to
    `==` chains and branches during check. Fine for slice 1, but
    exhaustiveness checking (required, pattern_matching.md), usefulness
    diagnostics (W-066), binding patterns (W5-S2 destructuring — the very
    next dependent slice), and any decision-tree lowering all need a real
    pattern representation. **The next slice must rewrite this one.** The
    merge was a valid process trial; counting it as durable feature
    velocity overstates progress.

Also noted: negative literals (`case -1`) are a prefix-op node, so they
fall into the TODO — diagnosed, but no SKIP program or inventory item
records this user-visible gap (the conformance program only probes a
negative _scrutinee_, match_switch.carbon:47).

Debt grade: **medium, not yet compounding — provided the rewrite happens
at W5-S2 rather than a third layer of special cases.**

## 3. Arbiter depth (quantitative Kelley check)

101 programs / 56 bullets ≈ 1.8 per bullet; 5 differential C++-oracle
pairs (fork/conformance/README.md table). Sampled 5 shipped bullets and
enumerated what a hostile reviewer could break with the conformance
suite staying green:

| Bullet | Programs | Surface pinned (est.) | Undetected hostile breaks |
| --- | --- | --- | --- |
| Checked generics | 1 (checked_generics.carbon: 1 interface, 1 impl, 1 constrained fn) | ~5% | specialization/match_first ordering, blanket/forall impls, associated-constant substitution in lowering, deduction with multiple params — all runtime-invisible to the suite |
| Virtual dispatch | 1 (virtual_dispatch.carbon: one virtual fn, one level) | ~10% | any vtable-indexing bug (only one slot exists), multi-level hierarchies, dispatch through references, abstract classes |
| Operator overloading | 1 + 1 diff | ~15% | every operator interface except AddWith/MulWith/EqWith at runtime; ordered comparisons, unary/compound ops, rewrite rules |
| Fundamental types | 1 + 1 diff | ~10–20% | signed division/remainder rounding with negative operands, overflow/wrap semantics, i8/i16/u16/u32/f32, shifts, bitwise ops |
| Match (freshly shipped, best case) | 4 + 1 diff + 12 goldens | ~40% of slice 1 | scrutinee evaluated once vs per-case (no side-effect probe exists), duplicate cases silently accepted (W-066), `case -1` unsupported and unrecorded |

**Conclusion: the suite is a progress ledger with excellent SKIP
forensics** (the SKIP detail strings — exact diagnostics, file:line of
stubs, hand-verification notes — are the best artifact in fork/) **but
it is not a conformance suite.** For DONE bullets it pins maybe 5–20% of
semantic surface. Two mitigations exist and one hole remains:

-   Mitigation 1: the merge gate runs upstream's full 1,625-golden suite
    (F-002, decision-log.md:199-213), which catches _regressions_ to
    pre-existing features as reviewable golden diffs.
-   Mitigation 2: R16 prohibits the classic gaming moves; hooks enforce
    the mechanical ones.
-   **Hole (F-A1): for NEW fork features the goldens are generated by the
    implementation under test** by way of runner-side autoupdate (R15). R16(d)
    bans deriving EXPECT values from the implementation for conformance
    programs, but golden CHECK lines are definitionally
    implementation-derived. For new features the only independent
    semantics checks are the handful of runtime programs, 5 differential
    pairs, and reviewer attention. The Kelley critique is procedurally
    acknowledged (R16 cites it) but quantitatively unanswered: 5
    differential programs across 101 is 5%.

## 4. Process overhead and decision load

-   **Lines:** diff vs 99cda60: process (fork/, .github/, .claude/)
    13,667 added lines vs product 2,895 — **4.7:1**. Within product,
    compiler source is ~201 lines: **1.2% of the total diff**.
-   **Tokens (caller's figures, consistent with artifacts):** process/meta
    (audit 1.1M + inventory 0.9M + W5 planning 0.55M + orchestrator)
    ≈ 2.5–3.5M; arbiter 3.4M; design 2.3M; compiler code ≈ 1.8M. **~16%
    of subagent spend touched compiler code.** Much is one-time, but the
    standing per-slice overhead is real: B0's plan.md is 471 lines against
    ~90 compiler lines; trial-w4/plan.md is 413 lines.
-   **Decision load: 51 user ratifications on day 1** (decision-log.md:
    F-001..F-011 = 11 forks; F-006a + F-006b..l + F-007a..k + DIFF-1..4 +
    W5 SF-1..8 + B0 SF-1..5 = 40 sub-decisions). The policy "Sub-forks are
    forks... no matter how mundane" (process.md Human-in-the-loop) prices
    the remaining ~13 feature areas at **~120–180 further ratifications**.
    Warning sign already present: F-006b..l were accepted "all per doc
    recommendation" (decision-log.md:59-60) — eleven-for-eleven adoption
    of the recommendation is the signature of rubber-stamping, that is, the
    ceremony is consuming the user's attention without changing outcomes.
    This is the strongest evidence FOR the "process-heavy theater" worry:
    not the docs (they earn their keep as compaction-survival state), but
    the mundane-sub-fork ritual.

Is it theater overall? **No — the process artifacts demonstrably caught
real defects** (12 W4 findings incl. two golden-invisible ones,
retrospective; R20's incident 837bb60; R13's YAML failure 29696011228).
But the ratio must fall: if by ~10 more slices the cumulative
compiler:process token ratio hasn't inverted, the answer changes.

## 5. Structural risks

-   **R-S1 Single self-hosted runner ("jeromehome", 28-core,
    ORCHESTRATION.md).** Day-1 stall cost 3.5h of ~20h (17%) (R14). It is
    the merge gate, the autoupdate loop, AND the release pipeline; one
    machine owned by one person is the project's availability ceiling. No
    fallback path exists.
-   **R-S2 Orchestrator context compaction.** Mitigated unusually well
    (ORCHESTRATION.md one-read resume + quantized state files) — but the
    designated behavioral source of truth is broken: **scoreboard.json is
    gitignored (.gitignore:55) and the in-tree copy is stale** — generated
    2026-07-19T07:23 against the _upstream nightly_, 60 PASS, pre-merge —
    while the post-merge truth (63, then 68 PASS) lives only in a commit
    message (5a83b0e) and a self-declared "don't trust this line" in
    ORCHESTRATION.md. R9 says progress reports quote scoreboard.json;
    today nothing committed or CI-produced backs those quotes.
-   **R-S3 Upstream drift.** Zero now (fork is hours old); upstream lands
    weekly-to-daily (audit: proposal burst through 2026-07-13). Collision
    risk is concentrated precisely in the fork's files — upstream WILL
    implement match/choice payloads on its own schedule and its own
    design. Deeper: the fork's ratified designs (Result + `?`, native
    `union`, `overload fn`) are user-accepted, not community-accepted —
    so (a) gap-analysis arbiters reading "accepted proposals" are
    self-graded, and (b) **none of this work is upstreamable**; the
    deliverable is a demonstration dialect, which should be said plainly.
-   **R-S4 No-local-build tax.** Cheaper than feared: 28-core runner,
    ~2-min fast check, ~4-min warm gate, compile-first-try achieved once.
    But the tax is per-iteration latency plus queue, and the sample size
    for "compiles first try" is n=1; a slice that misses will pay a
    7-minute round trip per compiler error. Watch B0/W5 for the real
    distribution.
-   **R-S5 Branch sprawl.** 4 active branches with an enforced disjoint
    scope map (3d649a2) and R20 born from an actual accident (837bb60
    swept 12 staged files). Managed, but the control is a convention, not
    a mechanism; it degrades exactly when parallelism (the velocity plan)
    increases.

## 6. Verdict: VIABLE-WITH-CHANGES

The factory is real: it merged working, reviewed compiler code through a
no-local-build CI loop in one day, and its guards caught real defects.
The refutation attempt fails on "this can never work" but succeeds on
three specific counts: official-0.1-with-Windows is unreachable as
configured; the arbiter is a ledger, not a conformance suite; and the
decision ritual is already showing rubber-stamp symptoms. A rubber-stamp
of the current trajectory would therefore also be wrong.

### The user must decide (cannot be delegated)

1.  **Scope: name the real target.** Either provision a Windows
    runner/CI machine now (W10 is XL and serial-late) or formally retarget
    to "fork-0.1 (Linux/macOS)" and stop describing the goal as the
    official checklist. Expected effect: converts the largest hidden
    schedule lie into a plan.
2.  **Reform the sub-fork ritual (reverses a standing user directive, so
    only the user can).** Keep synchronous AskUserQuestion for genuine
    forks (divergent consequences, scope trades, upstream divergence);
    demote mundane sub-forks to adopt-recommendation-by-default with a
    batched veto digest. Expected effect: removes ~120–180 pending
    ratifications from the critical path; the F-006b..l pattern shows
    ~zero information is currently produced by them.
3.  **Own the dialect decision.** Confirm that non-upstreamable,
    user-ratified designs are the intent (demonstration/fork), or
    re-anchor W2/W3 outputs to upstream leads' public direction at the
    cost of speed. This changes what "0.1" means and only the user can
    sign it.

### The orchestrator should just fix (prioritized)

4.  **Make the scoreboard a CI artifact.** Run the conformance suite in
    the gate workflow against the fork-built toolchain and commit/publish
    scoreboard.json per merge. Closes R-S2/R9's verifiability hole; cost
    ≈ one workflow edit + ~30s runtime (suite runs in 26.6s,
    scoreboard.json:4).
5.  **Re-platform match on the pattern machinery BEFORE W5-S2**, not
    after: delete the index-arithmetic peek (F-Q1) and give match a real
    pattern path (F-Q2) as its own slice. Expected effect: prevents three
    downstream slices (bindings, guards, choice destructuring) from
    stacking on a structure that must die.
6.  **Deepen the arbiter as a merge-gate requirement, not a backlog
    item:** every bullet flipped to PASS needs ≥1 differential pair and a
    hostile-review pass listing what the programs do NOT pin (append to
    the program header); grow differential coverage from 5 toward every
    runtime-semantics bullet; add the known missing probes now
    (scrutinee-evaluation count, negative case literals, duplicate
    arms). Expected effect: PASS flips stop being 5%-surface smoke
    claims.
7.  **Runner resilience:** health-check Routine + a documented hosted-CI
    fallback lane (slow is fine; dead is not). Expected effect: caps
    repeat of the 17% day-1 downtime.
8.  **Weekly upstream-merge Routine + pre-workstream upstream-activity
    check** (standing rule 5 — verify the armed Routine actually fires
    and gate-runs the merge). Expected effect: drift paid in small weekly
    installments instead of one compounding balloon.
9.  **Record user-visible slice gaps as inventory items at merge time**
    (for example `case -1`): a gap a user can hit must exist in
    work-items.json even when no SKIP program covers it.

### Falsifiable checkpoints (re-run this review against them)

-   By +10 merged slices: cumulative compiler:process token ratio
    inverted; ≥2 L-size slices merged (not S); differential count ≥15.
-   By 2026-09-01: W6 variadics lexer+parse merged (first XL evidence) or
    the end-of-year claim is withdrawn.
-   Windows: runner provisioned by 2026-09-01 or the target is formally
    Linux/macOS.
