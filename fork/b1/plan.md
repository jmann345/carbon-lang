<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# F-006 B1 plan: postfix `?` + `Core.Try`, arbitrated over user-defined generic choices

Status: PLAN (process step 6, scaled loop). Baseline: trunk 3f6e6da (W5-S3 complete —
generic choices with payloads work end-to-end; 81 PASS / 0 FAIL / 31 SKIP over 112).
Design authority: docs/design/error_handling.md (the ratified F-006 design document,
sub-decisions D1-D12), the F-006/F-006a..l entries in fork/decision-log.md, and the
landed W5 state (SF-1..8, W5-S1 scope trades, S2a-S2e and S3a-S3c landing notes).
Precedent format: fork/w5-s3/plan.md. NO implementation in this document — planning only.

---

## 0. Scope and non-goals

### 0.1 In scope

Error-handling slice B1 delivers Carbon's one dedicated error-handling control-flow
construct — the postfix `?` operator — end-to-end, UNGATED by the OPEN SF-9 fork:

-   **(a) Parse support for postfix `?`.** Upstream has NONE (§1 finding: the bare
    `Question` token is lexed but consumed by no parser state), so the parse work is
    in scope: a suffix-group postfix node per F-006b/D2, chaining with `.`/`->`/calls.
-   **(b) The `Core.Try` interface in the prelude**, plus the branch-carrier type its
    `Branch` method returns (§2.2 — the one genuine design fork in this plan).
-   **(c) The check-side desugar of `expr?`** — Branch call, discriminant test, break
    payload → ImplicitAs-converted `FromBreak` call → early return; continue payload →
    the expression's value. No new SemIR inst kinds, no lowering changes (F-006's
    option paper prediction, re-verified in §1).
-   **(d) Conformance:** flip error_handling/control_flow_constructs.carbon (the
    "dedicated control flow constructs" bullet) from SKIP to PASS on `?` over
    USER-DEFINED generic choices, plus one new differential pair (§8).

The arbitration substrate is deliberately user-defined `choice MyResult(T: type,
E: type) { Ok(v: T), Err(e: E) }` — fully expressible since W5-S3 — NOT prelude
`Core.Result`. §0.2 is the scoping resolution making that split explicit.

### 0.2 The SF-9 fork-in-the-road: what B1 is, and what only S3p can be

F-006's original staging table (docs/design/error_handling.md §Implementation staging)
put `Core.Result` in the prelude at B1 and postfix `?`/`Core.Try` at B2. That staging
is RESTAGED here, because its B1 half is gated and its B2 CORE is not — one item of
the doc's B2 row, the `Run` `Result` signatures (error_handling.md:736), is itself
gated and is carved out to S3p as boundary item 3 below:

-   **Gated on SF-9 (OPEN):** the identity of `Core.Optional` — re-platform onto
    generic choices, adapter, or independent class — "and how `Core.Result(T, E)`
    relates" (decision-log OPEN forks). Minting prelude `Core.Result` or rebuilding
    `Core.Optional` before that AskUserQuestion round would preempt a user decision.
    Per the W5-S3 plan §0.2 split, that work is W5-S3p and rides the SF-9 round.
-   **Ungated:** everything mechanical about `?` — the token, the parse node, the
    `Core.Try` interface, the check desugar, the ImplicitAs error conversion (F-006c),
    and the D4 placement rules — arbitrated against user-defined generic choices.
    Note the original B1's other content, "consumption by way of `match`", ALREADY
    LANDED de facto for user choices at W5-S2/S3 (destructuring, exhaustiveness,
    guards, generics); nothing of original-B1 remains ungated except what this plan
    ships.

**This plan's B1 therefore = the F-006 `?`/`Core.Try` machinery (original B2's core),
arbitrated over user choices. What B1 CANNOT deliver without SF-9 — the recorded S3p
boundary:**

1.  Prelude `Core.Result(T, E)` itself and its `Try` impl (naming F-006a is decided;
    its prelude identity/relationship rides SF-9).
2.  The `Core.Optional` rebuild and its `Try` impl (F-006i/D9).
3.  The `Run() -> Core.Result(...)` entry-point signatures (F-006j/D10) — they name
    `Core.Result` in their contract.
4.  stdlib/optional_missing_ops.carbon stays SKIP (pinned to the placeholder API).
5.  error_handling/cpp_exception_interop.carbon stays SKIP (B3 work, and its intended
    body names `Core.Result(T, Cpp.Exception)`).
6.  The design doc's `Core.Result`-spelled examples as verbatim conformance programs.
7.  Unit break types (`BreakType = ()`) — independently blocked by SF-6, §2.7.

The F-006 staging table gets an in-slice doc amendment recording this restaging
(approval-gate item 1); the S3p plan inherits items 1-7 as its opening scope.

### 0.3 Out of scope (with rationale)

