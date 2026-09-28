<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Unions plan: native `union` (UN-1, W-009) and C++ union interop (UN-2, W-015)

**Status:** SIGNED OFF FOR IMPLEMENTATION (UN-1 first), rev 2b,
2026-09-27. The two adversarial plan reviews returned REJECT (rev A:
blockers B-1, B-2; minors m-1, m-2) and APPROVE-WITH-AMENDMENTS (rev B:
F-1 blocker, F-2..F-14), folded as rev 2; the coordinator's rev 2a
amendment (prelude-trusted `Copy` impls) was auto-adopted under R29(a);
the focused re-review of rev 2a returned SIGN-OFF-WITH-AMENDMENTS
(mechanism spellings only: one blocker, one major, three minors), folded
as rev 2b. Every fold is marked "(amended 2026-09-27, review fold: ...)"
in place and listed in the fold record before Sign-off. Branch
`claude/carbon-fork-0-1-unions` off trunk e78db5df4 (post-PR #40: EH-A
landed). **Trunk has since moved (amended 2026-09-27, review fold: rev B
F-4):** PR #41 landed W-012, so trunk's floor is **108 PASS / 0 FAIL / 27
SKIP over 135**, 44/56 bullets, gap-analysis header (fork/gap-analysis.md:18
on trunk) 27 DONE / 20 PARTIAL / 7 MISSING / 2 DESIGN-ONLY; this branch's
own checkout still reads 106/0/28 over 134. Every count in this plan is
therefore stated as a DELTA from trunk at rebase time, with the expected
absolutes for both plausible bases (post-W-012, and post-EH-B — EH-B is
in flight in ../carbon-ehb touching
toolchain/check/cpp/{thunk,import,export,type_mapping}.cpp, expected
+4 PASS / −1 SKIP / +3 total → 112/0/26 over 138; it is the UN-2
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
DESIGN-ONLY → PARTIAL at UN-1 → DONE at UN-2, or PARTIAL if the by-value
residue of §5.B survives (§8.6; amended 2026-09-27, review fold: rev B
F-6). R7: the bullet
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
| 9 | Destruction of a union local | LANDED by way of the choice work | `CanDestroyClass` (custom_witness.cpp:151-208) walks the object repr; the `CustomLayoutType` case :314-333 mirrors the struct walk over the overlapping fields (its comment :315-318 says "today the payload region of a payload-carrying choice" — refreshed in §2.1); `MakeDestroyOpBody` lists `CustomLayoutType` (:637) as a placeholder no-op like every aggregate |
| 10 | Importing: `is_union` marking (:462-491) | MISSING | import.cpp:619-628 `GetInheritanceKind` maps a union to `Final` only; `SemIR::ClassFields` (sem_ir/class.h:57-70) has `is_choice` (:80-85) and no `is_union`; import_ref.cpp:2019 mirrors `is_choice` on import |
| 11 | Exporting as a genuine union (:493-505) | MISSING, and would CRASH | export.cpp:76-79 creates every exported record with `clang::TagTypeKind::Class`; `ExportAllFieldsToCpp` (:543-580, :550) and `CalculateCppFieldOffsets` (sem_ir/read_only_ast_source.cpp:15-49, :22) both call `Class::GetStructTypeFields` (sem_ir/class.cpp:55-72), which `GetAs<SemIR::StructType>` the object repr — a CHECK failure on a `CustomLayoutType` repr; :45 accumulates sequential offsets (`AppendField`), wrong for a union |
| 12 | Generic unions "as they fall out" (:105-117) | DO NOT FALL OUT | the only symbolic-layout machinery is the choice payload eval hook (check/eval_inst.cpp:212-351): it requires every field to be a payload TUPLE (:254-256 `GetAs<SemIR::TupleType>`) and enforces the SF-6 allowlist per element (:240-250, :278-297, :319-324) — a `union Slot(T: type) { var value: T; }` would CHECK-fail in it. §0.3 D-UN-3 |
| 12b | Unformed state: `var u: U;` type-checks (:245-258, F-007d) (amended 2026-09-27, review fold: rev A B-1 / rev B F-1) | MISSING — the plan's rev 1 evidence was a FAILURE golden | every non-field `var` without an initializer calls `(T as Core.DefaultOrUnformed).Op()` (check/handle_let_and_var.cpp:253-263 `MakeDefaultInit`, :303-313 the call site); `DefaultOrUnformed` has exactly two blanket impls, over `Default` and over `UnformedInit` (core/prelude/default.carbon:41-54); a native union as a `SemIR::Class` implements neither, so the conversion to the facet fails — the choice precedent fails exactly this way (check/testdata/choice/fail_generic_payload.carbon:37-41, `ConversionFailureTypeToFacet` "cannot convert type `P(C)` into type implementing `Core.DefaultOrUnformed`"). `UnformedInit` is a zero-method interface (default.carbon:18-26) implemented by scalars, pointers, arrays, `()`, `{}`, `String`, `Optional`, `MaybeUnformed`, the `CppCompat` adapters (string.carbon:28, optional.carbon:48, maybe_unformed.carbon:17, cpp/int.carbon:40-45); it is NOT a `CoreInterface` (sem_ir/core_interface_kind.def:19-43) and has no `CoreIdentifier` (check/core_identifier.def: `Copy` :35, `DefaultOrUnformed` :41, `Destroy` :42, no `UnformedInit`). D-UN-9 |
| 13 | Conformance | SKIP stub | fork/conformance/programs/types/union_basic.carbon: bullet :5, EXPECT lines :6-9, SKIP reason :10 (says "no design doc" — stale since F-007), strawman body :17-45 returns 1 |
| 12c | Export crash tolerance for the UN-1 guard (amended 2026-09-27, review fold: rev A B-2) | CALLERS DO NOT TOLERATE nullptr from `ExportClassToCppInDeclContext` | export.cpp:279-283 (`ExportClassToCpp`: `cast<clang::Decl>(record_decl)` on the result), :145-149 (`ExportNameScopeToCpp`: `setHasExternalVisibleStorage()` on it), :415-418 (`ExportClassTemplateToCpp`: `record_decl->getDeclName()`); the callers of `ExportClassToCpp` and `ExportNameScopeToCpp` DO tolerate nullptr (type_mapping.cpp:239-242; export.cpp:403-410, :745-749, :1702-1706; generate_ast.cpp:219-223), and the namespace branch's `context.TODO(...); return nullptr;` at :131-136 is the precedent |
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
    (custom_witness.cpp:504) extended with a `CustomLayoutType` arm AND
    a class-keyed "no non-trivial user `Core.Copy` impl" check, NOT the
    SF-6 scalar allowlist.** Rationale: the design's own canonical union
    has an `array(u8, 4)` field (unions.md:96-99) and admits arrays,
    tuples, structs, classes and unions "whose members recursively
    satisfy" the predicate (:212-215); `IsInSliceChoicePayloadType`
    rejects all of those. `IsTriviallyDestructible` is the design's
    "defined once, reused" predicate (:196-202) as landed at F8b, but it
    is only the DESTRUCTIBLE half: it checks `HasUserDestroyImpl`
    (:551-556) and never looks at `Core.Copy` impls, and
    `IsTriviallyCopyableForExport` (export.cpp:1583-1602) is shape plus
    `IsTriviallyDestructible`, nothing more — a class field with a user
    `impl as Core.Copy` would be admitted and D-UN-5's `PrimitiveCopy`
    memcpy would silently bypass it (amended 2026-09-27, review fold: rev
    B F-2; rev 1's sentence claiming export.cpp "says so" was false and
    is deleted). **Adopted: option (a), the copyable half is added to the
    union walk as `HasNonTrivialUserCopyImpl(class)`.** It is NOT a
    literal mirror of `HasUserDestroyImpl`'s symbolic-self shortcut
    (:436-438, :461-465: "any symbolic-self impl in scope disqualifies
    every class"): the prelude already declares several symbolic-self
    `Core.Copy` impls — `impl forall [T: type] T* as Copy`
    (core/prelude/copy.carbon:46), `impl forall [T: Copy] const T as
    Copy` (:22), `impl forall [N: IntLiteral] Int(N) as Copy`
    (types/int.carbon:25), `UInt(N)` (uint.carbon:26), `Float(N)`
    (float.carbon:26), `Optional(T)` (optional.carbon:50) — so the
    shortcut would return true for every class, and `i32` is itself
    `class_type @Int`, so a class-keyed match alone would reject every
    integer field. The check is therefore: an impl of `Core.Copy`
    (`GetCoreInterface`, custom_witness.cpp:886-894) whose self constant
    is a `ClassType` (concrete) or a symbolic `ClassType` of the SAME
    `class_id` as the field's class — walking the local store and the
    imported stores exactly as `HasUserDestroyImpl` does (:425-497), the
    canonical-identity match included — and which is declared OUTSIDE
    package `Core` (amended 2026-09-27, rev 2a, auto-adopted under
    R29(a): a TRUST BOUNDARY replaces rev 2's "bodied impl ⇒ rejected"
    rule, which would have rejected the design's own canonical
    `Optional(T*)` idiom, unions.md:341-344 — rejecting a ratified design
    example is a user-visible contradiction, not a narrowing). The
    prelude is toolchain-trusted code: its `Copy` impls over a
    trivially-destructible shape are bitwise by construction, so
    `user-provided` in the design's definition (:207-210) means
    "declared by the program, not by the prelude". **Prelude `Core.Copy`
    audit (every `impl ... as Copy` under core/, none outside
    core/prelude):** copy.carbon:26-47 (`Bool`, `CharLiteral`,
    `FloatLiteral`, `IntLiteral`, `type`, `T*`) and :22 (`const T`,
    delegates to `T`); int.carbon:25-27, uint.carbon:26-28,
    float.carbon:26-28, char.carbon:22-24; cpp/int.carbon:49-72 (the six
    `CppCompat` adapters) — all `= "primitive_copy"`; cpp/nullptr.carbon:42-46
    (`NullptrT`, `return Make()` over a `make_uninitialized` builtin — a
    stateless type, trivially equivalent to a byte copy);
    string.carbon:19-21 (`String`, `{.ptr = self.ptr, .size = self.size}`
    — a field-wise copy of both fields, bitwise on the object
    representation); optional.carbon:50-54 (`Optional(T)`, delegates to
    `T.Copy` on the storage: the pointer specialization's `Copy` is
    `= "primitive_copy"` (:203), and `DefaultOptionalStorage(T)`'s
    (:174-180) rebuilds `{value, has_value}` through `Some()`/`None()` —
    not a literal memcpy, but observationally identical to one for every
    `T` the walk admits: same `has_value`, same `value` bytes when
    present, no side effects, no ownership). Conclusion: NO prelude
    `Copy` impl over an admitted shape has side effects or differs
    observably from a byte copy of the object representation, so no
    explicit allowlist is needed; the package test alone is the rule.
    **Mechanism, verified (amended 2026-09-27, review fold: rev 2b
    B-1):** the local-store leg first SKIPS every impl that import
    MATERIALIZED into the local store — `context.insts().GetImportSource(
    impl.first_decl_id()).has_value()` (sem_ir/inst.h:590-594; equivalently
    `SemIR::GetCanonicalFileAndInstId(&context.sem_ir(),
    impl.first_decl_id()).first != &context.sem_ir()`, sem_ir/import_ir.h:81)
    — because a materialized impl's `parent_scope_id` is `None`
    (`GetIncompleteLocalEntityBase`, import_ref.cpp:1458-1466; the impl
    import phases :2868-2915 set only `parent_scope_inst_id`, :2876-2877),
    so rev 2a's `IsCorePackage(impl.parent_scope_id)` spelling would have
    classified a materialized prelude `Int.as.Copy.impl` (routine —
    class/basic.carbon:56-58; 178 check goldens carry `as.Copy.impl`) as a
    USER impl and diagnosed `var a: i32;` whenever an `i32` `Copy` lookup
    preceded the union in the file, order-dependently. The remaining
    file-declared impls are classified by `context.sem_ir().package_id()
    == PackageNameId::Core` (sem_ir/file.h:133; the handle_interface.cpp:88
    idiom); the imported-store leg classifies by
    `import_sem_ir.package_id() == PackageNameId::Core` inside the same
    `import_irs()` loop `HasUserDestroyImpl` walks (custom_witness.cpp:455-497),
    whose canonical-decl identity match finds `impl forall [T] MyBox(T)
    as Copy` for a `MyBox(i32)` field (re-review verified). Order
    independence is pinned by §4.A `order_independent_i32`. `Int(N)`/`UInt(N)`/`Float(N)`/`Char`/`Bool`/`T*`/
    `CppCompat`/`String`/`Optional(T)` fields therefore pass; a user
    class with an `impl as Core.Copy` declared outside `Core` — bodied or
    builtin, the package is the boundary — is rejected with
    `UnionFieldNotTriviallyCopyable` (pinned: §4.A `fail_user_copy_field`).
    `Core.Optional(T*)` is ADMITTED (pinned: §4.A `optional_pointer_field`,
    check + lower — the lower golden must show a plain memcpy/load-store
    of the pointer-sized storage). **Record of the rev 2 detour, kept
    for the log:** rev 2 read rev B F-2's "`Optional(T*)` still passes
    because its `Copy` is the `primitive_copy` builtin
    (optional.carbon:189-203)" as citing the `OptionalStorage` helper
    (:203) rather than the class's `Core.Copy` impl (:50-54), which is
    bodied, and rejected `Optional(T*)`; rev 2a's trust boundary makes
    the reviewer's conclusion right by a different mechanism — the
    `fail_optional_pointer_field` pin, the ":341-344 self-contradiction"
    doc note and the residue "union fields of `Core.Optional(T*)`" are
    WITHDRAWN. Break condition of the trust boundary: a prelude `Copy`
    impl that is not observationally bitwise over an admitted shape
    (re-run the audit above at every weekly upstream merge that touches
    core/prelude; the fix is then an explicit allowlist of prelude
    classes, never widening the boundary to user packages). Falsifier:
    the lower golden of `optional_pointer_field` showing anything other
    than a plain memcpy/load-store of the storage (a call to the prelude
    `Op` there means the union copy is not the primitive copy D-UN-5
    specifies). Three conservative exclusions follow from the predicate as
    it stands and are recorded loudly rather than papered over: (i) a
    CHOICE-typed field is rejected (:535-538 returns false for `is_choice`,
    deferring to the destroy machinery) although the design permits
    choices whose payloads are trivial — residue "union fields of choice
    type" (§8.5); (ii) `str` fields are rejected (the builtin string type
    hits `IsTriviallyDestructible`'s default arm) — `String` fields are
    ADMITTED under rev 2a (prelude `Copy`, string.carbon:19-21, and a
    trivially-destructible `{ptr, size}` repr); (iii) an IMPORTED C++ class or union as a field is rejected,
    because `IsTriviallyDestructible` returns false for every
    `is_cpp_scope` class (custom_witness.cpp:528-534) — the canonical
    migration shape (unions.md:54-58, :64-66) is therefore not admitted
    in 0.1 (amended 2026-09-27, review fold: rev A M-1 / rev B F-3);
    pinned by §4.A `fail_cpp_class_field`, doc note at §8.6, residue
    "union fields of imported C++ type" naming the mechanism — a cpp-scope
    arm consulting `CXXRecordDecl::isTriviallyCopyable()` through
    `context.clang_decls()`. That residue is deliberately NOT pulled into
    UN-2 although UN-2 has the cpp/ files open: the predicate lives in
    custom_witness.cpp and is the F8b single-owner predicate whose other
    consumer, `IsTriviallyCopyableForExport`, would change meaning for
    exported classes with C++-typed fields — a separate review, not a
    rider. **Mechanism behind the break condition:** `HasUserDestroyImpl`'s
    symbolic-self shortcut (:436-438) makes ANY blanket `Core.Destroy`
    impl in scope disqualify all classes; none exists today
    (`grep -rn 'as Destroy' core/` is empty), and the predicate becomes
    useless the day one lands. Break condition: a prelude or user
    blanket `Core.Destroy` impl appearing, or the `aggregate_fields` /
    `nested_union_field` subfiles diagnosing — then the predicate gains a
    class-keyed `Destroy` match like the `Copy` one, never a silent
    widening elsewhere.
-   **D-UN-3 — generic unions are TODO-gated in 0.1: a union with its
    own parameters or an enclosing generic scope (`generic_id.has_value()`,
    the handle_choice.cpp:645-646 test — citation corrected; amended
    2026-09-27, review fold: rev B F-7) diagnoses `SemanticsTodo`
    "`generic union`" at its definition and completes with an error
    witness.** The gate is deliberately the BROAD one (amended
    2026-09-27, review fold: rev B F-7): it also fires for a
    concrete-field union nested in a generic class (`class Box(T: type) {
    union U { var a: i32; } }`), which the design's cut line
    (design-sprint unions.md:518-523, "concrete (non-generic) unions")
    does not require; the narrow alternative — gate on "any field type
    not `is_concrete()`" — would admit a union whose `ClassType` is
    itself per-specific inside a generic region, a shape no golden pins,
    for no 0.1 program. The :116-117 amendment and the residue title say
    "generic unions and unions nested in generic scopes". unions.md:116-117 says generic unions are "supported as
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
    `fail_copy_nontrivial_member`). **Consequence (amended 2026-09-27,
    review fold: rev B F-8):** because the custom-witness dispatch
    precedes candidate-impl iteration (custom_witness.cpp:925-934, the
    W-075 posture), the synthesized witness SHADOWS a user `impl as
    Core.Copy` written inside a union body — a member the design permits
    (unions.md:129). This is the choice precedent's declared consequence
    (alternative_copy.carbon) carried over unchanged, pinned by §4.A
    `user_copy_impl_shadowed` (check: the copy resolves to the
    `custom_witness (%Copy.Op), @Copy` constant, not the user `Op`; lower:
    a memcpy and no call to the user function). Break condition: the
    W-015 negative pin compiling clean.
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
    merges.** See §0.4. UN-1 carries a guard so that a union reaching C++
    export diagnoses `SemanticsTodo` "`union export`" instead of
    CHECK-crashing in `GetStructTypeFields` (§0.1 row 11). **Placement
    (amended 2026-09-27, review fold: rev A B-2):** NOT inside
    `ExportClassToCppInDeclContext` (export.cpp:60-91) — its three
    callers dereference the result unconditionally (§0.1 row 12c), so a
    nullptr there turns the CHECK into a null-pointer crash. The guard
    lives at the two entry points whose callers all handle nullptr: in
    `ExportClassToCpp` immediately AFTER the `clang_decls().Lookup`
    at :270-273 (so an imported union, already in `clang_decls`, keeps
    returning its `TagDecl` untouched), and in `ExportNameScopeToCpp`'s
    class branch (:143-147, a union used as a name scope), both spelled
    exactly like the namespace branch's precedent `context.TODO(loc_id,
    ...); return nullptr;` (:131-136). Two hunks of three lines each in
    an EH-B contention file, both additive (amended 2026-09-27, review
    fold: rev B F-9: UN-1 does touch export.cpp; the rebase direction is
    that UN-1 lands first and EH-B rebases over it if EH-B is still open,
    else UN-1 rebases over EH-B — either way single additive hunks; see
    R-12's time-box). UN-2 deletes both hunks. Pre-existing, recorded
    (amended 2026-09-27, review fold: rev 2b m-3): `ExportClassToCpp`
    passes `ExportNameScopeToCpp`'s result UNCHECKED into
    `ExportClassToCppInDeclContext` (export.cpp:277-280), so a nullptr
    from the name-scope guard would still crash there; this is unreachable
    for unions only because D-UN-6 forbids nested classes in a union body
    (the guard fires for a union AS a name scope, which nothing can be
    declared inside). A later D-UN-6 relaxation must re-check :277-280
    before admitting nested types.
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
-   **D-UN-9 — unformed state by way of `Core.UnformedInit`: a native
    union implements `UnformedInit` through a synthesized empty custom
    witness, so the prelude's blanket `impl forall [T: UnformedInit] T as
    DefaultOrUnformed { fn Op() -> Self = "make_uninitialized"; }`
    (default.carbon:52-54) applies and `var u: U;` type-checks (amended
    2026-09-27, review fold: rev A B-1 / rev B F-1 — a rev 1 BLOCKER: the
    design-faithful mechanism both reviewers preferred).** Mechanism, all
    on landed patterns: (1) `CARBON_SEM_IR_CORE_INTERFACE_KIND(UnformedInit)`
    in sem_ir/core_interface_kind.def (before `Unknown`, :43) — the tag
    is assigned automatically to the prelude interface by name
    (check/handle_interface.cpp:93-97's `StringSwitch` over the same
    x-macro) and mirrored on import (import_ref.cpp:3089
    `.core_interface = import_interface.core_interface`); (2)
    `CARBON_CORE_IDENTIFIER(UnformedInit)` in check/core_identifier.def
    (alphabetical), which `AsCoreIdentifier`'s x-macro switch
    (custom_witness.cpp:873-882) requires for every core interface; (3) a
    `case SemIR::CoreInterface::UnformedInit:` arm in `LookupCustomWitness`
    (:1196-1218) calling a new `LookupUnionUnformedInitWitness` that
    mirrors `LookupChoiceCopyWitness` (:936-967): nullopt unless the self
    is a `ClassType` with `is_union && !is_cpp_scope`; `InstId::None` when
    `!build_witness` or the self is symbolic (the :946-953 handling —
    unreachable for a 0.1 union under D-UN-3 but kept for parity); else
    `BuildCustomWitness(context, loc_id, query_self_const_id,
    query_specific_interface_id, /*values=*/{})` — legal because
    `UnformedInit` declares no associated entities (default.carbon:18-26)
    and `BuildCustomWitness` CHECKs only `assoc_entities.size() ==
    values.size()` (:741-756); (4) `case SemIR::CoreInterface::UnformedInit:
    return SemIR::InstId::None;` in `LookupCppImpl`
    (check/cpp/impl_lookup.cpp:571-636 — an exhaustive switch with no
    default ending in `case Unknown: CARBON_FATAL`, so the new kind
    breaks the -Werror build without an arm; the `IntFitsIn`/`FloatFitsIn`
    precedent is :629-632). Behaviorally `EvalLookupSingleImplWitness`
    (check/impl_lookup.cpp:1313-1322) now calls `LookupCppImpl` for
    concrete selves whose associated import IR is `Cpp` with this kind,
    and `None` keeps imported C++ classes' `DefaultOrUnformed` path
    unchanged — the "imported unions unaffected" claim below depends on
    it (amended 2026-09-27, review fold: rev 2b M-1). The `Op` call then
    resolves through the blanket impl to the `MakeUninitialized`
    builtin, which lowers to a poison value (lower/handle_call.cpp:333-336). **Rejected: a
    synthesized `Core.Default` witness** — it would declare the variable
    FORMED, contradicting unions.md:245-253 ("A union variable declared
    without an initializer is in the unformed state ... The first write
    to a field forms the variable") and the unformed-state contract that
    destruction is optional and no other operation is permitted
    (default.carbon:16-17). **Imported unions are unaffected:** their
    `DefaultOrUnformed` resolves through `Core.Default` from the C++
    default constructor (check/cpp/impl_lookup.cpp:216-240
    `BuildDefaultWitness`, dispatched at :618), exactly as today. Golden
    precedent note, verified: NO golden in the tree exercises an unformed
    local of a class type with an in-place initializing representation
    (`grep -rln 'var [a-z_]*: \(Core.\)\?String;'` and `... Optional(i32);`
    over check/lower testdata are empty; the `String as UnformedInit` and
    `Optional(T) as UnformedInit` impls exist but are unpinned), so the
    §4.A shapes are derived from the code path and from the empty-tuple
    precedent check/testdata/var/initialization.carbon:133-134
    (`%...as.DefaultOrUnformed.impl.Op.call: init %... = call
    constants.%...Op()` then `assign %x.var, %...call`) and the
    custom-witness constant shape alternative_copy.carbon:166-167. Break
    condition and falsifier: `ConversionFailureTypeToFacet` ("cannot
    convert type `IntOrBytes` into type implementing
    `Core.DefaultOrUnformed`") on `var u: IntOrBytes;` in §4.A
    `unformed_then_assign` — the exact rev 1 failure; there is no
    fallback that keeps F-007d.

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
    (`union_basic` SKIP→PASS + a differential pair); the `UnformedInit`
    core-interface plumbing (D-UN-9); docs, ledger, gap-analysis PARTIAL.
    Size M. Touches lex/parse/check/sem_ir and two three-line additive
    hunks of check/cpp/export.cpp (the D-UN-7 guard; amended 2026-09-27,
    review fold: rev A B-2 / rev B F-9).
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
    mirrors it (`.is_union = import_class.is_union`); `PrintClassFields`
    (class.h:122-140), which today omits `is_choice`, prints both
    `is_choice` and `is_union` (amended 2026-09-27, review fold: rev A
    m-2). handle_class.cpp's
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
    `IsTriviallyDestructible(context, element_type) &&
    !HasNonTrivialUserCopyImpl(context, element_type)` (D-UN-2; the
    second walks the same class/adapted/repr structure as the first and
    answers false for non-class kinds) else
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
6.  **Copy, destroy and unformed state.** `LookupChoiceCopyWitness`
    (custom_witness.cpp:936-967) gate widened per D-UN-5 (the :921-935
    comment gains the union sentence, the `is_cpp_scope` rationale and
    the in-body-impl shadowing consequence); the function keeps its name.
    Unformed state is D-UN-9: the `UnformedInit` core-interface kind and
    identifier, and `LookupUnionUnformedInitWitness` beside
    `LookupChoiceCopyWitness` with its `LookupCustomWitness` arm. The
    union field predicate is `IsTriviallyDestructible` plus
    `HasNonTrivialUserCopyImpl` (D-UN-2), the latter a static beside
    `HasUserDestroyImpl` (:425-497) sharing its local-and-imported-store
    walk. Destroy needs no code: `CanDestroyClass` (:151-208) reaches
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
    `HasNonTrivialUserCopyImpl` beside `HasUserDestroyImpl` (:425-497)
    (D-UN-2); `LookupUnionUnformedInitWitness` + the `LookupCustomWitness`
    arm (:1196-1218) (D-UN-9); comment refresh :315-318.
    **toolchain/sem_ir/core_interface_kind.def:43** — `UnformedInit`
    before `Unknown`; **toolchain/check/core_identifier.def** —
    `UnformedInit`; **toolchain/check/cpp/impl_lookup.cpp:629-632** —
    the `UnformedInit → InstId::None` arm (D-UN-9; amended 2026-09-27,
    review fold: rev A B-1 / rev B F-1 / rev 2b M-1).
7.  **toolchain/check/cpp/export.cpp** — the union TODO guard at
    `ExportClassToCpp` after :270-273 and at `ExportNameScopeToCpp`'s
    class branch :143-147 (D-UN-7; amended 2026-09-27, review fold: rev A
    B-2).
8.  **toolchain/diagnostics/kind.def** — four kinds (§1.A.7).
9.  **Docs and grammars:** docs/design/unions.md and classes.md dated
    amendments (§8.6); docs/design/lexical_conventions/words.md keyword list
    (`union` between `type` and `var`, :101-102); utils/vim/syntax/carbon.vim:40
    (a `carbonUnionDeclaration` line mirroring `choice`),
    utils/vscode/carbon.tmLanguage.json:369 and
    utils/textmate/Syntaxes/carbon.tmLanguage:488 (add `union` to the
    introducer alternation), utils/textmate/Samples/keywords.carbon:17,
    utils/tree_sitter/queries/highlights.scm:94 (after `"choice"`).
10. **No BUILD changes beyond check/BUILD; no CI or workflow changes.**

### §2.B UN-2 (file by file)

1.  **toolchain/check/cpp/import.cpp:950** — `is_union` (§1.B.1).
2.  **toolchain/check/cpp/export.cpp** — delete both guard hunks (at
    :270-273 and :143-147); :76-79 `TagTypeKind` (§1.B.2).
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
    fold suppression, copy gate, the two-part field predicate, the
    `UnformedInit` core interface + witness (D-UN-9), export guard,
    kind.def).
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
    `InvalidParseSubtree` recovery (:15-25) — D-UN-6. Authoring rule
    (amended 2026-09-27, review fold: rev A m-1): `SkipPastLikelyEnd`
    (parse/context.cpp:159-189) stops at a `;`, an unmatched `}`, or a
    dedent below the root line's indent, so every offending member sits
    on its OWN line indented inside the union body and the union's `}`
    on its own dedented line — then recovery consumes only the member and
    the `UnionDefinition '}'` node still closes the tree.
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
    return u.word;` (rewritten; amended 2026-09-27, review fold: rev A
    B-1 / rev B F-1 — rev 1 cited class/fail_incomplete.carbon:157, a
    FAILURE golden, as evidence that no interface is consulted; wrong,
    §0.1 row 12b): predicted, per D-UN-9, a `custom_witness (),
    @UnformedInit [concrete]` constant and `%UnformedInit.facet:
    %UnformedInit.type = facet_value %IntOrBytes, (%custom_witness...)`
    (the alternative_copy.carbon:166-167 shape with an EMPTY table), the
    blanket-impl specific `@T.as.DefaultOrUnformed.impl(%IntOrBytes)`, a
    call `%IntOrBytes.as.DefaultOrUnformed.impl.Op.call: init
    %IntOrBytes = call ...(%u.var)` targeting the variable's return slot
    (in-place class repr) followed by `assign %u.var, %...call` (the
    var/initialization.carbon:133-134 shape), then the field store; a
    `ConversionFailureTypeToFacet` line here is D-UN-9's falsifier; `designated_init` — `var v: IntOrBytes = {.word = 5};` and
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
    in check/testdata/choice/alternative_copy.carbon; then the ASSIGNMENT
    `w = v;` (unions.md:271-274) — predicted a second witness call whose
    initializer targets `%w.var` through `assign`, and in lower a second
    `llvm.memcpy` of 4 bytes; amended 2026-09-27, review fold: rev B
    F-11); `user_copy_impl_shadowed` (`union Shadowed { var a: i32; impl
    as Core.Copy { fn Op(self) -> Self { return {.a = 0}; } } }` then
    `var y: Shadowed = x;` — predicted the copy resolves to the
    synthesized `custom_witness (%Copy.Op), @Copy`, NOT the user `Op`,
    the D-UN-5 consequence; amended 2026-09-27, review fold: rev B F-8); `method` (`fn
    LowHalf(self) -> i32 { return self.bytes[0] as i32; }` and `fn
    Set(ref self, x: i32) { self.word = x; }`); `impl_member` (an
    `impl as Core.Default`-free interface impl inside the union body —
    a user interface `I` with `fn Get(self) -> i32`, pins `impl` as a
    permitted member); `forward_decl` (`union U;` ... `union U { var a:
    i32; }` merges: one `class_decl`, no diagnostic); `member_of_class`
    (`class C { union Inner { var a: i32; } var u: Inner; }`);
    `namespace_scoped` (`namespace N; union N.U { var a: i32; }` —
    unions.md:105-106; amended 2026-09-27, review fold: rev B F-12);
    `order_independent_i32` (`fn Warm(x: i32) -> i32 { var y: i32 = x;
    return y; }` — an `i32` `Core.Copy` lookup that materializes
    `Int.as.Copy.impl` into the local store — placed textually BEFORE
    `union U { var a: i32; }`: predicted ACCEPTED, no
    `UnionFieldNotTriviallyCopyable`; the rev 2b B-1 pin, amended
    2026-09-27, review fold: rev 2b B-1);
    `file_scope_designated` (`var g: IntOrBytes = {.word = 5};` at file
    scope — with D-UN-4 the initializer is `NotConstant`, so predicted:
    the variable's `var` inst has no constant initializer and the
    `class_init` is emitted in the file's `__global_init` block, the
    lower/testdata/global/decl.carbon path; the lower twin pins
    `@_Cg.Main = internal global [4 x i8] zeroinitializer` plus a `store
    i32 5` through a GEP in `@__global_init`; amended 2026-09-27, review
    fold: rev A M-2 — R-14 is now pinned, not deferred);
    `raw_identifier` (`var r#union: i32 = 1;` compiles — F-007h);
    `nested_union_field` (`union Outer { var inner: IntOrBytes; var w:
    i64; }` — the `IsTriviallyDestructible` `CustomLayoutType` arm;
    predicted accepted, `size=8, align=8`); `aggregate_fields` (a struct
    field `{.a: i32, .b: i32}`, a tuple field `(i32, i16)`, a pointer
    field, a `bool` field, a `char` field, a `Core.String` field — all
    accepted: every prelude `Core.Copy` impl they reach is declared in
    package `Core`, D-UN-2); `optional_pointer_field` (`var p:
    Core.Optional(i32*);` — predicted ACCEPTED: `IsTriviallyDestructible`
    walks the adapter (custom_witness.cpp:555-566) into
    `MaybeUnformed(i32*)` (optional.carbon:189-190, :196-199) and the
    `Core.Copy` impl at :50-54 is prelude-declared, so the copy half
    passes; its lower twin pins the union copy as a plain `llvm.memcpy`
    of the 8-byte storage with NO call to the prelude `Op` — the rev 2a
    falsifier; restored as a POSITIVE subfile, amended 2026-09-27, rev
    2a).
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
    Signal;` — the D-UN-2(i) residue, comment cites it);
    `fail_user_copy_field` (`class Counted { var n: i32; impl as
    Core.Copy { fn Op(self) -> Self { return {.n = self.n + 1}; } } }` as
    a field — the copyable half of the predicate, amended 2026-09-27,
    review fold: rev B F-2; the impl is declared outside `Core`, which is
    the rev 2a boundary — a `primitive_copy`-bodied user impl would be
    rejected too); `fail_cpp_class_field` (a `// ---
    point.h` subfile declaring `struct Point { int x; int y; };` and
    `union CppU { int a; float f; };`, then `import Cpp library
    "point.h";` with `var p: Cpp.Point;` and `var u: Cpp.CppU;` as union
    fields — both rejected by the `is_cpp_scope` early-out
    custom_witness.cpp:528-534, D-UN-2(iii); amended 2026-09-27, review
    fold: rev A M-1 / rev B F-3): each predicted
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
    at UN-2) — `import Cpp;` + `union U { var a: i32; fn F(self) {} }` +
    `inline Cpp ''' Carbon::U u; '''` (the `ExportClassToCpp` entry, by way of
    type_mapping.cpp:239-242) and a second subfile calling an exported
    method (`Carbon::U::F`): predicted, in BOTH subfiles, the
    `ExportClassToCpp` `SemanticsTodo` "semantics TODO: `union export`"
    followed by generate_ast.cpp:210's "interop with unsupported type" —
    C++ name lookup resolves the enclosing record first through
    `MapInstIdToClangDeclOrType` → `MapToCppType` → `ExportClassToCpp`
    (generate_ast.cpp:200-212, type_mapping.cpp:239-242), so the
    `ExportNameScopeToCpp` class-branch guard is never the first hit and
    stays as defense in depth (reworded; amended 2026-09-27, review fold:
    rev 2b m-1). The pin is the `ExportClassToCpp` TODO in both subfiles;
    the falsifier is a CHECK failure in `GetStructTypeFields` or a null
    dereference (§7 R-9; amended 2026-09-27, review fold: rev A B-2).
-   **lower/testdata/union/basic.carbon** (full prelude) — subfiles
    mirroring `unformed_local` (a `fail_`-free twin of
    `unformed_then_assign`; amended 2026-09-27, review fold: rev A B-1 /
    rev B F-1: predicted `%u.var = alloca [4 x i8], align 4` and NO store
    from the default init — the `MakeUninitialized` call's value is a
    poison `[4 x i8]` (handle_call.cpp:333-336) and the in-place
    consumer emits nothing for a non-constant source
    (function_context.cpp:398-405); the one acceptable variant the fill
    may show instead is a single `store [4 x i8] poison, ptr %u.var`,
    the by-copy scalar analogue of lower/testdata/global/decl.carbon:24's
    `store i32 poison`; a memcpy, a call, or any non-poison store is a
    miss), `designated_init`, `copy` (two memcpys: initialization and
    the `w = v;` assignment, rev B F-11), `user_copy_impl_shadowed` (a
    memcpy and no call to the user `Op`, rev B F-8), `optional_pointer_field`
    (`var q: OptPtr = p;` over `union OptPtr { var o: Core.Optional(i32*);
    var n: i64; }` — an 8-byte `llvm.memcpy`, no call to the prelude
    `Optional.as.Copy.impl.Op`; rev 2a), `method`, `by_pointer`,
    `file_scope_union` (rev A M-2). Predicted IR: `%u.var =
    alloca [4 x i8], align 4`; field access `getelementptr inbounds nuw [4 x i8], ptr
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
    as in check/testdata/interop/cpp/impls/copy.carbon); `by_value`
    (`inline int ReadA(Pair u) { return u.a; }` and `inline Pair
    MakePair(int v) { Pair p; p.a = v; return p; }` called from Carbon —
    the function/import/union.carbon:105-115 shape; amended 2026-09-27,
    review fold: rev B F-5);
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
    } Carbon::Wide MakeWide(int v) { Carbon::Wide w; w.lo = v; return w; }
    int SumLo(Carbon::Wide w) { return w.lo; } '''` with Carbon calling
    all three: predicted a clean compile, the `imports` block showing
    the `Cpp.Use` thunk with a `Carbon::Wide*` parameter, the by-value
    return thunk for `MakeWide` (precedent: an exported class returned by
    value from inline C++, function/export/generic.carbon:41-46), and no
    destructor thunk decl for `Wide` (`IsTriviallyCopyableForExport`
    true — the trivially_copyable.carbon:1-40 posture). **By-value
    parameter crossing (amended 2026-09-27, review fold: rev B F-5):**
    `Cpp.SumLo(w)` passes an exported Carbon union BY VALUE into C++; no
    landed golden exercises a C++ function taking an exported Carbon
    class by value (`grep -rn 'Carbon::[A-Z][A-Za-z]* [a-z_]*[,)]'` over
    check/testdata/interop/cpp is empty), so this subfile is a PROBE: if
    the fill shows a `SemanticsTodo`/`Unsupported:` line for it, the
    crossing is recorded as the residue "exported union passed by value
    into C++" citing unions.md:509-510 and the gap row stays PARTIAL
    (§8.6); the import direction by value has precedent
    (function/import/union.carbon:105-115, `auto foo(U) -> void;` called
    with `Cpp.foo(u)`).
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
--self-test` before every commit that touches programs). **Counts are
deltas (amended 2026-09-27, review fold: rev B F-4):** UN-1 is PASS +2,
SKIP −1, total +1, bullets +1; UN-2 is PASS +2, total +2. Absolutes:
on the post-W-012 base (108/0/27 over 135, 44/56) UN-1 → **110/0/26 over
136, 45/56** and UN-2 → **112/0/26 over 138**; on the post-EH-B base
(112/0/26 over 138 expected) UN-1 → **114/0/25 over 139** and UN-2 →
**116/0/25 over 141**. **Layout arbiters (amended 2026-09-27, review
fold: rev B F-14):** union_basic cannot observe size or alignment at
runtime; UN-1's layout arbiters are check/testdata/union/layout.carbon
(the `size=`/`align=` constants) and union_pun_diff's `halves[1]` read
(which is wrong unless `both` and `halves` overlap at offset 0 with an
8-byte region); UN-2's `static_assert(__is_union/sizeof/alignof)` lines
run in the EMBEDDED Clang during `carbon compile` of the `inline Cpp`
block (precedent export/trivially_copyable.carbon:35-36), not in the
runner's clang++, which compiles only `.diff.cpp` oracles
(runner.py:43-52, :628-638) — so a layout disagreement is a
COMPILE-FAIL of the Carbon program, not a C++-side event. Every
`var u: U;` in these programs depends on D-UN-9 (rev 1 would have
COMPILE-FAILed on the first one). Harness
conventions (fork/w077/plan.md §5): runtime inputs through
`fn RuntimeSeed(x: i32) -> i32 { return x + 20; }` so nothing constant
folds (R16(d)); EXPECT values hand-derived below from the design's
byte-reinterpretation rule (unions.md:304-352) on the V-1 little-endian
targets (x86-64 Linux, arm64 macOS); `Core.Print(x: i32)` only
(core/io.carbon:12; R1); narrowing/widening spelled with `as`
(core/prelude/types/int.carbon:70 `Int(From) as As(Int(To))`).

### §5.A UN-1 — one SKIP→PASS, one new pair; delta PASS +2 / SKIP −1 / total +1 (110/0/26 over 136 on the post-W-012 base)

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

### §5.B UN-2 — two new programs; delta PASS +2 / total +2 (112/0/26 over 138 on the post-W-012 base)

1.  **types/union_cpp_import.carbon (new)** — `import Cpp inline '''c++
    union Pair { int a; int b; int* p; }; struct Tagged { int kind; union
    { int i; float f; }; }; inline void WriteA(Pair* u, int v) { u->a = v;
    } inline Tagged MakeTagged(int v) { Tagged t; t.kind = 1; t.i = v;
    return t; } static_assert(sizeof(Pair) == 8, "layout"); ''';`
    plus `inline int ReadA(Pair u) { return u.a; } inline Pair
    MakePair(int v) { Pair p; p.a = v; return p; }` (by-value crossings
    in both directions; amended 2026-09-27, review fold: rev B F-5);
    then: `var u: Cpp.Pair = {.a = RuntimeSeed(22)}; Core.Print(u.b);`
    (designated init on an imported union — the UN-2 deliverable — read
    back through the other `int` member: 42, defined by Carbon's read
    rule); `Cpp.WriteA(&u, RuntimeSeed(-15)); Core.Print(u.a);` (C++
    writes, Carbon reads: 5); `let t: Cpp.Tagged =
    Cpp.MakeTagged(RuntimeSeed(-13)); Core.Print(t.i);` (anonymous-union
    member flattened on import: 7); `Core.Print(Cpp.ReadA(u));` (Carbon
    passes the union by value to C++: 5); `var m: Cpp.Pair =
    Cpp.MakePair(RuntimeSeed(-9)); Core.Print(m.b);` (C++ returns by
    value, Carbon reads the other member: 11). EXPECT-STDOUT: `42`, `5`,
    `7`, `5`, `11`.
2.  **types/union_cpp_export.carbon (new)** — `import Cpp;` + `union
    Wide { var lo: i32; var both: i64; fn Low(self) -> i32 { return
    self.lo; } }` + `inline Cpp ''' static_assert(__is_union(Carbon::Wide),
    "kind"); static_assert(sizeof(Carbon::Wide) == 8 &&
    alignof(Carbon::Wide) == 8, "layout"); int RoundTrip(int v) {
    Carbon::Wide w; w.lo = v; return w.Low(); } void WriteBoth(Carbon::Wide*
    w, int hi, int lo) { w->both = (static_cast<long long>(hi) << 32) |
    static_cast<unsigned>(lo); } Carbon::Wide MakeWide(int v) {
    Carbon::Wide w; w.lo = v; return w; } int SumLo(Carbon::Wide w) {
    return w.lo + 1; } '''` (by-value crossings in both directions;
    amended 2026-09-27, review fold: rev B F-5); then
    `Core.Print(Cpp.RoundTrip(RuntimeSeed(22)));` (C++ constructs,
    writes and calls the exported method: 42); `var w: Wide;
    Cpp.WriteBoth(&w, RuntimeSeed(-13), RuntimeSeed(-11));
    Core.Print(w.lo); Core.Print((w.both / 4294967296) as i32);` (C++
    writes the 64-bit member, Carbon reads the low half through `lo` —
    defined by Carbon's rule — and the high half arithmetically: 9, 7);
    `var m: Wide = Cpp.MakeWide(RuntimeSeed(-8)); Core.Print(m.lo);`
    (C++ returns a Carbon union by value: 12); `Core.Print(Cpp.SumLo(m));`
    (Carbon passes it by value into C++: 13). EXPECT-STDOUT: `42`, `9`,
    `7`, `12`, `13`. If the by-value parameter probe of §4.B fails, the
    `SumLo` line is dropped from this program at the same commit (the
    EXPECT list loses its last line), the residue is filed and the row
    stays PARTIAL (§8.6) — recorded in the commit message and the
    decision-log entry, never silently. The `static_assert`s are the compile-time
    layout arbiter (D-UN-8); a wrong `TagTypeKind` fails `__is_union`, a
    wrong layout fails `sizeof`, both as COMPILE-FAIL — loud.

The bullet's runner status flips SKIP → PASS at UN-1 (bullets +1: 45/56
on the post-W-012 base); `gap_status` follows the gap-analysis row
(PARTIAL at UN-1, DONE — or PARTIAL — at UN-2, §8.6). `runner.py --update-readme-table` refreshes the README table at
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
-   Source files touched: 25 (amended 2026-09-27, review fold: rev A
    B-1 / rev B F-1: (23) toolchain/sem_ir/core_interface_kind.def and
    (24) toolchain/check/core_identifier.def added for D-UN-9; rev 2b
    M-1: (25) toolchain/check/cpp/impl_lookup.cpp for the `LookupCppImpl`
    arm — a third EH-B contention file, one three-line additive hunk;
    export.cpp is two hunks, rev A B-2) — (1) lex/token_kind.def; (2)
    parse/node_kind.def; (3) parse/typed_nodes.h; (4) parse/node_ids.h;
    (5) parse/state.def; (6) parse/handle_type.cpp; (7)
    parse/handle_decl_definition.cpp; (8) parse/handle_decl_scope_loop.cpp;
    (9) parse/handle_statement.cpp; (10) sem_ir/class.h; (11)
    check/import_ref.cpp; (12) check/class.h; (13) check/class.cpp;
    (14) check/handle_class.cpp; (15) check/handle_union.cpp (new);
    (16) check/BUILD; (17) check/convert.cpp; (18) check/eval_inst.cpp;
    (19) check/custom_witness.cpp; (20) check/cpp/export.cpp (two
    three-line hunks); (21) diagnostics/kind.def; (22)
    docs/design/unions.md; (23) sem_ir/core_interface_kind.def; (24)
    check/core_identifier.def; (25) check/cpp/impl_lookup.cpp — plus
    docs/design/classes.md (one dated sentence), words.md and the five
    grammar files. The `UnformedInit` core-interface tag changes no
    golden: `Interface::Print` DOES emit `core_interface` in
    `--dump-raw-sem-ir` (sem_ir/interface.h:55-57;
    basics/raw_sem_ir/one_file.carbon:437 shows `core_interface: Copy`),
    but no raw-dump golden mentions `UnformedInit` (`grep -rl
    UnformedInit toolchain/check/testdata/basics/raw_sem_ir/` is empty),
    and no landed witness lookup keys on the new kind (rationale
    corrected; amended 2026-09-27, review fold: rev 2b m-2).

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
-   **R-3 — the two-part field predicate rejects a design-permitted
    field type (amended 2026-09-27, review fold: rev B F-2/F-3).**
    Predicted accepted: scalars, pointers, arrays, tuples, structs,
    `String`, `Optional(T*)` (prelude `Copy` impls are inside the rev 2a
    trust boundary), non-choice classes with neither a `Destroy` impl nor
    a `Copy` impl declared outside `Core`, nested unions. Predicted
    rejected (recorded loudly): choice-typed fields, `str`, classes with
    a user-package `Copy` impl, imported C++ classes/unions.
    Falsifier: `aggregate_fields`, `nested_union_field` or
    `order_independent_i32` diagnosing (the last is the materialized-impl
    misclassification of rev 2a, rev 2b B-1), or any of the `fail_*_field`
    pins compiling clean. Contingency: D-UN-2's break condition.
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
    D-UN-7 TODO at `ExportClassToCpp` (after :270-273) and
    `ExportNameScopeToCpp`'s class branch (:143-147), the two entries
    whose callers handle nullptr (§0.1 row 12c); `ExportClassTemplateToCpp`
    (:415-418) is unreachable for a union under D-UN-3 (a generic union
    never completes). Falsifier: `fail_todo_export` (either subfile) not
    showing the `ExportClassToCpp` TODO, or crashing on a null
    `record_decl` (amended 2026-09-27, review fold: rev A B-2; rev 2b m-1:
    both subfiles reach the same guard, §4.A).
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
-   **R-12 — EH-B contention (UN-1's export.cpp guard hunks and UN-2's
    import.cpp/export.cpp hunks; amended 2026-09-27, review fold: rev B
    F-9).** Rule and time-box: UN-1 lands whenever its verification is
    green — if EH-B is still open, EH-B rebases over UN-1's two additive
    hunks. UN-2 waits for EH-B; if EH-B has NOT merged when UN-1's
    verification is green, UN-2 branches off trunk anyway and whichever
    of UN-2/EH-B lands second rebases (both sides are single additive
    hunks per file). Conflicts are resolved by rebase, never by
    reordering a landed PR. Falsifier: a merge that drops either side's
    hunk (the post-merge grep of §8.4 catches the union side).
-   **R-13 — `Context::TODO` and generic unions.** The TODO fires at the
    `}` and the definition completes with an error witness, so stacks
    stay balanced and later uses diagnose incompleteness normally.
    Falsifier: a `VerifyOnFinish` CHECK after `fail_todo_generic`.
-   **R-14 — file-scope union variables with designated initializers**
    take the runtime-global-init path (a `NotConstant` initializer at
    file scope). PINNED by §4.A `file_scope_designated`/`file_scope_union`
    (amended 2026-09-27, review fold: rev A M-2 — rev 1 left it
    unpinned): falsifier is a CHECK in global init lowering or a folded
    constant global. Rejected alternative: allowing the fold for
    all-constant designated inits — it reintroduces R-1 for every
    constant literal.
-   **R-15 — the `UnformedInit` witness does not make `var u: U;`
    type-check (D-UN-9; amended 2026-09-27, review fold: rev A B-1 / rev
    B F-1).** The blanket impl's facet lookup must find the custom
    witness at both `LookupCustomWitness` call sites
    (impl_lookup.cpp:902, :1276), as the choice `Copy` witness does.
    Falsifier: `ConversionFailureTypeToFacet` on `var u: IntOrBytes;`.
    Contingency: none that keeps F-007d — the synthesized-`Default`
    alternative is rejected (D-UN-9); a failure here is a stop.
-   **R-16 — erroneous reads of invalid representations (amended
    2026-09-27, review fold: rev B F-10).** unions.md:315-321 promises
    "not undefined behavior" for a read whose bytes are not a valid
    value of the read type; the planned lowering is a plain `load i1` /
    `load ptr` from `[N x i8]`, and LLVM yields poison for an `i1` load
    of a byte holding 2. 0.1 therefore delivers the design's "unspecified
    value" outcome only where LLVM's poison does not propagate into a
    branch or a memory access; the fail-stop half is F-007g future work.
    Recorded as a dated doc note at :315-321 (§8.6) and the residue
    "invalid-representation reads yield poison in 0.1" (§8.5). Not
    pinned: a golden cannot observe poison.
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
3.  **Conformance:** mode `conformance`; UN-1 delta PASS +2 / SKIP −1
    / total +1, UN-2 delta PASS +2 / total +2 — absolutes per base in
    §5 (110/0/26 over 136 then 112/0/26 over 138 on the post-W-012 base;
    114/0/25 over 139 then 116/0/25 over 141 on the post-EH-B base;
    amended 2026-09-27, review fold: rev B F-4);
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
        `CanDestroyClass` choice clause's SF-6 trust); "union fields of
        imported C++ type" (D-UN-2(iii),
        rev A M-1 / rev B F-3; mechanism: a cpp-scope arm consulting
        `CXXRecordDecl::isTriviallyCopyable()` through `clang_decls()`);
        "generic unions and unions nested in generic scopes" (D-UN-3,
        rev B F-7; mechanism named there); "union member-restriction
        diagnostics" (D-UN-6's parse-level message quality);
        "invalid-representation reads yield poison in 0.1" (R-16, rev B
        F-10); and, only if the §4.B probe fails, "exported union passed
        by value into C++" (rev B F-5). "File-scope union variables" is
        NO LONGER a residue — pinned (R-14, rev A M-2). Choice-side note
        (amended 2026-09-27, review fold: rev B F-12): a union used as a
        CHOICE PAYLOAD is governed by the SF-6 allowlist
        (check/type.cpp:313-331: int/float/bool/pointer through adapters,
        plus `()`), which rejects it — unions.md:78 ("its payloads may be
        of any type") is the Sum types bullet's SF-6 residue (W-010
        notes), not a union item. Carbon-authored anonymous unions,
        bit-fields, non-trivial fields and debug-mode tracking are
        design-deferred (F-007f/g, unions.md:444-452, :239-241) and stay
        in the doc, not the ledger, unless a reviewer asks for items.
6.  **Docs:** docs/design/unions.md — dated amendments, history
    unrewritten: :84-88 (choice payloads landed at W-010; the sentence
    stays with a "landed" note); :116-117 (D-UN-3: "the 0.1 toolchain
    diagnoses `generic union` for a union with parameters OR nested in a
    generic scope; the design intent stands"); :148-149 (nested types
    rejected at parse in 0.1, D-UN-6); :217-226 (the 0.1 predicate is
    `IsTriviallyDestructible` plus the class-keyed non-trivial-`Copy`
    check with the prelude as its trust boundary; choice-typed, `str`
    and imported C++-typed fields are conservatively rejected,
    D-UN-2(i)-(iii); and a
    reconciliation of :222-223 "diagnosed at the point where the union
    type is required to be complete" with the definition-site diagnosis:
    for a Carbon-authored union the `}` of its definition IS the point at
    which the type becomes complete, so the two coincide — the sentence
    is kept and annotated; amended 2026-09-27, review fold: rev B F-13);
    :315-321 (R-16: "0.1 lowering yields poison on an
    invalid-representation read; fail-stop tracking is F-007g future
    work"; rev B F-10); :207-210 (one dated sentence: "user-provided"
    means declared outside package `Core` — the prelude's `Copy` impls
    are trusted as bitwise, rev 2a; the rev 2 note planned for :341-344
    is withdrawn, `Optional(T*)` is admitted as the design says);
    :278-283 (implementation note → "landed at UN-1 for
    native unions" then "and at UN-2 for imported unions").
    docs/design/classes.md:2282-2300 ("Memory layout") gains one dated
    back-reference sentence ("Unions are the one place layout is
    guaranteed today; see unions.md#layout" — the reverse of unions.md:68-70;
    rev B F-13). words.md keyword list. README.md:2207-2237 and
    :3777-3789 already cover unions (no change); pattern_matching.md needs
    nothing (unions.md:556-562 states the non-dependency).
    **fork/gap-analysis.md:45** (header at :18 on trunk — corrected from
    :17; amended 2026-09-27, review fold: rev B F-4) — UN-1: DESIGN-ONLY →
    **PARTIAL** with evidence "native `union` end to end (keyword,
    class-shaped body, all-offsets-zero `CustomLayoutType`, designated
    single-field init, unformed-then-assign by way of a synthesized
    `UnformedInit` witness, byte-copy, methods/impls; concrete unions
    only — generic unions TODO-gated; field predicate rejects choice-,
    `str`- and C++-typed fields; 2/2 conformance
    programs PASS); C++ side: designated init of imported unions,
    `is_union` marking and union export are UN-2 (W-015)"; header delta
    DESIGN-ONLY −1 / PARTIAL +1 (27 / 21 / 7 / 1 on the post-W-012 base;
    EH-B leaves the header unchanged, fork/eh/plan.md §8.6). UN-2: →
    **DONE** with evidence "UN-1 text + imported unions construct by
    designated init and keep C++'s copy determination; Carbon unions
    export as `TagTypeKind::Union` with Carbon-supplied layout; round-trip
    programs in both directions, by pointer and by value, PASS (4/4).
    Gated residue, each a filed item: generic unions and unions nested in
    generic scopes; union fields of choice and imported C++ type;
    invalid-representation reads yield poison" (amended
    2026-09-27, review fold: rev B F-6 — DONE-with-gated-residue has the
    row 44 precedent: Sum types is DONE with Self-dependent payloads and
    qualified alternative patterns "still gated by diagnostics", cited in
    the decision-log entry); header delta PARTIAL −1 / DONE +1 (28 / 20 /
    7 / 1). **If the by-value parameter probe of §4.B fails, the row
    stays PARTIAL** at UN-2 with the by-value residue named in its
    evidence and no header delta. R7: bullet TEXT untouched.
7.  **Decision log:** entries "UN-1: native `union` declaration (date)"
    and "UN-2: C++ union interop (date)" carrying D-UN-1..9 with break
    conditions, the §0.2 corrections verbatim, the review-claim
    correction of the rev 2 fold (the `HasUserDestroyImpl` mirror) and
    the rev 2a trust-boundary amendment with its prelude `Copy` audit
    (auto-adopted under R29(a), veto-able), the V-3a divergence-register line (the
    `union` keyword and byte-reinterpretation reads are already F-007's;
    nothing new is minted), the row 44 DONE-with-gated-residue precedent
    (rev B F-6), the residue items by title with the ids allocated at
    that discharge, and the R29(a) auto-adoption note.
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
-   Land D-UN-9 in the SAME commit as the union handlers: without the
    `UnformedInit` witness every `var u: U;` in every golden and program
    is a `ConversionFailureTypeToFacet` (rev A B-1 / rev B F-1). The
    `CoreIdentifier` entry is required or `AsCoreIdentifier` fails to
    compile (its switch is x-macro-generated over every core interface).
-   The union field predicate is TWO walks (destructible + no `Copy`
    impl declared outside package `Core`), class-keyed; do NOT copy
    `HasUserDestroyImpl`'s symbolic-self shortcut into the `Copy` half —
    the prelude's blanket `T*`/`const T`/`Int(N)`/`Optional(T)` `Copy`
    impls would disqualify every class — and the package test, not the
    body, is the boundary (D-UN-2, rev 2a): `Optional(i32*)` must be
    ADMITTED. In the LOCAL leg skip import-materialized impls
    (`GetImportSource(impl.first_decl_id()).has_value()`) BEFORE the
    package test — their `parent_scope_id` is `None`, so any scope-based
    test misclassifies them (rev 2b B-1); `order_independent_i32` is the
    pin.
-   `LookupCppImpl`'s switch is exhaustive without a default: add the
    `UnformedInit → None` arm in the same commit as the core-interface
    kind or the -Werror build breaks (rev 2b M-1).
-   The export guard goes in `ExportClassToCpp` and `ExportNameScopeToCpp`,
    never in `ExportClassToCppInDeclContext` (rev A B-2).
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

## Review fold record (rev 2, 2026-09-27)

Every finding of the two rev 1 reviews, where it was folded, and the
two places the fold departs from the reviewer's own text (each with the
evidence the departure rests on).

| Finding | Fold |
| --- | --- |
| rev A B-1 = rev B F-1 (BLOCKER): `var u: U;` fails `DefaultOrUnformed` | D-UN-9 (§0.3), §0.1 row 12b, §1.A.6, §2.A.6, §3, §4.A `unformed_then_assign` + lower `unformed_local`, §5 note, §6.A (+2 files), §7 R-15, hand-off. Synthesized-`Default` alternative rejected in D-UN-9. Verified: no in-place-class `UnformedInit` golden exists in the tree; predictions derived from the code path and the empty-tuple/witness precedents |
| rev A B-2 (BLOCKER): guard placement null-crashes | D-UN-7 rewritten, §0.1 row 12c, §2.A.7, §2.B.2, §4.A `fail_todo_export` (both entries), §7 R-9 |
| rev B F-2: destructible-only predicate; false export.cpp sentence | D-UN-2 rewritten: option (a) adopted as a CLASS-KEYED, `primitive_copy`-exempting walk; false sentence deleted; `fail_user_copy_field`. **Departure, with evidence:** the reviewer's "(a) mirroring `HasUserDestroyImpl`" cannot be literal — the prelude declares symbolic-self `Core.Copy` impls (copy.carbon:22, :46; int.carbon:25; uint.carbon:26; float.carbon:26; optional.carbon:50) so the :436-438 shortcut would reject every class, and `i32` is `class_type @Int`, so the exemption for builtin-bodied impls is load-bearing. **Rev 2 departure, superseded by rev 2a:** rev 2 read the reviewer's "`Optional(T*)` still passes (optional.carbon:189-203)" as citing the `OptionalStorage` helper (the class's `Core.Copy` impl at :50-54 is bodied) and rejected `Optional(T*)`; rev 2a's prelude trust boundary admits it (see the rev 2a row) |
| rev 2a (coordinator amendment, auto-adopted under R29(a)): prelude-trusted `Copy` impls | D-UN-2 copy half re-ruled as a package boundary (`package_id() == PackageNameId::Core` on the declaring file, file.h:133 — rev 2a's local-leg spelling `IsCorePackage(impl.parent_scope_id)` was corrected at rev 2b B-1); prelude `Core.Copy` audit recorded in D-UN-2 (all builtin-bodied, delegating, or side-effect-free field-wise copies; no allowlist needed); `optional_pointer_field` restored as a positive subfile with a lower memcpy pin; `fail_optional_pointer_field`, the :341-344 note and the `Optional(T*)` residue withdrawn; `fail_user_copy_field` kept; R-3, §8.5, §8.6, hand-off updated |
| rev A M-1 = rev B F-3: cpp-scope fields rejected | D-UN-2(iii), `fail_cpp_class_field`, residue with mechanism, kept out of UN-2 with the stated reason; `HasUserDestroyImpl` shortcut recorded as the break-condition mechanism |
| rev A M-2: file-scope initializer unpinned | §4.A `file_scope_designated` + lower `file_scope_union`; R-14 now pinned; residue withdrawn |
| rev B F-4: counts stale (W-012 landed) | Header, §5 (deltas + both bases), §5.A/§5.B titles, §8.3, §8.6 (:17 → :18; header deltas) |
| rev B F-5: by-value crossings missing | §4.B import `by_value` + export `MakeWide`/`SumLo` probe; §5.B both programs; residue rule + PARTIAL rule |
| rev B F-6: DONE needs justification | §8.6 UN-2 evidence names every gated item; row 44 precedent cited; PARTIAL rule for the by-value residue |
| rev B F-7: generic gate breadth; citation | D-UN-3: broad gate kept and stated; :645-646 corrected; residue title widened |
| rev B F-8: in-body `Copy` impl shadowed | D-UN-5 consequence; `user_copy_impl_shadowed` (check + lower) |
| rev B F-9: UN-1 touches export.cpp | D-UN-7 and §0.4 record it; R-12 time-boxed |
| rev B F-10: invalid-representation reads | R-16; doc note :315-321; residue |
| rev B F-11: assignment `w = v;` | §4.A `copy` (check + lower second memcpy) |
| rev B F-12: namespace-scoped union; unions as choice payloads | §4.A `namespace_scoped`; §8.5 choice-side note (SF-6, type.cpp:313-331) |
| rev B F-13: docs cross-references | §8.6: classes.md:2282-2300 back-reference; :222-223 reconciliation; README/pattern_matching no-change statements |
| rev B F-14: runtime cannot observe layout | §5 arbiters paragraph (layout.carbon, `halves[1]`, embedded-Clang `static_assert`, runner.py:43-52/:628-638) |
| rev A m-1: `SkipPastLikelyEnd` recovery | §4.A `fail_members` authoring rule (context.cpp:159-189) |
| rev A m-2: `PrintClassFields` | §1.A.3: prints `is_choice` and `is_union` |
| rev 2b B-1 (BLOCKER, re-review): local-leg `IsCorePackage(parent_scope_id)` misclassifies import-materialized impls (`parent_scope_id` None, import_ref.cpp:1458-1466, :2876-2877) — order-dependent false `UnionFieldNotTriviallyCopyable` on `i32` fields | D-UN-2 mechanism respelled: skip `GetImportSource(...).has_value()` impls in the local leg, classify file-declared impls by `sem_ir().package_id()`, imported leg unchanged; §4.A `order_independent_i32`; R-3 falsifier; hand-off; rev 2a row corrected |
| rev 2b M-1 (MAJOR): `LookupCppImpl`'s exhaustive switch needs an `UnformedInit` arm (-Werror) | D-UN-9 step (4) (`return InstId::None`, the :629-632 precedent; keeps imported classes' `DefaultOrUnformed` path unchanged through `EvalLookupSingleImplWitness` :1313-1322); §2.A.6; §6.A 24 → 25 files; hand-off |
| rev 2b m-1: second `fail_todo_export` subfile reaches `ExportClassToCpp` first (generate_ast.cpp:200-212) | §4.A pin reworded to "the `ExportClassToCpp` TODO in both subfiles" + generate_ast.cpp:210's follow-on; R-9; the name-scope guard kept as defense in depth |
| rev 2b m-2: `Interface::Print` does emit `core_interface` in raw dumps | §6.A rationale corrected (interface.h:55-57; one_file.carbon:437); conclusion stands — no raw-dump golden mentions `UnformedInit` |
| rev 2b m-3: `ExportClassToCpp` :277-280 passes the name-scope result unchecked (pre-existing) | D-UN-7 records it, unreachable for unions only under D-UN-6; re-check on any D-UN-6 relaxation |

Re-review (rev 2a) items verified with no change, recorded: D-UN-9's
mechanics (a)-(d) including `BuildCustomWitness` with empty values, the
blanket impl's constraint path through `EvalLookupSingleImplWitness`,
and `MakeUninitialized` → poison with the in-place `InitializeStorage`
emitting nothing; D-UN-7's callers null-check; the imported leg's
canonical-decl identity finds `impl forall [T] MyBox(T) as Copy` for
`MyBox(i32)`; the §5 deltas are consistent.

Findings verified and accepted without change: everything both reviews
listed as verified (VARIANTS5, the three-entry `DeclIntroducers` table,
`ClassFields`/import_ref.cpp:2019, `CustomLayoutType` completion, the
fold suppression and one-element `ClassInit`, the `PrimitiveCopyable`
bypass, the UN-2 crash sites, diagnostics, conformance conventions, no
`union` identifier migrating; §0.2 items 1-12, D-UN-1/4/6/8,
residue-by-title, break conditions).

## Sign-off

**SIGNED OFF FOR IMPLEMENTATION, 2026-09-27 (rev 2b).** Rev 2 folded
the two adversarial reviews; rev 2a (prelude-trusted `Copy` impls) was
auto-adopted under R29(a); the focused re-review of rev 2a returned
SIGN-OFF-WITH-AMENDMENTS, whose five mechanism-spelling items are folded
as rev 2b with no decision changes. Implementation proceeds UN-1 first
(§3), UN-2 after EH-B per §0.4/R-12. Later amendments continue to be
folded in place, each marked "(amended <date>, review fold: ...)".

## Landed notes (2026-09-27)

UN-1 landed on claude/carbon-fork-0-1-unions: bd680c842 (lex + parse),
d0cdd474e (check), 8a8754198 (goldens + conformance), b19f105e5 (docs),
then d96369b93 (deferral fix) and e54a7e1a7 (implementation-review
fixes). Ledger, gap-analysis row and decision-log entry ("UN-1: native
`union` declarations (2026-09-27)") are the discharge commit. UN-2 is
next, after EH-B (§0.4, D-UN-7). Deltas from this plan, honestly:

-   **`str` is `Core.String` — D-UN-2(ii), §4.A `fail_nontrivial_field`
    and §8.6's doc text were WRONG.** check/literal.cpp resolves the
    `str` spelling through `CoreIdentifier::String`, so a `str` field IS
    a `Core.String` field and is admitted under the rev 2a trust
    boundary (`String`'s `Copy` impl is declared in package `Core` over a
    trivially destructible `{ptr, size}` repr). The planned failing
    subfile could not be written; `str` is pinned as ACCEPTED beside
    `Core.String` in `aggregate_fields`, and the doc amendment lists TWO
    conservatively rejected field types (choice-typed, imported C++-typed;
    review fix e54a7e1a7 corrected the count). The §8.5 residue list
    loses nothing: no `str` item was planned.
-   **check/BUILD needs no edit** — §1.A.3, §2.A.4 and §6.A item (16)
    said check/BUILD lists sources explicitly; it globs `handle_*.cpp`
    (check/BUILD:240-241), so handle_union.cpp was picked up without a
    BUILD change. §6.A's "25 source files" is therefore 24 plus the three
    parity sites below.
-   **`BuildClassOrUnionDecl` takes the `NameComponent`** (check/class.h:
    24-28: `(Context&, Parse::AnyClassDeclId, bool is_definition,
    NameComponent name, DeclIntroducerState introducer, Lex::TokenKind
    decl_kind)`); §1.A.3 omitted the popped name from the signature.
-   **Three class-shape parity sites beyond §2.A's inventory**, found by
    auditing every `NodeKind::Class*` switch: check/node_id_traversal.cpp
    (`UnionDefinitionStart`/`UnionDefinition` in the deferred-definition
    scope kinds), sem_ir/formatter.cpp (`IsDefinitionStart`, so
    `//@dump-sem-ir` ranges cover a union body), and
    language_server/handle_document_symbol.cpp (`SymbolKind::Struct`,
    clangd's kind for C++ unions).
-   **The deferral fix (d96369b93) — a review miss per R28(d).** The
    first hosted autoupdate fill (run 36313187966, 17 new goldens) showed
    method bodies inside a union body checked EAGERLY
    (`IncompleteTypeInFunctionParam` / `IncompleteTypeInMemberAccess`;
    lower/testdata/union/basic.carbon `method` blanked). The PARSER
    decides deferral: `ParsingInDeferredDefinitionScope`
    (parse/context.cpp:461-476) registers a `DeferredDefinition` only
    for the class/interface/regular scope loops under the
    class/impl/interface/named-constraint definition-finish states, and
    the union states were in neither list — so the check-side scope
    kinds added in node_id_traversal.cpp never saw a deferred definition
    to replay. Both lists now include `DeclScopeLoopAsUnion` /
    `DeclDefinitionFinishAsUnion`, mirroring class. The plan named the
    check-side parity site and nobody asked where deferral is decided.
    `impl_member` in the same fill was a test-spelling defect: `u.Get()`
    needs `extend impl as I`, as for classes (the plain impl is reached as
    `u.(I.Get)()`); the subfile now uses the design's "as in classes"
    spelling. `fail_virtual_method` uses a bodied `fn` (its surviving
    CHECK lines carried `@LINE` offsets relative to the stripped ones).
-   **Tree-sitter**: utils/tree_sitter/queries/highlights.scm:134 carries
    `; "union"` COMMENTED, on the `final`/`friend` precedent (:102, :106)
    — grammar.js has no `union` token (`grep -c union grammar.js` = 0)
    and an active capture for a token the grammar lacks fails query
    loading. §0.1 row 14 listed the file as a plain keyword edit. Residue
    "tree-sitter union grammar" (W-091).
-   **One pre-existing golden moved — §6.A's "Existing goldens that move:
    NONE predicted" was false as written, and the §8.1 stop rule fired.**
    `git diff origin/trunk...HEAD --diff-filter=M -- toolchain/check/testdata
    toolchain/lower/testdata toolchain/parse/testdata` lists exactly one
    file: check/testdata/basics/raw_sem_ir/cpp_interop.carbon (1 line),
    whose `classes` entry gains `is_choice: 0, is_union: 0` — the text
    the rev A m-2 `PrintClassFields` amendment (§1.A.3) itself added. The
    m-2 fold never updated §6.A, and the rev 2b m-2 argument ("no raw-dump
    golden mentions `UnformedInit`") looked at the interface tag, not the
    class fields, although the same raw_sem_ir directory prints every
    class. Commit 8a8754198 predicted the move before the fill; the stop
    was resolved by inspection (the diff is exactly the amendment's text)
    rather than by halting. Every other golden in the diff is new.
-   **§8.4 reconciliation greps, as actually run at e54a7e1a7:**
    -   `grep -rn 'union export' toolchain` → check/cpp/export.cpp:152
        and :290 (the two D-UN-7 guards) plus
        check/testdata/union/fail_todo_export.carbon. As predicted (two
        guard sites, one golden).
    -   `grep -rn 'generic union' toolchain` → the TODO string at ONE
        site, check/class.cpp:708 (inside `CheckCompleteUnionType`, the
        static helper `ComputeUnionObjectRepr` calls), plus comments in
        check/class.h:48-49, check/handle_union.cpp:27 and
        parse/testdata/union/generic.carbon:12, and the golden
        check/testdata/union/fail_todo_generic.carbon. §8.4 named "the
        `ComputeUnionObjectRepr` site" — same function family, one TODO.
    -   `grep -rn 'Builtin conversion does not apply'
        toolchain/check/convert.cpp` → one hit, :1009 (the non-union
        imported-class bailout), directly after the `is_union` branch at
        :1004-1006. As predicted.
    -   `grep -rn 'payload region of a payload-carrying choice' toolchain`
        → ONE line, check/convert.cpp:740 (the `ChoicePayload` fill
        comment, which is choice-specific and was not meant to change).
        §8.4 expected "the two refreshed comments": the
        custom_witness.cpp `CanDestroyClass` comment (:315-320) IS
        refreshed — it now reads "the payload region of a payload-carrying
        choice ... or the object representation of a native `union`" —
        but the phrase wraps across two lines, so the single-line grep
        misses it. A grep-shape miss, not a code miss.
    -   Diagnostic-kind uniqueness: each of `UnionWithoutFields`,
        `UnionFieldNotTriviallyCopyable` (check/class.cpp),
        `UnionInitNotSingleField`, `UnionInitUnknownField`
        (check/convert.cpp) has one kind.def line and one
        `CARBON_DIAGNOSTIC` definition + one emit site in exactly one
        .cpp (grep count 2 in that file, 1 in kind.def, 0 elsewhere).
    -   New TODO strings: `union export` 2 sites (both deleted at UN-2),
        `generic union` 1 site. `is_union` reads: 19 non-testdata lines
        across sem_ir/class.h, check/import_ref.cpp, class.cpp,
        handle_union.cpp, convert.cpp, eval_inst.cpp, custom_witness.cpp,
        cpp/export.cpp, cpp/impl_lookup.cpp.
-   **Verification (R28, hosted-only):** first autoupdate 36313187966
    (17 new goldens filled, the deferral defect surfaced). Second
    autoupdate, after d96369b93, run 36314113850: refilled clean. A first
    gate (run 36315119109) failed on one non-converged Clang snippet line
    number in fail_todo_export.carbon (the previous fill's layout); a third
    autoupdate (run 36316933295) converged it. Conformance run
    36315125503: 110/0/26 over 136, 45/56 bullets, exactly the §5.A delta
    on the post-W-012 base. Of record after merging trunk with EH-B:
    gate run 36318283448 green, conformance run 36318245113 at 114/0/25
    over 140, 45/56 bullets (the same delta on the post-EH-B base). Implementation review: one review,
    APPROVE-WITH-FIXES (the doc count; `Field::index` assignment moved
    before the generic gate; discharge artifacts).
-   **Residue ids allocated at discharge** (assuming EH-B takes
    W-083..W-085; verified at merge): W-086 union fields of choice type;
    W-087 union fields of imported C++ type; W-088 generic unions and
    unions nested in generic scopes; W-089 union member-restriction
    diagnostics; W-090 invalid-representation reads yield poison in 0.1;
    W-091 tree-sitter union grammar; W-092 union field copy predicate is
    textual-order dependent for user impls (the local-store leg of
    `HasUserCopyImplOutsideCore` enumerates `impls()` at the union's `}`,
    so a file-declared impl AFTER the union is admitted — an unpinned
    soundness hole D-UN-2 did not foresee; `order_independent_i32` pins
    only the import-materialized case); W-093 user blanket `Core.Copy`
    impls are invisible to the union field predicate (the class-keyed
    match skips non-`ClassType` selves such as `impl forall [T: type] T
    as Copy` declared outside `Core` — the price of rejecting the
    symbolic-self shortcut, recorded rather than papered over).

## UN-2 landed notes (2026-09-28)

UN-2 landed on claude/carbon-fork-0-1-un2, cut from trunk at c0c57285f
(after EH-B #42 and UN-1 #43 had merged — the §0.4/D-UN-7 sequencing,
met without a rebase): 23fc16583 (check/cpp + sem_ir), f0970f148
(goldens + conformance), ad2367435 (docs), then the 2026-09-28 weekly
trunk sync 46f9d2112, the hosted autoupdate fill 4f005ecdd and the
implementation-review fixes 3f89d7caa. Ledger, gap-analysis row and
decision-log entry ("UN-2: union C++ interop (2026-09-28)") are the
discharge commit. Deltas from this plan, honestly:

-   **The import subfiles are a NEW file, not appended to
    class/import/union.carbon as §4.B wrote.** The landed file uses the
    `convert` minimal prelude (`INCLUDE-FILE:
    toolchain/testing/testdata/min_prelude/convert.carbon`, `as` and copy
    parts only), which lacks `Core.Destroy`, `Core.Optional` and the
    `IntLiteral` → `i32` conversion that `var u: Cpp.Pair = {.a = 1}`
    and the by-value calls need under the full prelude. So the positives
    are check/interop/cpp/class/import/union_init.carbon
    (designated_init, empty_init, copy, by_value) and the negatives are
    fail_union_init.carbon (fail_init_two_fields, fail_init_unknown_field,
    fail_copy_nontrivial_member, and the review's fail_init_non_aggregate)
    — fail_ subfiles never share a positive file, per the fork golden
    rule. The by-value probe `SumLo(Carbon::Wide)` is its own file,
    export/union_by_value.carbon, so a `fail_` rename would not have
    touched the positives; it was not needed.
-   **§4.B's precedent citation for `MakeWide` was WRONG.**
    function/export/generic.carbon:41-46 defines `Carbon::B G()` inside
    the inline C++ block, and nothing in that file calls it from Carbon
    (`grep -n 'Cpp\.G' generic.carbon` is empty; the only `Cpp.` hits are
    the namespace import). `Cpp.MakeWide(1)` (check/export/union.carbon;
    conformance union_cpp_export) is therefore the first Carbon-side call
    through a return-address thunk for a Carbon-owned record. The fill
    passed it (a `MakeWide__carbon_thunk` declaration and an ordinary
    call), so nothing was restructured and no residue is filed — but the
    claim is recorded because a failure would have been misread as a
    union defect.
-   **`[4 x i8]`, not `[8 x i8]`, for the lower import golden.** §4.B's
    "`alloca [8 x i8]`" for lower/interop/cpp/class/import/union_init.carbon
    belongs to the conformance program's three-member `Pair` (`int a;
    int b; int* p;`); the golden's `Pair` is `{int a; int b;}`, 4 bytes,
    so the fill shows `alloca [4 x i8], align 4` and offset-zero GEPs
    over `[4 x i8]`. The exported `Wide` is `[8 x i8]` as planned.
-   **The aggregate gate (review MAJOR, 3f89d7caa).** As landed in
    23fc16583, `is_union` on import let every imported union take the
    `ConvertStructToUnion` arm, so a union with a user-provided
    constructor (`union U { U() : a(0) {} int a; float f; };`) was
    designated-initializable from Carbon — contradicting unions.md's
    "Carbon code is never _more_ permitted than C++ code with such a
    union" (:555-558) while the landed `{}` path admits aggregates only.
    §1.B.1's "identically to native unions" was read too literally: the
    design's identity is about the conversion, not about which unions
    admit it. Fixed at the root: `IsImportedCppAggregate`
    (check/cpp/import.{h,cpp}: `clang_decls().Lookup` of the first
    declaration, `getDefinition()`, `isAggregate()`) gates the arm for
    cpp-scope classes (convert.cpp:1005-1016); a non-aggregate falls
    through to the `Builtin conversion does not apply` bailout and the
    ordinary `ConversionFailure`. Two MINORs in the same commit: the
    `ClassInit` fold suppression keys on a `CustomLayoutType` repr, not
    `is_union` alone (the empty imported union's `StructType{}`
    initializer keeps folding); import.cpp says `is_union` is set on
    definition import only.
-   **`static_method` subfile added** to export/union.carbon
    (`Carbon::Wide::Zero()`, the union as a C++ name scope) beyond §4.B's
    single `exported` subfile — it pins the `ExportNameScopeToCpp` path
    whose UN-1 guard was deleted.
-   **§8.4 reconciliation greps, as actually run at 3f89d7caa:**
    -   `grep -rn 'union export' toolchain` → empty. As predicted (both
        guards and fail_todo_export.carbon gone).
    -   `grep -rn 'Builtin conversion does not apply'
        toolchain/check/convert.cpp` → one hit, :1020 (the non-union
        imported-class bailout, now also the non-aggregate union's
        landing). As predicted; the line moved from :1009 with the gate.
    -   `git diff origin/trunk...HEAD --diff-filter=M --
        toolchain/check/testdata toolchain/lower/testdata
        toolchain/parse/testdata` → empty. §6.B's "existing goldens that
        move: NONE" held (UN-1's one raw_sem_ir move is already on
        trunk).
    -   `grep -rn 'generic union' toolchain` → unchanged from UN-1 (the
        one TODO site check/class.cpp:708, its comments and golden).
    -   `grep -rnE 'Carbon::[A-Z][A-Za-z]* [a-z_]*[,)]'
        toolchain/check/testdata/interop/cpp` minus the union goldens →
        still empty: `SumLo` remains the only by-value-parameter crossing
        of an exported Carbon record in the tree.
-   **Verification (R28, hosted-only):** autoupdate run 36438032097
    filled the six new goldens (4f005ecdd) with zero pre-existing goldens
    moved; the R-11 arbiter (`static_assert(__is_union/sizeof/alignof)`)
    and the by-value probe both PASSED, so D-UN-8's contingency and rev B
    F-5's drop rule were not exercised. Second autoupdate after
    3f89d7caa: run 36445060391, success (refill of
    fail_init_non_aggregate and empty_init). Gate run
    36447075548 green (a first gate, 36440202472, failed on one
    unconverged Clang snippet line number). Conformance run 36447037687:
    116/0/25 over 141, 45/56 bullets — the expected delta (the plan's
    "over 142" assumed a 140 base; the base was 139)
    (the §5.B delta PASS +2 / total +2 on UN-1's post-EH-B base 114/0/25
    over 140; the unions bullet was already PASS at UN-1, so the bullet
    count is unchanged). Implementation review: one review,
    APPROVE-WITH-FIXES (the aggregate gate; the repr-keyed fold
    suppression; the `is_union` comment).
-   **Residue: none new.** Every §8.5 item was filed at UN-1
    (W-086..W-093); the conditional "exported union passed by value into
    C++" did not arise. W-087 (union fields of imported C++ type) is NOT
    lifted: `IsImportedCppAggregate` serves the initialization gate only,
    and the field predicate's cpp-scope arm is still the separate review.
    §0.2 items 5-8 are recorded verbatim in W-015's notes; item 9 in
    W-007's.
