<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W5-S3 plan: generic `choice` types — payload synthesis, specifics as scrutinees, exhaustiveness through specifics

Status: PLAN (process step 6, scaled loop). Baseline: trunk 435ce66 (post-match-re-platform
integrated line). Design authority: docs/design/sum_types.md (esp. :60-89, the
`Optional(T: type)` declaration/construction/match example), the normative F-007k storage
contract (docs/design/unions.md, "Relationship to choice types"), and the ratified decisions
in fork/decision-log.md (W5 SF-1..8, W5-S1 scope trades, S2a-S2e landing notes). Precedent
format: fork/w5-choice/plan.md + fork/match-replatform/plan.md. This document supersedes
fork/w5-choice/plan.md §4's S3 outline. NO implementation in this document — planning only.

---

## 0. Scope and non-goals

### 0.1 In scope

Three recorded W5-S1 gates lift, in dependency order:

-   **(a) Payload synthesis in generic choices** — lifts the decision-log W5-S1 gate
    "Alternatives with parameter lists in generic choices are gated to the generic/
    Self-dependent TODO string … generic synthesis is S3's re-plan". The code gate is the
    `is_generic_choice` branch in toolchain/check/handle_choice.cpp:628-631, which rejects
    EVERY parameterized alternative of a generic choice — including concrete-typed ones
    (`Concrete(b: i32)`, pinned by choice/fail_todo_generic_payload.carbon) and zero-payload
    `Alt()`.
-   **(b) Specifics of generic choices as `match` scrutinees** — lifts "Specifics of generic
    choices are not matchable in S1 (`choice P(T: type) { A, B }` matched as a `P(i32)`
    value) … S3's generic re-plan owns it". The code gate is ONE clause:
    `class_type->specific_id.has_value()` in `GetChoiceDiscriminantType`
    (toolchain/check/pattern_match.cpp:366), which routes such scrutinees to the
    `match on unsupported scrutinee type` TODO (handle_match.cpp:140) and alternative
    patterns to the combined W4 string (handle_match.cpp:245-248).
-   **(c) Exhaustiveness for generic-choice specifics** — should fall out of (b) + S2e's
    `MatchStatementContext` analysis. §2.5 verifies the argument rather than assuming it.
    Discharges S2e recorded deviation (2): "§3.5's 'sum_types.md example compiles' is met
    modulo genericity" — after S3 the doc's `Optional(i32)` match compiles without `default`.

### 0.2 Out of scope (with rationale)

-   **W-068: choices with fewer than two alternatives.** Their discriminant is `()`, not an
    integer; `GetChoiceDiscriminantType` rejects them at :387 independently of `specific_id`,
    so the gates compose — `Always(i32)` for `choice Always(T: type) { Sunny }` stays behind
    the scrutinee TODO, still pinned by match/fail_todo_single_alternative_choice.carbon.
    Admitting them is dispatch-shape work (no-test arms), orthogonal to genericity.
-   **User-defined `Match` interface / Continuation machinery** (sum_types.md:124-246) —
    the whole-workstream W5 §0.3 exclusion, unchanged.
-   **Template-dependent scrutinees.** A scrutinee whose type is a template-phase symbolic
    (`template T:! type` member shapes) never resolves to a concrete `ClassType` at check
    time; it keeps the scrutinee TODO. Template monomorphization lowering is itself
    CARBON_FATAL upstream (conformance SKIP generics/templates_dependent_member.carbon).
-   **Prelude `Core.Result(T, E)` / `Core.Optional(T)` and SF-9.** The original S3 sketch
    bundled them; this re-plan splits them out. SF-9 (identity of the existing
    `Core.Optional` class) is an undecided user fork that "must be decided before S3's
    detailed plan is written" — for the PRELUDE half only. The generic-choice machinery here
    has no SF-9 dependency, and stdlib/optional_missing_ops.carbon's SKIP is pinned to the
    placeholder API, not to this slice. A follow-on W5-S3p (prelude) plan rides the SF-9
    AskUserQuestion round and unblocks F-006 B1; sequencing it after S3c means the prelude
    types land on proven machinery.