-   **B3 interop** (catching thunks, `Cpp.Exception` synthesis, `Carbon::expected`
    export) — unchanged staging; `?` on a C++ call whose mapped return type does not
    implement `Try` is the ordinary missing-impl error in B1, with no catching-thunk
    selection (the doc's selection rule activates at B3).
-   **F-011 `if (let ...)` / `let ... else`** — sibling workstream; the doc's claim
    that `?` shares the refutable-match core is honored at the machinery level (§2.4
    reuses the same choice-test/extract helpers), not by blocking on F-011.
-   **`try` blocks / `catch` expressions** — deferred past 0.1 (F-006k/D11).
-   **SF-6 relaxation** (aggregate/non-trivial payloads, including `()`) — §2.7
    records the consequence honestly instead of widening the gate.
-   **Match-expression form** — the desugar emits expression-level CFG directly; no
    value-yielding `match` is introduced (doc §Semantics and desugaring).

---

## 1. Current state (claims re-derived from the tree at 3f6e6da)

-   **Upstream `?` parse status: token only, no parser.** `Question` ("?") is lexed
    (toolchain/lex/token_kind.def:108) and used by NO parse state — the only
    Question-family consumers are `->?` (handle_function.cpp:28,
    handle_decl_name_and_params.cpp:70) and `:?` (handle_binding_pattern.cpp:186),
    the expression-forms tokens. `PrecedenceGroup::ForTrailing` has no `Question`
    case (precedence.cpp:182-283). Nothing named Try/Result/ControlFlow exists in
    core/prelude/ (grep; `Result` hits only arithmetic interfaces' associated
    constants). Conclusion: parse work IS in scope, and no dedicated error-handling
    machinery exists anywhere upstream to collide with.
-   **The suffix-position slot is the postfix loop, not `ForTrailing`.**
    `HandleExprInPostfixLoop` (parse/handle_expr.cpp:267-300) is the repeating state
    that chains `.`, `->`, calls, and indexing — exactly D2's "highest suffix group,
    repeating". The `ForTrailing` postfix path (handle_expr.cpp:417-435) runs at
    `TypePostfix` (precedence.cpp:238-240), which does NOT re-enter member access —
    `x?.y` would fail there, so `?` must land in the loop, not the table. The
    x-macro family for postfix operator nodes exists and has one instantiation
    (`CARBON_PARSE_NODE_KIND_POSTFIX_OPERATOR(Star)`, node_kind.def:325; typed node
    template typed_nodes.h:1226,1261-1262).
-   **The compiler-desugar-onto-prelude-interface precedent is `for`.**
    handle_loop_statement.cpp:171-257 desugars entirely in check:
    `BuildUnaryOperator`/`BuildBinaryOperator` with
    `{.interface_name = CoreIdentifier::Iterate, .op_name = CoreIdentifier::NewCursor/Next}`,
    accessor calls by way of `PerformMemberAccess` + `PerformCall` (:161-169), and
    `DeferCleanups` for statement-spanning temporaries (:240). The operator machinery
    (operator.cpp:24-103) resolves `LookupNameInCore` → interface member →
    `PerformCompoundMemberAccess` (impl-witness lookup, with a
    `missing_impl_diagnostic_context` hook) → `PerformCall`. CoreIdentifier names are
    declared in core_identifier.def. `Core.Iterate` itself (core/prelude/
    iterate.carbon:12-32) is the live precedent for everything the Try interface
    needs: associated constants (`let ElementType: ...;`), methods typed by them, and
    `impl forall [...] ... where .X = T and .Y = i32` — all compiling in today's
    prelude.
-   **Early return machinery is reusable mid-body.** `GetCurrentFunctionForReturn`
    reads the enclosing function off the scope stack (return.cpp:17-25);
    `function.GetDeclaredReturnType` distinguishes declared from omitted return
    types (:132-134, :152-155 — the D4 hook); `BuildReturnWithExpr` converts by way of
    `InitializeExisting(..., /*for_return=*/true)` into the return slot (:194) and
    discharges ALL enclosing cleanups (`AddReturnInstWithCleanups`, :241). An
    initializing expression (a call result) forwards into the return slot in place;
    `PerformCopy`/`CopyOfUncopyableType` (convert.cpp:1695-1702) fires only when a
    VALUE-category class expression must be copied — the load-bearing fact for §2.6.
-   **Choice test/extract helpers are one export away from reuse.**
    `GetChoiceDiscriminantType` (pattern_match.cpp:361) and `GetChoicePayloadInfo`
    (:411) are public (pattern_match.h:117,144); `EmitChoiceDiscriminantTest` (:460)
    is file-static. All three consume specific-resolved types (S3a/S3b), and the
    alternative name→index/payload metadata is the S2c `SemIR::ChoiceAlternative`
    table. Expression-level branching helpers exist in control_flow.h
    (`AddDominatedBlockAndBranchIf`, convergence helpers) — the short-circuit
    `and`/`or` precedent.
-   **SF-6 bounds every payload in this slice.** `IsInSliceChoicePayloadType`
    (type.cpp:313-320) admits integer/float/bool/pointer through adapters and
    qualifiers ONLY — tuples, including the empty tuple `()`, are rejected; the
    per-specific enforcement for generic choices is the S3b eval hook (diagnostic
    `ChoicePayloadNotTrivialInSpecific`, eval_inst.cpp:243-249; the structural
    pre-filter and post-completion checks at :286-326). Choice
    values: value repr is a pointer, init repr is in-place
    (handle_choice.cpp:414-420), no `Core.Copy` impl exists for any choice (S1 gap,
    re-confirmed at S3b/S3c landings).
-   **Conformance ground truth.** Scoreboard: 81/0/31 over 112. In
    fork/conformance/programs/error_handling/: control_flow_constructs.carbon is
    SKIP with pre-F-006 evidence ("no try/throw tokens or parser states exist … a
    strawman to be replaced by the accepted design", line 10) and a strawman
    `-> i32 or E` / `try` body — B1's flip target; cpp_exception_interop.carbon is
    SKIP pinned to B3; the four cpp_exceptions_* B0 programs PASS. No other program
    quotes `?`/Try/Result blockers (grep; project/evaluator_docs_review.carbon's
    SKIP is a documentation bullet, unrelated).

---

## 2. Design

### 2.1 Restaging is the scoping decision

Stated once, §0.2; carried as approval-gate item 1 and a doc co-amendment to
docs/design/error_handling.md §Implementation staging (B1 row: "`Core.Try`, postfix
`?`, ImplicitAs error conversion, arbitrated over user-defined choice types; prelude
`Core.Result`/`Core.Optional` and entry-point `Result` signatures move to the
post-SF-9 prelude stage (W5-S3p)"). The doc's normative SEMANTICS sections are
untouched by the restaging; §2.2's interface amendment is separate and explicit.

### 2.2 What does `Branch` return before `Core.Result` exists? (the design fork)

The doc's normative interface has `fn Branch(self) -> Result(ContinueType,
BreakType)` — circular with the SF-9 gate: the interface B1 must ship names the type
B1 must not mint. Three options:

-   **Option A — mint `Core.Result` now, exactly per doc.** F-006a fixed the naming,
    so the spelling is decided; only the identity question is open. REJECTED: SF-9's
    recorded scope is "how `Core.Result(T, E)` relates" to the Optional decision —
    landing the type preempts the user's fork, exactly what the S3p split exists to
    prevent. Secondary defect: the doc's own `Result` impl body (`fn Branch(self) ->
    Result(T, E) { return self; }`) does not compile in this fork — `return self`
    value-copies a choice (§2.6) — so option A would land a prelude impl that needs
    rewriting anyway.
-   **Option B — a dedicated prelude branch-carrier choice (RECOMMENDED, adopted):**

    ```carbon
    // core/prelude/try.carbon (new library "prelude/try").
    choice ControlFlow(C: type, B: type) {
      Continue(value: C),
      Break(value: B)
    }

    interface Try {
      let ContinueType: type;
      let BreakType: type;
      fn Branch(self) -> ControlFlow(ContinueType, BreakType);
      fn FromBreak(b: BreakType) -> Self;
    }
    ```

    `Core.ControlFlow` is Rust's actual `Try` shape (`ControlFlow<B, C>`), is NOT
    within SF-9's question (it is new, internal to the `Try` contract, and neither
    Optional nor Result), and preserves the doc's desugar semantics exactly — single
    `Branch` call, single destructuring, same laws — changing only the NAME of the
    carrier. When S3p mints `Core.Result`, its `Try` impl is written against
    `ControlFlow` unchanged. Costs, recorded: (i) a fork-authored prelude name lands
    pre-SF-9 → divergence-risk register entry per V-3a (upstream has no signal here;
    Rust alignment is the stated good reason); (ii) doc co-amendment of §The
    `Core.Try` interface (Branch's return type, the two prelude impls' bodies
    rewritten to match-reconstruct per §2.6, and the `ControlFlow` declaration);
    (iii) `ControlFlow(C, ())` is SF-6-inexpressible — §2.7, bounded out with the
    unit-break-type item. REVERSIBILITY (what makes this V-2 digest-able rather
    than a synchronous fork): pre-S3p, nothing outside B1's own testdata and one
    conformance program names `Core.ControlFlow` — a user veto at the digest is a
    prelude rename/removal plus golden churn, with no user-facing migration; the
    S3p round can still supersede the carrier when it decides `Core.Result`.
-   **Option C — accessor-shaped interface** (`fn IsBreak(self) -> bool` +
    `ContinueValue`/`BreakValue` accessors; no carrier choice at all — the for-loop
    `HasValue`/`Get` shape). REJECTED: it changes the USER-FACING impl surface and
    the observable call pattern (three user calls per `?` instead of one Branch),
    a much larger divergence from the ratified doc than renaming Branch's carrier;
    its only unique win (dodging the `()` payload gap) buys nothing B1 needs, since
    unit break types are S3p-boundary material either way.

Sub-decisions riding option B, all veto-able: the library name `prelude/try`
(export-imported from core/prelude.carbon like the other seven libraries); new
CoreIdentifier entries `Try`, `Branch`, `FromBreak` (core_identifier.def, the
Iterate/NewCursor precedent); alternative order `Continue` then `Break` — fixing
discriminant indices Continue=0/Break=1, which the desugar's test (§2.4 step 4)
and the goldens HARD-DEPEND on; `ControlFlow`'s alternatives spelled
`Continue(value: C)`/`Break(value: B)`. The parameter order `ControlFlow(C, B)`
(continue-first, matching `Try`'s `Result(T, E)`-shaped reading) is a DELIBERATE
divergence from Rust's `ControlFlow<B, C>` (break-first) — recorded in the V-3a
register entry alongside the name itself.

### 2.3 Parse design (B1a)

Add `CARBON_PARSE_NODE_KIND_POSTFIX_OPERATOR(Question)` (node_kind.def, beside Star
at :325 — the typed node and category ride the existing macros), and a
`case Lex::TokenKind::Question:` in `HandleExprInPostfixLoop`
(handle_expr.cpp:267-300): consume the token, `AddNode(NodeKind::
PostfixOperatorQuestion, ...)`, re-push the loop state. That single placement yields
every F-006b/D2 property BY CONSTRUCTION: highest (suffix) precedence, left-to-right
chaining with `.`/`->`/`(...)`/`[...]`, repeatability (`x??`), and `-x?` ≡ `-(x?)` /
`x? + y?` without parentheses (prefix/binary operands parse through
`ExprInPostfix`). `ForTrailing` is untouched — `?` never enters the binary-operator
table. Non-interactions, pinned by parse goldens: `->?`/`:?` remain intact (max
munch is unaffected — `?` here always follows a complete suffix expression, where
`->`/`:` cannot begin); `x->y?` and `a?.b` chain; `?` with nothing to its left stays
"expected expression". Two further recorded parse sub-decisions (both veto-able,
both golden-pinned): (i) `x ?` with whitespace before the `?` is ACCEPTED silently —
the postfix loop's tokens (`.`, `(`, `[`) perform no adjacency check and never call
`DiagnoseOperatorFixity` (parse/context.cpp:290; the fixity path belongs to
`ExprLoop`, handle_expr.cpp:360), so `?` inherits the loop's convention rather than
the operator table's; (ii) `i32*?` is a HARD parse error (after `*` binds at
`TypePostfix` through `ExprLoop`, control does not re-enter the postfix loop) while
`i32?` parses and is rejected in check — an asymmetry accepted as inherent to the
two parsing routes, pinned by a fail parse golden. Type-position `?`
(`var x: i32? `) PARSES as a postfix
expression and is rejected in CHECK by the ordinary missing-impl diagnostic (`type`
does not implement `Core.Try`) — no parse-level ban, recorded as a sub-decision
(approval-gate item 6; the doc's "never appears in type position" is enforced
semantically, which also keeps error recovery uniform).

Check-side, B1a registers the `HandleParseNode(Context&, Parse::
PostfixOperatorQuestionId)` handler emitting a NEW gate string —
`` `postfix `?` operator` `` — by way of `context.TODO`, so the whole surface stays
honestly gated until B1b (§6).

### 2.4 The check desugar (B1b)

One new handler path (handle_operator.cpp, beside `PostfixOperatorStar`'s handler at
:256, or a dedicated handle_question.cpp if it outgrows the file), emitting only
existing inst kinds. Sequence for `expr?` (revised after plan review, 2026-08-08:
step 1 gains the pre-flight witness lookup and the return-form check, step 4 the
bail-not-CHECK rule, step 5 loses the broken diagnostic-hook spec — see the A-1
paragraph after the list — and the region-position policy is new):

1.  **Enclosing-context pre-flight** (cheap, before ANY emission): not in a
    function scope → `QuestionOutsideFunction`; the §2.4-policy region check (see
    REGION-POSITION POLICY below) → `QuestionInPatternContext`;
    `GetDeclaredReturnType` has no value → `QuestionNoDeclaredReturnType` with the
    return.cpp:54 "no return type provided" note shape (covers D4's auto-return
    and file-scope/global-initializer bans — file scope has no function scope);
    the declared return FORM is not `InitForm` (return.cpp:202-236's `RefForm`
    and `SymbolicBinding` paths) → `QuestionNonInitReturnForm` — the desugar
    supports ordinary value-returning functions only, rejected up front rather
    than surfacing a conversion failure deep in the return machinery; finally the
    **return-type `Try` witness pre-flight**: resolve `Core.Try`'s facet type
    (`LookupNameInCore` + `FacetTypeFromInterface`, the `GetAssociatedValueImpl`
    shape, member_access.cpp:730-740) and run `LookupImplWitness` against the
    declared return type's constant; no witness → the real Error
    `QuestionReturnTypeNotTry` at the `?` token with the return-type-here note
    (return.cpp:63-69 shape). The pre-flight also gives B1a's gate and B1b's
    diagnostics one stable anchor: everything is diagnosed before the first inst
    exists. Inside `match` arm BODIES nothing special is needed:
    `GetCurrentFunctionForReturn` is scope-stack-based, so `?` targets the
    enclosing FUNCTION by construction (D4's third clause).
2.  **Evaluate once:** `ConvertToValueOrRefExpr(operand)` (the for-loop's :181
    discipline).
3.  **Branch call:** `BuildUnaryOperator(loc, {.interface_name = CoreIdentifier::
    Try, .op_name = CoreIdentifier::Branch}, operand_id)` with a
    `missing_impl_diagnostic_context` note `QuestionOperandNotTry` — valid on THIS
    path because `Branch` has `self`, so `PerformCompoundMemberAccess` takes the
    instance branch that consumes the hook (`PerformImplLookup`,
    member_access.cpp:815-821). The interface SIGNATURE guarantees the result type
    is a `ControlFlow(C, B)` specific with the impl's associated constants
    substituted — the desugar reads `C` and `B` off the call's type (payload
    metadata), never off the witness directly. `ConvertToValueOrRefExpr`
    materializes the temporary.
4.  **Discriminant test:** `GetChoiceDiscriminantType` on the carrier type (its
    forced-completion discipline rides the S3a scrutinee-gate mechanism — the call
    in step 3 already completed the specific; `RequireCompleteType` first if tracing
    shows otherwise), then `EmitChoiceDiscriminantTest` against `Break`'s index
    (1, fixed by §2.2's declaration order) — EXPORTED from pattern_match.cpp
    (pattern_match.h), the one helper-visibility co-change. A nullopt from
    `GetChoiceDiscriminantType` (reachable under error recovery — an
    all-payloads-rejected carrier resolves its repr to `ErrorInst`, the S3b
    §2.5(ii) shape) is a BAIL to `ErrorInst`, never a CARBON_CHECK.
    `AddDominatedBlockAndBranchIf` → break block; else-path block is the continue
    block.
5.  **Break block:** extract the break payload (`GetChoicePayloadInfo` +
    `ClassElementAccess` payload region + tuple element — the S2c bind-pass shape,
    reference projection, no copy); resolve `R.(Core.Try.FromBreak)` — the
    `GetOperatorOpFunction` lookup (operator.cpp:24-41) anchored by
    `PerformCompoundMemberAccess` on the RETURN TYPE's type-inst, proceeding under
    the step-1 pre-flight guarantee that the witness exists (defensive `ErrorInst`
    bail retained); `PerformCall({break_value})` — **the argument conversion to
    `R.BreakType` IS the D3/F-006c ImplicitAs error conversion**, applied by the
    ordinary call machinery, no `?`-specific conversion code exists; then
    `BuildReturnWithExpr` on the call result — an initializing expression
    forwarding into the function's return slot, cleanups discharged by
    `AddReturnInstWithCleanups` (§2.8).
6.  **Continue block:** extract the continue payload the same way, convert to value
    — that inst is the VALUE of `expr?` (type `C`); expression checking continues
    with the continue block as the current block (the `and`/`or` mid-expression
    block-switch precedent). No convergence-with-arg is needed: the break path
    diverges, so the continue block has a single predecessor.

**A-1 mechanism correction (revised after plan review, 2026-08-08).** The original
draft hung `QuestionReturnTypeNotTry` on `missing_impl_diagnostic_context` at the
`FromBreak` compound access. That hook is DEAD on this path: `FromBreak` has no
`self`, so `PerformCompoundMemberAccess` takes the NON-instance branch
(member_access.cpp:823-829 → `GetAssociatedValueImpl`, :704-740), which never reads
`diagnose` or the context hook — a non-`Try` return type would have surfaced as a
note-less generic facet-conversion failure. The fix is the step-1 pre-flight
witness lookup (chosen over a `Diagnostics::ContextScope` bracket around the
access — the S3b IncompleteTypeInMonomorphization precedent — because the
pre-flight diagnoses before any emission, upgrades the diagnostic from a context
note to a targeted Error, and anchors ALL of D4's rejections in one place).

**REGION-POSITION POLICY (new, revised after plan review, 2026-08-08 — a V-2
digest item).** Three positions put a Try-implementing `?` inside a CAPTURED
EXPRESSION REGION rather than straight-line body CFG: (1) a `case` guard
(`case .Ok(v: i32) if (H(v)? > 0)` — the guard region splices by way of
`SpliceMatchCaseGuard`/`InsertHere` and owns the S2d failure-edge discharge);
(2) a `case` expression pattern (`case H(b)? =>` — RF-4's constant gate consults
the region after building and DISCARDS non-constant regions, orphaning any blocks
inside); (3) a binding-pattern type annotation (`var y: r? = 0;` — the type-expr
region splices at pattern_match.cpp:600-608). The desugar emits a `ReturnExpr`
TERMINATOR plus multi-block CFG, which no captured region has ever contained
(guard regions carry only Branch-terminated blocks; pattern.cpp:42's own comment
concedes single-entry/single-exit is unvalidated). Options: (i) SUPPORT — trace
and validate return-terminated regions through every splice path; rejected for
B1: three splice consumers × an unvalidated region invariant is its own slice of
work, and no F-006 example needs it; (ii) GATE-BY-TODO — rejected: this is not a
staging gate on planned work but a real design boundary (`?` inside a pattern has
no defined F-011 story yet), and a TODO string would promise support nobody has
planned; (iii) **DIAGNOSE-AND-REJECT (RECOMMENDED, adopted):** a clean authored
diagnostic, `QuestionInPatternContext` (§2.5), emitted by the step-1 pre-flight
whenever `?` is checked with an open captured expression region. Detection: the
`context.region_stack()` depth — the function body itself is region depth 1
(function.cpp:499), and every captured-expression push (`BeginExprRegionForPattern`,
pattern.cpp:20-24, and the S2d guard capture) nests above it, so the check is
"region depth > 1" (a trivial depth accessor on RegionStack if one is missing —
mechanical). The policy's own over-fire falsifier is the POSITIVE initializer
golden — `var f: i32 = Open()?;` and `?` in ordinary statement/argument positions
run at depth 1 and must compile; the three region shapes are each pinned as fail
goldens (§3 B1b exit criteria, risk R-2).

No new SemIR inst kinds; no lowering changes (branch/return/call/class-access all
lower today); the lower golden pins the emitted CFG, not new code.

### 2.5 Diagnostics authored here (final text, house precedent: plan-reviewed)

-   `QuestionOutsideFunction`, Error: `` `?` can only be used inside a function
    body ``.
-   `QuestionInPatternContext`, Error: `` `?` cannot be used inside a pattern, a
    `case` guard, or a binding's type expression `` (the §2.4 region-position
    policy; revised after plan review, 2026-08-08).
-   `QuestionNoDeclaredReturnType`, Error: `` `?` requires the enclosing function to
    have a declared return type that implements `Core.Try` `` (+ the existing
    no-return-type note).
-   `QuestionNonInitReturnForm`, Error: `` `?` cannot be used in a function whose
    return uses a `ref` or expression form `` (+ the return-form-here note shape,
    return.cpp:113-114; revised after plan review, 2026-08-08).
-   `QuestionOperandNotTry`, Context (attached to the Branch impl-lookup failure —
    live on this path per §2.4 step 3): `` operand of `?` does not implement
    `Core.Try` ``.
-   `QuestionReturnTypeNotTry`, Error (revised after plan review, 2026-08-08:
    upgraded from a context note to the pre-flight's own Error — the original
    context-hook placement was dead code, §2.4's A-1 paragraph): `` return type
    {0} of the enclosing function does not implement `Core.Try` `` ({0} =
    InstIdAsType), at the `?` token, with the return-type-here note
    (return.cpp:63-69).

The B1a gate string `` `postfix `?` operator` `` is authored in §2.3 and discharged
in B1b (§6). Recorded trade: `QuestionReturnTypeNotTry` surfaces at the `?` site
(where the pre-flight runs), not the return-type declaration; the attached note
points at the declaration.

### 2.6 The `Core.Copy` interaction (the flagged central risk) — traced, verdict: does not block B1

The gap (S1-recorded, re-confirmed at S3b/S3c): choice types implement no
`Core.Copy`, and initializing a `var`/return slot from a VALUE-category choice
expression runs `PerformCopy` → `CopyOfUncopyableType` (convert.cpp:1695-1702).
Trace of every choice-valued flow in the `?` design:

1.  **Operand → Branch's `self` param:** by-value param passing of a choice is
    value BINDING, not copy — pinned since S3b (the R-2 by-value-param passing pin).
    No copy.
2.  **Branch's result → scrutinee temporary:** a call result is
    initializing-category; materialization into a temporary is in-place
    (`FinalizeTemporary`), not `PerformCopy`. No copy.
3.  **Payload extraction (both paths):** `ClassElementAccess` chains are reference
    projection (S2c's R-7 argument); payload element types are SF-6-scalar in every
    admissible specific, so the subsequent binding/conversion copies scalars only.
    No choice-valued copy.
4.  **`FromBreak(...)` result → return slot:** the desugar returns a CALL RESULT —
    initializing-category, forwarded into the enclosing return slot by
    `InitializeExisting(..., for_return=true)` (return.cpp:194). No copy. Inside
    the impl, `FromBreak`'s body constructs `.Err(e)` in place (S3b constructor
    return-slot shape). No copy.
5.  **The one shape that DOES hit the gap:** an impl body that returns a
    choice-valued BINDING — the design doc's own `fn Branch(self) -> Result(T, E)
    { return self; }`. `self` is value-category; the return-slot init copies →
    `CopyOfUncopyableType`, a real diagnostic today. CONSEQUENCE, designed around
    rather than fixed: every B1 impl (testdata, conformance, and the doc's amended
    impl sketches) writes `Branch` by MATCH-RECONSTRUCT — destructure `self`, build
    the `ControlFlow` alternative by way of constructor call in the return position:

    ```carbon
    impl forall [T: type, E: type] MyResult(T, E) as Core.Try
        where .ContinueType = T and .BreakType = E {
      fn Branch(self) -> Core.ControlFlow(T, E) {
        match (self) {
          case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }
          case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }
        }
      }
      fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }
    }
    ```

    Every piece of that body is landed, pinned S3 surface: symbolic-specific
    scrutinee + symbolic payload destructure (S3c's R-8 POSITIVE verdict,
    choice_generic_payload_pattern.carbon), generic constructor calls returning
    in place (S3b), exhaustive match without `default` (S2e). A fail golden pins
    the `return self` shape's CopyOfUncopyableType so the bound is visible, not
    latent (§3 B1b exit criteria; risk R-5).

Verdict: the `?` desugar itself never value-copies a choice; the Copy gap
constrains impl-body STYLE, which this plan adopts explicitly and pins. Choice
`Core.Copy` synthesis stays a recorded post-0.1/W-item matter, NOT a B1
prerequisite.

### 2.7 SF-6 transitivity and the unit-break-type bound (honest scope-in of a gap)

`ControlFlow(C, B)` is itself a generic choice, so `C` and `B` must pass the
per-specific SF-6 check (eval_inst.cpp) at every use. Two consequences:

-   **No NEW restriction on `Result`-likes:** a user `MyResult(T, E)`'s `T`/`E`
    already had to be SF-6-admissible for `MyResult` to exist; `ControlFlow(T, E)`
    admits exactly the same set. `?` inherits SF-6, unchanged and un-widened.
-   **Unit break types are inexpressible:** `BreakType = ()` (the doc's `Optional`
    impl, D9) needs `Break(value: ())`, and `IsInSliceChoicePayloadType` rejects
    tuples including `()` (type.cpp:318-319; the S1 "aggregates rejected"
    allowlist). B1 does NOT widen the allowlist: user impls in this slice use
    scalar break types (which the openness demo needs anyway), a fail golden pins
    `ControlFlow(C, ())`'s per-specific rejection so the bound is arbitrated, and
    the gap is recorded as a NEW work item at landing (options for S3p, decided
    then: admit the zero-sized `()` payload as a minimal allowlist widening, or
    give the prelude `Optional` impl a scalar break carrier). This is S3p-boundary
    item 7 and risk R-4.

### 2.8 Cleanups statement (the R-7 discipline, re-derived for mid-expression return)

`?` introduces the first EARLY RETURN emitted mid-statement with a partially built
expression around it (`F(a, G(b)?)`). The discharge argument: every temporary
registered so far in the statement (the operand temp, the ControlFlow temp, earlier
argument temporaries) lives in enclosing Owned scopes; the break path's
`AddReturnInstWithCleanups` discharges ALL of them at return (return.cpp:241 —
the same whole-function discharge every `return` performs), while the continue path
discharges the identical set at statement end as usual. The paths are exclusive —
no double-destroy — the S2d guard-failure-edge argument transplanted to the return
edge. In-slice, all registered cleanups are of trivially-destructible shape
(SF-6-scalar payloads; choice destroys are structurally trivial), so discharge
placement is pinned by goldens rather than observable at runtime; the S2d
"revisit if non-trivial destructors become registrable" note carries over verbatim.
Falsifier goldens: R-2 (§5).

---

## 3. Slices

Each independently landable through the full R11 loop (implementer → 2 adversarial
reviewers → fixer → merge gate: runner autoupdate + `bazel test //toolchain/...` +
conformance non-regression), scoreboard/work-items/decision-log updates at landing
(R9). No local bazel — verification rides CI (house rule; one red-first-CI
reconciliation commit per slice, R15/R19).

