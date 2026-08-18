<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-072 plan: projection rewrite-reduction under symbolic arguments — the `final impl` lane and threading arbitration

Status: PLAN, AMENDED after adversarial review (process step 6, scaled loop).
Drafted 2026-08-17; fix round 2026-08-18. Title revised at the fix round: the
`Try` success constructor (W72c) is CUT from this plan per coordinator
adjudication — see the Amendments log and §0.3.
Baseline: trunk a34ebfb (post-PR #22, F-008 complete; conformance **90 PASS /
0 FAIL / 29 SKIP over 119 programs**). Design authority:
docs/design/generics/details.md (specialization + `final impl` sections),
docs/design/error_handling.md (Try section as amended at B1b),
proposals p000983 / p002868 / p005337, the F-006 decision-log entries with the
B1/B2a landing notes, fork/b1/plan.md §2.6, fork/b2/plan.md (whose §2.3
uniformity policy this plan composes with), and the W-072 ledger entry in
fork/inventory/work-items.json. Precedent format: fork/b2/plan.md. NO
implementation in this document — planning only. No local bazel: all
verification rides the self-hosted runner CI (golden autoupdate to fixpoint
per R26; conformance suite per R9).

## Amendments (2026-08-18, post-review fix round)

Both adversarial plan reviews returned APPROVE-WITH-AMENDMENTS (correctness
F-1..F-5; strictness F-1..F-6), and the coordinator adjudicated strictness
F-4. Every amendment below is applied and integrated into the sections it
names (the b1/f008 dated-amendment pattern — "added/revised after plan
review, 2026-08-18" at each touched site).

-   **ADJ — coordinator adjudication of strictness F-4: W72c
    (`Try.FromContinue`) is CUT from this plan** and parked in the SF-9/S3p
    brief, where the B2a landing note routed it — a digest-adopted routing is
    not re-opened without a new-information acknowledgment from the user. The
    plan is now W72a + W72b only. §0.3 retains the non-goal paragraph with
    W72c's content, the new-information note (the §0.1 dissolution makes
    generic transformers expressible), the RECURRENCE FLAG as brief material
    (S3p's future prelude `Result`/`Optional` `Try` impls MUST be spelled
    `final`; the doc sketches already are), and the standing re-staging
    instruction. Floor ladder recomputed: 90/0/29//119 → W72a unchanged →
    W72b 91/0/29//120. Touched: title, §0.2, §0.3, §1 (sweep-surface note),
    §2.4 step 3, §2.5 (tombstoned), §3, §4, §5 (R-9 retired), §6, §7, §8,
    §9, approval gate + digest items 4/6.
-   **Correctness F-1 — the claim-3 history hole.** The §0.1 assertion that
    the doc's sketches "already carry `final`" now carries its verified
    history: `final` in the doc since the original F-006 commit 9fdad04; the
    non-final testdata idiom entered at B1b 6b0b80e; the third-round
    correction 3099532 quoted the doc's final-spelled sketches while
    recording non-reduction. Touched: §0.1 item 4.
-   **Correctness F-2 — the in-body counter-evidence.** §2.2 gains the
    paragraph distinguishing the in-body non-collapse path
    (`GetImplSelfWitnessInsideImplDecl`, impl_lookup.cpp:1186-1190, which
    skips `RequireSpecificDefinition` per :294-296) from the out-of-body
    candidate-collection path P-1 exercises — defusing B1b's recorded
    non-collapse as standing counter-evidence. Touched: §2.2.
-   **Correctness F-3 — choice-self precedent citations.** §2.2 now cites
    specialization_with_symbolic_rewrite.carbon:26,65 (bare-`T` reduction +
    the designed non-final FAIL), validate_impl_constraints.carbon:94
    (parameterized-class self), and the choice-is-a-class dependency
    (sem_ir/class.h:85 `is_choice`; impl_validation.cpp:112-131 `ClassStart`
    arm accepting a choice root self). Touched: §2.2.
-   **Correctness F-4 — P-3's empty falsifier cell** filled: deduction
    failure on the partially-concrete query ⇒ §2.4 step 2. Touched: §3 probe
    table.
-   **Correctness F-5 — P-6 diagnostic prediction** now names the candidate
    diagnostic families by their pinning testdata
    (specialization_poison.carbon / impl_overlap.carbon). Touched: §3 probe
    table.
-   **Strictness F-1 — postmortem + loop fix.** §0.1 gains the postmortem
    sentence (the omission survived because testdata was reviewed against
    the doc's SEMANTICS, never diffed against the sketch's exact spelling —
    and 3099532 edited the very lines carrying `final`); W72a stages the
    rulebook amendment R27 (sketch-spelling diff before landing). Touched:
    §0.1 item 4, §3 W72a, §6.
-   **Strictness F-2 — the min_prelude mirror** (mostly moot with W72c cut):
    toolchain/testing/testdata/min_prelude/{try.carbon,parts/try.carbon}
    added to the §4 sweep obligations for W72a/W72b — any Try-adjacent
    golden churn checks BOTH preludes — and the drift hazard is flagged for
    the future W72c in §0.3. Touched: §4, §0.3.
-   **Strictness F-3 — the record-honesty sweep list completed**:
    question_generic_diff.carbon:92 inline comment,
    question_generic_diff.diff.cpp:51 oracle comment, the decision-log
    RETRACTION obligation (the :697-726 overstated claims named, two-part
    correction specified), the EIGHT-file "does not type-collapse" comment
    family with P-9's new MINTING rule, ORCHESTRATION.md:63-64 noted as
    historical (no retro-edit; the new stamp carries the correction).
    Touched: §3 W72a (new sweep list + P-9 row), §3 W72b, §6.
-   **Strictness F-5 — broken-oracle drill mechanism declared** (no local
    bazel, so "flip during authoring" needed a mechanism): the B2a-style
    deliberate red CI push is picked and declared in W72b. Touched: §3 W72b.
-   **Strictness F-6 — W72b/W72c supersession**: moot with W72c cut; W72b's
    comment-only claim about the existing pair now stands unqualified for
    the plan's whole horizon (no later slice of this plan touches the pair's
    program semantics). Touched: §3 W72b.

## Amendment (2026-08-18, W72a fix round — post-regen outcomes)

