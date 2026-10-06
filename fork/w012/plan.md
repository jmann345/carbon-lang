<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-012 plan: if-let / while-let / let-else as refutable-match desugarings

**Status:** APPROVED FOR IMPLEMENTATION, 2026-09-27. Two adversarial plan
reviews per R29(c) — rev 1 REJECT (findings 1-5 against §1.1, §2.2, §2.3,
§4, §5) and rev 2 APPROVE-WITH-AMENDMENTS, both converged on the same
blocker (the `var`-wrapped alternative root had no engine lane) — then a
focused re-review of §1.1/§2.2/§2.3/§4/§5 returned
APPROVE-WITH-AMENDMENTS (M1-M3, m4-m6). Every amendment is folded below,
marked "(amended 2026-09-27, review fold: rev N …)" or "(amended
2026-09-27, review fold: re-review …)"; the list is in Sign-off. Branch
`claude/carbon-fork-0-1-w012`
(plan-only), merged with trunk f0e1980 (the reconciled gap-analysis and
R29; the trunk delta since 55517908c is fork/gap-analysis.md only, so
every toolchain line number below holds against f0e1980).

**Base premise (amended 2026-09-27, review fold: rev 2 M2):** base =
origin/trunk f0e1980 (+ PR #39 W-077 when merged — the implementer rebases
first). W-077 (struct patterns in match case position, branch
`claude/carbon-fork-0-1-w077`, HEAD 438f569ec, plan APPROVED 2026-09-26)
is NOT in trunk at this writing (`git merge-base --is-ancestor` says no);
its handle_match.cpp adds `StructType` to `IsSupportedScrutineeType` at
~:230 and a struct classification lane at ~:828-833 with its bind lane at
~:1105, and moves `EmitCaseArmTestAndBind` to :766. Conformance floors:
trunk f0e1980 measures 101 PASS / 0 FAIL / 28 SKIP over 129
(fork/conformance/out/scoreboard.json totals); the **102 / 0 / 28 over
130** floor this plan builds on was measured on the W-077 branch (hosted
conformance run, scoreboard generated 2026-09-26T10:28Z); W-012's target
is relative to that floor, +2 programs: **104 PASS / 0 FAIL / 27 SKIP over
131**. Every line number below is against trunk f0e1980 unless marked
"(W-077: …)".

**Item:** W-012 (fork/inventory/work-items.json) — "IL-1: if-let /
let-else / while-let (Option A) as desugarings onto W4's refutable-match
SemIR + pattern_matching.md amendment"; milestone bullet "Control flow:
matching — if-let / let-else combined match+declaration", MISSING at
fork/gap-analysis.md:57. The design is DECIDED and STANDS:
fork/decision-log.md:1311-1318 (F-011, 2026-07-19, Option A of
fork/design-sprint/if-let.md:241-373; recommendation :493-532; rejected
B/C/D on record). This plan does not reopen it: it settles how Option A
lands on the match machinery that exists in-tree today (W8a/W8b, W-066,
W-076, W-078a/b, W-077), which the design paper predated (it was written
against trunk `99cda60`, when every `match` check handler was a TODO
stub, if-let.md:207-220).

Slice (R29(b), one PR per milestone feature): all three forms —
`if (let P = e) {…} else {…}`, `while (let P = e) {…}`, and
`let P = e else { <diverging block> }` — plus their `var` spellings
(`if (var P = e)`, `var P = e else {…}`; if-let.md:296-303 grammar), the
docs/design/pattern_matching.md amendment, the un-SKIP of
fork/conformance/programs/control_flow/if_let_let_else.carbon, and one
new while-let conformance program.

## §0 Ledger and design corrections this plan rests on

Each verified in-tree; recorded at discharge (§8.5).

