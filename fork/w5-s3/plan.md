<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W5-S3 plan: generic `choice` types — payload synthesis, specifics as scrutinees, exhaustiveness through specifics

Status: PLAN (process step 6, scaled loop). Baseline: trunk 435ce66 (post-match-re-platform
integrated line). Design authority: docs/design/sum_types.md (esp. :60-89, the
`Optional(T: type)` example), the normative F-007k storage contract (docs/design/unions.md,
"Relationship to choice types"), and the ratified decisions in fork/decision-log.md (W5 SF-1..8,
W5-S1 scope trades, S2a-S2e landing notes). Precedent format: fork/w5-choice/plan.md +
fork/match-replatform/plan.md. This document supersedes fork/w5-choice/plan.md §4's S3 outline.
NO implementation in this document — planning only.

---

## 0. Scope and non-goals

### 0.1 In scope

Three recorded W5-S1 gates lift, in dependency order:

-   **(a) Payload synthesis in generic choices** — lifts the decision-log W5-S1 gate
    "Alternatives with parameter lists in generic choices are gated to the generic/
    Self-dependent TODO string … generic synthesis is S3's re-plan". The code gate, the
    `is_generic_choice` branch at toolchain/check/handle_choice.cpp:628-631, rejects EVERY
    parameterized alternative — even concrete-typed `Concrete(b: i32)` (pinned by
    choice/fail_todo_generic_payload.carbon) and zero-payload `Alt()`.
-   **(b) Specifics of generic choices as `match` scrutinees** — lifts "Specifics of generic
    choices are not matchable in S1 (`choice P(T: type) { A, B }` matched as a `P(i32)` value)
    … S3's generic re-plan owns it". The code gate is the `class_type->specific_id.has_value()`
    clause in `GetChoiceDiscriminantType` (toolchain/check/pattern_match.cpp:366), routing such
    scrutinees to the `match on unsupported scrutinee type` TODO (handle_match.cpp:140) and
    alternative patterns to the combined W4 string (handle_match.cpp:246-248).
-   **(c) Exhaustiveness for generic-choice specifics** — should fall out of (b) + S2e's
    `MatchStatementContext` analysis; §2.5 verifies rather than assumes it. Discharges S2e
    recorded deviation (2) — after S3 the doc's `Optional(i32)` match compiles without `default`.

### 0.2 Out of scope (with rationale)

-   **W-068: choices with fewer than two alternatives.** Their discriminant is `()`, not an
    integer; `GetChoiceDiscriminantType` rejects them at :387 independently of `specific_id`, so
    the gates compose — `Always(i32)` for `choice Always(T: type) { Sunny }` stays behind the
    scrutinee TODO, still pinned by match/fail_todo_single_alternative_choice.carbon. Admitting
    them is dispatch-shape work (no-test arms), orthogonal to genericity; since the :366
    deletion makes the composition reachable, S3a adds a fail subfile pinning `Always(i32)` and
    a zero-alternative specific on the post-deletion path (§3).
-   **User-defined `Match` interface / Continuation machinery** (sum_types.md:124-246) —
    the whole-workstream W5 §0.3 exclusion, unchanged.
-   **Template-dependent scrutinees.** A template-phase symbolic scrutinee (`template T:! type`
    member shapes) never resolves to a concrete `ClassType` at check time; it keeps the
    scrutinee TODO. Template monomorphization lowering is itself CARBON_FATAL upstream
    (conformance SKIP generics/templates_dependent_member.carbon).
