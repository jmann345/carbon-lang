<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-066 plan: usefulness diagnostics for match case patterns

Status: PLAN. Drafted 2026-09-25. Size S — one implementation slice.
Baseline: trunk 869de65 (post-W-008/W8c; conformance **99 PASS / 0
FAIL / 28 SKIP over 127**). Authoritative record:
fork/inventory/work-items.json W-066. NO implementation in this
document. All verification rides self-hosted runner CI (autoupdate to
fixpoint per R26; gate per R21; conformance per R9). The W-008 blocker
is discharged: W8a fixed the value domain usefulness comparisons need —
tuple constant vectors and alternative index + payload constants
(fork/w008/plan.md §3.4, verified 2026-09-25).

Scope sentence: diagnose, as an error at the offending arm with a note
naming the covering prior arm, every `case` arm of a `match` statement
whose pattern is not useful in the context of the prior arms — exact
constant duplicates (compared by evaluated constant value, never source
form), constants subsumed by a prior arm's irrefutable subtree at the
same position, and any `case` arm after an unguarded irrefutable arm —
over exactly the in-slice pattern domain W-008 left (integer constants
including negative and constant-expression forms, tuple constant
vectors, choice alternatives with and without payload constants,
bindings, `var`/`ref` bindings, guards, `default`), changing no SemIR
and no runtime behavior (first-match-wins dispatch is already
design-correct, pattern_matching.md:694-695).

## 1. Design adjudications

Each entry: the design citation, the call, and the break condition
that would invalidate it.

### 1.1 Severity: Error, not warning

-   Citation: docs/design/pattern_matching.md:625-631 ("We will
    diagnose the following situations: A pattern is not useful in the
    context of prior patterns...") and the worked example's own
    annotation at :645 — "❌ Error, this pattern never matches."
    Precedents: parse's arms-after-`default` diagnostic is an Error
    (`UnreachableMatchCase`, toolchain/parse/handle_match.cpp:138-141,
    pinned by parse/testdata/match/fail_cases_after_default.carbon),
    and it diagnoses the same never-matches condition one layer
    earlier. The fork's Warning precedents (UnusedBinding,
    patterns/unused.carbon; UnusedPatternNoBindings) are about unused
    _bindings_ — code that runs but whose result is unused — not about
    arms that cannot execute.
-   Call: Error.
-   Break condition: a design change re-annotating the :645 example,
    or an upstream decision landing this class as a warning.

### 1.2 One diagnostic for duplicate and subsumed alike

-   Citation: pattern_matching.md:627-631 defines a single condition —
    "A pattern is not useful in the context of prior patterns... all
    cases it could cover are handled by prior cases" — with no
    duplicate-vs-subsumed distinction; :577-578 defines useful purely
    extensionally (a value exists that P matches and no prior
    matches).
-   Call: one error kind covers `case 5` after `case 5`, `case 5`
    after `case 2 + 3`, `case (1, 2)` after `case (1, b: i32)`
    (subsumption by a prior more-general pattern), and `case 5` after
    `case n: i32` (subsumption by a prior irrefutable arm). The note
    names which prior arm covers it; the wording does not classify.
-   Break condition: none foreseen; a reviewer preferring split
    wording is a polish veto, not a design conflict.

### 1.3 Guards: prior guarded arms never block later ones

-   Citation: pattern_matching.md:620-623, verbatim: "no attempt is
    made to determine the value of any guards... a guard on that
    pattern is assumed to evaluate to true and a guard on any pattern
    in the context set is assumed to evaluate to false."
-   Call: the context accumulator records only UNGUARDED arms (the
    exact rule the SF-7 exhaustiveness machinery already applies to
    `covered_alternatives` and `has_irrefutable_arm`,
    handle_match.cpp:649-675). The usefulness CHECK runs for guarded
    and unguarded arms alike: a guarded arm whose pattern is fully
    covered by a prior unguarded arm is dead regardless of its guard,
    because control only reaches its test with values the prior arm
    already consumed. A guarded `default` mid-list (W-067) is a
    guarded arm in the context sense: it blocks nothing.
