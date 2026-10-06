<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Structural conformance plan: `template constraint` with member requirements (SC-1, W-027)

**Status:** rev 1 — awaiting the two adversarial plan reviews (R29(c)). Branch
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

| # | Design element (F-010 B1 / p000818 / p002200) | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `template` keyword | LANDED as a keyword, not a modifier | lex/token_kind.def:236 `CARBON_KEYWORD_TOKEN(Template, "template")`; it is consumed only inside binding patterns (parse/handle_binding_pattern.cpp:89, :218 `TemplateBindingName`; handle_pattern.cpp:37; handle_let.cpp:36). `constraint` is a declaration introducer (token_kind.def:163; parse/handle_decl_scope_loop.cpp:134-135 maps it to `NamedConstraintIntroducer` / `TypeAfterIntroducerAsNamedConstraint`) |
| 2 | Parsing `template constraint X { … }` | MISSING: `UnrecognizedDecl` | parse/testdata/generics/named_constraint/template_constraint.carbon, split `fail_todo_template_constraint.carbon` (:11-33): both `template constraint Foo {` and `template constraint ForwardDeclared;` yield `InvalidParseStart 'template'`. Mechanism: `HandleDecl` (handle_decl_scope_loop.cpp:333-351) runs `TryHandleAsModifier` (:299-331), whose accepted set is the x-macro `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER` list (:303-309) plus `extern` (:311-325); `template` is in neither, so `TryHandleAsDecl` sees it with `DeclIntroducerKind::Unrecognized` (:195-205). The TODO at :343-347 even names the phase-keyword-before-introducer case |
| 3 | Modifier machinery | MACHINERY LANDED, one x-macro line away (the OV-1 `overload` precedent, fork/overload/plan.md D-OV-1) | parse/node_kind.def modifier block :422-437 (`Abstract` :422 … `Static` :436, `Virtual` :437); every consumer is generated: `TryHandleAsModifier` (:303-309), the next-token list of `ResolveAmbiguousTokenAsDeclaration` (:284-286), the statement-level dispatch (parse/handle_statement.cpp:54-56), the check handler `HandleParseNode(Parse::Name##ModifierId)` (check/handle_modifier.cpp:111-118). `NamedConstraintSignature` already carries `llvm::SmallVector<AnyModifierId> modifiers` (parse/typed_nodes.h:1992-2000) |
| 4 | Check: modifier set and per-declaration limits | MACHINERY LANDED | `CARBON_KEYWORD_MODIFIER_SET` (check/keyword_modifier_set.h:29-58; the "at most one of these declaration modifiers" group :41-51 is `Abstract` … `Virtual`), `LimitModifiersOnDecl` diagnoses `ModifierNotAllowedOnDeclaration` "`{0}` not allowed on `{1}` declaration" (check/modifiers.cpp:100-107). The named-constraint declaration limits itself to `KeywordModifierSet::Access` (check/handle_named_constraint.cpp:57) |
| 5 | Check: the `template constraint` hook | TODO, two sites | handle_named_constraint.cpp:44-45 "TODO: PopSoloNodeId(`template`) if it's present, and track that in the NamedConstraint. Or maybe it should be a modifier, like `abstract class`?" and :113-114 "TODO: Support for `template constraint`." / `bool is_template = false;`, which already flows into `AddSelfSymbolicBindingToScope(…, is_template)` (:134-136; check/interface.cpp:138-157) — upstream intends `Self` to be a template binding inside a template constraint |
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

