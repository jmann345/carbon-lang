<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Structural conformance plan: `template constraint` with member requirements (SC-1, W-027)

**Status:** rev 2 (2026-10-06) — both adversarial plan reviews (R29(c)) are
folded (review A, correctness of the mechanism against the toolchain, and
review B, design fidelity / scope / tests / process; each
APPROVE-WITH-AMENDMENTS, no BLOCKER); signed off for implementation — see the
Review fold record and Sign-off at the end. Each fold is marked in place as
"(amended 2026-10-06, review fold: A*n* / B*n*)". Branch
`claude/carbon-fork-0-1-sc` off trunk 8068151ed (post-PR 50: the upstream
advance UA-1 landed; the cut is upstream c1e83b0b7 of 2026-10-05 plus every fork
feature). **Base:** fork/conformance/out/scoreboard.json on this trunk reads
`totals.PASS = 128`, `totals.SKIP = 22`, every fail class 0, so 150 programs
(generated 2026-10-06T02:26:01Z on the hosted-verification toolchain, run
37402970811); 48 of 56 bullets PASS. The gap-analysis header
(fork/gap-analysis.md:18) agrees: 30 DONE / 21 PARTIAL / 4 MISSING / 1
DESIGN-ONLY. Every count below is a DELTA against that base and the absolutes
are re-quoted from scoreboard.json at rebase, never derived (R9).

This plan implements the member-requirement half of fork decision F-010
(fork/decision-log.md:1357-1363: "`template constraint` + `require`"; design
record fork/design-sprint/structural-conformance.md, option B staged B1 → B2 →
B3). SC-1 is B1 — ledger item W-027 "SC-B1: `template constraint` + structural
member requirements" (fork/inventory/work-items.json:521). B2 (`require`
validity blocks and boolean predicates, W-028) and B3 (two-way C++20 concept
mapping, W-029) stay blocked on this item and are NOT in scope; §1.G says what
SC-1 deliberately leaves for them. One PR, three commits, a hosted fill after
each (§3).

The design record predates two upstream mechanisms that change where the work
lands, and this plan decides against the record where the code has moved:
upstream's action-based template phase (PRs 7682, 7710 and 7727: `CallAction`,
`ConvertAction`, `AccessMemberAction` parked in the generic's eval block and
performed at instantiation, and template lowering through `SpliceInst`) retires
the record's "one new deferred-action kind" (D-SC-3), and the facet-conversion
chokepoint the ledger cites as convert.cpp:1596 is now convert.cpp:1955 (§0.2).

## §0 Audit: what already exists, and where the ledger is stale

### §0.1 Sub-feature table (verified in-tree at 8068151ed)

| # | Design element (F-010 B1 / p000818 as landed in details.md:1071-1077 / p002200) | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `template` keyword | LANDED as a keyword, not a modifier | lex/token_kind.def:236 `CARBON_KEYWORD_TOKEN(Template, "template")`; it is consumed only inside binding patterns (parse/handle_binding_pattern.cpp:89, :218 `TemplateBindingName`; handle_pattern.cpp:37; handle_let.cpp:36). `constraint` is a declaration introducer (token_kind.def:163; parse/handle_decl_scope_loop.cpp:134-135 maps it to `NamedConstraintIntroducer` / `TypeAfterIntroducerAsNamedConstraint`) |
| 2 | Parsing `template constraint X { … }` | MISSING: `UnrecognizedDecl` | parse/testdata/generics/named_constraint/template_constraint.carbon, split `fail_todo_template_constraint.carbon` (:11-33): both `template constraint Foo {` and `template constraint ForwardDeclared;` yield `InvalidParseStart 'template'`. Mechanism: `HandleDecl` (handle_decl_scope_loop.cpp:333-351) runs `TryHandleAsModifier` (:299-331), whose accepted set is the x-macro `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER` list (:303-309) plus `extern` (:311-325); `template` is in neither, so `TryHandleAsDecl` sees it with `DeclIntroducerKind::Unrecognized` (:195-205). The TODO at :343-347 even names the phase-keyword-before-introducer case |
| 3 | Modifier machinery | MACHINERY LANDED, one x-macro line away (the OV-1 `overload` precedent, fork/overload/plan.md D-OV-1) | parse/node_kind.def modifier block :422-437 (`Abstract` :422 … `Static` :436, `Virtual` :437); every consumer is generated: `TryHandleAsModifier` (:303-309), the next-token list of `ResolveAmbiguousTokenAsDeclaration` (:284-286), the statement-level dispatch (parse/handle_statement.cpp:54-56), the check handler `HandleParseNode(Parse::Name##ModifierId)` (check/handle_modifier.cpp:111-118). `NamedConstraintSignature` already carries `llvm::SmallVector<AnyModifierId> modifiers` (parse/typed_nodes.h:1992-2000) |
| 4 | Check: modifier set and per-declaration limits | MACHINERY LANDED | `CARBON_KEYWORD_MODIFIER_SET` (check/keyword_modifier_set.h:29-58; the "at most one of these declaration modifiers" group :41-51 is `Abstract` … `Virtual`), `LimitModifiersOnDecl` diagnoses `ModifierNotAllowedOnDeclaration` "`{0}` not allowed on `{1}` declaration" (check/modifiers.cpp:100-107). The named-constraint declaration limits itself to `KeywordModifierSet::Access` (check/handle_named_constraint.cpp:53; re-cited 2026-10-06, review fold: A7 / B8). The group constants are explicit unions, not x-macro derived: `Decl(Class | Method | MatchFirst | Impl | Interface | Export | Returned | Overload)` at :150-154, and `CARBON_KEYWORD_MODIFIER_SET_IN_GROUP` (:170-176) `static_assert`s that every modifier is in some set |
| 5 | Check: the `template constraint` hook | TODO, two sites | handle_named_constraint.cpp:44-45 "TODO: PopSoloNodeId(`template`) if it's present, and track that in the NamedConstraint. Or maybe it should be a modifier, like `abstract class`?" and :113-114 "TODO: Support for `template constraint`." / `bool is_template = false;`, which already flows into `AddSelfSymbolicBindingToScope(…, is_template)` (:141-143, re-cited 2026-10-06, review fold: A7 / B8; check/interface.cpp:138-157) — upstream intends `Self` to be a template binding inside a template constraint |
| 6 | SemIR entity | LANDED, no template fields | `SemIR::NamedConstraint` (sem_ir/named_constraint.h:16-39: the two scopes, two body blocks, `generic_with_self_id`, `self_param_id`, `require_impls_block_id`, `complete`); `Print` :45-50 prints only `require_impls_block_id`; `MergeDefinition` :64-73. The with-self scope and generic (`scope_with_self_id`, `generic_with_self_id`) are exactly an interface's (sem_ir/interface.h:27-44), minus `associated_entities_id` (:44) |
| 7 | A `fn` declared inside a constraint body | ACCEPTED SILENTLY today | check/testdata/named_constraint/invalid_members.carbon split `todo_fail_invalid_fn.carbon` (:13-26): `fn DeclaredMethod(self, b: Self);` and `fn DefinedMethod(unused self, unused b: Self) {}` inside plain `constraint E` / `constraint F` check with NO diagnostic ("TODO: Any fn in a non-template constraint is an error"). Mechanism: the constraint body parses in `DeclScopeLoopAsRegular` (parse/handle_decl_definition.cpp:24-33: only class, interface and union get their own loop), and check builds an ordinary function whose `self` resolves against the scope's required name `Self` (interface.cpp:154-155); `MaybeAddToNameLookup` (check/handle_function.cpp:555-575) special-cases only `InterfaceWithSelfDecl` (:562-571 → `BuildAssociatedEntity`), so a constraint member is a plain `FunctionDecl` in `scope_with_self_id` |
| 8 | Facet-type store | LANDED; no structural slot | `SemIR::DeclaredFacetType` (sem_ir/declared_facet_type.h:36-121): interfaces (:59-62), named constraints (:66-69), `type_impls_*` (:72-90), rewrites (:92-102), `other_requirements` TODO bool (:106). `SemIR::IdentifiedFacetType` (sem_ir/identified_facet_type.h:35-118): `required_impls()` (:58-60), rewrites, the single impl-as interface. Flattening of named constraints into interfaces: `IdentifyFacetType` (check/type_completion.cpp:963-1250), three near-identical loops over `extend_named_constraints` (:1072-1127), `self_impls_named_constraints` (:1129-1183) and `type_impls_named_constraints` (:1185-1245), each walking the constraint's `require_impls_block_id` under `MakeSpecificWithInnerSelf` (check/generic.h:161-166); "TODO: Process other kinds of requirements." at :1247. The design record's `facet_type_info.h` does not exist at this cut (it split into these two files) |
| 9 | The conversion chokepoint | LANDED; stale citation | `PerformBuiltinConversion` (check/convert.cpp:1529-1987): the facet block :1914-1983 — runtime-facet TODO :1918-1923, the lossless round-trip shortcut :1945-1948, `LookupImplWitness(…, target.diagnose)` :1955-1957, `FacetValue{type_inst_id, witnesses_block_id}` :1966-1969, the failure branch :1970-1982 whose TODO (:1976-1977) reads "Pass this function into `LookupImplWitness` so it can construct the error add notes explaining failure". `DiagnoseConversionFailureToConstraintValue` :1503-1527 emits `ConversionFailureFacetToFacet` / `ConversionFailureTypeToFacet` with `Emit` directly (no builder, so no notes). The ledger's `convert.cpp:1596` is stale (§0.2 item 1) |
| 10 | Impl lookup | LANDED; interface-only | `LookupImplWitness` (check/impl_lookup.cpp:989-1118; header impl_lookup.h:40-43 with `diagnose = true`): `GetRequiredImplsFromConstraint` (:226-246) returns ONLY `required_impls()`, then `if (req_impls.empty()) return InstBlockId::Empty;` (:1014-1016) — a facet type with no interfaces is satisfied by every type, which is what makes `constraint E {}` convertible from anything (named_constraint/convert.carbon). The custom-witness dispatch for core interfaces lives at :910-923 (`FindNonFinalWitness`) and :1284-1296 (`EvalLookupSingleFinalWitness`) |
| 11 | Deduction converts arguments at the chokepoint | LANDED | check/deduce.cpp:309-315 (a facet-typed parameter deduces against the canonical facet), :343-346 and :566-571 (`ConvertToValueOfType` / `TryConvertToValueOfType` by `diagnose_`) — the call-site path that reaches row 9 for a concrete argument type |
| 12 | Template-dependent replay | LANDED upstream (PRs 7682, 7710, 7727) | `HandleAction` / `AddActionSpliceIfDependent` (check/action.h:139-186) park a dependent action in the eval block; `PerformDelayedAction` (:250-276) replays it from eval (check/eval.cpp:3150-3163); `PerformAction(CallAction)` → `PerformCallHelper` (check/call.cpp:894-900), `PerformAction(ConvertAction)` → `PerformBuiltinConversion` (convert.cpp:2439-2451), `PerformAction(AccessMemberAction)` (check/member_access.cpp:700-704; `PerformMemberAccess` :502-522 always goes through `HandleAction`). A dependent argument reaches the chokepoint by replay, with a concrete type (D-SC-3) |
| 13 | Template lowering | LANDED upstream (PR 7727) | lower/handle.cpp:489-513: `SpliceBlock` and same-file `SpliceInst` lower; the only remaining fatal is cross-file (:508 "Cross-file template lowering not implemented yet"). Dependent METHOD calls have lower goldens: lower/testdata/template/merging.carbon:20 `fn CallF(template T: type) { T.F(); }`, :49 `({} as T).F()`, :58-59 `x.(B.F)()`; plus class.carbon, convert.carbon, operator.carbon. The SKIP program generics/templates_dependent_member.carbon (`x.n` on a template binding) is a UA-2 un-SKIP probe (fork/upstream/plan.md §0.6, W-014 row) |
| 14 | Lowering of facet values | NO CHANGE NEEDED | lower/constant.cpp:198-199 "Represent facet values the same as types"; lower/handle.cpp:220 `FacetValue` is a no-op; witness blocks are `is_lowered = false` (`ImplWitness` typed_insts.h:1106-1112, `CustomWitness` :734-740). An empty `witnesses_block_id` is what every conversion to a pure named constraint already produces (row 10) |
| 15 | Signature matching modulo `Self` | LANDED (the thunk criterion) | check/thunk.cpp:453-468: `BuildThunk` first asks `CheckFunctionTypeMatches(callee, signature, signature_specific_id, /*check_syntax=*/false, /*diagnose=*/false)` (check/function.cpp:353-371 → `CheckRedeclParamsMatch` merge.cpp:603-633 + `CheckFunctionReturnTypeMatches` function.cpp:252-300) and uses the impl's function directly when it matches; the specific comes from `GetSelfSpecificForInterfaceMemberWithSelfType` (check/interface.cpp:59-104; the impl.cpp:49-86 caller). This is p003763 redeclaration matching — the stranded design page's own criterion ("the same notion of 'same signature' governs redeclarations, impl checking, and structural matching") |
| 16 | Qualified lookup through a named constraint (`HasGet.Get`) | LANDED | check/name_lookup.cpp:406-418 pushes `constraint.scope_with_self_id` (under `MakeSpecificWithInnerSelf`) for every `extend_named_constraints` entry of a facet type — a member declared in a template constraint's body is found by `HasGet.Get` with no new code |
| 17 | Compound access `x.(HasGet.Get)` | MISSING: would misbind | `PerformCompoundMemberAccessAction` (member_access.cpp:792-868): a member that is not an `AssociatedEntity` goes straight to `PerformInstanceBinding` (:405-...), which would bind the CONSTRAINT's bodiless function to `x` — a call would then lower an undefined symbol. D-SC-4 redirects this case |
| 18 | Member access on a template binding | LANDED, deferred | check/testdata/generic/template/member_access.carbon: `x.n` on `x: T` (`template T: type`) is `access_member_action` + `splice_inst` in the generic (golden :239-243), resolved per specific (:177-185 `specific_inst @F.%x.ref, @F(%C)` → `class_element_access`); `fail_no_such_member` gives `ResolvingSpecificHere` + `MemberNameNotFoundInInstScope` (:43-49). Structural constraints do not change this (p002200:379-399) |
| 19 | C++ methods as candidate members | LANDED import; `ref self` default | check/cpp/import.cpp:1681-1690 builds the imported `self` pattern from `signature->self_passing_mode`; `SemIR::ClangDeclSignature::self_passing_mode` defaults to `PassingMode::ByRef` (sem_ir/clang_decl.h:63-64), mapped to `ParamPatternKind::Ref` (import.cpp:1602-1612) — the golden check/testdata/interop/cpp/class/import/method.carbon:293-294 shows `%self.param_patt… = ref_param_pattern`. So a C++ method imports as `fn Get(ref self)`; a template constraint written `fn Get(self)` (value `self`) does not match it (D-SC-11) |
| 20 | Diagnostics discipline | LANDED | toolchain/diagnostics/kind.def ("Named constraint checking." block :401-403); coverage_test.cpp (every kind must appear in a file_test); check_diagnostics.py (exactly one `CARBON_DIAGNOSTIC` per kind); parse/coverage_test.cpp:17-28 (every node kind, so `TemplateModifier` needs a parse golden) |
| 21 | Conformance | SKIP stub, stale sketch | fork/conformance/programs/generics/structural_conformance.carbon: bullet :5, `EXPECT-STDOUT: 42` :7-8, SKIP :9, sketch :21-33. The sketch is Option A (an INTERFACE `HasGet` satisfied structurally) in the retired `template T:! HasGet` spelling (`:!` survives in exactly one check golden; the working spelling is `[template T: Core.Copy & Core.Destroy]`, generics/templates_type_param.carbon:27). F-010 rejected Option A, so the program is rewritten, not just un-SKIPped (D-SC-14) |
| 22 | Docs | MISSING on trunk; COMPLETE on the stranded branch | `git show 481e08c24 --stat`: docs/design/generics/template_constraints.md (862 lines; §Member requirements :180-254, §Template bindings only :362-402, §Satisfaction :451-581, §Dependencies :719-765, §Open sub-forks :788-834 listing F-010a..m), plus generics/README.md (+3), details.md (+11/−), terminology.md (+7), templates.md (+12). On trunk, details.md:1068-1127 already documents `template constraint` from p000818, and templates.md:100-111 ("Constraining templates with interfaces") is the placeholder the gap row cites. D-SC-13 ports the page (the D-OV-8 precedent: ported, not re-authored) |

### §0.2 Ledger and record claims found stale (each corrected at §8.5 discharge)

1.  **W-027 notes and the design record (:217, :286, :349, :395, :507 —
    re-cited 2026-10-06 against the 119b35439 reflow, review fold: B8) cite
    `toolchain/check/convert.cpp:1596` as the chokepoint.** It is
    `LookupImplWitness` at convert.cpp:1955-1957 inside the facet block
    :1914-1983 (§0.1 row 9). The record's `impl_lookup.h:40` for
    `diagnose = false` is still exact.
