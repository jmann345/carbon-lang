<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-012 plan: if-let / while-let / let-else as refutable-match desugarings

**Status:** DRAFT FOR ADVERSARIAL REVIEW (two fresh-context plan reviews
per R29(c)), 2026-09-27. Branch `claude/carbon-fork-0-1-w012` off trunk
55517908c (post-PR: W-005 discharged; conformance 101 PASS / 0 FAIL /
28 SKIP over 129 per fork/conformance/out/scoreboard.json totals). W-077
(struct patterns in match case position, branch
`claude/carbon-fork-0-1-w077` at 15207a17f, plan APPROVED 2026-09-26) is
merging into trunk ahead of this slice and moves the conformance floor to
102 / 0 / 28 over 130; every line number below is against trunk
55517908c unless marked "(W-077 15207a17f: …)".

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
(`if (var P = e)`, `var P = e else {…}`; if-let.md:293-300 grammar), the
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
    driver out of that function (§1.4, §2.3) and adds ONE engine lane
    that `match` never needed: **deferred alternative resolution** (§1.6).
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
7.  **Design premise re-verified, not corrected:** "`let`/`var` can never
    begin an expression" (if-let.md:191-197). `var` appears in the
    expression grammar only after `form(` (toolchain/parse/handle_form_literal.cpp:
    34-48, reached from handle_expr.cpp:172-174 on the `form` token); `let`
    appears nowhere in it. So the single-token peek after `(` is
    unambiguous.
8.  **Refutable patterns in plain `let`/`var` are a TODO today, not the
    design's error.** `LocalPatternMatch` on an `ExprPattern` root emits
    ``context_.TODO(entry.pattern_id, "expression pattern")``
    (toolchain/check/pattern_match.cpp:1176-1192), and no check golden
    contains a refutable `let`/`var` root (grep record in §6.1). The
    real refutability error of pattern_matching.md:670-687 stays out of
    this slice and is filed as a work item (§8.5).

## §1 Design decisions

Each decision names its break condition. "Refutable pattern binding" below
means any of the three forms.

