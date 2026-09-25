<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-077 plan: struct patterns in match case position

**Status:** DRAFT FOR ADVERSARIAL REVIEW, 2026-09-25. Branch
`claude/carbon-fork-0-1-w077` off trunk c8467e1 (post-PR #38: W-078b
landed; conformance 101 PASS / 0 FAIL / 28 SKIP over 129 per
fork/conformance/out/scoreboard.json totals). All line numbers in this
plan are against trunk c8467e1.

**Item:** W-077 (fork/inventory/work-items.json): struct patterns are
DESIGNED (docs/design/pattern_matching.md:413-468) and PARSE
(toolchain/parse/testdata/struct/struct_pattern.carbon — 12 positive
subfiles covering designated fields, shorthand, `ref`/`var` shorthand,
mixed, nesting, and the trailing `_` discard, plus 24 fail subfiles),
but check-side every struct-pattern parse node is upstream-TODO:
`HandleParseNode(StructPatternStartId)` is
``context.TODO(node_id, "struct pattern start")`` at
toolchain/check/handle_pattern_list.cpp:38-41, `StructPatternId` is
``context.TODO(node_id, "struct pattern")`` at :137-139, and
`StructPatternDesignatedFieldId` is
``context.TODO(node_id, "struct pattern field")`` at :141-144 — all
three verified at c8467e1. This slice builds the struct-pattern check
layer for `match` `case` position — pattern inst, name-keyed field walk
in both engine passes, usefulness/exhaustiveness integration — on the
landed tuple-machinery shape (W8a/W8b, W-066, W-076, W-078a/b).

Two ledger corrections this plan rests on (each verified in-tree, to be
recorded at discharge):

-   **The ledger's "not a match-arm slice" premise is wrong.** The
    W-077 notes say taking struct patterns on "means building the whole
    struct-pattern check layer ... not a match-arm slice". In fact the
    pattern-list handlers CAN distinguish context:
    `FullPatternStack::Kind` (toolchain/check/full_pattern_stack.h:41-66)
    has a dedicated `MatchCaseArm` kind, pushed at
    handle_match.cpp:333 (`PushMatchCaseArm`, full_pattern_stack.h:104-110)
    and queryable by way of `CurrentKind()` (:71-72). Keeping the
    `struct pattern start` TODO for every non-match kind at the same
    site with the same string makes the match-only slice clean (§1.1).
-   **The `:138`/`:143` TODOs are unreachable dead gates.** Check
    processes parse nodes in postorder, and `StructPatternStart` — the
    bracketing leaf — precedes every field node and the closing
    `StructPattern` node (see any tree dump in
    parse/testdata/struct/struct_pattern.carbon, for example :300-309).
    `Context::TODO` returns false, which aborts checking of the file,
    so the `struct pattern` and `struct pattern field` TODOs behind it
    never fire. Consistent with this, the three TODO strings appear
    NOWHERE in check/lower testdata (grep over toolchain/ and fork/
    finds only the code sites and this plan) — the ledger's "no
    check-side golden pinning those TODO strings" line is confirmed.

## §1 Design decisions