-   **SF-6 relaxation** (non-trivially-copyable/destructible payloads) and **SF-4 qualified
    patterns** (`Optional(i32).Some(v)` in case position) — recorded post-0.1/work-item
    status unchanged; §2.3 covers how SF-6's gate MOVES for generic choices without widening.

---

## 1. Current state (claims re-derived from the tree at 435ce66)

-   **The alternative metadata is already specific-independent.** `SemIR::ChoiceAlternative`
    (sem_ir/class.h:35-55) stores `{name_id, index, payload_field_index, has_parameters}` —
    no TypeIds. Its import copies indices verbatim ("plain integers … carry over unchanged",
    import_ref.cpp:2077-2088). All type information flows from the object repr at use time.
-   **The use sites already thread `specific_id`.** `GetChoiceDiscriminantType` and
    `GetChoicePayloadInfo` call `class_info.GetObjectRepr(sem_ir, class_type->specific_id)`
    (pattern_match.cpp:374, :425) — dead generality today, guarded by the :366 rejection.
    Upstream's `Class::GetObjectRepr` resolves the witness per-specific by way of
    `GetConstantValueInSpecific(file, specific_id, complete_type_witness_id)`
    (sem_ir/class.cpp:39-53), the same idiom as `GetAdaptedType`/`GetBaseType`.
-   **The layout numbers are the real problem.** `CustomLayoutType` bakes concrete
    `[size, align, offsets…]` into a `CustomLayoutId` block (typed_insts.h:617-627,
    handle_choice.cpp:694-718). Generic eval substitutes `StructTypeFieldsId` field types
    (eval.cpp:652-680) but `CustomLayoutId` has no `GetConstantValue` overload — a
    substituted `CustomLayoutType` would carry STALE definition-time numbers, and BOTH
    consumers read them blind: `TypeCompleter::BuildInfoForInst` (type_completion.cpp:787-795)
    and lowering's `[N x i8]` (lower/type.cpp:633-640). Without per-specific recomputation
    this silently miscompiles — W5 plan R-9's prophecy, now located precisely.
-   **Eval-time completion is an established idiom.** `EvalConstantInst` for
    `RequireCompleteType` calls `TryToCompleteType` during monomorphization and diagnoses
    `IncompleteTypeInMonomorphization` (eval_inst.cpp:603-639); eval also owns the
    "unable to monomorphize specific {0}" context (eval.cpp:3290). Per-specific semantic
    work inside eval, with diagnostics, is precedented — not invented here.
-   **Payload-free generic choices already complete concretely.** choice/generic.carbon's
    golden shows `complete_type_witness %struct_type.discriminant [concrete]` inside the
    generic — a payload-free generic choice's repr has no symbolic content, so slice (b) for
    the payload-free shape needs no layout work at all.
-   **Plan finding — the specifics scrutinee gate is UNPINNED.** Grep shows only three
    goldens pin `match on unsupported scrutinee type` (fail_todo_non_int_scrutinee,
    fail_todo_adapter_scrutinee, fail_todo_single_alternative_choice); none matches a
    specific of a generic choice, and choice/generic.carbon never constructs or matches one.
    The W5-S1 recorded gate exists in prose only. S3a adds the positive pins directly; the
    reviewers' brief notes the pre-existing pin gap (R10 hygiene).

---

## 2. Design

### 2.1 Metadata resolution through a specific — two options, one recommendation

-   **Option A — extend the table.** Grow `ChoiceAlternative` with payload/param TypeInstIds
    and substitute them at lookup (or materialize a per-specific table copy). Rejected:
    upstream keeps NO per-specific entity tables anywhere — specifics resolve member values
    on demand through `GetConstantValueInSpecific` (see `GetObjectRepr`/`GetAdaptedType`/
    `GetBaseType`, and pattern_match.cpp's own `WrapInstForSpecific`/`specific_id_stack_`
    machinery at :68-73, :1095-1107); the table was deliberately built type-free and its
    import contract ("plain integers") would break; and a second source of payload-type
    truth can drift from the repr the bind pass actually indexes into.