### B1a — parse `?` + gated check handler (S)

Scope — parse only, plus the gate: node_kind.def/typed_nodes.h postfix-Question
macro row; the `HandleExprInPostfixLoop` case; the check handler emitting the NEW
`` `postfix `?` operator` `` TODO at the node; a courtesy R10 refresh of
error_handling/control_flow_constructs.carbon's SKIP evidence (its "no … parser
states exist" sentence goes stale at B1a — re-pinned to the B1a gate string,
un-SKIP still B1b's). NOTHING else — no prelude, no desugar.
Exit criteria: parse goldens question.carbon (chaining `Open(n)?.Read()?.x`,
repetition `x??`, `-x?` and `x? + y?` shapes, `a?[i]`, `x->y?`, and the C-1 pin —
`x ?` with whitespace, accepted) and fail_question.carbon (`?` with no operand;
`?` at statement start; the C-2 pin — `i32*?` hard parse error); check golden
fail_todo_question.carbon pinning the TODO at expression, statement, argument, and
type positions (all four gated identically); lexer adjacency pins that `->?`/`:?`
forms are unchanged. Byte-equivalence: §4's zero-churn claim holds (the only
reachable new path requires a bare `?` token). Conformance: NO change — a gated
TODO flips nothing (the SKIP-evidence refresh is R10 hygiene, not a status
change); floor stays 81/0/31 over 112.

