<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Unions plan: native `union` (UN-1, W-009) and C++ union interop (UN-2, W-015)

**Status:** PROPOSED, 2026-09-27 — awaiting the two adversarial plan
reviews R29(c) keeps for plans. Branch `claude/carbon-fork-0-1-unions`
off trunk e78db5df4 (post-PR #40: EH-A landed). Conformance in this tree
is **106 PASS / 0 FAIL / 28 SKIP over 134** per
fork/conformance/out/scoreboard.json totals; every floor below is stated
relative to that. Two workstreams are in flight elsewhere and land
before or beside this one: W-012 (if-let/while-let/let-else, main
checkout, target 108/0/28 over 136 — adds exactly two PASS programs to
both sides of every equation here) and EH-B (../carbon-ehb, touching
toolchain/check/cpp/{thunk,import,export,type_mapping}.cpp — the UN-2
sequencing constraint of §0.4). All toolchain, core, docs and fork line
numbers are against trunk e78db5df4 and were re-verified for this plan;
where the ledger's citations are stale the correction is recorded in
§0.2. The container cannot build the toolchain (clang 18 < 19), so this
plan pre-registers every golden and diagnostic outcome for the hosted
autoupdate to confirm or refute (R28(b)).

**Items:** W-009 ("UN-1: native `union` declaration — design page +
lex/parse/check/lower front-end on CustomLayoutType", size M) and W-015
("UN-2: union C++ interop — designated-init construction of imported
unions, is_union import marking, union export", size M, blocked_by
W-009). **Design authority, not reopened:** fork/decision-log.md F-007
(:1023-1045) with the owner's sub-decisions F-007a..k; the ratified
normative text docs/design/unions.md (656 lines); the option paper
fork/design-sprint/unions.md is its research record and is not edited.

**Milestone bullet this plan flips** (fork/gap-analysis.md:45):
"Type system: Unions (un-discriminated) + C++ union mapping" —
DESIGN-ONLY → PARTIAL at UN-1 → DONE at UN-2 (§8.6). R7: the bullet
string is copied character-for-character into every conformance header.

## §0 Audit: what already exists, and where the ledger is stale

### §0.1 Sub-feature table (verified in-tree at e78db5df4)

| # | Design element (docs/design/unions.md) | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `union` keyword (:154-192, F-007a/h) | MISSING | `grep -n union toolchain/lex/token_kind.def` is empty; the decl-introducer block is :157-176 (`Require` :174, `Var` :175-176 inside `CARBON_TOKEN_WITH_VIRTUAL_NODE`); `DeclIntroducerStateStack::IsDeclIntroducer` is generated from that block (check/decl_introducer_state.h:48-57) |
| 2 | Parser: declaration/definition shape with a class-style body (:90-152) | MISSING | no `Union` node kind (parse/node_kind.def:422-425 are the four `Class*` kinds; :462-465 the four `Choice*` kinds); the class shape is the `TypeAfterIntroducer`/`DeclOrDefinition`/`DeclDefinitionFinish` variant states (parse/state.def:1553-1578) fed by `DeclScopeLoop`/`Decl` variants (:425, :441) over `DeclContextKind` (parse/handle_decl_scope_loop.cpp:49-54: Regular/Class/Interface) |
| 3 | Check: a class-shaped entity whose object representation is an all-offsets-zero `CustomLayoutType` (:418-426) | MISSING for native unions; LANDED for imported ones | `SemIR::CustomLayoutType` (sem_ir/typed_insts.h:622-633; layout block = size, align, per-field offsets, sem_ir/ids.h:887-906); built by `ImportClassObjectRepr` for every imported C++ record (check/cpp/import.cpp:666-865, union fields land at offset 0 by way of Clang's `getFieldOffset`, :838-851) and by `handle_choice.cpp:799-833` for a choice payload region with the max-of-fields rule at :671-680; completion (check/type_completion.cpp:787-796: pointer value repr, size/align from the block), nested completion (:497-501), import resolution (check/import_ref.cpp:4187-4233) all exist |
| 4 | Lowering of the representation (:418-426) | LANDED | lower/type.cpp:675-682 lowers `CustomLayoutType` to `[size x i8]`; lower/aggregate.cpp:29-39 turns element access into a byte-offset GEP; goldens lower/testdata/interop/cpp/class/import/field.carbon `access_union`/`assign_union` (:59-85; IR :227-231 `getelementptr inbounds nuw [4 x i8], ptr %a, i32 0, i32 0` + `load i32`) |
| 5 | Field read/write on imported unions, anonymous-union flattening (:460-491, :428-442) | LANDED | check/testdata/interop/cpp/class/import/field.carbon `use_union_fields` (:43-65) and `use_anon_struct_union` (:86-93); import.cpp:807-811 (anonymous members by way of `IndirectFieldDecl` chains), :802-805 (bit-fields skipped — the documented limitation :450-452) |
| 6 | Designated single-field initialization (:260-283, F-007d) | MISSING for both native and imported | check/convert.cpp:909-912 `ConvertStructToClass`: `if (context.types().Is<SemIR::CustomLayoutType>(object_repr_id)) { // Builtin conversion does not apply. return value_id; }` — the bailout the design's implementation note (:278-283) and W-015's notes cite (as ":882-885"; §0.2 item 5) |
| 7 | Field rules: trivially copyable + destructible (:194-241, F-007e) | PREDICATE EXISTS, unwired | `IsTriviallyDestructible` (check/custom_witness.cpp:504-620: arrays, non-choice non-C++ classes by way of adapted type/object repr, `const`, `MaybeUnformed`, structs, tuples, scalars; `is_choice` → false at :535-538; NO `CustomLayoutType` arm — :568-598 list Const/MaybeUnformed/Struct/Tuple only, :600-618 scalars/default-false) and `IsTriviallyCopyableForExport` (check/cpp/export.cpp:1583-1602) — the F8b single-owner predicate W-015's notes call "needed" (§0.2 item 7). The SF-6 choice allowlist `IsInSliceChoicePayloadType` (check/type.cpp:313-331: int/float/bool/pointer through adapters, plus `()`) is NOT the union predicate — it rejects the design's canonical `array(u8, 4)` field (:96-99) |
| 8 | Whole-union copy is a byte copy (:271-276) | MECHANISM EXISTS, gated to choices | `LookupChoiceCopyWitness` (custom_witness.cpp:936-967) answers a `Core.Copy` query with the primitive-copy witness only when `is_choice` (:944); lowering `PrimitiveCopy` (lower/handle_call.cpp:339-372) memcpys an in-place-repr object through `CopyValue` (lower/function_context.cpp:496-514, pointer value repr → `CopyObject`) |
| 9 | Destruction of a union local (needed for any `var u: U;`) | LANDED by way of the choice work | `CanDestroyClass` (custom_witness.cpp:151-208) walks the object repr; the `CustomLayoutType` case :314-333 mirrors the struct walk over the overlapping fields (its comment :315-318 says "today the payload region of a payload-carrying choice" — refreshed in §2.1); `MakeDestroyOpBody` lists `CustomLayoutType` (:637) as a placeholder no-op like every aggregate |
| 10 | Importing: `is_union` marking (:462-491) | MISSING | import.cpp:619-628 `GetInheritanceKind` maps a union to `Final` only; `SemIR::ClassFields` (sem_ir/class.h:57-70) has `is_choice` (:80-85) and no `is_union`; import_ref.cpp:2019 mirrors `is_choice` on import |
| 11 | Exporting as a genuine union (:493-505) | MISSING, and would CRASH | export.cpp:76-79 creates every exported record with `clang::TagTypeKind::Class`; `ExportAllFieldsToCpp` (:543-580, :550) and `CalculateCppFieldOffsets` (sem_ir/read_only_ast_source.cpp:15-49, :22) both call `Class::GetStructTypeFields` (sem_ir/class.cpp:55-72), which `GetAs<SemIR::StructType>` the object repr — a CHECK failure on a `CustomLayoutType` repr; :45 accumulates sequential offsets (`AppendField`), wrong for a union |
| 12 | Generic unions "as they fall out" (:105-117) | DO NOT FALL OUT | the only symbolic-layout machinery is the choice payload eval hook (check/eval_inst.cpp:212-351): it requires every field to be a payload TUPLE (:254-256 `GetAs<SemIR::TupleType>`) and enforces the SF-6 allowlist per element (:240-250, :278-297, :319-324) — a `union Slot(T: type) { var value: T; }` would CHECK-fail in it. §0.3 D-UN-3 |
| 13 | Conformance | SKIP stub | fork/conformance/programs/types/union_basic.carbon: bullet :5, EXPECT lines :6-9, SKIP reason :10 (says "no design doc" — stale since F-007), strawman body :17-45 returns 1 |
| 14 | Docs | DONE (text), three stale sentences | docs/design/unions.md :84-88 ("Payload-carrying `choice` alternatives are not yet implemented ... W5") — false since W-010 was DISCHARGED (gap-analysis.md:44); :116-117 (generic unions "supported as they fall out") — refuted by row 12; :278-283 implementation note — becomes "landed at UN-1/UN-2". docs/design/README.md:2207-2237 already carries the Unions section; docs/design/lexical_conventions/words.md:47-104 keyword list lacks `union`; the editor grammars the design names (:188-192) lack it: utils/vim/syntax/carbon.vim:40, utils/vscode/carbon.tmLanguage.json:369, utils/textmate/Syntaxes/carbon.tmLanguage:488 and Samples/keywords.carbon:17, utils/tree_sitter/queries/highlights.scm:94 |

### §0.2 Ledger and brief claims found stale (each corrected at §8.5 discharge)

1.  **The planning brief's template path `fork/w012/plan.md` does not
    exist in this tree** (`ls fork/` — no `w012`; the W-012 workstream
    is on branch claude/carbon-fork-0-1-w012 in another checkout, per
    fork/ORCHESTRATION.md). The templates used are fork/eh/plan.md
    (two-slice, C++-interop half), fork/w077/plan.md (single feature)
    and fork/w5-choice/plan.md (the `choice` build-a-`Class` precedent).
2.  **W-009 evidence `fork/conformance/programs/types/union_basic.carbon:6`**
    points at the `EXPECT-EXIT` line; the SKIP line is :10.
3.  **W-009 notes "choice-pattern parse (~12 states)"** and the option
    paper's "`node_kind.def:412-415`, 12 states in `state.def`"
    (fork/design-sprint/unions.md:232-234): `choice` has FIVE states
    (parse/state.def:1817-1866) and its node kinds are at :462-465. More
    importantly a union body is a CLASS-shaped declaration scope, so the
    parser follows the `class` variant shape (state.def:1553-1578,
    handle_decl_definition.cpp:12-79), not the choice alternative list —
    five new variant states, four new node kinds (§1.2).
4.  **W-009 notes "symbolic max-size/max-align (route b preferred)" as
    the one genuinely new piece:** route (b) LANDED at W5-S3b for choice
    payload regions (the dependent-layout sentinel + eval hook,
    eval_inst.cpp:212-351) but is SF-6-specific (§0.1 row 12); the
    genuinely new piece is the designated-initialization conversion and
    its constant-fold suppression (§1.5), and generic unions are
    TODO-gated in 0.1 (D-UN-3).
5.  **W-015 notes "convert.cpp:882-885 struct-literal bailout":** the
    bailout is at convert.cpp:909-912 (`ConvertStructToClass`, after the
    `AbstractTypeInInit` check :889-895 and `GetObjectRepr` :897-902).
    The option paper's `lower/type.cpp:633-640` and `import.cpp:648-858`
    (unions.md:214-222) are now :675-682 and :592-865; its
    `export.cpp:104/161` record-creation sites (:245-248) are :76-79.
6.  **W-015 notes omit two hard blockers on export:** `GetStructTypeFields`
    CHECK-fails on a `CustomLayoutType` repr and `CalculateCppFieldOffsets`
    accumulates sequential offsets (§0.1 row 11). Both are in-plan (§1.B).
    The notes' claim "layout agrees by construction" holds only once
    Carbon supplies offset 0 for every union field (D-UN-8).
7.  **W-015 notes "Needs the shared trivially-copyable predicate
    (coherence risk 7, W-006)":** it exists since F8b (2026-08-18) —
    `IsTriviallyDestructible` / `IsTriviallyCopyableForExport` (§0.1 row
    7). What is missing is its `CustomLayoutType` arm, added at UN-1.
8.  **W-015 notes "gap-analysis row 32's 'opaque interop types' claim is
    stale":** `grep -n opaque fork/gap-analysis.md` is empty — trunk's
    2026-09-27 reconciliation already removed it; the note itself is now
    stale and is dropped at discharge.
9.  **W-007 (five-way contention refactor-first)** lists UN-2 as a
    contender. EH-B is in flight in the same files; the precondition
    "before any two start concurrently" is met by SEQUENCING, not by the
    refactor: UN-2 rebases onto trunk after EH-B merges (§0.4). W-007's
    notes get that record.
10. **union_basic.carbon:10 SKIP reason "no design doc"** — stale since
    F-007 (2026-07-19); the stub is replaced wholesale at UN-1 (§5.A).
11. **docs/design/unions.md:84-88** says choice payloads are
    unimplemented (W5) — W-010 DISCHARGED (gap-analysis.md:44); dated
    amendment at §8.6. **:116-117** promises generic unions fall out —
    they do not (§0.1 row 12); dated amendment recording D-UN-3.
12. **W-010 notes' coordination line** ("W-009 coordination per plan
    risk R-3: S1 built the narrow custom-layout pieces (convert.cpp
    ChoicePayload fill; custom_witness.cpp CustomLayoutType destroy
    cases); W-009 rebases on them") is ACCURATE and is exactly what this
    plan builds on (§0.1 rows 3, 8, 9); it gains a "discharged at UN-1"
    note.

### §0.3 Decisions this plan auto-adopts (R29(a): design recommendation under V-2/V-3, veto-able after the fact)

None of these reopens an F-007 sub-decision; each fixes an
implementation choice the design leaves to the toolchain, or draws a
0.1 line the design itself drew.

-   **D-UN-1 — a union is a `SemIR::Class` with a new entity flag
    `ClassFields::is_union`, whose object representation is a
    `CustomLayoutType` with every field offset zero and size/alignment
    by the max-of-fields rule.** This is what unions.md:418-426 says the
    toolchain does ("a Carbon-authored `union` builds the _same_
    representation ... Nothing about the representation or its lowering
    distinguishes an imported union from a native one"), and it is the
    `choice` precedent (handle_choice.cpp:74-87 `is_choice`, the
    sum_types design's "class with methods and some builtin impls").
    Consequence: every class facility the design grants unions (fields,
    methods, `impl`, `alias`, forward declaration, member-of-class,
    import/export of the entity) is inherited; `var` fields become
    `FieldDecl`s through the unchanged class-scope path
    (handle_let_and_var.cpp:66-82, pattern.cpp:150-175). V-3 check:
    upstream has no `union`; p000157 leaves typed-union versus `Storage`
    open (design-sprint unions.md:372-379) — no contradiction; the fork
    spelling is already in F-007's register. Break condition: none —
    the representation is design-mandated.
-   **D-UN-2 — the 0.1 field predicate is `IsTriviallyDestructible`
    (custom_witness.cpp:504) extended with a `CustomLayoutType` arm, NOT
    the SF-6 scalar allowlist.** Rationale: the design's own canonical
    union has an `array(u8, 4)` field (unions.md:96-99) and admits
    arrays, tuples, structs, classes and unions "whose members
    recursively satisfy" the predicate (:212-215); `IsInSliceChoicePayloadType`
    rejects all of those. `IsTriviallyDestructible` is the design's
    "defined once, reused" predicate (:196-202) as landed at F8b, and
    Carbon has no user-provided copy operation other than `Core.Copy`
    impls, so trivially-destructible-with-trivial-shape IS the
    trivially-copyable predicate today (export.cpp:1583-1602 says so).
    Two conservative exclusions follow from the predicate as it stands
    and are recorded loudly rather than papered over: (i) a CHOICE-typed
    field is rejected (:535-538 returns false for `is_choice`, deferring
    to the destroy machinery) although the design permits choices whose
    payloads are trivial — residue item "union fields of choice type"
    (§8.5); (ii) `str`/`String` fields are rejected (default arm). Break
    condition: if the `optional_pointer_field` subfile (§4.A) diagnoses,
    the design's named migration idiom `Optional(T*)` (:341-344) is not
    admitted by the predicate — the predicate gains the case (the
    adapter walk :555-566 is expected to reach the pointer through
    `MaybeUnformed(T*)`, optional.carbon:180-185) and the doc gets a
    dated note; never a silent widening elsewhere.
-   **D-UN-3 — generic unions are TODO-gated in 0.1: a union with its
    own parameters or an enclosing generic scope (`generic_id.has_value()`,
    the handle_choice.cpp:633-634 test) diagnoses `SemanticsTodo`
    "`generic union`" at its definition and completes with an error
    witness.** unions.md:116-117 says generic unions are "supported as
    they fall out of the general machinery"; §0.1 row 12 shows they do
    not — the only symbolic-layout recompute is the choice payload hook,
    which asserts tuple fields and the SF-6 allowlist. Making that hook
    union-aware would either key on a flag `CustomLayoutType` does not
    carry or duplicate the hook; both are beyond a slice whose design
    cut line is "concrete (non-generic) unions" (design-sprint
    unions.md:518-523; "only concrete instantiations are covered by the
    conformance suite", unions.md:116-117). Recorded as a dated doc
    amendment (§8.6) and a residue item "generic unions" (§8.5) naming
    the mechanism: a `CustomLayoutType` origin bit or a separate
    dependent-layout rebuild without the SF-6 element check. Break
    condition: none in this workstream.
-   **D-UN-4 — designated single-field initialization is a new
    `ConvertStructToUnion` arm inside `ConvertStructToClass`, replacing
    the :909-912 bailout for `is_union` classes; it emits a ONE-element
    `ClassInit` (the designated field's in-place initializer into
    `ClassElementAccess(storage, field_index)`), and `EvalConstantInst(ClassInit)`
    (eval_inst.cpp:180-186) returns `ConstantEvalResult::NotConstant`
    for a union class so the initializer never folds.** The fold
    suppression is the load-bearing part: a folded `ClassInit` becomes a
    `StructValue` whose lowering is
    `EmitAggregateConstant<llvm::ConstantStruct>(...,
    cast<llvm::StructType>(GetType(type)))` (lower/constant.cpp:204-208)
    — but a union's LLVM type is `[N x i8]` (lower/type.cpp:675-682), so
    the cast is a CHECK failure; overlapping fields have no constant
    aggregate spelling (the `PadToType` zero-size arm, constant.cpp:127-172,
    is the only sub-object shape lowering accepts, and it was minted for
    exactly one folded shape by EH-A's R-3). One-sentence justification
    for the reviewer: a union value has no constant object representation
    in lowering, so union initializers are always runtime stores. The
    one-element `ClassInit` is safe because the in-place aggregate
    initializer lowering iterates the ELEMENT block, not the repr fields
    (lower/aggregate.cpp:200-232: constant elements are stored through
    `InitializeStorage`, non-constant ones were stored when their
    `InPlaceInit` lowered, handle.cpp:207-211), and the element-count
    convention the choice constructor keeps ("so the `ClassInit`'s
    element count matches the object representation's field count",
    handle_choice.cpp:404-408) exists for the CONSTANT fold, which
    D-UN-4 forbids. Covering the other fields with `InPlaceInit(UninitializedValue)`
    is rejected: at offset 0 the cover's zero store would clobber the
    designated value whenever it is ordered after it (`EmitAggregateInitializer`
    stores constant elements last, aggregate.cpp:213-232). Break
    condition: any autoupdate fill showing a `struct_value` of union
    type, or a lowering CHECK in `EmitAsConstant(StructValue)`, means
    the suppression missed a path — stop and diagnose (§7 R-1).
-   **D-UN-5 — whole-union copy reuses the synthesized primitive-copy
    witness: `LookupChoiceCopyWitness`'s gate becomes `is_choice ||
    (is_union && !is_cpp_scope)`.** Justification is the union field
    rule itself (unions.md:271-276: "every union is itself trivially
    copyable: copy initialization and assignment ... copy the union's
    full object representation — all `size(U)` bytes"), the same
    per-field triviality argument W-075 made for choices
    (custom_witness.cpp:921-935). The `is_cpp_scope` exclusion is
    load-bearing: an IMPORTED union keeps C++'s determination
    (unions.md:482-485 "the import preserves exactly Clang's
    determination"), so its copy stays on the C++ copy-constructor path
    (`BuildCopyWitness`, check/cpp/impl_lookup.cpp:130-160) where a
    non-trivial member deletes it. Pinned both ways (§4.A `copy`; §4.B
    `fail_copy_nontrivial_member`). Break condition: the W-015 negative
    pin compiling clean.
-   **D-UN-6 — member restrictions (unions.md:140-152) are enforced at
    PARSE by a fourth `DeclContextKind`, `UnionContext`, whose introducer
    table omits `adapt`, `base`, `class`, `choice`, `constraint`,
    `interface` and a nested `union`; the remaining rules reuse existing
    check diagnostics.** Upstream precedent: the interface context
    already rejects `var` this way (handle_decl_scope_loop.cpp:140-150
    registers `Var` for Regular and Class only), producing
    `UnrecognizedDecl` "unrecognized declaration introducer" (:27-34).
    `abstract union`/`base union` diagnose the existing
    `ModifierNotAllowedOnDeclaration` (modifiers.cpp:102-105) because the
    allowed set excludes `KeywordModifierSet::Class`; a `virtual`/`abstract`
    method diagnoses the existing `ModifierVirtualNotAllowed` /
    `ModifierAbstractNotAllowed` (modifiers.cpp:155-176) because a union
    is `Final`; a redeclaration that flips kind (`class C; union C {}`)
    diagnoses the existing `NameDeclDuplicate`/`NameDeclPrevious` pair
    through `DiagnoseDuplicateName`, the "redeclaration of something
    other than a class" branch (handle_class.cpp:150-155). Zero new
    diagnostics for restrictions; four new diagnostics in total (§1.7).
    Recorded residue: the parse-level message for a nested `class` in a
    union is generic ("union member-restriction diagnostics", §8.5).
    Break condition: none.
-   **D-UN-7 — split: two PRs, UN-1 then UN-2, UN-2 rebased after EH-B
    merges.** See §0.4. UN-1 carries a two-line guard in
    `ExportClassToCppInDeclContext` (export.cpp:60-91): a union reaching
    C++ export diagnoses `SemanticsTodo` "`union export`" and returns
    nullptr, instead of CHECK-crashing in `GetStructTypeFields` (§0.1 row
    11). UN-2 deletes the guard.
-   **D-UN-8 — on export, Carbon is the layout authority for a union as
    for every exported record: `CalculateCppFieldOffsets` gets a union
    arm that records offset 0 for every field, and `layoutRecordType`
    keeps supplying size/alignment from `GetCompleteTypeInfo` (which for
    a union reads the `CustomLayoutType` block).** Rejected: returning
    `false` from `layoutRecordType` for unions to let Clang lay it out —
    it would make Carbon's exported records two-regime, and the
    design's "agree by construction" (unions.md:497-500) is then checked
    by the conformance program's `static_assert(sizeof/alignof)` in the
    inline C++ block rather than assumed. Also: the `FinalAttr` that
    `CompleteType` adds for every `Final` class (generate_ast.cpp:452-457)
    is NOT added for a union (`final` is meaningless on a C++ union and
    is a Clang-side shape no existing golden exercises) — the C++ side
    sees an ordinary trivial union (unions.md:502-505).

### §0.4 The split decision: two PR-sized workstreams, sequential

The bullet is one row, but the work is two milestone deliverables with
one directed dependency and one external sequencing constraint, so per
R29(b) it is two PRs:

-   **UN-1 (W-009, "native `union` end to end"):** lex keyword; parse
    (five variant states, four node kinds, `UnionContext`); check
    (`handle_union.cpp` on the `handle_class.cpp` decl/merge path with
    `is_union`, union object-repr computation, field predicate,
    designated-init conversion + fold suppression, copy-witness gate,
    the export TODO guard); lower unchanged; goldens; conformance
    (`union_basic` SKIP→PASS + a differential pair); docs, ledger,
    gap-analysis PARTIAL. Size M. Touches lex/parse/check/sem_ir and
    exactly two lines of check/cpp/export.cpp (the guard).
-   **UN-2 (W-015, "C++ union interop"):** `is_union` on import;
    designated init of imported unions (falls out of UN-1's arm once the
    flag is set — the design's implementation note :278-283 says the two
    are the same conversion); union export (`TagTypeKind::Union`,
    `GetStructTypeFields` over `CustomLayoutType`, the offset-0 layout
    arm, no `FinalAttr`, trivial-union destructor omission); goldens; two
    conformance programs; gap-analysis DONE. Size S/M. Touches
    check/cpp/{import,export}.cpp, check/cpp/generate_ast.cpp,
    sem_ir/{class,read_only_ast_source}.cpp — the W-007 contention files
    EH-B is editing now.
-   **Dependency and sequencing:** UN-2 needs UN-1's `is_union` flag,
    conversion arm and `IsTriviallyDestructible` arm. UN-2's implementer
    starts after UN-1's hosted verification is green AND rebases onto
    trunk after EH-B merges (R29(d) pipelining: UN-2's planner-level
    spec is complete here; its import.cpp/export.cpp hunks are small and
    additive, so the rebase is mechanical, but it is a rebase, never a
    reorder).
-   Rejected: one PR (mixes the lex/parse/check surface with the
    check/cpp contention files while EH-B is in flight — the rebase
    would drag the whole union front-end through it, and the bullet's
    two halves flip the scoreboard independently: DESIGN-ONLY → PARTIAL
    is observable at UN-1); three PRs (splitting the designated-init
    conversion out of UN-1 would leave the design's own construction
    idiom, F-007d, un-testable and the conformance program at one
    field-assignment shape).

## §1 Design decisions

### §1.A UN-1 — native `union`

1.  **Lex: one line.** `CARBON_DECL_INTRODUCER_TOKEN(Union, "union")`
    inserted at token_kind.def:175, between `Require` (:174) and the
    `CARBON_TOKEN_WITH_VIRTUAL_NODE(CARBON_DECL_INTRODUCER_TOKEN(Var,
    "var"))` wrapper (:175-176) — alphabetical, and NOT wrapped in the
    virtual-node macro (unions.md:175-177: like `class`/`choice`, a
    union's tree introduces no virtual node). Mechanical fallout, all
    generated: `Lex::UnionTokenIndex` (token_index.h:57-58), the
    `IsDeclIntroducer` switch (decl_introducer_state.h:48-57), the
    `LexerTest.Keywords` sweep (tokenized_buffer_test.cpp:717-731), the
    `token_kind_test.cpp` spelling checks, the `DeclIntroducers` table
    row (handle_decl_scope_loop.cpp:72-84, one `CARBON_TOKEN` expansion).
    Keyword fallout check (unions.md:181-187): `grep -rnw union` over
    every `.carbon` under toolchain/*/testdata, core/, examples/ and
    fork/conformance/programs finds `union` only inside C++ header
    subfiles (`// --- union.h` and friends) and in prose comments — no
    Carbon identifier migrates (§6.A). `r#union` is pinned as a
    still-valid raw identifier (§4.A `raw_identifier`).
2.  **Parse: the `class` shape, not the `choice` shape.** A union body
    is a declaration scope (fields, methods, impls, aliases), so the
    parser mirrors the class variant chain exactly:
    -   node_kind.def: `UnionIntroducer`, `UnionDefinitionStart`,
        `UnionDefinition`, `UnionDecl` as
        `CARBON_PARSE_NODE_KIND_DECLARATION`s after `ClassDecl` (:425).
        typed_nodes.h: a `UnionSignature` template beside `ClassSignature`
        (:1578-1589 — `bracketed_by` and the `introducer` member type are
        class-specific, so a 12-line sibling rather than a fourth template
        parameter on a struct three aliases already instantiate),
        `UnionDecl`/`UnionDefinitionStart` aliases over it (`Lex::SemiTokenIndex`
        -   `NodeCategory::Decl`, `Lex::OpenCurlyBraceTokenIndex` +
            `NodeCategory::None`, as :1591-1597), and `UnionDefinition`
            `{signature, members, token}` (:1599-1607 shape). Every struct
            has at most four fields (the eight-field cap of
            common/struct_reflection.h). `Parse::AnyUnionDeclId =
            NodeIdOneOf<UnionDeclId, UnionDefinitionStartId>` in node_ids.h,
            and `AnyClassDeclId` (:172-177) gains both — the exact precedent
            is `ChoiceDefinitionStartId`'s presence there with its TODO
            ("we have choice types produce a class, so they are a form of
            class decls"), which is what lets `SemIR::ClassDecl`
            (`Define<Parse::AnyClassDeclId>`, typed_insts.h:460-463) be
            placed at a union node without a location-verification CHECK
            (§7 R-6).
    -   state.def: `TypeAfterIntroducer` VARIANTS3 → VARIANTS4 (+Union,
        :1562-1563); `DeclOrDefinition` VARIANTS4 → VARIANTS5 (:1577-1578);
        `DeclDefinitionFinish` VARIANTS4 → VARIANTS5 (:1553-1554); `Decl`
        VARIANTS3 → VARIANTS4 (:425); `DeclScopeLoop` VARIANTS3 → VARIANTS4
        (:441). `CARBON_PARSE_STATE_VARIANTS5` exists (:56-59); no
        VARIANTS6 is needed. Five new states; the comment blocks at
        :346-357 and :1556-1576 name the new variant.
    -   handle_type.cpp: `HandleTypeAfterIntroducerAsUnion` →
        `DeclOrDefinitionAsUnion` (:11-31 shape). handle_decl_definition.cpp:
        `HandleDeclOrDefinitionAsUnion(NodeKind::UnionDecl,
        NodeKind::UnionDefinitionStart, StateKind::DeclDefinitionFinishAsUnion)`,
        the `if (decl_kind == NodeKind::ClassDecl)` chain at :25-31 gains
        `UnionDecl → DeclScopeLoopAsUnion`, and
        `HandleDeclDefinitionFinishAsUnion(NodeKind::UnionDefinition)`.
        handle_decl_scope_loop.cpp: `UnionContext = 3`,
        `MaxDeclContextKind = UnionContext` (:49-54; the table initializer
        :72-84 grows to four `Unrecognized` entries per token);
        `set(Lex::TokenKind::Union, NodeKind::UnionIntroducer,
        StateKind::TypeAfterIntroducerAsUnion)` after `Require` (:138-139);
        `set_contextual(Var, UnionContext, VariableIntroducer, VarAsRegular)`
        and `set_contextual(Let, UnionContext, LetIntroducer, Let)` beside
        :140-150; then an `unset(token, UnionContext)` lambda applied to
        `Adapt`, `Base`, `Choice`, `Class`, `Constraint`, `Interface`,
        `Union` — D-UN-6's exclusion list; everything else a class body
        admits (`fn`, `impl`, `alias`, `let`, `var`, `extend`/access
        modifiers, `namespace`, `observe`, `require`, `match_first`,
        `inline`, the packaging keywords) stays admitted so the check
        layer keeps owning those rules, exactly as for classes.
        `HandleDeclAsUnion`/`HandleDeclScopeLoopAsUnion` (:320-356 shape).
        `ResolveAmbiguousTokenAsDeclaration`'s next-token list (:227-240)
        gains `Lex::TokenKind::Union` for parity with `Class` (so
        `export union U;` parses `export` as the modifier).
        handle_statement.cpp: `case Lex::TokenKind::Union:` beside `Choice`/
        `Class` (:59-60) so a local union declaration inside a function
        body takes `DeclAsRegular` — the `choice/local.carbon` precedent.
    -   Coverage: parse/coverage_test.cpp:17-30 requires every node kind
        in some golden; §4.A's parse goldens cover all four.
3.  **Check: the class declaration path, shared, with `is_union`.**
    sem_ir/class.h `ClassFields` gains `bool is_union = false;` after
    `is_choice` (:85) with the entity-level-truth comment; import_ref.cpp:2019
    mirrors it (`.is_union = import_class.is_union`). handle_class.cpp's
    `BuildClassDecl` (:173-263) is split: the two pops (`PopAndDiscardSoloNodeId<ClassIntroducer>`
    :178-179, `Pop<Lex::TokenKind::Class>` :184-185) stay in the class
    caller, and the remainder becomes `BuildClassOrUnionDecl(Context&,
    Parse::AnyClassDeclId, bool is_definition, DeclIntroducerState
    introducer, Lex::TokenKind decl_kind)` declared in check/class.h:
    the allowed modifier set is `Access | Extern` plus
    `KeywordModifierSet::Class` only for `decl_kind == Class` (:186-190);
    `inheritance_kind` is `Final` for a union (unions.md:142-146) and
    the `.Case(...)` mapping :204-208 for a class; `.is_union = (decl_kind
    == Lex::TokenKind::Union)` in the `SemIR::Class` initializer
    (:219-224); `MergeClassRedecl` (:51-91) passes `decl_kind` to
    `DiagnoseIfInvalidRedecl` (merge.h:47-50) so `RedeclRedef` reads
    "redefinition of `union U`"; `MergeOrAddName` (:95-171) treats
    `prev_class.is_union != new_is_union` like the "something other than
    a class" branch (:150-155, `DiagnoseDuplicateName`). New file
    check/handle_union.cpp (BUILD: check/BUILD:17-118 lists sources
    explicitly — `class.cpp` at :20 — so `handle_union.cpp` is added
    there; parse/BUILD globs testdata only, its `handle_*.cpp` list is
    explicit too) with the four handlers: `UnionIntroducerId` mirrors
    :36-49 with `Push<Lex::TokenKind::Union>`; `UnionDeclId` pops and
    calls `BuildClassOrUnionDecl(..., /*is_definition=*/false, ...)`
    then `decl_name_stack().PopScope()` (:265-269); `UnionDefinitionStartId`
    pops, builds, then the :271-299 scaffolding verbatim
    (`StartClassDefinition`, `PushForEntity` with the self specific,
    `StartGenericDefinition`, `inst_block_stack().Push()`,
    `node_stack().Push(node_id, class_id)`, `field_decls_stack().PushArray()`,
    `vtable_stack().Push()`, `body_block_id`); `UnionDefinitionId` pops
    the class id, calls the new `ComputeUnionObjectRepr` (§1.A.4), pops
    the three stacks and `FinishGenericDefinition` (:560-577 shape). The
    `vtable_stack` push/pop is kept for symmetry with the class path even
    though a union can never request a vtable (`virtual` is forbidden
    for `Final` classes and `ForbidModifiersOnDecl` strips the modifier);
    `ComputeUnionObjectRepr` CHECKs the vtable block is empty.
4.  **`ComputeUnionObjectRepr` (check/class.cpp, beside
    `ComputeClassObjectRepr` :432-441; `AddStructTypeFields` :115-142
    stays static and is reused):** (i) if `class_info.generic_id.has_value()`
    — the union has parameters or an enclosing generic — `context.TODO(
    SemIR::LocId(class_info.definition_id), "generic union")` and the
    witness is `SemIR::ErrorInst::InstId` (D-UN-3; the error-witness
    precedent is `CheckCompleteAdapterClassType` returning
    `ErrorInst::InstId` :56-114, after which `GetObjectRepr` yields
    `ErrorInst::TypeId`, sem_ir/class.cpp:39-53); (ii) build the field
    list with `AddStructTypeFields` (this also assigns each
    `Field::index`, :121-123, which `ClassElementAccess` and the
    byte-offset GEP index by); (iii) if `field_decls.empty()` →
    `UnionWithoutFields` at the definition (unions.md:151, F-007i) →
    error witness; (iv) for every field whose type is not `ErrorInst`:
    `IsTriviallyDestructible(context, element_type)` else
    `UnionFieldNotTriviallyCopyable` at `SemIR::LocId(field_decl_id)`
    naming the field and its type — ALL offending fields are reported,
    then the witness is the error witness; an `ErrorInst`-typed field
    (already diagnosed) also yields the error witness; (v) otherwise
    `size = max(field.size)`, `align = max(field.alignment)` from
    `GetCompleteTypeInfo(type).object_layout` (fields are complete at
    their declaration — the class-field `IncompleteTypeInBindingDecl`
    rule — and the union is non-generic by (i), so `has_value()` is
    CHECKed, the eval_inst.cpp:327-330 posture), the layout block is
    `[size.AlignedTo(align), align, 0 × n]` (handle_choice.cpp:817-823
    shape; unions.md:405-408), `AddTypeInst(node_id, CustomLayoutType{
    TypeType, fields_id, custom_layouts().Add(layout)})` and a
    `CompleteTypeWitness` over it (:835-841 shape). The design's layout
    rule is thereby literal: every field offset 0, `align(U)` = max,
    `size(U)` = max rounded up.
5.  **Designated initialization (D-UN-4), `ConvertStructToUnion` in
    convert.cpp:** static, called from `ConvertStructToClass` inside the
    :909-912 branch when `dest_class_info.is_union` (the non-union
    imported-C++ case keeps the bailout and its comment). Body, in
    order: (a) if `!target.is_initializer()`, form temporary storage
    exactly as :914-921 does; (b) source fields from `src_type.fields_id`;
    if their count is not exactly one → `UnionInitNotSingleField`
    (naming the union type and the count; `target.diagnose`-gated like
    :660-679) → `ErrorInst::InstId`; (c) look the one source field's
    name up in the repr's fields (`struct_type_fields().Get(custom_layout.fields_id)`)
    → not found → `UnionInitUnknownField` → error; (d) literal-versus-value
    source handling verbatim from :644-651 (`StructLiteral` elements
    used directly, else `MaterializeIfInitializer`); (e) `inner_kind =
    GetAggregateElementConversionTargetKind(sem_ir, target)` (:172) and
    `init_id = ConvertAggregateElement<SemIR::StructAccess,
    SemIR::ClassElementAccess>(context, loc, value_id,
    src_field.type_inst_id, literal_elems, inner_kind, target.storage_id,
    dest_field.type_inst_id, target.storage_access_block,
    /*src_index=*/0, /*dest_index=*/field_index)` (:207; the :794-798
    call shape); (f) `target.storage_access_block->InsertHere()` and
    `AddInst<SemIR::ClassInit>(loc, {target.type_id,
    inst_blocks().Add({init_id}), target.storage_id})`. Zero-field and
    two-field literals therefore never reach element conversion, and
    `{.word = "text"}` diagnoses the ordinary element `ConversionFailure`.
    `EvalConstantInst(ClassInit)` (eval_inst.cpp:180-186, whose
    `Context&` parameter is currently unused) gains the union check
    first: `TryGetAs<SemIR::ClassType>(inst.type_id)` → `is_union` →
    `ConstantEvalResult::NotConstant` (eval_inst.h:44, :92-93), with the
    D-UN-4 comment. Consequence pinned by §4.A: a `var v: U = {.word =
    5};` lowers to one `store i32 5` through a byte-offset GEP; no
    `@U.val`-style template global exists for any union.
6.  **Copy and destroy.** `LookupChoiceCopyWitness` (custom_witness.cpp:936-967)
    gate widened per D-UN-5 (the :921-935 comment gains the union
    sentence and the `is_cpp_scope` rationale); the function keeps its
    name. Destroy needs no code: `CanDestroyClass` (:151-208) reaches
    the repr walk, whose `CustomLayoutType` case (:314-333) already
    mirrors the struct walk. `IsTriviallyDestructible` gains the
    `CustomLayoutType` arm (push every field type; between the
    `StructType` and `TupleType` arms, :583-598) — needed for nested
    unions under D-UN-2 and for UN-2's trivial-union export. Comment
    refreshes at :315-318 and import_ref.cpp:4188-4189 ("today, the
    payload region of a payload-carrying choice" → "... or the object
    representation of a native `union`").
7.  **Diagnostics: exactly four new kinds, one site each** (kind.def
    entries beside the class/choice block):
    -   `UnionWithoutFields` (Error): "union `{0}` must declare at
        least one field" (`SemIR::NameId`).
    -   `UnionFieldNotTriviallyCopyable` (Error): "union field `{0}`
        has type {1}, which is not trivially copyable and destructible"
        (`SemIR::NameId`, `InstIdAsType`).
    -   `UnionInitNotSingleField` (Error): "initializer for union {0}
        must designate exactly one field; found {1}" (`SemIR::TypeId`,
        `int`).
    -   `UnionInitUnknownField` (Error): "union {0} has no field named
        `{1}`" (`SemIR::TypeId`, `SemIR::NameId`).
        Everything else reuses landed diagnostics (D-UN-6) or
        `SemanticsTodo` (`generic union`, `union export`).
8.  **Lowering: zero code.** `[N x i8]` type, byte-offset GEPs, in-place
    `ClassInit`, `PrimitiveCopy` memcpy and the destroy no-op all exist
    (§0.1 rows 4, 8, 9). The lower goldens are pins, not drivers.
9.  **Modifiers on the declaration:** `private`/`protected` follow the
    class rules (`CheckAccessModifiersOnDecl`); `extern` follows the
    class path (its `extern library` TODO :193-196 included) so the two
    kinds stay one code path; `abstract`/`base` are the only class
    modifiers removed (D-UN-6).

### §1.B UN-2 — C++ union interop

1.  **Import marking:** `BuildClassDefinition` (import.cpp:939-962)
    sets `class_info.is_union = clang_def->isUnion();` beside
    `inheritance_kind` (:950). The empty-aggregate special case (:651-664,
    `union Bar {}` → `StructType{}` repr) is untouched: D-UN-4's arm is
    inside the `CustomLayoutType` branch, so `var b: Cpp.Bar = {};` keeps
    its landed behavior (§4.B `empty_init`). With the flag set, designated
    init of an imported union is UN-1's `ConvertStructToUnion` unchanged
    — the design's "identically to native unions" (unions.md:486-488).
    Copy of an imported union stays on `LookupCppImpl`'s C++ copy
    constructor (D-UN-5's exclusion), so a union with a non-trivial
    member keeps C++'s deletion.
2.  **Export as a genuine union:** export.cpp:76-79 passes
    `class_info.is_union ? clang::TagTypeKind::Union :
    clang::TagTypeKind::Class` and the UN-1 TODO guard is deleted.
    `Class::GetStructTypeFields` (sem_ir/class.cpp:55-72) returns the
    `fields_id` of a `CustomLayoutType` repr as it does for a
    `StructType` (both carry `StructTypeFieldsId`) — its two callers
    (export.cpp:550, read_only_ast_source.cpp:22) then enumerate union
    fields correctly. `CalculateCppFieldOffsets` (read_only_ast_source.cpp:15-49):
    for `is_union`, every `FieldDecl` gets offset 0 and `class_layout`
    is not advanced (D-UN-8); `layoutRecordType` (:51-90) needs no change
    — size/alignment already come from `GetCompleteTypeInfo(class)`,
    which for a union is the `CustomLayoutType` block. `CompleteType`
    (generate_ast.cpp:427-540): skip the `FinalAttr` for `is_union`
    (:452-457, D-UN-8); the destructor decision (:486-497) needs no
    change — `IsTriviallyCopyableForExport` → `IsTriviallyDestructible`
    now walks the `CustomLayoutType` repr (UN-1) and answers true for
    every 0.1 union, so no destructor thunk is declared and Clang's
    implicit special members stay trivial (unions.md:502-505). Methods
    export as for classes (`ExportAllFieldsToCpp` :483-484 then the
    vtable loop, which is empty).
3.  **Round-trip guarantee (unions.md:507-514)** is what the two
    conformance programs execute: C++ writes / Carbon reads and Carbon
    writes / C++ reads, by pointer, both directions, with a compile-time
    `static_assert(sizeof/alignof/__is_union)` in the inline C++ block
    as the layout arbiter.
4.  **Zero new diagnostics in UN-2.** The negative pins reuse landed
    kinds (§4.B).

## §2 Implementation spec

### §2.A UN-1 (file by file)

1.  **toolchain/lex/token_kind.def:175** — the one line (§1.A.1).
2.  **toolchain/parse/node_kind.def** (after :425), **typed_nodes.h**
    (after :1607), **node_ids.h** (:172-177 + `AnyUnionDeclId`),
    **state.def** (:425, :441, :1553-1578 + comment blocks),
    **handle_type.cpp**, **handle_decl_definition.cpp** (:25-31, + two
    handlers), **handle_decl_scope_loop.cpp** (:49-54, :72-84, :138-150,
    :227-240, :320-356), **handle_statement.cpp** (:59-60) — §1.A.2.
3.  **toolchain/sem_ir/class.h:85** — `is_union`; **check/import_ref.cpp:2019**
    — mirror.
4.  **toolchain/check/class.h / class.cpp** — `BuildClassOrUnionDecl`
    (moved from handle_class.cpp with the `decl_kind` parameter),
    `ComputeUnionObjectRepr` (§1.A.4). **handle_class.cpp** — the class
    callers keep the pops and delegate; `MergeOrAddName`/`MergeClassRedecl`
    take `decl_kind`. **handle_union.cpp (new)** — four handlers (§1.A.3).
    **check/BUILD** — add `handle_union.cpp`.
5.  **toolchain/check/convert.cpp:909-912** — the `is_union` branch and
    `ConvertStructToUnion` (§1.A.5). **eval_inst.cpp:180-186** — the
    `NotConstant` return (D-UN-4).
6.  **toolchain/check/custom_witness.cpp** — :944 gate (D-UN-5);
    `CustomLayoutType` arm in `IsTriviallyDestructible` (:583-598);
    comment refresh :315-318.
7.  **toolchain/check/cpp/export.cpp:60-91** — the two-line union TODO
    guard (D-UN-7).
8.  **toolchain/diagnostics/kind.def** — four kinds (§1.A.7).
9.  **Docs and grammars:** docs/design/unions.md dated amendments
    (§8.6); docs/design/lexical_conventions/words.md keyword list
    (`union` between `type` and `var`, :101-102); utils/vim/syntax/carbon.vim:40
    (a `carbonUnionDeclaration` line mirroring `choice`),
    utils/vscode/carbon.tmLanguage.json:369 and
    utils/textmate/Syntaxes/carbon.tmLanguage:488 (add `union` to the
    introducer alternation), utils/textmate/Samples/keywords.carbon:17,
    utils/tree_sitter/queries/highlights.scm:94 (after `"choice"`).
10. **No BUILD changes beyond check/BUILD; no CI or workflow changes.**

### §2.B UN-2 (file by file)

1.  **toolchain/check/cpp/import.cpp:950** — `is_union` (§1.B.1).
2.  **toolchain/check/cpp/export.cpp:60-91** — delete the guard;
    :76-79 `TagTypeKind` (§1.B.2).
3.  **toolchain/sem_ir/class.cpp:55-72** — `GetStructTypeFields` over
    `CustomLayoutType`. **toolchain/sem_ir/read_only_ast_source.cpp:15-49**
    — union offset arm.
4.  **toolchain/check/cpp/generate_ast.cpp:452-457** — no `FinalAttr`
    for unions.
5.  **Docs:** unions.md:278-283 implementation note → landed (§8.6).

## §3 Commit structure

**UN-1 (PR "UN-1: native `union` declaration"), four commits:**

1.  lex + parse (keyword, node kinds, states, `UnionContext`) + the
    parse goldens of §4.A (CHECK-free) + grammar files.
2.  check + sem_ir (`is_union`, `BuildClassOrUnionDecl`,
    `handle_union.cpp`, `ComputeUnionObjectRepr`, `ConvertStructToUnion`,
    fold suppression, copy gate, triviality arm, export guard, kind.def).
3.  check + lower goldens of §4.A (AUTOUPDATE, empty CHECK lines,
    R15/R19) + §5.A conformance (union_basic rewritten, the differential
    pair) + gap-analysis row 45 PARTIAL + ledger.
4.  discharge: decision-log entry, doc amendments (§8.6), words.md,
    ORCHESTRATION stamp, residue items (ids allocated then, §8.5).

**UN-2 (PR "UN-2: C++ union interop"), three commits (after EH-B
merges; rebase first):**

1.  import `is_union` + export (`TagTypeKind::Union`, `GetStructTypeFields`,
    offset arm, no `FinalAttr`, guard deleted).
2.  §4.B goldens (the UN-1 `fail_export_todo` subfile deleted — its pin
    was the UN-1 placeholder, R16(b) citation: D-UN-7) + §5.B
    conformance + gap-analysis row 45 DONE + ledger.
3.  discharge: decision-log entry, doc amendment, ORCHESTRATION stamp.

## §4 Testdata matrix (R16: no hand-written goldens; autoupdate fills)

Every new file ships with `AUTOUPDATE` and no CHECK lines; every
prediction below is what the hosted autoupdate must show, hand-traced
from the code paths cited, for the reviewers to compare against the
fill. Diagnostic kinds are spelled exactly as their `CARBON_DIAGNOSTIC`
names; message text is quoted from §1.A.7 or the cited landed site. No
testdata identifier is a reserved word (`CARBON_KEYWORD_TOKEN` list,
token_kind.def:157-241); `union` appears only as the keyword or as
`r#union`.

### §4.A UN-1

-   **parse/testdata/union/basic.carbon** — `union IntOrBytes { var
    word: u32; var bytes: array(u8, 4); fn LowByte(self) -> u8 { return
    self.bytes[0]; } }`. Predicted tree: `UnionIntroducer 'union'`,
    `IdentifierNameNotBeforeSignature 'IntOrBytes'`, `UnionDefinitionStart
    '{'`, two `VariableDecl` subtrees, one `FunctionDefinition` subtree,
    `UnionDefinition '}'` (the class/basic.carbon shape with the four
    kinds renamed).
-   **parse/testdata/union/forward_decl.carbon** — `union U;` then a
    definition: predicted `UnionDecl ';'` for the first, the definition
    triple for the second (covers the fourth node kind).
-   **parse/testdata/union/generic.carbon** — `union Slot(T: type) {
    var value: T; var next_free: Slot(T)*; }` parses (the parameter list
    rides `DeclNameAndParams`, handle_type.cpp:15-17); the TODO is
    check-side.
-   **parse/testdata/union/member_and_local.carbon** — a union as a
    class member and a union declared inside a function body
    (`handle_statement.cpp` dispatch); both parse.
-   **parse/testdata/union/fail_missing_definition.carbon** — `union U`
    at EOF: predicted `ExpectedDeclSemiOrDefinition` ("`union`
    declarations must either end with a `;` or have a `{ ... }` block
    for a definition" — the class/fail_modifiers.carbon:14 text with
    `union`), `UnionDecl` node with error.
-   **parse/testdata/union/fail_members.carbon** — subfiles
    `fail_nested_class` (`union U { class C {} }`), `fail_nested_choice`,
    `fail_nested_union`, `fail_adapt` (`adapt i32;`), `fail_base`
    (`extend base: B;`), `fail_interface`: each predicted `UnrecognizedDecl`
    "unrecognized declaration introducer" at the inner introducer
    (handle_decl_scope_loop.cpp:27-34) with `InvalidParseStart`/
    `InvalidParseSubtree` recovery to the `;`/`}` (:15-25) — D-UN-6.
-   **check/testdata/union/basic.carbon** (`INCLUDE-FILE:
    toolchain/testing/testdata/min_prelude/full.carbon`,
    `//@dump-sem-ir` ranges on positives). Subfiles:
    `declare_and_access` — `union IntOrBytes { var word: i32; var
    bytes: array(i8, 4); }`, `fn Read(u: IntOrBytes) -> i32 { return
    u.word; }`, `fn Write(p: IntOrBytes*) { p->word = 1; }`: predicted
    `%IntOrBytes: type = class_type @IntOrBytes`, the class's
    `complete_type_witness` over a `custom_layout_type` constant that
    formats as `size=4, align=4` with two zero field offsets
    (sem_ir/formatter.cpp:1171-1178), `class_element_access %u.ref,
    element0`; `unformed_then_assign` — `var u: IntOrBytes; u.word = 5;
    return u.word;` (no `Unformed` interface is consulted: check/testdata/
    class/fail_incomplete.carbon:157 shows a plain `var c: C;` on a
    class); `designated_init` — `var v: IntOrBytes = {.word = 5};` and
    `var b: IntOrBytes = {.bytes = (1, 2, 3, 4)};`: predicted ONE
    `class_element_access %v.var, element0` (resp. `element1`), the
    element's in-place initializer, `class_init (%...), %v.var` with ONE
    element, and NO `struct_value` constant of type `%IntOrBytes` anywhere
    in the dump (D-UN-4's falsifier is exactly such a line);
    `return_designated` (`fn Make() -> IntOrBytes { return {.word = 7};
    }` — the `class_init` targets `%return`), `let_designated` (temporary
    storage then the binding); `from_struct_value` (`var s: {.word:
    i32} = {.word = 1}; var v: IntOrBytes = s;` — `struct_access %s,
    element0` feeds the element init); `copy` (`var w: IntOrBytes = v;`
    → a `Core.Copy` witness call: predicted `%.loc: init %IntOrBytes =
    call %Op.ref(%v.ref) to %w.var` with the primitive-copy builtin as
    in check/testdata/choice/alternative_copy.carbon); `method` (`fn
    LowHalf(self) -> i32 { return self.bytes[0] as i32; }` and `fn
    Set(ref self, x: i32) { self.word = x; }`); `impl_member` (an
    `impl as Core.Default`-free interface impl inside the union body —
    a user interface `I` with `fn Get(self) -> i32`, pins `impl` as a
    permitted member); `forward_decl` (`union U;` ... `union U { var a:
    i32; }` merges: one `class_decl`, no diagnostic); `member_of_class`
    (`class C { union Inner { var a: i32; } var u: Inner; }`);
    `raw_identifier` (`var r#union: i32 = 1;` compiles — F-007h);
    `nested_union_field` (`union Outer { var inner: IntOrBytes; var w:
    i64; }` — the `IsTriviallyDestructible` `CustomLayoutType` arm;
    predicted accepted, `size=8, align=8`); `aggregate_fields` (a struct
    field `{.a: i32, .b: i32}`, a tuple field `(i32, i16)`, a pointer
    field, a `bool` field — all accepted); `optional_pointer_field` (`var
    p: Core.Optional(i32*);` — predicted ACCEPTED through the adapter walk
    custom_witness.cpp:555-566 into `MaybeUnformed(i32*)`,
    optional.carbon:180-185; D-UN-2's break condition if not).
-   **check/testdata/union/layout.carbon** — `union Wide { var lo: i32;
    var both: i64; }` → `size=8, align=8`; `union Odd { var a: i8; var b:
    i16; var c: array(i8, 3); }` → `size=4, align=2` (max size 3 rounded
    up to alignment 2); `union OneByte { var b: bool; }` → `size=1,
    align=1`; `union Ptr { var p: i32*; var n: i64; }` → `size=8,
    align=8`.
-   **check/testdata/union/import.carbon** — `// --- lib.carbon`
    declares `IntOrBytes` and a function taking it; `// --- use.carbon`
    imports the library, designated-inits, reads a field and copies:
    predicted the imported `class_decl` with the resolved
    `custom_layout_type` (import_ref.cpp:4187-4233) and the same
    `class_init`/`class_element_access` shapes — pins the `is_union`
    mirror (a missing mirror would take the :909-912 bailout and diagnose
    `ConversionFailure`).
-   **check/testdata/union/fail_no_fields.carbon** — `union Empty {}` and
    `union OnlyFns { fn F() {} }`: predicted `UnionWithoutFields` at each
    definition ("union `Empty` must declare at least one field").
-   **check/testdata/union/fail_nontrivial_field.carbon** — a class
    `Boxy` with `impl as Core.Destroy` as a field type; a `str` field; a
    choice-typed field (`choice Signal { Go(speed: i32), Stop }` → `var s:
    Signal;` — the D-UN-2(i) residue, comment cites it): each predicted
    `UnionFieldNotTriviallyCopyable` at the field ("union field `b` has
    type `Boxy`, which is not trivially copyable and destructible"); a
    subfile with TWO bad fields shows two diagnostics (§1.A.4 (iv)
    reports all).
-   **check/testdata/union/fail_todo_generic.carbon** — `union Slot(T:
    type) { var value: T; var next_free: Slot(T)*; }` and `class Box(T:
    type) { union U { var a: i32; } }`: predicted `SemanticsTodo`
    "semantics TODO: `generic union`" at each definition (D-UN-3).
-   **check/testdata/union/fail_init.carbon** — `{.word = 1, .bytes =
    (0, 0, 0, 0)}` → `UnionInitNotSingleField` ("... must designate
    exactly one field; found 2"); `{}` → the same with "found 0";
    `{.nope = 1}` → `UnionInitUnknownField` ("union `IntOrBytes` has no
    field named `nope`"); `{.word = "text"}` → the landed element
    `ConversionFailure`; `var u: IntOrBytes = 5;` → landed
    `ConversionFailure` (no `ImplicitAs` — unchanged path).
-   **check/testdata/union/fail_modifiers_and_redecl.carbon** —
    `abstract union A { var a: i32; }` → `ModifierNotAllowedOnDeclaration`
    ("`abstract` not allowed on `union` declaration", modifiers.cpp:102-105);
    `base union B {...}` → the same with `base`; `union V { var a: i32;
    virtual fn F[self: Self](); }` → `ModifierVirtualNotAllowed`
    ("`virtual` not allowed; requires `abstract` or `base` class scope")
    with its `ModifierNotInContext` note; `class C; union C { var a:
    i32; }` → `NameDeclDuplicate` + `NameDeclPrevious`; `union D { var a:
    i32; } union D { var a: i32; }` → `RedeclRedef` "redefinition of
    `union D`" + `RedeclPrevDef` (merge.cpp:35-37).
-   **check/testdata/union/fail_todo_export.carbon** (UN-1 only; deleted
    at UN-2) — `import Cpp;` + `union U { var a: i32; }` + `inline Cpp
    ''' Carbon::U u; '''`: predicted `SemanticsTodo` "semantics TODO:
    `union export`" (D-UN-7) followed by whatever Clang reports for the
    unresolved name; the pin is the TODO line, and the falsifier is a
    CHECK failure in `GetStructTypeFields` (§7 R-9).
-   **lower/testdata/union/basic.carbon** (full prelude) — subfiles
    mirroring `unformed_then_assign`, `designated_init`, `copy`,
    `method`, `by_pointer`. Predicted IR: `%u.var = alloca [4 x i8],
    align 4`; field access `getelementptr inbounds nuw [4 x i8], ptr
    %u.var, i32 0, i32 0` for BOTH `word` and `bytes` (offset 0 each —
    the field.carbon:229 shape), `store i32 5, ptr %..., align 4` for
    the designated init with NO `@IntOrBytes.val`/`llvm.memcpy` from a
    constant global (D-UN-4), `llvm.memcpy.p0.p0.i64(ptr align 4 %w.var,
    ptr align 4 %v.var, i64 4, i1 false)` for the copy (`CopyObject`),
    and the method thunk-free `define ... @_CLowHalf.IntOrBytes.Main(ptr
    %self)` reading `getelementptr ... i32 0, i32 0` then indexing the
    `[4 x i8]` array element.
-   **lower/testdata/union/layout.carbon** — `Wide`: `alloca [8 x i8],
    align 8`, `store i32` and `store i64` both at GEP `i32 0, i32 0`;
    `Odd`: `alloca [4 x i8], align 2`.
-   **Hand-traced predictions the reviewers check against the
    autoupdate:** (1) no pre-existing golden moves (§6.A); (2) no
    `struct_value` of a union type in any check dump; (3) every union
    field GEP has trailing indices `i32 0, i32 0`; (4) `define i32
    @_CRead.Main(ptr %u)` — a union parameter is passed as a pointer
    (pointer value repr, type_completion.cpp:787-796), as
    `access_union.carbon`'s `@_CAccessN.Main(ptr %a)` already shows.

### §4.B UN-2

-   **check/testdata/interop/cpp/class/import/union.carbon** — new
    subfiles appended to the landed file: `designated_init` (`union Pair
    { int a; int b; };` → `var u: Cpp.Pair = {.a = 1}; return u.b;` —
    predicted the UN-1 shapes: `class_element_access ... element0`,
    one-element `class_init`); `empty_init` (`union Bar {};` → `var b:
    Cpp.Bar = {};` — unchanged `StructType{}` path, accepted);
    `fail_init_two_fields` → `UnionInitNotSingleField`;
    `fail_init_unknown_field` → `UnionInitUnknownField`; `copy` (`var b:
    Cpp.Pair = a;` — the C++ copy constructor path, `BuildCopyWitness`,
    unchanged; predicted a call to the imported copying constructor thunk
    as in check/testdata/interop/cpp/impls/copy.carbon);
    `fail_copy_nontrivial_member` (`struct NT { NT(const NT&); int x; };
    union U { NT nt; int i; };` → `var b: Cpp.U = a;` — C++ deletes `U`'s
    copy constructor; predicted an ERROR at the copy — the exact kind is
    decided by the fill (the landed path reaches `LookupCopyingConstructor`
    and the deleted-function handling); the pin is that it is not a
    `PrimitiveCopy`, D-UN-5's exclusion).
-   **check/testdata/interop/cpp/class/export/union.carbon** (new) —
    `union Wide { var lo: i32; var both: i64; fn Low(self) -> i32 {
    return self.lo; } }` + `import Cpp;` + `inline Cpp '''
    static_assert(__is_union(Carbon::Wide), "kind");
    static_assert(sizeof(Carbon::Wide) == 8 && alignof(Carbon::Wide) ==
    8, "layout"); int Use(Carbon::Wide* w) { w->lo = 3; return w->Low();
    } '''`: predicted a clean compile, the `imports` block showing the
    `Cpp.Use` thunk with a `Carbon::Wide*` parameter, and no destructor
    thunk decl for `Wide` (`IsTriviallyCopyableForExport` true — the
    trivially_copyable.carbon:1-40 posture).
-   **lower/testdata/interop/cpp/class/export/union.carbon** — the
    exported method thunk and `Use` reading through `[8 x i8]` at offset 0.
-   **lower/testdata/interop/cpp/class/import/union_init.carbon** —
    designated init of `Cpp.Pair`: `alloca [8 x i8]`, `store i32` at GEP
    `i32 0, i32 0`.
-   **Deleted:** check/testdata/union/fail_todo_export.carbon (its TODO
    string leaves the tree with the guard; §8.4 grep).
-   **Hand-traced predictions:** the `static_assert`s compile (D-UN-8's
    arbiter); `__is_union` is true only because `TagTypeKind::Union` was
    used; no pre-existing interop golden moves (§6.B).

## §5 Conformance

All under bullet "Type system: Unions (un-discriminated) + C++ union
mapping" (fork/gap-analysis.md:45; R7: exact string; `runner.py
--self-test` before every commit that touches programs). Harness
conventions (fork/w077/plan.md §5): runtime inputs through
`fn RuntimeSeed(x: i32) -> i32 { return x + 20; }` so nothing constant
folds (R16(d)); EXPECT values hand-derived below from the design's
byte-reinterpretation rule (unions.md:304-352) on the V-1 little-endian
targets (x86-64 Linux, arm64 macOS); `Core.Print(x: i32)` only
(core/io.carbon:12; R1); narrowing/widening spelled with `as`
(core/prelude/types/int.carbon:70 `Int(From) as As(Int(To))`).

### §5.A UN-1 — one SKIP→PASS, one new pair; floor **108 PASS / 0 FAIL / 27 SKIP over 135** (tree-relative)

1.  **types/union_basic.carbon — body REPLACED (SKIP → PASS).** Header
    keeps the bullet line verbatim; `EXPECT-EXIT: 0`; the SKIP line and
    the strawman are deleted (the un-SKIP discloses, per R6's F8d
    template, that the stub's `Cpp.CppIntBytes` half moves to §5.B where
    the importer's field mapping is verified). Program:

    ```carbon
    import Core library "io";

    union IntOrBytes {
      var word: i32;
      var bytes: array(i8, 4);
    }

    union Wide {
      var lo: i32;
      var both: i64;
      fn Low(self) -> i32 { return self.lo; }
    }

    fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

    fn Run() -> i32 {
      // Unformed-then-assign (F-007d).
      var u: IntOrBytes;
      u.word = RuntimeSeed(22);
      Core.Print(u.word);
      // Designated single-field init (F-007d); word = 0x01020304.
      var v: IntOrBytes = {.word = RuntimeSeed(16909040)};
      Core.Print(v.bytes[0] as i32);
      Core.Print(v.bytes[3] as i32);
      // Whole-union copy is all size(U) bytes (unions.md:271-276).
      var w: IntOrBytes = v;
      w.bytes[0] = 9;
      Core.Print(w.word - v.word);
      // Method; i64 write, i32 read of the low half.
      var x: Wide;
      x.both = RuntimeSeed(-15) as i64;
      Core.Print(x.Low());
      return 0;
    }
    ```

    EXPECT-STDOUT, hand-derived: `42` (22 + 20); `4` and `1` (the
    little-endian bytes of 0x01020304 at offsets 0 and 3); `5`
    (0x01020309 − 0x01020304 after the copy and the byte write — a
    partial copy would print 0x01020309 − garbage, not 5); `5` (the low
    32 bits of the i64 value 5). Five lines.
2.  **types/union_pun_diff.carbon + .diff.cpp (new pair; DIFF-1: no
    EXPECT-STDOUT, the C++ oracle arbitrates).** The Carbon side prints
    all four bytes of a seeded `word` through `bytes`, then splits a
    seeded i64 `both = (RuntimeSeed(-13) as i64) * 4294967296 +
    (RuntimeSeed(-11) as i64)` through `union Wide { var lo: i32; var
    both: i64; var halves: array(i32, 2); }` as `lo` and `halves[1]`.
    The C++ oracle holds the same values in `int`/`long long` and reads
    them back with `std::memcpy` into the read types (defined C++ — the
    oracle must not itself lean on union-member UB), printing with
    `printf("%d\n")` (the choice_discriminant_diff.diff.cpp:1-40
    conventions). Independent derivation for the reviewer: `4 3 2 1`
    then `9` and `7`.

Zero landed programs move: no program in fork/conformance/programs
declares a `union` or spells `union` as an identifier (§1.A.1 grep), and
UN-1 changes no diagnostic a landed program triggers.

### §5.B UN-2 — two new programs; floor **110 PASS / 0 FAIL / 27 SKIP over 137** (tree-relative)

1.  **types/union_cpp_import.carbon (new)** — `import Cpp inline '''c++
    union Pair { int a; int b; int* p; }; struct Tagged { int kind; union
    { int i; float f; }; }; inline void WriteA(Pair* u, int v) { u->a = v;
    } inline Tagged MakeTagged(int v) { Tagged t; t.kind = 1; t.i = v;
    return t; } static_assert(sizeof(Pair) == 8, "layout"); ''';`
    then: `var u: Cpp.Pair = {.a = RuntimeSeed(22)}; Core.Print(u.b);`
    (designated init on an imported union — the UN-2 deliverable — read
    back through the other `int` member: 42, defined by Carbon's read
    rule); `Cpp.WriteA(&u, RuntimeSeed(-15)); Core.Print(u.a);` (C++
    writes, Carbon reads: 5); `let t: Cpp.Tagged =
    Cpp.MakeTagged(RuntimeSeed(-13)); Core.Print(t.i);` (anonymous-union
    member flattened on import: 7). EXPECT-STDOUT: `42`, `5`, `7`.
2.  **types/union_cpp_export.carbon (new)** — `import Cpp;` + `union
    Wide { var lo: i32; var both: i64; fn Low(self) -> i32 { return
    self.lo; } }` + `inline Cpp ''' static_assert(__is_union(Carbon::Wide),
    "kind"); static_assert(sizeof(Carbon::Wide) == 8 &&
    alignof(Carbon::Wide) == 8, "layout"); int RoundTrip(int v) {
    Carbon::Wide w; w.lo = v; return w.Low(); } void WriteBoth(Carbon::Wide*
    w, int hi, int lo) { w->both = (static_cast<long long>(hi) << 32) |
    static_cast<unsigned>(lo); } '''`; then `Core.Print(Cpp.RoundTrip(RuntimeSeed(22)));`
    (C++ constructs, writes and calls the exported method: 42); `var w:
    Wide; Cpp.WriteBoth(&w, RuntimeSeed(-13), RuntimeSeed(-11));
    Core.Print(w.lo); Core.Print((w.both / 4294967296) as i32);` (C++
    writes the 64-bit member, Carbon reads the low half through `lo` —
    defined by Carbon's rule — and the high half arithmetically: 9, 7).
    EXPECT-STDOUT: `42`, `9`, `7`. The `static_assert`s are the compile-time
    layout arbiter (D-UN-8); a wrong `TagTypeKind` fails `__is_union`, a
    wrong layout fails `sizeof`, both as COMPILE-FAIL — loud.

The bullet's runner status flips SKIP → PASS at UN-1 (44/56 bullets);
`gap_status` follows the gap-analysis row (PARTIAL at UN-1, DONE at UN-2,
§8.6). `runner.py --update-readme-table` refreshes the README table at
each discharge.

## §6 Churn inventory (verified by grep at e78db5df4)

### §6.A UN-1

-   **Existing goldens that move: NONE predicted.** The keyword adds a
    token kind: no golden prints token-kind numbers; lex/testdata/
    keywords.carbon:22 is a fixed chain, not an enumeration; the
    `LexerTest.Keywords` sweep is a unit test. No Carbon source uses
    `union` as an identifier (§1.A.1). `EvalConstantInst(ClassInit)`'s
    new branch, the copy-witness gate, the `IsTriviallyDestructible`
    arm (reachable today only through a class field whose repr is a
    `CustomLayoutType` — none exists: imported classes return early at
    :531-534 and choices at :535-538), the export guard and the
    `DeclIntroducers` fourth column all key on `is_union` or on parse
    contexts no existing input enters. The `BuildClassOrUnionDecl`
    refactor is behavior-preserving for `decl_kind == Class`.
-   **Falsifier:** any pre-existing file in the autoupdate diff is a
    plan miss — stop and reconcile before gating (the R26 loc-number
    rule does not apply: no file gains lines above existing code).
-   Source files touched: 22 — (1) lex/token_kind.def; (2)
    parse/node_kind.def; (3) parse/typed_nodes.h; (4) parse/node_ids.h;
    (5) parse/state.def; (6) parse/handle_type.cpp; (7)
    parse/handle_decl_definition.cpp; (8) parse/handle_decl_scope_loop.cpp;
    (9) parse/handle_statement.cpp; (10) sem_ir/class.h; (11)
    check/import_ref.cpp; (12) check/class.h; (13) check/class.cpp;
    (14) check/handle_class.cpp; (15) check/handle_union.cpp (new);
    (16) check/BUILD; (17) check/convert.cpp; (18) check/eval_inst.cpp;
    (19) check/custom_witness.cpp; (20) check/cpp/export.cpp (two
    lines); (21) diagnostics/kind.def; (22) docs/design/unions.md — plus
    words.md and the five grammar files.

### §6.B UN-2

-   **Existing goldens that move: NONE predicted.** `is_union` on import
    changes behavior only where a struct literal meets a `CustomLayoutType`
    union repr (no landed test does — the only imported-class
    struct-literal test is non_aggregate_init.carbon's `{}` on structs);
    `TagTypeKind::Union`, the offset arm and the `FinalAttr` skip key on
    `is_union`; `GetStructTypeFields`'s widening is a no-op for every
    `StructType` repr; `ExportAllFieldsToCpp`/`CalculateCppFieldOffsets`
    run only for Carbon-owned classes (`GetAsCarbonOwnedClass`), never
    for imported ones.
-   Source files touched: 6 — check/cpp/import.cpp, check/cpp/export.cpp,
    check/cpp/generate_ast.cpp, sem_ir/class.cpp,
    sem_ir/read_only_ast_source.cpp, docs/design/unions.md. Contention
    with EH-B: import.cpp and export.cpp only, both single-hunk
    additive — rebase after EH-B merges (§0.4).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — the fold suppression misses a path and a union constant
    reaches lowering.** Paths audited: `ClassInit` (suppressed); a
    `StructValue`/`ClassValue` of union type can otherwise arise only
    from `ConvertStructToStructOrClass`'s value target, which the union
    arm never calls; `let u: U = {...}` materializes a temporary
    (`ConvertStructToClass` :914-921) so it is a `ClassInit` too. Falsifier:
    a `struct_value ... [concrete]` of a union type in any §4.A dump, or
    a CHECK in `EmitAsConstant(StructValue)` (`cast<llvm::StructType>`).
    Contingency: extend the suppression to the missed producer; never a
    lowering arm that invents a constant spelling for overlapping fields.
-   **R-2 — a one-element `ClassInit` trips an element-count invariant.**
    Consumers audited: `EmitAggregateInitializer` iterates elements
    (aggregate.cpp:207-232); `FindStorageArgForInitializer` reads
    `dest_id`; `EvalConstantInst(ClassInit)` is suppressed; no
    `Verify` pass counts elements against the repr (`grep -n elements_id
    toolchain/sem_ir/file.cpp` finds no such check). Falsifier: a
    CHECK/crash on the `designated_init` subfiles. Contingency: cover the
    remaining fields with `InPlaceInit(UninitializedValue)` ORDERED
    BEFORE the designated element and prove the zero store precedes the
    value store in the lower golden — a documented second choice, not a
    silent fallback.
-   **R-3 — `IsTriviallyDestructible` rejects a design-permitted field
    type.** Predicted accepted: scalars, pointers, arrays, tuples,
    structs, non-choice classes without `Destroy` impls, nested unions,
    `Optional(T*)`. Predicted rejected (recorded): choice-typed fields,
    `str`. Falsifier: `optional_pointer_field` or `aggregate_fields`
    diagnosing. Contingency: D-UN-2's break condition.
-   **R-4 — the copy-witness gate reaches imported unions.** Excluded by
    `is_cpp_scope`. Falsifier: `fail_copy_nontrivial_member` compiling
    clean or showing a `PrimitiveCopy` call.
-   **R-5 — `DeclIntroducers` table shape.** The `CARBON_TOKEN`
    initializer (:73-84) hard-codes one `Unrecognized` entry per context;
    a fourth entry and `MaxDeclContextKind` are mechanical, but a missed
    `set_contextual` leaves `var` unrecognized in a union body.
    Falsifier: parse/testdata/union/basic.carbon showing `UnrecognizedDecl`
    at `var`.
-   **R-6 — `SemIR::ClassDecl` location verification.** Its `Define<Parse::AnyClassDeclId>`
    accepts only the ids in that `NodeIdOneOf`; both union ids are added
    (§1.A.2). Falsifier: a location CHECK when `AddPlaceholderInst`
    builds the union's `class_decl`.
-   **R-7 — destroying a union local.** `CanDestroyClass` → repr walk →
    `CustomLayoutType` case over fields (all trivially destroyable by the
    field rule) → a placeholder `Destroy.Op` as for choices. Falsifier: a
    "does not implement `Core.Destroy`" diagnostic on `var u: IntOrBytes;`.
-   **R-8 — keyword fallout in the tree.** grep-verified empty (§1.A.1).
    Falsifier: any lex/parse/check golden moving with a `union`-related
    diagnostic.
-   **R-9 — UN-1 tree crashes on C++ export of a union.** Guarded by the
    D-UN-7 TODO before `GetStructTypeFields` can run (the export entry
    points at export.cpp:147, :279, :415 all pass through
    `ExportClassToCppInDeclContext`). Falsifier: `fail_todo_export` not
    showing the TODO or crashing.
-   **R-10 — pointer/i64 sizes in check-side layout.** `GetCompleteTypeInfo`
    gives target-independent sizes for `i64` (8) and pointers (8), as
    check/testdata/choice/payload_layout.carbon relies on without a
    `--target` flag; the lower goldens pin the x86_64 default target.
    Falsifier: `layout.carbon` printing `size=12` or `size=16` for `Ptr`.
-   **R-11 — export layout disagreement (UN-2).** Carbon supplies size,
    alignment and offset 0; Clang's record layout must accept them.
    Falsifier: the `static_assert`s in export/union.carbon or
    union_cpp_export.carbon failing (COMPILE-FAIL), or a Clang assertion
    in `ASTRecordLayoutBuilder` with the external source. Contingency:
    D-UN-8's rejected alternative (return `false` for unions) becomes the
    plan, recorded loudly as a two-regime exception.
-   **R-12 — EH-B contention (UN-2).** import.cpp/export.cpp hunks
    conflict textually with EH-B's. Rule: UN-2 rebases after EH-B
    merges; conflicts are resolved by rebase, never by reordering the
    PRs or landing UN-2 first. Falsifier: a UN-2 PR opened before EH-B's
    merge.
-   **R-13 — `Context::TODO` and generic unions.** The TODO fires at the
    `}` and the definition completes with an error witness, so stacks
    stay balanced and later uses diagnose incompleteness normally.
    Falsifier: a `VerifyOnFinish` CHECK after `fail_todo_generic`.
-   **R-14 — file-scope union variables with designated initializers**
    take the runtime-global-init path (a `NotConstant` initializer at
    file scope). Not exercised in 0.1; recorded as a residue rather than
    pinned (§8.5). Rejected alternative: allowing the fold for
    all-constant designated inits — it reintroduces R-1 for every
    constant literal.
-   **Rejected alternatives (not risks):** check-side rejection of nested
    types in unions (seven call sites for one diagnostic versus the
    upstream-precedented parse context, D-UN-6); the SF-6 allowlist as
    the field predicate (rejects the design's canonical example, D-UN-2);
    making the choice payload eval hook union-aware for generic unions
    (D-UN-3); a `Core.Storage` primitive (F-007 rejected it).

## §8 Verification and discharge

1.  **Regen (per PR):** `Fork: hosted verification` mode `autoupdate` to
    fixpoint (R26/R28(d): the gate's file_test pass proves it); expected
    churn is NEW files only (§6). Any pre-existing golden in the diff is
    a stop.
2.  **Gate:** mode `gate` green (prek + `bazel test //toolchain/...`;
    clang-format 21.1.8 per R18; `uvx prek run --files <changed>` locally
    before every push, R25). The parse coverage test is part of the gate
    (parse/BUILD:242-253).
3.  **Conformance:** mode `conformance`; UN-1 **108/0/27 over 135**,
    UN-2 **110/0/27 over 137** (both +2/+2 once W-012 merges);
    `runner.py --self-test` and `--update-readme-table` clean. Any other
    movement is a §5/§6 miss — stop and reconcile.
4.  **Reconciliation greps at discharge:** after UN-1, `grep -rn 'union
    export' toolchain` hits exactly the guard and its golden; after UN-2
    it is empty; `grep -rn 'generic union' toolchain` hits the
    `ComputeUnionObjectRepr` site and fail_todo_generic.carbon; `grep -rn
    'Builtin conversion does not apply' toolchain/check/convert.cpp`
    still hits once (the non-union imported-class bailout); `grep -rn
    'payload region of a payload-carrying choice' toolchain` shows the
    two refreshed comments.
5.  **Ledger edits (fork/inventory/work-items.json):**
    -   W-009 → kind `implemented`, evidence = token_kind.def line, the
        parse/check/lower goldens, union_basic + union_pun_diff; notes
        record §0.2 items 2-4 and D-UN-1..7 by name.
    -   W-015 → kind `implemented`, blocked_by cleared, evidence = the
        §4.B goldens and §5.B programs; notes record §0.2 items 5-8 and
        D-UN-8, and the sequencing after EH-B.
    -   W-007 → notes: "UN-2 landed additively after EH-B by rebase; the
        refactor-first precondition was met by sequencing".
    -   W-010 → notes: the W-009 coordination line gains "discharged at
        UN-1: native unions build on the S1 custom-layout pieces".
    -   **NEW residue items, referred to BY TITLE; ids allocated at
        discharge** by `grep -oE '"id": ?"W-[0-9]+"'
        fork/inventory/work-items.json | sort -t- -k2 -n | tail -1` on
        trunk at that moment (W-080..W-082 are being taken by W-012 and
        W-083+ by EH-B — never assume numbers): "union fields of choice
        type" (D-UN-2(i); mechanism: a per-payload triviality walk or the
        `CanDestroyClass` choice clause's SF-6 trust); "generic unions"
        (D-UN-3; mechanism named there); "union member-restriction
        diagnostics" (D-UN-6's parse-level message quality); "file-scope
        union variables" (R-14). Carbon-authored anonymous unions,
        bit-fields, non-trivial fields and debug-mode tracking are
        design-deferred (F-007f/g, unions.md:444-452, :239-241) and stay
        in the doc, not the ledger, unless a reviewer asks for items.
6.  **Docs:** docs/design/unions.md — dated amendments, history
    unrewritten: :84-88 (choice payloads landed at W-010; the sentence
    stays with a "landed" note); :116-117 (D-UN-3: "the 0.1 toolchain
    diagnoses `generic union`; the design intent stands"); :148-149
    (nested types rejected at parse in 0.1, D-UN-6); :217-226 (the 0.1
    predicate is `IsTriviallyDestructible`; choice-typed and `str` fields
    are conservatively rejected, D-UN-2); :278-283 (implementation note
    → "landed at UN-1 for native unions" then "and at UN-2 for imported
    unions"). words.md keyword list. README.md needs no change.
    **fork/gap-analysis.md:45** — UN-1: DESIGN-ONLY → **PARTIAL** with
    evidence "native `union` end to end (keyword, class-shaped body,
    all-offsets-zero `CustomLayoutType`, designated single-field init,
    unformed-then-assign, byte-copy, methods/impls; concrete unions
    only — generic unions TODO-gated; 2/2 conformance programs PASS);
    C++ side: designated init of imported unions, `is_union` marking and
    union export are UN-2 (W-015)"; header :17 27/19/8/2 → **27 DONE /
    20 PARTIAL / 8 MISSING / 1 DESIGN-ONLY**. UN-2: → **DONE** with
    evidence "+ imported unions construct by designated init and keep
    C++'s copy determination; Carbon unions export as `TagTypeKind::Union`
    with Carbon-supplied layout; round-trip programs in both directions
    PASS (4/4)"; header → **28 / 19 / 8 / 1**. R7: bullet TEXT untouched.
7.  **Decision log:** entries "UN-1: native `union` declaration (date)"
    and "UN-2: C++ union interop (date)" carrying D-UN-1..8 with break
    conditions, the §0.2 corrections verbatim, the V-3a divergence-register
    line (the `union` keyword and byte-reinterpretation reads are already
    F-007's; nothing new is minted), the residue items by title with the
    ids allocated at that discharge, and the R29(a) auto-adoption note.
    fork/ORCHESTRATION.md header and scoreboard line stamped per PR.

## Hand-off notes for the implementer

-   R27 first: diff every testdata `union` declaration against the
    design's spellings (unions.md:96-99, :110-113, :132-137, :264-267)
    — `var` fields, `fn Name(self)`/`(ref self)` methods, no modifiers.
-   Build order inside UN-1 commit 2: `is_union` + `BuildClassOrUnionDecl`
    -   the four handlers + `ComputeUnionObjectRepr` FIRST and compile
        with a `declare_and_access`-only golden before the conversion arm;
        a `class_decl` location CHECK (R-6) or a `DeclIntroducers` shape
        error (R-5) shows up here, not in the conversion.
-   The `EvalConstantInst(ClassInit)` branch is not optional and not a
    performance choice — without it the first constant designated init
    CHECK-fails in lowering (D-UN-4).
-   Do not cover non-designated fields in the `ClassInit` (R-2's
    contingency is a documented second choice, only after the falsifier
    fires).
-   The copy-witness gate must test `is_cpp_scope` (D-UN-5); an imported
    union that copies through `PrimitiveCopy` is a correctness bug, not a
    convenience.
-   UN-2 starts with `git rebase trunk` AFTER EH-B merges; then delete
    the guard and its golden in the same commit that adds the export
    golden (§3).
-   Every new AUTOUPDATE golden ships with empty CHECK lines (R15/R19);
    hand-derived EXPECT values only (R16(d)); `runner.py --self-test`
    before every conformance commit (R7); `uvx prek run --files` before
    every push (R25).

## Sign-off

_Pending two adversarial plan reviews (R29(c)). Amendments will be
folded in place, each marked "(amended <date>, review fold: ...)"._