-   **Option B — resolve through the specific at use (RECOMMENDED).** Keep the table
    type-free. Delete the `specific_id.has_value()` clause at pattern_match.cpp:366; every
    downstream consumer already passes `class_type->specific_id` into `GetObjectRepr`, so
    discriminant type, payload region type, and per-alternative payload tuple types arrive
    substituted for free once the specific's witness constant is correct. This is a
    one-clause lift riding upstream's exact members-of-specifics idiom; all new work
    concentrates in §2.2 where it belongs (the repr, not the metadata).

### 2.2 Per-specific payload layout (the S3b core)

At the definition of a generic choice with symbolic payloads, `GetCompleteTypeInfo` cannot
supply sizes. The definition-time computation (handle_choice.cpp:679-684) changes for
symbolic payload tuple types only: skip the size/align max-fold and emit the
`CustomLayoutType` with sentinel zero size/align (fields carry the symbolic tuple types; the
witness constant is symbolic, so nothing concrete ever reads the sentinels). Then add an
`EvalConstantInst(Context&, InstId, SemIR::CustomLayoutType)` overload in eval_inst.cpp: when
every substituted field type is concrete, complete each (the `TryToCompleteType` discipline
of the `RequireCompleteType` case, including its diagnostic-context scope) and rebuild the
layout block with real max-of-fields numbers, returning a fresh concrete constant; while any
field is symbolic, `NewSamePhase`. Because a `var` of type `P(i32)` forces
`require_complete` evaluation before any value exists, every concrete use sees a recomputed
layout — completion and lowering read correct numbers with zero changes to either consumer.
Concrete choices never enter the new path (their layout is baked correct at definition and
their constant is already concrete-at-birth).

### 2.3 SF-6 enforcement moves to monomorphization for symbolic payloads

`IsInSlicePayloadType(T)` is unanswerable at definition time for symbolic `T`. The
definition-time loop (handle_choice.cpp:633-665) keeps: the Self-dependence rejection
(`TypeContainsChoice`) and the SF-6 check for CONCRETE payload types (now also inside
generic choices — `Concrete(b: i32)` validates at definition). Symbolic payload types defer
to the §2.2 eval hook, which runs the same `IsInSlicePayloadType` on the substituted type
and diagnoses (new real diagnostic, not a TODO:
`` choice alternative payload type {0} is not trivially copyable and destructible in this specific ``,
name TBD by implementer within R10 discipline) — so `P(String)` errors at the use that
forces the specific, with the monomorphization context note. Recorded trade: the diagnostic
lands at the use site, not the declaration — same placement as
`IncompleteTypeInMonomorphization`, upstream's own precedent. The W5-S1 admitted exception
(no destroy-witness query) carries over unchanged and un-widened.

### 2.4 Constructor synthesis under genericity

`BuildAlternativeConstructor` runs inside `StartGenericDefinition`/`FinishGenericDefinition`
already, but `MakeGeneratedFunctionDecl` hard-codes `build_generic=false` /
`generic_id = None` (function.cpp:164-201). A constructor of a generic choice must
participate in the enclosing generic so `P(i32).Ok(42)` and `P(f64).Ok(1.5)` resolve, check,
and LOWER as distinct specifics: S3b wires the generated decl through `BuildGenericDecl`
(or an equivalent enclosing-generic attachment — implementer picks the minimal upstream-
idiomatic spelling; member functions of generic classes are the precedent). This is the
slice's second-deepest unknown after §2.2 — see R-3.

### 2.5 Exhaustiveness through specifics — verification of "falls out"

`DiagnoseNonexhaustiveMatch` (handle_match.cpp:717-769) reads
`class_info.choice_alternatives` by way of `class_type.class_id`; specifics of one generic share
the `class_id`, so the alternative table — and therefore coverage identity — is shared by
construction, and per-arm coverage records the table's `index` (handle_match.cpp:560-572),
also specific-independent. Two provisos make this real rather than assumed: (i) S3a must
populate the table for generic choices' parameterized alternatives (today the :628 reject
path skips the push at :778-783, so a generic choice's table holds only its constant
alternatives — matching `P(i32)` against a table missing `Ok` would wrongly diagnose or
mis-resolve); (ii) the empty/partial-table error-recovery bail (S2e deviation (3)) must
behave identically when the rejections happened per-specific — covered by an S3b fail
golden. With (i)+(ii), (c) is verification work, not new machinery.

