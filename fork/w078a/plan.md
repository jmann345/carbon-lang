<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-078a plan: dead `default` arms on choice and bool scrutinees

**Status:** PLAN (no implementation), APPROVED FOR IMPLEMENTATION per the
Sign-off below (2026-09-26). Branch `claude/carbon-fork-0-1-w078a`
off trunk 30761b1 (post-W-076/PR #36; conformance 100/0/28 over 128).

**Item:** the separable CHOICE half of W-078 (fork/inventory/work-items.json),
extended to bool scrutinees. The design mandates diagnosing a `default` that
can never match: "A pattern is not useful in the context of prior patterns. In
a `match` statement, this happens if a pattern or `default` cannot match
because all cases it could cover are handled by prior cases or a prior
`default`" (docs/design/pattern_matching.md:627-631). W-066 exempted `default`
arms wholesale because the W-008 residue R8 conservative gate
(handle_match.cpp:1436, `match statement without `default` arm`) FORCES a dead
`default` on integer matches with irrefutable arms. The W-066 plan-review
INDEPENDENCE RECORD: the R8 TODO fires only for non-choice scrutinees, so the
choice half may land alone; only the integer half must land with-or-after the
R8 lift.

**Bool is in this slice** (verified): W-076 routed bool scrutinees past the R8
gate — `MatchStatement`'s no-`default` branch classifies bool alongside choice
(handle_match.cpp:1425-1447) and diagnoses `MatchNonexhaustiveBool` instead of
the TODO, so a bool `default` is never R8-forced. Bool has the same finite
covered_alternatives {0,1} domain machinery (W-076). Same design rule
(`bool` "is treated like a choice type", pattern_matching.md:589-591), same
mechanism, so bool-default deadness is adjudicated IN: excluding it would be
an arbitrary seam the design does not have.

## §1 Adjudications

1.  **Severity/kind: Error, new diagnostic `MatchDefaultNeverMatches`.** A
    `default` arm is not a `case` pattern, so `MatchCaseNeverMatches`'s text
    ("`case` pattern never matches...") would be false. New primary:
    `"`default` arm never matches; every value of the scrutinee is matched by
    prior arms"`. (amended 2026-09-26, review fold: rev 2 F1, adjudication made
    explicit) Error is the DESIGN'S OWN call, not a fork choice:
    pattern_matching.md:238-246 annotates a dead `default` after `case _:
    i32` as "❌ Error: unreachable." (the annotation comment is :243, on the
    `default` arm at :244); :627-629 lists "`default` cannot match" in the
    same diagnosed situation as the :645 Error-annotated example; :814-815
    (`default` remains equivalent to `case _: auto`) makes a warning
    incoherent with the landed W-066 Error for the equivalent case form; and
    the design reserves warnings for unused bindings (:360). Break
    condition: upstream re-annotating :243-244 or :645, or landing this
    class as a lint/warning — fail goldens re-churn, but the §6
    default-drops stand either way. (amended 2026-09-26, review fold: rev 2 F5,
    log-worthy nuance) The design's :243-244 annotation says "unreachable"
    while this diagnostic family's wording says "never matches" — a
    deliberate uniformity choice with the landed W-066 family, recorded here
    and in the §8 decision-log entry. Notes by coverage source:
    -   _Irrefutable prior arm_ (single covering prior): new note
        `MatchDefaultNeverMatchesPriorArm`, `"every value is matched by this
        prior arm"`, at the covering arm's introducer — the W-066 first-
        covering-arm determinism (the first recorded `Wildcard`-root arm).
    -   _Alternative union / bool value union_ (no single covering prior):
        NEW note kind `MatchDefaultNeverMatchesFullCoverage` with
        byte-identical text to `MatchCaseNeverMatchesFullCoverage` ("all
        alternatives of {0} are matched by prior arms"); the bool rendering
        "all alternatives of `bool`" is the landed W-076 wording. (amended
        2026-09-26, review fold: rev 2 F2 + rev 1 C-5 — the former fallback is now
        the primary plan. Cross-primary note reuse has precedent
        (`RedeclPrevDecl`, merge.cpp:16, shared by three primaries), but
        those precedents are NEUTRALLY named; a `[MatchCase...]`-tagged note
        under a `default` primary is user-visibly incoherent. No hoist of
        `MatchCaseNeverMatchesFullCoverage`; R-3 retired.)
2.  **Guarded `default`s ARE checked.** Deadness is arm reachability: when
    priors fully cover, control reaches the arm's test only with values prior
    arms already consumed, so even a guarded `default` never runs — exactly
    W-066's guarded-LATERS rule (guarded arms are checked, only unguarded
    arms are recorded as context). (amended 2026-09-26, review fold: rev 2 F3,
    mis-citation replaced) The design's worst-case guard assumption
    (:620-623) covers BOTH sides: the arm under test's own guard is assumed
    TRUE — which licenses checking the guarded `default` directly, since its
    usefulness then reduces to `_: auto`'s per :814-815 in the prior
    context — while guards on context arms are assumed false, so guarded
    priors never cover. A guarded
    `default` may appear mid-list (parse allows it; guarded_default.carbon's
    basic subfile), and its check at `MatchGuardedDefault` compares against
    priors only — which is the definition of usefulness, so mid-list timing
    is sound. The UNGUARDED `default` is parse-guaranteed last
    (parse/testdata/match/fail_cases_after_default.carbon), so its
    priors-only check sees every arm.
3.  **Integer (and tuple) lanes stay exempt.** The check fires ONLY when the
    scrutinee's unqualified type is `bool` or `IsMatchableChoiceType` — the
    same root-only classification as the step-3b union rule (W-076's
    accepted false-negative record: tuple roots do not extend). The R8 gate
    still forces `default` on integer matches, so integer silence is the
    recorded residue; usefulness_no_false_positive.carbon's
    `dead_default_exempt` IntSide keeps pinning it (§6).
4.  **Error-arm suppression.** `match_context.has_error_arm` (a prior arm
    whose pattern or condition errored): keep the blanket suppression, as
    `DiagnoseNonexhaustiveMatch` does. (amended 2026-09-26, review fold:
    rev 1 A-3, rationale corrected) This is NOT a mirror of the case-arm
    usefulness rule — it is a deliberate conservative DIVERGENCE from it:
    the case-arm check does NOT suppress on prior error arms
    (handle_match.cpp:777-785; the guard at :791-792 tests only the arm's
    own error), so the blanket suppression here produces a known
    deterministic false negative — an error arm plus a `Wildcard`-root prior
    plus `default` stays silent where the analogous `case` arm would be
    diagnosed. The in-code comment at the suppression must state this
    divergence, and §4 pins the asymmetry as a negative. A BIND-pass-error
    arm (`case
    n: i32` on a bool scrutinee) is recorded as covering (`Wildcard` key,
    W-066 §1.8 carve-out), so a `default` after it IS diagnosed — stacking,
    the same documented behavior as fail_case_after_bind_error_arm.carbon.
    An empty or all-rejected choice alternative table stays silent (the
    landed two-way covers_all answer; empty_choice.carbon's default-only and
    guarded-default subfiles are the standing negative pins).
5.  **Interaction with exhaustiveness: at most one statement-level story.**
    An unguarded `default` sets `has_default`, short-circuiting
    `DiagnoseNonexhaustiveMatch`; the dead-default error fires only under
    full prior coverage. A dead GUARDED `default` also implies full coverage,
    which discharges the `default` requirement, so nonexhaustive cannot fire
    alongside it either; a guarded `default` with partial priors is silent
    while the statement's nonexhaustive diagnostic fires as today
    (fail_guarded_default.carbon unchanged). No shape is both
    nonexhaustive-diagnosed and dead-default-diagnosed.
6.  **The covers-all refactor is in scope.** The step-3b union computation
    (handle_match.cpp:835-858: bool = {0,1} ⊆ covered_alternatives; choice =
    non-empty alternative table with every index covered) is duplicated by
    this slice's default check; factor it into one static helper used by
    both so the two rules can never diverge. `DiagnoseNonexhaustiveMatch`
    keeps its own per-value loops (it must NAME the missing values); the
    helper is the boolean coverage predicate only.

## §2 Mechanism (no SemIR change; diagnose-and-proceed; no insts emitted)

1.  **Factor** `static auto UnguardedArmsCoverWholeDomain(Context&,
    SemIR::TypeId unqualified_scrutinee_type_id, const
    Context::MatchStatementContext&) -> bool` out of
    `EmitCaseArmTestAndBind`'s step 3b, verbatim semantics: bool branch
    computed before and without the `GetAs<SemIR::ClassType>` read (the
    W-076 CHECK-fail guard), choice branch `!choice_alternatives.empty() &&
    all indexes covered`. Step 3b calls it; so does the default check.
2.  **Hook: a small `DiagnoseDeadDefault(Context&, Parse::NodeId
    introducer_node_id)`** called from BOTH default handlers, reading
    `context.match_statement_stack().back()` (still pushed; popped only at
    `MatchStatement`) and the scrutinee by way of `PeekScrutinee` (node-stack
    shape at both sites after popping the `MatchDefaultIntroducer`: prior
    `MatchHandler` entries or `MatchStatementStart` on top — the same
    protocol `MatchHandler` uses at :1299):
    -   Lane gate: unqualified scrutinee type is `bool` or
        `IsMatchableChoiceType`; otherwise return (integer/tuple R8 lane).
    -   Suppress on `has_error_arm`, with an in-code comment stating the
        deliberate divergence from the case-arm rule and its false negative
        (amended 2026-09-26, review fold: rev 1 A-3; §1.4).
    -   Stage 1 (single-prior): scan `useful_arms` in order for the first
        arm whose key `Wildcard`-root subsumes a synthetic `{Wildcard}` key
        (equivalently: first recorded irrefutable arm — only a
        `Wildcard`-root prior subsumes `default` ≡ `case _: auto`); emit
        `MatchDefaultNeverMatches` + `MatchDefaultNeverMatchesPriorArm`.
    -   Stage 2 (union): else if `UnguardedArmsCoverWholeDomain`, emit
        `MatchDefaultNeverMatches` + the new
        `MatchDefaultNeverMatchesFullCoverage` note (byte-identical text to
        `MatchCaseNeverMatchesFullCoverage`, which is NOT hoisted; amended
        2026-09-26, review fold: rev 2 F2 + rev 1 C-5, §1.1) at the scrutinee,
        naming the unqualified type. Guarded priors never count (they are
        neither in `useful_arms` nor in `covered_alternatives`) — the
        design's assumed-false rule for context guards, for free.
    -   Kind registration (amended 2026-09-26, review fold: rev 1 A-2): the
        three new kinds — `MatchDefaultNeverMatches`,
        `MatchDefaultNeverMatchesFullCoverage`,
        `MatchDefaultNeverMatchesPriorArm` — are registered in
        toolchain/diagnostics/kind.def's Match block, alphabetized between
        `MatchCaseTuplePatternWrongArity` (:169) and `MatchNonexhaustive`
        (:170); the §4 fail files must cover all three, as the diagnostic
        coverage test requires.
3.  **Call sites.** `HandleParseNode(... MatchDefaultId ...)` and
    `HandleParseNode(... MatchGuardedDefaultId ...)` (handle_match.cpp:1191,
    :1212): change the leading
    `PopAndDiscardSoloNodeId<MatchDefaultIntroducer>` to a value-keeping pop
    so the `default` keyword's node locates the error; call
    `DiagnoseDeadDefault` there (before the guarded arm's dispatch
    emission — ordering within the handler is free since the check emits
    nothing). The arm then emits its normal SemIR (diagnose-and-proceed,
    like `MatchCaseNeverMatches`), and — per the W-066 discharge note — the
    unconditional exhaustiveness recording block is untouched.
4.  **Comment sweep** (behavioral honesty, no logic): the file-header
    exemption sentence (:132, :144-146), the `MatchDefault` /
    `MatchGuardedDefault` exemption paragraphs (now describe the check and
    the surviving integer-lane exemption), and step 3b's "`default` arms
    never reach this site" pointer.

## §3 Slice plan

One slice, one PR (size S): the §2 refactor + check + diagnostics, the §4
testdata, the §6 restructures, golden regen to fixpoint. No sub-slicing —
the check is one function and the churn is mechanical. Commit structure
(amended 2026-09-26, review fold: rev 2 F7): refactor + check + kinds in commit
1; testdata restructures + new fail files in commit 2; regen fires after.

## §4 Testdata matrix

New file `toolchain/check/testdata/match/fail_dead_default.carbon`, subfiles:

| subfile | shape | expect |
| --- | --- | --- |
| fail_choice_full_coverage | `Flag{.Off,.On}` both covered + `default` (exhaustive_choice with_default's shape, moved) | error + FullCoverage note naming `Flag` |
| fail_choice_after_irrefutable | `case c: Signal` then `default` (dead_default_exempt ChoiceSide's flipped lane) | error + PriorArm note |
| fail_bool_full_coverage | `case true` + `case false` + `default` | error + FullCoverage "all alternatives of `bool`" |
| fail_bool_after_irrefutable | `case b2: bool` then `default` | error + PriorArm note |
| fail_trailing_guarded_default | `.Off` + `.On` + `default if (x > 0)` (guarded_default trailing_guarded_default's shape, moved) | error at the guarded `default` |
| fail_guarded_default_after_irrefutable | `case c: Flag` then `default if (g)` | error + PriorArm note |
| fail_bool_guarded_default | `case true` + `case false` + `default if (g)` | error at the dead guarded `default` on bool + FullCoverage note (amended 2026-09-26, review fold: rev 2 F6 nit b) |
| fail_bind_error_arm_prior | bool scrutinee, `case n: i32` (bind-pass error, recorded covering) then `default` | conversion error + stacked dead-default (the §1.4 carve-out mirror) |

The fail_trailing_guarded_default subfile carries `//@dump-sem-ir` markers:
diagnose-and-proceed still emits full SemIR, so the multi-arm guard-failure
convergence shape keeps a SemIR pin there (amended 2026-09-26, review fold:
rev 1 A-4; see §6.8).

Negatives (silent unless noted), added to
usefulness_no_false_positive.carbon: `guarded_priors_default` (choice whose
every alternative is covered only by GUARDED arms, + `default` — guards never
count); `fail_error_arm_prior_default` (choice, full coverage + an error arm +
`default` — only the arm's own error; has_error_arm suppression);
`fail_error_arm_wildcard_prior_default` (choice, an error arm + a
`Wildcard`-root irrefutable prior + `default` — silent on the `default`,
pinning the §1.4 asymmetry: the analogous `case` arm in that position would
be diagnosed; amended 2026-09-26, review fold: rev 1 A-3). Error-arm spelling
pin (amended 2026-09-26, review fold: rev 1 A-5): both error-arm negatives must
use a non-aborting alternative-pattern error that push_error()s and
proceeds — for example `.Err()` unexpected-parens (`MatchAlternativeUnexpectedParens`)
or an unknown alternative name, per fail_choice_alternative_pattern.carbon's
shapes — because `case 5` on a choice scrutinee TODO-aborts the subfile
(fail_todo_choice_expr_case.carbon's SemanticsTodo pin). Already
pinned in-tree and staying silent: partial coverage + `default`
(choice_scrutinee, nested_choice_designator — which also pins nested-match
independence on choice roots), integer irrefutable + `default`
(dead_default_exempt IntSide, the R8 record), empty-choice `default`
(empty_choice, choice_generic_scrutinee empty_choice_specific,
single_alternative_choice default_only), tuple roots (bool_tuple_scrutinee,
bool_pair_keeps_default).

## §5 Conformance

Floor stays **100/0/28 over 128, zero program edits** — verified by grepping
every `default =>`/`default if` in fork/conformance/programs: all are integer
or tuple scrutinees (match_switch, match_switch_diff, match_position,
match_no_fallthrough, match_guard_diff, match_guard_binding,
match_guarded_default, match_var_ref_binding, most_features_missing_match,
match_tuple_case_diff), partial-coverage choice matches
(choice_payload_construct, choice_discriminant_diff, choice_generic_diff), an
empty-choice `default` (match_single_alternative's `Impossible`), or
commented-out (match_sum_type_payload, SKIP). match_var_ref_binding's
`default` after `var`/`ref` arms is the integer lane → exempt → silent, as is
most_features_missing_match's (guarded binding records nothing anyway).
match_bool, match_payload_literal and control_flow_constructs have no
`default` arms at all.

## §6 Golden churn inventory

Complete: every full-coverage-plus-`default` in the tree, from grepping all
`.carbon` files.

Restructures (R16: a landed positive golden must not silently gain an error;
the error shape moves to fail_ files, the positive stays positive):

1.  **check/match/exhaustive_choice.carbon** — with_default subfile
    (:84-100): the "Diagnosing it as useless is future work" comment and the
    dead `default` go away; the shape moves to fail_dead_default's
    fail_choice_full_coverage. File keeps its exhaustive-without-`default`
    subfiles.
2.  **check/match/usefulness_no_false_positive.carbon** —
    dead_default_exempt: ChoiceSide (choice union + `default`) moves to the
    fail file; IntSide STAYS with the comment rewritten to record the
    remaining integer-lane exemption (R8 still forces that `default`;
    W-078's integer half). The bool lane needs no flip here — it never had
    a commented bool negative — the fail file's bool subfiles are its pins.
3.  **check/match/binding_choice_scrutinee.carbon** — outer match: `case
    c: Signal` then `default` is dead; DROP the outer `default` (the
    irrefutable arm keeps it exhaustive). Inner match's `default` stays
    (partial coverage). SemIR regen.
4.  **check/match/bool_scrutinee.carbon** — the W-076 "default tails only
    where not fully covered" claim VERIFIED and found false for the
    irrefutable-arm source: `compose` (`case b2: bool` + `default`) and
    `var_ref_binding` (both fns: `var`/`ref` irrefutable arm + `default`)
    carry dead defaults; DROP those three `default` arms (matches stay
    exhaustive by way of the irrefutable arm). with_default (partial),
    fail_unparenthesized_comparison_case (error arm), constant_expr_case /
    exhaustive / order / constant_scrutinee (no `default`) are unaffected —
    the claim holds for the VALUE-union source.
5.  **check/match/choice_payload_guard.carbon** — unguarded `.Ok(w: i32)` +
    `.Err` cover both alternatives; DROP the dead `default`. Regen.
    Post-drop the file becomes a near-duplicate of exhaustive_choice's
    third subfile (guarded_duplicate) — acceptable redundancy, recorded
    (amended 2026-09-26, review fold: rev 1 A-6).
6.  **check/match/choice_payload_pattern.carbon** — `.Ok(value: i32)` +
    `.Err` full coverage; DROP the `default`. Regen.
7.  **check/match/choice_payload_multi.carbon** — `.Move`/`.Set`/`.On()`/
    `.Off` all covered; DROP the `default`. Regen.
8.  **check/match/guarded_default.carbon** — trailing_guarded_default
    subfile is now the dead-guarded-default fail shape; MOVE it to
    fail_dead_default (fail_trailing_guarded_default) and delete the
    subfile. Its CFG pin (guard-failure edge to the statement's top else
    block when no arm follows) is kept two ways (amended 2026-09-26, review
    fold: rev 1 A-4): primarily by the fail_trailing_guarded_default subfile
    itself, which carries `//@dump-sem-ir` markers — diagnose-and-proceed
    still emits full SemIR, so the multi-arm guard-failure convergence
    shape keeps a SemIR pin — and secondarily by empty_choice.carbon's
    guarded_default_vacuous, whose last-arm shape is similar but not
    identical (single-arm, empty-choice context, no prior-arm convergence
    blocks); note this relocation in the file header. basic, compound_guard
    (integer) and choice_coverage (mid-list, partial priors) stay.
9.  **lower/testdata/match/choice_payload.carbon** — `.Ok(value: i32)` +
    `.Err` + `default`: a check error would break this non-fail lowering
    golden outright; DROP the `default`, lowering IR regenerates. All other
    lower goldens with `default` (let/import_choice, choice/payload_layout,
    choice/generic_payload, choice/generic_payload_imported, match/basic,
    match/tuple_pattern, match/var_binding) are partial-coverage or
    integer/tuple lanes — silent.
10. **Comment-only refresh:** fail_case_after_bind_error_arm.carbon's "The
    `default` arm stays exempt (plan §1.5)" sentence becomes "the `default`
    is integer-lane exempt (R8; W-078 integer half)" — behavior unchanged
    (integer scrutinee), autoupdate refreshes the file.

Verified silent (no churn), for the record: all other check/match goldens
with `default` — partial-coverage choice files (choice_scrutinee[_imported,
_reexported], choice_payload_imported, payload_subpattern,
nested_choice_designator, bool_choice_payload, fail_bool_choice_payload,
fail_choice_alternative_pattern and every other fail_ file: partial coverage
and/or error-arm suppression), every integer/tuple-scrutinee file (basic,
guard, var_binding, tuple_pattern, binding_pattern, ref_binding, nested,
converging_arms, default_only, constant_*, negative_literal_case,
fail_case_never_matches_*, usefulness_no_false_positive's other subfiles,
patterns/unused.carbon), empty-choice files, operators/fail_question.carbon
and check/choice/generic_payload.carbon (no dead defaults), and all
parse/testdata (parse-only). Completeness additions (amended 2026-09-26,
review fold: rev 1 A-1 + rev 2 F6 nits): bool_scrutinee_default_only.carbon (a
`default`-only bool match — no priors, nothing covers it),
choice_generic_payload_scrutinee.carbon (every subfile is `default`-only or
partial coverage — `case .Neither` + `default` on a two-alternative choice),
and exhaustive_choice_binding.carbon (its "default" hits are comment-only;
no `default` arm at all) are also verified silent.

## §7 Risks

-   **R-1 hidden churn:** a full-coverage-plus-`default` golden missed by
    §6. Mitigation: the inventory came from an exhaustive tree grep; any
    straggler surfaces as a hard test failure (new error in a non-fail
    file) at regen, not silently.
-   **R-2 node-stack shape at the guarded-default hook:** `PeekScrutinee`
    after the introducer pop is derived from the handler code, not yet
    executed mid-list; the choice_coverage golden (mid-list guarded
    `default` on a choice) exercises it and must stay silent.
-   **R-3 note-kind reuse across primaries: RETIRED** (amended 2026-09-26,
    review fold: rev 2 F2 + rev 1 C-5). The former fallback — a new
    `MatchDefaultNeverMatchesFullCoverage` kind with byte-identical text —
    is now the §1.1 primary plan; no hoist, no reuse, nothing left to risk.
-   **R-4 SemIR shape drift in restructured positives:** dropping `default`
    arms changes convergence-block arithmetic (`num_blocks`); pure regen,
    but the reconciliation diff must show only the expected per-file
    reshapes.
-   **R-5 guarded-default deadness contested: demoted to
    wording-veto-at-most** (amended 2026-09-26, review fold: rev 2 F3).
    §1.2's corrected reading of :620-623 shows the design itself assumes
    the arm under test's guard true, so guarded-default deadness is
    design-licensed, not a fork judgment call; the residual risk is at
    most a wording veto on the diagnostic text, not the dropped-subfiles
    contingency previously recorded here.

## §8 Verification and discharge

1.  Regen: runner autoupdate to R26 fixpoint (expect pass 2 clean); churn
    confined to fail_dead_default.carbon (new), the two
    usefulness_no_false_positive additions, and the §6 files.
2.  Gate: full `bazelisk` test gate green.
3.  Conformance: unchanged **100/0/28 over 128** (no program edits, §5).
4.  Reconciliation: diff audit that no golden outside §6 changed.
5.  **Ledger edit at discharge:** W-078's notes gain a choice-half-
    DISCHARGED record — "choice+bool `default` deadness diagnosed
    (MatchDefaultNeverMatches, fork/w078a/plan.md); the integer lane stays
    exempt behind R8 (dead_default_exempt IntSide pin); item stays OPEN for
    the integer half, which lands with-or-after the R8 lift" — plus a
    decision-log entry for §1.1/§1.2/§1.6; the item is NOT closed. (amended
    2026-09-26, review fold: rev 2 F1 + F5) The §1.1 decision-log entry must
    carry the full severity reasoning, mirrored from §1.1: Error is the
    design's own call (pattern_matching.md:238-246 "❌ Error: unreachable."
    at :243-244; :627-629 with the :645 Error-annotated example; :814-815
    `default` ≡ `case _: auto` versus the landed W-066 Error; warnings
    reserved for unused bindings, :360), its break condition (upstream
    re-annotating :243-244/:645 or landing this class as a lint/warning —
    fail goldens re-churn, the §6 default-drops stand either way), and the
    wording nuance (the design's annotation says "unreachable", the family
    says "never matches" — deliberate uniformity choice).

## Sign-off

Both adversarial reviews returned APPROVE-WITH-AMENDMENTS. The one
severity contest is settled by the design's own annotation: a dead
`default` is "❌ Error: unreachable." at pattern_matching.md:238-246
(:243-244), so Error is the design's call, not a fork choice (§1.1).
Amendments 1-11 are folded above with dated "(amended 2026-09-26, review
fold: ...)" notes: rev 2 F1 severity adjudication + rev 2 F5 wording nuance
(§1.1, §8), rev 2 F2 + rev 1 C-5 new `MatchDefaultNeverMatchesFullCoverage` kind
as primary plan with R-3 retired (§1.1, §2, §7), rev 2 F3 corrected
:620-623 reading with R-5 demoted (§1.2, §7), rev 1 A-3 corrected error-arm
suppression rationale + asymmetry negative (§1.4, §2, §4), rev 1 A-2 kind.def
registration and coverage (§2, §4), rev 1 A-1 + rev 2 F6 verified-silent
completeness (§6), rev 1 A-4 SemIR pin by way of `//@dump-sem-ir` in
fail_trailing_guarded_default with the equivalence claim softened (§4,
§6.8), rev 1 A-5 non-aborting error-arm spelling pin (§4), rev 2 F6 nit b bool
guarded-default row (§4), rev 1 A-6 choice_payload_guard redundancy note
(§6.5), rev 2 F7 commit-structure note (§3).

**Status: APPROVED FOR IMPLEMENTATION, 2026-09-26.**
