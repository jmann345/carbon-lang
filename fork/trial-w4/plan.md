# W4 Slice 1 implementation plan: `match` statement (integer scrutinee, integer-literal cases, `default`)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

Status: PLAN (trial run, process step 5). Author context: fork/process.md +
fork/rulebook.md loaded; design authority docs/design/pattern_matching.md and
docs/design/control_flow/. Work item: fork/inventory/work-items.json W4 entry
("all 14 check handlers are TODO stubs", toolchain/check/handle_match.cpp:13-77).

## 0. Slice boundary (restated as checkable behavior)

In slice: `match (<int-expr>) { case <int-literal> => { ... } ... default => { ... } }`
as a _statement_. Everything else — binding patterns, tuple patterns,
`unused`/`var` patterns, guards (`if (...)`), choice/variant patterns, missing
`default`, non-integer scrutinee — must keep producing a clean
`semantics TODO: ...` error (Context::TODO → emit + return false, which aborts
the file check in CheckUnit::ProcessNodeIds, toolchain/check/check_unit.cpp:417-423).
No crash, no silent mischeck. There is no expression-form `match` in the parse
tree (only `NodeKind::MatchStatement`, category Statement — parse/typed_nodes.h:999),
so nothing to guard there.

## 1. Parse-side facts the checker consumes (verified in worktree)

Node kinds and shapes: toolchain/parse/typed_nodes.h:920-1008; producer:
toolchain/parse/handle_match.cpp; goldens: toolchain/parse/testdata/match/.
Postorder node sequence for one match (from parse/testdata/match/match.carbon):

```
MatchIntroducer                    (leaf)
MatchConditionStart                (leaf, '(')
<scrutinee expr nodes>
MatchCondition                     (2 children)
MatchStatementStart                ('{', bracketed by MatchIntroducer)
  per case arm:
    MatchCaseIntroducer            (leaf, 'case')
    <pattern nodes>                (AnyPatternId = Pattern|Expr category!)
    [MatchCaseGuardIntroducer, MatchCaseGuardStart, <expr>, MatchCaseGuard]
    MatchCase                      ('=>')
    MatchHandlerStart              ('{')
    <statement nodes>
    MatchHandler                   ('}')
  default arm:
    MatchDefaultIntroducer         (leaf, 'default')
    MatchDefault                   ('=>')
    MatchHandlerStart / stmts / MatchHandler
MatchStatement                     ('}')
```

Key fact: `case 0` parses through parse/handle_pattern.cpp:53
(StateKind::ExprPattern) and leaves a bare `IntLiteral` node (category
Expr|IntConst, typed_nodes.h:1234) as the MatchCase pattern child —
`AnyPatternId` accepts Expr (parse/node_ids.h:109-110). No wrapper node. So the
in-slice pattern is handled entirely by the existing IntLiteral expr handler;
the out-of-slice patterns are the ones with Pattern-category nodes
(LetBindingPattern etc.), whose handlers (check/handle_binding_pattern.cpp)
CARBON_FATAL / CHECK-fail without pattern-context setup
(FullPatternStack::Kind::NotInEitherParamList → "Unreachable",
handle_binding_pattern.cpp:451-452). Because the traversal is postorder,
pattern nodes are visited BEFORE MatchCase — the abort decision must be made at
MatchCaseIntroducer, by way of parse-tree lookahead (see §3, H5).

Error-recovery trees never reach these handlers: any node with has_error makes
ProcessNodeIds emit "handle invalid parse trees in `check`" and abort
(check_unit.cpp:400-403), so parse-recovered matches (fail_* parse tests) are
already safe.

## 2. Prerequisite plumbing: node_stack.h kind mapping

All Match* node kinds currently sit in the `Id::Kind::Invalid` group of
`NodeStack::NodeKindToIdKindSpecialCases` (toolchain/check/node_stack.h:516-529)
— pushing any of them CHECK-fails. Move:

-   → `Id::KindFor<SemIR::InstId>` group (with CallExprStart, node_stack.h:417):
    `MatchCondition`, `MatchStatementStart`, `MatchHandler` (payload: scrutinee value).
