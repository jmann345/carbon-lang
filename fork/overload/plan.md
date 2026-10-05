<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Overloading plan: `overload fn` closed sets (OV-1 W-024, OV-2 W-025, OV-3 W-026)

**Status:** SIGNED OFF FOR IMPLEMENTATION (OV-1 first), rev 2b,
2026-09-27. The focused re-review of rev 2 returned
SIGN-OFF-WITH-AMENDMENTS (0 blockers, 2 majors M1-M2, 6 minors m1-m6),
folded as rev 2b and listed in the fold record. **Trunk has since moved
(amended 2026-09-27, review fold: rev 2b):** c0c57285f landed EH-B
(PR #42) and UN-1 (PR #43), so trunk's floor is **114 PASS / 0 FAIL / 25 SKIP

over 140**, 45/56 bullets, gap-analysis header 27 DONE / 21 PARTIAL / 7
MISSING / 1 DESIGN-ONLY, ledger max id W-093; this branch's checkout is
still c9708a0ea and rebases onto c0c57285f before OV-1's first commit
(the token_kind.def/node_kind.def/kind.def/generate_ast.cpp shifts of
§6.A apply). The two adversarial plan
reviews returned REJECT (rev A: blockers A1 cleanup leak and A2 `self`
misalignment in D-OV-4; majors A3-A7) and APPROVE-WITH-AMENDMENTS (rev B:
B1-B14, incl. the port of the stranded design page); every finding is
folded below, each marked "(amended 2026-09-27, review fold: rev A n /
rev B n)", and the coordinator's [R29(a)] rulings (A2/rev B F3 mixed
`self` gate, A3 literal pre-test, B1 port, B4 template gate, B5 lifting
the generic-scope gate in OV-2, B11 `export` exclusivity) are recorded
with break conditions. The fold record precedes Sign-off. Branch `claude/carbon-fork-0-1-overload` off trunk c9708a0ea
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
docs are STRANDED on `claude/carbon-fork-0-1-7mwfb7-design-docs` (tip
481e08c24; fork/ORCHESTRATION.md:311, gated on an unanswered veto digest),
and trunk's docs/design/functions.md has no overloading section (its
headings, :46-903, go from "Redeclaration matching" :607 to "Function
types and values" :631). **The stranded branch DOES carry a complete
page** — `git show 481e08c24:docs/design/functions_overloading.md` is 906
lines with thirteen OPEN sub-forks F-009a..m — plus a four-line link block
in functions.md (:879-882 there), rewrites of pattern_matching.md:696 and
:1063, an interop README "### Overload resolution" section and the
README.md:3878 text (amended 2026-09-27, review fold: rev B B1; rev 1
wrongly said no page existed). This workstream therefore PORTS that page
and those edits as dated amendments, closing each sub-fork in place with
the D-OV decision that resolves it (D-OV-8, §8.6), under R29(a).

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
| 16 | Docs | MISSING on trunk; COMPLETE on the stranded branch (amended 2026-09-27, review fold: rev B B1) | `git show 481e08c24:docs/design/functions_overloading.md` (906 lines: Overview :47, Declaring :103-291, Redeclaration rules :293-390, Overload resolution :392-535, Interaction with checked generics :537-597, C++ interoperability :599-726, Future work :728, Decisions D1-D5 :758-790, Open sub-forks F-009a..m :813-876) and the sibling edits (functions.md +4 at :879-882, pattern_matching.md :696 and :1063 hunks, interoperability/README.md `### Overload resolution`, README.md:3878 note); on trunk docs/design/functions.md has no section; docs/design/pattern_matching.md:696 still says "We do not yet have an approved design for overloaded functions"; docs/design/interoperability/README.md:210 is `### TODO: Overload resolution`; docs/design/README.md:3878-3881 is the "Pattern matching as function overload resolution" placeholder (the ledger says :3822 — §0.2 item 3); docs/design/pattern_matching.md:1063-1066 is a SECOND placeholder of the same title ("Need to flesh out specific details of how overload selection leverages the pattern matching machinery") that W-065's evidence (:712-714, now :714-716) does not list (amended 2026-09-27, review fold: rev B B7); docs/design/lexical_conventions/words.md keyword list (:47-104; `or` :86, `override` :87) lacks `overload`; grammars: utils/vim/syntax/carbon.vim:37 (`carbonClassMethodDeclarationMod private virtual abstract protected impl`), utils/vscode/carbon.tmLanguage.json:417 and utils/textmate/Syntaxes/carbon.tmLanguage:524 (the `auto|destructor|forall|friend|observe|override|require` alternation), utils/textmate/Samples/keywords.carbon:35, utils/tree_sitter/queries/highlights.scm:121 (`; "override"` COMMENTED — the UN-1 landed lesson: grammar.js lacks the token) |

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
11. **This plan's rev 1 header ("there is no ratified docs/design page ...
    authors the normative section itself")** was wrong about the stranded
    branch's contents (§0.1 row 16): the page exists and is ported, not
    re-authored (D-OV-8; amended 2026-09-27, review fold: rev B B1).
12. **W-065 evidence `pattern_matching.md:712-714`** names the `match`
    placeholder (now :714-716) and misses the second overload placeholder
    at :1063-1066; both overload placeholders (README.md:3878,
    pattern_matching.md:1063) are retired by the port (§8.6; amended
    2026-09-27, review fold: rev B B7).