2.  **The record's "`FacetTypeInfo` is the constraint store
    (toolchain/sem_ir/facet_type_info.h)" and "two new requirement vectors
    in facet_type_info.h".** The file split into
    sem_ir/declared_facet_type.h and sem_ir/identified_facet_type.h; the new
    requirement lives on `IdentifiedFacetType` (one vector, D-SC-15), and
    nothing is added to `DeclaredFacetType`.
3.  **The record's "one new deferred-action kind for dependent arguments"
    (B1 cost, :389-399; §Implementation realities in this toolchain,
    :191-246; re-cited 2026-10-06, review fold: B8).** Upstream's PRs
    7682/7710/7727 made calls and conversions actions in their own right
    (§0.1 row 12), so a dependent argument reaches the chokepoint by replay
    of `CallAction`/`ConvertAction` with a concrete type. No new action kind
    (D-SC-3).
4.  **The record's "Template lowering is a hard fatal (lower/handle.cpp:363)"
    and W-014's citation.** Same-file template lowering landed (PR 7727;
    §0.1 row 13); the remaining fatal is cross-file at lower/handle.cpp:508.
    UA-2 re-cites W-014; this plan only depends on the fact.
5.  **The conformance program's sketch** uses an interface and `:!` (§0.1
    row 21); its SKIP reason says "neither design nor implementation
    exists" — the design has existed since F-010 (2026-07-19). Rewritten by
    D-SC-14.
