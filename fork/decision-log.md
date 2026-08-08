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