-   → `Id::KindFor<SemIR::InstBlockId>` group (with IfCondition, node_stack.h:427):
    `MatchCase` (payload: the arm's else/next-test block).
-   → `Id::Kind::None` (solo) group (with CodeBlockStart, node_stack.h:456):
    `MatchCaseIntroducer`, `MatchHandlerStart`, `MatchDefault`.
-   Stay `Invalid` (never pushed): `MatchIntroducer`, `MatchConditionStart`,
    `MatchDefaultIntroducer`, `MatchCaseGuardIntroducer`, `MatchCaseGuardStart`,
    `MatchCaseGuard` (guard kinds stay TODO stubs), `MatchFirstIntroducer`
    (unrelated feature, untouched).

The table is consteval-checked, so a miscategorized kind is a compile error,
not a runtime surprise.

## 3. Per-handler behavior (toolchain/check/handle_match.cpp)

Model files: check/handle_if_statement.cpp (block discipline),
check/handle_codeblock.cpp (arm-body scope), check/handle_operator.cpp:30-50
(equality building), check/handle_loop_statement.cpp (ConvertToValueOrRefExpr
precedent for reusable scrutinee). New includes: control_flow.h, inst.h,
operator.h, core_identifier.h (all same bazel target; no BUILD change).

H1 `MatchIntroducer` — no-op, `return true` (mirror IfConditionStart).

H2 `MatchConditionStart` — no-op, `return true`.

H3 `MatchCondition` — pop the scrutinee expr
(`node_stack().PopExpr()`), `ConvertToValueOrRefExpr` (loop_statement.cpp:181
precedent: "so that we can use it multiple times"). Slice gate: if
`!context.types().TryGetIntTypeInfo(type_id)` (sem_ir/type.cpp:170 — sees
through the `i32`/`u32` class adapters by way of object repr, and accepts
`Core.IntLiteral`) → `return context.TODO(node_id, "match on non-integer scrutinee")`.
Then `AddAndDiscardTemporaryCleanups` (mirror IfCondition; safe because integer
values have no cleanups). Push `(MatchCondition, scrutinee_inst_id)`.

H4 `MatchStatementStart` — `Pop<Parse::NodeKind::MatchCondition>()` →
scrutinee; push `(MatchStatementStart, scrutinee)`. No scope, no blocks.

H5 `MatchCaseIntroducer` — **slice gate by parse-tree lookahead** (the parse
tree is stored in postorder; `Parse::NodeId` is the postorder index — index
arithmetic precedent: parse/tree.cpp:83, tree_and_subtrees.cpp:124-133).
The introducer is a leaf, so `NodeId(index+1)` is the first node of the pattern
subtree:

```cpp
auto pattern_first = Parse::NodeId(node_id.index + 1);
auto after_pattern = Parse::NodeId(node_id.index + 2);
if (context.parse_tree().node_kind(pattern_first) != Parse::NodeKind::IntLiteral ||
    context.parse_tree().node_kind(after_pattern) != Parse::NodeKind::MatchCase) {
  return context.TODO(node_id,
      "match `case` pattern other than an integer literal, or a case guard");
}
context.node_stack().Push(node_id);  // solo
```

This is exactly "pattern is a single IntLiteral and there is no guard" (a guard
would put MatchCaseGuardIntroducer at index+2). Aborting HERE is what keeps
out-of-slice binding/tuple/var/unused pattern nodes from ever reaching their
handlers in an unprepared context (§1). Negative literals (`case -1` =
IntLiteral + PrefixOperatorMinus) are deliberately out of slice.

H6-H8 `MatchCaseGuardIntroducer` / `MatchCaseGuardStart` / `MatchCaseGuard` —
keep the existing `context.TODO` stubs verbatim (defense in depth; unreachable
in-slice because H5 aborts first).

H9 `MatchCase` — build the test, open the arm:

```cpp
auto literal_id = context.node_stack().PopExpr();
context.node_stack().PopAndDiscardSoloNodeId<Parse::NodeKind::MatchCaseIntroducer>();
// Scrutinee: below us is MatchStatementStart (first arm) or MatchHandler (later arms).
auto scrutinee_id = context.node_stack().PeekIs(Parse::NodeKind::MatchHandler)
    ? context.node_stack().Peek<Parse::NodeKind::MatchHandler>()
    : context.node_stack().Peek<Parse::NodeKind::MatchStatementStart>();
// scrutinee == literal, exactly as `n == 0` in an `if` (handle_operator.cpp:30-50,131-135):
SemIR::InstId args[] = {
    context.types().GetTypeInstId(context.insts().Get(literal_id).type_id())};
auto eq_id = BuildBinaryOperator(context, node_id,
                                 {.interface_name = CoreIdentifier::EqWith,
                                  .interface_args_ref = args,
                                  .op_name = CoreIdentifier::Equal},
                                 scrutinee_id, literal_id);
auto cond_id = ConvertToBoolValue(context, node_id, eq_id);
auto then_block_id = AddDominatedBlockAndBranchIf(context, node_id, cond_id);
auto else_block_id = AddDominatedBlockAndBranch(context, node_id);
context.inst_block_stack().Pop();          // test block complete
context.inst_block_stack().Push(then_block_id);
context.region_stack().AddToRegion(then_block_id, node_id);
context.node_stack().Push(node_id, else_block_id);   // MatchCase → InstBlockId
```

(`EqWith`/`Equal` exist: check/core_identifier.def:44-45.)

H10 `MatchDefaultIntroducer` — no-op, `return true`.

H11 `MatchDefault` — `context.node_stack().Push(node_id)` (solo). No emission:
after the last case's MatchHandler (H13), the current block is already that
case's else block, which IS the default body. Parse guarantees default is last
(UnreachableMatchCase, parse/handle_match.cpp:120-138; error trees abort per §1).

H12 `MatchHandlerStart` — arm body scope, mirror CodeBlockStart
(handle_codeblock.cpp:12-17):
`scope_stack().PushForSameRegion(ScopeStack::CleanupScopeKind::Owned)`;
push solo node.

H13 `MatchHandler` — close the arm, mirror CodeBlock + IfStatementElse:

```cpp
AddAndDiscardScopeCleanups(context);
context.scope_stack().Pop(/*check_unused=*/true);
context.node_stack().PopAndDiscardSoloNodeId<Parse::NodeKind::MatchHandlerStart>();
if (context.node_stack().PeekIs(Parse::NodeKind::MatchCase)) {
  // Case arm: leave the finished body block on the inst block stack (it will
  // be converged in H14) and start emitting the else/next-test block.
  auto else_block_id = context.node_stack().Pop<Parse::NodeKind::MatchCase>();
  context.inst_block_stack().Push(else_block_id);
  context.region_stack().AddToRegion(else_block_id, node_id);
  auto scrutinee_id = context.node_stack().PeekIs(Parse::NodeKind::MatchHandler)
      ? context.node_stack().Peek<Parse::NodeKind::MatchHandler>()
      : context.node_stack().Peek<Parse::NodeKind::MatchStatementStart>();
  context.node_stack().Push(node_id, scrutinee_id);   // MatchHandler → InstId
}
// else: default arm — leave the MatchDefault solo entry for H14; the default
// body block stays on the inst block stack; push nothing.
```

H14 `MatchStatement` — converge:

```cpp
bool has_default = context.node_stack()
    .PopAndDiscardSoloNodeIdIf<Parse::NodeKind::MatchDefault>();
int num_case_arms = 0;
while (context.node_stack().PeekIs(Parse::NodeKind::MatchHandler)) {
  context.node_stack().Pop<Parse::NodeKind::MatchHandler>();
  ++num_case_arms;
}
context.node_stack().Pop<Parse::NodeKind::MatchStatementStart>();  // discard scrutinee
if (!has_default) {
  // docs/design/pattern_matching.md ("If the patterns in a `match` are not
  // exhaustive and no `default` is provided" → error): non-exhaustive match
  // must not silently fall through; real exhaustiveness checking is a later slice.
  return context.TODO(node_id, "match statement without `default` arm");
}
// Blocks on the inst block stack from this match: one body block per case arm
// plus the default body block.
int num_blocks = num_case_arms + 1;
if (num_blocks >= 2) {
  AddConvergenceBlockAndPush(context, node_id, num_blocks);
}
// num_blocks == 1: `match (n) { default => {...} }` — body flowed inline; nothing to do.
return true;
```

`AddConvergenceBlockAndPush` (control_flow.cpp:50-67) already skips branches
for unreachable blocks, so arms ending in `return` (which swap in
InstBlockId::Unreachable — handle_return_statement.cpp:56-57) behave exactly as
in if/else, including the all-arms-return case where the resume block itself
becomes Unreachable.

Interactions checked: nested match (stack discipline is reentrant; inner
MatchCase peek sees the inner MatchStatementStart); `break`/`continue` inside an
arm target the enclosing loop through match untouched (break_continue_stack is
not modified); arm bodies containing if/while leave net one block on the inst
block stack (their own convergence restores that invariant).

## 4. SemIR shape for a 3-arm match (2 literal cases + default)

```carbon
fn F(n: i32) { match (n) { case 1 => { A(); } case 2 => { B(); } default => { C(); } } D(); }
```

is checked into exactly the SemIR of `if (n == 1) { A(); } else if (n == 2) { B(); } else { C(); } D();`:

```
!entry:
  %n.ref  = name_ref n                             // scrutinee, ConvertToValueOrRefExpr'd
  %int_1  = int_value 1                            // constant, IntLiteral type
  ...impl_witness_access / bound_method insts...   // i32 as EqWith(IntLiteral), fn Equal
  %Equal.call: init bool = call ...(%n.val, %.1)   // literal converted per EqWith impl
  %cond: bool = value_of_initializer/converted %Equal.call
  branch_if %cond -> !then.1                       // SemIR::BranchIf
  branch -> !else.1                                // SemIR::Branch
!then.1:   <A() insts>  branch -> !resume          // added by convergence at H14
!else.1:   %int_2, %Equal.call.2, %cond.2, branch_if -> !then.2, branch -> !else.2
!then.2:   <B() insts>  branch -> !resume
!else.2:   <C() insts>  branch -> !resume          // default body IS the last else block
!resume:   <D() insts> ...
```

Op confirmation: integer `==` goes through interface `Core.EqWith(<rhs type>)`,
member `Equal` (handle_operator.cpp:131-135 → BuildBinaryOperator → impl lookup
→ Call inst), whose i32 impl bottoms out in the `int.eq` builtin → LLVM
`icmp eq` in lowering. We call the same BuildBinaryOperator with the same
Operator struct, so check output and lowering are inst-for-inst identical to
the `if` form.

**Lowering: NO changes to toolchain/lower.** Verified basis: the emitted SemIR
contains only pre-existing inst kinds (Branch — lower/handle.cpp; BranchIf —
lower/handle.cpp:147; Call/IntValue/converted — everywhere). No new SemIR inst
kind is introduced, so formatter/typed_insts/lower are all untouched.
Optional cosmetic (recommended, tiny): add `MatchCase` →
`{.prefix="match", .branch_if="case.then", .branch="case.else"}` and
`MatchStatement` → `{.prefix="match", .branch="done"}` to
sem_ir/inst_namer.cpp's GetBranchInfo (default already returns nullopt safely —
sem_ir/inst_namer.cpp:480-481 — so skipping this only costs golden readability).