### 2.6 R-7 cleanups statement (re-derivation for S3)

The scrutinee-gate soundness argument (handle_match.cpp:116-122: payloads restricted to
trivially copyable+destructible "when the choice's representation is completed") is
re-derived, not inherited: for a specific of a generic choice, the SF-6 property is
enforced at the specific's witness resolution (§2.3), and a scrutinee value of type
`P(i32)` cannot exist before that resolution ran — `require_complete` is forced by the
declaration that produced the value. So every specific admitted past
`GetChoiceDiscriminantType` has only trivial payloads, and the S2b-S2e cleanup discipline
(`DeferCleanups` at bind, guard-failure-edge discharge) carries over with no new
temporary-producing paths: S3 adds substitution and analysis, not runtime conversions.
Reviewers must attack the ordering claim (R-2's falsifier).

---

## 3. Slices

Each independently landable through the full R11 loop (implementer → 2 adversarial
reviewers → fixer → merge gate: runner autoupdate + `bazel test //toolchain/...` +
conformance non-regression), with scoreboard/work-items/decision-log updates at landing (R9).

### S3a — payload-free generic choices end-to-end (S)

Scope: delete the pattern_match.cpp:366 `specific_id` clause; populate the alternative
table for generic choices (constant alternatives only in this slice — the :628 synthesis
gate stays); pin construction (`P(i32).A` by way of the `WrapperBinding`'s symbolic constant
resolved through the specific) and match+exhaustiveness of `P(i32)` scrutinees.
Exit criteria: check testdata match/choice_generic_scrutinee.carbon (two-alternative
payload-free generic; exhaustive match without `default`; nonexhaustive fail subfile naming
the missing alternative; two different specifics matched in one function; imported-generic
pair per choice_scrutinee_imported.carbon conventions); lower golden pinning discriminant
dispatch on a specific; `Always(T)` single-alternative stays gated (W-068 pin unchanged).
Conformance: none flips (§8); no new program — runtime observability arrives with S3b's
differential pair, and S3a's dispatch is pinned by the lower golden (recorded honesty note:
this is the one slice arbitrated by goldens, not runtime, because a payload-free
generic-choice program adds nothing over types/choice_basic.carbon + generics/generic_class.carbon).

### S3b — generic payload synthesis + per-specific layout (L, the risk slice)

Scope: lift handle_choice.cpp:628-631; symbolic-payload definition path + eval-time layout
recomputation (§2.2); SF-6 per-specific enforcement (§2.3); constructor generic wiring
(§2.4); full table population. Exit criteria: `Optional(T: type) { Some(value: T), None }`
— `Optional(i32).None` and `.Some(42)` construct at runtime and match by discriminant
(`case .None` + `default`, the S1 honesty minimum); check+lower goldens
choice/generic_payload.carbon pinning TWO specifics of one generic with different payload
sizes (`P(i32)` vs `P((i64, i64))`-shaped) showing distinct `[N x i8]` regions — the R-1
discriminating golden; fail goldens: per-specific SF-6 rejection, Self-dependent payload
(narrowed string, §6), per-specific all-alternatives-rejected exhaustiveness bail (§2.5 ii).
Conformance: new types/choice_generic_diff.carbon / .diff.cpp (C++ oracle: class template
over `std::variant<T, std::monostate>` probed by way of `index()`, DIFF-1 conventions) — PASS
78/109.

### S3c — payload destructuring on specifics + the sum_types.md example (M)