-   Break condition: a design change to the worst-case guard
    assumption.

### 1.4 An arm after an unguarded irrefutable arm is in scope

-   Citation: pattern_matching.md:627-629 ("cannot match because all
    cases it could cover are handled by prior cases or a prior
    `default`"); `default` is equivalent to `case _: auto`
    (handle_match.cpp:91-100 records the design rule), and parse
    already errors on arms after an unguarded `default`
    (fail_cases_after_default.carbon) — an unguarded irrefutable
    binding arm (`case n: i32`, `case var a: i32`, all-binding tuple
    roots) covers exactly the same value set, so consistency demands
    the same treatment at the check layer, where bindings become
    known.
-   Call: any `case` arm (guarded or not) after an unguarded
    irrefutable arm diagnoses. The existing `has_irrefutable_arm` bit
    is the trigger; the prior arm's location must additionally be
    recorded for the note (§2.2).
-   Break condition: none; this is the F3 shape's closest kin.

### 1.5 `default` arms are not diagnosed in this slice

-   Citation: pattern_matching.md:627-629 includes `default` in the
    mandate ("if a pattern or `default` cannot match"). HOWEVER, the
    fork's R8 conservative gate REQUIRES a `default` arm on every
    integer-scrutinee `match` even when an unguarded irrefutable arm
    makes it genuinely exhaustive (handle_match.cpp:1130, the R8 TODO
    string "match statement without 'default' arm"; pin
    match/fail_todo_no_default.carbon:48 records exactly the
    irrefutable-binding-arm case as the CONSERVATIVE gate; W-008
    residue R8 marks lifting it "W-066-adjacent polish").
-   Call: diagnosing a dead `default` while R8 stands would make
    `match (n) { case m: i32 => {...} }` unwritable — the gate demands
    the `default` and the usefulness check would reject it. So this
    slice diagnoses `case` arms only; `default` arms (guarded and
    unguarded) are exempt from the usefulness check, the exemption is
    stated in the diagnostic-site comment with this citation, and a
    follow-up work item (proposed id W-078, filed as part of this
    slice's ledger edit) bundles default-arm usefulness WITH the R8
    lift, which must land together or in that order. Negative goldens
    record the exemption (§4). This also keeps five existing goldens
    byte-stable (§6: binding_pattern.carbon,
    binding_choice_scrutinee.carbon, var_binding.carbon,
    fail_binding_scope.carbon, exhaustive_choice.carbon:95-98).
-   Break condition: the R8 lift landing — W-078 then owes the
    `default` half of the design mandate.

### 1.6 Comparison is by evaluated constant value, never source form

-   Citation: the work-item scope cut (W4 slice-1 review finding F3)
    and W-008 plan RF-4: a `case` expression is admitted whenever its
    constant value is a concrete `IntValue`
    (pattern_match.cpp:1160-1170), so `case 5` and `case 2 + 3` are
    the same pattern extensionally; pattern_matching.md:592-594
    identifies an expression pattern with the single value it matches.
-   Call: keys are evaluated constants — the integer value for
    integer leaves, the alternative's discriminant index (plus payload
    constant slots) for alternative roots, elementwise vectors for
    tuple roots. Source text never participates.
-   Break condition: R9 widening (non-constant or symbolic case
    expressions admitted) — W-008's residue already records that R9
    must not widen before W-066; after this slice the dependency
    inverts and R9 widening must extend or gate the key builder first.

### 1.7 Single-prior subsumption suffices; no pattern matrix

-   Citation: pattern_matching.md:588-594 — expression patterns that
    are not constant tuple/struct/choice values "are considered to
    match a single value from an infinite set of values so that a set
    of expression patterns is never exhaustive". In-slice, choice
    alternatives occur only at the ROOT of a case pattern: tuple
    elements and payload leaves are constant integers, bindings, or
    nested tuples of those (fork/w008/plan.md §2.2 "Element scope
    honesty", §2.3; bool scrutinees are gated, filed W-076, and the
    W8 OQ-4 adjudication explicitly kept them out of W-066's domain;
    struct patterns are gated, filed W-077).
-   Call: an arm is dead iff some SINGLE prior unguarded arm subsumes
    it slot-wise (each slot: prior is wildcard, or both constant and
    equal; alternative roots additionally require equal discriminant).
    Argument for completeness, recordable in one paragraph: every
    non-wildcard leaf slot draws from an infinite domain by design
    fiat, and arms with different root alternatives are disjoint, so
    for a finite set of priors to cover a later arm's value set, pick
    for each wildcard slot of the later arm a value distinct from
    every constant any prior uses at that slot — a prior matching the
    resulting value must be wildcard-or-equal at every slot, that is it
    subsumes the arm outright. The design's own multi-arm-union
    example (:632-647) needs alternative patterns at tuple element
    positions, which are out of slice. So no pattern matrix, no
    usefulness lattice beyond slot-wise subsumption.
-   Break condition: any finite domain entering a leaf position —
    bool scrutinees (W-076), choice-typed tuple elements or payload
    leaves, struct patterns (W-077), or design-level "treat constant
    choice values as alternative patterns" applied below the root.
    Whichever lands first must revisit this section; the accumulator
    (a per-statement vector of per-arm keys, §2.2) is the right shape
    to extend to a matrix walk, so nothing here paints that in.

### 1.8 Symbolic and generic scrutinees; error arms

-   Citation: R9 (pattern_match.cpp:1165-1170) already rejects
    non-concrete constants, so symbolic integer case keys cannot
    arise; generic choice scrutinees that are in-slice (W5-S3) carry
    concrete alternative metadata (index), so their keys are sound;
    metadata-less generic choice shapes are behind the scrutinee gate
    (choice_generic_payload_scrutinee.carbon:132). Error suppression
    precedent: `has_error_arm` (handle_match.cpp:662-666) makes
    exhaustiveness silent when any arm errored.
-   Call: an arm whose pattern or condition errored gets no key, is
    never itself diagnosed, and records nothing (its coverage is
    unknowable); later arms are still checked against the sound keys
    accumulated so far — no false positive is possible from checking
    against strictly-recorded priors. Unlike exhaustiveness, a prior
    error arm does not suppress later usefulness checks: usefulness
    only ever compares against arms whose keys are known.
-   Break condition: none; mirrors the landed suppression rule.

### 1.9 `default` before the end is already parse-blocked

-   Verified: an UNGUARDED `default` closes the case loop and any
    following `case`/`default` gets the parse-level Error
    `UnreachableMatchCase` with checking skipped
    (parse/handle_match.cpp:130-146,
    parse/testdata/match/fail_cases_after_default.carbon), so the
    check-layer context set can never contain a prior unguarded
    `default`. A GUARDED `default` mid-list keeps the loop open by
    design (W-067) and is excluded from the context per §1.3. No new
    work; stated so reviewers need not re-derive it.

## 2. Mechanism

Diagnostic-only: no new SemIR insts, no CFG change, no lowering
change. Everything lands in toolchain/check (handle_match.cpp,
pattern_match.cpp/.h, context.h) plus kind.def.

### 2.1 The per-arm key, and where its values already sit

A key is a small tree over the scrutinee's shape, one node per
pattern position:

-   `Wildcard` — the position is covered by an irrefutable subtree:
    a value/`ref` binding, a `var` wrapper over an irrefutable
    subtree, or an all-binding tuple. The existing classifier
    `IsIrrefutableMatchCasePattern` (pattern_match.cpp:665-692) is
    the exact predicate; the key builder reuses it (or inlines the
    same worklist) rather than re-deriving refutability.
-   `IntConst(value)` — an integer expression leaf's evaluated
    constant. The value is read exactly where the condition builder
    reads it: the leaf `ExprPattern`'s region result
    (`expr_regions().Get(region_id).result_id`) looked up in
    `constant_values()` — the same lookup
    `DoMatchCaseExprPattern` performs at pattern_match.cpp:1165. This
    is a memoized-constant READ, not a re-evaluation: check-time
    evaluation already ran and the test pass already gated
    non-concrete/non-`IntValue` results behind the R9 TODO (which
    aborts the arm before any key is built). The stored key value is
    the `IntValue`'s integer value (its `IntId`), scrutinee-
    normalized: `case 5`, `case 2 + 3`, and `case -(4 * 4)` versus
    `case -16` key equal iff their APInt values are equal. The
    implementer must verify `IntId` equality is value-canonical
    across the admitted constant types (`Core.IntLiteral` literals vs
    typed constants) with the mixed-form duplicate golden (§4); if
    `IntId` is not canonical across widths, compare the APInts by way of
    `ints().Get` instead — either way the key is the VALUE.
-   `Alternative(index, payload...)` — a choice-alternative root:
    the discriminant index from `MatchCaseContext::Alternative::index`
    (resolved at pattern-check time, handle_match.cpp:381-384 and
    :503-507 — the same field the condition builder's discriminant
    test consumes in `MatchCaseAlternativePatternMatch`,
    pattern_match.cpp:561-611), plus the payload subpattern slots
    (from walking `payload_pattern_id`), or no payload slots for the
    bare `.Name` spelling — the design treats a constant choice value
    as an alternative pattern (pattern_matching.md:589-592), so
    `case .Stop` twice keys equal through either spelling.
-   `Tuple(elements...)` — elementwise, in scrutinee element order.
    Arity against the scrutinee is already enforced
    (`MatchCaseTuplePatternWrongArity`), so two keys for the same
    scrutinee type are structurally compatible; a kind mismatch
    during comparison is treated as not-subsumed (defensive, should
    be unreachable).

The key is built by a read-only worklist walk over the CHECKED
pattern insts (`TuplePattern`, `VarPattern`, binding patterns,
`ExprPattern`), a sibling of `IsIrrefutableMatchCasePattern` and
housed next to it in pattern_match.cpp, exported through
pattern_match.h (proposed name: `BuildMatchCaseUsefulnessKey`). It
runs only after the arm's test pass succeeded, so every shape it can
meet is one the engine just accepted; any unexpected inst kind yields
no key (arm records nothing, diagnoses nothing) rather than a crash.

### 2.2 The accumulator

`Context::MatchStatementContext` (context.h:327-341) gains the
usefulness sibling of `covered_alternatives`:

-   `useful_arms`: a vector of `{key, introducer_node_id}` — one
    entry per prior UNGUARDED, non-error `case` arm, in arm order.
    The `introducer_node_id` (already carried per-arm in
    `MatchCaseContext`) locates the note.
-   `has_irrefutable_arm` additionally needs the irrefutable arm's
    location for the note; either widen the bool to an optional node
    id or let the irrefutable arm's all-`Wildcard` key entry in
    `useful_arms` carry it (recommended: the latter — one list, one
    subsumption loop, and `has_irrefutable_arm` keeps its
    exhaustiveness role untouched).

Key storage is per-statement and dies with the statement's stack
entry; nested `match` statements stack naturally. Cost is
O(arms² × pattern size) per statement with trivial constants —
irrelevant at real-arm counts, and strictly bounded by code size.

### 2.3 When the check fires, and the diagnostic

Site: `EmitCaseArmTestAndBind` (handle_match.cpp:564-770), in/next to
the existing coverage-recording block (:662-675) — the one point both
unguarded arms (from `MatchCase`) and guarded arms (from
`MatchCaseGuardIntroducer`) flow through, after the test pass
succeeded and with `pattern_id`, the resolved `alternative`, and the
introducer node all in hand. Order:

1.  Skip entirely for error arms (`pattern_id` or `cond_value_id` is
    `ErrorInst`), per §1.8.
2.  Build this arm's key.
3.  If any recorded prior key subsumes it (slot-wise, §1.7), emit the
    error at THIS arm's `introducer_node_id` with the note at the
    covering arm's recorded `introducer_node_id`. Checking CONTINUES
    (the arm still emits its normal SemIR): this is a
    diagnose-and-proceed error like `MatchNonexhaustive`, not an
    aborting TODO, so a `fail_` golden still shows well-formed SemIR
    and later arms still get checked. First covering arm wins the
    note (arm order; deterministic).
4.  If the arm is unguarded (and not diagnosed dead — a dead arm adds
    nothing new to the covered set by definition, so recording it is
    harmless but pointless; recommended: record only useful arms to
    keep notes pointing at the FIRST covering arm), append its key.

`default` arms never reach this site (`MatchDefault` and
`MatchGuardedDefault` are separate handlers) — the §1.5 exemption is
the absence of any new code there, plus a comment at each handler
citing §1.5/W-078.

Proposed diagnostics (kind.def gets two entries in the match block,
alphabetically between `MatchAlternativeUnexpectedParens` and
`MatchCaseTuplePatternWrongArity`):

```cpp
CARBON_DIAGNOSTIC(MatchCaseNeverMatches, Error,
                  "`case` pattern never matches; every value it can "
                  "match is matched by a prior arm");
CARBON_DIAGNOSTIC(MatchCaseNeverMatchesPriorArm, Note,
                  "pattern is fully covered by this prior arm");
```

Wording follows the design's own phrase ("this pattern never
matches", :645) and the parse-layer sibling's register ("unreachable
case; ..."), lowercase, no trailing period, note-with-location per
the `UnusedButUsedHere` shape. Names are proposals; reviewers may
polish wording, not severity.

### 2.4 Subsumption

Lockstep recursive compare of two keys (worklist, misc-no-recursion
per house style). `A subsumes B` iff at each node: A is `Wildcard`;
or both `IntConst` with equal value; or both `Alternative` with equal
index and A's payload slots subsume B's elementwise (a payload-free
alternative has zero slots and subsumes itself); or both `Tuple` and
elementwise subsumption. Nothing else subsumes. Note the asymmetry:
`Wildcard` never IS subsumed by a constant — `case (1, 2)` then
`case (1, b: i32)` is useful and must stay silent (§4 negatives).

## 3. Slices

ONE slice (S). Order within the slice: (1) red goldens first — the
new `fail_` files land with AUTOUPDATE markers and empty CHECK lines
per R15, exercising every §4 positive shape against the CURRENT
toolchain (they compile clean today; the "red" is the review
expectation that they SHOULD diagnose); (2) the mechanism commit; (3)
runner autoupdate to fixpoint (R26 — new STDERR lines shift line
numbers, expect two passes); (4) ledger edits: W-066 notes rewritten
to landed form, W-078 filed (§1.5), and the stale
handle_match.cpp:121-123 TODO sentence ("Diagnose cases that can
never match") dropped from the file comment.

## 4. Testdata plan

All under toolchain/check/testdata/match/, autoupdated on the runner
only (R15/R16/R19/R26). Positive files (each shape diagnosed, error +
note both pinned):

-   `fail_case_never_matches_int.carbon`: exact duplicate literal
    (`case 5` / `case 5`); source-form-invisible duplicate (`case 5`
    then `case 2 + 3`); negative-value duplicate (`case -1` then
    `case -(1)`); a guarded later duplicate (`case 5` then
    `case 5 if (g)` — dead per §1.3's second half).
-   `fail_case_never_matches_tuple.carbon`: duplicate constant vector
    (`case (1, 2)` twice, non-literal tuple scrutinee — the W8a
    lesson: the literal shortcut hides bugs); subsumption by a prior
    mixed arm (`case (1, b: i32)` then `case (1, 2)`); nested-tuple
    duplicate (`case (1, (2, 3))` twice); subsumption with the
    wildcard on the other element (`case (a: i32, 2)` then
    `case (1, 2)`).
-   `fail_case_never_matches_alternative.carbon`: duplicate bare
    alternative (`case .Stop` twice); duplicate payload constant
    (`case .Ok(42)` twice); payload subsumption (`case .Ok(v: i32)`
    then `case .Ok(42)`); mixed payload subsumption
    (`case .Pair(1, b: i32)` then `case .Pair(1, 2)`).
-   `fail_case_never_matches_after_irrefutable.carbon`: `case n: i32`
    then `case 5`; `case var a: i32` then `case 1` (var-wrapper
    wildcard); choice scrutinee `case c: Signal` then `case .Stop`;
    an all-binding tuple arm then a constant tuple arm.

Negative file (`usefulness_no_false_positive.carbon`, non-fail —
proves silence, every fn compiles clean):

-   Guarded prior arm: `case 5 if (g)` then `case 5` — silent
    (§1.3).
-   Guarded `default` mid-list then a `case` repeating nothing —
    silent (guarded_default.carbon's landed shape, restated here as
    usefulness evidence).
-   Different constants: `case (1, 2)` then `case (1, 3)`;
    `.Ok(1)` then `.Ok(2)`; different alternatives with equal payload
    constants (`.Ok(42)` then `.Err2(42)`-shaped) — silent.
-   Specific-then-general: `case (1, 2)` then `case (1, b: i32)`;
    `.Only(7)` then `.Only(x: i32)` — silent (the asymmetry, §2.4).
-   `default` after an unguarded irrefutable arm, and `default`
    after full alternative coverage — SILENT, with a comment citing
    the §1.5 deferral, R8, and W-078. This is the fail_todo-style
    record for the deferred diagnostic (a `fail_todo_` file cannot
    pin the ABSENCE of a diagnostic, so the record is a commented
    negative golden plus the filed work item).
-   Prior ERROR arm (`case 5000000000` on i32, the
    fail_arm_conversion shape) then `case 5` — silent for the later
    arm (no sound key was recorded), belongs in a `fail_` subfile
    since the error arm itself diagnoses its conversion error.

Location check for every positive: the error's caret sits at the
arm's `case` introducer (matching the slice-gate TODO pin locations
and parse's `UnreachableMatchCase`), the note's at the covering arm's
introducer.

## 5. Conformance impact

Expected: NONE — the scoreboard stays **99 PASS / 0 FAIL / 28 SKIP
over 127**. Two claims, both checked against the tree at 869de65:

-   Diagnostics do not flip bullets: no conformance bullet asks for a
    usefulness diagnostic, so nothing moves to PASS.
-   No existing conformance program newly errors: every
    `match`-using program was scanned (grep over
    fork/conformance/programs for `case `/`default`); none contains a
    duplicate constant arm, a subsumed arm, or a `case` after an
    unguarded irrefutable arm. Nearest shapes, all silent under this
    plan: match_guard_diff.carbon and match_guard_binding.carbon
    (guarded binding arms then `default` — guarded priors excluded,
    `default` exempt), match_payload_literal.carbon (`.Some(42)` then
    `.Some(n: i32)` — specific-then-general, useful),
    match_guarded_default.carbon (guarded `default` mid-list, W-067's
    own program). One WATCH item: match_sum_type_payload.carbon's
    SKIP sketch (commented body) ends `case .None` + `default` —
    dead `default` territory for W-078, not this slice; noted in the
    W-078 filing so the un-SKIP agent is not surprised later.

## 6. Existing-goldens impact

Prediction: ZERO churn outside the new §4 files. Every near-miss in
toolchain/check/testdata/match/ was inventoried and adjudicated;
lower/testdata and parse/testdata contain no shape this diagnostic
can reach (lower tests reuse check-clean sources; the `?` desugar
builds the shared refutable SemIR core without the `match` parse
handlers, so `match_statement_stack` — and with it the accumulator —
is never touched there). The inventory, file by file:

-   `binding_pattern.carbon` — three fns end `default` after an
    unguarded irrefutable arm (`a: i32` / `5` then `b: i32` /
    `unused c: i32`): silent per §1.5. The `case 5` then
    `case b: i32` ordering is specific-then-general: useful.
-   `binding_choice_scrutinee.carbon` — `.Stop`, then `c: Signal`,
    then `default`: the binding arm is useful (`.Wait` etc. reach
    it); the `default` is §1.5-exempt.
-   `var_binding.carbon`, `ref_binding.carbon`,
    `fail_ref_binding_value_scrutinee.carbon`,
    `fail_binding_scope.carbon` — irrefutable arm then `default`
    only: §1.5-exempt.
-   `exhaustive_choice.carbon` — the :95-98 fn is `.Off`, `.On`,
    `default` on a two-alternative choice: a dead `default` by full
    coverage — §1.5-exempt (and W-078's first golden candidate).
-   `exhaustive_choice_binding.carbon` — irrefutable arm LAST: all
    arms useful.
-   `payload_subpattern.carbon` — `.Pair(1, 2)` then
    `.Pair(a: i32, b: i32)`, `.Ok(42) if (b)` then `.Ok(value)`,
    `.Only(7)` then `.Only(x)`: specific-then-general and
    guarded-prior shapes, all useful.
-   `choice_payload_guard.carbon`,
    `choice_generic_payload_pattern.carbon` (:84-87) — `.Ok/.Some
    guarded` then unguarded same-alternative: guarded priors
    excluded, useful.
-   `guard.carbon`, `fail_guard_sibling_binding.carbon` — guarded
    binding arms in sequence: guarded priors excluded, useful.
-   `guarded_default.carbon` — `case 1` after a guarded `default`:
    guarded arms block nothing (§1.3), useful; trailing guarded
    `default` after full coverage (:105-108): `default` exempt.
-   `tuple_pattern.carbon` — distinct vectors and
    general-in-different-position shapes (`(42, (x, y))` then
    `(n, (1, 2))`): pairwise useful.
-   `constant_expr_case.carbon` — `2 + 3` and `-(4 * 4)`: distinct
    values (5, -16), useful.
-   `constant_scrutinee.carbon` — `match (3) { case 3 ... }`:
    usefulness never consults the scrutinee's own constant value (no
    design mandate to), single case arm, silent.
-   `basic.carbon`, `converging_arms.carbon`, `nested.carbon`,
    `nested_choice_designator.carbon`, `negative_literal_case.carbon`,
    `default_only.carbon`, `empty_choice.carbon`,
    `single_alternative_choice.carbon`, choice scrutinee/import
    files, `choice_payload_multi.carbon`,
    `fail_arm_conversion.carbon` (error arms record nothing),
    `fail_error_payload_no_cascade.carbon`, `fail_todo_*` (checking
    aborts at the gate before or at the arm), remaining `fail_*` —
    distinct constants or single relevant arms throughout: silent.

If implementation contradicts any line above (a file newly
diagnosing), that is a FALSE POSITIVE to design away, not golden
churn to accept — §6 is the falsifiable claim both reviewers should
attack first.

## 7. Risks

-   **R-1 Int value canonicalization.** If `IntId` equality is not
    value-canonical across `Core.IntLiteral` and typed integer
    constants, keying on `IntId` under-reports (`case 5` vs a typed
    constant 5). Mitigation: the mixed-form duplicate golden (§4
    int file) is authored to force the question; fallback is APInt
    value comparison. Under-reporting is silent-but-sound (a missed
    diagnostic, not a wrong one); the golden decides.
-   **R-2 EqWith idealization.** RF-4 admits int-adapter-class
    constants whose `EqWith` could in principle not be value
    equality; the design's own model (:592-594) identifies an
    expression pattern with a single VALUE, and this plan follows
    it. A pathological non-value-equality `EqWith` would make a
    diagnosed-dead arm reachable at runtime. Accepted as the
    design's idealization (one-sentence justification per R17);
    revisit only if a design change sanctions such an impl for
    match dispatch. In practice, in-slice adapter constants that are
    not `EqWith`-compatible with the scrutinee already error at the
    comparison (error arm — no key).
-   **R-3 Key-walk / engine divergence.** The key builder is a
    second walk over shapes the engine accepted; a future
    pattern kind added to the engine but not the key walk would
    silently record nothing. Mitigation: the walk's default is
    conservative (no key, no diagnostic — never a false positive),
    and the plan's break conditions (§1.6, §1.7) name the widenings
    that must touch it. A CHECK is not appropriate: no-key must stay
    a soft path for exactly this forward-compatibility reason.
-   **R-4 Diagnose-and-continue plumbing.** The check must not
    disturb the arm's block structure (it runs before
    `AddDominatedBlockAndBranchIf` and emits no insts). Purely a
    diagnostic emission; if implementation finds itself wanting CFG
    edits, STOP and report (R17).
-   **R-5 New STDERR pins shift SemIR loc numbers** in the new files
    only — the standard R26 two-pass autoupdate; a structural pass-2
    diff means stop and diagnose.

## 8. Verification plan

-   Local, pre-push: `uvx prek run --files <changed>` (R22/R25);
    clang-format by way of the R12 hook.
-   Runner: golden autoupdate to fixpoint (R15/R26, two passes
    expected for the new fail files); `bazel test //toolchain/...`
    green; the R21 merge gate (upstream prek + clangd-tidy +
    build matrix).
-   Conformance: full run per R9; expected floor UNCHANGED at
    **99 PASS / 0 FAIL / 28 SKIP over 127** — any movement is a §5
    prediction failure and blocks the land pending diagnosis.
-   Goldens: zero diffs outside the new §4 files (the §6 claim); the
    reviewer verifies by diff inspection, per R16 no golden is ever
    hand-edited.
-   Process: two adversarial reviews of this plan, then the
    implement/review/fix loop per R11; ledger edits (§3 step 4) land
    with the slice.

## 9. Open questions for reviewers (recorded calls, veto-able)

-   **OQ-1:** §1.5's blanket `default` exemption vs a narrower one
    (diagnose dead `default` on CHOICE scrutinees only, where R8
    does not force it). Recorded call: blanket exemption — one rule,
    no scrutinee-kind fork in the exemption, and the choice-side
    dead `default` (exhaustive_choice.carbon:95-98 churn) rides
    W-078 with the integer side. A veto splits W-078.
-   **OQ-2:** record dead arms' keys into the accumulator or not
    (§2.3 step 4). Recorded call: do not record — subsumed keys add
    no coverage and first-covering-arm notes stay stable. A veto is
    behavior-invisible except in multi-dead-arm note targets.
-   **OQ-3:** diagnostic names/wording (§2.3). `MatchCaseNeverMatches`
    aligns with the design's phrase; `MatchCaseNotUseful` would align
    with the design's TERM. Recorded call: NeverMatches — user-facing
    text should say what happens, not name the analysis.
-   **OQ-4:** should the W-078 filing also absorb the R8 lift's
    other half (integer exhaustiveness by way of irrefutable arm,
    fail_todo_no_default.carbon:48's recorded conservative gate)?
    Recorded call: yes, one item — they are the same gate viewed
    from two sides, and landing either alone re-creates the §1.5
    contradiction in one direction or the other.
