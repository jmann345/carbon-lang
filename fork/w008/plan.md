<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-008 plan: match residue — the remaining case-pattern kinds

Status: PLAN. Drafted 2026-08-18. Size M — two implementation slices
(W8a, W8b) plus a disposition slice (W8c). Baseline: db51b12
(post-PR #31; conformance **96 PASS / 0 FAIL / 28 SKIP over 124**).
Authoritative record: fork/inventory/work-items.json W-008. NO
implementation in this document. All verification rides self-hosted
runner CI (autoupdate to fixpoint per R26; conformance per R9). W-066
(usefulness diagnostics) is blocked_by W-008 — §3.4 states exactly which
slice discharges that blocker.

Scope sentence: after W4 slice 1, S2b/S2c/S2d/S2e, W5-S3a/b/c, W-067,
and W-068, the match statement handles integer and choice scrutinees
with constant-integer expression cases, bare `name: type` bindings,
alternative patterns with all-binding payloads, guards (case and
`default`), and choice exhaustiveness. W-008's residue is every
case-pattern KIND still behind a semantics-TODO. This plan inventories
that residue against the tree (not the ledger's stale line numbers),
classifies each item, and slices the implementable subset.

## 0. Residue inventory (gating; every claim re-verified at db51b12)

Live match-arm TODO strings and their sites, enumerated by grep over
toolchain/check (handle_match.cpp, handle_binding_pattern.cpp,
handle_let_and_var.cpp, pattern_match.cpp):

| # | Residue item | Gate site(s) | Golden pin | Classification |
|---|---|---|---|---|
| R1 | Tuple patterns in case position (`case (1, 2)`, `case (a: i32, b: i32)`, mixed) — and tuple SCRUTINEES, which they require | handle_match.cpp:609-613 (non-binding-root fallback, string ``match `case` pattern other than an integer literal, or a case guard``); scrutinee gate handle_match.cpp:185-187 (`match on unsupported scrutinee type`) | check/testdata/match/fail_todo_tuple_pattern.carbon (subfile fail_todo_tuple_case) | Straightforward extension — S2b/S2c shapes + the engine's existing TuplePattern walk. **W8a** |
| R2 | Non-binding payload subpatterns in alternative patterns (`case .Some(42)`, `case .Pair(1, b: i32)`) | handle_match.cpp:405-413 (string ``non-binding subpattern in match `case` alternative pattern``) | check/testdata/match/fail_choice_alternative_pattern.carbon (subfiles fail_todo_expr_subpattern, fail_nested_designator_subpattern) | Straightforward extension of S2c + the W4 expression-pattern compare, with one design nuance (§1.3) and the coverage subtlety (§4 R-4). **W8a** |
| R3 | `var`/`ref` case bindings (`case var a: i32`, `case ref a: i32`, `case var (a: i32, b: i32)`) | handle_binding_pattern.cpp:517-520 (string `` `var` or `ref` binding in match `case` pattern ``); handle_let_and_var.cpp:146-155 (binding-free `case var 5`, combined string) | check/testdata/match/fail_todo_var_binding.carbon, fail_todo_ref_binding.carbon | Straightforward extension — S2b binding path + upstream's own VarPattern/LocalState machinery. **W8b** |
| R4 | Compile-time case bindings (`case template n: i32`) | handle_binding_pattern.cpp:647-653 (combined string, fired before the upstream local-generic-`let` gate could misfire) | fail_todo_tuple_pattern.carbon (subfile fail_todo_compile_time_binding) | **Design-open** (§1.4) — keep gated; W8c narrows the string and records. |
| R5 | Form bindings in case position | handle_binding_pattern.cpp:521-526 | (no dedicated pin; combined string) | Out — form bindings are upstream-TODO in ALL local contexts (`support local form bindings`, :532). Not fork residue. Record in W8c. |
| R6 | Struct patterns in case position | handle_pattern_list.cpp:38-41, :137-144 (`struct pattern start` / `struct pattern` TODOs) | (upstream; no match-specific golden) | Out — struct patterns are unimplemented upstream in EVERY context (let/var/param too). Designed (pattern_matching.md:413-468) but not match-specific residue; taking them on means building the whole struct-pattern check layer. Record in W8c; candidate future work item. |
| R7 | Non-integer, non-choice scrutinees (`bool`, adapter classes, `Core.Char`, class types) | handle_match.cpp:185-187 | fail_todo_non_int_scrutinee.carbon, fail_todo_adapter_scrutinee.carbon | Stays gated except the tuple widening R1 forces (§2.2). `bool` is design-reachable (treated "like a choice type", pattern_matching.md:591) but is its own small item — record in W8c, do not smuggle into W8a. |
| R8 | Integer-scrutinee `match` without `default` | handle_match.cpp:913-924 (``match statement without `default` arm``) | fail_todo_no_default.carbon (both subfiles, incl. the recorded conservative fail_irrefutable_binding_arm gate), fail_guarded_default.carbon:28 | Stays — the S2e-recorded conservative gate. Lifting the irrefutable-arm case is W-066-adjacent polish, not pattern-kind residue. Record in W8c. |
| R9 | Non-constant case expressions (`case y` for runtime `y`) | pattern_match.cpp:858-866 (`match case expression pattern that is not a constant integer`) | fail_todo_non_constant_case.carbon (both subfiles), operators/fail_question.carbon:175 | Stays — RF-4's recorded constant-only admission; W-066's overlap detection depends on evaluated constants, so widening this moves in the OPPOSITE direction from the next work item. Record in W8c. |
| R10 | Refutable-pattern rejection in irrefutable contexts (`let 5 = n`) | pattern_match.cpp:771 (upstream `expression pattern` TODO, LocalState) | check/testdata/patterns/expression.carbon (:17, :29, :41 upstream TODO comments) | Out of match arms entirely — an upstream-owned surface (upstream testdata, upstream TODO text). W8c records it as not-W-008; flipping it churns upstream goldens for no bullet movement. |
| R11 | Qualified alternative patterns (`case IntResult.Err`) | pattern_match.cpp:836-838 | fail_choice_alternative_pattern.carbon (fail_todo_qualified_pattern) | Out — the ledger files this under W-010's SF-4 work item, not W-008. No action here. |

Also verified: the defense-in-depth string `match case pattern on
unsupported choice alternative shape` (pattern_match.cpp:812-815) and
the non-choice leading-dot gate (handle_match.cpp:291-295) are
unreachable-by-design backstops, not residue.

**Scoreboard truth (R9):** both W-008 scoreboard entries —
control_flow/match_switch.carbon and
project/most_features_missing_match.carbon — already PASS (un-SKIPped
at W4-S1 and S2d). The residue slices therefore move the floor by
ADDING conformance programs (bullet deepening), not by un-SKIPping; §3
names them. The remaining match-family SKIPs (match_sum_type_payload's
interop half; if_let_let_else) belong to W5-S4 and W-012, not W-008.

## 1. V-3a: design authority per item

### 1.1 Tuple case patterns — DESIGNED, explicitly and centrally

-   pattern_matching.md:397-411 (§Tuple patterns): grammar, arity rule,
    elementwise sub-match.
-   :100-118: a tuple literal in pattern position IS a tuple pattern of
    expression patterns (ambiguity resolved in the pattern's favor), with
    left-to-right SHORT-CIRCUIT evaluation ("this code will call `F()`
    but not `G()`").
-   :723-741: the design's flagship `match` example is
    `case (42, (x: f32, y: f32))` — mixed literal/binding/nested-tuple
    case patterns. This is the load-bearing shape of the entire section.
-   p002188 §"Pattern matching syntax and semantics" is the accepted
    proposal behind all of the above.

### 1.2 `var` and `ref` case bindings — DESIGNED, with match examples

-   `var`: pattern_matching.md:318-356, with `match`-specific examples at
    :336-346 (`case (var n: i32, 1)`, `case var (n: i32, m: i32)`) and
    the lifetime/destruction example at :776-791.
-   `ref`: :134-135 grammar; :199-203 the constraint — "for `ref` binding
    patterns the user-provided scrutinee must meet this [durable
    reference] requirement itself". So `case ref a: i32` is valid exactly
    when the scrutinee expression is a durable reference (for example a
    `var` local); against a value expression it is a REAL error, not a
    TODO, and the conversion machinery already owns that diagnostic.
-   The re-platform plan recorded these as a later slice with their own
    TODO string (fork/match-replatform/plan.md §3.2(c)); this is that
    slice.

### 1.3 Non-binding payload subpatterns — DESIGNED, one nuance to record

pattern_matching.md:487-497: with a proper pattern present in the list,
an alternative pattern "matches if the active alternative in the
scrutinee is the specified alternative, and the arguments of the
alternative match the given tuple pattern" — exactly discriminant test +
elementwise match, the S2c shape extended. The nuance: with NO proper
patterns in the list (`case .Ok(42)`), the design says it "behaves like
an expression pattern" — that is, `==` on the whole constructed choice
value. In-slice choices implement no `Core.EqWith`, so a literal reading
would reject every such pattern. Recorded call (veto-able, §5 OQ-3):
implement the all-expression list identically to the mixed case
(discriminant test + elementwise `==` on the payload), which is
observationally equivalent to the specified whole-value `==` for choice
types with structural equality — the only equality these choices could
have. Refutability authority for the coverage interaction:
pattern_matching.md:589-594 (a constant-choice-valued expression pattern
is "treated as if" an alternative pattern for usefulness/exhaustiveness,
and remaining expression patterns are never exhaustive).

### 1.4 Compile-time case bindings — DESIGN-OPEN, keep gated

pattern_matching.md:154-177 defines binding phases for parameters and
declarations; nothing licenses a compile-time binding against a RUNTIME
match scrutinee, no design example exists, and upstream itself gates the
nearest relative ("local generic `let` bindings are currently
unsupported", handle_binding_pattern.cpp:405-412). A checked/template
binding in a case arm could only mean a constant scrutinee feeding a
symbolic binding — a shape nobody has designed. Verdict: NOT
implementable without design authorship; W8c narrows the gate to an
honest dedicated string and records the fork position. Lane "reject with
a real diagnostic" is NOT taken: the design does not forbid it either,
and a hard error would need the same missing design authority (the W-074
§1 lane-b lesson).

## 2. Mechanism

### 2.1 Shared infrastructure (built once, in W8a)

The landed machinery this rides:

-   **The refutable engine's state split** (pattern_match.cpp:94-105):
    `MatchCaseState` is a first-class `State` alternative; the test pass
    already prunes at binding roots (:567-573 — "bindings are
    irrefutable and belong to the bind pass") and already emits the
    `==` condition for `ExprPattern` (:763-882, operand order per
    pattern_matching.md:87-88).
-   **The engine's TuplePattern walk is state-generic**
    (:1040-1115): it converts the scrutinee to the tuple type
    (diagnosing arity/type mismatch — `TuplePatternSizeDoesntMatchLiteral`
    and the conversion diagnostics come free), then emits
    `TupleAccess` subscrutinees and pushes per-element work items.
    Upstream already CHECKS tuple patterns containing `ExprPattern`
    leaves in `let` (check/testdata/patterns/expression.carbon's
    fail_todo_control_flow golden shows
    `tuple_pattern (%expr_patt, %expr_patt)` SemIR) — check-side pattern
    construction needs NO new inst kinds.
-   **The two-pass arm contract** (handle_match.cpp:551-716): test pass
    emits one bool condition in the test block; bind pass runs
    `LocalPatternMatch` in the arm's body block; guards splice after the
    bind pass with their own failure edge.

Three shared pieces to build:

(a) **Condition collection for pattern trees.** Extend the
`MatchCaseState` traversal so a `TuplePattern` node collects its
elements' conditions (by way of `results_stack_`, the way `DoPostWork
TuplePattern` already collects element results at :1117-1128) and folds
them into ONE bool. Fold shape: the `and` operator's short-circuit
block_arg SemIR (handle_operator.cpp:410-500 is the existing in-tree
shape) rather than a flat chain of `BranchIf`s — it yields a single
value, preserving `MatchCase`'s one-condition CFG contract
(AddDominatedBlockAndBranchIf at :642-644) unchanged, and it is
design-shaped: pattern_matching.md:113-118 mandates short-circuit
left-to-right. In-slice all case expressions are constants (R9 stays),
so short-circuit vs eager is not observable — but the payload case (c)
REQUIRES it, so build it once.

(b) **Bind-pass pruning at expression leaves.** A mixed tree
(`case (1, b: i32)`) reaches the bind pass as a `TuplePattern`
containing an `ExprPattern`, and `LocalState`'s `ExprPattern` pre-work
is `context.TODO(..., "expression pattern")` (pattern_match.cpp:771).
The bind pass must prune at `ExprPattern` for match arms — the exact
mirror of the test pass pruning at bindings. Mechanism: a match-bind
mode on the local walk (a flag in `LocalState` set by a new
`MatchCaseBindPatternMatch` entry point, or an equivalent narrow carve)
so upstream `let`/`var` behavior is byte-identical. This also keeps the
single-splice invariant: each `ExprPattern`'s region is spliced exactly
once, by the test pass (`InsertHere` cannot run twice on a region,
pattern_match.cpp:314-319).

(c) **Coverage refinement** (the W-066 seam). `MatchCase`'s coverage
recording (handle_match.cpp:615-635) gains one bit: an
alternative-pattern arm counts toward `covered_alternatives` ONLY when
its payload subpattern tree is wholly irrefutable (all bindings); a
`.Some(42)` arm is refutable and records nothing
(pattern_matching.md:589-594 — see §4 R-4, the subtle part). Tuple-root
arms record nothing on choice scrutinees (they cannot type-match one);
on integer/tuple scrutinees the `default` requirement is unchanged (R8
stays), so their coverage state is inert — but record the
all-binding-tree = irrefutable classification anyway, because W-066
consumes exactly this classification.

### 2.2 W8a: tuple case patterns

-   **Scrutinee gate widening** (handle_match.cpp:127-187): admit tuple
    types whose element types are recursively in-slice-matchable
    (integer-shape, matchable choice, or tuple thereof). The
    temporary-cleanup argument at :139-144 extends elementwise: a tuple
    of trivially-destructible element types is trivially destructible.
-   **Root classification** (handle_match.cpp:577-613): add a
    `TuplePattern` root arm — test pass = the §2.1(a) traversal
    (all-binding trees contribute constant `true`, the existing
    binding-arm shape); bind pass = `LocalPatternMatch` with §2.1(b)
    pruning, `DeferCleanups` as today. The :609 fallback then narrows to
    genuinely unclassified roots; it stays (defense-in-depth precedent:
    the `unsupported choice alternative shape` string) — W8a must
    inventory what still reaches it (`case var 5` routes earlier by way of
    handle_let_and_var.cpp:152; `unused` roots classify as binding roots
    since the wrapper preserves `ValueBindingPattern`,
    handle_binding_pattern.cpp:46) and keep a golden pinned on it.
-   **Element scope honesty:** elements are constant-integer expression
    patterns, bindings, and nested tuples. Choice-typed elements match
    only by way of bindings in this slice: a leading-dot element is an ordinary
    designator needing `.Self` (real NameNotFound — the
    fail_nested_designator_subpattern precedent) and a qualified element
    hits the R11 TODO. Both already diagnose; no widening.

### 2.3 W8a: non-binding payload subpatterns

-   Delete the subpattern filter at handle_match.cpp:405-413; the
    payload `TuplePattern` root (already built at :417-451) becomes a
    mixed tree.
-   `MatchCaseAlternativePatternMatch` (pattern_match.cpp:504-526)
    currently returns only the discriminant test. Extend: discriminant
    condition, then — **strictly under it, in the `and`-rhs block**
    (§2.1(a)) — the payload-region `ClassElementAccess` extraction
    (today's bind-pass shape, handle_match.cpp:672-685) and the
    elementwise `==` conditions for expression leaves. The ordering is
    correctness, not style: the payload region of a non-active
    alternative is uninitialized storage, and a hoisted load feeds
    poison to a branch (§4 R-2).
-   Bind pass unchanged except §2.1(b) pruning; binding elements of a
    mixed payload (`case .Pair(1, b: i32)`) still initialize in the
    arm's body block from a second extraction — the arm's body is
    dominated by the discriminant test, so that read is safe, and
    re-extraction of a trivially-copyable payload is the landed S3c
    shape.
-   Coverage: §2.1(c). Single-alternative choices (W-068): the
    constant-true discriminant degenerate case keeps working — the
    payload conditions simply become the whole condition.

### 2.4 W8b: `var`/`ref` case bindings

-   handle_binding_pattern.cpp:517-520: delete the gate; let
    `VarBindingPattern` and `is_ref` fall through to the
    NameBindingDecl-shaped binding construction (`RefBindingPattern`
    kind, :496-498), under the case arm's implicit `let` introducer.
-   handle_let_and_var.cpp:146-155 (`VariablePattern` under
    `MatchCaseArm`): route to `add_local_var()` — `VarPattern` +
    `GetOrAddVarStorage` + `AddLocalVarPattern`, the NameBindingDecl
    arm's shape. Widen the `full_pattern_stack.h` kind CHECKs
    (`AddLocalVarPattern` :182-187, `GetLocalVarStorage` :195-201) to
    admit `Kind::MatchCaseArm`; the stack already books var arrays for
    it (`PushMatchCaseArm`, :105-110). Binding-free `case var 5` stays
    behind the (now correctly-narrow) combined-string TODO — `var`
    around a refutable pattern is a design oddity nobody has specified.
-   Root classification: `is_binding_arm` (handle_match.cpp:590-591)
    widens to `VarPattern` and ref-binding roots — irrefutable, constant
    `true` test, `has_irrefutable_arm` coverage. The bind pass needs no
    new engine work: `DoPreWork VarPattern` (pattern_match.cpp:946-1035)
    already initializes storage through `GetLocalVarStorage` under
    `LocalState`, and ref-binding conversion runs through
    `ConversionKindFor`.
-   `ref` scrutinee category: the scrutinee is already
    `ConvertToValueOrRefExpr` (handle_match.cpp:125); a durable-ref
    scrutinee (a `var` local) binds, a value scrutinee diagnoses through
    the standard conversion error. Both directions get goldens.
-   Composition: `case var (a: i32, b: i32)` (the design's own :343
    example, modulo types) is W8a's tuple tree under W8b's `VarPattern`
    — testdata-only if the machinery composes; a gate if it does not
    (§4 R-5).
-   Cleanups: in-slice types destroy trivially, but registration still
    goes through the arm scope (`MatchHandler`'s
    `AddAndDiscardScopeCleanups`), so the design's :776-791 destruction
    order is the one we grow into, not a re-platform.

### 2.5 Shared vs per-item summary

Shared (W8a builds): condition folding, bind-pass expr pruning, coverage
bit, scrutinee-gate recursion. W8a-only: tuple root classification,
payload-subpattern admission. W8b-only: binding-kind admission,
full_pattern_stack widening, var storage plumbing, ref category
testdata. W8b depends on W8a only for the composition testdata — it
could land first, but W8a first maximizes leverage (it alone discharges
the W-066 blocker, §3.4).

## 3. Slices

### 3.1 W8a — tuple case patterns + non-binding payload subpatterns (M)

Files: toolchain/check/handle_match.cpp, pattern_match.cpp (+ .h),
context.h (MatchCaseContext/MatchStatementContext bits), possibly a
narrow LocalState flag in pattern_match.cpp. No parse changes (parse
already produces TuplePattern/ParenPattern in case position). No
lowering changes expected — every emitted inst kind (TupleAccess,
ClassElementAccess, `and`-shape blocks, EqWith calls) lowers today; new
LOWER goldens only.

Probes, red-first (the TODOs are goldenable — the pins ARE the red
state): fail_todo_tuple_pattern's fail_todo_tuple_case subfile flips to
a positive golden; fail_choice_alternative_pattern's
fail_todo_expr_subpattern flips; fail_nested_designator_subpattern
keeps its NameNotFound error and loses only the trailing TODO line
(stays a fail golden, re-pinned).

New check goldens: match/tuple_pattern.carbon (all-expr, all-binding,
mixed, nested-tuple subfiles; fail_arity pinning
TuplePatternSizeDoesntMatchLiteral in case position; a fail_todo pin on
whatever still reaches the :609 fallback); match/payload_subpattern.carbon
(literal, mixed, multi-element, guarded, single-alternative choice);
**the coverage pin**: fail_nonexhaustive_payload_literal — a
two-alternative choice matched by `case .Some(42)` + `case .None` with
NO `default` MUST diagnose MatchNonexhaustive naming `.Some` (§4 R-4).
New lower goldens: lower/testdata/match/tuple_pattern.carbon and
payload_subpattern.carbon, the latter pinning the payload load's
position under the discriminant branch (the R-2 anti-regression pin).
All goldens ship empty-CHECK, autoupdated on the runner to fixpoint
(R15/R19/R26).

Conformance: new program control_flow/match_tuple_case_diff.carbon
(+ .diff.cpp C++ oracle) — bullet `Control flow: matching — good switch
equivalents` (R7 exact string), exercising the design's :723-741 mixed
shape on integer tuples; new program
control_flow/match_payload_literal.carbon — bullet `Control flow:
matching — sum-type consumption incl. std::variant/std::optional
interop`, a runtime dispatch on payload VALUE (`.Some(42)` vs
`.Some(n: i32)` fall-through proving first-match-wins order). Floor
96 → 98 over 126. R9 discharge: gate green (R21 parity), both programs
PASS on the scoreboard, every untouched match/let/param golden
byte-identical at autoupdate fixpoint, ledger W-008 notes updated.

### 3.2 W8b — `var`/`ref` case bindings (S/M)

Files: toolchain/check/handle_binding_pattern.cpp,
handle_let_and_var.cpp, full_pattern_stack.h, handle_match.cpp
(classification only). Probes: fail_todo_var_binding.carbon and
fail_todo_ref_binding.carbon flip to positive goldens (the TODO string
dies entirely — grep-clean). New check goldens:
match/var_binding.carbon (mutation through the binding observable;
binding scoped to arm body+guard, extending fail_binding_scope's
discipline; `case var (a: i32, b: i32)` composition), match/ref_binding.carbon
(aliasing a `var` scrutinee — write through `ref` visible after the
match), fail_ref_binding_value_scrutinee.carbon (real conversion error,
not TODO). New lower goldens: lower/testdata/match/var_binding.carbon
(pinning the per-arm alloca + copy — storage NOT aliased across arms,
pattern_matching.md:773-791). Conformance: new program
control_flow/match_var_ref_binding.carbon (owning bullet, good-switch
string) — mutate a `var` case binding, observe the original unchanged;
`ref` the scrutinee, observe the original changed. Floor 98 → 99
over 127. R9 discharge as W8a, plus: the `var`/`ref` TODO string
absent from the tree.

### 3.3 W8c — disposition and gate-narrowing (S; cut-with-record allowed)

No feature work. (1) Give compile-time case bindings their own honest
string (``compile-time binding in match `case` pattern``) at
handle_binding_pattern.cpp:647-653, re-pinning
fail_todo_compile_time_binding — needed anyway once W8a flips the
sibling subfile. (2) Ledger truth: rewrite W-008's notes to the
post-W8a/b residue — R4, R5/R6, R7 (`bool` called out as
design-reachable), R8, R9, R10 — each with gate site and pin; file
follow-up items for `bool` scrutinees and struct patterns if wanted.
(3) Decision-log entries for the §1.3 equality call and the §4 R-3
evaluation-order approximation. Alternatively (1) rides W8a and
(2)/(3) the W8b landing note, dissolving W8c; the DEFAULT is a thin
third slice so neither implementation slice carries ledger-rewrite
review load.

### 3.4 Ordering and the W-066 gate

Order: **W8a → W8b → W8c**. W8a first because it alone moves the
W-066 blocker: usefulness diagnostics compare arm pattern VALUES, and
W8a is what fixes that value domain (tuple constant vectors;
alternative index + payload constants). W8b adds only irrefutable
classifications that the existing binding-arm machinery already
represents, and W8c changes no semantics — **neither gates W-066**.
Recorded position: after W8a lands, W-066's blocked_by is dischargeable
(partial discharge of W-008 suffices); starting W-066 before W8a means
building overlap detection on a domain W8a immediately extends.
R4/R8/R9 interactions all push the same way: W-066 wants constant-only
cases (R9 stays) and profits from the R8 gate staying conservative.

## 4. Contingency + risks

-   **R-1 Blast radius / upstream merge friction.** handle_match.cpp and
    pattern_match.cpp are the fork's hottest files; pattern_match.cpp is
    additionally UPSTREAM-hot (the callee/caller/thunk engine). W8a
    deliberately touches only `MatchCaseState`-guarded paths plus the
    state-generic TuplePattern walk; the guard: every untouched
    let/var/param/thunk golden byte-identical at autoupdate fixpoint
    (R26), enforced as a review obligation, and the §2.1(b) carve keeps
    `LocalState` behavior bit-for-bit for non-match callers. Any edit
    that widens a `CARBON_KIND_SWITCH` over `State` must keep every arm
    exhaustive (the :746-751 FATAL arms are the pattern).
-   **R-2 Poison-safe payload reads (the W8a correctness core).** The
    payload region of a non-active alternative is uninitialized; loading
    it yields poison and branching on a poison-derived bool is UB. The
    elementwise `==` for `.Some(42)` MUST be emitted in the
    short-circuit rhs block dominated by the discriminant test — never
    folded eagerly. Pinned by the lower golden's block structure (§3.1).
    If review finds the `and`-shape awkward to build outside expression
    context, the fallback is the guard-shaped two-stage CFG
    (handle_match.cpp:701-712 is the in-tree template: BranchIf into an
    intermediate block, failure edge to the shared else block) — same
    dominance guarantee, two blocks instead of block_args.
-   **R-3 Evaluation-order approximation (record explicitly).** The
    design interleaves `var` initialization with testing
    (pattern_matching.md:776-791: `var y: X` initialized, then the
    sibling `0` tested, then destroyed on failure) and orders
    side-effectful pattern evaluation (:834-952). The fork's two-pass
    split (test all conditions, then bind) is observationally equivalent
    ONLY because in-slice scrutinee/element types are trivially copyable
    integers and in-slice case expressions are constants — no observable
    conversions, copies, or destructions exist to mis-order. This is a
    recorded approximation (decision-log, W8c), re-examined the day
    non-trivial types pass the scrutinee gate; the design's "Destroyed!"
    example is inexpressible in-slice, which is exactly why the
    approximation is safe today.
-   **R-4 Coverage interaction (the S2e seam — spell it out).** New
    pattern kinds must record coverage correctly or S2e exhaustiveness
    silently rots: (a) a payload-literal alternative arm is REFUTABLE —
    it must NOT push `covered_alternatives`; the §3.1 coverage pin
    golden makes this a hard regression test. (b) An all-binding tuple
    arm is irrefutable-ish — irrefutable given the arity/type already
    matched, which the checker enforces statically — but on non-choice
    scrutinees coverage is inert because R8 keeps requiring `default`;
    the classification is still recorded for W-066. (c) A guarded
    anything still records nothing (:620-623). (d) An error-recovery
    subtree still sets `has_error_arm`.
-   **R-5 Var storage placement.** `GetOrAddVarStorage` from a case
    arm's pattern context emits `VarStorage` inside the arm's
    NameBindingDecl in the TEST block; lowering must alloca it exactly
    as it does for `let var` locals. If lowering assumes
    NameBindingDecl-in-entry shapes, the contingency ladder is: (i) emit
    storage on demand in the bind pass (the full_pattern_stack.h:176-181
    comment's other lane), (ii) gate `var` composition shapes
    (`case var (…)`) behind a narrowed TODO and land bare `case var
    a: T` only. The lower golden lands FIRST in the slice to surface
    this before the conformance program depends on it.
-   **R-6 Mixed-tree engine unknowns.** If the §2.1(a)/(b) split fights
    the worklist engine (results_stack_ discipline across prune
    boundaries), fall back to splitting W8a: W8a-1 lands all-expr and
    all-binding tuples (no mixed trees, no bind-pass pruning needed —
    the two passes see disjoint shapes) with mixed trees behind a
    narrowed TODO; W8a-2 lands mixed trees + payload literals. The
    W-066 blocker discharge then moves to W8a-2; say so in the ledger
    if taken.
-   **R-7 Upstream match churn.** If upstream lands its own
    match/pattern work mid-stream, the F-002 staging-merge rule applies;
    the `MatchCaseState` isolation (R-1) keeps the rebase mechanical. Do
    not preemptively restructure for hypothetical upstream shapes (the
    W-012 rider-2 posture).

## 5. Open questions for the coordinator (genuine forks; recorded calls veto-able)

-   **OQ-1 (call recorded, §2.1(a)):** condition folding by way of the
    `and`-shape short-circuit block_args (recommended) vs guard-shaped
    multi-stage BranchIf CFG. Recommended for the single-condition
    contract; R-2 names the fallback. Veto flips to the fallback, not to
    eager folding (which R-2 forbids for payloads).
-   **OQ-2 (genuine fork):** does W8c exist as a slice, or do its three
    actions ride W8a/W8b landings (§3.3)? Default: thin third slice.
-   **OQ-3 (call recorded, §1.3):** all-expression payload lists
    implemented as discriminant + elementwise `==` (recommended) vs
    rejecting until choices have `Core.EqWith`. Rejecting would gate
    `case .Some(42)` on a prelude-equality workstream that no 0.1 bullet
    demands; the recorded equivalence argument is one sentence (R17).
-   **OQ-4 (genuine fork):** should `bool` scrutinees (design-reachable
    by way of :591 "treated like a choice type", exhaustiveness included) be
    filed as a new S-size work item at W8c, or folded into W-066's
    domain work? Plan takes no position beyond filing it.
-   **OQ-5 (genuine fork):** is the R10 upstream refutable-rejection
    surface worth a fork divergence ever, or does it wait for upstream?
    Plan recommends wait-for-upstream (it is upstream testdata churn
    with no bullet movement); a veto files it as its own item.

## Coordinator adjudications (2026-08-18, pre-review)

-   **OQ-1 → the short-circuit `and`-shape folding as W8a describes,
    CONTINGENTLY**: if it fights S2e coverage recording or the bind-pass
    pruning in implementation, the implementer STOPS and reports (R17),
    and the guard-shaped CFG (the S2d precedent) is the sanctioned
    fallback — a dated amendment either way.
-   **OQ-2 → W8c exists** as the cheap ledger-closing slice.
-   **OQ-3 → adopted**: discriminant + elementwise `==`, with the
    design's whole-value-`==` nuance recorded as observationally
    equivalent (digest item).
-   **OQ-4 → `bool` scrutinees filed as a NEW S work item** at the W8c
    round, not W-008 scope.
-   **OQ-5 → not fork work**; recorded.

All veto-able. Two adversarial plan reviews next (M-sized, broad
mechanism); on fold + sign-off, W8a proceeds.