1.  **"No lexer change" holds for lexing but not for the parse-tree size
    budget.** `Tree::Verify` rejects an error-free tree with more nodes
    than the lexer budgeted (toolchain/parse/tree.cpp:52-56, "Tree has {0}
    nodes and no errors, but Lex::TokenizedBuffer expected up to {1}
    nodes"); the budget is 1 node per token and 2 for
    `CARBON_TOKEN_WITH_VIRTUAL_NODE` tokens (toolchain/lex/token_kind.cpp:
    76-80). `let` has budget 1 (toolchain/lex/token_kind.def:169), `var`
    2 (:175-176), `else` 1 (:193). A `let`-`else` needs three nodes with
    no token of their own besides `let` and `else` — the introducer, the
    `else` leaf that hooks the branch, and the closing declaration node
    (§1.2, §1.3) — so `else` must become
    `CARBON_TOKEN_WITH_VIRTUAL_NODE(CARBON_KEYWORD_TOKEN(Else, "else"))`,
    exactly the precedent of `and`/`or`/`self`/`fn`/`var` (:164-165,
    :175-176, :213-214, :224-225). Lexing behavior is untouched; only the
    upper bound loosens. Worked arithmetic in §1.2.
2.  **Node/state counts: 5 node kinds (as the ledger says), 2 states (not
    ~6).** The pattern-condition forms reuse the existing
    `ParenConditionFinishAs(If|While)` states and the existing
    `IfCondition`/`WhileCondition` close nodes (§1.2); `let`-`else` reuses
    the `CodeBlock` state. Only `PatternConditionAfterPattern` and
    `LetElseFinish` are new.
3.  **"A refutable `LocalPatternMatch` variant with failure-block target"
    is not what the landed engine needs.** The refutable test pass
    (`MatchCasePatternMatch`, toolchain/check/pattern_match.h:118-120) and
    the bind pass (`MatchCaseBindPatternMatch` :133-134 / `LocalPatternMatch`
    :88-89) already exist and are driven by `EmitCaseArmTestAndBind`
    (toolchain/check/handle_match.cpp:733-1051; W-077 15207a17f: :766).
    This slice adds no engine variant; it factors a statement-level
    driver out of that function (§1.4, §2.3) and adds TWO lanes that
    `match` never needed (amended 2026-09-27, review fold: rev 1 F1 + rev
    2 B1 — the draft said "one"): **deferred alternative resolution**
    (§1.6) and the **var-alternative classification lane** (§1.1, decision
    R29a: a `var`-wrapped alternative root such as `var .Some(v: i32)` is
    classified and bound explicitly instead of falling to the slice-gate
    TODO; `match` inherits the lane through the shared driver).
    In `match`, the scrutinee is checked before the `case` patterns, and
    `HandleParseNode(AlternativePatternId)` resolves `.Name` against
    `match_case_stack().back().scrutinee_type_id` at pattern-check time
    (handle_match.cpp:389-398, `LookupChoiceAlternative` :405, member
    access :420-421, arity :471-495). In `let P = e`, `if (let P = e)` and
    `while (let P = e)` the parse tree — and therefore check's postorder
    traversal — visits the pattern BEFORE the initializer
    (toolchain/parse/typed_nodes.h:657-672 `LetDecl`: `pattern` precedes
    `initializer`; the `for` header is the in-tree precedent for a pattern
    checked before its scrutinee, toolchain/check/handle_loop_statement.cpp:
    126-158, bound only at :255). So the scrutinee type is unknown when
    `.Some(n: i32)` is checked. Everything else a pattern does at check
    time is scrutinee-independent (bindings carry explicit types,
    handle_binding_pattern.cpp:340-366; tuple arity and struct field
    walks run in the test pass against the scrutinee's own type,
    pattern_match.cpp:1643-1738 and W-077 plan §1.4).
4.  **The SKIP program's strawman is not p002188 grammar.**
    fork/conformance/programs/control_flow/if_let_let_else.carbon:30 and
    :34 spell the payload binding `.Some(let v: i32)`; the accepted grammar
    is `.Some(v: i32)` (docs/design/pattern_matching.md:474-524; parse
    golden toolchain/parse/testdata/match/alternative_pattern.carbon).
    The body is replaced wholesale (§5).
5.  **The ledger's doc evidence `pattern_matching.md:712-714` is the
    "skeletal design" placeholder, not the amendment target.** The
    reserved slot is :670-676 (the #1871 "second context" sentence quoted
    by the design paper); the amendment edits that sentence and adds a
    new subsection (§2.6).
6.  **Both ledger blockers are landed.** W-008 (match statement) and
    W-010 (payload alternatives) carry "implemented" titles and empty
    `blocked_by`; the machinery this plan reuses is the evidence.
7.  **Design premise re-verified, not corrected:** "`let`/`var` can never begin
    an expression" (if-let.md:191-197). `var` appears in the expression grammar
    only after `form(` (toolchain/parse/handle_form_literal.cpp: 34-48, reached
    from handle_expr.cpp:172-174 on the `form` token); `let` appears nowhere in
    it. So the single-token peek after `(` is unambiguous.
8.  **Refutable patterns in plain `let`/`var` are a TODO today, not the design's
    error.** `LocalPatternMatch` on an `ExprPattern` root emits
    ``context_.TODO(entry.pattern_id, "expression pattern")``
    (toolchain/check/pattern_match.cpp:1176-1191; the TODO is :1191), and no
    check golden contains a refutable `let`/`var` root (grep record in §6.1).
    The real refutability error of pattern_matching.md:670-687 stays out of this
    slice and is filed as a work item (§8.5).

## §1 Design decisions

Each decision names its break condition. "Refutable pattern binding" below
means any of the three forms.

1.  **SLICE: the three forms with their `var` spellings, one PR, no
    guard, no `and` chaining, no expression form** (if-let.md:330-334 lists
    these as reserved for after 0.1). The `var` spellings are included
    because they cost nothing new: the pattern-level `var` wrapper node the
    `var` declaration parser already emits (`VariablePattern`,
    toolchain/parse/handle_var.cpp:57-74) is re-emitted by the new states,
    and check's `VariablePattern` handler under the refutable context
    already produces the on-demand-storage `VarPattern` lane
    (toolchain/check/handle_let_and_var.cpp:146-165; `case var a: i32` is
    golden-pinned at toolchain/check/testdata/match/var_binding.carbon).
    Break condition: a review finding that `var` in these forms needs
    frame-indexed storage — then the `var` spellings drop to a follow-up
    item and everything else stands.

    **The var-alternative lane (amended 2026-09-27, review fold: rev 1 F1
    -   rev 2 B1; decision R29a, auto-adopted by the orchestrator under
        R29(a) and recorded in the decision log for after-the-fact veto,
        §8.5).** Both reviews found the same blocker: the `var`-wrapped
        alternative root — `if (var .Some(n: i32) = opt)`,
        `var .Some(v: i32) = o else {…}`, the design's own example
        (if-let.md:291) — has NO lane in `EmitCaseArmTestAndBind` today. The
        classification (handle_match.cpp:776-816) tests
        `alternative->payload_pattern_id == pattern_id` (:782-784), but under
        the `var` spelling the root is the `VarPattern` that check's
        `VariablePattern` handler wraps around the payload tuple
        (handle_let_and_var.cpp:162-164, `.subpattern_id = subpattern_id`), so
        `is_alternative_payload_arm` is false; `is_irrefutable_var_arm`
        (:779-781) is true only for an all-binding payload and then routes to
        `MatchCasePatternMatch` on the `VarPattern`, which never tests the
        discriminant (wrong: `.Some` must fail on `.None`), and a payload with
        an expression subpattern falls to the slice-gate TODO (:812-816).
        Decision R29a: the `var`-wrapped alternative root gets an EXPLICIT
        second engine lane rather than being dropped.
    -   Classification, in the shared test driver (§2.2), computed BEFORE
        `is_irrefutable_var_arm`, which EXCLUDES it (amended 2026-09-27, review
        fold: re-review M1 — ordering the dispatch alone is not enough, see the
        next bullet): `is_var_alternative_arm =
        context.insts().Is<SemIR::VarPattern>(pattern_id) && alternative &&
        alternative->payload_pattern_id.has_value() &&
        alternative->payload_pattern_id ==
        context.insts().GetAs<SemIR::VarPattern>(pattern_id).subpattern_id` —
        the `VarPattern`'s `subpattern_id` (sem_ir/typed_insts.h:2394) is the
        synthesized payload `TuplePattern` that `AlternativePattern` records as
        `payload_pattern_id` (handle_match.cpp:556-560) — and
        `is_irrefutable_var_arm =
        context.insts().Is<SemIR::VarPattern>(pattern_id) &&
        !is_var_alternative_arm && IsIrrefutableMatchCasePattern(context,
        pattern_id)`.
    -   **Why the exclusion is load-bearing (amended 2026-09-27, review fold:
        re-review M1).** Today's `is_irrefutable_var_arm`
        (handle_match.cpp:779-781) is TRUE for `case var .Some(n: i32)`:
        `IsIrrefutableMatchCasePattern` recurses through the `VarPattern`
        (pattern_match.cpp:680-684) into the all-binding payload. With the
        dispatch merely ordered, the flag would still reach `match`'s coverage
        block (:939-941), set `has_irrefutable_arm`, and mark the match
        exhaustive — suppressing `DiagnoseNonexhaustiveMatch` (:1460) for a
        two-alternative choice whose `.None` no arm covers, and breaking the "`has_irrefutable_arm`
        iff a `Wildcard`-root usefulness entry" invariant that
        `DiagnoseDeadDefault` rests on (:1239-1245). With the exclusion, none of
        the three flags that feed `has_irrefutable_arm` is set for the arm, so
        :942-943 records `covered_alternatives` through
        `alternative->payload_is_irrefutable` exactly as for the plain `case
        .Some(n: i32)`. Usefulness keys the arm with
        `BuildMatchCaseUsefulnessKey(context, alternative->payload_pattern_id,
        alternative)` — the payload root, not the `VarPattern` — because the
        builder's defensive check (pattern_match.cpp:740-744) returns `nullopt`
        when `payload_pattern_id != pattern_id`, which is why today's `case var
        .Some(n: i32)` is silently neither checked nor recorded for usefulness.
        Guards: the §4 match rows `fail_nonexhaustive_var_alternative` (the arm
        alone on a two-alternative choice → `MatchNonexhaustive` naming `.None`)
        and `var_alternative_then_default` (a trailing `default` is NOT dead).
        The §8.1 zero-diff gate cannot catch a regression here: no existing
        golden spells a `var`-wrapped alternative root (§8.1).
    -   Test: `MatchCaseAlternativePatternMatch(context, scrutinee_id, node_id)`
        unchanged — it reads only `alternative` (pattern_match.cpp:561-603:
        the CHECK at :565, the copy at :569, the constant-`true`
        single-alternative rule :578-597, the discriminant test :599-603,
        payload conditions on `alternative.payload_pattern_id`), never the
        root inst, so the wrapper is invisible to it.
    -   Bind, in the success block: `MatchCaseBindPatternMatch(context,
        var_root_id, EmitChoicePayloadFieldAccess(context,
        SemIR::LocId(node_id), scrutinee_id, alternative->payload_field_index))`
        when `alternative->payload_field_index >= 0 &&
        MatchCasePatternHasBindings(context, var_root_id)` (the
        alternative-payload lane's own guard, handle_match.cpp: 1006-1009). The
        bind walk meets the `VarPattern` root first and emits on-demand storage
        through `GetOrAddVarStorage` (pattern_match.cpp:1476-1477, the
        `in_match_case_bind` branch), typed by the `VarPattern`'s type — the
        payload-tuple pattern type the `VariablePattern` handler took from its
        subpattern (handle_let_and_var.cpp:102, :164) — initialized from the
        payload field ref, then destructured elementwise into the payload's
        `ref` bindings. Precedent, shape for shape: `case var (a: i32, b: i32)`
        (toolchain/check/testdata/match/var_binding.carbon:58) — one tuple-typed
        storage bound elementwise. The field ref is trivially copyable (the
        scrutinee gate) and dominated by the discriminant test exactly as in the
        plain payload lane (:1010-1019 comment).
    -   Irrefutability for the §1.10 WARNING looks THROUGH the wrapper: the
        driver's `is_irrefutable` (the warn predicate, §2.2 — a flag kept
        SEPARATE from the three that `match` feeds into
        `has_irrefutable_arm`; amended 2026-09-27, review fold: re-review
        M1/M3) is, for this arm, "the choice has a single alternative and
        `alternative->payload_is_irrefutable`" — the same rule the plain
        alternative lane uses — and the single-alternative constant-`true`
        test reads `alternative` as before.
    -   `match` gets the lane too (the driver is shared): `case var .Some(n:
        i32) => …` starts working as a side effect. §4 pins `var_alternative`
        positives in check AND lower, plus — in the same PR — a `match` golden
        for the payload-level `case .Some(var n: i32)`, which the
        alternative-payload lane admits today through its
        `MatchCasePatternHasVarPattern` branch (handle_match.cpp:1027-1031) but
        which NO golden pins (grep `\.[A-Za-z]*(var` over
        toolchain/check/testdata/match, toolchain/lower/testdata/match and
        fork/conformance/programs: no hits).
    -   Bare `var .None` (empty synthetic payload root, no bindings): the
        `VariablePattern` handler under `MatchCaseArm` runs
        `MatchCasePatternHasBindings` on the empty subpattern and hits the
        binding-free-`var` TODO ``binding-free `var` in match `case`
        pattern`` at PATTERN time (handle_let_and_var.cpp:157-160), pinned
        to the form's introducer. Disposition: KEPT as that TODO in this
        slice — no lane; `var` on a binding-free pattern has no storage to
        name in the design either — and pinned in fail_if_let.carbon
        (`fail_todo_var_bare_alternative`, §4).

    Rejected, with reason: dropping the root-`var` spellings to a
    follow-up work item (§7 A-8). (i) The design's own worked example is
    the `var`-else form (if-let.md:291) and the SKIP program's replacement
    (§5, `Bump`) exercises it — deferring would ship the milestone bullet
    with its canonical example rejected by a TODO. (ii) The lane is ~15
    lines over machinery that exists (`VarPattern` on-demand storage,
    `EmitChoicePayloadFieldAccess`, `MatchCaseBindPatternMatch`), with the
    var_binding.carbon:58 precedent for its exact SemIR shape. (iii) The
    shared driver hands the lane to `match` for free, closing a gap in the
    match row as well. Break condition: a review finding that the lane's
    storage must be frame-indexed rather than on-demand — then root-`var`
    in the new forms drops to a follow-up and everything else stands.

2.  **PARSE: no `PatternCondition` grouping node; the pattern-condition
    prefix lives directly under the existing `IfCondition` /
    `WhileCondition` close node, whose typed nodes gain an optional
    prefix.** Tree for `if (let .Some(n: i32) = opt) { … }`:

    ```text
    ╭─IfConditionStart '('
    │ ╭─PatternConditionIntroducer 'let'
    │ │ ╭─AlternativePatternStart '.'
    │ │ ├─IdentifierNameNotBeforeSignature 'Some'
    │ │ │ ╭─TuplePatternStart '('
    │ │ │ │ ╭─IdentifierNameNotBeforeSignature 'n'
    │ │ │ │ ├─BindingPatternTypeStart ':'
    │ │ │ │ ├─IntTypeLiteral 'i32'
    │ │ │ ├─LetBindingPattern ':'
    │ │ ├─ParenPattern ')'
    │ ├─AlternativePattern '.'
    │ ├─PatternConditionInitializer '='
    │ ├─IdentifierNameExpr 'opt'
    ├─IfCondition ')'
    │ ╭─CodeBlockStart '{'
    ├─CodeBlock '}'
    ├─IfStatement 'if'
    ```

    (Alternative-pattern subtree shape per
    toolchain/parse/testdata/match/alternative_pattern.carbon; `if`
    bracketing per toolchain/parse/testdata/if/else.carbon:33-35.) Why no
    grouping node: `IfStatement` is `bracketed_by = IfCondition::Kind`
    (typed_nodes.h:894-896) and `bracketed_by` names exactly one kind
    (toolchain/parse/node_kind.h:99-106), so the condition's close node
    must stay `IfCondition`; a grouping node closing the `let … = e` run
    would have to ride the `let` token, whose budget of 1 is spent on the
    introducer (§0.1). Budget check for
    `if (let n: i32 = x) { }`: tokens `if ( let n : i32 = x ) { }` budget
    1+1+1+1+2+1+1+1+1+1+1 = 12 (`:` is a virtual-node token: the plain
    `let n: i32 = x;` golden toolchain/parse/testdata/let/let.carbon:20-27
    has 8 nodes on 8 budget with `:` carrying `BindingPatternTypeStart`
    and `LetBindingPattern`); nodes: IfConditionStart, introducer, `n`,
    type start, `i32`, binding, initializer leaf, `x`, IfCondition,
    CodeBlockStart, CodeBlock, IfStatement = 12. Exact. `var`: introducer
    -   `VariablePattern` = 2 on `var`'s budget of 2.

    Typed nodes (toolchain/parse/typed_nodes.h): `IfCondition` and
    `WhileCondition` drop `.child_count = 2` (keeping `.bracketed_by`,
    which alone is sufficient — node_kind.h:99) and become

    ```cpp
    // `let`/`var`, or `let`/`var` inside a pattern condition.
    using PatternConditionIntroducer =
        LeafNode<NodeKind::PatternConditionIntroducer, Lex::TokenIndex>;
    using PatternConditionInitializer =
        LeafNode<NodeKind::PatternConditionInitializer, Lex::EqualTokenIndex>;

    // `let P =` or `var P =` in front of a condition's expression, making
    // the condition a refutable pattern binding; see IfCondition.
    struct PatternConditionPrefix {
      PatternConditionIntroducerId introducer;
      AnyPatternId pattern;  // a VariablePattern for the `var` spelling
      PatternConditionInitializerId equals;
    };

    // The condition portion of an `if` statement: `(expr)` or
    // `(let P = expr)`.
    struct IfCondition {
      static constexpr auto Kind = NodeKind::IfCondition.Define(
          {.bracketed_by = IfConditionStart::Kind});
      IfConditionStartId left_paren;
      std::optional<PatternConditionPrefix> pattern;
      // The boolean condition, or the initializer when `pattern` is set.
      AnyExprId condition;
      Lex::CloseParenTokenIndex token;
    };
    ```

    `WhileCondition` identically. Extraction runs right-to-left over the
    children, so `condition` binds the last child in both spellings and
    the optional prefix is tried against what precedes it — the
    `std::optional<Initializer>` of `LetDecl` (typed_nodes.h:665-669) and
    `IfStatement::Else` (:898-905) are the in-tree precedents for optional
    nested structs, and `LeafNode<…, Lex::TokenIndex>` for a two-token
    leaf is precedented by `Placeholder` and `InvalidParse`
    (typed_nodes.h:94, :99, :112). Break condition: the typed-node test
    (toolchain/parse/typed_nodes_test.cpp) rejecting an optional struct
    that precedes a mandatory categorized field — then the fallback is a
    `NodeId condition` (untyped, the `Lambda::body` precedent,
    typed_nodes.h:782) with the prefix still optional; tree output is
    identical either way.

3.  **PARSE, `let`-`else`: the introducer node is re-kinded when the parser
    reaches the `else`.** The parser learns that a `let` is a `let`-`else` only
    after the full initializer expression, exactly as it learns a declaration's
    introducer only after its modifiers — and it handles that with
    `ReplacePlaceholderNode(state.subtree_start, …)`
    (toolchain/parse/context.cpp:42-53; the state's `subtree_start` is retained
    through `ApplyIntroducer`, handle_decl_scope_loop.cpp:38-45, and
    `HandleLet`'s `PushState(state, LetFinishAsRegular)`, handle_let.cpp:17, so
    `state.subtree_start` in `HandleLetFinish` indexes the `LetIntroducer`
    node). This slice adds the sibling `Context::ReplaceIntroducerNode(position,
    old_kind, new_kind)`: the same one-line `NodeImpl` rewrite with a CHECK on
    the old kind (the tree already exposes `set_kind` for exactly this
    operation, tree.h:245-250). Tree for `let .Some(port: i32) = Parse(s) else {
    return -1; }`:

    ```text
    ╭─LetElseIntroducer 'let'
    │ … pattern subtree as above …
    ├─LetInitializer '='
    ├─<initializer expression>
    ├─LetElse 'else'
    │ ╭─CodeBlockStart '{'
    │ │ … statements …
    ├─CodeBlock '}'
    ├─LetElseDecl 'let'
    ```

    `LetInitializer`/`VariableInitializer` are NOT re-kinded (their position is
    not retained by any state); their check handlers become context-aware
    instead (§2.3, a two-line branch each). Budget: `let n: i32 = x else {
    return; }` tokens 1+1+2+1+1+1+2(else, §0.1)+1+1+1+1 = 13; nodes: introducer,
    `n`, type start, `i32`, binding, `=`, `x`, LetElse, CodeBlockStart,
    ReturnStatementStart, ReturnStatement, CodeBlock, LetElseDecl = 13. Exact.
    Typed nodes:

    ```cpp
    // `let` or `var` opening a `let`-`else` declaration (re-kinded from
    // LetIntroducer/VariableIntroducer when the `else` is reached).
    using LetElseIntroducer =
        LeafNode<NodeKind::LetElseIntroducer, Lex::TokenIndex>;
    using LetElse = LeafNode<NodeKind::LetElse, Lex::ElseTokenIndex>;

    // A `let`-`else` declaration: `let P = e else { <diverging block> }`.
    struct LetElseDecl {
      static constexpr auto Kind = NodeKind::LetElseDecl.Define(
          {.category = NodeCategory::Statement,
           .bracketed_by = LetElseIntroducer::Kind});
      LetElseIntroducerId introducer;
      llvm::SmallVector<AnyModifierId> modifiers;
      // `returned var P = e else {…}`: the parser's `HandleVarAsReturned`
      // shares `VarFinish` (handle_var.cpp:53-54) and emits a
      // `ReturnedModifier` leaf (:25), so the re-kind reaches this form
      // too; check rejects it (§2.3, `ReturnedNotAllowedOnLetElse`). Cf.
      // `VariableDecl::returned`, typed_nodes.h:730. (amended 2026-09-27,
      // review fold: rev 1 F4 + rev 2 M1)
      std::optional<ReturnedModifierId> returned;
      AnyPatternId pattern;  // a VariablePattern for the `var` spelling
      NodeIdOneOf<LetInitializer, VariableInitializer> equals;
      AnyExprId initializer;
      LetElseId else_token;
      CodeBlockId else_block;
      Lex::TokenIndex token;  // the introducer token
    };
    ```

    Category `Statement` (function-body only, §1.9); `AnyStatementId` admits it
    (toolchain/parse/node_ids.h:111-112). No trailing `;` (design open question
    1, if-let.md:575-580, resolved by the paper's own assumption; the `;`
    alternative is §7 A-3). Break condition: a reviewer rejecting node
    re-kinding — the fallback is a distinct `LetElseDecl` close node only, with
    the check side deciding the pattern context late; §7 A-4 records why that
    fallback is worse (it cannot resolve `.Name` roots, §0.3).

4.  **CHECK: `FullPatternStack::Kind::MatchCaseArm` plus a
    `MatchCaseContext` entry ARE the refutable pattern context; the three
    forms reuse them unchanged, and a shared driver is factored out of
    `EmitCaseArmTestAndBind`.** Every admission gate and every lane of the
    engine keys on that kind or that entry: bindings
    (handle_binding_pattern.cpp:510-527), compile-time bindings (:649-654),
    `var` (handle_let_and_var.cpp:146-165), the test pass reading
    `match_case_stack().back()` for TODO locations and the resolved
    alternative (pattern_match.cpp:1197-1198, :565-569, :1413-1416), and
    W-077's struct-pattern gate (`CurrentKind() == Kind::MatchCaseArm`,
    fork/w077/plan.md §1.1). Reusing them means "everything the match
    engine admits, the new forms admit; everything it gates, they gate,
    with the engine's own TODO strings" — the requirement in the brief.
    Two mechanical consequences: (a) `FullPatternStack::StartPatternInitializer`
    /`EndPatternInitializer` CHECK the kind is `NameBindingDecl` or
    `ClassScopeVarDecl` (full_pattern_stack.cpp:13-14) — the CHECK admits
    `MatchCaseArm` too, because the new forms HAVE an initializer whose
    evaluation must not see the bindings (the tombstone mechanism, :15-33,
    is exactly what §1.8 relies on); the `next_var_index_stack_` arming
    at :33 is harmless for the on-demand-storage lane (`PopFullPattern`'s
    CHECK at full_pattern_stack.h:155-158 compares against an empty
    `var_pattern_stack_` frame, `0 == 0`); (b) the kind's comment
    (full_pattern_stack.h:48-49) is reworded to "the pattern of a `match`
    `case` arm, a pattern condition, or a `let`-`else` — the refutable
    contexts". The driver (§2.3) is the body of `EmitCaseArmTestAndBind`
    minus the match-only usefulness and coverage blocks
    (handle_match.cpp:818-956; drift refreshed 2026-09-27, review fold: rev
    1 F9), which stay in the `match` caller; so `match_statement_stack` is
    never touched by the new forms (§1.7). The exact line-range ownership
    map is in §2.2.
    Rejected: a new `Kind::RefutableBinding` (§7 A-5) — it would need
    every gate site above to test two kinds for identical behavior.
    Break condition: a reviewer showing a gate site whose `MatchCaseArm`
    behavior is WRONG for the new forms — then that one site tests a
    new `Context` flag (`refutable_binding_kind`) and everything else
    stands.

5.  **CHECK, scoping.** Binding names enter the CURRENT lexical scope at
    pattern-check time ("Add name to lookup immediately",
    handle_binding_pattern.cpp:357-366), so the scope that owns a form's
    bindings must be on the scope stack before its pattern is checked:
    -   **if-let: a dedicated scope, pushed at `PatternConditionIntroducer`
        and popped before the `else` arm.** The introducer handler pushes
        `ScopeStack::PushForSameRegion(Owned)` when the node stack's top is
        the `IfConditionStart` solo node (the `MatchCaseIntroducer`
        precedent, handle_match.cpp:324). To make that possible,
        `HandleParseNode(IfConditionStartId)` — a no-op today,
        handle_if_statement.cpp:13-16 — pushes its node id
        (`WhileConditionStart` and `ForHeaderStart` already push theirs,
        handle_loop_statement.cpp:99, :141); no SemIR changes. **Node-stack
        protocol (amended 2026-09-27, review fold: rev 1 F8):** the
        introducer handler CONSUMES the `IfConditionStart` solo node
        (`PopAndDiscardSoloNodeIdIf<IfConditionStart>()`, node_stack.h:178
        — true means if-let, push the scope; false means the top is the
        `WhileConditionStart` entry, which carries the loop header id and
        is left for `WhileCondition`) and then pushes its own node id.
        `IfCondition`'s pattern path pops the initializer solo node, the
        pattern and the initializer expression but LEAVES the
        `PatternConditionIntroducer` solo node beneath its own
        `(node_id, else_block_id)` entry; `IfCondition`'s expression path
        pops the `IfConditionStart` solo node itself (its one added line).
        The scope is popped (with `AddAndDiscardScopeCleanups` first, the
        `CodeBlock` discipline, handle_codeblock.cpp:19-24) in the
        then-block at `IfStatementElse` (before the else block is pushed)
        or, with no `else`, at `IfStatement`'s `IfCondition` case before
        the branch (handle_if_statement.cpp:56-66): both do
        `Pop<IfCondition>()` and then
        `PopAndDiscardSoloNodeIdIf<PatternConditionIntroducer>()`, popping
        the scope exactly when that returns true. The draft's
        `context.parse_tree_and_subtrees().ExtractAs<Parse::IfCondition>`
        mechanism is withdrawn: it has no precedent in check and builds the
        whole subtree map (context.h:87-89) for one bit. Result: the
        bindings are visible in the then-block only — not in `else`, not
        after — mirroring case-arm scoping
        (toolchain/check/testdata/match/fail_binding_scope.carbon). The pop
        runs `check_unused = true`, so an unused if-let binding warns
        `UnusedBinding` (unused.cpp:47-49) like any local.
    -   **while-let: the existing loop scope.** `WhileConditionStart` pushes
        an `Owned` scope covering header and body (handle_loop_statement.cpp:
        98) and `FinishLoopBody` pops it (:89-90); bindings are added into
        it at pattern time and rebound each iteration by the bind pass in
        the body block. Nothing new.
    -   **let-else: the enclosing scope, no push** — the `let` discipline
        (`HandleIntroducer`, handle_let_and_var.cpp:65-79 pushes no scope),
        which is the design's requirement (if-let.md:316-321,
        "ordinary `let`/`var` bindings of the enclosing scope").

6.  **CHECK, deferred alternative resolution (the first of the two engine
    lanes; the second is §1.1's var-alternative lane).**
    `HandleParseNode(AlternativePatternId)` (handle_match.cpp:370-563;
    line numbers refreshed 2026-09-27, review fold: rev 1 F9)
    gains a deferred mode, entered when
    `match_case_stack().back().scrutinee_type_id` is `None` (the value the
    new forms push, since the initializer has not been checked). In that
    mode the handler does only the scrutinee-independent half of its
    work: it pops the payload list and name exactly as today (:376-389),
    synthesizes the root `TuplePattern` over the payload subpatterns
    exactly as today (:525-553; for the bare `.Name` spelling it
    synthesizes an EMPTY `TuplePattern`, so the root is always a tuple
    pattern), computes `payload_is_irrefutable` (:516-523), records
    `MatchCaseContext::pending_alternative = {name_id, node_id, has_parens,
    root_id, payload_is_irrefutable}` (a new optional struct), and pushes
    the root. Resolution runs at the start of the shared test driver
    (§2.3 step 2) once the scrutinee is known, in a new function
    `ResolvePendingAlternative(context, case_context, scrutinee_id)`
    factored out of the existing handler so that `match` and the new
    forms share one body (the exact move list is in §2.2): the choice
    gate (:393-400 — under the new forms the TODO location is the form's
    introducer node), the `LookupChoiceAlternative` (:408-409), the
    parens-iff-parameters rules (`MatchAlternativeUnexpectedParens`
    :417-424, `MatchAlternativeMissingParens` :458-465), the standard
    member-access diagnostic for an unknown name (:425-426, emitted into
    the current block — no expression region is involved), and
    `MatchAlternativeArgCountMismatch` (:476-505). On success it fills
    `case_context.alternative = {index, payload_field_index,
    payload_pattern_id = root_id, payload_is_irrefutable}` — for the bare
    spelling too, with the empty root. The engine then needs no new lane
    for the `let` spelling (the `var` spelling's lane is §1.1):
    `MatchCaseAlternativePatternMatch` (pattern_match.cpp:561-603 for the
    part that matters) reads only `alternative`; with
    `payload_is_irrefutable` it returns the discriminant test alone
    (:599-603) or constant `true` for a single-alternative choice
    (:578-597), never touching the root; and the bind pass skips a
    binding-free root (`MatchCasePatternHasBindings`, handle_match.cpp:
    1009, :1035). The `designator_root_id` lane
    (pattern_match.cpp:1215-1245) stays `match`-only. Break condition: a
    review finding that the empty-root trick breaks an engine CHECK —
    then the bare spelling records `payload_pattern_id = None` and the
    driver classifies "alternative && !payload_pattern_id" as the
    discriminant-only lane explicitly; same SemIR.

7.  **Usefulness / exhaustiveness: structurally unreachable, not
    suppressed.** Both blocks live in `EmitCaseArmTestAndBind`
    (handle_match.cpp:818-956) and read `match_statement_stack().back()`,
    which only `MatchStatementStart` pushes (:306-316); the factored
    driver (§2.3) does not contain them and the new forms never push a
    `MatchStatementContext`. `DiagnoseDeadDefault`/`DiagnoseNonexhaustiveMatch`
    run from `MatchDefault`/`MatchGuardedDefault`/`MatchStatement` handlers
    only (:1339, :1355; :1594 — refreshed 2026-09-27, review fold: rev 1
    F9).
    A nested `match` inside an if-let body pushes and pops its own
    contexts (LIFO). The `?` bans: `?` inside the pattern (a binding's
    type expression) is at region depth > 1 and stays banned
    (handle_question.cpp:180-189); `?` in the INITIALIZER is legal — the
    initializer is checked at depth 1 after `EndExprRegionForPattern`
    closed the pattern's region (§2.3 step 1), and `in_case_guard` reads
    `match_case_stack().back().else_block_id`, which the new forms leave
    `None` (the success/else blocks ride the node stack, §2.3). Pinned
    both ways in §4.

8.  **`let`-`else` divergence = the toolchain's reachability predicate,
    and the bindings are tombstoned throughout the `else` block.** At
    `LetElseDecl`, if `IsCurrentPositionReachable(context)`
    (control_flow.cpp:126-139) is true at the end of the else block,
    diagnose `LetElseBlockFallsThrough` (§2.5). This is the predicate the
    function-end missing-`return` check uses (handle_function.cpp:749-757),
    and `return`/`break`/`continue` each end their block and push an
    unreachable block (handle_return_statement.cpp:53-58,
    handle_loop_statement.cpp:284-285, :309-310), so the design's
    syntactic list (if-let.md:316-321; F-011 "syntactic divergence list in
    0.1 (return/break/continue)", fork/decision-log.md:1314-1316) is
    accepted in full, and so is a block whose
    every path diverges
    (`else { if (c) { return 1; } else { return 2; } }`, because
    `AddConvergenceBlockAndPush` yields an unreachable block when no
    predecessor is reachable, control_flow.cpp:54-65). `else { Abort(); }`
    is still rejected (no noreturn typing; if-let.md:318-320 defers that
    to the error-handling design), and so is a nested `if` WITHOUT `else`
    (`else { if (c) { return 1; } }` — the convergence block is reachable
    from the false edge). **This is a DEVIATION from F-011's literal list,
    accepting a strict superset (amended 2026-09-27, review fold: rev 1 F7
    -   rev 2 M4)**: it is recorded as an explicit F-011 amendment, **F-011a:
        else-block divergence = reachability predicate
        (`IsCurrentPositionReachable`), overruling the literal
        return/break/continue list**, in the §8.5 decision-log spec, with its
        break condition and fallback; the pattern_matching.md amendment states
        the precise rule (§2.6). Break condition: the owner vetoing F-011a —
        then the check becomes a parse-node-kind test on the else block's last
        statement (`ReturnStatement`/`BreakStatement`/`ContinueStatement`), one
        function, same diagnostic; the all-paths-diverge block and every other
        superset case become errors. Bindings inside the else block: the names
        are in the enclosing scope from pattern time (§1.5), but they are never
        initialized on the else path — so the `StartPatternInitializer`
        tombstones (full_pattern_stack.cpp:15-33; they make a use diagnose
        `UsedBeforeInitialization`, pinned at toolchain/check/testdata/let/
        fail_use_in_init.carbon) are kept live through the else block and
        released by `EndPatternInitializer` only at `LetElseDecl`, before the
        bind pass. Zero new machinery; pinned in §4.

9.  **`let`-`else` outside a function body is an error at the
    introducer.** The parser cannot tell statement `let` from file/class
    scope `let` (both reach `StateKind::Let`, handle_decl_scope_loop.cpp:
    140-143), so `let x: i32 = 1 else { }` parses everywhere and check
    gates it: `LetElseOutsideFunction` when
    `!context.scope_stack().IsInFunctionScope()` (scope_stack.h:143), then
    `return false`. **Accurately (amended 2026-09-27, review fold: rev 1
    F6): `return false` from a `HandleParseNode` aborts checking of the
    whole FILE, not the declaration** — `CheckUnit::ProcessNodeIds`'s
    traversal loop returns false on the first handler that does
    (check_unit.cpp:410-416, after CHECKing an error was diagnosed), so no
    later node in the file is checked; that is also exactly what
    `context.TODO` does. The fail_file_scope / fail_class_scope pins in §4
    therefore show truncated output (nothing after the offending `let` is
    checked), and each is its own split file so the truncation reaches no
    sibling. Design basis:
    the else block must `return`/`break`/`continue` (if-let.md:316-321),
    none of which exists outside a function.

10. **Irrefutable patterns warn.** Per if-let.md:327-329 and F-011:
    `IrrefutablePatternAlwaysMatches` (Warning) when the pattern cannot
    fail — `IsIrrefutableMatchCasePattern(root)` (pattern_match.h:144-145)
    for non-alternative roots, or a resolved alternative whose choice has
    a single alternative and whose payload is irrefutable (that arm is a
    constant-`true` test, pattern_match.cpp:578-590, and handle_match.cpp:
    142-150). Checked after resolution (§2.3 step 3), because the empty
    synthetic root of a bare `.Name` is itself "irrefutable".

11. **`and`/`or` at the top level of a pattern-condition initializer is
    reserved, by a check-time error.** The design keeps `)` right after
    the initializer so let-chains can be added later (if-let.md:330-334).
    Today `e and c` is a legal initializer expression, and no single
    ambient precedence excludes only `and`/`or`: `LogicalAnd`/`LogicalOr`
    are incomparable with `As` and `Where` (precedence.cpp:31-33), so a
    tighter precedence would also force parentheses around `x as T`.
    Instead the `IfCondition`/`WhileCondition` pattern path inspects the
    initializer's parse node kind (`PopExprWithNodeId`, node_stack.h:188;
    check inspecting node kinds is precedented at handle_function.cpp:58)
    and diagnoses `PatternConditionChainReserved` for
    `ShortCircuitOperatorAnd`/`ShortCircuitOperatorOr` roots; the
    parenthesized form `(e and c)` is a `ParenExpr` root and passes.
    `let`-`else` initializers are not restricted (Rust's `let`-`else` has
    no chains either).

12. **The `if`-expression ambiguity (if-let.md:322-326; the ambiguity itself
    :201-203): forbidden at the `else`, plus a targeted recovery for the
    misparse.** (a) In `HandleLetFinish`/`HandleVarFinish`, when the next token
    is `else` and the initializer's root node
    (`context.tree().node_kind(NodeId(size-1))`, context.h:475, tree.h:121) is
    `IfExprElse`, diagnose `LetElseUnparenthesizedIfExpr` and mark the
    declaration errored (it is still parsed as a `let`-`else` for recovery); (a)
    is gated on `!context.tree().node_has_error(last)` so that when (b) below
    already diagnosed and errored the if-expression, a line gets exactly ONE
    `LetElseUnparenthesizedIfExpr` (amended 2026-09-27, review fold: rev 1 F3).
    (b) In `HandleIfExprFinishThen` (handle_if_expr.cpp:34-54), before consuming
    `else`: if the next-next token is `{`, **the token after that `{` is neither
    `.` nor `}`** (struct literals start `{.` or are `{}`, so `var s: {.a: i32} =
    if c then t else {.a = 1};` keeps parsing as an if-expression — pinned as a
    positive in §4; amended 2026-09-27, review fold: rev 1 F3), and the state
    stack below is `[…, LetFinishAsRegular | VarFinish, IfExprFinish]` (the
    if-expression is the whole initializer — state-stack inspection is
    precedented at handle_expr.cpp:249-255 and context.cpp:449-456), emit the
    same diagnostic, do NOT consume the `else`, and return the if-expression
    with an error (`ReturnErrorOnState` plus the ONE `AddInvalidParse` the
    existing missing-`else` path adds for the final operand, :51 — the missing-`then`
    path adds two, :28-29, because it substitutes both `IfExprThen` and the
    final operand; the draft's "two" was wrong); `HandleLetFinish` then sees
    `else` and parses the `let`-`else`, so the user gets one diagnostic and a
    sane tree. Without (b) the user sees the struct-literal error the design
    paper describes (:201-203).

13. **Root `.Name` peek in `let`/`var` too.** `let .Some(port: i32) = e
    else` requires `HandleLet`/`HandleVar` (handle_let.cpp:13-25,
    handle_var.cpp:11-33) to route a root `.` `Identifier` to
    `StateKind::MatchCaseAlternativePattern`, exactly as
    `HandleMatchCaseIntroducer` does (parse/handle_match.cpp:163-171);
    the parser cannot know about the `else` yet, so plain `let .X = e;`
    also becomes an `AlternativePattern` root. Check's `AlternativePattern`
    handler therefore gains a first branch: when
    `full_pattern_stack().CurrentKind() != Kind::MatchCaseArm` (a plain
    `let`/`var`), ``context.TODO(node_id, "alternative pattern outside a
    refutable pattern context")`` — the same disposition (a TODO, not the
    design's error) that `let 5 = x;` has today (§0.8). Churn: none — no
    testdata, example or `core/` source has a `let .`/`var .` root (§6.1).

14. **Zero lower/ changes; two formatter label entries.** The forms emit
    `BranchIf`/`Branch`/`NameBindingDecl` and the engine's comparison
    insts, all lowered today (toolchain/lower/handle.cpp:147, :208;
    match's lower goldens toolchain/lower/testdata/match/*.carbon). Block
    labels come from `BranchNames::For(node_kind)` (toolchain/sem_ir/
    inst_namer.cpp:445-497): if-let branches from the `IfCondition` /
    `IfStatement` nodes, so it prints `!if.then`/`!if.else`/`!if.done`
    (toolchain/check/testdata/if/basics.carbon:141-153); while-let from
    `WhileCondition` → `!while.body`/`!while.done`; `let`-`else` branches
    from the new `LetElse` node, which gets
    `{.prefix = "let", .branch_if = "then", .branch = "else"}` so goldens
    read `!let.then`/`!let.else` instead of the anonymous default. A
    formatter-only edit; no existing label moves (new kind).

15. **Diagnostic locations.** Engine TODOs stay pinned to
    `match_case_stack().back().introducer_node_id`, which the new forms
    set to their introducer (`PatternConditionIntroducer` /
    `LetElseIntroducer`), so every gate points at the `let`/`var` token of
    the form — the analogue of the `case` token. The scrutinee-shape
    TODO points at the initializer expression.

## §2 Implementation spec

### §2.1 Parse

**node_kind.def** (toolchain/parse/node_kind.def): after `LetDecl` (:248)
add

```text
CARBON_PARSE_NODE_KIND_STATEMENT(LetElseIntroducer)
CARBON_PARSE_NODE_KIND_STATEMENT(LetElse)
CARBON_PARSE_NODE_KIND_STATEMENT(LetElseDecl)
```

and before `IfConditionStart` (:277) add

```text
CARBON_PARSE_NODE_KIND_STATEMENT(PatternConditionIntroducer)
CARBON_PARSE_NODE_KIND_STATEMENT(PatternConditionInitializer)
```

(the `_STATEMENT` macro is a clustering hint only; categories come from
`Define`, node_kind.def:10-37). The parse coverage test requires every new
kind to appear in a parse golden (toolchain/parse/coverage_test.cpp:12-25)
— §4 covers all five.

**state.def** (toolchain/parse/state.def): two states, documented in the
file's example style (:17-35):

```text
// Handles a pattern condition after its pattern: adds the VariablePattern
// wrapper for the `var` spelling, then the `=` and the initializer.
//
// if/while ( let ... = ...
//                   ^
//   1. Expr
//   2. ParenConditionFinishAs(If|While)
//
// if/while ( let ... ???
//                   ^
//   2. ParenConditionFinishAs(If|While)   (state done, error)
CARBON_PARSE_STATE(PatternConditionAfterPattern)

// Handles the end of a `let`-`else` declaration after its else block.
//
// let ... = ... else { ... }
//                           ^
//   (state done)
CARBON_PARSE_STATE(LetElseFinish)
```

**handle_paren_condition.cpp** — `HandleParenCondition` (:13-32) gains the
peek between the `{` recovery and the `Expr` push:

```cpp
  } else if (context.PositionIs(Lex::TokenKind::Let) ||
             context.PositionIs(Lex::TokenKind::Var)) {
    // A pattern condition: `(let P = e)` / `(var P = e)`. `let` and `var`
    // never begin an expression (`var` occurs only after `form(`), so a
    // single-token peek is unambiguous (fork/design-sprint/if-let.md,
    // "Implementation realities").
    auto introducer = context.Consume();
    context.AddLeafNode(NodeKind::PatternConditionIntroducer, introducer);
    context.PushState(StateKind::PatternConditionAfterPattern, introducer);
    PushRootPattern(context, /*in_var_pattern=*/
                    context.tokens().GetKind(introducer) == Lex::TokenKind::Var);
  } else {
    context.PushState(StateKind::Expr);
  }
```

`PushRootPattern` is the root-alternative peek factored out of
`HandleMatchCaseIntroducer` (parse/handle_match.cpp:158-178: `.` `Identifier` →
`PushStateForPattern(MatchCaseAlternativePattern, …)`, else `Pattern`), taking
`in_var_pattern`, and is called from `HandleLet`, `HandleVar` and
`HandleMatchCaseIntroducer` too (§1.13). It lives in handle_pattern.cpp with a
declaration in handle.h. The `MatchCaseAlternativePattern` states (:181-212)
already propagate `in_var_pattern` into the payload list (:193-196).

**Root `var` before the peek (amended 2026-09-27, review fold: re-review
M2).** `HandleMatchCaseIntroducer` peeks `.` ONLY
(parse/handle_match.cpp:163-171), so today `case var .Some(n: i32)` — the
shape §1.1's lane and the §4 `root_var` row need — misparses: `var` routes
to `StateKind::Pattern`, whose `Var` case pushes `VariablePattern`
(handle_pattern.cpp:25-30); `HandleVariablePattern` consumes the `var` and
pushes a plain `Pattern` (handle_var.cpp:100-106), in which the leading `.`
falls to the `default:` arm and becomes an `ExprPattern`
(handle_pattern.cpp:49-64), never `MatchCaseAlternativePattern`. So
`PushRootPattern(context, in_var_pattern)` handles a root `var` itself:
when the position is `var` and the next token is `.` (`Lookahead` reaches
one token, parse/context.h:28-31, so the `Identifier` check follows the
consume), it consumes the `var` and pushes `FinishVariablePattern` at the
`var` token (`PushState(StateKind, Lex::TokenIndex)`, context.h:345-347 —
the state `HandleVariablePattern` leaves behind, handle_var.cpp:98-100;
`HandleFinishVariablePattern`, :109-118, then emits the `VariablePattern`
node at that token — `var` has budget 2, §0.1, so the wrapper node is paid
for), then runs the ordinary peek at the `.`: `.` `Identifier` →
`MatchCaseAlternativePattern` with `in_var_pattern=true` (the payload list
inherits it, :193-196, so a nested `var` still diagnoses `NestedVar`,
handle_var.cpp:93-97); anything else → `Pattern` with
`in_var_pattern=true`, exactly what `HandleVariablePattern` would have
pushed, so every non-alternative `var` root parses as today. The new forms
never reach this branch: their `var` is consumed as the
`PatternConditionIntroducer` / `VariableIntroducer` before
`PushRootPattern` runs, and their wrapper node is added by
`HandlePatternConditionAfterPattern` / `HandleVarAfterPattern`. Pinned by
the §4 parse golden toolchain/parse/testdata/match/var_alternative.carbon.

`HandlePatternConditionAfterPattern` (new, handle_paren_condition.cpp):

```cpp
auto HandlePatternConditionAfterPattern(Context& context) -> void {
  auto state = context.PopState();
  if (context.tokens().GetKind(state.token) == Lex::TokenKind::Var) {
    // Mirror `var` declarations: the whole pattern is a `var` pattern.
    context.AddNode(NodeKind::VariablePattern, state.token, state.has_error);
  }
  if (state.has_error) {
    if (auto next = context.FindNextOf({Lex::TokenKind::Equal,
                                        Lex::TokenKind::CloseParen})) {
      context.SkipTo(*next);
    }
  }
  if (auto equals = context.ConsumeIf(Lex::TokenKind::Equal)) {
    context.AddLeafNode(NodeKind::PatternConditionInitializer, *equals);
    context.PushState(StateKind::Expr);
  } else {
    CARBON_DIAGNOSTIC(ExpectedPatternConditionInitializer, Error,
                      "expected `=` after the pattern in a pattern condition");
    context.emitter().Emit(*context.position(),
                           ExpectedPatternConditionInitializer);
    context.AddLeafNode(NodeKind::PatternConditionInitializer,
                        *context.position(), /*has_error=*/true);
    context.AddInvalidParse(*context.position());
    context.ReturnErrorOnState();
  }
}
```

The `has_error` propagation reaches `ParenConditionFinishAs(If|While)`
(below on the stack), whose `ConsumeAndAddCloseSymbol` (context.cpp:87-106)
skips to the matching `)` on error exactly as for a malformed expression
condition. The `Expr` is pushed with the default `ForTopLevelExpr`
precedence, as the expression condition is (handle_paren_condition.cpp:30).

**handle_let.cpp / handle_var.cpp** — `HandleLetFinishAsRegular` (:121-123)
and `HandleVarFinish` (:76-89) gain the `else` peek before the `;` check:

```cpp
  if (context.PositionIs(Lex::TokenKind::Else)) {
    // `let P = e else { ... }`: a let-else declaration. Re-kind the
    // introducer so check sees the refutable context from the start.
    // §1.12(a); gated on `!node_has_error` so a line that §1.12(b)
    // already diagnosed gets one diagnostic (review fold: rev 1 F3).
    auto last = NodeId(context.tree().size() - 1);
    if (context.tree().node_kind(last) == NodeKind::IfExprElse &&
        !context.tree().node_has_error(last)) {
      CARBON_DIAGNOSTIC(LetElseUnparenthesizedIfExpr, Error,
                        "`if` expression initializer of a `let`-`else` "
                        "declaration must be parenthesized");
      context.emitter().Emit(*context.position(), LetElseUnparenthesizedIfExpr);
      state.has_error = true;
    }
    context.ReplaceIntroducerNode(state.subtree_start, introducer_kind,
                                  NodeKind::LetElseIntroducer);
    context.AddLeafNode(NodeKind::LetElse, context.Consume());
    context.PushState(state, StateKind::LetElseFinish);
    context.PushState(StateKind::CodeBlock);
    return;
  }
```

(`introducer_kind` is `LetIntroducer` or `VariableIntroducer` per caller;
`HandleLetFinishAsAssociatedConstant` is untouched.) `HandleLetElseFinish`
pops its state and adds `LetElseDecl` at the introducer token
(`context.tree().node_token(NodeId(state.subtree_start))`), propagating
`state.has_error`. A non-`{` after `else` is handled by `HandleCodeBlock`'s
existing `ExpectedCodeBlock` recovery (handle_code_block.cpp:17-26). The
`Context::ReplaceIntroducerNode` helper:

```cpp
auto Context::ReplaceIntroducerNode(int32_t position, NodeKind old_kind,
                                    NodeKind new_kind) -> void {
  CARBON_CHECK(position >= 0 && position < tree_->size(), ...);
  auto* node_impl = &tree_->node_impls_[position];
  CARBON_CHECK(node_impl->kind() == old_kind, "{0}", node_impl->kind());
  *node_impl = Tree::NodeImpl(new_kind, node_impl->has_error(), node_impl->token());
}
```

**handle_if_expr.cpp** — `HandleIfExprFinishThen` (:34-54): the §1.12(b)
recovery, before `ConsumeChecked(Else)` (:41): fires only when
`PositionIs(Else)`, the token after `else` is `{`, the token after that
`{` is neither `.` nor `}`, and the state stack below reads
`[…, LetFinishAsRegular | VarFinish, IfExprFinish]`; it then emits
`LetElseUnparenthesizedIfExpr`, adds ONE `AddInvalidParse` for the
missing else-operand (mirroring :51) and `ReturnErrorOnState()`, leaving
`else` unconsumed (amended 2026-09-27, review fold: rev 1 F3).

**token_kind.def:193** — `Else` wrapped in `CARBON_TOKEN_WITH_VIRTUAL_NODE`
(§0.1).

**typed_nodes.h** — per §1.2/§1.3. `handle.h`/`state.h` x-macro
declarations follow from the `.def` edits.

### §2.2 Check: new file `toolchain/check/refutable_binding.{h,cpp}`

Added to the explicit `srcs`/`hdrs` lists in toolchain/check/BUILD (the
library lists sources by name, BUILD:50-69, :118). It hosts the shared
driver used by `match` and the three forms, so handle_match.cpp shrinks:

```cpp
// Starts a refutable pattern context: pushes the `let` introducer state,
// a pattern block, a `MatchCaseArm` full-pattern frame, an expression
// region, and a `MatchCaseContext` whose scrutinee type is `None` (the
// scrutinee is checked after the pattern; alternatives resolve at test
// time) and whose TODO location is `introducer_node_id`.
auto BeginRefutableBinding(Context& context, Parse::NodeId introducer_node_id)
    -> void;

// Ends the pattern of a refutable pattern context and starts its
// initializer: the `FinishCasePattern` body MINUS its pop
// (handle_match.cpp:583-597 — initializing-category conversion of a
// leftover expression, `EndExprRegionForPattern`), then
// `StartPatternInitializer`. The pattern root is LEFT on the node stack —
// the `HandleDecl` order for `let`/`var` (handle_let_and_var.cpp:289-318:
// the initializer is popped first, `PopPattern` runs at :318) — and the
// form's close handler pops it exactly once and passes it to
// `EmitRefutableBindingTest`. `match` keeps `FinishCasePattern` as this
// plus the pop into `MatchCaseContext::pattern_id`.
// (amended 2026-09-27, review fold: rev 1 F2)
auto EndRefutableBindingPattern(Context& context) -> void;

// Returns whether `type_id` is a scrutinee shape the engine dispatches on
// (moved from handle_match.cpp `IsSupportedScrutineeType`, :179-221).
auto IsSupportedScrutineeType(Context& context, SemIR::TypeId type_id) -> bool;

// The scrutinee gate shared with `MatchCondition` (:228-298): value-or-ref
// conversion, `RequireCompleteType` with the `IncompleteTypeInMatchScrutinee`
// context note, the shape gate (TODO `todo_string`), temporary cleanup.
// Returns the converted scrutinee, or `None` after a diagnostic that
// aborts checking.
auto CheckRefutableScrutinee(Context& context, Parse::NodeId node_id,
                             SemIR::InstId scrutinee_id,
                             llvm::StringLiteral todo_string) -> SemIR::InstId;

// Test pass. `pattern_id` is the finished root; resolves a pending
// alternative against the scrutinee's type, classifies the root exactly as
// `EmitCaseArmTestAndBind` does (handle_match.cpp:779-822), attaches the
// pattern block to a `NameBindingDecl` in the current block, and returns
// the bool condition inst (`ErrorInst` for an errored pattern, `None`
// after an aborting TODO). Emits `IrrefutablePatternAlwaysMatches` when
// `warn_irrefutable` and the pattern cannot fail. Pops NOTHING: the
// full-pattern frame and the case context stay pushed; the CALLER pops
// them (`match` before its branches, the new forms after the bind pass).
//
// The struct is the driver contract between the two passes (amended
// 2026-09-27, review fold: re-review M3). It is defined in context.h as
// `Context::MatchCaseContext::RefutableBindingTest`, nested right after
// `Alternative` (which it holds) and before the `let_else_test` member
// that stores one, so a `let`-`else` can park it in the case context
// between `LetElse` and `LetElseDecl` (§2.3, §2.4); refutable_binding.h
// re-exports it with a `using` alias.
struct RefutableBindingTest {
  // The arm's bool condition (`ErrorInst` for an errored pattern). The
  // bind lanes gate on `cond_id != SemIR::ErrorInst::InstId`, as
  // handle_match.cpp:991-992, :1007 and :1034 do today.
  SemIR::InstId cond_id;
  // The classification, exactly the flags `EmitCaseArmTestAndBind`
  // computes (handle_match.cpp:776-816 plus §1.1's `is_var_alternative_arm`).
  // `match` feeds the first three into `has_irrefutable_arm` (:939-941).
  bool is_binding_arm;
  bool is_irrefutable_var_arm;    // §1.1: excludes is_var_alternative_arm
  bool is_irrefutable_tuple_arm;
  bool is_alternative_payload_arm;
  bool is_tuple_arm;
  bool is_var_alternative_arm;
  // The warn predicate (§1.10) — SEPARATE from the three flags above: for
  // a var-alternative arm it is "single alternative and irrefutable
  // payload", which sets none of them.
  bool is_irrefutable;
  // The resolved alternative, copied AFTER `ResolvePendingAlternative`:
  // in `match` the case context is popped (:963) BEFORE the bind pass,
  // which is why :752 copies it today.
  std::optional<Context::MatchCaseContext::Alternative> alternative;
};
auto EmitRefutableBindingTest(Context& context, Parse::NodeId node_id,
                              SemIR::InstId pattern_id,
                              SemIR::InstId scrutinee_id,
                              bool warn_irrefutable)
    -> std::optional<RefutableBindingTest>;

// Bind pass, in the current (success) block: the lane selection of
// handle_match.cpp:977-1048 keyed on `test`'s flags (`LocalPatternMatch`
// for all-binding `var`-free trees, `MatchCaseBindPatternMatch` otherwise,
// payload extraction for `test.alternative`, §1.1's var-alternative lane),
// each lane gated on `test.cond_id != ErrorInst` as today, then
// `DeferCleanups`. Pops NOTHING (amended 2026-09-27, review fold:
// re-review M3 — the :958-964 pops have one owner, the caller).
auto EmitRefutableBindingBind(Context& context, Parse::NodeId node_id,
                              SemIR::InstId pattern_id,
                              SemIR::InstId scrutinee_id,
                              const RefutableBindingTest& test) -> void;
```

`EmitCaseArmTestAndBind` becomes: `test = EmitRefutableBindingTest` (with
`warn_irrefutable = false` — an irrefutable `case` arm is the exhaustive
arm, not a warning) → the two match-only blocks (usefulness and coverage,
byte-identical, reading `test`'s flags and `test.alternative`; the
var-alternative arm keys usefulness through
`alternative->payload_pattern_id`, §1.1) → `PopFullPattern`/`pop_back` as
today, in the caller → branches →
`EmitRefutableBindingBind(context, node_id, pattern_id, scrutinee_id, test)`.

**Line-range ownership map (amended 2026-09-27, review fold: rev 1 F2;
against trunk f0e1980's `EmitCaseArmTestAndBind`, handle_match.cpp:
733-1051 — on the W-077 branch the function starts at :766 and the ranges
shift accordingly):**

| Lines today | What | Goes to |
| --- | --- | --- |
| :736 `pattern_id = match_case_stack().back().pattern_id` | root lookup | `match` caller keeps it (its root sits in the case context, popped by `FinishCasePattern`); the new forms pass the root they popped ONCE from the node stack |
| :737-738 `PopAndDiscardSoloNodeId<MatchCaseIntroducer>()` | introducer solo node | `match` caller keeps it (match-specific kind). New forms: `IfCondition` LEAVES `PatternConditionIntroducer` for `IfStatementElse`/`IfStatement` (§1.5); `WhileCondition` pops it itself, before `WhileConditionStart`; `LetElse` pops `LetElseIntroducer` at its step 1 |
| :739 `decl_introducer_state_stack().Pop<Let>()` | introducer state | `match` caller keeps it here. `IfCondition`/`WhileCondition` pop it right after the test (step 4a) — nothing in the bind pass reads it: the on-demand storage passes `is_returned_var=false` (pattern_match.cpp:1476-1477) and the only `Returned` reader is the `NameBindingDecl` lane's `add_local_var` (handle_let_and_var.cpp:113-115). `LetElseDecl` pops it LAST (step 5), after the modifier checks that read it |
| :741-746 pattern block pop + `NameBindingDecl` | pattern home | `EmitRefutableBindingTest` |
| :748-753 `introducer_node_id`, `alternative` copy, `PeekScrutinee` | inputs | `EmitRefutableBindingTest`: the scrutinee is a parameter; `introducer_node_id` from the case context; `alternative` is copied AFTER `ResolvePendingAlternative` into `RefutableBindingTest::alternative` (re-review M3) |
| :755-816 classification + test dispatch | test | `EmitRefutableBindingTest`, returning the flags in `RefutableBindingTest`, plus §1.1's `is_var_alternative_arm`, which `is_irrefutable_var_arm` excludes (re-review M1; W-077: plus `is_struct_arm`, :828-833 there) |
| :818-956 usefulness + coverage | match-only | `match` caller, unchanged, between the test and its pops as today, reading `test`'s flags; the var-alternative arm keys through `alternative->payload_pattern_id` (§1.1) |
| :958-964 `PopFullPattern` + `match_case_stack().pop_back()` | frame/context pops | the CALLERS, one owner (amended 2026-09-27, review fold: re-review M3): `match` unchanged at :958-964, before its branches; `IfCondition` (step 6), `WhileCondition` and `LetElseDecl` (step 4) pop right AFTER `EmitRefutableBindingBind`. Neither driver function pops. The ordering difference is safe: the bind lanes read only `test` (its `alternative` copy and flags) and `pattern_id`, never the frame or the context (:748-750 copy note); the on-demand storage lane is keyed on `in_match_case_bind` (pattern_match.cpp:1475-1479), not on the frame's absence; and `PopFullPattern`'s CHECK (full_pattern_stack.h:155-158) still compares `0 == 0` (§1.4) |
| :966-975 branches + then-block switch | control flow | each caller (`match` verbatim; `IfCondition` step 5; `WhileCondition` through `BranchAndStartLoopBody`; `LetElse` step 4) |
| :977-1049 bind lanes | bind | `EmitRefutableBindingBind(…, test)`, plus §1.1's var-alternative lane (W-077: plus the struct lane, :1105 there) |
| :1051 `return else_block_id` | result | `match` caller |

`MatchCaseIntroducer` (:318-346) becomes `scope push;
BeginRefutableBinding(node_id); set scrutinee_type_id = type of
PeekScrutinee()` — the only place the type is filled at pattern time.

**`ResolvePendingAlternative` — exactly what moves (amended 2026-09-27, review
fold: rev 2 m1/m7).** Signature `ResolvePendingAlternative(context, node_id,
scrutinee_type_id, name_id, has_parens, subpattern_count) ->
std::optional<Alternative>`, called from the driver (deferred mode) and from
`HandleParseNode(AlternativePatternId)` (immediate mode, `match`) alike. It
hosts, moved verbatim from handle_match.cpp: the choice gate :393-400 (its TODO
at `match_case_stack().back().introducer_node_id`, which under the new forms is
the form's introducer), the `LookupChoiceAlternative` :408-409,
`MatchAlternativeUnexpectedParens` :417-424, the unknown-name member-access
diagnostic :425-426 (`PerformMemberAccess` for its standard `NameNotFound`; in
deferred mode the result is discarded — the driver runs in the test block with
no pattern region open; in immediate mode it feeds the designator lane as
today), `MatchAlternativeMissingParens` :458-465, the parameter count :476-490
and `MatchAlternativeArgCountMismatch` :491-505, and the `alternative` fill.
STAYS immediate in the handler, in both modes: the §1.13 context TODO, the
payload/name pop :376-389, the `payload_id == ErrorInst` bail :466-468, the
payload collection :469-475 (reordered ahead of the resolution call so
`subpattern_count` is known; no parens gives zero subpatterns, as today's
`param_count` comparison expects), the irrefutability fold :516-523 and the root
synthesis :525-553. STAYS match-only: the designator lane for a constant
alternative :427-454 (`designator_root_id`, the `ExprPattern` wrap, the
`ConsumeExprRegionForPattern`) — the new forms' bare `.Name` uses the empty
synthetic root instead (§1.6).

### §2.3 Check handlers for the new parse nodes

**`PatternConditionIntroducerId`** (new handler, in handle_if_statement.cpp
or a new handle_pattern_condition.cpp):

```cpp
  if (context.node_stack()
          .PopAndDiscardSoloNodeIdIf<Parse::NodeKind::IfConditionStart>()) {
    // if-let: the bindings' scope, popped before the else arm (§1.5). The
    // `IfConditionStart` solo node is consumed here; this introducer node
    // takes its place on the stack, beneath `IfCondition`'s entry.
    context.scope_stack().PushForSameRegion(ScopeStack::CleanupScopeKind::Owned);
  } else {
    // while-let: `WhileConditionStart` carries the loop header id and is
    // left for `WhileCondition`.
    CARBON_CHECK(context.node_stack().PeekIs(Parse::NodeKind::WhileConditionStart));
  }
  BeginRefutableBinding(context, node_id);
  context.node_stack().Push(node_id);
```

**`PatternConditionInitializerId`**: `EndRefutableBindingPattern(context)`;
push node (the pattern stays on the node stack beneath this solo node,
§2.2). (The pattern's region is now closed: the initializer checks at
region depth 1, §1.7.)

**`IfConditionId`** (handle_if_statement.cpp:18-40) — the pattern path,
entered when `PeekIs(PatternConditionInitializer)` (node_stack.h:115)
after `PopExprWithNodeId()` (:188) — the initializer solo node is then on
top (amended 2026-09-27, review fold: rev 2 m1/m7: the draft's
`PeekNextIs` looked one entry too deep):

1.  `PatternConditionChainReserved` if the initializer's node kind is a
    short-circuit operator root (§1.11) — diagnose and continue with the
    value.
2.  `scrutinee = CheckRefutableScrutinee(…, "refutable pattern binding on
    unsupported scrutinee type")`; `None` → `return false`.
3.  `full_pattern_stack().EndPatternInitializer()`; pop the initializer
    solo node, then `pattern_id = PopPattern()` ONCE — the root that
    `EndRefutableBindingPattern` left on the stack (§2.2; amended
    2026-09-27, review fold: rev 1 F2 — the draft popped it twice). The
    `PatternConditionIntroducer` solo node STAYS (§1.5 protocol); the
    `IfConditionStart` node was consumed by the introducer handler.
4.  `test = EmitRefutableBindingTest(…, pattern_id, scrutinee,
    warn_irrefutable = true)`; `nullopt` → `return false`.
    4a. `decl_introducer_state_stack().Pop<Let>()` (the :739 pop, §2.2
    map).
5.  `then = AddDominatedBlockAndBranchIf(cond)`, `else =
    AddDominatedBlockAndBranch()`, pop/push then, `AddToRegion` — the existing
    lines :29-36 verbatim (the labels are `if.then`/`if.else` because the node
    is `IfCondition`).
6.  `EmitRefutableBindingBind(…, pattern_id, scrutinee, *test)` in the
    then block, then `full_pattern_stack().PopFullPattern()` and
    `match_case_stack().pop_back()` — the :958-964 pops, owned by the
    caller (amended 2026-09-27, review fold: re-review M3).
7.  `node_stack().Push(node_id, else_block_id)` — identical to the
    expression path, so `IfStatementElse`/`IfStatement` see the same
    entry; in the pattern path it sits above the
    `PatternConditionIntroducer` solo node.

The expression path is the existing body with one added
`PopAndDiscardSoloNodeId<IfConditionStart>()`.

**`IfStatementElseId`** (:42-52) and **`IfStatementId`**'s `IfCondition` case
(:56-66): `auto else_block_id = Pop<IfCondition>()` as today, then `if
(node_stack().PopAndDiscardSoloNodeIdIf<PatternConditionIntroducer>()) {
AddAndDiscardScopeCleanups(context); scope_stack().Pop(/*check_unused=*/true);
}` in the then block, BEFORE switching to the else block / branching (§1.5;
amended 2026-09-27, review fold: rev 1 F8 — the node-stack protocol replaces the
typed-node extraction). `IfStatement`'s `IfStatementElse` case is unchanged (the
scope was popped at `IfStatementElse`, and the introducer node went with it).

**`WhileConditionId`** (handle_loop_statement.cpp:103-115) — pattern path, same
detection: steps 1-4a as above, except that `WhileCondition` DOES pop the
`PatternConditionIntroducer` solo node (nothing later needs it — the loop scope
is popped by `FinishLoopBody`) before popping `WhileConditionStart`, which
yields `loop_header_id` as today, then `BranchAndStartLoopBody(…, cond)`
verbatim (:44-71 — the `ConvertToBoolValue` is a no-op on a bool; labels
`while.body`/`while.done`), then `EmitRefutableBindingBind(…, *test)` in the
body block, then the `PopFullPattern()`/`pop_back()` pair (the caller owns the
pops; re-review M3). `WhileStatement` (:117-121) is unchanged: `FinishLoopBody`
adds the back-edge to the header — where the initializer is re-evaluated and the
pattern re-tested each iteration — and pops the loop scope, so the bindings end
with the loop. `break`/`continue` inside the body use the `break_continue_stack`
entry `BranchAndStartLoopBody` pushed (:66-70); `continue` destroys header
temporaries (none of consequence: the scrutinee gate admits only trivially
destructible shapes, handle_match.cpp:256-263, the same argument `match` makes).

**`LetElseIntroducerId`**: if `!scope_stack().IsInFunctionScope()` →
`LetElseOutsideFunction`, `return false` (aborts the rest of the file,
§1.9). Else
`decl_introducer_state_stack().Push<Let>()` is done by
`BeginRefutableBinding` (both spellings push `Let`, as `MatchCaseIntroducer`
does at :331 — the `var` spelling's pattern is a `VariablePattern` node,
which is what makes it `var`); push node. NOT pushing a scope (§1.5).

**`LetInitializerId` / `VariableInitializerId`** (handle_let_and_var.cpp:
216-235): first line `if (context.full_pattern_stack().CurrentKind() ==
FullPatternStack::Kind::MatchCaseArm) { EndRefutableBindingPattern(context);
context.node_stack().Push(node_id); return true; }`; the existing body
follows for the other kinds.

**`LetElseId`**:

1.  `PopExprWithNodeId()` → initializer; pop the initializer solo node
    (either kind); `pattern_id = PopPattern()` ONCE (the root
    `EndRefutableBindingPattern` left, §2.2; amended 2026-09-27, review
    fold: rev 1 F2); pop the `LetElseIntroducer` solo node (the :737-738
    analogue). The `Let` introducer STATE is NOT popped here —
    `LetElseDecl`'s modifier checks read it.
2.  `scrutinee = CheckRefutableScrutinee(…, same TODO string)`.
3.  `test = EmitRefutableBindingTest(…, pattern_id, scrutinee,
    warn_irrefutable = true)`.
4.  `then = AddDominatedBlockAndBranchIf(cond)`; `else_block =
    AddDominatedBlockAndBranch()`; `inst_block_stack().Pop()`;
    `Push(else_block)`; `AddToRegion(else_block, node_id)` — the `?`
    desugar's shape (handle_question.cpp:377-395: test, the diverging
    block emitted first, the continuation after).
5.  `node_stack().Push(node_id, then_block_id)`; the pattern, scrutinee
    and test result stay reachable through the case context, which is
    still pushed — `let`-`else`'s pops run at `LetElseDecl` step 4
    (re-review M3): set `match_case_stack().back().pattern_id`
    (already a `MatchCaseContext` field, context.h:289-293; citation
    corrected 2026-09-27, review fold: re-review m4), and the two new
    fields `scrutinee_id` and `let_else_test = *test` (§2.4). The
    tombstones stay live (§1.8).

**`LetElseDeclId`**:

1.  Pop the `CodeBlock` bookkeeping is already done by the `CodeBlock`
    handler; `auto [else_node_id, then_block_id] = PopWithNodeId<LetElse>()`.
2.  `if (IsCurrentPositionReachable(context))` → `LetElseBlockFallsThrough`
    at `else_node_id`; then `AddInst<SemIR::Branch>` to `then_block_id` so
    the CFG stays well-formed (diagnose-and-proceed).
3.  `inst_block_stack().Pop()` (the else block), `Push(then_block_id)`,
    `AddToRegion(then_block_id, node_id)` — labels `let.then`/`let.else`
    (§1.14).
4.  `full_pattern_stack().EndPatternInitializer()` (releases the
    tombstones, §1.8); `EmitRefutableBindingBind(…, case.pattern_id,
    case.scrutinee_id, *case.let_else_test)` in the success block, reading
    the three fields `LetElse` parked in `match_case_stack().back()` — the
    bindings are now initialized on the only path that continues, in the
    enclosing scope, with `DeferCleanups` so they live to the end of that
    scope (the `let` rule, handle_let_and_var.cpp:367-369); then
    `PopFullPattern()` and `match_case_stack().pop_back()` (the caller
    owns the pops; amended 2026-09-27, review fold: re-review M3).
5.  **Modifier checks, verbatim from `LetDecl` (amended 2026-09-27, review fold:
    rev 1 F4 + rev 2 M1 — without them `fail_modifier` in §4 would diagnose
    nothing):** `auto introducer =
    context.decl_introducer_state_stack().innermost();` (a copy, as
    `DeclInfo::introducer` is, handle_let_and_var.cpp:329) — then, first, the
    `returned` rejection: `if
    (introducer.modifier_set.HasAnyOf(KeywordModifierSet::Returned)) {
    Emit(introducer.modifier_node_id(ModifierOrder::Decl),
    ReturnedNotAllowedOnLetElse); introducer.modifier_set.Remove(Returned); }` (`Returned`
    is in the `Decl` modifier group, keyword_modifier_set.h: 149-152, so
    `HandleModifier` files it under `ModifierOrder::Decl`,
    handle_modifier.cpp:58-59; without the rejection the `returned` on `returned
    var P = e else {…}` would be silently dropped — the `MatchCaseArm` `var`
    lane never reads it). Then `CheckAccessModifiersOnDecl(context, introducer,
    parent_scope_inst)` with `parent_scope_inst` computed as at :325-328 (in a
    function body this is what rejects `private`: `ModifierPrivateNotAllowed`, "`private`
    not allowed; requires class or file scope", modifiers.cpp:147-150, pinned
    for a local `var` at
    toolchain/check/testdata/function/definition/fail_local_decl.carbon:40);
    `decl_introducer_state_stack().Pop<Let>()` (:339);
    `LimitModifiersOnDecl(context, introducer, KeywordModifierSet::Access |
    KeywordModifierSet::Interface)` (:341-343 — `virtual` etc. diagnose
    `ModifierNotAllowedOnDeclaration`, "`virtual` not allowed on `let`
    declaration", pinned at
    toolchain/check/testdata/let/fail_modifiers.carbon:33);
    `RequireDefaultFinalOnlyInInterfaces(context, introducer,
    SemIR::NameScopeId::None, /*is_definition=*/false)` (:348-350). Same calls,
    same order, same mask as `LetDecl` (:329-350), so the two declarations
    reject the same modifiers with the same texts. The diagnostic name is
    spelled with `let` for the `var` spelling too (`LetDecl`'s `{1}` is the
    pushed `Let` introducer kind, and `BeginRefutableBinding` pushes `Let` for
    both spellings, as `MatchCaseIntroducer` does at :331) — accepted; the
    `let`-`else` form is named "`let`-`else`" throughout the design.

SemIR emission order consequence: the success block's insts follow the
else block's in inst-id order. Blocks are independent for lowering, and
the `?` desugar emits its diverging block before its continuation
(handle_question.cpp:383-395); recorded as §7 R-2.

### §2.4 Check: `AlternativePattern` deferred mode and `MatchCaseContext`

context.h `MatchCaseContext` gains

```cpp
    // A root alternative pattern checked before its scrutinee (a pattern
    // condition or `let`-`else`, whose initializer follows the pattern):
    // resolved against the scrutinee's choice type by
    // `ResolvePendingAlternative` when the test pass runs.
    struct PendingAlternative {
      SemIR::NameId name_id;
      Parse::NodeId node_id;
      bool has_parens;
      SemIR::InstId root_id;  // the synthesized payload TuplePattern
      bool payload_is_irrefutable;
    };
    std::optional<PendingAlternative> pending_alternative;
    // The converted scrutinee and the test-pass result of a `let`-`else`,
    // parked by `LetElse` for the bind pass at `LetElseDecl` (the else
    // block is checked in between; the context stays pushed until then).
    // (amended 2026-09-27, review fold: re-review M3)
    SemIR::InstId scrutinee_id = SemIR::InstId::None;
    std::optional<RefutableBindingTest> let_else_test;
```

(`RefutableBindingTest` itself is the nested
`MatchCaseContext::RefutableBindingTest`, declared after `Alternative` and
before this member, §2.2.)

and the `scrutinee_type_id` comment becomes "…or `None` while the
scrutinee is not yet checked (§1.6)". `HandleParseNode(AlternativePatternId)`
order: (1) the §1.13 non-refutable-context TODO; (2) pop payload/name
(:376-388); (3) if `scrutinee_type_id` is `None` → deferred record and
push root (§1.6); (4) else the existing body, with its resolution half
called through `ResolvePendingAlternative`. The empty-root synthesis for a
bare `.Name` reuses the `TuplePattern` synthesis at :518-553 with zero
elements (`GetTupleType` of no elements is the `()` type).

### §2.5 Diagnostics (toolchain/diagnostics/kind.def), alphabetized within

their groups

Parser section, new group after "If-specific diagnostics" (:197-199):

```text
// Pattern condition and let-else diagnostics.
CARBON_DIAGNOSTIC_KIND(ExpectedPatternConditionInitializer)
CARBON_DIAGNOSTIC_KIND(LetElseUnparenthesizedIfExpr)
```

Check section, new group after "Let declaration checking" (:444-445):

```text
// Refutable pattern binding checking (if-let, while-let, let-else).
CARBON_DIAGNOSTIC_KIND(IrrefutablePatternAlwaysMatches)
CARBON_DIAGNOSTIC_KIND(LetElseBlockFallsThrough)
CARBON_DIAGNOSTIC_KIND(LetElseOutsideFunction)
CARBON_DIAGNOSTIC_KIND(PatternConditionChainReserved)
CARBON_DIAGNOSTIC_KIND(ReturnedNotAllowedOnLetElse)
```

| Kind | Level | Text | Site |
| --- | --- | --- | --- |
| ExpectedPatternConditionInitializer | Error | ``expected `=` after the pattern in a pattern condition`` | parse, §2.1 |
| LetElseUnparenthesizedIfExpr | Error | ``` `if` expression initializer of a `let`-`else` declaration must be parenthesized ``` | parse, §1.12 (a) and (b) |
| IrrefutablePatternAlwaysMatches | Warning | `pattern always matches, so this binding cannot fail` | check, at the introducer node |
| LetElseBlockFallsThrough | Error | ``` `else` block of a `let`-`else` declaration must not complete normally; end it with `return`, `break`, or `continue` ``` | check, at the `else` node |
| LetElseOutsideFunction | Error | ``` `let`-`else` declaration can only be used inside a function body ``` | check, at the introducer |
| PatternConditionChainReserved | Error | ``` `and`/`or` at the top level of a pattern condition's initializer is reserved for pattern chaining; parenthesize the expression ``` | check, at the initializer |
| ReturnedNotAllowedOnLetElse | Error | ``` `returned` not allowed on a `let`-`else` declaration ``` | check, at the `returned` modifier node (§2.3 `LetElseDecl` step 5; new kind rather than `ModifierNotAllowedOnDeclaration`, whose "`returned` not allowed on `let` declaration" would misname the `var` spelling — amended 2026-09-27, review fold: rev 1 F4 + rev 2 M1) |

Reused unchanged: `ExpectedCodeBlock` (missing `{` after `else`),
`IncompleteTypeInMatchScrutinee` (context note text "matching on value of
incomplete type {0}" fits all forms), `UsedBeforeInitialization` (binding
used in the else block, §1.8), `UnusedBinding`, `UnusedPatternNoBindings`,
`MatchAlternativeMissingParens`/`UnexpectedParens`/`ArgCountMismatch`,
`NameNotFound`, `ModifierPrivateNotAllowed`/`ModifierNotAllowedOnDeclaration`/
`ModifierRequiresInterface` (the `LetDecl` modifier checks, §2.3 step 5),
and every engine `SemanticsTodo` string. New
`SemanticsTodo` strings (no new kinds): ``refutable pattern binding on
unsupported scrutinee type`` (the shape gate) and ``alternative pattern
outside a refutable pattern context`` (§1.13).

### §2.6 Docs

**docs/design/pattern_matching.md:**

-   :670-676 (the #1871 sentence): replace "This currently includes all
    pattern matching contexts other than `match` statements, but the
    `var`/`let`-`else` feature in [#1871] would introduce a second context
    permitting refutable matches, and overloaded functions might introduce
    a third context." with "Refutable patterns are permitted in exactly
    three contexts, each of which provides fallback behavior: a `match`
    statement's `case`, a pattern condition of `if` or `while`, and a
    `let`-`else` declaration (see the "Refutable pattern bindings"
    section, linked by its anchor in the real edit). Overloaded functions
    might introduce a further context." (coherence risk 10: the three contexts
    are enumerated in one place). The `var 5 = n;` example (:678-687)
    stays.
-   New subsection `### Refutable pattern bindings` after `#### Guards`
    (:801-815) and before `### Pattern matching in local variables`
    (:817): the grammar of if-let.md:296-303 (both `let` and `var`
    spellings), the semantics of :305-334 (test-and-bind; then-block
    scoping for `if`, body scoping and per-iteration rebinding for
    `while`, enclosing-scope bindings for `let`-`else`; the else block
    must not complete normally, with the 0.1 rule stated PRECISELY as
    F-011a (amended 2026-09-27, review fold: rev 1 F7 + rev 2 M4): "the
    end of the `else` block must be unreachable — every path through it
    ends in `return`, `break` or `continue`; a nested `if` WITHOUT an
    `else`, or one whose `else` completes normally, is rejected, and so is
    a call such as `Abort()` until a noreturn rule exists" (if-let.md:
    318-320); irrefutable patterns warn; p005164 failure destruction unchanged;
    `and`/`or` reserved for chaining; the `if`-expression initializer
    parenthesization rule), the examples of :247-294 adapted to
    p002188 spelling, and a "Bindings are not visible in the `else`
    block; using one there is an error" sentence.
-   :710-714 (the skeletal-design note) is left alone: it is about
    `match`, outside this slice.
-   Table of contents (:11-46) gains the new subsection.

**docs/design/control_flow/conditionals.md:21-27** gains a fourth syntax
line ``if (` `let` | `var` _pattern_ `=` _expression_ `) {` _statements_ `}``
with one sentence and a link to the new subsection;
**docs/design/control_flow/loops.md:32-36** gains the `while (let …)`
line likewise. Design-paper dependency list at if-let.md:559-563 names
exactly these three files.

**docs/design/error_handling.md** (amended 2026-09-27, review fold: rev 2
M3): the section "Consuming results with `let ... else` and
`if (let ...)`" (:163-197) keeps its two examples; its two F-011 links
(:167, :191) are retargeted from `/fork/decision-log.md` to the new
pattern_matching.md anchor (`pattern_matching.md#refutable-pattern-bindings`),
and the sentence :191-197 ("These forms are fixed by fork decision F-011
… is a deliverable of the F-011 workstream, sequenced alongside this
document") becomes one line pointing at the landed subsection. At
:831-835 the clause "until F-011's implementation lands, the
`let ... else` / `if (let ...)` consumption forms are design-only" is
DELETED (the `Core.Result` half of that sentence stays). The other F-011
mentions (:288-289, :908, :949) cite the decision itself and stay.

**docs/design/README.md:3898-3902** (same fold): the sentence "Results are
consumed with `match` and with the combined match control-flow forms
`if (let ...)` and `let ... else` — adopted in fork decision F-011 … with
their own design doc to land with the control-flow work —" drops the
"with their own design doc to land" clause and links the forms to
`pattern_matching.md#refutable-pattern-bindings`.

**fork/gap-analysis.md:64** (retargeted 2026-09-27, review fold: rev 2
M2 — the reconciled trunk moved the row from :57; its text now reads
"Design decided F-011 … W-012 open, planned as a desugaring onto the
landed refutable-match SemIR"): status MISSING → PARTIAL (§8.6); detail
column rewritten. The bullet TEXT is untouched (R7).

## §3 Commit structure

One PR, four reviewable commits, then the discharge commit:

1.  **parse** — §2.1: node kinds, states, typed nodes, the peek, the
    `let`-`else` re-kind, `PushRootPattern`, the if-expression recovery,
    the `Else` budget entry; plus the §4 parse goldens WITH their CHECK
    lines empty (R15/R19). This commit compiles and passes the parse
    coverage test only once the goldens are filled, so its gate is the
    hosted autoupdate (R28(b)).
2.  **check + sem_ir + diagnostics** — §2.2-§2.5: `refutable_binding.{h,cpp}`,
    the `EmitCaseArmTestAndBind` factoring (behavior-preserving for
    `match`: §6 requires zero match golden movement), deferred
    alternative resolution, the new handlers, the `BranchNames` entries,
    kind.def.
3.  **testdata** — §4 check and lower goldens (empty CHECK lines) and the
    two pinned-TODO files.
4.  **conformance + docs** — §5 programs, §2.6 doc edits, the
    gap-analysis row.
5.  **discharge** (after hosted autoupdate to fixpoint, gate, and
    conformance are green) — §8.5 ledger, decision log, this plan's status
    line.

Sizes: parse S, check M, testdata M, conformance/docs S — M-to-L overall,
consistent with the ledger's "M on top of W4".

## §4 Testdata matrix (R16: no hand-written goldens; hosted autoupdate fills)

Every new file carries `// AUTOUPDATE` and empty CHECK lines; positives
carry `//@dump-sem-ir-begin/end` around the function under test
(toolchain/check/testdata/if/basics.carbon:19-27 convention). Bindings in
fail matrices are used or `unused`-marked so no incidental `UnusedBinding`
rides the goldens (fork/w077/plan.md hand-off note).

**Every matrix row is its own `// --- name.carbon` split file** (amended
2026-09-27, review fold: rev 2 m9/m10): a TODO or `return false` aborts
the rest of a FILE (§1.9), so no row may share a file with a sibling it
could truncate; the table rows below are the split-file names.

**Parse — toolchain/parse/testdata/if/if_let.carbon** (positive): subfiles
`let_binding` (`if (let n: i32 = x) {}`), `var_binding`, `alternative_bare`
(`.None`), `alternative_payload` (`.Some(n: i32)`), `tuple` (`(0, n: i32)`),
`else_if_chain` (`if (let …) {} else if (let …) {} else {}` — exercises
`StatementIfThenBlockFinish`'s `else if` special case,
handle_statement.cpp:196-199, with a pattern condition in the chained `if`),
`nested_in_match_arm`, `parenthesized_and` (`(x and y)` initializer).
**fail_if_let_missing_initializer.carbon** (`if (let n: i32) {}` →
`ExpectedPatternConditionInitializer` + recovery to `)`),
**fail_if_let_missing_pattern.carbon** (`if (let = x)` → the pattern parser's
`ExpectedPattern`-family error, recovery pinned).
**toolchain/parse/testdata/while/while_let.carbon** (`let`, `var`, payload
alternative), **fail_while_let_missing_initializer.carbon**.
**toolchain/parse/testdata/let/let_else.carbon**: `basic`,
`alternative_payload`, `alternative_bare`, `var_else`, `tuple`, `with_modifier`
(`private let … else` parses; check rejects), `returned_var_else` (`returned var
.Some(v: i32) = o else { return 0; }` parses with the `ReturnedModifier` leaf;
check rejects, §2.3), `if_expr_struct_literal_else` (`var s: {.a: i32} = if c
then t else {.a = 1};` and `var e: {} = if c then t else {};` — the §1.12(b)
lookahead lets both parse as if-expressions; amended 2026-09-27, review fold:
rev 1 F3). **fail_let_else_missing_block.carbon** (`let x: i32 = y else return;`
→ `ExpectedCodeBlock`, handle_code_block.cpp:22),
**fail_let_else_if_expr.carbon** (both §1.12 shapes: `let x: i32 = if c then 1
else { return 0; }` and `let x: i32 = if c then 1 else 2 else { return 0; }` —
one diagnostic each, `LetElseUnparenthesizedIfExpr`),
**fail_let_else_trailing_semi.carbon** (`let … else { return; };` — the stray
`;` is diagnosed as today's empty expression statement; documents the no-`;`
decision). **toolchain/parse/testdata/let/alternative_root.carbon**: plain `let
.Some(n: i32) = e;` and `var .None = e;` now parse (§1.13).
**toolchain/parse/testdata/match/var_alternative.carbon** (amended 2026-09-27,
review fold: re-review M2): `case var .Some(n: i32) => {…}` and `case var .None
=> {…}` — a `VariablePattern` at the `var` token wrapping the
`AlternativePattern` root, the §2.1 root-`var` peek; today this shape misparses
as a `VariablePattern` over an `ExprPattern`.

**Check — toolchain/check/testdata/if/if_let.carbon** (positives, silent):

| subfile | shape | pins |
| --- | --- | --- |
| alternative_payload | `if (let .Some(n: i32) = opt) { return n; } else { return 0; }` on a two-alternative choice | discriminant test, `if.then`/`if.else`, bind in then |
| alternative_bare | `if (let .None = opt) {}` | discriminant test only, no bind insts (empty root) |
| payload_literal | `if (let .Some(42) = opt)` | payload block dominated by the discriminant test |
| tuple_root | `if (let (0, n: i32) = pair)` | elementwise fold |
| var_alternative | `if (var .Some(n: i32) = opt) { n = n + 1; … }` | the §1.1 var-alternative lane: discriminant test, then one payload-tuple-typed on-demand `VarStorage` in the then block, bound elementwise (renamed from `var_spelling`; amended 2026-09-27, review fold: rev 1 F1 + rev 2 B1) |
| var_tuple_root | `if (var (0, n: i32) = pair)` | the existing irrefutable-`var`/tuple lanes under a refutable root |
| bool_scrutinee | `if (let true = b)` | bool expression-pattern root (W-076 lane); amended 2026-09-27, review fold: rev 2 m9 |
| nested_payload_tuple | `if (let .Some((1, n: i32)) = q)` on `choice Q { Some(p: (i32, i32)), None }` | payload tuple walk with an expression element under the discriminant test; rev 2 m9 |
| ref_binding | `if (let .Some(ref r: i32) = v)` on a `var` scrutinee | ref lane |
| else_if_chain | two pattern conditions chained | nested `if` scopes |
| question_in_initializer | `if (let .Some(n: i32) = F()?)` in a `Core.Try`-returning fn | `?` legal at depth 1 (§1.7) |
| struct_root | `if (let {.a = 1, b: i32} = s)` | W-077 lane admitted by way of `CurrentKind()` (lands only if W-077 is in trunk; otherwise moves to the fail_todo file) |
| single_alternative | `if (let .Only(n: i32) = x)` on a one-alternative choice | constant-true test AND `IrrefutablePatternAlwaysMatches` — placed in the fail file below instead |

**toolchain/check/testdata/if/fail_if_let.carbon**:

| subfile | shape | expect |
| --- | --- | --- |
| fail_binding_in_else | `if (let .Some(n: i32) = o) { Use(n); } else { Use(n); }` | `NameNotFound` at the `else` use (scope popped at `IfStatementElse`); the then-block USES `n`, or an incidental `UnusedBinding` (unused.cpp:46-49) rides the golden (amended 2026-09-27, review fold: re-review m6) |
| fail_binding_after | `if (let .Some(n: i32) = o) { Use(n); } Use(n);` | `NameNotFound` at the trailing use (same `Use(n)` discipline, re-review m6) |
| fail_binding_in_else_if_condition | `if (let .Some(n: i32) = o) { Use(n); } else if (n > 0) {}` | `NameNotFound` — the if-let scope is popped at `IfStatementElse`, before the chained `if`'s condition is checked (rev 2 m9; then-block `Use(n)` per re-review m6) |
| fail_irrefutable_binding | `if (let n: i32 = x)` | `IrrefutablePatternAlwaysMatches` (Warning) |
| fail_irrefutable_single_alternative | one-alternative choice, all-binding payload | same warning (§1.10) |
| fail_chain_reserved | `if (let n: i32 = x and y)` | `PatternConditionChainReserved` |
| fail_binding_in_initializer | `if (let n: i32 = n)` | `UsedBeforeInitialization` (tombstones) |
| fail_unknown_alternative | `if (let .Nope = opt)` | the member-access `NameNotFound` at resolution |
| fail_missing_parens / fail_unexpected_parens / fail_arg_count | the three `MatchAlternative*` errors, resolved late | same texts as match |
| fail_unused_binding | `if (let .Some(n: i32) = opt) {}` | `UnusedBinding` at the if-let scope pop |
| fail_question_in_pattern_type | `if (let n: F()? = x)` | `QuestionInPatternContext` (depth > 1) |
| fail_todo_unsupported_scrutinee | `if (let n: i32 = some_class_value)` | TODO ``refutable pattern binding on unsupported scrutinee type`` |
| fail_todo_binding_free_var | `if (var 5 = x)` | engine TODO ``binding-free `var` in match `case` pattern`` at the introducer |
| fail_todo_var_bare_alternative | `if (var .None = opt)` | the same binding-free-`var` TODO, hit at PATTERN time by the empty synthetic payload root (§1.1 disposition; handle_let_and_var.cpp:157-160) |
| fail_todo_form_binding, fail_todo_compile_time_binding | `if (let form n: i32 …)`, `if (let n:! i32 …)` | the two handle_binding_pattern.cpp gates at the introducer |
| fail_todo_qualified_alternative | `if (let Opt.None = opt)` | engine TODO ``qualified alternative pattern in match case`` |
| fail_incomplete_scrutinee | forward-declared class value | `IncompleteTypeInMatchScrutinee` context |

**toolchain/check/testdata/while/while_let.carbon**: `pop_loop`
(`while (let .Some(x: i32) = Next(cur)) { cur = x; }`), `break_continue`,
`var_alternative` (`while (var .Some(x: i32) = Next(cur))`, the §1.1
lane); **fail_while_let.carbon**: `fail_binding_after_loop`
(`while (let .Some(x: i32) = Next(cur)) { cur = x; } Use(x);` →
`NameNotFound`; the body uses `x`, re-review m6), `fail_irrefutable`
(Warning), `fail_chain_reserved`.

**toolchain/check/testdata/let/let_else.carbon** (positives):
`alternative_payload` (`let .Some(port: i32) = e else { return -1; } return
port;`), `alternative_bare`, `tuple`, `var_else` (`var .Some(v: i32) = o else {
return 0; } v = v + 1;` — the §1.1 var-alternative lane, mutated after),
`break_in_loop`, `continue_in_loop`, `nested_all_paths_return` (`else { if (c) {
return 1; } else { return 2; } }` — accepted, §1.8),
`let_else_in_match_arm_body`, `two_in_sequence` (second let-else's initializer
uses the first's binding). **fail_let_else.carbon**:

| subfile | shape | expect |
| --- | --- | --- |
| fail_empty_else | `else {}` | `LetElseBlockFallsThrough` |
| fail_else_ends_in_expr | `else { F(); }` | same |
| fail_else_partial_return | `else { if (c) { return 1; } }` | same (convergence reachable) |
| fail_binding_used_in_else | `else { Print(port); return; }` | `UsedBeforeInitialization` (§1.8) |
| fail_file_scope | `let x: i32 = 1 else { }` at file scope | `LetElseOutsideFunction`; the golden shows TRUNCATED output — nothing after the `let` is checked (§1.9; rev 1 F6) |
| fail_class_scope | inside `class C { … }` | same, same truncation |
| fail_irrefutable | `let n: i32 = x else { return; }` | `IrrefutablePatternAlwaysMatches` |
| fail_modifier | `private let .Some(n: i32) = e else { return; }` and `virtual let .Some(m: i32) = e else { return; }` (two rows) | `ModifierPrivateNotAllowed` ("`private` not allowed; requires class or file scope") and `ModifierNotAllowedOnDeclaration` ("`virtual` not allowed on `let` declaration") — real only because `LetElseDecl` runs `LetDecl`'s checks (§2.3 step 5; amended 2026-09-27, review fold: rev 1 F4 + rev 2 M1) |
| fail_returned_var_else | `returned var .Some(v: i32) = o else { return 0; }` | `ReturnedNotAllowedOnLetElse` at the `returned` node (rev 1 F4 + rev 2 M1) |
| fail_todo_unsupported_scrutinee | class-typed initializer | the shape TODO |

**toolchain/check/testdata/let/fail_todo_alternative_root.carbon**: plain
`let .Some(n: i32) = e;` and `var .None = e;` → TODO ``alternative pattern
outside a refutable pattern context`` (§1.13 pin).

**toolchain/check/testdata/match/var_alternative.carbon** (NEW match
golden, same PR; amended 2026-09-27, review fold: rev 1 F1 + rev 2 B1):
`root_var` (`case var .Some(n: i32) => { n = n + 1; return n; }` — the
§1.1 lane reached through `match`), `payload_var`
(`case .Some(var n: i32) => …` — payload-level `var`, admitted today by
handle_match.cpp:1027-1031 but unpinned until now), and
`var_alternative_then_default` (`case var .Some(n: i32) => { Use(n); }
default => {…}` — the `default` is NOT dead: the arm records
`covered_alternatives`, not `has_irrefutable_arm`, so `DiagnoseDeadDefault`
finds neither a `Wildcard` prior nor whole-domain coverage; amended
2026-09-27, review fold: re-review M1), all on the two-alternative choice.
**toolchain/check/testdata/match/fail_var_alternative.carbon** (NEW, same
fold): `fail_nonexhaustive_var_alternative` — `case var .Some(n: i32) =>
{ Use(n); }` as the ONLY arm on the two-alternative choice →
`MatchNonexhaustive` naming `.None` (handle_match.cpp:1556). These two rows
are the guard the §8.1 zero-diff gate cannot provide (§1.1, §8.1).

**Lower — toolchain/lower/testdata/if/if_let.carbon, while/while_let.carbon,
let/let_else.carbon**: one `let` function each over the two-alternative
choice, pinning the discriminant load + `icmp` + `br` and the block labels
(`if.then`/`if.else`/`if.done`; `while.body`/`while.done`; `let.then`/
`let.else`), PLUS a `var_alternative` function in if_let.carbon and
let_else.carbon (the payload-tuple storage's `alloca` is HOISTED to the
function's entry block like every alloca — `FunctionContext::CreateAlloca`
moves the insert point to the alloca prologue, function_context.cpp:
325-338, and lower/testdata/match/var_binding.carbon:50-56 shows
`%a.var`/`%b.var` in `entry:` — so only the `llvm.lifetime.start` and the
initializing `store` land in the success block after the `br`; amended
2026-09-27, review fold: rev 1 F1 + rev 2 B1, reworded re-review m5), and
**toolchain/lower/testdata/match/var_alternative.carbon**
mirroring the check golden — all with zero lower/ code change (the
toolchain/lower/testdata/match/choice_payload.carbon and
var_binding.carbon shapes).

**Extensions to existing files: none** (§6). R26 note: all new files, so
the hosted autoupdate converges in at most two passes and touches nothing
else.

## §5 Conformance

**Un-SKIP if_let_let_else.carbon and add one program; the floor becomes
104 PASS / 0 FAIL / 27 SKIP over 131** (from W-077's 102 / 0 / 28 over
130 as measured on the W-077 branch, one SKIP → PASS and one new PASS; if
W-012 were to land first, the same delta reads 103 / 0 / 27 over 130
against trunk's 101 / 0 / 28 over 129 — amended 2026-09-27, review fold:
rev 2 M2). Both under the existing bullet
"Control flow: matching — if-let / let-else combined match+declaration"
(R7: exact gap-analysis string). `runner.py --self-test` before commit.

**control_flow/if_let_let_else.carbon** — SKIP line removed, strawman
replaced (§0.4), header comments kept in the sibling style; the choice,
`RuntimeSeed(x) = x + 20`, and the exit-code belt follow
control_flow/match_payload_literal.carbon:26-31, :49-55:

```carbon
choice OptInt { Some(x: i32), None }
fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

// if-let: bindings live in the then-block only.
fn Double(o: OptInt) -> i32 {
  if (let .Some(n: i32) = o) { return n * 2; } else { return 0; }
}
// let-else: `port` is in scope after the declaration.
fn PortOr99(o: OptInt) -> i32 {
  let .Some(port: i32) = o else { return 99; }
  return port;
}
// var-else: mutable storage after the declaration (the §1.1
// var-alternative lane; this spelling STAYS now that the lane exists —
// amended 2026-09-27, review fold: rev 1 F1 + rev 2 B1).
fn Bump(o: OptInt) -> i32 {
  var .Some(v: i32) = o else { return 98; }
  v = v + 1;
  return v;
}
fn Run() -> i32 {
  Core.Print(Double(OptInt.Some(RuntimeSeed(1))));      // (1+20)*2 = 42
  Core.Print(Double(OptInt.None));                       // 0
  Core.Print(PortOr99(OptInt.Some(RuntimeSeed(-13))));   // -13+20 = 7
  Core.Print(PortOr99(OptInt.None));                     // 99
  Core.Print(Bump(OptInt.Some(RuntimeSeed(-20))));       // 0+1 = 1
  Core.Print(Bump(OptInt.None));                         // 98
  if (Double(OptInt.Some(RuntimeSeed(1))) != 42) { return 1; }
  return 0;
}
```

EXPECT-EXIT 0; EXPECT-STDOUT `42 0 7 99 1 98` (one per line) — each value
hand-derived above per R16(d), never from running the toolchain; the
first two lines keep the original stub's `42`/`0`. Re-derived once at the
fold (2026-09-27): `Double(Some(1+20))` = 21·2 = 42; `Double(None)` = 0;
`PortOr99(Some(-13+20))` = 7; `PortOr99(None)` = 99;
`Bump(Some(-20+20))` = 0+1 = 1; `Bump(None)` = 98 — the expectation
stands.

**control_flow/while_let.carbon** (new). Its header — the
`CONFORMANCE-BULLET`/`EXPECT-EXIT`/`EXPECT-STDOUT` comment lines in the
sibling style, `import Core library "io";`, the `choice OptInt`, and
`RuntimeSeed` — is repeated IN FULL (each program is a standalone
compilation unit; amended 2026-09-27, review fold: rev 2 m10):

```carbon
// CONFORMANCE-BULLET: Control flow: matching — if-let / let-else combined match+declaration
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   6
//   3
//   7

import Core library "io";

choice OptInt { Some(x: i32), None }
fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

fn Next(n: i32) -> OptInt {
  if (n > 0) { return OptInt.Some(n - 1); }
  return OptInt.None;
}
fn Run() -> i32 {
  var cur: i32 = RuntimeSeed(-16);   // 4
  var total: i32 = 0;
  var iterations: i32 = 0;
  while (let .Some(m: i32) = Next(cur)) {   // m: 3, 2, 1, 0; then None
    cur = m; total = total + m; iterations = iterations + 1;
  }
  Core.Print(iterations);            // 4
  Core.Print(total);                 // 3+2+1+0 = 6
  var k: i32 = RuntimeSeed(-10);     // 10
  var stops: i32 = 0;
  while (let .Some(m: i32) = Next(k)) {     // m: 9, 8, 7 (break)
    k = m; stops = stops + 1;
    if (m == 7) { break; }
  }
  Core.Print(stops);                 // 3
  Core.Print(k);                     // 7
  return 0;
}
```

EXPECT-STDOUT `4 6 3 7`. The loop proves per-iteration re-evaluation and
rebinding (the counter would be 1 if the header ran once) and `break`
from a while-let body. Both programs use `Core.Print` (R1) and payload
values routed through `RuntimeSeed` so the discriminant tests are runtime
compares, not constant folds.

Other programs: none use the new forms (grep record §6.1), and no
program's `match` is touched by the `EmitCaseArmTestAndBind` factoring
(behavior-preserving; the scoreboard's 102 PASS must not move).

## §6 Churn inventory (verified file-by-file)

**Existing goldens: ZERO move.** The verification record:

1.  **No source under toolchain/parse|check|lower/testdata, examples/,
    core/ or fork/conformance/programs spells the new forms.** Greps at
    55517908c: `if (let`, `if (var`, `while (let`, `while (var` — the
    only hits are the SKIP program's comments (if_let_let_else.carbon:10,
    :30); `^\s*(let|var) .*= .* else \{` — one hit, a `var` INSIDE an
    `else` arm (toolchain/check/testdata/basics/duplicate_name_same_line.carbon:
    18), not a `let`-`else`; `^\s*(let|var) \.` — none; refutable roots
    `^\s*(let|var) ([0-9]|\.)` — none. So no golden exercises the peeks
    (§1.2, §1.13) or the `else` path (§1.3).
2.  **Existing `if (expr)` / `while (expr)` trees are byte-identical by
    construction**: the peek fires only on a `let`/`var` token after `(`
    (§0.7), and the `{`-recovery branch is checked first
    (handle_paren_condition.cpp:24-28; golden if/fail_missing_cond.carbon:
    27-30 unchanged). Removing `.child_count = 2` from `IfCondition`/
    `WhileCondition` changes extraction rules only, not tree output.
3.  **`IfConditionStart` pushing its node id** and the `IfStatementElse`/
    `IfStatement` typed-node extraction change no SemIR: the node stack
    is not dumped; the expression path emits the same insts.
4.  **`EmitCaseArmTestAndBind` factoring is behavior-preserving**: the
    usefulness/exhaustiveness blocks stay in the `match` caller in the
    same order relative to the branches and bind pass; §8.1 requires the
    70 files under toolchain/check/testdata/match and the 9 under
    toolchain/lower/testdata/match to show ZERO diffs after autoupdate.
    `MatchCaseIntroducer` still sets `scrutinee_type_id` at pattern time,
    so `AlternativePattern` takes the immediate path for `match`.
5.  **`Else` budget**: raises `expected_max_parse_tree_size` for files
    containing `else`; `Tree::Verify` compares an UPPER bound
    (tree.cpp:52-56), and the LOWER bound (`num_nodes >= tokens_->size()`,
    :58-62) is untouched. No output change.
6.  **`StartPatternInitializer`/`EndPatternInitializer` CHECK relaxation**:
    admits a third kind; behavior for the existing two kinds is
    unchanged.
7.  **kind.def, node_kind.def, state.def, inst_namer `BranchNames`**:
    additive; diagnostics print kind names and SemIR dumps print names,
    neither positional; the two label entries are for a new node kind.
8.  **fork/conformance/programs**: no program uses the forms (item 1);
    no `match` semantics change (item 4).
9.  **Class/file-scope `let … else`**: today `else` after a `let`
    initializer at those scopes yields `ExpectedDeclSemi` + skip
    (handle_let.cpp:111-117); after this slice it parses as `let`-`else`
    and check rejects it (§1.9). No golden pins the old behavior. Record
    correction (amended 2026-09-27, review fold: rev 1 F9 + rev 2 m1/m7):
    the draft's "grep `else` in toolchain/parse/testdata/let and /var:
    none" was FALSE — expression_pattern_precedence.carbon:18
    (`let (if true then 1 else 2) = 3;`) and :48
    (`let if true then 1 else 2 = 3;`) contain `else`. Both are harmless:
    each `else` belongs to an if-expression in PATTERN position (consumed
    by `HandleIfExprFinishThen` inside the parentheses at :18; inside an
    already-errored unary-`if` pattern at :48), so `HandleLetFinish`'s
    peek sees `;`, and §1.12(b)'s state-stack test
    (`[…, LetFinishAsRegular, IfExprFinish]`) does not hold with the
    pattern states in between. Neither golden moves.

**Compiler files touched:** toolchain/lex/token_kind.def (one budget
entry); toolchain/parse/{node_kind.def, state.def, typed_nodes.h,
context.h, context.cpp, handle.h, handle_paren_condition.cpp,
handle_let.cpp, handle_var.cpp, handle_pattern.cpp, handle_match.cpp
(`PushRootPattern` call), handle_if_expr.cpp}; toolchain/check/{BUILD,
refutable_binding.h, refutable_binding.cpp (new), context.h,
handle_match.cpp, handle_if_statement.cpp, handle_loop_statement.cpp,
handle_let_and_var.cpp, full_pattern_stack.h, full_pattern_stack.cpp};
toolchain/sem_ir/inst_namer.cpp; toolchain/diagnostics/kind.def.

**New files:** the §4 testdata (parse 10 — including
match/var_alternative.carbon — check 9 — including
match/var_alternative.carbon and match/fail_var_alternative.carbon —
lower 4; counts amended 2026-09-27, review fold: re-review M1/M2), the §5
program, fork/w012/plan.md.

## §7 Risks and rejected alternatives

-   **R-1 Deferred alternative resolution (§1.6) is the slice's real
    engine change.** Mitigation: it is a code MOVE (the resolution half of
    the existing handler into `ResolvePendingAlternative`, called
    immediately by `match`), plus one new call site; §6.4 pins `match`'s
    70+9 goldens to zero diffs. Break condition: a `match` golden moving
    means the move was not behavior-preserving — stop and diagnose.
-   **R-2 Emission order for `let`-`else`** (§2.3): the success block's
    insts follow the else block's. Lowering treats blocks independently
    and the `?` desugar already emits its diverging block first
    (handle_question.cpp:383-395). If a formatter or verifier assumption
    surfaces in autoupdate, the fallback is to bind first and re-push the
    success block by way of `InstBlockStack::Push(id, inst_ids)`
    (inst_block_stack.h:29-31).
-   **R-3 `Else` budget entry (§0.1)** contradicts the ledger's "no lexer
    change" literally. It is a table constant, not a lexing rule; recorded
    as a ledger correction. Alternative rejected: a trailing `;`
    (design open question 1) — it would make `let`-`else` the only
    brace-terminated construct in the language that also needs a `;`,
    against if-let.md:575-580's own assumption.
-   **R-4 Reachability vs the literal syntactic list (§1.8) — recorded
    as the explicit F-011 amendment F-011a (amended 2026-09-27, review
    fold: rev 1 F7 + rev 2 M4).** The predicate accepts strictly more than
    the list (all-paths-diverging blocks) and nothing the list rejects for
    a reason; it is a deviation, not a paraphrase, so it carries its own
    decision-log entry (§8.5). Veto-able; the fallback is one function
    (a last-statement node-kind test).
-   **R-5 `var` spellings and cleanup.** On-demand `VarStorage` lands in
    the success block (if-let: then block; while-let: body; let-else: the
    continuation) with `DeferCleanups`, so destruction happens at the
    owning scope's end (if-let: the §1.5 scope pop in the then block;
    while-let: `FinishLoopBody`'s exit-block cleanups; let-else: the
    enclosing scope). In-slice scrutinee types are trivially destructible
    (handle_match.cpp:256-263), so the failure-path destruction rule
    (p005164, pattern_matching.md:776-792) has no observable work yet —
    the same recorded state `match` is in.
-   **R-6 The if-expression recovery (§1.12(b)) inspects the state
    stack.** Precedented (handle_expr.cpp:249-255); its scope is one
    token pair (`else` `{`) in one syntactic position. If a review finds
    a false positive beyond the one now handled — the struct-literal
    else operand `let x: {.a: i32} = if c then y else {.a = 1};` is
    excluded by the `{` `.`/`}` lookahead that is part of the rule (§1.12;
    amended 2026-09-27, review fold: rev 1 F3) — the fallback is to drop
    (b) and keep only (a): users then see the struct-literal error the
    design anticipated. A code block that begins with `.` or is empty
    (`else {}`) is misread as a struct literal by design; the empty case
    is an error anyway (`LetElseBlockFallsThrough`), and a statement
    cannot begin with `.`.
-   **R-7 W-077 merge interplay.** Struct patterns become admissible in
    the new forms automatically (§1.4); the `struct_root` positive
    subfile lands only if W-077 is in trunk at autoupdate time, else it
    moves to the fail_todo file with the surviving `struct pattern start`
    TODO. The two branches touch disjoint regions of handle_match.cpp
    except `EmitCaseArmTestAndBind`'s classification lines (W-077 adds a
    struct lane, :766-1120 on 15207a17f) — the factoring in §2.2 must be
    done on the merged file; the classification lane list is carried
    over verbatim.
-   **R-8 Scope of `MatchCaseArm` reuse.** Any FUTURE gate written as
    "this is a match arm" rather than "this is a refutable context" will
    apply to the new forms too. Mitigated by the kind's comment change
    (§1.4) and by naming the new forms in handle_match.cpp's header
    comment.
-   **R-9 File-scope let-else and global init.** `UseGlobalInit` paths
    (handle_let_and_var.cpp:194-207) are never reached: §1.9 rejects the
    forms outside functions before the initializer is checked.
-   **R-10 The `and`/`or` reservation is check-time (§1.11).** A parse-time
    rule would be tidier but no precedence group expresses "all but
    `and`/`or`" (precedence.cpp:31-33). If let-chains land, the check
    lifts and the parser gains the chain grammar.

Rejected alternatives (each with the reason, for the record):

-   **A-1 A `PatternCondition` grouping node** — needs a token budget the
    `let` token does not have (§1.2), or a second lexer-table edit.
-   **A-2 Emitting the initializer subtree before the pattern subtree** —
    would break the tree's source-order postorder (every consumer,
    including diagnostics' token advancement, check_unit.cpp:392, assumes
    it).
-   **A-3 Trailing `;` on `let`-`else`** — see R-3.
-   **A-4 Deciding the `let`-`else` pattern context late in check (no
    introducer re-kind)** — the pattern would check under
    `NameBindingDecl`: `var` roots would allocate frame storage
    (`add_local_var`, handle_let_and_var.cpp:110-120) that the on-demand
    bind lane duplicates, and a root `.Name` could not be recorded
    anywhere (`AlternativePattern` reads `match_case_stack().back()`,
    which would be absent). Deferring by way of `NodeIdTraversal`'s deferred
    worklist (node_id_traversal.h:17-31) is a function-definition
    mechanism keyed on `DeferredDefinitionIndex`, not a general reorder.
-   **A-5 A new `FullPatternStack::Kind`** — §1.4.
-   **A-6 Suppressing usefulness/exhaustiveness by way of a mode flag** —
    unnecessary: the new forms never push `match_statement_stack`
    (§1.7); a flag would be dead code.
-   **A-7 Reusing `LetIntroducer`/`LetDecl` with context-aware check
    handlers for `let`-`else`** — `LetDecl` is `bracketed_by
    LetIntroducer` and carries a `SemiTokenIndex`; the close node needs
    its own kind either way, and the check ordering problem (A-4)
    remains.
-   **A-8 Dropping the root-`var` spellings (`if (var .Some(…) = e)`,
    `var .Some(…) = e else {…}`) to a follow-up** — rejected by decision
    R29a (§1.1): the design's own example, the SKIP program's replacement,
    ~15 lines over existing machinery with an exact precedent, and a free
    lane for `match` (amended 2026-09-27, review fold: rev 1 F1 + rev 2
    B1).
-   **Options B/C/D** of the design paper — rejected by F-011; not
    reopened.

## §8 Verification and discharge

1.  **Regen:** hosted autoupdate (`Fork: hosted verification`, mode
    autoupdate; R28(b)) to R26 fixpoint. Expected: diffs ONLY in the
    §4 new files; in particular ZERO diffs under toolchain/check/testdata/
    match (70 files) and toolchain/lower/testdata/match (9 files) — the
    §6.4 behavior-preservation proof. Any other movement is a §6 miss:
    stop and reconcile. **Limit of this gate (amended 2026-09-27, review
    fold: re-review M1):** zero match-golden diffs prove only that the
    factoring preserved every shape the existing goldens spell, and NO
    existing golden spells a `var`-wrapped alternative root
    (`grep -E 'var \.[A-Za-z]'` over toolchain/{parse,check,lower}/testdata
    and fork/conformance/programs: no hits) — so the gate cannot detect
    the §1.1 exhaustiveness/usefulness misclassification of
    `case var .Some(n: i32)`. The new negatives
    `fail_nonexhaustive_var_alternative` and `var_alternative_then_default`
    (§4) are the guard.
2.  **Gate:** hosted gate mode green (R21 mirror), `uvx prek run --files
    <changed>` clean locally first (R25), clang-format 21.1.8 on the C++
    diff (R18); parse coverage test green (all five node kinds appear in
    §4 parse goldens).
3.  **Conformance:** hosted conformance mode: **104 PASS / 0 FAIL / 27
    SKIP over 131**; `runner.py --self-test` green (R7).
4.  **Reconciliation greps at discharge:** ``expression pattern`` TODO site
    count unchanged (pattern_match.cpp:1191 only); the new TODO strings appear
    at exactly one code site each plus their §4 pins; ``match `case` pattern
    other than an integer literal, or a case guard`` site count unchanged;
    `Kind::MatchCaseArm` site count grew only by the new handlers and the CHECK
    relaxation; `IsSupportedScrutineeType` has one definition
    (refutable_binding.cpp).
5.  **Ledger edits (fork/inventory/work-items.json):**
    -   W-012: notes gain the closing record — "DISCHARGED
        (fork/w012/plan.md): if-let / while-let / let-else (+ `var`
        spellings) as a shared refutable-binding driver factored from
        `EmitCaseArmTestAndBind`, on `FullPatternStack::Kind::MatchCaseArm`
        -   `MatchCaseContext`; deferred alternative resolution for
            pattern-before-scrutinee order; if-let scope popped before the
            else arm; let-else divergence by `IsCurrentPositionReachable`,
            bindings tombstoned through the else block; zero lower/ changes;
            conformance 104/0/27 over 131" — with the §0 corrections recorded
            verbatim (the `else` budget entry; 5 kinds / 2 states; no engine
            "variant", one deferred lane; the strawman spelling; the doc
            evidence line).
    -   NEW work items filed, `blocked_by: []`: (a) the design's
        refutability ERROR for plain `let`/`var` (pattern_matching.md:
        670-687) replacing the two TODO lanes (`expression pattern`,
        `alternative pattern outside a refutable pattern context`),
        evidence = pattern_match.cpp:1191 and the §4 fail_todo pins;
        (b) let-chains (`if (let P = e and c)`), evidence = the
        `PatternConditionChainReserved` site and if-let.md:330-334;
        (c) type-based (noreturn) divergence for `let`-`else` replacing
        the reachability rule once the error-handling design defines it
        (if-let.md:318-320, :565-571).
    -   W-012's own `blocked_by` (`["W-008", "W-010"]` today, both
        landed, §0.6) is CLEARED to `[]` (amended 2026-09-27, review fold:
        rev 2 M2).
    -   Decision-log entry "W-012: if-let / while-let / let-else landed
        (date)" carrying §1.2/§1.3 (the tree shapes, the re-kind, the
        `else` budget), §1.4 (`MatchCaseArm` reuse), §1.6 (deferred
        resolution), §1.8 (the tombstone rule — veto-able), §1.11-§1.13
        (the two reservations and the root peek), and §7 R-6, each with
        its break condition; F-011's design rider 2 (mechanical
        re-spelling if upstream #5101 lands differently) restated with the
        parse surface this slice actually has (five node kinds, two
        states). It ALSO carries the following auto-adopted decisions
        (R29(a): no questions; recorded for after-the-fact veto — amended
        2026-09-27, review fold: rev 1 F1/F7 + rev 2 B1/M4/m8):
        -   **R29a — the var-alternative lane** (§1.1): the `var`-wrapped
            alternative root is classified and bound by an explicit lane
            (`is_var_alternative_arm`; test through
            `MatchCaseAlternativePatternMatch`, bind through
            `MatchCaseBindPatternMatch` on the payload field ref with
            on-demand storage), shared with `match`; bare `var .None` stays
            behind the binding-free-`var` TODO. Rejected: dropping
            root-`var` to a follow-up (§7 A-8). Break condition: §1.1.
        -   **F-011a — else-block divergence = reachability predicate
            (`IsCurrentPositionReachable`), overruling the literal
            return/break/continue list** (fork/decision-log.md:1314-1316;
            if-let.md:316-321). A DEVIATION accepting a strict superset:
            every block the list accepts, plus any block whose every path
            ends in `return`/`break`/`continue`; a nested `if` without
            `else` and `Abort()`-style calls (pending a noreturn rule,
            if-let.md:318-320) are rejected. Break condition: owner veto —
            fallback is a last-statement parse-node-kind test on the else
            block (one function, same diagnostic), which then rejects the
            superset cases.
        -   **Design paper open questions resolved** (if-let.md:569-596):
            Q1 `let`-`else` terminator — NO trailing `;` (the paper's own
            assumption; §1.3, §7 A-3); Q5 `var` forms — INCLUDED, with the
            root-`var` lane above (§1.1); Q6 irrefutable pattern in the
            combined forms — a Warning, `IrrefutablePatternAlwaysMatches`
            (§1.10), not an error. (Q2/Q3/Q4/Q7 are already fixed by
            §1.12, F-011a, the slice definition and §1.11.)
6.  **fork/gap-analysis.md:64** (retargeted 2026-09-27, review fold: rev
    2 M2; the row was :57 before trunk f0e1980's reconciliation): status
    MISSING → **PARTIAL**, detail:
    "Parsed, checked and lowered as desugarings onto the match engine
    (parse/if, parse/while, parse/let goldens; check/if, check/while,
    check/let; lower/); both forms conformance-PASS. Residue shared with
    the `match` row: the engine's scrutinee/pattern admission gates
    (class-typed and adapter scrutinees, form/compile-time bindings,
    qualified alternatives), plus `and` chaining reserved and the
    noreturn-based divergence rule deferred to the error-handling
    design." Justification for PARTIAL rather than DONE: the bullet's
    "combined match control flow" inherits every gate the match bullet
    (:62, which the reconciled trunk now marks DONE with residual edges
    named in its detail column) still carries — the two rows flip to DONE
    together when the engine's gates close. R7: the bullet text is
    untouched.

## Hand-off notes for the implementer

-   Do the `EmitCaseArmTestAndBind` factoring on the tree AFTER W-077
    merges (its 15207a17f version of the function is the base); carry the
    classification lane list over verbatim and keep the usefulness and
    coverage blocks in the `match` caller at their current position
    relative to the branches.
-   `MatchCaseIntroducer` must keep filling `scrutinee_type_id` at pattern time;
    only the new forms leave it `None`. `ResolvePendingAlternative` is the
    single body for both — do not fork the diagnostics.
-   The bare `.Name` root under the new forms is an EMPTY synthetic
    `TuplePattern` with `payload_pattern_id = root_id`; never route it
    through the `designator_root_id` lane, which needs a pattern-time
    member access.
-   Order in the `IfCondition`/`WhileCondition` pattern path is
    load-bearing: chain check → scrutinee gate → `EndPatternInitializer`
    → test → branches → bind. `EndPatternInitializer` before the bind
    pass, or the bind pass's own name resolution hits the tombstones.
-   For `let`-`else`, `EndPatternInitializer` runs at `LetElseDecl`, not
    at `LetElse` — that is what makes a binding use in the else block
    diagnose `UsedBeforeInitialization`.
-   `IfConditionStart` now pushes its node id: the expression path of
    `IfCondition` pops it; the pattern path's introducer handler has
    already consumed it and left `PatternConditionIntroducer` in its
    place, which `IfStatementElse`/`IfStatement` pop with
    `PopAndDiscardSoloNodeIdIf` (§1.5, §2.3).
-   The pattern root is popped from the node stack exactly ONCE, by the
    form's close handler (`IfCondition`, `WhileCondition`, `LetElse`);
    `EndRefutableBindingPattern` does not pop it (§2.2).
-   The var-alternative lane (§1.1) must be classified BEFORE
    `is_irrefutable_var_arm`, or an all-binding `var .Some(n: i32)` root
    folds to constant `true` and never tests the discriminant — AND
    `is_irrefutable_var_arm` must carry `&& !is_var_alternative_arm`, or
    `match`'s coverage block marks the statement exhaustive on that arm
    (re-review M1). Key its usefulness through
    `alternative->payload_pattern_id`, never the `VarPattern` root.
-   `case var .Some(…)` does not parse today: the root-`var` peek in
    `PushRootPattern` (§2.1, re-review M2) is what makes the §4
    match/var_alternative rows reachable — land it in the parse commit.
-   The `PopFullPattern()`/`match_case_stack().pop_back()` pair has ONE
    owner, the caller: `match` before its branches (as today), the new
    forms right after `EmitRefutableBindingBind` (re-review M3). Neither
    `EmitRefutableBindingTest` nor `EmitRefutableBindingBind` pops.
-   `LetElseDecl` runs `LetDecl`'s modifier checks (§2.3 step 5) BEFORE
    `Pop<Let>()`; `LetElse` must not pop the introducer state.
-   `else` in token_kind.def becomes `CARBON_TOKEN_WITH_VIRTUAL_NODE`; do
    the §1.2/§1.3 node-count arithmetic against any tree shape you change
    before firing autoupdate — `Tree::Verify` failures show up as
    CHECK-crashes, not diagnostics.
-   Fail-matrix bindings: used or `unused`-marked.

## Sign-off

Status: **APPROVED FOR IMPLEMENTATION, 2026-09-27** — after rev 1
(REJECT), rev 2 (APPROVE-WITH-AMENDMENTS) and the focused re-review of
§1.1/§2.2/§2.3/§4/§5 (APPROVE-WITH-AMENDMENTS; folds 13-18 below). Folds
applied, each verified against trunk f0e1980 (and the W-077 branch where
marked) before writing:

1.  **rev 1 F1 + rev 2 B1 (the shared blocker)** — §0.3, §1.1, §1.6, §4,
    §5, §7 A-8, §8.5: the var-alternative classification lane (decision
    R29a), `var_alternative` pins in check and lower, the new
    match/var_alternative.carbon golden (`case var .Some(n: i32)` and
    `case .Some(var n: i32)`), bare `var .None` disposition pinned as
    `fail_todo_var_bare_alternative`, `Bump` kept as `var … else`,
    EXPECT `42 0 7 99 1 98` re-derived.
2.  **rev 1 F2** — §2.2, §2.3, hand-off: `EndRefutableBindingPattern`
    leaves the pattern on the node stack; each close handler pops it once;
    line-range ownership map of `EmitCaseArmTestAndBind` :733-1051
    including the introducer state/node pops for both callers.
3.  **rev 1 F3** — §1.12, §2.1, §4, §7 R-6: (b) fires only when the token
    after `{` is neither `.` nor `}`; (a) gated on `!node_has_error`;
    `AddInvalidParse` count corrected (missing-`else` adds one, :51;
    missing-`then` two, :28-29); struct-literal else operand pinned
    positive.
4.  **rev 1 F4 + rev 2 M1** — §1.3, §2.3, §2.5, §4: `LetElseDecl` typed
    node gains `returned`; new `ReturnedNotAllowedOnLetElse`;
    `LetElseDecl` runs `LetDecl`'s modifier checks verbatim before
    `Pop<Let>()`; `fail_modifier` made real (two rows) and
    `fail_returned_var_else` added.
5.  **rev 1 F6** — §1.9, §4: `return false` aborts the file; truncated
    goldens noted; one row per split file.
6.  **rev 1 F7 + rev 2 M4** — §1.8, §2.6, §7 R-4, §8.5: F-011a recorded
    as an explicit deviation with break condition and fallback; the
    pattern_matching.md rule stated precisely.
7.  **rev 1 F8** — §1.5, §2.3, hand-off: node-stack protocol
    (`PopAndDiscardSoloNodeIdIf<PatternConditionIntroducer>`) replaces the
    `ExtractAs<IfCondition>` mechanism.
8.  **rev 1 F9 + rev 2 m1/m7** — §0.8, §1.4, §1.6, §1.7, §2.2, §2.3, §6.9,
    §8.4/§8.5: record fixes (`else` IS in parse/testdata/let, harmlessly);
    `ResolvePendingAlternative` move list; `PeekIs` after
    `PopExprWithNodeId`; drift refresh (usefulness :818, `DiagnoseDeadDefault`
    :1339/:1355, `DiagnoseNonexhaustiveMatch` :1594, HasBindings
    :1009/:1035, `LookupChoiceAlternative` :408-409, the `expression
    pattern` TODO :1191).
9.  **rev 2 M2** — Status, §2.6, §5, §8.3, §8.5, §8.6: base premise
    (trunk f0e1980 + PR #39 W-077 when merged; W-077's ~:230 / ~:830
    edits); gap-analysis row :64 (match row :62); `blocked_by` clear;
    floors attributed (102/0/28 over 130 measured on the W-077 branch;
    target +2).
10. **rev 2 M3** — §2.6: error_handling.md (:163-197, :831-835) and
    README.md (:3898-3902) retargeted; "design-only" clause deleted.
11. **rev 2 m8** — §8.5: open questions 1, 5, 6 resolved on record as
    auto-adopted (R29(a)).
12. **rev 2 m9/m10** — §4, §5: bool scrutinee positive, chained-`else if`
    condition leak negative, nested payload tuple, `.Some(var n: i32)`
    pin, one split file per row, while_let.carbon header in full.
13. **re-review M1 (match exhaustiveness soundness)** — §1.1, §2.2, §4, §6,
    §8.1, hand-off: `is_irrefutable_var_arm` gains `&& !is_var_alternative_arm`
    (today's :779-781 is TRUE for `case var .Some(n: i32)` because
    `IsIrrefutableMatchCasePattern` recurses through `VarPattern`,
    pattern_match.cpp:680-684, and the coverage block :939-941 would set
    `has_irrefutable_arm`); :942-943 then records `covered_alternatives`;
    usefulness keyed with `BuildMatchCaseUsefulnessKey(context,
    alternative->payload_pattern_id, alternative)` (:740-744 returns `nullopt`
    on the root today — the arm was silently unchecked/unrecorded); new rows
    `fail_nonexhaustive_var_alternative` (match/fail_var_alternative.carbon) and
    `var_alternative_then_default`; §8.1 records that the zero-diff gate cannot
    catch this (no existing golden has a `var`-wrapped alternative root — grep
    recorded there).
14. **re-review M2 (parse of `case var .Some(…)`)** — §2.1, §4, §6,
    hand-off: `HandleMatchCaseIntroducer` peeks `.` only
    (parse/handle_match.cpp:163-171); `var` first routes
    Pattern → VariablePattern → Pattern → `.` → `ExprPattern`
    (handle_pattern.cpp:25-30, :49-64; handle_var.cpp:100-106).
    `PushRootPattern` now consumes a root `var` before `.`, pushes
    `FinishVariablePattern` at the `var` token (handle_var.cpp:109-118
    emits the `VariablePattern`; budget 2), then
    `MatchCaseAlternativePattern` with `in_var_pattern=true`; parse golden
    toolchain/parse/testdata/match/var_alternative.carbon added.
15. **re-review M3 (driver contract coherence)** — §1.1, §2.2, §2.3, §2.4,
    hand-off: `RefutableBindingTest` widened to the six classification
    flags plus `is_irrefutable` (the warn predicate, kept SEPARATE from
    the three flags `match` feeds into `has_irrefutable_arm`),
    `std::optional<Alternative> alternative` (copied after resolution —
    the case context is popped at :963 before bind, why :752 copies
    today) and `cond_id` (bind lanes gate on `!= ErrorInst`, :991-992,
    :1007, :1034); `EmitRefutableBindingBind(context, node_id, pattern_id,
    scrutinee_id, const RefutableBindingTest&)`; the :958-964 pops moved
    to the CALLERS (match unchanged; new forms after bind) — one owner;
    ownership table updated; `let`-`else` parks the test in the case
    context (`let_else_test`, §2.4) between `LetElse` and `LetElseDecl`.
16. **re-review m4 (citations)** — §2.3 step 5: introducer copy :329,
    `Pop<Let>` :339, `LimitModifiersOnDecl` :341-343,
    `RequireDefaultFinalOnlyInInterfaces` :348-350, `parent_scope_inst`
    :325-328, "`LetDecl` (:329-350)"; §2.3 `LetElse` step 5:
    `MatchCaseContext::pattern_id` is context.h:289-293; §1.1 alternative
    record handle_match.cpp:556-560; §1.8/§2.6 if-let.md let-else rule
    :316-321, initializer restriction :322-326, reserved :330-334, warn
    :327-329; §7 R-5/§2.3 trivially-destructible argument
    handle_match.cpp:256-263.
17. **re-review m5 (lower prediction)** — §4: allocas are hoisted to the
    function entry (`CreateAlloca`, function_context.cpp:325-338;
    lower/testdata/match/var_binding.carbon:50-56) — only
    `llvm.lifetime.start` plus the initializing `store` land in the
    success block.
18. **re-review m6 (`UnusedBinding` hygiene)** — §4:
    `fail_binding_in_else_if_condition`, `fail_binding_in_else`,
    `fail_binding_after` and while-let's `fail_binding_after_loop` USE the
    binding in the success block (`{ Use(n); }`), so no incidental
    `UnusedBinding` (unused.cpp:46-49) rides the golden.

Wrong citations found in the draft and corrected: handle_if_expr.cpp
"two `AddInvalidParse` … :50-52" (one, :51); handle_match.cpp `:405`
(`LookupChoiceAlternative` is :408-409), `:824-951` (usefulness+coverage
:818-956), `:1327/:1565` (:1339, :1355 / :1594), `:999/:1031`
(:1009/:1035), `:370-565` (:370-563) and the other `AlternativePattern`
sub-ranges (§1.6); pattern_match.cpp `:1192` (:1191), `:597-600`/`:578-590`
(:599-603 / :578-597); gap-analysis `:57`/`:55` (:64 / :62 after
f0e1980); §6.9's "no `else` in parse/testdata/let|var" (two hits,
harmless). Not verifiable from this container: PR #39's number (GitHub API
404 — private visibility); git confirms W-077 (HEAD 438f569ec) is not in
trunk.