6.  **The record's "structural witness: an impl-witness-shaped table" (:255-256,
    :363-367; re-cited 2026-10-06, review fold: B8) and the stranded page's
    "Structural witnesses" section (:550-566).** p002200:385-399 defines the
    semantics by NAME ("`C.F` and `HasF.F` refer to the same function";
    `z.(HasF.F)` resolves to `z.(C.(A.F))` through D's alias), which needs no
    table; a table has no consumer in B1 (§0.1 rows 14, 17). D-SC-4 drops the
    table and the ported page says so.
7.  **The record's "Checked generics unaffected: using a template constraint
    on a non-template binding is an error" is under-specified about the
    other entry points** (`impl C as HasGet`, `require impls HasGet` inside
    an interface, a symbolic argument to a template function). D-SC-8 and
    D-SC-6 decide each.
8.  **The stranded page's dependency list (:723-736) says "`template
    constraint` is not yet parsed" and "template lowering hits a hard
    `CARBON_FATAL`".** The first is what SC-1 fixes; the second is stale
    (item 4). Both sentences are rewritten in the port.
9.  **W-027's `blocked_by: []` is right; its notes still say "its
    compile-and-run arbiter blocks on W-014".** Not any more (item 4).
10. **fork/gap-analysis.md:55** ("a `template T:! I` argument still needs a
    nominal `impl as I`") spells the retired `:!`; rewritten at discharge
    (§8.5), together with the W7 paragraph's "lowering hits CARBON_FATAL"
    sentence at :187-203 insofar as it is UA-2's to fix (it is; this plan
    only flags it).

### §0.3 Decisions this plan auto-adopts (R29(a): design recommendation under V-2/V-3, veto-able after the fact)

Each decision names the upstream text it follows or the silence it fills and
carries a break condition. The decision-log F-010 entry gains a landing note
listing them verbatim at discharge (§8.5).

-   **D-SC-1 — surface: `template` becomes a declaration MODIFIER, accepted
    only on `constraint`.** Parse: one line
    `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER(Template)` in parse/node_kind.def
    between `Static` (:436) and `Virtual` (:437); every parser and checker
    consumer is x-macro generated (§0.1 row 3). Check: `X(Template)` in the
    "at most one of these declaration modifiers" group of
    `CARBON_KEYWORD_MODIFIER_SET` (keyword_modifier_set.h:41-51, between
    `Returned` and `Virtual`) AND `| Template` in the explicit union
    `KeywordModifierSet::Decl` (:150-154) — the group constants are not
    derived from the x-macro, and `CARBON_KEYWORD_MODIFIER_SET_IN_GROUP`
    (:170-176) fails the build ("Modifier missing from all modifier sets:
    Template") for a modifier in no set; membership in `Decl` is also what
    gives `HandleModifier` its ordering arm (handle_modifier.cpp:58-60; the
    fall-through is `CARBON_FATAL("Unexpected modifier keyword.")` :68).
    The OV-1 precedent made the same two edits (fork/overload/plan.md:201,
    commit 495b58274). Because `Decl` is the "at most one of" group,
    `template abstract constraint X {}` is diagnosed `ModifierNotAllowedWith`
    by `HandleModifier` (:76-78) before any declaration-specific limit runs —
    acceptable, pinned in §4.A (amended 2026-10-06, review fold: A4 / B1).
    handle_named_constraint.cpp:53 (re-cited: A7 / B8) becomes
    `LimitModifiersOnDecl(context, introducer, KeywordModifierSet::Access |
    KeywordModifierSet::Template)` and `is_template =
    introducer.modifier_set.HasAnyOf(KeywordModifierSet::Template)`. Every
    other declaration rejects it through its existing `LimitModifiersOnDecl`
    call with `ModifierNotAllowedOnDeclaration` ("`template` not allowed on
    `fn` declaration") — zero new code on the rejection side; the acceptance
    side is the one set-constant edit above. This is the second branch of
    upstream's own TODO ("Or maybe it should be a modifier, like `abstract
    class`?", handle_named_constraint.cpp:44-45) and the OV-1 precedent. No
    conflict with the keyword's pattern uses: `TryHandleAsModifier` runs
    only at declaration start (handle_decl_scope_loop.cpp:333-341), and the
    binding-pattern consumers (§0.1 row 1) run inside parameter lists and
    after `let`. Break condition: upstream parses `template constraint` as a
    two-token introducer — a parse-only respelling; SemIR and check are
    unchanged.
-   **D-SC-2 — requirement forms in SC-1: `fn` DECLARATIONS only.** Methods
    (`self`, `ref self`, `addr self: Self*`) and associated functions (no
    `self`) are structural requirements. Everything else in a template
    constraint body keeps `require … impls` and `alias` semantics unchanged and
    is otherwise `context.TODO`: a `fn` with a body ("function definition in
    `template constraint`"), `var` members ("field requirement in `template
    constraint`"), `let` members ("associated constant requirement in `template
    constraint`"), and a requirement `fn` with its own compile-time bindings
    ("parameterized requirement in `template constraint`" — sub-fork F-010l, the
    stranded page :236-237 recommends deferring past 0.1; such a `fn` is also
    NOT collected into `structural_members_id`, §1.A.3). DISCLOSURE (amended
    2026-10-06, review fold: B3): deferring `var` field requirements REVERSES
    the recorded F-010b recommendation ("keep them, per proposal 2200" —
    stranded page :245-248 and :798-800; p002200:352-354 admits "function and
    field declarations"; the design record's Option B sketch :317 carries `var
    count: i32;`), which R29(a) would otherwise auto-adopt. Reason: a field
    match needs its own type-equality path (`FieldDecl`, not the D-SC-5(d)
    function matcher), nothing in the conformance arbiter needs it, and SC-B2's
    validity blocks are the natural second consumer; veto-able after the fact;
    residue filed (§1.G), and the §8.5 landing note repeats this paragraph.
    Deferring associated-constant requirements (`let X: type;`) NARROWS the
    landed p000818 text itself (details.md:1073-1075 enumerates "Method,
    associated constant, and associated function requirements"), on an
    implementation-cost ground: the interface form routes through
    `AssociatedConstantIntroducer` in `InterfaceContext` only
    (handle_decl_scope_loop.cpp:160-162), so there is no parse for it in a
    constraint body today and a `let X: type;` there is a plain `let` without
    initializer (§4.A); also veto-able, residue filed. Break condition: owner
    veto, or SC-B2 needing fields for its validity blocks — then fields land
    with B2 under the same matcher (D-SC-5) with `FieldDecl` type equality.
-   **D-SC-3 — WHERE satisfaction is evaluated: inside `LookupImplWitness`, and
    nowhere else.** Its callers at this cut (amended 2026-10-06, review fold: A6
    — there is no `impls` EXPRESSION; `impls` exists only in `require impls` /
    `where … impls`, parse/node_kind.def:400, token_kind.def:211):
    convert.cpp:1955 (the facet-conversion chokepoint, reached for a concrete
    type at a call site from deduce.cpp:343-346 — `ConvertToValueOfType` /
    `TryConvertToValueOfType` by `diagnose_`; the :567-571 twin runs only when
    the binding's own type is symbolic), impl.cpp:885 and :943
    (`CheckRequireDeclsSatisfied`, the `require` entry point — D-SC-19),
    custom_witness.cpp:175, handle_index.cpp:98, handle_question.cpp:278,
    member_access.cpp:277/:743 and cpp/thunk.cpp:1253 (all with a Core interface
    as target, so a template constraint never reaches them). A
    template-DEPENDENT argument never reaches the conversion chokepoint early:
    the enclosing call is a `CallAction` (call.cpp:765, :886) or the conversion
    a `ConvertAction` (convert.cpp:2312, :2418), both parked in the eval block
    and replayed by `PerformDelayedAction` at instantiation with concrete
    operands (eval.cpp:3150-3163; §0.1 row 12), where the replay calls
    `PerformCallHelper` → deduce → convert → the same chokepoint. So the
    structural check composes with upstream's template mechanism by construction
    and does not fight it; the design record's extra action kind (§0.2 item 3)
    is retired. The ONE eager entry point that does deliver a template-phase
    self is the `require` check (impl.cpp:834-960 is not an action); D-SC-19
    decides it (amended 2026-10-06, review fold: A3). Break condition: a §4
    golden shows a dependent shape reaching the CONVERSION chokepoint
    (convert.cpp:1955) with a still-symbolic template self (a `[template]`-phase
    `symbolic_binding` as `query_self`) — then D-SC-19's deferred rule already
    covers it (the structural part reads as satisfied-for-now and the conversion
    stays an action), and the finding is recorded as a second deferred site, not
    a new action kind.
-   **D-SC-4 — witness representation: NO witness table and NO new inst
    kind.** Satisfaction of structural requirements is a boolean check
    inside `LookupImplWitness`; the resulting `FacetValue` carries only the
    interface witnesses its `IdentifiedFacetType` lists (`InstBlockId::Empty`
    for a pure template constraint — today's shape for `constraint E {}`,
    §0.1 row 10), so lowering is untouched (§0.1 row 14). The "structural
    witness" of F-010 is the type's own member set: `x.(HasGet.Get)`
    resolves by converting the base type to the constraint's facet type
    (the check) and then performing MEMBER LOOKUP of the requirement's
    name in the base type, the semantics p002200:385-399 states. The
    fork's synthesized-witness precedent (`BuildCustomWitness`,
    check/custom_witness.cpp:1297; cpp/impl_lookup.cpp) is for
    INTERFACES — it needs a `SpecificInterface` and a witness index, and a
    template constraint has neither. Break condition: a consumer that needs
    a table appears — SC-B3's concept export, or a blanket `impl forall
    [template T: HasF] T as NewF` wanting `T.(HasF.F)` as a constant — then
    a `CustomWitness` keyed on the constraint is added at that point, and
    D-SC-4's FacetValue shape is unchanged (the table would hang off the
    IdentifiedFacetType, not the witnesses block).
-   **D-SC-5 — the satisfaction algorithm (new
    toolchain/check/structural_conformance.{h,cpp}).** For each structural
    requirement `{self_const_id, SpecificNamedConstraint}` of the identified
    facet type (D-SC-15), for each requirement `fn` in the constraint's
    `structural_members_id` block, in declaration order:
    (a) the self type must be concrete and COMPLETE (`RequireCompleteType`
    with a context note when `diagnose`, `TryToCompleteType` when not —
    R-7; sub-fork F-010h resolved as the stranded page recommends —
    incomplete is unsatisfied, diagnosed when `diagnose`), and the
    constraint's own `structural_members_id` must not be `InstBlockId::None`
    (a constraint still being defined, which `IdentifyFacetType` admits under
    `allow_partially_identified`, type_completion.cpp:1090-1095, has no
    members block yet — treated as incomplete → unsatisfied; the chokepoint
    itself identifies with `allow_partially_identified = false`,
    :1269-1270, so this is belt-and-braces; amended 2026-10-06, review fold:
    A11);
    (b) member lookup of the requirement's name IN THE TYPE through the
    member-access lookup path (`LookupMemberNameInScope`,
    member_access.cpp:320-406, exposed through a thin wrapper in
    member_access.h), with `required = false`, `lookup_in_type_of_base =
    false`, and the conversion's `loc_id` passed through
    `context.insts().GetLocIdForDesugaring(loc_id)` so the `NameRef` the
    lookup builds with `GetOrAddInst` (:378-382; inst.h:71-74 skips the
    block add only for desugared locations) does not land as an extra inst
    in the caller's block — the impl_lookup.cpp:1061 idiom (amended
    2026-10-06, review fold: A5(i)). ACCESS IS CHECKED (decision, amended
    2026-10-06, review fold: A1): `LookupQualifiedName` emits
    `ClassInvalidMemberAccess` whenever `prohibited_accesses` is non-empty
    and nothing else is found (name_lookup.cpp:562-578 — `required = false`
    does NOT silence it), and `LookupMemberNameInScope` always builds its own
    `AccessInfo` (:327-333), so the exposed wrapper
    (`LookupMemberNameInTypeScopes`, §2.B.4) takes
    `std::optional<AccessInfo>` plus a `diagnose` flag: it calls
    `LookupQualifiedName` with `access_info = nullopt` (no tracking, so a
    private member IS found), then applies `IsAccessProhibited`
    (name_lookup.cpp:250-273, made non-static) to the result's
    `access_kind()` against the caller's `AccessInfo`
    (`GetHighestAllowedAccess` from the current scope, member_access.cpp
    :327-331 — a private `Get` satisfies from inside `C`'s own scope, not
    from outside). Check mode (`diagnose = false`) records "prohibited" as
    unsatisfied and emits nothing; explain mode adds the note
    `StructuralMemberInaccessible` (D-SC-9) — the existing kind is
    Error-severity (name_lookup.cpp:237-240), so it cannot be attached as a
    note and a Note kind carrying its text is added instead. So an `alias F =
    A.F` in the class resolves through impl lookup to the impl's function
    (p002200's class `D`), an external `impl C as A` does NOT satisfy
    (p002200:361-377: lookup in `C` finds nothing), a private member does
    not satisfy from outside, and a C++ class's methods are imported on
    demand exactly as for `p->Get()`;
    (c) the found member must resolve to ONE function: the predicate is
    `SemIR::GetCallee(member_id)` yielding `CalleeFunction`
    (sem_ir/function.h:440-465; the `PerformInstanceBinding` read,
    member_access.cpp:415-416) — not "is a `FunctionDecl` inst", because
    the alias / `extend impl` case returns an `ImplWitnessAccess` or
    `SpecificConstant` whose CONSTANT is the impl's function
    (member_access.cpp:390-402; `ScopeNeedsImplLookup` :168-189 is true for
    a class). `CalleeOverloadSet`, `CalleeCppOverloadSet`,
    `CalleeCppFunctionPointer`, `CalleeNonFunction` (a field, a class, a
    namespace) and `CalleeError` are mismatches (amended 2026-10-06, review
    fold: A10);
    (d) signature match = `MakeSpecificWithInnerSelf(constraint.generic_id,
    constraint.generic_with_self_id, requirement.specific_id, self)`
    (generic.h:161) → `GetSelfSpecificForInterfaceMemberWithSelfType(…,
    function.generic_id, SpecificId::None)` (interface.cpp:59) →
    `CheckFunctionTypeMatches(member_fn, requirement_fn, that specific,
    /*check_syntax=*/false, /*diagnose=*/false)` — byte-for-byte the
    thunk.cpp:462-468 criterion (§0.1 row 15), so `self` form, parameter
    count, parameter types after `Self := C`, and return type must agree
    and parameter NAMES need not. No thunks are built: a near-miss is a
    mismatch, not an adaptation (the ladder step that adapts is the blanket
    impl, p002200:580-610).
    Rationale for (b) over a raw `LookupNameInExactScope`: p002200's alias
    example requires impl lookup through the alias, and the C++ case
    requires the Cpp-scope import hook; both live only on the member-access
    path. Break condition: `CheckFunctionTypeMatches` proves too strict for
    a shape the §4 matrix predicts positive (the likely one: a `ref self`
    requirement against an imported `const` method whose `self` type
    carries `const`) — then the matcher gains ONE documented relaxation
    (qualifier-tolerant `self`) and the golden split moves, never a thunk.
-   **D-SC-6 — a SYMBOLIC (checked-phase) self.** A structural requirement
    against a checked-symbolic self is satisfied iff the self facet value's
    own facet type already lists the same structural requirement (same
    `SpecificNamedConstraint`, same self). `T: HasGet` converting to itself
    takes the existing shortcut (convert.cpp:1945-1948) before any lookup.
    Reachability of the positive branch (amended 2026-10-06, review fold:
    B7): D-SC-8(i) rejects every checked binding whose facet type mentions a
    template constraint but keeps the pattern's type, so the ONLY input that
    reaches this branch is the error-recovery path after that diagnostic —
    `fn Bad[T: HasGet & I](x: T) -> i32 { return CallGet(x); }` (the `&`
    makes the facet types differ, so the shortcut does not fire). The branch
    is kept as a CASCADE GUARD with that one-sentence purpose (R17) and is
    pinned by §4.B `fail_implicit_binding_compound_use.carbon`: exactly one
    diagnostic, at the binding. Otherwise a checked-symbolic self is
    unsatisfied: a checked-generic `U: type` passed to `template T: HasGet`
    fails at the checked function's DEFINITION with
    `ConversionFailureTypeToFacet` plus the note
    `StructuralRequirementNeedsConcreteType` — the conservative answer to
    leads issue 2153 that F-010 already adopted. The interface-`require`
    forwarding case `interface I { require impls HasGet; } fn G[T: I](x: T)
    { CallGet(x); }` is REJECTED in SC-1 (`ConversionFailureFacetToFacet` +
    the same note; §4.B `fail_require_in_interface_symbolic.carbon`): D-SC-15
    fills `structural_requirements()` from `IdentifyFacetType`'s three
    named-constraint loops only, never from an interface's
    `require_impls_block_id`, and this mirrors upstream's own nominal
    behavior — check/testdata/interface/require.carbon
    `fail_todo_implicit_self_impls` (:79-98) still cannot do impl lookup for
    `Y` on `T: Z` when `Z` requires `Y` ("the identified facet type doesn't
    include `Y`"), so forwarding structural requirements through an
    interface's `require` would run ahead of upstream's nominal rule; residue
    filed (§1.G). A TEMPLATE-phase self reaches the check only through the
    `require` entry point and is deferred there (D-SC-19). Break condition:
    upstream resolves issue 2153 toward "checked generics may call
    templates", or lands the interface/require.carbon TODO — then the
    symbolic case becomes a deferred `LookupImplWitness`-style query instead
    of an error, and the interface-forwarding residue is picked up with it.
-   **D-SC-7 — completeness and caching.** Completeness per D-SC-5(a). No
    satisfaction cache in SC-1: the check is linear in the constraint's
    requirement count and runs once per conversion site; the impl-lookup
    cache (`impl_lookup_cache`, keyed by `(self, SpecificInterfaceId)`) does
    not apply and is not extended. Break condition: a measured compile-time
    regression on the gate — then a `(IdentifiedFacetTypeId, self
    ConstantId) → bool` map on `Context`, cleared with the impl-lookup
    cache.
-   **D-SC-8 — template bindings only; the other entry points.** (i) A
    NON-template compile-time binding (`generic T: HasGet`, an implicit
    `[T: HasGet]`, an interface or constraint parameter) whose facet type
    transitively mentions a template constraint diagnoses
    `TemplateConstraintOnNonTemplateBinding` at the binding
    (handle_binding_pattern.cpp:313-349, where `is_template` is known),
    using `FacetTypeHasStructuralRequirements` (a DFS over
    `DeclaredFacetType` named constraints and their complete
    `require_impls` blocks, reading only `is_template` — never
    `structural_members_id`, which is `None` on a being-defined constraint
    (A11); incomplete constraints are skipped there and caught at use; the
    implementer MAY instead reuse `TryToIdentifyFacetType(…,
    allow_partially_identified = true)` with the binding as self and test
    `structural_requirements()` non-empty, which is the same walk —
    handle_where.cpp:96 and impl.cpp:864 already call it at
    declaration-ish points; review A Angle 5's reuse suggestion, accepted
    as an option, 2026-10-06). (ii) `impl C as HasGet` is ALREADY an error:
    identification yields no impl-as interface and impl.cpp:1025-1030
    emits `ImplOfNotOneInterface` "impl as 0 interfaces, expected 1" —
    sub-fork F-010m resolved as "error" by pinning (§4.B
    `fail_impl_as_template_constraint`). (iii) `require impls HasGet` inside
    an interface or plain constraint stays legal: a concrete implementer is
    checked at the chokepoint when `CheckRequireDeclsSatisfied` runs
    (impl.cpp:834) and a blanket `impl forall` is rejected by D-SC-6 — the
    natural meaning, pinned by `template_constraint_require.carbon`; a
    TEMPLATE blanket `impl forall
    [template T: type] T as I {}` is deferred, not rejected (D-SC-19). Break
    condition for (i): upstream's issue 2153 resolution (as D-SC-6).
-   **D-SC-9 — diagnostics: EIGHT new kinds (heading corrected from "six",
    body from seven — amended 2026-10-06, review fold: B4 / A1), notes
    attached to the EXISTING conversion error.**
    `DiagnoseConversionFailureToConstraintValue`
    (convert.cpp:1503-1527) switches from `Emit` to `Build` + notes +
    `Emit`, and `NoteStructuralConformanceFailure` (structural_conformance.h)
    re-runs the check in explain mode to add, for the FIRST unsatisfied
    requirement in declaration order (the stranded page's rule, :566-579):
    `StructuralMemberMissing` (Note, "type {0} has no member named `{1}`
    required by template constraint `{2}`"),
    `StructuralMemberMismatch` (Note, "member `{1}` of type {0} does not
    match the signature required by template constraint `{2}`"),
    `StructuralRequirementHere` (Note, "requirement declared here", at the
    requirement `fn`), `StructuralMemberInaccessible` (Note, "member `{1}`
    of type {0} is {2:private|protected} here and cannot satisfy template
    constraint `{3}`" — D-SC-5(b), A1; the text mirrors
    `ClassInvalidMemberAccess`, name_lookup.cpp:237-240, which is
    Error-severity and so cannot itself be a note),
    `StructuralRequirementNeedsConcreteType` (Note,
    "template constraint `{0}` can only be satisfied by a concrete type;
    {1} is a checked generic binding" — D-SC-6). Errors:
    `TemplateConstraintOnNonTemplateBinding` ("template constraint `{0}`
    can only constrain a `template` binding" — D-SC-8),
    `FunctionInNonTemplateConstraint` ("function declaration in a
    non-`template` `constraint`; use `template constraint` to declare a
    structural requirement" — §0.1 row 7's TODO retired),
    `NamedConstraintRedeclTemplateMismatch` ("redeclarations of `constraint
    {0}` must match use of `template`", with the existing `RedeclPrevDecl`
    note — the `RedeclExternMismatch` shape, merge.cpp:45-57; D-SC-16).
    That is 8 kinds (9 if R-6's completeness context note is counted), each
    covered by a §4 golden (coverage_test). The deferred forms of D-SC-2 use
    `context.TODO` (`SemanticsTodo`, no kind). impl.cpp's two `require`
    emits (`IdentifiedRequireImplsNotImplemented` :891-904 for the identified
    facet type's requirements, `InterfaceRequireImplsNotImplemented` :946-956
    for the interface's own `require` block) stay `Emit` with NO structural
    note in SC-1 — the notes are wired only into convert.cpp:1503-1527
    (amended 2026-10-06, review fold: A5(ii)). Break condition: a reviewer
    finds an existing kind whose text already fits — then that kind is reused
    and the count drops.
-   **D-SC-10 — `Self` inside a template constraint is a TEMPLATE-phase
    binding.** `is_template = true` flows into
    `AddSelfSymbolicBindingToScope` (handle_named_constraint.cpp:134-136),
    exactly the hook upstream left for it (§0.1 row 5), so a requirement's
    `self` and `Self`-typed parameters carry `[template]` phase like `x: T`
    for `template T`. Nothing in SC-1 depends on the phase (signatures are
    matched through specifics, which substitute either phase); SC-B2's
    validity blocks will need it. Break condition: the commit-1 fill shows
    a template-phase `Self` breaking a positive §4.A golden (a
    `<dependent type>` or `type_of_inst` in a requirement's parameter
    pattern, or a `CARBON_CHECK` in `CheckRedeclParams`) — then SC-1 passes
    `false` and files the flip as an SC-B2 prerequisite.
-   **D-SC-11 — C++ interop is IN scope at the structural level, with one
    spelling rule.** A C++ class satisfies a template constraint through its
    imported methods under D-SC-5 unchanged; because imported methods are
    `ref self` (§0.1 row 19), a constraint meant to be satisfied by C++
    classes spells its methods `fn Get(ref self) -> i32`, which Carbon
    classes satisfy with `fn Get(ref self) -> i32` (the working spelling,
    check/testdata/class/method/method.carbon:17). Overloaded C++ methods
    (`CppOverloadSetValue`) and C++ `static` members never satisfy a method
    requirement (D-SC-5(c)). Deliverables: the check golden
    interop/cpp/class/import/template_constraint.carbon and the conformance
    program interop/cpp_structural_conformance.carbon (§5), both predicted
    positive for a NON-`const` method called through `T*`. The `const`-method
    split is predicted but flagged (D-SC-5's break condition). Break
    condition: the commit-3 fill shows the imported `self` pattern cannot
    match any Carbon spelling — then the conformance program lands SKIP
    citing the exact diagnostic (a NEW program may start SKIP; R16(b) is
    about previously-passing ones) and the residue "C++ method `self`
    qualifiers in structural matching" is filed.
-   **D-SC-12 — interactions decided: none need code.** Overload sets: a
    `template T: HasGet` member of an `overload fn` set is probed with
    `diagnose = false` (fork/overload/plan.md D-OV-4), which reaches
    `LookupImplWitness(…, diagnose=false)`; the structural check honors the
    flag (no emission), so first-match resolution is unchanged and an
    unsatisfied structural member is simply skipped — pinned by
    `template_constraint_overload.carbon`. The probe path for a GENERIC
    member is D-OV-4 step 2(d) (non-diagnosing `DeduceGenericCallArguments`
    inside the discard scope), landed with OV-2 and golden-backed for a
    facet-constrained checked member by
    check/testdata/function/overload/generic.carbon `fail_deduce_all` (both
    members rejected by deduction, "nothing is diagnosed by the probes
    themselves"); a `[template T: HasGet]` member is the same deduce →
    convert → `LookupImplWitness(diagnose = false)` path with Template
    phase, and D-OV-6 gate (xi) concerns template-dependent ARGUMENTS only
    (bypassed since UA-1, fail_todo_gates.carbon:20-23). This is also what
    makes the §5 conformance programs non-vacuous (D-SC-14; verified
    2026-10-06, review fold: B2). `?`: no interaction (a
    `Core.Result` return through a template-constrained function is an
    ordinary type). Choice and union types: both are name scopes; a union
    class's methods can satisfy a requirement, a choice type has no `fn`
    members and is unsatisfied — no special case. Imported Carbon
    constraints across libraries: D-SC-15's import path. Break condition:
    the overload golden shows a probe emitting a structural note — a
    `diagnose` leak, fixed at the check's emit sites.
-   **D-SC-13 — docs: port the stranded F-010 page, amended for SC-1.**
    docs/design/generics/template_constraints.md (862 lines at 481e08c24)
    lands with a status paragraph ("fork amendment 2026-10-07 (F-010 /
    SC-1): member requirements implemented; validity blocks, predicates
    and concept mapping are SC-B2/SC-B3"), the §Structural witnesses
    section rewritten per D-SC-4, the §Dependencies list corrected per
    §0.2 item 8, and each of F-010b/h/l/m marked with its SC-1 resolution
    (D-SC-2, D-SC-5(a), D-SC-2, D-SC-8); F-010a/c/d/e/f/g/i/j/k stay OPEN
    for SC-B2/SC-B3. The §Completeness and caching paragraph (stranded
    :544-548, "Satisfaction results are cached and reused … checked at most
    once per compilation") is amended to D-SC-7 (no cache in SC-1; the
    answer is still coherent because it is computed only from a complete
    type) — R27's doc-vs-code spelling rule (amended 2026-10-06, review
    fold: B10). The four sibling hunks (generics/README.md link,
    details.md cross-reference, terminology.md, templates.md :100-111
    replaced by a dated paragraph linking the page) are re-read against
    trunk before porting (details.md moved under UA-1). Correction (B10):
    `git show 481e08c24 -- docs/design/generics/details.md` is purely
    ADDITIVE — two hunks, `@@ -1061,7 +1061,11 @@` (the cross-reference,
    taken) and `@@ -6873,6 +6877,11 @@` (boolean predicates under "Value
    constraints for template parameters", now near :7131; deferred to SC-B2
    on purpose, since it documents `require <bool-expr>`); trunk's §Rewrites
    and same-type constraints (:1131) and §Constraints that don't depend on
    `.Self` (:1141) are at risk only if the stranded FILE were copied over
    trunk's, which the hunk-wise port never does — rev 1's "the stranded
    diff also deletes trunk sections" was wrong and is withdrawn. The same
    commit repairs the design record's manufactured R31 heading at
    fork/design-sprint/structural-conformance.md:450 ("## 2153 'predicates'
    direction, but shipping _only_ this leaves the accepted", a 119b35439
    reflow artifact: the H2 is rejoined to its paragraph at :448-452) with
    the R31(b) count diff recorded in the commit message. Break condition:
    none; docs follow the implementation.
-   **D-SC-14 — the conformance program is rewritten in F-010's shape
    (template constraint, not interface), un-SKIPped in commit 2, no
    `.diff.cpp`, and its printed value DEPENDS on the satisfaction check.**
    Exact text in §5.A. Shape (amended 2026-10-06, review fold: B2): rev 1's
    `CallGet(s)` was vacuous with respect to satisfaction — after commit 1
    alone, impl_lookup.cpp:1017-1019 returns `InstBlockId::Empty` for a facet
    type with no interfaces, so `template T: HasGet` accepted EVERY type and
    the program printed 42 whether or not the check existed (the arbiter
    then measured only W-014's "a template method call lowers"). The runner
    cannot express a negative program (runner.py:138-144 knows
    `EXPECT-EXIT`/`EXPECT-STDOUT` only; COMPILE-FAIL is a status, :95), so
    the fix is in-harness: an `overload fn Pick` set whose member 1 is
    `[template T: HasGet]` and member 2 `[template T: type]`, called with a
    satisfying class (prints 42) and a `Lacking` class with no `Get` (prints
    7). Under declaration-order first-match (F-009, fork/overload/plan.md
    D-OV-4 step 2(d)) a silently-ignored constraint selects member 1 for
    `Lacking`, `x.Get()` then fails at instantiation and the program is
    COMPILE-FAIL; a check that rejects everything prints `7\n7`
    (OUTPUT-MISMATCH); a `diagnose` leak is COMPILE-FAIL; only a correct
    check prints `42\n7`. The §4.B `template_constraint_overload.carbon`
    golden fills in the same commit, before the conformance run, so the
    template-member probe path is golden-pinned first. Order of shapes
    (amended 2026-10-06, review fold: B5 / A8): the VALUE shape (`x: T`,
    `x.Get()`) is tried first — the mechanism is proven by
    lower/testdata/template/merging.carbon:49 `InitAndCallF` (`({} as
    T).F()`, a dependent instance-method call through an
    `AccessMemberAction` on a value of type `T`, lowered at :241-272) and
    :58-60 `CallBF` (`x.(B.F)()`, :278-300); the POINTER shape (`p: T*`,
    `p->Get()`) is the fallback IF the value shape fails to lower, and is
    what the C++ program uses anyway (D-SC-11). R30 does not apply (no
    documented divergence; both sides agree) and the README's differential
    preference (fork/conformance/README.md:396-399) is for "already-working
    behavior with a natural C++ counterpart" — a C++20 concept oracle would
    test Clang, not the fork. The second program (D-SC-11) sits under the
    SAME bullet (the C++ class is the argument, not a concept mapping) and
    takes the same two-member shape with a `Plain` C++ struct lacking `Get`.
    Break condition (added 2026-10-06, review fold: B11): the SC-1b
    conformance run prints `42\n7` while the §4.B
    `fail_template_constraint_unsatisfied` goldens fill POSITIVE — a check
    that passes the arbiter without rejecting anything — then the arbiter
    is wrong, not the goldens: stop, and re-derive the program's falsifier
    before any un-SKIP.
-   **D-SC-15 — storage: two fields on `NamedConstraint`, one vector on
    `IdentifiedFacetType`.** `bool is_template` (set at the declaration,
    checked on redeclaration — D-SC-16) and `InstBlockId
    structural_members_id` (the requirement `FunctionDecl` inst ids in
    declaration order, collected at `}` by scanning
    `body_block_with_self_id` for `FunctionDecl` insts — no new collector
    stack; `require_impls_block_id` is set at the same point,
    handle_named_constraint.cpp:189-194). `Print` prints both only when
    non-default (the `Function::Print` pattern, sem_ir/function.h:244-290),
    so the two raw_sem_ir goldens that print named constraints stay
    byte-identical (§6; "two", not "three" — amended 2026-10-06, review
    fold: B9). Import (amended 2026-10-06, review fold: A2): `is_template` is
    copied in the first-phase entity creation (`ImportNamedConstraintDecl`,
    import_ref.cpp:3696-3799, beside the existing `require_impls_block_id`
    import at :3754-3755 — re-cited, B8); the members block is imported in
    the `NamedConstraintWithSelfDecl` resolver (:3801-3918), NOT in
    `TryResolveTypedInst(NamedConstraintDecl)` or
    `ImportNamedConstraintDefinition` (:3675-3694), because only the
    with-self resolver owns `scope_with_self_id`'s import-refs and
    `body_block_with_self_id` (`InitializeNameScopeAndImportRefs` on the
    with-self scope :3907-3910, `body_block_with_self_id = Pop()`
    :3912-3913) — the exact analogue of the interface resolver's
    `AddAssociatedEntities` call (:3620-3622, inside its pushed block). The
    requirement import-refs are built there, after :3910 and before the
    `Pop()`, with the `AddAssociatedEntities` block idiom (:1519-1540).
    `IdentifiedFacetType` gains `struct StructuralRequirement
    {ConstantId self_facet_value; SpecificNamedConstraint constraint;}`,
    a vector filled by `IdentifyFacetType`'s three named-constraint loops
    (type_completion.cpp:1072-1245) whenever `constraint.is_template`, and
    `structural_requirements()`; the store stays keyed by
    `IdentifiedFacetTypeKey` (no hashing change). Break condition: a
    reviewer shows a template constraint reached ONLY through `type_impls`
    (`C impls HasGet` inside another constraint) needs the type's own self
    — it does, and the loop at :1185-1245 already has it
    (`self_type_inst_id`).
-   **D-SC-16 — redeclarations must agree on `template`.** A forward
    declaration and definition (or two declarations) of one constraint with
    different `template` presence diagnose
    `NamedConstraintRedeclTemplateMismatch` + `RedeclPrevDecl` in
    `BuildNamedConstraintDecl` after `TryMergeRedecl` succeeds
    (handle_named_constraint.cpp:69-83). details.md:5495 lists `template
    constraint` as the redeclaration's introducer text. Break condition:
    none.
-   **D-SC-17 — gap row 55 moves MISSING → PARTIAL, not DONE.** The bullet
    reads "both modeling the members (like interfaces) and arbitrary
    predicates (like C++20 expression validity predicates)"; SC-1 delivers
    the first half MINUS the four deferred member forms, which the row text
    names (fields, associated constants, parameterized requirements, default
    definitions — §8.5; amended 2026-10-06, review fold: B3). Header
    30/21/4/1 → 30/22/3/1. DONE waits for SC-B2. Break condition (added
    2026-10-06, review fold: B11): the SC-1c discharge finds the row's
    "remaining" list disagrees with §1.G's residue titles — then the row is
    rewritten from §1.G, never the reverse; a reviewer showing a landed
    deferred form moves the row toward DONE only through SC-B2's plan.
-   **D-SC-18 — `FunctionInNonTemplateConstraint` is an ERROR, not a TODO,
    and `var`/`let` in a plain constraint stay as they are.** A `fn` in a
    plain `constraint` would otherwise look structural and check nothing —
    the silent-wrong shape R15 forbids — and it sits on the one code path
    SC-1 edits (handle_function.cpp:555-575). The `var`/`let`-in-plain-
    constraint TODOs (invalid_members.carbon splits `todo_fail_invalid_var`,
    `todo_fail_invalid_let`) are upstream's and untouched. Break condition:
    none.
-   **D-SC-19 — a TEMPLATE-phase self at the `require` entry point is
    DEFERRED: structurally satisfied for now, checked at monomorphization
    (added 2026-10-06, review fold: A3).** `CheckRequireDeclsSatisfied`
    (impl.cpp:834-960) calls `LookupImplWitness` EAGERLY with the impl's
    self (:885-889 for the identified facet type's requirements, :943-944
    for the interface's own `require` block); it is not an action, so for
    `interface I { require impls HasGet; } impl forall [template T: type] T
    as I {}` the structural check receives a `[template]`-phase
    `symbolic_binding` as `query_self` — the one place rev 1's "a
    template-phase self never reaches the check" was false. Rule: when
    `constant_values().GetDependence(self) == ConstantDependence::Template`
    (sem_ir/constant.h), `CheckStructuralRequirements` returns true without
    lookup (helper `SelfIsTemplatePhase`, §2.B.3) and the structural part of
    the query reads as `InstBlockId::Empty` — the blanket impl is accepted,
    exactly as its body is accepted before instantiation. What IS checked at
    monomorphization: every use of a structural member inside the impl
    (`fn DoF(self) { self.Get(); }` in p002200:605-610's ladder step `impl
    forall [template T: HasGet] T as NewF`) is a template-dependent
    `AccessMemberAction`/`CallAction` replayed with the concrete self, and
    every concrete caller's conversion to `HasGet` runs the full check. What
    is NOT re-run in SC-1: the bare `require impls HasGet` clause itself for
    the specific `C as I` resolved through the template blanket impl —
    upstream runs `CheckRequireDeclsSatisfied` once at the impl declaration
    and never per specific, so an empty-bodied template blanket impl of `I`
    is accepted for a `C` lacking `Get` with no diagnostic; pinned as the
    current behavior by §4.B `require_in_interface_template_blanket.carbon`
    and filed as the residue "re-run deferred structural `require` checks
    at template blanket-impl specifics" (§1.G). Unverified premise (R-11):
    no golden in tree uses `impl forall [template` at all, so the binding
    form in an impl is itself a probe — §4.B
    `template_constraint_impl_forall_template.carbon`. Checked-phase blanket
    impls (`[T: type]`) stay REJECTED by D-SC-6. Break condition: the
    positive golden shows impl deduction or `EvalLookupSingleFinalWitness`
    cannot instantiate a template-phase blanket impl — then the split moves
    to `fail_todo_`, the ladder step is filed as a residue, and D-SC-19's
    rule stands for the `require` entry point alone.

### §0.4 The split decision: one PR, three commits

R29(b) sizes a PR per milestone feature. SC-1 is one feature (member
requirements) with three internally verifiable layers — declaration,
satisfaction, interop+docs — each with its own goldens and a hosted fill
after it (§3). SC-B2 and SC-B3 are separate workstreams (W-028, W-029) and
their plans start when SC-1 is in review (R29(d)).

## §1 Design decisions

### §1.A Declaring a template constraint

```carbon
template constraint HasGet {
  fn Get(self) -> i32;            // method requirement (value self)
  fn Make() -> Self;              // associated-function requirement
  require impls Core.Destroy;     // nominal requirements still compose
}
template constraint Forward;      // forward declaration; D-SC-16
```

1.  Parse (D-SC-1): `template` is a modifier leaf (`TemplateModifier`)
    before `NamedConstraintIntroducer`; `NamedConstraintSignature.modifiers`
    carries it. The body is unchanged (`DeclScopeLoopAsRegular`).
2.  Check, declaration (D-SC-1, D-SC-15, D-SC-16): `BuildNamedConstraintDecl`
    limits modifiers to `Access | Template`, sets `constraint_info.is_template`
    on a new entity, and on a merged redeclaration compares the flag
    (`NamedConstraintRedeclTemplateMismatch`). `is_template` replaces the
    hard-coded `false` at :114 and reaches the `Self` binding (D-SC-10).
3.  Check, members (D-SC-2, D-SC-18): in `MaybeAddToNameLookup`
    (handle_function.cpp:555-575) a `NamedConstraintWithSelfDecl` parent
    scope is recognized beside the interface case: if the constraint is not
    template → `FunctionInNonTemplateConstraint` (the declaration is still
    added so later lookups do not cascade); if template → the declaration is
    a requirement (nothing else to do here; the block is collected at `}`).
    A definition (`is_definition`) in a template constraint →
    `context.TODO("function definition in `template constraint`")`. A
    requirement with implicit or explicit compile-time bindings of its own
    (`function.generic_id` has parameters beyond the enclosing with-self
    generic's) → `context.TODO("parameterized requirement in `template
    constraint`")` AND is not collected into `structural_members_id` at `}`
    (the `}` scan skips a `FunctionDecl` whose generic has its own
    parameters) — otherwise `GetSelfSpecificForInterfaceMemberWithSelfType`'s
    `index_delta = -1` adjustment (interface.cpp:80-101) would trip
    `CARBON_CHECK(bind_index_value >= 0)` (:94) at match time; the
    adjustment loop is empty only for an unparameterized requirement
    (amended 2026-10-06, review fold: A12). `var`/`let` with a
    `NamedConstraintWithSelfDecl` current scope in `HandleIntroducer`
    (handle_let_and_var.cpp:67-81) when the constraint is template →
    `context.TODO("field requirement in `template constraint`")` for `var`
    and `context.TODO("associated constant requirement in `template
    constraint`")` for `let` (D-SC-2).
4.  Check, `}` (D-SC-15): after `require_impls_block_id` is set
    (handle_named_constraint.cpp:189-194), `structural_members_id =
    inst_blocks().Add(FunctionDecl insts of body_block_with_self_id)` (or
    `InstBlockId::Empty`). `complete` semantics unchanged.
5.  Import (D-SC-15; amended 2026-10-06, review fold: A2):
    `TryResolveTypedInst(NamedConstraintDecl)` (import_ref.cpp:3696-3799)
    copies `is_template`; `TryResolveTypedInst(NamedConstraintWithSelfDecl)`
    (:3801-3918) imports `structural_members_id` as a block of import-refs
    inside its pushed with-self block (after :3910, before the `Pop()` at
    :3912-3913; `AddAssociatedEntities`-style, :1519-1540); `MergeDefinition`
    carries both. A template constraint declared in library `a` and used in `b`
    (§4.B `template_constraint_import.carbon`) then identifies and satisfies
    exactly as locally.

### §1.B Using a template constraint on a binding

`fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }`

1.  The binding (D-SC-8(i)): `HandleAnyBindingPattern` already knows
    `is_template` (:313-318) and `is_generic`; when `is_generic &&
    !is_template` and `FacetTypeHasStructuralRequirements(type_id)` →
    `TemplateConstraintOnNonTemplateBinding`, the pattern keeps its type
    (no cascade). A runtime binding of facet type is unaffected (it is a
    facet VALUE binding; the facet type's structural requirements apply when
    its initializer converts).
2.  The body: `x.Get()` is `access_member_action` + `splice_inst` exactly as
    today (§0.1 row 18); structural constraints do not alter lookup
    (p002200:379-399). At instantiation the action resolves in the concrete
    type. No change.
3.  Compound access `x.(HasGet.Get)()` (D-SC-4): in
    `PerformCompoundMemberAccessAction` (member_access.cpp:792-868), before
    `PerformInstanceBinding`, a member that is a `FunctionDecl` whose
    `parent_scope_id` is a TEMPLATE constraint's `scope_with_self_id`
    (`name_scopes().TryGetInstAs<NamedConstraintWithSelfDecl>` +
    `is_template`) is redirected: `ConvertToValueOfType(base_type as type →
    the constraint's facet type)` (the check, with the usual diagnostics),
    then `member_id = LookupMemberNameInScope(base, requirement name, …)`
    on the base type's scopes — the type's own member; instance binding
    proceeds on that. A template-dependent base defers through the existing
    `CompoundMemberAccessAction` (:870-883) and replays into the same code.

### §1.C Satisfaction at the chokepoint

```text
convert.cpp:1955  LookupImplWitness(query_self, target facet type, diagnose)
impl_lookup.cpp   GetIdentifiedFacetTypeForQuery (was GetRequiredImplsFromConstraint)
                  ├─ structural_requirements() non-empty?
                  │    ├─ SelfIsTemplatePhase(self)? → deferred (true; D-SC-19)
                  │    └─ CheckStructuralRequirements(…, diagnose)  ── false → InstBlockId::None
                  ├─ required_impls() empty? → InstBlockId::Empty
                  └─ interface loop (unchanged)
convert.cpp:1976  diagnose → DiagnoseConversionFailureToConstraintValue
                               Build(ConversionFailure*…) + NoteStructuralConformanceFailure + Emit
```

1.  `GetRequiredImplsFromConstraint` (impl_lookup.cpp:226-246) is widened to
    return the `IdentifiedFacetType*` (callers read `required_impls()`), so
    `LookupImplWitness` can read `structural_requirements()` before the
    `req_impls.empty()` early return at :1017-1019 (re-cited 2026-10-06).
2.  `CheckStructuralRequirements` (D-SC-5, D-SC-6, D-SC-7, D-SC-19) returns
    `true` at once for a template-phase self (deferred), and otherwise
    `false` for the first unsatisfied requirement; with `diagnose == false`
    it emits nothing (overload probing, deduction with `diagnose_ = false`;
    the access check is applied by `IsAccessProhibited` on the found
    result, never by `LookupQualifiedName`'s own emit — D-SC-5(b), A1). With
    `diagnose == true` it still emits nothing here — the error is the
    conversion's (D-SC-9) — EXCEPT completeness (`RequireCompleteType` emits
    its own `IncompleteType*` error with the structural context note, the
    way every other completeness requirement does).
3.  `NoteStructuralConformanceFailure` (explain mode) is pure diagnostics:
    it re-runs steps (a)-(d) and adds the first failing requirement's notes.
    `LookupImplWitness` keeps returning `InstBlockId::None` (not an error
    value) for an unsatisfied query, so `impls` expressions and
    `require` checks observe plain "not satisfied".
4.  `EvalLookupSingleFinalWitness` (:1182-1347) is untouched: it is the
    per-INTERFACE monomorphization path and no `LookupImplWitness` inst is
    created for a structural requirement (D-SC-4). The symbolic case that
    would otherwise need it is rejected up front (D-SC-6).

### §1.D What the implementation reuses (and what is new)

Reused: modifier x-macros (§0.1 rows 3-4), `MakeSpecificWithInnerSelf`,
`GetSelfSpecificForInterfaceMemberWithSelfType`, `CheckFunctionTypeMatches`
(check_syntax=false, diagnose=false), `LookupMemberNameInScope`,
`IsAccessProhibited` (made non-static, A1), `SemIR::GetCallee` (A10),
`RequireCompleteType`, `IdentifyFacetType`'s loops, the import-ref block
helpers, `RedeclPrevDecl`. New: structural_conformance.{h,cpp} (about 280
lines: `CheckStructuralRequirements`, `NoteStructuralConformanceFailure`,
`FacetTypeHasStructuralRequirements`, the five private helpers of §2.B.3),
two `NamedConstraint` fields, one `IdentifiedFacetType` vector, 8 diagnostic
kinds (9 with R-6), one parse node kind, one modifier-set x-macro entry plus
one set-constant edit (A4 / B1).

### §1.E Lowering impact: none (proof)

A satisfied conversion produces `FacetValue{type_inst_id, witnesses_block_id}`
where the block holds only interface witnesses (D-SC-4); `FacetValue` lowers
as its type (lower/constant.cpp:198-199) and is a no-op as an instruction
(lower/handle.cpp:220); witness blocks are never lowered (`is_lowered =
false`). The template body's member call lowers through `SpliceInst`
(lower/handle.cpp:495-513) with the dependent-method-call precedent
lower/testdata/template/merging.carbon:20/:49/:58. The compound-access
redirect (§1.B.3) produces an ordinary `bound_method` on the type's own
function. Hence no file under toolchain/lower/ changes; the §4.B lower golden
`lower/testdata/template/template_constraint.carbon` is the pin, and a
`CARBON_FATAL` or a missing `define` there is a plan miss (§7 R-1).

### §1.F Interactions (D-SC-11, D-SC-12)

Overload sets: probe path honors `diagnose = false`; first-match unchanged.
`?`, choice, union: no code. C++: a class's imported methods are candidates
through the Cpp-scope lookup hook; `ref self` spelling rule; overload sets
never satisfy. Cross-library: import of the two new fields.

### §1.G What SC-1 does NOT do (residue titles, filed at §8.5)

-   "SC-B2: `require (…) {…}` validity blocks and `require <bool-expr>`
    predicates" (W-028, already filed; blocked_by cleared).
-   "SC-B3: two-way C++20 concept mapping" (W-029, already filed; blocked_by
    cleared).
-   "field requirements in template constraints" (D-SC-2; F-010b).
-   "associated-constant requirements in template constraints" (D-SC-2).
-   "parameterized requirement functions" (D-SC-2; F-010l).
-   "function definitions (defaults) in template constraints" (D-SC-2).
-   "structural witness table for blanket impls over template constraints"
    (D-SC-4's break condition).
-   "checked generics calling template-constrained functions (leads issue
    2153)" (D-SC-6).
-   "forward structural requirements through an interface's `require impls`
    for checked bindings" (D-SC-6; waits on upstream's
    interface/require.carbon TODO; review fold B7).
