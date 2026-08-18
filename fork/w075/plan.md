<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-075 plan: choice alternative constants in initializing position — the Core.Copy witness

Status: PLAN. Drafted 2026-08-18. Size S — one slice (W75a).
Baseline: trunk 3ee4b05 (post-PR #30; conformance **96 PASS / 0 FAIL /
28 SKIP over 124**). Authoritative record: fork/inventory/work-items.json
W-075 (minted at the W69b fix round, fork/w069/plan.md blocker 1). NO
implementation in this document. All verification rides self-hosted
runner CI (autoupdate to fixpoint per R26; conformance per R9).

## 0. The defect, precisely

`return <ChoiceType>.<PayloadFreeAlternative>;` — and every other
consumption of an alternative constant by an initializing destination —
diagnoses `CopyOfUncopyableType` + `MissingImplInMemberAccessInContext`:

-   A payload-free alternative is a `let`-style constant member: a
    `WrapperBinding` whose bound value is a converted class VALUE
    (handle_choice.cpp `MakeLetBinding`, 293-341). Category: Value.
-   Value→initializing conversion is unconditionally a copy:
    convert.cpp `ConvertImpl`'s Value case (1929-1938,
    `target_.is_initializer()`) calls `PerformCopy` (1695-1705), which
    does a `Core.Copy` impl lookup and emits the two diagnostics on
    failure. Choices implement no `Core.Copy`, and
    `LookupCustomWitness`'s `CoreInterface::Copy` case answers nullopt
    (custom_witness.cpp 1152/1169-1171).
-   Affected shapes: `return C.Alt;` (return slot), `var x: C = C.Alt;`
    (the W5-S3b R-2 blocker), assignment `x = C.Alt;` (handle_operator
    `InfixOperatorEqual` → `InitializeExisting` → same path), and
    `return r;` for any choice-typed binding `r`.
-   Unaffected: `let x: C = C.Alt;` (value binding, no copy) and value
    params (`F(C.Alt)` — the param is a value binding). Payload
    alternatives are constructor CALLS, initializing from birth
    (`BuildAlternativeConstructor` writes the return slot in place) —
    which is exactly the W69b workaround shape (`MakeRuntime() ->
    P(i64).Both(1, 2)`, commit f2a7274) and the shape both landed
    choice conformance programs use.

## 1. V-3a: choice copyability — designed FOR, acknowledged gap. Lane (b)