1.  **SLICE: match case position only; every other context keeps the
    upstream TODO, same site, same string.**
    `HandleParseNode(StructPatternStartId)` becomes: if
    `full_pattern_stack()` is empty or `CurrentKind() !=
    Kind::MatchCaseArm`, keep ``context.TODO(node_id, "struct pattern
    start")`` verbatim; otherwise run the real pattern-list start (the
    `TuplePatternStartId` body, handle_pattern_list.cpp:30-36). Because
    the non-match TODO still aborts at the START node, the real
    `StructPattern`/`StructPatternDesignatedField` handlers stay
    unreachable in let/var/param/class-field contexts — so replacing
    the two dead TODOs at :137-144 with real handlers changes nothing
    outside match arms. Rationale for the narrow slice:
    -   The fork's precedent is one workstream = one PR, and the
        ledger's own bullet ("Control flow: matching — good switch
        equivalents") is match-scoped.
    -   The `let`/`var` lane is a genuinely different second half: it
        needs the irrefutable `LocalState` walk (whole-aggregate
        conversion or a let-side field walk), storage typing for
        subset+`_` patterns, and `FieldWithTuplePattern`-style class
        `var` handling — none of which the match lane touches (§1.4
        shows why the match lane CANNOT go through conversions, which
        is also why the two lanes share little beyond the pattern
        inst).
    -   Nested-context correctness is free: a struct pattern inside a
        `let` inside a match arm's body sees `CurrentKind() ==
        NameBindingDecl` (the innermost full-pattern) and stays TODO; a
        struct pattern nested anywhere inside a case pattern —
        including under a guarded arm, whose pattern checks before the
        guard — sees `MatchCaseArm`.
    -   The residue is recorded, not hidden: §4 adds the first-ever
        check-side pins of the surviving `struct pattern start` TODO in
        `let` and `var` position (closing the upstream golden gap the
        ledger recorded), and §8 files the let/var/param lane as a new
        work item.

    Break condition: reviewers rejecting the gate spelling
    (`CurrentKind()` at the start node) — the fallback is gating inside
    the `StructPattern` end handler instead, which costs the ability to
    keep the exact `struct pattern start` string for non-match
    contexts; the slice itself stands either way.

2.  **New pattern inst `SemIR::StructPattern`, shaped on
    `SemIR::TuplePattern` (typed_insts.h:2117-2131), with the field
    names carried by the pattern's own type.**

    ```cpp
    // A struct pattern, such as `{.a = 1, b: i32, _}`.
    struct StructPattern {
      static constexpr auto Kind =
          InstKind::StructPattern.Define<Parse::StructPatternId>(
              {.ir_name = "struct_pattern",
               .expr_category = ExprCategory::Pattern,
               .constant_kind = InstConstantKind::Always,
               .is_lowered = false});

      // Always a PatternType whose scrutinee type is a struct type
      // pairing each named field with its subpattern's scrutinee type,
      // in pattern (lexical) order.
      TypeId type_id;
      InstBlockId elements_id;
      // Whether the pattern ends with the `_` field discard
      // (pattern_matching.md:458-468). BoolValue is the precedented
      // enum-typed inst arg (BoolLiteral, typed_insts.h:300).
      BoolValue has_trailing_discard;
    };
    ```

    The pattern's field NAMES ride in `type_id`: the handler builds a
    `StructTypeField` list (sem_ir/struct_type_field.h:14-25) pairing
    each field's name with `ExtractScrutineeType` of its element's
    type — the exact protocol the tuple handler uses for element types
    (handle_pattern_list.cpp:122-126) — then
    `GetPatternType(GetStructType(...))`. Consumers recover
    name-to-element alignment by unwrapping the pattern type
    (`ExtractScrutineeType(pattern.type_id)` → `StructType` → fields,
    index-aligned with `elements_id`). No second block store, no new id
    space. `constant_kind = Always` needs no eval_inst case (structural
    constants, same as TuplePattern); `is_lowered = false` needs no
    lower support. Registration: inst_kind.def, alphabetically after
    `StructLiteral` (:153). Rejected: a separate names block (redundant
    with the type); two inst kinds for the `_`/no-`_` split (doubles
    every switch); a sentinel element for `_` (breaks block walkers).

3.  **Field-subset semantics, adjudicated from
    pattern_matching.md:435-444 with one diagnostic each:**
    -   _Unknown field_ — "every field name in the pattern must be a
        field name in the scrutinee" (:435-436): new
        `MatchCaseStructPatternUnknownField` (Error), emitted by the
        field walk (§2.3).
    -   _Unmentioned scrutinee fields_ — discarded "if the pattern has
        a trailing `_` ... or diagnosed as an error if it does not"
        (:440-444): new `MatchCaseStructPatternMissingFields` (Error),
        naming the missing fields (a struct's field set is finite and
        nameable, unlike the integers `MatchNonexhaustiveNoIrrefutableArm`
        declines to enumerate).
    -   _Trailing `_` with all fields named_ — "valid even if all
        fields are actually named" (:468): silent; positive pin (§4).
    -   _Duplicate field name in the pattern_ — not stated for
        patterns, adjudicated as an error by parity with struct
        literals (`StructNameDuplicate`, handle_struct.cpp:81-105): a
        duplicate either dead-constrains one scrutinee field twice or
        double-binds; new `StructPatternNameDuplicate` (Error) +
        `StructPatternNamePrevious` (Note), diagnosed where the pattern
        inst is built (§2.2), so it is context-independent by
        construction.
    -   _Reorder_ — each field-pattern matches "the same-named element"
        (:437-440): the walk looks pattern names up in the SCRUTINEE's
        `StructType` field table, name-keyed, order-free (§2.3). The
        design's own reorder example (:427-432, `case {.b = 2, .a =
        1}`) is a §4 positive.
    -   _Sub-match emission order_ — pattern (lexical) order, each
        against its named scrutinee field. The flat-`and` fold and its
        recorded observational-equivalence premise (in-slice element
        reads total, case expressions constant —
        pattern_match.cpp:889-897, W-008 plan §2.1(a)) carry over
        unchanged: `StructAccess` on an in-slice scrutinee is total.
    -   _Shorthand_ — `a: T` ≡ `.a = a: T`, likewise `ref`/`var`
        (:446-456): parse already normalizes nothing — shorthand fields
        arrive as bare binding patterns (typed_nodes.h:1553-1556) — so
        the check handler derives the field name from the binding
        (§2.2); no semantic difference downstream, which IS the design
        equivalence.

4.  **Struct arms take the scrutinee-typed field walk in BOTH passes;
    the whole-aggregate conversion path is structurally unusable.** The
    tuple precedent already walks the scrutinee's own type in the match
    lane (`DoMatchCaseTuplePreWork`, pattern_match.cpp:1643-1738,
    rationale at :284-297). For structs this is not just parallel, it
    is forced: a subset pattern's scrutinee-type (`{.a: i32}`) has
    FEWER fields than the scrutinee (`{.a: i32, .b: i32}`), and
    `ConvertStructToStructOrClass` (convert.cpp:618-701) diagnoses any
    source field absent from the destination
    (`StructInitUnexpectedFieldInConversion`, :671-677) — so
    converting the scrutinee to the pattern's type can never implement
    the design's discard rule. Consequences, each specced in §2:
    -   Both passes route through a new `DoMatchCaseStructPreWork`
        (test pass prunes irrefutable fields, bind pass prunes
        binding-free fields), mirroring the tuple walk's shape checks,
        eager per-field `StructAccess` emission, and
        emission-disjointness argument (pattern_match.cpp:1666-1695).
    -   The bind dispatch never uses plain `LocalPatternMatch` for a
        struct root: `EmitCaseArmTestAndBind`'s new struct branch
        always calls `MatchCaseBindPatternMatch` (§2.4). The tuple
        root's `LocalPatternMatch` fast path (handle_match.cpp:
        1041-1043) is additionally rerouted when the tuple CONTAINS a
        struct subpattern, because that path converts the scrutinee to
        the PATTERN's type (pattern_match.cpp:1616-1619) — the same
        impossible conversion.
    -   `ConvertStructToStructOrClass`'s name-keyed source-field map
        (convert.cpp:658-686) is the reorder PRECEDENT (name-keyed
        `Map<NameId, int32_t>` lookup), not reused code.
5.  **`var` wrapping a subtree that contains a struct pattern is gated
    out (W4 slice-gate TODO); field-level `var`/`ref` bindings are
    in-slice.** The match-bind `var` path initializes on-demand storage
    of the `var` subtree's own scrutinee-type by `Convert ...
    Initializing` (pattern_match.cpp:1475-1510); for a subset struct
    subtree that storage type drops fields and the conversion diagnoses
    the misleading `StructInitUnexpectedFieldInConversion` (§1.4). Gate
    site: the `MatchCaseState` branch of `DoPreWork(VarPattern)`
    (pattern_match.cpp:1404-1430), which already diagnoses refutable
    `var` subtrees with the W4 string (:1412-1417) — a
    contains-struct-pattern test reuses that exact TODO string and
    location. Field-level `.a = var n: i32` and `.a = ref r: i32` ride
    the landed leaf machinery (tuple parity: `(var n: i32, 1)` and the
    W8b `ref` lane) — the `var` storage there is the FIELD's scalar
    type, no aggregate conversion. Break condition: a reviewer wanting
    full-field-set `var {a: i32, b: i32}` admitted (the conversion
    would succeed by way of reorder) — that is a widening, not a soundness
    fix; the uniform gate is smaller and the shape is pinned (§4).
6.  **Usefulness: a `Struct` key node kind, NORMALIZED to the
    scrutinee's full field set with `Wildcard` fills.** The W-066
    machinery is slot-wise over structurally identical keys
    (`UsefulnessKeySubsumes`, handle_match.cpp:627-677;
    `SkipUsefulnessKeySubtree` :605-612) and assumes fixed arity per
    position — field-subset patterns break that raw: `{.a = 1, _}`
    names one field, `{.a = 1, .b = 2}` names two, and name-order is
    free. Normalization restores the fixed-arity invariant:
    -   New `UsefulnessKeyNode::Kind::Struct` (context.h:335-371) with
        `arity` = the SCRUTINEE struct type's field count. Children
        follow in preorder, one per scrutinee field, in the SCRUTINEE's
        canonical field order: the keyed subpattern where the pattern
        names the field, a synthetic `Wildcard` where it does not.
    -   The trailing `_` never enters the key: `{.a = 1, _}` and
        `{.a = 1, .b = 2, _}` on a two-field scrutinee key as
        `Struct[IntConst 1, Wildcard]` and `Struct[IntConst 1,
        IntConst 2]` respectively — comparison is by matched VALUE SET,
        never source form, the standing W-066 principle
        (context.h:343-353).
    -   **Soundness.** Fix the statement's one scrutinee struct type S
        with fields f1..fn in S's canonical order (struct types are
        canonicalized by field sequence, so both arms see the same
        order; the walk unqualifies first, so `const` riders cannot
        split it). For a shape-valid struct pattern P (key building
        runs only when the arm's condition is not errored,
        handle_match.cpp:843-846, and every §1.3 shape error errors the
        condition, §2.3), position i of the normalized key denotes
        exactly the set of fi-values P admits: P omits fi ⟹ fi is
        unconstrained (the design's discard rule, :440-444) ⟹
        `Wildcard`; P's subpattern at fi is irrefutable ⟹ `Wildcard`
        (the existing first-check, pattern_match.cpp:761-768); else the
        subtree's key, by induction. A struct value matches P iff every
        field matches its position (:444, "matches if all of these
        sub-matches succeed"), so the key denotes P's exact match set
        as a product, and slot-wise subsumption over identical shapes
        is pointwise set-inclusion over a product — sound and complete
        for the in-slice node kinds, the same argument the landed tuple
        lane rests on, with the normalization restoring the
        identical-shape premise that subsets removed. Consequences
        pinned in §4: `{.a = 1, _}` prior kills `{.a = 1, .b = 2}`;
        `{.a = 1, .b = 2}` prior does NOT kill `{.a = 1, _}`;
        `{.b = 2, .a = 1}` prior kills `{.a = 1, .b = 2}` (reorder);
        an all-binding struct arm — full-set or subset+`_` — keys as
        the single `{Wildcard}` by way of the irrefutability first-check,
        never as a `Struct` node.
    -   **Scrutinee-type threading.** Normalization needs the scrutinee
        field set, so `BuildMatchCaseUsefulnessKey`
        (pattern_match.cpp:718-823) gains a `scrutinee_type_id`
        parameter (the one call site, handle_match.cpp:846, has
        `scrutinee_id` in hand) and the worklist carries per-position
        scrutinee types: tuple nodes push their elements' types from
        the scrutinee `TupleType`; struct nodes consume theirs;
        alternative payload slots push `TypeId::None` with a defensive
        nullopt in the `Struct` case — sound because no in-slice choice
        payload element can be struct-typed (§1.8). Any missing/
        mismatched type nullopts the key (record-nothing,
        diagnose-nothing), preserving the builder's soft-path contract
        (:816-820).
    -   `UsefulnessKeySubsumes` gains a `Kind::Struct` case identical
        in shape to `Kind::Tuple` (:663-668): kinds and arity equal,
        else defensive not-subsumed.
7.  **Exhaustiveness and dead-`default` need ZERO diagnostic-function
    changes: struct scrutinees take the open-domain lane the W-078b
    machinery already generalizes over.** Verified branch by branch:
    -   `DiagnoseNonexhaustiveMatch` (handle_match.cpp:1457-1563): a
        struct type is neither `BoolType` nor a matchable choice, so it
        takes the :1474-1483 branch — `MatchNonexhaustiveNoIrrefutableArm`
        naming the unqualified scrutinee type (renders `{.a: i32, .b:
        i32}` by way of the existing `SemIR::TypeId` parameter). The
        `has_irrefutable_arm` early return (:1460-1462) discharges an
        all-binding struct arm once §2.4 records it.
    -   `DiagnoseDeadDefault` (:1252-1325): stage 1 runs on every lane
        and fires when a prior struct arm keyed `{Wildcard}`; stage 2
        stays gated to bool/choice (:1310-1311) — correct for structs,
        whose root domain is OPEN under the landed W-076 root-only
        record exactly as tuples' is: a struct-of-bools' four values
        can no more be union-covered than `(bool, bool)`'s
        (bool_tuple_scrutinee.carbon's bool_pair_keeps_default is the
        standing pin; the struct twin is pinned in §4). The
        brief's worry that the open-domain lane might be "wrong for
        structs-of-bools" resolves the same way W-078b §1.2/R-6
        recorded it for tuples: root-only, residue not defect.
    -   The `has_irrefutable_arm` ⟺ `{Wildcard}`-in-`useful_arms`
        agreement invariant (:1238-1250) EXTENDS rather than breaks:
        §2.4 adds `is_irrefutable_struct_arm` to the flag's recording
        (handle_match.cpp:939-941) and §1.6 keys the same arms
        `{Wildcard}` — both sides move together; the invariant comment
        gains the struct root so a future splitter sees it.
    -   `IsSupportedScrutineeType` (:179-221) gains a struct branch
        mirroring the tuple branch (:210-218): unqualified `StructType`
        → push every field's type; the trivial-destructibility
        argument extends fieldwise exactly as it extends elementwise
        (:255-263). Adapter classes over struct types stay behind the
        scrutinee TODO, matching the int/bool strictness (:198-205).
8.  **Choice payloads cannot contain struct positions in-slice — no
    payload-lane work.** `IsInSliceChoicePayloadType`
    (toolchain/check/type.cpp:313-320) admits only int/float/bool/
    pointer payload types; anything else is rejected at choice
    completion (handle_choice.cpp:758-763), so no in-slice choice
    scrutinee has a struct-typed payload element for a struct
    subpattern to match. A struct SUBPATTERN written against a
    non-struct payload element (`case .Some({x: i32})` on `Some(i32)`)
    reaches the struct walk with a non-struct element scrutinee and
    takes the same W4 slice-gate TODO as the tuple twin
    (pattern_match.cpp:1666-1695); §4 pins it. Where a struct root
    lands today: never in handle_match at all — a struct SCRUTINEE
    aborts first at MatchCondition's gate (`match on unsupported
    scrutinee type`, handle_match.cpp:290-292, which precedes every
    case arm), and a struct PATTERN on a supported scrutinee aborts at
    handle_pattern_list.cpp:40. Neither abort is pinned by any golden
    today (§6 grep record).
9.  **R9 admission: expression leaves inside struct patterns hit the
    landed gate verbatim, no widening.** Field expression leaves
    (`case {.a = 1, _}`, and the design's struct-literal-as-pattern
    example :427-432) are `ExprPattern` insts — parse wraps a
    designated field's expression initializer the same way tuple
    elements wrap (EndExprRegionForPattern, pattern.cpp:70-105) — so
    each leaf flows through `DoMatchCaseExprPattern` against its
    field's scrutinee: concrete `IntValue`/`BoolLiteral` constants are
    admitted and compared with `==` in the design-mandated operand
    order (pattern_match.cpp:1284-1339); everything else stays behind
    the exact W-076-widened string ``match case expression pattern
    that is not a constant integer or `bool` `` (:1303-1312). A named
    STRUCT constant as a leaf (`case S_CONST`) is a concrete constant
    whose inst is `StructValue`, not `IntValue`/`BoolLiteral` — it
    stays behind that same gate (the design's whole-value `==` lane is
    out of slice), pinned in §4. Error-leaf recovery scopes unchanged:
    the walk's root is now possibly a `StructPattern`, and the
    root-vs-leaf test (:1273-1283) compares inst ids, not kinds, so a
    NameNotFound field leaf recovers into an errored condition exactly
    as tuple leaves do.
10. **Lowering: zero toolchain/lower/ changes.** The check layer
    desugars a struct arm to `StructAccess` insts (already lowered:
    lower/handle_aggregates.cpp:66, lower/file_context.cpp:955), the
    landed `==`/`ConvertToBoolValue` comparisons, and the landed
    dispatch CFG; `StructPattern` itself is `is_lowered = false`
    metadata like `TuplePattern`. The §4 lower golden pins the IR the
    same way lower/testdata/match/tuple_pattern.carbon pins the tuple
    lane's.

## §2 Implementation spec

1.  **sem_ir:** `StructPattern` in inst_kind.def (after
    `StructLiteral`, :153) and typed_insts.h (§1.2 spelling, placed by
    the file's struct-inst grouping near :2050). Extend
    `GetFirstBindingNameFromPatternId` (sem_ir/pattern.cpp:57-76) to
    walk `StructPattern` elements — discharging upstream's own marker
    comment "TODO: Look through struct patterns." at :68 — so
    shorthand-name derivation (§2.2) and any existing caller see
    through struct nodes. No eval, no lower, no import_ref: match-arm
    pattern insts live in function bodies and are never exported (the
    import_ref TuplePattern support at import_ref.cpp:4317-4324 exists
    for signature patterns, which the §1.1 gate keeps struct-free);
    `ClangDeclSignature::TuplePattern` (clang_decl.h) is an unrelated
    C++-interop enum — untouched. node_stack.h needs nothing:
    `NodeKind::StructPattern` resolves to an `InstId` entry through
    the category default (node_stack.h:552-555), exactly as
    `NodeKind::TuplePattern` does; `StructPatternStart` and
    `StructPatternDesignatedField` stay in the solo-`None` bucket
    (:487-488) — the field handler re-pushes elements under their own
    node ids and never pushes itself (§2.2).
2.  **handle_pattern_list.cpp — the three handlers:**
    -   `StructPatternStartId` (:38-41): the §1.1 gate; in-slice, run
        the `TuplePatternStartId` body (:30-36:
        `EndEmptyExprRegionForPattern` + `HandlePatternListStart`) and
        push a frame on a new `struct_pattern_names_stack()` — an
        `ArrayStack` of `{int32_t ordinal; SemIR::NameId name_id}` in
        `Context` (precedent: `struct_type_fields_stack()`), one frame
        per open struct pattern so nesting is free.
    -   `StructPatternDesignatedFieldId` (:141-144): the node stack
        holds `[.., NameId, element]` — the designator's name was left
        by the shared `StructFieldDesignatorId` handler
        (handle_struct.cpp:33-38), and `element` is the field's checked
        subpattern inst or its still-unwrapped expression (an
        expression initializer is wrapped into an `ExprPattern` later,
        at the comma/end region close — pattern.cpp:70-105). Pop
        `element` with its node id, pop the name, append
        `{ordinal, name}` to the open names frame — ordinal is
        `param_and_arg_refs_stack().PeekCurrentBlockContents().size()`
        (the completed-element count of this frame,
        param_and_arg_refs_stack.h:67-69) — and re-push `element`
        under its ORIGINAL node id, so the shared comma/end machinery
        (`PatternListCommaId` :146-152, region close, `ApplyComma`'s
        top-of-stack pop, param_and_arg_refs_stack.h:32-36) sees
        exactly the stack it would have seen with no designator.
    -   `StructPatternId` (:137-139): four steps, mirroring
        `TuplePatternId` (:95-135) plus the struct-specific work:
        1.  `_` discard: if the node stack top is an `UnderscoreName`
            entry (its handler pushes `NameId::Underscore`,
            handle_binding_pattern.cpp:32-36), pop-and-discard it and
            set `has_trailing_discard`. Parse guarantees `_` is last
            and comma-preceded (grammar :417-418; parse fail pins
            :163-177), so after popping it the top is
            `StructPatternStart` and the pending region is the empty
            one the comma opened — `EndEmptyExprRegionForPattern`.
            Without `_`, run the tuple handler's two-way region close
            verbatim (:96-103).
        2.  `refs_id = param_and_arg_refs_stack().EndAndPop(
            StructPatternStart)`; pop the solo start node.
        3.  Names: for element i of the refs block, take the recorded
            designated name for ordinal i if present, else derive the
            shorthand field name from the element's binding
            (`GetFirstBindingNameFromPatternId` + its `EntityName` —
            parse guarantees shorthand fields are named bindings,
            AnonymousBindingInStructPattern pins :281-297). Diagnose
            duplicates with `StructPatternNameDuplicate` /
            `StructPatternNamePrevious` (§1.3), pushing
            `ErrorInst::InstId` on a duplicate, mirroring the struct
            literal's error path (handle_struct.cpp:139-141).
        4.  Type and inst: build the `StructTypeField` list
            `{name, ExtractScrutineeType(element type)}` in element
            order, `GetPatternType(GetStructType(...))`, then
            `AddInst<SemIR::StructPattern>` and push;
            `BeginExprRegionForPattern` to restore the pending-region
            invariant (:131-134). No `InNonStaticFieldDecl` check: the
            §1.1 gate makes class-field position unreachable (that
            context's kind is `ClassScopeVarDecl`), recorded in a
            comment where the tuple handler checks it (:113-120).
3.  **pattern_match.cpp — the walk:**
    -   `Dispatch` (:1876-1981): add the `StructPattern` PreWork case;
        no PostWork case is registered because none is ever scheduled
        in-slice (the match walks never need a struct RESULT value —
        same reason the tuple match lane never schedules its PostWork).
    -   `DoPreWork(State, SemIR::StructPattern, ...)`: `MatchCaseState`
        → `DoMatchCaseStructPreWork(..., is_test_pass=true)`;
        `LocalState` with `in_match_case_bind` →
        `DoMatchCaseStructPreWork(..., is_test_pass=false)`; every
        other state `CARBON_FATAL` — unreachable by the §1.1 gate plus
        the §2.4 routing, and a fatal keeps a future gate-lifter honest
        (contrast the reachable-by-design TODO the expression-pattern
        LocalState keeps at :1191).
    -   `DoMatchCaseStructPreWork(struct_pattern, scrutinee_id, entry,
        is_test_pass)`, mirroring `DoMatchCaseTuplePreWork`
        (:1643-1738) stage for stage: error-typed pattern or scrutinee
        → errored result (:1652-1663); unqualified scrutinee type not
        a `StructType` → the W4 slice-gate TODO with the tuple twin's
        pass-split locations and the same emission-disjointness
        argument (:1666-1695); then the struct-specific shape checks,
        emitted by whichever pass reaches them (same disjointness):
        -   Build the name-keyed scrutinee field map
            (`Map<NameId, int32_t>`, the convert.cpp:658-686 shape).
            For each pattern field (names from the pattern's type,
            §1.2): missing from the map →
            `MatchCaseStructPatternUnknownField` at the element's inst,
            errored result, return.
        -   Scrutinee fields absent from the pattern and no
            `has_trailing_discard` →
            `MatchCaseStructPatternMissingFields` at
            `entry.pattern_id` (the arity-mismatch location precedent,
            :1705), listing the missing names in scrutinee order,
            errored result, return.
        -   Then per pattern field in pattern order: prune —
            test pass prunes irrefutable subtrees, bind pass prunes
            binding-free subtrees (:1716-1721) — else emit
            `AddInst<SemIR::StructAccess>` with the SCRUTINEE field's
            type and index (the `TupleAccess` twin, :1723-1730) and
            queue the sub-work in reverse for left-to-right processing
            (:1732-1737).
    -   Recursion extensions, one `StructPattern` arm each, shaped on
        the existing tuple arms: `IsIrrefutableMatchCasePattern`
        (:665-691), `MatchCasePatternHasBindings` (:825-847),
        `MatchCasePatternHasVarPattern` (:849-864), plus a new static
        `MatchCasePatternHasStructPattern` (the §1.5/§2.4 routing
        predicate, same worklist shape).
    -   `DoPreWork(VarPattern)` `MatchCaseState` branch (:1404-1430):
        after the irrefutability test, a
        `MatchCasePatternHasStructPattern(subtree)` hit diagnoses the
        W4 TODO at the introducer (:1412-1417's exact spelling and
        location) — §1.5.
    -   `BuildMatchCaseUsefulnessKey` (:718-823): the §1.6 signature
        and worklist change (typed positions), the `Struct` node
        emission with `Wildcard` fills (a `{InstId::None, type}`
        worklist entry emits a synthetic `Wildcard`, keeping preorder),
        and tuple positions pushing element types from the scrutinee
        `TupleType`. The irrefutability first-check (:761-768) stays
        FIRST, so all-binding struct subtrees key `Wildcard` before
        any `Struct` node is considered.
4.  **handle_match.cpp:**
    -   `IsSupportedScrutineeType` (:179-221): the §1.7 struct branch.
    -   `EmitCaseArmTestAndBind` classification (:775-816): add
        `is_struct_arm` (`StructPattern` root AND unqualified
        struct-typed scrutinee — the `is_tuple_arm` twin, :785-788)
        and `is_irrefutable_struct_arm`; `is_struct_arm` joins the
        engine-routing disjunction (:799-801), so every struct root
        against a struct scrutinee — refutable or not — runs the
        engine and gets the shape checks; a struct root against a
        NON-struct scrutinee falls to the final `else` W4 TODO
        (:811-816), the tuple root's exact precedent.
    -   Coverage recording (:932-956): `is_irrefutable_struct_arm`
        joins the `has_irrefutable_arm` disjunction (:939-941) — the
        §1.7 invariant's flag side.
    -   Bind dispatch (:988-1048): a new struct branch — `is_struct_arm
        && cond != ErrorInst && MatchCasePatternHasBindings` →
        `MatchCaseBindPatternMatch` + `DeferCleanups` (never plain
        `LocalPatternMatch`, §1.4) — and the tuple branch's fast-path
        condition (:1041-1043) additionally requires
        `!MatchCasePatternHasStructPattern`, so a tuple root with a
        struct element takes the match-bind walk. The alternative-
        payload branch (:1027-1032) needs no change: §1.8 makes struct
        payload subtrees unreachable, and the reused walk would route
        them correctly anyway.
    -   `UsefulnessKeySubsumes` (:627-677): the `Kind::Struct` case
        (§1.6). `UsefulnessKeyNode` (context.h:335-371): the `Struct`
        kind, documented with the normalization contract; the
        `Wildcard` doc comment (:337-342) gains all-binding struct
        subtrees.
    -   Comment sweep (behavioral honesty, no logic): the file header's
        scrutinee-shape and exhaustiveness paragraphs
        (handle_match.cpp:47-77, :109-124 — "integer or tuple" becomes
        "integer, tuple, or struct" where the open-domain lane is
        meant), `MatchCondition`'s shape comment (:236-263),
        `EmitCaseArmTestAndBind`'s classification and recording
        comments (:755-774, :913-931), `DiagnoseDeadDefault`'s
        invariant paragraph (:1238-1250), `DiagnoseNonexhaustiveMatch`'s
        doc and branch comments (:1441-1456, :1467-1473),
        `MatchStatement`'s exhaustiveness comment (:1582-1593), and
        pattern_match.cpp's match-lane comments where they enumerate
        tuple-only shapes (:106-111, :284-297).
5.  **Diagnostics (toolchain/diagnostics/kind.def + definition sites),
    exact texts:**
    -   `MatchCaseStructPatternUnknownField` (Error, pattern_match.cpp):
        ``"struct pattern field `{0}` is not a field of the match
        scrutinee's type {1}"`` — `SemIR::NameId`, `SemIR::TypeId`.
    -   `MatchCaseStructPatternMissingFields` (Error,
        pattern_match.cpp): ``"struct pattern has no trailing `_` and
        does not name field{0:s} {1} of the match scrutinee's type
        {2}"`` — `Diagnostics::IntAsSelect`, `std::string` (backticked
        comma list, the `MatchNonexhaustive` builder shape,
        handle_match.cpp:1550-1555), `SemIR::TypeId`.
    -   `StructPatternNameDuplicate` (Error, handle_pattern_list.cpp):
        ``"duplicated field name `{0}` in struct pattern"`` —
        `SemIR::NameId`; note `StructPatternNamePrevious`: ``"field
        with the same name here"`` (the `StructNameDuplicate` /
        `StructNamePrevious` twins, handle_struct.cpp:90-95).
    -   kind.def placement: the two `MatchCaseStructPattern*` kinds
        between `MatchCaseNeverMatchesPriorArm` (:168) and
        `MatchCaseTuplePatternWrongArity` (:169), alphabetized; the
        two `StructPattern*` kinds after `StructNamePrevious` (:553).
        Every kind is covered by a §4 fail file, as the diagnostic
        coverage test requires.
6.  **Context:** the `struct_pattern_names_stack()` member (§2.2) with
    push/pop verified by `VerifyOnFinish`, alongside the existing
    per-kind stacks (context.h:761-765 region).

## §3 Commit structure

One slice, one PR (size M), mirroring fork/w078b/plan.md §3: commit 1 =
§2 compiler change (sem_ir inst + handlers + walk + gate + usefulness +
diagnostics + comment sweep); commit 2 = §4 testdata with AUTOUPDATE
markers and empty CHECK lines (R15/R19) + §5 conformance program +
gap-analysis PARTIAL-row refresh; then the runner-side autoupdate to
R26 fixpoint, the R21 gate and conformance runs, and the §8 discharge
commit (ledger + decision log). No sub-slicing: the compiler diff is
one new inst, three handlers, one walk function, and point extensions
to five existing functions, and §6's churn is additive-only.

## §4 Testdata matrix (R16: no hand-written goldens; autoupdate fills)

**New check/testdata/match/struct_pattern.carbon** (the
tuple_pattern.carbon twin — its 13 subfiles at :19-208 are the
template), `//@dump-sem-ir` on the positives:

| subfile | shape | expect |
| --- | --- | --- |
| literal_scrutinee | `match ({.a = 1, .b = 2})`, `case {.a = 1, .b = 2}`, `default` | silent; SemIR pins two `struct_access` + two `==` |
| reordered_fields | `case {.b = 2, .a = 1}` (design :427-432) | silent; accesses keyed by name, emitted in pattern order |
| all_binding | `fn F(p: {.a: i32, .b: i32})`, `case {a: i32, b: i32}`, NO `default` | silent — irrefutable arm discharges exhaustiveness (W-078b integration) |
| subset_discard | `case {.a = 1, _}` then `case {b: i32, _}` (design :461-466), no `default` | silent — second arm is irrefutable |
| all_fields_discard | `case {.a = 1, .b = 2, _}`, `default` | silent (design :468) |
| mixed_shorthand | `case {.a = 1, b: i32}`, binding used | silent |
| nested | `case {.y = {a: i32, b: i32}, _}` and `case {.y = (a: i32, b: i32), _}` on struct-of-struct / struct-of-tuple scrutinees; `case ({x: i32, _}, 1)` on a tuple-of-struct | silent |
| field_var_ref | `case {.a = var n: i32, _}`; `case {.a = ref r: i32, _}` on a `var` scrutinee | silent (field-level `var`/`ref`, §1.5) |
| unused_field | `case {unused a: i32, _}` | silent |
| empty_struct | `match ({})`, `case {}` | silent, irrefutable |
| fail_unknown_field | `case {.c = 1}` on `{.a: i32, .b: i32}` | `MatchCaseStructPatternUnknownField` |
| fail_missing_fields | `case {.a = 1}` on two-field scrutinee, no `_` | `MatchCaseStructPatternMissingFields` naming `` `b` `` |
| fail_missing_fields_all_binding | `case {a: i32}` on two-field scrutinee | same error — shape checks run at the root even for irrefutable trees (§1.4); no coverage recorded (errored condition) |
| fail_duplicate_field | `case {.a = 1, .a = 2, _}` | `StructPatternNameDuplicate` + note |
| fail_struct_nonexhaustive | `case {.a = 1, .b = 2}` only, no `default` | `MatchNonexhaustiveNoIrrefutableArm` naming `{.a: i32, .b: i32}` (§1.7, zero-code-change lane) |
| fail_struct_of_bool_pairs | struct-of-two-bools scrutinee, all four constant-pair arms, no `default` | same error — the root-only open-domain record, the bool_pair_keeps_default twin (§1.7) |
| fail_todo_non_struct_scrutinee | `case {x: i32}` on `i32` scrutinee | W4 slice-gate TODO abort (root `else`, §2.4) |
| fail_todo_nested_non_struct | `case ({x: i32}, 1)` on `(i32, i32)` | W4 TODO from the walk (§2.3) — also the §1.8 payload-shape twin |
| fail_todo_var_struct | `case var {a: i32, b: i32}` | W4 TODO (§1.5 gate) |
| fail_todo_struct_constant_leaf | `let` — a named struct constant as the case expression | R9 gate string ``match case expression pattern that is not a constant integer or `bool` `` (§1.9) |
| fail_error_element_recovery | `case {.a = undeclared, .b = 2}` | NameNotFound + errored-arm recovery, later arms still checked (:1273-1283) |
| fail_pruned_subtree_shape_error | `case (n: i32, {x: i32})` on `(i32, {.x: i32, .y: i32})` | test pass prunes the irrefutable struct element; the BIND pass diagnoses `MatchCaseStructPatternMissingFields` at the subpattern (the tuple fail_pruned_subtree_shape_error twin) |
| fail_ref_binding_value_scrutinee_field | `case {.a = ref r: i32, _}` on a value scrutinee | the bind-pass ref-conversion error (W8b parity) |