1.  **SLICE: the three forms with their `var` spellings, one PR, no
    guard, no `and` chaining, no expression form** (if-let.md:329-333 lists
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

3.  **PARSE, `let`-`else`: the introducer node is re-kinded when the
    parser reaches the `else`.** The parser learns that a `let` is a
    `let`-`else` only after the full initializer expression, exactly as it
    learns a declaration's introducer only after its modifiers — and it
    handles that with `ReplacePlaceholderNode(state.subtree_start, …)`
    (toolchain/parse/context.cpp:42-53; the state's `subtree_start` is
    retained through `ApplyIntroducer`, handle_decl_scope_loop.cpp:38-45,
    and `HandleLet`'s `PushState(state, LetFinishAsRegular)`,
    handle_let.cpp:17, so `state.subtree_start` in `HandleLetFinish`
    indexes the `LetIntroducer` node). This slice adds the sibling
    `Context::ReplaceIntroducerNode(position, old_kind, new_kind)`: the
    same one-line `NodeImpl` rewrite with a CHECK on the old kind (the
    tree already exposes `set_kind` for exactly this operation,
    tree.h:245-250). Tree for `let .Some(port: i32) = Parse(s) else { return -1; }`:

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

    `LetInitializer`/`VariableInitializer` are NOT re-kinded (their
    position is not retained by any state); their check handlers become
    context-aware instead (§2.3, a two-line branch each). Budget:
    `let n: i32 = x else { return; }` tokens 1+1+2+1+1+1+2(else, §0.1)+1+1+1+1
    = 13; nodes: introducer, `n`, type start, `i32`, binding, `=`, `x`,
    LetElse, CodeBlockStart, ReturnStatementStart, ReturnStatement,
    CodeBlock, LetElseDecl = 13. Exact. Typed nodes:

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
      AnyPatternId pattern;  // a VariablePattern for the `var` spelling
      NodeIdOneOf<LetInitializer, VariableInitializer> equals;
      AnyExprId initializer;
      LetElseId else_token;
      CodeBlockId else_block;
      Lex::TokenIndex token;  // the introducer token
    };
    ```

    Category `Statement` (function-body only, §1.9); `AnyStatementId`
    admits it (toolchain/parse/node_ids.h:111-112). No trailing `;`
    (design open question 1, if-let.md:575-580, resolved by the paper's
    own assumption; the `;` alternative is §7 A-3). Break condition: a
    reviewer rejecting node re-kinding — the fallback is a distinct
    `LetElseDecl` close node only, with the check side deciding the
    pattern context late; §7 A-4 records why that fallback is worse
    (it cannot resolve `.Name` roots, §0.3).

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
    minus the match-only usefulness and exhaustiveness blocks
    (handle_match.cpp:824-951), which stay in the `match` caller; so
    `match_statement_stack` is never touched by the new forms (§1.7).
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
        `IfConditionStart` (the `MatchCaseIntroducer` precedent,
        handle_match.cpp:324). To make that peek possible,
        `HandleParseNode(IfConditionStartId)` — a no-op today,
        handle_if_statement.cpp:13-16 — pushes its node id, and the
        `IfCondition` handler pops it (`WhileConditionStart` and
        `ForHeaderStart` already push theirs, handle_loop_statement.cpp:99,
        :141); no SemIR changes. The scope is popped (with
        `AddAndDiscardScopeCleanups` first, the `CodeBlock` discipline,
        handle_codeblock.cpp:19-24) in the then-block at
        `IfStatementElse` (before the else block is pushed) or, with no
        `else`, at `IfStatement`'s `IfCondition` case before the branch
        (handle_if_statement.cpp:56-66). Those two handlers learn whether
        the `if` is an if-let by extracting the `IfCondition` typed node
        (`context.parse_tree_and_subtrees().ExtractAs<Parse::IfCondition>`
        — lazily built, context.h:87-89) and testing `pattern.has_value()`;
        the node id comes from `PopWithNodeId<IfCondition>()`. Result: the
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
        which is the design's requirement (if-let.md:315-320,
        "ordinary `let`/`var` bindings of the enclosing scope").

6.  **CHECK, deferred alternative resolution (the one engine change).**
    `HandleParseNode(AlternativePatternId)` (handle_match.cpp:370-565)
    gains a deferred mode, entered when
    `match_case_stack().back().scrutinee_type_id` is `None` (the value the
    new forms push, since the initializer has not been checked). In that
    mode the handler does only the scrutinee-independent half of its
    work: it pops the payload list and name exactly as today (:376-388),
    synthesizes the root `TuplePattern` over the payload subpatterns
    exactly as today (:518-553; for the bare `.Name` spelling it
    synthesizes an EMPTY `TuplePattern`, so the root is always a tuple
    pattern), computes `payload_is_irrefutable` (:507-514), records
    `MatchCaseContext::pending_alternative = {name_id, node_id, has_parens,
    root_id, payload_is_irrefutable}` (a new optional struct), and pushes
    the root. Resolution runs at the start of the shared test driver
    (§2.3 step 2) once the scrutinee is known, in a new function
    `ResolvePendingAlternative(context, case_context, scrutinee_id)`
    factored out of the existing handler so that `match` and the new
    forms share one body: the choice gate (:394-398 — under the new
    forms the TODO location is the form's introducer node), the
    `LookupChoiceAlternative` (:405), the parens-iff-parameters rules
    (`MatchAlternativeUnexpectedParens` :410-418,
    `MatchAlternativeMissingParens` :462-470), the standard member-access
    diagnostic for an unknown name (:420-421, emitted into the current
    block — no expression region is involved), and
    `MatchAlternativeArgCountMismatch` (:471-495). On success it fills
    `case_context.alternative = {index, payload_field_index,
    payload_pattern_id = root_id, payload_is_irrefutable}` — for the bare
    spelling too, with the empty root. The engine then needs no new lane:
    `MatchCaseAlternativePatternMatch` (pattern_match.cpp:561-658) reads
    only `alternative`; with `payload_is_irrefutable` it returns the
    discriminant test alone (:597-600) or constant `true` for a
    single-alternative choice (:578-590), never touching the root; and the
    bind pass skips a binding-free root (`MatchCasePatternHasBindings`,
    handle_match.cpp:999, :1031). The `designator_root_id` lane
    (pattern_match.cpp:1215-1245) stays `match`-only. Break condition: a
    review finding that the empty-root trick breaks an engine CHECK —
    then the bare spelling records `payload_pattern_id = None` and the
    driver classifies "alternative && !payload_pattern_id" as the
    discriminant-only lane explicitly; same SemIR.

7.  **Usefulness / exhaustiveness: structurally unreachable, not
    suppressed.** Both blocks live in `EmitCaseArmTestAndBind`
    (handle_match.cpp:824-951) and read `match_statement_stack().back()`,
    which only `MatchStatementStart` pushes (:306-316); the factored
    driver (§2.3) does not contain them and the new forms never push a
    `MatchStatementContext`. `DiagnoseDeadDefault`/`DiagnoseNonexhaustiveMatch`
    run from `MatchDefault`/`MatchStatement` handlers only (:1327, :1565).
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
    syntactic list (if-let.md:308-314; F-011 "syntactic divergence list")
    is accepted verbatim, and so is a block whose every path diverges
    (`else { if (c) { return 1; } else { return 2; } }`, because
    `AddConvergenceBlockAndPush` yields an unreachable block when no
    predecessor is reachable, control_flow.cpp:54-65). `else { Abort(); }`
    is still rejected (no noreturn typing; if-let.md:311-313 defers that
    to the error-handling design). Recorded in the decision log as a
    refinement of F-011's wording (veto-able): one predicate, already the
    compiler's notion of "does not complete normally". Break condition:
    the owner insisting on the literal list — then the check becomes a
    parse-node-kind test on the block's last statement, one function,
    same diagnostic. Bindings inside the else block: the names are in the
    enclosing scope from pattern time (§1.5), but they are never
    initialized on the else path — so the `StartPatternInitializer`
    tombstones (full_pattern_stack.cpp:15-33; they make a use diagnose
    `UsedBeforeInitialization`, pinned at toolchain/check/testdata/let/
    fail_use_in_init.carbon) are kept live through the else block and
    released by `EndPatternInitializer` only at `LetElseDecl`, before
    the bind pass. Zero new machinery; pinned in §4.

9.  **`let`-`else` outside a function body is an error at the
    introducer.** The parser cannot tell statement `let` from file/class
    scope `let` (both reach `StateKind::Let`, handle_decl_scope_loop.cpp:
    140-143), so `let x: i32 = 1 else { }` parses everywhere and check
    gates it: `LetElseOutsideFunction` when
    `!context.scope_stack().IsInFunctionScope()` (scope_stack.h:143-146),
    aborting the declaration like a TODO (return false). Design basis:
    the else block must `return`/`break`/`continue` (if-let.md:308-314),
    none of which exists outside a function.

10. **Irrefutable patterns warn.** Per if-let.md:325-328 and F-011:
    `IrrefutablePatternAlwaysMatches` (Warning) when the pattern cannot
    fail — `IsIrrefutableMatchCasePattern(root)` (pattern_match.h:144-145)
    for non-alternative roots, or a resolved alternative whose choice has
    a single alternative and whose payload is irrefutable (that arm is a
    constant-`true` test, pattern_match.cpp:578-590, and handle_match.cpp:
    142-150). Checked after resolution (§2.3 step 3), because the empty
    synthetic root of a bare `.Name` is itself "irrefutable".

11. **`and`/`or` at the top level of a pattern-condition initializer is
    reserved, by a check-time error.** The design keeps `)` right after
    the initializer so let-chains can be added later (if-let.md:329-333).
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

12. **The `if`-expression ambiguity (if-let.md:334-339): forbidden at
    the `else`, plus a targeted recovery for the misparse.** (a) In
    `HandleLetFinish`/`HandleVarFinish`, when the next token is `else` and
    the initializer's root node (`context.tree().node_kind(NodeId(size-1))`,
    context.h:475, tree.h:121) is `IfExprElse`, diagnose
    `LetElseUnparenthesizedIfExpr` and mark the declaration errored (it is
    still parsed as a `let`-`else` for recovery). (b) In
    `HandleIfExprFinishThen` (handle_if_expr.cpp:34-54), before consuming
    `else`: if the next-next token is `{` and the state stack below is
    `[…, LetFinishAsRegular | VarFinish, IfExprFinish]` (the
    if-expression is the whole initializer — state-stack inspection is
    precedented at handle_expr.cpp:249-255 and context.cpp:449-456),
    emit the same diagnostic, do NOT consume the `else`, and return the
    if-expression with an error (`ReturnErrorOnState` plus the two
    `AddInvalidParse` the existing missing-`else` path adds, :50-52);
    `HandleLetFinish` then sees `else` and parses the `let`-`else`, so the
    user gets one diagnostic and a sane tree. Without (b) the user sees
    the struct-literal error the design paper describes (:336-337).

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
`HandleMatchCaseIntroducer` (parse/handle_match.cpp:158-178: `.`
`Identifier` → `PushStateForPattern(MatchCaseAlternativePattern, …)`, else
`Pattern`), taking `in_var_pattern`, and is called from `HandleLet`,
`HandleVar` and `HandleMatchCaseIntroducer` too (§1.13). It lives in
handle_pattern.cpp with a declaration in handle.h. The `MatchCaseAlternativePattern`
states (:181-212) already propagate `in_var_pattern` into the payload list
(:193-196).

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
    if (context.tree().node_kind(NodeId(context.tree().size() - 1)) ==
        NodeKind::IfExprElse) {
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
recovery, before `ConsumeChecked(Else)`.

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

// Ends the pattern of a refutable pattern context (the `FinishCasePattern`
// body: initializing-category conversion, `EndExprRegionForPattern`, pop
// the pattern root into the context) and starts its initializer
// (`StartPatternInitializer`).
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
// `warn_irrefutable` and the pattern cannot fail. Leaves the full-pattern
// frame and the case context pushed for the bind pass.
struct RefutableBindingTest {
  SemIR::InstId cond_id;
  bool is_irrefutable;
};
auto EmitRefutableBindingTest(Context& context, Parse::NodeId node_id,
                              SemIR::InstId pattern_id,
                              SemIR::InstId scrutinee_id,
                              bool warn_irrefutable)
    -> std::optional<RefutableBindingTest>;

// Bind pass, in the current (success) block: the lane selection of
// handle_match.cpp:972-1048 (`LocalPatternMatch` for all-binding `var`-free
// trees, `MatchCaseBindPatternMatch` otherwise, payload extraction for a
// resolved alternative), then `DeferCleanups`. Pops the full-pattern frame
// and the case context.
auto EmitRefutableBindingBind(Context& context, Parse::NodeId node_id,
                              SemIR::InstId pattern_id,
                              SemIR::InstId scrutinee_id) -> void;
```

`EmitCaseArmTestAndBind` becomes: `EmitRefutableBindingTest` (with
`warn_irrefutable = false` — an irrefutable `case` arm is the exhaustive
arm, not a warning) → the two match-only blocks (usefulness :824-914,
coverage :916-951, byte-identical) → `PopFullPattern`/`pop_back` as today
→ branches → `EmitRefutableBindingBind`. The frame/context pop ordering
differs slightly between the callers (match pops before branching, the
new forms after binding); the driver takes the pops at the end of the
bind pass and `match` keeps its own pops where they are — the bind lanes
themselves read only `alternative` (copied) and `pattern_id`, never the
frame (handle_match.cpp:746-749 copy note). `MatchCaseIntroducer` (:318-346)
becomes `scope push; BeginRefutableBinding(node_id); set scrutinee_type_id
= type of PeekScrutinee()` — the only place the type is filled at pattern
time. `ResolvePendingAlternative` (§1.6) is called from the driver and from
`AlternativePattern` (immediate mode) alike.

### §2.3 Check handlers for the new parse nodes

**`PatternConditionIntroducerId`** (new handler, in handle_if_statement.cpp
or a new handle_pattern_condition.cpp):

```cpp
  if (context.node_stack().PeekIs(Parse::NodeKind::IfConditionStart)) {
    // if-let: the bindings' scope, popped before the else arm.
    context.scope_stack().PushForSameRegion(ScopeStack::CleanupScopeKind::Owned);
  } else {
    CARBON_CHECK(context.node_stack().PeekIs(Parse::NodeKind::WhileConditionStart));
  }
  BeginRefutableBinding(context, node_id);
  context.node_stack().Push(node_id);
```

**`PatternConditionInitializerId`**: `EndRefutableBindingPattern(context)`;
push node. (The pattern's region is now closed: the initializer checks at
region depth 1, §1.7.)

**`IfConditionId`** (handle_if_statement.cpp:18-40) — the pattern path,
entered when `PeekNextIs(PatternConditionInitializer)` after
`PopExprWithNodeId()`:

1.  `PatternConditionChainReserved` if the initializer's node kind is a
    short-circuit operator root (§1.11) — diagnose and continue with the
    value.
2.  `scrutinee = CheckRefutableScrutinee(…, "refutable pattern binding on
    unsupported scrutinee type")`; `None` → `return false`.
3.  `full_pattern_stack().EndPatternInitializer()`; pop the initializer
    solo node, the pattern (`PopPattern`), the introducer solo node, the
    `IfConditionStart` solo node.
4.  `test = EmitRefutableBindingTest(…, warn_irrefutable = true)`;
    `nullopt` → `return false`.
5.  `then = AddDominatedBlockAndBranchIf(cond)`, `else = AddDominatedBlockAndBranch()`,
    pop/push then, `AddToRegion` — the existing lines :29-36 verbatim (the
    labels are `if.then`/`if.else` because the node is `IfCondition`).
6.  `EmitRefutableBindingBind(…)` in the then block.
7.  `node_stack().Push(node_id, else_block_id)` — identical to the
    expression path, so `IfStatementElse`/`IfStatement` see the same
    entry.

The expression path is the existing body with one added
`PopAndDiscardSoloNodeId<IfConditionStart>()`.

**`IfStatementElseId`** (:42-52) and **`IfStatementId`** (:54-82): before
the existing work, `auto [cond_node_id, else_block_id] =
PopWithNodeId<IfCondition>()`; if `IsPatternCondition(cond_node_id)`
(`ExtractAs<Parse::IfCondition>(...)->pattern.has_value()`), run
`AddAndDiscardScopeCleanups(context); scope_stack().Pop(/*check_unused=*/true);`
in the then block (§1.5). `IfStatement`'s `IfStatementElse` case is
unchanged (the scope was popped at `IfStatementElse`).

**`WhileConditionId`** (handle_loop_statement.cpp:103-115) — pattern path,
same detection: steps 1-3 as above (popping `WhileConditionStart` yields
`loop_header_id` as today), then `BranchAndStartLoopBody(…, cond)` verbatim
(:44-71 — the `ConvertToBoolValue` is a no-op on a bool; labels
`while.body`/`while.done`), then `EmitRefutableBindingBind` in the body
block. `WhileStatement` (:117-121) is unchanged: `FinishLoopBody` adds the
back-edge to the header — where the initializer is re-evaluated and the
pattern re-tested each iteration — and pops the loop scope, so the bindings
end with the loop. `break`/`continue` inside the body use the
`break_continue_stack` entry `BranchAndStartLoopBody` pushed (:66-70);
`continue` destroys header temporaries (none of consequence: the scrutinee
gate admits only trivially destructible shapes, handle_match.cpp:245-253,
the same argument `match` makes).

**`LetElseIntroducerId`**: if `!scope_stack().IsInFunctionScope()` →
`LetElseOutsideFunction`, `return false`. Else
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
    (either kind), `PopPattern()`, pop `LetElseIntroducer`.
2.  `scrutinee = CheckRefutableScrutinee(…, same TODO string)`.
3.  `test = EmitRefutableBindingTest(…, warn_irrefutable = true)`.
4.  `then = AddDominatedBlockAndBranchIf(cond)`; `else_block =
    AddDominatedBlockAndBranch()`; `inst_block_stack().Pop()`;
    `Push(else_block)`; `AddToRegion(else_block, node_id)` — the `?`
    desugar's shape (handle_question.cpp:377-395: test, the diverging
    block emitted first, the continuation after).
