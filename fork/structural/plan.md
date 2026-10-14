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
    NOT collected into `structural_members_id`, §1.A.3), and, since fill round
    10, a requirement `fn` with a tuple pattern parameter, directly or under
    `var`, and since fill round 11 under a default value too ("tuple pattern
    parameter in `template constraint`", also not collected, W-234; round 9's
    review 2 finding MINOR-2 and round 10's review 1 finding MINOR-1: the
    signature comparison fails fatally on a `TuplePattern`, merge.cpp
    `CheckRedeclParam`, as trunk 0bdce60a5's does for an impl of an interface
    with such a member and for a redeclaration). DISCLOSURE (amended
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
    impl, p002200:580-610). AMENDED 2026-10-14 (fill round 12, round 11's
    review 1 finding MAJOR-2): `CheckFunctionTypeMatches` compares a `self`
    parameter as any parameter of its type, so a member without `self` whose
    first parameter has the self type (`fn Get(c: C) -> i32`) matched `fn
    Get(self) -> i32`, and the use `x.Get()` then failed at monomorphization
    (sc1-fix12/p st1; trunk 0bdce60a5 accepts the impl analog with no thunk,
    st1.t). A requirement with `self` now needs a member with `self`
    (structural_conformance.cpp:492-501, in `CheckRequirementFunction`); a
    requirement without `self` is still satisfied by a method, which
    `T.Get(x)` calls with `x` as its `self` (st2, and st4, which runs and
    prints `42`). Pinned by unsatisfied `fail_static_for_method` and satisfy
    `method_for_assoc_fn`. The amendment rejects programs that compiled and ran
    before it: a static member whose first parameter has the self type, called
    as `T.Get(x)` or not called at all, satisfied `fn Get(self)` through fill
    round 11 and is rejected from fill round 12 (sc1-review12/adv2/m4 c1, which
    prints `42` on a round-11 toolchain and gives `StructuralMemberMismatch` on
    the round-12 and round-13 builds; sc1-review12/adv1/p/b r05 and r13). No
    design text requires accepting them: p002200:354-355 says "Only types with
    matching declarations will satisfy the template constraint", and such a
    member's declaration does not match the method's (recorded at fill round 13,
    round 12's review 2 finding MINOR-3; the design page dates the amendment
    2026-10-14, round 12's review 1 finding MINOR-3).
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
    and the worklist defers definitions, not declaration checks; amended again
    2026-10-13, fill round 4, review findings MAJOR-1 of both reviews: a union
    is a class, so its `UnionDefinition` handler drains the list as well, and
    `Context::VerifyOnFinish` checks that the list is empty at the end of the
    file); a
    TEMPLATE blanket `impl forall
    [template T: type] T as I {}` is deferred, not rejected (D-SC-19). Break
    condition for (i): upstream's issue 2153 resolution (as D-SC-6).