**New check/testdata/match/fail_case_never_matches_struct.carbon**
(the fail_case_never_matches_tuple.carbon twin, subfiles at :21-82):

| subfile | shape | expect |
| --- | --- | --- |
| fail_duplicate_exact | `{.a = 1, .b = 2}` twice | `MatchCaseNeverMatches` + PriorArm |
| fail_reordered_duplicate | `{.a = 1, .b = 2}` then `{.b = 2, .a = 1}` | dead — normalization is order-free (§1.6) |
| fail_subset_subsumes | `{.a = 1, _}` then `{.a = 1, .b = 2}` | dead — `Wildcard` fill subsumes |
| fail_after_irrefutable_struct | `{a: i32, b: i32}` then any struct constant arm | dead by way of the `{Wildcard}` prior |
| fail_wildcard_field | `{.a = 1, .b = b: i32, _}` then `{.a = 1, .b = 2}` | dead — per-field `Wildcard` |

**Extensions:** fail_dead_default.carbon (subfile inventory :32-335)
gains fail_struct_after_all_binding (`case {a: i32, b: i32}` then
`default`) and fail_struct_after_subset_binding (`case {a: i32, _}`
then `default`) — stage-1 `MatchDefaultNeverMatches` + PriorArm on the
struct lane. usefulness_no_false_positive.carbon (subfiles :25-284)
gains struct_superset_then_subset (`{.a = 1, .b = 2}` prior, then
`{.a = 1, _}` — SILENT: a constant never subsumes a `Wildcard` slot)
and struct_different_constants (silent).

