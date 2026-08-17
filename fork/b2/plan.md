<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# F-006 B2 plan: the ungated error-handling remainder (W-071 discharge), plus the B3 scoping resolution

Status: PLAN (process step 6, scaled loop). Baseline: trunk f7b36d4 (B1
complete across PRs #15/#16 — postfix `?` desugars through prelude
`Core.Try`/`Core.ControlFlow` over user-defined generic choices; 83 PASS /
0 FAIL / 30 SKIP over 113). Design authority: docs/design/error_handling.md
(as amended at B1b — staging table, Try section, impl sketches), the
F-006/F-006a..l entries and the B1 landing note in fork/decision-log.md,
fork/b1/plan.md (whose §0.2 S3p boundary this plan composes with), and the
W-070/W-071 ledger entries in fork/inventory/work-items.json. Precedent
format: fork/b1/plan.md. NO implementation in this document — planning only.

---

## 0. Scoping resolution: what is left of B2, and what B3 is

### 0.1 The F-006 sub-item classification (the ratified decision, enumerated)

F-006 staged the ratified design B0-B3 (decision text + the
docs/design/error_handling.md staging table as amended 2026-08-08 at B1b).
Every sub-item, classified against trunk f7b36d4:

| # | F-006 sub-item (stage as ratified) | Status at f7b36d4 |
| --- | --- | --- |
| 1 | `--cpp-exceptions={auto,none,catch}` flag, default `auto` (F-006e; B0) | LANDED at B0 (compile_options.cpp:154-173; B0 SF-2..4 sub-decisions) |
| 2 | Fenced std::terminate at unfenced boundaries (F-006f/l; B0) | LANDED at B0 (thunk.cpp:246 `IsCppThunkFenceRequired`, :477 `EST_BasicNoexcept`; SF-1 fence variant; boundary-identifying diagnostic deferred to B3 by SF-1) |
| 3 | Prelude `Core.Result(T, E)`, `Ok`/`Err` (F-006a; original B1) | S3p-GATED (SF-9: "how `Core.Result(T, E)` relates"; b1 plan §0.2 item 1) |
| 4 | `match` consumption of results (original B1) | LANDED at W5-S2/S3 for user-defined choices (destructuring, exhaustiveness, guards, generics) |
| 5 | Postfix `?`: suffix group, repeatable (F-006b/D2; original B2) | LANDED at B1a (postfix-loop parse; PR #15) |
| 6 | `Core.Try` + the desugar machinery (original B2) | LANDED at B1b over user choices, with the `Core.ControlFlow` carrier (PR #16); prelude `Try` IMPLS (Result/Optional) are S3p-gated |
| 7 | ImplicitAs-only error conversion (F-006c/D3; original B2) | LANDED at B1b (the `FromBreak` argument conversion) |
| 8 | D4 placement rules — declared-Try-return only, no file scope/globals (F-006d; original B2) | LANDED at B1b (seven `?` diagnostics, pre-flight) |
| 9 | `?` on an operand of SYMBOLIC type | W-071-GATED (the B1b third-fix-round narrowing; the one live `?` TODO string) — **this plan's B2 scope** |
| 10 | `Optional` implements `Try`, `BreakType = ()`, no implicit bridge (F-006i/D9) | S3p-GATED twice over: SF-9 (Optional identity) + W-070 (unit break types vs SF-6; blocked_by SF-9 in the ledger) |
| 11 | Entry points `Run() -> Result(...)`, Err → stderr + exit 1 (F-006j/D10) | S3p-GATED (they name `Core.Result`; b1 plan §0.2 item 3) |
| 12 | Catching thunks / `Result(T, Cpp.Exception)` imports (B3) | B3, gated on W5-S3p (staging table as amended; §0.3 below) |
| 13 | `Cpp.Exception` synthesis, exception_ptr-only, lazy accessors (F-006g; B3) | B3, gated on W5-S3p (`Message()` names `Core.Optional(str)`; sole producer is item 12) |
| 14 | `Carbon::expected<T, E>` export + support header, no throwing wrappers (F-006h; B3) | B3, gated on W5-S3p (the export mapping is defined ONLY for functions returning `Core.Result`) |
| 15 | try-blocks / catch-expressions (F-006k/D11) | DEFERRED past 0.1 by the ratified decision — never B2/B3 scope |

Exhaustiveness footnote (added after plan review, 2026-08-09): sub-decision
F-006l/D12 — Carbon aborts terminate without unwinding C++ frames — is a
boundary-contract statement, not a stageable implementation item; it landed
as normative doc text with B0's fence contract and is covered by row 2.
Rows 1-15 therefore exhaust F-006's stageable surface.

Conclusion, stated plainly: **original-B2's core landed at B1** (the 2026-08-08
restaging, decision-log B1 landing note). The only ungated B2-scope remainder
is row 9 — the symbolic-operand narrowing gate, work item W-071. Rows 3, 10,
11 are S3p/SF-9; rows 12-14 (all of B3) are staged after W5-S3p by the
ratified amended table. There is no `else`-style handling sugar, error-context
mechanism, or additional prelude `Try` impl anywhere in F-006's text — rows
1-15 are exhaustive; inventing more surface would be new design, not F-006.

### 0.2 In scope: B2 = discharge W-071 (symbolic-operand `?`)

-   **(a) Destroy machinery support for symbolic choice specifics** — W-071's
    candidate resolution (b), chosen in §2.1: teach
    `CanDestroyType`/`CanDestroyClass` (custom_witness.cpp) that a choice
    class specific is destroyable under symbolic arguments, on the strength
    of the SF-6 per-specific payload guarantee. No interface-contract change,
    no new prelude names, no user-facing surface minted.
-   **(b) Delete the `` `postfix `?` on an operand of symbolic type` `` TODO
    gate** (handle_question.cpp:331) and restore the positive generic
    golden — W-071's recorded discharge test (question.carbon's
    fail_todo_generic subfile flips back to the pre-gate body
    `let unused c: R.ContinueType = r?; return R.FromBreak(0);`).