## 5. Out-of-slice diagnostic strategy (no crash, no mischeck)

One principle: **abort (Context::TODO → return false) before any node whose
handler assumes unprepared context can run.** Concretely:

| Out-of-slice input | Where caught | Diagnostic |
| --- | --- | --- |
| binding / tuple / var / unused / paren pattern in `case` | H5 lookahead (before pattern nodes are traversed) | `semantics TODO: match `case` pattern other than an integer literal, or a case guard` |
| guard `if (...)` on an integer-literal case | H5 lookahead (index+2 is MatchCaseGuardIntroducer, not MatchCase) | same as above |
| non-integer scrutinee (bool, class, tuple, float, choice...) | H3 TryGetIntTypeInfo | `semantics TODO: match on non-integer scrutinee` |
| missing `default` (non-exhaustive) | H14 | `semantics TODO: match statement without `default` arm` |
| negative-literal case `case -1` | H5 (pattern is 2 nodes) | pattern TODO |
| expression-form match | does not exist in parse | n/a |
| choice/variant patterns | choice pattern parse produces Pattern-category nodes → H5 | pattern TODO |

Because TODO returns false and ProcessNodeIds aborts the file, leftover
node/inst-block/scope stack state is irrelevant — this is the established
pattern for every existing mid-construct TODO (for example today's
HandleMatchIntroducer abort inside a function body). The guard-node stubs
(H6-H8) remain as unreachable backstops.