-   "re-run deferred structural `require` checks at template blanket-impl
    specifics" (D-SC-19; review fold A3).
-   "`impl forall [template T: HasGet]` migration-ladder step" — ONLY if
    D-SC-19's break condition fires (R-11).
-   "`const` C++ method conformance sibling (`const_method` program)" — ONLY
    if §4.C `const_method.carbon` fills positive (D-SC-11; review fold B14).
-   "SemIR dump of a structural facet value hangs file_test" — ONLY if the
    W-121 pre-registration in §8.1 fires (review fold B12).
-   "C++ method `self` qualifiers in structural matching" — ONLY if
    D-SC-5's break condition fires.
-   "satisfaction cache" — ONLY if D-SC-7's break condition fires.

## §2 Implementation spec (file by file)

### §2.A Commit 1 — declaration side

1.  toolchain/parse/node_kind.def:
    `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER(Template)` between `Static` (:436)
    and `Virtual` (:437).
2.  toolchain/check/keyword_modifier_set.h: `X(Template)` between `Returned`
    and `Virtual` in the Decl group (:41-51) AND `| Template` appended to the
    explicit union `KeywordModifierSet::Decl` (:150-154) — without it the
    `CARBON_KEYWORD_MODIFIER_SET_IN_GROUP` static_assert (:170-176) stops the
    build and `HandleModifier` would hit its `CARBON_FATAL` (amended
    2026-10-06, review fold: A4 / B1; rev 1's "No set constant changes" was
    wrong). `Interface`, `Class`, `Method`, `MatchFirst`, `ImplDecl` stay as
    they are.