-   **(c) One new conformance differential pair** exercising generic `?`
    propagation at runtime (§2.5, §8) so the discharge is
    scoreboard-arbitrated, not only dump-pinned.
-   **(d) The S3p ask package** (slice B2b): assemble the SF-9
    AskUserQuestion round material — SF-9 identity options, the W-070
    unit-break resolution options, and ratification of this plan's W-071
    option choice — since §0.3 concludes every remaining error-handling item
    hangs off that one user decision. Deliverable is decision-brief text for
    the coordinator to present; the ask itself is user-facing and
    coordinator-owned (V-2: SF-9 is a genuine fork, synchronous).

### 0.3 B3 scoping: why B3 cannot be restaged the way B1 was

The B1 restaging worked because `?`/`Core.Try` could be ARBITRATED over
user-defined choices — a full substitute substrate existed with no prelude
dependency. Each B3 item was checked for the same move, and none admits it:

1.  **Catching thunks (row 12).** The selection rule types the call
    expression as `Core.Result(S, Cpp.Exception)` — a COMPILER-minted type.
    There is no user-substitutable carrier: the compiler cannot mint values
    of a user's `MyResult`, and minting a fork-authored prelude error carrier
    for the boundary would preempt exactly the SF-9 question ("how
    `Core.Result(T, E)` relates") that the S3p split exists to protect.
2.  **`Cpp.Exception` (row 13).** Its Carbon API names `Core.Optional(str)`
    (`Message()`), and its only producer is the catching thunk — synthesized
    early it would be dead, unarbitrable surface (an R16 Goodhart shape).
3.  **`Carbon::expected` export (row 14).** The ratified mapping is "exported
    Carbon function returning `Core.Result(T, E)` appears as
    `Carbon::expected<T', E'>`" — with no prelude `Core.Result` there is no
    exportable function, so the header ships without an arbiter. The W-019
    ledger row additionally sequences B3 behind W-007 (the export.cpp /
    thunk.cpp / type_mapping.cpp five-way-contention refactor plan) and
    carries the SF-1 boundary-diagnostic follow-up — a ratified user decision
    ("recorded as a B3 follow-up", B0 SF-1) this plan does NOT pull forward.

So B3 stays where the amended staging table puts it: after W5-S3p. **The
honest critical path for error handling is the SF-9 AskUserQuestion round**,
which unblocks S3p (rows 3, 10, 11 + b1 plan §0.2 items 1-7, inherited
unchanged as S3p's opening scope) and then B3 (rows 12-14). This plan's B2 is
deliberately small because that is what is honestly ungated; the
recommendation to the orchestrator, recorded as approval-gate item 1: fire
the SF-9 round now (slice B2b's brief), land B2a in parallel, and point
further implementation capacity at a DIFFERENT next-action (F-008 threading
defect fixes or conformance depth, per ORCHESTRATION next-actions) rather
than stretching error-handling scope that F-006 does not contain.

### 0.4 Out of scope (with rationale)

-   **Everything S3p/SF-9-gated** — rows 3, 10, 11; b1 plan §0.2 boundary
    items 1-7 inherited verbatim (this plan adds NO new boundary items and
    removes none).
-   **All of B3** (rows 12-14) — §0.3; error_handling/
    cpp_exception_interop.carbon stays SKIP with its B3 evidence intact.
-   **W-070** (unit break types) — blocked_by SF-9 in the ledger; B1's R-4
    pin (fork/b1/plan.md §5: the `ControlFlow(C, ())` per-specific
    rejection) stays as-landed.
-   **The SF-1 boundary-identifying fence diagnostic** — ratified as a B3
    follow-up (decision-log B0 SF-1; W-019 notes); pulling it forward would
    reverse a user decision for no unblocking gain.
-   **W-071 option (a)** — `Destroy` bounds on `Try.ContinueType`/
    `BreakType`: an interface-contract change to a ratified doc interface,
    breaking every existing user impl's `forall` params. Offered to the user
    in the B2b brief as the S3p-round alternative; not implemented here.
-   **Real destroy-op synthesis / SF-6 widening** — MakeDestroyOpBody is an
    upstream placeholder (custom_witness.cpp:338); B2 changes the
    yes/no/format ANSWER for symbolic choice specifics, not what destruction
    executes. The §2.2 revisit note records the coupling.

---

## 1. Current state (claims re-derived from the tree at f7b36d4)

-   **The gate.** handle_question.cpp:314-332: after the pre-flight, an
    operand whose type's constant `is_symbolic()` hits
    `context.TODO(node_id, "postfix `?` on an operand of symbolic type")` —
    the fork's only live `?` TODO string (net-one, b1 plan §6 as amended).
    Pin: toolchain/check/testdata/operators/question.carbon, subfile
    fail_todo_generic (`fn PropagateOnly[R: Core.Try where .BreakType = i32]
    (r: R)`); the subfile's comment records the discharge test verbatim.
-   **Why it was gated** (B1b third fix round, decision-log B1 landing note):
    the desugar's carrier temporary gets the STANDARD cleanup discharge; for
    a symbolic operand the carrier is a symbolic `Core.ControlFlow` specific,
    and the discharge's `Core.Destroy` lookup failed eagerly —
    `MissingImplInMemberAccess` at the `?`, once per exclusive discharge
    path — because `CanDestroyType` requires every payload element
    destroyable and `Try` places no `Destroy` bound on its associated
    constants.
-   **The destroy machinery.** custom_witness.cpp: `CanDestroyClass` (:144)
    resolves the class's adapted/object repr and checks it field-wise;
    `CanDestroyType` (:176) dispatches — `ImplWitnessAccess`/
    `SymbolicBinding` → NoDestroy (:199-204), `ClassType` → `CanDestroyClass`
    (:225-231), the fork-added `CustomLayoutType` case walks a choice's
    payload region field-wise (:273-296, "restricted to trivially
    destructible payload tuples at completion time"). `LookupDestroyWitness`
    (:646-666): format == NoDestroy → nullopt; otherwise witness BUILDING is
    already deferred whenever `query_self_const_id.is_symbolic()` (:658,
    returns `SemIR::InstId::None`), so concrete monomorphizations re-derive
    their own witnesses. `MakeDestroyOpBody` is a placeholder no-op (:338)
    — but NonTrivial destroys LOWER as real calls to the resulting empty
    weak_odr function: the concrete lower golden
    (lower/testdata/operators/question.carbon:146-148, :160-162) shows three
    `_COp…core.Destroy.Core` calls on BOTH the break and continue paths of
    `_CBasic.Main` today (carrier temp, operand temp, `f.var`) — the §3/§5
    baseline (noted after plan review, 2026-08-09).
    `Class::is_choice` exists (sem_ir/class.h:85).
-   **The per-specific SF-6 guarantee.** Every instantiable specific of a
    payload-carrying choice passes `IsInSliceChoicePayloadType`
    (type.cpp:313: integer/float/bool/pointer through adapters/qualifiers
    only) — enforced at monomorphization by the S3b eval hook
    (`ChoicePayloadNotTrivialInSpecific`, eval_inst.cpp:243-249). The S1
    admitted exception stands: the allowlist does not query Destroy
    witnesses, so an adapter over a scalar with a user `Core.Destroy` impl
    passes it — harmless while destroy synthesis is a no-op, recorded in the
    decision log.
-   **B0/fence state** (rows 1-2 of §0.1): flag + `auto` resolution from
    final LangOpts + `EST_BasicNoexcept` fence, landed and PASS-arbitrated by
    the four cpp_exceptions_* conformance programs (one differential pair).
-   **Conformance ground truth.** Scoreboard totals at f7b36d4: 83 PASS /
    0 FAIL (all failure classes zero) / 30 SKIP over 113 programs, 56
    bullets. No SKIP anywhere cites the symbolic-operand gate (re-read of all
    30 SKIP evidence lines, §8). error_handling/ carries exactly ONE SKIP —
    cpp_exception_interop.carbon, pinned to B3; the other error-handling-
    adjacent SKIP, stdlib/optional_missing_ops.carbon, pins SF-9 (not B3)
    and lives outside error_handling/ (reworded after plan review,
    2026-08-09).

---

## 2. Design

### 2.1 The W-071 resolution fork (the one design decision in this plan)

W-071's ledger entry records three candidate resolutions, "decided outside a
fix round" — that is here:

-   **(a) Bound the `Try` associated constants** (`let ContinueType:
    Destroy;`-style, the `Iterate.ElementType: Copy & Destroy` precedent).
    REJECTED for B2: it amends the ratified doc's interface, forces `Destroy`
    bounds onto every user impl's `forall` params (a breaking change to the
    landed B1 surface and its goldens), and is exactly the "interface-
    contract change → veto digest / S3p round" territory the fix round
    declined. It remains the S3p-round alternative, offered in the B2b brief
    — and if the user later chooses it, option (b)'s machinery stays sound
    (bounds would make the structural answer redundant, not wrong).
-   **(b) Structural trust for choice specifics (RECOMMENDED, adopted):**
    `CanDestroyType` answers "destroyable" for a choice class specific even
    under symbolic arguments, because SF-6's per-specific enforcement is
    precisely the guarantee that every INSTANTIABLE specific's payload
    elements are allowlist-scalar. §2.2 gives the mechanism. No user-facing
    surface changes; divergence risk is nil (no name, no API — machinery
    only, in a fork-extended region of an upstream file).
-   **(c) A deferred-destroy mechanism for symbolic specifics** (defer the
    LOOKUP itself, not just witness building). REJECTED: a general
    check-machinery redesign in upstream-owned code for a problem (b) solves
    within the fork's own choice cases; largest merge surface of the three.

### 2.2 Mechanism for (b), and its honesty conditions

`CanDestroyClass` gains a choice clause: when
`context.classes().Get(class_type.class_id).is_choice` and the detection
predicate below holds, answer `DestroyFormat::NonTrivial` instead of walking
to NoDestroy. Notes, each load-bearing:

-   **Detection predicate, pinned (revised after plan review, 2026-08-09):
    the QUERY constant is symbolic** — the same
    `query_self_const_id.is_symbolic()` fact `LookupDestroyWitness` already
    branches on at :658 (threaded down or re-derived from the canonical type
    constant at the `CanDestroyType` entry; a mechanical parameter, not new
    state). Chosen over the alternative — probing the object REPR's fields
    for symbolic constants — for two reasons: (i) yes/no and build/defer
    must key on ONE predicate, or a type could be trusted structurally yet
    still attempt witness building (or the other way around); (ii) the repr under
    symbolic args may be the S3b dependent-layout sentinel or a partially
    substituted `CustomLayoutType` — probing it is exactly the walk that
    fails today, and keying on a derived artifact invites divergence.
    MIXED-specific edge behavior, named: a specific with any symbolic
    argument (`ControlFlow(i32, T)`) has a symbolic type constant, so the
    clause fires and the concrete monomorphization re-derives per specific;
    a fully concrete specific (`ControlFlow(i32, i32)`) is non-symbolic, so
    the field walk runs unchanged — concrete behavior does not move.
-   **Clause site, resolved (revised after plan review, 2026-08-09):
    `CanDestroyClass` hosts the clause**, before the object-repr field walk
    — the one frame where `is_choice` is readable off `class_info` and both
    the `ClassType` (:225) and `PartialType` (:248) entries funnel. The
    fork's `CustomLayoutType` case in `CanDestroyType` (:273) is NOT
    touched: it also serves CONCRETE choice reprs, whose field walk must
    keep running. (R-6's earlier "adjacent to the CustomLayoutType case"
    siting was inconsistent with this section and is corrected there.)
-   **`NonTrivial`, not `Trivial`.** The symbolic answer is only ever a
    yes/no: `LookupDestroyWitness` already declines to BUILD a witness for
    symbolic selves (:658), and each concrete monomorphization re-runs
    `CanDestroyType` on concrete scalar fields, computing the real format.
    Claiming `Trivial` at symbolic time would encode a format nothing
    consumes today but a future consumer could trust wrongly (the S1
    admitted-exception adapter shape: a specific whose payload adapter
    carries a user `Destroy` impl is NonTrivial concretely).
-   **Keyed on `is_choice`, nothing wider.** The `ImplWitnessAccess`/
    `SymbolicBinding` NoDestroy cases (:199-204) are untouched: a bare
    symbolic facet value still has no derivable destroy — behavior for
    non-choice symbolic types does not move (R-3's falsifier).
-   **The widening is language-wide, deliberately.** Any symbolic choice
    specific — a `var` of type `MyResult(T, E)` in a generic body, a match
    scrutinee temporary — now answers destroyable, not only `?` carriers.
    This is the uniformity the fix is FOR (the carrier discharge is "the
    same one a `var` or a match scrutinee temporary of this type would
    get", W-071 notes); the probe goldens in §3 pin the non-`?` shapes too.
-   **Revisit note (recorded obligation, the S1 precedent).** The structural
    trust is valid exactly while SF-6's per-specific allowlist holds. When
    SF-6 widens (W-070's `()` payload stays fine — trivially destructible;
    post-0.1 non-trivial payloads do NOT) or when destroy-op synthesis stops
    being a placeholder, this clause must become a real per-element witness
    check under the symbolic args. Recorded at landing as an amendment to
    W-071's successor state in fork/inventory/work-items.json, not silently.

### 2.3 Gate discharge shape (pre-declared outcomes)

With §2.2 landed, the carrier temporary's discharge resolves for every
symbolic-operand shape, and the gate at handle_question.cpp:331 is
DELETED — no narrowing gate replaces it. One residual shape needs a
pre-declared decision rather than an assumption: an operand that is ITSELF a
symbolic-typed TEMPORARY (`MakeR()?` where `fn MakeR() -> R` and `R` is a
facet binding) registers an OPERAND cleanup whose type is a `SymbolicBinding`
— outside (b)'s choice clause, so its destroy lookup still fails.

-   **Adopted policy: uniform diagnostic, no gate.** After discharge,
    `MakeR()?` diagnoses exactly what `var x: R = MakeR();` diagnoses in the
    same generic body today (the ordinary missing-destroy behavior for
    symbolic non-choice temporaries — a language-wide bound question, the
    same one upstream answers with interface bounds a la `Iterate`, not a
    `?` question). `?` gets no carve-out in either direction. Pinned by a
    side-by-side probe golden (the uniformity pin, §3).
-   **Pre-declared fallback (the b1 §3 narrowing precedent):** if the probe
    shows the `MakeR()?` shape CRASH (verifier CHECK / orphaned CFG) rather
    than diagnose cleanly, the gate is re-authored NARROWED to "symbolic-
    typed operand temporaries" with a new precise TODO string + work item,
    and §6's net-TODO count is amended from zero to one. That outcome is a
    recorded deviation, not a silent ride.

W-071's discharge test is unconditional either way: the fail_todo_generic
subfile's operand `r` is a PARAMETER (no operand temporary), so the split
flips positive under (b) alone.

### 2.4 Diagnostics

None authored. One TODO string deleted (§6). The uniformity policy (§2.3)
reuses whatever the existing symbolic-destroy diagnostic already is —
by design, no `?`-specific wording exists to review.

### 2.5 Conformance addition

NEW differential pair error_handling/question_generic_diff.carbon/.diff.cpp:
a GENERIC propagation helper (`fn Chain[...]`-shaped over a user
`MyResult(T, E)`-style choice, per-DIFF-1 conventions) instantiated at two
distinct type arguments, a `?` chain inside the generic body on the
symbolic-typed operand, failure depth selected at runtime (R16d
runtime-computed inputs); C++ oracle: a function TEMPLATE with early returns
instantiated at the matching types. This makes the W-071 discharge runtime-
arbitrated (the check/lower goldens pin dumps; the pair pins behavior), and
deepens the already-PASS "dedicated control flow constructs" bullet per
ORCHESTRATION next-action 3's differential-depth direction. Compile-verified
against the fork toolchain before commit (b1 plan §7 practice; R1 PrintStr
trap, R2 Core units noted).

---

## 3. Slices

Each independently landable through the full R11 loop (implementer → 2
adversarial reviewers → fixer → merge gate: runner autoupdate +
`bazel test //toolchain/...` + conformance non-regression), scoreboard /
work-items / decision-log updates at landing (R9). No local bazel —
verification rides CI (one red-first-CI reconciliation commit per slice,
R15/R19).

### B2a — symbolic-carrier destroy + gate discharge + conformance (M)

Scope: the §2.2 `CanDestroyClass` choice clause; delete the
handle_question.cpp gate (§2.3); restore question.carbon's generic split
positive (the W-071 discharge test) and extend it with the second symbolic
shape (`mr: MyResult(T, E)` operand inside a `forall [T: type, E: type]`-
parameterized body — spelling per the landed testdata; there is no `:!`
token in this toolchain); probe goldens (below); the lower golden for an
INSTANTIATED generic `?` (monomorphized CFG: concrete discriminant test,
payload access, FromBreak, early ret, and the SAME destroy-call shape the
concrete baseline pins — §1's noted baseline); the SF-6 negative probe
(below); the §2.5 differential pair; ledger updates (W-071 closed with
the revisit note, §6 discharge, decision-log landing note).
Exit criteria:

-   check golden question.carbon: the restored positive generic split
    (facet-bound operand `r: R`, per the recorded discharge test); the
    symbolic-choice-operand split; a non-`?` probe subfile — `var` of a
    symbolic `MyResult(T, E)` specific in the same generic body compiles
    (the §2.2 language-wide widening, pinned deliberately, not incidentally).
-   check golden fail_question.carbon (or a new probe subfile): the §2.3
    uniformity pin — `MakeR()?` and `var x: R = MakeR();` side by side,
    diagnosing identically (or the pre-declared narrowing fallback fires,
    as a recorded deviation).
-   Existing goldens: fail_todo_generic's TODO pin deleted; every OTHER
    golden byte-identical (§4).
-   lower golden (re-specified after plan review, 2026-08-09 — the original
    "no destroy call materializes" criterion was falsified AT BASELINE by
    the concrete golden, §1): the instantiated-generic `?` CFG carries the
    SAME no-op-body destroy-call shape the concrete `_CBasic.Main` baseline
    already pins (empty `weak_odr` `_COp…core.Destroy.Core` definitions,
    calls on both exclusive paths). R-1 falsification is now: a destroy
    call whose definition has a NON-EMPTY body, a USER `Destroy` impl
    invoked on the propagation path, or destroy calls ABSENT where the
    concrete baseline has them.
-   NEW negative probe, fail golden (added after plan review, 2026-08-09):
    instantiate a generic-`?` body (or the widened symbolic-choice `var`
    shape) at an SF-6-REJECTED payload type, pinning
    `ChoicePayloadNotTrivialInSpecific` as a clean DIAGNOSTIC-not-crash at
    monomorphization. Why this is newly reachable: the eval hook defers
    while any payload field is symbolic, so §2.2's trust makes BAD
    instantiations reach the mono-time destroy path for the first time —
    and eval_inst.cpp's witness lookup can leave the query unresolved and
    retry (`ConstantEvalResult::NewSamePhase`, :433-434), the S3b
    resolution-order lesson. Risk R-8's falsifier.
-   Conformance: question_generic_diff PASSes both toolchain and oracle;
    floor 84/0/30 over 114 (§8); `runner.py --self-test` OK; README table
    regenerated (DIFF-4).

### B2b — the S3p ask package (S, document-only, coordinator-owned handoff)

Scope: a decision brief (fork/design-sprint/s3p-ask.md) assembling the
queued SF-9 round: (i) SF-9's three `Core.Optional` identity options and
"how `Core.Result` relates" (from the OPEN-forks entry and W-058); (ii)
W-070's two recorded unit-break resolutions; (iii) this plan's W-071
option-(b) adoption presented for ratification with option (a) as the
alternative — INCLUDING the plan's deviation from the ledger's option-(b)
wording (revised after plan review, 2026-08-09): W-071's notes say "teach
the destroy machinery that an SF-6-admissible choice specific is TRIVIALLY
destructible"; §2.2 deliberately answers `NonTrivial`-deferred instead, and
the brief surfaces that delta for ratification rather than silently
narrowing it; (iv) the S3p opening scope = b1 plan §0.2 items 1-7, restated
with their post-B2 status; (v) the B3 unblock chain (§0.3) so the user sees
what the decision releases. No decisions are made in the brief — it is ask
material for the coordinator's AskUserQuestion round (V-2 synchronous: SF-9
is a genuine fork). Exit criteria: brief exists, cites only verifiable
tree/ledger state (reviewer #2's citation spot-check applies), prek-clean.

Dependency: B2a and B2b are independent; neither blocks the other. B2b
SHOULD land (or at least be presented) promptly — it is the critical path
for everything in §0.1 rows 3, 10-14.

---

## 4. Byte-equivalence expectations

-   **B2a is behavior-widening by design, in one direction only.** Programs
    that previously diagnosed missing-destroy on SYMBOLIC CHOICE specifics
    now compile; nothing that compiled before changes meaning. Expected
    golden movement, enumerated: fail_todo_generic (TODO pin → positive),
    plus the new/probe subfiles. Pre-implementation grep obligation: every
    testdata hit for `MissingImplInMemberAccess`-on-choice-specific and
    every golden naming `Core.Destroy` near choice types is listed before
    the change; expected count of OTHER movements: zero. ANY movement
    outside the enumerated set — including ID-only churn — is a
    stop-and-explain event with a written §4 amendment (S3b precedent).
-   **No parse, no lowering, no prelude changes.** core/prelude/try.carbon
    is untouched (no new names — V-3a surface check: nothing public-facing
    is minted in B2a); lowering consumes the same inst kinds; the fence/
    driver files are untouched.

## 5. Risk register (falsifiable)

-   **R-1. The structural trust is unsound for some instantiable specific.**
    FALSIFIERS (re-specified after plan review, 2026-08-09 — the original
    "any destroy call is falsification" phrasing was wrong at baseline,
    since concrete NonTrivial destroys already lower as calls to empty
    no-op bodies, §1): the lower golden's instantiated-generic CFG — a
    concrete specific whose witness fails to re-derive at monomorphization,
    a destroy call whose definition body is NON-EMPTY, a USER `Destroy`
    impl invoked on the propagation path, or destroy calls ABSENT where the
    concrete baseline has them; the S1 adapter shape (a payload adapter
    with a user `Core.Destroy` impl) exercised as a probe — it must still
    behave as today concretely, with §2.2's revisit note carrying the
    future obligation.
-   **R-2. The widening leaks past choices.** FALSIFIER: the non-choice
    symbolic cases (:199-204) answering destroyable anywhere — pinned by the
    §2.3 uniformity probe (`var x: R = MakeR();` must NOT start compiling in
    B2a; if it does, the clause is keyed too wide).
-   **R-3. The `MakeR()?` operand-temporary shape crashes instead of
    diagnosing.** FALSIFIER: the uniformity pin producing a verifier CHECK,
    orphaned block, or silent compile. Response is pre-declared (§2.3
    fallback): narrowed gate + new work item + net-TODO amendment — a
    recorded deviation, not a fix-round improvisation.
-   **R-4. Existing-golden blast radius.** FALSIFIER: post-autoupdate diff
    shows movement outside §4's enumerated set. Ladder: ID-only → written §4
    amendment; content → halt and root-cause before landing.
-   **R-5. The differential pair Goodharts to the check golden.** FALSIFIER:
    the pair must fail against a deliberately-broken oracle (flip the
    injected failure depth once locally during authoring — the DIFF-1
    mismatch-is-the-arbiter discipline); an always-green pair is
    falsification, not success.
-   **R-6. Upstream collision (standing rule 5 / V-3a).** custom_witness.cpp
    is upstream-owned and destroy synthesis is active upstream work
    (`MakeDestroyOpBody` placeholder churn risk) — CONCRETELY (noted after
    plan review, 2026-08-09): upstream commit 453b547 (upstream #7553)
    touches `CanDestroyType`'s symbolic-facet `Destroy` CHECK, that is the
    exact dispatch this plan's clause sits beside. Re-check
    carbon-language/carbon-lang for that line of work and any further
    destroy-synthesis changes before B2a implementation; a hit escalates to
    the orchestrator. The choice clause lands in `CanDestroyClass` (§2.2's
    resolved site — corrected here from this plan's earlier
    "CustomLayoutType-adjacent" siting), a function upstream also owns, so
    the weekly-merge exposure is real and budgeted. No public names are
    minted, so no new divergence-register entries; the existing
    `ControlFlow`/`Try`/`Ok`/`Err` entries stand for the weekly upstream
    review unchanged.
-   **R-8. Mono-time reachability of SF-6-rejected instantiations.** §2.2's
    trust makes a bad instantiation reach the destroy path at
    monomorphization for the first time (added after plan review,
    2026-08-09). FALSIFIER: the §3 negative probe producing anything other
    than the clean `ChoicePayloadNotTrivialInSpecific` diagnostic — a
    CARBON_CHECK crash, an unresolved-witness eval loop (the
    `NewSamePhase` retry, eval_inst.cpp:433-434, the S3b resolution-order
    lesson), or a silent compile each falsify the clause's interaction with
    the eval hook, not just the golden. (Label R-7 is skipped — it would
    collide with the R-7 cleanups rule referenced in §9, the w5-s3/b1
    plans' convention.)

## 6. TODO-string discharge ledger

-   `` `postfix `?` on an operand of symbolic type` `` — DISCHARGED at B2a:
    the handle_question.cpp:331 emission site is deleted (the phrase may
    survive only in prose comments/history); the pin flips from
    fail_todo_generic's TODO lines to the restored positive split. W-071
    closes with the §2.2 revisit note recorded. **Net TODO strings across
    B2: zero** (amended to one only under §2.3's pre-declared fallback,
    which would be a dated deviation in this section).
-   All other TODO strings (the six-site combined W4 string, the scrutinee
    string, the `var`/`ref` case-binding string, S2e's integer-`default`
    string, the Self-dependent payload string) survive BYTE-IDENTICAL; B2
    touches none of them.
-   SKIP evidence: NO SKIP text changes in B2. cpp_exception_interop's B3
    evidence stays accurate (`Core.Result` still absent — §0.3);
    optional_missing_ops stays pinned to SF-9. (Re-verified: no SKIP quotes
    the symbolic-operand gate.)

## 7. Testdata & golden flow

House rules as at B1: new failing subfiles ship hand-written CHECK:STDERR
pins; positive CHECK content rides the runner autoupdate (R15/R19, one
red-first-CI reconciliation commit per slice); clang-format by way of hooks
(R12/R18); `runner.py --self-test` before conformance-touching commits;
private `--out` (R5); prek locally before every push (R23/R25). The
differential pair follows DIFF-1..4 conventions; program bodies
compile-verified against the fork toolchain before commit. B2b is
document-only: prek + citation spot-check.

## 8. Conformance floor arithmetic

Starting floor (fork/conformance/out/scoreboard.json at f7b36d4): **83 PASS
/ 0 FAIL / 30 SKIP over 113 programs** (56 bullets, 42 green).

-   **B2a: one addition, no flips** — NEW
    error_handling/question_generic_diff pair: **84 PASS / 0 FAIL / 30 SKIP
    over 114.** No SKIP can honestly flip in B2 (each of the 30 re-read
    against its evidence line): cpp_exception_interop (B3: catching thunks +
    `Core.Result` + `Cpp.Exception` — §0.3), stdlib/optional_missing_ops
    (SF-9 placeholder API → S3p), control_flow/if_let_let_else (F-011
    implementation, a sibling workstream), control_flow/
    match_sum_type_payload (W5-S4 std::variant mapping),
    interop/cpp_threading_atomics (F-008), and the 25 others (unions,
    overloading, structural conformance, variadics, templates lowering,
    slices/span, string ops, code-org/link, project/docs bullets) — none
    cites `?`, `Try`, destroy, or symbolic-operand evidence.
-   **B2b: no movement** (document-only). The S3p round it enables is where
    the next error-handling flips live (optional_missing_ops at S3p;
    cpp_exception_interop at B3).
-   FAIL stays 0 throughout; scoreboard regeneration rides the landing gate
    (`Fork: conformance suite`, R9); README table by way of
    `runner.py --update-readme-table` (DIFF-4).

## 9. Standing constraints (named boundaries)

-   **SF-9** (OPEN): no prelude `Core.Result`/`Core.Optional` work of any
    kind in B2; B2b packages the ask, decides nothing.
-   **W-070**: unit break types stay inexpressible; the R-4 pin from B1
    stays as-landed; resolution rides the S3p round.
-   **W-071**: discharged by B2a per §2.1-2.3; the option-(a) alternative is
    preserved for the user in B2b's brief; the §2.2 revisit note is the
    recorded residue.
-   **V-3a**: B2a mints no public-facing surface (no names, no API, no doc
    semantics change), so no new upstream-divergence register entries; R-6's
    pre-implementation upstream check applies to the destroy machinery.
-   **R-7 cleanups discipline**: B2a's only cleanup-relevant change is that
    symbolic choice carriers now REGISTER dischargeable cleanups instead of
    erroring; the discharge placement (statement-end vs return-path,
    exclusive) is unchanged from B1's §2.8 argument and re-pinned by the
    restored generic goldens.

## Approval gate

This plan does not authorize implementation. Per house protocol it went to
TWO adversarial plan reviewers (round 1 complete, 2026-08-09 — findings
folded in above: the lower-golden/R-1 baseline re-specification, the R-8
negative probe, the §2.2 predicate and clause-site pins, the digest-item-2
widening statement, the B2b Trivial→NonTrivial ratification item, and the
citation/spelling corrections; option (b)'s core design was verified sound
against the machinery). The revised plan re-reviews until both pass. Briefs:
reviewer #1 attacks §2.2's soundness (the structural-trust argument against
the SF-6 hook's actual guarantees, the NonTrivial-vs-Trivial format choice,
the `MakeR()?` operand-temporary analysis, R-2's leak surface) with concrete
counter-programs; reviewer #2 attacks the §0.1 classification for omissions
(anything in F-006's text not in rows 1-15), the §0.3 no-restaging argument,
the §4 enumerated-churn claim, §8's no-flip enumeration, and spot-checks
every file:line citation against the tree (the mandate from B1's round 1).

Items the coordinator signs off on (the V-2 veto digest for this plan):

1.  **The scoping resolution (§0.1-0.3):** B2 = the W-071 discharge (the
    only ungated F-006 remainder); B3 stays post-S3p (not restageable); the
    recommendation to fire the SF-9 round now and direct surplus capacity to
    a different workstream rather than widening error-handling scope.
2.  **W-071 resolution = option (b)** (§2.1-2.2): structural trust for
    choice specifics in the destroy machinery, `NonTrivial`-deferred, keyed
    on `is_choice` + the symbolic-query predicate, hosted in
    `CanDestroyClass`, with the recorded revisit note — **explicitly
    including the LANGUAGE-WIDE widening (stated after plan review,
    2026-08-09): plain `var`s and `match` scrutinees of symbolic choice
    specifics in generic bodies newly compile, not only `?` operands**;
    option (a) explicitly preserved as the user's S3p alternative in the
    B2b brief, alongside the Trivial→NonTrivial deviation from the W-071
    ledger wording (§3 B2b item iii).
3.  **The uniformity policy (§2.3):** the gate is deleted outright;
    symbolic-typed operand TEMPORARIES diagnose like any other symbolic
    temporary (no `?` carve-out), with the pre-declared narrowed-gate
    fallback as the only sanctioned deviation.
4.  **TODO ledger movement (§6):** the symbolic-operand string discharged;
    net `?` TODO count returns to zero.
5.  **Conformance movement (§8):** the question_generic_diff pair, target
    floor 84/0/30 over 114; no SKIP flips claimed.
6.  **The B2b ask package** (§3): scope of the SF-9/S3p brief, including
    presenting W-070's options and W-071's ratification alongside SF-9.