### B1b — `Core.Try` + desugar + conformance (M, the risk slice)

Scope: core/prelude/try.carbon (§2.2's `ControlFlow` + `Try`, export-imported from
core/prelude.carbon; BUILD glob is mechanical); the matching min_prelude part
toolchain/testing/testdata/min_prelude/parts/try.carbon so check/lower goldens can
import it (the parts/iterate.carbon precedent — the D-1 co-change, revised after
plan review, 2026-08-08); core_identifier.def entries; the §2.4 desugar (pre-flight
included) replacing the B1a TODO; §2.5 diagnostics; the pattern_match.h export
of `EmitChoiceDiscriminantTest`; testdata; the conformance flip + new differential
pair; doc co-amendments (staging table §2.1, Try section §2.2, impl sketches §2.6);
divergence-risk register entry; decision-log landing note.
PRE-DECLARED fallback split if the slice overruns: B1b-i (prelude + desugar +
check/lower goldens, arbitrated by testdata) and B1b-ii (conformance flip +
differential pair + doc amendments), each independently landable.
Exit criteria:

-   check golden question.carbon: `?` over a concrete user `MyResult(i32, i32)`;
    TWO specifics in one function resolving distinct `ControlFlow` specifics (risk
    R-3's falsifier); `?` in a `var` initializer (`var f: i32 = Open()?;` — the
    region-policy over-fire falsifier, §2.4); a `?` chain in one statement; `?` in
    argument position; `?` inside a `match` arm body (propagates from the
    function); `?` inside an `if` expression arm; error CONVERSION — break type
    `E1` (an adapter) returned from a function whose break type is `E2` with a
    user `ImplicitAs` impl (D3 pin), plus the no-conversion fail pin; `?` inside a
    generic function body (symbolic `R`) — scoped IN like S3a's R-8 with the same
    narrowing rule (instability re-gates it behind a precise TODO, not the slice).
