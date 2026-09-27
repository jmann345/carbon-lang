<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Overloading plan: `overload fn` closed sets (OV-1 W-024, OV-2 W-025, OV-3 W-026)

**Status:** REV 1, READY FOR THE TWO ADVERSARIAL PLAN REVIEWS (R29(c)),
2026-09-27. Branch `claude/carbon-fork-0-1-overload` off trunk c9708a0ea
(post-PR #41: W-012 landed). Trunk's floor is **108 PASS / 0 FAIL / 27
SKIP over 135**, 44/56 bullets, gap-analysis header (fork/gap-analysis.md:18)
27 DONE / 20 PARTIAL / 7 MISSING / 2 DESIGN-ONLY. EH-B (../carbon-ehb) and
UN-1 (../carbon-unions) land before OV-1 and each add programs, so every
count in this plan is a DELTA from trunk at rebase time; the absolutes
given are for the post-W-012 base only and are recomputed by the delta
rule at each rebase (§5, §8.3). All toolchain, core, docs and fork line
numbers are against trunk c9708a0ea and were re-verified for this plan;
where the ledger's or the option paper's citations are stale the
correction is recorded in §0.2. UN-1 inserts lines in
toolchain/lex/token_kind.def (the `Union` introducer at :175), in
parse/node_kind.def and parse/handle_decl_scope_loop.cpp, and in
diagnostics/kind.def, so the OV-1 implementer re-verifies those four
files' line numbers at rebase; every OV-1 hunk in them is additive and
disjoint from UN-1's (§6.A). The container cannot build the toolchain
(clang 18 < 19), so this plan pre-registers every golden and diagnostic
outcome for the hosted autoupdate to confirm or refute (R28(b)).

**Items:** W-024 ("OV-1: `overload fn` non-generic same-library sets —
keyword, modifier, OverloadSet SemIR store, first-match resolution loop,
signature-fingerprint mangling", size M), W-025 ("OV-2: generic
overload-set members (non-diagnosing deduction) + cross-library set
import", size M, blocked_by W-024) and W-026 ("OV-3: overload-set export
to C++ + documented-divergence conformance tests + docs", size M,
blocked_by W-024 and W-007). **Design authority, not reopened:**
fork/decision-log.md F-009 (:1286-1293: "Closed same-library sets
(p000998), declaration-order first-match (p002875), explicit marker on
every member (preserves p003763 typo diagnostics), no value patterns in
0.1. Exported sets resolve under C++ rules: documented divergence with
bidirectional conformance tests") and the option paper
fork/design-sprint/function-overloading.md, Option A (:190-261) with the
recommendation (:348-389) and the open questions the paper answers with a
recommendation (:416-450); the paper is the research record and is not
edited. **There is no ratified docs/design page:** the F-008..F-011 design
docs are STRANDED on `claude/carbon-fork-0-1-7mwfb7-design-docs`
(fork/ORCHESTRATION.md:311, gated on an unanswered veto digest), and
docs/design/functions.md has no overloading section (its headings, :46-903,
go from "Redeclaration matching" :607 to "Function types and values"
:631). This workstream therefore authors the normative section itself as a
dated amendment (D-OV-8, §8.6), under R29(a).

**Milestone bullet this plan flips** (fork/gap-analysis.md:57): "Functions:
function overloading (Carbon-native)" — MISSING → PARTIAL at OV-1 → PARTIAL
at OV-2 → DONE at OV-3 (§8.6). R7: the bullet string is copied
character-for-character into every conformance header.

## §0 Audit: what already exists, and where the ledger is stale

### §0.1 Sub-feature table (verified in-tree at c9708a0ea)

| # | Design element (F-009 / paper Option A) | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `overload` marker keyword (paper :418-421, recommendation: modifier on every member) | MISSING | `grep -n overload toolchain/lex/token_kind.def` is empty; the keyword block is :178-245 (`Or` :217-218, `Override` :219); the declaration-modifier keywords are the parse x-macro list `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER(...)` at parse/node_kind.def:414-427 (`MustEval` :422, `Override` :423) |
| 2 | Parser: modifier before `fn` | MACHINERY LANDED, one x-macro line away | every consumer of the modifier list is x-macro generated: the typed leaf node (parse/typed_nodes.h:1327-1330), `TryHandleAsModifier` (parse/handle_decl_scope_loop.cpp:263-275), the next-token list of `ResolveAmbiguousTokenAsDeclaration` (:240-244), the statement-level dispatch to `DeclAsRegular` (parse/handle_statement.cpp:54-56), the check handler `HandleParseNode(Parse::Name##ModifierId)` (check/handle_modifier.cpp:111-118). `FunctionSignature` (typed_nodes.h:570-581) already carries `llvm::SmallVector<AnyModifierId> modifiers` (five fields; the eight-field cap of common/struct_reflection.h is not approached). Zero new parse states or node fields |
| 3 | Check: modifier set membership and ordering | MACHINERY LANDED | `CARBON_KEYWORD_MODIFIER_SET` groups (check/keyword_modifier_set.h:29-58) with the order groups Access/Extern/Extend/Decl/Static/Evaluation (:17-25); `HandleModifier` orders and rejects repeats (handle_modifier.cpp:41-109); `LimitModifiersOnDecl` diagnoses `ModifierNotAllowedOnDeclaration` "`{0}` not allowed on `{1}` declaration" (check/modifiers.cpp:100-107); the function allowed set is handle_function.cpp:90-94 |
| 4 | Redeclaration path an overload set replaces (paper :43-49) | LANDED, today's errors | `TryMergeRedecl` (check/handle_function.cpp:190-268): a previous `FunctionDecl` under the same name goes to `MergeFunctionRedecl` (:151-187) → `CheckFunctionTypeMatches` → `CheckRedeclParamsMatch` (merge.cpp:531-561) → `RedeclParamCountDiffers` (:384-398), `RedeclParamDiffersType` (:261-272), `RedeclParamDiffers` (:218-226), `RedeclParamSyntaxDiffers` (:505-512), `FunctionRedeclReturnTypeDiffers` (function.cpp:265-290); a non-function previous inst goes to `DiagnoseDuplicateName` (:256-259; name_lookup.cpp:696-707). Pinned today by check/testdata/function/declaration/fail_redecl.carbon (`fn C(); fn C(x: ());` → `RedeclParamCountDiffers`) |
| 5 | Non-diagnosing signature comparison (member identity) | LANDED | `CheckRedeclParamsMatch(..., bool diagnose, bool check_syntax)` (merge.cpp:531-561) with `CheckRedeclParam`'s `check_syntax` gating the binding-name comparison (:320-323) and `diagnose` gating every emit (:214-227, :260-273, :354-356, :381-383) |
| 6 | SemIR entity to mirror (paper :161) | LANDED for C++ sets | `SemIR::CppOverloadSet` (sem_ir/cpp_overload_set.h:22-59: name_id, parent_scope_id, a Clang `UnresolvedSet<4>`), `CppOverloadSetId` (sem_ir/ids.h:291-296; registered in sem_ir/id_kind.h:43), the store (file.h:171-176, :365-366; constructed file.cpp:44; NOT printed by `OutputYaml` file.cpp:151-174), `CppOverloadSetType`/`CppOverloadSetValue` (sem_ir/typed_insts.h:575-597; inst_kind.def:58-59), `GetCppOverloadSetType` (check/type.cpp:180-185), and every dispatch site listed in §1.A.3 |
| 7 | Call path dispatch on callee kind (paper :162) | LANDED for C++ sets | `GetCallee` recognizes a C++ set by its callee's TYPE (sem_ir/function.cpp:58-69) and returns `CalleeCppOverloadSet` (function.h:373-379); `PerformCall` dispatches on the variant (check/call.cpp:345-368, the `CalleeCppOverloadSet` arm :362-366 → `PerformCallToCppFunction`, cpp/call.cpp:54-104); instance binding treats a set as a possible instance method (member_access.cpp:63-81, :402-419) |
| 8 | Tentative (non-diagnosing) conversion and deduction (paper :163) | HALF-BUILT, as the ledger says | `ConvertToValueOfType(..., diagnose=false)` / `TryConvertToValueOfType` (check/convert.h:175-196, convert.cpp:2263-2269); `DeductionContext` already carries `diagnose_` (deduce.cpp:169, :234, :257-261) but `DeduceGenericCallArguments` hard-codes `/*diagnose=*/true` (:625-627) while `DeduceImplArguments` passes false (:654-656). **The discard idiom exists:** `DeduceImplArguments` pushes a scratch inst block and a `GenericId::None` generic region, deduces, then `generic_region_stack().Pop()` + `inst_block_stack().PopAndDiscard()` (deduce.cpp:666-678) — the comment names exactly the "Converted instructions" side effect the loop must discard |
| 9 | Mangling (paper :164) | COLLIDES today | `Mangler::MangleImpl` (sem_ir/mangler.cpp:190-259) emits `_C` + name + special-kind marker + inverse scope + a fingerprint only when `IsPrivateToLibrary` (:252-256) + the specific fingerprint (:258); two non-generic same-scope functions of one name would get one symbol, and lowering's `llvm_module().getFunction(mangled_name)` early-return (lower/file_context.cpp:394-416) would SILENTLY reuse the first — the R15 hazard §7 R-4 pins. **Inst fingerprints are NOT cross-file stable:** the fingerprinter hashes an inst's kind, type and operands in the file it is read from (inst_fingerprinter.cpp:736-755), an imported `FunctionDecl` is created with `decl_block_id = InstBlockId::Empty` (import_ref.cpp:2391-2394), and the landed TODO golden lower/testdata/function/generic/cross_library_name_collision_private.carbon (`todo_use.carbon`: "Currently it calls the same function in both") shows the private-name fingerprint failing to separate two libraries' `F` — so a "signature fingerprint" (the W-024 title) is the wrong mechanism; D-OV-5 mangles by set-relative index |
| 10 | Cross-library / api-to-impl set import (paper :165) | MISSING; the C++ precedent is a TODO gate | `HandleUnsupportedCppOverloadSet` (import_ref.cpp:2254-2267) resolves an imported `CppOverloadSetType`/`CppOverloadSetValue` to `context.TODO(LocId::None, "Unsupported: Importing C++ function `{0}` indirectly")` + `ErrorInst`; the api-to-impl path is the SAME resolver (`ImportRefUnloaded` entries per scope member :1487-1505, `LoadImportRef` :5090-5135, `ApiForImpl` :74, :2814, :2909) — which is why OV-1 gates api/impl sets and OV-2 lifts both at once (D-OV-7, §0.4) |
| 11 | Export (paper :166, :235-243) | PER-FUNCTION LANDED; sets unreachable | C++ name lookup enters `FindExternalVisibleDeclsByName` → `LookupQualifiedName` → `MapInstIdToClangDeclOrType` (cpp/generate_ast.cpp:333-405, :199-256), whose `StructValue`-of-`FunctionType` case exports ONE function (:231-245) and whose `default:` returns nullptr (:253-254) → `SetNoExternalVisibleDeclsForName` (:402); `SetExternalVisibleDeclsForName` already takes a decl LIST (:399, :421). Each exported function's thunk carries an asm label equal to its Carbon mangled name (export.cpp:893-899), so distinct member manglings give distinct C++ symbols with no export.cpp change |
| 12 | Lowering (paper :167) | NO CHANGE NEEDED | a resolved call's callee is a name reference to the chosen member's `FunctionDecl`; lowering reads it through `GetCalleeAsFunction` (lower/handle_call.cpp:738, :752); the set value/type insts are constants and lower like `CppOverloadSetValue`/`CppOverloadSetType` (lower/constant.cpp:303-307 `GetLiteralAsValue`; lower/type.cpp:862-879 empty struct) |
| 13 | Language server | NO CHANGE NEEDED | handle_document_symbol.cpp:132-175 keys on `FunctionDecl`/`FunctionDefinitionStart` node kinds; a modifier leaf is never a symbol; UN-1's parity audit of every `NodeKind::Class*` switch has no analogue here because no node kind is added |
| 14 | Implicit conversions the first-match rule is observed through | VERIFIED in the prelude | `Int(From) as ImplicitAs(Int(To))` for `From: IntFitsIn(Int(To))` (core/prelude/types/int.carbon:62-68) — `i32 → i64` widens implicitly; `IntLiteral as ImplicitAs(Int(To))` (:31-33); NO `Bool as ImplicitAs(...)`, NO integer-to-float implicit conversion (`grep -rn 'as ImplicitAs' core/prelude`, the only non-int impls are `CharLiteral as ImplicitAs(Char)`, `Optional`, `CppCompat`) — the §5 EXPECT values rest on these three facts |
| 15 | Conformance | SKIP stub | fork/conformance/programs/functions/overloading_native.carbon: bullet :5, EXPECT lines :6-9, SKIP line :10 (says "MISSING with no design" — stale since F-009), strawman :22-23 commented, guard body returns 1 (:25-33) |
| 16 | Docs | MISSING everywhere the ledger points | docs/design/functions.md has no section; docs/design/pattern_matching.md:696 still says "We do not yet have an approved design for overloaded functions"; docs/design/interoperability/README.md:210 is `### TODO: Overload resolution`; docs/design/README.md:3878-3881 is the "Pattern matching as function overload resolution" placeholder (the ledger says :3822 — §0.2 item 3); docs/design/lexical_conventions/words.md keyword list (:47-104; `or` :86, `override` :87) lacks `overload`; grammars: utils/vim/syntax/carbon.vim:37 (`carbonClassMethodDeclarationMod private virtual abstract protected impl`), utils/vscode/carbon.tmLanguage.json:417 and utils/textmate/Syntaxes/carbon.tmLanguage:524 (the `auto|destructor|forall|friend|observe|override|require` alternation), utils/textmate/Samples/keywords.carbon:35, utils/tree_sitter/queries/highlights.scm:121 (`; "override"` COMMENTED — the UN-1 landed lesson: grammar.js lacks the token) |

### §0.2 Ledger and paper claims found stale (each corrected at §8.5 discharge)

1.  **W-024 evidence `fork/conformance/programs/functions/overloading_native.carbon:6`**
    points at the `EXPECT-EXIT` line; the SKIP line is :10 (the W-009
    stale-citation pattern, fork/unions/plan.md §0.2 item 2).
2.  **W-024 title "signature-fingerprint mangling" and the paper's
    "`MangleFingerprint` already exists" (:164):** a fingerprint of the
    member's declaration is not cross-file stable (§0.1 row 9) and the
    private-name precedent it would copy is itself a landed TODO
    (cross_library_name_collision_private.carbon). D-OV-5 mangles by
    set-relative index instead; the title's mechanism is recorded as
    rejected in the ledger notes.
3.  **W-026 notes "design README:3822 placeholder":** the section is at
    docs/design/README.md:3878-3881 (W-012's and EH-A's README edits moved
    it). `interoperability/README.md:210` is accurate.
4.  **Paper :159 "`parse/keyword_modifier_set.h`":** the file is
    toolchain/check/keyword_modifier_set.h; the parser has no modifier set,
    only the node-kind x-macro (§0.1 row 2).
5.  **Paper :45-49 line numbers:** `DiagnoseDuplicateName` is called at
    handle_function.cpp:257 (paper: :250); `TryMergeRedecl` is :190-268
    (paper :183-261); `Mangler::Mangle` is mangler.cpp:261-266 with
    `MangleImpl` :190-259 (paper :186); `ExportFunctionToCpp` is
    export.cpp:1500 (paper :1023) and `clang::FunctionDecl::Create` is at
    :824 and :1113 (paper :455); `PerformCall` :345-368, `convert.h:175-196`
    and `deduce.h:23-28` are exact.
6.  **W-024 says "same-library sets"; W-025 says "cross-library set
    import".** The api-file/impl-file half of "same library" is the import
    resolver (§0.1 row 10), that is W-025's machinery. OV-1 therefore delivers
    same-FILE sets and TODO-gates a set reached through any import
    (including `ApiForImpl`), on the `HandleUnsupportedCppOverloadSet`
    precedent; OV-2 lifts the gate for api/impl and cross-library at once.
    D-OV-7 records the re-cut; the W-024/W-025 titles gain a note at
    discharge, not a rewrite.
7.  **W-026 blocked_by W-007 ("five-way contention refactor-first"):** the
    precondition "before any two start concurrently" was met by SEQUENCING
    for EH-B (fork/eh/plan.md §0.2 item 3, §1.B.9: "landed without a
    refactor: every EH-B edit ... is ADDITIVE") and UN-2 (fork/unions/plan.md
    §0.2 item 9, D-UN-7). OV-3 touches NONE of W-007's three files
    (export.cpp, thunk.cpp, type_mapping.cpp): its C++-side edits are in
    cpp/generate_ast.cpp (§1.C), which is not a contention file, and each
    member exports through the unchanged `ExportFunctionToCpp`. D-OV-9
    discharges the edge by the same precedent (additive arms + sequencing
    after UN-2), never by the refactor.
8.  **fork/gap-analysis.md:57 evidence text** ("nothing is implemented — a
    second `fn Describe` with a different signature is a redeclaration
    error") is accurate today; it is rewritten at each slice (§8.6).
9.  **Paper :224-226 "Methods overload the same way (`overload fn
    Append[addr self: Self*](x: i32);`)":** the working method syntax is
    `fn F(self)` / `fn G(ref self)` with `self` as the FIRST EXPLICIT
    parameter (check/testdata/class/method/method.carbon:5-9;
    handle_function.cpp:572-583 diagnoses `self` in the implicit list). The
    plan's testdata uses the working spelling (R3); the docs section
    (§8.6) spells it that way too.
10. **Paper :163 "non-diagnosing `DeduceGenericCallArguments`":** the
    `DeductionContext` already has the flag (§0.1 row 8); OV-2's change is a
    parameter on the entry point and the discard scope, not a new variant.

### §0.3 Decisions this plan auto-adopts (R29(a): design recommendation under V-2/V-3, veto-able after the fact)

None reopens F-009 or a paper recommendation; each fixes an
implementation choice the design leaves to the toolchain, or draws a 0.1
line the paper itself drew ("stageable: non-generic sets first ... generics
second, export third", :253-255).

-   **D-OV-1 — `overload` is a new `CARBON_KEYWORD_TOKEN(Overload,
    "overload")` and a declaration MODIFIER in the `Decl` order group.**
    Lex: one line in toolchain/lex/token_kind.def between `Or` (:217-218)
    and `Override` (:219), alphabetical, not wrapped in
    `CARBON_TOKEN_WITH_VIRTUAL_NODE` (a modifier keyword adds no virtual
    node — the `Abstract`/`Virtual` precedent :178, :241). Parse: one line
    `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER(Overload)` in
    parse/node_kind.def between `MustEval` (:422) and `Override` (:423);
    every parser and checker consumer is x-macro generated (§0.1 row 2).
    Check: `X(Overload)` in the "at most one of these declaration
    modifiers" group of `CARBON_KEYWORD_MODIFIER_SET`
    (keyword_modifier_set.h:41-51, alphabetical after `Impl` :48) and `|
    Overload` in `KeywordModifierSet::Decl` (:149-152); the group
    `static_assert`s (:158-175) then hold without change. V-3 check:
    upstream has no overloading and its own placeholder spells `overloaded
    fn` (p002875 "Overloading": "using placeholder syntax `overloaded fn
    Abs...`"); F-009 chose `overload` (paper :418-421); a rename is a
    mechanical migration. Keyword fallout, verified: `grep -rnw overload`
    over every `.carbon` under toolchain/, core/, examples/ and
    fork/conformance/programs finds the word only in comments and in the
    header-name string `"overload.h"` (check/testdata/interop/cpp/class/import/override.carbon:28,
    :39, :92 — a string literal, not an identifier); no Carbon identifier
    migrates; `r#overload` is pinned as a raw identifier (§4.A).
    **Consequence of the Decl group, stated as a 0.1 narrowing:** `overload`
    is mutually exclusive with `virtual`/`abstract`/`override`/`impl`/
    `default`/`final`/`export`/`returned` through the existing
    `ModifierNotAllowedWith` ("`{0}` not allowed on declaration with `{1}`",
    handle_modifier.cpp:25-35) — no virtual overload sets and no
    interface-member overload sets in 0.1 (the paper already excludes
    interface members, :225-226; virtual sets would need vtable-slot
    disambiguation by signature, which `RequestVtableIfVirtual`
    handle_function.cpp:491-528 keys by name). Rejected: a seventh order
    group (resizes `ordered_modifier_node_ids` decl_introducer_state.h:31-34,
    the exhaustive `ModifierOrderAsSet` switch modifiers.cpp:54-69 under
    -Werror, and `HandleModifier`'s if-chain :47-69) for a combination no
    0.1 program needs. Break condition: a design ruling that `virtual
    overload fn` is required — then the seventh group, recorded as a
    titled residue "virtual members of overload sets" (§8.5).
-   **D-OV-2 — the entity is `SemIR::OverloadSet`, a mirror of
    `CppOverloadSet`, and the name-lookup result for an overloaded name is
    an `OverloadSetValue` inst of type `OverloadSetType`.** Store shape
    (new sem_ir/overload_set.h/.cpp beside cpp_overload_set.h/.cpp, listed
    in sem_ir/BUILD:101/:136): `{NameId name_id; NameScopeId
    parent_scope_id; llvm::SmallVector<InstId, 4> member_decl_ids;}` — the
    members are the `FunctionDecl` inst ids of the FIRST declaration of each
    member in declaration order (append-only; `CppOverloadSet` keeps its
    candidates inline the same way, cpp_overload_set.h:47-50).
    `SemIR::Function` gains `OverloadSetId overload_set_id =
    OverloadSetId::None;` (function.h, after `self_param_id` :182),
    printed by `Function::Print` ONLY when it has a value (the :243-259
    conditional pattern — the UN-1 landed lesson: `PrintClassFields`
    printed unconditionally and moved a raw_sem_ir golden). The set store
    is NOT added to `File::OutputYaml` (file.cpp:151-174 omits
    `cpp_overload_sets` too), so the eight
    check/testdata/basics/raw_sem_ir goldens do not move (§6.A).
    Justification for the mirror rather than a "first member is the
    anchor" design: (a) F-009's "naming an overload set other than as a
    callee is an error in 0.1" (paper :231-233) needs the name to resolve
    to something whose non-call use the conversion machinery can see — a
    distinct type does that (D-OV-4 step 6); an anchor `FunctionDecl` would
    silently select member 0 for `let f = F;`, an R15 violation; (b)
    `GetCallee` already identifies a set by its callee's TYPE
    (function.cpp:58-69), and `PerformInstanceBinding` already treats a set
    callee as a possible instance method (member_access.cpp:63-81), so
    method sets and `alias` of a set fall out. Break condition: none — the
    mirror is the paper's own recommendation (:161, :369-370).
-   **D-OV-3 — member identity is parameter-TYPE equality; the marker must
    be on every declaration of the name or on none; each member keeps
    p003763 redeclaration matching.** At a `fn F` declaration whose
    unqualified name resolves to a previous inst P, with M = "the introducer
    carries `overload`" (`introducer.modifier_set.HasAnyOf(Overload)`):
    -   P none, M: create the set with this member (§1.A.4).
    -   P is a local `OverloadSetValue`, M: scan `member_decl_ids` in order
        with `CheckRedeclParamsMatch(DeclParams(new), DeclParams(member),
        SpecificId::None, /*diagnose=*/false, /*check_syntax=*/false)`
        (merge.cpp:531-561 — implicit and explicit parameter patterns
        compared by kind and type, `self` included, binding names ignored
        because `check_syntax` is false :320-323, return type NOT compared
        because `CheckFunctionReturnTypeMatches` is not called). The first
        match is THE member being redeclared: `MergeFunctionRedecl(context,
        node_id, function_info, is_definition, member_function_id,
        ImportIRId::None)` runs unchanged (handle_function.cpp:151-187), so a
        differing binding name diagnoses `RedeclParamDiffers`/
        `RedeclParamSyntaxDiffers`, a differing return type diagnoses
        `FunctionRedeclReturnTypeDiffers` ("we do not permit overloading on
        return types", p002875 :248-251 as cited by the paper :114-116), a
        second definition diagnoses `RedeclRedef`, and a definition merges
        into the member (`MergeDefinition`). No match: a NEW member —
        `function_info.overload_set_id = set`, the new `FunctionDecl` inst
        id is appended to `member_decl_ids`, and the name is not re-added to
        lookup.
    -   P is a local `OverloadSetValue`, not M: diagnose
        `OverloadMarkerMismatch` at the declaration with the
        `OverloadMarkerPrevious` note at the set's first member, then recover
        AS IF marked (so a definition still merges into its member and later
        calls still resolve; one diagnostic, no cascade).
    -   P is a plain `FunctionDecl` (or an interface associated function,
        the `AssociatedEntity` arm :216-223), M: diagnose
        `OverloadMarkerMismatch` with the note at P, then `return` from
        `TryMergeRedecl` without merging — the declaration gets its own
        `FunctionId` and is not added to lookup (`MaybeAddToNameLookup`
        :271-295 already skips when `prev_inst_id().has_value()`), so today's
        `RedeclParam*` family is NOT emitted on top (one diagnostic per
        site; §4.A `fail_marker_mismatch`).
    -   P is an `ImportRefLoaded` (:229-251): OV-1 gates at the resolver
        (D-OV-7), so the arm falls through to `DiagnoseDuplicateName` after
        the resolver's `SemanticsTodo` — two diagnostics, both loud, pinned
        (§4.A `fail_todo_impl_file`); OV-2 adds the `OverloadSetValue`
        constant case (§1.B.3).
    -   Members distinguished ONLY by the `self` pattern (`F(self, x: i32)`
        vs `F(ref self, x: i32)`): the identity scan finds no type-equal
        member (pattern kinds differ, merge.cpp:250-253); a second scan over
        the explicit parameters AFTER `self` (a static in merge.cpp built
        from `CheckRedeclParams`'s loop refactored to take
        `llvm::ArrayRef<SemIR::InstId>` slices, §2.A.6) finds a match →
        `context.TODO(node_id, "`overload fn` members distinguished only by
        `self`")` and the declaration still becomes a new member (no
        cascade). This is paper open question 4's recommendation
        ("explicit parameters only; `self`-shape overloading deferred",
        :430-435).
        Rationale for "types, not syntax" as identity: with syntax as identity,
        `overload fn F(a: i32); overload fn F(b: i32);` would form a two-member
        set whose second member is unreachable, and p003763's typo catching
        (F-009's stated reason for the marker) would be lost inside sets. Break
        condition: none.
-   **D-OV-4 — resolution is a first-match loop over the members in
    declaration order, probing conversions inside the `DeduceImplArguments`
    discard scope, then committing by re-running the ordinary call path on
    the chosen member.** `PerformCallToOverloadSet` (check/call.cpp, new
    `CalleeOverloadSet` arm beside :362-366), in order:
    1.  If any `arg_id == ErrorInst::InstId`, return `ErrorInst::InstId`
        without diagnosing (the ordinary call path also stays silent on
        erroneous arguments: fail_param_type.carbon:89-90 shows `converted
        %float, <error>` feeding `call %G.ref(<error>)`).
    2.  For each member decl id in `member_decl_ids`: F = its function.
        (a) Arity: `[min, max]` from `GetExplicitArityRange(function)` — a
        static returning `{n, n}` with `n = param_patterns.size() -
        (self_id.has_value() ? 1 : 0)` (the call.cpp:61-64 rule) and a
        comment naming W-013 variadics as the reason the check is a range
        (paper :403-406). Mismatch → reason 0, next member. (b) Generic
        member (OV-2 only; OV-1 never sees one, D-OV-6): non-diagnosing
        `DeduceGenericCallArguments(..., /*diagnose=*/false)` inside the
        discard scope; `None` → reason 2, next member. (c) Conversion probe
        inside the discard scope — `context.inst_block_stack().Push();
        context.generic_region_stack().Push({.generic_id =
        SemIR::GenericId::None});` — for each explicit parameter pattern
        after `self` in order, `TryConvertToValueOfType(context, loc_id,
        arg, GetTypeOfInstInSpecific(sem_ir, specific_id, param_pattern))`
        (the merge.cpp:280-282 type read; every 0.1 member's explicit
        parameters are by-value patterns, D-OV-6); the first
        `ErrorInst::InstId` result → reason 1; then always
        `context.generic_region_stack().Pop();
        context.inst_block_stack().PopAndDiscard();` (deduce.cpp:672-678,
        verbatim order). Constants and specifics minted by a failed probe
        (an `ImplicitAs` impl lookup, a `SpecificFunction`) stay in the
        constants block exactly as failed impl lookups leave them today;
        they are not in any inst block and do not print in a
        `--dump-sem-ir` block.
    3.  First member that passes → COMMIT: `callee_id =
        BuildNameRef(context, loc_id, set.name_id, member_decl_id,
        enclosing_specific_id)` (check/inst.h:224-226; the thunk precedent
        call.cpp:273-275); if the original callee was a `BoundMethod`
        (`overload.self_id.has_value()`), re-wrap it with
        `GetOrAddInst<SemIR::BoundMethod>` over the new callee (the
        :202-209 shape); then `return PerformCallToFunction(context,
        loc_id, callee_id, GetCalleeAsFunction(context.sem_ir(),
        callee_id), arg_ids, is_desugared)` — the real conversions, return
        slot, thunk inlining and `Call` inst are the unchanged :214-306
        path. A probe/commit divergence (probe passes, commit diagnoses) is
        a plan miss (§7 R-1).
    4.  No member passes → `OverloadNoMatch` at the call, then one
        `OverloadCandidateRejected` note per member with the recorded
        reason (0/1/2) at `SemIR::LocId(member_decl_id)`; return
        `ErrorInst::InstId`. This is the paper's "lists every candidate
        with its first failure reason" (:229-230) at the granularity the
        loop knows for free.
    5.  Ranking is deliberately absent (paper :363-370, open question 2:
        "pure declaration order"). `Pick(x: i64)` before `Pick(x: i32)`
        called with an `i32` selects the FIRST (widening is an implicit
        conversion, §0.1 row 14) — the exact divergence from C++'s
        best-viable-match that OV-3 documents.
    6.  Non-call uses: `Convert`'s entry (convert.cpp, at the point where
        the source expression's type is known and before category
        conversion, beside the `ConversionTarget::Discarded` handling
        :1855-1882) diagnoses `OverloadSetNotCallee` when the source type's
        inst is an `OverloadSetType` (whatever the target), returning
        `ErrorInst`; the callee of a `CallExpr` never passes through
        `Convert` (handle_call_expr.cpp pops the callee inst and hands it to
        `PerformCall` raw), so calls are unaffected. `DiscardExpr` (:2417)
        goes through the same entry, so a bare `F;` statement diagnoses too.
        C++ sets (`CppOverloadSetType`) are NOT keyed — upstream behavior
        untouched (V-3).
        Break condition: a member that the probe accepts and the commit rejects
        (R-1), or a probe that leaves an inst in the current block (the
        `LoadImportRef` CHECK idiom import_ref.cpp:5113-5120 is the model for
        a `CARBON_CHECK` the loop adds in debug builds: the discarded block is
        popped, so nothing to check — the falsifier is a stray `converted`
        line in a §4.A dump before the `call`).
-   **D-OV-5 — mangling by set-relative index, not by fingerprint.**
    `Mangler::MangleImpl` (mangler.cpp:190-259) emits, immediately after
    `MangleNameId(os, function.name_id)` (:210) and before the special-kind
    switch (:214-247), `if (function.overload_set_id.has_value()) { os <<
    ":overload" << index; }` where `index` is the member's position in
    `overload_sets().Get(id).member_decl_ids` (found by comparing each
    entry's `FunctionDecl.function_id` with `function_id`; a CHECK that it
    is found). The `:` marker follows `:thunk`/`:core` (:222, :225); the
    inverse scope, the private fingerprint and the specific fingerprint
    follow unchanged, so `overload fn Pick(x: i64)` at file scope in
    package `Main` lowers to `@_CPick:overload0.Main` and its sibling to
    `@_CPick:overload1.Main` (hand-predictable, no hash — §4.A lower
    goldens). Stability: the index is api order (D-OV-3 appends only), an
    impl-file definition merges into the SAME member (the api set is
    imported with its member list, OV-2), and importers see the same list
    — no fingerprint of any inst is involved (§0.1 row 9). Entry point:
    `IsEntryPoint` short-circuits to `main` (:194-198), so an `overload fn
    Run` in `Main` would alias every member to `main`; D-OV-6 gates it.
    Exported thunks pick the marker up through `MangleWithPlatform`
    (:268-286) into their asm labels (export.cpp:893-899), so C++ sees N
    distinct symbols behind N same-named `FunctionDecl`s (OV-3). Rejected:
    the title's decl fingerprint (§0.2 item 2); a second `Function` field
    `overload_index` (redundant with the list; one more import mirror).
    Break condition: two members mangling equal — impossible by
    construction; falsifier: any lower golden showing one `define` for two
    members, or lowering's `getFunction(mangled_name)` early return firing
    for a member (R-4).
-   **D-OV-6 — 0.1 gates, each a `SemanticsTodo` at the DECLARATION so the
    resolution loop only ever sees supported members:** (i) a generic
    member (`function_info.generic_id.has_value()` after `BuildGenericDecl`,
    handle_function.cpp:633; OV-1 only, lifted at OV-2): "`overload fn`
    with generic parameters"; (ii) a set declared where
    `context.scope_stack().PeekSpecificId().has_value()` (scope_stack.h:137-139
    — inside a generic class, interface or impl; the value that would have
    to flow into `OverloadSetType.specific_id` the way
    `GetFunctionType(..., PeekSpecificId())` :635-637 does for functions):
    "`overload fn` in a generic scope" — stays gated through OV-3, titled
    residue "overload sets in generic scopes" (§8.5); (iii) an explicit
    parameter after `self` whose leaf pattern is not a `ValueParamPattern`
    (`ref`/`var` parameters; the handle_function.cpp:321-331 shape
    check): "`overload fn` with a non-value explicit parameter" — the probe
    of D-OV-4 is a VALUE conversion, so admitting `ref` members would make
    the probe over-accept and the commit diagnose (R-1); the member is
    still added (no cascade); (iv) `extern overload fn`: "`extern overload
    fn`" — an extern member belongs to another library's set, that is OV-2's
    import direction; (v) `overload` on `Main.Run` (`IsEntryPoint`): "`overload`
    on the entry point" (D-OV-5); (vi) a member whose access modifier
    differs from the set's name-scope entry access kind (the first member
    fixed it; `name_scope.Lookup(name_id)` → `GetEntry(...).result.access_kind()`,
    the merge.cpp:174-180 read; block scopes have no entry and skip the
    check): "`overload fn` members with differing access"; (vii) OV-1
    only: a set reached through import (D-OV-7): "overload set import";
    (viii) OV-1/OV-2: C++ lookup of a set (`MapInstIdToClangDeclOrType`
    `OverloadSetValue` arm): "overload set export"; (ix) a first marked
    declaration directly in an interface scope (`parent_scope_id` is an
    `InterfaceWithSelfDecl` scope, the handle_function.cpp:285-287 test):
    "`overload fn` in an interface" — the paper excludes interface members
    (:225-226), and `overload` is already exclusive with `default`/`final`
    by D-OV-1. Every string is
    grep-reconciled at discharge (§8.4). Break condition per gate: the
    lifting slice deletes the gate and its `fail_todo_*` pin in the same
    commit (R16(b) citation: this decision).
-   **D-OV-7 — the split is three PRs, OV-1 same-file sets first, OV-2
    import + generic members second, OV-3 export + docs completion last
    after UN-2 lands.** See §0.4. The api/impl re-cut (§0.2 item 6) is
    the load-bearing part: OV-1's resolver arms for `OverloadSetType`/
    `OverloadSetValue` are the `HandleUnsupportedCppOverloadSet` shape
    (import_ref.cpp:2254-2279 — `context.TODO(LocId::None, ...)` and
    `ResolveResult::Done(ErrorInst::ConstantId, ErrorInst::InstId)`);
    OV-2 replaces them with real resolution (§1.B.2). Break condition:
    none.
-   **D-OV-8 — this workstream authors the normative docs/design text as
    dated amendments (functions.md section at OV-1, generic/cross-library
    paragraphs at OV-2, interop README section and design README
    placeholder at OV-3).** The F-009 docs are stranded (fork/ORCHESTRATION.md:311)
    with reconstruction gated on a veto digest the owner has not
    answered; R29(a) forbids waiting on a question. The section is written
    from F-009 and the paper's Option A rules (:214-233) using the working
    syntax (§0.2 item 9), marked "(fork amendment 2026-09-27, F-009)"; if
    the stranded branch is later reconstructed, its overloading text is
    reconciled AGAINST this section (this section wins on any point the
    toolchain pins). Break condition: the owner's veto digest answer
    naming a different spelling — then a doc-only follow-up, never a
    toolchain reopen without a new F-decision.
-   **D-OV-9 — W-007 is discharged for OV-3 by the EH-B/UN-2 precedent:
    additive hunks plus sequencing.** OV-3's C++-side edits are (1) the
    `OverloadSetValue` arm of `MapInstIdToClangDeclOrType` returning a
    decl list and (2) `FindExternalVisibleDeclsByName` passing that list
    to `SetExternalVisibleDeclsForName` — both in cpp/generate_ast.cpp
    (:199-256, :396-405), not in export.cpp/thunk.cpp/type_mapping.cpp.
    Each member is exported by the unchanged `ExportFunctionToCpp`
    (export.cpp:1500) through `GetOrExportFunctionToCpp`
    (generate_ast.cpp:258-296, which keys `clang_decls` by
    `first_decl_id()` per member). If verification shows a hunk in a
    W-007 file is unavoidable (§7 R-9's falsifier), it is a single
    additive arm and the R-12 time-box of fork/unions/plan.md applies:
    OV-3 rebases onto trunk after UN-2 merges; if UN-2 is still open when
    OV-3's verification is green, whichever lands second rebases. The
    W-026 blocked_by edge is cleared at OV-3 discharge with this note in
    W-007's notes (§8.5). Break condition: a refactor of the export
    machinery landing first — then OV-3 rebases over it.
-   **D-OV-10 — `alias` of an overload set re-exports the whole set
    (paper open question 8's recommendation, :448-450); `export name` is
    untouched.** `alias G = F;` binds `G` to the `OverloadSetValue` inst
    (the alias machinery binds the looked-up inst; name_poisoning.carbon
    `alias N.F2 = F1` precedent), so `G(...)` resolves over the same
    members — pinned positive (§4.A `alias_of_set`), zero code. Break
    condition: none.

### §0.4 The split decision: three PR-sized workstreams, sequential

The bullet is one row, but the paper's staging (:380-389) is three
milestone deliverables with two directed dependencies and one external
sequencing constraint, so per R29(b) it is three PRs:

-   **OV-1 (W-024, "same-file `overload fn` sets end to end"):** lex
    keyword; parse modifier; check (modifier group, `OverloadSet` store,
    inst kinds and every mirror site, `TryMergeRedecl` branches, the
    resolution loop, the non-callee diagnostic, the D-OV-6 gates incl. the
    import and export TODO arms); sem_ir mangling; goldens (parse, check,
    lower); conformance (`overloading_native` SKIP→PASS + one new
    program); docs/design/functions.md section; ledger; gap-analysis
    PARTIAL. Size M. Touches lex/parse/check/sem_ir/lower-adjacent
    (lower/constant.cpp, lower/type.cpp requires-lists only) and
    cpp/generate_ast.cpp (one four-line TODO arm; NOT a W-007 file).
-   **OV-2 (W-025, "set import + generic members"):** real
    `TryResolveTypedInst` arms for the set type/value (the `ImportFunctionDecl`
    two-phase shape), `Function::overload_set_id` mirrored on import,
    `member_decl_ids` localized, the `ImportRefLoaded` arm of
    `TryMergeRedecl` (api set seen from the impl file: member definitions
    merge; a NEW member declared in an impl file or in an importing library
    diagnoses `OverloadSetFrozen` — p000998's "signatures defined together
    in the same library", paper :216-223), `extern overload fn` handling,
    generic members (non-diagnosing deduction + the loop's step (b)),
    goldens, two conformance programs (one multi-unit directory program),
    docs paragraphs. Size M. Touches check/import_ref.cpp, deduce.cpp,
    call.cpp, handle_function.cpp — none of the W-007 files.
-   **OV-3 (W-026, "export + documented divergence + docs completion"):**
    the generate_ast.cpp set arm (D-OV-9), two export conformance programs
    asserting both directions' resolution (one where they agree, one where
    they DIVERGE — Carbon first-match picks `i64`, C++ picks `int`), the
    interop README section, the design README placeholder retirement,
    gap-analysis DONE. Size S/M. Starts after UN-2 merges (D-OV-9).
-   **Dependencies and sequencing:** OV-2 needs OV-1's store, loop and
    gates; OV-3 needs OV-1's entity and mangling and is independent of
    OV-2 (an OV-3 program exports non-generic same-file sets only), but is
    sequenced last so that W-007's contention window (EH-B landed; UN-2 in
    flight after EH-B) has closed. R29(d) pipelining: OV-2's planner-level
    spec is complete here; its implementer starts when OV-1's hosted
    verification is green.
-   Rejected: one PR (mixes the import resolver and the deduction change
    into the first landing, and the scoreboard flip MISSING → PARTIAL is
    observable at OV-1 alone); two PRs with export folded into OV-2 (drags
    the C++-side arm through the W-007 window while UN-2 is open).

## §1 Design decisions

### §1.A OV-1 — same-file `overload fn` sets

1.  **Lex: one line** (D-OV-1). Mechanical fallout, all generated:
    `Lex::OverloadTokenIndex`, `TokenKind::Overload`, the
    `LexerTest.Keywords` sweep (lex/tokenized_buffer_test.cpp:717), the
    token_kind_test.cpp lowercase-spelling checks (:22-65; `overload`
    complies).
2.  **Parse: one line** (D-OV-1). Fallout, all generated: the
    `OverloadModifier` leaf node (typed_nodes.h:1327-1330; category
    `Modifier`, so it lands in `FunctionSignature::modifiers` :577),
    `TryHandleAsModifier` (handle_decl_scope_loop.cpp:271-275),
    `ResolveAmbiguousTokenAsDeclaration`'s next-token list (:240-244 — so
    `export overload fn` and `base overload fn` still parse `export`/`base`
    as modifiers), `HandleStatement`'s modifier-led `DeclAsRegular`
    dispatch (handle_statement.cpp:54-56 — an `overload fn` inside a
    function body parses as a declaration, D-OV-1's local-set pin). Parse
    coverage: parse/coverage_test.cpp:17-30 requires every node kind in
    some golden; §4.A `parse/testdata/function/overload_modifier.carbon`
    covers `OverloadModifier`. `parse/typed_nodes_test.cpp:93-109`
    (`ModifierOrder`) extracts four specific modifiers by type and does not
    enumerate the list — unchanged.
3.  **Check: the entity and its mirror surface** (D-OV-2). New
    sem_ir/overload_set.h/.cpp (`OverloadSetStore = ValueStore<OverloadSetId,
    OverloadSet, Tag<CheckIRId>>`, the explicit instantiation
    cpp_overload_set.cpp:10-11 shape); `OverloadSetId` in sem_ir/ids.h
    beside `CppOverloadSetId` (:291-296, `Label = "overload_set"`) and in
    the sem_ir/id_kind.h `TypeEnum` (:43 neighbor — this registration is
    what lets an inst carry the id as an operand; without it
    `IdKindFor<OverloadSetValue, 1>` in sem_ir/inst.cpp:85-89 fails to
    compile); `File::overload_sets_` + accessors (file.h:171-176, :365-366;
    file.cpp:44 constructor; the `CollectMemUsage` label :199 pattern) and
    `Context::overload_sets()` (context.h:636-638). Inst kinds
    `OverloadSetType` (`ir_name = "overload_set_type"`, `is_type =
    Always`, `constant_kind = WheneverPossible`, fields `{TypeId type_id;
    OverloadSetId overload_set_id; SpecificId specific_id;}`) and
    `OverloadSetValue` (`ir_name = "overload_set_value"`, `constant_kind =
    Always`, `{TypeId type_id; OverloadSetId overload_set_id;}`) in
    inst_kind.def (alphabetical — after `NamespaceType`'s neighborhood;
    the def is a sorted list) and typed_insts.h (the :575-597 text with
    `Cpp` dropped). `GetOverloadSetType(Context&, OverloadSetId,
    SpecificId)` in check/type.h/.cpp beside :50-53/:180-185. **Mirror
    sites, each a grep hit of `CppOverloadSet` today and each an arm the
    -Werror build or an exhaustive switch requires:** (a)
    sem_ir/function.h:373-405 — `struct CalleeOverloadSet {OverloadSetId
    overload_set_id; SpecificId enclosing_specific_id; InstId self_id;}`
    added to the `Callee` variant; (b) function.cpp:58-69 — `GetCallee`
    tests `TryGetAs<OverloadSetType>` right after the C++ test and
    returns it with `fn.self_id` (`resolved_specific_id` CHECKed empty, as
    :64-65); (c) member_access.cpp:63-81 — `CalleeOverloadSet` arm
    returning `overload.self_id`; (d) sem_ir/expr_info.cpp:89-95 —
    `CalleeOverloadSet` arm returning `ExprCategory::ReprInitializing`
    (the C++ arm's value; a resolved Carbon call is re-categorized by its
    committed `Call` inst, so the set-callee category is only consulted
    for the unresolved callee expression); (e) stringify.cpp:400-407 —
    `StringifyInst(InstId, OverloadSetType)` printing `<type of Pick>`
    through the same `QualifiedNameItem`; (f) type_completion.cpp:298-304
    and lower/type.cpp:862-872 — `OverloadSetType` in both requires-lists
    (empty value representation, empty LLVM struct); (g)
    sem_ir/type_iterator.cpp:131-142 — `case OverloadSetType::Kind:` in the
    concrete-types group; (h) lower/constant.cpp:303-307 —
    `EmitAsConstant(ConstantContext&, OverloadSetValue)` returning
    `GetLiteralAsValue()`; (i) inst_namer.h:57-61 — `OverloadSetId` in
    `ScopeIdTypeEnum` plus the `GetScopeFor` if-chain arm (:69-100 —
    `overload_sets().GetRawIndex(id)`), inst_namer.cpp:153-215 — a
    fallthrough `case ScopeIdTypeEnum::For<OverloadSetId>: offset +=
    sem_ir_->functions().size();` step keeping the sum consistent (the
    :169-177 pattern), `PushEntity(OverloadSetId, ScopeId, Scope&)`
    (:740-753 shape, suffix `.overload_set`, fingerprint from
    `fingerprinter_.GetOrCompute(sem_ir_, overload_set_id)`), and the two
    `AddEntityNameAndMaybePush` cases for the value (`.value`) and type
    (`.type`) insts (:1194-1201); (j) inst_fingerprinter.cpp:220 (the
    worklist variant gains `OverloadSetId`), :425-430 (`Add(OverloadSetId)`
    hashing name and parent scope), :696-698 (the `CARBON_KIND` case),
    :809-815 (`GetOrCompute(const File*, OverloadSetId)` + the header
    declaration); (k) import_ref.cpp:2254-2279 — `HandleUnsupportedOverloadSet`
    with the string "overload set import" and the two `TryResolveTypedInst`
    overloads, plus the two `CARBON_KIND` arms in the big switch beside
    :4589-4594 (its `default:` is `CARBON_FATAL("Missing case ...")`
    :4784-4790 — an unhandled kind is a crash, not a compile error, which
    is why the arms land in OV-1 with the TODO body); (l) eval: NONE —
    `TryEvalTypedInst` handles `Always`/`WheneverPossible` generically
    (eval.cpp:3123-3157) and `EvalConstantInst` overloads are declared for
    every kind by x-macro (eval_inst.h:189-191) with missing ones diagnosed
    at LINK (the comment :185-188), so no per-kind eval function is
    needed — the same reason `CppOverloadSetValue` has none (`grep
    CppOverloadSet eval_inst.cpp eval.cpp` is empty); (m) lower: NONE
    beyond (f)/(h) — `HandleInst` is declared for all kinds but defined
    only for non-constant ones (lower/function_context.h:419-425) and
    `LowerInst` skips constants (function_context.cpp:126-127); (n)
    formatter: NONE — entity ids format through the `ScopeIdTypeEnum`
    constraint (formatter.h:265, :311), so (i) is sufficient; predicted
    dump shape by the C++ precedent
    (check/testdata/interop/cpp/stdlib/string_view.carbon:82):
    `%Pick.overload_set.value: %Pick.overload_set.type =
    overload_set_value @Pick.overload_set [concrete]`.
4.  **Declaration: `BuildFunctionDecl` and `TryMergeRedecl`** (D-OV-3).
    `DiagnoseModifiers` (handle_function.cpp:81-110): the
    `LimitModifiersOnDecl` allowed set (:90-94) gains
    `KeywordModifierSet::Overload`; every other declaration kind's allowed
    set is unchanged, so `overload class C {}` diagnoses the existing
    `ModifierNotAllowedOnDeclaration` "`overload` not allowed on `class`
    declaration" (pinned §4.A). `TryMergeRedecl` (:190-268) takes the
    introducer's `modifier_set` (one extra parameter) and grows the
    D-OV-3 branches; the new-set case lives in `BuildFunctionDecl` after
    the function is added (:628-637): `if (is_overload &&
    !function_decl.function_id-was-merged)` → `set_id =
    context.overload_sets().Add({.name_id = name_context.name_id,
    .parent_scope_id = name_context.parent_scope_id, .member_decl_ids =
    {decl_id}})`; `functions().Get(function_id).overload_set_id = set_id`;
    `set_value_id = AddInstInNoBlock<SemIR::OverloadSetValue>(context,
    node_id, {.type_id = GetOverloadSetType(context, set_id,
    context.scope_stack().PeekSpecificId()), .overload_set_id = set_id})`
    (the cpp/import.cpp:2516-2520 shape; the inst is a constant so it
    needs no block, and `AddInstInNoBlock` keeps `LoadImportRef`-style
    "no new insts in the current block" invariants for later probes);
    `MaybeAddToNameLookup(context, name_context, introducer.modifier_set,
    parent_scope_id, set_value_id)` — the SET VALUE is the name-lookup
    result (and the `exports()` entry, decl_name_stack.cpp:163-168; the
    member `FunctionDecl`s are in the file's block regardless). The
    D-OV-6 gates (i)-(vi) run right after, keyed on `is_overload`. The
    interface-scope `BuildAssociatedEntity` path (:281-291) is unreachable
    for a set: `overload` is Decl-group-exclusive with `default`/`final`
    but an unmarked interface member could still precede a marked one —
    that is the "P is an `AssociatedEntity`" case of D-OV-3 (mismatch
    diagnostic, no set).
5.  **Resolution** (D-OV-4): `PerformCallToOverloadSet` in call.cpp (the
    `CalleeOverloadSet` arm of `PerformCall` :345-368); `GetExplicitArityRange`
    static beside it. `ResolveCalleeInCall` (:53-99) is unchanged — the
    committed member goes through it with its arity already verified.
6.  **Non-callee use** (D-OV-4 step 6): one `CARBON_DIAGNOSTIC(OverloadSetNotCallee,
    ...)` site in convert.cpp.
7.  **Mangling** (D-OV-5): mangler.cpp:210-214, one hunk; sem_ir/mangler.h
    needs no signature change (`MangleImpl` reads `sem_ir().overload_sets()`).
8.  **Diagnostics: exactly four new kinds, one site each** (kind.def
    entries: `OverloadMarkerMismatch`/`OverloadMarkerPrevious` after the
    `Redecl*` block :280-296; `OverloadNoMatch`/`OverloadCandidateRejected`
    in the "Function call checking" block :301-312;
    `OverloadSetNotCallee` beside `CallToNonCallable` :303):
    -   `OverloadMarkerMismatch` (Error): "`overload` must appear on every
        declaration of `{0}` or on none" (`SemIR::NameId`), with
        `OverloadMarkerPrevious` (Note): "previous declaration of `{0}`
        here" (`SemIR::NameId`). Site: handle_function.cpp `TryMergeRedecl`.
    -   `OverloadNoMatch` (Error): "no member of overload set `{0}` accepts
        this call" (`SemIR::NameId`), with `OverloadCandidateRejected`
        (Note): a `Diagnostics::IntAsSelect` over the recorded reason —
        0 "candidate takes a different number of arguments", 1 "candidate
        has a parameter its argument cannot implicitly convert to", 2
        "candidate has generic parameters that could not be deduced" (the
        `{0:=0:...|=1:...|=2:...}` select form of `CallArgCountMismatch`,
        call.cpp:66-72; reason 2 is emitted only from OV-2 but the select is
        written once).
        Site: call.cpp `PerformCallToOverloadSet`.
    -   `OverloadSetNotCallee` (Error): "overload set `{0}` can only be used
        as the callee of a call" (`SemIR::NameId`). Site: convert.cpp.
        The diagnostics coverage test (diagnostics/coverage_test.cpp:17-79: every
        kind in kind.def must fire in some testdata file or be listed as
        untested) is satisfied by §4.A: `fail_marker_mismatch` (kinds 1-2),
        `fail_no_match` (3-4), `fail_set_as_value` (5). `check_diagnostics.py`'s
        one-`CARBON_DIAGNOSTIC`-per-kind rule holds by construction.
        Everything else reuses landed kinds or `SemanticsTodo` (D-OV-6).
9.  **Lowering: zero code beyond the two requires-list entries.** The lower
    goldens pin distinct `define`s per member (D-OV-5).
10. **Docs, keyword list, grammars** (D-OV-8; §8.6).

### §1.B OV-2 — set import and generic members

1.  **Import resolution of the entity.** `HandleUnsupportedOverloadSet` is
    deleted; `TryResolveTypedInst(ImportRefResolver&, OverloadSetValue)`
    resolves the imported set in the two-phase shape of `FunctionDecl`
    (import_ref.cpp:2429-2534): phase 1 requests every member decl's local
    constant (`GetLocalConstantId` on each `member_decl_ids[i]` — each is a
    `FunctionDecl`, whose own resolution creates the local `Function` with
    `first_decl_id()` set, :2387-2427) and the parent scope
    (`GetLocalNameScopeId`); on `HasNewWork()` → `Retry()`; phase 2 adds the
    local `OverloadSet` with the localized member decl ids (in the imported
    order), sets `overload_set_id` on each local member `Function`
    (mirroring — `ImportFunctionDecl` :2399-2410 copies the modifiers; the
    set id cannot be copied there because the set may not exist yet, so the
    set's resolver writes it), and returns
    `ResolveResult::Deduplicated<OverloadSetValue>(resolver, {.type_id =
    <local OverloadSetType>, .overload_set_id = local_id})`; the type inst
    resolves through the same set id (`TryResolveTypedInst(OverloadSetType)`
    → `GetOverloadSetType` over the localized id and specific, the
    `FunctionType` :2412-2421 "don't evaluate" caveat applies: use
    `AddImportedConstant` directly). Members resolve lazily as today; the
    set's member list is complete at set resolution because every member
    decl is a required dependency (a set is never partially imported —
    p000998's frozen set).
2.  **Definitions in the impl file.** `TryMergeRedecl`'s `ImportRefLoaded`
    arm (:229-251) gains: if the import IR inst is an `OverloadSetValue`
    → the local constant (loaded by `LookupNameInExactScope`'s
    `LoadImportRef` :187) is the local `OverloadSetValue`; run the D-OV-3
    identity scan over the LOCAL set's members with `prev_import_ir_id =
    import_ir_inst.ir_id()` so `MergeFunctionRedecl` → `DiagnoseIfInvalidRedecl`
    takes its `ApiForImpl` branch (merge.cpp:121-140: a forward declaration
    in the impl is allowed, a redefinition diagnosed) and
    `ReplacePrevInstForMerge` (:171-181) is NOT called (the scope entry
    stays the set value — the member's `FunctionDecl` is reached through the
    set, never through the name). No identity match → `OverloadSetFrozen`
    (Error, new): "overload set `{0}` is closed; new members may only be
    declared in the API file of its library" (`SemIR::NameId`) with
    `OverloadSetDeclaredHere` (Note) "overload set declared here" at the
    imported set's first member — one site covering both the impl file of
    the same library (the paper's "`impl` files may only _define_ members,
    not add them", :222-223) and an importing library (p000998's
    same-library rule; `import_ir_id != ApiForImpl`): the same rule at two
    distances. Unmarked `fn F(...)` against an
    imported set → `OverloadMarkerMismatch` as in D-OV-3.
3.  **`extern overload fn`**: gate (iv) is lifted only to the extent the
    `extern` machinery needs: an `extern overload fn F(...)` in an
    importing library must name an EXISTING member (identity scan against
    the imported set; `DiagnoseIfInvalidRedecl`'s cross-library `extern`
    branches :142-168 then apply per member); a non-member →
    `OverloadSetFrozen`. If verification shows the `extern library`
    ownership paths (`RestrictExternModifierOnDecl` modifiers.cpp:187-224)
    interact badly, the gate stays and the residue "extern members of
    overload sets" is filed by title — recorded loudly, never silently.
4.  **Generic members.** `DeduceGenericCallArguments` gains a trailing
    `bool diagnose = true` parameter threaded into `DeductionContext`
    (deduce.cpp:619-647; `DeduceImplArguments` :649-684 is the non-diagnosing
    precedent). Gate (i) is deleted; the loop's step (b) runs the
    non-diagnosing deduction INSIDE the discard scope (deduction "has side
    effects in the semir by generating `Converted` instructions" :666-668,
    which is exactly what the scope discards), and on success carries the
    `SpecificId` into the probe's parameter-type reads
    (`GetTypeOfInstInSpecific(sem_ir, specific_id, pattern)`) and into the
    commit (`PerformCallToFunction` re-deduces diagnosing — a second
    deduction of the same arguments yields the same specific,
    `MakeSpecific` deduplicates). Rejected: caching the probe's specific
    into the commit (an API change to `PerformCallToFunction` for a
    deduplicated lookup). Declaration-order first-match over mixed
    generic/non-generic members is pure order (D-OV-4 step 5; open question
    2).
5.  **Sets in generic scopes stay gated** (gate (ii)); titled residue.
6.  **One new diagnostic kind pair in OV-2** (`OverloadSetFrozen` +
    `OverloadSetDeclaredHere`), one site in handle_function.cpp.

### §1.C OV-3 — export and documented divergence

1.  **C++ name lookup returns every member.** `MapInstIdToClangDeclOrType`
    (generate_ast.cpp:199-256) gains a `CARBON_KIND(SemIR::OverloadSetValue
    set)` arm that calls `GetOrExportFunctionToCpp(member_decl_id,
    function_id)` for each member in order and collects the non-null
    results; the variant return type widens to carry
    `llvm::SmallVector<clang::NamedDecl*, 4>` for this arm only (the
    single-decl cases keep their shape); `FindExternalVisibleDeclsByName`
    (:396-405) passes the list to `SetExternalVisibleDeclsForName` (it
    already takes a list, :399). The OV-1 TODO arm is deleted. A member
    that fails to export (nullptr from `ExportFunctionToCpp` — a
    `SemanticsTodo` already emitted by the existing per-function paths)
    is dropped from the list, and if the list is empty the arm returns
    nullptr as the single-function case does.
2.  **C++ resolves with C++ rules; the divergence is documented, not
    prevented** (F-009; paper :235-243, open question 3). No export-side
    coherence check. Each member's thunk symbol is its own mangled name
    (D-OV-5), so the divergence is only ever "which member or whether" —
    never a wrong-ABI call (paper :240-242).
3.  **Zero new diagnostics in OV-3.**
4.  **Docs:** interop README:210 section; design README:3878 placeholder
    retired; functions.md section gains the export paragraph (§8.6).

## §2 Implementation spec

### §2.A OV-1 (file by file)

1.  **toolchain/lex/token_kind.def:218-219** — `CARBON_KEYWORD_TOKEN(Overload,
    "overload")` between the `Or` wrapper and `Override` (§1.A.1; +1 line
    if UN-1's `Union` at :175 has landed).
2.  **toolchain/parse/node_kind.def:422-423** —
    `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER(Overload)` (§1.A.2).
3.  **toolchain/check/keyword_modifier_set.h:48-49, :149-152** — `X(Overload)`
    and `| Overload` in `Decl` (D-OV-1).
4.  **toolchain/sem_ir/overload_set.h (new), overload_set.cpp (new),
    BUILD:101/:136; ids.h:296; id_kind.h:43; file.h:171-176/:365-366;
    file.cpp:44/:199; inst_kind.def; typed_insts.h:597; function.h:182
    (`overload_set_id`) and :225-267 (conditional print), :373-405
    (`CalleeOverloadSet`); function.cpp:58-69; expr_info.cpp:89-95;
    stringify.cpp:400-407; type_iterator.cpp:131-142; inst_namer.h:57-61,
    :69-100; inst_namer.cpp:153-215, :740-753, :1194-1201;
    inst_fingerprinter.cpp:220, :425-430, :696-698, :809-815 (+ header
    decl); mangler.cpp:210-214** — §1.A.3, §1.A.7.
5.  **toolchain/check/context.h:636-638; type.h:50-53; type.cpp:180-185;
    type_completion.cpp:298-304; member_access.cpp:63-81; import_ref.cpp:2254-2279
    and :4589-4594; handle_function.cpp:81-110, :190-268, :628-671;
    call.cpp:345-368 (+ `PerformCallToOverloadSet`, `GetExplicitArityRange`);
    convert.cpp (the `OverloadSetNotCallee` entry check, §1.A.6);
    merge.h/.cpp:337-409 (the `ArrayRef` refactor of `CheckRedeclParams`
    and the exported explicit-after-`self` comparison, D-OV-3)** — §1.A.4-6.
6.  **toolchain/lower/constant.cpp:303-307; lower/type.cpp:862-872** —
    §1.A.3 (f)/(h).
7.  **toolchain/check/cpp/generate_ast.cpp:216-255** — the `OverloadSetValue`
    TODO arm ("overload set export"), four lines on the :210 precedent
    (D-OV-6 (viii)).
8.  **toolchain/diagnostics/kind.def** — five kinds (§1.A.8).
9.  **Docs and grammars** (§8.6): docs/design/functions.md (new section +
    TOC :11-42 entry), docs/design/pattern_matching.md:696 (dated note),
    docs/design/lexical_conventions/words.md:86-87 (`overload` between
    `or` and `override`), utils/vim/syntax/carbon.vim:37,
    utils/vscode/carbon.tmLanguage.json:417,
    utils/textmate/Syntaxes/carbon.tmLanguage:524,
    utils/textmate/Samples/keywords.carbon:35,
    utils/tree_sitter/queries/highlights.scm:121 (`; "overload"` COMMENTED,
    after `"or"` :120 — grammar.js has no such token, the UN-1 landed
    lesson).
10. **No BUILD changes beyond sem_ir/BUILD; no CI or workflow changes.**

### §2.B OV-2 (file by file)

1.  **toolchain/check/import_ref.cpp** — real `TryResolveTypedInst` arms
    (§1.B.1) replacing :2254-2279's TODO bodies; the switch arms stay.
2.  **toolchain/check/handle_function.cpp:229-251** — the `ImportRefLoaded`
    `OverloadSetValue` case (§1.B.2); the `extern` rule (§1.B.3); gates
    (i), (iv), (vii) deleted.
3.  **toolchain/check/deduce.h:14-21, deduce.cpp:619-647** — `diagnose`
    parameter (§1.B.4). **call.cpp** — step (b) of the loop.
4.  **toolchain/diagnostics/kind.def** — `OverloadSetFrozen`,
    `OverloadSetDeclaredHere`.
5.  **Docs:** functions.md paragraphs (§8.6).

### §2.C OV-3 (file by file)

1.  **toolchain/check/cpp/generate_ast.cpp:165-166, :199-256, :396-405** —
    §1.C.1; the OV-1 TODO arm deleted.
2.  **Docs:** docs/design/interoperability/README.md:210,
    docs/design/README.md:3878-3881, functions.md export paragraph.

## §3 Commit structure

**OV-1 (PR "OV-1: `overload fn` closed sets, same-file"), four commits:**

1.  lex + parse (keyword, modifier node kind) + the parse golden of §4.A
    (CHECK-free) + grammar files + words.md.
2.  sem_ir + check (store, inst kinds and every mirror site, modifier
    group, `TryMergeRedecl` branches, the loop, the non-callee check, the
    gates incl. the import/export TODO arms, mangling, kind.def).
3.  check + lower goldens of §4.A (AUTOUPDATE, empty CHECK lines, R15/R19)
    -   §5.A conformance (`overloading_native` rewritten, `overloading_methods`
        new) + gap-analysis row 57 PARTIAL + ledger.
4.  discharge: decision-log entry, functions.md section and
    pattern_matching.md note (§8.6), ORCHESTRATION stamp, residue items
    (ids allocated then, §8.5).

**OV-2 (PR "OV-2: overload-set import and generic members"), three
commits:** (1) import resolution + `TryMergeRedecl` import arm + frozen
diagnostic + `extern` rule; (2) non-diagnosing deduction + loop step (b) +
gate deletions + §4.B goldens (the OV-1 `fail_todo_impl_file`,
`fail_todo_generic_member`, `fail_todo_extern` pins deleted, R16(b)
citation: D-OV-6) + §5.B conformance + ledger; (3) discharge.

**OV-3 (PR "OV-3: overload-set export"), two commits (after UN-2 merges;
rebase first):** (1) generate_ast.cpp arm + §4.C goldens (OV-1
`fail_todo_export` deleted) + §5.C conformance + gap-analysis DONE +
ledger; (2) discharge: docs (interop README, design README), decision
log, W-007 note, ORCHESTRATION stamp.

## §4 Testdata matrix (R16: no hand-written goldens; autoupdate fills)

Every new file ships with `AUTOUPDATE` and no CHECK lines; every
prediction below is what the hosted autoupdate must show, hand-traced from
the code paths cited. Diagnostic kinds are spelled exactly as their
`CARBON_DIAGNOSTIC` names; message text is quoted from §1.A.8 or the cited
landed site. No testdata identifier is a reserved word (`CARBON_KEYWORD_TOKEN`
list, token_kind.def:157-245); `overload` appears only as the modifier or
as `r#overload`. Split-file rule (testing/file_test/README.md:74-83,
the UN-1 lesson): every erroring subfile carries the `fail_` prefix, and
positive lower subfiles never share a file with a failing one, because one
erroring subfile blanks a lower golden's IR. `EXTRA-ARGS` is file-wide
(:207-213), so the string-fingerprint variant is its own file.

### §4.A OV-1

-   **parse/testdata/function/overload_modifier.carbon** — `overload fn
    F(x: i32);`, `private overload fn G(b: bool) {}`, `class C { overload fn
    M(self, x: i32); }` and a function body containing `overload fn L(x:
    i32) {}`. Predicted tree: `OverloadModifier 'overload'` as a child of
    `FunctionDecl`/`FunctionDefinitionStart` after any `PrivateModifier`
    (the declaration.carbon:280-300 shape), including inside the function
    body (handle_statement.cpp:54-56). Also `fail_overload_after_fn`
    subfile: `fn overload F();` → the parser takes `overload` as the
    declaration name position → predicted the existing name-parse error of
    parse/testdata/function/declaration.carbon:52 (`fn foo bar;`'s
    diagnostic), a `FunctionDecl` with error; and `fail_ordering`: `overload
    private fn H();` parses (both are modifiers; the ORDER error is
    check-side).
-   **check/testdata/function/overload/basic.carbon** (`INCLUDE-FILE:
    toolchain/testing/testdata/min_prelude/full.carbon`, `//@dump-sem-ir`
    ranges on positives). Subfiles: `two_members` — `overload fn Describe(n:
    i32) -> i32 { return 1; } overload fn Describe(b: bool) -> i32 { return
    2; } fn Use() -> i32 { return Describe(7) + Describe(true); }`:
    predicted a single scope entry `.Describe = %Describe.overload_set.value`
    (NOT `%Describe.decl`), two `fn_decl` insts `%Describe.decl.<suffix>`
    named with disambiguating suffixes as same-named functions are today,
    the constant `%Describe.overload_set.value: %Describe.overload_set.type
    = overload_set_value @Describe.overload_set [concrete]`, and in `Use` a
    `%Describe.ref: %Describe.overload_set.type = name_ref Describe,
    file.%Describe.overload_set.value` followed for the FIRST call by a
    second name reference to member 0's `fn_decl` (the committed callee,
    D-OV-4 step 3) and `call %Describe.ref.<n>(%int_7...)`, and for the
    second call a reference to member 1 and `call ...(%true)`; NO
    `converted` line from the probe of member 0 against `true` appears
    before the second call (the discard scope; D-OV-4's falsifier);
    `first_match_order` — `overload fn Pick(x: i64) -> i32 { return 1; }
    overload fn Pick(x: i32) -> i32 { return 2; } fn Use(n: i32) -> i32 {
    return Pick(n); }` → predicted the committed callee is MEMBER 0 with an
    `i32 → i64` `ImplicitAs` conversion call in the argument (`%Int.as.ImplicitAs.impl.Convert...`
    over `IntFitsIn`, the int.carbon:62-68 impl), never member 1;
    `arity_dispatch` — `overload fn Sum(a: i32) -> i32; overload fn Sum(a:
    i32, b: i32) -> i32;` called both ways → member by count;
    `method_set` — `class Acc { var total: i32; overload fn Add(ref self,
    x: i32) { self.total = self.total + x; } overload fn Add(ref self,
    flag: bool) { if (flag) { self.total = self.total + 100; } } }` and a
    caller `a.Add(1); a.Add(true);` → predicted `%Acc.Add.bound: <bound
    method> = bound_method %a.ref, %Add.overload_set.value`-shaped binding
    of the SET (member_access.cpp:413-418 over the set value), then per
    call a `bound_method` over the committed member (the :202-209 re-wrap)
    and `call` with the `addr`-taken self; `alias_of_set` — `overload fn
    Twice(x: i32) -> i32; overload fn Twice(b: bool) -> i32; alias Double
    = Twice; fn Use() -> i32 { return Double(1) + Double(false); }` →
    resolves over both members (D-OV-10); `later_member_not_visible` —
    `overload fn F(x: i32) -> i32 { return 1; } fn G() -> i32 { return
    F(true); } overload fn F(b: bool) -> i32 { return 2; }` is a FAIL
    subfile (`fail_later_member_not_visible`): predicted `OverloadNoMatch`
    at `F(true)` with ONE `OverloadCandidateRejected` note (reason 1) —
    information accumulation (p000875; paper :123-126): file-scope bodies
    are checked eagerly in order, so the set had one member; `class_defers`
    — the same shape inside a class body with a method calling `F(true)`
    → ACCEPTED: class member bodies are deferred to the class's `}`
    (`ParsingInDeferredDefinitionScope`, parse/context.cpp:461-476 — the
    UN-1 lesson), so all members are visible; `forward_decl_and_def` —
    `overload fn H(x: i32) -> i32; overload fn H(b: bool) -> i32; overload
    fn H(x: i32) -> i32 { return x; } overload fn H(b: bool) -> i32 {
    return 0; }` → each definition merges into its member (one `fn_decl`
    pair per member as forward_decl goldens show, no diagnostic);
    `local_set` — `fn Outer() -> i32 { overload fn L(x: i32) -> i32 {
    return 1; } overload fn L(b: bool) -> i32 { return 2; } return L(true);
    }` → accepted (block-scope lookup binds the set value through
    `AddNameToLookup`, decl_name_stack.cpp:142-146); `raw_identifier` —
    `var r#overload: i32 = 1;` compiles; `single_member` — one `overload fn
    Solo(x: i32)` and a call → a one-member set resolves (the marker on a
    single declaration is legal: "any single declaration reveals the set
    exists", paper :420-421); `discard_probe_constants` — a call whose
    first member fails on an `ImplicitAs` lookup and whose second member
    matches: predicted the `constants` block may carry the failed lookup's
    specifics (as failed impl lookups do today) but the dumped function
    block has no `converted`/`call` for member 0 (the D-OV-4 falsifier).
-   **check/testdata/function/overload/fail_marker_mismatch.carbon** —
    `fail_unmarked_second`: `overload fn F(x: i32); fn F(b: bool);` →
    `OverloadMarkerMismatch` ("`overload` must appear on every declaration
    of `F` or on none") at the second declaration + `OverloadMarkerPrevious`
    at the first; the second is then a member (recovery), pinned by a call
    `F(true)` resolving; `fail_marked_second`: `fn F(x: i32); overload fn
    F(b: bool);` → the mismatch at the second + note at the first, NO
    `RedeclParam*` diagnostic (D-OV-3's `return`); `fail_plain_redecl_unchanged`:
    `fn G(x: i32); fn G(b: bool);` → today's `RedeclParamDiffersType`
    ("type `bool` of parameter 1 in redeclaration differs from previous
    parameter type `i32`") — the "keeps today's errors" pin (paper
    :216-219).
-   **check/testdata/function/overload/fail_member_redecl.carbon** —
    per-member p003763: `fail_name_differs`: `overload fn F(a: i32);
    overload fn F(b: i32) {}` → `RedeclParamDiffers` ("redeclaration differs
    at parameter 1") + `RedeclParamPrevious` — same TYPES means the same
    member (D-OV-3); `fail_return_type`: `overload fn F(x: i32) -> i32;
    overload fn F(x: i32) -> bool;` → `FunctionRedeclReturnTypeDiffers`
    ("function redeclaration differs because return type is `bool`") —
    no overloading on return type; `fail_redefinition`: two definitions of
    one member → `RedeclRedef` "redefinition of `fn F`" + `RedeclPrevDef`;
    `fail_redundant`: two identical forward declarations → `RedeclRedundant`.
-   **check/testdata/function/overload/fail_no_match.carbon** —
    `fail_no_candidate`: `overload fn F(x: i32); overload fn F(b: bool);
    fn Use() { F("text"); }` → `OverloadNoMatch` ("no member of overload
    set `F` accepts this call") + two `OverloadCandidateRejected` notes,
    both reason 1 ("has a parameter its argument cannot implicitly convert
    to"); `fail_arity`: `F(1, 2)` against the same set → two notes with
    reason 0; `fail_error_arg`: `F(undeclared)` → only `NameNotFound`, no
    `OverloadNoMatch` (D-OV-4 step 1).
-   **check/testdata/function/overload/fail_set_as_value.carbon** —
    `fail_let`: `overload fn F(x: i32); overload fn F(b: bool); let g:
    auto = F;` → `OverloadSetNotCallee` ("overload set `F` can only be used
    as the callee of a call"); `fail_discard`: `F;` as a statement → the
    same kind (D-OV-4 step 6); `fail_arg`: `G(F)` for `fn G(f: i32)` →
    the same kind, not `ConversionFailure`.
-   **check/testdata/function/overload/fail_modifiers.carbon** —
    `fail_on_class`: `overload class C {}` → `ModifierNotAllowedOnDeclaration`
    "`overload` not allowed on `class` declaration"; `fail_with_virtual`:
    `class B { virtual overload fn F(self); }` → `ModifierNotAllowedWith`
    "`overload` not allowed on declaration with `virtual`" +
    `ModifierPrevious` (D-OV-1's narrowing, pinned); `fail_order`: `overload
    private fn H();` → `ModifierMustAppearBefore` "`private` must appear
    before `overload`"; `fail_repeated`: `overload overload fn I();` →
    `ModifierRepeated`; `fail_on_interface_member`: `interface I { overload
    fn M(self); }` → NOT a modifier error (the function allowed set admits
    the marker) and NOT the D-OV-3 `AssociatedEntity` mismatch (a FIRST
    marked declaration has no previous inst); it would create a set inside
    an interface, which the paper excludes (:225-226), so `BuildFunctionDecl`
    gates it when `parent_scope_id` is an `InterfaceWithSelfDecl` scope
    (the :285-287 test): `SemanticsTodo` "`overload fn` in an interface" —
    D-OV-6 gate (ix), pinned here.
-   **check/testdata/function/overload/fail_todo_gates.carbon** — one
    subfile per D-OV-6 gate, each predicted `SemanticsTodo` with the quoted
    string: `fail_todo_generic_member` (`overload fn F[T:! type](x: T);`
    → "semantics TODO: `\`overload fn\` with generic parameters`"),
    `fail_todo_generic_scope` (`class Box(T:! type) { overload fn F(self);
    }`), `fail_todo_ref_param` (`overload fn F(ref x: i32);`),
    `fail_todo_extern` (`extern overload fn F(x: i32);` — plus the
    landed `ExternRequiresDeclInApiFile`? no: the file is an api file, so
    only the TODO), `fail_todo_entry_point` (`overload fn Run() -> i32 {
    return 0; }` in package `Main`), `fail_todo_access` (`overload fn F(x:
    i32); private overload fn F(b: bool);`), `fail_todo_self_only`
    (`class C { overload fn F(self, x: i32); overload fn F(ref self, x:
    i32); }` → "`overload fn` members distinguished only by `self`"),
    `fail_todo_interface` (gate (ix)).
-   **check/testdata/function/overload/fail_todo_impl_file.carbon** —
    `// --- api.carbon` (`library "[[@TEST_NAME]]";` declaring `overload fn
    F(x: i32) -> i32; overload fn F(b: bool) -> i32;`) and `// ---
    fail_impl.carbon` (`library "[[@TEST_NAME]]" impl;` defining `overload
    fn F(x: i32) -> i32 { return x; }`): predicted, in the impl subfile,
    `SemanticsTodo` "semantics TODO: `overload set import`" (emitted with
    no location, the `HandleUnsupportedCppOverloadSet` precedent) followed
    by `NameDeclDuplicate` "duplicate name `F` being declared in the same
    scope" + `NameDeclPrevious` (D-OV-3's import case). Deleted at OV-2.
-   **check/testdata/function/overload/fail_todo_export.carbon** —
    `import Cpp;` + `overload fn F(x: i32) -> i32 { return 1; } overload fn
    F(b: bool) -> i32 { return 2; }` + `inline Cpp ''' int Use() { return
    Carbon::F(true); } '''` and a Carbon call of `Cpp.Use()`: predicted the
    generate_ast.cpp arm's `SemanticsTodo` "semantics TODO: `overload set
    export`" followed by Clang's "no member named 'F' in namespace
    'Carbon'" (the :402 `SetNoExternalVisibleDeclsForName` outcome) — exact
    Clang text decided by the fill. Deleted at OV-3.
-   **lower/testdata/function/overload/basic.carbon** (full prelude) —
    positive twins of `two_members`, `first_match_order`, `arity_dispatch`,
    `method_set`, `alias_of_set`, `local_set`. Predicted IR: `define i32
    @_CDescribe:overload0.Main(i32 %n)` and `define i32
    @_CDescribe:overload1.Main(i1 %b)` — two distinct definitions; in
    `Use`, `call i32 @_CDescribe:overload0.Main(i32 7)` then `call i32
    @_CDescribe:overload1.Main(i1 true)`; `first_match_order`: `call i32
    @_CPick:overload0.Main(i64 %...)` preceded by a `sext i32 ... to i64`
    (the `int.convert` builtin of the widening impl) and NO call to
    `@_CPick:overload1.Main` from `Use` (its definition still exists);
    method members `@_CAdd:overload0.Acc.Main(ptr %self, i32 %x)`; the
    local set `@_CL:overload0:enclosed.Main`-shaped names (the ":enclosed"
    marker mangler.cpp:66-70 for a block-scope parent — exact ordering of
    the markers as the fill shows; the pin is TWO distinct `define`s).
-   **lower/testdata/function/overload/mangle_string.carbon** —
    `EXTRA-ARGS: --mangle-string-fingerprint` (the
    lower/testdata/packages/imported_package_mangle_string.carbon
    precedent) over `first_match_order`: predicted the same
    `:overload0`/`:overload1` markers (no fingerprint is involved, so the
    flag changes nothing for members — the pin is that the flag does NOT
    change the names, D-OV-5's "no hash" claim).
-   **Hand-traced predictions the reviewers check against the autoupdate:**
    (1) no pre-existing golden moves (§6.A); (2) no `converted`/`call` for
    a rejected member in any check dump; (3) every member has its own
    `define` with a `:overload<N>` marker and N equals declaration order;
    (4) `.Describe = %Describe.overload_set.value` is the only scope entry
    for an overloaded name.

### §4.B OV-2

-   **check/testdata/function/overload/import.carbon** — `// --- lib.carbon`
    declares `overload fn F(x: i32) -> i32; overload fn F(b: bool) -> i32;`
    with definitions; `// --- use.carbon` imports and calls both:
    predicted the imported `%F.overload_set.value` as an `import_ref` in
    the `imports` block, two imported `fn_decl`s, and the same committed-
    callee shapes as §4.A; `api_impl` pair (the `fail_todo_impl_file`
    shape, now positive): the impl subfile's definitions merge (one
    `fn_decl` each, `ApiForImpl` import) — no diagnostic; `fail_impl_adds_member`:
    an impl-file `overload fn F(s: str) -> i32 {...}` → `OverloadSetFrozen`
    ("overload set `F` is closed; new members may only be declared in the
    API file of its library") + `OverloadSetDeclaredHere`;
    `fail_cross_library_adds_member`: the same from an importing library;
    `fail_import_unmarked`: `fn F(x: i32) -> i32 {...}` in the impl file →
    `OverloadMarkerMismatch`; `extern_member` (positive): `extern overload
    fn F(x: i32) -> i32;` in an importing library naming an existing
    member → accepted; `fail_extern_non_member` → `OverloadSetFrozen`.
-   **check/testdata/function/overload/generic.carbon** — `overload fn
    Kind(x: i32) -> i32 { return 1; } overload fn Kind[T:! type](x: T) ->
    i32 { return 2; }`: `Kind(5)` → member 0 (IntLiteral → i32);
    `Kind(true)` → member 1 with a deduced specific (`specific_fn`,
    `T = bool`) — predicted the committed callee is a `SpecificFunction`
    over member 1's decl (the :193-199 shape); `generic_first`: the generic
    member declared FIRST swallows every call (pure order, open question
    2) — pinned: `Kind(5)` resolves to the generic member with `T =
    Core.IntLiteral`; `fail_deduce_all`: a set whose only members are
    generic with constraints no argument satisfies → `OverloadNoMatch` +
    notes with reason 2 ("has generic parameters that could not be
    deduced"); `fail_todo_generic_scope` stays (gate (ii)).
-   **lower/testdata/function/overload/generic.carbon** — the specific's
    mangled name carries both the marker and the specific fingerprint:
    `@_CKind:overload1.Main.<16 hex>` beside `@_CKind:overload0.Main`.
-   **lower/testdata/function/overload/import.carbon** — the cross-file
    call names `@_CF:overload1.Lib`-shaped symbols identical in the
    defining and using subfiles (D-OV-5's stability pin).
-   **Deleted:** `fail_todo_impl_file.carbon`, the `fail_todo_generic_member`
    and `fail_todo_extern` subfiles.

### §4.C OV-3

-   **check/testdata/interop/cpp/function/export/overload_set.carbon** —
    `import Cpp;` + `overload fn F(x: i64) -> i32 { return 1; } overload fn
    F(b: bool) -> i32 { return 2; }` + `inline Cpp ''' int CallBool() {
    return Carbon::F(true); } int CallWithInt() { return Carbon::F(7); } '''`
    plus Carbon calls of both: predicted a clean compile, the `imports` block
    showing both exported thunks (asm labels `_CF:overload0.Main`,
    `_CF:overload1.Main`), and Clang's resolution selecting `F(bool)` for
    `true` (exact) and `F(long)` for `7` (integral conversion `int → long`,
    the only viable candidate since `int → bool` is a boolean conversion,
    [over.ics.rank]/4: both are conversions of the same rank — this pin's
    fill decides; if Clang reports ambiguity the C++ test argument becomes
    `7L`, recorded); `divergence`: `overload fn Pick(x: i64) -> i32 {
    return 1; } overload fn Pick(x: i32) -> i32 { return 2; }` + `inline
    Cpp ''' int FromCpp(int v) { return Carbon::Pick(v); } '''` → C++
    selects `Pick(int)` (exact match, [over.ics.rank]) — member 1 — while
    Carbon's `Pick(n)` for `n: i32` selects member 0: pinned as two
    different callee symbols in the same golden; `fail_todo_...`: none.
-   **lower/testdata/interop/cpp/function/export/overload_set.carbon** —
    the two thunks and the direct calls.
-   **Deleted:** `fail_todo_export.carbon`.

## §5 Conformance

All under bullet "Functions: function overloading (Carbon-native)"
(fork/gap-analysis.md:57; R7: exact string; `runner.py --self-test` before
every commit that touches programs). **Counts are deltas:** OV-1 is PASS
+2, SKIP −1, total +1, bullets +1; OV-2 is PASS +2, total +2 (one of them
a multi-unit directory program, counted once); OV-3 is PASS +2, total +2.
Absolutes on the post-W-012 base (108/0/27 over 135, 44/56): OV-1 →
**110/0/26 over 136, 45/56**; OV-2 → **112/0/26 over 138**; OV-3 →
**114/0/26 over 140**. Rebase rule: add EH-B's and UN-1/UN-2's landed
deltas (fork/eh/plan.md §5.B: +4 PASS / −1 SKIP / +3 total expected;
fork/unions/plan.md §5: UN-1 +2 / −1 / +1, UN-2 +2 / 0 / +2) to both sides
of every equation; never hard-code. Harness conventions (fork/w077/plan.md
§5, fork/unions/plan.md §5): runtime inputs through `fn RuntimeSeed(x:
i32) -> i32 { return x + 20; }` so nothing constant-folds (R16(d)); EXPECT
values hand-derived below from the design's first-match rule and the
prelude's implicit conversions (§0.1 row 14); `Core.Print(x: i32)` only
(core/io.carbon:12; R1).

### §5.A OV-1 — one SKIP→PASS, one new; delta PASS +2 / SKIP −1 / total +1

1.  **functions/overloading_native.carbon — body REPLACED (SKIP → PASS).**
    Header keeps the bullet line verbatim; `EXPECT-EXIT: 0`; the SKIP line
    and the strawman are deleted (the un-SKIP discloses, per R6's F8d
    template, that the stub's `Describe(n: i32)`/`Describe(b: bool)`
    strawman is kept as the first pair with the accepted marker). Program:

    ```carbon
    import Core library "io";

    overload fn Describe(n: i32) -> i32 { return 1; }
    overload fn Describe(b: bool) -> i32 { return 2; }

    // Declaration order decides: `i32` widens implicitly to `i64`
    // (core/prelude/types/int.carbon:62-68), so the first member wins
    // for an `i32` argument even though the second is an exact match.
    overload fn Pick(x: i64) -> i32 { return 1; }
    overload fn Pick(x: i32) -> i32 { return 2; }

    overload fn Sum(a: i32) -> i32 { return a; }
    overload fn Sum(a: i32, b: i32) -> i32 { return a + b; }

    fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

    fn Run() -> i32 {
      Core.Print(Describe(RuntimeSeed(-13)));
      Core.Print(Describe(true));
      var n: i32 = RuntimeSeed(-19);
      Core.Print(Pick(n));
      Core.Print(Sum(RuntimeSeed(-17)));
      Core.Print(Sum(RuntimeSeed(-17), RuntimeSeed(-16)));
      return 0;
    }
    ```

    EXPECT-STDOUT, hand-derived: `1` (an `i32` argument: member 0
    converts exactly); `2` (`bool` has no implicit conversion to `i32`
    — §0.1 row 14 — so member 0 is rejected and member 1 matches); `1`
    (first match after `i32 → i64` widening; a best-match resolver would
    print 2 — this line IS the F-009 rule observed natively); `3`
    (arity 1); `7` (arity 2: 3 + 4). Five lines.
2.  **functions/overloading_methods.carbon (new).** A class with two
    overloaded method sets and a file-scope alias of a set:

    ```carbon
    import Core library "io";

    class Acc {
      var total: i32;
      fn Make() -> Acc { return {.total = 0}; }
      overload fn Add(ref self, x: i32) { self.total = self.total + x; }
      overload fn Add(ref self, flag: bool) {
        if (flag) { self.total = self.total + 100; }
      }
      overload fn Get(self) -> i32 { return self.total; }
      overload fn Get(self, scale: i32) -> i32 { return self.total * scale; }
    }

    overload fn Twice(x: i32) -> i32 { return x * 2; }
    overload fn Twice(b: bool) -> i32 { if (b) { return 2; } return 0; }
    alias Double = Twice;

    fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

    fn Run() -> i32 {
      var a: Acc = Acc.Make();
      a.Add(RuntimeSeed(-15));
      a.Add(true);
      Core.Print(a.Get());
      Core.Print(a.Get(RuntimeSeed(-18)));
      Core.Print(Double(RuntimeSeed(-17)));
      Core.Print(Double(false));
      return 0;
    }
    ```

    EXPECT-STDOUT: `105` (0 + 5 + 100), `210` (105 × 2), `6` (3 × 2),
    `0`. Four lines. Syntax per R3: `fn F(self)`/`fn G(ref self)` and
    `{.total = 0}` from check/testdata/class/method/method.carbon:5-9 and
    the class init goldens; `alias` of a function from
    name_poisoning.carbon and code_org/importing_core_library.carbon:24.

Zero landed programs move: no program in fork/conformance/programs uses
`overload` as an identifier (D-OV-1's grep), and OV-1 changes no
diagnostic a landed program triggers.

### §5.B OV-2 — two new programs (one multi-unit); delta PASS +2 / total +2

1.  **functions/overloading_generic.carbon (new)** — `overload fn Kind(x:
    i32) -> i32 { return 1; } overload fn Kind[T:! type](x: T) -> i32 {
    return 2; }` with `Core.Print(Kind(RuntimeSeed(-19)))` → `1` (member 0
    exact), `Core.Print(Kind(true))` → `2` (deduced `T = bool`),
    `Core.Print(Kind(RuntimeSeed(-19) as i64))` → `2` (no `i64 → i32`
    implicit conversion — `IntFitsIn` rejects narrowing — so member 0 is
    rejected and the generic member deduces `T = i64`). EXPECT-STDOUT: `1`,
    `2`, `2`.
2.  **functions/overloading_cross_library/ (new directory program,
    fork/conformance/README.md:117-140)** — `geometry.carbon` (`library
    "geometry";` api: `overload fn Dist(a: i32, b: i32) -> i32; overload fn
    Dist(a: i64, b: i64) -> i32;`), `geometry.impl.carbon` (`library
    "geometry" impl;` defining both members: `|a - b|` as i32; the i64
    member returns `(a - b) as i32` doubled to make the member observable),
    `main.carbon` importing `geometry` and printing `Dist(RuntimeSeed(-17),
    RuntimeSeed(-10))` → member 0 → `7`; `Dist(RuntimeSeed(-17) as i64,
    RuntimeSeed(-10) as i64)` → member 1 → `14`. EXPECT-STDOUT: `7`, `14`.
    Scoreboard path `functions/overloading_cross_library`.

### §5.C OV-3 — two new programs; delta PASS +2 / total +2

1.  **interop/cpp_export_overload_set.carbon (new)** — the agreeing
    direction: `import Cpp;` + the `Describe` set (`i32`/`bool`) + `inline
    Cpp ''' int FromCpp(bool b) { return Carbon::Describe(b); } int
    FromCppInt(int n) { return Carbon::Describe(n); } '''`; Carbon prints
    `Describe(RuntimeSeed(-13))` → `1`, `Describe(true)` → `2`,
    `Cpp.FromCpp(true)` → `2` (exact `bool`), `Cpp.FromCppInt(RuntimeSeed(-13))`
    → `1` (exact `int` ↔ `i32`). EXPECT-STDOUT: `1`, `2`, `2`, `1` — both
    directions agree, hand-derived from [over.match.best] exact-match
    ranking.
2.  **interop/cpp_export_overload_set_divergence.carbon (new)** — the
    documented divergence: the `Pick` set (`i64` first, `i32` second) +
    `inline Cpp ''' int FromCpp(int v) { return Carbon::Pick(v); } '''`;
    Carbon prints `Pick(n)` → `1` (first match) and `Cpp.FromCpp(n)` → `2`
    (C++ exact match `int`). EXPECT-STDOUT: `1`, `2`. The header comment
    states the divergence rule (F-009; functions.md section) and the
    rulebook rule the paper proposed ("every exported-overload conformance
    test asserts both directions' resolution", :242-243) is added to
    fork/rulebook.md as R30 at OV-3 discharge, citing this program as its
    origin.

The bullet's runner status flips SKIP → PASS at OV-1 (bullets +1);
`gap_status` follows the gap-analysis row (PARTIAL at OV-1 and OV-2, DONE
at OV-3). `runner.py --update-readme-table` refreshes the README table at
each discharge.

## §6 Churn inventory (verified by grep at c9708a0ea)

### §6.A OV-1

-   **Existing goldens that move: NONE predicted.** The keyword adds a
    token kind: no golden prints token-kind numbers (the UN-1 §6.A
    argument, verified the same way). The modifier adds a parse node kind:
    parse dumps print kind NAMES; `typed_nodes_test.cpp:93-109` extracts by
    type. The two inst kinds: raw dumps print kind names; `id_kind.h`'s
    `TypeEnum` order is internal. `Function::Print` prints
    `overload_set_id` only when set, and the set store is not in
    `OutputYaml` (D-OV-2) — the eight basics/raw_sem_ir goldens are
    byte-identical. `GetCallee`'s new test runs after the C++ test and
    before the `FunctionTypeWithSelfType` test, keyed on a type no existing
    input has. `TryMergeRedecl` is unchanged when the introducer lacks
    `overload` and the previous inst is not a set. The
    `CheckRedeclParams` `ArrayRef` refactor is behavior-preserving. The
    `Convert` entry check keys on `OverloadSetType` only. inst_namer's
    scope-offset chain gains a term that is zero for every existing file.
-   **Falsifier:** any pre-existing file in the autoupdate diff is a plan
    miss — stop and reconcile before gating (the R26 loc-number rule does
    not apply: no file gains lines above existing code).
-   Source files touched: 32 — (1) lex/token_kind.def; (2)
    parse/node_kind.def; (3) check/keyword_modifier_set.h; (4)
    sem_ir/overload_set.h (new); (5) sem_ir/overload_set.cpp (new); (6)
    sem_ir/BUILD; (7) sem_ir/ids.h; (8) sem_ir/id_kind.h; (9)
    sem_ir/file.h; (10) sem_ir/file.cpp; (11) sem_ir/inst_kind.def; (12)
    sem_ir/typed_insts.h; (13) sem_ir/function.h; (14) sem_ir/function.cpp;
    (15) sem_ir/expr_info.cpp; (16) sem_ir/stringify.cpp; (17)
    sem_ir/type_iterator.cpp; (18) sem_ir/inst_namer.h; (19)
    sem_ir/inst_namer.cpp; (20) sem_ir/inst_fingerprinter.h; (21)
    sem_ir/inst_fingerprinter.cpp; (22) sem_ir/mangler.cpp; (23)
    check/context.h; (24) check/type.h; (25) check/type.cpp; (26)
    check/type_completion.cpp; (27) check/member_access.cpp; (28)
    check/import_ref.cpp; (29) check/handle_function.cpp; (30)
    check/call.cpp; (31) check/convert.cpp; (32) check/merge.h/.cpp —
    plus lower/constant.cpp, lower/type.cpp, cpp/generate_ast.cpp,
    diagnostics/kind.def, docs/design/functions.md,
    docs/design/pattern_matching.md, words.md and the five grammar files.
    Contention with UN-1 (if it lands first): token_kind.def (UN-1 :175,
    OV-1 :218 — disjoint lines), node_kind.def (UN-1 after the `ClassDecl`
    kinds, OV-1 inside the modifier block — disjoint), kind.def (disjoint
    blocks), no shared .cpp file. Contention with EH-B: none (EH-B's files
    are cpp/{thunk,import,export,type_mapping}.cpp).

### §6.B OV-2

-   **Existing goldens that move: NONE predicted.** The `diagnose`
    parameter defaults to true; the import arms replace TODO bodies no
    landed golden reaches; the `ImportRefLoaded` arm keys on
    `OverloadSetValue`.
-   Source files touched: 6 — check/import_ref.cpp, check/handle_function.cpp,
    check/deduce.h, check/deduce.cpp, check/call.cpp, diagnostics/kind.def
    (+ functions.md).

### §6.C OV-3

-   **Existing goldens that move: NONE predicted.** The generate_ast.cpp arm
    keys on `OverloadSetValue`; the variant widening is internal.
-   Source files touched: 1 — check/cpp/generate_ast.cpp (+ two docs
    files, fork/rulebook.md). No W-007 file (D-OV-9).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — probe/commit divergence.** The probe converts each argument
    to the parameter pattern's TYPE as a value; the commit runs
    `CallerPatternMatch` through `ConvertCallArgs` (convert.cpp:2288-2301),
    which also applies parameter-pattern rules (`ref` tags, `var`
    parameters, `unused`). D-OV-6 (iii) confines 0.1 members to by-value
    explicit parameters so the two agree. Falsifier: any §4.A positive
    subfile showing a `ConversionFailure`/`RefParamNoRefTag` after a
    committed callee. Contingency: extend the probe with the pattern-kind
    check, never weaken the commit.
-   **R-2 — the discard scope leaks.** `PopAndDiscard` drops the scratch
    block, but a probe that MATERIALIZES a specific or an `ImportRef` load
    outside the block (constants, `imports`) is by design; a probe that
    adds an inst to the ENCLOSING block would be a leak. Falsifier: a
    `converted` or `call` line for a rejected member in a dumped function
    block (§4.A `discard_probe_constants`). Contingency: the
    `LoadImportRef` style CHECK on the enclosing block's size around the
    probe.
-   **R-3 — exhaustive switches and x-macro dispatch under -Werror (the
    baked lesson).** Every site in §1.A.3 is enumerated from a grep of
    `CppOverloadSet`; a missed `requires`-list entry fails at compile
    (lower/type.cpp `BuildTypeForInst`, type_completion.cpp
    `BuildInfoForInst`), a missed `EvalConstantInst` fails at LINK
    (eval_inst.h:185-188), a missed import_ref.cpp switch arm CRASHES at
    runtime (`CARBON_FATAL` :4784-4790), a missed inst_namer chain term
    misnumbers scopes silently. Falsifier: the hosted compile probe (R28(b)
    mode `compile`) — run it BEFORE the autoupdate, the F8/EH-B discipline.
-   **R-4 — mangling collision is silent in lowering.**
    `FileContext::GetOrCreateFunction`'s `getFunction(mangled_name)`
    early return (lower/file_context.cpp:394-416) reuses an existing LLVM
    function without checking it is the same Carbon function (the TODO at
    :407-414 says so). Falsifier: one `define` where §4.A predicts two, or
    a lower golden calling the wrong member. Contingency: none needed by
    construction (D-OV-5); if a lower fill shows it, stop.
-   **R-5 — the diagnostics coverage test (baked lesson).** Every new kind
    must fire in a golden: five kinds in OV-1 (§1.A.8), two in OV-2 —
    each has a named `fail_` subfile. Falsifier: `coverage_test` red on
    the gate. Also `OverloadCandidateRejected` reason 2 fires only at OV-2
    — the KIND fires at OV-1 with reasons 0/1, which is what the test
    checks.
-   **R-6 — `ParsingInDeferredDefinitionScope` (baked lesson).** No new
    parse state or scope loop is added, so the deferral lists
    (parse/context.cpp:461-476) need no change; class-body method members
    of a set are deferred exactly as today. Falsifier: `class_defers`
    diagnosing `OverloadNoMatch`.
-   **R-7 — lowering block-arg PHIs carry by-copy values only (baked
    lesson).** Not engaged: resolution is compile-time and the committed
    call is an ordinary `Call`; no convergence block is created.
    Falsifier: any `phi` in a §4.A lower golden that was not there for a
    plain call.
-   **R-8 — `CARBON_DECL_INTRODUCER_TOKEN` tables sized by
    `MaxDeclContextKind` (baked lesson).** Not engaged: `overload` is a
    `CARBON_KEYWORD_TOKEN`, not an introducer; the `DeclIntroducers` table
    (handle_decl_scope_loop.cpp:72-84) is untouched. Falsifier: parse golden
    showing `UnrecognizedDecl` at `overload fn`.
-   **R-9 — file_test split-file rule (baked lesson).** Positive lower
    subfiles never share a file with a `fail_` subfile (§4 preamble).
    Falsifier: a lower golden with blank IR for a positive subfile.
-   **R-10 — OV-3 needs a W-007 file after all.** `GetOrExportFunctionToCpp`
    dedups by `function.first_decl_id()` and `ExportFunctionToCpp` exports
    one function; both are per-member already. Falsifier: a
    `SemanticsTodo` or a Clang redeclaration error when two members export
    into one `DeclContext` — then the additive-hunk rule of D-OV-9.
-   **R-11 — C++ resolution of the exported set behaves unexpectedly (OV-3
    probes).** `Carbon::F(7)` against `F(long)`/`F(bool)` may be
    ambiguous under C++ rules; the plan pre-registers the fallback
    (`7L`). Falsifier: the fill; recorded, never papered over.
-   **R-12 — the `Convert` entry check fires on a path that legitimately
    consumes a set value.** Audited consumers of a name-lookup inst that
    are NOT calls: `alias` (binds the inst without converting — D-OV-10),
    member access on a class scope (`C.F` yields the set value without
    conversion; the call converts nothing), `BoundMethod` construction
    (no conversion). Falsifier: `alias_of_set` or `method_set` diagnosing
    `OverloadSetNotCallee`.
-   **R-13 — same-name member insts confuse the inst namer.** Two
    `fn_decl`s named `Describe` get disambiguating suffixes today
    (`%F.decl.loc12`-style names exist for redeclarations); the set's own
    scope is named `@Describe.overload_set` (inst_namer suffix). Falsifier:
    an autoupdate fill with duplicate `%` names (file_test would fail on
    ambiguity).
-   **R-14 — the `PeekSpecificId` gate misfires for a non-generic class
    nested in a generic function or similar.** Falsifier: `method_set`
    (a non-generic class at file scope) diagnosing the generic-scope TODO.
    Contingency: gate on the parent scope's entity `generic_id` instead
    (the handle_choice.cpp:645-646 predicate the union plan cites).
-   **Rejected alternatives (not risks):** unmarked sets (Option B,
    F-009 rejected); ranking/best-match (open question 2); the anchor
    `FunctionDecl` entity (D-OV-2); decl-fingerprint mangling (D-OV-5);
    an export-side coherence check (open question 3, undecidable); a
    seventh modifier order group (D-OV-1).

## §8 Verification and discharge

1.  **Regen (per PR):** `Fork: hosted verification` mode `compile` first
    (R-3), then `autoupdate` to fixpoint (R26/R28(d): the gate's file_test
    pass proves it); expected churn is NEW files only (§6). Any
    pre-existing golden in the diff is a stop.
2.  **Gate:** mode `gate` green (prek + `bazel test //toolchain/...`;
    clang-format 21.1.8 per R18; `uvx prek run --files <changed>` locally
    before every push, R25). The parse coverage test and the diagnostics
    coverage test are part of the gate.
3.  **Conformance:** mode `conformance`; deltas per §5 (OV-1 +2/−1/+1,
    OV-2 +2/0/+2, OV-3 +2/0/+2) on whatever base trunk has at rebase
    time; `runner.py --self-test` and `--update-readme-table` clean. Any
    other movement is a §5/§6 miss — stop and reconcile.
4.  **Reconciliation greps at discharge:** after OV-1, `grep -rn 'overload
    set import' toolchain` hits the two resolver arms and
    fail_todo_impl_file.carbon; `grep -rn 'overload set export' toolchain`
    hits the generate_ast.cpp arm and fail_todo_export.carbon; `grep -rn
    '`overload fn` with generic parameters\|`overload fn` in a generic
    scope\|non-value explicit parameter\|`extern overload fn`\|`overload`
    on the entry point\|members with differing access\|distinguished only
    by `self`\|`overload fn` in an interface' toolchain` hits one site each
    in handle_function.cpp plus fail_todo_gates.carbon; after OV-2 the
    import, generic-member and extern strings are gone; after OV-3 the
    export string is gone; each of the five OV-1 kinds and two OV-2 kinds
    has one kind.def line, one `CARBON_DIAGNOSTIC` and one emit site
    (`check_diagnostics.py`).
5.  **Ledger edits (fork/inventory/work-items.json):**
    -   W-024 → kind `implemented`, evidence = token_kind.def line, the
        parse/check/lower goldens, `overloading_native` +
        `overloading_methods`; notes record §0.2 items 1, 2, 6, 9 and
        D-OV-1..6, 8, 10 by name ("same-file in OV-1; api/impl at OV-2 with
        the import resolver").
    -   W-025 → kind `implemented`, blocked_by cleared, evidence = the
        §4.B goldens and §5.B programs; notes record §0.2 items 6, 10 and
        the `OverloadSetFrozen` rule.
    -   W-026 → kind `implemented`, blocked_by cleared (W-007 by D-OV-9),
        evidence = §4.C goldens and §5.C programs; notes record §0.2 items
        3, 7 and the divergence rule R30.
    -   W-007 → notes: "OV-3 landed additively in cpp/generate_ast.cpp
        after UN-2 by rebase; none of the three contention files changed;
        the refactor-first precondition was met by sequencing (EH-B, UN-2,
        OV-3)".
    -   W-013 → notes: "the overload resolution loop's arity check is a
        range (`GetExplicitArityRange`, call.cpp) per
        function-overloading.md:403-406".
    -   W-028 → notes: "the overload candidate probe (call.cpp
        `PerformCallToOverloadSet`) uses the `DeduceImplArguments` discard
        idiom (deduce.cpp:666-678) and `TryConvertToValueOfType`; a shared
        probe subsystem would replace both call sites".
    -   W-065 → notes: the interop README overload-resolution TODO and the
        design README placeholder closed at OV-3.
    -   **NEW residue items, referred to BY TITLE; ids allocated at
        discharge** by `grep -oE '"id": ?"W-[0-9]+"'
        fork/inventory/work-items.json | sort -t- -k2 -n | tail -1` on
        trunk at that moment (W-083..W-085 are being taken by EH-B and
        W-086..W-093 by UN-1 — never assume numbers): "overload sets in
        generic scopes" (D-OV-6 (ii); mechanism: `OverloadSetType.specific_id`
        substitution as `FunctionType.specific_id` is substituted, then the
        loop's `enclosing_specific_id`); "virtual members of overload sets"
        (D-OV-1; mechanism: a seventh modifier order group and
        signature-keyed vtable slots); "members of overload sets with
        non-value parameters" (D-OV-6 (iii); mechanism: a pattern-kind-aware
        probe, or a `diagnose` flag on `CallerPatternMatch`); "`self`-shape
        overloading" (D-OV-3; paper open question 4, upstream #3154);
        "overload sets in interfaces" (gate (ix)); "per-candidate failure
        notes at Clang granularity" (paper open question 7 — the 0.1 notes
        carry a three-way reason); and, only if §1.B.3's fallback fires,
        "extern members of overload sets". The pattern-dispatch future
        (Option C) stays in the doc, not the ledger.
6.  **Docs:** docs/design/functions.md — a new `## Function overloading`
    section between "Forward declarations" (:577-629) and "Function types
    and values" (:631), with a TOC entry (:32-34), marked "(fork amendment
    2026-09-27, F-009)", stating: the `overload` modifier on every member
    and the mismatch error; a set is closed to its library, `api`-file
    order is resolution order, `impl` files may only define members (OV-2
    landed note); member identity is parameter types (redeclaration
    matching per member; no overloading on return type); resolution is
    first match in declaration order over arity, deduction, then implicit
    conversions, with the `Pick(i64)/Pick(i32)` example and the sentence
    "a later member with an exact match is never considered once an
    earlier member accepts the arguments"; the no-match diagnostic lists
    candidates; a set is not a value in 0.1 (the p002875 `Call`-impls
    model is the future path); methods overload the same way with `self`
    as the first explicit parameter; `alias` re-exports the set; 0.1
    limits (D-OV-6 list) as a dated paragraph; and, at OV-3, "Exported
    sets are resolved by C++ under C++ rules; where the two rules disagree
    the divergence is documented and conformance-tested in both
    directions" with the divergence example. docs/design/pattern_matching.md:696
    gains a dated note ("F-009 (fork, 2026-09-27) fixed declaration order
    for overloaded functions; see functions.md#function-overloading").
    docs/design/README.md:3878-3881 (OV-3): the placeholder becomes a
    two-sentence summary pointing at the section (the "Error handling"
    entry :3884-3888 is the fork-note shape). docs/design/interoperability/README.md:210
    (OV-3): "Overload resolution" filled: import direction Clang-exact
    (:66-69 restated), export direction C++ rules, divergence rule, the
    two program names. **fork/gap-analysis.md:57** — OV-1: MISSING →
    **PARTIAL** with evidence "Carbon-native `overload fn` closed sets:
    marker keyword, `OverloadSet` SemIR entity, declaration-order
    first-match resolution with implicit conversions, per-member
    redeclaration matching, distinct mangling per member, method sets and
    aliases; same-file sets only — api/impl and cross-library import,
    generic members and export are TODO-gated (OV-2/OV-3); 2/2 conformance
    programs PASS"; header delta MISSING −1 / PARTIAL +1. OV-2: PARTIAL
    with the evidence rewritten ("+ set import across api/impl and
    libraries with the closed-set rule, generic members by non-diagnosing
    deduction; export TODO-gated; 4/4 PASS"); no header delta. OV-3: →
    **DONE** with evidence "OV-2 text + exported sets resolve under C++
    rules with the documented divergence conformance-tested both ways
    (6/6 PASS). Gated residue, each a filed item: overload sets in
    generic scopes and interfaces, virtual members, non-value parameters,
    `self`-shape overloading" (the row 44 DONE-with-gated-residue
    precedent fork/unions/plan.md §8.6 cites); header delta PARTIAL −1 /
    DONE +1. R7: bullet TEXT untouched.
7.  **Decision log:** entries "OV-1: `overload fn` closed sets (date)",
    "OV-2: overload-set import and generic members (date)", "OV-3:
    overload-set export (date)" carrying D-OV-1..10 with break
    conditions, the §0.2 corrections verbatim, the V-3a divergence-register
    line (the `overload` keyword, the `:overload<N>` mangling marker and
    the `OverloadSet*` inst kinds are fork spellings; upstream's
    `overloaded` placeholder is a rename away), the residue items by
    title with the ids allocated at that discharge, and the R29(a)
    auto-adoption note. fork/rulebook.md gains R30 at OV-3 (§5.C.2).
    fork/ORCHESTRATION.md header, branch table and scoreboard line stamped
    per PR.

## Hand-off notes for the implementer

-   Run the hosted `compile` probe after commit 2 and before writing a
    single golden: the mirror surface (§1.A.3) is where a missed arm
    bites, and three of its failure modes are not compile errors (R-3).
-   The keyword goes in the `CARBON_KEYWORD_TOKEN` block, NOT the
    introducer block; the modifier goes in the parse x-macro list, NOT a
    parse state. If you find yourself editing state.def or
    `DeclIntroducers`, stop — you are building UN-1, not OV-1.
-   Name lookup binds the SET VALUE inst, never a member's `FunctionDecl`;
    the members live only in `member_decl_ids` and the file's block. Do
    not add a member to lookup "for convenience" — D-OV-2's non-callee
    diagnostic depends on it.
-   Member identity is `CheckRedeclParamsMatch(..., diagnose=false,
    check_syntax=false)`; commit to the FIRST type-equal member and let
    `MergeFunctionRedecl` diagnose everything else. Never compare
    signatures by syntax for identity.
-   The probe is the `DeduceImplArguments` idiom verbatim (push block +
    push `GenericId::None` region; pop region, then `PopAndDiscard`) — in
    that order, on every exit path including "reason" early-outs.
-   Commit by RE-RUNNING `PerformCallToFunction` on a fresh `BuildNameRef`
    to the member; do not reuse any inst the probe produced.
-   Mangling is `:overload<index>` after the name; no fingerprint (§0.1
    row 9 is the reason — read the cross-library TODO golden before
    "improving" this).
-   Every gate is a `context.TODO` with the exact string of D-OV-6, and
    every gate has a `fail_todo_*` subfile; OV-2/OV-3 delete gate and pin
    in one commit.
-   `Function::Print` prints `overload_set_id` only when set; the store
    is not added to `OutputYaml`. The eight raw_sem_ir goldens must not
    move.
-   Every new AUTOUPDATE golden ships with empty CHECK lines (R15/R19);
    hand-derived EXPECT values only (R16(d)); `runner.py --self-test`
    before every conformance commit (R7); `uvx prek run --files` before
    every push (R25).

## Review fold record

None yet — rev 1. Every fold will be marked "(amended <date>, review fold:
...)" in place and listed here before Sign-off.

## Sign-off

Pending the two adversarial plan reviews (R29(c)).