-   **The design's canonical example IS the failing shape.**
    docs/design/sum_types.md (the fork's design authority for choices),
    "a value of an empty alternative like `None` is specified by naming
    it": `var my_opt: Optional(i32) = Optional(i32).None;` — var
    initialization from the constant. The landed arbiter
    fork/conformance/programs/control_flow/choice_generic_roundtrip_diff
    .carbon:14-24 records the deviation verbatim: "that line cannot
    compile in this fork … so the None value binds with `let`", and the
    doc's None-to-Some transition on the same variable "is not
    exercised (assigning `.None` is also a value copy through the same
    path)". A documented-limitation lane (c) would contradict the
    design doc directly — V-3 veto criterion; REJECTED.
-   **Copy management is design-open, not designed-against.**
    docs/design/values.md ("Initializing expressions"): "Value
    expressions are written directly into the storage to form a new
    object", and "**Future work:** The design should be expanded to
    fully cover how copying is managed". Nothing fences choices out of
    copyability; proposals/p000157's manual class emulation notes
    "Copy, move, assign, destroy, and similar operations need to be
    defined explicitly, but are omitted for brevity" — operations the
    `choice` shorthand is meant to provide, since sum_types.md says a
    `choice` cannot "define methods or other members for it".
-   **Upstream's toolchain names this exact gap as a TODO with a
    designed slot.** custom_witness.cpp `LookupCustomWitness` (upstream
    text, present at the graft root 643ab57): "TODO: Handle more
    interfaces, particularly copy, move, and conversion" — the
    `CoreInterface::Copy` case exists and returns nullopt.
    handle_choice.cpp:63-64: choices "ultimately turn into a class with
    methods and some builtin impls". And the sanctioned precedent:
    cpp/impl_lookup.cpp:165-169 synthesizes a Copy witness for C++
    enums by way of `BuildPrimitiveCopyWitness` (custom_witness.cpp 897-907)
    — "it's an enum (or eventually a C struct type). Perform a
    primitive copy." A choice is morally that: a trivially-copyable
    tag(+payload) type not authored as a class.
-   **Triviality is guaranteed today.** The SF-6 slice-1 fence rejects
    any payload "that is not trivially copyable and destructible"
    (SemanticsTodo, check/testdata/choice/fail_todo_nontrivial_payload
    .carbon) — every definable choice is memcpy-copyable. The B2a
    destroy work leaned on the same fence (CanDestroyClass's
    `is_choice` clause, custom_witness.cpp 196-198).
-   **Classes stay fenced.** Upstream is explicitly undecided on class
    copyability ("TODO: Decide on rules for when classes are copyable",
    check/testdata/var/fail_not_copyable.carbon) — the fix must key on
    `class_info.is_choice` and leak nothing to classes.
-   **Lane (a) rejected on altitude and coverage.** There is no
    sanctioned in-place materialization path for a class-typed constant
    VALUE: class constants reach storage either as literal-conversion
    `ClassInit` (initializing from birth — the constructor route) or
    through `PerformCopy`; tuple constants materialize elementwise and
    bottom out in the prelude's per-element Copy impls. Teaching
    convert.cpp to exempt choice constants would mint a new,
    choice-special conversion mechanism at the generic conversion layer
    (blast-radius risk the ledger flags), and would still leave
    `return r;`, assignment, and the doc's None-to-Some transition
    broken — fixing the symptom, not the item.

Verdict: lane (b), scoped to choices — implement the designed-for
custom Copy witness. ADOPTED (veto-able).

## 2. Mechanism: synthesize the Copy witness for choice types

Check side (custom_witness.cpp only):

1.  New `LookupChoiceCopyWitness(...)` mirroring `LookupDestroyWitness`
    (935-953): resolve the query self to a `ClassType` whose
    `class_info.is_choice` holds (non-choice → nullopt: classes,
    tuples, primitives keep today's behavior and the prelude impls);
    symbolic self → answer yes, defer witness building
    (`SemIR::InstId::None`), the same `query_self_const_id.is_symbolic()`
    posture as destroy's B2a choice clause (196-198) and justified by
    the same SF-6 fence (every instantiation's payloads are trivially
    copyable); concrete self →
    `BuildPrimitiveCopyWitness(context, loc_id, <Copy interface's
    scope_without_self_id, per BuildDestroyWitness 920-924>, ...)`.
2.  `LookupCustomWitness`: move `case SemIR::CoreInterface::Copy` out
    of the nullopt block to dispatch to it. Both call sites
    (impl_lookup.cpp 902 with build_witness=false, 1276 with true) are
    reached only after ordinary impl candidates fail — no landed
    lookup changes result.

Lower side (handle_call.cpp only): the `PrimitiveCopy` builtin arm
(339-341) today assumes a by-value return (`SetLocal(inst_id,
GetValue(arg_ids[0]))`) — correct for C++ enums and for payload-free
choices with copy value repr, wrong for pointer-rep choices (for example
`P(i64)`, InitRepr::InPlace per type_info.cpp 87-89) whose call carries
a return slot as the trailing arg. Extension: when the callee has a
return slot, `context.CopyValue(type, arg_ids[0], arg_ids[1])`
(function_context.cpp 496-514 — handles both Copy and Pointer reprs,
memcpy by way of `CopyObject`). Eval needs nothing: `PrimitiveCopy` already
constant-forwards (eval.cpp 2327-2329).

Upstream-merge posture: both files are already fork-hot (B2a). The
LookupCustomWitness TODO is the collision point — if upstream lands its
own copy synthesis, upstream wins at the weekly merge and this witness
re-derives against their shape (same yield rule as w069/w074), never
force-carried.

## 3. Probes (red-first — the defect is a clean diagnostic, so the pins land FIRST, green)

-   P-0 (red pins, first commit): new check/testdata/choice/
    fail_alternative_copy.carbon pinning today's diagnostics on all
    three shapes — `return C.Alt;`, `var x: C = C.Alt;`, `x = C.Alt;`
    — for a payload-free choice AND for a payload-carrying choice's
    payload-free alternative (`P(i64).Neither`, the W69b fill shape).
    Boundary subfile, stays green throughout: `let` binding and
    value-param argument passing of the same constants.
-   P-1 (the flip): with the fix, P-0's fail subfiles become positive
    goldens (renamed per convention) pinning the `Copy.Op` call shape;
    a generic subfile pins the symbolic-self deferral (a generic
    `fn Make(T:! type) -> Opt(T) { return Opt(T).None; }` plus a
    concrete instantiation).
-   P-2 (designed tripwire fires): check/testdata/operators/
    fail_question.carbon's fail_return_choice_binding subfile
    (`return r;`) says in its own header "If this ever compiles,
    choices gained copyability and §2.6 needs re-derivation" — it flips
    to a positive pin (relocated per convention), and the §2.6-derived
    records retext: docs/design/error_handling.md:344-350 ("because
    choices have no `Core.Copy` impl") gets a dated amendment (the
    match-reconstruct Branch bodies STAY — rewriting prelude Try impls
    is not W75a scope; only the stated reason is updated).
-   P-3 (lower): lower/testdata/choice subfiles for both reprs —
    copy-rep return (by-value `PrimitiveCopy`) and pointer-rep
    `P(i64).Neither` return (slot memcpy by way of CopyValue).
-   Negative pins: every class/tuple Copy golden byte-identical —
    var/fail_not_copyable, generic/fail_generic_copy, adapter/abstract/
    interop copy goldens; lower/testdata/let/import_choice.carbon's
    runtime-bound-vs-constant predicate subjects unchanged (MakeRuntime
    stays a constructor call ON PURPOSE — its job is a non-folding
    initializer, not a copy dodge).
-   Retexts made true by the fix (comment-only): the W69b workaround
    records in fork/conformance/programs/types/choice_generic_diff
    .carbon:35-37 and error_handling/control_flow_constructs.carbon:20;
    work-items.json W-075 disposition; decision-log entry.

## 4. One slice: W75a

1.  P-0 red pins land first (green — diagnostics are goldenable).
2.  custom_witness.cpp witness (§2) + handle_call.cpp arm; flip P-0 →
    P-1/P-2/P-3; autoupdate to fixpoint (R26); all untouched goldens
    byte-identical.
3.  Conformance (ADOPTED, veto-able): restore the DOC-VERBATIM shape in
    control_flow/choice_generic_roundtrip_diff.carbon — `var my_opt:
    Optional(i32) = Optional(i32).None;` and the deliberately-dodged
    None-to-Some(-to-None) transition on the same variable, mirrored in
    the std::optional oracle (`.reset()`), churn declared. This is the
    honest arbitration: the program exists precisely to arbitrate
    sum_types.md's example, and the fix removes its recorded deviation.
    No new program; **expected floor: exactly 96/0/28 over 124** (the
    pair stays one PASS, coverage deepened; comment retexts move no
    status).
4.  Records: W-075 disposition, w069 plan blocker-1 back-reference,
    decision-log, ORCHESTRATION.

Discharge criteria (R9-aligned): P-1/P-2/P-3 pin the fixed shapes for
both reprs; the roundtrip arbiter runs the doc's lines verbatim against
the C++ oracle; class-copy negative pins byte-stable; floor exactly
96/0/28 over 124; the toolchain diff is the two files in §2 only.

## 5. Risks

-   **R-1 conversion-layer blast radius: structurally zero** —
    convert.cpp is untouched; narrowing lives in the witness predicate
    (`is_choice`), so only previously-FAILING Copy lookups change.
-   **R-2 generic-bounds widening (declared consequence):** choices now
    satisfy `T: Copy` bounds (for example iterate.carbon's `let ElementType:
    Copy & Destroy;`) — design-consistent, but a semantic widening; the
    P-1 generic subfile pins it deliberately.
-   **R-3 SF-6 coupling (W-071-style revisit):** the triviality
    argument (concrete and symbolic) is valid exactly while the
    nontrivial-payload fence holds. When SF-6 widens, the witness needs
    a real per-payload Copy walk — record rides the same ledger note as
    destroy's.
-   **R-4 pointer-rep lowering:** the CopyValue arm is the only new
    lowering; falsifier is P-3's pointer-rep golden (a wrong arm
    can't hide — the by-value fallback would miscompile the slot shape
    visibly).
-   **R-5 upstream collision:** the custom-witness TODO is upstream's
    natural landing spot for their own copy work — weekly-merge yield
    rule (§2), never force-carry.
-   **R-6 W-069 interaction: none.** Promotion is lowering-side for
    package-scope runtime lets; this is check-side witness synthesis.
    Noted so the S-items stay disentangled (w074 §6 R-4 mirror).

## 6. Open questions for the coordinator

None blocking. Adopt-unless-vetoed calls restated: (i) lane (b),
choice-only, symbolic-deferral mirroring destroy; (ii) the roundtrip
arbiter's doc-verbatim restoration with declared churn (floor exactly
96/0/28); (iii) P-2's error_handling.md §2.6 retext WITHOUT rewriting
the prelude Try impls (their simplification is future material, not
W75a). One genuine fork: if the coordinator reads upstream's class-copy
indecision as fencing ALL synthesized Copy, the fallback is lane (c)
with the roundtrip arbiter's deviation record promoted to a permanent
documented limitation — the §1 evidence argues against, but the call is
theirs.

## Coordinator adjudication (2026-08-18, pre-review)

The one genuine fork (§: whether upstream's class-copy indecision fences
ALL synthesized Copy) is adjudicated in the plan's favor: **lane (b)
ADOPTED**, choice-only. Grounds: the design's own canonical example
requires the shape; upstream's enum Copy synthesis
(BuildPrimitiveCopyWitness by way of cpp/impl_lookup.cpp) proves per-kind
witness synthesis is a sanctioned pattern; the `is_choice` gate plus the
SF-6 triviality fence leaves the class-copy question exactly where
upstream left it. The three adopt-unless-vetoed calls stand as written.
All veto-able by way of the PR digest. One plan review next; on fold +
sign-off, W75a proceeds.

## Review-round amendments + sign-off (2026-08-18, coordinator)

One adversarial plan review: **APPROVE with amendments** — the V-3a
chain verified verbatim end-to-end (incl. the counter-evidence sweep:
nothing fences choices from copyability; the Copy TODO's designed slot
IS toolchain-side synthesis; prelude Copy is already toolchain-managed
per-kind). Folded:

1.  **SF-1 (factual correction, binding):** §2's dispatch-order sentence
    was FALSE — the custom-witness dispatch PRECEDES candidate-impl
    iteration at both sites (impl_lookup.cpp:1286 "Only consider
    candidates when a custom witness didn't apply"); "no landed lookup
    changes" holds only because no landed test declares a Copy impl
    candidate for a choice (all landed user Core.Copy impls are on
    classes, gated out by `is_choice`). DECLARED CONSEQUENCE, digest-
    grade: a user out-of-line `impl <choice> as Core.Copy` (sanctioned
    by sum_types.md:95-98) is SHADOWED by the synthesized witness —
    the same posture Destroy already has for choices. W75a adds a probe
    subfile pinning the shadowing.
2.  **SF-2 (contract record):** the synthesized witness bypasses
    source-builtin validation by way of SetCoreWitness, and the new lower arm
    widens PrimitiveCopy's de-facto contract past its own
    PrimitiveCopyable validator (builtin_function_kind.cpp:243-249) —
    named here as the seam an upstream merge could tighten; the R-5
    yield rule covers it.
3.  Nits folded: the lower arm carries the trailing
    `SetLocal(inst_id, GetValue(arg_ids[1]))` per the
    CppStdInitializerListMake precedent; §5 names the
    symbolic→monomorphization BuildPrimitiveCopyWitness link as the
    least-exercised path (P-1 pins it); "R16a" reads R16 clause (a);
    the error_handling.md clause is :343-349; the parent-scope choice
    (interface scope, diverging from the enum precedent's GetClassScope)
    is a mangling-hint choice, stated.

**This plan is APPROVED for implementation** (one slice, W75a). Digest
carries: lane (b) adoption; the shadowing consequence; the contract
widening; the tripwire flip; the roundtrip restoration. Veto-able.