-   check golden fail_question.carbon: operand not implementing Try (`i32?`, and a
    type-position `i32?` — same diagnostic, §2.3's sub-decision); return type not
    implementing Try (`fn F() -> i32` using `?` inside) — pinning the PRE-FLIGHT
    `QuestionReturnTypeNotTry` Error + note, not a facet-conversion cascade
    (revised after plan review, 2026-08-08); undeclared return type; file-scope
    `?`; the THREE region-position pins (`?` in a `case` guard, in a `case`
    expression pattern, in a binding's type annotation — each diagnosing
    `QuestionInPatternContext`, §2.4 policy); a `ref`/form-return function using
    `?` (`QuestionNonInitReturnForm`); `ControlFlow(C, ())` per-specific SF-6
    rejection (R-4 pin); the impl-body `return self` CopyOfUncopyableType pin
    (R-5, §2.6).
-   lower golden question.carbon: the full desugar CFG for two specifics —
    discriminant compare, conditional branch, payload access, FromBreak call,
    early `ret`, continue-path value — pinning that NO copy/memcpy exists on the
    propagation path beyond in-place return-slot init (R-5 falsifier).
-   Conformance (§8): error_handling/control_flow_constructs.carbon rewritten to
    the F-006 shape (user `MyResult` + `Try` impl + `?` propagation, both paths
    observed at runtime, inputs runtime-computed per R16d, match consumption
    exhaustive without `default`) and un-SKIPped; NEW differential pair
    error_handling/question_propagation_diff.carbon/.diff.cpp (C++ oracle: an
    early-return chain over a struct-shaped result, DIFF-1 conventions — no
    EXPECT-STDOUT, mismatch is the arbiter), probing a 3-deep `?` chain with the
    failure injected at a runtime-selected depth.

Dependency chain: B1a → B1b. Inventory: closes the gap-analysis "dedicated error
handling control flow" line to arbitrated-PASS; opens the unit-break-type work item
(§2.7); W5-S3p and B3 follow.

---

## 4. Byte-equivalence expectations

-   **B1a: zero churn.** The new parse case is keyed on a token no existing source
    produces in a reachable position (bare `?` today is already a parse error whose
    goldens do not change shape — the new case replaces "expected expression"
    recovery only where `?` FOLLOWS a complete postfix expression, which previously
    also errored; any golden that pinned such an error is listed and re-pinned in
    the slice, expected count: zero, verified by grep before implementation).
    Adding a node kind and its check handler touches no existing golden (kinds
    print by name). Any other churn is stop-and-explain.
-   **B1b: new/touched files only.** Non-`?` code takes byte-identical check paths
    (the desugar is reachable only from the new node). The prelude ADDITION is this
    fork's first — the budgeted expectation is churn confined to: new goldens, the
    conformance rewrite, and docs; ZERO churn in existing check/lower goldens, on
    the argument that unused prelude entities are not printed and import-ref
    naming is content-derived, not positional. This claim is explicitly the
    watchlist item (risk R-1): ANY existing-golden movement from the prelude
    addition — even ID-only — is a stop-and-explain event requiring a written
    reconciliation (the S3b §4-amendment precedent), not a silent autoupdate ride.

## 5. Risk register (falsifiable)

-   **R-1. Prelude-addition blast radius.** First prelude library added by the
    fork; the zero-churn claim (§4) is untested. FALSIFIER: post-autoupdate diff
    shows any existing check/lower golden changed. Response ladder: pure ID
    renumbering → written §4 amendment (S3b precedent); content changes → halt,
    root-cause before landing.
-   **R-2. Mid-expression early return.** §2.8's discharge argument and the
    partially-built-expression claim. FALSIFIERS (all B1b goldens): `?` in argument
    position (`F(a, G(b)?)`) — malformed SemIR or a dropped pending operand would
    surface in the golden or verifier; a two-`?` chain in one statement; `?` in a
    `match` arm (interaction with the arm's DeferCleanups discipline — discharge
    must be the return's whole-function discharge, not the arm's); `?` inside an
    `if` expression arm (branched CFG at region depth 1 — must compile). Extended
    after plan review, 2026-08-08: the three CAPTURED-REGION shapes (guard,
    expression pattern, type annotation — §2.4 policy) are R-2 territory too, and
    their falsifiers are the three `QuestionInPatternContext` fail pins — any of
    them instead producing a verifier CHECK-crash, an orphaned return-terminated
    block, or a silent compile falsifies the policy's detection mechanism (the
    region-depth check), not just the golden. A verifier CHECK-crash on any of
    these is the falsification.