5.  `node_stack().Push(node_id, then_block_id)`; the pattern and scrutinee
    stay reachable through the case context (`pattern_id` is already a
    `MatchCaseContext` field, context.h:296-300; add `scrutinee_id`).
    The tombstones stay live (§1.8).

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
    tombstones, §1.8); `EmitRefutableBindingBind(…)` in the success block
    — the bindings are now initialized on the only path that continues,
    in the enclosing scope, with `DeferCleanups` so they live to the end of
    that scope (the `let` rule, handle_let_and_var.cpp:367-369).
5.  `decl_introducer_state_stack().Pop<Let>()`.

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
    // The converted scrutinee, for the bind pass of a `let`-`else`.
    SemIR::InstId scrutinee_id = SemIR::InstId::None;
```

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
```

| Kind | Level | Text | Site |
| --- | --- | --- | --- |
| ExpectedPatternConditionInitializer | Error | ``expected `=` after the pattern in a pattern condition`` | parse, §2.1 |
| LetElseUnparenthesizedIfExpr | Error | ``` `if` expression initializer of a `let`-`else` declaration must be parenthesized ``` | parse, §1.12 (a) and (b) |
| IrrefutablePatternAlwaysMatches | Warning | `pattern always matches, so this binding cannot fail` | check, at the introducer node |
| LetElseBlockFallsThrough | Error | ``` `else` block of a `let`-`else` declaration must not complete normally; end it with `return`, `break`, or `continue` ``` | check, at the `else` node |
| LetElseOutsideFunction | Error | ``` `let`-`else` declaration can only be used inside a function body ``` | check, at the introducer |
| PatternConditionChainReserved | Error | ``` `and`/`or` at the top level of a pattern condition's initializer is reserved for pattern chaining; parenthesize the expression ``` | check, at the initializer |