**New check/testdata/let/fail_todo_struct_pattern.carbon**: `let
{x: i32} = {.x = 1};` and `var {.x = y: i32} = {.x = 1};` — the
FIRST check-side pins of the surviving ``struct pattern start`` TODO
(the §1.1 slice boundary and the ledger's recorded golden gap, closed
in the direction the slice leaves it).

**New lower/testdata/match/struct_pattern.carbon** (the
lower/testdata/match/tuple_pattern.carbon twin): constants+bindings
subfiles plus a subset+`_` arm, pinning the field-access/`icmp`/branch
IR with zero lower/ code change (§1.10).

## §5 Conformance

**One new program; floor becomes 102 PASS / 0 FAIL / 28 SKIP over
130.**

-   **New program control_flow/match_struct_destructure.carbon** under
    the existing bullet "Control flow: matching — good switch
    equivalents" (gap-analysis.md:55; R7 requires the exact string —
    `runner.py --self-test` before commit). Shape: a struct-typed
    value dispatched by constant-field arms (`case {.tag = 1, _}`),
    destructured by a shorthand binding arm (`case {tag: i32, val:
    i32}` — also the exhaustiveness discharge, no `default` in the
    second function), with reordered designated fields exercised; the
    C++ mental model is `switch` on one member plus member reads. The
    gap-analysis row's stale note ("all 15 check handlers ... are
    context.TODO stubs") is refreshed in passing — the PARTIAL status
    column is re-judged at discharge against the post-W-077 tree.
