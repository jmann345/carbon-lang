# Design option paper: combined match control flow (if-let / let-else)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

Status: **OPEN design fork** (input to `fork/decision-log.md`). Part of
workstream W2 (design authorship) feeding W4 (pattern matching
semantics) and W5 (sum types / variant interop) per
`fork/gap-analysis.md`.

<!-- toc -->

## Table of contents

-   [Problem statement](#problem-statement)
-   [Constraints](#constraints)
    -   [What the milestone actually requires](#what-the-milestone-actually-requires)
    -   [Carbon design principles that bind this design](#carbon-design-principles-that-bind-this-design)
    -   [What upstream has already said](#what-upstream-has-already-said)
    -   [Prior art](#prior-art)
    -   [Implementation realities in this toolchain](#implementation-realities-in-this-toolchain)
-   [Options](#options)
    -   [Option A: `if (let ...)` conditions plus `let ... else` declarations](#option-a-if-let--conditions-plus-let--else-declarations)
    -   [Option B: `is` pattern-test expressions with flow-scoped bindings](#option-b-is-pattern-test-expressions-with-flow-scoped-bindings)
    -   [Option C: Swift-shaped `guard let ... else` for the negative form](#option-c-swift-shaped-guard-let--else-for-the-negative-form)
    -   [Option D: no dedicated forms - `match` only](#option-d-no-dedicated-forms---match-only)
-   [Recommendation](#recommendation)
-   [Dependencies on other workstreams](#dependencies-on-other-workstreams)
-   [Open questions for the user](#open-questions-for-the-user)

<!-- tocstop -->

## Problem statement

The 0.1 milestone (`docs/project/milestones.md:170-175`) requires, under
"Control flow statements → Matching":

> -   Good equivalents for C/C++ uses of `switch`
> -   Working with sum-types, especially for C++ `std::variant` and
>     `std::optional` interop
> -   Both positive (`if let` in Rust) and negative (`let else` in Rust)
>     combined match control flow and variable declaration

This paper is the design input for the **third** bullet, which is
**MISSING at every layer** per `fork/gap-analysis.md`: no tokens, no
parse states, no check support, and no design text — the only trace in
the whole tree is `docs/design/pattern_matching.md:670-676`, which notes
that a refutable pattern in a `let`/`var` declaration is currently an
error, and that "the `var`/`let`-`else` feature in
[#1871](https://github.com/carbon-language/carbon-lang/pull/1871) would
introduce a second context permitting refutable matches". That sentence
comes from accepted proposal `proposals/p002188` (same wording at
p002188:651-658), so the _slot_ for this feature is already reserved in
an accepted design; the feature itself was never designed.

Closing this bullet also materially advances the other two Matching
bullets: single-alternative consumption of `Optional`/`std::optional`
and `std::variant` is precisely the case where a full `match` is too
heavy (per-case exhaustiveness, mandatory `default`, extra nesting), so
the "good switch equivalents" and "sum-type interop" bullets are only
_ergonomically_ closed once an if-let family exists. It also advances
the 0.1 documentation goal ("understandable ... without placeholders",
`milestones.md:55-56`) by replacing the pattern-matching design's
forward reference to a dead upstream PR with real text.

Scoping note: `milestones.md:102-108` allows a bullet to be closed by "a
clear statement that Carbon will _not_ include this design". Option D
takes that escape hatch; A, B, and C do not.

## Constraints

### What the milestone actually requires

1.  A **positive** form: test-and-bind in one construct, with the
    bindings scoped to the success path (`if let` in Rust's terms).
2.  A **negative** form: bind-or-diverge, with the bindings scoped to
    the _enclosing_ scope (`let else` in Rust's terms).
3.  Both must be _combined match control flow and variable declaration_
    — that is they must use the real pattern grammar (bindings,
    destructuring, choice alternatives), not a boolean-plus-cast idiom.
4.  They must serve the `std::optional`/`std::variant` interop story
    named two bullets up.

### Carbon design principles that bind this design

-   **Low context sensitivity** (`proposals/p000646`): a reader (and the
    parser) should know what a construct is from its introducer. Carbon
    consistently disambiguates with leading keywords (`var`, `let`,
    `fn`, `match`) rather than lookahead. Any design that makes
    `if (a = b)` mean "pattern match" only after unbounded lookahead
    violates this.
-   **Braces required, conditions parenthesized**
    (`proposals/p000623`, `docs/design/control_flow/conditionals.md`):
    the surface must be `if (...) { ... }`-shaped; a Rust-literal
    `if let P = e { }` (no parens) is off-style.
-   **One pattern grammar** (`proposals/p002188`, accepted): patterns
    are already fully specified — binding patterns are
    `name: type` (not Rust's bare `name`), `var`/`ref` produce storage
    and reference bindings, choice alternatives match by way of
    `.Some(n: i32)` (`docs/design/pattern_matching.md:474-524`), and
    refutability is already defined
    (`pattern_matching.md:573-607`). The combined forms must consume
    this grammar unchanged, and their semantics must be "refutable
    full-pattern match" — not a new mini-language.
-   **Failure-path object semantics already exist**
    (`proposals/p005164`): `pattern_matching.md:776-792` specifies that
    objects created by `var` subpatterns during a _failed_ `case` match
    are destroyed at the failure point. if-let failure must reuse
    exactly this rule.
-   **Interop-first ergonomics** (`docs/project/goals.md`,
    "Interoperability with and migration from existing C++ code"): the
    forms must give obvious translations for the dominant C++ idioms
    (`if (auto* p = std::get_if<T>(&v))`, `if (opt) { use(*opt); }`,
    early-return guard clauses).

### What upstream has already said

-   Upstream PR
    [#1871](https://github.com/carbon-language/carbon-lang/pull/1871)
    ("var/let ... else") is cited by accepted p002188 as the anticipated
    second refutable-match context. It was never merged, but the
    accepted design _plans for its existence_ — strong evidence that a
    `let ... else` shape converges with upstream intent.
-   Upstream issue
    [#5101](https://github.com/carbon-language/carbon-lang/issues/5101)
    "Design idea: patterns as control flow conditions" is the live
    upstream thread. Direct browsing is proxy-blocked in this session;
    search snippets show it (a) motivating patterns as `if` conditions,
    with an example shaped like `if ((x, let y) = point) ... else ...`,
    and (b) stating that "the precedents of Swift and Rust point toward
    a syntax like `guard let (x: i32, y) = Foo() else { ... }`, where
    bindings in the pattern are added to the enclosing scope". Treat as
    directional, not settled: no proposal p-number exists for it (the
    proposals index has nothing between p005164 and p005545 on this
    topic, and nothing since).
-   No accepted proposal anywhere defines the positive form. This fork
    must therefore author the design (workstream W2), and any choice
    carries some divergence risk if #5101 later lands differently.

### Prior art

-   **Rust**: `if let P = e { }` / `else`, `while let`,
    `let P = e else { diverging-block };`
    ([RFC 3137](https://rust-lang.github.io/rfcs/3137-let-else.html)),
    and let-chains (RFC 2497, stabilized in edition 2024). RFC 3137's
    key lessons: the `else` block must **diverge** (type `!`), and the
    initializer expression must be syntactically restricted so a
    trailing brace-bearing expression can't swallow the `else`.
-   **Swift**: `if let x = opt { }`, `if case .foo(let x) = e`,
    `guard let x = opt else { return }` — `guard` requires the `else`
    block to exit the scope, and its bindings live in the _enclosing_
    scope. Swift demonstrates the readability value of a dedicated
    negative-form introducer.
-   **C#**: `if (e is T x)` / `is` patterns with flow-sensitive ("scoped
    by definite assignment") bindings — powerful and composable, but
    the scoping rules (negation, `||`, loops) are famously subtle.
-   **C++**: C++17 `if (init; cond)`, `std::get_if`, and the in-flight
    pattern-matching (P2688) and `is`/`as` (P2392) proposals — that is the
    audience Carbon targets has _no_ stable native equivalent; Carbon
    gets to define the idiom for them.
-   **Zig**: `if (opt) |x| { }` and `while (it.next()) |x|` payload
    captures — compact, but a separate capture syntax disjoint from the
    pattern grammar; wrong fit for Carbon's "one pattern grammar" rule.

### Implementation realities in this toolchain

Ground truth in `toolchain/` (trunk `99cda60`):

-   **Statement dispatch is introducer-driven**:
    `toolchain/parse/handle_statement.cpp:16-81` switches on the first
    token; `if` pushes `StatementIf`, `let` routes to the declaration
    path (`DeclAsRegular` → `HandleLet`,
    `toolchain/parse/handle_let.cpp:13-24`). Both paths already exist;
    combined forms only add branches, not a new dispatch mechanism.
-   **Conditions are expression-only today**:
    `toolchain/parse/handle_paren_condition.cpp:13-32` (states
    `ParenConditionAs(If|While|Match)`,
    `toolchain/parse/state.def:1065-1084`) consumes `(` then pushes
    `StateKind::Expr`. Since `let`/`var` can never begin an expression,
    a **single-token peek** after `(` cleanly forks to a pattern
    condition — no backtracking, satisfying p000646.
-   **The pattern state machine is reusable as-is**: `let`, `var`,
    `for`-headers, and `match` `case`s all parse patterns by pushing
    `StateKind::Pattern` by way of `PushStateForPattern`
    (`handle_let.cpp:20-23`, `handle_statement.cpp:121-124` for `for`,
    `handle_match.cpp:145-148` for `case`). An if-let condition is the
    same call.
-   **`=` is an expression operator**
    (`toolchain/parse/precedence.cpp:185-198`, Assignment group), so a
    bare `if (P = e)` (upstream #5101's sketch) is ambiguous with an
    assignment expression until the parser proves `P` contains a
    binding. This is the concrete reason to require an introducer
    keyword inside the condition.
-   **`else` is contended**: `if` _expressions_ (`if c then a else b`,
    `docs/design/expressions/if.md`; parse states
    `IfExprFinishThen/IfExprFinishElse`,
    `toolchain/parse/state.def:641-675`) consume `else` greedily, and
    `{...}` in expression position is a struct literal. So
    `let P = if c then a else {...}` is genuinely ambiguous between
    "if-expression whose else-value is a struct literal" and "let-else".
    Rust hit the identical problem and restricted the initializer
    grammar (RFC 3137); we must too.
-   **Check-side**: irrefutable local matching is implemented —
    `LocalPatternMatch` (`toolchain/check/pattern_match.cpp:1183`,
    called from `toolchain/check/handle_let_and_var.cpp:332,420`) —
    but it has **no failure path**: refutable patterns in `let`/`var`
    are diagnosed, and every `match` check handler is a `context.TODO`
    stub (`toolchain/check/handle_match.cpp`, 14 stubs). The refutable
    core (match a pattern, branch on failure, destroy partial `var`
    storage) is exactly workstream W4's deliverable. The CFG helpers
    the combined forms need already exist and are used by `if`:
    `AddDominatedBlockAndBranchIf` / `AddDominatedBlockAndBranch` /
    `AddConvergenceBlockAndPush`
    (`toolchain/check/control_flow.h:21-41`,
    `toolchain/check/handle_if_statement.cpp:18-40`).
-   **Lowering is free if check desugars**: `if`/`while` lower through
    ordinary `Branch`/`BranchIf` SemIR today; if the combined forms are
    specified as emitting the same SemIR a one-case `match` emits, W4's
    lowering covers them and `toolchain/lower/` needs **zero** new inst
    kinds.
-   **Tokens**: `if`, `else`, `let`, `var`, `while` are all already
    keywords (`toolchain/lex/token_kind.def:173-236`). Option A needs no
    lexer change; Option B needs an `is` token; Option C needs `guard`
    (the `r#guard` raw-identifier escape already lexes for C++ code
    using that name, `toolchain/lex/lex.cpp:1493`).
-   **Test surface**: parse coverage tests force every new node kind to
    appear in `toolchain/parse/testdata/`; `match` parse tests
    (`toolchain/parse/testdata/match/`, 14 files) are the template.

## Options

All options share the same _semantic core_ (deliberately): a refutable
full pattern per p002188 is matched against a scrutinee; on success its
bindings become visible in some scope; on failure control transfers
somewhere. They differ in surface syntax, binding scope rules, and how
much new machinery check needs.

### Option A: `if (let ...)` conditions plus `let ... else` declarations

Rust's two forms, spelled with Carbon's existing tokens and brace/paren
style. Positive form — a _pattern condition_ inside the existing
parenthesized condition slot:

```carbon
choice Optional(T: type) { None, Some(value: T) }

fn UseOpt(opt: Optional(i32)) -> i32 {
  // Positive: bindings (`n`) are in scope only in the then-block.
  if (let .Some(n: i32) = opt) {
    return n * 2;
  } else {
    return 0;
  }
}

fn Sum(v: Vector) -> f32 {
  var total: f32 = 0.0;
  // while-let: re-matched each iteration; exits on first failure.
  while (let .Some(x: f32) = v.PopBack()) {
    total += x;
  }
  return total;
}

fn Classify(pair: (i32, i32)) {
  // Destructuring + expression subpattern; `else if` chains fall out.
  if (let (0, n: i32) = pair) {
    Print("zero then {0}", n);
  } else if (let (n: i32, 0) = pair) {
    Print("{0} then zero", n);
  }
}
```

Negative form — a `let`/`var` declaration with an `else` block that must
diverge; bindings land in the **enclosing** scope:

```carbon
fn ParsePort(s: str) -> i32 {
  let .Some(port: i32) = ParseI32(s) else {
    return -1;
  }
  // `port` is in scope here.
  return port;
}

fn Mutate(opt: Optional(Widget)) {
  var .Some(w: Widget) = opt else { return; }
  w.Frob();  // `w` is mutable storage, per `var` pattern semantics.
}
```

Grammar (extending p002188's forms):

-   _statement_ ::= `if` `(` (`let` | `var`) _full-pattern_ `=`
    _expression_ `)` _block_ [`else` (_block_ | _if-statement_)]
-   _statement_ ::= `while` `(` (`let` | `var`) _full-pattern_ `=`
    _expression_ `)` _block_
-   _declaration_ ::= (`let` | `var`) _full-pattern_ `=` _expression_
    `else` _block_

Semantics:

-   The pattern is matched per p002188/p005545 (same conversion,
    evaluation-order, and guard-free rules as a `match` `case`). On
    failure, objects already created by `var` subpatterns are destroyed
    (p005164 rule, `pattern_matching.md:776-792`).
-   `if (let ...)`: success → then-block with bindings in its scope;
    failure → `else` arm (or fall through). No bindings are visible in
    the `else` arm or after the statement.
-   `while (let ...)`: the match is the loop condition; bindings are in
    the body scope, rebound each iteration.
-   `let ... else`: the `else` block must not complete normally — for
    0.1, it must end with `return`, `break`, or `continue` (a syntactic
    rule; revisit as a type-based "noreturn" rule once the
    error-handling design lands — see
    `fork/design-sprint/error-handling.md`). After the declaration, the
    bindings are ordinary `let`/`var` bindings of the enclosing scope.
-   Initializer restriction (the `else` ambiguity): in the `let ... else`
    form, the initializer expression must not be an unparenthesized `if`
    expression (diagnose with a "parenthesize the initializer" fixit).
    This is Rust RFC 3137's restriction adapted to Carbon's one
    brace-bearing expression form.
-   An _irrefutable_ pattern in these forms is valid but warns (as with
    Rust's `irrefutable_let_patterns`), keeping the macro-friendly
    degenerate case legal.
-   Not in 0.1 (reserved): boolean chaining (`if (let P = e and cond)`),
    guards inside the condition, and an if-let _expression_ form. The
    grammar above keeps `)` immediately after the initializer expression
    precisely so a future `and` chain (Rust let-chains) can be added
    without reparsing.

C++ interop story: no ABI or export surface — these are intra-function
control flow, invisible to C++. The interop payoff is consumption-side:
once W5 maps `std::optional`/`std::variant` into `Optional`/choice-shaped
types, `if (let .Some(x: T) = opt)` is the direct translation of C++'s
`if (opt) { use(*opt); }` and `if (auto* p = std::get_if<T>(&v))`, and
`let ... else` is the guard-clause idiom (`if (!opt) return;`). Nothing
here blocks on Clang or thunk machinery.

Implementation cost in this toolchain: **M** (assuming W4 lands first;
**XL** standalone, because it would pull in W4's refutable-match core).

-   `toolchain/lex/`: **none** (all tokens exist).
-   `toolchain/parse/`: ~5 new node kinds (`node_kind.def`:
    pattern-condition intro/finish, `LetElse` block start/finish), ~6
    new states (`state.def`), a one-token peek in
    `handle_paren_condition.cpp`, an `else`-path in
    `handle_let.cpp::HandleLetAfterPattern` (it already stops exactly at
    `=`/`;`), `typed_nodes.h` entries, testdata + coverage. Size **S**.
-   `toolchain/check/`: the real work. A refutable variant of
    `LocalPatternMatch` (`pattern_match.cpp`) that takes a failure block
    target instead of diagnosing refutability; wiring in
    `handle_let_and_var.cpp` (else-region + divergence check) and a
    pattern-condition sibling to `handle_if_statement.cpp` /
    `handle_loop_statement.cpp` using the existing
    `control_flow.h:21-41` helpers; binding scope placement by way of the
    existing `full_pattern_stack`/`scope_stack` (bindings go to the
    dominated block's scope — same mechanism W4 needs for `case`
    bodies). Size **M** on top of W4.
-   `toolchain/lower/`: **none** (standard branches).

Evolution risk vs upstream: **low-to-medium**. The negative form is the
one upstream's accepted design already reserves (#1871 citation in
p002188), and the milestone words the requirement in Rust's terms. The
positive form is where #5101 might land elsewhere (bare
pattern-condition or `guard`); if it does, the delta is surface
respelling over identical semantics — mechanical to migrate, and our
parse states are additive (no upstream file is restructured, so merges
stay clean).

### Option B: `is` pattern-test expressions with flow-scoped bindings

A new low-precedence operator makes pattern-testing an _expression_:

```carbon
fn UseOpt(opt: Optional(i32)) -> i32 {
  if (opt is .Some(n: i32) and n > 10) {
    return n;
  }
  return 0;
}

fn ParsePort(s: str) -> i32 {
  if (not (ParseI32(s) is .Some(port: i32))) {
    return -1;
  }
  // C#-style: `port` is definitely bound here, so it is in scope.
  return port;
}
```

-   _expression_ ::= _expression_ `is` _full-pattern_ (non-associative,
    below `and`/`or`, above `if`-expression)
-   Bindings are visible wherever the compiler can prove the test
    succeeded (flow-sensitive scoping: then-blocks, `and`-continuations,
    post-diverging-else code).

Advantages: one construct covers positive, negative, chained, and
boolean-mixed cases; composes with `while`; aligns with where C++ itself
may go (P2392 `is`/`as`) and with C#'s proven ergonomics; reads well to
the target audience.

Disadvantages: **flow-sensitive name scoping is a new compiler concept** —
`scope_stack` is strictly lexical today, and check would need
dominance-driven scope injection plus rules for `not`/`or`/loops (C#'s
definite-assignment tangle); it violates the "patterns appear only after
introducers" simplicity and p000646's spirit (deep in an expression, a
`:` flips you into pattern grammar); needs a new `is` keyword _and_
precedence surgery in `precedence.cpp`; and no upstream artifact hints
at `is`, so divergence risk is highest. Guards/chains — its main selling
point over A — can be added to A later as let-chains anyway.

C++ interop story: same as A (no ABI surface; same optional/variant
consumption wins; `is` spelling coincidentally matches P2392 if that
ever ships).

Implementation cost: **L-XL** even after W4: lex **S** (token), parse
**M** (expression-operator with a pattern RHS; the only place patterns
appear mid-expression), check **L** (refutable core _plus_ the novel
flow-scoping machinery), lower none. Evolution risk: **medium-high**.

### Option C: Swift-shaped `guard let ... else` for the negative form

Adopt Option A's positive form unchanged, but spell the negative form as
a dedicated statement instead of overloading `let` declarations:

```carbon
fn ParsePort(s: str) -> i32 {
  guard let .Some(port: i32) = ParseI32(s) else {
    return -1;
  }
  return port;
}
```

-   _statement_ ::= `guard` (`let` | `var`) _full-pattern_ `=`
    _expression_ `else` _block_
-   Semantics identical to Option A's `let ... else` (enclosing-scope
    bindings, diverging `else`); optionally also `guard (cond) else`
    as a boolean guard for symmetry (Swift precedent).

Advantages: matches the syntax the upstream #5101 snippet literally floats
(`guard let (x: i32, y) = Foo() else { ... }`), so *if that snippet
reflects upstream's lean*, this is the convergent spelling; the
introducer announces "early-exit" to readers; and the if-expression
`else` ambiguity narrows, since a `guard` statement can forbid `if`
expressions as its initializer without touching ordinary `let` grammar.

Disadvantages: burns a new keyword — `guard` is a common identifier in exactly
the C++ code Carbon targets (`std::lock_guard`, scope guards), forcing
`r#guard` escapes on import; it duplicates spelling for one semantic
(a `guard let` is observationally a `let ... else`); and p002188's own
reservation cites the `let ... else` shape (#1871), so upstream evidence
points both ways. The parse cost is Option A plus a keyword and one more
statement dispatch case; check cost is identical to A.

Implementation cost: **M** (Option A + lex **S** + one statement
handler). Evolution risk: **medium** — hedged against #5101 choosing
`guard`, exposed if upstream instead revives #1871's `let ... else`.

### Option D: no dedicated forms - `match` only

Take the `milestones.md:102-108` escape hatch: document that Carbon
covers these use cases with `match` plus early `return`:

```carbon
fn ParsePort(s: str) -> i32 {
  match (ParseI32(s)) {
    case .Some(port: i32) => { return port; }
    default => { return -1; }
  }
}
```

Advantages: zero design and implementation cost beyond W4; no divergence
risk; everything remains expressible.

Disadvantages: fails the milestone bullet _as written_ — it explicitly names both
combined forms, and the audit already scored this row MISSING against
that wording; the escape hatch requires arguing `match` "addresses the
use cases", but the use case _is_ ergonomics (a guard clause becomes
5 lines of nesting with a mandatory `default`, and the "translate C++
into obvious and unsurprising Carbon" goal, `milestones.md:57-61`, is
hurt for every `if (opt)` in the source corpus); and it would leave
`pattern_matching.md`'s #1871 forward-reference dangling, failing the
"no placeholders" documentation bar. Cost **S** (prose only). Evolution
risk: none now, guaranteed rework when upstream lands #5101.

## Recommendation

**Option A**, with two riders:

1.  Specify both forms as _desugarings onto W4's refutable-match SemIR_
    (an if-let is a one-case match with the else-arm as the failure
    target; a let-else is the same with a divergence-checked failure
    block). This keeps check/lower deltas at M/zero and means the
    conformance tests for W4 and this feature share machinery.
2.  Record a standing note in `fork/decision-log.md` that if upstream
    #5101 lands a different surface (bare pattern conditions or
    `guard`), this fork re-spells mechanically but keeps the semantics —
    the semantics (p002188 pattern grammar, p005164 failure
    destruction, enclosing-scope let-else bindings, diverging else) are
    the part every candidate surface shares.

Rationale:

-   It closes the milestone bullet in the bullet's own vocabulary (the
    milestone literally defines the requirement by pointing at Rust's
    two forms).
-   It is the only option whose negative form is *already reserved by an
    accepted upstream proposal* (p002188's #1871 reference), minimizing
    both design-doc delta and upstream divergence.
-   It fits this parser like a glove: introducer-keyword dispatch,
    single-token peek after `(`, reuse of the existing `Pattern` state
    — no lexer change, no precedence surgery, no backtracking
    (p000646 upheld).
-   Its cost is honestly M _because_ it rides W4; Options B's novel
    scoping machinery is the only L/XL item on the table and buys
    nothing that let-chains can't add to A later.
-   `while (let ...)` comes along nearly free and strengthens the loops
    bullet ("good equivalents for ... existing C/C++ looping
    constructs", `milestones.md:167-169`) for pop/iterate loops.

Option C is the fallback if the user weighs the #5101 `guard` snippet
heavily; it is A plus a keyword, and switching between them later is a
parser-level rename. Option B should be explicitly rejected in the
decision log (not deferred silently) so reviewers citing C#/P2392 have
an answer on record. Option D fails the milestone as written.

## Dependencies on other workstreams

-   **W4 (pattern matching semantics) — hard dependency.** The
    refutable-match core (pattern → CFG with failure edge, partial-match
    destruction, binding scope placement in dominated blocks) is W4's
    deliverable; this feature is a thin statement-level client of it.
    Sequencing: land W4's `match` first, then this as the second
    refutable context. (Standalone implementation would drag most of
    W4 in, inverting the dependency map.)
-   **W5 (choice payloads + `std::variant`/`std::optional` interop) —
    soft dependency.** The forms work on tuples/structs/expression
    patterns without W5, but the motivating interop examples
    (`.Some(x: T)` over an imported `std::optional`) need payload
    alternatives (`toolchain/check/handle_choice.cpp:159` TODO) and the
    W5 mapping. Conformance tests should include both a W5-free program
    and the optional/variant programs (initially marked fail_todo).
-   **W1 (conformance harness)** — arbiter for the executed-behavior
    tests (success path, failure path, destruction order on failed
    match, while-let iteration count).
-   **W2 (error handling design)** — the let-else divergence rule
    should eventually reference the error-handling design's
    control-flow forms (early-return sugar like a future `?`/`try`
    would typically desugar _to_ let-else; and a noreturn-type-based
    divergence rule replaces the syntactic list). Coordinate wording so
    the two papers don't define "diverges" twice.
-   **Design docs**: amend `docs/design/pattern_matching.md` (replace
    the #1871 reference at lines 670-676 with the real design; add the
    new context to the refutability section) and
    `docs/design/control_flow/conditionals.md` / `loops.md`; add the
    decision to `fork/decision-log.md`.

## Open questions for the user

Beyond choosing A/B/C/D:

1.  **`let ... else` terminator**: does the declaration end at the
    else-block's `}` (statement-like, matches `if`/Swift `guard`), or
    require a trailing `;` (declaration-like, matches Rust)? This paper
    assumes no `;`; it is a two-line parser choice but a permanent
    style decision.
2.  **The if-expression ambiguity rule**: forbid unparenthesized `if`
    expressions as let-else initializers (recommended, Rust-style), or
    resolve greedily in favor of the if-expression and let users
    discover the misparse? Affects diagnostics quality more than
    grammar.
3.  **Divergence definition** for the else block in 0.1: syntactic
    (must end with `return`/`break`/`continue`) vs deferred to a
    noreturn-type rule. Syntactic is implementable today; it rejects
    `else { Abort(); }` until a noreturn design exists.
4.  **`while (let ...)` in 0.1 scope**: included here as nearly-free;
    confirm, since the milestone's matching bullet does not name it.
5.  **`var` forms in 0.1** (`if (var P = e)`, `var P = e else`):
    p002188 treats `var` uniformly, and `handle_var.cpp` shares the
    machinery, so this paper includes them — but they can be deferred
    (S saving) if W4's `var`-in-`case` support slips.
6.  **Irrefutable patterns in the combined forms**: warn (recommended,
    Rust-style) or hard error (Swift-style for `guard let` of
    non-optionals)?
7.  **Chaining reservation**: confirm that `and`-chaining
    (`if (let P = e and cond)`) is out of 0.1 but the grammar must not
    foreclose it. If you want it _in_ 0.1, Option A's parse cost rises
    to M and evaluation-order text must extend p005545.
8.  **Upstream tracking policy**: if upstream #5101 produces an
    accepted proposal mid-implementation, do we pause and adopt, or
    finish our spelling and migrate later? (Standing rule 5 in
    `fork/process.md` says check before starting; this is the explicit
    per-feature instance.)
