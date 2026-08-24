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

-   **SF-9: identity of the existing `Core.Optional` class** (recorded OPEN at
    the W5-S3a landing per fork/w5-s3/plan.md §0.2's landing obligation,
    2026-08-08). Whether the prelude's placeholder `Core.Optional(T)` class is
    re-platformed onto the generic `choice` machinery (W5-S3 family), kept as
    an adapter over it, or left as an independent class with a redesigned API
    (W-058), and how `Core.Result(T, E)` relates. The generic-choice slices
    S3a-S3c have NO SF-9 dependency; the decision rides the W5-S3p (prelude)
    AskUserQuestion round, which this entry queues — this split explicitly
    supersedes the fork/w5-choice/plan.md §5/§7 gate ("SF-9 … must be decided
    before S3's detailed plan is written"), which now binds W5-S3p only.
    stdlib/optional_missing_ops.carbon's SKIP stays pinned to the placeholder
    API until then.

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

### Weekly upstream merge 2026-08-24: cut before the template-action series; runner disk blocker (2026-08-24)

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

### F-005: Own-toolchain build environment — **Self-hosted runner** (2026-07-19)

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

### F-001: What "0.1" means for this fork — **Staged official 0.1** (2026-07-19)

Chase the full official checklist from `docs/project/milestones.md`, in
dependency order, tagging intermediate fork milestones (`fork-0.1-alpha`,
`fork-0.1-beta`, …) as scoreboard tiers go green. Design authorship for
the undesigned bullets is in scope. Alternatives rejected: pragmatic
subset-0.1 (diverges from the official definition), upstream-lockstep
(too slow, not autonomous).

### F-002: Upstream relationship — **Bun-style merge gating** (2026-07-19)

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

### F-003: First scaled track — **Design sprint + match chain in parallel** (2026-07-19)

After the conformance-harness trial (W1): agent fleets draft the missing
designs (error handling, unions, if-let/let-else, function overloading,
threading/atomics interop; then safe Carbon) with the user reviewing at
each design fork, while the implementation loop grinds
match semantics → choice payloads → std::variant/optional interop against
the harness.

### F-004: Arbiter toolchain source — **Upstream nightly prebuilt** (2026-07-19)

User approved adding `carbon-language/carbon-lang` to the session to
download the nightly prebuilt toolchain tarball (Linux x86_64). This
arbitrates _language behavior_ while our fork's tree equals upstream
trunk; it cannot execute fork-local compiler changes — see OPEN F-005.