Scope: `case .Some(the_value: i32)` on an `Optional(i32)` scrutinee — expected to be mostly
verification: `GetChoicePayloadInfo` and the bind pass's element access
(handle_match.cpp:602-625) already consume specific-resolved types under Option B; this
slice pins it, re-derives R-7 for substituted binding conversions (`case .Some(v: i64)` on
an `i32` payload — same `DeferCleanups` shape as S2c), and closes exhaustiveness with
payload arms. Exit criteria: the sum_types.md:60-89 example compiles and runs VERBATIM
(match without `default`) — discharging S2e deviation (2); check golden
match/choice_generic_payload_pattern.carbon (+ guarded-arm and imported-generic subfiles);
conformance control_flow/choice_generic_roundtrip_diff.carbon / .diff.cpp
(runtime-computed payload, R16d) — PASS 79/110.

Dependency chain: S3a → S3b → S3c. Inventory: completes W-010's generic residue; the
choice half of W-011 stays with S3c's roundtrip arbiter; W5-S4 (interop) and W5-S3p
(prelude, post-SF-9) follow.

---

## 4. Byte-equivalence expectations

Concrete choices take byte-identical paths in all three slices: the :366 deletion is
unreachable for `specific_id == None`; the handle_choice.cpp changes are inside
`is_generic_choice`-only branches plus a symbolic-only skip of the size fold; the eval
overload triggers only for CustomLayoutType constants with symbolic fields (concrete
choices' constants are born concrete and never re-evaluate). Expected golden churn: ONLY
the new files plus the §6 flips (fail_todo_generic_payload.carbon, params.carbon's
fail_todo_generic_params/fail_todo_self_param subfiles) and choice/generic.carbon's
dump-sem-ir if S3a's table population perturbs the generic body (budgeted, reviewed as
sanctioned). Any other golden movement is a stop-and-explain event.

## 5. Risk register (falsifiable)

-   **R-1. Stale-layout silent miscompile.** The §2.2 recompute is the load-bearing claim.
    FALSIFIER: the S3b lower golden's two-specific choice — if the two `[N x i8]` payload
    regions come out the same size (or match the definition-time sentinel), the recompute
    didn't run; the differential pair's `P((i64,i64))` round-trip catches it at runtime.
    Reviewer #2's brief: verify the golden discriminates (R-6 discipline).
-   **R-2. SF-6 ordering hole.** If any path yields a `P(BadT)` scrutinee value without
    having forced witness resolution, an untriviality-unchecked payload passes the match
    gate. FALSIFIER: a program declaring `fn F(x: P(NonTrivial))` (param, not `var`) and
    matching `x` — must diagnose at the specific, not compile; reviewers hunt other
    value-producing paths (returns, tuple elements, imported constants).
-   **R-3. Constructor generic wiring (§2.4).** `MakeGeneratedFunctionDecl`'s
    `build_generic=false` may not extend cleanly; if constructors need bespoke generic
    plumbing beyond the member-function precedent, that is a plan-revision trigger (W5 §6
    discipline), not an inline improvisation. FALSIFIER: `P(i32).Ok(42)` and `P(f64).Ok(1.5)`
    called in one function, lowered — two distinct specific function bodies in the golden.
-   **R-4. Imported generic choices.** Layout recompute must fire in the IMPORTING file
    (witness imports symbolic; local specifics evaluate locally through import_ref's
    CustomLayoutType resolver, import_ref.cpp:4186-4217/:4531). FALSIFIER: the S3b/S3c
    imported-generic testdata pairs (declare generic choice in a library; construct, match,
    and exhaustively cover a specific in another file); a stale import shows as a wrong
    region size in the importing file's lower golden.
-   **R-5. Exhaustiveness identity across specifics.** Shared `class_id` is the argument
    (§2.5). FALSIFIER: one function matching `P(i32)` exhaustively (no `default`, must
    compile) and `P(bool)` missing one alternative (must diagnose, naming it) — coverage
    bleeding between the nested `MatchStatementContext`s or between specifics proves it wrong.
-   **R-6. Upstream collision (standing rule 5).** Choice payloads and generics are live
    upstream territory; re-check carbon-language/carbon-lang for in-flight generic-choice
    work before each slice's implementation starts; a hit escalates to the orchestrator.