-   **Prelude `Core.Result(T, E)` / `Core.Optional(T)` and SF-9.** The original S3 sketch
    bundled them; this re-plan splits them out. SF-9 (identity of the existing `Core.Optional`
    class) is an undecided user fork; the generic-choice machinery here has no SF-9 dependency,
    and stdlib/optional_missing_ops.carbon's SKIP is pinned to the placeholder API, not to this
    slice. A follow-on W5-S3p (prelude) plan rides the SF-9 AskUserQuestion round and unblocks
    F-006 B1; sequencing it after S3c lands the prelude types on proven machinery. This split
    EXPLICITLY SUPERSEDES the fork/w5-choice/plan.md §5/§7 gate ("SF-9 … must be decided before
    S3's detailed plan is written"): it now binds W5-S3p only. Landing obligation: S3a's
    landing records SF-9 as OPEN in the decision-log.
-   **SF-6 relaxation** (non-trivially-copyable/destructible payloads) and **SF-4 qualified
    patterns** (`Optional(i32).Some(v)` in case position) — recorded post-0.1/work-item status
    unchanged; §2.3 covers how SF-6's gate MOVES for generic choices without widening.

---

## 1. Current state (claims re-derived from the tree at 435ce66)

-   **The alternative metadata is already specific-independent.** `SemIR::ChoiceAlternative`
    (sem_ir/class.h:35-55) stores `{name_id, index, payload_field_index, has_parameters}` —
    no TypeIds. Its import copies indices verbatim ("plain integers … carry over unchanged",
    import_ref.cpp:2077-2088). All type information flows from the object repr at use time.
-   **The use sites already thread `specific_id`.** `GetChoiceDiscriminantType` and
    `GetChoicePayloadInfo` call `class_info.GetObjectRepr(sem_ir, class_type->specific_id)`
    (pattern_match.cpp:374, :425) — dead generality today, guarded by the :366 rejection.
    Upstream's `Class::GetObjectRepr` resolves the witness per-specific through
    `GetConstantValueInSpecific` (sem_ir/class.cpp:39-53), the `GetAdaptedType` idiom.
-   **The layout numbers are the real problem.** `CustomLayoutType` bakes concrete
    `[size, align, offsets…]` into a `CustomLayoutId` block (typed_insts.h:617-627,
    handle_choice.cpp:694-718). Generic eval substitutes `StructTypeFieldsId` field types
    (eval.cpp:652-680) but `CustomLayoutId` has no `GetConstantValue` overload — a substituted
    `CustomLayoutType` would carry STALE definition-time numbers, and BOTH consumers read them
    blind: `TypeCompleter::BuildInfoForInst` (type_completion.cpp:786-795) and lowering's
    `[N x i8]` (lower/type.cpp:633-640). Without per-specific recomputation this silently
    miscompiles — W5 plan R-9's prophecy, now located precisely. Also: `CustomLayoutType` is
    `WheneverPossible` (typed_insts.h:621) — `TryEvalTypedInst` calls `MakeConstantResult`
    directly (eval.cpp:2920-2922) and eval_inst.h:103-121 statically deletes `EvalConstantInst`
    overloads for the kind, so an eval hook is unreachable without §2.2's constant-kind change.
-   **Eval-time completion is an established idiom.** `EvalConstantInst` for
    `RequireCompleteType` calls `TryToCompleteType` during monomorphization and diagnoses
    `IncompleteTypeInMonomorphization` (eval_inst.cpp:603-639); eval also owns the "unable to
    monomorphize specific {0}" context (eval.cpp:3290) — per-specific semantic work inside
    eval, with diagnostics, is precedented.
-   **Payload-free generic choices already complete concretely.** choice/generic.carbon's
    golden shows `complete_type_witness %struct_type.discriminant [concrete]` inside the
    generic — no symbolic content in the repr, so the payload-free shape needs no layout work.
-   **Plan finding — the specifics scrutinee gate is UNPINNED.** Only three goldens pin
    `match on unsupported scrutinee type` (fail_todo_non_int_scrutinee,
    fail_todo_adapter_scrutinee, fail_todo_single_alternative_choice); none matches a specific
    of a generic choice, and choice/generic.carbon never constructs or matches one — the W5-S1
    gate exists in prose only. S3a adds the positive pins directly (R10 hygiene).

---

## 2. Design

### 2.1 Metadata resolution through a specific — two options, one recommendation

-   **Option A — extend the table.** Grow `ChoiceAlternative` with payload/param TypeInstIds
    and substitute them at lookup (or materialize a per-specific table copy). Rejected: upstream
    keeps NO per-specific entity tables anywhere — specifics resolve member values on demand
    through `GetConstantValueInSpecific` (see `GetObjectRepr` et al., and pattern_match.cpp's
    own `WrapInstForSpecific`/`specific_id_stack_` machinery at :68-73, :1095-1107); the
    table's import contract ("plain integers") would break; and a second source of payload-type
    truth can drift from the repr the bind pass indexes into.
-   **Option B — resolve through the specific at use (RECOMMENDED, adopted).** Keep the table
    type-free. NOT a one-clause lift — two coordinated changes: (1) delete the
    `specific_id.has_value()` clause at pattern_match.cpp:366 (every downstream consumer already
    passes `class_type->specific_id` into `GetObjectRepr`, so discriminant, payload region, and
    payload tuple types arrive substituted once the witness is resolved); and (2) make the
    scrutinee gate FORCE that resolution: the `MatchCondition` handler (handle_match.cpp:123-141,
    the entry to `MatchStatementStart`'s region) calls `RequireCompleteType` on the scrutinee
    type BEFORE `GetChoiceDiscriminantType` reads the repr — for a `has_value` specific the
    completer's `ClassType` case runs `ResolveSpecificDefinition` (type_completion.cpp:481-483);
    symbolic types defer to monomorphization as usual. Without (2) the lift is unsound — nothing
    guarantees the path that produced a scrutinee value completed its type (§2.6, R-2); with (2)
    the match itself is a forcing use and the ordering argument holds by construction.

### 2.2 Per-specific payload layout (the S3b core)

**Definition side.** With symbolic payloads, `GetCompleteTypeInfo` cannot supply sizes at
definition: the size/align max-fold (handle_choice.cpp:679-683) is skipped and the
`CustomLayoutType` is emitted with RAW ZERO size and alignment words, pushed directly — the
`AlignedTo` fold CARBON_CHECKs power-of-2 alignment (type_info.h:99-103) and must be bypassed.
The zero is not ad-hoc: alignment == 0 is the toolchain's dependent-layout encoding
(`ObjectLayout::has_value()` is `alignment != 0`, type_info.h:211-213; invalid layout =
"dependent on a generic parameter", :195-200). A symbolic completion inside the generic body
reads the zeros through `TypeCompleter::BuildInfoForInst(CustomLayoutType)`
(type_completion.cpp:786-795) into a no-value `object_layout` and degrades to the
dependent-layout path by the SAME rule as a generic class's dependent fields — the sentinel is
the mechanism, not an accident.

**Eval side.** An `EvalConstantInst(CustomLayoutType)` overload is unreachable today (§1).
CHOSEN MECHANISM: change `CustomLayoutType`'s `constant_kind` to `InstConstantKind::Conditional`
with `constant_needs_inst_id = DuringEvaluation` — the `RequireCompleteType` shape
(typed_insts.h:1616-1623) — and add the now-reachable
`EvalConstantInst(Context&, InstId, SemIR::CustomLayoutType)` overload (NOT a `TryEvalTypedInst`
specialization). RECOMPUTE PREDICATE: the sentinel (alignment word == 0), NOT "all fields
concrete" — a fields-concrete trigger would rebuild (i) concrete choices' layouts at birth,
breaking §4's byte-equivalence, and (ii) C++-imported class layouts, whose blocks are
Clang-computed offsets (check/cpp/import.cpp:855-868) that the max-of-fields rule would
silently corrupt. So: alignment != 0 blocks pass through unchanged; sentinel blocks with a
symbolic field return `NewSamePhase`; sentinel blocks with all-concrete substituted fields
complete each field type (the `RequireCompleteType` case's `TryToCompleteType` discipline,
diagnostic-context scope included, eval_inst.cpp:603-639), run §2.3's SF-6 check, and rebuild
the layout block with real max-of-fields numbers as a fresh concrete constant. A `var` of type
`P(i32)` — and, after §2.1(2), the scrutinee gate itself — forces `require_complete`
evaluation, so completion and lowering's `[N x i8]` (lower/type.cpp:633-640) read recomputed
numbers with zero consumer changes.

### 2.3 SF-6 enforcement moves to monomorphization for symbolic payloads

`IsInSlicePayloadType(T)` is unanswerable at definition time for symbolic `T`. The
definition-time loop (handle_choice.cpp:633-665) keeps: the Self-dependence rejection
(`TypeContainsChoice`) and the SF-6 check for CONCRETE payload types (now also inside generic
choices — `Concrete(b: i32)` validates at definition). Symbolic payload types defer to the §2.2
eval recompute, which runs the same `IsInSlicePayloadType` on the substituted type and
diagnoses with a new real diagnostic, authored HERE and final (R10 governs SKIP evidence, not
diagnostic authoring; house precedent is plan-reviewed text): enum name
`ChoicePayloadNotTrivialInSpecific`, severity `Error`, message
`` choice alternative payload type {0} is not trivially copyable and destructible in this specific ``
({0} = `InstIdAsType`, the substituted payload type). So `P(String)` errors at the use that
forces the specific, with eval's "unable to monomorphize specific {0}" context note
(eval.cpp:3290). Recorded trade: the diagnostic lands at the use site, not the declaration —
`IncompleteTypeInMonomorphization` placement, upstream's own precedent. The W5-S1 admitted
exception (no destroy-witness query) carries over unchanged and un-widened.

### 2.4 Constructor synthesis under genericity

`BuildAlternativeConstructor` runs inside `StartGenericDefinition`/`FinishGenericDefinition`
already, but `MakeGeneratedFunctionDecl` hard-codes `build_generic=false` / `generic_id = None`
(function.cpp:164-201). The no-wiring hypothesis is REFUTED, and the refutation recorded:
constructors must resolve, check, and LOWER per specific (`P(i32).Ok(42)` vs `P(f64).Ok(1.5)`),
and a `generic_id = None` member function of a generic scope has no upstream precedent.
Pre-committed nested-region shape: `MakeGeneratedFunctionDecl` gains a `build_generic` mode
bracketing `MakeFunctionSignature` with `StartGenericDecl` then `BuildGenericDecl` — the
member-function precedent, opened at the introducer (handle_function.cpp:41) and closed over
the finished decl (:583); the body side needs no new wiring, since `StartFunctionDefinition`
already runs `StartGenericDefinition` (function.cpp:463-464). Second-deepest unknown after
§2.2 — R-3's plan-revision trigger stands if the bracketing needs more than this.

### 2.5 Exhaustiveness through specifics — verification of "falls out"

`DiagnoseNonexhaustiveMatch` (handle_match.cpp:717-769) reads `class_info.choice_alternatives`
by way of `class_type.class_id`; specifics of one generic share the `class_id`, so coverage
identity is shared by construction, and per-arm coverage records the table's `index`
(handle_match.cpp:560-572), also specific-independent. Two provisos: (i) the table needs NO S3a
work — the constant-alternative push is UNCONDITIONAL today (handle_choice.cpp:756-770 pushes
every parameterless alternative, generic or not); parameterized rows appear wholly in S3b, when
the :628-631 reject stops setting the error flag that skips the push at :775-783. Until then a
MIXED generic choice matched through a specific sees a partial table — the parameterized
alternative carries the definition TODO while a match covering only the constant alternatives
is judged exhaustive IN SILENCE; S3a pins this window with a fail golden (§3), S3b closes it.
(ii) A specific ALL of whose payloads are rejected (§2.3) degrades at the SCRUTINEE gate, not
the empty/partial-table exhaustiveness bail (S2e deviation (3)): the error witness makes
`GetObjectRepr` return `ErrorInst::TypeId` (sem_ir/class.cpp:46-48), so
`GetChoiceDiscriminantType` returns nullopt and the match keeps the scrutinee TODO — the S3b
fail golden pins that placement. With (i)+(ii), (c) is verification work, not new machinery.

### 2.6 R-7 cleanups statement (re-derivation for S3)

The scrutinee-gate soundness argument (handle_match.cpp:116-122: payloads restricted to
trivially copyable+destructible "when the choice's representation is completed") is re-derived,
not inherited — and now holds BY CONSTRUCTION: §2.1(2) makes the gate itself force
completion/resolution before any repr read, so every specific admitted past
`GetChoiceDiscriminantType` has run §2.3's SF-6 check regardless of how the scrutinee value was
produced. The value-producing-path audit would in fact fail — pointer deref and import complete
nothing (R-2) — which is why the forcing is part of Option B's adoption, not an optimization.
The S2b-S2e cleanup discipline (`DeferCleanups` at bind, guard-failure-edge discharge) carries
over with no new temporary-producing paths — S3 adds substitution and analysis only.

---

## 3. Slices

Each independently landable through the full R11 loop (implementer → 2 adversarial reviewers →
fixer → merge gate: runner autoupdate + `bazel test //toolchain/...` + conformance
non-regression), with scoreboard/work-items/decision-log updates at landing (R9).

### S3a — payload-free generic choices end-to-end (S)

Scope — two code changes plus testdata, NOTHING else: delete the pattern_match.cpp:366
`specific_id` clause; add §2.1(2)'s forced completion at the scrutinee gate. (The originally
sketched "populate the alternative table" is a NO-OP — §2.5(i); all table work is S3b's.)
Exit criteria: check testdata match/choice_generic_scrutinee.carbon — two-alternative
payload-free generic; exhaustive match without `default`; nonexhaustive fail subfile naming the
missing alternative; the R-5 one-file pin as an explicit subfile (exhaustive `P(i32)` compiling
beside `P(bool)` missing one alternative, diagnosed by name); imported-generic pair per
choice_scrutinee_imported.carbon conventions; positive golden matching `x: P(T)` INSIDE a
generic body (`fn F(T:! type, x: P(T))`) — symbolic-specific scrutinees of payload-free choices
are admitted by the same :366 deletion and scoped IN, sound at S3a because their witness is
concrete (risk R-8; S3c adds the destructuring counterpart); fail subfile pinning W-068
composition post-deletion (`Always(i32)` and a zero-alternative specific keep the scrutinee
TODO by way of pattern_match.cpp:387); fail subfile pinning the mixed-choice partial-table
window — the definition TODO PAIRED with the silent exhaustiveness pass over constant-only
coverage (§2.5 i); lower golden pinning discriminant dispatch on a specific.
Conformance: NEW one-file roundtrip program types/choice_generic_roundtrip.carbon (construct
and match two payload-free specifics, printed output) — PASS 78/109. S3a is runtime-arbitrated
after all; independently, S3b's differential commits to probing the payload-free dispatch path
explicitly (its `.None`/monostate `index()` arm).

### S3b — generic payload synthesis + per-specific layout (L, the risk slice)

Scope: lift handle_choice.cpp:628-631; symbolic-payload definition path + sentinel + eval-time
recomputation, including the `CustomLayoutType` constant-kind change (§2.2); SF-6 per-specific
enforcement (§2.3); constructor generic wiring (§2.4); full table population (§2.5 i).
PRE-DECLARED fallback split if the slice overruns: S3b-i (definition path + sentinel +
recompute + SF-6, arbitrated by check/lower goldens) and S3b-ii (constructor wiring + the
differential pair), each independently landable.
Exit criteria: `Optional(T: type) { Some(value: T), None }` — `Optional(i32).None` and
`.Some(42)` construct at runtime and match by discriminant (`case .None` + `default`, the S1
honesty minimum); check+lower goldens choice/generic_payload.carbon pinning TWO specifics with
different payload sizes (`P(i32)` vs `P((i64, i64))`-shaped) showing distinct `[N x i8]`
regions matching R-1's independently derived numbers; a mixed-alternative max-of-fields golden
(one concrete-payload + one symbolic-payload alternative, the largest flipping between the two
pinned specifics); an imported-generic-payload pair whose IMPORTING-file lower golden pins the
recomputed `[N x i8]` — R-4's falsifier landed as an exit artifact; R-2's counter-program
subfiles (pointer-deref scrutinee, imported `let`) plus the by-value-param passing pin; fail
goldens: per-specific SF-6 rejection (§2.3's diagnostic), Self-dependent payload (narrowed
string, §6), and the §2.5(ii) pin — all payloads rejected degrades at the SCRUTINEE gate
(`GetObjectRepr == ErrorInst`), not the exhaustiveness bail.
Conformance: new types/choice_generic_diff.carbon / .diff.cpp (C++ oracle: class template over
`std::variant<T, std::monostate>` probed by way of `index()`, DIFF-1 conventions), the probe
explicitly exercising the payload-free `.None`/monostate arm — PASS 79/110. The diff pair
runtime-arbitrates SIZE, not alignment; alignment is pinned only by the lower goldens (R-1).

### S3c — payload destructuring on specifics + the sum_types.md example (M)

Scope: `case .Some(the_value: i32)` on an `Optional(i32)` scrutinee — expected to be mostly
verification: `GetChoicePayloadInfo` and the bind pass's element access
(handle_match.cpp:602-625) already consume specific-resolved types under Option B; this slice
pins it, re-derives R-7 for substituted binding conversions (`case .Some(v: i64)` on an `i32`
payload — same `DeferCleanups` shape as S2c), and closes exhaustiveness with payload arms.
Exit criteria: the sum_types.md:60-89 example compiles and runs with the doc's
declaration/construction/match shapes verbatim, I/O adapted per R1 (match without `default`) —
discharging S2e deviation (2); check golden match/choice_generic_payload_pattern.carbon
(+ guarded-arm and imported-generic subfiles, and the R-8 counterpart: payload destructuring
from SYMBOLIC payload tuples inside a generic body); conformance control_flow/
choice_generic_roundtrip_diff.carbon / .diff.cpp (runtime-computed payload, R16d) — PASS 80/111.

Dependency chain: S3a → S3b → S3c. Inventory: completes W-010's generic residue; the choice
half of W-011 stays with S3c's roundtrip arbiter; W5-S4 and W5-S3p (post-SF-9) follow.

---

## 4. Byte-equivalence expectations

Concrete choices take byte-identical paths in all three slices: the :366 deletion is
unreachable for `specific_id == None`; §2.1(2)'s forced completion is a no-op for
already-complete concrete choice types; the handle_choice.cpp changes are inside
`is_generic_choice`-only branches plus a symbolic-only skip of the size fold; and the §2.2 eval
overload passes every alignment != 0 layout block through unchanged — ALSO the byte-equivalence
argument for C++-imported class layouts (their Clang-computed blocks, check/cpp/
import.cpp:855-868, never carry the sentinel). Expected golden churn: ONLY the new files plus
the §6 flips (fail_todo_generic_payload.carbon, params.carbon's fail_todo_generic_params/
fail_todo_self_param subfiles). The previously budgeted choice/generic.carbon churn is
WITHDRAWN — S3a never touches the table (§2.5 i), and the table is unprinted anyway; any
movement there is a stop-and-explain event. The stop-and-explain watchlist explicitly includes
every C++-IMPORTED-CLASS check and lower golden (the blast radius if §2.2's predicate is wrong).

## 5. Risk register (falsifiable)

-   **R-1. Stale-layout silent miscompile.** The §2.2 recompute is the load-bearing claim.
    Expected numbers, derived HERE so review arbitrates against the plan, not the compiler's
    own output: payload region = max over alternatives of payload tuple size, rounded up to max
    alignment (F-007k); `P(i32)` = 4 bytes, align 4 (`[4 x i8]`); `P((i64, i64))` = 16 bytes,
    align 8 (`[16 x i8]`); the mixed-alternative golden's two specifics must flip WHICH
    alternative is largest. FALSIFIER: regions equal, zero-sized (sentinel leaked), or off the
    derived numbers. The differential pair catches SIZE at runtime; ALIGNMENT is arbitrated
    only by the lower goldens (the diff pair cannot observe it). Reviewer #2's brief: verify
    the goldens discriminate (R-6 discipline).
-   **R-2. Forced-completion gap at the scrutinee gate.** §2.1(2) claims the gate forces
    witness resolution before any repr read. FALSIFIERS — two real counter-programs, each an
    S3b subfile: (a) pointer-deref scrutinee, `fn F(p: P(Big)*) { match (*p) {...} }` — the
    pointee is never completed on the way in (completion has no nested `PointerType` case,
    type_completion.cpp:440-520; a pointer's value repr is Copy, :712-717;
    `PerformPointerDereference` completes nothing), so WITHOUT the forcing, `GetObjectRepr` on
    the unresolved specific dies on the value-block CARBON_CHECK (sem_ir/generic.cpp:86-101);
    (b) an imported `let x: P(Big)` matched in another file. The by-value-param program
    (`fn F(x: P(NonTrivial))`) is a PASSING pin, not a falsifier — parameter setup already
    completes the type. CAUTION: S3a's payload-free shapes cannot crash even unforced (concrete
    witness; `GetConstantInSpecific` early-returns on non-symbolic constants,
    sem_ir/generic.cpp:59-61) — S3a green does NOT validate the unforced path; only (a)/(b) arbitrate it.
-   **R-3. Constructor generic wiring (§2.4).** If the pre-committed bracketing needs bespoke
    plumbing beyond the member-function precedent, that is a plan-revision trigger (W5 §6
    discipline), not an inline improvisation. FALSIFIER: `P(i32).Ok(42)` and `P(f64).Ok(1.5)`
    called in one function, lowered — two distinct specific function bodies in the golden.
-   **R-4. Imported generic choices.** Layout recompute must fire in the IMPORTING file
    (witness imports symbolic; local specifics evaluate locally through import_ref's
    CustomLayoutType resolver, import_ref.cpp:4186-4217/:4531). FALSIFIER-AS-ARTIFACT: the S3b
    imported-generic-payload pair's importing-file lower golden pinning the recomputed
    `[N x i8]` (§3 S3b exit), plus S3c's imported subfile; a stale import shows as a wrong
    region size there.
-   **R-5. Exhaustiveness identity across specifics.** Shared `class_id` is the argument
    (§2.5). FALSIFIER (an explicit S3a subfile, not a hypothetical): one file matching `P(i32)`
    exhaustively (no `default`, must compile) and `P(bool)` missing one alternative (must
    diagnose, naming it) — coverage bleeding between the nested `MatchStatementContext`s or
    between specifics proves it wrong.
-   **R-6. Upstream collision (standing rule 5).** Choice payloads and generics are live
    upstream territory; re-check carbon-language/carbon-lang for in-flight generic-choice work
    before each slice's implementation starts; a hit escalates to the orchestrator.
-   **R-8. Symbolic-specific scrutinees (scoped in — §3 S3a/S3c).** Matching `x: P(T)` inside a
    generic body is admitted by the same :366 deletion; payload-free choices are sound at S3a
    (concrete witness), and §2.1(2)'s `RequireCompleteType` defers symbolic types to
    monomorphization instead of reading an unresolved repr. RISK: generic-body match behavior
    is otherwise unexercised; the S3a positive golden and S3c's symbolic-destructuring golden
    are the pins. Instability here NARROWS the scope-in (re-gate behind the TODO), not the
    slice. (Risk label R-7 is skipped — it would collide with the R-7 cleanups rule in §2.6/§9.)

## 6. TODO-string discharge ledger

-   `` `choice alternative payload with generic or Self-dependent type` `` — emitted at
    handle_choice.cpp:631 (generic-choice branch) and :645-648 (symbolic/Self-dependent branch).
    S3b DELETES :631 and NARROWS :645-648: symbolic types in generic choices proceed to
    synthesis; `TypeContainsChoice` keeps a gate with the narrowed string
    `` `choice alternative payload with Self-dependent type` `` (a golden+decision-log co-change
    per R10). Pins that move: choice/fail_todo_generic_payload.carbon flips to positive
    generic_payload.carbon; params.carbon's fail_todo_generic_params subfile flips positive;
    its fail_todo_self_param subfile re-pins to the narrowed string.
-   `` `match on unsupported scrutinee type` `` — survives BYTE-IDENTICAL at
    handle_match.cpp:140; what lifts is the un-stringed `specific_id` clause at
    pattern_match.cpp:366 (S3a). No pin moves — none exists (§1's pin-gap finding); S3a adds
    the positive goldens that would have replaced it.
-   `` `match `case` pattern other than an integer literal, or a case guard` `` — survives
    byte-identical at all six sites; its handle_match.cpp:246-248 site simply stops firing for
    choice-specific scrutinees once :366 lifts (no text or site change).
-   S2e's `` `match statement without `default` arm` `` (integer narrowing) and all other
    strings: untouched.

## 7. Testdata & golden flow

Per-slice lists in §3. House rules apply: new failing subfiles ship hand-written CHECK:STDERR
pins (S2c-S2e precedent); other CHECK content rides the runner autoupdate (R15/R19, one
red-first-CI reconciliation commit per slice); no local build — verification rides CI;
clang-format hooks (R12/R18); `runner.py --self-test` before conformance-touching commits (R7);
private `--out` (R5).

## 8. Conformance floor arithmetic

Current floor (fork/conformance/out/scoreboard.json, regenerated at S2e): **77 PASS / 0 FAIL /
31 SKIP over 108 programs.** Grep evidence: NO SKIP in fork/conformance/programs cites the
generic-choice TODO strings; the only program quoting the scrutinee string is
control_flow/match_sum_type_payload.carbon, whose SKIP pins a DIFFERENT blocker (no
std::variant/std::optional interop mapping; W5 slice 4), and stdlib/optional_missing_ops.carbon
pins the SF-9 placeholder API, not this slice. Therefore **no existing SKIP flips in
S3a-S3c**; the floor moves only by addition, exactly one new PASS program per slice: S3a
**78/0/31 over 109** (types/choice_generic_roundtrip.carbon), S3b **79/0/31 over 110** (the
choice_generic_diff pair counts as one program), S3c **80/0/31 over 111**
(choice_generic_roundtrip_diff). Both quoted SKIPs stay, un-SKIPped by W5-S4 and W5-S3p
respectively. Scoreboard regeneration rides each landing gate (R9); FAIL stays 0 throughout.

## 9. R-7 cleanups

Stated in §2.6 and re-derived per slice: S3a adds analysis only; S3b's new runtime code is the
constructor body (return-slot in-place init, no temporaries beyond S1's audited shape); S3c
re-derives the binding-conversion temporary discipline on substituted payload types. No new
cleanup-registering path is introduced anywhere in the slice family.

## Approval gate

This plan does not authorize implementation. Per house protocol it goes to TWO adversarial plan
reviewers first — briefs: reviewer #1 attacks the §2.2 eval-recompute design and the R-2
ordering claim with concrete counter-programs; reviewer #2 attacks the ledger, the
byte-equivalence claims, and whether every §3 exit criterion is arbitrable (R16 Goodhart
checks, including R-1's golden-discrimination check). Findings return as data; the plan is
revised and re-reviewed until both pass; only then does the S3a implementer start, with the V-2
veto digest carrying every sub-decision above to the user for overrule: (1) the §0.2 prelude
split, (2) the §2.3 diagnostic placement, (3) the §6 string narrowing, (4) Option B adoption
itself, including the forced completion at the scrutinee gate (§2.1), (5) the sentinel-zero
layout representation choice (§2.2), (6) the S3a conformance-program addition (§3/§8).