-   **R-3. Generic machinery over choice impl subjects.** `impl forall` on a
    generic CHOICE + associated-constant `where` rewrites + witness calls resolving
    per specific is upstream-mature machinery composed in a new way. FALSIFIER:
    the two-specifics-one-function golden — both `Branch` calls must resolve to
    distinct `ControlFlow` specifics with correct payload types; a shared or
    stale specific is the falsification. Symbolic-`R` instability NARROWS the
    scope-in (re-gate behind a precise TODO string), not the slice.
-   **R-4. Unit break types (§2.7).** The bound must be visible, not latent.
    FALSIFIER-AS-ARTIFACT: the `ControlFlow(C, ())` fail pin — if it does NOT
    diagnose (the allowlist admits `()` after all), §2.7's premise is wrong and
    the S3p boundary item is re-scoped (that would be good news, but it must be
    discovered by the pin, not assumed).
-   **R-5. A copy hiding on the propagation path (§2.6).** FALSIFIERS: the lower
    golden's no-copy claim (any `Core.Copy` call or unexpected memcpy on the
    break/continue path falsifies the §2.6 trace); the `return self`
    CopyOfUncopyableType fail pin (if it COMPILES, choices gained copyability
    somewhere and §2.6 needs re-derivation).
-   **R-6. Upstream collision (standing rule 5 / V-3a).** Error handling is
    named-but-undesigned upstream ("errors are values" + a future `?`-like
    operator). Re-check carbon-language/carbon-lang for in-flight error-handling
    or `?` work before EACH slice's implementation; a hit escalates to the
    orchestrator. `ControlFlow`/`Try`/`Ok`/`Err` spellings ride the
    divergence-risk register.