Wrong citations found and corrected in the re-review fold (2026-09-27),
beyond the six m4 named: if-let.md `:293-300` (grammar is :296-303),
`:302-333` (semantics :305-334), `:244-291` (the Option A examples are
:247-294), `:308-314`/`:308-311` (the let-else rule is :316-321),
`:311-313` (the noreturn deferral is :318-320), `:315-320` (:316-321),
`:325-328` (the warn rule is :327-329), `:329-333` (reserved :330-334),
`:334-339`/`:336-337` (the `if`-expression ambiguity is :322-326, stated
at :201-203; :336-339 is the C++ interop paragraph). Re-verified as
correct against f0e1980 while folding: handle_match.cpp :733-1051,
:736-753, :776-816, :779-781, :818-956, :939-943, :958-964, :991-992,
:1006-1009, :1027-1031, :1034, :1239-1245, :1460, :1556;
pattern_match.cpp :680-684, :740-744, :1475-1479; parse/handle_match.cpp
:163-171; parse/handle_pattern.cpp :25-30, :49-64; parse/handle_var.cpp
:93-118; parse/context.h :28-31, :345-347; full_pattern_stack.h :155-158;
unused.cpp :46-49; lower/function_context.cpp :325-338;
lower/testdata/match/var_binding.carbon :50-56.