-   **Zero landed programs move.** Arm-level sweep: no program in
    fork/conformance/programs uses a struct pattern or a struct-typed
    `match` scrutinee (grep for brace-rooted `case`/`let`/`var`
    patterns over fork/conformance/programs is empty — §6 record), and
    this slice changes no diagnostic any landed program triggers: the
    only behavior changes are gated behind parse shapes
    (`StructPattern*` nodes) and scrutinee types (struct) that no
    landed program produces.

## §6 Churn inventory (verified file-by-file)

**Existing goldens: ZERO move.** The verification record, so the
reviewers can re-run it:

1.  The three TODO strings appear nowhere in any golden: grep for
    ``struct pattern start`` / ``"struct pattern"`` / ``struct pattern
    field`` over toolchain/ and fork/ hits only
    handle_pattern_list.cpp:40/:138/:143 (and parse's two unrelated
    shorthand-diagnostic texts, parse/handle_pattern_list.cpp:216,
    :224, which contain the words but pin parse diagnostics this slice
    does not touch). The `struct pattern start` string SURVIVES at its
    site for non-match contexts (§1.1), so even the code-side string
    only narrows, and the first goldens to pin it are §4 additions.
2.  No check or lower golden contains a struct pattern or struct
    scrutinee: grep for `let {`, `var {`, `case {` over
    toolchain/check/testdata and toolchain/lower/testdata is empty
    (parse/testdata/struct/struct_pattern.carbon is parse-only and
    untouched — struct-pattern PARSING does not change).