-   **D-SC-9 — diagnostics: EIGHT new kinds (heading corrected from "six", body
    from seven — amended 2026-10-06, review fold: B4 / A1), notes attached to
    the EXISTING conversion error.**
    `DiagnoseConversionFailureToConstraintValue` (convert.cpp:1503-1527)
    switches from `Emit` to `Build` + notes + `Emit`, and
    `NoteStructuralConformanceFailure` (structural_conformance.h) re-runs the
    check in explain mode to add, for the FIRST unsatisfied requirement in
    declaration order (the stranded page's rule, :566-579):
    `StructuralMemberMissing` (Note, "type {0} has no member named `{1}`
    required by template constraint `{2}`"), `StructuralMemberMismatch` (Note,
    "member `{1}` of type {0} does not match the signature required by template
    constraint `{2}`"), `StructuralRequirementHere` (Note, "requirement declared
    here", at the requirement `fn`), `StructuralMemberInaccessible` (Note,
    "member `{1}` of type {0} is {2:private|protected} here and cannot satisfy
    template constraint `{3}`" — D-SC-5(b), A1; the text mirrors
    `ClassInvalidMemberAccess`, name_lookup.cpp:237-240, which is Error-severity
    and so cannot itself be a note), `StructuralRequirementNeedsConcreteType`
    (Note, "template constraint `{0}` can only be satisfied by a concrete type;
    {1} is a checked generic binding" — D-SC-6). Errors:
    `TemplateConstraintOnNonTemplateBinding` ("template constraint `{0}` can
    only constrain a `template` binding" — D-SC-8),
    `FunctionInNonTemplateConstraint` ("function declaration in a non-`template`
    `constraint`; use `template constraint` to declare a structural requirement"
    — §0.1 row 7's TODO retired), `NamedConstraintRedeclTemplateMismatch`
    ("redeclarations of `constraint {0}` must match use of `template`", with the
    existing `RedeclPrevDecl` note — the `RedeclExternMismatch` shape,
    merge.cpp:45-57; D-SC-16). That is 8 kinds (9 if R-6's completeness context
    note is counted), each covered by a §4 golden (coverage_test); fill round 2
    adds one more, the error `StructuralRequirementCalled` ("requirement `{0}`
    of template constraint `{1}` can only be called through a type that
    satisfies it", D-SC-4: a requirement `fn` is never itself the callee; its
    text says "used" for "called" since fill round 4, when it also reports a
    requirement used as a value, D-SC-20, and the kind is named
    `StructuralRequirementUsed` since fill round 5, review 2 finding MINOR-1),
    so 9 kinds, 10 with R-6's (amended 2026-10-13); fill round 3 adds the note
    `StructuralMemberIsRequirement` ("name `{1}` in type {0} refers to a
    requirement of template constraint `{2}`, not to a member of the type",
    D-SC-5(c) as amended; review finding F7), so 10 kinds, 11 with R-6's
    (amended 2026-10-13). The deferred forms of D-SC-2 use `context.TODO`
    (`SemanticsTodo`, no kind). impl.cpp's two `require` emits (`IdentifiedRequireImplsNotImplemented`
    :891-904 for the identified facet type's requirements,
    `InterfaceRequireImplsNotImplemented` :946-956 for the interface's own
    `require` block) stay `Emit` with NO structural note in SC-1 — the notes are
    wired only into convert.cpp:1503-1527 (amended 2026-10-06, review fold:
    A5(ii)). Errors follow one rule (amended 2026-10-14, fill rounds 12 and 13):
    a member satisfies a requirement exactly when D-SC-5(d)'s comparison holds;
    when it does not, nothing more is reported if the comparison would hold with
    each erroneous type and each erroneous default value of either declaration
    counted as equal to the type or default value in its place in the other (a
    type with an error anywhere in it is the error, and so is a default value of
    a parameter whose type is the error); everything else, including the binding
    form (`var`, `ref`) of a parameter with an error and whether a default value
    or a return type is there, is compared as without the error; such a silent
    failure is still a failure for a direct use, an overload probe and a blanket
    impl (W-233). The comparison runs in its errors-match mode, which reads a
    parameter pattern with an error as declared, since its constant value is the
    error, and an imported one in the file that declares it. A member that fails
    is reported as for a requirement with no error, so every difference
    D-SC-5(d) reports without an error is reported beside one (a member without
    the `self` the requirement has, the `self` form, the presence and length of
    each parameter list, a parameter's type, binding form or default value,
    whether a return type is there and which, the evaluation mode, compile-time
    parameters of the member's own, a member that is not a function), except a
    difference that the counted-as-equal parts themselves hide: one inside a
    composite type with an error (`(i32, Undefined)` against `(bool, i32)`) and
    the value of a default value of a parameter whose type is the error
    (sc1-fix13 mx: 19 cases of review 1's 878 and 10 of review 2's 1094). A
    member that matches only through such a part adds no error and no note of
    its own: the error was reported at its declaration, so the requirement is
    skipped with no further diagnostic, in both modes, and every other
    requirement, template constraint and interface of the facet type is still
    checked and reported; the check fails with no diagnostic only when nothing
    else fails. Trunk 0bdce60a5's impl analog does not govern the rule, and
    nothing it reports is silent here (sc1-fix13 mx: none of review 1's 330, 275
    and 878 cases and review 2's 1094). SC-1 diverges from that analog in one
    class: it reports beside an error every difference it reports without one,
    but for the two the rule hides, where the thunk adapts some (a convertible
    parameter or return type, the evaluation mode, a `var` parameter, an empty
    implicit parameter list, a deducible compile-time parameter of the member's
    own, a default value of an impl member's own) and stops comparing others
    beside an erroneous part (a parameter type, a binding form or the presence
    of a default value beside an interface member's erroneous parameter or
    default value, a missing `self` beside an erroneous `self`, a return type's
    presence beside an erroneous return type) (amended 2026-10-14, fill round 9,
    round 8's review 1 finding MINOR-3 and review 2 finding MINOR-1; narrowed at
    fill round 10, round 9's review 1 findings MAJOR-1 and MINOR-2 and review 2
    findings MAJOR-1 and MINOR-1: round 9 returned at the first such mismatch,
    which hid a genuine failure of a later requirement, and tested the
    requirement's side only; narrowed again at fill round 11, round 10's review
    1 finding MAJOR-1 and review 2 finding MAJOR-1: round 10 skipped any
    mismatch when either signature had an error anywhere, which hid each of
    those differences; restated as one rule at fill round 12, round 11's review
    1 findings MAJOR-1, MAJOR-2 and MINOR-1 to MINOR-3 and review 2 findings
    MAJOR-1 and MINOR-1 to MINOR-4: round 11 read an erroneous default value as
    no error, so one gave a spurious mismatch and two aborted at merge.cpp:391,
    and its `OnlyErrorsDiffer` and merge.cpp
    `CheckRedeclParamsMatchExceptErrors` re-listed the comparison's parts and
    justified the skip by the thunk, which it does not follow; narrowed at fill
    round 13, round 12's review 1 findings MAJOR-1, MINOR-1 and MINOR-4 and
    review 2 findings MAJOR-1, MINOR-1 and MINOR-2: round 12 skipped a parameter
    with an erroneous type whole and compared one with an erroneous default
    value by its type alone, which hid the binding form, `ref y: i32 =
    Undefined` against `y: i32` among them, where trunk's analog reports it, and
    matched an erroneous return type or default value against none, and its
    statement of the rule did not describe the code; the errors-match mode is a
    `found_error` parameter of upstream's comparison, function.cpp
    `CheckFunctionTypeMatches` and `CheckFunctionReturnTypeMatches` (:265-276),
    merge.cpp `CheckRedeclParamsMatch` (:768-772), `CheckRedeclParams`,
    `CheckRedeclParamLists` and `CheckRedeclParam` (:360-404, with
    `GetDeclaredParamPattern` at :222-281), each function with a fork marker,
    used by structural_conformance.cpp `CheckRequirementFunction` (:502-531) and
    `CheckRequirements` (:620-631), with impl_lookup.cpp `LookupImplWitness`
    looking the interfaces up after the error; pinned by unsatisfied
    `fail_requirement_signature_error` and its `_genuine`, `_other_member`,
    `_other_constraint` and `_require` siblings, `fail_member_signature_error`
    and `fail_member_signature_error_genuine`, and the uses in the declaration
    golden's `fail_todo_` splits). A deduction that meets such a requirement is
    a rejection, so an overload set whose other members all reject reports
    `OverloadNoMatch` and a blanket impl is not applied, as for a member's or a
    candidate's own error on trunk (W-233). Break condition: a reviewer finds an
    existing kind whose text already fits — then that kind is reused and the
    count drops.
-   **D-SC-10 — `Self` inside a template constraint is a TEMPLATE-phase
    binding.** (BREAK CONDITION TAKEN 2026-10-14, fill round 7: a CHECKED-phase
    binding as landed; restated at fill round 8, W-169; heading annotated at
    fill round 9, round 8's review 2 finding MINOR-5.) `is_template = true`
    flows into `AddSelfSymbolicBindingToScope`
    (handle_named_constraint.cpp:160-162 at the round-10 head; :141-143 at
    8068151ed, where the plan cited :134-136; re-pointed at fill round 10, round
    9's review 2 finding MINOR-4), exactly the hook upstream left for it
    (§0.1 row 5), so a requirement's `self` and `Self`-typed parameters carry
    `[template]` phase like `x: T` for `template T`. Nothing in SC-1 depends on
    the phase (signatures are matched through specifics, which substitute either
    phase); SC-B2's validity blocks will need it. (Amended 2026-10-13, fill
    round 1: false for a requirement named with no self, `HasGet.Get`, whose
    with-self specific carried the template-phase `Self` and so made the name
    template-dependent; D-SC-20 gives such a lookup `.Self` instead, and the
    phase of `Self` itself stands. Amended again 2026-10-14, fill round 6, round
    5's review 2 finding MINOR-4: since fill round 5 such a name is a value of
    the concrete `StructuralRequirementType`, D-SC-20 replaced, so no `Self`
    phase reaches it and no `.Self` is given.) Break condition: the commit-1
    fill shows a template-phase `Self` breaking a positive §4.A golden (a
    `<dependent type>` or `type_of_inst` in a requirement's parameter pattern,
    or a `CARBON_CHECK` in `CheckRedeclParams`) — then SC-1 passes `false` and
    files the flip as an SC-B2 prerequisite. TAKEN 2026-10-14 (fill round 7,
    round 6's review 1 finding BLOCKER-1): "nothing in SC-1 depends on the
    phase" was false for every other name of the body that depends on `Self`.
    An alias of `Self`, a class, interface or constraint declared in the body,
    and a template constraint nested in it (with its requirements) were
    template-dependent where non-template code named them with no self type,
    so `Convert`, calls and member access recorded actions that a non-generic
    function never performs: type errors and D-SC-20's refusal were skipped,
    check passed and lowering aborted on an unexpanded `SpliceInst`. SC-1 now
    passes `false` (handle_named_constraint.cpp:126-133), as upstream's code
    did before SC-1, so `Self` is a checked-phase binding in a template
    constraint, those names are symbolic as a `constraint`'s are, and each
    probe is diagnosed as its `constraint` spelling is on trunk 0bdce60a5 or
    aborts as that spelling does there. A requirement named with no self type
    keeps its concrete type and a signature is still matched through
    specifics, but each requirement's signature is now checked at the
    definition as an interface member's is. (Restated 2026-10-14, fill round
    8, round 7's review 1 finding MAJOR-1 and review 2 findings MAJOR-1,
    MAJOR-2 and MINOR-1: round 7 wrote here that requirements were
    unaffected and that one shape, a requirement named through `Self.N`,
    moved from accepted and never satisfiable to rejected; both were false.)
    Moved from accepted to rejected at the definition: every member access
    into `Self` (`typeof(Self.N)*`, `Self.A` of an alias, `Self.K` of a
    nested class; upstream's "member access into facet of incomplete type",
    as trunk's interface `fail_todo_self_period_associated_type`), and every
    use of `Self` that must satisfy a facet type the constraint does not
    itself require (`Box(Self)` for `class Box(T: J)`, `Self.(J.Elem)`,
    `Core.Slice(Self)`, `Core.Optional(Self)`). Of these, `typeof(Self.N)*` as a
    parameter or return type, `Box(Self)`, `Self.(J.Elem)`, `Core.Slice(Self)`
    and `Core.Optional(Self)` were satisfiable and ran on fb12f63cb (round 7's
    review probes q01, q04 to q06, f14 and f18; for `Core.Slice(Self)` and
    `Core.Optional(Self)`, a class that declares `impl as Core.Copy` and `impl
    as Core.Destroy` before the member, fill round 9's probes z06 and z08, where
    round 8 cited f22, which declares the constraint and no satisfying type), as
    did `Self.A` for a type with its own `A` (z10), so programs valid under
    F-010's definition-time rule are lost; since fill round 9 the declaration
    golden's `fail_todo_` splits hold those satisfying classes and their uses.
    Requiring the facet type that `Self` must satisfy restores the facet cases:
    `require impls J` for `Box(Self)` and `Self.(J.Elem)` (f15, f17), and
    `require impls Core.Copy & Core.Destroy` for `Core.Slice(Self)` and
    `Core.Optional(Self)` (z07, z09), all pinned by
    `self_facet_in_signature_required`; requiring a template constraint does not
    (D-SC-6), and a member access into `Self` has no workaround in SC-1 (amended
    at fill round 9, round 8's review 1 finding MINOR-1 and review 2 findings
    MINOR-3 and MINOR-4). The template-phase `Self` of fill rounds 1 to 6 also
    made a type that does not satisfy such a signature a hard "unable to
    monomorphize" error at its use, even in an overload probe and with `require
    impls J` (round 8's review 1 probes b01 to b04), against D-SC-12; a template
    phase brought back keeps such a probe silent, as
    `self_facet_in_signature_required`'s `P` and lower `overload_probe_require`
    pin (round 8's review 1 finding MINOR-2). Unchanged since SC-1a and never
    satisfiable: a requirement named unqualified in another's signature (`fn
    M(p: typeof(N)*)`), which names the requirement's own function for the
    satisfying type. Moved from rejected to accepted: a `require` whose facet
    type takes `Self` as an argument (`require Self impls Conv(Self)`,
    `require impls Has(Self)`), which the template-phase `Self` made a splice
    ("constrained by a non-facet type") since SC-1a, against the design
    page's "compose freely". The flip is kept as that trade (the decision
    log's ROUND 8's DECISION): the lost signatures are pinned as `fail_todo_`
    splits of the declaration golden and filed as W-169, and the template
    phase as an SC-B2 prerequisite (W-028's notes), since SC-B2's validity
    blocks need expressions of the body to be checked per specific; a
    template phase brought back for them keeps the require golden's
    `require_self_argument` and `fail_require_self_argument_unsatisfied` as
    they are, or is scoped to the validity blocks' own checks.
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
-   **D-SC-20 — a requirement named with no self type is a value of its own
    concrete type (added 2026-10-13 as "has `Self := .Self`", introduced by
    fill round 1's fix 2 and recorded at fill round 2, review finding F4;
    replaced at fill round 5, round 4's review 1 findings BLOCKER-1,
    BLOCKER-2, MAJOR-1 and MAJOR-2 and review 2 findings BLOCKER-1 and
    MAJOR-1).** A lookup into a template constraint with no self type
    (`HasGet.Get`; `T.N` once a template's `T` is the facet type `HasN`; a
    runtime facet value's member, looked up in its facet type) builds the
    constraint-with-self specific with the constraint's own `Self`, as upstream
    does for an interface's `I.F` (name_lookup.cpp
    `GetSelfFacetForInterfaceFromLookupSelfType`, unchanged from trunk), and
    the requirement found there is not returned as a function:
    `MakeStructuralRequirementName` (structural_conformance.cpp, called from
    member_access.cpp's lookup) returns a name reference to an empty
    `struct_value` of `StructuralRequirementType` (sem_ir/typed_insts.h: the
    requirement's function and the constraint's specific without `Self`), a
    type that depends on the constraint's arguments only, as upstream's `I.F` is
    an `assoc_entity` of the concrete `AssociatedEntityType`. Reason: the
    requirement `fn` is the one with-self member whose value depends on `Self`.
    Returned as a function, it had a function type symbolic in a `Self` that no
    specific replaces (the constraint's own at the first fill, `.Self` from
    round 1 to round 4), and every construct that takes a type without
    converting a value (`typeof`, a template's constant tuple or struct value,
    deduction) carried that type into concrete code, where lowering aborts
    (lower/type.cpp:459, lower/file_context.h:187; round 4's reviews). With a
    concrete type nothing symbolic escapes, so round 1's `.Self` lookup and
    generic.cpp's early return for `.Self`-only constants are deleted (the
    lookup's with-self path is trunk's, while name_lookup.cpp keeps SC-1b's
    `diagnose` parameter; generic.cpp as on the base 8068151ed; restated at
    fill round 6, round 5's review 2 finding MINOR-3). Consequences: the
    requirement is never itself called (`StructuralRequirementUsed` in call.cpp
    `PerformCallToNonFunction`, D-SC-9); a compound access through it redirects
    to the base type's own member, the facet type taken from its type (D-SC-4),
    except, as an associated function, through a facet that is symbolic for a
    concrete base (a constraint argument naming a checked generic's parameter,
    `C.(Has(T).N)()`, or a constraint declared in another constraint's or an
    interface's body, `C.(Outer.Inner.N)()`): that is a TODO, filed as W-232 at
    fill round 9, and `(C as Has(T)).N` keeps the requirement, while a method
    requirement is redirected through the value's type (fill round 8, round 7's
    MINOR-2 of both reviews; requirement-call `fail_todo_symbolic_facet`);
    an `alias` of it is that value; `typeof(HasN.N)` is its type, usable as a
    type (a pointer, a field, an impl's self, a generic argument) but with no
    values. Named, a value that names or holds it is refused (amended at fill
    round 4, review finding BLOCKER-1; restated at fill round 5; reworded at
    fill round 8, round 7's review 2 finding MINOR-3): `Convert` refuses a
    value whose type is, or holds as a tuple or struct element, a
    requirement's type (as an array element or under `const` too since fill
    round 7), and a bound method of a requirement found through a checked
    binding, whose
    type does not say; a template replays the refusal in its convert actions
    at instantiation (convert.cpp `PerformAction`), so `Take((T.N, 1))` and a
    discarded `T.N;` instantiated with `HasN` are refused like `Take((HasN.N,
    1))` and `HasN.N;`. The refusal is the design rule, not a guard against a
    crash: a use that converts nothing yields an empty value of a concrete
    type. (Amended 2026-10-14, fill round 6, round 5's findings MAJOR-1 of both
    reviews and review 1 MINOR-1.) The refusal covers what `Convert` and the
    template convert actions see: an expression that is, or produces, a value
    or an initializer whose type is or holds a requirement's type. A
    reference to an object of such a type that stays a reference (bound to a
    `ref` parameter or binding, the callee's own `ref self` included, used as
    a member access base, or discarded) reads no value and is not refused
    (convert.cpp `CheckConversionIsNotOfStructuralRequirement`), so a class,
    tuple, struct or array with an element of the type is destroyed through
    its synthesized `Destroy.Op`'s `ref self` (custom_witness.cpp
    `MakeSubobjectDestroyOpBody`); round 5 refused every local or temporary
    of such a class with a dozen copies of the error. A value typed by a type
    parameter bound to the requirement's type is an accepted empty value,
    lowered as `{}`: in a checked generic necessarily, since no refusal can
    be replayed in a specific, and in a template only where the conversion
    records no action (a `let` typed by the parameter); both are pinned by
    lower `requirement_typeof_object` (`Pass`, `LetValue`), with
    requirement-call `fail_requirement_typeof_value`'s `ReadField` for the
    boundary. (Amended 2026-10-14, fill round 7, round 6's review 1 findings
    MAJOR-1 and MINOR-1 and review 2 findings MAJOR-1 and MINOR-1.) A type
    holds a requirement's type when a value of it is built from values of
    that type element by element: a tuple, struct or array element, or the
    same type under `const`; a value of such a type is refused, while a
    pointer to it is not (`ConstParam`, `ConstPointer`, `ArrayLet`,
    `ArrayArg`). A class, adapter or `MaybeUnformed` value is a value of its
    own type, not built element by element, and is accepted; but a field
    accessed through a class value is read as a value (member access
    acquires it, member_access.cpp:614-624), so that read is refused when the
    field is or holds the type, a tuple or struct field read only for its
    other element included (`self.t.1` in a value method, `Get`; `e.s.x`,
    `StructField`): such a field is reached through a reference to the object
    (`GetRef`), round 6's review 2 MAJOR-1 being taken as its second option.
    In a template, a call argument or a `var` initializer that depends on the
    parameter is replayed at instantiation and refused (`TemplateDeref`). A
    value parameter of the type is refused at its declaration, whose binding
    converts the parameter; a `var` parameter's binding keeps its storage a
    reference, so its declaration is accepted and each call, which
    initializes it from a value, is refused (`VarParam`). Pinned by
    requirement-call `fail_requirement_as_value`,
    `fail_requirement_through_checked_binding_as_value`,
    `fail_requirement_through_template_instantiation` and
    `fail_requirement_typeof_value`; compound `checked_generic_name`,
    `assoc_fn_compound` and `requirement_typeof` (the dumps show
    `structural_requirement_type`, symbolic only through a generic
    constraint's arguments, and no `.Self`); lower `compound_nongeneric`,
    `requirement_through_template_instantiation` and `requirement_typeof`.
    Veto-able (R29(a)). Break condition: upstream gives a named constraint's
    members associated entities, so the requirement becomes an `assoc_entity`
    of the constraint and `StructuralRequirementType` folds into
    `AssociatedEntityType`; or W-138's structural witness table lands, and a
    requirement value names a table entry instead of being refused.

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
    (Amended 2026-10-14, fill round 7: the `Self` binding takes `false`
    again, D-SC-10's break condition.)
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
| check/testdata/named_constraint/template_constraint.carbon (new) | `decl.carbon`: `template constraint HasGet { fn Get(self) -> i32; fn Make() -> Self; }` with `//@include-in-dumps`; `forward.carbon`: `template constraint F; template constraint F { fn G(ref self); }`; `compose.carbon`: a template constraint with `require impls Core.Destroy;` and a method; `generic.carbon`: `template constraint Has(T: type) { fn Get(self) -> T; }` | No STDERR. SemIR: `%HasGet.type: type = facet_type <@HasGet>` as for plain constraints (basic.carbon golden :59/:86 — re-cited 2026-10-06, review fold: B8); inside `@HasGet` a `%Self: %HasGet.type = symbolic_binding Self, 0, template [template]` (D-SC-10 — the `, template` suffix as member_access.carbon:137-138, re-cited) and two `fn_decl`s whose `self` pattern is `@HasGet.%Self`-typed; `generic.carbon` shows the with-self generic over `(T, Self)`. These shapes are DERIVED FROM INTERFACE ANALOGUES, not golden-backed: no check golden dumps a `fn` inside a named constraint (invalid_members.carbon has zero `CHECK:STDOUT`) or a template-phase `Self`, so the fill is evidence, not confirmation (R9/R16(d); amended 2026-10-06, review fold: A9) AMENDED 2026-10-14 (fill round 7, D-SC-10's break condition taken): `%Self: %HasGet.type = symbolic_binding Self, 0 [symbolic]` and the requirement `fn_decl`s and their patterns `[symbolic]`, the interface-analogue shape without the template phase |
| check/testdata/named_constraint/fail_template_constraint_modifier.carbon (new) | `fail_on_fn.carbon`: `template fn F();`; `fail_on_class.carbon`: `template class C {}`; `fail_on_interface.carbon`: `template interface I {}`; `fail_twice.carbon`: `template template constraint X {}`; `fail_with_abstract.carbon`: `template abstract constraint X {}` (added 2026-10-06, review fold: A4) | `ModifierNotAllowedOnDeclaration` "`template` not allowed on `fn` declaration" (modifiers.cpp:102-104) etc.; `fail_twice` → `ModifierRepeated` from `HandleModifier` (handle_modifier.cpp:72-74); `fail_with_abstract` → `ModifierNotAllowedWith` (:76-78; both in the `Decl` at-most-one group) |
| check/testdata/named_constraint/fail_template_constraint_redecl.carbon (new) | `fail_decl_then_template_def.carbon`: `constraint X; template constraint X {}`; `fail_template_decl_then_def.carbon`: `template constraint X; constraint X {}` | `NamedConstraintRedeclTemplateMismatch` at the second declaration + `RedeclPrevDecl` note at the first |
| check/testdata/named_constraint/invalid_members.carbon (EXISTING; three splits move) | `todo_fail_invalid_fn.carbon` → `fail_invalid_fn.carbon` (same source, TODO comments rewritten); `fail_todo_invalid_var_template.carbon`, `fail_todo_invalid_let_template.carbon` keep their names | `fail_invalid_fn`: `FunctionInNonTemplateConstraint` at each of the four `fn`s (:19-20, :25-26). The two template splits lose `UnrecognizedDecl` + "handle invalid parse trees" and gain `SemanticsTodo` "`field requirement in `template constraint``" at the `var` |
| check/testdata/named_constraint/fail_todo_template_constraint_members.carbon (new) | `fail_todo_definition.carbon`: `fn G(self) -> i32 { return 1; }` in a template constraint; `fail_todo_parameterized.carbon`: `fn H[U: type](self, u: U);`; `fail_todo_assoc_const.carbon`: `let X: type;` | `SemanticsTodo` with the D-SC-2 strings. `fail_todo_assoc_const` (amended 2026-10-06, review fold: B13): the parser accepts `let X: type;` in `DeclScopeLoopAsRegular` without error (`HandleLetAfterPattern` consumes `=` only if present, parse/handle_let.cpp:89-92), so check emits exactly two diagnostics — `SemanticsTodo` "associated constant requirement in `template constraint`" at the `let` introducer (`HandleIntroducer`, handle_let_and_var.cpp:67-81, runs first) and then `ExpectedInitializerAfterLet` (kind.def:471; handle_let_and_var.cpp:405) at the declaration — in that order |
| check/testdata/named_constraint/template_constraint.carbon (round-7 splits, 2026-10-14) | new `fail_self_dependent_name` (`HasN` with `alias A = Self` and a nested `class Inner { var k: i32; }`; `AliasOfSelf`: `let unused y: HasN.A* = 1`; `NestedClassAs`: `let unused x: bool = 1 as HasN.Inner`; `NestedClassPointer`: `let unused y: HasN.Inner* = 1`); new `nested_class` (`Outer.Inner.N()` for a class with a method declared in a template constraint); `decl`'s comment | Round 7, written after the development build ran these shapes (observed, not counted, R16(d)): the fail split has the diagnostics of the `constraint` spelling on trunk 0bdce60a5, a `ConversionFailure` to `Self*`, to `Inner` with `as` followed by `Inner` to `bool`, and to `Inner*`, each with its `MissingImplInMemberAccessInContext` note; `nested_class` has no STDERR (its lowering aborts at sem_ir/mangler.cpp:185, as the `constraint` spelling does on trunk); the dumps of `decl`, `forward`, `compose` and `generic` show `Self`, the requirements' function types and their patterns `[symbolic]` where they were `[template]` (D-SC-10 as amended) FILLED 2026-10-14 (fill round 7, 36181a729): as written, observed and not counted |
| check/testdata/named_constraint/template_constraint.carbon (round-8 splits, 2026-10-14) | new `fail_todo_self_member_in_signature` (`HasNM` with `fn M(p: typeof(Self.N)*) -> i32`; `HasA` with `alias A = i32` and `fn Get(self) -> Self.A`); new `fail_todo_self_facet_in_signature` (`fn Wrap(self) -> Box(Self)` for `class Box(T: J)`; `fn Get(self) -> Self.(HasElem.Elem)`); new `self_facet_in_signature_required` (the same two with `require impls J` and `require impls HasElem`, a class `C` that has `impl as J`, `Wrap`, `V` and `Get`, `impl C as HasElem where .Elem = i32`, called through `CallWrap` and `CallGet`); new `fail_todo_unqualified_requirement_in_signature` (`fn M(p: typeof(N)*) -> i32`, a class mirroring it, `CallN(c)`) | Round 8, written after the round-7 build ran these shapes in the reviews' probes (observed, not counted, R16(d)): `IncompleteTypeInMemberAccessOfFacet` at `Self` of `Self.N` and of `Self.A`, each with `NamedConstraintIncompleteWithinDefinition` at the constraint; `ConversionFailureFacetToFacet` at `Box(Self)` with `InitializingGenericParam` at `T: J`, and at `Self.(HasElem.Elem)`; no STDERR for the required split; `ConversionFailureTypeToFacet` at `CallN(c)` with `StructuralMemberMismatch` at `C.M`, `StructuralRequirementHere` and `DeductionGenericHere`; the dumps of the four dumped splits unchanged FILLED 2026-10-14 (fill round 8, 3245ec0d2): as written, observed and not counted |
| check/testdata/named_constraint/template_constraint.carbon (round-9 changes, 2026-10-14) | `fail_todo_self_member_in_signature` gains `fn Get2(self) -> A` in `HasA`, a class `C` with `N` and `M(p: typeof(N)*)`, and `Test(c)` calling `CallN(c)`; `fail_todo_self_facet_in_signature` gains `HasAll` (`fn All(self) -> Core.Slice(Self)`), `HasNext` (`fn Next(self) -> Core.Optional(Self)`), a class `C` with `impl as J`, `Wrap` and `Get` and `impl C as HasElem where .Elem = i32`, a class `S` declaring `impl as Core.Copy` and `impl as Core.Destroy` before `All` and `Next`, and `Test(c, s)` calling `CallWrap(c)` twice, `CallGet(c)`, `CallAll(s)` and `CallNext(s)`; `self_facet_in_signature_required` gains `HasAll` and `HasNext` with `require impls Core.Copy & Core.Destroy`, the class `S` and `TestSlice(s)`, a class `D` with `Wrap` returning `i32` and `V`, and `overload fn P[template T: HasWrap]` / `P[T: type]` called as `P(c) + P(d)` | Round 9, predicted by hand before the fill (counted): no diagnostic at `Get2` and none at any use in the two `fail_todo_` splits (D-SC-9 as amended at fill round 9); no STDERR for the required split, `P(d)` skipping the constrained member (D-SC-12). Observed on the development build before the fill (not counted, R16(d)): `ConversionFailureFacetToFacet` at `Core.Slice(Self)`, into `Core.Destroy & Core.Copy`, and at `Core.Optional(Self)`, into `Core.OptionalStorage`, each with `InitializingGenericParam` at the prelude class's parameter FILLED 2026-10-14 (fill round 9, a5078358c): as predicted, and as observed |
| check/testdata/named_constraint/fail_todo_template_constraint_members.carbon (round-10 split, 2026-10-14) | new `fail_todo_tuple_pattern_param` (`HasF` with `fn F(self, (a: i32, b: i32))`; a class `D` with the same member; `Call[template T: HasF]` and `Test(d)` calling `Call(d)`); the file comment names the form | Round 10, derived by hand from D-SC-2 as amended at fill round 10 (the trunk analogs v06t and v06r abort on 0bdce60a5; observed on the development build first, so not counted, R16(d)): `SemanticsTodo` "tuple pattern parameter in `template constraint`" at the requirement; nothing at `Call(d)`, the requirement not being collected; no abort FILLED 2026-10-14 (fill round 10, 001cdb4c7): as derived |

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
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon (new at fill round 2; round-2 splits POST-FILL, round-3 splits PRE-FILL, 2026-10-13) | `fail_direct_call` (`HasCount.Count()`, `HasMake.Make()`); `fail_todo_runtime_facet` (`F.Make()`, `F.(HasMake.Make)()` through `let F: HasMake = C`); fill round 3: `fail_impl_member_alias` (`impl C as I { alias F = HasGet.Get; alias Mk = HasMake.Make; }` and `extend impl as I { alias F = HasGet.Get; ... }` in a class `D`, then `c.(I.F)() + d.F()` and `ViaHasF(d)` for a `template constraint HasF { fn F(self) -> i32; }`), `fail_ladder_alias` (`impl forall [template T: HasGet] T as NewF { alias DoF = HasGet.Get; }` with `G(c) + c.(NewF.DoF)()`) | Round 2, as filled: `fail_direct_call` `StructuralRequirementCalled` + `StructuralRequirementHere` twice; `fail_todo_runtime_facet` the same pair for `F.Make()` and `SemanticsTodo` (the fork's runtime-facet TODO, member_access.cpp:987-996) for the compound access. Round 3, predicted before the fill: `fail_impl_member_alias` three `ImplFunctionWithNonFunction` errors, each with `AssociatedFunctionHere` and `StructuralRequirementHere`, nothing at `Use` (the witness entries are errors), and at `UseStructurally` `ConversionFailureTypeToFacet` + `StructuralMemberMismatch` + `StructuralRequirementHere` + `DeductionGenericHere`, lookup of `F` in `D` resolving to the error entry (OBSERVED, not predicted: read off the review's probe p24 on the pre-fill build of round 3's own sources; on the build under review the alias built a thunk and the note would have read `StructuralMemberMissing`; relabelled 2026-10-13 at fill round 4, review finding MINOR-7); `fail_ladder_alias` one such triple and nothing at `Test` FILLED 2026-10-13 (fill round 3, bc8b37290): both round-3 predictions held as written; the observed `UseStructurally` clause is not counted as a prediction |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (round-2 splits POST-FILL; round-3 changes PRE-FILL, 2026-10-13) | `fail_own_params` (respelled at round 3, review finding F3: `fn Get[unused U: type](unused self) -> i32`, differing from the requirement only by its own parameter); `fail_alias_requirement` (`alias Get = HasGet.Get`); `fail_facet_type_self` (`F(HasCount)`) | Round 2, as filled: `ConversionFailureTypeToFacet` + `StructuralMemberMismatch` + `StructuralRequirementHere` + `DeductionGenericHere` for `fail_own_params`; the same with `StructuralMemberMissing` for `fail_alias_requirement`, and with `StructuralMemberMissing` and `InitializingGenericParam` for `fail_facet_type_self`. Round 3, predicted: `fail_own_params` unchanged in kinds; `StructuralMemberIsRequirement` (naming `HasGet` / `HasCount`) in place of `StructuralMemberMissing` in the other two FILLED 2026-10-13 (fill round 3, bc8b37290): held as written |
| check/testdata/named_constraint/template_constraint_compound_access.carbon (round-2 splits POST-FILL, 2026-10-13) | `assoc_fn_compound` (dumped: `ViaT`, `ViaType`, `ViaFacet`); `fail_assoc_fn_compound_unsatisfied` (`D.(HasMake.Make)()`, comment added at round 3, F9); `checked_generic_name` (dumped) | As filled: the two positives have no STDERR; the negative carries `ConversionFailureTypeToFacet` + `StructuralMemberMissing` + `StructuralRequirementHere` at the compound access AMENDED 2026-10-13 (fill round 4, PRE-FILL): `checked_generic_name`'s `G` named the requirement as a statement, `HasGet.Get;`, a value use that D-SC-20 as amended rejects; it is respelled `fn G[T: type](unused x: T, c: C) -> i32 { return c.(HasGet.Get)(); }`, still naming the requirement inside a checked generic, and predicted STDERR-free, its dump keeping the `.Self` binding and binding `C`'s own `Get` in `G`'s compound access FILLED 2026-10-13 (fill round 4, ff490bd48): held; `G` binds `name_ref Get, @C.%C.Get.decl` beside `%.Self.e0b: %HasGet.type = symbolic_binding .Self [symbolic_self]` |
| check/testdata/named_constraint/template_constraint_require.carbon (round-2 splits POST-FILL; round-3 splits PRE-FILL, 2026-10-13) | Round 2: `fail_require_in_interface_concrete_lacking`, `require_in_constraint`, `fail_require_in_constraint_unsatisfied` (comment added at round 3, F9), `extend_require`, `require_in_interface_in_class_impl`, `fail_require_in_interface_in_class_impl_lacking`, `fail_extend_impl_extend_require_self`. Round 3: `fail_require_mixed_in_class_impl_order` (`require impls HasGet & J` and `require impls J`, each with `impl as J` after the impl); `require_self_class_being_defined` (impls in a nested class whose self is the enclosing class, `Get` after and before the nested class, and `impl D as IU(F)` inside `F` for `IU(U)` doing `require U impls HasGet & J(Self)`, after `F`'s `impl as J(D)`; respelled after the first fill, miss (k)); `fail_require_self_class_being_defined_lacking`; `fail_todo_require_in_interface_in_generic_class_impl` (`Box(T)`, `Outer(T).Inner`, `Box2(template T)`) | Round 2, as filled: `InterfaceRequireImplsNotImplemented` alone for the two `_lacking` splits (the in-class one at the class end); the four positives STDERR-free; `fail_require_in_constraint_unsatisfied` `ConversionFailureTypeToFacet` + `StructuralMemberMissing` + `StructuralRequirementHere` + `DeductionGenericHere`; `fail_extend_impl_extend_require_self` `InterfaceRequireImplsNotImplemented` then `StructuralRequirementCalled` + `StructuralRequirementHere` at `c.Get()`. Round 3, predicted: `InterfaceRequireImplsNotImplemented` at `impl as I1` (`HasGet & J`, which the fill prints as `J & HasGet`) and at `impl as I2` (`J`); no STDERR for `require_self_class_being_defined`; one `InterfaceRequireImplsNotImplemented` at `impl Lacking as I`; and for the generic-class split `InterfaceRequireImplsNotImplemented` for `Box(T)` and for `Inner`, none for `Box2` (D-SC-19) AMENDED 2026-10-13 (fill round 3, bc8b37290, miss (l)): held, except that the `impl as I1` error prints the facet type as `J & HasGet`, not as written; `require_self_class_being_defined` is filled as respelled after miss (k) |
| check/testdata/named_constraint/template_constraint_satisfy.carbon (round-2 splits POST-FILL, 2026-10-13) | `nested_generic`; `as_facet` (dumped); `fail_todo_ambiguous_with_interface` (STDERR only; comment re-cited at round 3, MINOR-4 / F5) | As filled: the two positives STDERR-free; the `fail_todo` split `ResolvingSpecificHere` with the note `NameAmbiguousDueToExtend` |
| lower/testdata/template/template_constraint.carbon (round-2 split POST-FILL; round-3 split PRE-FILL, 2026-10-13) | `compound_nongeneric` (`c.(HasGet.Get)()` in a non-generic `Run`); fill round 3: `impl_member_alias` (`impl C as I { alias F = (C as HasGet).Get; }`, `c.(I.F)()`) | As filled: `compound_nongeneric` a `define` of `Run` calling `C.Get`'s symbol. Round 3, predicted: `impl_member_alias` a `define` of `Run` calling `C.Get`'s symbol directly (no thunk is built, the alias being `C.Get` itself), and no `CARBON_FATAL` (§1.E as amended) FILLED 2026-10-13 (fill round 3, bc8b37290): held; `Run` lowers as `@main` calling `@_CGet.C.Main`, with no thunk and no fatal |
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon (round-4 splits PRE-FILL, 2026-10-13) | `fail_requirement_as_value` (`HasN.N;`, `Take(HasN.N)`, `Take(HasGet.Get)`, `Take(Has(i32).N)`, `Take((HasGet & J).Get)`, `Take((HasN.N, 1))`, `Take({.f = HasN.N})`, with `fn Take[T: type](unused f: T)`); `fail_requirement_through_checked_binding_as_value` (`Take(T.N)` for `[T: I]`, `I` doing `extend require impls HasN`; `Take(x.Get)` and `Take((x.Get, 1))` for `[T: K]`, `K` doing `extend require impls HasGet`); `fail_impl_member_alias` gains upstream's twin, `impl E as OnlyF { alias F = I2.Get; }` | Round 4, predicted before the fill from D-SC-20 as amended (a requirement is never a runtime value; the check sits in `Convert`): each of the ten value uses gives exactly one `StructuralRequirementCalled`, now worded "requirement `N` of template constraint `HasN` can only be used through a type that satisfies it", located at the requirement expression itself (inside a literal, at the element), with `StructuralRequirementHere`, and nothing else (the argument's conversion fails, so the call is an error and deduction adds no note). The twin: `ImplFunctionWithNonFunction` + `AssociatedFunctionHere` and no `StructuralRequirementHere`. Every existing `StructuralRequirementCalled` line in the SC-1 goldens changes only its wording ("can only be called through" to "can only be used through") FILLED 2026-10-13 (fill round 4, ff490bd48): held, except miss (m): each of the nine argument uses also carries the note `InCallToFunctionParam` ("initializing function parameter", at `Take`'s parameter), the context the call-argument conversion attaches to any error inside it; the statement use has none; the twin and the rewording held |
| check/testdata/named_constraint/template_constraint_require.carbon (round-4 splits PRE-FILL, 2026-10-13) | `require_in_interface_in_union_impl` (`union U` with `impl as I` before its own `Get`, `I` doing `require impls HasGet`; `u.(I.F)() + CallGet(u)`); `fail_require_in_interface_in_union_impl_lacking` (`union Lacking { var a: i32; impl as I {} }`, and `union LackingMixed { var a: i32; impl as J {} impl as I2 {} }` with `I2` doing `require impls HasGet & J`) | Round 4, predicted: the positive has no STDERR; the negative has exactly two `InterfaceRequireImplsNotImplemented`, at `impl as I` ("requires that `Lacking` implements `HasGet`") and at `impl as I2` ("requires that `LackingMixed` implements `J & HasGet`", the order miss (l) found), each emitted at its union's end, and no CHECK failure at the end of the file (the new `VerifyOnFinish` check) FILLED 2026-10-13 (fill round 4, ff490bd48): held as written |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (round-4 change PRE-FILL, 2026-10-13) | `fail_own_params` respelled (review finding MINOR-3 of round 3's review 2): requirement `fn Get(self, n: i32) -> i32`, member `fn Get[U: type](unused self, unused n: U) -> i32`, `CallGet` calling `x.Get(1)` | Round 4, predicted: unchanged kinds, `ConversionFailureTypeToFacet` + `StructuralMemberMismatch` (at the member's declaration) + `StructuralRequirementHere` + `DeductionGenericHere` FILLED 2026-10-13 (fill round 4, ff490bd48): held as written |
| lower/testdata/template/template_constraint.carbon (round-4 split PRE-FILL, 2026-10-13) | `requirement_through_type_as_value` (`Take(C.(HasN.N)) + Take((C as HasN).N) + Dependent(c)`, `Dependent[template T: HasN]` returning `Take(T.N)`) | Round 4, predicted: a `define` of `C.N`, one `Take` specific (all three arguments have `C.N`'s function type, D-SC-4), a `Dependent` specific calling it, and `@main` calling `Take` twice and `Dependent` once; no `CARBON_FATAL` FILLED 2026-10-13 (fill round 4, ff490bd48): held; one `@_CTake.Main.…` specific, called twice from `@main` and once from the `Dependent` specific |
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon (round-5 splits PRE-FILL, 2026-10-13) | `fail_requirement_as_value` gains `TemplateValueParam` (`TemplateParam(HasN.N)` with `[template U: type](unused template f: U)`), `GenericValueParam` (the `generic f: U` form) and `Overload` (`P(HasN.N)` against `overload fn P(unused x: i32)` and `overload fn P[T: type](unused f: T)`); `fail_requirement_through_checked_binding_as_value` gains `BoundInStruct` (`Take({.a = x.Get})`); new `fail_requirement_through_template_instantiation` (`Tuple`, `Struct`, `Nested`, `IfTuple`, `LetTuple`, `Discard`, `DiscardTuple`, `DiscardStruct` and `Box(template FT: type).F` instantiated with `HasN`, `MethodTuple` with `HasGet & J`); new `fail_requirement_typeof_value` (a parameter of `typeof(HasN.N)`, `Take(w.f)` for a field of it, and `return HasN.N` from a function returning it) | Round 5, written before the fill from D-SC-20 as amended at round 5 (the development build's probes of the reviews' shapes ran first, R16(d) disclosure). Every existing `[StructuralRequirementCalled]` becomes `[StructuralRequirementUsed]` with unchanged text (review 2 finding MINOR-1). The two value parameters: one `StructuralRequirementUsed` each, located at the call (the deduced value is a constant with no location, so `Convert`'s location; review 1 finding MINOR-1), with `StructuralRequirementHere` and `DeductionGenericHere`. `Overload`: only `OverloadNoMatch` with two `OverloadCandidateRejected` notes (the candidates convert with diagnostics off). `BoundInStruct`: one `StructuralRequirementUsed` at `x.Get` with `StructuralRequirementHere` and `InCallToFunctionParam`. The instantiation split: one `ResolvingSpecificHere` ("unable to monomorphize specific") at each `Use*` call, two for `IfTuple` (one per branch), each with a `StructuralRequirementUsed` note and `StructuralRequirementHere`; for the call arguments (`Tuple`, `Struct`, `Nested`, `MethodTuple`, `Box`) the note has no location and is followed by `InCallToFunctionParam`, as upstream's own conversion notes for a constant argument at instantiation (trunk 0bdce60a5, `TakeI((T.N, 1))` with a class); for `LetTuple`, `IfTuple` and the three discards it is at the element or statement. The `typeof` split: three `StructuralRequirementUsed` (the parameter, `w.f`, `HasN.N`), each with `StructuralRequirementHere` only FILLED 2026-10-13 (fill round 5, 18775fee3): held as written NOT COUNTED 2026-10-14 (fill round 6, round 5's review 2 finding MINOR-1, R16(d)): the development build ran these shapes before the row was written, and clauses such as the unlocated note followed by `InCallToFunctionParam`, `IfTuple`'s two `ResolvingSpecificHere` and `Overload`'s two candidate notes read as observed; no clause of a round-5 row is counted as a prediction that held, as round 3's `UseStructurally` clause was withdrawn (round 3's review 2, MINOR-7) |
| check/testdata/named_constraint/template_constraint_compound_access.carbon (round-5 split PRE-FILL, 2026-10-13) | new `requirement_typeof` (dumped): `TypeOnly(typeof(HasN.N))`, a `typeof(HasN.N)*` parameter, a field of `typeof(HasN.N)`, `impl typeof(HasN.N) as Z` called as `typeof(HasN.N).(Z.F)()`, and `Generic[T: type]` taking a `typeof(Has(T).N)*`; `checked_generic_name`'s comment rewritten | Round 5, predicted: no STDERR; the dump shows `structural_requirement_type @HasN.WithSelf.N` as a concrete constant with an empty `struct_value ()` of it, and in `Generic` a symbolic `structural_requirement_type @Has.WithSelf.N, @Has(%T)`; no `.Self` binding inside the range. `checked_generic_name`'s `G` loses its `.Self` binding: `HasGet.Get` is a `name_ref` of the concrete requirement type, and the compound access still binds `C`'s own `Get` FILLED 2026-10-13 (fill round 5, 18775fee3): held, except miss (n): the `requirement_typeof` range does show a `.Self` binding, `%.Self.frozen: type`, upstream's frozen `.Self` of the `type` facet that the range's `[T: type]` and `(unused T: type)` parameters spell, as every such dump in the compound golden already did; no constraint's `.Self` appears NOT COUNTED 2026-10-14 (fill round 6, round 5's review 2 finding MINOR-1, R16(d)): written after the development build's probes, as the requirement-call row above; miss (n) stands as an error in the written row |
| lower/testdata/template/template_constraint.carbon (round-5 splits PRE-FILL, 2026-10-13) | new `requirement_through_template_instantiation` (the instantiation split's templates, less `Nested` and `IfTuple`, with a class `C`); new `requirement_typeof` (`Pointer`, `Wrapped(w: W)`, `Generic[T: type]` with an `array(typeof(Has(T).N), 0)` local, `Upstream(f: typeof(I.F))` called with `I.F`, `Satisfied(f: typeof(C.(HasN.N)))` called with `C.(HasN.N)`, and `typeof(HasN.N).(Z.F)()`) | Round 5, predicted: no `CARBON_FATAL` and no verifier failure; one `define` per template specific with `C`, calling `Take` specifics over `C.N`'s and `C.Get`'s function types; the requirement type lowers as `{}` (a `W` of one empty field, an empty-array local, a pointer parameter), and `@main` calls the impl's `F` by its mangled name. `Nested` and `IfTuple` are left out because their class instantiations fail on trunk 0bdce60a5 too (`Take(((C.N, 1), 2))` at the module verifier, lower/lower.cpp:48; the `if` form in `BranchWithArg`) FILLED 2026-10-13 (fill round 5, 18775fee3): held, except miss (o): the IR has one `Take` definition, `@_CTake.Main.1f03bbe8d00cdc13`, called for the three tuple shapes (`(C.N, 1)`, `(C.N, 1)` as `(typeof(C.N), i32)`, `(C.Get, 1)`) and one for the struct, not one per argument type, because the lower phase's specific coalescer (lower/specific_coalescer.cpp) merges specifics whose bodies are equivalent; the three specifics' mangled names differ (a `Take` whose body depends on `T` keeps three symbols), and trunk 0bdce60a5 coalesces the same three non-template calls into the same single definition AMENDED 2026-10-14 (fill round 6, round 5's review 2 finding MAJOR-2): the cause first written here, a mangling that does not distinguish the tuple types, was false NOT COUNTED 2026-10-14 (fill round 6, round 5's review 2 finding MINOR-1, R16(d)): written after the development build's probes, as the requirement-call row above; miss (o) stands as an error in the written row |
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon (round-6 change, 2026-10-14) | `fail_requirement_typeof_value` gains `impl W as Core.UnformedInit {}`, `fn Ref(unused ref f: typeof(HasN.N))` and `ReadField` (`var w: W`, then `Ref(ref w.f)`, `let unused v: typeof(HasN.N) = w.f;` and `Ref(ref HasN.N)`) | Round 6, written after the development build ran these shapes (R16(d) disclosure: observed, not counted): nothing at `Ref(ref w.f)`, a reference bound to a `ref` parameter; one `StructuralRequirementUsed` with `StructuralRequirementHere` at `w.f` in the `let`, a value read; one `StructuralRequirementUsed` with `StructuralRequirementHere` and `InCallToFunctionParam` at `ref HasN.N`, a requirement name; the three existing uses unchanged FILLED 2026-10-14 (fill round 6, fb12f63cb): as written, observed and not counted |
| check/testdata/named_constraint/template_constraint_import.carbon (round-6 splits, 2026-10-14) | new `requirement_type_a` (exports `HasN`, `Has(X: type)`, `Z`, `alias A = HasN.N`, `fn P(unused p: typeof(HasN.N)*)`, `impl typeof(Has(i32).N) as Z` and `Take`); new `requirement_type_b` (dumped: `Use(p: typeof(A)*)` returning `P(p) + typeof(Has(i32).N).(Z.F)() + C.(A)()`); new `fail_requirement_type_value` (`Take(A)`; `P(p)` for `p: typeof(Has(i32).N)*`) | Round 6, written after the development build ran these shapes (observed, not counted): `requirement_type_b` has no STDERR; its dump shows the imported `A` of the concrete `structural_requirement_type @HasN.WithSelf.N`, the imported impl's witness for `structural_requirement_type @Has.WithSelf.N, @Has(%i32)`, and `C.(A)` binding `@C.%C.N.decl` (D-SC-4); the fail split has one `StructuralRequirementUsed` with the imported `StructuralRequirementHere` and `InCallToFunctionParam`, and one `ConversionFailure` printing `<type of Has(i32).N>*` and `<type of HasN.N>*` FILLED 2026-10-14 (fill round 6, fb12f63cb): as written, observed and not counted |
| lower/testdata/template/template_constraint.carbon (round-6 split, 2026-10-14) | new `requirement_typeof_object`: `class W` with fields of `typeof(HasN.N)`, `(typeof(HasN.N), i32)`, `{.f: typeof(Has(i32).N), .x: i32}`, `array(typeof(HasN.N), 2)` and `i32`, and `impl W as Core.UnformedInit`; `class Box(T: type)` used as `Box(typeof(HasN.N))`; in `Run`, a `var` of each, `w.f;`, a discarded `MakeW()`, `MakeW().x`, `D(&w)` for `D[T: Core.Destroy](p: T*)`, `Ref(ref w.f)`, the `ref self` method `Z.M` through `w.f` and `w.t.0`, `Pass(&w.f)` for a checked `Pass[T: type](p: T*)` returning `Take(*p)`, `LetValue(&w.f)` for a template `let unused v: T = *p`, and `C.(w.f)()` | Round 6, written after the development build ran these shapes (observed, not counted): no STDERR and no `CARBON_FATAL`; the requirement type lowers as `{}` inside `W`'s and `Box`'s LLVM struct types; the synthesized `SubobjectDestroy` bodies call `SelfDestruct` on every element, the requirement-typed ones empty; `@main` calls the impl's `M` with the field's address and `C.N` for `C.(w.f)()`; compiled and linked outside the golden, the program returns 23 FILLED 2026-10-14 (fill round 6, fb12f63cb): as written, observed and not counted |
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon (round-7 changes, 2026-10-14) | `fail_requirement_as_value` gains `TupleIndex` (`(HasN.N, 1).1`); `fail_requirement_typeof_value` gains `class V` (fields of `typeof(HasN.N)` and `array(typeof(HasN.N), 2)`), `ConstParam`, `ConstPointer` (`Take(*p)` for `p: const typeof(HasN.N)*`), `ArrayLet`, `ArrayArg`, `class E` (a tuple and a struct field holding the type; a value `Get` reading `self.t.1` and a `GetRef(ref self)` reading `self.t.1 + self.s.x`), `StructField(e: E)` reading `e.s.x`, `VarParam(var x: typeof(HasN.N))` with `CallVarParam`, and `TemplateDeref` with `UseTemplateDeref`; new `fail_nested_requirement_as_value` (`Init`, `Statement`, `Call` and `Arg` naming `Outer.Inner.N`) | Round 7, written after the development build ran these shapes (observed, not counted, R16(d)): `TupleIndex` has one `StructuralRequirementUsed` and no `TupleIndexOnANonTupleType`; `ConstParam` one at the parameter; `ConstPointer` and `ArrayArg` one at the argument with `InCallToFunctionParam`; `ArrayLet` one at `v.a`; `Get` one at `self.t` and `StructField` one at `e.s`, each alone; `GetRef`, `VarParam` and `TemplateDeref`'s definition accepted; `CallVarParam` one at `w.f` with `InCallToFunctionParam` at the `var` parameter; `UseTemplateDeref` a `ResolvingSpecificHere` with the `StructuralRequirementUsed` note at `*p`, its requirement note and `InCallToFunctionParam`; the nested split one `StructuralRequirementUsed` per use naming `Inner`, with its requirement note, and `Arg` with `InCallToFunctionParam` FILLED 2026-10-14 (fill round 7, 36181a729): as written, observed and not counted |
| check/testdata/named_constraint/template_constraint_require.carbon (round-8 splits, 2026-10-14) | new `require_self_argument` (`ConvSelf` with `require Self impls Conv(Self)`, `HasSelf` with `require impls Has(Self)`, a class `C` satisfying both, `Test(c)` calling `CallDo` and `CallGet`); new `fail_require_self_argument_unsatisfied` (`D` without `impl D as Conv(D)` and with `fn Get(self) -> i32`, `TestConv` and `TestHas`) | Round 8, observed, not counted (R16(d)): no STDERR for the positive split; `ConversionFailureTypeToFacet` at `CallConv(d)` with `DeductionGenericHere` only (a nominal `require` has no structural note, D-SC-9), and at `CallHas(d)` with `StructuralMemberMismatch` at `D.Get`, `StructuralRequirementHere` at `Has`'s `Get` and `DeductionGenericHere` FILLED 2026-10-14 (fill round 8, 3245ec0d2): as written, observed and not counted |
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon (round-8 changes, 2026-10-14) | new `fail_todo_symbolic_facet` (`Has(X: type)` with `N` and `Get`, `Outer` declaring `Inner` with `M` and `G`, a class `C` with all four; `Compound` `C.(Has(T).N)()`, `ThroughAs` `(C as Has(T)).N()` and `Method` `c.(Has(T).Get)()` in checked generics `[T: type]`, `NestedCompound` `C.(Outer.Inner.M)()` and `NestedMethod` `c.(Outer.Inner.G)()`); `fail_todo_runtime_facet`'s cite and `fail_requirement_as_value`'s first sentence | Round 8, observed, not counted (R16(d)): the `SemanticsTodo` "through a symbolic facet" at `Compound` and `NestedCompound`; `StructuralRequirementUsed` at `(C as Has(T)).N` with its note; no diagnostic for the two method forms; `fail_todo_runtime_facet` keeps "through a runtime facet value" FILLED 2026-10-14 (fill round 8, 3245ec0d2): as written, observed and not counted |
| lower/testdata/template/template_constraint.carbon (round-8 split, 2026-10-14) | new `require_self_argument` (the require split's constraints and class, `Run` returning `CallDo(c) + CallGet(c)`) | Round 8, observed, not counted (R16(d)): `CallDo`'s specific calls `C.Do` of `impl C as Conv(C)` and then `C.V`, `CallGet`'s calls `C.Get` and then `C.V`, and `main` adds the two results FILLED 2026-10-14 (fill round 8, 3245ec0d2): as written, observed and not counted |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (round-9 split, 2026-10-14) | new `fail_requirement_signature_error` (`H` with `fn F(x: Undefined) -> i32`; `HasF` with `fn F(self) -> Undefined` and `G`; classes `C` with `F(x: i32)`, `D` with `F` and `G`, and an empty `E`; `overload fn P[template T: H]` / `P[T: type]`; `Test(c, d)` with `P(c)`, `G1(c)` twice and `G2(d)` twice; `TestMissing(e)` with `G1(e)`) | Round 9, predicted by hand before the fill from the trunk interface analog (sc1-fix9/t/e01t on 0bdce60a5; counted): `NameNotFound` at each `Undefined`; nothing at `Test`; at `G1(e)`, `ConversionFailureTypeToFacet` with `StructuralMemberMissing`, `StructuralRequirementHere` at `H.F` and `DeductionGenericHere` FILLED 2026-10-14 (fill round 9, a5078358c): as predicted |
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon (round-9 change, 2026-10-14) | `fail_todo_symbolic_facet`'s comment names W-232, rewrapped in its eight lines | Round 9: no CHECK line moves FILLED 2026-10-14 (fill round 9, a5078358c): as predicted |
| lower/testdata/template/template_constraint.carbon (round-9 split, 2026-10-14) | new `overload_probe_require` (`HasWrap` with `require impls J`, `fn Wrap(self) -> Box(Self)` and `V`; `C` with `impl as J`; `D` without; `overload fn P[template T: HasWrap]` / `P[T: type]`; `Run` returning `P(c) + P(d) - 30`) | Round 9, predicted by hand before the fill (counted): `Run` calls `P`'s specific for `C`, which returns 10, and the next member's for `D`, which returns 20; run as a program it returns 0 FILLED 2026-10-14 (fill round 9, a5078358c): as predicted |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (round-10 splits, 2026-10-14) | `fail_requirement_signature_error`'s comment narrowed; new `fail_requirement_signature_error_other_member` (`HasFG` with `fn F(self) -> Undefined` then `G`, `HasGF` the reverse; `Lacking` with `F` only, `WrongG` with `G` returning `bool`; `TestLacking` and `TestLackingGF` calling `CallFG(l)` and `CallGF(l)`, `TestWrongG` calling `CallFG(w)`), `fail_requirement_signature_error_other_constraint` (`HasF` in error, `HasG`, an interface `I`; `D` with `F` only; `CallFG[template T: HasF & HasG]`, `CallGF[template T: HasG & HasF]` and `CallFI[template T: HasF & I]`, each called with `d`), `fail_requirement_signature_error_require` (`HasFG` in error; `interface I { require impls HasFG; }`; `Lacking` and `Complete` each with `impl as I {}`, only `Complete` declaring `G`), `fail_member_signature_error` (`HasFG` with `F(self, x: i32) -> i32` and `G`; `ReturnError` and `ParamError` with an error in `F`'s return or parameter and `G`; `LackingG` with an error in `F` and no `G`), `fail_todo_requirement_signature_error_overload` (`H` in error; `C` with `F`; `overload fn P[template T: H]` / `P(x: i32)` called as `P(c)`) and `fail_todo_requirement_signature_error_blanket` (`HasF` in error; `impl forall [template T: HasF] T as I`; `D` with `F`; `d.(I.K)()`) | Round 10, derived by hand from the trunk analogs on 0bdce60a5 (round 9's review 1 t01, t03, t04, t13 and review 2 a01t, a03t, a04t, b01t, t02, t12; the fixer's n01 for the printed facet types and o01, o02 and k01 for the overload and blanket shapes; observed on the development build first, so not counted, R16(d)): `NameNotFound` at each `Undefined`; at each `Lacking` use `ConversionFailureTypeToFacet` with `StructuralMemberMissing` for `G` of the constraint used, `StructuralRequirementHere` at that `G` and `DeductionGenericHere`; at `CallFG(w)` the same with `StructuralMemberMismatch` at `WrongG.G`; at `CallFG(d)` and `CallGF(d)` the facet type printed `HasF & HasG`, the note for `HasG`'s `G`; at `CallFI(d)` `ConversionFailureTypeToFacet` into `I & HasF` with `DeductionGenericHere` and no structural note; `InterfaceRequireImplsNotImplemented` at `Lacking`'s `impl as I` and nothing at `Complete`'s; nothing at `Test(r, p)` and the missing `G` at `Call(l)`; `OverloadNoMatch` with `OverloadCandidateRejected` notes (deduction, then conversion) at `P(c)`; `MissingImplInMemberAccess` at `d.(I.K)()` (W-233) FILLED 2026-10-14 (fill round 10, 001cdb4c7): as derived |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (round-10 split after 001cdb4c7, 2026-10-14) | new `fail_incomplete_and_interface` (`HasGet` and an empty `interface I`; incomplete classes `Inc` and `Impl`, with `impl Impl as I {}`; `F(template T: HasGet & I)` called with each) | Round 10, derived by hand from R-6's `fail_incomplete` and the trunk analog sc1-fix10/t n02 on 0bdce60a5 (observed on the round-10 build first, sc1-fix10/q q01 and q02, so not counted, R16(d)): `UnusedBinding` at `T`; at `F(Inc)` `StructuralRequirementIncompleteType` with `ClassForwardDeclaredHere` and `InitializingGenericParam`, then `ConversionFailureTypeToFacet` into `I & HasGet` with `InitializingGenericParam`; at `F(Impl)` the incomplete-type error alone FILLED 2026-10-14 (fill round 10, 0d7ee5c19): as derived |
| lower/testdata/template/template_constraint.carbon (round-10 change, 2026-10-14) | `overload_probe_require`'s `Run` returns `P(c) * 2 + P(d) - 40` and its comment gives both selections (round 9's review 1 finding MINOR-4) | Round 10, derived by hand: `C` selects the constrained member, which returns 10, and `D` the next, which returns 20, so 10 * 2 + 20 - 40 = 0, where the swapped selection gives 10; run as a program it returns 0 FILLED 2026-10-14 (fill round 10, 001cdb4c7): as derived; the IR calls `P`'s `overload0` specific for `C`, doubled, and `overload1` for `D`, then subtracts 40, and the extracted split returns 0 |
| check/testdata/named_constraint/template_constraint_require.carbon (round-10 change, 2026-10-14) | `fail_todo_require_in_interface_in_generic_class_impl`'s comment re-points structural_conformance.cpp:533 to :541, in its line | Round 10: no CHECK line moves FILLED 2026-10-14 (fill round 10, 001cdb4c7): as stated |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (round-11 splits, 2026-10-14) | `fail_requirement_signature_error`'s and `fail_member_signature_error`'s comments narrowed; new `fail_requirement_signature_error_genuine` (`HasReturnError` with `fn F(self, x: i32) -> Undefined` and `HasParamError` with `fn F(self, x: Undefined, y: i32) -> i32`; classes `Arity`, `ParamType`, `NoSelf`, `Field` and `ReturnOnly` called through `CallR`, `ParamArity`, `OtherParam`, `ParamReturn` and `ParamOnly` through `CallP`) and `fail_member_signature_error_genuine` (`HasF` with `fn F(self, x: i32, y: i32) -> i32`; classes `ReturnErrorArity`, `ReturnErrorParamType`, `ReturnErrorRefSelf`, `ParamErrorArity`, `ParamErrorOtherParam`, `ParamErrorReturn`, `ParamErrorNoSelf` and `ErrorsOnly`, each called through `Call`); `fail_todo_requirement_signature_error_overload` adds `HasG`, `D` with `fn G(self) -> Undefined`, `overload fn Q[template T: HasG]` / `Q(x: i32)` called as `Q(d)`; `fail_todo_requirement_signature_error_blanket` adds `J`, `impl forall [template T: HasF & J] T as J` and `d.(J.L)()` | Round 11, derived by hand from the trunk impl analogs on 0bdce60a5 (sc1-fix11/p/s tr_* and tm_*, one per class; round 10's reviews' x1t to y3t, b07t to b11t, r01t to r04t, f01t, o6t and c1t; observed on the development build first, so not counted, R16(d)): `NameNotFound` at each `Undefined`; at each use of `Arity`, `ParamType`, `NoSelf`, `Field`, `ParamArity`, `OtherParam` and `ParamReturn` `ConversionFailureTypeToFacet` with `StructuralMemberMismatch` (at the member; at the use for `Field`), `StructuralRequirementHere` and `DeductionGenericHere`, and nothing at `TestOnly`; the same at each member-side use but `TestErrorsOnly`, which gives nothing; at `Q(d)` `OverloadNoMatch` with the two `OverloadCandidateRejected` notes (deduction, then conversion); at `d.(J.L)()` `ImplLookupCycle` with `ImplLookupCycleNote` at the impl, then `MissingImplInMemberAccess` FILLED 2026-10-14 (fill round 11, e7783c80e): as derived |
| check/testdata/named_constraint/fail_todo_template_constraint_members.carbon (round-11 change, 2026-10-14) | `fail_todo_tuple_pattern_param` adds `fn G(self, (a: i32, b: i32) = (1, 2))` and `D`'s matching `G`; the comment names the three forms | Round 11, derived by hand from D-SC-2 as amended at fill round 11 (round 10's review 1 tp01 and tp11 abort at merge.cpp:391 on 001cdb4c7, tp01t on trunk; observed on the development build first, so not counted, R16(d)): a second `SemanticsTodo` "tuple pattern parameter in `template constraint`", at `G`; nothing at `Call(d)`; no abort FILLED 2026-10-14 (fill round 11, e7783c80e): as derived |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (round-12 splits, 2026-10-14) | the two `_genuine` splits' comments restated (one rule); `fail_requirement_signature_error_genuine` adds `HasDefaultError` (`fn F(self, x: i32, y: i32 = Undefined) -> i32`) and `HasStaticParamError` (`fn F(w: Self, x: Undefined) -> i32`), the class `OtherParamConvertible` (`y: i64`) called through `CallP`, `DefaultParamType` (`x: bool, y: i32 = 1`), `DefaultType` (`y: bool = true`), `DefaultOnly` (`y: i32 = 1`) and `DefaultBothErrors` (`y: i32 = Undefined`) through the `HasDefaultError` caller, and `MethodForStatic` (`fn F(self, x: i32)`) through the `HasStaticParamError` caller; `fail_member_signature_error_genuine` adds `ParamErrorVar` (`x: Undefined, var y: i32`), `ParamErrorGeneric` (`[unused U: type]` and `x: Undefined`), `DefaultErrorType` (`y: bool = Undefined`) and `DefaultOnly` (`y: i32 = Undefined`), each called through `Call`; new `fail_static_for_method` (`HasGet` with `fn Get(self) -> i32`, `C` with `fn Get(unused c: C) -> i32`, `CallGet(c)` calling `x.Get()`) | Round 12, derived from the rule and checked against the trunk impl analogs on 0bdce60a5 (sc1-fix12/p/s, one per class; observed on the development build first, so not counted, R16(d)): `NameNotFound` at each `Undefined`; at the uses of `OtherParamConvertible`, `DefaultParamType`, `DefaultType`, `ParamErrorVar`, `ParamErrorGeneric` and `DefaultErrorType` `ConversionFailureTypeToFacet` with `StructuralMemberMismatch` at the member, `StructuralRequirementHere` and `DeductionGenericHere`; nothing at `TestDefaultOnly` (both splits) or `TestMethodForStatic`; no abort at `DefaultBothErrors`; at `CallGet(c)` in `fail_static_for_method` the same four, with no monomorphization error after them FILLED 2026-10-14 (fill round 12, 62d39c9f6): as derived; the splits give 15, 23 and 1 errors |
| check/testdata/named_constraint/template_constraint_satisfy.carbon (round-12 split, 2026-10-14) | new `method_for_assoc_fn` (`HasGet` with `fn Get(x: Self) -> i32`, `C` with `fn Get(unused self) -> i32`, `CallGet` calling `T.Get(x)`, `Test(c)`) | Round 12, derived from D-SC-5(d) as amended: no STDERR, no SemIR dump (no dump range) FILLED 2026-10-14 (fill round 12, 62d39c9f6): as derived |
| check/testdata/named_constraint/fail_todo_template_constraint_members.carbon (round-12 change, 2026-10-14) | each `fail_todo_` split's comment starts with its residue, "TODO: W-137.", "TODO: W-136.", "TODO: W-135." and "TODO: W-234." (round 11's review 2 finding MINOR-3) | Round 12: no CHECK line changes, the CHECK lines' offsets being relative FILLED 2026-10-14 (fill round 12, 62d39c9f6): as stated, autoupdate one dot |
| check/testdata/named_constraint/template_constraint_require.carbon (round-12 change, 2026-10-14) | `fail_todo_require_in_interface_in_generic_class_impl`'s comment re-points structural_conformance.cpp:541 (stale since fill round 11) to :562, D-SC-6's branch, in its line | Round 12: no CHECK line moves; the gate passes it on the toolchain stamped 0.0.0-0.dev+62d39c9f6 |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (round-13 splits, 2026-10-14) | the two `_genuine` splits' comments restated (the rule as narrowed at fill round 13); `fail_requirement_signature_error_genuine`: `ParamOnly` becomes `fn F(unused self, unused x: i32, unused y: i32) -> i32` and round 12's `ref x: i32` member becomes the new `ParamRef`, called through `CallP`; new `ReturnAbsent` (`fn F(unused self, unused x: i32) {}`) through `CallR`; new `DefaultAbsent` (`y: i32`), `DefaultRef` (`ref y: i32 = 1`) and `DefaultVar` (`var y: i32 = 1`) through the `HasDefaultError` caller; `fail_member_signature_error_genuine`: new `HasDefault` (`fn F(self, x: i32, y: i32 = 1) -> i32`) and `HasNoReturn` (`fn F(self, x: i32, y: i32);`), each with its caller; round 12's member-side `DefaultOnly` (`y: i32 = Undefined`) renamed `DefaultError`, still called through `Call`; a new `DefaultOnly` of the same signature through the `HasDefault` caller; new `ParamErrorRef` (`ref x: Undefined`) and `DefaultErrorRef` (`ref y: i32 = Undefined`) through `Call`, and `ReturnErrorAbsent` (`-> Undefined`) through the `HasNoReturn` caller | Round 13, derived from the rule and checked against the trunk impl analogs on 0bdce60a5 (sc1-fix13/p/s, one per class, with each class's no-error twin; observed on the development build first, so not counted, R16(d)): `NameNotFound` at each new `Undefined`; at the uses of `ParamRef`, `ReturnAbsent`, `DefaultAbsent`, `DefaultRef`, `DefaultVar`, `DefaultError`, `ParamErrorRef`, `DefaultErrorRef` and `ReturnErrorAbsent` `ConversionFailureTypeToFacet` with `StructuralMemberMismatch` at the member, `StructuralRequirementHere` and `DeductionGenericHere`; nothing at `TestOnly` (`ParamOnly`, `ReturnOnly`), `TestDefaultOnly` (both splits) or `TestMethodForStatic`; of the trunk analogs only `DefaultErrorRef`'s reports ("value expression passed to reference parameter"), and the analog of the member-side `DefaultOnly` aborts at thunk.cpp:169 (W-236) FILLED 2026-10-14 (fill round 13, 2af5604a3): as derived; the splits give 20 and 31 errors (15 and 23 in the round-12 golden), and every other split its round-12 count |
| check/testdata/named_constraint/template_constraint_require.carbon (round-13 change, 2026-10-14) | `fail_todo_require_in_interface_in_generic_class_impl`'s comment re-points structural_conformance.cpp:562 (stale since fill round 13) to :569, D-SC-6's branch, in its line | Round 13: no CHECK line moves; the gate passes it on the toolchain stamped 0.0.0-0.dev+dfd22bdd6 |

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
    condition (pass `false`; file for SC-B2). TAKEN 2026-10-14 (fill round 7)
    on a different falsifier: round 6's review 1 BLOCKER-1, check-clean
    non-template programs aborting lowering (D-SC-10).
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
0.0.0-0.dev+bc8b37290 (below). Fill round 4 folds round 3's two implementation
reviews: aa67ea281 (fixes, test sources, the design page, records), ff490bd48 (6
goldens refilled) and d232d4753 (records); it re-measured the same totals on the
toolchain stamped 0.0.0-0.dev+ff490bd48 (below). Fill round 5 folds round 4's
two implementation reviews: 616d0bc4f (fixes, test sources, the design page,
records), 18775fee3 (5 goldens refilled) and df5120d03 (records); it re-measured
the same totals on the toolchain stamped 0.0.0-0.dev+18775fee3 (below). Fill
round 6 (2026-10-14) folds round 5's two implementation reviews: 56e400145
(fixes, test sources, the design page, records), fb12f63cb (3 goldens, CHECK
lines only) and 857d5b048 (records); it re-measured the same totals on the
toolchain stamped 0.0.0-0.dev+fb12f63cb (below), again on 857d5b048 for the
records commit after it. Fill round 7 (2026-10-14) folds round 6's two
implementation reviews (REJECT on one BLOCKER, and APPROVE-WITH-FIXES; 7
findings, none rejected): a template constraint's `Self` is a checked-phase
binding, D-SC-10's break condition; `const` and array types hold the
requirement's type; a class value's field is reached through a reference:
c0fa52df2 (fixes, test sources, the design page, records), 36181a729 (2 goldens,
CHECK lines only) and 30716a8c2 (records); it measured the same totals on the
toolchain built from its sources, again on the clean-stamped toolchain of
36181a729 (`carbon version` 0.0.0-0.dev+36181a729, below) and again on 30716a8c2
for the records commit after it. Fill round 8 (2026-10-14) folds round 7's two
implementation reviews (APPROVE-WITH-FIXES both; 9 findings, none rejected): the
checked-phase `Self` is kept as a trade, re-weighed, with what it rejects (filed
as W-169) and what it accepts recorded and pinned, and the compound-access TODO
names a symbolic facet: 4c2ecee22 (fixes, test sources, the design page,
records), 3245ec0d2 (4 goldens, CHECK lines only), 253dd4031 and a13e70542
(records); it measured the same totals on the toolchain built from its sources,
again on the toolchain stamped 0.0.0-0.dev+3245ec0d2 (below) and again on
a13e70542 for the records commit after it. Fill round 9 (same day) folds round
8's two implementation reviews (APPROVE-WITH-FIXES both; 12 findings, one
rejected in part): a mismatch against a requirement whose declaration has an
error is not diagnosed again at each use, the trade's lost and restorable
signatures are pinned in the repository, the records' overstatements are
corrected and the symbolic-facet compound access is filed as W-232: 58dc46eb6
(the fix, test sources, the design page, records), a5078358c (3 goldens, CHECK
lines only) and 6231d5b42 (records); it measured the same totals on the
toolchain built from its sources, again on the toolchain stamped
0.0.0-0.dev+a5078358c (below) and again on 6231d5b42, for itself and for the
records commit after it, ae807c7e8, which completes round 8's review record.
Fill round 10 (same day) folds round 9's two implementation reviews
(APPROVE-WITH-FIXES both; 11 findings, none rejected): only a requirement that
cannot be compared with a type's member, because its declaration or the member's
has an error, is skipped, so the failures round 9's guard hid are reported again
(its test was still too broad, round 11 below); a requirement with a tuple
pattern parameter, which aborted every use, is a TODO; the follow-on of an
overload set or a blanket impl after such an error is filed as W-233 and the
TODO as W-234: 3ae639811 (fixes, test sources, the design page, records),
001cdb4c7 (3 goldens, CHECK lines only), 04755f23b (the split pinning an
incomplete type's interfaces after its structural error, and its records),
0d7ee5c19 (its golden, CHECK lines only) and 6247769bb (records); it measured
the same totals on the toolchain built from its sources, again on the toolchain
stamped 0.0.0-0.dev+001cdb4c7 (below) and again on 6247769bb for the records
commit after it, which completes round 9's review record. Fill round 11 (same
day) folds round 10's two implementation reviews (APPROVE-WITH-FIXES both; 8
findings, none rejected): a mismatch is skipped only where an error causes it,
so every other difference from a requirement with an error, or from a member
with one, is reported as trunk's impl analog reports it; a tuple pattern
parameter under a default value is the TODO too; the impl-lookup cycle after the
error and W-233's member side are pinned; the ledger's SC-1 cites are checked
mechanically at the head: 2ee29f311 (fixes, test sources, the design page),
e7783c80e (2 goldens, CHECK lines only) and fa9038828 (records), which completes
round 10's review record; it measured the same totals on the toolchain built
from its sources, again on the toolchain stamped 0.0.0-0.dev+e7783c80e (below),
again on fa9038828 for 93f2b9f24, which checks round 11's records against the
head, and again on 93f2b9f24 for the records commit after it, 62e25dcdd. Fill
round 12 (same day) folds round 11's two implementation reviews
(APPROVE-WITH-FIXES both; 10 findings, none rejected): the error handling is one
rule, D-SC-5(d)'s comparison in an errors-match mode of upstream's own
comparison, which reads an erroneous default value as an error, so the new abort
on two of them and the spurious mismatch beside one are gone; a requirement with
`self` needs a member with `self`; the `fail_todo_` splits name their W-ids;
upstream's abort on a redeclaration with two erroneous default values is filed
as W-235: a6289f86e (fixes, test sources, the design page), 62d39c9f6 (1 golden,
CHECK lines only) and 9af776bac (records); it measured the same totals on the
toolchain built from its sources, again on the toolchain stamped
0.0.0-0.dev+62d39c9f6 (below) and again on 9af776bac for the records commit
after it, which writes round 11's review record below. Fill round 13 (same day)
folds round 12's two implementation reviews (APPROVE-WITH-FIXES both; 10
findings, none rejected): the errors-match mode compares a parameter with an
error as declared, so a binding form and whether a default value or a return
type is there are compared beside an error, only an erroneous type or default
value counting as equal; the rule is stated identically in the code, D-SC-9, the
decision log and the design page; the three missing fork markers are added;
trunk's thunk abort on an interface member's default value is filed as W-236:
dfd22bdd6 (fixes, test sources, the design page), 2af5604a3 (1 golden, CHECK
lines only) and 6992c6cc5 (records), which writes round 12's review record
below; it measured the same totals on the toolchain built from its sources,
again on the toolchain stamped 0.0.0-0.dev+dfd22bdd6 (below) and again on
6992c6cc5 for the records commit after it. Not of record until
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
-   (m) round 4's fill: the §4.B requirement-call row predicted exactly one
    error and its requirement note for each value use; each of the nine uses
    that is a call argument also carries `InCallToFunctionParam`
    ("initializing function parameter"), the context the call-argument
    conversion attaches to any error inside it (upstream's shape). A
    prediction error; the row carries a dated amendment.
-   (n) round 5's fill: the §4.B compound row predicted no `.Self` binding in
    the `requirement_typeof` range; the range shows `%.Self.frozen: type`,
    upstream's frozen `.Self` of the `type` facet its `T: type` parameters
    spell, as every such compound dump does, and no constraint's `.Self`. A
    prediction error; the row carries a dated amendment.
-   (o) round 5's fill: the §4.B lower row predicted `Take` specifics over
    `C.N`'s and `C.Get`'s function types; the IR has one `Take` definition
    called for the three tuple shapes, because lower/specific_coalescer.cpp
    merges the three specifics, whose bodies are equivalent; their mangled
    names differ (round 5's review 2 probes adv2/mg), and trunk 0bdce60a5
    coalesces the same calls written without a template. A prediction error;
    the row carries a dated amendment. (Amended 2026-10-14, fill round 6, round
    5's review 2 finding MAJOR-2: the cause first recorded, a trunk mangling
    that does not distinguish the tuple types, was false.)

Round 1's four mechanisms (1a7cce0b2), each now golden-pinned: the member's own
specific in `RequirementMatches` (satisfy `generic_self`, `nested_generic`;
unsatisfied `fail_generic_self_wrong_return`, `fail_own_params`); the `.Self`
lookup, D-SC-20 (compound `checked_generic_name`, lower `compound_nongeneric`;
SUPERSEDED at fill round 5, which deleted the lookup and gave the name the
concrete `StructuralRequirementType`, so those two splits now pin the concrete
type; amended 2026-10-14, round 5's review 2 finding MINOR-4);
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
    through an interface", filed at fill round 4 as W-168, the id the
    orchestrator reserved for it (SC-1 held no reserved id above W-151;
    W-152..W-159 are EV-1's, ST-1 starts at W-160).
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
    SUPERSEDED 2026-10-13 (fill round 5): a requirement named with no self type
    is a value of its own concrete type, so nothing depends on its `Self`, and
    both the `.Self` lookup and the generic.cpp early return are deleted
    (D-SC-20 as amended).
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
    rejected member, a mismatch. That mismatch is a follow-on of the impl
    error, reached through the error witness entry, not through the thunk
    test, which BLOCKER-1's rejection left unreachable and fill round 4
    deleted (review finding MINOR-1 of round 3's review 2; the split pins the
    follow-on, not the test).
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
    W-033. The ambiguity residue's ledger id stayed pending at round 3 (SC-1
    held no reservation above W-151, the W-151 paragraph below); it is W-168
    since fill round 4.
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
None of the 15 findings is rejected. Tally (corrected at fill round 4, review
finding MINOR-6 of round 3's review 2): round 3 fixed 13 as asked and took two
in part, MAJOR-1 (its second guard declined) and F5 (the cites, not the ledger
id); with F5's id filed at round 4 as W-168, 14 are done as asked and MAJOR-1 in
part.

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
-   **A thunk is not a requirement** (round 3's structural_conformance.cpp
    :641-647 in `GetStructuralRequirementConstraint`; MAJOR-1). A function of
    any special kind is never a requirement; the "no definition" guard is
    declined (handle_function.cpp:1212-1225 keeps a requirement written with a
    body collected). Design: D-SC-2, D-SC-15. SUPERSEDED 2026-10-13 at fill
    round 4 (review finding MINOR-1 of round 3's review 2, R17): the test is
    deleted. Once a requirement is no impl member (the decision above), no
    thunk's callee is a requirement (thunks are built only for impl members,
    impl.cpp, and for virtual overriders, class.cpp, whose callee is a class
    member), so the test could not be reached and no split could pin it. If an
    impl member could again alias a requirement, the decision above has hit
    its break condition, and the test returns with it.
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
(written `HasGet & J`); each round-3 row now says so, dated. One clause of the
requirement-call row, the `StructuralMemberMismatch` at `UseStructurally`, was
read off the pre-fill build of round 3's own sources (probe p24) and is not
counted as a prediction that held (fill round 4, review finding MINOR-7 of round
3's review 2, R16(d)).

Round 3's own diff (0efe76e7d, bc8b37290, 5171e5eda, 2497d5000) had two
implementation reviews: review 1, REJECT, 1 BLOCKER, 1 MAJOR and 2 MINOR
(BLOCKER-1, MAJOR-1, MINOR-1, MINOR-2), and review 2, APPROVE-WITH-FIXES, 2
MAJOR and 7 MINOR (MAJOR-1, MAJOR-2, MINOR-1 to MINOR-7), 13 findings, with the
two MAJOR-1s the same defect and review 1 MINOR-1 / review 2 MINOR-2 and review
1 MINOR-2 / review 2 MINOR-5 overlapping. Both confirmed round 3's folds on the
0.0.0-0.dev+bc8b37290 driver, its gate (1959 passed, 0 failed) and its
conformance (130 / 0 / 21 over 151) privately. Fill round 4 folds all 13, below.

Fill round 4 (2026-10-13), by review finding (review 1 BLOCKER-1 / MAJOR-1 /
MINOR-n, review 2 MAJOR-n / MINOR-n), each reproduced first on the toolchain
stamped 0.0.0-0.dev+bc8b37290 with the reviews' probes:

-   BLOCKER-1 (review 1): a requirement named with no satisfying self and passed
    as a value, `Take(HasN.N)` for `fn Take[T: type](unused f: T)`, checked
    clean and aborted lowering at lower/type.cpp:459 ("Found symbolic type id
    after resolution": the `.Self`-symbolic function type in a concrete
    specific), as did `Take(HasGet.Get)`, `Take(Has(i32).N)`, `Take((HasGet &
    J).Get)`, `Take((HasN.N, 1))` and `Take({.f = HasN.N})`; found through a
    checked binding's `extend require`, `Take(x.Get)`, `Take((x.Get, 1))` and
    `Take({.a = x.Get})` crashed lowering the specific (a segmentation fault
    lowering the call, tuple or struct), the bound method naming the bodiless
    requirement. Round 3 had guarded only the impl member; the value use is now
    rejected at one place, `Convert`, which every argument, initializer, return
    and discarded expression passes through (AMENDED 2026-10-13, fill round 5:
    false, round 4's reviews found `typeof`, which converts nothing, and a
    template's instantiation, which converts constant values and replays
    conversions without `Convert`'s check; see round 5)
    (structural_conformance.cpp:681 `CheckValueIsNotStructuralRequirement`,
    called at convert.cpp:2625 beside the fork's overload-set check): a
    requirement, a bound method of one, or a tuple or struct literal holding one
    (a conversion to the literal's own type does not visit its elements) is
    `StructuralRequirementCalled`, now worded "can only be used through a type
    that satisfies it" and emitted by one helper for both uses
    (structural_conformance.cpp:654). D-SC-9 and D-SC-20 amended. Pinned by
    requirement-call `fail_requirement_as_value` (a statement, five arguments, a
    tuple element, a struct field) and
    `fail_requirement_through_checked_binding_as_value` (`T.N`, `x.Get`,
    `(x.Get, 1)`), and lower `requirement_through_type_as_value`
    (`Take(C.(HasN.N))`, `Take((C as HasN).N)` and a template's `Take(T.N)`
    lower to one `Take` specific). Compound `checked_generic_name` named the
    requirement as a statement, `HasGet.Get;`, now a value use; it is respelled
    to name the requirement in a compound access inside the same checked
    generic, which keeps it positive and keeps its `.Self` dump (§4.B compound
    row, dated). Every other `StructuralRequirementCalled` line changes its
    wording only.
-   MAJOR-1 (both reviews): an impl inside a `union` body waited, as an
    in-class impl does, but only `ClassDefinition` drained the list, so its
    structural `require` was never checked and an invalid program compiled
    and ran (review 1 u01, review 2 p01, p07 and p13). The `UnionDefinition`
    handler drains it too (handle_union.cpp:99), and `Context::VerifyOnFinish`
    checks that the list is empty (context.cpp:83). D-SC-8(iii) and the
    design page say "class or union". Pinned by require
    `require_in_interface_in_union_impl` and
    `fail_require_in_interface_in_union_impl_lacking` (with review 2 p13's
    mixed `HasGet & J`).
-   MINOR-1 (review 1) and MINOR-2 (review 2): every cite of the rule that a
    requirement is not a member of the type and implements no impl member
    names D-SC-5(c): impl.cpp:58, structural_conformance.cpp:61 and :441,
    requirement-call `fail_impl_member_alias`, unsatisfied
    `fail_alias_requirement` and `fail_facet_type_self`, require
    `fail_extend_impl_extend_require_self`, and the design page. The cites of
    the lookup path and the access decision keep D-SC-5(b), and the decision
    log's round-2 "D-SC-5(b) clarified" is the amendment filed under (c).
    Comment-only edits.
-   MINOR-2 (review 1) and MINOR-5 (review 2): the ambiguity residue is W-168
    (the satisfy `fail_todo_ambiguous_with_interface` comment, same line
    count); the generic-class `fail_todo` comment cites
    structural_conformance.cpp:495, the checked-symbolic branch.
-   MAJOR-2 (review 2): the PR body's attribution paragraph names no model.
-   MINOR-1 (review 2): the thunk test is deleted (round 3's "A thunk is not a
    requirement", superseded above). `fail_impl_member_alias`'s comment says
    that its `UseStructurally` mismatch is a follow-on of the impl error, and
    the split gains upstream's twin, `impl E as OnlyF { alias F = I2.Get; }`
    (`ImplFunctionWithNonFunction` with no requirement note), so the parity
    round 3's impl-member decision relies on is golden-pinned.
-   MINOR-3 (review 2): unsatisfied `fail_own_params` is the deducible shape,
    requirement `fn Get(self, n: i32) -> i32` against member `fn Get[U:
    type](unused self, unused n: U) -> i32`, which a call deduces (`U = i32`)
    and W-136's break condition would flip; the F3 spelling's `U` was
    deducible from nothing.
-   MINOR-4 (review 2): the design page's accepted alias is qualified: for a
    class that declares its own matching `F`.
-   MINOR-6 (review 2): round 3's tally is restated (above, the decision log,
    W-027, ORCHESTRATION).
-   MINOR-7 (review 2): the `UseStructurally` clause of the round-3
    requirement-call row is relabelled as observed and not counted as held;
    round 4's §4.B rows were written from the design text before the build
    under test ran on them.

Rejected or narrowed: none of the 13.

Round 4's decisions as R29(a) implementation decisions, with design citation and
break condition:

-   **A requirement is never a runtime value** (structural_conformance.cpp:681
    `CheckValueIsNotStructuralRequirement`, convert.cpp:2625; BLOCKER-1). A
    requirement has no runtime identity: its witness is the self type's own
    member set (D-SC-4), and named with no satisfying self its `Self` is
    `.Self` (D-SC-20), which nothing replaces. The check sits where the fork's
    overload sets are refused as values (F-009, D-OV-4 step 6), whatever the
    target, so the uses that are not values (a callee, call.cpp:851; the
    member of a compound access; an `alias`) are untouched and a discarded
    `HasN.N;` is refused like a discarded overload set. Design: D-SC-20 and
    D-SC-9 as amended. Break condition: W-138's structural witness table
    lands, or upstream gives a facet type's member a value whose self is
    supplied later; then a requirement value names that entry instead of
    being refused. AMENDED 2026-10-13 (fill round 5, round 4's review 1
    MAJOR-1 and review 2 MAJOR-1): the claim that this check addressed the
    root cause, and that a callee, a compound member and an `alias` were the
    only uses that convert nothing, was false; the root cause was the
    `.Self`-symbolic type, which `typeof` and a template's instantiation
    carried past the check. Round 5 gives the requirement a concrete type
    (D-SC-20 as amended) and keeps the refusal as the design rule, type-based
    and replayed at instantiation.
-   **A union drains its waiting `require`s** (handle_union.cpp:99,
    context.cpp:83; MAJOR-1). Design: D-SC-12 (a union is a class, and its
    methods satisfy as a class's do) and D-SC-8(iii) as amended. Break
    condition: D-SC-8(iii)'s; the empty-list check stays as long as the list
    does.

Round 4's fill predictions, checked against the fill (ff490bd48): every round-4
row of §4.B held except miss (m), the `InCallToFunctionParam` note on each
argument use; each round-4 row says so, dated. Pinned by the round-4 splits,
the two reviews' value-use probes now give `StructuralRequirementCalled` at
check, and their union probes `InterfaceRequireImplsNotImplemented`; every
check-clean probe of round 2's and round 3's reviews and of this round (60
programs) compiles, and the three that abort at sem_ir/generic.cpp:84 (round
2's p40, p41, p43) abort so on trunk 0bdce60a5 too.

W-151: the commit-3 residue first filed as W-144 was renumbered to W-151 by
2f4ebbf6e, because SAFE-1 (PR 53) allocated W-144..W-150; trunk's id
reservations (9d3ca60a3) give SC-1 nothing above W-151, so the MINOR-3 residue
waited for an id; the orchestrator reserved W-168 for it, filed at fill round 4.

Round 4's own diff (aa67ea281, ff490bd48, d232d4753, 77838fdd5) had two
implementation reviews: review 1, REJECT, 2 BLOCKER, 2 MAJOR and 1 MINOR
(BLOCKER-1, BLOCKER-2, MAJOR-1, MAJOR-2, MINOR-1), and review 2, REJECT, 1
BLOCKER, 1 MAJOR and 2 MINOR (BLOCKER-1, MAJOR-1, MINOR-1, MINOR-2), 9
findings, with review 1 BLOCKER-2 and review 2 BLOCKER-1 the same defect
(`typeof`) and the two MAJOR-1s the same R17 judgement. Both confirmed round
4's union drain and its value refusals on the 0.0.0-0.dev+ff490bd48 driver, its
gate (1959 passed, 0 failed) and its conformance (130 / 0 / 21 over 151)
privately. On the round's question, whether the branch was dry and round 4's
chokepoint the root cause, both answered no (R17): the `typeof` and
instantiation aborts, and an accepted instantiated discard; no rejected valid
program and no waiting-list defect. Fill round 5 folds all 9, below.

Fill round 5 (2026-10-13), by review finding, each reproduced first on the
toolchain stamped 0.0.0-0.dev+ff490bd48 with the reviews' probes:

-   BLOCKER-1 (review 1): a template instantiated with a facet type checked
    clean and aborted lowering: `Take((T.N, 1))` in `fn F(template T: type)`
    called as `F(HasN)` (lower/type.cpp:459), and the struct, nested, method,
    template-class-member and deduced shapes, with `let` and `if` forms at
    lower/function_context.cpp:223. The call action converts the instantiation's
    constant `tuple_value`, which round 4's literal walk did not visit. Fixed by
    D-SC-20 as amended: the requirement's type is concrete, the refusal asks
    whether the value's type is or holds a requirement's type
    (`GetStructuralRequirementOfType`: the type itself, or a tuple or struct
    element), and the template's convert actions replay it (convert.cpp
    `PerformAction` for `ConvertAction`, `ConvertToValueAction`,
    `ConvertToCategoryAction` and `InitializeAction`). Pinned by
    requirement-call `fail_requirement_through_template_instantiation` and,
    instantiated with a class, lower
    `requirement_through_template_instantiation`.
-   BLOCKER-2 (review 1) and BLOCKER-1 (review 2): `typeof(HasN.N)` handed out
    the `.Self`-symbolic function type without converting anything: `fn H(unused
    f: typeof(HasN.N)) {}` aborted lowering at lower/type.cpp:459, other shapes
    at lower/file_context.h:187 and lower/function_context.cpp:223, `Take(f)`
    on such a parameter passed the check, and `impl typeof(HasN.N) as Z` linked
    to an undefined symbol. Fixed at the root: `typeof(HasN.N)` is the concrete
    `StructuralRequirementType`, usable as a type (the impl now prints 9
    through `typeof(HasN.N).(Z.F)()`), and a value of it (a parameter, a field
    read, a return) is refused. Pinned by requirement-call
    `fail_requirement_typeof_value`, compound `requirement_typeof` and lower
    `requirement_typeof` (with upstream's `typeof(I.F)` twin and
    `typeof(C.(HasN.N))`). The reviews' minimal alternative, refusing `typeof`
    itself, is not taken: once concrete the type is harmless, as upstream's
    `typeof(I.F)` is, and a refusal at definition would not see a template's
    `typeof(T.N)`, which evaluates at instantiation, the split MAJOR-2 objects
    to.
-   MAJOR-1 (both reviews, R17): round 4's check was a broader use-site guard,
    not the root cause. Agreed, and the design alternative both name is taken:
    a requirement named with no self type is a value of its own concrete type
    (D-SC-20 replaced), the `.Self` lookup and generic.cpp's early return are
    deleted (name_lookup.cpp's `.Self` hunks reverted, its SC-1b `diagnose`
    parameter kept; generic.cpp as on the base 8068151ed; restated at fill
    round 6, round 5's review 2 finding MINOR-3), and the eval.cpp:151
    failure they existed for does not recur (compound `checked_generic_name`
    and `assoc_fn_compound`). The refusal in `Convert` stays as D-SC-20's rule
    (values of a requirement's type are refused, as overload sets are), not as
    a crash guard: deleting it would make `Take(HasN.N)` compile, as upstream's
    `H(I.F)` does, which round 4 decided against and its goldens pin (R16(b)).
    The records that called round 4's check the root cause are amended (the
    convert.cpp comment, D-SC-20, round 4's BLOCKER-1 bullet and decision
    above, the decision log, the design page, ORCHESTRATION). W-169 stays
    unused: nothing is deferred.
-   MAJOR-2 (review 1): a discarded `T.N;`, `(T.N, 1);` or `{.a = T.N};`
    instantiated with `HasN` compiled and ran; the replayed category
    conversion now refuses all three, as `HasN.N;` is refused. Pinned by the
    instantiation split's `Discard`, `DiscardTuple` and `DiscardStruct`.
-   MINOR-1 (review 1): a value that deduction built has no location, so the
    error now takes the conversion's (requirement-call `TemplateValueParam`
    and `GenericValueParam`, at the call). At instantiation a constant
    argument has no location and neither has its conversion, as for upstream's
    own conversion notes on such an argument (trunk 0bdce60a5, `TakeI((T.N,
    1))` instantiated with a class); those notes stay unlocated, pinned so.
-   MINOR-1 (review 2): the kind is renamed `StructuralRequirementUsed`
    (kind.def, the one `CARBON_DIAGNOSTIC`, the goldens by autoupdate, D-SC-9,
    the design page).
-   MINOR-2 (review 2): `BoundInStruct` (`Take({.a = x.Get})`) and an
    overload-set use (`P(HasN.N)` against `overload fn P(unused x: i32)` and
    `overload fn P[T: type](unused f: T)`, whose candidates convert with
    diagnostics off) are pinned; the latter reports only `OverloadNoMatch`
    with its two candidate notes.

Rejected or narrowed: none of the 9; the two `typeof` findings are fixed by the
root fix their reviews prefer, not by their minimal alternative.

Round 5's decision as an R29(a) implementation decision, with design citation
and break condition:

-   **A requirement named with no self type has its own concrete type**
    (sem_ir/typed_insts.h:2235 `StructuralRequirementType`;
    structural_conformance.cpp:696 `MakeStructuralRequirementName`, :746
    `GetStructuralRequirementOfType` and :821
    `CheckValueIsNotStructuralRequirement`; convert.cpp:2688 in `Convert` and
    :2495, :2515, :2531 and :2575 in the four template `PerformAction`s,
    re-cited at the round-7 head, where `Convert` and the first two call round
    6's `CheckConversionIsNotOfStructuralRequirement`;
    call.cpp:772-775 in `PerformCallToNonFunction`; member_access.cpp:400 (the
    lookup) and :949 (the compound redirect); the type's lowering
    (lower/type.cpp:879), completion, destruction, import, printing and naming
    beside `OverloadSetType`'s). Design: D-SC-20 as amended, D-SC-4, D-SC-9.
    Break condition: D-SC-20's. Found while probing it and fixed by it: through
    a generic constraint in a checked generic, `typeof(Has(T).N)` aborted
    lowering on round 4's build too (there `.Self` depends on `T`, so
    generic.cpp's early return did not apply and the specific kept `.Self`). Not
    SC-1's, reproduced on trunk 0bdce60a5 with a class: `Take(((C.N, 1), 2))`
    fails the module verifier (lower/lower.cpp:48), an `if` expression of a
    tuple holding a function value aborts in `BranchWithArg`, and `typeof` of a
    bound method is type_iterator.cpp's `BoundMethodType` FATAL.

Round 5's fill predictions, checked against the fill (18775fee3): every round-5
row of §4.B held except misses (n), a frozen `.Self` of `type` in the compound
range, and (o), one `Take` definition shared by three tuple shapes, the lower
phase's specific coalescing that trunk 0bdce60a5 shows for the same non-template
calls (amended 2026-10-14, round 5's review 2 finding MAJOR-2: first recorded as
a mangling property, which it is not); each row says so, dated. None of these
"held" clauses is counted as a prediction (amended 2026-10-14, round 5's review
2 finding MINOR-1, R16(d)): the development build ran the reviews' shapes before
the rows were written, so the rows record observations, each marked NOT COUNTED,
and misses (n) and (o) stand as errors in them. Pinned by the round-5 splits,
the reviews' `typeof` and instantiation probes now give
`StructuralRequirementUsed` at check or compile and run (a type use), and their
union and value probes keep round 4's results; every check-clean probe of round
2's, round 3's and round 4's reviews and of this round compiles, except the
trunk aborts listed under round 5's decision and round 2's p40, p41 and p43 at
sem_ir/generic.cpp:84.

Round 5's own diff (616d0bc4f, 18775fee3, df5120d03, a9c887101) had two
implementation reviews, both APPROVE-WITH-FIXES with no BLOCKER: review 1, 1
MAJOR and 2 MINOR (MAJOR-1, MINOR-1, MINOR-2), and review 2, 2 MAJOR and 6
MINOR (MAJOR-1, MAJOR-2, MINOR-1 to MINOR-6), 11 findings, with the two MAJOR-1s
the same defect and the two MINOR-2s the same coverage gap. Both confirmed round
5 on the 0.0.0-0.dev+18775fee3 driver, its gate (1959 passed, 0 failed) and its
conformance (130 / 0 / 21 over 151) privately, and re-ran the 553 probe runs of
rounds 2 to 5 with unchanged outcomes. On the round's question, whether the
branch was dry with the representation concrete and the concrete type a sound
SemIR citizen, both found no check-clean input that crashes or miscompiles
because of SC-1 and no accepted invalid program; the type held for completeness,
value representation, lowering, mangling, import and export across libraries,
equality and specifics; the one rejected valid class was the destruction of a
type that holds it (MAJOR-1). The other aborts their probes found reproduce on
trunk 0bdce60a5: lower/handle_call.cpp:984 for a nested aggregate holding a
function value, sem_ir/generic.cpp:84 for a template-local alias of a dependent
name, import_ref.cpp:5172 (`SpliceInst`) for an imported template whose body
depends on `T`, and custom_witness.cpp:487 for a class field of an overload
set's or an associated entity's type. Fill round 6 folds all 11, below.

Fill round 6 (2026-10-14), by review finding, each reproduced first on the
toolchain stamped 0.0.0-0.dev+18775fee3 with the reviews' probes:

-   MAJOR-1 (both reviews): a class, generic-class specific, tuple, struct or
    array with a field of `typeof(HasN.N)` could not be destroyed, so every
    local, temporary or `Core.Destroy` query of it (`var w: W;`, `MakeW().x`, a
    discarded `MakeW()`, `D(p)` for `D[T: Core.Destroy](p: T*)`,
    `Box(typeof(HasN.N))`) was refused with 3 to 19 copies of
    `StructuralRequirementUsed` at a site that names no requirement. Root
    cause: the refusal in `Convert` applied whatever the target, and the
    synthesized `Destroy.Op` binds each such element as its own `ref self` (a
    `NoOp` conversion of the generated function's reference parameter in
    `CalleePatternMatch`, then `ValueOrRef` and `UnmarkedRefParam` conversions
    of the element in `MakeSubobjectDestroyOpBody`), none of which reads a
    value. Fixed at that rule rather than in the destroy synthesis: a reference
    that stays a reference (a `NoOp`, `ValueOrRef`, `DurableRef`, `RefParam`,
    `UnmarkedRefParam` or `Discarded` target of a reference expression, a `ref`
    tag looked through) is not refused (convert.cpp:2464
    `CheckConversionIsNotOfStructuralRequirement`, called by `Convert` at :2688
    and by the `ConvertAction` and `ConvertToCategoryAction` replays at :2495
    and :2515); a value or an initializer stays refused. The reviews' first
    mechanism, skipping the destroy call for a requirement-typed element, would
    still refuse a struct- or tuple-typed field that holds the type (review 1's
    e10) and would skip a non-trivial element beside it; their second,
    exempting synthesized `SelfDestruct` calls, would leave a user's `ref`
    binding of the same object refused for no reason D-SC-20 gives. Every
    destroy probe of both reviews now checks and runs, and the trunk-analog
    controls are unchanged. Pinned by lower `requirement_typeof_object` and
    requirement-call `fail_requirement_typeof_value`'s `ReadField`.
-   MINOR-1 (review 1): D-SC-20's "never a runtime value" overclaimed: a value
    typed by a type parameter bound to the requirement's type passes in a
    template and in a checked generic. Taken as its first fix: D-SC-20 is
    narrowed to what is enforced (amended above), and the accepted shapes are
    pinned in lower `requirement_typeof_object` (`Pass`, a checked generic's
    `Take(*p)`; `LetValue`, a template's `let v: T = *p`). With the reference
    rule a discarded `*p;` is accepted outside a template too (review 1's k26),
    as k25 found it inside one. The second fix, recording an action for every
    template-dependent value conversion, is not taken: it would add actions to
    every template body upstream's goldens dump and cannot reach checked
    generics.
-   MINOR-2 (both reviews): the import of `StructuralRequirementType`
    (import_ref.cpp:3029-3051 and :5111-5113) had no golden. Import
    `requirement_type_a`, `requirement_type_b` (dumped) and
    `fail_requirement_type_value` pin an exported alias, function, impl and
    type, the importer's value refusal and its printed type (`<type of
    Has(i32).N>*`). The stringifier's unreached fallback (review 2) is a
    `CARBON_CHECK` now (sem_ir/stringify.cpp:934): the type is only formed for a
    requirement (`MakeStructuralRequirementName`, or its import), whose parent
    scope is a template constraint's with-self scope.
-   MAJOR-2 (review 2): miss (o)'s cause was recorded as a trunk mangling that
    does not distinguish the tuple types. It is the lower phase's specific
    coalescer (lower/specific_coalescer.cpp), which merges the three
    equivalent specifics: `carbon -v compile` logs "Found equivalent
    specifics", and a `Take` whose body depends on `T` keeps three symbols
    (`_CTake.Main.18d60a26b9cae11d`, `.0263d9da23f6f4db`, `.4273d82e53b409ec`)
    and returns 111, on this build and on trunk 0bdce60a5. Reworded in the §4.B
    row, the misses list, the round-5 note above, the decision log and the PR
    body.
-   MINOR-1 (review 2): the round-5 §4.B rows were written after the development
    build ran the reviews' shapes, yet were counted as held. Each is marked NOT
    COUNTED (R16(d)), as round 3's `UseStructurally` clause was, with misses (n)
    and (o) standing as errors in them; the decision log and the PR body carry
    the disclosure, and round 6's rows say the same of themselves.
-   MINOR-3 (review 2): "name_lookup.cpp and generic.cpp as on trunk" is
    restated in D-SC-20, the round-5 MAJOR-1 bullet, the decision log and
    W-027's evidence: the `.Self` hunks are reverted and the with-self path is
    trunk's, while name_lookup.cpp keeps SC-1b's `diagnose` parameter;
    generic.cpp is as on the base 8068151ed.
-   MINOR-4 (review 2): D-SC-10's amendment and the round-1 mechanisms paragraph
    say that the `.Self` lookup is superseded since fill round 5, and that the
    two splits that pinned it pin the concrete type.
-   MINOR-5 (review 2): the convert.cpp comment names "the `PerformAction`
    overloads above".
-   MINOR-6 (review 2): df5120d03's whitespace-only rewrap of ORCHESTRATION's
    UA-1 "Last updated" sentences is undone, their line breaks as before it;
    SC-1's records edits there keep to SC-1's own sentences and Branches row.

Rejected or narrowed: none of the 11. MAJOR-1 is fixed at the refusal's rule
rather than by either mechanism its reviews suggest, for the reasons in its
bullet; review 1's MINOR-1 is taken as its first fix.

Round 6's decision as an R29(a) implementation decision, with design citation
and break condition:

-   **A reference kept a reference is not a requirement's value**
    (convert.cpp:2464 `CheckConversionIsNotOfStructuralRequirement`; :2688 in
    `Convert`, :2495 and :2515 in the `ConvertAction` and
    `ConvertToCategoryAction` replays). Design:
    D-SC-20 as amended at fill round 6: the type is usable as a field and a
    pointee, so objects of it exist, and binding or discarding a reference to
    one reads no value, as taking its address does not. Break condition:
    D-SC-20's, or upstream makes a conversion to a reference category read the
    object; then that target leaves the exemption and is refused as a value is.
    Observed with it, not SC-1's: a template's `F(ref *p)` is refused at
    instantiation when `*p` has the requirement's type (the replayed argument is
    a `SpecificInst` of the `ref` tag, which the rule does not look through),
    while trunk 0bdce60a5 aborts on every such template call (inst.h:249,
    "Casting ... to wrong kind RefTagExpr", with `i32`).

Round 6's §4.B rows were written after the development build ran their shapes
(R16(d)): they record observations and are not counted as predictions. With the
round-6 build, the 553 probe runs of rounds 2 to 5 classify exactly as on
18775fee3 (398 check errors, 131 compile and run, 5 with no `Run` to link, 19
aborts, all trunk's); the reviews' own 412 runs give 249 check errors, 135
compile and run, 16 with no `Run`, and 12 aborts, each reproduced on trunk
0bdce60a5 (handle_call.cpp:984; sem_ir/generic.cpp:84 for a template-local
alias; lower/lower.cpp:48 for a nested tuple of a function value;
custom_witness.cpp:487 for a field of an overload set's or associated entity's
type); against the reviews' recorded outcomes the only changes are the
destroy probes, from refused to running (review 1's d11 now reaching upstream's
"conversion of runtime facet value" TODO, as its trunk analog does), and review
1's m14, a `ref self` method called through `(*p)`, from refused to running.

Round 6's own diff (56e400145, fb12f63cb, 857d5b048, 4bc4802ae) had two
implementation reviews, 7 findings in all: review 1, REJECT, 1 BLOCKER, 1 MAJOR
and 1 MINOR (BLOCKER-1, MAJOR-1, MINOR-1); review 2, APPROVE-WITH-FIXES, 1 MAJOR
and 3 MINOR (MAJOR-1, MINOR-1 to MINOR-3). Both confirmed round 6 privately on
the driver stamped 0.0.0-0.dev+fb12f63cb, its gate (1959 passed, 0 failed) and
conformance (130 / 0 / 21 over 151) and the 1007 earlier probe runs line for
line, their 31 aborts trunk's. On the round's question, both found that the
reference exemption lets no requirement value reach lowering or escape (a `ref`
binding read as a value elsewhere, a dereferenced pointer, `ref self` methods in
place of the retired `addr self`, a `ref` parameter passed on, a returned
reference, nested destructors, generic-class specifics and arrays, every value
read refused; the enclosing objects are not copyable), that the stringifier's
`CARBON_CHECK` is not reachable from user input (imports of every shape,
constraints nested in generic classes, interfaces and namespaces, mismatched
redeclarations, and in review 1 456 dump runs), and both found the records
accurate but for the overclaims below. The branch was not dry: the BLOCKER,
which predates round 6 (D-SC-10's template-phase `Self`, since SC-1a), checked
clean and aborted lowering; review 1's MAJOR-1 accepted invalid values; review
2's MAJOR-1 refused valid reads. On fb12f63cb review 1's probes
(sc1-review6/adv1) abort on names of a template constraint's body and on four
trunk shapes (r02 at inst.h:249, q03 and q05 at LLVM's PHI assertion, k29 a
segmentation fault at run time), and review 2's (sc1-review6/adv2) once, q41, as
its trunk analog t41 does.

Fill round 7 (2026-10-14), by review finding, each reproduced first on the
toolchain stamped 0.0.0-0.dev+fb12f63cb with the reviews' probes:

-   BLOCKER-1 (review 1): a name of a template constraint's body that depends on
    its `Self`, other than a requirement (an alias of `Self`, a class,
    interface or constraint declared in the body, a template constraint nested
    in it and its requirements), was template-dependent where non-template code
    named it with no self type, through D-SC-10's template-phase `Self`.
    `Convert`, calls and member access then recorded actions that a
    non-generic function never performs, so type errors (`let y: HasN.A* = 1`,
    `1 as Outer.Inner`) and D-SC-20's refusal (`Outer.Inner.N;`,
    `Take(Outer.Inner.N)`) were skipped, check passed, and lowering aborted on
    an unexpanded `SpliceInst` (function_context.cpp:223, handle.cpp:405) or
    the program ran. Fixed by the reviewer's preferred option, D-SC-10's own
    break condition: `Self` is a checked-phase binding in a template
    constraint (handle_named_constraint.cpp:126-133 passes `false`, as the base
    8068151ed did), so those names are symbolic as a `constraint`'s are and
    are checked where they are used; D-SC-10 is amended and the template phase
    filed as an SC-B2 prerequisite (W-028's notes). Pinned by declaration
    `fail_self_dependent_name` (u01, v02, v10) and `nested_class` (v01), and
    requirement-call `fail_nested_requirement_as_value` (y01, y06, y07, y10).
    The probes that still abort reproduce on trunk 0bdce60a5 with an
    `interface` or `constraint` spelling, at the same site: v01 at
    sem_ir/mangler.cpp:185 (a `constraint`'s nested class); `var p:
    typeof(Outer.Inner.N)*`, `HasN.A*`, a field of such a type and a nested
    class local at lower/file_context.h:187; a nested constraint as a
    binding's type at check/eval.cpp:151, an impl of its requirement's type at
    check/generic.cpp:477; and the template-function forms (v08, u08) at
    eval.cpp:151 after their error. A requirement whose signature names
    another through `Self` is now upstream's "member access into facet of
    incomplete type", as `Self.N` in an interface being defined is on trunk.
    (Amended 2026-10-14, fill round 8, round 7's review 1 finding MAJOR-1 and
    review 2 findings MAJOR-1 and MAJOR-2: this bullet said that one shape
    moved and that with the template phase it was accepted and could never be
    satisfied. It was satisfiable, and a wider class moved both ways: D-SC-10
    as restated at fill round 8.)
-   MAJOR-1 (review 1): `const typeof(HasN.N)` and `array(typeof(HasN.N), 2)`
    were not looked into, so values of them were accepted (a by-value
    parameter, `Take(*p)` through a `const` pointer, `let` and `Take` of an
    array field), and an `if` over them reached LLVM's PHI assertion. Fixed as
    asked: `GetStructuralRequirementOfType` follows a `ConstType`'s inner type
    and an `ArrayType`'s element type (structural_conformance.cpp:779-788,
    :810-819 at the round-9 head),
    and the header's array sentence is replaced (structural_conformance.h:
    95-100). Pinned by `ConstParam`, `ConstPointer`, `ArrayLet` and
    `ArrayArg` in requirement-call `fail_requirement_typeof_value`. A class,
    adapter or `MaybeUnformed` value stays accepted (D-SC-20 as amended at
    fill round 7 says why).
-   MAJOR-1 (review 2): `self.t.1` in a value method and `w.s.x` through a
    class value were refused at a site that reads only an `i32`. Taken as the
    reviewer's second option, with evidence against the first: member access
    on a class value acquires the field as a value (member_access.cpp:614-624,
    `ConvertToValueExpr` of the element access, which for a tuple field builds
    `tuple_value` from an `acquire_value` of each element, the
    requirement-typed one included), so a value of a type holding the
    requirement's type is formed there, and the first option's premise, that
    the projection "forms no new value", does not hold. D-SC-20, the design
    page and the test comments now say that such a field is reached through a
    reference to the object (a `ref self` method), and why a class value is
    accepted; pinned by `Get`, `GetRef` and `StructField` in
    `fail_requirement_typeof_value`.
-   MINOR-1 (review 1) and MINOR-1 (review 2): the convert.cpp comments
    (:2454-2463, :2682-2687) and structural_conformance.h:104-110 no longer say
    "never a runtime value"; the helper's comment names the storage of a `var`
    pattern or parameter; D-SC-20's template sentence says a template accepts
    such a value only where its conversion records no action (a `let` of the
    parameter's type), while a call argument or a `var` initializer is
    replayed and refused (`TemplateDeref`, review 1's h22); the design page
    says the same and that a `var` parameter of the type is declared and
    uncallable (`VarParam`, `CallVarParam`, review 2's q14 and q15).
-   MINOR-2 (review 2): the PR body's trunk advance is restated (seven
    records-only commits ending at f67ab650d, `git merge-tree` re-run against
    it), PRs 51 to 56 are listed as held open, and SC-1's position in trunk's
    merge order is quoted. The body is outside the repository.
-   MINOR-3 (review 2): `PerformTupleAccess` returns `ErrorInst` without a
    second diagnostic when its base's conversion failed
    (member_access.cpp:1178-1183), as member access already does; trunk's own
    `undefined.1` cascade goes with it (no golden pins it). Pinned by
    `TupleIndex` in `fail_requirement_as_value` and by the single errors of
    `Get` and `StructField`.

Rejected or narrowed: none of the 7. Review 2's MAJOR-1 is taken as its second
option, on the evidence in its bullet; review 1's BLOCKER-1 as its first.

Round 7's decisions as R29(a) implementation decisions, each with design
citation and break condition (the second and third recorded as decisions by the
records commit after 30716a8c2; c0fa52df2 recorded them as dispositions):

-   **`Self` in a template constraint is a checked-phase binding**
    (handle_named_constraint.cpp:126-133). Design: D-SC-10 as amended at fill
    round 7 (its own break condition, met by a different falsifier than the one
    it named); the definition-time checking section of
    docs/design/generics/template_constraints.md states the as-landed limit.
    Break condition: SC-B2 (W-028) lands validity blocks, which need the
    template phase; the flip comes back with them, and round 6's review-1
    BLOCKER-1 probes are re-run first, each to be diagnosed or to abort only
    where its `interface` or `constraint` analog aborts on trunk. Kept at fill
    round 8 as a trade, re-weighed on round 7's reviews' facts (round 8's
    decision below); the flip back must also keep the require golden's
    `require_self_argument` splits as they are.
-   **`const` and array types hold a requirement's type**
    (structural_conformance.cpp:779-788, :810-819 at the round-9 head,
    structural_conformance.h:95-100; review
    1 MAJOR-1 and review 2 MAJOR-1). Design: D-SC-20 as amended at fill round 7:
    a type holds a requirement's type when its values are built element by
    element (a tuple, struct or array element, or the type under `const`); a
    class, adapter or `MaybeUnformed` value is accepted, and a field read
    through it, which member access acquires as a value
    (member_access.cpp:614-624), is refused when the field is or holds the type,
    so such a field is reached through a reference. Break condition: D-SC-20's;
    or upstream stops acquiring a class value's field as a value, so that the
    read stays a reference, which round 6's rule admits; then `Get` and
    `StructField` are respelled as positive splits.
-   **A refused tuple-index base is diagnosed once**
    (member_access.cpp:1190-1195 at the round-8 head; review 2 MINOR-3).
    Design: D-SC-20 (one
    refusal per use) and upstream's propagation of an error without a second
    diagnostic, as its member access does for an error-typed base
    (member_access.cpp:839); trunk's own follow-on for an undefined base goes
    with it (`undefined.1`: two errors on trunk 0bdce60a5, one here, no golden
    pinning it). Break condition: upstream guards `PerformTupleAccess` against
    an error base itself; then the fork hunk is deleted.

Round 7's §4 rows were written after the development build ran their shapes
(R16(d)): they record observations and are not counted as predictions. With
the round-7 build, the 553 probe runs of rounds 2 to 4 give 399 check errors,
130 compile and run, 5 with no `Run` and 19 aborts (round 4's v18b, a by-value
`array(typeof(HasN.N), 0)` parameter, refused by the array rule); the round-5
reviews' 412 give 253, 132, 15 and 12 (r05, s08, n22 and m33, a requirement
naming another through `Self.N`, rejected at the declaration as above); round
6's 42 give 24 and 18 as before; and the 19 + 12 aborts are the trunk classes
recorded above. Round 6's reviews' probes: review 1's 271 (p, p2 to p15) give
184 check errors, 70 compile and run and 17 aborts (38 on fb12f63cb), each with
a trunk-spelled analog aborting at the same site on 0bdce60a5 (the BLOCKER-1
bullet; r02 at inst.h:249 as r01t), and its 44 trunk analogs run as before;
review 2's 76 give 57, 18 and 1 (q41, as its trunk analog t41), its 5 analogs as
before; the 14 import sets of rounds 5 and 6 give the same results as on
fb12f63cb, their two aborts trunk's import_ref.cpp:5172. Round 7's own 14
probes (sc1-fix7/p7: `const` pointers discarded, array elements through a
reference and through a value, a checked generic's array parameter, a class
value's other field, `MaybeUnformed`, an alias of `Self` in a template, the
satisfaction, redeclaration and generic-constraint paths) behave as D-SC-20 and
D-SC-10 as amended say; the one abort (c07, an error then inst.h:249) is
trunk's with an `interface` (c07t).

Round 7's own diff (c0fa52df2, 36181a729, 30716a8c2, fa4cd094d) had two
implementation reviews, 9 findings in all: review 1, APPROVE-WITH-FIXES, 1 MAJOR
and 2 MINOR (MAJOR-1, MINOR-1, MINOR-2); review 2, APPROVE-WITH-FIXES, 2 MAJOR
and 4 MINOR (MAJOR-1, MAJOR-2, MINOR-1 to MINOR-4). Both confirmed round 7
privately on the driver stamped 0.0.0-0.dev+36181a729, its gate (1959 passed, 0
failed) and conformance (130 / 0 / 21 over 151, 49 of 56), and every earlier
probe run line for line. On the round's question (whether the branch is dry with
`Self` checked-phase), both found every SC-1 feature working (template bodies
naming requirements, compound access, the redirect for concrete selves,
generic-class members, imports, the two conformance programs), no program that
checks clean and then aborts or miscompiles because of SC-1 (each abort found
pairs with an `interface` or `constraint` analog aborting at the same site on
trunk 0bdce60a5: lower/file_context.h:187, sem_ir/mangler.cpp:185,
check/eval.cpp:151, check/generic.cpp:477, sem_ir/inst.h:249, import_ref.cpp at
a `SpliceInst` and at :1086, lower/function_context.cpp:223, LLVM's PHI
assertion), and the `const`, array and field rules complete for every shape
asked (a pointer to an array, arrays of tuples or structs, `const` struct
fields, nested `const`, arrays of arrays). The records were wrong about the
flip: it rejects a wider class of requirement signatures than D-SC-10 said,
valid programs that ran on fb12f63cb among them (review 1 MAJOR-1; review 2
MAJOR-1, whose probes show the `Self.N` shape satisfiable there), and it accepts
a `require` whose facet type takes `Self` as an argument, rejected since SC-1a
(review 2 MAJOR-2). The rejection is not F-010's rule: the design page's
definition-time checking defers a requirement's checks that involve `Self` to
satisfaction, as p002200:714-732 leaves template-dependent expressions unchecked
until instantiation, so these signatures are valid under F-010; their loss is a
limit of SC-1, accepted and recorded as one (D-SC-10 as restated, the page's
as-landed note, the `fail_todo_` splits below, W-169), which SC-B2's template
phase (W-028) is to lift. Review 1's probes are sc1-review7/adv1 (p, p2 to p9,
tr to tr6, imp: 250 probes, 48 trunk analogs, 9 import sets and trunk analogs of
3 of them), review 2's sc1-review7/adv2 (p, p2 to p12, tr to tr6, imp7: 175
probes, 28 trunk analogs, 6 import sets).

Fill round 8 (2026-10-14), by review finding, each reproduced first on the
toolchain stamped 0.0.0-0.dev+36181a729 with the reviews' probes, and on the
toolchain of fb12f63cb for the round-6 behavior:

-   MAJOR-1 (review 1) and MAJOR-1 (review 2): with a checked-phase `Self` a
    requirement's signature is checked at the definition as an interface
    member's is, so every member access into `Self` (`typeof(Self.N)*`,
    `Self.A`, `Self.K`, `Self.Me`; review 2's q01 to q06, q08, q09, m01 to
    m04 and m06) is
    `IncompleteTypeInMemberAccessOfFacet`, and every use of `Self` that must
    satisfy a facet type the constraint does not require (`Box(Self)` for
    `class Box(T: J)`, `Self.(J.Elem)`, `Core.Slice(Self)`,
    `Core.Optional(Self)`; review 1's f11, f12, f14, f18, f20 and f22) is
    `ConversionFailureFacetToFacet`. On fb12f63cb q01, q04 to q06, f14, f18
    and f22 checked and ran, and f11 and f12 checked. Not reverted: review
    2's second option is taken, the decision re-weighed on these facts (round
    8's decision below) and the flip kept. D-SC-10 is restated, round 7's
    BLOCKER-1 bullet and decision above amended, the decision log's ROUND 7's
    first decision amended and ROUND 8's DECISION added; the design page's
    as-landed note gives the rule, the examples, the `require impls J`
    workaround and its exception (a required template constraint, D-SC-6);
    W-169 files the lost shapes, and W-028's notes name them as what SC-B2's
    template phase restores. Pinned by declaration
    `fail_todo_self_member_in_signature` (`typeof(Self.N)*` and `Self.A`: the
    error with `NamedConstraintIncompleteWithinDefinition`, as trunk's
    `fail_todo_self_period_associated_type`),
    `fail_todo_self_facet_in_signature` (f14's and f18's declarations) and
    `self_facet_in_signature_required` (f15's and f17's programs). The PR body
    is restated (outside the repository).
-   MAJOR-2 (review 2): the flip accepts a `require` whose facet type takes
    `Self` as an argument (s02, s04, r01 and t01 run; r04 and t02 are
    diagnosed), rejected since SC-1a as "constrained by a non-facet type".
    Recorded in D-SC-10, the decision log's ROUND 7's first decision and ROUND
    8's DECISION, the design page's as-landed note and W-028's notes, whose
    re-flip is now conditional on these splits. Pinned by require
    `require_self_argument` and `fail_require_self_argument_unsatisfied`, and
    lower `require_self_argument`, whose specifics call `C.Do` and `C.Get`.
-   MINOR-1 (review 1) and MINOR-1 (review 2): a requirement named
    unqualified in another's signature (`fn M(p: typeof(N)*)`) is accepted and
    never satisfiable (review 1's e05, e20, e25, e26 and e44; review 2's a02,
    a02b and q07), on fb12f63cb as now. Taken as both reviewers' recording
    option: D-SC-10 and the design page's as-landed note state it, W-169 files
    it, and declaration `fail_todo_unqualified_requirement_in_signature` pins
    e44's shape. A diagnosis at the declaration is declined: it would be one
    more partial walk over a signature's types (R17), while the fix, matching
    a requirement's own function type for a concrete self against the
    member's, is W-169's.
-   MINOR-2 (review 1) and MINOR-2 (review 2): the compound-access TODO said
    "runtime facet value" for a concrete type whose facet is symbolic through
    the constraint's arguments (l02 to l04) or through the `Self` of an
    enclosing constraint or interface (g11, e01; round 6's z05, z16, y04,
    y09). The TODO now says "through a symbolic
    facet" for a constant facet that is not concrete and keeps its text for a
    runtime one, and its comment names both (member_access.cpp:1013-1036);
    D-SC-20 and the design page's name-lookup paragraph record the limit,
    with `(C as Has(T)).N` keeping the requirement and the method form
    redirected; requirement-call `fail_todo_symbolic_facet` pins l02, e01 and
    the method forms (n01). The header's adapter wording is corrected
    (structural_conformance.h:98-100: a class with such a field, an adapter of
    such a type and `MaybeUnformed` of it).
-   MINOR-3 (review 2): D-SC-20's "Named, it is never a runtime value" and the
    requirement-call comment of `fail_requirement_as_value` are reworded ("a
    value that names or holds it is refused"; "refused as a value").
-   MINOR-4 (review 2): the decision log's head and ROUND 7's first decision
    now say that D-SC-10's break condition was taken on a falsifier other than
    the one it named (R29(a), veto-able); the design page's dependency list
    names the template-phase `Self` as SC-B2's prerequisite (W-028); W-027's
    `Self` cite is :126-133 and :160-162.

Rejected or narrowed: none of the 9. Review 2's MAJOR-1 is taken as its second
option, review 1's MAJOR-1 as asked, and MINOR-1 of both reviews as its
recording option.

Round 8's decision as an R29(a) implementation decision, with design citation
and break condition:

-   **The checked-phase `Self` is kept as a trade**
    (handle_named_constraint.cpp:126-133, unchanged). Re-weighed on round 7's
    reviews' facts: the flip removed the crash class of round 6's BLOCKER-1
    (non-template code recording template actions for names of the body) and
    accepts `require ... impls X(Self)`; it loses the requirement signatures
    that use `Self` beyond what the constraint requires, now diagnosed at the
    definition, with no crash or miscompile, as trunk diagnoses an
    interface's. Round 6's review 1 offered a second option, the template
    phase kept with each name of the body that depends on `Self` refused or
    made a TODO; it keeps those signatures, but it keeps rejecting the
    `require`s (the template-phase `Self` made `Conv(Self)` a splice) and
    leaves each further kind of such name to the crash class of round 6's
    BLOCKER-1; and, as round 8's review 1 found (finding MINOR-2, added at fill
    round 9), it keeps the hard "unable to monomorphize" error that the
    template-phase `Self` gave a type not satisfying such a signature, even in
    an overload probe and with `require impls J` (b01 to b04 on fb12f63cb),
    against D-SC-12, which only SC-B2's probe subsystem can capture. Design:
    D-SC-10 as restated at fill round 8; F-010's definition-time rule stays the
    target, its gap filed as W-169. Break condition: SC-B2's template phase
    (W-028) lands; then the `fail_todo_` splits of the declaration golden become
    positive, and the require golden's `require_self_argument` splits stay as
    they are, or the phase is scoped to the validity blocks' own checks.
    Consequence if taken: SC-B2 makes positive the satisfying classes and uses
    that the `fail_todo_` splits hold since fill round 9, keeps
    `self_facet_in_signature_required`'s overload probe silent for `D` and lower
    `overload_probe_require` returning 0, and keeps round 6's review-1 BLOCKER-1
    shapes diagnosed as declaration `fail_self_dependent_name` and
    `nested_class` and requirement-call `fail_nested_requirement_as_value` pin
    them (W-028's notes; re-pointed at fill round 9 from probe directories
    outside the repository, round 8's review 2 finding MINOR-3).

Round 8's §4 rows were written after the round-7 build ran their shapes in the
reviews' probes and the development build ran the splits (R16(d)): they record
observations and are not counted as predictions. With the round-8 build, every
earlier probe run (the 1007 of rounds 2 to 5 and round 6's 42; round 6's
reviews' 347 and 49 trunk analogs; round 7's 14; the 51 runs of the eleven
further directories round 7's review 1 re-ran; round 7's reviews' own, review
1's 298 runs in sc1-review7/adv1 and review 2's 203 in sc1-review7/adv2) gives
the same result, line for line, as on 36181a729, but for nine runs whose TODO
now says "through a symbolic facet" (round 6's z05, z16, y04 and y09, round 7's
g11, l02 to l04 and e01) and for the addresses that abort traces print (the
stack addresses of the nine runs aborting at sem_ir/mangler.cpp:185, seven of
them in round 7's reviews' sets, and code offsets, which move with every
rebuild; amended by the records commit after a13e70542, which said two); the 29
import sets of rounds 5 to 7 give the same results. Round 8's own 14 probes
(sc1-fix8/p8: the new splits extracted, the method forms and `(C as Has(T)).N`
through a symbolic facet, a signature depending on a constraint argument
rejected for a symbolic one, and a requirement whose signature has an error,
followed at its use by the "does not match" note as before round 7) behave as
the splits record, and lower `require_self_argument` run as a program returns 5,
`CallDo`'s 3 plus `CallGet`'s 2 derived by hand. The follow-on at the uses of a
requirement whose signature has an error (s05: `ConversionFailureTypeToFacet`
with the "does not match" note after the definition's error) was pinned by no
golden and filed under no id; its `interface` analog on trunk 0bdce60a5 reports
the definition's error alone (sc1-records8/t/s05t.carbon), so it is a second
diagnostic after a hard error, with no program accepted and no abort. Fixed at
fill round 9 (round 9's decision below; unsatisfied
`fail_requirement_signature_error`).

Round 8's own diff (4c2ecee22, 3245ec0d2, 253dd4031, a13e70542, ee1f905b0) had
two implementation reviews, 12 findings in all: review 1, APPROVE-WITH-FIXES, 4
MINOR (MINOR-1 to MINOR-4); review 2, APPROVE-WITH-FIXES, 2 MAJOR and 6 MINOR
(MAJOR-1, MAJOR-2, MINOR-1 to MINOR-6). Both confirmed round 8 privately on the
driver stamped 0.0.0-0.dev+3245ec0d2: its only toolchain changes are the TODO
text, chosen by `is_constant()` with the control flow and the `ErrorInst` return
unchanged (member_access.cpp:1013-1036), and a header comment; its golden commit
adds CHECK lines only. Review 1 re-ran the gate (1959 passed, 0 failed),
conformance (130 / 0 / 21 over 151, 49 of 56) and every earlier probe run line
for line (1983 runs and the 29 import sets); review 2's directory holds
file_test over the four goldens round 8 changed (4 passed) and the conformance
runner over the two SC-1 programs (both PASS), and no re-run of the earlier sets
(narrowed by the records commit after 6231d5b42; fill round 9 wrote that both
re-ran them). On the round's question (whether the branch is dry and the trade
honestly recorded and acceptable), both found the records honest in D-SC-10,
ROUND 8's DECISION, the as-landed note, W-028 and W-169, and the trade
acceptable under F-010 with SC-B2 as its lift, and neither found round 6's
review-1 second option strictly better. Review 1's evidence: on fb12f63cb a type
that does not satisfy a `Self`-dependent signature was a hard "unable to
monomorphize" error even in an overload probe and with `require impls J` (b01 to
b04), against D-SC-12; the second option keeps rejecting `require Self impls
Conv(Self)` (a08) and must refuse nested template constraints, losing c01, which
runs now and aborted lowering at lower/handle.cpp:405 on fb12f63cb; most of the
loss has a workaround. Review 2's: the second option's refusal must cover every
kind of name that depends on `Self`, and a kind it misses checks clean and
aborts lowering (n01 on fb12f63cb); the lost signatures fail closed with trunk's
definition errors (d01, d01t); relative to trunk nothing is lost. Both found the
per-use follow-on of a requirement with an error unpinned and unfiled, and gap
row 60 silent on the trade (review 2 also the PR body's lead). Review 1's probes
are sc1-review8/adv1 (p, x: 31 probes, 3 of them `interface` or `constraint`
spellings for trunk), review 2's sc1-review8/adv2 (p: 17 probes, 6 of them such
spellings; splits and lsplits: round 8's nine new or changed splits, extracted).
The round counts 2 MAJOR, both review 2's disclosure findings, and no BLOCKER.
The records commit after 6231d5b42 checked the round's four answers against the
round-9 head: (a) 4c2ecee22's toolchain diff is member_access.cpp:1013-1036's
comment and TODO text and structural_conformance.h:95-100's comment, and nothing
else; (b) the trade is stated in D-SC-10's heading and body (:488-572 above),
the design page's as-landed note and dependency list
(template_constraints.md:608-633 and :927-931), W-028's notes, W-169, gap row 60
(fork/gap-analysis.md:60) and the PR body's lead, the `fail_todo_` splits assert
the current rejection and name W-169 (`fail_todo_symbolic_facet` W-232), and the
two conformance programs are unchanged since 830447980; (c) the trade is kept:
on fb12f63cb b01 and b03 are "unable to monomorphize", a08 is rejected, and c01
and n01 abort lowering at lower/handle.cpp:405, while on the round-9 build b01
is rejected at the definition, b03, a08 and c01 run, and n01 is W-232's TODO;
(d) the follow-on is round 9's decision below, so no id is needed.

Fill round 9 (2026-10-14), by review finding, each reproduced first on the
toolchain stamped 0.0.0-0.dev+3245ec0d2 with the reviews' probes, and on the
toolchain of fb12f63cb for the round-6 behavior:

-   MINOR-3 (review 1) and MINOR-1 (review 2): the per-use follow-on reproduces
    (review 1's d01: two direct uses, two more `ConversionFailureTypeToFacet`
    errors with the "does not match" note; review 2's d01 and d02, d02 also on
    fb12f63cb). Taken as review 1's preferred option, round 9's decision below:
    a member that does not match a requirement whose own declaration has an
    error fails the check with no further diagnostic. The records' reason for
    leaving it, that no id was left reserved, is withdrawn. Pinned by
    unsatisfied `fail_requirement_signature_error` (d01's three uses, two uses
    of a requirement with an erroneous return type, and a type with no member of
    the name, still reported), its expectation derived by hand from the trunk
    interface analog sc1-fix9/t/e01t (the two definition errors and the
    missing-impl error on 0bdce60a5), and by the uses in the declaration
    golden's `fail_todo_` splits. No id is filed for it.
-   MINOR-1 (review 1): taken in part. f22, the evidence cited for
    `Core.Slice(Self)`, declares the constraint and no satisfying type, so that
    cite is replaced. The finding's claim that no class can name `Core.Slice` or
    `Core.Optional` of itself in its own members is rejected on evidence: a
    class that declares `impl as Core.Copy` and `impl as Core.Destroy` before
    such a member checks on trunk 0bdce60a5, on fb12f63cb and on the round-9
    build (sc1-fix9/p z01, z05; the review's x/s1 and x/s5 declare no
    `Core.Destroy` impl), and on fb12f63cb it satisfied `fn All(self) ->
    Core.Slice(Self)` and `fn Next(self) -> Core.Optional(Self)` and ran (z06,
    z08). D-SC-10, the decision log's ROUND 7's first decision and ROUND 8's
    DECISION, W-169's and W-028's notes and the design page's as-landed note now
    say that both were satisfied and ran, citing z06 and z08, and that `require
    impls Core.Copy & Core.Destroy` restores both (z07, z09 run on the round-9
    build); review 2's MINOR-3 below pins them. W-028's list keeps `Self.A`,
    which ran on fb12f63cb for a type with its own `A` (z10) and not for one
    without (review 1's a06).
-   MINOR-2 (review 1): taken. On fb12f63cb b01 to b04 fail with "unable to
    monomorphize", b03 with `require impls J` too; on the round-9 build b03 runs
    and the others are rejected at the definition. Recorded in ROUND 8's
    DECISION (the decision log's and the one above), D-SC-10 and W-028's notes,
    whose re-flip must keep such a probe silent. Pinned by
    `self_facet_in_signature_required` (class `D`, without `J`, and the overload
    set `P`; expected from D-SC-12 and the design page's overload rule: no
    STDERR, `P(c)` selecting the constrained member and `P(d)` the next) and by
    lower `overload_probe_require` (`Run` returns 10 + 20 - 30 = 0, derived by
    hand; it returns 0 on the round-9 build and is "unable to monomorphize" on
    fb12f63cb).
-   MINOR-4 (review 1) and MAJOR-2 (review 2): gap row 60 says "after nine fill
    rounds" and its Remaining list names the W-169 limit, with SC-B2 as its lift
    and the workaround, and W-232; the first cell is unchanged and the
    conformance runner's `--self-test` passes (R7).
-   MAJOR-1 (review 2): the PR body's lead paragraph states the trade, the
    workarounds and W-169 (outside the repository).
-   MINOR-2 (review 2): the compound access to an associated-function
    requirement through a symbolic facet is filed as W-232, the id given to
    SC-1's round 9 in place of W-200, which OP-2's reservation W-196..W-201
    holds (orchestrator task 38); `fail_todo_symbolic_facet`'s comment,
    D-SC-20's limit sentence and the design page's name-lookup paragraph name
    it.
-   MINOR-3 (review 2): the recorded parts of the trade are pinned in the
    repository. `fail_todo_self_facet_in_signature` adds `Core.Slice(Self)` and
    `Core.Optional(Self)`, and each `fail_todo_` split holds the class that
    satisfied it on fb12f63cb with a use (`C` and `S` there, `C` for
    `typeof(Self.N)*`), silent after the definition's errors;
    `self_facet_in_signature_required` adds the `Core.Copy & Core.Destroy`
    workaround with class `S`; `HasA` adds `fn Get2(self) -> A`, the unqualified
    alias accepted. ROUND 8's decision's consequence and W-169's and W-028's
    notes point at these splits rather than at probe directories outside the
    repository. Extracted, the two `fail_todo_` splits check clean on fb12f63cb,
    where the constraints were satisfied.
-   MINOR-4 (review 2): the workaround is reworded in D-SC-10, ROUND 8's
    DECISION, the design page and the PR body: requiring the facet type that
    `Self` must satisfy restores the facet cases (`require impls J`; `require
    impls Core.Copy & Core.Destroy`, which restores `Core.Optional(Self)` as
    well, z09, beyond the finding's "lets it be declared"), and a member access
    into `Self` has no workaround in SC-1.
-   MINOR-5 (review 2): D-SC-10's heading carries its taken break condition, as
    D-SC-6's carries its supersession.
-   MINOR-6 (review 2): the comment at handle_named_constraint.cpp:127-132 cites
    D-SC-10 as restated at fill round 8 and says that a requirement's signature
    is therefore checked at the definition (W-169), in the same six lines, so no
    cite of :126-133 moves; it is rebuilt with round 9's toolchain change.

Rejected or narrowed: review 1's MINOR-1 in part (its "never satisfiable" claim,
above); none of the other 11.

Round 9's decision as an R29(a) implementation decision, with design citation
and break condition:

-   **A mismatch against a requirement with an error is not diagnosed again**
    (structural_conformance.cpp `RequirementSignatureHasError` and its use in
    `CheckRequirements`; round 8's review 1 MINOR-3 and review 2 MINOR-1).
    Symptom: a requirement whose declaration has an error in a parameter or
    return type (`fn F(x: Undefined) -> i32`, and since fill round 7 every W-169
    shape) made each use of a type with a member of that name fail with
    `ConversionFailureTypeToFacet` and a "does not match" note after the
    definition's error, where trunk's interface analog reports the definition's
    error alone. Root cause: `CheckFunctionTypeMatches` fails on an error type
    without a diagnostic, as upstream's redeclaration checks do (function.cpp
    `CheckFunctionReturnTypeMatches`, merge.cpp `EntityHasParamError`), and the
    check reported that failure as a mismatch. Decision: a `Mismatch` against a
    requirement whose declaration has an error type in a parameter or its return
    gives `StructuralCheckResult::Error`, so the conversion fails with no
    further diagnostic in both modes and an overload probe skips the member as
    before; a missing, inaccessible or requirement-only member is still
    reported. (Narrowed at fill round 10, round 9's review 1 MAJOR-1 and review
    2 MAJOR-1: the `Error` was returned at that mismatch, so the missing,
    inaccessible or mismatched member of a later requirement, of another
    template constraint or of an interface went unreported; since round 10's
    first decision only the requirement with the error is skipped, and an
    overload set whose other members all reject reports `OverloadNoMatch`,
    W-233.) Design: D-SC-9 as amended at fill round 9; upstream's suppression
    of follow-on diagnostics after an error type. Break condition: some member
    is found to satisfy a requirement whose declaration has an error, or
    upstream starts diagnosing an impl member against an erroneous interface
    member; then the guard goes and the split's uses report. (Corrected at fill
    round 11, round 10's review 2 MAJOR-1: trunk 0bdce60a5 already diagnoses
    such an impl member wherever it differs from the interface member outside
    the error, sc1-review10/adv2 x1t to y3t, so the second condition reads:
    upstream starts diagnosing a difference in the error alone.) Pinned by
    unsatisfied `fail_requirement_signature_error` and the uses in the
    declaration golden's `fail_todo_` splits. Checked by the records commit
    after 6231d5b42: with `H`'s requirement in error and `C` declaring a
    mismatching `F`, `P(c)` calls the unconstrained member of the overload set,
    as a type that does not satisfy the constraint does (sc1-records9/p o01, its
    `Test` dumped on the round-9 build).

Round 9's new expectations were derived by hand before the fill (the trunk
analog e01t run on 0bdce60a5 for the unsatisfied split; D-SC-12 for the overload
probe; the definition errors alone for the `fail_todo_` uses), and the
development build matched each (R16(d)). Extracted and checked on fb12f63cb, on
36181a729 and on the round-9 build, the member and facet `fail_todo_` splits
give no error and none, 3 and 9 errors, and 2 and 4;
`fail_requirement_signature_error` 7, 7 and 3 errors;
`self_facet_in_signature_required` and `overload_probe_require` "unable to
monomorphize", then no error and no error.

Round 9's own diff (58dc46eb6, a5078358c, 6231d5b42, ae807c7e8) had two
implementation reviews, 11 findings in all: review 1, APPROVE-WITH-FIXES, 1
MAJOR and 4 MINOR (MAJOR-1, MINOR-1 to MINOR-4); review 2, APPROVE-WITH-FIXES,
1 MAJOR and 5 MINOR (MAJOR-1, MINOR-1 to MINOR-5). Both checked round 9 on the
driver stamped 0.0.0-0.dev+a5078358c: no crash and no invalid program accepted
(every `Error` path needs an `ErrorInst` in a requirement's declaration, which
is diagnosed in the same invocation, and any error stops lowering,
toolchain/driver/compile_driver.cpp:635-640); gate 1959 passed and 0 failed;
conformance 130 / 0 / 21 over 151, 49 of 56. Review 1 also re-ran the earlier
probe sets, the 2047 runs of round 9's comparison, and the 29 import sets
(sc1-review9/adv1 rv9_*: 2115 result lines with the import sets' 68, where fill
round 10 wrote 2081 result lines), identical, line for line, to the records
commit's runs (sc1-records9 rec_*) but for hexadecimal addresses, re-classified
the 132 differing files of round 9's 2047-file comparison as recorded, and
re-ran them and 80 identical ones; review 2's directory holds its gate and
conformance runs and its own probes, and no re-run of the earlier sets. On the
round's question, both found the cascade gone and the guard too broad: it
returned at the first mismatch against a requirement with an error, so a missing
or mismatched member of a later requirement, another template constraint or an
interface of the facet type, and the class-end `require`, went unreported, in an
order-dependent way (review 1's a01, a03 to a06, e03 and imp/d1; review 2's a01
to a04, where fill round 10 wrote a01 to a05: review 2's a05 declares the
requirement with the error last and reported `G`), where trunk 0bdce60a5's
interface analogs report each (t01, t03, t04, t13; a01t to a04t) and the round-7
build reported each with the follow-on note, so the records' "a missing member
is still reported" overclaimed. Both found the partial rejection of round 8's
review 1 MINOR-1 right (z01 and z05 check and run on trunk, fb12f63cb and
a5078358c; z06, z08 and z10 ran on fb12f63cb and are rejected now; z07 and z09
run), the new splits pinning what the records say (`require_self_argument` 5,
`overload_probe_require` 0), the PR body naming all 44 commits and stating the
trade, gap row 60 naming W-169 and W-232, W-232 R10-exact, and no model
identifier. Review 1's probes are sc1-review9/adv1 (a: 29 probes; ti: 10 trunk
analogs; imp/d1: an import set of 5 files, with its trunk analog d1t; lsplit:
the two lower splits extracted), review 2's sc1-review9/adv2 (p: 21; t: 10 trunk
analogs; v: 26, valid and invalid signature pairs, v06t and v06r the trunk
spellings; z: 10; imp1: an import set of 2 files), 108 probe files and 2 import
sets in all. The round counts 2 MAJOR, one finding of both reviews, and no
BLOCKER. The records commit after 6247769bb checked the round's four answers
against the round-10 head, as the decision log's round-9 review record states:
(a) round 9's guard removed the follow-on but was not confined to it; round 10's
first decision skips only the requirement that cannot be compared (its test
still too broad, round 10's review MAJOR-1, round 11's decision), the
hidden failures are reported with their trunk analogs' error counts and the
follow-on stays removed; an error nested in a requirement's parameter or return,
in the constraint's argument or in a specific gives the errors at its
declarations and nothing at a use, on the round-9 and round-10 builds alike
(review 1's b01, b03 to b11, g01; review 2's b02 to b05); an overload probe
chooses another accepting member silently (c02) and reports `OverloadNoMatch`
when none accepts (c01, W-233); the 31 import sets give the round-9 results but
for abort code offsets and d1's use_missing_g, which now reports `G`; (b) the
splits give the round-10 counts recorded below, and the lower split's IR selects
`P`'s first member for `C` and its second for `D` and computes 10 * 2 + 20 - 40
= 0; (c) z01 and z05 check and run on trunk 0bdce60a5, fb12f63cb, the round-9
build and the round-10 build; z06, z08 and z10 run on fb12f63cb and are rejected
at the definition on both later builds; z07 and z09 run on the three fork builds
(sc1-records10/z), as the records say; (d) the PR body draft names all 49
commits to 6247769bb in its lead and states the trade there (ae807c7e8 had no
item of its own in its commit list until that records commit added one); gap row
60 lists W-169, W-232, W-233, W-234 and `Core.Optional(Self)`; W-232, W-233 and
W-234 are R10-exact, their evidence cites checked at the head; and no model
identifier appears in the branch's diff from 8068151ed or in the PR body.

Fill round 10 (2026-10-14), by review finding, each reproduced first on the
toolchain stamped 0.0.0-0.dev+a5078358c with the reviews' probes, and their
trunk analogs on 0bdce60a5:

-   MAJOR-1 (both reviews): reproduced (review 1's a01, a03 to a06 and e03 give
    the definition's error alone, a02 reports `G`; review 2's a01 to a04 alike,
    a05 reports `G`). Taken as both reviews direct, round 10's first decision
    below: such a mismatch skips only that requirement, the check gives `Error`
    only when nothing else fails, and `LookupImplWitness` still looks up the
    interfaces after it (review 2's third step). Pinned by the new splits
    `fail_requirement_signature_error_other_member`, `_other_constraint` and
    `_require`, their expectations derived by hand from the trunk analogs; the
    claim is corrected in D-SC-9, round 9's decision here and in the decision
    log, the split's comment, the design page and the PR body.
-   MINOR-2 (review 1) and MINOR-1 (review 2), the member side: reproduced (b02
    and b12; b01). Taken: the error test applies to the found member too, round
    10's first decision; pinned by `fail_member_signature_error`, expected from
    t02, t12 and b01t.
-   MINOR-1 (review 1) and MINOR-1 (review 2), the deductions: reproduced (c01,
    `OverloadNoMatch`; c05, `MissingImplInMemberAccess`). Taken as each
    reviewer's second option: an overload probe and impl selection treat a
    deduction that meets the error as a rejection, which is the fork's overload
    resolution and upstream's impl selection after a member's or a candidate's
    own error on trunk 0bdce60a5 (sc1-fix10/p o01 and o02, an overload member
    with an error in its parameter or in its binding's facet type:
    `OverloadNoMatch`; k01, a blanket impl whose constraint has an error:
    `MissingImplInMemberAccess`), so SC-1 does not special-case it. The claims
    are narrowed (the split's comment, D-SC-9, round 9's decision), the two
    shapes pinned as `fail_todo_requirement_signature_error_overload` and
    `fail_todo_requirement_signature_error_blanket`, and W-233 filed.
-   MINOR-4 (review 1): taken. `overload_probe_require`'s `Run` returns `P(c) *
    2 + P(d) - 40`, 0 for the recorded selection and 10 for the swapped one; it
    returns 0 on the round-10 build.
-   MINOR-2 (review 2): reproduced (v06_tuplepat_good and v06_tuplepat_bad abort
    at merge.cpp:391 on a5078358c; v06t and v06r at merge.cpp:360 on trunk).
    Taken as the preferred option, round 10's second decision below: such a
    requirement is a TODO and is not collected; pinned by
    `fail_todo_tuple_pattern_param` and filed as W-234. v06d and both v06 probes
    now give the TODO alone.
-   MINOR-3 (both reviews): gap row 60's list adds `Core.Optional(Self)`; the
    first cell is unchanged and `runner.py --self-test` passes (R7).
-   MINOR-4 (review 2): D-SC-10's cite is re-pointed at the round-10 head
    (handle_named_constraint.cpp:160-162; :141-143 at 8068151ed).
-   MINOR-5 (review 2): the design page's as-landed note says two kinds of
    signature are rejected because of the checked-phase `Self`, and that the
    unqualified spelling has never been satisfiable.

Rejected: none. Review 1's MINOR-1 and the deduction half of review 2's MINOR-1
are taken as the reviewers' second options, residue W-233; review 2's MINOR-2
as its preferred option, with the new TODO filed as W-234.

Round 10's decisions as R29(a) implementation decisions, with design citation
and break condition:

-   **Only the requirement that cannot be compared is skipped**
    (structural_conformance.cpp `FunctionSignatureHasError` and
    `CheckRequirements`, impl_lookup.cpp `LookupImplWitness`; round 9's review 1
    MAJOR-1 and MINOR-2, review 2 MAJOR-1 and MINOR-1). Symptom: round 9's guard
    returned at the first mismatch against a requirement whose declaration has
    an error, so a genuine failure of a later requirement, another template
    constraint, an interface of the facet type or the class-end `require` went
    unreported, depending on declaration order; and a member whose own signature
    has an error was still reported as a mismatch at each use. Root cause: the
    guard was a `return` inside the per-requirement loop, and it tested one side
    of the comparison that `CheckFunctionTypeMatches` fails silently on.
    Decision: such a mismatch, on either side, is skipped with no diagnostic and
    the loop continues, so every other requirement is checked and reported as
    before; the check gives `StructuralCheckResult::Error` only when nothing
    else fails; `LookupImplWitness` then still looks up the facet type's
    interfaces, giving `None` (the conversion error, with no structural note)
    when one is missing and the error value otherwise. They are looked up after
    the incomplete-type error of D-SC-5(a) too, so an incomplete class that does
    not implement one is reported for it as well (sc1-fix10/q q01; trunk reports
    it for the interface alone, sc1-fix10/t n02), pinned by
    `fail_incomplete_and_interface`, added after 001cdb4c7. The impl-lookup
    cycle through them is reported after the error too, as trunk reports it for
    the analog (sc1-review10/adv2 c1, c1t; round 10's review 2 MINOR-2), pinned
    in `fail_todo_requirement_signature_error_blanket` since fill round 11.
    Design: D-SC-9 as amended at fill round 10; trunk's interface analogs, which
    report every other member, constraint and interface. (Corrected at fill
    round 11, round 10's review 2 MAJOR-1: this cited upstream's redeclaration
    checks as testing both sides, which they do not alike, since a parameter
    error silences the redeclaration's parameter check, `EntityHasParamError`,
    while a return-type error does not, x5t, d02r, d03r.) Break condition: as
    round 9's, or a program is found whose genuine failure the skip still hides;
    then the skip narrows further. BREAK CONDITION TAKEN at fill round 11 (round
    10's review 1 MAJOR-1 and review 2 MAJOR-1): the test was an error anywhere
    in either signature, so a difference the error does not cause, and a member
    that is not a function, went unreported (b07 to b12, r01 to r04, f01 to f03;
    x1 to x6, y1 to y3, m5), and round 11's decision narrows the skip to the
    error's own difference. Pinned by unsatisfied
    `fail_requirement_signature_error` and its `_other_member`,
    `_other_constraint` and `_require` siblings and
    `fail_member_signature_error`. Checked by the records commit after
    6247769bb: the cites hold at the head (structural_conformance.cpp :396
    `FunctionSignatureHasError`, :501 the member's test, :592-602 the skip,
    :611-612 the result; impl_lookup.cpp :1015-1047 and :1144-1146), and on the
    round-10 build review 1's a01, a03 to a06 and e03 and review 2's a01 to a04
    give the error counts their interface analogs give on trunk 0bdce60a5 (t01,
    t03, t04, t06, t13; a01t to a04t: 2 each), and b02, b12 and b01 the member's
    error alone, as t02, t12 and b01t do there (sc1-records10 fullcmp and
    trunk_analogs.txt).
-   **A requirement with a tuple pattern parameter is a TODO**
    (handle_named_constraint.cpp `HasTupleParamPattern` and
    `CollectStructuralMembers`; round 9's review 2 MINOR-2). Symptom: any use of
    a type against such a requirement aborted at merge.cpp:391. Root cause:
    upstream's parameter-pattern comparison has no case for a `TuplePattern`,
    and trunk aborts so for an impl of such an interface member and for a
    redeclaration (merge.cpp:360). Decision: "tuple pattern parameter in
    `template constraint`" at the requirement when the constraint's definition
    ends, and the requirement is not collected, as a parameterized one is not.
    Design: D-SC-2 as amended at fill round 10. Break condition: upstream's
    comparison handles a `TuplePattern`; then the TODO goes and the split
    becomes positive (W-234). Checked by the records commit after 6247769bb: the
    `CARBON_FATAL` is at merge.cpp:390-391 at the head and :359-360 on trunk
    0bdce60a5, the test and the TODO at handle_named_constraint.cpp:207-225 and
    :267-270, and v06_tuplepat_good, v06_tuplepat_bad and v06d give the TODO
    alone on the round-10 build.

Round 10's expectations were derived by hand from the trunk analogs, as the §4
rows say, but the development build ran the reviews' shapes before the splits
were written, so none is counted (R16(d)). Extracted and checked on 36181a729,
on the round-9 toolchain and on the round-10 build, the splits give
`fail_requirement_signature_error_other_member` 5, 3 and 5 errors,
`_other_constraint` 4, 1 and 4, `_require` 3, 1 and 2,
`fail_member_signature_error` 6, 6 and 4, the two
`fail_todo_requirement_signature_error_` splits 2 each on all three, and
`fail_todo_tuple_pattern_param` an abort, an abort and 1.

Round 10's own diff (3ae639811, 001cdb4c7, 04755f23b, 0d7ee5c19, 6247769bb,
444ccbafe) had two implementation reviews, 8 findings in all: review 1,
APPROVE-WITH-FIXES, 1 MAJOR and 2 MINOR (MAJOR-1, MINOR-1, MINOR-2); review 2,
APPROVE-WITH-FIXES, 2 MAJOR and 3 MINOR (MAJOR-1, MAJOR-2, MINOR-1 to MINOR-3).
Both checked round 10 on the driver stamped 0.0.0-0.dev+001cdb4c7 against the
round-9 toolchain rebuilt from ae807c7e8's sources (sc1-fix10/r9-install) and
trunk 0bdce60a5; review 2 re-ran the gate (1959 passed, 0 failed) and
conformance (130 / 0 / 21 over 151, 49 of 56) in a private cache. On the round's
question both found the narrowed guard right on every mixed shape they built: an
erroneous requirement before or after a genuine failure of another requirement,
`HasF & HasG` and `HasF & I` in both orders, an interface `require`, an
associated function, an import across a library boundary, an incomplete type, a
template instantiation and a nested `require` each report the genuine failure as
trunk's interface analog does and nothing for the error; "Error only when
nothing else fails" is the right rule; and looking the interfaces up after
`Error` changes no overload or blanket-impl selection, both results rejecting
(review 1's o01 to o05, review 2's o5), the one new diagnostic an impl-lookup
cycle that trunk's analog reports too (review 1's o04 and o04t, review 2's c1
and c1t). Both
found the skip itself too broad, MAJOR-1 of both: it fired on any mismatch when
either signature had an error anywhere, so a different parameter count, `self`
form, parameter type or return type next to the error, and a member that is not
a function, went unreported where trunk's impl analog reports each (review 1's
b07 to b12, r01 to r04 and f01 to f03; review 2's x1 to x6, y1 to y3, m5 and
imp/i1's `Arity`), a regression from round 9 on the member side (b07 to b12; x2,
x3, x6, y3, `Arity`) that meets round 10's break condition; the records' "only
the requirement that cannot be compared" and "upstream's redeclaration checks,
which test both sides" overclaimed, since the redeclaration check reports a
parameter difference next to a return-type error (x5t, d02r, d03r). Review 1's
other findings: MINOR-1 a tuple pattern under a default value still aborting at
merge.cpp:391 (tp01, tp10, tp11; trunk aborts so for tp01t and tp13t), W-234 and
the PR body overclaiming; MINOR-2 the ledger cites stale at the head (W-135,
W-136, W-137, W-138, W-139, W-141, W-143, W-151). Review 2's: MAJOR-2 the PR
body at 96,027 characters, over GitHub's 65,536-character description limit;
MINOR-1 the design page not listing the tuple-pattern TODO; MINOR-2 the cycle
unrecorded; MINOR-3 W-233's member side unpinned and described as following a
requirement's error only (o6; trunk's o6t is silent since there the type
declares its impl). Both found the tuple-pattern TODO honest scope under R17
(neither the design page nor p002200 covers a tuple pattern parameter, and trunk
aborts for the impl and redeclaration analogs), pinned, not firing for a
tuple-typed parameter (tp02, tp03) and changing no golden outside SC-1; the
splits pinning what the records say (their error counts, and
`overload_probe_require`'s 10 * 2 + 20 - 40 = 0 with 10 for the swapped
selection, the IR selecting `P`'s first member for `C` and its second for `D`);
the PR body naming all 50 commits, stating the trade and holding no model
identifier; gap row 60 with ten rounds, `Core.Optional(Self)`, W-233 and W-234;
and W-233's trunk claims (o01, o02 `OverloadNoMatch`; k01
`MissingImplInMemberAccess`). Review 1 re-ran probes.sh (2174 result lines) and
imps.sh (the 31 import sets), identical to sc1-records10's runs but for abort
offsets, and re-classified 147 files of round 10's comparison (the 107 differing
and 40 identical) as recorded. Review 1's probes are sc1-review10/adv1 (b: 17,
f: 4, m: 21, o: 7, rq: 17, ti: 12 trunk analogs, tp: 14, lsplit: 2, imp/x1: an
import set of 2 files), review 2's sc1-review10/adv2 (p: 22, t: 26 trunk
analogs, ti: 10, cpp: 1, imp/i1: an import set of 2 files), 153 probe files and
2 import sets in all. The round counts 2 MAJOR, MAJOR-1 the one finding of both
reviews, and no BLOCKER.

Fill round 11 (2026-10-14), by review finding, each reproduced first on the
toolchain stamped 0.0.0-0.dev+001cdb4c7 with the reviews' probes, against the
rebuilt round-9 toolchain and their trunk analogs on 0bdce60a5:

-   MAJOR-1 (both reviews): reproduced (review 1's b07 to b12, r01 to r04 and
    f01 to f03, review 2's x1 to x6, y1 to y3, m5 and imp/i1's `Arity` give the
    declaration's error alone; round 9 reported b07 to b12, x2, x3, x6 and y3;
    trunk's impl analogs report each). Taken, round 11's decision below, with
    review 2's rule refined to compare the parameters pair by pair, since
    trunk's thunk also reports a parameter that differs next to an erroneous one
    (sc1-fix11/p/z z1, z2 against z1t, z2t), and with review 1's question on
    which analog governs a parameter error next to a count or `self` difference
    answered by the impl analog, which reports it (b07t, b09t, b10t, r01t,
    r03t), not the redeclaration, which is silent (d01r), since a requirement is
    checked as an interface member is. Pinned by
    `fail_requirement_signature_error_genuine` and
    `fail_member_signature_error_genuine`, each class's expectation derived from
    its trunk impl analog (sc1-fix11/p/s); the claims are corrected in D-SC-9,
    round 9's and round 10's decisions here and in the decision log, the two
    split comments, the design page, ORCHESTRATION and the PR body.
-   MAJOR-2 (review 2): reproduced (96,027 characters). Taken as directed: the
    PR body's Review record and Verification paragraphs move verbatim into the
    PR's first comment, as PR 58 did, the body naming it in one line; both are
    re-measured with len() after this round's additions (outside the
    repository). The records commits after fa9038828 keep in the body a
    per-round summary of the review record and the latest gate and conformance
    lines, as the description's layout requires, with the NOT run paragraph,
    which the layout moves to the comment only when the body would exceed
    65,000 characters, each file measured with len() (corrected by the records
    commit after 93f2b9f24, which had said the paragraph moved).
-   MINOR-1 (review 1): reproduced (tp01, tp10 and tp11 abort at merge.cpp:391
    on 001cdb4c7; tp08 is a plain mismatch and tp09 checks clean). Taken:
    `HasTupleParamPattern` looks through a `DefaultValuePattern` as through
    `var` (round 11's toolchain change, handle_named_constraint.cpp); pinned by
    `G` in `fail_todo_tuple_pattern_param`; W-234's title and evidence say
    "directly, under `var` or under a default value". tp01, tp09, tp10 and tp11
    now give the TODO alone, and tp08 the TODO instead of its mismatch, its
    requirement no longer collected.
-   MINOR-1 (review 2): taken. The design page's D-SC-2 account adds the
    tuple-pattern TODO beside the default-definition one.
-   MINOR-2 (review 1): reproduced, and a mechanical check of every file:line
    cite in W-027, W-028, W-134 to W-143, W-151, W-168, W-169 and W-232 to W-234
    at the head (125 cites, each a named symbol checked within two lines, the
    rest read) found these off as well: W-027's handle_function.cpp:573-585
    (:571-587), handle_let_and_var.cpp:69 (:69-82), import_ref.cpp:3708 (:3732),
    type_completion.cpp :1108, :1168 and :1230 (:1109, :1169, :1231) and the
    chokepoint's convert.cpp:1955 (that of 8068151ed; :1969 at the head);
    W-134's and W-135's handle_let_and_var.cpp:69 (:77-80); W-138's
    structural_conformance.cpp:507 (:552); W-139's
    structural_conformance.cpp:541 (:587) and impl.cpp:1092 (:1091); W-140's
    :1108-1230 (:1109-1236); W-141's impl.cpp:994-1090 and :926 (:993-1089,
    :925). Each is re-pointed at the round-11 head with the reported ones (W-135
    :44, W-136 :33, W-137 :18, W-138 custom_witness.cpp:1299, W-139 :524, W-141
    :98, W-143 :299 `GetComparisonSpecifics` and :387, W-151 :273-274), and with
    the cites round 11 moved (W-027's CollectStructuralMembers :246 and the
    tuple-pattern TODO :275-278, W-234's :207-233 and :275-278); W-027's round-9
    and round-10 cites of functions round 11 removed are marked as of those
    heads.
-   MINOR-2 (review 2): taken. Round 10's first decision says the facet type's
    interfaces are looked up after the error too, so an impl-lookup cycle
    through them is reported, as trunk reports it; pinned as `J` in
    `fail_todo_requirement_signature_error_blanket`, expected from c1t.
-   MINOR-3 (review 2): reproduced (o6: `OverloadNoMatch` after the member's
    error). Taken: `fail_todo_requirement_signature_error_overload` adds the
    member-side shape (`HasG`, `D`, `Q`); gap row 60 and the PR body say "after
    a requirement's or member's signature error (W-233)", the row's first cell
    unchanged, and W-233's evidence names the shape.

Rejected: none. Review 2's MAJOR-1 rule is taken with its fourth step refined
pair by pair, as stated, and review 1's (iii) is decided for the impl analog.

Round 11's decision as an R29(a) implementation decision, with design citation
and break condition:

-   **A mismatch is skipped only where an error causes it**
    (structural_conformance.cpp `OnlyErrorsDiffer`, replacing
    `FunctionSignatureHasError`, and its use in `CheckRequirementFunction` and
    `CheckRequirements`; merge.cpp `CheckRedeclParamsMatchExceptErrors`, new;
    round 10's review 1 MAJOR-1 and review 2 MAJOR-1; SUPERSEDED at fill round
    12 by round 12's first decision, both functions deleted). Symptom: round 10
    skipped any mismatch when either signature had an error anywhere, so a
    member that differs from the requirement in its parameter count, its `self`
    form, a parameter or its return type next to the error, or that is not a
    function, was not reported, where trunk's impl analog reports each and round
    9 reported the member side. Root cause: the test asked whether an error was
    present, not whether it caused the mismatch, and was applied to every
    `Mismatch`, including the paths that compare no signature. Decision: a
    member function whose signature does not match is skipped only when it
    agrees with the requirement in the presence of `self`, the presence and
    length of each parameter list, every pair of parameters where neither has an
    error type (compared as D-SC-5(d) compares them), the return type where
    neither is an error, and the evaluation mode, and some parameter or return
    type has an error; every other mismatch, and every member that is not a
    function or has compile-time parameters of its own, is reported as for a
    requirement with no error. So each difference that the comparison reports
    without the error is reported next to it, and only the error's own
    difference is silent, as building an impl member's thunk reports nothing for
    an argument or a result of an error type. The evaluation mode is compared as
    D-SC-5(d) compares it although the thunk does not (trunk accepts an impl
    member whose mode differs, sc1-fix11/p/e e2t, and SC-1 reports it with or
    without an error, e2, e1). Design: D-SC-9 as amended at fill round 11; trunk
    0bdce60a5's impl analog, which governs a parameter error next to a count or
    `self` difference (b07t, b09t, b10t, r01t, r03t report it) where the
    redeclaration analog is silent (d01r). Break condition: upstream's thunk
    starts reporting a difference next to an erroneous parameter or result, or
    stops reporting one; then the skip follows it. Pinned by unsatisfied
    `fail_requirement_signature_error_genuine` (7 shapes reported, `ReturnOnly`
    and `ParamOnly` silent) and `fail_member_signature_error_genuine` (7
    reported, `ErrorsOnly` silent), with the earlier
    `fail_requirement_signature_error`, `fail_member_signature_error` and their
    siblings unchanged.

Round 11's expectations were derived by hand from the trunk impl analogs, as the
§4 rows say, but the development build ran the reviews' shapes before the splits
were written, so none is counted (R16(d)). Extracted and checked on the round-11
build, the splits give `fail_requirement_signature_error` 3 errors, `_genuine`
9, `_other_member` 5, `_other_constraint` 4, `_require` 2,
`fail_member_signature_error` 4, `fail_member_signature_error_genuine` 16, the
two `fail_todo_requirement_signature_error_` splits 4 each (2 each on the
round-10 build) and `fail_todo_tuple_pattern_param` 2 (1 on the round-10 build).

Round 11's own diff (2ee29f311, e7783c80e, fa9038828, 93f2b9f24, 62e25dcdd) had
two implementation reviews, 10 findings in all: review 1, APPROVE-WITH-FIXES, 2
MAJOR and 3 MINOR (MAJOR-1, MAJOR-2, MINOR-1 to MINOR-3); review 2,
APPROVE-WITH-FIXES, 1 MAJOR and 4 MINOR (MAJOR-1, MINOR-1 to MINOR-4). Both
checked round 11 on the driver stamped 0.0.0-0.dev+e7783c80e against trunk
0bdce60a5; review 1 also against a round-10 toolchain it relinked from
444ccbafe's sources and then deleted, review 2 against the round-9 build
(sc1-fix10/r9-install). On the round's question both found that round 11 hides
no genuine failure and compiles no wrong program, a skip returning `Error`.
Review 1's matrix of 330 cases (error positions none, `self`, a parameter, the
return, a default value, a compile-time parameter and a modifier, on either side
and both, against 15 mismatch positions) and review 2's of 275 (7
requirement-side and 8 member-side error positions and 5 both-side placements,
against 15 kinds of mismatch) found no case silent that trunk's impl analog
reports and nothing hidden against round 9's member side.
`CheckRedeclParamsMatchExceptErrors` had one caller and changed no non-SC-1
behavior (review 1's file_test subset 115 / 115, review 2's gate 1959 / 0),
though it copied upstream's list logic (review 1's MINOR-3, review 2's MINOR-4).
A requirement's tuple pattern was refused in every form they built (review 1's
tp: 17 and a redeclaration; review 2's tp: 13, a nested default, a tuple inside
a struct pattern and a member-side default among them), the aborts among them
being MINOR-1's. The two new splits gave 9 and 16 errors, each class as its
trunk analog. The records held: the PR body at 63,377 characters and its first
comment at 50,199, all 55 commits named, no model identifier, W-233 and W-234
exact at the head, gap row 60. Both found an erroneous default value (`y: i32 =
Undefined`, whose pattern's constant value is the error but not its type) read
as no error, MAJOR-1 of both: one gave a spurious mismatch where trunk's analog
is silent (review 1's d2, d10 and 11 matrix cases; review 2's d1, d2), and after
a skipped erroneous parameter two aborted at merge.cpp:391 (review 2's n1, n2),
an abort new in round 11. Review 1's MAJOR-2 (R17): the code followed one rule
that fits a sentence, D-SC-5(d)'s comparison with errors counted as equal, but
the records justified it by trunk's thunk, which is false for five classes newly
reported in round 11 (a `var` form, the member's own compile-time parameters,
`self` presence beside an erroneous `self`, an empty `[]`, a default value's
error) and contradicted itself on the evaluation mode. Review 1's MINORs:
MINOR-1 two erroneous default values still aborting, as trunk's plain
redeclaration does; MINOR-2 parameter errors read in the generic and return
errors in the specific (sp/s1, s2); MINOR-3 the copied list logic without a fork
marker at its definition. Review 2's MINORs: MINOR-1 the same pre-existing abort
(d3, n3; trunk's r1, r2); MINOR-2 the records' thunk analogy overclaimed (c1 to
c3); MINOR-3 `fail_todo_tuple_pattern_param` and its three siblings not naming
their W-ids; MINOR-4 the comparison logic duplicated. On R17 both stated the
code's rule in one sentence, so neither graded the machinery itself a
patchwork; review 1's MAJOR-2 graded the records' rationale for it. Review 1's
probes are sc1-review11/adv1 (mx: the 330 cases with their trunk analogs; d, e,
n, sp, tp and splits), and it re-ran probes.sh (1474 result lines over 16 sets)
and imps.sh (93 lines, identical to round 10's); review 2's are
sc1-review11/adv2 (m: the 275 cases with their analogs; mf: the no-error
baselines; d: d1 to d11, n1 to n4, s1, s1f, s2, s3 and c1 to c3 with their trunk
analogs, and r1 and r2, trunk redeclarations; tp: 13), with the gate and a cite
check (131 cites). The round counts 2 MAJOR, MAJOR-1 the one finding of both
reviews, and no BLOCKER. 9af776bac recorded the count as 9 findings, counting
that one finding once, as no earlier round's count does; the records commit
after it corrects it to 10 and writes this paragraph.

Fill round 12 (2026-10-14), by review finding, each reproduced first on the
toolchain stamped 0.0.0-0.dev+e7783c80e with the reviews' probes
(sc1-review11/adv1 and adv2) and their trunk analogs on 0bdce60a5:

-   MAJOR-1 (both reviews, the same defect): reproduced. Review 2's n1 and n2
    abort at merge.cpp:391 with exit 134; d1 and d2, and review 1's d2 and d10,
    report a mismatch that only the erroneous default value causes, where
    trunk's d1t and i_d2 are silent. Taken in review 2's preferred form, round
    12's first decision below: the comparison's errors-match mode, in which an
    erroneous default value is an error part compared by its parameter's type.
    The reviews' coarser form, the whole parameter counted as equal, is refined
    on evidence: trunk's thunk reports a member-side `y: bool = Undefined`
    against `y: i32` (sc1-fix12/p g3 and g3.t), which that form would hide. n1,
    n2, d1, d2, d3 and n3 now give the declarations' errors alone, d10 its
    genuine mismatch. Pinned by `DefaultOnly`, `DefaultBothErrors`,
    `DefaultParamType` and `DefaultType` in
    `fail_requirement_signature_error_genuine` and by `DefaultOnly` and
    `DefaultErrorType` in `fail_member_signature_error_genuine`, each against
    its trunk analog (sc1-fix12/p/s). `tr_DefaultBothErrors` aborts on trunk at
    merge.cpp:360, and an interface member's default value aborts trunk's thunk
    at thunk.cpp:169 even with no error whenever the impl member differs from
    it, so that a thunk is built (review 2's d2t; sc1-fix12/p h5.t to h7.t;
    W-236), so the no-error twins of the requirement-side default shapes have no
    trunk reference beyond that abort (corrected at fill round 13, round 12's
    review 1 finding MINOR-2 and review 2 finding MINOR-4: this note said a
    member-side default value aborts the thunk, which accepts one,
    sc1-review12/adv1/p/h h1e0, so tm_DefaultOnly is a trunk reference for the
    member side).
-   MAJOR-2 (review 1): taken. The one rule is review 1's sentence, stated in
    D-SC-9, round 12's first decision, the decision log, the design page and
    the comment at structural_conformance.cpp:502-509; the records' trunk-parity
    rationale is replaced, and the one divergence class is recorded in D-SC-9.
    Two refinements, each on evidence. First, the rule applied to D-SC-5(d) as
    built would hide a static member against a method requirement beside an
    error, which trunk reports (ms1, ms3 and ms6 against ms1.t, ms3.t and
    ms6.t), because `CheckFunctionTypeMatches` never compared the presence of
    `self`, even with no error (st1); so D-SC-5(d) is amended (round 12's
    second decision) and the rule inherits it. Second, round 11's symmetric
    `self` test is not kept, since a method serves a requirement without `self`
    (st4 runs), so ms2, ms4 and review 1's e2 are silent, as their trunk
    analogs are. The classes review 1 named are reported, each as without the
    error: a `var` form, the member's own compile-time parameters, an empty
    `[]`, a missing `self` beside an erroneous `self`. Pinned by
    `ParamErrorVar` and `ParamErrorGeneric` in
    `fail_member_signature_error_genuine`, expected from the rule (their trunk
    analogs are silent). The break condition is D-SC-5(d)'s own.
-   MINOR-1 (both reviews): reproduced. d3, n3, t_d4, t_v3 and the B_def_def
    matrix cases abort at merge.cpp:391; trunk's r1 and r2, plain
    redeclarations, abort at :360. Taken as both reviews' first option: the
    structural check runs only the errors-match comparison, which reads a
    pattern whose constant value is the error before the switch that aborts,
    so the check no longer reaches the abort. The upstream abort itself is
    filed as W-235, with the redeclaration reproducer.
-   MINOR-2 (review 1): reproduced (sp/s1 skipped, s2 a mismatch). Taken: the
    errors-match mode reads each pattern's type in its own specific, as the
    return type is read, so s2 is skipped as s1 is.
-   MINOR-3 (review 1) and MINOR-4 (review 2): taken in review 2's preferred
    form. `CheckRedeclParamsMatchExceptErrors` and `OnlyErrorsDiffer` are
    deleted, so no copy of upstream's logic remains to keep in step, and the
    errors-match mode carries a fork marker at each function that gains it (true
    from fill round 13, which adds the markers then missing at
    `CheckRedeclParamLists`, `CheckRedeclParams` and the
    `CheckFunctionTypeMatches` definition, round 12's review 1 finding MINOR-4
    and review 2 finding MINOR-1).
-   MINOR-2 (review 2): taken with review 1's MAJOR-2, which corrects the same
    account of the divergences. c1, `y: i64` beside an erroneous `x`, is
    pinned as `OtherParamConvertible`.
-   MINOR-3 (review 2): taken. The four `fail_todo_` splits of the members
    golden name W-137, W-136, W-135 and W-234; their CHECK lines are unchanged.

Rejected: none. Both reviews' MAJOR-1 is taken with the default value compared
by its type, and review 1's MAJOR-2 with the two `self` refinements above.

Round 12's decisions as R29(a) implementation decisions, with design citation
and break condition:

-   **One rule for errors: the comparison's errors-match mode** (function.cpp
    `CheckFunctionTypeMatches` and `CheckFunctionReturnTypeMatches`, merge.cpp
    `CheckRedeclParamsMatch`, `CheckRedeclParams`, `CheckRedeclParamLists` and
    `CheckRedeclParam`, each with a `found_error` parameter;
    structural_conformance.cpp `CheckRequirementFunction`; `OnlyErrorsDiffer`
    and `CheckRedeclParamsMatchExceptErrors` deleted; round 11's review 1
    MAJOR-1 and MAJOR-2 and review 2 MAJOR-1). Symptom: an erroneous default
    value was read as no error, so one gave a spurious mismatch and two aborted
    at merge.cpp:391, and the skip was justified by trunk's thunk, which it
    does not follow. Root cause: round 11 re-listed the comparison's parts in a
    parallel function that tested only a parameter's type for the error, after
    running the plain comparison. Decision: the structural check runs one
    comparison, D-SC-5(d)'s, in an errors-match mode: a parameter type or a
    return type that is the error matches any type, and a parameter whose
    default value is the error is compared by its type alone, each read in its
    own specific. A member that fails is reported as without the error; one
    that matches only through such a part is skipped, and the check's result is
    then an error when nothing else fails. A null `found_error` keeps
    upstream's behavior for every other caller. Design: D-SC-9 as restated at
    fill round 12; D-SC-5(d). Break condition: D-SC-5(d)'s own, the comparison
    proving too strict for a shape the §4 matrix predicts positive. An upstream
    change to the comparison reaches the mode by construction. Pinned by the
    two `_genuine` splits (15 and 23 errors).
-   **A requirement with `self` needs a member with `self`**
    (structural_conformance.cpp:492-501, in `CheckRequirementFunction`).
    Symptom: a static member whose first parameter has the self type satisfied
    a method requirement and failed at the use `x.Get()` (st1), and beside an
    error the rule above would hide it where trunk reports it (ms1, ms3, ms6).
    Root cause: `CheckFunctionTypeMatches` compares a `self` parameter as any
    parameter of its type. Decision: a requirement with `self` is satisfied
    only by a member with `self`; one without `self` also by a method, which
    `T.Get(x)` calls (st4). Design: D-SC-5(d) as amended at fill round 12 (the
    `self` form must agree). Break condition: Carbon gives a static member a
    method-call form, or stops calling a method as `T.Get(x)`; then the test
    follows. Pinned by `fail_static_for_method` and `method_for_assoc_fn`.

Round 12's expectations were derived from the rule and checked against the trunk
analogs before the splits were written, but the development build ran the
reviews' shapes first, so none is counted (R16(d)). Checked on the round-12
build, the splits give `fail_requirement_signature_error_genuine` 15 errors (the
round-11 golden had 9), `fail_member_signature_error_genuine` 23 (the round-11
golden had 16) and the new `fail_static_for_method` 1; every other split gives
its round-11 count, and `method_for_assoc_fn` checks clean. (Reworded at fill
round 13, round 12's review 2 finding MINOR-4: run on a round-11 toolchain, the
round-12 splits give 16 errors, with an abort at `DefaultBothErrors`, and 24.)

Round 12's own diff (a6289f86e, 62d39c9f6, 9af776bac, 395096d51) received two
implementation reviews, 10 findings in all: review 1, APPROVE-WITH-FIXES, 1
MAJOR and 4 MINOR; review 2, APPROVE-WITH-FIXES, 1 MAJOR and 4 MINOR. Both
checked round 12 on the driver stamped 0.0.0-0.dev+62d39c9f6 against trunk
0bdce60a5 and against a round-11 toolchain each relinked from 62e25dcdd's
sources and then deleted. On the round's questions both found: (a) every caller
of the six functions that gained `found_error` but
structural_conformance.cpp:511 (:518 at the round-13 head) passes null
(decl_name_stack.cpp:533, :547 and :567; merge.cpp:668, :955 and :961, at :759,
:1040 and :1046 at the round-13 head; impl.cpp:181; thunk.cpp:466 and :486;
handle_function.cpp:184, :366 and :435), with which each new branch is dead; the
full gate passed 1959 / 0; review 1's 27 probes (redeclarations, out-of-line and
qualified redeclarations, impl members with thunks, C++ operator thunks, C++
aliases, a three-file api/impl/importer set) and review 2's SemIR and LLVM IR
dumps were byte-identical, normalized, on trunk, the round-11 relink and the
current driver; both matrices re-ran as recorded, none silent where trunk's
analog reports and none aborting; (b) the `self` amendment is a fix toward
D-SC-5(d)'s own criterion and p002200's matching declarations, with a break
condition, that narrows acceptance (review 1's r05 and r13, review 2's c1,
accepted through round 11) where no design text requires accepting, every
program the page or p002200 says to accept checking clean and the runnable ones
printing `42`, conformance 130 / 0 / 21 of 151; (c) W-235 is exact and
upstream-confirmed (trunk aborts at merge.cpp:360 on a plain redeclaration, an
out-of-line method, two different erroneous default values, and an interface and
its impl); (d) the 34 removed CHECK lines are `@LINE` shifts only and the split
counts 15, 23 and 1, each class's trunk analog as recorded; (e) the PR body at
64,921 characters with all 59 commits named, the review count corrected to 10;
(f) the hunks re-apply to upstream/trunk 66a250ad9 in a clean three-way merge.
Both found, MAJOR-1 of both, that the errors-match mode compared a parameter
with an error by its type alone: it skipped a parameter with an erroneous type
whole and compared one with an erroneous default value by its declared type,
then skipped it, so its binding form (`var`, `ref`) and whether a default value
is there went uncompared, though the error does not touch them. Review 1's x1,
member `ref y: i32 = Undefined` against `y: i32`, is silent where trunk's analog
reports "value expression passed to reference parameter", and the records'
statement of the rule (D-SC-9, the decision log, the design page) said every
other difference is reported. Review 1 measured 177 of its 878-case extended
matrix hidden by the rule (127 a binding form, 5 of them reported by trunk; 50
presence or composite classes); review 2 measured 143 of its 1094 (99 a binding
form, 31 a default value's presence or value, 11 an erroneous return type
against none, 2 twin artifacts), 42 newly silent since round 11. Review 1's
MINORs: MINOR-1 the presence classes and composite types unstated; MINOR-2
W-235's related note naming an impl member's default value as the trigger of
trunk's thunk abort, which is the interface member's; MINOR-3 the D-SC-5(d)
amendment undated and the page's "same notion of same signature" sentence no
longer true; MINOR-4 three functions that gained `found_error` without a fork
marker. Review 2's MINORs: MINOR-1 the same markers; MINOR-2 the same sentence,
both round-12 amendments undated and the four statements of the rule not
identical (the W-233 clause missing from the page and from the comment); MINOR-3
the amendment's record omitting the programs it newly rejects (c1, which ran on
round 11); MINOR-4 the same trigger and the split counts' wording. Review 1's
probes are sc1-review12/adv1 (p/x, p/h, p/g, p/sp, p/tp, p/imp, p/b, p/n, p/nimp
and p/w235; mx1 and mx2, the two earlier matrices; mx3 with gen3.py, the 878
cases; dump_triple.txt, gate.log and conf/scoreboard.json); review 2's are
sc1-review12/adv2 (x with gen.py, the 1094 cases; p: bf1 to bf5, dp1, dp2, se1
to se5, tt1 and w235a to w235d; m4; th; splits; up; r1m and r2m, the earlier
matrices re-run), with a check of 138 cites and the gate. The round counts 2
MAJOR, MAJOR-1 the one finding of both reviews, and no BLOCKER.

Fill round 13 (2026-10-14), by review finding, each reproduced first on the
toolchain stamped 0.0.0-0.dev+62d39c9f6 with the reviews' probes
(sc1-review12/adv1 and adv2) and their trunk analogs on 0bdce60a5:

-   MAJOR-1 (both reviews, the same defect): reproduced. x1 gives its
    declaration's `NameNotFound` alone, while x1.t reports; bf1 to bf5 (a `var`
    or `ref` form beside an erroneous default value) are silent while their
    counted-as-equal twins report. Taken in review 2's option (b), which
    includes review 1's fix for the binding form: in the errors-match mode a
    pattern pair of which either has an error is compared as declared (merge.cpp
    `GetDeclaredParamPattern`, which reads an imported pattern in the file that
    declares it and imports its subpattern in turn), pattern kinds always and
    types where neither is the error, so only an erroneous type or default value
    counts as equal. Review 1's handling of a default value on one side only,
    counted as equal, is not taken: both reviews' mechanical oracles keep a
    default value's presence, so it is compared, as `DefaultAbsent` and
    `DefaultError` pin. x1, bf1 to bf5, review 1's k1 and its `ParamOnly` shape
    now report, and the imported shapes report or stay silent as the local ones
    do (sc1-fix13/p im1 to im15). Pinned by `ParamRef`, `DefaultRef`,
    `DefaultVar` and `DefaultAbsent` in
    `fail_requirement_signature_error_genuine` and by `ParamErrorRef`,
    `DefaultErrorRef` and `DefaultError` in
    `fail_member_signature_error_genuine`, each against its trunk analog
    (sc1-fix13/p/s).
-   MINOR-1 (review 1): taken by the code where the rule allows and stated where
    it does not. An erroneous return type no longer matches the absence of one
    (function.cpp:265-276; `ReturnAbsent`, `ReturnErrorAbsent`), and an
    erroneous default value no longer matches none (MAJOR-1). A type with an
    error anywhere in it is the error, so a composite type's other elements are
    not compared; the four statements of the rule say so (19 of review 1's 878
    cases).
-   MINOR-2 (review 1) and MINOR-4 (review 2): reproduced (sc1-fix13/p/w236:
    h5t, i64, other and static abort at thunk.cpp:169 on trunk and on the fork;
    same and implonly compile). W-235's note and round 12's note above are
    corrected, and the abort is filed as W-236; review 2's count wording is
    corrected above.
-   MINOR-3 (review 1) and MINOR-2 (review 2): taken. The design page dates both
    round-12 amendments 2026-10-14, qualifies the "same notion of same
    signature" sentence with the landed departure (the impl member comparison
    and the `self` check), and states the rule as the comment at
    structural_conformance.cpp:502-516, D-SC-9 and the decision log do, the
    W-233 clause included.
-   MINOR-4 (review 1) and MINOR-1 (review 2): taken. Fork markers at
    `CheckRedeclParamLists` (merge.cpp:514-516), `CheckRedeclParams` (:537-539)
    and the `CheckFunctionTypeMatches` definition (function.cpp:363-364).
-   MINOR-3 (review 2): taken. D-SC-5(d)'s amendment and round 12's second
    decision record the programs it newly rejects (c1, r05, r13), with
    p002200:354-355 as the reason.

Rejected: none. Review 1's suggestion to count a default value's presence as
equal gives way to review 2's option (b), with which both reviews' oracles
agree; review 2's option (a), records only, is not taken, since review 1's x1
shows a hidden genuine failure that trunk reports.

Round 13's decision as an R29(a) implementation decision, with design citation
and break condition:

-   **The errors-match mode compares a parameter with an error as declared**
    (merge.cpp `GetDeclaredParamPattern` :222-281 and `CheckRedeclParam`
    :360-404; function.cpp `CheckFunctionReturnTypeMatches` :265-276; markers at
    merge.cpp:514-516 and :537-539 and function.cpp:363-364; round 12's review 1
    MAJOR-1, MINOR-1 and MINOR-4 and review 2 MAJOR-1 and MINOR-1). Symptom: a
    binding form or a default value's presence beside an error went unreported
    (x1, which trunk's analog reports; bf1 to bf5, dp1, dp2), and an erroneous
    return type matched none. Root cause: round 12 stopped at the first pattern
    with an error, whose constant value is the error, so nothing was left to
    compare. Decision: such a pattern is read as declared and compared kind by
    kind with its subpatterns, types compared where neither is the error; an
    erroneous return type matches any return type but not none. Design: D-SC-9
    as narrowed at fill round 13; D-SC-5(d). Break condition: D-SC-5(d)'s own,
    the comparison proving too strict for a shape the §4 matrix predicts
    positive; or a Carbon change that gives a pattern with an error a constant
    value other than the error, after which the mode reads it the ordinary way.
    Pinned by the two `_genuine` splits (20 and 31 errors).

Round 13's expectations were derived from the rule and checked against the trunk
analogs and the no-error twins before the splits were written, but the
development build ran the reviews' shapes first, so none is counted (R16(d)).
Checked on the round-13 build, the splits give
`fail_requirement_signature_error_genuine` 20 errors (the round-12 golden had
15) and `fail_member_signature_error_genuine` 31 (23); every other split gives
its round-12 count. The matrices, re-run on the round-13 build (sc1-fix13/mx):
of round 11's matrices, review 1's 330 cases and review 2's 275 have none silent
where trunk's analog reports and none aborting, and the 19 and 29 that change
from round 12 are all reported now, each also reported with the error replaced
by a valid type or value (mx1tw, mx2tw); review 1's 878 cases, against its own
oracle, are 859 as the rule predicts and 19 silent where the oracle reports,
each a composite type with an error (`(i32, Undefined)`, `{.a: i32, .b:
Undefined}`), with no spurious case, no abort and none silent where trunk
reports (177 hidden on round 12); review 2's 1094 cases, against its own oracle,
flag 31 (143 on round 12), none silent where trunk reports and none aborting: 6
contain no error (a mutation deleted the erroneous part and the twin restored
it), 15 compare `ref self` against an erroneous `self` (the oracle copies the
whole parameter, the rule compares the form, as review 1's MAJOR-1 requires) and
10 are a default value beside an erroneous parameter type (stated: such a
default value is the error). The paths without `found_error` are unchanged:
review 1's 26 probes and its three-file set give byte-identical normalized SemIR
dumps on trunk and on the round-13 build, n11 differing only in the stack
addresses of an upstream abort both builds share.

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
programs moving. Round 4, on the toolchain built from the round-4 sources before
the commit (stamped 0.0.0-0.dev+2497d5000.dirty, the uncommitted edits being
exactly aa67ea281's): autoupdate over the 19 SC-1 goldens to a fixpoint, the
first pass reporting compound `checked_generic_name` as a failing positive (its
statement use, now refused; respelled before aa67ea281), the last pass changing
nothing; gate 1959 passed and 0 failed; conformance 130 / 0 / 21 over 151 with
49 of 56 bullets. Re-run on the toolchain rebuilt from ff490bd48 with a clean
tree (stamped 0.0.0-0.dev+ff490bd48): autoupdate over the 19 SC-1 goldens
changed nothing; gate 1959 passed and 0 failed, exit 0, no `!` or `?` mark;
conformance PASS 130, every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0
FAIL, 7 SKIP of 56, the same two programs moving against
fork/conformance/out/scoreboard.json. Round 4's commits: aa67ea281 (fixes, test
sources, docs, records), ff490bd48 (goldens) and d232d4753 (records). Re-run for
the records commit after d232d4753, on d232d4753 with the installed toolchain
stamped 0.0.0-0.dev+ff490bd48 (no toolchain source differs): autoupdate over the
19 SC-1 goldens changed nothing (one dot per file, the satisfy golden whose
W-168 comment round 4 edited among them); gate 1959 passed and 0 failed, exit 0,
no `!` or `?` mark; conformance PASS 130, every failure class 0, SKIP 21 of 151,
bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 48.9 s, the same two programs moving.
Round 5, on the toolchain built from the round-5 sources before the commit
(stamped 0.0.0-0.dev+77838fdd5.dirty, the uncommitted edits being exactly
616d0bc4f's): autoupdate over the 19 SC-1 goldens to a fixpoint (pass 1 rewrote
5, pass 2 none); gate 1959 passed and 0 failed; conformance 130 / 0 / 21 over
151 with 49 of 56 bullets. Re-run on the toolchain rebuilt from 18775fee3 with a
clean tree (stamped 0.0.0-0.dev+18775fee3): autoupdate over the 19 SC-1 goldens
changed nothing; gate 1959 passed and 0 failed, exit 0, no `!` or `?` mark;
conformance PASS 130, every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0
FAIL, 7 SKIP of 56, 60.9 s, the same two programs moving against
fork/conformance/out/scoreboard.json. Round 5's commits: 616d0bc4f (fixes, test
sources, docs, records), 18775fee3 (goldens) and df5120d03 (records). Re-run for
the records commit after df5120d03, on df5120d03 with the installed toolchain
stamped 0.0.0-0.dev+18775fee3 (no toolchain source differs): autoupdate over the
19 SC-1 goldens changed nothing; gate 1959 passed and 0 failed, exit 0, no `!`
or `?` mark; conformance PASS 130, every failure class 0, SKIP 21 of 151,
bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 72.0 s, the same two programs moving; the
553 probe runs (round 2's, round 3's and round 4's review sets, 514, and round
5's 39) classify on it exactly as on 18775fee3: 398 check errors, 131 programs
that compile and run, 5 that compile with no `Run` to link, and 19 aborts, each
trunk's (the 9 runs of p40, p41 and p43; 6 of `typeof` of a bound method,
type_iterator.cpp:310; 2 of C++ calling a Carbon template,
sem_ir/generic.cpp:96; 2 of an `if` expression of a tuple holding a function
value, in `BranchWithArg`), the trunk-spelled probes of each aborting so on the
trunk build of 0bdce60a5. Round 6, on the toolchain built from the round-6
sources before the commit (stamped 0.0.0-0.dev+a9c887101.dirty, the uncommitted
edits being exactly its fixes commit's): autoupdate over the 19 SC-1 goldens to
a fixpoint (pass 1 rewrote the 3 with new splits, pass 2 none); gate 1959 passed
and 0 failed, exit 0, no `!` or `?` mark; conformance PASS 130, every failure
class 0, SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 51.2 s, the same
two programs moving; the probe runs as stated under round 6's decision. Re-run
on the toolchain rebuilt from fb12f63cb with a clean tree (stamped
0.0.0-0.dev+fb12f63cb, no toolchain source differing from 56e400145): autoupdate
over the 19 SC-1 goldens changed nothing; gate 1959 passed and 0 failed, exit 0,
no `!` or `?` mark; conformance PASS 130, every failure class 0, SKIP 21 of 151,
bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 111.3 s, the same two programs moving
against fork/conformance/out/scoreboard.json; the 553 probe runs, the round-5
reviews' 412 and round 6's 42 classify exactly as on the pre-commit build. Round
6's commits: 56e400145 (fixes, test sources, docs, records), fb12f63cb (goldens)
and 857d5b048 (records). Re-run for the records commit after 857d5b048, on
857d5b048 with the installed toolchain stamped 0.0.0-0.dev+fb12f63cb (no
toolchain source differs): autoupdate over the 19 SC-1 goldens changed nothing;
gate 1959 passed and 0 failed, exit 0, no `!` or `?` mark; conformance PASS 130,
every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56
(51.2 s), the same two programs moving; the 553, 412 and 42 probe runs give
results identical, line for line, to the run on fb12f63cb. Round 7, on the
toolchain built from the round-7 sources before the commit (stamped
0.0.0-0.dev+4bc4802ae.dirty, the uncommitted edits being exactly its fixes
commit's): autoupdate over the 19 SC-1 goldens to a fixpoint (pass 1 rewrote the
2 with new splits, the declaration golden's dumps `[symbolic]` where they were
`[template]`, pass 2 none); gate 1959 passed and 0 failed, exit 0, no `!` or `?`
mark; conformance PASS 130, every failure class 0, SKIP 21 of 151, bullets 49
PASS, 0 FAIL, 7 SKIP of 56, 76.8 s, the same two programs moving against
fork/conformance/out/scoreboard.json; the probe runs as stated under round 7's
decision, and the 1007 earlier runs on fb12f63cb byte-identical to round 6's
record. Re-run on the toolchain rebuilt from 36181a729 with a clean tree
(stamped 0.0.0-0.dev+36181a729, no toolchain source differing from c0fa52df2):
autoupdate over the 19 SC-1 goldens changed nothing (one dot each, git status
clean); gate 1959 passed and 0 failed, exit 0, no `!` or `?` mark; conformance
PASS 130, every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP
of 56, 65.9 s, the same two programs moving; every probe run of rounds 2 to 7
(the 1007, round 6's reviews' 347 and 49 trunk analogs, the 14 import sets and
round 7's 14) gives the same result, line for line, as on the pre-commit build,
but for the stack addresses printed by the two sem_ir/mangler.cpp:185 aborts.
Round 7's commits: c0fa52df2 (fixes, test sources, docs, records), 36181a729
(goldens) and 30716a8c2 (records). Re-run for the records commit after
30716a8c2, on 30716a8c2 with the installed toolchain stamped
0.0.0-0.dev+36181a729 (no toolchain source differs): autoupdate over the 19 SC-1
goldens changed nothing (one dot each, git status clean); gate 1959 passed and 0
failed, exit 0, no `!` or `?` mark; conformance PASS 130, every failure class 0,
SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56 (2060.9 s, its first links
rebuilding the runtimes into a cold cache while other workstreams' runs loaded
the machine), the same two programs moving; every probe run of rounds 2 to 7
(the 1007 earlier runs, round 6's reviews' 347 and 49 trunk analogs, the 14
import sets and round 7's 14) gives results identical, line for line, to the run
on 36181a729, but for the stack addresses printed by the two
sem_ir/mangler.cpp:185 aborts. Round 8, on the toolchain built from the round-8
sources before the commit (stamped 0.0.0-0.dev+fa4cd094d.dirty, the uncommitted
edits being exactly its fixes commit's): autoupdate over the 19 SC-1 goldens to
a fixpoint (pass 1 rewrote the 4 with new splits, pass 2 none, and a third pass
after a comment-only rebuild none); gate 1959 passed and 0 failed, exit 0, no
`!` or `?` mark; conformance PASS 130, every failure class 0, SKIP 21 of 151,
bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 67.0 s, the same two programs moving
against fork/conformance/out/scoreboard.json; the probe runs as stated under
round 8's decision. Re-run on the toolchain rebuilt from 3245ec0d2 with a clean
tree (stamped 0.0.0-0.dev+3245ec0d2, no toolchain source differing from
4c2ecee22): autoupdate over the 19 SC-1 goldens changed nothing (one dot each,
git status clean); gate 1959 passed and 0 failed, exit 0, no `!` or `?` mark;
conformance PASS 130, every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0
FAIL, 7 SKIP of 56, 83.1 s, the same two programs moving; every probe run (the
1969 earlier runs, round 8's 14 and the 29 import sets) gives the same result,
line for line, as on the pre-commit build, but for the addresses that abort
traces print (amended as above). Round 8's commits: 4c2ecee22 (fixes, test
sources, docs, records), 3245ec0d2 (goldens), 253dd4031 and a13e70542 (records).
Re-run for the records commit after a13e70542, on a13e70542 with the installed
toolchain stamped 0.0.0-0.dev+3245ec0d2 (no toolchain source differs):
autoupdate over the 19 SC-1 goldens changed nothing (one dot each, git status
clean); gate 1959 passed and 0 failed, exit 0, no `!` or `?` mark; conformance
PASS 130, every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP
of 56 (51.4 s), the same two programs moving; every probe run (the 1969 earlier
runs, round 8's 14 and the 29 import sets) gives results identical, line for
line, to the run on 3245ec0d2, but for the stack addresses printed by the nine
runs aborting at sem_ir/mangler.cpp:185. Round 9 (the toolchain built from the
round-9 sources before the commit, stamped 0.0.0-0.dev+ee1f905b0.dirty, the
uncommitted edits being exactly 58dc46eb6's): autoupdate over the 19 SC-1
goldens to a fixpoint (pass 1 rewrote the 3 with new source lines, pass 2 none;
the commit messages of 58dc46eb6 and a5078358c say 4, counting requirement-call,
whose change is a comment and moved no CHECK line); gate 1959 passed, 0 failed,
exit 0, 38 s, no `!` or `?` mark; conformance PASS 130, every failure class 0,
SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 104.0 s; the full
check-phase diagnostics of 2047 probe files (every earlier set, round 8's
reviews' and round 9's own) against the toolchain of 36181a729 are identical for
1915, differ for 77 aborts only in the trace's program-arguments and version
lines, for 11 only in round 8's "through a symbolic facet" TODO text, and for 44
only by removed lines, all 55 removed errors the follow-on
`ConversionFailureTypeToFacet` with its mismatch, requirement and deduction
notes. Re-run on the toolchain rebuilt from a5078358c with a clean tree (stamped
0.0.0-0.dev+a5078358c, no toolchain source differing from 58dc46eb6): autoupdate
over the 19 SC-1 goldens changed nothing (one dot each, git status clean); gate
1959 passed, 0 failed, exit 0, 46 s, no `!` or `?` mark; conformance PASS 130,
every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56,
79.3 s; every probe run (the 1969 earlier runs, round 8's 14 and the 29 import
sets) gives results identical, line for line, to the run on a13e70542
(sc1-records8 rec_*), but for the addresses that abort traces print (the stack
addresses of the nine sem_ir/mangler.cpp:185 aborts and the code offsets of five
aborts of rounds 3 and 4's typeof probes); round 8's reviews' 48 runs and round
9's 16 (sc1-fix9 p, t, splits) give 20 clean, 42 check errors and 2 aborts, n01c
and n01i, the `constraint` and `interface` spellings that abort so on trunk
0bdce60a5 (check/eval.cpp:151, check/generic.cpp:477). Re-run for the records
commit after a5078358c, on its tree with that installed toolchain (no toolchain
source differs; one comment of the require golden re-pointed): autoupdate over
the 19 SC-1 goldens changed nothing; gate 1959 passed, 0 failed, exit 0, 93 s,
no `!` or `?` mark; conformance PASS 130, every failure class 0, SKIP 21 of 151,
bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 58.4 s. Re-run for the records commit
after 6231d5b42, on 6231d5b42 with that installed toolchain (stamped
0.0.0-0.dev+a5078358c; no toolchain source differs from 58dc46eb6): autoupdate
over the 19 SC-1 goldens changed nothing (one dot each, git status clean); gate
1959 passed, 0 failed, exit 0, 66 s, no `!` or `?` mark; conformance PASS 130,
every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56,
105.1 s, the same two programs moving; every probe run (the 1969 earlier runs,
round 8's 14, round 8's reviews' 48 and round 9's 16, 2047 in all, and the 29
import sets) gives results identical, line for line, to the run on a5078358c
(sc1-fix9 clean9_*), but for the stack addresses of the nine
sem_ir/mangler.cpp:185 aborts (round 6's v01 and vt01b; round 7's g07, g14, g15,
g07t, g07t2, g14t and g15t); the 64 runs of round 8's reviews and round 9 give
20 clean, 42 check errors and the 2 trunk-spelling aborts again (sc1-records9
rec_*). Round 9's commits: 58dc46eb6 (fix, test sources, docs, records),
a5078358c (goldens), 6231d5b42 and ae807c7e8 (records). Round 10 (the toolchain
built from the round-10 sources before the commit,
stamped 0.0.0-0.dev+ae807c7e8.dirty, the uncommitted edits being exactly
3ae639811's): autoupdate over the 19 SC-1 goldens to a fixpoint from exactly
3ae639811's test sources (pass 1 rewrote the 3 with new source lines, pass 2
none; the result is 001cdb4c7); gate 1959 passed, 0 failed, exit 0, 64 s, no `!`
or `?` mark; conformance PASS 130, every failure class 0, SKIP 21 of 151,
bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 129.4 s; the full check-phase diagnostics
of 2172 probe files (round 9's 2047, round 9's reviews' 108 and round 10's 17)
against the round-9 toolchain rebuilt from ae807c7e8's toolchain sources
(sc1-fix10/r9-install) are identical for 2065 and differ for 79 aborts only in
the trace's program-arguments line, for 13 only by added errors (the genuine
failures MAJOR-1 named: round 9's review 1's a01, a03 to a06 and e03, review 2's
a01 to a04, and the three new splits that pin them), for 10 only by removed
lines (the follow-on mismatch error with its notes after the member's own error:
b01, b02, b12, p31 three times, f03, a09, a10 and s02) and for 5 by both
(`fail_member_signature_error`; four tuple-pattern files, each an abort now the
TODO); the 31 import sets (round 9's 29, review 1's d1 and review 2's imp1) give
the same results but for abort code offsets, d1's use_missing_g now reporting
the missing `G` across the import. Re-run on the toolchain rebuilt from
001cdb4c7 with a clean tree (stamped 0.0.0-0.dev+001cdb4c7, no toolchain source
differing from 3ae639811): autoupdate over the 19 SC-1 goldens changed nothing
(one dot each, git status clean); gate 1959 passed, 0 failed, exit 0, 254 s, no
`!` or `?` mark; conformance PASS 130, every failure class 0, SKIP 21 of 151,
bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 500.7 s (other workstreams' builds
loading the machine), the same two programs moving; the 2172 probe files compare
with the round-9 toolchain exactly as on the pre-commit build (2065 identical,
each of the 107 differing files' diffs byte-identical), and the 31 import sets
give results identical, line for line, to the pre-commit build's. On 04755f23b
with that toolchain (no toolchain source differs): autoupdate over the 19 SC-1
goldens rewrote the unsatisfied golden (the new split, 31 CHECK lines), a second
pass none, the result 0d7ee5c19; gate on 0d7ee5c19 1959 passed, 0 failed, exit
0, 117 s, no `!` or `?` mark. Re-run for the records commit after 6247769bb, on
6247769bb with that installed toolchain (stamped 0.0.0-0.dev+001cdb4c7; no
toolchain source differs from 3ae639811): autoupdate over the 19 SC-1 goldens
changed nothing (one dot each, git status clean); gate 1959 passed, 0 failed,
exit 0, 60 s, no `!` or `?` mark; conformance PASS 130, every failure class 0,
SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 79.9 s, the same two
programs moving; `runner.py --self-test` OK (151 programs, 56 bullets); the full
check-phase diagnostics of the 2172 probe files against the round-9 toolchain
reproduce the clean-stamp comparison byte for byte (2065 identical; the 107
differing files' diffs identical to sc1-fix10/fulldiff_clean), and the 31 import
sets give the clean-stamp results line for line (sc1-fix10 imps_clean.txt);
every probe run through check, compile, link and run (sc1-records10 rec_*)
gives, for the 2047 earlier runs and the 29 earlier import sets, results
identical, line for line, to the run on 6231d5b42 (sc1-records9 rec_*) but for
hexadecimal addresses, since each run records its first error and round 10
changed none; round 9's reviews' 108 give 16 clean programs that run, 90 check
errors and 2 aborts, v06t and v06r, the trunk spellings that abort at
merge.cpp:391 here and at :360 on trunk 0bdce60a5; round 10's 19 (sc1-fix10 p,
t, splits) give 16 check errors, `overload_probe_require` exiting 0 and
`require_self_argument` 5, and tp_dump, which has no `Run` to link; z01 to z10
on trunk, fb12f63cb, the round-9 build and the round-10 build are as round 9's
review record states (sc1-records10/z). Round 10's commits: 3ae639811 (fixes,
test sources, docs, records), 001cdb4c7 (goldens), 04755f23b (the
incomplete-type split and its records), 0d7ee5c19 (its golden), 6247769bb
(records) and 444ccbafe (records). Round 11 (the toolchain built from
the round-11 sources before the commit, stamped 0.0.0-0.dev+444ccbafe.dirty, the
uncommitted edits being exactly 2ee29f311's): autoupdate over the 19 SC-1
goldens to a fixpoint from exactly 2ee29f311's test sources (pass 1 rewrote the
2 with new source lines, pass 2 none; the result is e7783c80e); gate 1959
passed, 0 failed, exit 0, 37 s, no `!` or `?` mark. Re-run on the toolchain
rebuilt from e7783c80e with a clean tree (stamped 0.0.0-0.dev+e7783c80e, no
toolchain source differing from 2ee29f311): autoupdate over the 19 SC-1 goldens
changed nothing (one dot each, git status clean); gate 1959 passed, 0 failed,
exit 0, 35 s, no `!` or `?` mark; conformance PASS 130, every failure class 0,
SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 72.6 s, the same two
programs moving (sc1-fix11/conf, in a private cache); the check-phase
diagnostics of 2442 probe files (round 10's 2172; round 10's reviews' 153 and
the 98 single files of review 1's import-run copies, sc1-review10/adv1/imprun;
round 11's 19, sc1-fix11/p/z), compared with the same files on the round-10
toolchain before its rebuild (sc1-fix11 r10_all.txt), are identical for 2410,
differ for 28 only by added errors (the genuine failures MAJOR-1 named: review
1's b07 to b12, r01 to r04 and f01 to f03, review 2's x1 to x4, x6, y1 to y3 and
m5; round 9's review 1 a08, a member that is a field; z1, z2, z5 and z8; and
tp09, whose requirement under a default value is the TODO now) and for 4 by both
(tp01, tp10 and tp11, each an abort now the TODO; tp08, its mismatch now the
TODO), and none only by removed lines; the 33 import sets (round 10's 31, review
1's x1 and review 2's i1) give the round-10 results but for i1's `Arity`, now
reported across the import. The comparison was first run on a development build
whose merge.cpp had an `#include <tuple>`, removed before the commit, which
moved the abort at merge.cpp:391 to :393 in 7 files and changed nothing else.
Round 11's commits: 2ee29f311 (fixes, test sources, the design page), e7783c80e
(goldens), fa9038828 (records), 93f2b9f24 (records) and the records commit
after it. Re-run by 93f2b9f24 on fa9038828 with the toolchain stamped
0.0.0-0.dev+e7783c80e (no
toolchain or test source differs from e7783c80e): gate 1959 passed, 0 failed,
exit 0, 70 s; conformance PASS 130, every failure class 0, SKIP 21 of 151,
bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 97.3 s, the same two programs moving
(sc1-records11/conf, in a private cache); `runner.py --self-test` OK (151
programs, 56 bullets); `git merge-tree` of fa9038828 against trunk 3eb7f36f0
conflicts in fork/ORCHESTRATION.md only. On trunk 0bdce60a5 93f2b9f24 also
re-ran the analogs that round 11's records cite, each as recorded: the two new
splits' classes (sc1-fix11/p/s: `tr_ReturnOnly`, `tr_ParamOnly` and
`tm_ErrorsOnly` give their declarations' errors alone, each other class the
thunk's report at the impl too), z1t to z9t (each the error count of its fork
probe), e1t (the interface's error alone) and e2t (clean), W-233's o01, o02 and
k01, and the cycle's o04t and c1t. Re-run on 93f2b9f24 for the records commit
after it with that toolchain: gate 1959 passed, 0 failed, exit 0, 69 s;
conformance PASS 130, every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0
FAIL, 7 SKIP of 56, 53.9 s, the same two programs moving. Round 12 (the
toolchain built from the round-12 sources before the commit, stamped
0.0.0-0.dev+62e25dcdd.dirty, the uncommitted edits being a6289f86e's but for a
comment and clang-format's rewrap of one signature): autoupdate over the 3
edited SC-1 goldens from exactly a6289f86e's test sources rewrote the
unsatisfied golden (153 CHECK lines added, 34 removed, each removed line an
`@LINE` offset that the new lines moved; the result is 62d39c9f6), a second pass
none; gate 1959 passed, 0 failed, exit 0, 37 s; conformance PASS 130, every
failure class 0, SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 76.8 s.
Re-run on the toolchain rebuilt from 62d39c9f6 with a clean tree (stamped
0.0.0-0.dev+62d39c9f6): autoupdate over the 19 SC-1 goldens changed nothing (one
dot each, git status clean); gate 1959 passed, 0 failed, exit 0, 39 s, no `!` or
`?` mark; conformance PASS 130, every failure class 0, SKIP 21 of 151, bullets
49 PASS, 0 FAIL, 7 SKIP of 56, 85.8 s, exactly the same two programs moving
against fork/conformance/out/scoreboard.json (sc1-fix12/conf, in a private
cache). The check-phase diagnostics of the earlier probe files that still exist
(1547 of round 11's 2442; sc1-review5, sc1-review6, sc1-fix5 and sc1-fix6, 895
files, are no longer in the scratch area), compared with round 11's run on
e7783c80e (sc1-fix11 r11a_all.txt), are identical for 1538, differ for 7 only in
the line of an upstream abort (merge.cpp:391 now :425, the trunk spellings v06r,
v06t, tp01t, tp12t, tp13t, tp1 and tp2 that abort on a redeclaration or an
impl), and for 2 only by removed lines (sc1-review10/adv1 b01 and b02, an
erroneous default value against a default value or none, whose spurious mismatch
is gone); the 19 import sets that still exist give round 11's results for all 31
runs. Round 11's reviews' 1989 probe files and round 12's own (sc1-fix12/p and
p/s) were run on the round-12 build (sc1-fix12 r12n_all.txt): no abort on an
SC-1 path, the 60 that abort being trunk spellings (an interface and its impl,
or a redeclaration) on upstream's paths; review 1's 330-case matrix differs from
round 11 in 14 cases, 10 now silent as trunk's analogs are and 4 of round 11's
aborts now the declarations' errors or a mismatch, and review 2's 275-case
matrix in 7, each now silent as trunk's analog is; neither has a case silent
where trunk's impl analog reports. Round 12's commits: a6289f86e (fixes, test
sources, the design page), 62d39c9f6 (goldens), 9af776bac (records), which
re-ran the gate after its test comment's edit (1959 passed, 0 failed, exit 0, 54
s), and the records commit after it. Re-run on 9af776bac for the records commit
after it with the toolchain stamped 0.0.0-0.dev+62d39c9f6 (no toolchain source
differs from 62d39c9f6, and no test source but that comment): gate 1959 passed,
0 failed, exit 0, 78 s, no `!` or `?` mark; conformance PASS 130, every failure
class 0, SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56, 114.4 s, the
same two programs moving (sc1-records12/conf, in a private cache); `runner.py
--self-test` OK (151 programs, 56 bullets); `git merge-tree` of 9af776bac
against trunk 3eb7f36f0 conflicts in fork/ORCHESTRATION.md only. Round 13 (the
toolchain built from the round-13 sources before the commit, stamped
0.0.0-0.dev+395096d51.dirty, the uncommitted edits being exactly dfd22bdd6's):
autoupdate over the unsatisfied golden from dfd22bdd6's test sources rewrote it
(185 CHECK lines added, 52 removed, each removed line an `@LINE` offset that the
new lines moved; the result is 2af5604a3); gate 1959 passed, 0 failed, exit 0,
39 s; conformance PASS 130, every failure class 0, SKIP 21 of 151, bullets 49
PASS, 0 FAIL, 7 SKIP of 56, 73.2 s. Re-run on the toolchain rebuilt from
dfd22bdd6 (stamped 0.0.0-0.dev+dfd22bdd6): autoupdate over the 19 SC-1 goldens
rewrote the unsatisfied golden to the same result and a second pass changed
nothing; gate 1959 passed, 0 failed, exit 0, 44 s, no `!` or `?` mark;
conformance PASS 130, every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0
FAIL, 7 SKIP of 56, 76.0 s, exactly the same two programs moving against
fork/conformance/out/scoreboard.json (sc1-fix13/conf2, in a private cache).
Round 13's commits: dfd22bdd6 (fixes, test sources, the design page), 2af5604a3
(goldens) and 6992c6cc5 (records), which re-ran the gate after its test
comment's edit (1959 passed, 0 failed, exit 0, 41 s) and conformance (the same
totals, 56.7 s, sc1-fix13/conf3), and the records commit after it. Re-run on
6992c6cc5 for the records commit after it with that toolchain (no toolchain
source differs from dfd22bdd6, and no test source but 6992c6cc5's comment): gate
1959 passed, 0 failed, exit 0, 40 s, no `!` or `?` mark; conformance PASS 130,
every failure class 0, SKIP 21 of 151, bullets 49 PASS, 0 FAIL, 7 SKIP of 56,
86.9 s, the same two programs moving (sc1-records13/conf, in a private cache);
`runner.py --self-test` OK (151 programs, 56 bullets); `git merge-tree` of
6992c6cc5 against trunk 3eb7f36f0 conflicts in fork/ORCHESTRATION.md only;
W-236's six reproducers (sc1-fix13/p/w236) give on trunk 0bdce60a5 what they
give on the round-13 build: h5t, i64, other and static abort at thunk.cpp:169,
and same and implonly compile (sc1-records13/w236). For the records commit after
6992c6cc5, round 13's records checked against the head (sc1-records13): the two
`_genuine` splits give 20 and 31 errors and `fail_static_for_method` 1, every
other split its round-12 count; each of 2af5604a3's 52 removed CHECK lines
matches one of its 185 added lines once its `@LINE` offset is normalized;
D-SC-9's statement of the rule and ROUND 13's DECISION's are the same word for
word, and the comment at structural_conformance.cpp:502-516 and the design page
carry each of its clauses in the same words, written as sentences among their
own on what is reported, the page naming "the signature comparison" for
D-SC-5(d)'s.

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