1.  **W-027 notes and the design record (:277, :375, :453) cite
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
    (B1 cost, :370; implementation-realities :266-273).** Upstream's PRs
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
6.  **The record's "structural witness: an impl-witness-shaped table"
    (:335-339, :383-386) and the stranded page's "Structural witnesses"
    section (:550-566).** p002200:385-399 defines the semantics by NAME
    ("`C.F` and `HasF.F` refer to the same function"; `z.(HasF.F)` resolves
    to `z.(C.(A.F))` through D's alias), which needs no table; a table has
    no consumer in B1 (§0.1 rows 14, 17). D-SC-4 drops the table and the
    ported page says so.
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
    `Returned` and `Virtual`); handle_named_constraint.cpp:57 becomes
    `LimitModifiersOnDecl(context, introducer, KeywordModifierSet::Access |
    KeywordModifierSet::Template)` and `is_template =
    introducer.modifier_set.HasAnyOf(KeywordModifierSet::Template)`. Every
    other declaration rejects it through its existing `LimitModifiersOnDecl`
    call with `ModifierNotAllowedOnDeclaration` ("`template` not allowed on
    `fn` declaration") — zero new code. This is the second branch of
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
    constraint body keeps `require … impls` and `alias` semantics unchanged
    and is otherwise `context.TODO`: a `fn` with a body ("function
    definition in `template constraint`"), `var`/`let` members ("field
    requirement in `template constraint`" — sub-fork F-010b deferred, the
    details.md:1068-1071 enumeration lists only methods, associated
    constants and associated functions), and a requirement `fn` with its
    own compile-time bindings ("parameterized requirement in `template
    constraint`" — sub-fork F-010l, the stranded page recommends deferring
    past 0.1). Associated-constant requirements (`let X: type;`) are also
    TODO in SC-1: the interface form routes through
    `AssociatedConstantIntroducer` in `InterfaceContext` only
    (handle_decl_scope_loop.cpp:160-162), so there is no parse for it in a
    constraint body today. Break condition: owner veto, or SC-B2 needing
    fields for its validity blocks — then fields land with B2 under the
    same matcher (D-SC-5) with `FieldDecl` type equality.
-   **D-SC-3 — WHERE satisfaction is evaluated: the facet-conversion
    chokepoint, and nowhere else.** `LookupImplWitness`, reached from
    convert.cpp:1955 for a concrete type at a call site
    (deduce.cpp:343/:568 → `ConvertToValueOfType`), at `impls`
    expressions, and at `require` satisfaction for impls
    (impl.cpp `CheckRequireDeclsSatisfied` :834). A template-DEPENDENT
    argument never reaches it early: the enclosing call is a `CallAction`
    (call.cpp:765, :886) or the conversion a `ConvertAction`
    (convert.cpp:2312, :2418), both parked in the eval block and replayed
    by `PerformDelayedAction` at instantiation with concrete operands
    (eval.cpp:3150-3163; §0.1 row 12), where the replay calls
    `PerformCallHelper` → deduce → convert → the same chokepoint. So the
    structural check composes with upstream's template mechanism by
    construction and does not fight it; the design record's extra action
    kind (§0.2 item 3) is retired. Break condition: a §4 golden shows a
    dependent shape reaching `LookupImplWitness` with a still-symbolic
    template self (a `[template]`-phase `symbolic_binding` as
    `query_self`) — then D-SC-6's symbolic rule would wrongly reject it,
    and the fix is to return `InstBlockId::None`-free "deferred" from the
    structural check for template-phase selves (the conversion then stays
    an action), not a new action kind.
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
    with a context note; sub-fork F-010h resolved as the stranded page
    recommends — incomplete is unsatisfied, diagnosed when `diagnose`);
    (b) member lookup of the requirement's name IN THE TYPE through the
    member-access lookup path (`LookupMemberNameInScope`,
    member_access.cpp:320-386, exposed through a thin wrapper in
    member_access.h), with `required = false`, the caller's access
    context, and `lookup_in_type_of_base = false` — so an `alias F =
    A.F` in the class resolves through impl lookup to the impl's function
    (p002200's class `D`), an external `impl C as A` does NOT satisfy
    (p002200:361-377: lookup in `C` finds nothing), a private member does
    not satisfy from outside, and a C++ class's methods are imported on
    demand exactly as for `p->Get()`;
    (c) the found member must be a single `FunctionDecl` (an
    `OverloadSetValue`, a `CppOverloadSetValue`, a field, a class or a
    namespace is a mismatch);
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
-   **D-SC-6 — a SYMBOLIC (non-template) self.** A structural requirement
    against a symbolic self is satisfied iff the self facet value's own
    facet type already lists the same structural requirement (same
    `SpecificNamedConstraint`, same self) — so `T: HasGet & I` converts to
    `HasGet`, and `T: HasGet` converting to itself takes the existing
    shortcut (convert.cpp:1945-1948) before any lookup. Otherwise it is
    unsatisfied: a checked-generic `U: type` passed to `template T:
    HasGet` fails at the checked function's DEFINITION with
    `ConversionFailureTypeToFacet` plus the note
    `StructuralRequirementNeedsConcreteType` — the conservative answer to
    leads issue 2153 that F-010 already adopted. A TEMPLATE-phase self never
    reaches the check (D-SC-3). Break condition: upstream resolves issue 2153
    toward "checked generics may call templates" — then the symbolic case
    becomes a deferred `LookupImplWitness`-style query instead of an error.
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
    `require_impls` blocks; incomplete constraints are skipped there and
    caught at use). (ii) `impl C as HasGet` is ALREADY an error:
    identification yields no impl-as interface and impl.cpp:1025-1030
    emits `ImplOfNotOneInterface` "impl as 0 interfaces, expected 1" —
    sub-fork F-010m resolved as "error" by pinning (§4.B
    `fail_impl_as_template_constraint`). (iii) `require impls HasGet` inside
    an interface or plain constraint stays legal: a concrete implementer is
    checked at the chokepoint when `CheckRequireDeclsSatisfied` runs
    (impl.cpp:834) and a blanket `impl forall` is rejected by D-SC-6 — the
    natural meaning, pinned by `template_constraint_require.carbon`. Break
    condition for (i): upstream's issue 2153 resolution (as D-SC-6).
-   **D-SC-9 — diagnostics: six new kinds, notes attached to the EXISTING
    conversion error.** `DiagnoseConversionFailureToConstraintValue`
    (convert.cpp:1503-1527) switches from `Emit` to `Build` + notes +
    `Emit`, and `NoteStructuralConformanceFailure` (structural_conformance.h)
    re-runs the check in explain mode to add, for the FIRST unsatisfied
    requirement in declaration order (the stranded page's rule, :566-579):
    `StructuralMemberMissing` (Note, "type {0} has no member named `{1}`
    required by template constraint `{2}`"),
    `StructuralMemberMismatch` (Note, "member `{1}` of type {0} does not
    match the signature required by template constraint `{2}`"),
    `StructuralRequirementHere` (Note, "requirement declared here", at the
    requirement `fn`), `StructuralRequirementNeedsConcreteType` (Note,
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
    That is 7 kinds, each covered by a §4 golden (coverage_test). The
    deferred forms of D-SC-2 use `context.TODO` (`SemanticsTodo`, no kind).
    Break condition: a reviewer finds an existing kind whose text already
    fits — then that kind is reused and the count drops.
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
    `template_constraint_overload.carbon`. `?`: no interaction (a
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
    for SC-B2/SC-B3. The four sibling hunks (generics/README.md link,
    details.md:1068-1077 cross-reference, terminology.md, templates.md
    :100-111 replaced by a dated paragraph linking the page) are re-read
    against trunk before porting (details.md moved under UA-1; the stranded
    diff also deletes trunk sections it must NOT delete — §Rewrites and
    same-type constraints :1131, §Constraints that don't depend on `.Self`
    :1141 — so only the :1068-1077 hunk is taken). Break condition: none;
    docs follow the implementation.
-   **D-SC-14 — the conformance program is rewritten in F-010's shape
    (template constraint, not interface), un-SKIPped in commit 2, no
    `.diff.cpp`.** Exact text in §5.A. R30 does not apply (no documented
    divergence; both sides agree) and the README's differential preference
    (fork/conformance/README.md:396-399) is for "already-working behavior
    with a natural C++ counterpart" — a C++20 concept oracle would test
    Clang, not the fork. The second program (D-SC-11) sits under the SAME
    bullet (the C++ class is the argument, not a concept mapping).
-   **D-SC-15 — storage: two fields on `NamedConstraint`, one vector on
    `IdentifiedFacetType`.** `bool is_template` (set at the declaration,
    checked on redeclaration — D-SC-16) and `InstBlockId
    structural_members_id` (the requirement `FunctionDecl` inst ids in
    declaration order, collected at `}` by scanning
    `body_block_with_self_id` for `FunctionDecl` insts — no new collector
    stack; `require_impls_block_id` is set at the same point,
    handle_named_constraint.cpp:189-194). `Print` prints both only when
    non-default (the `Function::Print` pattern, sem_ir/function.h:244-290),
    so the three raw_sem_ir goldens that print named constraints stay
    byte-identical (§6). Import: `is_template` copied, the members block
    imported as import-refs the way interfaces import
    `associated_entities_id` (import_ref.cpp:1519-1540 `AddAssociatedEntities`,
    :3620-3622), beside the existing `require_impls_block_id` import
    (:3781-3783). `IdentifiedFacetType` gains `struct StructuralRequirement
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
    the first half. Header 30/21/4/1 → 30/22/3/1. DONE waits for SC-B2.
-   **D-SC-18 — `FunctionInNonTemplateConstraint` is an ERROR, not a TODO,
    and `var`/`let` in a plain constraint stay as they are.** A `fn` in a
    plain `constraint` would otherwise look structural and check nothing —
    the silent-wrong shape R15 forbids — and it sits on the one code path
    SC-1 edits (handle_function.cpp:555-575). The `var`/`let`-in-plain-
    constraint TODOs (invalid_members.carbon splits `todo_fail_invalid_var`,
    `todo_fail_invalid_let`) are upstream's and untouched. Break condition:
    none.

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
    constraint`")`. `var`/`let` with a `NamedConstraintWithSelfDecl` current
    scope in `HandleIntroducer` (handle_let_and_var.cpp:68-80) when the
    constraint is template → `context.TODO("field requirement in `template
    constraint`")`.
4.  Check, `}` (D-SC-15): after `require_impls_block_id` is set
    (handle_named_constraint.cpp:189-194), `structural_members_id =
    inst_blocks().Add(FunctionDecl insts of body_block_with_self_id)` (or
    `InstBlockId::Empty`). `complete` semantics unchanged.
5.  Import (D-SC-15): `TryResolveTypedInst(NamedConstraintDecl)`
    (import_ref.cpp:3697-3796) copies `is_template` and imports
    `structural_members_id` as a block of import-refs
    (`AddAssociatedEntities`-style, :1519-1540); `MergeDefinition` carries
    both. A template constraint declared in library `a` and used in `b`
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
                  │    └─ CheckStructuralRequirements(…, diagnose)  ── false → InstBlockId::None
                  ├─ required_impls() empty? → InstBlockId::Empty
                  └─ interface loop (unchanged)
convert.cpp:1976  diagnose → DiagnoseConversionFailureToConstraintValue
                               Build(ConversionFailure*…) + NoteStructuralConformanceFailure + Emit
```

1.  `GetRequiredImplsFromConstraint` (impl_lookup.cpp:226-246) is widened to
    return the `IdentifiedFacetType*` (callers read `required_impls()`), so
    `LookupImplWitness` can read `structural_requirements()` before the
    `req_impls.empty()` early return at :1014-1016.
2.  `CheckStructuralRequirements` (D-SC-5, D-SC-6, D-SC-7) returns `false`
    for the first unsatisfied requirement; with `diagnose == false` it emits
    nothing (overload probing, deduction with `diagnose_ = false`). With
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
`RequireCompleteType`, `IdentifyFacetType`'s loops, the import-ref block
helpers, `RedeclPrevDecl`. New: structural_conformance.{h,cpp} (about 250
lines: `CheckStructuralRequirements`, `NoteStructuralConformanceFailure`,
`FacetTypeHasStructuralRequirements`, the four private helpers), two
`NamedConstraint` fields, one `IdentifiedFacetType` vector, 7 diagnostic
kinds, one parse node kind, one modifier-set entry.

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
-   "C++ method `self` qualifiers in structural matching" — ONLY if
    D-SC-5's break condition fires.
-   "satisfaction cache" — ONLY if D-SC-7's break condition fires.

## §2 Implementation spec (file by file)

### §2.A Commit 1 — declaration side

1.  toolchain/parse/node_kind.def:
    `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER(Template)` between `Static` (:436)
    and `Virtual` (:437).
2.  toolchain/check/keyword_modifier_set.h: `X(Template)` between `Returned`
    and `Virtual` in the Decl group (:41-51). No set constant changes
    (`KeywordModifierSet::Interface`, `Class`, `Method` do not include it).
3.  toolchain/sem_ir/named_constraint.h: `bool is_template = false;` and
    `InstBlockId structural_members_id = InstBlockId::None;` in
    `NamedConstraintFields`; `Print` adds `, is_template: true` and `,
    structural_members_id: …` only when set; `MergeDefinition` copies
    `structural_members_id` (and asserts `is_template` equality — the check
    diagnosed it first).
4.  toolchain/check/handle_named_constraint.cpp: :57 limit → `Access |
    Template`; after `TryMergeRedecl` (:69-83) the D-SC-16 comparison; new
    entity sets `is_template`; :113-114 read the flag; `}` handler collects
    `structural_members_id` after :194. The two TODO comments (:44-45,
    :113) are deleted.
5.  toolchain/check/handle_function.cpp:555-575: the
    `NamedConstraintWithSelfDecl` branch (§1.A.3) + the two `context.TODO`
    sites (definition, parameterized requirement) placed where
    `is_definition` and `function_info.generic_id` are known (the
    `BuildFunctionDecl` tail around :1100-1140, which already reads
    `introducer.modifier_set`).
6.  toolchain/check/handle_let_and_var.cpp:68-80 `HandleIntroducer`: the
    field-requirement TODO when the current scope is a template
    `NamedConstraintWithSelfDecl`.
7.  toolchain/check/import_ref.cpp:3697-3796 and
    `ImportNamedConstraintDefinition` (:3675-3693): import `is_template` and
    `structural_members_id`.
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
    `FacetTypeHasStructuralRequirements`; helpers `FindStructuralMember`
    (wraps the exposed `LookupMemberNameInScope`), `RequirementMatches`
    (D-SC-5(d)), `SelfFacetCarriesRequirement` (D-SC-6).
4.  toolchain/check/member_access.{h,cpp}: expose `LookupMemberNameInScope`
    (:320) as `LookupMemberNameInTypeScopes` (or make it non-static); the
    compound-access redirect (§1.B.3) at :792-868.
5.  toolchain/check/impl_lookup.cpp:226-246 and :1007-1016 (§1.C.1-2).
6.  toolchain/check/convert.cpp:1503-1527 (§1.C.3).
7.  toolchain/check/handle_binding_pattern.cpp:313-349 (D-SC-8(i)).
8.  toolchain/diagnostics/kind.def: the five remaining kinds in a new "//
    Structural conformance." block after "Require checking." (:455-465).
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
    whose scoreboard must move: +1 PASS / −1 SKIP).
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
| check/testdata/named_constraint/template_constraint.carbon (new) | `decl.carbon`: `template constraint HasGet { fn Get(self) -> i32; fn Make() -> Self; }` with `//@include-in-dumps`; `forward.carbon`: `template constraint F; template constraint F { fn G(ref self); }`; `compose.carbon`: a template constraint with `require impls Core.Destroy;` and a method; `generic.carbon`: `template constraint Has(T: type) { fn Get(self) -> T; }` | No STDERR. SemIR: `%HasGet.type: type = facet_type <@HasGet>` as for plain constraints (basic.carbon golden :45-49); inside `@HasGet` a `%Self: %HasGet.type = symbolic_binding Self, 0, template [template]` (D-SC-10 — the `, template` suffix as member_access.carbon:159) and two `fn_decl`s whose `self` pattern is `@HasGet.%Self`-typed; `generic.carbon` shows the with-self generic over `(T, Self)` |
| check/testdata/named_constraint/fail_template_constraint_modifier.carbon (new) | `fail_on_fn.carbon`: `template fn F();`; `fail_on_class.carbon`: `template class C {}`; `fail_on_interface.carbon`: `template interface I {}`; `fail_twice.carbon`: `template template constraint X {}` | `ModifierNotAllowedOnDeclaration` "`template` not allowed on `fn` declaration" (modifiers.cpp:102-104) etc.; `fail_twice` → `ModifierRepeated` from `HandleModifier` (handle_modifier.cpp:41-109) |
| check/testdata/named_constraint/fail_template_constraint_redecl.carbon (new) | `fail_decl_then_template_def.carbon`: `constraint X; template constraint X {}`; `fail_template_decl_then_def.carbon`: `template constraint X; constraint X {}` | `NamedConstraintRedeclTemplateMismatch` at the second declaration + `RedeclPrevDecl` note at the first |
| check/testdata/named_constraint/invalid_members.carbon (EXISTING; three splits move) | `todo_fail_invalid_fn.carbon` → `fail_invalid_fn.carbon` (same source, TODO comments rewritten); `fail_todo_invalid_var_template.carbon`, `fail_todo_invalid_let_template.carbon` keep their names | `fail_invalid_fn`: `FunctionInNonTemplateConstraint` at each of the four `fn`s (:19-20, :25-26). The two template splits lose `UnrecognizedDecl` + "handle invalid parse trees" and gain `SemanticsTodo` "`field requirement in `template constraint``" at the `var` |
| check/testdata/named_constraint/fail_todo_template_constraint_members.carbon (new) | `fail_todo_definition.carbon`: `fn G(self) -> i32 { return 1; }` in a template constraint; `fail_todo_parameterized.carbon`: `fn H[U: type](self, u: U);`; `fail_todo_assoc_const.carbon`: `let X: type;` | `SemanticsTodo` with the D-SC-2 strings; the `let` one is whatever a `let` in `DeclScopeLoopAsRegular` yields plus the field TODO — predicted TODO text "field requirement in `template constraint`" (the `let` path also enters `HandleIntroducer`) |