## Landed notes (2026-09-27)

Deltas from this plan to the landing, each verifiable from
`git log --stat claude/carbon-fork-0-1-w012 ^origin/trunk` and
`git diff origin/trunk...HEAD --stat` (61 files, +14021/−572 including
this plan). Code commits after sign-off: a7d0366d4 (parse), 290522c68
(check), df98b0aa2 (testdata skeletons), af35bf881 (conformance + docs),
7b6257535, d77b5dd19 (review fixes), a17856ffd (hosted autoupdate fill),
b134c2022 (testdata authoring fixes).

1.  **`LetElseDecl` typed node (§1.3).** Landed with `equals` +
    `initializer` grouped into a nested `LetElseInit` aggregate
    (7b6257535): the §1.3 struct as written had nine fields and
    common/struct_reflection.h caps typed parse nodes at eight — the
    hosted autoupdate failed to compile. `init` is `std::optional`
    (d77b5dd19): `let P else {…}` without `= e` built an error-free tree
    whose mandatory field failed extraction (debug FATAL); the optional
    field makes check's `ExpectedInitializerAfterLet` reachable (pinned:
    parse let_else_missing_initializer, check fail_missing_initializer).
    Category is `Statement | Decl`, not the plan's `Statement` alone: the
    parser cannot tell statement `let` from file/class-scope `let`
    (§1.9), so `File` and `ClassDefinition` must extract the node for the
    fail_file_scope / fail_class_scope pins to reach check's
    `LetElseOutsideFunction`.