## 6. TODO-string discharge ledger

-   `` `choice alternative payload with generic or Self-dependent type` `` — emitted at
    handle_choice.cpp:631 (generic-choice branch) and :646-647 (symbolic/Self-dependent
    branch). S3b DELETES the :631 site and NARROWS :646: symbolic types in generic choices
    proceed to synthesis; `TypeContainsChoice` keeps a gate with the narrowed string
    `` `choice alternative payload with Self-dependent type` `` (string change is a
    golden+decision-log co-change per R10). Pins that move: choice/
    fail_todo_generic_payload.carbon flips to positive generic_payload.carbon;
    params.carbon's fail_todo_generic_params subfile flips positive; its
    fail_todo_self_param subfile re-pins to the narrowed string.
-   `` `match on unsupported scrutinee type` `` — the string survives BYTE-IDENTICAL at
    handle_match.cpp:140; what lifts is the un-stringed `specific_id` clause at
    pattern_match.cpp:366 (S3a). No pin moves — none exists (§1's pin-gap finding); S3a
    adds the positive goldens that would have replaced it.
-   `` `match `case` pattern other than an integer literal, or a case guard` `` — survives
    byte-identical at all six sites; its handle_match.cpp:245 site simply stops firing for
    choice-specific scrutinees once :366 lifts (no text or site change).
-   S2e's `` `match statement without `default` arm` `` (integer narrowing) and all other
    strings: untouched.

## 7. Testdata & golden flow

Per-slice lists in §3. House rules apply: new failing subfiles ship hand-written
CHECK:STDERR pins (S2c-S2e precedent), all other CHECK content rides the runner autoupdate
(R15/R19, one red-first-CI reconciliation commit per slice budgeted); no local build —
verification rides CI; clang-format hooks (R12/R18); `runner.py --self-test` before
conformance-touching commits (R7); private `--out` (R5).

## 8. Conformance floor arithmetic

Current floor (fork/conformance/out/scoreboard.json, regenerated at S2e): **77 PASS /
0 FAIL / 31 SKIP over 108 programs.** Grep evidence: NO SKIP in fork/conformance/programs
cites the generic-choice TODO strings; the only program quoting the scrutinee string is
control_flow/match_sum_type_payload.carbon, whose SKIP pins a DIFFERENT blocker —
"Remaining blocker: no std::variant/std::optional interop mapping (check/cpp/
custom_type_mapping.cpp has no variant/optional matcher; W5 slice 4)" — and
stdlib/optional_missing_ops.carbon pins the SF-9 placeholder ("Core.Optional is an
unapproved placeholder API … with no comparison support"), not this slice. Therefore **no
existing SKIP flips in S3a-S3c**; the floor moves only by addition: S3a 77/0/31 over 108
(unchanged), S3b 78/0/31 over 109, S3c 79/0/31 over 110. Both quoted SKIPs stay, un-SKIPped
by W5-S4 and W5-S3p respectively. Scoreboard regeneration rides each landing gate (R9);
FAIL stays 0 throughout.

## 9. R-7 cleanups

Stated in §2.6 and re-derived per slice: S3a adds analysis only; S3b's new runtime code is
the constructor body (return-slot in-place init, no temporaries beyond S1's audited shape);
S3c re-derives the binding-conversion temporary discipline on substituted payload types.
No new cleanup-registering path is introduced anywhere in the slice family.

## Approval gate

This plan does not authorize implementation. Per house protocol it goes to TWO adversarial
plan reviewers first — briefs: reviewer #1 attacks the §2.2 eval-recompute design and the
R-2 ordering claim with concrete counter-programs; reviewer #2 attacks the ledger, the
byte-equivalence claims, and whether every §3 exit criterion is arbitrable (R16 Goodhart
checks, including R-1's golden-discrimination check). Findings return as data; the plan is
revised and re-reviewed until both pass it; only then does the S3a implementer start, with
the V-2 veto digest carrying every sub-decision recorded above (the §0.2 prelude split, the
§2.3 diagnostic placement, the §6 string narrowing) to the user for overrule.
