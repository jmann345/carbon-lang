# Decision log

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

Every design fork — a point where the user chose among researched options —
is recorded here. Format: context, options considered, decision, date,
consequences. Undecided forks are listed as OPEN at the top.

## OPEN forks

-   None. SF-9 (identity of the existing `Core.Optional` class, recorded OPEN
    2026-08-08) was decided 2026-09-27 by D-EH-1 — see "EH-A: Core.Result,
    Optional as Try, Result entry points" under Decided, which carries the
    former OPEN entry verbatim.

## Decided

### V-1..3: viability-review decisions (user by way of AskUserQuestion, 2026-07-20)

**V-1: fork-0.1 targets Linux/macOS** — F-001 amended; Windows recorded
as post-0.1 (XL item stays visible in the gap analysis and inventory).
**V-2: veto-digest model replaces always-ask** — synchronous
AskUserQuestion rounds only for genuine forks (design divergence, scope
trades, north-star tension); mundane sub-decisions auto-adopt the
recommendation and appear in a per-merge veto digest the user can
overturn (overturned items get reworked before the next merge).
**V-3 (as amended by V-3a, 2026-07-20): upstream alignment as veto
criterion, not permission gate** — decisions that CONTRADICT upstream's
accepted proposals or recorded leads' direction are vetoed; where
upstream is ambiguous or silent, creative fork design is permitted and
progress must not slow to await upstream signals; upstream intent is the
default preference, overridable with stated good reason. Ratified designs
F-006..F-011 stand (audit: each was already the lowest-divergence option;
none contradicts an accepted proposal), but genuinely fork-local
spellings (for example F-006a Ok/Err vs the README's illustrative
Success/Failure) enter a divergence-risk register reviewed at each
upstream merge.

### B0 SF-1..5: exception-boundary implementation sub-forks (user by way of AskUserQuestion, 2026-07-20)

Fence = noexcept exception-spec on the thunk type; boundary-identifying
diagnostic recorded as a B3 follow-up (1); explicit mode wins over user
clang args, appended last, justified as a boundary contract not a tuning
default (2); flag on `carbon compile` only for B0 (3); auto resolves from
Clang's final LangOpts, not arg-string scanning (4); the exception-interop
bullet flips PASS on B0's boundary-contract slice with this recorded
scope trade — catching-into-Result stays a visible SKIP until B3 (5).

### W5-S1: scope trades in choice-payload slice 1 (2026-07-19)

Process/scope decisions made by Claude during S1 implementation under
standing rule 6 (language semantics follow docs/design/sum_types.md and the
ratified SF-1..8 outcomes unchanged); recorded per process step 4 so the user
can overrule. Also records, per plan §0.3, that the `Match`
interface/Continuation mechanism of sum_types.md:124-246 (user-defined sum
types) is OUT of the whole W5 workstream — S1 match consumption is direct
discriminant dispatch only.

-   **Scalar-only payload gate.** SF-6's "trivially copyable + trivially
    destructible" restriction is implemented as an over-restrictive structural
    allowlist: integer/float/bool/pointer types and adapters over them
    (`IsInSlicePayloadType`, handle_choice.cpp). Trivially-copyable aggregates
    (struct/tuple payload params) are also rejected, with the same SF-6
    contract diagnostic. Rationale: the allowlist is a type property that fails
    safe (match-gate soundness, plan risk R-4) and avoids relying on
    aggregate-copy machinery S1 does not exercise. Relaxation rides SF-6's
    recorded post-0.1 work item. **Admitted exception**: the gate does not
    query Destroy/Copy witnesses, so a user adapter over a scalar carrying its
    own `Core.Destroy` impl passes it despite not being trivially destructible.
    Harmless today only because destroy-op synthesis is a placeholder no-op
    (custom_witness.cpp `MakeDestroyOpBody`); when destroy synthesis lands, the
    gate must become a destroy-witness triviality check. Recorded here, not
    silently accepted, so the user can overrule.
-   **Alternatives with parameter lists in generic choices** (including
    zero-payload `Alt()`) are gated to the generic/Self-dependent TODO string —
    SF-3's function-like `Alt()` lands for non-generic choices only; generic
    synthesis is S3's re-plan.
-   **Choices with fewer than two alternatives are not matchable in S1**: their
    discriminant is the empty tuple, so they stay behind the widened scrutinee
    TODO (`match on unsupported scrutinee type`). There is nothing to dispatch
    on; S2's exhaustiveness work is the natural place to admit them.
    _S2e landing note (2026-08-08):_ NOT admitted at S2e. Plan §3.5
    sanctions only the `MatchStatement` exhaustiveness analysis; admitting
    an empty-tuple discriminant is scrutinee-gate + dispatch work (a
    single-alternative match needs a no-test always-taken arm, an empty
    choice a vacuous zero-arm match), so both stay behind the scrutinee
    string, now pinned by match/fail_todo_single_alternative_choice.carbon
    and tracked as work item W-068.
    _W-068 landing note (2026-08-18):_ lifted — both shapes are admitted
    at the scrutinee gate (`IsMatchableChoiceType`), with constant-true
    dispatch and the empty-choice lane scoped to type admission under
    parse's at-least-one-arm rule; the fail_todo pin flipped (git mv) to
    match/single_alternative_choice.carbon. See the W-068 landing note
    below.
-   **Specifics of generic choices are not matchable in S1** (`choice P(T:
    type) { A, B }` matched as a `P(i32)` value): they also stay behind
    `match on unsupported scrutinee type`. Plan §2.2c scopes alternative
    name→index metadata to concrete choices, and admitting the
    specific-resolved constant path untested would trade a diagnostic for a
    potential compiler crash; S3's generic re-plan owns it.
    _S3a landing note (2026-08-08):_ lifted for payload-free generic
    choices — specifics (concrete and symbolic) now dispatch and are
    covered by SF-7 exhaustiveness; see the W5-S3a landing note below.
-   **Matching a zero-payload function-like alternative (`case .On` for
    `On()`) is gated by the `match case pattern destructuring a choice
    payload` TODO string**, although there is no payload to destructure: the
    designator resolves to the alternative's constructor function, and S1
    keeps every function-typed alternative pattern behind S2's
    destructuring work. SF-3's ratification text covers construction only;
    the string choice is recorded here so R10 SKIP quoting stays consistent.
    In S1 such alternatives are observable through `default`-arm inversion.
    _S2c landing note (2026-07-28):_ superseded — `.On()` now matches per
    SF-3; bare `.On` diagnoses MissingParens (see the S2c note).
-   **Guarded designator patterns** (`case .Err if (...)`) keep W4's generic
    pattern/guard TODO string, not the payload-destructuring string.
    _S2a landing note (2026-07-28):_ the match re-platform's RF-3 co-change
    (fork/match-replatform/plan.md §6) supersedes this: guard nodes are now
    reached by checking, and every guard — on any pattern — is diagnosed at
    the guard's `if` token with the single string
    `` `match case guard` ``. Patterns whose own gate fires first (for
    example a binding in `case a: i32 if (...)`) still emit their pattern
    TODO at the `case` token before the guard nodes are reached. A further
    recorded deviation class from the same landing: pattern-expression
    diagnostics now surface before or instead of the slice-gate TODOs for
    non-golden-pinned inputs (inherent to plan §2.1's re-route of pattern
    nodes through their ordinary handlers) — for example `case undeclared` adds a
    real name-not-found before the TODO; `case .Err == .Stop` and the like
    produce expression errors instead of the payload TODO; `case (.Err)`
    loses the TODO entirely (the tuple wrapper masks the introducer peek;
    the error-typed pattern continues with real `.Self`-scope errors).
    Disposition: recorded as more-honest diagnostics rather than gated —
    adding lookahead to preserve blanket TODOs on unpinned inputs would
    reintroduce the sniffing this slice removes (R17). No golden or SKIP
    evidence pins any affected input (verified by reviewer #1). Veto-able.
    Relatedly, the binding-root gate lives in the binding handlers rather
    than in `MatchCase` classification as the plan sketched, because
    binding nodes check before `MatchCase` — same string and location,
    forced by traversal order.
-   **The `default` arm stays required** for choice matches in S1 (SF-7's
    exhaustiveness lands in S2), so every S1 conformance/testdata match carries
    `default`.
    _Discharged at S2e (2026-08-08): exhaustive choice matches no longer
    require `default`; integer matches still do (see the S2e note)._
-   **Reconstruction-landing addendum (2026-07-27):** the first full CI run
    of S1 exposed and fixed six defects across five fix rounds:
    generated-constructor FunctionDecl loc; match discriminant lookup (plan
    §2.2c's "constant imports with the binding" premise was wrong, see the
    amendment there); TypeIterator missing CustomLayoutType;
    alternative-param names leaking into the choice scope
    (NameDeclDuplicate across alternatives); constructor ClassInit elements
    built with InitializeExisting against its documented contract (by-copy
    discriminant crashed lowering AND the Small payload store was silently
    dropped — now InPlaceInitializing per upstream's aggregate discipline);
    and review-found F1, a zero-param `Alt()` in a payload-carrying choice
    producing a 1-element ClassInit against a 2-field repr (now filled with
    an uninit payload element mirroring convert.cpp's ChoicePayload case,
    covered by the new mixed_payload_alternatives testdata). Adversarial review passed both semantic fixes with no
    landing blockers and these recorded follow-ups: (1) DONE
    (claude/carbon-fork-0-1-followups): the defense-in-depth fallback at the
    choice-case pattern now emits `match case pattern on unsupported choice
    alternative shape` instead of the scrutinee string, which stays on the
    scrutinee gate only; (2) when §2.2c name-to-index metadata lands for S2
    exhaustiveness, replace `GetAlternativeDiscriminant`'s constant
    excavation with it; (3) optional comment that CustomLayoutType's
    type-structure fingerprint conflates with a same-shaped StructType
    (filter/ordering-only today); (4) DONE (claude/carbon-fork-0-1-followups):
    match/choice_scrutinee_reexported.carbon pins the
    GetCanonicalFileAndInstId multi-hop path through an `export import`
    relay library; (5) DONE (claude/carbon-fork-0-1-followups): duplicate
    alternative NAMES (`choice C { A, A }`, distinct from the fixed param
    collision) no longer CHECK-crash in NameScope::AddRequired —
    handle_choice.cpp diagnoses NameDeclDuplicate/NameDeclPrevious before
    registration and drops the duplicate (references resolve to the first
    alternative), with choice/fail_duplicate_alternative.carbon covering
    constant/constant, constant/function, and function/constant orders. Also
    landed on that branch: the review F-A1 OneShot single-payload-alternative
    testdata (check+lower) pinning the zero-bit-()-discriminant +
    payload-region constructor shape.

_W5-S3a landing note (2026-08-08):_ the first slice of the approved
generic-choice plan (fork/w5-s3/plan.md §3 S3a) lifts the W5-S1
specifics-as-scrutinees gate for PAYLOAD-FREE generic choices, end-to-end.
_Mechanism (plan §2.1 Option B, two coordinated changes):_ (1) the
un-stringed `specific_id.has_value()` clause in `GetChoiceDiscriminantType`
(pattern_match.cpp) is deleted — every downstream consumer already resolves
the object representation through `class_type->specific_id`
(`Class::GetObjectRepr`), so discriminant and payload types arrive
substituted; (2) the `MatchCondition` scrutinee gate now FORCES that
resolution — `RequireCompleteType` on the scrutinee type runs before any
repr read, so the match itself is the forcing use (the completer's
`ClassType` case runs `ResolveSpecificDefinition`) and the handle_match
soundness comment's payload restriction holds BY CONSTRUCTION regardless of
which path produced the scrutinee value (§2.6; the value-producing-path
audit would fail — pointer deref and import complete nothing, risk R-2).
Symbolic scrutinee types defer to monomorphization through a
`require_complete_type` witness, which also admits SYMBOLIC specifics
(`x: P(T)` matched inside `fn F(T:! type, ...)`) — risk R-8's recorded
scope-in, sound at S3a because a payload-free choice's representation
witness is concrete; instability here narrows the scope-in (re-gate behind
the TODO), not the slice (plan R-8). _S3a implementation sub-decision
(veto-able):_
`RequireCompleteType` requires a diagnostic-context callback, which the plan
did not spell; authored here as the Context-severity
`IncompleteTypeInMatchScrutinee` (`matching on value of incomplete type
{0}`, the member-access precedent's shape). Consequence: a genuinely
incomplete concrete scrutinee type (for example matching a dereferenced
pointer to a forward-declared class) now gets a real incomplete-type error
instead of the scrutinee TODO, and the handler aborts exactly as the TODO
path does; no golden pinned that input. _TODO ledger (plan §6):_ the
`` `match on unsupported scrutinee type` `` string survives byte-identical
at its site; no pin moves (the gate was unpinned, plan §1's finding) — the
new goldens add the positive pins directly, plus the W-068 composition pins
(single-alternative and empty-choice SPECIFICS keep the scrutinee TODO by
way of the non-integer-discriminant check) and the S3a partial-table window
pin: a MIXED generic choice's parameterized alternative still carries the
definition TODO and no table row, so a specific's match covering only the
constant alternatives passes exhaustiveness IN SILENCE
(fail_todo_mixed_partial_table subfile; S3b populates the rows and closes
the window — plan §2.5 i. SUPERSEDED at the S3b landing, 2026-08-08: the
window is CLOSED — the subfile is now fail_mixed_table_closed, pinning the
MatchNonexhaustive diagnostic that names the uncovered payload
alternative). _Byte-equivalence (plan §4):_ concrete-choice
and integer matches take byte-identical paths — the deleted clause is
unreachable for `specific_id == None` and the forced completion is a no-op
for already-complete concrete types; expected golden churn is NEW FILES
ONLY (match/choice_generic_scrutinee.carbon: positive
basic/two-specifics/symbolic-specific/imported-pair subfiles + the R-5
one-file exhaustive-beside-nonexhaustive pin naming the missing alternative
per specific + the fail pins above; lower/match/choice_generic_scrutinee
pinning discriminant dispatch and construction on a specific), CHECK
content riding the runner autoupdate (R15/R19), STDERR pins hand-written.
_Conformance:_ NEW types/choice_generic_roundtrip.carbon (two specifics
constructed and matched at runtime, exhaustive matches without `default`,
runtime-selected alternatives per R16d) — PASS floor 77 → 78 over 109
programs, README table regenerated, scoreboard regeneration rides the
landing gate (R9); no existing SKIP quotes the lifted gate (plan §8), so
none flips. _Bookkeeping:_ SF-9 recorded as OPEN per plan §0.2's landing
obligation (see the OPEN forks section); W-010's generic residue narrows to
payload synthesis (S3b) + destructuring on specifics (S3c). Veto-able.

_S3a crash-fix addendum (2026-08-08, post-first-CI-cycle):_ the slice's
first CI cycle surfaced two defects the no-local-bazel review could not
execute. (1) SIGSEGV: a generic choice's eval block holds a
`require_complete_type` of the choice's own type (its body converts
alternative constants to symbolic `Self`), and
`ResolveSpecificDefinition` had no in-progress guard — completing
`Pair(i32)` re-entered its own resolution unboundedly. Fixed by a
placeholder guard mirroring `ResolveSpecificDecl`, a loud bounds
CHECK in `GetConstantInSpecific` (was an unchecked opt-mode read), and
`LookupMemberNameInScope` attaching the scope's specific to a
`WrapperBinding`'s symbolic bound value (it was silently dropped;
`P(i32).B` would have failed lowering). One fresh-context adversarial
review, five lanes, no blocker; residual for S3b recorded in the plan
(symbolic witness during the placeholder window hits the new CHECK).
(2) R17 catch by the gate's `fail_`-prefix invariant: the
symbolic-specific testdata split was authored with the retired `:!`
binding syntax, so it PARSED WITH ERRORS and never exercised the
symbolic path — autoupdate faithfully pinned the error goldens and only
the gate refused. Re-authored to the current bracket-list form
(`fn F[T: type](x: P(T))`, `T` deduced at the call); its regenerated
goldens are the symbolic path's first real execution, so the
"symbolic specifics" exit claim rests on that run, not on the earlier
review tracing alone.

_W5-S3b landing note (2026-08-08):_ the risk slice of the approved
generic-choice plan (fork/w5-s3/plan.md §3 S3b) lands payload synthesis in
generic choices end-to-end. _Mechanism (plan §2.2-§2.5):_ the
handle_choice.cpp definition gate lifts — symbolic payload types proceed
to synthesis (concrete payloads inside generic choices validate SF-6 at
the definition; `TypeContainsChoice` keeps a definition-time gate with the
narrowed string `` `choice alternative payload with Self-dependent
type` ``, the §6 co-change); the payload region's `CustomLayoutType` is
emitted with the zero-alignment dependent-layout sentinel and recomputed
per specific by the now-reachable `EvalConstantInst` hook (constant kind
flipped to `Conditional` + `DuringEvaluation`), which completes the
substituted payload tuples, runs SF-6 per specific (the plan-authored
`ChoicePayloadNotTrivialInSpecific` diagnostic at the forcing use), and
rebuilds the layout by max-of-fields (F-007k); alternative constructors of
a generic choice are themselves generic (`MakeGeneratedFunctionDecl` gains
the pre-committed `build_generic` bracketing — the member-function
precedent sufficed, so plan R-3's revision trigger did not fire); and the
alternative table now carries parameterized rows, closing the S3a
partial-table silence window (choice_generic_scrutinee.carbon's subfile is
now fail_mixed_table_closed, pinning MatchNonexhaustive naming the
uncovered payload alternative — see the superseded S3a sentence above).
_Guard redesign (veto-able sub-decision):_ S3a's `InstBlockId::Empty`
placeholder in `ResolveSpecificDefinition` — and its "the in-progress
region must not be queried" discipline — is REPLACED by incremental
publication: the definition value block is pre-sized to the eval block
(every entry `None`) and published on the specific BEFORE evaluation, and
`TryEvalBlockForSpecific` writes each value in as it is evaluated, so the
nested completion that recursion produces (the choice's own
`require_complete_type`, whose completion reads the class's complete-type
witness — under S3b a recomputed, symbolic-at-definition constant, exactly
the S3a-recorded residual) legally reads already-evaluated PREFIX entries,
while a genuine forward reference reads `None` and dies on a loud
per-entry `has_value` CARBON_CHECK in `GetConstantInSpecific`
(sem_ir/generic.cpp) instead of silently yielding a wrong constant.
Consequence: the pre-allocation shifts inst-block allocation order, so
raw_sem_ir dump goldens renumber InstBlockIds with contents unchanged.
_Plan amendments (in-slice, house rule — reality diverged):_ §4 now
budgets the ID-only raw_sem_ir renumbering and states the reconciliation
rule (churn beyond pure renumbering, or outside those dumps plus the §6
flips and new files, is stop-and-explain); the §S3b residual paragraph is
rewritten to the landed incremental-publication mechanism; §8's floor
arithmetic is reconciled (pre-S3b floor 79/0/31 over 110 — the
exception-interop pair and S3a landed after the plan was written; S3b
target 80/0/31 over 111; S3c shifts to 81/112); §5 R-1's falsifier numbers
re-derive for the landed `Pair(T: type) { Both(x: T, y: T), Neither }`
artifact (8 bytes/align 4 vs 16 bytes/align 8; the 4-byte single-payload
case rides the optional subfile's `[4 x i8]`). _Fixer round (two
adversarial reviews):_ (1) conformance pair strengthened — the runtime
size-collision claim was unarbitrable as written (with field order
{.discriminant, .payload} any corrupted discriminant fell to `default`,
reproducing the expected output), so the i64 side adds a runtime-computed
COLLISION probe (seed-derived 257, low byte 1 == `None`'s discriminant)
whose probed index flips under a discriminant/payload collision,
`Some(64)` became runtime-computed (making the R16d claim true), and the
header comment now claims only what the program arbitrates — constructor
synthesis, dispatch, and the collision probe; layout numbers (size AND
alignment) are pinned by the lower goldens. (2) Hardening
(crash-not-diagnostic): mutual by-value generic recursion (`choice
P(T: type) { A(x: G(T)) }` with `class G(T: type) { var p: P(T); }`)
would recurse from the hook's payload-tuple completion back into the
specific's own in-progress resolution and die on the forward-reference
CHECK; the hook now runs a structural SF-6 pre-filter BEFORE each
completion — kinds classifiable without completeness (defined non-adapter
classes, every non-class kind) reject with the real diagnostic; adapters
and undefined classes still defer to completion — pinned by
fail_generic_payload.carbon's fail_mutual_by_value_recursion subfile; the
hook's completion also gained the plan-specified
`Diagnostics::ContextScope` (IncompleteTypeInMonomorphization, the
RequireCompleteType-hook precedent). (3) Newly-reachable surface: payload
DESTRUCTURING on a concrete specific (`case .Some(v: i32)` on `Opt(i32)`)
became reachable with the table population and traces to WORKING —
`GetChoicePayloadInfo` resolves the payload tuple through
`class_type->specific_id` at both the case check and the bind pass —
pinned by new destructure subfiles (check + lower
choice/generic_payload.carbon); S3c keeps symbolic destructuring,
substituted binding conversions, imported pairs, and the doc example.
_Byte-equivalence (plan §4 as amended):_ concrete choices and
C++-imported class layouts pass through the eval hook unchanged (nonzero
alignment word); expected churn is the §6 flips, the new files, and the
ID-only raw_sem_ir renumbering. _Conformance:_ NEW
types/choice_generic_diff pair (DIFF-1: C++ `std::variant<T,
std::monostate>` oracle, no EXPECT-STDOUT, the `.None`/monostate arm
probed explicitly) — PASS floor 79 → 80 over 111; runner --self-test
green; README table regenerated; scoreboard regeneration rides the
landing gate (R9). _Bookkeeping:_ the S3a partial-table sentence above and
W-010's inventory entry are superseded/updated in place (payload synthesis
landed; destructuring remains S3c); stale W-010 evidence references
(renamed testdata, drifted line numbers) refreshed. Veto-able.

_S3b landing addendum — the five CI cycles (2026-08-08):_ the slice
needed five autoupdate cycles to land, each defect root-caused by a
dedicated fixer round before the next push (branch commits are the
audit trail). (1) The definition path asserted on payload tuples naming
forward-declared class specifics — now a real diagnostic
(`IncompleteTypeInChoicePayload`, class-field precedent). (2) The import
resolver had no `UninitializedValue` case for the exported constant
alternatives' struct values — mechanical case added. (3) A PRE-EXISTING
fork bug, first exercised here: the `CustomLayoutType` import resolver
minted its blocks non-canonically, so one exported constant resolved to
two local constants and broke the eval-block rebuild invariant —
`AddCanonical` on import and recompute paths. (4) The constructor
wiring was semantically broken two ways (Convert demanded `Core.Copy`
on symbolic `T` at definition; the canonical return-type inst never
substituted through specifics) — reworked to raw per-element
initialization (SF-6 is the correctness argument) plus a
region-attached return type; the rework's own review caught a P0
miscompile (the folded `ClassInit`'s cover memcpy clobbering the
element stores at the return) — fixed by `UpdateInit` sequencing,
golden-pinned cover-then-stores. (5) Imported choice-alternative
bindings arrived value-less (upstream's let-import TODO), crashing
cross-file `case` lowering — the resolver now propagates the bound
value's constant. _Consequences beyond the slice (veto-able):_ imported
`let` bindings tree-wide now carry their bound constants (four upstream
`let/` goldens improved; two upstream `fail_*.impl.carbon` splits whose
own comments asked "Should this be valid?" now pass and were renamed);
W-069 records the remaining cross-file RUNTIME-let gap, and the R-2
split's binding moved to the importing file (a `var` cannot initialize
from an alternative constant — choice types implement no `Core.Copy`).
Veto-able.

_W5-S3c landing note (2026-08-08):_ the closing slice of the approved
generic-choice plan (fork/w5-s3/plan.md §3 S3c) — payload destructuring
on specifics plus the sum_types.md example — landed as pure
verification-and-pinning: NO toolchain code changed; the surface S3b
built carries every S3c shape. _Trace verdicts (the two questions the
plan left open, both resolved POSITIVE, so no fail_ pins were needed):_
(1) the R-8 symbolic destructure — `fn F[T: type](p: P(T))` matching
`case .Both(a: T, b: T)` — WORKS: the scrutinee gate's forced completion
runs the type completer even for a symbolic scrutinee
(`RequireCompleteType` completes before its `is_symbolic` check,
type_completion.cpp:884-886), the completer's `ClassType` case resolves
the symbolic specific's definition (type_completion.cpp:481-483,
`ResolveSpecificDefinition` on the specific with symbolic arguments), and
from there `GetChoicePayloadInfo`'s reads are purely structural on the
substituted symbolic constants (sentinel `CustomLayoutType`, `(T, T)`
tuple) — no size is read — while the payload bindings bind `T` values
without copying (`let`-binding semantics; unconstrained `T` has no
`Core.Copy`, so the goldens deliberately avoid returning or
`var`-initializing from them); (2) R-7 substituted binding conversion —
`case .Some(v: i64)` on an `Opt(i32)` scrutinee — WORKS: the specific's
payload tuple is fully concrete by the bind pass, so the per-element
conversion rides S2c's exact `DeferCleanups` shape
(choice_payload_multi.carbon precedent). _Pins:_ NEW check golden
match/choice_generic_payload_pattern.carbon — multi-parameter payloads on
two specifics, a guarded destructuring arm (S2d composing with the S3b
table), the R-7 conversion, an imported-generic pair (plib convention),
the R-8 symbolic subfile, every positive match exhaustive without
`default` (S2e's coverage records a destructuring arm by ALTERNATIVE
index, handle_match.cpp's `MatchCase` recording — verified, pattern-shape
independent), and a fail_nonexhaustive_payload subfile (destructuring arm
covers only its own alternative; MatchNonexhaustive names `.Neither`);
NEW lower golden match/choice_generic_payload_pattern.carbon under the
plan's only-if-new clause — per-specific ELEMENT offsets (second payload
element at byte 4 in `Pair(i32)`'s `[8 x i8]` vs byte 8 in `Pair(i64)`'s
`[16 x i8]`) and the instantiated symbolic-body destructure, neither
pinned by S3b's single-element lower subfile. _Doc example
(S2e deviation (2) discharged):_ NEW conformance pair
control_flow/choice_generic_roundtrip_diff.carbon / .diff.cpp
(std::optional oracle, DIFF-1) runs the sum_types.md example —
declaration (63-66) and match (81-88, no `default`) VERBATIM, I/O
adapted per rulebook R1 — with ONE construction adaptation, recorded as
a plan amendment rather than discovered-at-review: sum_types.md:74's
`var ... = Optional(i32).None` cannot compile (initializing a `var`
from a class value copies, and choices implement no `Core.Copy` — the
S1-recorded gap), so the None value binds with `let` while
sum_types.md:75's re-assignment (`my_opt = Optional(i32).Some(42);`)
runs SHAPE-verbatim on a `var` initialized in place — the payload
argument is runtime-computed per R16d — (the rhs is an
in-place-initializing constructor call; `InitializeExisting` + the
`Assign` lowering, a no-op for an in-place-initializing rhs, need no
copy). One further honest bound: the doc's None→Some transition on the
SAME variable is not exercised (assigning `.None` is also a value copy
through the same path), so the arbitrated transition is Some→Some,
the closest achievable. Payloads are runtime-computed
(R16d, 22 + 20 = 42), the re-assignment is arbitrated (a failed
overwrite leaves the initial payload visible), and the i64 side carries
the collision payload (257, low byte 1) into payload READBACK. Floor per
the §8 amendment: 81 PASS / 0 FAIL / 31 SKIP over 112; runner
--self-test green; README table regenerated; scoreboard regeneration
rides the landing gate (R9). _Bookkeeping:_ plan §3 S3c amended in-slice
(the dated 2026-08-08 clause: the construction-verbatim narrowing and
both trace verdicts); W-010's generic residue closed and W-011's choice
half updated in fork/inventory/work-items.json. Veto-able.

### W5 SF-1..8: choice-payload plan sub-forks (user by way of AskUserQuestion, 2026-07-20)

Hybrid struct representation — discriminant + CustomLayoutType payload
region; payload-free choices untouched (SF-1); bit-minimal discriminant
kept, export may revisit behind a repr version (SF-2); zero-payload
`Alt()` function-like alternatives in slice 1 (SF-3); leading-dot
patterns only, qualified form a recorded work item (SF-4); bare
`name: type` bindings per the design doc (SF-5); trivially-copyable +
trivially-destructible payloads only in 0.1, clean diagnostic, deviation
from the unions.md contract text recorded as post-0.1 work (SF-6);
exhaustive choice matches need no `default` — the closed-set case lands
in slice 2, W4's rule stays for integer matches (SF-7 — _discharged at
the match re-platform's S2e, 2026-08-08: choice matches get real
coverage analysis and integer matches keep the requirement; see the S2e
landing note_); std::variant
mapping DEFERRED to S4 planning WITH the user's steer: tagged unions are
the first-class construct (`choice`), any Core.Variant prelude name would
be sugar over a generic choice at most, and the default lean is the
anonymous/synthesized-choice mapping — introducing a Variant vocabulary
type requires affirmative justification at the S4 fork (SF-8).

### DIFF-1..4: differential-harness sub-decisions (user by way of AskUserQuestion, 2026-07-19)

Differential programs use the C++ oracle only, no EXPECT-STDOUT (1);
C++-side failures report as DIFF-MISMATCH with detail, no separate status
(2); commit 837bb60's conflation fixed by an empty record commit, no
history rewrite (3); the conformance README program table is
auto-generated by `runner.py --update-readme-table` with a `--self-test`
staleness gate (4).

### F-006: Error handling — **Result + postfix `?` by way of Core.Try** (2026-07-19)

**Sub-decision F-006a (user, 2026-07-19): variant naming is `Ok`/`Err`**,
overriding the design README's older Success/Failure spelling; docs and
prelude code use `Core.Result(T, E)` with alternatives `Ok(T)` / `Err(E)`.

**Sub-decisions F-006b..l (user by way of AskUserQuestion, 2026-07-19), all per
doc recommendation:** `?` in the suffix-operator precedence group,
repeatable (b); ImplicitAs-only error conversion, no dedicated trait (c);
`?` requires a declared Core.Try-implementing return type — no
auto-return, file scope, or global initializers (d); `--cpp-exceptions`
defaults to `auto` (e); fenced std::terminate at unfenced boundaries (f);
Cpp.Exception stores exception_ptr only with lazy str accessors and
lossless rethrow (g); export ships the Carbon::expected<T,E> header only,
no generated throwing wrappers (h); Optional implements Try but no
implicit Optional/Result bridge (i); entry points: (), i32,
Result((),E), Result(i32,E) with Err → stderr + exit 1 (j); try-blocks
and catch-expressions deferred past 0.1 (k); Carbon aborts terminate
without unwinding C++ frames (l).

Staged B0-B3 per fork/design-sprint/error-handling.md: B0 `--cpp-exceptions`
flag + fenced terminate-at-boundary thunks (zero deps, replaces today's UB);
B1 Core.Result + match (after W4/W5); B2 postfix `?` through an open
Core.Try interface with ImplicitAs error conversion; B3 catching thunks
importing throwing C++ as Result(T, Cpp.Exception) + Carbon::expected
export. Rejected: library-only (fails the milestone bullet), declared
fallibility (2-3x cost, collides with if-let), native exceptions
(contradicts p000301, XL lowering).

_B1 landing note (2026-08-08):_ both slices of the approved B1 plan
(fork/b1/plan.md — process step 6, two adversarial plan-review rounds with
the 2026-08-08 revisions folded in, coordinator sign-off on the eight-item
V-2 veto digest) are landed: B1a (postfix `?` parse in the postfix loop +
the gated check TODO) and B1b (`Core.Try` + the desugar + conformance).
_The restaging (digest item 1):_ this B1 = the F-006 `?`/`Core.Try`
machinery over USER-DEFINED generic choices; prelude
`Core.Result`/`Core.Optional` and the entry-point `Result` signatures move
to W5-S3p behind OPEN SF-9 — the F-006 staging table carries the dated
amendment. _The carrier (digest item 2, option B):_ `Branch` returns the
NEW prelude choice `Core.ControlFlow(C, B)` (core/prelude/try.carbon,
library "prelude/try", export-imported from the prelude; alternatives
`Continue(value: C)`/`Break(value: B)` in that order, fixing discriminants
Continue=0/Break=1 that the desugar's test and the goldens hard-depend on).
_V-3a divergence-risk register entries (reviewed at each upstream merge):_
(i) the name `Core.ControlFlow` — a fork-authored prelude name landed
pre-SF-9; Rust's `Try` shape is the stated good reason; reversible pre-S3p
(only B1 testdata and one conformance program name it); (ii) the parameter
order `ControlFlow(C, B)` — continue-first, matching `Try`'s
`(ContinueType, BreakType)` reading, a DELIBERATE divergence from Rust's
break-first `ControlFlow<B, C>`; (iii) the member spellings
`Try`/`Branch`/`FromBreak`/`Continue`/`Break` (with F-006a's `Ok`/`Err`
already on the register). _Mechanism (plan §2.4 as revised):_ the desugar
(new toolchain/check/handle_question.cpp) emits only existing inst kinds —
pre-flight (QuestionOutsideFunction; region-depth>1 →
QuestionInPatternContext, digest item 3's diagnose-and-reject policy, by way of
the new RegionStack::depth()/ArrayStack::size() accessors;
QuestionNoDeclaredReturnType; QuestionNonInitReturnForm;
QuestionInReturnedVarScope (added at the same-day B1b fix round — a
`returned var` in scope is rejected up front, before the break path could
reach `BuildReturnWithExpr`'s ReturnExprWithReturnedVar mid-desugar; seven
`?` diagnostics total); the discarded scratch-block `LookupImplWitness`
pre-flight → QuestionReturnTypeNotTry, the A-1 correction, bracketed by a
fresh `GenericId::None` generic region per the DeduceImplArguments
precedent so dropped lookup insts never register in an enclosing generic's
eval region), then Branch by way of `BuildUnaryOperator` with the
QuestionOperandNotTry context hook, the exported
`EmitChoiceDiscriminantTest` against Break's discriminant, reference-
projection payload extraction, `FromBreak` resolved by compound access on
the return type with the argument conversion as the D3 ImplicitAs error
conversion, and `BuildReturnWithExpr`'s whole-function cleanup discharge on
the exclusive break edge. return.cpp's note helpers
(NoteReturnType/NoteNoReturnTypeProvided/new NoteReturnForm) are exported
for the §2.5 diagnostics. _As-landed deviations, dated in the plan:_ the
fail goldens split in two (fail_question_preflight.carbon on the NEW
min_prelude/try combo — proving the pre-flight fires before the
EqWith-needing discriminant test — plus fail_question.carbon on the full
prelude), and §2.3's type-position sub-decision is amended: binding-type-
annotation positions take the region-policy rejection (the annotation IS a
captured region), depth-1 type operands keep the missing-impl rejection.
Second fix round, same day: reachability analysis does not consult match
exhaustiveness (the S3a/S3c convention), so every match-reconstruct body
ends with an unreachable trailing return — a dead constructible value in
concrete contexts, and in generic bodies (where no carrier value is
conjurable) a diverging idiom — per plan §2.6's dated trailing-return
amendment; the doc's impl sketches carry the same amendment. Third fix
round, same day, two regen-surfaced defects: (1) the second round's
generic idiom — the interface-recursive `return
self.(Core.Try.Branch)();` — is SUPERSEDED: it does not type-check,
because the recursive call's return type carries associated-constant
projections (`ControlFlow(MyResult(T, E).(Core.Try.ContinueType), ...)`)
that are NOT reduced under the impl's own `where` rewrites, so it never
converts to the declared `ControlFlow(T, E)`; generic bodies now diverge
through a testdata-local helper, `fn Diverge(generic T2: type) -> T2 {
return Diverge(T2); }` (the arbiter-verified
function/generic/deduce.carbon `ExplicitGenericParam` self-recursion
shape), applied across both check goldens, the lower golden, and both
conformance programs. (2) The symbolic-`R` generic golden hit a genuine
machinery gap: the carrier temporary's STANDARD cleanup discharge needs a
`Core.Destroy` witness for the symbolic `ControlFlow` specific, and
`CanDestroyType` (custom_witness.cpp) cannot derive one — its symbolic
deferral only engages for types it can prove destroyable, `Try` places no
`Destroy` bound on `ContinueType`/`BreakType` (contrast
`Iterate.ElementType: Copy & Destroy`), and bounding them is an
interface-contract change for the veto digest, not a fix round. Per §3's
pre-declared narrowing rule the symbolic-operand case is re-gated behind
the NEW precise TODO `` `postfix `?` on an operand of symbolic type` ``
(pinned by question.carbon's fail_todo_generic subfile; concrete operands
in generic bodies stay ungated), NEW work item W-071 records the gap with
the restored positive split as its discharge test, and plan §6's net-TODO
count is amended from zero to one.
_The impl-style rule (digest item 5):_ match-reconstruct `Branch` bodies
throughout (testdata, conformance, the doc's amended impl sketches); the
`return r` choice-binding CopyOfUncopyableType bound is pinned (R-5).
_The unit-break bound (digest item 4):_ `ControlFlow(C, ())` per-specific
SF-6 rejection pinned (R-4); NEW work item W-070 records the resolution
options for S3p. _Conformance (digest item 8):_
error_handling/control_flow_constructs.carbon SKIP → PASS (rewritten to the
F-006 shape, both `?` paths runtime-observed) plus the NEW differential
pair error_handling/question_propagation_diff.{carbon,diff.cpp} (C++
struct-shaped early-return oracle, 3-deep chain, runtime-selected failure
depth): target floor 83 PASS / 0 FAIL / 30 SKIP over 113;
`runner.py --self-test` OK, README table regenerated, scoreboard
regeneration rides the landing gate (R9). _TODO ledger:_ the B1a gate
string is DISCHARGED; one `?` TODO string remains as landed — the third
fix round's symbolic-operand narrowing gate, ledgered in plan §6 with
W-071 as its discharge (amended from "zero remain" at that round).
Veto-able.

_B2a landing note (2026-08-09):_ the implementation slice of the approved
B2 plan (fork/b2/plan.md — process step 6, two adversarial plan-review
rounds, coordinator sign-off on the six-item veto digest) is landed: the
W-071 discharge, the only ungated F-006 remainder per the plan's §0.1
classification (B3 stays post-S3p; the B2b S3p ask package is the sibling
slice). _The resolution (digest item 2, option (b) as pinned):_
`CanDestroyClass` (custom_witness.cpp) gains a choice clause BEFORE the
object-repr field walk — `class_info.is_choice` plus the symbolic-QUERY
predicate (the same `query_self_const_id.is_symbolic()` fact
`LookupDestroyWitness` defers witness building on, threaded down from the
`CanDestroyType` entry so yes/no and build/defer key on one predicate) —
answering destroyable-deferred `NonTrivial`, never `Trivial`, on the
strength of SF-6's per-specific payload guarantee; concrete choice
specifics take the unchanged field walk, and non-choice symbolic cases
(`ImplWitnessAccess`/`SymbolicBinding`) are untouched. **Recorded
deviation, flagged for B2b ratification:** the W-071 ledger's option-(b)
wording said "TRIVIALLY destructible"; the landed answer is
`NonTrivial`-deferred (a symbolic-time `Trivial` would encode a format a
future consumer could trust wrongly — the S1 adapter shape is genuinely
`NonTrivial` concretely); the B2b brief surfaces that delta alongside
option (a) as the user's S3p alternative. The §2.2 revisit note (valid
only while SF-6's allowlist holds and destroy synthesis stays a
placeholder) is recorded in the clause comment and in W-071's successor
state in work-items.json. _The widening (digest item 2's language-wide
statement):_ plain `var`s, `match` scrutinee temporaries, and `?`
carriers/operands of SYMBOLIC choice specifics in generic bodies now
compile uniformly — pinned deliberately by question.carbon's restored
generic split (the recorded discharge body `let unused c: R.ContinueType
= r?; return R.FromBreak(0);`), its symbolic-choice-operand,
widened-var, and widened-scrutinee-temporary probes (the scrutinee
probe carries the mixed-specific `MyResult(T, i32)` edge). _The uniformity policy (digest item
3):_ the handle_question.cpp gate is DELETED outright, no narrowed-gate
fallback needed — the NEW fail_question_generic.carbon pins `MakeR(R)?`
and `var unused x: R = MakeR(R);` side by side diagnosing the identical
missing-`Core.Destroy` error (`?` gets no carve-out; R-2/R-3's
falsifiers), plus the R-8 negative probe: an SF-6-REJECTED instantiation
of the widened `var` shape (`Widened(Fat)`) pins
`ChoicePayloadNotTrivialInSpecific` as a clean
monomorphization-time diagnostic under `ResolvingSpecificHere`, not a
crash or eval retry loop. _Golden placement note:_ the §3 probes landed
as NEW files (check fail_question_generic.carbon, lower
question_generic.carbon with the instantiated-generic CFG and the S1
adapter-payload probe) rather than subfiles of the existing
fail_question.carbon/question.carbon lower goldens, keeping those
byte-identical per §4; positive CHECK content rides the runner
autoupdate (R15/R19 red-first-CI reconciliation). The lower criterion is
the REVISED one: the instantiated-generic CFG carries the same
no-op-body destroy-call shape as the concrete `_CBasic.Main` baseline;
falsification is a non-empty destroy body, a user `Destroy` impl invoked
on the propagation path, or absent calls. _TODO ledger (digest item 4):_
the symbolic-operand string is DISCHARGED at its emission site; **net `?`
TODO strings across B2: zero** (plan §6 as written, no amendment needed);
all other TODO strings byte-identical. _Conformance (digest item 5):_ NEW
differential pair error_handling/question_generic_diff.{carbon,diff.cpp}
(generic `?` chain over symbolic `MyResult(T, i32)` operands instantiated
at i32 AND i64 — distinct `ControlFlow` specifics/layouts at runtime —
against a C++ function-TEMPLATE early-return oracle, runtime-selected
failure depth, runtime-computed payloads, an i64 payload-integrity
comparison): target floor 84 PASS / 0 FAIL / 30 SKIP over 114, no SKIP
flips; `runner.py --self-test` OK, README table regenerated (DIFF-4),
scoreboard regeneration rides the landing gate (R9). _R-6 (upstream):_
the pre-implementation re-check found the tree matching every plan
citation (CanDestroyClass :144, CanDestroyType dispatch, the :658
symbolic-build deferral, the eval hook) — no drift from upstream 453b547's
line of work; no public names minted, no new V-3a divergence-register
entries. _Review-round records (2026-08-09):_ plan §4's pre-change grep
found zero `Core.Destroy`-adjacent choice/match goldens outside the
enumerated set (outcome verified independently by the strictness
review); the R-5 broken-oracle drill was NOT run locally (no toolchain)
— its falsifier stands and the drill rides the conformance gate, whose
runtime differential comparison is also the pair's first compile+run
verification; the reconciliation churn review must apply the R-1/R-8
falsification triads by hand against the autoupdated goldens (they are
pinned in comments until then). Named residue: IMPORT parity for
generic bodies containing `?` (the deferred destroy-witness eval-block
content is only instantiated same-file; the W-069 precedent says
import-side gaps are real) — a follow-up subfile, not B2a scope. _Regen
round (2026-08-09):_ two authoring defects caught by the first
autoupdate — the symbolic-choice-operand probe annotated the continue
value as `T`, but it types as the unreduced projection
`MyResult(T, E).(Core.Try.ContinueType)` (the B1b non-reduction family;
now consumed through the deduced sink and RECORDED AS A KNOWN WART:
`?` on a direct choice operand under symbolic arguments yields
projection-typed values users must consume by way of deduction or
projection-annotated bindings until rewrite-reduction lands); and the
scrutinee probe's maker was declaration-only, but a GENERIC function
must be defined to be callable — defined (and the fail file's facet
maker likewise, as a diverging body). _R-1 triad applied by hand to the
regen (2026-08-09):_ destroy calls carry the baseline no-op shape; all
synthesized op bodies are bare returns; the adapter probe's user
`Tag.Op` appears ONLY inside the materialized witness thunk's
definition, which has ZERO call sites — never invoked from program
flow, which is the honest reading of the S1 exception's
"consulted-but-never-invoked". _Conformance round (2026-08-09):_ the
suite's first run COMPILE-FAILED the new pair — its original `let a: T =
Step(...)?;` chain was authored (in the implementation commit) before the
regen round surfaced the projection wart, and never received the goldens'
fix; the golden fix consumed the value through a deduced sink because
under symbolic arguments the continue value CANNOT be threaded as `T` at
all — an expressiveness limit of the landed slice, now ledgered as
**W-072** (projection rewrite-reduction; facet-binding rewrites DO reduce
— the W-071 discharge body's `FromBreak(0)` — but impl-lookup projections
on symbolic specifics do not; `Core.Try`'s missing success constructor is
recorded there as adjacent B2b/SF-9 brief material). Per R17 the pair was
NOT worked around silently: it is restructured to the proven
`PropagateChoice` configuration (operand and return the same specific so
the break path's `FromBreak` aligns projection-for-projection; continue
values through the golden's `Discard` sink; Ok payload reconstructed from
the seed — the identical value `Step` passes through, so the output
table, the runtime-selected depths, and the i64 layout-roundtrip
observation are unchanged) with the honest scope narrowing stated in the
pair's header: it arbitrates BREAK-path propagation + per-instantiation
layouts; continue-THREADING runtime arbitration is W-072 follow-up. The
C++ oracle's Chain mirrors the discard semantics. Veto-able.

_RETRACTION addendum (2026-08-18, W72a — fork/w072/plan.md §3,
record-honesty sweep item 1; a dated addendum, the historical text above
is deliberately NOT rewritten):_ two claims in the 2026-08-09 rounds above
are OVERSTATED and are hereby corrected. Quoted: "projection-annotated
bindings until rewrite-reduction lands" (the regen round) and "under
symbolic arguments the continue value CANNOT be threaded as `T` at all"
(the conformance round) — and the R17-cited restructure rationale carried
the same overstatement. The two-part correction, per the W-072
dissolution verdict (fork/w072/plan.md §0.1): (i) the continue value CAN
be threaded as `T` — under the ratified doc's own `final impl` spelling
(docs/design/error_handling.md's `Try` sketches, which have carried
`final` since the original F-006 design commit 9fdad04) — with NO
compiler change expected (the W72a probe goldens question_final.carbon /
fail_question_final.carbon / lower question_generic_final.carbon, probes
P-1..P-9); and (ii) non-final rewrite-reduction is NOT pending — it will
never "land", being upstream-DESIGNED refusal (specialization soundness:
docs/design/generics/details.md "`final` impl declarations";
p000983/p002868/p005337; upstream's
fail_nonfinal_specialized_symbolic_rewrite pin). W-072 accordingly
reclassifies from "language gap" to "idiom gap + verification gap"; it
stays OPEN until W72b's runtime threading arbiter lands. _Postmortem
(plan amendment, strictness F-1):_ the `final` omission survived every
review because testdata was reviewed against the doc's SEMANTICS, never
diffed against the sketch's exact spelling — the non-final idiom entered
at B1b (6b0b80e), and the third-round correction (3099532) edited the
very lines carrying `final` without connecting the modifier to the
behavior. The loop fix is rulebook rule R27 (code-to-sketch spelling diff
before landing), staged in W72a. Veto-able.

_W72a fix-round addenda (2026-08-18, the R11 fixer — dated follow-up lines
in the W-072 area per correctness F-3):_

-   **P-9 observed outcome: the falsification branch FIRED; W-073 MINTED.**
    The 3d261c0 regen showed fail_question_final.carbon's
    fail_inbody_recursive_branch split compiling CLEAN — under `final`, the
    in-body interface-recursive `return self.(Core.Try.Branch)();`
    type-collapses TOO, the opposite of the plan §2.2 in-body-unchanged
    prediction (the completed definition's body no longer routes through
    the declaring_impl_decls intercept, impl_lookup.cpp:949-963
    `GetImplSelfWitnessInsideImplDecl`, so the ordinary candidate path
    applies the final-impl rewrite). Processed per the plan §3 P-9 minting
    rule, which the implementation round left unexecuted (both adversarial
    reviews' converged BLOCKER): the split MOVED to question_final.carbon
    as the positive inbody_recursive_branch.carbon (zero diagnostics is
    the pin; no hand CHECK lines), and **W-073 is the minted item**
    (fork/inventory/work-items.json) — retext the eight-file "does not
    type-collapse" comment family plus the b1 §2.6 / B2a-era
    dated-correction texts FOR FINAL IMPLS (non-final sites stay valid)
    and EVALUATE retiring the `Diverge` trailing-return idiom in
    final-spelled impls, swept once W72b's runtime arbiter confirms.
-   **§2.4 contingency ladder: RESOLVED-CLEAN (strictness M-1).**
    P-1/P-2/P-3/P-8 all landed POSITIVE on the 3d261c0 regen
    (question_final.carbon's thread/mixed/lib+use splits; lower
    question_generic_final.carbon's instantiated threading CFG) — ladder
    step 1 taken; steps 2 (narrow machinery defect) and 3 (lane blocked)
    were never invoked and are closed for W72a.
-   **Deviation-2 adjudication (one line):** the prek doc-style hook's
    auto-fixes of pre-existing fork docs LAND per the F8a convention
    (hook-clean tree); the 6a635cd housekeeping commit is the standing
    resolution, superseding the W72a implementer's in-commit revert.

Veto-able.

_W72b landing note (2026-08-18, the W72b implementer — fork/w072/plan.md
§3 W72b, the final W-072 slice):_ the continue-THREADING runtime arbiter
lands as the NEW differential pair
error_handling/question_generic_thread_diff.{carbon,diff.cpp}. _The
arbiter's design:_ the same `final impl forall [T, E] MyResult(T, E) as
Core.Try where .ContinueType = T and .BreakType = E` the W72a goldens
proved statically, with the threaded continue values LOAD-BEARING in the
observable payload — `fn Chain[T: Combinable](x: T, fail_at: i32)`
spells the dissolved shape `let a: T = Step(x, fail_at == 1, 101)?;`
then `let b: T = Step(a.Combine(), fail_at == 2, 202)?;` and returns
`Ok(b)` (the plan's Combine(a)-style chaining: each step's input is
computed from the PREVIOUS step's threaded output through the
arbiter-verified checked_generics.carbon interface shape, Combine(x) =
x + x, so the Ok payload is 2 * seed — computable only from correctly
threaded values, never reconstructed from the seed, unlike the sibling
pair's discard shape, which stays unchanged per R16: the W72a retext of
its header/:92/.diff.cpp comments already carries the sibling pointer,
so this slice touches it not at all). Instantiated at i32 AND i64
(distinct monomorphized `Core.ControlFlow` carrier layouts); failure
depths and seeds runtime-computed (R16d; RuntimeSeed = x + 20, depths
0..2 from RuntimeSeed(-20..-18), i32 seed 42, i64 seed 2^32 + 44 with
the independently computed Ok expectation 2^33 + 88 — widened
high-half-significant at the review round, see the round-2 amendment);
the C++ oracle is a function
TEMPLATE with the same explicit early returns; byte-identical
stdout + exit per DIFF-1, no EXPECT-STDOUT. Hand-computed output table,
both sides: depth 0 -> `0,84` (i32) / `0,1` (i64 payload == 88); depth
1 -> `1,101`; depth 2 -> `1,202`. _The broken-oracle drill (R-5):_ per
the plan's declared mechanism (strictness F-5) the drill is the
B2a-style DELIBERATE RED CI PUSH — the pair rides the PR branch once
with step 1's injected depth flipped in the `.carbon` side only
(`fail_at == 1` -> `fail_at == 3`), the red differential run is linked
in the round-2 amendment below as the drill evidence, and the flip is
reverted before landing (an
always-green pair under the flip is falsification); the mechanism is
recorded in the pair's header. _Discharge staging (the R9 hedge):_
W-072's ledger notes now read DISCHARGE PENDING THIS RUN — the item
discharges when this landing's scoreboard regeneration shows the pair
PASS (target floor **91 PASS / 0 FAIL / 29 SKIP over 120**, no SKIP
flips, no bullet claims — the pair deepens the already-PASS "Error
handling: dedicated control flow constructs" bullet), per the §6
discharge criteria (whose items (i), (iii), (iv), (v) landed at W72a;
this slice completes (ii)); a non-PASS re-opens the item with the run's
evidence. `runner.py --self-test` OK at 120 programs; README table
regenerated (DIFF-4); conformance-request line fired. W-072's closure
successor note, staged for the confirming run: non-final non-reduction
is UPSTREAM-DESIGNED behavior, permanently pinned by the negative
probes — not a residual gap; the `FromContinue` residue lives in the
SF-9/S3p brief (W72c cut, plan §0.3). Veto-able.

_W72b round-1 amendment (2026-08-18, coordinator — R17 loud-not-silent):_
the first CI round of the drill push (run 32095993785, commit 066cdc3)
came back red as a **COMPILE-FAIL, not the drill's DIFF-MISMATCH** — the
pair as first authored did not compile:
`error: cannot access member of interface Core.Destroy in type T that
does not implement that interface` at the `a.Combine()` argument of
step 2. _Root cause (diagnosed before any fix, per the no-slop
directive):_ `Chain` bound its generic as `[T: Combinable]`, a bare
user-facet — but the generic body destroys T-typed temporaries (the
`a.Combine()` argument temp), and destroy insertion on symbolic `T`
needs the `Core.Destroy` witness. Every W72a-proven shape used
`[T: type]`, and the `type` facet carries that witness implicitly —
pinned by upstream's impl/custom_witness/destroy.carbon
(`type as Core.Destroy` succeeds); a bare `Combinable` facet exposes
only `Combine`. _Fix:_ the precedented combined-facet spelling
`[T: Combinable & Core.Destroy]`
(facet/call_combined_impl_witness.carbon's `G[T: A & Empty & B]` is the
exact binding-position shape, with member calls through the combined
facet). This is a test-program authoring defect, not a toolchain
defect — the diagnostic is correct behavior. The implementer's staged
claim that the floor "confirms on this run's scoreboard" was
aspirational and is retracted for round 1; the drill restarts with the
fix + flip on the next push, so the DIFF-MISMATCH drill evidence and the
green discharge run both still lie ahead. The round-1 red run is
compile-fail evidence only. Veto-able.

_W72b round-2 amendment (2026-08-18, coordinator — drill evidence +
review round):_ **The R-5 broken-oracle drill is DONE and verified.**
Round 2 (run
<https://github.com/jmann345/carbon-lang/actions/runs/32096324806>,
commit 2217244: the Destroy-constraint fix + the drill flip) came back
red as exactly the predicted **DIFF-MISMATCH** — the Carbon leg (flip
live) succeeded at depth 1 (`0,84` on i32; `0,1` on i64) while the C++
oracle broke (`1,101`), depths 0 and 2 byte-identical, both exits 0,
stdout differing — so the harness demonstrably catches divergence on
this pair, and the `& Core.Destroy` fix compiles AND runs (no
`Core.Copy` conjunct needed for these `let` bindings). _The adversarial
review round (2 fresh-context reviewers, findings folded into the
landing commit):_ (1) BLOCKER, both reviews: the only
conformance-request bump rode the drill (red) commit, so no scoreboard
run would ever fire against the landing content — fixed: the landing
commit carries its own request bump with the discharge-targeting text.
(2) SHOULD-FIX, both reviews: the i64 leg observed its payload through
a single boolean over values fitting in 32 bits, so a
truncate-then-extend width collapse (the B2a corruption family) would
pass invisibly — fixed: i64 seed widened to 2^32 + 44 (expectation
2^33 + 88) on BOTH sides, and the single-boolean channel limit is now
acknowledged in the pair's ProbeL comment. The widening postdates the
drill run; the drill's divergence channel (depth-1 outcome-tag
disagreement) is unaffected by seed magnitude, so the drill evidence
stands for the landing content. (3) SHOULD-FIX (review B): plan §0.1's
candidate lanes (a) eval-side and (b) desugar-side reduction were
vetoed in the plan but never recorded in THIS log — recorded here:
**both are VETOED per V-3a** (upstream contradictions: non-final
non-reduction is upstream-DESIGNED specialization soundness), which
completes the §6 criterion (iv) obligation the landing note had
attributed entirely to W72a. (4) Ledger retexts (review B): W-072
STATUS re-pointed at the post-revert green run; the new pair added to
W-073's enumerated sweep surface (a final-impl `Diverge` site the
pre-existing eight-file list predates). Residual review notes, recorded
not actioned: `Step` is the identity on success, so the
"yield-the-operand's-input" mis-thread class is unobservable in
principle (rated implausible dataflow by the reviewer — accepted); the
drill exercises the depth/tag channel only (the plan mandates exactly
that). Veto-able.

_W72b discharge confirmation (2026-08-18, coordinator):_ the post-revert
green run
(<https://github.com/jmann345/carbon-lang/actions/runs/32096689454>,
commit 547aa83) regenerated the scoreboard at exactly the target floor —
**91 PASS / 0 FAIL / 29 SKIP over 120**, `question_generic_thread_diff`
PASS inside the rolled-up PASS "Error handling: dedicated control flow
constructs" bullet (4 programs). All of fork/w072/plan.md §6's discharge
criteria are now met: (i)/(iii)/(v) at W72a, (iv) completed by the
round-2 amendment's veto record, (ii) by this run. **W-072 is
DISCHARGED** (ledger retitled; the staging hedge's confirming condition
fired as staged, so no re-open). W-073 (the Diverge/comment-family
sweep, nine files) unblocks as the natural successor. Veto-able.

_W-073 sweep landing note (2026-08-18, the W-073 sweep implementer —
fork/inventory/work-items.json W-073, the P-9-fallout retext/evaluation
sweep):_ the nine-file surface swept per the item's per-site rule
(EVALUATE, not blanket-rewrite). Evidence chain, restated once: the P-9
observation (question_final.carbon's inbody_recursive_branch split,
3d261c0 regen — `return self.(Core.Try.Branch)();` compiles CLEAN inside
a `final` impl body) falsified the "does not type-collapse" rationale
statically FOR FINAL IMPLS; W72b's runtime arbiter
(question_generic_thread_diff PASS at 91/0/29 over 120, run 32096689454)
confirmed the collapse-threaded values at runtime; non-final
non-reduction stays upstream-designed and permanently pinned. Per-site
decisions:

| # | Site | Impl finality | Decision |
| --- | --- | --- | --- |
| 1 | check/testdata/operators/question.carbon (4 subfiles) | non-final | retext only: scope-qualified comment; `Diverge` kept |
| 2 | check/testdata/operators/fail_question.carbon (3 subfiles) | non-final | retext only, line-count-preserving per split |
| 3 | lower/testdata/operators/question.carbon | non-final | retext only |
| 4 | lower/testdata/operators/question_generic.carbon (generic split; adapter split's short comment makes no claim) | non-final | retext only |
| 5 | conformance error_handling/control_flow_constructs.carbon | non-final | retext only; code untouched |
| 6 | conformance error_handling/question_propagation_diff.carbon | non-final | retext only (comment-only, oracle untouched) |
| 7 | conformance error_handling/question_generic_diff.carbon | non-final | retext only (R16: semantics pinned; SCOPE header already carried the two-regime truth) |
| 8 | conformance error_handling/question_generic_thread_diff.carbon | FINAL | SIMPLIFIED: `return self.(Core.Try.Branch)();` replaces the `Diverge` trailing return; helper DELETED |
| 9 | docs/design/error_handling.md | final (sketches) | re-corrected (dated 2026-08-18 fourth-round amendment) to the two-regime truth; both sketches simplified to the recursive trailing return, helper dropped |

The uniform non-final retext replaces the falsified blanket claim with
"through this NON-final impl the interface-recursive call does not
type-collapse (upstream specialization soundness keeps its projections
unreduced; under `final` it does — question_final.carbon)" — six comment
lines to six, so golden line counts per split are unchanged. CODE changed
at site 8 only: the deleted helper and the swapped trailing return are
both unreachable-path content (the match is exhaustive), the reachable
control flow is untouched, and the C++ oracle is untouched —
hand-recomputed output table, both sides, unchanged: depth 0 -> `0,84`
(i32) / `0,1` (i64, payload == 2^33 + 88); depth 1 -> `1,101`; depth 2 ->
`1,202`. The site-8 shape is byte-for-byte the P-9 pin's (final impl
forall, same match, same recursive return), and R27 now holds
code-to-sketch: the pair's spelling matches the doc's simplified
sketches. Dated-correction texts: fork/b1/plan.md §2.6 gained an
APPENDED W-073 amendment scope-narrowing the third-round correction to
non-final impls (history unrewritten); this log's B1/B2a correction
records stay as-is (historical dated addenda). RESIDUE, recorded not
actioned (outside the item's enumerated surface): question_final.carbon
(thread/mixed/lib splits) and lower question_generic_final.carbon keep
`Diverge` inside final impls with "retained pending W-073" comments that
go stale at discharge — a comment refresh can ride any future touch of
those goldens. `runner.py --self-test` OK. _Discharge staging (R9
hedge):_ W-073 is DISCHARGE-STAGED — it discharges when this landing's
runner autoupdate reconciles the retexted goldens at fixpoint (R26:
loc-number shifts expected, no structural pass-2 drift), the gate is
green, and the conformance run holds the floor at EXACTLY 91 PASS /
0 FAIL / 29 SKIP over 120 with question_generic_thread_diff still PASS
(the pair's PASS re-arbitrates the site-8 code change at runtime; this
sweep must not move the floor). A non-PASS or floor movement re-opens
the item with the run's evidence. Veto-able.

_W-073 review-round amendment (2026-08-18, the W-073 review round — two
adversarial reviews, NO code defects found; fixes applied by the R11
fixer):_ (i) Reviewer A's BLOCKER — the landing commit 18f11a1 did not
arm the conformance re-arbitration (no conformance-request bump rode the
sweep; the same class as the W72b round's blocker) — was ALREADY RESOLVED
before this round closed: the follow-up push 1e55ae7 carried the
gate/conformance bump, and all three fired runs are in hand — autoupdate
(<https://github.com/jmann345/carbon-lang/actions/runs/32097812689>,
commit 18f11a1) a STRICT NO-OP with no push-back, gate
(<https://github.com/jmann345/carbon-lang/actions/runs/32098017539>)
green, and conformance
(<https://github.com/jmann345/carbon-lang/actions/runs/32098017538>,
commit 1e55ae7) green at EXACTLY **91 PASS / 0 FAIL / 29 SKIP over 120**
with `question_generic_thread_diff` PASS inside the 4-program PASS
bullet. (ii) That conformance run is the FIRST-EVER lowering exercise of
the collapsed in-body recursive interface call — no lower golden pins the
shape (lower/question_generic_final.carbon still spells `Diverge`) — and
it passed. (iii) REGEN-WORDING CORRECTION (both reviews): the landing
note's staging clause "(R26: loc-number shifts expected, no structural
pass-2 drift)" and the ledger's matching "loc-shift passes expected:
CHECK content moves but line counts per split are unchanged" were wrong
and self-contradictory — unchanged line counts mean CHECK content does
NOT move, so the correct prediction was a STRICT NO-OP, which is exactly
what run 32097812689 delivered (R26 fixpoint met trivially). The ledger
STATUS text is corrected in place (current-slice staged text); the
landing note above stands corrected by this amendment, unrewritten.
(iv) RESIDUE third member (review A): check
fail_question_final.carbon (P-6/P-7 splits) also keeps `Diverge` inside
FINAL impls — with no stale claim text, so no retext is owed — now
recorded in the ledger's residue list alongside question_final.carbon
and lower question_generic_final.carbon; recorded, not actioned.
(v) RECURSION-IF-REACHED acknowledgment (review A): one sentence added
at the pair's trailing-return comment and in the doc's fourth-round
amendment — if the trailing return were ever reached (it cannot be while
the match stays exhaustive), the recursive self-call diverges rather
than diagnosing, the same if-reached behavior as the deleted `Diverge`
helper; the pair's edit is COMMENT-ONLY, so run 32098017538's runtime
arbitration of its semantics stays valid. (vi) NITs, recorded not
actioned further: the landing note's "six comment lines to six"
uniformity overstates — conformance sites 5/6 went 6 -> 7 (harmless;
conformance programs carry no CHECK/@LINE machinery); the R27
code-to-sketch spelling match holds modulo the necessary `Core.`
qualification outside the prelude; the autoupdate-request timestamp
regression is cosmetic. With the three runs in hand, all four
DISCHARGE-STAGED conditions are hereby confirmed MET — autoupdate
fixpoint (trivially, by strict no-op), gate green, floor exact at
91/0/29 over 120, pair PASS — **W-073 is DISCHARGED** (ledger retitled;
STATUS updated with the run ids and date). Veto-able.

### F-007: Unions - **Native `union` declaration** (2026-07-19)

Rust-shaped safety surface (writes safe, reads defined byte-reinterpretation,
trivially-copyable fields in 0.1), C++-compatible layout on the existing
CustomLayoutType machinery, both interop directions. Settles the
overlapping-storage primitive choice payloads (W5) lower onto. Rejected:
Core.Storage primitive only, import-only. Per fork/design-sprint/unions.md.

**Sub-decisions F-007a..k (user by way of AskUserQuestion, 2026-07-19):**
standalone `union` introducer keyword (a); Rust safety model — writes
safe, reads Strict-unsafe, Permissive behavior in 0.1 (b) — WITH the
user's standing guidance that `choice` is Carbon's safe tagged union
(Rust-enum model) and the docs must steer users to `choice` unless C++
union interop is needed; read semantics are defined byte reinterpretation,
never UB — chosen by the user's lowest-friction rule since the existing
imported-union lowering already behaves this way mechanically (c);
designated single-field or unformed-then-assign init only (d);
trivially-copyable + trivially-destructible fields in 0.1 (e);
anonymous unions import-only in 0.1 (f); debug-build discriminator
tracking committed as named future work (g); `union` reserved keyword
with r#union migration (h); at least one field required (i); fully
guaranteed layout — offset 0, max size/align (j); choice-payload storage
contract stated normatively as the W5 implementation contract (k).

### F-008: Threading/atomics interop — **Fix the three defects** (2026-07-19)

Memory-model design doc + conformance programs + upstreamable fixes for:
std::thread(carbon_fn) check failure, template-specialization-typed global
link failure, std::atomic<CarbonClass> triviality assert (the last doubles
as the first Carbon-type-into-Clang slice F-010/W8 need). Rejected:
doc-only, Core.Sync veneer, native atomics. Per
fork/design-sprint/threading-atomics.md.

_F8b landing note (2026-08-18):_ the D2 fix of the approved F-008 plan
(fork/f008/plan.md §2.2, §3 F8b), post-review fix round folded in.
Mechanism: `CarbonExternalASTSource::CompleteType`
(check/cpp/generate_ast.cpp) consults `IsTriviallyCopyableForExport`
(check/cpp/export.cpp, the single-owner predicate of W-006 coherence risk
7) and exports a qualifying class WITHOUT the thunk-bodied destructor, so
Clang's implicitly-declared special members stay trivial and libc++'s
`static_assert(is_trivially_copyable<T>)` gate accepts the class.
Qualifying = concrete non-generic, `HasTrivialClassShapeForExport` (no
base, no vtable, not dynamic, not abstract), and `IsTriviallyDestructible`
(check/custom_witness.cpp — the destroy machinery's own `CanDestroyType`
classification recursed through adapted types / object representations,
scalars as the base case) including no user `Core.Destroy` impl. **W-021
DISCHARGED**; no §2.2 S→M escalation fired. Deviations from the plan
letter, recorded per R17: **(1)** the implementation commit's falsifier
labels are corrected to plan §5's R-2 (positive pin / real-libc++ pair
arbiter) and R-3 (negative probe). **(2)** Adapter classes qualify through
`GetAdaptedType` recursion — §2.2 is silent on `adapt`; the recursion is
destruction-semantics-aligned per `CanDestroyClass`'s identical
adapted-type dispatch — pinned both ways (positive `adapter_of_scalar`
split in trivially_copyable.carbon; negative user-Destroy-adapter arm in
the fail probe). **(3)** The user-impl scan (`HasUserDestroyImpl`) is
forward-looking (a user `Core.Destroy` impl is inert today — the custom
witness wins the lookup and destroy ops are no-op placeholders) — WITH the
F1 correction: the first cut scanned only the LOCAL impl store while its
comment claimed equivalence with destroy-lookup's candidate population;
both adversarial reviews refuted that (BLOCKER) — an imported class whose
defining library declares a user `Core.Destroy` impl would have exported
trivially-copyable in the importing TU while non-trivial in its own, a
cross-TU divergence of the exported record. The landed scan mirrors the
candidate collection (`CollectCandidateImplsForQuery`,
check/impl_lookup.cpp) READ-ONLY: local store PLUS every imported IR's
impl store, matched in place with no `ImportImpl`/materialization —
interface identity by the imported IR's `core_interface` tag (assigned
only to Core-package interfaces and propagated through import) plus the
Core-package scope check `GetCoreInterface` applies locally; self identity
by canonical defining declaration (`GetCanonicalFileAndInstId`,
sem_ir/import_ir.cpp — the identity import deduplication itself verifies).
Divergences from the collection are conservative-only: ALL import IRs are
walked (a superset of the orphan-rule-filtered `FindAssociatedImportIRs`
set) and symbolic-self blanket impls are treated as covering. The remaining
same-file ordering hole is documented at the scan (an impl textually after
the class's first clang completion is missed where lookup would poison the
use — inert today for the same custom-witness reason). Falsifier landed
with the fix: the two-file `destroy_lib` +
`fail_atomic_of_imported_user_destroy` split pins that the imported-impl
case KEEPS the thunk. **(4)** Nested-field narrowing per the strictness
review's F2: the base/vtable/dynamic(/abstract) checks now apply to NESTED
class-type fields too, through the shared `HasTrivialClassShapeForExport`,
per §2.2's "under the same predicate" letter.
make_unique_test.carbon re-derivation (plan §4, review amendment 5): its
`class C` (single i32 field, no user Destroy, no base/vtable) qualifies,
so `unique_ptr<C>`'s deleter now runs C++'s implicit trivial destructor
instead of the exported thunk; the thunk's body was the no-op placeholder,
so observable behavior is unchanged — exit criterion stays "test green on
the runner". Refined golden-movement prediction (correctness F3): churn is
confined to the nine goldens naming `__destroy_thunk`
(check interop function/export/generic; lower class/static; lower interop
cpp/class/export/{class,method}; lower interop cpp/class/import/dynamic;
lower interop cpp/class/virtual_fn; lower interop
cpp/function/export/{constructor,generic}; lower interop cpp/issue7142) —
and of those, import/dynamic.carbon and virtual_fn.carbon must NOT move
(C++-owned and dynamic classes stay on the thunk path); movement there is
a stop-and-explain event. Process note: the R12 post-edit hook flagged the
NEW fail arms' hand-written CHECK:STDERR pins under R16a; plan §8's
fail-file exception applies (new fail_ content ships hand-pinned, S2c/S2d
precedent), the pins are marked best-effort in-file, no pre-existing CHECK
line was touched, and the red-first runner autoupdate reconciliation
(fork/autoupdate-request.txt refreshed) is the arbiter. Veto-able.

_SL-1 round-2 note (2026-10-05), superseding "(3)" above in part:_ a
user `Core.Destroy` impl is no longer inert. The SL-1 implementation review
(fork/slices/plan.md §6.A amendment) found `Core.Buf(T)`'s in-class `impl
as Destroy` was never selected — impl lookup consults the destroy custom
witness first (check/impl_lookup.cpp `EvalLookupSingleFinalWitness`) and
`CanDestroyClass` never looked for a declared impl — so every `Buf` leaked
behind a synthesized `ret void`. Fixed at the root: `CanDestroyClass`
answers `NoDestroy` for a class covered by a CLASS-KEYED declared `Destroy`
impl (`HasClassKeyedImpl`, the union rule's `HasUserCopyImplOutsideCore`
scan generalized over the interface and the `Core` trust boundary; blanket
symbolic-self impls do not count, `partial` selves keep the synthesized
witness), and impl lookup then selects the declared impl. `HasUserDestroyImpl`
(the export predicate's scan, with its symbolic-self shortcut) is unchanged
and now strictly broader than the lookup's yield, which keeps the exported
record's triviality conservative. The "same-file ordering hole" stays as
described (a lookup before a same-file out-of-class impl's declaration is
answered by the synthesized witness; the design's in-class spelling never
hits it). Synthesized AGGREGATE destroy ops remain the member-destruction
placeholder (`MakeDestroyOpBody`) — residue W-108 (filed as W-105 at the
round-2 fix; renumbered at discharge, trunk's OV-2 having taken W-105..W-107).
Six existing goldens
move (all those holding a user `Destroy` impl with a dumped or lowered
destroy); the thunk-path goldens of this note do not.

_SL-1 round-3 note (2026-10-05), the literal-subscript rule:_ the hosted
autoupdate of the round-2 tree (run 37329946461) crashed lowering
`Slice.At(i32, Core.IntLiteral as ImplicitAs(i64))` — "Missing constant
value for call to comptime-only function" — because the rev 2 blanket
`impl forall [U: ImplicitAs(i64)] Slice(T) as IndexWith(U)` calls
`subscript.Convert()` on a runtime parameter, and `IntLiteral`'s
`ImplicitAs(Int(To)).Convert` is `"int.convert_checked"`, compile-time only.
Plan R-5 cited `Core.String`'s identical blanket impl as precedent; that
impl lowers only because its `At` is itself a builtin (`"string.at"`) lowered
at the call site with the call site's constant — a review miss (R28(d),
recorded at R-5). Decision: `Slice(T)`/`Buf(T)` implement `IndexWith(i64)`
only, and check/handle_index.cpp applies a literal-subscript rule — an
`IntLiteral`-typed subscript converts to `i64` before dispatch when the
operand type implements `IndexWith(i64)` and has no
`IndexWith(Core.IntLiteral)` impl (a non-diagnosing `LookupImplWitness`
probe over a facet type built directly from the `Core.IndexWith` decl, found
with the new `TryLookupNameInCore`; the array arm's hardcoded subscript
conversion, decided by lookup). The "and implements `IndexWith(i64)`" half is
deliberate: it keeps every existing `IndexWith` golden byte-identical (types
with neither impl still diagnose `Core.IndexWith(Core.IntLiteral)`; String
and user `IndexWith(Core.IntLiteral)` impls dispatch as written; the
missing/wrong-`Core.IndexWith` splits are not probed). Cost accepted: an
`i32` subscript on a slice is an error (`s[i as i64]`), pinned by
`fail_subscript_i32` and listed in slices.md "0.1 limits".

_SL-1 round-4 note (2026-10-05), after hosted autoupdate run 37335213696
moved 40 files where 18 were predicted (fork/slices/plan.md §6.A round-4
amendment, R-5 amendment):_ (a) REGRESSION fixed — the round-2 note's
"`HasUserDestroyImpl` is unchanged and now strictly broader" was the bug:
its symbolic-self shortcut treated the prelude's own `impl as Destroy` in
`class Buf(T)` (self `Buf(T)`, symbolic, in every file's import set) as a
blanket, so `IsTriviallyDestructible` — the union field rule and the C++
export predicate — rejected every class, `i32` (`Core.Int(32)`) included;
13 union/export goldens broke, plus the `union_scope_set` split of
check/function/overload/basic.carbon. Now a class-typed impl self, concrete or a
symbolic specific, is keyed on its class, and only `impl forall [T: type] T
as Destroy` is a blanket; the 13 goldens return byte-identical. (b)
Disclosed, kept: the appended `Slice(T) as Iterate` impl is imported into
every file that looks `Iterate` up (the import filter is interface-keyed)
and carries the `i64 as Destroy` facet of its rewrite, so the four
`for`-over-array lower goldens gain one uncalled `declare` of
iterate.carbon's synthesized `Op` — the array impl's `i32` twin of which
they already carried — and check/interop/cpp/range_for renumbers two
constants; not a destroy-selection change. (c) Decision: `Slice(T)`/`Buf(T)
as IndexWith(i64)` and `Slice(T) as Iterate` are `final impl`s (the
`Optional(T) as Try` precedent), because a symbolic lookup resolves only
final impls and a non-final impl's `where .ElementType = T` rewrite is
unknown in a generic body — the `generic_element` split had pinned
`cannot implicitly convert ... (Core.IndexWith(i64).ElementType) to T` in
a POSITIVE golden; re-predicted clean, the four slice goldens cleared. (d)
The literal-subscript probe is skipped for an `ErrorInst` operand (two
index goldens return byte-identical); the `Core.Int` import_ref it must
load to name `i64` is accepted and disclosed for index/fail_non_tuple_access
and operators/overloaded/index_with_prelude (semantically inert,
unavoidable). The round-3 re-review's three findings (APPROVE-WITH-FIXES:
the false byte-identity claim, the unguarded `Core.Int` lookup, the stale
"no diagnostic kind" bullets) are folded.

_F8c landing note (2026-08-18):_ the D3 fix of the approved F-008 plan
(fork/f008/plan.md §2.3, §3 F8c). _Adjudication verdict (step 1, plan
adjudication D, run 32079343005, 2026-08-17T23:11Z): H0 REFUTED — and the plan's pre-declared H0-mock-divergence
stop-and-explain path FIRED (the F8a mock dump looked fixed while the
real pair link-failed; the §2.3 amendment is filed on this branch, a
strictness-review catch: the substance was done, the mandated filing
was not)._ The un-SKIPped real-header
pair cpp_atomic_global_counter_diff COMPILES fully (the flagged as-i32
chain and every thunk lowered) but LINKS red with `undefined symbol:
_Ctotal.Main.2` (referenced by the fetch_add thunk and both
`__thread_proxy` instantiations) AND `_Ctotal.Main.3` (referenced by the
store and load thunks) — the defect is live, and richer than the sprint's
single-symbol `_Cgcount.Main.1` measurement: references split per
function across DISTINCT `.N`-renamed duplicates of one variable.
_Mechanism (§2.3 H1 family):_
`Lower::FileContext::BuildNonCppGlobalVariableDecl`
(toolchain/lower/file_context.cpp) created a fresh `llvm::GlobalVariable`
on EVERY call — no cache, no module-symbol-table lookup — while the
function path (`GetOrCreateLLVMFunction`) has had a name-keyed
early-return all along. LLVM silently uniquifies each duplicate with a
`.N` suffix, so the initializer added by `LowerGlobalVariables`
(file_context.cpp `LowerGlobalVariables`, the :305/:306 insert+define)
lands on one object while references bind others. The evidence
adjudicates the hypothesis set: two distinct undefined suffixes in one
link refute H3 (a deterministic mangling divergence yields ONE wrong
name, not per-function rename suffixes); H2's non-concrete constant-walk
skip is refuted by the compile succeeding (a skipped constant would have
crashed the definition walk's `cast`/`setInitializer` at
file_context.cpp:297-307); H0 by the link failure itself. Honest residue,
recorded per R17: the check-side reason the creation count EXCEEDS the
two call sites the plan's H1 story names (constant lowering + the
non-constant definition-walk branch) — the per-function split implies
per-use-cluster mints — was not fully traced without a local build; the
fix below restores the one-mangled-name⇔one-object invariant at the only
site that mints these symbols, which closes every variant of the split,
and the probe's new member-calls split plus the pair arbitrate that claim
at regen and link level (falsifiers §5 R-4). _Fix:_ name-keyed reuse in
`BuildNonCppGlobalVariableDecl` — `llvm_module().getGlobalVariable(
mangled_name, /*AllowInternal=*/true)` early-return before creating, the
exact global-side mirror of `GetOrCreateLLVMFunction`'s
`getFunction(mangled_name)` early-return (the B2a-coalescer-adjacent
function path had the dedup; the global path was the hole — answering
the plan's H1/coalescer-analog question affirmatively). No check-side,
mangler, or driver changes. _Probe:_
lower/testdata/interop/cpp/globals_carbon_defined.carbon gains a third
split (mock `Counter<T>` template, file-scope `var total:
Cpp.Counter(i32)`, store/fetch_add/load member CALLS from two functions
mirroring the pair's Bump/Run) with the R-4 pin stated in-file: one
defined `@_Ctotal.Main`, every reference on that same symbol, no `.N`
duplicate anywhere. _Movement prediction for the regen:_ ONLY
globals_carbon_defined.carbon moves, by the ADDED split's new module dump
(the fix's reuse path is unreachable when a variable is created once, so
the existing splits' dumps and every other golden — globals.carbon in
particular, the R-5 imported-direction negative — stay byte-identical;
any other movement is stop-and-explain). Conformance:
cpp_atomic_global_counter_diff flips SKIP→PASS off the branch's red
baseline; floor 89/0/30 over 119; bullets stay 43/56 (plan §6). W-022
DISCHARGED (ledger updated, plan §9). Veto-able.

_F8d landing note (2026-08-18):_ the D1 fix of the approved F-008 plan
(fork/f008/plan.md §2.4, §3 F8d) — the FIX path taken; the §2.4
sanctioned degrade did NOT fire (no wall outside the M estimate was
hit). (Reconciliation, review finding F4: the same-signature
thunk-symbol collision recorded below WAS a wall the plan's shape left
unnamed, but it fell inside the M estimate's multi-file effort —
thunk-name plumbing, not a re-design — so §2.4's deeper-than-M degrade
trigger never armed.) _Step-0 upstream re-check (plan §2.4 mandate,
standing rule 5):_
through the 2026-08-17 weekly merge (864845c by way of dfe308d),
p003848-lambdas remains an accepted proposal with NO implementation
landed that a callable mapping could build on — no lambda/callable
commits in the range, `TryMapType` (check/cpp/type_mapping.cpp) still
enumerated no `SemIR::FunctionType` case, and upstream's recent
check/cpp activity (3bb2453/2784f33/de1cd70: class-specific and generic
CLASS export) is disjoint from function-as-callable — so the fix is
built beside nothing: no machinery exists to build on, and W-023's
upstream-watch is retired with the discharge. _Mechanism (the §2.4
design as pre-declared, digest item 4):_ a call argument whose type is
the `SemIR::FunctionType` of a concrete, non-generic, non-member
function now maps to a POINTER to its exported declaration's C++
function type (`TryMapFunctionType` → new `GetOrExportFunctionDeclToCpp`
in check/cpp/export.cpp, reusing the reverse-interop `Carbon::F`
export machinery the F8a bridge programs already exercise — the
exported decl's ABI to the Carbon body is the existing thunk pair, not
new ABI surface, answering the plan's checked-not-assumed note); the
invented Clang argument is an AST-embedded `DeclRefExpr` +
`CK_FunctionToPointerDecay` (`InventConstantFunctionArg`, the
constant.cpp:253-272 shape the plan cites, NOT an `OpaqueValueExpr`),
so Sema deduces `std::thread`'s constructor template on `void(*)()` and
plain function-pointer parameters convert exactly. The resolved
signature records the embedded declaration
(`ClangDeclSignature::constant_function_args`, sem_ir/clang_decl.h —
part of the canonical signature key, so two same-signature Carbon
functions passed to one callee import as distinct Carbon decls with
distinct thunks); downstream, the argument is a compile-time constant:
`MakeParamPatternsBlockId` (check/cpp/import.cpp) forms no Carbon
parameter for it, `PerformCallToCppFunction` (check/cpp/call.cpp) drops
it from the runtime argument list, `IsCppThunkRequired` forces a thunk,
and the thunk (check/cpp/thunk.cpp) embeds
`sema.BuildDeclRefExpr(constant_decl)` in its body instead of a
parameter — with the constant's Itanium-mangled name appended to the
thunk's asm label (`.argN.<mangled>`) so thunks differing only in the
embedded function get distinct symbols (two functions of one signature
would otherwise collide on one internal asm label — a miscompile the
plan's shape didn't name, caught in design here). A guard in
`MaybeModifyCppThunkCallForConstEval` (check/cpp/constant.cpp) keeps
const-eval from zipping the shortened runtime argument list against the
full C++ parameter list. _Post-review narrowing (B-1, 2026-08-18):_ the
mapping was initially installed in `TryMapType`, where EVERY
`MapToCppType` consumer — exported RETURN types and exported globals
(check/cpp/export.cpp) included — would have accepted function types
and paired a Carbon function value's EMPTY runtime representation with
an 8-byte `void (*)()`: an export-direction uninitialized-value
miscompile where pre-F8d code failed cleanly with "failed to map". The
fix round confined the mapping to the call-argument path —
`InventPrimitiveClangArg` tests `Is<SemIR::FunctionType>` and calls
`TryMapFunctionType`/`InventConstantFunctionArg` directly, BEFORE the
generic `MapToCppType`, and `TryMapType` returns null for
`SemIR::FunctionType` again (wrapped `const`/pointer forms unwrap to
the same null) — restoring the export-direction diagnosis while the
argument path keeps the full mechanism above. _Negative partition (plan
§5 R-7):_ generic
functions (`generic_id`/`specific_id`), methods (`self_param_id`), and
`FunctionTypeWithSelfType` values fall to the same null mapping and
keep today's `CppCallArgTypeNotSupported`; constructor- and
method-shaped exports are additionally rejected decl-side
(`isa<CXXMethodDecl>`). _Goldens:_ the F8a red-baseline pin
fail_todo_carbon_fn_as_callable.carbon flips POSITIVE as
carbon_fn_as_callable.carbon (hand error pins dropped; runner
autoupdate owns the CHECK content per R15/R19, dump-sem-ir regions
around the two flipped calls), gains the two R-7 fail_todo splits
(generic fn, method value — hand-pinned best-effort per §8's fail-file
rule, reconciled by the same autoupdate), and gains the
two_carbon_fns_one_callee split (post-review B1, 2026-08-18): TWO
same-signature Carbon functions into the SAME constructor-template
callee, whose regen must surface TWO DISTINCT thunk symbols (differing
`.argN.<mangled>` suffixes) — the executable pin of the collision fix,
autoupdate-owned like the rest. Movement prediction: ONLY this golden
moves — no existing golden passes a function to C++ (plan §4's novelty
claim); any other movement is stop-and-explain. _Conformance:_
cpp_thread_carbon_fn_diff un-SKIPs per its own SKIP protocol (body
uncommented — one mechanical reorder recorded: the sketch's `Work`
preceded `RuntimeSeed`, which Carbon's declare-before-use rejects, so
the two swapped; semantics untouched) and now carries the R-6 arbiter
shape: real `std::thread(Carbon fn)` with the observable seeded
fetch_add checked after `.join()`, plus (post-review B1) a second
same-signature function `Work2` on a second thread whose contribution
folds into the oracle total — a thunk-symbol collision would run one
body twice and diverge the printed sum. Floor 90/0/29 over 119
expected; bullets stay 43/56 (plan §6 — the threading bullet already
PASSes from F8b). _Verification status:_ nothing in this entry is
live-verified in-container — the golden CHECK content, the pair's PASS,
and the floor are all pending-CI, with the autoupdate regen
(fork/autoupdate-request.txt) and the conformance run as the arbiters.
_Pre-stated falsifier:_ if the regen churns any hand-pinned line this
entry had presented as settled, that is an R17 hit. **W-023 DISCHARGED
pending those arbiters** (ledger updated, plan §9); F-008 defect scope
closes with all three fixes landed, no degrade, zero net-new TODO
strings (plan §7). Veto-able.

### F-009: Function overloading — **Marked `overload fn`** (2026-07-19)

Closed same-library sets (p000998), declaration-order first-match
(p002875), explicit marker on every member (preserves p003763 typo
diagnostics), no value patterns in 0.1. Exported sets resolve under C++
rules: documented divergence with bidirectional conformance tests.
Rejected: unmarked sets, pattern-dispatch, no-overloading. Per
fork/design-sprint/function-overloading.md.

### F-010: Template structural conformance — **`template constraint` + `require`** (2026-07-19)

Implement accepted p000818/p002200 plus require validity blocks and
boolean predicates by way of probe-mode evaluation; two-way C++20 concept
mapping; adopts F-009's declaration-order/no-subsumption rule for
constrained candidates. Rejected: Go-style implicit satisfaction,
predicates-only. Per fork/design-sprint/structural-conformance.md.

### F-011: Combined match control flow — **`if (let ...)` + `let ... else`** (2026-07-19)

Positive form `if (let P = e)` (and while-let), negative form
`let P = e else { diverge }` filling p002188's reserved slot; enclosing-
scope bindings; syntactic divergence list in 0.1 (return/break/continue),
type-based noreturn rule deferred to safe-Carbon work. A future `?`
desugars onto this core per F-006. Rejected: is-expression flow scoping,
guard-let, match-only. Per fork/design-sprint/if-let.md.

### W4-S1: conformance scope trades for match slice 1 (2026-07-19)

Process/scope decision made by Claude during the trial run under standing
rule 6 (not a language-design divergence — the language semantics follow
`docs/design/pattern_matching.md` unchanged); recorded per process step 4
so the user can overrule. Slice 1 implements the `match` _statement_ with
an integer scrutinee, integer-literal `case` patterns, and a `default`
arm; everything else keeps a clean `semantics TODO` diagnostic. Trades:

-   **`control_flow/match_switch.carbon` narrowed to slice-1 arms** (literal
    cases + `default`, the honest C `switch` equivalent) and un-SKIPped so the
    bullet is scoreboard-arbitrated. The guarded-binding arm it previously
    carried moved to the new SKIP program
    `control_flow/match_guard_binding.carbon`, whose SKIP cites the exact
    `MatchCaseIntroducer` gate diagnostic (R10). Alternative rejected:
    keeping the guard arm would have left the bullet permanently SKIP during
    slice 1 with no executable arbiter for the switch-equivalent subset.
-   **`project/most_features_missing_match.carbon` kept SKIP** as the
    guarded-binding representative of that PARTIAL bullet, with its SKIP
    evidence refreshed to the post-slice-1 gate diagnostic, instead of the
    plan §7 alternative (rewrite to slice-1 arms + un-SKIP). Rationale:
    un-SKIPping it on slice-1 arms would double-count coverage
    match_switch.carbon already provides and overstate "most 0.1 features".
-   **Usefulness/redundancy diagnostics deferred**: duplicate or
    never-matching `case` literals (for example two `case 5` arms) are accepted in
    slice 1; runtime first-match-wins SemIR is design-correct, but
    `pattern_matching.md` ("We will diagnose... A pattern is not useful in
    the context of prior patterns") requires a diagnostic. Recorded as
    work item W-066, blocked on W-008 landing.
-   **Scrutinee gate**: only `Core.IntLiteral`, builtin integer types, and
    the `Int(N)`/`UInt(N)` adapters are in-slice. Other class types whose
    object representation is an integer (`Core.Char`, user adapter classes)
    are explicitly gated out to the scrutinee TODO — they have their own
    operator semantics and would break the slice's cleanup-soundness
    argument (adversarial finding F2).

_RF-4 landing note (2026-07-28):_ the match re-platform's RF-4 slice
(fork/match-replatform/plan.md) widens this section's "integer-literal
`case` patterns" to constant integer expression patterns. At the
integer-scrutinee expression-pattern gate in
toolchain/check/pattern_match.cpp ONLY, the TODO string
`` `match `case` pattern other than an integer literal, or a case guard` ``
becomes `` `match case expression pattern that is not a constant integer` ``;
the old string survives verbatim at its other six sites
(handle_match.cpp, handle_binding_pattern.cpp twice,
handle_let_and_var.cpp, pattern_match.cpp's choice-pattern fallback, and
handle_name.cpp's leading-dot designator gate — the last was missed in
this note's original count because the string literal is split across
two source lines there; corrected at S2b).
_RF-4 addendum (2026-07-28):_ the RF-4 autoupdate run exposed a
formatter CHECK-crash on initializing-category case expressions
(`case 2 + 3` — the prelude operator call returns through a return
slot, and a spliced region result must never be initializing-category).
Fixed in commit d9be8f4 by converting such expressions to values inside
the pattern's expression region before it closes, the same invariant
type expressions uphold by way of `ExprAsType`. This invariant is
load-bearing for all later slices. Veto-able.
Testdata: fail_todo_non_int_literal_case.carbon flips to the now-passing
negative_literal_case.carbon, and two files land alongside it —
constant_expr_case.carbon (admitted constant arithmetic) and
fail_todo_non_constant_case.carbon (runtime `var` reads and plain `let`
bindings stay behind the TODO). Recorded admission-semantics caveat from
review: admission is by constant representation (a concrete SemIR
`IntValue`), so a constant of an int-adapter class type is admitted and
produces a real missing-impl `==` operator error downstream rather than
the TODO — reviewed, no crash, deemed acceptable for RF-4 scope.
Implication for W-066 (usefulness diagnostics): constant-expression
admission creates invisible overlaps (`case 5` vs `case 2 + 3` on the
same scrutinee), so duplicate/overlap detection must compare evaluated
constant values, not source forms — noted on the work item. Veto-able.

_S2b landing note (2026-07-28):_ the match re-platform's S2b slice
(fork/match-replatform/plan.md §3.2) discharges this section's binding
gate for bare `name: type` case bindings: they check to a
`ValueBindingPattern` under `Kind::MatchCaseArm` and bind the scrutinee's
value in the arm's scope. The test pass contributes no condition
(bindings are irrefutable), so the arm's condition is a constant `true`
emitted by handle_match.cpp — keeping the first-match-wins CFG uniform —
and the bind pass runs `LocalPatternMatch` in the arm's body block, so
the binding is initialized only where the arm has matched. The TODO
string `` `match `case` pattern other than an integer literal, or a case
guard` `` is therefore no longer emitted at the plain-binding case gate
in toolchain/check/handle_binding_pattern.cpp, but survives byte-identical
at its remaining sites (handle_match.cpp's non-binding-root fallback, the
compile-time-binding and form-binding case gates in
handle_binding_pattern.cpp, handle_let_and_var.cpp's binding-free `var`
case pattern, pattern_match.cpp's choice-pattern fallback, and
handle_name.cpp's leading-dot designator gate — six in all; the
tuple-case and compile-time-binding sites are golden-pinned by
fail_todo_tuple_pattern.carbon). Per
§3.2(c), `var`-mode and `ref` case bindings stay gated behind a NEW
precise TODO string `` `var` or `ref` binding in match `case` pattern ``,
pinned to the binding itself (fail_todo_var_binding.carbon,
fail_todo_ref_binding.carbon). Other testdata: the now-compiling
fail_todo_binding_pattern.carbon flips to binding_pattern.carbon (multiple
arms, mixed literal+binding arms, `unused` modifier);
binding_choice_scrutinee.carbon binds a choice-typed scrutinee and
rematches it in a nested match (risks R-2/R-8);
fail_binding_scope.carbon pins sibling-arm and post-match leakage as
`NameNotFound` (§3.2(b)); fail_unused_case_binding.carbon pins
`UnusedButUsed` under the arm's implicit `let` introducer (§3.2(a));
fail_arm_conversion.carbon gains a bind-pass conversion-failure pin
(R-1); and the fail_todo_match subfile of
toolchain/check/testdata/patterns/unused.carbon — whose first case is a
`var`-mode binding — moves from the combined string at its `case` token
to the new `var`/`ref` string at the binding, the same §3.2(c) sanction. `default` stays required — an irrefutable binding arm does not yet
discharge exhaustiveness (S2e; _discharged there for choice scrutinees
only, 2026-08-08 — integer matches keep the requirement per SF-7_). SKIP
evidence refreshed for
control_flow/match_guard_binding.carbon and
project/most_features_missing_match.carbon: their guarded-binding arms
are now rejected at the guard's `if` token ("match case guard") instead
of the `case` token, and both un-SKIP only at S2d. Veto-able.

_S2b R-7 re-derivation (2026-07-28, post-review):_ the bind pass's
no-cleanups argument does not close from the scrutinee gate alone. The
gate guarantees the _scrutinee's_ type is trivially destructible (integer
types; an in-slice choice's payloads are restricted to trivially copyable
and destructible types when its representation completes), but the bind
pass's `Convert` targets the _binding's declared type_, which is not
gated: `case n: i64` on an `i32` scrutinee runs `Core.ImplicitAs` and
materializes a `Temporary` (convert.cpp `FinalizeTemporary` →
`AddInstWithCleanup`), registering a cleanup in the arm's Owned scope —
and destroy synthesis is live on this branch (`Destroy.Op` calls are
emitted at discharge; see toolchain/check/testdata/let/lifetime.carbon),
so discharge placement is real output. Fix applied per the `let`/`for`
precedent (handle_let_and_var.cpp, handle_loop_statement.cpp): the bind
pass now calls `scope_stack().DeferCleanups()` (handle_match.cpp), so
such a temporary is discharged by `MatchHandler`'s end-of-scope cleanups
at arm exit, not by the first arm-body statement's temporary-cleanup
discharge while the binding is live. Output-neutral for in-slice
testdata: `DeferCleanups` only raises the scope's ambient cleanup-depth
marker (scope_stack.h) and emits no insts, and a same-type bind
conversion registers no cleanup (value→value is a no-op; ref→value binds
a value without a `Temporary`), so no existing golden changes. Bounded
today by DeferCleanups plus the scrutinee gate — the binding-type hole
now yields correctly-placed end-of-arm destroys, not unsound ones. Must
be re-derived at S2c (payload destructuring adds non-integer
subscrutinees and per-element conversions). Two further recorded
nuances: the bind pass re-reads the scrutinee at _arm entry_ in the
arm's body block, not at match entry, so a reference-category scrutinee
is observed after earlier arms' tests ran — benign while tests are
effect-free, re-derive at S2d when guards can run arbitrary code between
tests; and fork/conformance/out/scoreboard.json is not hand-edited here —
its regeneration rides the landing autoupdate/merge gate (R9). Also
landed post-review:
toolchain/check/testdata/match/fail_todo_tuple_pattern.carbon re-pins
the surviving combined W4 TODO
string (a tuple-pattern root at handle_match.cpp's non-binding-root
fallback, and `case template n: i32` at handle_binding_pattern.cpp's
compile-time case gate), which had zero testdata pins after S2b's flips.
Veto-able.

_S2c landing note (2026-07-28):_ the match re-platform's S2c slice
(fork/match-replatform/plan.md §3.3) discharges W5-S2's payload
destructuring: `case .Ok(value: i32)` tests the scrutinee's discriminant
and, in the bind pass, extracts the alternative's payload tuple from the
payload region (`ClassElementAccess` field 1, then the alternative's tuple
field — the F-007k offset-0 overlap) and initializes each payload binding
through `LocalPatternMatch` on a `TuplePattern` root, in the arm's scope.
Parse gains the RF-5 dedicated form: `AlternativePatternStart` +
`AlternativePattern` node kinds, entered from `MatchCaseIntroducer` only
when the case pattern starts with `.` followed by an identifier
(leading-dot-only per SF-4); the `Period` token gains a virtual-node
allowance because the wrapper node shares the period with its bracketing
start node. **Name-to-index metadata (the W5-S1 review follow-up (2), now
DONE):** a `SemIR::ChoiceAlternative` side table
(`{name_id, index, payload_field_index, has_parameters}`) on
`SemIR::Class`, populated in declaration order when the choice definition
completes and imported with the class definition (names translated by
`GetLocalNameId`). It replaces `GetAlternativeDiscriminant`'s constant
excavation, which is DELETED from pattern_match.cpp together with its
cross-file `GetCanonicalFileAndInstId` walk — imported and reexported
choices resolve through the ordinary class import
(choice_scrutinee_imported/choice_scrutinee_reexported still pin those
paths, plus the new choice_payload_imported.carbon for payload metadata).
Sanctioned diagnostic changes, verbatim: the TODO string
`` `match case pattern destructuring a choice payload` `` is DISCHARGED —
both emission sites (bare `.Ok` and wrapped-designator, pattern_match.cpp)
are deleted. In its place: in-slice payload patterns compile; the
parens-iff-parameter-list rule (p2188:453-456) is enforced by two new
diagnostics, `` alternative `{0}` is declared with a parameter list, so its
pattern requires parentheses `` (MatchAlternativeMissingParens, bare `.Ok`
— this also supersedes the W5-S1 recorded gate that kept `case .On` for a
zero-payload `On()` behind the payload TODO: `.On()` now matches per SF-3
and bare `.On` gets this error) and `` alternative `{0}` is declared
without a parameter list, so its pattern cannot have parentheses ``
(MatchAlternativeUnexpectedParens, `case .Err()`); wrong arity gets
`` alternative pattern has {0} subpattern{0:s}, but alternative `{1}` is
declared with {2} parameter{2:s} `` (MatchAlternativeArgCountMismatch); a
non-binding payload subpattern (`case .Ok(42)`) gets a NEW precise TODO
`` `non-binding subpattern in match `case` alternative pattern` ``, pinned
to the subpattern. Span choice: all three new match-alternative
diagnostics anchor on the whole alternative pattern node — uniformity
over sharpness — with sharper sub-spans deferred to W-066's
diagnostics-quality work. The combined W4 string survives byte-identical at six
sites, but one site MOVES: handle_name.cpp's leading-dot designator gate
(the split-literal site) is deleted with the whole S2c-scheduled
DesignatorExpr node-stack hack (plan §1.2 F-Q1 residue), and the same
string with the same introducer-node pin is re-emitted from the
`AlternativePattern` check handler in handle_match.cpp (non-choice
scrutinee gate). `qualified alternative pattern in match case` and
`match case pattern on unsupported choice alternative shape` survive
verbatim (the latter now keyed on missing metadata rather than failed
excavation). _R-7 re-derivation for S2c:_ payload extraction itself
registers no cleanups — the `ClassElementAccess` chain is reference
projection into the scrutinee, and in-slice payload element types are
trivially copyable and destructible by the choice-completion gate — but
the bind pass's per-element `Convert` to each binding's DECLARED type is
ungated (the same S2b hole: `case .Set(n: i64)` on an `i32` payload runs
`Core.ImplicitAs` and can materialize a `Temporary` with a registered
cleanup, and destroy synthesis is live), so alternative-payload arms get
the identical `DeferCleanups` treatment as S2b binding arms: such
temporaries discharge at arm exit by `MatchHandler`'s scope cleanups, not
at the next statement while the binding is live. Re-derive at S2d, where
guards run arbitrary code between test and bind. Recorded deviations
(veto-able): (1) the alternative-pattern parse form is gated to the match
case ROOT position only, not all pattern positions as W5 plan §3.2.1
sketched — leading-dot in any other pattern position (function params,
`let`, nested in payload lists, `case (.Err)`) parses exactly as before;
alternative patterns are meaningless without a scrutinee-typed scope, and
F-011's if-let can widen the gate later. (2) Consequently unpinned inputs
of the S2a "more-honest diagnostics" class shift again: `case .Err ==
.Stop` now parses `.Err` as an alternative pattern and the trailing
operator is a parse error (expected `=>`), and `case .Self` takes the
ordinary expression route (`.Self` not in scope) since the lookahead gate
requires an identifier after the period; no golden or SKIP evidence pins
either. (3) A single parenthesized subpattern (`ParenPattern`) is wrapped
in a synthesized `TuplePattern` so payloads uniformly destructure through
upstream's tuple machinery. (4) Unknown alternative names get the standard
member-access diagnostic in both forms (`PerformMemberAccess` against the
choice scope; in the paren form its name-ref lands in a consumed,
unreferenced expr region). (5) `default` stays required — payload arms do
not discharge exhaustiveness (S2e; _discharged there, 2026-08-08: an
unguarded payload arm now covers its alternative_). (6) The paren-form discriminant test
is emitted by a free function (`MatchCaseAlternativePatternMatch`)
sharing `EmitChoiceDiscriminantTest` rather than entering the
`MatchContext` engine worklist as plan §2.1/RF-1 sketched — functionally
equivalent, same file (pattern_match.cpp); fold into the engine at S2d
when guards force it. Testdata:
fail_todo_choice_payload_pattern.carbon is renamed (git mv) to
fail_choice_alternative_pattern.carbon, its `.Ok(42)`/`.Ok` subfiles
re-pinned to the new TODO/diagnostics, qualified subfile unchanged, plus
new arity/parens/unknown-name/nested-designator fail subfiles; new
positive goldens choice_payload_pattern.carbon,
choice_payload_multi.carbon (multi-element, `.On()`, converting binding),
choice_payload_imported.carbon, lower/testdata/match/choice_payload.carbon
(the R-9 payload-GEP pin), and parse alternative_pattern goldens — all new
CHECK content rides the runner autoupdate (R15/R19). Conformance:
choice_payload_roundtrip_diff.carbon un-SKIPs (with a recorded
never-taken `default` arm until S2e); match_sum_type_payload.carbon keeps
only its interop half per the W5 plan §3.3 split, SKIP evidence refreshed
to the S4 blocker. Veto-able.

_S2d landing note (2026-07-29):_ the match re-platform's S2d slice
(fork/match-replatform/plan.md §3.4) gives `case` guards real semantics.
Sanctioned diagnostic change, verbatim: the TODO string
`` `match case guard` `` is DISCHARGED — all three emission sites (the
guard stub handlers in toolchain/check/handle_match.cpp) are deleted; a
guard expression that does not implicitly convert to `bool` now gets the
real `ConversionFailure` at the guard expression
(fail_guard_non_bool.carbon). The combined W4 string survives
byte-identical at its six sites, including its now-anachronistic "or a
case guard" tail — preserved verbatim per R10; rewording it is left to
the slice that discharges each remaining site. _CFG and sequencing:_ the
guard's nodes precede `MatchCase` in postorder while the pattern's
expression region is still pending, so `MatchCaseGuardIntroducer`
finishes the case pattern early (shared `FinishCasePattern` helper, root
recorded in the case-arm context) and captures the guard expression in
its own region, converted to `bool` inside the region
(`MatchCaseGuard`); `MatchCase` splices the region into the arm's body
block AFTER the bind pass — test → BranchIf → bind → guard →
BranchIf(body) — so the pattern's bindings are initialized and in scope
in the guard (p2188:543-544), and the guard-failure edge branches to the
SAME else block the pattern test falls through to (next arm's test or
the `default` body), preserving first-match-wins. Compound guards
(`and`/`or`) capture multi-block regions; the splice's branch path
handles them (plan §2.1). _Scope unwind on guard failure (R-7
re-derivation for S2d):_ guard evaluation and the bind pass can both
materialize cleanup-registered temporaries in the arm's Owned scope
(registered at capture/bind time; `DeferCleanups` keeps the body's
statement-level discharge off them). The failure edge leaves the arm's
scope, so it discharges the arm scope's cleanups itself —
`AddBranchWithCleanups` at the enclosing cleanup depth, emitted between
the guard's `BranchIf` and the `Branch` to the else block, so the
destroys run only on the failure path; the success path discharges the
identical set at arm exit (`MatchHandler`), and the two paths are
exclusive, so no double-destroy. Bind-pass conversion temporaries (the
S2b/S2c hole, for example `case n: i64` on an `i32` scrutinee) are live on the
failure edge — the binds ran before the guard — and are destroyed there
(guard.carbon's `Converting` fn pins the shape). One recorded nuance:
cleanups discharge in reverse REGISTRATION order, and a guard temporary
registers at capture time (before `MatchCase` runs the binds) while
executing after them, so a guarded arm's discharge destroys bind-pass
temporaries before guard temporaries — reverse-execution order would be
the opposite. Unobservable in-slice — every cleanup-registered object
here is of trivially-destructible integer shape — but revisit if
non-trivial destructors ever become registrable in a case arm.
_Engine-fold resolution
(supersedes S2c recorded deviation (6) "fold into the engine at S2d when
guards force it"):_ NOT folded, recorded as a sanctioned deviation
instead (R17: no ritual folds). Guards do not force it: the plan's own
sequencing places the guard AFTER the bind pass, in the dispatch-CFG
layer that §2.1 assigns to handle_match.cpp — the guard never
participates in the engine's test-pass worklist, so folding
`MatchCaseAlternativePatternMatch` into `MatchContext` would move code
into the engine with no consumer of the move. The free function stays
(same file, shares `EmitChoiceDiscriminantTest` with the engine's
expression-pattern path); the only S2d engine surface is the
`SpliceMatchCaseGuard` wrapper over the existing `InsertHere`. Revisit
only if a later slice needs guard state inside the worklist (none
planned; S2e reads arms, not the engine). _Ref-category scrutinee
(discharges the S2b "revisit at S2d" note):_ the arm-entry re-read is
KEPT and is the correct semantics. Within one arm, no user code runs
between the test and the bind (the guard runs after both), so test and
bind cannot disagree about a reference-category scrutinee's state.
Across arms, a guard that mutates the scrutinee's object through a
reference is ordinary sequential execution: the next arm's test AND bind
both re-read at that arm's entry, so they stay mutually consistent — a
choice scrutinee mutated to a different alternative by a failed guard is
re-tested against the NEW discriminant before any payload extraction,
which is exactly what prevents test/extraction type confusion. The
design supports this: pattern_matching.md:190-204 defines bindings as
aliases of the converted scrutinee expression and requires `ref`-binding
scrutinees to remain durable references — snapshotting the scrutinee's
value at match entry would break that model; neither pattern_matching.md
("Guards") nor p2188:552-554 prescribes any scrutinee freeze across
guard evaluation. _Scope trade re-recorded:_ guards on `default` clauses
(p002188:552-553, pattern_matching.md:814-815) remain unimplemented —
the fork's parser has no `default`-guard production — now tracked as
work item W-067. Testdata: fail_todo_guard.carbon flips (git mv) to
guard.carbon (guarded literal arm, guarded binding arms using their
bindings with fall-through chaining, multi-block `and` guard, converting
binding under a guard); new choice_payload_guard.carbon (guard over a
payload-destructured binding, same alternative matched twice — once
guarded, once unguarded); new fail_guard_non_bool.carbon; new CHECK content
rides the runner autoupdate (R15/R19). Expected golden churn: ONLY the
guard files — unguarded arms take a byte-identical code path (the
`FinishCasePattern` refactor is behavior-preserving and the guard CFG is
emitted only when a guard region exists). Conformance:
control_flow/match_guard_binding.carbon and
project/most_features_missing_match.carbon un-SKIP (PASS floor 74 → 77);
differential pair match_guard_diff.carbon/.diff.cpp added (guard chain
vs C++ `if`/`else if` with `&&` mirroring the short-circuit `and`);
README program table regenerated; scoreboard regeneration rides the
landing gate (R9). No new lower golden: plan §7 schedules none for S2d,
failure-edge destroys are vacuous in-slice (trivially destructible
integer shapes), and runtime behavior is locked by the match_guard_diff
differential pair; revisit with the same trigger as the
cleanup-ordering nuance. Veto-able.

_S2e landing note (2026-08-08):_ the match re-platform's final slice
(fork/match-replatform/plan.md §3.5) makes `match` exhaustiveness real for
choice scrutinees, discharging SF-7's closed-set rule. _Mechanism:_ a
per-statement coverage context (`Context::MatchStatementContext`, a stack
because matches nest) is pushed by `MatchStatementStart`; each arm's
`MatchCase` records what its already-classified pattern covers — an
unguarded alternative-pattern arm covers its alternative's discriminant
(the index the S2c `SemIR::ChoiceAlternative` metadata resolved), an
unguarded binding-pattern arm is irrefutable and covers everything, and a
GUARDED arm covers nothing whatever its pattern, because exhaustiveness
assumes every guard can evaluate to false (pattern_matching.md,
"Refutability, overlap, usefulness, and exhaustiveness" — the S2d
guarded-arm-never-irrefutable rule made observable by
fail_choice_nonexhaustive.carbon's fail_guarded_binding subfile);
`MatchStatement` pops the context and, when there is no `default`, compares
coverage against the choice's full alternative table. Sanctioned diagnostic
changes, verbatim: a covered choice match without `default` now compiles; a
non-exhaustive one gets the NEW real error
`` `match` on choice {0} has no `default` arm and does not cover
alternative{1:s} {2} `` (MatchNonexhaustive; {0} the unqualified scrutinee
type, {2} the uncovered alternatives in declaration order, each formatted
`` `.Name` `` and joined with ", " — one diagnostic naming the set, per
plan §3.5; upstream has no list-diagnostic precedent to follow, so the
joined-string shape mirrors SemanticsTodo's std::string argument). The TODO
string `` `match statement without `default` arm` `` survives
byte-identical but is NARROWED to integer scrutinees (SF-7: "W4's rule
stays for integer matches") — deliberately including an integer match whose
only arm is an irrefutable binding, which is genuinely exhaustive by the
design but keeps the TODO as a recorded conservative gate (pinned by
fail_todo_no_default.carbon's new fail_irrefutable_binding_arm subfile;
narrowing rides future integer-exhaustiveness work under W-008). _CFG (the
final-arm else edge):_ no new machinery. Without a `default`, the last
arm's else block — always a real branch target of that arm's test — is the
top of the instruction block stack at `MatchStatement`, so the existing
`num_case_arms + 1` convergence (`AddConvergenceBlockAndPush`) pops it as
the +1 that used to be the `default` body and emits its single `Branch` to
the resumption block: the else edge of an exhaustive match is dynamically
dead but statically wired, byte-for-byte the shape an empty
`default => {}` body block produces, and lowering sees no dangling edge.
_R-7 re-derivation for S2e:_ exhaustiveness adds analysis, not runtime
temporaries — the coverage recording reads already-computed per-arm state
and the only new emission is the diagnostic; no inst, conversion,
temporary, or cleanup is created on any new path, so the S2b-S2d cleanup
discipline carries over untouched, and matches WITH `default` take a
byte-identical check path (the coverage context push/pop emits nothing).
Recorded deviations (veto-able): (1) choices with fewer than two
alternatives stay behind the scrutinee gate — §3.5 sanctions only the
`MatchStatement` analysis (see the inline note on the W5-S1 bullet; new
work item W-068). (2) §3.5's "sum_types.md example compiles" is met modulo
genericity: the doc's example matches a generic `Optional(i32)`, and
generic-choice scrutinees remain gated (W5-S1, S3's re-plan); the same
match shape over a concrete choice compiles without `default`
(exhaustive_choice.carbon's payload subfile). (3) An EMPTY alternative
table at the exhaustiveness analysis is a graceful bail, not a
CARBON_CHECK or a TODO: a valid choice with two or more alternatives
always builds its name-to-index table alongside the integer discriminant,
so an empty table is USER-REACHABLE only under error recovery — a choice
whose alternatives were ALL rejected with a diagnostic (for example every
payload names an unknown type) gets no table entries, yet the declared
alternative count still sizes a real discriminant, the class completes,
and the scrutinee passes its gate; with only a guarded arm, neither the
error-arm nor the irrefutable-arm suppression fires. The analysis then
returns without diagnosing — coverage is unknowable and the declaration
already carries its own diagnostics — mirroring the error-arm
suppression (pinned by fail_choice_nonexhaustive.carbon's
fail_all_alternatives_rejected subfile, whose expected STDERR is the
declaration's NameNotFound pair and NO nonexhaustive error). Nuance: a
PARTIALLY-errored choice keeps table entries for its surviving
alternatives, so coverage is computed over those only — deliberate
error-recovery behavior, consistent with how references to rejected
alternatives resolve. (4) No lower golden: plan §7
schedules none for S2e, the exhaustive no-default CFG is inst-identical to
an empty-`default` match at the SemIR level, and runtime behavior is
locked by the un-defaulted choice_payload_roundtrip_diff differential
pair. (5) An arm whose pattern contained an error suppresses the
nonexhaustive diagnostic — coverage is unknowable and the arm already
carries its own error, so staying silent avoids a cascading diagnostic;
§3.5 does not sanction this suppression, recorded here. Files touched
beyond plan §7's list: toolchain/check/context.{h,cpp} — the
`Context::MatchStatementContext` stack and its `VerifyOnFinish`
empty-check — disclosed as the coverage-context mechanism above.
Testdata: new exhaustive_choice.carbon (payload-free, payload — the
sum_types.md shape, guarded-duplicate, still-legal never-taken
`default`, and an imported-choice pair — signal library + use_imported —
per choice_scrutinee_imported.carbon's conventions),
exhaustive_choice_binding.carbon (irrefutable final
arm; single binding-only arm), fail_choice_nonexhaustive.carbon
(missing-one singular, missing-many plural in declaration order,
guarded-only-cover, a guarded binding arm covering nothing — the
guarded-arm-never-irrefutable pin — the all-alternatives-rejected
empty-table pin, and an imported-choice pair — signal library +
fail_imported_nonexhaustive), fail_todo_single_alternative_choice.carbon
(single-alternative and empty-choice scrutinees stay gated);
fail_todo_no_default.carbon splits into integer subfiles per §3.5
(fail_literal_arms, fail_irrefutable_binding_arm); the choice shape is
NEW in fail_choice_nonexhaustive.carbon (fail_todo_no_default had no
choice shape to move). Every failing subfile ships with hand-written
CHECK:STDERR pins (house precedent: S2c/S2d landed their new diagnostics
hand-pinned), so the intended text is reviewed rather than derived from
the implementation; the runner autoupdate remains the corrector for any
rendering detail, and STDOUT dump content rides it as before (R15/R19).
Expected golden churn: ONLY the new files
plus fail_todo_no_default.carbon's subfile split — no existing match
loses its `default`, and defaulted matches are byte-identical.
Conformance: choice_payload_roundtrip_diff.carbon drops the never-taken
`default` recorded at S2c for exactly this slice (comment + arm; PASS
before and after), choice_payload_construct.carbon's stale
"exhaustiveness arrives in slice 2" comment refreshed (its `default` is a
live arm and stays); no SKIP flips — scoreboard stays 77 PASS / 0 FAIL /
31 SKIP over 108 programs; runner.py --self-test OK; scoreboard
regeneration rides the landing gate (R9). Veto-able.

_W-067 landing note (2026-08-18, the W-067 implementer):_ guards on
`default` clauses (`default if (E) => ...`), the S2d scope trade recorded
at fork/match-replatform/plan.md §3.4 and tracked as W-067. _Design
authority, verified before building (R17):_ pattern_matching.md:814-815
and p002188:552-553 both say, verbatim, "For consistency, this facility is
also available for `default` clauses, so that `default` remains equivalent
to `case _: auto`" — no contradiction with the ledger. _Parse:_ the
`default` introducer now takes the case arm's optional guard production —
extracted into a shared `HandleMatchGuard(context, has_error, label_kind)`
helper (parse/handle_match.cpp) so the `ExpectedMatchCaseGuardOpenParen`
diagnostic stays declared once and the malformed-guard recovery is
parameterized only by the label node kind; the unguarded `default` path is
byte-identical to before. A guarded `default` gets its OWN label node kind
`MatchGuardedDefault` (bracketed by `MatchDefaultIntroducer`, children =
introducer + the existing `MatchCaseGuard` subtree, closed by the new
`MatchGuardedDefaultStart` state), rather than an optional guard child on
`MatchDefault`: the two arms diverge in every consumer — node-stack id
kind (`InstBlockId` else-block entry vs solo), scope-push site, terminal
vs continuing arm — so a distinct kind keeps every dispatch typed instead
of threading a guarded-ness bit through the node stack (R17: the
one-sentence version is "different behavior, different node kind", the
`MatchCase`/`MatchDefault` split's own precedent). _Arms after a guarded
`default`:_ ACCEPTED, by one-token `default`+`if` lookahead in
`MatchCaseLoop` (the `.`+identifier lookahead in the same file is the
precedent). The design's usefulness rule assumes "a guard on any pattern
in the context set ... to evaluate to false" and speaks of "a prior
`default`" (pattern_matching.md, "Refutability, overlap, usefulness, and
exhaustiveness"), so arms after a guarded `default` are reachable and
useful; only an unguarded `default` ends the arm list, keeping
`UnreachableMatchCase` byte-identical at its site
(fail_cases_after_default.carbon unchanged). _Check:_ exactly the ledger's
shape — the S2d capture-splice-branch with no pattern test and no
bindings. `MatchCaseGuardIntroducer` recognizes the `default` case by the
introducer entry the (now node-pushing) `MatchDefaultIntroducer` handler
leaves on the node stack, pushes the arm's Owned scope there (a case arm's
comes from `MatchCaseIntroducer`; `MatchHandlerStart` pushes only for
unguarded `MatchDefault`), and pushes a pattern-less case-arm context for
the shared `MatchCaseGuard` handler to record the guard's bool-converted
region into (scrutinee type deliberately not recorded — only case
patterns resolve against it). `MatchGuardedDefault` then emits the
guarded-irrefutable-arm CFG minus `NameBindingDecl` and bind pass:
constant-`true` test entering the arm (the `MatchCase` binding-arm
condition), `SpliceMatchCaseGuard`, `DeferCleanups`, `BranchIf` into the
body, and `AddBranchWithCleanups` to the else block at the enclosing
cleanup depth — the guard-failure edge discharges the arm scope's
cleanups and falls through, first-match-wins preserved; `MatchHandler`
and `MatchStatement` treat the arm as an ordinary case arm (else-block
entry, convergence count). _Exhaustiveness interaction (the ledger's
explicit requirement):_ a guarded `default` records NOTHING into
`Context::MatchStatementContext` and never pops as `MatchDefault`, so it
does not discharge the `default` requirement. _Dangling else edge
(guarded `default` followed by nothing):_ the design authority is SILENT
on the shape, so per the slice brief the diagnosis path REUSES the
existing mandatory-default machinery unchanged (R6, no new diagnostic):
integer scrutinee — the SemanticsTodo `` `match statement without
`default` arm` `` gate; choice scrutinee — `MatchNonexhaustive` naming
the uncovered alternatives; a choice fully covered by unguarded arms
around a guarded `default` legitimately compiles (coverage sums across
it). Recorded decision, veto-able. _Testdata:_ parse
guarded_default.carbon (guarded defaults between arms and last),
fail_missing_default_guard_open_paren.carbon +
fail_missing_default_guard_close_paren.carbon (mirroring the case-guard
fail pair); check guarded_default.carbon (basic chain with a case arm and
a second guarded default after the first, compound `and` guard on
`default`, choice coverage across a guarded default) and
fail_guarded_default.carbon (integer no-covering-arm TODO pin,
choice-uncovered MatchNonexhaustive pin, non-bool `default` guard
ConversionFailure pin). Positive files ship with AUTOUPDATE and no CHECK
lines; fail files carry hand-written CHECK:STDERR pins only (house
precedent per the S2e note); all golden content rides the runner
autoupdate to R26 fixpoint (R15/R19: red-first is expected). Expected
golden churn: ONLY the new files — unguarded arms and unguarded defaults
take byte-identical paths (the case-guard helper extraction and the
`MatchDefaultIntroducer` node-stack push change no emitted SemIR).
_Conformance:_ new run program
control_flow/match_guarded_default.carbon (guard-true takes the `default`
arm; guard-false falls through to a LATER case arm and the final
unguarded `default`; inputs runtime-computed by way of the RuntimeSeed x+20
convention, R16d); README table regenerated; --self-test OK (121
programs). Expected floor: EXACTLY 92 PASS / 0 FAIL / 29 SKIP over 121,
moving only by the new program's PASS — any other movement re-opens
W-067 (R9 hedge; status DISCHARGE-STAGED in the inventory). No lower
change: the guarded-default CFG uses only inst kinds S2d already lowers,
and runtime behavior will be locked by the new run program at the
conformance run, next to the existing match_guard_diff differential
pair. Veto-able.

_W-067 review-round amendment (2026-08-18, the W-067 fixer):_ both
adversarial reviews returned clean — no blockers, no code defects. Two
coverage additions landed at the review round and ride a follow-up
autoupdate pass: a positive falsifier subfile in check
guarded_default.carbon (trailing_guarded_default.carbon — a choice fully
covered by unguarded arms plus a TRAILING guarded `default`, pinning the
guard-failure edge's convergence into the statement's top empty else
block), and a parse recovery golden
fail_default_guard_recovery_midlist.carbon (malformed `default` guard
mid-list; the arm loop continues and later arms still parse). For the
record: the parenthesized-guard spelling (`if (E)`, vs the design
grammar's parenless `if expression`) is the inherited S2d deviation
recorded at fork/match-replatform/plan.md §3.4 — cross-referenced here,
not a new W-067 choice. Correcting a ledger/log drift: the
pattern_matching.md line-cite for the `default`-guard sentence is
813-815 (the landing note above says 814-815; the inventory already
says 813-815). Reviewer A's process gate — discharge evidence
outstanding at review time — rides the in-flight gate+conformance runs
per the landing note's R9 hedge. Veto-able.

_W-067 discharge confirmation (2026-08-18, coordinator):_ every staged
condition is met and **W-067 is DISCHARGED**. The evidence chain:
autoupdate reconciled the four implementation goldens (run 32110931780,
+1033 CHECK lines) and the two review-round additions (run 32112294566,
+411 lines), each confirmed at R26 fixpoint by an empty second pass
(32111055736 / 32121167408); the gate is GREEN
(<https://github.com/jmann345/carbon-lang/actions/runs/32121303702>) —
its first attempt (32111182653) died at the ~07:33Z runner outage with
the test step mid-flight and no logs (diagnosed infra, not a test
failure; the re-fire after the runner returned ~09:20Z passed the full
`bazel test //toolchain/...`); the conformance run
(<https://github.com/jmann345/carbon-lang/actions/runs/32111182558>)
landed the floor at EXACTLY **92 PASS / 0 FAIL / 29 SKIP over 121**,
moving only by control_flow/match_guarded_default.carbon's PASS on the
already-PASS match bullet. Guarded `default` clauses are now a working
fork feature under the design's own license. Veto-able.

_W-068 landing note (2026-08-18, the W-068 implementer):_ `match` over
choices with FEWER than two alternatives — the W5-S1 scope trade
re-recorded at S2e and tracked as W-068. _Gate:_ the scrutinee gate
(`MatchCondition`), the alternative-pattern gate (`AlternativePattern`),
and `MatchStatement`'s choice-vs-integer exhaustiveness split now ask a
new `IsMatchableChoiceType` (pattern_match.cpp): the same F-007k repr
walk `GetChoiceDiscriminantType` performs — factored into a shared
`GetChoiceDiscriminantFieldType` so the two queries cannot drift — but
accepting an integer OR empty-tuple `.discriminant` field. Any other
field type still fails safe, the all-payloads-rejected error repr still
degrades at the gate (choice_generic_payload_scrutinee.carbon's
fail_all_payloads_rejected pin is untouched), and
`GetChoiceDiscriminantType` keeps its integer-only contract for its other
consumer (the `?` desugar, handle_question.cpp — out of scope here).
_Dispatch:_ where no integer discriminant exists there is nothing to
test, so the alternative arm's condition is a constant `true` by way of
`MakeBoolLiteral` — exactly the condition shape binding arms and W-067's
guarded `default` already lower — in both the payload-arm path
(`MatchCaseAlternativePatternMatch`) and the payload-free designator path
(`DoMatchCaseExprPattern`); payload extraction is untouched and real
(`GetChoicePayloadInfo` never required the integer discriminant, and the
bind pass reads the payload region exactly as for multi-alternative
choices). _Exhaustiveness:_ NO coverage arithmetic changed, as the ledger
predicted — one alternative is covered by its one unguarded arm, and an
empty choice's legitimately-empty alternative table leaves nothing
missing, so `DiagnoseNonexhaustiveMatch`'s empty-table bail is now
documented as also being the correct vacuous-exhaustiveness answer (the
same no-diagnostic outcome the loop would compute). _EMPTY-CHOICE LANE
(the recorded decision):_ scrutinee-TYPE admission only, keeping parse's
at-least-one-arm requirement — the zero-arm spelling `match (e) {}`
remains the `ExpectedMatchCases` parse error. Grounding: the design docs
define exhaustiveness over pattern sets and give NO zero-arm grammar
(pattern_matching.md, "Refutability, overlap, usefulness, and
exhaustiveness"), and empty-choice VALUES are unconstructible by
construction — handle_choice.cpp deliberately gives an empty choice a
`()` discriminant field so "there's no way to construct the Choice
(which can be a useful type)" — so a zero-arm body would be
design-unsanctioned syntax for an unreachable statement; minting a
fork-only grammar extension for it fails R17's one-sentence-justification
bar. Vacuous exhaustiveness is still REAL and pinned: a
guarded-`default`-only match over an empty choice compiles with no
unguarded `default` (empty_choice.carbon's guarded_default_vacuous
subfile), while the same shape over a non-empty choice stays diagnosed
(fail_choice_nonexhaustive.carbon). The zero-arm grammar question is
recorded here as design residue, deliberately NOT a fork work item.
_Construction side (verified):_ single-alternative construction landed
long ago — constant alternatives by way of the empty-tuple discriminant `let`
and payload alternatives by way of the composed constructor (W5-S1 review
F-A1's choice/single_payload_alternative.carbon, check+lower; generic
payload synthesis at S3b) — so this slice is consumption-only; empty
choices are the uninhabited case. _Testdata:_ check
single_alternative_choice.carbon (git mv from
fail_todo_single_alternative_choice.carbon: constant alternative
exhaustive one-arm match + construction, payload alternative with real
extraction, `default`-only, and the W5-S3 composition — a
single-alternative generic payload specific), empty_choice.carbon
(`default`-only + the vacuous-exhaustiveness guarded-`default` pin),
choice_generic_scrutinee.carbon's two fail_todo subfiles flipped positive
(single_alternative_specific + empty_choice_specific — the ledger's
must-flip pins), fail_choice_nonexhaustive.carbon gains
fail_single_alternative_guarded (a guarded-only arm still leaves the one
alternative uncovered: MatchNonexhaustive naming `.TheOnlyOption`);
lower single_alternative_choice.carbon pins the new dispatch shape at
lowering (no discriminant load/icmp, constant-true branch, real payload
GEP — the discriminating counterpart of lower/match/choice_payload.carbon).
Positive files ship with AUTOUPDATE and no CHECK lines; the fail subfile
carries hand-written CHECK:STDERR pins only (house precedent per the
S2e/W-067 notes); all golden content rides the runner autoupdate to R26
fixpoint (R15/R19: red-first is expected — the R16a hook fired on the
fail-pin additions and fail_todo removals, both sanctioned flip shapes).
_Conformance:_ new run program
control_flow/match_single_alternative.carbon (single-alternative payload
consumption with RuntimeSeed x+20 runtime-computed payloads per R16d —
expected prints 42/7/5 derived from the seed arithmetic, never from
running the toolchain — plus the payload-free one-arm match and the
compiled-but-uncallable empty-choice consumer); README table
regenerated; --self-test OK (122 programs). Expected floor: EXACTLY
**93 PASS / 0 FAIL / 29 SKIP over 122**, moving only by the new
program's PASS — any other movement re-opens W-068 (R9 hedge; status
DISCHARGE-STAGED in the inventory). Veto-able.

_W-068 review-round amendment (2026-08-18, the W-068 fixer):_ Both
adversarial reviews came back clean: reviewer A APPROVE with zero
should-fixes after tracing every caller of the new gate, reviewer B no
blockers with the R16a flip-sanction independently verified against the
old fail_todo pins. CI evidence chain: fast compile run
<https://github.com/jmann345/carbon-lang/actions/runs/32123492856>; the
runner autoupdate run
<https://github.com/jmann345/carbon-lang/actions/runs/32123657954>
reconciled the goldens (+1311 lines) with a NO-COMMIT pass-2 fixpoint run
<https://github.com/jmann345/carbon-lang/actions/runs/32123793539>; the
gate ran GREEN
(<https://github.com/jmann345/carbon-lang/actions/runs/32123926260>); the
conformance run
(<https://github.com/jmann345/carbon-lang/actions/runs/32123926356>)
landed the floor at EXACTLY **93 PASS / 0 FAIL / 29 SKIP over 122**,
moving only by control_flow/match_single_alternative.carbon's PASS.
Reviewer A's residual "asserted, not executed" risk is discharged by
these runs, including B's verification that the reconciled lower golden
shows the claimed no-discriminant dispatch shape (`br i1 true`, no icmp,
real payload GEP). _Hook-environment note (flagged by the implementer;
the landed diff dropped it):_ the container's distro clang-format is
18.1.3 while the R18 edit-hook comment claims it matches CI — CI pins
21.1.8 — and the implementer installed the pinned version manually;
recorded here so the next slice doesn't rediscover it (a hook-environment
fix is follow-up material, not this slice's scope). _Corrections of
record:_ (1) the landing note's "flipped (git mv)" overstates — git
records the flip as delete+add with a substantial rewrite (2 → 4
subfiles, coverage added, nothing lost; the old fail_empty_choice
territory is covered by empty_choice.carbon); (2) the landing note's R17
citation for the zero-arm cut was a stretch — the actual grounding (no
design grammar + deliberately unconstructible values) stands alone.
_Accepted residue (recorded, not actioned):_ two stale golden header
comments still name `GetChoiceDiscriminantType` where the gate now reads
`IsMatchableChoiceType` (check/testdata/match/choice_generic_scrutinee.carbon:16
and choice_generic_payload_scrutinee.carbon:78) — comment-only staleness;
a retext rides any future touch of those goldens rather than costing a
regen round now. _Inventory hedge parity:_ W-008's fewer-than-two
sentence now carries the run-evidence qualifier (gate 32123926260 +
conformance 32123926356 green) for parity with W-010's wording, and the
W-068 entry's silently-shortened scope sentence and W5-S3a pin-flip
obligation are restored with explicit amendment markers. Veto-able.

_W-068 discharge confirmation (2026-08-18, coordinator):_ Every staged
condition is met: the landing runner autoupdate reconciled the
new/flipped goldens (run 32123657954) and pass 2 confirmed the R26
NO-COMMIT fixpoint (run 32123793539); fast compile green (run
32123492856); the gate ran GREEN (run 32123926260); and the conformance
floor moved to EXACTLY **93 PASS / 0 FAIL / 29 SKIP over 122** (run
32123926356) with the movement being ONLY the new program
control_flow/match_single_alternative.carbon's PASS. **W-068 is
DISCHARGED.** Veto-able.

_W-069 W69a landing (2026-08-18, the W69a implementer):_ the scalar half
of the approved lane (a1) is staged per fork/w069/plan.md §4 —
lowering-only, SemIR untouched, import_ref.cpp untouched. _Mechanism:_
`FileContext::RegisterGlobalLetBindings` (a `PrepareToLower` pre-pass, so
the registry exists in every module that can reference the file) selects
package-scope VALUE bindings (`GetExprCategory == Value`, excluding
`let ref`; aliases can't be runtime-valued; class-scope statics stay out
of scope) whose bound value is NotConstant, and dispatches on
`ValueRepr`: `IsCopyOfObjectRepr` Copy → Promote (named global, mangled
by the new `Mangler::MangleGlobalLetBinding` — `_C` + name +
inverse-qualified scope + private-to-library fingerprint of the BINDING
inst, both sides feeding the same input); `None` → no storage,
references served as the empty value; pointer/custom (or a bound-value
chain the chase can't map to a ctor-resident initializer, or one whose
terminal is itself constant) → Declined. `PrepareGlobalLetDefinitions`
(defining side only) zero-initializes the definitions and schedules the
stores; the `__global_init` `LowerInst` tail hook emits each store right
after the binding's ctor-resident initializer lowers (so later
initializers already observe it), lowering the file-top-block wrapper
chain (`converted`/`value_of_initializer`/`acquire_value`/`temporary`/
`tuple_access`/`struct_access`) on demand; a post-ctor CHECK guarantees
no scheduled store is silently dropped (the "promoted or diagnosed,
never a silent zeroinit" invariant); `GetValue`'s fall-through — entered
ONLY when the constant path would have CHECK-crashed, so every
previously-green path is bit-identical — serves same-file references by way of
the value-id key and imported references by way of
`SemIR::GetCanonicalFileAndInstId` (the SF-1 amendment), then loads from
the get-before-create global (F8c discipline; R-2's
`AddGlobalToCurrentFingerprint` on every hit). Declined shapes
CARBON_FATAL with a named "semantics TODO ... (W-069)" message instead
of the cryptic missing-value CHECK. _Probes staged (autoupdate fills):_
check+lower `testdata/let/global_runtime.carbon` (P-1 scalar, P-2
cross-file + the A/B/main re-export subfile, P-7 tuple pattern, P-8
`let ref` exclusion pin, P-9 empty-tuple no-storage pin), lower
`testdata/let/global_runtime_symbols.carbon` (the R-1 falsifier:
defining file + two importers + private let — any `.N` symbol is the
alarm), and the P-6 flip in upstream's lower/testdata/var/import.carbon
(`fn X() -> i32 { return x; }` added, the :47 TODO deleted; prediction:
green already by way of half (b)'s constant import — regeneration rides the
runner per R16a). _Expected golden movement:_ the three let goldens fill
from empty CHECK; var/import.carbon regenerates (new `X` function; no
other module content should change); every OTHER file under
toolchain/**/testdata must be byte-identical in the PR diff — that audit
is this slice's negative pin. _Floor:_ no movement claimed, 93/0/29 over
122 (goldens only; the runtime arbiters land at W69b after W69h).
_Recorded deviations (R17, for coordinator adjudication):_ (1) the SF-1
amendment's `export x;` re-export golden form is UNCHECKABLE today —
`export x` of a runtime let mints an `ExportDecl` whose constant is
NotConstant, and import_ref.cpp:4483's non-constant branch
`CARBON_CHECK(Is<AnyBinding>...)` fails on ExportDecl — so P-2's
re-export subfile uses the `export import library` form (import-chain
hops; checks clean by way of half (b)); the chase's ExportDecl arm is
implemented but not golden-pinned, and pinning it needs an import_ref.cpp
amendment with its own review round (§5 step 3(ii) STOP honored —
import_ref.cpp has zero changed lines). (2) The plan's "(a3) diagnostic"
demotion is realized as loud named CARBON_FATALs plus silent
declination at declaration (never at reference), because lowering has no
diagnostic emitter and runs only on error-free SemIR — a true user-facing
diagnostic would be a check-side change outside W69a's file list; if the
coordinator wants the check-time diagnostic of §2.3, that is a dated
plan amendment, not this slice. (3) `let x = <var member>` shapes whose
initializer chain bottoms out in a CONSTANT reference (no ctor-resident
key) are Declined, not promoted — recorded as in-scope-for-later residue
under §5 step 4. Veto-able.

_W69a review+fill round (2026-08-18, the W69a fixer):_ both adversarial
implementation reviews APPROVE — reviewer A: the reachability invariant
(`GetValue`'s fall-through entered only where the old CHECK crashed) is
proven structurally, the mangler's two-sided agreement (defining and
importing sides feeding the same binding-inst fingerprint input) is
verified, no F8c-shaped name split is possible; reviewer B: the
import_ref.cpp/runner.py fence held (zero changed lines), the three R17
deviations are genuine discoveries, no cheating found. _CI chain:_
runner autoupdate fill run 32136846740 (commit 535680c, +536/−12) →
R26 NO-COMMIT fixpoint run 32136984670 → gate GREEN run 32137118870 →
conformance GREEN run 32137118887 at the byte-exact floor **93/0/29
over 122**. _Fill audit:_ the fill touched THREE files, not the
predicted four — lower let/global_runtime.carbon and
let/global_runtime_symbols.carbon filled from empty CHECK, and
var/import.carbon regenerated (the P-6 flip produced the new `_CX.Main`
function and no other module movement). **The landing note's "three let
goldens fill from empty CHECK" prediction FAILED for
check/testdata/let/global_runtime.carbon: it did not fill and remains
CHECK-free** — the check component's default args are
`--dump-sem-ir-ranges=only` and the file marks no `//@dump-sem-ir-begin`
ranges, so its dump output is EMPTY and autoupdate had nothing to
insert; the golden therefore pins clean checking only, NOT the SemIR
shape its header claimed (header reconciled in place; adding dump
ranges is W69b evaluation material). Load-bearing predictions HELD:
exactly one `_Cx.Main` across the A/B/main re-export chain (one
defining `global i32 0`, two `external global` decls); zero
`.N`-suffixed symbols anywhere in the R-1 falsifier (the only `.2` is
the prose citation of the F8c incident); no `_Ce`/`_Cr` globals; the
private-let fingerprint present (`_Chidden.Main.b2b5bfc054bc42f8`, 3
sites: definition, store, load). _P-8 (`let ref`):_ the fill records
`UseR` loading straight from `@_Cv.Main` — the reference-category
exclusion held and the reference rides the variable's own storage; the
subfile comment already matched, no reconciliation needed. _P-9
(NoStorage):_ reviewer A NIT-3's dead-arm prediction is CONFIRMED — a
runtime call of empty tuple type converts to a value carrying
`[concrete = constants.%empty_tuple]` (pinned in
check/testdata/basics/dump_sem_ir_ranges.carbon), so `e`'s bound value
is CONSTANT, fails the pre-pass NotConstant gate, never registers, and
rides the constant path; the `NoStorage` disposition arms (pre-pass
dispatch and `TryEmitGlobalLetValue`) are unexercised defensive
residue, and the empty-subfile probe comments were reconciled to say
so. _Hardening (landed THIS round, ride the NEXT gate round before
W69h):_ (1) `EmitGlobalLetStores` now CHECKs
`ctor_context.HasLocal(binding.value_id)` before the store, naming the
binding — a failed chain lowering can no longer route `GetValue` back
through `TryEmitGlobalLetValue` and store the zeroinit global into
itself while satisfying the post-ctor count (review B SF-1); (2) the
pre-pass chase's `Temporary` arm now demotes to Declined when the
`storage_id` (`TemporaryStorage`) inst is neither ctor-resident nor
constant — the shape the hook cannot lower (on-demand `GetValue` of an
unlowered `TemporaryStorage` would hit the generic missing-value
CHECK) now demotes at pre-pass per the plan invariant (review A SF-1;
the fill proves the shape does not occur today). _W-074 attribution
corrected:_ the `CARBON_CHECK(Is<AnyBinding>)` at import_ref.cpp:4483
PREDATES W5-S3b (upstream-era CHECK at the shallow-clone boundary,
present in the initial import of the file); S3b added only the
bound-constant resolution logic beneath it. _Accepted, not actioned:_
A NIT-2 (an exotic non-Value runtime binding shape keeps the old
missing-value CHECK — loud, acceptable); A NIT-4 (the
`global_let_ctor_stores_` linear scan per ctor inst — small n, revisit
only if profiled); A NIT-6 (declaration-side promotion widens the
future upstream-merge byte-surface of lower/ — recorded as a
WEEKLY-MERGE WATCH ITEM); B NIT-7 (the registry's duplicate-key
`Insert` assumption — binding_id and value_id never collide across
bindings — stated, relied upon, unchecked). Veto-able.

_W69h landing (2026-08-18, the W69h implementer):_ split-file multi-unit
conformance-program support staged per fork/w069/plan.md §4 W69h —
capability only, NO new programs, and the file fence held:
fork/conformance/runner.py + fork/conformance/README.md are the only
non-bookkeeping files touched (zero toolchain files, zero workflow yaml,
zero program files, zero SKIP-directive edits). _Lane chosen —
DIRECTORY programs, not an in-file `// --- name.carbon` splitter:_ a
directory under programs/ directly containing a `main.carbon` unit is
ONE program; every `*.carbon` directly inside is a compilation unit;
all directives (CONFORMANCE-BULLET/COMPILE-ARGS/EXPECT-*/SKIP) live in
main.carbon (a directive in a library unit's leading comment block is a
discovery ERROR, never silently ignored). Why: real files are what the
driver actually compiles — no fork-invented splitter, and the
`// ---` convention is file_test-internal machinery. _Compile shape —
one `carbon compile` invocation PER UNIT (all units on every command
line, target unit last, `--output=<obj> --output-last-input-only`),
then ONE `carbon link` of all per-unit objects:_ this mirrors
upstream's own multi-unit build rule verbatim
(bazel/carbon_rules/defs.bzl:64-89) because a single invocation cannot
emit the library units' objects — compile_subcommand.cpp's
get_output_filename gives `--output` to the LAST input only, and
library units' lowered bodies would be dropped, guaranteeing undefined
symbols at link. _Ordering:_ units are passed sorted by filename with
main.carbon last, and NO numbering convention exists — command-line
order is immaterial to import resolution because
Check::CheckParseTrees orders units by import dependency internally
(check.cpp's ready_to_check worklist); the fixed order only pins
object names/diagnostics/link lines. _Fail classes:_ unchanged five —
any unit's compile failure is the existing COMPILE-FAIL with the unit
named in the detail (fork_conformance.yaml:84-91's hardcoded key list
untouched); the differential oracle stays single-file as
`main.diff.cpp` inside the program directory. _No-flip proof
(structural):_ SKIP is an in-file marker parsed from the program's own
header and returned before any compile, this slice edits no program
file, and discovery treats a directory as multi-unit ONLY on a
`main.carbon` marker — no file named main.carbon exists anywhere under
programs/ (verified by find), so every one of the 122 existing
programs takes the byte-identical single-file path. _Equivalence
evidence (local python3):_ `--self-test` green at **122 programs
parsed, 56 bullets, OK** including the new fixture-based multi-unit
discovery self-check; a harness importing runner.py proved
discovery metadata AND order, the generated README table, and the
compile+link argv for all 122 existing programs byte-identical to a
pre-change baseline snapshot; scoreboard entries gain a `units` key
for multi-unit programs ONLY, so existing entries are byte-identical.
A throwaway 4-unit program (base/export/reexport/main, the
library_multifile_export sketch) driven through main() with an
argv-recording stub toolchain exercised PASS, COMPILE-FAIL (middle
unit, named), LINK-FAIL, OUTPUT-MISMATCH, `--filter`, and `--self-test`
end-to-end, then was deleted. _Rides next:_ the W69h arbiter's
byte-identical full-run scoreboard (93/0/29 over 122) on the
conformance workflow — per the plan's re-open clause, ANY movement
stops the slice un-landed; W69b does not start until that rerun is
clean. Veto-able.

_W69h review round (2026-08-18, the W69h fixer):_ both adversarial
reviews APPROVE. Reviewer A (zero should-fixes, 7 NITs): byte-identity
proven three independent ways, the driver-contract claim
(`--output` names the LAST input's object) verified against
compile_subcommand.cpp, and ~18 discovery edge cases all fail loud.
Reviewer B (one SHOULD-FIX + 5 NITs): the arbiter-weakening sweep came
back clean — zero diff hunks on every comparison path, the deviation
records verified true, and the no-flip proof CI-confirmed at b3f3ed2
(the byte-identical 93/0/29-over-122 rerun landed; the §4 arbiter is
DISCHARGED). _B's SHOULD-FIX, actioned:_ the landing note's stub-driven
end-to-end verification (PASS / middle-unit COMPILE-FAIL / LINK-FAIL
through the real execution machinery) was throwaway — run once, then
deleted, leaving the claims unreproducible. It is now COMMITTED into
`--self-test` as the execution-path self-check: a hermetic tempdir
program tree plus an argv-recording stub `carbon` executable drives
main() through the multi-unit EXECUTION path and asserts PASS with
per-unit objects + an N-object link in unit order + the `units`
scoreboard key, a middle-unit COMPILE-FAIL naming the unit with no
link attempted, and a LINK-FAIL with no run — permanently
reproducible, sub-second, and skipped gracefully where the platform
cannot exec the stub. _Two corrections to the landing note above
(amendment, not rewrite):_ (1) missing clause — "a single invocation
cannot emit the library units' objects" is true only under the
runner's `--output` shape: the no-`--output` driver mode DOES emit
per-input objects, but scatters them next to the sources, violating
the out-dir isolation discipline, so the per-unit `--output` shape
remains the right choice for a different reason than impossibility;
(2) "mirrors ... verbatim" is too strong — the runner mirrors the
bazel rule's per-unit shape but omits `--no-include-carbon-core`
(conformance programs want the default core for `import Core`) and
passes no dep API files (the runner has no dependency concept).
_Also landed this round:_ a DIRECTIVE_PREFIXES drift guard in
`--self-test` (source-derived sync with parse_directives' dispatch
ladder + a behavioral check that every listed prefix is genuinely
parsed; A NIT-7 + B NIT-3); the discover_programs sort-order comment
qualified — parts-based key matches Path sort on the current Python,
the byte-identical-rerun arbiter is the authority (A NIT-1); the
README multi-unit section notes the `main.carbon` marker is
case-sensitive (`Main.carbon` falls to single-file semantics; A
NIT-2); work-items.json W-002's stale sentences refreshed with dated
markers (the one-file-per-program limitation is false post-W69h, the
EXTRA-ARGS question is answered by COMPILE-ARGS, README staleness is
now machine-checked, the runner.py line pin re-pinned).
library_multifile_export.carbon itself is deliberately untouched: its
SKIP-reason retext rides the adjudicated separate un-SKIP follow-up
(plan §8-A / review N-3). _Accepted, not actioned:_ A NIT-3
(symlinked program directories invisible to rglob — pre-existing
discovery behavior); A NIT-4 (a directory literally named `*.carbon`
would crash discovery — pre-existing and crash-loud); A NIT-5
(root-level main.carbon error duplicated per rglob hit — cosmetic); A
NIT-6 (unit-stem obj-name aliasing across programs is impossible
given name uniqueness — harmless-atomic); B NIT-1 (request-file
timestamp sloppiness — noted as a record-hygiene habit to keep); B
NIT-4 (scoreboard order sorts by parts while the README table sorts
by rel string — cosmetic, both deterministic); B NIT-5 (the runner
reports only the first failing unit's compile error — pre-existing
first-error-only shape). Veto-able.

_W-069 W69b landing (2026-08-18, the W69b implementer):_ the workstream
closer per fork/w069/plan.md §4 W69b — the pointer-value-rep arm, the
restored ledger acceptance split, the W69b golden set, BOTH conformance
programs, and the W69a fill-audit residue. _Mechanism (the pointer arm):_
`GlobalLetBinding::Disposition` gains `PromoteObject` — the
`ValueRepr::Pointer` case (classes, choices, multi-element tuples/structs)
now promotes instead of Declining. The dispatch is unchanged in structure:
object-identical `Copy` → the W69a store/load `Promote`; `Pointer` →
`PromoteObject`; `None` → `NoStorage` (still dead defensive per the W69a
fill audit); non-object-copy `Copy`/`Custom` and unmapped chase shapes →
`Declined` FATAL (message retexted to name what remains declined). A
`PromoteObject` binding's backing global holds the OBJECT representation
(`GetType(type_id)`, exactly what `GetOrCreateGlobalLetVariable` already
built), `PrepareGlobalLetDefinitions` zero-initializes it identically, and
the ctor hook fills it with a MEMCPY of the object's alloc size from the
bound value's lowered pointer — mirrored precedent:
`FunctionContext::CopyObject` (function_context.cpp), whose body is now
shared through a new public `CopyObject(TypeInFile, llvm::Value*
source_addr, llvm::Value* dest_addr)` overload that the inst-id form
delegates to. The bound value's lowered value IS a pointer because
`AcquireValue`'s `Pointer` arm forwards the acquired ref's address
(handle_expr_category.cpp), and the source is the binding's own
materialized temporary (nothing can alias it — values cannot have their
address taken), so the copy rides the values.md as-if license (§6 R-3).
References: `TryEmitGlobalLetValue`'s `PromoteObject` arm serves the
global's ADDRESS as the value representation — the same shape
`FileContext::GetConstant`'s pointer-value-rep arm serves for constants
and a by-value parameter carries — with `AddGlobalToCurrentFingerprint` on
every hit, same as the `Promote` arm. handle.cpp's NameRef comment
retexted (copy-of-object OR pointer now served; class-scope statics and
namespace-scope bindings still excluded). import_ref.cpp and check
untouched; SemIR untouched. _The ledger acceptance test (OQ-3):_
check/testdata/match/choice_generic_payload_scrutinee.carbon's
`imported_global` subfile is RESTORED to a cross-file split — plib gains
`fn MakeNeither() -> P(i64)` and binds `let g: P(i64) = MakeNeither();`
(RUNTIME-bound, the form that arbitrates the residue), the importer
matches `g` — the exact shape that CRASHED lowering at W5-S3b — plus the
constant-bound sibling `let gc: P(i64) = P(i64).Neither;` with its own
importing subfile (`imported_global_constant`) as the half-(b) boundary
pin; dump ranges mark both bindings and both match fns. _W69b goldens
(all CHECK-less or range-marked; autoupdate fills):_ NEW
lower/testdata/let/import_choice.carbon — the acceptance split's
lower-side pin (object-rep `_Cg.Main` global + ctor memcpy + the
importer's external decl + discriminant load; `gc` pinned to the constant
path with no `_Cgc` symbol; a same-file `match (g)` for the same-file
half), the class-typed subfile with FIELD-READ consumption (S-5:
`Pt`/`MakePt`/`let origin` + same-file and cross-file `origin.x`), and
the P-10 whole-tuple subfile (`let t: (i32, i32) = MakePair();` consumed
cross-file as `t.0` AND whole `t`). NEW
lower/testdata/let/global_runtime_specifics.carbon — the R-2 falsifier in
its nearest EXPRESSIBLE form (deviation, below). W69a residue discharged:
check/testdata/let/global_runtime.carbon now marks
`//@dump-sem-ir-begin`/`end` ranges around every binding and consumer
(11 ranges), so it pins the SemIR shape — binding in the file top block
wrapping a `@__global_init.`-qualified bound value; the importer's
no-`[concrete]` `import_ref` — and its header is retexted back from the
"clean checking only" reconciliation. _R17 DEVIATION, loud (for
coordinator adjudication):_ risk R-2's falsifier as written — "two
specifics of one generic each reading a DIFFERENT imported runtime let" —
is STRUCTURALLY INEXPRESSIBLE: a file-scope name reference in a generic
body resolves statically to one binding, so every specific of a generic
references the SAME `let` set; the only specific-dependent value channel
in `GetValue` is the constant path (`GetConstantValueInSpecific`), and a
runtime `let` is NotConstant by definition. The falsifier golden
therefore pins the nearest expressible shapes: (1) two specifics of one
generic (`fn G(generic T: Reader)`, the call_different_impls.carbon
pattern) whose witness calls reach per-type impl readers each loading a
DIFFERENT imported runtime let — a coalesced `_CG` specific serving both
is the alarm; (2) two specifics of one generic reading the SAME imported
runtime let directly — the direct promoted-global load inside
specific-function lowering, the path whose
`AddGlobalToCurrentFingerprint` call R-2 mandates (retained: correct,
cheap, and future-proof parity with the constant path at GetValue's
:217, though no expressible program today can make it the deciding
fingerprint entry). Recorded as a dated plan amendment. _Conformance
(the discharge arbiter; recipes per §4 N-6, RuntimeSeed(x) = x + 20,
expectations from seed arithmetic written as literals):_ (1)
control_flow/match_global_runtime_let.carbon (single-file, deepens the
already-PASS sum-type-consumption bullet): `let boxed: Box(i32) =
Box(i32).Full(RuntimeSeed(1));` matched exhaustively in `Run` with the
payload printed, and `let bias: i32 = RuntimeSeed(2);` read through a
cross-function helper — hand-computed output: RuntimeSeed(1)=1+20=**21**,
RuntimeSeed(2)=2+20=**22**; EXPECT-STDOUT 21,22, exit 0; a zeroinit read
prints 0 and fails loudly. (2) code_org/import_runtime_let/ (the FIRST
multi-unit directory program — W69h's capability exercised for real;
deepens the already-PASS Importing bullet): library unit seeds.carbon
binds `let scalar_from_lib: i32 = RuntimeSeed(3);` and `let opt_from_lib:
IntOption = IntOption.Some(RuntimeSeed(4));`, main.carbon imports
`library "seeds"` and prints the scalar then the matched payload —
hand-computed output: RuntimeSeed(3)=3+20=**23**,
RuntimeSeed(4)=4+20=**24**; EXPECT-STDOUT 23,24, exit 0. Directives live
in main.carbon only; discovery verified locally (`--self-test` green at
**124 programs parsed, 56 bullets, OK**, the program listed as
`multi-unit (2 units)`; README table regenerated by
`--update-readme-table`). The program COMPILES AND RUNS only on the
runner (no local toolchain) — its first real execution is the landing
conformance run. _Expected golden movement:_ import_choice.carbon and
global_runtime_specifics.carbon fill from empty CHECK;
check let/global_runtime.carbon fills its new ranges (first real fill —
the W69a empty-dump surprise cannot recur, ranges now exist);
check match/choice_generic_payload_scrutinee.carbon regenerates (declared
churn per §7 criterion (2): the P-5 restore — plib gains
MakeNeither/g/gc with ranges, imported_global re-splits, the new
imported_global_constant subfile fills); NO other file under
toolchain/**/testdata may move — the byte-equivalence audit obligation.
_Floor:_ **95/0/29 over 124** (+2 by addition: the two new programs'
PASS; no SKIP flips — library_multifile_export's stale one-file SKIP
text stays untouched per the adjudicated separate follow-up; no bullet
flips — both bullets were already PASS). _Ledger:_ W-069 →
DISCHARGE-STAGED under the R9 hedge (discharges when the landing
autoupdate reaches the R26 fixpoint over the new/changed goldens
including the restored split, the gate runs green, and the conformance
floor lands at EXACTLY 95/0/29 over 124 with the movement being ONLY the
two new programs' PASS; any other movement re-opens with the run's
evidence). Veto-able.

_W69b fix round (2026-08-18, coordinator):_ both adversarial
implementation reviews returned NEEDS-FIX on the EVIDENCE RECORD while
finding the mechanism sound and runtime-proven (the discharge arbiters
were already green: floor exactly 95/0/29 over 124 at scoreboard
889760a, movement isolated to the two new programs, the multi-unit
program's first real execution PASS). Two blockers, both root-caused:
(1) the acceptance vehicle's `return P(i64).Neither;` pins
CopyOfUncopyableType — the plan's own sketch shape, passed by both plan
reviewers, falsified by the fill; fixed at f2a7274 to the
constructor-call shape (`MakeRuntime() -> P(i64).Both(1, 2)`), the
runtime-bound predicate intact; the copy gap minted as **W-075**.
(2) three undeclared lower-golden movements
(choice/{basic,mixed_payload_alternatives,payload_layout}.carbon):
PromoteObject promotes plain-choice CONSTANT initializers because their
bound values are SemIR-NotConstant today (generic-specific alternatives
fold) — §3 R-7's falsifier FIRED as designed; ADJUDICATED
accept-and-declare (no principled predicate line exists; the promotion
is verified behavior-preserving and fixes a previously-crashing
plain-choice cross-file shape; the three files become declared churn;
registry comment retexted; the weekly-merge byte-surface watch item is
now demonstrated real). Review residuals folded per the plan's fix-round
amendment (import_choice absence-claim audit obligation named;
same-commit-adjudication pattern acknowledged for the PR digest).
Discharge criteria (2)/(3) re-arbitrate at the post-fix regen + gate;
criterion (4) already met. Veto-able.

_W69b post-fix crash round (2026-08-18, separate fixer per R11):_ the
post-fix regen (autoupdate run 32146552813) crashed lowering
import_choice.carbon's `imported_global_constant` subfile — `match (gc)`
on the imported CONSTANT-bound generic-specific choice let, a shape whose
lowering the f2a7274 fix un-suppressed for the first time anywhere in the
tree (the earlier fill was masked by the plib copy error). ROOT-CAUSED BY
READING as a PRE-EXISTING constant-lowering defect, not W69b promotion
(gc folds `[concrete]`, the promotion gate excludes it) and not
import-specific: the discriminant `class_element_access` folds to a
value-category `[concrete]` int constant while staying a REF-category
inst; `LowerInst` skips it as constant; `AcquireValue`'s Copy arm then
loads from `GetValue`'s served value — which `FileContext::GetConstant`
keys off the CONSTANT inst's category (value-category `IntValue`, Copy
rep u1 → the raw scalar, not an address; file_context.cpp:230-254) — so
`LoadObject` handed a non-pointer to `CreateLoad` ("Ptr must have pointer
type"). No green golden ever matched on a constant scrutinee, which is
why the defect never fired. CHOSEN LANE: the sanctioned small fenced
lowering fix (lane (i); no check/ or import_ref surface, no W-076
minted): the Copy arm passes the folded constant through — it IS the
acquired value representation, the same pass-through shape as the Pointer
arm and `GetConstant`'s value-rep return — by way of the new
`FunctionContext::GetValueServesConstantValueRep`, which mirrors
`GetValue`'s resolution order and `GetConstant`'s two address conventions
line for line and answers false for every non-folded shape (no behavior
change outside the crashing one); the branch is fingerprinted so
specifics differing in fold-ness never coalesce. Probe extended with
plib's `SameFileConst()` (pins import-independence); headers retexted.
Full chain + citations in the plan's post-fix crash round amendment.
W-069 hedge intact — discharge still waits on the rerun regen → fixpoint
→ gate → conformance at exactly 95/0/29 over 124. Veto-able.

_W69b crash round part 2 (2026-08-18, coordinator):_ the regen
re-crashed on the mechanism's own Declined FATAL — P-10's consuming
form references a binding the pre-pass declines (aggregate value rep;
the amended SF-3 dispatch routes it to the loud (a3) FATAL by design).
The probe contradicted the plan's own dispatch and is un-goldenable.
P-10 narrowed to declaration-only (silence pinned; the FATAL pinned by
run 32148462189's crash text); whole-aggregate consumption recorded as
workstream residue with candidate lanes in the plan amendment. The
AcquireValue folded-ref fix from part 1 is confirmed working (the prior
crash site lowered past cleanly this round). Veto-able.

_W-069 discharge confirmation (2026-08-18, coordinator):_ every
criterion of fork/w069/plan.md §7 is met and **W-069 is DISCHARGED**.
The final evidence chain: W69a mechanism + probes (gates green, two
APPROVE reviews, hardening landed); W69h multi-unit runner capability
(byte-identical rerun arbiter, execution coverage committed); W69b
pointer-rep arm + the restored runtime `let g` acceptance split + BOTH
conformance programs. The floor landed at EXACTLY **95 PASS / 0 FAIL /
29 SKIP over 124** twice (scoreboard 889760a at the discharge-arbiter
run; re-arbitrated green at the final round), moving only by the two
W69b programs — including the fork's FIRST multi-unit directory
program. The acceptance split is green in check AND lower goldens with
real pins (354 filled lower lines: `_Cg.Main` object-rep global, ctor
memcpy, external-decl import side, folded-constant match path, zero
`_Cgc` symbols); autoupdate at no-commit fixpoint (32149312735); gate
GREEN (32149634688). Three honest defect rounds rode the close: the
plan-sketch copy error (W-075 minted), the pre-existing AcquireValue
folded-ref crash (fixed, fenced), and the aggregate-Copy-rep
consumption FATAL (P-10 narrowed to declaration-only, residue
recorded). Veto-able.

_library_multifile_export un-SKIP landing (2026-08-18, the follow-up
implementer):_ the separate follow-up adjudicated at fork/w069/plan.md
§8-A OQ-1(a) (and tightened by the plan-round reviewer #2 N-3: the
Libraries BULLET is already PASS by way of
code_org/library_named_import.carbon, so this slice moves ONE PROGRAM
from SKIP to PASS — no bullet movement is at stake). The single-file
SKIP stub code_org/library_multifile_export.carbon (whose reason —
"runner.py compiles exactly one file per program" — was discharged by
W69h) is DELETED and replaced by the 5-unit directory program
code_org/library_multifile_export/ exercising at runtime exactly the
features the stub named: geo.carbon (`library "geo";` api — class Rect
plus DECLARED fns RuntimeSeed/Area) + geo.impl.carbon (`impl library
"geo";` — the only unit holding the fn bodies; pairing fail sides
pinned upstream by fail_api_not_found/fail_duplicate_api.carbon) +
export.carbon (`import library "geo"; export Rect;` — the `export C;`
spelling of export_name.carbon) + reexport.carbon (`export import
library "export";` — chained AFTER the name-export, the
export_name_then_import shape of export_mixed.carbon, so both export
spellings sit in series on main's route to the class) + main.carbon
(imports "geo" directly and "reexport" through the chain — the
import_both/use_both merge shape; directives in main only per the W69h
convention). _W-074 dodge:_ only the CLASS is exported by name; no
runtime `let` is exported anywhere, so the import_ref.cpp:4483 crash
shape cannot fire. _Hand-computed expectations (R16d, RuntimeSeed(x) =
x + 20, literals from seed arithmetic):_ w = RuntimeSeed(3) = 23, h =
RuntimeSeed(4) = 24, Area = 23 × 24 = **552**, RuntimeSeed(w) = 23 +
20 = **43**; EXPECT-STDOUT 552,43, exit 0. _Verified locally:_
`--self-test` green at **124 programs parsed, 56 bullets, OK** (the
stub was one program and the directory is one program — the count
stays 124), the program listed as `multi-unit (5 units)`; README table
regenerated by `--update-readme-table`. The program COMPILES AND RUNS
only on the runner (no local toolchain) — its first real execution is
the landing conformance run. No plan document: S-sized, adjudicated
follow-up; zero toolchain files touched (conformance + bookkeeping
only, so the landing sequence needs a conformance run only — no
autoupdate, no build gate). _Expected floor (the R9 hedge):_
**96 PASS / 0 FAIL / 28 SKIP over 124**, the movement being EXACTLY
this one program's SKIP → PASS (from 95/0/29); the Libraries bullet
stays PASS (no bullet flips claimed); ANY other movement re-opens the
slice with the run's evidence. Ledger: W-002's note (2) refreshed with
a dated marker — no remaining SKIP in the tree cites the
one-file-per-program limitation — and its evidence pin moved from the
deleted stub to the directory's main.carbon. Veto-able.

_multifile un-SKIP review round (2026-08-18, coordinator):_ the single
adversarial review returned NO blockers (spellings verified golden-exact
incl. the export-library-named-"export" detail; the W-074 dodge clean;
R16d holds with expectations provably preceding first execution by
commit timestamps; the scoreboard push-back verified at exactly 96/0/28
with only this program moving). Folded: the main.carbon arbitration
comment now splits honestly — the api/impl half is runtime-load-bearing
(visible LINK-FAIL failure mode), the export chain half is
COMPILE-arbitrated (one merged entity, routes unattributable at
runtime); the composed-not-single-golden merge-shape wording; the W-002
evidence pin re-aimed at the un-SKIP paragraph. Accepted-not-actioned:
the request-file timestamp regression (recurring cosmetic pattern);
impl_files_impl_defined_fn.carbon's stale one-file sentence rides its
own future un-SKIP. Comment-only edits — the landed arbitration stays
valid. Veto-able.

_W74a landing note (2026-08-18, the W74a implementer — fork/w074/plan.md,
the single W-074 slice):_ the sanctioned import_ref.cpp amendment round
lands the lane-(a) fix for the `export x;` runtime-`let` crash.
_Mechanism:_ ONE contiguous insertion in
`TryResolveInstCanonical`'s non-constant branch (toolchain/check/
import_ref.cpp, immediately inside the `!is_constant()` branch, before
upstream's own non-constant-BindNames TODO and the `Is<AnyBinding>`
CHECK): `untyped_inst.TryAs<SemIR::ExportDecl>()` (the N-1 reuse; the
check-side mirror of `GetCanonicalFileAndInstId`'s export arm in
sem_ir/import_ir.cpp) — on match, an inner `CARBON_CHECK` states the
eval-forwarding invariant (a non-constant `ExportDecl` cannot wrap a
constant value, per eval_inst.cpp's constant forwarding; it firing is
the R-3 falsifier that triggers the §2 widening amendment), then
`return ResolveResult::Done(SemIR::ConstantId::NotConstant)` —
identical in effect to the AnyBinding branch's runtime-`let` return
(the importer's type arrives separately by way of GetInstForLoad/
ResolveType). Nothing else in import_ref.cpp moves — the single-hunk
merge posture (§2 yield rule) is load-bearing. _Probes:_ the NEW
CHECK-less check golden toolchain/check/testdata/let/
export_runtime.carbon distributes P-0 (constant-bound boundary chain
const/export_const/use_export_const — the untouched constant path),
P-1 (crash shape scalar/export_name/import_export_name), P-2 (two-hop
export_export_name chain + importer; per-hop discharge — pre-fix the
MIDDLE exporter's own check crashed loading the inner ExportDecl, N-3),
P-4 (export_name.impl.carbon — the ApiForImpl route reading its api's
`export x;`, adopted N-5), and P-5 (import_both — the dual-route
merge, adopted N-5); the lower golden lower/testdata/let/
global_runtime.carbon gains the P-3 export_name/import_export_name
subfiles pinning ONE `_Cx.Main` across the by-name export route — the
W69a "implemented but unpinned" ExportDecl-arm record is updated at
fork/w069/plan.md Amendment 1 (dated cross-ref; the historical W69a
decision-log records above stand unrewritten). _Red evidence:_ the
crash is not goldenable (R17 deviation (1)'s recorded crash + a
one-time pre-fix reproduction quoted in the PR description stand in);
the goldens land CHECK-less and the runner autoupdate fills them
red-first to the R26 fixpoint. _Expected golden movement:_ ONLY the
new export_runtime.carbon fill and the lower global_runtime.carbon
appended subfiles' fill (existing CHECK content byte-stable — the new
source subfiles are appended after let_ref); every other golden
byte-identical; expected pins: export + importer lines with NO
`[concrete = ...]` (the NotConstant signature), the P-0 chain WITH its
`[concrete = ...]`, one `_Cx.Main` external in the lower importer.
_Floor:_ NO conformance program change (the plan's adopted decision) —
EXACTLY **96 PASS / 0 FAIL / 28 SKIP over 124**; the two stale
library_multifile_export "W-074 dodge" comments retexted comment-only
(the dodge is now historical; the record stays). W-074 is
**DISCHARGE-STAGED** (R9 hedge in the ledger): fast compile →
autoupdate red-first → fixpoint → gate, floor unchanged; the inner
CHECK firing, any `[concrete]` on the staged pins, or any floor
movement re-opens the item. Veto-able.

_W-074 discharge confirmation (2026-08-18, coordinator):_ every staged
condition met — fills 32185260726 (no-commit fixpoint 32185406315; all
six probe pins audited against pre-registered predictions and matching
verbatim), gate GREEN 32185553936, conformance confirm GREEN
32185553820 at exactly 96/0/28 over 124 unchanged. The implementation
review returned APPROVE (single-hunk verified; fence held); its
probe-placement deviation record is folded as a dated plan amendment.
`export x;` of a runtime `let` now checks clean with the NotConstant
import signature, the two-hop chain and ApiForImpl routes are pinned,
and the W69a ExportDecl chase arm carries its first lower-side pin.
**W-074 is DISCHARGED.** Veto-able.

_W75a landing note (2026-08-18, the W75a implementer — fork/w075/plan.md,
the single W-075 slice):_ lane (b) as adjudicated — the synthesized
`Core.Copy` witness for choice types. _Mechanism:_ check side,
custom_witness.cpp only: `LookupChoiceCopyWitness` mirroring
`LookupDestroyWitness` — resolve the canonical query self to a
`ClassType` whose `class_info.is_choice` holds (any other self answers
nullopt, so classes/tuples/primitives keep today's behavior and the
class-copy question stays where upstream left it); symbolic self or
`build_witness=false` answers yes with `InstId::None` (the destroy/B2a
deferral posture, justified by the SF-6 triviality fence); concrete self
builds by way of `BuildPrimitiveCopyWitness` with the Copy interface's
`scope_without_self_id` as the mangling hint (stated divergence from the
C++-enum precedent's `GetClassScope`); dispatched from
`LookupCustomWitness`'s Copy case, upstream's TODO comment left intact
over the remaining nullopt block. Lower side, handle_call.cpp: the
`PrimitiveCopy` arm gains the return-slot case (two args = value + slot,
`PrimitiveCopy` declares one parameter) — `CopyValue` into the slot
(memcpy for pointer-rep choices) then the trailing
`SetLocal(inst_id, GetValue(arg_ids[1]))` per the
CppStdInitializerListMake precedent. _Declared deviation from the plan's
two-file toolchain diff:_ `FunctionContext::CopyValue` was PRIVATE; its
declaration moved to the public section of lower/function_context.h
(declaration-visibility move only, no behavior change) — the plan's
prescribed call is impossible without it. _Declared consequences carried
to the digest:_ SF-1 — the custom-witness dispatch PRECEDES
candidate-impl iteration, so a user out-of-line
`impl <choice> as Core.Copy` (sum_types.md:95-98) is SHADOWED by the
synthesized witness, the posture Destroy already has; pinned by the new
shadowed_user_impl probe. SF-2 — `SetCoreWitness` bypasses
source-builtin validation and the lower arm widens `PrimitiveCopy`'s
de-facto contract past its `PrimitiveCopyable` validator
(sem_ir/builtin_function_kind.cpp); the R-5 weekly-merge yield rule
covers the seam. _Probes:_ NEW check/testdata/choice/
alternative_copy.carbon (payload_free return/var/assign round trip; the
sum_types.md:74-75 doc_shape verbatim incl. the None-to-Some-to-None
transition; the W69b minting shape `Pair(i64).Neither` with return slot;
boundary `let` + value-param no-copy pins; the symbolic-deferral +
monomorphization generic pin — the least-exercised link; the SF-1
shadowing pin); NEW lower/testdata/choice/alternative_copy.carbon (both
reprs: by-value `PrimitiveCopy`, pointer-rep slot memcpy, constant folds
vs runtime calls); the P-2 tripwire FIRED as designed —
fail_question.carbon's fail_return_choice_binding subfile (its header:
"if this ever compiles ... §2.6 needs re-derivation") relocated to
question.carbon as the return_choice_binding positive pin, and the
§2.6-derived records retext (docs/design/error_handling.md:343-349
dated amendment — the match-reconstruct `Branch` bodies STAY, `Branch`
returns the `ControlFlow` carrier, not `Self`;
control_flow_constructs.carbon:20; choice_generic_diff.carbon's `let`
workaround record marked historical). All new/changed goldens land
source-side and ride the runner autoupdate red-first to the R26
fixpoint; every untouched class/tuple copy golden must come back
byte-identical. _Conformance (adopted, veto-able):_ control_flow/
choice_generic_roundtrip_diff restored to the DOC-VERBATIM shape —
`var my_opt: Optional(i32) = Optional(i32).None;` and the full
None-to-Some(-to-None) transition on one variable, the oracle
`.reset()`-symmetric, churn declared; NO program count change. _Floor
(R9 hedge):_ EXACTLY **96 PASS / 0 FAIL / 28 SKIP over 124**, the pair
staying one PASS with coverage deepened. W-075 is **DISCHARGE-STAGED**:
fast compile → autoupdate red-first → fixpoint → gate → conformance;
any diagnostic on the flipped shapes, a candidate-impl binding in the
shadowing probe's dump, or any floor movement re-opens the item with
the run's evidence. Veto-able.

_W75a fix-round addendum (2026-08-18, the R11 fixer — dated follow-up in
the W-075 area per correctness F-3):_ the staged-discharge autoupdate
(run 32190561198) crashed gate-grade on a PRE-EXISTING golden —
lower/testdata/class/generic.carbon's create_generic subfile,
`fn Make[T: Core.Copy](x: T, y: T) -> A(T)` monomorphized at `T = i32`,
at `return {.x = x, .y = y};` — two signatures across the parallel
tests: the `CHECK failure at toolchain/lower/function_context.cpp:482:
value->getType() == llvm_type` (frame: `StoreObject` ← `CopyValue` ←
`InitializeStorage` ← `HandleInst(InPlaceInit)`) and LLVM's
`StoreInst ... "Ptr must have pointer type!"` assert. _Root cause
(confirmed against the code, not the hypothesized orientation swap):_
the landed arm discriminated on ARITY (`arg_ids.size() == 2` ⇒ slot
call), but a call built against a symbolic `T: Core.Copy` carries the
return-slot trailing arg for EVERY specific — check decided the slot
from the symbolic (dependent) init repr — so a monomorphized by-copy
specific (i32) also arrives with two args. The arm then took the slot
path: its `CopyValue`'s argument ORDER was correct
(`CopyValue(type, source_id, dest_id)`, function_context.h:213-216 —
no swap to fix), but the trailing
`SetLocal(inst_id, GetValue(arg_ids[1]))` published the SLOT POINTER as
the call's value, while every by-copy consumer dispatches through
`InitializeStorage`'s `InitRepr::ByCopy` arm (function_context.cpp:
406-407) and hands the call's value to
`StoreObject(type, GetValue(call), addr)` — pointer where an `i32` is
required, exactly the :482 CHECK; the pointer-type asserts are the same
misdispatch reaching LLVM's `StoreInst` operand checks on the sibling
consumer paths. _The old-code behavior (a99034e~1, the green baseline
for this exact golden):_ the pre-W75a arm was unconditionally
`context.SetLocal(inst_id, context.GetValue(arg_ids[0]));` — the call's
value is the SOURCE VALUE, the slot arg is left untouched at the arm,
and the consumer's `InitializeStorage` (ByCopy → `CopyValue` →
`StoreObject`) performs the store into the destination itself — the
golden's own CHECK line `store i32 %x, ptr %.loc10_25.2.x` is that
consumer store, and the corrected arm reproduces it byte-identically.
_The corrected dispatch (handle_call.cpp, PrimitiveCopy arm):_
discriminate on the CONCRETE type's init repr — the same discriminator
the consumers use (`FunctionContext::InitializeStorage`'s switch,
function_context.cpp:393-419; `GetTypeIdOfInst` maps through
`GetTypeOfInstInSpecific`, so the specific's concrete type answers) —
`arg_ids.size() == 2 && GetInitRepr(type).kind == InitRepr::InPlace` ⇒
the landed slot path (`CopyValue` into the slot, `SetLocal` the slot,
per the CppStdInitializerListMake precedent, handle_call.cpp:635-642);
otherwise (ByCopy/None, including every monomorphized by-copy specific)
the old arm verbatim — no slot store at the arm, matching the green
baseline (the consumer fills the destination, which IS the call's
storage arg per `FindStorageArgForInitializer`). The bare `InitRepr`
spelling without a new include follows lower/handle.cpp:306-335. The
W75a-new pointer-rep golden subfiles are unchanged in meaning
(`Pair(i64)` is `InitRepr::InPlace`, still the slot path); the
regression class is now pinned inside the W75a probe set as
lower/testdata/choice/alternative_copy.carbon's NEW mono_from_generic
subfile (one generic `Dup[T: Core.Copy]` monomorphized at a by-copy
choice, `i32`, and a pointer-rep choice). fork/w075/plan.md §2 carries
the dated contract correction; W-075 stays DISCHARGE-STAGED with the
hedge intact — this fix re-enters at fast compile → autoupdate
red-first → R26 fixpoint (every untouched class/tuple copy golden
byte-identical, create_generic included) → gate → conformance floor
96/0/28. Veto-able.

_W-075 discharge confirmation (2026-08-19, coordinator):_ every staged
condition met — the fix-round pipeline all green (fills 32191819332,
no-commit fixpoint 32191946652; gate 32192068700 with every untouched
golden byte-identical including the class/generic family the regression
had crashed; conformance 32192068450 at exactly 96/0/28 over 124, the
restored doc-verbatim roundtrip pair one PASS). The review's fill-audit
obligations discharged: the shadowing probe's dump binds the
synthesized `custom_witness (%Copy.Op)` at the outside call site with
no user-impl reference (predicted verbatim); the untouched
CopyOfUncopyableType goldens byte-identical by the fill's own file
list + the green gate. The design's canonical
`var my_opt: Optional(i32) = Optional(i32).None;` now compiles and
runs; the fork's tripwire flipped exactly as its own header predicted.
**W-075 is DISCHARGED.** Veto-able.

### W8c records the §1.3 all-expression alternative equality call (2026-09-25)

The design (pattern_matching.md:487-497) says an alternative pattern
whose payload list contains NO proper patterns — `case .Ok(42)` —
"behaves like an expression pattern": whole-value `==` on the
constructed choice value. In-slice choices implement no `Core.EqWith`,
so the literal reading would reject every such pattern. Recorded call
(OQ-3, adopted 2026-08-18, landed at W8a): the all-expression payload
list is implemented IDENTICALLY to the mixed case — the discriminant
test, then elementwise `==` on the payload in a block dominated by
that test (`MatchCaseAlternativePatternMatch`, pattern_match.cpp:561).
This is observationally equivalent to the specified whole-value `==`
for choice types with structural equality, which is the only equality
these choices could have; the equivalence breaks the day user-defined
`EqWith` on choices exists, which is when this entry is re-examined.
Coverage keeps the design's refutability reading
(pattern_matching.md:589-594): a constant-payload arm such as
`.Some(42)` is refutable and records NOTHING toward exhaustiveness
(the `payload_is_irrefutable` classification, pinned by
fail_nonexhaustive_payload_literal.carbon). Veto-able.

### W8c records the §4 R-3 evaluation-order approximation (2026-09-25)

The design interleaves pattern-match evaluation with binding
initialization and destruction (pattern_matching.md:776-791: a
`var y: X` element is initialized, the sibling `0` tested, `y`
destroyed on failure) and orders side-effectful pattern evaluation
(:834-952), with left-to-right short-circuit across tuple elements
(:100-118). The fork's match arms instead run a two-pass split — every
arm condition is emitted in the test pass and bindings initialize
afterward in the bind pass (`EmitCaseArmTestAndBind`,
handle_match.cpp:564) — and tuple-element conditions are emitted
eagerly into one block and folded flat (`FoldMatchCaseConditions`,
pattern_match.cpp:766) rather than short-circuited per element.
Recorded approximation (plan §2.1(a)(i) and §4 R-3): this is
observationally equivalent BECAUSE in-slice scrutinee and element
types are trivially copyable integers and choices of those (total
reads — no observable copies or destructions to mis-order) and
in-slice case expressions are constants (no effects to sequence). The
one ordering kept as MANDATORY structure is discriminant-then-payload
dominance (the explicit block switch in
`MatchCaseAlternativePatternMatch`), which is R-2 poison safety, not
part of the approximation. The design's "Destroyed!" example is
inexpressible in-slice — exactly why the approximation is safe today.
Re-examined the day non-trivial types pass the scrutinee gate
(handle_match.cpp:238). Veto-able.

### Full autonomy and the throughput protocol (2026-09-27)

Owner, verbatim: "your fork output is trash. stop making excuses and
work more efficiently." / "just finish everything without making
mistakes basically" / "im not helping u btw ur on ur own but you have
to finish" / "no more questions". Recorded as rulebook R29. Two
corrections to the fork's own bookkeeping fall out: (1) the six design
forks F-006..F-011 were never a block — they are decided here (F-006
with owner sub-decisions a..l; F-011 ratified) and stand under V-2/V-3;
treating the unanswered veto digest as a gate idled the error-handling,
if-let/let-else, union, overloading and structural-conformance chains
for two months. W-005 is discharged and every F-0xx/W-005 blocked_by
gate is lifted. (2) The two W-077 implementation reviews launched on
2026-09-26 died at startup (122-byte transcripts) and were waited on
for 21 hours; R29(e) makes that a relaunch, not a wait. Next
workstreams, in order of milestone value and unblocked state: W-012
if-let/let-else/while-let (flips a MISSING bullet on landed match
machinery), then the error-handling chain W-016..W-019 (Result, `?`,
exception interop), then unions W-009/W-015.

### SL-2 round-1 note: the prelude interop impl was an orphan (2026-10-05)

The first hosted autoupdate of SL-2 (run 37356848697, fill 0790c7428 on
12a2143d2) moved 306 files for ten predicted: core/prelude/types/cpp/slice.carbon
failed to type-check and every program including the full prelude carried its
three errors. Root causes, read from the tree (fork/slices/plan.md §2.B.9/R-9
amendments; W-056 notes):

-   **`ImplIsOrphan` at cpp/slice.carbon:64** — the blanket `impl forall [C:
    CppContiguous where .Element impls Copy & Destroy] C as
    ImplicitAs(Slice(C.Element))` lived in the helpers' library, not
    `Slice`'s. `DiagnoseOrphanImpl` (check/impl_validation.cpp) walks the
    impl's SELF type and INTERFACE SPECIFIC for a class, generic class,
    generic interface or generic named constraint of the same library; the
    facet-type bound on the self binding (`CppContiguous`, local) is not
    visited, and `Slice` is prelude/types/slice's. The deeper invariant, from
    the implementation review (REJECT, BLOCKER 1): impl lookup imports
    candidates only from the IRs owning the query's self, interface and
    arguments (`FindAssociatedImportIRs`, `CollectCandidateImplsForQuery`),
    so an impl in cpp/slice would never have been a candidate for
    `Cpp.VectorLike as ImplicitAs(Slice(const i32))` even had it compiled.
    The plan's §2.B.9 placement was right; the implementer moved the section
    because the rev A A2 `u64` spelling is not nameable in slice.carbon and
    an import line would have moved the SL-1 lower goldens' DI lines (R28(d):
    a review miss — the deviation was disclosed in one sentence and the
    reviewer of record did not run the orphan walk over it).
-   **`MissingImplInMemberAccess` for `Destroy` at :68/:69** — the
    `self.Data()`/`self.Size()` temporaries of `Convert` need `Destroy`, and
    `CppContiguousRange` declares bare `let DataType: type; let SizeType:
    type;`. A synthesized witness cannot supply bounded associated constants
    (custom_witness.cpp `BuildCustomWitness` TODOs on any associated-constant
    type other than `type`), so the requirement goes on the constraint —
    `require Self.(DataType) impls CppDataPointer & Destroy; require
    Self.(SizeType) impls CppSizeToI64 & Destroy;` — the `CppIterator` shape
    of prelude/iterate.carbon, whose `Inc & Destroy` serves `++cursor->0`
    through the same facet-type route (`CollectFacetWitnessSources` reads the
    binding's identified facet type).
-   **impls/cpp_contiguous_range.carbon came back with no CHECK lines**
    (every other new golden filled) — unexplained at the time. Round 1
    attributed it to its mock `unsigned long size()` importing as
    `Core.CppCompat.ULong64`, absent from the primitives min-prelude, and so
    to `LookupCppMemberWithResultType`'s `CARBON_CHECK` aborting file_test;
    that attribution was FALSE (corrected at round 2, 2026-10-05): with
    `--target=x86_64-linux-gnu`, `unsigned long` is `uint64_t` and
    `MapBuiltinIntegerType` maps it to `u64` (the golden's original
    "`--target` pins `unsigned long` to `u64`" was right; `ULong64` is
    Darwin's import, `ULong32` LLP64's — long_and_long_long.{lp64,darwin,
    llp64}.carbon), and the run log shows no crash (1898 tests ran, no
    `Stack dump:`, the push happened). Root cause, read from the harness:
    the check component runs `--dump-sem-ir-ranges=only`
    (toolchain/testing/file_test.cpp), the golden had no
    `//@dump-sem-ir-begin` range and no split produced a diagnostic, so the
    test passed with empty stdout and stderr and the autoupdater had nothing
    to write — exactly the precedent's positive splits. The `CARBON_CHECK`
    was still a real ICE for `void data(); void size();` (the review's MAJOR
    2, reachable from every `ImplicitAs(Slice(...))` conversion of such a
    class), and the round-1 fix of it stands.

Fix (this round): the helpers stay in cpp/slice.carbon as public Core names
with a new `CppSizeToI64` interface hiding `u64`; slice.carbon's
SL-1-reserved `prelude/types/optional` import line (unused there) becomes
`import library "prelude/types/cpp/slice";` at the same line count, and the
blanket impl is appended beside `Slice` — zero DI churn, orphan walk anchored
on `Slice`, import graph acyclic. `LookupCppMemberWithResultType` declines on
`void` and propagates an error type; the `Span` import arm tests the element
against `Slice`'s own `Copy & Destroy` binding without diagnostics
(`SliceElementSatisfiesBound`) so `std::span<NonCopyable>` is a class import,
not a header-site error (MAJOR 3). D-SL-9's primary spelling is kept: the
projection-in-interface-argument shape has the in-tree precedent
impl/lookup/access.carbon:26 (MINOR 8), and the post-deduction specific
comparison evaluates it through `EvalLookupSingleFinalWitness` →
`LookupCppImpl` exactly as `for` over a C++ range evaluates `.ElementType =
T.ValueType`. The 299 pre-existing goldens the fill moved are restored
byte-identical from 12a2143d2 (the SL-1 lower slice goldens included); the
ten new goldens ship empty again. Review dispositions (REJECT → all nine
addressed): BLOCKER 1 fixed as above; MAJOR 2 fixed + `fail_void_members`;
MAJOR 3 fixed + `noncopyable_element_is_a_class` (a Carbon class with no
`Copy` impl as the element — a deleted C++ copy constructor would NOT fail
the bound, `BuildCopyWitness` imports the deleted decl); MAJOR 4: the gap row
says "PASS pending the hosted conformance run of record", stamped at
discharge; MINOR 5 fail_span.carbon's header reduced to `ConsumeStatic`;
MINOR 6 `{T*, size_t}` wording + `--target` pins on span/fail_span; MINOR 7
`Core.Print(Cpp.SumSpan(v))` added to cpp_span_view (EXPECT 10 6 12); MINOR
8 the precedent cited, fallback comment dropped; MINOR 9 the note prediction
dropped.

Round 2 (2026-10-05, after the second fill 18e2165c1 on fd9cdd5da; re-review
APPROVE-WITH-FIXES, 2 MAJOR, 3 MINOR): the second fill touched exactly the
seven filled goldens and no pre-existing one; vector_view.carbon's positive
splits are clean and show `custom_witness (%Optional.f0c, %u64, ...)` —
`size_t` as `u64` — with the `ImplicitAs(u64)` step resolving to uint.carbon's
`UInt(From) as ImplicitAs(To)` over `FromUInt(u64)`; the lower span thunk is
`@_Z7ConsumeNSt3__14spanIKiLm18446744073709551615EEE.carbon_thunk._` (R-8);
`noncopyable_element_is_a_class` shows `class_type @span` for `Cpp.NoCopySpan`;
`fail_no_size`/`fail_void_members`/`fail_static_extent_from_slice`/
`fail_no_span_header` carry the predicted diagnostics and no nullability
warning. Fixes: the `ULong64` story corrected in the seven records (above,
plan §1.B step 4 / R-9 / hand-off, W-056, the four golden and prelude
comments, slices.md); the silent golden explained (above) and given dump
ranges with `unsigned long`/`u64` restored; the gap row back to PARTIAL with
the header at 28 / 22 / 5 / 1 until the run of record (R9); `_Nonnull` on
`no_size.h`; `GetOrEmpty` on `Slice`'s bindings in
`SliceElementSatisfiesBound`; the deleted-copy-constructor consequence
(`std::span<std::unique_ptr<int>>` maps to a `Core.Slice` whose element
copies fail at the use site) recorded in slices.md, W-056 and import.cpp.

### SL-1: Core.Slice, Core.Buf, heap allocation, fail-stop (2026-10-05)

Milestone bullet "Stdlib: Slices" flips MISSING → PARTIAL
(fork/gap-analysis.md row 78; header 28 DONE / 22 PARTIAL / 5 MISSING / 1
DESIGN-ONLY over 56). Landed on claude/carbon-fork-0-1-slices in the four
commits fork/slices/plan.md §3 fixed — 2adc95742 (the four builtins:
`pointer.offset`, `fail_stop`, `heap.allocate`, `heap.free`, with their
builtin goldens), 2633b769e (`Core.Slice`, `Core.Buf`, the `Iterate` impl,
the prelude goldens), 55706e3eb (conformance: `slices_basic` SKIP → PASS,
`slices_heap_buf`, `slices_bounds_fail_stop`; ledger), 0c88bddf5
(docs/design/slices.md and the README amendment) — plus c200e6b81 (round 1:
the pointee-completeness hook), 24ef65c1c (round 2: declared `Destroy` impls
win destroy lookup; the `heap.allocate` overflow check), ee434b2b3 (round 3:
`IndexWith(i64)` and the literal-subscript rule), 7b69e540b and 713eddc7a
(round 4: class-keyed `HasUserDestroyImpl`, `final` on the prelude container
impls, the probe gate), with the hosted fills 50cd6c82c and 84315a5d4 between
rounds 3 and 4. The plan's SL-1 slice was W-055; W-056 (SL-2, the `std::span`
mapping and owning-container views) is next and is unblocked. Design
authority was not reopened: README.md's arrays-and-buffers text, values.md's
"slice or view style types", indexing.md's `Span` target shape and the safety
README's bounds promise stand; every decision below is an R29(a) fill under a
missing notion or an implementation choice, recorded for after-the-fact veto.
This entry is the decision record the plan's §0.3 and §8.5 call F-012.

WHAT LANDED, by mechanism. (1) Four `BuiltinFunctionKind`s
(sem_ir/builtin_function_kind.def:154, :157, :160-161; signatures in
builtin_function_kind.cpp:836-856), each runtime-only (check/eval.cpp
:2648-2651) with a lowering arm (lower/handle_call.cpp:660, :682, :719,
:790): `pointer.offset` is `getelementptr inbounds` by the pointee's stride;
`fail_stop` loads the `str` as `StringAt` does, calls `write(2, ptr, size)`
through the byte-identical declaration of the `Core.Result` epilogue and then
`abort`, declared `noreturn`, with no terminator emitted (R-1 was not
refuted); `heap.allocate` multiplies the sign-extended count by `sizeof(T)`
with `llvm.umul.with.overflow.i64`, routes the wrap bit and a zero-byte
request into a null result and calls `malloc`, the element type unwrapped
from the result's `Core.MaybeUnformed(T*)` adapter class
(`GetTransitiveAdaptedType`); `heap.free` calls `free`. A builtin body `=
"name"` is accepted in any file, as for `pointer.unsafe_convert`, so no new
surface class. (2) Two prelude types. core/prelude/types/slice.carbon: `class
Slice(T: Copy & Destroy)` with private `ptr: T*`, `size: i64` — `FromArray[N:
IntLiteral](p: array(T, N)*)` (the array's data pointer through
`pointer.unsafe_convert`, `.size = N`), `UnsafeMake(p, size)`, `Size`,
`Data`, `Get(i)` (tests `i < 0 or i >= self.size` in Carbon and calls
`FailStop`), `Subslice(start, end)`, an in-class `impl as Copy`; out of class
`UnformedInit`, `final impl ... as IndexWith(i64) where .ElementType = T`
(`At` calls `Get`) and `ImplicitAs(Slice(const T))` through
`Data()`/`Size()`/`UnsafeMake` — every out-of-class impl reaches the data
through the public API only. core/prelude/types/buf.carbon: `class Buf(T: Copy
& Destroy)` over `malloc`/`free` — `Make(size, fill)` fail-stops on a
negative size or a null block, fills every element through
`*PointerOffset(ptr, i) = fill`; `Size`, `Get`, `Set` (by-value `self`:
the storage mutated is the heap block), `AsSlice` (through `UnsafeMake`); an
in-class `impl as Destroy { fn Op(ref self) { HeapFree(self.ptr); } }`; no
`Copy` impl (`CopyOfUncopyableType`, `fail_copy`), no `UnformedInit`
(`fail_unformed`); `final impl ... as IndexWith(i64)`. core/prelude/types
.carbon gains two `export import` lines. (3) `Iterate` for slices: `final
impl forall [T: Copy & Destroy] Slice(T) as Iterate where .ElementType = T
and .CursorType = i64` APPENDED to core/prelude/iterate.carbon (:84-96), the
array impl's shape with `Size()`/`Get()` for the bound and the read; the
file's existing methods did not move. (4) Three toolchain rules this slice
forced, each with its own decision below: the pointee-completeness
requirement at `pointer.offset`/`heap.allocate` calls (check/call.cpp
`RequireBuiltinCallPointeeComplete`, the new Context diagnostic
`IncompleteTypeInBuiltinCall`, kind.def:533 — the one new kind, covered by
the `fail_incomplete_pointee` splits of builtins/heap/allocate_free.carbon
and builtins/pointer/offset.carbon); declared `Destroy` impls selected over
the synthesized destroy witness (check/custom_witness.cpp `CanDestroyClass`
→ `HasClassKeyedImpl`), with `HasUserDestroyImpl` — the union field rule's
and the C++ export predicate's scan — made class-keyed in the same file; the
literal-subscript rule (check/handle_index.cpp `LiteralSubscriptTargetType`,
`HasIndexWithImpl`; check/name_lookup.cpp `TryLookupNameInCore`). (5)
Goldens: check builtins/{pointer/offset, failstop, heap/allocate_free}
.carbon and slice/{basic, fail_basic, buf, fail_buf}.carbon; lower
builtins/{pointer_offset, failstop, heap}.carbon and slice/{basic, buf}
.carbon — `failstop.carbon`, not `fail_stop.carbon`, because file_test
reserves the `fail_` prefix for diagnosing files. (6) Conformance: the three
programs of plan §5.A under bullet "Stdlib: Slices" (hand-derived 2/3/30/32,
3/7/12/33, and `EXPECT-EXIT: -6` with no `EXPECT-STDOUT`); `runner.py
--self-test` clean, the README program table regenerated. (7) Docs:
docs/design/slices.md (new, normative, dated), README.md:887-889's `buf(T)`
sentence gains the fork parenthetical and README.md:914-928 replaces the
slices TODO with a summary and link. Twelve toolchain source files:
builtin_function_kind.{def,cpp}, eval.cpp, handle_call.cpp, call.cpp,
custom_witness.{h,cpp}, handle_index.cpp, impl_lookup.cpp, name_lookup
.{h,cpp}, kind.def.

DECISIONS. D-SL-1..14 of fork/slices/plan.md §0.3 are adopted as written
there, each with its break condition, and are restated here by name only:
**D-SL-1** `Core.Slice(T)` is a prelude class `{ptr: T*, size: i64}` with
`T: Copy & Destroy`, spelled in full, layout-identical to `String` and to
dynamic-extent `std::span`; **D-SL-2** views are formed from POINTERS to
arrays (`FromArray(&a)`), from `Buf` (`AsSlice`), from pointer+size
(`UnsafeMake`) and from slices (`Subslice`) — no array-VALUE conversion
(pinned `fail_array_value_no_conversion`); **D-SL-3** indexing is
`IndexWith.At` by value, bounds-checked, read-only in 0.1 (pinned
`fail_write_through`; break: `IndirectIndexWith`/`ref` returns); **D-SL-4** a
bounds violation fails-stop — one stderr line naming the operation, then
`abort()`, SIGABRT — unconditionally, the DEBUG build's promise
(safety/README.md:229-232) adopted as the single 0.1 mode; the release
paragraph's enforcement opt-out is residue; **D-SL-5** the four private
runtime-only builtins; **D-SL-6** `Core.Buf(T)` over `malloc`/`free`, in-class
`Destroy` frees, not `Copy`, not `UnformedInit` (`Destroy` on `var` storage
is unconditional, so an unformed `Buf` would free garbage), element
destructors not run, no `buf(T)` keyword, no `Allocator`; **D-SL-7**
`Slice(T) as Iterate` with `.CursorType = i64`, appended to iterate.carbon;
**D-SL-8/9/14** are SL-2's (the `std::span` mapping, the synthesized
`CppContiguousRange`, mocked spans in goldens); **D-SL-10** `Slice(T)`
implicitly converts to `Slice(const T)`; **D-SL-11** `UnsafeMake` is public;
**D-SL-12** the fail-stop program asserts `EXPECT-EXIT: -6`; **D-SL-13**
slices.md plus the README amendment, indexing.md untouched. The slice forced
six more, numbered on: **D-SL-15** — a `pointer.offset` or `heap.allocate`
call requires its pointee type complete (`RequireBuiltinCallPointeeComplete`
in `PerformCallToFunction`, after `ConvertCallArgs`, for every `Builtin`
callee: the first converted argument's pointee for `pointer.offset`, the
result's `MaybeUnformed(T*)` pointee for `heap.allocate`; a symbolic pointee
records a `RequireCompleteType` in the enclosing generic, enforced per
specific in the specific's file; the diagnostic is
`IncompleteTypeInBuiltinCall` with the `ClassForwardDeclaredHere` note; both
lower arms `CARBON_CHECK(isSized())`). A pointer type is complete without its
pointee and nothing else at such a call completed it, so `i32`
(`Core.Int(32)`, an adapter class) was never completed in the builtin
goldens' user files. Break condition: upstream adds a general completeness
rule for builtin operands — fold into it; falsifier: a `fail_incomplete
_pointee` split filling without the diagnostic. **D-SL-16** — a class's own
declared `Destroy` impl wins destroy lookup. `CanDestroyClass` answers
`NoDestroy` for a non-`partial` class covered by a CLASS-KEYED declared
`Destroy` impl (`HasClassKeyedImpl`: the union rule's
`HasUserCopyImplOutsideCore` scan generalized over the interface and the
`Core` trust boundary — the local store plus every imported IR's store,
read-only, matched by `class_id` locally and by canonical defining
declaration for imports; a blanket symbolic-self impl such as `impl forall
[T: type] T as Destroy` does not count; a `partial` self keeps the
synthesized witness because a declared impl's self never matches it), so
`LookupDestroyWitness` returns `nullopt` and impl lookup, which consults the
custom witness first (`EvalLookupSingleFinalWitness`), selects the declared
impl; `AddCleanups` then binds the impl's `Op` to the `var` storage (a `fn
Op(self)` through the impl's signature thunk) and `Buf(i32).as.Destroy.impl
.Op` lowers `HeapFree` to `call void @free`. This supersedes the W-021 note's
"a user `Core.Destroy` impl is inert today" for every class-keyed impl in the
tree (the round-2 note below the W-021 entry records it in place); the
"same-file ordering hole" (a lookup textually before a same-file out-of-class
impl's declaration is answered by the synthesized witness) stays as
documented at the scan — the design's in-class spelling never hits it. Break
condition: upstream lands destroy-op synthesis that calls declared impls —
drop the yield; falsifier: lower slice/buf.carbon losing the `call void
@free` inside its destroy specific, or a destroy call on a class without an
impl changing shape. **D-SL-17** — the literal-subscript rule. An
`IntLiteral`-typed subscript on an operand that implements `IndexWith(i64)`
and has no `IndexWith(Core.IntLiteral)` impl converts to `i64`
(`ConvertToValueOfType`) before `PerformIndexWith` dispatches — the array
arm's hardcoded subscript conversion, decided by impl lookup: two
non-diagnosing `LookupImplWitness` probes over a facet type built from the
`Core.IndexWith` declaration (found with `TryLookupNameInCore`, which never
diagnoses), the `i64` type formed inside a discarded inst block only after
`TryLookupNameInCore(Int)` succeeds, and no probe at all for an `ErrorInst`
operand (the dispatch exits before any lookup there). An operand with its own
`IndexWith(Core.IntLiteral)` impl (`Core.String`) or with neither impl
dispatches as written, so every landed diagnostic is unchanged. Why not the
blanket `impl forall [U: ImplicitAs(i64)] Slice(T) as IndexWith(U)` of plan
rev 2: its `At` calls `subscript.Convert()` on a RUNTIME parameter, and
`IntLiteral`'s `ImplicitAs(Int(To)).Convert` is `"int.convert_checked"`,
compile-time only (`IsCompTimeOnly`), so the `U = IntLiteral` specific cannot
lower ("Missing constant value for call to comptime-only function");
`String`'s identical blanket impl lowers only because its `At` is itself a
builtin (`"string.at"`), lowered at the call site with the call site's
constant. Cost accepted: an `i32` subscript on a `Slice`/`Buf` is an error
(`fail_subscript_i32`; `s[i as i64]`), and the `Core.Int` import_ref the
rule must load to name `i64` is a disclosed footprint in two goldens (below).
Break condition: upstream specifies subscript conversion (indexing.md's
rewrite rules, `IndirectIndexWith`) — the rule is replaced by the specified
one; an integer-subscript widening design — the `i32` limit lifts.
**D-SL-18** — the prelude container impls are `final`: `Slice(T)`/`Buf(T)
as IndexWith(i64)` and `Slice(T) as Iterate` (the `final impl forall [T:
Destroy & OptionalStorage] Optional(T) as Try` precedent, optional.carbon
:69). A symbolic impl lookup resolves only final impls
(`EvalLookupSingleFinalWitness`), so through a non-final impl the `where
.ElementType = T` rewrite is unknown in a generic body and `s[0]` on a
`Core.Slice(T)` has the abstract type `Core.Slice(T).(Core.IndexWith(i64)
.ElementType)` — the `generic_element` split of check/slice/basic.carbon had
filled with that `ConversionFailure` in a POSITIVE golden. impl_validation's
rules hold: slice.carbon/buf.carbon own the root self type and iterate.carbon
the interface (`FinalImplInvalidFile`), no non-final impl's query matches
(`ImplFinalOverlapsNonFinal`: `String`'s blanket is keyed on `String`, the
`CppRange` blanket's self is a facet binding, `array(T, N)` is not a `Slice`),
and `ImportFinalImplsWithImplInFile` enumerates only the interface's own IR.
Break condition: the toolchain resolves non-final `where` rewrites in generic
bodies — `final` becomes optional, not wrong. **D-SL-19** — `HasUserDestroyImpl`
is class-keyed. The scan behind `IsTriviallyDestructible` (the union field
rule, class.cpp:737, and the C++ export triviality predicate) treated EVERY
symbolic impl self as a blanket covering every class; the prelude's in-class
`impl as Destroy` of `class Buf(T)` has the symbolic self `Buf(T)` and sits
in every file's import set, so every class left the trivially-destructible
set, `i32` included, and 13 union/export goldens broke at the round-3 fill.
Now a class-typed self, concrete or a symbolic specific, is keyed on its class
(local `class_id`; imported canonical defining declaration) and only a
non-class symbolic self (`impl forall [T: type] T as Destroy`,
impl/lookup/fail_poison_custom_witness.carbon) is a blanket; the predicate
stays strictly broader than D-SL-16's yield (a blanket still disqualifies),
so an exported record's triviality is identical across the defining and
importing TUs. Break condition: `git diff ee434b2b3~3 -- toolchain/check
/testdata/union toolchain/lower/testdata/union` non-empty after a fill (it is
empty at HEAD), or an exported class without a `Destroy` impl growing a
`__destroy_thunk`. **D-SL-20** — a `Buf` byte count that overflows
fails-stop: the `heap.allocate` arm's `llvm.umul.with.overflow.i64` wrap bit
selects a null block, which the prelude's existing `PointerIsNull` check turns
into "carbon: heap allocation failed; terminating" (the implementation
review's MINOR 2: `Make(0x4000000000000001, 7)` would have `malloc`ed 4 bytes
and filled past them). Break condition: a runtime diagnostics facility that
can name the size — the message gains it.

REVIEWS. One implementation review of the four plan commits (R29(c): hosted
verification was not yet green) returned REJECT. BLOCKER — `Core.Buf(T)`'s
`impl as Destroy` was dead code: impl lookup consults the destroy custom
witness first and `CanDestroyClass` never looked for a declared impl, so the
synthesized `ret void` placeholder (`MakeDestroyOpBody`) won and every `Buf`
leaked while the docs, the ledger, plan R-12's prediction and the golden
comments claimed `free`; the conformance program exits 0 either way, so the
whole hosted pipeline would have gone green with slices.md asserting
behavior that did not exist — and the fact was decidable from the tree
(decision-log W-021 note; lower/testdata/var/param.carbon and
var/destroy_control_flow.carbon display it), so plan R-12 was a planning
miss of the rev B B1 class. MINOR 2 — the `heap.allocate` byte count could
wrap. MINOR 3 — the `UnusedBinding` prediction on `var s: Core.Slice(i32);`
was unverified but harmless (confirmed by the fill). 24ef65c1c fixed the
BLOCKER at the root with D-SL-16 (the review's option (a); option (b), landing
honestly with an inert destructor, was rejected because the plan's own R-12
contingency names a same-PR fix) and MINOR 2 with D-SL-20, cleared the six
goldens that hold a user `Destroy` impl for the fill and filed the
member-held-`Buf` residue (W-108). The focused re-review of c200e6b81,
24ef65c1c and ee434b2b3 returned APPROVE-WITH-FIXES. MAJOR 1 — the round-3
record called index/fail_non_tuple_access.carbon byte-identical, but the
rule's `MakeIntType` loads `Core.Int` into a file whose only integer-typed
expression is `0[1]`, so the golden moves (an unpredicted move is plan §8.1's
STOP); fixed by recording the move and clearing the file. MINOR 2 — the
probe could emit a spurious `CoreNameNotFound` for `Int` in a test `Core`
without it; fixed with the `TryLookupNameInCore(Int)` guard. MINOR 3 — the
plan's coverage bullets said "no diagnostic kind" after
`IncompleteTypeInBuiltinCall` had landed; fixed in place. The reviewer named
the literal-subscript probe the riskiest remaining edit — a name lookup with
import side effects running on every literal subscript of every non-array
operand in every file — which the fourth hosted round then confirmed in two
more goldens (below).

FILL-CAUGHT MISSES — review misses per R28(d), one per hosted round. Round 1
(run 37324972577 FAILED, fix c200e6b81): `file_test` crashed twice with one
root cause — "Cannot get layout of opaque structs" in `getTypeAllocSize`
(lower/builtins/heap.carbon) and "GEP into unsized type!" from the IR
verifier (lower/builtins/pointer_offset.carbon) — because `i32` was never
completed in the goldens' user files; the plan's R-1 (the `fail_stop` block
shape) was NOT refuted. D-SL-15. Round 2 (the implementation review, above;
fix 24ef65c1c): decidable from the tree. Round 3 (run 37329946461 FAILED, fix
ee434b2b3): lowering `Slice.At(i32, Core.IntLiteral as ImplicitAs(i64))` hit
"Missing constant value for call to comptime-only function" — plan R-5's
`Core.String` precedent was misapplied (its `At` is a call-site-lowered
builtin), decidable from the tree. D-SL-17. Round 4 (run 37335213696
success, fill 50cd6c82c, 40 files moved where 18 were predicted; the
convergence pass 84315a5d4 was `.loc`-only; fixes 7b69e540b, 713eddc7a): (a)
the D-SL-19 regression — 13 union/export goldens (check/union/{basic,
fail_init, fail_modifiers_and_redecl, fail_nontrivial_field, import,
layout}; lower/union/{basic, layout}; lower interop/cpp/issue7142,
function/export/constructor, class/export/union; check class/export/union,
union_by_value) restored from ee434b2b3~3 and byte-identical at HEAD, plus
a 14th, check/function/overload/basic.carbon, whose `union_scope_set` split
took the same spurious pins and is cleared rather than restored because its
`destroy_arg` content is the legitimate round-2 move; the round-2 note's
"`grep -rn 'as Destroy' core/`, so no other prelude type changes behavior"
looked at the wrong predicate — the impl being ADDED is in the result set
and every prelude impl is in every file's import set; (b) UNPREDICTED,
disclosed and kept: `ImportImplFilter::IsRelevantImpl` filters imported
impls by INTERFACE only, so every file that looks `Iterate` up materializes
the appended `Slice(T) as Iterate` impl and the `i64 as Destroy` facet value
of its rewrite — lower/for/{for, bindings, break_continue}.carbon and
lower/array/iterate.carbon gain one uncalled `declare void
@"_COp.41b89bfca5f3c7d4:core.Destroy.Core"(ptr)` beside the
`_COp.6f4dee545ed23f91` twin the array impl's `.CursorType = i32` already
left in exactly those four goldens, and check/interop/cpp/range_for.carbon
renumbers two constants; not a destroy-selection change, unavoidable while
the impl lives in iterate.carbon (slice.carbon cannot import
`prelude/iterate`: cycle); (c) the `generic_element` defect — D-SL-18; the
four slice goldens are cleared for the fill; (d) the literal-subscript probe
ran on operands the dispatch rejects before any lookup (`N[0]`, `F[1]`,
unresolved `a[0]`), loading or poisoning `Core.IndexWith` where the dispatch
never does — gated on a non-`ErrorInst` operand, index/fail_invalid_base and
fail_name_not_found restored byte-identical; the `Core.Int` import_ref
(`.Int = %Core.Int`, `%Int.type`/`%Int.generic`) in
index/fail_non_tuple_access and operators/overloaded/index_with_prelude is
accepted and disclosed — `i64` IS `Core.Int(64)` and a discarded inst block
cannot undo file-level import state. The plan's R-12 and R-5 were decidable
from the tree; rounds 1 and 4(b)/(d) were not: a name lookup's residue in
the file (`import_ref`s, scope poison) is state no probe can discard.
Round 5 (fill a6cae2bab on 713eddc7a, the fill the round-4 movers list was
written against; found at the discharge merge): check/for/actual.carbon
moved by 81/81 lines of pure name disambiguation (`%N` → `%N.fe9`, `%N.patt`
→ `%N.patt.aa5`, `%Iterate_where.type` → `.131`, `%Iterate.impl_witness` →
`.195`, the `Optional.{Some,None}.specific_fn`, `Convert.{bound,specific_fn}`
and `%bound_method` suffixes, `%Core.import_ref.84b` → `.84ba`; every
reference renamed, no instruction added or removed). Cause, read from the
tree: lib.carbon declares a local `impl as Core.Iterate`, so
`ImportFinalImplsWithImplInFile` (impl_validation.cpp:473) imports every
`final impl` of `Iterate` — since D-SL-18, `Slice(T) as Iterate` — and that
import's closure brings a second, unprinted `symbolic_binding N` into the
file's constant namespace (not the impl's own `forall [T]`: the `N`-named
bindings reachable through `Slice(T)` are `Slice.FromArray[N: IntLiteral]`
and slice.carbon's file-scope `ArrayData[T, N]`; its fingerprint differs
from the printed `N, 0`, so it is not `Int(N)`'s), beside a second `Iterate
where ...` facet type and witness; trivial.carbon, with no local `Iterate`
impl, keeps `%N` bare. Same class as 4(b) — the `final` qualifier widened
the import footprint from "every file that looks `Iterate` up" to "every
file with a local `Iterate` impl", and the round-4 prediction grepped the
former only. Accepted and disclosed, not fixed: the import is the
final-impl validation D-SL-18 relies on.

DEVIATIONS from the plan, each in fork/slices/plan.md's "Landed notes (SL-1,
2026-10-05)": the builtin arms live at handle_call.cpp:660-810 (the plan's
:649 anchor moved) and the runtime-fatal `default` is :812; `IndexWith(i64)`
only, not the rev 2 blanket (D-SL-17); `final` on three impls (D-SL-18); the
checker hook and the one diagnostic kind the plan's §6.A had said did not
exist (D-SL-15); fifteen pre-existing goldens move where §6.A(a) predicted
none (six for D-SL-16, four `for`/iterate lower goldens plus range_for for
the `Iterate` footprint, two index goldens for the `Core.Int` load,
function/overload/basic.carbon, and check/for/actual.carbon for the `final`
impl's import by `ImportFinalImplsWithImplInFile`, fill a6cae2bab); check/slice/basic.carbon's `unformed` split
keeps its `UnusedBinding` STDERR pin; slices_bounds_fail_stop.carbon's
subscript is `s[RuntimeSeed(-18) as i64]`; `index_runtime_subscript` takes
`i: i64`; the W-055 subsystem is "core/prelude + toolchain/sem_ir +
toolchain/check (eval) + toolchain/lower", never prelude-only.

VERIFICATION is hosted-only (the container's clang cannot build the
toolchain; R28(b)). First autoupdate: run 37324972577 FAILED (the two
incomplete-pointee crashes). Second autoupdate (after c200e6b81, 24ef65c1c,
ee434b2b3): run 37329946461 FAILED (the comptime-only conversion in
`Slice.At`). Third autoupdate (after ee434b2b3): run 37335213696, success —
fill 50cd6c82c (40 files) and the convergence pass 84315a5d4 (8 files,
`.loc`-only), the 13-file regression and the three disclosed footprints
above. Fourth autoupdate (after 7b69e540b and 713eddc7a): run 37341482411 (and 37345524695 on the trunk merge, which changed nothing),
filling the four slice goldens and check/function/overload/basic.carbon with
the union goldens unmoved. Gate: run 37347712964, green (prek, `bazel test
//toolchain/...`, the diagnostics coverage test with
`IncompleteTypeInBuiltinCall` covered by the filled `fail_incomplete_pointee`
splits). Conformance: run 37347619141, **124 PASS / 0 FAIL / 23 SKIP over 147, 47/56 bullets** — expected 121 PASS / 0
FAIL / 23 SKIP over 144 programs, 47/56 bullets ("Stdlib: Slices" SKIP →
PASS), from the branch base READ FROM fork/conformance/out/scoreboard.json
(3c9df53f7, generated 2026-09-28T17:19:40Z: 118 PASS / 0 FAIL / 24 SKIP over
142 programs, 46/56); delta PASS +3 / SKIP −1 / total +2 as plan §5.A
predicted; zero landed programs move. Trunk meanwhile carries OV-2's 121 / 0
/ 24 over 145 (46/56), so the of-record numbers on the trunk merge are the
same delta over that base.

RESIDUE, filed with blocked_by [] (ids follow the ledger: trunk's OV-2
discharge took W-105..W-107, so this branch's round-2 item W-105 is
RENUMBERED W-108 everywhere it was cited — ledger, plan, this log — and
the new items follow it): W-108 a `Core.Buf` (or any class with a
declared `Destroy` impl) held in a field is not destroyed — synthesized
aggregate `Destroy.Op` bodies are the member-destruction placeholder
(`MakeDestroyOpBody`; D-SL-16's limit); W-109 write-through slice indexing
(`IndirectIndexWith`, `ref` returns; D-SL-3); W-110 `buf(T)` keyword
shorthand for `Core.Buf(T)` (D-SL-6); W-111 `Core.Buf` element destructors
and an `Allocator` parameter (D-SL-6; explicit destroy calls or the
`TrivialDestructor` facet, details.md:4190-4192); W-112 over-aligned
`Core.Buf` element types (`aligned_alloc`); W-113 runtime bounds diagnostics
with the offending index (D-SL-4); W-114 unchecked slice access (the
release-build enforcement opt-out, safety/README.md:222-224; D-SL-4, plan
fold rev A A3); W-115 `Core.Buf` unformed declarations (needs
unformed-state-aware destroy; D-SL-6, plan fold rev B B1); W-116 integer
subscripts other than `i64` and literals on `Core.Slice`/`Core.Buf` (`i32`
needs `as i64`; D-SL-17). Not filed: "array-value to slice conversion"
(D-SL-2 files it only if upstream specifies the conversion); the SL-2 titles
(static-extent `std::span`, the D-SL-9 fallback, ADL `data`/`size`) wait for
SL-2; `Buf.Resize`/`Push` and comptime slice reads are slices.md "0.1
limits" entries without a mechanism to file against.

PLAN §0.2 CORRECTIONS carried into the ledger (items 1, 3, 4, 6 per §8.5):
W-055's evidence pointed at slices_basic.carbon's EXPECT-EXIT line, not the
SKIP line :10, and at gap-analysis.md:61 (the open-overload-sets row; the
Slices row is :78 after this entry's header edit); the subsystem was never
prelude-only (four builtins); no separate heap-allocation SKIP program
existed and none is invented — `slices_heap_buf` attaches to "Stdlib:
Slices", whose arbiter is a slice over heap storage (R7); gap-analysis row
76's `{Char*, u64}` is `{Char*, i64}` (string.carbon:23-25). Item 5 — the
§W9 "Depends on" line names dependencies of the String/Optional halves only
— is corrected in the §W9 paragraph rather than merely recorded, since the
paragraph now distinguishes the landed halves. W-056's two stale citations
(`cpp_span_view.carbon:6` → :10; `custom_type_mapping.cpp:92-104` → :93-99
and :102-109) are corrected with its SL-1 hand-off note.

_V-3a divergence-risk register entries (reviewed at each upstream merge):_
upstream has no slice or heap-buffer prelude type and no pointer-offset,
fail-stop or allocation builtins (values.md:1125-1131 forbids pointer
arithmetic except "through specialized constructs"; README.md:887-889 names
`Core.Buf(T)` as a placeholder) — the four builtin names, the two prelude
files, the `Iterate` impl and D-SL-15..20 are fork-local. If upstream names
the slice type or its literal syntax, D-SL-1 renames with layout unchanged;
if `IndirectIndexWith`/`ref` returns land, D-SL-3 switches `Core.Slice` to
indexing.md's `Span` shape and the literal-subscript rule yields to the
specified rewrite; if upstream's destroy-op synthesis starts calling
declared impls, D-SL-16's yield and D-SL-19's keying are dropped in favor of
it. Veto-able.

### OV-2: overload-set import, generic members, api/impl definitions (2026-10-05)

Milestone bullet "Functions: function overloading (Carbon-native)" stays
PARTIAL (fork/gap-analysis.md row 58; header 28 DONE / 21 PARTIAL / 6
MISSING / 1 DESIGN-ONLY over 56, unchanged — OV-3 flips the row). Landed on
claude/carbon-fork-0-1-ov2 in the three commits fork/overload/plan.md §3
fixed — 255314a06 (import of the set, the closed-set rule, api-member
definitions), 90a603a38 (generic members, sets in generic scopes, goldens,
conformance, ledger), b1cdf9e16 (the ported page's status paragraph) — plus
24cacacf3 (implementation-review fixes) and 843d20244 (round-2 fixes), with
the hosted fills 71fa9bb1a, fc3a74dce and 657bbe634 between them. The plan's
OV-2 slice was W-025; W-026 (OV-3, export) is next, after UN-2 per
D-OV-7/D-OV-9 (UN-2 is in). Design authority was not reopened: F-009, Option
A and D-OV-1..10 stand; every decision below is an implementation choice the
plan left open or got wrong, auto-adopted under R29(a) and veto-able after
the fact.

WHAT LANDED, by mechanism. (1) Import of a set, whole: check/import_ref.cpp
`GetLocalOverloadSet` replaces `HandleUnsupportedOverloadSet` (gate (vii))
and localizes an imported set in the two-phase shape of `FunctionDecl` —
every member declaration and the parent scope are required dependencies
(retry while any is pending), the local `OverloadSet` keeps the imported
member order, `Function::overload_set_id` is written on every localized
member by the set's resolver (`overload_index` stays mirrored by
`ImportFunctionDecl`, D-OV-5), and the `OverloadSetType`/`OverloadSetValue`
resolvers share one localization keyed on the first member; the type
resolver localizes the specific like `FunctionType` and adds the constant
directly. The set arrives whole through `export import` (one hop and two —
`CollectTransitiveImports` flattens the chain; D-OV-10 holds), from a class
scope (`C.F(...)` through an import) and from a generic class
(`OverloadSetType.specific_id` through `GetLocalSpecificData`). (2)
Definitions in the implementation file and the closed-set rule:
check/handle_function.cpp `TryMergeRedecl`'s `ImportRefLoaded` arm keys on
the loaded constant being an `OverloadSetValue` and runs the D-OV-3 identity
scan (`TryMergeIntoOverloadSet`) with the import's IR id; a type-equal
member merges through `MergeFunctionRedecl` with `replace_prev_inst=false`
(the name's scope entry stays the set value), so `DiagnoseIfInvalidRedecl`'s
`ApiForImpl` and cross-library `extern` branches apply per member; no
identity match → `OverloadSetFrozen` ("overload set `{0}` is closed; new
members may only be declared in the API file of its library") +
`OverloadSetDeclaredHere` at the set's first member — one site for the
implementation file and for an importing library — and the declaration
continues as a plain function kept out of name lookup; an unmarked
declaration against an imported set is `OverloadMarkerMismatch` recovering
as marked. `fn D.G(...)` out of line in an implementation file against an
api-declared class resolves through check/decl_name_stack.cpp
`GetApiClassDeclForQualifier` (D-OV-13). (3) `extern` members (gate (iv)
lifted in full): `extern library "owner" overload fn` members and the
owner's `extern overload fn` redeclarations go through the same identity
scan, in the one-file owner shape (the owner's api defines inline) and the
two-file shape (the owner's api redeclares, its impl defines), with
per-member ownership (D-OV-11) and the eager load that makes
`MissingOwningDeclarationInApi` fire for set members (D-OV-12). (4) Generic
members (gate (i) lifted): check/deduce.h/.cpp `DeduceGenericCallArguments(
..., bool diagnose = true)` threaded into the `DeductionContext` flag it
already had (plan §0.2 item 10); check/call.cpp `ProbeOverloadCandidate` /
`ProbeOverloadCandidateInScratchScope` run D-OV-4 step 2(d) inside the
discard scope — non-diagnosing deduction against the enclosing specific,
`None` is reason 2 ("has generic parameters that could not be deduced"),
success carries the specific into the parameter-type reads
(`GetScrutineeTypeInSpecific`); the commit re-deduces diagnosing and
`MakeSpecific` deduplicates. Pure declaration order over mixed
generic/non-generic members (`generic_first`: the generic member swallows
`Kind(5)` with `T = Core.IntLiteral`). (5) Sets in generic scopes (gate (ii)
lifted by DELETION ALONE; §1.B.5 confirmed): `OverloadSetType.specific_id`
already records the enclosing self specific and `GetCallee` already carries
it as `CalleeOverloadSet.enclosing_specific_id`; neither check/type.cpp nor
sem_ir/function.cpp needed an edit. Two `define`s per specific, marker then
fingerprint (`@"_CAdd:overload0.Box.Main.5d388d3559e392d2"`), in
lower/generic_class.carbon and lower/import_generic_class.carbon. (6) The
api-member missing-definition check (§1.B.7): check/check_unit.cpp
`CheckRequiredDefinitions` walks the `ApiForImpl` IR's `overload_sets()`,
skips a set whose first member carries an import source (another library's
set the api merely loaded), and emits `MissingDefinitionInImpl` at the api
declaration (an `ImportIRInst` location) of every non-`extern` member
neither file defines. OV-1's three conditional residues ("extern members of
overload sets", "overload sets in generic scopes", "marked members without a
definition") are NOT filed — no fallback fired. (7) Two new diagnostic
kinds, `OverloadSetFrozen` and `OverloadSetDeclaredHere` (kind.def:302-303;
one `CARBON_DIAGNOSTIC` and one emit site each, handle_function.cpp:401-409).
Nine source files: call.cpp, check_unit.cpp, decl_name_stack.cpp,
deduce.cpp, deduce.h, handle_function.cpp, import.cpp, import_ref.cpp,
kind.def.

DECISIONS beyond the plan, each with its break condition. **D-OV-11** —
per-member `ApiForImpl` selection. In an implementation file whose api file
imported a set from another library and redeclared some of its members
(`extern overload fn`, the owner side of §1.B.3), the impl's import ref
canonicalizes to the set's library and the api's owning redeclarations are
not in name lookup (the entry stays the set value, by D-OV-3 / rev A A6), so
a per-SET rule cannot be right: `ImportedOverloadSetSource::GetMember`
decides per member — when the member at the same index in the api IR's
localized copy of the set has `first_owning_decl_id`, the `ApiForImpl` rules
apply, with the previous declaration's FACTS taken from the api member's
`Function` (`MakeApiMemberRedeclInfo`: definition started, latest api
declaration for the note, no `extern library`) and passed as
`prev_decl_override` into `MergeFunctionRedecl`; otherwise the set's own
library's rules, so an impl can never silently define another library's
member, and an impl redefinition of a member the api defined inline is
`RedeclRedef`, not a silent merge (the re-review's MAJOR: rules chosen from
IR A applied to facts from IR B). Index parity holds because both copies are
localized from the same source set in source order and `member_decl_ids` is
append-only; a `CARBON_CHECK(index < size)` pins it. Break condition: that
CHECK firing, or `fail_extern_unowned.impl`'s `ExternRequiresDeclInApiFile`
or `fail_extern_api_defined.impl`'s `RedeclRedef` disappearing from a fill
(an impl silently owning or redefining). **D-OV-12** — eager load of
owner-library set members. check/import.cpp `AddImportRefOrMerge` loads an
imported set's members when one is a non-owning declaration (`extern
library`) owned by the CURRENT library, as it does for a plain
`FunctionDecl`, so `CheckRequiredDeclarations`'
`MissingOwningDeclarationInApi` fires for a member the owner never
redeclared (`fail_extern_unowned`, `fail_extern_partial`). It fires only
when `extern_library_id` names the current library; a library that merely
imports an `extern library` set is untouched (`fail_extern_non_member`'s
filled lines did not move). Break condition: a dump range or diagnostic
appearing in an importing library that never names the set. **D-OV-13** —
an api-declared class as a qualifier in an implementation file.
`DeclNameStack::ResolveAsScope` had no arm for an `ImportRefLoaded`, so `fn
C.F(...) {...}` out of line in an impl file against a class its api declares
was `QualifiedNameInNonScope` — `overload` or not; a trunk-level gap (no
landed golden had `fn C.F` in an impl file, and `class C;` in the impl is
`RedeclRedundant`). `GetApiClassDeclForQualifier` resolves an `ApiForImpl`
import ref whose api inst is a `ClassDecl` to the localized class's first
declaration (through the ref's constant: the class type, or a value of the
generic class type); a class the api merely imported (its api inst is itself
an import ref) stays a non-scope, as does every import ref in an api file.
Break condition: an impl file qualifying by a class its api merely imported
being accepted, or any qualifier resolution in an api file changing.
**D-OV-14** — `class Box(T: Core.Copy)` is the generic-class spelling (R3):
`Make` copies its `t: T` parameter into the `tag` field, which `T: type`
cannot (class/generic/member_type.carbon is the precedent); the plan's `T:!
type` does not lex here (OV-1's landed note). Break condition: none —
spelling. **D-OV-15** — step 2(d) DOES run for members of a generic class.
§1.B.5 said they are "effectively non-generic within the specific, so step
2(d) is not engaged"; a method of a generic class has its own `generic_id`
carrying the class's bindings, so the probe deduces it against
`enclosing_specific_id` exactly as `ResolveCalleeInCall` does for a plain
method, and reads parameter types through the resulting specific. Break
condition: the probe's specific differing from the commit's for the same
arguments — impossible by construction (`MakeSpecific` deduplicates);
falsifier: a third `define` for an `Add` member of one `Box` specific.
**D-OV-16** — gate (iii) is keyed on the declaration being checked.
`DiagnoseOverloadGates` read the MERGED function's `param_patterns_id`,
which for a declaration-only redeclaration of an imported member is the
localized block of `ImportRefLoaded`s (`AddLoadedImportRefBlock`) and never
a `WrapperBindingPattern`, so `extern library "x" overload fn D(x: i32)`
redeclared without a body in its owner's api fired the non-value-parameter
TODO at a by-value parameter; `extern library` was never the discriminator —
a definition passed only because `MergeDefinition` had copied the local
patterns first. The gate now walks `function_info` (this declaration's own
patterns). Break condition: fail_todo_gates.carbon's `fail_todo_ref_param`
moving, or a `ref`/`var` member reaching the probe through an import.

REVIEWS. One implementation review (R29(c): hosted verification was not yet
green) returned REJECT. BLOCKER 1 — the api-member arm of
`CheckRequiredDefinitions` walked `api_ir->overload_sets()`, which also
holds every set the api file merely LOADED from an import (localized whole,
placeholder members without `definition_id`), so any library whose api used
another library's set inline and had an implementation file got spurious
`MissingDefinitionInImpl` errors at the other library's declarations — a
shape no golden or conformance program reached. MAJOR 2 — the two-file
`extern` owner shape falsely emitted `ExternRequiresDeclInApiFile` (the
impl's canonicalized ref reaches the set's library, never `ApiForImpl`), and
§1.B.3's loud fallback had not been applied either. Minors 3-7: the
unrecorded §1.B.5 deviation, the probe-minted-specific side effect, two
`ErrorInst` cascades, the ledger's base numbers, three coverage gaps.
24cacacf3 fixed each at the root: the import-source skip plus a
`has_value()` guard on a never-loaded member constant (`is_constant()` would
have DCHECKed — a latent crash the review did not name); D-OV-11 and
D-OV-12; silent returns on `ErrorInst`; goldens `api_imports_set`,
`fail_untouched`, `extern_two_file`, `fail_extern_unowned`,
`fail_extern_partial`, import_class_scope.carbon and
import_generic_class.carbon (check + lower), `reexport_twice`/`use_two_hops`.
The focused re-review of that commit returned APPROVE-WITH-FIXES. MAJOR 1 —
the per-member rule chose the `ApiForImpl` rule set from the api IR but
applied it to the impl-local member localized from the SET's library (no
body), so an impl redefining a member the api had defined inline merged
silently and would fail at link with a duplicate symbol (the plain-function
twin is `RedeclRedef`). Minors: the still-unaddressed landed-notes items;
`use_two_hops`' comment claiming a walk that `CollectTransitiveImports`
flattens away; no lower pin for the `extern` shapes. 843d20244 fixed the
MAJOR with `MakeApiMemberRedeclInfo` / `prev_decl_override` (D-OV-11's
second half; pin: the `extern_api_defined` trio — `RedeclRedef` +
`RedeclPrevDef`, `RedeclRedundant` + `RedeclPrevDecl`), reworded the
comment, added the lower trio, and fixed the two fill-caught root causes
below.

FILL-CAUGHT MISSES — review misses per R28(d), one line each. The second
hosted autoupdate (run 37325822499, fill fc3a74dce) refuted three predicted
fills that both the implementation review and the re-review had traced:
(a) import_class_scope.carbon `api_impl.impl` — `fn D.G(x: i32) -> i32
{...}` out of line diagnosed `QualifiedNameInNonScope` twice (with two
`MissingDefinitionInImpl` cascades) where the re-review had predicted
"positives; the `fn D.G` out-of-line path canonicalizes to `ApiForImpl` and
returns early" — the arm `ResolveAsScope` lacked (D-OV-13), a trunk-level
gap no landed golden covered; (b) import.carbon `extern_two_file` —
predicted clean, filled with two gate (iii) `SemanticsTodo`s at the `extern
library` members' by-value parameters (D-OV-16); (c) import.carbon
`fail_extern_partial` — predicted `MissingOwningDeclarationInApi` alone,
filled with gate (iii) at the redeclared member too (the same root cause as
(b)). The third fill (run 37331151699, 657bbe634) matched 843d20244's
predictions in one pass: `fail_extern_partial` down to the one
`MissingOwningDeclarationInApi`; `fail_extern_api_defined.impl` exactly the
`RedeclRedef` / `ExternRequiresDeclInApiFile` / `RedeclRedundant` triple
(the middle one is the plain path's recovery for a rejected `extern`
redeclaration in an impl file, W-107); `extern_two_file` and `api_impl.impl`
diagnostic-free with one `define` per member. The first fill (run
36459794418, 71fa9bb1a) had converged in one pass over commits 1-3.

DEVIATIONS from the plan, each in fork/overload/plan.md's "Landed notes
(OV-2, 2026-10-05)": `impl_defines_all` is folded into the `api_impl` pair
(defining both members IS the positive); subfile spellings forced by
`[[@TEST_NAME]]` pairing (`frozen`/`fail_frozen.impl`,
`unmarked`/`fail_unmarked.impl`, `extern_lib`/`extern_owner`,
`undefined`/`fail_undefined.impl`; generic.carbon's main subfile is
`generic_second` beside `generic_first`; `export_import_of_set` is
export_import.carbon); §1.B.5 lifted by deletion alone AND step 2(d) runs
for generic-class members (D-OV-15); §1.B.3's `extern` lifted fully
including the two-file owner shape (D-OV-11/12) — no residue; §1.B.7 landed
with the import-sourced skip — no residue; the `ResolveAsScope` arm the plan
never anticipated (D-OV-13); §6.B's nine files are nine, but import.cpp and
decl_name_stack.cpp replace type.cpp and sem_ir/function.cpp; `unused` on
every unused runtime binding so positives carry no warnings. W-025 notes
corrected: the OV-1 hand-off sentence claiming import_member_specific.carbon
is deleted at OV-2 was wrong (it is kept; comment edit only), and the base
numbers are restated against the trunk of-record scoreboard.

VERIFICATION is hosted-only (R28(b)). Autoupdate: run 36459794418 (fill
71fa9bb1a, one pass over commits 1-3; no pre-existing golden moved beyond
the planned fail_todo_gates.carbon subfile deletions and the
import_member_specific.carbon comment), run 37325822499 (fill fc3a74dce
after 24cacacf3; the three refuted predictions above), run 37331151699 (fill
657bbe634 after 843d20244; one pass). Gate: run 37333625063. Conformance: run
37333428997, **121 PASS / 0 FAIL / 24 SKIP over 145, 46/56 bullets** — expected 121 PASS / 0 FAIL / 24 SKIP over 145
programs, 46/56 bullets, from the trunk of-record base READ FROM
origin/trunk's fork/conformance/out/scoreboard.json (3c9df53f7, OV-1
merged: 118 PASS / 0 FAIL / 24 SKIP over 142; this branch's in-tree copy is
the UN-2-era 6e6e4c7a9, 116/0/25 over 141, which predates OV-1's of-record
run and is replaced by the orchestrator's scoreboard push). Delta PASS +3 /
SKIP 0 / total +3 as plan §5.B predicted — §1.B.5 was not refuted, so the
+2/+1/+3 fallback does not apply. Reconciliation greps (§8.4) at 657bbe634:
`overload set import` has ZERO hits in toolchain (sources and goldens); the
generic-parameters, generic-scope and `extern overload fn` TODO strings are
gone from sources (the phrase `extern overload fn` survives only in two
comments, handle_function.cpp:264 and :273, describing the owning
redeclaration) and from fail_todo_gates.carbon; the remaining gates are one
site each — handle_function.cpp:422 (x), :435 `self`-only, :855 (ix), :859
(xiii), :902 (iii), :908 (v), :918 (vi), call.cpp:453 (xii), :535 (xi) —
plus fail_todo_gates.carbon; `overload set export` is generate_ast.cpp:256
and fail_todo_export.carbon:28; the two OV-2 kinds have one kind.def line,
one `CARBON_DIAGNOSTIC` and one emit site each and fire in
`fail_frozen.impl`, `fail_cross_library_adds_member` and
`fail_extern_non_member`; `DiscardCleanupsSince` is ONE hit (call.cpp:504;
the probe exits through a single unwind); `git diff 490ee40cd...HEAD
--diff-filter=M` over the testdata trees lists only fail_todo_gates.carbon
(three subfiles deleted, as planned) and import_member_specific.carbon
(comment); fail_todo_impl_file.carbon is deleted (its `impl_local` pair
survives as import.carbon `impl_local_set`).

RESIDUE, filed with blocked_by [] (ids follow this branch's ledger max
W-104; the slices branch allocates independently, so the orchestrator
renumbers at merge if they collide): W-105 probe-minted specifics evaluated
before conversion decides (`ProbeOverloadCandidateInScratchScope` →
`DeduceGenericCallArguments` → `MakeSpecific` → `ResolveSpecificDecl`: a
candidate that deduction accepts and conversion rejects has its declaration
block evaluated into `specifics()`, and that evaluation may diagnose — the
`discard_probe_constants` shape; `DeduceImplArguments` mints only after
success); W-106 `diagnose=false` deduction accepts an `ErrorInst` argument
(deduce.cpp's `RuntimeConversionDuringCompTimeDeduction` path and the
incomplete-deduction path substitute `ErrorInst` and succeed when not
diagnosing, so the probe can accept a member the commit then diagnoses —
inherited from trunk's `diagnose_` design); W-107 an impl-file `extern
overload fn` whose set localized to `ErrorInst` (or whose redefinition was
rejected) still gets `ExternRequiresDeclInApiFile` from the plain path
(handle_function.cpp:1022 on the no-merge path — the recovery trunk's plain
functions share; `fail_extern_api_defined.impl` pins the
rejected-redefinition case).

PLAN §0.2 CORRECTIONS carried into the ledger (items 6, 10 and 13 per
§8.5): "cross-library" covers the api/impl half of "same library" (both go
through the import resolver and are lifted together — the W-025 title's
note); `DeductionContext` already carried `diagnose_`, so the change is an
entry-point parameter plus the discard scope; the implementation-file
marker is `impl library "x";` throughout.

_V-3a divergence-risk register entries (reviewed at each upstream merge):_
OV-1's entries stand; OV-2 adds the two diagnostic kinds
`OverloadSetFrozen`/`OverloadSetDeclaredHere`, the
`replace_prev_inst`/`prev_decl_override` parameters of
`MergeFunctionRedecl`, the `diagnose` parameter of
`DeduceGenericCallArguments`, the `GetApiClassDeclForQualifier` arm of
`ResolveAsScope` (a trunk-level fix upstream may land differently — on
merge, keep whichever resolves `fn C.F` in an impl file and drop the other)
and the `OverloadSetValue` arm of `AddImportRefOrMerge`. Veto-able.

### OV-1: `overload fn` closed sets, first-match resolution (2026-09-28)

Milestone bullet "Functions: function overloading (Carbon-native)" flips
MISSING → PARTIAL (fork/gap-analysis.md row 57; header 27 DONE / 22
PARTIAL / 6 MISSING / 1 DESIGN-ONLY over 56). Landed on
claude/carbon-fork-0-1-overload in the four commits fork/overload/plan.md
§3 fixed — f18daf9e5 (the `overload` keyword and declaration modifier),
495b58274 (the `OverloadSet` SemIR entity, declaration merging and
first-match resolution), 51f831638 (check and lower goldens, conformance
programs), f3daa13e1 (the ported design page and its sibling edits) —
plus cd6d97a42 (the export-name switch arm, below) and ad2cb5031
(implementation-review fixes). The plan's OV-1 slice was W-024; W-025
(OV-2, set import and generic members) is next and W-026 (OV-3, export)
follows UN-2 per D-OV-7/D-OV-9. Design authority was not reopened: F-009
and the option paper fork/design-sprint/function-overloading.md Option A
stand; every decision below is an implementation choice the design
leaves to the toolchain, auto-adopted under R29(a) and veto-able after
the fact.

DECISIONS, rev 2b spellings, each with its break condition. **D-OV-1** —
`overload` is a new `CARBON_KEYWORD_TOKEN` and a declaration modifier in
the `Decl` order group, so it is mutually exclusive with `virtual`,
`abstract`, `override`, `impl`, `default`, `final`, `export` and
`returned` through the existing `ModifierNotAllowedWith`; the stranded
page's YES for `overload` with `virtual` (sub-fork F-009d) is DECLINED
for 0.1 because vtable slots are keyed by name, and F-009m (modifier
position) is moot. Break condition: a design ruling that `virtual
overload fn` is required — then a seventh order group and
signature-keyed vtable slots, never a silent relaxation. **D-OV-2** — the
entity is `SemIR::OverloadSet` mirroring `CppOverloadSet` (`{name_id,
parent_scope_id, member_decl_ids}` in declaration order); name lookup
binds an `OverloadSetValue` inst of type `OverloadSetType`, `AddInst`ed
into the current block right after the first member's `fn_decl`;
`Function` gains `overload_set_id`, printed only when set; the store is
not in `OutputYaml`, so the raw_sem_ir goldens did not move. Break
condition: none. **D-OV-3** — member identity is parameter-TYPE equality
(`CheckRedeclParamsMatch(diagnose=false, check_syntax=false)`); the
first type-equal member is the one being redeclared and
`MergeFunctionRedecl` diagnoses everything else (p003763 preserved per
member); the marker must be on every declaration of the name or on none
(`OverloadMarkerMismatch` + `OverloadMarkerPrevious`; an unmarked later
declaration recovers AS IF marked, a marked declaration against a plain
function is not merged); members distinguished only by `self` are
TODO-gated. Break condition: none. **D-OV-4** — resolution is a
first-match loop in declaration order: receiver alignment (reason 3;
only a receiver bound to a non-method is illegal — the explicit receiver
`C.M(c, ...)` is a legal landed shape), exact arity through
`GetExplicitArityRange` (a range for W-013 variadics; reason 0), the
template-dependence gate, then a value-conversion probe inside the
`DeduceImplArguments` discard scope extended with a cleanup-depth
snapshot and `DiscardCleanupsSince` on every exit plus a mandatory
block-size/cleanup-depth CHECK, with an `IntLiteral` range pre-test
through the shared `IntFitsInIntType` predicate (reason 1); commit by a
fresh `BuildNameRef` (re-wrapped as `BoundMethod` when the callee was
bound) into the unchanged `PerformCallToFunction`; `OverloadNoMatch`
plus one `OverloadCandidateRejected` note per member otherwise; no
ranking; `Convert` diagnoses `OverloadSetNotCallee` for every non-call
use; calls from checked-generic bodies resolve once, at the definition.
Break conditions: a member the probe accepts and the commit rejects
(R-1); the CHECK firing (R-2); a probe diagnostic outside the R-15
residue's enumerated cases. **D-OV-5** — mangling by set-relative index:
`:overload<N>` after the name (`_CPick:overload0.Main`), no fingerprint
(inst fingerprints are not cross-file stable, plan §0.1 row 9; the W-024
title's mechanism is recorded as rejected). Break condition: two members
mangling equal — impossible by construction; falsifier: one `define` for
two members. **D-OV-6** — thirteen 0.1 gates, each a `SemanticsTodo`
with a fixed string: (i) generic members, (ii) sets in generic scopes,
(iii) non-value explicit parameters, (iv) `extern` members, (v) the
entry point, (vi) differing access, (vii) set import incl. api/impl,
(viii) export, (ix) interfaces, (x) mixed `self`, (xi)
template-dependent arguments, (xii) explicit `ref self`/`addr self`
receivers, (xiii) `impl` bodies (covers destructors, which are `impl as
Core.Destroy`). Break condition per gate: the lifting slice deletes the
gate and its `fail_todo_*` pin in the same commit. **D-OV-7** — three
PRs: OV-1 same-FILE sets (the api/impl half of "same library" is the
import resolver, so it is gated on the `HandleUnsupportedCppOverloadSet`
precedent and lifted together with cross-library import at OV-2), OV-2,
then OV-3 after UN-2. Break condition: none. **D-OV-8** — the stranded
design page (481e08c24) is PORTED, not re-authored (below). Break
condition: the owner's veto digest changing a sub-fork ruling — then a
doc-only amendment, never a toolchain reopen without a new F-decision.
**D-OV-9** — W-007 is discharged for OV-3 by the EH-B/UN-2 precedent
(additive arms in cpp/generate_ast.cpp plus sequencing after UN-2; no
W-007 file); the W-026 edge on W-007 is cleared at OV-3 discharge, not
now. Break condition: an export-machinery refactor landing first — OV-3
rebases over it. **D-OV-10** — `alias` of a set re-exports the whole set
(zero code; pinned `alias_of_set`), transitively through `export import`
(OV-2's `export_import_of_set`). Break condition: an `export import`
chain that drops or splits the set.

REVIEWS. Two adversarial plan reviews of rev 1: rev A REJECT (blockers
A1 the probe's cleanup leak, A2 `self` misalignment; majors A3-A7) and
rev B APPROVE-WITH-AMENDMENTS (B1-B14, incl. the port of the stranded
page), folded as rev 2 with the coordinator's R29(a) rulings (A2/F-009l
mixed `self` gate, A3 literal pre-test, B1 port, B4 template gate, B5
lifting the generic-scope gate in OV-2, B11 `export` exclusivity). A
focused re-review of rev 2 returned SIGN-OFF-WITH-AMENDMENTS (0
blockers; M1 the explicit receiver is a legal shape, which added gate
(xii); M2 the generic-class test shape; m1-m6), folded as rev 2b. One
implementation review, APPROVE-WITH-FIXES. MAJOR-1: an imported set
MEMBER named in an imported generic's body resolved through the plain
`FunctionDecl` arm without its `overload_set_id`, so the specific
instantiated in the importing file would call an un-indexed mangled name
that collapses onto its siblings' — an undefined symbol at link with no
diagnostic. First fixed by gating the member import (the OV-2 "overload
set import" TODO), but the pin for that gate compiled CLEAN: the specific
of an imported generic reaches the member without ever importing the set,
so the gate was unreachable and the collapse live. Fixed at the root
instead (1baec5d70): the member's index is stored on `SemIR::Function`
(`overload_index`, mirrored by `ImportFunctionDecl`) and the mangler keys
`:overload<N>` on it, so an imported member mangles exactly as its
defining library did; the set entity itself stays un-imported until OV-2.
Pinned by the positive import_member_specific.carbon check golden and its
LOWER twin, whose falsifier is an un-indexed `_CP.Main` call in the
importing file's specific. MAJOR-2: the ported page's heading levels were corrupted by a
line-leading `#3763` (prettier turned it into a `##` heading and demoted
every following H2); repaired with heading parity to the stranded page
proven by diffing `grep '^#'` against `git show 481e08c24:...` (the only
difference is the added `### 0.1 limits`). Minors: gate (ii) takes
precedence over gate (i) (`else if`; one TODO for a method of a generic
class); the R-15 residue wording is "unconditional constant-evaluation
diagnostics inside overload probes: literal→float, abstract-init and
aggregate-literal element conversions"; an IWYU include in
sem_ir/overload_set.h; the plan's comma in `OverloadCandidateRejected`
reason 3.

THE EXPORT-SWITCH CRASH — a review miss per R28(d). check/import.cpp
`GetImportName` is a runtime-fatal switch over EXPORTED inst kinds
(`default: CARBON_FATAL("Unsupported export kind: {0}")`) that neither
the plan's R-3 mirror list nor the implementer's `CppOverloadSet` grep
named: a C++ set is never exported by name, so it has no arm there to
mirror. The first hosted autoupdate (run 36441457310) FAILED on an
api-scope `overload fn` set with "Unsupported export kind:
OverloadSetValue"; cd6d97a42 adds the arm (the set value maps to its
`OverloadSet` entity's name and parent scope; resolving it on import
stays gated in import_ref.cpp). The plan's landed notes add it to the
R-3 list as the third runtime-fatal class beside sem_ir/type_iterator.cpp
and the import_ref.cpp switch, and record that R-3's falsifier
(basic.carbon's fill) could not reach it — only a multi-file golden with
an api-scope set does.

DEVIATIONS from the plan, each in fork/overload/plan.md's landed notes:
`IntFitsInIntType` is a non-static function declared in eval.h (a
`static` cannot be shared across translation units), built from two
shared predicates so `PerformCheckedIntConvert` keeps emitting
`NegativeIntInUnsignedType` and `IntTooLargeForType` independently;
gates (ix) and (xiii) diagnose and then treat the declaration as an
UNMARKED function (a set value cannot be wrapped by
`BuildAssociatedEntity`), where the plan said the member is still added;
gate (xii) aborts the whole resolution (`ErrorInst`, no further
candidate tried) rather than rejecting one member; two mirror sites
beyond the plan's list — cpp/call.cpp's exhaustive `Callee` variant
switch (a `CalleeOverloadSet` arm) and lex/lex.cpp's hand-written
bracket-recovery modifier list — plus the `GetImportName` arm above;
spellings to this tree's working syntax (generic parameters are `[T:
type]` / `template T: type` because the plan's `T:! type` does not lex
here; the user destructor is `impl as Core.Destroy { fn Op(unused ref
self) {} }`; `fail_no_candidate` passes `1.5`; the api/impl pair is
`set.carbon` / `fail_set.impl.carbon`); the parse subfile
`fail_ordering` is `ordering` (its error is check-side); the doc links
to the em-dash decision-log headings carry no fragment (the check-links
hook percent-encodes the dash in the link but not in the anchor, so no
spelling validates — recorded in an HTML comment at the first link).

DOCS PORT (D-OV-8). docs/design/functions_overloading.md is `git show
481e08c24:docs/design/functions_overloading.md` edited in place: a dated
status paragraph after the Overview; every "OPEN (sub-fork F-009x)"
paragraph and sub-forks entry rewritten "CLOSED (fork amendment
2026-09-27) by D-OV-n" — a single-member sets legal (D-OV-3), b
same-file rule with impl files defining only (D-OV-7 +
`OverloadSetFrozen` at OV-2), c `self`-shape gated, d `virtual` DECLINED
with the vtable reason, e interface members gated, f per-candidate
notes, g `OverloadSetNotCallee`, h whole-set alias transitive through
`export import`, i export the exportable subset, j exact arity, k
invalid redeclaration of the type-identical member, l mixed `self`
gated, m modifier position moot; the two §0.2 item 14 corrections
("Linkage and mangling" rewritten to the `:overload<N>` index with the
§0.1 row 9 reason; exported members DO carry their Carbon mangled name
as an asm label); the rev 2b m3 rewrites (Decl-group placement, the
false `i32 → f64` divergence example replaced by `Pick`, the
marker-mismatch behavior, unions pinned and destructors under gate
(xiii), the full "0.1 limits" gate list, the R-15 probe annotation, the
checked-generics annotations, the template-dependent gate); and the
heading repair of MAJOR-2. docs/design/functions.md gains the ported
link block; docs/design/pattern_matching.md:696 and :1063 get the ported
hunks, each "(fork amendment 2026-09-27)"; words.md gains `overload`.
The interop README section and the README.md:3878 note are OV-3's. The
fork/ORCHESTRATION.md stranded-branch row gains "overloading portion
ported by OV-1/OV-3; do not re-land" — the owner's edit, not this
commit's.

VERIFICATION is hosted-only (the container's clang 18 cannot build the
toolchain; R28(b)). First autoupdate: run 36441457310 FAILED at the
`GetImportName` crash. Second autoupdate (after cd6d97a42): run
36444528619, success, filling every golden of commits 1-3 with zero
pre-existing goldens moved. Third autoupdate (after ad2cb5031): run
36446922583, success — every positive warning-free, `fail_todo_generic_scope`
down to one TODO, and the member-gate pin filled EMPTY (the finding
above). Fourth autoupdate (after 1baec5d70): run
36449480945, success, filling import_member_specific.carbon (check +
lower) — the importer's specific calls `_CP:overload0.Main` (the
falsifier `_CP.Main` did not appear). Gate: run 36451253811, green.
Conformance: run 36451200115 (scoreboard d8dce1343), **116 PASS / 0 FAIL
/ 24 SKIP over 140, 46/56 bullets** — the expected 116 PASS / 0 FAIL / 24 SKIP
over 140 programs, 46/56 bullets, from the trunk c0c57285f base READ FROM
fork/conformance/out/scoreboard.json: 114 PASS / 0 FAIL / 25 SKIP over
139 programs (the totals sum to 139 and the programs list has 139
entries; the plan's and the gap-analysis header's "over 140" were hand
counts, off by one). Delta PASS +2 / SKIP −1 / total +1 as plan §5.A
predicted; `git diff origin/trunk...HEAD --diff-filter=M` over the
check, lower and parse testdata trees is empty (no pre-existing golden
moved).
Of record on the trunk merge 490ee40cd (UN-2 #44 in): conformance run
36455269810 (scoreboard 3c9df53f7) READ FROM
fork/conformance/out/scoreboard.json: **118 PASS / 0 FAIL / 24 SKIP over
142, 46/56 bullets** — the same +2 / −1 / +1 delta over UN-2's 116 / 0 /
25 over 141 (the programs list has 142 entries); gate run 36455321083
green.

RESIDUE, filed with blocked_by []: W-094 virtual members of overload
sets (D-OV-1); W-095 members of overload sets with non-value parameters
(gate (iii)); W-096 `self`-shape overloading (D-OV-3; paper open
question 4); W-097 overload sets in interfaces (gate (ix)); W-098
per-candidate failure notes at Clang granularity (paper open question
7); W-099 mixed method/non-method overload sets (gate (x)); W-100
per-member access in overload sets (gate (vi) versus the ported page's
"visible members only"); W-101 overload resolution with
template-dependent arguments (gate (xi)); W-102 explicit receiver for
`ref self`/`addr self` overload members (gate (xii)); W-103 overload
sets in `impl` bodies (gate (xiii)); W-104 unconditional
constant-evaluation diagnostics inside overload probes: literal→float,
abstract-init and aggregate-literal element conversions (R-15). Ids
W-094..W-104 follow the ledger max W-093 on trunk c0c57285f (UN-2's
discharge allocated none). The conditional residues "extern members of
overload sets", "overload sets in generic scopes" and "marked members
without a definition" are filed only if OV-2's fallbacks fire.

PLAN §0.2 CORRECTIONS carried into the ledger (items 1, 2, 6, 9 per
§8.5): the W-024 evidence pointed at overloading_native.carbon's
EXPECT-EXIT line, not the SKIP line :10; the title's
"signature-fingerprint mangling" is rejected (not cross-file stable) in
favor of the set-relative index; "same-library" is re-cut to same-FILE
at OV-1 with api/impl at OV-2 (the titles gain a note, not a rewrite);
the paper's `overload fn Append[addr self: Self*]` method spelling is
replaced by the working `fn F(self)` / `fn G(ref self)` throughout.

_V-3a divergence-risk register entries (reviewed at each upstream
merge):_ upstream has no native function overloading; its p002875
placeholder spells `overloaded fn`, so the fork-only `overload` keyword
is a rename away. Fork-local surface added by implementation: the
`:overload<N>` mangling marker, the `OverloadSet*` inst kinds and the
`OverloadSetId` store, the five diagnostic kinds and the
`overload_set_id` field of `Function::Print`. F-009's register entries
(closed sets, first-match, the marker) stand. Veto-able.

### UN-2: union C++ interop (2026-09-28)

Milestone bullet "Type system: Unions (un-discriminated) + C++ union
mapping" flips PARTIAL → DONE (fork/gap-analysis.md row 47; header 28
DONE / 20 PARTIAL / 7 MISSING / 1 DESIGN-ONLY over 56). Landed on
claude/carbon-fork-0-1-un2, branched from trunk at c0c57285f after EH-B
(#42) and UN-1 (#43) had merged — the D-UN-7 sequencing, met by cutting
the branch after the merge rather than by a rebase — in the three commits
fork/unions/plan.md §3 fixed: 23fc16583 (check/cpp and sem_ir: `is_union`
on import, `TagTypeKind::Union` on export, the layout arm), f0970f148
(goldens and the two conformance programs), ad2367435 (dated design
amendments), then the 2026-09-28 weekly trunk sync 46f9d2112, 4f005ecdd
(the hosted autoupdate fill) and 3f89d7caa (implementation-review fixes).
W-015 is DISCHARGED; the plan's B half is complete and no union item
remains open beyond the UN-1 residue W-086..W-093. Design authority was
not reopened: F-007 and the ratified docs/design/unions.md stand; both
decisions below are implementation choices the design leaves to the
toolchain, auto-adopted under R29(a) and veto-able after the fact.

DECISIONS, as landed, each with its break condition. **D-UN-7**
(completed) — the export path creates a union's record with
`clang::TagTypeKind::Union` (`ExportClassToCppInDeclContext`,
export.cpp:81-82), and the two UN-1 placeholder guards — the `union
export` `SemanticsTodo` in `ExportClassToCpp` after the `clang_decls`
lookup and in `ExportNameScopeToCpp`'s class branch — are deleted, so
`grep -rn 'union export' toolchain` is empty and
check/testdata/union/fail_todo_export.carbon, whose only pin was the
guard, is deleted with them. The rev 2b m-3 pre-existing note stands
unchanged: `ExportClassToCpp` still passes the name-scope result
unchecked into `ExportClassToCppInDeclContext`, unreachable for unions
because D-UN-6 forbids nested types. Break condition: a D-UN-6
relaxation admitting nested types in a union body re-checks that call
before landing. **D-UN-8** — on export Carbon is the layout authority
for a union as for every exported record: `Class::GetStructTypeFields`
(sem_ir/class.cpp) returns the fields of a `CustomLayoutType` object
representation as it does for a `StructType` (both carry a
`StructTypeFieldsId`), so `ExportAllFieldsToCpp` and
`CalculateCppFieldOffsets` enumerate union fields instead of
CHECK-failing; `CalculateCppFieldOffsets` (sem_ir/read_only_ast_source.cpp)
records offset zero for every field of a union and does not advance the
layout; `layoutRecordType` is unchanged, supplying size and alignment
from `GetCompleteTypeInfo`, which for a union reads the
`CustomLayoutType` block; `CompleteType` (check/cpp/generate_ast.cpp)
adds no `FinalAttr` for a union; and no destructor thunk is declared,
because `IsTriviallyCopyableForExport` walks the union's
`CustomLayoutType` repr and answers true for every 0.1 union, so Clang's
implicit special members stay trivial. The R-11 trace outcome: the
arbiters `static_assert(__is_union(Carbon::Wide))` and
`static_assert(sizeof(Carbon::Wide) == 8 && alignof(Carbon::Wide) == 8)`
in check/interop/cpp/class/export/union.carbon compiled in the hosted
fill, so Clang's `ASTRecordLayoutBuilder` accepted the external layout
and D-UN-8's rejected alternative (returning `false` from
`layoutRecordType` for unions, a two-regime exception) was never needed.
Break condition: any exported union whose `static_assert`s fail or that
trips a Clang layout assertion; the contingency is still the rejected
alternative, recorded loudly as a two-regime exception.

THE BY-VALUE CROSSINGS (rev B F-5) and a corrected precedent claim. The
plan made `Cpp.SumLo(w)` — an exported Carbon union passed BY VALUE into
C++ — a PROBE in its own golden (union_by_value.carbon), with a drop
rule: on a `SemanticsTodo` the `SumLo` line leaves union_cpp_export and
a residue is filed. The probe PASSED in the fill (a `SumLo__carbon_thunk`
declaration and an ordinary call), as did the import direction
(`ReadA(Pair)` in, `MakePair` out) and the by-value return `MakeWide`,
so the drop rule was not exercised, no by-value residue exists and the
DONE row carries no by-value caveat. The plan's precedent claim for
`MakeWide` was WRONG: §4.B cited function/export/generic.carbon:41-46 as
"an exported class returned by value from inline C++", but that file's
`G()` is defined inside the inline C++ block and never called from
Carbon, so `Cpp.MakeWide(1)` (check/export/union.carbon; conformance
union_cpp_export) is the first Carbon-side call through a
return-address thunk for a Carbon-owned record. The fill passed it, so
nothing was restructured and no residue is filed; the claim is recorded
as wrong because a failing probe would have been misdiagnosed as a union
defect instead of a thunk gap.

THE AGGREGATE GATE, a review-caught design-fidelity fix. As landed in
23fc16583, `is_union` on import let EVERY imported union take UN-1's
`ConvertStructToUnion` arm, so `union U { U() : a(0) {} int a; float f;
};` accepted `var u: Cpp.U = {.f = 1.0};` from Carbon — bypassing the C++
constructor and contradicting docs/design/unions.md:555-558 ("the import
preserves exactly Clang's determination. Carbon code is never _more_
permitted than C++ code with such a union") while the landed `{}` path
for empty imported classes admits aggregates only
(`ImportClassObjectRepr`). Fixed at the root in 3f89d7caa: the union arm
of `ConvertStructToClass` (convert.cpp:1005-1016) is taken for a
cpp-scope class only when the new `IsImportedCppAggregate`
(check/cpp/import.{h,cpp}) — `clang_decls().Lookup` of the class's first
declaration, the accessor `ExportClassToCpp` uses for imported classes,
then `getDefinition()` and `isAggregate()` — says so; otherwise the
literal falls through to the existing "Builtin conversion does not
apply" bailout and the ordinary `ConversionFailure`, exactly as for a
non-aggregate class (non_aggregate_init.carbon). Pinned by the new
`fail_init_non_aggregate` subfile of fail_union_init.carbon, CHECK-free
until the refill. The gate is a fidelity fix, not a design change: the
sentence it enforces was ratified at F-007, and the UN-2 doc amendment
(unions.md:345-348) records the gate in one sentence. Two minor fixes in
the same commit: the `EvalConstantInst(ClassInit)` fold suppression now
keys on a `CustomLayoutType` repr rather than `is_union` alone, so an
empty imported union's `StructType{}` initializer keeps folding
(union_init.carbon `empty_init`, its CHECK block stripped for the
refill); and import.cpp carries the comment that `is_union` is set on
definition import only, so a forward-declared-only imported union keeps
`is_union == false` and any later class-versus-union redeclaration check
must account for it.

IMPLEMENTATION DEVIATIONS from the plan, each recorded in the plan's
UN-2 landed notes. The import subfiles are a NEW
check/interop/cpp/class/import/union_init.carbon (designated_init,
empty_init, copy, by_value) plus fail_union_init.carbon
(fail_init_two_fields, fail_init_unknown_field,
fail_copy_nontrivial_member, fail_init_non_aggregate) beside the landed
class/import/union.carbon rather than appended to it: that file uses the
`convert` minimal prelude (min_prelude/convert.carbon: `as` and copy
parts only), which lacks `Core.Destroy`, `Core.Optional` and the
`IntLiteral` → `i32` conversion the local-variable shapes need, and
fail_ subfiles never share a positive file. The by-value probe is its own
file, union_by_value.carbon, so a `fail_` rename would not have touched
the positives. The lower `Pair` is `{int a; int b;}` (4 bytes), so
lower/interop/cpp/class/import/union_init.carbon shows `alloca [4 x
i8]`, not the `[8 x i8]` §4.B wrote — that size belongs to the
conformance program's three-member `Pair` (`int a; int b; int* p;`); the
exported `Wide` is `[8 x i8]` as planned. fail_todo_export.carbon is
deleted, and W-009's evidence entry citing it is re-pinned to
check/interop/cpp/class/export/union.carbon. Zero new diagnostics, as
§1.B.4 required: every negative pin reuses a landed kind
(`UnionInitNotSingleField`, `UnionInitUnknownField`,
`CppInteropParseError` for the deleted copy constructor,
`ConversionFailure` for the non-aggregate).

IMPLEMENTATION REVIEW: a single review, APPROVE-WITH-FIXES on the fill
4f005ecdd — the MAJOR aggregate gate and the two MINORs above, folded in
3f89d7caa; and the discharge artifacts (this entry, the ledger, the
gap-analysis row, the plan's landed notes).

VERIFICATION was hosted-only per R28: `Fork: hosted verification` in
autoupdate → gate → conformance. First autoupdate run 36438032097 filled
the six new goldens (fill 4f005ecdd); ZERO existing goldens moved, as
§6.B predicted (`git diff origin/trunk...HEAD --diff-filter=M` over the
check/lower/parse testdata is empty), and both probes — R-11's layout
`static_assert`s and the by-value `SumLo` — PASSED. Second autoupdate,
after the review fix 3f89d7caa (rebased as 0ec762ad2): run 36445060391, success (the refill
of `fail_init_non_aggregate` and `empty_init`; predicted: the
non_aggregate_init.carbon pair — `ConversionFailure` plus the
`MissingImplInMemberAccessInContext` note — and `class_init () [concrete
= constants.%Bar.val]`). Gate run 36447075548, green (a first gate,
36440202472, failed only on a not-yet-converged Clang snippet line number
in fail_union_init.carbon, converged by the refill). Conformance run
36447037687 (scoreboard
6e6e4c7a9): **116 PASS / 0 FAIL / 25 SKIP over 141, 45/56 bullets** — the §5.B delta exactly (the plan wrote "over 142" from a miscounted 140 base; the trunk base was 139), the §5.B
delta PASS +2 / total +2 on UN-1's post-EH-B base of 114/0/25 over 139;
bullets stay 45/56 because the unions bullet was already PASS at UN-1
(fork/conformance/out/scoreboard.json at 06557fb21: `status: PASS`,
`gap_status: PARTIAL`, now DONE), so the two new programs add PASSes,
not a bullet. `runner.py --self-test` clean and the README program table
regenerated at f0970f148. Reconciliation greps (§8.4), as run at
3f89d7caa: `union export` empty; `Builtin conversion does not apply` one
hit, convert.cpp:1020; `generic union` unchanged from UN-1 (one TODO
site, class.cpp:708).

THE DONE JUSTIFICATION (rev B F-6). The row's evidence is the UN-1 text
plus the UN-2 sentence and names every gated item by ledger id: generic
unions and unions nested in generic scopes behind the `generic union`
TODO (W-088); choice-typed (W-086) and imported-C++-typed (W-087) union
fields rejected by the 0.1 predicate; member-restriction message quality
(W-089); invalid-representation reads yielding poison rather than the
design's fail-stop (W-090); the copy predicate's textual-order
dependence for user impls (W-092) and its blindness to user blanket
`Core.Copy` impls (W-093). DONE-with-gated-residue has the row 44
precedent: Sum types is DONE with Self-dependent payloads and qualified
alternative patterns "still gated by diagnostics". The one condition
that would have kept the row PARTIAL — the by-value probe failing — did
not occur. W-087 is explicitly NOT lifted by UN-2:
`IsImportedCppAggregate` consults `clang_decls()` for the initialization
gate only, and the field predicate's cpp-scope arm remains the separate
review W-087 names.

PLAN CORRECTIONS (§0.2 items 5-8), recorded verbatim in the ledger: (5)
W-015's "convert.cpp:882-885 struct-literal bailout" was the
`ConvertStructToClass` bailout at :909-912 in the planning tree (:1020
today, after the gated union arm); the option paper's lower/type.cpp and
import.cpp ranges and its export.cpp record-creation sites had likewise
moved. (6) W-015's notes omitted two hard blockers on export —
`GetStructTypeFields` CHECK-failing on a `CustomLayoutType` repr and
`CalculateCppFieldOffsets` accumulating sequential offsets — and its
"layout agrees by construction" held only once Carbon supplied offset 0
for every union field (D-UN-8); both landed. (7) W-015's "needs the
shared trivially-copyable predicate (coherence risk 7, W-006)": it has
existed since F8b (2026-08-18) as `IsTriviallyDestructible` /
`IsTriviallyCopyableForExport`; only its `CustomLayoutType` arm was
missing, added at UN-1. (8) W-015's "gap-analysis row 32's 'opaque
interop types' claim is stale": `grep -n opaque fork/gap-analysis.md` is
empty — the reconciliation of 2026-09-27 removed it — so the note was
itself stale and is dropped from the ledger. Item 9 (W-007's contention
precondition met by sequencing) is closed in W-007's notes.

RESIDUE: none new. Every §8.5 item was filed at UN-1 (W-086..W-093) and
the conditional "exported union passed by value into C++" did not arise;
no ids are allocated and W-093 remains the highest id.

_V-3a divergence-risk register entries (reviewed at each upstream
merge):_ upstream imports C++ unions (the `CustomLayoutType` importer
this fork inherited) but has no `union` declaration and never exports a
Carbon union; `TagTypeKind::Union` on the export side and the
offset-zero layout arm are fork-local implementation surface with no
upstream counterpart to contradict. The `union` keyword and the
byte-reinterpretation reads remain F-007's register entries; UN-2 mints
no new public name and no new diagnostic. Veto-able.

### Scoreboard totals corrected: EH-B was 138 programs, UN-1 139 (2026-09-28)

An audit of the committed scoreboards (`totals.PASS + totals.SKIP` equals
the `programs` list length in every one) found the orchestrator's recorded
program TOTALS off by one for the last two landings: PR #42 (EH-B) is 112
PASS / 0 FAIL / 26 SKIP over **138** (recorded as 139) and PR #43 (UN-1)
is 114 / 0 / 25 over **139** (recorded as 140); the PASS/SKIP counts and
bullet counts were right, only the sums were miscomputed. Corrected in
place in the EH-B and UN-1 entries, ORCHESTRATION, the gap-analysis
header, the W-019 ledger notes and both plans' landed notes, and in the
two PR descriptions. Rule going forward: quote totals from
`scoreboard.json` (`PASS + SKIP + failures`), never from mental
arithmetic on deltas.

### UN-1: native `union` declarations (2026-09-27)

Milestone bullet "Type system: Unions (un-discriminated) + C++ union
mapping" flips DESIGN-ONLY → PARTIAL (fork/gap-analysis.md row 47; header
27 DONE / 21 PARTIAL / 7 MISSING / 1 DESIGN-ONLY over 56). Landed on
claude/carbon-fork-0-1-unions in the four commits fork/unions/plan.md §3
fixed — bd680c842 (the `union` keyword and the class-shaped parse),
d0cdd474e (check: a union as a `SemIR::Class` with an all-offsets-zero
`CustomLayoutType` representation), 8a8754198 (goldens and conformance),
b19f105e5 (dated design amendments) — plus d96369b93 (the deferral fix
below) and e54a7e1a7 (implementation-review fixes). The plan's UN-1
half was W-009; W-015 (UN-2, the C++ side) is next and is sequenced after
EH-B per D-UN-7. Design authority was not reopened: F-007 with the owner's
sub-decisions a..k and the ratified docs/design/unions.md stand; every
decision below is an implementation choice the design leaves to the
toolchain, auto-adopted under R29(a) and veto-able after the fact.

DECISIONS, final rev 2/2a/2b spellings, each with its break condition.
**D-UN-1** — a union is a `SemIR::Class` with the entity flag
`ClassFields::is_union`, whose object representation is a
`CustomLayoutType` with every field at offset zero and size/alignment by
the max-of-fields rule; every class facility the design grants unions is
inherited (fields as `FieldDecl`s through the unchanged class-scope path,
methods, `impl`, `alias`, forward declaration, member-of-class,
import/export of the entity). Break condition: none — the representation
is design-mandated. **D-UN-2** — the 0.1 field predicate is
`IsTriviallyDestructible` (with a new `CustomLayoutType` arm) plus a
class-keyed `HasNonTrivialUserCopyImpl` walk, NOT the SF-6 scalar
allowlist (which rejects the design's canonical `array(u8, 4)` field).
The copyable half's trust boundary (rev 2a, coordinator amendment): a
`Core.Copy` impl counts as user-provided only when declared OUTSIDE
package `Core`, bodied or builtin; the prelude's impls are trusted as
bitwise over trivially destructible shapes on the strength of the audit
recorded in the plan (copy.carbon `Bool`/`CharLiteral`/`FloatLiteral`/
`IntLiteral`/`type`/`T*` and `const T`; `Int(N)`/`UInt(N)`/`Float(N)`/
`Char`; the six `CppCompat` adapters — all `primitive_copy`; `NullptrT`
over `make_uninitialized`; `String`'s field-wise `{ptr, size}` copy;
`Optional(T)` delegating to `T.Copy`, whose pointer specialization is
`primitive_copy` — none has side effects or differs observably from a
byte copy). Mechanism (rev 2b B-1): the local-store leg skips every
import-materialized impl (`GetImportSource(first_decl_id).has_value()`,
because a materialized impl's `parent_scope_id` is `None` and rev 2a's
scope-based spelling would have diagnosed `var a: i32;` order-dependently)
and classifies file-declared impls by `sem_ir().package_id()`; the
imported leg classifies each `import_irs()` entry by its `package_id()`
and matches the field's class by canonical decl identity. The
symbolic-self shortcut of `HasUserDestroyImpl` was deliberately NOT
mirrored (the prelude's blanket `T*`/`const T`/`Int(N)`/`Optional(T)`
impls would disqualify every class). `Optional(T*)` is ADMITTED, as the
design says (rev 2's "bodied impl ⇒ rejected" rule, which would have
rejected the design's own idiom, is withdrawn with its pin, doc note and
residue). Break conditions: a prelude `Copy` impl that is not
observationally bitwise over an admitted shape (re-run the audit at every
weekly upstream merge touching core/prelude; the fix is an explicit
allowlist of prelude classes, never widening the boundary to user
packages); a blanket `Core.Destroy` impl appearing anywhere (none exists;
`HasUserDestroyImpl`'s shortcut then disqualifies every class and the
predicate gains a class-keyed `Destroy` match). Falsifier: the lower
golden of `optional_pointer_field` showing anything other than a plain
memcpy/load-store of the storage. **D-UN-3** — generic unions are
TODO-gated: a union with its own parameters OR nested in a generic scope
(`generic_id.has_value()`, the broad gate, rev B F-7) diagnoses
`SemanticsTodo` "`generic union`" at its definition and completes with an
error witness; the only symbolic-layout recompute in the tree is the
choice payload eval hook, which asserts tuple payloads and the SF-6
allowlist. Break condition: none in this workstream. **D-UN-4** —
designated single-field initialization is a `ConvertStructToUnion` arm
inside `ConvertStructToClass`, replacing the struct-literal bailout for
`is_union` classes, emitting a ONE-element `ClassInit`; and
`EvalConstantInst(ClassInit)` returns `NotConstant` for a union so the
initializer never folds into a `StructValue` (whose lowering casts to an
`llvm::StructType`, a CHECK failure against a union's `[N x i8]`). The
other fields are not covered with `UninitializedValue` (at offset 0 a
cover ordered after the designated store would clobber it). Break
condition: any autoupdate fill showing a `struct_value` of union type, or
a lowering CHECK in `EmitAsConstant(StructValue)` — neither fired.
**D-UN-5** — whole-union copy reuses the synthesized primitive-copy
witness: `LookupChoiceCopyWitness`'s gate is `is_choice || (is_union &&
!is_cpp_scope)`; an imported union keeps C++'s copy determination on the
C++ copy-constructor path. Declared consequence (rev B F-8): the
synthesized witness SHADOWS a user `impl as Core.Copy` written inside a
union body, the choice precedent carried over unchanged, pinned by
`user_copy_impl_shadowed` (check + lower). Break condition: UN-2's
negative pin `fail_copy_nontrivial_member` compiling clean. **D-UN-6** —
member restrictions are enforced at PARSE by a fourth `DeclContextKind`,
`UnionContext`, whose introducer table omits `adapt`, `base`, `class`,
`choice`, `constraint`, `interface` and a nested `union` (the interface
context's `var` precedent), diagnosing the existing `UnrecognizedDecl`;
`abstract`/`base` unions and `virtual`/`abstract` methods reuse the class
modifier diagnostics; a redeclaration that flips `class`/`union`
diagnoses `NameDeclDuplicate`/`NameDeclPrevious`. Four new diagnostics in
total (UnionFieldNotTriviallyCopyable, UnionInitNotSingleField,
UnionInitUnknownField, UnionWithoutFields), none for restrictions. Break
condition: none; residue W-089 for message quality. **D-UN-7** — two PRs,
UN-1 then UN-2, UN-2 rebased after EH-B merges; UN-1 carries a `union
export` TODO guard in `ExportClassToCpp` (after the `clang_decls` lookup,
so an imported union keeps returning its `TagDecl`) and in
`ExportNameScopeToCpp`'s class branch — the two entries whose callers all
handle nullptr — never in `ExportClassToCppInDeclContext`, whose three
callers dereference the result (rev A B-2). Recorded pre-existing (rev
2b m-3): `ExportClassToCpp` passes the name-scope result unchecked into
`ExportClassToCppInDeclContext`, unreachable for unions only because
D-UN-6 forbids nested types; any relaxation re-checks it. **D-UN-8** (a
UN-2 decision, recorded now for completeness) — on export Carbon is the
layout authority: `CalculateCppFieldOffsets` gets a union arm recording
offset 0 for every field, `layoutRecordType` keeps supplying
size/alignment from the `CustomLayoutType` block, and no `FinalAttr` is
added for a union; rejected: letting Clang lay unions out. **D-UN-9** —
unformed state by way of `Core.UnformedInit`: `UnformedInit` becomes a
`CoreInterface` kind and a `CoreIdentifier`; `LookupCustomWitness` gains
an arm calling `LookupUnionUnformedInitWitness`, which for a native
non-C++ union returns `BuildCustomWitness(..., /*values=*/{})` (legal
because the interface declares no associated entities), so the prelude's
blanket `impl forall [T: UnformedInit] T as DefaultOrUnformed { fn Op()
-> Self = "make_uninitialized"; }` applies and `var u: U;` lowers to a
poison value with the in-place `InitializeStorage` emitting nothing;
`LookupCppImpl`'s exhaustive switch gains `UnformedInit → None` (rev 2b
M-1), keeping imported classes' `DefaultOrUnformed` path on the C++
default constructor. Rejected: a synthesized `Core.Default` witness,
which would declare the variable FORMED against unions.md's unformed
contract. Break condition and falsifier: `ConversionFailureTypeToFacet`
on `var u: IntOrBytes;` in `unformed_then_assign` — the exact rev 1
failure; it did not fire.

PLAN CORRECTIONS (§0.2), recorded verbatim in substance: (1) the brief's
template path fork/w012/plan.md did not exist in the planning tree (the
W-012 workstream was in another checkout); fork/eh, fork/w077 and
fork/w5-choice were the templates. (2) W-009's evidence
union_basic.carbon:6 pointed at the `EXPECT-EXIT` line; the SKIP line was
:10. (3) W-009's "choice-pattern parse (~12 states)": `choice` has FIVE
states, and a union body is CLASS-shaped, so the parser follows the
`class` variant shape — five new variant states, four new node kinds, a
fourth `DeclContextKind`. (4) W-009's "symbolic max-size/max-align (route
b preferred)": route (b) landed at W5-S3b for choice payloads but is
SF-6-specific; the genuinely new piece was the designated-init
conversion and its fold suppression, and generic unions are TODO-gated.
(5) W-015's "convert.cpp:882-885 struct-literal bailout" is the
`ConvertStructToClass` bailout, at :1009 after UN-1 (the `is_union`
branch precedes it at :1004-1006); items (6)-(8) — the two UN-2 export
crash sites (`GetStructTypeFields` on a `CustomLayoutType` repr,
`CalculateCppFieldOffsets` accumulating sequential offsets), the "needs
the shared trivially-copyable predicate" claim (it exists since F8b; UN-1
added its `CustomLayoutType` arm) and the stale "opaque interop types"
note — are UN-2's to record. (9) W-007's five-way contention
precondition is met by SEQUENCING (UN-2 rebases after EH-B), not by the
refactor. (10) union_basic.carbon's SKIP reason "no design doc" was stale
since F-007; the stub is replaced. (11) unions.md said choice payloads
were unimplemented (W-010 DISCHARGED) and promised generic unions fall
out (they do not) — both carry dated amendments. (12) W-010's W-009
coordination line was accurate and is closed in its notes.

PLAN REVIEWS. Two adversarial reviews of rev 1: rev A returned REJECT
(blockers B-1 — `var u: U;` fails `DefaultOrUnformed`, the rev 1
evidence was a failure golden; B-2 — the export guard inside
`ExportClassToCppInDeclContext` would turn the CHECK into a null-pointer
crash; majors M-1 cpp-scope fields rejected, M-2 file-scope initializer
unpinned; minors m-1 `SkipPastLikelyEnd` recovery in the parse
negatives, m-2 `PrintClassFields` must print `is_union`) and rev B
returned APPROVE-WITH-AMENDMENTS (F-1 = B-1 as a blocker; F-2 the
destructible-only predicate and a false export.cpp sentence; F-3 = M-1;
F-4 stale counts after W-012; F-5 by-value crossings for UN-2; F-6 DONE
needs justification; F-7 the generic gate's breadth and a citation; F-8
an in-body `Copy` impl shadowed; F-9 UN-1 touches export.cpp; F-10
invalid-representation reads; F-11 assignment `w = v;`; F-12
namespace-scoped unions and unions as choice payloads; F-13 docs
cross-references; F-14 runtime cannot observe layout). All folded as rev
2 with two documented departures from the reviewers' text (the
`HasUserDestroyImpl` mirror cannot be literal; the `Optional(T*)`
reading). The coordinator's rev 2a amendment (prelude-trusted `Copy`
impls) was auto-adopted under R29(a) because rev 2 would have rejected
the design's own `Optional(T*)` example. The focused re-review of rev 2a
returned SIGN-OFF-WITH-AMENDMENTS, mechanism spellings only: B-1 the
local-leg `IsCorePackage(parent_scope_id)` misclassifying
import-materialized impls (order-dependent false diagnostics on `i32`
fields), M-1 the `LookupCppImpl` exhaustive switch, m-1 the second
`fail_todo_export` subfile reaching `ExportClassToCpp` first, m-2
`Interface::Print` does emit `core_interface`, m-3 the unchecked
name-scope pass — folded as rev 2b, no decision changes, signed off.

IMPLEMENTATION DEVIATIONS from the plan, each recorded in the plan's
Landed notes. `str` is `Core.String` in this toolchain (check/literal.cpp
resolves it through `CoreIdentifier::String`), so it is ADMITTED under
the rev 2a trust boundary, not rejected — D-UN-2(ii), §4.A's planned
failing `str` subfile and §8.6's doc text were wrong; `str` is pinned as
accepted in `aggregate_fields` and the doc amendment says so.
`BuildClassOrUnionDecl` also takes the popped `NameComponent`. Three
class-shape parity sites the plan's file inventory omitted, found by
auditing every `NodeKind::Class*` switch: the deferred-definition scope
kinds in check/node_id_traversal.cpp, the `IsDefinitionStart` set in
sem_ir/formatter.cpp, and the document-symbol outline in
language_server/handle_document_symbol.cpp. check/BUILD needs no edit —
it globs `handle_*.cpp` (the plan's §1.A.3/§2.A.4/§6.A item 16 said it
lists sources explicitly). The tree-sitter highlight entry is commented
on the `final`/`friend` precedent because grammar.js has no `union`
token (residue W-091). `fail_virtual_method` uses a bodied `fn`. And ONE
pre-existing golden moved, check/testdata/basics/raw_sem_ir/
cpp_interop.carbon, gaining `is_choice: 0, is_union: 0` in its `classes`
entry — the text the rev A m-2 `PrintClassFields` amendment itself
added; the plan's §6.A "zero existing goldens move" claim was false as
written because the m-2 fold never updated the churn inventory, and the
rev 2b m-2 argument (no raw-dump golden mentions `UnformedInit`) looked
at the interface tag, not the class fields. The §8.1 stop rule fired on
that one file; it was reconciled by inspection (the diff is exactly the
amendment's text, nothing else) rather than by halting, and commit
8a8754198 predicted it before the fill.

THE DEFERRAL REVIEW MISS. The first hosted autoupdate fill exposed one
defect, fixed at the root in d96369b93: method bodies written directly in
a union body were checked EAGERLY, before the union completed
(`IncompleteTypeInFunctionParam` / `IncompleteTypeInMemberAccess` with
`ClassIncompleteWithinDefinition` notes,
blanking lower/testdata/union/basic.carbon's `method` subfile), because
the PARSER decides deferral — `ParsingInDeferredDefinitionScope`
(parse/context.cpp) registers a `DeferredDefinition` only when the state
stack's top is a class/interface/regular declaration-scope loop under a
class/impl/interface/named-constraint definition-finish state — and the
union states were in neither list, so the check-side scope kinds UN-1
added in node_id_traversal.cpp never saw a deferred definition to replay.
Both lists now carry the union states, mirroring class. This is a review
miss per R28(d): the plan named node_id_traversal.cpp's deferred scope
as a parity site and no reviewer asked where deferral is DECIDED. The
`impl_member` failure in the same fill was a test-spelling defect, not a
deferral one: `u.Get()` needs `extend impl as I`, as for classes.

IMPLEMENTATION REVIEW: a single review, APPROVE-WITH-FIXES, folded in
e54a7e1a7 — the doc amendment said "Three" conservatively rejected field
types while listing two (`str` admitted); `AddStructTypeFields`, which
assigns each `Field::index`, now runs before the `generic union` TODO
gate so a union that completes with the error witness never leaves a
`None` element index in error dumps; and the discharge artifacts (this
entry, the ledger, the gap-analysis row, the plan's Landed notes).

VERIFICATION was hosted-only per R28: `Fork: hosted verification` in
autoupdate → gate → conformance. First autoupdate run 36313187966 filled
the 17 new goldens and surfaced the deferral defect above. Second
autoupdate run 36314113850, after d96369b93: the method/impl_member/lower
subfiles refilled clean, the only other movement being converged location
markers. A first gate (run 36315119109) failed on ONE non-converged line —
the Clang snippet line number a `CppInteropParseError` echoes in
fail_todo_export.carbon still reflected the previous fill's layout — so a
third autoupdate (run 36316933295) converged it. Conformance run
36315125503 (scoreboard b17874390) on the post-W-012 base: **110 PASS / 0
FAIL / 26 SKIP over 136, 45/56 bullets** — the predicted delta exactly. Of
record, after merging trunk with EH-B (#42): gate run 36318283448 green;
conformance run 36318245113 (scoreboard 06557fb21): **114 PASS / 0 FAIL /
25 SKIP over 139, 45/56 bullets**, again the predicted delta (on the post-W-012
base PASS +2 / SKIP −1 / total +1, that is 110 PASS / 0 FAIL / 26 SKIP over
136, 45/56 bullets; on a post-EH-B base 114/0/25 over 139 — as landed). `runner.py
--self-test` clean (136 programs, 56 bullets) and the README program
table regenerated, confirmed locally at 8a8754198. Reconciliation greps
run at discharge are in the plan's Landed notes; the one surprise is that
§8.4's "two refreshed comments" grep matches one line only because
custom_witness.cpp's refreshed comment wraps the phrase across two lines.

RESIDUE, filed with blocked_by []: W-086 union fields of choice type
(D-UN-2(i)); W-087 union fields of imported C++ type (D-UN-2(iii); the
`CXXRecordDecl::isTriviallyCopyable()` arm, deliberately not a UN-2
rider); W-088 generic unions and unions nested in generic scopes
(D-UN-3); W-089 union member-restriction diagnostics (D-UN-6); W-090
invalid-representation reads yield poison in 0.1 (R-16, F-007g future
work); W-091 tree-sitter union grammar; W-092 union field copy predicate
is textual-order dependent for user impls (a file-declared `Core.Copy`
impl after the union is invisible at the union's `}`); W-093 user blanket
`Core.Copy` impls are invisible to the union field predicate (the
class-keyed match skips non-`ClassType` selves). Ids W-086..W-093 assume
EH-B, which merges first, takes W-083..W-085 — verified at merge. The
"union fields of `Core.Optional(T*)`" and "file-scope union variables"
residues of rev 1/2 were withdrawn (admitted by rev 2a; pinned by R-14).
Choice-side note (rev B F-12): a union as a CHOICE PAYLOAD is governed by
the SF-6 allowlist, which rejects it — that is the Sum types bullet's
residue, not a union item. For UN-2's eventual DONE-with-gated-residue,
the row 44 precedent applies (Sum types is DONE with Self-dependent
payloads and qualified alternative patterns still gated by diagnostics);
if the by-value parameter probe of §4.B fails, the row stays PARTIAL.

_V-3a divergence-risk register entries (reviewed at each upstream merge):_
the `union` keyword, the class-shaped union declaration and the
byte-reinterpretation read semantics are already F-007's register
entries; UN-1 mints no new public name. Fork-local surface added by
implementation only: `Core.UnformedInit` as a `CoreInterface` kind and
`CoreIdentifier` (an existing prelude interface, now recognized by the
toolchain; no library change), the `is_union` raw-dump field, and the
four diagnostic kinds. Upstream has no `union`; p000157 leaves typed
union versus `Storage` open — no contradiction. Veto-able.

### EH-B: catching thunks, Cpp.Exception, Carbon::expected export (2026-09-27)

Milestone bullet "Error handling: C++ exception interop (-fno-except config,
calling throwing C++, exporting Carbon errors as std::expected/exceptions)"
STAYS PARTIAL (fork/gap-analysis.md, evidence rewritten; header counts
unchanged), exactly as fork/eh/plan.md §8.6 fixed: B3 landed, three residue
items remain. Landed on claude/carbon-fork-0-1-ehb in the plan's five commits
plus the review round: 94b588847 (the `Cpp.Exception` prelude class
`Core.CppCompat.Exception { adapt VoidBase*; }` with `Copy`/`UnformedInit`,
surfaced as `Cpp.Exception` by the `Cpp.nullptr` builtin path;
`Exception`/`Result` core identifiers; the `CppException` recognized kind; the
reserved-name pre-check in `ImportNameFromCpp` with the Warning
`CppReservedNameShadowed`), c83d33051 (catching thunks selected by `?`,
`Core.Result(S, Cpp.Exception)` calls, the `QuestionCppCatchingImportNote`
context note),
3eb4ed0e7 (`Carbon::expected` export mapping by name, `<carbon/expected.h>`
installed at `lib/carbon/include` on the default `-isystem` path,
`CppExportResultNeedsExpectedHeader`), afccce55f (the SF-1 fence diagnostic
inside the fenced thunk — the last, droppable commit), 973fd41f1 (CHECK-free
goldens, the conformance un-SKIP plus three programs, the dated doc amendments),
90d49c24d and aa04ea7e0 (the hosted-build and review fixes below). Per R29(a)
the plan's decisions are auto-adopted design recommendations under V-2/V-3;
veto-able after the fact. The §0.4 fallback split (two M PRs) was NOT invoked:
EH-B is one PR.

_D-EH-3 — `Cpp.Exception` storage:_ the 0.1 storage is the Itanium primary
exception object pointer (`__cxa_current_primary_exception()`, refcount +1 at
capture) held in a prelude adapter over `VoidBase*` — which IS "stores the
exception_ptr": on libc++abi a `std::exception_ptr` is exactly that pointer with
refcounting, and `Carbon::Exception::ptr()` in the support header reconstitutes
a real `std::exception_ptr` losslessly (D7). Two honest bounds, both forced by
SF-6 (a choice payload must be a scalar after adapters): `Cpp.Exception` is
trivially copyable and trivially destructible, so the refcount is released only
at process exit (the D7 release-on-destroy clause is deferred to the
choice-payload destroy-synthesis work; `MakeDestroyOpBody` is still upstream's
placeholder), and the lazy `TypeName()`/`Message()` accessors are deferred (they
need a synthesized C++ helper buildable only when `std::exception` is declared
in the TU). Both are the residue item W-083. Break condition: an SF-6 widening
past scalars (W-010's residue) reopens the release half as a real `Destroy` impl
calling `__cxa_decrement_exception_refcount`.

_D-EH-4 — the selection surface is `?` directly on the call:_
`PerformCppThunkCall` keys on the call's own parse node — when the postorder
successor of the `CallExpr`, walking up through `ParenExpr` nodes, is
`PostfixOperatorQuestion`, the callee is fence-required, and the mapped return
type does not itself implement `Core.Try`, the call goes through the catching
thunk and has type `Core.Result(S, Cpp.Exception)`. The other context the design
names — a binding or argument whose EXPECTED type is `Core.Result(S,
Cpp.Exception)` — needs an expected-type channel the checker does not have
(conversions run after the call is emitted) and is the residue item W-084, with
the workaround `fn Wrap() -> Core.Result(S, Cpp.Exception) { return
Core.Result(S, Cpp.Exception).Ok(Cpp.f(x)?); }`. A `noexcept` callee or `none`
mode never reaches the branch, so `?` then diagnoses the usual non-`Try`
operand. The SF-6 bound on the success type is stated in the doc amendment and
W-019's notes: `S` must be scalar or `void`; a class, `std::string` or
constructor return diagnoses `CppCatchingImportNonScalarSuccess` naming the
C++ callee (the SF-6 admission predicate checked up front). Break condition:
an expected-type mechanism landing (F-011's `let ... else` work may add one)
lifts W-084; the SF-6 lift removes the scalar bound.

_D-EH-5 — the SF-1 boundary-identifying diagnostic:_ delivered as `try { <call>
} catch (...) { __carbon_boundary_write(2, "carbon: C++ exception escaped into
Carbon through `<callee qualified name>`; terminating\n", len); throw; }` INSIDE
the still-`noexcept` fenced thunk, so the rethrow reaches the existing terminate
landing pad and B0's contract is unchanged; `write(2)` because `abort()` drops
buffered stdout and no linkable Carbon runtime object exists; the decl keeps a
distinct identifier with the asm label `getUserLabelPrefix() + "write"`
(macOS-portable). This closes the B0 SF-1..5 entry's item (1)
("boundary-identifying diagnostic recorded as a B3 follow-up") and W-016's
recorded DEVIATION. Drop rule (plan §7 R-9): if the commit fails hosted
verification twice after one fix round it is reverted alone and W-016's SF-1
line reopens citing the run. The "## OPEN forks" section stays empty: SF-9 was
already moved under Decided by the EH-A entry, and no other OPEN fork touched
EH-B.

_D-EH-6 — the split:_ EH-B is the second of the two sequential PRs (EH-A merged
as #40); dependency honored (`Core.Result` and `RecognizedTypeInfo::Result` came
from EH-A).

_Ledger corrections at discharge (plan §0.2, verbatim):_ [3] 3. **W-019
blocked_by W-007 ("five-way contention refactor plan before any two of these
start"):** W-007 is unblocked, S-sized, and still unwritten; none of the other
four contenders (W-015 unions, W-026, W-021/W-023 threading — the last two
DISCHARGED at F8b/F8d) is in flight. The precondition of W-007 ("before any two
start concurrently") is not met, so it does not gate this PR; §1.B.9 states the
additive landing shape that makes the refactor unnecessary now. [4] 4. **W-016
notes ("fenced (try/catch-terminate) thunks")** — the fence is the `noexcept`
exception spec, not a `try`/`catch` (thunk.cpp:529-533; the notes' own DEVIATION
line says so two sentences later). The title should not say try/catch. [6] the
row-67 half of item 6: the evidence rewrite of the exception-interop row (stays
PARTIAL). Applied in fork/inventory/work-items.json: W-019 → `implemented`,
DISCHARGED with its residue filed, blocked_by cleared; W-016 retitled to
"noexcept-spec fenced thunks" and DISCHARGED (its only residue was the SF-1
line; the fail_fence_thunk_unbuildable golden the runner was to fill is filled),
and W-020's stale blocked_by on W-016 cleared; W-007's notes record that EH-B
landed additively without the refactor (every edit a new function or switch arm;
the one factoring is `BuildThunkBody`'s call construction split into
`BuildCalleeCallExpr` + `BuildReturnValueStore`, reused by the catching body)
and that the item re-evaluates when a second contender starts; W-059's notes
gain the fence diagnostic's `write(2)` dependency and the macOS notes (asm
labels need `getUserLabelPrefix()`; libc++ on Apple does not re-export
`__cxa_rethrow_primary_exception`, so `<carbon/expected.h>` consumers link
`-lc++abi` there). Residue ids allocated by verifying the ledger's max id
(W-082, the W-012 discharge): **W-083** "`Cpp.Exception` accessors and
release-on-destroy" (blocked_by W-010 for the release half only), **W-084**
"catching-import selection in binding/argument contexts", **W-085**
"`Carbon::expected` import direction" — the plan's provisional W-080/W-081/W-082
renumbered everywhere they are cited here and in the gap-analysis row; the plan
text keeps the provisional numbers with its landed notes recording the mapping.

_V-3a divergence-risk register entries (reviewed at each upstream merge):_ (i)
the doc's "`Cpp.Exception` maps to `std::exception_ptr`" sentence is landed as
the layout-identical wrapper `Carbon::Exception { void* primary_; }` whose
`.ptr()` is the `std::exception_ptr` (the doc's own usage line already assumed
the wrapper; dated amendment). (ii) `<carbon/expected.h>` mirrors the fork-owned
choice layout — `unsigned char disc_` (0 = Ok, 1 = Err, the alternative order)
at offset 0, then `union { T ok; E err; }` at `alignof(Payload)` — so the export
is a reinterpretation, not a conversion; `static_assert`s pin
`offsetof(expected, payload_) == alignof(Payload)`, `sizeof(expected) ==
alignof(Payload) + sizeof(Payload)` and trivial copyability, so any future
non-scalar payload or layout change fails loudly at the header, not at runtime.
The header is C++17 (`std::expected` conversions only under `__cplusplus >=
202302L`), and the `Exception` members exist only with exceptions enabled, so
`--cpp-exceptions=none` builds see the same mapping. Foreign-exception contract:
`__cxa_current_primary_exception` returns NULL for an exception not thrown by
the C++ runtime, so the thunk still returns `Err` with a NULL primary;
`Exception::ptr()` then yields an EMPTY `std::exception_ptr` and `rethrow()`
calls `std::terminate()` (both commented in the header; `has_value()` is
unaffected). (iii) The catching thunk's identifier
`<callee>__carbon_catching_thunk` and asm label
`<mangled>.carbon_thunk_catch.<modes>` are fork-local names beside B0's
`__carbon_thunk`.

_Review record and the blocker:_ one implementation review (R28),
APPROVE-WITH-FIXES. BLOCKER: the catching thunk was imported through the public
`ImportCppFunctionDecl` path, which evaluates `IsCppThunkRequired` on the thunk
ITSELF — a member callee's implicit object parameter (`const C&` for a `const`
method) is not a simple ABI type, so `ImportFunctionDecl` would have built a
thunk-of-the-thunk and marked the function `HasCppThunk`, and the later
`SetCppThunk` would have tripped its CARBON_CHECK on `Cpp.obj.ConstMethod()?`.
Root-cause fix (aa04ea7e0): a new public `ImportCppThunkFunctionDecl`
(cpp/import.{h,cpp}) that does exactly what the fenced-thunk import does —
`AddImportIRInst` plus the static `ImportFunction`, nothing else — used from
`GetOrBuildCppCatchingThunkDecl`, with a CHECK-free `member` subfile (a `?` on a
potentially-throwing `const` method and on a non-const method through a pointer)
in the check golden and its `M` twin in the lower golden. MINOR fixes:
`IsCatchingCallSite` also rejects a desugared `LocId`;
cpp_exception_rethrow_export.carbon reshaped to `import Cpp;` plus a single
`inline Cpp` block (the interop/cpp_export_function.carbon shape). Finding 4
checked, no change: an SF-6-rejected `Core.Result` specific leaves the class
incomplete, so `RequireCompleteType` returns false and the catching call returns
`ErrorInst` before emitting any CFG.

_Two hosted-build compile misses, recorded as review misses (R28(d)):_ (1)
thunk.cpp called `getTargetInfo().getUserLabelPrefix()` on a forward-declared
`clang::TargetInfo`; the hosted autoupdate build failed and 90d49c24d added the
`clang/Basic/TargetInfo.h` include. (2) type_mapping.cpp's `LookupCppDecl`
returned `clang::QualType()` from a `clang::Decl*` function (run 36307696501);
aa04ea7e0 returns `nullptr` (`LookupCppType`/`LookupCppClassTemplate` wrap it
with `dyn_cast_or_null`) and two `size_t` narrowings in the fence diagnostic
were made explicit after a mental-compile pass over the whole C++ diff against
the LLVM checkout. The single review traced the Sema construction and caught
neither; both are the class "no local build, hosted-only compile" that R28
accepts and R28(d) records.

_Deviations from the plan, each with its necessity:_ `fail_none_mode` is its own
file, fail_catching_none_mode.carbon, because `EXTRA-ARGS` is file-wide, not per
subfile (plan §4.B listed it as a subfile). The Ok/Err arms converge exactly
as §1.B.3 specified — `InitializeExisting` into one shared `TemporaryStorage`
minted before the branch, read back with `ConvertToValueExpr` — after a first
landing through the `if`-expression shape (`AddConvergenceBlockWithArgAndPush`)
crashed the third hosted autoupdate (run 36308713023): lowering types a
block-argument PHI by the OBJECT type (lower/function_context.cpp:178) while a
value of a by-pointer type such as `Core.Result` is a `ptr`, so that shape only
carries by-copy values (no lower golden has an `if`-expression over class
values). Recorded as a review miss per R28(d). `cpp_catching_call_results` is a
`Map<InstId, FunctionId>` rather than a `Set<InstId>` so the `?` break-path note
can name the C++ callee. Reference-returning callees fail closed (a TODO plus
the FENCED fallback, never an unfenced call) because the out-pointer would need
the referent's address, not a placement-new copy. The thunk identifier is
`<callee>__carbon_catching_thunk` (parallel to `__carbon_thunk`), not the plan's
`__carbon_catching`. The catching thunk's build annotates Clang diagnostics
with the SAME `InCppThunk` note as the fenced build through a shared helper
(one `CARBON_DIAGNOSTIC` site); a separate `InCppCatchingThunk` note was
landed first and deleted when the diagnostics coverage test showed it is
unreachable (the catching body reuses the callee call the fenced build
already accepted). An SF-6 rejection produces `ErrorInst` before any CFG
is emitted (the predicate below). types.carbon exports
`cpp/exception` in alphabetical position (before `cpp/int`), not "after
`cpp/void`". The header carries `has_exception()`, `operator*` and an `ok()`
alternative-name beyond D8's list, and `value()` is non-throwing by precondition
(unlike `std::expected::value()`) so the header is usable with exceptions
disabled.

_Docs:_ docs/design/error_handling.md gained dated EH-B amendments (history
unrewritten): the entry point's `Cpp.Exception` message clause deferred (W-083);
the catching selection rule's binding/argument arm deferred (W-084) plus the
SF-6 scalar-or-`void` bound with its break condition; the `Cpp.Exception`
storage, release-on-destroy and accessor deferrals (D-EH-3); the
`std::exception_ptr` mapping sentence amended to `Carbon::Exception` with
`.ptr()`, the foreign-exception and Apple `-lc++abi` notes; the staging table's
B3 row marked landed. Residue items are referred to by title in the doc; the ids
above are allocated here.

_Verification (hosted-only per R28):_ gate and conformance are the hosted runs;
local verification is limited to `uvx prek` on the bookkeeping files.
Conformance of record (run 36315999330, scoreboard 3d398fe6f, after the fixes
below): **112 PASS / 0 FAIL / 26 SKIP over 138**, 44/56 bullets — plan §5.B's
tree-relative 109/136 plus W-012's one program, PASS +4 / SKIP −1 / total +3
exactly (the
un-SKIP of cpp_exception_interop plus three new programs, zero other movement;
`runner.py --self-test` and `--update-readme-table` clean per the implementer);
gate of record run 36315995464 green on the same head (32d93701d).
Hosted autoupdate: the branch itself modifies ZERO existing goldens (`git diff
origin/trunk...HEAD --diff-filter=M` over the testdata trees is empty; the six
goldens are new and CHECK-free), so the fill of record is expected to add CHECK
lines to those six and to move exactly the 27 lower goldens containing
`__clang_call_terminate` (plan §6.B) by the fence diagnostic's `write` call,
message global and `throw;` resume edge inside each fenced thunk — any other
file moving is a §6 miss to reconcile. _Fill of record (run 36310053869,
e247c2700):_ the six new goldens filled; THIRTY existing goldens moved, the 27
predicted plus three §6.B misses with the same benign cause — the check-side
AST dump thunk_ast.carbon (a `CXXTryStmt`/`CXXCatchStmt` around the callee
call), lower/optimize/clang_no_optimize_twice.carbon (its `terminate.lpad`
became a real landing pad with `exn.slot`/`ehselector.slot`) and
lower/debug_info.carbon (a `DILexicalBlock` for the try). Two negatives were
wrong and fixed at the root (c214b5adf): `fail_class_return` cascaded into
five follow-on monomorphization errors because `RequireCompleteType` returns
TRUE for an SF-6-rejected `Core.Result(Cpp.Widget, Cpp.Exception)` specific
(the class completes with an error-valued layout; `GetObjectRepr` is
`ErrorInst`), so the catching call now checks `IsInSliceChoicePayloadType` on
the success type BEFORE forming the specific and emits the new Error
`CppCatchingImportNonScalarSuccess`; the specific's completion behind it
is a `CARBON_CHECK` invariant (a drift between the predicate and the SF-6
rule is a toolchain bug, not a user diagnostic — the `CppCatchingImportPayloadNote`
belt was deleted when the coverage test showed it can no longer fire); and
`fail_ctor_return` spelled the
constructor call `Cpp.Widget(1)` instead of the tree's static-member form
`Cpp.Widget.Widget(1)`, so it never reached the catching lane. Both are
review misses per R28(d), alongside the two compile misses and the
convergence shape above. _Gate + conformance of record (runs 36311895668,
36311899697 on the fill b8abdb68a) both FAILED and were fixed at the root
(ebf12feae): the gate on `//toolchain/diagnostics:coverage_test` (the two
dead kinds above), the conformance suite on a SIGSEGV in
`CarbonExternalASTSource::FindExternalVisibleDeclsByName` while Clang parsed
`<carbon/expected.h>` — a constructor declarator inside a C++-declared class
nested in `namespace Carbon` (the export namespace) sends a
`CXXConstructorName` redeclaration lookup up to the namespace, and the
source's constructor arm `cast<CXXRecordDecl>`-ed the `NamespaceDecl`; now a
`dyn_cast` with a negative answer, pinned by
function/export/carbon_namespace_cpp_class.carbon and by inline members in
result_expected.carbon's skeletons. Veto-able.

### W-012: if-let / while-let / let-else landed (2026-09-27)

The milestone's if-let / let-else bullet flips MISSING → PARTIAL: `if (let P =
e)`, `while (let P = e)` and `let P = e else { diverge }`, with their `var`
spellings, land as desugarings onto the match engine (fork/w012/plan.md; F-011
Option A). PARSE (§1.2/§1.3): no `PatternCondition` grouping node — the `let P
=` prefix lives directly under the existing `IfCondition`/`WhileCondition` close
node, whose typed nodes gain an optional `PatternConditionPrefix` (break
condition: the typed-node test rejecting an optional struct before a mandatory
categorized field — fallback an untyped `NodeId condition`, identical tree
output). `let`-`else` RE-KINDS its introducer to `LetElseIntroducer` when the
parser reaches the `else`, the `ReplacePlaceholderNode` precedent (break
condition: a reviewer rejecting node re-kinding — fallback a distinct
`LetElseDecl` close node only, which §7 A-4 records as worse because it cannot
resolve `.Name` roots). The `else` BUDGET entry: `else` becomes
`CARBON_TOKEN_WITH_VIRTUAL_NODE` because a `let`-`else` needs three nodes with
no token of their own; this contradicts the ledger's "no lexer change" literally
but is a table constant, not a lexing rule (§7 R-3), recorded as a ledger
correction. Parse surface, exactly: FIVE node kinds (PatternConditionIntroducer,
PatternConditionInitializer, LetElseIntroducer, LetElse, LetElseDecl) and TWO
states (PatternConditionAfterPattern, LetElseFinish) — the pattern conditions
reuse `ParenConditionFinishAs(If|While)`, `let`-`else` the `CodeBlock` state.
CHECK (§1.4): `FullPatternStack::Kind::MatchCaseArm` plus a `MatchCaseContext`
entry ARE the refutable pattern context; a shared driver is factored out of
`EmitCaseArmTestAndBind` into toolchain/check/refutable_binding.{h,cpp} minus
the match-only usefulness and coverage blocks, so everything the engine admits
the forms admit and everything it gates they gate, with the engine's own TODO
strings (break condition: a gate site whose `MatchCaseArm` behavior is WRONG for
the new forms — that one site tests a new `Context` flag and everything else
stands). DEFERRED RESOLUTION (§1.6): the tree visits the pattern before the
initializer, so `.Name` resolution against the scrutinee type moves into
`ResolvePendingAlternative`, run by the driver once the scrutinee is known and
called immediately by `match` — a code move, and the 70 check and 9 lower match
goldens moved zero lines (§7 R-1's break condition, a match golden moving, did
not fire). The bare `.Name` root is an EMPTY synthetic `TuplePattern` (break
condition: the empty root breaking an engine CHECK — then the bare spelling
records `payload_pattern_id = None` and the driver classifies the
discriminant-only lane explicitly, same SemIR). TOMBSTONE RULE (§1.8,
veto-able): `let`-`else` bindings are in the enclosing scope from pattern time
but never initialized on the else path, so the `StartPatternInitializer`
tombstones stay live through the else block and are released by
`EndPatternInitializer` only at `LetElseDecl` — a use in the else block
diagnoses `UsedBeforeInitialization`; zero new machinery. RESERVATIONS AND ROOT
PEEK (§1.11-§1.13): `and`/`or` at the top level of a pattern-condition
initializer is a CHECK-time error, `PatternConditionChainReserved`, because no
precedence group expresses "all but `and`/`or`" (lifted when let-chains land,
W-081); the if-expression ambiguity is forbidden at the `else`
(`LetElseUnparenthesizedIfExpr`) with a targeted parse recovery that fires only
when the token after `else {` is neither `.` nor `}`; and
`HandleLet`/`HandleVar` peek a root `.Name` (`PushRootPattern` a root `var`
before `.`, which is what makes `case var .Some(…)` parse), so a plain `let .X =
e;` becomes an `AlternativePattern` root behind the TODO `alternative pattern
outside a refutable pattern context`. §7 R-6: the recovery inspects the state
stack (precedented, one token pair in one position); break condition: a false
positive beyond the struct-literal else operand — drop (b) and keep (a), users
then see the struct-literal error the design anticipated. F-011 RIDER 2,
restated with this slice's surface: if upstream #5101 lands a different
spelling, re-spell mechanically keeping semantics — what gets re-spelled is
exactly the five node kinds, the two states and the single-token peek in
`HandleParenCondition`; the check driver and SemIR are spelling-neutral.

AUTO-ADOPTED under R29(a), recorded for after-the-fact veto. **R29a —
the var-alternative lane** (§1.1): the `var`-wrapped alternative root
(`if (var .Some(n: i32) = opt)`, `var .Some(v: i32) = o else {…}`, the
design's own example) had NO lane in `EmitCaseArmTestAndBind`; it is
classified by an explicit `is_var_alternative_arm` computed BEFORE
`is_irrefutable_var_arm`, which excludes it (else `match`'s coverage
block marks a two-alternative choice exhaustive on that arm — pinned as
fail_nonexhaustive_var_alternative and var_alternative_then_default),
tested through `MatchCaseAlternativePatternMatch`, bound through
`MatchCaseBindPatternMatch` on the payload field ref with on-demand
storage, shared with `match` (so `case var .Some(n: i32)` works as a
side effect); bare `var .None` stays behind the binding-free-`var` TODO.
Rejected: dropping root-`var` to a follow-up (§7 A-8). Break condition
(§1.1): a review finding that the lane's storage must be frame-indexed
rather than on-demand — then root-`var` in the new forms drops to a
follow-up and everything else stands. **F-011a — else-block divergence
= the reachability predicate (`IsCurrentPositionReachable`), overruling
the literal return/break/continue list** (F-011 above; if-let.md:316-321).
A DEVIATION accepting a strict superset: every block the list accepts,
plus any block whose every path ends in `return`/`break`/`continue`
(pinned positive: nested_all_paths_return); a nested `if` without `else`
and `Abort()`-style calls are rejected, the latter pending a noreturn
rule (W-082). Break condition: owner veto — fallback is a last-statement
parse-node-kind test on the else block (one function, same diagnostic
`LetElseBlockFallsThrough`), which then rejects the superset cases.
**Design-paper open questions resolved** (if-let.md:569-596): Q1
`let`-`else` terminator — NO trailing `;`, the paper's own assumption
(§1.3; the `;` alternative is §7 A-3/R-3, rejected because it would make
`let`-`else` the only brace-terminated construct that also needs a `;`);
Q5 `var` forms — INCLUDED, with the root-`var` lane above (its break
condition is R29a's); Q6 an irrefutable pattern in the combined forms —
a Warning, `IrrefutablePatternAlwaysMatches` (§1.10, per
if-let.md:327-329), not an error. The plan records no break condition
for Q1 and Q6 beyond the standing R29(a) veto. Q2/Q3/Q4/Q7 were already
fixed by §1.12, F-011a, the slice definition and §1.11.

IMPLEMENTATION REVIEW FIXES (commit d77b5dd19): `HandleParenCondition`'s
`let`/`var` peek was shared with the `match` variant, so `match (let …)`
produced a pattern prefix under a `MatchCondition` node and crashed
`Tree::Verify`; the peek is now gated to `if`/`while` and `match (let …)`
diagnoses an expected expression (parse fail_let_condition). `let P else
{…}` without `= e` built an error-free `LetElseDecl` whose mandatory init
field failed extraction (a debug FATAL); `LetElseDecl::init` is now
optional, the `LetDecl::initializer` precedent, so check's
`ExpectedInitializerAfterLet` path is reachable (parse
let_else_missing_initializer, check fail_missing_initializer). And
(commit 7b6257535) the hosted autoupdate's compile failure: `LetElseDecl`
had nine fields and common/struct_reflection.h caps typed parse nodes at
eight, so `equals` + `initializer` moved into a nested `LetElseInit`
aggregate (the `PatternConditionPrefix` precedent; check reads the node
stack, so no consumer changed). TESTDATA AUTHORING FIXES found by the
hosted autoupdate fill (commit b134c2022): nested_payload_tuple used a
`(i32, i32)` payload, which is behind upstream's "choice alternative
payload that is not trivially copyable and destructible" TODO — now a
two-field payload `Pair(a: i32, b: i32)`; question_in_initializer
converted an IntLiteral straight to the adapter `Tok` and needed
`(0 as i32) as Tok`. Both are authoring errors the refill exposed, not
compiler defects. Residue filed: W-080 (the design's refutability ERROR
for plain `let`/`var`, replacing the `expression pattern` and
`alternative pattern outside a refutable pattern context` TODO lanes),
W-081 (let-chains), W-082 (noreturn divergence). W-012's `blocked_by`
(`W-008`, `W-010`, both long landed) is cleared.

VERIFICATION was hosted-only per R28: `Fork: hosted verification` on
ubuntu-22.04 reading upstream's remote cache
(`--noremote_upload_local_results`), autoupdate → gate → conformance. The
autoupdate refill touched only the 26 new golden files — no pre-existing golden
under toolchain/{parse,check,lower}/testdata moved, so the §8.1 zero-diff proof
for the `EmitCaseArmTestAndBind` factoring holds (with the §8.1 caveat that it
cannot see a `var`-wrapped alternative root; the two new match negatives are
that guard). Conformance (run 36306915573, scoreboard f8ee67837): **108
PASS / 0 FAIL / 27 SKIP over 135**, 44/56 bullets — the plan's
tree-relative target of 104/0/27 over 131 (if_let_let_else un-SKIPped,
while_let added) plus EH-A's four programs, since trunk (#40) was merged
in before the gate. Gate run 36306909481 green on the same merge.

### EH-A: Core.Result, Optional as Try, Result entry points (2026-09-27)

Milestone bullet "Error handling: dedicated control flow constructs" flips
PARTIAL → DONE (fork/gap-analysis.md row 66; header 27 DONE / 19 PARTIAL /
8 MISSING / 2 DESIGN-ONLY). Landed on claude/carbon-fork-0-1-eh in the
four commits fork/eh/plan.md §3 fixed: a27059915 (the prelude
`Core.Result(T, E)` choice, library "prelude/types/result", `Ok`=0/`Err`=1,
with its `final` `Try` impl — the first `match` compiled inside package
`Core`, needing the explicit `prelude/operators/comparison` import for the
file-scoped `Core.EqWith` lookup; `Optional`'s `Try` impl; the `()` payload
admission in `IsInSliceChoicePayloadType`; `RecognizedTypeInfo::Result`;
the D10 entry-point check with the four-shape diagnostic text), ea1822f66
(a `Result`-returning `Main.Run` lowers as `i32 main()` with NO parameters
— the return param is ignored in `FunctionTypeInfoBuilder`, bound to a
local alloca in `BuildFunctionBody` — and the D10 epilogue at `ReturnExpr`:
`.Ok(())` → 0, `.Ok(code)` → code, `.Err(e)` → `write(2, ...)` naming `E`,
exit 1), 1918b307e (CHECK-free goldens for the autoupdate to fill; the
W-070 `fail_unit_break_type` pin moved to check/testdata/choice/
unit_payload.carbon as a POSITIVE test with a lower twin; four conformance
programs), c127784c4 (the runner-exposed `Destroy` bound, below). Zero new
diagnostics; no leading-period `.Ok(...)` shorthand exists in this tree, so
constructors are spelled `Core.Result(T, E).Ok(...)`; type_mapping.cpp's
`case Result:` carries a TODO for EH-B. Per R29(a) the plan's §0.3
decisions are auto-adopted design recommendations under V-2/V-3;
veto-able after the fact.

_D-EH-1 — SF-9 resolved:_ `Core.Result(T, E)` is minted as an INDEPENDENT
prelude choice, and `Core.Optional` KEEPS its placeholder class identity —
it is NOT re-platformed onto `choice` (that is W-058's approved-design
work, with the pointer null-niche ABI and the entry-point
`argv: Core.Optional(char*)*` signature to preserve); it gains a `Try` impl
over its existing `HasValue()`/`Get()` API. "How `Core.Result` relates" is
answered as D9 already says: no implicit bridge, two independent `Try`
implementers. V-3 check: upstream has no `Result`; upstream's `Optional` is
the same placeholder — no contradiction. The impl SIGNATURE landed is the
design sketch's (error_handling.md, "The `Core.Try` interface") MODULO the
bound: `final impl forall [T: Destroy & OptionalStorage] Optional(T) as Try
where .ContinueType = T and .BreakType = ()` (core/prelude/types/
optional.carbon:69-70) — `OptionalStorage` because the placeholder class
forces it on `T` (optional.carbon:29), `Destroy` because `Branch` moves the
`T` payload (the runner-exposed correction below; the plan had recorded
`OptionalStorage` alone). Break condition: if W-058's approved design makes
`Optional` a choice, the impl BODY is rewritten to the doc's `match`
sketch; the signature stays.

_D-EH-2 — W-070 resolved by option (a):_ the zero-sized empty tuple `()` is
admitted as a choice payload element — one predicate edit
(`IsInSliceChoicePayloadType`, toolchain/check/type.cpp) that the
definition path and both per-specific eval-hook sites consult, so no second
predicate exists. It keeps D9's `BreakType = ()` and D10's `Result((), E)`
literally true, is trivially copyable and destructible (the W-071
structural-trust note stays valid), and changes no existing choice layout
(a `((),)` payload tuple has size 0; `ControlFlow(i32, ())` lays out as
`<{ <{ i1, [3 x i8] }>, [4 x i8] }>`). Rejected: a scalar break carrier for
`Optional` (contradicts D9's text). Break condition: a lowering defect on
zero-sized payload stores flips `Optional` ONLY to the scalar carrier with
a dated D9 amendment; `Result((), E)` is unaffected (its `()` sits in a
two-payload region sized by `E`).

_Ledger corrections at discharge (plan §0.2, verbatim):_ [1] 1. **W-017 title/kind ("design-needed", "Core.Result choice in the prelude + match-based consumption + conformance programs", blocked_by W-008/W-010):** the design is ratified (docs/design/ error_handling.md:94-124) and both blockers are landed (W-008 W8c COMPLETE 2026-09-25; W-010's payload construction/destructuring landed S1-S3c). What is actually missing is the prelude file (§0.1 row 9), and the real gate was SF-9 (OPEN, decision-log:15-26), which the ledger does not record as a blocker at all. [2] 2. **W-018 ("design-needed", "postfix `?` operator + Core.Try interface + ImplicitAs error conversion", blocked_by W-017):** everything in the title landed at B1b/B2a (§0.1 rows 4-8) — over user choices. The blocked_by edge is inverted: `?` does not wait on `Core.Result`; the prelude `Try` IMPLS (rows 10-11) do. W-018's note "Bare Question token already lexed and unused (token_kind.def:103)" is also stale — the token is at :108 and is consumed by the parser.
[5] 5. **W-070 blocked_by "SF-9":** the unit-break bound is an SF-6 allowlist question (type.cpp:313-320); SF-9 (Optional's identity) does not decide it. This plan decides it (§0.3 D-EH-2). [7] 7. **decision-log OPEN fork SF-9 (:15-26)** was to "ride the W5-S3p AskUserQuestion round" whose ask package (fork/b2/plan.md §3 B2b, :397-420: `fork/design-sprint/s3p-ask.md`) was never written — no such file exists, `git log --all | grep -i s3p` is empty. Under R29(a) there are no more question rounds; §0.3 auto-adopts the recommendation. Applied in fork/inventory/work-items.json: W-017 and W-018
→ `implemented`, blocked_by cleared (W-017 retitled and re-evidenced;
W-018's token line corrected to :108); W-070 DISCHARGED at EH-A by option
(a), blocked_by cleared; W-058's notes carry the corrected impl signature;
W-059's notes gain the POSIX `write(2)` dependency of the entry-point
epilogue (plan R-5). W-016/W-019/W-007 and the three residue items are
EH-B's.

_V-3a divergence-risk register entries (reviewed at each upstream merge):_
(i) `Core.Result(T, E)` as an INDEPENDENT prelude choice with a `final`
`Try` impl — upstream has no `Result` type and no `Try`; F-006a's `Ok`/`Err`
spellings and B1's `Core.ControlFlow` are already on the register; the new
surface is the library name "prelude/types/result" and the `Ok`-first
discriminant order (Ok=0, Err=1) that the entry-point epilogue and EH-B's
`Carbon::expected` header rely on. (ii) The `()` payload admission — a
widening of the fork-local SF-6 payload allowlist; upstream's choice design
has no such allowlist, so admitting `()` moves toward upstream and cannot
contradict it; the zero-size `((),)` region layout is fork-owned until
upstream lands a choice layout of its own.

_Runner-exposed defect — a review MISS (R28(d)) and a lesson:_ plan §7
R-12's falsifier fired exactly as written, on optional.carbon rather than
result.carbon. The first hosted autoupdate (run 36301020281) moved ~230
goldens — every full-prelude golden gained the same two errors,
`optional.carbon:71: cannot access member of interface Destroy in type T
that does not implement that interface [MissingImplInMemberAccess]`, and
the lower goldens collapsed. Root cause: inside `forall [T:
OptionalStorage]`, `Branch` moves a `T` payload into `ControlFlow(T,
()).Continue(...)`, and a symbolic `T` bound by a non-`type` facet carries
only its declared constraints, so `T: Destroy` was unprovable
(result.carbon's `[T: type, E: type]` impl was fine). Fix, c127784c4:
`final impl forall [T: Destroy & OptionalStorage] Optional(T) as Try` — the
file's own `ImplicitAs` impls (optional.carbon:110, :117) already use that
bound for the same reason. The polluted fill was reverted (92a6191ee) and
the refill re-dispatched. The single implementation review traced the impl
and did not catch it, so this is recorded as a review miss. LESSON: a
symbolic binding bound by a non-`type` facet has only its declared
interfaces; moving a value of that type requires `Destroy` in the bound.

_Review record:_ one implementation review (R28), APPROVE-WITH-FIXES, all
MINOR: (1) an 82-column comment, fixed in c127784c4; (2) plan §6.A counted
12 source files but 15 were touched — lower/context.h, lower/
function_context.h and lower/file_context.h carry the message-global cache
and the `FunctionInfo` plumbing; (3) plan §2.A.5's "override the poison"
alloca sequence was unimplementable (`SetLocal` CHECKs duplicate inserts,
function_context.h:127-131; `CreateAlloca` needs an insert block for
`CreateLifetimeStart`) — landed as: skip that param in the poison loop,
create the decl block as the entry block, set the insert point, alloca,
then `lower_block`; (4) plan §1.A.3 spelled `FromBreak(b: ())`, landed
`unused b: ()` (in-prelude `UnusedBinding` otherwise; precedent
iterate.carbon:23, :74). Each is a dated "(landed 2026-09-27, EH-A: ...)"
note in the plan.

_SF-9, formerly OPEN — entry moved here verbatim:_ "**SF-9: identity of the existing `Core.Optional` class** (recorded OPEN at the W5-S3a landing per fork/w5-s3/plan.md §0.2's landing obligation, 2026-08-08). Whether the prelude's placeholder `Core.Optional(T)` class is re-platformed onto the generic `choice` machinery (W5-S3 family), kept as an adapter over it, or left as an independent class with a redesigned API (W-058), and how `Core.Result(T, E)` relates. The generic-choice slices S3a-S3c have NO SF-9 dependency; the decision rides the W5-S3p (prelude) AskUserQuestion round, which this entry queues — this split explicitly supersedes the fork/w5-choice/plan.md §5/§7 gate ("SF-9 … must be decided before S3's detailed plan is written"), which now binds W5-S3p only. stdlib/optional_missing_ops.carbon's SKIP stays pinned to the placeholder API until then."
Resolution: D-EH-1 above. stdlib/optional_missing_ops.carbon's SKIP stays
pinned to the placeholder API; the redesign is W-058.

_Docs:_ docs/design/error_handling.md gained two dated amendments (history
unrewritten): the staging table's W5-S3p row records "landed at EH-A" and
D-EH-1, and the `Optional` sketch carries the "signature normative MODULO
`Destroy & OptionalStorage`; body over the placeholder API until W-058"
note. EH-B's amendments (`Cpp.Exception` message clause, selection rule,
release clause, `Carbon::Exception` mapping) are untouched.

_Verification (CONFIRMED before merge, hosted-only per R28):_ gate run
36304152824 green (`prek --all-files` + `bazel test //toolchain/...`);
conformance run 36304154221 (scoreboard 82a382ee1): **106 PASS / 0 FAIL /
28 SKIP over 134** — the plan's tree-relative 105/0/28 over 133 plus the
one program W-077 (#39) added to trunk in between; the four EH-A programs
PASS, zero SKIP flips, exactly as §5.A predicted.
_Hosted verification record:_ the first autoupdate (run 36301020281)
fired R-12 — every full-prelude golden gained two errors because
Optional's `Try` impl moved a `T` payload under a bound without
`Destroy` (fixed: `Destroy & OptionalStorage`, the file's own idiom;
polluted fill reverted). The second (run 36301651448) fired R-3 — a
CHECK failure in `PadToType` while emitting the folded constant
`U.A(())` whose payload element carried the payload-tuple type against
the byte-array region (fixed in lower/constant.cpp: a zero-sized
constant zero-fills the region; the deeper check-side fold residual is
recorded in plan §7 R-3) — and, because file_test isolates crashes and
exits 0, it pushed a PARTIAL fill; the hosted autoupdate step now fails
on any stack dump (trunk 154692b66). The third (run 36303332559) filled
the three lower goldens as predicted (`define i32 @main()` with zero
parameters, `declare i64 @write(i32, ptr, i64)`, the 71-byte message
global, `store { {} } poison` for unit payloads) and moved eight
Optional-using lower goldens by debug-info line numbers only (plan §6
churn addendum). Two runner-exposed defects on one slice, both caught
by the plan's own falsifiers; both are review misses under R28(d).
 (tree-relative, plan §5.A; +1/+1 after the W-077
merge — PR #39 landed on trunk during EH-A — that is 106/0/28 over 134 on
the merged tree); the four new programs PASS and no SKIP flips; hosted
autoupdate to fixpoint with the churn confined to §6.A's two existing
files plus new files — the first fill (run 36301020281) was reverted for
the R-12 event and the refill, in flight at discharge time, is the
fixpoint of record; gate green on it; `runner.py --self-test` clean
(confirmed locally). No new work-item ids allocated — trunk's max id is
W-079 (the W-077 discharge); the three residue items are allocated at the
EH-B discharge. Veto-able.

### W-077: struct patterns in match case position (2026-09-27)

The upstream-missing struct-pattern check layer lands for `match`
arms: `case {.a = 1, .b = n: i32}`, shorthand `{tag: i32}`, field
reorder, subset-with-`_`, nesting, `var`/`ref` fields. SLICE (§1.1):
match-only, gated on FullPatternStack::Kind::MatchCaseArm — two ledger
corrections: the context kind exists (the "not a match-arm slice"
premise was false), and the :138/:143 handler TODOs were unreachable
dead code (the Start TODO aborts first, even for `{}`). WHY THE LANES
SPLIT (§1.4): a subset pattern's own struct type drops fields, so the
let/var conversion path would reject it (StructInitUnexpectedField-
InConversion); the match lane therefore runs a scrutinee-typed
name-keyed field walk mirroring the tuple walk, and the irrefutable
lane keeps its byte-identical TODO, pinned check-side for the first
time (let, var, param, let-in-arm-body) and filed as residue. Break
condition: upstream landing its own struct-pattern layer — the F-002
staging-merge rule applies. USEFULNESS (§1.6): a new Struct key kind
normalized to the SCRUTINEE's field set in canonical order with
Wildcard fills for omitted fields (trailing `_` never enters the key)
restores the W-066 slot-wise machinery's fixed-arity premise, so
{.a=1,_} kills {.a=1,.b=2} and reorder is by value set; all-binding
struct patterns key {Wildcard}, extending the W-078b has_irrefutable_arm
invariant. LANE INTEGRATION (§1.7): zero changes to exhaustiveness or
dead-`default` — struct scrutinees take the open-domain lane, and
struct-of-bools is root-only open exactly like (bool, bool) (pinned).
Diagnostics: MatchCaseStructPatternUnknownField/MissingFields,
StructPatternNameDuplicate/Previous, and StructPatternDiscardWithoutFields
for bare `{_}` (grammar-invalid but parse-accepted; break condition:
upstream legalizing it flips one pin). Zero lower/ changes (struct_access

-   icmp already lower). PLAN REVIEWS: both APPROVE-WITH-AMENDMENTS,
    converging on the pruned-irrefutable-struct fast-path family — the
    choice-payload bind fast path would have CARBON_FATALed on
    `case .Some({x: i32})` and the nested-var lane would have emitted a
    misleading conversion error; both gated pre-implementation. SHARED
    RESIDUE R-2: nested empty-aggregate subpatterns are pruned by both
    passes so their shape checks never run (tuple parity; payload variant
    `case .Some({})`), filed with the residue item. FIRST HOSTED-RUNNER
    VERIFICATION: autoupdate (13 min) matched every hand-traced golden
    prediction; the one runner-exposed defect was `val` being a reserved
    word in the lower golden and conformance program (renamed); gate and
    conformance green at the new floor 102 PASS / 0 / 28 SKIP over 130.
    REVIEW (single implementation review per R29c, after both first
    launches died): APPROVE-WITH-FIXES — one real bug, `MarkPatternUnused`
    lacked a StructPattern case so `case unused {a: i32, _}` emitted a
    false UnusedPatternNoBindings warning (fixed, pinned as
    unused_struct_root); the pin's first spelling carried a dead `default`
    after the irrefutable arm, which the W-078 machinery correctly
    diagnosed — an authoring error caught by the hosted refill, not a
    compiler defect. Review residue recorded with W-079: bind-pass shape
    errors after coverage recording (the W-066 §1.8 carve-out class gains
    struct shapes), names left unbound by a TODO'd subtree add rider
    diagnostics on body use (unpinned in both lanes), no cross-file golden
    exercises a body TuplePattern/StructPattern through import_ref (a miss
    there would CARBON_FATAL loudly), and node_stack.h:227/:337's stale
    "TuplePatterns store an InstBlockId" comments predate this slice.
    Lesson worth a lint: `val` and 60 siblings are CARBON_KEYWORD_TOKENs
    (token_kind.def) — testdata field/binding names must avoid them.

### Runner access revoked: the sparing-verification protocol (2026-09-26)

Owner directive, mid-W-077, verbatim in the parts that govern: "You no
longer have permission to use my computer for this project, but you
must still finish it. You can test your work more sparingly. [...]
Don't like it? Figure out another way. You're no longer squatting in
there." The self-hosted runner IS that computer: every workflow that
compiles or tests fork code (autoupdate, gate, conformance, fast
check) runs on it, and the fast check had been auto-firing on every
C++ push to a `claude/**` branch. Interpretation recorded for review:
routine use is revoked, sparing use for verification is still
permitted, and the work continues. Applied as rulebook R28: the fast
check becomes request-file driven (the one CI change — it REMOVES
load rather than gaming a result, so it is compliance, not the
forbidden kind of CI edit); a workstream reaches the runner only after
both implementation reviews approve, in at most two rounds (one
autoupdate, then gate + conformance together, the gate's file_test
pass doubling as the R26 fixpoint proof); the weekly cycle touches the
runner only if the cut advances. Consequence: fresh-context reviews
with precise golden predictions are now the primary defect detector,
and any runner-exposed surprise is a review miss to record.
Alternatives considered and rejected: building in the session
container (host clang 18 < 19, and an LLVM-from-source bazel build far
exceeds its disk allowance); GitHub-hosted runners for the gate (a
cold Carbon build has no remote cache here and would not fit a hosted
job); hand-written goldens (R16 forbids them — that is the cheating
the owner also forbade). Same day, a usage-limit interruption killed
both W-077 implementation reviews mid-run; they were relaunched with
an explicit efficiency brief.

Same day, superseded: the owner repeated the directive verbatim after
the merge that introduced the request file itself fired one fast check
(the new path filter matched the file's creation; cancelled within a
minute). The "rationed use" reading was too generous. R28 is now
absolute: all four self-hosted workflows are `workflow_dispatch` only,
the agent never dispatches them, and a workstream whose goldens are
unfilled parks as an open PR with the dispatch list stamped in
ORCHESTRATION for the owner. The other way being probed for what the
agent CAN run itself: GitHub-hosted runners (the fork is public, so
standard runners are free under a 6-hour cap) — a timed compile probe
decides whether the fast check, and possibly autoupdate and the gate,
can live there.

Later the same day the owner asked for everything the fork workflows
had put on the machine to be deleted; a one-shot owner-dispatched
cleanup workflow removed the runner-checkout bazel output bases, the
fork disk cache, the libunwind host deps, /tmp scratch, tool caches
and the `_work` checkouts (run 36229750515, success) and is the last
thing this project will ever run there. The replacement is
fork_hosted.yaml on GitHub-hosted ubuntu-22.04 (free for the public
fork, 6-hour cap): it reuses upstream's build-setup action so bazel
reads upstream's public remote cache with matching keys, never
uploads, and offers compile / autoupdate / gate / conformance modes.
Its first compile probe (run 36230850086) took 18 minutes end to
end — 5 of setup, 13 of compile — so the cache reads hit and the
loop's verification survives intact on GitHub's machines; the free
hosted minutes also remove the old reason to ration autoupdate passes.

### W-078b: R8 lift + integer/tuple dead `default` — W-078 closed (2026-09-26)

The W-008 residue R8 conservative gate is lifted: an integer or tuple
`match` without `default` no longer TODO-aborts. Unguarded irrefutable
arms discharge exhaustiveness — the machinery was already landed
(has_irrefutable_arm recording; DiagnoseNonexhaustiveMatch's early
return), only the TODO stood in front — and a match with neither a
`default` nor an irrefutable arm now gets the new Error
MatchNonexhaustiveNoIrrefutableArm ("`match` on {0} has no `default`
arm and no `case` arm that matches every value"): the design's own
nonexhaustive Error example is an integer match
(pattern_matching.md:657-668), and the missing-value-naming kinds
cannot enumerate an integer domain. Enumeration-based exhaustiveness
is recorded design-REJECTED (fully enumerated u8 "Not considered
exhaustive", :596-607; rejected alternative :705) — the in-code
"future work" claim was deleted, not carried. Break condition:
upstream landing enumeration exhaustiveness re-opens only the
diagnostic wording, not the discharge rule. UNGUARDED-ONLY (§1.1):
guarded irrefutable arms never discharge (:620-623), with the
agreement invariant recorded in-code (has_irrefutable_arm ⇔ a
Wildcard-root useful_arms entry on this lane, bind-error carve-out
consistent on both sides). MECHANISM (§1.2): DiagnoseDeadDefault's
entry lane gate deleted — stage 1 (first-covering-arm subsumption)
now serves every lane — while stage 2 stays bool/choice-gated, which
is the structural guarantee that FullCoverage never names an open
domain and the ClassType read stays unreachable for integers.
RUNNER-EXPOSED BOUNDARY, pinned honestly (the W-076 parse-boundary
precedent): a constant-conversion error (`case 5000000000`,
IntTooLargeForType) does NOT set has_error_arm — the flag captures
structural pattern errors (pattern or cond is the error inst) — so
the nonexhaustive error stacks truthfully after it; suppressing would
hide a diagnostic that stays true however the constant is fixed
(fail_error_arm_constant_stacks). CONFORMANCE-EDIT PRECEDENT (§5):
first time a landed program is edited for a new diagnostic —
match_var_ref_binding's two dynamically-dead defaults dropped
(EXPECTs untouched; the arms were design-mandated rejections,
pattern_matching.md:238-246); break condition: upstream downgrading
dead-default severity re-opens the edit, not the program. Loop: both
plan reviews APPROVE-WITH-AMENDMENTS converging on the same top
finding (the error-scrutinee guards rested on a false premise —
error-typed scrutinees abort at MatchCondition, so the guards were
dropped as dead code); both implementation reviews APPROVE (one
comment-only fix); R26 fixpoint at pass 3; gate green; conformance
101/0/28 over 129 — a new floor (+match_irrefutable_no_default).
W-078 is CLOSED (choice half at W-078a, integer half + R8 lift here);
W-008's [R8] residue line rewritten to DISCHARGED.

### W-078a dead `default` arms on choice and bool scrutinees (2026-09-26)

A `default` whose unguarded prior arms already cover the whole closed
value domain (all choice alternatives, or both bool values) now
diagnoses as dead: MatchDefaultNeverMatches at the `default` keyword,
with a PriorArm note at the single covering irrefutable arm or a
FullCoverage note at the scrutinee for union coverage (the new
MatchDefaultNeverMatchesFullCoverage kind, byte-identical text to the
case-arm one — no hoist of a [MatchCase]-tagged note under a default
primary). SEVERITY — Error is the design's own call:
pattern_matching.md:238-246 annotates exactly this shape
"❌ Error: unreachable." (annotation at :243-244); :627-629 mandates
the diagnosis with the :645 Error-annotated example; :814-815 makes
`default` ≡ `case _: auto`, and the landed W-066 rule already errors
on a dead `case _`; warnings are reserved for unused bindings (:360).
Break condition: upstream re-annotating :243-244/:645 or landing this
class as a lint/warning — the fail goldens re-churn, but the §6
default-drops in positive suites stand either way. Wording nuance,
recorded deliberately: the design's annotation says "unreachable",
the diagnostic family says "never matches" — uniformity with the
landed W-066/W-076 family wins. GUARD RULE (§1.2): a guarded
`default`'s own guard is assumed TRUE (:620-623 — the arm under
test's guard is assumed true, context guards assumed false), so full
prior coverage kills even `default if (g)`; prior GUARDED arms never
count toward coverage (unchanged W-066 semantics). MECHANISM (§1.6):
step 3b's covers-all predicate factored into
UnguardedArmsCoverWholeDomain — proven behavior-identical for landed
paths by both implementation reviews — and reused by
DiagnoseDeadDefault at both default handlers (value-keeping
introducer pop); stage 1 scans useful_arms for a Wildcard-root
subsumer (first-covering-arm determinism), stage 2 is union
coverage. The blanket has_error_arm suppression is a recorded
conservative DIVERGENCE from the case-arm rule, with the
deterministic false negative pinned
(fail_error_arm_wildcard_prior_default). Integer/tuple lanes stay
exempt behind R8 (dead_default_exempt IntSide pin); the integer half
lands with-or-after the R8 lift. Loop: both plan reviews
APPROVE-WITH-AMENDMENTS (11 folded), both implementation reviews
APPROVE with zero code fixes (two comment nits); R26 fixpoint at
pass 3 (pass 2 was pure loc-relabel churn in the new fail file);
gate green; conformance unchanged 100/0/28 over 128 with zero
conformance edits.

### W-076 bool scrutinees: the scoreboard's first triple digits (2026-09-26)

`match` on `bool` lands per the design's bool-as-two-alternative-choice
sentence (pattern_matching.md:591): `case true`/`case false` dispatch
through the existing EqWith lane, both-values coverage discharges
exhaustiveness with no `default` (new MatchNonexhaustiveBool names the
missing value or values otherwise), and the W-066 usefulness domain
gained BoolConst keys plus the union rule from day one, exactly as the
ledger demanded. Both plan reviews independently converged on the same
major — the R9 admission widening is positionally global, so bool
constants in choice-payload positions went live and needed pins — and
both implementation reviews approved with zero code fixes. One
runner-exposed fix round, on the shape the plan itself hedged:
`case 1 == 1` does not parse (the case-pattern grammar terminates
before `==`; `case 2 + 3` parses because `+` binds tighter), so the
positive rides the W8a paren-pattern lane as `case (1 == 1)` and the
bare form is pinned as an honest parse boundary. Reconciliation was
airtight: churn confined to the new files plus the three planned
strips, and fail_question.carbon's 44 refilled lines byte-identical
except the single widened R9 message. Verified: R26 fixpoint, gate
green, conformance 100 PASS / 0 fail-class / 28 SKIP over 128 —
the first triple-digit scoreboard (99/127 -> 100/128, match_bool
PASS). Root-only union-rule residue recorded for W-078 and
successors.

### W-066 usefulness diagnostics landed through the full loop (2026-09-26)

The first post-W-008 workstream: `case` patterns that can never match
now diagnose (MatchCaseNeverMatches, Error, per pattern_matching.md's
own "this pattern never matches" annotation), with the covering prior
arm noted — or, for choice-root union coverage, a statement-level
note naming the choice. Two plan reviews independently converged on
the same major before implementation: single-prior slot-wise
subsumption is complete for every slot EXCEPT a choice-scrutinee case
root, whose alternative domain is finite — `.Off`/`.On` priors kill a
later binding-rooted arm by union, which no single prior subsumes.
The folded plan added the step-3b full-coverage rule riding the
landed covered_alternatives semantics (irrefutable payloads only,
guarded arms never count). The reviews also settled canonicalization
from the tree — IntId compares mathematical values, so `case 5` and
`case 2 + 3` share one id and the planned APInt fallback (a
width-mismatch assert hazard) was struck — and recorded the
bind-pass-error carve-out (such arms count as covering, matching
landed has_irrefutable_arm behavior). Both implementation reviews:
APPROVE, zero required fixes; reviewer #1 hand-ran the subsumption
truth table and proved the unconditional exhaustiveness-recording
deviation behavior-invisible. Verified on the runner: autoupdate
filled ONLY the eight new testdata files — the plan's zero
existing-golden-churn claim held empirically — R26 fixpoint at pass
2, gate green, conformance unchanged 99/0/28 over 127. W-078 filed
(default-arm usefulness + the W-008 residue R8 lift, with the
independence record: the choice half is unblocked and separable).

### W8c discharged: W-008 residue is honest, pinned, and filed (2026-09-25)

The disposition slice closes the W-008 round: the combined W4 TODO
string narrowed at FOUR sites (compile-time bindings, form bindings,
binding-free `var`, and the choice-scrutinee expression backstop —
the last found self-contradictory, since `case 5` IS an integer
literal), each re-pinned or newly pinned by hand and reconciled
byte-exact by the runner (regen pass 1 at fixpoint with zero
push-back, run 36149421739). Exactly five combined-string backstops
survive, each re-derived reachable and pinned — including the
plan-§0 "unreachable-by-design" alternative-on-non-choice gate,
which was falsified (parse routes `.Foo` roots type-blind), pinned,
and corrected in the ledger with independent reviewer confirmation.
W-008's ledger notes rewritten to residue form (R4-R10 with live
gate sites, strings, pins); follow-ups filed: W-076 `bool`
scrutinees (OQ-4 mandatory), W-077 struct patterns. Decision-log
records added for the §1.3 all-expression equality call and the §4
R-3 evaluation-order approximation, both with verified break
conditions. Guard-flow comment sweep, line-count-neutral. Review
APPROVE (one minor: completion claimed pre-arbitration — closed by
recording the green run IDs; gate 36149524368, conformance
36149524396 at 99/0/28 over 127 unchanged). The match statement
workstream's implementation slices are done; remaining match work
lives in W-066 (usefulness, now unblocked), W-076, and W-077.

### W8b verified and discharged the same day (2026-09-25)

`var`/`ref` case bindings landed through the full loop: implementer,
two adversarial reviews (one APPROVE-WITH-FIXES, one REWORK on a
genuine blocker — upstream's InitializeExisting dominance CHECK
fatals on the on-demand storage lane), a findings-fold fixer, and
three verification-driven fix rounds. Round 2: cleanup-bearing
guard-failure edges get their own block (the SemIR verifier rejects
destroys inside a BranchIf+Branch terminator sequence; arm scopes
own cleanups for the first time). Round 3, the structural one:
case-arm guards are now checked AFTER the bind pass, inline in the
arm's body block — the guard's captured-region checking predated the
bind fill, and WrapperBinding's use-before-fill category assumption
(upstream expr_info.cpp:80-90, their own TODO) miscompiled ref-backed
bindings in guards (comparison built without a load; lowering fed a
pointer to icmp). Value bindings had worked in guards only by
categorical accident; the reorder makes both principled. Guarded
defaults keep the region lane (no bindings, no hazard). Round 4: the
fail_question.carbon pin caught the `?`-in-case-guard ban silently
lifting (its enforcement WAS the region-depth test); the ban is
re-established explicitly on the guard-checking window — widening `?`
into case guards is an SF-9 surface decision, kept symmetric with
default guards. Delta re-review of rounds 2-4 + golden fill:
APPROVE, no defects; the guard reordering also resolved the W8a
formatter artifact ('match.<unexpected BranchWithArg>' labels).
Verification: R26 fixpoint with every hand pin byte-exact
(patterns/unused.carbon Warns included), untouched non-guard goldens
byte-identical, per-arm alloca/no-alias lower pins inspected, gate
36145509684 green, conformance 99/0/28 over 127
(match_var_ref_binding PASS). Floor 98/126 -> 99/127.

### W8a verified and discharged on the runner's return (2026-09-25)

The runner came back (~29 days offline; disk freed 36GB -> 126GB), the
08-24 weekly merge landed to trunk (F-002 merge d34ed63, gate
36116293634 green 46/46), and W8a verification ran end to end. The
first full-runner autoupdate of the W8a testdata crashed the SemIR
formatter (FATAL sem_ir/expr_info.cpp:280) on tuple_pattern.carbon's
expr_element_conversion subfile: tuple element expressions closed
their regions through EndExprRegionForPattern with no category
conversion, so an initializing element such as `2 + 3` made the
splice_block itself an initializing expression, which
FindStorageArgForInitializer rejects. Root fix (fix round 3,
7c0e638): value-convert initializing results inside
EndExprRegionForPattern while the region is open — the same invariant
FinishCasePattern and MatchCaseGuard already maintain — with the F5
post-splice conversion kept as defense-in-depth. Autoupdate then
filled the four W8a golden files and reconciled ONE hand-pinned fail
file: fail_choice_alternative_pattern.carbon's
fail_nested_designator_subpattern gained a second min_prelude-only
diagnostic (Core.EqWith CoreNameNotFound) because F2 semantics still
key the discriminant compare for arms with errored payloads —
adjudicated CORRECT (primary designator error leads; full-prelude
no-cascade pin unchanged), not a wrong pin. R26 fixpoint: pass 2
pushed nothing; every let/var/param/thunk golden byte-identical,
proving the shared-region change a no-op outside match. R-2 lower pin
inspected: the payload load for `case .Ok(42)` sits in a block
dominated by the discriminant compare, phi false on the not-taken
edge — no hoisted poison load. Gate 36135807130 green; conformance
98 PASS / 0 fail-class / 28 SKIP over 126 (match_tuple_case_diff +
match_payload_literal PASS; floor 96/124 -> 98/126). Ledger: W-008
notes refreshed (stale pin filename, dead :364 reference, arity
diagnostic recorded); W-066 blocked_by discharged per plan §3.4.
Noted for W8b/W8c: lower merge-block namer emits the label
"match.<unexpected BranchWithArg>" (label-only polish), the
choice-payload bind-pass coverage nuance, and the R8 conservative
gate.

### Weekly upstream merge 2026-10-05: cut HOLDS a seventh week; a dry-run merge conflicts in 99 files (2026-10-05)

Hosted-only check (R28). Measured upstream trunk d31a8b67d
(2026-10-03, "Update tree-sitter grammar (#7885)"): 181 commits since the
631f8fb cut (2026-08-20; 137 last week), 1530 upstream files touched, 189
of them also modified by the fork since the cut (157 last week). New this
week: a dry-run `git merge --no-commit` of upstream trunk into trunk
0187198fa in a throwaway worktree, aborted after counting — 99 conflicted
files: 30 sources/docs (check/call.cpp, convert.cpp, core_identifier.def,
cpp/export.cpp, cpp/import.cpp/.h, cpp/thunk.cpp/.h, custom_witness.cpp,
eval.cpp/.h, function.cpp/.h, generic.cpp, handle_class.cpp,
handle_function.cpp, handle_pattern_list.cpp, member_access.cpp,
lower/function_context.cpp, lower/type.cpp, sem_ir/expr_info.cpp,
sem_ir/function.h, sem_ir/generic.cpp, sem_ir/stringify.cpp,
docs/design/lexical_conventions/words.md, and the five editor-syntax
files that carry the fork's `union`/`overload` keywords) plus 69 goldens
(which a hosted autoupdate would refill, but only after the sources
merge). The A/B probes were not re-run this week (the session was out of
usage credits from 09-28 until this check fired; the mirror workflow was
not dispatched to save credits for the in-flight slices) — the 09-28
reading stands: the tip was still a regression against the floor. The cut
holds a seventh week; the deferred set is 181 commits. Recommendation
unchanged and firmer: an "upstream advance" workstream with its own plan
and two reviews, scheduled after OV-2 and SL-1 land (both in flight on
their branches), since every week adds conflicts to the same check-core
files those slices touch. No staging branch was pushed; the dry-run
worktree was removed.

### Weekly upstream merge 2026-09-28: cut HOLDS a sixth week; tip half-healed with a new crash signature (2026-09-28)

First weekly check run entirely under R28 (no runner): the nightly is
mirrored by the GitHub-hosted `Fork: mirror upstream nightly toolchain`
workflow (release arbiter-v0.0.0-0.nightly.2026.09.28, upstream 1579d4e)
and the A/B probes run in the sandbox against that tarball. Measured
upstream trunk: 137 commits since the 631f8fb cut (2026-08-20); 1435
upstream files touched, 157 of them also modified by the fork since the
cut — including the check core the last four slices landed on
(class.cpp, custom_witness.cpp/.h, convert.cpp, eval.cpp/.h, eval_inst.cpp,
pattern_match.cpp, pattern.cpp, handle_function.cpp, handle_class.cpp,
import_ref.cpp, member_access.cpp, scope_stack.*, node_stack.h, type.cpp,
cpp/import.cpp, cpp/export.cpp/.h, cpp/generate_ast.cpp,
cpp/impl_lookup.cpp, cpp/overload_resolution.cpp, cpp/call.cpp,
cpp/constant.cpp) and docs/design/{README,classes,pattern_matching}.md.
Empirical A/B: generics/templates_value_param.carbon compiles, links and
runs clean (prints 9 10 20, exit 0 — unchanged); generics/
templates_type_param.carbon still CRASHES, with a NEW signature — `CHECK
failure at toolchain/lower/function_context.cpp:198: const_id.is_concrete():
Missing value: inst… {kind: StructLiteral, …, type: type(symbolic_constant…)}`
(a symbolic struct literal reaches lowering without a concrete value; the
09-21 signature was an unhandled SpliceInst category at lower/handle.cpp:294).
Half-healed is still a regression against the fork floor (both probes PASS
at the cut, which now stands at 114/0/25 over 139), so the cut holds a
sixth week; the deferred set is 137 commits. Conflict surface has grown
from one fork-modified file to the twenty-odd above: advancing the cut is
no longer a weekly fold but a workstream of its own (recommendation:
schedule an "upstream advance" slice once the OV/UN-2 slices land, with
its own plan and two reviews, rather than folding it into a cron run).
The staging branch was not created (no merge was attempted).

### Weekly upstream merge 2026-09-21: cut HOLDS a fifth week; tip still half-healed (2026-09-21)

Fold-in to the still-unlanded 08-24 staging merge (runner jeromehome
offline since 08-27 ~02:20Z — 25 days; the landing loop keeps a gate
run queued and re-bumps past GitHub's 24h queue expiry, now at
attempt 48). Measured upstream trunk 76e7fc5 (28 commits since
4081848). Template-adjacent work continued (#7769 removes
`refine_inst_action` and its splices, #7768/#7804 type-sugar
preservation in diagnostics, #7737 non-canonical default values).
Empirical A/B against the freshly mirrored 2026.09.21 nightly
(version 76e7fc5): generics/templates_value_param.carbon COMPILES
CLEAN (object emitted, exit 0) — unchanged from last week — but
generics/templates_type_param.carbon still CRASHES, now with a
sharper signature: FATAL at toolchain/lower/handle.cpp:294
"Unexpected category 9 for `return` expression {kind: SpliceInst,
...}" (the SpliceInst reaches lowering with an unhandled expression
category). Half-healed is still a regression vs the fork floor (both
probes PASS at the 631f8fb cut), so the cut stands a fifth week; the
deferred set grows to 119 commits (7+12+28+44+28). One deferred
commit now touches a fork-modified file (toolchain/check/
pattern_match.cpp), raising future-merge conflict surface for the
W-008 family — noted for the eventual advance past the cut. The
clang-21 note from 09-14 stands.

### Weekly upstream merge 2026-09-14: cut HOLDS a fourth week; tip half-healed (2026-09-14)

Fold-in to the still-unlanded 08-24 staging merge (runner jeromehome
offline since 08-27 ~02:20Z — 18 days; the landing loop keeps a gate
run queued and re-bumps past GitHub's 24h queue expiry). Measured
upstream trunk 4081848 (44 commits since 386327e). Real template
progress landed: #7726 SpecificInst, #7727 template LOWERING support,

## 7741 template-dependent assignment, #7735/#7736 template-argument

tests, #7772 out-of-line template decl fix. Empirical A/B against the
freshly mirrored 2026.09.14 nightly (version 4081848):
generics/templates_value_param.carbon now COMPILES CLEAN (was
crashing) — but generics/templates_type_param.carbon still CRASHES
(stack dump, exit 141). Half-healed is still a regression vs the
fork floor (both probes PASS at the 631f8fb cut), so the cut stands a
fourth week; the deferred set grows to 91 commits (7+12+28+44).
Operational note for the runner's return: #7779 raises upstream's
minimum toolchain to clang 21 and CI now uses it — jeromehome carried
clang >= 19; when a post-#7779 merge is eventually attempted, the
host may need a clang upgrade (user-visible ask at that point, not
now; the staged 631f8fb cut predates the requirement and is
unaffected).

### Weekly upstream merge 2026-09-07: cut HOLDS a third week; tip now crashes BOTH probes (2026-09-07)

Fold-in to the still-unlanded 08-24 staging merge (runner jeromehome
offline since 08-27 ~02:20Z — 11 days; the landing loop keeps a gate
run queued). Measured upstream trunk 386327e (28 commits since
f519ccc). The template-action series continued (#7689 TemplateInst,

### 7700 splice-stepping for bound methods, #7710 call-action operand

refinement — the last two aimed at exactly the `<bound method>`
failure class measured last week). Empirical A/B against the freshly
mirrored 2026.09.07 nightly (version 386327e; mirror is
GitHub-hosted, unaffected by the runner outage): BOTH
generics/templates_{type,value}_param.carbon now CRASH the compiler
(stack dump, "Pending diagnostics:", exit 141) — last week only
value_param crashed and type_param diagnosed. Facet-constrained
`template T` bindings remain broken at tip, trending worse. Verdict:
the 631f8fb cut stands a third week; the deferred set grows to 47
commits (7 + 12 + 28), all descendants of the in-flight series. The
09-06/09-07 upstream `match_first` and named-constraint work
(#7713/#7714) is inside the deferred span and returns whenever the
series stabilizes. Digest note (user's call, unchanged): the
tip crashes are reportable upstream bugs; filing is an outward-facing
action left to the user.

#### Weekly upstream merge 2026-08-31: cut HOLDS; tip now crashes the probe (2026-08-31)

Fold-in to the still-unlanded 2026-08-24 staging merge (runner offline
since 08-27 ~02:20Z; gate never ran). Measured upstream trunk f519ccc
(12 commits since 2b9fdd6). The template-action series continued
(#7671 constant InstActions, #7682 CallAction deferred calls) and the
`CallToNonCallable` fail_todo pins in
generic/template/unimplemented.carbon dropped 5 -> 0 at tip — but the
EMPIRICAL A/B against the freshly mirrored 2026.08.31 nightly
(version f519ccc; the mirror workflow runs GitHub-hosted, so it was
available despite the runner outage) shows the facet-constrained
template shape is still broken and now WORSE:
generics/templates_type_param.carbon fails with "unable to
monomorphize specific `Identity(i32 as Core.Copy & Core.Destroy)`"
plus "value of type `<bound method>` is not callable", and
generics/templates_value_param.carbon CRASHES the compiler (stack
dump, exit 141). Verdict: the 631f8fb cut stands for another week;
the deferred set grows to 19 commits (last week's 7 + this week's
12 — all descendants of the in-flight series). Candidate user ask
(digest, non-blocking): the value_param crash on pure upstream tip is
a reportable upstream bug; filing an upstream issue is an
outward-facing action left to the user's call. Staging branch
otherwise unchanged; the 08-24 record's landing plan still applies
the moment the runner returns.

##### Weekly upstream merge 2026-08-24: cut before the template-action series; runner disk blocker (2026-08-24)

The scheduled weekly merge (standing rule 5) measured upstream trunk
2b9fdd6 (24 commits since the 2026-08-17 sync point 864845c), built the
FULL tip merge on staging first, and caught a conformance regression:
96/0 -> 94/2 over 124, both `generics/templates_{type,value}_param`
newly COMPILE-FAIL with `value of type <dependent type> is not
callable` at `return x;` under `[template T: <facet>]`. Root cause
verified FORK-INDEPENDENT by an A/B on pure upstream nightlies (the
mirrored arbiter tarballs): 2026.08.17 compiles both programs;
2026.08.24 fails them with identical diagnostics. Upstream's in-flight
template-action series (#7657 6eb900d, #7662 186a756, #7663 c41033c)
reroutes dependent conversions through template actions with
INITIALIZING conversions explicitly left as future work (#7662's own
message); upstream pins the class as fail_todo_ in
generic/template/unimplemented.carbon — acknowledged gap, V-3a. Per the
weekly-merge non-regression rule the landed merge CUTS at 631f8fb
(#7658), taking 17 of 24 commits and deferring seven (the three
template commits + c588ead, 4172f4d, 40aa441, 2b9fdd6) to next week's
merge, by which point the promised initializing-conversion follow-up
should exist. Conflict resolutions on the cut (identical spelling to
the measured tip merge): 14 goldens fork-side CHECK-renumbering only,
taken upstream for runner regen; node_kind.def match family follows
upstream's new `_STATEMENT` extraction-sharding classification with the
three fork-only kinds alongside their siblings; clang_decl.h takes
upstream #7642's defaulted `operator==` (member-wise covers F8d's
`constant_function_args`). R26 fixpoint at regen pass 2 (pass pushed
nothing); conformance at fixpoint EXACTLY 96/0/28 over 124 —
non-regressing.

**Runner disk blocker (OPEN at recording):** the F-002 gate could not
run — the build workflow's Preflight guard trips at 37GB free vs the
40GB cold-build threshold ($HOME 94% full on jeromehome). Two
misleading "gate failures" first appeared as golden mismatches: with
Preflight failed and every build/test step SKIPPED, the diagnostic
"Print failing test logs" step dumps the PREVIOUS run's bazel-testlogs
— content provably absent from the tested SHA. Remediation attempted
within charter: `user.bazelrc` (upstream's own documented override
point, force-added past the gitignore) capping the bazel disk cache GC
at 80G, plus a bazel cycle — freed nothing (cache evidently under
cap). Three gate attempts, then stop-per-checkpoint-rule. USER ACTION
ASKED (push notification sent): free ~5GB on jeromehome, or bless
lowering MIN_FREE_GB 40->30 (a CI change, so it needs the user's
explicit blessing; 37GB demonstrably suffices for warm-cache builds —
conformance builds the full toolchain in it). The staged merge lands
(F-002 into trunk) as soon as one gate run is green. Veto-able:
the cut-not-tip call, the user.bazelrc cap, and the deferred-commit
list.

##### F-005: Own-toolchain build environment — **Self-hosted runner** (2026-07-19)

The user registered a self-hosted GitHub Actions runner ("jeromehome",
self-hosted/Linux/X64) on the fork. `.github/workflows/fork_build_toolchain.yaml`
builds `//toolchain/install:carbon_toolchain_tar_gz` from the pushed
branch, runs `bazel test //toolchain/...` as the F-002 merge gate, and
publishes the tarball as a fork release (by way of a hosted publish job). The
sandbox then downloads that release the same way it downloads the mirrored
nightly. First cold build compiles LLVM (hours); the runner's bazel disk
cache makes subsequent fork builds incremental. Security note: on a public
repository, keep the default "require approval for outside collaborators'
workflow runs" protection enabled so third-party PRs can't run code on the
runner host.

##### F-001: What "0.1" means for this fork — **Staged official 0.1** (2026-07-19)

Chase the full official checklist from `docs/project/milestones.md`, in
dependency order, tagging intermediate fork milestones (`fork-0.1-alpha`,
`fork-0.1-beta`, …) as scoreboard tiers go green. Design authorship for
the undesigned bullets is in scope. Alternatives rejected: pragmatic
subset-0.1 (diverges from the official definition), upstream-lockstep
(too slow, not autonomous).

##### F-002: Upstream relationship — **Bun-style merge gating** (2026-07-19)

User's words: "Follow the same approach used by the Bun zig->rust rewrite
for merging into my fork branch." Interpretation (recorded for review):
in the Bun rewrite, work happened in isolated worktrees/branches and
merged only after **100% of the pre-existing test suite passed in CI**.
Applied here:

-   Feature work happens in child branches/worktrees, never directly on
    `claude/carbon-fork-0-1-7mwfb7`.
-   A merge into the fork branch requires the full pre-existing toolchain
    test suite plus the conformance scoreboard to be green (no skipped or
    deleted tests to force a pass).
-   Upstream trunk merges are treated the same way: merge upstream into a
    staging branch, re-run the suite, land only when green.

##### F-003: First scaled track — **Design sprint + match chain in parallel** (2026-07-19)

After the conformance-harness trial (W1): agent fleets draft the missing
designs (error handling, unions, if-let/let-else, function overloading,
threading/atomics interop; then safe Carbon) with the user reviewing at
each design fork, while the implementation loop grinds
match semantics → choice payloads → std::variant/optional interop against
the harness.

##### F-004: Arbiter toolchain source — **Upstream nightly prebuilt** (2026-07-19)

User approved adding `carbon-language/carbon-lang` to the session to
download the nightly prebuilt toolchain tarball (Linux x86_64). This
arbitrates _language behavior_ while our fork's tree equals upstream
trunk; it cannot execute fork-local compiler changes — see OPEN F-005.
