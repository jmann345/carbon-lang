<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-078b plan: R8 lift + dead `default` arms on integer/tuple scrutinees

**Status:** APPROVED FOR IMPLEMENTATION, 2026-09-26 — two adversarial
plan reviews returned APPROVE-WITH-AMENDMENTS; the folds are recorded
in the "Sign-off" section at the end of this file. Branch
`claude/carbon-fork-0-1-w078b` off trunk e06a55d (post-PR #37: W-078a
landed; conformance 100/0/28 over 128 per
fork/conformance/out/scoreboard.json totals).

**Item:** the remaining INTEGER half of W-078 (fork/inventory/
work-items.json), which this slice CLOSES: lift the W-008 residue R8
conservative gate — `MatchStatement`'s
``context.TODO(node_id, "match statement without `default` arm")`` at
toolchain/check/handle_match.cpp:1551 (branch :1536-1552), which fires for
every non-bool, non-choice scrutinee without an unguarded `default`, even
when an unguarded irrefutable arm makes the match genuinely exhaustive —
and widen W-078a's `DiagnoseDeadDefault` past its integer/tuple lane
exemption (handle_match.cpp:1237-1242, "The integer/tuple lane keeps its
`default` exemption (R8, above)."). The in-code comment at :1549-1550
names exactly this work, verbatim (held between doc-style-ignore
markers because the doc-style hook rewrites this sentence's third word
in prose — a code span does not protect it; markers are the in-tree
precedent, for example toolchain/docs/idioms.md):

<!-- google-doc-style-ignore -->
> Exhaustiveness via an irrefutable arm or full enumeration of a small
> integer type is future work.
<!-- google-doc-style-resume -->

(Amended 2026-09-26, review fold: rev 2 F5 — the quotation previously
paraphrased the code's wording; a quotation must be verbatim.) All line
numbers in this plan are against trunk e06a55d.

## §1 Adjudications (the five design questions)

1.  **What discharges integer/tuple exhaustiveness: UNGUARDED irrefutable
    arms only.** The design defines exhaustiveness as `_: auto` not being
    useful in the context (pattern_matching.md:579-581), and an
    irrefutable arm is precisely one that matches all values (:582-585);
    guards are assumed false on context arms (:620-623), so a guarded
    irrefutable arm never discharges. The machinery already exists, two
    ways, and they provably agree on this lane:
    -   Statement-level: `has_irrefutable_arm` is set at
        handle_match.cpp:929-931 for an unguarded binding root,
        irrefutable `var` root, or all-binding tuple root
        (`is_binding_arm || is_irrefutable_var_arm ||
        is_irrefutable_tuple_arm`); guarded arms are excluded one branch
        earlier (:927-928), error arms one earlier still (:924-926).
        `DiagnoseNonexhaustiveMatch` already early-returns on it
        (:1432-1434) — the discharge is literally already implemented;
        only the R8 gate in front of it blocks the integer lane.
    -   Arm-level (for the dead-`default` note): only unguarded,
        undiagnosed arms are pushed to `useful_arms` (:895-901), and
        **tuple scrutinees need no new key machinery**: verified in
        `BuildMatchCaseUsefulnessKey`, pattern_match.cpp:761-770 — the
        worklist tests `IsIrrefutableMatchCasePattern` FIRST, so an
        all-binding tuple `case (a: i32, b: i32)` (and an irrefutable
        `var` root) keys as the single node `{Wildcard}`, "the same as a
        binding root" (comment :763-766; `IsIrrefutableMatchCasePattern`
        at pattern_match.cpp:665-691 recurses through tuples and `var`).
        So W-078a's stage-1 synthetic-`{Wildcard}` subsumption
        (handle_match.cpp:1263-1281, by way of `UsefulnessKeySubsumes`
        :619-669) fires unchanged for both integer and tuple lanes.
    -   Agreement proof (recorded so the two rules can never be accused
        of diverging): on the integer/tuple lane,
        `has_irrefutable_arm == true` iff `useful_arms` contains a
        `Wildcard`-root entry. Forward: every arm that sets the flag
        builds a `{Wildcard}` key, and the FIRST such arm cannot itself
        be diagnosed dead on this lane — stage-2 union coverage does not
        exist for open domains, so only a prior `Wildcard` arm could kill
        it, contradicting firstness — so it is recorded. Backward: only
        irrefutable roots key `Wildcard` (pattern_match.cpp:767-768). The
        one deliberate asymmetry-free carve-out: a BIND-pass-error arm
        (`case b: bool` on an `i32` scrutinee) sets the flag AND is
        recorded as covering (W-066 §1.8; comment :822-827), so both
        rules also agree there. Break condition: a future pattern kind
        that is irrefutable but keys non-`Wildcard` would split the two —
        the §2 comment must state the invariant so the splitter sees it.
2.  **The lift is exactly two edits + comments; stage 2 has NO integer
    meaning and the code guarantees `...FullCoverage` can never fire on
    this lane structurally.** Integers (and tuples of them) have no
    closed alternative table — `UnguardedArmsCoverWholeDomain`
    (handle_match.cpp:689-706) answers for `bool` (:692-695) or else
    unconditionally does `GetAs<SemIR::ClassType>` (:696-699), which
    would CHECK-fail on an integer type. So `DiagnoseDeadDefault` is NOT
    changed to "remove the early return": the bool-or-choice test MOVES
    from a function-entry gate (:1237-1242) to guarding the stage-2
    union block only (:1283-1299). Stage 1 (single `Wildcard`-root prior,
    :1263-1281) runs for every lane; stage 2 stays bool/choice. That
    placement is the structural guarantee the brief asks for:
    `MatchDefaultNeverMatchesFullCoverage` is emitted only inside the
    guarded block, and the `ClassType` read stays unreachable for
    non-choice types. The design agrees stage 2 must not extend:
    expression patterns "are considered to match a single value from an
    infinite set of values so that a set of expression patterns is never
    exhaustive" (pattern_matching.md:592-594), demonstrated on a FULLY
    ENUMERATED `u8` — all 256 cases — annotated "Not considered
    exhaustive." (:596-607), with enumeration-based exhaustiveness a
    formally REJECTED alternative (:705, "Treat expression patterns as
    exhaustive if they cover all possible values", p2188). Full
    enumeration is therefore not deferred work but design-rejected — the
    current comment :1549-1550 calling it "future work" contradicts the
    design and is deleted, not carried forward (see §2.5). Tuple ROOTS
    likewise do not extend (the landed W-076 root-only record;
    bool_tuple_scrutinee.carbon's bool_pair_keeps_default — all four
    `(bool, bool)` constants plus `default`, :41-47 — stays the standing
    silent pin). Post-lift boundary residue (amended 2026-09-26, review
    fold: rev 1 F4): the same four-constant `(bool, bool)` shape WITHOUT
    a `default` flips from the R8 TODO-abort to the new definitive
    `MatchNonexhaustiveNoIrrefutableArm`, even though the design's
    reduction (pattern_matching.md:589-591 — constant tuple expression
    patterns are treated as tuple patterns, and `bool` like a choice
    type) would make the four-pair set exhaustive. That is the landed
    W-076 root-only record surfacing as a definitive diagnostic, not a
    new call, and the wording holds: "no `case` arm that matches every
    value" stays literally true — no SINGLE arm matches every value. The
    boundary is pinned by the new fail_bool_pair_enumeration subfile
    (§4) and carried as §7 R-6. Break condition: upstream re-annotating
    :598 or reversing :705 — then a new work item, not this one.
3.  **The residual no-default-no-irrefutable-arm shape gets a REAL
    diagnostic, not a TODO: new kind `MatchNonexhaustiveNoIrrefutableArm`
    (Error).** The design's own nonexhaustive example is an INTEGER
    match — `fn F(n: i32)` with `case 0`..`case 4`, annotated "❌ Error,
    this `match` is not exhaustive." (pattern_matching.md:657-668, under
    the :651-655 rule "the patterns in a `match` are not exhaustive and
    no `default` is provided") — so keeping a semantics-TODO would be an
    R17 quiet-gate violation on a shape the design fully specifies.
    Neither existing kind fits: `MatchNonexhaustive` (registered
    kind.def:173; text at handle_match.cpp:1510-1513) says "`match` on
    choice {0} ... does not cover alternative{1:s} {2}" and
    `MatchNonexhaustiveBool` (kind.def:174; :1461-1464) enumerates
    missing values — integers cannot enumerate their missing values
    (:592-594), so a new kind is needed. Adjudicated:
    -   Kind: `MatchNonexhaustiveNoIrrefutableArm`, primary only, no
        note — mirroring `MatchNonexhaustiveBool`'s primary-only shape.
        The name states the one in-lane remedy besides `default`: an
        irrefutable arm (the design's `_: auto` reformulation,
        :579-581).
    -   Text: ``"`match` on {0} has no `default` arm and no `case` arm
        that matches every value"`` with one `SemIR::TypeId` parameter
        (the unqualified scrutinee type — renders `i32` or
        `(i32, i32)`, covering the tuple lane with the same kind).
        Deliberately parallel to its two siblings' "`match` on X has no
        `default` arm and does not cover ..." while claiming no
        enumeration.
    -   R15 reconciliation of the disappearing TODO string: the string
        ``match statement without `default` arm`` occurs in exactly four
        goldens tree-wide (verified by grep): fail_todo_no_default.carbon
        :27 (fail_literal_arms) and :48 (fail_irrefutable_binding_arm,
        the recorded conservative-gate pin), fail_guarded_default.carbon
        :28 (fail_integer_no_covering_arm), and — comment-only —
        usefulness_no_false_positive.carbon:219 (the dead_default_exempt
        header). §4/§6 dispose of each; no fifth pin exists.
        Break condition: reviewers vetoing the kind name or text is a
        wording veto only — the Error severity and the no-enumeration shape
        are the design's own calls (:659, :592-594).
4.  **Lowering needs nothing.** The convergence machinery in
    `MatchStatement` is lane-independent: with no unguarded `default`,
    the block on top of the stack is "the last arm's empty else block,
    whose edge from the last arm's test branches straight to the
    resumption block" (handle_match.cpp:1564-1574), and the choice-lane
    comment already names that shape "dynamically dead when the arms are
    exhaustive ... the same shape an empty `default` arm produces"
    (:1553-1559). An unguarded irrefutable binding arm's condition is a
    constant `true` (`MakeBoolLiteral`, :801-802), so the dead else edge
    is even statically obvious to LLVM. The lift only deletes the TODO
    in front of this path; the integer lane then takes byte-for-byte the
    code path the exhaustive-choice lane takes today, whose lowering pin
    is lower/testdata/match/choice_payload.carbon (default dropped at
    W-078a §6.9 — an exhaustive no-`default` match lowering golden
    already in-tree). Integer-lane lowering pins come free from §6:
    lower/testdata/match/var_binding.carbon's three subjects lose their
    dead `default` arms (:24, :32, :41) and regenerate as
    irrefutable-arm-exhaustive matches, and the new positive check
    golden carries `//@dump-sem-ir` for the SemIR side (§4). No file
    under toolchain/lower/ changes code; grep confirms lower/ has no
    match-specific `default` handling to update.
5.  **Ledger closure: W-078 CLOSES, and W-008's R8 residue line is
    rewritten.** Spec in §8. The W-008 entry's RESIDUE list ("[R8] ...
    gate handle_match.cpp:1130 ... Stays — the S2e-recorded conservative
    gate") and the W-078 evidence line `handle_match.cpp:1130` are
    STALE line references (the gate sits at :1551 at e06a55d; the :1130
    number predates W8b/W-066 growth) — the discharge edit replaces, not
    repeats, them.

## §2 Mechanism (no SemIR change; diagnose-and-proceed; no insts emitted)

1.  **`MatchStatement` (handle_match.cpp:1536-1552):** delete the
    integer/tuple branch (:1542-1552) with its TODO; the `!has_default`
    path calls `DiagnoseNonexhaustiveMatch` for EVERY lane. The
    surviving comment states: exhaustiveness is an unguarded irrefutable
    arm (any lane) or full closed-domain coverage (choice/bool only);
    enumeration is design-rejected (pattern_matching.md:596-607, :705).
2.  **`DiagnoseNonexhaustiveMatch` (:1429-1517):** ONE addition, after
    the `has_irrefutable_arm || has_error_arm` early return (:1432-1434)
    and before the bool branch (:1439). (Amended 2026-09-26, review
    fold: rev 1 F1 + rev 2 F1/F3 — the previously specced
    error-scrutinee guard rested on a false premise and is DROPPED: an
    error-typed scrutinee never reaches this function, or
    `MatchStatement` at all, because `IsSupportedScrutineeType`
    (handle_match.cpp:171-213) rejects `ErrorInst::TypeId` —
    `TryGetIntTypeInfo` is nullopt and the bool/choice/tuple tests are
    all false — so ``context.TODO(node_id, "match on unsupported
    scrutinee type")`` fires at :282-284 and aborts checking of the
    whole `match` (`Context::TODO` returns false, context.cpp:49-53).
    The MatchCondition gate is the real barrier; a defensive guard here
    would be unreachable dead code. Recorded in §7 R-5.)
    -   Lane branch: `if (!is_bool && !IsMatchableChoiceType(...))`
        (`IsMatchableChoiceType` unqualifies internally, per the
        :1237-1238 comment) → emit `MatchNonexhaustiveNoIrrefutableArm`
        at `node_id` with the unqualified type; return. This keeps the
        `GetAs<SemIR::ClassType>` at :1472-1474 reachable only for
        choice types, exactly as before.
3.  **`DiagnoseDeadDefault` (:1231-1300):** simply DELETE the entry
    lane gate (:1237-1243) — no replacement guard. (Amended 2026-09-26,
    review fold: rev 1 F1 + rev 2 F1/F3 — the previously specced
    error-scrutinee guard's motivating shape
    `match (undeclared) { case n: i32 => {} default => {} }` cannot
    occur: the error-typed scrutinee aborts checking at MatchCondition
    (§2.2), so no arm handler runs and `DiagnoseDeadDefault` is never
    called for it; the binding-arm-records-a-`Wildcard`-key scenario was
    vacuous.) The
    `has_error_arm` suppression (:1246-1257) and stage 1 (:1263-1281)
    then run for every lane; stage 2's `UnguardedArmsCoverWholeDomain`
    call + `MatchDefaultNeverMatchesFullCoverage` emission (:1283-1299)
    are wrapped in the relocated bool-or-choice test (§1.2). Existing
    kinds `MatchDefaultNeverMatches` / `...PriorArm` (:1259-1261,
    :1273-1274) are reused verbatim — their texts ("`default` arm never
    matches; every value of the scrutinee is matched by prior arms";
    "every value is matched by this prior arm") are already
    lane-neutral. Guarded `default` arms are covered for free: both
    handlers already call `DiagnoseDeadDefault` (:1316, :1332), and a
    guarded `default` still records nothing toward exhaustiveness
    (:1340-1345), so it still never discharges the (now softer)
    `default` requirement.
4.  **Kind registration:** `MatchNonexhaustiveNoIrrefutableArm` in
    toolchain/diagnostics/kind.def's Match block, alphabetized after
    `MatchNonexhaustiveBool` (:174) and before
    `UnexpectedTokenInMatchCasesBlock` (:175); §4's fail files cover it,
    as the diagnostic coverage test requires.
5.  **Comment sweep (behavioral honesty, no logic):** the file-header
    integer sentence (:118-120 "Integer scrutinees keep requiring
    `default`..." → irrefutable-arm discharge + the design-rejected
    enumeration note), the usefulness paragraph's exemption sentence
    (:132-136), the header TODO (:148-152 — the R8/W-078 sentences go;
    "full enumeration" is stated as design-rejected, not future work,
    per §1.2), `EmitCaseArmTestAndBind`'s recording comment (:905-921
    gains the lane-neutral discharge note), `DiagnoseDeadDefault`'s doc
    comment (:1209-1230, R8 paragraph replaced by the §1.1 agreement
    invariant), the `MatchDefault` handler comment (:1306-1315, R8
    sentences), `DiagnoseNonexhaustiveMatch`'s doc comment (:1418-1428
    now covers three lanes), and `MatchStatement`'s comments
    (:1544-1559). Golden-header additions to the sweep (amended
    2026-09-26, review fold: rev 1 F3 + rev 2 F5): three stale-R8
    golden headers —
    fail_case_never_matches_after_irrefutable.carbon:17-19, which
    becomes actively FALSE when its own four `default` arms (:35, :55,
    :102, :130) are dropped by §6 item 7, is rewritten to describe the
    lift; fail_case_never_matches_int.carbon:17-20 and
    fail_case_never_matches_tuple.carbon:17-18 keep their `default`
    arms for the honest reason — only refutable arms, no irrefutable
    coverage — and each gets a one-sentence rewrite saying so.

## §3 Slice plan

One slice, one PR (size S), mirroring W-078a §3: commit 1 = §2 compiler
change + kind registration + comment sweep; commit 2 = testdata
restructures + new fail/positive files with AUTOUPDATE markers and empty
CHECK lines (R15/R19) + the §5 conformance edits; runner-side autoupdate
to R26 fixpoint fires after, then the gate and conformance runs, then the
§8 discharge commit (ledger + decision log). No sub-slicing: the compiler
diff is ~three functions, and the churn — §6's inventory — is mechanical.

## §4 Testdata matrix (R16: no hand-written goldens; autoupdate fills)

**Extend `fail_dead_default.carbon`** (the W-078a matrix file; header
:13-29 rewritten to drop "the integer lane stays exempt (R8)") with the
integer/tuple lanes:

| subfile | shape | expect |
| --- | --- | --- |
| fail_int_after_irrefutable | `case n: i32` then `default` (the design's own :238-246 example shape, and dead_default_exempt IntSide's flipped lane) | error + PriorArm note at the binding arm |
| fail_int_after_var_binding | `case var a: i32` then `default` | error + PriorArm note |
| fail_int_mid_constants | `case 5`, `case n: i32`, `default` | error + PriorArm note at the BINDING arm, not `case 5` |
| fail_int_guarded_default_after_irrefutable | `case n: i32` then `default if (g)` | error at the guarded `default` + PriorArm note |
| fail_tuple_after_all_binding | `(i32, i32)` scrutinee, `case (a: i32, b: i32)` then `default` | error + PriorArm note (the §1.1 tuple-`Wildcard`-key proof) |
| fail_int_bind_error_arm_prior | `case b: bool` on `i32` (bind-pass error, recorded covering) then `default` | conversion error + stacked dead-default (integer mirror of W-078a's fail_bind_error_arm_prior) |

**New file `fail_int_nonexhaustive.carbon`** (the R8-lift residual lane;
takes over the two flipped TODO pins):

| subfile | shape | expect |
| --- | --- | --- |
| fail_literal_arms | `case 0`, no `default` (moved from fail_todo_no_default.carbon:20-34) | `MatchNonexhaustiveNoIrrefutableArm` naming `i32` |
| fail_guarded_irrefutable_only | `case n: i32 if (g)`, no `default` | same error — a guarded irrefutable arm discharges nothing (:620-623) |
| fail_tuple_constant_arms | `(i32, i32)` scrutinee, `case (1, 2)`, no `default` | same error naming `(i32, i32)` |
| fail_error_arm_suppresses | `case 5000000000` (pattern error), no `default` | only the arm's own error (`has_error_arm` suppression, :1432-1434) |
| fail_bind_error_arm_no_default | `case b: bool` on `i32`, no `default` | only the conversion error — the bind-pass carve-out sets `has_irrefutable_arm` (§1.1), a documented false negative |
| fail_bool_pair_enumeration | `(bool, bool)` scrutinee, all four constant pairs, no `default` | `MatchNonexhaustiveNoIrrefutableArm` naming `(bool, bool)` — the §1.2 W-076 root-only boundary pin |

Matrix fold notes (amended 2026-09-26, review fold): the previously
specced fail_error_scrutinee_no_default row is DELETED (rev 1 F1 +
rev 2 F1/F3 — its "only `NameNotFound`" expectation was wrong: an
error-typed scrutinee TODO-aborts at MatchCondition, so the actual
output also carries the SemanticsTodo abort, a shape already pinned by
the existing unsupported-scrutinee family, for example
fail_todo_non_int_scrutinee.carbon and fail_todo_adapter_scrutinee
.carbon); fail_bool_pair_enumeration is ADDED per rev 1 F4 (§1.2); and
per the rev 2 record note, fail_guarded_irrefutable_only,
fail_int_after_var_binding, and fail_tuple_after_all_binding must USE
their bindings (or mark them `unused`) so no incidental UnusedBinding
warning rides along and each subfile's golden carries only the intended
diagnostics.

**New positive `no_default_irrefutable.carbon`** with `//@dump-sem-ir`
(the flipped conservative-gate pin, and the §1.4 SemIR CFG pin: constant-
`true` arm condition, last arm's else edge branching straight to the
resumption block):

-   binding_only: `case n: i32 => { return n; }`, no `default` — the
    exact fail_irrefutable_binding_arm shape (fail_todo_no_default
    .carbon:36-54) turned positive (binding USED, so no UnusedBinding
    warning rides along).
-   constants_then_binding: `case 0`, `case 1`, `case n: i32`, no
    `default`.
-   tuple_all_binding: `case (a: i32, b: i32)`, no `default`.
-   The guarded-irrefutable negative for
    the DEFAULT check is already pinned by usefulness_no_false_positive
    .carbon's guarded_irrefutable_prior (:72-81 — guarded `case n: i32`
    prior + `default`, stays silent, now doing double duty). (Amended
    2026-09-26, review fold: rev 1 F1 — a dangling cross-reference to
    an "error_scrutinee_dead_default_silent" subfile was removed here;
    no such subfile was ever specced, and §2.2/§2.3 record why no
    error-scrutinee pin is needed.)

**Deletions/flips:** fail_todo_no_default.carbon is DELETED (both
subfiles superseded above). fail_guarded_default.carbon's
fail_integer_no_covering_arm keeps its shape; its pin flips in place from
SemanticsTodo to `MatchNonexhaustiveNoIrrefutableArm` (autoupdate), and
the file header's "the integer scrutinee's TODO gate" sentence (:14-19)
is rewritten. usefulness_no_false_positive.carbon's dead_default_exempt
subfile (:212-231) is DELETED — the exemption it records ceases to exist;
its IntSide shape lives on as fail_int_after_irrefutable — and the file
header (:13-24) drops the exemption sentence. NOTE (R15): the two flipped
TODO sites were checking ABORTS (`context.TODO` returns false); the
replacement diagnose-and-proceed means those subfiles gain full SemIR
output where none existed — expected autoupdate growth, not drift.

## §5 Conformance

**One program edit, one new program; floor becomes 101/0/28 over 129.**

-   **match_var_ref_binding.carbon MUST be edited or it regresses to
    COMPILE-FAIL:** MutateCopy is `case var a: i32` + `default` (:33-34)
    and MutateThroughRef is `case ref r: i32` + `default` (:43-44) —
    both defaults are unguarded-irrefutable-arm-dead, so the lift makes
    the program ill-formed. (W-078a §5 recorded this file as "integer
    lane → exempt → silent"; that exemption is exactly what this slice
    removes, so the zero-edit claim does not carry over.) Fix: DROP both
    `default => { return -1; }` arms — they are dynamically dead today
    (the irrefutable arms always match), so EXPECT lines are untouched
    and this is not an R16(b) weakening: the design mandates rejecting
    the old shape (pattern_matching.md:238-246), and the program still
    exercises everything it exercised. The dropped-default rationale is
    recorded in the program comment with the design citation.
-   All other programs verified silent by arm-level sweep of every
    `match` in fork/conformance/programs: constant-arm integer matches
    (match_switch :38-41, match_switch_diff :30-34, match_position,
    match_no_fallthrough, match_guarded_default :33-36 — guarded
    defaults with only constant priors are NOT dead, §6 "verified
    silent"), guarded-binding matches (match_guard_binding :30-32,
    match_guard_diff :30-33 — guarded arms record nothing), refutable
    tuple cases (match_tuple_case_diff :25-27), choice/bool lanes
    (match_bool, match_payload_literal, match_single_alternative,
    choice_payload_construct, choice_discriminant_diff,
    choice_generic_diff, choice_generic_roundtrip[_diff],
    match_global_runtime_let, import_runtime_let, control_flow_constructs
    and the question_* family — no integer-lane dead defaults),
    match_sum_type_payload (SKIP, body commented),
    choice_payload_roundtrip_diff.carbon (choice lane, no `default`)
    and cpp_exception_interop.carbon (SKIP; its `match` is commented
    out) — the last two added to the record 2026-09-26 (review fold:
    rev 2 F6).
    project/most_features_missing_match.carbon stays PASS untouched
    (amended 2026-09-26, review fold: rev 1 F2 + rev 2 F2 — this bullet
    previously claimed the file "no longer exists"; that was FALSE: it
    exists at fork/conformance/programs/project/
    most_features_missing_match.carbon, is PASS in the scoreboard, and
    contains an integer match — `case 0`, guarded
    `case a: i32 if (a < 0)`, `default`). The real per-arm
    justification: the only binding arm is GUARDED, so it records
    nothing toward exhaustiveness (handle_match.cpp:927-928) and is
    never pushed to `useful_arms` (:895), and the `case 0` IntConst
    prior cannot subsume the `Wildcard` key — the `default` is NOT dead
    and the program stays PASS. W-078a §5's reference to this file was
    accurate; the §8 discharge must NOT record it as stale.
-   **New program (recommended, raising the floor):**
    control_flow/match_irrefutable_no_default.carbon under the existing
    bullet "Control flow: matching — good switch equivalents" (the
    match_switch.carbon bullet; R7 requires the exact gap-analysis
    string). Shape: an integer match whose only arm is `case n: i32`
    (plus a constants-then-binding function), no `default` — the C
    equivalent is `switch` with `default` only, and the program proves
    the lifted toolchain compiles, runs, and takes the irrefutable arm.
    This is the first conformance-visible behavior the lift ADDS (the
    dead-default diagnostics are compile errors, which conformance
    cannot pin positively), so the floor moves 100→101 PASS, 128→129
    total. `runner.py --self-test` before commit (R7).

## §6 Golden churn inventory (complete; from an exhaustive tree sweep of every `default =>` / `default if` and every match golden)

Positive goldens whose `default` becomes dead → DROP the arm (R16: a
landed positive must not silently gain an error; post-lift the matches
stay exhaustive by way of the irrefutable arm, so the drop is behavior-neutral
and the SemIR regenerates):

1.  **check/match/binding_pattern.carbon** — all three fns: F
    (`case a: i32` + default :21-22), G (`case 5`, `case b: i32`,
    default :33-35), H (`case unused c: i32` + default :44-45). Drop
    three defaults.
2.  **check/match/var_binding.carbon** — basic (`case var a: i32` +
    default :26-27) and composition (`case var (a: i32, b: i32)` +
    default :59-60). Drop two. mixed_element (:77, `(var n: i32, 1)` —
    refutable) keeps its default; the guard subfile (:40-43, guarded
    `var` arm + `default` — a guarded arm records nothing, :927-928)
    stays silent (added to the record 2026-09-26, review fold: rev 2
    F6); fail_todo_* subfiles abort before the
    `default` node; fail_var_arity (error arm) and
    fail_unused_used_in_guard (guarded) stay silent.
3.  **check/match/ref_binding.carbon** — `case ref a: i32` + default
    (:24-25). Drop one.
4.  **check/match/tuple_pattern.carbon** — all_binding subfile
    (`case (a: i32, b: i32)` + default :51-52). Drop one; every other
    subfile's tuple cases are refutable or error arms.
5.  **check/patterns/unused.carbon** — match_case_bindings subfile, all
    four fns (UnusedMarkedTuple :168-169, UnusedMarkedSingle :176-177,
    UsedInBody :184-185, Warns :196-197). Drop four defaults.
6.  **lower/testdata/match/var_binding.carbon** — TwoVarArms (guarded
    `var` arm, then UNGUARDED `case var b: i32`, then default :24),
    VarTuple (:32), RefAlias (:41). Drop three; the regenerated LLVM IR
    is the §1.4 integer-lane exhaustive-no-default lowering pin.

Fail goldens where the `default` was R8 scaffolding, incidental to the
pinned error → DROP the arm (the pinned diagnostics are untouched):

7.  **check/match/fail_case_never_matches_after_irrefutable.carbon** —
    fail_after_binding (:35), fail_after_var_binding (:55),
    fail_after_all_binding_tuple (:102), fail_dead_arm_bindings_warn
    (:130). Four drops; fail_choice_after_binding has no `default`. The
    file header (:17-19) becomes actively FALSE after these drops and
    is rewritten per §2.5 (amended 2026-09-26, review fold: rev 1 F3).
8.  **check/match/fail_binding_scope.carbon** — fail_after_match's
    default (:38). One drop. (fail_sibling_arm is class 9 below.)
9.  **check/match/fail_unused_case_binding.carbon** — default :27. One
    drop.

Fail goldens where the `default` is LOAD-BEARING → keep it; the subfile
gains one stacked `MatchDefaultNeverMatches` + PriorArm (autoupdate;
each is a deliberate pin of the §1.1 bind-error carve-out or of scope
behavior, mirroring W-078a's fail_bind_error_arm_prior stacking):

10. **check/match/fail_binding_scope.carbon** — fail_sibling_arm: the
    default's body IS the test site (`return a` out of scope, :27).
11. **check/match/fail_arm_conversion.carbon** —
    fail_case_binding_conversion (`case b: bool` on i32 + default
    :75-76).
12. **check/match/fail_case_after_bind_error_arm.carbon** — bind-error
    arm + dead `case 5` + default (:31-40); now stacks the dead-default
    too. Its W-078a-era comment "the `default` is integer-lane exempt
    (R8...)" is rewritten.
13. **check/match/fail_ref_binding_value_scrutinee.carbon** —
    `case ref a: i32` errors in the BIND pass
    (ConversionFailureNonRefToRef, :20-26), so the arm is recorded
    covering; default stacks.
14. **check/match/var_binding.carbon** — fail_scope subfile: default
    body references the sibling arm's `a` (:92-97); stacks.

Flips/deletions (from §4):

15. **fail_todo_no_default.carbon** deleted.
16. **fail_guarded_default.carbon** — pin :28 flips in place + header
    comment.
17. **usefulness_no_false_positive.carbon** — dead_default_exempt
    subfile deleted + header comment.

Verified SILENT (no diagnostic change; zero or loc-only churn), for the
record — every remaining match golden was arm-checked: integer
constant-arm files (basic, converging_arms, default_only, nested,
constant_expr_case, constant_scrutinee, negative_literal_case,
fail_case_never_matches_int, fail_case_never_matches_tuple — constant
priors never subsume `default`; the latter two's stale-R8 headers get
the §2.5 one-sentence rewrite, comment-only churn — amended 2026-09-26,
review fold: rev 1 F3), guarded-arm files (guard.carbon — all
four fns guarded; guarded_default.carbon basic :44-53 and compound_guard
:63-69 — the brief's direct question: NEITHER has an irrefutable arm, so
NEITHER default becomes dead, and choice_coverage is choice-lane;
fail_guard_non_bool, fail_guard_sibling_binding,
usefulness_no_false_positive's guarded_prior / both_guarded_twins /
guarded_irrefutable_prior / guarded_default_mid_list), error-arm
suppression (fail_prior_error_arm :241-255, fail_arm_conversion's other
two subfiles, tuple_pattern's fail_ files), fail_incomplete_scrutinee —
aborts at MatchCondition's `RequireCompleteType`
(handle_match.cpp:268-280): an incomplete CLASS scrutinee, diagnosed
before any arm exists (amended 2026-09-26, review fold: rev 1 F1 —
previously misattributed to a §2.3 error-scrutinee guard, which no
longer exists), TODO-abort files (fail_todo_binding_
free_var, _compile_time_binding, _form_binding, _non_constant_case,
_alternative_non_choice, _adapter_scrutinee, _non_int_scrutinee,
_choice_expr_case, _non_constant_bool_case — checking aborts before the
`default` node), tuple-root union negatives (bool_tuple_scrutinee both
subfiles incl. bool_pair_keeps_default, usefulness Tuples/
specific_then_general — no `Wildcard` priors), every choice/bool-lane
file (unchanged by this slice: bool_scrutinee*, fail_bool_*,
choice_*/empty_choice/single_alternative_choice/nested_choice_designator/
payload_subpattern/binding_choice_scrutinee/exhaustive_choice*,
fail_dead_default's existing eight subfiles, check+lower choice/
generic_payload*, payload_layout, let/import_choice, operators/
fail_question — its integer-scrutinee ExprPattern match keeps `default`
after an error arm), lower/match/{basic,tuple_pattern,bool_scrutinee,
choice_*,payload_subpattern,single_alternative_choice}, and all
parse/testdata (parse-only, no check diagnostics). Silent-inventory
additions (recorded 2026-09-26, review fold: rev 2 F6 — files the sweep
had not named explicitly, each verified silent): the question* operator
files — check/operators/{question,question_final,fail_question_final}
.carbon and the five lower/operators/question*.carbon files — whose
every `match` is a choice-lane alternative dispatch, unaffected by this
slice; and check/match's fail_error_payload_no_cascade,
fail_nonexhaustive_payload_literal, and
fail_case_never_matches_full_coverage — all choice-lane, outside the
integer/tuple lanes this slice touches.

Churn totals (amended 2026-09-26, review fold: rev 2 F7): 1
flipped-pin file (fail_guarded_default), 1 deleted file
(fail_todo_no_default), 1 subfile deletion in a kept file
(usefulness_no_false_positive's dead_default_exempt — a deletion, not
a pin flip), 2 new fail files (one an extension), 1 new positive file,
6 positive files dropping 14 dead `default` arms (incl. 1 lower
golden), 3 fail files dropping 6 scaffolding defaults, 5 fail subfiles
across FIVE files (fail_binding_scope, fail_arm_conversion,
fail_case_after_bind_error_arm, fail_ref_binding_value_scrutinee,
var_binding) gaining stacked dead-default errors, 1 conformance
program edited, 1 conformance program added, plus comment-only
refreshes riding autoupdate (§2.5's three golden-header rewrites
included).

## §7 Risks and rejected alternatives

-   **R-1 hidden churn:** a `Wildcard`-prior-plus-`default` golden or
    conformance program missed by §6/§5. Mitigation: the inventory came
    from an exhaustive `default =>`/`default if` grep over ALL of
    toolchain/*/testdata and fork/conformance/programs with per-arm
    classification; any straggler surfaces as a hard failure at regen
    (new error in a non-fail golden) or a COMPILE-FAIL scoreboard row —
    loud both ways, never silent.
-   **R-2 stage-1-without-stage-2 asymmetry contested:** a reviewer may
    push to unify the two stages' gating. Rebuttal is one sentence: the
    union stage requires a closed root domain, which integers do not
    have (pattern_matching.md:592-607) and whose absence the `ClassType`
    read would CHECK-fail on (§1.2) — the gate placement IS the
    correctness argument.
-   **R-3 diagnostic-text veto:** kind name or wording (§1.3) — a
    wording veto at most; severity and shape are design-fixed (:659).
-   **R-4 SemIR/LLVM shape drift in restructured positives:** dropping
    14 `default` arms changes convergence-block arithmetic
    (`num_blocks`, :1571) and lower IR; pure regen, and the
    reconciliation diff must show only per-file reshapes plus the two
    abort-flip growths (§4 note).
-   **R-5, demoted to a record — no error-scrutinee guards (amended
    2026-09-26, review fold: rev 1 F1 + rev 2 F1/F3):** the original
    R-5 defended guards whose premise was vacuous. In-tree fact: an
    error-typed scrutinee aborts at MatchCondition —
    `IsSupportedScrutineeType` (handle_match.cpp:171-213) rejects
    `ErrorInst::TypeId`, so the unsupported-scrutinee TODO at :282-284
    aborts checking (context.cpp:49-53) and `MatchStatement`, the arm
    handlers, `DiagnoseDeadDefault`, and `DiagnoseNonexhaustiveMatch`
    are never reached. That MatchCondition gate is the real barrier; a
    defensive guard in either diagnose function would be unreachable
    dead code, so none is added.
-   **R-6 `(bool, bool)` enumeration boundary (added 2026-09-26, review
    fold: rev 1 F4):** the §1.2 post-lift residue — the four-pair
    `(bool, bool)` no-`default` shape flips from TODO-abort to the new
    definitive Error although the design's reduction
    (pattern_matching.md:589-591) would make the set exhaustive. W-076
    root-only residue; the diagnostic wording stays literally true (no
    single arm matches every value); pinned by
    fail_bool_pair_enumeration (§4). A future item extending tuple-root
    union coverage retires the pin, not this diagnostic's wording.
-   **Rejected: full-enumeration exhaustiveness for small integer
    types.** Not deferred — design-rejected (:596-607, :705); recorded
    so no future item resurrects it without a design change.
-   **Rejected: keeping the TODO for the residual no-default shape.** An
    R17 quiet gate on a design-specified error (:657-668); also
    inconsistent with the bool lane, which W-076 already gave a real
    diagnostic in the identical position.
-   **Rejected: a separate fail file per lane for dead defaults.**
    Extending fail_dead_default.carbon keeps the whole
    `MatchDefaultNeverMatches` family's matrix in one place, mirroring
    how fail_case_never_matches_{int,tuple,alternative} split by lane
    only where the SHAPES differ.

## §8 Verification and discharge

1.  Regen: runner autoupdate to R26 fixpoint (expect pass 2 loc-only);
    churn confined to the §6 inventory.
2.  Gate: full `bazelisk` toolchain gate green (R21 mirror), prek clean
    (R25: `uvx prek run --files ...` locally first).
3.  Conformance: **101 PASS / 0 FAIL / 28 SKIP over 129** — the §5 edit
    keeps match_var_ref_binding PASS, the new program adds one;
    `runner.py --self-test` green (R7). Any other movement is a §6 miss
    — stop and reconcile.
4.  Reconciliation: diff audit that no golden outside §6 changed, and
    that the TODO string ``match statement without `default` arm``
    survives NOWHERE in the tree (code or goldens) — grep-verified as
    part of discharge.
5.  **Ledger edits at discharge (fork/inventory/work-items.json):**
    -   W-078: notes gain the closing record — "INTEGER-HALF DISCHARGED
        -   R8 LIFTED (fork/w078b/plan.md): the `MatchStatement` TODO is
            replaced by `MatchNonexhaustiveNoIrrefutableArm`; unguarded
            irrefutable arms discharge integer/tuple exhaustiveness
            (`has_irrefutable_arm`, the already-landed
            `DiagnoseNonexhaustiveMatch` early return);
            `DiagnoseDeadDefault` stage 1 runs on every lane with stage 2
            still bool/choice-gated (no closed domain, `ClassType`
            CHECK-fail); fail_dead_default.carbon integer/tuple subfiles +
            fail_int_nonexhaustive.carbon + no_default_irrefutable.carbon;
            conformance 101/0/28 over 129" — and the item is CLOSED (both
            halves + R8 lift; the stale `handle_match.cpp:1130` evidence
            line replaced by the new diagnostic sites).
    -   W-008: the RESIDUE [R8] sentence is rewritten to "DISCHARGED at
        W-078b (fork/w078b/plan.md): the conservative gate is lifted;
        irrefutable-arm exhaustiveness lands, enumeration-based
        exhaustiveness recorded design-rejected
        (pattern_matching.md:596-607, :705)".
    -   Decision-log entry "W-078b: R8 lift + integer/tuple dead
        `default` (date)" carrying §1.1 (unguarded-irrefutable-only,
        with the agreement invariant), §1.2 (stage-2 gate placement as
        the structural FullCoverage guarantee + the design-rejected
        enumeration record, replacing the in-code "future work" claim),
        §1.3 (the new kind, its text, and the R15 four-pin
        reconciliation), and the §5 conformance-program edit precedent
        (first time a landed program is edited for a new diagnostic;
        rationale: dynamically dead arms dropped, EXPECTs untouched,
        design-mandated rejection), each with its break condition.

## Hand-off notes for the implementer

-   The lane test spelling matters: `Is<SemIR::BoolType>` on the
    UNQUALIFIED id, `IsMatchableChoiceType` on the qualified id (it
    unqualifies internally) — copy the :1237-1240 / :1540-1543 pattern.
-   Do not touch the unconditional exhaustiveness recording block
    (:922-946) — the W-066 discharge note's invariant (diagnosed-dead
    arms still record) is load-bearing for §1.1's agreement proof.
-   `fail_int_bind_error_arm_prior` and the class-10-14 stacking files
    must keep using shapes whose errors do NOT abort checking (bind-pass
    conversion errors; never `case template`/form-binding/non-constant
    shapes, which TODO-abort — W-078a §4's non-aborting spelling pin).

## Sign-off

Two adversarial plan reviews returned APPROVE-WITH-AMENDMENTS. The
consolidated amendments were folded into this plan on 2026-09-26, each
marked in place with a dated "(amended 2026-09-26, review fold: ...)"
note. The folds:

1.  rev 1 F1 + rev 2 F1/F3 (both reviews' top finding): the
    error-scrutinee sub-mechanism rested on a false premise — an
    error-typed scrutinee TODO-aborts at MatchCondition
    (`IsSupportedScrutineeType`, handle_match.cpp:171-213, rejects
    `ErrorInst::TypeId`; the abort fires at :282-284 by way of
    `Context::TODO`, context.cpp:49-53), so `MatchStatement`, the arm
    handlers, and both diagnose functions are never reached. Both
    proposed `ErrorInst` guards dropped (§2.2, §2.3 — the
    `DiagnoseDeadDefault` change is now "delete the :1237-1243 entry
    lane gate, wrap stage 2 :1283-1299 in the bool/choice test"); the
    fail_error_scrutinee_no_default row deleted and the dangling
    error_scrutinee_dead_default_silent cross-reference removed (§4);
    fail_incomplete_scrutinee reattributed to `RequireCompleteType`
    (handle_match.cpp:268-280) in §6; §7 R-5 demoted to a record that
    the MatchCondition gate is the real barrier.
2.  rev 1 F2 + rev 2 F2: §5's "most_features_missing_match.carbon no
    longer exists" claim was FALSE; replaced with the real per-arm
    silence justification (the only binding arm is guarded and records
    nothing, handle_match.cpp:927-928, :895; the program stays PASS).
    W-078a §5's reference to the file stands accurate and is not
    recorded as stale.
3.  rev 1 F3 + rev 2 F5: three stale-R8 golden headers added to the
    §2.5/§6 comment sweep —
    fail_case_never_matches_after_irrefutable.carbon:17-19 (rewritten
    to describe the lift once its own four defaults drop),
    fail_case_never_matches_int.carbon:17-20 and
    fail_case_never_matches_tuple.carbon:17-18 (one-sentence
    honest-reason rewrites).
4.  rev 1 F4: the `(bool, bool)` full-enumeration no-`default` boundary
    recorded in §1.2 and §7 R-6 (W-076 root-only residue, with the
    wording defense) and pinned by the new fail_bool_pair_enumeration
    subfile (§4).
5.  rev 2 F5: the intro's :1549-1550 quotation corrected to the
    verbatim in-code text, held between google-doc-style-ignore
    markers — a code span proved insufficient: the doc-style hook is
    line-based and rewrote the quote's wording inside backticks, so the
    marker form (the in-tree precedent) is used instead.
6.  rev 2 F6: silent-inventory additions — check/match/
    var_binding.carbon's guard subfile (:40-43), the question* operator
    files, fail_error_payload_no_cascade /
    fail_nonexhaustive_payload_literal /
    fail_case_never_matches_full_coverage (§6), and
    choice_payload_roundtrip_diff.carbon / cpp_exception_interop.carbon
    (§5).
7.  rev 2 F7: §6 tallies corrected — the stacked-diagnostic class spans
    FIVE files, and usefulness_no_false_positive.carbon's change is a
    subfile deletion, not a pin flip.
8.  rev 2 record note: the §4 fail-matrix note that
    fail_guarded_irrefutable_only, fail_int_after_var_binding, and
    fail_tuple_after_all_binding must use (or mark `unused`) their
    bindings so their goldens carry only the intended diagnostics.

Status: APPROVED FOR IMPLEMENTATION, 2026-09-26.
