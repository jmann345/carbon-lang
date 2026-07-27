<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W5 implementation plan: payload-carrying `choice` types

Status: PLAN (process step 6, scaled loop). Author context: fork/process.md +
fork/rulebook.md loaded; design authority docs/design/sum_types.md and the
**normative F-007k storage contract** in docs/design/unions.md
["Relationship to choice types"](/docs/design/unions.md#relationship-to-choice-types)
(unions.md:516-562, decision-log F-007k). Work items:
fork/inventory/work-items.json **W-010** (choice payloads,
handle_choice.cpp:158-162 TODO) and **W-011** (match destructuring +
std::variant/std::optional interop). Precedent format: fork/trial-w4/plan.md +
retrospective.md. NO implementation in this document — planning only.

---

## 0. Target design

### 0.1 Language surface (docs/design/sum_types.md)

```carbon
choice IntResult {
  Ok(value: i32),
  Err
}

var r: IntResult = IntResult.Ok(42);   // function-like construction
r = IntResult.Err;                     // constant, as today

match (r) {
  case .Ok(value: i32) => { Core.Print(value); }
  case .Err => { Core.Print(-1); }
}
```

-   Payload alternatives are **function-like**: constructed by "calling" them
    (`sum_types.md:69-76`); payload-free alternatives stay constants
    (WrapperBinding members — naming, not calling, per sum_types.md:69-76 and
    the constant-vs-factory pattern rule at sum_types.md:233-241). The
    _surface_ is "as today", but the constant's **value synthesis is not**:
    once the choice carries any payload, the constant must cover the new
    `.payload` field — planned explicitly in §2.2 step (b), on S1's critical
    path (`IntResult.Err` is the arbiter's second arm).
-   Patterns mirror construction: `.Name(bindings...)` for payload
    alternatives, `.Name` for constants (`sum_types.md:78-89`, and the
    factory/pattern symmetry rule at sum_types.md:220-241).
-   Generic choices (`Optional(T: type) { Some(value: T), None }`) are part of
    the design; **the fork's eventual `Core.Result(T, E)` uses `Ok(T)` /
    `Err(E)` naming per decision F-006a** — every example, prelude line, and
    conformance program in this workstream uses that spelling, never
    Success/Failure.

### 0.2 Storage (the F-007k contract, normative)

Per unions.md:521-526: *"The storage of a payload-carrying choice type is a
discriminant together with union storage for the payloads: all payload
tuples overlap at a common offset, in storage sized and aligned by the same
max-of-fields rule specified in Layout, using the same explicit-layout
object representation. choice lowering must build on this machinery rather
than a private overlapping-storage mechanism."*

Concretely (recommended repr — sub-fork SF-1, §5):

-   Object repr becomes `StructType { .discriminant: UInt(N), .payload:
    CustomLayoutType }` where the `CustomLayoutType` (sem_ir/typed_insts.h:617-627)
    carries one field per payload-carrying alternative — that alternative's
    payload tuple type — **all at offset 0**, with size/align = max over
    payload tuples (the unions.md Layout rule). Payload-free choices keep
    today's exact `{.discriminant}` repr (the degenerate case of the
    contract): zero golden churn for existing choices, and the by-copy value
    repr of single-field structs (type_completion.cpp:570-576) is preserved.
-   The contract operates at the compiler layout level; source-level union
    field rules do **not** constrain choice payloads (unions.md:543-554). 0.1
    slices below nevertheless _restrict_ payloads to trivially copyable +
    destructible types with a clean diagnostic — a scoped deviation, recorded
    as a work item and sub-fork SF-6, never a silent acceptance.
-   Lowering: `CustomLayoutType` already lowers to `[size x i8]` with
    byte-offset GEP field access (lower/type.cpp:633-640,
    lower/aggregate.cpp:25-39) — no new lowering mechanism, exactly as the
    contract demands.

### 0.3 What W5 match consumption is — and is NOT

0.1 choice-match is **direct discriminant dispatch**: read `.discriminant`,
compare against alternative indices, branch, extract payload by way of
element access on the overlapping storage. The `Match`
interface/Continuation mechanism in sum_types.md:124-246 is the
_user-defined sum type_ generality and is **explicitly out of scope for the
whole workstream** (see risk R-8 and the decision-log scope entry this plan
requires at landing). An implementer following sum_types.md into generated
Continuation impls has left the slice.

### 0.4 Honesty about observability (why slice 1 is shaped as it is)

**Construction alone has no runtime-observable behavior.** A constructed
choice value exposes: no discriminant accessor, no `==` impl, no field
access (the repr is compiler-internal), no C++ interop mapping (that is
slice 4), and no byte-reinterpretation path in safe code. A
"construction-only" conformance program could only assert "compiles and
exits 0" — vacuous by adversary #1's standard. Therefore **slice 1 must
include a minimal match-consumption path**, and the honest minimum is
_payload-free alternative patterns over a choice scrutinee_ (`case .Err`),
which observes at runtime that the payload constructor wrote the correct
discriminant — without touching the deep end of match (the case-arm
binding-pattern context, handle_binding_pattern.cpp:451-452
CARBON_FATAL), which is deferred to slice 2 where payload _values_ become
observable.

What that minimal match path genuinely requires (no shortcuts exist):

1.  Widening the `MatchCondition` integer-scrutinee gate
    (handle_match.cpp:59-74) to admit choice-typed scrutinees — which
    requires re-deriving the temporary-cleanup soundness argument that the
    integer gate currently guarantees (W4 plan §9 risk 4). Slice 1's payload
    restriction (trivially copyable/destructible) keeps choice values
    destroy-free, preserving the argument; the gate widens to "integers +
    choice types whose payloads are all trivial", not to classes generally.
2.  Widening the `MatchCaseIntroducer` lookahead gate
    (handle_match.cpp:107-115) to also accept the alternative-pattern node
    shape.
3.  Resolving `.Err` in case-pattern position against the _scrutinee type_.
    Today `.Err` parses as `DesignatorExpr` (parse/handle_expr.cpp:208-243)
    whose check handler demands `.Self` in scope
    (check/handle_name.cpp:191-225). Slice 1 gives match case arms a
    designator resolution context keyed to the scrutinee type — check-side
    only; the parse tree for `.Err` already exists.
4.  Emitting discriminant compare: `class_element_access` of
    `.discriminant` on the scrutinee ref expr, then the same
    `BuildBinaryOperator` EqWith chain W4's H9 uses, against the
    alternative-index literal converted to `UInt(N)`. No new inst kinds.

What slice 1 explicitly does NOT need: the new `FullPatternStack` case-arm
context, refutable binding semantics, payload extraction, or any parse
changes (`.Name` with no parens is already a well-formed pattern-position
parse). `case .Ok(value: i32)` does not even parse today
(parse/handle_pattern.cpp:43-55 routes it to ExprPattern where a binding is
not an expression) — that parse work is slice 2's, and slice 1 gates
payload-alternative patterns with a TODO diagnostic.

---

## 1. Slice decomposition

Four slices, each independently landable through the full loop
(implementer → 2 adversarial reviewers → fixer → merge gate, R11) with a
runnable conformance arbiter and a differential pair.

| # | Name | Size | Runtime-observable arbiter |
| --- | --- | --- | --- |
| S1 | Payload construction + F-007k storage + discriminant-observable match | L | `IntResult.Ok(42)` / `IntResult.Err` constructed at runtime; `match` with `case .Err` + `default` prints different values per alternative — observes the payload constructor writes the correct discriminant. Differential pair vs C++ `std::variant<...>::index()`. Lower golden pins overlapping layout (size/align/offsets). |
| S2 | Payload destructuring: `case .Ok(value: i32)` binding patterns | L (XL risk) | Payload value round-trips: construct with runtime-computed argument, extract by way of match binding, print it. Differential pair vs C++ `std::variant` + `std::get_if`. Exhaustive alternative coverage replaces `default` (per SF-7 outcome). |
| S3 | Generic payload choices + `Core.Result(T, E)` / `Core.Optional(T)` prelude types | M | `Optional(i32).Some(7)`, `Result(i32, i32)` with `Ok`/`Err` (F-006a) construct and destructure through generic instantiation at runtime. Differential pair vs C++ class templates over `std::variant`. Unblocks F-006 B1. |
| S4 | Transparent `std::optional` / `std::variant` interop mapping | L | A Carbon `match` over a value returned by imported C++ (`std::optional<int>`, `std::variant<int, double>`) prints the payload; inherently differential (C++ side is the oracle per DIFF-1). Un-SKIPs `control_flow/match_sum_type_payload.carbon` (post-S2-split: interop half only — see §3.3/§4). |

Dependency chain: S1 → S2 → S3 → S4 (each consumes the previous slice's
machinery; S4 additionally rides check/cpp/custom_type_mapping.cpp).

Sizing note (post-review): S1 stays L, re-checked after the R11 review
round surfaced two previously unplanned S1 pieces — payload-free
alternative constants (§2.2b) and choice-ness/index metadata (§2.2c).
Both resolved to existing machinery (`UninitializedValue` + a
one-bool `Class` flag), so they add scope, not mechanism; R-14 and the
§6 trigger guard the residual risk of that resolution being wrong.

Inventory mapping: S1+S2+S3 discharge W-010 and the choice half of W-011;
S4 discharges the interop half of W-011. W-010 is inventoried as
`blocked_by: [W-008, W-009]`; W-008 (match slice 1) is landed. **W-009
(native unions) is NOT landed** — see risk R-3 for the coordination rule:
W5 does not wait; whichever workstream lands first builds the two shared
pieces (custom-layout initialization, native custom-layout destroy/copy
witness cases), and the inventory edge is updated to reflect
"shared-machinery coordination", not a hard block.

---

## 2. Slice 1 — construction + storage + discriminant-observable match

### 2.1 In-slice behavior

-   `choice C { Ok(value: i32), Err }` with **concrete** (non-generic,
    non-`Self`-referential) payload types that are trivially copyable and
    trivially destructible. Multi-parameter payloads (`Pair(a: i32, b: f64)`)
    in-slice; they form the alternative's payload tuple.
-   Construction: `C.Ok(42)` as a call expression; `C.Err` unchanged.
-   Match: choice-typed scrutinee admitted; `case .Err` (payload-free
    alternative pattern, leading-dot form only per SF-4) + `default` arm;
    `default` still required (exhaustiveness arrives in S2 per SF-7).
-   Layout per §0.2; existing payload-free choices bit-identical to today.

Gated out with clean `semantics TODO` diagnostics (contract strings, R10):

| Input | Where caught | Diagnostic (exact contract text) |
| --- | --- | --- |
| generic/`Self`-dependent payload type | AddChoiceAlternative | `semantics TODO: choice alternative payload with generic or Self-dependent type` |
| non-trivially-copyable/destructible payload | choice type completion | `semantics TODO: choice alternative payload that is not trivially copyable and destructible` |
| payload-alternative pattern `.Ok(...)` or `.Ok` in `case` | MatchCaseIntroducer lookahead | `semantics TODO: match case pattern destructuring a choice payload` |
| qualified pattern `C.Err` in `case` | MatchCaseIntroducer lookahead | `semantics TODO: qualified alternative pattern in match case` |
| choice scrutinee with non-trivial payload (defensive; unreachable while completion gate holds) | MatchCondition | existing `match on non-integer scrutinee` text widens to `semantics TODO: match on unsupported scrutinee type` |
| `Alt()` empty parens | per SF-3 outcome | today's TODO retained until SF-3 decided |

The S1 fix for the **silent-drop hazard**: today a rejected payload
alternative vanishes from the class scope (handle_choice.cpp:158-162 early
return), so later references get confusing member-not-found errors after
the TODO. Any alternative S1 still rejects (generic payloads) must be
pushed into the scope as an error binding (ErrorInst type) so later
references diagnose against the TODO, not against a phantom missing member.

### 2.2 Check-side shape (handle_choice.cpp)

-   `AddChoiceAlternative`: instead of the :158-162 rejection, queue the
    NameComponent _with_ its param patterns (already fully pattern-checked —
    NameComponent carries param_patterns_id/call_params_id/pattern_block_id,
    name_component.h:27-46) into `choice_deferred_bindings()`.
-   At `ChoiceDefinitionId`, **(a) payload alternatives**: synthesize a
    member **function** named for the alternative, returning `Self`, whose
    body: (1) materializes `Self` storage, (2) stores the alternative index
    into `.discriminant` (class_element_access + init, exactly the existing
    MakeLetBinding conversion machinery re-targeted), (3) stores the call
    parameters into the alternative's payload-tuple field of the `.payload`
    custom-layout region (class_element_access on the CustomLayoutType —
    reads already work by way of convert.cpp:551-559; **writes/init are the new
    code**: the struct-literal→custom-layout bailout at convert.cpp:882-885
    is exactly the unwired piece, and S1 wires the narrow
    "known-single-field, known-alternative" init path, not general
    designated-init — that generality stays with W-009).
-   **(b) Payload-free alternative constants of payload-carrying choices**
    (`IntResult.Err` — on S1's arbiter critical path). Today's MakeLetBinding
    path (handle_choice.cpp:186-235) builds a StructLiteral containing ONLY
    the discriminant and converts by way of ConvertStructToClass; that dies once
    the repr grows a `.payload` field, because ConvertStructToStructOrClass
    requires the source to supply (or a FieldDecl initializer to default)
    every dest field (convert.cpp:736-744, :901-936) and choice reprs have
    no FieldDecls. **The fix uses only existing machinery** — the exact
    precedent is the partial-class vptr fill: ConvertStructToStructOrClass
    already special-cases a compiler-known dest field the source never
    supplies, filling it with `SemIR::UninitializedValue`
    (convert.cpp:702-733, esp. :721-727). S1's MakeLetBinding builds the
    self-struct literal as `{discriminant value, UninitializedValue(payload
    CustomLayoutType)}` (or equivalently teaches the conversion to fill the
    known `.payload` field the same way the vptr case does). The whole chain
    pre-exists: `UninitializedValue` is `InstConstantKind::Always`
    (typed_insts.h:2211-2219), so the alternative constant evals to a
    StructValue whose payload element is an UninitializedValue constant, and
    lowering already emits that as `llvm::PoisonValue` of the `[size x i8]`
    region (lower/constant.cpp:351-354) inside the ordinary StructValue
    constant emitter (constant.cpp:174-179, PadToType trivially satisfied) —
    **no new inst kinds, no lower/ source change**. Two honesty notes:
    (1) this chain is confirmed-by-inspection, not executed — the sole
    in-tree UninitializedValue producer is the vptr path, and no existing
    constant nests one inside a StructValue; the S1 lower golden
    `payload_construct.carbon` must include an `Err`-style constant
    precisely to execute it (risk R-14). (2) Turning `Err` into a
    synthesized function instead was considered and is REJECTED: it breaks
    the design surface (`r = IntResult.Err;` names, never calls,
    sum_types.md:69-76) and flips the observable pattern spelling
    (`case .Err()` vs `.Err`, sum_types.md:233-241). Payload-free CHOICES
    (no payload field at all) keep today's constants bit-for-bit — the
    zero-golden-churn claim in §0.2 is unaffected.
-   **(c) Choice-ness + alternative-index metadata.** SemIR has no way to
    ask "is this ClassType a choice?" (`toolchain/sem_ir/class.h`: zero
    mentions of choice; alternatives are plain WrapperBinding scope entries
    with the index baked into the constant, handle_choice.cpp:221-234), and
    §2.3's H3/H9 need exactly that plus name→index. S1 adds **one bool
    `is_choice` to `SemIR::Class`**, set where `ChoiceDefinitionStart`
    creates the class, copied at import like the existing `is_dynamic` /
    `fields_exported` flags (class.h:47-50; import copy site
    import_ref.cpp:~2016) — precedented, one-flag entity churn, NOT
    inferred from the `NameId::ChoiceDiscriminant` repr field (a syntactic
    test R-4's discipline forbids; the flag is entity truth). Name→index
    for S1's payload-free arms comes from the alternative's **bound
    value** constant, not the WrapperBinding's own constant. AMENDED
    post-CI (autoupdate run 30251025460): a WrapperBinding over a
    value-category bound value is never constant — EvalConstantInst
    forwards constants only for ref-category bounds (eval_inst.cpp:118-126)
    — and a non-constant binding imports as ConstantId::NotConstant
    (import_ref.cpp:4401-4408), so this section's original "constant
    imports with the binding (LoadImportRef + canonical constants)"
    premise was wrong on both counts and CHECK-crashed the first real run.
    The implemented mechanism resolves the binding to its defining file
    (SemIR::GetCanonicalFileAndInstId) and reads the bound value's
    concrete StructValue discriminant element there (handle_match.cpp
    GetAlternativeDiscriminant). S2's payload patterns need richer per-alternative
    metadata (payload tuple type, payload field index); that shape
    (an alternatives side-table on Class, a la fields) is planned in §3.2.
    The §2.4 sem_ir line and §6 are updated accordingly; a cross-file
    testdata program pins the imported-choice match path.
-   Object repr: extend the :248-289 computation — collect payload tuple
    types, compute max size/align by way of the same completion-time queries the
    C++ import layout path uses, build the CustomLayoutId block
    ([size, align, offsets...] per sem_ir/ids.h:885-904) with every payload
    field at offset 0 inside the payload region.
-   Discriminant scheme unchanged: `UInt(ceil(log2(n)))`, `()` for 0/1
    alternatives — pending SF-2 ratification. A single-alternative choice
    _with_ a payload gets repr `{ .payload: CustomLayoutType }` (zero-bit
    discriminant elided as today) — called out for adversarial review.
-   Destroy witness: add the `CustomLayoutType` case to
    `CanDestroyType`/`MakeDestroyOpBody` (custom_witness.cpp:311-312 /
    :339-340 CARBON_FATAL today — risk R-5): with S1's trivial-payload gate,
    the case is "all fields trivially destructible → NoOp", mirroring the
    struct/tuple recursion at custom_witness.cpp:262-298.

### 2.3 Check-side shape (handle_match.cpp)

-   H3 `MatchCondition`: widen the gate — accept `TryGetIntTypeInfo`
    successes as today, **plus** class types with `Class::is_choice` set
    (§2.2c metadata; all of whose payloads passed the trivial gate at
    completion). Scrutinee becomes a
    value/ref expr; `AddAndDiscardTemporaryCleanups` stays sound because
    in-slice choice values are trivially destructible (re-derived cleanup
    argument; reviewers must attack this — risk R-4).
-   H5 `MatchCaseIntroducer`: extend the lookahead — accept the existing
    single-IntLiteral shape, and the single-DesignatorExpr shape
    (`DesignatorExprId` node + name, then MatchCase) **when the scrutinee is
    a choice**; everything else keeps/gets the TODO strings of §2.1.
-   H9 `MatchCase` (choice path): resolve the designator name in the
    scrutinee choice's class scope (by way of LoadImportRef so imported choices
    work — the cross-file case has its own testdata program, §2.4); if it
    names a payload-free alternative, extract the alternative's index from
    the WrapperBinding constant's discriminant element (§2.2c), emit
    `class_element_access .discriminant` on the scrutinee + EqWith
    compare against that index literal (converted to
    `UInt(N)`), then the identical branch discipline as the integer path. If
    it names a payload alternative → §2.1 TODO. Testdata note: `UInt(N)`
    EqWith requires the real prelude or `min_prelude/uint.carbon` includes,
    as the existing choice testdata already does.

### 2.4 Files touched (S1)

-   `toolchain/check/handle_choice.cpp` — alternative synthesis, repr
    computation (bulk of the slice).
-   `toolchain/check/handle_match.cpp` — H3/H5/H9 widening per §2.3.
-   `toolchain/check/convert.cpp` — narrow custom-layout init path
    (convert.cpp:882-885 vicinity).
-   `toolchain/check/custom_witness.cpp` — CustomLayoutType destroy cases.
-   `toolchain/check/handle_name.cpp` or a new small helper — designator
    resolution against a match scrutinee type (check-only; no parse change).
-   `toolchain/sem_ir/class.h` + `toolchain/check/import_ref.cpp` — the one
    `Class::is_choice` bool and its import copy (§2.2c). **No new inst
    kinds planned** (§6); possible inst_namer cosmetic labels besides.
-   `toolchain/lower/` — **no source changes planned**: CustomLayoutType,
    byte-offset GEP, struct constants, and the UninitializedValue→poison
    constant path (§2.2b, lower/constant.cpp:351-354) all pre-exist. The
    lower testdata golden is the executable proof of this claim — including
    an `Err`-style constant of a payload-carrying choice (risk R-14).
-   Testdata (all AUTOUPDATE, empty CHECK lines, runner-side reconcile —
    §7): `toolchain/check/testdata/choice/params.carbon` (**four** fail_todo
    splits flip — grep-verified: `fail_todo_empty_params` → SF-3 outcome,
    `fail_todo_params` → success, `fail_todo_generic_params` and
    `fail_todo_self_param` → the new generic/Self-dependent TODO string),
    new `toolchain/check/testdata/choice/payload_construct.carbon`,
    `payload_layout.carbon` (multi-payload max-size/align shapes),
    `fail_todo_generic_payload.carbon`, `fail_todo_nontrivial_payload.carbon`,
    new `toolchain/check/testdata/match/choice_scrutinee.carbon`,
    `choice_scrutinee_imported.carbon` (multi-file: choice declared in one
    library, matched in another — pins the §2.2c/§2.3 import path),
    `fail_todo_choice_payload_pattern.carbon`; new
    `toolchain/lower/testdata/choice/payload_layout.carbon` — **the F-007k
    arbiter golden**: must show the `[size x i8]` payload region with
    max-of-payloads size and the byte-offset GEPs (anti-Goodhart guard, risk
    R-6).
-   Conformance: new `types/choice_payload_construct.carbon` (un-SKIPped at
    S1 landing: construct `Ok(42)`/`Err`, match on `.Err` vs `default`,
    EXPECT exact prints) + differential pair
    `types/choice_discriminant_diff.carbon` / `.diff.cpp` (C++ oracle:
    `std::variant<int, std::monostate>` probed by way of `index()`, printf
    mirroring Core.Print; DIFF conventions per
    control_flow/match_switch_diff.*). `types/choice_basic.carbon` must stay
    green untouched (R16b). Update SKIP evidence in
    `control_flow/match_sum_type_payload.carbon` to the new exact TODO
    strings (R10). `runner.py --self-test` before commit (R7); private
    `--out` (R5); update work-items.json W-010 state.

---

## 3. Slice 2 — payload destructuring in match

### 3.1 In-slice behavior

`case .Ok(value: i32) => { ... }` binds the payload; multi-param
alternatives bind positionally-by-declaration (`case .Pair(a: i32, b:
f64)`); binding spelling per SF-5 outcome. Exhaustiveness per SF-7 outcome
(recommended: a match over a choice listing every alternative needs no
`default`, which is what makes the sum_types.md:80-89 example and the
`match_sum_type_payload` sketch compile). Guards on alternative patterns
remain out (existing W4 guard TODO). Duplicate-alternative usefulness
diagnostics join W-066's deferral (recorded, not silent).

### 3.2 The three hard parts (be honest — this is the XL-risk slice)

1.  **Parse**: `case .Ok(value: i32)` has no parse today —
    parse/handle_pattern.cpp:43-55 sends leading-`.` down ExprPattern where
    `value: i32` is not an expression. S2 adds an alternative-pattern parse
    form: on `.`+identifier(+`(`) in pattern position, parse designator then
    a paren _pattern_ list (reusing the existing TuplePattern/paren-pattern
    states). New parse node kind(s) (for example `AlternativePattern`,
    `AlternativePatternStart`) → typed_nodes.h, node kind tables, parse
    goldens, and check node_stack.h kind-table entries (consteval-checked).
    Parse-only changes, no lexer work. This is the workstream's only parse
    surface — W4 was check-only; the reviewers' brief must include parse
    golden churn.
2.  **Check pattern context**: case-arm bindings currently CARBON_FATAL
    (`handle_binding_pattern.cpp:451-452`,
    FullPatternStack::Kind::NotInEitherParamList). S2 introduces a case-arm
    pattern context: FullPatternStack pushed at MatchCaseIntroducer, binding
    patterns allowed with the scrutinee (not a call param) as the match
    source, bindings materialized into the arm's then-block scope
    (MatchHandlerStart's scope, W4 H12) by way of the existing BindName machinery,
    initialized from `class_element_access` payload extraction +
    tuple-element access. By-value copy of trivially-copyable payloads only
    (S1 gate), so no destroy/cleanup novelty. Declared binding type must
    ImplicitAs-match the alternative's declared payload type (design:
    pattern reproduces the parameter list, sum_types.md:220-231). Payload
    patterns need per-alternative metadata beyond §2.2c's flag — payload
    tuple type + payload field index, keyed by name: S2 adds an
    alternatives side-table on `SemIR::Class` (shape modeled on the
    existing fields store), imported alongside the class.
3.  **Exhaustiveness (the SF-7(a) outcome is machinery, not a flag flip)**:
    "all alternatives covered ⇒ no `default`" needs, in the match
    completion handler (W4's H14 vicinity, handle_match.cpp): a
    covered-alternative set accumulated across choice-pattern arms (bitset
    over alternative indices — the full set's size comes from the §3.2.2
    alternatives table), a missing-alternative error naming the uncovered
    alternatives when the match ends with neither `default` nor full
    coverage, and the default-arm rule inverted for fully-covered choice
    matches. Its own fail goldens (`fail_choice_nonexhaustive.carbon`,
    missing-one / missing-several / default-plus-full-coverage shapes) ride
    §3.3's testdata list. Small relative to parts 1-2, but it is real new
    check logic and is budgeted, not discovered.

### 3.3 Files touched (S2)

-   `toolchain/parse/handle_pattern.cpp`, `toolchain/parse/typed_nodes.h`,
    `toolchain/parse/node_kind.def` (+ state.def if a new state) — the
    alternative-pattern form; new parse goldens
    `toolchain/parse/testdata/match/alternative_pattern.carbon` + fail cases.
-   `toolchain/check/node_stack.h` — new kinds categorized.
-   `toolchain/check/handle_match.cpp` — H5 accepts the new shape; H9 splits
    discriminant test from payload-binding emission; match-completion
    handler grows the §3.2.3 exhaustiveness tracking + diagnostic.
-   `toolchain/sem_ir/class.h` + `toolchain/check/import_ref.cpp` — the
    §3.2.2 alternatives side-table and its import.
-   `toolchain/check/handle_binding_pattern.cpp` /
    `toolchain/check/full_pattern_stack.h` (or equivalent) — the case-arm
    pattern context.
-   Testdata: new `toolchain/check/testdata/match/choice_payload_binding.carbon`,
    `choice_exhaustive.carbon`, `fail_choice_nonexhaustive.carbon` (§3.2.3
    shapes), fail cases (wrong binding type, wrong arity,
    unknown alternative, duplicate alternative accepted-with-work-item);
    `toolchain/lower/testdata/match/choice_payload.carbon` (payload GEP +
    branch chain).
-   Conformance: new `control_flow/choice_payload_roundtrip_diff.carbon` /
    `.diff.cpp` — Carbon choice construct+match-bind vs C++
    `std::variant<int,...>` + `std::get_if`, runtime-computed payload values
    so constants can't fake it (R16d). Scope-trade recommendation (W4-S1
    precedent, needs its own decision-log entry at landing): split
    `control_flow/match_sum_type_payload.carbon` — its choice-only half
    moves to a new program un-SKIPped at S2; the program itself keeps its
    interop half and stays SKIP citing S4's exact blockers.

---

## 4. Slices 3 and 4 (outline depth — re-planned in detail after S2's retrospective)

### S3 — generic payload choices + prelude `Result`/`Optional`

Lifts S1's generic-payload TODO: payload types mentioning choice type
parameters (`Some(value: T)`). The repr/CustomLayoutId computation moves
to (or is re-run at) specialization completion — layout depends on the
substituted `T`; this is the slice's core difficulty and must reuse the
generic class completion path, not clone it. Then `core/prelude/`:
`Core.Result(T, E)` with alternatives **`Ok(T)` / `Err(E)`** and
`Core.Optional(T)` with `Some(T)` / `None` (F-006a spelling). What
becomes of the EXISTING `Core.Optional` — today a class with a
pointer-niche layout and passing conformance programs — is sub-fork
**SF-9**, which must be decided before S3's detailed plan is written.
Files: handle_choice.cpp,
check/type_completion.cpp vicinity, core/prelude/*, testdata
choice/generic_payload.carbon (+lower), conformance
`types/choice_generic_result_diff.carbon` / `.diff.cpp` (C++ oracle: class
template over `std::variant<T, E>`). Unblocks F-006 B1 (Result + match).

### S4 — `std::optional` / `std::variant` transparent mapping

Rides check/cpp/custom_type_mapping.cpp (the std::string_view matcher at
:92-104 is the extension mechanism per W-011 notes): map
`std::optional<T>` → `Core.Optional(T)` and `std::variant<Ts...>` → a
choice-shaped mapping (exact target is sub-fork SF-8). Layout cannot be
assumed identical (libc++'s optional/variant layout is not Carbon's choice
layout) — the mapping is by-value conversion at the boundary, not a
reinterpret; the differential arbiter (C++ oracle per DIFF-1) is what
keeps this honest. Un-SKIPs `control_flow/match_sum_type_payload.carbon` —
which, per the §3.3 split, by S4 contains only the `Cpp.MaybeSeven`
interop half (its Carbon-choice half moved to a new program already
un-SKIPped at S2); one consistent end-state for R10 SKIP bookkeeping:
choice half green at S2, interop half green at S4. Files:
check/cpp/custom_type_mapping.cpp + import glue, conformance interop
programs both directions where exportable.

---

## 5. OPEN sub-forks (user decisions — marked, recommended, never decided here)

Per fork/process.md "Sub-forks are forks": every point below has more than
one defensible answer; the orchestrator batches these into AskUserQuestion
rounds and records outcomes in fork/decision-log.md **before the affected
slice merges**. Recommendations follow each; none is a decision.

-   **SF-1 (blocks S1): object representation.** Shared cost first, so the
    options are weighed honestly: under EITHER option, payload-free
    alternative constants of payload-carrying choices (`IntResult.Err`)
    need a constant that covers the payload storage — neither gets "as
    today" for free (§2.2b). The options differ in whether that cost is
    solvable with existing machinery. (a) Hybrid
    `StructType{.discriminant, .payload: CustomLayoutType}` —
    payload-free choices keep today's repr/value-repr/constants; only the
    payload region uses explicit layout; the `Err` constant is an ordinary
    StructValue whose payload element is `UninitializedValue`, and BOTH
    layers already lower (StructValue emitter constant.cpp:174-179,
    UninitializedValue→poison constant.cpp:351-354). (b) Whole-choice
    CustomLayoutType — more uniform, but forces pointer value reprs on all
    existing choices (type_completion.cpp:782-792), trips the
    convert.cpp:882-885 bailout for today's constructions, and has **no
    representable alternative constant at all**: the constant would have to
    BE a CustomLayoutType-typed aggregate value, and no SemIR value inst or
    lower/constant.cpp emitter produces one (the StructValue emitter
    hard-casts the constant's type to llvm::StructType,
    constant.cpp:174-179, while CustomLayoutType lowers to `[N x i8]`) —
    a new inst kind + emitter, that is the §6 XL trigger fired on day one.
    **Recommend (a)**; both satisfy F-007k's letter ("using the same
    explicit-layout object representation" for the _overlapping storage_).
-   **SF-2 (blocks S1): discriminant scheme ratification.** Keep
    `UInt(ceil(log2(n)))` with `()`-discriminant for 0/1 alternatives
    (bit-minimal, matches today, existing goldens stable) vs widen to `u8`
    (byte-addressable, friendlier to future C++ export/std::variant ABI
    thinking, W6+). Changing later is a fork ABI break, so W5 must ratify or
    change **now**. **Recommend: keep the current scheme** — choice export
    to C++ is not a 0.1 bullet, S4's variant mapping is by-value conversion
    not layout-sharing, and minimal churn wins; record that a future export
    workstream may revisit behind a repr version.
-   **SF-3 (blocks S1): `Alt()` empty parameter list.** (a) Becomes a
    zero-payload _function-like_ alternative — constructed `C.Alt()`,
    matched `.Alt()` — per the sum_types.md:233-241 constant-vs-factory
    distinction and the handle_choice.cpp:146-152 TODO direction. (b) Stays
    a TODO/error in 0.1 (today's behavior, minus the silent downgrade).
    **Recommend (a)** in S1 (it falls out of the same synthesis machinery).
-   **SF-4 (blocks S1): pattern spelling scope.** Leading-dot `.Name` only
    in 0.1 (the design's example form) vs also qualified
    `IntResult.Err`/`Optional(i32).Some(...)` patterns (the design's
    expression-pattern-with-alternative-form rule, sum_types.md:208-218).
    Qualified constants can't fall back to `==` (choices have no `==`), so
    qualified support means compiler-recognized alternative-pattern form
    either way. **Recommend leading-dot only** for S1/S2 with the qualified
    form as a recorded TODO + work item.
-   **SF-5 (blocks S2): binding spelling inside alternative patterns.**
    sum_types.md:82 writes `case .Some(the_value: i32)`; the conformance
    sketch writes `case .Ok(let v: i32)`; W4 parse testdata shows bare
    `case a: i32` producing LetBindingPattern. Accept bare only, `let` only,
    or both? **Recommend: bare `name: type`** (design-doc spelling), with
    `let` rejected by way of the normal pattern grammar — revisit alongside F-011
    if-let work which touches the same pattern surface.
-   **SF-6 (blocks S1, revisited each slice): trivially-copyable payload
    restriction.** The F-007k contract explicitly permits non-trivial
    payloads (`String`, unions.md:543-554); 0.1 slices restrict + diagnose,
    needing discriminant-dispatched destroy/copy synthesis to lift (no
    machinery exists — custom_witness.cpp:316-345 placeholder, no native
    Copy fallback :846-865). (a) Restriction is acceptable for all of 0.1
    fork scope (record as post-0.1 work item). (b) Restriction is
    S1-S4-temporary and a fifth slice for non-trivial payloads is added to
    this workstream. **Recommend (a)** — nothing in the 0.1 milestone
    bullets requires String payloads, and Result(T, E) over trivially
    copyable T/E covers F-006 B1; the deviation is recorded against the
    contract text.
-   **SF-7 (blocks S2): exhaustiveness vs `default` for choice matches.**
    (a) All-alternatives-covered choice match needs no `default`
    (sum_types.md:80-89 example compiles; missing alternatives = error). (b)
    Keep W4's `default`-required rule for every match in 0.1 (simpler,
    consistent, but the design-doc example and the conformance sketch never
    compile). **Recommend (a) at S2** — it is what "typecheck the match
    body, identify missing cases" (sum_types.md:118-122) asks for on the
    easy (closed-alternative-set) case.
-   **SF-8 (blocks S4): std::variant mapping target.**
    (a) `std::variant<Ts...>` maps to an anonymous compiler-synthesized
    choice with positional alternatives matched as `.0(x)`-style or
    index-named patterns; (b) maps only by way of user-declared
    `Core.Variant(...Ts)` prelude type; (c) 0.1 maps `std::optional` only,
    `std::variant` deferred. Naming/shape of positional alternatives has no
    design-doc answer. **Recommendation deferred to the S4 detailed plan**
    (after S2/S3 retrospectives); the milestone bullet names both types, so
    (c) needs explicit user sign-off if chosen.
-   **SF-9 (blocks S3's detailed plan): identity of `Core.Optional`.**
    `core/prelude/types/optional.carbon` is today a **class** over a
    private `OptionalStorage` interface with a pointer-niche layout and
    `HasValue`/`Get` methods, and its basic operations + niche already PASS
    conformance (work-items W-058 notes). S3's `Core.Optional(T)` choice
    silently overwrites that identity unless decided. Real trade-offs, all
    defensible: (a) **Replace** — Optional becomes the S3 generic choice;
    matches S4's mapping and the W-011 arbiter ("a Carbon match over an
    imported std::optional works"), but `choice` types cannot carry methods
    (sum_types.md:93-96), so `HasValue`/`Get` are removed or become free
    functions, currently-PASSING conformance programs change (must be
    re-pointed at the new API in the same slice with an explicit R16b note:
    design-directed change, not test-weakening), and the pointer niche is
    lost — a layout regression against docs/project/goals.md, recorded as a
    post-0.1 niche-optimization work item. (b) **Coexist** — the class
    stays; a separately-named choice serves S4's mapping; costs two
    Optionals and an answer for which one W-058's EqWith work targets.
    (c) **Facade** — the class keeps its API + niche specializations and
    its general-case storage becomes the S3 choice internally; costs:
    `match` over `Optional` still impossible (H3 gates on `is_choice`), so
    S4's optional arbiter must go through `HasValue`/`Get`, weakening the
    match-based bullet. **Recommend (a)**, with the niche-regression work
    item and the R16b program-migration note recorded at decision time; the
    W-058 inventory item folds into S3 per its own coherence-risk-9 note
    either way.

---

## 6. SemIR additions — new inst kinds?

**None planned for S1-S3.** The plan deliberately routes everything through
pre-existing kinds: `ClassDecl`/`CompleteTypeWitness` +
`StructType`/`CustomLayoutType` for the repr; `Call` + synthesized member
functions for construction; `ClassElementAccess` (custom-layout-aware,
convert.cpp:551-559, lower/aggregate.cpp:25-39) for discriminant/payload
access; `UninitializedValue` (typed_insts.h:2211-2219, poison-lowered at
lower/constant.cpp:351-354) for the payload slot of payload-free
alternative constants (§2.2b — the case that would otherwise have forced
a new value-inst); `BindName` + existing binding-pattern insts (in a new
_context_, not new _kinds_) for S2; `BranchIf`/`Branch`/EqWith `Call` for
dispatch — the same inventory W4 proved lowers untouched. S2 adds new
**parse** node kinds (§3.3), which are cheap by comparison. Distinct from
inst kinds and planned openly: **entity-level metadata** on `SemIR::Class`
— the S1 `is_choice` bool (§2.2c) and the S2 alternatives side-table
(§3.2.2), each with its import_ref copy; small, precedented
(`is_dynamic`/`fields_exported`), and NOT covered by the "no new inst
kinds" claim.

**XL-risk trigger (flagged per the workstream brief):** if implementation
finds that payload initialization or extraction through the overlapping
region cannot be expressed with existing init/access insts (for example an
`init`-category inst targeting a custom-layout field, or constant
evaluation of a payload-carrying choice constant demands a new value-inst),
then a new SemIR inst kind drags typed_insts.h + inst kind tables +
formatter + inst_namer + constant eval + lowering + goldens across every
affected file — that is a **plan-revision event**: stop, update this plan,
re-estimate the slice as XL, and notify the orchestrator; never quietly add
the kind mid-loop. S4 needs custom-type-mapping glue but no inst kinds.

---

## 7. Testdata & golden flow (R15/R16/R19)

-   All new/changed goldens ship with AUTOUPDATE markers and empty CHECK
    lines; the runner-side autoupdate workflow
    (`bazel run //toolchain/testing:file_test -- --autoupdate`) commits the
    reconciliation **before** the merge gate is judged. A red first CI on
    empty goldens is expected, not a semantics failure (R19). One
    reconciliation commit per slice is budgeted. Never hand-author or
    hand-edit CHECK lines (R16a).
-   Changed existing goldens per slice are enumerated in §2-§4; the S1 set
    is exactly `check/testdata/choice/params.carbon` (TODO flips) plus any
    `fail_todo` match testdata whose diagnostics move — grep-verify the full
    TODO-string inventory against testdata before each slice's
    implementation starts (W4 plan §6 discipline).
-   Every TODO string in §2.1 is contract text: conformance SKIP reasons
    quote them verbatim (R10), and changing one is a golden+conformance
    co-change.
-   clang-format 21.1.8 by way of hooks (R12/R18); `runner.py --self-test` before
    every conformance-touching commit (R7); private `--out` dirs (R5); one
    committer per worktree (R20).

---

## 8. Risk register

-   **R-1. Case-arm pattern context is the deep unknown (S2).** No existing
    caller exercises refutable, scrutinee-sourced binding patterns; the
    CARBON_FATAL at handle_binding_pattern.cpp:451-452 marks genuinely
    unbuilt machinery. Mitigation: S1 lands value first without it; S2 is
    pre-declared as the XL-risk slice with a plan-revision trigger (§6);
    reviewers briefed to attack scope/lifetime of bindings (arm scope only,
    no leakage into siblings/default).
-   **R-2. Parse surface (S2) is W5's departure from W4's check-only
    precedent.** New node kinds ripple into typed_nodes.h tables,
    node_stack.h consteval tables, and parse goldens. Mitigation: consteval
    tables turn miscategorization into compile errors; parse goldens
    autoupdate like check goldens.
-   **R-3. W-009 (native unions) coordination.** W-010 is inventoried as
    blocked_by W-009, but the true relationship is two shared unbuilt
    pieces: custom-layout init (convert.cpp:882-885) and native
    custom-layout destroy/copy witnesses (custom_witness.cpp:311-312
    CARBON_FATAL). Rule: whichever lands first builds them narrowly;
    the other rebases. If W-009 starts concurrently, these two files need a
    single owner (W-007-style ownership note) or serialized landing under
    F-002 gating.
-   **R-4. Temporary/cleanup soundness when the scrutinee gate widens
    (S1).** W4's argument was "integers have no cleanups"; S1's replacement
    is "in-slice choices are trivially destructible by construction (payload
    gate at completion)". Both adversarial reviewers must re-derive this,
    and the gate must be _type-property-based_ (trivial destructibility),
    never a choice-vs-class syntactic test, so it fails safe if S1's payload
    gate is later relaxed.
-   **R-5. custom_witness.cpp CustomLayoutType FATAL.** A native type with a
    custom-layout repr entering destroy-witness lookup crashes today.
    S1 must add the case _before_ the first native choice with a payload
    region completes, or scope-exit of a local choice var is a
    compiler crash. This is a confirmed-by-trace (not executed) hazard;
    the S1 testdata matrix includes a local `var r: IntResult` going out of
    scope precisely to execute it.
-   **R-6. F-007k needs an enforcing arbiter, not just behavior tests
    (anti-Goodhart, R16).** An implementer could pass all runtime tests with
    non-overlapping ordinary fields. The contract's arbiter is the S1 lower
    golden `payload_layout.carbon` pinning `[size x i8]` payload-region size
    = max(payload sizes) and identical GEP offsets for two different
    alternatives' payloads, on a choice whose payloads differ in size —
    sized so sequential layout would produce a visibly different constant.
    Reviewer #2's brief: verify the golden actually discriminates.
-   **R-7. Discriminant/ABI freeze (SF-2).** Whatever S1 ships becomes fork
    ABI; std::variant interop (S4) and any future C++ export inherit it.
    Mitigation: SF-2 goes to the user before S1 merges, with the
    reading-list rule (process.md Human-in-the-loop).
-   **R-8. sum_types.md `Match`-interface overreach.** The design doc's
    user-defined-sum-type mechanism (Continuation impls) is not W5. The
    slice boundary in §0.3 plus a decision-log scope entry at S1 landing
    (W4-S1 precedent) keep an implementer off that cliff; reviewers cite
    §0.3 against any generated-interface machinery in the diff.
-   **R-9. Generic payload layout at specialization (S3).** Layout depending
    on substituted T must be computed where generic class completion
    computes reprs, not ad hoc; getting this wrong silently miscompiles
    `Optional(T)` for exactly one T. S3's detailed plan (written post-S2)
    owns this; the S1 generic-payload TODO gate is what buys the time.
-   **R-10. Upstream collision (standing rule 5).** handle_choice.cpp's
    TODOs cite upstream trunk docs; choice payloads and pattern contexts are
    live upstream territory. Before each slice's implementation starts,
    check carbon-language/carbon-lang for in-flight work on choice
    alternatives / match patterns; a hit escalates to the orchestrator for a
    merge-vs-implement call.
-   **R-11. No local build.** All goldens by way of runner-side autoupdate; plan
    one red-first-CI reconciliation commit per slice (R19); runner-offline
    stalls handled per R14.
-   **R-12. Stale contract-doc text (R8 hygiene, S1 doc chore).**
    unions.md:556-562 still says "match is unimplemented" — false since W4
    slice 1 (commit 5a83b0e). S1's landing includes the one-line doc
    correction (and updates the same paragraph's choice-payload status as
    slices land), so reviewers can't be misled by a false dependency
    statement. Doc-only edit; no golden impact.
-   **R-13. Silent alternative dropout must not survive any slice.** Every
    input a slice still rejects must leave a diagnosable trace (error
    binding in scope, §2.1), never the current vanish-after-TODO behavior —
    adversary #1's standing probe: reference a rejected alternative later in
    the file and check the second diagnostic is sane.
-   **R-14. The §2.2b constant chain is confirmed-by-inspection, not
    executed.** `UninitializedValue`'s only in-tree producer today is the
    partial-class vptr fill (convert.cpp:721-727); no existing constant
    nests one inside a StructValue, and constant-eval of a struct literal
    carrying one as an element is unexercised. If eval or the StructValue
    emitter rejects the nesting, the fallback inside the same design is a
    narrow eval/emitter case for that one shape — still no new inst kind;
    anything beyond that hits the §6 plan-revision trigger. Mitigations:
    the S1 lower golden includes an `Err`-style constant of a
    payload-carrying choice (§2.4), and the arbiter's `IntResult.Err` arm
    executes it at runtime; adversary #1's brief includes attacking this
    chain first.

---

## 9. Loop mechanics per slice

Each slice runs the full R11 loop — 1 implementer (this plan + rulebook +
design docs in context), 2 adversarial reviewers (correctness: "find the
input that breaks this, write the failing test"; strictness: "find the
rule/SemIR-invariant/contract violation, run the R16 Goodhart checks —
including R-6's layout-golden discrimination check"), 1 fixer with
findings-as-data — then the merge gate: runner autoupdate + `bazel test
//toolchain/...` + conformance scoreboard non-regression. Slice lands only
green (F-002); scoreboard/work-items/decision-log updated at landing (R9).
Sub-forks SF-1..SF-9 must be decided before their blocking slice's
implementer starts (SF-9 earlier still: before S3's detailed plan is
written); the orchestrator batches SF-1..SF-4+SF-6 (S1 blockers)
into the first AskUserQuestion round.