3.  The additions to inst_kind.def, kind.def, typed_insts.h, and
    context.h shift no existing golden: SemIR dumps print inst
    `ir_name`s and diagnostics print kind names — neither is
    positional.
4.  fork/conformance/programs: no struct patterns (grep record, §5).

**Compiler files touched (additive except comments):**
toolchain/sem_ir/{inst_kind.def, typed_insts.h, pattern.cpp},
toolchain/check/{handle_pattern_list.cpp, pattern_match.cpp,
handle_match.cpp, context.h}, toolchain/diagnostics/kind.def. The
comment sweep (§2.4) also touches no goldens: file comments do not
print.

**New files:** check/testdata/match/struct_pattern.carbon,
check/testdata/match/fail_case_never_matches_struct.carbon,
check/testdata/let/fail_todo_struct_pattern.carbon,
lower/testdata/match/struct_pattern.carbon, two subfile extensions in
kept files (fail_dead_default.carbon,
usefulness_no_false_positive.carbon — additions only; their existing
subfiles' output is untouched, loc-shift-free because new subfiles
append), and
fork/conformance/programs/control_flow/match_struct_destructure.carbon.
NOTE (R26): appending subfiles adds no CHECK lines ABOVE existing
source, so the autoupdate is expected to converge in one pass for the
two extended files and two passes at most for the new files.

## §7 Risks and rejected alternatives