-   **R-8. Parse regressions around the Question-family tokens.** FALSIFIERS: the
    B1a lexer/parse pins — `->?` and `:?` goldens byte-identical; `x->y?`, `a?.b`,
    `x??` parse as specified; any existing parse golden churn. (Label R-7 is
    skipped — it would collide with the R-7 cleanups rule referenced in §2.8/§9,
    the w5-s3 plan's convention.)

## 6. TODO-string discharge ledger

-   `` `postfix `?` operator` `` — NEW, authored at B1a (the PostfixOperatorQuestion
    check handler, the only emission site), pinned by fail_todo_question.carbon.
    B1b DELETES the site and the pin flips to the positive question.carbon goldens
    plus the §2.5 real diagnostics. Net across B1: zero TODO strings remain.
-   All existing TODO strings — the six-site combined W4 string, the scrutinee
    string, the `var`/`ref` case-binding string, S2e's integer-`default` string,
    the Self-dependent payload string — survive BYTE-IDENTICAL at their sites;
    B1 touches none of them (verified by §1: no error-handling gate exists to
    lift).
-   SKIP-evidence flips (R10 co-changes): error_handling/
    control_flow_constructs.carbon's SKIP line is REFRESHED at B1a (stale
    "no parser states exist" sentence re-pinned to the B1a gate string) and
    DELETED at B1b (program un-SKIPs); no other SKIP quotes B1-affected
    evidence (§1). The
    cpp_exception_interop.carbon SKIP text is NOT touched (its B3 evidence
    remains accurate — `Core.Result` still absent, per the S3p boundary).