13. **Rev 1's testdata spelled the implementation-file marker `library
    "x" impl;`**; the working spelling is `impl library "x";`
    (check/testdata/function/declaration/no_definition_in_impl_file.carbon:9,
    :16) — corrected throughout §4 (R3; amended 2026-09-27, self-caught
    while verifying rev B B13).
14. **The stranded page's "Linkage and mangling" (:713-726)** prescribes a
    signature fingerprint and says "Exported members are unaffected by
    Carbon-internal mangling" — the first is superseded by D-OV-5 (§0.1
    row 9), the second is false: export.cpp:893-899 attaches
    `AsmLabelAttr(MangleWithPlatform(...))` to every exported thunk, so an
    exported member's C++ symbol IS its Carbon mangled name. Both are
    corrected while porting (§8.6; amended 2026-09-27, review fold: rev B
    B1).

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
    handle_modifier.cpp:25-35) — no virtual overload sets, no `impl fn`
    members, no `default`/`final` members, no `export overload fn` and no
    interface-member overload sets in 0.1, each pinned (§4.A
    `fail_modifiers`: `fail_with_virtual`, `fail_with_impl`,
    `fail_with_export`; amended 2026-09-27, review fold: rev A A7 / rev B
    B11). **Declined recommendation, recorded (amended 2026-09-27, review
    fold: rev B B2, sub-fork F-009d):** the stranded page recommends YES
    for `overload` with `virtual`/`abstract`/`impl` ("overload resolution
    selects a member statically first, and virtual dispatch then applies",
    :280-286, :834-837) and consequently a NEW standalone modifier group
    (:148-162: "`overload` cannot join the existing `Decl` group"). This
    plan declines it for 0.1: `RequestVtableIfVirtual`
    (handle_function.cpp:491-528) and vtable construction key a virtual
    function by NAME within the class, so two virtual members of one name
    need signature-keyed vtable slots and override matching by signature
    — a vtable-layout change no 0.1 program needs — and the seventh order
    group (resizing `ordered_modifier_node_ids` decl_introducer_state.h:31-34,
    the exhaustive `ModifierOrderAsSet` switch modifiers.cpp:54-69 under
    -Werror, and `HandleModifier`'s if-chain :47-69) would land without a
    consumer. Sub-fork F-009m (modifier position, :119-124, :873-876) is
    MOOT under this choice: `overload` sits in the Decl slot, after
    access/`extern`/`extend` and exclusive with the other Decl modifiers, so
    no relative order among them arises. `export overload fn` is likewise
    exclusive in 0.1 [R29(a), rev B B11]: an exported set reaches importers
    through the ordinary name path once sets import (OV-2), and C++ through
    OV-3, so `export` on a member has no meaning to give. Residue "virtual
    members of overload sets" (§8.5) names the mechanism. Break condition:
    a design ruling that `virtual overload fn` is required — then the
    seventh group and signature-keyed vtable slots, never a silent
    relaxation of the exclusivity.
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
    method sets and `alias` of a set fall out. The set value inst is
    `AddInst`ed into the CURRENT block at the first member's declaration,
    right after the member's placeholder `FunctionDecl`
    (handle_function.cpp:598-602), so it has a location and a block like
    every declaration; rev 1's `AddInstInNoBlock` was wrong — the C++
    precedent adds its no-block inst to `context.imports()`
    (cpp/import.cpp:2516-2522), which a declaration has no business doing
    (amended 2026-09-27, review fold: rev A A4). Break condition: none —
    the mirror is the paper's own recommendation (:161, :369-370).
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
    -   A declaration whose parameters carry an already-diagnosed error
        never type-matches (`EntityHasParamError`, merge.cpp:185-200 makes
        `CheckRedeclParamsMatch` return false) and so silently becomes a NEW
        member; nothing further is diagnosed (the error was), and the
        member is unreachable only in the sense that its erroneous
        parameter rejects every probe (amended 2026-09-27, review fold: rev
        A minor, recorded as no-change).
    -   Members that disagree on whether they declare `self` at all
        (`F(self, x: i32)` vs `F(x: i32)` in one class body) are TODO-gated
        [R29(a): D-OV-6 gate (x); amended 2026-09-27, review fold: rev A A2
        / rev B B2 sub-fork F-009l, whose recommendation is "no in 0.1"].
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
        (a) Receiver alignment (amended 2026-09-27, review fold: rev A A2,
        corrected rev 2b M1): the ONLY illegal combination is a receiver
        bound to a member with no `self` pattern — `self_id.has_value() &&
        !F.self_param_id.has_value()` → reason 3 ("is not an instance
        method, but the call provides a receiver"), next member; it is the
        belt behind D-OV-6 gate (x) (under the gate every member of a set
        agrees on `self`, so it fires only if binding and members disagree)
        and it guards `CallerPatternMatch`'s CHECK that a `self_arg_id`
        has a `self_pattern_id` (pattern_match.cpp:2489-2494). The REVERSE
        combination — a method member reached without a bound receiver —
        is a LEGAL landed call shape: `Point.Get(p)` ≡ `p.Get()` and `alias
        A = Point.Get; A(p)` (check/testdata/class/method/call_without_method_syntax.carbon:25-31),
        where `CallerPatternMatch` zips `concat(self_arg_refs, arg_refs)`
        against ALL parameter patterns so argument 0 binds to the `self`
        pattern. Rev 2's reason 3 rejected that shape and is deleted.
        (b) Arity: `[min, max]` from `GetExplicitArityRange(function,
        self_id)` — a static returning `{n, n}` with `n =
        param_patterns.size() - (self_id.has_value() ? 1 : 0)`, that is
        call.cpp:61-64 VERBATIM, keyed on the CALL's `self_id` (rev 2 keyed
        it on `F.self_param_id`, the wrong variable — rev 2b M1), and a
        comment naming W-013 variadics as the reason the check is a range
        (paper :403-406); Carbon has no default arguments, so the
        range is exact (stranded sub-fork F-009j's recommendation, :450-457,
        adopted; amended 2026-09-27, review fold: rev B B2). Mismatch →
        reason 0, next member. (c) Template-dependent arguments (amended
        2026-09-27, review fold: rev B B4 [R29(a)]): if any argument's type
        constant has `constant_values().GetDependence(...) ==
        ConstantDependence::Template` (sem_ir/constant.h:19-31, :246-250),
        D-OV-6 gate (xi) fires ("overload resolution with
        template-dependent arguments") and the call returns `ErrorInst`;
        checked-generic (`Checked`) dependence is NOT gated — see step 7.
        (d) Generic member (OV-2 only; OV-1 never sees one, D-OV-6):
        non-diagnosing `DeduceGenericCallArguments(..., /*diagnose=*/false)`
        — the `diagnose` parameter does not exist today (deduce.h:14-21)
        and is added by §1.B.4 (amended 2026-09-27, review fold: rev 2b m6)
        — inside the discard scope of (e) — deduction converts runtime
        deduced arguments through `TryConvertToValueOfType`
        (deduce.cpp:572-576), so it gets the same cleanup wrap (amended
        2026-09-27, review fold: rev A A1); `None` → reason 2, next member.
        (e) Conversion probe inside the DISCARD SCOPE, which is the
        `DeduceImplArguments` idiom (deduce.cpp:666-678) EXTENDED with a
        cleanup snapshot (amended 2026-09-27, review fold: rev A A1, a
        BLOCKER): before the probe, `auto enclosing_size =
        context.inst_block_stack().PeekCurrentBlockContents().size(); auto
        cleanup_depth = context.scope_stack().cleanup_scope_depth();`
        (scope_stack.h:290-293), then `context.inst_block_stack().Push();
        context.generic_region_stack().Push({.generic_id =
        SemIR::GenericId::None});`; the probe zips
        `concat(self_refs, arg_ids)` against ALL of `F.param_patterns_id`
        exactly as `CallerPatternMatch` does (pattern_match.cpp:2489-2498):
        when a receiver is BOUND (`self_id.has_value()`), the `self` pattern
        gets no conversion (presence was checked in (a); `ref self`/`addr
        self` binding is the commit's job — a value conversion of the
        receiver would be the R-1 divergence); when a method member is
        reached WITHOUT a bound receiver (`!self_id && F.self_param_id`,
        the explicit-receiver shape of (a)), `arg_ids` is zipped against ALL
        patterns and argument 0 is probed against the `self` pattern: if
        the pattern's leaf is a by-value `self` (`ValueParamPattern`),
        `TryConvertToValueOfType` on argument 0; if it is `ref self`/`addr
        self` [R29(a); amended 2026-09-27, review fold: rev 2b M1], the
        cheaper 0.1 rule applies — D-OV-6 gate (xii) `context.TODO(loc_id,
        "explicit receiver for a `ref self`/`addr self` overload member")`
        and `ErrorInst`, pinned by §4.A `fail_todo_explicit_ref_receiver`,
        titled residue "explicit receiver for `ref self`/`addr self`
        overload members" (mechanism: a `ref`-tag/category probe on
        argument 0 mirroring `CallerPatternMatch`'s ref-param binding);
        and for each explicit pattern `TryConvertToValueOfType(context, loc_id, arg,
        GetTypeOfInstInSpecific(sem_ir, specific_id, param_pattern))` (the
        merge.cpp:280-282 type read; every 0.1 member's explicit parameters
        are by-value patterns, D-OV-6 (iii)); BEFORE that conversion, when
        the argument's constant is an `IntValue` of type `Core.IntLiteral`
        and the parameter type has `TryGetIntTypeInfo` (eval.cpp:1415), an
        `IntFitsIn`-style range pre-test applies the two checks of
        `PerformCheckedIntConvert` (eval.cpp:1425-1443: negative into
        unsigned; `getSignificantBits() - 1 + is_signed > width`) through a
        SHARED helper `static auto IntFitsInIntType(const llvm::APInt&
        value, bool is_signed, unsigned width) -> bool` extracted in
        eval.cpp and declared in eval.h, used by both
        `PerformCheckedIntConvert` and the probe so the two cannot drift
        (amended 2026-09-27, review fold: rev 2b m2), and rejects the
        member SILENTLY on failure [R29(a); amended 2026-09-27, review
        fold: rev A A3] — because constant evaluation of
        `int.convert_checked` emits `IntTooLargeForType` /
        `NegativeIntInUnsignedType` UNCONDITIONALLY and still returns a
        value, a bare probe would ACCEPT `F(300)` for an `i8` member and
        diagnose it twice; the first `ErrorInst::InstId` result → reason 1.
        On EVERY exit path (success, reasons 1/2, an early error) the scope
        is unwound in this order: `context.generic_region_stack().Pop();
        context.inst_block_stack().PopAndDiscard();
        context.scope_stack().DiscardCleanupsSince(cleanup_depth);`
        (scope_stack.h:277-288) — the third call is load-bearing: an
        initializing argument (`F(G())`, or `Describe(RuntimeSeed(-13))` in
        §5.A) converted to a value inside the probe goes through
        `MaterializeTemporary` → `AddInstWithCleanup<Temporary>` →
        `PushCleanupFor` (convert.cpp:79-102, control_flow.h:76-83,
        control_flow.cpp:142-148, scope_stack.h:255-259) onto
        `destroy_id_stack_`, which `PopAndDiscard` never touches, and the
        statement's `AddCleanups` would then emit a `Destroy` call in the
        ENCLOSING block over a `Temporary` that is in no block — a lowering
        `CARBON_CHECK` "Missing value" (lower/function_context.cpp:190-212).
        The cited `DeduceImplArguments` idiom never ran a runtime conversion
        (deduce.cpp:346-347), which is why it needed no such call. Then, as
        a RULE (R-2's contingency promoted): `CARBON_CHECK(
        context.inst_block_stack().PeekCurrentBlockContents().size() ==
        enclosing_size && context.scope_stack().cleanup_scope_depth() ==
        cleanup_depth)`. Constants and specifics minted by a failed probe
        (an `ImplicitAs` impl lookup, a `SpecificFunction`) stay in the
        constants store and DO print: the formatter's tentative scopes are
        `constants().array_ref()` and the `Imports` block
        (sem_ir/formatter.cpp:44-54), so a golden's `constants {}` block
        MAY carry them, in probe order — predicted, not forbidden (amended
        2026-09-27, review fold: rev 2b m1; rev 2 wrongly said they do not
        print). Two side effects of a rejected probe are PERSISTENT and not
        undone, recorded rather than papered over: (a) a `SpecificFunction`
        / `SpecificImplFunction` constant minted while probing a generic
        member pushes `definitions_required_by_use` (eval_inst.cpp:882,
        :901), so `ResolveSpecificDefinition` runs for it at the end of
        checking (check_unit.cpp:503-507) — an EXTRA specific `define` in
        the lower golden of a program whose rejected candidate was generic
        and, if that generic is undefined, a real
        `MissingGenericFunctionDefinition` (check_unit.cpp:508-510) — the
        OV-2 lower twin of `discard_probe_constants` predicts the extra
        `define`; (b) a successful impl lookup inside a later-rejected
        probe poisons the query (`PoisonImplLookupQuery`,
        impl_lookup.cpp:1136-1150, called at :1303), so a later impl that
        would change the answer is diagnosed — semantically RIGHT: the
        probe's answer participated in resolution. Pins: §4.A `init_arg`
        (check + lower twin) and `destroy_arg` — exactly ONE
        `temporary_storage`/`temporary`/`Destroy.Op` triple per call.
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
        reason (0-4) at `SemIR::LocId(member_decl_id)`; return
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
        untouched (V-3). Other non-call uses reach OTHER landed diagnostics
        first and are pinned as such rather than claimed for this kind
        (amended 2026-09-27, review fold: rev B B12): `&F` → `AddrOfNonRef`
        (handle_operator.cpp:269-285 tests the category before any
        conversion; a set value's category is `Value`); `F.member` → the
        member-access family (`QualifiedExprNameNotFound` /
        `QualifiedExprUnsupported`, member_access.cpp:671-683 — the fill
        decides which); `match (F) {...}` → the match scrutinee gate's
        `SemanticsTodo` if the scrutinee is gated before conversion, else
        `OverloadSetNotCallee`; `if (let x: auto = F) {...}` → the
        initializer conversion → `OverloadSetNotCallee`; `alias G = F;` is
        NOT a conversion (handle_alias.cpp:59-78 converts only initializing
        / mixed / dependent categories; a set value is `Value`), which is
        what keeps D-OV-10 zero-code.
    7.  Calls from CHECKED-GENERIC bodies resolve ONCE, at the definition,
        against the symbolic argument types (amended 2026-09-27, review
        fold: rev B B4; paper constraint 4 :117-121; stranded page :537-569
        "never deferred to instantiation"): the probe's
        `TryConvertToValueOfType` on a symbolic `T` succeeds exactly when
        `T`'s constraints guarantee the `ImplicitAs` impl (the constraint
        path of impl lookup) and fails otherwise — so a
        constraint-guaranteed member is selected once and every specific
        of the enclosing function calls that member (`call_from_generic_body`,
        predicted NO per-specific re-resolution: the committed `Call` is in
        the generic's definition region and specifics substitute it), while
        an unconstrained `T` yields `OverloadNoMatch` with reason 1
        (`fail_call_from_generic_no_match`). The stranded page's third case
        — a candidate whose match status depends on the specific — cannot
        arise from this probe: a symbolic conversion either resolves
        through a constraint or fails; there is no "maybe". Template
        dependence is gated (step 2(c)).
        Break condition: a member that the probe accepts and the commit rejects
        (R-1); the block-size/cleanup-depth CHECK firing (R-2, now a CHECK, not
        a contingency); a probe emitting any diagnostic OUTSIDE the
        residue's enumerated cases — a literal→float conversion
        (`IntTooLargeForFloatType` / `IntLossyConversionToFloat`,
        `FloatLiteralTooLargeForType`) or an abstract-class
        struct/tuple-literal initializer (`AbstractTypeInInit`) (R-15;
        amended 2026-09-27, review fold: rev A A3 / rev 2b m2) — the
        falsifier is a stray `converted`/`Destroy` line or an unexpected
        `error:` in a §4.A dump.
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
    "`overload fn` in a generic scope" — LIFTED IN OV-2 [R29(a); amended
    2026-09-27, review fold: rev B B5: overloaded methods of a generic
    class are the canonical migration shape] by the mechanism §1.B.5 names;
    if OV-2 finds it infeasible the gap row stays PARTIAL through OV-3 and
    the residue "overload sets in generic scopes" is filed; (iii) an explicit
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
    by D-OV-1; (x) a marked declaration whose `self` presence differs from
    the set's existing members (`F.self_param_id.has_value()` differs):
    "`overload fn` members that disagree on `self`" [R29(a); amended
    2026-09-27, review fold: rev A A2 / rev B B2 sub-fork F-009l] — the
    declaration still becomes a member (no cascade); (xi) a call to a set
    with a template-dependent argument (D-OV-4 step 2(c)): "overload
    resolution with template-dependent arguments" [R29(a); amended
    2026-09-27, review fold: rev B B4] — titled residue "overload
    resolution with template-dependent arguments" names the mechanism
    (resolve after substitution, the stranded page :587-597); (xii) an
    explicit receiver for a `ref self`/`addr self` member (D-OV-4 step
    2(e)): "explicit receiver for a `ref self`/`addr self` overload member"
    [R29(a); amended 2026-09-27, review fold: rev 2b M1]; (xiii) a marked
    declaration directly inside an `impl` body (`parent_scope_id`'s inst
    is an `ImplDecl`, the handle_function.cpp:199-200 test): "`overload
    fn` in an `impl` body" — an impl's functions must each match one
    associated function of the interface, and Carbon destructors are `impl
    as Core.Destroy` (there is no `fn destroy`: `grep -rn 'fn destroy'
    toolchain/check/testdata` is empty; the destroy machinery is
    custom_witness.cpp `HasUserDestroyImpl`), so the ported page's "not
    permitted on destructors" (:262-263) is subsumed by this gate (amended
    2026-09-27, review fold: rev 2b m3d). Every string is
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
-   **D-OV-8 — this workstream PORTS the stranded design page
    docs/design/functions_overloading.md (481e08c24, 906 lines) and its
    sibling edits by `git show` as dated amendments, closing each OPEN
    sub-fork F-009a..m in place with the D-OV decision that resolves it
    [R29(a): ADOPT PORT; amended 2026-09-27, review fold: rev B B1 — rev 1
    would have authored a parallel functions.md section].** Port
    schedule: OV-1 lands the page (whole, with a dated status paragraph
    saying which sections are toolchain-landed per slice: same-file sets at
    OV-1, import/generic at OV-2, export at OV-3), the functions.md link
    block (stranded :879-882), the pattern_matching.md :696 and :1063
    rewrites (both reference the page, which exists from OV-1), and
    words.md; OV-3 lands the interop README `### Overload resolution`
    section and the README.md:3878 note (their text describes export as
    landed). The other hunks in the stranded pattern_matching.md/README.md
    diffs are pre-W-012 content and are NOT ported. Two corrections while
    porting (§0.2 item 14): "Linkage and mangling" is rewritten to D-OV-5's
    `:overload<N>` index (superseding the signature fingerprint, with the
    §0.1 row 9 reason), and "Exported members are unaffected by
    Carbon-internal mangling" is replaced by the true statement that every
    exported member's C++ declaration carries its Carbon mangled name as an
    asm label (export.cpp:893-899). Every "OPEN (sub-fork F-009x)"
    paragraph becomes "CLOSED by D-OV-n (fork amendment 2026-09-27)" with
    the mapping (amended 2026-09-27, review fold: rev B B2): a single-member
    sets legal → D-OV-3 (pinned `single_member`); b same-file rule with
    impl files defining only → D-OV-7 + `OverloadSetFrozen`; c `self`-shape
    → D-OV-3's `self`-only gate; d `overload` with `virtual` → DECLINED, the
    stranded YES recorded with the vtable reason in D-OV-1; e interface
    members → gate (ix); f diagnostic depth → D-OV-4 step 4 (per-candidate
    notes); g naming outside a call → step 6; h alias whole-set and
    transitive through `export import` → D-OV-10 (rule added); i partially
    exportable sets → §1.C.1 (export the subset; the per-function
    `SemanticsTodo` on the omitted member is the note); j default
    arguments → none in 0.1, arity exact (step 2(b)); k type-identical,
    token-different → D-OV-3 (`fail_name_differs`); l mixed methods and
    non-methods → gate (x); m modifier position → moot (D-OV-1). One
    divergence from the page is named rather than papered over: the page
    says a call from another file "resolves against the visible members
    only" (:189-191, private members hidden), while gate (vi) requires
    uniform access across a 0.1 set, so visibility is all-or-nothing; the
    residue "per-member access in overload sets" (§8.5) carries the page's
    rule. fork/ORCHESTRATION.md:311's stranded-branch row gains
    "overloading portion ported by OV-1/OV-3; do not re-land" at OV-1
    discharge (§8.7). Break condition: the owner's veto digest answer
    changing a sub-fork ruling — then a doc-only amendment of the ported
    text, never a toolchain reopen without a new F-decision.
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
    `alias N.F2 = F1` precedent; handle_alias.cpp:59-78 does not convert a
    `Value`-category operand), so `G(...)` resolves over the same members
    — pinned positive (§4.A `alias_of_set`), zero code. **Transitivity
    (amended 2026-09-27, review fold: rev B B2 sub-fork F-009h; paper Q8
    :448-450):** a set re-exported through `export import` (or an `alias`
    in an api file) is re-exported like any other name — the importing
    library's scope entry is an `ImportRefUnloaded` to the set value, which
    OV-2's resolver localizes as a whole set — so the set stays closed and
    whole; pinned by the multi-unit golden §4.B `export_import_of_set`.
    `export overload fn` is excluded by D-OV-1. Break condition: an
    `export import` chain that drops or splits the set (a localized set
    with fewer members than the source, or a per-member scope entry) —
    the falsifier is `export_import_of_set` showing fewer `fn_decl`s than
    the source set or a `MemberNameNotFound` on a member.

### §0.4 The split decision: three PR-sized workstreams, sequential