### §4.B Commit 2

| File | Splits | Prediction |
| --- | --- | --- |
| check/testdata/named_constraint/template_constraint_satisfy.carbon (new) | `method.carbon`: `class C { fn Get(self) -> i32 { return 1; } } fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); } fn Test(c: C) -> i32 { return CallGet(c); }` with `//@dump-sem-ir-begin/end` around `Test`; `ref_self.carbon` (`fn Get(ref self)` both sides, called on a `var`); `assoc_fn.carbon` (`fn Make() -> Self;` satisfied, called as `T.Make()`); `alias_member.carbon` (p002200's `class D { impl as A { fn F(self) {} } alias F = A.F; }` satisfies `HasF`) | No STDERR. In `Test`: `%HasGet.facet: %HasGet.type = facet_value %C, () [concrete]` (EMPTY witness list — D-SC-4; the shape `facet_value <type>, (<witnesses>)` from member_access.carbon:163), `%CallGet.specific_fn … @CallGet(%HasGet.facet)`, a `call`. The generic body is unchanged from member_access.carbon's action shape (:239-243). `alias_member` shows the alias resolving through `impl_witness_access` during the check (no visible SemIR; the test is that it compiles) |
| check/testdata/named_constraint/fail_template_constraint_unsatisfied.carbon (new) | `fail_missing.carbon` (class without `Get`); `fail_wrong_return.carbon` (`-> bool`); `fail_wrong_self.carbon` (`ref self` vs value `self`); `fail_wrong_arity.carbon` (`fn Get(self, n: i32)`); `fail_external_impl.carbon` (p002200's `class C {} impl C as A { fn F(self) {} }` — lookup in `C` finds nothing); `fail_private.carbon` (`private fn Get(self)`); `fail_overload_set.carbon` (the class's `Get` is an `overload fn` set); `fail_incomplete.carbon` (`class Inc; … CallGet(p)` on an incomplete type) | Each: `ConversionFailureTypeToFacet` "cannot convert type `C` into type implementing `HasGet`" at the call (as fail_convert_facet_value_to_missing_impl.carbon:20-25 shows the facet-to-facet twin) + `DeductionGenericHere` note + `StructuralMemberMissing` or `StructuralMemberMismatch` + `StructuralRequirementHere`. `fail_private`: `StructuralMemberMissing` (lookup rejects access → treated as not found — predicted; if the access check emits `ClassInvalidMemberAccess` instead, the split's prediction moves, not the design). `fail_incomplete`: `IncompleteTypeInConversion`-class error with the structural context note (the exact kind is whatever `RequireCompleteType`'s caller supplies — this plan supplies a Context note "while checking `HasGet` requirements"; if a reviewer prefers an existing kind, §7 R-6) |
| check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon (new) | `fail_generic_binding.carbon`: `fn Bad(generic T: HasGet) {}`; `fail_implicit_binding.carbon`: `fn Bad[T: HasGet](x: T) {}`; `fail_symbolic_arg.carbon`: `fn Caller[U: type](x: U) { CallGet(x); }`; `fail_require_in_interface_blanket.carbon`: `interface I { require impls HasGet; } impl forall [T: type] T as I {}` | First two: `TemplateConstraintOnNonTemplateBinding` at the binding. Third: `ConversionFailureTypeToFacet` + `StructuralRequirementNeedsConcreteType` + `DeductionGenericHere` (D-SC-6). Fourth: the existing `require`-not-satisfied diagnostic (`IdentifiedRequireImplsNotImplemented`, kind.def:463) plus the concrete-type note — pinning D-SC-8(iii) |
| check/testdata/named_constraint/template_constraint_dependent.carbon (new) | `dependent_caller.carbon`: `fn Outer[template U: type](x: U) -> i32 { return CallGet(x); } fn Test(c: C) -> i32 { return Outer(c); }`; `fail_dependent_caller_unsatisfied.carbon`: `Outer(d)` with `D` lacking `Get` | Positive: in `@Outer` a `call_action` (the call.carbon shape) and no facet value until the specific `Outer(C)` resolves — D-SC-3. Negative: `ResolvingSpecificHere` "unable to monomorphize specific `Outer(D)`" + the `ConversionFailureTypeToFacet` notes located at `CallGet(x)` (the member_access.carbon:43-49 shape) |
| check/testdata/named_constraint/template_constraint_compound_access.carbon (new) | `compound.carbon`: `fn F[template T: HasGet](x: T) -> i32 { return x.(HasGet.Get)(); }` + `Test(c: C)`; `fail_compound_unsatisfied.carbon` | Positive: in the specific, a `bound_method %x…, @C.%Get.decl`-shaped call (the type's OWN function, D-SC-4). Negative: the conversion diagnostics at the compound access |
| check/testdata/named_constraint/template_constraint_require.carbon (new) | `require_in_template.carbon`: `template constraint Both { fn Get(self) -> i32; require impls Core.Destroy; }` satisfied by a class; `require_in_interface_concrete.carbon`: `interface I { require impls HasGet; } impl C as I {}` with `C` having `Get` | Positive. `Both`'s facet value lists ONE witness (`Destroy`), structural check silent. `impl C as I` passes `CheckRequireDeclsSatisfied` |
| check/testdata/named_constraint/fail_template_constraint_impl_as.carbon (new) | `fail_impl_as.carbon`: `impl C as HasGet {}` | `ImplOfNotOneInterface` "impl as 0 interfaces, expected 1" (impl.cpp:1026-1029) — F-010m pinned (D-SC-8(ii)) |
| check/testdata/named_constraint/template_constraint_overload.carbon (new) | `overload.carbon`: `overload fn F[template T: HasGet](x: T) -> i32 { return 1; } overload fn F(x: i32) -> i32 { return 2; }` called with a `C` and with an `i32` (the OV-1 same-file set shape, fork/overload/plan.md §4.A) | Positive, no STDERR: the `i32` call skips member 1 silently (D-SC-12). Falsifier for a `diagnose` leak |
| check/testdata/named_constraint/template_constraint_import.carbon (new; multi-file) | `a.carbon`: `library "a"; template constraint HasGet { fn Get(self) -> i32; }`; `b.carbon`: `import library "a"; class C {…} fn CallGet[template T: HasGet](x: T)…; fn Test(c: C) …` | Positive; the imports block shows `%Main.HasGet = import_ref Main//a, HasGet, …` and the requirement as a loaded import-ref (D-SC-15). The import_constraint_decl.carbon shape (:12-60) |
| lower/testdata/template/template_constraint.carbon (new) | `call_method.carbon`: the §5.A conformance body minus `Core.Print` (returns `CallGet(s)`) | A `define i32 @…CallGet…(%C …)`-style specific calling `@C.Get` and a caller `define`; no `splice`-related fatal (§1.E) |

### §4.C Commit 3

| File | Splits | Prediction |
| --- | --- | --- |
| check/testdata/interop/cpp/class/import/template_constraint.carbon (new) | `method.h`: `struct Counter { int value; Counter(int v) : value(v) {} int Get() { return value; } int Twice(int n) { return 2 * n; } }` + `struct Overloaded { int Get(); int Get(int); }`; `satisfy.carbon`: `template constraint HasGet { fn Get(ref self) -> i32; }`, `fn CallGet[template T: HasGet](p: T*) -> i32 { return p->Get(); }`, `fn Test(c: Cpp.Counter*) -> i32 { return CallGet(c); }`; `fail_value_self.carbon`: the same constraint spelled `fn Get(self)` → mismatch (D-SC-11's spelling rule pinned); `fail_overloaded.carbon`: `Cpp.Overloaded*` → `StructuralMemberMismatch` (a `CppOverloadSetValue` is not a single function, D-SC-5(c)); `const_method.carbon` (`int Get() const` with `fn Get(ref self)`): PREDICTED positive, flagged (D-SC-5 break condition) | `satisfy`: `facet_value %Cpp.Counter, ()` in `Test`; the specific binds the imported `Get` through `ref self`. `fail_value_self`: `ConversionFailureTypeToFacet` + `StructuralMemberMismatch` + `StructuralRequirementHere` |

Diagnostic coverage: `TemplateConstraintOnNonTemplateBinding` (§4.B
checked_binding), `FunctionInNonTemplateConstraint` (§4.A invalid_members),
`NamedConstraintRedeclTemplateMismatch` (§4.A redecl), `StructuralMemberMissing`
/ `StructuralMemberMismatch` / `StructuralRequirementHere` (§4.B unsatisfied),
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
`runner.py --self-test` before commit):

```carbon
// CONFORMANCE-BULLET: Generics: Template-style structural conformance to nominal constraints
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// A `template constraint` (p000818; p002200 "Template constraints") is
// satisfied STRUCTURALLY: `StructuralOnly` declares no `impl` anywhere, its
// own member `Get` matches the requirement `fn Get(self) -> i32` modulo
// `Self := StructuralOnly`, so the call to the template-constrained
// `CallGet` is accepted (fork decision F-010 / SC-1, D-SC-5) and `x.Get()`
// dispatches to that member at instantiation. Binding spelling from
// generics/templates_type_param.carbon (`[template T: …]`); the value-`let`
// argument avoids a copy (no `Core.Copy` requirement is stated or needed).

import Core library "io";

template constraint HasGet {
  fn Get(self) -> i32;
}

class StructuralOnly {
  // Deliberately NO `impl as …`: the member alone satisfies the constraint.
  fn Get(self) -> i32 { return 42; }
}

fn CallGet[template T: HasGet](x: T) -> i32 {
  return x.Get();
}

fn Run() -> i32 {
  let s: StructuralOnly = {};
  Core.Print(CallGet(s));
  return 0;
}
```

Expected output hand-derived: `Get` returns 42, `Core.Print` prints `42\n`,
`Run` returns 0. The SKIP line is removed; no `.diff.cpp` (D-SC-14).

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
//
// The interop payoff of structural conformance (F-010 / SC-1, D-SC-11): a
// C++ class with no Carbon declarations at all satisfies a Carbon
// `template constraint` through its imported method. Imported C++ methods
// take `ref self` (check/cpp/import.cpp: PassingMode::ByRef default), so the
// requirement is spelled `fn Get(ref self) -> i32` and the template takes a
// pointer, calling through `->` on the dependent pointee. Construction shape
// from interop/cpp_type_import_class_enum.carbon (`Cpp.Vec2.Vec2(3, 4)`).

import Core library "io";
import Cpp inline '''
struct Counter {
  int value;
  Counter(int v) : value(v) {}
  int Get() { return value; }
};
''';

template constraint HasGet {
  fn Get(ref self) -> i32;
}

fn CallGet[template T: HasGet](p: T*) -> i32 {
  return p->Get();
}

fn Run() -> i32 {
  var c: Cpp.Counter = Cpp.Counter.Counter(7);
  Core.Print(CallGet(&c));
  return 0;
}
```

Expected output hand-derived: `value` is 7, printed once; exit 0.

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
-   **Goldens predicted byte-identical:** the three files whose dumps print
    named constraints
    (check/testdata/basics/raw_sem_ir/non_core_interfaces.carbon,
    …/one_file.carbon, check/testdata/facet/nested_facet_types.carbon) — the new
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
-   **Source files touched (19):** (1) parse/node_kind.def; (2)
    check/keyword_modifier_set.h; (3) sem_ir/named_constraint.h; (4)
    check/handle_named_constraint.cpp; (5) check/handle_function.cpp; (6)
    check/handle_let_and_var.cpp; (7) check/import_ref.cpp; (8)
    diagnostics/kind.def; (9) sem_ir/identified_facet_type.h; (10)
    sem_ir/identified_facet_type.cpp; (11) check/type_completion.cpp; (12)
    check/structural_conformance.h (new); (13) check/structural_conformance.cpp
    (new); (14) check/BUILD; (15) check/member_access.h; (16)
    check/member_access.cpp; (17) check/impl_lookup.cpp; (18)
    check/convert.cpp; (19) check/handle_binding_pattern.cpp. Plus docs (five
    files, D-SC-13), fork/ ledger and plan files. No contention with the
    W-007 files (cpp/export.cpp, cpp/thunk.cpp, cpp/type_mapping.cpp are
    untouched); SC-B3 remains W-007's last contender.
-   **Concurrent workstreams:** UA-2 (reconciliation) touches fork/ ledger
    files, gap-analysis.md:52/:150 and the templates_dependent_member
    program; this plan's §8.5 edits are to row 55, the header, W-027/028/029
    and new residues — disjoint cells, rebase-mechanical. Re-quote absolutes
    at rebase (R9).

## §7 Risks and rejected alternatives (each with its falsifier)

-   **R-1 — the dependent method call does not lower (the riskiest
    dependence).** The conformance program needs `x.Get()` on a template binding
    to execute. Evidence for: lower/testdata/template/merging.carbon :20/:49/:58
    lower `T.F()`, `({} as T).F()` and `x.(B.F)()`; the `SpliceInst` fatal is
    cross-file only (:508). Evidence against: no upstream lower golden has
    exactly `x.F()` (instance method through an `access_member_action` on a
    value `x: T`); the fork's templates_dependent_member probe (`x.n`, a field)
    is unverified until UA-2 runs. Falsifier: the §4.B lower golden fails to
    fill (stack dump in the autoupdate log) or the SC-1b conformance run is
    COMPILE-FAIL/RUN-FAIL on structural_conformance.carbon. Contingency: the
    lower golden is kept as `fail_todo_` only if the defect is upstream's and
    not fixable in one round; the conformance program keeps SKIP with the
    measured diagnostic (allowed: it is SKIP today) and W-014 gains the finding;
    D-SC-14's pointer shape (`p: T*`, `p->Get()`) is tried FIRST since
    merging.carbon :58 proves a call through a dependent reference-like base.
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
    `RequireCompleteType` needs a Context note; this plan adds none as a
    KIND (it reuses the builder's Context mechanism with an inline
    `CARBON_DIAGNOSTIC` of Context severity, which IS a kind —
    `StructuralRequirementIncompleteType`, the eighth kind if a reviewer
    prefers it to be counted). Falsifier: check_diagnostics.py or
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
    the diff is a stop.
2.  **Gate:** mode `gate` green (prek + `bazel test //toolchain/...`;
    clang-format 21.1.8 per R18; `uvx prek run --files <changed>` locally
    before every push, R25). The diagnostics coverage test (7 or 8 new
    kinds, §4 coverage list, R-6), check_diagnostics.py (one
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
        items 1-9 and D-SC-1..18 by name, and "the chokepoint is
        convert.cpp:1955 (was :1596)".
    -   W-028, W-029 → `blocked_by` loses W-027 (W-029 keeps W-021/W-007
        edges as they stand).
    -   New residue items by TITLE (§1.G); ids allocated at discharge by
        `grep -oE '"id": ?"W-[0-9]+"' fork/inventory/work-items.json | sort
        -t- -k2 -n | tail -1` on trunk then (W-125 is the highest today —
        never assume numbers).
    -   gap-analysis row 55 → PARTIAL with the text "`template constraint`
        member requirements landed (SC-1, F-010 B1): a `template T: HasGet`
        binding is satisfied by a type's own matching members, no `impl`;
        remaining: `require` validity blocks and boolean predicates (SC-B2,
        W-028), concept mapping (SC-B3, W-029)"; header 30/21/4/1 →
        30/22/3/1 (D-SC-17); the W7 paragraph (:187-203) gains "structural
        conformance (B1) landed; see fork/structural/plan.md".
    -   decision-log: an F-010 landing note "(SC-1 landing note,
        <date>)" after :1363 listing D-SC-1..18 one line each, the §0.2
        corrections, and the two review folds.
6.  **Docs (D-SC-13):** the ported page + the four sibling hunks, re-read
    against trunk; `prek` (rumdl, google-doc-style) clean; heading and list
    counts recorded before/after per R31(b).
7.  **ORCHESTRATION stamp** per landing (status paragraph, the floor, the PR
    count, the dispatch list if goldens are parked under R28(c)).

## Hand-off notes for the implementer

-   Read §0.1 rows 5, 7, 9, 10, 15, 17 and 19 before touching code; they are
    the seven facts the design record got wrong or did not know.
-   Commit 1 first, hosted `compile` probe second, goldens third. The only
    exhaustive-switch exposure is `Print`/`MergeDefinition` on
    `NamedConstraint` (R-10); run `check_one_sc.sh` on every touched file.
-   `is_template` must be set BEFORE `TryMergeRedecl` reads it for the
    mismatch check, and the Self binding's `is_template` must come from the
    stored entity (a redeclaration can be the definition).
-   Collect `structural_members_id` from `body_block_with_self_id` at `}`;
    do not add a stack. Filter to `FunctionDecl` insts whose function's
    `parent_scope_id` is `scope_with_self_id` (a nested entity's decl could
    otherwise sneak in).
-   In `CheckStructuralRequirements`, canonicalize the self with
    `GetCanonicalQuerySelfForLookupImplWitness` (impl_lookup.h:68) before
    anything else, exactly as the interface loop does, and read
    `FacetValue`s through `GetCanonicalFacet` for D-SC-6.
-   The member lookup MUST go through the member-access path (D-SC-5(b));
    `LookupNameInExactScope` will not resolve p002200's alias and will not
    import C++ members.
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
    bullet cell must match fork/gap-analysis.md:55 byte for byte (R7). Try
    the `let s` value shape first; R-1 names the pointer fallback.
-   Docs: port, do not re-author (D-OV-8 precedent); take only the
    details.md:1068-1077 hunk from the stranded diff; re-run prek and the
    R31 count diff.
-   Keep every PR/issue number in prose as "PR 7727" / "issue 2153" and
    never end a sentence with a bare number (R31).

## Sign-off

_(left for the two adversarial plan reviews: rev A — design fidelity against
p000818, p002200, F-010 and the stranded page; rev B — toolchain reality
against the cited lines at 8068151ed. Folds are applied in place, each marked
"(amended <date>, review fold: rev A An / rev B Bn)", and tabled in a Review
fold record above this section.)_