Exact TODO strings above are part of the contract: conformance SKIP reasons
must quote them (rulebook R10).

## 6. Existing goldens that change

Searched all of toolchain/*/testdata for match statements and for the
`HandleMatchIntroducer` TODO text. Exactly **one** existing golden changes:

1.  `/home/user/w4-match/toolchain/check/testdata/patterns/unused.carbon`
    (split-file `fail_todo_match.carbon`, lines 162-176): today expects
    `error: semantics TODO: \`HandleMatchIntroducer\`` at the `match (f(x))`
    line (col 3). After slice 1, MatchIntroducer/Condition succeed (scrutinee
    `f(x)` is i32) and the abort moves to the first `case` (its pattern is
    `unused var (a: i32, b: i32)`): message becomes the H5 pattern TODO,
    location the `case` token (line 169 col 5). CHECK:STDERR block and its
    [[@LINE+n]] offsets must be regenerated/hand-updated.

Not affected: `toolchain/check/testdata/match_first/*` (unrelated
`match_first` impl-prioritization feature); all parse/testdata/match/* (parse
untouched); no lower testdata mentions match; no other check testdata contains
a `match (` statement (verified by grep).

New goldens to ADD (all with AUTOUPDATE):

-   `toolchain/check/testdata/match/basic.carbon` — 3-arm shape of §4.
-   `toolchain/check/testdata/match/default_only.carbon`, `nested.carbon`,
    `converging_arms.carbon` (arms without return; statement after match),
    `constant_scrutinee.carbon` (`match (3)`, IntLiteral-typed scrutinee).
-   `toolchain/check/testdata/match/fail_todo_binding_pattern.carbon`,
    `fail_todo_guard.carbon`, `fail_todo_no_default.carbon`,
    `fail_todo_non_int_scrutinee.carbon`, `fail_todo_non_int_literal_case.carbon`
    (float/bool/negative literal cases).
-   `toolchain/lower/testdata/match/basic.carbon` — locks the "no lower changes"
    claim as an executable golden (icmp eq + br chain).

## 7. Conformance suite impact (fork/conformance/programs/)

-   `control_flow/match_switch.carbon` (bullet "Control flow: matching — good
    switch equivalents"): currently SKIP citing the HandleMatchIntroducer stub.
    Its middle arm `case a: i32 if (a < 0)` is out of slice. Recommendation
    (log per process step 4, scope trade): rewrite arms to slice-1 form —
    probes (0, 1, 42), `case 0 => 10`, `case 1 => 20`, `default => 30`, EXPECT
    updated — literal cases + default is the honest C `switch` equivalent
    (C switch has no guards), then remove SKIP → scoreboard bullet flips PASS
    (R9). Guard/binding coverage moves to a new SKIP program
    (`match_guard_binding.carbon`) citing the H5 TODO text verbatim (R10, R6:
    sketch must at least parse-compile).
-   `project/most_features_missing_match.carbon`: identical structure and same
    out-of-slice guard arm; same treatment (rewrite arms + un-SKIP), or keep
    SKIP with evidence updated to the H5 TODO string. Recommend rewrite+un-SKIP;
    decision-log entry.
-   `control_flow/match_sum_type_payload.carbon`: stays SKIP (choice payloads =
    W5), but its SKIP text cites "every check handler ... is a context.TODO
    stub" — must be updated to the new exact blocking evidence (H5 pattern TODO
    -   choice payload gaps) per R10.
-   Run `runner.py --self-test` before commit (R7); regenerate scoreboard with a
    private --out dir (R5); update fork/inventory/work-items.json W4 item state.

## 8. Files touched (complete list)

-   `toolchain/check/handle_match.cpp` — implement H1-H5, H9-H14; keep H6-H8 stubs.
-   `toolchain/check/node_stack.h` — recategorize 6 match node kinds (§2).
-   `toolchain/sem_ir/inst_namer.cpp` — optional block labels (§4).
-   `toolchain/check/testdata/patterns/unused.carbon` — golden update (§6).
-   `toolchain/check/testdata/match/*` + `toolchain/lower/testdata/match/basic.carbon` — new.
-   `fork/conformance/programs/control_flow/match_switch.carbon`,
    `fork/conformance/programs/project/most_features_missing_match.carbon`,
    `fork/conformance/programs/control_flow/match_sum_type_payload.carbon`,
    plus new `match_guard_binding.carbon` — §7.
-   `fork/inventory/work-items.json`, `fork/decision-log.md` (scope-trade entry),
    `fork/conformance/out/scoreboard.json` (regenerated).

No changes to: toolchain/parse/*, toolchain/lower/* (source),
toolchain/sem_ir/* except optional inst_namer, any BUILD file.

## 9. Risk list

1.  **No local build; goldens cannot be autoupdated locally.** The
    unused.carbon edit and all new goldens must be produced by way of the CI
    file_test autoupdate path (or hand-written CHECK lines and reconciled on
    first CI run). This is the single most likely source of a red first CI run
    — plan for one golden-reconciliation commit; candidate rulebook rule.
2.  **Node-stack discipline bugs** (wrong Peek kind at arm boundaries,
    MatchDefault entry left/popped asymmetrically) manifest as CHECK failures in
    file_test, not diagnostics. Mitigation: the §6 testdata matrix deliberately
    exercises first-arm/later-arm/default-only/nested/sequential-match paths;
    both adversarial reviewers should re-derive the stack trace tables in §3.
3.  **Lookahead novelty**: H5's `NodeId(index+1)` peek has precedent in parse
    (tree.cpp:83) but is new in check handlers. It relies only on immutable
    postorder layout, not traversal order; NodeIdTraversal's deferred-definition
    reordering never applies inside a match (no deferred definitions there).
    Reviewer instruction: attack this assumption specifically.
4.  **Temporary/cleanup semantics** are only trivially correct because the slice
    is integers (no destroy fns, by-value repr). H3's early
    AddAndDiscardTemporaryCleanups and the absence of per-case temporary cleanup
    are NOT correct for class-typed scrutinees — the H3 integer gate is what
    makes this sound. Future slices must revisit before widening the gate.
5.  **Missing usefulness/redundancy diagnostics**: design
    (pattern_matching.md §"Refutability, overlap, usefulness") requires errors
    for never-matching cases (for example duplicate `case 0`); slice 1 accepts them
    (runtime first-match-wins is still correct). Deviation must be recorded as
    a follow-up work item, not silently.
6.  **`match (n)` with errored scrutinee** (ErrorInst type) hits the H3 TODO,
    adding a second diagnostic after the real one. Noisy but safe; golden for
    this case optional.
7.  **Upstream collision** (standing rule 5): upstream lands features weekly and
    match checking is an obvious target; before implementation starts, check
    upstream carbon-language/carbon for in-flight match-check PRs to avoid
    re-implementing a merge.
8.  **Conformance rewrite trade-off**: replacing the guard arm in two programs
    narrows what the PASS asserts. Mitigated by the new guard SKIP program and a
    decision-log entry; reviewer #2's "SKIP hides working behavior / PASS hides
    narrowed coverage" lens applies.
9.  **`Peek<Kind>` API assumption**: H9/H13 rely on NodeStack::Peek<NodeKind>
    (node_stack.h:315) returning the mapped id of the top entry and on
    PopAndDiscardSoloNodeIdIf (node_stack.h:178). Both exist today; if upstream
    merge churns node_stack.h, re-verify signatures before CI.