-   **R-1 name-collection protocol complexity (§2.2).** The
    ordinal-keyed side stack is the one genuinely novel check-side
    mechanism (tuples have no names, struct literals have no
    shorthand). Failure mode: a mixed designated/shorthand pattern
    misaligning names to elements. Mitigation: the mixed_shorthand and
    nested positives pin alignment through SemIR (field names ride the
    pattern's printed type), and the mechanism degrades loudly — a
    misalignment produces a wrong-name `StructTypeField`, visible in
    every dump. Rejected: deriving names by re-walking the parse tree
    (check is single-pass); wrapping elements in a per-field SemIR inst
    (a whole extra inst kind to carry one NameId the type already
    carries).
-   **R-2 nested empty-aggregate silent hole (shared with the landed
    tuple lane, recorded, not fixed here).** A NESTED `{}` (or `()`)
    subpattern is irrefutable AND binding-free, so the test pass prunes
    it (irrefutable) and the bind pass prunes it (no bindings) — its
    shape checks never run, so `case ({}, 1)` against a tuple whose
    element is a NON-empty struct is silently accepted where the design
    wants the missing-fields error. The tuple lane has the identical
    latent hole for nested `()` arity today (same two prune predicates,
    pattern_match.cpp:1716-1721) — this is tuple-parity residue, not
    new unsoundness (nothing binds, the arm's condition is unchanged,
    no wrong code is emitted). ROOT-position `{}` is fully checked
    (§2.4 routes every struct root through the engine). Recorded in
    the ledger note at discharge as shared residue with a pointer to
    both lanes; fixing it means an unconditional shape-check pass and
    belongs to a joint follow-up, not this slice.
-   **R-3 subsumption-normalization contested.** A reviewer may push
    for name-sorted children instead of scrutinee-order children. The
    rebuttal is one sentence: sorting alone cannot restore fixed arity
    for subset patterns — only filling to the scrutinee's field set
    can, and once filled, any canonical order works, so the scrutinee's
    own order is the one that needs no extra sort and matches the walk.
    The soundness argument (§1.6) is written to survive either
    spelling.
-   **R-4 `BoolValue` as the discard flag's arg type.** If the inst
    plumbing rejects a third field or the formatter prints it poorly,
    the fallback is two inst kinds or a `.discarded` sentinel — both
    §1.2-rejected for size; the review should treat a fallback as a
    NEEDS-FIX on the plan, not an implementer improvisation (R17).
-   **R-5 upstream race (F-002).** Struct patterns are on upstream's
    own path (the ledger's watch note; upstream's marker TODO at
    sem_ir/pattern.cpp:68). If upstream lands a struct-pattern layer
    first, the F-002 staging-merge rule applies: merge upstream into
    staging, re-run the suite, and REGENERATE this slice against their
    representation rather than hand-merging — their layer will differ
    at minimum in the let/var lane this slice deliberately excludes.
-   **R-6 `MatchCasePatternHasStructPattern` reroute misses a path.**
    The two rerouted sites (§2.4: the var gate, the tuple bind fast
    path) were found by enumerating every `LocalPatternMatch` /
    `DoVarPreWorkImpl` entry reachable from a match arm; a missed path
    surfaces loudly as the `CARBON_FATAL` in the struct `DoPreWork`
    for non-match states (§2.3) — a crash in testing, never a silent
    wrong answer. The §4 nested and var matrices cover each found
    path.
-   **Rejected: implementing all contexts (the ledger's framing).**
    §1.1's evidence: the context gate exists, the match lane cannot
    share the let/var lane's conversion machinery anyway (§1.4), and
    the fork precedent is focused slices. The let/var/param lane is
    filed as follow-up work at discharge with the §4 TODO pins as its
    starting evidence.
-   **Rejected: a real diagnostic for struct-root-on-non-struct
    scrutinee.** The tuple lane keeps the W4 slice-gate TODO for the
    same shape at both root and nested positions
    (handle_match.cpp:811-816, pattern_match.cpp:1666-1695); diverging
    for structs would split twin shapes across diagnostic classes for
    no design gain. Recorded so the eventual W4-gate-retirement item
    lifts both lanes together.
-   **Rejected: widening R9 to struct-valued constant leaves.**
    W-066's subsumption runs on evaluated `IntId`/bool constants;
    admitting `StructValue` leaves without keying them would create
    record-nothing arms that weaken usefulness — the same direction
    W8c's R9 disposition already declined for non-constant cases.

## §8 Verification and discharge

1.  Regen: runner autoupdate to R26 fixpoint (expected: pass 2 loc-only
    at most, §6 note); churn confined to the §6 inventory —
    specifically, ZERO diffs outside newly added files and the two
    appended-subfile files.
2.  Gate: full `bazelisk` toolchain gate green (R21 mirror), prek
    clean (R25: `uvx prek run --files <changed>` locally first;
    clang-format 21.1.8 per R18 on the C++ diff).
3.  Conformance: **102 PASS / 0 FAIL / 28 SKIP over 130**;
    `runner.py --self-test` green (R7). Any other movement is a §5/§6
    miss — stop and reconcile.
4.  Reconciliation greps at discharge: ``struct pattern start``
    survives at exactly handle_pattern_list.cpp (one site) plus the
    new let/var pins; ``"struct pattern"`` and ``struct pattern
    field`` survive NOWHERE in check code; the W4 gate string's site
    count grew only by the §4 pins.
5.  **Ledger edits (fork/inventory/work-items.json):**
    -   W-077: notes gain the closing record — "MATCH-LANE DISCHARGED
        (fork/w077/plan.md): `SemIR::StructPattern` + match-only slice
        gated on `FullPatternStack::Kind::MatchCaseArm`; name-keyed
        scrutinee-typed field walk in both passes
        (`DoMatchCaseStructPreWork`); field-subset/unknown/duplicate
        diagnostics; usefulness `Struct` key normalized to the
        scrutinee field set with `Wildcard` fills; exhaustiveness and
        dead-`default` ride W-078b's open-domain lane unchanged; zero
        lower/ changes; conformance 102/0/28 over 130" — evidence
        lines `:138`/`:143` replaced (dead gates removed), `:40`
        retitled to the surviving non-match gate, and the two §0
        ledger corrections (the context gate exists; :138/:143 were
        unreachable) recorded verbatim.
    -   NEW work item filed: struct patterns in `let`/`var`/param
        contexts (the §1.1 residue), evidence = the surviving gate
        site + the new let/var TODO pins + §1.4's note that the
        irrefutable lane needs the conversion-or-walk decision this
        slice did not make; blocked_by: none.
    -   Decision-log entry "W-077: struct patterns in match case
        position (date)" carrying §1.1 (the slice and the two ledger
        corrections), §1.4 (conversion-path impossibility — the reason
        the lanes split), §1.6 (the normalization and its soundness
        argument), §1.7 (zero-change lane integration and the extended
        agreement invariant), and §7 R-2 (the shared nested
        empty-aggregate residue), each with its break condition.
6.  gap-analysis.md:55: the matching row's stale detail column is
    refreshed (it still claims all match handlers are TODO stubs);
    R7 forbids touching the bullet TEXT itself.

## Hand-off notes for the implementer

-   Keep the §1.1 gate at the START handler and keep its TODO string
    byte-identical: the non-match lane's behavior today IS the abort at
    that string, and §4's new let/var pins are written against it.
-   The walk's shape checks must run BEFORE the per-field prune loop
    (§2.3 order), or fail_missing_fields_all_binding regresses to
    silent — the root routes the engine precisely to get those checks
    (§2.4).
-   Build the usefulness `Struct` node only from the SCRUTINEE's
    unqualified `StructType`, never from the pattern's own type — the
    pattern type is the SUBSET; using it re-introduces the arity bug
    the normalization exists to fix.
-   `DoMatchCaseStructPreWork`'s two TODO locations follow the tuple
    twin exactly (introducer node in the test pass, subpattern in the
    bind pass, pattern_match.cpp:1683-1694) — the bind pass runs with
    the arm's case context already popped.
-   The fail-matrix bindings must be used or `unused`-marked so no
    incidental UnusedBinding warning rides the goldens (the W-078b
    rev 2 record note; fork/w078b/plan.md §4).