Reused unchanged: `ExpectedCodeBlock` (missing `{` after `else`),
`IncompleteTypeInMatchScrutinee` (context note text "matching on value of
incomplete type {0}" fits all forms), `UsedBeforeInitialization` (binding
used in the else block, §1.8), `UnusedBinding`, `UnusedPatternNoBindings`,
`MatchAlternativeMissingParens`/`UnexpectedParens`/`ArgCountMismatch`,
`NameNotFound`, and every engine `SemanticsTodo` string. New
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
    (:817): the grammar of if-let.md:293-300 (both `let` and `var`
    spellings), the semantics of :302-333 (test-and-bind; then-block
    scoping for `if`, body scoping and per-iteration rebinding for
    `while`, enclosing-scope bindings for `let`-`else`; the else block
    must not complete normally, with the 0.1 rule stated as
    "return/break/continue or a block all of whose paths do so";
    irrefutable patterns warn; p005164 failure destruction unchanged;
    `and`/`or` reserved for chaining; the `if`-expression initializer
    parenthesization rule), the three examples of :244-291 adapted to
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

**fork/gap-analysis.md:57**: status MISSING → PARTIAL (§8.6); detail
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

**Parse — toolchain/parse/testdata/if/if_let.carbon** (positive): subfiles
`let_binding` (`if (let n: i32 = x) {}`), `var_binding`, `alternative_bare`
(`.None`), `alternative_payload` (`.Some(n: i32)`), `tuple`
(`(0, n: i32)`), `else_if_chain` (`if (let …) {} else if (let …) {} else {}`
— exercises `StatementIfThenBlockFinish`'s `else if` special case,
handle_statement.cpp:196-199, with a pattern condition in the chained
`if`), `nested_in_match_arm`, `parenthesized_and` (`(x and y)` initializer).
**fail_if_let_missing_initializer.carbon** (`if (let n: i32) {}` →
`ExpectedPatternConditionInitializer` + recovery to `)`),
**fail_if_let_missing_pattern.carbon** (`if (let = x)` → the pattern
parser's `ExpectedPattern`-family error, recovery pinned).
**toolchain/parse/testdata/while/while_let.carbon** (`let`, `var`,
payload alternative), **fail_while_let_missing_initializer.carbon**.
**toolchain/parse/testdata/let/let_else.carbon**: `basic`, `alternative_payload`,
`alternative_bare`, `var_else`, `tuple`, `with_modifier` (`private let … else`
parses; check rejects). **fail_let_else_missing_block.carbon**
(`let x: i32 = y else return;` → `ExpectedCodeBlock`, handle_code_block.cpp:22),
**fail_let_else_if_expr.carbon** (both §1.12 shapes:
`let x: i32 = if c then 1 else { return 0; }` and
`let x: i32 = if c then 1 else 2 else { return 0; }` — one diagnostic each,
`LetElseUnparenthesizedIfExpr`), **fail_let_else_trailing_semi.carbon**
(`let … else { return; };` — the stray `;` is diagnosed as today's empty
expression statement; documents the no-`;` decision).
**toolchain/parse/testdata/let/alternative_root.carbon**: plain
`let .Some(n: i32) = e;` and `var .None = e;` now parse (§1.13).

**Check — toolchain/check/testdata/if/if_let.carbon** (positives, silent):

| subfile | shape | pins |
| --- | --- | --- |
| alternative_payload | `if (let .Some(n: i32) = opt) { return n; } else { return 0; }` on a two-alternative choice | discriminant test, `if.then`/`if.else`, bind in then |
| alternative_bare | `if (let .None = opt) {}` | discriminant test only, no bind insts (empty root) |
| payload_literal | `if (let .Some(42) = opt)` | payload block dominated by the discriminant test |
| tuple_root | `if (let (0, n: i32) = pair)` | elementwise fold |
| var_spelling | `if (var .Some(n: i32) = opt) { n = n + 1; … }` | on-demand `VarStorage` in the then block |
| ref_binding | `if (let .Some(ref r: i32) = v)` on a `var` scrutinee | ref lane |
| else_if_chain | two pattern conditions chained | nested `if` scopes |
| question_in_initializer | `if (let .Some(n: i32) = F()?)` in a `Core.Try`-returning fn | `?` legal at depth 1 (§1.7) |
| struct_root | `if (let {.a = 1, b: i32} = s)` | W-077 lane admitted by way of `CurrentKind()` (lands only if W-077 is in trunk; otherwise moves to the fail_todo file) |
| single_alternative | `if (let .Only(n: i32) = x)` on a one-alternative choice | constant-true test AND `IrrefutablePatternAlwaysMatches` — placed in the fail file below instead |

**toolchain/check/testdata/if/fail_if_let.carbon**:

| subfile | shape | expect |
| --- | --- | --- |
| fail_binding_in_else | binding named in the `else` arm | `NameNotFound` (scope popped at `IfStatementElse`) |
| fail_binding_after | binding named after the statement | `NameNotFound` |
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
| fail_todo_form_binding, fail_todo_compile_time_binding | `if (let form n: i32 …)`, `if (let n:! i32 …)` | the two handle_binding_pattern.cpp gates at the introducer |
| fail_todo_qualified_alternative | `if (let Opt.None = opt)` | engine TODO ``qualified alternative pattern in match case`` |
| fail_incomplete_scrutinee | forward-declared class value | `IncompleteTypeInMatchScrutinee` context |

**toolchain/check/testdata/while/while_let.carbon**: `pop_loop`
(`while (let .Some(x: i32) = Next(cur)) { cur = x; }`), `break_continue`,
`var_spelling`; **fail_while_let.carbon**: `fail_binding_after_loop`
(`NameNotFound`), `fail_irrefutable` (Warning), `fail_chain_reserved`.

**toolchain/check/testdata/let/let_else.carbon** (positives): `alternative_payload`
(`let .Some(port: i32) = e else { return -1; } return port;`), `alternative_bare`,
`tuple`, `var_else` (mutated after), `break_in_loop`, `continue_in_loop`,
`nested_all_paths_return` (`else { if (c) { return 1; } else { return 2; } }`
— accepted, §1.8), `let_else_in_match_arm_body`, `two_in_sequence`
(second let-else's initializer uses the first's binding).
**fail_let_else.carbon**:

| subfile | shape | expect |
| --- | --- | --- |
| fail_empty_else | `else {}` | `LetElseBlockFallsThrough` |
| fail_else_ends_in_expr | `else { F(); }` | same |
| fail_else_partial_return | `else { if (c) { return 1; } }` | same (convergence reachable) |
| fail_binding_used_in_else | `else { Print(port); return; }` | `UsedBeforeInitialization` (§1.8) |
| fail_file_scope | `let x: i32 = 1 else { }` at file scope | `LetElseOutsideFunction` |
| fail_class_scope | inside `class C { … }` | same |
| fail_irrefutable | `let n: i32 = x else { return; }` | `IrrefutablePatternAlwaysMatches` |
| fail_modifier | `private let .Some(n: i32) = e else { return; }` | the existing access-modifier rejection for locals (handle_let_and_var.cpp:341-350 path) |
| fail_todo_unsupported_scrutinee | class-typed initializer | the shape TODO |

**toolchain/check/testdata/let/fail_todo_alternative_root.carbon**: plain
`let .Some(n: i32) = e;` and `var .None = e;` → TODO ``alternative pattern
outside a refutable pattern context`` (§1.13 pin).

**Lower — toolchain/lower/testdata/if/if_let.carbon, while/while_let.carbon,
let/let_else.carbon**: one function each over the two-alternative choice,
pinning the discriminant load + `icmp` + `br` and the block labels
(`if.then`/`if.else`/`if.done`; `while.body`/`while.done`; `let.then`/
`let.else`), with zero lower/ code change (the toolchain/lower/testdata/match/
choice_payload.carbon shape).

**Extensions to existing files: none** (§6). R26 note: all new files, so
the hosted autoupdate converges in at most two passes and touches nothing
else.

## §5 Conformance

**Un-SKIP if_let_let_else.carbon and add one program; the floor becomes
104 PASS / 0 FAIL / 27 SKIP over 131** (from W-077's 102 / 0 / 28 over
130: one SKIP → PASS, one new PASS). Both under the existing bullet
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
// var-else: mutable storage after the declaration.
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
first two lines keep the original stub's `42`/`0`.

**control_flow/while_let.carbon** (new):

```carbon
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
    and check rejects it (§1.9). No golden pins the old behavior (grep
    `else` in toolchain/parse/testdata/let and /var: none).

**Compiler files touched:** toolchain/lex/token_kind.def (one budget
entry); toolchain/parse/{node_kind.def, state.def, typed_nodes.h,
context.h, context.cpp, handle.h, handle_paren_condition.cpp,
handle_let.cpp, handle_var.cpp, handle_pattern.cpp, handle_match.cpp
(`PushRootPattern` call), handle_if_expr.cpp}; toolchain/check/{BUILD,
refutable_binding.h, refutable_binding.cpp (new), context.h,
handle_match.cpp, handle_if_statement.cpp, handle_loop_statement.cpp,
handle_let_and_var.cpp, full_pattern_stack.h, full_pattern_stack.cpp};
toolchain/sem_ir/inst_namer.cpp; toolchain/diagnostics/kind.def.

**New files:** the §4 testdata (parse 9, check 7, lower 3), the §5
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
-   **R-4 Reachability vs the literal syntactic list (§1.8).** The
    predicate accepts strictly more than the list (all-paths-diverging
    blocks) and nothing the list rejects for a reason. Veto-able; the
    break condition is one function.
-   **R-5 `var` spellings and cleanup.** On-demand `VarStorage` lands in
    the success block (if-let: then block; while-let: body; let-else: the
    continuation) with `DeferCleanups`, so destruction happens at the
    owning scope's end (if-let: the §1.5 scope pop in the then block;
    while-let: `FinishLoopBody`'s exit-block cleanups; let-else: the
    enclosing scope). In-slice scrutinee types are trivially destructible
    (handle_match.cpp:245-253), so the failure-path destruction rule
    (p005164, pattern_matching.md:776-792) has no observable work yet —
    the same recorded state `match` is in.
-   **R-6 The if-expression recovery (§1.12(b)) inspects the state
    stack.** Precedented (handle_expr.cpp:249-255); its scope is one
    token pair (`else` `{`) in one syntactic position. If a review finds
    a false positive (`let x: {.a: i32} = if c then y else {.a = 1};`
    — a struct literal that IS the intended else operand), the check
    adds a lookahead for `{` `.`/`}`; recorded as the one known
    ambiguity of the heuristic. Alternatively drop (b) and keep only
    (a): users then see the struct-literal error the design anticipated.
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
-   **Options B/C/D** of the design paper — rejected by F-011; not
    reopened.

## §8 Verification and discharge

1.  **Regen:** hosted autoupdate (`Fork: hosted verification`, mode
    autoupdate; R28(b)) to R26 fixpoint. Expected: diffs ONLY in the
    §4 new files; in particular ZERO diffs under toolchain/check/testdata/
    match (70 files) and toolchain/lower/testdata/match (9 files) — the
    §6.4 behavior-preservation proof. Any other movement is a §6 miss:
    stop and reconcile.
2.  **Gate:** hosted gate mode green (R21 mirror), `uvx prek run --files
    <changed>` clean locally first (R25), clang-format 21.1.8 on the C++
    diff (R18); parse coverage test green (all five node kinds appear in
    §4 parse goldens).
3.  **Conformance:** hosted conformance mode: **104 PASS / 0 FAIL / 27
    SKIP over 131**; `runner.py --self-test` green (R7).
4.  **Reconciliation greps at discharge:** ``expression pattern`` TODO
    site count unchanged (pattern_match.cpp:1192 only); the new TODO
    strings appear at exactly one code site each plus their §4 pins;
    ``match `case` pattern other than an integer literal, or a case
    guard`` site count unchanged; `Kind::MatchCaseArm` site count grew
    only by the new handlers and the CHECK relaxation; `IsSupportedScrutineeType`
    has one definition (refutable_binding.cpp).
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
        evidence = pattern_match.cpp:1192 and the §4 fail_todo pins;
        (b) let-chains (`if (let P = e and c)`), evidence = the
        `PatternConditionChainReserved` site and if-let.md:329-333;
        (c) type-based (noreturn) divergence for `let`-`else` replacing
        the reachability rule once the error-handling design defines it
        (if-let.md:311-313, :565-571).
    -   Decision-log entry "W-012: if-let / while-let / let-else landed
        (date)" carrying §1.2/§1.3 (the tree shapes, the re-kind, the
        `else` budget), §1.4 (`MatchCaseArm` reuse), §1.6 (deferred
        resolution), §1.8 (the reachability refinement of F-011 and the
        tombstone rule — both veto-able), §1.11-§1.13 (the two
        reservations and the root peek), and §7 R-6, each with its break
        condition; F-011's design rider 2 (mechanical re-spelling if
        upstream #5101 lands differently) restated with the parse surface
        this slice actually has (five node kinds, two states).
6.  **fork/gap-analysis.md:57:** status MISSING → **PARTIAL**, detail:
    "Parsed, checked and lowered as desugarings onto the match engine
    (parse/if, parse/while, parse/let goldens; check/if, check/while,
    check/let; lower/); both forms conformance-PASS. Residue shared with
    the `match` row: the engine's scrutinee/pattern admission gates
    (class-typed and adapter scrutinees, form/compile-time bindings,
    qualified alternatives), plus `and` chaining reserved and the
    noreturn-based divergence rule deferred to the error-handling
    design." Justification for PARTIAL rather than DONE: the bullet's
    "combined match control flow" inherits every gate the match bullet
    (itself PARTIAL, :55) still carries — the two rows flip to DONE
    together when the engine's gates close. R7: the bullet text is
    untouched.

## Hand-off notes for the implementer

-   Do the `EmitCaseArmTestAndBind` factoring on the tree AFTER W-077
    merges (its 15207a17f version of the function is the base); carry the
    classification lane list over verbatim and keep the usefulness and
    coverage blocks in the `match` caller at their current position
    relative to the branches.
-   `MatchCaseIntroducer` must keep filling `scrutinee_type_id` at
    pattern time; only the new forms leave it `None`. `ResolvePendingAlternative`
    is the single body for both — do not fork the diagnostics.
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
-   `IfConditionStart` now pushes its node id: pop it in BOTH `IfCondition`
    paths.
-   `else` in token_kind.def becomes `CARBON_TOKEN_WITH_VIRTUAL_NODE`; do
    the §1.2/§1.3 node-count arithmetic against any tree shape you change
    before firing autoupdate — `Tree::Verify` failures show up as
    CHECK-crashes, not diagnostics.
-   Fail-matrix bindings: used or `unused`-marked.
