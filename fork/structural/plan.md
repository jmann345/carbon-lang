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
    fold: A10). A `CalleeFunction` that is itself a requirement `fn` is not a
    member at all (amended 2026-10-13: fill round 2 made it `Missing`, the
    decision log's "D-SC-5(b) clarified"; fill round 3, review finding F7,
    gives it its own note, `StructuralMemberIsRequirement`, D-SC-9); and a
    requirement named as an impl member, `impl C as I { alias F = HasGet.Get;
    }`, implements nothing (`ImplFunctionWithNonFunction`, as upstream's alias
    of another interface's member; fill round 3, review finding BLOCKER-1: it
    passed check, its thunk took the constraint's scope, and the mangler
    aborted);
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
-   **D-SC-6 — a SYMBOLIC (checked-phase) self.** (SUPERSEDED 2026-10-13, fill
    round 2: the positive branch this sentence and the reachability paragraph
    describe was deleted; a checked-symbolic self is now always unsatisfied,
    see the amendment below.) A structural requirement
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
    diagnostic, at the binding (amended 2026-10-13, fill round 2: the guard
    did not deliver that — the callee's template body still reached the
    bodiless requirement — so D-SC-8(i) now gives the diagnosed binding an
    error type, as an invalid binding type does, the positive branch is
    deleted, and the one diagnostic holds by that recovery; "Landed notes
    (SC-1 fill rounds, 2026-10-13)"). Otherwise a checked-symbolic self is
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
    natural meaning, pinned by `template_constraint_require.carbon` (amended
    2026-10-13, fill round 2: an impl defined inside the class that is its
    self has its structural `require`s checked when the class completes,
    since the class is incomplete within its definition and the check reads
    its members, D-SC-5(a); amended again 2026-10-13, fill round 3, review
    findings MINOR-1, MINOR-2 / F1 and F8: the wait is keyed on the
    `require`'s own self being a class whose definition has started and not
    ended, wherever the impl is, so an impl in a nested class or an impl of
    another type whose interface requires the class waits too; only the
    structural part waits, the interfaces the same facet type names being
    looked up at the impl as a nominal `require` is, so `require impls HasGet &
    J` orders `J`'s impl as `require impls J` does; the waiting `require`s sit
    on a per-class list on `Context` that the class's `ClassDefinition`
    handler drains, rather than on upstream's `DeferredDefinitionWorklist`,
    because the check needs only that class complete, not the outermost one,
    and the worklist defers definitions, not declaration checks); a
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
    covered by a §4 golden (coverage_test); fill round 2 adds one more, the
    error `StructuralRequirementCalled` ("requirement `{0}` of template
    constraint `{1}` can only be called through a type that satisfies it",
    D-SC-4: a requirement `fn` is never itself the callee), so 9 kinds, 10
    with R-6's (amended 2026-10-13); fill round 3 adds the note
    `StructuralMemberIsRequirement` ("name `{1}` in type {0} refers to a
    requirement of template constraint `{2}`, not to a member of the type",
    D-SC-5(c) as amended; review finding F7), so 10 kinds, 11 with R-6's
    (amended 2026-10-13). The deferred forms of D-SC-2 use
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
    validity blocks will need it. (Amended 2026-10-13, fill round 1: false
    for a requirement named with no self, `HasGet.Get`, whose with-self
    specific carried the template-phase `Self` and so made the name
    template-dependent; D-SC-20 gives such a lookup `.Self` instead, and the
    phase of `Self` itself stands.) Break condition: the commit-1 fill shows
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
-   **D-SC-20 — a requirement named with no self type has `Self := .Self`
    (added 2026-10-13: introduced by fill round 1's fix 2, recorded at fill
    round 2, review finding F4).** A lookup into a template constraint with
    no self type (`HasGet.Get`, or a facet type as the lookup's self) builds
    the constraint-with-self specific with `.Self` of the constraint's facet
    type (name_lookup.cpp `GetPeriodSelfForTemplateConstraintLookup`: an
    unfrozen `symbolic_binding .Self` with no parent scope), not the
    constraint's own `Self` binding. Reason: the requirement `fn` is the one
    with-self member whose value depends on `Self`; the abstract `Self` is a
    parameter of the constraint's generic, so naming the requirement inside
    any generic attached that binding to the generic's eval block (eval.cpp
    "does not belong to generic", a CHECK failure) and its template phase
    made the name template-dependent (a `splice_inst` that lowering cannot
    handle); `.Self` depends on no generic parameter (sem_ir/constant.h
    `DependsOnGenericParameter`), and generic.cpp's
    `GetOrAddInstWithSpecificConstantValue` returns early for such a
    constant. Interfaces and plain constraints keep the abstract `Self`, so
    no upstream golden moves. Consequences: the requirement is never itself
    called (D-SC-9's `StructuralRequirementCalled`), and a compound access
    through it redirects to the base type's own member (D-SC-4). Pinned by
    template_constraint_compound_access.carbon `checked_generic_name` and
    `assoc_fn_compound` (the SemIR shows `%.Self: %HasGet.type =
    symbolic_binding .Self [symbolic_self]`) and lower/testdata/template/
    template_constraint.carbon `compound_nongeneric`. Veto-able (R29(a)).
    Break condition: a golden shows the unfrozen `.Self` replaced by
    `SubstPeriodSelf` where a requirement's specific reaches a facet type,
    or upstream gives facet-type member lookups a self of their own — then
    the placeholder becomes a frozen or dedicated binding printed as the
    constraint's `Self`.

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
    `is_template` (:313-318) and `is_generic`; when `is_generic && !is_template`
    and `FacetTypeHasStructuralRequirements(type_id)` →
    `TemplateConstraintOnNonTemplateBinding`, the pattern keeps its type (no
    cascade) (amended 2026-10-13, fill round 2: the pattern gets an error type
    instead, which is what makes "no cascade" true, D-SC-6). A runtime binding
    of facet type is unaffected (it is a facet VALUE binding; the facet type's
    structural requirements apply when its initializer converts).
2.  The body: `x.Get()` is `access_member_action` + `splice_inst` exactly as
    today (§0.1 row 18); structural constraints do not alter lookup
    (p002200:379-399). At instantiation the action resolves in the concrete
    type. No change. (Amended 2026-10-13, fill round 1: true for `x.Get()`,
    whose type becomes `C`; an access on the facet value itself, `T.Make()`,
    finds the requirement with `Self := C`, and `LookupMemberNameInTypeScopes`
    redirects it to `C`'s own member, D-SC-4.)
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

Amended 2026-10-13 (fill round 3, review finding BLOCKER-1): the proof missed
one input. `impl C as I { alias F = HasGet.Get; }` passed check and built a
thunk whose parent scope is the requirement's (thunk.cpp `CloneFunctionDecl`
copies its callee's), the template constraint's with-self scope, which
sem_ir/mangler.cpp:185 cannot mangle. That spelling is now rejected at the impl
(D-SC-5(c) as amended), so no thunk of a requirement exists, and the accepted
spelling `alias F = (C as HasGet).Get` names `C.Get` itself; the lower split
`impl_member_alias` pins that it lowers. The rest of the proof stands.

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
| parse/testdata/generics/named_constraint/template_constraint.carbon (EXISTING; split renamed) | `template_constraint.carbon` (was `fail_todo_template_constraint.carbon`; same source) | No STDERR. Tree: `TemplateModifier 'template'` leaf, then `NamedConstraintIntroducer 'constraint'`, `IdentifierNameNotBeforeSignature 'Foo'`, `NamedConstraintDefinitionStart '{'`, the two `FunctionDecl`/`FunctionDefinition` subtrees, `NamedConstraintDefinition '}'`; then the forward declaration as `TemplateModifier` + `NamedConstraintDecl ';'` (modifier placement as `AbstractModifier` before `ClassIntroducer` in parse/testdata/class/). Covers node kind `TemplateModifier` (parse coverage test) AMENDED 2026-10-13 (fill round 1, miss (a)): the tree prints `NamedConstraintIntroducer` first and `TemplateModifier` second, the parse/testdata/class/introducer.carbon:30-31 placement this row cites |
| check/testdata/named_constraint/template_constraint.carbon (new) | `decl.carbon`: `template constraint HasGet { fn Get(self) -> i32; fn Make() -> Self; }` with `//@include-in-dumps`; `forward.carbon`: `template constraint F; template constraint F { fn G(ref self); }`; `compose.carbon`: a template constraint with `require impls Core.Destroy;` and a method; `generic.carbon`: `template constraint Has(T: type) { fn Get(self) -> T; }` | No STDERR. SemIR: `%HasGet.type: type = facet_type <@HasGet>` as for plain constraints (basic.carbon golden :59/:86 — re-cited 2026-10-06, review fold: B8); inside `@HasGet` a `%Self: %HasGet.type = symbolic_binding Self, 0, template [template]` (D-SC-10 — the `, template` suffix as member_access.carbon:137-138, re-cited) and two `fn_decl`s whose `self` pattern is `@HasGet.%Self`-typed; `generic.carbon` shows the with-self generic over `(T, Self)`. These shapes are DERIVED FROM INTERFACE ANALOGUES, not golden-backed: no check golden dumps a `fn` inside a named constraint (invalid_members.carbon has zero `CHECK:STDOUT`) or a template-phase `Self`, so the fill is evidence, not confirmation (R9/R16(d); amended 2026-10-06, review fold: A9) |
| check/testdata/named_constraint/fail_template_constraint_modifier.carbon (new) | `fail_on_fn.carbon`: `template fn F();`; `fail_on_class.carbon`: `template class C {}`; `fail_on_interface.carbon`: `template interface I {}`; `fail_twice.carbon`: `template template constraint X {}`; `fail_with_abstract.carbon`: `template abstract constraint X {}` (added 2026-10-06, review fold: A4) | `ModifierNotAllowedOnDeclaration` "`template` not allowed on `fn` declaration" (modifiers.cpp:102-104) etc.; `fail_twice` → `ModifierRepeated` from `HandleModifier` (handle_modifier.cpp:72-74); `fail_with_abstract` → `ModifierNotAllowedWith` (:76-78; both in the `Decl` at-most-one group) |
| check/testdata/named_constraint/fail_template_constraint_redecl.carbon (new) | `fail_decl_then_template_def.carbon`: `constraint X; template constraint X {}`; `fail_template_decl_then_def.carbon`: `template constraint X; constraint X {}` | `NamedConstraintRedeclTemplateMismatch` at the second declaration + `RedeclPrevDecl` note at the first |
| check/testdata/named_constraint/invalid_members.carbon (EXISTING; three splits move) | `todo_fail_invalid_fn.carbon` → `fail_invalid_fn.carbon` (same source, TODO comments rewritten); `fail_todo_invalid_var_template.carbon`, `fail_todo_invalid_let_template.carbon` keep their names | `fail_invalid_fn`: `FunctionInNonTemplateConstraint` at each of the four `fn`s (:19-20, :25-26). The two template splits lose `UnrecognizedDecl` + "handle invalid parse trees" and gain `SemanticsTodo` "`field requirement in `template constraint``" at the `var` |
| check/testdata/named_constraint/fail_todo_template_constraint_members.carbon (new) | `fail_todo_definition.carbon`: `fn G(self) -> i32 { return 1; }` in a template constraint; `fail_todo_parameterized.carbon`: `fn H[U: type](self, u: U);`; `fail_todo_assoc_const.carbon`: `let X: type;` | `SemanticsTodo` with the D-SC-2 strings. `fail_todo_assoc_const` (amended 2026-10-06, review fold: B13): the parser accepts `let X: type;` in `DeclScopeLoopAsRegular` without error (`HandleLetAfterPattern` consumes `=` only if present, parse/handle_let.cpp:89-92), so check emits exactly two diagnostics — `SemanticsTodo` "associated constant requirement in `template constraint`" at the `let` introducer (`HandleIntroducer`, handle_let_and_var.cpp:67-81, runs first) and then `ExpectedInitializerAfterLet` (kind.def:471; handle_let_and_var.cpp:405) at the declaration — in that order |

### §4.B Commit 2

| File | Splits | Prediction |
| --- | --- | --- |
| check/testdata/named_constraint/template_constraint_satisfy.carbon (new) | `method.carbon`: `class C { fn Get(self) -> i32 { return 1; } } fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); } fn Test(c: C) -> i32 { return CallGet(c); }` with `//@dump-sem-ir-begin/end` around `Test`; `ref_self.carbon` (`fn Get(ref self)` both sides, called on a `var`); `assoc_fn.carbon` (`fn Make() -> Self;` satisfied, called as `T.Make()`); `alias_member.carbon` (p002200's `class D { impl as A { fn F(self) {} } alias F = A.F; }` satisfies `HasF`); `class_param.carbon` (added 2026-10-06, review fold: B6): `class Box(template T: HasGet) { fn Call(self, x: T) -> i32 { return x.Get(); } } fn Test(c: C) -> i32 { var b: Box(C) = {}; return b.Call(c); }` — the class-parameter site the stranded page names (:461-462); `class D(template T: type) {}` is the landed spelling (class/destroy_calls.carbon:68) | No STDERR. In `Test`: `%HasGet.facet: %HasGet.type = facet_value %C, () [concrete]` (EMPTY witness list — D-SC-4; the shape `facet_value <type>, (<witnesses>)` from member_access.carbon:162, re-cited B8; empty-list precedent named_constraint/empty.carbon:59), `%CallGet.specific_fn … @CallGet(%HasGet.facet)` (the interface/final.carbon:88-89 shape), a `call`, and NO `name_ref Get` line from the check itself (the desugared `loc_id` of D-SC-5(b) keeps it out of the block — if the fill shows one, the prediction moves to "one extra `name_ref`", not the design; A5(i)). The generic body is unchanged from member_access.carbon's action shape (:237-243). `alias_member` compiles with no visible SemIR from the check (same desugared-loc reason) and exercises the A10 predicate (`GetCallee` on an `ImplWitnessAccess`). The `facet_value`/`specific_function` lines are golden-backed; the template-phase `Self` and requirement `fn_decl` shapes are derived from interface analogues (A9) AMENDED 2026-10-13 (fill rounds, misses (e) and (f)): "No STDERR" holds once round 2 spells `unused` on the unused bindings (round 1 carried upstream's `UnusedBinding` warnings); `method` prints the `facet_value`/`converted` pair twice (deduction, then the argument; the interop/cpp/function/export/generic.carbon:446-449 shape); `assoc_fn` is positive only through fill round 1's D-SC-4 redirect, and its round-2 dump shows `MakeIt(C)` calling `@C.%C.Make.decl` ("Landed notes (SC-1 fill rounds, 2026-10-13)") |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (new) | `fail_missing.carbon` (class without `Get`); `fail_wrong_return.carbon` (`-> bool`); `fail_wrong_self.carbon` (`ref self` vs value `self`); `fail_wrong_arity.carbon` (`fn Get(self, n: i32)`); `fail_external_impl.carbon` (p002200's `class C {} impl C as A { fn F(self) {} }` — lookup in `C` finds nothing); `fail_private.carbon` (`private fn Get(self)`, called from outside `C`); `fail_overload_set.carbon` (the class's `Get` is an `overload fn` set); `fail_incomplete.carbon` (amended 2026-10-06, review fold: B6): `class Inc; fn F(template T: HasGet) {} fn Test() { F(Inc); }` — the TYPE is the facet argument (rev 1's `CallGet(p)` with `p: Inc*` deduced `T = Inc*`, whose member lookup finds no `Get` and never reaches completeness; explicit template parameter spelling from lower/testdata/template/merging.carbon:20); `fail_incomplete_class_param.carbon` (added, B6): `class Inc; class Box(template T: HasGet) {} fn Test() { var b: Box(Inc) = {}; }` | Each: `ConversionFailureTypeToFacet` "cannot convert type `C` into type implementing `HasGet`" at the call (as fail_convert_facet_value_to_missing_impl.carbon:20-25 shows the facet-to-facet twin) + `DeductionGenericHere` note + `StructuralMemberMissing` or `StructuralMemberMismatch` + `StructuralRequirementHere`. `fail_private` (amended 2026-10-06, review fold: A1): `ConversionFailureTypeToFacet` + `StructuralMemberInaccessible` ("member `Get` of type `C` is private here …") + `StructuralRequirementHere`; NO `ClassInvalidMemberAccess` (the access check is applied to the found result, D-SC-5(b)). `fail_incomplete` and `fail_incomplete_class_param`: `IncompleteTypeInConversion`-class error with the structural context note (the exact kind is whatever `RequireCompleteType`'s caller supplies — this plan supplies a Context note "while checking `HasGet` requirements"; if a reviewer prefers an existing kind, §7 R-6); the class-parameter split reaches the chokepoint through the class's parameter conversion, not deduction, so no `DeductionGenericHere` AMENDED 2026-10-13 (fill round 1, miss (c)): the error line of both incomplete splits is the Context diagnostic `StructuralRequirementIncompleteType` itself ("incomplete type `Inc` cannot satisfy template constraint `HasGet`"), followed by `ClassForwardDeclaredHere` and `InitializingGenericParam`; neither carries `DeductionGenericHere`, since `F(Inc)` passes the type explicitly too |
| check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon (new) | `fail_generic_binding.carbon`: `fn Bad(generic T: HasGet) {}`; `fail_implicit_binding.carbon`: `fn Bad[T: HasGet](x: T) {}`; `fail_implicit_binding_compound_use.carbon` (added 2026-10-06, review fold: B7): `interface I {} fn Bad[T: HasGet & I](x: T) -> i32 { return CallGet(x); }`; `fail_symbolic_arg.carbon`: `fn Caller[U: type](x: U) { CallGet(x); }`; `fail_require_in_interface_symbolic.carbon` (added, B7): `interface I { require impls HasGet; } fn G[T: I](x: T) -> i32 { return CallGet(x); }`; `fail_require_in_interface_blanket.carbon`: `interface I { require impls HasGet; } impl forall [T: type] T as I {}` | First two: `TemplateConstraintOnNonTemplateBinding` at the binding. `fail_implicit_binding_compound_use`: EXACTLY ONE diagnostic, `TemplateConstraintOnNonTemplateBinding` at the binding, and nothing at `CallGet(x)` — D-SC-6's cascade guard (the self's facet type `HasGet & I` lists the requirement). `fail_symbolic_arg`: `ConversionFailureTypeToFacet` (`U` has type `type`, so it is a type, not a facet value) + `StructuralRequirementNeedsConcreteType` + `DeductionGenericHere` (D-SC-6). `fail_require_in_interface_symbolic`: `ConversionFailureFacetToFacet` (`T` is a facet value of type `I`, the fail_convert_facet_value_to_missing_impl.carbon:20-25 shape) + `StructuralRequirementNeedsConcreteType` + `DeductionGenericHere` — the interface-forwarding case rejected per D-SC-6. `fail_require_in_interface_blanket`: `InterfaceRequireImplsNotImplemented` (impl.cpp:946-956 — the interface's own `require` loop; `IdentifiedRequireImplsNotImplemented` :891-904 is the identified-facet-type loop and does not fire here), with NO structural note (D-SC-9; amended 2026-10-06, review fold: A5(ii)) — pinning D-SC-8(iii) for a CHECKED blanket AMENDED 2026-10-13: fill round 1 overturned the exactly-one prediction (miss (b): a MissingGenericFunctionDefinition cascade inside `CallGet`); fill round 2 restores it by giving the diagnosed binding an error type (D-SC-6 amended) and adds `fail_implicit_binding_direct_use`, `fail_implicit_binding_assoc_fn_use`, `fail_wrap_checked_binding` and `fail_extend_require_in_interface_symbolic` (`StructuralRequirementCalled`); `fail_require_in_interface_blanket` filled with no diagnostic at the first fill (the `require` of a facet type naming no interface was dropped) and holds as written since fill round 1 keeps it (D-SC-8(iii)) |
| check/testdata/named_constraint/template_constraint_dependent.carbon (new) | `dependent_caller.carbon`: `fn Outer[template U: type](x: U) -> i32 { return CallGet(x); } fn Test(c: C) -> i32 { return Outer(c); }`; `fail_dependent_caller_unsatisfied.carbon`: `Outer(d)` with `D` lacking `Get` | Positive: in `@Outer` a `call_action` (the call.carbon shape) and no facet value until the specific `Outer(C)` resolves — D-SC-3. Negative: `ResolvingSpecificHere` "unable to monomorphize specific `Outer(D)`" + the `ConversionFailureTypeToFacet` notes located at `CallGet(x)` (the member_access.carbon:43-49 shape) AMENDED 2026-10-13 (miss (g)): the golden has no dump range, so the positive's `call_action` claim was verified by a fill-round-1 probe and is not golden-pinned; the golden pins the positive's absence of diagnostics and the negative's notes |
| check/testdata/named_constraint/template_constraint_compound_access.carbon (new) | `compound.carbon`: `fn F[template T: HasGet](x: T) -> i32 { return x.(HasGet.Get)(); }` + `Test(c: C)`; `fail_compound_unsatisfied.carbon` | Positive: in the specific, a `bound_method %x…, @C.%Get.decl`-shaped call (the type's OWN function, D-SC-4). Negative: the conversion diagnostics at the compound access AMENDED 2026-10-13 (fill rounds 1 and 2, miss (g)): both splits CHECK-failed at eval.cpp:151 on the first fill until D-SC-20's `.Self` lookup; the positive had no dump range at round 1 and is dumped since round 2, where the specific's call binds `name_ref Get, @C.%C.Get.decl`, the type's own function as predicted |
| check/testdata/named_constraint/template_constraint_require.carbon (new) | `require_in_template.carbon`: `template constraint Both { fn Get(self) -> i32; require impls Core.Destroy; }` satisfied by a class; `require_in_interface_concrete.carbon`: `interface I { require impls HasGet; } impl C as I {}` with `C` having `Get`; `require_in_interface_template_blanket.carbon` (added 2026-10-06, review fold: A3): `interface I { require impls HasGet; } impl forall [template T: type] T as I {}` followed by `class Lacking {} fn Use[U: I](x: U) {} fn Test(l: Lacking) { Use(l); }` | Positive. `Both`'s facet value lists ONE witness (`Destroy`), structural check silent. `impl C as I` passes `CheckRequireDeclsSatisfied`. `require_in_interface_template_blanket`: NO STDERR — the template-phase self is deferred at the `require` entry point (D-SC-19), and the specific `Lacking as I` resolves through the blanket impl with no re-check; this split PINS the SC-1 gap named in D-SC-19 and §1.G, so a later re-check lands as a `fail_` rename, not a surprise |
| check/testdata/named_constraint/fail_template_constraint_impl_as.carbon (new) | `fail_impl_as.carbon`: `impl C as HasGet {}` | `ImplOfNotOneInterface` "impl as 0 interfaces, expected 1" (impl.cpp:1026-1029) — F-010m pinned (D-SC-8(ii)) |
| check/testdata/named_constraint/template_constraint_impl_forall_template.carbon (new; added 2026-10-06, review fold: A3) | `ladder.carbon`: `interface NewF { fn DoF(self) -> i32; } impl forall [template T: HasGet] T as NewF { fn DoF(self) -> i32 { return self.Get(); } } fn Test(c: C) -> i32 { return c.DoF(); }` — p002200:605-610's migration-ladder step; `fail_ladder_unsatisfied.carbon`: the same with `class D {}` lacking `Get` and `d.DoF()` | PREDICTED positive (lower-confidence, R-11: no golden in tree has `impl forall [template`): the impl's `[template]`-phase `T` deduces `C` in `EvalLookupSingleFinalWitness`, the `T: HasGet` conversion of the deduced `C` runs the full check at that point (concrete self), and `self.Get()` replays as an `AccessMemberAction`. Negative: `D` fails the `T: HasGet` conversion during impl deduction, so no impl is found — `MissingImplInMemberAccess` (the existing shape) at `d.DoF()`; NO structural note, since impl-deduction probes run `diagnose = false`. If the positive split fails to fill, D-SC-19's break condition applies AMENDED 2026-10-13 (miss (d)): `c.DoF()` cannot name a non-`extend` impl's member; the splits spell p002200's `x.(NewF.DoF)()` inside the changed-constraint `fn G[template T: NewF](x: T)` called as `G(c)` (p002200-template-generics.md:617-634, R27), plus the same call outside a template; both predictions hold, and `G(d)` fails with `ConversionFailureTypeToFacet` and no structural note |
| check/testdata/named_constraint/template_constraint_overload.carbon (new) | `overload.carbon`: `overload fn F[template T: HasGet](x: T) -> i32 { return 1; } overload fn F(x: i32) -> i32 { return 2; }` called with a `C` and with an `i32` (the OV-1 same-file set shape, fork/overload/plan.md §4.A); `overload_catch_all.carbon` (added 2026-10-06, review fold: B2): the §5.A `Pick` set — `[template T: HasGet]` then `[template T: type]` — called with `C` and with `Lacking`, with `//@dump-sem-ir-begin/end` around the caller | Positive, no STDERR: the `i32` call skips member 1 silently (D-SC-12). `overload_catch_all`: the caller shows two `specific_function` lines, `@Pick(%HasGet.facet)` for `C` and the second member's specific for `Lacking` — the golden-side pin of the conformance program's falsifier, filled before the conformance run. Falsifier for a `diagnose` leak |
| check/testdata/named_constraint/template_constraint_import.carbon (new; multi-file) | `a.carbon`: `library "a"; template constraint HasGet { fn Get(self) -> i32; }`; `b.carbon`: `import library "a"; class C {…} fn CallGet[template T: HasGet](x: T)…; fn Test(c: C) …` | Positive; the imports block shows `%Main.HasGet = import_ref Main//a, HasGet, …` and the requirement as a loaded import-ref (D-SC-15). The import_constraint_decl.carbon shape (:12-60) AMENDED 2026-10-13 (miss (g)): the golden has no dump range, so the imports-block claim is not golden-pinned; the golden pins that `b.carbon` checks with no diagnostics |
| lower/testdata/template/template_constraint.carbon (new) | `call_method.carbon`: the §5.A conformance body minus `Core.Print` and minus the overload set (`fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }` returning `CallGet(s)`) — the lower pin is for the dependent method call, not for overload resolution | A `define i32 @…CallGet…(%C …)`-style specific calling `@C.Get` and a caller `define`; no `splice`-related fatal (§1.E); the merging.carbon:241-272 `InitAndCallF` precedent (A8) |
| check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon (added 2026-10-13, fill round 2; recorded POST-FILL at fill round 3, review finding F9) | `fail_implicit_binding_direct_use` (`x.Get()` on `[T: HasGet]`), `fail_implicit_binding_assoc_fn_use` (`Use(x)` with `[T: HasMake & I]`, `Use` calling `T.Make()`), `fail_wrap_checked_binding` (`[T: Wrap]`, `Wrap` a plain constraint that does `require impls HasGet`); `fail_extend_require_in_interface_symbolic` (`x.Get()` on `[T: I]`, `I` doing `extend require impls HasGet`) | As filled at 502e7861a: the first three carry exactly `TemplateConstraintOnNonTemplateBinding` (the error-typed binding, D-SC-6 as amended); the fourth `StructuralRequirementCalled` + `StructuralRequirementHere` |
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon (new at fill round 2; round-2 splits POST-FILL, round-3 splits PRE-FILL, 2026-10-13) | `fail_direct_call` (`HasCount.Count()`, `HasMake.Make()`); `fail_todo_runtime_facet` (`F.Make()`, `F.(HasMake.Make)()` through `let F: HasMake = C`); fill round 3: `fail_impl_member_alias` (`impl C as I { alias F = HasGet.Get; alias Mk = HasMake.Make; }` and `extend impl as I { alias F = HasGet.Get; ... }` in a class `D`, then `c.(I.F)() + d.F()` and `ViaHasF(d)` for a `template constraint HasF { fn F(self) -> i32; }`), `fail_ladder_alias` (`impl forall [template T: HasGet] T as NewF { alias DoF = HasGet.Get; }` with `G(c) + c.(NewF.DoF)()`) | Round 2, as filled: `fail_direct_call` `StructuralRequirementCalled` + `StructuralRequirementHere` twice; `fail_todo_runtime_facet` the same pair for `F.Make()` and `SemanticsTodo` (the fork's runtime-facet TODO, member_access.cpp:987-996) for the compound access. Round 3, predicted before the fill: `fail_impl_member_alias` three `ImplFunctionWithNonFunction` errors, each with `AssociatedFunctionHere` and `StructuralRequirementHere`, nothing at `Use` (the witness entries are errors), and at `UseStructurally` `ConversionFailureTypeToFacet` + `StructuralMemberMismatch` + `StructuralRequirementHere` + `DeductionGenericHere`, lookup of `F` in `D` resolving to the error entry (seen on the review's probe p24 before the fill); `fail_ladder_alias` one such triple and nothing at `Test` FILLED 2026-10-13 (fill round 3, bc8b37290): both round-3 predictions held as written |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (round-2 splits POST-FILL; round-3 changes PRE-FILL, 2026-10-13) | `fail_own_params` (respelled at round 3, review finding F3: `fn Get[unused U: type](unused self) -> i32`, differing from the requirement only by its own parameter); `fail_alias_requirement` (`alias Get = HasGet.Get`); `fail_facet_type_self` (`F(HasCount)`) | Round 2, as filled: `ConversionFailureTypeToFacet` + `StructuralMemberMismatch` + `StructuralRequirementHere` + `DeductionGenericHere` for `fail_own_params`; the same with `StructuralMemberMissing` for `fail_alias_requirement`, and with `StructuralMemberMissing` and `InitializingGenericParam` for `fail_facet_type_self`. Round 3, predicted: `fail_own_params` unchanged in kinds; `StructuralMemberIsRequirement` (naming `HasGet` / `HasCount`) in place of `StructuralMemberMissing` in the other two FILLED 2026-10-13 (fill round 3, bc8b37290): held as written |
| check/testdata/named_constraint/template_constraint_compound_access.carbon (round-2 splits POST-FILL, 2026-10-13) | `assoc_fn_compound` (dumped: `ViaT`, `ViaType`, `ViaFacet`); `fail_assoc_fn_compound_unsatisfied` (`D.(HasMake.Make)()`, comment added at round 3, F9); `checked_generic_name` (dumped) | As filled: the two positives have no STDERR; the negative carries `ConversionFailureTypeToFacet` + `StructuralMemberMissing` + `StructuralRequirementHere` at the compound access |
| check/testdata/named_constraint/template_constraint_require.carbon (round-2 splits POST-FILL; round-3 splits PRE-FILL, 2026-10-13) | Round 2: `fail_require_in_interface_concrete_lacking`, `require_in_constraint`, `fail_require_in_constraint_unsatisfied` (comment added at round 3, F9), `extend_require`, `require_in_interface_in_class_impl`, `fail_require_in_interface_in_class_impl_lacking`, `fail_extend_impl_extend_require_self`. Round 3: `fail_require_mixed_in_class_impl_order` (`require impls HasGet & J` and `require impls J`, each with `impl as J` after the impl); `require_self_class_being_defined` (impls in a nested class whose self is the enclosing class, `Get` after and before the nested class, and `impl D as IU(F)` inside `F` for `IU(U)` doing `require U impls HasGet & J(Self)`, after `F`'s `impl as J(D)`; respelled after the first fill, miss (k)); `fail_require_self_class_being_defined_lacking`; `fail_todo_require_in_interface_in_generic_class_impl` (`Box(T)`, `Outer(T).Inner`, `Box2(template T)`) | Round 2, as filled: `InterfaceRequireImplsNotImplemented` alone for the two `_lacking` splits (the in-class one at the class end); the four positives STDERR-free; `fail_require_in_constraint_unsatisfied` `ConversionFailureTypeToFacet` + `StructuralMemberMissing` + `StructuralRequirementHere` + `DeductionGenericHere`; `fail_extend_impl_extend_require_self` `InterfaceRequireImplsNotImplemented` then `StructuralRequirementCalled` + `StructuralRequirementHere` at `c.Get()`. Round 3, predicted: `InterfaceRequireImplsNotImplemented` at `impl as I1` (`HasGet & J`, which the fill prints as `J & HasGet`) and at `impl as I2` (`J`); no STDERR for `require_self_class_being_defined`; one `InterfaceRequireImplsNotImplemented` at `impl Lacking as I`; and for the generic-class split `InterfaceRequireImplsNotImplemented` for `Box(T)` and for `Inner`, none for `Box2` (D-SC-19) AMENDED 2026-10-13 (fill round 3, bc8b37290, miss (l)): held, except that the `impl as I1` error prints the facet type as `J & HasGet`, not as written; `require_self_class_being_defined` is filled as respelled after miss (k) |
| check/testdata/named_constraint/template_constraint_satisfy.carbon (round-2 splits POST-FILL, 2026-10-13) | `nested_generic`; `as_facet` (dumped); `fail_todo_ambiguous_with_interface` (STDERR only; comment re-cited at round 3, MINOR-4 / F5) | As filled: the two positives STDERR-free; the `fail_todo` split `ResolvingSpecificHere` with the note `NameAmbiguousDueToExtend` |
| lower/testdata/template/template_constraint.carbon (round-2 split POST-FILL; round-3 split PRE-FILL, 2026-10-13) | `compound_nongeneric` (`c.(HasGet.Get)()` in a non-generic `Run`); fill round 3: `impl_member_alias` (`impl C as I { alias F = (C as HasGet).Get; }`, `c.(I.F)()`) | As filled: `compound_nongeneric` a `define` of `Run` calling `C.Get`'s symbol. Round 3, predicted: `impl_member_alias` a `define` of `Run` calling `C.Get`'s symbol directly (no thunk is built, the alias being `C.Get` itself), and no `CARBON_FATAL` (§1.E as amended) FILLED 2026-10-13 (fill round 3, bc8b37290): held; `Run` lowers as `@main` calling `@_CGet.C.Main`, with no thunk and no fatal |

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

### Landed notes (SC-1 commit 1)

Commit 1 (SC-1a, 33b22ecbd) landed on the branch and received its
implementation review (verdict APPROVE-WITH-FIXES: three MINOR findings, no
MAJOR, no BLOCKER); the fixer commit that carries this note folds all three.
The review ran BEFORE any hosted verification, against the §3 order: GitHub
Actions is disabled on the repository, so the hosted `compile` probe and the
autoupdate fill of every §4.A golden are DEFERRED and no fill has run for
commit 1 or for this fix. Every new golden carries `AUTOUPDATE` and no CHECK
lines, the two pre-existing goldens of §6 have their CHECK lines cleared, and
the diagnostics coverage test (two new kinds) and the parse coverage test
(`TemplateModifier`) stay expected red until the fill lands (R19). Nothing
below claims a fill; every prediction is a hand trace (R9).

-   Finding 1 (MINOR, confirmed): error recovery after
    `NamedConstraintRedeclTemplateMismatch` was unspecified. D-SC-16 asks only
    for the diagnostic, and commit 1 kept the FIRST declaration's flag, so
    `constraint X; template constraint X { fn G(self); }` diagnosed the mismatch
    and then one `FunctionInNonTemplateConstraint` per member, while the reverse
    order silently collected `G` as a requirement, and neither direction was
    pinned (the §4.A row 3 splits have empty bodies). ACCEPTED, reviewer option
    (a): after the diagnostic, `BuildNamedConstraintDecl` sets the stored
    entity's `is_template` to true (handle_named_constraint.cpp, one
    assignment), so both directions recover as a template constraint, the
    permissive mode, and no member diagnostic cascades. `MergeDefinition` still
    leaves the flag uncopied (its comment now says why). Two splits are added to
    fail_template_constraint_redecl.carbon so the fill pins the recovery,
    amending §4.A row 3 from two splits to four:
    `fail_decl_then_template_def_member.carbon` (`constraint X; template
    constraint X { fn G(self); }`) and
    `fail_template_decl_then_def_member.carbon` (`template constraint X;
    constraint X { fn G(self); }`). Prediction for each: exactly one error,
    `NamedConstraintRedeclTemplateMismatch` "redeclarations of `constraint X`
    must match use of `template`" at the second declaration, plus the
    `RedeclPrevDecl` note at the first; NO `FunctionInNonTemplateConstraint`;
    `G` is collected into `structural_members_id` under a template-phase `Self`.
    The D-SC-16 text stands as written (diagnose); this note specifies the
    recovery it left silent.
-   Finding 2 (MINOR, confirmed): commit 1's body lists four line drifts
    against the plan and omits a fifth. Drift (5), recorded here and in the
    fixer commit's body, with commit 1 left unamended (rulebook: never rewrite
    submitted history): §2.A.3 says `MergeDefinition` "asserts `is_template`
    equality — the check diagnosed it first", but `MergeDefinition` runs
    inside `TryMergeRedecl` (merge.cpp:937) BEFORE control returns to the
    D-SC-16 comparison in `BuildNamedConstraintDecl`, so such an assert would
    fire ahead of the diagnostic; the implementer correctly dropped the assert
    and leaves the flag uncopied, and the comparison diagnoses it afterwards
    (and, after finding 1, recovers as template). The sem_ir paragraph of
    commit 1's body disclosed the behavior but not the departure from §2.A.3.
-   Finding 3 (MINOR, not confirmed as reachable): `AddStructuralMembers`
    (import_ref.cpp) read every block entry with
    `GetAs<SemIR::FunctionDecl>`, whereas the sibling idiom it cites,
    `AddAssociatedEntities`, switches on the kind and also accepts an
    `AnyImportRef` (name from `import_entity_names()`). An imported IR whose
    constraint entity was itself localized from a further import would hold
    import-refs in that block and CHECK-fail; reachability was not
    demonstrated (the resolver canonicalizes to the owning IR and the §4.B
    import golden is single-hop). ACCEPTED as defensive parity and folded now
    rather than riding commit 2: a `CARBON_KIND_SWITCH` with a `FunctionDecl`
    arm, an `AnyImportRef` arm and a fatal default, mirroring
    `AddAssociatedEntities`.

Verification for the fixer commit, same harness as commit 1 (no bazel run,
no fill): clang++ -fsyntax-only with the toolchain's -Werror set against the
pinned LLVM headers, OK on handle_named_constraint.cpp and import_ref.cpp and,
as consumers of the touched header or the merge template, handle_require.cpp,
type_completion.cpp, sem_ir/name_scope.cpp, sem_ir/named_constraint.cpp,
merge.cpp and handle_function.cpp; prek (clang-format 21.1.8, header guards,
check-toolchain-diagnostics, codespell, copyright) at a fixpoint over every
touched file. The R12 hook's container clang-format is 18.1.3, which
reformatted unrelated function signatures in handle_named_constraint.cpp and
import_ref.cpp on edit; the pinned 21.1.8 under prek restored every one of
them (the committed diff touches only the lines named above), so prek remains
the arbiter (R18).

R31 record for this note: before, 1 H1 / 12 H2 / 19 H3 / 0 H4, 73 dash items,
53 numbered items (identical to the rev 2 record); after, 1 / 12 / 20 / 0, 76
dash, 53 numbered: exactly this subsection's heading and its three findings,
nothing manufactured; the hazard greps are empty before and after.

### Landed notes (SC-1 commit 2)

Commit 2 (SC-1b, 1f207c892) landed on the branch and received its
implementation review (verdict APPROVE-WITH-FIXES: one MAJOR, six MINOR of
which one unconfirmed, no BLOCKER); the fixer commit that carries this note
folds all seven, extending the commit-1 note above. As for commit 1, the review
ran BEFORE any hosted verification: GitHub Actions is disabled on the
repository, so the autoupdate fill of every §4.B and §4.C golden is DEFERRED
and no fill has run for commit 2 or for this fix. Every new golden and split
carries `AUTOUPDATE` and no CHECK lines; the diagnostics coverage test (seven
kinds from commit 2) stays expected red until the fill lands (R19). Nothing
below claims a fill; every prediction is a hand trace (R9).

-   Finding 1 (MAJOR, confirmed): a member of a GENERIC class specific never
    satisfied a method requirement. D-SC-5(d) calls the matcher "byte-for-byte
    the thunk criterion", and the thunk.cpp:462-468 caller IS that criterion
    only because there both sides live in the impl's own generic (the impl's
    `self` type is symbolic on both sides). At the chokepoint the self is
    concrete and the member symbolic in its class's generic: for `class Box(T:
    type) { fn Get(self) -> i32 }` and a `Box(i32)` argument,
    `FindStructuralMember` returns a `SpecificConstant{Get, Box(i32)}` whose
    `GetCallee` carries `enclosing_specific_id`, but `CheckRedeclParam`
    (merge.cpp) compared the member's RAW pattern type `Box(T)` with the
    requirement's substituted `Self := Box(i32)` and
    `CheckFunctionReturnTypeMatches` (function.cpp) read the member's return
    type unsubstituted, so every generic-class specific was a silent
    `StructuralMemberMismatch`. No §4.B split used a generic self, so the fill
    would not have caught it. ACCEPTED, the reviewer's fix: a trailing
    `new_specific_id` (default `SpecificId::None`, so every existing caller is
    unchanged — each passes its arguments positionally ahead of the new default)
    threaded through `CheckFunctionTypeMatches`,
    `CheckFunctionReturnTypeMatches` (function.{h,cpp}),
    `CheckRedeclParamsMatch` and the three static helpers below it
    (merge.{h,cpp}); the new side is read in its specific with
    `GetConstantValueInSpecific` / `GetTypeOfInstInSpecific`, exactly as the
    prev side already was, and `new_function.GetDeclaredReturnType(sem_ir,
    new_specific_id)`; `RequirementMatches` passes the member's
    `enclosing_specific_id`. D-SC-5(d) is CORRECTED by this note: the criterion
    is the thunk criterion with BOTH sides read in their own specifics. §4.B
    amendments: template_constraint_ satisfy.carbon gains `generic_self.carbon`
    (`class Box(T: type) { fn Get(self) -> i32 }`, `fn Test(b: Box(i32)) -> i32
    { return CallGet(b); }`; predicted no STDERR, no dump range — the fork's
    generic-class spelling is `class C(T: type)`,
    class/method/generic_method.carbon:15) and
    fail_template_constraint_unsatisfied.carbon gains
    `fail_generic_self_wrong_return.carbon` (`fn Get(self) -> T;` with
    `Box(bool)`; predicted `ConversionFailureTypeToFacet` for `Box(bool)` +
    `StructuralMemberMismatch` at the member declaration +
    `StructuralRequirementHere` + `DeductionGenericHere`). §6's source-file list
    gains function.{h,cpp}; merge.{h,cpp} were already commit 1's drift (1).
-   Finding 2 (MINOR, confirmed): commit scope against §3. The §4.C interop
    golden (a commit-3 deliverable, §2.C item 1) landed in commit 2 with all
    four splits negative, and the §2.B.9 / §3 item 2 / D-SC-14 deliverables
    (the §5.A conformance rewrite and un-SKIP, gap row 55 → PARTIAL, ledger
    W-027) were omitted, each disclosed in the body but nowhere in the plan.
    ACCEPTED as recorded here; commit 2 is not amended (never rewrite submitted
    history). (a) D-SC-11's break condition fired at implementation time, by a
    mechanism the plan did not foresee: an imported C++ method NAME resolves to
    a `cpp_overload_set_value` (interop/cpp/class/import/method.carbon
    :279-280), which D-SC-5(c) / A10 classifies as `CalleeCppOverloadSet` → a
    mismatch, so NO C++ class satisfies any method requirement under the
    commit-2 predicate. Owner decision, auto-adopted under R29(a) and veto-able
    after the fact: the D-SC-5(c) predicate is EXTENDED to look through a
    `CalleeCppOverloadSet` whose `candidate_functions` holds exactly one member
    to that member's imported function (the `fn (ref self)` thunk of §0.1 row
    19, imported through check/cpp/import.h's declaration entry point) and to
    match it under D-SC-5(d); a set with two or more candidates stays a
    mismatch (`fail_overloaded` keeps its name). This lands in SC-1c together
    with §4.C and §5.B, where the golden's `fail_todo_satisfy` and
    `fail_todo_const_method` splits revert to `satisfy` and `const_method` and
    the §4.C predictions are re-traced; if the imported function's `self`
    pattern then still cannot match (the break condition D-SC-5 and D-SC-11
    originally named), the SKIP fallback of D-SC-11 and the residue "C++ method
    `self` qualifiers in structural matching" stand. (b) The §5.A conformance
    rewrite and un-SKIP, gap row 55 and the W-027 ledger edit move from SC-1b
    to SC-1c; the D-SC-14 arbiter order is preserved, since
    `template_constraint_overload.carbon`'s `overload_catch_all` split is
    already committed and fills before any conformance run. §3 is read with
    these two moves; the R31 count diff of that commit stays with it.
-   Finding 3 (MINOR, confirmed): the compound-access redirect ran with
    diagnostics unconditionally on while its caller
    `PerformCompoundMemberAccessAction` carries `diagnose` from operator.cpp's
    probes — R-7 ("`diagnose = false` must be total") violated by construction,
    unreachable today only because those probes pass interface members, which
    never reach the redirect. ACCEPTED: `diagnose` is threaded into
    `RedirectStructuralRequirementAccess` — `ConvertToValueOfType(…, diagnose)`,
    then `LookupMemberNameInTypeScopes(…, required = diagnose, the scope's
    `AccessInfo`, diagnose, &info)` returning `ErrorInst` silently when nothing
    is found, and the generic-constraint `context.TODO` gated the same way.
-   Finding 4 (MINOR, confirmed): `impl C as I & HasGet {}` is accepted with NO
    structural check of the impl's self: `CheckRequireDeclsSatisfied`
    (impl.cpp) walks the identified facet type's `required_impls()` only, and
    the structural entries never reach `LookupImplWitness`. Not unsound (a later
    `T: I & HasGet` conversion of `C` runs the check), but undiagnosed and
    unpinned. ACCEPTED as the reviewer's second option — pin and file —
    because the first (a check in impl.cpp) would cross D-SC-3 ("inside
    `LookupImplWitness`, and nowhere else"), §2.B / §6 (impl.cpp untouched) and
    A5(ii) (impl.cpp's emits stay note-less in SC-1): split
    `todo_fail_impl_as_interface_and_template.carbon` added to
    fail_template_constraint_impl_as.carbon (predicted no STDERR; the
    container's own `fail_` prefix is enforced only when every split succeeds,
    testing/file_test/file_test_base.cpp:134-173, so a positive split beside
    `fail_impl_as` is well-formed), and the residue "structural requirements on
    an impl's `as` facet type" is added to §1.G by this note.
-   Finding 5 (MINOR, confirmed): a private method inherited from a base class
    was explained as `StructuralMemberMissing`: with `access_info = nullopt` a
    hit in an extended scope synthesizes a Protected `AccessInfo`
    (name_lookup.cpp, the `is_parent_access` branch), the private hit goes into
    `prohibited_accesses`, the walk finds nothing else and `LookupQualifiedName`
    returns `MakeError()` silently. ACCEPTED: `LookupResult` gains
    `prohibited_access_kind` (the last prohibited hit's access, set only on that
    error return), `MemberLookupInfo` gains `found_but_prohibited`, and
    `CheckRequirementFunction` reports such a miss as `Inaccessible` with that
    access kind. Split `fail_private_base.carbon` added to
    fail_template_constraint_unsatisfied.carbon (`base class B { private fn
    Get(self) -> i32 }`, `class C { extend base: B; }`; predicted
    `ConversionFailureTypeToFacet` for `C` + `StructuralMemberInaccessible`
    "member `Get` of type `C` is private here …" at the call +
    `StructuralRequirementHere` + `DeductionGenericHere`). Observation recorded,
    not decided: an inherited PUBLIC method does not satisfy either, because the
    matcher compares the member's `self` type (`B`) with `Self := C` exactly;
    unpinned, a residue candidate for the SC-1c discharge ("inherited methods
    in structural matching").
-   Finding 6 (MINOR, not confirmed): re-entrant impl lookup from inside the
    structural check (`class D { impl as A {…} alias F = A.F; }` plus a blanket
    `impl forall [template T: HasF] T as A`), with `PerformImplLookup` calling
    `LookupImplWitness` at its default `diagnose = true`. ACCEPTED in part:
    `diagnose` is now forwarded to that call (R-7). REJECTED in part, with
    evidence, for "skip a requirement whose lookup would re-query a pair on
    `impl_lookup_stack`": (a) in the reviewer's shape the blanket impl is never
    probed for `D` — `CollectCandidateImplsForQuery` sorts candidates
    most-specific first (impl_lookup.cpp:803-816, a concrete `impl D as A`
    ahead of a `forall` impl) and both `FindNonFinalWitness` (:941-955) and
    `EvalLookupSingleFinalWitness` (:1323-1343) stop at the first witness, so
    no re-entry occurs; (b) in the variant WITHOUT `D`'s own impl the shape is a
    genuine acyclic-rule violation (`D.F` needs `D as A`, which needs `D:
    HasF`, which needs `D.F`), and upstream diagnoses impl-lookup cycles
    unconditionally by design ("Cycles are diagnosed even if they are found when
    diagnostics are otherwise being suppressed", impl_lookup.cpp:1046-1047), so
    reading it as silently unsatisfied would hide a cycle upstream wants
    reported. Pinned as `fail_alias_cycle.carbon` in
    fail_template_constraint_unsatisfied.carbon, predicted: `ImplLookupCycle`
    "cycle found in search for impl of `A` for type `D`" at `d.F()` with the
    `ImplLookupCycleNote` at the blanket impl, then `MissingImplInMemberAccess`
    at `d.F()` (the outer lookup finds no witness; the cycle sets
    `diagnosed_cycle` on the outer entry, so it is reported once).
-   Finding 7 (MINOR, confirmed): a side effect A5(i) did not state. Every
    miss poisons the requirement's name in the self type's class scope and in
    each walked base scope (`LookupNameInExactScope` →
    `NameScope::LookupOrPoison`), including during overload probes and the
    explain re-run; a poisoned entry prints as `.Get = <poisoned>` in
    `!members:` under a dump range. Harmless (every probed scope is complete,
    so `DiagnosePoisonedName` cannot fire), and none of the three
    pre-registered dump ranges includes a probed class, so no committed
    prediction moves — but the commit-2 body's "no SemIR trace from the check"
    is incomplete by exactly this. Rule from here: positive dump ranges stay
    away from classes the check probes (`Lacking` in overload_catch_all.carbon
    and fail_missing.carbon carry the poison).

§1.G addition by this note: "structural requirements on an impl's `as` facet
type" (finding 4); candidate, not yet filed: "inherited methods in structural
matching" (finding 5's observation).

Verification for the fixer commit, same harness as commits 1 and 2 (no bazel
run, no fill): clang++ -fsyntax-only with the toolchain's -Werror set against
the pinned LLVM headers, OK on all 46 files — the five changed .cpp (merge,
function, name_lookup, member_access, structural_conformance) and every .cpp
that includes merge.h, function.h, name_lookup.h, member_access.h or
structural_conformance.h — run once before prek (one failure: the fork's OV-3
`CheckRedeclExplicitParamsAfterSelfMatch` is a seventh caller of the static
`CheckRedeclParamLists`, fixed by passing `None`) and once more on the
post-prek tree; prek (clang-format 21.1.8, header guards,
check-toolchain-diagnostics, rumdl, google-doc-style, codespell, copyright,
links) at a fixpoint over every touched file (pass 1 reformatted the C++ and
reflowed one line of this note; passes 2 and 3 clean). The R12 hook's
clang-format 18.1.3 and the pinned 21.1.8 disagreed on the same files as for
commit 1; prek remains the arbiter (R18).

R31 record for this note: before, 1 H1 / 12 H2 / 20 H3 / 0 H4, 76 dash items,
53 numbered items (identical to the commit-1 record); after, 1 / 12 / 21 / 0,
83 dash, 53 numbered: exactly this subsection's heading and its seven findings,
nothing manufactured; the hazard greps are empty before and after.

### Landed notes (SC-1 commit 3)

Commit 3 (SC-1c, 43575bf1d) landed on the branch and received the ONE
implementation review R29(c) owes (verdict APPROVE-WITH-FIXES: seven MINOR, no
MAJOR, no BLOCKER); the fixer commit that carries this note folds all seven,
extending the two notes above. As before, the review ran BEFORE any hosted
verification: no fill, gate or conformance run exists for any SC-1 commit, every
golden still carries `AUTOUPDATE` and no CHECK lines, and nothing below claims a
measurement (R9). The review's verified-clean list (the look-through inside
`LookupImplWitness`, the refined D-SC-11 rule against the call-site import, R27
spelling fidelity of the page, the port's diff against 481e08c24, both
conformance programs' falsifier shape and hand-derived EXPECTs, the record SHAs
and counts, the ledger ids, gap row 55, the Branches row, the design-record
repair, the whole-branch toolchain scope, golden coverage of all nine kinds and
every D-SC, trailers and no model identifiers) stands as the review stated it.

-   Finding 1 (MINOR, confirmed): the page's §Diagnostics paragraph said each
    of the four notes, `StructuralRequirementNeedsConcreteType` included, is
    "followed by `StructuralRequirementHere`"; the code emits
    `StructuralRequirementNeedsConcreteType` in `CheckRequirements`'
    checked-symbolic branch and returns before the per-`fn` loop, so
    `NoteMemberFailure` (the only `StructuralRequirementHere` emitter) never
    runs — the plan's own §4.B `fail_symbolic_arg` prediction agrees. ACCEPTED,
    reworded as the reviewer proposed: the three member notes are each followed
    by `StructuralRequirementHere`; for a checked-generic self the single note
    `StructuralRequirementNeedsConcreteType` is attached instead (R27).
-   Finding 2 (MINOR, confirmed): the port split "This design was fixed by fork
    decision F-010 … and depends on several unimplemented toolchain features"
    into two paragraphs by inserting the fragment-stripping HTML comment
    between them (the stranded page had one sentence). ACCEPTED: the comment
    moved to just before the paragraph and the sentence is rejoined; a
    paragraph move only — the page's counts are unchanged (below).
-   Finding 3 (MINOR, confirmed): the SC-1 decision-log entry's "(9) GOLDENS"
    said "fifteen new files" while enumerating sixteen, and `git diff
    --name-status origin/trunk..HEAD -- 'toolchain/*/testdata/*'` shows sixteen
    added files (plus the two modified §6 goldens). ACCEPTED: "sixteen".
-   Finding 4 (MINOR, confirmed): the gap analysis's W7 paragraph kept "needs
    a real design first (templates.md is a placeholder)" beside the appended
    "landed … the design is template_constraints.md, and templates.md now links
    it" — §8.5 asked only for the appended sentence, but the sentence it
    contradicts is one SC-1 made false. ACCEPTED: the two sentences are
    rewritten as one ("has its design in docs/design/generics/
    template_constraints.md (F-010; member requirements, B1, landed on the SC-1
    branch 2026-10-12 with the fill pending — fork/structural/plan.md);
    templates.md links it."); the "lowering hits CARBON_FATAL" sentence stays
    UA-2's, as the plan says. Counts unchanged (prose only).
-   Finding 5 (MINOR, confirmed by code reading): R-7 ("`diagnose = false` must
    be total") is violated by construction in the SC-1c look-through —
    `ImportSingleCppOverloadCandidate` calls `ImportCppFunctionDecl` in both
    check modes, and the C++ import emits unconditionally (cpp/import.cpp:2152
    "Unsupported: Template function", :2213 the fenced-thunk TODO, :1654 and
    :1786 the type-mapping TODOs); the two shape checks narrow the exposure but
    do not close it, so a one-candidate `Get` of the right arity with an
    unmappable parameter type emits during the silent member-1 probe of the
    two-member `Pick` set and the program is COMPILE-FAIL instead of selecting
    member 2 — the commit-2 finding-3 class, reachable only through interop,
    with no golden. ACCEPTED exactly as the reviewer asked, the import NOT gated
    on `diagnose` (the §5.B program's own member-1 probe is a `diagnose =
    false` path and must import): (a) residue W-151 "C++ member import inside a
    non-diagnosing structural probe can emit (R-7)", blocked_by [], citing the
    import.cpp sites, the mechanism being to thread `diagnose` into
    `ImportCppDecl` (check/cpp/, untouched by §2.C) — W-151 is allocated above
    W-143 under the same cross-branch assumption as W-134..W-143; (b) split
    `fail_todo_probe_import_leak.carbon` added to interop/cpp/class/import/
    template_constraint.carbon with its own header `unmappable_param.h`
    (`struct BitGetter { int Get(_BitInt(23) n); }`, the
    param_unsupported.carbon shape) and the two-member `Pick` set over
    `HasGetN { fn Get(ref self, n: i32) -> i32; }`; predicted exactly one
    diagnostic, `SemanticsTodo` "Unsupported: parameter type: _BitInt(23)"
    located at the member-1 probe (the conversion of `b` in `Pick(b)`), member 2
    selected regardless — the overload probe runs in a discard scope with no
    diagnostic suppression (call.cpp `ProbeOverloadCandidate`), so the TODO
    reaches the consumer; (c) the look-through's comment now states that the
    import is not `diagnose`-aware, why it is not gated, and the residue's
    mechanism. The twelve comment lines shift the file below them: W-143's cite
    (`RequirementMatches`) moves :281 → :293, W-027's (`CheckRequirements`) :418
    → :430, and the decision-log's look-through range is re-cited :167-282;
    the cpp diff is comment-only (twelve added lines, nothing else).
-   Finding 6 (MINOR, confirmed): §8.7 (review fold B15) lists the status
    paragraph among the stamps the discharge updates, and commit 3's deviation
    (4) left it reading "Last updated: 2026-10-06" with a NEXT list silent on
    the open, HELD SC branch one row below. ACCEPTED, the reviewer's first
    option: one dated sentence appended to the status paragraph ("Appended
    2026-10-12 (SC-1 commit-3 fold): SC-1 … is OPEN on claude/carbon-fork-0-1-sc
    and HELD awaiting the fork toolchain's autoupdate + gate + conformance — see
    the Branches row; no measured numbers yet, so the floor above stands"), and
    the Branches row now counts three fixer commits and W-134..W-143 and W-151.
    Deviation (4) of the commit-3 body is thereby withdrawn for the status
    paragraph and stands for the Scoreboard section and the floor (no measured
    numbers exist, R9), which is a narrower reading of §8.7, recorded here
    rather than as an amendment of the signed-off plan. Counts unchanged.
-   Finding 7 (MINOR, confirmed): the page's 0.1 limits said "filed as a ledger
    residue" without an id at F-010l (:270), F-010b and the associated-constant
    deferral (:288), the `impl … as I & SomeTemplateConstraint` gap (:448) and
    the F-010l sub-fork entry (:932), while the ledger carries W-134..W-137 and
    W-142 for exactly these; and D-SC-16 (redeclarations must agree on
    `template`) appeared nowhere on the page. ACCEPTED: W-136, W-134, W-135,
    W-142 and W-136 appended in place, and one sentence under §Declaring a
    template constraint beside the completeness-rules link states the D-SC-16
    rule, its diagnostic `NamedConstraintRedeclTemplateMismatch` and the
    commit-1 recovery (treated as a template constraint after the diagnostic).

§1.G addition by this note: "C++ member import inside a non-diagnosing
structural probe can emit (R-7)" (finding 5; W-151).

Verification for the fixer commit, same harness as commits 1-3 (no bazel run,
no fill): clang++ -fsyntax-only with the toolchain's -Werror set against the
pinned LLVM 21.1.8 headers, OK on structural_conformance.cpp before and after
prek's clang-format (the R12 hook's clang-format 18.1.3 again reformatted
unrelated lines on edit and the pinned 21.1.8 under prek restored them, R18);
prek (rumdl, google-doc-style, markdown-toc, prettier on the ledger,
clang-format, check-toolchain-diagnostics, codespell, copyright, check-links)
at a fixpoint over every touched file (pass 1 reformatted only the C++ the hook
had drifted; pass 2 clean); `runner.py --self-test` OK (151 programs; no
program changed); the ledger parses and W-151 is the unique maximum id.

R31 record for this note (H1/H2/H3/H4, dash items, numbered items): plan.md
before 1 / 12 / 21 / 0, 83 dash, 53 numbered (identical to the commit-2
record); after 1 / 12 / 22 / 0, 90 dash, 53 numbered — exactly this
subsection's heading and its seven findings (the §1.G addition is a
paragraph, not an item). The other
files are unchanged before and after: template_constraints.md 1/12/19/0/0, 83,
3 (the comment move and the appended ids add no item); decision-log.md
1/2/44/1/6, 23, 0 (its one hazard-grep hit is the pre-existing trunk heading
"7700 splice-stepping …", UA-2's, untouched); gap-analysis.md 1/5/23/0/0, 0;
ORCHESTRATION.md 1/1/5/0/0, 8, 4. The hazard greps over the diff are empty.

### Landed notes (SC-1 fill rounds, 2026-10-13)

The fills ran on 2026-10-13 on the container-built toolchain (the carbonbuild
scripts: a fastbuild of the branch with Carbon's assertions on, the pinned LLVM,
file_test and the conformance runner), not on hosted runners: Actions stays
disabled, the upstream nightly lacks the feature, and R28 keeps the owner's
machine out. Fill round 1 is 1a7cce0b2 (four toolchain fixes, two test-source
corrections), bcaeadb98 (the goldens) and 2f4ebbf6e (records); its two
implementation reviews (APPROVE-WITH-FIXES both: 3 MAJOR and 5 MINOR, 5 MAJOR
and 6 MINOR, no BLOCKER) are folded by fill round 2: 6f2f40d3c (fixes and test
sources), 502e7861a (the goldens, autoupdated by the toolchain built from
6f2f40d3c with a clean tree, `carbon version` 0.0.0-0.dev+6f2f40d3c) and
cb85e6b8b (records, this note's first version). Measured at round 2: autoupdate
to fixpoint over the 19 SC-1 goldens (pass 1 rewrote 11, pass 2 rewrote 4 with
`locNN` renumbering only, pass 3 none); file_test over all toolchain testdata
1959 passed, 0 failed; conformance into a private outdir 130 PASS / 0 FAIL / 21
SKIP of 151, bullets 49/56, exactly generics/structural_conformance (SKIP to
PASS, `42` then `7`) and interop/cpp_structural_conformance (PASS, `7` then `0`)
moving. Fill round 3 folds round 2's two implementation reviews: 0efe76e7d
(fixes, test sources, the design page, records), bc8b37290 (4 goldens refilled)
and 5171e5eda (records); it re-measured the same totals on the toolchain stamped
0.0.0-0.dev+bc8b37290 (below). Not of record until
fork/conformance/out/scoreboard.json is updated (R9).

Fill-caught misses (a reviewed prediction a fill overturned; the plan text each
one falsified carries a dated amendment above):

-   (a) §4.A parse row: the tree prints `NamedConstraintIntroducer` before
    `TemplateModifier`, the class/introducer.carbon:30-31 placement.
-   (b) §4.B checked-binding row and D-SC-6: "exactly one diagnostic" failed at
    round 1 (a `MissingGenericFunctionDefinition` cascade inside `CallGet`'s
    template body, reached through the cascade guard); round 2 restores it with
    an error-typed binding, and the guard is deleted.
-   (c) §4.B unsatisfied row, the two incomplete-type splits: the error line is
    R-6's Context diagnostic `StructuralRequirementIncompleteType`, followed by
    `ClassForwardDeclaredHere` and `InitializingGenericParam`.
-   (d) §4.B ladder row: `c.DoF()` cannot name a non-`extend` impl's member;
    the splits use p002200's qualified call, and round 2 ports its
    changed-constraint `G` (R27).
-   (e) the "No STDERR" positive rows carried upstream's `UnusedBinding`
    warnings at round 1; round 2 spells `unused` on those bindings, so the rows
    hold as written.
-   (f) satisfy `method`: the facet value and its conversion print twice
    (deduction, then the argument), upstream's shape.
-   (g) compound, dependent and import rows: no dump range at round 1. Round 2
    dumps `compound` (the specific binds `@C.%C.Get.decl`, the D-SC-4 claim)
    and adds dumped `assoc_fn_compound` and `checked_generic_name` splits;
    dependent and import stay STDERR-only, their positive claims being the
    absence of diagnostics.
-   (h) D-SC-10's "Nothing in SC-1 depends on the phase" was false for a
    requirement named with no self; D-SC-20.
-   (i) §1.B.2's "the action resolves in the concrete type" was false for an
    access on the facet value itself; the D-SC-4 redirect of round 1.
-   (j) round 2's first fill: two new fail splits shared a library name with a
    positive split of the same file (`[[@TEST_NAME]]` drops `fail_`), so they
    were renamed `..._lacking` before 6f2f40d3c.
-   (k) round 3's first fill: the positive split
    `require_self_class_being_defined` first spelled its other-self `require` as
    `require U impls HasGet`, which upstream rejects
    (`RequireImplsMissingSelfEmptyFacetType`: a `require` must name `Self`);
    respelled `require U impls HasGet & J(Self)`, the review's own probe shape,
    with `F`'s `impl as J(D)` first, before the round-3 commit.
-   (l) round 3's fill: the §4.B require row predicted the `impl as I1` error
    naming the facet type as written, `HasGet & J`; the fill prints `J &
    HasGet`. A prediction error; the row carries a dated amendment.

Round 1's four mechanisms (1a7cce0b2), each now golden-pinned: the member's own
specific in `RequirementMatches` (satisfy `generic_self`, `nested_generic`;
unsatisfied `fail_generic_self_wrong_return`, `fail_own_params`); the `.Self`
lookup, D-SC-20 (compound `checked_generic_name`, lower `compound_nongeneric`);
the D-SC-4 redirect of a requirement found for a concrete self (satisfy
`assoc_fn` and `as_facet`, both dumped); a `require` kept for a facet type with
structural requirements, D-SC-8(iii) (require
`fail_require_in_interface_concrete_lacking`, `require_in_constraint`,
`fail_require_in_constraint_unsatisfied`, `extend_require`; checked-binding
`fail_wrap_checked_binding`).

Round 2, by review finding (review 1 MAJOR-n / MINOR-n, review 2 Fn / Mn):

-   MAJOR-1: compound access of an associated-function requirement converts the
    base itself, as Step 2b does for an interface's non-instance member, and
    looks the name up in that facet's type (member_access.cpp
    `RedirectStructuralRequirementAccess`); compound `assoc_fn_compound`,
    `fail_assoc_fn_compound_unsatisfied`.
-   MAJOR-2 / F1: D-SC-6 and §1.B.1 amended (error-typed binding, guard
    deleted); checked-binding `fail_implicit_binding_compound_use`,
    `fail_implicit_binding_direct_use`, `fail_implicit_binding_assoc_fn_use`.
-   MAJOR-3: D-SC-8(iii) amended (an in-class impl's structural `require` is
    checked at the end of the class: impl.cpp
    `IsStructuralRequireDeferredToClassEnd`, replaced at round 3 by
    `GetRequireSelfClassBeingDefined`, and
    `CheckDeferredRequireDeclsAtClassEnd`, handle_class.cpp); require
    `require_in_interface_in_class_impl` and
    `fail_require_in_interface_in_class_impl_lacking`. An in-class impl in a
    GENERIC class still fails, at the class end instead of the impl, because its
    self is checked-symbolic (D-SC-6, W-139).
-   MINOR-1 / F2: a found member that is itself a requirement `fn` is Missing
    (structural_conformance.cpp `CheckRequirementFunction`, D-SC-5(b)), and
    merge.cpp's same-block early return no longer short-circuits two different
    specifics; unsatisfied `fail_alias_requirement`, `fail_facet_type_self`,
    require `fail_extend_impl_extend_require_self`.
-   MINOR-2: D-SC-9 amended (`StructuralRequirementCalled`, call.cpp);
    fail_template_constraint_requirement_call.carbon (new) and checked-binding
    `fail_extend_require_in_interface_symbolic`. The `.Self`-typed conversion
    diagnostics review 2 quoted (F4) no longer occur: those calls now stop at
    the new error.
-   MINOR-3: kept as a residue, the reviewer's second option. A name found
    through a template constraint and through an interface the type implements
    is still ambiguous although both resolve to the same function
    (p002200:385-399): `LookupQualifiedName` decides ambiguity across extended
    scopes before the D-SC-4 redirect, the same order as upstream's own TODO for
    an associated entity and its impl member (member_access.cpp, "a lookup that
    finds an associated entity and also finds the corresponding impl member is
    not supposed to be treated as ambiguous"). Pinned by satisfy
    `fail_todo_ambiguous_with_interface`; residue title "lookup ambiguity
    between a template-constraint requirement and the same function found
    through an interface", id pending (SC-1 holds no reserved id above W-151;
    W-152..W-159 are EV-1's, ST-1 starts at W-160), allocated by the
    orchestrator at landing.
-   MINOR-4 / F3: the splits named above, plus dumps on satisfy `assoc_fn` and
    compound `compound`.
-   F4: D-SC-20 recorded; the two code comments that cited D-SC-4 for it now
    cite D-SC-20.
-   F5 / MINOR-5: this note, the dated amendments above, W-027's title,
    evidence and notes, the golden and source re-cites of W-134..W-143 and
    W-151, the Branches row and status paragraph, and the decision-log appendix.
-   M1: the `generic_self` and `fail_generic_self_wrong_return` comments say the
    member is read in its own specific. M2: `unused` (above). M3:
    `RequirementMatches` uses `CopySpecificToGeneric` after its count guard.
    M4: member_access.h documents the redirect;
    `GetSelfFacetForInterfaceFromLookupSelfType` calls `HasLookupSelfType`. M5:
    the ladder port (above). M6: the round-2 toolchain is stamped with its
    commit and a clean tree.

§1.G addition by this note: the MINOR-3 residue above.

Rejected or narrowed, with evidence: none of the 19 findings is rejected.
Review 1 MINOR-1's suggested `ErrorInst` for a redirected lookup that finds the
requirement again is not taken: the requirement is kept, and the two places it
can do harm are closed instead (a type whose lookup finds only a requirement
does not satisfy, `CheckRequirementFunction`; a requirement is never called,
`StructuralRequirementCalled`), pinned by
`fail_extend_impl_extend_require_self`. Four probes from the reviews abort the
toolchain (`impl forall [template T: Core.Copy] Box(T) as I(T)`, and an
explicit-template-parameter call `G(i32, C, c)` of `fn G(template U: type,
template T: Has(U), x: T)`), and each aborts identically on the trunk build of
0bdce60a5 with an interface in place of the template constraint (check: "impl
as non-facet type `<splice of ...>`"; lower: type.cpp:459 "Found symbolic type
id after resolution"), so they are upstream's, not SC-1's.

Added 2026-10-13 by the fill-rounds records commit, which renamed this note from
"Landed notes (fill rounds 1 and 2)"; the decision log's "SC-1 fill rounds
(2026-10-13)" entry states the same facts.

Round 1's four defects as R29(a) implementation decisions, each with its design
citation and break condition (the paragraph "Round 1's four mechanisms" above
names the splits that pin them):

-   **Member specific** (structural_conformance.cpp:280 `RequirementMatches`,
    :286-301; re-cited at fill round 3). The first fill, on the toolchain built
    from 42841fa8d, CHECK-failed at sem_ir/generic.cpp:84 on satisfy
    `generic_self` and unsatisfied `fail_generic_self_wrong_return`, because the
    class specific `Box(i32)` was passed where the member function's own
    specific is read. The member is read in its own specific, formed from the
    enclosing arguments as a call forms it (call.cpp:109-118), and a member with
    compile-time parameters of its own never matches. Design: D-SC-5(d); D-SC-2
    with review fold A12. Break condition: W-136 lands, and the member's own
    parameters are then deduced against the requirement's.
-   **`.Self` lookup** (name_lookup.cpp:338, generic.cpp:268). Both
    compound-access splits CHECK-failed at eval.cpp:151 ("does not belong to
    generic"), and a probe's non-generic `c.(HasGet.Get)()` reached
    lower/handle.cpp:404's FATAL on an unresolved splice. Design: D-SC-10, whose
    phase claim this falsified (miss (h)) but whose break condition was not
    needed; D-SC-20 (§0.3), recorded at round 2. Break condition: D-SC-20's.
-   **Facet redirect** (member_access.cpp:451-509). Satisfy `assoc_fn` failed
    "use of undefined generic function" at the requirement: the replayed
    `T.Make()` on the facet value found the requirement with `Self := C`. A
    requirement found for a concrete self names the self type's own member,
    access re-checked against that type; a symbolic self keeps it. Design:
    D-SC-4 and §1.B.2 (miss (i)). Break condition: D-SC-4's (a consumer needing
    a table, W-138), and the redirect then reads the table.
-   **`require` kept** (handle_require.cpp:303-309). Checked-binding
    `fail_require_in_interface_blanket` filled clean because a `require` of a
    facet type naming no interface was dropped. It is kept when the facet type
    has structural requirements. Design: D-SC-8(iii), not enforced before. Break
    condition: upstream gives an interface-free `require` a meaning of its own,
    or pins it as a no-op, and the structural requirement attaches there. Round
    2's class-end deferral (MAJOR-3) extends it.

The §4 rows the fills corrected, each prediction as the goldens now hold it
(each row carries a dated amendment):

-   §4.A parse: `NamedConstraintIntroducer`, then `TemplateModifier` (miss (a)).
-   §4.B satisfy: no STDERR once round 2 spells `unused` (miss (e)); `method`
    prints the `facet_value`/`converted` pair twice, deduction then argument
    (miss (f)); `assoc_fn` positive through the facet redirect, `MakeIt(C)`
    calling `@C.%C.Make.decl` (dumped at round 2).
-   §4.B unsatisfied: `fail_incomplete` and `fail_incomplete_class_param` report
    the Context error `StructuralRequirementIncompleteType` with
    `ClassForwardDeclaredHere` and `InitializingGenericParam`, and no
    `DeductionGenericHere` (miss (c)).
-   §4.B checked binding: `fail_implicit_binding_compound_use` has exactly one
    diagnostic since round 2 (miss (b)); `fail_require_in_interface_blanket` has
    `InterfaceRequireImplsNotImplemented` since round 1's `require` fix.
-   §4.B dependent and import: positive and STDERR-free with no dump range; the
    `call_action` and imports-block shapes were probe-verified at round 1 and
    are not golden-pinned (miss (g)).
-   §4.B compound: positive since the `.Self` fix, dumped since round 2 with the
    specific binding `@C.%C.Get.decl` (miss (g)).
-   §4.B ladder: p002200's spelling; positive, and `fail_ladder_unsatisfied`
    gives `MissingImplInMemberAccess` with no structural note (miss (d)).

Held as written: the other §4.A rows; the §4.B impl_as, require, overload and
lower rows; §4.C, all six interop splits as the golden's header predicts.

Review record: the two round-1 reviews are as stated at the head of this note
(19 findings, all folded by round 2, none rejected; the per-finding list above).
Round 2's own diff (6f2f40d3c, 502e7861a, cb85e6b8b, 830447980) had two
implementation reviews, REJECT (one BLOCKER, one MAJOR, four MINOR) and
APPROVE-WITH-FIXES (two MAJOR, seven MINOR), folded by fill round 3 below.

Fill round 3, by review finding (review 1 BLOCKER-1 / MAJOR-1 / MINOR-n, review
2 Fn), each reproduced first on the 0.0.0-0.dev+6f2f40d3c driver:

-   BLOCKER-1: `impl C as I { alias F = HasGet.Get; }` passed check and aborted
    lowering at sem_ir/mangler.cpp:185, the thunk built for the alias taking
    the template constraint's with-self scope as its parent (thunk.cpp:235). A
    requirement as an impl member is now `ImplFunctionWithNonFunction` with the
    requirement's note, before any thunk (impl.cpp
    `CheckAssociatedFunctionImplementation`), as upstream's alias of another
    interface's member is; D-SC-5(c) and §1.E amended. Pinned by
    requirement-call `fail_impl_member_alias` (method, associated function,
    `extend impl` in a class) and `fail_ladder_alias`, and lower
    `impl_member_alias` (`alias F = (C as HasGet).Get` lowers to a direct call
    of `C.Get`).
-   MAJOR-1: `GetStructuralRequirementConstraint` returns `None` for any
    special function, so a thunk is never a requirement. The review's second
    guard, "no definition", is not taken: a requirement written with a body is
    the diagnosed D-SC-2 TODO and stays collected in `structural_members_id`
    (handle_function.cpp:1212-1225), so it stays a requirement. The review's
    p24 shape now gives only the impl error and, at a structural use of the
    rejected member, a mismatch (pinned in `fail_impl_member_alias`).
-   MINOR-1: the class-end wait is keyed on the `require`'s self being a class
    whose definition has started and not ended (impl.cpp
    `GetRequireSelfClassBeingDefined`), not on the impl's lexical placement;
    D-SC-8(iii) amended. Pinned by require `require_self_class_being_defined`
    and `fail_require_self_class_being_defined_lacking`.
-   MINOR-2 / F1: only the structural part waits; the interfaces the same facet
    type names are looked up at the impl (impl.cpp `LookupRequireInterfaces`),
    so `require impls HasGet & J` orders `J`'s impl as `require impls J` does
    (option (a) of F1). Pinned by `fail_require_mixed_in_class_impl_order`; the
    `require_in_interface_in_class_impl` comment and the impl.cpp comment now
    say what the code does.
-   MINOR-3 / F6 (part): require
    `fail_todo_require_in_interface_in_generic_class_impl` pins the
    generic-class shapes (`Box(T)`, `Outer(T).Inner`; a `template` parameter
    is deferred), and W-139's evidence and notes record them.
-   MINOR-4 / F5: the satisfy `fail_todo_ambiguous_with_interface` comment cites
    this note's heading, name_lookup.cpp:589 and member_access.cpp:430-432;
    `fail_todo_runtime_facet` cites member_access.cpp:853-858 and :987-996 and
    W-033. The ambiguity residue's ledger id stays pending: SC-1 holds no
    reservation above W-151 (the W-151 paragraph below), and ids are allocated
    by the orchestrator.
-   F2: docs/design/generics/template_constraints.md gains the four landed
    behaviors (the alias rule with its normative sentence narrowed, the
    requirement-call error, the class-end timing with its generic-class
    limitation, the associated-function form of qualified access) and the two
    new diagnostic kinds.
-   F3: unsatisfied `fail_own_params` is `fn Get[unused U: type](unused self)
    -> i32`, differing from the requirement only by its own parameter.
-   F4: the ladder header cites p002200:601-637 exactly and lists each delta
    from the sketch with its reason, including why the sketch's commented
    `alias DoF = T.F;` is not ported (upstream rejects an impl alias of a
    template-dependent name for any template binding, trunk 0bdce60a5).
-   F6 (rest): W-141 and W-142 and every SC-1 ledger cite into a file this round
    changed are re-cited; D-SC-6's lead sentence is marked superseded; D-SC-5(c)
    carries the dated amendment.
-   F7: a found requirement has its own note, `StructuralMemberIsRequirement`
    (structural_conformance.cpp `NoteMemberFailure`); D-SC-9 now counts 10
    kinds, 11 with R-6's.
-   F8: the waiting `require`s sit on a per-class list on `Context`
    (`deferred_structural_requires()`), taken off the list before any check
    runs, instead of a view of the live class-body block; D-SC-8(iii) records
    why not `DeferredDefinitionWorklist`.
-   F9: §4.B rows for the 23 round-2 splits (post-fill, as filled) and the
    round-3 splits (predicted before the fill); the two fail splits without a
    comment have one.

Rejected or narrowed, with evidence: MAJOR-1's "no definition" guard (above).
None of the 15 findings is rejected otherwise.

Round 3's four decisions as R29(a) implementation decisions, each with its
design citation and break condition (the decision log's "SC-1 fill rounds
(2026-10-13)" entry gives each one's symptom and root cause; the bullets above
name the splits that pin them):

-   **A requirement is not an impl member** (impl.cpp:52-86
    `CheckAssociatedFunctionImplementation`, joining upstream's non-function
    branch at :66; BLOCKER-1). A requirement `fn` named as an impl member is
    `ImplFunctionWithNonFunction` with the requirement's note, before any thunk
    (the thunk copied the constraint's with-self scope, thunk.cpp:235, and
    sem_ir/mangler.cpp:185 aborted). Design: D-SC-4, D-SC-5(c) and §1.E as
    amended; upstream's alias of another interface's member
    (impl/fail_impl_bad_assoc_fn.carbon:28-37 pins the branch). Break condition:
    upstream accepts an impl member aliasing another interface's member,
    resolved for the impl's self, or W-138's table lands; then the alias
    resolves to the self type's own member instead of being rejected.
-   **A thunk is not a requirement** (structural_conformance.cpp:637-657
    `GetStructuralRequirementConstraint`, :641-647; MAJOR-1). A function of any
    special kind is never a requirement; the "no definition" guard is declined
    (handle_function.cpp:1212-1225 keeps a requirement written with a body
    collected). Design: D-SC-2, D-SC-15. Break condition: a requirement can
    itself be a special function, or thunk.cpp stops copying its callee's parent
    scope; then the test reads membership in `structural_members_id`.
-   **The class-end wait keyed on the `require`'s own self, structural part
    only** (impl.cpp:870-887, :894-920, :926-981, :1092-1114; context.h:598-610;
    handle_class.cpp:386; MINOR-1, MINOR-2 / F1, F8). Design: D-SC-8(iii) as
    amended, D-SC-5(a). Break condition: upstream checks an interface's
    `require`s once the self is complete, or lets a class be looked into for
    satisfaction within its own definition; then the per-class list is deleted
    and the structural part is checked with the rest. The generic-class limit is
    W-139's, under W-139's break condition.
-   **A found requirement gets its own note**
    (structural_conformance.cpp:367-377, toolchain/diagnostics/kind.def:471;
    F7): `StructuralMemberIsRequirement` replaces `StructuralMemberMissing` when
    the name found is the requirement itself. Design: D-SC-9 (10 kinds, 11 with
    R-6's), D-SC-5(c). Break condition: D-SC-9's, an existing kind whose text
    fits is found and the count drops.

Round 3's fill predictions, checked against the fill: every round-3 row of §4.B
held after miss (k), except miss (l), the printed facet type `J & HasGet`
(written `HasGet & J`); each round-3 row now says so, dated.

Round 3's own diff (0efe76e7d, bc8b37290, 5171e5eda) has no implementation
review on record at this commit. The records commit after 5171e5eda noticed one
stale cite there and leaves it for that review (a records commit changes no
source): the impl.cpp:58 comment names D-SC-5(b), and the amendment is in
D-SC-5(c).

W-151: the commit-3 residue first filed as W-144 was renumbered to W-151 by
2f4ebbf6e, because SAFE-1 (PR 53) allocated W-144..W-150; trunk's id
reservations (9d3ca60a3) give SC-1 nothing above W-151, so the MINOR-3 residue
takes the next free id at landing.

Measured, on the container only (not of record, R9; hosted: not run, Actions
disabled). Round 1: autoupdate over the 18 goldens in three passes (all 18
rewritten; then the 3 files whose STDERR lines sit above dumped source, `loc`
and `line:` numbers only; then none), gate 1958 passed and 0 failed, conformance
at 2f4ebbf6e 130 / 0 / 21 over 151 with 49 of 56 bullets. Round 2: as stated at
the head of this note. Re-run on cb85e6b8b with the toolchain stamped
0.0.0-0.dev+6f2f40d3c (no toolchain source differs): gate 1959 passed and 0
failed; conformance PASS 130 with every failure class 0 and SKIP 21 of 151,
bullets 49 PASS, 0 FAIL, 7 SKIP of 56, the same two programs moving against
fork/conformance/out/scoreboard.json. Round 3, on the toolchain built from the
round-3 sources before the commit (stamped 0.0.0-0.dev+830447980.dirty):
autoupdate over the 19 SC-1 goldens rewrote 4 and reported miss (k), and after
the respelling a second pass rewrote none; gate 1959 passed and 0 failed;
conformance 130 / 0 / 21 over 151 with 49 of 56 bullets. Re-run on the toolchain
rebuilt from bc8b37290 with a clean tree (stamped 0.0.0-0.dev+bc8b37290,
recorded by the round-3 records commit): gate 1959 passed and 0 failed;
conformance 130 / 0 / 21 over 151 with 49 of 56 bullets; the same two programs
moving. Round 3's commits: 0efe76e7d (fixes, test sources, docs, records),
bc8b37290 (goldens) and 5171e5eda (records). Re-run for the records commit after
5171e5eda, on 5171e5eda with the installed toolchain stamped
0.0.0-0.dev+bc8b37290 (no toolchain source differs): gate 1959 passed and 0
failed; conformance 130 / 0 / 21 over 151 with 49 of 56 bullets, the same two
programs moving.

Verification of the fill-rounds records commit: prek (rumdl, google-doc-style,
markdown-toc, prettier on the ledger, codespell, copyright, check-links) at a
fixpoint over the six changed files (pass 1 reflowed one line of this note and
one decision-log paragraph, MD013; pass 2 clean); `runner.py --self-test` OK
with 151 programs and 56 bullets (both programs' edits are comment-only); the
ledger parses, 136 items, W-151 the maximum id. R31 record (H1/H2/H3/H4/H5, dash
items, numbered items): this file 1/12/23/0/0, 111, 53 before and 1/12/23/0/0,
122, 53 after (the heading renamed in place; eleven new items, the four defects
and the seven corrected rows); decision-log.md 1/2/44/1/6, 23, 0 before and
1/2/45/1/6, 27, 0 after (the new entry's heading and its four defects);
ORCHESTRATION.md 1/1/5/0/0, 8, 4 before and after; gap-analysis.md not edited,
1/5/23/0/0, 0, 0. The hazard greps over the diff are empty.