2.  **The `match (` gate (§1.2, §2.1).** `HandleParenCondition`'s
    `let`/`var` peek is shared with the `match` variant; as planned it
    produced a pattern prefix under a `MatchCondition` node and crashed
    `Tree::Verify` (debug) or the introducer handler's CHECK (release).
    Landed gated on `start_kind != MatchConditionStart`; `match (let …)`
    falls to the expression path and diagnoses an expected expression
    (d77b5dd19; parse/testdata/match/fail_let_condition.carbon).
3.  **Testdata authoring (§4).** The hosted fill (a17856ffd) exposed two
    positives that were wrong as authored, fixed in b134c2022:
    nested_payload_tuple's `(i32, i32)` payload sits behind upstream's
    "choice alternative payload that is not trivially copyable and
    destructible" TODO — now `Pair(a: i32, b: i32)` with
    `.Pair(1, n: i32)`; question_in_initializer's `0 as Tok` needed
    `(0 as i32) as Tok` (no `IntLiteral → Tok` conversion). Neither is a
    compiler defect.
4.  **§8.1 zero-diff gate.** Holds: `git diff origin/trunk...HEAD
    --diff-filter=M -- 'toolchain/*/testdata'` is empty — every one of
    the 26 autoupdate-filled files is new, and the only match-directory
    changes are the five new var_alternative / fail_var_alternative /
    fail_let_condition files.