3.  toolchain/sem_ir/named_constraint.h: `bool is_template = false;` and
    `InstBlockId structural_members_id = InstBlockId::None;` in
    `NamedConstraintFields`; `Print` adds `, is_template: true` and `,
    structural_members_id: …` only when set; `MergeDefinition` copies
    `structural_members_id` (and asserts `is_template` equality — the check
    diagnosed it first).
4.  toolchain/check/handle_named_constraint.cpp (re-cited 2026-10-06, review
    fold: A7 / B8 — the fork's file differs from upstream's by the
    `TryMergeRedecl` unification, PR 7632): :53 limit → `Access |
    Template`; after `TryMergeRedecl` (:73-81) the D-SC-16 comparison; new
    entity sets `is_template`; :113-114 read the flag and pass it at
    :141-143; the `}` handler (:188-210) collects `structural_members_id`
    right after `require_impls_block_id` is set (:196-206). The two TODO
    comments (:44-45, :113) are deleted.
5.  toolchain/check/handle_function.cpp: `MaybeAddToNameLookup` (:552-575,
    called from `BuildFunctionDecl` at :1219): the
    `NamedConstraintWithSelfDecl` branch (§1.A.3) + the two `context.TODO`
    sites (definition, parameterized requirement) placed in
    `BuildFunctionDecl` (:1050-) where `is_definition` and
    `function_info.generic_id` are known — it reads
    `introducer.modifier_set` at :1097-1102 (re-cited 2026-10-06, review
    fold: B8; the :109-112 read is `HandleParseNode(FunctionIntroducer)`'s
    `Method` removal, a different function).
6.  toolchain/check/handle_let_and_var.cpp:67-81 `HandleIntroducer`: the
    field-requirement (`var`) and associated-constant-requirement (`let`)
    TODOs when the current scope is a template
    `NamedConstraintWithSelfDecl`.
7.  toolchain/check/import_ref.cpp: `is_template` in
    `TryResolveTypedInst(NamedConstraintDecl)` (:3696-3799);
    `structural_members_id` in
    `TryResolveTypedInst(NamedConstraintWithSelfDecl)` (:3801-3918, inside the
    pushed block after :3910). Not in `ImportNamedConstraintDefinition`
    (:3675-3694), which owns only the without-self scope (amended 2026-10-06,
    review fold: A2).
8.  toolchain/diagnostics/kind.def: `FunctionInNonTemplateConstraint`,
    `NamedConstraintRedeclTemplateMismatch` in the "Named constraint
    checking." block (:401-403).
9.  Goldens of §4.A (AUTOUPDATE, empty CHECK lines) and the two edited
    existing goldens (§6).

### §2.B Commit 2 — satisfaction

1.  toolchain/sem_ir/identified_facet_type.{h,cpp}: `StructuralRequirement`,
    the ctor parameter, `structural_requirements()`.
2.  toolchain/check/type_completion.cpp:1072-1245: in each of the three
    loops, after the constraint is known complete (or being defined), `if
    (constraint.is_template) structural.push_back({self, {id, specific}})`;
    :1248 passes the vector.
3.  toolchain/check/structural_conformance.{h,cpp} (new; BUILD entry):
    `CheckStructuralRequirements`, `NoteStructuralConformanceFailure`,
    `FacetTypeHasStructuralRequirements`; helpers `SelfIsTemplatePhase`
    (D-SC-19), `FindStructuralMember` (wraps the exposed lookup, applies the
    access decision and the `GetCallee` predicate — D-SC-5(b)(c)),
    `RequirementMatches` (D-SC-5(d)), `SelfFacetCarriesRequirement`
    (D-SC-6), `RequirementTargetIsComplete` (D-SC-5(a), A11).
4.  toolchain/check/member_access.{h,cpp}: expose `LookupMemberNameInScope`
    (:320-406) as `LookupMemberNameInTypeScopes(context, loc_id, base_id,
    name_id, name_scope_const_id, lookup_scopes, lookup_in_type_of_base,
    required, std::optional<AccessInfo> access_info, bool diagnose)` — the
    existing body becomes the `access_info = its own AccessInfo, diagnose =
    true` case (amended 2026-10-06, review fold: A1); the compound-access
    redirect (§1.B.3) at :792-868. toolchain/check/name_lookup.{h,cpp}:
    `IsAccessProhibited` (:250-273) declared in the header (one `static`
    removed; no behavior change).
5.  toolchain/check/impl_lookup.cpp:226-246 and :1010-1019 (§1.C.1-2).
6.  toolchain/check/convert.cpp:1503-1527 (§1.C.3).
7.  toolchain/check/handle_binding_pattern.cpp:313-349 (D-SC-8(i)).
8.  toolchain/diagnostics/kind.def: the six remaining kinds (the four notes
    of D-SC-9 plus `StructuralMemberInaccessible` and
    `TemplateConstraintOnNonTemplateBinding`) in a new "// Structural
    conformance." block after "Require checking." (:455-465).
9.  Goldens of §4.B (check + lower) and the conformance rewrite (§5.A);
    gap-analysis row 55 → PARTIAL; ledger W-027 → implemented.

### §2.C Commit 3 — interop, docs, discharge

1.  Golden interop/cpp/class/import/template_constraint.carbon (§4.C) and
    the conformance program interop/cpp_structural_conformance.carbon (§5.B).
2.  Docs per D-SC-13.
3.  Discharge per §8.5: decision-log landing note, ledger (W-027 evidence,
    W-028/W-029 `blocked_by` cleared, residues by title), gap-analysis
    header and row 55 text, ORCHESTRATION stamp.

