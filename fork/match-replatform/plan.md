<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Match re-platform plan: `match` onto the pattern machinery (pre-W5-S2)

Status: PLAN (process step 6). Mandated by fork/viability-review-2026-07-20.md
§2 F-Q1/F-Q2 and §6 item 5 ("Re-platform match on the pattern machinery BEFORE
W5-S2 … prevents three downstream slices (bindings, guards, choice
destructuring) from stacking on a structure that must die"). Design authority:
docs/design/pattern_matching.md,
proposals/p002188-pattern-matching-syntax-and-semantics.md,
docs/design/sum_types.md, and the ratified decisions in fork/decision-log.md
(W4-S1, W5 SF-1..8, W5-S1 scope trades, V-2/V-3). Precedent format:
fork/w5-choice/plan.md. NO implementation in this document — planning only.

## 0. Scope and non-goals

### 0.1 Scope

Replace the internals of the `match` statement checker
(toolchain/check/handle_match.cpp) so that `case` patterns are checked into
real pattern SemIR through upstream's pattern machinery
(pattern.cpp/pattern_match.cpp/full_pattern_stack.h) instead of parse-tree
index sniffing and direct `==`-chain desugar — then grow bindings, payload
destructuring, guards, and choice exhaustiveness on that platform. Slices are
S2a..S2e; S2c is the slice that discharges W5-S2's payload destructuring
(`case .Ok(x)`), and it is forbidden from landing before S2a/S2b by this
plan's dependency chain.

### 0.2 Non-goals

-   **No decision-tree lowering.** The first-match-wins if/else-chain CFG
    (handle_match.cpp:20-36) is design-correct per pattern_matching.md and
    survives; only the _pattern side_ is re-platformed. Optimizing dispatch
    is post-0.1.
-   **No `Match` interface/Continuation machinery** (sum_types.md
    user-defined sum types) — same exclusion as W5 plan §0.3.
-   **No usefulness/redundancy diagnostics** (W-066 stays deferred, W4-S1
    trade).
-   **No `if let`/`let else`** (F-011) — but S2a's refutable-match entry
    point is designed so F-011 can consume it later (see §2.5).
-   **No changes to choice construction/layout** (W5-S1 machinery in
    handle_choice.cpp is consumed, not modified, except the S2c metadata
    side-table already promised there — decision-log follow-up (2)).
-   **Generic choices, prelude Result/Optional, std::variant interop** stay
    W5-S3/S4, unchanged by this plan.

### 0.3 Honesty about "byte-equivalent"

S2a cannot keep SemIR _dumps_ identical — routing patterns through the
pattern machinery necessarily adds pattern insts and pattern blocks to check
goldens. "Byte-equivalent-or-better observable behavior" means: identical
diagnostics (strings and, where prescribed below, locations), identical
runtime behavior of every conformance program, and — the strong arbiter —
**byte-identical LLVM output**: lower/testdata/match/basic.carbon's golden
diff after S2a must be empty or loc-comment-only. Two deliberate co-changes
are called out as sub-forks and never slipped in: the guard TODO string
(RF-3), and constant-expression-pattern admission (RF-4), which flips
fail_todo_non_int_literal_case.carbon and deletes its pinned diagnostic.
RF-4 lands as a separate second commit within S2a, sequenced after the
lower-golden byte-equivalence arbiter has been proven on the pre-RF-4
state.

## 1. Current state (claims re-derived from the tree at b81d473)

### 1.1 What upstream has TODAY for pattern matching

**Value-side entry point.** The runtime pattern-match engine is
`MatchContext` in toolchain/check/pattern_match.cpp:119-265, a worklist
traversal over pattern SemIR with four states —
`CallerState`/`CalleeState`/`LocalState`/`ThunkState`
(pattern_match.cpp:90-91). The value-side entry is **`LocalPatternMatch`**
(pattern_match.cpp:1183-1191, declared pattern_match.h:83-86). Its only
callers: `let` (handle_let_and_var.cpp:332), `var`
(handle_let_and_var.cpp:420), and the `for`-loop element
(handle_loop_statement.cpp:255). `CalleePatternMatch`/`CallerPatternMatch`
are the function-signature sides (pattern_match.h:23-81) — not relevant as
an entry point, but the same engine.

**How far it goes.** Irrefutable patterns only, straight-line IR, no
branching:

-   Bindings: full support — `AnyBindingPattern` pre/post work converts the
    scrutinee and fills the pre-created `AnyBinding` by way of `bind_name_map`
    (pattern_match.cpp:369-444); `ConversionKindFor` maps
    value/ref/var/symbolic kinds (:343-367).
-   Tuples: full destructuring by way of `TupleAccess` per element
    (pattern_match.cpp:715-790).
-   `var` patterns: storage + `InitializeExisting` (:643-707).
-   **Literal/expression patterns: NOT implemented.** `SemIR::ExprPattern`
    exists (typed_insts.h:698-708; explicitly `is_lowered = false` with a
    constant-eval TODO) and is _built_ by check (pattern.cpp:68-86 wraps any
    expression in pattern position), but the engine TODO's it:
    `DoPreWork(… ExprPattern …)` is
    `context_.TODO(entry.pattern_id, "expression pattern")`
    (pattern_match.cpp:559-564). Even `let 5 = x;` is a TODO upstream.
-   **Alternative patterns: no SemIR kind, no parse form, no engine case.**
    Upstream's own roadmap comment confirms intent to build them _in this
    engine_: "TODO: Instead, form a `.Some(pattern_id)` pattern and
    pattern-match against that" (handle_loop_statement.cpp:234-235).
-   **Refutability/exhaustiveness: nothing.** The engine emits into the
    current block only; `LocalState` FATALs on param patterns
    (pattern_match.cpp:545-547).
-   Guards: **parse-only.** Parse fully parses `case P if (E) => {…}`
    (parse/handle_match.cpp:151-219; typed_nodes.h MatchCaseGuard :961-969,
    MatchCase with `AnyPatternId pattern` + optional guard :971-979); the
    fork's check handlers TODO all three guard nodes
    (handle_match.cpp:259-272).

**Pattern check-side scaffolding**: `FullPatternStack` with kinds
NameBindingDecl/ClassScopeVarDecl/ImplicitParamList/ExplicitParamList/NotInEitherParamList
(full_pattern_stack.h:41-63); the expr-region protocol in pattern.cpp:20-92
(`BeginExprRegionForPattern`, `EndExprRegionForPattern` which converts a
leftover _expression_ on the node stack into an `ExprPattern` inst,
pattern.cpp:68-86); binding-pattern checking in
handle_binding_pattern.cpp:295-562, which reads the innermost
`decl_introducer_state_stack` entry (:324-325) and switches on
`full_pattern_stack().CurrentKind()` (:416-560) — `NotInEitherParamList` is
`CARBON_FATAL("Unreachable")` (:558-559). The driving sequence for a
statement-context pattern is proven by the `for` loop: an implicit
introducer push (`decl_introducer_state_stack().Push<Lex::TokenKind::Let>()`,
handle_loop_statement.cpp:136) + `pattern_block_stack().Push()` +
`full_pattern_stack().PushNameBindingDecl()`

-   `BeginExprRegionForPattern` (handle_loop_statement.cpp:136-139), pattern
    popped by way of `EndExprRegionForPattern` + `PopPattern` (:146,173),
    `StartPatternInitializer`/`EndPatternInitializer` around the scrutinee
    (:151,250), `LocalPatternMatch` + `PopFullPattern` (:255-256). The finished
    pattern block is attached to a `NameBindingDecl` inst
    (typed_insts.h:1321-1329; emitted at handle_let_and_var.cpp:341-344).

**`match_first` is NOT runtime matching.** It is an impl-prioritization
_declaration_ construct: `HandleParseNode(… MatchFirstDefinitionStartId …)`
requires namespace/class/function scope and creates a `SemIR::MatchFirstDecl`
plus a `match_first_context()` on Context
(handle_match_first.cpp:22-48; context.h:238-239,580). There is no
runtime-value connection at all. **Conclusion: upstream has no refutable,
value-side match construct to desugar onto; the only re-platform target is
the pattern-inst representation + MatchContext engine itself.**

**Design authority for the semantics we must implement:** p002188 defines
alternative patterns (match iff active alternative matches and its arguments
match the tuple pattern; parens present iff the alternative has a parameter
list — p002188:442-473), guards (on **both `case` and `default` clauses** —
p002188:552-553, pattern_matching.md:814-815 — with pattern bindings in
scope in the guard, :538-554; the fork's parser attaches guard nodes to
`case` only, a gap recorded as a scope trade in §3.4), and
refutability/exhaustiveness (:555-604;
non-exhaustive match without `default` is an error, :633-641).

### 1.2 What the fork's match is today

toolchain/check/handle_match.cpp checks match as an if/else chain (:20-36).
Inventory of what must survive vs die:

-   **Dies (F-Q1):** the parse-tree index sniff in `MatchCaseIntroducer` —
    `node_id.index + 1`, `+ 2`, `+ 3` peeks classifying the case pattern
    before its nodes are traversed (:214-217, :223-224).
-   **Dies with S2c (F-Q1 residue):** the node-stack layout hack in
    handle_name.cpp:191-220 — the `DesignatorExpr` handler pops the
    `MatchCaseIntroducer` entry off the node stack to find the scrutinee and
    resolve `.Err` in its choice scope (:203-211).
-   **Dies (F-Q2):** no pattern SemIR — cases desugar directly to EqWith
    `Call`s and branches in `MatchCase` (:274-362).
-   **Survives:** the scrutinee-once conversion (:145) and the
    type-property cleanup argument (:156-161, W5 R-4 discipline); the choice
    gate `GetChoiceDiscriminantType` on the `Class::is_choice` entity flag
    (:55-85); the cross-file discriminant excavation
    `GetAlternativeDiscriminant` (:98-132) until S2c's side-table; the EqWith
    operand-order mandate ("_expression_ `==` _scrutinee_", :281-285); the
    block/branch/convergence structure (:349-361, :435-438); the
    mandatory-`default` diagnostic (:423-429).

Contract TODO strings currently emitted (each R10 SKIP-quoted or
golden-pinned): `match on unsupported scrutinee type` (:179), ``match `case`
pattern other than an integer literal, or a case guard`` (:230-232,
:245-247, :250-253), `match case pattern destructuring a choice payload`
(:236-237, :299-300), `qualified alternative pattern in match case`
(:242-243), `match case pattern on unsupported choice alternative shape`
(:316-318), guard handler TODOs (:261,266,271), ``match statement without
`default` arm`` (:428).

Goldens/conformance floor: 15 check/testdata/match files (~2,000 lines),
lower/testdata/match/basic.carbon, 14 parse/testdata/match files; scoreboard
**73 PASS / 34 SKIP / 0 FAIL (107 programs, 40/56 bullets)** — the
regression floor for every slice.

### 1.3 Upstream drift status

The last upstream sync merged 25 commits and that batch is _dense with
pattern work_: 8be274c #7479 replaced the `:!` binding syntax with phase
keywords and added `FormBindingPattern`/`:?` form bindings — rewriting
handle_binding_pattern.cpp and parse pattern files; 11901b1 #7478 +
bf106c3 #7480 landed `match_first` parsing; b1c7e58/4261bb2 reworked
`.Self` handling inside binding types. Upstream is actively building on
exactly the files this plan touches. Risk R-4 governs.

## 2. Design

### 2.1 The re-platform shape

**Not a desugar to `match_first`** — §1.1 shows match_first is an
impl-lookup declaration with no runtime semantics. The fork's match
**drives the pattern machinery directly**, in two layers:

1.  **Pattern construction** — `case` patterns become real pattern SemIR by
    letting the parse tree's pattern nodes reach their ordinary check
    handlers **inside a per-arm full-pattern context**, mirroring the
    `for`-loop driving sequence (handle_loop_statement.cpp:136-139,146):
    `MatchCaseIntroducer` pushes scope + implicit introducer state (R-5) +
    full-pattern + pattern block + expr region; `MatchCase` pops the
    checked pattern root. The index sniff
    is deleted; unsupported shapes are diagnosed by inspecting the _checked
    pattern inst_, not raw node indices.
2.  **Refutable matching** — a new **`MatchCaseState`** added to
    `MatchContext` (pattern_match.cpp), with a public entry point
    `MatchCasePatternMatch(context, pattern_id, scrutinee_id) -> InstId
    /*bool cond*/` beside `LocalPatternMatch` (pattern_match.h). It runs
    the refutable prefix of the pattern and returns a boolean condition
    inst; `handle_match.cpp` keeps ownership of the CFG (BranchIf/else/
    convergence, unchanged). Matching is **two-pass per arm**:
    -   _Test pass_ (in the arm's test block): `ExprPattern` → splice its
        region (`InsertHere` exists, pattern_match.cpp:298-337), classify,
        and emit the compare; alternative-pattern roots → emit
        `ClassElementAccess .discriminant` + compare. Result: cond. The
        test pass **must prune at binding-pattern roots**: descending into
        bindings would consume `bind_name_map` entries by way of
        `std::exchange` (pattern_match.cpp:430-433) that the bind pass
        still needs, tripping the used-twice CHECK (:437).
    -   _Bind pass_ (in the arm's body block, only when the pattern
        contains bindings — S2b+): irrefutable residue initialized from
        payload extraction by way of the existing `LocalState` machinery.
        The invariant this preserves is not "single-block per invocation" —
        it is that **the engine never emits dispatch CFG**:
        BranchIf/else/convergence stay in handle_match.cpp, while
        `InsertHere` may legitimately emit branches when splicing a
        multi-block expr region (pattern_match.cpp:317-336). S2a regions
        are single-block; S2d guard regions will be multi-block, and the
        splice mechanism already handles that. This division of labor is
        what makes the extension small and upstream-mergeable.

### 2.2 What replaces the EqWith chain

**Nothing replaces it; it is relocated and kept as the comparison
primitive.** pattern_matching.md and p2188 _mandate_ `==` dispatch for
expression patterns with the operand order _expression_ `==` _scrutinee_
(implemented and comment-cited at handle_match.cpp:281-285, :329-336,
:340-346). The EqWith `Call` emission moves into `MatchCaseState`'s
`ExprPattern` case; the choice-discriminant compare remains an EqWith on
the discriminant integer type exactly as today. The _chain structure_
(test → BranchIf → else-block per arm) also survives — it is the CFG
realization of first-match-wins, and W4/W5 goldens prove it lowers.
Upstream's comparison approach for patterns does not exist yet (§1.1
ExprPattern TODO); if upstream later lands its own expression-pattern
semantics, the divergence-risk register entry (R-6) triggers
reconciliation.

### 2.3 SemIR representation

Per arm, the checked pattern block is attached to a **`NameBindingDecl`**
inst (typed_insts.h:1321-1329) emitted in the arm's test block — the same
home `let`/`var` give their patterns (handle_let_and_var.cpp:341-344).
This gives match a real, formatter-visible pattern representation (F-Q2
discharged) with **zero new SemIR inst kinds**; exhaustiveness (S2e) reads
covered alternatives from these blocks or from per-arm state. A dedicated
`MatchCaseDecl` inst is sub-fork RF-2 — new inst kinds are the W5 §6
plan-revision trigger, so the recommendation is NameBindingDecl reuse.
Entity-level additions: only S2c's per-alternative side-table on
`SemIR::Class` (already promised: decision-log follow-up (2), W5 plan
§3.2.2), with its import_ref copy.

### 2.4 Scope and stack discipline

The arm scope must cover pattern bindings + guard + body (p2188:543-544:
bindings in scope in the guard). Today `MatchHandlerStart` pushes the arm
scope _after_ the pattern is handled (handle_match.cpp:379-384) — too late
once bindings register names at pattern-check time
(handle_binding_pattern.cpp:357-365). Design: `MatchCaseIntroducer` pushes
the arm scope (and pattern context); `MatchHandlerStart` detects the
case-arm context and does **not** double-push; `MatchHandler` pops both
levels symmetrically. `MatchDefault` arms keep today's push/pop. The
node-stack scrutinee protocol (`PeekScrutinee`, handle_match.cpp:40-45) is
retained; the scrutinee's _type_ additionally becomes available to pattern
checking by way of the case-arm context (needed by S2c's alternative resolution)
— recommended as a small match-scrutinee stack on `Context`, mirroring
`match_first_context()` (context.h:238-239) in shape. The case-arm context
also carries the **`MatchCaseIntroducer` node id**: preserved diagnostics
are pinned to the case token (§0.3, §3.1), and handle_binding_pattern has
no other cheap access to that token, so the combined TODO for binding
roots keeps its location only if the id is plumbed through here. The
context carries a third field, **`designator_root_id`**, recording the
inst that the case pattern's root `DesignatorExpr` resolved to (written
in handle_name.cpp, read by the engine's classification): checked-inst
classification alone cannot distinguish a leading-dot alternative
spelling from a wrapped or qualified spelling resolving to the same
constant, so the provenance must be recorded at resolution time.

### 2.5 Forward compatibility

`MatchCasePatternMatch` returning a cond inst + a bind pass is exactly the
shape F-011's `if (let P = e)` needs; S2a's entry point is designed with
that consumer in mind but F-011 work is out of scope.

## 3. Slices

Dependency chain S2a → S2b → S2c → S2d → S2e; each lands independently
through the full R11 loop and the R21 gate; scoreboard floor 73 PASS /
0 FAIL at every landing (PASS may only grow).

| #   | Name                                                           | Size | What flips                                                     |
| --- | -------------------------------------------------------------- | ---- | -------------------------------------------------------------- |
| S2a | Re-platform core: pattern SemIR + refutable engine              | M/L  | only the two §0.3 co-changes flip (RF-3 guard string; RF-4 flips fail_todo_non_int_literal_case); otherwise byte-equivalent; goldens restructure |
| S2b | Bindings in case arms (`case a: i32`) + arm-scope discipline    | M    | fail_todo_binding_pattern → success golden                     |
| S2c | Alternative patterns with payload destructuring (the W5-S2 slice) | L  | fail_todo_choice_payload_pattern flips; roundtrip conformance un-SKIPs |
| S2d | Guards (`case P if (E)`)                                        | M    | fail_todo_guard flips; 2 conformance programs un-SKIP (75 PASS) |
| S2e | Choice exhaustiveness (SF-7): full coverage ⇒ no `default`      | S/M  | fail_todo_no_default splits; sum_types.md example compiles     |

### 3.1 S2a — minimal re-platform (byte-equivalent-or-better)

In-slice:

-   `MatchCaseIntroducer`: delete the index peeks; push arm scope + an
    **implicit introducer state** (R-5's resolution, the for-loop precedent
    at handle_loop_statement.cpp:136 — required in S2a, not S2b: binding
    nodes reach `HandleAnyBindingPattern`, whose introducer read at
    :324-325 precedes the `CurrentKind()` switch, and by statement position
    the stack is otherwise empty) + `full_pattern_stack` frame
    (recommended: new `Kind::MatchCaseArm`, so handle_binding_pattern can
    gate case-arm bindings to the S2b TODO explicitly — RF-1 companion) +
    `pattern_block_stack` + `BeginExprRegionForPattern`, mirroring
    handle_loop_statement.cpp:136-139.
-   `MatchCase`: `EndExprRegionForPattern`, `PopPattern`; classify the
    root: integer-literal expr pattern → EqWith test; payload-free
    alternative constant → discriminant test (reusing
    `GetChoiceDiscriminantType`/`GetAlternativeDiscriminant` unchanged);
    payload alternative's constructor (FunctionType) → payload TODO;
    binding-pattern root → the W4 combined TODO (S2b's flip is S2b's);
    other shapes → existing strings, **emitted against the introducer's
    node id** so diagnostic locations do not move (§0.3) — the id is
    carried in the case-arm context (§2.4). The test emission
    moves into `MatchCaseState` in pattern_match.cpp (RF-1), entry declared
    in pattern_match.h.
-   Emit the per-arm `NameBindingDecl` (§2.3), amending its doc comment in
    the same commit (typed_insts.h:1319-1320 currently says a declaration
    "introduced with `let` or `var`"); pop the pattern context
    symmetrically on every **success** path (`VerifyOnFinish` CHECKs at
    full_pattern_stack.h:197-201 make imbalance a deterministic crash on
    passing programs). Symmetric popping after a TODO early-out is _not_
    required: a TODO aborts checking before `FinishRun` ever reaches
    `VerifyOnFinish` (check_unit.cpp:100-104, :628), so it is unverifiable
    dead work — see R-2.
-   Guard nodes now _reached_: keep TODO, string consolidates — RF-3.
-   The handle_name.cpp:191-220 designator special case is _kept_ in S2a
    and deleted in S2c.
-   Stretch (RF-4): admit `case -1` and other constant integer expr
    patterns — strictly better; default is to take it since the
    classification is by checked-inst, making the literal-only restriction
    _more_ work than the general constant. This is the **second deliberate
    co-change** (§0.3): it flips fail_todo_non_int_literal_case.carbon and
    deletes its pinned diagnostic, so it lands as a **separate commit
    within S2a**, sequenced after the lower-golden byte-equivalence arbiter
    has been proven on the pre-RF-4 state.

Exit criteria: `bazel test //toolchain/...` green after R26 fixpoint;
conformance 73 PASS / 34 SKIP / 0 FAIL with identical EXPECT outputs; every
§1.2 TODO string byte-identical except the two §0.3 deliberate co-changes —
the RF-3 guard string and RF-4's flip of
fail_todo_non_int_literal_case.carbon (each with a decision-log entry +
SKIP-evidence refresh in the same slice);
**lower/testdata/match/basic.carbon golden diff empty or loc-only** (the
byte-equivalence arbiter), proven on the pre-RF-4 commit before the RF-4
commit lands; fail_todo goldens diff loc-only where strings are preserved.

Golden churn: all 15 check/testdata/match files (pattern blocks +
`expr_pattern` insts appear), zero parse-golden churn, lower churn asserted
~zero.

### 3.2 S2b — bindings in case arms

`case a: i32 => {…}` (bare `name: type`, SF-5) checks to a
`ValueBindingPattern` under `Kind::MatchCaseArm`; test pass contributes no
condition (irrefutable); bind pass runs in the arm's body block by way of
`LocalState`. `default` stays required. Hard parts, budgeted: (a) the
`decl_introducer_state_stack` coupling (handle_binding_pattern.cpp:324-325)
is discharged in S2a by R-5's implicit introducer push; S2b's job is to
verify modifier behavior under that introducer kind with failing testdata;
(b) name-scope
discipline: binding visible in guard+body only, with failing testdata for
sibling-arm and post-match leakage; (c) `var`-mode case bindings and `ref`
stay TODO (new precise string, recorded).

### 3.3 S2c — alternative patterns with payload destructuring (the W5-S2 slice)

Everything W5 plan §3 planned, now on the platform: new parse
alternative-pattern form (`.`+name(+paren _pattern_ list) in pattern
position; new node kinds; parse goldens); check-side alternative-pattern
handler resolving the name against the case-arm scrutinee type (deleting
the handle_name.cpp:191-220 hack); the per-alternative side-table on
`SemIR::Class` replacing `GetAlternativeDiscriminant`'s constant excavation
with import support; `MatchCaseState` discriminant test + payload
extraction feeding subpattern bindings in the bind pass; SF-3 zero-payload
`.Alt()` patterns; parens-iff-parameter-list per p2188:453-456. W5-S1
preserved gates keep their strings. Flips fail_todo_choice_payload_pattern;
un-SKIPs conformance roundtrip; executes the W5 §3.3 split of
match_sum_type_payload. The XL-risk slice of the program (W5 R-1/R-2 carry
over), but S2a/S2b will have already proven the two deep unknowns (case-arm
pattern context, refutable engine).

### 3.4 S2d — guards

Guard expression checked in the arm scope (bindings visible,
p2188:543-544), converted to bool, emitted in the arm's body-entry block:
test → BranchIf → bind block → guard test → BranchIf(body, else), both else
edges converging on the next arm's test block — a handle_match.cpp CFG
change, engine untouched. fail_todo_guard flips; match_guard_binding.carbon
and project/most_features_missing_match.carbon un-SKIP (PASS floor rises to
75); differential pair for guards added.

Two recorded notes. **Scope trade (recorded, veto-able per §6):** S2d
implements guards on `case` clauses only. Design authority extends guards
to `default` clauses too (p002188:552-553; pattern_matching.md:814-815),
but the fork's parser attaches guard nodes only to `case`
(parse/handle_match.cpp:151-219 has no `default`-guard production) — the
gap is parse + check, and `default`-clause guards are recorded as a work
item with a decision-log entry at S2d landing. **Sizing: M, not S/M** —
the guard expression's nodes precede `MatchCase` in postorder, so
capturing the guard requires its own expr-region plumbing threaded through
the case-arm context.

### 3.5 S2e — choice exhaustiveness (SF-7)

In `MatchStatement`: covered-alternative bitset from the arms' alternative
patterns (size from S2c's side-table); full coverage ⇒ no `default`;
missing-alternative error naming the uncovered set; integer matches keep
the `default` requirement verbatim (SF-7: "W4's rule stays for integer
matches"). fail_todo_no_default splits into choice/integer shapes; new
fail_choice_nonexhaustive goldens.

## 4. Preserved contracts

1.  **W5-S1 recorded scope trades** keep their exact diagnostics through
    every slice until the slice that discharges them (details in §1.2 and
    decision-log W5-S1; the defense-in-depth pattern string stays attached
    to the _pattern_, never the scrutinee).
2.  **F-007k discriminant storage contract**: the pattern path keeps
    reading the discriminant as field 0 of the
    `StructType{.discriminant, .payload}` repr by way of `ClassElementAccess`,
    gated on `Class::is_choice` + the `NameId::ChoiceDiscriminant` repr
    check — entity truth plus repr contract, never syntactic sniffing.
3.  **Mandatory `default` until exhaustiveness**: survives S2a-S2d verbatim
    and is narrowed (not removed) at S2e per SF-7.
4.  **EqWith operand order** — _expression_ `==` _scrutinee_ — preserved
    inside the engine; reviewers re-verify operand order in the moved code.
5.  **Scrutinee evaluated once + type-property cleanup argument**: H3
    unchanged; any per-arm conversions the engine adds must not create
    arm-scoped temporaries without matching cleanup discipline (risk R-7).

## 5. Risk register (numbered, falsifiable)

-   **R-1. Generated-code loc discipline** (the W5-S1 FunctionDecl-loc
    lesson). Engine-emitted insts must carry real locs as the existing
    DoPostWork does (pattern_match.cpp:406,423); the relocated EqWith calls
    keep the case node loc. _Falsifier:_ a lowering CHECK-crash or a
    diagnostic pointing at the wrong token — S2a testdata includes a
    deliberately-failing conversion inside an arm to pin diagnostic locs.
-   **R-2. Scope-stack imbalance.** MatchCaseIntroducer now pushes what
    MatchHandlerStart used to; every success path must leave the
    scope/full-pattern/pattern-block/region stacks poppable. TODO
    early-outs are exempt: a TODO aborts checking before `FinishRun`
    (check_unit.cpp:100-104), so `VerifyOnFinish` (check_unit.cpp:628)
    never runs on fail_todo inputs and cannot verify them (§3.1).
    _Falsifier:_ `VerifyOnFinish` CHECK failures
    (full_pattern_stack.h:197-201) on **passing** programs — the entire
    S2a testdata suite plus the nested-match golden; adversary #1's brief:
    a match inside a match inside a lambda.
-   **R-3. Autoupdate churn scale.** All 15 match check goldens churn
    structurally in S2a (~2,000 lines); two-pass fixpoint mandatory (R26).
    _Falsifier:_ a pass-2 diff with structural (non-loc) changes = real
    nondeterminism — stop and diagnose, never loop. Budget: 2 autoupdate
    rounds per slice, one reconciliation commit each (R19).
-   **R-4. Upstream drift in exactly these files.** §1.3 evidence: the last
    25-commit batch rewrote binding-pattern surface (#7479) and is building
    match_first (#7478/#7480). `MatchCaseState` is _not_ purely additive:
    widening the State variant forces in-body edits at
    pattern_match.cpp:90-91 and at every state-discriminating site —
    `AnyParamPattern` (:477-548), `ExprPattern` (:559-564),
    `DoVarPreWorkImpl` (:643-707), `SpliceInst` (:812-853) — plus ~8
    `holds_alternative` sites each needing a per-site decision (:272,
    :374, :396-397, :597, :610, :736-737, :860, :877, :893). Mitigations:
    that enumerated set is the **accepted collision surface** — each site
    gains one alternative mechanically, with no restructuring, and new
    code is otherwise appended; pre-slice upstream-activity check
    (standing rule 5); weekly upstream-merge Routine keeps installments
    small; RF-1(b) is the recorded fallback if this surface turns hostile.
    _Falsifier:_ an upstream merge conflicting in >2 of this plan's files
    in one week — re-plan trigger.
-   **R-5. `decl_introducer_state_stack` coupling** (S2a). Binding checks
    read the innermost introducer state
    (handle_binding_pattern.cpp:324-325) _before_ the `CurrentKind()`
    switch, and binding nodes reach `HandleAnyBindingPattern` as soon as
    S2a routes pattern nodes to their ordinary handlers — exposure starts
    at **S2a**, not S2b. The failure mode is not a semantics leak: in
    statement position the enclosing `fn` introducer has already been
    popped (handle_function.cpp:541 pops before body statements), so the
    stack is _empty_ and `innermost()` is `back()` on an empty vector —
    crash/UB. Upstream's own answer is the for-loop's implicit introducer
    push (handle_loop_statement.cpp:136 pushes `Lex::TokenKind::Let`).
    Options: (a) an implicit introducer push at MatchCaseIntroducer — the
    for-loop precedent, **recommended and scheduled in S2a** (§3.1, §7);
    (b) a dedicated introducer state kind; (c) branch on
    `Kind::MatchCaseArm` before the introducer read. _Falsifier:_ an S2a
    binding-root testdata program crashing instead of emitting the
    combined TODO; a case binding accepting a modifier only valid under
    the pushed introducer kind (adversary #1 writes it).
-   **R-6. ExprPattern semantics divergence.** Upstream TODO's expression
    patterns engine-wide; our MatchCaseState implements them for match
    only. If upstream lands its own, ours reconciles (V-3). Entered in the
    divergence-risk register at S2a landing. _Falsifier:_ an upstream
    commit implementing `DoPreWork(ExprPattern)` — reconciliation becomes a
    scheduled slice.
-   **R-7. Per-arm temporary cleanup.** The engine's binding post-work
    calls `Convert` (pattern_match.cpp:406-408), which can materialize
    temporaries; in a case arm these are per-arm, inside branched CFG —
    W4's "no cleanups" argument must be re-derived per slice as a type
    property. _Falsifier:_ a destroy-op count probe once destroy synthesis
    lands; until then both reviewers re-derive the argument.
-   **R-8. Node-stack layout contracts.** `PeekScrutinee`
    (handle_match.cpp:40-45) and, until S2c, the handle_name.cpp:203-211
    peek depend on exact stack layout across the new pushes. _Falsifier:_
    the existing nested.carbon golden plus a new designator-in-nested-match
    testdata program.
-   **R-9. Conformance floor + Goodhart guard.** match_switch,
    match_position, match_no_fallthrough, choice_payload_construct,
    choice_discriminant_diff, match_switch_diff stay PASS at every slice;
    no SKIP on a passing program (R16b); goldens only by way of runner autoupdate
    (R16a/R15); S2c's lower golden must actually discriminate payload GEPs.

## 6. Open sub-forks (V-2 veto digest)

Real-entropy decisions (recommendation ≠ decision; auto-adopted per V-2
with digest entries, veto-able):

-   **RF-1 (blocks S2a): where the refutable engine lives.** (a) New
    `MatchCaseState` inside pattern_match.cpp's MatchContext. The
    originally claimed benefit — "S2b/S2c reuse binding/tuple traversal
    for free" — is false in-scope: no slice's test pass recurses past
    binding-pattern roots (§2.1's pruning obligation), and bind-pass reuse
    comes by way of the already-public `LocalPatternMatch` under either
    option. (a) stands instead on **upstream alignment** (upstream's own
    roadmap points into this engine — the `.Some(pattern_id)` comment,
    handle_loop_statement.cpp:234-235) and on **F-011's future entry
    point** (§2.5); its cost is R-4's enumerated variant-widening
    collision surface. (b) A fork-local check/match_case_pattern.cpp — in
    truth root-classification plus calls to the existing public entries,
    cheaper than this plan first claimed, though still a second dispatch
    point to keep in sync (an R17 smell). **Adopted: (a)** on this
    re-argued basis; (b) is the recorded fallback if upstream churn in
    pattern_match.cpp turns hostile (R-4's trigger).
    Companion: new `FullPatternStack::Kind::MatchCaseArm` vs reusing
    `NameBindingDecl` kind — **adopted: the new enum value** (explicit
    gating, cheap).
-   **RF-2 (blocks S2a): SemIR home for case patterns.** (a) Reuse
    `NameBindingDecl` per arm — zero new inst kinds. (b) Dedicated
    `MatchCaseDecl` inst — self-describing but fires the new-inst-kind cost
    across formatter/inst_namer/eval/import. **Adopted: (a)**; revisit only
    if S2e's exhaustiveness walk proves awkward.
-   **RF-3 (blocks S2a): guard TODO string co-change.** (a) One clean
    `semantics TODO: match case guard` at MatchCaseGuardIntroducer, with
    same-slice decision-log entry + SKIP-evidence refresh. (b) Re-emit the
    W4 string at the introducer — requires lookahead, an R17 smell.
    **Adopted: (a).**
-   **RF-4 (S2a stretch): admit constant integer expression patterns**
    (`case -1`, `case 2+3`). Strictly-better; discharges the recorded
    viability-review gap; needs a duplicate-arm story recorded against
    W-066. **Adopted: take it in S2a** with new testdata — as the second
    §0.3 deliberate co-change: it flips
    fail_todo_non_int_literal_case.carbon (deleting its pinned
    diagnostic) and lands as a separate commit sequenced after the
    lower-golden arbiter is proven on the pre-RF-4 state (§3.1).
-   **RF-5 (blocks S2c): alternative-pattern parse-node shape** — dedicated
    `AlternativePattern`/`AlternativePatternStart` kinds vs generalizing
    the designator-expr route. **Adopted: dedicated kinds** (W5 plan
    §3.2.1's shape), detailed at S2c planning.

Mundane auto-adopts (rationale inline, veto-able): EqWith remains the
compare primitive (mandated by pattern_matching.md/p2188); first-match
if/else CFG retained; `default` required until S2e — noting SF-7 itself
said exhaustiveness "lands in slice 2", so deferring it to S2e is a
plan-made resequencing under the viability mandate, recorded here as its
own veto-able digest entry rather than as SF-7-ratified; S2d implements
`case`-clause guards only, with `default`-clause guards deferred as a
recorded work item (the parse gap is named in §3.4); leading-dot-only
patterns (SF-4); bare `name: type` binding spelling (SF-5); TODO strings
preserved elsewhere verbatim (R10); S2c side-table replaces
`GetAlternativeDiscriminant` (recorded follow-up); diagnostic locations
for preserved strings pinned to the introducer node.

## 7. Files touched (budgeted generously per the W5 §2.4 drift lesson)

S2a: toolchain/check/handle_match.cpp (major rewrite);
toolchain/check/pattern_match.{h,cpp} (MatchCaseState + entry);
toolchain/check/full_pattern_stack.h (new Kind);
toolchain/check/handle_binding_pattern.cpp (MatchCaseArm gating);
toolchain/check/handle_let_and_var.cpp (the exhaustive `CurrentKind()`
switch at ~:125-148 has no default and must gain a `Kind::MatchCaseArm`
case); toolchain/check/decl_introducer_state.h surfaces as needed for
R-5's implicit introducer push; toolchain/sem_ir/typed_insts.h
(NameBindingDecl doc comment, :1319-1320); toolchain/check/context.h
(case-arm scrutinee + introducer-node-id context, §2.4);
toolchain/check/node_stack.h; toolchain/check/handle_name.cpp
(guard TODOs + designator-provenance recording); possibly
toolchain/check/pattern.{h,cpp},
toolchain/check/scope_stack.{h,cpp}, toolchain/sem_ir/inst_namer.cpp
(labels). Drift buffer (+50%, the W5 lesson): convert.cpp,
control_flow.{h,cpp}, sem_ir/formatter if NameBindingDecl printing needs a
tweak, diagnostics kinds. Testdata: all 15 check/testdata/match goldens,
lower/testdata/match/basic (assert-no-change), new expr-pattern testdata
(RF-4).

S2b adds: unused.cpp surfaces; new binding testdata (R-5's introducer work
lands in S2a). S2c adds: parse/handle_pattern.cpp, parse/typed_nodes.h,
parse node kinds + goldens; sem_ir/class.h + import_ref.cpp (side-table);
handle_choice.cpp (metadata population); lower golden. S2d:
handle_match.cpp CFG + guard handlers + guard expr-region capture plumbing
through the case-arm context (§3.4). S2e: handle_match.cpp completion +
diagnostics. Every slice ends with runner autoupdate to fixpoint (R26),
`prek run --all-files` (R25), scoreboard publication (R9), and
decision-log/work-items updates at landing.