The bullet is one row, but the paper's staging (:380-389) is three
milestone deliverables with two directed dependencies and one external
sequencing constraint, so per R29(b) it is three PRs. **Base at rebase
(amended 2026-09-27, review fold: rev 2b):** trunk c0c57285f (EH-B #42 and
UN-1 #43 landed; 114/0/25 over 140, 45/56) — EH-B is no longer in flight,
so the only remaining W-007-window sibling is UN-2 (D-OV-9), and UN-1's
line shifts in the four shared files are now concrete (§6.A).

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
    generic members (non-diagnosing deduction + the loop's step 2(d)),
    sets in generic scopes (gate (ii) lifted, §1.B.5; amended 2026-09-27,
    review fold: rev B B5), the api-member missing-definition check
    (§1.B.7), goldens, three conformance programs (one multi-unit
    directory program), the ported page's status paragraph. Size M.
    Touches check/import_ref.cpp, deduce.cpp, call.cpp,
    handle_function.cpp, check_unit.cpp, type.cpp, sem_ir/function.cpp —
    none of the W-007 files.
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
    `export overload fn` and `base overload fn` still PARSE `export`/`base`
    as modifiers; the check layer then rejects both combinations,
    `ModifierNotAllowedWith` for `export` under D-OV-1 and
    `ModifierNotAllowedOnDeclaration` for `base` on a function — parse
    accepts, check diagnoses; amended 2026-09-27, review fold: rev B B11), `HandleStatement`'s modifier-led `DeclAsRegular`
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
    returning `overload.self_id` ONLY IF some member `IsInstanceMethod`
    (:53-57; under gate (x) "some" equals "all"), else `nullopt`, so a set
    of non-methods reached through an object is NOT wrapped in a
    `BoundMethod` — unlike the C++ arm (:73-81), whose "treat every set as
    possibly-instance" posture relies on Clang sorting it out (amended
    2026-09-27, review fold: rev A A2); (d) sem_ir/expr_info.cpp:89-95 —
    `CalleeOverloadSet` arm returning `ExprCategory::ReprInitializing`
    (the C++ arm's value; a resolved Carbon call is re-categorized by its
    committed `Call` inst, so the set-callee category is only consulted
    for the unresolved callee expression); (e) stringify.cpp:400-407 —
    `StringifyInst(InstId, OverloadSetType)` printing `<type of Pick>`
    through the same `QualifiedNameItem`; (f) type_completion.cpp:298-304
    and lower/type.cpp:862-872 — `OverloadSetType` in both requires-lists
    (empty value representation, empty LLVM struct); (g)
    sem_ir/type_iterator.cpp:131-142 — `case OverloadSetType::Kind:` in the
    concrete-types group, whose `default:` is a RUNTIME `CARBON_FATAL`
    ("Unhandled type instruction", :304-307) that the compile probe cannot
    catch (amended 2026-09-27, review fold: rev A A5); (h) lower/constant.cpp:303-307 —
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
    `set_value_id = AddInst<SemIR::OverloadSetValue>(context,
    node_id, {.type_id = GetOverloadSetType(context, set_id,
    context.scope_stack().PeekSpecificId()), .overload_set_id = set_id})`
    — into the CURRENT block, immediately after the member's placeholder
    `FunctionDecl` (:598-602), so the set value sits in the file (or
    class) block with a location (amended 2026-09-27, review fold: rev A
    A4: rev 1's `AddInstInNoBlock` copied the C++ importer, whose no-block
    inst is pushed into `context.imports()`, cpp/import.cpp:2516-2522; a
    declaration has no such home);
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
8.  **Diagnostics: exactly five new kinds (three errors, two notes), one
    site each** (kind.def
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
        "candidate has generic parameters that could not be deduced", 3
        "candidate is not an instance method, but the call provides a
        receiver" (reason 3 amended 2026-09-27, review fold: rev A A2 /
        rev 2b M1 — rev 2's "instance method without a receiver" reason is
        DELETED: an explicit receiver through the class scope is a legal
        call shape, D-OV-4 step 2(a); the
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
    `ReplacePrevInstForMerge` (:171-181) is NOT called — today
    `MergeFunctionRedecl` calls it UNCONDITIONALLY whenever
    `prev_import_ir_id` has a value (handle_function.cpp:181-185), so OV-2
    threads an explicit `bool replace_prev_inst` parameter, true on the
    existing path and false for set members (the scope entry stays the set
    value — the member's `FunctionDecl` is reached through the set, never
    through the name; amended 2026-09-27, review fold: rev A A6). No identity match → `OverloadSetFrozen`
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
5.  **Sets in generic scopes are LIFTED** (gate (ii) deleted; [R29(a)],
    amended 2026-09-27, review fold: rev B B5). Mechanism, all on landed
    paths: `OverloadSetType.specific_id` is a `SpecificId` operand, and
    every `SpecificId` operand of an inst is substituted under the current
    specific by `GetConstantValue(EvalContext&, SemIR::SpecificId, Phase*)`
    (eval.cpp:702) inside `ReplaceAllFieldsWithConstantValues`
    (eval.cpp:3136-3138) — the same path that turns `FunctionType.specific_id`
    into the per-specific function type when `Box(i32).F` is named, since
    `GetOverloadSetType(context, set_id, PeekSpecificId())` records the
    enclosing self specific exactly as `GetFunctionType(...,
    PeekSpecificId())` does (handle_function.cpp:635-637). `GetCallee`'s
    set arm then carries `enclosing_specific_id =
    overload_set_type->specific_id` into `CalleeOverloadSet`; the loop
    reads each member's parameter types through it
    (`GetTypeOfInstInSpecific(sem_ir, enclosing_specific_id, pattern)`) and
    the commit passes it to `PerformCallToFunction` as
    `callee_function.enclosing_specific_id` (call.cpp:221-224 already
    threads it into `ResolveCalleeInCall`). Members of a generic class are
    "effectively non-generic within the specific" (`IsGenericFunction`,
    handle_function.cpp:466-488), so step 2(d) is not engaged for them.
    Pins: §4.B `generic_class_method_set` (check + lower: two `define`s
    per specific with the marker AND the specific fingerprint,
    `@_CAdd:overload0.Box.Main.<16 hex>`) and §5.B's third program. If
    hosted verification refutes the mechanism (a `specific_id` that does
    not substitute, or a CHECK in `GetCallee`), the gate stays, the residue
    "overload sets in generic scopes" is filed by title, the program is
    parked SKIP citing the diagnostic (R10), and the gap row stays PARTIAL
    through OV-3 — never DONE with that gate (B5's rule).
6.  **One new diagnostic kind pair in OV-2** (`OverloadSetFrozen` +
    `OverloadSetDeclaredHere`), one site in handle_function.cpp.
7.  **Marked-signature typo across api/impl (amended 2026-09-27, review
    fold: rev B B6).** F-009's stated reason for the marker is p003763's
    typo catching; inside a set, `overload fn G(x: i64) -> i64;` followed
    by the definition `overload fn G(x: u64) -> i64 {...}` legally declares
    a two-member set whose first member is never defined. Today an
    api-declared function without a definition is ACCEPTED at compile time
    and fails at LINK (no_definition_in_impl_file.carbon `decl_only_in_api`;
    `definitions_required_by_decl` is fed only for impl-file declarations,
    handle_function.cpp:669-671, and `CheckRequiredDefinitions`
    check_unit.cpp:459-476 checks only those). OV-1 pins today's behavior
    (`marked_typo_undefined_member`: a positive check golden with a comment
    naming the link-time failure) and the ported page's "0.1 limits"
    sentence says so. OV-2 extends the check to api-declared set members:
    in the impl file's `CheckRequiredDefinitions`, walk the `ApiForImpl`
    IR's `overload_sets()` and, for each member whose api `Function` has
    no `definition_id` and whose local merged `Function` (found through the
    localized set's `member_decl_ids`) has none either, emit
    `MissingDefinitionInImpl` at the member's imported decl (the
    `FunctionDecl` arm's shape, :469-475) — an overload-set-specific rule
    justified by the marker's contract (the general "any api decl without
    a definition" gap is #3762's and stays out of scope). If verification
    shows the api IR's functions are not reachable there (an
    `ImportRefUnloaded` never loaded), the residue "marked members without
    a definition" is filed by title with this mechanism. Pins: §4.B
    `fail_member_undefined_in_impl` (api declares two members, impl defines
    one → `MissingDefinitionInImpl` at the other's decl) and
    `impl_defines_all` (positive).
8.  **Re-export of a set through `export import` / api `alias`** is
    D-OV-10's transitivity rule; the resolver of §1.B.1 localizes the
    whole set wherever the `ImportRefUnloaded` came from, so nothing is
    set-specific — pinned by §4.B `export_import_of_set` (amended
    2026-09-27, review fold: rev B B2 sub-fork F-009h).

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
    nullptr as the single-function case does — the stranded sub-fork
    F-009i recommendation ("export the exportable members and omit the
    rest", :670-676), with the existing per-function `SemanticsTodo` on the
    omitted member serving as its note (amended 2026-09-27, review fold: rev
    B B2). Pinned by §4.C `partial_export` (one member with a parameter
    type that has no C++ mapping: predicted the TODO for that member, the
    other member callable from C++).
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
9.  **Docs and grammars** (§8.6; amended 2026-09-27, review fold: rev B
    B1): docs/design/functions_overloading.md (NEW, ported by `git show
    481e08c24:docs/design/functions_overloading.md` then edited per
    D-OV-8), docs/design/functions.md:879-882 (the ported four-line link
    block under "Functions in other features"),
    docs/design/pattern_matching.md:696 and :1063 (the ported hunks),
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
    `OverloadSetValue` case (§1.B.2) with the `replace_prev_inst` flag on
    `MergeFunctionRedecl` (:151-187); the `extern` rule (§1.B.3); gates
    (i), (ii), (iv), (vii) deleted. **toolchain/check/check_unit.cpp:459-476**
    — the api-member arm of `CheckRequiredDefinitions` (§1.B.7).
    **toolchain/check/type.cpp / sem_ir/function.cpp** — the enclosing
    specific through `CalleeOverloadSet` (§1.B.5).
3.  **toolchain/check/deduce.h:14-21, deduce.cpp:619-647** — `diagnose`
    parameter (§1.B.4). **call.cpp** — step (b) of the loop.
4.  **toolchain/diagnostics/kind.def** — `OverloadSetFrozen`,
    `OverloadSetDeclaredHere`.
5.  **Docs:** the ported page's status paragraph (import/generic landed)
    (§8.6).

### §2.C OV-3 (file by file)

1.  **toolchain/check/cpp/generate_ast.cpp:165-166, :199-256, :396-405** —
    §1.C.1; the OV-1 TODO arm deleted.
2.  **Docs:** docs/design/interoperability/README.md:210 and
    docs/design/README.md:3878-3881 (the ported hunks), the ported page's
    status paragraph (export landed).

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
4.  discharge: decision-log entry, the docs port (functions_overloading.md,
    functions.md link block, pattern_matching.md :696/:1063 hunks; §8.6),
    ORCHESTRATION stamp incl. the stranded-branch row note, residue items
    (ids allocated then, §8.5).

**OV-2 (PR "OV-2: overload-set import and generic members"), three
commits:** (1) import resolution + `TryMergeRedecl` import arm + frozen
diagnostic + `extern` rule + the api-member missing-definition arm; (2)
non-diagnosing deduction + loop step 2(d) + the generic-scope lifting +
gate deletions + §4.B goldens (the OV-1 `fail_todo_impl_file`,
`fail_todo_generic_member`, `fail_todo_generic_scope`, `fail_todo_extern`
pins deleted, R16(b) citation: D-OV-6) + §5.B conformance + ledger; (3)
discharge (incl. the ported page's status paragraph).

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
    and — in the `file {}` block, immediately after the FIRST member's
    `fn_decl` (A4: the set value is `AddInst`ed at that declaration) —
    `%Describe.overload_set.value: %Describe.overload_set.type =
    overload_set_value @Describe.overload_set [concrete]`, and in `Use` a
    `%Describe.ref: %Describe.overload_set.type = name_ref Describe,
    file.%Describe.overload_set.value [concrete =
    constants.%Describe.overload_set.value]` followed for the FIRST call by a
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
    block has no `converted`/`call` for member 0 (the D-OV-4 falsifier);
    `init_arg` (amended 2026-09-27, review fold: rev A A1) — `class C {
    var n: i32; } fn G() -> C { return {.n = 1}; } overload fn F(b: bool)
    -> i32 { return 1; } overload fn F(c: C) -> i32 { return c.n; } fn Use()
    -> i32 { return F(G()); }`: member 0 is probed against an INITIALIZING
    argument (`G()` returns a class by in-place initialization) and
    rejected; predicted EXACTLY ONE `temporary_storage` / `temporary` pair
    for the argument and, at statement end, exactly one `Destroy.Op`-style
    cleanup call over it (the commit's materialization), NEVER two — a
    second `temporary` or a `Destroy` over an inst that appears in no block
    is the A1 leak; `destroy_arg` — the same with `class D { var n: i32;
    fn destroy[addr self: Self*]() {} }` as the argument type (the
    class/destroy_calls.carbon spelling), predicted one user-`destroy`
    call per statement; `literal_range` (amended 2026-09-27, review fold:
    rev A A3) — `overload fn N(x: i8) -> i32 { return 1; } overload fn N(x:
    i32) -> i32 { return 2; } overload fn U(x: u8) -> i32 { return 1; }
    overload fn U(x: i32) -> i32 { return 2; }` with `N(300)` and `U(-1)`:
    predicted member 1 for both, with NO `IntTooLargeForType` /
    `NegativeIntInUnsignedType` diagnostic anywhere in the golden (a
    POSITIVE subfile; the pre-test rejects the `i8`/`u8` members
    silently); `class_scope_call` (amended 2026-09-27, review fold: rev A
    A2) — `class K { overload fn S(x: i32) -> i32 { return 1; } overload fn
    S(b: bool) -> i32 { return 2; } fn Use() -> i32 { return K.S(true) +
    S(1); } }` — a non-method set called through the class scope and
    unqualified: predicted no `bound_method`, members resolve by
    conversion; `explicit_receiver` (amended 2026-09-27, review fold: rev
    2b M1 — rev 2's `fail_static_member_via_instance` predicted an error
    for a LEGAL shape and is replaced by this POSITIVE subfile) — `class K
    { overload fn M(self, x: i32) -> i32 { return 1; } overload fn M(self,
    b: bool) -> i32 { return 2; } } alias A = K.M; fn Use(k: K) -> i32 {
    return K.M(k, 1) + A(k, true); }` — the method set named through the
    class scope and through an alias with the receiver passed explicitly
    (the call_without_method_syntax.carbon:25-31 shape): predicted member 0
    for `K.M(k, 1)` and member 1 for `A(k, true)`, argument 0 bound to
    the by-value `self` pattern, no `bound_method`, no diagnostic;
    `union_scope_set` (amended 2026-09-27, review fold: rev 2b m3d; UN-1
    landed in trunk c0c57285f) — `union U { var a: i32; var b: i64;
    overload fn Set(ref self, x: i32) { self.a = x; } overload fn Set(ref
    self, x: i64) { self.b = x; } }` with `u.Set(1); u.Set(1 as i64);`:
    predicted ACCEPTED (a union is a `SemIR::Class` with `is_union`, so the
    class-scope path is the union-scope path; the ported page's :259-260
    "under the same rules as classes"); `call_from_generic_body` (amended
    2026-09-27, review fold: rev B B4) — `overload fn P(x: i32) -> i32 { return 1; } overload fn
    P(b: bool) -> i32 { return 2; } fn Gen[T:! Core.ImplicitAs(i32)](x: T)
    -> i32 { return P(x); } fn Use() -> i32 { return Gen(7 as i16); }`:
    predicted member 0 committed ONCE inside `@Gen`'s definition (the
    `call` names member 0's decl with a symbolic `ImplicitAs` conversion
    of `%x`), and the `specific @Gen(...)` block shows the substituted
    conversion, not a re-resolution; `marked_typo_undefined_member`
    (amended 2026-09-27, review fold: rev B B6) — `overload fn G(x: i64)
    -> i64; overload fn G(x: u64) -> i64 { return 1; }` with a call
    `G(1 as u64)`: predicted ACCEPTED with two members and no diagnostic
    (today's api-decl behavior; the missing definition surfaces at link),
    with a comment naming §1.B.7's OV-2 rule.
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
    `OverloadNoMatch` (D-OV-4 step 1); `fail_call_from_generic_no_match`
    (amended 2026-09-27, review fold: rev B B4) — `fn Gen[T:! type](x: T)
    -> i32 { return F(x); }` against the `i32`/`bool` set → `OverloadNoMatch`
    at the definition with two reason-1 notes (an unconstrained `T` has no
    `ImplicitAs` impl to any parameter type).
-   **check/testdata/function/overload/fail_set_as_value.carbon** —
    `fail_let`: `overload fn F(x: i32); overload fn F(b: bool); let g:
    auto = F;` → `OverloadSetNotCallee` ("overload set `F` can only be used
    as the callee of a call"); `fail_discard`: `F;` as a statement → the
    same kind (D-OV-4 step 6); `fail_arg`: `G(F)` for `fn G(f: i32)` →
    the same kind, not `ConversionFailure`; `fail_if_let`: `if (let x: auto
    = F) {}` → `OverloadSetNotCallee` (the initializer converts);
    `fail_addr_of`: `&F` → the landed `AddrOfNonRef` ("cannot take the
    address of non-reference expression", handle_operator.cpp:279-282 —
    category test precedes conversion); `fail_member_of_set`: `F.x` → the
    landed member-access family (`QualifiedExprNameNotFound` /
    `QualifiedExprUnsupported`, member_access.cpp:671-683; the fill
    decides); `fail_match_scrutinee`: `match (F) { default => {} }` → the
    match scrutinee gate's `SemanticsTodo` or `OverloadSetNotCallee`
    (whichever the scrutinee path reaches first; pinned as the fill shows,
    both loud). `F(x)?` needs no pin — the call resolves before `?` sees a
    value (amended 2026-09-27, review fold: rev B B12).
-   **check/testdata/function/overload/fail_modifiers.carbon** —
    `fail_on_class`: `overload class C {}` → `ModifierNotAllowedOnDeclaration`
    "`overload` not allowed on `class` declaration"; `fail_with_virtual`:
    `class B { virtual overload fn F(self); }` → `ModifierNotAllowedWith`
    "`overload` not allowed on declaration with `virtual`" +
    `ModifierPrevious` (D-OV-1's narrowing, pinned); `fail_with_impl`:
    `class B2 { impl overload fn F(self); }` → `ModifierNotAllowedWith`
    "`overload` not allowed on declaration with `impl`" (amended
    2026-09-27, review fold: rev A A7); `fail_with_export`: `export
    overload fn E();` → `ModifierNotAllowedWith` "`overload` not allowed on
    declaration with `export`" (amended 2026-09-27, review fold: rev B
    B11); `fail_order`: `overload private fn H();` →
    `ModifierMustAppearBefore` "`private` must appear before `overload`";
    `fail_repeated`: `overload overload fn I();` → `ModifierRepeated`. Gate
    (ix) (`interface I { overload fn M(self); }` — not a modifier error,
    since the function allowed set admits the marker, and not the D-OV-3
    `AssociatedEntity` mismatch, since a first marked declaration has no
    previous inst; `BuildFunctionDecl` gates it when `parent_scope_id` is
    an `InterfaceWithSelfDecl` scope, the :285-287 test) is pinned ONCE, in
    fail_todo_gates.carbon `fail_todo_interface` (amended 2026-09-27,
    review fold: rev 2b m5 — rev 2 pinned it twice).
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
    `fail_todo_interface` (gate (ix)); `fail_todo_mixed_self` (gate (x);
    amended 2026-09-27, review fold: rev A A2 / rev B B2) — `class C {
    overload fn F(self, x: i32); overload fn F(b: bool); }` → "`overload
    fn` members that disagree on `self`" at the second; `fail_todo_template_dependent`
    (gate (xi); amended 2026-09-27, review fold: rev B B4) — `fn T2[template
    T:! type](x: T) -> i32 { return F(x); }` → "overload resolution with
    template-dependent arguments" at the call; `fail_todo_explicit_ref_receiver`
    (gate (xii); amended 2026-09-27, review fold: rev 2b M1) — `class R {
    var n: i32; overload fn Bump(ref self, x: i32) { self.n = self.n + x; }
    overload fn Bump(ref self, b: bool) {} } fn Use(r: R) { R.Bump(r, 1); }`
    → "explicit receiver for a `ref self`/`addr self` overload member" at
    the call (the same call through `r.Bump(1)` is the positive
    `method_set` shape); `fail_todo_impl_body` (gate (xiii);
    amended 2026-09-27, review fold: rev 2b m3d) — `interface I { fn
    Get(self) -> i32; } class D { extend impl as I { overload fn Get(self)
    -> i32 { return 1; } } }` → "`overload fn` in an `impl` body" (this is
    also where a marked `Core.Destroy` `Op` would land).
-   **check/testdata/function/overload/fail_todo_impl_file.carbon** —
    `// --- api.carbon` (`library "[[@TEST_NAME]]";` declaring `overload fn
    F(x: i32) -> i32; overload fn F(b: bool) -> i32;`) and `// ---
    fail_impl.impl.carbon` (`impl library "[[@TEST_NAME]]";` — the
    no_definition_in_impl_file.carbon:9 spelling — defining `overload fn
    F(x: i32) -> i32 { return x; }`): predicted, in the impl subfile,
    `SemanticsTodo` "semantics TODO: `overload set import`" (emitted with
    no location, the `HandleUnsupportedCppOverloadSet` precedent) followed
    by `NameDeclDuplicate` "duplicate name `F` being declared in the same
    scope" + `NameDeclPrevious` (D-OV-3's import case). Deleted at OV-2. A
    third subfile `impl_local.impl.carbon` (amended 2026-09-27, review
    fold: rev B B13) declares a set WHOLLY inside the impl file under a name
    the api does not declare (`overload fn L(x: i32) -> i32 {...} overload
    fn L(b: bool) -> i32 {...}` + a call): predicted ACCEPTED in OV-1 — no
    `ImportRef` is involved, so the same-file path runs (this positive
    subfile survives OV-2 as `impl_local_set`).
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
    `method_set`, `alias_of_set`, `local_set`, `init_arg`, `destroy_arg`,
    `literal_range`, `call_from_generic_body` (amended 2026-09-27, review
    fold: rev A A1 / A3, rev B B4). Predicted IR for `init_arg`: ONE
    `alloca` for the temporary, ONE call to `@_CG.Main` storing into it,
    ONE call to member 1 and ONE destroy sequence (for `destroy_arg`, one
    `call void @_Cdestroy.D.Main`) — a second alloca/destroy or a "Missing
    value" CHECK is the A1 leak; `call_from_generic_body`: the specific
    `@_CGen.Main.<16 hex>` calls `@_CP:overload0.Main` (never member 1).
    Predicted IR for the rest: `define i32
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
    member → accepted; `fail_extern_non_member` → `OverloadSetFrozen`;
    `fail_member_undefined_in_impl` and `impl_defines_all` (§1.B.7; amended
    2026-09-27, review fold: rev B B6): api declares two members, the impl
    subfile defines one → `MissingDefinitionInImpl` ("no definition found
    for declaration in impl file") at the undefined member's imported
    decl; defining both → clean. Every impl subfile uses the `impl library
    "[[@TEST_NAME]]";` spelling (§0.2 item 13).
-   **check/testdata/function/overload/export_import.carbon** (amended
    2026-09-27, review fold: rev B B2 sub-fork F-009h / D-OV-10) — `// ---
    base.carbon` declares and defines the set; `// --- reexport.carbon`
    does `export import library "base";`; `// --- use.carbon` imports
    `reexport` and calls both members: predicted the set arrives whole
    (one `import_ref` to the set value through the re-exporting library,
    two member `fn_decl`s), both calls resolve; the falsifier is fewer
    members or a `MemberNameNotFound` — D-OV-10's break condition.
-   **check/testdata/function/overload/generic_class_method_set.carbon**
    (amended 2026-09-27, review fold: rev B B5; shape corrected rev 2b M2
    — rev 2's `self.v + n` on a `T:! type` field needs `T as AddWith(i32)`
    at the definition and cannot type-check) — `class Box(T:! type) { var
    tag: T; var total: i32; fn Make(x: i32, t: T) -> Box(T) { return {.tag
    = t, .total = x}; } overload fn Add(ref self, n: i32) { self.total =
    self.total + n; } overload fn Add(ref self, b: bool) { if (b) {
    self.total = self.total + 100; } } fn Get(self) -> i32 { return
    self.total; } }` with `var b: Box(i64) = Box(i64).Make(1, 0 as i64);
    b.Add(1); b.Add(true);`: predicted `%Add.overload_set.value` inside `@Box`'s
    definition with an `OverloadSetType` whose `specific_id` is the self
    specific, the bound set naming `Box(i64)`'s substituted set value, and
    the two committed callees as `specific_fn`-shaped members of the
    `Box(i64)` specific; `fail_todo_generic_scope` is deleted in the same
    commit. If the fill shows a `SemanticsTodo` or CHECK instead, §1.B.5's
    fallback applies and this file is renamed `fail_todo_generic_scope`
    again with the diagnostic pinned (R16(b) citation: §1.B.5).
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
    deduced"); `fail_todo_generic_scope` is DELETED here (gate (ii) lifted,
    §1.B.5; amended 2026-09-27, review fold: rev B B5).
-   **lower/testdata/function/overload/generic.carbon** — the specific's
    mangled name carries both the marker and the specific fingerprint:
    `@_CKind:overload1.Main.<16 hex>` beside `@_CKind:overload0.Main`; a
    `discard_probe_constants` twin (amended 2026-09-27, review fold: rev 2b
    m1) — a generic member declared FIRST and rejected by deduction for a
    call that the second, non-generic member accepts: predicted an EXTRA
    `define` for the rejected candidate's specific (its `SpecificFunction`
    constant was minted in the probe and `ResolveSpecificDefinition` ran
    at check end, D-OV-4 step 2(e)(a)) alongside the call to member 1 — a
    predicted, not forbidden, artifact.
-   **lower/testdata/function/overload/import.carbon** — the cross-file
    call names `@_CF:overload1.Lib`-shaped symbols identical in the
    defining and using subfiles (D-OV-5's stability pin).
-   **lower/testdata/function/overload/generic_class.carbon** — the
    `Box(i64)` members as `@_CAdd:overload0.Box.Main.<16 hex>` and
    `@_CAdd:overload1.Box.Main.<16 hex>` (marker THEN specific
    fingerprint, mangler.cpp:249-258 order) — two `define`s per specific.
-   **Deleted:** `fail_todo_impl_file.carbon` (its `impl_local` subfile
    survives as `impl_local_set`), the `fail_todo_generic_member`,
    `fail_todo_generic_scope` and `fail_todo_extern` subfiles.

### §4.C OV-3

-   **check/testdata/interop/cpp/function/export/overload_set.carbon** —
    `import Cpp;` + `overload fn F(x: i64) -> i32 { return 1; } overload fn
    F(b: bool) -> i32 { return 2; }` + `inline Cpp ''' int CallBool() {
    return Carbon::F(true); } int CallWithInt() { return Carbon::F(7); } '''`
    plus Carbon calls of both: predicted a clean compile, the `imports` block
    showing both exported thunks (asm labels `_CF:overload0.Main`,
    `_CF:overload1.Main`), and Clang's resolution selecting `F(bool)` for
    `true` (exact) and `F(long)` for `7L` (exact) — the positive subfile
    passes `7L`, because `Carbon::F(7)` with an `int` argument is
    AMBIGUOUS under C++ rules: `int → long` (integral conversion) and `int
    → bool` (boolean conversion) are both Conversion rank, and
    [over.ics.rank]/4.1 demotes only pointer/member-pointer → `bool`
    (amended 2026-09-27, review fold: rev B B9; rev 1 predicted `F(long)`
    would win — wrong); `fail_cpp_ambiguous` pins that: `int CallWithPlainInt() {
    return Carbon::F(7); }` → Clang "call to 'F' is ambiguous" (exact text
    from the fill) — the "whether" half of the documented divergence
    (paper :237-240: "Carbon picks the first candidate; C++ rejects the
    call as ambiguous"); `partial_export` (amended 2026-09-27, review fold:
    rev B B2 sub-fork F-009i) — a set whose second member takes a parameter
    of a type with no C++ mapping (a Carbon `choice`, the landed
    per-function `SemanticsTodo` "failed to map Carbon type to C++",
    export.cpp:875-878): predicted that TODO for the second member and a
    clean C++ call of the first; `divergence`: `overload fn Pick(x: i64) -> i32 {
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
+2, SKIP −1, total +1, bullets +1; OV-2 is PASS +3, total +3 (one of them
a multi-unit directory program, counted once; the third is the
generic-class program of §1.B.5, which parks as SKIP +1 / PASS +2 if the
lifting is refuted — amended 2026-09-27, review fold: rev B B5); OV-3 is
PASS +2, total +2. Absolutes on the post-UN-1 base trunk c0c57285f
(114/0/25 over 140, 45/56; amended 2026-09-27, review fold: rev 2b): OV-1
→ **116/0/24 over 141, 46/56**; OV-2 → **119/0/24 over 144**; OV-3 →
**121/0/24 over 146**. (On the superseded post-W-012 base 108/0/27 over
135 these were 110/0/26 over 136, 113/0/26 over 139, 115/0/26 over 141.) Rebase rule: add EH-B's and UN-1/UN-2's landed
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

### §5.B OV-2 — three new programs (one multi-unit); delta PASS +3 / total +3

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
    Dist(a: i64, b: i64) -> i32;`), `geometry.impl.carbon` (`impl library
    "geometry";` defining both members with the absolute difference in
    BOTH, the `i64` member doubled to make it observable — amended
    2026-09-27, review fold: rev B B10, rev 1's `(a - b)` gave −14):
    member 0 `if (a < b) { return b - a; } return a - b;`, member 1 `if (a
    < b) { return ((b - a) * 2) as i32; } return ((a - b) * 2) as i32;`),
    `main.carbon` importing `geometry` and printing `Dist(RuntimeSeed(-17),
    RuntimeSeed(-10))` → member 0, |3 − 10| → `7`; `Dist(RuntimeSeed(-17) as
    i64, RuntimeSeed(-10) as i64)` → member 1, 2 × |3 − 10| → `14`.
    EXPECT-STDOUT: `7`, `14`. Scoreboard path
    `functions/overloading_cross_library`.
3.  **functions/overloading_generic_class.carbon (new; amended 2026-09-27,
    review fold: rev B B5; shape corrected rev 2b M2 — rev 2's `self.v +
    n` over `T:! type` could not type-check)** — `class Box(T:! type) {
    var tag: T; var total: i32; fn Make(x: i32, t: T) -> Box(T) { return
    {.tag = t, .total = x}; } overload fn Add(ref self, n: i32) {
    self.total = self.total + n; } overload fn Add(ref self, b: bool) { if
    (b) { self.total = self.total + 100; } } fn Get(self) -> i32 { return
    self.total; } }` (the generic parameter types only the inert `tag`
    field, so every member body type-checks at the definition): `var b:
    Box(i32) = Box(i32).Make(RuntimeSeed(-15), 0); b.Add(RuntimeSeed(-18));
    b.Add(true); Core.Print(b.Get());` → 5 + 2 + 100 → `107`; a second
    `Box(i32).Make(RuntimeSeed(-15), 0)` with `Add(false)` → `5`.
    EXPECT-STDOUT: `107`, `5`. If
    §1.B.5's lifting is refuted, this program lands SKIP citing the exact
    gate diagnostic (R10) and the deltas are PASS +2 / SKIP +1 / total +3.

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
    fork/rulebook.md at OV-3 discharge under the next free number
    (allocate at discharge, never assume R30 — amended 2026-09-27, review
    fold: rev B B14), citing this program as its origin. Neither §5.C
    program has a `.diff.cpp` sibling, deliberately: a divergence test
    cannot use an equality oracle, and the agreeing program's C++ side is
    already the oracle for its own two lines (amended 2026-09-27, review
    fold: rev B B9).

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
    UN-1 HAS landed (trunk c0c57285f, PR #43; amended 2026-09-27, review
    fold: rev 2b): its token_kind.def `Union` line sits above OV-1's
    `Overload` line (OV-1 inserts at the shifted `Or`/`Override` pair),
    its four `Union*` node kinds sit outside the modifier block, its
    kind.def block is disjoint, and no .cpp file is shared — the rebase is
    mechanical; the implementer re-reads those four files' line numbers
    first. EH-B HAS landed (PR #42); none of its files
    (cpp/{thunk,import,export,type_mapping}.cpp) is touched by OV-1. Contention with UN-2
    (amended 2026-09-27, review fold: rev B B8): UN-2 edits
    cpp/generate_ast.cpp at :452-457 (`CompleteType`'s `FinalAttr`,
    fork/unions/plan.md §1.B.2/§2.B.4) while OV-1's TODO arm is at
    :216-255 — disjoint hunks in one file, rebase-mechanical.

### §6.B OV-2

-   **Existing goldens that move: NONE predicted.** The `diagnose`
    parameter defaults to true; the import arms replace TODO bodies no
    landed golden reaches; the `ImportRefLoaded` arm keys on
    `OverloadSetValue`.
-   Source files touched: 9 — check/import_ref.cpp, check/handle_function.cpp,
    check/deduce.h, check/deduce.cpp, check/call.cpp, check/check_unit.cpp,
    check/type.cpp, sem_ir/function.cpp, diagnostics/kind.def (+ the
    ported page's status paragraph; amended 2026-09-27, review fold: rev B
    B5/B6).

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
    explicit parameters so the two agree; the receiver is never
    value-converted in the probe and its presence is checked in step 2(a)
    (amended 2026-09-27, review fold: rev A A2). Falsifier: any §4.A
    positive subfile showing a `ConversionFailure`/`RefParamNoRefTag`
    after a committed callee, or a CHECK in `CallerPatternMatch`
    (pattern_match.cpp:2494) on `explicit_receiver` / `method_set`, or
    `explicit_receiver` diagnosing at all (rev 2b M1: the explicit receiver
    is a legal shape). Contingency: extend the probe with the pattern-kind
    check, never weaken the commit.
-   **R-2 — the discard scope leaks (rev A's A1 BLOCKER; amended
    2026-09-27, review fold: rev A A1).** `PopAndDiscard` drops the scratch
    block but not the CLEANUP stack: a value conversion of an initializing
    argument materializes a `Temporary` and registers its cleanup on
    `destroy_id_stack_` (convert.cpp:79-102, control_flow.cpp:142-148,
    scope_stack.h:255-259), which the statement's `AddCleanups` later emits
    into the ENCLOSING block as a `Destroy` over an inst that is in no
    block — lowering's "Missing value" CHECK
    (lower/function_context.cpp:210-212). D-OV-4 step 2(e) therefore
    snapshots `cleanup_scope_depth()` and calls `DiscardCleanupsSince` on
    every exit, and CHECKs both the enclosing block size and the cleanup
    depth after each probe — rev 1's "contingency" is the rule. Probes that
    MATERIALIZE a specific or an `ImportRef` load outside the block
    (constants, `imports`) remain by design and PRINT in the `constants`
    block (rev 2b m1); two persistent side effects are named in D-OV-4
    step 2(e): a rejected generic candidate's specific still gets its
    definition resolved (`definitions_required_by_use`, an extra `define`
    or a real `MissingGenericFunctionDefinition`), and a probe's impl
    lookup poisons its query (impl_lookup.cpp:1136-1150) — both predicted,
    neither undone. Falsifier: `init_arg` /
    `destroy_arg` (check + lower) showing two temporaries, two destroy
    calls, a `Destroy` over an unlisted inst, or the CHECK firing; a
    `converted`/`call` line for a rejected member in a dumped function
    block (`discard_probe_constants`). Contingency: none silent — a CHECK
    here is a stop.
-   **R-3 — exhaustive switches and x-macro dispatch under -Werror (the
    baked lesson).** Every site in §1.A.3 is enumerated from a grep of
    `CppOverloadSet`; a missed `requires`-list entry fails at compile
    (lower/type.cpp `BuildTypeForInst`, type_completion.cpp
    `BuildInfoForInst`), a missed `EvalConstantInst` fails at LINK
    (eval_inst.h:185-188), a missed import_ref.cpp switch arm CRASHES at
    runtime (`CARBON_FATAL` :4784-4790), a missed sem_ir/type_iterator.cpp
    arm CRASHES at runtime too (its `default:` is `CARBON_FATAL("Unhandled
    type instruction")`, :304-307 — amended 2026-09-27, review fold: rev A
    A5), a missed inst_namer chain term misnumbers scopes silently.
    Falsifier: the hosted compile probe (R28(b) mode `compile`) for the
    compile-time class — run it BEFORE the autoupdate, the F8/EH-B
    discipline — and basic.carbon's fill for the two runtime fatals (a
    stack dump in the autoupdate log, which the hosted workflow greps for
    since EH-A).
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
    subfiles never share a file with a `fail_` subfile (§4 preamble;
    the rule is testing/file_test/README.md:74-83 at the repository root
    — amended 2026-09-27, review fold: rev A minor / rev B B14).
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
-   **R-15 — probes are not diagnostic-free (rev A A3; amended
    2026-09-27, review fold: rev A A3).** Constant evaluation inside a
    `TryConvertToValueOfType` can emit unconditionally: `int.convert_checked`
    diagnoses `IntTooLargeForType` / `NegativeIntInUnsignedType` and still
    returns a value (eval.cpp:1425-1445), so without the pre-test of step
    2(e) `N(300)` would SELECT the `i8` member and diagnose twice. The
    pre-test (through the shared `IntFitsInIntType` helper, rev 2b m2)
    covers the IntLiteral → Int case only. Still reachable from a literal
    argument, each returning `ErrorInst` (member correctly rejected) but
    EMITTING (amended 2026-09-27, review fold: rev 2b m2): IntLiteral →
    `Float(To)` through `int.convert_float_checked`
    (core/prelude/types/float.carbon:175-178; `IntTooLargeForFloatType` /
    `IntLossyConversionToFloat`, eval.cpp:1578-1596 — for example `F(16777217)`
    against an `f32` member declared first), FloatLiteral → `Float(N)`
    through `float.convert_checked` (`FloatLiteralTooLargeForType`,
    eval.cpp:1516-1522 — `F(1.0e39)` against an `f32` member), and a
    struct/tuple literal against an abstract-class parameter
    (`AbstractTypeInInit`, convert.cpp:898-903). Recorded as the residue
    "unconditional constant-evaluation diagnostics inside overload probes:
    literal→float and abstract-init" (§8.5) [R29(a)]; the D-OV-4 break
    condition excludes exactly these cases. Falsifier: `literal_range`
    showing any diagnostic, or selecting member 0; any OTHER probe
    diagnostic in a §4 dump.
-   **R-16 — the generic-scope lifting of OV-2 (rev B B5) does not fall
    out.** `OverloadSetType.specific_id` must substitute like
    `FunctionType.specific_id` (eval.cpp:702 through :3136-3138). Falsifier:
    `generic_class_method_set` showing a `SemanticsTodo`/CHECK, or a
    committed member whose specific is the generic's self specific rather
    than `Box(i64)`'s. Contingency: §1.B.5's fallback (gate stays, residue
    filed, program parked SKIP, row PARTIAL through OV-3).
-   **R-17 — the api-member missing-definition arm (rev B B6) cannot see
    the api IR's functions from `CheckRequiredDefinitions`.** Falsifier:
    `fail_member_undefined_in_impl` compiling clean. Contingency: the
    residue "marked members without a definition" by title, with the
    mechanism named in §1.B.7.
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
    OV-2 +3/0/+3 — or +2/+1/+3 if §1.B.5 is refuted — OV-3 +2/0/+2; amended
    2026-09-27, review fold: rev 2b m4) on whatever base trunk has at
    rebase time (c0c57285f today: 116/0/24 over 141, then 119/0/24 over
    144, then 121/0/24 over 146); `runner.py --self-test` and `--update-readme-table` clean. Any
    other movement is a §5/§6 miss — stop and reconcile.
4.  **Reconciliation greps at discharge:** after OV-1, `grep -rn 'overload
    set import' toolchain` hits the two resolver arms and
    fail_todo_impl_file.carbon; `grep -rn 'overload set export' toolchain`
    hits the generate_ast.cpp arm and fail_todo_export.carbon; `grep -rn
    '`overload fn` with generic parameters\|`overload fn` in a generic
    scope\|non-value explicit parameter\|`extern overload fn`\|`overload`
    on the entry point\|members with differing access\|distinguished only
    by `self`\|`overload fn` in an interface\|members that disagree on
    `self`' toolchain` hits one site each in handle_function.cpp plus
    fail_todo_gates.carbon (gate (ix)'s string in exactly ONE golden, rev
    2b m5), `grep -rn 'template-dependent arguments\|explicit receiver for
    a' toolchain` hits the two call.cpp gates plus fail_todo_gates.carbon,
    and `grep -rn '`overload fn` in an `impl` body' toolchain` hits the
    handle_function.cpp gate plus fail_todo_gates.carbon; after
    OV-2 the import, generic-member, generic-scope and extern strings are
    gone; after OV-3 the export string is gone; each of the five OV-1
    kinds and two OV-2 kinds has one kind.def line, one `CARBON_DIAGNOSTIC`
    and one emit site (`check_diagnostics.py`); `grep -rn
    DiscardCleanupsSince toolchain/check/call.cpp` hits every exit path of
    the probe (amended 2026-09-27, review fold: rev A A1).
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
        W-086..W-093 by UN-1 — never assume numbers): "virtual members of overload sets"
        (D-OV-1; mechanism: a seventh modifier order group and
        signature-keyed vtable slots); "members of overload sets with
        non-value parameters" (D-OV-6 (iii); mechanism: a pattern-kind-aware
        probe, or a `diagnose` flag on `CallerPatternMatch`); "`self`-shape
        overloading" (D-OV-3; paper open question 4, upstream #3154);
        "overload sets in interfaces" (gate (ix)); "per-candidate failure
        notes at Clang granularity" (paper open question 7 — the 0.1 notes
        carry a five-way reason); "mixed method/non-method overload sets"
        (gate (x); rev A A2 / rev B B2 F-009l; mechanism: per-member
        receiver alignment in the loop is already the belt, so lifting is
        deleting the gate once binding is decided per member); "per-member
        access in overload sets" (gate (vi) vs the ported page's
        "visible members only", D-OV-8); "overload resolution with
        template-dependent arguments" (gate (xi), rev B B4; mechanism:
        resolve after substitution); "explicit receiver for `ref self`/`addr
        self` overload members" (gate (xii), rev 2b M1; mechanism: a
        ref-tag/category probe on argument 0); "overload sets in `impl` bodies"
        (gate (xiii), rev 2b m3d — covers destructors); "unconditional constant-evaluation diagnostics
        inside overload probes: literal→float and abstract-init" (R-15, rev
        A A3 / rev 2b m2); and, only if
        their fallbacks fire, "extern members of overload sets" (§1.B.3),
        "overload sets in generic scopes" (§1.B.5 — otherwise NOT a
        residue, the gate is lifted at OV-2) and "marked members without a
        definition" (§1.B.7). The pattern-dispatch future (Option C) stays
        in the doc, not the ledger.
6.  **Docs (D-OV-8, the PORT; amended 2026-09-27, review fold: rev B
    B1/B2/B6/B7):** at OV-1, `git show
    481e08c24:docs/design/functions_overloading.md >
    docs/design/functions_overloading.md`, then edit in place: a dated
    status paragraph after the Overview ("fork amendment 2026-09-27, F-009;
    ported from the stranded design-docs branch 481e08c24; toolchain
    status: same-file sets landed at OV-1, import and generic members at
    OV-2, export at OV-3"); every "OPEN (sub-fork F-009x)" paragraph and
    its "Open sub-forks" entry rewritten to "CLOSED (fork amendment
    2026-09-27) by D-OV-n: ..." per the D-OV-8 mapping — a: legal
    (single_member); b: yes, impl files define only, `OverloadSetFrozen`;
    c: no, TODO-gated; d: NO in 0.1 (the page's YES declined with the
    vtable reason; residue); e: no, TODO-gated; f: per-candidate notes with
    a five-way reason; g: hard error `OverloadSetNotCallee`; h: yes,
    whole-set and transitive through `export import`; i: export the
    exportable subset; j: no default arguments, arity exact; k: invalid
    redeclaration of the type-identical member; l: no, TODO-gated; m: moot
    (Decl group, exclusive with `virtual`/`abstract`/`impl`); the
    "Linkage and mangling" section rewritten to D-OV-5 with the §0.1 row 9
    reason and the asm-label truth (§0.2 item 14); further rewrites the
    re-review found (amended 2026-09-27, review fold: rev 2b m3): (a) "The
    `overload` keyword" :150-162 ("a NEW standalone modifier group ...
    cannot join the existing `Decl` group ... would foreclose sub-fork
    F-009d") rewritten to D-OV-1's Decl-group placement with the declined
    F-009d; (b) "Documented divergence" :692-698's second shape asserts
    "`i32 → f64` is a lossless implicit conversion" — FALSE in the prelude
    (the `Int(From) as ImplicitAs(Float(To))` impls are commented out,
    float.carbon:165-173) — replaced by this plan's own `Pick` (`i64`
    first, `i32` second: Carbon selects `i64` by widening, C++ selects
    `int` exactly, §5.C.2); (c) "The `overload` modifier" :133-138 ("never
    silently joins the set ... a note suggesting adding `overload` to the
    original declaration") annotated with D-OV-3's actual behavior
    (`OverloadMarkerMismatch` + `OverloadMarkerPrevious`; an unmarked
    later declaration is diagnosed and then recovers AS IF marked; a marked
    later declaration against a plain function is diagnosed and not
    merged); (d) :259-260 "member functions of unions, under the same rules
    as classes" stands and is pinned (`union_scope_set`; UN-1 landed),
    :262-263 "not permitted on destructors" is annotated: destructors are
    `impl as Core.Destroy` and every `impl`-body member is gate (xiii);
    (e) the
    dated "0.1 limits" paragraph lists EVERY gate — (i) generic members
    until OV-2, (ii) generic scopes until OV-2, (iii) non-value
    parameters, (iv) `extern` until OV-2, (v) the entry point, (vi)
    uniform access, (viii) export until OV-3, (ix) interfaces, (x) mixed
    `self`, (xi) template-dependent arguments, (xii) explicit `ref
    self`/`addr self` receivers, (xiii) `impl` bodies — plus `virtual`/`impl`/
    `export` members (D-OV-1) and the marked-signature-typo limit (an
    api-declared member without a definition fails at link until OV-2's
    check; §1.B.7); (f) "The candidate match test" :418-420 ("without
    emitting diagnostics") gets the R-15 annotation naming the
    literal→float and abstract-init emitters; the "Closed,
    same-library sets" paragraph's "visible members only" sentence
    annotated with gate (vi); the "Interaction with checked generics"
    section annotated: the third case ("depends on the specific") cannot
    arise from the probe (D-OV-4 step 7), template-dependent calls are
    TODO-gated (gate (xi)); the method example already uses `ref self`
    (:241-244, the working syntax). Also at OV-1: docs/design/functions.md
    gains the ported four-line link block after "Member functions" in
    "Functions in other features" (:879-882 on the stranded branch);
    docs/design/pattern_matching.md:696 and :1063-1066 get the ported
    hunks (the :696 bullet → "For overloaded functions, declaration order
    is used, per fork decision F-009 ..."; :1063 → "For 0.1, overload
    selection is fixed by fork decision F-009 and specified in Function
    overloading: declaration-order first-match over signatures containing
    only irrefutable patterns ..."), each followed by "(fork amendment
    2026-09-27)"; no other hunk of the stranded pattern_matching.md diff is
    ported (they predate W-012). At OV-2: the status paragraph.
    At OV-3: docs/design/interoperability/README.md:210 gets the ported
    `### Overload resolution` section and TOC line (NOT the stranded
    threading/inline-Cpp hunks); docs/design/README.md:3878-3881 gets the
    ported note + paragraph (the "Error handling" entry :3884-3888 shape);
    the status paragraph. W-065's evidence for the two retired
    placeholders is refreshed at OV-3 (§0.2 item 12). **fork/gap-analysis.md:57** — OV-1: MISSING →
    **PARTIAL** with evidence "Carbon-native `overload fn` closed sets:
    marker keyword, `OverloadSet` SemIR entity, declaration-order
    first-match resolution with implicit conversions, per-member
    redeclaration matching, distinct mangling per member, method sets and
    aliases; same-file sets only — api/impl and cross-library import,
    generic members and export are TODO-gated (OV-2/OV-3); 2/2 conformance
    programs PASS"; header delta MISSING −1 / PARTIAL +1. OV-2: PARTIAL
    with the evidence rewritten ("+ set import across api/impl and
    libraries with the closed-set rule, generic members by non-diagnosing
    deduction, overloaded methods of generic classes; export TODO-gated;
    5/5 PASS"); no header delta. OV-3: →
    **DONE** with evidence "OV-2 text + exported sets resolve under C++
    rules with the documented divergence conformance-tested both ways
    (7/7 PASS). Gated residue, each a filed item: overload sets in
    interfaces, virtual members, non-value parameters, `self`-shape
    overloading, mixed method/non-method sets, template-dependent
    arguments" (the row 44 DONE-with-gated-residue precedent
    fork/unions/plan.md §8.6 cites); header delta PARTIAL −1 / DONE +1.
    **If §1.B.5's generic-scope lifting is refuted, the row stays PARTIAL
    at OV-3** with that gate named in its evidence and no header delta
    (rev B B5's rule). R7: bullet TEXT untouched.
7.  **Decision log:** entries "OV-1: `overload fn` closed sets (date)",
    "OV-2: overload-set import and generic members (date)", "OV-3:
    overload-set export (date)" carrying D-OV-1..10 with break
    conditions, the §0.2 corrections verbatim, the V-3a divergence-register
    line (the `overload` keyword, the `:overload<N>` mangling marker and
    the `OverloadSet*` inst kinds are fork spellings; upstream's
    `overloaded` placeholder is a rename away), the residue items by
    title with the ids allocated at that discharge, and the R29(a)
    auto-adoption notes (rev 2's coordinator rulings included).
    fork/rulebook.md gains the bidirectional-assertion rule at OV-3 under
    the next free number (§5.C.2). fork/ORCHESTRATION.md header, branch
    table and scoreboard line stamped per PR; at OV-1 discharge the
    stranded-branch row (:311) gains "overloading portion ported by
    OV-1/OV-3; do not re-land" (amended 2026-09-27, review fold: rev B
    B1).

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
-   The probe is the `DeduceImplArguments` idiom PLUS the cleanup snapshot
    (record block size and `cleanup_scope_depth()`; push block; push
    `GenericId::None` region; probe; pop region; `PopAndDiscard`;
    `DiscardCleanupsSince(depth)`; CHECK size and depth) — in that order,
    on every exit path including "reason" early-outs. The idiom alone
    leaks temporaries' cleanups into the enclosing block (rev A A1).
-   Never value-convert the receiver in the probe; check receiver
    presence against `self_param_id` first (rev A A2), and run the
    IntLiteral range pre-test before converting a literal (rev A A3).
-   The set value is `AddInst`ed into the current block right after the
    first member's placeholder `fn_decl` (rev A A4).
-   Port the stranded page with `git show 481e08c24:...`; do not write a
    parallel section; close every sub-fork paragraph in place (rev B B1).
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

## Review fold record (rev 2, 2026-09-27)

Every finding of the two rev 1 reviews and where it was folded; the
coordinator's [R29(a)] rulings are marked.

| Finding | Fold |
| --- | --- |
| rev A A1 (BLOCKER): the probe leaks temporaries' cleanups into the enclosing block → lowering "Missing value" CHECK | D-OV-4 step 2(e) (cleanup snapshot, `DiscardCleanupsSince`, mandatory CHECK on block size + cleanup depth), step 2(d) (same wrap for OV-2 deduction), §7 R-2 rewritten, §4.A `init_arg` + `destroy_arg` (check + lower), §8.4 grep, hand-off |
| rev A A2 (BLOCKER): `self` misalignment (unconditional `BoundMethod` wrap; `CallerPatternMatch` CHECK; misaligned probe) | D-OV-4 step 2(a) receiver alignment with reasons 3/4, step 2(e) probe over `concat(self_refs, arg_ids)` with no receiver conversion, §1.A.3(c) `GetSelfIfInstanceMethod` arm keyed on `IsInstanceMethod`, §1.A.8 five-way select, §4.A `fail_static_member_via_instance` + `class_scope_call`, §7 R-1; [R29(a)] gate (x) mixed `self` (`fail_todo_mixed_self`, residue "mixed method/non-method overload sets") |
| rev A A3 (MAJOR): probes are not diagnostic-free (`int.convert_checked`) | [R29(a)] IntLiteral range pre-test in step 2(e), §4.A `literal_range`, §7 R-15, residue "unconditional constant-evaluation diagnostics inside overload probes" |
| rev A A4 (MAJOR): set value must be `AddInst`ed at declaration, not `AddInstInNoBlock` | D-OV-2, §1.A.4, §4.A dump shapes, hand-off |
| rev A A5 (MAJOR): type_iterator.cpp `default: CARBON_FATAL` is a runtime fatal | §1.A.3(g), §7 R-3 (runtime-fatal class, basic.carbon's fill as falsifier) |
| rev A A6 (MAJOR): `ReplacePrevInstForMerge` is unconditional on imported prev | §1.B.2 `replace_prev_inst` flag, §2.B.2 |
| rev A A7 (MAJOR): `overload` also exclusive with `impl`/`default`/`final` | D-OV-1 list, §4.A `fail_with_impl` |
| rev A minor (verified, no change): x-macro consumers, mirror list complete, `TryMergeRedecl` flag semantics (erroneous member becomes a new member), mangling, diagnostics, EXPECT derivations, README path | D-OV-3 `EntityHasParamError` note; §7 R-9 path; otherwise recorded here |
| rev B B1 [R29(a): ADOPT PORT]: stranded page exists (481e08c24) | header, §0.1 row 16, §0.2 items 11/14, D-OV-8 rewritten, §2.A.9, §2.B.5, §2.C.2, §3, §8.6, §8.7 ORCHESTRATION row, hand-off |
| rev B B2: sub-fork mapping F-009a..m; declined F-009d; access-kind divergence | D-OV-8 mapping and divergence note, D-OV-1 (declined recommendation with the vtable reason, F-009m moot), D-OV-3 (F-009l gate), D-OV-4 step 2(b) (F-009j), D-OV-10 (F-009h transitivity + `export_import_of_set`), §1.C.1 (F-009i `partial_export`), §8.5 residue "per-member access in overload sets" |
| rev B B4: calls from checked-generic bodies; template-dependent arguments | D-OV-4 step 7 (resolve once at the definition; no "depends on the specific" case), step 2(c) + gate (xi) [R29(a)], §4.A `call_from_generic_body` / `fail_call_from_generic_no_match` / `fail_todo_template_dependent`, residue |
| rev B B5 [R29(a)]: lift the generic-scope gate in OV-2 | D-OV-6 (ii), §1.B.5 mechanism (eval.cpp:702 specific substitution), §4.B `generic_class_method_set` + lower twin, §5.B third program, §5 deltas (+3), §7 R-16, §8.6 PARTIAL rule |
| rev B B6: marked-signature typo across api/impl | §1.B.7 (OV-1 pin `marked_typo_undefined_member`; OV-2 api-member arm of `CheckRequiredDefinitions`, fallback residue), §4.B `fail_member_undefined_in_impl` / `impl_defines_all`, §7 R-17, docs "0.1 limits" sentence |
| rev B B7: second placeholder pattern_matching.md:1063 | §0.1 row 16, §0.2 item 12, §8.6 |
| rev B B8: generate_ast.cpp is a UN-2 file (:452-457) | §6.A contention paragraph |
| rev B B9: `Carbon::F(7)` is ambiguous; no `.diff.cpp` for divergence | §4.C rewritten (`7L`, `fail_cpp_ambiguous`), §5.C note |
| rev B B10: EXPECT `14` not derivable | §5.B.2 both members `|a − b|`, i64 member doubled |
| rev B B11 [R29(a)]: `export overload fn` exclusivity stands | D-OV-1, §1.A.2, D-OV-10, §4.A `fail_with_export` |
| rev B B12: more non-callee shapes | D-OV-4 step 6 (pinned alternatives), §4.A `fail_set_as_value` additions |
| rev B B13: set declared wholly inside an impl file | §4.A `impl_local` subfile → `impl_local_set` |
| rev B B14: R30 hard-coded; D-OV-10 break condition; README path | §5.C.2 / §8.7 "allocate at discharge", D-OV-10 break condition, §7 R-9 |
| rev B verified-no-change: §0.2 items 1, 3, 4, 5, 9, 10; counts as deltas; `Pick(n)` prints 1 as the arbiter | recorded here |
| self-caught while folding B13: impl-file marker spelling | §0.2 item 13; every impl subfile spelled `impl library "...";` |
| rev 2b M1 (MAJOR): explicit receiver through the class scope is a legal shape (call_without_method_syntax.carbon:25-31); arity keyed on the wrong variable | D-OV-4 step 2(a) (reason "method without receiver" deleted; only receiver-on-non-method rejected, now reason 3), 2(b) (call.cpp:61-64 verbatim, keyed on the call's `self_id`), 2(e) (argument 0 probed against a by-value `self` pattern; `ref self`/`addr self` → [R29(a)] gate (xii) + `fail_todo_explicit_ref_receiver` + residue), §1.A.8 select, §4.A `explicit_receiver` (positive, replaces `fail_static_member_via_instance`), §7 R-1, §8.4/§8.5 |
| rev 2b M2 (MAJOR): the generic-class golden/program cannot type-check (`self.v + n` over `T:! type`) | §4.B `generic_class_method_set` and §5.B.3 use the re-reviewer's shape (`var tag: T; var total: i32`, `Make(x: i32, t: T)`); EXPECT 107, 5 unchanged |
| rev 2b m1: probe constants print; two persistent side effects | D-OV-4 step 2(e) ("may carry", `definitions_required_by_use` → extra specific `define` / `MissingGenericFunctionDefinition`; impl-lookup poisoning is right), §4.B lower `discard_probe_constants` twin, §7 R-2 |
| rev 2b m2: other unconditional emitters; helper drift | D-OV-4 break condition reworded, step 2(e) shared `IntFitsInIntType` (eval.cpp/eval.h), §7 R-15 enumerates literal→float (float.carbon:175-178, eval.cpp:1516-1522, :1578-1596) and `AbstractTypeInInit` (convert.cpp:898-903), residue title |
| rev 2b m3: port rewrites (a)-(f) | §8.6 (a) :150-162 modifier group, (b) :692-698 false `i32 → f64` example → `Pick`, (c) :133-138 marker-mismatch annotation, (d) unions pinned `union_scope_set` + gate (xiii) `fail_todo_impl_body` (destructors are `impl as Core.Destroy`), (e) full "0.1 limits" gate list, (f) :418-420 R-15 annotation |
| rev 2b m4: §8.3 OV-2 delta stale | §8.3 +3/0/+3 (or +2/+1/+3), absolutes on c0c57285f |
| rev 2b m5: gate (ix) pinned twice | `fail_on_interface_member` dropped from fail_modifiers.carbon; `fail_todo_interface` kept; §8.4 "exactly one golden" |
| rev 2b m6: `DeduceGenericCallArguments` has no `diagnose` today | D-OV-4 step 2(d) cross-references §1.B.4 |
| rev 2b trunk move: c0c57285f (EH-B #42, UN-1 #43; 114/0/25 over 140, 45/56; header 27/21/7/1; ledger max W-093) | header, §0.4, §5 absolutes, §6.A, §8.3 |
| rev 2b verified-no-change: A4 placement (set value after handle_function.cpp:637, passed at :663; class-body scope by way of `AddName`), receiver and arguments evaluated once on the commit path (`GetCallee` unwraps `BoundMethod`, function.cpp:26-29; call.cpp:257-259), gate (xi) predicate type-driven, A6/B6 feasible, EXPECT re-derivations, residue titles and gate numbering, §4/§2.A/§6.A consistency | recorded here |

## Sign-off

**SIGNED OFF FOR IMPLEMENTATION, 2026-09-27 (rev 2b).** Rev 2 folded the
two adversarial reviews; the focused re-review of rev 2 returned
SIGN-OFF-WITH-AMENDMENTS (0 blockers), whose two majors and six minors are
folded as rev 2b with no decision reopened (M1 narrows a rejection to the
one illegal combination and adds gate (xii) under R29(a); M2 fixes a test
shape). Implementation proceeds OV-1 first (§3) on trunk c0c57285f, OV-2
when OV-1's hosted verification is green, OV-3 after UN-2 per §0.4/D-OV-9.
Later amendments continue to be folded in place, each marked "(amended
<date>, review fold: ...)".

## Landed notes (2026-09-28)

OV-1 landed on claude/carbon-fork-0-1-overload: f18daf9e5 (lex + parse),
495b58274 (sem_ir + check), 51f831638 (goldens + conformance), f3daa13e1
(docs port), then cd6d97a42 (the `GetImportName` arm) and ad2cb5031
(implementation-review fixes). Ledger, gap-analysis row and decision-log
entry ("OV-1: `overload fn` closed sets, first-match resolution
(2026-09-28)") are the discharge commit; the fork/ORCHESTRATION.md
stranded-branch row (§8.7) is the owner's edit. OV-2 is next (§0.4).
Deltas from this plan, honestly:

-   **`IntFitsInIntType` is not `static`.** D-OV-4 step 2(e) asked for a
    `static` helper "extracted in eval.cpp and declared in eval.h"; a
    static cannot be shared across translation units. It is a non-static
    function (eval.h:33, eval.cpp:1417) built from two shared predicates
    (negative into unsigned; significant bits versus width), so
    `PerformCheckedIntConvert` keeps emitting `NegativeIntInUnsignedType`
    and `IntTooLargeForType` independently, as before, and the probe
    (call.cpp:394) cannot drift from it.
-   **Gates (ix)/(xiii) diagnose and then treat the declaration as
    UNMARKED** (handle_function.cpp:823-826). D-OV-6 said the member "is
    still added"; an interface member's inst is wrapped by
    `BuildAssociatedEntity`, which cannot wrap a set value, so after the
    TODO the declaration continues as a plain function. One diagnostic, no
    cascade; the gate's purpose (the loop never sees such a member) holds.
-   **Gate (xii) aborts the resolution** (call.cpp:441-445,
    `OverloadProbeResult::gated`): the plan's "and `ErrorInst`" is read as
    "the whole call is an error and no further candidate is tried", so a
    later by-value member does not silently win after the TODO.
-   **Gate ordering (i)/(ii)** (implementation-review minor): a method of
    a generic class has its own `generic_id`, so (ii) takes precedence
    (`else if`, handle_function.cpp:685-690) and one TODO fires. The
    `fail_todo_generic_scope` CHECK lines filled by the second autoupdate
    still show both strings (fail_todo_gates.carbon:34 and :38); the third
    autoupdate drops :34.
-   **Mirror sites the §1.A.3 / R-3 inventory missed — two compile-time,
    one RUNTIME FATAL.** (1) cpp/call.cpp `PerformCallToCppFunction`'s
    exhaustive `Callee` variant switch needs a `CalleeOverloadSet` arm
    (`CARBON_FATAL`, like `CalleeNonFunction`). (2) lex/lex.cpp
    `CollectMismatchedBracketTokens`' hand-written modifier-keyword list
    (the bracket-recovery statement-introducer set) gains
    `TokenKind::Overload` beside `Override`; behavior-preserving for every
    existing input. (3) check/import.cpp `GetImportName`'s switch over
    EXPORTED inst kinds has `default: CARBON_FATAL("Unsupported export
    kind: {0}")`, and neither this plan nor the implementer's
    `CppOverloadSet` grep found it — a C++ set is never exported by name,
    so it has no arm there to mirror. The first hosted autoupdate (run
    36441457310) crashed there on the api-scope set of
    fail_todo_impl_file.carbon ("Unsupported export kind:
    OverloadSetValue"); cd6d97a42 adds the arm (the set value maps to its
    `OverloadSet` entity's name and parent scope; resolving it on import
    stays gated in import_ref.cpp). R-3's runtime-fatal class is therefore
    THREE sites (sem_ir/type_iterator.cpp, the import_ref.cpp switch,
    `GetImportName`), and R-3's falsifier "basic.carbon's fill" was
    insufficient: only a multi-file golden with an api-scope set reaches
    `GetImportName`. A review miss per R28(d).
-   **Implementation-review MAJOR-1: imported set MEMBERS.**
    import_ref.cpp's `TryResolveTypedInst(FunctionDecl)` builds a local
    `Function` for a member named inside an imported generic's body
    (resolved when the importer instantiates the generic) without its
    `overload_set_id`, so it mangled un-indexed and collapsed onto its
    siblings' LLVM declaration. A first fix gated that arm with the OV-2
    TODO; its pin (fail_todo_import_member.carbon) filled EMPTY on the
    third autoupdate — the specific never imports the set, so the gate was
    unreachable and the collapse was live. Root fix (1baec5d70):
    `FunctionFields::overload_index` (assigned when a member joins its
    set, mirrored by `ImportFunctionDecl`), the mangler keys
    `:overload<N>` on it (a CHECK ties it to `GetOverloadMemberIndex` for
    local sets), and the member arm is no longer gated. Pins: the POSITIVE
    check golden import_member_specific.carbon and its lower twin (the
    importer's specific must call `_CP:overload0.Main`; `_CP.Main` is the
    falsifier). The "overload set import" string is reached at TWO sites
    (the set type and value resolver arms).
-   **§8.4's "two resolver arms" is one helper.** The grep hits the single
    `context.TODO(LocId::None, "overload set import")` in
    `HandleUnsupportedOverloadSet` (:2288); the three arms share it.
-   **Spellings to working syntax (R3).** Generic parameters are `[T:
    type]` / `template T: type` (the plan's `T:! type` does not lex in
    this tree); the user destructor is `impl as Core.Destroy { fn
    Op(unused ref self) {} }`; `fail_no_candidate` passes `1.5` (no
    string-literal parameter precedent); the api/impl pairs are
    `set.carbon` / `fail_set.impl.carbon` and `local.carbon` /
    `local.impl.carbon` so `[[@TEST_NAME]]` matches across each pair; the
    parse subfile `fail_ordering` is `ordering` (file_test requires
    `fail_` iff the subfile errors; the order error is check-side).
-   **Docs port.** The F-009k closure sentence had `#3763` at a line
    start; prettier read it as a `##` heading and demoted every following
    H2 (review MAJOR-2). Rejoined in ad2cb5031; heading parity with the
    stranded page proven by `grep '^#'` against `git show 481e08c24:...`
    (only `### 0.1 limits` is new). Links to the em-dash decision-log
    headings carry no fragment: check-links percent-encodes the dash in
    the link but keeps it raw in the anchor, so no spelling validates
    (HTML comment at functions_overloading.md:65). The candidate-match
    annotation's residue text adds aggregate-literal element conversions
    (an out-of-range literal element of a struct/tuple literal against a
    narrow integer field still runs `int.convert_checked`); the §8.5
    residue title is widened to match (W-104). Gate (iii) also covers
    destructuring tuple/struct parameter patterns (their leaf is not a
    single `ValueParamPattern`) — the gate comment and "0.1 limits" say
    so.
-   **Scoreboard base.** This plan's "114/0/25 over 140" (header, §0.4,
    §5, §8.3) is a hand count: fork/conformance/out/scoreboard.json at
    c0c57285f sums to 139 (PASS 114 + SKIP 25; 139 programs listed).
    OV-1's expected absolutes are therefore 116/0/24 over 140, 46/56
    bullets; the delta (+2 / −1 / +1) §5.A predicted is unchanged.

Reconciliation greps (§8.4), run at ad2cb5031:

-   `grep -rn 'overload set import' toolchain`: two hits in sources —
    import_ref.cpp:2288 (the TODO emitter) and import.cpp:83 (the comment
    on the `GetImportName` arm) — and two CHECK lines in one golden,
    fail_todo_impl_file.carbon:28 and :30. The two REACH sites are the
    set type and value resolver arms (import_ref.cpp:2296, :2302); the
    member arm is not gated (see the MAJOR-1 note above).
-   `grep -rn 'overload set export' toolchain`: cpp/generate_ast.cpp:256
    and fail_todo_export.carbon:36. As planned.
-   The nine declaration-gate strings: each exactly once in
    handle_function.cpp (:260 disagree on `self`, :273 distinguished only
    by `self`, :663 interface, :686 generic scope, :689 generic
    parameters, :710 non-value parameter, :716 `extern`, :720 entry point,
    :730 differing access) plus fail_todo_gates.carbon; gate (ix)'s string
    is in exactly ONE golden (fail_todo_gates.carbon:104, rev 2b m5). The
    generic-parameters string appears twice in the golden (:23, and the
    stale :34 the third autoupdate removes).
-   `grep -rn 'template-dependent arguments\|explicit receiver for a'
    toolchain`: call.cpp:441 and :495 (plus their comments :433, :485) and
    fail_todo_gates.carbon:139, :164. As planned.
-   `` grep -rn '`overload fn` in an `impl` body' toolchain ``:
    handle_function.cpp:667 and fail_todo_gates.carbon:180. As planned.
-   The five kinds: one kind.def line each (:300, :301, :309, :310, :311),
    one `CARBON_DIAGNOSTIC` each (handle_function.cpp:198 and :201,
    call.cpp:567 and :570, convert.cpp:2103), one emit site each
    (`DiagnoseOverloadMarkerMismatch` :204-205, called from :227 and :369;
    call.cpp:578 and :581; convert.cpp:2107); each fires in a golden
    (fail_marker_mismatch, fail_no_match and basic, fail_set_as_value).
-   `grep -n DiscardCleanupsSince toolchain/check/call.cpp`: ONE hit
    (:464). The probe's loop exits only by `break`, never `return`, so
    every exit path funnels through the single unwind sequence (`Pop`,
    `PopAndDiscard`, `DiscardCleanupsSince`, the CHECK at :465-468); §8.4's
    "every exit path" is met by structure, not repetition.
-   `git diff origin/trunk...HEAD --diff-filter=M -- toolchain/check/testdata
    toolchain/lower/testdata toolchain/parse/testdata`: empty. No
    pre-existing golden moved (§6.A's zero-churn claim holds, unlike UN-1).
-   Ledger max id on trunk c0c57285f: W-093 (by script); W-094..W-104
    allocated to the eleven §8.5 residues (UN-2's discharge took none).

Hosted verification of record (R28(b); the container cannot build the
toolchain): first autoupdate run 36441457310 FAILED (the `GetImportName`
crash); second autoupdate 36444528619 success; third
autoupdate, after ad2cb5031, 36446922583 success (the member-gate pin
filled empty); fourth, after 1baec5d70, 36449480945 success; gate
36451253811 green; conformance 36451200115: 116 / 0 / 24 over 140, 46/56
bullets, exactly the expected 116 / 0 / 24 over 140, 46/56.

## Landed notes (OV-2, 2026-10-05)

OV-2 landed on claude/carbon-fork-0-1-ov2: 255314a06 (import of the set,
the closed-set rule, api-member definitions), 90a603a38 (generic members,
sets in generic scopes, goldens, conformance, ledger), b1cdf9e16 (the
ported page's status paragraph), then 24cacacf3 (implementation-review
fixes) and 843d20244 (round-2 fixes), with the hosted fills 71fa9bb1a,
fc3a74dce and 657bbe634 between them. Ledger, gap-analysis row and
decision-log entry ("OV-2: overload-set import, generic members, api/impl
definitions (2026-10-05)", D-OV-11..16) are the discharge commit. OV-3 is
next (§0.4; UN-2 is in, so D-OV-9's sequencing is met). Deltas from this
plan, honestly:

-   **`impl_defines_all` is folded into `api_impl`.** §4.B asked for an
    `api_impl` pair (definitions merge, no diagnostic) and a separate
    `impl_defines_all` positive for §1.B.7; they are the same program, so
    import.carbon's `api_impl` / `api_impl.impl` pair is the one positive
    and `fail_undefined.impl` (api declares two, impl defines one) is the
    negative. The class-scope twin is import_class_scope.carbon's
    `api_impl` pair.
-   **Subfile spellings.** `[[@TEST_NAME]]` strips `fail_` and the first
    extension, so every api/impl pair is `<name>.carbon` /
    `[fail_]<name>.impl.carbon`: §4.B's `fail_impl_adds_member` is
    `frozen` / `fail_frozen.impl`, `fail_import_unmarked` is `unmarked` /
    `fail_unmarked.impl`, `extern_member` is `extern_lib` /
    `extern_owner`, `fail_member_undefined_in_impl` is `undefined` /
    `fail_undefined.impl`; `export_import_of_set` is export_import.carbon
    (`base` / `reexport` / `use`, plus `reexport_twice` / `use_two_hops`);
    generic.carbon's main subfile is `generic_second` beside
    `generic_first` and `fail_deduce_all`. Every `fail_` unit is the
    emitting unit (per-unit `success()`), which is why
    `fail_undefined.impl.carbon` carries the prefix although its diagnostic
    points into the api file. `unused` marks every unused runtime binding
    so positives carry no warnings (the OV-1 discipline).
-   **§1.B.5 lifted by deletion alone — AND step 2(d) runs for
    generic-class members (D-OV-15).** `OverloadSetType.specific_id`
    already records the enclosing self specific and `GetCallee` already
    carries it as `CalleeOverloadSet.enclosing_specific_id`, so lifting
    gate (ii) was deleting it: neither check/type.cpp nor
    sem_ir/function.cpp changed (§6.B listed both). §1.B.5's "members of a
    generic class are effectively non-generic within the specific, so step
    2(d) is not engaged" is wrong in its second half: such a member has its
    own `generic_id` carrying the class's bindings, so the probe deduces it
    non-diagnosing against `enclosing_specific_id` exactly as
    `ResolveCalleeInCall` does for a plain method (call.cpp
    `ProbeOverloadCandidateInScratchScope`). `MakeSpecific` deduplicates,
    so the lower pins still show exactly two `define`s per specific
    (`@"_CAdd:overload0.Box.Main.5d388d3559e392d2"`, lower/generic_class
    and lower/import_generic_class). The §1.B.5 fallback did not fire: no
    residue, and the gap row's DONE at OV-3 is not foreclosed.
-   **§1.B.3's `extern` lifted FULLY, two-file owner shape included
    (D-OV-11, D-OV-12).** The gate is gone and no "extern members of
    overload sets" residue is filed. The first implementation did only the
    one-file shape (the owner's api defines inline, `extern_owner`); the
    two-file shape — the owner's api redeclares `extern overload fn`
    without a body, its impl defines (function/definition/
    extern_library.carbon's `two_file`) — falsely emitted
    `ExternRequiresDeclInApiFile`, because the impl's import ref
    canonicalizes to the set's library and the api's owning redeclarations
    are not in name lookup (the entry stays the set value, rev A A6).
    `ImportedOverloadSetSource` now decides per MEMBER (the api IR's
    localized copy of the set at the same index has
    `first_owning_decl_id` → `ApiForImpl` rules) and supplies the api
    member's facts (`MakeApiMemberRedeclInfo` → `prev_decl_override` on
    `MergeFunctionRedecl`), so the api/impl rules see the api file's
    declaration as they do for a plain function (`RedeclRedef` /
    `RedeclRedundant`). import.cpp `AddImportRefOrMerge` loads the set's
    members eagerly when one is owned by the current library, so
    `MissingOwningDeclarationInApi` fires for set members. Pins:
    `extern_two_file` (check + lower), `fail_extern_unowned`,
    `fail_extern_partial`, `extern_api_defined`.
-   **An arm the plan never anticipated: `ResolveAsScope` for an
    api-declared class (D-OV-13).** `fn D.G(x: i32) -> i32 {...}` out of
    line in an implementation file hit `QualifiedNameInNonScope`: an impl
    file reaches the api's classes only through import refs and
    `DeclNameStack::ResolveAsScope` had no arm for one — no landed golden
    had `fn C.F` in an impl file (a trunk-level gap, `overload` or not).
    decl_name_stack.cpp `GetApiClassDeclForQualifier` resolves an
    `ApiForImpl` import ref whose api inst is a `ClassDecl` to the
    localized class's declaration; a class the api merely imported stays a
    non-scope. Found by the second fill, not by review.
-   **Gate (iii) keyed on the declaration being checked (D-OV-16).**
    `DiagnoseOverloadGates` read the merged function's `param_patterns_id`;
    for a declaration-only redeclaration of an imported member that block is
    `ImportRefLoaded`s, never a `WrapperBindingPattern`, so the two-file
    owner's api fired the non-value-parameter TODO at `x: i32`. The gate
    now walks `function_info`. Also found by the second fill.
-   **§1.B.7 landed with one more rule.** The api IR's `overload_sets()`
    also holds every set the api file merely loaded from an import
    (localized whole, placeholder members without `definition_id`), so the
    arm skips a set whose first member carries an import source; it also
    tolerates a member this file never loaded (`ConstantId::None` —
    `is_constant()` would have DCHECKed) and an `ErrorInst` member. The
    "marked members without a definition" fallback did not fire.
-   **Spellings to working syntax (R3).** `class Box(T: Core.Copy)`
    (D-OV-14) for the generic-class shapes, because `Make` copies its `t:
    T` parameter into the `tag` field; generic members are `[T: type]`;
    every impl subfile is `impl library "[[@TEST_NAME]]";` (§0.2 item 13).
-   **§6.B's file count holds, the list does not.** Nine source files:
    call.cpp, check_unit.cpp, decl_name_stack.cpp, deduce.cpp, deduce.h,
    handle_function.cpp, import.cpp, import_ref.cpp, kind.def — import.cpp
    and decl_name_stack.cpp in place of type.cpp and sem_ir/function.cpp.
    Pre-existing goldens that moved: fail_todo_gates.carbon (the three
    gated subfiles deleted, as planned) and import_member_specific.carbon
    (comment only); fail_todo_impl_file.carbon deleted with its
    `impl_local` pair surviving as import.carbon `impl_local_set`. Nothing
    else.
-   **Residue the reviews added (filed at discharge, blocked_by []):**
    W-105 probe-minted specifics evaluated before conversion decides
    (`DeduceGenericCallArguments` ends in `MakeSpecific` →
    `ResolveSpecificDecl`, so a deduction-accepted / conversion-rejected
    candidate's declaration block is evaluated and may diagnose — the
    `discard_probe_constants` shape); W-106 `diagnose=false` deduction
    accepts an `ErrorInst` argument; W-107 an impl-file `extern overload
    fn` against an `ErrorInst` set (or a rejected redefinition) still gets
    `ExternRequiresDeclInApiFile` from the plain no-merge path (trunk
    recovery parity; `fail_extern_api_defined.impl` pins it). The three
    conditional residues of §8.5 are NOT filed.
-   **Scoreboard base.** The base of record is origin/trunk's
    fork/conformance/out/scoreboard.json after the OV-1 merge (3c9df53f7):
    118 PASS / 0 FAIL / 24 SKIP over 142, 46/56 bullets. This branch's
    in-tree copy is the UN-2-era 6e6e4c7a9 (116 / 0 / 25 over 141, with
    overloading_native still SKIP), which the orchestrator's scoreboard
    push replaces. §5.B's delta (+3 PASS / 0 SKIP / +3 programs) applies to
    the base of record: expected 121 / 0 / 24 over 145, 46/56.

Reconciliation greps (§8.4), run at 657bbe634:

-   `grep -rn 'overload set import' toolchain`: ZERO hits — sources and
    goldens. `HandleUnsupportedOverloadSet` is gone; `GetLocalOverloadSet`
    and the two resolver arms replace it.
-   The generic-parameters, generic-scope and `extern overload fn` gate
    strings: gone from handle_function.cpp and from fail_todo_gates.carbon
    (the phrase `extern overload fn` survives in two comments,
    handle_function.cpp:264 and :273, describing the owning redeclaration
    — not a TODO). The nine remaining gates are one site each:
    handle_function.cpp:422 (x), :435 `self`-only, :855 (ix), :859 (xiii),
    :902 (iii), :908 (v), :918 (vi), call.cpp:453 (xii), :535 (xi), plus
    fail_todo_gates.carbon.
-   `grep -rn 'overload set export' toolchain`: cpp/generate_ast.cpp:256
    and fail_todo_export.carbon:28. As planned, OV-3's.
-   The two OV-2 kinds: kind.def:302-303, one `CARBON_DIAGNOSTIC` each
    (handle_function.cpp:401, :405), one emit site (:408-409); each fires
    in `fail_frozen.impl`, `fail_cross_library_adds_member` and
    `fail_extern_non_member`. Reason 2 of `OverloadCandidateRejected` fires
    in `fail_deduce_all`.
-   `grep -n DiscardCleanupsSince toolchain/check/call.cpp`: ONE hit
    (:504); `ProbeOverloadCandidate` owns the single unwind and
    `ProbeOverloadCandidateInScratchScope` returns into it from every exit.
-   `git diff 490ee40cd...HEAD --diff-filter=M -- toolchain/check/testdata
    toolchain/lower/testdata toolchain/parse/testdata`: fail_todo_gates.carbon
    and import_member_specific.carbon only, both intended.
-   Ledger max id on this branch: W-104; W-105..W-107 allocated to the
    three residues (the slices branch allocates independently; renumbered
    at merge if they collide).

Hosted verification of record (R28(b); the container cannot build the
toolchain): first autoupdate run 36459794418 (fill 71fa9bb1a) converged in
one pass over commits 1-3; second autoupdate run 37325822499 (fill
fc3a74dce, after 24cacacf3) refuted three predicted fills — import_class_scope
`api_impl.impl` (`QualifiedNameInNonScope` × 2 plus two
`MissingDefinitionInImpl` cascades), import.carbon `extern_two_file` (gate
(iii) × 2) and `fail_extern_partial` (gate (iii) beside the predicted
`MissingOwningDeclarationInApi`) — fixed at the root in 843d20244; third
autoupdate run 37331151699 (fill 657bbe634) matched every prediction in one
pass. Gate 37333625063; conformance 37333428997: 121 PASS / 0 FAIL / 24 SKIP over 145, 46/56 bullets, against the
expected 121 / 0 / 24 over 145, 46/56.