No file under toolchain/lower/, toolchain/lex/, toolchain/check/cpp/, or
.github/ changes (no CI changes). Formatter and language server have no
per-node-kind switches touching modifiers (`grep -c "NodeKind::"
toolchain/format/formatter.cpp` is 0; UN-1's parity audit covered the LS).

## §3 Commit structure

1.  **SC-1a (parse + sem_ir + check declaration side)** — §2.A, the §4.A
    goldens, `--self-test` clean. Hosted `compile` probe, then `autoupdate`
    to fixpoint. Expected churn: the two existing goldens of §6 plus new
    files.
2.  **SC-1b (satisfaction at the chokepoint)** — §2.B, the §4.B goldens, the
    §5.A conformance rewrite, gap row 55 PARTIAL, ledger W-027. Hosted
    `autoupdate` to fixpoint, then `gate`, then `conformance` (the first run
    whose scoreboard must move: +1 PASS / −1 SKIP — and the program's
    `42\n7` is produced ONLY by a working check, D-SC-14; amended
    2026-10-06, review fold: B2). W-121 pre-registration applies to the
    autoupdate step (§8.1).
3.  **SC-1c (interop golden + program, docs, discharge)** — §2.C, §4.C,
    §5.B, D-SC-13, §8.5. Hosted `autoupdate`, `gate`, `conformance` (+1
    PASS / +1 total, or the D-SC-11 fallback).

Each fill is a separate commit by the workflow (R15/R28(b)); R26's second
pass is proven by the gate's file_test. Implementation review: ONE after the
hosted verification of SC-1c is green (R29(c)).

## §4 Testdata matrix (R16: no hand-written goldens; autoupdate fills)

Every new file ships with `AUTOUPDATE` and no CHECK lines; each prediction is
what the hosted autoupdate must show, hand-traced from the code paths cited.
Diagnostic kinds are spelled exactly as their `CARBON_DIAGNOSTIC` names.
Split-file rule (the UN-1 lesson): every erroring subfile carries the `fail_`
prefix, positive lower subfiles never share a file with a failing one. Binding
spelling is the working one (`[template T: HasGet]`, `generic T: …`, `fn F(ref
self)`), never `:!` (R3). Prelude: `INCLUDE-FILE:
toolchain/testing/testdata/min_prelude/full.carbon` where `i32` or
`Core.Destroy` is used, `none.carbon` otherwise (the named_constraint/
convention).

### §4.A Commit 1

| File | Splits | Prediction |
| --- | --- | --- |
| parse/testdata/generics/named_constraint/template_constraint.carbon (EXISTING; split renamed) | `template_constraint.carbon` (was `fail_todo_template_constraint.carbon`; same source) | No STDERR. Tree: `TemplateModifier 'template'` leaf, then `NamedConstraintIntroducer 'constraint'`, `IdentifierNameNotBeforeSignature 'Foo'`, `NamedConstraintDefinitionStart '{'`, the two `FunctionDecl`/`FunctionDefinition` subtrees, `NamedConstraintDefinition '}'`; then the forward declaration as `TemplateModifier` + `NamedConstraintDecl ';'` (modifier placement as `AbstractModifier` before `ClassIntroducer` in parse/testdata/class/). Covers node kind `TemplateModifier` (parse coverage test) |
| check/testdata/named_constraint/template_constraint.carbon (new) | `decl.carbon`: `template constraint HasGet { fn Get(self) -> i32; fn Make() -> Self; }` with `//@include-in-dumps`; `forward.carbon`: `template constraint F; template constraint F { fn G(ref self); }`; `compose.carbon`: a template constraint with `require impls Core.Destroy;` and a method; `generic.carbon`: `template constraint Has(T: type) { fn Get(self) -> T; }` | No STDERR. SemIR: `%HasGet.type: type = facet_type <@HasGet>` as for plain constraints (basic.carbon golden :59/:86 — re-cited 2026-10-06, review fold: B8); inside `@HasGet` a `%Self: %HasGet.type = symbolic_binding Self, 0, template [template]` (D-SC-10 — the `, template` suffix as member_access.carbon:137-138, re-cited) and two `fn_decl`s whose `self` pattern is `@HasGet.%Self`-typed; `generic.carbon` shows the with-self generic over `(T, Self)`. These shapes are DERIVED FROM INTERFACE ANALOGUES, not golden-backed: no check golden dumps a `fn` inside a named constraint (invalid_members.carbon has zero `CHECK:STDOUT`) or a template-phase `Self`, so the fill is evidence, not confirmation (R9/R16(d); amended 2026-10-06, review fold: A9) |
| check/testdata/named_constraint/fail_template_constraint_modifier.carbon (new) | `fail_on_fn.carbon`: `template fn F();`; `fail_on_class.carbon`: `template class C {}`; `fail_on_interface.carbon`: `template interface I {}`; `fail_twice.carbon`: `template template constraint X {}`; `fail_with_abstract.carbon`: `template abstract constraint X {}` (added 2026-10-06, review fold: A4) | `ModifierNotAllowedOnDeclaration` "`template` not allowed on `fn` declaration" (modifiers.cpp:102-104) etc.; `fail_twice` → `ModifierRepeated` from `HandleModifier` (handle_modifier.cpp:72-74); `fail_with_abstract` → `ModifierNotAllowedWith` (:76-78; both in the `Decl` at-most-one group) |
| check/testdata/named_constraint/fail_template_constraint_redecl.carbon (new) | `fail_decl_then_template_def.carbon`: `constraint X; template constraint X {}`; `fail_template_decl_then_def.carbon`: `template constraint X; constraint X {}` | `NamedConstraintRedeclTemplateMismatch` at the second declaration + `RedeclPrevDecl` note at the first |
| check/testdata/named_constraint/invalid_members.carbon (EXISTING; three splits move) | `todo_fail_invalid_fn.carbon` → `fail_invalid_fn.carbon` (same source, TODO comments rewritten); `fail_todo_invalid_var_template.carbon`, `fail_todo_invalid_let_template.carbon` keep their names | `fail_invalid_fn`: `FunctionInNonTemplateConstraint` at each of the four `fn`s (:19-20, :25-26). The two template splits lose `UnrecognizedDecl` + "handle invalid parse trees" and gain `SemanticsTodo` "`field requirement in `template constraint``" at the `var` |
| check/testdata/named_constraint/fail_todo_template_constraint_members.carbon (new) | `fail_todo_definition.carbon`: `fn G(self) -> i32 { return 1; }` in a template constraint; `fail_todo_parameterized.carbon`: `fn H[U: type](self, u: U);`; `fail_todo_assoc_const.carbon`: `let X: type;` | `SemanticsTodo` with the D-SC-2 strings. `fail_todo_assoc_const` (amended 2026-10-06, review fold: B13): the parser accepts `let X: type;` in `DeclScopeLoopAsRegular` without error (`HandleLetAfterPattern` consumes `=` only if present, parse/handle_let.cpp:89-92), so check emits exactly two diagnostics — `SemanticsTodo` "associated constant requirement in `template constraint`" at the `let` introducer (`HandleIntroducer`, handle_let_and_var.cpp:67-81, runs first) and then `ExpectedInitializerAfterLet` (kind.def:471; handle_let_and_var.cpp:405) at the declaration — in that order |

### §4.B Commit 2

| File | Splits | Prediction |
| --- | --- | --- |
| check/testdata/named_constraint/template_constraint_satisfy.carbon (new) | `method.carbon`: `class C { fn Get(self) -> i32 { return 1; } } fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); } fn Test(c: C) -> i32 { return CallGet(c); }` with `//@dump-sem-ir-begin/end` around `Test`; `ref_self.carbon` (`fn Get(ref self)` both sides, called on a `var`); `assoc_fn.carbon` (`fn Make() -> Self;` satisfied, called as `T.Make()`); `alias_member.carbon` (p002200's `class D { impl as A { fn F(self) {} } alias F = A.F; }` satisfies `HasF`); `class_param.carbon` (added 2026-10-06, review fold: B6): `class Box(template T: HasGet) { fn Call(self, x: T) -> i32 { return x.Get(); } } fn Test(c: C) -> i32 { var b: Box(C) = {}; return b.Call(c); }` — the class-parameter site the stranded page names (:461-462); `class D(template T: type) {}` is the landed spelling (class/destroy_calls.carbon:68) | No STDERR. In `Test`: `%HasGet.facet: %HasGet.type = facet_value %C, () [concrete]` (EMPTY witness list — D-SC-4; the shape `facet_value <type>, (<witnesses>)` from member_access.carbon:162, re-cited B8; empty-list precedent named_constraint/empty.carbon:59), `%CallGet.specific_fn … @CallGet(%HasGet.facet)` (the interface/final.carbon:88-89 shape), a `call`, and NO `name_ref Get` line from the check itself (the desugared `loc_id` of D-SC-5(b) keeps it out of the block — if the fill shows one, the prediction moves to "one extra `name_ref`", not the design; A5(i)). The generic body is unchanged from member_access.carbon's action shape (:237-243). `alias_member` compiles with no visible SemIR from the check (same desugared-loc reason) and exercises the A10 predicate (`GetCallee` on an `ImplWitnessAccess`). The `facet_value`/`specific_function` lines are golden-backed; the template-phase `Self` and requirement `fn_decl` shapes are derived from interface analogues (A9) |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (new) | `fail_missing.carbon` (class without `Get`); `fail_wrong_return.carbon` (`-> bool`); `fail_wrong_self.carbon` (`ref self` vs value `self`); `fail_wrong_arity.carbon` (`fn Get(self, n: i32)`); `fail_external_impl.carbon` (p002200's `class C {} impl C as A { fn F(self) {} }` — lookup in `C` finds nothing); `fail_private.carbon` (`private fn Get(self)`, called from outside `C`); `fail_overload_set.carbon` (the class's `Get` is an `overload fn` set); `fail_incomplete.carbon` (amended 2026-10-06, review fold: B6): `class Inc; fn F(template T: HasGet) {} fn Test() { F(Inc); }` — the TYPE is the facet argument (rev 1's `CallGet(p)` with `p: Inc*` deduced `T = Inc*`, whose member lookup finds no `Get` and never reaches completeness; explicit template parameter spelling from lower/testdata/template/merging.carbon:20); `fail_incomplete_class_param.carbon` (added, B6): `class Inc; class Box(template T: HasGet) {} fn Test() { var b: Box(Inc) = {}; }` | Each: `ConversionFailureTypeToFacet` "cannot convert type `C` into type implementing `HasGet`" at the call (as fail_convert_facet_value_to_missing_impl.carbon:20-25 shows the facet-to-facet twin) + `DeductionGenericHere` note + `StructuralMemberMissing` or `StructuralMemberMismatch` + `StructuralRequirementHere`. `fail_private` (amended 2026-10-06, review fold: A1): `ConversionFailureTypeToFacet` + `StructuralMemberInaccessible` ("member `Get` of type `C` is private here …") + `StructuralRequirementHere`; NO `ClassInvalidMemberAccess` (the access check is applied to the found result, D-SC-5(b)). `fail_incomplete` and `fail_incomplete_class_param`: `IncompleteTypeInConversion`-class error with the structural context note (the exact kind is whatever `RequireCompleteType`'s caller supplies — this plan supplies a Context note "while checking `HasGet` requirements"; if a reviewer prefers an existing kind, §7 R-6); the class-parameter split reaches the chokepoint through the class's parameter conversion, not deduction, so no `DeductionGenericHere` |
| check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon (new) | `fail_generic_binding.carbon`: `fn Bad(generic T: HasGet) {}`; `fail_implicit_binding.carbon`: `fn Bad[T: HasGet](x: T) {}`; `fail_implicit_binding_compound_use.carbon` (added 2026-10-06, review fold: B7): `interface I {} fn Bad[T: HasGet & I](x: T) -> i32 { return CallGet(x); }`; `fail_symbolic_arg.carbon`: `fn Caller[U: type](x: U) { CallGet(x); }`; `fail_require_in_interface_symbolic.carbon` (added, B7): `interface I { require impls HasGet; } fn G[T: I](x: T) -> i32 { return CallGet(x); }`; `fail_require_in_interface_blanket.carbon`: `interface I { require impls HasGet; } impl forall [T: type] T as I {}` | First two: `TemplateConstraintOnNonTemplateBinding` at the binding. `fail_implicit_binding_compound_use`: EXACTLY ONE diagnostic, `TemplateConstraintOnNonTemplateBinding` at the binding, and nothing at `CallGet(x)` — D-SC-6's cascade guard (the self's facet type `HasGet & I` lists the requirement). `fail_symbolic_arg`: `ConversionFailureTypeToFacet` (`U` has type `type`, so it is a type, not a facet value) + `StructuralRequirementNeedsConcreteType` + `DeductionGenericHere` (D-SC-6). `fail_require_in_interface_symbolic`: `ConversionFailureFacetToFacet` (`T` is a facet value of type `I`, the fail_convert_facet_value_to_missing_impl.carbon:20-25 shape) + `StructuralRequirementNeedsConcreteType` + `DeductionGenericHere` — the interface-forwarding case rejected per D-SC-6. `fail_require_in_interface_blanket`: `InterfaceRequireImplsNotImplemented` (impl.cpp:946-956 — the interface's own `require` loop; `IdentifiedRequireImplsNotImplemented` :891-904 is the identified-facet-type loop and does not fire here), with NO structural note (D-SC-9; amended 2026-10-06, review fold: A5(ii)) — pinning D-SC-8(iii) for a CHECKED blanket |
| check/testdata/named_constraint/template_constraint_dependent.carbon (new) | `dependent_caller.carbon`: `fn Outer[template U: type](x: U) -> i32 { return CallGet(x); } fn Test(c: C) -> i32 { return Outer(c); }`; `fail_dependent_caller_unsatisfied.carbon`: `Outer(d)` with `D` lacking `Get` | Positive: in `@Outer` a `call_action` (the call.carbon shape) and no facet value until the specific `Outer(C)` resolves — D-SC-3. Negative: `ResolvingSpecificHere` "unable to monomorphize specific `Outer(D)`" + the `ConversionFailureTypeToFacet` notes located at `CallGet(x)` (the member_access.carbon:43-49 shape) |
| check/testdata/named_constraint/template_constraint_compound_access.carbon (new) | `compound.carbon`: `fn F[template T: HasGet](x: T) -> i32 { return x.(HasGet.Get)(); }` + `Test(c: C)`; `fail_compound_unsatisfied.carbon` | Positive: in the specific, a `bound_method %x…, @C.%Get.decl`-shaped call (the type's OWN function, D-SC-4). Negative: the conversion diagnostics at the compound access |
| check/testdata/named_constraint/template_constraint_require.carbon (new) | `require_in_template.carbon`: `template constraint Both { fn Get(self) -> i32; require impls Core.Destroy; }` satisfied by a class; `require_in_interface_concrete.carbon`: `interface I { require impls HasGet; } impl C as I {}` with `C` having `Get`; `require_in_interface_template_blanket.carbon` (added 2026-10-06, review fold: A3): `interface I { require impls HasGet; } impl forall [template T: type] T as I {}` followed by `class Lacking {} fn Use[U: I](x: U) {} fn Test(l: Lacking) { Use(l); }` | Positive. `Both`'s facet value lists ONE witness (`Destroy`), structural check silent. `impl C as I` passes `CheckRequireDeclsSatisfied`. `require_in_interface_template_blanket`: NO STDERR — the template-phase self is deferred at the `require` entry point (D-SC-19), and the specific `Lacking as I` resolves through the blanket impl with no re-check; this split PINS the SC-1 gap named in D-SC-19 and §1.G, so a later re-check lands as a `fail_` rename, not a surprise |
| check/testdata/named_constraint/fail_template_constraint_impl_as.carbon (new) | `fail_impl_as.carbon`: `impl C as HasGet {}` | `ImplOfNotOneInterface` "impl as 0 interfaces, expected 1" (impl.cpp:1026-1029) — F-010m pinned (D-SC-8(ii)) |
| check/testdata/named_constraint/template_constraint_impl_forall_template.carbon (new; added 2026-10-06, review fold: A3) | `ladder.carbon`: `interface NewF { fn DoF(self) -> i32; } impl forall [template T: HasGet] T as NewF { fn DoF(self) -> i32 { return self.Get(); } } fn Test(c: C) -> i32 { return c.DoF(); }` — p002200:605-610's migration-ladder step; `fail_ladder_unsatisfied.carbon`: the same with `class D {}` lacking `Get` and `d.DoF()` | PREDICTED positive (lower-confidence, R-11: no golden in tree has `impl forall [template`): the impl's `[template]`-phase `T` deduces `C` in `EvalLookupSingleFinalWitness`, the `T: HasGet` conversion of the deduced `C` runs the full check at that point (concrete self), and `self.Get()` replays as an `AccessMemberAction`. Negative: `D` fails the `T: HasGet` conversion during impl deduction, so no impl is found — `MissingImplInMemberAccess` (the existing shape) at `d.DoF()`; NO structural note, since impl-deduction probes run `diagnose = false`. If the positive split fails to fill, D-SC-19's break condition applies |
| check/testdata/named_constraint/template_constraint_overload.carbon (new) | `overload.carbon`: `overload fn F[template T: HasGet](x: T) -> i32 { return 1; } overload fn F(x: i32) -> i32 { return 2; }` called with a `C` and with an `i32` (the OV-1 same-file set shape, fork/overload/plan.md §4.A); `overload_catch_all.carbon` (added 2026-10-06, review fold: B2): the §5.A `Pick` set — `[template T: HasGet]` then `[template T: type]` — called with `C` and with `Lacking`, with `//@dump-sem-ir-begin/end` around the caller | Positive, no STDERR: the `i32` call skips member 1 silently (D-SC-12). `overload_catch_all`: the caller shows two `specific_function` lines, `@Pick(%HasGet.facet)` for `C` and the second member's specific for `Lacking` — the golden-side pin of the conformance program's falsifier, filled before the conformance run. Falsifier for a `diagnose` leak |
| check/testdata/named_constraint/template_constraint_import.carbon (new; multi-file) | `a.carbon`: `library "a"; template constraint HasGet { fn Get(self) -> i32; }`; `b.carbon`: `import library "a"; class C {…} fn CallGet[template T: HasGet](x: T)…; fn Test(c: C) …` | Positive; the imports block shows `%Main.HasGet = import_ref Main//a, HasGet, …` and the requirement as a loaded import-ref (D-SC-15). The import_constraint_decl.carbon shape (:12-60) |
| lower/testdata/template/template_constraint.carbon (new) | `call_method.carbon`: the §5.A conformance body minus `Core.Print` and minus the overload set (`fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }` returning `CallGet(s)`) — the lower pin is for the dependent method call, not for overload resolution | A `define i32 @…CallGet…(%C …)`-style specific calling `@C.Get` and a caller `define`; no `splice`-related fatal (§1.E); the merging.carbon:241-272 `InitAndCallF` precedent (A8) |

### §4.C Commit 3

| File | Splits | Prediction |
| --- | --- | --- |
| check/testdata/interop/cpp/class/import/template_constraint.carbon (new) | `method.h`: `struct Counter { int value; Counter(int v) : value(v) {} int Get() { return value; } int Twice(int n) { return 2 * n; } }` + `struct Overloaded { int Get(); int Get(int); }`; `satisfy.carbon`: `template constraint HasGet { fn Get(ref self) -> i32; }`, `fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }`, `fn Test(c: Cpp.Counter*) -> i32 { return CallGet(c); }`; `fail_value_self.carbon`: the same constraint spelled `fn Get(self)` → mismatch (D-SC-11's spelling rule pinned); `fail_overloaded.carbon`: `Cpp.Overloaded*` → `StructuralMemberMismatch` (a `CppOverloadSetValue` is not a single function, D-SC-5(c)); `const_method.carbon` (`int Get() const` with `fn Get(ref self)`): PREDICTED positive, flagged (D-SC-5 break condition); if it fills positive, a `const_method` conformance sibling is queued as a residue (§1.G; amended 2026-10-06, review fold: B14) | `satisfy`: `facet_value %Cpp.Counter, ()` in `Test`; the specific binds the imported `Get` through `ref self`. `fail_value_self`: `ConversionFailureTypeToFacet` + `StructuralMemberMismatch` + `StructuralRequirementHere` |

Diagnostic coverage: `TemplateConstraintOnNonTemplateBinding` (§4.B
checked_binding), `FunctionInNonTemplateConstraint` (§4.A invalid_members),
`NamedConstraintRedeclTemplateMismatch` (§4.A redecl), `StructuralMemberMissing`
/ `StructuralMemberMismatch` / `StructuralRequirementHere` /
`StructuralMemberInaccessible` (§4.B unsatisfied),
`StructuralRequirementNeedsConcreteType` (§4.B checked_binding). Node-kind
coverage: `TemplateModifier` (§4.A parse).

## §5 Conformance

Quoted base (scoreboard.json, run 37402970811): 128 PASS / 0 FAIL / 22 SKIP
over 150 programs; bullets 48/56. Bullet "Generics: Template-style structural
conformance to nominal constraints": `{"status": "SKIP", "gap_status":
"MISSING", "programs": ["generics/structural_conformance.carbon"]}`.

### §5.A SC-1b — one SKIP → PASS; delta PASS +1 / SKIP −1 / total 0

fork/conformance/programs/generics/structural_conformance.carbon, rewritten
(bullet line byte-identical to fork/gap-analysis.md:55's first cell, R7;
`runner.py --self-test` before commit; shape amended 2026-10-06, review fold:
B2 — the printed value depends on the check, D-SC-14):

```carbon
// CONFORMANCE-BULLET: Generics: Template-style structural conformance to nominal constraints
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   7
//
// A `template constraint` (p000818 as landed in docs/design/generics/
// details.md:1071-1077; p002200 "Template constraints") is satisfied
// STRUCTURALLY: `StructuralOnly` declares no `impl` anywhere, its own
// member `Get` matches the requirement `fn Get(self) -> i32` modulo
// `Self := StructuralOnly` (fork decision F-010 / SC-1, D-SC-5), and
// `x.Get()` dispatches to that member at instantiation.
//
// WHICH LINE PROVES THE CHECK: `Pick` is an `overload fn` set resolved by
// declaration-order first-match (fork decision F-009, fork/overload/plan.md
// D-OV-4). Member 1 is viable only if the argument type satisfies `HasGet`
// structurally; member 2 accepts any type. `Pick(s)` must print 42 (member
// 1 chosen) and `Pick(l)` must print 7 (member 1 rejected silently, member
// 2 chosen). If the constraint were silently ignored, member 1 would take
// `Lacking` and `x.Get()` would fail to compile; if the check rejected
// everything, the output would be `7` twice; if a rejected probe leaked a
// diagnostic, compilation would fail. Only a correct check prints `42` then
// `7`. Binding spelling from generics/templates_type_param.carbon
// (`[template T: …]`); overload-set spelling from
// functions/overloading_generic.carbon (`unused x: T`); the value-`let`
// arguments avoid a copy (no `Core.Copy` requirement is stated or needed).

import Core library "io";

template constraint HasGet {
  fn Get(self) -> i32;
}

class StructuralOnly {
  // Deliberately NO `impl as …`: the member alone satisfies the constraint.
  fn Get(self) -> i32 { return 42; }
}

class Lacking {
  // No `Get` at all: must NOT satisfy `HasGet`.
  fn Other(self) -> i32 { return 0; }
}

overload fn Pick[template T: HasGet](x: T) -> i32 {
  return x.Get();
}
overload fn Pick[template T: type](unused x: T) -> i32 {
  return 7;
}

fn Run() -> i32 {
  let s: StructuralOnly = {};
  let l: Lacking = {};
  Core.Print(Pick(s));
  Core.Print(Pick(l));
  return 0;
}
```

Expected output hand-derived from each member's own body and the first-match
rule: `Pick(s)` → member 1 → `Get` returns 42; `Pick(l)` → member 1 rejected
(no `Get`) → member 2 → 7; `Core.Print` prints `42\n7\n`, `Run` returns 0.
The SKIP line is removed; no `.diff.cpp` (D-SC-14).

Predicted scoreboard after SC-1b: 129 PASS / 0 / 21 SKIP over 150; bullets
49/56 (the structural bullet flips; it has exactly this one program).

### §5.B SC-1c — one new program; delta PASS +1 / total +1 (or SKIP +1 / total +1 under the D-SC-11 fallback)

fork/conformance/programs/interop/cpp_structural_conformance.carbon (new),
same bullet (D-SC-14):

```carbon
// CONFORMANCE-BULLET: Generics: Template-style structural conformance to nominal constraints
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   0
//
// The interop payoff of structural conformance (F-010 / SC-1, D-SC-11): a
// C++ class with no Carbon declarations at all satisfies a Carbon
// `template constraint` through its imported method. Imported C++ methods
// take `ref self` (check/cpp/import.cpp: PassingMode::ByRef default), so the
// requirement is spelled `fn Get(ref self) -> i32` and the template takes a
// pointer, calling through `->` on the dependent pointee. Construction shape
// from interop/cpp_type_import_class_enum.carbon (`Cpp.Vec2.Vec2(3, 4)`).
//
// WHICH LINE PROVES THE CHECK (same device as generics/
// structural_conformance.carbon): `Pick` is a first-match overload set;
// `Counter` has `Get` and prints 7 through member 1, `Plain` has no `Get`
// and prints 0 through member 2. An ignored constraint fails to compile on
// `Plain`; an over-strict check prints `0` twice.
//
// The classes are DELIBERATELY defined in `import Cpp inline` rather than a
// header: both are still imported through Clang (check/cpp/import.cpp
// method import), which is what D-SC-11 claims, and a non-`const` method is
// used because a `const` accessor's `self` qualifier is D-SC-5's flagged
// break condition (check golden interop/cpp/class/import/
// template_constraint.carbon `const_method` split); a `const`-method sibling
// program is queued if that split fills positive.

import Core library "io";
import Cpp inline '''
struct Counter {
  int value;
  Counter(int v) : value(v) {}
  int Get() { return value; }
};
struct Plain {
  int value;
  Plain(int v) : value(v) {}
};
''';

template constraint HasGet {
  fn Get(ref self) -> i32;
}

overload fn Pick[template T: HasGet](p: T*) -> i32 {
  return p->Get();
}
overload fn Pick[template T: type](unused p: T*) -> i32 {
  return 0;
}

fn Run() -> i32 {
  var c: Cpp.Counter = Cpp.Counter.Counter(7);
  var q: Cpp.Plain = Cpp.Plain.Plain(1);
  Core.Print(Pick(&c));
  Core.Print(Pick(&q));
  return 0;
}
```

Expected output hand-derived: `Pick(&c)` → member 1 → `value` is 7;
`Pick(&q)` → member 1 rejected (no `Get` on `Plain`) → member 2 → 0; printed
`7\n0\n`; exit 0 (program shape amended 2026-10-06, review fold: B2 / B14).

Predicted scoreboard after SC-1c: 130 PASS / 0 / 21 SKIP over 151; bullets
49/56 (same bullet). Fallback (D-SC-11 break condition): 129 / 0 / 22 over
151, bullets 49/56, with the program's SKIP citing the exact diagnostic (R10).

Programs NOT touched: generics/templates_dependent_member.carbon (UA-2's
probe); the stale `:!` claim in its header is UA-2's too. Any other movement
is a §5/§6 miss — stop and reconcile.

## §6 Churn inventory (verified by grep at 8068151ed)

-   **Existing goldens that move: exactly two, both edited on purpose.**
    (1) parse/testdata/generics/named_constraint/template_constraint.carbon
    — the split is renamed and its tree changes (§4.A row 1); (2)
    check/testdata/named_constraint/invalid_members.carbon — three splits'
    STDERR change (§4.A row 5). `grep -rln "^template constraint"
    toolchain/*/testdata` returns exactly these two files; no other golden
    begins a declaration with `template` (`grep -rnE
    "^\s*template\s+(fn|class|let|var|interface|impl|alias|namespace)"`
    over all testdata is empty, and the one parse golden mentioning
    `template` misuse, parse/testdata/function/fail_template_form_param.carbon,
    is a binding-pattern case).
-   **Goldens predicted byte-identical:** the two files whose dumps print
    named constraints (`grep -rln require_impls_block_id
    toolchain/check/testdata` → check/testdata/basics/raw_sem_ir/
    non_core_interfaces.carbon and …/one_file.carbon; rev 1's third,
    facet/nested_facet_types.carbon, matches only on a split FILENAME at
    :290/:311/:314 — amended 2026-10-06, review fold: B9) — the new
    `NamedConstraint` fields print only when set (D-SC-15); every
    named_constraint/, facet/, interface/ and generic/template/ golden — the
    modifier is a parse-time leaf that appears only when written, the check
    paths added are behind `is_template` or behind a non-empty
    `structural_requirements()`, `LookupImplWitness`'s interface loop is
    unchanged, `IdentifyFacetType` pushes nothing for non-template constraints,
    and `PerformCompoundMemberAccessAction`'s redirect keys on a template
    constraint's scope. The eight basics/raw_sem_ir goldens do not print the
    parse node-kind numbering or the modifier-set bits.
-   **Falsifier:** any pre-existing golden other than the two above in the
    autoupdate diff is a plan miss — stop and reconcile before gating. The
    R26 loc-number rule does not apply to new files; it may apply to
    invalid_members.carbon (the `UnrecognizedDecl` STDERR lines above the
    `var` go away, which shifts nothing below them that is dumped).
-   **Source files touched (21):** (1) parse/node_kind.def; (2)
    check/keyword_modifier_set.h (x-macro entry AND the `Decl` constant,
    A4 / B1); (3) sem_ir/named_constraint.h; (4)
    check/handle_named_constraint.cpp; (5) check/handle_function.cpp; (6)
    check/handle_let_and_var.cpp; (7) check/import_ref.cpp; (8)
    diagnostics/kind.def; (9) sem_ir/identified_facet_type.h; (10)
    sem_ir/identified_facet_type.cpp; (11) check/type_completion.cpp; (12)
    check/structural_conformance.h (new); (13) check/structural_conformance.cpp
    (new); (14) check/BUILD; (15) check/member_access.h; (16)
    check/member_access.cpp; (17) check/impl_lookup.cpp; (18)
    check/convert.cpp; (19) check/handle_binding_pattern.cpp; (20)
    check/name_lookup.h and (21) check/name_lookup.cpp (`IsAccessProhibited`
    exposed, A1). Plus docs (five files, D-SC-13), the design record's R31
    heading repair (B10), fork/ ledger and plan files. No contention with the
    W-007 files (cpp/export.cpp, cpp/thunk.cpp, cpp/type_mapping.cpp are
    untouched); SC-B3 remains W-007's last contender.
-   **Concurrent workstreams:** UA-2 (reconciliation) touches fork/ ledger
    files, gap-analysis.md:52/:150 and the templates_dependent_member
    program; this plan's §8.5 edits are to row 55, the header, W-027/028/029
    and new residues — disjoint cells, rebase-mechanical. Re-quote absolutes
    at rebase (R9).

## §7 Risks and rejected alternatives (each with its falsifier)

-   **R-1 — the dependent method call does not lower (amended 2026-10-06,
    review fold: A8 / B5 — rev 1 overstated this risk).** The conformance
    program needs `x.Get()` on a template binding to execute. Evidence for:
    lower/testdata/template/merging.carbon:49 `InitAndCallF` (`({} as
    T).F()` with `class A { fn F(self); }`) IS a dependent INSTANCE-method
    call through an `AccessMemberAction` on a value of type `T`, lowered at
    :241-272 (`call void @_CF.A.Main(ptr …)`), and :58-60 `CallBF` (`x.(B.F)()`
    on `x: T`) lowers at :278-300; :20 `T.F()` covers the associated-function
    form; the `SpliceInst` fatal is cross-file only (:508). What remains
    unproven is only the SPELLING `x.F()` (no golden has exactly that text —
    the mechanism is the same action) and the fork's
    templates_dependent_member probe (`x.n`, a field) until UA-2 runs.
    Falsifier: the §4.B lower golden fails to fill (stack dump in the
    autoupdate log) or the SC-1b conformance run is COMPILE-FAIL/RUN-FAIL on
    structural_conformance.carbon for a reason located at `x.Get()` (not at
    the overload set — a D-SC-14 falsifier instead). Contingency: the lower
    golden is kept as `fail_todo_` only if the defect is upstream's and not
    fixable in one round; the conformance program keeps SKIP with the
    measured diagnostic (allowed: it is SKIP today) and W-014 gains the
    finding; the VALUE shape is tried first and D-SC-14's pointer shape (`p:
    T*`, `p->Get()`) is the fallback IF the value shape fails (one order,
    stated here and in the hand-off; B5).
-   **R-2 — `CheckFunctionTypeMatches` is too strict or too loose for
    structural matching.** Too strict: parameter NAMES are compared only
    with `check_syntax` (D-SC-5 passes false); the `self` form is compared
    by pattern kind (merge.cpp:300-330), which is intended. Too loose: a
    `default`/`virtual` member or a `builtin` is matched by signature alone
    — acceptable (p002200 is signature-based). Falsifier: a §4.B
    `fail_wrong_*` split filling positive, or `method.carbon` filling with a
    mismatch. Contingency: one documented relaxation per D-SC-5's break
    condition, never a thunk.
-   **R-3 — the compound-access redirect misfires for a NON-template
    constraint member reached through `extend`.** Only template constraints
    carry members (plain ones diagnose, D-SC-18), and the redirect keys on
    `is_template`. Falsifier: `template_constraint_compound_access` shows a
    `CompoundMemberAccessDoesNotUseBase` or binds `@HasGet.%Get` instead of
    `@C.%Get`. Contingency: none silent — a wrong bind is a stop.
-   **R-4 — `is_template = true` on `Self` (D-SC-10) perturbs declaration
    goldens.** Falsifier: §4.A `decl.carbon` shows `<dependent type>` or a
    `type_of_inst` in a requirement's parameter pattern, or the fill
    CHECK-fails in `CheckRedeclParams`. Contingency: D-SC-10's break
    condition (pass `false`; file for SC-B2).
-   **R-5 — `FacetTypeHasStructuralRequirements` (D-SC-8(i)) misses a path
    or fires on an incomplete constraint.** It walks `DeclaredFacetType`'s
    three named-constraint vectors and each complete constraint's
    `require_impls` facet types; incomplete constraints are skipped. A
    binding declared BEFORE the template constraint's definition (`fn
    F(generic T: Fwd)` with `template constraint Fwd;` forward-declared) is
    caught by `is_template` on the forward declaration itself (set at the
    declaration, D-SC-16). Falsifier: `fail_generic_binding` without the
    diagnostic, or a plain `generic T: E` golden gaining it. Contingency:
    move the check to first identification of the binding's facet type.
-   **R-6 — completeness diagnostics choose the wrong existing kind.**
    `RequireCompleteType` needs a Context note; this plan adds none as a KIND
    (it reuses the builder's Context mechanism with an inline
    `CARBON_DIAGNOSTIC` of Context severity, which IS a kind —
    `StructuralRequirementIncompleteType`, the NINTH kind if a reviewer prefers
    it to be counted — eight after A1). Falsifier: check_diagnostics.py or
    coverage_test red on the gate. Contingency: add the kind and the golden
    (§4.B `fail_incomplete`).
-   **R-7 — the `diagnose = false` path still emits** (`RequireCompleteType`
    always diagnoses). D-SC-5(a) therefore calls `TryToCompleteType` when
    `!diagnose` and treats incomplete as unsatisfied silently. Falsifier:
    `template_constraint_overload` with an incomplete class argument
    emitting. Contingency: as stated.
-   **R-8 — import of the members block creates unloaded import-refs whose
    `FunctionDecl` is needed by the matcher.** `LoadImportRef` before reading
    the requirement's function (the compound-access precedent,
    member_access.cpp:819). Falsifier: `template_constraint_import` CHECK-
    failing on an `ImportRefUnloaded`. Contingency: load in the loop.
-   **R-9 — the C++ `self` shape (D-SC-11).** Discussed there; falsifier is
    §4.C `satisfy.carbon` filling negative. Contingency: the SKIP fallback.
-   **R-10 — exhaustive switches under -Werror (the baked lesson).** The
    new parse node kind is x-macro generated everywhere (§0.1 row 3); the
    new modifier-set bit is a mask entry; no inst kind is added (D-SC-4) so
    no `EvalConstantInst`, import_ref, type_iterator or lower switch arm is
    owed. Falsifier: the hosted `compile` probe after SC-1a. The container's
    `clang++-19 -fsyntax-only` harness (`scratchpad/syn/check_one_sc.sh`)
    runs on every touched .cpp/.h before each push.
-   **R-11 — `impl forall [template T: …]` is unverified in tree (added
    2026-10-06, review fold: A3).** `grep -rn "forall \[template"` over
    toolchain/*/testdata, core/, examples/ and fork/conformance/programs is
    empty; handle_binding_pattern.cpp:346-349 sets Template phase for any
    symbolic binding pattern with no impl-context rejection, and impl.cpp /
    handle_impl.cpp mention `template` nowhere, so the form is accepted at
    declaration — whether impl deduction and `EvalLookupSingleFinalWitness`
    instantiate a template-phase blanket impl is the open question.
    Falsifier: §4.B `template_constraint_impl_forall_template.carbon`'s
    `ladder` split fails to fill or fills with a diagnostic at the impl.
    Contingency: D-SC-19's break condition (split → `fail_todo_`, residue
    "`impl forall [template T: HasGet]` migration-ladder step"); the
    `require` entry-point deferral stands either way, since the
    `require_in_interface_template_blanket` split exercises only declaration
    and lookup.
-   **Rejected: a new `StructuralWitness`/`CustomWitness` table (the design
    record's shape).** No consumer in B1 (§0.2 item 6); it would add an inst
    kind and every exhaustive switch (R-10) for a value nothing reads.
    Revisited by D-SC-4's break condition.
-   **Rejected: a new `CheckStructuralAction` deferred action.** Replay of
    `CallAction`/`ConvertAction` already delivers a concrete type to the
    chokepoint (D-SC-3). An action keyed on the facet conversion alone
    would duplicate upstream's dependence tracking.
-   **Rejected: parsing `template constraint` as a dedicated introducer
    token pair.** Two parse states and a node kind for what one x-macro line
    does; upstream's own TODO offers the modifier reading (D-SC-1).
-   **Rejected: satisfying requirements through external impls.** Explicitly
    forbidden by p002200:361-377; pinned negative (§4.B
    `fail_external_impl`).
-   **Rejected: shipping `var` field requirements in SC-1 (F-010b).**
    details.md's enumeration omits them, nothing in the conformance arbiter
    needs them, and a field match needs its own type-equality path; they
    ride SC-B2 (D-SC-2).

## §8 Verification and discharge

1.  **Regen (per commit):** `Fork: hosted verification` mode `compile` on
    SC-1a (R-10), then `autoupdate` to fixpoint on each commit (R26/R28(d):
    the gate's file_test pass proves it); expected churn per §6 — exactly
    two pre-existing goldens, both named. Any other pre-existing golden in
    the diff is a stop. W-121 PRE-REGISTRATION (added 2026-10-06, review
    fold: B12): fork/inventory/work-items.json:2140 W-121 records a hosted
    autoupdate that hung for 37 minutes with no stack dump when a
    never-before-dumped facet-value shape was first dumped (the formatter
    and inst namer run only under `--dump-sem-ir-ranges=only`,
    toolchain/testing/file_test.cpp:284; root cause unknown, suspected
    inst_fingerprinter worklist cycle). §4.B `method.carbon`,
    `class_param.carbon` and `overload_catch_all.carbon` dump a
    `facet_value %C, ()` typed by a facet type with structural requirements
    and zero interfaces — a shape no golden has printed. Rule: if the
    autoupdate job's test step runs past 5 minutes after the build step
    completes (W-121's baseline is about 40 s for 1898 tests), cancel the
    run, drop the `//@dump-sem-ir-begin/end` range from the positive splits
    (the `fail_` siblings and the lower golden still pin the decisions),
    refill, and file the residue "SemIR dump of a structural facet value
    hangs file_test" beside W-121 with the cancelled run id.
2.  **Gate:** mode `gate` green (prek + `bazel test //toolchain/...`;
    clang-format 21.1.8 per R18; `uvx prek run --files <changed>` locally
    before every push, R25). The diagnostics coverage test (8 new kinds, or
    9 if R-6's context note is counted — the one place this count is stated,
    B4; §4 coverage list), check_diagnostics.py (one
    `CARBON_DIAGNOSTIC` per kind) and the parse coverage test
    (`TemplateModifier`) are part of the gate.
3.  **Conformance:** mode `conformance`; deltas per §5 (SC-1b +1 PASS / −1
    SKIP / total 0 → 129/0/21 over 150, 49/56; SC-1c +1 PASS / +1 total →
    130/0/21 over 151, or the fallback 129/0/22 over 151) on whatever base
    trunk has at rebase (re-quoted from scoreboard.json, R9).
    `runner.py --self-test` and `--update-readme-table` clean.
4.  **Reconciliation greps at discharge:** `grep -rn "TODO: Support for
    .template constraint" toolchain` is empty; `grep -rn "is_template"
    toolchain/sem_ir/named_constraint.h` hits the field; `grep -rn
    "structural_requirements()" toolchain/check` hits impl_lookup.cpp and
    structural_conformance.cpp; `grep -rn "ConversionFailureTypeToFacet"
    toolchain/check/convert.cpp` still hits exactly one `CARBON_DIAGNOSTIC`;
    `grep -rln "^template constraint" toolchain/*/testdata` lists the two §6
    files plus the new §4 files only; `grep -c "structural"
    fork/conformance/out/scoreboard.json` reflects two programs.
5.  **Ledger edits (fork/inventory/work-items.json, fork/gap-analysis.md,
    fork/decision-log.md):**
    -   W-027 → kind `implemented`; evidence = handle_named_constraint.cpp,
        structural_conformance.cpp, impl_lookup.cpp (the structural
        branch), the §4 goldens, the two §5 programs; notes record §0.2
        items 1-10 and D-SC-1..19 by name, "the chokepoint is
        convert.cpp:1955 (was :1596)", and the four deferred member forms
        BY NAME — field requirements (reverses F-010b's recorded
        recommendation), associated-constant requirements (narrows
        details.md:1073-1075), parameterized requirements (F-010l), default
        definitions — each with its residue title (B3).
    -   W-028, W-029 → `blocked_by` loses W-027 (W-029 keeps W-021/W-007
        edges as they stand).
    -   New residue items by TITLE (§1.G); ids allocated at discharge by
        `grep -oE '"id": ?"W-[0-9]+"' fork/inventory/work-items.json | sort
        -t- -k2 -n | tail -1` on trunk then (W-125 is the highest today —
        never assume numbers).
    -   gap-analysis row 55 → PARTIAL with the text "`template constraint`
        METHOD and associated-function requirements landed (SC-1, F-010 B1):
        a `template T: HasGet` binding is satisfied by a type's own matching
        `fn` members, no `impl`; remaining: field requirements (F-010b,
        deferred against its recorded recommendation), associated-constant
        requirements, parameterized requirement functions (F-010l), default
        definitions in constraints, `require` validity blocks and boolean
        predicates (SC-B2, W-028), concept mapping (SC-B3, W-029)" (amended
        2026-10-06, review fold: B3); header 30/21/4/1 → 30/22/3/1
        (D-SC-17); the W7 paragraph (:187-203) gains "structural conformance
        (B1) landed; see fork/structural/plan.md".
    -   decision-log: an F-010 landing note "(SC-1 landing note,
        <date>)" after :1363 (precedent: the W-068 landing note at :93)
        listing D-SC-1..19 one line each, the §0.2 corrections, the two
        review folds, and — verbatim — D-SC-2's disclosure that field
        requirements are deferred AGAINST F-010b's recorded recommendation
        and associated-constant requirements against details.md:1073-1075,
        both veto-able (B3).
6.  **Docs (D-SC-13):** the ported page + the four sibling hunks, re-read
    against trunk; `prek` (rumdl, google-doc-style) clean; heading and list
    counts recorded before/after per R31(b).
7.  **ORCHESTRATION stamp** per landing (amended 2026-10-06, review fold:
    B15 — the file is already internally stale and the discharge updates
    ALL of these): the "Last updated" status paragraph (:13-33, currently
    128/0/22 over 150), the "### Scoreboard" section (:366-378, still
    reading 126 PASS / 23 SKIP / 149 at PR 48 and ending its chain at "128
    SL-2" — append "→ 129 SC-1b → 130 SC-1c"), the "## Branches" table
    (:353-364, no SC row today — add one), the floor, the PR count, and the
    dispatch list if goldens are parked under R28(c).

## Hand-off notes for the implementer

-   Read §0.1 rows 5, 7, 9, 10, 15, 17 and 19 before touching code; they are
    the seven facts the design record got wrong or did not know.
-   Commit 1 first, hosted `compile` probe second, goldens third. Two
    compile-time exposures: `Print`/`MergeDefinition` on `NamedConstraint`
    (R-10) and the `CARBON_KEYWORD_MODIFIER_SET_IN_GROUP` static_assert —
    `X(Template)` without `| Template` in `KeywordModifierSet::Decl` does
    not build (A4 / B1); run `check_one_sc.sh` on every touched file.
-   `is_template` must be set BEFORE `TryMergeRedecl` reads it for the
    mismatch check, and the Self binding's `is_template` must come from the
    stored entity (a redeclaration can be the definition).
-   Collect `structural_members_id` from `body_block_with_self_id` at `}`;
    do not add a stack. Filter to `FunctionDecl` insts whose function's
    `parent_scope_id` is `scope_with_self_id` (a nested entity's decl could
    otherwise sneak in) AND whose generic has no parameters of its own
    beyond the with-self generic's (a parameterized requirement is
    TODO-diagnosed and must not be collected — A12).
-   Import the members block in the `NamedConstraintWithSelfDecl` resolver
    (import_ref.cpp:3801-3918), inside its pushed block, not in the
    `NamedConstraintDecl` one — only the with-self resolver owns the scope
    the requirements live in (A2).
-   In `CheckStructuralRequirements`, canonicalize the self with
    `GetCanonicalQuerySelfForLookupImplWitness` (impl_lookup.h:68) before
    anything else, exactly as the interface loop does, and read
    `FacetValue`s through `GetCanonicalFacet` for D-SC-6.
-   The member lookup MUST go through the member-access path (D-SC-5(b));
    `LookupNameInExactScope` will not resolve p002200's alias and will not
    import C++ members. Call the exposed wrapper with `access_info =
    nullopt` and apply `IsAccessProhibited` yourself on the result's
    `access_kind()` — `LookupQualifiedName` emits on a prohibited access
    even with `required = false` (A1); pass the desugared `loc_id` so no
    `name_ref` lands in the caller's block (A5); classify the result with
    `GetCallee`, not `Is<FunctionDecl>` — the alias case returns an
    `ImplWitnessAccess` (A10).
-   Use `GetSelfSpecificForInterfaceMemberWithSelfType` with
    `enclosing_specific_id = SpecificId::None` — the requirement is not
    being matched from inside another generic; if the fill shows a bind
    index assertion, the enclosing specific must be the CALLER's (the
    thunk.cpp:462 caller passes the impl's), and that is the one thing to
    re-trace.
-   Explain mode re-runs the check; keep both modes in one function with a
    `DiagnosticBuilder*` that is null in check mode, so they cannot drift.
-   `diagnose = false` must be total: no `RequireCompleteType`, no
    `context.TODO`, no `LoadImportRef`-time diagnostics (R-7).
-   Conformance: `runner.py --self-test` after editing the program; the
    bullet cell must match fork/gap-analysis.md:55 byte for byte (R7). The
    `let s` VALUE shape is tried first; the pointer shape is R-1's fallback
    only if the value shape fails to lower (B5 — one order, stated in R-1
    and here). Keep the two-member `Pick` set: it is what makes the printed
    value depend on the check (B2).
-   Docs: port, do not re-author (D-OV-8 precedent); take only the
    details.md:1068-1077 hunk from the stranded diff; re-run prek and the
    R31 count diff.
-   Keep every PR/issue number in prose as "PR 7727" / "issue 2153" and
    never end a sentence with a bare number (R31).

## Review fold record (rev 2, 2026-10-06)

Two fresh-context adversarial reviews of rev 1 (d9918a542): review A,
correctness of the mechanism against the toolchain (verdict
APPROVE-WITH-AMENDMENTS; 4 MAJOR, 8 MINOR, 0 BLOCKER), and review B, design
fidelity / scope / tests / process (verdict APPROVE-WITH-AMENDMENTS; 3 MAJOR,
12 MINOR, 0 BLOCKER). Every finding was re-opened at its cited file:line in
the worktree before disposition (R8); each accepted fold is marked in place.
No finding is rejected outright; two are accepted with a correction to the
reviewer's own proposed fix, noted in the table.

| Finding | Grade | Disposition | Landed in |
| --- | --- | --- | --- |
| A1 access check vs `diagnose = false` | MAJOR | ACCEPTED — access IS checked; wrapper takes `optional<AccessInfo>` + `diagnose`; check mode records prohibited as unsatisfied silently; explain mode emits a NOTE. Correction to the proposed fix: `ClassInvalidMemberAccess` is Error-severity (name_lookup.cpp:237-240), so a Note kind `StructuralMemberInaccessible` carrying its text is added rather than reusing it | D-SC-5(b), D-SC-9, §1.C.2, §1.D, §2.B.3-4, §2.B.8, §4.B `fail_private`, §6 (21 files), hand-off |
| A2 members-block import in the wrong resolver | MAJOR | ACCEPTED — `structural_members_id` imported in `TryResolveTypedInst(NamedConstraintWithSelfDecl)` (:3801-3918) inside its pushed block; `is_template` in the first-phase entity creation | D-SC-15, §1.A.5, §2.A.7, hand-off |
| A3 `require` entry point reaches the check with a template-phase self | MAJOR | ACCEPTED — new D-SC-19: deferred / structurally satisfied for now, uses checked at monomorphization; the bare `require` is not re-run per specific in SC-1 (disclosed, pinned, residue). Two goldens added | D-SC-3, D-SC-6, D-SC-8(iii), D-SC-19, §1.C, §1.G, §2.B.3, §4.B (`template_constraint_impl_forall_template.carbon`, `require_in_interface_template_blanket.carbon`), R-11 |
| A4 / B1 `KeywordModifierSet::Decl` must gain `Template` | MAJOR | ACCEPTED — `\| Template` in the explicit `Decl` union (:150-154); static_assert :170-176 and `HandleModifier` :58-60 cited; `template abstract` → `ModifierNotAllowedWith` pinned | D-SC-1, §0.1 row 4, §1.D, §2.A.2, §4.A `fail_with_abstract`, §6, hand-off |
| A5(i) extra `name_ref` inst from the check | MINOR | ACCEPTED — desugared `loc_id` (impl_lookup.cpp:1061 idiom); prediction states "no extra line" with the fallback | D-SC-5(b), §4.B `method.carbon` / `alias_member` |
| A5(ii) wrong kind for the checked blanket `require` | MINOR | ACCEPTED — `InterfaceRequireImplsNotImplemented` (impl.cpp:946-956); "plus the note" dropped; impl.cpp emits stay note-less in SC-1 | D-SC-9, §4.B `fail_require_in_interface_blanket` |
| A6 there is no `impls` expression | MINOR | ACCEPTED — replaced by the measured `LookupImplWitness` caller list (adds cpp/thunk.cpp:1253, which review A's list omitted) | D-SC-3 |
| A7 / B8 stale line cites | MINOR | ACCEPTED — re-cited: handle_named_constraint.cpp :53/:73-81/:141-143/:188-210/:196-206; import_ref.cpp :3754-3755/:3675-3694/:3696-3799/:3801-3918; handle_function.cpp :552-575/:1050/:1097-1102/:1219; design record :217/:286/:349/:395/:507, :389-399, :255-256/:363-367, :191-246; member_access.carbon :137-138/:162/:237-243; basic.carbon :59/:86; impl_lookup.cpp :1010-1019; p000818's text cited as details.md:1071-1077 | §0.1 header and rows 4-5, §0.2 items 1/3/6, D-SC-1, D-SC-15, §1.C.1, §2.A.4-7, §2.B.5, §4.A, §4.B, §5.A header |
| A8 R-1 overstates the lowering risk | MINOR | ACCEPTED — merging.carbon:49 `InitAndCallF` and :58-60 `CallBF` are the proof; value shape first, pointer an "if" | R-1, D-SC-14, hand-off |
| A9 central positive shapes have no upstream golden | MINOR | ACCEPTED — decl.carbon and method.carbon predictions labelled "derived from interface analogues" | §4.A row 2, §4.B row 1 |
| A10 `FunctionDecl` is the wrong predicate for the alias case | MINOR | ACCEPTED — `GetCallee` → `CalleeFunction`; the other five variants are mismatches | D-SC-5(c), §1.D, §2.B.3, hand-off |
| A11 being-defined constraints | MINOR | ACCEPTED — `structural_members_id == None` → incomplete → unsatisfied; `FacetTypeHasStructuralRequirements` reads only `is_template` | D-SC-5(a), D-SC-8(i), §2.B.3 |
| A12 `index_delta = -1` benign only because of D-SC-2 | MINOR | ACCEPTED — a parameterized requirement is not collected into `structural_members_id` | §1.A.3, D-SC-2, hand-off |
| Review A Angle 5 reuse suggestion (unnumbered) | note | ACCEPTED as an implementer option — `TryToIdentifyFacetType(allow_partially_identified = true)` may replace the separate DFS | D-SC-8(i) |
| B2 conformance programs vacuous with respect to satisfaction | MAJOR | ACCEPTED — both §5 programs take the two-member `overload fn Pick` first-match shape; verified against D-OV-4 step 2(d) and function/overload/generic.carbon `fail_deduce_all` (silent facet-constraint rejection by probe); gate (xi) is on template-dependent arguments only. `impls`-expression alternative not available (A6). Scoreboard deltas unchanged; outputs become `42\n7` and `7\n0` | D-SC-12, D-SC-14, §3 item 2, §4.B `overload_catch_all`, §5.A, §5.B, R-1, hand-off |
| B3 D-SC-2's narrowings undisclosed; row 55 text incomplete | MAJOR | ACCEPTED — the field deferral is disclosed as a REVERSAL of F-010b's recorded recommendation, the associated-constant deferral as a narrowing of details.md:1073-1075, both veto-able; row 55, W-027 evidence and the landing note name the four deferred forms | D-SC-2, D-SC-17, §8.5 |
| B4 "six" vs "7 kinds" | MINOR | ACCEPTED — heading and body agree (eight, after A1; nine with R-6), stated once in §8.2 | D-SC-9, §1.D, R-6, §8.2 |
| B5 value shape vs pointer shape first | MINOR | ACCEPTED — value first everywhere (R-1, D-SC-14, hand-off); A8 is why | R-1, D-SC-14, hand-off |
| B6 `fail_incomplete` cannot reach the completeness path; no class-parameter golden | MINOR | ACCEPTED — `F(Inc)` with an explicit `template T: HasGet` parameter, plus `fail_incomplete_class_param` (`Box(Inc)`) and the positive `class_param.carbon` | §4.B rows 1-2 |
| B7 D-SC-6's positive branch unpinned; `fn G[T: I]` answer unstated | MINOR | ACCEPTED — `fn G[T: I]` REJECTED in SC-1, mirroring upstream's interface/require.carbon TODO (:79-98); the positive branch is kept as a cascade guard with its one reachable input pinned (`fail_implicit_binding_compound_use`); residue filed | D-SC-6, §1.G, §4.B checked_binding |
| B9 "three files" is two | MINOR | ACCEPTED — grep result recorded | §6, D-SC-15 |
| B10 D-SC-13's deletion claim wrong; second hunk silent; cache sentence unamended; record's R31 heading | MINOR | ACCEPTED — the stranded details.md diff is additive (two hunks; the +6877 one deferred to SC-B2 on purpose); §Completeness and caching amended to D-SC-7; record heading at :450 repaired in the same commit with the R31(b) count diff | D-SC-13, §6 |
| B11 D-SC-14 and D-SC-17 lack break conditions | MINOR | ACCEPTED — both added | D-SC-14, D-SC-17 |
| B12 W-121 hang not pre-registered | MINOR | ACCEPTED — 5-minute rule, dump-range drop, residue beside W-121 | §8.1, §3 item 2, §1.G |
| B13 `fail_todo_assoc_const` hedged | MINOR | ACCEPTED — two diagnostics named in order: `SemanticsTodo` (associated constant requirement) then `ExpectedInitializerAfterLet` (kind.def:471) | §4.A row 6, D-SC-2, §1.A.3, §2.A.6 |
| B14 §5.B exercises an inline struct, no header | MINOR | ACCEPTED — header states why (Clang import is still exercised; `const` self is D-SC-5's break condition); `const_method` sibling queued conditionally | §5.B, §4.C, §1.G |
| B15 §8.7 stamp list omits stale sections | MINOR | ACCEPTED — status paragraph, Scoreboard section, Branches row, floor, dispatch list all named | §8.7 |

D-SC list changes in rev 2: D-SC-1 (set-constant edit), D-SC-2 (disclosures,
`let` TODO text, not-collected rule), D-SC-3 (caller list, `require` entry
point), D-SC-5 (a: being-defined; b: access decision + desugared loc; c:
`GetCallee` predicate), D-SC-6 (cascade-guard reachability, `T: I` rejected),
D-SC-8 (i: reuse option; iii: template blanket deferred), D-SC-9 (eight
kinds, `StructuralMemberInaccessible`, impl.cpp emits note-less), D-SC-12
(probe-path evidence), D-SC-13 (additive-diff correction, cache amendment,
record heading repair), D-SC-14 (two-member shape, order, break condition),
D-SC-15 (import placement, two goldens not three), D-SC-17 (deferred forms,
break condition), and the new D-SC-19 (template-phase self at the `require`
entry point is deferred). D-SC-4, D-SC-7, D-SC-10, D-SC-11, D-SC-16 and
D-SC-18 are unchanged.

R31 record for this revision. MD013 reflow IS on (`.rumdl.toml:29-30`,
`reflow = true`, applied by the pre-commit `rumdl --fix` hook that runs twice),
so the counts are the detector. Rev 1 (d9918a542): 1 H1 / 11 H2 / 19 H3 / 0
H4, 65 dash items, 53 numbered items. Rev 2 after authoring, before `prek`: 1 /
12 / 19 / 0, 73 dash, 53 numbered. Rev 2 after `prek` to fixpoint (pass 1
reflowed five over-long list-continuation segments in §0.2 item 6, D-SC-2,
D-SC-3, §2.A.7 and R-6; pass 2 clean): 1 / 12 / 19 / 0, 73 dash, 53 numbered —
identical before and after the reflow, so nothing was manufactured. The delta
against rev 1 is exactly the authored additions: the fold record's H2, and
eight dash items (D-SC-19, five §1.G residues, R-11, one hand-off bullet). The
hazard greps (`^#[0-9]`, `^\s*#{1,6} [0-9]`, `^\s*[*+] `) are empty before and
after.

## Sign-off

Signed off for implementation, 2026-10-06, rev 2. Review A (correctness of
the mechanism against the toolchain at c1e83b0b7 plus fork features):
APPROVE-WITH-AMENDMENTS, no BLOCKER, no REJECT. Review B (design fidelity,
scope, tests, process): APPROVE-WITH-AMENDMENTS, no BLOCKER, no REJECT. Every
finding is folded above or carried in the fold record with its disposition;
per the loop, two APPROVE-WITH-AMENDMENTS verdicts with no BLOCKER need no
focused re-review, and the ONE implementation review runs after the hosted
verification of SC-1c is green (R29(c)). The implementer starts from §2.A
with the hand-off notes; the first stop condition is the hosted `compile`
probe after SC-1a (R-10, A4 / B1).