-   **P-9 outcome: the falsification branch FIRED.** The 3d261c0 regen
    showed the in-body probe — `return self.(Core.Try.Branch)();` under the
    final impl — compiling CLEAN: the in-body recursive call type-collapses
    under `final` TOO. The §2.2 in-body-unchanged account (correctness
    F-2's defusal) is empirically FALSIFIED in the collapse direction: the
    completed definition's body does not route through the
    `GetImplSelfWitnessInsideImplDecl` intercept (impl_lookup.cpp:949-963 —
    it answers only while the impl decl is still being constructed, by way of
    declaring_impl_decls), so the ordinary candidate path applies the
    final-impl rewrite. Processed per the §3 P-9 row's minting rule: the
    split moved OUT of fail_question_final.carbon into
    question_final.carbon as the positive inbody_recursive_branch.carbon
    (zero diagnostics is the pin), and **W-073 is the minted follow-up**
    (fork/inventory/work-items.json) — the eight-file "does not
    type-collapse" family + b1 §2.6 dated-correction retext, and the
    EVALUATION of retiring the `Diverge` idiom in final-spelled impls,
    gated on W72b's runtime arbiter. Non-final sites stay valid; the §0.3
    "idiom is not revised in this plan" boundary holds — the revision is
    W-073's, not W72a's.
-   **§2.4 contingency ladder: RESOLVED-CLEAN.** P-1/P-2/P-3/P-8 landed
    positive on the 3d261c0 regen; step 1 taken, steps 2/3 never invoked
    and closed for W72a (decision-log follow-up lines carry the record).
-   **P-6 hygiene (both reviews' minor):** the disagreeing impl's
    `.ContinueType` is swapped `()` → `bool` so the overlap pin decouples
    from the W-070 unit-payload wart; the incidental
    IncompleteType/ChoicePayload pins drop and the next regen reconciles
    the overlap family alone.

---

## 0. Scope classification — the upstream-alignment verdict (the centerpiece)

### 0.1 The verdict: non-reduction through non-`final` impls is upstream-DESIGNED, and the designed spelling for reduction already exists

W-072's symptom: with `impl forall [T: type, E: type] MyResult(T, E) as
Core.Try where .ContinueType = T ...`, the `?` continue value on an operand of
type `MyResult(T, i32)` types as the unreduced projection
`MyResult(T, i32).(Core.Try.ContinueType)`, not `T`
(toolchain/check/testdata/operators/question.carbon, generic.carbon subfile
:279-288, the recorded wart; fork/conformance/programs/error_handling/
question_generic_diff.carbon:28-41, the honest scope narrowing). The ledger
offered candidates (a) eval-side reduction, (b) desugar-side annotation,
(c) documented wart. The V-3a check settles it — the mechanism, re-derived
from the tree:

1.  **Where reduction happens when it happens.** `EvalConstantInst(...,
    SemIR::ImplWitnessAccess)` (toolchain/check/eval_inst.cpp:593-670) has two
    productive arms. (i) A RESOLVED witness (`ImplWitness`, :598-620): the
    access reads the impl's witness table element and applies the impl's
    deduced specific — `GetConstantValueInSpecific(witness.specific_id,
    element)` (:612-613) — which is exactly "apply the impl's `where` rewrite
    with the specific's substitution" (`.ContinueType = T` becomes the query's
    argument). (ii) An UNRESOLVED symbolic witness (`LookupImplWitness`,
    :637-664): the only reduction source is the SELF FACET TYPE's own rewrite
    constraints, searched by `TryFindValueInRewriteConstraints` (:447-591).
    That search bails immediately when the query self has type `type`
    (:453-457: "A self facet of type `type` has no rewrite constraints to look
    in") — which is why facet-BINDING rewrites reduce (`R: Core.Try where
    .BreakType = i32` puts the rewrite in R's facet type; the W-071 discharge
    body's `R.FromBreak(0)` checks) while impl-lookup projections on a choice
    specific like `MyResult(T, i32)` (a `type`-typed self) do not.
2.  **Why the witness stays unresolved under a symbolic query.**
    `EvalConstantInst(..., SemIR::LookupImplWitness)` (eval_inst.cpp:420-442)
    calls `EvalLookupSingleFinalWitness` (impl_lookup.cpp:1170-1258), which
    collects candidates with `final_only = !query_is_concrete` (:1253-1258).
    `CollectCandidateImplsForQuery` filters non-final candidates out under
    `final_only` (:690-693) by way of `TreatImplAsFinal` (:232-238) →
    `IsImplEffectivelyFinal` (impl.cpp:980-984): an impl counts only if it is
    declared `final`, is fully concrete, or is the impl currently being
    defined. The fork's testdata/conformance `Core.Try` impls are none of
    these under a symbolic query — so the lookup deliberately returns nothing,
    the witness stays a `LookupImplWitness`, and the projection stays opaque.
3.  **This refusal is accepted upstream design, not a gap.**
    docs/design/generics/details.md, "`final` impl declarations" (~:5149-5262)
    states both halves explicitly: a non-final parameterized impl can be
    SPECIALIZED at monomorphization, so "the compiler can't assume anything
    about the return type" through it — and "If the Carbon compiler sees a
    matching `final` impl, it can assume it won't be specialized so it can use
    the assignments of the associated constants in that impl definition."
    Ratified in proposals p000983 (Generics details 7: final impls), p002868,
    p005337. Upstream testdata pins BOTH directions:
    toolchain/check/testdata/impl/lookup/specialization_with_symbolic_rewrite.carbon
    — `final_impl_rewrite_of_symbolic_through_impl_lookup.carbon` (`final impl
    forall [U: type] U as Ptr where .Type = U*` makes `T.(Ptr.Type)` reduce to
    `T*` under symbolic `T`, through impl lookup) versus
    `fail_nonfinal_specialized_symbolic_rewrite.carbon` (the identical shape
    without `final` is a FAIL test by design). find_in_final.carbon and
    import_final.carbon pin the facet-precedence and import sides.
4.  **The fork's own ratified design already prescribes the spelling.** The
    F-006 impl sketches in docs/design/error_handling.md are `final impl
    forall [T: type, E: type] Result(T, E) as Try ...` (:367) and `final impl
    forall [T: type] Optional(T) as Try ...` (:381). The B1b/B2a
    testdata/conformance idiom dropped the `final` the doc carries — the wart
    is, on this evidence, an IDIOM gap in fork-authored programs, not a
    compiler gap. _History (added after plan review, 2026-08-18 — the
    claim-3 answer, verified against the fork history):_ the `final`
    spelling has been in the doc's impl sketches since the ORIGINAL F-006
    design commit (9fdad04); the non-final testdata idiom entered at B1b
    (6b0b80e); the third-round correction (3099532) QUOTED the doc's
    final-spelled sketches while recording non-reduction — it edited the
    very lines carrying `final` without connecting the modifier to the
    behavior. _Postmortem (strictness F-1):_ the omission survived every
    review because testdata was reviewed against the doc's SEMANTICS, never
    diffed against the sketch's exact spelling. The loop fix is the W72a
    rulebook amendment (§3, R27).

**Verdict, applied per V-3a:**

-   **Candidate (a) — eval-side reduction through the resolved non-final
    impl: VETOED (contradiction).** Upstream's eval already applies an impl's
    rewrites exactly when sound (final / effectively-final / being-defined)
    and refuses otherwise BY DESIGN (specialization soundness — a
    more-specific impl may match at monomorphization with a different
    `ContinueType`). Unconditional application contradicts p000983 and the
    details.md doctrine; the fail_nonfinal testdata pins the refusal.
    Restricted-to-final application is already implemented — nothing to build.
-   **Candidate (b) — desugar-side annotation: VETOED (same contradiction,
    plus a carve-out).** handle_question.cpp holds no resolved operand
    witness to read: the pre-flight `LookupImplWitness` (:267-270) is on the
    RETURN type and uses only its yes/no; the continue type is read off the
    `Branch` call's carrier type (:346-347, :355-360, element_type_id
    :109-114). Annotating would mean running a fresh lookup and committing to
    a non-final impl — the identical unsoundness, localized — and would mint a
    `?`-only reduction rule, violating the B2a uniformity policy ("`?` gets no
    carve-out in either direction", b2 plan §2.3 / digest item 3).
-   **Candidate (c) — documented wart: unnecessary as the primary lane;
    retained as the pre-declared fallback (§2.4).**
-   **Chosen: candidate (d), the `final impl` lane** — align the fork's
    testdata / conformance / doc-example idiom with the ratified doc's own
    `final` spelling. Predicted outcome: the continue value of `mr?` types as
    `T`, so it can be bound `: T`, passed as `T`, and wrapped by `Ok(v)`. NO
    compiler change is expected; the slices are probe-goldens, conformance
    arbitration, and the adjacent `Try` surface item. Upstream alignment is
    UNAMBIGUOUS here, so per V-3a this proceeds at full speed with the choice
    recorded in the veto digest — the (a)-vs-(b) "genuine fork" contingency in
    the ledger dissolves (both are on the contradiction side of the line).

W-072 accordingly reclassifies from "language gap" to "idiom gap +
verification gap", pending the W72a probes (§2.3's contingency ladder covers
the case where the never-exercised combination — final impl × generic choice ×
`Try` × `?` — surfaces a machinery defect).

### 0.2 In scope

-   **W72a** — the final-impl reduction probe goldens: new check/lower
    testdata pinning `T`-typed threading of `?` continue values under a
    `final impl`, the negative pins (non-final stays unreduced; facet-binding
    scope; specialization-vs-final diagnostics; import parity), and the wart
    comment retext. No compiler-source changes expected.
-   **W72b** — runtime arbitration: a NEW conformance differential pair
    threading generic `?` continue values as `T` through a chain, C++
    function-template oracle; the existing pair's W-072 header pointer updated
    (comment-only).
    _(Revised after plan review, 2026-08-18: the draft's third slice — W72c, the
    `Core.Try` success constructor — is CUT by coordinator adjudication and
    parked in the SF-9/S3p brief; see §0.3. The plan is W72a + W72b only.)_

### 0.3 Out of scope (with rationale)

-   **W72c — the `Core.Try` success constructor (`FromContinue`) — CUT at
    coordinator adjudication (2026-08-18, strictness F-4) and PARKED in the
    SF-9/S3p brief, where the B2a landing note routed it.** A digest-adopted
    routing decision is not re-opened without a new-information
    acknowledgment from the user, so pulling the interface amendment into
    this plan was out of order. Retained content, for the brief: one member
    appended LAST in `interface Try` (core/prelude/try.carbon and its
    min_prelude mirrors — the strictness F-2 drift hazard:
    toolchain/testing/testdata/min_prelude/{try.carbon,parts/try.carbon}
    must be amended in the same commit or the preludes drift) — `fn
    FromContinue(c: ContinueType) -> Self;`, the Rust `Try::from_output`
    analogue, `FromBreak` name symmetry, append-last keeping witness-table
    indices stable, the `?` desugar untouched (it resolves members by name,
    handle_question.cpp:395-397, and never calls `FromContinue`); the doc
    amendment; the tree-wide fork-owned impl sweep (§1's 9-file list plus
    whatever W72a/W72b add); and a generic-transformer differential pair as
    the arbiter (no dead surface — the R16 Goodhart shape). NEW-INFORMATION
    NOTE, carried to the brief rather than acted on here: the §0.1
    dissolution makes facet-generic Result-transformers EXPRESSIBLE once the
    final-impl lane lands, and `FromContinue` is the missing
    Ok-reconstruction half — the brief should present the item as
    unblocked-but-parked. RECURRENCE FLAG (brief material): S3p's future
    prelude `Result`/`Optional` `Try` impls MUST be spelled `final` — the
    doc sketches already are (§0.1 item 4) — or the W-072 wart recurs in the
    prelude. STANDING INSTRUCTION: W72c re-stages when SF-9 resolves, or
    earlier if the user pulls it forward.
-   **Anything SF-9-dependent.** SF-9 is digest-pending with default DEFER:
    no prelude `Core.Result`/`Core.Optional`, no prelude `Try` impls, no
    carrier-identity assumptions. (The draft argued W72c SF-9-INDEPENDENT;
    with W72c cut and parked, the argument travels to the brief as
    supporting material, not as a live claim of this plan.)
-   **B3** (catching thunks, `Cpp.Exception`, `Carbon::expected`) — staged
    after W5-S3p by the ratified table; untouched.
-   **W-070** (unit break types) — rides the S3p round; untouched.
-   **Eval/impl-lookup machinery changes.** The lane needs none; if a probe
    surfaces a narrow defect in upstream's final-impl reduction path, fixing
    it is upstream-ALIGNED work but a pre-declared deviation (§2.4), not
    silent scope growth.
-   **The `==` equality-constraint workaround** details.md sketches for
    non-final impls (`where Optional(T).(Deref.Result) == .Self`) — not
    implemented in the toolchain; not relied on.
-   **The in-body trailing-return idiom** (b1 plan §2.6 `Diverge` helper).
    In-body lookups are already treated as final (`impl.is_being_defined()`,
    impl_lookup.cpp:237) yet B1b recorded non-collapse; whether `final`
    changes in-body behavior is an OBSERVATION probe (R-8), never a gate, and
    the idiom is not revised in this plan.

---

## 1. Current state (claims re-derived from the tree at a34ebfb)

-   **The wart's pins.** question.carbon generic.carbon subfile: non-final
    `impl forall ... MyResult(T, E) as Core.Try where .ContinueType = T and
    .BreakType = E` (:236-252); `PropagateChoice` consumes `mr?` through the
    deduced `Discard` sink with the wart comment (:279-288); `PropagateOnly`
    pins the facet-binding contrast — `R: Core.Try where .BreakType = i32`
    reduces `FromBreak`'s argument conversion, while `R.ContinueType` stays a
    projection consumed by way of a projection-annotated binding (:271-274).
    question_generic_diff.carbon:28-41 carries the honest scope narrowing
    ("continue-THREADING runtime arbitration is W-072 follow-up"); its Chain
    (:94-98) discards continue values and reconstructs Ok from the seed.
-   **The desugar.** handle_question.cpp: pre-flight witness check on the
    return type only, yes/no consumed (:240-296); `Branch` by way of
    `BuildUnaryOperator` (:333-341); continue type = the carrier's Continue
    payload element type (`ResolveCarrierPayload` :86-115, used :355-360);
    continue value emitted at :415-416. The desugar never reads the witness
    table directly (:327-332 comment).
-   **The reduction machinery** — §0.1 items 1-2 (eval_inst.cpp:593-670,
    :420-442; impl_lookup.cpp:1170-1258, :690-693, :232-238; impl.cpp:980-984;
    the deduced-specific witness at impl_lookup.cpp:245-307, incl. the
    `RequireSpecificDefinition` registration :288-303).
-   **Known final-impl constraints to design probes around.** (i) A `final
    impl` must be in the same file as its root self type or the interface
    (impl_validation.cpp:102-148, `FinalImplInvalidFile`) — every probe
    declares the choice and its final impl in one file. (ii) `final` is
    rejected inside `match_first` (handle_impl.cpp:328). (iii) The
    `.Self`-replacement cycle guard suppresses symbolic final lookups while
    identifying facet types (impl_lookup.cpp:335-361; :1240-1242), with an
    upstream TODO admitting it "prevents some legitimate code" — a candidate
    root cause if a probe unexpectedly fails to reduce.
-   **`Core.Try` today** (core/prelude/try.carbon): `ContinueType`,
    `BreakType`, `Branch`, `FromBreak` — no success constructor. Tree-wide
    `as Core.Try` impl sites (the sweep surface of the CUT W72c, kept here as
    the parked brief item's ground truth — 9 files):
    check/testdata/operators/{question,fail_question}.carbon,
    lower/testdata/operators/{question,question_generic,question_generic_mixed,question_generic_crossfile}.carbon,
    conformance error_handling/{control_flow_constructs,question_propagation_diff,question_generic_diff}.carbon.
    All fork-owned; no prelude impls exist (S3p-gated).
-   **Conformance ground truth.** 90 PASS / 0 FAIL / 29 SKIP over 119
    (fork/conformance/out/scoreboard.json, regenerated post-PR #22). No SKIP
    cites W-072, `Try`, `?`, or projection evidence (re-grep of all SKIP
    programs) — so no SKIP flip is honestly claimable; floor movement in this
    plan is by ADDITION only.

---

## 2. Design

### 2.1 The lane decision (recorded)

| Candidate | V-3a status | Disposition |
| --- | --- | --- |
| (a) eval-side reduction by way of resolved non-final impl | CONTRADICTS p000983 / details.md specialization doctrine; the refusal is pinned by upstream fail testdata | VETOED |
| (b) desugar-side continue-type annotation | Same commitment localized + a `?`-only carve-out (violates the B2a uniformity policy) | VETOED |
| (c) documented wart | Aligned but unnecessary as primary | FALLBACK ONLY (§2.4) |
| (d) `final impl` idiom (ADOPTED) | Upstream-designed mechanism, already implemented; the fork's ratified doc sketches already spell it | Full speed; digest item 1 |

### 2.2 Predicted mechanism for (d), and its honesty conditions

With `final impl forall [T: type, E: type] MyResult(T, E) as Core.Try where
.ContinueType = T and .BreakType = E {...}` in the same file as `MyResult`:

-   Under the symbolic query `MyResult(T', i32) as Core.Try`,
    `EvalLookupSingleFinalWitness` now finds the impl (`impl.is_final` ⇒
    passes the :690 filter), deduces its specific from the query
    (`TryGetSpecificWitnessIdForImpl`), and returns the impl witness with the
    specific applied (:305-306). The projection then reduces through the
    `ImplWitness` arm (eval_inst.cpp:598-620): `ContinueType` ↦ `T'`,
    `BreakType` ↦ `i32`.
-   The `?` desugar is UNTOUCHED: the `Branch` call's carrier type becomes
    `Core.ControlFlow(T', i32)` with reduced arguments, so
    `ResolveCarrierPayload`'s `element_type_id` is `T'` and the continue value
    binds `: T'`, passes as `T'`, wraps as `Ok(v)`.
-   The B2a destroy widening composes unchanged: the carrier is still a
    symbolic `ControlFlow` specific; its cleanup discharge still rides
    `CanDestroyClass`'s choice clause; monomorphizations still re-derive
    witnesses. Nothing in the destroy path keys on finality.
-   `RequireSpecificDefinition` insts (:297-303) now register in generic eval
    regions for the final impl's specifics — expected new golden content, not
    a defect (the S3b resolution-order lesson says watch for eval retry loops;
    R-7's falsifier).
-   **The in-body counter-evidence is defused (added after plan review,
    2026-08-18 — correctness F-2).** B1b's recorded non-collapse INSIDE
    `Try` impl bodies is NOT standing counter-evidence against this
    prediction: an in-body query rides the
    `GetImplSelfWitnessInsideImplDecl` path (impl_lookup.cpp:1186-1190),
    which hands back the impl's own witness while SKIPPING the
    deduced-specific registration (`RequireSpecificDefinition` bypassed per
    :294-296), so associated-constant reads through it never substitute a
    query specific's arguments. P-1 exercises the OUT-of-body
    candidate-collection path (`CollectCandidateImplsForQuery` → deduced
    specific → `GetConstantValueInSpecific`) — a different code path whose
    behavior the B1b observation predicts nothing about. P-9 remains the
    honest probe of the in-body side.
-   **Choice-self precedents (added after plan review, 2026-08-18 —
    correctness F-3).** The "never-exercised combination" is narrower than
    it looks:
    toolchain/check/testdata/impl/lookup/specialization_with_symbolic_rewrite.carbon:26,65
    pins bare-`T` reduction through a final impl AND the designed non-final
    FAIL; validate_impl_constraints.carbon:94 pins a final impl whose self
    is a PARAMETERIZED CLASS specific; and a choice IS a class in SemIR
    (sem_ir/class.h:85 `is_choice`) — impl_validation.cpp's `ClassStart` arm
    (:112-131) accepts a choice root self for the same-file check. The
    genuinely novel residue is only the composition with the `?` desugar and
    generic eval regions — exactly what P-1..P-3 probe.
-   **Semantic cost, stated:** marking an impl `final` forbids specialization
    of `MyResult(T, E) as Core.Try` for specific arguments. That is the
    POINT, matches Rust's sole blanket `Try for Result` impl, and matches the
    ratified doc's own sketches; conforming programs that specialized a Try
    impl would break — none exist in-tree (the §1 sweep).

### 2.3 Probe-first discipline

No local bazel exists, and the exact combination (final impl × parameterized
CHOICE self × prelude interface × `?` desugar × generic eval regions ×
import) has never been compiled. W72a is therefore structured probe-first: the
goldens ARE the probes, landed with empty CHECK lines and validated by the
runner autoupdate (R15/R19, red-first-CI reconciliation, R26 two-pass), and
the plan pre-declares outcomes for failure shapes rather than improvising.

### 2.4 Contingency ladder (pre-declared, the b1 §3 narrowing precedent)

1.  **Probe compiles and reduces (expected):** proceed; wart comments flip to
    positive/negative pins as specified in §3.
2.  **Probe fails with a NARROW machinery defect** (for example the :335-361 cycle
    guard suppressing a legitimate reduction; a deduction failure specific to
    choice specifics; an import-parity gap per the W-069 precedent): STOP,
    record the failing input in the decision log, and re-scope W72a to a
    minimal upstream-ALIGNED fix slice (fixing final-impl reduction is
    implementing upstream's documented semantics — the aligned direction) with
    its own adversarial review round. This is a recorded deviation with a
    plan amendment, not a silent ride. Upstream is checked FIRST for the same
    defect and any in-flight fix (standing rule 5).
3.  **Probe reveals the lane fundamentally blocked** (reduction lands but the
    desugar's carrier types don't pick it up, or finality is rejected for
    choice selves): fall back to candidate (c) — the wart stays documented,
    W-072 is re-noted with the probe evidence and the upstream citation trail,
    and W72b is re-scoped (it dies with the lane). (Revised after plan
    review, 2026-08-18: the draft's W72c re-scope clause is gone with the
    cut; the parked brief item inherits the probe evidence either way.)

### 2.5 W72c — CUT at coordinator adjudication (2026-08-18); see §0.3

The `FromContinue` design this section carried in the draft (surface,
append-last position, breaking sweep, SF-9 forward-compatibility argument)
is parked in the SF-9/S3p brief per the adjudication of strictness F-4 — the
draft's "one honest alternative" (route the interface amendment through the
S3p brief, the W-071(a) precedent) is the adjudicated outcome, taken by the
coordinator rather than left as a standing veto. §0.3 holds the retained
content, the new-information note, the recurrence flag, and the re-staging
instruction. Nothing else in this plan depends on it.

---

## 3. Slices

Each slice is one landable PR through the full R11 loop (implementer → 2
adversarial reviewers → fixer), gated on: runner golden autoupdate to fixpoint
(R15/R19/R26) + `bazel test //toolchain/...` on CI + `uvx prek run` (R25) +
conformance non-regression with `runner.py --self-test` (R7/R9) + scoreboard
regeneration at landing. Ordering: W72a → W72b (needs the lane proven). Two
slices only — W72c is cut (§0.3).

### W72a — final-impl reduction probes + goldens (M; no compiler changes expected)

Scope: NEW check golden toolchain/check/testdata/operators/question_final.carbon
(positive subfiles), NEW fail golden fail_question_final.carbon (STDERR-pinned
probes), NEW lower golden lower/testdata/operators/question_generic_final.carbon;
comment retext in question.carbon's generic.carbon subfile; ledger + decision-log
updates; PLUS (added after plan review, 2026-08-18) the rulebook amendment and
the record-honesty sweep below.

**Rulebook amendment staged in W72a (strictness F-1 loop fix).** A new rule,
in rulebook style, appended as:

> **R27. Testdata or conformance code implementing a design-doc sketch must
> be DIFFED against the sketch's exact spelling before landing — declaration
> modifiers included.** Semantic review of impl bodies is not a spelling
> diff. (Origin: W-072 — the doc's `Try` impl sketches carried `final` from
> the original F-006 commit 9fdad04; the B1b testdata idiom (6b0b80e)
> dropped it, and the third-round correction 3099532 edited the very lines
> carrying `final` without noticing the modifier; the omission survived
> every review because testdata was checked against the doc's semantics,
> never diffed against the sketch's spelling.)

R6 (compile-verified sketches) points the other direction — doc/sketch →
compiling code; R27 covers code → sketch spelling fidelity — so this is a
new rule, not an R6 extension.

**Record-honesty sweep (strictness F-3 — the completed list).** Every record
carrying the overstated non-reduction claim, with its correction slice:

1.  fork/decision-log.md, F-006 B1b entry (:697-726) — the RETRACTION
    obligation (rides W72a's decision-log landing note). The overstated
    claims, named: "projection-annotated bindings until rewrite-reduction
    lands" (:697) and "under symbolic arguments the continue value CANNOT be
    threaded as `T` at all" (:711-712). The honest two-part correction:
    (i) the value CAN be threaded as `T` under the doc's own `final`
    spelling, with no compiler change; (ii) non-final rewrite-reduction
    is not pending — it will never "land", being upstream-designed
    refusal (specialization soundness). The retraction is a dated
    addendum to the entry, not a rewrite of the historical text.
2.  question.carbon generic.carbon subfile :281-285 wart comment — the
    negative-pin retext already in scope (W72a).
3.  question_generic_diff.carbon:28-41 header narrowing AND the :92 inline
    comment ("continue values go through `Discard` per the W-072 wart
    note") — ride W72b's comment-only edit.
4.  question_generic_diff.diff.cpp:51 oracle comment (mirrors the wart
    scope) — rides W72b's comment-only edit.
5.  The EIGHT-file "does not type-collapse" comment family
    (control_flow_constructs.carbon, question_propagation_diff.carbon,
    question_generic_diff.carbon, lower question.carbon +
    question_generic.carbon, check question.carbon + fail_question.carbon,
    fork/inventory/work-items.json): those comments describe NON-final
    impls and stay TRUE under this plan's prediction — no edit staged. P-9
    is their arbiter for the in-body case: see the P-9 row's minting rule.
6.  ORCHESTRATION.md:63-64 ("W-072 minted (projection non-reduction, Try
    success-constructor gap)") — HISTORICAL, no retro-edit; the new landing
    stamp carries the correction (reclassification to idiom gap; the
    success-constructor half parked per §0.3).

Probe table (each row is a falsification probe; N = negative):

| # | Probe (subfile) | Expected | Falsifier ⇒ ladder step |
| --- | --- | --- | --- |
| P-1 | `final impl forall [T, E] MyResult(T, E) as Core.Try where .ContinueType = T and .BreakType = E`; in `fn F[T, E](mr: MyResult(T, E), ...)`: `let v: T = mr?;` | compiles; `v` types as `T` | any check error ⇒ §2.4 step 2/3 |
| P-2 | `v` passed to a `T`-typed sink AND `return MyResult(T, E).Ok(v);` | compiles (pass + wrap) | conversion failure ⇒ §2.4 |
| P-3 | mixed specific `mr: MyResult(T, i32)`, threading as P-1/P-2 | compiles; break path's `FromBreak` conversion intact | deduction failure on the partially-concrete query ⇒ §2.4 step 2 (cell filled after plan review, 2026-08-18) |
| P-4 (N) | the EXISTING generic.carbon subfile, untouched impl (non-final): `mr?` continue value | STAYS the unreduced projection; `Discard` sink still required | non-final reduction firing ⇒ specialization soundness broken — halt, upstream check |
| P-5 (N) | bare facet binding `R: Core.Try where .BreakType = i32` (`PropagateOnly`, untouched): `R.ContinueType` | stays a projection (no rewrite in R's facet type; the final impl's self `MyResult(T, E)` does not unify with `R`) | reduction firing ⇒ unsound blanket match — halt |
| P-6 (N, fail golden) | after the final impl, a disagreeing narrower impl (for example `impl MyResult(i32, i32) as Core.Try where .ContinueType = ()...`) | diagnosed (specialization-vs-final; pin the actual diagnostic from the CI run — candidate families named after plan review, 2026-08-18: the poisoned-query family pinned by toolchain/check/testdata/impl/lookup/specialization_poison.carbon and the final-overlap family pinned by impl_overlap.carbon) | silent acceptance ⇒ halt |
| P-7 (N, fail golden) | `final impl` for a choice defined in a DIFFERENT file | `FinalImplInvalidFile` (impl_validation.cpp:143-146) | other/no diagnostic ⇒ record |
| P-8 | import parity: lib.carbon declares choice + final impl; use.carbon threads `let v: T = mr?;` (the question_generic_crossfile shape) | reduction survives import (import_final.carbon precedent) | import-side non-reduction ⇒ W-069-family gap, §2.4 step 2 |
| P-9 (obs.) | inside the final impl's own body: does `return self.(Core.Try.Branch)();` now collapse? | observation only — either way recorded; the b1 §2.6 `Diverge` idiom is NOT revised here. MINTING RULE (added after plan review, 2026-08-18, strictness F-3): if the observation FALSIFIES the eight-file "does not type-collapse" comment family (W72a sweep item 5), a follow-up work item is MINTED to retext the family and revisit the idiom — not merely observed | no gate, but minting is mandatory on falsification |

Exit criteria: P-1..P-3 positive CHECK content by way of autoupdate; P-4/P-5 pinned
by the EXISTING goldens staying semantically identical (generic.carbon's wart
comment at :281-285 retexted into a deliberate negative pin citing
details.md's specialization doctrine and pointing at question_final.carbon —
comment-only, loc-number churn declared per R26); P-6/P-7 STDERR pins
hand-written from the CI run; lower golden pins the instantiated threading CFG
(the monomorphized continue value flowing into the `T`-typed binding and the
`Ok` construction — falsified by a `Discard`-shaped dead value or absent
flow) with the SAME no-op destroy-call shape as the B2a baseline. Conformance
floor: **unchanged, 90/0/29 over 119** (goldens only). W-072 stays OPEN until
W72b.

### W72b — continue-threading runtime arbitration (S)

Scope: NEW differential pair
error_handling/question_generic_thread_diff.{carbon,diff.cpp}: a `final impl`
for `MyResult(T, i32)`; `fn Chain[T: type](x: T, fail_at: i32)` threading
continue values as `T` — `let a: T = Step(x, ..., 101)?;` then `let b: T =
Step(Combine(a), ..., 202)?;` (each step's input computed from the PREVIOUS
step's threaded output, so a mistyped/misrouted continue value CHANGES the
observable payload — unlike the seed-reconstruction shape of the existing
pair) — instantiated at i32 AND i64 (distinct carrier layouts), failure depth
and seeds runtime-selected (R16d), C++ function-TEMPLATE oracle with explicit
early returns computing the expectation independently; byte-identical
stdout + exit code per DIFF-1. The EXISTING question_generic_diff pair is
touched COMMENT-ONLY: its header's "W-072 follow-up" narrowing is replaced by
a pointer to the sibling pair, and (added after plan review, 2026-08-18 —
strictness F-3 sweep items 3/4) the :92 inline comment and the .diff.cpp:51
oracle comment are retexted in the same commit to describe the discard shape
as a DESIGN CHOICE of this pair rather than a language limit. Its break-path +
layout arbitration scope is unchanged — R16: no semantic edits to a passing
program — and (strictness F-6, with W72c cut) that comment-only claim now
stands UNQUALIFIED for this plan's whole horizon: no later slice of this plan
touches the pair's program semantics. Broken-oracle drill (mechanism declared
after plan review, 2026-08-18 — strictness F-5): with no local bazel, the
drill is a B2a-style DELIBERATE RED CI PUSH — the pair is pushed once to the
PR branch with the injected failure depth flipped in the `.carbon` side only,
the red differential run is linked in the decision log as the drill evidence,
and the flip is reverted in the next commit before landing; an always-green
pair under the flip is falsification (R-5 discipline). Exit criteria: drill
red run recorded then reverted; pair PASSes both legs; `runner.py
--self-test` OK; README table regenerated (DIFF-4). Conformance floor: **91
PASS / 0 FAIL / 29 SKIP over 120**. W-072 DISCHARGES here (§6).

### W72c — CUT (coordinator adjudication, 2026-08-18)

The draft's third slice is not part of this plan. Its content is parked in
the SF-9/S3p brief with the new-information note, the `final`-spelling
recurrence flag, and the re-staging instruction — see §0.3.

---

## 4. Byte-equivalence expectations

-   **W72a:** all existing goldens byte-identical EXCEPT
    question.carbon/generic.carbon — comment-only retext, expected churn is
    loc-number-only (R26 pass-2 verified loc-only; structural churn there is
    stop-and-explain). New files carry all positive content. No parse, check,
    lower, or prelude source changes (any needed change = §2.4 deviation with
    plan amendment).
-   **W72b:** conformance-only; toolchain tree untouched; existing pair's
    edits comment-only (header pointer, :92 inline, .diff.cpp:51 — the
    strictness F-3 sweep items).
-   **Both-preludes sweep obligation (added after plan review, 2026-08-18 —
    strictness F-2):** the prelude `Try` surface exists TWICE —
    core/prelude/try.carbon and the min_prelude mirrors
    (toolchain/testing/testdata/min_prelude/try.carbon and
    min_prelude/parts/try.carbon). W72a/W72b change NEITHER, so the
    obligation here is a check, not an edit: any Try-adjacent golden churn
    the autoupdate surfaces is verified against BOTH preludes' spellings
    before being accepted, and divergence between the two is a
    stop-and-explain event. The drift hazard is flagged in §0.3 for the
    future W72c, whose interface amendment MUST touch all three files in one
    commit.
-   _(W72c bullet deleted at the 2026-08-18 fix round — slice cut; its
    Try-golden enumeration obligation travels with the parked brief item.)_

## 5. Risk register (falsifiable)

-   **R-1. The lane's premise is wrong** (final-impl reduction does not fire
    for choice selves). FALSIFIER: probe P-1/P-2. Response: §2.4 ladder, never
    improvised desugar patches.
-   **R-2. The widening leaks** — reduction firing through NON-final impls or
    bare facet bindings. FALSIFIER: P-4/P-5 negative pins. A hit means the
    toolchain violates upstream specialization soundness: halt + upstream
    check.
-   **R-3. Specialization conflicts go silent.** FALSIFIER: P-6 producing no
    diagnostic (or a crash instead of one).
-   **R-4. Destroy-path regression** — the reduced carrier type stops riding
    the B2a choice clause. FALSIFIER: any `Core.Destroy` missing-impl error
    in P-1..P-3, or lower-golden destroy-call shape diverging from the B2a
    baseline.
-   **R-5. The differential pairs Goodhart to the goldens.** FALSIFIER: each
    pair must fail against its deliberately-broken oracle during authoring
    (depth flip); an always-green pair is falsification. Threading integrity
    additionally arbitrated by payload arithmetic depending on threaded
    values (W72b's `Combine` chaining).
-   **R-6. Upstream collision** (standing rule 5 / V-3a). impl_lookup.cpp /
    eval_inst.cpp / impl_validation.cpp are upstream-owned and final-impl
    machinery is active upstream territory (the :348 TODO). This plan changes
    NONE of them, so exposure is testdata-shaped; the pre-implementation
    re-check still greps upstream for final-impl/eval churn, and a hit on the
    cycle-guard TODO escalates (it is the named candidate root cause for P-8
    style failures).
-   **R-7. Eval retry loops at monomorphization** — `RequireSpecificDefinition`
    for final-impl specifics in generic eval regions re-entering
    (`NewSamePhase` retry, the S3b resolution-order lesson). FALSIFIER: CI
    timeout/hang or unresolved-witness loop on the P-3/P-8 shapes.
-   **R-8. In-body behavior shifts** under `final` (the b1 §2.6 idiom). Probe
    P-9 is observation-only; ANY change to existing goldens' in-body content
    would surface as R26 structural churn ⇒ stop-and-explain. (Revised after
    plan review, 2026-08-18: a P-9 result falsifying the eight-file
    "does not type-collapse" comment family MINTS a follow-up item — the
    W72a sweep item 5 rule.)
-   _(R-9 retired at the 2026-08-18 fix round — it guarded the W72c sweep,
    and W72c is cut; the risk travels with the parked brief item.)_

## 6. Work-item / TODO ledger

-   **W-072 discharge criteria (revised after plan review, 2026-08-18):**
    (i) W72a's P-1..P-3 positive pins landed with P-4/P-5 negative pins
    intact; (ii) W72b's threading pair PASS on the scoreboard (R9);
    (iii) the record-honesty sweep complete per W72a's numbered list —
    generic.carbon negative-pin retext and the decision-log RETRACTION
    addendum at W72a; the question_generic_diff header/:92/.diff.cpp:51
    retexts at W72b; (iv) decision-log landing note recording the §0.1
    verdict, the (a)/(b) vetoes, and the two-part correction; (v) the R27
    rulebook amendment landed (W72a). W-072 then CLOSES with a successor
    note: non-final non-reduction is UPSTREAM-DESIGNED behavior, permanently
    pinned by the negative probes — not a residual gap.
-   **The `FromContinue` residue (revised after plan review, 2026-08-18):**
    the adjudicated outcome — W72c cut — moves the "adjacent design residue"
    note into the SF-9/S3p brief with §0.3's retained content, the
    new-information note, and the `final`-spelling recurrence flag. W-072's
    closure note names the brief as the residue's home; no work item is
    minted by this plan for it.
-   **TODO strings: none move.** No `?` TODO strings exist (net-zero since
    B2a); this plan mints none (a §2.4 step-2 deviation would re-open this
    section with a dated amendment).
-   **SKIP evidence: none changes.** No SKIP cites this work (§1); zero flips
    claimed anywhere in the plan.

## 7. Testdata & golden flow

House rules as at B1/B2: new fail subfiles ship hand-written CHECK:STDERR
pins; positive CHECK content rides the runner autoupdate (R15/R19), two-pass
to fixpoint where line counts shift (R26); clang-format by way of hooks (R12/R18);
`runner.py --self-test` before conformance-touching commits (R7); private
`--out` dirs (R5); `uvx prek run --all-files` before every push (R25);
conformance program bodies compile-verified against the fork toolchain before
commit (R1 PrintStr / R2 core-units traps apply); differential pairs follow
DIFF-1..4; `.diff.cpp` oracles stay out of clangd-tidy (R24). Golden
placement: NEW FILES for all positive content (question_final,
fail_question_final, question_generic_final, the W72b pair), keeping existing
goldens byte-identical except the declared comment-only edits
(generic.carbon at W72a; the existing pair's three comment sites at W72b —
revised after plan review, 2026-08-18).

## 8. Conformance floor arithmetic

Starting floor: **90 PASS / 0 FAIL / 29 SKIP over 119** (56 bullets).
(Recomputed after plan review, 2026-08-18: the W72c row is gone with the
cut — the ladder ends at W72b.)

| After | PASS | FAIL | SKIP | Total | Movement |
| --- | --- | --- | --- | --- | --- |
| W72a | 90 | 0 | 29 | 119 | none (goldens only) |
| W72b | 91 | 0 | 29 | 120 | +question_generic_thread_diff |

FAIL stays 0 throughout; no SKIP flips (none cites this work); scoreboard
regeneration rides each landing gate (R9); README table by way of
`runner.py --update-readme-table` (DIFF-4). The one addition deepens the
already-PASS "Error handling: dedicated control flow constructs" bullet —
this plan flips no bullet and claims no bullet movement.

## 9. Standing constraints (named boundaries)

-   **SF-9 (OPEN, default DEFER):** nothing here depends on an SF-9 answer.
    (Revised after plan review, 2026-08-18: the defer-to-S3p outcome digest
    item 4 held as a standing veto was ADJUDICATED — W72c is cut and parked
    in the SF-9/S3p brief, §0.3.)
-   **W-070 / B3 / S3p:** untouched; the B2b ask package remains the critical
    path for rows 3, 10-14 of the b2 §0.1 classification.
-   **B2a's uniformity policy:** reaffirmed — no `?`-specific typing rules in
    any outcome of this plan (it is the stated reason candidate (b) is dead).
-   **V-3a register:** NO new entry from this plan (revised after plan
    review, 2026-08-18 — the `FromContinue` name entry travels with the
    parked brief item). The `final impl` idiom itself mints nothing — it is
    upstream's own spelling.

## Approval gate

This plan does not authorize implementation. Per house protocol it went to
TWO adversarial plan reviewers before the coordinator saw the digest — both
returned APPROVE-WITH-AMENDMENTS on 2026-08-18, the coordinator adjudicated
strictness F-4, and this document carries the full fix round (see the
Amendments log at top). The original briefs, for the record: reviewer #1
attacks §0.1/§2.2 — the upstream-verdict citations (does the tree's
final-impl machinery really reduce for CHOICE selves; is the fail_nonfinal
reading right; the cycle-guard reachability for P-1/P-8), the P-6 diagnostic
prediction, and the draft §2.5 SF-9-independence argument, with concrete
counter-programs. Reviewer #2 attacks completeness — the sweep enumerations,
§4's churn claims, §8's no-flip claim, the probe table for missing
negatives — and spot-checks every file:line citation against the tree.

The V-2 veto digest for this plan:

1.  **The §0.1 verdict + lane (d)** — candidates (a)/(b) V-3a-VETOED as
    upstream contradictions; the `final impl` spelling adopted as the W-072
    resolution. Auto-adopt (one realistic answer; the ledger's "(a)-vs-(b)
    genuine fork" contingency dissolves because alignment is unambiguous —
    contradiction, not ambiguity, on both).
2.  **The final-impl idiom scope** — new goldens/conformance use `final`;
    existing non-final goldens are RETAINED as permanent negative pins
    (comment retext only). Auto-adopt.
3.  **W72b as a NEW sibling pair** (existing pair comment-only) rather than
    strengthen-in-place. Auto-adopt.
4.  **W72c — `FromContinue` now** — the plan's one borderline call, carried
    with the standing veto "defer the interface amendment to the B2b/S3p
    brief" (the W-071(a) routing precedent). **ADJUDICATED (2026-08-18,
    strictness F-4): the VETO FIRED** — the coordinator overruled the
    digest-grade classification itself (re-opening the B2a landing note's
    digest-adopted routing requires new-information acknowledgment from the
    USER, not a plan-level judgment call). W72c is cut and parked per §0.3.
5.  **The contingency ladder (§2.4)** as the only sanctioned deviation paths,
    including that a step-2 narrow machinery fix is upstream-aligned work
    requiring a plan amendment, not silent scope growth.
6.  **Conformance movement (§8, recomputed 2026-08-18):** one new pair,
    floor 90→91 over 119→120, zero SKIP flips, zero bullet claims.

Genuine user forks requiring a synchronous AskUserQuestion round: **none
found.** The (a)-vs-(b) fork the ledger anticipated is resolved by the V-3a
contradiction rule, not by user choice; item 4 was the closest call,
deliberately surfaced with a standing veto rather than an ask — and the veto
fired at adjudication, confirming the surfacing discipline.