## 7. Testdata & golden flow

Per-slice lists in §3. B1b goldens import `Core.Try`/`Core.ControlFlow` through
the NEW min_prelude part (toolchain/testing/testdata/min_prelude/parts/try.carbon,
mirroring library "prelude/try" — the parts/iterate.carbon precedent; D-1
co-change). House rules: new failing subfiles ship hand-written
CHECK:STDERR pins (S2c-S3c precedent) — including every §2.5 diagnostic and the
R-4/R-5 pins — other CHECK content rides the runner autoupdate (R15/R19, one
red-first-CI reconciliation commit per slice); clang-format by way of hooks (R12/R18);
`runner.py --self-test` before conformance-touching commits; private `--out`
(R5); prek gate (R23/R25). As this plan's own stated practice (not an R6 claim —
R6 governs sketches inside SKIP programs), the REWRITTEN conformance program
bodies are compile-verified against the fork toolchain before commit — noting
R1's PrintStr trap and R2's Core units for the runnable programs.

## 8. Conformance floor arithmetic

Starting floor (fork/conformance/out/scoreboard.json at 3f6e6da): **81 PASS /
0 FAIL / 31 SKIP over 112 programs.**

-   **B1a: no movement** — 81/0/31 over 112 (a parse-only slice with a gated
    check TODO cannot honestly flip anything; adding a conformance program for a
    gated feature would be a SKIP add, which this plan declines — the bullet
    already has its SKIP representative).
-   **B1b: exactly one flip + one addition.**
    -   error_handling/control_flow_constructs.carbon SKIP → PASS (the "Error
        handling: dedicated control flow constructs" bullet becomes
        scoreboard-arbitrated): 82 PASS / 30 SKIP over 112.
    -   NEW error_handling/question_propagation_diff.carbon/.diff.cpp (one
        program per DIFF conventions): **83 PASS / 0 FAIL / 30 SKIP over 113.**
-   **SKIPs that explicitly do NOT flip** (each re-verified against its quoted
    evidence): error_handling/cpp_exception_interop.carbon (B3: catching thunks +
    `Core.Result` + `Cpp.Exception`), stdlib/optional_missing_ops.carbon (SF-9
    placeholder API → S3p), control_flow/match_sum_type_payload.carbon (W5-S4
    variant interop), and the 27 others, none of which quotes `?`/Try evidence
    (§1 grep). FAIL stays 0 throughout; scoreboard regeneration rides each
    landing gate (R9); README program table regenerated by
    `runner.py --update-readme-table` (DIFF-4).

## 9. R-7 cleanups

Stated in §2.8 and re-derived per slice: B1a emits no runtime code; B1b's new
runtime surface is the desugar CFG, whose only cleanup-relevant novelty is the
mid-statement whole-function discharge on the break path — argued exclusive with
the statement-end discharge, pinned by the R-2 goldens, trivially destructible
in-slice. Impl bodies (`Branch`/`FromBreak`) introduce no new cleanup shapes:
they are ordinary generic-choice match/construct functions already covered by
the S2b-S3c discipline.

## Approval gate

This plan does not authorize implementation. Per house protocol it went to TWO
adversarial plan reviewers (round 1 complete, 2026-08-08 — findings folded in
above: the A-1 diagnostic-mechanism rewrite, the A-2 region-position policy and
pins, the D-1 min_prelude co-change, the reversibility and B2-carve-out
rewordings, and the recorded parse sub-decisions); the revised plan re-reviews
until both pass. Briefs: reviewer #1 attacks the §2.4 desugar (the pre-flight
witness-lookup mechanism, CFG well-formedness under R-2's shapes including the
three captured-region rejections, the compound-access-on-a-type claim for
`FromBreak`, the §2.6 no-copy trace) with concrete counter-programs; reviewer #2
attacks the §0.2/S3p boundary for leaks (anything in B1 that silently commits an
SF-9 outcome), the §4 zero-churn claims, the ledger, whether every §3 exit
criterion is arbitrable (R16 Goodhart checks), AND spot-checks the plan's
file:line citations against the tree (mandated after round 1 caught two drifted
citations). Findings return as data; only after both pass does the B1a
implementer start.

Items the coordinator signs off on (the V-2 veto digest for this plan):

1.  **The restaging (§0.2/§2.1):** B1 = `?`/`Core.Try` machinery over user-defined
    choices; prelude `Core.Result`/`Core.Optional`/entry-point signatures move to
    W5-S3p; the F-006 staging-table doc amendment recording it.
2.  **Option B (§2.2):** `Branch` returns a new prelude `Core.ControlFlow(C, B)`
    choice (`Continue`/`Break`) instead of the doc's `Result(...)`; the doc
    co-amendment; the alternative order fixing discriminants Continue=0/Break=1
    (which the desugar and goldens hard-depend on) and the deliberate
    continue-first parameter-order divergence from Rust's `ControlFlow<B, C>`;
    the divergence-risk register entry covering the name and both orders; the
    prelude library/CoreIdentifier sub-decisions; the reversibility premise
    (pre-S3p, only B1 testdata + one conformance program name the type).
3.  **The region-position policy (§2.4, revised after plan review, 2026-08-08):**
    `?` inside captured expression regions (guards, expression patterns, binding
    type annotations) is DIAGNOSED-AND-REJECTED (`QuestionInPatternContext`) in
    B1 — not supported, not TODO-gated — by way of the region-depth pre-flight check.
4.  **The unit-break-type bound (§2.7):** `BreakType = ()` stays inexpressible in
    B1; new work item at landing; S3p decides the resolution.
5.  **The impl-style rule (§2.6):** match-reconstruct `Branch` bodies as the
    documented pattern (doc impl sketches amended); choice `Core.Copy` synthesis
    remains out of scope.
6.  **Diagnostics and gate text (§2.3/§2.5):** the B1a TODO string and the six
    B1b diagnostic names/messages (including the pre-flight
    `QuestionReturnTypeNotTry` Error placement and `QuestionNonInitReturnForm`).
7.  **Type-position `?` is rejected in check, not parse (§2.3)** — plus the
    recorded C-1 whitespace-acceptance and C-2 `i32*?` asymmetry sub-decisions.
8.  **Conformance movement (§8):** the control_flow_constructs rewrite-and-flip
    and the new differential pair, with the 83/0/30-over-113 target floor.