5.  **§8.4 reconciliation greps, run at discharge (counts as measured):**
    -   ``expression pattern`` TODO: ONE site, pattern_match.cpp:1363 —
        count unchanged, but the plan's citation `:1191` was against
        f0e1980; trunk and this branch both have it at :1363 (drift from
        the intervening trunk merges, not a move by this slice).
    -   New TODO strings, one code site each plus their §4 pins:
        ``alternative pattern outside a refutable pattern context`` at
        handle_match.cpp:291-295 (pins: let/fail_todo_alternative_root
        .carbon, two subfiles); ``refutable pattern binding on
        unsupported scrutinee type`` defined once at
        refutable_binding.h:40 and emitted at refutable_binding.cpp:200
        (pins: fail_todo_unsupported_scrutinee in fail_if_let,
        fail_while_let and fail_let_else — three).
    -   ``match `case` pattern other than an integer literal, or a case
        guard``: 8 sites on trunk, 8 on the branch — handle_match.cpp:857
        moved to refutable_binding.cpp:460; the seven pattern_match.cpp
        sites are untouched. Unchanged.
    -   `Kind::MatchCaseArm`: 5 code sites on trunk (plus two testdata
        comments), 9 on the branch. The four new ones: handle_match.cpp:291
        (the §1.13 `AlternativePattern` first branch),
        handle_let_and_var.cpp:242 (`HandleInitializer`'s `let`-`else`
        branch), full_pattern_stack.cpp:19 (the §1.4 CHECK relaxation) and
        refutable_binding.h:21 (a header comment). The plan's expectation
        — "grew only by the new handlers and the CHECK relaxation" — holds
        with that one comment on top.
    -   `IsSupportedScrutineeType`: ONE definition,
        refutable_binding.cpp:83 (moved from handle_match.cpp:189;
        declared at refutable_binding.h:77).
6.  **§8.3 conformance:** hosted-only per R28 (ubuntu-22.04, upstream's
    remote cache read-only); result 108 PASS / 0 FAIL / 27 SKIP over 135
    against the §5 target of 104 PASS / 0 FAIL / 27 SKIP over 131 (the
    delta is EH-A's four programs, merged in from trunk before the gate).
7.  **§8.5 ledger:** W-012 closed with the §0 corrections; W-080
    (refutability ERROR), W-081 (let-chains), W-082 (noreturn divergence)
    filed with `blocked_by: []`; W-012's `blocked_by` cleared;
    gap-analysis:64 MISSING → PARTIAL (header 26 / 21 / 7 / 2). The
    decision-log entry is "W-012: if-let / while-let / let-else landed
    (2026-09-27)".
